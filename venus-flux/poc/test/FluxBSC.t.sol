// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IFluidOracle {
    function getExchangeRate() external view returns (uint256);
    function getExchangeRateOperate() external view returns (uint256);
    function getExchangeRateLiquidate() external view returns (uint256);
}

interface IFluidVaultT1 {
    function operate(uint256, int256, int256, address) external payable returns (uint256, int256, int256);
}

interface IFluidDexT1 {
    function swapIn(bool, uint256, uint256, address) external payable returns (uint256);
    function getPricesAndExchangePrices() external;
}

interface IDexResolver {
    struct Configs {
        bool isSmartCollateralEnabled;
        bool isSmartDebtEnabled;
        uint256 fee;
        uint256 revenueCut;
        uint256 upperRange;
        uint256 lowerRange;
        uint256 upperShiftThreshold;
        uint256 lowerShiftThreshold;
        uint256 shiftingTime;
        address centerPriceAddress;
        address hookAddress;
        uint256 maxCenterPrice;
        uint256 minCenterPrice;
        uint256 utilizationLimitToken0;
        uint256 utilizationLimitToken1;
        uint256 maxSupplyShares;
        uint256 maxBorrowShares;
    }
    function getDexConfigs(address) external view returns (Configs memory);
    function getDexVariables2Raw(address) external view returns (uint256);
    function getTotalSupplySharesRaw(address) external view returns (uint256);
    function getTotalBorrowSharesRaw(address) external view returns (uint256);
}

interface ILiquidityResolver {
    function getUserBorrowData(address user, address token) external view returns (
        bool modeWithInterest, uint256 borrow, uint256 borrowLimit, uint256 lastUpdateTimestamp,
        uint256 expandPercent, uint256 expandDuration, uint256 baseBorrowLimit,
        uint256 maxBorrowLimit, uint256 borrowableUntilLimit, uint256 borrowable, uint256 borrowLimitUtilization);
}

