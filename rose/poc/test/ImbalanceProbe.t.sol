// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface ICurve3Pool {
    function balances(uint256) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint) external;
    function remove_liquidity(uint256 amount, uint256[3] calldata min_amounts) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn) external;
    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

interface ICurveMeta {
    function balances(uint256) external view returns (uint256);
    function token() external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint) external;
    function remove_liquidity(uint256 amount, uint256[2] calldata min_amounts) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn) external;
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

/// Measures the maximum USD extraction from an imbalanced add+remove round trip.
contract ImbalanceProbe is Test {
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

    uint256 constant P_UST = 0.0363e18; // Aurora DEX implied
    uint256 constant P_FRAX = 0.9904e18;
    uint256 constant P_MAI = 0.9962e18;
    uint256 constant P_RUSD = 0.31e18;

    function setUp() public {
        vm.createSelectFork(vm.envOr("AURORA_RPC_URL", string("https://mainnet.aurora.dev")));
        emit log_named_uint("fork block", block.number);
    }

    function _bals3() internal view returns (uint256[3] memory b) {
        b[0] = ICurve3Pool(POOL3).balances(0);
        b[1] = ICurve3Pool(POOL3).balances(1);
        b[2] = ICurve3Pool(POOL3).balances(2);
    }

    function _mintLP3(uint256 usdcIn) internal returns (uint256 lp) {
        deal(USDC, address(this), usdcIn);
        IERC20(USDC).approve(POOL3, usdcIn);
        uint256 before = IERC20(LP3).balanceOf(address(this));
        uint256[3] memory a;
        a[1] = usdcIn;
        ICurve3Pool(POOL3).add_liquidity(a, 0);
        lp = IERC20(LP3).balanceOf(address(this)) - before;
    }

    /// Perfect balancing deposit into the 3pool, then proportional remove. Max theoretical extraction.
    function test_3pool_perfect_balance_extraction() public {
        uint256[3] memory b = _bals3();
        // normalise to 18 decimals
        uint256 n0 = b[0];
        uint256 n1 = b[1] * 1e12;
        uint256 n2 = b[2] * 1e12;
        uint256 maxB = n0 > n1 ? (n0 > n2 ? n0 : n2) : (n1 > n2 ? n1 : n2);
        uint256[3] memory dep;
        dep[0] = maxB - n0;
        dep[1] = (maxB - n1) / 1e12;
        dep[2] = (maxB - n2) / 1e12;
        emit log_named_uint("deposit DAI", dep[0]);
        emit log_named_uint("deposit USDC", dep[1]);
        emit log_named_uint("deposit USDT", dep[2]);

        deal(DAI, address(this), dep[0]);
        deal(USDC, address(this), dep[1]);
        deal(USDT, address(this), dep[2]);
        IERC20(DAI).approve(POOL3, dep[0]);
        IERC20(USDC).approve(POOL3, dep[1]);
        IERC20(USDT).approve(POOL3, dep[2]);
        uint256 lpBefore = IERC20(LP3).balanceOf(address(this));
        ICurve3Pool(POOL3).add_liquidity(dep, 0);
        uint256 lp = IERC20(LP3).balanceOf(address(this)) - lpBefore;

        uint256[3] memory balsBefore = [IERC20(DAI).balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), IERC20(USDT).balanceOf(address(this))];
        uint256[3] memory mins;
        ICurve3Pool(POOL3).remove_liquidity(lp, mins);
        uint256 got0 = IERC20(DAI).balanceOf(address(this)) - balsBefore[0];
        uint256 got1 = IERC20(USDC).balanceOf(address(this)) - balsBefore[1];
        uint256 got2 = IERC20(USDT).balanceOf(address(this)) - balsBefore[2];

        uint256 inUsd = dep[0] + dep[1] * 1e12 + dep[2] * 1e12;
        uint256 outUsd = got0 + got1 * 1e12 + got2 * 1e12;
        emit log_named_uint("lp minted", lp);
        emit log_named_int("PROFIT (wei 18)", int256(outUsd) - int256(inUsd));
    }

    /// iterate the plain balanced round trip to see cumulative extraction
    function test_3pool_iterated_roundtrip() public {
        int256 total;
        for (uint256 i = 0; i < 5; i++) {
            deal(DAI, address(this), 5_000e18);
            deal(USDC, address(this), 5_000e6);
            deal(USDT, address(this), 5_000e6);
            IERC20(DAI).approve(POOL3, 5_000e18);
            IERC20(USDC).approve(POOL3, 5_000e6);
            IERC20(USDT).approve(POOL3, 5_000e6);
            uint256[3] memory dep = [uint256(5_000e18), 5_000e6, 5_000e6];
            uint256 lpBefore = IERC20(LP3).balanceOf(address(this));
            ICurve3Pool(POOL3).add_liquidity(dep, 0);
            uint256 lp = IERC20(LP3).balanceOf(address(this)) - lpBefore;
            uint256[3] memory bb = [IERC20(DAI).balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), IERC20(USDT).balanceOf(address(this))];
            uint256[3] memory mins;
            ICurve3Pool(POOL3).remove_liquidity(lp, mins);
            uint256 out0 = IERC20(DAI).balanceOf(address(this)) - bb[0];
            uint256 out1 = IERC20(USDC).balanceOf(address(this)) - bb[1];
            uint256 out2 = IERC20(USDT).balanceOf(address(this)) - bb[2];
            uint256 outUsd = out0 + out1 * 1e12 + out2 * 1e12;
            int256 profit = int256(outUsd) - int256(15_000e18);
            total += profit;
            emit log_named_int("iter profit (wei)", profit);
        }
        emit log_named_int("TOTAL iter profit (wei 18)", total);
    }

    /// meta pools: try depositing the scarce (LP) side and removing the meta side, and vice versa
    function test_meta_imbalance_probe() public {
        // ---- metaFRAX ----
        uint256 lp = _mintLP3(2_000e6);
        IERC20(LP3).approve(META_FRAX, lp);
        uint256[2] memory depA = [uint256(0), lp];
        uint256 tsBefore = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this));
        ICurveMeta(META_FRAX).add_liquidity(depA, 0);
        uint256 mlp = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this)) - tsBefore;
        emit log_named_uint("metaFRAX LP in (wei)", lp);
        emit log_named_uint("metaFRAX metaLP minted", mlp);
        // remove FRAX
        uint256 fB = IERC20(FRAX).balanceOf(address(this));
        ICurveMeta(META_FRAX).remove_liquidity_one_coin(mlp, 0, 0);
        uint256 fraxOut = IERC20(FRAX).balanceOf(address(this)) - fB;
        emit log_named_uint("metaFRAX FRAX out (wei)", fraxOut);
        emit log_named_int("metaFRAX profit USD wei (out-in)", int256(fraxOut * P_FRAX / 1e18) - int256(lp));

        // ---- RUSD pool ----
        uint256 lp2 = _mintLP3(1_000e6);
        IERC20(LP3).approve(RUSD_POOL, lp2);
        uint256[2] memory depB = [uint256(0), lp2];
        uint256 tsB = IERC20(ICurveMeta(RUSD_POOL).token()).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).add_liquidity(depB, 0);
        uint256 mlp2 = IERC20(ICurveMeta(RUSD_POOL).token()).balanceOf(address(this)) - tsB;
        uint256 rB = IERC20(RUSD).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).remove_liquidity_one_coin(mlp2, 0, 0);
        uint256 rusdOut = IERC20(RUSD).balanceOf(address(this)) - rB;
        emit log_named_uint("RUSDpool LP in (wei)", lp2);
        emit log_named_uint("RUSDpool RUSD out (wei)", rusdOut);
        emit log_named_int("RUSDpool profit USD wei (out-in)", int256(rusdOut * P_RUSD / 1e18) - int256(lp2));

        // ---- metaUST ----
        uint256 lp3 = _mintLP3(200e6);
        IERC20(LP3).approve(META_UST, lp3);
        uint256[2] memory depC = [uint256(0), lp3];
        uint256 tsC = IERC20(ICurveMeta(META_UST).token()).balanceOf(address(this));
        ICurveMeta(META_UST).add_liquidity(depC, 0);
        uint256 mlp3 = IERC20(ICurveMeta(META_UST).token()).balanceOf(address(this)) - tsC;
        uint256 uB = IERC20(UST).balanceOf(address(this));
        ICurveMeta(META_UST).remove_liquidity_one_coin(mlp3, 0, 0);
        uint256 ustOut = IERC20(UST).balanceOf(address(this)) - uB;
        emit log_named_uint("metaUST LP in (wei)", lp3);
        emit log_named_uint("metaUST UST out (wei)", ustOut);
        emit log_named_int("metaUST profit USD wei (out-in)", int256(ustOut * P_UST / 1e18) - int256(lp3));

        // ---- metaMAI ----
        uint256 lp4 = _mintLP3(100e6);
        IERC20(LP3).approve(META_MAI, lp4);
        uint256[2] memory depD = [uint256(0), lp4];
        uint256 tsD = IERC20(ICurveMeta(META_MAI).token()).balanceOf(address(this));
        ICurveMeta(META_MAI).add_liquidity(depD, 0);
        uint256 mlp4 = IERC20(ICurveMeta(META_MAI).token()).balanceOf(address(this)) - tsD;
        uint256 mB = IERC20(MAI).balanceOf(address(this));
        ICurveMeta(META_MAI).remove_liquidity_one_coin(mlp4, 0, 0);
        uint256 maiOut = IERC20(MAI).balanceOf(address(this)) - mB;
        emit log_named_uint("metaMAI LP in (wei)", lp4);
        emit log_named_uint("metaMAI MAI out (wei)", maiOut);
        emit log_named_int("metaMAI profit USD wei (out-in)", int256(maiOut * P_MAI / 1e18) - int256(lp4));
    }

    /// reverse direction: deposit the meta coin, remove the LP side
    function test_meta_reverse_probe() public {
        // metaFRAX: deposit FRAX, remove LP
        deal(FRAX, address(this), 2_000e18);
        IERC20(FRAX).approve(META_FRAX, 2_000e18);
        uint256[2] memory dep = [uint256(2_000e18), 0];
        uint256 tsB = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this));
        ICurveMeta(META_FRAX).add_liquidity(dep, 0);
        uint256 mlp = IERC20(ICurveMeta(META_FRAX).token()).balanceOf(address(this)) - tsB;
        uint256 lpB = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(META_FRAX).remove_liquidity_one_coin(mlp, 1, 0);
        uint256 lpOut = IERC20(LP3).balanceOf(address(this)) - lpB;
        emit log_named_uint("metaFRAX FRAX in (wei)", 2_000e18);
        emit log_named_uint("metaFRAX LP out (wei)", lpOut);
        emit log_named_int("metaFRAX rev profit USD wei", int256(lpOut) - int256(2_000e18 * P_FRAX / 1e18));

        // RUSD pool: deposit RUSD, remove LP
        deal(RUSD, address(this), 2_000e18);
        IERC20(RUSD).approve(RUSD_POOL, 2_000e18);
        uint256[2] memory dep2 = [uint256(2_000e18), 0];
        uint256 tsB2 = IERC20(ICurveMeta(RUSD_POOL).token()).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).add_liquidity(dep2, 0);
        uint256 mlp2 = IERC20(ICurveMeta(RUSD_POOL).token()).balanceOf(address(this)) - tsB2;
        uint256 lpB2 = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(RUSD_POOL).remove_liquidity_one_coin(mlp2, 1, 0);
        uint256 lpOut2 = IERC20(LP3).balanceOf(address(this)) - lpB2;
        emit log_named_uint("RUSDpool RUSD in (wei)", 2_000e18);
        emit log_named_uint("RUSDpool LP out (wei)", lpOut2);
        emit log_named_int("RUSDpool rev profit USD wei", int256(lpOut2) - int256(2_000e18 * P_RUSD / 1e18));

        // metaUST: deposit UST, remove LP
        deal(UST, address(this), 20_000e18);
        IERC20(UST).approve(META_UST, 20_000e18);
        uint256[2] memory dep3 = [uint256(20_000e18), 0];
        uint256 tsB3 = IERC20(ICurveMeta(META_UST).token()).balanceOf(address(this));
        ICurveMeta(META_UST).add_liquidity(dep3, 0);
        uint256 mlp3 = IERC20(ICurveMeta(META_UST).token()).balanceOf(address(this)) - tsB3;
        uint256 lpB3 = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(META_UST).remove_liquidity_one_coin(mlp3, 1, 0);
        uint256 lpOut3 = IERC20(LP3).balanceOf(address(this)) - lpB3;
        emit log_named_uint("metaUST UST in (wei)", 20_000e18);
        emit log_named_uint("metaUST LP out (wei)", lpOut3);
        emit log_named_int("metaUST rev profit USD wei", int256(lpOut3) - int256(20_000e18 * P_UST / 1e18));

        // metaMAI: deposit MAI, remove LP
        deal(MAI, address(this), 60_000e18);
        IERC20(MAI).approve(META_MAI, 60_000e18);
        uint256[2] memory dep4 = [uint256(60_000e18), 0];
        uint256 tsB4 = IERC20(ICurveMeta(META_MAI).token()).balanceOf(address(this));
        ICurveMeta(META_MAI).add_liquidity(dep4, 0);
        uint256 mlp4 = IERC20(ICurveMeta(META_MAI).token()).balanceOf(address(this)) - tsB4;
        uint256 lpB4 = IERC20(LP3).balanceOf(address(this));
        ICurveMeta(META_MAI).remove_liquidity_one_coin(mlp4, 1, 0);
        uint256 lpOut4 = IERC20(LP3).balanceOf(address(this)) - lpB4;
        emit log_named_uint("metaMAI MAI in (wei)", 60_000e18);
        emit log_named_uint("metaMAI LP out (wei)", lpOut4);
        emit log_named_int("metaMAI rev profit USD wei", int256(lpOut4) - int256(60_000e18 * P_MAI / 1e18));
    }
}
