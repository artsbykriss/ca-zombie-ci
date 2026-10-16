// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IPerpEngine} from "../interface/IPerpEngine.sol";
import {Deposit} from "../lib/storage/Deposit.sol";
import {FeeSchedule} from "../lib/storage/FeeSchedule.sol";
import {PerpPosition} from "../lib/storage/PerpPosition.sol";
import {PerpProduct} from "../lib/storage/PerpProduct.sol";
import {Token} from "../lib/storage/Token.sol";
import {Withdraw} from "../lib/storage/Withdraw.sol";
import {ActionType, EngineType} from "../share/Enums.sol";

interface IExchangeGateway {
    // --- Events --- //

    /// @notice Emitted when the exchange pause status has transitioned state.
    event ExchangePauseUpdated(address indexed account, bool isPaused);

    /// @notice Emitted when a public indexer ping is recorded.
    /// @dev This is a permissionless offchain indexing aid, not an authenticated liveness signal.
    event Ping(address indexed sender, uint64 timestamp);

    /// @notice Emitted when a fee has been credited to a collector, but is yet to be transferred.
    event FeeAccrued(
        address indexed account,
        bytes32 indexed subaccount,
        address token,
        uint256 feeAmount,
        uint256 balance,
        uint64 messageIdx
    );

    /// @notice Emitted when a subaccount's position is transferred to another subaccount
    event PositionTransferred(
        uint32 indexed productId,
        EngineType indexed engineType,
        address accountFrom,
        bytes32 subaccountFrom,
        address accountTo,
        bytes32 subaccountTo,
        int128 amount
    );

    /// @notice Emitted when an address registry record is updated.
    event RegistryRecordUpdated(bytes32 indexed name, address indexed record);

    // --- Multicall --- //

    /// @notice Batches multiple owner calls into a single atomic transaction.
    /// @dev Uses `address(this).delegatecall` so that `msg.sender` is preserved for access-control checks.
    /// @param data Array of ABI-encoded function calls to execute on the gateway.
    /// @return results Array of ABI-encoded return values from each call.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    // --- AddressRegistry --- //

    /// @notice Update the exchange's address registry by `name` and `record`.
    /// @param name Name of the record we want to update or add
    /// @param record Address of the contract we want to set
    function updateRegistryRecord(bytes32 name, address record) external;

    // --- Ping --- //

    /// @notice Records a public exchange ping for offchain indexers.
    /// @dev Permissionless by design: any sender can emit this log so indexers can observe a recent gateway event
    ///      without relying on empty-block assumptions or external checkpointing.
    function ping() external;

    // -- EmergencyPause -- //

    /// @notice Prevents deposits, withdrawals and trading actions on the exchange.
    function emergencyPause() external;

    /// @notice Enables deposits, withdrawals and trading actions on the exchange.
    function emergencyUnpause() external;

    // --- PerpEngine --- //

    /// @notice Registers a product (i.e. trading pair) against an engine for trading.
    /// @param params AddProductParams struct for product configuration
    function registerPerpProduct(IPerpEngine.RegisterPerpProductParams calldata params) external returns (uint32);

    /// @notice Updates an existing product (i.e. trading pair).
    /// @param params struct for updating product configuration
    function updatePerpProduct(IPerpEngine.UpdatePerpProductParams calldata params) external;

    /// @notice Updates an existing perp product's Pyth feed id.
    function updatePerpProductPythFeedId(uint32 productId, uint32 pythFeedId) external;

    /// @notice Activates a pending perp product.
    function activatePerpProduct(uint32 productId) external;

    /// @notice Initiates a perp product delist. Offchain engine uses the latest available mark price to delist.
    /// @param productId Id of the perp product to delist
    function delistPerpProduct(uint32 productId) external;

    // --- PerpEngineViews --- //

    /// @notice Returns a perp product by its `productId`.
    /// @param productId Id of the targeted perp product
    function getPerpProduct(uint32 productId) external view returns (PerpProduct.Info memory);

    /// @notice Returns the pending perp product update for `productId`, if one exists.
    /// @param productId Id of the targeted perp product
    function getPendingPerpProductUpdate(uint32 productId)
        external
        view
        returns (IPerpEngine.UpdatePerpProductParams memory);

    /// @notice Returns the next perp product id that will be assigned on registration.
    function getNextPerpProductId() external view returns (uint32);

    /// @notice Returns a perp position by its `sender` and `subaccount` in `product`.
    /// @param sender Address of the account owner
    /// @param subaccount Subaccount the position belongs to
    /// @param productId Product the position was opened on
    function getPerpPosition(address sender, bytes32 subaccount, uint32 productId)
        external
        view
        returns (PerpPosition.Data memory);

    // --- GatewayViews --- //

    /// @notice Returns the balance of an account's subaccount for a specific token in D9.
    /// @param account Address of the account owner
    /// @param subaccount Subaccount belonging to the account
    /// @param token Address of token to check balances of
    function getAccountBalance(address account, bytes32 subaccount, address token) external view returns (uint256);

    /// @notice Returns whether the account's subaccount has been registered.
    /// @param account Address of the account owner
    /// @param subaccount Subaccount belonging to the account
    function getAccountHasRegistered(address account, bytes32 subaccount) external view returns (bool);

