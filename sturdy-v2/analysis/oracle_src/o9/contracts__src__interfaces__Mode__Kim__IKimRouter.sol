// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IKimRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;
}