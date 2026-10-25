// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IERC4626, IOracle, IPyth, IMorpho} from "../src/Interfaces.sol";

/// @title Morpho wSPYx/AUSD — MorphoPythOracle × donation-inflatable ERC-4626 (Ethereum) — fork only
/// @notice Reproduces, on a local Ethereum fork:
///   A. the oracle price == SCALE_FACTOR(1e10) * convertToAssets(wSPYx,1e6) * Pyth(SPY);
///   B. a plain SPYx donation to the wSPYx vault (totalAssets()=asset.balanceOf(this)) inflates the
///      oracle price exactly pro-rata -> the "Edel primitive" is live;
///   C. the market is permissionlessly borrowable and the *hard cap* on any extraction is the
///      market's free (unborrowed) liquidity;
///   D. a full "mint -> donate -> supply -> borrow -> default" attack is a NET LOSS, and the
///      donation makes it strictly worse: net <= -(1/LLTV - 1) * borrowed, always < 0.
contract MorphoWspyxOracleTest is Test {
    // ------------------------------------------------------------------ constants (Ethereum mainnet)
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant WSPYX = 0xc88FcD8B874fDb3256E8B55b3decB8c24EAb4c02; // ERC-4626 wrapper
    address constant SPYX = 0x90A2a4c76b5D8c0bc892A69EA28Aa775a8f2dD48;  // vault asset
    address constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;  // loan token (6 dec)
    address constant ORACLE = 0x01Fd716a703eD6A54922b1F2C8cc2Ed5a018bAC5; // MorphoPythOracle
    address constant PYTH = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    bytes32 constant FEED_SPY = 0x2817b78438c769357182c04346fddaad1178c82f4048828fe0997c3c64624e14;
    uint256 constant SCALE_FACTOR = 1e10;
    uint256 constant CONVERSION_SAMPLE = 1e6;
    uint256 constant LLTV = 0.86e18;
    bytes32 constant MID = 0xbf0432567b44ef5ce013ffcd7dd756c522252503f7986a406e780715b32c74fc;
    // large SPYx holder (Blockscout top-2 holder, 3,842 SPYx) — used to fund the attacker on the fork
    address constant WHALE = 0xf3C20F98Db6De1DBe023bBa94C9525620A0B37e8;

    /// @dev fund an address with real SPYx by impersonating a large holder on the fork
    function _fund(address to, uint256 amount) internal {
        vm.prank(WHALE);
        IERC20(SPYX).transfer(to, amount);
    }

    function _rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
    }

    function _mp() internal view returns (IMorpho.MarketParams memory) {
        return IMorpho(MORPHO).idToMarketParams(MID);
    }

    function _spyUsd1e8() internal view returns (uint256) {
        return uint256(uint64(IPyth(PYTH).getPriceUnsafe(FEED_SPY).price));
    }

    // ------------------------------------------------------------- A. price formula
    function test_A_priceFormulaMatchesOnChain() public {
        uint256 p = IOracle(ORACLE).price();
        uint256 cv = IERC4626(WSPYX).convertToAssets(CONVERSION_SAMPLE);
        uint256 pyth = _spyUsd1e8();
        uint256 expected = SCALE_FACTOR * cv * pyth;
        emit log_named_uint("block", block.number);
        emit log_named_uint("convertToAssets(1e6)", cv);
        emit log_named_uint("pyth SPY (exp -8)", pyth);
        emit log_named_uint("oracle price()", p);
        assertEq(p, expected, "oracle price must equal SCALE*convertToAssets*Pyth");
    }

    // ------------------------------------------------------------- B. donation inflation
    function test_B_donationInflatesOracleProRata() public {
        uint256 p0 = IOracle(ORACLE).price();
        uint256 a0 = IERC4626(WSPYX).totalAssets();
        uint256 d = 100e18; // donate 100 SPYx (~$76.4k)
        address atk = address(0xA11CE);
        _fund(atk, d);
        vm.prank(atk);
        IERC20(SPYX).transfer(WSPYX, d); // direct donation -> totalAssets() up
        uint256 p1 = IOracle(ORACLE).price();
        uint256 expected = p0 * (a0 + d + 1) / (a0 + 1);
        emit log_named_uint("totalAssets before", a0);
        emit log_named_uint("price before", p0);
        emit log_named_uint("price after +100 SPYx donation", p1);
        assertGt(p1, p0, "donation must raise the price");
        assertApproxEqRel(p1, expected, 1e12, "inflation is exactly pro-rata");
    }

    // ------------------------------------------------------------- C. cap = free liquidity
    function test_C_hardCapIsFreeLiquidity() public {
        IMorpho.MarketParams memory mp = _mp();
        IMorpho(MORPHO).accrueInterest(mp);
        IMorpho.Market memory m = IMorpho(MORPHO).market(MID);
        uint256 free = uint256(m.totalSupplyAssets) - uint256(m.totalBorrowAssets);
        emit log_named_uint("totalSupplyAssets (AUSD 1e6)", m.totalSupplyAssets);
        emit log_named_uint("totalBorrowAssets (AUSD 1e6)", m.totalBorrowAssets);
        emit log_named_uint("FREE LIQUIDITY (AUSD 1e6)", free);

        address atk = address(0xB0B);
        _fund(atk, 100e18);
        vm.startPrank(atk);
        IERC20(SPYX).approve(WSPYX, type(uint256).max);
        uint256 shares = IERC4626(WSPYX).deposit(100e18, atk);
        IERC4626(WSPYX).approve(MORPHO, type(uint256).max);
        IMorpho(MORPHO).supplyCollateral(mp, shares, atk, "");
        // 1 wei more than the free liquidity must revert
        vm.expectRevert();
        IMorpho(MORPHO).borrow(mp, free + 1, 0, atk, atk);
        // exactly the free liquidity succeeds -> that is the hard cap
        (uint256 assets,) = IMorpho(MORPHO).borrow(mp, free, 0, atk, atk);
        vm.stopPrank();
        assertEq(assets, free);
        assertEq(IERC20(AUSD).balanceOf(atk), free);
        emit log_named_uint("attacker borrowed AUSD (1e6)", assets);
    }

    // ------------------------------------------------------------- D. attack is net-negative
    /// @notice Concrete attack: mint `coll` SPYx of collateral, donate `don` SPYx to inflate the
    ///         oracle, supply, borrow the max, then default. Net is measured against the true
    ///         capital spent. The donation is strictly value-destructive for the attacker.
    function _attack(uint256 coll, uint256 don) internal returns (int256 netUsd, uint256 borrowed) {
        uint256 snap = vm.snapshot();
        {
            IMorpho.MarketParams memory mp = _mp();
            address atk = address(uint160(0xCAFE0000 + coll + don));
            _fund(atk, coll + don);
            vm.startPrank(atk);
            IERC20(SPYX).approve(WSPYX, type(uint256).max);
            uint256 shares = IERC4626(WSPYX).deposit(coll, atk);
            if (don > 0) {
                IERC20(SPYX).transfer(WSPYX, don); // donation -> inflate convertToAssets
            }
            IERC4626(WSPYX).approve(MORPHO, type(uint256).max);
            IMorpho(MORPHO).supplyCollateral(mp, shares, atk, "");
            uint256 tryBorrow = uint256(IMorpho(MORPHO).market(MID).totalSupplyAssets)
                - uint256(IMorpho(MORPHO).market(MID).totalBorrowAssets);
            // borrow the maximum the market allows (capacity vs free liquidity)
            while (tryBorrow > 0) {
                try IMorpho(MORPHO).borrow(mp, tryBorrow, 0, atk, atk) returns (uint256 a, uint256) {
                    borrowed = a;
                    break;
                } catch {
                    tryBorrow = tryBorrow * 99 / 100;
                }
            }
            vm.stopPrank();
        }
        // net USD (1e18): borrowed AUSD (=$1, 6dp) - (coll+don) SPYx * spyUsd
        netUsd = int256(borrowed) * 1e12 - int256(coll + don) * int256(_spyUsd1e8()) / 1e8;
        vm.revertTo(snap);
    }

    function test_D_attackWithoutDonationNetNegative() public {
        (int256 net, uint256 borrowed) = _attack(2e18, 0);
        emit log_named_uint("borrowed AUSD (1e6)", borrowed);
        emit log_named_int("net USD (1e18)", net);
        assertLt(net, 0, "borrow-and-default without inflation loses the LLTV haircut");
    }

    function test_D2_attackWithDonationIsStrictlyWorse() public {
        (int256 net0,) = _attack(2e18, 0);
        (int256 net1,) = _attack(2e18, 668e18); // ~double the price (donate ~one vault of SPYx)
        emit log_named_int("net USD no-donation (1e18)", net0);
        emit log_named_int("net USD with 668 SPYx donation (1e18)", net1);
        assertLt(net1, net0, "donation strictly worsens the attacker's net");
    }

    function test_D3_sweepAllAttacksNegative() public {
        uint256[5] memory colls = [uint256(1e18), 2e18, 5e18, 50e18, 200e18];
        uint256[5] memory dons = [uint256(0), 10e18, 100e18, 400e18, 668e18];
        int256 best = type(int256).min;
        for (uint256 i = 0; i < colls.length; i++) {
            for (uint256 j = 0; j < dons.length; j++) {
                (int256 net, uint256 borrowed) = _attack(colls[i], dons[j]);
                if (net > best) best = net;
                emit log_named_uint("coll (wei)", colls[i]);
                emit log_named_uint("don (wei)", dons[j]);
                emit log_named_uint("borrowed (1e6)", borrowed);
                emit log_named_int("net USD (1e18)", net);
            }
        }
        emit log_named_int("BEST (max) net USD across sweep (1e18)", best);
        assertLt(best, 0, "no (collateral, donation) combination is profitable");
    }
}
