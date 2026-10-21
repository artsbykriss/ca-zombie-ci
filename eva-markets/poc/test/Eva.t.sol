// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console, Vm} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

struct MarketState {
    bool isClosed;
    uint128 maxTotalSupply;
    uint128 accruedProtocolFees;
    uint128 normalizedUnclaimedWithdrawals;
    uint104 scaledTotalSupply;
    uint104 scaledPendingWithdrawals;
    uint32 pendingWithdrawalExpiry;
    bool isDelinquent;
    uint32 timeDelinquent;
    uint16 protocolFeeBips;
    uint16 annualInterestBips;
    uint16 reserveRatioBips;
    uint112 scaleFactor;
    uint32 lastInterestAccruedTimestamp;
}

interface IWildcat {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function scaledBalanceOf(address) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalDebts() external view returns (uint256);
    function scaleFactor() external view returns (uint256);
    function currentState() external view returns (MarketState memory);
    function queueWithdrawal(uint256) external returns (uint32);
    function queueFullWithdrawal() external;
    function updateState() external;
    function getUnpaidBatchExpiries() external view returns (uint32[] memory);
    function asset() external view returns (address);
}

struct RequestDetails {
    address requestor;
    uint256 shareAmount;
    uint256 requestAmount;
    uint256 requestTime;
    uint32 expiry;
    bool isProcessed;
    address receiver;
}

interface IEva {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function deposit(uint256, address) external returns (uint256);
    function depositFromMarket(uint256, address) external returns (uint256);
    function requestRedeem(uint256) external;
    function queueRequestsBatch(uint256[] calldata) external returns (uint32);
    function claimRequest(uint256) external;
    function excess() external view returns (uint256);
    function market() external view returns (address);
    function previewRedeem(uint256) external view returns (uint256);
    function minAmount() external view returns (uint256);
}

