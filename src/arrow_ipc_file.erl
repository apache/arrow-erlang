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

-module(arrow_ipc_file).
-moduledoc """
Provides records and functions to deal with the IPC File. The [IPC
File](https://arrow.apache.org/docs/format/Columnar.html#ipc-file-format) is an
extension of the [IPC Stream](
https://arrow.apache.org/docs/format/Columnar.html#ipc-streaming-format) that
supports random access with the help of a footer which contains the offsets of
all the messages.
""".
-export([from_erlang/2, to_ipc/1]).

-include("arrow_ipc_message.hrl").
-include("arrow_ipc_file.hrl").

-type file() :: #file{}.

%%%%%%%%%%%%%%%%%%%
%% from_erlang/2 %%
%%%%%%%%%%%%%%%%%%%

-doc """
Creates a file given a schema message and a list of record batch messages.
""".
-spec from_erlang(
    Schema :: arrow_ipc_message:message(), RecordBatches :: [arrow_ipc_message:message()]
) -> file().
from_erlang(SchemaMsg, RecordBatches) ->
    SchemaEMF = arrow_ipc_message:to_ipc(SchemaMsg),
    {RecordBatchBlocks, EMFs} = blocks(byte_size(SchemaEMF), RecordBatches, [], []),
    Schema = SchemaMsg#message.header,
    Footer = #footer{
        version = v5, schema = Schema, dictionaries = [], record_batches = RecordBatchBlocks
    },
    Stream = arrow_ipc_message:to_stream([SchemaEMF | EMFs]),
    #file{footer = Footer, body = Stream}.

%% Returns the blocks as wells as the intermediate EMFs used to generate each block.
-spec blocks(
    Offset :: non_neg_integer(),
    Messages :: [arrow_ipc_message:message()],
    Blocks :: [#block{}],
    EMFs :: [binary()]
) -> {Blocks :: [#block{}], EMFs :: [binary()]}.
blocks(_Offset, [], Blocks, EMFs) ->
    {lists:reverse(Blocks), lists:reverse(EMFs)};
blocks(Offset, [H | T], Blocks, EMFs) ->
    EMF = arrow_ipc_message:to_ipc(H),
    MetadataLen = arrow_ipc_message:metadata_len(EMF),
    Block = #block{
        offset = Offset, metadata_length = MetadataLen, body_length = H#message.body_length
    },

    blocks(Offset + byte_size(EMF), T, [Block | Blocks], [EMF | EMFs]).

%%%%%%%%%%%%%%
%% to_ipc/1 %%
%%%%%%%%%%%%%%

-doc """
Serializes a file into the IPC File Format.
""".
-spec to_ipc(File :: file()) -> SerializedFile :: binary().
to_ipc(File) ->
    Footer = arrow_format_nif:serialize_footer(File#file.footer),
    Sz = byte_size(Footer),
    <<"ARROW1", "00", (File#file.body)/binary, Footer/bitstring, Sz:4/little-signed-integer-unit:8,
        "ARROW1">>.