/// @notice Read-only + fork tests for the Venus Flux (Instadapp Fluid) deployment on BSC.
/// Verifies the wstUSR oracle is a USR-redemption-rate oracle that ignores the (permanent)
/// USR market depeg, and checks whether the resulting mis-pricing is still extractable by an
/// unprivileged attacker. No transaction is ever signed or broadcast to mainnet.
contract FluxBSCTest is Test {
    address constant WSTUSR = 0x4254813524695def4163A169e901f3d7a1a55429;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    // Fluid (Venus Flux) oracles
    address constant ORA_WSTUSR_USDT = 0xc0767760627E88Eef7f653bce49e660a351E95eD;
    address constant CAPPED_WSTUSR = 0x4c38911E3797Ba0ebD9a1D40673CA1A993445EDF;

    // Vaults collateralised by wstUSR (T1) + T2/T3/T4 smart vaults
    address constant VAULT_WSTUSR_USDT = 0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd; // T1
    address constant VAULT_WSTUSR_USDC = 0xeAEf563015634a9d0EE6CF1357A3b205C35e028D; // T1
    address constant VAULT_WSTUSR_USDT_T2 = 0xF74cb9D69ada3559903149CFD60fD57cEAF95F30;

    address constant DEX_WSTUSR_USDT = 0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7;
    address constant DEX_RESOLVER = 0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0;
    address constant LIQ_RESOLVER = 0xca13A15de31235A37134B4717021C35A3CF25C60;

    address attacker = address(0xA11CE);

    function setUp() public {
        // In CI the BSC_RPC_URL secret may be present but empty; fall back to keyless public RPCs.
        string memory env = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(env).length > 0) {
            vm.createSelectFork(env);
            return;
        }
        string[3] memory urls = [
            "https://bsc-rpc.publicnode.com",
            "https://bsc-dataseed.binance.org",
            "https://1rpc.io/bnb"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try this._forkTo(urls[i]) {
                return;
            } catch {}
        }
        revert("no working BSC rpc");
    }

    function _forkTo(string memory url_) external {
        vm.createSelectFork(url_);
    }

    /// 1) The wstUSR oracle is a redemption-rate oracle (USR per wstUSR) — it never reflects the
    ///    USR market price. At the current live value it is ~14x above wstUSR's market value.
    function test_wstUSR_oracle_is_redemption_rate_not_market() public {
        uint256 rate = IFluidOracle(ORA_WSTUSR_USDT).getExchangeRate();
        uint256 rateLiq = IFluidOracle(ORA_WSTUSR_USDT).getExchangeRateLiquidate();
        uint256 capped = IFluidOracle(CAPPED_WSTUSR).getExchangeRate();
        emit log_named_uint("wstUSR/USDT oracle getExchangeRate  (1e27)", rate);
        emit log_named_uint("wstUSR/USDT oracle liquidate rate   (1e27)", rateLiq);
        emit log_named_uint("CappedRateChainlink_WSTUSR          (1e27)", capped);
        assertGt(rate, 1.10e27, "oracle ~1.13 USDT per wstUSR");
        assertLt(rate, 1.20e27, "oracle ~1.13 USDT per wstUSR");
        // Market wstUSR (DefiLlama/CoinGecko 2026-10-23) ~ $0.081. Oracle is ~14x too high.
        uint256 market = 0.0813e18;
        assertGt(rate / 1e9, market * 13, "oracle must be >13x the market price");
    }

    /// 2) An unprivileged attacker cannot open a wstUSR/USDT T1 position and borrow: the Liquidity
    ///    layer borrow limit for this vault is 1 wei, so `operate` reverts.
    function test_borrow_against_wstUSR_T1_USDT_reverts() public {
        deal(WSTUSR, attacker, 1_000e18);
        vm.startPrank(attacker);
        IERC20(WSTUSR).approve(VAULT_WSTUSR_USDT, type(uint256).max);
        (bool ok, bytes memory ret) = VAULT_WSTUSR_USDT.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(0), int256(1000e18), int256(1000e18), attacker)
        );
        emit log_named_string("T1 wstUSR/USDT operate success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "borrow must be blocked");
        vm.stopPrank();
    }

    /// 2b) Supplying wstUSR is ALSO blocked: the Liquidity layer has the wstUSR token paused for
    ///     this vault (user-supply config bit 255 = 1) -> UserModule__UserPaused.
    function test_deposit_wstUSR_only_reverts_paused() public {
        deal(WSTUSR, attacker, 1_000e18);
        vm.startPrank(attacker);
        IERC20(WSTUSR).approve(VAULT_WSTUSR_USDT, type(uint256).max);
        (bool ok, bytes memory ret) = VAULT_WSTUSR_USDT.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(0), int256(1000e18), int256(0), attacker)
        );
        emit log_named_string("T1 wstUSR/USDT deposit-only success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "supply must be paused");
        vm.stopPrank();
    }

    /// 2c) Existing wstUSR positions are frozen: even the position owner cannot withdraw collateral
    ///     (the supply pause blocks withdraw too). NFT 38 = 0.7 wstUSR / 0.449 USDT.
    function test_existing_wstUSR_position_withdraw_frozen() public {
        address owner = 0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;
        vm.prank(owner);
        (bool ok, bytes memory ret) = VAULT_WSTUSR_USDT.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(38), int256(-0.05e18), int256(0), owner)
        );
        emit log_named_string("withdraw 0.05 wstUSR (small) success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        vm.prank(owner);
        (bool ok2, bytes memory ret2) = VAULT_WSTUSR_USDT.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(38), int256(-0.5e18), int256(0), owner)
        );
        emit log_named_string("withdraw 0.5 wstUSR success", ok2 ? "YES" : "NO");
        emit log_named_bytes("revert data2", ret2);
    }

    function test_borrow_against_wstUSR_T1_USDC_reverts() public {
        deal(WSTUSR, attacker, 1_000e18);
        vm.startPrank(attacker);
        IERC20(WSTUSR).approve(VAULT_WSTUSR_USDC, type(uint256).max);
        (bool ok, bytes memory ret) = VAULT_WSTUSR_USDC.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(0), int256(1000e18), int256(1000e18), attacker)
        );
        emit log_named_string("T1 wstUSR/USDC operate success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "borrow must be blocked");
        vm.stopPrank();
    }

    /// 3) The T2 (DEX-LP collateral) wstUSR vault is equally blocked.
    function test_borrow_against_wstUSR_T2_reverts() public {
        deal(WSTUSR, attacker, 1_000e18);
        vm.startPrank(attacker);
        IERC20(WSTUSR).approve(VAULT_WSTUSR_USDT_T2, type(uint256).max);
        (bool ok, bytes memory ret) = VAULT_WSTUSR_USDT_T2.call(
            abi.encodeWithSelector(IFluidVaultT1.operate.selector, uint256(0), int256(1000e18), int256(1000e18), attacker)
        );
        emit log_named_string("T2 wstUSR/USDT operate success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "borrow must be blocked");
        vm.stopPrank();
    }

    /// 4) The Fluid DEX wstUSR/USDT pool uses the same broken centre price but swapping is paused
    ///    (governance `SwapAndArbitragePaused`, error 51043).
    function test_dex_swap_wstUSR_to_USDT_reverts_paused() public {
        deal(WSTUSR, attacker, 1_000_000e18);
        uint256 before = IERC20(USDT).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(WSTUSR).approve(DEX_WSTUSR_USDT, type(uint256).max);
        (bool ok, bytes memory ret) = DEX_WSTUSR_USDT.call(
            abi.encodeWithSelector(IFluidDexT1.swapIn.selector, true, uint256(1_000_000e18), uint256(0), attacker)
        );
        vm.stopPrank();
        uint256 got = IERC20(USDT).balanceOf(attacker) - before;
        emit log_named_string("swapIn success", ok ? "YES" : "NO");
        emit log_named_bytes("revert data", ret);
        emit log_named_uint("USDT extracted", got);
        assertFalse(ok, "swap must be paused");
        assertEq(got, 0, "no USDT extracted");
    }

    /// 5) DEX-level lock: the wstUSR/USDT pool has maxSupplyShares == 0, maxBorrowShares == 0 and
    ///    the swap-paused bit (255) set, unlike all other pools.
    function test_dex_wstUSR_pool_is_locked() public {
        IDexResolver.Configs memory c = IDexResolver(DEX_RESOLVER).getDexConfigs(DEX_WSTUSR_USDT);
        uint256 vars2 = IDexResolver(DEX_RESOLVER).getDexVariables2Raw(DEX_WSTUSR_USDT);
        uint256 ss = IDexResolver(DEX_RESOLVER).getTotalSupplySharesRaw(DEX_WSTUSR_USDT);
        uint256 bs = IDexResolver(DEX_RESOLVER).getTotalBorrowSharesRaw(DEX_WSTUSR_USDT);
        emit log_named_uint("maxSupplyShares", c.maxSupplyShares);
        emit log_named_uint("maxBorrowShares", c.maxBorrowShares);
        emit log_named_uint("totalSupplyShares", ss);
        emit log_named_uint("totalBorrowShares", bs);
        emit log_named_uint("swapPausedBit255", (vars2 >> 255) & 1);
        assertEq(c.maxSupplyShares, 0, "supply disabled");
        assertEq(c.maxBorrowShares, 0, "borrow disabled");
        assertEq((vars2 >> 255) & 1, 1, "swap paused");
    }

    /// 6) Vault-level lock: Liquidity-layer borrow limits for the wstUSR vaults are 1 wei.
    function test_liquidity_borrow_limits_are_one_wei() public {
        ILiquidityResolver r = ILiquidityResolver(LIQ_RESOLVER);
        (,,,,,,, uint256 maxBL, , uint256 borrowable,) = r.getUserBorrowData(VAULT_WSTUSR_USDT, USDT);
        (,,,,,,, uint256 maxBL2, , uint256 borrowable2,) = r.getUserBorrowData(VAULT_WSTUSR_USDC, USDC);
        emit log_named_uint("wstUSR/USDT vault maxBorrowLimit", maxBL);
        emit log_named_uint("wstUSR/USDT vault borrowable", borrowable);
        emit log_named_uint("wstUSR/USDC vault maxBorrowLimit", maxBL2);
        emit log_named_uint("wstUSR/USDC vault borrowable", borrowable2);
        assertEq(maxBL, 1, "borrow limit disabled (1 wei)");
        assertEq(borrowable, 0, "nothing borrowable");
        assertEq(maxBL2, 1, "borrow limit disabled (1 wei)");
        assertEq(borrowable2, 0, "nothing borrowable");
    }

    /// 7) Latent magnitude: IF the borrow limit were re-opened, each 1 wstUSR of collateral would
    ///    let the attacker borrow 1.1327 * 0.90 = 1.019 USDT while costing only ~$0.081 on the
    ///    market -> ~$0.94 profit per wstUSR, at the protocol's expense (bad debt).
    function test_latent_profit_per_wstUSR_if_rearmed() public {
        uint256 rate = IFluidOracle(ORA_WSTUSR_USDT).getExchangeRate(); // 1e27
        uint256 cf = 9000; // 90%
        uint256 borrowPerWstUSR = (rate / 1e9) * cf / 10000; // in 1e18 USDT units
        uint256 market = 0.0813e18;
        emit log_named_uint("oracle USDT per wstUSR (1e18)", rate / 1e9);
        emit log_named_uint("borrowable USDT per wstUSR @CF (1e18)", borrowPerWstUSR);
        emit log_named_uint("market cost per wstUSR (1e18)", market);
        assertGt(borrowPerWstUSR, market, "latent profit positive if re-armed");
    }
}
