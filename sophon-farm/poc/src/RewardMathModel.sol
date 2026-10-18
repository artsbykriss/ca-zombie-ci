// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.26;

/// @notice Minimal logic model of the deployed SophonFarmingL2 reward math.
///         This is NOT a fork of the zkEVM chain (Foundry/revm cannot execute
///         zkSync-era bytecode); it is a line-for-line port of updatePool /
///         massUpdatePools / _settlePool / deposit / withdraw / updateUserInfo
///         used to demonstrate the accounting behaviour of the source.

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IPriceFeedsLike {
    function getPrice(address) external view returns (uint256);
}

contract RewardMathModel {
    struct PoolInfo {
        IERC20Like lpToken;
        uint256 amount;
        uint256 boostAmount;
        uint256 depositAmount;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accPointsPerShare;
        uint256 totalRewards;
    }

    struct UserInfo {
        uint256 amount;
        uint256 boostAmount;
        uint256 depositAmount;
        uint256 rewardSettled;
        uint256 rewardDebt;
    }

    struct PoolValue {
        uint256 lastValue;
        uint256 emissionsMultiplier;
    }

    address public immutable MERKLE;
    IPriceFeedsLike public immutable priceFeeds;

    uint256 public pointsPerBlock;
    uint256 public endBlock;
    uint256 public endBlockForWithdrawals;
    uint256 public totalValue;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => PoolValue) public poolValue;

    error OnlyMerkle();
    error FarmingIsEnded();
    error WithdrawNotAllowed();
    error WithdrawIsZero();
    error WithdrawTooHigh(uint256);
    error InvalidDeposit();

    constructor(address _merkle, address _feeds) {
        MERKLE = _merkle;
        priceFeeds = IPriceFeedsLike(_feeds);
    }

    // ---------------------------------------------------------------------
    // test helpers
    // ---------------------------------------------------------------------
    function addPool(address lp, uint256 mult) external returns (uint256 pid) {
        pid = poolInfo.length;
        poolInfo.push(PoolInfo(IERC20Like(lp), 0, 0, 0, 0, block.number, 0, 0));
        poolValue[pid].emissionsMultiplier = mult == 0 ? 1e18 : mult;
    }

    function seedPool(uint256 pid, uint256 amount, uint256 lastRewardBlock) external {
        poolInfo[pid].amount = amount;
        poolInfo[pid].depositAmount = amount;
        poolInfo[pid].lastRewardBlock = lastRewardBlock;
    }

    function seedUser(
        uint256 pid,
        address user,
        uint256 amount,
        uint256 depositAmount,
        uint256 settled,
        uint256 debt
    ) external {
        userInfo[pid][user] =
            UserInfo(amount, amount - depositAmount, depositAmount, settled, debt);
    }

    function setPoolValue(uint256 pid, uint256 lastValue, uint256 mult) external {
        poolValue[pid] = PoolValue(lastValue, mult);
    }

    function accOf(uint256 pid) external view returns (uint256) {
        return poolInfo[pid].accPointsPerShare;
    }

    function poolAmountOf(uint256 pid) external view returns (uint256) {
        return poolInfo[pid].amount;
    }

    function setPointsPerBlock(uint256 p) external {
        pointsPerBlock = p;
    }

    function setEndBlock(uint256 e, uint256 w) external {
        endBlock = e;
        endBlockForWithdrawals = e + w;
    }

    // ---------------------------------------------------------------------
    // deployed math (ported verbatim where possible)
    // ---------------------------------------------------------------------
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function isFarmingEnded() public view returns (bool) {
        return endBlock != 0 && block.number > endBlock;
    }

    function isWithdrawPeriodEnded() public view returns (bool) {
        return endBlockForWithdrawals != 0 && block.number > endBlockForWithdrawals;
    }

    function _getBlockMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (endBlock != 0) {
            to = to < endBlock ? to : endBlock;
        }
        return to > from ? (to - from) * 1e18 : 0;
    }

    function _settlePool(uint256 pid)
        internal
        view
        returns (uint256 accPointsPerShare, uint256 totalRewards)
    {
        PoolInfo storage pool = poolInfo[pid];
        accPointsPerShare = pool.accPointsPerShare;
        totalRewards = pool.totalRewards;

        uint256 lpSupply = pool.amount;
        uint256 _totalValue = totalValue;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && _totalValue != 0) {
            uint256 blockMultiplier = _getBlockMultiplier(pool.lastRewardBlock, block.number);
            uint256 pointReward =
                blockMultiplier * pointsPerBlock * poolValue[pid].lastValue / _totalValue;
            totalRewards = totalRewards + pointReward / 1e18;
            accPointsPerShare = pointReward / lpSupply + accPointsPerShare;
        }
    }

    function previewSettle(uint256 pid) external view returns (uint256, uint256) {
        return _settlePool(pid);
    }

    function pendingPoints(uint256 pid, address user) external view returns (uint256) {
        UserInfo storage u = userInfo[pid][user];
        (uint256 acc,) = _settlePool(pid);
        return u.amount * acc / 1e18 + u.rewardSettled - u.rewardDebt;
    }

    function _updatePool(uint256 pid) internal returns (uint256[4] memory values) {
        PoolInfo storage pool = poolInfo[pid];
        values[0] = pool.lastRewardBlock;

        if (block.number < values[0]) return values;

        PoolValue storage pv = poolValue[pid];
        values[1] = pv.lastValue;

        if (block.number == values[0]) return values;

        values[2] = pool.amount;
        if (values[2] == 0) return values;

        values[3] = priceFeeds.getPrice(address(pool.lpToken));
        if (values[3] == 0) return values;

        uint256 newValue = values[2] * values[3] / 1e18;
        newValue = newValue * pv.emissionsMultiplier / 1e18;
        if (newValue == 0) return values;

        pv.lastValue = newValue;
        values[1] = newValue;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalNewValue;
        uint256 pid;

        uint256[4][] memory valuesArray = new uint256[4][](length);
        for (pid = 0; pid < length; ++pid) {
            valuesArray[pid] = _updatePool(pid);
            totalNewValue += valuesArray[pid][1];
        }

        totalValue = totalNewValue;

        uint256 _pointsPerBlock = pointsPerBlock;
        for (pid = 0; pid < length; ++pid) {
            uint256[4] memory values = valuesArray[pid];
            PoolInfo storage pool = poolInfo[pid];

            if (block.number <= values[0]) continue;

            if (values[2] != 0 && values[1] != 0) {
                uint256 blockMultiplier = _getBlockMultiplier(values[0], block.number);
                uint256 pointReward =
                    blockMultiplier * _pointsPerBlock * values[1] / totalNewValue;

                pool.totalRewards = pool.totalRewards + pointReward / 1e18;
                pool.accPointsPerShare = pointReward / values[2] + pool.accPointsPerShare;
            }

            pool.lastRewardBlock = block.number;
        }
    }

    function deposit(uint256 pid, uint256 amount, uint256) external {
        poolInfo[pid].lpToken.transferFrom(msg.sender, address(this), amount);
        if (isFarmingEnded()) revert FarmingIsEnded();
        if (amount == 0) revert InvalidDeposit();

        massUpdatePools();

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 userAmount = user.amount;

        user.rewardSettled =
            userAmount * pool.accPointsPerShare / 1e18 + user.rewardSettled - user.rewardDebt;

        user.depositAmount += amount;
        pool.depositAmount += amount;

        userAmount += amount;
        user.amount = userAmount;
        pool.amount += amount;

        user.rewardDebt = userAmount * pool.accPointsPerShare / 1e18;
    }

    function withdraw(uint256 pid, uint256 amount) external {
        if (isWithdrawPeriodEnded()) revert WithdrawNotAllowed();
        if (amount == 0) revert WithdrawIsZero();

        massUpdatePools();

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 userDepositAmount = user.depositAmount;
        if (amount == type(uint256).max) {
            amount = userDepositAmount;
        } else if (amount > userDepositAmount) {
            revert WithdrawTooHigh(userDepositAmount);
        }

        uint256 userAmount = user.amount;
        user.rewardSettled =
            userAmount * pool.accPointsPerShare / 1e18 + user.rewardSettled - user.rewardDebt;

        user.depositAmount = userDepositAmount - amount;
        pool.depositAmount -= amount;

        userAmount -= amount;
        user.amount = userAmount;
        pool.amount -= amount;

        user.rewardDebt = userAmount * pool.accPointsPerShare / 1e18;

        pool.lpToken.transfer(msg.sender, amount);
    }

    function updateUserInfo(address user_, uint256 pid, UserInfo memory fromClaim) external {
        if (msg.sender != MERKLE) revert OnlyMerkle();
        require(
            fromClaim.amount == fromClaim.boostAmount + fromClaim.depositAmount,
            "balances don't match"
        );

        massUpdatePools();

        UserInfo storage user = userInfo[pid][user_];
        uint256 acc = poolInfo[pid].accPointsPerShare;

        user.amount = user.amount + fromClaim.amount;
        user.rewardSettled =
            user.amount * acc / 1e18 + user.rewardSettled - user.rewardDebt;
        user.rewardSettled = user.rewardSettled + fromClaim.rewardSettled;
        user.boostAmount = user.boostAmount + fromClaim.boostAmount;
        user.depositAmount = user.depositAmount + fromClaim.depositAmount;
        user.rewardDebt = user.amount * acc / 1e18;
    }
}

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function approve(address s, uint256 a) external returns (bool) {
        allowance[msg.sender][s] = a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a;
        balanceOf[f] -= a;
        balanceOf[to] += a;
        return true;
    }
}

contract MockPriceFeeds {
    mapping(address => uint256) public price;

    function set(address token, uint256 p) external {
        price[token] = p;
    }

    function getPrice(address token) external view returns (uint256) {
        return price[token];
    }
}
