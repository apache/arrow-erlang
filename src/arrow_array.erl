% Licensed to the Apache Software Foundation (ASF) under one
% or more contributor license agreements.  See the NOTICE file
% distributed with this work for additional information
% regarding copyright ownership.  The ASF licenses this file
% to you under the Apache License, Version 2.0 (the
% "License"); you may not use this file except in compliance
% with the License.  You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing,
% software distributed under the License is distributed on an
% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
% KIND, either express or implied.  See the License for the
% specific language governing permissions and limitations
% under the License.

-module(arrow_array).
-moduledoc """
Provides a record, a behaviour, and functions to work with Apache Arrow Arrays.

This module as mentioned, provides conveniences for working with Apache Arrow
[Arrays](https://arrow.apache.org/docs/format/Glossary.html#term-array) of
different
[Layouts](https://arrow.apache.org/docs/format/Glossary.html#term-physical-layout).
Firstly, it provides a record to represent all the Layout. Secondly, it provides
a behaviour for different layouts to adhere to common functionality. Lastly, it
provides functions to work with Arrays in a common manner.

# The Structure of an Array

`arrow`'s implementation of an Array has the following fields in its record
definition, each corresponding to a field in the Arrow Columnar Format
specification:

| Field             | Type                        | Representing                                                                              |
|-------------------|-----------------------------|-------------------------------------------------------------------------------------------|
| `layout`          | `t:atom/0`                  | Layout                                                                                    |
| `type`            | `t:arrow_type:arrow_type/0` | [Logical Type](https://arrow.apache.org/docs/format/Glossary.html#term-type)              |
| `len`             | `t:pos_integer/0`           | [Length](https://arrow.apache.org/docs/format/Columnar.html#array-lengths)                |
| `element_len`     | `t:pos_integer/0`           | Length of each element                                                                    |
| `null_count`      | `t:non_neg_integer/0`       | [Null Count](https://arrow.apache.org/docs/format/Columnar.html#null-count)               |
| `validity_bitmap` | `arrow_buffer`              | [Validity Bitmap](https://arrow.apache.org/docs/format/Columnar.html#validity-bitmaps)    |
| `offsets`         | `arrow_buffer`              | [Offsets](https://arrow.apache.org/docs/format/Columnar.html#variable-size-binary-layout) |
| `data`            | `arrow_buffer`              | Value Buffer                                                                              |


Certain fields are not required for certain layouts. For example, for the
Fixed-Sized Primitive Layout, the offsets field is not required, in which case
it is assigned as `undefined`. Similarly, the `validity_bitmap` is not required
if there are no null values, in which case it is also assigned as `undefined`.

# The Behaviour of an Array

As of right now, a layout needs to implement the `c:from_erlang/2` callback.
This is then used in the `from_erlang/3` function to create new arrays.

# Functions for working with Arrays

As of right now, only functions to access the various fields, to create
new arrays, and to serialize arrays to arrow exist.
""".
-export([
    from_erlang/3,
    layout/1,
    type/1,
    len/1,
    element_len/1,
    null_count/1,
    validity_bitmap/1,
    offsets/1,
    data/1,
    to_arrow/1
]).

-include("arrow_array.hrl").

-export_type([array/0, layout/0]).

-doc "Represents an Array.".
-type array() :: #array{}.

-doc "Represents the Layout of an Array.".
-type layout() :: fixed_primitive | variable_binary | fixed_list | variable_list.

%%%%%%%%%%%%%%%%%%%%
%% Array Creation %%
%%%%%%%%%%%%%%%%%%%%

-doc """
Creates a new array of a certain layout, given its value and options from its
erlang representation.
""".
-callback from_erlang(Value :: [arrow_type:native_type()], Opts :: map()) ->
    Array :: #array{}.

-doc """
A common way to create a new array, given its layout, value, and options.
from its erlang representation.
""".
-spec from_erlang(
    Layout :: layout(),
    Value :: [arrow_type:native_type()],
    Opts :: map() | arrow_type:arrow_type()
) ->
    Array :: #array{}.
from_erlang(Layout, Value, Opts) ->
    case Layout of
        fixed_primitive -> arrow_fixed_primitive_array:from_erlang(Value, Opts);
        variable_binary -> arrow_variable_binary_array:from_erlang(Value, Opts);
        fixed_list -> arrow_fixed_list_array:from_erlang(Value, Opts);
        variable_list -> arrow_variable_list_array:from_erlang(Value, Opts)
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Array Data and Metadata Access %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-doc "Returns the layout of an array.".
-spec layout(Array :: #array{}) -> Layout :: layout().
layout(Array) ->
    Array#array.layout.

-doc "Returns the type of an array.".
-spec type(Array :: #array{}) -> Type :: arrow_type:arrow_type().
type(Array) ->
    Array#array.type.

-doc "Returns the length of an array.".
-spec len(Array :: #array{}) -> Length :: pos_integer().
len(Array) ->
    Array#array.len.

-doc "Returns the length of an array.".
-spec element_len(Array :: #array{}) -> Length :: pos_integer() | undefined.
element_len(Array) ->
    Array#array.element_len.

-doc "Returns the null count of an array.".
-spec null_count(Array :: #array{}) -> NullCount :: non_neg_integer().
null_count(Array) ->
    Array#array.null_count.

-doc "Returns the validity bitmap of an array.".
-spec validity_bitmap(Array :: #array{}) -> ValidityBitmap :: #buffer{} | undefined.
validity_bitmap(Array) ->
    Array#array.validity_bitmap.

-doc "Returns the offsets of an array.".
-spec offsets(Array :: #array{}) -> Offsets :: #buffer{} | undefined.
offsets(Array) ->
    Array#array.offsets.

-doc "Returns the data of an array.".
-spec data(Array :: #array{}) -> Data :: #buffer{} | #array{} | undefined.
data(Array) ->
    Array#array.data.

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Array Serialization %%
%%%%%%%%%%%%%%%%%%%%%%%%%

-doc """ 
Serializes an array into the Arrow binary form.

Serializes the buffers of an Array and concatenates them in the following
order:

1. `validity`
2. `offsets`
3. `data`

In case an array doesn't have any of the following buffers, it is ommitted.
(e.g. validity in arrays with a null count of 0, offsets in fixed primitive
arrays). In the case of a nested array, `data` will be serialized form of nested
array.

Do note that this is just binary form that includes the buffers in an Array,
and not IPC.
""".
-spec to_arrow(Array :: #array{}) -> Arrow :: binary().
to_arrow(Array) ->
    Validity = some(validity_bitmap(Array)),
    Offsets = some(offsets(Array)),
    Data = some(data(Array)),

    <<Validity/binary, Offsets/binary, Data/binary>>.

-spec some(Value :: #array{} | #buffer{} | undefined) -> Binary :: binary().
some(undefined) ->
    <<>>;
some(Buffer) when is_record(Buffer, buffer) ->
    arrow_buffer:to_arrow(Buffer);
some(Array) when is_record(Array, array) ->
    to_arrow(Array).
