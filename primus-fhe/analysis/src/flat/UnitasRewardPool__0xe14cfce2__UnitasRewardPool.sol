// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {PrimusConfigUpgradeable} from "@primuslabs/fhe-contracts/contracts/config/PrimusConfigUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IConfidentialERC20} from "../token/interfaces/IConfidentialERC20.sol";
import {IConfidentialERC20Receiver} from "../token/interfaces/IConfidentialERC20Receiver.sol";
import {ConfidentialSafeMath} from "../utils/ConfidentialSafeMath.sol";
import {ConfidentialFeeable} from "../utils/ConfidentialFeeable.sol";

/**
 * @title UnitasRewardPool
 * @notice Independent MasterChef-style reward pool for Unitas USDu Booster depositors.
 *
 * The pool is fully decoupled from the vault aggregators: it knows nothing about aggregate ids,
 * batch states or route execution. Positions are denominated in esUSDu (the confidential share
 * token users receive from the mint aggregator's `claim`), which is non-rebasing — vault interest
 * (exchange-rate appreciation) never enters the reward ledger. A trusted keeper drives everything:
 *
 *   - {enterBatch}: at mint `claim` time, register the esUSDu amounts the users of one mint
 *     aggregate received (encrypted handles, ACL-granted to this pool by the mint aggregator).
 *   - {postPeriod}: once per period, advance the global accumulator with a plaintext subsidy and
 *     the plaintext total staked (`accRewardPerShare += deltaR * PRECISION / totalStaked`).
 *   - {claimRewardBatch}: at redeem dispatch time, pay out ALL rewards accrued to
 *     date in one shot (MasterChef withdraw semantics, regardless of partial/full redeem) and
 *     subtract the redeemed esUSDu (encrypted handles, ACL-granted by the redeem aggregator) from
 *     each user's position. A full redeem zeroes the position naturally — no separate exit hook.
 *
 * Replay protection: every keeper entry point takes a keeper-assigned batch `id` (uint256) and
 * consumes it — a replay of an already-consumed id reverts, so a faulty keeper cannot apply the
 * same batch twice. Ids are namespaced per entry point ({enterBatch}, {claimRewardBatch} and
 * {postPeriod} each have their own namespace), so the keeper is free to restart its counters per
 * pipeline. Single-user aggregates go through the same batch entry points with one-element arrays:
 * since `id` is the aggregate id, per-user calls would collide on the second user of an aggregate.
 *
 * The owner funds the pool by transferring reward tokens in via `confidentialTransferAndCall`;
 * the received amount accrues to `rewardBudget`. Payouts are clamped to the budget with
 * `FHE.select(FHE.le(pending, budget), ...)` (confidential transfers silently move 0 on
 * insufficient balance), so an underfunded pool caps the payout and leaves the remainder
 * claimable after the next funding.
 *
 * Emergency brake: the owner can {pause} to freeze {postPeriod} and payouts
 * ({claimRewardBatch}) when the off-chain reconciliation of `sum(_amounts)` against
 * the keeper-reported `totalStakedEsUSDu` flags an anomaly. {enterBatch} and funding stay
 * open while paused: they move no funds, and keeping position registration live lets the ledger
 * keep tracking mint claims so it can be reconciled before unpausing.
 *
 * Fee model: {enterBatch}/{claimRewardBatch} execute FHE ops and charge via {chargeFeeIfExternal} (the
 * keeper prepays). The reward token must register this pool as a fee-skip caller
 * (`setFeeSkipCaller(pool, true)`) so the inner `confidentialTransfer` in {_payAll} reuses the
 * outer fee session instead of reverting with `UnauthorizedFeeUser`. {postPeriod} does no FHE
 * work and charges nothing.
 *
 * Upgradeable: deployed behind a UUPS proxy via {initialize}. Storage is ERC-7201 namespaced.
 */
