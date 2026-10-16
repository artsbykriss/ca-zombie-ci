// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IActionHandler} from "../interface/IActionHandler.sol";
import {IDeleverage} from "../interface/IDeleverage.sol";
import {ILiquidation} from "../interface/ILiquidation.sol";
import {EngineType, OrderSide} from "../share/Enums.sol";
import {ActionType} from "../share/Enums.sol";
import {InvalidActionEncoding, InvalidActionEncodingHeader} from "../share/Errors.sol";
import {ActionId} from "../share/UserDefinedTypes.sol";

library ActionDecoder {
    uint8 private constant ACTION_ID_SIZE_BYTES = 8;

    // actionHeaderOffset = bytesSizeUint64 + bytesSizeUint8
    uint8 private constant ACTION_HEADER_OFFSET = 9;

    // --- MatchOrders indexes --- //

    // makerSenderIndex = bytesSizeUint64 + bytesSizeUint8
    uint16 private constant MATCH_ORDER_MAKER_SENDER = 9;
    // makerSubaccountIndex = makerSenderIndex + bytesSizeAddress
    uint16 private constant MATCH_ORDER_MAKER_SUBACCOUNT = 29;
    // makerQuantityIndex = makerSubaccountIndex + bytesSizeBytes32
    uint16 private constant MATCH_ORDER_MAKER_QUANTITY = 61;
    // makerPriceIndex = makerQuantityIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_MAKER_PRICE = 77;
    // makerReduceOnlyIndex = makerPriceIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_MAKER_REDUCE_ONLY = 93;
    // makerSideIndex = makerReduceOnlyIndex + bytesSizeBool
    uint16 private constant MATCH_ORDER_MAKER_SIDE = 94;
    // makerNonceIndex = makerSideIndex + bytesSizeUint8
    uint16 private constant MATCH_ORDER_MAKER_NONCE = 95;
    // makerSignedAtIndex = makerNonceIndex + bytesSizeUint64
    uint16 private constant MATCH_ORDER_MAKER_SIGNED_AT = 103;
    // takerSenderIndex = makerSignedAtIndex + bytesSizeUint64
    uint16 private constant MATCH_ORDER_TAKER_SENDER = 111;
    // takerSubaccountIndex = takerSenderIndex + bytesSizeAddress
    uint16 private constant MATCH_ORDER_TAKER_SUBACCOUNT = 131;
    // takerQuantityIndex = takerSubaccountIndex + bytesSizeBytes32
    uint16 private constant MATCH_ORDER_TAKER_QUANTITY = 163;
    // takerPriceIndex = takerQuantityIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_TAKER_PRICE = 179;
    // takerReduceOnlyIndex = takerPriceIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_TAKER_REDUCE_ONLY = 195;
    // takerSizeIndex = takerReduceOnlyIndex + bytesSizeBool
    uint16 private constant MATCH_ORDER_TAKER_SIDE = 196;
    // takerNonceIndex = takerSizeIndex + bytesSizeUint8
    uint16 private constant MATCH_ORDER_TAKER_NONCE = 197;
    // takerSignedAtIndex = takerNonceIndex + bytesSizeUint64
    uint16 private constant MATCH_ORDER_TAKER_SIGNED_AT = 205;
    // engineTypeIndex = takerSignedAtIndex + bytesSizeUint64
    uint16 private constant MATCH_ORDER_ENGINE_TYPE = 213;
    // productIdIndex = engineTypeIndex + bytesSizeUint8
    uint16 private constant MATCH_ORDER_PRODUCT_ID = 214;
    // makerFeeIndex = productIdIndex + bytesSizeUint32
    uint16 private constant MATCH_ORDER_MAKER_FEE = 218;
    // takerFeeIndex = makerFeeIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_TAKER_FEE = 234;
    // makerRealizedPnlIndex = takerFeeIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_MAKER_REALIZED_PNL = 250;
    // takerRealizedPnlIndex = makerRealizedPnlIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_TAKER_REALIZED_PNL = 266;
    // fillQuantityIndex = takerRealizedPnlIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_FILL_QUANTITY = 282;
    // fillNotionalIndex = fillQuantityIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_FILL_NOTIONAL = 298;
    // messageIndex = fillNotionalIndex + bytesSizeUint128
    uint16 private constant MATCH_ORDER_MESSAGE_IDX = 314;
    // makerSignatureLengthIndex = messageIndex + bytesSizeUint64
    uint16 private constant MATCH_ORDER_MAKER_SIGNATURE_LENGTH = 322;
    // takerSignatureLengthIndex = makerSignatureLengthIndex + bytesSizeUint8
    uint16 private constant MATCH_ORDER_TAKER_SIGNATURE_LENGTH = 323;
    // makerSignatureIndex = takerSignatureLengthIndex + bytesSizeUint8
    uint16 private constant MATCH_ORDER_MAKER_SIGNATURE = 324;

    /// @notice Retrieves the action id and action type from an action payload.
    /// @dev ActionId is 8 bytes in size and position at index 0 across all action types
    /// @dev ActionType is 1 byte in size, positioned after the ActionId across all action types.
    function decodeActionHeader(bytes calldata action) internal pure returns (ActionId, ActionType) {
        if (action.length < ACTION_HEADER_OFFSET) {
            revert InvalidActionEncodingHeader(action.length);
        }

        return
            (
                ActionId.wrap(uint64(bytes8(action[:ACTION_ID_SIZE_BYTES]))),
                ActionType(uint8(action[ACTION_ID_SIZE_BYTES]))
            );
    }

    /// @notice Retrieves a FinalizeDepositAction from an action payload.
    function decodeFinalizeDepositAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.FinalizeDepositAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.FinalizeDepositAction));
    }

    /// @notice Retrieves an InitiateWithdrawAction from an action payload.
    function decodeInitiateWithdrawAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.InitiateWithdrawAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.InitiateWithdrawAction));
    }

    /// @notice Retrieves a LinkSignerAction from an action payload.
    function decodeLinkSignerAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.LinkSignerAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.LinkSignerAction));
    }

    /// @notice Retrieves a LiquidateSubaccountAction from an action payload.
    function decodeLiquidateSubaccountAction(bytes calldata action)
        internal
        pure
        returns (ILiquidation.LiquidateSubaccountAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (ILiquidation.LiquidateSubaccountAction));
    }

    /// @notice Retrieves a LiquidateSubaccountWithCompensationAction from an action payload.
    /// @dev Packed format:
    ///   uint64 messageIdx
    ///   address liquidatedAccount
    ///   bytes32 liquidatedSubaccount
    ///   int128 balanceTransfer
    ///   uint16 numProducts
    ///   uint16 numPreRealizations
    ///   For each liquidated product:
    ///     uint32 productId
    ///     uint8 engineType
    ///     uint64 pythFee
    ///     int128 sizeDelta
    ///     uint16 pythPriceUpdateLength
    ///     bytes pythPriceUpdate
    ///     uint128 cost
    ///     int128 liquidatorRealizedPnl
    ///   For each pre-realization:
    ///     uint32 productId
    ///     int128 costDelta
    ///   uint16[] preRealizationCounts (length = numProducts)
    function decodeLiquidateSubaccountWithCompensationAction(bytes calldata action)
        internal
        pure
        returns (ILiquidation.LiquidateSubaccountWithCompensationAction memory result)
    {
        uint32 pos = ACTION_HEADER_OFFSET;

        // Read header
        result.messageIdx = uint64(bytes8(action[pos:pos + 8]));
        pos += 8;

        result.liquidatedAccount = address(bytes20(action[pos:pos + 20]));
        pos += 20;

        result.liquidatedSubaccount = bytes32(action[pos:pos + 32]);
        pos += 32;

        result.balanceTransfer = int128(uint128(bytes16(action[pos:pos + 16])));
        pos += 16;

        uint16 numProducts = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        uint16 numPreRealizations = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        // Read liquidated products
        result.products = new ILiquidation.LiquidatedProduct[](numProducts);
        for (uint16 p = 0; p < numProducts; p++) {
            result.products[p].productId = uint32(bytes4(action[pos:pos + 4]));
            pos += 4;

            result.products[p].engineType = EngineType(uint8(action[pos]));
            pos += 1;

            result.products[p].pythFee = uint64(bytes8(action[pos:pos + 8]));
            pos += 8;

            result.products[p].sizeDelta = int128(uint128(bytes16(action[pos:pos + 16])));
            pos += 16;

            uint16 pythPriceUpdateLength = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            result.products[p].pythPriceUpdate = action[pos:pos + pythPriceUpdateLength];
            pos += pythPriceUpdateLength;

            result.products[p].cost = uint128(bytes16(action[pos:pos + 16]));
            pos += 16;

            result.products[p].liquidatorRealizedPnl = int128(uint128(bytes16(action[pos:pos + 16])));
            pos += 16;
        }

        // Read pre-realizations
        result.preRealizations = new ILiquidation.RealizePnl[](numPreRealizations);
        for (uint16 r = 0; r < numPreRealizations; r++) {
            result.preRealizations[r].productId = uint32(bytes4(action[pos:pos + 4]));
            pos += 4;

            result.preRealizations[r].costDelta = int128(uint128(bytes16(action[pos:pos + 16])));
            pos += 16;
        }

        // Read pre-realization counts (length = numProducts)
        // If the payload is short, leave counts empty so higher-level validation can fail explicitly.
        if (action.length >= uint256(pos) + uint256(numProducts) * 2) {
            result.preRealizationCounts = new uint16[](numProducts);
            for (uint16 c = 0; c < numProducts; c++) {
                result.preRealizationCounts[c] = uint16(bytes2(action[pos:pos + 2]));
                pos += 2;
            }
        } else {
            result.preRealizationCounts = new uint16[](0);
        }
    }

    /// @notice Decodes a DeleverageLiquidatorAction from an action payload.
    /// @dev Packed format:
    /// @dev   uint64 messageIdx
    /// @dev   uint16 numProducts
    /// @dev   uint16 numUsers
    /// @dev   uint16 numPythUpdates (must equal numProducts - one update per product)
    /// @dev   For each Pyth update (individual update per product):
    /// @dev     uint16 pythUpdateLength
    /// @dev     bytes pythPriceUpdate (length = pythUpdateLength, single feed)
    /// @dev     uint64 pythFee
    /// @dev   uint32[] productIds (length = numProducts, tightly packed)
    /// @dev   For each user:
    /// @dev     address account (20 bytes)
    /// @dev     bytes32 subaccount (32 bytes)
    /// @dev     uint16 numMatches
    /// @dev     For each match:
    /// @dev       uint16 productIndex
    /// @dev       int64 sizeDelta
    /// @dev       uint64 notional
    /// @dev       int64 userRealizedPnl
    /// @dev       int64 liquidatorRealizedPnl
    function decodeDeleverageLiquidatorAction(bytes calldata action)
        internal
        pure
        returns (IDeleverage.DeleverageLiquidatorAction memory result)
    {
        uint32 pos = ACTION_HEADER_OFFSET;

        // Read header
        result.messageIdx = uint64(bytes8(action[pos:pos + 8]));
        pos += 8;

        uint16 numProducts = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        uint16 numUsers = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        uint16 numPythUpdates = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        // Read Pyth updates (one individual update per product)
        result.pythPriceUpdates = new IDeleverage.DeleveragePythUpdate[](numPythUpdates);
        for (uint16 p = 0; p < numPythUpdates; p++) {
            uint16 pythUpdateLength = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            result.pythPriceUpdates[p].pythPriceUpdate = action[pos:pos + pythUpdateLength];
            pos += pythUpdateLength;

            result.pythPriceUpdates[p].pythFee = uint64(bytes8(action[pos:pos + 8]));
            pos += 8;
        }

        // Read product IDs (4 bytes each, tightly packed)
        result.productIds = new uint32[](numProducts);
        for (uint16 i = 0; i < numProducts; i++) {
            result.productIds[i] = uint32(bytes4(action[pos:pos + 4]));
            pos += 4;
        }

        // Read users
        result.users = new IDeleverage.DeleverageUser[](numUsers);
        for (uint16 u = 0; u < numUsers; u++) {
            // Read account (20 bytes)
            result.users[u].account = address(bytes20(action[pos:pos + 20]));
            pos += 20;

            // Read subaccount (32 bytes)
            result.users[u].subaccount = bytes32(action[pos:pos + 32]);
            pos += 32;

            // Read numMatches (2 bytes)
            uint16 numMatches = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            // Read matches
            result.users[u].matches = new IDeleverage.DeleverageUserMatchPacked[](numMatches);
            for (uint16 m = 0; m < numMatches; m++) {
                // productIndex (2 bytes)
                result.users[u].matches[m].productIndex = uint16(bytes2(action[pos:pos + 2]));
                pos += 2;

                // sizeDelta (8 bytes)
                result.users[u].matches[m].sizeDelta = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;

                // notional (8 bytes)
                result.users[u].matches[m].notional = uint64(bytes8(action[pos:pos + 8]));
                pos += 8;

                // userRealizedPnl (8 bytes)
                result.users[u].matches[m].userRealizedPnl = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;

                // liquidatorRealizedPnl (8 bytes)
                result.users[u].matches[m].liquidatorRealizedPnl = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;
            }
        }
    }

    /// @notice Decodes a DeleverageLiquidatorWithCompensationAction from an action payload.
    /// @dev Packed format:
    ///   uint64 messageIdx
    ///   uint16 numProducts
    ///   uint16 numUsers
    ///   uint16 numPythUpdates
    ///   For each Pyth update:
    ///     uint16 pythUpdateLength
    ///     bytes pythPriceUpdate
    ///     uint64 pythFee
    ///   uint32[] productIds
    ///   For each user:
    ///     address account
    ///     bytes32 subaccount
    ///     uint16 numMatches
    ///     uint16 numPreRealizations
    ///     For each match:
    ///       uint16 productIndex
    ///       int64 sizeDelta
    ///       uint64 notional
    ///       int64 userRealizedPnl
    ///       int64 liquidatorRealizedPnl
    ///     For each preRealization:
    ///       uint32 productId
    ///       int128 costDelta
    ///     uint16[] preRealizationCounts (length = numMatches)
    function decodeDeleverageLiquidatorWithCompensationAction(bytes calldata action)
        internal
        pure
        returns (IDeleverage.DeleverageLiquidatorWithCompensationAction memory result)
    {
        uint32 pos = ACTION_HEADER_OFFSET;

        // Read header
        result.messageIdx = uint64(bytes8(action[pos:pos + 8]));
        pos += 8;

        uint16 numProducts = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        uint16 numUsers = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        uint16 numPythUpdates = uint16(bytes2(action[pos:pos + 2]));
        pos += 2;

        // Read Pyth updates (one individual update per product)
        result.pythPriceUpdates = new IDeleverage.DeleveragePythUpdate[](numPythUpdates);
        for (uint16 p = 0; p < numPythUpdates; p++) {
            uint16 pythUpdateLength = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            result.pythPriceUpdates[p].pythPriceUpdate = action[pos:pos + pythUpdateLength];
            pos += pythUpdateLength;

            result.pythPriceUpdates[p].pythFee = uint64(bytes8(action[pos:pos + 8]));
            pos += 8;
        }

        // Read product IDs (4 bytes each)
        result.productIds = new uint32[](numProducts);
        for (uint16 i = 0; i < numProducts; i++) {
            result.productIds[i] = uint32(bytes4(action[pos:pos + 4]));
            pos += 4;
        }

        // Read users
        result.users = new IDeleverage.DeleverageUserChunk[](numUsers);
        for (uint16 u = 0; u < numUsers; u++) {
            // Read account (20 bytes)
            result.users[u].account = address(bytes20(action[pos:pos + 20]));
            pos += 20;

            // Read subaccount (32 bytes)
            result.users[u].subaccount = bytes32(action[pos:pos + 32]);
            pos += 32;

            // Read numMatches (2 bytes)
            uint16 numMatches = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            // Read numPreRealizations (2 bytes)
            uint16 numPreRealizations = uint16(bytes2(action[pos:pos + 2]));
            pos += 2;

            // Read matches
            result.users[u].matches = new IDeleverage.DeleverageUserMatchPacked[](numMatches);
            for (uint16 m = 0; m < numMatches; m++) {
                // productIndex (2 bytes)
                result.users[u].matches[m].productIndex = uint16(bytes2(action[pos:pos + 2]));
                pos += 2;

                // sizeDelta (8 bytes)
                result.users[u].matches[m].sizeDelta = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;

                // notional (8 bytes)
                result.users[u].matches[m].notional = uint64(bytes8(action[pos:pos + 8]));
                pos += 8;

                // userRealizedPnl (8 bytes)
                result.users[u].matches[m].userRealizedPnl = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;

                // liquidatorRealizedPnl (8 bytes)
                result.users[u].matches[m].liquidatorRealizedPnl = int64(uint64(bytes8(action[pos:pos + 8])));
                pos += 8;
            }

            // Read pre-realizations
            result.users[u].preRealizations = new IDeleverage.RealizePnl[](numPreRealizations);
            for (uint16 r = 0; r < numPreRealizations; r++) {
                result.users[u].preRealizations[r].productId = uint32(bytes4(action[pos:pos + 4]));
                pos += 4;

                result.users[u].preRealizations[r].costDelta = int128(uint128(bytes16(action[pos:pos + 16])));
                pos += 16;
            }

            // Read pre-realization counts (length = numMatches)
            // If the payload is short, leave counts empty so higher-level validation can fail explicitly.
            if (action.length >= uint256(pos) + uint256(numMatches) * 2) {
                result.users[u].preRealizationCounts = new uint16[](numMatches);
                for (uint16 c = 0; c < numMatches; c++) {
                    result.users[u].preRealizationCounts[c] = uint16(bytes2(action[pos:pos + 2]));
                    pos += 2;
                }
            } else {
                result.users[u].preRealizationCounts = new uint16[](0);
            }
        }
    }

    /// @notice Decodes and inflates a MatchOrdersAction.
    /// @dev  Expected encoding:
    /// @dev     uint64 actionId;
    /// @dev     uint8 actionType;
    /// @dev     address makerSender;
    /// @dev     bytes32 makerSubaccount;
    /// @dev     uint128 makerQuantity;
    /// @dev     uint128 makerPrice;
    /// @dev     bool makerReduceOnly;
    /// @dev     uint8 makerSide;
    /// @dev     uint64 makerNonce;
    /// @dev     uint64 makerSignedAt;
    /// @dev     address takerSender;
    /// @dev     bytes32 takerSubaccount;
    /// @dev     uint128 takerQuantity;
    /// @dev     uint128 takerPrice;
    /// @dev     bool takerReduceOnly;
    /// @dev     uint8 takerSide;
    /// @dev     uint64 takerNonce;
    /// @dev     uint64 takerSignedAt;
    /// @dev     uint8 engineType;
    /// @dev     uint32 productId;
    /// @dev     uint128 makerFee;
    /// @dev     uint128 takerFee;
    /// @dev     int128 makerRealizedPnl;
    /// @dev     int128 takerRealizedPnl;
    /// @dev     uint128 fillQuantity;
    /// @dev     uint128 fillNotional;
    /// @dev     uint64 messageIdx;
    /// @dev     uint8 makerSignatureLength;
    /// @dev     uint8 takerSignatureLength;
    /// @dev     bytes makerSignature;
    /// @dev     bytes takerSignature;
    function decodeMatchOrdersAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.MatchOrdersAction memory)
    {
        // There must be enough data to read both signature lengths
        if (action.length <= MATCH_ORDER_TAKER_SIGNATURE_LENGTH) {
            (ActionId actionId, ActionType actionType) = decodeActionHeader(action);
            revert InvalidActionEncoding(actionId, actionType);
        }
        uint16 makerSignatureLength = uint8(action[MATCH_ORDER_MAKER_SIGNATURE_LENGTH]);
        uint16 takerSignatureLength = uint8(action[MATCH_ORDER_TAKER_SIGNATURE_LENGTH]);

        // Length must match the sum of all elements of the encoded action
        if (action.length != MATCH_ORDER_MAKER_SIGNATURE + makerSignatureLength + takerSignatureLength) {
            (ActionId actionId, ActionType actionType) = decodeActionHeader(action);
            revert InvalidActionEncoding(actionId, actionType);
        }

        uint32 takerSignatureIndex = MATCH_ORDER_MAKER_SIGNATURE + makerSignatureLength;
        uint32 productId = uint32(bytes4(action[MATCH_ORDER_PRODUCT_ID:]));
        EngineType engineType = EngineType(uint8(action[MATCH_ORDER_ENGINE_TYPE]));

        return IActionHandler.MatchOrdersAction({
            maker: IActionHandler.TradeOrder({
                sender: address(bytes20(action[MATCH_ORDER_MAKER_SENDER:])),
                subaccount: bytes32(action[MATCH_ORDER_MAKER_SUBACCOUNT:]),
                quantity: uint128(bytes16(action[MATCH_ORDER_MAKER_QUANTITY:])),
                price: uint128(bytes16(action[MATCH_ORDER_MAKER_PRICE:])),
                reduceOnly: uint8(action[MATCH_ORDER_MAKER_REDUCE_ONLY]) == 1,
                side: OrderSide(uint8(action[MATCH_ORDER_MAKER_SIDE])),
                engineType: engineType,
                productId: productId,
                nonce: uint64(bytes8(action[MATCH_ORDER_MAKER_NONCE:])),
                signedAt: uint64(bytes8(action[MATCH_ORDER_MAKER_SIGNED_AT:]))
            }),
            taker: IActionHandler.TradeOrder({
                sender: address(bytes20(action[MATCH_ORDER_TAKER_SENDER:])),
                subaccount: bytes32(action[MATCH_ORDER_TAKER_SUBACCOUNT:]),
                quantity: uint128(bytes16(action[MATCH_ORDER_TAKER_QUANTITY:])),
                price: uint128(bytes16(action[MATCH_ORDER_TAKER_PRICE:])),
                reduceOnly: uint8(action[MATCH_ORDER_TAKER_REDUCE_ONLY]) == 1,
                side: OrderSide(uint8(action[MATCH_ORDER_TAKER_SIDE])),
                engineType: engineType,
                productId: productId,
                nonce: uint64(bytes8(action[MATCH_ORDER_TAKER_NONCE:])),
                signedAt: uint64(bytes8(action[MATCH_ORDER_TAKER_SIGNED_AT:]))
            }),
            makerFee: uint128(bytes16(action[MATCH_ORDER_MAKER_FEE:])),
            takerFee: uint128(bytes16(action[MATCH_ORDER_TAKER_FEE:])),
            makerRealizedPnl: int128(uint128(bytes16(action[MATCH_ORDER_MAKER_REALIZED_PNL:]))),
            takerRealizedPnl: int128(uint128(bytes16(action[MATCH_ORDER_TAKER_REALIZED_PNL:]))),
            fillQuantity: uint128(bytes16(action[MATCH_ORDER_FILL_QUANTITY:])),
            fillNotional: uint128(bytes16(action[MATCH_ORDER_FILL_NOTIONAL:])),
            messageIdx: uint64(bytes8(action[MATCH_ORDER_MESSAGE_IDX:])),
            makerSignature: bytes(action[MATCH_ORDER_MAKER_SIGNATURE:takerSignatureIndex]),
            takerSignature: bytes(action[takerSignatureIndex:takerSignatureIndex + takerSignatureLength])
        });
    }

    /// @notice Retrieves a RevokeLinkedSignerAction from an action payload.
    function decodeRevokeLinkedSignerAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.RevokeLinkedSignerAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.RevokeLinkedSignerAction));
    }

    /// @notice Retrieves an UpdateFundingAction from an action payload.
    function decodeUpdateFundingAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.UpdateFundingAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.UpdateFundingAction));
    }

    /// @notice Retrieves a FinalizePerpProductUpdateAction from an action payload.
    function decodeFinalizePerpProductUpdateAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.FinalizePerpProductUpdateAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.FinalizePerpProductUpdateAction));
    }

    /// @notice Retrieves an UpdatePositionFeeAction from an action payload.
    function decodeUpdatePositionFeeAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.UpdatePositionFeeAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.UpdatePositionFeeAction));
    }

    /// @notice Retrieves a RealizeFundingAction from an action payload.
    function decodeRealizeFundingAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.RealizeFundingAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.RealizeFundingAction));
    }

    /// @notice Retrieves a RealizePnlAction from an action payload.
    function decodeRealizePnlAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.RealizePnlAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.RealizePnlAction));
    }

    /// @notice Retrieves a ConvertTokenAction from an action payload.
    function decodeConvertTokenAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.ConvertTokenAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.ConvertTokenAction));
    }

    /// @notice Retrieves an InitiatePerpProductDelistAction from an action payload.
    function decodeInitiatePerpProductDelistAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.InitiatePerpProductDelistAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.InitiatePerpProductDelistAction));
    }

    /// @notice Retrieves a FinalizePerpProductDelistAction from an action payload.
    function decodeFinalizePerpProductDelistAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.FinalizePerpProductDelistAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.FinalizePerpProductDelistAction));
    }

    /// @notice Retrieves a PerpProductDelistPositionSettlementAction from an action payload.
    function decodePerpProductDelistPositionSettlementAction(bytes calldata action)
        internal
        pure
        returns (IActionHandler.PerpProductDelistPositionSettlementAction memory)
    {
        return abi.decode(action[ACTION_HEADER_OFFSET:], (IActionHandler.PerpProductDelistPositionSettlementAction));
    }
}
