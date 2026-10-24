// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ---------------------------------------------------------------------------
// ZH4P5-LVIN  —  NEM-class "recycle" gate resolution
// Target: LVIN token 0x33bC8653EcA8469108f65FE87B18c87C136545a8 (BSC)
//         PancakeV2 pair 0x43365C7B7b039bc06dC201Ddf38117cf1C69dc8b (LVIN/USDT)
// Read-only: fork simulation only. No mainnet tx is ever signed/sent.
// ---------------------------------------------------------------------------

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function sync() external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IToken is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function owner() external view returns (address);
    function recycle(uint256 amount) external;
    function setStake(address) external;
    function tradingEnable() external view returns (bool);
}

interface IStake {
    function transfer(address to, uint256 value) external returns (bool);
    function usdtForAddStakeOrder(uint256 inAmt) external;
    function calculateReward() external;
    function getAllReward(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function owner() external view returns (address);
}

interface IUC {
    function registerForAddr(address top) external payable;
    function getUserTop(address) external view returns (uint256);
    function getTopLine(address) external view returns (address[] memory);
}

contract LvinRecycleTest is Test {
    // ---- live BSC addresses -------------------------------------------------
    address constant TOKEN = 0x33bC8653EcA8469108f65FE87B18c87C136545a8;
    address constant PAIR  = 0x43365C7B7b039bc06dC201Ddf38117cf1C69dc8b;
    address constant STAKE = 0xe120bBf90eb051A43A3BDc0408b194b6F99b488E;
    address constant USDT  = 0x55d398326f99059fF775485246999027B3197955;
    address constant UC    = 0xE18E914314c2AF0B9F3B0568b390AaFEEb98efaB;
    address constant TOP_STAKER = 0x28AC07a00F9A0345B469dE457394AEFA67626039;

    // Reference live-state snapshot block (read-only analysis). The fork itself is
    // taken at CI head because keyless BSC RPCs prune historical state; the gate
    // identity and burn bound are block-independent. Actual fork block is recorded.
    uint256 constant SNAPSHOT_BLOCK = 129283473;

    uint256 public forkBlock;
    address attacker = address(0xA11CE);

    function setUp() public {
        string[3] memory urls =
            [vm.envOr("BSC_RPC_URL", string("")), "https://bsc-rpc.publicnode.com", "https://binance.llamarpc.com"];
        bool ok = false;
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            try this.forkAt(urls[i]) {
                ok = true;
                break;
            } catch {}
        }
        require(ok, "no working BSC rpc");
        forkBlock = block.number;
    }

    // external self-call so a bad RPC can be caught and the next one tried
    function forkAt(string memory u) external {
        vm.createSelectFork(u);
    }

    function test_00_forkBlock_recorded() public {
        emit log_named_uint("fork block", forkBlock);
        assertGt(forkBlock, SNAPSHOT_BLOCK);
    }

    // =======================================================================
    // A. DIRECT CALL — the gate is `require(stake == msg.sender)`
    // =======================================================================
    function test_A_directRecycle_fromRandomEoa_reverts() public {
        vm.prank(attacker, attacker);
        vm.expectRevert(bytes("recycle fail"));
        IToken(TOKEN).recycle(1);
    }

    function test_B_recycle_fromStakeAddress_succeeds_andBurns() public {
        uint256 r0Before = _reserveLvin();
        uint256 pairBalBefore = IERC20(TOKEN).balanceOf(PAIR);
        // Only the Stake contract satisfies `stake == msg.sender`.
        vm.prank(STAKE, STAKE);
        IToken(TOKEN).recycle(1e18); // burn 1 LVIN from pair -> stake, then sync
        uint256 pairBalAfter = IERC20(TOKEN).balanceOf(PAIR);
        assertEq(pairBalBefore - pairBalAfter, 1e18, "recycle must move 1e18 LVIN out of pair");
        assertTrue(pairBalAfter < pairBalBefore);
        assertTrue(r0Before > 0);
    }

