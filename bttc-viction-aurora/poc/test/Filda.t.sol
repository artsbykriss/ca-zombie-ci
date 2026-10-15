// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface ICErc20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function getCash() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function getAccountSnapshot(address) external view returns (uint256, uint256, uint256, uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function approve(address, uint256) external returns (bool);
    function underlying() external view returns (address);
}

interface IComptroller {
    function getAllMarkets() external view returns (address[] memory);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function liquidateCalculateSeizeTokens(address, address, uint256) external view returns (uint256, uint256);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function oracle() external view returns (address);
    function mintGuardianPaused(address) external view returns (bool);
    function borrowGuardianPaused(address) external view returns (bool);
}

/// @title FilDA (BTTC) — adversarial fork tests
/// @notice Live E-U: permissionless liquidation of 5 underwater accounts (~$6.21).
///         Empty-market/donation hypothesis closed (internalCash accounting).
contract FildaTest is Test {
    address constant COMPTROLLER = 0xE52792E024697A6be770e5d6F1C455550265B2CD;
    address constant fBTT = 0x65019969b8308F062548d25B1483adD15c582d5B;
    address constant fUSDT = 0x590052BE9Ad26e51f2F1382d29338FCc4c04bfBf;
    address constant fTRX = 0x1B596E1FDd1d4895CF30F034eF1B7B6A8942136E;
    address constant fUSDC = 0xAeE67519049092AB91EFD033f7d350D62b9f166B;
    address constant fETH = 0xa258bfFD5F6814303a718d2B9D34B40E14C66289;
    address constant USDC = 0x935faA2FCec6Ab81265B301a30467Bbc804b43d3;
    address constant USDT = 0xdB28719F7f938507dBfe4f0eAe55668903D34a15;
    address constant VICTIM1 = 0x0dFd9fC5a3ABEfC047168830c10111bcA895305f;
    address constant VICTIM2 = 0x4e92B67c1A0dc26f346E822dDF0D7395427285B6;
    address constant ATTACKER = address(0xA77ACCE7);

    bool forked;

    function setUp() public {
        string[2] memory urls = [
            vm.envOr("BTTC_RPC_URL", string("https://rpc.bt.io")),
            "https://rpc.bittorrentchain.io"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) {
                forked = true;
                break;
            } catch {}
        }
    }

    modifier onlyFork() {
        if (!forked) {
            console2.log("SKIP: bttc fork unavailable");
            return;
        }
        _;
    }

    function test_01_no_empty_market() public onlyFork {
        address[] memory mkts = IComptroller(COMPTROLLER).getAllMarkets();
        assertEq(mkts.length, 5, "five markets");
        for (uint256 i = 0; i < mkts.length; i++) {
            uint256 ts = ICErc20(mkts[i]).totalSupply();
            console2.log(mkts[i], ts);
            assertGt(ts, 0, "no market has zero supply (donation path closed)");
        }
        assertEq(IComptroller(COMPTROLLER).closeFactorMantissa(), 0.5e18, "close factor");
        assertEq(IComptroller(COMPTROLLER).liquidationIncentiveMantissa(), 1.15e18, "liq incentive");
        // nothing paused
        for (uint256 i = 0; i < mkts.length; i++) {
            assertFalse(IComptroller(COMPTROLLER).mintGuardianPaused(mkts[i]), "mint open");
            assertFalse(IComptroller(COMPTROLLER).borrowGuardianPaused(mkts[i]), "borrow open");
        }
    }

    function test_02_donation_does_not_move_exchange_rate() public onlyFork {
        uint256 erBefore = ICErc20(fUSDC).exchangeRateStored();
        // donate 1,000 USDC straight to the market
        deal(USDC, address(this), 1_000e6);
        ICErc20_erc20(USDC).transfer(fUSDC, 1_000e6);
        uint256 erAfter = ICErc20(fUSDC).exchangeRateStored();
        assertEq(erAfter, erBefore, "internalCash accounting: donation cannot inflate rate");
    }

    function test_03_liquidation_is_profitable_and_permissionless() public onlyFork {
        // sanity: victim is in shortfall at protocol oracle prices
        (uint256 err, uint256 liq, uint256 shortfall) = IComptroller(COMPTROLLER).getAccountLiquidity(VICTIM1);
        assertEq(err, 0, "no comptroller error");
        assertEq(liq, 0, "no excess liquidity");
        assertGt(shortfall, 0, "account in shortfall");

        (uint256 e0, uint256 cUSDT, , ) = ICErc20(fUSDT).getAccountSnapshot(VICTIM1);
        (uint256 e1, uint256 cETH, , ) = ICErc20(fETH).getAccountSnapshot(VICTIM1);
        assertEq(e0 + e1, 0, "snapshots ok");
        assertGt(cUSDT, 0, "fUSDT collateral");
        assertGt(cETH, 0, "fETH collateral");

        // leg 1: repay USDC -> seize fUSDT (all)
        uint256 repay1 = 17_370_200; // 17.3702 USDC (close factor 0.5 of 58.45 debt capped by 1.15 incentive)
        (uint256 qerr, uint256 seize1) = IComptroller(COMPTROLLER).liquidateCalculateSeizeTokens(fUSDC, fUSDT, repay1);
        assertEq(qerr, 0, "seize quote ok");
        assertLe(seize1, cUSDT, "seize within victim balance");
        console2.log("leg1 repay(USDC 6d):", repay1);
        console2.log("leg1 seize(fUSDT wei):", seize1);

        deal(USDC, ATTACKER, 40e6);
        vm.startPrank(ATTACKER);
        ICErc20_erc20(USDC).approve(fUSDC, type(uint256).max);
        uint256 res = ICErc20(fUSDC).liquidateBorrow(VICTIM1, repay1, fUSDT);
        assertEq(res, 0, "liquidation leg1 succeeds");
        uint256 gotCTokens = ICErc20(fUSDT).balanceOf(ATTACKER);
        // protocol's safety-vault cut makes the credited amount < the raw quote
        assertGt(gotCTokens, 0, "seized tokens credited");
        assertLe(gotCTokens, seize1, "credited <= quote (safety vault cut)");
        console2.log("credited fUSDT wei:", gotCTokens);
        // redeem seized collateral for underlying
        uint256 usdtBefore = ICErc20_erc20(USDT).balanceOf(ATTACKER);
        ICErc20(fUSDT).redeem(gotCTokens);
        uint256 usdtGot = ICErc20_erc20(USDT).balanceOf(ATTACKER) - usdtBefore;
        vm.stopPrank();
        console2.log("redeemed USDT (6d):", usdtGot);
        console2.log("leg1 net (USDT 6d):", int256(usdtGot) - int256(repay1));
        assertGt(usdtGot, repay1, "net positive: seized value > repaid debt");

        // leg 2: repay USDC -> seize fETH (scale repay so the seize fits the remaining collateral)
        uint256 repay2 = 16_234_400;
        (uint256 qerr2, uint256 seize2) = IComptroller(COMPTROLLER).liquidateCalculateSeizeTokens(fUSDC, fETH, repay2);
        assertEq(qerr2, 0, "seize quote 2 ok");
        if (seize2 > cETH) {
            repay2 = repay2 * cETH / seize2 * 99 / 100;
            (qerr2, seize2) = IComptroller(COMPTROLLER).liquidateCalculateSeizeTokens(fUSDC, fETH, repay2);
            assertEq(qerr2, 0, "rescaled quote ok");
        }
        assertLe(seize2, cETH, "seize2 within balance");
        vm.startPrank(ATTACKER);
        res = ICErc20(fUSDC).liquidateBorrow(VICTIM1, repay2, fETH);
        assertEq(res, 0, "liquidation leg2 succeeds");
        uint256 gotEthCT = ICErc20(fETH).balanceOf(ATTACKER);
        assertGt(gotEthCT, 0, "fETH seized");
        assertLe(gotEthCT, seize2, "leg2 credited <= quote");
        console2.log("leg2 credited fETH wei:", gotEthCT);
        vm.stopPrank();
        console2.log("leg2 repay(USDC 6d):", repay2);
        console2.log("leg2 seize(fETH wei):", seize2);

        // remaining position after two legs (opportunity partially consumed)
        (, uint256 liq2, uint256 short2) = IComptroller(COMPTROLLER).getAccountLiquidity(VICTIM1);
        console2.log("post-liq liquidity/shortfall:", liq2, short2);
        assertTrue(liq2 > 0 || short2 > 0, "position accounted");
    }

    function test_04_second_victim_and_healthy_control() public onlyFork {
        // victim2: repay USDC -> seize all fUSDT
        (, uint256 liqV2, uint256 shortV2) = IComptroller(COMPTROLLER).getAccountLiquidity(VICTIM2);
        assertGt(shortV2, 0, "victim2 in shortfall");
        assertEq(liqV2, 0, "");
        uint256 repay = 7_373_400;
        (uint256 qerr, uint256 seize) = IComptroller(COMPTROLLER).liquidateCalculateSeizeTokens(fUSDC, fUSDT, repay);
        assertEq(qerr, 0, "quote ok");
        assertGt(seize, 0, "positive seize");
        console2.log("victim2 repay:", repay, "seize:", seize);

        // healthy control: random address has no shortfall
        (, , uint256 s3) = IComptroller(COMPTROLLER).getAccountLiquidity(address(0xBEEF));
        assertEq(s3, 0, "healthy address not liquidatable");
    }
}

interface ICErc20_erc20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
