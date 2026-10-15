// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IComp.sol";

/**
 * @dev RewardPool: Simple stake tokens and earn rewards
 */
contract RewardPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when DEEPR mining ends.
    uint256 public bonusEndTime;

    // The block number when DEEPR mining starts.
    uint256 public startTime;

    // Duration in seconds during which the tokens are locked after a withdraw request
    uint256 public timelockInterval;

    // The block number of the last pool update
    uint256 public lastRewardTime;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // DEEPR tokens created per second.
    uint256 public rewardsPerSec;

    // The precision factor
    uint256 public immutable PRECISION_FACTOR;

    // The reward token
    IERC20 public immutable rewardToken;

    // The staked token
    IERC20 public immutable stakedToken;

    // keeps track about the total supply of staked tokens
    uint256 public stakedSupply;

    // keeps track about the total supply of locked tokens awaiting a withdraw
    uint256 public lockedSupply;

    uint256 public constant MAX_EMISSION_RATE_PER_SEC = 10 ether;

    // trusted contract which can deposit for an user
    address public trustee;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 stakedAmount; // How many staked tokens the user has provided
        uint256 lockedRequestedAmount; // How many user tokens are locked waiting for withdraw
        uint256 rewardDebt; // Reward debt
        bool isRequestStarted; // Withdraw Request started flag
        uint256 requestTimestamp; // Withdraw Request Timestamp
    }

    // Modifier

    modifier onlyTrusted() {
        require(msg.sender == trustee, "only trusted contract");
        _;
    }

    // Events

    event Harvest(address indexed user, uint256 amount, address to);
    event Deposit(address indexed user, uint256 amount, address to);
    event WithdrawRequest(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(address indexed user, uint256 amount, address to);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event NewStartAndEndTime(uint256 startTime, uint256 endTime);
    event NewRewardPerTime(uint256 rewardsPerSec);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event NewTimelockInterval(uint256 _timelockInterval);
    event RewardsStop(uint256 blockTime);
    event UpdateEmissionRate(address indexed user, uint256 _rewardsPerSec);
    event UpdateTrustee(address _old, address _new);
    event PoolUpdated(
        uint256 lastRewardTime,
        uint256 supply,
        uint256 accRewardPerShare
    );
    event EmergencyRewardWithdraw(address indexed user, uint amount);
    event DelegateCompLikeToken(address indexed delegatee);

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardsPerSec: reward per block (in rewardToken)
     * @param _startTime: start timestamp
     * @param _bonusEndTime: end timestamp
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _timelockInterval: interval in seconds for the user to be able to withdraw their funds
     * @param _admin: admin address with ownership
     */
    constructor(
        ERC20 _stakedToken,
        ERC20 _rewardToken,
        uint256 _rewardsPerSec,
        uint256 _startTime,
        uint256 _bonusEndTime,
        uint256 _poolLimitPerUser,
        uint256 _timelockInterval,
        address _admin
    ) public {
        require(address(_stakedToken) != address(0), "init: zero address");
        require(address(_rewardToken) != address(0), "init: zero address");
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardsPerSec = _rewardsPerSec;
        startTime = _startTime;
        bonusEndTime = _bonusEndTime;
        timelockInterval = _timelockInterval;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(
            10 ** (uint256(30).sub(decimalsRewardToken))
        );

        // Set the lastRewardTime as the startTime
        lastRewardTime = startTime;

        stakedSupply = 0;
        lockedSupply = 0;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /**
     * @notice Deposit staked tokens
     * @param _amount: amount to deposit (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        _deposit(_amount, msg.sender);
    }

    /**
     * @notice Deposit staked tokens for a user, can only be done by a trusted contract (trustee)
     * @param _amount: amount to deposit (in rewardToken)
     * @param _to: address of the user for which should be deposit
     *
     */
    function depositOnBehalf(
        uint256 _amount,
        address _to
    ) external onlyTrusted {
        _deposit(_amount, _to);
    }

    /**
     * @notice Deposit staked tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function _deposit(uint256 _amount, address _to) internal {
        UserInfo storage user = userInfo[_to];

        require(
            user.isRequestStarted == false,
            "deposit: active withdraw request must end before making a new deposit"
        );

        uint256 userAmount = user.stakedAmount; // gas savings
        if (hasUserLimit) {
            require(
                _amount.add(userAmount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }

        _updatePool();

        user.stakedAmount = userAmount.add(_amount);

        stakedSupply = stakedSupply.add(_amount);

        user.rewardDebt = user.rewardDebt.add(
            (_amount.mul(accTokenPerShare)).div(PRECISION_FACTOR)
        );

        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, _to);
    }

    /**
     * @notice Collect reward tokens
     */
    function harvest() public {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        uint256 accRewards = (user.stakedAmount.mul(accTokenPerShare)).div(
            PRECISION_FACTOR
        );
        uint256 _pending = accRewards.sub(user.rewardDebt);

        user.rewardDebt = accRewards;

        if (_pending > 0) {
            rewardToken.safeTransfer(msg.sender, _pending);
        }

        emit Harvest(msg.sender, _pending, msg.sender);
    }

    /**
     * @notice Make the user Withdraw Request for the total staked amount and collect reward tokens
     * (if timelockInterval is 0, the tokens are not locked, and the withdrawal is made
     * in the same function without the timelock logic)
     */
    function withdrawRequestAndHarvest() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        uint256 userStakedAmount = user.stakedAmount; // gas savings

        require(
            user.isRequestStarted == false,
            "withdrawRequest: finalize the current withdraw request before starting another request"
        );
        require(
            userStakedAmount > 0,
            "withdrawRequest: staked amount must be greater than 0"
        );

        _updatePool();

        uint256 accRewards = userStakedAmount.mul(accTokenPerShare);
        uint256 _pending = accRewards.div(PRECISION_FACTOR).sub(
            user.rewardDebt
        );
        user.rewardDebt = accRewards
            .sub(userStakedAmount.mul(accTokenPerShare))
            .div(PRECISION_FACTOR);

        user.stakedAmount = 0;
        stakedSupply = stakedSupply.sub(userStakedAmount);

        if (_pending > 0) {
            rewardToken.safeTransfer(msg.sender, _pending);
        }

        // If timelockInterval is 0, there is no need to lock the funds, the safeTransfer is done automatically
        if (timelockInterval != 0) {
            user.isRequestStarted = true;
            user.requestTimestamp = block.timestamp;
            // Internal transfer of amount from Staked state to Locked state
            user.lockedRequestedAmount = userStakedAmount;
            lockedSupply = lockedSupply.add(userStakedAmount);
            emit WithdrawRequest(msg.sender, userStakedAmount, block.timestamp);
        } else {
            stakedToken.safeTransfer(msg.sender, userStakedAmount);
            emit Withdraw(msg.sender, userStakedAmount, msg.sender);
        }

        emit Harvest(msg.sender, _pending, msg.sender);
    }

    /**
     * @notice Withdraw locked tokens after the lock period
     */
    function withdrawLockedTokens() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(
            user.isRequestStarted == true,
            "withdrawLockedTokens: request must be started before withdraw"
        );
        require(
            block.timestamp > user.requestTimestamp + timelockInterval,
            "withdrawLockedTokens: tokens still locked, timelockInterval has not been surpassed yet"
        );

        uint256 userLockedAmount = user.lockedRequestedAmount; // gas savings

        user.lockedRequestedAmount = 0;
        lockedSupply = lockedSupply.sub(userLockedAmount);

        stakedToken.safeTransfer(msg.sender, userLockedAmount);

        user.isRequestStarted = false; // set flag again to false allow new future stakes by the user
        user.requestTimestamp = 0;

        emit Withdraw(msg.sender, userLockedAmount, msg.sender);
    }

    /**
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(msg.sender, _amount);

        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    /**
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndTime = block.timestamp;
        emit RewardsStop(block.timestamp);
    }

    /**
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(_poolLimitPerUser);
    }

    /**
     * @notice Update timelock interval
     * @dev Only callable by owner.
     * @param _timelockInterval: duration in seconds during which the tokens are locked after a withdraw request
     */
    function updateTimelockInterval(
        uint256 _timelockInterval
    ) external onlyOwner {
        timelockInterval = _timelockInterval;
        emit NewTimelockInterval(_timelockInterval);
    }

    /**
     * @notice Update reward per second
     * @dev Only callable by owner.
     * @param _rewardsPerSec: the reward per second
     */
    function updateRewardPerSecond(uint256 _rewardsPerSec) external onlyOwner {
        require(
            _rewardsPerSec <= MAX_EMISSION_RATE_PER_SEC,
            "update: emission rate too high"
        );
        _updatePool();
        rewardsPerSec = _rewardsPerSec;
        emit UpdateEmissionRate(msg.sender, _rewardsPerSec);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startTime: the new start timestamp
     * @param _bonusEndTime: the new end timestamp
     */
    function updateStartAndEndTime(
        uint256 _startTime,
        uint256 _bonusEndTime
    ) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        require(
            _startTime < _bonusEndTime,
            "New startTime must be lower than new endTime"
        );
        require(
            block.timestamp < _startTime,
            "New startTime must be higher than current block time"
        );

        startTime = _startTime;
        bonusEndTime = _bonusEndTime;

        // Set the lastRewardTime as the startTime
        lastRewardTime = startTime;

        emit NewStartAndEndTime(_startTime, _bonusEndTime);
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedSupply;
        uint256 currentBlockTime = block.timestamp;
        uint256 _lastRewardTime = lastRewardTime; // gas savings
        if (currentBlockTime > _lastRewardTime && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(
                _lastRewardTime,
                currentBlockTime
            );
            uint256 cakeReward = multiplier.mul(rewardsPerSec);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            return
                user
                    .stakedAmount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        } else {
            return
                user
                    .stakedAmount
                    .mul(accTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        }
    }

    /**
     * @notice View function to see if the user has an active withdraw request (has locked tokens)
     * @param _user: user address
     * @return isRequestStarted boolean
     */
    function hasActiveWithdrawRequest(
        address _user
    ) external view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return user.isRequestStarted;
    }

    /**
     * @notice View function to see the Timestamp where the user will be allowed to withdraw their locked tokens
     * @param _user: user address
     * @return Lock End Timestamp
     */
    function userLockEndTimestamp(
        address _user
    ) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        require(
            user.isRequestStarted == true,
            "this user does not have an active withdraw request"
        );
        return user.requestTimestamp + timelockInterval;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        uint256 _lastRewardTime = lastRewardTime;
        if (block.timestamp <= _lastRewardTime) {
            return;
        }

        uint256 stakedTokenSupply = stakedSupply;
        if (stakedTokenSupply == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(_lastRewardTime, block.timestamp);
        uint256 reward = multiplier.mul(rewardsPerSec);
        accTokenPerShare = accTokenPerShare.add(
            reward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
        );
        lastRewardTime = block.timestamp;
        emit PoolUpdated(_lastRewardTime, stakedTokenSupply, accTokenPerShare);
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    ) internal view returns (uint256) {
        uint256 _bonusEndTime = bonusEndTime;
        if (_to <= _bonusEndTime) {
            return _to.sub(_from);
        } else if (_from >= _bonusEndTime) {
            return 0;
        } else {
            return _bonusEndTime.sub(_from);
        }
    }

    /**
     * @dev update user limits
     */
    function updateUserPoolLimit(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(_hasUserLimit ? _poolLimitPerUser : 0);
    }

    /**
     * @notice Top up reward token as a safer alternative to transfer
     * @param amount Amount of rewards to add
     */
    function topUpRewards(uint256 amount) external {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Update the trustee, which can do a user deposit
     * @param _trustee address of the new trusted contract
     */
    function updateTrustee(address _trustee) external onlyOwner {
        require(_trustee != address(0), "can not be zero");
        address old = trustee;
        trustee = _trustee;
        emit UpdateTrustee(old, _trustee);
    }

    /**
     * @notice Admin call to delegate the votes of the COMP-like stake token
     * @param delegatee The address to delegate votes to
     * @dev Staked Tokens other than COMP-like should revert here
     */
    function delegateCompLikeTo(address delegatee) external onlyOwner {
        IComp(address(stakedToken)).delegate(delegatee);
        emit DelegateCompLikeToken(delegatee);
    }
}
