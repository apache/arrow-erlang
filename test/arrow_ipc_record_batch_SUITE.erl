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

-module(arrow_ipc_record_batch_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-include("arrow_ipc_record_batch.hrl").
-include("arrow_array.hrl").

-include("arrow_ipc_marks_data.hrl").

all() ->
    [
        valid_length_on_from_erlang,
        valid_nodes_on_from_erlang,
        valid_buffers_on_from_erlang,
        valid_compression_on_from_erlang,
        body_length
    ].

valid_length_on_from_erlang(_Config) ->
    ?assertEqual((?RecordBatch)#record_batch.length, 4).

valid_nodes_on_from_erlang(_Config) ->
    FieldNodes = lists:duplicate(4, #{length => 4, null_count => 1}),
    ?assertEqual((?RecordBatch)#record_batch.nodes, FieldNodes).

valid_buffers_on_from_erlang(_Config) ->
    ID = [#{offset => 0, length => 1}, #{offset => 64, length => 4}],
    Name = [
        #{offset => 128, length => 1},
        #{offset => 192, length => 20},
        #{offset => 256, length => 15}
    ],
    Age = [#{offset => 320, length => 1}, #{offset => 384, length => 4}],
    Marks =
        [
            #{offset => 448, length => 1},
            #{offset => 512, length => 2},
            #{offset => 576, length => 10}
        ],
    Buffers = ID ++ Name ++ Age ++ Marks,

    ?assertEqual((?RecordBatch)#record_batch.buffers, Buffers).

valid_compression_on_from_erlang(_Config) ->
    ?assertEqual((?RecordBatch)#record_batch.compression, undefined).

body_length(_Config) ->
    erlang:display(?Body),
    ?assertEqual(arrow_ipc_record_batch:body_length(?RecordBatch), byte_size(?Body)).
