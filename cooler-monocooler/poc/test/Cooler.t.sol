// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

interface IOracle {
    function currentLtvs() external view returns (uint96, uint96);
    function currentOriginationLtv() external view returns (uint96);
    function currentLiquidationLtv() external view returns (uint96);
    function originationLtvData()
        external
        view
        returns (uint96 startingValue, uint40 startTime, uint96 targetValue, uint40 targetTime, uint96 slope);
    function maxOriginationLtvDelta() external view returns (uint96);
    function minOriginationLtvTargetTimeDelta() external view returns (uint32);
    function maxOriginationLtvRateOfChange() external view returns (uint96);
    function liquidationLtvPremiumBps() external view returns (uint16);
}

interface IMonoCooler {
    struct DelegationRequest {
        address delegate;
        int256 amount;
    }
    struct LiquidationStatus {
        uint128 collateral;
        uint128 currentDebt;
        uint128 currentLtv;
        bool exceededLiquidationLtv;
        bool exceededMaxOriginationLtv;
        uint128 currentIncentive;
    }

    function addCollateral(uint128, address, DelegationRequest[] calldata) external;
    function borrow(uint128, address, address) external returns (uint128);
    function repay(uint128, address) external returns (uint128);
    function withdrawCollateral(uint128, address, address, DelegationRequest[] calldata)
        external
        returns (uint128);
    function totalCollateral() external view returns (uint128);
    function totalDebt() external view returns (uint128);
    function interestRateWad() external view returns (uint96);
    function borrowsPaused() external view returns (bool);
    function liquidationsPaused() external view returns (bool);
    function loanToValues() external view returns (uint96, uint96);
    function minDebtRequired() external view returns (uint256);
    function ltvOracle() external view returns (address);
    function treasuryBorrower() external view returns (address);
    function computeLiquidity(address[] calldata) external view returns (LiquidationStatus[] memory);
    function accountState(address) external view returns (uint128, uint128, uint256);
}

interface ISUSDS {
    function balanceOf(address) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
}