    /// @notice Returns the linked signer for the account's subaccount
    /// @param account Address of the account owner
    /// @param subaccount Subaccount belonging to the account
    function getAccountLinkedSigners(address account, bytes32 subaccount) external view returns (address[] memory);

    /// @notice Returns the number of positions that the account's subaccount has open.
    /// @param account Address of the account owner
    /// @param subaccount Subaccount belonging to the account
    function getAccountOpenPositions(address account, bytes32 subaccount) external view returns (uint128);

    /// @notice Returns a pending deposit by `account` and `subaccount`.
    /// @param account Address of the account owner
    /// @param subaccount Subaccount belonging to the account
    function getAccountPendingDeposit(address account, bytes32 subaccount) external view returns (Deposit.Data memory);

    /// @notice Returns a pending withdraw by`account` and `subaccount`.
    /// @param account Address of the account owner
    /// @param withdrawDigest identifier for the withdraw, EIP712 domain digest of the withdraw data
    function getAccountPendingWithdraw(address account, bytes32 withdrawDigest)
        external
        view
        returns (Withdraw.Data memory);

    /// @notice Returns the number of registered subaccounts.
    /// @param account Address of the account owner
    function getAccountRegisteredSubaccounts(address account) external view returns (uint32);

    /// @notice Returns the `account` whose `subaccount` the signer is linked with.
    /// @param linkedSigner the active linked signer who is being searched on.
    /// @return accountLinkedToSigner when signer is active, otherwise address zero.
    function getAccountGlobalLinkedSignersToAccount(address linkedSigner) external view returns (address);

    /// @notice Returns the balance held by the exchange, sum of all accounts holdings.
    /// @param token Address of the token to retrieve the details on
    function getAccountGlobalTotalBalance(address token) external view returns (uint256);

    /// @notice Returns the total backed balance held by the exchange which include balances converted to synthetic tokens,
    /// sum of all accounts backed balances.
    /// @param token Address of the token to retrieve the details on
    function getAccountGlobalTotalBackedBalance(address token) external view returns (uint256);

    /// @notice Returns the total pending balance held by the exchange, sum of all accounts pending deposits.
    /// @param token Address of the token to retrieve the details on
    function getAccountGlobalTotalPendingBalance(address token) external view returns (uint256);

    /// @notice Returns the settlement stablecoin address.
    function getAccountGlobalUsdToken() external view returns (address);

    /// @notice Returns the amount of time , after an action is signed tha it remains valid for execution, in seconds.
    /// @param action type of action to get the buffer for
    function getExchangeActionExpiryBuffer(ActionType action) external view returns (uint64);

    /// @notice Returns the configured rescue delay in seconds.
    function getExchangeRescueDelay() external view returns (uint64);

    /// @notice Returns the timestamp of the last recorded ping.
    function getExchangeLastPingTimestamp() external view returns (uint64);

    /// @notice Returns the maximum number of deposits that a delegate depositor can submit in one batch.
    function getExchangeDelegateDepositMaxBatchSize() external view returns (uint16);

    /// @notice Returns the `account` for the PythLazer contract used for price verification.
    function getExchangePythLazer() external view returns (address pythLazer, uint64 pythMaxAge);

    /// @notice Returns true if the sequencer is approved, false otherwise.
    /// @param sequencer Sequencer address to check
    function getExchangeSequencer(address sequencer) external view returns (bool isApproved, bool isPaused);

    /// @notice Returns an array of token names.
    function getExchangeTokens() external view returns (bytes32[] memory);

    /// @notice Returns the `account` and `subaccount` that accrue the exchange fees.
    function getFeeCollector() external view returns (address feeCollectorAccount, bytes32 feeCollectorSubaccount);

    /// @notice Returns the FeeSchedule for the given id.
    function getFeeSchedule(uint32 feeScheduleId) external view returns (FeeSchedule.Data memory);

    /// @notice Returns the `account` and `subaccount` that deals with liquidated positions.
    function getLiquidator() external view returns (address liquidatorAccount, bytes32 liquidatorSubaccount);

    /// @notice Returns the token details, that was at one point supported by the exchange.
    /// @param tokenName Name of the token to retrieve the details for
    function getToken(bytes32 tokenName) external view returns (Token.Data memory);

    /// @notice Returns true if `delegator` is an approved delegate depositor, false otherwise.
    /// @param delegator Address of delegator to verify
    function isDelegateDepositor(address delegator) external view returns (bool);

    /// @notice Returns true if the exchange has been paused for deposits, withdraws and trades, false otherwise.
    function isEmergencyPaused() external view returns (bool);

    /// @notice Returns true if the account has been granted the privilege to performs an emergency pause, false otherwise.
    /// @param account Address of pauser to verify
    function isEmergencyPauser(address account) external view returns (bool);

    /// @notice Returns true if `sequencer` is an approved sequencer, false otherwise.
    /// @param sequencer Address of sequencer to verify
    function isSequencerApproved(address sequencer) external view returns (bool);

    /// @notice Returns true if the `claimer` is an approved claimer, false otherwise.
    /// @param claimer Address of the claimer to verify.
    function isClaimer(address claimer) external view returns (bool);
}
