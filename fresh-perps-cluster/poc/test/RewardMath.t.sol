// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.26;

import "../src/RewardMathModel.sol";

interface Vm {
    function roll(uint256 newHeight) external;
}

contract RewardMathTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    MockERC20 lp;
    MockPriceFeeds feeds;
    RewardMathModel model;

    uint256 pid0;
    uint256 pid1;

    function setUp() public {
        vm.roll(1000);
        lp = new MockERC20();
        feeds = new MockPriceFeeds();
        model = new RewardMathModel(address(this), address(feeds));
        pid0 = model.addPool(address(lp), 1e18);
        pid1 = model.addPool(address(lp), 1e18);
        feeds.set(address(lp), 1e18);
        model.setPointsPerBlock(10e18);
    }

    /// @notice A second massUpdatePools() in the same block is harmless: it
    ///         rebuilds totalValue from the stored lastValue of each pool and
    ///         skips accrual for pools already touched this block, so there is
    ///         no same-block double emission.
    function test_sameBlockSecondMassUpdateNoDoubleAccrual() public {
        model.seedPool(pid0, 1000e18, 900);
        model.seedPool(pid1, 1000e18, 900);

        vm.roll(1000);
        model.massUpdatePools();
        require(model.totalValue() == 2000e18, "totalValue #1");

        uint256 acc0 = model.accOf(pid0);
        model.massUpdatePools(); // second call, same block
        require(model.totalValue() == 2000e18, "totalValue rebuilt from lastValue");
        require(model.accOf(pid0) == acc0, "no same-block double accrual");

        vm.roll(1001);
        model.massUpdatePools(); // exactly one block of emission
        require(model.accOf(pid0) - acc0 == 5e15, "one block only");
        require(model.accOf(pid1) - acc0 == 5e15, "one block only (pool1)");
    }

    /// @notice A pool that withdrew to zero keeps its stale lastValue and keeps
    ///         diluting the value-weighted emission of the active pool.
    function test_staleZeroAmountPoolDilutesActivePool() public {
        model.seedPool(pid0, 500e18, 900);
        model.seedPool(pid1, 1000e18, 900);

        vm.roll(1000);
        model.massUpdatePools(); // pv[0].lastValue = 500e18, pv[1] = 1000e18
        uint256 accBefore = model.accOf(pid1);

        model.seedPool(pid0, 0, 1000); // simulate full withdrawal from pid0
        vm.roll(1001);
        model.massUpdatePools();

        uint256 delta = model.accOf(pid1) - accBefore;
        // Undiluted would be 10e18 / 1000e18 * 1e18 = 1e16.
        // With 500e18 stale weight: 10e18 * 1000/1500 / 1000 * 1e18 = 6.666...e15.
        require(delta == 6666666666666666, "diluted acc");
        require(delta < 10e15, "must be diluted by stale pool");
    }

    /// @notice updateUserInfo() credits the claimed amount with the full
    ///         historical accPointsPerShare, on top of the rewardSettled that
    ///         comes from the merkle leaf.  This is the deployed migration
    ///         formula (comment says "backdated rewards on claimed amounts").
    function test_migrationBackdatedCredit() public {
        model.seedPool(pid0, 1000e18, 1000);

        vm.roll(1000);
        model.massUpdatePools();
        vm.roll(1100);
        model.massUpdatePools(); // one full 100-block emission, single pool

        uint256 acc = model.accOf(pid0);
        require(acc == 1e18, "one point per share");

        address user = address(0xA11CE);
        model.updateUserInfo(user, pid0, RewardMathModel.UserInfo(100e18, 0, 100e18, 5e18, 0));

        (uint256 amount, uint256 boost, uint256 dep, uint256 settled, uint256 debt) =
            model.userInfo(pid0, user);
        require(amount == 100e18, "amount credited");
        require(boost == 0, "no boost");
        require(dep == 100e18, "deposit credited");
        require(settled == 105e18, "backdated 100e18 + leaf 5e18");
        require(debt == 100e18, "debt reset on new amount only");
    }

    /// @notice withdraw() is hard-bounded by user.depositAmount; the max
    ///         sentinel bypasses the zero check but moves zero tokens.
    function test_withdrawBoundedAndMaxNoop() public {
        lp.mint(address(model), 100e18);
        model.seedPool(pid0, 100e18, 1000);
        model.seedUser(pid0, address(this), 100e18, 100e18, 0, 0);

        vm.roll(1000);
        try model.withdraw(pid0, 101e18) {
            revert("should revert");
        } catch {}

        model.withdraw(pid0, type(uint256).max);
        require(lp.balanceOf(address(this)) == 100e18, "paid exactly deposit");

        // boost-only user: depositAmount = 0, amount = 50e18
        model.seedUser(pid0, address(this), 50e18, 0, 0, 0);
        model.withdraw(pid0, type(uint256).max); // zero-value no-op, succeeds
        try model.withdraw(pid0, 1) {
            revert("should revert");
        } catch {}
    }

    /// @notice The deployed contract transfers the LP token before checking
    ///         isFarmingEnded(); the revert unwinds the transfer.
    function test_depositAfterFarmEndReverts() public {
        model.setEndBlock(1000, 86400);
        vm.roll(1001);
        lp.mint(address(this), 1e18);
        lp.approve(address(model), 1e18);
        try model.deposit(pid0, 1e18, 0) {
            revert("should revert");
        } catch {}
        require(lp.balanceOf(address(this)) == 1e18, "transfer unwound");
    }

    /// @notice updateUserInfo is hard-gated to the immutable MERKLE address.
    function test_updateUserInfoOnlyMerkle() public {
        RewardMathModel guarded = new RewardMathModel(address(0xDEAD), address(feeds));
        uint256 p = guarded.addPool(address(lp), 1e18);
        vm.roll(1000);
        guarded.seedPool(p, 1000e18, 1000);
        try guarded.updateUserInfo(address(this), p, RewardMathModel.UserInfo(1e18, 0, 1e18, 0, 0)) {
            revert("should revert");
        } catch {}
    }
}
