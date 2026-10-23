// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {PoolKey, IERC20, IPoolManager, SwapHarness, UnlockReinvest} from "../src/SwapHarness.sol";

interface IFRLM {
    function reinvest(PoolKey calldata key) external returns (bool);
    function donate(PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        payable
        returns (uint256, uint256);
    function getPendingFees(bytes32 poolId) external view returns (uint256, uint256);
    function accountedBalances(address) external view returns (uint256);
    function accountedERC6909Balances(address) external view returns (uint256);
    function sweepExcessTokens(address currency, address recipient) external returns (uint256);
    function sweepExcessERC6909(address currency, address recipient) external returns (uint256);
    function withdrawProtocolLiquidity(PoolKey calldata key, uint256 s, uint256 a0, uint256 a1, address r)
        external
        returns (uint256, uint256);
    function balanceOf(address, uint256) external view returns (uint256);
    function getPositionInfo(bytes32) external view returns (uint256, uint128, uint256, uint256);
    function getProtocolOwnedLiquidity(bytes32) external view returns (uint256, uint256, uint256);
    function authorizedHookAddress() external view returns (address);
    function reinvestmentTwap() external view returns (uint32);
    function tickRangeTolerance() external view returns (int24);
    function REINVEST_COOLDOWN() external view returns (uint256);
}

interface IDynamicFeeManager {
    function getFeeState(bytes32 poolId) external view returns (uint256, uint256);
}

interface IOracle {
    function consult(PoolKey calldata key, uint32 secondsAgo)
        external
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity);
    function maxTicksPerBlock(bytes32) external view returns (uint24);
}

interface IPositionManager {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getPositionLiquidity(uint256 tokenId) external view returns (uint128);
}

interface IPolicyManager {
    function owner() external view returns (address);
    function getPoolPOLShare(bytes32) external view returns (uint256);
    function getManualFee(bytes32) external view returns (uint24, bool);
}

