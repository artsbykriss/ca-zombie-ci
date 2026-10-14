// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/OrbitInterfaces.sol";

/// @title Orbit Protocol (Blast) — live-state probes and extraction-path PoCs.
/// @notice Read-only against mainnet: all tests run on a Blast fork, no broadcasts.
contract OrbitTest is Test {
    address constant C1 = 0x1E18C3cb491D908241D0db14b081B51be7B6e652;
    address constant C2 = 0x273683CA19D9CF827628EE216E4a9604EfB077A3;
    address constant C3 = 0xe9266ae95bB637A7Ad598CB0390d44262130F433;
    address constant C4 = 0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5;

    // markets
    address constant M_C1_OETH1 = 0xF92996dDC677a8Dcb032Ac5Fe62bBf00f92aE2Ec;
    address constant M_C1_EMPTY = 0xd847B486Fe612C51900F1Da1A045741820Dd5fA0;
    address constant M_C1_USDB = 0x9aECEdCD6A82d26F2f86D331B17a1C1676442A87;
    address constant M_C1_OETH2 = 0xF9B3B455f5d900f62bC1792A6Ca6e1d47B989389;
    address constant M_C1_OETHV2 = 0x0872b71EFC37CB8DdE22B2118De3d800427fdba0;
    address constant M_C1_SMALL = 0x8C415331761063E5D6b1c8E700f996b13603Fc2E;
    address constant M_C2_OETHV2 = 0x795dCD51EaC6eb3123b7a4a1f906992EAA54Cb0e;
    address constant M_C2_EZETH = 0x4991b902F397dC16b0BBd21b0057a20b4B357AE2;
    address constant M_C2_SMALL = 0xB51b76C73fB24f472E0dd63Bb8195bD2170Bc65d;
    address constant M_C3_OETHV2 = 0xAFAbd582E82042f4A8574f75c36409abEa916Ac5;
    address constant M_C3_WRSETH = 0x9bbbA6322Fe5F3968C1F27C8B860727d683194C8;
    address constant M_C3_SMALL = 0xD55634a79E571dc4C7CDD2F2C0a5857bf7a8a782;
    address constant M_C3_WEETH = 0xfB661cdcfCB62b4ed7bBEf6f70068863E213Cb6B;
    address constant M_C3_DETH = 0xa3135b76c28b3971B703a5e6CD451531b187Eb5A;
    address constant M_C3_DUSD = 0x4ADF85E2e760c9211894482DF74BA535BCae50A4;
    address constant M_C3_USDB = 0x3a61f4bF054cdFaC3a3436A21c4463C6D85C2408;
    address constant M_C3_USDE = 0x7732e29e35e8A8b26E7f026c0865C7c2d88CF853;
    address constant M_C3_RESC = 0x586aBb06179535De9eb6c6D968a355128dD74511;
    address constant M_C4_OETHV2 = 0x530a8D3fdf61112f8a879d753Fe02E9E37EC36Aa;
    address constant M_C4_WEETH = 0xE9391d8E1D5C970F7648852ffEda1A9F42833857;
    address constant M_C4_DETH = 0x7878C119F08052789F84CF4fDD3C3642fa291257;

    address constant PYTH = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    bytes32 constant ETH_USD = 0xfF61491a931112DDF1Bd8147cd1b641375F79f5825126d665480874634fd0ace;

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("BLAST_RPC_URL", string("https://81457.rpc.thirdweb.com"));
        forkBlock = vm.createSelectFork(rpc);
    }

    function _markets() internal pure returns (address[21] memory m) {
        m = [M_C1_OETH1, M_C1_EMPTY, M_C1_USDB, M_C1_OETH2, M_C1_OETHV2, M_C1_SMALL,
             M_C2_OETHV2, M_C2_EZETH, M_C2_SMALL, M_C3_OETHV2, M_C3_WRSETH, M_C3_SMALL,
             M_C3_WEETH, M_C3_DETH, M_C3_DUSD, M_C3_USDB, M_C3_USDE, M_C3_RESC,
             M_C4_OETHV2, M_C4_WEETH, M_C4_DETH];
    }

    function _comptrollers() internal pure returns (address[4] memory c) {
        c = [C1, C2, C3, C4];
    }

    /// 00 — live snapshot of all markets and comptrollers.
    function test_00_live_state() public {
        emit log_named_uint("fork block", forkBlock);
        for (uint256 i = 0; i < 4; i++) {
            IComptroller c = IComptroller(_comptrollers()[i]);
            emit log_named_address("comptroller", address(c));
            emit log_named_address("  admin", c.admin());
            emit log_named_address("  oracle", c.oracle());
            emit log_named_uint("  closeFactor", c.closeFactorMantissa());
            emit log_named_uint("  liqIncentive", c.liquidationIncentiveMantissa());
        }
        address[21] memory mks = _markets();
        for (uint256 i = 0; i < mks.length; i++) {
            address m = mks[i];
            emit log_named_address("market", m);
            try ICErc20(m).getCash() returns (uint256 v) { emit log_named_uint("  cash", v); } catch { emit log("  cash: revert"); }
            try ICErc20(m).totalBorrows() returns (uint256 v) { emit log_named_uint("  borrows", v); } catch { emit log("  borrows: revert"); }
            try ICErc20(m).totalSupply() returns (uint256 v) { emit log_named_uint("  supply", v); } catch { emit log("  supply: revert"); }
            try ICErc20(m).totalReserves() returns (uint256 v) { emit log_named_uint("  reserves", v); } catch { emit log("  reserves: revert"); }
            try ICErc20(m).exchangeRateStored() returns (uint256 v) { emit log_named_uint("  exchangeRate", v); } catch { emit log("  exchangeRate: revert"); }
        }
    }

    /// 01 — oracle price readability per market (stale feeds revert).
    function test_01_oracle_prices() public {
        address[4] memory cs = _comptrollers();
        address[21] memory mks = _markets();
        for (uint256 i = 0; i < 4; i++) {
            IOracle o = IOracle(IComptroller(cs[i]).oracle());
            for (uint256 j = 0; j < mks.length; j++) {
                // only markets belonging to this comptroller
                try ICErc20(mks[j]).comptroller() returns (address mc) {
                    if (mc != cs[i]) continue;
                } catch {
                    continue;
                }
                try o.getUnderlyingPrice(mks[j]) returns (uint256 p) {
                    emit log_named_uint(string(abi.encodePacked("price ", vm.toString(mks[j]))), p);
                } catch (bytes memory err) {
                    emit log_named_bytes(string(abi.encodePacked("price-revert ", vm.toString(mks[j]))), err);
                }
            }
        }
    }

    /// 02 — Pyth staleness and refreshability (needs PYTH_VAA_ETH from Hermes, fetched in CI).
    function test_02_pyth_refresh() public {
        IPyth pyth = IPyth(PYTH);
        emit log_named_uint("validTimePeriod", pyth.getValidTimePeriod());

        try pyth.getPriceUnsafe(ETH_USD) returns (IPyth.Price memory p) {
            emit log_named_int("stored ETH price", p.price);
            emit log_named_int("stored expo", p.expo);
            emit log_named_uint("stored publishTime", p.publishTime);
            emit log_named_uint("age_s", block.timestamp > p.publishTime ? block.timestamp - p.publishTime : 0);
        } catch (bytes memory e) {
            emit log_named_bytes("getPriceUnsafe reverted", e);
        }

        try pyth.getPriceNoOlderThan(ETH_USD, 3600) returns (IPyth.Price memory p2) {
            emit log_named_int("fresh-enough ETH price", p2.price);
        } catch (bytes memory e) {
            emit log_named_bytes("getPriceNoOlderThan(3600) reverted", e);
        }

        string memory vaaHex = vm.envOr("PYTH_VAA_ETH", string(""));
        if (bytes(vaaHex).length == 0) {
            emit log("no PYTH_VAA_ETH provided; skipping update test");
            return;
        }
        bytes memory vaa = vm.parseBytes(vaaHex);
        bytes[] memory vaas = new bytes[](1);
        vaas[0] = vaa;
        uint256 fee = pyth.getUpdateFee(vaas);
        emit log_named_uint("update fee", fee);
        vm.deal(address(this), 1 ether);
        try pyth.updatePriceFeeds{value: fee}(vaas) {
            emit log("updatePriceFeeds OK");
        } catch (bytes memory e) {
            emit log_named_bytes("updatePriceFeeds reverted", e);
            return;
        }
        try pyth.getPriceNoOlderThan(ETH_USD, 3600) returns (IPyth.Price memory p3) {
            emit log_named_int("post-update ETH price", p3.price);
            emit log_named_uint("post-update publishTime", p3.publishTime);
        } catch (bytes memory e) {
            emit log_named_bytes("post-update freshness still failing", e);
        }
        // and the protocol oracle should now return a price
        try IOracle(IComptroller(C1).oracle()).getUnderlyingPrice(M_C1_OETH2) returns (uint256 p4) {
            emit log_named_uint("c1 oETH oracle price after refresh", p4);
        } catch (bytes memory e) {
            emit log_named_bytes("c1 oracle still failing", e);
        }
    }

    /// 03 — admin functions must revert for a fresh unprivileged address.
    function test_03_admin_gates() public {
        address fresh = makeAddr("fresh");
        vm.startPrank(fresh);
        bool ok = true;
        address oracleBefore = IComptroller(C1).oracle();
        ok = _mustFail(C1, abi.encodeWithSignature("_setPriceOracle(address)", fresh)) && ok;
        assertEq(IComptroller(C1).oracle(), oracleBefore, "oracle changed by non-admin");
        ok = _mustFail(C1, abi.encodeWithSignature("_setCloseFactor(uint256)", uint256(1e18))) && ok;
        ok = _mustFail(C1, abi.encodeWithSignature("_become(address)", C1)) && ok;
        ok = _mustFail(M_C1_USDB, abi.encodeWithSignature("_reduceReserves(uint256)", uint256(1))) && ok;
        ok = _mustFail(M_C1_USDB, abi.encodeWithSignature("sweepToken(address)", M_C1_USDB)) && ok;
        ok = _mustFail(M_C1_OETH2, abi.encodeWithSignature("_blastClaimYield(address)", fresh)) && ok;
        ok = _mustFail(C3, abi.encodeWithSignature("_setMintPaused(address,bool)", M_C3_RESC, false)) && ok;
        ok = _mustFail(M_C3_DETH, abi.encodeWithSignature("_blastClaimYield(address)", fresh)) && ok;
        vm.stopPrank();
        emit log_named_string("all admin gates revert for fresh address", ok ? "YES" : "NO - SEE FAILURES");
        assertTrue(ok, "an admin gate did not revert");
    }

    function _mustRevert(address target, bytes memory data) internal returns (bool) {
        (bool success, bytes memory ret) = target.call(data);
        if (success) {
            emit log_named_bytes("NO-REVERT", data);
            return false;
        }
        emit log_named_bytes("revert ok", data);
        ret;
        return true;
    }

    /// Compound admin functions may revert OR return a non-zero error code; both mean "gated".
    function _mustFail(address target, bytes memory data) internal returns (bool) {
        (bool success, bytes memory ret) = target.call(data);
        if (!success) {
            emit log_named_bytes("revert ok", data);
            return true;
        }
        if (ret.length >= 32) {
            uint256 code;
            assembly { code := mload(add(ret, 32)) }
            if (code != 0) {
                emit log_named_uint("fail-code ok", code);
                return true;
            }
        }
        emit log_named_bytes("NO-FAIL", data);
        return false;
    }

    /// 04 — donation attack check: markets with zero supply but positive cash.
    function test_04_donation_check() public {
        address[21] memory mks = _markets();
        uint256 candidates;
        for (uint256 i = 0; i < mks.length; i++) {
            address m = mks[i];
            uint256 sup;
            uint256 cash;
            try ICErc20(m).totalSupply() returns (uint256 v) { sup = v; } catch { continue; }
            try ICErc20(m).getCash() returns (uint256 v) { cash = v; } catch { continue; }
            if (sup == 0 && cash > 0) {
                candidates++;
                emit log_named_address("DONATION-CANDIDATE", m);
                emit log_named_uint("  cash", cash);
            }
        }
        emit log_named_uint("donation candidates", candidates);
    }

    /// 05 — CEther donation check (native ETH): zero supply but balance.
    function test_05_ether_donation_check() public {
        address[6] memory ethers = [M_C1_OETH1, M_C1_OETH2, M_C1_OETHV2, M_C2_OETHV2, M_C3_OETHV2, M_C4_OETHV2];
        for (uint256 i = 0; i < ethers.length; i++) {
            uint256 sup = ICEther(ethers[i]).totalSupply();
            uint256 cash = ICEther(ethers[i]).getCash();
            emit log_named_address("oEther", ethers[i]);
            emit log_named_uint("  supply", sup);
            emit log_named_uint("  cash(wei)", cash);
            if (sup == 0 && cash > 0) {
                // first-depositor capture path
                vm.deal(address(this), 1);
                uint256 before = address(this).balance;
                ICEther(ethers[i]).mint{value: 1}();
                uint256 shares = ICEther(ethers[i]).balanceOf(address(this));
                ICEther(ethers[i]).redeem(shares);
                uint256 afterBal = address(this).balance;
                emit log_named_uint("  donation profit wei", afterBal > before ? afterBal - before : 0);
            }
        }
    }

    /// 06 — borrow path with fresh collateral (fair-value check; needs oracle working).
    function test_06_borrow_probe() public {
        address attacker = makeAddr("attacker");
        vm.deal(attacker, 100 ether);
        vm.startPrank(attacker);
        // try to borrow ETH from c1 oETH market with no collateral -> must revert
        try ICEther(M_C1_OETH2).borrow(1) {
            emit log("borrow without collateral SUCCEEDED (!!)");
        } catch (bytes memory e) {
            emit log_named_bytes("borrow without collateral reverted", e);
        }
        vm.stopPrank();
    }

    /// 07 — liquidation probe for addresses provided via env BORROWERS (csv of "comptroller:borrower").
    function test_07_liquidation_probe() public {
        string memory csv = vm.envOr("BORROWERS", string(""));
        if (bytes(csv).length == 0) {
            emit log("no BORROWERS env; skipping");
            return;
        }
        string[] memory parts = _split(csv, ",");
        for (uint256 k = 0; k < parts.length; k++) {
            bytes memory b = bytes(parts[k]);
            uint256 colon = b.length;
            for (uint256 j = 0; j < b.length; j++) {
                if (b[j] == ":") { colon = j; break; }
            }
            if (colon == b.length) continue;
            address comp = _parseAddr(b, 0, colon);
            address bor = _parseAddr(b, colon + 1, b.length);
            try IComptroller(comp).getAccountLiquidity(bor) returns (uint256 err, uint256 liquidity, uint256 shortfall) {
                emit log_named_address("account", bor);
                emit log_named_uint("  err", err);
                emit log_named_uint("  liquidity", liquidity);
                emit log_named_uint("  shortfall", shortfall);
            } catch (bytes memory e) {
                emit log_named_bytes(string(abi.encodePacked("liq-revert ", vm.toString(bor))), e);
            }
        }
    }

    /// Refresh Pyth price feeds from env VAAs; returns count pushed.
    function _refreshPyth() internal returns (uint256) {
        string[4] memory names = ["PYTH_VAA_ETH", "PYTH_VAA_USDC", "PYTH_VAA_WEETH", "PYTH_VAA_BTC"];
        bytes[] memory vaas = new bytes[](4);
        uint256 n;
        for (uint256 i = 0; i < 4; i++) {
            string memory h = vm.envOr(names[i], string(""));
            if (bytes(h).length > 2) {
                vaas[n] = vm.parseBytes(h);
                n++;
            }
        }
        if (n == 0) return 0;
        bytes[] memory use = new bytes[](n);
        for (uint256 i = 0; i < n; i++) use[i] = vaas[i];
        IPyth pyth = IPyth(PYTH);
        uint256 fee = pyth.getUpdateFee(use);
        vm.deal(address(this), 1 ether);
        try pyth.updatePriceFeeds{value: fee}(use) {
            emit log_named_uint("pyth feeds refreshed", n);
        } catch (bytes memory e) {
            emit log_named_bytes("pyth refresh failed", e);
            return 0;
        }
        return n;
    }

    /// 08 — targeted liquidation probes for the accounts found by the off-chain scan
    ///      (analysis/positions2.py over 4,042 candidates; 65 underwater, 1 with
    ///      profitable collateral). A full on-chain scan needs a stable RPC and is
    ///      done off-chain instead.
    function test_08_targeted_liquidation() public {
        address[4] memory probes = [
            0xD89b1b886719fB9f2168aEa44d719e9B81cD78DD, // underwater $1,602; $250 USDe collateral
            0x34bbf3b83F82342F16AC3C5d7D3256F9BE9441bc, // underwater $7.2M; collateral DETH (rho~0)
            0xB7eF760F30d139097bA547bD6f0dfaeCbf148452, // underwater $401; collateral rho~0
            0x6315F65843e7582508e4F0aAC20a7203E7B09F02  // team account, deep bad debt
        ];
        for (uint256 i = 0; i < probes.length; i++) {
            try IComptroller(C3).getAccountLiquidity(probes[i]) returns (uint256 err, uint256 liq, uint256 shortfall) {
                emit log_named_address("account", probes[i]);
                emit log_named_uint("  err", err);
                emit log_named_uint("  liquidity", liq);
                emit log_named_uint("  shortfall", shortfall);
            } catch (bytes memory e) {
                emit log_named_bytes(string(abi.encodePacked("liq-revert ", vm.toString(probes[i]))), e);
            }
        }
    }

    function _split(string memory s, string memory sep) internal pure returns (string[] memory) {
        bytes memory b = bytes(s);
        bytes memory sp = bytes(sep);
        uint256 count = 1;
        for (uint256 i = 0; i + sp.length <= b.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < sp.length; j++) {
                if (b[i + j] != sp[j]) { hit = false; break; }
            }
            if (hit) count++;
        }
        string[] memory out = new string[](count);
        uint256 start = 0;
        uint256 idx = 0;
        for (uint256 i = 0; i + sp.length <= b.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < sp.length; j++) {
                if (b[i + j] != sp[j]) { hit = false; break; }
            }
            if (hit) {
                out[idx++] = _substr(b, start, i);
                start = i + sp.length;
                i += sp.length - 1;
            }
        }
        out[idx] = _substr(b, start, b.length);
        return out;
    }

    function _substr(bytes memory b, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory o = new bytes(end - start);
        for (uint256 i = start; i < end; i++) o[i - start] = b[i];
        return string(o);
    }

    function _parseAddr(bytes memory b, uint256 start, uint256 end) internal pure returns (address a) {
        // skip 0x prefix
        if (end - start >= 2 && b[start] == 0x30 && (b[start + 1] == 0x78 || b[start + 1] == 0x58)) start += 2;
        uint256 acc;
        for (uint256 i = start; i < end; i++) {
            uint8 c = uint8(b[i]);
            uint256 v;
            if (c >= 48 && c <= 57) v = c - 48;
            else if (c >= 97 && c <= 102) v = c - 87;
            else if (c >= 65 && c <= 70) v = c - 55;
            else continue;
            acc = acc * 16 + v;
        }
        a = address(uint160(acc));
    }
}
