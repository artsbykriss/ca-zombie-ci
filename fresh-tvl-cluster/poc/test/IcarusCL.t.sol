// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {ForkHelper} from "../src/ForkHelper.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface ICLPoolIC {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function gauge() external view returns (address);
    function nft() external view returns (address);
    function factory() external view returns (address);
    function liquidity() external view returns (uint128);
    function stakedLiquidity() external view returns (uint128);
    function tickSpacing() external view returns (int24);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface ICLGaugeIC {
    function withdraw(uint256 tokenId) external;
    function getReward(uint256 tokenId) external;
    function deposit(uint256 tokenId) external;
    function voter() external view returns (address);
    function pool() external view returns (address);
    function rewardRate() external view returns (uint256);
}

interface INPMIC {
    function positions(uint256 tokenId)
        external
        view
        returns (uint96, address, address, address, int24, int24, int24, uint128, uint256, uint256, uint128, uint128);
    function ownerOf(uint256 tokenId) external view returns (address);
    function refundETH() external payable;
}

contract ICFlashBorrower {
    address public immutable pool;
    address public immutable tok0;
    address public immutable tok1;
    bool public repay;
    uint256 public a0;
    uint256 public a1;

    constructor(address _pool, address _t0, address _t1, bool _repay) {
        pool = _pool;
        tok0 = _t0;
        tok1 = _t1;
        repay = _repay;
    }

    function go(uint256 _a0, uint256 _a1) external {
        a0 = _a0;
        a1 = _a1;
        ICLPoolIC(pool).flash(address(this), _a0, _a1, "");
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata) external {
        require(msg.sender == pool, "not pool");
        if (repay) {
            if (a0 + fee0 > 0) IERC20(tok0).transfer(pool, a0 + fee0);
            if (a1 + fee1 > 0) IERC20(tok1).transfer(pool, a1 + fee1);
        }
    }
}

