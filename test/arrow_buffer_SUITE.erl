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

-module(arrow_buffer_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-include("arrow_buffer.hrl").

all() ->
    [
        valid_length_on_from_erlang,
        valid_type_on_from_erlang,
        valid_data_on_from_erlang,
        crashes_on_list_of_binaries_on_from_erlang,

        valid_regular_buffer_data_on_to_arrow,
        valid_binary_buffer_data_on_to_arrow,
        crashes_on_non_buffer_input_on_to_arrow,

        to_erlang,

        size
    ].

%%%%%%%%%%%%%%%%%%%
%% from_erlang/2 %%
%%%%%%%%%%%%%%%%%%%

valid_length_on_from_erlang(_Config) ->
    %% With Fixed-Size data
    Buffer1 = arrow_buffer:from_erlang([1, 2, undefined, 3, nil], {s, 8}),
    ?assertEqual(Buffer1#buffer.length, 5),

    Buffer2 = arrow_buffer:from_erlang([1, 2, undefined, 3, nil], {s, 8}, 5),
    ?assertEqual(Buffer2#buffer.length, 5),

    %% With binaries
    Buffer3 = arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined}),
    ?assertEqual(Buffer3#buffer.length, 3),

    Buffer4 = arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined}, 3),
    ?assertEqual(Buffer4#buffer.length, 3).

valid_type_on_from_erlang(_Config) ->
    Buffer1 = arrow_buffer:from_erlang([1, 2, 3], {s, 32}),
    ?assertEqual(Buffer1#buffer.type, {s, 32}),

    Buffer2 = arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined}),
    ?assertEqual(Buffer2#buffer.type, {bin, undefined}).

valid_data_on_from_erlang(_Config) ->
    Buffer1 = arrow_buffer:from_erlang([1, 2, 3], {s, 32}),
    ?assertEqual(Buffer1#buffer.data, [1, 2, 3]),

    Buffer2 = arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined}),
    ?assertEqual(Buffer2#buffer.data, <<1, 2, 3>>).

crashes_on_list_of_binaries_on_from_erlang(_Config) ->
    ?assertError(
        badarg, arrow_buffer:from_erlang([<<1, 2>>, undefined, <<3>>, nil], {bin, undefined})
    ).

%%%%%%%%%%%%%%%%
%% to_arrow/1 %%
%%%%%%%%%%%%%%%%

valid_regular_buffer_data_on_to_arrow(_Config) ->
    %% Works without any nulls
    Bin1 = arrow_buffer:to_arrow(arrow_buffer:from_erlang([1, 2, 3], {s, 8})),
    Data1 =
        <<1/little-signed-integer, 2/little-signed-integer, 3/little-signed-integer,
            (pad(61))/bitstring>>,
    ?assertEqual(Bin1, Data1),

    %% Works with undefined and nil
    Bin2 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang([1, 2, undefined, 3], {s, 8})
    ),
    Data2 =
        <<1/little-signed-integer, 2/little-signed-integer, 0, 3/little-signed-integer,
            (pad(60))/bitstring>>,
    ?assertEqual(Bin2, Data2),

    Bin3 = arrow_buffer:to_arrow(arrow_buffer:from_erlang([1, 2, nil, 3], {s, 8})),
    Data3 = Data2,
    ?assertEqual(Bin3, Data3),

    Bin4 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang([1, 2, undefined, nil, 3], {s, 8})
    ),
    Data4 =
        <<1/little-signed-integer, 2/little-signed-integer, 0, 0, 3/little-signed-integer,
            (pad(59))/bitstring>>,
    ?assertEqual(Bin4, Data4).

valid_binary_buffer_data_on_to_arrow(_Config) ->
    Data =
        <<1/little-signed-integer, 2/little-signed-integer, 3/little-signed-integer,
            (pad(61))/bitstring>>,

    %% Works without any nulls
    Bin1 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined})
    ),
    ?assertEqual(Bin1, Data),

    %% Works with undefined and nil
    Bin2 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined})
    ),
    ?assertEqual(Bin2, Data),

    Bin3 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined})
    ),
    ?assertEqual(Bin3, Data),

    Bin4 = arrow_buffer:to_arrow(
        arrow_buffer:from_erlang(<<1, 2, 3>>, {bin, undefined})
    ),
    ?assertEqual(Bin4, Data).

crashes_on_non_buffer_input_on_to_arrow(_Config) ->
    ?assertError(badarg, arrow_buffer:to_arrow(bar)).

%%%%%%%%%%%%%%%%%
%% to_erlang/1 %%
%%%%%%%%%%%%%%%%%

to_erlang(_Config) ->
    Data = [1, 2, undefined, 3, nil],
    ?assertEqual(arrow_buffer:to_erlang(arrow_buffer:from_erlang(Data, {s, 8})), Data),

    ?assertError(badarg, arrow_buffer:to_erlang([1, 2, 3])).

%%%%%%%%%%%%
%% size/1 %%
%%%%%%%%%%%%

size(_Config) ->
    Buffer = arrow_buffer:from_erlang([1, 2, 3], {s, 8}),
    ?assertEqual(arrow_buffer:size(Buffer), byte_size(arrow_buffer:to_arrow(Buffer))).

%%%%%%%%%%%
%% Utils %%
%%%%%%%%%%%

%% We need to use a simpler alternate pad function to test the buffer's pad
%% output.

pad(X) ->
    arrow_test_utils:pad(X).
