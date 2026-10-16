// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ActionType} from "../share/Enums.sol";

interface IExchangeConfig {
    // --- Events --- //

    /// @notice Emitted when a delegate depositor role for an account has been updated.
    event DelegateDepositorUpdated(address indexed account, bool granted);

    /// @notice Emitted when the Exchange fee collector details are updated.
    event FeeCollectorUpdated(address indexed account, bytes32 indexed subaccount);

    /// @notice Emitted when the delegate deposit max batch size is updated.
    event DelegateDepositMaxBatchSizeUpdated(uint16 delegateDepositMaxBatchSize);

    /// @notice Emitted when a fee schedule is added.
    event FeeScheduleAdded(uint32 indexed id);

    /// @notice Emitted when a fee schedule is updated.
    event FeeScheduleUpdated(uint32 indexed id);

    /// @notice Emitted when the Exchange liquidator details are updated.
    event LiquidatorUpdated(address indexed account, bytes32 indexed subaccount);

    /// @notice Emitted when the Emergency Pauser role is updated for an address.
    event EmergencyPauserUpdated(address indexed pauser, bool enabled);

    /// @notice Emitted when the PythLazer config data is updated.
    event PythLazerUpdated(address pythLazer, uint64 maxAge);

    /// @notice Emitted when the host chain LayerZero endpoint ID is updated.
    event LzEndpointIdUpdated(uint32 indexed lzEndpointId);

    /// @notice Emitted when a sequencer is added.
    event SequencerAdded(address indexed sequencer);

    /// @notice Emitted when a sequencer has their paused state set.
    event SequencerPausedUpdated(address indexed sequencer, bool paused);

    /// @notice Emitted when a sequencer is removed.
    event SequencerRemoved(address indexed sequencer);

    /// @notice Emitted when an action expiry buffer is updated.
    event ActionExpiryBufferUpdated(ActionType indexed action, uint64 buffer);

    /// @notice Emitted when a token is added.
    event TokenAdded(bytes32 indexed tokenName, address tokenAddress);

    /// @notice Emitted when an existing token is removed.
    event TokenRemoved(bytes32 indexed tokenName, address tokenAddress);

    /// @notice Emitted when an existing token is updated.
    event TokenUpdated(bytes32 indexed tokenName, address tokenAddress);

    /// @notice Emitted when a virtual token is promoted.
    event TokenPromoted(bytes32 indexed tokenName, address tokenAddress);

    /// @notice Emitted when the claimer has been updated.
    event ClaimerUpdated(address indexed claimer, bool granted);

    /// @notice Emitted when the rescue delay configuration is updated.
    event RescueDelayUpdated(uint64 rescueDelay);

    // --- Structs --- //

    struct AddFeeScheduleParams {
        /// Percentage fee charged to the maker side, in D9 precision.
        uint32 makerFee;
        /// Percentage fee charged to the taker side, in D9 precision.
        uint32 takerFee;
    }

    struct UpdateFeeScheduleParams {
        /// Id of the fee schedule
        uint32 id;
        /// Percentage fee charged to the maker side, in D9 precision.
        uint32 makerFee;
        /// Percentage fee charged to the taker side, in D9 precision.
        uint32 takerFee;
    }

    /// @dev Deposit and withdrawal settings only affect concrete tokens.
    struct UpdateTokenParams {
        /// Unique token name identifier
        bytes32 tokenName;
        /// Maximum active backed balance in D9, including pending deposits but excluding initiated withdrawals.
        uint256 depositCapacity;
        /// Minimum token amount per deposit, in D9 precision.
        uint256 minDeposit;
        /// Flat fee charged on each deposit, in D9 precision.
        uint128 depositFee;
        /// Flat fee charged on each withdrawal, in D9 precision.
        uint128 withdrawFee;
        /// Whether tokens can be deposited
        bool depositEnabled;
        /// Whether tokens can be withdrawn
        bool withdrawEnabled;
    }

    // --- Mutations --- //

    /// @notice Adds a new token.
    /// @param tokenName Name of token to add
    /// @param tokenAddress ERC20 address, synthetic accounting key, or zero for virtual tokens
    /// @param oftAddress Address of the OFT contract (or OFTAdapter)
    /// @param backingToken Address of the backing token (address(0) if not backed)
    /// @dev Once the USD_TOKEN_NAME has been added it cannot be removed if its used in a product.
    /// @dev tokenName is case sensitive which means USD and usd are treated differently.
    /// @dev Synthetic tokens use a non-ERC20 accounting address and cannot be deposited or withdrawn.
    function addToken(bytes32 tokenName, address tokenAddress, address oftAddress, address backingToken) external;

