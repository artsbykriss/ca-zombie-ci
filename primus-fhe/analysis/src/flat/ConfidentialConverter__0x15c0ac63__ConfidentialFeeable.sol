// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";

/**
 * @dev Conditional FHE fee charging, with an optional business fee, for the confidential token /
 * converter / aggregator stack.
 *
 * The Primus `FHEExecutor` bills every FHE operation against the user locked in transient storage for
 * the current transaction (set by a single `chargeFee(user)` call). Two hard constraints follow
 * (see `FHEExecutor.FeeManagerLib`):
 *
 * - C1: `chargeFee` may be called at most once per transaction (`UserLockedInTx`).
 * - C2: `chargeFee` requires `msg.value > 0` (`ZeroAmount`).
 * - C3: any transaction executing FHE ops must have called `chargeFee` first (`UserNotInitializedInTx`).
 *
 * Therefore each user transaction must charge exactly once, at the outermost user-facing entry point,
 * against the EOA. Internal cross-contract calls (e.g. a aggregator calling a converter) must NOT charge
 * again: they carry no `msg.value` and would re-enter `chargeFee`.
 *
 * {chargeFeeIfExternal} encodes this: it charges the caller when it is an end user, and skips when the
 * caller is a registered internal contract (a aggregator). The skipped call's FHE ops are still paid for,
 * because the outer entry already locked the EOA in the executor's transient storage, which is shared
 * across the whole transaction.
 *
 * {chargeFeeAsSelf} is the contract-wallet variant: it charges `address(this)` instead of the caller,
 * which passes the executor's `user == msg.sender || user == tx.origin` check even when the caller is a
 * multisig or any other contract (where charging the caller would revert `UnauthorizedFeeUser`). The
 * choice is per entry point: user-facing functions keep {chargeFeeIfExternal} so users pay for their own
 * FHE ops, while operator-facing settlement paths use {chargeFeeAsSelf} so the protocol funds them
 * centrally. (Do NOT implement "charge as self" by overriding the charging logic of
 * {chargeFeeIfExternal} contract-wide — that would also bill user deposits/claims to the contract and
 * silently drop the business fee.)
 *
 * Business fee (optional): when charging at the entry point, a business-layer fee may also be collected
 * in the same `msg.value`, so the user signs and pays once for both. The amount is provided by the
 * {_businessFee} hook (default 0). The FHE prepayment gets `msg.value - businessFee`; the business fee
 * is accrued to a pull balance for the recipient (see {claimBusinessFee}) to avoid reentrancy from a value push.
 * The whitelist/skip mechanism guarantees the business fee is also collected at most once per tx, at the
 * entry point — internal calls skip it together with the FHE fee.
 *
 * Concrete contracts expose `setFeeSkipCaller` (owner-gated) so a aggregator can be registered after
 * deployment. The whitelist lives in an ERC-7201 namespaced slot so this mixin is safe to add to
 * upgradeable contracts.
 */
