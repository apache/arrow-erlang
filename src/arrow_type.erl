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

-module(arrow_type).
-moduledoc """
Provides representation for as well as functions for working with Arrow
specific datatypes.

This module provides a longhand (a 2 tuple) as well as a shorthand (an atom)
represenations for representing a primitive types. Additionally it represents
Nested Types (i.e. Lists) as well as Native Types (i.e. Erlang Native Types
that are supported by this package).

Generally, when we say an array A has type X, we mean that each element in A
has type X. Thus, an array of type of `Int8` would look like `[1, 2, 3]`, but
an array of type `List<Int8>` would look like `[[1, 2], [3]]`.

## Primitive Types

A Primitive Type is any type that refers to a single value (as opposed to a
list of values). Currently it includes Booleans, Signed Integers, Unsigned
Integers, Floats and Binaries. Both a longhand and shorthand syntax had been
provided to initiate a type.

The following is a comprehensive list of all supported primitive types:

1.  Booleans
2.  Signed Integers: Includes `Int 8`, `Int 16`, `Int 32` and
    `Int 64`
3.  Unsigned Integers: Includes `UInt 8`, `UInt 16`, `UInt 32` and
    `UInt 64`
4.  Floats: Includes `Float 16`, `Float 32` and `Float 64`
5.  Binaries

### Shorthand Syntax

In the shorthand syntax, you can just use a single atom to refer to a type,
such that the atom is `<name><size>`. The name is a single letter that refers
to the type, and the size is that type's size in bits. Take the example of
`Int 8`. Its name is `s`, and size is `8`. Thus in shorthand, it is `s8`. In
the case of datatypes without variations, such as Booleans and Binaries, they
are represented by just their datatype. Do note that internally the longhand
syntax is used.

Here you can find the name of each table:

| Type             | Name  | Example Atom |
|------------------|-------|--------------|
| Booleans         | N/A   | `bool`       |
| Signed Integer   | `s`   | `s64`        |
| Unsigned Integer | `u`   | `u16`        |
| Float            | `f`   | `f32`        |
| Binaries         | N/A   | `bin`        |

Types that are shorthand are under the `t:arrow_shorthand_type/0` and
`arrow_short_*()` types.

### Longhand Syntax

In longhand syntax, you use a 2 tuple to to refer to the type, such that the
tuple is `{Name, Size}`. Thus, `Int 8` would be represented as `{s, 8}`. Do
note that in the case or Booleans and Binaries their `Size` is `undefined`, as
the have variable or undefined size.

Types that are longhand are under the `t:arrow_longhand_type/0` and
`arrow_long_*()` types.

### Nested Types

A Nested Type is any data structure that supports nesting. This can include
Lists, FixedLists, Maps, Structs and more, but is curently limited to
FixedLists. Nested Types are represented using a 3 tuple: `{NestedType, Type,
Length}`. `NestedType` refers to the data structure that is nesting your
primitive type. `Type` refers to the type that is being nested in the data
structure. Do note that `Type` can be a Primitive Type, or another Nested
Type. Both the shorthand and the longhand syntax can be used or Primitive
Types.`Length` refers to the length of each element, and will only be
required to represent FixedLists.

It is important to remember while nesting that the type refers to the type of
each element in an array. A list of `Int8` is 2 dimensional, and a list of
`List<Int8>` is 3 dimensional.

## Native Type

A Native Type is any Erlang Datatype that can be serialized by `arrow`,
and is represented by the type `t:native_type/0`. It currently only includes
values that are primitive in nature such as booleans, integers, floats,
binaries, and additionally the atoms `undefined` and `nil` to represent a
`NULL` value.
""".
-export([normalize/1, bit_length/1, byte_length/1, serialize/2]).
-export_type([
    arrow_type/0,
    arrow_primitive_type/0,
    arrow_longhand_type/0,
    arrow_shorthand_type/0,

    %% Booleans
    arrow_bool/0,
    arrow_long_bool/0,
    arrow_short_bool/0,

    %% Signed Integers
    arrow_int/0,
    arrow_long_int/0,
    arrow_short_int/0,

    %% Unsigned Integers
    arrow_uint/0,
    arrow_long_uint/0,
    arrow_short_uint/0,

    %% Floats
    arrow_float/0,
    arrow_long_float/0,
    arrow_short_float/0,

    %% Binaries
    arrow_bin/0,
    arrow_long_bin/0,
    arrow_short_bin/0,

    %% Nested Type
    arrow_nested_type/0,
    arrow_short_nested_type/0,
    arrow_long_nested_type/0,

    native_type/0
]).

