// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IOracle {
    function get_price() external view returns (uint256);
}

interface ISortedTroves {
    function last() external view returns (uint256);
    function prev(uint256) external view returns (uint256);
    function size() external view returns (uint256);
}

interface ITroveManager {
    function liquidate_trove(uint256, uint256, address) external returns (uint256);
    function redeem(uint256, address) external;
    function close_zombie_trove(uint256) external;
    function get_trove_debt_after_interest(uint256) external view returns (uint256);
    function price_oracle() external view returns (address);
    function sorted_troves() external view returns (address);
    function collateral_token() external view returns (address);
    function borrow_token() external view returns (address);
    function borrow_token_precision() external view returns (uint256);
}

/// @notice Fork checks for Flex (Liquity-v1 fork, custom share-price oracles).
/// Read-only against a fork; no mainnet transactions.
contract FlexForkTest is Test {
    // Snapshot block 26,217,683 (2026-10-18 06:34 UTC)
    uint256 constant SNAP = 26_217_683;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // yvUSD market (9 active troves; min CR 1.10175 at snapshot)
    address constant M_YVUSD = 0x8ee72c388aA73096338EE18CD46a39D98b8983c9;
    // yvcrvUSD market (min CR 1.10127 at snapshot)
    address constant M_YVCRV = 0x7582b47486F75F5D675f260d357972cD0DbEeA2E;
    // ysyBOLD market (min CR 1.10257 at snapshot)
    address constant M_YSYBOLD = 0xADf4E0226d59aac20272023c04B4DcF5Ade7Fc6E;

    // Zombie troves observed at snapshot (debt 0, collateral still in the TroveManager).
    uint256 constant Z_YVUSD_1 = 56561608069871619938672676192903653785163568072982414190076063014415970054973;
    uint256 constant Z_YVUSD_2 = 60365368387372377871352529054168902787205141492607880929245764628489152332952;
    uint256 constant Z_YVUSD_3 = 21175110529243671096927887014227767178899550713246808878035828630072060421320;
    uint256 constant Z_YSYBOLD = 78433219526561643495762864192840627886342138819788057196197278423631193892196;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", vm.envOr("BLOCKPI_RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
        vm.createSelectFork(rpc, SNAP);
    }

    /// @dev Return raw trove words. Deployed getter has 8 words:
    ///      [debt, collateral, rate, t1, t2, t3, owner, status]
    function _troveWords(address market, uint256 id) internal view returns (uint256 debt, uint256 coll, address owner, uint256 status) {
        (bool ok, bytes memory data) = market.staticcall(abi.encodeWithSignature("troves(uint256)", id));
        require(ok && data.length >= 8 * 32, "trove read");
        assembly {
            debt := mload(add(data, 32))
            coll := mload(add(data, 64))
            owner := mload(add(data, 224))
            status := mload(add(data, 256))
        }
        owner = address(uint160(owner));
    }

    function _cr(address market, uint256 coll, uint256 debt) internal view returns (uint256) {
        uint256 price = IOracle(ITroveManager(market).price_oracle()).get_price();
        uint256 borrowPrecision = ITroveManager(market).borrow_token_precision();
        // collateral_value is in borrow-token base units
        uint256 collateralValue = coll * price / 1e36;
        return collateralValue * borrowPrecision / debt;
    }

    /// @dev Lowest-CR active trove in the market, using the sorted list.
    function _minCR(address market) internal view returns (uint256 bestId, uint256 bestCr, uint256 bestDebt, uint256 bestColl) {
        uint256 id = ISortedTroves(ITroveManager(market).sorted_troves()).last();
        bestCr = type(uint256).max;
        while (id != 0) {
            (uint256 debt, uint256 coll,,) = _troveWords(market, id);
            uint256 d = ITroveManager(market).get_trove_debt_after_interest(id);
            if (d > 0) {
                uint256 cr = _cr(market, coll, d);
                if (cr < bestCr) {
                    bestCr = cr;
                    bestId = id;
                    bestDebt = d;
                    bestColl = coll;
                }
            }
            id = ISortedTroves(ITroveManager(market).sorted_troves()).prev(id);
        }
    }

    function test_min_cr_above_mcr_now() public {
        (uint256 id, uint256 cr,,) = _minCR(M_YVCRV);
        emit log_named_uint("yvcrvUSD min CR (1e6)", cr);
        emit log_named_uint("trove", id);
        assertGt(cr, 1_100_000, "a trove is already liquidatable");
        // Lowest-CR trove cannot be liquidated at the live oracle price.
        (bool ok,) = M_YVCRV.call(
            abi.encodeWithSignature("liquidate_trove(uint256,uint256,address)", id, type(uint256).max, address(this))
        );
        assertFalse(ok, "liquidation unexpectedly succeeded");
    }

    /// @notice Proves the conditional E-U: a 2% oracle decline makes the
    ///         lowest-CR trove liquidatable and the bonus is positive.
    function test_liquidation_after_2pct_oracle_drop() public {
        (uint256 id,, uint256 debt, uint256 coll) = _minCR(M_YVCRV);
        require(id != 0, "no active trove");
        address oracle = ITroveManager(M_YVCRV).price_oracle();
        uint256 realPrice = IOracle(oracle).get_price();
        uint256 mockPrice = realPrice * 98 / 100;

        vm.mockCall(oracle, abi.encodeWithSignature("get_price()"), abi.encode(mockPrice));
        (, uint256 crMock,,) = _minCR(M_YVCRV);
        emit log_named_uint("min CR after 2% drop (1e6)", crMock);
        assertLt(crMock, 1_100_000, "not liquidatable after drop");

        deal(USDC, address(this), 10_000_000e6);
        IERC20(USDC).approve(M_YVCRV, type(uint256).max);
        address collToken = ITroveManager(M_YVCRV).collateral_token();
        uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
        uint256 collBefore = IERC20(collToken).balanceOf(address(this));

        ITroveManager(M_YVCRV).liquidate_trove(id, type(uint256).max, address(this));

        uint256 usdcPaid = usdcBefore - IERC20(USDC).balanceOf(address(this));
        uint256 collGot = IERC20(collToken).balanceOf(address(this)) - collBefore;
        vm.clearMockedCalls();

        // Value the seized collateral at the *real* (unmocked) oracle price.
        uint256 collValue = collGot * IOracle(oracle).get_price() / 1e36;
        emit log_named_uint("debt repaid (USDC 6dp)", usdcPaid);
        emit log_named_uint("collateral seized (coll dp)", collGot);
        emit log_named_uint("collateral value at real price (USDC 6dp)", collValue);
        assertGt(collValue, usdcPaid, "liquidation not profitable");
        emit log_named_int("profit (USDC 6dp)", int256(collValue) - int256(usdcPaid));
    }

    /// @notice Zombie troves with debt 0 hold collateral; only the owner can
    ///         close them (H-O, not E-U). The test also proves the gate.
    function test_zombie_close_is_owner_only() public {
        _checkZombie(M_YVUSD, Z_YVUSD_1);
        _checkZombie(M_YVUSD, Z_YVUSD_2);
        _checkZombie(M_YVUSD, Z_YVUSD_3);
        _checkZombie(M_YSYBOLD, Z_YSYBOLD);
    }

    function _checkZombie(address market, uint256 id) internal {
        (uint256 debt,, address owner, uint256 status) = _troveWords(market, id);
        if (status != 2 || debt != 0) return; // already closed by its owner
        address collToken = ITroveManager(market).collateral_token();

        // Unprivileged caller cannot close it.
        (bool ok,) = market.call(abi.encodeWithSignature("close_zombie_trove(uint256)", id));
        assertFalse(ok, "zombie closed by non-owner");

        // Owner can, and receives the collateral.
        uint256 before = IERC20(collToken).balanceOf(owner);
        vm.prank(owner);
        (bool ok2,) = market.call(abi.encodeWithSignature("close_zombie_trove(uint256)", id));
        assertTrue(ok2, "owner close failed");
        assertGt(IERC20(collToken).balanceOf(owner), before, "owner did not receive collateral");
        emit log_named_uint("zombie closed", id);
    }

    /// @notice TroveManager.redeem is onlyLender; external users cannot redeem.
    function test_redeem_is_lender_only() public {
        (bool ok,) = M_YVCRV.call(abi.encodeWithSignature("redeem(uint256,address)", 1e6, address(this)));
        assertFalse(ok, "redeem was callable externally");
    }
}
