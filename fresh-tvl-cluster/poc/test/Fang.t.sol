// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";

// NOTE (Z3-H17 child, Fang): poc/src/ForkHelper.sol does NOT compile against the vendored
// forge-std 1.9.6 — its `VM_ADDRESS` constant redeclares `Base.VM_ADDRESS` (solc error 9097:
// "Identifier already declared") in any inheritor. Parent owns that file; this test therefore
// implements the identical semantics locally: env override first, then first working public RPC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IGenesisFarm {
    function poolLength() external view returns (uint256);
    function poolEndTime() external view returns (uint256);
    function convertible() external view returns (address);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function convert(uint256 pid, uint256 amount) external returns (uint256);
    function userInfo(uint256 pid, address u) external view returns (uint256 amount, uint256 rewardDebt);
    function pendingReward(uint256 pid, address u) external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (address, uint256, uint256, uint256, bool, uint16);
}

interface IMasonry {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function allocateSeigniorage(uint256 amount) external;
    function earned(address user) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IxGFANG {
    function redeem(uint256 amount, uint256 duration) external;
    function finalizeRedeem(uint256 index) external;
    function getGfangByVestingDuration(uint256 amount, uint256 duration) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function redeemingEnabled() external view returns (bool);
    function setRedeemingEnabled(bool) external;
}

interface IFangRedeem {
    function redeemFang(uint256 amount) external returns (uint256);
    function quoteRedeem(uint256 amount) external pure returns (uint256);
    function supplyUSDC(uint256 amount) external;
}

interface ITreasury {
    function epoch() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
    function allocateSeigniorage() external;
}

/// @title Z3-H17 · Fang (Robinhood Chain 4663) — Tomb-fork farm math + reward/convert surface
/// @notice Read-only research PoC. Runs on a local fork of live Robinhood Chain state via keyless
///         public RPCs only (env override RHO_RPC honored). No mainnet transactions, no keys.
contract FangH17Test is Test {
    address constant FARM = 0xC01B68919Cd0297B1bf43E4942880E98682D3bbF;
    address constant MASONRY = 0x33Be17082Bd477dC804EdabBa1A8D777Da3F668d;
    address constant GFANG = 0x6376010d9D1F64de70D9e83c4093c8294515aC28;
    address constant XGFANG = 0x6D60D2B9973Da40B5124358550d213BA8f266dF7;
    address constant FANG = 0x9E7739480b45602e1706cE7369e06698F20052e1;
    address constant FANGREDEEM = 0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47;
    address constant TREASURY = 0x7399ef6694b6357Ee4BF3C51C83aa4450958851e;
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address constant OWNER_EOA = 0x608730AabB55eE45Af29dADCC93bdB63470f0420;

    address constant ATTACKER = address(0xA77ACC);
    address constant PROBE = address(0xFEE1);

    // All 16 genesis pool tokens (verified against live poolInfo reads 2026-10-16)
    address[16] internal TOKENS = [
        0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73, // WETH
        0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168, // USDG
        0x63C12667638f2Ae6fC6ae09B43D98Ec84a8586eA, // wsNET
        0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC, // NVDA
        0x117cc2133c37B721F49dE2A7a74833232B3B4C0C, // SPY
        0x2E8c31162b855A2ffa90F6F8634643Ad6F111e18, // AI
        0x39dBED3a2bd333467115dE45665cC57F813C4571, // PONS
        0x020bfC650A365f8BB26819deAAbF3E21291018b4, // CASHCAT
        0x84d6BB25d3b013c784bE60dC598c920588F452bC, // fBOMB
        0x96765066f6a040a21EB027167D2315B707c82633, // RVH
        0x4e5195469A0360f5dfe811730C9CCaCFF0a0FeeE, // r33
        0x5BaaeC1B70864f01dbdb747358FF59F2E2cCF7D5, // GIGA
        0x378A50eaC56f45Fb74e4cE7F1962dbCA33515c14, // MCD
        0x9FE4d78202F97E982546Fd5f63E2418FEf8E4ea2, // S33
        0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34, // USDE
        0xab093dEF657F15dF31b33922A95e047aDd645B29 // SHROOM
    ];

    /// @dev Identical semantics to ForkHelper.forkChain: env override first, then public fallbacks.
    function _forkRho() internal returns (string memory) {
        string[4] memory urls = [
            vm.envOr("RHO_RPC", string("")),
            "https://rpc.mainnet.chain.robinhood.com",
            "https://robinhood-rpc.publicnode.com",
            "https://robinhood.drpc.org"
        ];
        for (uint256 i; i < urls.length; ++i) {
            if (bytes(urls[i]).length == 0) continue;
            (bool ok,) = address(vm).call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return urls[i];
        }
        revert("FangH17Test: no reachable Robinhood RPC");
    }

    // ---------------------------------------------------------------------------------------
    // T1 — live state: genesis running, convert() closed (convertible unset)
    // ---------------------------------------------------------------------------------------
    function test_T1_liveState_convertClosed() public {
        _forkRho();
        console2.log("fork block (eth_blockNumber space):", block.number);
        assertEq(IGenesisFarm(FARM).poolLength(), 16, "16 pools");
        uint256 end = IGenesisFarm(FARM).poolEndTime();
        assertGt(end, block.timestamp, "genesis still running (deposits open)");
        assertEq(IGenesisFarm(FARM).convertible(), address(0), "convertible not set");
        console2.log("poolEndTime:", end);
        console2.log("now:", block.timestamp);
        // fresh attacker: convert() is unreachable (screening claim verified)
        vm.prank(ATTACKER);
        vm.expectRevert("GenesisFarm: convertible not set");
        IGenesisFarm(FARM).convert(1, 1e18);
        // every pool charges a 2% deposit fee; allocpoints sum to 10000
        uint256 allocSum;
        for (uint256 pid; pid < 16; ++pid) {
            (, uint256 alloc, , , bool started, uint16 fee) = IGenesisFarm(FARM).poolInfo(pid);
            assertTrue(started, "pool started");
            assertEq(fee, 200, "2% deposit fee");
            allocSum += alloc;
        }
        assertEq(allocSum, 10000, "alloc sum");
    }

    // ---------------------------------------------------------------------------------------
    // T2 — USDG deposit/withdraw round trip + reward-debt accounting (fresh attacker, own capital)
    // ---------------------------------------------------------------------------------------
    function test_T2_usdgRoundTrip_rewardDebt() public {
        _forkRho();
        uint256 fund = 1_000e6; // USDG is 6dp
        deal(USDG, ATTACKER, fund);
        uint256 aStart = IERC20(USDG).balanceOf(ATTACKER);
        uint256 oStart = IERC20(USDG).balanceOf(OWNER_EOA);

        vm.startPrank(ATTACKER);
        IERC20(USDG).approve(FARM, type(uint256).max);
        IGenesisFarm(FARM).deposit(1, fund); // pid 1 = USDG
        vm.stopPrank();

        (uint256 credited, ) = IGenesisFarm(FARM).userInfo(1, ATTACKER);
        assertEq(credited, fund - (fund * 200) / 10_000, "credited = nominal - 2%");
        console2.log("deposited:", fund);
        console2.log("credited:", credited);

        // reward accrual over 24h then full withdrawal
        vm.warp(block.timestamp + 1 days);
        uint256 pending = IGenesisFarm(FARM).pendingReward(1, ATTACKER);
        assertGt(pending, 0, "xGFANG accrues");
        uint256 xStart = IERC20(XGFANG).balanceOf(ATTACKER);

        vm.prank(ATTACKER);
        IGenesisFarm(FARM).withdraw(1, credited);

        uint256 aEnd = IERC20(USDG).balanceOf(ATTACKER);
        uint256 oEnd = IERC20(USDG).balanceOf(OWNER_EOA);
        uint256 xEnd = IERC20(XGFANG).balanceOf(ATTACKER);

        // fully unstaked, debt reset
        (uint256 left, uint256 debt) = IGenesisFarm(FARM).userInfo(1, ATTACKER);
        assertEq(left, 0, "amount 0");
        assertEq(debt, 0, "rewardDebt 0");
        // reward paid equals pending at withdrawal block
        assertEq(xEnd - xStart, pending, "reward paid == pending");
        // round trip: attacker LOSES exactly the 2% deposit fee; owner gains it
        console2.log("attacker USDG start:", aStart);
        console2.log("attacker USDG end:", aEnd);
        console2.log("attacker USDG net loss:", fund / 50);
        console2.log("owner USDG fee collected:", oEnd - oStart);
        assertEq(aEnd, aStart - fund / 50, "attacker net = -2%");
        assertEq(oEnd - oStart, fund / 50, "owner fee = +2%");
        assertLt(aEnd, aStart, "closed: net loss");
    }

    // ---------------------------------------------------------------------------------------
    // T3 — fee-on-transfer / rebase probe across all 16 pool tokens + raw-transfer no-credit
    // ---------------------------------------------------------------------------------------
    function test_T3_fotProbe_noCreditOnDirectTransfer() public {
        _forkRho();
        uint256 fot;
        for (uint256 i; i < 16; ++i) {
            address t = TOKENS[i];
            uint256 bal = IERC20(t).balanceOf(FARM);
            if (bal == 0) continue;
            uint256 amount = bal / 100;
            if (amount == 0) amount = 1;
            uint256 before = IERC20(t).balanceOf(PROBE);
            vm.prank(FARM);
            (bool ok,) = t.call(abi.encodeWithSelector(IERC20.transfer.selector, PROBE, amount));
            if (!ok) {
                console2.log("probe transfer reverted for token", t);
                continue;
            }
            uint256 got = IERC20(t).balanceOf(PROBE) - before;
            console2.log("token", t);
            console2.log("  sent:", amount);
            console2.log("  received:", got);
            assertLe(got, amount, "no mint-on-transfer");
            if (got < amount) fot++;
        }
        console2.log("FoT tokens detected:", fot);

        // direct transfer into the farm must NOT create any user accounting (no rewardDebt desync)
        deal(USDG, ATTACKER, 10e6);
        vm.prank(ATTACKER);
        IERC20(USDG).transfer(FARM, 10e6);
        (uint256 amt, ) = IGenesisFarm(FARM).userInfo(1, ATTACKER);
        assertEq(amt, 0, "raw transfer gives no stake credit");
        assertEq(IGenesisFarm(FARM).pendingReward(1, ATTACKER), 0, "raw transfer gives no rewards");
    }

    // ---------------------------------------------------------------------------------------
    // T4 — Masonry: donation not creditable, stake locked until epoch, operator gated
    // ---------------------------------------------------------------------------------------
    function test_T4_masonry_donation_and_lockup() public {
        _forkRho();
        deal(GFANG, ATTACKER, 100e18);
        vm.startPrank(ATTACKER);
        IERC20(GFANG).approve(MASONRY, type(uint256).max);
        IMasonry(MASONRY).stake(100e18);
        vm.stopPrank();
        assertEq(IMasonry(MASONRY).balanceOf(ATTACKER), 100e18, "staked");

        uint256 earnedBefore = IMasonry(MASONRY).earned(ATTACKER);
        // donation by a third party (fresh attacker #2 capital)
        address donor = address(0xD00A);
        deal(GFANG, donor, 50e18);
        vm.prank(donor);
        IERC20(GFANG).transfer(MASONRY, 50e18);
        uint256 earnedAfter = IMasonry(MASONRY).earned(ATTACKER);
        assertEq(earnedAfter, earnedBefore, "donation changes nothing for stakers");
        assertEq(IMasonry(MASONRY).totalSupply(), 100e18, "denominator = real stakes only");
        assertEq(IERC20(GFANG).balanceOf(MASONRY), 150e18, "50e18 donation stranded");
        console2.log("masonry stake 100e18, donation 50e18, excess stranded:", IERC20(GFANG).balanceOf(MASONRY) - IMasonry(MASONRY).totalSupply());

        // withdraw is epoch-locked (treasury epoch 0 pre-TGE) -> stake cannot even be exited yet
        // (roll one block: Masonry has a one-call-per-block ContractGuard keyed on tx.origin)
        assertEq(ITreasury(TREASURY).epoch(), 0, "epoch 0");
        vm.roll(block.number + 1);
        vm.prank(ATTACKER);
        vm.expectRevert("Masonry: still in withdraw lockup");
        IMasonry(MASONRY).withdraw(1e18);

        // allocateSeigniorage is operator-only (treasury) -> fresh caller cannot mint to self
        vm.prank(ATTACKER);
        vm.expectRevert("operator: caller is not the operator");
        IMasonry(MASONRY).allocateSeigniorage(1e18);
    }

    // ---------------------------------------------------------------------------------------
    // T5 — xGFANG redeem: 0-duration forfeits 90%, max-duration round trip is exactly neutral
    // ---------------------------------------------------------------------------------------
    function test_T5_xgfang_redeem_noFreeLunch() public {
        _forkRho();
        deal(XGFANG, ATTACKER, 2e18);
        // LIVE: redeeming is owner-disabled; unprivileged redeem reverts outright
        assertFalse(IxGFANG(XGFANG).redeemingEnabled(), "redeeming disabled live");
        vm.prank(ATTACKER);
        vm.expectRevert("XGFANG: redeeming is not enabled");
        IxGFANG(XGFANG).redeem(1e18, 259200);

        // mechanism demo (owner action simulated): enable, then prove the ratio math is not gamed
        vm.prank(OWNER_EOA);
        IxGFANG(XGFANG).setRedeemingEnabled(true);
        assertEq(IxGFANG(XGFANG).getGfangByVestingDuration(1e18, 0), 1e17, "0-duration ratio = 10%");

        uint256 gStart = IERC20(GFANG).balanceOf(ATTACKER);
        // duration 0 -> immediate, forfeits 90%
        vm.prank(ATTACKER);
        IxGFANG(XGFANG).redeem(1e18, 0);
        uint256 afterImmediate = IERC20(GFANG).balanceOf(ATTACKER) - gStart;
        console2.log("redeem(1e18, 0) gFANG out:", afterImmediate);
        assertEq(afterImmediate, 1e17, "90% forfeited");

        // duration = maxRedeemDuration (3 days) -> 100% after vesting; still net zero
        vm.prank(ATTACKER);
        IxGFANG(XGFANG).redeem(1e18, 259200);
        vm.prank(ATTACKER);
        vm.expectRevert("XGFANG: finalizeRedeem: vesting duration has not ended yet");
        IxGFANG(XGFANG).finalizeRedeem(0);
        vm.warp(block.timestamp + 259201);
        vm.prank(ATTACKER);
        IxGFANG(XGFANG).finalizeRedeem(0);
        uint256 totalOut = IERC20(GFANG).balanceOf(ATTACKER) - gStart;
        console2.log("total gFANG out for 2e18 xGFANG:", totalOut);
        assertEq(totalOut, 1e18 + 1e17, "net loss of 0.9e18 xGFANG, no profit");
        assertEq(IxGFANG(XGFANG).balanceOf(ATTACKER), 0, "all xGFANG consumed");
    }

    // ---------------------------------------------------------------------------------------
    // T6 — FangRedeem: fixed $1 permissionless payout, pot empty today; funded case drains pot
    // ---------------------------------------------------------------------------------------
    function test_T6_fangredeem_fixed1usd_conditional() public {
        _forkRho();
        assertEq(IFangRedeem(FANGREDEEM).quoteRedeem(1e18), 1e6, "1 FANG = 1.000000 USDG");
        assertEq(IERC20(USDG).balanceOf(FANGREDEEM), 0, "USDC pot empty today");

        deal(FANG, ATTACKER, 1_000e18);
        vm.prank(ATTACKER);
        vm.expectRevert("Insufficient USDC");
        IFangRedeem(FANGREDEEM).redeemFang(1e18); // closed live: pot unfunded

        // simulate the protocol funding the pot (owner-only action), then the permissionless
        // fixed-$1 exit is open to any attacker holding FANG. Mechanism demo only.
        deal(USDG, OWNER_EOA, 1_000e6);
        vm.startPrank(OWNER_EOA);
        IERC20(USDG).approve(FANGREDEEM, type(uint256).max);
        IFangRedeem(FANGREDEEM).supplyUSDC(1_000e6);
        vm.stopPrank();
        uint256 aBefore = IERC20(USDG).balanceOf(ATTACKER);
        vm.startPrank(ATTACKER);
        IERC20(FANG).approve(FANGREDEEM, type(uint256).max);
        IFangRedeem(FANGREDEEM).redeemFang(1_000e18);
        vm.stopPrank();
        uint256 gained = IERC20(USDG).balanceOf(ATTACKER) - aBefore;
        console2.log("funded-pot drain: FANG in 1000e18, USDG out:", gained);
        assertEq(gained, 1_000e6, "pot drained at $1/FANG");
        assertEq(IERC20(USDG).balanceOf(FANGREDEEM), 0, "pot emptied");
    }

    // ---------------------------------------------------------------------------------------
    // T7 — Treasury: not started; permissionless allocateSeigniorage reverts pre-TGE
    // ---------------------------------------------------------------------------------------
    function test_T7_treasury_preStart() public {
        _forkRho();
        assertEq(ITreasury(TREASURY).epoch(), 0, "epoch 0");
        assertGt(ITreasury(TREASURY).nextEpochPoint(), block.timestamp, "treasury not started");
        vm.prank(ATTACKER);
        vm.expectRevert("Treasury: not started yet");
        ITreasury(TREASURY).allocateSeigniorage();
    }
}
