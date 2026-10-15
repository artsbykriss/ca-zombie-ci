// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/// @title LPBonus (BSC) residual-extractability BOUND test
/// @notice Read-only fork test: reads live LPBonus/MSN/FIST state and asserts that no
///         fresh unprivileged attacker can profitably claim the residual FIST pot.
///
///         Model (upper bound, generous to the attacker):
///         - The pot is capped by LPBonus's FIST balance P.
///         - Over-claim factor = A/R, where A = attacker userAddAmount (MSN added as LP)
///           and R = the pair's MSN reserve at index-inflation time (crushed).
///         - Max gross gain = P*(1 - R/A) (funding the inflation costs fistOut = claim*R/A).
///         - The crush requires an AMM round trip of F_in ~= F1*dM/R FIST; the two 0.25%
///           pool fees alone cost 0.005*F_in (a lower bound: slippage is ignored).
///         - Assertion: for every feasible (A, R), max gross gain <= lower-bound fee cost.
contract LPBonusBoundTest is Test {
    address constant LPB  = 0x52272524A22f941f5489c1233732797314BB054b;
    address constant FIST = 0xC9882dEF23bc42D53895b8361D0b1EDC7570Bc6A;
    address constant PAIR = 0xDD95c8a545E98D2C6De4D20aBCC44b104da1E6E5;

    uint256 constant MSN_TOTAL = 5000e18; // MSN total supply (cap on what an attacker could add)

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        vm.createSelectFork(rpc);
    }

    function _bal(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory d) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        require(ok, "balanceOf failed");
        return abi.decode(d, (uint256));
    }

    function _reserves() internal view returns (uint256 rFist, uint256 rMsn) {
        (bool ok, bytes memory d) = PAIR.staticcall(abi.encodeWithSignature("getReserves()"));
        require(ok, "getReserves failed");
        (uint112 r0, uint112 r1, ) = abi.decode(d, (uint112, uint112, uint32));
        // token0 = FIST, token1 = MSN (verified on-chain)
        rFist = r0;
        rMsn = r1;
    }

    /// @notice fee lower bound for a crush round trip, in FIST raw units
    function _feeLowerBound(uint256 F0, uint256 M0, uint256 A, uint256 R) internal pure returns (uint256) {
        if (R == 0 || A == 0) return type(uint256).max;
        uint256 F1 = F0 * (M0 + A) / M0;       // FIST reserve after adding A MSN as liquidity
        uint256 M1 = M0 + A;                    // MSN reserve after the add
        if (R >= M1) return 0;                  // no crush needed
        uint256 dM = M1 - R;                    // MSN bought to crush
        uint256 F_in = F1 * dM / R;             // cost of the buy (spot, fee-free approximation)
        return 0.005e18 * F_in / 1e18;          // two 0.25% pool fees = 0.5% (lower bound)
    }

    function testLPBonusResidualNotProfitablyExtractable() public {
        uint256 pot = _bal(FIST, LPB);          // FIST raw (6 dec)
        (uint256 F0, uint256 M0) = _reserves();
        emit log_named_decimal_uint("LPBonus FIST pot (FIST)", pot, 6);
        emit log_named_decimal_uint("pair FIST reserve", F0, 6);
        emit log_named_decimal_uint("pair MSN reserve", M0, 18);
        assertGt(pot, 0, "pot should be non-zero for the bound test to be meaningful");
        assertGt(M0, 0, "MSN reserve zero");

        // feasible A values (MSN added as liquidity, raw 18 dec): up to the whole supply
        uint256[8] memory As = [uint256(0.25e18), 1e18, 5e18, 10e18, 50e18, 140e18, 482e18, MSN_TOTAL];
        uint256 worst = 0;
        bool anyProfitable = false;
        for (uint256 i = 0; i < As.length; i++) {
            uint256 A = As[i];
            // R grid: 5%..100% of (M0+A)
            for (uint256 pct = 5; pct <= 100; pct += 5) {
                uint256 R = (M0 + A) * pct / 100;
                uint256 fee = _feeLowerBound(F0, M0, A, R);
                uint256 maxGross;
                if (R < A) {
                    maxGross = pot * (A - R) / A;   // capped by the pot
                } else {
                    maxGross = 0;                    // factor <= 1 -> no over-claim
                }
                if (maxGross > fee) {
                    anyProfitable = true;
                    emit log_named_uint("PROFITABLE (A)", A);
                    emit log_named_uint("  (R)", R);
                    emit log_named_uint("  maxGross", maxGross);
                    emit log_named_uint("  feeLB", fee);
                }
                if (maxGross > worst) worst = maxGross;
            }
        }
        emit log_named_decimal_uint("worst-case gross gain (FIST)", worst, 6);
        assertFalse(anyProfitable, "found a profitable parameter set -> re-open the finding");
    }
}
