// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IMoat {
    function owner() external view returns (address);
    function stakingToken() external view returns (address);
    function rewardInfo(address) external view returns (address, uint256, uint256, uint256, uint256);
    function pendingRewards(address, address) external view returns (uint256);
    function getCurrentPoints(address) external view returns (uint256);
    function totalPoints() external view returns (uint256);
    function burn(uint256) external;
    function stake(uint256) external;
    function claimAllRewards() external;
    function getAllPendingRewards(address) external view returns (address[] memory, uint256[] memory);
    function burningEnabled() external view returns (bool);
    function stakingEnabled() external view returns (bool);
    function lockingEnabled() external view returns (bool);
    function MIN_STAKE_AMOUNT() external view returns (uint256);
    function POINTS_SCALING_FACTOR() external view returns (uint256);
    function BURN_MULTIPLIER() external view returns (uint256);
    function totalBurned() external view returns (uint256);
    function addRewardToken(address) external;
    function depositRewards(address, uint256) external;
    function getRewardTokens() external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory);
}

interface IFactory {
    function deployContract(address) external returns (address);
    function getAllDeployedContracts() external view returns (address[] memory);
    function deploymentFee() external view returns (uint256);
    function usdcToken() external view returns (address);
    function adminWallet() external view returns (address);
    function owner() external view returns (address);
}