-type arrow_type() :: arrow_primitive_type() | arrow_nested_type().
%% Any type that is native to Apache Arrow that is supported by `arrow'

-type arrow_primitive_type() ::
    arrow_bool()
    | arrow_int()
    | arrow_uint()
    | arrow_float()
    | arrow_bin().
%% Any primitive logical type in Apache Arrow that is supported by `arrow'.

-type arrow_longhand_type() ::
    arrow_long_bool()
    | arrow_long_int()
    | arrow_long_uint()
    | arrow_long_float()
    | arrow_long_bin()
    | arrow_long_nested_type().
%% Longhand syntax of any type.

-type arrow_shorthand_type() ::
    arrow_short_bool()
    | arrow_short_int()
    | arrow_short_uint()
    | arrow_short_float()
    | arrow_short_bin()
    | arrow_short_nested_type().
%% Shorthand syntax of any type.

%%%%%%%%%%%%%%
%% Booleans %%
%%%%%%%%%%%%%%

-type arrow_bool() :: arrow_long_bool() | arrow_short_bool().
%% Apache Arrow Boolean. One of `True' or `False'

-type arrow_long_bool() :: {bool, undefined}.
%% Longhand representation for booleans in Apache Arrow.

-type arrow_short_bool() :: bool.
%% Shorthand representation for booleans in Apache Arrow.

%%%%%%%%%%%%%%%%%%%%%
%% Signed Integers %%
%%%%%%%%%%%%%%%%%%%%%

-type arrow_int() :: arrow_long_int() | arrow_short_int().
%% Any signed integer in Apache Arrow. Includes `Int 8', `Int 16', `Int 32' and
%% `Int 64'.

-type arrow_long_int() :: {s, 8} | {s, 16} | {s, 32} | {s, 64}.
%% Longhand representation for any signed integer in Apache Arrow. Includes
%% `Int 8', `Int 16', `Int 32' and `Int 64'.

-type arrow_short_int() :: s8 | s16 | s32 | s64.
%% Shorthand representation for any signed integer in Apache Arrow. Includes
%% `Int 8', `Int 16', `Int 32' and `Int 64'.

%%%%%%%%%%%%%%%%%%%%%%%
%% Unsigned Integers %%
%%%%%%%%%%%%%%%%%%%%%%%

-type arrow_uint() :: arrow_long_uint() | arrow_short_uint().
%% Any unsigned integer in Apache Arrow. Includes `UInt 8', `UInt 16', `UInt 32'
%% and `UInt 64'.

-type arrow_long_uint() :: {u, 8} | {u, 16} | {u, 32} | {u, 64}.
%% Longhand representation for any unsigned integer in Apache Arrow. Includes
%% `UInt 8', `UInt 16', `UInt 32' and `UInt 64'.

-type arrow_short_uint() :: u8 | u16 | u32 | u64.
%% Shorthand representation for any unsigned integer in Apache Arrow. Includes
%% `UInt 8', `UInt 16', `UInt 32' and `UInt 64'.

%%%%%%%%%%%%
%% Floats %%
%%%%%%%%%%%%

