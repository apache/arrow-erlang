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

-module(arrow_ipc_record_batch).
-moduledoc """
Provides a record and functions to deal with RecordBatches
A [RecordBatch](https://github.com/apache/arrow/blob/16328f0ccc73b7df665b4a18feb6adf26b7aa0e2/format/Message.fbs#L81-L102) represents a list of equal length arrays and their
coresponding buffers. This module provides a record and a function to manage
all the metadata required to represent a RecordBatch. Metadata such as:

1.  `length`: The number of rows or records. In other words, the
    length of an array.
2.  `nodes`: A list of maps, where each map has the length and null
    count of an array
3.  `buffers`: A list of maps, where each map has the length and the
    offset (from the beginning of the message body) of a buffer of an
    array.

4.  `compression`: The compression applied on the body of the Record
    Batch. Can either by `undefined` (i.e. no compression), `zstd` for
    [Zstandard](https://facebook.github.io/zstd/), or `lz4_frame` for [LZ4
    Frame](https://android.googlesource.com/platform/external/lz4/+/HEAD/doc/lz4_Frame_format.md).
    Defaults to `undefined`.

Currently, compression is not supported, but it has been added for forwards
comapatibility.

You can find RecordBatches in the Arrow spec
[here](https://arrow.apache.org/docs/format/Columnar.html#recordbatch-message).
""".
-export([from_erlang/1]).
-export_type([field_node/0, buffer/0, record_batch/0]).

-include("arrow_ipc_record_batch.hrl").
-include("arrow_array.hrl").

-type field_node() :: #{length => pos_integer(), null_count => non_neg_integer()}.
-type buffer() :: #{offset => non_neg_integer(), length => pos_integer()}.
-type record_batch() :: #record_batch{}.

-doc """
Creates a RecordBatch given a list of arrays
""".
-spec from_erlang(Arrays :: [arrow_array:array()]) -> RecordBatch :: record_batch().
from_erlang(Arrays) ->
    FieldNodes = lists:map(
        fun(X) -> #{length => X#array.len, null_count => X#array.null_count} end, Arrays
    ),
    {Buffers, _} = lists:foldl(
        fun(Array, {Acc, CurOffset}) ->
            {Data, NewOffset} = array_data(Array, CurOffset),
            {lists:reverse(Data) ++ Acc, NewOffset}
        end,
        {[], 0},
        Arrays
    ),
    [Array | _] = Arrays,
    Length = Array#array.len,
    #record_batch{length = Length, nodes = FieldNodes, buffers = lists:reverse(Buffers)}.

%% Returns the buffer data for all the buffers and nested arrays in an array.
-spec array_data(Array :: arrow_array:array(), CurOffset :: non_neg_integer()) ->
    {[buffer()], NewOffset :: non_neg_integer()}.
array_data(Array, CurOffset) ->
    Bitmap = Array#array.validity_bitmap,
    Offsets = Array#array.offsets,
    Data = Array#array.data,

    {Buffers, SndOffset} =
        case {Bitmap, Offsets} of
            {undefined, undefined} ->
                {[], CurOffset};
            {undefined, _} ->
                {Buffer, Offset} = buffer_data(Offsets, CurOffset),
                {[Buffer], Offset};
            {_, undefined} ->
                {Buffer, Offset} = buffer_data(Bitmap, CurOffset),
                {[Buffer], Offset};
            _ ->
                {BitmapBuffer, Offset} = buffer_data(Bitmap, CurOffset),
                {OffsetBuffer, OtherOffset} = buffer_data(Offsets, Offset),
                {[BitmapBuffer, OffsetBuffer], OtherOffset}
        end,

    if
        is_record(Data, array) ->
            {DataBuffers, NewOffset} = array_data(Data, SndOffset),
            {Buffers ++ DataBuffers, NewOffset};
        true ->
            {DataBuffer, NewOffset} = buffer_data(Data, SndOffset),
            {Buffers ++ [DataBuffer], NewOffset}
    end.

-spec buffer_data(Buffer :: arrow_buffer:buffer(), CurOffset :: non_neg_integer()) ->
    {BufferData :: buffer(), NewOffset :: pos_integer()}.
buffer_data(Buffer, CurOffset) ->
    {
        #{offset => CurOffset, length => Buffer#buffer.length},
        arrow_buffer:size(Buffer) + CurOffset
    }.
