// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/* =====================================================================================
   L1-staleprice — stale-price extraction candidates (READ-ONLY research; fork-only).
   Candidates:
   1. Shibarium  woofswap    WBONE/WETH   : sell WBONE into stale pool -> WETH
   2. Shibarium  chained     BONE->WETH (woofswap) -> WETH->DAI (shibaswap 0.3%)
   3. Shibarium  shibaswap   WBTC/WETH    : buy cheap WBTC with WETH
   4. Telos      meridian    USDM/WTLOS   : sell USDM priced at $1.03 vs DL $0.836 (no obtain route)
   5. Songbird   blazeswap   exUSDT/USDX  : control — pool "58% dev" is USDX impairment, not staleness
   ===================================================================================== */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}
interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256, uint256, address, bytes calldata) external;
}

contract L1StalePrice is Test {
    // ---- anchors (DefiLlama / coingecko, 2026-10-16) -------------------------------
    uint256 constant BONE_USD = 0.05941851845139092e18;
    uint256 constant WETH_USD = 2457.909399542849e18;
    uint256 constant DAI_USD  = 1.0003120144956508e18;
    uint256 constant WBTC_USD = 81738.51627072335e18;
    uint256 constant WTLOS_USD = 0.017033472383111977e18;
    uint256 constant USDM_DL    = 0.8363971146718292e18;  // DefiLlama reference (no obtain venue)
    uint256 constant USDM_OKU   = 1.0365e18;              // cheapest real Telos venue (Oku V3, tick-derived)
    uint256 constant EXUSDT_USD = 0.99927e18;
    uint256 constant USDX_XVENUE = 0.626284321387426e18;  // cross-venue USDX value (WSGB & FXRP pools)

    // ---- shibarium ----------------------------------------------------------------
    address constant WBONE_T = 0x839FdB6cc98342B428E074C1573ADF6D48CA3bFd;
    address constant WETH_T  = 0x8ed7d143Ef452316Ab1123d28Ab302dC3b80d3ce;
    address constant WOOF    = 0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13; // WBONE/WETH
    address constant DAI_T   = 0x0726959d22361B79e4D50A5D157b044A83eC870d;
    address constant SHIB_DW = 0xD7115c435eB221addbD3A1D15c95491ec0545f7f; // DAI/WETH
    address constant WBTC_T  = 0xE984D89fb00D0B44E798A55dc41EA598B0b0899d;
    address constant SHIB_WB = 0x1DcCD252eAA20eb8042eeD66C215f7e19279Dc18; // WBTC/WETH

    // ---- telos ---------------------------------------------------------------------
    address constant USDM_T  = 0x8f7D64ea96D729EF24a0F30b4526D47b80d877B9;
    address constant WTLOS_T = 0xD102cE6A4dB07D247fcc28F366A623Df0938CA9E;
    address constant MER_UW  = 0x4277c2B9f1Dd374b7E45778F62639BFA163DaA32; // USDM/WTLOS

    // ---- songbird ------------------------------------------------------------------
    address constant EXUSDT_T = 0x1a7b46656B2b8b29B1694229e122d066020503D0;
    address constant USDX_T   = 0x4A771Cc1a39FDd8AA08B8EA51F7Fd412e73B3d2B;
    address constant BLAZE_P  = 0xBD443213bbaf58012f2508D9cA515533C146326F; // exUSDT/USDX

    address attacker = address(0xA11CE);

    // --------------------------------------------------------------------------------
    function _swapV2(address pair, address tokenIn, uint256 amountIn, address to)
        internal returns (uint256 amountOut)
    {
        (uint112 r0, uint112 r1,) = IPair(pair).getReserves();
        address t0 = IPair(pair).token0();
        bool inIsT0 = (tokenIn == t0);
        (uint256 rIn, uint256 rOut) = inIsT0 ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
        uint256 inFee = amountIn * 997;
        amountOut = (inFee * rOut) / (rIn * 1000 + inFee);
        IERC20(tokenIn).transfer(pair, amountIn);
        if (inIsT0) {
            IPair(pair).swap(0, amountOut, to, "");
        } else {
            IPair(pair).swap(amountOut, 0, to, "");
        }
    }

    function _deal(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
    }

    function setUp() public {}

    /* ======================= 1+2: SHIBARIUM woofswap / chained ===================== */
    function test_shibarium_woofswap_and_chain() public {
        vm.createSelectFork("https://rpc.shibarium.shib.io");
        console2.log("fork block", block.number);

        // --- 1) woofswap only: BONE->WBONE -> WETH ---
        uint256 boneIn = 34_902e18;              // computed optimum (0.3% fee)
        _deal(WBONE_T, attacker, boneIn);
        vm.startPrank(attacker);
        uint256 wethOut = _swapV2(WOOF, WBONE_T, boneIn, attacker);
        vm.stopPrank();
        uint256 cost1 = boneIn * BONE_USD / 1e18;
        uint256 val1  = wethOut * WETH_USD / 1e18;
        console2.log("[1] woofswap WBONE->WETH");
        console2.log("    boneIn   :", boneIn / 1e18);
        console2.log("    wethOut  :", wethOut);
        console2.log("    cost USD :", cost1 / 1e18);
        console2.log("    value USD:", val1 / 1e18);
        console2.log("    NET USD  :", int256(val1) - int256(cost1));

        // --- 2) chained: fresh fork state, BONE -> WETH (woofswap) -> DAI (shibaswap) ---
        vm.createSelectFork("https://rpc.shibarium.shib.io");
        vm.roll(block.number); // no-op, keep fresh fork
        uint256 boneIn2 = 14_709e18;             // computed joint optimum
        _deal(WBONE_T, attacker, boneIn2);
        vm.startPrank(attacker);
        uint256 wethMid = _swapV2(WOOF, WBONE_T, boneIn2, attacker);
        // approve not needed: helper transfers directly
        uint256 daiOut = _swapV2(SHIB_DW, WETH_T, wethMid, attacker);
        vm.stopPrank();
        uint256 cost2 = boneIn2 * BONE_USD / 1e18;
        uint256 val2  = daiOut * DAI_USD / 1e18;
        console2.log("[2] chained BONE->WETH->DAI");
        console2.log("    boneIn   :", boneIn2 / 1e18);
        console2.log("    wethMid  :", wethMid);
        console2.log("    daiOut   :", daiOut / 1e18);
        console2.log("    cost USD :", cost2 / 1e18);
        console2.log("    value USD:", val2 / 1e18);
        console2.log("    NET USD  :", int256(val2) - int256(cost2));

        // --- 3) WBTC/WETH pool: WETH -> cheap WBTC ---
        vm.createSelectFork("https://rpc.shibarium.shib.io");
        uint256 wethIn = 5.49790e16;             // computed optimum
        _deal(WETH_T, attacker, wethIn);
        vm.startPrank(attacker);
        uint256 wbtcOut = _swapV2(SHIB_WB, WETH_T, wethIn, attacker);
        vm.stopPrank();
        uint256 cost3 = wethIn * WETH_USD / 1e18;
        uint256 val3  = wbtcOut * WBTC_USD / 1e8;
        console2.log("[3] shibaswap WBTC/WETH (buy WBTC)");
        console2.log("    wethIn   :", wethIn);
        console2.log("    wbtcOut  :", wbtcOut);
        console2.log("    NET USD  :", int256(val3) - int256(cost3));
    }

    /* ============================ 4: TELOS meridian USDM ============================ */
    function test_telos_usdm() public {
        vm.createSelectFork("https://rpc.telos.net");
        console2.log("fork block", block.number);
        uint256 usdmIn = 360.5e18;               // computed optimum at DL reference
        _deal(USDM_T, attacker, usdmIn);
        vm.startPrank(attacker);
        uint256 wtlosOut = _swapV2(MER_UW, USDM_T, usdmIn, attacker);
        vm.stopPrank();
        uint256 val = wtlosOut * WTLOS_USD / 1e18;
        uint256 costDL = usdmIn * USDM_DL / 1e18;   // "cheap" DL ref — NO obtain venue at this price
        uint256 costOKU = usdmIn * USDM_OKU / 1e18; // cheapest actual venue (Oku V3)
        console2.log("[4] Telos meridian USDM/WTLOS");
        console2.log("    usdmIn   :", usdmIn / 1e18);
        console2.log("    wtlosOut :", wtlosOut / 1e18);
        console2.log("    value USD:", val / 1e18);
        console2.log("    NET vs DL ref (unobtainable):", int256(val) - int256(costDL));
        console2.log("    NET vs real venue price     :", int256(val) - int256(costOKU));
    }

    /* =========================== 5: SONGBIRD exUSDT/USDX =========================== */
    function test_songbird_control() public {
        vm.createSelectFork("https://songbird-api.flare.network/ext/C/rpc");
        console2.log("fork block", block.number);
        // control: sell exUSDT into the pool, value the USDX received at its cross-venue price
        uint256 inAmt = 20_000e6;
        _deal(EXUSDT_T, attacker, inAmt);
        vm.startPrank(attacker);
        uint256 usdxOut = _swapV2(BLAZE_P, EXUSDT_T, inAmt, attacker);
        vm.stopPrank();
        uint256 cost = inAmt * EXUSDT_USD / 1e6;
        uint256 val  = usdxOut * USDX_XVENUE / 1e6;
        console2.log("[5] Songbird exUSDT/USDX control");
        console2.log("    exusdtIn :", inAmt / 1e6);
        console2.log("    usdxOut  :", usdxOut / 1e6);
        console2.log("    NET USD  :", int256(val) - int256(cost));
    }
}
