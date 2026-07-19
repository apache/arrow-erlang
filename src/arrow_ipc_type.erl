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

-module(arrow_ipc_type).
-moduledoc """
Provides types and functions to work with IPC types. This module provides
functions and types to produce the types in IPC Schema
[definitions](https://github.com/apache/arrow/blob/main/format/Schema.fbs).
These types are generated according to `Type` union in the schema. The types
have been represented in the form `{TypeName, Metadata}`, where `TypeName` is
the name of the type and is an atom, and `Metadata` is a map of all the metadata
associated with it. In case a type has no metadata associated with it, it is
represented as just `TypeName`
""".
-export([from_erlang/1]).
-export_type([
    ipc_type/0,
    int/0,
    floating_point/0,
    fixed_size_list/0,
    large_binary/0,
    large_list/0
]).

-include("arrow_array.hrl").

%% TODO: Add support for the commented types.
%%
%% Note that the types have been listed in the same order as the have been
%% defined in the Schema definitions.
-type ipc_type() ::
    %% null() |
    int()
    | floating_point()
    %% | binary()
    %% | utf8()
    %% | bool()
    %% | decimal()
    %% | data()
    %% | time()
    %% | timestamp()
    %% | interval()
    %% | list()
    %% | struct_()
    %% | union()
    %% | fixed_size_binary()
    | fixed_size_list()
    %% | map()
    %% | duration()
    | large_binary()
    %% | large_utf8()
    | large_list()
%% | run_end_encoded()
.
%% Represents and IPC Type. Of the from `{TypeName, Metadata}'.

-type int() :: {int, #{bit_width => pos_integer(), is_signed => boolean()}}.
%% Represents a Fixed-Size Primitive Layout Array of an integral type.

-type floating_point() :: {floating_point, #{precision => half | single | double}}.
%% Represents a Fixed-Size Primitive Layout Array of f16, f32 or f64.

-type fixed_size_list() :: {fixed_size_list, #{list_size => pos_integer()}}.
%% Represents a Fixed-Size List Layout Array.

-type large_binary() :: large_binary.
%% Represents a Variable-Size Binary Layout Array with 64 bit offsets.

-type large_list() :: large_list.
%% Represents a Variable-Size List Layout Array with 64 bit offsets.

%%%%%%%%%%%%%%%%%%%
%% from_erlang/1 %%
%%%%%%%%%%%%%%%%%%%

-doc """
Returns the IPC Type for an `t:arrow_array:array()`.
""".
-spec from_erlang(Array :: arrow_array:array()) -> Type :: ipc_type().
from_erlang(Array) ->
    case Array#array.layout of
        fixed_primitive -> primitive_type(Array#array.type);
        variable_binary -> large_binary;
        fixed_list -> {fixed_size_list, #{list_size => Array#array.element_len}};
        variable_list -> large_list
    end.

-spec primitive_type(Type :: arrow_type:arrow_longhand_type()) ->
    IPCType :: int() | floating_point().
primitive_type({s, Size}) ->
    {int, #{bit_width => Size, is_signed => true}};
primitive_type({u, Size}) ->
    {int, #{bit_width => Size, is_signed => false}};
primitive_type({f, Size}) ->
    {floating_point, #{
        precision =>
            case Size of
                16 -> half;
                32 -> single;
                64 -> double
            end
    }}.
