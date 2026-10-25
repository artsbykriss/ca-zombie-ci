// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ERC1271Wallet
 * @notice Test smart wallet that approves, through ERC-1271, any hash signed by one fixed
 *         key. The key is an immutable, i.e. part of the code, so the same behaviour holds
 *         when this code is placed at another address (hardhat_setCode) or used as an
 *         EIP-7702 delegate, where the account's own storage is empty.
 * @dev Not for production.
 */
contract ERC1271Wallet {
    address public immutable signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        (address recovered, ECDSA.RecoverError err,) = ECDSA.tryRecover(hash, signature);
        return err == ECDSA.RecoverError.NoError && recovered == signer ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }
}
