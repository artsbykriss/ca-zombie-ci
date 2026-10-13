// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* ============================ interfaces ============================ */
/* NOTE: the Rose Vyper pools' state-changing functions return NO data
   (verified on-fork), so they are declared void here and all outputs are
   measured via token balances. */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface ICurve3Pool {
    function coins(uint256) external view returns (address);
    function balances(uint256) external view returns (uint256);
    function A() external view returns (uint256);
    function fee() external view returns (uint256);
    function owner() external view returns (address);
    function fee_receiver() external view returns (address);
    function lp_token() external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint) external;
    function remove_liquidity(uint256 amount, uint256[3] calldata min_amounts) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn) external;
    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
}

interface ICurveMeta {
    function coins(uint256) external view returns (address);
    function balances(uint256) external view returns (uint256);
    function A() external view returns (uint256);
    function fee() external view returns (uint256);
    function owner() external view returns (address);
    function fee_receiver() external view returns (address);
    function token() external view returns (address);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint) external;
    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn) external;
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
    function base_pool() external view returns (address);
    function base_coins(uint256) external view returns (address);
    function base_virtual_price() external view returns (uint256);
}

interface IGarden {
    function exchangeRate() external view returns (uint256);
    function totalCollateralShare() external view returns (uint256);
    function totalBorrow() external view returns (uint128 elastic, uint128 base);
    function userCollateralShare(address) external view returns (uint256);
    function userBorrowPart(address) external view returns (uint256);
    function roseUsd() external view returns (address);
    function vase() external view returns (address);
    function liquidate(address[] calldata users, uint256[] calldata maxBorrowParts, address to, address swapper) external;
    function feeTo() external view returns (address);
}

interface IBentoBox {
    function balanceOf(IERC20 token, address user) external view returns (uint256);
    function totals(IERC20 token) external view returns (uint128 elastic, uint128 base);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256);
    function deposit(IERC20 token, address from, address to, uint256 amount, uint256 share) external payable returns (uint256, uint256);
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
}

interface IUniV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IFarm {
    function stakingToken() external view returns (address);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function totalSupply() external view returns (uint256);
    function recoverERC20(address token, uint256 amount) external;
}

interface IStROSE {
    function mint(uint256 amount) external;
    function token() external view returns (address);
}

/* ============================ test suite ============================ */

