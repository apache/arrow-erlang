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

-module(arrow_ipc_field).
-moduledoc """
Provides a record and functions to deal with individual fields in
a Schema

A
[Field](https://github.com/apache/arrow/blob/3456131ab7350bee5d9569ffd63d3f0ee713991c/format/Schema.fbs#L469-L492)
represents a single column in a table (which is represented by a
[Schema](https://github.com/apache/arrow/blob/3456131ab7350bee5d9569ffd63d3f0ee713991c/format/Schema.fbs#L514-L530).
This module provides a record and a function to manage all the metadata required
to represent a column. Metadata such as:

1.  `name`: The Name of the column. This can either be a string or
     null.
2.  `nullable`: A boolean representing whether a column can have null
    values. Generally true.
3.  `type`: The Type of the column, and is of type
    `t:arrow_ipc_type:ipc_type/0`
4.  `dictionary`: A boolean representing if the column is dictionary
    encoded
5.  `children`: The child fields of a nested datatype
6.  `custom_metadata`: A list of custom metadata in key-value format

Currently, dictionary encoding and custom metadata are not supported, but
they have been added for forwards comapatibility.
""".
-export([from_erlang/1, from_erlang/2, from_erlang/3]).

-include("arrow_ipc_schema.hrl").

-doc """
Creates a field given the type of the column. Assigns the name as
`undefined`.
""".
-spec from_erlang(Type :: arrow_ipc_type:ipc_type()) -> Field :: #field{}.
from_erlang(Type) ->
    from_erlang(Type, undefined, []).

-doc """
Creates a field given the type and name of the column.
""".
-spec from_erlang(Type :: arrow_ipc_type:ipc_type(), Name :: string() | undefined) ->
    Field :: #field{}.
from_erlang(Type, Name) ->
    from_erlang(Type, Name, []).

-doc """
Creates a field given the type, name and children of the column.
""".
-spec from_erlang(
    Type :: arrow_ipc_type:ipc_type(), Name :: string() | undefined, Children :: [#field{}]
) ->
    Field :: #field{}.
from_erlang(Type, Name, Children) ->
    #field{name = Name, type = Type, children = Children}.
