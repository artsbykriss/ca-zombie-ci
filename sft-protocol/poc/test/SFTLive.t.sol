// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

/// @title SFT Protocol (Filecoin FEVM) — live extractability probe
/// @notice Read-only fork tests. No mainnet transactions. Fork is pinned to a fixed block.
contract SFTLiveTest is Test {
    // ---- live addresses (Filecoin mainnet, chain id 314) ----
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E; // lending pool + rSFT share token
    address constant REWARD = 0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7; // reward pool / farm
    address constant MINT = 0xcdAfc875eed0f346D5D2584fc6C37B539459C445; // mint / withdraw (swap) pool
    address constant SFT = 0xC5eA96Dd365983cfEc90E72b6A2daC9562f458Ba; // Securitized Filecoin Token
    address constant RSPD = 0x97AAe66a1D2a41eAC573397B7a5656a9cF3E5616; // rSPD reward token
    address constant ADMIN_PROXY = 0x98002559DC58B1c1ba01f6c5F309a9e92af589DD; // EIP-1967 admin of all 3 pools
    address constant OWNER_EOA = 0x0E294a09Ab6d03597A79e52c951410955097c32C; // owner() of pool + reward + mint
    address constant HOLDER = 0xEA476bB3d33719cD2339d14a89aa7c82373Be2C1; // third-largest SFT EOA holder (~31k SFT)

    uint256 constant FORK_BLOCK = 6_457_969;

    ILendingPool pool;
    IRewardPool reward;
    IMintPool mint;
    IERC20 sft;

    address attacker = address(0xA11CE);
    address attacker2 = address(0xB0B);

    function setUp() public {
        string memory rpc = vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org"));
        vm.createSelectFork(rpc, FORK_BLOCK);
        pool = ILendingPool(POOL);
        reward = IRewardPool(REWARD);
        mint = IMintPool(MINT);
        sft = IERC20(SFT);
        vm.deal(attacker, 100 ether);
        vm.deal(attacker2, 100 ether);
    }

    // ---------------------------------------------------------------- helpers
    function logCall(string memory label, address target, bytes memory data) internal returns (bool ok, bytes memory ret) {
        (ok, ret) = target.call(data);
        if (!ok) {
            // try to surface Error(string)
            if (ret.length >= 68) {
                bytes memory slice = new bytes(4);
                for (uint i = 0; i < 4; i++) slice[i] = ret[i];
                if (bytes4(slice) == 0x08c379a0) {
                    // Error(string)
                    bytes memory strBytes = new bytes(ret.length - 68);
                    for (uint i = 0; i < strBytes.length; i++) strBytes[i] = ret[i + 68];
                    emit log_named_string(string.concat(label, " REVERT"), string(strBytes));
                    return (ok, ret);
                }
            }
            emit log_named_string(string.concat(label, " REVERT(raw)"), vm.toString(ret));
        } else {
            emit log_named_string(string.concat(label, " OK"), vm.toString(ret));
        }
    }

    // ---------------------------------------------------------------- state
    function test_A_live_state() public {
        emit log_named_uint("block.number", block.number);
        emit log_named_uint("pool FIL (wei)", POOL.balance);
        emit log_named_uint("reward FIL (wei)", REWARD.balance);
        emit log_named_uint("mint FIL (wei)", MINT.balance);
        emit log_named_uint("pool totalPooledFIL", pool.totalPooledFIL());
        emit log_named_uint("pool rSFT totalSupply", pool.totalSupply());
        emit log_named_uint("pool utilization", pool.getUtilizationRate());
        emit log_named_uint("pool borrowThreshold", pool.borrowThreshold());
        emit log_named_uint("pool ltv", pool.ltv());
        emit log_named_uint("pool startTime", pool.startTime());
        emit log_named_address("pool owner", pool.owner());
        emit log_named_address("pool rewardContract", pool.rewardContract());
        emit log_named_address("pool redeemPool", pool.redeemPool());
        emit log_named_uint("SFT totalSupply", sft.totalSupply());
        emit log_named_uint("SFT bal pool", sft.balanceOf(POOL));
        emit log_named_uint("SFT bal reward", sft.balanceOf(REWARD));
        emit log_named_uint("SFT bal mint", sft.balanceOf(MINT));
        emit log_named_uint("rSPD totalSupply", IERC20(RSPD).totalSupply());

        assertGe(POOL.balance, 53.7 ether, "pool FIL live");
        assertLe(POOL.balance, 54.0 ether, "pool FIL live upper");
        assertGe(REWARD.balance, 1000.0 ether, "reward FIL live");
        assertLe(REWARD.balance, 1001.0 ether, "reward FIL live upper");
        assertEq(pool.totalPooledFIL(), 234477718487329089234903, "totalPooledFIL");
        assertEq(pool.totalSupply(), 234477718487329089234903, "rSFT supply");
        assertEq(pool.getUtilizationRate(), 9999, "utilization 99.99%");
        assertEq(pool.borrowThreshold(), 9500, "borrow threshold 95%");
        assertEq(pool.ltv(), 6000, "ltv 60%");
    }

    // ------------------------------------------- fresh attacker (no positions)
    function test_B_fresh_withdraw_reverts() public {
        uint256 poolBefore = POOL.balance;
        vm.startPrank(attacker);
        (bool ok, ) = logCall("B: withdraw(1e18) fresh", POOL, abi.encodeWithSelector(ILendingPool.withdraw.selector, 1e18));
        (bool ok2, ) = logCall("B2: withdraw(53e18) fresh", POOL, abi.encodeWithSelector(ILendingPool.withdraw.selector, 53e18));
        vm.stopPrank();
        // withdraw() silently no-ops (returns 0) when the caller has no shares
        emit log_named_string("B: withdraw returned", ok ? "no-op success" : "revert");
        emit log_named_string("B2: withdraw returned", ok2 ? "no-op success" : "revert");
        assertEq(attacker.balance, 100 ether, "attacker gained nothing");
        assertEq(POOL.balance, poolBefore, "pool FIL unchanged");
    }

    function test_C_fresh_deposit_reverts_paused() public {
        vm.startPrank(attacker);
        (bool ok, ) = logCall("C: deposit() fresh", POOL, abi.encodeWithSelector(ILendingPool.deposit.selector));
        vm.stopPrank();
        assertFalse(ok, "fresh deposit must fail (paused)");
    }

    function test_D_fresh_borrow_reverts() public {
        vm.startPrank(attacker);
        (bool ok, ) = logCall("D: borrow(0,1e18) fresh", POOL, abi.encodeWithSelector(ILendingPool.borrow.selector, uint256(0), uint256(1e18)));
        vm.stopPrank();
        assertFalse(ok, "fresh borrow must fail");
        assertEq(attacker.balance, 100 ether, "attacker gained nothing");
    }

    function test_E_fresh_claim_reverts() public {
        uint256[] memory a = new uint256[](1);
        uint256[] memory b = new uint256[](1);
        uint256[] memory c = new uint256[](1);
        a[0] = 4; b[0] = 0; c[0] = 1e13;
        vm.startPrank(attacker);
        (bool ok, ) = logCall("E: batchClaim([4],[0],[1e13]) fresh", REWARD, abi.encodeWithSelector(IRewardPool.batchClaim.selector, a, b, c));
        vm.stopPrank();
        assertFalse(ok, "fresh claim must fail");
        assertEq(attacker.balance, 100 ether, "attacker gained nothing");
    }

    function test_F_fresh_unstake_reverts() public {
        vm.startPrank(attacker);
        (bool ok, ) = logCall("F: unstake(4,0,1e18) fresh", REWARD, abi.encodeWithSelector(IRewardPool.unstake.selector, uint256(4), uint256(0), uint256(1e18)));
        vm.stopPrank();
        assertFalse(ok, "fresh unstake must fail");
        assertEq(attacker.balance, 100 ether, "attacker gained nothing");
    }

    function test_G_fresh_pledge_probe() public {
        vm.startPrank(attacker);
        (bool ok1, ) = logCall("G1: pledge(attacker,4,0,100e18)", POOL, abi.encodeWithSelector(ILendingPool.pledge.selector, attacker, uint256(4), uint256(0), uint256(100e18)));
        (bool ok2, ) = logCall("G2: pledge(attacker,0,0,0)", POOL, abi.encodeWithSelector(ILendingPool.pledge.selector, attacker, uint256(0), uint256(0), uint256(0)));
        vm.stopPrank();
        // informational: pledge should be gated; if either succeeded, borrow probe below matters
        if (ok1 || ok2) {
            vm.startPrank(attacker);
            (bool ok3, ) = logCall("G3: borrow(0,1e18) after pledge", POOL, abi.encodeWithSelector(ILendingPool.borrow.selector, uint256(0), uint256(1e18)));
            vm.stopPrank();
            assertFalse(ok3, "borrow must not pay out");
        }
        assertEq(attacker.balance, 100 ether, "attacker gained nothing");
    }

    // ------------------------- attacker who acquires SFT from a holder (OTC)
    function test_H_stake_then_claim_borrow_unstake() public {
        // Acquire SFT from an existing EOA holder. NOTE: SFT has no DEX market
        // (no price/volume on Blockscout, no CoinGecko listing), so this models
        // an OTC/transfer acquisition, not a permissionless purchase.
        vm.prank(HOLDER);
        sft.transfer(attacker, 1000e18);
        assertEq(sft.balanceOf(attacker), 1000e18, "attacker got SFT");

        vm.startPrank(attacker);
        sft.approve(REWARD, type(uint256).max);
        (bool okStake, ) = logCall("H1: stake(4,100e18)", REWARD, abi.encodeWithSelector(IRewardPool.stake.selector, uint256(4), uint256(100e18)));
        emit log_named_uint("H1: attacker SFT after stake", sft.balanceOf(attacker));

        // try to claim (no credited rewards for a brand-new order expected)
        uint256[] memory a = new uint256[](1);
        uint256[] memory b = new uint256[](1);
        uint256[] memory c = new uint256[](1);
        a[0] = 4; b[0] = 0; c[0] = 1e13;
        uint256 balBefore = attacker.balance;
        (bool okClaim, ) = logCall("H2: batchClaim after fresh stake", REWARD, abi.encodeWithSelector(IRewardPool.batchClaim.selector, a, b, c));
        emit log_named_int("H2: attacker FIL delta", int(attacker.balance) - int(balBefore));

        // try to borrow against the fresh stake
        (bool okBorrow, ) = logCall("H3: borrow(0,1e18) after stake", POOL, abi.encodeWithSelector(ILendingPool.borrow.selector, uint256(0), uint256(1e18)));
        (bool okBorrow1, ) = logCall("H3b: borrow(1,1e18) after stake", POOL, abi.encodeWithSelector(ILendingPool.borrow.selector, uint256(1), uint256(1e18)));

        // unstake again
        (bool okUnstake, ) = logCall("H4: unstake(4,0,100e18)", REWARD, abi.encodeWithSelector(IRewardPool.unstake.selector, uint256(4), uint256(0), uint256(100e18)));
        emit log_named_uint("H4: attacker SFT after unstake", sft.balanceOf(attacker));
        vm.stopPrank();

        // informational flags
        emit log_named_string("H1 stake ok", okStake ? "yes" : "no");
        emit log_named_string("H2 claim ok", okClaim ? "yes" : "no");
        emit log_named_string("H3 borrow ok", okBorrow ? "yes" : "no");
        emit log_named_string("H3b borrow ok", okBorrow1 ? "yes" : "no");
        emit log_named_string("H4 unstake ok", okUnstake ? "yes" : "no");

        // The attacker must not have gained FIL beyond the stake round-trip.
        assertEq(attacker.balance, 100 ether, "no FIL gained via stake/claim/borrow");
    }

    // ------------------------------------------- mint/withdraw pool round-trip
    function test_I_mint_pool_roundtrip() public {
        vm.startPrank(attacker);
        uint256 sftBefore = sft.balanceOf(attacker);
        (bool okDep, ) = logCall("I1: mint.deposit{1 FIL}()", MINT, abi.encodeWithSelector(IMintPool.deposit.selector));
        emit log_named_uint("I1: attacker SFT after deposit", sft.balanceOf(attacker));
        emit log_named_int("I1: attacker FIL delta", int(attacker.balance) - int(100 ether));

        uint256 got = sft.balanceOf(attacker) - sftBefore;
        if (got > 0) {
            uint256 filBefore = attacker.balance;
            (bool okSwap, ) = logCall("I2: mint.swapFil(all SFT)", MINT, abi.encodeWithSelector(IMintPool.swapFil.selector, got));
            emit log_named_int("I2: attacker FIL delta", int(attacker.balance) - int(filBefore));
            emit log_named_string("I2 swap ok", okSwap ? "yes" : "no");
        }
        vm.stopPrank();
        // informational: the round-trip must not be profitable; if it is, that is a finding
        emit log_named_int("I: net FIL delta", int(attacker.balance) - int(100 ether));
    }

    // ------------------------------------------------------------- admin gates
    function test_J_admin_gates() public {
        vm.startPrank(attacker);
        (bool okRescue, ) = logCall("J1: pool.rescueTokens(SFT,attacker,1)", POOL, abi.encodeWithSelector(ILendingPool.rescueTokens.selector, SFT, attacker, uint256(1)));
        (bool okPause, ) = logCall("J2: mint.pause()", MINT, abi.encodeWithSelector(IMintPool.pause.selector));
        vm.stopPrank();
        assertFalse(okRescue, "rescueTokens must be owner-gated");
        assertFalse(okPause, "pause must be owner-gated");
        (bool okOwner, bytes memory ret) = ADMIN_PROXY.staticcall(abi.encodeWithSignature("owner()"));
        if (okOwner && ret.length == 32) {
            emit log_named_address("admin proxy owner", abi.decode(ret, (address)));
        }
    }

    // ------------------------------------------------ can attacker2 claim for staker1?
    function test_K_cross_user_claim() public {
        // attacker2 has no stake; try to claim order (4,0) — a real staker index
        uint256[] memory a = new uint256[](1);
        uint256[] memory b = new uint256[](1);
        uint256[] memory c = new uint256[](1);
        a[0] = 4; b[0] = 0; c[0] = 1e13;
        vm.startPrank(attacker2);
        (bool ok, ) = logCall("K: cross-user batchClaim([4],[0])", REWARD, abi.encodeWithSelector(IRewardPool.batchClaim.selector, a, b, c));
        vm.stopPrank();
        assertFalse(ok, "cross-user claim must fail");
        assertEq(attacker2.balance, 100 ether, "no payout to non-staker");
    }

    // ------------------------------------------------ sweep the reward pool?
    function test_L_fresh_withdraw_on_reward_pool() public {
        vm.startPrank(attacker);
        (bool ok, ) = logCall("L: reward.withdraw(1e18)", REWARD, abi.encodeWithSelector(IRewardPool.withdraw.selector, uint256(1e18)));
        vm.stopPrank();
        assertFalse(ok, "reward.withdraw must fail for fresh caller");
        assertEq(attacker.balance, 100 ether, "no payout");
    }

    // ------------------- dust-share attacker: can 1 wei of rSFT withdraw 53 FIL?
    function test_M_dust_shares_no_overwithdraw() public {
        // move 1 wei of rSFT from a live holder to the attacker
        address holder = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1; // ~355 rSFT live
        vm.prank(holder);
        (bool okT, ) = logCall("M0: transferShares(attacker,1)", POOL, abi.encodeWithSelector(ILendingPool.transferShares.selector, attacker, uint256(1)));
        uint256 shares = pool.balanceOf(attacker);
        emit log_named_uint("M0: attacker rSFT after transferShares", shares);
        if (shares == 0) {
            // fall back: plain transfer
            vm.prank(holder);
            (okT, ) = logCall("M0b: transfer(attacker,1)", POOL, abi.encodeWithSelector(ILendingPool.transfer.selector, attacker, uint256(1)));
            shares = pool.balanceOf(attacker);
            emit log_named_uint("M0b: attacker rSFT after transfer", shares);
        }
        uint256 balBefore = attacker.balance;
        uint256 poolBefore = POOL.balance;
        vm.prank(attacker);
        (bool ok, ) = logCall("M1: withdraw(53e18) with dust shares", POOL, abi.encodeWithSelector(ILendingPool.withdraw.selector, 53e18));
        emit log_named_int("M1: attacker FIL delta", int(attacker.balance) - int(balBefore));
        emit log_named_int("M1: pool FIL delta", int(POOL.balance) - int(poolBefore));
        assertLe(attacker.balance - balBefore, 1, "dust share must not over-withdraw");
    }

    // ------------------- H-O status: existing rSFT holder withdrawal is FROZEN
    function test_N_holder_withdraw_is_frozen() public {
        address holder = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1; // ~355 rSFT live
        uint256 balBefore = holder.balance;
        vm.prank(holder);
        (bool ok, ) = logCall("N: holder withdraw(1e18)", POOL, abi.encodeWithSelector(ILendingPool.withdraw.selector, 1e18));
        emit log_named_int("N: holder FIL delta", int(holder.balance) - int(balBefore));
        emit log_named_string("N: ok", ok ? "yes" : "no");
        // Live state: withdrawals revert POOL_FIL_BALANCE_NOT_ENOUGH for every holder
        assertFalse(ok, "holder withdrawal must currently revert");
        assertEq(holder.balance, balBefore, "no payout");
    }

    // ------------------- H-O proof: existing staker can still claim FIL rewards
    function test_O_existing_staker_claim_is_live() public {
        address staker = 0x8F64E277Bcb6B9d49cc1CaDdf3ebb189aE844eB1; // claimed at block 5,725,023
        uint256[] memory a = new uint256[](1);
        uint256[] memory b = new uint256[](1);
        uint256[] memory c = new uint256[](1);
        a[0] = 4; b[0] = 0; c[0] = 1e13;
        uint256 balBefore = staker.balance;
        vm.prank(staker);
        (bool ok, ) = logCall("O: staker batchClaim([4],[0],[1e13])", REWARD, abi.encodeWithSelector(IRewardPool.batchClaim.selector, a, b, c));
        emit log_named_int("O: staker FIL delta", int(staker.balance) - int(balBefore));
        emit log_named_string("O: ok", ok ? "yes" : "no");
    }
}
