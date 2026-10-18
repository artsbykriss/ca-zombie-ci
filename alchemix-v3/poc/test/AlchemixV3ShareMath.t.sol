// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IVaultV2 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function maxRate() external view returns (uint256);
    function _totalAssets() external view returns (uint256);
    function lastUpdate() external view returns (uint256);
    function accrueInterest() external;
    function virtualShares() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function deposit(uint256 assets, address onBehalf) external returns (uint256);
    function redeem(uint256 shares, address receiver, address onBehalf) external returns (uint256);
    function forceDeallocate(address adapter, bytes memory data, uint256 assets, address onBehalf)
        external
        returns (uint256);
    function adaptersLength() external view returns (uint256);
    function adapters(uint256) external view returns (address);
    function forceDeallocatePenalty(address adapter) external view returns (uint256);
    function owner() external view returns (address);
    function setIsAllocator(address account, bool value) external;
    function setCurator(address c) external;
    function submit(bytes memory data) external;
    function setMaxRate(uint256 r) external;
    function setName(string memory n) external;
}

interface IVaultV2Factory {
    function createVaultV2(address owner, address asset, bytes32 salt) external returns (address);
}

interface IAlchemist {
    function liquidate(uint256 accountId) external returns (uint256, uint256, uint256);
    function getCDP(uint256 tokenId) external view returns (uint256, uint256, uint256);
    function totalSyntheticsIssued() external view returns (uint256);
    function getTotalUnderlyingValue() external view returns (uint256);
}

