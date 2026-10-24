// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IVaultV2, IVaultV2Factory, IVaultErrors} from "../src/IAgentBankVault.sol";

/// @title AgentBank Deposit Vault (abWLD) — live-surface PoC on a World Chain fork.
/// @notice Read-only research. Every test runs on a local fork; no transaction is ever sent to mainnet.
///
/// Target : 0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1  ("AgentBank Deposit Vault", abWLD)
/// Chain  : World Chain (480)
/// Asset  : WLD 0x2cFc85d8E48F8EAB294be644d9E25C3030863003
/// Type   : genuine Morpho `VaultV2` (src/VaultV2.sol, 2025 Morpho Association, GPL-2.0-or-later),
///          deployed via Morpho's official `VaultV2Factory` 0x6846EA318B6B987Ee6b28eBFd87c3409F1d13108.
contract AgentBankVaultV2Test is Test {
    IVaultV2 internal constant VAULT = IVaultV2(0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1);
    IVaultV2Factory internal constant FACTORY = IVaultV2Factory(0x6846EA318B6B987Ee6b28eBFd87c3409F1d13108);
    address internal constant WLD = 0x2cFc85d8E48F8EAB294be644d9E25C3030863003;
    address internal constant SAFE = 0x148677e5fDd232adA601CF9e1b8194431D3E31b5; // owner == curator (Safe 1.5.0, 2-of-2)
    address internal constant DEPLOYER_EOA = 0x52811Ba027aa086c0c40Fbeb84670713787d9538; // constructor _owner
    address internal constant BIG_HOLDER = 0x0D1c78fC0215001a6619EaFD0Ae20Bf132cFa013; // top abWLD holder

    // Abdicated selectors (verified live via `abdicated(bytes4)`):
    bytes4 internal constant SEL_SET_RECEIVE_SHARES_GATE = 0x2cb19f98;
    bytes4 internal constant SEL_SET_SEND_SHARES_GATE = 0xc21ad028;
    bytes4 internal constant SEL_SET_RECEIVE_ASSETS_GATE = 0x04dbf0ce;
    bytes4 internal constant SEL_ADD_ADAPTER = 0x60d54d41;
    bytes4 internal constant SEL_SET_IS_ALLOCATOR = 0xb192a84a;
    bytes4 internal constant SEL_SET_PERFORMANCE_FEE = 0x70897b23;
    bytes4 internal constant SEL_SET_MANAGEMENT_FEE = 0xfe56e232;
    bytes4 internal constant SEL_SET_ADAPTER_REGISTRY = 0x5b34b823;
    bytes4 internal constant SEL_SET_SEND_ASSETS_GATE = 0x871c979c; // NOT abdicated, timelock 3600

    uint256 internal constant FORK_BLOCK = 36_771_979;

    function setUp() public {
        string memory rpc = vm.envOr("WORLDCHAIN_RPC_URL", string("https://worldchain-mainnet.g.alchemy.com/public"));
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    /* ------------------------------------------------------------------ */
    /* 1. Identity: it really is a genuine Morpho VaultV2, hardened       */
    /* ------------------------------------------------------------------ */

    function test_01_identity_isGenuineHardenedMorphoVaultV2() public view {
        assertEq(VAULT.asset(), WLD, "asset != WLD");
        assertEq(VAULT.decimals(), 18);
        assertEq(VAULT.symbol(), "abWLD");
        assertEq(VAULT.name(), "AgentBank Deposit Vault");

        // deployed by Morpho's official factory
        assertTrue(FACTORY.isVaultV2(address(VAULT)), "not a factory-deployed VaultV2");

        // owner == curator == the AgentBank Safe
        assertEq(VAULT.owner(), SAFE);
        assertEq(VAULT.curator(), SAFE);

        // no gates, no adapters, no fees, no interest, no allocator
        assertEq(VAULT.receiveSharesGate(), address(0));
        assertEq(VAULT.sendSharesGate(), address(0));
        assertEq(VAULT.receiveAssetsGate(), address(0));
        assertEq(VAULT.sendAssetsGate(), address(0));
        assertEq(VAULT.adaptersLength(), 0, "adapters != 0");
        assertEq(VAULT.liquidityAdapter(), address(0));
        assertEq(VAULT.maxRate(), 0);
        assertEq(VAULT.performanceFee(), 0);
        assertEq(VAULT.managementFee(), 0);
        assertEq(VAULT.performanceFeeRecipient(), address(0));
        assertEq(VAULT.managementFeeRecipient(), address(0));
        assertFalse(VAULT.isAllocator(SAFE), "Safe is allocator");
        assertFalse(VAULT.isAllocator(DEPLOYER_EOA));

        // the withdrawal-blocking gates + adapter/allocator/fee mutators are permanently abdicated
        assertTrue(VAULT.abdicated(SEL_SET_RECEIVE_SHARES_GATE), "receiveSharesGate not abdicated");
        assertTrue(VAULT.abdicated(SEL_SET_SEND_SHARES_GATE), "sendSharesGate not abdicated");
        assertTrue(VAULT.abdicated(SEL_SET_RECEIVE_ASSETS_GATE), "receiveAssetsGate not abdicated");
        assertTrue(VAULT.abdicated(SEL_ADD_ADAPTER), "addAdapter not abdicated");
        assertTrue(VAULT.abdicated(SEL_SET_IS_ALLOCATOR), "setIsAllocator not abdicated");
        assertTrue(VAULT.abdicated(SEL_SET_PERFORMANCE_FEE));
        assertTrue(VAULT.abdicated(SEL_SET_MANAGEMENT_FEE));
        assertTrue(VAULT.abdicated(SEL_SET_ADAPTER_REGISTRY));

        // every share is fully backed by idle WLD (no adapters => no illiquidity)
        assertGe(IERC20(WLD).balanceOf(address(VAULT)), VAULT.totalAssets(), "not 100% idle-backed");
    }

    /* ------------------------------------------------------------------ */
    /* 2. Fresh unprivileged EOA: deposit -> redeem, no profit            */
    /* ------------------------------------------------------------------ */

    function test_02_freshEOA_depositRedeem_noProfit() public {
        address atk = address(0xA11CE);
        deal(WLD, atk, 10_000e18);
        uint256 bal0 = IERC20(WLD).balanceOf(atk);

        vm.startPrank(atk);
        IERC20(WLD).approve(address(VAULT), type(uint256).max);
        uint256 shares = VAULT.deposit(10_000e18, atk);
        uint256 redeemed = VAULT.redeem(shares, atk, atk);
        vm.stopPrank();

        uint256 bal1 = IERC20(WLD).balanceOf(atk);
        console2.log("deposited", uint256(10_000e18));
        console2.log("shares   ", shares);
        console2.log("redeemed ", redeemed);
        console2.log("net delta", int256(bal1) - int256(bal0));

        assertGt(shares, 0);
        // correctly priced (~1.0) and never profitable: redeeming returns <= deposited
        assertApproxEqRel(shares, 10_000e18, 0.001e18, "shares mispriced");
        assertLe(bal1, bal0, "fresh EOA profited from round-trip");
    }

    /* ------------------------------------------------------------------ */
    /* 3. Donation / first-depositor inflation attack is dead              */
    /* ------------------------------------------------------------------ */

    function test_03_donationInflationAttack_fails() public {
        // Attacker deposits 1 wei of shares and then donates 1,000,000 WLD straight to the vault.
        address atk = address(0xBAD);
        deal(WLD, atk, 1_000_000e18 + 1);
        vm.startPrank(atk);
        IERC20(WLD).approve(address(VAULT), type(uint256).max);
        VAULT.deposit(1, atk); // 1 wei of shares
        uint256 ta0 = VAULT.totalAssets();
        IERC20(WLD).transfer(address(VAULT), 1_000_000e18); // raw donation
        uint256 ta1 = VAULT.totalAssets();
        vm.stopPrank();

        // maxRate == 0 => a donation is NOT recognised: totalAssets() is unchanged.
        console2.log("totalAssets before donation", ta0);
        console2.log("totalAssets after  donation", ta1);
        assertEq(ta1, ta0, "donation moved totalAssets");

        // Victim deposits at the unchanged price and is not diluted.
        address victim = address(0x1C71);
        deal(WLD, victim, 100_000e18);
        vm.startPrank(victim);
        IERC20(WLD).approve(address(VAULT), type(uint256).max);
        uint256 vshares = VAULT.deposit(100_000e18, victim);
        vm.stopPrank();

        uint256 victimBack = VAULT.previewRedeem(vshares);
        console2.log("victim shares    ", vshares);
        console2.log("victim redeemable", victimBack);
        assertApproxEqRel(victimBack, 100_000e18, 0.001e18, "victim was diluted");

        // Attacker redeems: cannot recover the donation.
        uint256 atkShares = VAULT.balanceOf(atk);
        uint256 atkBack = VAULT.previewRedeem(atkShares);
        console2.log("attacker shares   ", atkShares);
        console2.log("attacker redeemable", atkBack);
        assertLt(atkBack, 1_000_000e18, "attacker recovered donation");
    }

    /* ------------------------------------------------------------------ */
    /* 4. Liquidity: large real holder can withdraw in full (H-O)          */
    /* ------------------------------------------------------------------ */

    function test_04_largeHolder_canExit() public {
        uint256 hb = VAULT.balanceOf(BIG_HOLDER);
        assertGt(hb, 0, "top holder has no shares");

        uint256 wldBefore = IERC20(WLD).balanceOf(BIG_HOLDER);
        vm.prank(BIG_HOLDER);
        uint256 assets = VAULT.redeem(hb, BIG_HOLDER, BIG_HOLDER);
        uint256 wldAfter = IERC20(WLD).balanceOf(BIG_HOLDER);

        console2.log("shares redeemed", hb);
        console2.log("assets received", assets);
        assertEq(wldAfter - wldBefore, assets, "did not receive assets");
        assertApproxEqRel(assets, hb, 0.001e18, "wrong exit price");
    }

    /* ------------------------------------------------------------------ */
    /* 5. Privileged paths: owner/curator cannot enable a rug or extract   */
    /* ------------------------------------------------------------------ */

    function test_05_privileged_paths_blocked() public {
        // Direct (un-submitted) call to a withdrawal-blocking gate setter: the timelock guard fires first.
        vm.prank(SAFE);
        vm.expectRevert(IVaultErrors.DataNotTimelocked.selector);
        VAULT.setReceiveSharesGate(address(0xdead));

        // The curator (SAFE) submits each change and then executes it -> permanently Abdicated.
        vm.startPrank(SAFE);

        VAULT.submit(abi.encodeWithSelector(IVaultV2.setReceiveSharesGate.selector, address(0xdead)));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.setReceiveSharesGate(address(0xdead));

        VAULT.submit(abi.encodeWithSelector(IVaultV2.setSendSharesGate.selector, address(0xdead)));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.setSendSharesGate(address(0xdead));

        VAULT.submit(abi.encodeWithSelector(IVaultV2.setReceiveAssetsGate.selector, address(0xdead)));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.setReceiveAssetsGate(address(0xdead));

        VAULT.submit(abi.encodeWithSelector(IVaultV2.addAdapter.selector, address(0xdead)));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.addAdapter(address(0xdead));

        VAULT.submit(abi.encodeWithSelector(IVaultV2.setIsAllocator.selector, address(0xdead), true));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.setIsAllocator(address(0xdead), true);

        VAULT.submit(abi.encodeWithSelector(IVaultV2.setPerformanceFee.selector, uint256(1e18)));
        vm.expectRevert(IVaultErrors.Abdicated.selector);
        VAULT.setPerformanceFee(1e18);

        // No allocator exists and none can ever be created -> allocator-only functions are unreachable.
        vm.expectRevert(IVaultErrors.Unauthorized.selector);
        VAULT.setMaxRate(1);

        vm.expectRevert(IVaultErrors.Unauthorized.selector);
        VAULT.setLiquidityAdapterAndData(address(0xdead), "");

        // The single non-abdicated gate setter (deposit gate, harmless) is timelocked 3600s.
        VAULT.submit(abi.encodeWithSelector(IVaultV2.setSendAssetsGate.selector, address(0xdead)));
        vm.expectRevert();
        VAULT.setSendAssetsGate(address(0xdead));

        vm.stopPrank();

        // State unchanged: no gate, no adapter, no allocator.
        assertEq(VAULT.receiveSharesGate(), address(0));
        assertEq(VAULT.sendSharesGate(), address(0));
        assertEq(VAULT.receiveAssetsGate(), address(0));
        assertEq(VAULT.sendAssetsGate(), address(0));
        assertEq(VAULT.adaptersLength(), 0);
        assertFalse(VAULT.isAllocator(SAFE));
        assertFalse(VAULT.isAllocator(address(0xdead)));
    }

    /* ------------------------------------------------------------------ */
    /* 6. Unaccounted donation surplus is permanently stuck (S)            */
    /* ------------------------------------------------------------------ */

    function test_06_surplusIsStuck() public {
        uint256 real = IERC20(WLD).balanceOf(address(VAULT));
        uint256 accounted = VAULT.totalAssets();
        uint256 surplus = real - accounted;

        // Redeeming 100% of the supply cannot pay out the surplus (totalAssets is capped at maxRate=0).
        uint256 maxPayout = VAULT.previewRedeem(VAULT.totalSupply());
        console2.log("real WLD held     ", real);
        console2.log("accounted (total) ", accounted);
        console2.log("stuck surplus wei ", surplus);
        console2.log("max payout 100%   ", maxPayout);

        assertLe(maxPayout, accounted, "surplus is redeemable");
        assertLt(surplus, 1e18, "surplus unexpectedly large");
    }

    /* ------------------------------------------------------------------ */
    /* 9. forceDeallocate cannot be abused (no adapters exist)             */
    /* ------------------------------------------------------------------ */

    function test_09_forceDeallocate_unusable() public {
        // deallocateInternal requires isAdapter[adapter]; addAdapter is abdicated, so no adapter can exist.
        vm.prank(address(0xBAD2));
        vm.expectRevert(IVaultErrors.NotAdapter.selector);
        VAULT.forceDeallocate(address(0xdead), "", 0, BIG_HOLDER);
    }

    /* ------------------------------------------------------------------ */
    /* 8. Emit machine-readable live-state evidence for the CI artifact    */
    /* ------------------------------------------------------------------ */

    function test_08_emitEvidence() public {
        string memory o = "evidence";
        vm.serializeUint(o, "block", block.number);
        vm.serializeAddress(o, "vault", address(VAULT));
        vm.serializeAddress(o, "asset", VAULT.asset());
        vm.serializeAddress(o, "factory", address(FACTORY));
        vm.serializeAddress(o, "owner", VAULT.owner());
        vm.serializeAddress(o, "curator", VAULT.curator());
        vm.serializeUint(o, "totalSupply", VAULT.totalSupply());
        vm.serializeUint(o, "totalAssets", VAULT.totalAssets());
        vm.serializeUint(o, "vaultWldBalance", IERC20(WLD).balanceOf(address(VAULT)));
        vm.serializeUint(o, "adaptersLength", VAULT.adaptersLength());
        vm.serializeAddress(o, "liquidityAdapter", VAULT.liquidityAdapter());
        vm.serializeUint(o, "maxRate", VAULT.maxRate());
        vm.serializeUint(o, "performanceFee", VAULT.performanceFee());
        vm.serializeUint(o, "managementFee", VAULT.managementFee());
        vm.serializeBool(o, "isFactoryVaultV2", FACTORY.isVaultV2(address(VAULT)));
        vm.serializeBool(o, "abdicated_setReceiveSharesGate", VAULT.abdicated(SEL_SET_RECEIVE_SHARES_GATE));
        vm.serializeBool(o, "abdicated_setSendSharesGate", VAULT.abdicated(SEL_SET_SEND_SHARES_GATE));
        vm.serializeBool(o, "abdicated_setReceiveAssetsGate", VAULT.abdicated(SEL_SET_RECEIVE_ASSETS_GATE));
        vm.serializeBool(o, "abdicated_addAdapter", VAULT.abdicated(SEL_ADD_ADAPTER));
        vm.serializeBool(o, "abdicated_setIsAllocator", VAULT.abdicated(SEL_SET_IS_ALLOCATOR));
        vm.serializeBool(o, "hasAllocatorSafe", VAULT.isAllocator(SAFE));
        vm.serializeUint(o, "bigHolderShares", VAULT.balanceOf(BIG_HOLDER));
        string memory json = vm.serializeUint(o, "redeemPricePerShare1e18", VAULT.convertToAssets(1e18));
        vm.writeJson(json, "../ci-out/evidence.json");
        assertGt(VAULT.totalAssets(), 0);
    }

    /* ------------------------------------------------------------------ */
    /* 7. No free shares: mint/deposit always pulls the exact asset amount */
    /* ------------------------------------------------------------------ */

    function test_07_noFreeShares() public {
        address atk = address(0xF00);
        deal(WLD, atk, 10_000e18);
        vm.startPrank(atk);
        IERC20(WLD).approve(address(VAULT), type(uint256).max);

        uint256 cost = VAULT.previewMint(1_000e18);
        uint256 balBefore = IERC20(WLD).balanceOf(atk);
        uint256 minted = VAULT.mint(1_000e18, atk);
        uint256 balAfter = IERC20(WLD).balanceOf(atk);

        console2.log("cost for 1000 shares", cost);
        assertEq(minted, 1_000e18);
        assertEq(balBefore - balAfter, cost, "mint did not pull the quoted amount");
        assertGe(cost, 1_000e18 - 1e6, "minted cheaper than fair");
        vm.stopPrank();
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
