//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "@solady/utils/SafeTransferLib.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";
import { LibClone } from "@solady/utils/LibClone.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { FastLaneERC4626 } from "./FLERC4626.sol";
import { CoinbaseUpgradeable } from "./CoinbaseUpgradeable.sol";
import {
    STAKING_GAS_BUFFER,
    STAKING_GAS_GET_VALIDATOR,
    RAY,
    MAX_NON_STAKING_REVENUE_MULTIPLIER_RAY
} from "./Constants.sol";
import {
    Epoch,
    PendingBoost,
    CashFlows,
    ValidatorStats,
    StakingEscrow,
    AllocationRevenue,
    ValidatorData,
    ValidatorDataStorage
} from "./Types.sol";
import { StorageLib } from "./libraries/StorageLib.sol";
import { IMonadStaking } from "./interfaces/IMonadStaking.sol";
import { ICoinbase } from "./interfaces/ICoinbase.sol";
import {
    STAKING,
    SHMONAD_VALIDATOR_DEACTIVATION_PERIOD,
    BPS_SCALE,
    EPOCHS_TRACKED,
    UNKNOWN_VAL_ID,
    UNKNOWN_VAL_ADDRESS,
    LAST_VAL_ID,
    FIRST_VAL_ID,
    COINBASE_SALT,
    COINBASE_IMMUTABLE_ARGS_VERSION
} from "./Constants.sol";
import { StakeAllocationLib } from "./libraries/StakeAllocationLib.sol";

/*
WARNING: Validator ID vs. `block.coinbase` Addresses on Monad

- Block Author Address (block.coinbase): On Monad this is NOT a unique identifier
  for a validator. Multiple validator IDs can share the same block.coinbase address.
  As a result, ShMonad MUST NOT infer validator identity from block.coinbase.

- Registry Mappings in this file:
  - s_valCoinbases[valId] -> coinbaseContractAddress
  - s_valIdByCoinbase[coinbaseContractAddress] -> valId
  These mappings are ONLY for the per‑validator Coinbase contract, NOT the
  network’s block.coinbase author address.

- Primary Key is Validator ID: All runtime logic, cranking, accounting, and
  precompile calls must key off validator IDs. PrecompileHelpers obtains the
  current proposer via STAKING.getProposerValId() and never relies on
  block.coinbase. When ShMonad needs a coinbase address (for events or to call
  ICoinbase.process), it derives it from the validator ID via _validatorCoinbase.

- Where this matters:
  - Events that include a "coinbase" field reference the per‑validator Coinbase
    contract address for operator visibility.
  - Crank ordering uses a linked list indexed by validator IDs (FIRST_VAL_ID /
    LAST_VAL_ID sentinels). No address‑based sentinels remain.
  - Do not attempt to map block.coinbase -> validator ID in this contract; use
    the precompile (getProposerValId) or the stored valId -> coinbase mapping.
*/

