// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import {
    EIP712,
    ECDSA
} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    OfframpStorage,
    CegaOfframpStorage
} from "../../storage/OfframpStorage.sol";
import { IOfframpEntry } from "./interfaces/IOfframpEntry.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { OfframpOrder, OfframpOrderData } from "../../Structs.sol";
import { Errors } from "../../utils/Errors.sol";
import { OrderLib } from "./lib/OrderLib.sol";
import { Transfers } from "../../utils/Transfers.sol";

contract OfframpEntry is IOfframpEntry, EntryBase, OfframpStorage, EIP712 {
    using OrderLib for OfframpOrder;
    using SafeERC20 for IERC20;
    using Transfers for address;
    using SafeCast for uint256;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager
    ) EntryBase(_addressManager) EIP712("Cega Offramp Entry", "1") {}

    // VIEW FUNCTIONS

    function hashOrder(
        OfframpOrder calldata order
    ) external view returns (bytes32 orderHash) {
        return _hashOrder(order);
    }

    function getOfframpFeeBps() external view returns (uint16) {
        CegaOfframpStorage storage cos = getOfframpStorage();
        return cos.offrampFeeBps;
    }

    function getOrderData(
        address maker,
        bytes32 orderHash
    ) external view returns (OfframpOrderData memory) {
        CegaOfframpStorage storage cos = getOfframpStorage();
        return cos.orderData[maker][orderHash];
    }

    // MUTATIVE FUNCTIONS

    function setOfframpFeeBps(uint16 offrampFeeBps) external onlyCegaAdmin {
        CegaOfframpStorage storage cos = getOfframpStorage();

        cos.offrampFeeBps = offrampFeeBps;

        emit OfframpFeeBpsUpdated(offrampFeeBps);
    }

    function cancelOrder(bytes32 orderHash) external nonReentrant {
        CegaOfframpStorage storage cos = getOfframpStorage();

        require(
            !cos.orderData[msg.sender][orderHash].cancelled,
            Errors.ORDER_CANCELLED
        );

        cos.orderData[msg.sender][orderHash].cancelled = true;

        emit OrderCancelled(msg.sender, orderHash);
    }

    function fillOrder(
        OfframpOrder calldata order,
        bytes calldata makerSig,
        uint256 swapMakingAmount
    )
        external
        payable
        onlyValidVault(order.makerAsset)
        nonReentrant
        returns (uint256 swapTakingAmount, bytes32 orderHash)
    {
        orderHash = _hashOrder(order);

        CegaOfframpStorage storage cos = getOfframpStorage();
        OfframpOrderData memory orderData = cos.orderData[order.maker][
            orderHash
        ];

        require(!orderData.cancelled, Errors.ORDER_CANCELLED);

        // Check signature only on the first fill
        if (orderData.filledAmount == 0) {
            require(
                order.maker != address(0) &&
                    ECDSA.recover(orderHash, makerSig) == order.maker,
                Errors.INVALID_SIGNATURE
            );
        }

        require(order.isNotExpired(), Errors.ORDER_EXPIRED);

        if (order.allowsPartialFills()) {
            require(
                swapMakingAmount + orderData.filledAmount <= order.makingAmount,
                Errors.VALUE_TOO_LARGE
            );
        } else {
            require(
                swapMakingAmount + orderData.filledAmount == order.makingAmount,
                Errors.VALUE_TOO_LARGE
            );
        }

        uint256 fee;
        (swapTakingAmount, fee) = order.calculateTakingAmountAndFee(
            swapMakingAmount,
            cos.offrampFeeBps
        );

        if (order.takerAsset == address(0)) {
            require(msg.value == swapTakingAmount, Errors.VALUE_TOO_SMALL);
        }

        cos.orderData[order.maker][orderHash].filledAmount = (orderData
            .filledAmount + swapMakingAmount).toUint128();

        IERC20(order.makerAsset).safeTransferFrom(
            order.maker,
            msg.sender,
            swapMakingAmount
        );

        if (fee > 0) {
            order.takerAsset.receiveTo(
                addressManager.getCegaFeeReceiver(),
                fee
            );
        }
        order.takerAsset.receiveTo(order.maker, swapTakingAmount - fee);

        emit OrderFilled(
            order.maker,
            msg.sender,
            orderHash,
            order.makerAsset,
            order.takerAsset,
            swapMakingAmount,
            swapTakingAmount
        );
    }

    // INTERNAL FUNCTIONS

    function _hashOrder(
        OfframpOrder calldata order
    ) internal view returns (bytes32) {
        return _hashTypedDataV4(order.hash());
    }
}
