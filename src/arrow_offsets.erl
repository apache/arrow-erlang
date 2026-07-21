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

-module(arrow_offsets).
-moduledoc """
Provides support for Apache Arrow's Offsets

Arrow has a concept of
[offsets](https://arrow.apache.org/docs/format/Columnar.html#variable-size-binary-layout)
in order to tell the length of a
[slot](https://arrow.apache.org/docs/format/Columnar.html#terminology) or a
single element in an array of variable-size elements. This module provides
support for generating offsets.

There are couple of things to remember about offsets:

Firstly, each element in the offsets corresponds to the distance in bytes of the
corresponding element in the values from the beginning of the buffer.

I.E., distance of `values[j]` from beginning of the buffer = `offsets[j]`.

Secondly, the very last element in the offsets is the length of the buffer, or
distance of the end of the last slot from the beginning of the buffer.

Thus, the offsets is one element longer than the values, or:

```
length(offsets) == length(values) + 1
```

Therefore, in order to find the length of a slot, we subtract the offset the
current element from the offset of the next element, or:

```
slot[j] = offsets[j + 1] - offsets[j]
```

Finally, null values have an offset of 0 as they take no memory in the buffer.
Thus, the previous offset and the current offset are equivalent if the current
element is a null.
""".
-export([new/2, new/3]).

-doc """
Returns the offsets array given some values and their type as a buffer.
""".
-spec new(
    Value :: [arrow_type:native_type()],
    Type :: arrow_type:arrow_longhand_type()
) ->
    Buffer :: arrow_buffer:buffer().
new(Values, Type) ->
    new(Values, Type, length(Values)).

-doc """
Returns the offsets array given some values, their type and length as a buffer.
""".
-spec new(
    Value :: [arrow_type:native_type()],
    Type :: arrow_type:arrow_longhand_type(),
    Length :: pos_integer()
) ->
    Buffer :: arrow_buffer:buffer().
new(Values, Type, Len) ->
    Offsets = offsets(Values, [0], 0, Type),
    arrow_buffer:from_erlang(Offsets, {s, 32}, Len + 1).

-spec offsets(
    Value :: [arrow_type:native_type()],
    Acc :: [non_neg_integer()],
    Offset :: non_neg_integer(),
    Type :: arrow_type:arrow_longhand_type()
) -> Offsets :: [non_neg_integer()].
offsets([Value | Rest], Acc, Offset, Type) when (Value =:= undefined) orelse (Value =:= nil) ->
    offsets(Rest, [Offset | Acc], Offset, Type);
offsets([Value | Rest], Acc, Offset, Type) ->
    CurOffset = Offset + len(Value, Type),
    offsets(Rest, [CurOffset | Acc], CurOffset, Type);
offsets([], Acc, _Offset, _Type) ->
    lists:reverse(Acc).

-spec len(
    Value :: arrow_type:native_type() | undefined | nil,
    Type :: arrow_type:arrow_longhand_type()
) -> non_neg_integer().
len(Value, bin) ->
    byte_size(Value);
len(Value, Type) ->
    byte_size(arrow_type:serialize(Value, Type)).
