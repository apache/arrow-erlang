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

%% @doc Buffer implementation for `arrow'.
%% This module adds suppport for buffers, or Contiguous Memory Regions.
%%
%% There are multiple things to know about buffers[1]:
%%
%% <ol>
%%  <li>
%%      Each value it stores is called an element or a slot[2].
%%  </li>
%%  <li>
%%      Each slot's length (in bytes) is a positive integer. As a result when we
%%      say that a slot has a length of 1, we mean that each slot has a length of
%%      1 byte.
%%  </li>
%%  <li>
%%      The buffer's length in the metadata refers to the unpadded binary's size in bytes.
%%  </li>
%%  <li>
%%      All buffers have a size that is a multiple of 64. If their data's length
%%      is not a multiple of 64, it must be padded (in this implementation, by
%%      zeros).
%%  </li>
%%  <li>
%%      Null values are represented in this implementation by zeros.
%%  </li>
%%  <li>
%%      In this implementation buffers can be initialized from raw bytes as data
%%      apart datatypes supported by Arrow. This is so that the Validity Bitmap
%%      Buffer can be initialized.
%%  </li>
%% </ol>
%%
%% [1]: [https://arrow.apache.org/docs/format/Glossary.html#term-buffer]
%%
%% [2]: [https://arrow.apache.org/docs/format/Glossary.html#term-slot]
%% @end
-module(arrow_buffer).
-export([from_erlang/2, from_erlang/3, to_arrow/1, to_erlang/1, size/1]).

-include("arrow_buffer.hrl").

-export_type([buffer/0]).

-doc "Represents an Arrow Buffer.".
-type buffer() :: arrow_buffer:buffer().

%% @doc Creates a new buffer from a list of Erlang values or binaries, given its
%% type
%% @end
-spec from_erlang(
    Value :: [arrow_type:native_type()] | binary(),
    Type :: arrow_type:arrow_longhand_type()
) ->
    Buffer :: arrow_buffer:buffer().
from_erlang(Data, Type) ->
    Len =
        case Type of
            {bin, undefined} ->
                undefined;
            _ ->
                length(Data)
        end,
    from_erlang(Data, Type, Len).

%% @doc Creates a new buffer from a list of Erlang values or binaries, given its
%% type and length
%% @end
-spec from_erlang(
    Data :: [arrow_type:native_type()] | binary(),
    Type :: arrow_type:arrow_longhand_type(),
    DataLen :: pos_integer() | undefined
) ->
    Buffer :: arrow_buffer:buffer().
from_erlang(Data, Type, DataLen) ->
    Len =
        case Type of
            {bin, undefined} when is_binary(Data) ->
                byte_size(Data);
            {bin, undefined} ->
                erlang:error(badarg);
            _ ->
                DataLen * arrow_type:byte_length(Type)
        end,
    #buffer{type = Type, length = Len, data = Data}.

%% @doc Returns an Arrow buffer binary given a buffer.
%% @end
-spec to_arrow(Buffer :: arrow_buffer:buffer()) -> binary().
to_arrow(Buffer) when is_record(Buffer, buffer) ->
    Type = Buffer#buffer.type,
    Bin =
        case Type of
            {bin, undefined} ->
                Buffer#buffer.data;
            _ ->
                ElementLen = arrow_type:byte_length(Type),
                <<(slot(X, Type, ElementLen)) || X <- Buffer#buffer.data>>
        end,
    pad(Bin, arrow_utils:pad_len(byte_size(Bin)));
to_arrow(_Buffer) ->
    erlang:error(badarg).

%% @doc Returns a list of Erlang values or binaries from a buffer.
%% @end
-spec to_erlang(Buffer :: arrow_buffer:buffer()) -> [arrow_type:native_type()].
to_erlang(Buffer) when is_record(Buffer, buffer) ->
    Buffer#buffer.data;
to_erlang(_Buffer) ->
    erlang:error(badarg).

%% @doc Returns the size of the buffer inclusive of padding in bytes.
-spec size(Buffer :: arrow_buffer:buffer()) -> pos_integer().
size(Buffer) ->
    Len = Buffer#buffer.length * 8,
    round((Len + arrow_utils:pad_len(Len)) / 8).

-spec slot(
    Value :: arrow_type:native_type(),
    Type :: arrow_type:arrow_longhand_type(),
    ElementLen :: pos_integer() | undefined
) -> binary().
slot(Value, _Type, ElementLen) when (Value =:= undefined) orelse (Value =:= nil) ->
    pad(<<>>, ElementLen);
slot(Value, Type, _ElementLen) ->
    arrow_type:serialize(Value, Type).

-spec pad(Binary :: binary(), PadLen :: pos_integer() | undefined) -> binary().
pad(_Binary, undefined) ->
    <<>>;
pad(Binary, PadLen) when is_integer(PadLen) ->
    <<Binary/bitstring, <<0:(PadLen * 8)>>/bitstring>>.
