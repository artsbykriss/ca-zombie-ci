// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20,
    IERC4626,
    ITenbinRevenueModule,
    ITenbinCollateralManager,
    IGenericMorphoAdapter
} from "../src/Interfaces.sol";

/// @notice Fork tests for Tenbin Labs core contracts (Ethereum mainnet).
/// Read-only against a forked node; no mainnet transactions are sent.
contract TenbinTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // tBRL
    address constant TBRL_MANAGER = 0x67eB9338bAd71443aDC1f6C319D5400292a8b7e4;
    address constant TBRL_RM = 0x83cF329b9cbD2790aB2002E880592358C7c8Ff5F;
    address constant TBRL_ADAPTER = 0xb8097b0403bC4Bd0f1cfd6E778b84f425CA44fcE;
    // tGLD
    address constant TGLD_MANAGER = 0x42F3F01D45E67294e20cE98AcFDC24dD7EA75dEa;
    address constant TGLD_RM = 0x933745Dc6fcBcCDc491d9A8322672d731C8a262e;
    // tMXN
    address constant TMXN_MANAGER = 0x2a21014B89F72de3Ffa6d645F89b8Ca5A6eFfe75;
    address constant TMXN_RM = 0xD7D6C0c722b918045F1D725C5BB09F79Fc851033;
    address constant TMXN_KEEPER = 0xB6BA562eF547c94C2A863D5e4E0395695CfCF714;

    // Live GenericMorphoAdapter target used by all three parent vaults
    address constant STEAKHOUSE_PRIME_USDC = 0xbeef088055857739C12CD3765F20b7679Def0f51;

    address constant ATTACKER = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc);
    }

    /// @notice Finding 3.2's sink is REVENUE_KEEPER_ROLE-gated; an unprivileged caller cannot collect.
    function test_collect_is_keeper_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        ITenbinRevenueModule(TBRL_RM).collect(USDC, 1);
    }

    /// @notice CollateralManager.withdrawRevenue can only be called by its RevenueModule.
    function test_withdrawRevenue_is_module_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        ITenbinCollateralManager(TBRL_MANAGER).withdrawRevenue(USDC, 1);
    }

    /// @notice The 3.2 accounting bug is live (unrealized gain counted as revenue), but moving it
    /// requires the privileged keeper; the keeper is a protocol EOA, not an external attacker.
    function test_revenue_bug_live_but_keeper_only() public {
        ITenbinCollateralManager m = ITenbinCollateralManager(TMXN_MANAGER);
        uint256 rev = m.getRevenue(USDC);
        uint256 pending = m.pendingRevenue(USDC);
        uint256 liquid = IERC20(USDC).balanceOf(TMXN_MANAGER);
        uint256 vaultAssets = m.getVaultAssets(USDC);
        uint256 last = m.lastTotalAssets(USDC);
        console2.log("tMXN getRevenue (USDC 6dp)", rev);
        console2.log("tMXN pendingRevenue", pending);
        console2.log("tMXN vaultAssets", vaultAssets);
        console2.log("tMXN lastTotalAssets", last);
        console2.log("tMXN liquid USDC", liquid);
        if (vaultAssets > last) {
            assertEq(rev, pending + (vaultAssets - last), "unrealized gain counted as revenue (3.2 live)");
        }
        assertGt(rev, 0, "some revenue is reported");

        bytes32 keeperRole = keccak256("REVENUE_KEEPER_ROLE");
        assertTrue(ITenbinRevenueModule(TMXN_RM).hasRole(keeperRole, TMXN_KEEPER), "keeper role");

        uint256 amount = rev < liquid ? rev : liquid;
        if (amount == 0) {
            console2.log("no payable revenue at fork block");
            return;
        }
        uint256 rmBefore = IERC20(USDC).balanceOf(TMXN_RM);
        vm.prank(TMXN_KEEPER);
        ITenbinRevenueModule(TMXN_RM).collect(USDC, amount);
        assertEq(IERC20(USDC).balanceOf(TMXN_RM) - rmBefore, amount, "revenue moved to module");
        assertEq(IERC20(USDC).balanceOf(TMXN_MANAGER), liquid - amount, "paid from manager liquid principal");
        console2.log("privileged collect moved USDC", amount);
    }

    /// @notice Finding 3.3: the live allocation target is Steakhouse Prime USDC ($139M TVL).
    /// An inflation donation large enough to zero a $447k allocation is economically impossible.
    function test_inflation_attack_infeasible_on_live_target() public {
        IERC4626 vault = IERC4626(STEAKHOUSE_PRIME_USDC);
        uint256 ta = vault.totalAssets();
        uint256 ts = vault.totalSupply();
        uint256 allocation = 447_127_493_182; // tBRL parent vault totalAssets (USDC 6dp)
        console2.log("steakhouse totalAssets", ta);
        console2.log("steakhouse totalSupply", ts);

        // shares = allocation * ts / ta ; to mint < 1 wei share the vault would need
        // totalAssets > allocation * totalSupply (raw units).
        uint256 requiredAssets = allocation * ts; // raw USDC units, overflow-checked
        console2.log("totalAssets needed to mint <1 wei share", requiredAssets);
        assertGt(requiredAssets, 1e30, "required donation must be astronomically large");

        // A $1m donation only dilutes the next allocation by ~0.7%.
        uint256 sharesBefore = allocation * ts / ta;
        uint256 sharesAfter = allocation * ts / (ta + 1_000_000e6);
        uint256 dilutionBps = ((sharesBefore - sharesAfter) * 10_000) / sharesBefore;
        console2.log("dilution from $1m donation (bps)", dilutionBps);
        assertLt(dilutionBps, 100, "donation cannot materially dilute");

        // Execute the donation on the fork and confirm previewDeposit is barely affected.
        deal(USDC, ATTACKER, 1_000_000e6);
        vm.prank(ATTACKER);
        IERC20(USDC).transfer(STEAKHOUSE_PRIME_USDC, 1_000_000e6);
        uint256 previewAfter = vault.previewDeposit(allocation);
        console2.log("previewDeposit after donation", previewAfter);
        assertGt(previewAfter, sharesBefore * 99 / 100, "allocation still receives ~fair shares");
    }

    /// @notice The audited MorphoVaultV1Adapter is not in the live adapter path; the live adapter is
    /// GenericMorphoAdapter pointing at Steakhouse Prime USDC.
    function test_live_adapter_is_not_the_audited_vaultv1adapter() public {
        IGenericMorphoAdapter a = IGenericMorphoAdapter(TBRL_ADAPTER);
        assertEq(a.vault(), STEAKHOUSE_PRIME_USDC, "live target");
        assertGt(a.realAssets(), 0, "adapter is funded");

        (bool ok,) = TBRL_ADAPTER.staticcall(abi.encodeWithSignature("morphoVaultV1()"));
        assertFalse(ok, "audited MorphoVaultV1Adapter getter must be absent");
    }
}
