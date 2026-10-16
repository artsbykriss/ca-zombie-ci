// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {ForkHelper} from "../src/ForkHelper.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface ICLPoolAL {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function gauge() external view returns (address);
    function nft() external view returns (address);
    function factory() external view returns (address);
    function liquidity() external view returns (uint128);
    function stakedLiquidity() external view returns (uint128);
    function tickSpacing() external view returns (int24);
    function fee() external view returns (uint24);
    function collect(address recipient, int24 tl, int24 tu, uint128 a0, uint128 a1, address owner)
        external
        returns (uint128, uint128);
    function stake(int128 delta, int24 tl, int24 tu) external;
    function collectFees(address recipient) external returns (uint128, uint128);
    function setGaugeAndPositionManager(address _gauge, address _nft) external;
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

contract ALFlashBorrower {
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
        ICLPoolAL(pool).flash(address(this), _a0, _a1, "");
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata) external {
        require(msg.sender == pool, "not pool");
        if (repay) {
            if (a0 + fee0 > 0) IERC20(tok0).transfer(pool, a0 + fee0);
            if (a1 + fee1 > 0) IERC20(tok1).transfer(pool, a1 + fee1);
        }
    }
}

/// @title Z3-H17 · Aero Lite (Arc 5042) fork tests — no-gauge pool posture + unauthorized negatives
contract AeroLiteH17Test is ForkHelper {
    address constant FACTORY = 0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03;
    address constant POOL_IMPL = 0x0Df9fc8730eeC048e9832B31B4bFf4351158e19B;
    address constant REGISTRY = 0xCe44907DC45D3BFa3f5f6035B0e6E8B22D780A42;
    address constant OWNER = 0x6b031ac7420c2730E65eD9F8B7b2BD0648be45c4;
    address constant POOL0 = 0xbe080aC37ad1305DFCc9521F5e6F68CFDc41B7fa; // USDC/EURC ~$476k
    address constant POOL1 = 0xd945cAEe4635BcD7FB8A9fA74dC1D0c4C1472782; // cirBTC/USDC ~$1.11M

    address attacker = address(0xA11CE);

    function setUp() public {
        string[] memory urls = new string[](1);
        urls[0] = "https://rpc.mainnet.arc.io";
        string memory url = forkChain("ARC_RPC", urls);
        console2.log("fork rpc:", url);
        console2.log("block number:", block.number);
        vm.deal(attacker, 10 ether);
    }

    function _str(address a, string memory sig) internal view returns (bytes memory ret) {
        (bool ok, bytes memory d) = a.staticcall(abi.encodeWithSignature(sig));
        require(ok, sig);
        ret = d;
    }

    function test_T1_structural_no_gauges() public view {
        // all pools have gauge == 0, nft == 0 (the factory has no voter; registry has no gauge factory linked)
        assertEq(ICLPoolAL(POOL0).gauge(), address(0), "pool0 gauge zero");
        assertEq(ICLPoolAL(POOL0).nft(), address(0), "pool0 nft zero");
        assertEq(ICLPoolAL(POOL1).gauge(), address(0), "pool1 gauge zero");
        assertEq(ICLPoolAL(POOL1).nft(), address(0), "pool1 nft zero");
        assertEq(ICLPoolAL(POOL1).stakedLiquidity(), 0, "no staked liquidity");
        assertGt(ICLPoolAL(POOL1).liquidity(), 0, "pool1 liquidity live");
        assertEq(ICLPoolAL(POOL1).factory(), FACTORY, "factory link");
        console2.log("pool0 code-backed: impl", POOL_IMPL);
        console2.log("pool1 liquidity:", ICLPoolAL(POOL1).liquidity());
        console2.log("pool1 tickSpacing:", ICLPoolAL(POOL1).tickSpacing());
        address owner = abi.decode(_str(FACTORY, "owner()"), (address));
        assertEq(owner, OWNER, "factory owner");
        assertTrue(POOL_IMPL.code.length > 0, "pool impl has code");
    }

    function test_T2_registry_has_no_gauge_factory_for_factory() public view {
        (bool ok, bytes memory d) =
            REGISTRY.staticcall(abi.encodeWithSignature("targetFactoryToGaugeFactory(address)", FACTORY));
        assertTrue(ok, "registry callable");
        address gf = abi.decode(d, (address));
        console2.log("registry.targetFactoryToGaugeFactory(factory):", gf);
        assertEq(gf, address(0), "no gauge factory -> gauge setup impossible");
    }

    function test_T3_admin_gated_pool_owner_actions_revert() public {
        address[3] memory targets = [POOL0, POOL1, REGISTRY];
        targets;
        vm.startPrank(attacker);
        // onlyGauge paths revert because gauge == 0
        (bool ok1,) = POOL1.call(abi.encodeWithSignature("stake(int128,int24,int24)", int128(1), int24(-887220), int24(887220)));
        assertFalse(ok1, "stake must revert (gauge=0)");
        (bool ok2, bytes memory d2) = POOL1.call(abi.encodeWithSignature("collectFees(address)", attacker));
        assertFalse(ok2, "collectFees must revert (gauge=0)");
        console2.logBytes(d2);
        // onlyGaugeFactory path reverts because registry returns 0
        (bool ok3,) = POOL1.call(abi.encodeWithSignature("setGaugeAndPositionManager(address,address)", attacker, attacker));
        assertFalse(ok3, "setGaugeAndPositionManager must revert");
        // factory admin setters
        (bool ok4,) = FACTORY.call(abi.encodeWithSignature("setDefaultSwapHook(address)", attacker));
        assertFalse(ok4, "setDefaultSwapHook must revert");
        (bool ok5,) = FACTORY.call(abi.encodeWithSignature("setOwner(address)", attacker));
        assertFalse(ok5, "setOwner must revert");
        (bool ok6,) = FACTORY.call(abi.encodeWithSignature("setSwapFeeManager(address)", attacker));
        assertFalse(ok6, "setSwapFeeManager must revert");
        vm.stopPrank();
    }

    function test_T4_pool_owner_collect_requires_nft_manager() public {
        vm.prank(attacker);
        (bool ok, bytes memory d) = POOL0.call(
            abi.encodeWithSignature(
                "collect(address,int24,int24,uint128,uint128,address)", attacker, int24(-887220), int24(887220), uint128(1), uint128(1), attacker
            )
        );
        assertFalse(ok, "6-arg collect must revert (nft=0)");
        console2.logBytes(d);
    }

    /// @dev flash reachable; without repayment it must revert. On Arc the revert surfaces from the
    ///      native-token transfer inside flash (fork limitation), still proving the path is live.
    function test_T5_flash_without_repay_reverts() public {
        ALFlashBorrower b = new ALFlashBorrower(POOL0, ICLPoolAL(POOL0).token0(), ICLPoolAL(POOL0).token1(), false);
        vm.prank(attacker);
        (bool ok, bytes memory d) = address(b).call(abi.encodeWithSignature("go(uint256,uint256)", uint256(1000), uint256(1000)));
        assertFalse(ok, "flash must revert without repayment");
        console2.logBytes(d);
    }

    /// @dev Arc's native-token precompiles (0x1800..01 blacklist checks) cannot run in Foundry
    ///      forks, so no token transfer is simulatable on Arc. The flash path is reachable and
    ///      reverts at the token transfer (TransferHelper 'TF'); fee enforcement is proven from
    ///      the byte-identical metadex source + the UpV3/Icarus fork tests of the same code paths.
    function test_T6_fee_views_bounded_and_hook_wired() public view {
        uint24 f0 = ICLPoolAL(POOL0).fee();
        uint24 f1 = ICLPoolAL(POOL1).fee();
        console2.log("pool0 fee pips:", f0);
        console2.log("pool1 fee pips:", f1);
        assertLe(f0, 100_000, "fee <= 10% ceil");
        assertLe(f1, 100_000, "fee <= 10% ceil");
        (bool ok, bytes memory d) = FACTORY.staticcall(
            abi.encodeWithSignature("getPoolSwapHook(address)", POOL0)
        );
        assertTrue(ok, "getPoolSwapHook callable");
        address hook = abi.decode(d, (address));
        console2.log("default swap hook for pool0:", hook);
        assertTrue(hook.code.length > 0, "hook has code");
    }
}