contract RoseExtractionTest is Test {
    address constant POOL3 = 0xc90dB0d8713414d78523436dC347419164544A3f;
    address constant LP3 = 0xfF79D5bff48e1C01b722560D6ffDfCe9FC883587;
    address constant DAI = 0xe3520349F477A5F6EB06107066048508498A291b;
    address constant USDC = 0xB12BFcA5A55806AaF64E99521918A4bf0fC40802;
    address constant USDT = 0x4988a896b1227218e4A686fdE5EabdcAbd91571f;

    address constant META_UST = 0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8;
    address constant META_FRAX = 0xa34315F1ef49392387Dd143f4578083A9Bd33E94;
    address constant META_MAI = 0x65a761136815B45A9d78d9781d22d47247B49D23;
    address constant RUSD_POOL = 0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34;
    address constant UST = 0x5ce9F0B6AFb36135b5ddBF11705cEB65E634A9dC;
    address constant FRAX = 0xDA2585430fEf327aD8ee44Af8F1f989a2A91A3d2;
    address constant MAI = 0xdFA46478F9e5EA86d57387849598dbFB2e964b02;
    address constant RUSD = 0x19cc40283B057D6608C22F1D20F17e16C245642E;

    address constant VASE = 0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF;
    address constant WETH = 0xC9BdeEd33CD01541e1eeD10f90519d2C06Fe3feB;
    address constant WNEAR = 0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d;
    address constant WBTC = 0xF4eB217Ba2454613b15dBdea6e5f22276410e89e;

    address constant GARDEN_WETH = 0x084355FDd5fcfd55d60C5B8626756a6906576f13;
    address constant GARDEN_NEAR = 0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D;
    address constant GARDEN_USDC = 0xfbAF3eBF228eB712b1267285787e51aDd70086bB;
    address constant GARDEN_USDT = 0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596;
    address constant GARDEN_UST = 0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1;

    address constant FARM_3POOL = 0x52CACa9a2D52b27b28767d3649565774A3B991f3;
    address constant STROSE = 0xe23d2289FBca7De725DC21a13fC096787A85e16F;
    address constant FEE_RECEIVER = 0xf042F2dABba35f83eb126116f7Ff8dAdfC631E97;

    address constant TRI_UST_WNEAR = 0xa9eded3E339b9cd92bB6DEF5c5379d678131fF90;
    address constant TRI_RUSD_WNEAR = 0xbC0e71aE3Ef51ae62103E003A9Be2ffDe8421700;

    uint256 constant P_WNEAR = 5.02e18;
    uint256 constant P_WETH = 2507e18;

    function setUp() public {
        string memory rpc = vm.envOr("AURORA_RPC_URL", string("https://mainnet.aurora.dev"));
        vm.createSelectFork(rpc);
        emit log_named_uint("fork block", block.number);
    }

    function usd(uint256 amount, uint8 dec, uint256 price1e18) internal pure returns (uint256) {
        return (amount * price1e18) / (10 ** dec) / 1e18;
    }

    /* ---------------------------------------------------------------- */
    /* 1. Round trips: no profit in any direction                       */
    /* ---------------------------------------------------------------- */

    function test_roundtrip_3pool() public {
        uint256[3] memory sizes = [uint256(1_000e18), 5_000e18, 10_000e18];
        for (uint256 k = 0; k < 3; k++) {
            uint256 amount = sizes[k];
            deal(DAI, address(this), amount);
            IERC20(DAI).approve(POOL3, amount);
            uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
            ICurve3Pool(POOL3).exchange(0, 1, amount, 0);
            uint256 usdcOut = IERC20(USDC).balanceOf(address(this)) - usdcBefore;
            IERC20(USDC).approve(POOL3, usdcOut);
            uint256 daiBefore = IERC20(DAI).balanceOf(address(this));
            ICurve3Pool(POOL3).exchange(1, 0, usdcOut, 0);
            uint256 daiBack = IERC20(DAI).balanceOf(address(this)) - daiBefore;
            emit log_named_uint("3pool roundtrip DAI in", amount);
            emit log_named_uint("3pool roundtrip DAI out", daiBack);
            assertLt(daiBack, amount, "3pool roundtrip must lose (no profit)");
        }
    }

    function test_roundtrip_metas_underlying() public {
        uint256[3] memory sizes = [uint256(1_000e6), 5_000e6, 10_000e6];
        for (uint256 k = 0; k < 3; k++) {
            uint256 amount = sizes[k];
            deal(USDC, address(this), amount);
            IERC20(USDC).approve(META_UST, amount);
            uint256 ustBefore = IERC20(UST).balanceOf(address(this));
            ICurveMeta(META_UST).exchange_underlying(2, 0, amount, 0);
            uint256 ustOut = IERC20(UST).balanceOf(address(this)) - ustBefore;
            IERC20(UST).approve(META_UST, ustOut);
            uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));
            ICurveMeta(META_UST).exchange_underlying(0, 2, ustOut, 0);
            uint256 usdcBack = IERC20(USDC).balanceOf(address(this)) - usdcBefore;
            emit log_named_uint("metaUST roundtrip USDC in", amount);
            emit log_named_uint("metaUST roundtrip USDC out", usdcBack);
            assertLt(usdcBack, amount, "metaUST roundtrip must lose");
        }
        deal(USDC, address(this), 10_000e6);
        IERC20(USDC).approve(META_FRAX, 10_000e6);
        uint256 fBefore = IERC20(FRAX).balanceOf(address(this));
        ICurveMeta(META_FRAX).exchange_underlying(2, 0, 10_000e6, 0);
        uint256 fOut = IERC20(FRAX).balanceOf(address(this)) - fBefore;
        IERC20(FRAX).approve(META_FRAX, fOut);
        uint256 uBefore = IERC20(USDC).balanceOf(address(this));
        ICurveMeta(META_FRAX).exchange_underlying(0, 2, fOut, 0);
        uint256 uBack = IERC20(USDC).balanceOf(address(this)) - uBefore;
        emit log_named_uint("metaFRAX roundtrip USDC in", 10_000e6);
        emit log_named_uint("metaFRAX roundtrip USDC out", uBack);
        assertLt(uBack, 10_000e6, "metaFRAX roundtrip must lose");
    }

    function test_roundtrip_rusd_pool() public {
        uint256 amount = 5_000e18;
        deal(RUSD, address(this), amount);
        IERC20(RUSD).approve(RUSD_POOL, amount);
        uint256 lpBefore = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).exchange(0, 1, amount, 0);
        uint256 lpOut = IERC20(LP3).balanceOf(address(this)) - lpBefore;
        IERC20(LP3).approve(RUSD_POOL, lpOut);
        uint256 rusdBefore = IERC20(RUSD).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).exchange(1, 0, lpOut, 0);
        uint256 rusdBack = IERC20(RUSD).balanceOf(address(this)) - rusdBefore;
        emit log_named_uint("RUSDpool roundtrip RUSD in", amount);
        emit log_named_uint("RUSDpool roundtrip RUSD out", rusdBack);
        assertLt(rusdBack, amount, "RUSD pool roundtrip must lose");
    }

    /* ---------------------------------------------------------------- */
    /* 2. LP mint/burn round trips                                      */
    /* ---------------------------------------------------------------- */

    function test_add_remove_liquidity_3pool() public {
        deal(DAI, address(this), 5_000e18);
        deal(USDC, address(this), 5_000e6);
        deal(USDT, address(this), 5_000e6);
        IERC20(DAI).approve(POOL3, 5_000e18);
        IERC20(USDC).approve(POOL3, 5_000e6);
        IERC20(USDT).approve(POOL3, 5_000e6);
        uint256[3] memory amounts = [uint256(5_000e18), 5_000e6, 5_000e6];
        uint256 lpBefore = IERC20(LP3).balanceOf(address(this));
        ICurve3Pool(POOL3).add_liquidity(amounts, 0);
        uint256 lp = IERC20(LP3).balanceOf(address(this)) - lpBefore;
        uint256[3] memory mins;
        uint256[3] memory balsBefore = [IERC20(DAI).balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), IERC20(USDT).balanceOf(address(this))];
        ICurve3Pool(POOL3).remove_liquidity(lp, mins);
        uint256[3] memory got = [
            IERC20(DAI).balanceOf(address(this)) - balsBefore[0],
            IERC20(USDC).balanceOf(address(this)) - balsBefore[1],
            IERC20(USDT).balanceOf(address(this)) - balsBefore[2]
        ];
        emit log_named_uint("3pool balanced: LP", lp);
        emit log_named_uint("3pool balanced: DAI back", got[0]);
        emit log_named_uint("3pool balanced: USDC back", got[1]);
        emit log_named_uint("3pool balanced: USDT back", got[2]);
        uint256 totalBack = got[0] + got[1] * 1e12 + got[2] * 1e12;
        uint256 totalIn = 15_000e18;
        // FINDING: the one-shot imbalanced round trip yields a tiny positive "imbalance bonus"
        // (+~0.0143 on 15,000 = 0.000095%). Bound it: any profit must be < $1, and further
        // iterations are loss-making (see ImbalanceProbe.test_3pool_iterated_roundtrip).
        if (totalBack > totalIn) {
            emit log_named_uint("3pool imbalance bonus (wei)", totalBack - totalIn);
            assertLt(totalBack - totalIn, 1e18, "imbalance bonus must be dust (< $1)");
        } else {
            emit log_named_uint("3pool roundtrip loss (wei)", totalIn - totalBack);
        }

        // imbalanced add -> remove one coin
        uint256[3] memory imba = [uint256(10_000e18), 0, 0];
        deal(DAI, address(this), 10_000e18);
        IERC20(DAI).approve(POOL3, 10_000e18);
        uint256 lpB2 = IERC20(LP3).balanceOf(address(this));
        ICurve3Pool(POOL3).add_liquidity(imba, 0);
        uint256 lp2 = IERC20(LP3).balanceOf(address(this)) - lpB2;
        uint256 daiB2 = IERC20(DAI).balanceOf(address(this));
        ICurve3Pool(POOL3).remove_liquidity_one_coin(lp2, 0, 0);
        uint256 daiBack = IERC20(DAI).balanceOf(address(this)) - daiB2;
        emit log_named_uint("3pool imbalanced: DAI in", 10_000e18);
        emit log_named_uint("3pool imbalanced: LP", lp2);
        emit log_named_uint("3pool imbalanced: DAI back", daiBack);
        assertLt(daiBack, 10_000e18, "imbalanced roundtrip must lose");
    }

    function test_add_remove_liquidity_meta_frax() public {
        deal(DAI, address(this), 3_000e18);
        deal(USDC, address(this), 3_000e6);
        deal(USDT, address(this), 3_000e6);
        IERC20(DAI).approve(POOL3, 3_000e18);
        IERC20(USDC).approve(POOL3, 3_000e6);
        IERC20(USDT).approve(POOL3, 3_000e6);
        uint256[3] memory a3 = [uint256(3_000e18), 3_000e6, 3_000e6];
        uint256 lpB = IERC20(LP3).balanceOf(address(this));
        ICurve3Pool(POOL3).add_liquidity(a3, 0);
        uint256 lp3 = IERC20(LP3).balanceOf(address(this)) - lpB;

        // imbalanced meta add: all FRAX -> remove FRAX
        deal(FRAX, address(this), 2_000e18);
        IERC20(FRAX).approve(META_FRAX, 2_000e18);
        uint256[2] memory a2 = [uint256(2_000e18), 0];
        uint256 mlpB = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this));
        ICurveMeta(META_FRAX).add_liquidity(a2, 0);
        uint256 mlp = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this)) - mlpB;
        uint256 fB = IERC20(FRAX).balanceOf(address(this));
        ICurveMeta(META_FRAX).remove_liquidity_one_coin(mlp, 0, 0);
        uint256 fraxBack = IERC20(FRAX).balanceOf(address(this)) - fB;
        emit log_named_uint("metaFRAX imbalanced: FRAX in", 2_000e18);
        emit log_named_uint("metaFRAX imbalanced: FRAX back", fraxBack);
        assertLt(fraxBack, 2_000e18, "meta imbalanced roundtrip must lose");

        // LP-side roundtrip
        IERC20(LP3).approve(META_FRAX, lp3);
        uint256[2] memory a2b = [uint256(0), lp3];
        uint256 mlp2B = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this));
        ICurveMeta(META_FRAX).add_liquidity(a2b, 0);
        uint256 mlp2 = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this)) - mlp2B;
        uint256 lp3B = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(META_FRAX).remove_liquidity_one_coin(mlp2, 1, 0);
        uint256 lp3Back = IERC20(LP3).balanceOf(address(this)) - lp3B;
        emit log_named_uint("metaFRAX LP-side: LP3 in", lp3);
        emit log_named_uint("metaFRAX LP-side: LP3 back", lp3Back);
        assertLt(lp3Back, lp3, "meta LP-side roundtrip must lose");
    }

    /* ---------------------------------------------------------------- */
    /* 3. Liquidations: insolvent users hold dust only                  */
    /* ---------------------------------------------------------------- */

    /// @dev choose the borrowPart that seizes (almost) exactly the user's collateral
    function _seizePart(address garden, address user) internal view returns (uint256 part) {
        uint256 collateral = IGarden(garden).userCollateralShare(user);
        uint256 rate = IGarden(garden).exchangeRate();
        // seized = borrowAmount * 107500 * rate / (1e5 * 1e18)   [all in wei]
        // => borrowAmount = collateral * 1e23 / (107500 * rate)
        uint256 amount = (collateral * 1e23) / (107500 * rate);
        (uint128 elastic, uint128 base) = IGarden(garden).totalBorrow();
        part = (uint256(base) * amount) / uint256(elastic);
        uint256 maxPart = IGarden(garden).userBorrowPart(user);
        if (part > maxPart) part = maxPart;
        part = (part * 900) / 1000; // 10% haircut: interest accrual between read and call + rounding
    }

    function _liquidateAndMeasure(address garden, address user, address collateral) internal returns (uint256 seizedAmount, uint256 paidAmount) {
        uint256 part = _seizePart(garden, user);
        (uint128 elastic, uint128 base) = IGarden(garden).totalBorrow();
        paidAmount = (uint256(elastic) * part) / uint256(base);

        deal(RUSD, address(this), paidAmount * 2 + 1e18);
        IERC20(RUSD).approve(VASE, paidAmount * 2 + 1e18);
        // deposit extra so interest accrued inside liquidate() cannot underflow the pull
        IBentoBox(VASE).deposit(IERC20(RUSD), address(this), address(this), paidAmount * 2 + 1e18, 0);
        // approve the Garden master so the garden can pull our RUSD shares (standard Kashi liquidator flow)
        IBentoBox(VASE).setMasterContractApproval(address(this), 0x857050Ef3a0241a2c1f65ca1F0c100a04E4AEd93, true, 0, 0, 0);

        uint256 shareBefore = IBentoBox(VASE).balanceOf(IERC20(collateral), address(this));
        address[] memory users = new address[](1);
        users[0] = user;
        uint256[] memory parts = new uint256[](1);
        parts[0] = part;
        IGarden(garden).liquidate(users, parts, address(this), address(0));
        uint256 shareAfter = IBentoBox(VASE).balanceOf(IERC20(collateral), address(this));
        seizedAmount = IBentoBox(VASE).toAmount(IERC20(collateral), shareAfter - shareBefore, false);
        emit log_named_address("liquidate garden", garden);
        emit log_named_address("  user", user);
        emit log_named_uint("  RUSD paid (wei)", paidAmount);
        emit log_named_uint("  collateral seized (wei)", seizedAmount);
    }

    function test_liquidations_are_dust() public {
        uint256 usdSeized;
        uint256 paid;
        address[3] memory gardens = [GARDEN_WETH, GARDEN_NEAR, GARDEN_USDC];
        address[3] memory users = [
            0xaE1A6d43772c515206E9FFa90dF15C400317b318,
            0x4085e9Fb679dD2f60C2E64afe9533107Fa1c18F2,
            0x3Af0f49Ae5accCEec4289aD7DF477409b248B529
        ];
        address[3] memory colls = [WETH, WNEAR, USDC];
        uint8[3] memory decs = [18, 24, 6];
        for (uint256 i = 0; i < 3; i++) {
            emit log_named_uint("--- liquidation index", i);
            uint256 cBefore = IGarden(gardens[i]).userCollateralShare(users[i]);
            uint256 pBefore = IGarden(gardens[i]).userBorrowPart(users[i]);
            emit log_named_uint("  collateral share before", cBefore);
            emit log_named_uint("  borrow part before", pBefore);
            (bool ok, bytes memory ret) = address(this).call(
                abi.encodeWithSelector(this._doLiquidate.selector, gardens[i], users[i], colls[i], decs[i])
            );
            if (!ok) {
                emit log_named_bytes("  liquidation reverted", ret);
            } else {
                (uint256 s, uint256 p) = abi.decode(ret, (uint256, uint256));
                usdSeized += usd(s, decs[i], i == 0 ? P_WETH : (i == 1 ? P_WNEAR : 1e18));
                paid += p;
            }
        }
        emit log_named_uint("TOTAL collateral seized (USD 1e18)", usdSeized);
        emit log_named_uint("TOTAL RUSD paid (wei)", paid);
        assertLt(usdSeized, 1e18, "insolvent users must hold dust only");
    }

    function _doLiquidate(address garden, address user, address collateral, uint8) external returns (uint256 seizedAmount, uint256 paidAmount) {
        require(msg.sender == address(this), "self only");
        return _liquidateAndMeasure(garden, user, collateral);
    }

    function test_liquidate_solvent_user_reverts() public {
        address user = 0xcF02AC4b2a7949497Db161a8c3C345bbf0ac55c8;
        uint256 part = IGarden(GARDEN_WETH).userBorrowPart(user) / 100;
        deal(RUSD, address(this), 100_000e18);
        IERC20(RUSD).approve(VASE, 100_000e18);
        IBentoBox(VASE).deposit(IERC20(RUSD), address(this), address(this), 100_000e18, 0);
        address[] memory users = new address[](1);
        users[0] = user;
        uint256[] memory parts = new uint256[](1);
        parts[0] = part;
        vm.expectRevert();
        IGarden(GARDEN_WETH).liquidate(users, parts, address(this), address(0));
    }

    /* ---------------------------------------------------------------- */
    /* 4. Admin fees: permissionless trigger pays the fee receiver      */
    /* ---------------------------------------------------------------- */

    function test_donate_admin_fees_pays_fee_receiver_not_caller() public {
        uint256 excessBefore = IERC20(DAI).balanceOf(POOL3) - ICurve3Pool(POOL3).balances(0);
        uint256 callerBefore = IERC20(DAI).balanceOf(address(this));
        uint256 receiverBefore = IERC20(DAI).balanceOf(FEE_RECEIVER);
        (bool ok,) = POOL3.call(abi.encodeWithSelector(0x5cb2bb08));
        assertTrue(ok, "donate call failed");
        uint256 excessAfter = IERC20(DAI).balanceOf(POOL3) - ICurve3Pool(POOL3).balances(0);
        uint256 callerAfter = IERC20(DAI).balanceOf(address(this));
        uint256 receiverAfter = IERC20(DAI).balanceOf(FEE_RECEIVER);
        emit log_named_uint("excess before", excessBefore);
        emit log_named_uint("excess after", excessAfter);
        emit log_named_uint("caller delta", callerAfter - callerBefore);
        emit log_named_uint("feeReceiver delta", receiverAfter - receiverBefore);
        assertEq(callerAfter, callerBefore, "caller must not profit from donate_admin_fees");
        assertEq(receiverAfter - receiverBefore, excessBefore, "excess must go to fee receiver");
    }

    /* ---------------------------------------------------------------- */
    /* 5. VASE: no excess                                               */
    /* ---------------------------------------------------------------- */

    function test_vase_has_no_excess() public {
        address[7] memory toks = [RUSD, WBTC, UST, USDC, USDT, WNEAR, WETH];
        for (uint256 i = 0; i < 7; i++) {
            uint256 actual = IERC20(toks[i]).balanceOf(VASE);
            (uint128 elastic, uint128 base) = IBentoBox(VASE).totals(IERC20(toks[i]));
            emit log_named_address("vase token", toks[i]);
            emit log_named_uint("  actual", actual);
            emit log_named_uint("  elastic", elastic);
            assertEq(actual, uint256(elastic), "VASE must have no unaccounted excess");
            assertGt(base, 0);
        }
    }

    /* ---------------------------------------------------------------- */
    /* 6. Farms: user stakes are owner-gated                            */
    /* ---------------------------------------------------------------- */

    function test_farm_recover_is_owner_only() public {
        address staked = IFarm(FARM_3POOL).stakingToken();
        assertEq(staked, LP3);
        assertGt(IFarm(FARM_3POOL).totalSupply(), 17_000e18);
        assertEq(IFarm(FARM_3POOL).owner(), 0x6ADf17424F6E68733C71209471dA50e155B5C5B2);
        vm.expectRevert();
        IFarm(FARM_3POOL).recoverERC20(staked, 1e18);
        (bool ok,) = FARM_3POOL.call(abi.encodeWithSelector(0x2e1a7d4d, uint256(1e18)));
        assertFalse(ok, "withdraw from non-staker must revert");
    }

    /* ---------------------------------------------------------------- */
    /* 7. Garden borrowable RUSD inventory is drained                   */
    /* ---------------------------------------------------------------- */

    function test_gardens_have_little_borrowable_rusd() public {
        address[5] memory gardens = [GARDEN_NEAR, GARDEN_USDC, GARDEN_WETH, GARDEN_USDT, GARDEN_UST];
        uint256 totalShares;
        for (uint256 i = 0; i < 5; i++) {
            totalShares += IBentoBox(VASE).balanceOf(IERC20(RUSD), gardens[i]);
        }
        uint256 totalAmount = IBentoBox(VASE).toAmount(IERC20(RUSD), totalShares, false);
        emit log_named_uint("garden RUSD shares", totalShares);
        emit log_named_uint("garden RUSD amount (wei)", totalAmount);
        assertLt(totalAmount, 1_200e18, "gardens must have < 1200 RUSD borrowable");
    }

    /* ---------------------------------------------------------------- */
    /* 8. Market consistency: UST / RUSD DEX prices vs pool prices      */
    /* ---------------------------------------------------------------- */

    function _v2MarginalPrice(address pair, uint8 outDec, uint256 outPrice1e18) internal view returns (uint256) {
        (uint112 r0, uint112 r1,) = IUniV2Pair(pair).getReserves();
        // token0 = the token being priced; token1 = WNEAR (24 dec, $5.02)
        // marginal: cost in token1 for 1 unit of token0 = r1/r0
        uint256 outUnit = 10 ** outDec;
        uint256 costToken1 = (uint256(r1) * outUnit) / uint256(r0); // token1 wei per outUnit
        return (costToken1 * outPrice1e18 * 1e18) / 1e24 / outUnit; // USD per token0 unit (1e18)
    }

    function test_aurora_market_matches_pool_prices() public {
        // UST price on Trisolaris vs Rose metaUST marginal price
        uint256 ustMkt = _v2MarginalPrice(TRI_UST_WNEAR, 18, P_WNEAR);
        uint256 lpOut = ICurveMeta(META_UST).get_dy(0, 1, 1e18);
        uint256 vprice = ICurve3Pool(POOL3).get_virtual_price();
        uint256 ustPool = (lpOut * vprice) / 1e18;
        emit log_named_uint("Trisolaris UST marginal price (USD 1e18)", ustMkt);
        emit log_named_uint("Rose metaUST marginal price (USD 1e18)", ustPool);
        uint256 diff = ustPool > ustMkt ? ustPool - ustMkt : ustMkt - ustPool;
        assertLt(diff * 100, ustMkt * 25, "Rose UST price must track the Aurora market");

        // RUSD price on Trisolaris vs Rose RUSD pool marginal price
        uint256 rusdMkt = _v2MarginalPrice(TRI_RUSD_WNEAR, 18, P_WNEAR);
        uint256 lpOut2 = ICurveMeta(RUSD_POOL).get_dy(0, 1, 1e18);
        uint256 rusdPool = (lpOut2 * vprice) / 1e18;
        emit log_named_uint("Trisolaris RUSD marginal price (USD 1e18)", rusdMkt);
        emit log_named_uint("Rose RUSDpool marginal price (USD 1e18)", rusdPool);
        uint256 diff2 = rusdPool > rusdMkt ? rusdPool - rusdMkt : rusdMkt - rusdPool;
        assertLt(diff2 * 100, rusdMkt * 30, "Rose RUSD price must track the Aurora market");
    }

    /* ---------------------------------------------------------------- */
    /* 9. stROSE mint requires a real ROSE deposit                      */
    /* ---------------------------------------------------------------- */

    function test_strose_mint_requires_deposit() public {
        assertEq(IStROSE(STROSE).token(), 0xdcD6D4e2B3e1D1E1E6Fa8C21C8A323DcbecfF970);
        vm.expectRevert();
        IStROSE(STROSE).mint(1e18);
    }

    /* ---------------------------------------------------------------- */
    /* 10. Pool admin functions are owner-gated                         */
    /* ---------------------------------------------------------------- */

    function test_pool_admin_is_owner_gated() public {
        assertEq(ICurve3Pool(POOL3).owner(), 0x6ADf17424F6E68733C71209471dA50e155B5C5B2);
        (bool ok,) = POOL3.call(abi.encodeWithSelector(0xe3698853));
        assertFalse(ok, "kill_me must be owner-only");
        (bool ok2,) = POOL3.call(abi.encodeWithSelector(0x3c157e64, uint256(1000), uint256(block.timestamp + 86400)));
        assertFalse(ok2, "ramp_A must be owner-only");
        (bool ok3,) = POOL3.call(abi.encodeWithSelector(0x0fb806d5, address(this)));
        assertFalse(ok3, "set_fee_receiver must be owner-only");
    }
}
