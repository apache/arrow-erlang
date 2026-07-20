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

-module(arrow_variable_list_array).
-moduledoc """
Provides support for Arrow's Variable-Size List Layout.

This module provides support for the [Variable-Size List
Layout](https://arrow.apache.org/docs/format/Columnar.html#variable-size-list-layout),
which is an layout that supports storing a list of lists of a specific length
and nesting.

## Invalid Input

It is important that care is taken when passing input values to this
module. For performance reasons, the input is not validated. The
function crashes on nesting that is inconsitent: a. with the type, b.
between elements. The behaviour on invalid input **CANNOT BE
GUARANTEED**. Therefore, one must be careful to not to **CRASH THE
PROCESS** or worse still, **PRODUCE INVALID OUTPUT**.

Any input must follow the following rules:

1.  The nesting of each element must be consistent with the type
2.  The nesting of each element must be consistent with each other
""".

-behaviour(arrow_array).

-export([from_erlang/2]).

-include("arrow_array.hrl").

-spec from_erlang(Values :: list(), Type :: map() | arrow_type:arrow_type()) ->
    Array :: arrow_array:array().
from_erlang(Values, Opts) when is_map(Opts) ->
    case maps:get(type, Opts, undefined) of
        undefined ->
            erlang:error(badarg);
        Type when is_tuple(Type) orelse is_atom(Type) ->
            from_erlang(Values, Type)
    end;
from_erlang(Values, GivenType) ->
    Len = length(Values),
    {Bitmap, NullCount} = arrow_bitmap:validity_bitmap(Values),
    Type = arrow_type:normalize(GivenType),
    Flattened = arrow_utils:flatten(Values),
    Data =
        case Type of
            {bin, undefined} ->
                arrow_variable_binary_array:from_erlang(Flattened);
            {_, _} ->
                arrow_fixed_primitive_array:from_erlang(Flattened, Type);
            {Layout, NestedType, _Size} ->
                arrow_array:from_erlang(Layout, Flattened, NestedType)
        end,
    FlatOffsets =
        case Data#array.offsets of
            undefined ->
                fixed_offsets(Type, Data#array.len);
            Offset ->
                Offset#buffer.data
        end,
    Offsets = arrow_buffer:from_erlang(offsets(Values, FlatOffsets, 0), {s, 32}, Len + 1),
    #array{
        layout = variable_list,
        type = Type,
        len = Len,
        element_len = undefined,
        null_count = NullCount,
        validity_bitmap = Bitmap,
        offsets = Offsets,
        data = Data
    }.

%%%%%%%%%%%
%% Utils %%
%%%%%%%%%%%

-spec offsets(Values :: list(), Offsets :: [non_neg_integer()], CurOffset :: non_neg_integer()) ->
    [non_neg_integer()].
offsets([H | T], Offsets, CurOffset) when (H =:= undefined) orelse (H =:= nil) ->
    [CurOffset | offsets(T, Offsets, CurOffset)];
offsets(Values, [0 | TOffsets], CurOffset) ->
    [CurOffset | offsets(Values, TOffsets, CurOffset)];
offsets([H | T], Offsets, _CurOffset) ->
    Len = length(H),
    {_HOffsets, [CurOffset | TOffsets]} = lists:split(Len - 1, Offsets),
    [CurOffset | offsets(T, TOffsets, CurOffset)];
offsets([], _Offset, _CurOffset) ->
    [].

-spec fixed_offsets(Type :: arrow_type:arrow_longhand_type(), Length :: pos_integer()) ->
    [non_neg_integer()].
fixed_offsets(Type, Length) when tuple_size(Type) =:= 2 ->
    ByteLen = arrow_type:byte_length(Type),
    lists:seq(0, Length * ByteLen, ByteLen);
fixed_offsets({fixed_list, Type, Size}, Length) ->
    fixed_offsets(Type, Length * Size).