abstract contract ConfidentialFeeable {
    /// @custom:storage-location erc7201:primus.fhetransform.storage.ConfidentialFeeable
    struct ConfidentialFeeableStorage {
        /// @dev Internal callers (e.g. aggregators) that skip the fee, since their entry point already charged.
        mapping(address caller => bool skip) _feeSkipCallers;
        /// @dev Pull balances for accrued business fees, per recipient.
        mapping(address recipient => uint256 balance) _businessFeeBalances;
    }

    /// @dev A new internal caller `caller` was registered with skip flag `skip`.
    event FeeSkipCallerSet(address indexed caller, bool skip);

    /// @dev `amount` of business fee was accrued for `recipient` and is claimable via {claimFee}.
    event BusinessFeeAccrued(address indexed recipient, uint256 amount);

    /// @dev `amount` of accrued business fee was withdrawn to `recipient`.
    event BusinessFeeWithdrawn(address indexed recipient, uint256 amount);

    /// @dev `caller` is not registered as a fee-skip caller.
    error FeeSkipCallerNotRegistered(address caller);

    /// @dev The business fee exceeds the attached `msg.value`, leaving nothing for the FHE prepayment.
    error BusinessFeeExceedsValue(uint256 businessFee, uint256 msgValue);

    /// @dev The recipient for a non-zero business fee is the zero address.
    error BusinessFeeZeroRecipient();

    /// @dev No accrued business fee to withdraw for `recipient`.
    error NoBusinessFeeToClaim(address recipient);

    /// @dev ETH transfer to the recipient failed.
    error BusinessFeeTransferFailed();

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.ConfidentialFeeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CONFIDENTIAL_FEEABLE_STORAGE_LOCATION =
        0x5be2d6f131f3119a1c9ff4cade4336b3f8d7ba0ba3979bb477503a307e7c7600;

    function _getConfidentialFeeableStorage() internal pure returns (ConfidentialFeeableStorage storage $) {
        assembly {
            $.slot := CONFIDENTIAL_FEEABLE_STORAGE_LOCATION
        }
    }

    /// @dev Registers or unregisters an internal caller whose entry point already charges the fee.
    /// Only the concrete contract's owner should be able to reach this.
    function _setFeeSkipCaller(address caller, bool skip) internal {
        require(caller != address(0), FeeSkipCallerNotRegistered(caller));
        _getConfidentialFeeableStorage()._feeSkipCallers[caller] = skip;
        emit FeeSkipCallerSet(caller, skip);
    }

    /// @dev Whether `caller` is a registered fee-skip caller.
    function isFeeSkipCaller(address caller) public view returns (bool) {
        return _getConfidentialFeeableStorage()._feeSkipCallers[caller];
    }

    /**
     * @dev Business fee hook. Returns `(fee, recipient)` to charge the caller in addition to the FHE
     * prepayment. Default is no business fee. Business-layer contracts (e.g. a concrete aggregator, or a
     * delegate to an `IBusinessFeePolicy`) override this to return the real amount and recipient.
     *
     * `payer` is `msg.sender` — the same account the FHE fee is charged to, so the two stay consistent.
     */
    function _businessFee(address payer) internal view virtual returns (uint256 fee, address recipient) {
        return (0, address(0));
    }

    /**
     * @dev Charges the caller the attached `msg.value` unless it is a registered internal caller, in which
     * case the fee is skipped (the caller's own entry point already charged the EOA for this transaction).
     *
     * When not skipped, `msg.value` is split: `msg.value - businessFee` is forwarded to the FHE executor
     * as prepayment, and `businessFee` is accrued to the recipient's pull balance. Functions using this
     * modifier must be `payable`.
     *
     * The caller is charged directly (`user == msg.sender`), which the executor only accepts when the
     * caller is the EOA behind the transaction (`user == msg.sender || user == tx.origin`). Entry points
     * that must also be callable by a contract wallet (multisig keeper/owner) should use
     * {chargeFeeAsSelf} instead — charging a contract caller here would revert `UnauthorizedFeeUser`.
     */
    modifier chargeFeeIfExternal() {
        if (!_getConfidentialFeeableStorage()._feeSkipCallers[msg.sender]) {
            (uint256 businessFee, address recipient) = _businessFee(msg.sender);
            require(businessFee <= msg.value, BusinessFeeExceedsValue(businessFee, msg.value));

            // FHE prepayment gets the remainder; the actual op cost is deducted from the user's balance.
            FHE.chargeFee(msg.sender, msg.value - businessFee);

            if (businessFee > 0) {
                require(recipient != address(0), BusinessFeeZeroRecipient());
                ConfidentialFeeableStorage storage $ = _getConfidentialFeeableStorage();
                $._businessFeeBalances[recipient] += businessFee;
                emit BusinessFeeAccrued(recipient, businessFee);
            }
        }
        _;
    }

    /**
     * @dev Charges THIS contract (rather than the caller) as the FHE fee payer, funded by the
     * attached `msg.value`.
     *
     * Use this on entry points that must be callable by a contract wallet — e.g. a multisig keeper
     * settling via `dispatchAggregateCallback`, or a multisig owner calling `recoverAggregate`.
     * `FeeManagerLib.chargeFee` requires `user == msg.sender || user == tx.origin`
     * (`UnauthorizedFeeUser`), so {chargeFeeIfExternal} only works when the caller is the EOA that
     * submitted the transaction: for a multisig call, `msg.sender` is the wallet contract while
     * `tx.origin` is the signer EOA that executed it, so charging the caller reverts. Charging
     * `address(this)` sidesteps that check entirely: this contract IS the `msg.sender` of the
     * `FHEExecutor.chargeFee` call, so `user == msg.sender` always holds regardless of who the
     * external caller is.
     *
     * Caveats:
     * - The fee balance accrues to THIS contract's account at the executor, and every FHE op in
     *   the transaction is billed against it. Overpayment is NOT refunded to the caller; the
     *   surplus stays as this contract's prepaid balance and is consumed by later
     *   `chargeFeeAsSelf` transactions. Callers should attach only what the route needs.
     * - `msg.value` must still be > 0 (`ZeroAmount`), even if the contract already has prepaid
     *   balance from earlier overpayments — the executor's `chargeFee` rejects zero-value calls.
     * - The same once-per-transaction rule as {chargeFeeIfExternal} applies (C1): this must be
     *   the only `chargeFee` in the transaction, so nested FHE-charging calls (e.g. a converter's
     *   `shield`) must skip charging via the fee-skip whitelist exactly as with
     *   {chargeFeeIfExternal}.
     * - No business fee is collected here: the payer of record is the contract, not the caller,
     *   so a per-user business fee would be mis-attributed. Functions using this modifier must be
     *   `payable`.
     */
    modifier chargeFeeAsSelf() {
        FHE.chargeFee(address(this), msg.value);
        _;
    }

    /// @dev Accrued business fee claimable by `recipient` via {claimBusinessFee}.
    function businessFeeBalanceOf(address recipient) public view returns (uint256) {
        return _getConfidentialFeeableStorage()._businessFeeBalances[recipient];
    }

    /**
     * @dev Withdraws `recipient`'s accrued business fee. Permissionless: anyone may trigger it; funds
     * always go to `recipient`. Uses the pull pattern (balance zeroed before the transfer) so it is
     * safe against reentrancy.
     */
    function claimBusinessFee(address recipient) external {
        ConfidentialFeeableStorage storage $ = _getConfidentialFeeableStorage();
        uint256 amount = $._businessFeeBalances[recipient];
        require(amount > 0, NoBusinessFeeToClaim(recipient));

        $._businessFeeBalances[recipient] = 0;
        (bool ok, ) = recipient.call{value: amount}("");
        require(ok, BusinessFeeTransferFailed());

        emit BusinessFeeWithdrawn(recipient, amount);
    }
}
