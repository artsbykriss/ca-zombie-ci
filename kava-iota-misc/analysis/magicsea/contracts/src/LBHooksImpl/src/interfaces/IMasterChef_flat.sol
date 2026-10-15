// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// src/libraries/Constants.sol

/**
 * @title Constants Library
 * @dev A library that defines various constants used throughout the codebase.
 */
library Constants {
    uint256 internal constant ACC_PRECISION_BITS = 64;
    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant MAX_NUMBER_OF_FARMS = 32;
    uint256 internal constant MAX_NUMBER_OF_REWARDS = 32;

    uint256 internal constant MAX_LUM_PER_SECOND = 10e18;

    uint256 internal constant MAX_BRIBES_PER_POOL = 5;
}

// src/libraries/Math.sol

/**
 * @title Math
 * @dev Library for mathematical operations with overflow and underflow checks.
 */
library Math {
    error Math__UnderOverflow();

    uint256 internal constant MAX_INT256 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @dev Adds a signed integer to an unsigned integer with overflow check.
     * The result must be greater than or equal to 0 and less than or equal to MAX_INT256.
     * @param x Unsigned integer to add to.
     * @param delta Signed integer to add.
     * @return y The result of the addition.
     */
    function addDelta(uint256 x, int256 delta) internal pure returns (uint256 y) {
        uint256 success;

        assembly {
            y := add(x, delta)

            success := iszero(or(gt(x, MAX_INT256), gt(y, MAX_INT256)))
        }

        if (success == 0) revert Math__UnderOverflow();
    }

    /**
     * @dev Safely converts an unsigned integer to a signed integer.
     * @param x Unsigned integer to convert.
     * @return y Signed integer result.
     */
    function toInt256(uint256 x) internal pure returns (int256 y) {
        if (x > MAX_INT256) revert Math__UnderOverflow();

        return int256(x);
    }
}

// src/interfaces/ILum.sol

interface ILum is IERC20 {
    function mint(address account, uint256 amount) external returns (uint256);
}

// src/interfaces/IRewarder.sol

interface IRewarder {
    function getToken() external view returns (IERC20);

    function getCaller() external view returns (address);

    function initialize(address initialOwner) external;
}

// src/libraries/Amounts.sol

/**
 * @title Amounts Library
 * @dev A library that defines various functions for manipulating amounts of a key and a total.
 * The key can be bytes32, address, or uint256.
 */
