// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IVersionable.sol";
import "./Story/IIPTokenStaking.sol";

/// @title Delegator Interface for Staking Management
/// @notice Interface defining the core functionality for delegation and validator management
/// @dev Handles stake delegation, validator management, and distribution configuration
interface IDelegator is IVersionable {
    /// @notice State for the delegator contract
    /// @param unstakeInterval Time interval between unstake operations (in seconds)
    /// @param bondedMaturitiesEnabled Flag to enable/disable bonded maturities
    /// @param bondedMaturities Array of bonded maturities
    /// @custom:storage-location erc7201:VerioIP.Delegator.DelegatorState
    struct DelegatorState {
        uint256 unstakeInterval;
        bool bondedMaturitiesEnabled;
        IIPTokenStaking.StakingPeriod[] bondedMaturities;
    }

    /// @notice Configuration for the delegator contract
    /// @param unstakeInterval Time interval between unstake operations (in seconds)
    /// @param bondedMaturitiesEnabled Flag to enable/disable bonded maturities
    /// @param bondedMaturities Array of bonded maturities
    struct DelegatorConfig {
        uint256 unstakeInterval;
        bool bondedMaturitiesEnabled;
        IIPTokenStaking.StakingPeriod[] bondedMaturities;
    }

    /// @notice Configuration for distribution settings by maturity period
    /// @dev Maps staking periods (maturities) to their respective maturity configurations
    /// @custom:storage-location erc7201:VerioIP.Delegator.Distribution
    struct Distribution {
        mapping(IIPTokenStaking.StakingPeriod => MaturityConfig) configByMaturity;
    }

    /// @notice Configuration for different maturity periods
    /// @param maturity The staking period type
    /// @param bps Basis points for distribution (100 = 1%)
    /// @param duration Duration for the maturity period (in seconds)
    struct MaturityConfig {
        IIPTokenStaking.StakingPeriod maturity;
        uint256 bps;
        uint256 duration;
    }

    /// @notice Represents a single delegation entry
    /// @param validator Public key of the validator
    /// @param id Unique identifier for the delegation
    /// @param maturity Staking period type
    /// @param amount Amount delegated
    /// @param startTimestamp Time when delegation started (in seconds)
    /// @param duration Duration of the delegation (in seconds)
    /// @param endTimestamp Time when delegation ends (in seconds)
    struct Delegation {
        bytes validator;
        uint256 id;
        IIPTokenStaking.StakingPeriod maturity;
        uint256 amount;
        uint256 startTimestamp;
        uint256 duration;
        uint256 endTimestamp;
    }

    /// @notice Tracks delegations for a specific validator
    /// @param exists Whether the validator exists in the registry
    /// @param total Total amount delegated to the validator (in IP)
    /// @param distribution Distribution of delegations across different maturities
    struct ValidatorDelegations {
        bool exists;
        uint256 total;
        DelegationDistribution distribution;
    }

    /// @notice Registry of validators and their delegations
    /// @param validators Array of validator public keys
    /// @param delegations Mapping of validator public keys to their delegations
    /// @custom:storage-location erc7201:VerioIP.Delegator.ValidatorRegistry
    struct ValidatorRegistry {
        bytes[] validators;
        mapping(bytes => ValidatorDelegations) delegations;
        uint256 stakeIdx;
        uint256 unstakeIdx;
    }

    /// @notice Distribution of delegations across different maturity periods
    /// @param instant Amount in instant (non-bonded) delegations (in IP)
    /// @param instantId Shared ID of all instant delegations
    /// @param delegationsByMaturity Mapping of maturity periods to delegation queues
    struct DelegationDistribution {
        uint256 instant;
        uint256 instantId;
        mapping(IIPTokenStaking.StakingPeriod => DelegationQueue) delegationsByMaturity;
    }

    /// @notice Queue of delegations for a specific maturity period
    /// @param total Total amount in the queue (in IP)
    /// @param delegations Mapping of IDs to delegations
    /// @param ids Array of delegation IDs
    /// @param ptr Current pointer in the queue
    struct DelegationQueue {
        uint256 total;
        mapping(uint256 => Delegation) delegations;
        uint256[] ids;
        uint256 ptr;
    }

