// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library Signatures {
    bytes internal constant LINK_SIGNER_ABI_PARAM =
        "LinkSigner(address sender,address signer,bytes32 subaccount,uint64 nonce,uint64 signedAt)";

    bytes internal constant INITIATE_WITHDRAW_ABI_PARAM =
        "InitiateWithdraw(address account,bytes32 subaccount,address token,uint256 amount,uint64 nonce,uint64 signedAt,bytes32 destinationAddress,uint32 destinationEndpointId)";

    bytes internal constant REVOKE_LINKED_SIGNER_ABI_PARAM =
        "RevokeLinkedSigner(address sender,address signer,bytes32 subaccount,uint64 nonce,uint64 signedAt)";

    bytes internal constant TRADE_ORDER_ABI_PARAM =
        "TradeOrder(address sender,bytes32 subaccount,uint128 quantity,uint128 price,bool reduceOnly,uint8 side,uint8 engineType,uint32 productId,uint64 nonce,uint64 signedAt)";

    bytes internal constant CONVERT_TOKEN_ABI_PARAM =
        "ConvertToken(address sender,bytes32 subaccount,address fromToken,address toToken,uint128 amount,uint64 nonce,uint64 signedAt)";
}
