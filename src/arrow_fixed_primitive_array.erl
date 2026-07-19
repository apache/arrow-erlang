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

-module(arrow_fixed_primitive_array).
-moduledoc """
Provides support for Arrow's Fixed-Size Primitive Layout. The [Primitive
Layout](https://arrow.apache.org/docs/format/Columnar.html#fixed-size-primitive-layout)
uses the following metadata in the `arrow_array`:

1.  `layout`, of type `t:atom/0`, and a constant value of
    `fixed_primitive`.
2.  `type`, of type `t:arrow_type:arrow_primitive_type/0`, which
    represents the Logical Type of the Array.
3.  `len`, of type `t:pos_integer/0`, which represents the Array's
    Length.
4.  `null_count`, of type `t:non_neg_integer/0`, which represents
    the Array's Null Count, or the number of undefined values in the
    Array.
5.  `validity_bitmap`, which is a buffer (`arrow_buffer`) or the
    atom `undefined`, which represents the Array's [Validity
    Bitmap](https://arrow.apache.org/docs/format/Columnar.html#validity-bitmaps).
6.  `data`, which is a buffer (`arrow_buffer`), which represents the
    Array's Value Buffer.

The `offsets` field will be allocated as `undefined`. Same goes for the
`validity_bitmap` field in the case of a 0 `null_count`.
""".
-behaviour(arrow_array).

-export([from_erlang/2]).

-include("arrow_array.hrl").

%%%%%%%%%%%%%%%%%%%%
%% Array Creation %%
%%%%%%%%%%%%%%%%%%%%

-doc """
Creates a new primitive array, given its value and type from its erlang
representation.

Accepts a map with the type, or the type directly.
""".
-spec from_erlang(
    Value :: [arrow_type:native_type()],
    Type :: map() | arrow_type:arrow_primitive_type()
) ->
    Array :: arrow_array:array().
from_erlang(Value, Opts) when is_map(Opts) ->
    case maps:get(type, Opts, undefined) of
        undefined ->
            erlang:error(badarg);
        Type when is_tuple(Type) orelse is_atom(Type) ->
            from_erlang(Value, Type)
    end;
from_erlang(Value, GivenType) when is_tuple(GivenType) orelse is_atom(GivenType) ->
    Len = length(Value),
    Type = arrow_type:normalize(GivenType),
    {Bitmap, NullCount} = arrow_bitmap:validity_bitmap(Value),
    Data = arrow_buffer:from_erlang(Value, Type, Len),
    #array{
        layout = fixed_primitive,
        type = Type,
        len = Len,
        null_count = NullCount,
        validity_bitmap = Bitmap,
        data = Data
    }.
