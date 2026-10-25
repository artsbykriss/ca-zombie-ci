// SPDX-License-Identifier: MIT
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from OpenZeppelin Confidential Contracts. Copyright (c) OpenZeppelin.
// Modifications Copyright (c) 2026 Primus Labs.
// Full license terms: see the MIT notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";

/**
 * @dev Overflow-aware arithmetic on encrypted `ve_uint64` values.
 *
 * NOTE: an uninitialized handle (ve_uint64.wrap(bytes32(0))) behaves as 0. When every input is
 * uninitialized the returned handle may also be uninitialized.
 */
library ConfidentialSafeMath {
    /**
     * @dev Attempts `oldValue + delta`. On success `ok` is true and `updated` holds the sum; on overflow
     * `ok` is false and `updated` stays at `oldValue`.
     */
    function tryIncrease(ve_uint64 oldValue, ve_uint64 delta) internal returns (ve_bool ok, ve_uint64 updated) {
        if (!FHE.isInitialized(oldValue)) {
            return (FHE.asVEBool(true), delta);
        }
        ve_uint64 newValue = FHE.add(oldValue, delta);
        ok = FHE.ge(newValue, oldValue);
        updated = FHE.select(ok, newValue, oldValue);
    }

    /**
     * @dev Attempts `oldValue - delta`. On success `ok` is true and `updated` holds the difference; when it
     * would underflow `ok` is false and `updated` stays at `oldValue`.
     */
    function tryDecrease(ve_uint64 oldValue, ve_uint64 delta) internal returns (ve_bool ok, ve_uint64 updated) {
        if (!FHE.isInitialized(oldValue)) {
            if (!FHE.isInitialized(delta)) {
                return (FHE.asVEBool(true), oldValue);
            }
            return (FHE.eq(delta, uint64(0)), FHE.asVEUint64(0));
        }
        ok = FHE.ge(oldValue, delta);
        updated = FHE.select(ok, FHE.sub(oldValue, delta), oldValue);
    }

    /**
     * @dev Attempts `a + b`. On success `ok` is true and `res` is the sum, otherwise `ok` is false and
     * `res` is 0.
     */
    function tryAdd(ve_uint64 a, ve_uint64 b) internal returns (ve_bool ok, ve_uint64 res) {
        if (!FHE.isInitialized(a)) {
            return (FHE.asVEBool(true), b);
        }
        if (!FHE.isInitialized(b)) {
            return (FHE.asVEBool(true), a);
        }

        ve_uint64 sum = FHE.add(a, b);
        ok = FHE.ge(sum, a);
        res = FHE.select(ok, sum, FHE.asVEUint64(0));
    }

    /**
     * @dev Attempts `a - b`. On success `ok` is true and `res` is `a - b`, otherwise `ok` is false and
     * `res` is 0.
     */
    function trySub(ve_uint64 a, ve_uint64 b) internal returns (ve_bool ok, ve_uint64 res) {
        if (!FHE.isInitialized(b)) {
            return (FHE.asVEBool(true), a);
        }

        ve_uint64 difference = FHE.sub(a, b);
        ok = FHE.le(difference, a);
        res = FHE.select(ok, difference, FHE.asVEUint64(0));
    }
}
