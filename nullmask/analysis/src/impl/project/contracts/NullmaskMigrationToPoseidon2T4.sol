// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {State} from "./State.sol";
import {MerkleTree, MerkleTreeData, RootSet} from "./Merkle/MerkleTree.sol";
import {IUpgradeController} from "./upgrade/IUpgradeController.sol";

/**
 * @title NullmaskMigrationToPoseidon2T4
 * @notice One-shot migration contract to rebuild Merkle trees with Poseidon2T4 hashing.
 * @dev Deployed as a UUPS implementation upgrade. The protocol is effectively paused
 *      while this implementation is active (no deposit/transfer/withdraw functions).
 *      After migration, upgrade again to the new Nullmask implementation.
 *
 *      Root history is a persistent set and is deliberately NOT wiped here: it is
 *      unbounded, so clearing it is not something a transaction can do. Roots left over
 *      from before the migration stay in the set but are harmless - they were produced by
 *      the old hash function, and the deployed verifier only accepts proofs built with
 *      the new one, so no proof can be made to satisfy them.
 */
contract NullmaskMigrationToPoseidon2T4 is State, Initializable, UUPSUpgradeable {
    using MerkleTree for MerkleTreeData;
    using MerkleTree for RootSet;

    error NotAdmin(address caller);
    error UpgradeNotAuthorized(address caller);

    modifier onlyAdmin() {
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0)))
            revert NotAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Wipe and rebuild the note tree with new hashing.
     * @param leaves All note commitment leaves in insertion order.
     * @return The new root after rebuilding.
     */
    function migrateNoteTree(uint256[] calldata leaves) external onlyAdmin returns (uint256) {
        // 1. Clear leaves mapping (leaf_value -> index+1)
        for (uint256 i; i < leaves.length;) {
            _noteTree.tree.leaves[leaves[i]] = 0;
            unchecked { ++i; }
        }
        // 2. Clear sideNodes[0..depth]
        uint256 d = _noteTree.tree.depth;
        for (uint256 i; i <= d;) {
            _noteTree.tree.sideNodes[i] = 0;
            unchecked { ++i; }
        }
        // 3. Reset metadata (root history is a persistent set - see the contract doc)
        _noteTree.tree.size = 0;
        _noteTree.tree.depth = 0;
        // 4. Rebuild with Poseidon2T4 via insertMany
        if (leaves.length > 0) {
            _noteTree.insertMany(_noteTreeRoots, leaves);
        }
        return _noteTree.root();
    }

    /**
     * @notice Wipe and rebuild the key registry tree with new hashing.
     * @param leaves All key hash leaves in insertion order.
     * @return The new root after rebuilding.
     */
    function migrateKeyRegistryTree(uint256[] calldata leaves) external onlyAdmin returns (uint256) {
        // 1. Clear leaves mapping
        for (uint256 i; i < leaves.length;) {
            _keyRegistryTree.tree.leaves[leaves[i]] = 0;
            unchecked { ++i; }
        }
        // 2. Clear sideNodes[0..depth]
        uint256 d = _keyRegistryTree.tree.depth;
        for (uint256 i; i <= d;) {
            _keyRegistryTree.tree.sideNodes[i] = 0;
            unchecked { ++i; }
        }
        // 3. Reset metadata (root history is a persistent set - see the contract doc)
        _keyRegistryTree.tree.size = 0;
        _keyRegistryTree.tree.depth = 0;
        // 4. Rebuild
        if (leaves.length > 0) {
            _keyRegistryTree.insertMany(_keyRegistryTreeRoots, leaves);
        }
        return _keyRegistryTree.root();
    }

    // ---- View helpers ----

    function noteTreeRoot() external view returns (uint256) {
        return _noteTree.root();
    }

    function noteTreeSize() external view returns (uint256) {
        return _noteTree.size();
    }

    function keyRegistryRoot() external view returns (uint256) {
        return _keyRegistryTree.root();
    }

    function keyRegistrySize() external view returns (uint256) {
        return _keyRegistryTree.size();
    }

    // ---- UUPS ----

    function _authorizeUpgrade(address newImpl) internal view override {
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, newImpl))
            revert UpgradeNotAuthorized(msg.sender);
    }
}
