// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

use rustler::types::Binary;
use rustler::{Atom, Env};

mod file;
mod message;
mod utils;

use file::Footer;
use message::Message;

mod atoms {
    rustler::atoms! {
        // TODO Organize atoms in a more systematic order

        // Versions

        v1,
        v2,
        v3,
        v4,
        v5,

        // Endianness

        little,
        big,

        // Layouts

        fixed_primitive,
        variable_binary,
        fixed_list,
        variable_list,

        // Message Types

        schema,
        record_batch,

        // Features

        unused,

        // Built-ins

        ok,
        undefined
    }
}

#[cfg(test)]
pub mod test {
    pub mod fixtures {
        use crate::file::{Block, Footer};
        use crate::message::{Header, Version};
        use crate::utils;
        use arrow_format::ipc;

        pub fn arrow_schema() -> ipc::Message {
            ipc::Message {
                version: ipc::MetadataVersion::V5,
                header: Some(ipc::MessageHeader::Schema(Box::new(ipc::Schema {
                    endianness: ipc::Endianness::Little,
                    fields: Some(vec![
                        ipc::Field {
                            name: Some("id".to_string()),
                            nullable: true,
                            type_: Some(ipc::Type::Int(Box::new(ipc::Int {
                                bit_width: 8,
                                is_signed: true,
                            }))),
                            dictionary: None,
                            children: None,
                            custom_metadata: None,
                        },
                        ipc::Field {
                            name: Some("name".to_string()),
                            nullable: true,
                            type_: Some(ipc::Type::LargeBinary(Box::new(ipc::LargeBinary {}))),
                            dictionary: None,
                            children: None,
                            custom_metadata: None,
                        },
                        ipc::Field {
                            name: Some("age".to_string()),
                            nullable: true,
                            type_: Some(ipc::Type::Int(Box::new(ipc::Int {
                                bit_width: 8,
                                is_signed: false,
                            }))),
                            dictionary: None,
                            children: None,
                            custom_metadata: None,
                        },
                        ipc::Field {
                            name: Some("annual_marks".to_string()),
                            nullable: true,
                            type_: Some(ipc::Type::FixedSizeList(Box::new(ipc::FixedSizeList {
                                list_size: 3,
                            }))),
                            dictionary: None,
                            children: Some(vec![ipc::Field {
                                name: None,
                                nullable: true,
                                type_: Some(ipc::Type::Int(Box::new(ipc::Int {
                                    bit_width: 8,
                                    is_signed: false,
                                }))),
                                dictionary: None,
                                children: None,
                                custom_metadata: None,
                            }]),
                            custom_metadata: None,
                        },
                    ]),
                    custom_metadata: None,
                    features: Some(vec![ipc::Feature::Unused]),
                }))),
                body_length: 0i64,
                custom_metadata: None,
            }
        }

        pub fn arrow_record_batch() -> ipc::Message {
            ipc::Message {
                version: ipc::MetadataVersion::V5,
                header: Some(ipc::MessageHeader::RecordBatch(Box::new(
                    ipc::RecordBatch {
                        length: 4,
                        nodes: Some(vec![
                            ipc::FieldNode {
                                length: 4,
                                null_count: 1,
                            },
                            ipc::FieldNode {
                                length: 4,
                                null_count: 1,
                            },
                            ipc::FieldNode {
                                length: 4,
                                null_count: 1,
                            },
                            ipc::FieldNode {
                                length: 4,
                                null_count: 1,
                            },
                        ]),
                        buffers: Some(vec![
                            ipc::Buffer {
                                offset: 0,
                                length: 1,
                            },
                            ipc::Buffer {
                                offset: 64,
                                length: 4,
                            },
                            ipc::Buffer {
                                offset: 128,
                                length: 1,
                            },
                            ipc::Buffer {
                                offset: 192,
                                length: 20,
                            },
                            ipc::Buffer {
                                offset: 256,
                                length: 15,
                            },
                            ipc::Buffer {
                                offset: 320,
                                length: 1,
                            },
                            ipc::Buffer {
                                offset: 384,
                                length: 4,
                            },
                            ipc::Buffer {
                                offset: 448,
                                length: 1,
                            },
                            ipc::Buffer {
                                offset: 512,
                                length: 2,
                            },
                            ipc::Buffer {
                                offset: 576,
                                length: 10,
                            },
                        ]),
                        compression: None,
                    },
                ))),
                body_length: 0i64,
                custom_metadata: None,
            }
        }

        pub fn footer() -> Footer {
            let Header::Schema(schema) = utils::schema().header else {
                panic!("Record Batch!")
            };
            Footer {
                version: Version::V5,
                schema: schema,
                dictionaries: vec![],
                record_batches: vec![Block {
                    offset: 128,
                    metadata_length: 32,
                    body_length: 512,
                }],
                custom_metadata: vec![],
            }
        }

        pub fn arrow_footer() -> ipc::Footer {
            let ipc::MessageHeader::Schema(schema) = arrow_schema().header.unwrap() else {
                panic!("This is not gonna panic!")
            };
            ipc::Footer {
                version: ipc::MetadataVersion::V5,
                schema: Some(schema),
                dictionaries: vec![].into(),
                record_batches: Some(vec![ipc::Block {
                    offset: 128,
                    meta_data_length: 32,
                    body_length: 512,
                }]),
                custom_metadata: None,
            }
        }
    }
}

/// Returns `:ok` on successful decodes.
///
/// This function tests Message's (and its components')
/// `rustler::types::Decoder` implementation(s), and is only used for testing
/// purposes.
#[rustler::nif]
fn test_decode(_msg: Message) -> Atom {
    atoms::ok()
}

/// Returns an example `Message` of a `Schema` or a `RecordBatch`.
///
/// This function tests Message's (and its components')
/// `rustler::types::Encoder` implementation(s), and is only used for testing
/// purposes.
#[rustler::nif]
fn test_encode(msg_type: Atom) -> Message {
    if msg_type == atoms::schema() {
        utils::schema()
    } else {
        utils::record_batch()
    }
}

/// Serializes a message into its correspondding flatbuffers.
///
/// This function serializes a message into its correspondding flatbuffers and
/// returns a binary
#[rustler::nif]
fn serialize_message(env: Env, message: Message) -> Binary {
    let flatbuffers = message.serialize_to_ipc();

    let mut erl_bin = rustler::types::OwnedBinary::new(flatbuffers.len()).unwrap();
    erl_bin.as_mut_slice().copy_from_slice(&flatbuffers);
    erl_bin.release(env)
}

/// Serializes a footer into its correspondding flatbuffers.
///
/// This function serializes a footer into its correspondding flatbuffers and
/// returns a binary
#[rustler::nif]
fn serialize_footer(env: Env, footer: Footer) -> Binary {
    let flatbuffers = footer.serialize_to_ipc();

    let mut erl_bin = rustler::types::OwnedBinary::new(flatbuffers.len()).unwrap();
    erl_bin.as_mut_slice().copy_from_slice(&flatbuffers);
    erl_bin.release(env)
}

rustler::init!("arrow_format_nif");
