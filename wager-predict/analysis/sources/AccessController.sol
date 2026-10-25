// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24; // Phase 2 baseline: OZ 5.6.1 access extensions require >=0.8.24

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

/// @title  AccessController
/// @notice Central role registry for Predict Phase 2 (spec §2). Every protocol contract
///         references this single contract for authorization (`hasRole` / `requireRole`),
///         so the entire role set is granted, revoked, enumerated and audited in ONE place
///         instead of being duplicated across every module.
/// @dev    Roles (spec §2):
///           - GOVERNANCE     : multisig — sets bounded params, pauses, seeds insurance.
///           - CREATOR        : team / MM — creates featured markets (skip review).
///           - REVIEWER       : team — approves/rejects submitted markets.
///           - RESOLVER       : multisig — finalizes resolution / disputes.
///           - MM             : the (max `maxMarketMakers`, default 2) MM signing addresses.
///           - PAUSE_GUARDIAN : multisig — trips reduce-only / pause.
///         Permissionless liquidation (spec §2) needs NO role and is intentionally absent.
///
///         Role administration: GOVERNANCE_ROLE is the admin of every *operational* role;
///         DEFAULT_ADMIN_ROLE (the root) administers GOVERNANCE_ROLE itself. Both are held
///         by the governance multisig at genesis.
///
///         The *dynamic* role-conflict invariant — "RESOLVER / proposer must hold no
///         position in a market they resolve/propose" (spec §12.9) — is position-dependent
///         and therefore enforced in the ResolutionModule, NOT here. This contract owns the
///         *static* invariant: at most `maxMarketMakers` addresses may hold MM_ROLE (spec §8).
contract AccessController is AccessControlEnumerable {
    // ─── Roles ────────────────────────────────────────────────────────────────
    bytes32 public constant GOVERNANCE_ROLE     = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CREATOR_ROLE        = keccak256("CREATOR_ROLE");
    bytes32 public constant REVIEWER_ROLE       = keccak256("REVIEWER_ROLE");
    bytes32 public constant RESOLVER_ROLE       = keccak256("RESOLVER_ROLE");
    bytes32 public constant MM_ROLE             = keccak256("MM_ROLE");
    bytes32 public constant PAUSE_GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");
    /// @notice Operational roles consumed by MarketRegistry — the spot engine that records
    ///         trades, and the resolution module. Declared here so they get an explicit
    ///         GOVERNANCE_ROLE admin (L4), instead of falling back to the root DEFAULT_ADMIN_ROLE.
    bytes32 public constant TRADE_RECORDER_ROLE = keccak256("TRADE_RECORDER_ROLE");
    bytes32 public constant RESOLUTION_ROLE     = keccak256("RESOLUTION_ROLE");

    // ─── MM cap (the one static role-conflict invariant this contract owns) ─────
    /// @notice Max number of addresses that may simultaneously hold MM_ROLE (spec §8: two MMs).
    uint256 public maxMarketMakers;

    uint256 public constant MIN_MAX_MARKET_MAKERS = 1;
    uint256 public constant MAX_MAX_MARKET_MAKERS = 10;

    // ─── Errors ───────────────────────────────────────────────────────────────
    error ZeroGovernance();
    error NotAuthorized(bytes32 role, address account);
    error MarketMakerCapReached(uint256 cap);
    error MaxMarketMakersOutOfRange(uint256 value);
    error CannotShrinkBelowMembers(uint256 currentMembers);

    // ─── Events ───────────────────────────────────────────────────────────────
    event MaxMarketMakersUpdated(uint256 previous, uint256 current);

    /// @param governance The governance multisig — receives DEFAULT_ADMIN_ROLE + GOVERNANCE_ROLE.
    constructor(address governance) {
        if (governance == address(0)) revert ZeroGovernance();

        // Root admin manages GOVERNANCE_ROLE; GOVERNANCE_ROLE manages every operational role.
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(GOVERNANCE_ROLE, governance);

        _setRoleAdmin(GOVERNANCE_ROLE,     DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CREATOR_ROLE,        GOVERNANCE_ROLE);
        _setRoleAdmin(REVIEWER_ROLE,       GOVERNANCE_ROLE);
        _setRoleAdmin(RESOLVER_ROLE,       GOVERNANCE_ROLE);
        _setRoleAdmin(MM_ROLE,             GOVERNANCE_ROLE);
        _setRoleAdmin(PAUSE_GUARDIAN_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(TRADE_RECORDER_ROLE, GOVERNANCE_ROLE); // L4: explicit GOVERNANCE admin, not root
        _setRoleAdmin(RESOLUTION_ROLE,     GOVERNANCE_ROLE);

        maxMarketMakers = 2; // spec §8 default
        emit MaxMarketMakersUpdated(0, 2);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Revert with {NotAuthorized} unless `account` holds `role`.
    /// @dev    Convenience guard for consumer contracts: `controller.requireRole(CREATOR_ROLE, msg.sender)`.
    function requireRole(bytes32 role, address account) external view {
        if (!hasRole(role, account)) revert NotAuthorized(role, account);
    }

    // ─── Governance ───────────────────────────────────────────────────────────

    /// @notice Set the cap on concurrent MM_ROLE holders (bounded, evented; spec §11 discipline).
    /// @dev    Cannot be set below the number of addresses that already hold MM_ROLE, which
    ///         would otherwise leave the system in a state violating the cap invariant.
    /// @param  newMax New cap, within [MIN_MAX_MARKET_MAKERS, MAX_MAX_MARKET_MAKERS].
    function setMaxMarketMakers(uint256 newMax) external onlyRole(GOVERNANCE_ROLE) {
        if (newMax < MIN_MAX_MARKET_MAKERS || newMax > MAX_MAX_MARKET_MAKERS) {
            revert MaxMarketMakersOutOfRange(newMax);
        }
        uint256 members = getRoleMemberCount(MM_ROLE);
        if (newMax < members) revert CannotShrinkBelowMembers(members);

        uint256 prev = maxMarketMakers;
        maxMarketMakers = newMax;
        emit MaxMarketMakersUpdated(prev, newMax);
    }

    // ─── Internal: enforce the MM cap on EVERY grant path ──────────────────────

    /// @dev Overrides the grant hook so the MM cap holds regardless of which entry point
    ///      (grantRole, or any future internal grant) is used. A re-grant to an existing
    ///      holder is idempotent and does not consume cap.
    function _grantRole(bytes32 role, address account)
        internal
        override
        returns (bool)
    {
        if (role == MM_ROLE && !hasRole(MM_ROLE, account)) {
            if (getRoleMemberCount(MM_ROLE) >= maxMarketMakers) {
                revert MarketMakerCapReached(maxMarketMakers);
            }
        }
        return super._grantRole(role, account);
    }
}
