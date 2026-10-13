// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GeistInterfaces.sol";

/// @title Geist Finance — liquidation extractability PoC (fork, read-only on mainnet)
/// @notice Reads ci-out/borrowers.json (produced by analysis/scan_borrowers.py on CI) and, for
///         each live borrower with HF < 1, measures the net P&L of a real liquidation:
///         buy debt token on SpookySwap -> liquidationCall -> redeem/sell seized collateral.
contract GeistLiquidationTest is Test {
    address constant POOL = 0x9FAD24f572045c7869117160A571B2e50b10d068;
    address constant ORACLE = 0xC466e3FeE82C6bdc2E17f2eaF2c6F1E91AD10FD3;
    address constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address[9] ASSETS = [
        0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E, // DAI
        0x74b23882a30290451A17c44f4F05243b6b58C76d, // ETH
        0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83, // WFTM
        0x321162Cd933E2Be498Cd2267a90534A804051b11, // BTC
        0x049d68029688eAbF473097a2fC38ef61633A3C7A, // fUSDT
        0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, // USDC
        0x1E4F97b9f9F913c46F1632781732927B9019C68b, // CRV
        0x82f0B8B456c1A451378467398982d4834b6829c1, // MIM
        0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8  // LINK
    ];
    function sym(uint256 i) internal pure returns (string memory) {
        string[9] memory s = ["DAI", "ETH", "WFTM", "BTC", "fUSDT", "USDC", "CRV", "MIM", "LINK"];
        return s[i];
    }

    uint256 MAX_BORROWERS = 60;   // keep CI bounded
    uint256 TOP_N = 8;            // attempt liquidations for the worst N

    function _selectFork() internal returns (uint256) {
        string[6] memory urls = [
            vm.envOr("FANTOM_RPC_URL", string("")),
            "https://rpc2.fantom.network",
            "https://rpc3.fantom.network",
            "https://rpcapi.fantom.network",
            "https://fantom.drpc.org",
            "https://1rpc.io/ftm"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            try vm.createSelectFork(urls[i]) returns (uint256) {
                return block.number;
            } catch {}
            // note: createSelectFork returns the fork id; block.number is read below
        }
        revert("no working fantom fork rpc");
    }

    function setUp() public {
        _selectFork();
        emit log_named_uint("fork block", block.number);
    }

    function _readBorrowersFile() internal returns (string memory) {
        try vm.readFile("../ci-out/borrowers.txt") returns (string memory s) {
            return s;
        } catch {}
        try vm.readFile("ci-out/borrowers.txt") returns (string memory s) {
            return s;
        } catch {}
        return "";
    }

    function _readBorrowers() internal returns (address[] memory addrs, uint256[] memory hfs) {
        // ci-out/borrowers.txt: one "address,hf" per line, hf ascending
        string memory txt = _readBorrowersFile();
        string[] memory lines = vm.split(txt, "\n");
        uint256 n;
        for (uint256 i = 0; i < lines.length && n < MAX_BORROWERS; i++) {
            if (bytes(lines[i]).length > 10) n++;
        }
        addrs = new address[](n);
        hfs = new uint256[](n);
        uint256 k;
        for (uint256 i = 0; i < lines.length && k < n; i++) {
            if (bytes(lines[i]).length <= 10) continue;
            string[] memory parts = vm.split(lines[i], ",");
            addrs[k] = vm.parseAddress(parts[0]);
            hfs[k] = vm.parseUint(parts[1]);
            k++;
        }
    }

    /// generic liquidation attempt: repay `debtAmount` of `debt` to seize `coll` from `user`
    function _tryLiquidate(address user, address coll, address debt, uint256 debtAmount)
        internal
        returns (int256 pnlWftm, string memory note)
    {
        address attacker = makeAddr("attacker");
        uint256 wftmBefore;
        // fund attacker with debt token: buy on spooky (or deal WFTM)
        if (debt == WFTM) {
            deal(WFTM, attacker, debtAmount + 10e18);
        } else {
            address[] memory pathBuy = new address[](2);
            pathBuy[0] = WFTM;
            pathBuy[1] = debt;
            uint256 cost;
            try IUniswapV2Router(SPOOKY_ROUTER).getAmountsOut(debtAmount, pathBuy) returns (uint256[] memory a) {
                cost = a[1];
            } catch {
                return (0, "no market for debt token");
            }
            deal(WFTM, attacker, cost * 2 + 10e18);
            wftmBefore = cost * 2 + 10e18;
            vm.startPrank(attacker);
            IERC20(WFTM).approve(SPOOKY_ROUTER, cost * 2);
            try IUniswapV2Router(SPOOKY_ROUTER).swapExactTokensForTokens(cost, debtAmount, pathBuy, attacker, block.timestamp)
            returns (uint256[] memory) {}
            catch {
                vm.stopPrank();
                return (0, "buy debt failed");
            }
            vm.stopPrank();
        }
        uint256 debtBal = IERC20(debt).balanceOf(attacker);
        if (debtBal < debtAmount) return (0, "insufficient debt token acquired");

        vm.startPrank(attacker);
        IERC20(debt).approve(POOL, debtAmount);
        // liquidate; receive aTokens (so the call is not limited by the collateral reserve's cash)
        try ILendingPool(POOL).liquidationCall(coll, debt, user, debtAmount, true) {
            note = "liquidated (aTokens)";
        } catch {
            vm.stopPrank();
            return (0, "liquidationCall reverted");
        }
        // redeem the seized aTokens for underlying, capped by available cash
        IAToken aColl = IAToken(ILendingPool(POOL).getReserveData(coll).aTokenAddress);
        uint256 aBal = aColl.balanceOf(attacker);
        uint256 cash = IERC20(coll).balanceOf(address(aColl));
        uint256 redeemAmt = aBal < cash ? aBal : cash;
        if (redeemAmt > 0) {
            try ILendingPool(POOL).withdraw(coll, redeemAmt, attacker) {}
            catch { note = string.concat(note, " redeem reverted"); }
        }
        // sell any underlying received
        uint256 got = IERC20(coll).balanceOf(attacker);
        if (got > 0) {
            IERC20(coll).approve(SPOOKY_ROUTER, got);
            address[] memory pathSell = new address[](2);
            pathSell[0] = coll;
            pathSell[1] = WFTM;
            try IUniswapV2Router(SPOOKY_ROUTER).swapExactTokensForTokens(got, 0, pathSell, attacker, block.timestamp)
            returns (uint256[] memory) {
                note = string.concat(note, " + sold");
            } catch {
                note = string.concat(note, " but collateral not sellable");
            }
        }
        uint256 wftmAfter = IERC20(WFTM).balanceOf(attacker);
        pnlWftm = int256(wftmAfter) - int256(wftmBefore);
        vm.stopPrank();
    }

    function test_liquidate_worst_borrowers() public {
        (address[] memory users, uint256[] memory hfs) = _readBorrowers();
        emit log_named_uint("borrowers parsed", users.length);

        // Walk borrowers in HF order; skip those with no collateral (nothing to seize);
        // attempt liquidations for the first TOP_N that do have collateral.
        uint256 attempted;
        for (uint256 k = 0; k < users.length && attempted < TOP_N; k++) {
            uint256 best = type(uint256).max;
            uint256 bestIdx = type(uint256).max;
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == address(0)) continue;
                if (hfs[i] < best) {
                    best = hfs[i];
                    bestIdx = i;
                }
            }
            if (bestIdx == type(uint256).max) break;
            address user = users[bestIdx];
            users[bestIdx] = address(0);

            ILendingPool pool = ILendingPool(POOL);
            uint256[9] memory collBal;
            uint256[9] memory debtBal;
            uint256 anyColl;
            uint256 anyDebt;
            for (uint256 ci = 0; ci < ASSETS.length; ci++) {
                collBal[ci] = IERC20(pool.getReserveData(ASSETS[ci]).aTokenAddress).balanceOf(user);
                debtBal[ci] = IERC20(pool.getReserveData(ASSETS[ci]).variableDebtTokenAddress).balanceOf(user);
                anyColl += collBal[ci];
                anyDebt += debtBal[ci];
            }
            if (anyDebt == 0 || anyColl == 0) {
                emit log_named_address("skip (no collateral or no debt)", user);
                continue;
            }
            attempted++;
            emit log_named_address("worst borrower with collateral", user);
            emit log_named_uint("  healthFactor(1e18)", best);
            for (uint256 ci = 0; ci < ASSETS.length; ci++) {
                if (collBal[ci] > 0) emit log_named_uint(string.concat("  collateral ", sym(ci)), collBal[ci]);
                if (debtBal[ci] > 0) emit log_named_uint(string.concat("  debt ", sym(ci)), debtBal[ci]);
            }

            // attempt the liquidation for every (collateral, debt) pair
            for (uint256 ci = 0; ci < ASSETS.length; ci++) {
                if (collBal[ci] == 0) continue;
                for (uint256 di = 0; di < ASSETS.length; di++) {
                    if (debtBal[di] == 0) continue;
                    // close factor 50%
                    uint256 repay = debtBal[di] / 2;
                    if (repay == 0) continue;
                    (int256 pnl, string memory note) = _tryLiquidate(user, ASSETS[ci], ASSETS[di], repay);
                    emit log_named_string("  attempt", string.concat(sym(ci), " <- ", sym(di)));
                    emit log_named_int("  pnl WFTM", pnl);
                    emit log_named_string("  note", note);
                }
            }
        }
    }
}
