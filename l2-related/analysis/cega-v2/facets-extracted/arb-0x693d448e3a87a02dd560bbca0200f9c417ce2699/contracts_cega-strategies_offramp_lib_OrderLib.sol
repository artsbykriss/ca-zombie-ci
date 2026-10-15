// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { OfframpOrder } from "../../../Structs.sol";

library OrderLib {
    // CONSTANTS

    /// @notice EIP712 order typehash
    bytes32 internal constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(uint256 salt,uint256 makingAmount,uint256 takingAmount,address maker,address makerAsset,address takerAsset,uint256 expiry,uint256 makerTraits)"
            )
        );

    uint256 internal constant BPS_DECIMALS = 1e4;

    uint256 private constant NO_PARTIAL_FILLS_FLAG = 1 << 255;

    // FUNCTIONS

    function hash(OfframpOrder calldata order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.salt,
                    order.makingAmount,
                    order.takingAmount,
                    order.maker,
                    order.makerAsset,
                    order.takerAsset,
                    order.expiry,
                    order.makerTraits
                )
            );
    }

    function calculateTakingAmountAndFee(
        OfframpOrder calldata order,
        uint256 swapMakingAmount,
        uint16 feeBps
    ) internal pure returns (uint256 takingAmount, uint256 fee) {
        // Round up division to block taker from profiting by splitting order
        takingAmount =
            (swapMakingAmount * order.takingAmount + order.makingAmount - 1) /
            order.makingAmount;
        fee = (takingAmount * feeBps) / BPS_DECIMALS;
    }

    function isNotExpired(
        OfframpOrder calldata order
    ) internal view returns (bool) {
        return block.timestamp <= order.expiry;
    }

    // MAKER TRAITS

    function allowsPartialFills(
        OfframpOrder calldata order
    ) internal pure returns (bool) {
        return (order.makerTraits & NO_PARTIAL_FILLS_FLAG) == 0;
    }
}
