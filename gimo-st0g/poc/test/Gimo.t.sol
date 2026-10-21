// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IStakeManager, IStakePool, IValidator} from "../src/Interfaces.sol";

/// @notice Read-only fork analysis of Gimo st0G (0G chain, chainId 16661).
///         Every test runs on a local anvil fork. No transaction is signed or broadcast.
contract GimoForkTest is Test {
    address constant MGR = 0xAc06d1Df23a4Fa00981aFAC0f33A5936Bd2135aF; // StakeManager (ERC1967 proxy)
    address constant IMPL = 0x7A5E1B999a665f2b89e5F6eAE32DF9471De193C7; // StakeManager impl
    address constant POOL = 0x136b56554671976EF8366B01B31185F91Ae696AF; // StakePool (ERC1967 proxy)
    address constant TOKEN = 0x7bBC63D01CA42491c3E084C941c3E86e55951404; // st0G
    address constant VALIDATOR = 0xeC856948CF28a7c36E4c0D7877d027bA0a8AF17d;

    uint256 constant FORK_BLOCK = 47_841_263;

    IStakeManager mgr = IStakeManager(MGR);
    IStakePool pool = IStakePool(POOL);
    IERC20 token = IERC20(TOKEN);

    function setUp() public {
        vm.createSelectFork(vm.envOr("OG_RPC_URL", string("https://evmrpc.0g.ai")), FORK_BLOCK);
    }

    function _vals() internal view returns (address[] memory v) {
        v = mgr.getValidatorsOf(POOL);
    }

    // ---------------------------------------------------------------- live state

    function test_live_state() public view {
        (uint256 era, uint256 bond, uint256 unbond, uint256 active) = mgr.poolInfoOf(POOL);
        uint256 supply = token.totalSupply();
        uint256 rate = mgr.getRate();
        uint256 delegated = pool.getTotalDelegated(_vals());
        uint256 vShares = IValidator(VALIDATOR).delegatorShares();
        uint256 vTokens = IValidator(VALIDATOR).tokens();

        console2.log("block.number          ", block.number);
        console2.log("block.timestamp       ", block.timestamp);
        console2.log("block.chainid         ", block.chainid);
        console2.log("currentEra            ", mgr.currentEra());
        console2.log("latestEra             ", mgr.latestEra());
        console2.log("eraSeconds            ", mgr.eraSeconds());
        console2.log("eraOffset             ", mgr.eraOffset());
        console2.log("unbondingDuration     ", mgr.unbondingDuration());
        console2.log("rate (0G per st0G)    ", rate);
        console2.log("totalSupply st0G      ", supply);
        console2.log("poolInfo.era          ", era);
        console2.log("poolInfo.bond         ", bond);
        console2.log("poolInfo.unbond       ", unbond);
        console2.log("poolInfo.active       ", active);
        console2.log("getTotalDelegated     ", delegated);
        console2.log("pool liquid 0G balance", POOL.balance);
        console2.log("manager 0G balance    ", MGR.balance);
        console2.log("manager st0G balance  ", token.balanceOf(MGR));
        console2.log("totalProtocolFee      ", mgr.totalProtocolFee());
        console2.log("rateChangeLimit       ", mgr.rateChangeLimit());
        console2.log("minStakeAmount        ", mgr.minStakeAmount());
        console2.log("nextUnstakeIndex      ", mgr.nextUnstakeIndex());
        console2.log("validator shares      ", vShares);
        console2.log("validator tokens      ", vTokens);
        console2.log("last eraRate[400]     ", mgr.eraRate(400));
        console2.log("prev eraRate[399]     ", mgr.eraRate(399));

        assertEq(block.chainid, 16661);
        assertEq(mgr.lsdToken(), TOKEN);
        assertEq(pool.stakeManagerAddress(), MGR);
        assertEq(rate, (active * 1e18) / supply, "rate == floor(active*1e18/supply)");
        // mid-era: delegated = active + unbond - bond (nothing is delegated for era-400 flows yet)
        assertEq(delegated, active + unbond - bond, "delegated reconciles to ledger");
        assertEq(mgr.rateChangeLimit(), 0, "no per-era rate cap is configured");
        assertEq(mgr.unbondingDuration(), 3);
    }

    // ------------------------------------------------------- newEra access control

    function test_newEra_is_permissionless_once_per_era() public {
        uint256 nextEra = mgr.latestEra() + 1;
        uint256 boundary = (nextEra + mgr.eraOffset()) * mgr.eraSeconds();

        // 1) one second before the era boundary -> EraNotMatch
        vm.warp(boundary - 1);
        vm.prank(address(0xBEEF));
        vm.expectRevert(); // EraNotMatch()
        mgr.newEra();

        // 2) at the boundary -> anyone can execute it
        vm.warp(boundary + 13); // keeper on 0G is consistently 12-17s late
        vm.prank(address(0xBEEF));
        mgr.newEra();
        assertEq(mgr.latestEra(), nextEra);

        // 3) a second call in the same era -> EraNotMatch
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        mgr.newEra();
    }

    // -------------------------------------------------- stake/unstake round trip

    function test_no_roundtrip_profit_without_rate_move() public {
        address attacker = address(0xA77AC4);
        uint256 X = 1_000e18;
        vm.deal(attacker, X + 1 ether);
        vm.prank(attacker);
        token.approve(MGR, type(uint256).max);

        uint256 supply0 = token.totalSupply();
        uint256 rate0 = mgr.getRate();

        vm.prank(attacker);
        mgr.stakeWithPool{value: X}(POOL, "jit");
        uint256 shares = token.balanceOf(attacker);
        assertEq(shares, (X * 1e18) / rate0);
        assertEq(token.totalSupply(), supply0 + shares);

        uint256 idx = mgr.nextUnstakeIndex();
        vm.prank(attacker);
        mgr.unstakeWithPool(POOL, shares);
        (,,, uint256 claim) = mgr.unstakeAtIndex(idx);

        console2.log("staked 0G          ", X);
        console2.log("minted st0G        ", shares);
        console2.log("unstake claim 0G   ", claim);
        console2.log("round-trip delta   ", int256(claim) - int256(X));
        assertLe(claim, X, "round trip cannot create 0G (floor rounding)");
        // unstaking does not move the rate
        assertEq(mgr.getRate(), rate0);
    }

    // ------------------------------------------- donation to the pool does nothing

    function test_pool_donation_does_not_change_numerator() public {
        address donor = address(0xD00A7);
        vm.deal(donor, 5_000e18);
        uint256 before = pool.getTotalDelegated(_vals());
        uint256 pendingBefore = pool.pendingBond();

        vm.prank(donor);
        (bool ok,) = POOL.call{value: 5_000e18}("");
        assertTrue(ok, "pool receive() accepts plain 0G");

        uint256 afterBal = pool.getTotalDelegated(_vals());
        console2.log("pool liquid before donation", POOL.balance - 5_000e18);
        console2.log("getTotalDelegated before   ", before);
        console2.log("getTotalDelegated after    ", afterBal);
        assertEq(afterBal, before, "donation is NOT in getTotalDelegated");
        assertEq(pool.pendingBond(), pendingBefore, "donation is NOT in pendingBond");
    }

    // ----------------------------------------------------- JIT around newEra()

    /// Simulates exactly one era of consensus-layer staking rewards (R) by mocking
    /// StakePool.getTotalDelegated (the 0G validator layer is a precompile whose reward
    /// accrual anvil cannot advance).  Everything else (stake / newEra / rate / supply /
    /// unstake / fee mint) is the real deployed code.
    ///
    /// Runs the counterfactual (no JIT deposit) and the attack in two fresh forks of the
    /// same block, so the holder loss is *measured*, not modelled.
    function test_jit_capture_of_one_era_reward() public {
        uint256 R = 5_751e18; // eraRate[400]-eraRate[399] = 0.000402242 * 14.2989M st0G
        string memory rpc = vm.envOr("OG_RPC_URL", string("https://evmrpc.0g.ai"));

        // ---------------- counterfactual: one era of rewards, no JIT deposit
        uint256 S0 = token.totalSupply();
        uint256 r0 = mgr.getRate();
        (, , , uint256 A) = mgr.poolInfoOf(POOL);
        _mockPoolCalls();
        vm.mockCall(
            POOL,
            abi.encodeWithSelector(IStakePool.getTotalDelegated.selector),
            abi.encode(A + R)
        );
        vm.warp(((mgr.latestEra() + 1) + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        mgr.newEra();
        uint256 r1NoJit = mgr.getRate();

        // ---------------- attack: stake just before the same era flip
        vm.createSelectFork(rpc, FORK_BLOCK);
        address attacker = address(0xA77ACC);
        uint256 X = 19_370_546e18; // ~1x TVL
        vm.deal(attacker, X + 1 ether);
        vm.prank(attacker);
        token.approve(MGR, type(uint256).max);
        _mockPoolCalls();
        vm.mockCall(
            POOL,
            abi.encodeWithSelector(IStakePool.getTotalDelegated.selector),
            abi.encode(A + X + R)
        );

        vm.prank(attacker);
        mgr.stakeWithPool{value: X}(POOL, "jit");
        uint256 shares = token.balanceOf(attacker);

        vm.warp(((mgr.latestEra() + 1) + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        vm.prank(attacker);
        mgr.newEra();
        uint256 r1 = mgr.getRate();

        uint256 idx = mgr.nextUnstakeIndex();
        vm.prank(attacker);
        mgr.unstakeWithPool(POOL, shares);
        (,,, uint256 claim) = mgr.unstakeAtIndex(idx);

        int256 pnl = int256(claim) - int256(X);
        uint256 loss = (S0 * (r1NoJit - r1)) / 1e18;

        console2.log("R (one era reward)  ", R);
        console2.log("r0 (pre)            ", r0);
        console2.log("r1 no-JIT           ", r1NoJit);
        console2.log("r1 with JIT         ", r1);
        console2.log("attacker shares     ", shares);
        console2.log("staked 0G           ", X);
        console2.log("claim 0G            ", claim);
        console2.log("attacker pnl 0G     ", uint256(pnl) / 1e18);
        console2.log("holder loss 0G      ", loss / 1e18);

        assertGt(pnl, 0, "JIT captures part of the era reward");
        assertApproxEqRel(loss, uint256(pnl), 0.01e18, "holder loss == attacker gain (value conserved)");
        // pnl == f * (1-fee) * R with f = shares/(S0+shares)
        uint256 f = (shares * 1e18) / (S0 + shares);
        uint256 netR = (R * (1e18 - mgr.protocolFeeCommission())) / 1e18;
        assertApproxEqRel(uint256(pnl), (netR * f) / 1e18, 0.02e18, "pnl ~= f * (1-fee) * R");

        // economics: return per unit of locked capital for one 3-era unbond cycle
        uint256 retBps = (uint256(pnl) * 10_000) / X; // bps of capital per cycle
        uint256 honest3 = (3 * (r1 - r0) * 10_000) / r0; // bps from 3 eras of honest staking
        console2.log("JIT bps per 3-era cycle   ", retBps);
        console2.log("honest staking 3-era bps  ", honest3);
        assertLt(retBps, honest3, "JIT is dominated by simply staying staked");
    }

    function _mockPoolCalls() internal {
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.updateValidators.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.undelegateMulti.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.delegateMulti.selector), "");
    }

    /// With no reward accrued, adding a huge deposit must not change the rate.
    function test_jit_zero_reward_is_neutral() public {
        address[] memory vals = _vals();
        (, , , uint256 A) = mgr.poolInfoOf(POOL);
        uint256 S0 = token.totalSupply();
        uint256 r0 = mgr.getRate();

        address attacker = address(0xB0B);
        uint256 X = 5_000_000e18;
        vm.deal(attacker, X + 1 ether);

        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.updateValidators.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.undelegateMulti.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.delegateMulti.selector), "");

        vm.prank(attacker);
        mgr.stakeWithPool{value: X}(POOL, "");
        vm.mockCall(
            POOL,
            abi.encodeWithSelector(IStakePool.getTotalDelegated.selector),
            abi.encode(A + X) // no reward
        );
        vm.warp(((mgr.latestEra() + 1) + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        mgr.newEra();
        uint256 r1 = mgr.getRate();
        console2.log("r0", r0);
        console2.log("r1 (zero reward)", r1);
        assertApproxEqAbs(r1, r0, 2, "a pure deposit neither mints nor destroys rate");
        assertEq(S0 < token.totalSupply(), true);
    }

    /// rateChangeLimit == 0 disables the per-era cap: a large (keeper-lag) reward is accepted.
    /// With a non-zero cap the same move reverts.
    function test_uncapped_rate_move_when_limit_is_zero() public {
        address[] memory vals = _vals();
        (, , , uint256 A) = mgr.poolInfoOf(POOL);
        uint256 S0 = token.totalSupply();

        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.updateValidators.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.undelegateMulti.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.delegateMulti.selector), "");

        uint256 bigR = A / 10; // +10% NAV in one era (e.g. 30+ days of keeper lag)

        // (a) with the live limit == 0 the move is accepted
        vm.mockCall(
            POOL,
            abi.encodeWithSelector(IStakePool.getTotalDelegated.selector),
            abi.encode(A + bigR)
        );
        vm.warp(((mgr.latestEra() + 1) + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        mgr.newEra();
        uint256 r1 = mgr.getRate();
        console2.log("rate after +10% uncapped move", r1);
        assertGt(r1, (mgr.eraRate(400) * 105) / 100);

        // (b) restore the fork, set the documented max cap (0.5%) as the owner, same move reverts
        vm.createSelectFork(vm.envOr("OG_RPC_URL", string("https://evmrpc.0g.ai")), FORK_BLOCK);
        address owner = IStakeManager(MGR).owner();
        vm.prank(owner);
        mgr.setRateChangeLimit(5e15);
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.updateValidators.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.undelegateMulti.selector), "");
        vm.mockCall(POOL, abi.encodeWithSelector(IStakePool.delegateMulti.selector), "");
        vm.mockCall(
            POOL,
            abi.encodeWithSelector(IStakePool.getTotalDelegated.selector),
            abi.encode(A + bigR)
        );
        vm.warp(((mgr.latestEra() + 1) + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        vm.expectRevert();
        mgr.newEra();
        console2.log("capped move reverted as expected (RateChangeExceedLimit)");
        assertEq(S0 > 0, true);
    }

    // ------------------------------------------------------------ hard gates

    function test_token_mint_is_minter_only() public {
        address stranger = address(0xBAD);
        vm.prank(stranger);
        (bool ok, bytes memory ret) = TOKEN.call(
            abi.encodeWithSignature("mint(address,uint256)", stranger, 1_000_000e18)
        );
        assertFalse(ok, "stranger cannot mint st0G");
        console2.logBytes(ret);
        // and the minter itself cannot be re-pointed by a stranger
        vm.prank(stranger);
        (ok,) = TOKEN.call(abi.encodeWithSignature("updateMinter(address)", stranger));
        assertFalse(ok, "stranger cannot re-point minter");
    }

    function test_withdraw_lifecycle() public {
        address user = address(0xC0FFEE);
        uint256 X = 100e18;
        vm.deal(user, X);
        vm.prank(user);
        token.approve(MGR, type(uint256).max);

        vm.prank(user);
        mgr.stakeWithPool{value: X}(POOL, "wd");
        uint256 shares = token.balanceOf(user);
        uint256 idx = mgr.nextUnstakeIndex();
        vm.prank(user);
        mgr.unstakeWithPool(POOL, shares);

        // 1) not matured yet -> nothing to withdraw
        vm.warp(block.timestamp + 1 days);
        vm.prank(user);
        vm.expectRevert();
        mgr.withdraw();

        // 2) matured after unbondingDuration eras -> pool pays the recorded claim
        uint256 era = mgr.currentEra();
        vm.warp((era + mgr.unbondingDuration() + mgr.eraOffset()) * mgr.eraSeconds() + 13);
        uint256 balBefore = user.balance;
        vm.prank(user);
        mgr.withdraw();
        (,,, uint256 amt) = mgr.unstakeAtIndex(idx);
        console2.log("withdraw claim 0G", amt);
        console2.log("0G received      ", user.balance - balBefore);
        assertEq(user.balance - balBefore, amt, "paid exactly the recorded claim");

        // 3) replay is impossible
        vm.prank(user);
        vm.expectRevert();
        mgr.withdraw();

        // 4) pointing withdrawWithPool at a non-bonded address cannot extract anything
        vm.prank(user);
        vm.expectRevert();
        mgr.withdrawWithPool(address(0xDEAD));
    }

    function test_privileged_paths_revert_for_stranger() public {
        address stranger = address(0xBAD);
        vm.startPrank(stranger);
        vm.expectRevert();
        mgr.withdrawProtocolFee(stranger);
        vm.expectRevert();
        mgr.setRateChangeLimit(1);
        vm.expectRevert();
        mgr.setProtocolFeeCommission(1);
        vm.expectRevert();
        mgr.addStakePool(stranger);
        vm.expectRevert();
        mgr.upgradeTo(stranger);
        vm.stopPrank();
    }
}
