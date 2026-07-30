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

%% This header file contains data for testing various modules for IPC.
%% It includes things from Schema definitions to IPC streams.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Schema Encapsulated Message %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(IDField,
    arrow_ipc_field:from_erlang({int, #{bit_width => 8, is_signed => true}}, "id")
).
-define(NameField, arrow_ipc_field:from_erlang(large_binary, "name")).
-define(AgeField,
    arrow_ipc_field:from_erlang({int, #{bit_width => 8, is_signed => false}}, "age")
).
-define(AnnualMarksField,
    arrow_ipc_field:from_erlang(
        {fixed_size_list, #{list_size => 3}}, "annual_marks", [
            arrow_ipc_field:from_erlang(
                {int, #{bit_width => 8, is_signed => false}}
            )
        ]
    )
).
-define(Fields, [?IDField, ?NameField, ?AgeField, ?AnnualMarksField]).
-define(Schema, arrow_ipc_schema:from_erlang(?Fields)).
-define(SchemaMsg, arrow_ipc_message:from_erlang(?Schema)).
-define(SchemaEMF, arrow_ipc_message:to_ipc(?SchemaMsg)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RecordBatch Encapsulated Message %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(ID, arrow_array:from_erlang(fixed_primitive, [0, 1, 2, undefined], {s, 8})).
-define(Name,
    arrow_array:from_erlang(
        variable_binary, [<<"alice">>, <<"bob">>, <<"charlie">>, undefined], {bin, undefined}
    )
).
-define(Age, arrow_array:from_erlang(fixed_primitive, [10, 20, 30, undefined], {s, 8})).
-define(AnnualMarks,
    arrow_array:from_erlang(
        fixed_list, [[100, 97, 98], [100, 99, 96], [100, 98, 95], undefined], {s, 8}
    )
).
-define(Columns, [?ID, ?Name, ?Age, ?AnnualMarks]).
-define(RecordBatch, arrow_ipc_record_batch:from_erlang(?Columns)).
-define(RecordBatchMsg, arrow_ipc_message:from_erlang(?RecordBatch, ?Columns)).
-define(RecordBatchEMF, arrow_ipc_message:to_ipc(?RecordBatchMsg)).
-define(Body, <<<<(arrow_array:to_arrow(Array))/binary>> || Array <- ?Columns>>).

%%%%%%%%%%%%%%%%
%% IPC Stream %%
%%%%%%%%%%%%%%%%

-define(Stream, arrow_ipc_message:to_stream([?SchemaMsg, ?RecordBatchMsg])).

%%%%%%%%%%%%%%
%% IPC File %%
%%%%%%%%%%%%%%

-define(File, arrow_ipc_file:from_erlang(?SchemaMsg, [?RecordBatchMsg])).
-define(SerializedFile, arrow_ipc_file:to_ipc(?File)).
