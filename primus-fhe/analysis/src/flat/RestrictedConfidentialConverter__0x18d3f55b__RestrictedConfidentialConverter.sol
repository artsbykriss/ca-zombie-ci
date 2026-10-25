// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {ConfidentialConverter} from "./ConfidentialConverter.sol";

/**
 * @title RestrictedConfidentialConverter
 * @dev A {ConfidentialConverter} variant with an optional owner-managed transfer restriction
 * ({setTransferWhitelist} / {setTransferRestrictionEnabled}) that pins the token to whitelisted rails:
 * while enabled, only whitelisted accounts may mint (shield) or burn (unshield), and plain transfers
 * require a whitelisted counterparty. Off by default; both setters are owner-only and idempotent, so
 * upgrades enable it with plain `setTransferWhitelist(...)` calls followed by
 * `setTransferRestrictionEnabled(true)`.
 *
 * This is a dedicated converter for reward-tracked share tokens (e.g. esUSDu): pinning balances to the
 * mint/redeem aggregator rails keeps an external reward ledger (UnitasRewardPool) from ever desyncing
 * from real holdings. It is deliberately a separate contract from {ConfidentialConverter} so the plain
 * converters (e.g. eUSDT) carry no such capability at all — their implementation has no code path that
 * could freeze transfers, keeping the trust assumptions of the underlying issuer unchanged.
 *
 * WARNING: minting assumes the entire underlying transfer was received, so fee-on-transfer or deflationary
 * tokens are not supported.
 */
contract RestrictedConfidentialConverter is ConfidentialConverter {
    /// @custom:storage-location erc7201:primus.fhetransform.storage.RestrictedConfidentialConverter
    struct RestrictedConfidentialConverterStorage {
        /// @dev Accounts allowed to mint/burn this token and to be a counterparty to transfers while
        /// the transfer restriction is enabled (e.g. the mint/redeem aggregators of esUSDu).
        mapping(address account => bool allowed) _transferWhitelist;
        /// @dev When true, {_update} only allows mints/burns by whitelisted callers and transfers
        /// where at least one side is whitelisted. Defaults to false (unrestricted).
        bool _transferRestrictionEnabled;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.RestrictedConfidentialConverter")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RESTRICTED_CONFIDENTIAL_CONVERTER_STORAGE_LOCATION =
        0x56da46350d9c27bb2325de99ab1f78e6a80ae010dea721cdbc4ac535cc7e7600;

    /// @dev Emitted when `account` is added to or removed from the transfer whitelist.
    event TransferWhitelistSet(address indexed account, bool allowed);

    /// @dev Emitted when the transfer restriction is enabled or disabled.
    event TransferRestrictionEnabledSet(bool enabled);

    /// @dev A non-whitelisted `caller` attempted to mint (shield) while the transfer restriction is on.
    error RestrictedMint(address caller);

    /// @dev A non-whitelisted `caller` attempted to burn (unshield) while the transfer restriction is on.
    error RestrictedBurn(address caller);

    /// @dev A transfer between two non-whitelisted accounts was attempted while the restriction is on.
    error RestrictedTransfer(address from, address to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _getRestrictedConfidentialConverterStorage()
        internal
        pure
        returns (RestrictedConfidentialConverterStorage storage $)
    {
        assembly {
            $.slot := RESTRICTED_CONFIDENTIAL_CONVERTER_STORAGE_LOCATION
        }
    }

    /// @dev Adds `account` to (`allowed` = true) or removes it from the transfer whitelist. Used while
    /// the transfer restriction is enabled to pin this token's flow to whitelisted counterparties
    /// (e.g. the esUSDu mint/redeem aggregators). Owner only.
    function setTransferWhitelist(address account, bool allowed) external virtual onlyOwner {
        _setTransferWhitelist(account, allowed);
    }

    /// @dev Enables or disables the transfer restriction. Owner only. Disabling restores the fully
    /// permissionless transfer behavior; the whitelist is kept for the next activation.
    function setTransferRestrictionEnabled(bool enabled) external virtual onlyOwner {
        _setTransferRestrictionEnabled(enabled);
    }

    /// @dev Whether `account` is on the transfer whitelist.
    function isTransferWhitelisted(address account) public view virtual returns (bool) {
        return _getRestrictedConfidentialConverterStorage()._transferWhitelist[account];
    }

    /// @dev Whether the transfer restriction is enabled.
    function transferRestrictionEnabled() public view virtual returns (bool) {
        return _getRestrictedConfidentialConverterStorage()._transferRestrictionEnabled;
    }

    function _setTransferWhitelist(address account, bool allowed) internal virtual {
        _getRestrictedConfidentialConverterStorage()._transferWhitelist[account] = allowed;
        emit TransferWhitelistSet(account, allowed);
    }

    function _setTransferRestrictionEnabled(bool enabled) internal virtual {
        _getRestrictedConfidentialConverterStorage()._transferRestrictionEnabled = enabled;
        emit TransferRestrictionEnabledSet(enabled);
    }

    /**
     * @dev Transfer restriction (off by default; see {setTransferRestrictionEnabled}). While enabled, this
     * token only moves along whitelisted rails: mints (shield) and burns (unshield) require a whitelisted
     * caller, and plain transfers require at least one whitelisted side. For esUSDu the whitelist holds the
     * mint and redeem aggregators, so a user's balance can only change through the mint claim and the redeem
     * deposit — the exact two events the UnitasRewardPool ledger tracks — keeping `sum(positions)` equal to
     * the real staked supply. Every entry point (transfer/transferFrom/transferAndCall variants, operator
     * spends, mints and burns) funnels through {_update}, so this single check covers them all.
     */
    function _requireTransferAllowed(address from, address to) internal view virtual {
        RestrictedConfidentialConverterStorage storage $ = _getRestrictedConfidentialConverterStorage();
        if (!$._transferRestrictionEnabled) return;
        if (from == address(0)) {
            // Mint via {shield}: only a whitelisted aggregator may create supply.
            require($._transferWhitelist[msg.sender], RestrictedMint(msg.sender));
        } else if (to == address(0)) {
            // Burn via {unshield}: only a whitelisted aggregator may destroy supply.
            require($._transferWhitelist[msg.sender], RestrictedBurn(msg.sender));
        } else {
            // Plain transfer: aggregator -> user (claim / quit refund) or user -> aggregator (deposit).
            require($._transferWhitelist[from] || $._transferWhitelist[to], RestrictedTransfer(from, to));
        }
    }

    /// @dev Adds the transfer-restriction check on top of the {ConfidentialConverter} denylist enforcement.
    function _update(address from, address to, ve_uint64 amount) internal virtual override returns (ve_uint64) {
        _requireTransferAllowed(from, to);
        return super._update(from, to, amount);
    }
}
