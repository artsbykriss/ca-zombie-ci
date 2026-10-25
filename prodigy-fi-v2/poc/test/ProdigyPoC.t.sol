// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

/// @title Prodigy.Fi V2 (Base) — external-unprivileged extraction PoC
/// @notice Read-only fork test. Every candidate value-moving path is probed from a
///         fresh attacker EOA. Success of this suite == "no unprivileged path works".
///         No mainnet transaction is ever signed or sent.
contract ProdigyPoC is Test {
    // ---- Base mainnet addresses (verified on-chain at block below) ----
    address constant PM          = 0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7; // PositionManager proxy (UUPS)
    address constant PM_IMPL     = 0xB1522E3514ADFA6CbAcd6675378FCe03e1b97dd8; // unverified impl
    address constant POOL_V2     = 0xe1303B2514755A72da4AcA9B917d96F16c842c80; // funded collateral pool
    address constant POOL_V1     = 0x864cd49392a4348b5da5337623d994151610D0a3; // old pool (0 balance)
    address constant VAULT0      = 0xD6EE85424b29C8055b9cC71FAC0660CB5BaF35FB; // vault #0
    address constant VAULT_LAST  = 0xd1A1513B3E672eEBD42E7AB2A0a99bE372B77B90; // vault #1713
    address constant WETH        = 0x4200000000000000000000000000000000000006;
    address constant USDC        = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant CBBTC       = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address constant OWNER       = 0xB17A226B38A576738C1ad5E6ACC273a1A3A99A9F; // single EOA

    bytes32 constant IMPL_SLOT  = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    uint256 constant FORK_BLOCK = 53_044_841;

    address attacker;

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", vm.envOr("FORK_RPC_URL", string("https://base-rpc.publicnode.com")));
        vm.createSelectFork(rpc, FORK_BLOCK);
        attacker = vm.addr(0xA11CE); // fresh, unprivileged, never funded
    }

    // ------------------------------------------------------------------
    // 1. Live value: funds sit in the collateral pool, not in the vaults
    // ------------------------------------------------------------------
    function test_pool_holds_the_funds() public {
        uint256 usdc  = IERC20(USDC).balanceOf(POOL_V2);
        uint256 weth  = IERC20(WETH).balanceOf(POOL_V2);
        uint256 cbbtc = IERC20(CBBTC).balanceOf(POOL_V2);
        emit log_named_uint("pool USDC (6dp)", usdc);
        emit log_named_uint("pool WETH (18dp)", weth);
        emit log_named_uint("pool cbBTC (8dp)", cbbtc);
        assertGt(usdc, 0);
        assertGt(weth, 0);
        assertGt(cbbtc, 0);
        // v1 pool empty
        assertEq(IERC20(USDC).balanceOf(POOL_V1), 0);
        // PositionManager itself holds nothing
        assertEq(IERC20(USDC).balanceOf(PM), 0);
        assertEq(PM.balance, 0);
    }

    function test_vaults_hold_no_tokens_directly() public view {
        // 1714 vaults are EIP-1167 clones; every one has collateralPool() == POOL_V2.
        // Sampling proves no vault holds collateral directly.
        address[6] memory vs = [VAULT0, VAULT_LAST, 0x2e116d512bd75C4d1A12546175E2c5b13084c481,
            0x0bc58eb2Abe1e15193769d8Dd57625190Bd6fe50, 0x5E0aF267B051c6175F2eFc309AcAdFa01185d2ba,
            0x31b35051BeA8da2E96F049d807FB1644904cDC1C];
        for (uint256 i; i < vs.length; ++i) {
            assertEq(IERC20(USDC).balanceOf(vs[i]), 0);
            assertEq(IERC20(WETH).balanceOf(vs[i]), 0);
            assertEq(IERC20(CBBTC).balanceOf(vs[i]), 0);
            assertEq(vs[i].balance, 0);
        }
    }

    // ------------------------------------------------------------------
    // 2. Collateral pool: every outbound path is caller-keyed or vault-gated
    // ------------------------------------------------------------------
    function test_pool_withdraw_reverts_for_stranger() public {
        vm.prank(attacker);
        (bool ok, bytes memory ret) = POOL_V2.call(abi.encodeWithSelector(0xf3fef3a3, USDC, uint256(1)));
        assertFalse(ok, "withdraw must revert for a stranger");
        assertEq(_reason(ret), "CollateralPoolV2: insufficient withdrawable balance");
        vm.prank(attacker);
        (ok, ret) = POOL_V2.call(abi.encodeWithSelector(0xf3fef3a3, WETH, uint256(1)));
        assertFalse(ok);
        assertEq(_reason(ret), "CollateralPoolV2: insufficient withdrawable balance");
    }

    function test_pool_vault_only_functions_revert() public {
        vm.startPrank(attacker);
        (bool ok, bytes memory ret) = POOL_V2.call(abi.encodeWithSelector(0x1ea734b6, USDC, uint256(1))); // processUserDeposit
        assertFalse(ok); assertEq(_reason(ret), "CollateralPoolV2: not registered vault");

        (ok, ret) = POOL_V2.call(abi.encodeWithSelector(0xd5735e7d, VAULT0)); // vault settle/withdraw
        assertFalse(ok); assertEq(_reason(ret), "CollateralPoolV2: not registered vault");

        (ok, ret) = POOL_V2.call(abi.encodeWithSelector(0x05c4fdf9, attacker, attacker)); // registerVault
        assertFalse(ok); assertEq(_reason(ret), "CollateralPool: Caller is not factory");

        (ok, ret) = POOL_V2.call(abi.encodeWithSelector(0x3e99414e, VAULT0, true)); // approveVault
        assertFalse(ok); assertEq(_reason(ret), "CollateralPoolV2: approve with not vault owner");
        vm.stopPrank();
    }

    function test_pool_owner_only_reverts() public {
        vm.startPrank(attacker);
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0x5bb47808, attacker)));   // setFactory
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0x76ce28f1, USDC, true)));  // setWhitelistedToken
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0x9d73d725, USDC, true)));  // setWhitelistedLP
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0xf2fde38b, attacker)));    // transferOwnership
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0x4f1ef286, attacker, bytes("")))); // upgradeToAndCall
        assertFalse(_ok(POOL_V2, abi.encodeWithSelector(0xc4d66de8, attacker)));    // initialize (already init)
        vm.stopPrank();
    }

    /// The selector 0x715018a6 (renounceOwnership in OZ) is a *disabled no-op stub*
    /// on this deployment: it STOPs and moves nothing. Calling it changes no state.
    function test_renounce_selector_is_noop() public {
        uint256 balBefore = POOL_V2.balance;
        vm.prank(attacker);
        (bool ok, ) = POOL_V2.call(hex"715018a6");
        assertTrue(ok);
        assertEq(POOL_V2.balance, balBefore);
        // owner is unchanged
        (bool ok2, bytes memory r) = POOL_V2.staticcall(abi.encodeWithSelector(0x8da5cb5b));
        assertTrue(ok2);
        assertEq(abi.decode(r, (address)), OWNER);
    }

    // ------------------------------------------------------------------
    // 3. Vaults: deposit gated by window / signature; admin gated by creator/owner
    // ------------------------------------------------------------------
    function test_vault_value_paths_revert_for_stranger() public {
        vm.startPrank(attacker);
        // deposit(address,uint256,uint256,bytes[]) on vault #0 -> window closed
        (bool ok, bytes memory ret) = VAULT0.call(abi.encodeWithSelector(0x781229fc, USDC, uint256(1), uint256(0), new bytes[](0)));
        assertFalse(ok); assertEq(_reason(ret), "Vault: deposit period has ended");
        // deposit on vault #1713 (V2) -> signature required
        (ok, ret) = VAULT_LAST.call(abi.encodeWithSelector(0x781229fc, USDC, uint256(1), uint256(0), new bytes[](0)));
        assertFalse(ok); assertEq(_reason(ret), "VaultV2: Signature required for deposit");
        // creator-gated
        (ok, ret) = VAULT0.call(abi.encodeWithSelector(0x8caad7b5, uint256(1)));
        assertFalse(ok); assertEq(_reason(ret), "Vault: not creator");
        (ok, ret) = VAULT0.call(abi.encodeWithSelector(0x65de4b2a, uint64(1)));
        assertFalse(ok); assertEq(_reason(ret), "Vault: not creator");
        // owner-gated / misc value paths
        assertFalse(_ok(VAULT0, abi.encodeWithSelector(0xeaa46ccf)));
        assertFalse(_ok(VAULT0, abi.encodeWithSelector(0x08031eba)));
        assertFalse(_ok(VAULT0, abi.encodeWithSelector(0xb392c530, uint256(1))));
        assertFalse(_ok(VAULT0, abi.encodeWithSelector(0x4f1ef286, attacker, bytes(""))));
        assertFalse(_ok(VAULT0, abi.encodeWithSelector(0xc4d66de8, attacker)));
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 4. PositionManager (factory): all admin/upgrade paths are onlyOwner
    // ------------------------------------------------------------------
    function test_position_manager_admin_reverts() public {
        vm.startPrank(attacker);
        assertFalse(_ok(PM, abi.encodeWithSelector(0x4f1ef286, attacker, bytes("")))); // upgradeToAndCall
        assertFalse(_ok(PM, abi.encodeWithSelector(0x32c3c1b6, USDC)));                // deployVault?
        assertFalse(_ok(PM, abi.encodeWithSelector(0x1c2a75b9, USDC, WETH, uint256(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0x9d509f38, USDC, WETH)));
        assertFalse(_ok(PM, abi.encodeWithSelector(0x7159c42e, USDC, WETH, WETH, uint256(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0x4ce92445, USDC, uint64(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0xd17e970d, USDC, WETH, uint64(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0xda4f0f30, USDC, uint64(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0xbb3696dc, USDC, uint256(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0x43470ad5, uint256(1))));
        assertFalse(_ok(PM, abi.encodeWithSelector(0x8d58b216, attacker)));            // setCollateralPoolV2
        assertFalse(_ok(PM, abi.encodeWithSelector(0xc8d60b42, attacker, uint8(1))));  // setVaultImplementation
        assertFalse(_ok(PM, abi.encodeWithSelector(0x7c08b964, attacker)));            // changeFeeReceiver
        assertFalse(_ok(PM, abi.encodeWithSelector(0xdfe15bac, USDC, uint256(1))));    // setMinDepositAmount
        assertFalse(_ok(PM, abi.encodeWithSelector(0x3242edfc, uint256(1))));          // changeDepositDeadlineOffset
        assertFalse(_ok(PM, abi.encodeWithSelector(0x5b769f3c, attacker)));            // setWETH
        assertFalse(_ok(PM, abi.encodeWithSelector(0x1ba28878, attacker)));            // setCollateralPool
        assertFalse(_ok(PM, abi.encodeWithSelector(0xe12799b1)));                      // initializeUpgrade
        assertFalse(_ok(PM, abi.encodeWithSelector(0xc4d66de8, attacker)));            // initialize
        assertFalse(_ok(PM, abi.encodeWithSelector(0x8456cb59)));                      // pause
        assertFalse(_ok(PM, abi.encodeWithSelector(0x3f4ba83a)));                      // unpause
        assertFalse(_ok(PM, abi.encodeWithSelector(0xf2fde38b, attacker)));            // transferOwnership
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 5. Upgradeability: UUPS, owner is a single EOA (privileged, not E-U)
    // ------------------------------------------------------------------
    function test_upgrade_control() public view {
        assertEq(abi.decode(_static(PM, abi.encodeWithSelector(0x8da5cb5b)), (address)), OWNER);
        // proxy uses the EIP-1967 implementation slot; no ERC-1967 admin slot is set
        assertEq(address(uint160(uint256(vm.load(PM, IMPL_SLOT)))), PM_IMPL);
        assertEq(uint256(vm.load(PM, ADMIN_SLOT)), 0);
        // owner is an EOA -> key compromise is a PRIVILEGED (P) risk, not external-unprivileged
        assertEq(OWNER.code.length, 0);
        assertGt(PM.code.length, 0); // minimal ERC-1967 proxy (~81 bytes)
    }

    // ------------------------------------------------------------------
    // 6. Net result: attacker gains nothing
    // ------------------------------------------------------------------
    function test_attacker_net_profit_is_zero() public {
        uint256 usdc0 = IERC20(USDC).balanceOf(POOL_V2);
        uint256 weth0 = IERC20(WETH).balanceOf(POOL_V2);
        uint256 cbbtc0 = IERC20(CBBTC).balanceOf(POOL_V2);

        vm.startPrank(attacker);
        POOL_V2.call(abi.encodeWithSelector(0xf3fef3a3, USDC, type(uint256).max));
        POOL_V2.call(abi.encodeWithSelector(0xf3fef3a3, WETH, type(uint256).max));
        POOL_V2.call(abi.encodeWithSelector(0xf3fef3a3, CBBTC, type(uint256).max));
        POOL_V2.call(abi.encodeWithSelector(0x1749aa26, USDC, uint256(1)));
        POOL_V2.call(abi.encodeWithSelector(0x1ea734b6, USDC, uint256(1)));
        POOL_V2.call(abi.encodeWithSelector(0xd5735e7d, VAULT0));
        POOL_V2.call(hex"715018a6");
        PM.call(hex"715018a6");
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(POOL_V2), usdc0);
        assertEq(IERC20(WETH).balanceOf(POOL_V2), weth0);
        assertEq(IERC20(CBBTC).balanceOf(POOL_V2), cbbtc0);
        assertEq(IERC20(USDC).balanceOf(attacker), 0);
        assertEq(IERC20(WETH).balanceOf(attacker), 0);
        assertEq(IERC20(CBBTC).balanceOf(attacker), 0);
    }

    // ------------------------------------------------------------------ helpers
    function _ok(address t, bytes memory data) internal returns (bool) {
        (bool ok, ) = t.call(data);
        return ok;
    }

    function _static(address t, bytes memory data) internal view returns (bytes memory) {
        (bool ok, bytes memory r) = t.staticcall(data);
        require(ok, "staticcall failed");
        return r;
    }

    function _reason(bytes memory ret) internal pure returns (string memory) {
        if (ret.length < 68) return "";
        bytes memory slice = new bytes(ret.length - 4);
        for (uint256 i = 4; i < ret.length; ++i) slice[i - 4] = ret[i];
        return abi.decode(slice, (string));
    }
}
