// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

struct uve_bool    { bytes32 handle; bytes data; }
struct uve_uint8   { bytes32 handle; bytes data; }
struct uve_uint16  { bytes32 handle; bytes data; }
struct uve_uint32  { bytes32 handle; bytes data; }
struct uve_uint64  { bytes32 handle; bytes data; }
struct uve_uint128 { bytes32 handle; bytes data; }
struct uve_uint256 { bytes32 handle; bytes data; }

//
//
type ve_bool is bytes32;
type ve_uint8 is bytes32;
type ve_uint16 is bytes32;
type ve_uint32 is bytes32;
type ve_uint64 is bytes32;
type ve_uint128 is bytes32;
type ve_uint256 is bytes32;
