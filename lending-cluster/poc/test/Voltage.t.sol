// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IPool, IPoolAddressesProvider, IOracle} from "../src/Interfaces.sol";

/// @notice Fork test: Voltage Lending (Fuse) - the only two liquidatable accounts with collateral.
/// Read-only except against an in-memory Fuse fork; no mainnet transactions.
contract VoltageTest is Test {
    address constant POOL = 0xe3eda4b12ae4ACC031E4CF9Eae08ACe6250CED3E;
    address constant WETH = 0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590;
    address constant WFUSE = 0x0BE9e53fd7EDaC9F859882AfdDa116645287C629;
    address constant USER1 = 0xb9a22B240846F95D86E79CAea6F95bfe1c9E0d8F;
    address constant USER2 = 0x5ED1E9843B0F7289C7fb7A055e097a0576bc5C16;
    address attacker = address(0xA77AC4);

    function setUp() public {
        vm.createSelectFork(vm.envOr("FUSE_RPC_URL", string("https://rpc.fuse.io")));
    }

    function _reserve(address asset) internal view returns (address aToken, address vToken) {
        (,,,,,,,, aToken,, vToken,,,,) = IPool(POOL).getReserveData(asset);
    }

    function _price(address asset) internal view returns (uint256) {
        address oracle = IPoolAddressesProvider(IPool(POOL).ADDRESSES_PROVIDER()).getPriceOracle();
        return IOracle(oracle).getAssetPrice(asset);
    }

    function _fund(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
        if (IERC20(token).balanceOf(to) != amount) {
            // fall back to WETH9-style slot 3
            vm.store(token, keccak256(abi.encode(to, uint256(3))), bytes32(amount));
            require(IERC20(token).balanceOf(to) == amount, "fund failed");
        }
    }

    function _liquidate(address user) internal returns (uint256 bonusUsd8) {
        (, address vDebt) = _reserve(WFUSE);
        uint256 debt = IERC20(vDebt).balanceOf(user);
        uint256 cover = debt / 2;
        uint256 wfuseBefore = IERC20(WFUSE).balanceOf(attacker);
        uint256 wethBefore = IERC20(WETH).balanceOf(attacker);

        vm.startPrank(attacker);
        IERC20(WFUSE).approve(POOL, type(uint256).max);
        IPool(POOL).liquidationCall(WETH, WFUSE, user, cover, false);
        vm.stopPrank();

        uint256 wfuseSpent = wfuseBefore - IERC20(WFUSE).balanceOf(attacker);
        uint256 wethGot = IERC20(WETH).balanceOf(attacker) - wethBefore;
        uint256 wfusePrice = _price(WFUSE);
        uint256 wethPrice = _price(WETH);
        int256 pnl = int256((wethGot * wethPrice) / 1e18) - int256((wfuseSpent * wfusePrice) / 1e18);
        console2.log("user", user);
        console2.log("debt_wfuse", debt);
        console2.log("cover_wfuse", cover);
        console2.log("wfuseSpent", wfuseSpent);
        console2.log("wethGot", wethGot);
        console2.log("pnl_usd8", pnl);
        bonusUsd8 = uint256(pnl > 0 ? pnl : int256(0));
    }

    function test_voltage_two_real_liquidations() public {
        _fund(WFUSE, attacker, 1_000_000 ether);
        (uint256 coll1, uint256 debt1,,,, uint256 hf1) = IPool(POOL).getUserAccountData(USER1);
        (uint256 coll2, uint256 debt2,,,, uint256 hf2) = IPool(POOL).getUserAccountData(USER2);
        console2.log("user1 coll/debt/HF", coll1, debt1, hf1);
        console2.log("user2 coll/debt/HF", coll2, debt2, hf2);
        assertLt(hf1, 1e18);
        assertLt(hf2, 1e18);
        uint256 b1 = _liquidate(USER1);
        uint256 b2 = _liquidate(USER2);
        console2.log("bonus1_usd", b1 / 1e8);
        console2.log("bonus2_usd", b2 / 1e8);
        uint256 total = (b1 + b2) / 1e8;
        assertGt(total, 20);
        assertLt(total, 300);
    }
}
