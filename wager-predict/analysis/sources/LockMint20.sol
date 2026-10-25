// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {AccessControl} from "../access/AccessControl.sol";
import {IEvents} from "../interfaces/IEvents.sol";
import {ILockMint20} from "./interfaces/ILockMint20.sol";
import {Constants} from "../libraries/Constants.sol";
import {Errors} from "../libraries/Errors.sol";
import {AddressLib} from "../libraries/AddressLib.sol";
import {MathLib} from "../libraries/MathLib.sol";

/**
 * @title LockMint20
 * @notice Locked-balance upgradeable ERC-20 (+ `AccessControl` pause/blacklist) with mutable `name`/`symbol`, optional mint hook, and {ILockMint20} ledger-operator APIs.
 * @dev Concrete lock ledger: `lockedLedger`, `_lockOf`, `_lckAdd`, `_lckSub`. Child supplies {_requireTokenOperator}; optionally overrides {_onXfer} or `_lckBurn`.
 *      Use {__LockMint20_init} to bundle ERC-20 + AccessControl + metadata init. `setNameAndSymbol` is `onlyAdministrator` — schedulable by `GOVERNOR_ROLE` through the timelock.
 * @dev Underlying fungible surface: {IERC20} and metadata (`name` / `symbol` / `decimals`) via {ERC20Upgradeable}; decimals are {Constants.USDW_TOKEN_DECIMALS}.
 */
