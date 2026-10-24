// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiLockMoat is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    event RewardTokenAdded(address indexed token);

    struct Lock {
        uint256 amount;
        uint256 end;
        uint256 points;
        uint256 originalDuration;
        uint256 lastUpdated;
        bool active;
    }

    struct UserInfo {
        uint256 stakedAmount;
        uint256 totalUserBurn;
        uint256 stakingPoints;
        uint256 burnPoints;
        mapping(address => uint256) rewardDebt;
        Lock[] locks;
        uint256 activeLockCount;
    }

    struct RewardTokenInfo {
        IERC20 token;
        uint256 accRewardPerPoint;
        uint256 unallocatedRewards;
        uint256 totalRewardsDeposited;
        uint256 totalRewardsClaimed;
    }

    IERC20 public immutable stakingToken;
    uint8 public immutable tokenDecimals;
    uint256 public immutable POINTS_SCALING_FACTOR;
    uint256 public immutable MIN_STAKE_AMOUNT;
    address public constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;

    address[] public rewardTokenAddresses;
    mapping(address => RewardTokenInfo) public rewardInfo;

    string private _logoURL;
    address[] public activeUsers;
    mapping(address => bool) public isActiveUser;
    uint256 public activeUserCount;

    uint256 public constant POINTS_PER_TOKEN = 1;

    uint256 public constant BURN_MULTIPLIER = 10;
    uint256 public constant MAX_LOCK_DURATION = 730 days;
    uint256 public constant MIN_LOCK_DURATION = 1 days;
    uint256 public constant MIN_LOCK_MULTIPLIER = 2;
    uint256 public constant MAX_LOCK_MULTIPLIER = 5;
    uint256 public constant PRECISION_FACTOR = 1e18;
    uint256 public constant MULTIPLIER_PRECISION = 1e18;
    uint256 public constant EARLY_EXIT_MAX_FEE = 9500;
    uint256 public constant MAX_FEE = 3000;

    uint256 public totalPoints;
    uint256 public lastRewardBlock;
    uint256 public totalStaked;
    uint256 public totalLocked;
    uint256 public totalBurned;
    bool public emergencyUnlockEnabled = false;
    uint256 public unstakeFee = 50;
    address public feeCollector;
    bool public stakingEnabled = true;
    bool public earlyExitEnabled = true;
    bool public lockingEnabled = true;
    bool public burningEnabled = true;
    bool public paused = false;
    mapping(address => bool) public admins;
    mapping(address => UserInfo) public userInfo;

    // Moat manager role
    address public moatManager;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Locked(
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 lockIndex
    );
    event Burned(address indexed user, uint256 amount);

    event RewardClaimed(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event RewardsDeposited(address indexed token, uint256 amount);
    event StakeIncreased(
        address indexed user,
        uint256 additionalAmount,
        uint256 newTotalAmount
    );
    event LockExited(address indexed user, uint256 amount, uint256 lockIndex);
    event EarlyExit(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 lockIndex
    );
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newCollector);
    event UserAction(
        address indexed user,
        string actionType,
        uint256 amount,
        uint256 points,
        uint256 timestamp,
        bytes extraData
    );
    event BurnPointsMigrated(
        address indexed user,
        uint256 addedBurnAmount,
        uint256 addedBurnPoints
    );
    event EmergencyRewardWithdrawal(
        address indexed token,
        uint256 amount,
        address indexed recipient
    );

    constructor(
        address _stakingToken,
        address _feeCollector,
        address _adminWallet
    ) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_feeCollector != address(0), "Invalid fee collector");
        require(_adminWallet != address(0), "Invalid admin wallet");

        stakingToken = IERC20(_stakingToken);
        tokenDecimals = IERC20Metadata(_stakingToken).decimals();

        POINTS_SCALING_FACTOR = tokenDecimals >= 12
            ? 10 ** 12
            : 10 ** tokenDecimals;

        feeCollector = _feeCollector;
        MIN_STAKE_AMOUNT = POINTS_SCALING_FACTOR;
        admins[_adminWallet] = true;

        moatManager = _adminWallet;
    }

    modifier whenStakingEnabled() {
        require(stakingEnabled, "Staking is disabled");
        _;
    }
    modifier whenEarlyExitEnabled() {
        require(earlyExitEnabled, "Early exit is disabled");
        _;
    }
    modifier onlyAdmin() {
        require(owner() == msg.sender || admins[msg.sender], "Not admin");
        _;
    }
    modifier onlyMoatManager() {
        require(msg.sender == moatManager, "Not moat manager");
        _;
    }
    modifier whenLockingEnabled() {
        require(lockingEnabled, "Locking is disabled");
        _;
    }
    modifier whenBurningEnabled() {
        require(burningEnabled, "Burning is disabled");
        _;
    }
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function addRewardToken(address _rewardToken) external onlyAdmin {
        require(_rewardToken != address(0), "Invalid reward token");
        require(
            rewardInfo[_rewardToken].token == IERC20(address(0)),
            "Reward token already exists"
        );

        rewardInfo[_rewardToken] = RewardTokenInfo({
            token: IERC20(_rewardToken),
            accRewardPerPoint: 0,
            unallocatedRewards: 0,
            totalRewardsDeposited: 0,
            totalRewardsClaimed: 0
        });
        rewardTokenAddresses.push(_rewardToken);
        emit RewardTokenAdded(_rewardToken);
    }

    function depositRewards(
        address _rewardToken,
        uint256 _amount
    ) external onlyAdmin whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot deposit 0");
        require(
            rewardInfo[_rewardToken].token != IERC20(address(0)),
            "Reward token not added"
        );

        RewardTokenInfo storage reward = rewardInfo[_rewardToken];
        reward.token.safeTransferFrom(msg.sender, address(this), _amount);
        reward.unallocatedRewards += _amount;
        reward.totalRewardsDeposited += _amount;

        distributeRewards();

        emit RewardsDeposited(_rewardToken, _amount);
    }

    function setLockingEnabled(bool _enabled) external onlyAdmin {
        lockingEnabled = _enabled;
    }

    function setBurningEnabled(bool _enabled) external onlyAdmin {
        burningEnabled = _enabled;
    }

    function setStakingEnabled(bool _enabled) external onlyMoatManager {
        stakingEnabled = _enabled;
    }

    function setEarlyExitEnabled(bool _enabled) external onlyAdmin {
        earlyExitEnabled = _enabled;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Zero address not allowed");
        require(!admins[_admin], "Already admin");
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != owner(), "Cannot remove owner");
        require(_admin != moatManager, "Cannot remove moat manager");
        require(admins[_admin], "Not admin");
        admins[_admin] = false;
    }

    function setUnstakeFee(uint256 _newFee) external onlyMoatManager {
        require(_newFee <= MAX_FEE, "Fee too high");
        unstakeFee = _newFee;
    }

    function setFeeCollector(address _newCollector) external onlyMoatManager {
        require(_newCollector != address(0), "Invalid address");
        feeCollector = _newCollector;
    }

    function togglePause(bool _state) external onlyAdmin {
        paused = _state;
    }

    function enableEmergencyUnlock() external onlyAdmin {
        emergencyUnlockEnabled = true;
        paused = true;
    }

    function setLogoURL(string calldata newLogoURL) external onlyAdmin {
        require(bytes(newLogoURL).length > 0, "URL cannot be empty");
        _logoURL = newLogoURL;
    }

    function distributeRewards() internal {
        if (totalPoints > 0) {
            uint256 numRewardTokens = rewardTokenAddresses.length;
            for (uint i = 0; i < numRewardTokens; i++) {
                address rewardTokenAddress = rewardTokenAddresses[i];
                RewardTokenInfo storage reward = rewardInfo[rewardTokenAddress];

                if (reward.unallocatedRewards > 0) {
                    reward.accRewardPerPoint +=
                        (reward.unallocatedRewards * PRECISION_FACTOR) /
                        totalPoints;
                    reward.unallocatedRewards = 0;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        distributeRewards();
    }

    function stake(
        uint256 _amount
    ) external whenStakingEnabled whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        require(_amount >= MIN_STAKE_AMOUNT, "Amount below minimum");
        updatePool();
        UserInfo storage user = userInfo[msg.sender];

        _harvestAllRewards(msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 points = (_amount * POINTS_PER_TOKEN) / POINTS_SCALING_FACTOR;
        user.stakedAmount += _amount;
        user.stakingPoints += points;
        totalPoints += points;
        totalStaked += _amount;

        _updateAllRewardDebts(msg.sender);

        _addActiveUser(msg.sender);
        emit Staked(msg.sender, _amount);
    }

    function lock(
        uint256 _amount,
        uint256 _duration
    ) external whenLockingEnabled whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot lock 0");
        require(_amount >= MIN_STAKE_AMOUNT, "Amount below minimum");
        require(_duration >= MIN_LOCK_DURATION, "Duration too short");
        require(_duration <= MAX_LOCK_DURATION, "Duration too long");
        require(
            _amount <= stakingToken.balanceOf(msg.sender),
            "Insufficient balance"
        );

        updatePool();
        UserInfo storage user = userInfo[msg.sender];

        _harvestAllRewards(msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 multiplier = calculateLockMultiplier(_duration);
        uint256 points = (_amount * POINTS_PER_TOKEN * multiplier) /
            (POINTS_SCALING_FACTOR * MULTIPLIER_PRECISION);

        // Create new lock
        Lock memory newLock = Lock({
            amount: _amount,
            end: block.timestamp + _duration,
            points: points,
            originalDuration: _duration,
            lastUpdated: block.timestamp,
            active: true
        });

        user.locks.push(newLock);
        user.activeLockCount++;

        totalPoints += points;
        totalLocked += _amount;

        _updateAllRewardDebts(msg.sender);
        _addActiveUser(msg.sender);

        emit Locked(msg.sender, _amount, _duration, user.locks.length - 1);
    }

    function burn(
        uint256 _amount
    ) external whenBurningEnabled whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot burn 0");
        require(_amount >= MIN_STAKE_AMOUNT, "Amount below minimum");
        require(
            _amount <= stakingToken.balanceOf(msg.sender),
            "Insufficient balance"
        );

        updatePool();
        UserInfo storage user = userInfo[msg.sender];

        _harvestAllRewards(msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 points = (_amount * POINTS_PER_TOKEN * BURN_MULTIPLIER) /
            POINTS_SCALING_FACTOR;
        user.burnPoints += points;
        user.totalUserBurn += _amount;
        totalPoints += points;
        totalBurned += _amount;
        stakingToken.transfer(DEAD_WALLET, _amount);

        _updateAllRewardDebts(msg.sender);

        _addActiveUser(msg.sender);
        emit Burned(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedAmount >= _amount, "Insufficient staked amount");
        updatePool();

        _harvestAllRewards(msg.sender);

        uint256 remainingAmount = user.stakedAmount - _amount;

        if (remainingAmount > 0) {
            require(
                remainingAmount >= MIN_STAKE_AMOUNT,
                "Must unstake all or leave minimum amount"
            );
        }

        uint256 feeAmount = (_amount * unstakeFee) / 10000;
        uint256 amountAfterFee = _amount - feeAmount;

        user.stakedAmount -= _amount;
        totalStaked -= _amount;
        uint256 points = (_amount * POINTS_PER_TOKEN) / POINTS_SCALING_FACTOR;
        user.stakingPoints -= points;
        totalPoints -= points;

        _updateAllRewardDebts(msg.sender);

        if (feeAmount > 0) {
            stakingToken.safeTransfer(feeCollector, feeAmount);
        }
        stakingToken.safeTransfer(msg.sender, amountAfterFee);

        _removeActiveUser(msg.sender);
        emit Withdrawn(msg.sender, _amount);
    }

    function exitLock(uint256 _lockIndex) external whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_lockIndex < user.locks.length, "Invalid lock index");
        require(user.locks[_lockIndex].active, "Lock not active");
        require(user.locks[_lockIndex].amount > 0, "No locked tokens");
        require(
            block.timestamp >= user.locks[_lockIndex].end,
            "Lock period not ended"
        );

        updatePool();
        _harvestAllRewards(msg.sender);

        Lock storage lockData = user.locks[_lockIndex];
        uint256 lockAmount = lockData.amount;
        uint256 feeAmount = (lockAmount * unstakeFee) / 10000;
        uint256 amountAfterFee = lockAmount - feeAmount;

        totalLocked -= lockAmount;
        totalPoints -= lockData.points;

        // Deactivate the lock
        lockData.active = false;
        lockData.amount = 0;
        lockData.points = 0;
        lockData.lastUpdated = block.timestamp;
        user.activeLockCount--;

        _updateAllRewardDebts(msg.sender);

        if (feeAmount > 0) {
            stakingToken.safeTransfer(feeCollector, feeAmount);
        }
        stakingToken.safeTransfer(msg.sender, amountAfterFee);

        _removeActiveUser(msg.sender);
        emit LockExited(msg.sender, amountAfterFee, _lockIndex);
    }

    function earlyExitLock(
        uint256 _lockIndex
    ) external whenEarlyExitEnabled whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_lockIndex < user.locks.length, "Invalid lock index");
        require(user.locks[_lockIndex].active, "Lock not active");
        require(user.locks[_lockIndex].amount > 0, "No locked tokens");
        require(
            block.timestamp < user.locks[_lockIndex].end,
            "Lock period has ended"
        );

        updatePool();
        _harvestAllRewards(msg.sender);

        (uint256 feeAmount, uint256 amountAfterFee) = calculateEarlyExitFee(
            msg.sender,
            _lockIndex
        );

        Lock storage lockData = user.locks[_lockIndex];
        uint256 amountToReturn = lockData.amount;

        totalPoints -= lockData.points;
        totalLocked -= lockData.amount;

        // Deactivate the lock
        lockData.active = false;
        lockData.amount = 0;
        lockData.points = 0;
        lockData.lastUpdated = block.timestamp;
        user.activeLockCount--;

        _updateAllRewardDebts(msg.sender);

        if (feeAmount > 0) {
            stakingToken.safeTransfer(feeCollector, feeAmount);
        }
        stakingToken.safeTransfer(msg.sender, amountAfterFee);

        _removeActiveUser(msg.sender);
        emit EarlyExit(msg.sender, amountToReturn, feeAmount, _lockIndex);
    }

    function claimAllRewards() external whenNotPaused nonReentrant {
        _harvestAllRewards(msg.sender);
    }

    function _harvestAllRewards(address _user) internal {
        uint256 numRewardTokens = rewardTokenAddresses.length;
        if (numRewardTokens > 0) {
            updatePool();
            for (uint i = 0; i < numRewardTokens; i++) {
                address rewardTokenAddress = rewardTokenAddresses[i];
                uint256 pending = pendingRewards(_user, rewardTokenAddress);
                if (pending > 0) {
                    _harvestSingleReward(_user, rewardTokenAddress, pending);
                }
            }
        }
    }

    function _harvestSingleReward(
        address _user,
        address _rewardToken,
        uint256 _pending
    ) internal {
        UserInfo storage userData = userInfo[_user];
        RewardTokenInfo storage reward = rewardInfo[_rewardToken];

        uint256 currentPointsForDebt = getCurrentPoints(_user);
        userData.rewardDebt[_rewardToken] =
            (currentPointsForDebt * reward.accRewardPerPoint) /
            PRECISION_FACTOR;

        reward.totalRewardsClaimed += _pending;
        reward.token.safeTransfer(_user, _pending);

        emit RewardClaimed(_user, _rewardToken, _pending);
    }

    function _updateAllRewardDebts(address _user) internal {
        UserInfo storage user = userInfo[_user];
        uint256 totalUserPoints = getCurrentPoints(_user);
        uint256 numRewardTokens = rewardTokenAddresses.length;

        for (uint i = 0; i < numRewardTokens; i++) {
            address rewardTokenAddress = rewardTokenAddresses[i];
            user.rewardDebt[rewardTokenAddress] =
                (totalUserPoints *
                    rewardInfo[rewardTokenAddress].accRewardPerPoint) /
                PRECISION_FACTOR;
        }
    }

    function pendingRewards(
        address _user,
        address _rewardToken
    ) public view returns (uint256) {
        RewardTokenInfo storage reward = rewardInfo[_rewardToken];
        UserInfo storage user = userInfo[_user];
        uint256 currentPoints = getCurrentPoints(_user);

        uint256 accumulatedReward = (currentPoints * reward.accRewardPerPoint) /
            PRECISION_FACTOR;
        uint256 userRewardDebt = user.rewardDebt[_rewardToken];

        if (accumulatedReward <= userRewardDebt) {
            return 0;
        }
        return accumulatedReward - userRewardDebt;
    }

    function getAllPendingRewards(
        address _user
    ) external view returns (address[] memory, uint256[] memory) {
        uint256 numRewardTokens = rewardTokenAddresses.length;
        address[] memory tokens = new address[](numRewardTokens);
        uint256[] memory amounts = new uint256[](numRewardTokens);

        for (uint i = 0; i < numRewardTokens; i++) {
            address tokenAddress = rewardTokenAddresses[i];
            tokens[i] = tokenAddress;
            amounts[i] = pendingRewards(_user, tokenAddress);
        }
        return (tokens, amounts);
    }

    function getCurrentPoints(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 totalLockPoints = 0;

        for (uint256 i = 0; i < user.locks.length; i++) {
            if (user.locks[i].active && user.locks[i].amount > 0) {
                totalLockPoints += user.locks[i].points;
            }
        }

        return user.stakingPoints + totalLockPoints + user.burnPoints;
    }

    function calculateLockMultiplier(
        uint256 _duration
    ) public pure returns (uint256) {
        unchecked {
            if (_duration >= MAX_LOCK_DURATION) {
                return MAX_LOCK_MULTIPLIER * MULTIPLIER_PRECISION;
            }
            uint256 scaledDuration = _duration * 1e18;
            uint256 scaledMaxDuration = MAX_LOCK_DURATION * 1e18;
            uint256 multiplierIncrease = (sqrt(scaledDuration) *
                (MAX_LOCK_MULTIPLIER - MIN_LOCK_MULTIPLIER) *
                MULTIPLIER_PRECISION) / sqrt(scaledMaxDuration);
            return
                (MIN_LOCK_MULTIPLIER * MULTIPLIER_PRECISION) +
                multiplierIncrease;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function emergencyWithdraw() external nonReentrant {
        require(emergencyUnlockEnabled, "Emergency unlock not enabled");
        UserInfo storage user = userInfo[msg.sender];

        uint256 totalLockedAmount = 0;
        for (uint256 i = 0; i < user.locks.length; i++) {
            if (user.locks[i].active) {
                totalLockedAmount += user.locks[i].amount;
            }
        }

        uint256 totalAmount = user.stakedAmount + totalLockedAmount;
        require(totalAmount > 0, "Nothing to withdraw");
        require(
            stakingToken.balanceOf(address(this)) >= totalAmount,
            "Insufficient contract balance"
        );

        totalStaked -= user.stakedAmount;
        totalLocked -= totalLockedAmount;
        totalPoints -= (user.stakingPoints + user.burnPoints);

        // Subtract points from all active locks
        for (uint256 i = 0; i < user.locks.length; i++) {
            if (user.locks[i].active) {
                totalPoints -= user.locks[i].points;
            }
        }

        delete userInfo[msg.sender];
        stakingToken.safeTransfer(msg.sender, totalAmount);
        _removeActiveUser(msg.sender);
    }

    function calculateEarlyExitFee(
        address _user,
        uint256 _lockIndex
    ) public view returns (uint256 fee, uint256 amountAfterFee) {
        UserInfo storage user = userInfo[_user];
        require(_lockIndex < user.locks.length, "Invalid lock index");
        require(user.locks[_lockIndex].active, "Lock not active");
        require(user.locks[_lockIndex].amount > 0, "No locked tokens");
        require(
            block.timestamp < user.locks[_lockIndex].end,
            "Lock period ended"
        );

        Lock storage lockData = user.locks[_lockIndex];
        uint256 remainingDuration = lockData.end - block.timestamp;

        uint256 timeFeePercent = (remainingDuration * EARLY_EXIT_MAX_FEE) /
            lockData.originalDuration;

        uint256 feePercent = timeFeePercent > unstakeFee
            ? timeFeePercent
            : unstakeFee;

        fee = (lockData.amount * feePercent) / 10000;
        amountAfterFee = lockData.amount - fee;

        return (fee, amountAfterFee);
    }

    function _isUserActive(address _user) internal view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return
            user.stakedAmount > 0 ||
            user.activeLockCount > 0 ||
            user.burnPoints > 0;
    }

    function _addActiveUser(address _user) internal {
        if (!isActiveUser[_user] && _isUserActive(_user)) {
            activeUsers.push(_user);
            isActiveUser[_user] = true;
            activeUserCount++;
        }
    }

    function _removeActiveUser(address _user) internal {
        if (isActiveUser[_user] && !_isUserActive(_user)) {
            uint256 length = activeUsers.length;
            for (uint256 i = 0; i < length; i++) {
                if (activeUsers[i] == _user) {
                    activeUsers[i] = activeUsers[length - 1];
                    activeUsers.pop();
                    break;
                }
            }
            isActiveUser[_user] = false;
            activeUserCount--;
        }
    }

    // New view functions for multiple locks
    function getUserLockCount(address _user) external view returns (uint256) {
        return userInfo[_user].locks.length;
    }

    function getUserActiveLockCount(
        address _user
    ) external view returns (uint256) {
        return userInfo[_user].activeLockCount;
    }

    function getUserLock(
        address _user,
        uint256 _lockIndex
    )
        external
        view
        returns (
            uint256 amount,
            uint256 end,
            uint256 points,
            uint256 originalDuration,
            uint256 lastUpdated,
            bool active
        )
    {
        require(
            _lockIndex < userInfo[_user].locks.length,
            "Invalid lock index"
        );
        Lock storage lockData = userInfo[_user].locks[_lockIndex];
        return (
            lockData.amount,
            lockData.end,
            lockData.points,
            lockData.originalDuration,
            lockData.lastUpdated,
            lockData.active
        );
    }

    function getUserAllLocks(
        address _user
    )
        external
        view
        returns (
            uint256[] memory amounts,
            uint256[] memory ends,
            uint256[] memory points,
            uint256[] memory originalDurations,
            uint256[] memory lastUpdated,
            bool[] memory active
        )
    {
        UserInfo storage user = userInfo[_user];
        uint256 lockCount = user.locks.length;

        amounts = new uint256[](lockCount);
        ends = new uint256[](lockCount);
        points = new uint256[](lockCount);
        originalDurations = new uint256[](lockCount);
        lastUpdated = new uint256[](lockCount);
        active = new bool[](lockCount);

        for (uint256 i = 0; i < lockCount; i++) {
            Lock storage lockData = user.locks[i];
            amounts[i] = lockData.amount;
            ends[i] = lockData.end;
            points[i] = lockData.points;
            originalDurations[i] = lockData.originalDuration;
            lastUpdated[i] = lockData.lastUpdated;
            active[i] = lockData.active;
        }
    }

    function getActiveUserCount() external view returns (uint256) {
        return activeUserCount;
    }

    function getActiveUsers(
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (address[] memory) {
        require(_startIndex < activeUsers.length, "Start index out of range");
        require(_endIndex <= activeUsers.length, "End index out of range");
        require(_startIndex < _endIndex, "Invalid range");

        uint256 length = _endIndex - _startIndex;
        address[] memory users = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            users[i] = activeUsers[_startIndex + i];
        }

        return users;
    }

    function getTotalAmounts()
        external
        view
        returns (
            uint256 _totalStaked,
            uint256 _totalLocked,
            uint256 _totalBurned,
            uint256 _totalInContract
        )
    {
        return (
            totalStaked,
            totalLocked,
            totalBurned,
            stakingToken.balanceOf(address(this))
        );
    }

    function getLogoURL() external view returns (string memory) {
        return _logoURL;
    }

    function getRewardTokens()
        external
        view
        returns (
            address[] memory addresses,
            uint256[] memory totalDeposited,
            uint256[] memory totalClaimed,
            uint256[] memory unallocated
        )
    {
        uint256 numTokens = rewardTokenAddresses.length;

        addresses = new address[](numTokens);
        totalDeposited = new uint256[](numTokens);
        totalClaimed = new uint256[](numTokens);
        unallocated = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            address tokenAddress = rewardTokenAddresses[i];
            RewardTokenInfo storage info = rewardInfo[tokenAddress];

            addresses[i] = tokenAddress;
            totalDeposited[i] = info.totalRewardsDeposited;
            totalClaimed[i] = info.totalRewardsClaimed;
            unallocated[i] = info.unallocatedRewards;
        }

        return (addresses, totalDeposited, totalClaimed, unallocated);
    }

    function migrateBurnUsers(
        address[] calldata _users,
        uint256[] calldata _burnAmounts
    ) external onlyAdmin {
        require(_users.length == _burnAmounts.length, "Array mismatch");
        updatePool();
        for (uint i = 0; i < _users.length; i++) {
            address _user = _users[i];
            uint256 _burnAmountToAdd = _burnAmounts[i];
            require(_user != address(0), "Cannot migrate zero address");
            if (_burnAmountToAdd > 0) {
                UserInfo storage user = userInfo[_user];
                uint256 pointsToAdd = (_burnAmountToAdd *
                    POINTS_PER_TOKEN *
                    BURN_MULTIPLIER) / POINTS_SCALING_FACTOR;

                user.totalUserBurn += _burnAmountToAdd;
                user.burnPoints += pointsToAdd;

                totalPoints += pointsToAdd;
                totalBurned += _burnAmountToAdd;

                _addActiveUser(_user);
                _updateAllRewardDebts(_user);

                emit BurnPointsMigrated(_user, _burnAmountToAdd, pointsToAdd);
            }
        }
    }

    function emergencyWithdrawAllRewards(
        address _recipient
    ) external onlyAdmin nonReentrant {
        require(emergencyUnlockEnabled, "Emergency unlock not enabled");
        require(_recipient != address(0), "Invalid recipient");

        uint256 numRewardTokens = rewardTokenAddresses.length;
        require(numRewardTokens > 0, "No reward tokens");

        for (uint256 i = 0; i < numRewardTokens; i++) {
            address rewardTokenAddress = rewardTokenAddresses[i];
            RewardTokenInfo storage reward = rewardInfo[rewardTokenAddress];

            uint256 balance = reward.token.balanceOf(address(this));

            if (balance > 0) {
                reward.token.safeTransfer(_recipient, balance);
                emit EmergencyRewardWithdrawal(
                    rewardTokenAddress,
                    balance,
                    _recipient
                );
            }
        }
    }

    function emergencyWithdrawRewardToken(
        address _rewardToken,
        address _recipient
    ) external onlyAdmin nonReentrant {
        require(emergencyUnlockEnabled, "Emergency unlock not enabled");
        require(_recipient != address(0), "Invalid recipient");
        require(
            rewardInfo[_rewardToken].token != IERC20(address(0)),
            "Reward token not added"
        );

        RewardTokenInfo storage reward = rewardInfo[_rewardToken];
        uint256 balance = reward.token.balanceOf(address(this));

        require(balance > 0, "No balance to withdraw");

        reward.token.safeTransfer(_recipient, balance);
        emit EmergencyRewardWithdrawal(_rewardToken, balance, _recipient);
    }
}
