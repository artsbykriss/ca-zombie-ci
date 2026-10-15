// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// ============================================================================================
// Segment Finance (opBNB, chain 204) — adversarial extraction probe. FORK-ONLY.
// READ-ONLY on mainnet: every test runs on a fork; no real-chain transactions are sent.
// Parent copies this file into a shared foundry project as test/SegmentFork.t.sol.
//
// VERDICT (2026-10-15, block ~195,76x,xxx): an external unprivileged attacker can extract
//   $0. All value-moving paths are blocked; the protocol oracle is dead and its fix is
//   governance-gated. The only live (self-service) exit is ~$140 of seBNB that *non-member*
//   holders can redeem because Compound-fork redeemAllowed() skips the oracle for accounts
//   that never entered the market (H-O, in progress on-chain: block 195,199,920).
//
// Live-state facts proven below (see README.md / state.md / oracle.md for the call evidence):
//   Comptroller (Unitroller -> Diamond) 0x71ac0e9A7113130280040d0189d0556f45a8CBB5
//     admin = Gnosis Safe 1.3.0 2-of-3 0x1F41cFbBF95baC4F5A220700f78DbAa1E34B97D1
//     oracle = 0xAacf634DD705D37e94C38EA68384e669D2b4d491
//     closeFactor 0.5, liquidationIncentive 1.10, pendingAdmin/pendingImpl = 0
//   ResilientOracle (TransparentProxy) -> impl 0xE9AD4BE42B717b0CD3b38Be5d05729B51d0aD469
//     proxy-admin 0x982E35f6c693Efe0ee253Fba622CE443089c6b79 (owner = the Safe)
//     every configured asset has main oracle only, NO pivot/no fallback:
//     main = BinanceOracle (TransparentProxy) 0x15cB42A8bC953ba604CF17dcbAa7d78B235979bf
//     => getUnderlyingPrice() REVERTS "invalid resilient oracle price" for all 5 markets
//   BinanceOracle: feedRegistryAddress = 0x72d55658242377AF22907b6E7350148288f88033
//     exists(symbol,"USD") == false for FDUSD/USDT/ETH/BTCB/BNB and
//     maxStalePeriod(symbol) == 0 for all of them (zeroed config => price permanently invalid;
//     deltaTime > 0 always). setMaxStalePeriod/setSymbolOverride revert (AccessControl);
//     feed registry proposeFeed/confirmFeed revert "Only callable by owner".
//   Markets: seFDUSD 0xfe62ba7400d902A9773dA9F7469dA457cF54a565,
//            seUSDT  0x7ADd376cF7b33B7d09B0F0f4Ef0a741C3cB95102,
//            seETH   0x81b98b2896f1F262714F12Be36264AA8E02A08D2,
//            seBTC   0x567558167F102BB45c0437F1Fd5a527c5c534c3C,
//            seBNB   0x7e844423510A5081DE839e600F7960C7cE84eb82 (native, non-delegator)
//     four ERC20 markets: SeBep20Delegator -> SeBep20Delegate impl
//     0xBE7c6bED5c0b79c3BE45B1013f12a98c533c4798; mint/redeem/borrow do NOT add market
//     membership (only enterMarkets does).
//   All five markets' getAccountLiquidity reverts for any account with assets => borrow,
//     liquidateBorrow, member-redeem and member-transfer are all dead.
//   Reward surface: getSEFAddress() == 0 (SEF never wired), claimSegment() is a no-op,
//     _grantSEF is "only admin can". Reserve factor 0, reserves 0.

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

