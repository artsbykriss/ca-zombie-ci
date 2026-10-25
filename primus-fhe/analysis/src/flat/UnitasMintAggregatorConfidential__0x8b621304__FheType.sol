// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

enum FheType {
    Bool, // 0
    /// Unsigned integers
    Uint8, // 1
    Uint16, // 2
    Uint32, // 3
    Uint64, // 4
    Uint128, // 5
    Uint256, // 6
    ///
    NUMS
}

enum Operator {
    fheNone, // 0
    fheAdd, // 1
    fheSub,
    fheMul,
    fheDiv,
    fheBitAnd,
    fheBitOr,
    fheBitXor,
    fheBitNot,
    fheEq,
    fheNe,
    fheGe,
    fheGt,
    fheLe,
    fheLt,
    fheIfThenElse,
    trivialEncrypt,
    verifyAttestation,
    fheCast
}
