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

-include("arrow_ipc_schema.hrl").
-include("arrow_ipc_record_batch.hrl").
-include("arrow_array.hrl").

-record(message, {
    version = v5 :: arrow_ipc_message:metadata_version(),
    header :: #schema{} | #record_batch{},
    body_length :: non_neg_integer(),
    custom_metadata = [] :: [arrow_ipc_message:key_value()],

    %% This field is unique to arrow.
    %% The rest are from the flatbuffers definitions.
    body :: [arrow_array:array()] | undefined
}).