library Amounts {
    using Math for uint256;

    struct Parameter {
        uint256 totalAmount;
        mapping(bytes32 => uint256) amounts;
    }

    /**
     * @dev Returns the amount of a key.
     * @param amounts The storage pointer to the amounts.
     * @param key The key of the amount.
     * @return The amount of the key.
     */
    function getAmountOf(Parameter storage amounts, bytes32 key) internal view returns (uint256) {
        return amounts.amounts[key];
    }

    /**
     * @dev Returns the amount of an address.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the amount.
     * @return The amount of the address.
     */
    function getAmountOf(Parameter storage amounts, address account) internal view returns (uint256) {
        return getAmountOf(amounts, bytes32(uint256(uint160(account))));
    }

    /**
     * @dev Returns the amount of an id.
     * @param amounts The storage pointer to the amounts.
     * @param id The id of the amount.
     * @return The amount of the id.
     */
    function getAmountOf(Parameter storage amounts, uint256 id) internal view returns (uint256) {
        return getAmountOf(amounts, bytes32(id));
    }

    /**
     * @dev Returns the total amount.
     * @param amounts The storage pointer to the amounts.
     * @return The total amount.
     */
    function getTotalAmount(Parameter storage amounts) internal view returns (uint256) {
        return amounts.totalAmount;
    }

    /**
     * @dev Updates the amount of a key. The delta is added to the key amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param key The key of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, bytes32 key, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        oldAmount = amounts.amounts[key];
        oldTotalAmount = amounts.totalAmount;

        if (deltaAmount == 0) {
            newAmount = oldAmount;
            newTotalAmount = oldTotalAmount;
        } else {
            newAmount = oldAmount.addDelta(deltaAmount);
            newTotalAmount = oldTotalAmount.addDelta(deltaAmount);

            amounts.amounts[key] = newAmount;
            amounts.totalAmount = newTotalAmount;
        }
    }

    /**
     * @dev Updates the amount of an address. The delta is added to the address amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, address account, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        return update(amounts, bytes32(uint256(uint160(account))), deltaAmount);
    }

    /**
     * @dev Updates the amount of an id. The delta is added to the id amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param id The id of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, uint256 id, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        return update(amounts, bytes32(id), deltaAmount);
    }
}

// src/interfaces/IBaseRewarder.sol

interface IBaseRewarder is IRewarder {
    error BaseRewarder__NativeTransferFailed();
    error BaseRewarder__InvalidCaller();
    error BaseRewarder__Stopped();
    error BaseRewarder__AlreadyStopped();
    error BaseRewarder__NotNativeRewarder();
    error BaseRewarder__ZeroAmount();
    error BaseRewarder__ZeroReward();
    error BaseRewarder__InvalidDuration();
    error BaseRewarder__InvalidPid(uint256 pid);
    error BaseRewarder__InvalidStartTimestamp(uint256 startTimestamp);
    error BaseRewarder__CannotRenounceOwnership();

    event Claim(address indexed account, IERC20 indexed token, uint256 reward);

    event RewardParameterUpdated(uint256 rewardPerSecond, uint256 startTimestamp, uint256 endTimestamp);

    event Stopped();

    event Swept(IERC20 indexed token, address indexed account, uint256 amount);

    function getToken() external view returns (IERC20);

    function getCaller() external view returns (address);

    function getPid() external view returns (uint256);

    function getRewarderParameter()
        external
        view
        returns (IERC20 token, uint256 rewardPerSecond, uint256 lastUpdateTimestamp, uint256 endTimestamp);

    function getRemainingReward() external view returns (uint256);

    function getPendingReward(address account, uint256 balance, uint256 totalSupply)
        external
        view
        returns (IERC20 token, uint256 pendingReward);

    function isStopped() external view returns (bool);

    function initialize(address initialOwner) external;

    function setRewardPerSecond(uint256 maxRewardPerSecond, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);

    function setRewarderParameters(uint256 maxRewardPerSecond, uint256 startTimestamp, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);

    function stop() external;

    function sweep(IERC20 token, address account) external;

    function onModify(address account, uint256 pid, uint256 oldBalance, uint256 newBalance, uint256 totalSupply)
        external
        returns (uint256);
}

// src/interfaces/IBribeRewarder.sol

interface IBribeRewarder is IRewarder {
    error BribeRewarder__OnlyVoter();
    error BribeRewarder__InsufficientFunds();
    error BribeRewarder__WrongStartId();
    error BribeRewarder__WrongEndId();
    error BribeRewarder__ZeroReward();
    error BribeRewarder__NativeTransferFailed();
    error BribeRewarder__NotOwner();
    error BribeRewarder__CannotRenounceOwnership();
    error BribeRewarder__NotNativeRewarder();
    error BribeRewarder__AlreadyInitialized();
    error BribeRewarder__PeriodNotFound();

    event Claimed(uint256 indexed tokenId, address indexed pool, uint256 amount);
    event Deposited(uint256 indexed periodId, uint256 indexed tokenId, address indexed pool, uint256 amount);
    event BribeInit(uint256 indexed startId, uint256 indexed lastId, uint256 amountPerPeriod);

    function bribe(uint256 startId, uint256 lastId, uint256 amountPerPeriod) external;

    function claim(uint256 tokenId) external;

    function deposit(uint256 periodId, uint256 tokenId, uint256 deltaAmount) external;

    function getPool() external view returns (address);

    function getPendingReward(uint256 tokenId) external view returns (uint256);

    function getBribePeriods() external view returns (address pool, uint256[] memory);

    function getStartVotingPeriodId() external view returns (uint256);

    function getLastVotingPeriodId() external view returns (uint256);

    function getAmountPerPeriod() external view returns (uint256);
}

// src/interfaces/IMasterChefRewarder.sol

interface IMasterChefRewarder is IBaseRewarder {
    error MasterChefRewarder__AlreadyLinked();
    error MasterChefRewarder__NotLinked();
    error MasterChefRewarder__UseUnlink();

    enum Status {
        Unlinked,
        Linked,
        Stopped
    }

    function link(uint256 pid) external;

    function unlink(uint256 pid) external;
}

// src/libraries/Rewarder.sol

/**
 * @title Rewarder Library
 * @dev A library that defines various functions for calculating rewards.
 * It takes care about the reward debt and the accumulated debt per share.
 */
library Rewarder {
    using Amounts for Amounts.Parameter;

    struct Parameter {
        uint256 lastUpdateTimestamp;
        uint256 accDebtPerShare;
        mapping(address => uint256) debt;
    }

    /**
     * @dev Returns the debt associated with an amount.
     * @param accDebtPerShare The accumulated debt per share.
     * @param deposit The amount.
     * @return The debt associated with the amount.
     */
    function getDebt(uint256 accDebtPerShare, uint256 deposit) internal pure returns (uint256) {
        return (deposit * accDebtPerShare) >> Constants.ACC_PRECISION_BITS;
    }

    /**
     * @dev Returns the debt per share associated with a total deposit and total rewards.
     * @param totalDeposit The total deposit.
     * @param totalRewards The total rewards.
     * @return The debt per share associated with the total deposit and total rewards.
     */
    function getDebtPerShare(uint256 totalDeposit, uint256 totalRewards) internal pure returns (uint256) {
        return totalDeposit == 0 ? 0 : (totalRewards << Constants.ACC_PRECISION_BITS) / totalDeposit;
    }

    /**
     * @dev Returns the total rewards to emit.
     * If the end timestamp is in the past, the rewards are calculated up to the end timestamp.
     * If the last update timestamp is in the future, it will return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param rewardPerSecond The reward per second.
     * @param endTimestamp The end timestamp.
     * @param totalSupply The total supply.
     * @return The total rewards.
     */
    function getTotalRewards(
        Parameter storage rewarder,
        uint256 rewardPerSecond,
        uint256 endTimestamp,
        uint256 totalSupply
    ) internal view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 lastUpdateTimestamp = rewarder.lastUpdateTimestamp;
        uint256 timestamp = block.timestamp > endTimestamp ? endTimestamp : block.timestamp;

        return timestamp > lastUpdateTimestamp ? (timestamp - lastUpdateTimestamp) * rewardPerSecond : 0;
    }

    /**
     * @dev Returns the total rewards to emit.
     * @param rewarder The storage pointer to the rewarder.
     * @param rewardPerSecond The reward per second.
     * @param totalSupply The total supply.
     * @return The total rewards.
     */
    function getTotalRewards(Parameter storage rewarder, uint256 rewardPerSecond, uint256 totalSupply)
        internal
        view
        returns (uint256)
    {
        return getTotalRewards(rewarder, rewardPerSecond, block.timestamp, totalSupply);
    }

    /**
     * @dev Returns the pending reward of an account.
     * @param rewarder The storage pointer to the rewarder.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the account.
     * @param totalRewards The total rewards.
     * @return The pending reward of the account.
     */
    function getPendingReward(
        Parameter storage rewarder,
        Amounts.Parameter storage amounts,
        address account,
        uint256 totalRewards
    ) internal view returns (uint256) {
        return getPendingReward(rewarder, account, amounts.getAmountOf(account), amounts.getTotalAmount(), totalRewards);
    }

    /**
     * @dev Returns the pending reward of an account.
     * If the balance of the account is 0, it will always return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param account The address of the account.
     * @param balance The balance of the account.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return The pending reward of the account.
     */
    function getPendingReward(
        Parameter storage rewarder,
        address account,
        uint256 balance,
        uint256 totalSupply,
        uint256 totalRewards
    ) internal view returns (uint256) {
        uint256 accDebtPerShare = rewarder.accDebtPerShare + getDebtPerShare(totalSupply, totalRewards);

        return balance == 0 ? 0 : getDebt(accDebtPerShare, balance) - rewarder.debt[account];
    }

    /**
     * @dev Updates the rewarder.
     * If the balance of the account is 0, it will always return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param account The address of the account.
     * @param oldBalance The old balance of the account.
     * @param newBalance The new balance of the account.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return rewards The rewards of the account.
     */
    function update(
        Parameter storage rewarder,
        address account,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 totalSupply,
        uint256 totalRewards
    ) internal returns (uint256 rewards) {
        uint256 accDebtPerShare = updateAccDebtPerShare(rewarder, totalSupply, totalRewards);

        rewards = oldBalance == 0 ? 0 : getDebt(accDebtPerShare, oldBalance) - rewarder.debt[account];

        rewarder.debt[account] = getDebt(accDebtPerShare, newBalance);
    }

    /**
     * @dev Updates the accumulated debt per share.
     * If the last update timestamp is in the future, it will not update the last update timestamp.
     * @param rewarder The storage pointer to the rewarder.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return The accumulated debt per share.
     */
    function updateAccDebtPerShare(Parameter storage rewarder, uint256 totalSupply, uint256 totalRewards)
        internal
        returns (uint256)
    {
        uint256 debtPerShare = getDebtPerShare(totalSupply, totalRewards);

        if (block.timestamp > rewarder.lastUpdateTimestamp) rewarder.lastUpdateTimestamp = block.timestamp;

        return debtPerShare == 0 ? rewarder.accDebtPerShare : rewarder.accDebtPerShare += debtPerShare;
    }
}

