// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

/// FermiSwap (Ethereum) — Z3-H16 zombie-hunt PoC. READ-ONLY: fork tests only, no mainnet txs.
///
/// Finding hypothesis (corpus): "swap pricing reads the contract's own inventory" =>
/// donation/sandwich-manipulable quote. This suite tests that claim against the live system
/// and measures every unprivileged extraction path.
///
/// Live architecture (established via on-chain reads + callTracer):
///   user/solver -> FermiSwapper(0x5979458912) -> FermiEngine(0x0109AA91) -> price feed lane
///   price: updater-posted 8dp value per lane, valid ONLY in the block of its update ("unlocked")
///   inventory: engine reads vault balanceOf(tokenOut) as an output CAP (not as price)
///   vault: BaseManager treasury; manager-gated withdrawals; MAX allowances to swapper + 2 arb executors

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function deposit() external payable;
}

interface IFermiEngine {
    function quote(address, address, int256, address) external view returns (uint256, uint256);
    function swap(address, address, int256, address) external returns (uint256, uint256);
    function unlocked(address, address) external view returns (bool);
    function traderVault() external view returns (address);
    function swapper() external view returns (address);
}

interface IFermiSwapper {
    function fermiSwapWithAllowances(address, address, int256, uint256, address)
        external
        returns (uint256, uint256);
    function fermi() external view returns (address);
    function traderVault() external view returns (address);
}

interface IPrioRegistry {
    function updateState(address, uint256, uint32, uint256[] calldata) external;
    function isUpdater(address, address) external view returns (bool);
    function getState(uint256, uint32, uint32) external view returns (uint32, uint256[] memory);
    function MAX_UPDATE_AGE() external view returns (uint256);
    function MAX_UPDATE_LEAD_TIME() external view returns (uint256);
}

interface IVault {
    function withdrawAllTokens(address[] calldata) external;
    function transferToken(address, uint256) external;
    function executeGeneral(address, bytes calldata) external returns (bool, bytes memory);
}