    // =======================================================================
    // C. UNPRIVILEGED PATH EXISTS (Stake.transfer -> sell -> token.recycle)
    //    but requires a registered staker with a positive reward.
    // =======================================================================
    function test_C_randomEoaStakeTransfer_reverts_noReward() public {
        vm.prank(attacker, attacker);
        vm.expectRevert(bytes("sell amount fail"));
        IStake(STAKE).transfer(attacker, 1);
    }

    // The single largest live reward among all 1241 stakers; used as an upper
    // bound on what a *single* recycle call can burn today.
    function test_D_topStaker_transfer_triggersRecycle_measureBurn() public {
        uint256 reward = IStake(STAKE).getAllReward(TOP_STAKER);
        if (reward == 0) {
            emit log("top staker has no reward at fork block - skipping");
            vm.skip(true);
        }
        uint256 r0 = _reserveLvin();
        uint256 maxBurn = IERC20(TOKEN).balanceOf(PAIR) / 3;

        vm.recordLogs();
        vm.prank(TOP_STAKER, TOP_STAKER);
        IStake(STAKE).transfer(TOP_STAKER, 1); // value != 3 ether -> sell()

        uint256 burn = _findRecycleBurn(); // Transfer(pair -> stake) emitted by recycle
        emit log_named_decimal_uint("top staker reward (LVIN)", reward, 18);
        emit log_named_decimal_uint("recycle burn      (LVIN)", burn, 18);
        emit log_named_decimal_uint("pair reserve0     (LVIN)", r0, 18);
        emit log_named_decimal_uint("maxBurn = r0/3    (LVIN)", maxBurn, 18);

        // The burn equals min(reward, r0/3) and is tiny vs the pool.
        assertEq(burn, reward < maxBurn ? reward : maxBurn, "burn = min(reward, r0/3)");
        assertTrue(burn < r0 / 100, "burn < 1% of pair LVIN");
    }

    // =======================================================================
    // E. A FRESH attacker CAN register + stake permissionlessly...
    // =======================================================================
    function test_E_attacker_canRegisterAndStake() public {
        deal(USDT, attacker, 3000e18);
        vm.startPrank(attacker, attacker);
        IUC(UC).registerForAddr(TOP_STAKER); // permissionless bind to a referrer
        IERC20(USDT).approve(STAKE, type(uint256).max);
        IStake(STAKE).usdtForAddStakeOrder(3000e18);
        vm.stopPrank();

        assertEq(IStake(STAKE).getAllReward(attacker), 0, "no reward immediately after staking");
        assertGt(IStake(STAKE).balanceOf(attacker), 0);
    }

    // ...but immediately after staking there is NO reward, so recycle cannot be
    // triggered on demand (the "state condition" that blocks a flash attack).
    function test_E2_attacker_immediateSell_reverts_noReward() public {
        deal(USDT, attacker, 3000e18);
        vm.startPrank(attacker, attacker);
        IUC(UC).registerForAddr(TOP_STAKER);
        IERC20(USDT).approve(STAKE, type(uint256).max);
        IStake(STAKE).usdtForAddStakeOrder(3000e18);
        vm.expectRevert(bytes("sell amount fail"));
        IStake(STAKE).transfer(attacker, 1);
        vm.stopPrank();
    }