// src/interfaces/IRewarderFactory.sol

interface IRewarderFactory {
    error RewarderFactory__ZeroAddress();
    error RewarderFactory__InvalidRewarderType();
    error RewarderFactory__InvalidPid();

    enum RewarderType {
        InvalidRewarder,
        MasterChefRewarder,
        VeMoeRewarder,
        JoeStakingRewarder,
        BribeRewarder
    }

    event RewarderCreated(
        RewarderType indexed rewarderType, IERC20 indexed token, uint256 indexed pid, IBaseRewarder rewarder
    );

    event BribeRewarderCreated(
        RewarderType indexed rewarderType, IERC20 indexed token, address indexed pool, IBribeRewarder rewarder
    );

    event RewarderImplementationSet(RewarderType indexed rewarderType, IRewarder indexed implementation);

    function getRewarderImplementation(RewarderType rewarderType) external view returns (IRewarder);

    function getRewarderCount(RewarderType rewarderType) external view returns (uint256);

    function getRewarderAt(RewarderType rewarderType, uint256 index) external view returns (IRewarder);

    function getRewarderType(IRewarder rewarder) external view returns (RewarderType);

    function setRewarderImplementation(RewarderType rewarderType, IRewarder implementation) external;

    function createRewarder(RewarderType rewarderType, IERC20 token, uint256 pid) external returns (IBaseRewarder);