abstract contract LockMint20 is ERC20Upgradeable, AccessControl, IEvents, ILockMint20 {
    using AddressLib for address;
    using MathLib for uint256;

    /// @notice Mutable ERC-20 name (initialized by {_metaInit}; operator may {setNameAndSymbol}).
    string internal _custName;

    /// @notice Mutable ERC-20 symbol (initialized by {_metaInit}; operator may {setNameAndSymbol}).
    string internal _custSymbol;

    /// @notice Token units locked per account — excluded from spendable {balanceOf} (USDW redemption queue).
    mapping(address account => uint256 amount) internal lockedLedger;

    /**
     * @dev Storage gap for future upgrades of this abstract base.
     *      Slots used by `LockMint20` itself: 3 (_custName, _custSymbol, lockedLedger).
     *      Gap: 50 - 3 = 47 slots.
     */
    uint256[47] private __gap;

    /**
     * @notice Snapshot `__ERC20_init` strings into mutable metadata storage.
     * @param n ERC-20 name (typically same as initializer argument).
     * @param s ERC-20 symbol (typically same as initializer argument).
     * @dev Call once from the concrete token `initializer`, immediately after `__ERC20_init(n, s)`.
     */
    function _metaInit(string memory n, string memory s) internal onlyInitializing {
        _custName = n;
        _custSymbol = s;
    }

    /**
     * @notice One-shot bundled initializer for `LockMint20` children.
     * @dev Chains `__ERC20_init`, `__AccessControl_init`, and `_metaInit` in the correct order.
     *      Concrete child contracts should prefer this over the three separate calls.
     * @param name_ ERC-20 name
     * @param symbol_ ERC-20 symbol
     * @param administrator_ Address of the Administrator contract
     */
    // forge-lint: disable-next-line(mixed-case-function)
    function __LockMint20_init(
        string memory name_,
        string memory symbol_,
        address administrator_
    ) internal onlyInitializing {
        __ERC20_init(name_, symbol_);
        __AccessControl_init(administrator_);
        _metaInit(name_, symbol_);
    }

    /// @inheritdoc ERC20Upgradeable
    function name() public view virtual override returns (string memory) {
        return _custName;
    }

    /// @inheritdoc ERC20Upgradeable
    function symbol() public view virtual override returns (string memory) {
        return _custSymbol;
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public pure virtual override returns (uint8) {
        return Constants.USDW_TOKEN_DECIMALS;
    }

    /**
     * @notice Update human-readable metadata.
     * @param newName New full name (non-empty).
     * @param newSym New symbol (non-empty).
     */
    function setNameAndSymbol(string calldata newName, string calldata newSym) external onlyAdministrator {
        if (bytes(newName).length == 0 || bytes(newSym).length == 0) revert Errors.ZeroAmount();
        string memory oldN = _custName;
        string memory oldS = _custSymbol;
        _custName = newName;
        _custSymbol = newSym;
        emit NameAndSymbolUpdated(address(this), oldN, oldS, newName, newSym);
    }

    /**
     * @inheritdoc ERC20Upgradeable
     * @notice Spendable balance: total ledger minus `_lockOf(a)`.
     */
    function balanceOf(address a) public view virtual override(ERC20Upgradeable, IERC20) returns (uint256) {
        return MathLib.safeSub(super.balanceOf(a), _lockOf(a));
    }

    /**
     * @notice Locked amount for `account` ({lockedLedger}).
     */
    function _lockOf(address account) internal view virtual returns (uint256) {
        return lockedLedger[account];
    }

    /**
     * @inheritdoc ERC20Upgradeable
     * @dev Applies pause/blacklist, optional `_onXfer`, unlock sufficiency on debits, then ledger update.
     */
    function _update(address from, address to, uint256 v) internal virtual override {
        _notPaused();
        if (from != address(0)) _notBlacklisted(from);
        if (to != address(0)) _notBlacklisted(to);
        _onXfer(from, to, v);
        _chkUnlck(from, to, v);
        super._update(from, to, v);
    }

    /**
     * @dev Optional gate on transfer/mint/burn. Default: no-op.
     *      USDW leaves this open: minting is permissionless, so nothing gates the destination.
     */
    function _onXfer(address from, address to, uint256 v) internal virtual {}

    /**
     * @notice Whether burns (`to == address(0)`) must satisfy spendable {balanceOf} before debiting the ledger.
     * @dev Default `true`: release locks in product code before `_burn` when burning previously locked amounts. Override to `false` only if burns must bypass spendable checks (discouraged).
     */
    function _lckBurn() internal pure virtual returns (bool) {
        return true;
    }

    /**
     * @notice Ensures `from` has enough unlocked balance for this debit (mint skips; burn may skip per `_lckBurn`).
     */
    function _chkUnlck(address from, address to, uint256 v) internal view virtual {
        if (from == address(0)) return;
        if (!_lckBurn() && to == address(0)) return;
        uint256 u = balanceOf(from);
        if (u < v) revert Errors.InsufficientShares(u, v);
    }

    /**
     * @inheritdoc ERC20Upgradeable
     * @dev Enforces global pause and blacklist on owner and spender before delegating.
     */
    function _approve(address o, address s, uint256 v, bool e) internal virtual override {
        _notPaused();
        _notBlacklisted(o);
        _notBlacklisted(s);
        super._approve(o, s, v, e);
    }

    /**
     * @inheritdoc ERC20Upgradeable
     * @dev Reverts if `s` (spender) is blacklisted.
     */
    function _spendAllowance(address o, address s, uint256 v) internal virtual override {
        _notBlacklisted(s);
        super._spendAllowance(o, s, v);
    }

    /// @notice Restricts {mint}, {burn}, {spendAllowance}, {lockTokens}, {unlockTokens}; see {_requireTokenOperator}.
    modifier onlyTokenOperator() {
        _requireTokenOperator();
        _;
    }

    /**
     * @notice Enforce token-operator caller for {ILockMint20} externals.
     * @dev Implemented by concrete tokens (`USDW` requires `ISSUER_ROLE`).
     */
    function _requireTokenOperator() internal view virtual;

    /// @inheritdoc ILockMint20
    function mint(address to, uint256 a) external onlyTokenOperator {
        to.requireNonZero();
        if (a == 0) revert Errors.ZeroAmount();
        _mint(to, a);
    }

    /// @inheritdoc ILockMint20
    function burn(address from, uint256 a) external onlyTokenOperator {
        from.requireNonZero();
        if (a == 0) revert Errors.ZeroAmount();
        _burn(from, a);
    }

    /// @inheritdoc ILockMint20
    function spendAllowance(address o, address s, uint256 a) external override onlyTokenOperator {
        _spendAllowance(o, s, a);
    }

    /// @inheritdoc ILockMint20
    function lockTokens(address u, uint256 a) external onlyTokenOperator {
        u.requireNonZero();
        if (a == 0) revert Errors.ZeroAmount();
        uint256 unlocked = balanceOf(u);
        if (unlocked < a) revert Errors.InsufficientShares(unlocked, a);
        _lckAdd(u, a);
        emit TokensLocked(address(this), u, a);
    }

    /// @inheritdoc ILockMint20
    function unlockTokens(address u, uint256 a) external onlyTokenOperator {
        u.requireNonZero();
        if (a == 0) revert Errors.ZeroAmount();
        uint256 lk = _lockOf(u);
        if (lk < a) revert Errors.InsufficientShares(lk, a);
        _lckSub(u, a);
        emit TokensUnlocked(address(this), u, a);
    }

    /** @dev Increase {lockedLedger} after caller-side {balanceOf} checks; safe to override only for exotic ledgers. */
    function _lckAdd(address u, uint256 a) internal virtual {
        lockedLedger[u] = MathLib.safeAdd(lockedLedger[u], a);
    }

    /** @dev Decrease {lockedLedger} after caller-side sufficiency checks; safe to override only for exotic ledgers. */
    function _lckSub(address u, uint256 a) internal virtual {
        lockedLedger[u] = MathLib.safeSub(lockedLedger[u], a);
    }
}
