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

-module(arrow_bitmap).
-moduledoc """
Validity Bitmap implementation for `arrow`.

Defines a function `validity_bitmap/1` to return the [Validity
Bitmap](https://arrow.apache.org/docs/format/Columnar.html#validity-bitmaps)
along with the [Null
Count](https://arrow.apache.org/docs/format/Columnar.html#null-count), of an
Array.

An important thing to consider about our implementation of the Null Count is
that we need to support both `undefined` and `nil` as null values as they are
the conventions for null values in Erlang, and Elixir respectively.

There are 5 important characteristics to remember about the validity bitmap:

1. A null value is represented by a 0 bit, and a non null value by a 1 bit.

2. Every 8 elements's validities are batched into a byte, which are then
   reversed as Arrow uses least-significant bit (LSB) numbering (more in
   attached reference).
 
3. If a "batch" consists of less than 8 elements, its validity needs to be
   padded by 0 bits so that it can make a byte.
 
4. Each byte is stored in a slot of a Buffer (see docs for `arrow_buffer`). This
   buffer with the validities of each batch of 8 elements make up what is called
   the Validity Bitmap.

5. If the Null Count is 0, we can allocate the Validity Bitmap as a NULL pointer
   (which in Erlang's case is `undefined`).
""".
-export([validity_bitmap/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Validity Bitmap & Null Count %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-doc """
Returns the Validity Bitmap along with the Null Count, of an Array.
""".
%% TODO: Bitmap should be arrow_buffer:buffer() | undefined
%% Investigate why Dialyzer isn't raising, and potentially
%% run eqWAlizer via ELP on the CI.
-spec validity_bitmap(Value :: [arrow_type:native_type()] | list()) ->
    {Bitmap :: arrow_buffer:buffer(), non_neg_integer()}.
validity_bitmap(Value) ->
    case (lists:member(undefined, Value)) orelse (lists:member(nil, Value)) of
        true ->
            bitmap(Value, <<>>, 0);
        false ->
            {undefined, 0}
    end.

-spec bitmap(
    Value :: [arrow_type:native_type()],
    Acc :: binary(),
    NullCount :: non_neg_integer()
) -> {Bitmap :: arrow_buffer:buffer(), NullCount :: non_neg_integer()}.
bitmap([X1, X2, X3, X4, X5, X6, X7, X8 | Rest], Acc, NullCount) ->
    %% By assigning B8 as X1's validity, we are following LSB numbering.
    B8 = validity(X1),
    B7 = validity(X2),
    B6 = validity(X3),
    B5 = validity(X4),
    B4 = validity(X5),
    B3 = validity(X6),
    B2 = validity(X7),
    B1 = validity(X8),

    bitmap(
        Rest,
        <<Acc/binary, B1:1, B2:1, B3:1, B4:1, B5:1, B6:1, B7:1, B8:1>>,
        NullCount + (8 - (B1 + B2 + B3 + B4 + B5 + B6 + B7 + B8))
    );
bitmap([], Acc, NullCount) ->
    {arrow_buffer:from_erlang(Acc, {bin, undefined}), NullCount};
bitmap(LeftOver, Acc, NullCount) ->
    Validities = lists:map(fun(X) -> validity(X) end, LeftOver),
    Len = length(Validities),
    Nulls = Len - lists:sum(Validities),

    %% Here we both pad as well as LSB number at one pass.
    Padded = lists:duplicate(arrow_utils:pad_len(Len, 8), 0) ++ lists:reverse(Validities),

    [B1, B2, B3, B4, B5, B6, B7, B8] = Padded,
    bitmap(
        [],
        <<Acc/binary, B1:1, B2:1, B3:1, B4:1, B5:1, B6:1, B7:1, B8:1>>,
        NullCount + Nulls
    ).

-spec validity(X :: arrow_type:native_type()) -> Validity :: 0 | 1.
validity(X) ->
    if
        (X =:= nil) orelse (X =:= undefined) ->
            0;
        true ->
            1
    end.
