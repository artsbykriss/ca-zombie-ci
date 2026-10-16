// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {EngineType, OrderSide} from "../share/Enums.sol";
import {ActionId} from "../share/UserDefinedTypes.sol";

interface IActionHandler {
    // --- Events --- //

    /// @notice Emitted when a deposit has been finalized.
    event DepositFinalized(
        address indexed sender,
        bytes32 indexed subaccount,
        address token,
        uint256 amount,
        uint128 fee,
        uint256 balance,
        bytes32 initiatedTxHash,
        uint32 initiatedLogIdx,
        uint64 messageIdx
    );

    /// @notice Emitted when a token conversion is finalized.
    event ConvertFinalized(
        address indexed account,
        bytes32 indexed subaccount,
        bytes32 indexed convertDigest,
        address fromToken,
        address toToken,
        uint128 fromAmount,
        uint128 toAmount,
        uint128 fee,
        uint64 finalizedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when signer is linked to the subaccount (i.e. msg.sender).
    event SignerLinked(
        address indexed sender,
        bytes32 indexed subaccount,
        address indexed signer,
        uint64 linkedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when signer linkage is rejected i.e. the signer has deposited (is already an account).
    event SignerLinkRejected(
        address indexed sender,
        bytes32 indexed subaccount,
        address indexed signer,
        uint64 rejectedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when signer is revoked from the subaccount (i.e. msg.sender).
    event SignerRevoked(
        address indexed sender,
        bytes32 indexed subaccount,
        address indexed signer,
        uint64 revokedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when signer revocation is rejected (i.e. signature validation failed).
    event SignerRevokeRejected(
        address indexed sender,
        bytes32 indexed subaccount,
        address indexed signer,
        uint64 rejectedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when a subaccount initiated a withdrawal.
    event WithdrawInitiated(
        address indexed account,
        bytes32 indexed subaccount,
        bytes32 indexed withdrawDigest,
        address token,
        uint256 amount,
        uint128 fee,
        uint64 initiatedTimestamp,
        uint64 messageIdx
    );

    /// @notice Emitted when a batch is processed.
    event ActionsProcessed(ActionId firstActionId, ActionId lastActionId, uint256 length);

    // --- ActionTypes --- //

    struct FinalizeDepositAction {
        address account;
        bytes32 subaccount;
        address token;
        uint256 amount;
        bytes32 initiatedTxHash;
        uint32 initiatedLogIdx;
        uint64 messageIdx;
    }

    struct InitiateWithdrawAction {
        InitiateWithdrawMessage message;
        bytes signature;
        uint128 fee;
        uint64 messageIdx;
    }

    struct InitiateWithdrawMessage {
        address account;
        bytes32 subaccount;
        address token;
        uint256 amount;
        uint64 nonce;
        uint64 signedAt;
        bytes32 destinationAddress;
        uint32 destinationEndpointId;
    }

    struct ConvertTokenAction {
        ConvertTokenMessage message;
        bytes signature;
        uint128 fee;
        uint128 toAmount;
        uint64 messageIdx;
    }

    struct ConvertTokenMessage {
        address sender;
        bytes32 subaccount;
        address fromToken;
        address toToken;
        uint128 amount;
        uint64 nonce;
        uint64 signedAt;
    }

    struct LinkSignerAction {
        LinkSignerMessage message;
        bytes signature;
        bytes signerSignature;
        uint64 messageIdx;
    }

    struct LinkSignerMessage {
        address sender;
        address signer;
        bytes32 subaccount;
        uint64 nonce;
        uint64 signedAt;
    }

    struct MatchOrdersAction {
        TradeOrder maker;
        TradeOrder taker;
        bytes makerSignature;
        bytes takerSignature;
        uint128 makerFee;
        uint128 takerFee;
        int128 makerRealizedPnl;
        int128 takerRealizedPnl;
        uint128 fillQuantity;
        uint128 fillNotional;
        uint64 messageIdx;
    }

    struct RevokeLinkedSignerAction {
        RevokeLinkedSignerMessage message;
        bytes signature;
        uint64 messageIdx;
    }

    struct RevokeLinkedSignerMessage {
        address sender;
        address signer;
        bytes32 subaccount;
        uint64 nonce;
        uint64 signedAt;
    }

    struct TradeOrder {
        address sender;
        bytes32 subaccount;
        uint128 quantity;
        uint128 price;
        bool reduceOnly;
        OrderSide side;
        EngineType engineType;
        uint32 productId;
        uint64 nonce;
        uint64 signedAt;
    }

    struct UpdateFundingAction {
        uint32 productId;
        int128 fundingDeltaUsd;
        uint64 messageIdx;
    }

    struct FinalizePerpProductUpdateAction {
        uint32 productId;
        uint16 maxLeverage;
        uint128 maxQuantity;
        uint128 maxOpenInterestUsd;
        uint128 maxPositionNotionalUsd;
        uint64 messageIdx;
    }

    struct UpdatePositionFeeAction {
        uint32 productId;
        uint128 positionFeeDeltaUsd;
        uint256 liquidatorCreditAmount;
        uint64 messageIdx;
    }

    struct RealizeFundingAction {
        address account;
        bytes32 subaccount;
        uint32[] productIds;
        uint64 messageIdx;
    }

    struct RealizePnlAction {
        address account;
        bytes32 subaccount;
        uint32 productId;
        int128 costDelta;
        uint64 messageIdx;
    }

    struct InitiatePerpProductDelistAction {
        uint32 productId;
        uint64 messageIdx;
        uint64 pythFee;
        bytes pythPriceUpdate;
    }

    struct FinalizePerpProductDelistAction {
        uint32 productId;
        uint64 messageIdx;
    }

    struct PerpProductDelistPositionSettlementAction {
        address account;
        bytes32 subaccount;
        uint32 productId;
        int128 realizedPnl;
        uint64 messageIdx;
    }

    /// @notice Given a list of signed offchain actions, submit and process (sequencer only).
    /// @param actions Byte array of actions to process
    function processActions(bytes[] calldata actions) external payable;

    /// @notice Simulates `processActions` and always reverts after processing.
    /// @param actions Byte array of actions to simulate.
    /// @param minGasLeft Minimum gas that must remain after each action. Disables if zero.
    function processActionsDryRun(bytes[] calldata actions, uint256 minGasLeft) external payable;

    /// @notice Finalizes a revoked signer when signature verification failed onchain.
    /// @param message Revocation message data to finalize
    function finalizeRevokeLinkedSigner(RevokeLinkedSignerMessage calldata message) external;
}
