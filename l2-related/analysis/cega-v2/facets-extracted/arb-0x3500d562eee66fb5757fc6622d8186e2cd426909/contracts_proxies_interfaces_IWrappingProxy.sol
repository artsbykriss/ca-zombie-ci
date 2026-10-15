// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface IWrappingProxy {
    /**
     * @notice Unwraps the wrapped token and transfers the underlying token to the receiver.
     * @param receiver The address to receive the unwrapped tokens.
     * @param amount The amount of wrapped tokens to unwrap.
     */
    function unwrapAndTransfer(address receiver, uint256 amount) external;

    /**
     * @notice Wraps the token and adds it to the generic deposit queue.
     * @param productId The product ID for the deposit.
     * @param amount The amount of tokens to wrap.
     * @param receiver The address that will receive the deposit queue shares.
     */
    function wrapAndAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external;
}