/// @title Eva Markets — Wildcat face-valuation PoC (read-only mainnet fork)
contract EvaTest is Test {
    address constant EVA_USDC = 0x741bD193B6b40f8703d2e116FD1965421f290F58;
    address constant EVA_USDT = 0x501eBf66d76A96D4FB26ccead42957653e16B8B8;
    address constant EVA_ETH = 0xdBECD077c1C2feFDCB75f547d1b5a73BF8207e4C;
    address constant M_USDC = 0xC9499006a149C553d18171747ED19Aa7C6Dd19E2;
    address constant M_USDT = 0x5Ab22e9c360807F16DFA34AD5C589055d2871a5B;
    address constant M_ETH = 0xBAd1b632E90Ce02af868f07c572adB067eB98353;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant OPERATOR = 0x42E24C894Dc784276828fE74f47B35B0c8A676fD;
    address constant CURVE_POOL = 0x3C0965582dB7A0F660D491aA6174B9438f911c21;

    uint256 constant FORK_BLOCK = 26241741;

    event RequestSubmitted(RequestDetails requestDetails, uint256 requestId);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))),
            FORK_BLOCK
        );
    }

    function _lastRequestId() internal returns (uint256 id) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 sig = keccak256("RequestSubmitted((address,uint256,uint256,uint256,uint32,bool,address),uint256)");
        for (uint256 i = logs.length; i > 0; i--) {
            if (logs[i - 1].topics[0] == sig) {
                (, id) = abi.decode(logs[i - 1].data, (RequestDetails, uint256));
                return id;
            }
        }
        revert("no RequestSubmitted log");
    }

    function test_live_markets_current_and_vault_state() public {
        console.log("block", block.number);
        console.log("evaUSDC totalAssets", IEva(EVA_USDC).totalAssets());
        console.log("evaUSDT totalAssets", IEva(EVA_USDT).totalAssets());
        console.log("evaETH totalAssets", IEva(EVA_ETH).totalAssets());
        console.log("evaUSDC market", IEva(EVA_USDC).market());

        MarketState memory a = IWildcat(M_USDC).currentState();
        MarketState memory b = IWildcat(M_USDT).currentState();
        MarketState memory c = IWildcat(M_ETH).currentState();
        console.log("USDC delinq/time", a.isDelinquent, a.timeDelinquent);
        console.log("USDT delinq/time", b.isDelinquent, b.timeDelinquent);
        console.log("WETH delinq/time", c.isDelinquent, c.timeDelinquent);
        assertFalse(a.isDelinquent);
        assertFalse(b.isDelinquent);
        assertFalse(c.isDelinquent);
        assertEq(a.timeDelinquent, 0);
        assertEq(b.timeDelinquent, 0);

        console.log("wmtUSDC cash", IWildcat(M_USDC).totalAssets());
        console.log("wmtUSDC debt", IWildcat(M_USDC).totalDebts());
        console.log("wmtUSDC supply", IWildcat(M_USDC).totalSupply());
        console.log("wmtUSDT cash", IWildcat(M_USDT).totalAssets());
        console.log("wmtUSDT debt", IWildcat(M_USDT).totalDebts());
        console.log("wmtUSDT supply", IWildcat(M_USDT).totalSupply());
        console.log("wmtWETH cash", IWildcat(M_ETH).totalAssets());
        console.log("wmtWETH debt", IWildcat(M_ETH).totalDebts());

        console.log("evaUSDC market token bal", IWildcat(M_USDC).balanceOf(EVA_USDC));
        console.log("evaUSDT market token bal", IWildcat(M_USDT).balanceOf(EVA_USDT));
        console.log("evaETH market token bal", IWildcat(M_ETH).balanceOf(EVA_ETH));

        console.log("evaUSDC idle USDC", IERC20(USDC).balanceOf(EVA_USDC));
        console.log("evaUSDC excess", IEva(EVA_USDC).excess());
        console.log("evaUSDT excess", IEva(EVA_USDT).excess());
        console.log("evaETH excess", IEva(EVA_ETH).excess());
        console.log("minAmount", IEva(EVA_USDC).minAmount());

        assertEq(IEva(EVA_USDC).totalAssets(), 2440738433896);
        assertEq(IEva(EVA_USDC).totalSupply(), 2440738433896);
        assertEq(IWildcat(M_USDC).totalDebts(), 74024134675696);
    }

    /// @dev Demonstrates that a market token is converted at face: shares minted
    ///      equal the received normalized (face) amount, 1:1.
    function test_depositFromMarket_mints_at_face() public {
        uint256 amount = 2_500e6;
        deal(USDC, address(this), amount);
        IERC20(USDC).approve(M_USDC, amount);
        IWildcat(M_USDC).deposit(amount);

        uint256 mt = IERC20(M_USDC).balanceOf(address(this));
        console.log("market tokens received", mt);
        assertApproxEqAbs(mt, amount, 2);

        uint256 ta0 = IEva(EVA_USDC).totalAssets();
        uint256 ts0 = IEva(EVA_USDC).totalSupply();
        IERC20(M_USDC).approve(EVA_USDC, mt);
        uint256 shares = IEva(EVA_USDC).depositFromMarket(mt, address(this));
        console.log("shares minted", shares);
        console.log("previewRedeem(shares)", IEva(EVA_USDC).previewRedeem(shares));

        assertApproxEqAbs(shares, mt, 2);
        assertApproxEqAbs(IEva(EVA_USDC).totalAssets(), ta0 + mt, 2);
        assertApproxEqAbs(IEva(EVA_USDC).totalSupply(), ts0 + shares, 2);
        assertEq(IEva(EVA_USDC).previewRedeem(shares), shares);
    }

    /// @dev Full round trip while the market is current: the depositor gets back
    ///      exactly the face amount, i.e. the path is fair today.
    function test_current_market_roundtrip_is_breakeven() public {
        uint256 amount = 2_500e6;
        deal(USDC, address(this), amount);
        IERC20(USDC).approve(M_USDC, amount);
        IWildcat(M_USDC).deposit(amount);
        uint256 mt = IERC20(M_USDC).balanceOf(address(this));

        IERC20(M_USDC).approve(EVA_USDC, mt);
        uint256 shares = IEva(EVA_USDC).depositFromMarket(mt, address(this));

        vm.recordLogs();
        IEva(EVA_USDC).requestRedeem(shares);
        uint256 reqId = _lastRequestId();
        uint256[] memory ids = new uint256[](1);
        ids[0] = reqId;

        vm.prank(OPERATOR);
        IEva(EVA_USDC).queueRequestsBatch(ids);
        vm.warp(block.timestamp + 86400 + 1);

        uint256 before = IERC20(USDC).balanceOf(address(this));
        IEva(EVA_USDC).claimRequest(reqId);
        uint256 got = IERC20(USDC).balanceOf(address(this)) - before;
        console.log("USDC out on claim", got);
        console.log("profit/loss vs deposit", int256(got) - int256(amount));
        assertApproxEqAbs(got, amount, 2); // exact break-even (rounding <= 2 wei), minus gas
    }

    /// @dev A 200k exit by one holder (8.2% of evaUSDC) cannot be paid from the
    ///      market's 126k cash: the batch is partial, claim reverts, and the vault
    ///      freezes all further request queueing (ActiveBatchExists).
    function test_large_exit_partial_batch_freezes_vault() public {
        console.log("market cash before", IWildcat(M_USDC).totalAssets());
        uint256 amount = 200_000e6;
        vm.recordLogs();
        vm.prank(CURVE_POOL); // existing evaUSDC holder (Curve pool holds 1.916M shares)
        IEva(EVA_USDC).requestRedeem(amount);
        uint256 reqId = _lastRequestId();

        uint256[] memory ids = new uint256[](1);
        ids[0] = reqId;
        vm.prank(OPERATOR);
        IEva(EVA_USDC).queueRequestsBatch(ids);

        vm.warp(block.timestamp + 86400 + 1);
        vm.expectRevert(); // partial batch: vault holds < 200k, claim needs full amount
        IEva(EVA_USDC).claimRequest(reqId);

        IWildcat(M_USDC).updateState();
        MarketState memory s = IWildcat(M_USDC).currentState();
        console.log("delinquent after 200k exit", s.isDelinquent);
        console.log("timeDelinquent", s.timeDelinquent);
        console.log("vault idle USDC", IERC20(USDC).balanceOf(EVA_USDC));
        assertTrue(s.isDelinquent);

        uint32[] memory unpaid = IWildcat(M_USDC).getUnpaidBatchExpiries();
        console.log("unpaid batches", unpaid.length);
        assertGt(unpaid.length, 0);

        // A second request can no longer be queued: active batch is not fully paid.
        vm.recordLogs();
        vm.prank(CURVE_POOL);
        IEva(EVA_USDC).requestRedeem(3_000e6);
        uint256 reqId2 = _lastRequestId();
        uint256[] memory ids2 = new uint256[](1);
        ids2[0] = reqId2;
        vm.prank(OPERATOR);
        vm.expectRevert();
        IEva(EVA_USDC).queueRequestsBatch(ids2);
    }

    /// @dev The core mark-to-face bug: while the market is delinquent, new market
    ///      tokens are still priced at 100% face and minted 1:1.
    function test_delinquent_market_still_minted_at_face() public {
        // Force an unpaid batch with the vault's own 2.445M market token balance.
        vm.prank(EVA_USDC);
        IWildcat(M_USDC).queueWithdrawal(2_000_000e6);
        vm.warp(block.timestamp + 86400 + 1);
        IWildcat(M_USDC).updateState();
        MarketState memory s = IWildcat(M_USDC).currentState();
        console.log("delinquent", s.isDelinquent);
        assertTrue(s.isDelinquent);

        uint256 amount = 2_500e6;
        deal(USDC, address(this), amount);
        IERC20(USDC).approve(M_USDC, amount);
        IWildcat(M_USDC).deposit(amount);
        uint256 mt = IERC20(M_USDC).balanceOf(address(this));
        uint256 ta0 = IEva(EVA_USDC).totalAssets();

        IERC20(M_USDC).approve(EVA_USDC, mt);
        uint256 shares = IEva(EVA_USDC).depositFromMarket(mt, address(this));
        console.log("shares at face while delinquent", shares);
        console.log("vault totalAssets after", IEva(EVA_USDC).totalAssets());
        assertApproxEqAbs(shares, mt, 2);
        assertApproxEqAbs(IEva(EVA_USDC).totalAssets(), ta0 + mt, 2);
        assertEq(IEva(EVA_USDC).previewRedeem(shares), shares);
    }
}