    /// @notice Global distribution of delegations
    /// @param total Total amount distributed (in IP)
    /// @param totalByMaturity Mapping of maturity periods to their total amounts (in IP)
    /// @custom:storage-location erc7201:VerioIP.Delegator.GlobalDistribution
    struct GlobalDistribution {
        uint256 total;
        mapping(IIPTokenStaking.StakingPeriod => uint256) totalByMaturity;
    }

    /// @notice Queue for unstaking operations
    /// @param instantUnstake Mapping of validators to their instant unstake entries
    /// @param bondedUnstakes Mapping of validators to their bonded unstake queues
    /// @param unstakeValidators Array of validators with pending unstakes
    /// @param nextUnstake Timestamp of the next unstake operation (in seconds)
    /// @custom:storage-location erc7201:VerioIP.Delegator.UnstakeQueue
    struct UnstakeQueue {
        mapping(bytes => Delegation) instantUnstake;
        mapping(bytes => DelegationQueue) bondedUnstakes;
        bytes[] unstakeValidators;
        uint256 nextUnstake;
    }

    /// @notice Emitted when a new validator is added to the registry
    /// @param validator The public key of the added validator
    event ValidatorAdded(bytes validator);

    /// @notice Emitted when a validator is removed from the registry
    /// @param validator The public key of the removed validator
    event ValidatorRemoved(bytes validator);

    /// @notice Emitted when a delegation is created
    /// @param id Unique identifier for the delegation
    /// @param validator The public key of the validator
    /// @param amount The amount delegated (in IP)
    /// @param maturity The staking period type
    event DelegationStaked(uint256 id, bytes validator, uint256 amount, IIPTokenStaking.StakingPeriod maturity);

    /// @notice Emitted when a delegation is unstaked
    /// @param id Unique identifier for the delegation
    /// @param validator The public key of the validator
    /// @param amount The amount unstaked (in IP)
    /// @param maturity The staking period type
    event DelegationUnstaked(uint256 id, bytes validator, uint256 amount, IIPTokenStaking.StakingPeriod maturity);

    /// @notice Emitted when the delegator state is updated
    /// @param delegatorState The new delegator state
    event DelegatorStateUpdated(DelegatorState delegatorState);

    /// @notice Emitted when the distribution is updated
    /// @param maturityConfigs The new maturity configurations
    event DistributionUpdated(MaturityConfig[] maturityConfigs);

    /// @notice Error emitted when no validators are available to stake
    error NoValidatorsToStake();

    /// @notice Error emitted when no validators are available to unstake
    error NoValidatorsToUnstake();

    /// @notice Error emitted when the stake amount is below the threshold
    /// @param threshold The threshold amount
    error StakeAmountBelowThreshold(uint256 threshold);

    /// @notice Error emitted when a validator already exists
    error ValidatorAlreadyExists();

    /// @notice Error emitted when a validator is in an invalid format
    error ValidatorInvalidFormat();

    /// @notice Error emitted when a validator is null
    error ValidatorCannotBeNull();

    /// @notice Error emitted when a validator does not exist
    error ValidatorDoesNotExist();

    /// @notice Error emitted when a validator has delegations
    error ValidatorHasDelegations();

    /// @notice Error emitted when the minimum number of validators is not met
    error MinimumValidatorRequired();

    /// @notice Error emitted when the from and to validator are the same
    error FromAndToValidatorSame();

    /// @notice Error emitted when the number of redelegate attempts is invalid
    error RedelegateAttemptsInvalid();

    /// @notice Error emitted when the from validator has no delegations
    error FromValidatorNoDelegations();

    /// @notice Error emitted when the unstake interval is invalid
    error InvalidUnstakeInterval();

    /// @notice Error emitted when the unstake amount is invalid
    error UnstakeAmountInvalid();

    /// @notice Error emitted when the unstake amount exceeds the total stake
    /// @param total The total stake amount
    error UnstakeAmountExceedsTotal(uint256 total);

    /// @notice Error emitted when the full amount could not be unstaked
    /// @param remainder The amount that could not be unstaked
    error CouldNotUnstakeFullAmount(uint256 remainder);

    /// @notice Error emitted when an existing maturity is not accounted for
    /// @param maturity The maturity that is not accounted for
    error ExistingMaturityNotAccountedFor(IIPTokenStaking.StakingPeriod maturity);

    /// @notice Error emitted when maturity durations are not in ascending order
    error MaturityDurationsNotAscending();

