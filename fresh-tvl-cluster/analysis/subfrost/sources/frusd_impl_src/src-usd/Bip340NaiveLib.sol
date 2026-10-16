// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EllipticCurve} from "bip340-solidity/EllipticCurve.sol";
import {Secp256k1} from "bip340-solidity/Secp256k1.sol";
import {Bip340Util} from "bip340-solidity/Bip340Util.sol";

/// @title Bip340NaiveLib
/// @notice INTERNAL-library form of bip340-solidity's `Bip340Naive` full-coordinate
/// BIP340 verifier. Making it an internal library inlines the verify into the vault
/// bytecode, so:
///   * no separate verifier contract to deploy,
///   * no external STATICCALL per verification (saved on every FROST-gated op), and
///   * the verifier travels with the UUPS implementation — a verifier fix ships via
///     a FROST-authorized vault upgrade instead of being frozen in an immutable contract.
///
/// The logic is byte-identical to `Bip340Naive.{verify,verifyFull}` and reuses the
/// SAME audited primitives (EllipticCurve / Secp256k1 / Bip340Util). Equivalence to
/// the standalone contract is pinned by a differential test (see USDVaultSecurity.t.sol).
library Bip340NaiveLib {
    /// Verifies a BIP340 signature `(rx, s)` against message `m` and pubkey x-coord `px`.
    function verify(uint256 px, uint256 rx, uint256 s, bytes32 m) internal pure returns (bool) {
        // Check pubkey is in range.
        if (px >= Secp256k1.PP) {
            return false;
        }

        // Let P = lift_x(int(pk)); fail if that fails.
        (uint256 py, bool liftOk) = Bip340Util.liftX(px);
        if (!liftOk) {
            return false;
        }

        // Check pubkey is on curve.
        if (!EllipticCurve.isOnCurve(px, py, Secp256k1.AA, Secp256k1.BB, Secp256k1.PP)) {
            return false;
        }

        return _verifyFull(px, py, rx, s, m);
    }

    /// The point must already be on the curve (verify() validates it first).
    function _verifyFull(uint256 _px, uint256 _py, uint256 rx, uint256 s, bytes32 m)
        private
        pure
        returns (bool)
    {
        // Check rx and s are in-range.
        if (rx >= Secp256k1.PP || s >= Secp256k1.NN) {
            return false;
        }

        // Let e = int(hashBIP0340/challenge(bytes(r) || bytes(P) || m)) mod n.
        uint256 e = Bip340Util.computeChallenge(bytes32(rx), bytes32(_px), m);

        // Let R = s⋅G - e⋅P.
        (uint256 rvx, uint256 rvy) = (0, 0);
        {
            uint256 px = _px;
            uint256 py = _py;
            (uint256 sgx, uint256 sgy, uint256 sgz) =
                EllipticCurve.jacMul(s, Secp256k1.GX, Secp256k1.GY, 1, Secp256k1.AA, Secp256k1.PP);
            (uint256 epx, uint256 epy, uint256 epz) =
                EllipticCurve.jacMul(e, px, py, 1, Secp256k1.AA, Secp256k1.PP);

            // Check if it's safe to use jacAdd.
            if (Bip340Util.xToAffine(sgx, sgz, Secp256k1.PP) == Bip340Util.xToAffine(epx, epz, Secp256k1.PP)) {
                return false;
            }

            uint256 epy_inv = (Secp256k1.PP - epy) % Secp256k1.PP; // flip the y coordinate
            (uint256 jrvx, uint256 jrvy, uint256 jrvz) =
                EllipticCurve.jacAdd(sgx, sgy, sgz, epx, epy_inv, epz, Secp256k1.PP);

            // Convert back to affine now that we're done.
            (rvx, rvy) = EllipticCurve.toAffine(jrvx, jrvy, jrvz, Secp256k1.PP);
        }

        // Fail if is_infinite(R).
        if (rvx == 0 && rvy == 0) {
            return false;
        }

        // Fail if not has_even_y(R).
        if ((rvy & 1) != 0) {
            return false;
        }

        // Fail if x(R) ≠ r.
        return (rvx == rx);
    }
}