/// @title Z3-H17 · Icarus CL (RISE 4153) fork tests — verified-stack unauthorized negatives
contract IcarusCLH17Test is ForkHelper {
    address constant FACTORY = 0x6f7DA11c13Ba09A153dA06d376044e5859Db607B;
    address constant POOL_IMPL = 0x4356B9347D963076406187ED7BE73c526F071E53;
    address constant NPM = 0x195D3037cb4AF610B96EF2984b4013eE836568E1;
    address constant VOTER = 0xFB3773f03EFB35198b065e455090E55eE25D3177;
    address constant SAFE = 0x838fc4155Fc13B3b75030950Fd9B58DbCE874aE0;
    address constant POOL = 0xCBc0c0d2782f97077A6309e28B9B70Dc73a934D2; // USDR/USDC.e ~$8.02M
    address constant GAUGE = 0xbDf33a2237C862db56817C62c3771af83320591d;

    address attacker = address(0xA11CE);

    function setUp() public {
        string[] memory urls = new string[](1);
        urls[0] = "https://rpc.risechain.com";
        string memory url = forkChain("RISE_RPC", urls);
        console2.log("fork rpc:", url);
        console2.log("block number:", block.number);
        vm.deal(attacker, 10 ether);
    }

    function test_T1_structural_facts() public view {
        (bool ok, bytes memory od) = FACTORY.staticcall(abi.encodeWithSignature("owner()"));
        assertTrue(ok, "owner() readable");
        assertEq(abi.decode(od, (address)), SAFE, "factory owner is Safe proxy");
        assertTrue(SAFE.code.length > 0, "owner has code (Safe proxy)");
        assertEq(ICLPoolIC(POOL).gauge(), GAUGE, "pool gauge");
        assertEq(ICLPoolIC(POOL).nft(), NPM, "pool nft");
        assertEq(ICLPoolIC(POOL).factory(), FACTORY, "pool factory");
        assertGt(ICLPoolIC(POOL).liquidity(), 0, "liquidity live");
        console2.log("pool liquidity:", ICLPoolIC(POOL).liquidity());
        console2.log("pool stakedLiquidity:", ICLPoolIC(POOL).stakedLiquidity());
        console2.log("pool tickSpacing:", ICLPoolIC(POOL).tickSpacing());
        assertTrue(POOL_IMPL.code.length > 0, "impl has code");
        // gauge wired but emits nothing (no reward program running)
        console2.log("gauge rewardRate:", ICLGaugeIC(GAUGE).rewardRate());
        assertEq(ICLGaugeIC(GAUGE).pool(), POOL, "gauge pool");
        assertEq(ICLGaugeIC(GAUGE).voter(), VOTER, "gauge voter");
    }

    function test_T2_gauge_unauthorized_reverts() public {
        vm.startPrank(attacker);
        (bool ok1, bytes memory d1) = GAUGE.call(abi.encodeWithSignature("withdraw(uint256)", uint256(1)));
        assertFalse(ok1, "withdraw must revert");
        console2.logBytes(d1);
        (bool ok2, bytes memory d2) = GAUGE.call(abi.encodeWithSignature("getReward(uint256)", uint256(1)));
        assertFalse(ok2, "getReward must revert");
        console2.logBytes(d2);
        (bool ok3, bytes memory d3) = GAUGE.call(abi.encodeWithSignature("deposit(uint256)", uint256(1)));
        assertFalse(ok3, "deposit must revert");
        console2.logBytes(d3);
        vm.stopPrank();
    }

    function test_T3_npm_unauthorized_collect_reverts() public {
        uint256 foundId = 0;
        for (uint256 id = 1; id <= 200; id++) {
            (bool ok, bytes memory data) = NPM.staticcall(abi.encodeWithSignature("positions(uint256)", id));
            if (ok && data.length >= 64) {
                foundId = id;
                break;
            }
        }
        console2.log("existing tokenId found:", foundId);
        if (foundId == 0) {
            console2.log("no position in 1..200 - structural negative only");
            return;
        }
        console2.log("position owner:", INPMIC(NPM).ownerOf(foundId));
        vm.prank(attacker);
        (bool ok2, bytes memory d) = NPM.call(
            abi.encodeWithSignature(
                "collect((uint256,address,uint128,uint128))",
                foundId,
                attacker,
                uint128(1),
                uint128(1)
            )
        );
        assertFalse(ok2, "foreign NPM collect must revert");
        console2.logBytes(d);
    }

    function test_T4_pool_owner_collect_requires_nft_manager() public {
        vm.prank(attacker);
        (bool ok, bytes memory d) = POOL.call(
            abi.encodeWithSignature(
                "collect(address,int24,int24,uint128,uint128,address)", attacker, int24(-887220), int24(887220), uint128(1), uint128(1), NPM
            )
        );
        assertFalse(ok, "6-arg collect must revert (onlyNftManager)");
        console2.logBytes(d);
    }

    function test_T5_flash_without_repay_reverts() public {
        ICFlashBorrower b = new ICFlashBorrower(POOL, ICLPoolIC(POOL).token0(), ICLPoolIC(POOL).token1(), false);
        vm.prank(attacker);
        (bool ok, bytes memory d) = address(b).call(abi.encodeWithSignature("go(uint256,uint256)", uint256(1000), uint256(1000)));
        assertFalse(ok, "flash must revert without repayment");
        console2.logBytes(d);
    }

    /// @dev fee buffer sourced (fork-only impersonation) from a sibling pool holding USDR
    function test_T6_flash_with_repay_fee_accounting_identity() public {
        address t0 = ICLPoolIC(POOL).token0(); // USDR (6dp)
        address t1 = ICLPoolIC(POOL).token1(); // USDC.e
        ICFlashBorrower b = new ICFlashBorrower(POOL, t0, t1, true);
        uint256 a0 = 1e9; // 1000 USDR
        uint256 buf = 1e9; // 1000 USDR buffer (>= max 10% fee)
        // fund the buffer from the USDR/xlpUSD sibling pool (fork-only impersonation)
        vm.prank(0x6648031c9B95658113Db66c5f0548FE2FCEC43a8);
        IERC20(t0).transfer(address(b), buf);
        uint256 p0 = IERC20(t0).balanceOf(POOL);
        vm.prank(attacker);
        b.go(a0, 0);
        uint256 delta = IERC20(t0).balanceOf(POOL) - p0;
        uint256 residual = IERC20(t0).balanceOf(address(b));
        console2.log("flash fee paid to pool:", delta);
        console2.log("borrower residual:", residual);
        assertEq(residual + delta, buf, "accounting identity: fee = buffer - residual");
        assertLe(delta, a0 / 10, "fee <= 10% cap");
        assertEq(attacker.balance, 10 ether, "attacker gained nothing");
    }

    function test_T7_npm_eth_park_is_zero() public {
        console2.log("NPM ETH balance:", NPM.balance);
        assertEq(NPM.balance, 0, "no parked ETH");
        vm.prank(attacker);
        INPMIC(NPM).refundETH();
        assertEq(NPM.balance, 0, "refundETH yields nothing");
    }
}
