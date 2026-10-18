// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IPool, IPoolAddressesProvider, IOracle} from "../src/Interfaces.sol";

/// @notice Fork test: SakeFinance (Soneium) reserve config + oracle sanity.
contract SakeTest is Test {
    address constant POOL = 0x3C3987A310ee13F7B8cBBe21D97D4436ba5E4B5f;
    address constant ORACLE = 0x18530Af497F558e23134E223244F353ea776aF2A;

    function setUp() public {
        vm.createSelectFork(vm.envOr("SONEIUM_RPC_URL", string("https://rpc.soneium.org")));
    }

    function test_sake_configs_and_oracle() public {
        address[] memory assets = IPool(POOL).getReservesList();
        console2.log("reserves", assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 cfg = IPool(POOL).getConfiguration(assets[i]);
            uint256 ltv = cfg & 0xffff;
            uint256 liqth = (cfg >> 16) & 0xffff;
            uint256 bonus = (cfg >> 32) & 0xffff;
            uint256 active = (cfg >> 56) & 1;
            assertLe(ltv, liqth, "LTV > LT");
            assertGe(bonus, 10000, "bonus < 1x");
            assertLe(bonus, 12000, "bonus > 1.2x");
            if (active == 1) {
                uint256 p = IOracle(ORACLE).getAssetPrice(assets[i]);
                assertGt(p, 0, "zero price");
                console2.log("asset", assets[i]);
                console2.log("ltv", ltv);
                console2.log("lt", liqth);
                console2.log("bonus", bonus);
                console2.log("price", p);
            }
        }
    }
}
