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

-module(arrow_fixed_list_array).
-moduledoc """
Provides support for Arrow's Fixed-Size List Layout.

This module provides support for the [Fixed-Size List
Layout](https://arrow.apache.org/docs/format/Columnar.html#fixed-size-list-layout),
which is a layout that supports storing a list of lists of a specific length and
nesting.

## Invalid Input

It is important that care is taken when passing input values to this module. For
performance reasons, the input is not validated. The function crashes on nesting
that is inconsistent: either with the type, or between elements. The lists are
checked to have the same length as each other at the top level, but not for
deeper levels. The behaviour of the module on invalid input **CANNOT BE
GUARANTEED**. Therefore, one must be careful to not to **CRASH THE PROCESS** or
worse still, **PRODUCE INVALID OUTPUT**.

Any input must follow the following rules:

1.  The length of each element must be consistent with the type
2.  The nesting of each element must be consistent with the type
3.  The length of each element must be consistent with each other
4.  The nesting of each element must be consistent with each other
5.  The nested type is a `fixed_list` (as only then can fixed size be
    guaranteed)
""".
-behaviour(arrow_array).

-export([from_erlang/2]).

-include("arrow_array.hrl").

-doc """
Creates a Fixed-Size List Array given the values and type.
Accepts a map with the type, or the type directly.
""".
-spec from_erlang(Values :: list(), Type :: map() | arrow_type:arrow_type()) ->
    Array :: arrow_array:array().
from_erlang(Values, Opts) when is_map(Opts) ->
    case maps:get(type, Opts, undefined) of
        undefined ->
            erlang:error(badarg);
        Type when is_tuple(Type) orelse is_atom(Type) ->
            from_erlang(Values, Type)
    end;
from_erlang([[H | _] | _] = Values, GivenType) when
    (is_tuple(GivenType) andalso tuple_size(GivenType) =:= 2) orelse is_atom(GivenType),
    not is_list(H)
->
    Len = length(Values),
    ElementLen = element_len(Values),
    Type = arrow_type:normalize(GivenType),
    {Bitmap, NullCount} = arrow_bitmap:validity_bitmap(Values),
    Flattened = arrow_utils:flatten(Values, fun() -> [undefined] end, ElementLen),
    Array = arrow_fixed_primitive_array:from_erlang(Flattened, Type),
    #array{
        layout = fixed_list,
        type = Type,
        len = Len,
        element_len = ElementLen,
        null_count = NullCount,
        validity_bitmap = Bitmap,
        data = Array
    };
from_erlang(Value, {fixed_list, NestedType, Size} = Type) ->
    Len = length(Value),
    {Bitmap, NullCount} = arrow_bitmap:validity_bitmap(Value),
    Shape = shape(Value, NestedType),
    Null = [list_from_shape(Shape)],
    Flattened = arrow_utils:flatten(Value, fun() -> Null end, Size),
    Array = arrow_fixed_list_array:from_erlang(Flattened, NestedType),
    #array{
        layout = fixed_list,
        type = Type,
        len = Len,
        element_len = Size,
        null_count = NullCount,
        validity_bitmap = Bitmap,
        data = Array
    };
from_erlang(_Value, _Layout) ->
    erlang:error(badarg).

%%%%%%%%%%%
%% Utils %%
%%%%%%%%%%%

-spec element_len(List :: list()) -> ElementLen :: pos_integer().
element_len([H | _T]) when is_list(H) ->
    length(H);
element_len([H | T]) when (H =:= undefined) orelse (H =:= nil) ->
    element_len(T);
element_len([]) ->
    erlang:error(badarg).

-spec shape(Values :: list(), Type :: arrow_type:arrow_type()) -> [pos_integer()].
shape(Values, {_, Type, Size}) ->
    [Size] ++ shape(arrow_utils:flatten(Values), Type);
shape(Values, Type) when is_atom(Type) orelse tuple_size(Type) =:= 2 ->
    [element_len(Values)].

-spec list_from_shape(list()) -> list().
list_from_shape([H]) ->
    lists:duplicate(H, undefined);
list_from_shape([H | T]) ->
    lists:duplicate(H, list_from_shape(T)).
