// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";

/// @title FablesPoolRegistry
/// @notice Append-only, on-chain list of every Fables pool, so off-chain consumers (a DeFiLlama
///         adapter, the frontend, a subgraph) can enumerate all pools by reading one contract instead
///         of hardcoding per-pool hook addresses.
/// @dev Pure metadata. Holds no funds, has no authority over any hook, pool, ledger or role, makes no
///      external call, and is never called by the protocol itself — only read by off-chain consumers.
///      The worst outcome from a misconfigured or compromised registrar is an inaccurate list, which
///      affects what a reader displays and nothing else: no funds and no protocol state are reachable
///      from here. Writes are `restricted` to the same AccessManager as the rest of Fables; reads are
///      open. Non-upgradeable, no ETH, no token calls, no reentrancy surface.
///
///      A pool is stored as its full v4 PoolKey (currencies, fee, tickSpacing, hook) keyed by its
///      PoolId. The full key matters because v4 does NOT let a reader recover the tokens from a PoolId
///      on-chain (the id is an irreversible hash and the PoolManager never stores the key), so this
///      registry is the on-chain source of the keys a TVL reader needs.
///
///      "Deregister" is a soft retire (the `active` flag), never an array removal: removing would
///      shift every later index and desync event-based indexers. Consumers filter on `active`.
contract FablesPoolRegistry is AccessManaged {
    using PoolIdLibrary for PoolKey;

    error AlreadyRegistered(PoolId id);
    error NotRegistered(PoolId id);
    error NoHook();

    event PoolRegistered(PoolId indexed id, PoolKey key, address indexed hook, uint256 index);
    event PoolDeregistered(PoolId indexed id);
    event PoolReregistered(PoolId indexed id);

    struct PoolInfo {
        PoolKey key; // full v4 key: currency0, currency1, fee, tickSpacing, hooks
        PoolId id; // keccak(key), stored so a reader can index without recomputing it
        bool active; // false once retired; the entry is never removed
    }

    /// @notice Every pool ever registered, in registration order. Append-only.
    PoolInfo[] internal _pools;
    /// @notice One-based slot (index + 1) of a pool in `_pools`; zero means never registered.
    mapping(PoolId id => uint256 slot) internal _slot;

    constructor(address authority_) AccessManaged(authority_) {}

    /// @notice Records a pool. A given pool id can be registered exactly once; use `reregister` to
    ///         bring a retired one back rather than registering it again.
    function register(PoolKey calldata key) external restricted returns (PoolId id) {
        if (address(key.hooks) == address(0)) revert NoHook();
        id = key.toId();
        if (_slot[id] != 0) revert AlreadyRegistered(id);
        _pools.push(PoolInfo({key: key, id: id, active: true}));
        _slot[id] = _pools.length; // length == index + 1
        emit PoolRegistered(id, key, address(key.hooks), _pools.length - 1);
    }

    /// @notice Retires a pool: it stays in the list but is flagged inactive so consumers skip it.
    function deregister(PoolId id) external restricted {
        _pools[_index(id)].active = false;
        emit PoolDeregistered(id);
    }

    /// @notice Un-retires a previously deregistered pool.
    function reregister(PoolId id) external restricted {
        _pools[_index(id)].active = true;
        emit PoolReregistered(id);
    }

    // --- reads (open to anyone) ---

    /// @notice Number of pools ever registered, retired ones included.
    function poolCount() external view returns (uint256) {
        return _pools.length;
    }

    /// @notice Pool at a registration index. Reverts out-of-range like any array read.
    function poolAt(uint256 index) external view returns (PoolInfo memory) {
        return _pools[index];
    }

    /// @notice Whether a pool id has ever been registered (active or retired).
    function isRegistered(PoolId id) external view returns (bool) {
        return _slot[id] != 0;
    }

    /// @notice The record for a registered pool id.
    function poolById(PoolId id) external view returns (PoolInfo memory) {
        return _pools[_index(id)];
    }

    /// @notice The whole list, retired entries included.
    function allPools() external view returns (PoolInfo[] memory) {
        return _pools;
    }

    /// @notice Only the pools currently active — what a TVL reader wants. Fine for a curated registry;
    ///         a very large reader can page with `poolCount` + `poolAt` and filter itself.
    function activePools() external view returns (PoolInfo[] memory active) {
        uint256 n;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i].active) n++;
        }
        active = new PoolInfo[](n);
        uint256 j;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i].active) active[j++] = _pools[i];
        }
    }

    /// @dev Storage index of a registered pool, or revert. Shared by the mutators and `poolById`.
    function _index(PoolId id) internal view returns (uint256) {
        uint256 slot = _slot[id];
        if (slot == 0) revert NotRegistered(id);
        return slot - 1;
    }
}
