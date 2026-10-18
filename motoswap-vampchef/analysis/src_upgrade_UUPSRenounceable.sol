// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title UUPSRenounceable
/// @notice UUPS mix-in adding an operations-preserving "upgrade-to-immutable" switch (L15).
/// @dev A contract that shares its single `owner` between upgrade authority AND live operational levers
///      (emission schedules, fee buckets, keepers, …) cannot use `renounceOwnership` to freeze upgrades
///      without ALSO permanently bricking those operations. This base provides an INDEPENDENT one-way
///      flag: once `_renounceUpgradeability()` is called, `_requireUpgradable()` makes `_authorizeUpgrade`
///      revert forever, while ownership and every operational setter keep working. Uses ERC-7201
///      namespaced storage, so it adds ZERO sequential storage slots to any inheriting contract (no
///      layout impact, no `__gap` accounting needed for it).
///
/// @dev ONE CONTRACT DOES NOT USE THIS MIX-IN, AND THAT IS INTENTIONAL &mdash; READ THIS BEFORE HARDENING
///      ANYTHING HERE. Twelve UUPS contracts inherit this base. `MotocatStakingV3` does not: it
///      hand-rolls the same mechanism with its own ERC-7201 slot
///      (`0x8dbf43823b97c99adb98436cf84b14f79d8af8d4e690a7ce4245e5f076361d00`) and its own
///      `_authorizeUpgrade`. Same design, two code paths.
///
///      The consequence, recorded because it is the part that bites: any fix or hardening applied to
///      this file SILENTLY MISSES the cats contract, and the sentence "the renounce latch was audited"
///      is ambiguous until someone asks which latch. There is no cross-contamination today, because
///      ERC-7201 storage is per-proxy and the two slots differ.
///
///      WHY IT IS NOT SIMPLY CONVERGED: `MotocatStakingV3` is VENDORED here from its own canonical repo
///      and must not be edited in place (see `script/vendored-motocat-check.sh`), and the deployed
///      mainnet escrow holds roughly 19,800 cats &mdash; so converging is an upgrade to a live contract,
///      not a refactor. Recorded as a deliberate divergence rather than converged, per the
///      reviewers' own either/or. If the cats contract is ever upgraded for another reason, converge it
///      then; that is the moment the cost is already being paid.
abstract contract UUPSRenounceable is UUPSUpgradeable {
    /// @custom:storage-location erc7201:motoswap.storage.UUPSRenounceable
    struct RenounceStorage {
        bool renounced;
    }

    // keccak256(abi.encode(uint256(keccak256("motoswap.storage.UUPSRenounceable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RENOUNCE_STORAGE_SLOT = 0xa5942d98813e409540b6788a82bc0bf3bf6bb19b1d41d7399297cc0ab99b7c00;

    event UpgradesRenounced();

    error UpgradesAreRenounced();

    function _renounceStorage() private pure returns (RenounceStorage storage $) {
        assembly {
            $.slot := RENOUNCE_STORAGE_SLOT
        }
    }

    /// @notice True once the implementation can never be upgraded again (one-way).
    function upgradesRenounced() public view returns (bool) {
        return _renounceStorage().renounced;
    }

    /// @dev Call from `_authorizeUpgrade` to block upgrades once renounced.
    function _requireUpgradable() internal view {
        if (_renounceStorage().renounced) revert UpgradesAreRenounced();
    }

    /// @dev One-way: permanently disables `_authorizeUpgrade`. Ownership and admin ops are unaffected.
    ///      The inheriting contract exposes the access-gated external entrypoint that calls this.
    function _renounceUpgradeability() internal {
        _renounceStorage().renounced = true;
        emit UpgradesRenounced();
    }
}