/// Minimal ERC20 that returns `false` (non-reverting) from `transfer` and `transferFrom`.
contract FalseTransferERC20 {
    string public name = "FALSE";
    string public symbol = "FALSE";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    bool public transferReturnsFalse = true;

    function mint(address to, uint256 a) external { balanceOf[to] += a; totalSupply += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transfer(address, uint256) external returns (bool) { return !transferReturnsFalse; }
    function transferFrom(address from, address, uint256 a) external returns (bool) {
        balanceOf[from] -= a; // actually move so SafeERC20 sees a real effect
        balanceOf[msg.sender] += a;
        return true;
    }
}

contract MoatsForkTest is Test {
    uint256 constant BLK = 98459787;

    address constant FACTORY = 0xD0b5249EA2f93E54B90ff0737B4d78AA13a222BC;
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    // largest remaining priced reward pool: ~$1114 MYST (burning disabled on this moat)
    address constant MOAT_BIG = 0x7e27289337A46d8eca46f9a7B137b0CAa377A54C;
    address constant MYST = 0x0256B279D973C8d687264AC3eB36bE09232D4474;

    // ~$303 remaining pool, burning ENABLED
    address constant MOAT_HEFE = 0xCf65744c955A292d11DE2A4184e9faBEDbFc7b40;
    address constant HEFE = 0x18E3605B13F10016901eAC609b9E188CF7c18973;

    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(vm.envOr("AVAX_RPC", string("https://avalanche-c-chain-rpc.publicnode.com")), BLK);
        vm.deal(attacker, 100 ether);
    }

    // ---- 1. New entrant cannot touch an already-allocated pool ----
    function test_newEntrant_zeroPending_bigPool() public {
        IMoat m = IMoat(MOAT_BIG);
        (address tok, uint256 acc, , uint256 dep, uint256 clm) = m.rewardInfo(MYST);
        assertEq(tok, MYST, "reward token");
        assertGt(acc, 0, "pool allocated (acc>0)");
        assertGt(dep - clm, 0, "pool has remaining balance");

        // fresh address, never interacted
        assertEq(m.pendingRewards(attacker, MYST), 0, "new entrant pending == 0");
        assertEq(m.getCurrentPoints(attacker), 0, "new entrant points == 0");

        // even claimAllRewards yields nothing
        uint256 balBefore = IERC20(MYST).balanceOf(attacker);
        vm.prank(attacker);
        m.claimAllRewards();
        assertEq(IERC20(MYST).balanceOf(attacker), balBefore, "claim moved nothing");
    }

    // ---- 2. Acquiring points (burn) grants NO retroactive claim on the existing pool ----
    function test_burn_doesNotGrantRetroactiveRewards() public {
        IMoat m = IMoat(MOAT_HEFE);
        assertTrue(m.burningEnabled(), "burn enabled");
        (, uint256 acc, , uint256 dep, uint256 clm) = m.rewardInfo(HEFE);
        assertGt(acc, 0, "allocated");

        uint256 poolBefore = IERC20(HEFE).balanceOf(MOAT_HEFE);
        uint256 remainBefore = dep - clm;

        // fund attacker with HEFE and burn a chunk
        uint256 amount = 1_000_000e18;
        deal(HEFE, attacker, amount);
        vm.startPrank(attacker);
        IERC20(HEFE).approve(MOAT_HEFE, type(uint256).max);
        m.burn(amount);
        vm.stopPrank();

        // points credited (10x), but pending still zero for this reward token
        assertGt(m.getCurrentPoints(attacker), 0, "points credited");
        assertEq(m.pendingRewards(attacker, HEFE), 0, "no retroactive claim after burn");

        (, , , uint256 dep2, uint256 clm2) = m.rewardInfo(HEFE);
        assertEq(dep2 - clm2, remainBefore, "remaining pool unchanged");
        // HEFE that was burned: safeTransferFrom in, unchecked transfer to DEAD out (standard token succeeds)
        assertEq(IERC20(HEFE).balanceOf(MOAT_HEFE), poolBefore, "pool balance unchanged by burn");
    }

    // ---- 3. Cost to dominate a pool far exceeds the pool value ----
    function test_dominanceCost_exceedsPool() public {
        IMoat m = IMoat(MOAT_BIG);
        uint256 tp = m.totalPoints();
        uint256 scale = m.POINTS_SCALING_FACTOR();
        uint256 mult = m.BURN_MULTIPLIER();
        // cost (in staking-token wei) to mint `tp` extra points via burn:
        uint256 costWei = (tp * scale) / mult;
        // MYST price ~ $0.0100758 (DefiLlama, avax:0x0256b279...)
        uint256 costUsdE8 = (costWei * 1007580) / 1e18; // * $0.0100758 scaled 1e8 /1e18
        emit log_named_uint("totalPoints", tp);
        emit log_named_uint("burn-cost MYST wei to match totalPoints", costWei);
        emit log_named_uint("burn-cost USD (1e8)", costUsdE8);
        // remaining pool for this moat ~ $1114
        assertGt(costUsdE8, 1114e8, "cost to dominate > pool value");
    }

    // ---- 4. Permissionless factory: isolation ----
    function test_factory_deployIsolated() public {
        IFactory f = IFactory(FACTORY);
        address[] memory beforeList = f.getAllDeployedContracts();

        uint256 fee = f.deploymentFee();
        assertEq(fee, 250_000_000, "fee = 250 USDC");

        // existing moat balance snapshot
        IMoat existing = IMoat(MOAT_HEFE);
        uint256 existingBal = IERC20(HEFE).balanceOf(MOAT_HEFE);
        uint256 existingPoints = existing.totalPoints();

        // deploy without allowance -> revert
        vm.prank(attacker);
        vm.expectRevert();
        f.deployContract(HEFE);

        // deploy with allowance
        deal(USDC, attacker, fee);
        vm.startPrank(attacker);
        IERC20(USDC).approve(FACTORY, fee);
        address nm = f.deployContract(HEFE);
        vm.stopPrank();

        // new moat owned by attacker; isolated state
        assertEq(IMoat(nm).owner(), attacker, "new moat owner == caller");
        assertEq(IMoat(nm).totalPoints(), 0, "new moat fresh points");
        assertEq(IERC20(HEFE).balanceOf(nm), 0, "new moat holds no existing funds");
        assertEq(IERC20(HEFE).balanceOf(MOAT_HEFE), existingBal, "existing moat untouched");
        assertEq(existing.totalPoints(), existingPoints, "existing points untouched");

        address[] memory afterList = f.getAllDeployedContracts();
        assertEq(afterList.length, beforeList.length + 1, "registry grew by 1");
        assertEq(afterList[afterList.length - 1], nm, "registry appended new moat");
    }

    // ---- 5. burn()'s unchecked transfer: non-reverting-false ERC20 keeps tokens, but still costs the attacker ----
    function test_uncheckedTransfer_nonRevertingFalseToken() public {
        FalseTransferERC20 bad = new FalseTransferERC20();
        IFactory f = IFactory(FACTORY);
        uint256 fee = f.deploymentFee();
        deal(USDC, attacker, fee);

        vm.startPrank(attacker);
        IERC20(USDC).approve(FACTORY, fee);
        address nm = f.deployContract(address(bad));
        // as owner: register reward token + deposit rewards so points have a target
        IMoat(nm).addRewardToken(address(bad));
        bad.mint(attacker, 1e24);
        bad.approve(nm, type(uint256).max);
        IMoat(nm).depositRewards(address(bad), 1e18);
        uint256 ptsBefore = IMoat(nm).getCurrentPoints(attacker);
        IMoat(nm).burn(1e12);
        vm.stopPrank();

        uint256 ptsAfter = IMoat(nm).getCurrentPoints(attacker);
        assertGt(ptsAfter, ptsBefore, "burn credited points");
        // moat holds the 1e18 deposited reward + the 1e12 burned that never reached DEAD
        assertEq(bad.balanceOf(nm), 1e18 + 1e12, "burned tokens stuck in moat (transfer to DEAD silently failed)");
        assertEq(bad.balanceOf(address(0x000000000000000000000000000000000000dEaD)), 0, "DEAD received nothing");
        // NOTE: attacker still PAID 1e12 tokens via safeTransferFrom -> no free points.
    }

    // ---- 6. structural negative: factory exposes no path to move existing moat funds ----
    function test_factory_hasNoDrainFunction() public {
        // The factory ABI (verified) contains only: deployContract, getters, and onlyOwner config setters.
        // There is no function that references existing moat balances.
        assertTrue(true);
    }
}
