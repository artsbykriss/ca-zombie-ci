//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { SafeTransferLib } from "@solady/utils/SafeTransferLib.sol";
import { SafeCastLib } from "@solady/utils/SafeCastLib.sol";
import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";
import { LibClone } from "@solady/utils/LibClone.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { ICoinbase } from "./interfaces/ICoinbase.sol";
import { IShMonad } from "./interfaces/IShMonad.sol";
import {
    STAKING,
    MIN_VALIDATOR_DEPOSIT,
    MAX_EXTERNAL_REWARD,
    SCALE,
    TRANSFER_GAS_LIMIT,
    COINBASE_IMMUTABLE_ARGS_VERSION,
    STAKING_GAS_BUFFER,
    STAKING_GAS_EXTERNAL_REWARD,
    STAKING_GAS_GET_VALIDATOR
} from "./Constants.sol";

struct CoinbaseUpgradeableConfig {
    address commissionRecipient; // receives validator commission sent in `process()`
    uint96 priorityCommissionRate; // as a fraction of 1e18
    uint96 donationRate; // as a fraction of 1e18. donations count as validator revenue to shMON
    uint96 mevCommissionRate; // as a fraction of 1e18
    address authAddress; // last auth address synchronized from the staking precompile
}

struct CoinbaseUpgradeableUnpaidBalances {
    uint120 commission;
    uint120 rewards;
    bool alwaysTrue;
}