    function createBribeRewarder(IERC20 token, address pool) external returns (IBribeRewarder);
}

// src/interfaces/IVoter.sol

interface IVoter {
    error IVoter__InvalidLength();
    error IVoter_VotingPeriodNotStarted();
    error IVoter_VotingPeriodEnded();
    error IVoter__AlreadyVoted();
    error IVoter__NotOwner();
    error IVoter__InsufficientVotingPower();
    error IVoter__TooManyPoolIds();
    error IVoter__DuplicatePoolId(uint256 pid);
    error IVoter__InsufficientLockTime();
    error Voter__InvalidRegisterCaller();
    error Voter__PoolNotVotable();
    error IVoter__NoFinishedPeriod();
    error IVoter_ZeroValue();

    event VotingPeriodStarted();
    event Voted(uint256 indexed tokenId, uint256 votingPeriod, address[] votedPools, uint256[] votesDeltaAmounts);
    event TopPoolIdsWithWeightsSet(uint256[] poolIds, uint256[] pidWeights);
    event VoterPoolValidatorUpdated(address indexed validator);
    event VotingDurationUpdated(uint256 duration);
    event MinimumLockTimeUpdated(uint256 lockTime);
    event MinimumVotesPerPoolUpdated(uint256 minimum);
    event OperatorUpdated(address indexed operator);

    struct VotingPeriod {
        uint256 startTime;
        uint256 endTime;
    }

    function getMasterChef() external view returns (IMasterChef);

    function getTotalWeight() external view returns (uint256);

    function getTopPoolIds() external view returns (uint256[] memory);

    function getWeight(uint256 pid) external view returns (uint256);

    function hasVoted(uint256 period, uint256 tokenId) external view returns (bool);

    function getCurrentVotingPeriod() external view returns (uint256);

    function getLatestFinishedPeriod() external view returns (uint256);