    /// @notice Error emitted when the maturity bps sum is invalid
    /// @param bpsSum The sum of the maturity bps
    error MaturityBpsSumInvalid(uint256 bpsSum);

    /// @notice Error emitted when the delegation amount is invalid
    error DelegationAmountInvalid();

    /// @notice Error emitted when a delegation is already in the queue
    error DelegationAlreadyInQueue();

    /// @notice Handles incoming stake requests
    /// @dev Processes stake distribution according to maturity configurations
    function handleStake() external payable;

    /// @notice Allows admin to stake to a specific validator
    /// @param _validator The validator's public key
    /// @param _maturity The staking period (maturity) type
    function handleAdminStake(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity) external payable;

    /// @notice Handles unstake requests
    /// @param _amount The amount to unstake (in IP)
    /// @return excessUnstake The excess unstake amount (in IP)
    function handleUnstake(uint256 _amount) external returns (uint256 excessUnstake);

    /// @notice Handles unstake queue processing
    function handleUnstakeQueue() external;

    /// @notice Adds a new validator to the registry
    /// @param _validator The validator's public key
    function addValidator(bytes calldata _validator) external;

    /// @notice Removes a validator from the registry
    /// @param _validator The validator's public key
    function removeValidator(bytes calldata _validator) external;

    /// @notice Redelegates from one validator to another
    /// @param _fromValidator The validator's public key to redelegate from
    /// @param _toValidator The validator's public key to redelegate to
    /// @param _attempts The number of attempts to redelegate
    /// @return remainder The remainder of the redelegation (in IP)
    function redelegate(bytes calldata _fromValidator, bytes calldata _toValidator, uint256 _attempts)
        external
        returns (uint256 remainder);

    /// @notice Gets the list of validators
    /// @return validators The list of validator public keys
    function getValidators() external view returns (bytes[] memory);

    /// @notice Gets the staked amount for a specific validator
    /// @param _validator The validator's public key
    /// @return amount The staked amount (in IP)
    function getValidatorStakedAmount(bytes calldata _validator) external view returns (uint256);

    /// @notice Sets whether bonded maturities are enabled
    /// @param _bondedMaturitiesEnabled Whether bonded maturities are enabled
    function setBondedMaturitiesEnabled(bool _bondedMaturitiesEnabled) external;

    /// @notice Sets the unstake interval
    /// @param _unstakeInterval The unstake interval (in seconds)
    function setUnstakeInterval(uint256 _unstakeInterval) external;

    /// @notice Sets the distribution configuration
    /// @param _maturityConfigs The distribution configurations
    function setDistributionConfigs(MaturityConfig[] calldata _maturityConfigs) external;

    /// @notice Gets the distribution amount for a specific validator and maturity
    /// @param _validator The validator's public key
    /// @param _maturity The maturity period type
    /// @return amount The distribution amount (in IP)
    function getValidatorDistributionByMaturity(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity)
        external
        view
        returns (uint256);

    /// @notice Gets the global distribution amount for a specific maturity
    /// @param _maturity The maturity period type
    /// @return amount The global distribution amount (in IP)
    function getGlobalDistributionByMaturity(IIPTokenStaking.StakingPeriod _maturity) external view returns (uint256);

    /// @notice Gets the total global distribution amount
    /// @return amount The total global distribution amount (in IP)
    function getGlobalDistributionTotal() external view returns (uint256);

    /// @notice Gets the next unstake timestamp
    /// @return nextUnstake The next unstake timestamp (in seconds)
    function getNextUnstakeTimestamp() external view returns (uint256 nextUnstake);

    /// @notice Gets the list of validators in the unstake queue
    /// @return validators The list of validators in the unstake queue
    function getUnstakeQueueValidators() external view returns (bytes[] memory validators);

    /// @notice Gets the unstake queue for a specific validator
    /// @param _validator The validator's public key
    /// @return unstakes The unstake queue for the specific validator
    function getUnstakeQueueByValidator(bytes calldata _validator)
        external
        view
        returns (Delegation[] memory unstakes);

    /// @notice Sets the withdrawal address
    function setWithdrawalAddress() external;

    /// @notice Sets the rewards address
    function setRewardsAddress() external;

    /// @notice Rebases the distribution
    function rebase() external;
}