contract UnitasRewardPool is
    PrimusConfigUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ConfidentialFeeable,
    ReentrancyGuardTransient,
    IConfidentialERC20Receiver
{
    /// @dev Fixed-point scale for `accRewardPerShare` (MasterChef's ACC_SUSHI_PRECISION analogue).
    /// Prevents integer-division truncation when `deltaR < totalStaked`; unrelated to token decimals.
    uint256 public constant PRECISION = 1e12;

    /// @custom:storage-location erc7201:primus.fhetransform.storage.UnitasRewardPool
    struct UnitasRewardPoolStorage {
        /// @dev Confidential reward token paid out to users.
        IConfidentialERC20 _rewardToken;
        /// @dev Exclusive caller of enterBatch/postPeriod/claimRewardBatch (rotatable by the owner).
        address _keeper;
        /// @dev Global accumulator: cumulative reward per esUSDu share, scaled by {PRECISION} (plaintext).
        uint256 _accRewardPerShare;
        /// @dev Seconds between two subsidy postings.
        uint256 _periodDuration;
        /// @dev Scheduled start of the current period (advanced by exactly `_periodDuration` per post).
        uint256 _lastPeriodTime;
        /// @dev User esUSDu position (ciphertext; credited at enterBatch, debited at claimRewardBatch).
        mapping(address => ve_uint64) _amounts;
        /// @dev User's `accRewardPerShare` reading at the last settle (plaintext scalar; the rewardDebt
        /// analogue — `rewardDebt ≡ amount * preAccRewardPerShare`).
        mapping(address => uint256) _preAccRewardPerShare;
        /// @dev Crystallized-but-unpaid rewards per user (ciphertext).
        mapping(address => ve_uint64) _pendingRewards;
        /// @dev Funded reward balance (ciphertext); payouts are clamped to it.
        ve_uint64 _rewardBudget;
        /// @dev Mint batch ids already consumed by {enterBatch} (replay protection).
        mapping(uint256 => bool) _enteredBatchIds;
        /// @dev Redeem batch ids already consumed by {claimRewardBatch} (replay protection).
        mapping(uint256 => bool) _claimedBatchIds;
        /// @dev Period ids already consumed by {postPeriod} (replay protection).
        mapping(uint256 => bool) _postedPeriodIds;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.UnitasRewardPool")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant UNITAS_REWARD_POOL_STORAGE_LOCATION =
        0xc71a841d4ba70f4a076ca7aeeaf9bd059224d23df933cc6cd98a1e6cd8f78a00;

    /// @dev A required address argument is the zero address.
    error ZeroAddress();

    /// @dev The caller is not the keeper.
    error NotKeeper(address caller);

    /// @dev {postPeriod} was called before the current period elapsed.
    error PeriodNotReached(uint256 earliest, uint256 current);

    /// @dev {postPeriod} was called with a zero total staked.
    error ZeroTotalStaked();

    /// @dev Batch arrays are empty or of mismatched length.
    error InvalidBatchInput();

    /// @dev A keeper call replayed a batch id that was already consumed.
    error BatchAlreadyProcessed(uint256 id);

    /// @dev {claimRewardBatch} carried a nonzero redemption for a user with no registered position
    /// (the redeem pipeline outran {enterBatch}).
    error PositionNotInitialized(address user);

    /// @dev {onConfidentialTransferReceived} was invoked by a token other than the reward token.
    error UnauthorizedToken(address token);

    /// @dev The keeper was rotated to `keeper`.
    event KeeperSet(address indexed keeper);

    /// @dev The period duration was updated.
    event PeriodDurationSet(uint256 periodDuration);

    /// @dev A period subsidy was posted in batch `id`; `accRewardPerShare` is the new global accumulator.
    event PeriodPosted(uint256 indexed id, uint256 deltaR, uint256 totalStaked, uint256 accRewardPerShare);

    /// @dev `user`'s position was credited with `amount` esUSDu (handle) in batch `id`.
    event Entered(uint256 indexed id, address indexed user, ve_uint64 amount);

    /// @dev `user` was paid `paid` (handle) and `redeemed` (handle) was debited from their position in batch `id`.
    event RewardClaimed(uint256 indexed id, address indexed user, ve_uint64 paid, ve_uint64 redeemed);

    /// @dev `from` funded the reward budget with `amount` (handle).
    event RewardBudgetFunded(address indexed from, ve_uint64 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Returns a pointer to the reward pool namespaced storage.
    function _getUnitasRewardPoolStorage() internal pure returns (UnitasRewardPoolStorage storage $) {
        assembly {
            $.slot := UNITAS_REWARD_POOL_STORAGE_LOCATION
        }
    }

    /**
     * @notice Initializes the pool behind a UUPS proxy.
     * @param rewardToken_ Confidential token paid out as rewards.
     * @param keeper_ Exclusive caller of enterBatch/postPeriod/claimRewardBatch (rotatable via {setKeeper}).
     * @param owner_ Owner authorized to rotate the keeper, retune the period and upgrade.
     * @param periodDuration_ Seconds between two subsidy postings (0 = every post starts a new period).
     */
    function initialize(IConfidentialERC20 rewardToken_, address keeper_, address owner_, uint256 periodDuration_)
        public
        initializer
    {
        require(address(rewardToken_) != address(0), ZeroAddress());
        require(keeper_ != address(0), ZeroAddress());
        __PrimusConfigUpgradeable_init();
        __Ownable_init(owner_);
        __Pausable_init();

        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();
        $._rewardToken = rewardToken_;
        $._keeper = keeper_;
        $._periodDuration = periodDuration_;
        $._lastPeriodTime = block.timestamp;
        emit KeeperSet(keeper_);
        emit PeriodDurationSet(periodDuration_);
    }

    // ----------------------------------------------------------------------------------------------
    // Keeper entry points
    // ----------------------------------------------------------------------------------------------

    /**
     * @notice Credits each `users[i]`'s position with the esUSDu amount they claimed from the mint
     * aggregator.
     * @dev Keeper only, called once per mint aggregate. `id` is the keeper-assigned mint batch id
     * (the aggregate id); replaying an already-consumed id reverts. `esUsduHandles[i]` is the
     * claim's transferred amount handle; the mint aggregator must have granted this pool persistent
     * ACL access to it. Settles accrued rewards at the old position first, then credits (MasterChef
     * deposit semantics). A single-claimant aggregate uses one-element arrays.
     */
    function enterBatch(uint256 id, address[] calldata users, ve_uint64[] calldata esUsduHandles)
        external
        payable
        onlyKeeper
        chargeFeeIfExternal
    {
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();
        _consumeBatchId($._enteredBatchIds, id);
        require(users.length > 0 && users.length == esUsduHandles.length, InvalidBatchInput());
        for (uint256 i = 0; i < users.length; i++) {
            _enter(id, users[i], esUsduHandles[i]);
        }
    }

    /**
     * @notice Posts one period's subsidy: `accRewardPerShare += deltaR * PRECISION / totalStakedEsUSDu`.
     * @dev Keeper only. `id` is the keeper-assigned period id; replaying an already-consumed id
     * reverts. `deltaR` and `totalStakedEsUSDu` are plaintext (public budget). `deltaR` is a pure
     * accounting parameter — no tokens move here; the pool is funded separately via
     * `confidentialTransferAndCall`. `totalStakedEsUSDu` must be in the same base unit as the
     * encrypted positions (esUSDu). A misreported total only dilutes the operator's own subsidy;
     * user principal is unaffected. Advances the schedule by exactly one period (fixed cadence, no
     * drift); late posts do not catch up.
     */
    function postPeriod(uint256 id, uint256 deltaR, uint256 totalStakedEsUSDu) external onlyKeeper whenNotPaused {
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();
        _consumeBatchId($._postedPeriodIds, id);

        uint256 nextPeriodTime = $._lastPeriodTime + $._periodDuration;
        require(block.timestamp >= nextPeriodTime, PeriodNotReached(nextPeriodTime, block.timestamp));
        require(totalStakedEsUSDu > 0, ZeroTotalStaked());

        $._accRewardPerShare += (deltaR * PRECISION) / totalStakedEsUSDu;
        $._lastPeriodTime = nextPeriodTime;
        emit PeriodPosted(id, deltaR, totalStakedEsUSDu, $._accRewardPerShare);
    }

    /**
     * @notice Settles each `users[i]` at redeem time: pays ALL accrued rewards in one shot and
     * debits the redeemed esUSDu from their position (MasterChef withdraw semantics).
     * @dev Keeper only, called once per redeem aggregate. `id` is the keeper-assigned redeem batch
     * id (the aggregate id); replaying an already-consumed id reverts. `redeemedHandles[i]` is the
     * user's cumulative deposit handle in the redeem aggregator; the redeem aggregator must have
     * granted this pool persistent ACL access to it. A partial redeem keeps the remainder earning;
     * a full redeem zeroes the position naturally. An underfunded budget caps the payout — the
     * unpaid remainder stays in `pendingRewards` and is paid by a later claimRewardBatch once
     * refunded (a zero `redeemedHandle` collects without debiting). A nonzero redemption for a user
     * with no registered position reverts with {PositionNotInitialized}: the redeem pipeline must
     * not outrun {enterBatch}, and the batch id is not consumed on revert, so the keeper can
     * register the position first and retry with the same id. A single-redeemer aggregate uses
     * one-element arrays.
     */
    function claimRewardBatch(uint256 id, address[] calldata users, ve_uint64[] calldata redeemedHandles)
        external
        payable
        onlyKeeper
        whenNotPaused
        chargeFeeIfExternal
        nonReentrant
    {
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();
        _consumeBatchId($._claimedBatchIds, id);
        require(users.length > 0 && users.length == redeemedHandles.length, InvalidBatchInput());
        for (uint256 i = 0; i < users.length; i++) {
            _claimReward(id, users[i], redeemedHandles[i]);
        }
    }

    // ----------------------------------------------------------------------------------------------
    // Funding
    // ----------------------------------------------------------------------------------------------

    /**
     * @notice Receives reward-token funding via `confidentialTransferAndCall`; accrues to `rewardBudget`.
     * @dev Only the configured reward token may invoke this. Funding is separate from {postPeriod}'s
     * `deltaR`, which is a pure accounting parameter. The budget may cover many periods at once.
     */
    function onConfidentialTransferReceived(
        address,
        address from,
        ve_uint64 amount,
        bytes calldata
    ) external returns (ve_bool) {
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();
        require(msg.sender == address($._rewardToken), UnauthorizedToken(msg.sender));

        (, ve_uint64 newBudget) = ConfidentialSafeMath.tryIncrease($._rewardBudget, amount);
        FHE.accessPolicy(newBudget, address(this));
        $._rewardBudget = newBudget;

        ve_bool success = FHE.asVEBool(true);
        FHE.accessPolicy(success, msg.sender, PermissionType.Transient);
        emit RewardBudgetFunded(from, amount);
        return success;
    }

    // ----------------------------------------------------------------------------------------------
    // Views
    // ----------------------------------------------------------------------------------------------

    /// @return The confidential reward token.
    function rewardToken() external view returns (IConfidentialERC20) {
        return _getUnitasRewardPoolStorage()._rewardToken;
    }

    /// @return The keeper: the only account allowed to call enterBatch/postPeriod/claimRewardBatch.
    function keeper() external view returns (address) {
        return _getUnitasRewardPoolStorage()._keeper;
    }

    /// @return The global reward-per-share accumulator, scaled by {PRECISION}.
    function accRewardPerShare() external view returns (uint256) {
        return _getUnitasRewardPoolStorage()._accRewardPerShare;
    }

    /// @return The seconds between two subsidy postings.
    function periodDuration() external view returns (uint256) {
        return _getUnitasRewardPoolStorage()._periodDuration;
    }

    /// @return The scheduled start of the current period.
    function lastPeriodTime() external view returns (uint256) {
        return _getUnitasRewardPoolStorage()._lastPeriodTime;
    }

    /// @return `user`'s esUSDu position (ciphertext handle).
    function amounts(address user) external view returns (ve_uint64) {
        return _getUnitasRewardPoolStorage()._amounts[user];
    }

    /// @return `user`'s `accRewardPerShare` reading at their last settle.
    function preAccRewardPerShare(address user) external view returns (uint256) {
        return _getUnitasRewardPoolStorage()._preAccRewardPerShare[user];
    }

    /// @return `user`'s crystallized-but-unpaid rewards (ciphertext handle).
    function pendingRewards(address user) external view returns (ve_uint64) {
        return _getUnitasRewardPoolStorage()._pendingRewards[user];
    }

    /// @return The funded reward budget (ciphertext handle).
    function rewardBudget() external view returns (ve_uint64) {
        return _getUnitasRewardPoolStorage()._rewardBudget;
    }

    // ----------------------------------------------------------------------------------------------
    // Admin
    // ----------------------------------------------------------------------------------------------

    /// @notice Rotates the keeper. Owner only.
    function setKeeper(address keeper_) external onlyOwner {
        require(keeper_ != address(0), ZeroAddress());
        _getUnitasRewardPoolStorage()._keeper = keeper_;
        emit KeeperSet(keeper_);
    }

    /// @notice Updates the period duration. Owner only; applies from the next posted period.
    function setPeriodDuration(uint256 periodDuration_) external onlyOwner {
        _getUnitasRewardPoolStorage()._periodDuration = periodDuration_;
        emit PeriodDurationSet(periodDuration_);
    }

    /**
     * @notice Pauses subsidy posting ({postPeriod}) and reward payouts
     * ({claimRewardBatch}). Owner only.
     * @dev The emergency brake for reconciliation anomalies (e.g. `sum(_amounts)` diverging from the
     * keeper-reported `totalStakedEsUSDu`). {enterBatch} and budget funding stay open: they
     * move no funds, and blocking position registration would desync the ledger from the aggregators
     * further. Pausing mid-period does not shift the cadence — {_lastPeriodTime} only advances on a
     * successful post, so the schedule resumes where it left off.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resumes subsidy posting and payouts after a pause. Owner only.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Authorizes an implementation upgrade. Only the owner may upgrade the proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ----------------------------------------------------------------------------------------------
    // Internals
    // ----------------------------------------------------------------------------------------------

    modifier onlyKeeper() {
        require(msg.sender == _getUnitasRewardPoolStorage()._keeper, NotKeeper(msg.sender));
        _;
    }

    /// @dev Replay protection: reverts if `id` was already consumed, else consumes it.
    function _consumeBatchId(mapping(uint256 => bool) storage consumed, uint256 id) internal {
        require(!consumed[id], BatchAlreadyProcessed(id));
        consumed[id] = true;
    }

    /// @dev MasterChef deposit: settle at the old position, then credit the new amount and snapshot
    /// the accumulator reading. Repeated enters merge into one position.
    function _enter(uint256 id, address user, ve_uint64 esUsduHandle) internal {
        require(user != address(0), ZeroAddress());
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();

        _settle($, user);

        (, ve_uint64 newAmount) = ConfidentialSafeMath.tryIncrease($._amounts[user], esUsduHandle);
        FHE.accessPolicy(newAmount, address(this));
        FHE.accessPolicy(newAmount, user);
        $._amounts[user] = newAmount;

        emit Entered(id, user, esUsduHandle);
    }

    /// @dev MasterChef withdraw: crystallize, pay everything, then debit the redeemed shares and
    /// re-snapshot the accumulator reading for the reduced position.
    function _claimReward(uint256 id, address user, ve_uint64 redeemedHandle) internal {
        require(user != address(0), ZeroAddress());
        UnitasRewardPoolStorage storage $ = _getUnitasRewardPoolStorage();

        // A nonzero redemption requires a registered position: otherwise the debit below would
        // silently no-op while RewardClaimed still reports a successful debit, corrupting the
        // off-chain reconciliation that consumes these events (the redeem pipeline must never
        // outrun enterBatch). A zero redeemedHandle stays allowed: it is the collect-pending-without-
        // redeeming flow and debits nothing, so the event is truthful.
        require(
            FHE.isInitialized($._amounts[user]) || !FHE.isInitialized(redeemedHandle),
            PositionNotInitialized(user)
        );

        _settle($, user);
        ve_uint64 paid = _payAll($, user);

        if (FHE.isInitialized(redeemedHandle)) {
            // Underflow-safe: a redeem larger than the tracked position zeroes the position
            // (trySub clamps to 0) rather than reverting or wrapping.
            (, ve_uint64 newAmount) = ConfidentialSafeMath.trySub($._amounts[user], redeemedHandle);
            FHE.accessPolicy(newAmount, address(this));
            FHE.accessPolicy(newAmount, user);
            $._amounts[user] = newAmount;
        }

        emit RewardClaimed(id, user, paid, redeemedHandle);
    }

    /// @dev Crystallizes rewards accrued since the user's last settle into `pendingRewards`, then
    /// re-snapshots their accumulator reading. `pending = amount * accDelta / PRECISION`; the position
    /// is widened to 128 bits before multiplying so the intermediate product cannot overflow (same
    /// pattern as the aggregator's `_claim`).
    function _settle(UnitasRewardPoolStorage storage $, address user) internal {
        ve_uint64 amount = $._amounts[user];
        if (FHE.isInitialized(amount)) {
            uint256 accDelta = $._accRewardPerShare - $._preAccRewardPerShare[user];
            if (accDelta > 0) {
                ve_uint64 delta = FHE.asVEUint64(
                    FHE.div(FHE.mul(FHE.asVEUint128(amount), SafeCast.toUint128(accDelta)), uint128(PRECISION))
                );
                ve_uint64 newPending = FHE.isInitialized($._pendingRewards[user])
                    ? FHE.add($._pendingRewards[user], delta)
                    : delta;
                FHE.accessPolicy(newPending, address(this));
                FHE.accessPolicy(newPending, user);
                $._pendingRewards[user] = newPending;
            }
        }
        $._preAccRewardPerShare[user] = $._accRewardPerShare;
    }

    /// @dev Pays `user` their whole `pendingRewards`, capped at `rewardBudget` (no `FHE.min`; use
    /// `FHE.select(FHE.le(...))`). The unpaid remainder stays claimable. Returns the paid handle.
    function _payAll(UnitasRewardPoolStorage storage $, address user) internal returns (ve_uint64 paid) {
        ve_uint64 pending = $._pendingRewards[user];
        ve_uint64 budget = $._rewardBudget;
        if (!FHE.isInitialized(pending) || !FHE.isInitialized(budget)) return paid;

        paid = FHE.select(FHE.le(pending, budget), pending, budget);
        ve_uint64 newBudget = FHE.sub(budget, paid);
        ve_uint64 newPending = FHE.sub(pending, paid);

        FHE.accessPolicy(newBudget, address(this));
        FHE.accessPolicy(newPending, address(this));
        FHE.accessPolicy(newPending, user);
        $._rewardBudget = newBudget;
        $._pendingRewards[user] = newPending;

        FHE.accessPolicy(paid, address($._rewardToken), PermissionType.Transient);
        $._rewardToken.confidentialTransfer(user, paid);
    }
}