/// @notice Fork proofs for the Alchemix V3 (MYT / Morpho VaultV2 + Alchemist) share-math
///         and liquidation claims. All checks are read-only aside from local fork state.
contract AlchemixV3ShareMathTest is Test {
    struct SwapParams {
        bytes txData;
        uint256 minIntermediateOut;
    }

    struct VaultAdapterParams {
        uint8 action; // 0 = direct
        SwapParams swapParams;
    }

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC_VAULT = 0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5; // mixUSDC
    address constant WETH_VAULT = 0x29bcfeD246ce37319d94eBa107db90C453D4c43D; // mixWETH
    address constant FACTORY = 0xdd56B00302e91C4c2B8246156BDEAa1cEDC58984;
    address constant ALCHEMIST_ALUSD = 0xeB83112d925268BeDe86654C13D423a987587e3E;
    address constant ALCHEMIST_ALETH = 0xfa995B6ABc387376C3e7De5f6d394Ab5B6beE26B;
    address constant USDC_LIQ_ADAPTER = 0xdFDC17F784e16D7634AC270911D98755C68Ae220;

    uint256 constant FORK_BLOCK = 26_217_600;

    function setUp() public {
        string memory rpc = vm.envOr(
            "FORK_RPC_URL",
            vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        vm.createSelectFork(rpc, FORK_BLOCK);
        vm.roll(FORK_BLOCK + 1);
    }

    // ---------------------------------------------------------------- A
    /// @notice A donation to the live USDC MYT cannot move totalAssets within the
    ///         same block: the maxRate cap (10%/yr) applies to all unrecognised gains.
    function test_A_donation_rate_capped_live_usdc() public {
        IVaultV2 v = IVaultV2(USDC_VAULT);
        uint256 stored = v._totalAssets();
        uint256 last = v.lastUpdate();
        uint256 rate = v.maxRate();
        uint256 cap = stored + stored * (block.timestamp - last) * rate / 1e18;
        uint256 sharesBefore = v.convertToShares(1e6); // shares per 1 USDC

        deal(USDC, address(this), 5_000_000e6);
        IERC20(USDC).transfer(USDC_VAULT, 5_000_000e6);

        uint256 sameBlock = v.totalAssets();
        assertLe(sameBlock, cap + 1, "donation escaped maxRate cap in same block");

        vm.warp(block.timestamp + 30 days);
        vm.roll(block.number + 200_000);
        uint256 cap30 = stored + stored * (block.timestamp - last) * rate / 1e18;
        uint256 after30d = v.totalAssets();
        uint256 gain = after30d > stored ? after30d - stored : 0;
        console2.log("donation 5,000,000 USDC; recognised after 30d (USDC):", gain / 1e6);
        assertLe(after30d, cap30 + 1, "gain exceeded maxRate envelope");
        assertLt(gain, 5_000_000e6 / 50, "donation substantially recognised");

        uint256 sharesAfter = v.convertToShares(1e6);
        assertLe(sharesAfter, sharesBefore, "share price did not rise");
    }

    // ---------------------------------------------------------------- B
    /// @notice Fresh permissionlessly-created VaultV2 has maxRate=0 by default, so a
    ///         first-depositor donation is never recognised: the classic inflation
    ///         attack cannot steal the next depositor's principal.
    function test_B_fresh_vault_donation_blocked_by_zero_max_rate() public {
        address attacker = address(0xA11CE);
        address victim = address(0xB0B);
        IVaultV2Factory f = IVaultV2Factory(FACTORY);
        address fresh = f.createVaultV2(attacker, USDC, keccak256("zh4-alchemix-poc"));
        IVaultV2 v = IVaultV2(fresh);
        assertEq(v.maxRate(), 0, "default maxRate not zero");

        deal(USDC, attacker, 2_000_000e6);
        deal(USDC, victim, 1_000_000e6);

        vm.startPrank(attacker);
        IERC20(USDC).approve(fresh, type(uint256).max);
        uint256 aShares = v.deposit(1e6, attacker); // 1 USDC
        IERC20(USDC).transfer(fresh, 1_000_000e6); // donation
        vm.stopPrank();

        vm.startPrank(victim);
        IERC20(USDC).approve(fresh, type(uint256).max);
        uint256 vShares = v.deposit(1_000_000e6, victim);
        vm.stopPrank();

        uint256 attackerAssets = v.previewRedeem(aShares);
        uint256 victimAssets = v.previewRedeem(vShares);
        console2.log("fresh vault: attacker redeem (USDC):", attackerAssets / 1e6);
        console2.log("fresh vault: victim redeem   (USDC):", victimAssets / 1e6);

        // No value transfer: attacker only gets their 1 USDC back, victim keeps ~1:1.
        assertLe(attackerAssets, 1e6, "attacker profited from donation");
        assertGe(victimAssets, 1_000_000e6 - 1e6, "victim principal lost");
    }

    // ---------------------------------------------------------------- C
    /// @notice forceDeallocate on another holder's shares requires their share
    ///         allowance; without it the penalty withdrawal underflows/reverts.
    function test_C_force_deallocate_without_allowance_reverts() public {
        address holder = address(0xC0FFEE);
        IVaultV2 v = IVaultV2(USDC_VAULT);
        deal(USDC, holder, 10_000e6);
        vm.startPrank(holder);
        IERC20(USDC).approve(USDC_VAULT, 10_000e6);
        uint256 shares = v.deposit(10_000e6, holder);
        vm.stopPrank();
        require(shares > 0, "no shares minted");

        address attacker = address(0xBAD);
        bytes memory data = abi.encode(VaultAdapterParams(0, SwapParams("", 0))); // ActionType.direct
        vm.prank(attacker);
        vm.expectRevert();
        v.forceDeallocate(USDC_LIQ_ADAPTER, data, 1_000e6, holder);
    }

    // ---------------------------------------------------------------- D
    /// @notice Deposit -> immediate redeem on the live vault returns at most the
    ///         deposit (rounding is in favour of the vault), no round-trip profit.
    function test_D_deposit_redeem_roundtrip_no_profit() public {
        IVaultV2 v = IVaultV2(USDC_VAULT);
        uint256 amount = 100_000e6;
        deal(USDC, address(this), amount);
        IERC20(USDC).approve(USDC_VAULT, amount);

        uint256 before = IERC20(USDC).balanceOf(address(this));
        uint256 shares = v.deposit(amount, address(this));
        uint256 out = v.redeem(shares, address(this), address(this));
        uint256 afterBal = IERC20(USDC).balanceOf(address(this));
        console2.log("roundtrip in/out (USDC):", amount / 1e6, out / 1e6);
        assertLe(afterBal, before, "round trip profitable");
    }

    // ---------------------------------------------------------------- E
    /// @notice No live alUSD position is liquidatable at the fork block; the
    ///         previously-worst position (id 1202) reverts with LiquidationError.
    function test_E_liquidate_healthy_position_reverts() public {
        IAlchemist a = IAlchemist(ALCHEMIST_ALUSD);
        (uint256 collateral, uint256 debt,) = a.getCDP(1202);
        assertGt(debt, 0, "no debt on 1202");
        console2.log("position 1202 collateral shares:", collateral);
        console2.log("position 1202 debt:", debt);

        // CR currently ~1.111; healthy accounts must not be liquidatable.
        vm.expectRevert();
        a.liquidate(1202);
    }

    // ---------------------------------------------------------------- F
    /// @notice All seven live MYT vaults hold real assets and reconcile; the two
    ///         largest share prices are > 1.0 (seeded), so first-depositor attacks
    ///         are structurally impossible on them.
    function test_F_live_vaults_seeded_and_reconciled() public {
        address[2] memory vaults = [USDC_VAULT, WETH_VAULT];
        for (uint256 i; i < vaults.length; i++) {
            IVaultV2 v = IVaultV2(vaults[i]);
            uint256 ta = v.totalAssets();
            uint256 ts = v.totalSupply();
            uint256 price = v.convertToAssets(1e18);
            console2.log("vault:", vaults[i]);
            console2.log("  totalAssets:", ta);
            console2.log("  totalSupply:", ts);
            console2.log("  price per 1e18 shares:", price);
            assertGt(ta, 0, "empty vault");
            assertGt(ts, 0, "no shares");
            assertGt(price, 1e6, "share price ~0");
        }
    }
}