-type arrow_float() :: arrow_long_float() | arrow_short_float().
%% Any floating point number in Apache Arrow. Includes `Float 16', `Float 32'
%% and `Float 64'.

-type arrow_long_float() :: {f, 16} | {f, 32} | {f, 64}.
%% Longhand representation for any floating point number in Apache Arrow.
%% Includes `Float 16', `Float 32' and `Float 64'.

-type arrow_short_float() :: f16 | f32 | f64.
%% Shorthand representation for any floating point number in Apache Arrow.
%% Includes `Float 16', `Float 32' and `Float 64'.

%%%%%%%%%%%%%%
%% Binaries %%
%%%%%%%%%%%%%%

-type arrow_bin() :: arrow_long_bin() | arrow_short_bin().
%% Any binary whose length in bits is a multiple of 8.

-type arrow_long_bin() :: {bin, undefined}.
%% Longhand representation for binaries in Apache Arrow.

-type arrow_short_bin() :: bin.
%% Shorthand representation for booleans in Apache Arrow.

%%%%%%%%%%%%%%%%%%
%% Nested Types %%
%%%%%%%%%%%%%%%%%%

-type arrow_nested_type() :: arrow_short_nested_type() | arrow_long_nested_type().
%% A Nested Type.

-type arrow_short_nested_type() ::
    {fixed_list, arrow_short_nested_type() | arrow_shorthand_type(), pos_integer()}
    | {variable_list, arrow_short_nested_type() | arrow_shorthand_type(), undefined}.
%% A Nested Type in which the base primitive type is in shorthand.

-type arrow_long_nested_type() ::
    {fixed_list, arrow_long_nested_type() | arrow_longhand_type(), pos_integer()}
    | {variable_list, arrow_long_nested_type() | arrow_longhand_type(), undefined}.
%% A Nested Type in which the base primitive type is in longhand.

%%%%%%%%%%%%%%%%%
%% Native Type %%
%%%%%%%%%%%%%%%%%

-type native_type() ::
    boolean()
    | undefined
    | nil
    | integer()
    | float()
    | binary().
%% Any Erlang datatype which `arrow' supports serializing from and
%% deserializing into.

%%%%%%%%%%%%%%%
%% Normalize %%
%%%%%%%%%%%%%%%

-define(Normalize(Atom, Char, Size),
    normalize(Atom) ->
        {Char, Size}
).

-spec normalize(Type :: arrow_type()) -> arrow_longhand_type().
%% Booleans
?Normalize(bool, bool, undefined);
%% Signed Integers
?Normalize(s8, s, 8);
?Normalize(s16, s, 16);
?Normalize(s32, s, 32);
?Normalize(s64, s, 64);
%% Unsigned Integers
?Normalize(u8, u, 8);
?Normalize(u16, u, 16);
?Normalize(u32, u, 32);
?Normalize(u64, u, 64);
%% Floats
?Normalize(f16, f, 16);
?Normalize(f32, f, 32);
?Normalize(f64, f, 64);
%% Binaries
?Normalize(bin, bin, undefined);
normalize({Name, Size} = Type) when (Name =:= s) orelse (Name =:= u) ->
    case lists:member(Size, [8, 16, 32, 64]) of
        true -> Type;
        false -> erlang:error(badarg)
    end;
normalize({f, Size} = Type) ->
    case lists:member(Size, [16, 32, 64]) of
        true -> Type;
        false -> erlang:error(badarg)
    end;
normalize({Name, undefined} = Type) when (Name =:= bool) orelse (Name =:= bin) ->
    Type;
normalize({fixed_list, Type, Length}) when is_integer(Length) ->
    {fixed_list, normalize(Type), Length};
normalize({variable_list, Type, undefined}) ->
    {variable_list, normalize(Type), undefined};
normalize(_Type) ->
    erlang:error(badarg).

-spec bit_length(Type :: arrow_type()) -> Length :: pos_integer() | undefined.
-doc """
Returns the size of the type in bits.
""".
bit_length(Type) when is_atom(Type) ->
    bit_length(normalize(Type));
bit_length({Type, Size}) when (Type =:= s) orelse (Type =:= u) orelse (Type =:= f) ->
    Size;
bit_length({bool, undefined}) ->
    1;
bit_length({bin, undefined}) ->
    erlang:error(badarg);
bit_length(Type) when tuple_size(Type) =:= 3 ->
    erlang:error(badarg).

-spec byte_length(Type :: arrow_type()) -> Length :: pos_integer() | undefined.
-doc """
Returns the size of the type in bytes.
""".
byte_length(Type) when is_atom(Type) ->
    byte_length(normalize(Type));
byte_length(Type) when tuple_size(Type) =:= 3 ->
    erlang:error(badarg);
byte_length({bool, undefined}) ->
    %% This is a stub function.
    %% TODO Find out the Arrow convention for Boolean Buffers
    1;
byte_length({bin, undefined}) ->
    undefined;
byte_length(Type) ->
    round(bit_length(Type) / 8).

-spec serialize(Value :: native_type(), Type :: arrow_longhand_type()) -> binary().
serialize(Value, {s, Size}) ->
    <<Value:Size/little-signed-integer>>;
serialize(Value, {u, Size}) ->
    <<Value:Size/little-unsigned-integer>>;
serialize(Value, {f, Size}) ->
    <<Value:Size/little-float>>;
serialize(Value, {bin, undefined}) ->
    Value.
