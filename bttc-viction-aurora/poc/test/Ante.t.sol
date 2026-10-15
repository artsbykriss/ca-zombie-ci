// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IAntePool {
    function stake(bool isChallenger) external payable;
    function unstake(uint256 amount, bool isChallenger) external;
    function unstakeAll(bool isChallenger) external;
    function checkTest() external;
    function claim() external;
    function withdrawStake() external;
    function pendingFailure() external view returns (bool);
    function failedBlock() external view returns (uint256);
    function numTimesVerified() external view returns (uint256);
    function anteTest() external view returns (address);
    function verifier() external view returns (address);
    function getTotalStaked() external view returns (uint256);
    function getTotalChallengerStaked() external view returns (uint256);
    function getVerifierBounty() external view returns (uint256);
    function getCheckTestAllowedBlock(address) external view returns (uint256);
}

interface IAnteTest {
    function checkTestPasses() external returns (bool);
    function testName() external view returns (string memory);
    function testAuthor() external view returns (address);
}

interface IAuriOracle {
    function mainFeed(address) external view returns (uint216 answer, uint8 underlyingDecimal, uint32 updatedAt);
    function updateMainFeedData(address, int256, uint256) external;
    function updator1() external view returns (address);
    function updator2() external view returns (address);
    function updator3() external view returns (address);
    function validPeriod() external view returns (uint256);
}

/// @title AntePool v0.5.2 (Aurora) — adversarial fork tests
/// @notice The 1 ETH pot is staker-owned; the test reads an updator-gated stale oracle feed.
contract AnteTest is Test {
    address constant POOL = 0xA32046e096fAc0aD197089f22103d6c76dc9b684;
    address constant TEST_ = 0x40107F542c6D7d9d9C9F7c46FB8874eF59fD3C65;
    address constant ORACLE = 0xC6e5185438e1730959c1eF3551059A3feC744E90; // AuriOracle
    address constant AUUSDC = 0x4f0d864b1ABf4B701799a0b30b57A22dFEB5917b;
    address constant STAKER = 0xa5b4f91FDE4E35Be891eA97C47D1052D8a4D75f7; // sole staker (1 ETH)
    address constant ATTACKER = address(0xA77ACCE7);

    bool forked;

    function setUp() public {
        string[2] memory urls = [
            vm.envOr("AURORA_RPC_URL", string("https://mainnet.aurora.dev")),
            "https://aurora.drpc.org"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) {
                forked = true;
                break;
            } catch {}
        }
    }

    modifier onlyFork() {
        if (!forked) {
            console2.log("SKIP: aurora fork unavailable");
            return;
        }
        _;
    }

    function test_01_live_state_and_test_passes() public onlyFork {
        assertEq(POOL.balance, 1 ether, "pot is 1 ETH");
        assertEq(IAntePool(POOL).getTotalStaked(), 1 ether, "staker side = 1 ETH");
        assertEq(IAntePool(POOL).getTotalChallengerStaked(), 0, "no challengers");
        assertFalse(IAntePool(POOL).pendingFailure(), "pool not failed");
        assertEq(IAntePool(POOL).anteTest(), TEST_, "test address");

        // the Ante test currently PASSES (reads mainFeed(auUSDC) > 90c)
        assertTrue(IAnteTest(TEST_).checkTestPasses(), "test must pass now");

        // the feed it reads is stale (Oct 2023) but still > 0.9
        (uint216 answer, uint8 dec, uint32 updatedAt) = IAuriOracle(ORACLE).mainFeed(AUUSDC);
        console2.log("mainFeed(auUSDC).answer:", uint256(answer));
        console2.log("decimals:", dec);
        console2.log("updatedAt:", updatedAt);
        assertEq(dec, 6, "underlying decimals");
        assertGt(uint256(answer), 90000000, "stale feed still above 90c -> test passes");
        assertLt(uint256(updatedAt), block.timestamp - 300 days, "feed is stale");
    }

    function test_02_outsider_cannot_push_price() public onlyFork {
        // only the 3 hardcoded updator EOAs may update the feed
        assertEq(ORACLE.code.length > 0 ? 1 : 0, 1, "oracle has code");
        assertEq(IAuriOracle(ORACLE).updator1().code.length, 0, "updator1 is EOA");
        assertEq(IAuriOracle(ORACLE).updator2().code.length, 0, "updator2 is EOA");
        assertEq(IAuriOracle(ORACLE).updator3().code.length, 0, "updator3 is EOA");

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("not allowed"));
        IAuriOracle(ORACLE).updateMainFeedData(AUUSDC, 1, block.timestamp);

        // owner-gated knobs
        vm.prank(ATTACKER);
        (bool ok, ) = ORACLE.call(abi.encodeWithSignature("setPriceValidity(uint256)", 3650 days));
        assertFalse(ok, "setPriceValidity must be owner-only");
    }

    function test_03_outsider_challenger_path_is_benign_while_test_passes() public onlyFork {
        uint256 poolBefore = POOL.balance;
        // anyone can stake as challenger (>= 0.01 ETH) — permissionless by design
        vm.deal(ATTACKER, 1 ether);
        vm.prank(ATTACKER);
        IAntePool(POOL).stake{value: 0.01 ether}(true);
        assertEq(IAntePool(POOL).getTotalChallengerStaked(), 0.01 ether, "challenger stake recorded");

        // must wait 12 blocks, then only a challenger can call checkTest()
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes("ANTE: Only challengers can checkTest"));
        IAntePool(POOL).checkTest();

        vm.roll(block.number + 257);
        uint256 balBefore = POOL.balance;
        vm.prank(ATTACKER);
        IAntePool(POOL).checkTest();
        // test passes -> no failure, no payout
        assertFalse(IAntePool(POOL).pendingFailure(), "test passed; pool not failed");
        assertEq(IAntePool(POOL).numTimesVerified(), 1, "verification counter only");
        assertEq(POOL.balance, balBefore, "no value moved");

        // challenger can exit with funds (minus negligible decay)
        vm.prank(ATTACKER);
        IAntePool(POOL).unstakeAll(true);
        assertEq(POOL.balance, poolBefore, "pool back to 1 ETH (challenger whole)");
    }

    function test_04_no_payout_without_failure() public onlyFork {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("ANTE: Test has not failed"));
        IAntePool(POOL).claim();

        // staker can self-withdraw (H-O): unstake + 24h + withdrawStake
        vm.prank(STAKER);
        IAntePool(POOL).unstakeAll(false);
        assertEq(IAntePool(POOL).getTotalStaked(), 0, "staker unstaked");
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 25 hours);
        vm.prank(STAKER);
        IAntePool(POOL).withdrawStake();
        assertEq(POOL.balance, 0, "staker recovered the 1 ETH (H-O)");
    }

    function test_05_failure_path_math_if_oracle_ever_moved() public onlyFork {
        // illustrative: IF the updators pushed auUSDC below 90c, a challenger who staked
        // >=12 blocks earlier would become verifier and (as sole eligible challenger)
        // claim ~95% of the staker pot + 5% bounty. Requires 2-of-3 updator keys.
        uint256 bounty = IAntePool(POOL).getVerifierBounty();
        assertEq(bounty, 0.05 ether, "verifier bounty = 5% of staker pot");
        console2.log("conditional challenger payout (sole eligible): ~", (1 ether - bounty), "wei + own stake + bounty");
    }
}
