// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./abstract/VerioComponent.sol";
import "./interfaces/IDelegator.sol";
import "./interfaces/IInsurancePool.sol";
import "./interfaces/Story/IIPTokenStaking.sol";

/// @title Delegator Implementation for Staking Management
/// @notice Manages stake delegation and validator operations
/// @dev Implements IDelegator interface with upgradeable OpenZeppelin contracts
contract Delegator is IDelegator, VerioComponent {
    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.Delegator.DelegatorState")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant DELEGATOR_STATE = 0x7899037626cb2c1c83449733c9424fa0b50ccb85f7d1a4814ad00b2241760200;
    // keccak256(abi.encode(uint256(keccak256("VerioIP.Delegator.Distribution")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant DISTRIBUTION = 0x1cabc4f66faf75a6801c6197355114f5ebd705f2e81b30d9ebff88ea7ce3df00;
    // keccak256(abi.encode(uint256(keccak256("VerioIP.Delegator.GlobalDistribution")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant GLOBAL_DISTRIBUTION = 0x828fa141910afe6dab7aa0d7389fb55f709c6fdd34270412eec75df301c6c100;
    // keccak256(abi.encode(uint256(keccak256("VerioIP.Delegator.ValidatorRegistry")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant VALIDATOR_REGISTRY = 0xfcb5889e0f31a4bb142d899ac93484f3ebdb1137ddd1fd4897d8406143cdbd00;
    // keccak256(abi.encode(uint256(keccak256("VerioIP.Delegator.UnstakeQueue")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant UNSTAKE_QUEUE = 0x8703616b75ce035f6b8044850efaf17dc3fdc2d44f2517cff4b0bbf7aad1e800;

    /// @notice Length of a secp256k1 compressed pubkey
    uint256 private constant VALIDATOR_PUBKEY_LENGTH = 33;

    /// @dev Storage slot for delegator state
    function _delegatorState() internal pure returns (DelegatorState storage $) {
        assembly {
            $.slot := DELEGATOR_STATE
        }
    }

    /// @dev Storage slot for distribution
    function _distribution() internal pure returns (Distribution storage $) {
        assembly {
            $.slot := DISTRIBUTION
        }
    }

    /// @dev Storage slot for global distribution
    function _globalDistribution() internal pure returns (GlobalDistribution storage $) {
        assembly {
            $.slot := GLOBAL_DISTRIBUTION
        }
    }

    /// @dev Storage slot for validator registry
    function _validatorRegistry() internal pure returns (ValidatorRegistry storage $) {
        assembly {
            $.slot := VALIDATOR_REGISTRY
        }
    }

    /// @dev Storage slot for unstake queue
    function _unstakeQueue() internal pure returns (UnstakeQueue storage $) {
        assembly {
            $.slot := UNSTAKE_QUEUE
        }
    }

    // --- INITIALIZATION ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the delegator contract
    /// @dev This function replaces the constructor for upgradeable contracts
    /// @param _delegatorConfig Initial configuration for the delegator
    /// @param _maturityConfigs Array of maturity configurations
    /// @param _validatorPubkeys Array of validator public keys
    function initialize(
        DelegatorConfig calldata _delegatorConfig,
        MaturityConfig[] calldata _maturityConfigs,
        bytes[] calldata _validatorPubkeys
    ) external initializer {
        _init(msg.sender);
        _trySetDelegatorState(_delegatorConfig);
        _trySetDistribution(_maturityConfigs);
        _trySetValidatorRegistry(_validatorPubkeys);
    }

    /// @notice Internal function to set validator registry
    /// @dev Validates validator pubkeys array and adds validators to registry
    /// @param _validatorPubkeys Array of validator public keys
    function _trySetValidatorRegistry(bytes[] calldata _validatorPubkeys) internal {
        require(_validatorPubkeys.length > 0, NoValidatorsToStake());

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            bytes memory pubkey = _validatorPubkeys[i];
            _addValidator(pubkey);
        }
    }

    /// @notice Internal function to set delegator configuration
    /// @dev Validates unstake interval and delegator pubkey format
    /// @param _delegatorConfig New delegator configuration
    function _trySetDelegatorState(DelegatorConfig calldata _delegatorConfig) internal {
        require(_isValidUnstakeInterval(_delegatorConfig.unstakeInterval), InvalidUnstakeInterval());
        DelegatorState storage delegatorState = _delegatorState();
        delegatorState.unstakeInterval = _delegatorConfig.unstakeInterval;
        delegatorState.bondedMaturitiesEnabled = _delegatorConfig.bondedMaturitiesEnabled;
        delegatorState.bondedMaturities = _delegatorConfig.bondedMaturities;
        emit DelegatorStateUpdated(delegatorState);
    }

    /// @notice Internal function to set distribution configuration
    /// @dev Validates maturity durations are ascending and BPS sum to 10000
    /// @param _maturityConfigs Array of maturity configurations
    function _trySetDistribution(MaturityConfig[] calldata _maturityConfigs) internal {
        /**
         * inverting this order has the effect of making the longest maturity
         * the first to be processed when unstaking
         * and the last to be processed when staking
         */
        DelegatorState storage delegatorState = _delegatorState();
        Distribution storage distribution = _distribution();
        GlobalDistribution storage globalDistribution = _globalDistribution();

        /**
         * We need to check that no existing maturity is being removed
         * Therefore all staked maturities must be accounted for in the new config
         * TODO: make this not n^2
         */
        bool found;
        for (uint256 i = 0; i < delegatorState.bondedMaturities.length; i++) {
            // its safe to disregard any maturities that haven't been staked
            if (globalDistribution.totalByMaturity[delegatorState.bondedMaturities[i]] == 0) {
                continue;
            }
            found = false;
            for (uint256 j = 0; j < _maturityConfigs.length; j++) {
                if (_maturityConfigs[j].maturity == delegatorState.bondedMaturities[i]) {
                    found = true;
                    break;
                }
            }
            require(found, ExistingMaturityNotAccountedFor(delegatorState.bondedMaturities[i]));
        }

        // reset the bonded maturities to prepare for the new config
        delete delegatorState.bondedMaturities;

        uint256 lastMaturityDuration = 0;
        uint256 bpsSum = 0;
        for (uint256 i = 0; i < _maturityConfigs.length; i++) {
            if (_maturityConfigs[i].maturity == IIPTokenStaking.StakingPeriod.FLEXIBLE) {
                distribution.configByMaturity[IIPTokenStaking.StakingPeriod.FLEXIBLE] = _maturityConfigs[i];
                bpsSum += _maturityConfigs[i].bps;
            } else {
                require(_maturityConfigs[i].duration > lastMaturityDuration, MaturityDurationsNotAscending());
                distribution.configByMaturity[_maturityConfigs[i].maturity] = _maturityConfigs[i];
                // this determines insertion order
                delegatorState.bondedMaturities.push(_maturityConfigs[i].maturity);
                lastMaturityDuration = _maturityConfigs[i].duration;
                bpsSum += _maturityConfigs[i].bps;
            }
        }
        require(bpsSum == 10000, MaturityBpsSumInvalid(bpsSum));
        emit DistributionUpdated(_maturityConfigs);
    }

    function _isValidUnstakeInterval(uint256 _unstakeInterval) internal pure returns (bool) {
        return _unstakeInterval >= 1 days;
    }

    // --- BUSINESS LOGIC ---

    /// @inheritdoc IDelegator
    function handleStake() external payable override onlyStakePool nonReentrant whenNotPaused {
        require(_validatorRegistry().validators.length > 0, NoValidatorsToStake());
        require(_stakeThresholdMet(msg.value), StakeAmountBelowThreshold(_selector().ipTokenStaking().minStakeAmount()));
        _handleStake(msg.value);
    }

    /// @notice Internal function to handle stake distribution
    /// @dev Creates delegation and emits ValidatorStaked event
    /// @param _amount Amount to stake (in IP)
    function _handleStake(uint256 _amount) internal {
        Delegation memory delegation = _nextStakeDelegation(_amount);
        uint256 id = _selector().ipTokenStaking().stake{value: delegation.amount}(
            delegation.validator,
            delegation.maturity,
            "" // Empty data parameter
        );
        delegation.id = id;
        _enqueueDelegation(delegation);
        emit DelegationStaked(delegation.id, delegation.validator, delegation.amount, delegation.maturity);
    }

    /// @notice Internal function to determine next stake delegation
    /// @dev Calculates appropriate maturity based on distribution targets
    /// @param _amount Amount to be delegated (in IP)
    /// @return Delegation struct with calculated parameters
    function _nextStakeDelegation(uint256 _amount) internal returns (Delegation memory) {
        // default to instant
        Delegation memory delegation = Delegation({
            validator: _nextStakeValidator(),
            maturity: IIPTokenStaking.StakingPeriod.FLEXIBLE,
            startTimestamp: block.timestamp,
            duration: 0,
            endTimestamp: block.timestamp,
            amount: _amount,
            id: 0 // override later
        });

        DelegatorState storage delegatorState = _delegatorState();
        Distribution storage distribution = _distribution();
        GlobalDistribution storage globalDistribution = _globalDistribution();

        uint256 targetInstantAmount = _calculateProportion(
            globalDistribution.total + delegation.amount,
            distribution.configByMaturity[IIPTokenStaking.StakingPeriod.FLEXIBLE].bps
        );
        if (
            globalDistribution.totalByMaturity[IIPTokenStaking.StakingPeriod.FLEXIBLE] + delegation.amount
                < targetInstantAmount
        ) {
            return delegation;
        }

        uint256 bondedMaturitiesLength = delegatorState.bondedMaturities.length;
        if (delegatorState.bondedMaturitiesEnabled && bondedMaturitiesLength > 0) {
            // iterate over reverse maturity order (try longest first)
            for (uint256 i = 1; i <= bondedMaturitiesLength; i++) {
                IIPTokenStaking.StakingPeriod maturity = delegatorState.bondedMaturities[bondedMaturitiesLength - i];
                MaturityConfig memory maturityConfig = distribution.configByMaturity[maturity];
                uint256 targetAmount =
                    _calculateProportion(globalDistribution.total + delegation.amount, maturityConfig.bps);
                if (globalDistribution.totalByMaturity[maturity] + delegation.amount < targetAmount) {
                    delegation.maturity = maturity;
                    delegation.duration = maturityConfig.duration;
                    delegation.endTimestamp = block.timestamp + maturityConfig.duration;
                    break;
                }
            }
        }

        return delegation;
    }

    /// @notice Internal function to calculate proportion based on basis points
    /// @dev Returns 0 if either input is 0
    /// @param _amount Total amount to calculate proportion from (in IP)
    /// @param _bps Basis points (100 = 1%)
    /// @return Calculated proportion (in IP)
    function _calculateProportion(uint256 _amount, uint256 _bps) internal pure returns (uint256) {
        if (_amount == 0 || _bps == 0) {
            return 0;
        }
        return _amount * _bps / 10_000;
    }

    /// @notice Internal function to get next validator for staking
    /// @dev Rotates through validators in round-robin fashion
    /// @return Validator public key
    function _nextStakeValidator() internal returns (bytes memory) {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        bytes memory validatorPubkey = validatorRegistry.validators[validatorRegistry.stakeIdx];
        validatorRegistry.stakeIdx = (validatorRegistry.stakeIdx + 1) % validatorRegistry.validators.length;
        return validatorPubkey;
    }

    /// @notice Internal function to add delegation to queue
    /// @dev Updates global and validator-specific distribution totals
    /// @param _delegation Delegation to be enqueued
    function _enqueueDelegation(Delegation memory _delegation) internal {
        require(_delegation.amount > 0, DelegationAmountInvalid());
        ValidatorDelegations storage validatorDelegations = _validatorRegistry().delegations[_delegation.validator];
        GlobalDistribution storage globalDistribution = _globalDistribution();

        globalDistribution.total += _delegation.amount;
        globalDistribution.totalByMaturity[_delegation.maturity] += _delegation.amount;
        validatorDelegations.total += _delegation.amount;

        if (_delegation.maturity == IIPTokenStaking.StakingPeriod.FLEXIBLE) {
            validatorDelegations.distribution.instant += _delegation.amount;
            validatorDelegations.distribution.instantId = _delegation.id;
            return;
        }

        DelegationQueue storage queue = validatorDelegations.distribution.delegationsByMaturity[_delegation.maturity];
        queue.total += _delegation.amount;
        queue.delegations[_delegation.id] = _delegation;
        queue.ids.push(_delegation.id);
    }

    /// @notice Internal function to dequeue a delegation from a maturity queue
    /// @dev Updates global and validator-specific distribution totals
    /// @param _queue The delegation queue to dequeue from
    /// @return The dequeued delegation
    function _dequeueDelegation(DelegationQueue storage _queue) internal returns (Delegation memory) {
        require(_queue.ptr < _queue.ids.length, DelegationAmountInvalid());

        Delegation memory delegation = _queue.delegations[_queue.ids[_queue.ptr]];
        delete _queue.delegations[_queue.ids[_queue.ptr]];

        ValidatorDelegations storage validatorDelegations = _validatorRegistry().delegations[delegation.validator];
        GlobalDistribution storage globalDistribution = _globalDistribution();

        globalDistribution.total -= delegation.amount;
        globalDistribution.totalByMaturity[delegation.maturity] -= delegation.amount;
        validatorDelegations.total -= delegation.amount;

        _queue.total -= delegation.amount;
        _queue.ptr++;

        return delegation;
    }

    /// @notice Internal function to dequeue an instant delegation
    /// @dev Updates global and validator-specific distribution totals for flexible maturity
    /// @param delegation The instant delegation to dequeue
    function _dequeueInstantDelegation(Delegation memory delegation) internal {
        GlobalDistribution storage globalDistribution = _globalDistribution();
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        globalDistribution.totalByMaturity[IIPTokenStaking.StakingPeriod.FLEXIBLE] -= delegation.amount;
        globalDistribution.total -= delegation.amount;
        validatorRegistry.delegations[delegation.validator].distribution.instant -= delegation.amount;
        validatorRegistry.delegations[delegation.validator].total -= delegation.amount;
    }

    /// @notice Internal function to enqueue an unstake request
    /// @dev Adds validator to unstake queue if not already present
    /// @param _unstake The unstake delegation to enqueue
    function _enqueueUnstake(Delegation memory _unstake) internal {
        bytes memory validator = _unstake.validator;
        _tryAddValidatorToUnstakeQueue(validator);

        UnstakeQueue storage unstakeQueue = _unstakeQueue();

        if (_unstake.maturity == IIPTokenStaking.StakingPeriod.FLEXIBLE) {
            if (unstakeQueue.instantUnstake[validator].amount == 0) {
                unstakeQueue.instantUnstake[validator] = _unstake;
            } else {
                unstakeQueue.instantUnstake[validator].amount += _unstake.amount;
            }
        } else {
            DelegationQueue storage queue = unstakeQueue.bondedUnstakes[validator];
            require(queue.delegations[_unstake.id].amount == 0, DelegationAlreadyInQueue());
            queue.delegations[_unstake.id] = _unstake;
            queue.ids.push(_unstake.id);
            queue.total += _unstake.amount;
        }
    }

    /// @inheritdoc IDelegator
    function handleAdminStake(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity)
        external
        payable
        override
        onlyStakePool
    {
        require(_stakeThresholdMet(msg.value), StakeAmountBelowThreshold(_selector().ipTokenStaking().minStakeAmount()));
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        require(validatorRegistry.validators.length > 0, NoValidatorsToStake());
        require(validatorRegistry.delegations[_validator].exists, ValidatorDoesNotExist());
        _handleAdminStake(_validator, _maturity);
    }

    /// @notice Internal function to handle admin stake requests
    /// @dev Creates and processes a new delegation with specified validator and maturity
    /// @param _validator The validator to stake with
    /// @param _maturity The staking period type
    function _handleAdminStake(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity) internal {
        Distribution storage distribution = _distribution();
        Delegation memory delegation = Delegation({
            validator: _validator,
            maturity: _maturity,
            startTimestamp: block.timestamp,
            duration: distribution.configByMaturity[_maturity].duration,
            endTimestamp: block.timestamp + distribution.configByMaturity[_maturity].duration,
            amount: msg.value,
            id: 0 // override later
        });
        uint256 id = _selector().ipTokenStaking().stake{value: delegation.amount}(
            delegation.validator,
            delegation.maturity,
            "" // Empty data parameter
        );
        delegation.id = id;
        _enqueueDelegation(delegation);
        emit DelegationStaked(delegation.id, delegation.validator, delegation.amount, delegation.maturity);
    }

    /// @inheritdoc IDelegator
    function handleUnstake(uint256 _amount)
        external
        override
        onlyStakePool
        nonReentrant
        whenNotPaused
        returns (uint256 excessUnstake)
    {
        _handleUnstakeQueue();
        require(_amount > 0, UnstakeAmountInvalid());
        uint256 total = _globalDistribution().total;
        require(_amount <= total, UnstakeAmountExceedsTotal(total));
        require(_validatorRegistry().validators.length > 0, NoValidatorsToUnstake());
        return _handleUnstake(_amount);
    }

    /// @notice Internal function to handle unstake requests
    /// @dev Processes unstakes from instant and bonded delegations
    /// @param _amount Amount to unstake (in IP)
    /// @return excessUnstake Any excess amount that was unstaked (in IP)
    function _handleUnstake(uint256 _amount) internal returns (uint256 excessUnstake) {
        uint256 remainingUnstake;
        (remainingUnstake, excessUnstake) = _handleInstantUnstakes(_amount);
        if (remainingUnstake > 0) {
            (remainingUnstake, excessUnstake) = _handleBondedUnstakes(remainingUnstake);
        }
        require(remainingUnstake == 0, CouldNotUnstakeFullAmount(remainingUnstake));
    }

    /// @notice Internal function to handle instant unstakes
    /// @dev Processes unstakes from flexible maturity delegations
    /// @param _amount Amount to unstake (in IP)
    /// @return amountToUnstake Remaining amount to unstake (in IP)
    /// @return excessUnstake Any excess amount that was unstaked (in IP)
    function _handleInstantUnstakes(uint256 _amount)
        internal
        returns (uint256 amountToUnstake, uint256 excessUnstake)
    {
        amountToUnstake = _amount;

        bytes memory validatorPubkey;
        ValidatorDelegations storage validatorDelegations;

        while (amountToUnstake > 0 && _globalDistribution().totalByMaturity[IIPTokenStaking.StakingPeriod.FLEXIBLE] > 0)
        {
            validatorPubkey = _nextUnstakeValidator();
            validatorDelegations = _validatorRegistry().delegations[validatorPubkey];
            if (validatorDelegations.distribution.instant > 0) {
                uint256 unstakeAmount =
                    _calculateInstantUnstakeAmount(validatorDelegations.distribution.instant, amountToUnstake);
                Delegation memory instantUnstake = Delegation({
                    validator: validatorPubkey,
                    maturity: IIPTokenStaking.StakingPeriod.FLEXIBLE,
                    startTimestamp: 0,
                    duration: 0,
                    endTimestamp: 0,
                    amount: unstakeAmount,
                    id: validatorDelegations.distribution.instantId
                });
                _dequeueInstantDelegation(instantUnstake);
                _enqueueUnstake(instantUnstake);
                if (instantUnstake.amount > amountToUnstake) {
                    return (0, instantUnstake.amount - amountToUnstake);
                }
                amountToUnstake -= instantUnstake.amount;
            }
        }
    }

    /// @notice Internal function to calculate instant unstake amount
    /// @dev Ensures stake threshold constraints are met
    /// @param _existingStake Current stake amount (in IP)
    /// @param _unstakeAmount Requested unstake amount (in IP)
    /// @return Amount that can be unstaked (in IP)
    function _calculateInstantUnstakeAmount(uint256 _existingStake, uint256 _unstakeAmount)
        internal
        view
        returns (uint256)
    {
        /**
         * The threshold represents both the minimum delegation size, and the minimum unstake amount.
         * In the event that the remaining delegation amount after unstaking would be below the threshold,
         * the entire delegation will be unstaked automatically.
         */
        uint256 threshold = _selector().ipTokenStaking().minStakeAmount();

        /**
         * Case 1: If the existing stake is below the threshold; OR
         * Case 2: If the remaining stake would be below the threshold after the minimum unstake; OR
         * Case 3: If the requested unstake amount exceeds existing stake; OR
         * Case 4: If the remaining stake would be less than the threshold after the requested unstake;
         * return the existing stake.
         */
        if (
            _existingStake < threshold || _existingStake - threshold < threshold || _existingStake < _unstakeAmount
                || _existingStake - _unstakeAmount < threshold
        ) {
            return _existingStake;
        }

        /**
         * Case 5: The remaining stake after any unstake will be greater than the threshold;
         * return the maximum value among the requested amount and the threshold.
         */
        return _unstakeAmount < threshold ? threshold : _unstakeAmount;
    }

    /// @notice Internal function to check if amount meets stake threshold
    /// @param _amount Amount to check (in IP)
    /// @return Whether the amount meets the stake threshold
    function _stakeThresholdMet(uint256 _amount) internal view returns (bool) {
        return _amount >= _selector().ipTokenStaking().minStakeAmount();
    }

    /// @notice Internal function to handle bonded unstakes
    /// @dev Processes unstakes from bonded maturity delegations
    /// @param _amount Amount to unstake (in IP)
    /// @return amountToUnstake Remaining amount to unstake (in IP)
    /// @return excessUnstake Any excess amount that was unstaked (in IP)
    function _handleBondedUnstakes(uint256 _amount) internal returns (uint256 amountToUnstake, uint256 excessUnstake) {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        DelegatorState storage delegatorState = _delegatorState();
        amountToUnstake = _amount;
        excessUnstake = 0;

        bytes memory validatorPubkey;
        ValidatorDelegations storage validatorDelegations;
        DelegationQueue storage queue;

        // unstake in ascending maturity order
        for (uint256 i = 0; i < delegatorState.bondedMaturities.length; i++) {
            IIPTokenStaking.StakingPeriod maturity = delegatorState.bondedMaturities[i];
            // try each validator once
            for (uint256 j = 0; j < validatorRegistry.validators.length; j++) {
                validatorPubkey = _nextUnstakeValidator();
                validatorDelegations = validatorRegistry.delegations[validatorPubkey];
                queue = validatorDelegations.distribution.delegationsByMaturity[maturity];
                // while the next delegation in the queue is mature, unstake it
                while (amountToUnstake > 0 && _nextDelegationIsMature(queue)) {
                    Delegation memory bondedUnstake = _dequeueDelegation(queue);
                    _enqueueUnstake(bondedUnstake);
                    if (bondedUnstake.amount > amountToUnstake) {
                        excessUnstake = bondedUnstake.amount - amountToUnstake;
                        amountToUnstake = 0;
                        return (amountToUnstake, excessUnstake);
                    }
                    amountToUnstake -= bondedUnstake.amount;
                }
            }
        }
    }

    /// @notice Internal function to get next validator for unstaking
    /// @dev Rotates through validators in round-robin fashion
    /// @return Validator public key
    function _nextUnstakeValidator() internal returns (bytes memory) {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        bytes memory validatorPubkey = validatorRegistry.validators[validatorRegistry.unstakeIdx];
        validatorRegistry.unstakeIdx = (validatorRegistry.unstakeIdx + 1) % validatorRegistry.validators.length;
        return validatorPubkey;
    }

    /// @notice Internal function to check if next delegation in queue is mature
    /// @param _queue The delegation queue to check
    /// @return Whether the next delegation is mature
    function _nextDelegationIsMature(DelegationQueue storage _queue) internal view returns (bool) {
        bool hasNextDelegation = _queue.ptr < _queue.ids.length;
        return hasNextDelegation && block.timestamp > _queue.delegations[_queue.ids[_queue.ptr]].endTimestamp;
    }

    /// @notice Internal function to add validator to unstake queue
    /// @dev Adds validator to unstake queue if not already present
    /// @param _validator The validator to add to the unstake queue
    function _tryAddValidatorToUnstakeQueue(bytes memory _validator) internal {
        UnstakeQueue storage unstakeQueue = _unstakeQueue();
        if (unstakeQueue.instantUnstake[_validator].amount == 0 && unstakeQueue.bondedUnstakes[_validator].total == 0) {
            unstakeQueue.unstakeValidators.push(_validator);
        }
    }

    /// @inheritdoc IDelegator
    function handleUnstakeQueue() external override nonReentrant whenNotPaused {
        _handleUnstakeQueue();
    }

    /// @notice Internal function to process the unstake queue
    /// @dev Processes unstakes for all validators in the queue if enough time has passed
    function _handleUnstakeQueue() internal {
        UnstakeQueue storage unstakeQueue = _unstakeQueue();
        DelegatorState storage delegatorState = _delegatorState();
        IIPTokenStaking ipTokenStaking = _selector().ipTokenStaking();

        if (block.timestamp < unstakeQueue.nextUnstake || unstakeQueue.unstakeValidators.length == 0) {
            return;
        }

        uint256 fee = ipTokenStaking.fee();

        for (uint256 i = 0; i < unstakeQueue.unstakeValidators.length; i++) {
            bytes memory validator = unstakeQueue.unstakeValidators[i];
            Delegation memory instantUnstake = unstakeQueue.instantUnstake[validator];
            DelegationQueue storage bondedUnstakes = unstakeQueue.bondedUnstakes[validator];
            if (_stakeThresholdMet(instantUnstake.amount)) {
                _maybeClaimFee(fee);
                ipTokenStaking.unstake{value: fee}(
                    instantUnstake.validator,
                    instantUnstake.id,
                    instantUnstake.amount,
                    "" // Empty data parameter
                );
                delete unstakeQueue.instantUnstake[validator];
            } else if (bondedUnstakes.total > 0) {
                Delegation memory bondedUnstake = bondedUnstakes.delegations[bondedUnstakes.ids[bondedUnstakes.ptr]];
                _maybeClaimFee(fee);
                ipTokenStaking.unstake{value: fee}(
                    bondedUnstake.validator,
                    bondedUnstake.id,
                    bondedUnstake.amount,
                    "" // Empty data parameter
                );
                delete bondedUnstakes.delegations[bondedUnstakes.ids[bondedUnstakes.ptr]];
                bondedUnstakes.total -= bondedUnstake.amount;
                bondedUnstakes.ptr++;
            }
        }

        _tryRemoveValidatorsFromUnstakeQueue();
        unstakeQueue.nextUnstake += delegatorState.unstakeInterval;
    }

    /// @notice Internal function to claim fee from fee pool
    /// @dev Claims fee from fee pool if balance is less than fee amount
    /// @param _feeAmount The amount of fee to claim (in IP)
    function _maybeClaimFee(uint256 _feeAmount) internal {
        if (address(this).balance < _feeAmount) {
            _selector().insurancePoolByComponent(address(this)).claim(_feeAmount - address(this).balance);
        }
    }

    /// @notice Internal function to remove validators from unstake queue
    /// @dev Removes validators that have no remaining unstakes
    function _tryRemoveValidatorsFromUnstakeQueue() internal {
        UnstakeQueue storage unstakeQueue = _unstakeQueue();
        uint256 i = 0;
        while (i < unstakeQueue.unstakeValidators.length) {
            bytes memory validator = unstakeQueue.unstakeValidators[i];
            if (unstakeQueue.instantUnstake[validator].amount == 0 && unstakeQueue.bondedUnstakes[validator].total == 0)
            {
                unstakeQueue.unstakeValidators[i] =
                    unstakeQueue.unstakeValidators[unstakeQueue.unstakeValidators.length - 1];
                unstakeQueue.unstakeValidators.pop();
            } else {
                i++;
            }
        }
    }

    /// @inheritdoc IDelegator
    function addValidator(bytes calldata _validator) external override onlyAdmin {
        _addValidator(_validator);
        emit ValidatorAdded(_validator);
    }

    /// @notice Internal function to add a validator to the registry
    /// @dev Validates validator public key format and uniqueness
    /// @param _validator The validator public key to add
    function _addValidator(bytes memory _validator) internal {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        require(!validatorRegistry.delegations[_validator].exists, ValidatorAlreadyExists());
        require(_validator.length == VALIDATOR_PUBKEY_LENGTH, ValidatorInvalidFormat());
        require(keccak256(_validator) != keccak256(bytes("")), ValidatorCannotBeNull());
        validatorRegistry.validators.push(_validator);
        validatorRegistry.delegations[_validator].exists = true;
    }

    /// @inheritdoc IDelegator
    function removeValidator(bytes calldata _validator) external override onlyAdmin {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        require(validatorRegistry.delegations[_validator].exists, ValidatorDoesNotExist());
        require(validatorRegistry.delegations[_validator].total == 0, ValidatorHasDelegations());
        require(validatorRegistry.validators.length > 1, MinimumValidatorRequired());
        _removeValidator(_validator);
        emit ValidatorRemoved(_validator);
    }

    /// @notice Internal function to remove a validator from the registry
    /// @dev Removes validator and updates validator list
    /// @param _validator The validator public key to remove
    function _removeValidator(bytes calldata _validator) internal {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        delete validatorRegistry.delegations[_validator];
        for (uint256 i = 0; i < validatorRegistry.validators.length; i++) {
            if (keccak256(validatorRegistry.validators[i]) == keccak256(_validator)) {
                validatorRegistry.validators[i] = validatorRegistry.validators[validatorRegistry.validators.length - 1];
                validatorRegistry.validators.pop();
                break;
            }
        }
        if (validatorRegistry.stakeIdx >= validatorRegistry.validators.length) {
            validatorRegistry.stakeIdx = 0;
        }
        if (validatorRegistry.unstakeIdx >= validatorRegistry.validators.length) {
            validatorRegistry.unstakeIdx = 0;
        }
    }

    /// @inheritdoc IDelegator
    function redelegate(bytes calldata _fromValidator, bytes calldata _toValidator, uint256 _attempts)
        external
        override
        onlyAdmin
        returns (uint256 remainder)
    {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        require(validatorRegistry.delegations[_fromValidator].exists, ValidatorDoesNotExist());
        require(validatorRegistry.delegations[_toValidator].exists, ValidatorDoesNotExist());
        require(keccak256(_fromValidator) != keccak256(_toValidator), FromAndToValidatorSame());
        require(_attempts > 0, RedelegateAttemptsInvalid());
        require(validatorRegistry.delegations[_fromValidator].total > 0, FromValidatorNoDelegations());
        return _redelegate(_fromValidator, _toValidator, _attempts);
    }

    /// @notice Internal function to handle redelegation
    /// @dev Processes redelegation requests up to specified number of attempts
    /// @param _fromValidator Validator to redelegate from
    /// @param _toValidator Validator to redelegate to
    /// @param _attempts Number of redelegation attempts to make
    /// @return remainder Remaining amount that couldn't be redelegated (in IP)
    function _redelegate(bytes calldata _fromValidator, bytes calldata _toValidator, uint256 _attempts)
        internal
        returns (uint256 remainder)
    {
        ValidatorRegistry storage validatorRegistry = _validatorRegistry();
        DelegatorState storage delegatorState = _delegatorState();

        remainder = validatorRegistry.delegations[_fromValidator].total;
        for (uint256 i = 0; i < _attempts; i++) {
            ValidatorDelegations storage fromValidatorDelegations = validatorRegistry.delegations[_fromValidator];
            uint256 delegationId;
            uint256 amount;

            if (fromValidatorDelegations.distribution.instant > 0) {
                delegationId = fromValidatorDelegations.distribution.instantId;
                amount = fromValidatorDelegations.distribution.instant;
                Delegation memory instantDelegation = Delegation({
                    validator: _fromValidator,
                    maturity: IIPTokenStaking.StakingPeriod.FLEXIBLE,
                    startTimestamp: 0,
                    duration: 0,
                    endTimestamp: 0,
                    amount: amount,
                    id: delegationId
                });
                _dequeueInstantDelegation(instantDelegation);
                instantDelegation.validator = _toValidator;
                _enqueueDelegation(instantDelegation);
            } else {
                for (uint256 j = 0; j < delegatorState.bondedMaturities.length; j++) {
                    IIPTokenStaking.StakingPeriod maturity = delegatorState.bondedMaturities[j];
                    if (fromValidatorDelegations.distribution.delegationsByMaturity[maturity].total > 0) {
                        Delegation memory bondedDelegation =
                            _dequeueDelegation(fromValidatorDelegations.distribution.delegationsByMaturity[maturity]);
                        delegationId = bondedDelegation.id;
                        amount = bondedDelegation.amount;
                        bondedDelegation.validator = _toValidator;
                        _enqueueDelegation(bondedDelegation);
                        break;
                    }
                }
            }

            // exit early if there is nothing else to redelegate
            if (amount == 0) {
                break;
            }

            IIPTokenStaking ipTokenStaking = _selector().ipTokenStaking();
            uint256 fee = ipTokenStaking.fee();
            _maybeClaimFee(fee);
            ipTokenStaking.redelegate{value: fee}(_fromValidator, _toValidator, delegationId, amount);

            remainder = remainder > amount ? remainder - amount : 0;
        }

        return remainder;
    }

    /// @inheritdoc IDelegator
    function rebase() external override onlyAdmin {
        // TODO: Implement rebase logic
    }

    // --- GETTERS AND SETTERS ---

    /// @inheritdoc IDelegator
    function getValidators() external view override returns (bytes[] memory) {
        return _validatorRegistry().validators;
    }

    /// @inheritdoc IDelegator
    function getValidatorStakedAmount(bytes calldata _validator) external view override returns (uint256) {
        return _validatorRegistry().delegations[_validator].total;
    }

    /// @inheritdoc IDelegator
    function getValidatorDistributionByMaturity(bytes calldata validator, IIPTokenStaking.StakingPeriod maturity)
        external
        view
        override
        returns (uint256)
    {
        return _validatorRegistry().delegations[validator].distribution.delegationsByMaturity[maturity].total;
    }

    /// @inheritdoc IDelegator
    function setUnstakeInterval(uint256 _unstakeInterval) external override onlyAdmin {
        require(_isValidUnstakeInterval(_unstakeInterval), InvalidUnstakeInterval());
        _delegatorState().unstakeInterval = _unstakeInterval;
        emit DelegatorStateUpdated(_delegatorState());
    }

    /// @inheritdoc IDelegator
    function setDistributionConfigs(MaturityConfig[] calldata _maturityConfigs) external override onlyAdmin {
        _trySetDistribution(_maturityConfigs);
    }

    /// @inheritdoc IDelegator
    function getGlobalDistributionByMaturity(IIPTokenStaking.StakingPeriod _maturity)
        external
        view
        override
        returns (uint256)
    {
        return _globalDistribution().totalByMaturity[_maturity];
    }

    /// @inheritdoc IDelegator
    function getGlobalDistributionTotal() external view override returns (uint256) {
        return _globalDistribution().total;
    }

    /// @inheritdoc IDelegator
    function getNextUnstakeTimestamp() external view override returns (uint256 nextUnstake) {
        return _unstakeQueue().nextUnstake;
    }

    /// @inheritdoc IDelegator
    function getUnstakeQueueValidators() external view override returns (bytes[] memory validators) {
        return _unstakeQueue().unstakeValidators;
    }

    /// @inheritdoc IDelegator
    function getUnstakeQueueByValidator(bytes calldata _validator)
        external
        view
        override
        returns (Delegation[] memory unstakes)
    {
        UnstakeQueue storage unstakeQueue = _unstakeQueue();
        Delegation memory instantUnstake = unstakeQueue.instantUnstake[_validator];
        DelegationQueue storage bondedQueue = unstakeQueue.bondedUnstakes[_validator];

        bool instantExists = instantUnstake.amount > 0;
        uint256 bondedIds = bondedQueue.ids.length - bondedQueue.ptr;
        uint256 unstakeLength = instantExists ? bondedIds + 1 : bondedIds;
        unstakes = new Delegation[](unstakeLength);

        uint256 unstakeIdx = 0;
        if (instantExists) {
            unstakes[unstakeIdx] = instantUnstake;
            unstakeIdx++;
        }

        for (uint256 idx = bondedQueue.ptr; idx < bondedQueue.ids.length; idx++) {
            unstakes[unstakeIdx] = bondedQueue.delegations[bondedQueue.ids[idx]];
            unstakeIdx++;
        }

        return unstakes;
    }

    /// @inheritdoc IDelegator
    function setBondedMaturitiesEnabled(bool _bondedMaturitiesEnabled) external override onlyAdmin {
        _delegatorState().bondedMaturitiesEnabled = _bondedMaturitiesEnabled;
        emit DelegatorStateUpdated(_delegatorState());
    }

    function setWithdrawalAddress() external onlyAdmin {
        _setWithdrawalAddress();
    }

    function _setWithdrawalAddress() internal {
        IIPTokenStaking ipTokenStaking = _selector().ipTokenStaking();
        uint256 fee = ipTokenStaking.fee();
        _maybeClaimFee(fee);
        ipTokenStaking.setWithdrawalAddress{value: fee}(address(_selector().withdrawalPool()));
    }

    function setRewardsAddress() external onlyAdmin {
        _setRewardsAddress();
    }

    function _setRewardsAddress() internal {
        IIPTokenStaking ipTokenStaking = _selector().ipTokenStaking();
        uint256 fee = ipTokenStaking.fee();
        _maybeClaimFee(fee);
        ipTokenStaking.setRewardsAddress{value: fee}(address(_selector().rewardPool()));
    }

    // --- RECEIVER ---

    /// @dev Fallback function that treats all incoming IP as funds to pay fees
    receive() external payable {
        // do nothing
    }
}