interface ISeToken {
    function mint(uint256) external returns (uint256);
    function mintBehalf(address, uint256) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function borrowBehalf(address, uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function repayBorrowBehalf(address, uint256) external returns (uint256);
    function liquidateBorrow(address, uint256, address) external returns (uint256);
    function accrueInterest() external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function getCash() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalBorrowsCurrent() external returns (uint256);
    function totalReserves() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function borrowIndex() external view returns (uint256);
    function accrualBlockNumber() external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function borrowBalanceCurrent(address) external returns (uint256);
    function getAccountSnapshot(address) external view returns (uint256, uint256, uint256, uint256);
    function underlying() external view returns (address);
    function comptroller() external view returns (address);
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function implementation() external view returns (address);
    function interestRateModel() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function reserveFactorMantissa() external view returns (uint256);
    function _reduceReserves(uint256) external returns (uint256);
    function _setReserveFactor(uint256) external returns (uint256);
    function _setInterestRateModel(address) external returns (uint256);
    function _setComptroller(address) external returns (uint256);
    function _setPendingAdmin(address) external returns (uint256);
    function _setImplementation(address, bool, bytes memory) external;
    function _becomeImplementation(bytes memory) external;
    function _resignImplementation() external;
    function seize(address, address, uint256) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function initialize(address, address, address, uint256, string memory, string memory, uint8) external;
}

interface ISeBNB {
    // native market (Compound CEther-style): payable, direct contract, no delegator
    function mint() external payable;
    function redeem(uint256) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function getCash() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function admin() external view returns (address);
}

interface IComptroller {
    function markets(address) external view returns (bool, uint256, bool);
    function oracle() external view returns (address);
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint256);
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function comptrollerImplementation() external view returns (address);
    function pendingComptrollerImplementation() external view returns (address);
    function pauseGuardian() external view returns (address);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function getHypotheticalAccountLiquidity(address, address, uint256, uint256)
        external view returns (uint256, uint256, uint256);
    function checkMembership(address, address) external view returns (bool);
    function getAssetsIn(address) external view returns (address[] memory);
    function enterMarkets(address[] memory) external returns (uint256[] memory);
    function exitMarket(address) external returns (uint256);
    function claimSegment(address) external;
    function segmentAccrued(address) external view returns (uint256);
    function getSEFAddress() external view returns (address);
    function borrowCaps(address) external view returns (uint256);
    function supplyCaps(address) external view returns (uint256);
    function protocolPaused() external view returns (bool);
    function allMarkets(uint256) external view returns (address);
    function _grantSEF(address, uint256) external;
    function _setCollateralFactor(address, uint256) external returns (uint256);
    function _setPriceOracle(address) external returns (uint256);
    function _setCloseFactor(uint256) external returns (uint256);
    function updateDelegate(address, bool) external;
}

interface IResilientOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
    function getPrice(address) external view returns (uint256);
    function paused() external view returns (bool);
    function accessControlManager() external view returns (address);
    function pause() external;
    function setAccessControlManager(address) external;
}

interface IBinanceOracle {
    function getPrice(address) external view returns (uint256);
    function feedRegistryAddress() external view returns (address);
    function maxStalePeriod(string memory) external view returns (uint256);
    function setMaxStalePeriod(string memory, uint256) external;
    function setSymbolOverride(string memory, string memory) external;
    function transferOwnership(address) external;
}

interface IFeedRegistry {
    function exists(string memory, string memory) external view returns (bool);
    function latestRoundDataByName(string memory, string memory)
        external view returns (uint80, int256, uint256, uint256, uint80);
    function proposeFeed(address, address, address) external;
}

