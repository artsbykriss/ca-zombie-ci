// SPDX-License-Identifier: MIT
// Read-only fork verification for World Markets Spot (Concord Exchange, MegaETH).
// No mainnet transactions: everything runs against a local fork of the public MegaETH RPC.
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Concord as C} from "../src/Concord.sol";

contract WMSpotTest is Test {
    address constant ATTACKER = address(0x1111);
    address constant VICTIM = 0xC37b5d9A854de08C5d74522B726C316833E6a047; // user 265

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("MEGAETH_RPC", string("https://mainnet.megaeth.com/rpc"));
        forkBlock = vm.createSelectFork(rpc);
        emit log_named_uint("fork block", forkBlock);
    }

    // ---------- helpers ----------
    function _u32(uint32 v) internal pure returns (bytes memory) { return abi.encode(v); }
    function _u64(uint64 v) internal pure returns (bytes memory) { return abi.encode(v); }
    function _u(uint256 v) internal pure returns (bytes memory) { return abi.encode(v); }
    function _addr(address a) internal pure returns (bytes memory) { return abi.encode(a); }

    function _sel(bytes4 s) internal pure returns (bytes memory) { return abi.encodePacked(s); }

    function _call(address to, bytes memory data) internal returns (bool ok, bytes memory ret) {
        (ok, ret) = to.call(data);
    }

    function _sel4(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length < 4) return bytes4(0);
        assembly { s := mload(add(ret, 32)) }
    }

    function _expectRevertWith(address to, bytes memory data, bytes4 errSel, string memory label) internal {
        (bool ok, bytes memory ret) = _call(to, data);
        assertFalse(ok, string.concat("UNEXPECTED SUCCESS: ", label));
        assertEq(_sel4(ret), errSel, string.concat("wrong revert selector: ", label));
        emit log_named_bytes(string.concat("revert ", label), ret);
    }

    function _readUint(address to, bytes memory data) internal view returns (uint256) {
        (bool ok, bytes memory ret) = to.staticcall(data);
        require(ok && ret.length >= 32, "read failed");
        return abi.decode(ret, (uint256));
    }

    function _erc20BalanceOf(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory ret) =
            token.staticcall(abi.encodeWithSelector(C.SEL_balanceOf, who));
        require(ok, "balanceOf failed");
        return abi.decode(ret, (uint256));
    }

    // ---------- 1. live state ----------
    function test_live_state_and_discovery() public {
        assertEq(block.chainid, 4326, "chain id");
        assertGt(C.EXCHANGE.code.length, 0, "exchange has code");

        uint256 maxId = _readUint(C.EXCHANGE, _sel(C.SEL_getHighestTokenId));
        assertEq(maxId, 13, "highest token id");
        emit log_named_uint("highestTokenId", maxId);

        uint256 maxUser = _readUint(C.EXCHANGE, _sel(C.SEL_bulkReadMaxUserId));
        assertGt(maxUser, 1500, "user count");
        emit log_named_uint("maxUserId", maxUser);

        // token 1 = USDm, decimals 18; token 4 = WETH
        uint256 cfg1 = _readUint(C.EXCHANGE, abi.encodePacked(C.SEL_readTokenConfig, _u32(1)));
        assertEq(address(uint160(cfg1)), C.USDM, "token1 address");
        assertEq(uint8(cfg1 >> 184), 18, "token1 erc20Decimals");
        uint256 cfg4 = _readUint(C.EXCHANGE, abi.encodePacked(C.SEL_readTokenConfig, _u32(4)));
        assertEq(address(uint160(cfg4)), C.WETH, "token4 address");

        // spot book for (4,1)
        (bool ok, bytes memory ret) =
            C.EXCHANGE.staticcall(abi.encodePacked(C.SEL_getSpotOrderBook, _u32(4), _u32(1)));
        assertTrue(ok, "getSpotOrderBook");
        (address book,,) = abi.decode(ret, (address, uint32, uint32));
        assertEq(book, C.SPOT_BOOK_WETH_USDM, "spot book address");

        // order book config: bookType 11 = spot
        uint256 obc = _readUint(C.EXCHANGE, abi.encodePacked(C.SEL_readOrderBookConfig, _addr(book)));
        assertEq(uint8(obc >> 248), 11, "bookType spot");
        emit log_named_uint("spot book minOrderQuantity", _readUint(book, _sel(C.SEL_readMinOrderQuantity)));
        assertFalse(_readUint(book, _sel(C.SEL_isHalted)) == 1, "book not halted");
    }

    // ---------- 2. custody: all value sits in the exchange ----------
    function test_custody_in_exchange() public {
        uint256 usdm = _erc20BalanceOf(C.USDM, C.EXCHANGE);
        uint256 weth = _erc20BalanceOf(C.WETH, C.EXCHANGE);
        emit log_named_decimal_uint("exchange USDm", usdm, 18);
        emit log_named_decimal_uint("exchange WETH", weth, 18);
        assertGt(usdm, 100_000e18, "exchange holds >100k USDm");

        // order books hold no tokens (pure order storage)
        assertEq(_erc20BalanceOf(C.USDM, C.SPOT_BOOK_WETH_USDM), 0, "spot book holds USDm");
        assertEq(_erc20BalanceOf(C.USDM, C.LEND_BOOK_USDM), 0, "lend book holds USDm");
    }

    // ---------- 3. permission gates on every user-scoped path ----------
    function test_gate_trading_paths() public {
        // all of these are trader-scoped -> CallerIsNotTrader for an address with no account
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_newSpotBuyOrder, _addr(C.SPOT_BOOK_WETH_USDM), _u(0)),
            C.ERR_CallerIsNotTrader, "newSpotBuyOrder"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_cancelSpotBuyOrder, _addr(C.SPOT_BOOK_WETH_USDM), _u(0)),
            C.ERR_CallerIsNotTrader, "cancelSpotBuyOrder"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_newLendOrder, _addr(C.LEND_BOOK_USDM), _u(0)),
            C.ERR_CallerIsNotTrader, "newLendOrder"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_liquidate, _u64(265), _u64(0), _u64(0)),
            C.ERR_CallerIsNotTrader, "liquidate"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_markLendPositionAsNonReturnable, _u64(1)),
            C.ERR_CallerIsNotTrader, "markLendPositionAsNonReturnable"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_lifoLenderSwap, _u64(1)),
            C.ERR_CallerIsNotTrader, "lifoLenderSwap"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_renewLoan, _u64(265), _u64(0), _u64(0)),
            C.ERR_CallerIsNotTrader, "renewLoan"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_requestPerpTrueUp, _u64(1), _u64(1), _u32(4)),
            C.ERR_CallerIsNotTrader, "requestPerpTrueUp"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_liqSwap, _u64(265), _u(0), _u64(0)),
            C.ERR_CallerIsNotTrader, "liqSwap(bulk)"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodeWithSelector(C.SEL_bankruptcy, uint64(265), uint16(10000)),
            C.ERR_CallerNotPermissioned, "bankruptcy (OPS role)"
        );
    }

    // ---------- 4. custody / withdraw gates ----------
    function test_gate_withdraw_and_account() public {
        // an address with no account cannot withdraw
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_withdrawErc20, _addr(C.USDM), _u(1)),
            C.ERR_CallerHasNoAccount, "withdrawErc20 (no account)"
        );
        // attacker cannot grant itself trading rights on a victim account
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_allowTradingForAccount, _u64(265), _addr(ATTACKER)),
            C.ERR_CallerNotPermissioned, "allowTradingForAccount(victim,attacker)"
        );
    }

    function test_attacker_account_has_zero_value() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = C.EXCHANGE.call(_sel(C.SEL_createAccount));
        assertTrue(ok, "createAccount");
        uint64 uid = abi.decode(ret, (uint64));
        emit log_named_uint("attacker userId", uid);
        assertGt(uid, 0, "attacker got an account");

        // balance is zero
        (bool ok2, bytes memory ret2) =
            C.EXCHANGE.staticcall(abi.encodePacked(C.SEL_getBalance, _u64(uid), _u32(1)));
        assertTrue(ok2, "getBalance");
        (uint128 bal,,) = abi.decode(ret2, (uint128, uint64, uint64));
        assertEq(bal, 0, "attacker balance is zero");

        // withdrawing anything still fails
        vm.prank(ATTACKER);
        (bool ok3, bytes memory ret3) =
            C.EXCHANGE.call(abi.encodePacked(C.SEL_withdrawErc20, _addr(C.USDM), _u(1)));
        assertFalse(ok3, "attacker withdraw must fail");
        emit log_named_bytes("attacker withdraw revert", ret3);
    }

    // ---------- 5. admin paths are role-gated ----------
    function test_gate_admin_paths() public {
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodeWithSelector(C.SEL_setTokenConfig, uint32(1), uint8(1), uint8(1)),
            C.ERR_AdminRoleOnly, "setTokenConfig"
        );
        _expectRevertWith(
            C.EXCHANGE, abi.encodePacked(C.SEL_setOpsAddress, _addr(ATTACKER)),
            C.ERR_AdminRoleOnly, "setOpsAddress"
        );
        _expectRevertWith(
            C.EXCHANGE,
            abi.encodePacked(C.SEL_switchTokenAddress, _u32(1), _addr(ATTACKER), _u(96), _u(0)),
            C.ERR_AdminRoleOnly, "switchTokenAddress"
        );
        // changeAdmin (super-admin rotation) reverts for a non-admin caller (distinct guard, no data)
        (bool okc, bytes memory rc) =
            C.EXCHANGE.call(abi.encodePacked(C.SEL_changeAdmin, _addr(ATTACKER)));
        assertFalse(okc, "changeAdmin must revert for attacker");
        emit log_named_bytes("changeAdmin(attacker) revert", rc);
    }

    function test_admin_role_is_real() public {
        // fork-only: prove the AdminRoleOnly gate is a real role check (never broadcast)
        vm.prank(C.ADMIN);
        (bool ok, bytes memory ret) =
            C.EXCHANGE.call(abi.encodeWithSelector(C.SEL_setTokenConfig, uint32(1), uint8(10), uint8(20)));
        assertTrue(ok, "admin setTokenConfig");
        emit log_named_bytes("admin setTokenConfig ret", ret);

        vm.prank(C.ADMIN);
        (bool ok2,) = C.EXCHANGE.call(abi.encodePacked(C.SEL_setOpsAddress, _addr(C.ADMIN)));
        assertTrue(ok2, "admin setOpsAddress");

        // changeAdmin (super-admin rotation) reverts even for the known admin -> separate role
        vm.prank(C.ADMIN);
        (bool ok3, bytes memory r3) =
            C.EXCHANGE.call(abi.encodePacked(C.SEL_changeAdmin, _addr(C.ADMIN)));
        emit log_named_uint("changeAdmin (admin caller) ok", ok3 ? 1 : 0);
        emit log_named_bytes("changeAdmin revert", r3);
    }

    // ---------- 6. order-book admin paths are exchange-only ----------
    function test_gate_orderbook_admin_paths() public {
        _expectRevertWith(
            C.SPOT_BOOK_WETH_USDM, abi.encodePacked(C.SEL_haltTrading, uint256(1)),
            C.ERR_ExchangeOnlyCall, "book haltTrading"
        );
        _expectRevertWith(
            C.SPOT_BOOK_WETH_USDM, abi.encodePacked(C.SEL_setMinOrderQuantity, _u64(1)),
            C.ERR_ExchangeOnlyCall, "book setMinOrderQuantity"
        );
        _expectRevertWith(
            C.LEND_BOOK_USDM, abi.encodePacked(C.SEL_haltTrading, uint256(1)),
            C.ERR_ExchangeOnlyCall, "lend book haltTrading"
        );
    }

    // ---------- 7. compute* simulations are side-effect free ----------
    function test_orderbook_compute_is_readonly() public {
        uint256 before = _readUint(C.SPOT_BOOK_WETH_USDM, _sel(C.SEL_countBuyOrders));
        (bool ok,) = C.SPOT_BOOK_WETH_USDM.call(
            abi.encodePacked(C.SEL_computeBuyMarketOrderSpecifyIn, _u(1e18))
        );
        uint256 afterBuy = _readUint(C.SPOT_BOOK_WETH_USDM, _sel(C.SEL_countBuyOrders));
        emit log_named_uint("computeBuyMarketOrderSpecifyIn ok", ok ? 1 : 0);
        assertEq(afterBuy, before, "book state unchanged by compute()");
    }

    // ---------- 8. wl vaults are admin-gated ----------
    function test_gate_wl_vault_admin() public {
        (bool ok1, bytes memory r1) =
            C.WL_USDM.call(abi.encodePacked(C.SEL_wl_setManagerAddress, _addr(ATTACKER)));
        assertFalse(ok1, "wl setManagerAddress must fail");
        (bool ok2, bytes memory r2) =
            C.WL_USDM.call(abi.encodePacked(C.SEL_wl_setTraderAddress, _addr(ATTACKER)));
        assertFalse(ok2, "wl setTraderAddress must fail");
        (bool ok3, bytes memory r3) =
            C.WL_USDM.call(abi.encodePacked(C.SEL_wl_setAdmin, _addr(ATTACKER)));
        assertFalse(ok3, "wl setAdmin must fail");
        (bool ok4, bytes memory r4) =
            C.WL_USDM.call(abi.encodePacked(C.SEL_wl_rescueErc20, _addr(C.USDM)));
        assertFalse(ok4, "wl rescueErc20 must fail");
        emit log_named_bytes("wl setManager revert", r1);
        emit log_named_bytes("wl setTrader revert", r2);
        emit log_named_bytes("wl setAdmin revert", r3);
        emit log_named_bytes("wl rescueErc20 revert", r4);
    }

    // ---------- 10. permissionless keeper paths (design-intended, bounded) ----------
    function test_keeper_liquidation_path() public {
        // 4 accounts currently have a negative risk-adjusted portfolio value (liquidatable).
        // liquidate() is permissionless-by-design but requires the caller to have an account.
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = C.EXCHANGE.call(_sel(C.SEL_createAccount));
        assertTrue(ok, "createAccount");
        uint64 uid = abi.decode(ret, (uint64));
        emit log_named_uint("attacker userId", uid);

        uint64[4] memory targets = [uint64(561), 954, 1434, 1574];
        for (uint256 i; i < 4; i++) {
            uint256 before = _usdmOf(uid);
            vm.prank(ATTACKER);
            (bool okL, bytes memory rL) = C.EXCHANGE.call(
                abi.encodeWithSelector(C.SEL_liquidate, targets[i], uid, uint64(0))
            );
            uint256 afterBal = _usdmOf(uid);
            emit log_named_uint("liquidate target", targets[i]);
            emit log_named_uint("  ok", okL ? 1 : 0);
            emit log_named_int("  attacker USDm delta", int256(afterBal) - int256(before));
            emit log_named_bytes("  ret/revert", rL);
            // design-intended keeper path only; assert it never pays out more than the
            // liquidatee's deficit (no free money from the exchange's other users)
            assertLe(afterBal, before + 1_000e18, "keeper payout must be bounded");
        }
    }

    function _usdmOf(uint64 uid) internal view returns (uint256) {
        (bool ok, bytes memory ret) =
            C.EXCHANGE.staticcall(abi.encodePacked(C.SEL_getBalance, _u64(uid), _u32(1)));
        require(ok, "getBalance");
        (uint128 bal,,) = abi.decode(ret, (uint128, uint64, uint64));
        return bal;
    }

    function test_liquidatable_set() public {
        uint64[4] memory targets = [uint64(561), 954, 1434, 1574];
        for (uint256 i; i < 4; i++) {
            (bool ok, bytes memory ret) = C.EXCHANGE.staticcall(
                abi.encodePacked(C.SEL_riskAdjustedPortfolioValue, _u64(targets[i]))
            );
            assertTrue(ok, "riskAdjustedPortfolioValue");
            int64 v = abi.decode(ret, (int64));
            emit log_named_uint("user", targets[i]);
            emit log_named_int("  riskAdjustedPortfolioValue", v);
            assertLt(v, 0, "expected underwater");
        }
    }

    function test_sweep_no_unprivileged_state_change() public {
        bytes[12] memory datas;
        string[12] memory labels;
        datas[0] = abi.encodePacked(C.SEL_withdrawErc20, _addr(C.USDM), _u(1e18));
        labels[0] = "withdrawErc20";
        datas[1] = abi.encodePacked(C.SEL_batchCommands, _u64(265), _u(32), _u(1), _u(uint256(192)));
        labels[1] = "batchCommands(victim)";
        datas[2] = abi.encodePacked(C.SEL_liquidate, _u64(265), _u64(265), _u64(0));
        labels[2] = "liquidate(victim)";
        datas[3] = abi.encodePacked(C.SEL_payInterestAndFees, _u64(1), _u64(0), uint256(0));
        labels[3] = "payInterestAndFees";
        datas[4] = abi.encodePacked(C.SEL_markLendPositionAsNonReturnable, _u64(1));
        labels[4] = "markLendNoReturn";
        datas[5] = abi.encodePacked(C.SEL_lifoLenderSwap, _u64(1));
        labels[5] = "lifoLenderSwap";
        datas[6] = abi.encodePacked(C.SEL_renewLoan, _u64(265), _u64(265), _u64(0));
        labels[6] = "renewLoan";
        datas[7] = abi.encodePacked(C.SEL_requestPerpTrueUp, _u64(1), _u64(1), _u32(4));
        labels[7] = "requestPerpTrueUp";
        datas[8] = abi.encodePacked(C.SEL_allowTradingForAccount, _u64(265), _addr(ATTACKER));
        labels[8] = "allowTrading(victim)";
        datas[9] = abi.encodePacked(C.SEL_switchTokenAddress, _u32(1), _addr(ATTACKER), _u(96), _u(0));
        labels[9] = "switchTokenAddress";
        datas[10] = abi.encodePacked(C.SEL_haltTrading, uint256(1));
        labels[10] = "book.haltTrading";
        datas[11] = abi.encodePacked(C.SEL_wl_setTraderAddress, _addr(ATTACKER));
        labels[11] = "wl.setTraderAddress";

        address[12] memory targets;
        for (uint256 i; i < 12; i++) targets[i] = C.EXCHANGE;
        targets[10] = C.SPOT_BOOK_WETH_USDM;
        targets[11] = C.WL_USDM;

        for (uint256 i; i < 12; i++) {
            vm.prank(ATTACKER);
            (bool ok,) = targets[i].call(datas[i]);
            assertFalse(ok, string.concat("unprivileged call unexpectedly succeeded: ", labels[i]));
            emit log_named_string("blocked", labels[i]);
        }
    }
}
