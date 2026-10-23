// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IPredyPool {
    error CallerIsNotOperator();
    error CallerIsNotPoolCreator();
    error LockedBy(address locker);

    struct IRMParams {
        uint256 baseRate;
        uint256 kinkRate;
        uint256 slope1;
        uint256 slope2;
    }
    struct AssetRiskParams {
        uint128 riskRatio;
        uint128 debtRiskRatio;
        int24 rangeSize;
        int24 rebalanceThreshold;
        uint64 minSlippage;
        uint64 maxSlippage;
    }
    struct AddPairParams {
        address marginId;
        address poolOwner;
        address uniswapPool;
        address priceFeed;
        bool whitelistEnabled;
        uint8 fee;
        AssetRiskParams assetRiskParams;
        IRMParams quoteIrmParams;
        IRMParams baseIrmParams;
    }
    struct TradeParams {
        uint256 pairId;
        uint256 vaultId;
        int256 tradeAmount;
        int256 tradeAmountSqrt;
        bytes extraData;
    }

    function operator() external view returns (address);
    function registerPair(AddPairParams memory p) external returns (uint256);
    function trade(TradeParams memory p, bytes memory settlementData) external returns (bytes memory);
    function withdraw(uint256 pairId, bool isQuoteAsset, uint256 withdrawAmount)
        external returns (uint256, uint256);
    function supply(uint256 pairId, bool isQuoteAsset, uint256 supplyAmount) external returns (uint256);
    function take(bool isQuoteAsset, address to, uint256 amount) external;
    function createVault(uint256 pairId) external returns (uint256);
    function reallocate(uint256 pairId, bytes memory settlementData) external returns (bool);
}

/// @title Predy V2 PredyPool — 2024 "caller-becomes-owner" registerPair drain: live reachability PoC
/// @notice Read-only research. Fork only. No mainnet transactions.
contract PredyRegisterPairTest is Test {
    // Arbitrum mainnet
    IPredyPool constant POOL = IPredyPool(0x9215748657319B17fecb2b5D086A3147BFBC8613);
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // native USDC
    address constant USDC_E = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // bridged USDC.e
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    address constant ATTACKER = address(0x1111);

    function forkRpc() internal view returns (string memory) {
        string memory u = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(u).length == 0) u = "https://arb1.arbitrum.io/rpc";
        return u;
    }

    function setUp() public {
        vm.createSelectFork(forkRpc());
    }

    function _params() internal view returns (IPredyPool.AddPairParams memory p) {
        p = IPredyPool.AddPairParams({
            marginId: WETH,
            poolOwner: ATTACKER,
            uniswapPool: 0xC6962004f452bE9203591991D15f6b388e09E8D0,
            priceFeed: ATTACKER,
            whitelistEnabled: false,
            fee: 0,
            assetRiskParams: IPredyPool.AssetRiskParams({
                riskRatio: 100_000_001,
                debtRiskRatio: 0,
                rangeSize: 1000,
                rebalanceThreshold: 500,
                minSlippage: 1_005_000,
                maxSlippage: 1_050_000
            }),
            quoteIrmParams: IPredyPool.IRMParams(1e16, 9e17, 5e17, 1e18),
            baseIrmParams: IPredyPool.IRMParams(1e16, 9e17, 5e17, 1e18)
        });
    }

    /// @notice The 2024 exploit primitive (permissionless registerPair) now reverts for an outsider.
    function test_registerPair_is_operator_gated() public {
        IPredyPool.AddPairParams memory p = _params();
        vm.prank(ATTACKER);
        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        POOL.registerPair(p);
    }

    /// @notice Every value-moving entry point is `onlyOperator` too, so even a registered pair is useless to an outsider.
    function test_all_value_paths_operator_gated() public {
        IPredyPool.TradeParams memory tp =
            IPredyPool.TradeParams({pairId: 2, vaultId: 0, tradeAmount: 0, tradeAmountSqrt: 0, extraData: ""});

        vm.startPrank(ATTACKER);
        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        POOL.trade(tp, "");
        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        POOL.withdraw(2, true, 1);
        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        POOL.supply(2, true, 1);
        // `take` is `onlyByLocker onlyOperator`; the locker is unset, so it reverts LockedBy(0) before the operator gate.
        vm.expectRevert(abi.encodeWithSelector(IPredyPool.LockedBy.selector, address(0)));
        POOL.take(true, ATTACKER, 1);
        vm.stopPrank();
    }

    /// @notice Control: the operator (proxy admin EOA 0x4f07..) CAN register — confirming the gate is the only barrier.
    function test_operator_can_register_control() public {
        address op = POOL.operator();
        assertEq(op, 0x4f071924D66BBC71A5254217893CC7D49938B1c4, "operator == EIP-173 proxy admin");
        IPredyPool.AddPairParams memory p = _params();
        vm.prank(op);
        uint256 pairId = POOL.registerPair(p);
        assertGt(pairId, 0, "operator can register a pair");
    }

    /// @notice Permissionless surface check: createVault() and reallocate() are callable by anyone, but neither
    /// can move pooled tokens to the caller (take/supply/withdraw are operator/locker gated). Documents residual.
    function test_permissionless_surface_is_harmless() public {
        vm.startPrank(ATTACKER);
        uint256 vaultId = POOL.createVault(2);
        assertGt(vaultId, 0, "createVault is permissionless (by design, no value moved)");
        POOL.reallocate(2, "");
        vm.stopPrank();
    }

    /// @notice Quantify the live value an outsider could ever reach through the pool contract.
    function test_measure_live_pool_value() public {
        uint256 usdc = IERC20(USDC).balanceOf(address(POOL));
        uint256 usdce = IERC20(USDC_E).balanceOf(address(POOL));
        uint256 weth = IERC20(WETH).balanceOf(address(POOL));
        uint256 arb = IERC20(ARB).balanceOf(address(POOL));
        emit log_named_uint("pool USDC (6dp)", usdc);
        emit log_named_uint("pool USDC.e (6dp)", usdce);
        emit log_named_uint("pool WETH (18dp)", weth);
        emit log_named_uint("pool ARB (18dp)", arb);
        // The headline: the drain recipe's target holds ~$0 USDC/WETH; only dust + ~82.8 ARB remain.
        assertEq(usdc, 0);
        assertEq(weth, 0);
    }
}
