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

-module(arrow_variable_binary_array).
-moduledoc """
Provides support for Arrow's Variable-Sized Binary Layout.

The [Variable-Sized Binary
Layout](https://arrow.apache.org/docs/format/Columnar.html#variable-size-binary-layout)
provides support for storing binaries of varying length in a way similar to the
primitive layout, i.e. in a 1 Dimensional Array.
""".
-behaviour(arrow_array).

-export([from_erlang/1, from_erlang/2]).

-include("arrow_array.hrl").

-doc """
Creates a Variable-Sized Binary Array given the values and options in the form of
a map, from its erlang representation.
""".
-spec from_erlang(Values :: [arrow_type:native_type()], Opts :: map()) ->
    Array :: arrow_array:array().
from_erlang(Values, _Opts) ->
    from_erlang(Values).

-doc """
Creates a Variable-Sized Binary Array given the values
""".
-spec from_erlang(Values :: [arrow_type:native_type()]) -> Array :: arrow_array:array().
from_erlang(Values) ->
    Len = length(Values),
    {Bitmap, NullCount} = arrow_bitmap:validity_bitmap(Values),
    Offsets = arrow_offsets:new(Values, {bin, undefined}, Len),
    Bin = <<X || X <- Values, X =/= undefined, X =/= nil>>,
    Data = arrow_buffer:from_erlang(Bin, {bin, undefined}),
    #array{
        layout = variable_binary,
        type = {bin, undefined},
        len = Len,
        null_count = NullCount,
        validity_bitmap = Bitmap,
        offsets = Offsets,
        data = Data
    }.