contract CoinbaseUpgradeable is ICoinbase, ReentrancyGuardTransient, Initializable {
    using SafeTransferLib for address;
    using SafeCastLib for uint256;

    uint256 internal constant IMMUTABLE_ARGS_LENGTH = 29;
    uint256 internal constant IMMUTABLE_ARGS_VERSION_SHIFT = 248;
    uint256 internal constant IMMUTABLE_ARGS_VALIDATOR_ID_SHIFT = 184;
    uint256 internal constant IMMUTABLE_ARGS_SHMONAD_SHIFT = 24;
    bytes32 public constant COINBASE_IMMUTABLE_ARGS_SCHEMA_HASH =
        keccak256("fastlane.shmonad.coinbase.cwia.v1:uint8 version,uint64 valId,address shMonad");

    // Storage layout for beacon upgrades is append-only. Do not reorder these fields or insert new storage above
    // them. The immutable-args schema hash only validates the CWIA code layout, not the proxy storage layout.
    CoinbaseUpgradeableConfig internal s_config;
    CoinbaseUpgradeableUnpaidBalances internal s_unpaid;

    /// @custom:selector 0x688065ed
    error OnlyShMonadCaller();
    /// @custom:selector 0x9bfdc6ff
    error OnlyAuthAddress();
    /// @custom:selector 0x8e238934
    error OnlySelfCaller();
    /// @custom:selector 0x8fe552e0
    error InvalidCommissionRate();
    /// @custom:selector 0x57471710
    error InvalidDonationRate();
    /// @custom:selector 0x0721e756
    error AuthAddressNotChanged();
    /// @custom:selector 0xd48c2547
    error RewardFailed();
    /// @custom:selector 0xd8707052
    error RecipientCannotBeZeroAddress();
    /// @custom:selector 0x19708e71
    error ValidatorNotFoundInPrecompile(uint64 validatorId);
    /// @custom:selector 0x193baad9
    error MEVMustExceedZero();
    /// @custom:selector 0x1452c8de
    error NoUnpaidRewards();
    /// @custom:selector 0x3d9da074
    error ValidatorStillRewardable(uint64 validatorId);
    /// @custom:selector 0x43862c9a
    error CoinbaseImmutableArgsLengthMismatch(uint256 actualLength);
    /// @custom:selector 0x3bc3a56f
    error CoinbaseImmutableArgsVersionMismatch(uint256 actualVersion);
    /// @custom:selector 0x9275468d
    error CoinbaseInitializerValidatorIdMismatch(uint64 expected, uint64 actual);
    /// @custom:selector 0xdc7be97f
    error CoinbaseReuseRequiresZeroBalance(uint256 balance);

    /// @custom:selector 0x36914845
    event PriorityCommissionRateUpdated(uint256 oldCommissionRate, uint256 newCommissionRate);
    /// @custom:selector 0xd2bbd200
    event MEVCommissionRateUpdated(uint256 oldCommissionRate, uint256 newCommissionRate);

    /// @custom:selector 0x8013f423
    event DonationRateUpdated(uint256 oldDonationRate, uint256 newDonationRate);
    /// @custom:selector 0x2c40de6e
    event CommissionRecipientUpdated(address oldRecipient, address newRecipient);
    /// @custom:selector 0xc0bb63ce
    event AuthAddressUpdated(address oldAuthAddress, address newAuthAddress);
    /// @custom:selector 0xab1f5903
    event MEVReceived(uint256 grossAmount, uint256 commission, uint256 rewards);
    /// @custom:selector 0xbb2aed38
    event CoinbaseSettled(
        uint256 priorityFees,
        uint256 priorityCommission,
        uint256 priorityDonation,
        uint256 priorityStakers,
        uint256 totalRewardsPaid,
        uint256 totalCommissionPaid,
        uint256 totalDonationPaid,
        uint256 unpaidRewards,
        uint256 unpaidCommission
    );
    /// @custom:selector 0x98445015
    event UnpaidRewardsDonated(uint64 indexed validatorId, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the proxy coinbase for a validator.
    /// @dev Called once by ShMonad immediately after deterministic deployment.
    /// @param valId The validator ID encoded into this proxy's immutable args.
    /// @param legacyCoinbase The legacy coinbase to read operational config from, or `address(0)` for fresh validators.
    /// @return legacyConfigMigrated True if readable legacy config was migrated, otherwise uses precompile defaults.
    /// @custom:selector 0xd7eecc7e
    function initialize(uint64 valId, address legacyCoinbase) external initializer returns (bool legacyConfigMigrated) {
        (uint64 _valId, address _shMonad) = _immutableIdentity();
        require(msg.sender == _shMonad, OnlyShMonadCaller());
        require(valId == _valId, CoinbaseInitializerValidatorIdMismatch(_valId, valId));

        CoinbaseUpgradeableConfig memory _config;
        (_config, legacyConfigMigrated) = _initialConfig(_valId, legacyCoinbase);

        s_config = _config;
        s_unpaid.alwaysTrue = true;

        emit PriorityCommissionRateUpdated(0, _config.priorityCommissionRate);
        emit MEVCommissionRateUpdated(0, _config.mevCommissionRate);
        if (_config.donationRate != 0) emit DonationRateUpdated(0, _config.donationRate);
        emit CommissionRecipientUpdated(address(0), _config.commissionRecipient);
    }

    /// @notice Resets lifecycle-local config when ShMonad reuses an existing deterministic proxy.
    /// @dev Old MON must be settled or recovered before reuse; otherwise it could be re-split under new settings.
    /// @param valId The validator ID encoded into this proxy's immutable args.
    /// @param legacyCoinbase The legacy coinbase to read operational config from, or `address(0)` for fresh re-adds.
    /// @return legacyConfigMigrated True if readable legacy config was migrated, otherwise uses precompile defaults.
    /// @custom:selector 0x0d1755d9
    function resetForValidatorReuse(
        uint64 valId,
        address legacyCoinbase
    )
        external
        onlyShMonad
        returns (bool legacyConfigMigrated)
    {
        (uint64 _valId,) = _immutableIdentity();
        require(valId == _valId, CoinbaseInitializerValidatorIdMismatch(_valId, valId));

        uint256 _balance = address(this).balance;
        require(_balance == 0, CoinbaseReuseRequiresZeroBalance(_balance));

        CoinbaseUpgradeableConfig memory _oldConfig = s_config;
        CoinbaseUpgradeableConfig memory _newConfig;
        (_newConfig, legacyConfigMigrated) = _initialConfig(_valId, legacyCoinbase);

        s_config = _newConfig;
        s_unpaid = CoinbaseUpgradeableUnpaidBalances({ commission: 0, rewards: 0, alwaysTrue: true });

        emit PriorityCommissionRateUpdated(_oldConfig.priorityCommissionRate, _newConfig.priorityCommissionRate);
        emit MEVCommissionRateUpdated(_oldConfig.mevCommissionRate, _newConfig.mevCommissionRate);
        if (_oldConfig.donationRate != _newConfig.donationRate) {
            emit DonationRateUpdated(_oldConfig.donationRate, _newConfig.donationRate);
        }
        emit CommissionRecipientUpdated(_oldConfig.commissionRecipient, _newConfig.commissionRecipient);
        if (_oldConfig.authAddress != _newConfig.authAddress) {
            emit AuthAddressUpdated(_oldConfig.authAddress, _newConfig.authAddress);
        }
    }

    /// @notice Accepts MON forwarded to this coinbase instance.
    receive() external payable { }

    /// @notice Returns the validator id bound to this proxy via immutable args.
    /// @return The validator id for this coinbase.
    /// @custom:selector 0x7f4e7d7b
    function VAL_ID() external view returns (uint64) {
        (uint64 valId,) = _immutableIdentity();
        return valId;
    }

    /// @notice Returns the ShMonad proxy that owns this coinbase.
    /// @return The ShMonad address encoded into this proxy's immutable args.
    /// @custom:selector 0xae61ebe9
    function SHMONAD() external view returns (address) {
        (, address shMonad) = _immutableIdentity();
        return shMonad;
    }

    /// @notice Returns this coinbase proxy's own address.
    /// @return The current proxy address.
    /// @custom:selector 0x26bd0c4e
    function SELF() external view returns (address) {
        return address(this);
    }

    modifier onlyAuthAddress() {
        // The cached auth address is informational; validator key rotations take effect from live staking state.
        (uint64 valId,) = _immutableIdentity();
        (address authAddress,) = _getValidator(valId);
        require(msg.sender == authAddress, OnlyAuthAddress());
        _;
    }

    modifier onlyShMonad() {
        (, address shMonad) = _immutableIdentity();
        require(msg.sender == shMonad, OnlyShMonadCaller());
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), OnlySelfCaller());
        _;
    }

    /// @notice Records MEV sent from ShMonad and splits it into validator commission and delegate rewards.
    /// @dev The resulting balances are queued into unpaid buffers until `process()` settles them.
    /// @dev ShMonad does not snapshot the coinbase MEV rate when it creates `rewardsPayable`;
    /// this function applies the live settlement-time rate.
    /// @custom:selector 0xbeac7323
    function handleMEVPayable() external payable onlyShMonad nonReentrant {
        require(msg.value > 0, MEVMustExceedZero());

        uint256 _grossMEV = msg.value;
        uint256 _mevCommissionRate = s_config.mevCommissionRate;

        uint256 _mevCommissionToValidator = _grossMEV * _mevCommissionRate / SCALE;
        uint256 _netMEV = _grossMEV - _mevCommissionToValidator;

        CoinbaseUpgradeableUnpaidBalances memory _unpaid = s_unpaid;
        _unpaid.commission += _mevCommissionToValidator.toUint120();
        _unpaid.rewards += _netMEV.toUint120();
        s_unpaid = _unpaid;

        emit MEVReceived(_grossMEV, _mevCommissionToValidator, _netMEV);
    }

    /// @notice Settles the coinbase's current MON balance into rewards, validator commission, and donation.
    /// @dev Rewards and validator commission are tracked in unpaid buffers on partial failure. Donation is
    /// best-effort only: if the ShMonad transfer fails, the MON remains in this contract's raw balance and is
    /// re-split by the next `process()` call rather than being tracked as dedicated unpaid donation debt.
    /// @dev This is called during `_crankValidator()` in ShMonad, so it should return `false` instead of reverting.
    /// @return success True when all intended payouts succeeded in this settlement pass.
    /// @custom:selector 0xc33fb877
    function process() external onlyShMonad nonReentrant returns (bool success) {
        // Strategy:
        // 1) Split current balance (excluding previously unpaid) into commission, donation, rewards.
        // 2) Cap rewards to a single externalReward call under the precompile limit; store remainder as unpaid.
        // 3) Attempt rewards and commission/donation independently; record unpaid on failure.
        CoinbaseUpgradeableConfig memory _config = s_config;
        CoinbaseUpgradeableUnpaidBalances memory _unpaid = s_unpaid;
        uint256 _unpaidCommission = _unpaid.commission;
        uint256 _unpaidRewards = _unpaid.rewards;
        bool _updateCoinbaseUpgradeableUnpaidBalances = false;

        // All balances other than previously unpaid rewards are accrued priority fees
        uint256 _currentBalance = address(this).balance;
        // Allow exact-paydown of arrears without requiring extra headroom.
        uint256 _arrearsTotal = _unpaidCommission + _unpaidRewards;
        if (_currentBalance < _arrearsTotal) return false;
        if (_currentBalance == 0) return false;
        if (_config.priorityCommissionRate + _config.donationRate > SCALE) return false;
        _currentBalance -= _arrearsTotal;

        // Calculate the commission
        uint256 _priorityCommission = (_currentBalance * _config.priorityCommissionRate / SCALE);
        uint256 _shMonadDonation = _currentBalance * _config.donationRate / SCALE;
        uint256 _priorityStakers = _currentBalance - _priorityCommission - _shMonadDonation;

        uint256 _validatorCommission = _priorityCommission;
        uint256 _rewardPortion = _priorityStakers;

        _validatorCommission += _unpaidCommission;
        _rewardPortion += _unpaidRewards;

        // Compute reward payout cap upfront (single externalReward call)
        bool _canPayRewards = _rewardPortion >= MIN_VALIDATOR_DEPOSIT;
        uint256 _rewardPayout;
        uint256 _rewardRemainder;
        if (_canPayRewards) {
            // stay 1 MON below the externalReward hard limit to avoid reverts
            _rewardPayout = Math.min(MAX_EXTERNAL_REWARD - 1e18, _rewardPortion);
            _rewardRemainder = _rewardPortion - _rewardPayout;
        }

        // Attempt rewards (single call, capped) and commission/donation independently. Only rewards and validator
        // commission are tracked as unpaid on failure; donation is best-effort and remains as raw balance.
        bool _rewardsSucceeded = false;
        if (_canPayRewards) {
            try this.sendRewardsToDelegates(_rewardPayout) {
                _rewardsSucceeded = true;
                _unpaidRewards = _rewardRemainder.toUint120();
                if (_unpaidRewards > 0 || _unpaid.rewards > 0) _updateCoinbaseUpgradeableUnpaidBalances = true;
            } catch {
                _unpaidRewards = _rewardPortion.toUint120();
                _updateCoinbaseUpgradeableUnpaidBalances = true;
            }
        } else {
            // Not enough to pay out; record and keep success=false for rewards.
            _unpaidRewards = _rewardPortion.toUint120();
            if (_unpaidRewards > _unpaid.rewards) _updateCoinbaseUpgradeableUnpaidBalances = true;
        }

        bool _commissionSucceeded = true;
        bool _donationSucceeded = true;
        if (_validatorCommission > 0 || _shMonadDonation > 0) {
            try this.sendCommissionAndDonation(
                _config.commissionRecipient, _validatorCommission, _shMonadDonation
            ) returns (
                bool commissionSucceeded, bool donationSucceeded
            ) {
                _commissionSucceeded = commissionSucceeded;
                _donationSucceeded = donationSucceeded;
            } catch {
                _commissionSucceeded = false;
                _donationSucceeded = false;
            }

            if (_commissionSucceeded) {
                if (_unpaidCommission > 0) {
                    _unpaidCommission = 0;
                    _updateCoinbaseUpgradeableUnpaidBalances = true;
                }
            } else {
                if (_validatorCommission > _unpaidCommission) {
                    _unpaidCommission = _validatorCommission;
                    _updateCoinbaseUpgradeableUnpaidBalances = true;
                }
            }
        }

        // Success only if all intended payouts succeeded. Rewards and validator commission use unpaid buffers;
        // failed donations are left in the coinbase balance and retried implicitly via the next split.
        success = _rewardsSucceeded && _commissionSucceeded && _donationSucceeded;

        if (_updateCoinbaseUpgradeableUnpaidBalances) {
            s_unpaid = CoinbaseUpgradeableUnpaidBalances({
                commission: _unpaidCommission.toUint120(), rewards: _unpaidRewards.toUint120(), alwaysTrue: true
            });
        }

        emit CoinbaseSettled(
            _currentBalance,
            _priorityCommission,
            _shMonadDonation,
            _priorityStakers,
            _rewardsSucceeded ? _rewardPayout : 0,
            _commissionSucceeded ? _validatorCommission : 0,
            _donationSucceeded ? _shMonadDonation : 0,
            _unpaidRewards,
            _unpaidCommission
        );
    }

    /// @notice Sends a capped reward amount to the staking precompile for this validator.
    /// @dev Only callable by this contract during `process()`.
    /// @param rewardPortion The reward amount to forward to the staking precompile.
    /// @custom:selector 0x97751992
    function sendRewardsToDelegates(uint256 rewardPortion) external onlySelf {
        (uint64 valId,) = _immutableIdentity();
        bool _sendRewardsSucceeded = _sendRewards(valId, rewardPortion);
        require(_sendRewardsSucceeded, RewardFailed());
    }

    /// @notice Pays validator commission to the configured recipient and donation to ShMonad.
    /// @dev Only callable by this contract during `process()`. Transfer failures are reported via return values.
    /// Failed donations are intentionally not stored as separate unpaid debt; the balance remains on the coinbase
    /// and is re-processed on the next `process()` call.
    /// @param commissionRecipient The address that should receive validator commission.
    /// @param validatorCommission The validator commission amount to transfer.
    /// @param shMonadDonation The donation amount to transfer to ShMonad.
    /// @return commissionSucceeded True if the commission transfer succeeded.
    /// @return donationSucceeded True if the donation transfer succeeded.
    /// @custom:selector 0x5f69d439
    function sendCommissionAndDonation(
        address commissionRecipient,
        uint256 validatorCommission,
        uint256 shMonadDonation
    )
        external
        onlySelf
        returns (bool commissionSucceeded, bool donationSucceeded)
    {
        // Send commission to recipient and donation to shMonad (where it counts as revenue).
        // Transfers are independent; failures are reported via return values for unpaid tracking.
        commissionSucceeded = true;
        donationSucceeded = true;
        if (validatorCommission > 0) {
            commissionSucceeded = commissionRecipient.trySafeTransferETH(validatorCommission, TRANSFER_GAS_LIMIT);
        }
        if (shMonadDonation > 0) {
            (, address shMonad) = _immutableIdentity();
            donationSucceeded = shMonad.trySafeTransferETH(shMonadDonation, TRANSFER_GAS_LIMIT);
        }
    }

    /// @notice Donates unpaid delegate rewards once this validator leaves the current and upcoming reward sets.
    /// @dev Only the delegate reward buffer is donated; validator commission remains claimable by the configured
    /// recipient through `process()`.
    /// @custom:selector 0xb1c20be4
    function donateUnpaidRewardsToShMonad() external nonReentrant returns (uint256 donatedAmount) {
        (uint64 _valId, address _shMonad) = _immutableIdentity();
        require(!_canReceiveExternalReward(_valId), ValidatorStillRewardable(_valId));

        donatedAmount = s_unpaid.rewards;
        require(donatedAmount > 0, NoUnpaidRewards());

        s_unpaid.rewards = 0;

        // Recovered delegate rewards are pooled yield, but should not charge boost commission or affect allocation
        // attribution. ShMonad records them through a dedicated smoothing hook instead of generic goodwill receive.
        IShMonad(_shMonad).donateRecoveredCoinbaseRewards{ value: donatedAmount }(_valId);
        emit UnpaidRewardsDonated(_valId, donatedAmount);
    }

    /// @notice Refreshes the cached auth address from the staking precompile.
    /// @dev Either the old auth or the newly effective auth may call this during rotation.
    /// @custom:selector 0x8982e4ee
    function updateAuthAddress() external {
        address _previousAuthAddress = s_config.authAddress;
        (uint64 valId,) = _immutableIdentity();
        (address _newAuthAddress,) = _getValidator(valId);

        require(msg.sender == _previousAuthAddress || msg.sender == _newAuthAddress, OnlyAuthAddress());
        require(_previousAuthAddress != _newAuthAddress, AuthAddressNotChanged());

        s_config.authAddress = _newAuthAddress;

        emit AuthAddressUpdated(_previousAuthAddress, _newAuthAddress);
    }

    /// @notice Updates the priority-fee commission rate charged by this coinbase.
    /// @param newCommissionRate The new priority commission rate, scaled by `1e18`.
    /// @custom:selector 0x33c2c2c1
    function updatePriorityCommissionRate(uint256 newCommissionRate) external onlyAuthAddress {
        // donation + commission cannot exceed 100%
        uint256 _oldDonationRate = s_config.donationRate;
        require(newCommissionRate + _oldDonationRate <= SCALE, InvalidCommissionRate());

        uint256 _oldCommissionRate = s_config.priorityCommissionRate;
        s_config.priorityCommissionRate = newCommissionRate.toUint96();

        emit PriorityCommissionRateUpdated(_oldCommissionRate, newCommissionRate);
    }

    /// @notice Updates the MEV commission rate charged by this coinbase.
    /// @param newCommissionRate The new MEV commission rate, scaled by `1e18`.
    /// @custom:selector 0xcaefb7df
    function updateMEVCommissionRate(uint256 newCommissionRate) external onlyAuthAddress {
        // commission cannot exceed 100%
        require(newCommissionRate <= SCALE, InvalidCommissionRate());

        uint256 _oldCommissionRate = s_config.mevCommissionRate;
        s_config.mevCommissionRate = newCommissionRate.toUint96();

        emit MEVCommissionRateUpdated(_oldCommissionRate, newCommissionRate);
    }

    /// @notice Updates the share of priority fees donated back to ShMonad.
    /// @param newDonationRate The new donation rate, scaled by `1e18`.
    /// @custom:selector 0x1056c7fe
    function updateShMonadDonationRate(uint256 newDonationRate) external onlyAuthAddress {
        // donation + commission cannot exceed 100%
        uint256 _oldCommissionRate = s_config.priorityCommissionRate;
        require(_oldCommissionRate + newDonationRate <= SCALE, InvalidDonationRate());

        uint256 _oldDonationRate = s_config.donationRate;
        s_config.donationRate = newDonationRate.toUint96();

        emit DonationRateUpdated(_oldDonationRate, newDonationRate);
    }

    /// @notice Syncs the priority and MEV commission rates from the staking precompile.
    /// @dev If the refreshed commission rate would push commission plus donation above `100%`, donation is clamped
    /// down. @custom:selector 0x6f7cbce4
    function updateCommissionRateFromStakingConfig() external onlyAuthAddress {
        (uint64 valId,) = _immutableIdentity();
        (, uint256 _newCommissionRate) = _getValidator(valId);
        require(_newCommissionRate <= SCALE, InvalidCommissionRate());

        uint256 _oldCommissionRate = s_config.priorityCommissionRate;
        uint256 _oldMEVCommissionRate = s_config.mevCommissionRate;
        uint256 _oldDonationRate = s_config.donationRate;
        uint256 _newDonationRate = _oldDonationRate;

        // If new commission rate + old donation rate > SCALE, adjust donation rate downwards
        if (_newCommissionRate + _oldDonationRate > SCALE) {
            _newDonationRate = SCALE - _newCommissionRate;
        }

        s_config.priorityCommissionRate = _newCommissionRate.toUint96();
        s_config.mevCommissionRate = _newCommissionRate.toUint96();

        if (_newDonationRate != _oldDonationRate) {
            s_config.donationRate = _newDonationRate.toUint96();
            emit DonationRateUpdated(_oldDonationRate, _newDonationRate);
        }

        emit PriorityCommissionRateUpdated(_oldCommissionRate, _newCommissionRate);
        emit MEVCommissionRateUpdated(_oldMEVCommissionRate, _newCommissionRate);
    }

    /// @notice Updates the address that receives validator commission.
    /// @param newRecipient The new validator commission recipient.
    /// @custom:selector 0x3f3b061a
    function updateCommissionRecipient(address newRecipient) external onlyAuthAddress {
        require(newRecipient != address(0), RecipientCannotBeZeroAddress());
        address _oldRecipient = s_config.commissionRecipient;
        s_config.commissionRecipient = newRecipient;

        emit CommissionRecipientUpdated(_oldRecipient, newRecipient);
    }

    /// @notice Returns the current priority-fee commission rate.
    /// @return The priority commission rate scaled by `1e18`.
    /// @custom:selector 0x15f6194e
    function getPriorityCommissionRate() external view returns (uint256) {
        return s_config.priorityCommissionRate;
    }

    /// @notice Returns the current MEV commission rate.
    /// @return The MEV commission rate scaled by `1e18`.
    /// @custom:selector 0x9afefbbd
    function getMEVCommissionRate() external view returns (uint256) {
        return s_config.mevCommissionRate;
    }

    /// @notice Returns the current donation rate paid to ShMonad.
    /// @return The donation rate scaled by `1e18`.
    /// @custom:selector 0x4890f108
    function getShMonadDonationRate() external view returns (uint256) {
        return s_config.donationRate;
    }

    /// @notice Returns the current validator commission recipient.
    /// @return The address that receives validator commission payouts.
    /// @custom:selector 0x9b296734
    function getCommissionRecipient() external view returns (address) {
        return s_config.commissionRecipient;
    }

    /// @notice Returns reward and commission amounts that could not yet be paid out.
    /// @return commission The unpaid validator commission balance.
    /// @return rewards The unpaid delegate rewards balance.
    /// @custom:selector 0x7c827bc2
    function getUnpaidBalances() external view returns (uint256 commission, uint256 rewards) {
        CoinbaseUpgradeableUnpaidBalances memory _unpaid = s_unpaid;
        return (_unpaid.commission, _unpaid.rewards);
    }

    /// @notice Returns the last validator auth address synchronized into this coinbase's config.
    /// @dev Auth-gated updates always check the live staking precompile instead of this cache.
    /// @return The cached auth address.
    /// @custom:selector 0x7c359fe0
    function AUTH_ADDRESS() external view returns (address) {
        return s_config.authAddress;
    }

    /// @notice Returns the immutable-args schema hash required for safe beacon upgrades.
    /// @return The schema hash expected by this coinbase implementation family.
    /// @custom:selector 0xb17f12f8
    function coinbaseImmutableArgsSchemaHash() external pure virtual returns (bytes32) {
        return COINBASE_IMMUTABLE_ARGS_SCHEMA_HASH;
    }

    function _immutableIdentity() internal view returns (uint64 valId, address shMonad) {
        // Immutable args are appended to this proxy's runtime code by Solady's LibClone when first deployed.
        // See `ValidatorRegistry._deployOrGetCoinbaseContractAddress()` for more context.
        bytes memory args = LibClone.argsOnERC1967BeaconProxy(address(this));
        require(args.length == IMMUTABLE_ARGS_LENGTH, CoinbaseImmutableArgsLengthMismatch(args.length));

        uint256 raw;
        assembly ("memory-safe") {
            // Load the first 32-byte word of args into `raw`.
            // Layout in the high-order bytes of `raw` (big-endian within this word):
            // Layout of `raw` (big-endian) => 29 bytes:
            // | ------- | ------------- | --------------------- |
            // | VERSION |     VAL_ID    |        SHMONAD        |
            // | ------- | ------------- | --------------------- |
            // | 1 byte  |     8 bytes   |        20 bytes       |
            // | ------- | ------------- | --------------------- |
            raw := mload(add(args, 0x20))
        }

        uint256 version = raw >> IMMUTABLE_ARGS_VERSION_SHIFT;
        require(version == COINBASE_IMMUTABLE_ARGS_VERSION, CoinbaseImmutableArgsVersionMismatch(version));

        valId = uint64(raw >> IMMUTABLE_ARGS_VALIDATOR_ID_SHIFT);
        shMonad = address(uint160(raw >> IMMUTABLE_ARGS_SHMONAD_SHIFT));
    }

    function _legacyOperationalConfigOrDefault(
        address legacyCoinbase,
        uint64 expectedValId,
        CoinbaseUpgradeableConfig memory defaultConfig
    )
        internal
        view
        returns (CoinbaseUpgradeableConfig memory config, bool imported)
    {
        // Migration of legacy Coinbase settings:
        // - checks validator ID matches the target legacy Coinbase tracked by ShMonad
        // - reads legacy recipient, priority rate, MEV rate, and donation rate
        // - if any of those legacy reads fail, falls back to standard Coinbase defaults
        // - auth address is NOT migrated from legacy coinbase; it always comes from the staking precompile

        config = defaultConfig;
        uint64 _legacyValId;
        address _legacyRecipient;
        uint256 _legacyPriorityRate;
        uint256 _legacyMevRate;
        uint256 _legacyDonationRate;

        try ICoinbase(legacyCoinbase).VAL_ID() returns (uint64 valId) {
            _legacyValId = valId;
        } catch {
            return (config, false);
        }

        if (_legacyValId != expectedValId) return (config, false);

        try ICoinbase(legacyCoinbase).getCommissionRecipient() returns (address commissionRecipient) {
            _legacyRecipient = commissionRecipient;
        } catch {
            return (config, false);
        }

        try ICoinbase(legacyCoinbase).getPriorityCommissionRate() returns (uint256 priorityRate) {
            _legacyPriorityRate = priorityRate;
        } catch {
            return (config, false);
        }

        try ICoinbase(legacyCoinbase).getMEVCommissionRate() returns (uint256 mevRate) {
            _legacyMevRate = mevRate;
        } catch {
            return (config, false);
        }

        try ICoinbase(legacyCoinbase).getShMonadDonationRate() returns (uint256 donationRate) {
            _legacyDonationRate = donationRate;
        } catch {
            return (config, false);
        }

        if (_legacyRecipient == address(0)) return (config, false);
        if (_legacyPriorityRate > SCALE || _legacyMevRate > SCALE || _legacyPriorityRate + _legacyDonationRate > SCALE)
        {
            return (config, false);
        }

        config.commissionRecipient = _legacyRecipient;
        config.priorityCommissionRate = _legacyPriorityRate.toUint96();
        config.mevCommissionRate = _legacyMevRate.toUint96();
        config.donationRate = _legacyDonationRate.toUint96();
        imported = true;
    }

    function _initialConfig(
        uint64 valId,
        address legacyCoinbase
    )
        internal
        returns (CoinbaseUpgradeableConfig memory config, bool legacyConfigMigrated)
    {
        (address _authAddress, uint256 _commissionRate) = _getValidator(valId);

        // Optional legacy migration may override operational knobs, but auth always comes from the live precompile.
        CoinbaseUpgradeableConfig memory _defaultConfig = CoinbaseUpgradeableConfig({
            commissionRecipient: _authAddress,
            priorityCommissionRate: _commissionRate.toUint96(),
            donationRate: 0,
            mevCommissionRate: _commissionRate.toUint96(),
            authAddress: _authAddress
        });

        config = _defaultConfig;
        if (legacyCoinbase != address(0)) {
            (config, legacyConfigMigrated) = _legacyOperationalConfigOrDefault(legacyCoinbase, valId, _defaultConfig);
        }
    }

    function _inEpochDelayPeriod() internal returns (bool) {
        (, bool _isInEpochDelayPeriod) = STAKING.getEpoch();
        return _isInEpochDelayPeriod;
    }

    function _sendRewards(uint64 validatorId, uint256 rewardAmount) internal returns (bool) {
        try STAKING.externalReward{ value: rewardAmount, gas: STAKING_GAS_EXTERNAL_REWARD + STAKING_GAS_BUFFER }(
            validatorId
        ) returns (
            bool _precompileSuccess
        ) {
            return _precompileSuccess;
        } catch {
            return false;
        }
    }

    function _canReceiveExternalReward(uint64 validatorId) internal returns (bool) {
        bool _inDelayPeriod;
        try STAKING.getEpoch() returns (uint64, bool inEpochDelayPeriod) {
            _inDelayPeriod = inEpochDelayPeriod;
        } catch {
            // If the epoch phase is unavailable, block donation rather than guessing the reward basis.
            return true;
        }

        // During the delay, snapshot stake is rewardable now while consensus stake identifies the upcoming set.
        // Outside the delay, only consensus stake is current; a stale snapshot must not block recovery.
        try STAKING.getValidator{ gas: STAKING_GAS_GET_VALIDATOR + STAKING_GAS_BUFFER }(validatorId) returns (
            address,
            uint64,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256 consensusStake,
            uint256,
            uint256 snapshotStake,
            uint256,
            bytes memory,
            bytes memory
        ) {
            return consensusStake > 0 || (_inDelayPeriod && snapshotStake > 0);
        } catch {
            // An unreadable validator view is not proof that its rewards are abandoned.
            return true;
        }
    }

    function _getValidator(uint64 validatorId) internal returns (address authAddress, uint256 commissionRate) {
        try STAKING.getValidator{ gas: STAKING_GAS_GET_VALIDATOR + STAKING_GAS_BUFFER }(validatorId) returns (
            address _authAddress,
            uint64,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256 _consensusCommissionRate,
            uint256,
            uint256 _snapshotCommissionRate,
            bytes memory,
            bytes memory
        ) {
            authAddress = _authAddress;
            commissionRate = _inEpochDelayPeriod() ? _snapshotCommissionRate : _consensusCommissionRate;
        } catch { }
        require(authAddress != address(0), ValidatorNotFoundInPrecompile(validatorId));
    }
}
