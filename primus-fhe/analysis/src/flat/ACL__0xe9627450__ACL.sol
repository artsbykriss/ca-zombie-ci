// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {ACLEvents} from "./ACLEvents.sol";
import {IACL, PermissionType} from "./IACL.sol";

/**
 * @notice The ACL (Access Control List) is a permission management system.
 */
contract ACL is OwnableUpgradeable, PausableUpgradeable, IACL, ACLEvents, MulticallUpgradeable {
    /// @notice Returned if the handlesList array is empty.
    error HandlesListIsEmpty();
    /// @notice Returned if the sender address is not allowed for allow operations.
    error SenderNotAllowed(address sender);

    struct ACLStorage {
        mapping(bytes32 handle => mapping(address account => bool isAllowed)) persistedAllowedPairs;
        mapping(bytes32 handle => mapping(address account => bool isAllowed)) persistedDecryptionPairs;
        mapping(bytes32 handle => bool isAllowedForDecryption) allowedForDecryption;
    }

    string private constant CONTRACT_NAME = "ACL";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    /// @notice The FHEExecutor contract address.
    address private fheExecutorAddress;

    /// keccak256(abi.encode(uint256(keccak256("primus.fhe.storage.ACL")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant ACLStorageLocation = 0x31bf31e8cacfdd78fe4be4479b2612f91d54e60094c080a2b577c4edba0e5b00;

    /**
     * @notice Initializes the contract.
     */
    function initialize(address owner) public initializer {
        require(owner != address(0), "Owner cannot be zero");

        __Ownable_init(owner);
        __Pausable_init();
    }

    /**
     * @notice Pauses all permission mutations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses permission mutations.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @param addr The FHEExecutor address
     */
    function setFheExecutorAddress(address addr) external onlyOwner {
        require(addr != address(0), "FHEExecutor cannot be zero");
        fheExecutorAddress = addr;
    }

    /**
     * @notice Allows the use of `handle` for the address `account`.
     */
    function allow(bytes32 handle, address account) public virtual whenNotPaused {
        ACLStorage storage $ = _getACLStorage();
        if (!isAllowed(handle, msg.sender)) {
            revert SenderNotAllowed(msg.sender);
        }
        $.persistedAllowedPairs[handle][account] = true;
        emit Allowed(msg.sender, account, handle);
    }

    /**
     * @notice Allows a list of handles to be decrypted.
     */
    function allowForDecryption(bytes32[] memory handlesList) public virtual whenNotPaused {
        uint256 lenHandlesList = handlesList.length;
        if (lenHandlesList == 0) {
            revert HandlesListIsEmpty();
        }

        ACLStorage storage $ = _getACLStorage();
        for (uint256 k = 0; k < lenHandlesList; k++) {
            bytes32 handle = handlesList[k];
            if (!isAllowed(handle, msg.sender)) {
                revert SenderNotAllowed(msg.sender);
            }
            $.allowedForDecryption[handle] = true;
        }
        emit AllowedForDecryption(msg.sender, handlesList);
    }

    /**
     * @notice Allows the use of `handle` by address `account` for this transaction.
     */
    function allowTransient(bytes32 handle, address account) public virtual whenNotPaused {
        if (msg.sender != fheExecutorAddress) {
            if (!isAllowed(handle, msg.sender)) {
                revert SenderNotAllowed(msg.sender);
            }
        }
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            tstore(key, 1)
            let length := tload(0)
            let lengthPlusOne := add(length, 1)
            tstore(lengthPlusOne, key)
            tstore(0, lengthPlusOne)
        }
    }

    /**
     * @notice Allows the use of `handle` for the address `account`.
     */
    function accessPolicy(bytes32 handle, address account, PermissionType pt) public virtual whenNotPaused {
        if (pt == PermissionType.Persistent) {
            allow(handle, account);
        } else if (pt == PermissionType.Transient) {
            allowTransient(handle, account);
        } else {
            // bytes32[] memory handleArray = new bytes32[](1);
            // handleArray[0] = handle;
            // allowForDecryption(handleArray);
            ACLStorage storage $ = _getACLStorage();
            if (!isAllowed(handle, msg.sender)) {
                revert SenderNotAllowed(msg.sender);
            }
            $.persistedDecryptionPairs[handle][account] = true;
            emit Allowed(msg.sender, account, handle);
        }
    }
    function accessPolicy(bytes32 handle, address account) public virtual {
        return accessPolicy(handle, account, PermissionType.Persistent);
    }

    /**
     * @notice Checks whether the account is allowed to use the handle in the same transaction (transient).
     */
    function allowedTransient(bytes32 handle, address account) public view virtual returns (bool) {
        bool isAllowedTransient;
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            isAllowedTransient := tload(key)
        }
        return isAllowedTransient;
    }

    /**
     * @notice Returns whether the `account` is allowed to use the `handle`.
     */
    function isAllowed(bytes32 handle, address account) public view virtual returns (bool) {
        return allowedTransient(handle, account) || persistAllowed(handle, account);
    }

    /**
     * @notice Checks whether a `handle` is allowed for decryption.
     */
    function isAllowedForDecryption(bytes32 handle) public view virtual returns (bool) {
        return isAllowedForDecryption(handle, msg.sender);
    }
    function isAllowedForDecryption(bytes32 handle, address account) public view virtual returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        return $.allowedForDecryption[handle] || $.persistedDecryptionPairs[handle][account];
    }

    /**
     * @notice Returns `true` if address `account` is allowed to use `handle` and `false` otherwise.
     */
    function persistAllowed(bytes32 handle, address account) public view virtual returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        return $.persistedAllowedPairs[handle][account];
    }

    /**
     * @notice Removes the transient allowances.
     */
    function cleanTransientStorage() external virtual {
        require(msg.sender == fheExecutorAddress, "Only FHEExecutor");
        assembly {
            let length := tload(0)
            tstore(0, 0)
            let lengthPlusOne := add(length, 1)
            for {
                let i := 1
            } lt(i, lengthPlusOne) {
                i := add(i, 1)
            } {
                let handle := tload(i)
                tstore(i, 0)
                tstore(handle, 0)
            }
        }
    }

    /**
     * @notice Getter for the name and version of the contract.
     */
    function getVersion() external pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    CONTRACT_NAME,
                    " v",
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }

    /**
     * @notice Returns the ACL storage location.
     */
    function _getACLStorage() internal pure returns (ACLStorage storage $) {
        assembly {
            $.slot := ACLStorageLocation
        }
    }
}
