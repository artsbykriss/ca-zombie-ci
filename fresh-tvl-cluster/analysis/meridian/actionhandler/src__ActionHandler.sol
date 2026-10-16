// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IActionHandler} from "./interface/IActionHandler.sol";
import {IDeleverage, IDeleverageWithCompensation} from "./interface/IDeleverage.sol";
import {ILiquidation} from "./interface/ILiquidation.sol";
import {IPerpEngine} from "./interface/IPerpEngine.sol";
import {ActionDecoder} from "./lib/ActionDecoder.sol";
import {VerifierLib} from "./lib/VerifierLib.sol";
import {Account} from "./lib/storage/Account.sol";
import {AddressRegistry} from "./lib/storage/AddressRegistry.sol";
import {Deposit} from "./lib/storage/Deposit.sol";
import {Exchange} from "./lib/storage/Exchange.sol";
import {FeeCollector} from "./lib/storage/FeeCollector.sol";
import {Token} from "./lib/storage/Token.sol";
import {Withdraw} from "./lib/storage/Withdraw.sol";
import {EXCHANGE_NAME, EXCHANGE_VERSION} from "./share/Constants.sol";
import {ActionType, EngineType} from "./share/Enums.sol";
import {
    ActionAlreadyProcessed,
    DelegationFailed,
    DryRunResult,
    EmptyActions,
    ExcludedAccount,
    FeeNotCoveredByBalance,
    GasLimitExceeded,
    InsufficientBalance,
    InvalidAction,
    InvalidEngineType,
    InvalidNonce,
    InvalidSigner,
    InvalidTokenConversionAmount,
    InvalidTokenConversionFee,
    InvalidTokenConversionPair,
    InvalidTokenConversionZeroAmount,
    PendingDepositMismatch,
    PendingDepositNotFound,
    PendingRevokeNotFound,
    SubaccountNotFound,
    TokenWithdrawPaused,
    WithdrawFeeMismatch
} from "./share/Errors.sol";
import {
    DELEVERAGE_RECORD,
    DELEVERAGE_WITH_COMPENSATION_RECORD,
    LIQUIDATION_RECORD,
    PERP_ENGINE_RECORD
} from "./share/RegistryRecords.sol";
import {Signatures} from "./share/Signatures.sol";
import {ActionId} from "./share/UserDefinedTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EIP712} from "solady/utils/EIP712.sol";

