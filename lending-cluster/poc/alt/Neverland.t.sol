// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IPool} from "../src/Interfaces.sol";

/// @notice Fork test: Neverland (Monad) - no account is liquidatable; the "debt-token drift"
/// is real legacy debt held by 27 borrowers, not phantom supply.
contract NeverlandTest is Test {
    address constant CANON = 0x80F00661b13CC5F6ccd3885bE7b4C9c67545D585;
    address constant ISO = 0x690AD251a0D9c8A47cf1bC5e4C0dBd3131eE09D3;
    address constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address constant PT2 = 0x8B562578b2f9Aa8C14cCda3c5d6CBCEaD3B06a57;
    address constant VDEBT = 0x9da2d91D0CcF2daaf16B8Bd2778593Af1C369657;
    address constant ATOKEN = 0xF58E7aDC6F4eC524C09B7b6f058d3aB48D7CD65e;
    address constant USER = 0xC853E78877c758cC43ad152726Cb593f03D23030;
    address attacker = address(0xA77AC4);

    function setUp() public {
        vm.createSelectFork(vm.envOr("MONAD_RPC_URL", string("https://rpc.monad.xyz")));
    }

    function _hf(address pool, address u) internal view returns (uint256) {
        (,,,,, uint256 hf) = IPool(pool).getUserAccountData(u);
        return hf;
    }

    function test_neverland_no_live_liquidation_and_balanced_debt() public {
        uint256 hfIso = _hf(ISO, USER);
        uint256 hfCan = _hf(CANON, USER);
        console2.log("isolated HF", hfIso);
        console2.log("canonical HF", hfCan);
        assertGt(hfIso, 1e18);
        assertGt(hfCan, 1e18);
        assertLt(hfIso, 1.02e18); // near-threshold watch

        uint256 vDebt = IERC20(VDEBT).totalSupply();
        uint256 aTok = IERC20(ATOKEN).totalSupply();
        uint256 cash = IERC20(AUSD).balanceOf(ATOKEN);
        console2.log("vDebt", vDebt);
        console2.log("aToken supply", aTok);
        console2.log("aToken cash", cash);
        // cash + debt must match supply (interest rounding tolerance 1%)
        assertApproxEqRel(cash + vDebt, aTok, 1e16);

        // A liquidation attempt must revert (HF not below threshold).
        deal(AUSD, attacker, 10e6);
        vm.startPrank(attacker);
        IERC20(AUSD).approve(ISO, type(uint256).max);
        vm.expectRevert();
        IPool(ISO).liquidationCall(PT2, AUSD, USER, 1e6, false);
        vm.stopPrank();
    }
}
