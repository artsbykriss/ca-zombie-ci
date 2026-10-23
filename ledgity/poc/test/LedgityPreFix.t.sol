// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import { stdError } from "forge-std/StdError.sol";
import { IVault, IERC20 } from "../src/Interfaces.sol";

/**
 * @title Ledgity Yield — pre-fix implementation live on all chains (ZH4-PASS5 P5-09)
 *
 * Repo fix f6ec0e0 (2026-09-10, VaultLiquidityModule) + 968786c (2026-07-14, LedgityYieldVault)
 * are NOT deployed: all vault proxies point at impl 0x4D462f5f... (source == repo commit f7f76d2).
 *
 * This suite proves on a mainnet fork:
 *   (a) the deployed impl is the pre-fix one on Ethereum + Base;
 *   (b) NO unprivileged path exists (attacker cannot advance lastFeeTime, cannot set fee rates,
 *       cannot call processRequests) -> E-U = $0;
 *   (c) the underflow DoS is reachable ONLY via a privileged owner call after a stale fee
 *       checkpoint (managementFeeRate==0 for >365d);
 *   (d) the duplicate-request-id double-pay is reachable ONLY by the liquidityManager.
 *
 * read-only; fork-only; no mainnet transactions.
 */
contract LedgityPreFixTest is Test {
  // EIP-1967 implementation slot
  bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
  address constant PRE_FIX_IMPL = 0x4D462f5fD60b1E4CB3057856D4fce85B48d80bD9;

  // Ethereum mainnet
  address constant VAULT_USD_ETH = 0x3C769d0e8D21d380228dFB7918c6933bb6ecB6D4;
  address constant VAULT_EUR_ETH = 0x20968165B7d2cDF33aF632aAB3e0539848d44BC8;
  address constant USDC_ETH = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant OWNER = 0x972c17D0adA071db4a0395505dD3Ad0a80809053; // GlobalOwner.owner()
  address constant LIQUIDITY_MANAGER = 0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac;

  // Base
  address constant VAULT_USD_BASE = 0x916f179D5D9B7d8Ad815AC2f8570aabF0C6a6e38;
  address constant VAULT_EUR_BASE = 0xFaA1e3720e6Ef8cC76A800DB7B3dF8944833b134;

  address constant ATTACKER = address(0xBEEF);

  uint256 ethFork;
  uint256 baseFork;

  function _ethRpc() internal view returns (string memory) {
    string memory r = vm.envOr("FORK_RPC_URL", string(""));
    if (bytes(r).length == 0) r = vm.envOr("RPC_URL", string(""));
    if (bytes(r).length == 0) r = "https://ethereum-rpc.publicnode.com";
    return r;
  }
  function _baseRpc() internal view returns (string memory) {
    string memory r = vm.envOr("BASE_RPC_URL", string(""));
    if (bytes(r).length == 0) r = "https://mainnet.base.org";
    return r;
  }

  function setUp() public {
    ethFork = vm.createSelectFork(_ethRpc());
  }

  function _implOf(address proxy) internal view returns (address) {
    return address(uint160(uint256(vm.load(proxy, IMPL_SLOT))));
  }

  // ---------------------------------------------------------------- (a)

  function test_a1_ethereumVaults_pointAtPreFixImpl() public view {
    assertEq(_implOf(VAULT_USD_ETH), PRE_FIX_IMPL, "lyUSD impl");
    assertEq(_implOf(VAULT_EUR_ETH), PRE_FIX_IMPL, "lyEUR impl");
  }

  function test_a2_baseVaults_pointAtPreFixImpl() public {
    vm.createSelectFork(_baseRpc());
    assertEq(_implOf(VAULT_USD_BASE), PRE_FIX_IMPL, "base lyUSD impl");
    assertEq(_implOf(VAULT_EUR_BASE), PRE_FIX_IMPL, "base lyEUR impl");
  }

  // ---------------------------------------------------------------- (b) E-U gate

  function test_b1_state_is_staleFeeCheckpoint() public view {
    // managementFeeRate == 0 and lastFeeTime has never advanced since the proxy was
    // created (2025-11-17) -> the exact precondition the f6ec0e0 fix protects against.
    assertEq(IVault(VAULT_USD_ETH).managementFeeRate(), 0);
    assertEq(IVault(VAULT_USD_ETH).performanceFeeRate(), 0);
    assertGt(block.timestamp, IVault(VAULT_USD_ETH).lastFeeTime() + 300 days);
    assertFalse(IVault(VAULT_USD_ETH).paused());
  }

  function test_b2_attacker_cannotAdvanceLastFeeTime() public {
    uint256 before = IVault(VAULT_USD_ETH).lastFeeTime();
    vm.warp(block.timestamp + 30 days);
    // attacker calls the permissionless harvestFees()
    vm.prank(ATTACKER);
    IVault(VAULT_USD_ETH).harvestFees();
    // pre-fix: feeShares==0 -> lastFeeTime is NOT advanced (bug); attacker can only make it stale
    assertEq(IVault(VAULT_USD_ETH).lastFeeTime(), before, "attacker cannot advance lastFeeTime");
    // and the view still works (no underflow while rate==0)
    (uint256 fs,) = IVault(VAULT_USD_ETH).getFeeData();
    assertEq(fs, 0);
  }

  function test_b3_attacker_cannotCallPrivilegedPaths() public {
    uint256[] memory ids = new uint256[](1);
    ids[0] = 0;

    vm.startPrank(ATTACKER);
    vm.expectRevert(); // Ownable: caller is not the owner
    IVault(VAULT_USD_ETH).updateFeeRates(1e27, 0, 0);

    vm.expectRevert(); // OnlyLiquidityManager
    IVault(VAULT_USD_ETH).processRequests(ids, 0);

    vm.expectRevert(); // Ownable
    IVault(VAULT_USD_ETH).burnAndRemintBlacklistedShares(address(0xBEEF), ATTACKER);
    vm.stopPrank();
  }

  // ---------------------------------------------------------------- (c) privileged DoS

  function test_c1_ownerEnablingMgmtFees_afterStaleCheckpoint_bricks_vault() public {
    // attacker cannot do this; simulate the OWNER (GlobalOwner.owner()) enabling management fees
    // after the >1y zero-fee period that the pre-fix code fails to checkpoint.
    vm.warp(IVault(VAULT_USD_ETH).lastFeeTime() + 366 days);

    vm.prank(OWNER);
    IVault(VAULT_USD_ETH).updateFeeRates(1e27, 0, 0); // 100% mgmt fee (legal, <= RAY)

    // pre-fix getFeeData(): (currentAssets + 1) - managementFeeAssets underflows -> Panic(0x11)
    vm.expectRevert(stdError.arithmeticError);
    IVault(VAULT_USD_ETH).getFeeData();

    // ...which bricks convertToAssets/convertToShares -> deposit/withdraw/redeem/harvestFees
    vm.expectRevert(stdError.arithmeticError);
    IVault(VAULT_USD_ETH).harvestFees();

    vm.prank(ATTACKER);
    vm.expectRevert(stdError.arithmeticError);
    IVault(VAULT_USD_ETH).requestWithdrawal{ value: 1e15 }(1e18);

    // recoverable by owner (set mgmt fee back to 0) -> category P/DoS, not S
    vm.prank(OWNER);
    IVault(VAULT_USD_ETH).updateFeeRates(0, 0, 0);
    (uint256 fs,) = IVault(VAULT_USD_ETH).getFeeData();
    assertEq(fs, 0, "owner can recover by zeroing mgmt fee");
  }

  // ---------------------------------------------------------------- (e) fix math (model)

  function _mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    return (a * b + c - 1) / c;
  }

  /// @dev Models the 6-line VaultLiquidityModule fix on the live numbers: pre-fix the stale
  ///      checkpoint makes managementFeeAssets > currentAssets+1 (underflow); the fix resets
  ///      lastFeeTime when management fees are enabled, so elapsed==0 and no underflow occurs.
  function test_e1_fixMath_preventsUnderflow() public view {
    uint256 CA = IVault(VAULT_USD_ETH).totalAssets();
    uint256 RAY = 1e27;
    uint256 staleElapsed = 366 days;
    uint256 mfaPre = _mulDivUp(_mulDivUp(CA, RAY, RAY), staleElapsed, 365 days);
    assertGt(mfaPre, CA + 1, "pre-fix mgmtFeeAssets exceeds assets+1 -> underflow");
    uint256 mfaFixed = _mulDivUp(_mulDivUp(CA, RAY, RAY), 0, 365 days); // lastFeeTime reset by fix
    assertEq((CA + 1) - mfaFixed, CA + 1, "fixed math does not underflow");
  }

  // ---------------------------------------------------------------- (d) privileged double-pay
  function _createPendingRequest(uint256 amount) internal returns (uint256 id, uint256 reqAmount) {
    vm.deal(ATTACKER, 1 ether);
    deal(USDC_ETH, ATTACKER, amount);
    vm.startPrank(ATTACKER);
    IERC20(USDC_ETH).approve(VAULT_USD_ETH, amount);
    IVault(VAULT_USD_ETH).deposit(amount, ATTACKER);
    uint256 shares = IERC20(VAULT_USD_ETH).balanceOf(ATTACKER);
    IVault(VAULT_USD_ETH).requestWithdrawal{ value: 1e15 }(shares);
    vm.stopPrank();
    id = IVault(VAULT_USD_ETH).getWithdrawalRequestCount() - 1;
    (, reqAmount,,) = IVault(VAULT_USD_ETH).withdrawalRequests(id);
  }

  function test_d1_unprivileged_cannotProcessRequests() public {
    (uint256 id,) = _createPendingRequest(400e6);
    uint256[] memory ids = new uint256[](2);
    ids[0] = id;
    ids[1] = id;
    vm.prank(ATTACKER);
    vm.expectRevert(); // OnlyLiquidityManager
    IVault(VAULT_USD_ETH).processRequests(ids, 0);
  }

  function test_d2_duplicateIds_doublePay_byLiquidityManager() public {
    (uint256 id, uint256 reqAmount) = _createPendingRequest(400e6);
    assertGt(reqAmount, 0, "request created");
    uint256 bufferBefore = IVault(VAULT_USD_ETH).getBufferAssets();
    assertGe(bufferBefore, 2 * reqAmount, "buffer covers 2x");

    uint256[] memory ids = new uint256[](2);
    ids[0] = id;
    ids[1] = id;

    uint256 balBefore = IERC20(USDC_ETH).balanceOf(ATTACKER);
    vm.prank(LIQUIDITY_MANAGER);
    IVault(VAULT_USD_ETH).processRequests(ids, 0);
    uint256 received = IERC20(USDC_ETH).balanceOf(ATTACKER) - balBefore;

    emit log_named_uint("single request amount (USDC 6dp)", reqAmount);
    emit log_named_uint("attacker received for ONE request (USDC 6dp)", received);
    // the same request id was paid twice
    assertEq(received, 2 * reqAmount, "one request paid twice");
  }
}
