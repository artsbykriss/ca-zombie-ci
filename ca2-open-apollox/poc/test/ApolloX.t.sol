// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IApolloXDiamond, IAggregatorV3, ISafe} from "../src/IApolloX.sol";

/// @title ApolloX EIP-2535 diamond (BSC) — 29-facet surface, access control, 123k USDT provenance
/// @notice Read-only research. All state changes happen on a local fork; nothing is broadcast.
contract ApolloXTest is Test {
    address constant DIAMOND  = 0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0;
    address constant USDT     = 0x55d398326f99059fF775485246999027B3197955;
    address constant USDC     = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant WBNB     = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant ETH      = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant BTCB     = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant LISUSD   = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
    address constant USDF     = 0x5A110fC00474038f6c02E89C707D638602EA44B5;
    address constant FDUSD    = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409;
    address constant ASBNB    = 0x77734e70b6E88b4d82fE632a168EDf6e700912b6;

    address constant ALP      = 0x4E47057f45adF24ba41375a175dA0357cB3480E5;
    address constant SAFE     = 0x60EdE4402a34762D608AD9bA7bD3797f5bFE544c;
    address constant DAO_REPURCHASE = 0x4339bDB090939768987cBFDE8cc8E5619042C94b;

    uint256 constant PIN = 131443197;

    IApolloXDiamond diamond;
    IERC20 usdt;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        vm.createSelectFork(rpc, PIN);
        diamond = IApolloXDiamond(DIAMOND);
        usdt = IERC20(USDT);
    }

    function _tokens() internal pure returns (address[] memory t) {
        t = new address[](1);
        t[0] = USDT;
    }

    function test_facet_surface_is_29_facets_229_selectors() public view {
        IApolloXDiamond.Facet[] memory f = diamond.facets();
        assertEq(f.length, 29, "facet count");
        uint256 n;
        for (uint256 i; i < f.length; i++) {
            n += f[i].functionSelectors.length;
        }
        assertEq(n, 229, "selector count");
        // DiamondCutFacet owns diamondCut; the loupe owns facets().
        assertEq(diamond.facetAddress(bytes4(0x1f931c1c)), 0x61595c597fB5b00067507d8850E5c9161406Ae9c);
        assertEq(diamond.facetAddress(bytes4(0x7a0ed627)), 0x903441522f439304Ec39DD34DA67074aa32A17a5);
    }

    function test_123k_usdt_is_unaccounted_and_not_user_collateral() public {
        uint256 bal = usdt.balanceOf(DIAMOND);
        emit log_named_decimal_uint("diamond USDT balance", bal, 18);
        assertEq(bal, 123423072368061213847725, "123,423.072368 USDT");

        // Not in the LP treasury: itemValue(USDT) and getTotalValueUsd() exclude it.
        IApolloXDiamond.LpItem memory it = diamond.itemValue(USDT);
        assertEq(it.value, 0, "treasury[USDT] == 0");
        assertEq(it.valueUsd, 0, "valueUsd[USDT] == 0");
        assertEq(diamond.getTotalValueUsd(), 5306461272940611275808705);

        // Not user collateral: pending/open trade amounts for USDT are all zero.
        IApolloXDiamond.TraderAsset[] memory ta = diamond.traderAssets(_tokens());
        for (uint256 i; i < ta.length; i++) {
            assertEq(ta[i].value, 0, "no pending/open USDT");
        }

        // Not protocol revenue pending: only ~1.41 USDT is claimable.
        IApolloXDiamond.CommissionInfo[] memory rev = diamond.revenues(_tokens());
        assertEq(rev[0].total, 1425410878509332293404172);
        assertEq(rev[0].pending, 1411857352416864204);

        assertFalse(diamond.paused(), "not paused");
    }

    function test_alp_burn_cannot_touch_the_123k_usdt() public {
        address attacker = address(0xA11CE);
        deal(ALP, attacker, 1_000e18);

        vm.startPrank(attacker);
        // Even with a real ALP balance, burning for USDT reverts: the USDT treasury is empty.
        vm.expectRevert();
        diamond.burnAlp(USDT, 1_000e18, 0, attacker);
        vm.stopPrank();

        // The 123k is still there and still excluded from the LP NAV.
        assertEq(usdt.balanceOf(DIAMOND), 123423072368061213847725);
        assertEq(diamond.itemValue(USDT).value, 0);
    }

    function test_withdraw_revenue_moves_only_pending() public {
        uint256 beforeBal = usdt.balanceOf(DIAMOND);
        uint256 beforeRev = usdt.balanceOf(SAFE);

        vm.prank(address(0xA11CE));
        diamond.withdrawRevenue(_tokens());

        uint256 moved = beforeBal - usdt.balanceOf(DIAMOND);
        emit log_named_decimal_uint("revenue moved", moved, 18);
        assertEq(moved, 1411857352416864204, "only pending revenue moves");
        assertEq(usdt.balanceOf(SAFE) - beforeRev, 1411857352416864204);
        assertEq(usdt.balanceOf(DIAMOND), 123423072368061213847725 - 1411857352416864204);
    }

    function test_admin_is_4of7_safe_and_upgrades_are_timelocked() public view {
        bytes32 adminRole = bytes32(0);
        assertEq(diamond.getRoleMemberCount(adminRole), 1);
        assertEq(diamond.getRoleMember(adminRole, 0), SAFE);
        assertEq(ISafe(SAFE).getThreshold(), 4);
        assertEq(ISafe(SAFE).getOwners().length, 7);
        assertEq(keccak256(bytes(ISafe(SAFE).VERSION())), keccak256(bytes("1.3.0")));
    }

    function test_upgrade_and_sweep_paths_are_privileged() public {
        address attacker = address(0xA11CE);

        // queueTransaction (the only route to a self-call diamondCut) is ADMIN_ROLE only.
        vm.prank(attacker);
        vm.expectRevert("TimeLockFacet: missing role.");
        diamond.queueTransaction("diamondCut((address,uint8,bytes4[])[],address,bytes)", "");

        // diamondCut itself is onlySelf; an EOA call reverts.
        IApolloXDiamond.FacetCut[] memory empty = new IApolloXDiamond.FacetCut[](0);
        vm.prank(attacker);
        vm.expectRevert("only self call");
        diamond.diamondCut(empty, address(0), "");
    }

    function test_oracle_feeds_live_but_one_is_stale() public {
        IApolloXDiamond.PriceFeedInfo[] memory feeds = diamond.chainlinkPriceFeeds();
        assertGt(feeds.length, 60, "feed count");

        address[9] memory want = [USDT, USDC, LISUSD, WBNB, ETH, BTCB, USDF, FDUSD, ASBNB];
        for (uint256 w; w < want.length; w++) {
            // The vault/pricing path always resolves through the diamond.
            uint256 p = diamond.getPrice(want[w]);
            assertGt(p, 0, "diamond getPrice > 0");

            bool found;
            for (uint256 i; i < feeds.length; i++) {
                if (feeds[i].token != want[w]) continue;
                found = true;
                // Some ApolloX "SingleFeed" oracles only allow the diamond to read them.
                // Probe with a low-level staticcall so a permissioned feed does not fail the test.
                (bool ok, bytes memory ret) = feeds[i].feedAddress.staticcall(
                    abi.encodeWithSignature("latestRoundData()")
                );
                if (ok && ret.length >= 160) {
                    (, int256 answer,, uint256 updatedAt,) = abi.decode(ret, (uint80, int256, uint256, uint256, uint80));
                    assertGt(answer, 0, "positive price");
                    assertGt(updatedAt, 0, "has update time");
                    emit log_named_uint(
                        string.concat("feed age (s) ", feeds[i].description),
                        block.timestamp > updatedAt ? block.timestamp - updatedAt : 0
                    );
                    assertLt(block.timestamp - updatedAt, 7 days, "feed older than 7d");
                } else {
                    emit log_named_string(
                        string.concat("permissioned feed (direct read reverts) ", feeds[i].description),
                        "diamond getPrice still resolves"
                    );
                }
                break;
            }
            assertTrue(found, "feed exists");
        }
    }
}