abstract contract ValidatorRegistry is FastLaneERC4626 {
    using Math for uint256;
    using SafeTransferLib for address;
    using SafeCastLib for uint256;
    using StorageLib for CashFlows;
    using StorageLib for StakingEscrow;
    using StorageLib for PendingBoost;

    // ================================================== //
    //                    Admin Functions                 //
    // ================================================== //

    // Queue up a deactivation.
    // NOTE: SHMONAD_VALIDATOR_DEACTIVATION_PERIOD is a minimum. Final removal also waits for isolated crank work and
    // all tracked and native pooled stake to clear; an unreadable native position defers cleanup.
    // NOTE: Deactivation immediately flags the validator as inactive for reward settlement, so any unpaid
    // rewards (including those earned earlier in the current epoch) are redirected to shMON yield.
    /// @custom:selector 0x8f289544
    function deactivateValidator(uint64 validatorId) external virtual onlyOwner {
        _assertAllocationRoundIdle();
        _beginDeactivatingValidator(validatorId);
    }

    /// @notice Adds a validator and primes its epoch windows without affecting ordering.
    /// @dev Validates existence via precompile (except UNKNOWN placeholder during init).
    /// Inserts at tail of the crank linked list; enforces one id ↔ one coinbase mapping.
    /// Reverts if attempting to reuse sentinel addresses or if validator not fully removed.
    /// @custom:selector 0xb5965470
    function addValidator(uint64 validatorId, address coinbase) external virtual onlyOwner {
        _assertAllocationRoundIdle();
        require(validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));

        // NOTE: We want to avoid scenarios where a validator has their own custom smart contract
        // as the coinbase with unknown code being run when 'process()' is called. We can check
        // at crank time that the bytecode isn't 7702-enabled, it must be manually verified offchain
        // that the coinbase is a wallet with a known private key and not an undeployed create2
        // smart contract.
        require(coinbase.code.length == 0, CustomCoinbaseCantBeContract(validatorId));
        _addValidator(validatorId, coinbase);
    }

    /// @custom:selector 0x9fc758e1
    function addValidator(uint64 validatorId) external virtual onlyOwner returns (address coinbase) {
        _assertAllocationRoundIdle();
        require(validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));
        coinbase = _deployOrGetCoinbaseContractAddress(validatorId);
        _addValidator(validatorId, coinbase);
    }

    /// @notice Deploys and links a fresh coinbase proxy for an existing validator.
    /// @dev `nonReentrant` prevents the previous coinbase's `process()` callback from reentering
    /// while registry links are being migrated.
    /// @custom:selector 0x0c017712
    function updateCoinbaseForExistingValidator(uint64 validatorId)
        external
        virtual
        nonReentrant
        onlyOwner
        returns (address newCoinbase)
    {
        // Migration rewrites validator coinbase links used by the allocation pass; require an idle round onchain.
        _assertAllocationRoundIdle();
        require(validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));
        // Migration is only valid for validators already registered with ShMonad. Check this before CREATE2 so a
        // mistaken Safe batch cannot deploy and reserve the deterministic coinbase for an unrelated validator id.
        require(s_validatorIsActive[validatorId], ValidatorNotActive(validatorId));
        address _previousCoinbase = s_valCoinbases[validatorId];
        require(_previousCoinbase != address(0), InvalidValidatorId(validatorId));
        address _legacyCoinbase = _previousCoinbase.code.length > 0 ? _previousCoinbase : address(0);

        bool _configImported;
        // Get the new coinbase address. On first deployment, initialization will best-effort migrate the legacy
        // operational config while still defaulting auth to the current precompile value.
        (newCoinbase, _configImported) = _deployOrGetCoinbaseContractAddress(validatorId, _legacyCoinbase);

        // Verify this is a net new deployment
        require(_previousCoinbase != newCoinbase, CoinbaseAlreadyDeployed(validatorId, newCoinbase));
        require(newCoinbase != address(0), ZeroAddress());

        if (_legacyCoinbase != address(0)) {
            if (_configImported) {
                emit CoinbaseMigrationConfigImported(validatorId, _previousCoinbase, newCoinbase);
            } else {
                emit CoinbaseMigrationConfigImportFailed(validatorId, _previousCoinbase, newCoinbase);
            }
        }

        // Clear out any pending balances / rewards on the old contract, if it exists
        if (_previousCoinbase.code.length > 0 && _previousCoinbase.balance > 0) {
            _settleCoinbaseContract(validatorId, _previousCoinbase);
            if (_previousCoinbase.balance > 0) {
                emit CoinbaseMigrationResidualBalance(validatorId, _previousCoinbase, _previousCoinbase.balance);
            }
        }

        // Unlink the previous coinbase address if it exists and then link the new one
        _unlinkValidatorCoinbase(validatorId);
        _linkValidatorCoinbase(validatorId, newCoinbase);

        emit CoinbaseContractUpdated(validatorId, _previousCoinbase, newCoinbase);
    }

    /// @custom:selector 0x9e6cb0bf
    function updateStakingCommission(uint16 feeInBps) external virtual onlyOwner {
        require(feeInBps < BPS_SCALE, CommissionMustBeBelow100Percent());
        s_admin.stakingCommission = feeInBps;
    }

    /// @custom:selector 0x01b3bfa4
    function updateBoostCommission(uint16 feeInBps) external virtual onlyOwner {
        require(feeInBps < BPS_SCALE, CommissionMustBeBelow100Percent());
        s_admin.boostCommissionRate = feeInBps;
    }

    /// @custom:selector 0x071c3626
    function updateIncentiveAlignmentPercentage(uint16 percentageInBps) external virtual onlyOwner {
        require(percentageInBps < BPS_SCALE, PercentageMustBeBelow100Percent());
        s_admin.incentiveAlignmentPercentage = percentageInBps;
    }

    /// @notice Updates the multiplier applied to non-staking revenue during stake allocation.
    /// @dev The configured value is stored as a ray and clamped to the governance-approved [1x, 20x] range.
    /// @param multiplierRay New non-staking revenue multiplier in ray precision.
    /// @custom:selector 0xc1d470fc
    function updateNonStakingRevenueMultiplierRay(uint256 multiplierRay) external virtual onlyOwner {
        _assertAllocationRoundIdle();
        require(
            multiplierRay >= RAY && multiplierRay <= MAX_NON_STAKING_REVENUE_MULTIPLIER_RAY,
            InvalidNonStakingRevenueMultiplier(multiplierRay, RAY, MAX_NON_STAKING_REVENUE_MULTIPLIER_RAY)
        );

        uint256 oldMultiplierRay = getNonStakingRevenueMultiplierRay();
        s_stakeAllocationConfig.nonStakingRevenueMultiplierRay = multiplierRay.toUint128();
        emit NonStakingRevenueMultiplierUpdated(oldMultiplierRay, multiplierRay);
    }

    /// @notice Updates the staking-yield deadband used during stake allocation.
    /// @param deadbandBps New deadband in basis points of each validator's expected staking yield.
    /// @custom:selector 0x122db637
    function updateStakingYieldDeadbandBps(uint16 deadbandBps) external virtual onlyOwner {
        _assertAllocationRoundIdle();
        require(deadbandBps <= BPS_SCALE, InvalidStakingYieldDeadband(deadbandBps, BPS_SCALE));

        uint16 oldDeadbandBps = s_stakeAllocationConfig.stakingYieldDeadbandBps;
        s_stakeAllocationConfig.stakingYieldDeadbandBps = deadbandBps;
        emit StakingYieldDeadbandUpdated(oldDeadbandBps, deadbandBps);
    }

    /// @notice Updates whether validator-attributed isolated rewards are included in the stake-allocation signal.
    /// @dev This only changes the weighting signal used to route pooled stake. Actual pooled-versus-isolated reward
    /// accounting remains split and unchanged.
    /// @param include Whether to include isolated rewards in the signal used for pooled stake allocation.
    /// @custom:selector 0xe5b790d1
    function updateIncludeIsolatedRewardsInStakeAllocation(bool include) external virtual onlyOwner {
        _assertAllocationRoundIdle();

        bool oldInclude = s_stakeAllocationConfig.includeIsolatedRewardsInStakeAllocation;
        s_stakeAllocationConfig.includeIsolatedRewardsInStakeAllocation = include;
        emit IncludeIsolatedRewardsInStakeAllocationUpdated(oldInclude, include);
    }

    /// @custom:selector 0x84aae4c9
    function setFrozenStatus(bool isFrozen) external virtual onlyOwner {
        globalEpochPtr_N(0).frozen = isFrozen;
    }

    /// @custom:selector 0xc2006eaa
    function setClosedStatus(bool isClosed) external virtual onlyOwner {
        globalEpochPtr_N(0).closed = isClosed;
    }

    /// @custom:selector 0x374eabf1
    function upgradeCoinbaseBeaconImplementation(address newImplementation) external virtual onlyCodeUpgradeAuthority {
        require(s_coinbaseBeacon != address(0), CoinbaseBeaconNotInitialized());
        require(newImplementation.code.length > 0, InvalidCoinbaseImplementation(newImplementation));

        address _beacon = s_coinbaseBeacon;
        address _oldImplementation = UpgradeableBeacon(_beacon).implementation();
        bytes32 _expectedSchema = _coinbaseImmutableArgsSchemaHash(_oldImplementation);
        bytes32 _newSchema = _coinbaseImmutableArgsSchemaHash(newImplementation);
        require(_newSchema == _expectedSchema, IncompatibleCoinbaseImplementation(newImplementation));
        UpgradeableBeacon(_beacon).upgradeTo(newImplementation);

        emit CoinbaseBeaconImplementationUpgraded(_beacon, _oldImplementation, newImplementation);
    }

    // ================================================== //
    //            Coinbase Auth Functions                //
    // ================================================== //

    /// @notice Allows a validator's auth address or the ShMonad owner to process its Coinbase contract via ShMonad.
    /// @dev Uses the same settlement path as cranking to account for donations as revenue. `nonReentrant`
    /// blocks coinbase callbacks from reentering and mutating balances mid-settlement.
    /// @custom:selector 0xa1b6d59b
    function processCoinbaseByAuth(uint64 validatorId) external notWhenFrozen nonReentrant {
        require(validatorId != 0 && validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));

        address coinbase = s_valCoinbases[validatorId];
        require(coinbase != address(0), InvalidValidatorId(validatorId));
        require(coinbase.code.length > 0, InvalidValidatorAddress(coinbase));

        // Preserve owner recovery without a precompile dependency, but authorize validators from live staking state.
        if (msg.sender != owner()) {
            (address authAddress,,,,,,,,,,,) =
                STAKING.getValidator{ gas: STAKING_GAS_GET_VALIDATOR + STAKING_GAS_BUFFER }(validatorId);
            require(msg.sender == authAddress, OnlyCoinbaseAuth(validatorId, msg.sender));
        }

        _settleCoinbaseContract(validatorId, coinbase);
    }

    /// @notice Allows the ShMonad owner to process a Coinbase contract via its address.
    /// @dev Supports coinbases no longer registered in ShMonad. Restricted to `onlyOwner` to prevent unauthorized
    /// processing of arbitrary coinbase addresses. `nonReentrant` blocks coinbase callbacks from reentering and
    /// mutating balances mid-settlement.
    /// @param coinbase The address of the Coinbase contract to process.
    /// @custom:selector 0x41638da9
    function processCoinbaseByAuth(address coinbase) external onlyOwner notWhenFrozen nonReentrant {
        require(coinbase != address(0), InvalidValidatorAddress(coinbase));
        require(coinbase.code.length > 0, InvalidValidatorAddress(coinbase));

        uint64 valId;
        try ICoinbase(coinbase).VAL_ID() returns (uint64 _valId) {
            valId = _valId;
            require(valId != 0 && valId != UNKNOWN_VAL_ID, InvalidValidatorId(valId));
        } catch {
            revert InvalidValidatorAddress(coinbase);
        }

        try ICoinbase(coinbase).SHMONAD() returns (address shmonad) {
            require(shmonad == address(this), InvalidValidatorAddress(coinbase));
        } catch {
            revert InvalidValidatorAddress(coinbase);
        }

        _settleCoinbaseContract(valId, coinbase);
    }

    function _addValidator(uint64 validatorId, address coinbase) internal {
        require(validatorId != 0, InvalidValidatorId(validatorId));
        // Prevent registering sentinel IDs which would break the linked list
        require(validatorId != FIRST_VAL_ID && validatorId != LAST_VAL_ID, InvalidValidatorId(validatorId));
        require(coinbase != address(0), ZeroAddress());
        require(
            !s_validatorIsActive[UNKNOWN_VAL_ID] || coinbase != UNKNOWN_VAL_ADDRESS, InvalidValidatorAddress(coinbase)
        );

        // Verify validator exists in precompile (unless it's the UNKNOWN_VAL_ID placeholder used during init)
        // Public entry points explicitly reject UNKNOWN_VAL_ID, so it can only reach here during initialization
        if (validatorId != UNKNOWN_VAL_ID) {
            // Note: Real precompile returns zeros for missing, mock reverts with UnknownValidator()
            try STAKING.getValidator{ gas: STAKING_GAS_GET_VALIDATOR + STAKING_GAS_BUFFER }(validatorId) returns (
                address authAddress,
                uint64,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                bytes memory,
                bytes memory
            ) {
                require(authAddress != address(0), ValidatorNotFoundInPrecompile(validatorId));
            } catch {
                revert ValidatorNotFoundInPrecompile(validatorId);
            }
        }

        // Disallow re-adding an active validator
        require(!s_validatorIsActive[validatorId], ValidatorAlreadyAdded());

        // If the coinbase is already linked:
        // - to a different validatorId: treat as already added
        // - to the same validatorId: treat as not fully removed
        uint64 _existingForCoinbase = s_valIdByCoinbase[coinbase];
        require(_existingForCoinbase == 0 || _existingForCoinbase != validatorId, ValidatorNotFullyRemoved());
        require(_existingForCoinbase == 0, ValidatorAlreadyAdded());

        // Validator must be fully removed (which takes a min of SHMONAD_VALIDATOR_DEACTIVATION_PERIOD from when
        // deactivation is initiated) before they can be added again.
        for (uint256 i; i < EPOCHS_TRACKED; i++) {
            require(s_validatorEpoch[validatorId][i].epoch == 0, ValidatorNotFullyRemoved());
        }

        // Policy decision: isolated claimants must not be able to keep a validator in the crank sequence forever once
        // all precompile-facing unwind work is done. Instead, registry reuse is what gets blocked until any residual
        // isolated state for this validator id has been fully claimed out and can be safely reset.
        _assertValidatorCanBeAdded(validatorId);
        _prepareValidatorForReuse(validatorId);

        ++s_activeValidatorCount;

        s_validatorIsActive[validatorId] = true;
        ValidatorDataStorage storage _validatorData = s_validatorData[validatorId];
        _validatorData.isActive = true;
        // Registration is the first native membership observation. Recording its epoch prevents the first crank from
        // counting the same view again toward the two-observation deactivation policy.
        (uint64 _monadEpoch, bool _inEpochDelayPeriod) = _getEpochInfo();
        _validatorData.inActiveSet_Current = _isValidatorInActiveSet(validatorId, _inEpochDelayPeriod);
        // There is no prior inactive observation at registration, regardless of the initial native view.
        _validatorData.inActiveSet_Last = true;
        _validatorData.activeSetObservationEpoch = _monadEpoch;
        _linkValidatorCoinbase(validatorId, coinbase);

        uint64 _currentEpoch = s_admin.internalEpoch;

        // Initialize s_validatorEpoch for the new validator
        _setEpochStorage(
            validatorEpochPtr_N(1, validatorId),
            Epoch({
                epoch: _currentEpoch + 1,
                withdrawalId: 1,
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                wasCranked: false,
                frozen: false,
                closed: false,
                targetStakeAmount: 0
            })
        );

        _setEpochStorage(
            validatorEpochPtr_N(0, validatorId),
            Epoch({
                epoch: _currentEpoch,
                withdrawalId: 1,
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                // Every real validator can receive escrow before native activation, so its onboarding bucket must run
                // the normal crank after rotating to N(-1). This intentionally gives pending native activation no
                // onboarding grace; the placeholder never owns validator rewards and keeps the initial skip.
                wasCranked: validatorId == UNKNOWN_VAL_ID,
                frozen: false,
                closed: false,
                targetStakeAmount: 0
            })
        );

        if (_currentEpoch > 0) --_currentEpoch;

        _setEpochStorage(
            validatorEpochPtr_N(-1, validatorId),
            Epoch({
                epoch: _currentEpoch,
                withdrawalId: 1,
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                wasCranked: true,
                frozen: false,
                closed: false,
                targetStakeAmount: 0
            })
        );

        if (_currentEpoch > 0) --_currentEpoch;

        _setEpochStorage(
            validatorEpochPtr_N(-2, validatorId),
            Epoch({
                epoch: _currentEpoch,
                withdrawalId: 1,
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                wasCranked: true,
                frozen: false,
                closed: false,
                targetStakeAmount: 0
            })
        );

        if (_currentEpoch > 0) --_currentEpoch;

        _setEpochStorage(
            validatorEpochPtr_N(-3, validatorId),
            Epoch({
                epoch: _currentEpoch,
                withdrawalId: 1,
                hasWithdrawal: false,
                hasDeposit: false,
                crankedInBoundaryPeriod: false,
                wasCranked: true,
                frozen: false,
                closed: false,
                targetStakeAmount: 0
            })
        );

        validatorRewardsPtr_N(0, validatorId).clear();
        validatorRewardsPtr_N(1, validatorId).clear();

        validatorPendingPtr_N(0, validatorId).clear();
        validatorPendingPtr_N(1, validatorId).clear();

        // Update the link pointers
        _addValidatorToCrankSequence(validatorId);

        emit ValidatorAdded(validatorId, coinbase);
    }

    /// @notice Checks if a validator is in the active set and caches the result in transient storage.
    function _isValidatorInActiveSetTransient(uint64 valId) internal returns (bool) {
        if (valId == UNKNOWN_VAL_ID) {
            // Placeholder validator represents unregistered-flow accounting and must always stay "active".
            return true;
        }
        if (t_validatorActiveSetCheckValId != valId) {
            bool _isActive = _isValidatorInActiveSet(valId);
            t_validatorActiveSetCheckValId = valId;
            t_validatorActiveSetCheckValIdState = _isActive;
            return _isActive;
        }
        return t_validatorActiveSetCheckValIdState;
    }

    /// @notice Checks native membership for a known epoch phase and caches the result in transient storage.
    function _isValidatorInActiveSetTransient(uint64 valId, bool inEpochDelayPeriod) internal returns (bool) {
        if (valId == UNKNOWN_VAL_ID) return true;
        if (t_validatorActiveSetCheckValId != valId) {
            bool _isActive = _isValidatorInActiveSet(valId, inEpochDelayPeriod);
            t_validatorActiveSetCheckValId = valId;
            t_validatorActiveSetCheckValIdState = _isActive;
            return _isActive;
        }
        return t_validatorActiveSetCheckValIdState;
    }

    /// @notice Marks a validator inactive only after revalidating the cached native membership result.
    function _markValidatorNotInActiveSet(uint64 valId, uint256 detectionIndex) internal {
        bool _stillActive = s_validatorData[valId].inActiveSet_Current && _isValidatorInActiveSetTransient(valId);
        if (_stillActive) return;

        if (s_validatorData[valId].inActiveSet_Current) s_validatorData[valId].inActiveSet_Current = false;

        emit ValidatorNotFoundInActiveSet(valId, s_valCoinbases[valId], globalEpochPtr_N(0).epoch, detectionIndex);
    }

    function _beginDeactivatingValidator(uint64 validatorId) internal {
        address _coinbase = s_valCoinbases[validatorId];
        require(s_validatorData[validatorId].isActive, ValidatorAlreadyDeactivated());

        --s_activeValidatorCount;
        s_validatorData[validatorId].isActive = false;
        s_validatorData[validatorId].epoch = s_admin.internalEpoch;
        emit ValidatorMarkedInactive(validatorId, _coinbase, s_admin.internalEpoch);
    }

    function _completeDeactivatingValidator(uint64 validatorId) internal virtual {
        require(s_validatorIsActive[validatorId], ValidatorAlreadyDeactivated());

        // Enforce the minimum queue delay before the StakeTracker residual-state guards can finalize removal.
        require(!s_validatorData[validatorId].isActive, ValidatorDeactivationNotQueued());
        require(
            s_admin.internalEpoch >= s_validatorData[validatorId].epoch + SHMONAD_VALIDATOR_DEACTIVATION_PERIOD,
            ValidatorDeactivationQueuedIncomplete()
        );

        delete s_validatorIsActive[validatorId];
        _unlinkValidatorCoinbase(validatorId);
        delete s_validatorData[validatorId];

        // Remove this validator from the link and connect together the validators on either end
        _removeValidatorFromCrankSequence(validatorId);

        for (uint256 i; i < EPOCHS_TRACKED; i++) {
            delete s_validatorEpoch[validatorId][i];
            delete s_validatorRewards[validatorId][i];
            delete s_validatorPending[validatorId][i];
            delete s_validatorAllocationRevenue[validatorId][i];
        }

        emit ValidatorDeactivated(validatorId);
    }

    // Extension hooks for subclasses that need allocation or validator-reuse checks. Base registry paths are no-ops.
    function _assertAllocationRoundIdle() internal view virtual { }

    function _assertValidatorCanBeAdded(uint64 validatorId) internal view virtual { }

    function _prepareValidatorForReuse(uint64 validatorId) internal virtual { }

    function _removeValidatorFromCrankSequence(uint64 validatorId) internal {
        uint64 _nextValidator = s_valLinkNext[validatorId];
        uint64 _previousValidator = s_valLinkPrevious[validatorId];

        s_valLinkNext[_previousValidator] = _nextValidator;
        s_valLinkPrevious[_nextValidator] = _previousValidator;
    }

    function _addValidatorToCrankSequence(uint64 validatorId) internal {
        uint64 _previousTailValidator = s_valLinkPrevious[LAST_VAL_ID];
        s_valLinkNext[_previousTailValidator] = validatorId;
        s_valLinkPrevious[validatorId] = _previousTailValidator;
        s_valLinkNext[validatorId] = LAST_VAL_ID;
        s_valLinkPrevious[LAST_VAL_ID] = validatorId;
    }

    // ================================================== //
    //          validatorId <-> block.coinbase map        //
    // ================================================== //

    /// @dev Establishes 1:1 link between `valId` and `coinbase`. Reverts if either already linked.
    /// Invariant after success: `s_valCoinbases[valId] == coinbase` and `s_validatorData[coinbase].id == valId`.
    function _linkValidatorCoinbase(uint64 valId, address coinbase) internal {
        require(coinbase != address(0), ZeroAddress());
        require(s_valCoinbases[valId] == address(0) && s_valIdByCoinbase[coinbase] == 0, ValidatorAlreadyAdded());

        s_valCoinbases[valId] = coinbase;
        s_valIdByCoinbase[coinbase] = valId;
    }

    /// @dev Clears 1:1 link between `valId` and its existing `coinbase`, if any.
    /// Invariant after success: `s_valCoinbases[valId] == address(0)` and `s_validatorData[coinbase].id == 0`.
    function _unlinkValidatorCoinbase(uint64 valId) internal {
        address _coinbase = s_valCoinbases[valId];
        if (_coinbase != address(0)) {
            delete s_valIdByCoinbase[_coinbase];
            delete s_valCoinbases[valId];
        }
    }

    function _validatorCoinbase(uint64 valId) internal view returns (address) {
        return s_valCoinbases[valId];
    }

    function _getValidatorData(uint64 valId) internal view returns (ValidatorData memory) {
        ValidatorDataStorage memory _validatorData = s_validatorData[valId];
        address coinbase = s_valCoinbases[valId];
        return ValidatorData({
            epoch: _validatorData.epoch,
            id: valId,
            isPlaceholder: valId == UNKNOWN_VAL_ID,
            isActive: _validatorData.isActive,
            inActiveSet_Current: _validatorData.inActiveSet_Current,
            inActiveSet_Last: _validatorData.inActiveSet_Last,
            coinbase: coinbase
        });
    }

    // ================================================== //
    //             Coinbase Deployment Helpers            //
    // ================================================== //

    function _coinbaseSalt(uint64 validatorId) internal pure returns (bytes32) {
        // Domain-separated salt for safety across potential future CREATE2 usages.
        return keccak256(abi.encodePacked(COINBASE_SALT, validatorId));
    }

    function _coinbaseImmutableArgs(uint64 validatorId) internal view returns (bytes memory) {
        return abi.encodePacked(COINBASE_IMMUTABLE_ARGS_VERSION, validatorId, address(this));
    }

    function _predictCoinbaseAddress(uint64 validatorId) internal view returns (address) {
        require(s_coinbaseBeacon != address(0), CoinbaseBeaconNotInitialized());
        return LibClone.predictDeterministicAddressERC1967BeaconProxy(
            s_coinbaseBeacon, _coinbaseImmutableArgs(validatorId), _coinbaseSalt(validatorId), address(this)
        );
    }

    function _deployOrGetCoinbaseContractAddress(uint64 validatorId) internal returns (address coinbase) {
        (coinbase,) = _deployOrGetCoinbaseContractAddress(validatorId, address(0));
    }

    function _deployOrGetCoinbaseContractAddress(
        uint64 validatorId,
        address legacyCoinbase
    )
        internal
        returns (address coinbase, bool importedLegacyConfig)
    {
        require(s_coinbaseBeacon != address(0), CoinbaseBeaconNotInitialized());
        bytes32 salt = _coinbaseSalt(validatorId);
        (bool alreadyDeployed, address instance) = LibClone.createDeterministicERC1967BeaconProxy(
            s_coinbaseBeacon, _coinbaseImmutableArgs(validatorId), salt
        );
        coinbase = instance;
        require(coinbase != address(0), Create2Failed());

        if (!alreadyDeployed) {
            importedLegacyConfig = ICoinbase(coinbase).initialize(validatorId, legacyCoinbase);
        } else {
            importedLegacyConfig =
                CoinbaseUpgradeable(payable(coinbase)).resetForValidatorReuse(validatorId, legacyCoinbase);
        }
    }

    function _coinbaseImmutableArgsSchemaHash(address implementation) internal view returns (bytes32 schemaHash) {
        (bool success, bytes memory data) = implementation.staticcall(
            abi.encodeWithSelector(CoinbaseUpgradeable.coinbaseImmutableArgsSchemaHash.selector)
        );
        require(success && data.length == 32, IncompatibleCoinbaseImplementation(implementation));
        schemaHash = abi.decode(data, (bytes32));
    }

    function __CoinbaseBeacon_init() internal onlyInitializing {
        require(s_coinbaseBeacon == address(0), CoinbaseBeaconAlreadyInitialized());
        address implementation = address(new CoinbaseUpgradeable());
        s_coinbaseBeacon = address(new UpgradeableBeacon(implementation, address(this)));
        emit CoinbaseBeaconInitialized(s_coinbaseBeacon, implementation);
    }

    // ================================================== //
    //                   View Functions                   //
    // ================================================== //

    /// @custom:selector 0xd02611a5
    function getCoinbaseBeacon() external view returns (address beacon) {
        beacon = s_coinbaseBeacon;
    }

    /// @custom:selector 0xd77309a0
    function getCoinbaseBeaconImplementation() external view returns (address implementation) {
        if (s_coinbaseBeacon == address(0)) return address(0);
        implementation = UpgradeableBeacon(s_coinbaseBeacon).implementation();
    }

    /// @notice Returns the deterministic Coinbase address for a validator without deploying it.
    /// @dev Reverts for invalid placeholders to mirror addValidator checks.
    /// @custom:selector 0xa60232ad
    function previewCoinbaseAddress(uint64 validatorId) external view returns (address predicted) {
        require(validatorId != 0 && validatorId != UNKNOWN_VAL_ID, InvalidValidatorId(validatorId));
        predicted = _predictCoinbaseAddress(validatorId);
    }

    /// @custom:selector 0xd3b9fd72
    function getValidatorStats(uint64 validatorId) external view returns (ValidatorStats memory stats) {
        address coinbase = s_valCoinbases[validatorId];
        stats.isActive = s_validatorData[validatorId].isActive;
        require(stats.isActive || coinbase != address(0), InvalidValidatorId(validatorId));

        Epoch memory _validatorEpoch = validatorEpochPtr_N(-1, validatorId);
        PendingBoost memory _rewardsLast = validatorRewardsPtr_N(-1, validatorId);
        PendingBoost memory _rewardsCurrent = validatorRewardsPtr_N(0, validatorId);

        stats.coinbase = coinbase;
        stats.lastEpoch = _validatorEpoch.epoch;
        stats.targetStakeAmount = _validatorEpoch.targetStakeAmount;
        stats.rewardsPayableLast = _rewardsLast.rewardsPayable;
        stats.earnedRevenueLast = _rewardsLast.earnedRevenue;
        stats.rewardsPayableCurrent = _rewardsCurrent.rewardsPayable;
        stats.earnedRevenueCurrent = _rewardsCurrent.earnedRevenue;
    }

    /// @custom:selector 0x0e1e8f7d
    function isValidatorActive(uint64 validatorId) external view returns (bool) {
        return s_validatorIsActive[validatorId];
    }

    /// @notice Mirrors precompile epoch; startBlock not provided by precompile → returns 0.
    /// @custom:selector 0xa9fd1a8f
    function getEpochInfo() external returns (uint256 epochNumber, uint256 epochStartBlock) {
        (uint64 e,) = STAKING.getEpoch();
        return (uint256(e), 0);
    }

    /// @custom:selector 0x3bbc81d1
    function getValidatorCoinbase(uint256 validatorId) external view returns (address) {
        return _validatorCoinbase(validatorId.toUint64());
    }

    /// @custom:selector 0xc84fef9f
    function getValidatorIdForCoinbase(address coinbase) external view returns (uint256) {
        return s_valIdByCoinbase[coinbase];
    }

    /// @notice Returns detailed validator data (no structs) for a validatorId.
    /// @custom:selector 0x6c91b101
    function getValidatorData(uint64 validatorId)
        external
        view
        returns (
            uint64 epoch,
            uint64 id,
            bool isPlaceholder,
            bool isActive,
            bool inActiveSet_Current,
            bool inActiveSet_Last,
            address coinbase
        )
    {
        ValidatorData memory _validatorData = _getValidatorData(validatorId);
        return (
            _validatorData.epoch,
            _validatorData.id,
            _validatorData.isPlaceholder,
            _validatorData.isActive,
            _validatorData.inActiveSet_Current,
            _validatorData.inActiveSet_Last,
            _validatorData.coinbase
        );
    }

    /// @notice Returns the active validator set as parallel arrays of ids and coinbases.
    /// @custom:selector 0xd5dc7f75
    function listActiveValidators() external view returns (uint64[] memory validatorIds, address[] memory coinbases) {
        uint256 count = s_activeValidatorCount;
        validatorIds = new uint64[](count);
        coinbases = new address[](count);
        uint64 cursorId = s_valLinkNext[FIRST_VAL_ID];
        uint256 i;
        while (cursorId != LAST_VAL_ID && i < count) {
            if (cursorId != UNKNOWN_VAL_ID) {
                uint64 valId = cursorId;
                if (valId != 0 && s_validatorData[valId].isActive) {
                    validatorIds[i] = valId;
                    coinbases[i] = s_valCoinbases[valId];
                    unchecked {
                        ++i;
                    }
                }
            }
            cursorId = s_valLinkNext[cursorId];
        }
    }

    /// @notice Returns last and current epoch values for a validator.
    /// @custom:selector 0xaeefe59d
    function getValidatorEpochs(uint64 validatorId)
        external
        view
        returns (uint64 lastEpoch, uint128 lastTargetStakeAmount, uint64 currentEpoch, uint128 currentTargetStakeAmount)
    {
        Epoch memory _last = validatorEpochPtr_N(-1, validatorId);
        Epoch memory _current = validatorEpochPtr_N(0, validatorId);
        return (_last.epoch, _last.targetStakeAmount, _current.epoch, _current.targetStakeAmount);
    }

    /// @notice Returns last and current pending escrow values for a validator.
    /// @custom:selector 0x00601aaf
    function getValidatorPendingEscrow(uint64 validatorId)
        external
        view
        returns (
            uint120 lastPendingStaking,
            uint120 lastPendingUnstaking,
            uint120 currentPendingStaking,
            uint120 currentPendingUnstaking
        )
    {
        StakingEscrow memory _last = validatorPendingPtr_N(-1, validatorId);
        StakingEscrow memory _current = validatorPendingPtr_N(0, validatorId);
        return (_last.pendingStaking, _last.pendingUnstaking, _current.pendingStaking, _current.pendingUnstaking);
    }

    /// @notice Returns last and current rewards tracking for a validator.
    /// @custom:selector 0x0b4c7141
    function getValidatorRewards(uint64 validatorId)
        external
        view
        returns (
            uint120 lastRewardsPayable,
            uint120 lastEarnedRevenue,
            uint120 currentRewardsPayable,
            uint120 currentEarnedRevenue
        )
    {
        PendingBoost memory _last = validatorRewardsPtr_N(-1, validatorId);
        PendingBoost memory _current = validatorRewardsPtr_N(0, validatorId);
        return (_last.rewardsPayable, _last.earnedRevenue, _current.rewardsPayable, _current.earnedRevenue);
    }

    /// @notice Returns the split allocation signal for a validator and epoch pointer.
    /// @dev These buckets are additive to legacy `earnedRevenue`; they only drive weighted stake allocation and
    /// turnover routing, while legacy accounting continues to read the aggregate revenue fields. When
    /// `getIncludeIsolatedRewardsInStakeAllocation()` is enabled, validator-attributed isolated rewards are included
    /// in this signal even though pooled and isolated accounting remain separate elsewhere.
    /// @param validatorId Validator to inspect.
    /// @param epochPointer Epoch selector: -2=LastLast, -1=Last, 0=Current, 1=Next (others wrap modulo tracking).
    /// @return stakingYield Stake-allocation staking-yield signal attributed to the validator for the selected epoch.
    /// @return nonStakingRevenue Stake-allocation MEV / boost / donation signal attributed to the validator.
    /// @custom:selector 0x39c4322a
    function getValidatorAllocationRevenue(
        uint64 validatorId,
        int256 epochPointer
    )
        external
        view
        returns (uint120 stakingYield, uint120 nonStakingRevenue)
    {
        AllocationRevenue memory revenue = validatorAllocationRevenuePtr_N(epochPointer, validatorId);
        return (revenue.stakingYield, revenue.nonStakingRevenue);
    }

    /// @notice Returns the configured multiplier for non-staking revenue.
    /// @dev A zero storage value means the contract is using the default launch multiplier.
    /// @return multiplierRay Non-staking revenue multiplier in ray precision.
    /// @custom:selector 0x98aba375
    function getNonStakingRevenueMultiplierRay() public view returns (uint256 multiplierRay) {
        return StakeAllocationLib.defaultedNonStakingRevenueMultiplierRay(s_stakeAllocationConfig);
    }

    /// @notice Returns the configured staking-yield deadband for allocation scoring.
    /// @return deadbandBps Basis points of expected staking yield filtered from each validator's staking-yield signal.
    /// @custom:selector 0x38441898
    function getStakingYieldDeadbandBps() public view returns (uint16 deadbandBps) {
        return s_stakeAllocationConfig.stakingYieldDeadbandBps;
    }

    /// @notice Returns whether validator-attributed isolated rewards are included in stake-allocation signal buckets.
    /// @return include Whether the weighted allocation signal uses pooled-only rewards (`false`) or pooled+isolated
    /// validator-attributed rewards (`true`).
    /// @custom:selector 0x4fd80af9
    function getIncludeIsolatedRewardsInStakeAllocation() public view returns (bool include) {
        return s_stakeAllocationConfig.includeIsolatedRewardsInStakeAllocation;
    }

    /// @notice Returns crank linked-list neighbors for a validator (previous, next).
    /// @custom:selector 0x29067fef
    function getValidatorNeighbors(uint64 validatorId) external view returns (address previous, address next) {
        uint64 prevId = s_valLinkPrevious[validatorId];
        uint64 nextId = s_valLinkNext[validatorId];
        previous = (prevId == FIRST_VAL_ID || prevId == LAST_VAL_ID) ? address(0) : s_valCoinbases[prevId];
        next = (nextId == FIRST_VAL_ID || nextId == LAST_VAL_ID) ? address(0) : s_valCoinbases[nextId];
    }

    /// @notice Returns active validator count.
    /// @custom:selector 0x37deea70
    function getActiveValidatorCount() external view returns (uint256) {
        return s_activeValidatorCount;
    }

    /// @notice Returns next validator scheduled to crank.
    /// @custom:selector 0x44390e2f
    function getNextValidatorToCrank() external view returns (address) {
        // Start from the current cursor. If we're at the FIRST sentinel,
        // peek the first node after it (which may be UNKNOWN_VAL_ID).
        uint64 id = s_nextValidatorToCrank;
        if (id == FIRST_VAL_ID) id = s_valLinkNext[FIRST_VAL_ID];

        // By construction, UNKNOWN_VAL_ID is always immediately after FIRST_VAL_ID
        // and never appears elsewhere in the list. Skip it if encountered.
        if (id == UNKNOWN_VAL_ID) id = s_valLinkNext[UNKNOWN_VAL_ID];

        if (id == LAST_VAL_ID) return address(0);
        return s_valCoinbases[id];
    }

    /// @custom:selector 0x0cb9f3ad
    function STAKING_PRECOMPILE() public pure virtual override(FastLaneERC4626) returns (IMonadStaking);
    function _settleCoinbaseContract(uint64 valId, address coinbase) internal virtual;
}
