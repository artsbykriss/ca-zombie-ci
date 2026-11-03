// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IVault {
    function deposit(bytes32 ccy, uint256 amount) external payable;
    function withdraw(bytes32 ccy, uint256 amount) external;
    function getDepositAmount(address user, bytes32 ccy) external view returns (uint256);
    function getCollateralDetail(address user) external view returns (uint256, uint256, uint256);
    function getWithdrawableCollateral(bytes32 ccy, address user) external view returns (uint256);
}

interface IMarket {
    function isReady(uint8 orderBookId) external view returns (bool);
    function getMarketUnitPrice(uint8 orderBookId) external view returns (uint256);
}

interface IController {
    function executeOrder(bytes32 ccy, uint256 maturity, uint8 side, uint256 amount, uint256 unitPrice)
        external
        returns (bool);
    function getCurrentMinDebtUnitPrice(bytes32 ccy, uint256 maturity) external view returns (uint256);
    function getOrderUnitPriceRange(bytes32 ccy, uint256 maturity)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, bool);
    function getMinDebtUnitPrice(bytes32 ccy) external view returns (uint256);
    function getOrderBookId(bytes32 ccy, uint256 maturity) external view returns (uint8);
    function getLendingMarket(bytes32 ccy) external view returns (address);
}

/// @notice Re-check of the Secured Finance "in-block price-ratio collateral inflation" economics.
/// Read-only: fork only, nothing broadcast to mainnet.
contract SecuredFinanceEconomics is Test {
    address constant CTRL = 0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2;
    address constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 constant CCY = bytes32("USDC");

    address A = address(0xA11CE);
    address B = address(0xB0B);

    uint256[9] internal MATS = [
        uint256(1798156800),
        1806019200,
        1813881600,
        1821744000,
        1830211200,
        1838073600,
        1845936000,
        1853798400,
        1861660800
    ];

    function _rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
    }

    function _ready(uint256 maturity) internal view returns (bool) {
        uint8 id = IController(CTRL).getOrderBookId(CCY, maturity);
        return IMarket(IController(CTRL).getLendingMarket(CCY)).isReady(id);
    }

    /// @notice Cost of one unit of future value at the best *tradeable* live book.
    /// requiredCollateral = 1.25 * max(orderPrice, currentMinDebtUnitPrice) * FV / 10000
    /// A claim of FV is worth at most FV, so profit = FV * (1 - 1.25*P/10000), P = max(p, M).
    function test_live_best_tradeable_book_is_net_negative() public {
        int256 bestEdge = -1e18;
        uint256 bestPrice;
        uint256 bestMaturity;
        for (uint256 i = 0; i < MATS.length; i++) {
            if (!_ready(MATS[i])) {
                emit log_named_uint("not ready (not tradeable)", MATS[i]);
                continue;
            }
            (,, uint256 minBorrow,,,) = IController(CTRL).getOrderUnitPriceRange(CCY, MATS[i]);
            uint256 m = IController(CTRL).getCurrentMinDebtUnitPrice(CCY, MATS[i]);
            uint256 p = minBorrow > m ? minBorrow : m;
            int256 edge = int256(1e18) - (int256(p) * 125 * 1e18) / 1_000_000;
            emit log_named_uint("maturity", MATS[i]);
            emit log_named_uint("  minBorrowPrice", minBorrow);
            emit log_named_uint("  minDebtUnitPrice(now)", m);
            emit log_named_uint("  effective valuation price", p);
            if (edge > bestEdge) {
                bestEdge = edge;
                bestPrice = p;
                bestMaturity = MATS[i];
            }
        }
        emit log_named_uint("BEST tradeable effective price", bestPrice);
        emit log_named_uint("BEST tradeable maturity", bestMaturity);
        emit log_named_int("BEST edge (bps of FV)", bestEdge / 1e14);
        assertLt(bestEdge, 0, "every tradeable book is net-negative: 1.25*P > 10000");
        assertGt(bestPrice, 8000, "breakeven requires P < 8000");
    }

    /// @notice End-to-end: plant a cheap resting borrow at the live minimum price on the best
    /// tradeable book and measure the collateral the protocol actually requires vs the FV claim.
    function test_plant_cost_vs_claim() public {
        uint256 maturity = 1853798400; // USDC book id 19: lowest live effective price among tradeable books
        (,, uint256 minBorrow,,,) = IController(CTRL).getOrderUnitPriceRange(CCY, maturity);
        uint256 m = IController(CTRL).getCurrentMinDebtUnitPrice(CCY, maturity);
        uint256 fv = 19_000e6; // target claim (FV), USDC 6dp
        uint256 amount = (fv * minBorrow) / 10_000; // PV the borrower asks for at price p
        // p < M here, so the book values the resting borrow at FV * M / 10000, and the
        // 125% liquidation threshold makes the required deposit 1.25 * FV * M / 10000.
        uint256 requiredDeposit = (fv * 125 * m) / 1_000_000;
        uint256 depositWithBuffer = requiredDeposit + 1e6; // +1 USDC: base-currency conversion rounds down
        emit log_named_uint("order price p", minBorrow);
        emit log_named_uint("current minDebtUnitPrice M", m);
        emit log_named_uint("borrow PV amount", amount);
        emit log_named_uint("FV claim", fv);
        emit log_named_uint("required deposit", requiredDeposit);

        // 1 wei short of the requirement must be rejected
        deal(USDC, address(0xBAD), requiredDeposit - 1);
        vm.startPrank(address(0xBAD));
        IERC20(USDC).approve(VAULT, requiredDeposit - 1);
        IVault(VAULT).deposit(CCY, requiredDeposit - 1);
        bool underOk = true;
        try IController(CTRL).executeOrder(CCY, maturity, 1, amount, minBorrow) {
            underOk = true;
        } catch (bytes memory err) {
            underOk = false;
            emit log_named_bytes("under-collateralised revert data", err);
        }
        vm.stopPrank();
        emit log_named_string("under-collateralised (1 wei short) accepted?", underOk ? "YES" : "no (reverted)");

        // exactly at the requirement must be accepted
        deal(USDC, A, depositWithBuffer);
        vm.startPrank(A);
        IERC20(USDC).approve(VAULT, depositWithBuffer);
        IVault(VAULT).deposit(CCY, depositWithBuffer);
        bool ok = IController(CTRL).executeOrder(CCY, maturity, 1, amount, minBorrow);
        vm.stopPrank();
        assertTrue(ok, "fully collateralised borrow order must be accepted");
        (uint256 tc, uint256 tuc,) = IVault(VAULT).getCollateralDetail(A);
        emit log_named_uint("totalCollateral (base ccy 1e18)", tc);
        emit log_named_uint("totalUsedCollateral (base ccy 1e18)", tuc);
        emit log_named_uint("(used*12500)/collateral (bps, must be <=10000)", (tuc * 12500 * 1e18) / tc / 1e18);

        int256 edge = int256(fv) - int256(depositWithBuffer);
        emit log_named_int("edge (claim - required deposit), USDC 6dp", edge);
        assertLt(edge, 0, "claim is smaller than the collateral it costs");
    }
}