contract ActionHandler is EIP712, IActionHandler {
    using Account for Account.Data;
    using Account for Account.DataGlobal;
    using ActionDecoder for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Exchange for Exchange.Data;
    using FeeCollector for FeeCollector.Data;
    using VerifierLib for address;

    // --- EIP712 --- //

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = EXCHANGE_NAME;
        version = EXCHANGE_VERSION;
    }

    function _domainNameAndVersionMayChange() internal pure override returns (bool) {
        return false;
    }

    // --- Signatures --- //

    bytes32 private constant LINK_SIGNER_ABI_PARAM_SIG = keccak256(Signatures.LINK_SIGNER_ABI_PARAM);
    bytes32 private constant TRADE_ORDER_ABI_PARAM_SIG = keccak256(Signatures.TRADE_ORDER_ABI_PARAM);
    bytes32 private constant REVOKE_LINKED_SIGNER_ABI_PARAM_SIG = keccak256(Signatures.REVOKE_LINKED_SIGNER_ABI_PARAM);
    bytes32 private constant INITIATE_WITHDRAW_ABI_PARAM_SIG = keccak256(Signatures.INITIATE_WITHDRAW_ABI_PARAM);
    bytes32 private constant CONVERT_TOKEN_ABI_PARAM_SIG = keccak256(Signatures.CONVERT_TOKEN_ABI_PARAM);

    // --- External Functions --- //

    /// @inheritdoc IActionHandler
    function processActions(bytes[] calldata actions) external payable {
        _processActions(actions, 0);
    }

    /// @inheritdoc IActionHandler
    function processActionsDryRun(bytes[] calldata actions, uint256 minGasLeft) external payable {
        _processActions(actions, minGasLeft);
        revert DryRunResult(gasleft());
    }

    function _processActions(bytes[] calldata actions, uint256 minGasLeft) private {
        uint256 previousGasLeft;
        if (minGasLeft != 0) {
            previousGasLeft = gasleft();
        }

        uint256 length = actions.length;
        if (length == 0) {
            revert EmptyActions();
        }

        Exchange.Data storage exchange = Exchange.load();
        ActionId lastCompleteId = exchange.lastActionId;
        ActionId firstId;
        ActionId lastId = lastCompleteId;

        for (uint256 i; i < length; i++) {
            bytes calldata actionData = actions[i];
            (ActionId id, ActionType actionType) = actionData.decodeActionHeader();

            if (i == 0) {
                firstId = id;
            }

            if (ActionId.unwrap(id) <= ActionId.unwrap(lastId)) {
                revert ActionAlreadyProcessed(id, lastId, lastCompleteId);
            }
            lastId = id;

            if (actionType == ActionType.MatchOrders) {
                _handleMatchOrders(exchange, id, actionData);
            } else if (actionType == ActionType.InitiateWithdraw) {
                _handleInitiateWithdraw(exchange, id, actionData);
            } else if (actionType == ActionType.UpdatePositionFee) {
                _handleUpdatePositionFee(id, actionData);
            } else if (actionType == ActionType.UpdateFunding) {
                _handleUpdateFunding(id, actionData);
            } else if (actionType == ActionType.LinkSigner) {
                _handleLinkSigner(exchange, id, actionData);
            } else if (actionType == ActionType.FinalizeDeposit) {
                _handleFinalizeDeposit(id, actionData);
            } else if (actionType == ActionType.LiquidateSubaccount) {
                _handleLiquidateSubaccount(id, actionData);
            } else if (actionType == ActionType.RevokeLinkedSigner) {
                _handleRevokeLinkedSigner(exchange, id, actionData);
            } else if (actionType == ActionType.RealizeFunding) {
                _handleRealizeFunding(id, actionData);
            } else if (actionType == ActionType.RealizePnl) {
                _handleRealizePnl(id, actionData);
            } else if (actionType == ActionType.DeleverageLiquidator) {
                _handleDeleverageLiquidator(id, actionData);
            } else if (actionType == ActionType.ConvertToken) {
                _handleConvertToken(exchange, id, actionData);
            } else if (actionType == ActionType.LiquidateSubaccountWithCompensation) {
                _handleLiquidateSubaccountWithCompensation(id, actionData);
            } else if (actionType == ActionType.DeleverageLiquidatorWithCompensation) {
                _handleDeleverageLiquidatorWithCompensation(id, actionData);
            } else if (actionType == ActionType.PerpProductDelistPositionSettlement) {
                _handlePerpProductDelistPositionSettlement(id, actionData);
            } else if (actionType == ActionType.InitiatePerpProductDelist) {
                _handleInitiatePerpProductDelist(id, actionData);
            } else if (actionType == ActionType.FinalizePerpProductDelist) {
                _handleFinalizePerpProductDelist(id, actionData);
            } else if (actionType == ActionType.FinalizePerpProductUpdate) {
                _handleFinalizePerpProductUpdate(id, actionData);
            } else {
                revert InvalidAction(id, actionType);
            }

            if (minGasLeft != 0) {
                uint256 currentGasLeft = gasleft();
                if (currentGasLeft < minGasLeft) {
                    revert GasLimitExceeded(id, currentGasLeft, previousGasLeft);
                }
                previousGasLeft = currentGasLeft;
            }
        }
        exchange.lastActionId = lastId;
        emit ActionsProcessed(firstId, lastId, length);
    }

    // --- Admin --- //

    /// @inheritdoc IActionHandler
    function finalizeRevokeLinkedSigner(RevokeLinkedSignerMessage calldata message) external {
        Account.Data storage account = Account.load(message.sender);

        bool isSignerPendingRevoke = account.pendingSignerRevoke[message.subaccount][message.signer];
        if (!isSignerPendingRevoke) {
            revert PendingRevokeNotFound(message.sender, message.subaccount, message.signer);
        }

        // NOTE: Unlike the normal revokeSigner in the `processActions` path, we do _not_ check the message expiry
        // here. This is intentional as we know that the message expiry has already been checked in `processActions`.
        // If a revoke linked signer action has reached this point, all upstream state has already considered this
        // signer revoked, we are merely just finalizing the revoke.
        delete account.pendingSignerRevoke[message.subaccount][message.signer];

        Account.load().revokeSigner(message, ActionId.wrap(0));
        emit SignerRevoked(message.sender, message.subaccount, message.signer, uint64(block.timestamp), 0);
    }

    // --- Delegation --- //

    /// @dev Borrowed from openzeppelin-contracts/utils/Address.sol
    /// @custom:see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/Address.sol#L146
    function _revert(bytes memory returnData) private pure {
        if (returnData.length > 0) {
            assembly ("memory-safe") {
                let returndata_size := mload(returnData)
                revert(add(32, returnData), returndata_size)
            }
        } else {
            revert DelegationFailed();
        }
    }

    /// @dev Wraps `delegatecall` and verifies error in returndata.
    function _delegatecall(address target, bytes memory data) private returns (bytes memory) {
        (bool success, bytes memory returnData) = target.delegatecall(data);
        if (!success) {
            _revert(returnData);
        } else {
            return returnData;
        }
    }

    /// @dev Performs a delegate call to the PerpEngine with the data argument.
    function _delegateCallPerpEngine(bytes memory data) private returns (bytes memory) {
        return _delegatecall(AddressRegistry.load().records[PERP_ENGINE_RECORD], data);
    }

    /// @dev Performs a delegate call to the Liquidation contract with the data argument.
    function _delegateCallLiquidation(bytes memory data) private {
        _delegatecall(AddressRegistry.load().records[LIQUIDATION_RECORD], data);
    }

    /// @dev Performs a delegate call to the Deleverage contract with the data argument.
    function _delegateCallDeleverage(bytes memory data) private {
        _delegatecall(AddressRegistry.load().records[DELEVERAGE_RECORD], data);
    }

    /// @dev Performs a delegate call to the compensation Deleverage contract with the data argument.
    function _delegateCallDeleverageWithCompensation(bytes memory data) private {
        _delegatecall(AddressRegistry.load().records[DELEVERAGE_WITH_COMPENSATION_RECORD], data);
    }

    // --- Action Handlers --- //

    /// @dev Action handler for InitiateWithdraw.
    function _handleInitiateWithdraw(Exchange.Data storage exchange, ActionId id, bytes calldata actionData) private {
        InitiateWithdrawAction memory action = actionData.decodeInitiateWithdrawAction();
        InitiateWithdrawMessage memory message = action.message;

        bytes32 withdrawDigest = _getInitiateWithdrawDigest(message);

        exchange.verifyBeforeActionExpiry(id, ActionType.InitiateWithdraw, message.signedAt);

        Account.DataGlobal storage accountGlobal = Account.load();
        if (accountGlobal.excludedAccounts[message.account]) {
            revert ExcludedAccount(id, message.account);
        }

        Account.Data storage account = Account.load(message.account);
        if (!account.isSubaccountRegistered(message.subaccount)) {
            revert SubaccountNotFound(id, message.account, message.subaccount);
        }
        if (account.isNonceUsed(message.account, ActionType.InitiateWithdraw, message.nonce)) {
            revert InvalidNonce(id, message.nonce);
        }
        account.usedNonces[message.account][ActionType.InitiateWithdraw][message.nonce] = true;

        uint256 subaccountTokenBalance = account.balance[message.subaccount][message.token];
        if (message.amount > subaccountTokenBalance) {
            revert InsufficientBalance(
                id, message.account, message.subaccount, message.token, message.amount, subaccountTokenBalance
            );
        }

        Token.Data storage token = Token.load(exchange.tokensByAddress[message.token]);
        uint128 withdrawFee = token.withdrawFee;

        if (action.fee != withdrawFee) {
            revert WithdrawFeeMismatch(id, action.fee, withdrawFee);
        }

        if (withdrawFee >= message.amount) {
            revert FeeNotCoveredByBalance(
                id, message.account, message.subaccount, message.token, message.amount, withdrawFee
            );
        }

        if (!token.withdrawEnabled) {
            revert TokenWithdrawPaused(id, message.token);
        }

        {
            // `amount` represents the total amount to withdraw. This should be removed from the subaccount. However,
            // the `withdrawFee` is an optional fee charged against the subaccount. This fee is transferred to the
            // `feeCollector` once the withdraw is finalised. The withdraw fee still exists within the exchange until
            // the collector calls `claimFees`.
            uint256 amountMinusFee = message.amount - withdrawFee;
            account.balance[message.subaccount][message.token] -= message.amount;
            accountGlobal.totalBalance[message.token] -= amountMinusFee;
            accountGlobal.totalBackedBalance[message.token] -= amountMinusFee;

            account.pendingWithdraw[withdrawDigest] = Withdraw.Data({
                destinationAddress: message.destinationAddress,
                destinationEndpointId: message.destinationEndpointId,
                token: message.token,
                amount: amountMinusFee,
                fee: withdrawFee,
                messageIdx: action.messageIdx,
                initiatedAt: uint64(block.timestamp),
                signature: action.signature
            });
        }

        emit WithdrawInitiated(
            message.account,
            message.subaccount,
            withdrawDigest,
            message.token,
            message.amount,
            withdrawFee,
            uint64(block.timestamp),
            action.messageIdx
        );
    }

    /// @dev Action handler for FinalizeDeposit.
    function _handleFinalizeDeposit(ActionId id, bytes calldata actionData) private {
        FinalizeDepositAction memory action = actionData.decodeFinalizeDepositAction();
        Account.DataGlobal storage accountGlobal = Account.load();
        Account.Data storage account = Account.load(action.account);

        // NOTE: Pulls the entire pendingDeposit into memory. If we add more, it will pull more so be careful here.
        Deposit.Data memory pendingDeposit = account.pendingDeposit[action.subaccount];

        if (pendingDeposit.token == address(0)) {
            revert PendingDepositNotFound(id, action.account, action.subaccount);
        }

        if (pendingDeposit.amount != action.amount || pendingDeposit.token != action.token) {
            revert PendingDepositMismatch(
                id, action.account, action.subaccount, pendingDeposit.token, pendingDeposit.amount
            );
        }

        // Only register the subaccount once.
        if (!account.isSubaccountRegistered(action.subaccount)) {
            account.hasRegistered[action.subaccount] = true;
            account.registeredSubaccounts++;
        }

        // NOTE: `pendingDeposit.amount` is the amount of the deposit, excluding fee.
        uint256 updatedBalance = account.balance[action.subaccount][pendingDeposit.token] + pendingDeposit.amount;
        account.balance[action.subaccount][pendingDeposit.token] = updatedBalance;

        uint256 totalDepositAmount = pendingDeposit.amount + pendingDeposit.fee;
        accountGlobal.totalPendingBalance[pendingDeposit.token] -= totalDepositAmount;
        accountGlobal.totalBalance[pendingDeposit.token] += totalDepositAmount;
        accountGlobal.totalBackedBalance[pendingDeposit.token] += totalDepositAmount;

        delete account.pendingDeposit[action.subaccount];

        if (pendingDeposit.fee > 0) {
            FeeCollector.load().accrueFees(pendingDeposit.token, pendingDeposit.fee, action.messageIdx);
        }

        emit DepositFinalized(
            action.account,
            action.subaccount,
            pendingDeposit.token,
            pendingDeposit.amount,
            pendingDeposit.fee,
            updatedBalance,
            action.initiatedTxHash,
            action.initiatedLogIdx,
            action.messageIdx
        );
    }

    /// @dev Action handler for LinkSigner.
    function _handleLinkSigner(Exchange.Data storage exchange, ActionId id, bytes calldata actionData) private {
        LinkSignerAction memory action = actionData.decodeLinkSignerAction();
        LinkSignerMessage memory message = action.message;

        bytes32 digest = _getLinkSignerDigest(message);
        if (message.signer == address(0)) {
            revert InvalidSigner(id, action.message.signer);
        }

        // Verify "sender" signature (both SCW + EoA).
        bool isValidSenderSignature = message.sender.isValidSignature(digest, action.signature, id);
        if (!isValidSenderSignature) {
            emit SignerLinkRejected(
                message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
            );
            return;
        }

        // Verify "signer" signature (only EoA), revert on invalid ECDSA signature.
        message.signer._verifyEcdsaSignature(digest, action.signerSignature, id, true);
        exchange.verifyBeforeActionExpiry(id, ActionType.LinkSigner, message.signedAt);

        if (Account.load().linkSigner(message, id)) {
            emit SignerLinked(
                message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
            );
        } else {
            emit SignerLinkRejected(
                message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
            );
        }
    }

    /// @dev Action handler for LiquidateSubaccount.
    function _handleLiquidateSubaccount(ActionId id, bytes calldata actionData) private {
        bytes memory data = abi.encodeWithSelector(ILiquidation.liquidateSubaccount.selector, id, actionData);
        _delegateCallLiquidation(data);
    }

    /// @dev Action handler for LiquidateSubaccountWithCompensation.
    function _handleLiquidateSubaccountWithCompensation(ActionId id, bytes calldata actionData) private {
        bytes memory data =
            abi.encodeWithSelector(ILiquidation.liquidateSubaccountWithCompensation.selector, id, actionData);
        _delegateCallLiquidation(data);
    }

    /// @dev Action handler for DeleverageLiquidator.
    function _handleDeleverageLiquidator(ActionId id, bytes calldata actionData) private {
        bytes memory data = abi.encodeWithSelector(IDeleverage.deleverageLiquidator.selector, id, actionData);
        _delegateCallDeleverage(data);
    }

    /// @dev Action handler for DeleverageLiquidatorWithCompensation.
    function _handleDeleverageLiquidatorWithCompensation(ActionId id, bytes calldata actionData) private {
        bytes memory data = abi.encodeWithSelector(
            IDeleverageWithCompensation.deleverageLiquidatorWithCompensation.selector, id, actionData
        );
        _delegateCallDeleverageWithCompensation(data);
    }

    /// @dev Action handler for MatchedOrders.
    function _handleMatchOrders(Exchange.Data storage exchange, ActionId id, bytes calldata actionData) private {
        MatchOrdersAction memory action = actionData.decodeMatchOrdersAction();

        EngineType engineType = action.maker.engineType;
        if (engineType == EngineType.PERP) {
            // Verify the signatures and message expiry for both maker and taker orders.
            bytes32 makerDigest = _getTradeOrderDigest(action.maker);
            action.maker.sender._verifyEcdsaSignature(makerDigest, action.makerSignature, id, true);

            bytes32 takerDigest = _getTradeOrderDigest(action.taker);
            action.taker.sender._verifyEcdsaSignature(takerDigest, action.takerSignature, id, true);

            exchange.verifyBeforeActionExpiry(id, ActionType.MatchOrders, action.taker.signedAt);
            exchange.verifyBeforeActionExpiry(id, ActionType.MatchOrders, action.maker.signedAt);

            bytes memory data = abi.encodeWithSelector(
                IPerpEngine.executeMatch.selector,
                id,
                action,
                IPerpEngine.ExecuteMatchDigests({maker: makerDigest, taker: takerDigest})
            );
            _delegateCallPerpEngine(data);
        } else {
            // NOTE: PERP is the only supported engine type right now.
            revert InvalidEngineType(id, engineType);
        }
    }

    /// @dev Action handler for RevokeLinkedSigner.
    function _handleRevokeLinkedSigner(Exchange.Data storage exchange, ActionId id, bytes calldata actionData) private {
        RevokeLinkedSignerAction memory action = actionData.decodeRevokeLinkedSignerAction();
        RevokeLinkedSignerMessage memory message = action.message;

        bytes32 digest = _getRevokeLinkedSignerDigest(message);

        Account.Data storage account = Account.load(message.sender);
        bool isPendingRevoke = account.pendingSignerRevoke[message.subaccount][message.signer];
        if (isPendingRevoke) {
            emit SignerRevokeRejected(
                message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
            );
            return;
        }

        exchange.verifyBeforeActionExpiry(id, ActionType.RevokeLinkedSigner, message.signedAt);
        bool isSignatureValid = message.sender.isValidSignature(digest, action.signature, id);
        if (!isSignatureValid) {
            account.pendingSignerRevoke[message.subaccount][message.signer] = true;
            emit SignerRevokeRejected(
                message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
            );
            return;
        }

        Account.load().revokeSigner(message, id);
        emit SignerRevoked(
            message.sender, message.subaccount, message.signer, uint64(block.timestamp), action.messageIdx
        );
    }

    /// @dev Action handler for UpdateFunding.
    function _handleUpdateFunding(ActionId id, bytes calldata actionData) private {
        UpdateFundingAction memory action = actionData.decodeUpdateFundingAction();
        bytes memory data = abi.encodeWithSelector(
            IPerpEngine.updateFunding.selector, id, action.productId, action.fundingDeltaUsd, action.messageIdx
        );
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for FinalizePerpProductUpdate.
    function _handleFinalizePerpProductUpdate(ActionId id, bytes calldata actionData) private {
        FinalizePerpProductUpdateAction memory action = actionData.decodeFinalizePerpProductUpdateAction();
        bytes memory data = abi.encodeWithSelector(IPerpEngine.finalizeUpdate.selector, id, action);
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for UpdatePositionFee.
    function _handleUpdatePositionFee(ActionId id, bytes calldata actionData) private {
        UpdatePositionFeeAction memory action = actionData.decodeUpdatePositionFeeAction();
        bytes memory data = abi.encodeWithSelector(
            IPerpEngine.updatePositionFee.selector,
            id,
            action.productId,
            action.positionFeeDeltaUsd,
            action.liquidatorCreditAmount,
            action.messageIdx
        );
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for RealizeFunding.
    function _handleRealizeFunding(ActionId id, bytes calldata actionData) private {
        RealizeFundingAction memory action = actionData.decodeRealizeFundingAction();
        bytes memory data = abi.encodeWithSelector(
            IPerpEngine.realizeFunding.selector,
            id,
            action.account,
            action.subaccount,
            action.productIds,
            action.messageIdx
        );
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for RealizePnl.
    function _handleRealizePnl(ActionId id, bytes calldata actionData) private {
        RealizePnlAction memory action = actionData.decodeRealizePnlAction();
        bytes memory data = abi.encodeWithSelector(
            IPerpEngine.realizePnl.selector,
            id,
            action.account,
            action.subaccount,
            action.productId,
            action.costDelta,
            action.messageIdx
        );
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for ConvertToken: verifies the user's signature, marks nonce, then settles the balance move.
    function _handleConvertToken(Exchange.Data storage exchange, ActionId id, bytes calldata actionData) private {
        ConvertTokenAction memory action = actionData.decodeConvertTokenAction();
        ConvertTokenMessage memory message = action.message;

        bytes32 digest = _getConvertTokenDigest(action.message);
        message.sender._verifyEcdsaSignature(digest, action.signature, id, true);

        exchange.verifyBeforeActionExpiry(id, ActionType.ConvertToken, message.signedAt);

        Account.DataGlobal storage accountGlobal = Account.load();
        Account.Data storage account = accountGlobal.resolveAccount(message.sender);
        address resolvedSender = account.sender;

        if (accountGlobal.excludedAccounts[resolvedSender]) {
            revert ExcludedAccount(id, resolvedSender);
        }

        if (!account.isSubaccountRegistered(message.subaccount)) {
            revert SubaccountNotFound(id, message.sender, message.subaccount);
        }

        // Check if the signer is associated to named subaccount
        if ((resolvedSender != message.sender) && !account.linkedSigners[message.subaccount].contains(message.sender)) {
            revert InvalidSigner(id, message.sender);
        }

        if (account.isNonceUsed(message.sender, ActionType.ConvertToken, message.nonce)) {
            revert InvalidNonce(id, message.nonce);
        }
        account.usedNonces[message.sender][ActionType.ConvertToken][message.nonce] = true;

        _verifyConvertToken(id, action, exchange);
        {
            uint256 fromBalance = account.balance[message.subaccount][message.fromToken];
            if (message.amount > fromBalance) {
                revert InsufficientBalance(
                    id, resolvedSender, message.subaccount, message.fromToken, message.amount, fromBalance
                );
            }
            // Note: total backed balance is not affected by conversion.
            account.balance[message.subaccount][message.fromToken] = fromBalance - message.amount;
            account.balance[message.subaccount][message.toToken] += message.amount;
            accountGlobal.totalBalance[message.fromToken] -= message.amount;
            accountGlobal.totalBalance[message.toToken] += message.amount;
        }

        emit ConvertFinalized(
            resolvedSender,
            message.subaccount,
            digest,
            message.fromToken,
            message.toToken,
            message.amount,
            message.amount,
            0,
            uint64(block.timestamp),
            action.messageIdx
        );
    }

    /// @dev Verifies the convert token message, reverts if invalid.
    function _verifyConvertToken(ActionId id, ConvertTokenAction memory action, Exchange.Data storage exchange)
        private
        view
    {
        ConvertTokenMessage memory message = action.message;
        if (action.fee != 0) {
            revert InvalidTokenConversionFee(id);
        }

        if (action.toAmount != message.amount) {
            revert InvalidTokenConversionAmount(id);
        }

        if (message.amount == 0) {
            revert InvalidTokenConversionZeroAmount(id);
        }

        if (message.fromToken == message.toToken) {
            revert InvalidTokenConversionPair(id, message.fromToken, message.toToken);
        }

        // Check if from and to tokens are parent/children or siblings.
        // Each branch guards `backingToken != 0` to reject unregistered or zero-address tokens, whose
        // Token.Data fields are zero-default and would otherwise trivially satisfy `0 == 0` equalities.
        Token.Data storage fromToken = Token.load(exchange.tokensByAddress[message.fromToken]);
        Token.Data storage toToken = Token.load(exchange.tokensByAddress[message.toToken]);
        if (fromToken.name == bytes32(0) || toToken.name == bytes32(0)) {
            revert InvalidTokenConversionPair(id, message.fromToken, message.toToken);
        }

        address fromBackingToken = fromToken.backingToken;
        address toBackingToken = toToken.backingToken;
        address fromTokenAddress = fromToken.tokenAddress;
        address toTokenAddress = toToken.tokenAddress;

        bool isValidConversion =
        // shared backing token (sibling <-> sibling)
         (fromBackingToken != address(0) && fromBackingToken == toBackingToken)
            // child -> parent: from is backed by to
            || (fromBackingToken != address(0) && fromBackingToken == toTokenAddress)
            // parent -> child: to is backed by from
            || (toBackingToken != address(0) && toBackingToken == fromTokenAddress);
        if (!isValidConversion) {
            revert InvalidTokenConversionPair(id, message.fromToken, message.toToken);
        }
    }

    /// @dev Action handler for InitiatePerpProductDelist.
    function _handleInitiatePerpProductDelist(ActionId id, bytes calldata actionData) private {
        InitiatePerpProductDelistAction memory action = actionData.decodeInitiatePerpProductDelistAction();
        bytes memory data = abi.encodeWithSelector(IPerpEngine.initiateDelist.selector, id, action);
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for FinalizePerpProductDelist.
    function _handleFinalizePerpProductDelist(ActionId id, bytes calldata actionData) private {
        FinalizePerpProductDelistAction memory action = actionData.decodeFinalizePerpProductDelistAction();
        bytes memory data = abi.encodeWithSelector(IPerpEngine.finalizeDelist.selector, id, action);
        _delegateCallPerpEngine(data);
    }

    /// @dev Action handler for PerpProductDelistPositionSettlement.
    function _handlePerpProductDelistPositionSettlement(ActionId id, bytes calldata actionData) private {
        PerpProductDelistPositionSettlementAction memory action =
            actionData.decodePerpProductDelistPositionSettlementAction();
        bytes memory data = abi.encodeWithSelector(IPerpEngine.settleDelistPosition.selector, id, action);
        _delegateCallPerpEngine(data);
    }

    // --- Digest --- //

    /// @dev Returns link signer message digest for sig verification.
    function _getLinkSignerDigest(LinkSignerMessage memory message) private view returns (bytes32) {
        bytes32 structDigest = keccak256(
            abi.encode(
                LINK_SIGNER_ABI_PARAM_SIG,
                message.sender,
                message.signer,
                message.subaccount,
                message.nonce,
                message.signedAt
            )
        );
        return _hashTypedData(structDigest);
    }

    /// @dev Returns revoke linked signer message digest for sig verification.
    function _getRevokeLinkedSignerDigest(RevokeLinkedSignerMessage memory message) private view returns (bytes32) {
        bytes32 structDigest = keccak256(
            abi.encode(
                REVOKE_LINKED_SIGNER_ABI_PARAM_SIG,
                message.sender,
                message.signer,
                message.subaccount,
                message.nonce,
                message.signedAt
            )
        );
        return _hashTypedData(structDigest);
    }

    /// @dev Returns trade order digest for sig verification.
    function _getTradeOrderDigest(TradeOrder memory order) private view returns (bytes32) {
        bytes32 structDigest = keccak256(
            abi.encode(
                TRADE_ORDER_ABI_PARAM_SIG,
                order.sender,
                order.subaccount,
                order.quantity,
                order.price,
                order.reduceOnly,
                order.side,
                order.engineType,
                order.productId,
                order.nonce,
                order.signedAt
            )
        );
        return _hashTypedData(structDigest);
    }

    /// @dev Returns init withdraw digest for sig verification.
    function _getInitiateWithdrawDigest(InitiateWithdrawMessage memory message) private view returns (bytes32) {
        bytes32 structDigest = keccak256(
            abi.encode(
                INITIATE_WITHDRAW_ABI_PARAM_SIG,
                message.account,
                message.subaccount,
                message.token,
                message.amount,
                message.nonce,
                message.signedAt,
                message.destinationAddress,
                message.destinationEndpointId
            )
        );
        return _hashTypedData(structDigest);
    }

    /// @dev Returns the convert token digest for sig verification.
    function _getConvertTokenDigest(ConvertTokenMessage memory message) private view returns (bytes32) {
        bytes32 structDigest = keccak256(
            abi.encode(
                CONVERT_TOKEN_ABI_PARAM_SIG,
                message.sender,
                message.subaccount,
                message.fromToken,
                message.toToken,
                message.amount,
                message.nonce,
                message.signedAt
            )
        );
        return _hashTypedData(structDigest);
    }
}