/// @title Cooler MonoCooler — live-state / extraction-path PoC
/// @notice Read-only fork verification. No transaction is signed or sent to a real chain.
contract CoolerPoC is Test {
    address constant MONO = 0xdb591Ea2e5Db886dA872654D58f6cc584b68e7cC;
    address constant ORACLE = 0x9ee9f0c2e91E4f6B195B988a9e6e19efcf91e8dc;
    address constant GOHM = 0x0ab87046fBb341D058F17CBC4c1133F25a20a52f;
    address constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address constant TB = 0xD58d7406E9CE34c90cf849Fc3eed3764EB3779B0;
    address constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address constant TRSRY = 0xa8687A15D4BE32CC8F0a8a7B9704a4C3993D9613;

    /// @dev pin: state read 2026-10-21 (block 26,241,769)
    uint256 constant FORK_BLOCK = 26_241_769;

    IMonoCooler mono = IMonoCooler(MONO);
    IOracle oracle = IOracle(ORACLE);

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(url, FORK_BLOCK);
    }

    // ------------------------------------------------------------------ //
    // 1. live state: the oracle is a fixed, up-only USDS/gOHM price
    // ------------------------------------------------------------------ //
    function test_live_oracle_and_book() public view {
        (uint96 oltv, uint96 lltv) = oracle.currentLtvs();
        (uint96 mOltv, uint96 mLltv) = mono.loanToValues();
        (, , uint96 target, uint40 targetTime, uint96 slope) = oracle.originationLtvData();

        console2.log("block.timestamp     ", block.timestamp);
        console2.log("origination LTV     ", uint256(oltv) / 1e18);
        console2.log("liquidation LTV     ", uint256(lltv) / 1e18);
        console2.log("loanToValues()      ", uint256(mOltv) / 1e18);
        console2.log("target OLTV         ", uint256(target) / 1e18);
        console2.log("target time         ", targetTime);
        console2.log("slope / day         ", uint256(slope) * 86400 / 1e18);
        console2.log("totalCollateral gOHM", mono.totalCollateral() / 1e18);
        console2.log("totalDebt USDS      ", mono.totalDebt() / 1e18);
        console2.log("interest rate /yr % ", uint256(mono.interestRateWad()) / 1e16);
        console2.log("borrowsPaused       ", mono.borrowsPaused());
        console2.log("liquidationsPaused  ", mono.liquidationsPaused());
        console2.log("treasury sUSDS      ", ISUSDS(SUSDS).balanceOf(TRSRY));
        console2.log("sUSDS -> USDS       ", ISUSDS(SUSDS).convertToAssets(ISUSDS(SUSDS).balanceOf(TRSRY)));

        assertEq(oltv, 3119.289005484298284112e18, "OLTV changed");
        assertEq(lltv, 3150.481895539141266953e18, "LLTV changed");
        assertFalse(mono.borrowsPaused());
        assertFalse(mono.liquidationsPaused());
        assertEq(mono.totalCollateral(), 42058.343233953062415086e18);
        assertEq(mono.totalDebt(), 128971024.878805048809040285e18);
    }

    // ------------------------------------------------------------------ //
    // 2. the borrow path is live; today it is NEGATIVE carry
    //    attacker buys gOHM at market, deposits, borrows 100% of oracle
    // ------------------------------------------------------------------ //
    function test_borrow_max_is_unprofitable_at_todays_price() public {
        uint128 collateral = 10e18;
        uint256 gohmMarketUsd = 5337.300530479948e18; // DefiLlama, ts 1792595355 (2026-10-21)

        uint256 collateralUsd = (uint256(collateral) * gohmMarketUsd) / 1e18;

        deal(GOHM, address(this), collateral);
        IERC20(GOHM).approve(MONO, collateral);
        mono.addCollateral(collateral, address(this), new IMonoCooler.DelegationRequest[](0));

        uint128 received = mono.borrow(type(uint128).max, address(this), address(this));

        console2.log("gOHM deposited      ", uint256(collateral) / 1e18);
        console2.log("USDS borrowed       ", uint256(received) / 1e18);
        console2.log("gOHM cost USD       ", collateralUsd / 1e18);
        console2.log("borrow value USD    ", uint256(received) / 1e18);
        console2.log("NET USD (walk away) ", (int256(uint256(received)) - int256(collateralUsd)) / 1e18);

        // max origination = oracle price exactly
        assertEq(received, 31192.890054842982841120e18, "max borrow != OLTV");

        // position is healthy at the oracle -> cannot be liquidated by anyone
        address[] memory one = new address[](1);
        one[0] = address(this);
        IMonoCooler.LiquidationStatus[] memory st = mono.computeLiquidity(one);
        assertFalse(st[0].exceededLiquidationLtv);
        assertEq(st[0].currentLtv, 3119.289005484298284112e18);

        // net is deeply negative at todays market price
        assertLt(int256(uint256(received)), int256(collateralUsd));
    }

    // ------------------------------------------------------------------ //
    // 3. no account on the book is liquidatable (free-collateral bounty
    //    is zero), and none is even above the origination LTV
    // ------------------------------------------------------------------ //
    function test_all_accounts_healthy() public view {
        address[] memory a = new address[](12);
        a[0] = 0xe6C5dc8508939B1c417f83B7fed3149ef22cF3Ff; // 23,417 gOHM / 73.02M debt
        a[1] = 0xaDF9E6C82eD1828db23435FE57f5D42fBcB116dB; //  3,202 gOHM
        a[2] = 0xA701b1315168F2CD290c3F3df3427e88E946f91c; //  1,743
        a[3] = 0x06d486A38E1195fdEE147Fbe309821d72b06f197; //  1,075
        a[4] = 0x8ca3CFf6D91c3e4656E7355649Db2ce4fF0e2572; //  1,038
        a[5] = 0x922d012c7E8fCe3C46ac761179Bdb6d16246782D; //    926
        a[6] = 0xA4B29E4F7e0Dab7925623Aa19259c44082Ada76C; //    913
        a[7] = 0xB4fb31E7B1471A8e52dD1e962A281a732EaD59c1; //    891
        a[8] = 0x4c71dB02aEeB336cBD8f3d2Cc866911F6e2FBD94; //    725
        a[9] = 0xea17e11fa9d3D772EeE6f34A03f0Ef44dB395720; //    504
        a[10] = 0x0430C0cD447397D5411aEA19933165Bd96C46fe3; //   497
        a[11] = 0x03dA5c3B75503A1dDa58E2bd23D4726B5EE8DD26; //   479

        IMonoCooler.LiquidationStatus[] memory st = mono.computeLiquidity(a);
        for (uint256 i; i < a.length; ++i) {
            console2.log(a[i], st[i].currentLtv / 1e18);
            assertFalse(st[i].exceededLiquidationLtv, "account liquidatable");
            assertFalse(st[i].exceededMaxOriginationLtv, "account above OLTV");
        }
    }

    // ------------------------------------------------------------------ //
    // 4. conditional: if gOHM trades below the up-only oracle, a new
    //    borrower mints USDS at the stale price and walks away.
    //    Ceiling = min(treasury sUSDS headroom, DEX depth).
    // ------------------------------------------------------------------ //
    function test_conditional_profit_if_gohm_below_oracle() public view {
        (uint96 oltv, ) = oracle.currentLtvs();
        uint256 capacityUsd = ISUSDS(SUSDS).convertToAssets(ISUSDS(SUSDS).balanceOf(TRSRY)); // borrowing headroom

        console2.log("oracle (USDS/gOHM)  ", uint256(oltv) / 1e18);
        console2.log("borrow headroom USDS", capacityUsd / 1e18);

        uint256[5] memory px = [uint256(3100e18), 2500e18, 2000e18, 1500e18, 1000e18];
        for (uint256 i; i < px.length; ++i) {
            // per-gOHM profit = oracle - market (buy at market, borrow at oracle, abandon)
            uint256 perGohm = uint256(oltv) - px[i];
            // ceiling: all headroom deployed at this price, profit = capacity * (1 - px/oltv)
            uint256 ceiling = (capacityUsd * perGohm) / uint256(oltv);
            console2.log("--- market price    ", px[i] / 1e18);
            console2.log("   profit / gOHM    ", perGohm / 1e18);
            console2.log("   E-U ceiling USD  ", ceiling / 1e18);
        }

        // 41.6% below today's market is the break-even
        assertGt(oltv, 3100e18);
    }

    // ------------------------------------------------------------------ //
    // 5. the free-liquidation bounty is real once an account crosses the
    //    LLTV, but takes ~2 years of 0.5%/yr accrual from a max-LTV open
    // ------------------------------------------------------------------ //
    function test_liquidation_bounty_timeline() public view {
        (uint96 oltv, uint96 lltv) = oracle.currentLtvs();
        uint256 rate = mono.interestRateWad(); // per-second wad
        // years for debt/collateral to grow from OLTV to LLTV
        uint256 ratio = (uint256(lltv) * 1e18) / uint256(oltv);
        // continuous compounding: t = ln(1+g) ~= g / rate   (g = 100 bps)
        uint256 yearsWad = ((ratio - 1e18) * 1e18) / rate;
        console2.log("LLTV/OLTV gap (bps)", (ratio - 1e18) / 1e14);
        console2.log("years to liq (wad)  ", yearsWad);
        console2.log("(from 0.49875%/yr continuous compounding)");
        assertGt(lltv, oltv);
    }
}