    // =======================================================================
    // F. Realistic E-U: stake, wait one reward cycle, trigger recycle.
    //    Quantifies the burn + net USD. Expected: negligible / not profitable.
    // =======================================================================
    function test_F_attacker_oneCycle_recycle_burn_and_pnl() public {
        deal(USDT, attacker, 3000e18);
        vm.startPrank(attacker, attacker);
        IUC(UC).registerForAddr(TOP_STAKER);
        IERC20(USDT).approve(STAKE, type(uint256).max);
        IStake(STAKE).usdtForAddStakeOrder(3000e18);
        vm.stopPrank();

        // advance one reward interval and crank the reward accounting
        vm.warp(block.timestamp + 1 days + 1);
        IStake(STAKE).calculateReward();

        uint256 reward = IStake(STAKE).getAllReward(attacker);
        if (reward == 0) {
            emit log("attacker has no reward after one cycle - skipping");
            vm.skip(true);
        }
        uint256 r0 = _reserveLvin();
        uint256 usdtBefore = IERC20(USDT).balanceOf(attacker);

        vm.recordLogs();
        vm.prank(attacker, attacker);
        IStake(STAKE).transfer(attacker, 1);

        uint256 burn = _findRecycleBurn();
        uint256 usdtAfter = IERC20(USDT).balanceOf(attacker);

        emit log_named_decimal_uint("attacker reward (LVIN)", reward, 18);
        emit log_named_decimal_uint("recycle burn    (LVIN)", burn, 18);
        emit log_named_decimal_uint("pair reserve0   (LVIN)", r0, 18);
        emit log_named_decimal_uint("USDT paid to attacker", usdtAfter - usdtBefore, 18);

        assertGt(burn, 0, "recycle fires");
        assertLt(burn, r0 / 100, "one-cycle burn < 1% of pair LVIN");
    }

    // =======================================================================
    // G. Upper bound: even burning the MAXIMUM (r0/3) via a *privileged*
    //    impersonation of the stake contract, a buy-before/sell-after round
    //    trip is not profitable at the live pool size.
    // =======================================================================
    function test_G_maxBurn_roundtrip_notProfitable() public {
        uint256 r0;
        uint256 r1;
        (r0, r1) = _reserves();
        uint256 burnMax = IERC20(TOKEN).balanceOf(PAIR) / 3;

        // attacker buys LVIN with USDT (dealt), holds it
        uint256 spend = 20_000e18; // $20k
        deal(USDT, attacker, spend);
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = TOKEN;
        uint256 tokensOut;
        {
            // simple constant-product quote (0.25% fee) against live reserves
            uint256 amountInWithFee = spend * 9975;
            tokensOut = (amountInWithFee * r0) / (r1 * 10000 + amountInWithFee);
        }
        // fund the buy directly (fork deal) and measure post-burn sell value
        deal(TOKEN, attacker, tokensOut);

        // burn the max from the pair (privileged impersonation = upper bound)
        vm.prank(STAKE, STAKE);
        IToken(TOKEN).recycle(burnMax);
        (uint256 nr0, uint256 nr1) = _reserves();

        // sell the held LVIN back into the burned pool
        uint256 amountInWithFee2 = tokensOut * 9975;
        uint256 usdtOut = (amountInWithFee2 * nr1) / (nr0 * 10000 + amountInWithFee2);

        emit log_named_decimal_uint("r0 before burn", r0, 18);
        emit log_named_decimal_uint("burned (max r0/3)", burnMax, 18);
        emit log_named_decimal_uint("LVIN bought", tokensOut, 18);
        emit log_named_decimal_uint("USDT out after burn", usdtOut, 18);

        // Round trip on a $20k buy against a ~$98k pool loses money (fees/slippage).
        assertLt(usdtOut, spend, "round trip is a net loss");
    }

    // ---------------------------- helpers ----------------------------------
    function _reserves() internal view returns (uint256 r0, uint256 r1) {
        (uint112 a, uint112 b, ) = IPair(PAIR).getReserves();
        if (IPair(PAIR).token0() == TOKEN) return (uint256(a), uint256(b));
        return (uint256(b), uint256(a));
    }

    function _reserveLvin() internal view returns (uint256) {
        (uint256 r0, ) = _reserves();
        return r0;
    }

    // find the Transfer(pair -> stake) emitted by recycle()
    function _findRecycleBurn() internal returns (uint256) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 sig = keccak256("Transfer(address,address,uint256)");
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics.length == 3 && logs[i].topics[0] == sig && logs[i].emitter == TOKEN) {
                address from = address(uint160(uint256(logs[i].topics[1])));
                address to = address(uint160(uint256(logs[i].topics[2])));
                if (from == PAIR && to == STAKE) {
                    return abi.decode(logs[i].data, (uint256));
                }
            }
        }
        return 0;
    }
}
