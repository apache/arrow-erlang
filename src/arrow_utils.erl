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

-module(arrow_utils).
-moduledoc false.
-export([nesting/1, flatten/1, flatten/3, pad_len/1, pad_len/2]).

%% Finds the nesting level of deep list
%%
%% Assumes each sublist has the same nesting
-spec nesting(List :: list() | term()) -> pos_integer().
nesting([H | _T]) when is_list(H) ->
    1 + nesting(H);
nesting([H | T]) when (H =:= undefined) orelse (H =:= nil) ->
    nesting(T);
nesting(_H) ->
    1.

%% Flattens a deeplist by one level
%%
%% Assumes each sublist has the same nesting
-spec flatten(List :: list()) -> list().
flatten([H | T]) when is_list(H) ->
    H ++ flatten(T);
flatten([H | T]) when (H =:= undefined) orelse (H =:= nil) ->
    flatten(T);
flatten(H) ->
    H.

-spec flatten(List :: list(), Null :: fun(() -> list()), Length :: pos_integer()) ->
    list().
flatten([H | T], Null, Length) when is_list(H) ->
    if
        length(H) =:= Length -> H ++ flatten(T, Null, Length);
        true -> erlang:error(badarg)
    end;
flatten([H | T], Null, Length) when (H =:= undefined) orelse (H =:= nil) ->
    Null() ++ flatten(T, Null, Length);
flatten(H, _Null, _Length) ->
    H.

%% Finds the length to be padded to a binary of a given length and dividend.
%%
%% Defaults to 64 as the dividend, or the number of which the padded binary's
%% length needs to be a multiple.
-spec pad_len(Len :: non_neg_integer()) -> PadLen :: non_neg_integer().
pad_len(Len) ->
    pad_len(Len, 64).

-spec pad_len(Len :: non_neg_integer(), Dividend :: pos_integer()) -> PadLen :: non_neg_integer().
pad_len(Len, Dividend) ->
    case Len rem Dividend of
        0 ->
            0;
        X ->
            Dividend - X
    end.
