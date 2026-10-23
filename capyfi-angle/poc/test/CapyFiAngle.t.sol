// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function allowance(address, address) external view returns (uint256);
    function symbol() external view returns (string memory);
}

interface ICToken {
    function mint(uint256) external returns (uint256);
    function redeem(uint256) external returns (uint256);
    function redeemUnderlying(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function getCash() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function getAccountSnapshot(address) external view returns (uint256, uint256, uint256, uint256);
    function whitelist() external view returns (address);
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
    function admin() external view returns (address);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
}

interface IComptroller {
    function enterMarkets(address[] calldata) external returns (uint256[] memory);
    function exitMarket(address) external returns (uint256);
    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);
    function markets(address) external view returns (bool, uint256, uint256);
    function getAssetsIn(address) external view returns (address[] memory);
    function oracle() external view returns (address);
    function admin() external view returns (address);
}

interface IWhitelist {
    function isActive() external view returns (bool);
    function isWhitelisted(address) external view returns (bool);
}

interface IOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

/// @title CapyFi access-control angle (Apr-2026 disclosure) — fresh-attacker fork verification
/// @notice READ-ONLY research: fork-only, no mainnet transactions. Verifies whether the
///         disclosed "access-control bypass" lets an unprivileged caller move the ~$5.1M cash.
contract CapyFiAngleTest is Test {
    // ---- live Ethereum mainnet addresses (block pinned in setUp) ----
    address constant UNITROLLER = 0x0b9af1fd73885aD52680A1aeAa7A3f17AC702afA;
    address constant ORACLE     = 0xfbA2712d3bbcf32c6E0178a21955b61FE1FF424A;
    address constant WHITELIST  = 0x302a893B1AC44fed29Cdf3e3a0a083d1Df3ce54E;
    address constant MULTISIG   = 0x6C15e4Bc44CC5674b1d7956D0e9596d2E509eD24;

    address constant caUSDT = 0x0f864A3e50D1070adDE5100fd848446C0567362B;
    address constant caUSDC = 0xc3aD34De18B59A24BD0877e454Fb924181F09C8f;
    address constant caETH  = 0x37DE57183491Fa9745d8Fa5DCd950f0c3a4645c9;
    address constant caWBTC = 0xDa5928d59ECE82808Af2cbBE4f2872FeA8E12CD6;
    address constant caLAC  = 0x0568F6cb5A0E84FACa107D02f81ddEB1803f3B50; // whitelisted mint
    address constant caRPC  = 0xF61159B4a0EE5b1615c9Afb3dA38111043344c32; // whitelisted mint

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant LAC  = 0x0Df3a853e4B604fC2ac0881E9Dc92db27fF7f51b;
    address constant RPC  = 0xEd025A9Fe4b30bcd68460BCA42583090c2266468;

    // known non-whitelisted account that already borrowed restricted LAC/RPC (bad debt)
    address constant BAD_DEBT_ACCT = 0x7CcA923387A3ce8d1f36354F8385aA9045798D51;

    address attacker = address(0xA11CE);
    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        console2.log("fork block", forkBlock);
    }

    // ------------------------------------------------------------------
    // 1. Whitelist state + mint is genuinely gated (no permissionless mint)
    // ------------------------------------------------------------------
    function test_01_whitelist_state_and_mint_gated() public {
        assertEq(ICToken(caLAC).whitelist(), WHITELIST, "caLAC whitelist set");
        assertEq(ICToken(caRPC).whitelist(), WHITELIST, "caRPC whitelist set");
        assertEq(ICToken(caUSDT).whitelist(), address(0), "caUSDT has NO whitelist");
        assertEq(ICToken(caETH).whitelist(), address(0), "caETH has NO whitelist");
        assertTrue(IWhitelist(WHITELIST).isActive(), "whitelist active");
        assertFalse(IWhitelist(WHITELIST).isWhitelisted(attacker), "attacker not whitelisted");

        // attacker tries to mint the restricted markets -> must revert
        vm.startPrank(attacker);
        vm.expectRevert(bytes("WhitelistAccess: not whitelisted"));
        ICToken(caLAC).mint(1e18);
        vm.expectRevert(bytes("WhitelistAccess: not whitelisted"));
        ICToken(caRPC).mint(1e18);
        vm.stopPrank();
        console2.log("PASS: mint on caLAC/caRPC is whitelist-gated for a fresh caller");
    }

    // ------------------------------------------------------------------
    // 2. The actual disclosed "gap": borrow is NOT whitelist-gated (design, I-01)
    // ------------------------------------------------------------------
    function test_02_nonwhitelisted_can_borrow_restricted_asset() public {
        // give attacker USDC, mint caUSDC (no whitelist), enter market, borrow LAC (restricted)
        uint256 amt = 100_000e6;
        deal(USDC, attacker, amt);
        vm.startPrank(attacker);
        IERC20(USDC).approve(caUSDC, type(uint256).max);
        require(ICToken(caUSDC).mint(amt) == 0, "mint caUSDC");
        address[] memory mk = new address[](1);
        mk[0] = caUSDC;
        IComptroller(UNITROLLER).enterMarkets(mk);
        // borrow restricted LAC while NOT whitelisted -> succeeds (this is the disclosed gap)
        uint256 borrowed = ICToken(caLAC).borrow(1000e18);
        vm.stopPrank();
        assertEq(borrowed, 0, "borrow of restricted asset succeeded for non-whitelisted caller");
        assertGt(ICToken(caLAC).borrowBalanceStored(attacker), 0, "debt recorded");
        console2.log("CONFIRMED: non-whitelisted caller CAN borrow restricted caLAC (mint-only whitelist design)");
    }

    // ------------------------------------------------------------------
    // 3. No collateral -> cannot borrow the $5.1M cash
    // ------------------------------------------------------------------
    function test_03_no_collateral_cannot_borrow_cash() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        ICToken(caUSDT).borrow(1_000e6);
        vm.stopPrank();
        console2.log("PASS: zero-collateral caller cannot borrow USDT");
    }

    // ------------------------------------------------------------------
    // 4. Even with collateral, the $5.1M cannot be extracted (over-collateralised)
    // ------------------------------------------------------------------
    function test_04_extraction_is_overcollateralised_no_profit() public {
        uint256 coll = 300_000e6; // $300,000 USDC (keeps borrow < USDT cash)
        deal(USDC, attacker, coll);
        vm.startPrank(attacker);
        IERC20(USDC).approve(caUSDC, type(uint256).max);
        require(ICToken(caUSDC).mint(coll) == 0, "mint");
        address[] memory mk = new address[](1);
        mk[0] = caUSDC;
        IComptroller(UNITROLLER).enterMarkets(mk);

        (, uint256 liquidity, ) = IComptroller(UNITROLLER).getAccountLiquidity(attacker);
        // borrow power is 85% of the USDC collateral; cap the borrow at liquidity
        uint256 maxBorrow = liquidity / 1e12; // oracle USD (1e18) -> USDT 6dp
        // borrow above liquidity must revert
        vm.expectRevert();
        ICToken(caUSDT).borrow(maxBorrow * 2);
        // borrow at/under liquidity succeeds
        uint256 ok = ICToken(caUSDT).borrow(maxBorrow);
        vm.stopPrank();
        assertEq(ok, 0, "borrow within liquidity");
        // Net: attacker locked $300,000 USDC to receive <= $255,000 USDT. No profit.
        console2.log("max borrowable USDT (6dp):", maxBorrow);
        console2.log("collateral locked (USDC 6dp):", coll);
        assertLt(maxBorrow, coll, "borrow power < collateral -> no profit");
        console2.log("PASS: extraction is capped at CF*col (85%) -> net negative for attacker");
    }

    // ------------------------------------------------------------------
    // 5. The only shortfall accounts are uncollectible bad debt (no seizable collateral)
    // ------------------------------------------------------------------
    function test_05_bad_debt_uncollectible() public {
        (uint err, uint liq, uint shortfall) = IComptroller(UNITROLLER).getAccountLiquidity(BAD_DEBT_ACCT);
        assertEq(err, 0, "no error");
        assertEq(liq, 0, "no positive liquidity");
        assertGt(shortfall, 0, "account is undercollateralised");
        console2.log("bad-debt shortfall (1e18 USD):", shortfall);

        // sum the account's seizable collateral across all markets
        address[] memory assets = IComptroller(UNITROLLER).getAssetsIn(BAD_DEBT_ACCT);
        uint256 collUsd = 0;
        for (uint i = 0; i < assets.length; i++) {
            (, uint cBal, , ) = ICToken(assets[i]).getAccountSnapshot(BAD_DEBT_ACCT);
            if (cBal == 0) continue;
            // value of cToken balance in underlying, then USD
            uint256 er = ICToken(assets[i]).exchangeRateStored();
            uint256 und = cBal * er / 1e18;
            uint256 price = IOracle(ORACLE).getUnderlyingPrice(assets[i]); // 1e(36-dec)
            // normalise: usd = und * price / 1e36
            collUsd += (und * price) / 1e36;
        }
        console2.log("seizable collateral (USD):", collUsd);
        // The shortfall dwarfs the collateral -> a liquidator repays debt and seizes ~nothing.
        assertLt(collUsd, shortfall / 1e18, "collateral < shortfall -> liquidation is a loss");
        console2.log("PASS: bad-debt account has essentially no seizable collateral -> not profitable to liquidate");
    }

    // ------------------------------------------------------------------
    // 6. Price feeds are access-controlled (no permissionless price manipulation)
    // ------------------------------------------------------------------
    function test_06_price_feed_update_is_owner_gated() public {
        address rpcFeed = 0x5da9a0bc9342b801640366e61592EE50E0285437; // CapyfiAggregatorV3 for RPC
        assertEq(IFeed(rpcFeed).owner(), MULTISIG, "feed owner = multisig");
        vm.prank(attacker);
        vm.expectRevert(); // UnauthorizedCaller
        IFeed(rpcFeed).updateAnswer(999_999e6);
        console2.log("PASS: oracle/price feed updateAnswer is owner-gated");
    }
}

interface IFeed {
    function owner() external view returns (address);
    function updateAnswer(int256) external;
}