    /// @notice Updates an existing token with new params.
    /// @param params Token update parameters; all amount fields use D9 precision.
    function updateToken(UpdateTokenParams calldata params) external;

    /// @notice Promotes a virtual token to concrete by providing a new `tokenAddress`.
    /// @param tokenName Name of existing virtual token
    /// @param tokenAddress New token address to associate the virtual token against
    /// @param oftAddress Address of the OFT contract (or OFTAdapter)
    function promoteToken(bytes32 tokenName, address tokenAddress, address oftAddress) external;

    /// @notice Removes an existing token from set of exchange tokens.
    /// @param tokenName Name of the previously configured token to remove
    /// @notice This remove will revert if `token` is `usdToken` or if there is a balance > 0.
    function removeToken(bytes32 tokenName) external;

    /// @notice Adds a new sequencer to the approved mapping.
    /// @param account Address of the approved sequencer
    function addSequencer(address account) external;

    /// @notice Removes an existing sequencer from the approved mapping.
    /// @param account Address of the sequencer to remove
    function removeSequencer(address account) external;

    /// @notice Sets the paused state of a sequencer. Requests are only accepted from enabled sequencers.
    /// @param sequencer Address of the sequencer whose pause state is to be altered
    /// @param paused Whether the sequencer is paused
    function updateSequencerPaused(address sequencer, bool paused) external;

    /// @notice Updates the expiry time for a category of actions.
    /// @param action The category of action whose buffer will be updated
    /// @param buffer Amount of time after signing that an action is valid to execution, in seconds
    function updateActionExpiryBuffer(ActionType action, uint64 buffer) external;

    /// @notice Updates the details for the Exchange's fee collector.
    /// @param account Address that will accrue the Exchange fees
    /// @param subaccount Subaccount identifier for the address collecting the Exchange fees
    function updateFeeCollector(address account, bytes32 subaccount) external;

    /// @notice Updates a fee schedule.
    /// @param params Update fee schedule params
    function updateFeeSchedule(UpdateFeeScheduleParams calldata params) external;

    /// @notice Adds a new fee schedule.
    /// @param params Add new fee schedule params
    function addFeeSchedule(AddFeeScheduleParams calldata params) external returns (uint32);

    /// @notice Updates the details for the Exchange's liquidator account.
    /// @param account Address that accrues liquidated positions
    /// @param subaccount Subaccount identifier of the liquidator account
    function updateLiquidator(address account, bytes32 subaccount) external;

    /// @notice Updates the details for the PythLazer contract used for price verification.
    /// @param updatedContract Address of the PythLazer contract
    /// @param updatedMaxAge Maximum price age in seconds
    function updatePythLazer(address updatedContract, uint64 updatedMaxAge) external;

    /// @notice Updates the host chain LayerZero endpoint ID.
    /// @param updatedEndpointId Host chain LayerZero endpoint ID
    function updateLzEndpointId(uint32 updatedEndpointId) external;

    /// @notice Grants the delegate depositor role to an address.
    /// @param delegateDepositor who will be granted the role, reverts if role is currently granted
    function addDelegateDepositor(address delegateDepositor) external;

    /// @notice Removes the delegate depositor role from an address.
    /// @param delegateDepositor who will have their the role remove, reverts if role is not currently granted
    function removeDelegateDepositor(address delegateDepositor) external;

    /// @notice Updates the maximum number of deposits that a delegate depositor can make in a batch.
    /// @param delegateDepositMaxBatchSize maximum number of accounts that can passed into depositOnBehalf
    function updateDelegateDepositMaxBatchSize(uint16 delegateDepositMaxBatchSize) external;

    /// @notice Grants the emergency pauser role to an address.
    /// @param pauser that will be granted the role, reverting if role is currently granted
    function addEmergencyPauser(address pauser) external;

    /// @notice Remove the emergency pauser role from an address.
    /// @param pauser that will have their the role remove, reverting if role is not currently granted
    function removeEmergencyPauser(address pauser) external;

    /// @notice Grants the claimer role to an address.
    /// @param claimer who will be granted the role, reverts if role is currently granted
    function addClaimer(address claimer) external;

    /// @notice Revokes the claimer role from an address.
    /// @param claimer who will have their the role remove, reverts if role is not currently granted
    function removeClaimer(address claimer) external;

    /// @notice Updates the delay before funds can be rescued from a withdrawal.
    /// @param rescueDelay New delay in seconds
    function updateRescueDelay(uint64 rescueDelay) external;
}