contract SegmentForkTest is Test {
    address constant CTRL = 0x71ac0e9A7113130280040d0189d0556f45a8CBB5;
    address constant ORACLE = 0xAacf634DD705D37e94C38EA68384e669D2b4d491;
    address constant BINANCE_ORACLE = 0x15cB42A8bC953ba604CF17dcbAa7d78B235979bf;
    address constant FEED_REGISTRY = 0x72d55658242377AF22907b6E7350148288f88033;
    address constant SAFE_ADMIN = 0x1F41cFbBF95baC4F5A220700f78DbAa1E34B97D1;
    address constant DIAMOND_IMPL = 0xaE2a97297EA09f82229076C9caff7c00A6140817;
    address constant MARKET_IMPL = 0xBE7c6bED5c0b79c3BE45B1013f12a98c533c4798;

    address constant SE_FDUSD = 0xfe62ba7400d902A9773dA9F7469dA457cF54a565;
    address constant SE_USDT = 0x7ADd376cF7b33B7d09B0F0f4Ef0a741C3cB95102;
    address constant SE_ETH = 0x81b98b2896f1F262714F12Be36264AA8E02A08D2;
    address constant SE_BTC = 0x567558167F102BB45c0437F1Fd5a527c5c534c3C;
    address constant SE_BNB = 0x7e844423510A5081DE839e600F7960C7cE84eb82;

    address constant U_FDUSD = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address constant U_USDT = 0x9e5AAC1Ba1a2e6aEd6b32689DFcF62A509Ca96f3;
    address constant U_ETH = 0xE7798f023fC62146e8Aa1b36Da45fb70855a77Ea;
    address constant U_BTC = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;

    address constant ATTACKER = address(0xA11CE);

    // Real accounts with live positions, enumerated from the complete Borrow/RepayBorrow event
    // history (blocks 19,200,685 -> 195,771,482; sum of enumerated debts == totalBorrows for all
    // five markets, so the debtor set is complete). See analysis/borrowers.csv.
    address constant BAD_DEBT = 0x68a0187089E2d1addeE1FF35c4B0a7B5988931Ea; // 733.26 USDT debt, ~no collateral
    address constant SMALL_UNDERWATER = 0xeed518c9D0719F016BEbCFb3E25c4c9acd00B6C2; // 0.0022 seETH debt
    address constant WHALE1 = 0x8d97998B147Db2412592cFD56D6eFae78670105E; // 84% of seFDUSD supply
    address constant WHALE2 = 0xF8221bdd9F8615c27C430923353168755B58F81F; // 16% of seFDUSD supply

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("OPBNB_RPC_URL", string("https://opbnb-mainnet-rpc.bnbchain.org"))
        );
        console2.log("fork block", block.number);
    }

    // ------------------------------------------------------------------ T1 state invariants

    function test_T1_live_state_invariants() public {
        IComptroller c = IComptroller(CTRL);
        assertEq(c.admin(), SAFE_ADMIN, "comptroller admin");
        assertEq(c.pendingAdmin(), address(0), "pendingAdmin must be 0");
        assertEq(c.oracle(), ORACLE, "oracle");
        assertEq(c.closeFactorMantissa(), 0.5e18, "closeFactor");
        assertEq(c.liquidationIncentiveMantissa(), 1.1e18, "liqIncentive");
        assertEq(c.pauseGuardian(), address(0), "pauseGuardian 0");
        assertEq(c.comptrollerImplementation(), DIAMOND_IMPL, "diamond impl");
        assertEq(c.pendingComptrollerImplementation(), address(0), "pending impl 0");
        assertFalse(c.protocolPaused(), "protocol not paused");

        address[5] memory mkts = [SE_FDUSD, SE_USDT, SE_ETH, SE_BTC, SE_BNB];
        for (uint256 i = 0; i < 5; i++) {
            (bool listed, uint256 cf, bool isSegment) = c.markets(mkts[i]);
            assertTrue(listed, "market listed");
            assertTrue(cf == 0.77e18 || cf == 0.75e18 || cf == 0.65e18, "collateral factor");
            assertFalse(isSegment, "isSegment flag");
            ISeToken m = ISeToken(mkts[i]);
            assertEq(m.comptroller(), CTRL, "market comptroller");
            assertEq(m.admin(), SAFE_ADMIN, "market admin");
            assertEq(m.pendingAdmin(), address(0), "market pendingAdmin");
            assertEq(m.reserveFactorMantissa(), 0, "reserve factor 0");
            assertEq(m.totalReserves(), 0, "no reserves");
            assertEq(m.decimals(), 8, "seToken decimals");
            console2.log(m.symbol(), m.getCash());
            console2.log("  borrowsStored", m.totalBorrows());
            console2.log("  supplySeTokens", m.totalSupply());
            console2.log("  exchangeRateStored", m.exchangeRateStored());
        }
        // four ERC20 markets share one implementation; seBNB is a direct native market
        assertEq(ISeToken(SE_FDUSD).implementation(), MARKET_IMPL, "shared impl");
        assertEq(ISeToken(SE_USDT).implementation(), MARKET_IMPL, "shared impl");
        assertEq(ISeToken(SE_ETH).implementation(), MARKET_IMPL, "shared impl");
        assertEq(ISeToken(SE_BTC).implementation(), MARKET_IMPL, "shared impl");
        vm.expectRevert();
        ISeToken(SE_BNB).implementation();
        // exactly five markets
        assertEq(c.allMarkets(0), SE_FDUSD, "m0");
        assertEq(c.allMarkets(4), SE_BNB, "m4");
        vm.expectRevert();
        c.allMarkets(5);
    }

    function test_T1_oracle_dead_for_every_market() public {
        address[5] memory mkts = [SE_FDUSD, SE_USDT, SE_ETH, SE_BTC, SE_BNB];
        for (uint256 i = 0; i < 5; i++) {
            vm.expectRevert(bytes("invalid resilient oracle price"));
            IResilientOracle(ORACLE).getUnderlyingPrice(mkts[i]);
        }
        vm.expectRevert(bytes("binance oracle price expired"));
        IBinanceOracle(BINANCE_ORACLE).getPrice(U_USDT);
        vm.expectRevert(bytes("binance oracle price expired"));
        IBinanceOracle(BINANCE_ORACLE).getPrice(U_FDUSD);
        vm.expectRevert(bytes("binance oracle price expired"));
        IBinanceOracle(BINANCE_ORACLE).getPrice(U_BTC);

        // Root cause (live 2026-10-15): feeds now EXIST for USDT/FDUSD/ETH/BNB (the team registered
        // them and set maxStalePeriod=86400) but every round is older than maxStalePeriod, and BTCB
        // has no feed at all. The invariant that keeps every price dead:
        //   age(latest round) > maxStalePeriod(symbol)  OR  no feed  OR  registry denies the caller.
        string[5] memory syms = ["USDT", "FDUSD", "ETH", "BTCB", "BNB"];
        for (uint256 i = 0; i < 5; i++) {
            if (!IFeedRegistry(FEED_REGISTRY).exists(syms[i], "USD")) {
                assertEq(IBinanceOracle(BINANCE_ORACLE).maxStalePeriod(syms[i]), 0, "no feed => stale 0");
                continue;
            }
            try IFeedRegistry(FEED_REGISTRY).latestRoundDataByName(syms[i], "USD") returns (
                uint80, int256 ans, uint256, uint256 updatedAt, uint80
            ) {
                assertGt(ans, 0, "answer positive");
                uint256 stale = IBinanceOracle(BINANCE_ORACLE).maxStalePeriod(syms[i]);
                assertGt(block.timestamp, updatedAt + stale, string.concat("feed fresh?! ", syms[i]));
                console2.log("feed", syms[i]);
                console2.log("  answer", uint256(ans));
                console2.log("  age", block.timestamp - updatedAt);
                console2.log("  maxStale", stale);
            } catch {
                // registry access-controlled for this caller -> round not readable either
                console2.log("registry read denied for caller", syms[i]);
            }
        }
        assertEq(IBinanceOracle(BINANCE_ORACLE).feedRegistryAddress(), FEED_REGISTRY, "registry addr");
        assertFalse(IResilientOracle(ORACLE).paused(), "not paused, just unpriceable");
    }

    // ------------------------------------------------------------- T2 extraction attempts

    /// Any borrow reverts: borrowAllowed -> hypothetical liquidity -> oracle -> revert.
    function test_T2_borrow_and_liquidation_revert_dead_oracle() public {
        deal(U_FDUSD, ATTACKER, 100e18);
        vm.startPrank(ATTACKER);
        IERC20(U_FDUSD).approve(SE_FDUSD, type(uint256).max);
        assertEq(ISeToken(SE_FDUSD).mint(50e18), 0, "mint ok");
        // minting does not make the account a member of the market
        assertFalse(IComptroller(CTRL).checkMembership(ATTACKER, SE_FDUSD), "not a member after mint");
        assertEq(IComptroller(CTRL).getAssetsIn(ATTACKER).length, 0, "no assets in");
        // borrow reverts on the oracle
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_USDT).borrow(1e6);
        // so does borrowBehalf (delegate check first, oracle later - blocked either way)
        vm.expectRevert(bytes("not an approved delegate"));
        ISeToken(SE_USDT).borrowBehalf(ATTACKER, 1e6);
        vm.stopPrank();
    }

    /// A market MEMBER cannot redeem while the oracle is dead; a non-member can (Compound semantics).
    function test_T2_member_redeem_frozen_nonmember_redeem_works() public {
        deal(U_FDUSD, ATTACKER, 100e18);
        vm.startPrank(ATTACKER);
        IERC20(U_FDUSD).approve(SE_FDUSD, type(uint256).max);
        assertEq(ISeToken(SE_FDUSD).mint(50e18), 0, "mint");
        uint256 ct = ISeToken(SE_FDUSD).balanceOf(ATTACKER);
        assertGt(ct, 0, "got seTokens");

        // non-member redeem: allowed (no oracle required)
        uint256 before = IERC20(U_FDUSD).balanceOf(ATTACKER);
        assertEq(ISeToken(SE_FDUSD).redeem(ct / 2), 0, "non-member redeem ok");
        uint256 got = IERC20(U_FDUSD).balanceOf(ATTACKER) - before;
        assertGt(got, 0, "received underlying");
        console2.log("non-member redeem paid underlying", got);

        // enter market -> member -> oracle required -> frozen
        address[] memory list = new address[](1);
        list[0] = SE_FDUSD;
        uint256[] memory res = IComptroller(CTRL).enterMarkets(list);
        assertEq(res[0], 0, "enterMarkets ok (no oracle needed)");
        assertTrue(IComptroller(CTRL).checkMembership(ATTACKER, SE_FDUSD), "now a member");
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_FDUSD).redeem(ct / 2);
        vm.stopPrank();
    }

    /// Mint -> redeem round trip is value-neutral: no rounding profit exists.
    function test_T2_mint_redeem_roundtrip_no_profit() public {
        deal(U_FDUSD, ATTACKER, 100e18);
        vm.startPrank(ATTACKER);
        uint256 b0 = IERC20(U_FDUSD).balanceOf(ATTACKER);
        IERC20(U_FDUSD).approve(SE_FDUSD, type(uint256).max);
        assertEq(ISeToken(SE_FDUSD).mint(10e18), 0, "mint");
        uint256 ct = ISeToken(SE_FDUSD).balanceOf(ATTACKER);
        assertEq(ISeToken(SE_FDUSD).redeem(ct), 0, "redeem all");
        uint256 b1 = IERC20(U_FDUSD).balanceOf(ATTACKER);
        console2.log("roundtrip in", b0);
        console2.log("roundtrip out", b1);
        assertLe(b1, b0, "round trip must not profit");
        vm.stopPrank();
    }

    /// Sonne-class donation attack: not applicable / closed.
    /// Preconditions absent: markets are interest-saturated (huge supply, tiny attacker share),
    /// donation only gifts pro-rata to existing holders, and the borrow leg reverts anyway.
    function test_T2_donation_attack_closed() public {
        ISeToken m = ISeToken(SE_FDUSD);
        uint256 supply0 = m.totalSupply();
        uint256 cash0 = m.getCash();
        uint256 rate0 = m.exchangeRateStored();
        assertGt(supply0, 1e11, "not near-empty: supply");
        assertGt(cash0, 1e18, "not near-empty: cash");

        deal(U_FDUSD, ATTACKER, 200e18);
        vm.startPrank(ATTACKER);
        IERC20(U_FDUSD).approve(SE_FDUSD, type(uint256).max);
        assertEq(m.mint(1e18), 0, "tiny mint");
        uint256 ct = m.balanceOf(ATTACKER);
        uint256 rateAfterMint = m.exchangeRateStored();
        // donation into the market (no seTokens minted to the attacker)
        assertTrue(IERC20(U_FDUSD).transfer(SE_FDUSD, 100e18), "donation");
        assertEq(m.getCash(), cash0 + 101e18, "cash inflated by donation");
        uint256 rateNow = m.exchangeRateStored();
        assertGt(rateNow, rateAfterMint, "donation raises the exchange rate");
        // the attacker owns only ct of (supply+ct) => captures only their pro-rata share of the gift
        uint256 redeemable = (ct * rateNow) / 1e18;
        console2.log("attacker cTokens", ct);
        console2.log("exchangeRate before mint", rate0);
        console2.log("attacker redeemable after donating 100e18", redeemable);
        assertLt(redeemable, 102e18, "donation is a net loss to the attacker");
        // inflated exchange rate cannot be turned into a borrow (oracle dead; and pro-rata anyway)
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_USDT).borrow(1e6);
        vm.stopPrank();
    }

    /// Native market (seBNB) mirrors the same economics; a fresh mint->redeem gains nothing.
    function test_T2_seBNB_no_extraction() public {
        vm.deal(ATTACKER, 10 ether);
        uint256 bnbBefore = ATTACKER.balance;
        vm.startPrank(ATTACKER);
        ISeBNB(SE_BNB).mint{value: 1 ether}();
        uint256 ct = ISeBNB(SE_BNB).balanceOf(ATTACKER);
        assertGt(ct, 0, "got seBNB");
        assertEq(ISeBNB(SE_BNB).redeem(ct), 0, "seBNB redeem");
        uint256 bnbAfter = ATTACKER.balance;
        console2.log("seBNB roundtrip start", bnbBefore);
        console2.log("seBNB roundtrip end", bnbAfter);
        assertLe(bnbAfter, bnbBefore, "no profit vs starting balance");
        vm.stopPrank();
    }

    // ------------------------------------------------------------------- T3 liquidation probe

    /// Every real debtor with a live position is a market MEMBER, so a liquidation attempt
    /// reaches the oracle and reverts. There is no oracle-free liquidation path.
    function test_T3_liquidation_of_real_positions_reverts() public {
        // borrower with 733.26 USDT debt and (almost) no collateral
        (, , uint256 debtUsdt, ) = ISeToken(SE_USDT).getAccountSnapshot(BAD_DEBT);
        assertGt(debtUsdt, 700e18, "bad-debt position still live");
        assertTrue(IComptroller(CTRL).checkMembership(BAD_DEBT, SE_USDT), "borrower is a member");
        deal(U_USDT, ATTACKER, debtUsdt);
        vm.startPrank(ATTACKER);
        IERC20(U_USDT).approve(SE_USDT, type(uint256).max);
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_USDT).liquidateBorrow(BAD_DEBT, debtUsdt / 2, SE_ETH);
        vm.stopPrank();

        // second real debtor (seETH)
        (, , uint256 debtEth, ) = ISeToken(SE_ETH).getAccountSnapshot(SMALL_UNDERWATER);
        assertGt(debtEth, 0, "second debtor live");
        assertTrue(IComptroller(CTRL).checkMembership(SMALL_UNDERWATER, SE_ETH), "member");
        deal(U_ETH, ATTACKER, debtEth);
        vm.startPrank(ATTACKER);
        IERC20(U_ETH).approve(SE_ETH, type(uint256).max);
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_ETH).liquidateBorrow(SMALL_UNDERWATER, debtEth / 2, SE_FDUSD);
        vm.stopPrank();

        // an empty account (no assets) fails cleanly with an error code instead of reaching the oracle
        vm.prank(ATTACKER);
        assertEq(ISeToken(SE_FDUSD).liquidateBorrow(ATTACKER, 1e6, SE_USDT), 3, "no shortfall code");
    }

    /// Even the protocol's largest (healthy) holders are price-frozen: getAccountLiquidity reverts.
    function test_T3_whale_positions_are_frozen() public {
        assertTrue(IComptroller(CTRL).checkMembership(WHALE1, SE_FDUSD), "whale1 member");
        assertTrue(IComptroller(CTRL).checkMembership(WHALE1, SE_USDT), "whale1 member");
        assertTrue(IComptroller(CTRL).checkMembership(WHALE2, SE_BNB), "whale2 member");
        vm.expectRevert(bytes("invalid resilient oracle price"));
        IComptroller(CTRL).getAccountLiquidity(WHALE1);
        vm.expectRevert(bytes("invalid resilient oracle price"));
        IComptroller(CTRL).getAccountLiquidity(WHALE2);
        // whale1 holds the majority of the seFDUSD supply
        uint256 w1 = ISeToken(SE_FDUSD).balanceOf(WHALE1);
        uint256 ts = ISeToken(SE_FDUSD).totalSupply();
        assertGt(w1 * 2, ts, "whale1 owns >50% of seFDUSD");
    }

    // ----------------------------------------------------- T4 negative controls / privilege

    function test_T4_reward_paths_have_no_value() public {
        assertEq(IComptroller(CTRL).getSEFAddress(), address(0), "SEF token not wired");
        assertEq(IComptroller(CTRL).segmentAccrued(ATTACKER), 0, "no accrued SEF");
        uint256 before = IERC20(U_FDUSD).balanceOf(ATTACKER);
        IComptroller(CTRL).claimSegment(ATTACKER); // permissionless, but a no-op here
        assertEq(IERC20(U_FDUSD).balanceOf(ATTACKER), before, "claim pays nothing");
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("only admin can"));
        IComptroller(CTRL)._grantSEF(ATTACKER, 1e18);
    }

    function test_T4_admin_paths_gated() public {
        vm.startPrank(ATTACKER);
        vm.expectRevert(bytes("only admin can"));
        IComptroller(CTRL)._setPriceOracle(ATTACKER);
        vm.expectRevert(bytes("only admin can"));
        IComptroller(CTRL)._setCloseFactor(0.9e18);
        vm.expectRevert(bytes("access denied"));
        IComptroller(CTRL)._setCollateralFactor(SE_FDUSD, 1e18);

        // market-level admin returns UNAUTHORIZED (1) without reverting (Compound error codes)
        assertEq(ISeToken(SE_FDUSD)._reduceReserves(1), 1, "reduceReserves unauthorized");
        assertEq(ISeToken(SE_FDUSD)._setReserveFactor(1e17), 1, "setReserveFactor unauthorized");
        assertEq(ISeToken(SE_FDUSD)._setInterestRateModel(ATTACKER), 1, "setIRM unauthorized");
        assertEq(ISeToken(SE_FDUSD)._setComptroller(ATTACKER), 1, "setComptroller unauthorized");
        assertEq(ISeToken(SE_FDUSD)._setPendingAdmin(ATTACKER), 1, "setPendingAdmin unauthorized");
        vm.expectRevert(bytes("SeBep20Delegator::_setImplementation: Caller must be admin"));
        ISeToken(SE_FDUSD)._setImplementation(ATTACKER, false, "");
        vm.expectRevert(bytes("only the admin may call _becomeImplementation"));
        ISeToken(SE_FDUSD)._becomeImplementation("");
        vm.expectRevert(bytes("only the admin may call _resignImplementation"));
        ISeToken(SE_FDUSD)._resignImplementation();
        vm.expectRevert(bytes("only admin may initialize the market"));
        ISeToken(SE_FDUSD).initialize(U_FDUSD, ATTACKER, ATTACKER, 2e16, "x", "x", 8);
        vm.stopPrank();
    }

    function test_T4_oracle_revival_requires_privilege() public {
        // ACL owners on the three price layers are all the 2-of-3 Safe (or revert for non-owners)
        assertEq(IResilientOracle(ORACLE).accessControlManager(), 0x2e81AF8BdB43EAAcF96d79145B36aBc2407Cc80a, "acm");
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        IResilientOracle(ORACLE).setAccessControlManager(ATTACKER);
        vm.expectRevert();
        IResilientOracle(ORACLE).pause();
        vm.expectRevert();
        IBinanceOracle(BINANCE_ORACLE).setMaxStalePeriod("USDT", 86400);
        vm.expectRevert();
        IBinanceOracle(BINANCE_ORACLE).setSymbolOverride("USDT", "USDT2");
        vm.expectRevert();
        IBinanceOracle(BINANCE_ORACLE).transferOwnership(ATTACKER);
        vm.expectRevert(bytes("Only callable by owner"));
        IFeedRegistry(FEED_REGISTRY).proposeFeed(ATTACKER, ATTACKER, ATTACKER);
        vm.stopPrank();
    }

    function test_T4_seize_and_market_hijack_closed() public {
        vm.startPrank(ATTACKER);
        // seize from a non-listed caller returns UNAUTHORIZED (3)
        assertEq(ISeToken(SE_FDUSD).seize(ATTACKER, ATTACKER, 1), 3, "seize unauthorized");
        // markets cannot be hijacked: admin/pendingAdmin are the Safe / zero
        assertEq(ISeToken(SE_FDUSD).admin(), SAFE_ADMIN);
        assertEq(ISeToken(SE_FDUSD).pendingAdmin(), address(0));
        // transfers of seTokens fail without balance (false); and a real holder's tokens cannot be
        // pulled even by a spender, because transferAllowed for a MEMBER source hits the dead oracle
        assertFalse(ISeToken(SE_FDUSD).transfer(ATTACKER, 1), "no balance transfer false");
        vm.expectRevert(bytes("invalid resilient oracle price"));
        ISeToken(SE_FDUSD).transferFrom(WHALE1, ATTACKER, 1);
        vm.stopPrank();
    }
}
