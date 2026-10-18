// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSRenounceable } from "../upgrade/UUPSRenounceable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { IRewardVestingEscrow } from "../interfaces/IRewardVestingEscrow.sol";

/// @title VampChef
/// @notice The short-lived "vampire attack" farm — Contract A of the two-contract farm split
///         of the farm design. Distributes a fixed, pre-minted
///         MOTO reward pool to Uniswap-V2 LP stakers pro-rata by allocation points and time, over a
///         single fixed 14-day window, then goes cold. Its counterpart is the long-lived halving farm
///         (`MasterChef`, Contract B) on Motoswap LP.
/// @dev Deliberately a TRIMMED `MasterChef`. The two phases share the same core accrual machinery
///      (`accRewardPerShare` × time × allocPoint), but the vampire phase differs by design decision, so
///      the extra machinery is dropped rather than mode-switched (PRD "why two contracts"):
///        - FLAT emission, not a 42-day halving: `rewardPerSecond = budget / DURATION` over exactly
///          `DURATION`, so the vampire APR is legible and strong. `emittedByTime` is linear, clamped to
///          the window, so accrual is 0 before the start and after the end.
///        - 50% liquid / 50% into the same 180-day `RewardVestingEscrow` as `MasterChef`: this farm
///          vests on the same terms as the halving farm, rather than paying out 100% liquid.
///        - NO unstake cooldown queue (PRD open-Q5, confirmed): `withdraw` settles rewards and returns
///          principal in the same call. The 24h cooldown only protects a long distribution.
///        - NO deposit fees: the vampire pools are LP pairs, never the single-sided fee pool.
///      Kept verbatim from `MasterChef`, because they are safety properties, not phase policy:
///        - Reward-token-principal tracking (`totalStakedRewardToken`): if a single-sided MOTO pool is
///          added, staked MOTO principal is reserved out of `availableReward` and can NEVER be paid as
///          reward.
///        - `RewardsExhausted` backstop + `emergencyWithdraw` principal escape hatch.
///        - `MAX_POOLS` bound on the O(pools) `massUpdatePools` loop.
///        - UUPS proxy + one-way `renounceUpgradeability` (L15), Ownable2Step, transient reentrancy
///          guard.
///      Pre-minted: `startEmission` pulls the whole budget up front (no minting), so `RewardsExhausted`
///      is a backstop, never a normal path. One campaign, ever — the vampire window does not restart.
contract VampChef is Initializable, UUPSRenounceable, Ownable2StepUpgradeable, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    /// @notice Info of each user, per pool.
    struct UserInfo {
        uint256 amount; // actively staked (reward-earning) LP amount
        uint256 rewardDebt; // pending = amount * accRewardPerShare / ACC_PRECISION - rewardDebt
    }

    /// @notice Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accRewardPerShare; // accumulated rewards per share, times ACC_PRECISION
        uint256 lpSupply; // total actively-staked amount
    }

    /// @dev Fixed-point precision for `accRewardPerShare`. `reward * ACC_PRECISION / lpSupply` rounds to
    ///      0 when staked supply >> per-interval reward, stalling accrual — a non-issue at the vampire
    ///      reward scale (300M / 14 days across a few pools; PRD open-Q3).
    uint256 public constant ACC_PRECISION = 1e12;

    /// @notice The single, fixed emission window length: 14 days. Flat over the whole window.
    /// @dev TWO WEEKS, PHASED. Week 1 runs the MOTO pool plus the three MOTO pairs; week 2 opens the rest
    ///      of the roster on day 8, and the campaign ends at day 14, after which the DEX launches.
    ///
    ///      Everything derives from this one constant &mdash; `rewardPerSecond = _budget / DURATION` and
    ///      `emissionEnd = start + DURATION` &mdash; so the edit is the whole mechanical change. On the 300M
    ///      budget that is ~248.02 MOTO/sec, ~21.43M/day, flat for 14 days. Constants take no storage slot, and
    ///      the public getter updates off-chain readers for free.
    ///
    ///      DELIBERATELY A CONSTANT, not a `startEmission` parameter: on a one-shot contract a duration
    ///      parameter is one more way to fat-finger the deployment ceremony, and it buys nothing. The
    ///      budget and the 50/50 liquid/stream split do not couple to campaign length.
    uint256 public constant DURATION = 14 days;

    /// @notice Max future offset for a scheduled campaign start. Bounds a fat-fingered `_startTime`:
    ///         there is no cancel path, so a wildly-future start would otherwise lock the pulled budget.
    uint256 public constant MAX_START_DELAY = 90 days;

    /// @notice Window after `emissionEnd` during which {recoverUndistributedRewards} stays shut, so every
    ///         staker has a published stretch of time to harvest before the owner can sweep. Same 30 days
    ///         as `MasterChef`.
    ///
    /// @dev    Accrual stops dead at `emissionEnd`, so without this the sweep would open the very second
    ///         the curve ended — a staker who had not harvested in that block could be swept before they
    ///         ever got the chance. 14-day campaign, 30-day grace: the window to act is longer than the
    ///         campaign itself.
    uint256 public constant HARVEST_GRACE = 30 days;

    /// @notice Hard cap on the pool count. `massUpdatePools` (run inside `add`/`set`/`startEmission`) is
    ///         O(pools).
    ///
    /// @dev    RAISED 64 -> 500. 64 was sized against an earlier rollout — 3 pools week 1, then +25-50
    ///         memecoin LP pools, so ~53 total — which it covers with 11 to spare. 500 was chosen to leave
    ///         room for the week-2 roster without a second raise; this
    ///         contract is the vamp chef, so the instruction lands here.
    ///
    ///         64 would probably have held. It has 11 pools of margin against a plan whose upper bound is
    ///         already stated as an estimate, and running out mid-rollout means a redeploy of a live farm —
    ///         the cap is a constant, and this contract is one-shot. Cheap headroom beats that.
    ///
    ///         The cost was measured, not assumed, on MasterChef's identical loop: `add()` at 499 existing
    ///         pools is ~483k gas, about 1.6% of a 30M block, because `massUpdatePools` skips pools with
    ///         nothing staked. See `test/unit/MasterChefMaxPools.t.sol` and `VampChefMaxPools.t.sol`.
    uint256 public constant MAX_POOLS = 500;

    /// @notice The pre-minted reward token (MOTO). Settable only while no campaign has ever started and
    ///         no pools exist — reward-token principal tracking keys off this address.
    IERC20 public rewardToken;

    /// @notice Escrow that streams the vested half (50%) of every harvest over 180 days. Set at `initialize`.
    IRewardVestingEscrow public vestingEscrow;

    /// @notice The pulled reward budget for the campaign (300M at launch). Emitted flat over `DURATION`.
    uint256 public rewardBudget;
    /// @notice Flat per-second emission = `rewardBudget / DURATION`. `rewardBudget % DURATION` wei is
    ///         un-emitted dust that stays in the contract (covered by the `availableReward` backstop).
    uint256 public rewardPerSecond;
    /// @notice Unix time the window begins. 0 = no campaign has ever started.
    uint64 public emissionStart;
    /// @notice Unix time the window ends; accrual auto-stops here.
    uint64 public emissionEnd;

    /// @notice Reward-token principal currently staked across all pools; never paid as reward.
    uint256 public totalStakedRewardToken;

    /// @notice Running total of reward ever credited into a pool's `accRewardPerShare` by {updatePool}.
    /// @dev Paired with {totalHarvested} this is the stakers' outstanding claim on the pot — the number
    ///      {recoverableReward} subtracts so the owner's sweep can never reach an earned reward. Emission
    ///      that streamed while a pool sat at zero stake (or `totalAllocPoint == 0`) never enters here,
    ///      which is precisely the value the hatch exists to free.
    uint256 public totalCredited;
    /// @notice Running total of reward actually paid out by {_safeRewardTransfer} (liquid + escrowed).
    uint256 public totalHarvested;
    /// @notice Reward abandoned by {emergencyWithdraw}. It was already counted into {totalCredited} but
    ///         will never reach {totalHarvested}, so without netting it out it would inflate the
    ///         outstanding claim permanently and strand that much forever.
    uint256 public forfeitedReward;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    /// @notice Info of each user that stakes, keyed by pool id then user address.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice Total allocation points across all pools.
    uint256 public totalAllocPoint;
    /// @dev Tracks which LP tokens already have a pool.
    mapping(address => bool) public poolExistence;

    /**
     * @notice The one contract permitted to deposit on a user's behalf, or `address(0)` if none.
     *
     * @dev SET ONCE, THEN FROZEN — {setTrustedZapper} reverts if this is already non-zero, and there is no
     *      clear path and no owner path that can redirect credits afterward.
     *
     *      WHY THAT MATTERS: a trusted zapper can credit a deposit to an arbitrary `_user`, which
     *      force-settles that user's pending reward and restarts their 180-day vest clock. On `MasterChef`
     *      that is unreachable only because the shipped zap happens to hardcode
     *      `msg.sender` — a property of that contract, not one the chef enforces. Here the slot cannot be
     *      re-pointed at all, so the exposure ends at whatever is named once, and that is a contract whose
     *      only deposit path hardcodes its own caller.
     *
     *      THE COST, STATED: if the zapper ever needs replacing, this chef can never point at a new one.
     *      A broken zap means no zap for the rest of the campaign — joining reverts to the four-step
     *      sequence, which is exactly what shipped before the zap existed. Accepted deliberately: losing a
     *      convenience is recoverable, an open credit-redirect path on a live farm is not.
     */
    address public trustedZapper;

    /// @dev Storage gap for future upgrades (L15). Never shrink; only consume from the front.
    ///      50 -> 47 when `totalCredited`, `totalHarvested` and `forfeitedReward` were appended above,
    ///      mirroring MasterChef's own 50 -> 46. 47 -> 46 for `trustedZapper`.
    uint256[46] private __gap;

    event TrustedZapperSet(address trustedZapper);
    event PoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocPoint, uint256 totalAllocPoint);
    event PoolSet(uint256 indexed pid, uint256 allocPoint, uint256 totalAllocPoint);
    event PoolUpdated(uint256 indexed pid, uint256 accRewardPerShare, uint256 lastRewardTime);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardForfeited(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionStarted(uint256 budget, uint256 rewardPerSecond, uint64 startTime, uint64 endTime);
    event RewardTokenSet(address rewardToken);
    event UndistributedRewardsRecovered(address to, uint256 amount);

    error RewardsExhausted();
    error DuplicatePool();
    error LengthMismatch();
    error InvalidPool();
    error InsufficientStaked();
    error ZeroAddress();
    /// @dev The zapper slot is already set. It is set-once by design; there is no re-point.
    error TrustedZapperAlreadySet();
    /// @dev A third party tried to deposit into a position that already exists.
    error Unauthorized();
    error EmissionActive();
    error InvalidEmission();
    error TooManyPools();
    error PoolsExist();
    error CampaignRan();
    error RewardTokenMismatch();

    /// @dev Reverts if `_lpToken` already has a pool.
    modifier nonDuplicated(IERC20 _lpToken) {
        if (poolExistence[address(_lpToken)]) revert DuplicatePool();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the farm behind its proxy.
    /// @param _rewardToken The pre-minted reward token (MOTO).
    /// @param _vestingEscrow Escrow that streams the vested half of every harvest over 180 days.
    /// @param _owner Initial owner (deployer EOA locally, timelock/multisig in production).
    function initialize(IERC20 _rewardToken, address _vestingEscrow, address _owner) external initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        if (address(_rewardToken) == address(0) || _vestingEscrow == address(0)) revert ZeroAddress();
        // The escrow streams the reward token; a mismatch would send the vested half into an escrow
        // denominated in a different token (silent loss). Bind them at init, like MasterChef.
        if (address(_rewardToken) != IRewardVestingEscrow(_vestingEscrow).token()) revert RewardTokenMismatch();
        rewardToken = _rewardToken;
        vestingEscrow = IRewardVestingEscrow(_vestingEscrow);
    }

    /// @dev Only the owner (deployer key / timelock / multisig) may upgrade the implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        _requireUpgradable();
    }

    /// @notice Permanently relinquish the ability to upgrade this contract (one-way, owner-gated).
    function renounceUpgradeability() external onlyOwner {
        _renounceUpgradeability();
    }

    /// @notice Start the single vampire campaign: flat emission of `_budget` over exactly `DURATION`,
    ///         pulled up front. `_startTime` anchors the window (0 = now; a future time schedules it).
    ///         ONE campaign, ever — the vampire window never restarts.
    /// @dev Caller must approve this contract for `_budget` (pulled via `transferFrom`).
    /// @param _budget Total MOTO emitted flat across the window (production: 300M).
    /// @param _startTime Unix time the window begins; must be >= now. 0 defaults to `block.timestamp`.
    function startEmission(uint256 _budget, uint64 _startTime) external onlyOwner {
        if (emissionStart != 0) revert EmissionActive(); // one-shot: no restart machinery
        // Reject a ghost curve: the budget must emit >= 1 wei/sec, else the per-second rate floors to 0.
        // Also covers `_budget == 0`.
        uint256 _rewardPerSecond = _budget / DURATION;
        if (_rewardPerSecond == 0) revert InvalidEmission();

        uint64 start = _startTime == 0 ? uint64(block.timestamp) : _startTime;
        if (start < block.timestamp) revert InvalidEmission(); // no retroactive emission
        if (start > block.timestamp + MAX_START_DELAY) revert InvalidEmission(); // bound the mis-schedule footgun

        massUpdatePools(); // settle every pool at its pre-start baseline before the window opens

        rewardToken.safeTransferFrom(msg.sender, address(this), _budget);

        rewardBudget = _budget;
        rewardPerSecond = _rewardPerSecond;
        emissionStart = start;
        emissionEnd = start + uint64(DURATION);
        emit EmissionStarted(_budget, _rewardPerSecond, start, emissionEnd);
    }

    /// @notice Swap the reward token BEFORE the farm ever runs. Locked out once a campaign has started
    ///         or any pool exists (reward-token principal tracking keys off this address).
    /// @dev Must keep matching the escrow's fixed token: the vested half of every harvest is pulled by
    ///      `escrow.depositFor` in the escrow's own token, so a reward token that differs from
    ///      `vestingEscrow.token()` would revert every harvest (and there is no `setVestingEscrow` to
    ///      re-point it). Same invariant `initialize` enforces.
    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        if (address(_rewardToken) == address(0)) revert ZeroAddress();
        if (emissionStart != 0) revert CampaignRan();
        if (poolInfo.length != 0) revert PoolsExist();
        if (address(_rewardToken) != IRewardVestingEscrow(vestingEscrow).token()) revert RewardTokenMismatch();
        rewardToken = _rewardToken;
        emit RewardTokenSet(address(_rewardToken));
    }

    /// @notice Number of pools.
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new pool. Cannot add the same LP token twice.
    /// @dev Always settles every pool first: changing `totalAllocPoint` without settling would
    ///      re-weight the elapsed interval of existing pools (over/under-payment).
    function add(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner nonDuplicated(_lpToken) {
        if (address(_lpToken) == address(0)) revert ZeroAddress();
        if (poolInfo.length >= MAX_POOLS) revert TooManyPools();
        massUpdatePools();
        // accrual is window-clamped, so starting from the current time is safe mid-campaign
        uint256 lastRewardTime = block.timestamp;
        totalAllocPoint += _allocPoint;
        poolExistence[address(_lpToken)] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accRewardPerShare: 0,
                lpSupply: 0
            })
        );
        emit PoolAdded(poolInfo.length - 1, address(_lpToken), _allocPoint, totalAllocPoint);
    }

    /// @notice Update a pool's allocation points.
    /// @dev Always settles every pool first (see {add}).
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        if (_pid >= poolInfo.length) revert InvalidPool();
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit PoolSet(_pid, _allocPoint, totalAllocPoint);
    }

    /**
     * @notice Re-weight several pools in ONE transaction. Owner-only.
     *
     * @dev BUILT FOR THE DAY-8 FLIP, and the reason is arithmetic rather than convenience. The two-week
     *      phased campaign opens week 1 on the MOTO pool plus its three pairs and switches the rest of the
     *      roster on at day 8. That is roughly 26 tokens across 2 pairs each — about 52 calls to {set}, and
     *      by day 8 the owner is the Ledger, so 52 hardware signatures in one sitting.
     *
     *      IT LEAKS WHILE IT RUNS, which is what makes this a correctness ask and not ergonomics. Emission is
     *      global and flat: until the flips land, the entire ~248 MOTO/sec keeps flowing to the week-1 pools.
     *      That is ~893k MOTO redirected per hour of lateness, paid to real stakers and unrecoverable. And
     *      because {set} re-splits immediately, a half-finished sitting skews the split pool by pool while it
     *      is in progress — so the ordering of 52 signatures becomes load-bearing. One atomic call removes
     *      both problems. `SeedVampPools.s.sol` already flagged this.
     *
     *      ONE {massUpdatePools} FOR THE WHOLE BATCH, before any assignment. That is the same ordering {set}
     *      and {add} use and it is the part that must not be got wrong: settling every pool at the old weights
     *      first is what keeps the flip non-retroactive in both directions. Settling per-pool inside the loop
     *      would price each pool against a `totalAllocPoint` already half-updated by its predecessors — the
     *      exact skew this exists to avoid, reintroduced inside the fix.
     *
     *      NOT per-pool scheduled activation. That was considered and explicitly not asked for: it touches the
     *      accrual path, and this does not.
     *
     *      Duplicate pids are permitted and the last write wins, deliberately — rejecting them would mean an
     *      O(n²) scan on a Ledger-signed call for a mistake that is visible in the emitted events. Every
     *      {PoolSet} is emitted, so the readback shows exactly what landed.
     */
    function setMany(uint256[] calldata _pids, uint256[] calldata _allocPoints) external onlyOwner {
        uint256 n = _pids.length;
        if (n == 0 || n != _allocPoints.length) revert LengthMismatch();
        // Settle EVERYTHING once, at the old weights, before a single assignment.
        massUpdatePools();
        uint256 total = totalAllocPoint;
        for (uint256 i; i < n; ++i) {
            uint256 pid = _pids[i];
            if (pid >= poolInfo.length) revert InvalidPool();
            total = total - poolInfo[pid].allocPoint + _allocPoints[i];
            poolInfo[pid].allocPoint = _allocPoints[i];
            emit PoolSet(pid, _allocPoints[i], total);
        }
        totalAllocPoint = total;
    }

    /// @notice A user's actively-staked LP amount in a pool — the withdrawable principal.
    function stakedBalance(uint256 _pid, address _user) external view returns (uint256) {
        if (_pid >= poolInfo.length) revert InvalidPool();
        return userInfo[_pid][_user].amount;
    }

    /// @notice Cumulative MOTO the campaign has emitted by time `_t` (across all pools, before the
    ///         per-pool allocation split). Monotonic: 0 before the start, `rewardPerSecond * DURATION`
    ///         (== budget minus dust) after the end. Flat/linear — the vampire has no halving.
    function emittedByTime(uint256 _t) public view returns (uint256) {
        uint256 start = emissionStart;
        if (start == 0 || _t <= start) return 0;
        uint256 end = emissionEnd;
        uint256 capped = _t < end ? _t : end;
        return rewardPerSecond * (capped - start);
    }

    /// @notice MOTO emitted in `[_from, _to)` across all pools (before the per-pool split), clamped to
    ///         the window by {emittedByTime}. Returns 0 outside the window, so accrual auto-stops.
    function emissionBetween(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= _from) return 0;
        return emittedByTime(_to) - emittedByTime(_from);
    }

    /// @notice The current per-second emission rate (0 before the start or after the end). View helper
    ///         for indexers / the frontend; accrual itself integrates via {emissionBetween}.
    function currentRewardPerSecond() external view returns (uint256) {
        if (emissionStart == 0 || block.timestamp < emissionStart || block.timestamp >= emissionEnd) return 0;
        return rewardPerSecond;
    }

    /// @notice Pending reward for `_user` in pool `_pid`.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        if (_pid >= poolInfo.length) revert InvalidPool();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 reward = emissionBetween(pool.lastRewardTime, block.timestamp) * pool.allocPoint / totalAllocPoint;
            accRewardPerShare += reward * ACC_PRECISION / lpSupply;
        }
        return user.amount * accRewardPerShare / ACC_PRECISION - user.rewardDebt;
    }

    /// @notice Reward tokens still available for distribution (excludes staked reward-token principal).
    function availableReward() public view returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(this));
        return balance > totalStakedRewardToken ? balance - totalStakedRewardToken : 0;
    }

    /// @notice Reward that was emitted but credited to NOBODY, and so is genuinely recoverable:
    ///         {availableReward} minus the stakers' outstanding, accrued-but-unharvested claim
    ///         (`totalCredited - totalHarvested`). Emission that streamed while a pool sat at zero stake
    ///         (or `totalAllocPoint == 0`) never entered any `accRewardPerShare`, so it is not in
    ///         `totalCredited` and shows up here — that is exactly what the hatch is for.
    /// @dev Call {massUpdatePools} first for an up-to-the-second figure; as a plain view this is settled
    ///      only to each pool's last `updatePool`, so it can read slightly HIGH between settlements.
    ///      {recoverUndistributedRewards} settles before it checks, so the enforced bound is never stale.
    /// @dev SATURATES, for the reason spelled out on `MasterChef.recoverableReward`: `totalCredited`
    ///      grows by the exact interval `reward`, while what the pool owes is a sum of per-user FLOOR
    ///      DIFFERENCES, which can exceed it by up to one wei per settling staker. Written as a plain
    ///      subtraction the accumulated drift eventually panics and bricks {recoverUndistributedRewards}
    ///      permanently — and this contract is one-shot, so there is no second campaign to unwedge it
    ///      with. A negative remainder means the outstanding claim is fully retired: nothing is owed.
    function recoverableReward() public view returns (uint256) {
        uint256 available = availableReward();
        // Less what `emergencyWithdraw` gave up: it sits in `totalCredited` and will never reach
        // `totalHarvested`, so without this it inflates the outstanding claim permanently.
        uint256 retired = totalHarvested + forfeitedReward;
        uint256 owed = totalCredited > retired ? totalCredited - retired : 0;
        return available > owed ? available - owed : 0;
    }

    /// @notice Recover undistributed reward tokens after the 14-day window has fully ended. Emission that
    ///         streamed while a pool sat at zero stake (or `totalAllocPoint == 0`) is never credited to
    ///         any `accRewardPerShare`, so it would be trapped once `renounceUpgradeability` is called —
    ///         this is the escape hatch. Bounded to {recoverableReward} (never touches staked
    ///         principal, and never a staker's accrued reward) and gated to
    ///         `block.timestamp >= emissionEnd + HARVEST_GRACE` so it can neither run against the live
    ///         window nor pre-empt the harvest window that follows it.
    /// @dev THE BOUND IS NOT `availableReward()` ALONE. That figure does not subtract stakers'
    ///      accrued-but-unclaimed rewards, so bounding on it would let the owner pull rewards users had
    ///      already earned, on a contract whose upgrade path may be renounced. The grace window alone
    ///      does not close that: it moves the
    ///      sweep 30 days later, but anyone who still has not harvested by then loses their pending
    ///      balance just the same. Timing and amount are separate defences and this contract needs both,
    ///      exactly as MasterChef has both. Now bounded by the liability-netted figure, with
    ///      `massUpdatePools()` first so both terms reflect a settled state.
    function recoverUndistributedRewards(address _to, uint256 _amount) external onlyOwner {
        if (_to == address(0)) revert ZeroAddress();
        // THE `emissionStart != 0` GUARD. The same flaw exists on MasterChef and is STRICTLY WORSE here:
        // VampChef is one-shot
        // (`startEmission` reverts once `emissionStart` is set), so if the vamp campaign is never run,
        // `emissionStart` stays 0 forever and the old `emissionStart == 0 ||` made every token ever sent
        // to this address permanently unrecoverable. There is no second campaign to unlock it with, and
        // `emergencyWithdraw` only returns staked LP, not reward-token balance.
        //
        // That window is not theoretical: this contract is deployed on T-day and funded when the campaign
        // starts, so between those two moments any mis-send lands in a contract with no exit.
        //
        // See {HARVEST_GRACE} for the second half. The two clauses answer different risks and do not
        // overlap: the `!= 0` guard
        // is about a campaign that NEVER ran (nothing to protect, so let the tokens out), the grace is about
        // one that JUST ran (stakers hold un-harvested claims, so hold the door shut).
        if (emissionStart != 0 && block.timestamp < emissionEnd + HARVEST_GRACE) revert EmissionActive();
        massUpdatePools();
        if (_amount > recoverableReward()) revert RewardsExhausted();
        rewardToken.safeTransfer(_to, _amount);
        emit UndistributedRewardsRecovered(_to, _amount);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending.
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of pool `_pid` to be up to date.
    function updatePool(uint256 _pid) public {
        if (_pid >= poolInfo.length) revert InvalidPool();
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) return;
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0 || totalAllocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            emit PoolUpdated(_pid, pool.accRewardPerShare, block.timestamp);
            return;
        }
        uint256 reward = emissionBetween(pool.lastRewardTime, block.timestamp) * pool.allocPoint / totalAllocPoint;
        totalCredited += reward; // stakers' running claim on the pot — see {recoverUndistributedRewards}
        pool.accRewardPerShare += reward * ACC_PRECISION / lpSupply;
        pool.lastRewardTime = block.timestamp;
        emit PoolUpdated(_pid, pool.accRewardPerShare, block.timestamp);
    }

    /// @notice Deposit `_amount` of pool `_pid`'s LP token for the caller (harvests pending first).
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        _deposit(_pid, _amount, msg.sender);
    }

    /**
     * @notice Name the one contract allowed to deposit on a user's behalf. Owner-only, and ONCE.
     *
     * @dev No re-point, no clear, no owner escape hatch — the second call reverts whatever it is passed.
     *      That is the whole difference from MasterChef's version of this setter, which is owner-settable
     *      for ever and therefore keeps C13 permanently reachable by a compromised or careless owner.
     *
     *      Deploy ordering follows from it: the zapper must exist before this is called, and calling it
     *      with the wrong address is unrecoverable. `DeployTDay` wires it in the same run that deploys the
     *      zap, so the two cannot drift apart.
     */
    function setTrustedZapper(address _trustedZapper) external onlyOwner {
        if (trustedZapper != address(0)) revert TrustedZapperAlreadySet();
        if (_trustedZapper == address(0)) revert ZeroAddress();
        trustedZapper = _trustedZapper;
        emit TrustedZapperSet(_trustedZapper);
    }

    /**
     * @notice Deposit `_amount` into pool `_pid` and credit `_user`. For the one-signature zap join.
     *
     * @dev THE GUARD IS THE SAME SHAPE AS MASTERCHEF'S, because the griefing vector is the
     *      same: crediting a deposit to somebody who already has a position force-settles their pending
     *      reward. Here that is a live harvest rather than a vest restart — the vamp chef has no cooldown
     *      and no per-user vest clock — but it is still someone else's transaction moving their money, so
     *      a stranger may only ever SEED A NEW position, never top up an existing one.
     *
     *      The trusted zapper is exempt from that restriction and nothing else. It is exempt safely only
     *      because {UniswapZap.zapInETHAndStake} and {UniswapZap.zapInTokenAndStake} passes `msg.sender` of the zap call and offers no recipient
     *      parameter, so a caller can only deposit for THEMSELVES through it. That property is pinned by
     *      `test_zapCreditsOnlyItsOwnCaller`; if a future zap takes a beneficiary, this exemption reopens
     *      C13 and the test is what says so.
     */
    function depositFor(uint256 _pid, uint256 _amount, address _user) external nonReentrant {
        if (_user == address(0)) revert ZeroAddress();
        if (msg.sender != _user && msg.sender != trustedZapper && userInfo[_pid][_user].amount != 0) {
            revert Unauthorized();
        }
        // PORTED FROM `MasterChef.depositFor` WITH ITS REASONING, because these two contracts are written
        // to share a safety property and were silently differing on it. Two things it does, and the second
        // is the one that is easy to miss:
        //
        // 1. A zero-amount call moves no money but still runs `_deposit`, which settles and emits
        //    `Deposit(_user, ...)`. So a stranger could publish a deposit record against ANY address for
        //    the cost of gas — the indexer decodes those events and they feed points and the public
        //    leaderboards. The guard above does not catch it: a fresh beneficiary has
        //    `userInfo.amount == 0`, which is exactly the legitimate seed path it exists to allow.
        //
        // 2. It is the SECOND, independent line under the `trustedZapper` exemption. That exemption is
        //    safe today only because `UniswapZap`/`MotoSwapZap` pass `msg.sender` and take no recipient
        //    parameter, so a caller can only deposit for THEMSELVES through them — a property that lives
        //    entirely in a different contract and is pinned by `test_zapCreditsOnlyItsOwnCaller`.
        //    MasterChef does not rest on that alone. Without this line the more serious version stays
        //    reachable if that property ever changes: a forced harvest on a victim's existing position,
        //    folding their vested half into escrow and restarting the clock.
        //
        // Deliberately a silent `return` rather than a revert, matching MasterChef exactly: a zapper
        // batching a zero-value leg must not have the whole call reverted under it.
        if (_amount == 0 && msg.sender != _user) return;
        _deposit(_pid, _amount, _user);
    }

    /**
     * @notice Harvest your pending reward from pool `_pid` without changing your stake.
     *
     * @dev BEHAVIOURALLY IDENTICAL to `deposit(_pid, 0)`, which is what this contract has always used as
     *      its harvest path. It exists for a user-safety reason rather than a functional one: a wallet
     *      decodes the calldata it is handed, so pressing "Harvest" in the app produced a MetaMask
     *      confirmation reading `Method: Deposit` — the opposite of the action taken, on the screen where
     *      people check they are not being tricked. Shipped on `MasterChef` first.
     *
     *      THE DEPOSIT BODY WAS EXTRACTED INTO {_deposit} RATHER THAN DUPLICATED HERE, and that is the
     *      whole of the diff beyond this function. Writing the harvest steps out again would have been the
     *      literal "three lines", but it would create a SECOND settlement path that can drift from the
     *      first — the exact risk this wrapper is supposed to avoid. `deposit` now calls the same private
     *      body it always ran; the code inside is unchanged, only its location.
     *
     *      Self-only: `_deposit` reads `msg.sender` throughout, so this adds no authority and no third-party
     *      settlement surface. The vamp has no cooldown queue, so unlike MasterChef there is no
     *      `CooldownActive` guard to inherit.
     */
    function harvest(uint256 _pid) external nonReentrant {
        _deposit(_pid, 0, msg.sender);
    }

    /// @dev The body `deposit` has always run. Unchanged — extracted so {harvest} shares it rather than
    ///      re-implementing it.
    /**
     * @dev `_for` is CREDITED; `msg.sender` PAYS. They are the same on every path except the trusted
     *      zapper, which pulls the LP it just minted and credits the user who called it.
     */
    function _deposit(uint256 _pid, uint256 _amount, address _for) private {
        if (_pid >= poolInfo.length) revert InvalidPool();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];

        updatePool(_pid);
        bool isRewardPool = address(pool.lpToken) == address(rewardToken);

        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accRewardPerShare / ACC_PRECISION - user.rewardDebt;
            if (pending > 0) _safeRewardTransfer(_for, _pid, pending);
        }

        uint256 netShares = 0;
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            netShares = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            user.amount += netShares;
            pool.lpSupply += netShares;
            if (isRewardPool) totalStakedRewardToken += netShares;
        }

        user.rewardDebt = user.amount * pool.accRewardPerShare / ACC_PRECISION;
        emit Deposit(_for, _pid, netShares);
    }

    /// @notice Withdraw `_amount` from pool `_pid`, harvesting pending rewards and returning principal
    ///         in the same call. No cooldown — the vampire phase exits are instant (PRD open-Q5).
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        if (_pid >= poolInfo.length) revert InvalidPool();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (_amount == 0 || user.amount < _amount) revert InsufficientStaked();

        updatePool(_pid);
        uint256 pending = user.amount * pool.accRewardPerShare / ACC_PRECISION - user.rewardDebt;
        if (pending > 0) _safeRewardTransfer(msg.sender, _pid, pending);

        user.amount -= _amount;
        pool.lpSupply -= _amount;
        if (address(pool.lpToken) == address(rewardToken)) {
            totalStakedRewardToken -= _amount;
        }

        user.rewardDebt = user.amount * pool.accRewardPerShare / ACC_PRECISION;
        pool.lpToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw everything immediately, forfeiting all pending rewards.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        if (_pid >= poolInfo.length) revert InvalidPool();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // SETTLE BEFORE SHRINKING `lpSupply`, same fix as MasterChef. Skipping it priced the whole
        // elapsed interval against the POST-exit supply, handing the leaver's un-settled accrual to
        // whoever remained rather than forfeiting it. Arithmetic only — the exit still always works.
        updatePool(_pid);

        uint256 staked = user.amount;

        // Record what is being given up, so it stops counting as a staker's outstanding claim forever.
        // See {forfeitedReward}. Read before `rewardDebt` is zeroed below.
        uint256 forfeited = staked * pool.accRewardPerShare / ACC_PRECISION - user.rewardDebt;
        if (forfeited > 0) {
            forfeitedReward += forfeited;
            emit RewardForfeited(msg.sender, _pid, forfeited);
        }

        pool.lpSupply -= staked;
        if (address(pool.lpToken) == address(rewardToken)) {
            totalStakedRewardToken -= staked;
        }

        user.amount = 0;
        user.rewardDebt = 0;

        if (staked > 0) pool.lpToken.safeTransfer(msg.sender, staked);
        emit EmergencyWithdraw(msg.sender, _pid, staked);
    }

    /// @dev Pay `_amount` of reward: 50% liquid now, 50% folded into the caller's 180-day vesting stream
    ///      (odd wei favors the liquid half), mirroring `MasterChef`.
    ///      Reverts the WHOLE call if the reward pool is exhausted; principal stays exitable via
    ///      `emergencyWithdraw`.
    function _safeRewardTransfer(address _to, uint256 _pid, uint256 _amount) private {
        if (_amount > availableReward()) revert RewardsExhausted();
        totalHarvested += _amount; // retires this much of {totalCredited}'s outstanding claim
        uint256 vested = _amount / 2;
        rewardToken.safeTransfer(_to, _amount - vested);
        if (vested > 0) {
            rewardToken.forceApprove(address(vestingEscrow), vested);
            vestingEscrow.depositFor(_to, vested);
        }
        emit RewardPaid(_to, _pid, _amount);
    }
}