/// @title ZH4-PASS5 P5-03 Spot hook (AEGIS DFM) — read-only fork probes (Unichain)
/// @notice Fork-only. No transactions are signed or broadcast. A fresh, unprivileged
///         attacker address is used for every probe; the question is whether the
///         permissionless `reinvest(PoolKey)` path (take/burn + re-add LP with custom
///         accountedBalances / ERC-6909 accounting) can mis-account or extract value.
contract SpotTest is Test {
    address constant PM = 0x1F98400000000000000000000000000000000004;
    address constant POSM = 0x4529A01c7A0410167c5740C487A8DE60232617bf;

    address constant HOOK1 = 0x88C9fF9FC0B22cCa42265d3f1D1C2C39E41cDACC; // flags 0x1acc
    address constant FRLM1 = 0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3;
    address constant DFM1 = 0xD7deABAb9ECd3BcB3B89ab0cE2c84C8565bB8D98;
    address constant ORACLE1 = 0xbe4F23B9488300c532A5d9d8D11B0b8163Be6ABF;

    address constant HOOK2 = 0xA0b0D2d00fD544D8E0887F1a3cEDd6e24Baf10cc; // flags 0x10cc
    address constant FRLM2 = 0xA7ce35E886e58926Ad0C149f4cc558e27D458a2c;
    address constant DFM2 = 0xe6768629156d4B713e266b87502fbeccc218a028;

    address constant USDC = 0x078D782b760474a361dDA0AF3839290b0EF57AD6; // 6 dec
    address constant XRP = 0x2615a94df961278DcbC41Fb0a54fEc5f10a693aE; // 18 dec
    address constant AGa = 0xAAAa68f5D1f7855954ecB361D4b9FF3127cfefA7; // 18 dec
    address constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c; // 8 dec

    uint160 constant MIN_SQRT = 4295128740;
    uint160 constant MAX_SQRT = 1461446703485210103287273052203988822378723970341;

    address attacker;
    SwapHarness harness;

    function setUp() public {
        string memory rpc = vm.envOr("UNICHAIN_RPC_URL", string("https://mainnet.unichain.org"));
        vm.createSelectFork(rpc);
        attacker = makeAddr("fresh-attacker");
        harness = new SwapHarness(IPoolManager(PM));
    }

    // ---------------- helpers ----------------

    function _pid(PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k));
    }

    // hook1 USDC/XRP ts=10 : has live pendingFees >= MIN_REINVEST_AMOUNT both sides
    function _k1UsdcXrp() internal pure returns (PoolKey memory) {
        return PoolKey(USDC, XRP, 8388608, 10, HOOK1);
    }

    // hook1 ETH/AG ts=60 : thin pool, used for the swap + TWAP-guard probe
    function _k1EthAg() internal pure returns (PoolKey memory) {
        return PoolKey(address(0), AGa, 8388608, 60, HOOK1);
    }

    // hook2 USDC/XRP ts=10 : has an existing FRLM position + pendingFees
    function _k2UsdcXrp() internal pure returns (PoolKey memory) {
        return PoolKey(USDC, XRP, 8388608, 10, HOOK2);
    }

    function _bal(address t, address who) internal view returns (uint256) {
        if (t == address(0)) return who.balance;
        return IERC20(t).balanceOf(who);
    }

    function _logPool(string memory tag, address frlm, PoolKey memory k) internal view {
        bytes32 pid = _pid(k);
        (uint256 p0, uint256 p1) = IFRLM(frlm).getPendingFees(pid);
        (uint256 posId, uint128 liq,,) = IFRLM(frlm).getPositionInfo(pid);
        (uint256 shares,,) = IFRLM(frlm).getProtocolOwnedLiquidity(pid);
        console2.log("---", tag);
        console2.log("  pendingFees", p0, p1);
        console2.log("  positionId", posId);
        console2.log("  positionLiquidity", uint256(liq));
        console2.log("  protocolOwnedShares", shares);
        console2.log("  frlm token0 bal", _bal(k.currency0, frlm));
        console2.log("  frlm acc0", IFRLM(frlm).accountedBalances(k.currency0));
        console2.log("  frlm 6909-0", IPoolManager(PM).balanceOf(frlm, uint256(uint160(k.currency0))));
        console2.log("  frlm acc6909-0", IFRLM(frlm).accountedERC6909Balances(k.currency0));
    }

    // ---------------- 0. sanity: pool identity ----------------

    function test_pool_ids_match_live() public {
        assertEq(_pid(_k1UsdcXrp()), 0xbf12f5e68b1e1b3060bfb39b79794a0d5c1a723c0879281132b54887f87f928d, "k1 usdc/xrp");
        assertEq(_pid(_k1EthAg()), 0x93a9759d15116697734921cf31000f5f6a8bb4cf163ab837071d94c8a48efd36, "k1 eth/ag");
        assertEq(_pid(_k2UsdcXrp()), 0xe56f1855a315fe2984a401b8939e7c1c314070ea637e642acdc7ffed0d36387c, "k2 usdc/xrp");
    }

    // ---------------- 1. permissionless reinvest: attacker gain ----------------

    /// @dev Core probe (hook1, no existing FRLM position): a fresh caller triggers
    ///      take/burn + re-add on a pool with live pendingFees. Attacker must not profit.
    function test_reinvest_hook1_fresh_caller_no_gain() public {
        PoolKey memory k = _k1UsdcXrp();
        bytes32 pid = _pid(k);
        _logPool("hook1 USDC/XRP BEFORE", FRLM1, k);

        uint256 a0 = _bal(k.currency0, attacker);
        uint256 a1 = _bal(k.currency1, attacker);
        uint256 aeth = attacker.balance;

        vm.prank(attacker);
        bool ok;
        try IFRLM(FRLM1).reinvest(k) returns (bool r) {
            ok = r;
            console2.log("reinvest returned", r);
        } catch (bytes memory e) {
            console2.log("reinvest REVERTED, len", e.length);
        }
        console2.log("reinvest success flag", ok);

        assertEq(_bal(k.currency0, attacker), a0, "attacker gained token0");
        assertEq(_bal(k.currency1, attacker), a1, "attacker gained token1");
        assertEq(attacker.balance, aeth, "attacker gained ETH");
        _logPool("hook1 USDC/XRP AFTER", FRLM1, k);

        // accounting: ERC6909 ledger must equal PoolManager balance (no phantom 6909)
        uint256 pmBal = IPoolManager(PM).balanceOf(FRLM1, uint256(uint160(k.currency0)));
        assertEq(pmBal, IFRLM(FRLM1).accountedERC6909Balances(k.currency0), "6909 drift");
        // and the FRLM must not hold less real ERC20 than it has accounted (would be a surplus)
        assertGe(IERC20(k.currency0).balanceOf(FRLM1), IFRLM(FRLM1).accountedBalances(k.currency0), "surplus");
    }

    /// @dev Core probe (hook2, existing position): take/burn + increase-liquidity path.
    function test_reinvest_hook2_fresh_caller_no_gain() public {
        PoolKey memory k = _k2UsdcXrp();
        _logPool("hook2 USDC/XRP BEFORE", FRLM2, k);

        uint256 a0 = _bal(k.currency0, attacker);
        uint256 a1 = _bal(k.currency1, attacker);
        uint256 aeth = attacker.balance;

        vm.prank(attacker);
        try IFRLM(FRLM2).reinvest(k) returns (bool r) {
            console2.log("reinvest returned", r);
        } catch (bytes memory e) {
            console2.log("reinvest REVERTED, len", e.length);
        }

        assertEq(_bal(k.currency0, attacker), a0, "attacker gained token0");
        assertEq(_bal(k.currency1, attacker), a1, "attacker gained token1");
        assertEq(attacker.balance, aeth, "attacker gained ETH");
        _logPool("hook2 USDC/XRP AFTER", FRLM2, k);

        uint256 pmBal = IPoolManager(PM).balanceOf(FRLM2, uint256(uint160(k.currency0)));
        assertEq(pmBal, IFRLM(FRLM2).accountedERC6909Balances(k.currency0), "6909 drift");
    }

    /// @dev If reinvest created a position, it must be owned by the FRLM (protocol), never the caller.
    function test_reinvest_position_never_owned_by_caller() public {
        PoolKey memory k = _k1UsdcXrp();
        bytes32 pid = _pid(k);
        vm.prank(attacker);
        try IFRLM(FRLM1).reinvest(k) returns (bool) {} catch {}

        (uint256 posId,,,) = IFRLM(FRLM1).getPositionInfo(pid);
        if (posId != 0) {
            address owner = IPositionManager(POSM).ownerOf(posId);
            console2.log("position owner", owner);
            assertEq(owner, FRLM1, "position must be protocol-owned");
            assertTrue(owner != attacker, "position hijacked");
        } else {
            console2.log("no position created (reinvest no-op/revert)");
        }
    }

    /// @dev Variant: the attacker calls reinvest from *inside* their own PoolManager.unlock,
    ///      forcing the FRLM's `isUnlocked` branch (direct take/burn + modifyLiquiditiesWithoutUnlock).
    function test_reinvest_inside_attacker_unlock_no_gain() public {
        PoolKey memory k = _k2UsdcXrp();
        UnlockReinvest u = new UnlockReinvest(IPoolManager(PM), FRLM2);
        uint256 a0 = _bal(k.currency0, attacker);
        uint256 a1 = _bal(k.currency1, attacker);
        vm.prank(attacker);
        try u.go(k) {
            console2.log("in-unlock reinvest ok flag", u.lastOk());
        } catch (bytes memory e) {
            console2.log("in-unlock reinvest REVERTED len", e.length);
        }
        assertEq(_bal(k.currency0, attacker), a0, "attacker gained token0");
        assertEq(_bal(k.currency1, attacker), a1, "attacker gained token1");
        // accounting still consistent
        assertEq(
            IPoolManager(PM).balanceOf(FRLM2, uint256(uint160(k.currency0))),
            IFRLM(FRLM2).accountedERC6909Balances(k.currency0),
            "6909 drift after in-unlock reinvest"
        );
    }

    // ---------------- 2. fabricated key cannot move funds ----------------

    function test_reinvest_fabricated_key_is_noop() public {
        PoolKey memory fake = PoolKey(address(0xdead), address(0xbeef), 8388608, 60, HOOK1);
        uint256 before = address(FRLM1).balance;
        vm.prank(attacker);
        bool r = IFRLM(FRLM1).reinvest(fake);
        console2.log("fabricated reinvest returned", r);
        assertFalse(r, "fabricated key must return false");
        assertEq(address(FRLM1).balance, before, "no value moved");
    }

    function test_reinvest_wrong_hook_key_is_noop() public {
        PoolKey memory k = PoolKey(USDC, XRP, 8388608, 10, address(0x1234));
        vm.prank(attacker);
        bool r = IFRLM(FRLM1).reinvest(k);
        assertFalse(r, "wrong-hook key must return false");
    }

    // ---------------- 3. privileged sweep/withdraw reverts for attacker ----------------

    function test_privileged_functions_revert_for_attacker() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IFRLM(FRLM1).sweepExcessTokens(USDC, attacker);
        vm.expectRevert();
        IFRLM(FRLM1).sweepExcessERC6909(USDC, attacker);
        vm.expectRevert();
        IFRLM(FRLM1).withdrawProtocolLiquidity(_k1UsdcXrp(), 1, 0, 0, attacker);
        vm.stopPrank();
    }

    // ---------------- 4. dynamic fee is non-zero and bounded ----------------

    function test_dynamic_fee_nonzero_and_bounded() public {
        (uint256 b1, uint256 s1) = IDynamicFeeManager(DFM1).getFeeState(_pid(_k1UsdcXrp()));
        console2.log("hook1 USDC/XRP base,surge", b1, s1);
        assertGt(b1 + s1, 0, "fee cannot be zero");

        (uint256 b2, uint256 s2) = IDynamicFeeManager(DFM2).getFeeState(_pid(_k2UsdcXrp()));
        console2.log("hook2 USDC/XRP base,surge", b2, s2);
        assertGt(b2 + s2, 0, "fee cannot be zero");
        assertLt(b1 + s1, 1_000_000, "fee sane");
        assertLt(b2 + s2, 1_000_000, "fee sane");

        // no permissionless setter: only the policy owner can change the manual fee
        (uint24 mf, bool set) = IPolicyManager(0xE072D3C7567D4B326dDdE0F77062E6758Aec0eE7).getManualFee(
            _pid(_k1UsdcXrp())
        );
        console2.log("manualFee set?", set, uint256(mf));
    }

    // ---------------- 5. swap: fee is applied (exact hook-fee check) ----------------

    function _doEthAgSwap(uint256 amountIn) internal returns (uint256 ethIn, uint256 agOut, int256 d) {
        PoolKey memory k = _k1EthAg();
        vm.deal(address(harness), 1 ether);
        IPoolManager.SwapParams memory p =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -int256(amountIn), sqrtPriceLimitX96: MIN_SQRT});
        uint256 e0 = address(harness).balance;
        uint256 a0 = IERC20(AGa).balanceOf(address(harness));
        d = harness.swap(k, p);
        ethIn = e0 - address(harness).balance;
        agOut = IERC20(AGa).balanceOf(address(harness)) - a0;
    }

    function test_swap_applies_fee_and_attacker_cannot_profit() public {
        bytes32 pid = _pid(_k1EthAg());
        (uint256 base, uint256 surge) = IDynamicFeeManager(DFM1).getFeeState(pid);
        uint256 polShare = IPolicyManager(0xE072D3C7567D4B326dDdE0F77062E6758Aec0eE7).getPoolPOLShare(pid);
        console2.log("fee base+surge ppm", base + surge);
        console2.log("polShare ppm", polShare);

        // native ETH ERC-6909 id is 0
        uint256 fee6909Before = IPoolManager(PM).balanceOf(FRLM1, 0);
        uint256 amountIn = 0.001 ether;
        (uint256 ethIn, uint256 agOut, int256 d) = _doEthAgSwap(amountIn);
        uint256 fee6909After = IPoolManager(PM).balanceOf(FRLM1, 0);

        console2.log("swap delta", d);
        console2.log("AG out", agOut);
        console2.log("ETH in", ethIn);
        console2.log("hookFee 6909 delta", fee6909After - fee6909Before);

        // v4 semantics: the hook's +beforeSwapDelta is netted against the specified amount, so the
        // swapper pays exactly the specified input; the hook fee is routed to the FRLM (protocol).
        assertEq(ethIn, amountIn, "swapper pays exactly the specified input");
        assertGt(agOut, 0, "swapper received nothing");
        uint256 expectedHookFee = amountIn * (base + surge) / 1e6 * polShare / 1e6;
        assertGt(expectedHookFee, 0, "fee must be non-zero");
        assertEq(fee6909After - fee6909Before, expectedHookFee, "hook fee minted to FRLM");
    }

    /// @dev TWAP guard: after a swap that moves the tick well past tickRangeTolerance, a
    ///      direct permissionless reinvest must be refused (returns false), i.e. an attacker
    ///      cannot force the FRLM to add liquidity at a manipulated price.
    function test_reinvest_twap_guard_blocks_after_price_move() public {
        uint256 tol = uint256(uint24(IFRLM(FRLM1).tickRangeTolerance()));
        console2.log("tickRangeTolerance", tol);

        // push the thin ETH/AG pool hard with a swap
        _doEthAgSwap(0.01 ether);

        // now try to reinvest: spot vs 60s TWAP deviation should exceed the tolerance
        vm.prank(attacker);
        bool r = IFRLM(FRLM1).reinvest(_k1EthAg());
        console2.log("reinvest after price move returned", r);
        assertFalse(r, "TWAP guard should block reinvest after a large move");
    }

    // ---------------- 6. donate is pay-in only ----------------

    function test_donate_payin_only() public {
        PoolKey memory k = _k1EthAg();
        vm.deal(attacker, 1 ether);
        uint256 before = attacker.balance;
        vm.prank(attacker);
        (uint256 d0, uint256 d1) = IFRLM(FRLM1).donate{value: 1}(k, 1, 0);
        uint256 afterBal = attacker.balance;
        console2.log("donated", d0, d1);
        assertEq(before - afterBal, 1, "donate only takes from caller");
        assertEq(d0, 1);
        assertEq(d1, 0);
    }
}