contract FermiPoC is Test {
    // ===== live addresses (verified on-chain, Oct 2026) =====
    address constant VAULT = 0x585d44727129B9C69791B10238Ca605932938B4F; // traderVault inventory
    address constant SWAP1 = 0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e; // old FermiSwapper (allowances 0)
    address constant SWAP2 = 0x5979458912F80B96d30D4220af8E2e4925A33320; // new FermiSwapper (MAX allowances)
    address constant E3 = 0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f; // engine v20260720 (registry-fed)
    address constant E4 = 0x0109AA912B58508886a2a707204B0F8C8b164CCc; // engine v20260907 (internal prices)
    address constant REG = 0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F; // PrioUpdateRegistry
    address constant ARB1 = 0xB4723899a492330fedACcf22ec12F53A06e3B659; // trader-gated arb executor
    address constant ARB2 = 0xeff407D968de7d312Fd5e036AEf8837b3679d777; // trader-gated arb executor

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    // lane (price-feed id) for WETH/USDC + its dedicated provider
    uint256 constant LANE_WETH_USDC = 0x2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46;
    uint256 constant LANE_WETH_USDT = 0x1f160fb6b5eff44c72397d5a5dca127da716ebbf5efe6a024a6a09031fb359f4;
    address constant UPD_WETH_USDC = 0x14E870f0A7C764Ca71289952006D6bf130058927;
    address constant UPD3 = 0x69939a6C590C9cd0Bf8EFBe9b3df2cDAC4A4906B; // engine3 registry updater

    bytes4 constant SEL_POST_PRICE = 0xacee8aab; // engine4: postPrice(lane, price8dp), gated "NP"

    // historical arb-executor route calldata (replay must revert "NT")
    bytes constant ARB1_SAMPLE =
        hex"00000000e0554a476a092703abdb3ef35c80e0d76d32939f00c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000007256d40f229396900000000000000000000000000000000000051315809a5d744000000000000000000000000000000000000000000000000005130c43d5371f80000000000000000000000017cae4100000000000000000000000000000000000000000000000000000ede3319a72c";
    bytes constant ARB2_SAMPLE =
        hex"000000000000000000000000000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f400000a0100000000000000000fdb161db43aea1a0000000000000000000369a7d17da004400000000000000000000000000369b2484b0f7e4000000000000000018ec48600000000000000000000000000000000000000000000000000004573214196a5";

    address attacker = makeAddr("attacker");
    uint256 forkBlock;

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")))
        );
        forkBlock = block.number;
    }

    // ------------------------------------------------------------------
    // T1: live state snapshot (inventory + loaded allowances + feed locks)
    // ------------------------------------------------------------------
    function test_T1_live_state_snapshot() public {
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("vault WETH", IERC20(WETH).balanceOf(VAULT));
        emit log_named_uint("vault USDC", IERC20(USDC).balanceOf(VAULT));
        emit log_named_uint("vault USDT", IERC20(USDT).balanceOf(VAULT));
        emit log_named_uint("vault WBTC", IERC20(WBTC).balanceOf(VAULT));
        emit log_named_uint("vault cbBTC", IERC20(CBBTC).balanceOf(VAULT));
        assertGt(IERC20(WETH).balanceOf(VAULT), 100 ether, "vault WETH > 100");
        assertGt(IERC20(USDC).balanceOf(VAULT), 100_000e6, "vault USDC > 100k");

        uint256 max = type(uint256).max;
        uint256 huge = 1e30;
        // loaded allowances: new swapper + 2 arb executors (consume slowly as the desk trades)
        assertGt(IERC20(WETH).allowance(VAULT, SWAP2), huge, "WETH->SWAP2 ~MAX");
        assertGt(IERC20(USDC).allowance(VAULT, SWAP2), huge, "USDC->SWAP2 ~MAX");
        assertGt(IERC20(USDT).allowance(VAULT, SWAP2), huge, "USDT->SWAP2 ~MAX");
        assertGt(IERC20(WBTC).allowance(VAULT, SWAP2), huge, "WBTC->SWAP2 ~MAX");
        assertGt(IERC20(CBBTC).allowance(VAULT, SWAP2), huge, "cbBTC->SWAP2 ~MAX");
        assertGt(IERC20(WETH).allowance(VAULT, ARB1), huge, "WETH->ARB1 ~MAX");
        assertGt(IERC20(WBTC).allowance(VAULT, ARB1), huge, "WBTC->ARB1 ~MAX");
        assertGt(IERC20(WETH).allowance(VAULT, ARB2), huge, "WETH->ARB2 ~MAX");
        assertGt(IERC20(USDC).allowance(VAULT, ARB2), huge, "USDC->ARB2 ~MAX");
        max; // silence unused
        assertEq(IERC20(WETH).allowance(VAULT, SWAP1), 0, "WETH->SWAP1 = 0");
        assertEq(IERC20(USDC).allowance(VAULT, SWAP1), 0, "USDC->SWAP1 = 0");

        emit log_named_string("engine4 unlocked(WETH,USDC)", IFermiEngine(E4).unlocked(WETH, USDC) ? "true" : "false");
        emit log_named_string("engine4 unlocked(WETH,USDT)", IFermiEngine(E4).unlocked(WETH, USDT) ? "true" : "false");
        emit log_named_string("engine4 unlocked(WBTC,USDC)", IFermiEngine(E4).unlocked(WBTC, USDC) ? "true" : "false");
        // registry staleness windows (engine3 side)
        emit log_named_uint("registry MAX_UPDATE_AGE", IPrioRegistry(REG).MAX_UPDATE_AGE());
        emit log_named_uint("registry MAX_UPDATE_LEAD_TIME", IPrioRegistry(REG).MAX_UPDATE_LEAD_TIME());
    }

    // ------------------------------------------------------------------
    // T2: no fresh update in the fork block => permissionless swap reverts "SP"
    // ------------------------------------------------------------------
    function test_T2_swap_reverts_when_pair_locked() public {
        // walk back to a block whose block.timestamp had no engine4 update for the lane
        uint256 b = block.number;
        for (uint256 i = 0; i < 40; i++) {
            vm.rollFork(b - i);
            if (!IFermiEngine(E4).unlocked(WETH, USDC)) break;
        }
        assertFalse(IFermiEngine(E4).unlocked(WETH, USDC), "found locked block");
        emit log_named_uint("locked test block", block.number);

        vm.deal(attacker, 2 ether);
        vm.startPrank(attacker);
        IERC20(WETH).deposit{value: 1 ether}();
        IERC20(WETH).approve(SWAP2, 1 ether);
        vm.expectRevert(bytes("SP"));
        IFermiSwapper(SWAP2).fermiSwapWithAllowances(WETH, USDC, 1 ether, 0, attacker);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // T3: old swapper path — even with a fresh registry lane it stays blocked
    //     (vault allowance to SWAP1 == 0)
    // ------------------------------------------------------------------
    function test_T3_old_swapper_fresh_price_still_blocked() public {
        assertTrue(IPrioRegistry(REG).isUpdater(E3, UPD3), "engine3 updater live");
        uint256[] memory slots = new uint256[](1);
        slots[0] = 242770000000;
        vm.prank(UPD3);
        IPrioRegistry(REG).updateState(E3, LANE_WETH_USDC, uint32(block.timestamp), slots);
        // read as the engine (lanes are msg.sender-scoped)
        vm.prank(E3);
        (uint32 ts,) = IPrioRegistry(REG).getState(LANE_WETH_USDC, uint32(block.timestamp), uint32(block.timestamp));
        emit log_named_uint("lane ts after updater write", ts);
        assertEq(uint256(ts), block.timestamp, "lane fresh");

        vm.deal(attacker, 2 ether);
        vm.startPrank(attacker);
        IERC20(WETH).deposit{value: 1 ether}();
        IERC20(WETH).approve(SWAP1, 1 ether);
        (bool ok, bytes memory reason) = address(SWAP1).call(
            abi.encodeWithSelector(
                IFermiSwapper.fermiSwapWithAllowances.selector, WETH, USDC, int256(1 ether), uint256(0), attacker
            )
        );
        emit log_named_bytes("old swapper w/ fresh price", reason);
        assertFalse(ok, "blocked: vault allowance to SWAP1 is 0");
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // T4: attacker cannot post a price on engine4 (provider-gated "NP")
    // ------------------------------------------------------------------
    function test_T4_engine4_price_post_gated() public {
        vm.prank(attacker);
        (bool ok, bytes memory reason) = E4.call(abi.encodeWithSelector(SEL_POST_PRICE, LANE_WETH_USDC, uint256(242770000000)));
        emit log_named_bytes("engine4 postPrice from attacker", reason);
        assertFalse(ok, "must revert");
        assertEq(_revertString(reason), "NP", "gate = NP");
    }

    // ------------------------------------------------------------------
    // T5: attacker cannot write the engine3 registry lane (NotAuthorized)
    // ------------------------------------------------------------------
    function test_T5_registry_write_gated() public {
        assertFalse(IPrioRegistry(REG).isUpdater(E3, attacker), "attacker not updater");
        uint256[] memory slots = new uint256[](1);
        slots[0] = 242770000000;
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        IPrioRegistry(REG).updateState(E3, LANE_WETH_USDC, uint32(block.timestamp), slots);
    }

    // ------------------------------------------------------------------
    // T6: attacker cannot call the arb executors (trader-gated "NT")
    // ------------------------------------------------------------------
    function test_T6_arb_executors_gated() public {
        vm.prank(attacker);
        (bool ok1, bytes memory r1) = ARB1.call(ARB1_SAMPLE);
        emit log_named_bytes("ARB1 revert", r1);
        assertFalse(ok1, "ARB1 must revert");
        assertEq(_revertString(r1), "NT", "ARB1 gate = NT");

        vm.prank(attacker);
        (bool ok2, bytes memory r2) = ARB2.call(ARB2_SAMPLE);
        emit log_named_bytes("ARB2 revert", r2);
        assertFalse(ok2, "ARB2 must revert");
        assertEq(_revertString(r2), "NT", "ARB2 gate = NT");
    }

    // ------------------------------------------------------------------
    // T7: attacker cannot withdraw from the vault (manager-gated "NM")
    // ------------------------------------------------------------------
    function test_T7_vault_withdraw_gated() public {
        address[] memory toks = new address[](1);
        toks[0] = WETH;
        vm.prank(attacker);
        vm.expectRevert(bytes("NM"));
        IVault(VAULT).withdrawAllTokens(toks);

        vm.prank(attacker);
        vm.expectRevert(bytes("NM"));
        IVault(VAULT).transferToken(WETH, 1);

        vm.prank(attacker);
        vm.expectRevert(bytes("NM"));
        IVault(VAULT).executeGeneral(WETH, abi.encodeWithSignature("transfer(address,uint256)", attacker, 1));
    }

    // ------------------------------------------------------------------
    // T8: QUOTE MATH — donation does NOT move the price (refutes the corpus
    //     "inventory-priced / donation-manipulable" hypothesis)
    // ------------------------------------------------------------------
    function test_T8_donation_does_not_move_quote() public {
        _unlockRealistic();

        (uint256 inA, uint256 outA) = IFermiEngine(E4).quote(WETH, USDC, int256(1 ether), attacker);
        emit log_named_uint("quote before donation: in", inA);
        emit log_named_uint("quote before donation: out", outA);

        // donate BOTH the output asset (USDC) and the input asset (WETH) to the vault
        deal(USDC, attacker, 1_000_000e6);
        vm.deal(attacker, 10 ether);
        vm.startPrank(attacker);
        IERC20(USDC).transfer(VAULT, 1_000_000e6);
        IERC20(WETH).deposit{value: 10 ether}();
        IERC20(WETH).transfer(VAULT, 10 ether);
        vm.stopPrank();

        (uint256 inB, uint256 outB) = IFermiEngine(E4).quote(WETH, USDC, int256(1 ether), attacker);
        emit log_named_uint("quote after donation: in", inB);
        emit log_named_uint("quote after donation: out", outB);
        assertEq(inA, inB, "input quote unchanged by donation");
        // Measured sensitivity: +1M USDC donation shifts a 1 WETH quote by ~+0.003%.
        // Bound it hard: donation of 40% of the vault's USDC balance must move the quote
        // by <0.01% (economically dead: donation is unrecoverable, gain/cost ~1e-7).
        uint256 delta = outB > outA ? outB - outA : outA - outB;
        emit log_named_uint("abs quote delta", delta);
        assertLt(delta, outA / 10_000, "donation impact < 0.01% (not exploitable)");
    }

    // ------------------------------------------------------------------
    // T9: QUOTE MATH — no same-block price impact (no sandwich surface):
    //     a large swap does not move the quote for the next swap in the block
    // ------------------------------------------------------------------
    function test_T9_no_same_block_price_impact() public {
        _unlockRealistic();
        (uint256 inA, uint256 outA) = IFermiEngine(E4).quote(WETH, USDC, int256(1 ether), attacker);

        // large swap first (10 WETH)
        vm.deal(attacker, 12 ether);
        vm.startPrank(attacker);
        IERC20(WETH).deposit{value: 10 ether}();
        IERC20(WETH).approve(SWAP2, 10 ether);
        (, uint256 bigOut) = IFermiSwapper(SWAP2).fermiSwapWithAllowances(WETH, USDC, 10 ether, 0, attacker);
        vm.stopPrank();
        emit log_named_uint("big swap out (10 WETH)", bigOut);

        (uint256 inB, uint256 outB) = IFermiEngine(E4).quote(WETH, USDC, int256(1 ether), attacker);
        assertEq(inA, inB, "input quote unchanged after big swap");
        // Same-block price impact must be negligible (no depletion, no sandwich surface).
        uint256 delta = outB > outA ? outB - outA : outA - outB;
        emit log_named_uint("quote delta after 10 WETH swap", delta);
        assertLt(delta, outA / 10_000, "same-block impact < 0.01% (no sandwich surface)");
    }

    // ------------------------------------------------------------------
    // T10: RE-ARM — an authorized provider unlocks the pair and the vault pays
    //      at the posted price (legit flow, quantified)
    // ------------------------------------------------------------------
    function test_T10_rearm_updater_unlocks_and_vault_pays() public {
        uint256 price = 242770000000; // $2,427.70/WETH at 8dp
        assertTrue(_postPrice(LANE_WETH_USDC, price), "provider price post ok");
        assertTrue(IFermiEngine(E4).unlocked(WETH, USDC), "unlocked after provider post");

        vm.deal(attacker, 2 ether);
        vm.startPrank(attacker);
        IERC20(WETH).deposit{value: 1 ether}();
        IERC20(WETH).approve(SWAP2, 1 ether);
        uint256 usdcBefore = IERC20(USDC).balanceOf(attacker);
        uint256 vaultUsdcBefore = IERC20(USDC).balanceOf(VAULT);
        (uint256 amountIn, uint256 amountOut) =
            IFermiSwapper(SWAP2).fermiSwapWithAllowances(WETH, USDC, 1 ether, 0, attacker);
        vm.stopPrank();
        emit log_named_uint("swap in (WETH)", amountIn);
        emit log_named_uint("swap out (USDC)", amountOut);
        emit log_named_uint("effective price 8dp", (amountOut * 1e18) / amountIn);
        emit log_named_uint("attacker USDC delta", IERC20(USDC).balanceOf(attacker) - usdcBefore);
        emit log_named_uint("vault USDC delta", vaultUsdcBefore - IERC20(USDC).balanceOf(VAULT));
        assertGt(amountOut, 0, "vault paid out");
        assertEq(amountIn, 1 ether, "1 WETH in");
        assertEq(IERC20(USDC).balanceOf(attacker) - usdcBefore, amountOut, "recipient paid exactly amountOut");
    }

    // ------------------------------------------------------------------
    // T11: RE-ARM CEILING — provider posts an arbitrary (manipulated) price:
    //      measure how much one block can extract (latent, requires provider key)
    // ------------------------------------------------------------------
    function test_T11_rearm_manipulated_price_ceiling() public {
        uint256 absurdPrice = 1e15; // $10,000,000/WETH at 8dp — expected to trip the "PB" band
        assertTrue(_postPrice(LANE_WETH_USDC, absurdPrice), "provider price post ok");

        uint256 vaultUsdcStart = IERC20(USDC).balanceOf(VAULT);
        uint256[4] memory sizes = [uint256(0.25 ether), 1 ether, 10 ether, 100 ether];
        uint256 totalOut;
        for (uint256 i = 0; i < sizes.length; i++) {
            vm.deal(attacker, sizes[i] + 1);
            vm.startPrank(attacker);
            IERC20(WETH).deposit{value: sizes[i]}();
            IERC20(WETH).approve(SWAP2, sizes[i]);
            try IFermiSwapper(SWAP2).fermiSwapWithAllowances(WETH, USDC, int256(sizes[i]), 0, attacker) returns (
                uint256 amountIn, uint256 amountOut
            ) {
                emit log_named_uint("size WETH", sizes[i]);
                emit log_named_uint("  in", amountIn);
                emit log_named_uint("  out USDC", amountOut);
                totalOut += amountOut;
            } catch (bytes memory reason) {
                emit log_named_uint("size WETH", sizes[i]);
                emit log_named_bytes("  reverted", reason);
            }
            vm.stopPrank();
        }
        uint256 vaultUsdcEnd = IERC20(USDC).balanceOf(VAULT);
        emit log_named_uint("vault USDC start", vaultUsdcStart);
        emit log_named_uint("vault USDC end", vaultUsdcEnd);
        emit log_named_uint("total USDC extracted by attacker", totalOut);
        assertEq(vaultUsdcStart - vaultUsdcEnd, totalOut, "vault loss == attacker gain");
    }

    // ------------------------------------------------------------------
    // T12: unprivileged live probe — can the attacker swap WITHOUT a provider key
    //      in the fork block? (only if an update landed in that exact block)
    // ------------------------------------------------------------------
    function test_T12_unprivileged_live_probe() public {
        bool live = IFermiEngine(E4).unlocked(WETH, USDC);
        emit log_named_string("unlocked at fork block", live ? "true" : "false");
        vm.deal(attacker, 2 ether);
        vm.startPrank(attacker);
        IERC20(WETH).deposit{value: 1 ether}();
        IERC20(WETH).approve(SWAP2, 1 ether);
        try IFermiSwapper(SWAP2).fermiSwapWithAllowances(WETH, USDC, 1 ether, 0, attacker) returns (
            uint256 amountIn, uint256 amountOut
        ) {
            emit log_named_uint("UNPRIVILEGED swap succeeded: in", amountIn);
            emit log_named_uint("UNPRIVILEGED swap succeeded: out USDC", amountOut);
            emit log_named_uint("effective price 8dp", (amountOut * 1e18) / amountIn);
            assertTrue(live, "swap worked only because an update landed this block");
        } catch (bytes memory reason) {
            emit log_named_bytes("swap reverted", reason);
            assertFalse(live, "revert expected when locked");
            assertEq(_revertString(reason), "SP", "gate = SP");
        }
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
    function _unlockRealistic() internal {
        require(_postPrice(LANE_WETH_USDC, 242770000000), "price post failed");
        require(IFermiEngine(E4).unlocked(WETH, USDC), "not unlocked");
    }

    /// @dev any authorized provider can post for any registered lane; try the known set
    function _postPrice(uint256 lane, uint256 price) internal returns (bool) {
        address[8] memory ups = [
            0x14E870f0A7C764Ca71289952006D6bf130058927,
            0xfc42bE9494F1Af6b03AdAd71811c62aDa2D6f3c3,
            0x14ffd5D4f0C48e3e79D8346B85917e092b0C52d2,
            0x47667E5C897DfdE871b4833f4Ae7DEF39526E897,
            0x842089E53568804579AD9e31296Ef723aa5DD29b,
            0xd6d3C12e9FB4838f55F9CC531c42af246de82A07,
            0x70A387e68831c67b9759Ea1bBF383802e67B08Fb,
            0x216624013844cCbE5A1d27eF0515cEC02C91BB25
        ];
        for (uint256 i = 0; i < ups.length; i++) {
            vm.prank(ups[i]);
            (bool ok,) = E4.call(abi.encodeWithSelector(SEL_POST_PRICE, lane, price));
            if (ok) return true;
        }
        return false;
    }

    function _revertString(bytes memory data) internal pure returns (string memory) {
        // Error(string) = 0x08c379a0 | offset | len | data...
        if (data.length < 68) return "";
        uint256 len;
        assembly {
            len := mload(add(data, 68))
        }
        bytes memory out = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            out[i] = data[i + 68];
        }
        return string(out);
    }
}
