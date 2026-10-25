// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SettlementBatcher
 * @notice Test delegate for an EIP-7702 guard account: runs several calls to the pool in
 *         one transaction, each with msg.sender == the guard account itself. Used by
 *         test/Guard.ts to show that a batched guard is not reimbursed the per-transaction
 *         part of the settlement overhead more than once (audit finding 8).
 * @dev Not for production.
 */
contract SettlementBatcher {
    function batch(address target, bytes[] calldata calls) external {
        require(msg.sender == address(this), "self only");
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory ret) = target.call(calls[i]);
            if (!ok) {
                assembly {
                    revert(add(ret, 32), mload(ret))
                }
            }
        }
    }

    receive() external payable {}
}
