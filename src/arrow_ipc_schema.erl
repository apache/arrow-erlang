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

-module(arrow_ipc_schema).
-moduledoc """
Provides a record and functions to deal with Schemas A
[Schema](https://github.com/apache/arrow/blob/3456131ab7350bee5d9569ffd63d3f0ee713991c/format/Schema.fbs#L514-L530)[1]
represents a table, or a list of arrays of equal length. This module provides a
record and a function to manage all the metadata required to represent a schema.
Metadata such as:

1.  `endianness`: The Endianness of the table. One of `little` or
    `big`. Defaults to `little`.
2.  `fields`: The list of [fields](https://github.com/apache/arrow/blob/3456131ab7350bee5d9569ffd63d3f0ee713991c/format/Schema.fbs#L469-L492) in a table.
3.  `type`: The Layout of the column
4.  `custom_metadata`: A list of custom metadata in key-value format
5.  `features`: Any features used by the table which may not be
    present in other implementations of Arrow.

Currently, big endianness, custom metadata and features are not supported, but
they have been added for forwards comapatibility.

You can find Schemas in the Arrow spec
[here](https://arrow.apache.org/docs/format/Columnar.html#schema-message).
""".
-export([from_erlang/1]).
-export_type([endianness/0, feature/0, schema/0]).

-include("arrow_ipc_schema.hrl").

-doc "Endianness of the data. Either `little` or `big`.".
-type endianness() :: little | big.

-doc """
Features used in the data which may not be present in other implementations.
See the [definition](https://github.com/apache/arrow/blob/3456131ab7350bee5d9569ffd63d3f0ee713991c/format/Schema.fbs#L51-L78).
""".
-type feature() :: unused | dictionary_replacement | compressed_body.

-doc "Represents a schema".
-type schema() :: #schema{}.

-doc """
Creates a Schema given an ordered list of fields.
""".
-spec from_erlang(Fields :: [arrow_ipc_field:field()]) -> Schema :: schema().
from_erlang(Fields) ->
    #schema{fields = Fields}.
