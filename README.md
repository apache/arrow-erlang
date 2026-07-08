<!---
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
-->

# arrow-erlang

Erlang implementation of the [Apache Arrow](https://arrow.apache.org/) in-memory
columnar format.

As of right now, `arrow-erlang` only provides serialization (write) of Erlang
data structures into to Arrow. Support for deserialization (read) will be added
soon.

We provide support for the [Apache Arrow Columnar
Format](https://arrow.apache.org/docs/format/Columnar.html#physical-memory-layout)
and the [Apache Arrow IPC
Format](https://arrow.apache.org/docs/format/Columnar.html#serialization-and-interprocess-communication-ipc).
Support for [Flight RPC](https://arrow.apache.org/docs/format/Flight.html),
[Flight SQL](https://arrow.apache.org/docs/format/FlightSql.html), as well
conversion of Arrow into other formats like [Apache
Parquet](https://parquet.apache.org/), [Apache Avro](https://avro.apache.org/),
CSV and JSON is out of the scope of the project.

## Build

In addition to an Erlang installation, you will need a Rust installation with
`cargo`. You can then add the following to your rebar.config:

``` erlang
{arrow, {git, "https://github.com/apache/arrow-erlang.git"}}
```

And compile!

    $ rebar3 compile

## Format Support

This implementation is still a work in progress. As mentioned earlier, we do not
have read functionality as of right now, only write.

We support the following primitive data types:

- Int 8/16/32/64
- UInt 8/16/32/64
- Float 32/64
- Fixed Size Binary
- Binary
- Large Binary

and the following nested data types:

- Fixed Size List
- List
- Large List

support for the other data types (both primitive and nested) will be added soon.

## IPC Format Support

Currently we support all the 3 "formats":

- Encapsulated Message Format
- Stream Format
- File Format

and the following message types:

- Schema
- RecordBatch

Support for the following will be added shortly:

- Buffer compression
- Endianness conversion
- Custom schema metadata

Support for the following will be added post v0.1.0:

- Dictionaries
- Replacement dictionaries
- Delta dictionaries
- Tensors
- Sparse Tensors