    function getPeriodStartTime() external view returns (uint256);

    function getPeriodStartEndtime(uint256 periodId) external view returns (uint256, uint256);

    function getVotesPerPeriod(uint256 periodId, address pool) external view returns (uint256);

    function getVotedPools() external view returns (address[] memory);

    function getVotedPoolsLength() external view returns (uint256);

    function getVotedPoolsAtIndex(uint256 index) external view returns (address, uint256);

    function getTotalVotes() external view returns (uint256);

    function getUserVotes(uint256 tokenId, address pool) external view returns (uint256);

    function getPoolVotesPerPeriod(uint256 periodId, address pool) external view returns (uint256);

    function getUserBribeRewaderAt(uint256 period, uint256 tokenId, uint256 index)
        external
        view
        returns (IBribeRewarder);

    function getUserBribeRewarderLength(uint256 period, uint256 tokenId) external view returns (uint256);

    function getBribeRewarderAt(uint256 period, address pool, uint256 index) external view returns (IBribeRewarder);

    function getBribeRewarderLength(uint256 period, address pool) external view returns (uint256);

    function ownerOf(uint256 tokenId, address account) external view returns (bool);

    function onRegister() external;
}

// src/interfaces/IMasterChef.sol

interface IMasterChef {
    error MasterChef__InvalidShares();
    error MasterChef__InvalidLumPerSecond();
    error MasterChef__ZeroAddress();
    error MasterChef__NotMasterchefRewarder();
    error MasterChef__CannotRenounceOwnership();
    error MasterChef__MintFailed();
    error MasterChef__TrusteeNotSet();
    error MasterChef__NotTrustedCaller();

    struct Farm {
        Amounts.Parameter amounts;
        Rewarder.Parameter rewarder;
        IERC20 token;
        IMasterChefRewarder extraRewarder;
    }
    // bool depositOnBehalf; // true if v2 pool zap in should be possible
    // uint256 startTime;

    event PositionModified(uint256 indexed pid, address indexed account, int256 deltaAmount, uint256 lumReward);

    event LumPerSecondSet(uint256 lumPerSecond);

    event FarmAdded(uint256 indexed pid, IERC20 indexed token);

    event ExtraRewarderSet(uint256 indexed pid, IMasterChefRewarder extraRewarder);

    event TreasurySet(address indexed treasury);

    event VoterSet(IVoter indexed newVoter);

    event TrusteeSet(address indexed trustee);

    event MintLumSet(bool mintLum);

    event OperatorUpdated(address indexed operator);

    function add(IERC20 token, IMasterChefRewarder extraRewarder) external;

    function claim(uint256[] memory pids) external;

    function deposit(uint256 pid, uint256 amount) external;

    function depositOnBehalf(uint256 pid, uint256 amount, address account) external;

    function emergencyWithdraw(uint256 pid) external;

    function getDeposit(uint256 pid, address account) external view returns (uint256);

    function getLastUpdateTimestamp(uint256 pid) external view returns (uint256);

    function getPendingRewards(address account, uint256[] memory pids)
        external
        view
        returns (uint256[] memory lumRewards, IERC20[] memory extraTokens, uint256[] memory extraRewards);

    function getExtraRewarder(uint256 pid) external view returns (IMasterChefRewarder);

    function getLum() external view returns (ILum);

    function getLumPerSecond() external view returns (uint256);

    function getLumPerSecondForPid(uint256 pid) external view returns (uint256);

    function getNumberOfFarms() external view returns (uint256);

    function getToken(uint256 pid) external view returns (IERC20);

    function getTotalDeposit(uint256 pid) external view returns (uint256);

    function getTreasury() external view returns (address);

    function getTreasuryShare() external view returns (uint256);

    function getRewarderFactory() external view returns (IRewarderFactory);

    function getLBHooksManager() external view returns (address);

    function getVoter() external view returns (IVoter);

    function setExtraRewarder(uint256 pid, IMasterChefRewarder extraRewarder) external;

    function setLumPerSecond(uint96 lumPerSecond) external;

    function setTreasury(address treasury) external;

    function setVoter(IVoter voter) external;

    function setTrustee(address trustee) external;

    function updateAll(uint256[] calldata pids) external;

    function withdraw(uint256 pid, uint256 amount) external;
}
