// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOracleProxy.sol";

/**
 * @title DisputeResolver
 * @notice Adds a dispute window between ResolutionMultiSig and OracleProxy,
 *         enabling stakeholders to challenge AI-driven resolutions before settlement.
 * @dev Auto-finalization and timeout handling are driven via OPERATOR_ROLE
 */
contract DisputeResolver is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    string public constant VERSION = "4.0.0";

    // ============ Roles ============

    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // ============ Constants ============

    uint256 public constant MIN_WINDOW_DURATION = 1 hours;
    uint256 public constant MAX_WINDOW_DURATION = 10 days;
    uint256 public constant MAX_ACTIVE_RETURN = 200;

    // ============ Enums ============

    enum DisputeStatus {
        Pending,    // 0: Resolution received, dispute window open
        Disputed,   // 1: Someone has disputed, awaiting re-vote
        Upheld,     // 2: Re-vote confirmed original result, dispute failed
        Overturned, // 3: Re-vote produced different result, dispute succeeded
        TooEarly,   // 4: Agent committee didn't reach consensus in time, market can be re-proposed
        Finalized   // 5: Resolution forwarded to OracleProxy
    }

    enum DisputeReason {
        WrongResult, // 0: Disputor claims the outcome is incorrect
        TooEarly     // 1: Disputor claims the event hasn't happened yet
    }

    // ============ Structs ============

    struct Resolution {
        bytes32 questionId;
        uint256[2] originalPayouts;   // [yes, no] payouts from original resolution
        uint256[2] finalPayouts;      // May differ if overturned
        DisputeStatus status;
        DisputeReason disputeReason;
        uint256 receivedAt;           // When resolve() was called
        uint256 disputeDeadline;      // receivedAt + disputeWindow
        uint256 reVoteDeadline;       // disputedAt + reVoteWindow
        address disputor;             // address(0) if undisputed
        address stakeToken;           // ERC20 token for this resolution
        uint256 rewardAmount;         // Set by admin, also = required stake
        uint256 stakedAmount;         // Actual amount locked by disputor
        bool claimed;                 // Whether stake/reward has been claimed
        bool disputeSucceeded;        // Whether the dispute was won by disputor
    }

    struct QuestionDeadlineConfig {
        uint256 disputeWindow;
        uint256 reVoteWindow;
        bool configured;
    }

    // ============ Events ============

    event ResolutionReceived(
        bytes32 indexed questionId,
        uint256[2] payouts,
        uint256 disputeDeadline
    );

    event RewardDeposited(
        bytes32 indexed questionId,
        address indexed stakeToken,
        uint256 amount
    );

    event RewardWithdrawn(
        bytes32 indexed questionId,
        uint256 amount
    );

    event DisputeFiled(
        bytes32 indexed questionId,
        address indexed disputor,
        uint256 stakeAmount,
        DisputeReason reason,
        uint256 reVoteDeadline
    );

    event DisputeResolved(
        bytes32 indexed questionId,
        bool overturned,
        uint256[2] finalPayouts
    );

    event DisputeTimedOut(
        bytes32 indexed questionId
    );

    event StakeClaimed(
        bytes32 indexed questionId,
        address indexed recipient,
        uint256 amount
    );

    event ResolutionFinalized(
        bytes32 indexed questionId,
        uint256[2] payouts
    );

    event GlobalDisputeWindowUpdated(uint256 oldWindow, uint256 newWindow);
    event GlobalReVoteWindowUpdated(uint256 oldWindow, uint256 newWindow);
    event QuestionDeadlineConfigured(bytes32 indexed questionId, uint256 disputeWindow, uint256 reVoteWindow);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event ResolutionMultiSigUpdated(address indexed oldMultiSig, address indexed newMultiSig);
    event OracleProxyUpdated(address indexed oldProxy, address indexed newProxy);
    event ReVoteWindowBoundsUpdated(uint256 min, uint256 max);

    // ============ Errors ============

    error ResolutionAlreadyExists(bytes32 questionId);
    error ResolutionNotFound(bytes32 questionId);
    error InvalidStatus(bytes32 questionId, DisputeStatus current);
    error DisputeWindowClosed(bytes32 questionId, uint256 deadline);
    error DisputeWindowOpen(bytes32 questionId, uint256 deadline);
    error ReVoteWindowClosed(bytes32 questionId, uint256 deadline);
    error ReVoteWindowOpen(bytes32 questionId, uint256 deadline);
    error NoRewardDeposited(bytes32 questionId);
    error RewardAlreadyDeposited(bytes32 questionId);
    error AlreadyClaimed(bytes32 questionId);
    error NotDisputor(address caller, address disputor);
    error ZeroAddress();
    error ZeroAmount();
    error InvalidPayouts();
    error CannotFinalize(bytes32 questionId);
    error RewardNotReclaimable(bytes32 questionId);
    error InvalidWindowDuration(uint256 value, uint256 min, uint256 max);
    error ActiveQuestionsTooMany(uint256 count, uint256 max);

    // ============ State Variables ============

    /// @notice Address of ResolutionMultiSig contract (AI agent committee, has RESOLVER_ROLE)
    address public resolutionMultiSig;

    /// @notice Address of OracleProxy contract (forwarding target)
    address public oracleProxy;

    /// @notice Treasury address that receives forfeited stakes
    address public treasury;

    /// @notice Global default dispute window duration in seconds (e.g., 86400 = 24h)
    uint256 public globalDisputeWindow;

    /// @notice Global default re-vote window duration in seconds (e.g., 172800 = 48h)
    uint256 public globalReVoteWindow;

    /// @notice Mapping from questionId to Resolution
    mapping(bytes32 => Resolution) private _resolutions;

    /// @notice Track active question IDs for querying and iteration
    bytes32[] private _activeQuestionIds;
    mapping(bytes32 => uint256) private _questionIdIndex; // questionId -> index+1 (0 = not tracked)

    /// @notice Per-question deadline overrides; falls back to global defaults if not configured
    mapping(bytes32 => QuestionDeadlineConfig) private _questionDeadlines;

    /// @notice Configurable minimum re-vote window (>= MIN_WINDOW_DURATION)
    uint256 public minReVoteWindow;

    /// @notice Configurable maximum re-vote window (<= MAX_WINDOW_DURATION)
    uint256 public maxReVoteWindow;

    /// @dev Reserved storage gap for future upgrades
    uint256[38] private __gap;

    // ============ Constructor ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the DisputeResolver contract
     * @param _admin Address that gets DEFAULT_ADMIN_ROLE
     * @param _resolutionMultiSig Address of ResolutionMultiSig contract (gets RESOLVER_ROLE)
     * @param _oracleProxy Address of OracleProxy contract
     * @param _treasury Treasury for forfeited stakes
     * @param _disputeWindow Dispute window duration in seconds
     * @param _reVoteWindow Re-vote window duration in seconds
     */
    function initialize(
        address _admin,
        address _resolutionMultiSig,
        address _oracleProxy,
        address _treasury,
        uint256 _disputeWindow,
        uint256 _reVoteWindow
    ) external initializer {
        if (_admin == address(0)) revert ZeroAddress();
        if (_resolutionMultiSig == address(0)) revert ZeroAddress();
        if (_oracleProxy == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();
        if (_disputeWindow < MIN_WINDOW_DURATION || _disputeWindow > MAX_WINDOW_DURATION)
            revert InvalidWindowDuration(_disputeWindow, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);
        if (_reVoteWindow < MIN_WINDOW_DURATION || _reVoteWindow > MAX_WINDOW_DURATION)
            revert InvalidWindowDuration(_reVoteWindow, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);

        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        resolutionMultiSig = _resolutionMultiSig;
        oracleProxy = _oracleProxy;
        treasury = _treasury;
        globalDisputeWindow = _disputeWindow;
        globalReVoteWindow = _reVoteWindow;
        minReVoteWindow = MIN_WINDOW_DURATION;
        maxReVoteWindow = MAX_WINDOW_DURATION;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(RESOLVER_ROLE, _resolutionMultiSig);
    }

    // ============ Core Functions ============

    /**
     * @notice Called by ResolutionMultiSig for initial resolution OR re-vote result
     * @dev If questionId doesn't exist, creates new resolution in Pending state
     *      If questionId exists and is Disputed, resolves the dispute and auto-finalizes
     * @param questionId The question ID being resolved
     * @param payouts The payout array [yesAmount, noAmount]
     */
    function resolve(
        bytes32 questionId,
        uint256[] calldata payouts
    ) external onlyRole(RESOLVER_ROLE) nonReentrant whenNotPaused {
        // Validate payouts
        if (payouts.length != 2) revert InvalidPayouts();
        if (payouts[0] == 0 && payouts[1] == 0) revert InvalidPayouts();
        // Upper-bound validation intentionally omitted: RESOLVER_ROLE is a trusted
        // AI agent committee and payouts are oracle probability weights, not token amounts.

        Resolution storage res = _resolutions[questionId];

        if (res.receivedAt == 0) {
            // CASE 1: New resolution - create Pending state
            _createResolution(questionId, payouts);
        } else if (res.status == DisputeStatus.Disputed) {
            // CASE 2: Re-vote result for disputed resolution
            _resolveDispute(questionId, payouts);
            // Auto-finalize after dispute resolution
            _finalize(questionId);
        } else if (res.status == DisputeStatus.TooEarly) {
            // CASE 3: Agent committee's final resolution after a dispute timeout.
            // The dispute window is intentionally skipped here: the resolution was
            // already disputed once (hence TooEarly), the committee is providing
            // its authoritative answer, and no second dispute window is warranted.
            res.finalPayouts[0] = payouts[0];
            res.finalPayouts[1] = payouts[1];
            res.status = DisputeStatus.Finalized;

            // Already removed from active list during timeout, no need to remove again
            uint256[] memory finalPayouts = new uint256[](2);
            finalPayouts[0] = payouts[0];
            finalPayouts[1] = payouts[1];
            IOracleProxy(oracleProxy).resolve(questionId, finalPayouts);

            emit ResolutionFinalized(questionId, res.finalPayouts);
        } else {
            revert InvalidStatus(questionId, res.status);
        }
    }

    /**
     * @notice Dispute a pending resolution. Caller must have approved stakeAmount.
     * @dev Only a single disputor is permitted per resolution. First caller wins
     *      the slot; subsequent callers receive InvalidStatus. This keeps claim
     *      logic simple and avoids pro-rata split complexity.
     * @param questionId The question ID to dispute
     * @param reason The reason for dispute (WrongResult or TooEarly)
     */
    function dispute(
        bytes32 questionId,
        DisputeReason reason
    ) external nonReentrant whenNotPaused {
        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // Validate status is Pending
        if (res.status != DisputeStatus.Pending) {
            revert InvalidStatus(questionId, res.status);
        }

        // Validate within dispute window
        if (block.timestamp >= res.disputeDeadline) {
            revert DisputeWindowClosed(questionId, res.disputeDeadline);
        }

        // Validate reward has been deposited (and thus stakeToken is set)
        if (res.rewardAmount == 0) {
            revert NoRewardDeposited(questionId);
        }

        // Update resolution (all state changes before external call — CEI pattern)
        res.status = DisputeStatus.Disputed;
        res.disputeReason = reason;
        res.disputor = msg.sender;
        res.stakedAmount = res.rewardAmount;
        QuestionDeadlineConfig storage cfg = _questionDeadlines[questionId];
        res.reVoteDeadline = block.timestamp + (cfg.configured ? cfg.reVoteWindow : globalReVoteWindow);

        emit DisputeFiled(questionId, msg.sender, res.rewardAmount, reason, res.reVoteDeadline);

        // Transfer stake from disputor (after all state updates — CEI pattern)
        IERC20(res.stakeToken).safeTransferFrom(msg.sender, address(this), res.rewardAmount);
    }

    /**
     * @notice Claim stake/reward after dispute is resolved.
     * @dev Intentionally includes whenNotPaused: this guards against fund taken when there is a known contract issue
     * @param questionId The resolution to claim for
     */
    function claim(bytes32 questionId) external nonReentrant whenNotPaused {
        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // Must have a disputor to claim
        if (res.disputor == address(0)) revert InvalidStatus(questionId, res.status);

        // Validate claimable status (includes Finalized for auto-finalized disputes)
        if (res.status != DisputeStatus.Upheld &&
            res.status != DisputeStatus.Overturned &&
            res.status != DisputeStatus.TooEarly &&
            res.status != DisputeStatus.Finalized) {
            revert InvalidStatus(questionId, res.status);
        }

        // Validate not already claimed
        if (res.claimed) revert AlreadyClaimed(questionId);

        res.claimed = true;

        if (res.disputeSucceeded) {
            // Dispute succeeded - only disputor can claim
            if (msg.sender != res.disputor) {
                revert NotDisputor(msg.sender, res.disputor);
            }
            // Transfer stake + reward to disputor
            uint256 totalAmount = res.stakedAmount + res.rewardAmount;
            res.rewardAmount = 0;
            res.stakedAmount = 0;
            IERC20(res.stakeToken).safeTransfer(res.disputor, totalAmount);
            emit StakeClaimed(questionId, res.disputor, totalAmount);
        } else {
            // Dispute failed (Upheld or Finalized with same payouts) - anyone can trigger, stake goes to treasury
            // rewardAmount intentionally kept intact for withdrawRewardPool()
            uint256 stakedAmt = res.stakedAmount;
            res.stakedAmount = 0;
            IERC20(res.stakeToken).safeTransfer(treasury, stakedAmt);
            emit StakeClaimed(questionId, treasury, stakedAmt);
        }
    }

    // ============ Operator Functions ============

    /**
     * @notice Finalize a pending resolution after dispute window has expired
     * @dev Called by OPERATOR_ROLE when block.timestamp > disputeDeadline
     * @param questionId The resolution to finalize
     */
    function finalize(bytes32 questionId) external onlyRole(OPERATOR_ROLE) nonReentrant whenNotPaused {
        _finalize(questionId);
    }

    /**
     * @notice Timeout a disputed resolution when re-vote deadline has passed
     * @dev Called by OPERATOR_ROLE when block.timestamp > reVoteDeadline
     * @param questionId The disputed resolution to timeout
     */
    function timeoutDispute(bytes32 questionId) external onlyRole(OPERATOR_ROLE) nonReentrant whenNotPaused {
        _timeoutDispute(questionId);
    }

    /**
     * @notice Pre-configure per-question dispute and re-vote window durations
     * @dev Called by OPERATOR_ROLE BEFORE resolve() creates a resolution.
     *      If not called, global defaults apply.
     * @param questionId The question ID to configure
     * @param _disputeWindow Dispute window in seconds
     * @param _reVoteWindow Re-vote window in seconds
     */
    function configureQuestionDeadline(
        bytes32 questionId,
        uint256 _disputeWindow,
        uint256 _reVoteWindow
    ) external onlyRole(OPERATOR_ROLE) nonReentrant whenNotPaused {
        if (_disputeWindow < MIN_WINDOW_DURATION || _disputeWindow > MAX_WINDOW_DURATION)
            revert InvalidWindowDuration(_disputeWindow, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);
        if (_reVoteWindow < minReVoteWindow || _reVoteWindow > maxReVoteWindow)
            revert InvalidWindowDuration(_reVoteWindow, minReVoteWindow, maxReVoteWindow);

        // Prevent modifying config after resolution exists (reVoteWindow
        // is read dynamically at dispute() time, so changing it post-resolution
        // could allow deadline manipulation)
        if (_resolutions[questionId].receivedAt != 0) revert ResolutionAlreadyExists(questionId);

        _questionDeadlines[questionId] = QuestionDeadlineConfig({
            disputeWindow: _disputeWindow,
            reVoteWindow: _reVoteWindow,
            configured: true
        });

        emit QuestionDeadlineConfigured(questionId, _disputeWindow, _reVoteWindow);
    }

    // ============ Admin Functions ============

    /**
     * @notice Deposit reward pool for a resolution (sets stake token and reward amount)
     * @dev Once deposited, the stakeToken address cannot be changed for this resolution.
     *      This is intentional: changing it mid-lifecycle would break stake/reward accounting.
     * @param questionId The resolution to deposit for
     * @param stakeToken The ERC20 token for this resolution's stake/reward
     * @param amount The amount to deposit (also becomes required stake)
     */
    function depositRewardPool(
        bytes32 questionId,
        address stakeToken,
        uint256 amount
    ) external onlyRole(REWARD_MANAGER_ROLE) nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (stakeToken == address(0)) revert ZeroAddress();

        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // Validate status is Pending
        if (res.status != DisputeStatus.Pending) {
            revert InvalidStatus(questionId, res.status);
        }

        // Validate reward not already deposited
        if (res.rewardAmount > 0) {
            revert RewardAlreadyDeposited(questionId);
        }

        // Dispute window starts now, at deposit time (not at resolution time).
        // This ensures the full window is available for disputors after reward is deposited.
        QuestionDeadlineConfig storage cfg = _questionDeadlines[questionId];
        res.disputeDeadline = block.timestamp + (cfg.configured ? cfg.disputeWindow : globalDisputeWindow);

        // Update state before external call (CEI pattern)
        res.stakeToken = stakeToken;
        res.rewardAmount = amount;

        emit RewardDeposited(questionId, stakeToken, amount);

        // Transfer tokens from caller (after all state updates — CEI pattern)
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw unused reward from a finalized or upheld resolution
     * @dev Includes whenNotPaused for consistency: if contract is paused due to
     *      a known issue, admin should upgrade/fix first, then unpause to withdraw.
     * @param questionId The resolution to withdraw from
     */
    function withdrawRewardPool(bytes32 questionId) external onlyRole(REWARD_MANAGER_ROLE) nonReentrant whenNotPaused {
        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // If a disputor exists, check claim state
        if (res.disputor != address(0)) {
            // Cannot withdraw if dispute succeeded (reward belongs to disputor)
            if (res.disputeSucceeded) {
                revert RewardNotReclaimable(questionId);
            }

            // For upheld disputes, require claim processed first
            if (!res.claimed) {
                revert RewardNotReclaimable(questionId);
            }
        }

        // Must be in a terminal state: Finalized (no dispute or upheld+claimed) or Upheld+claimed
        if (res.status != DisputeStatus.Finalized &&
            !(res.status == DisputeStatus.Upheld && res.claimed)) {
            revert RewardNotReclaimable(questionId);
        }

        uint256 amount = res.rewardAmount;
        if (amount == 0) revert ZeroAmount();

        res.rewardAmount = 0;

        IERC20(res.stakeToken).safeTransfer(msg.sender, amount);

        emit RewardWithdrawn(questionId, amount);
    }

    /**
     * @notice Update the global default dispute window duration
     * @param _disputeWindow New dispute window in seconds
     */
    function setGlobalDisputeWindow(uint256 _disputeWindow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_disputeWindow < MIN_WINDOW_DURATION || _disputeWindow > MAX_WINDOW_DURATION)
            revert InvalidWindowDuration(_disputeWindow, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);
        uint256 oldWindow = globalDisputeWindow;
        globalDisputeWindow = _disputeWindow;
        emit GlobalDisputeWindowUpdated(oldWindow, _disputeWindow);
    }

    /**
     * @notice Update the global default re-vote window duration
     * @param _reVoteWindow New re-vote window in seconds
     */
    function setGlobalReVoteWindow(uint256 _reVoteWindow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_reVoteWindow < minReVoteWindow || _reVoteWindow > maxReVoteWindow)
            revert InvalidWindowDuration(_reVoteWindow, minReVoteWindow, maxReVoteWindow);
        uint256 oldWindow = globalReVoteWindow;
        globalReVoteWindow = _reVoteWindow;
        emit GlobalReVoteWindowUpdated(oldWindow, _reVoteWindow);
    }

    /**
     * @notice Set configurable min/max bounds for the re-vote window
     * @dev Bounds are constrained within absolute constants [MIN_WINDOW_DURATION, MAX_WINDOW_DURATION]
     * @param _min Minimum allowed re-vote window duration
     * @param _max Maximum allowed re-vote window duration
     */
    function setReVoteWindowBounds(uint256 _min, uint256 _max) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_min < MIN_WINDOW_DURATION)
            revert InvalidWindowDuration(_min, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);
        if (_max > MAX_WINDOW_DURATION)
            revert InvalidWindowDuration(_max, MIN_WINDOW_DURATION, MAX_WINDOW_DURATION);
        if (_min > _max)
            revert InvalidWindowDuration(_min, _min, _max);
        minReVoteWindow = _min;
        maxReVoteWindow = _max;
        emit ReVoteWindowBoundsUpdated(_min, _max);
    }

    /**
     * @notice Update the treasury address
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasury == address(0)) revert ZeroAddress();
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @notice Update the ResolutionMultiSig address (also updates RESOLVER_ROLE)
     * @param _resolutionMultiSig New ResolutionMultiSig address
     */
    function setResolutionMultiSig(address _resolutionMultiSig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_resolutionMultiSig == address(0)) revert ZeroAddress();
        address oldMultiSig = resolutionMultiSig;

        // Revoke role from old, grant to new
        _revokeRole(RESOLVER_ROLE, oldMultiSig);
        _grantRole(RESOLVER_ROLE, _resolutionMultiSig);

        resolutionMultiSig = _resolutionMultiSig;
        emit ResolutionMultiSigUpdated(oldMultiSig, _resolutionMultiSig);
    }

    /**
     * @notice Update the OracleProxy address
     * @param _oracleProxy New OracleProxy address
     */
    function setOracleProxy(address _oracleProxy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_oracleProxy == address(0)) revert ZeroAddress();
        address oldProxy = oracleProxy;
        oracleProxy = _oracleProxy;
        emit OracleProxyUpdated(oldProxy, _oracleProxy);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /**
     * @notice Authorize an upgrade to a new implementation
     * @dev Only callable by DEFAULT_ADMIN_ROLE. Required by UUPSUpgradeable.
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ============ View Functions ============

    /**
     * @notice Get a resolution by questionId
     * @param questionId The question ID
     * @return The Resolution struct
     */
    function getResolution(bytes32 questionId) external view returns (Resolution memory) {
        return _resolutions[questionId];
    }

    /**
     * @notice Check if a resolution can be disputed
     * @param questionId The question ID
     * @return True if disputable
     */
    function isDisputable(bytes32 questionId) external view returns (bool) {
        Resolution storage res = _resolutions[questionId];
        return res.status == DisputeStatus.Pending &&
               block.timestamp < res.disputeDeadline &&
               res.rewardAmount > 0;
    }

    /**
     * @notice Check if a resolution can be finalized
     * @param questionId The question ID
     * @return True if finalizable
     */
    function isFinalizable(bytes32 questionId) external view returns (bool) {
        Resolution storage res = _resolutions[questionId];

        if (res.status == DisputeStatus.Finalized ||
            res.status == DisputeStatus.TooEarly) {
            return false;
        }

        if (res.status == DisputeStatus.Pending) {
            return block.timestamp > res.disputeDeadline;
        }

        if (res.status == DisputeStatus.Disputed) {
            return false;
        }

        // Upheld or Overturned
        return true;
    }

    /**
     * @notice Check if a disputed resolution has timed out
     * @param questionId The question ID
     * @return True if the resolution is Disputed and past reVoteDeadline
     */
    function isDisputeTimedOut(bytes32 questionId) external view returns (bool) {
        Resolution storage res = _resolutions[questionId];
        return res.status == DisputeStatus.Disputed &&
               block.timestamp > res.reVoteDeadline;
    }

    /**
     * @notice Get the required stake amount for a resolution
     * @param questionId The question ID
     * @return The required stake amount
     */
    function getRequiredStake(bytes32 questionId) external view returns (uint256) {
        return _resolutions[questionId].rewardAmount;
    }

    /**
     * @notice Get all active question IDs (for monitoring)
     * @dev Reverts if the list exceeds MAX_ACTIVE_RETURN to protect on-chain
     *      callers from unbounded gas costs. Use the paginated overload instead.
     * @return Array of active question IDs
     */
    function getActiveQuestionIds() external view returns (bytes32[] memory) {
        if (_activeQuestionIds.length > MAX_ACTIVE_RETURN) {
            revert ActiveQuestionsTooMany(_activeQuestionIds.length, MAX_ACTIVE_RETURN);
        }
        return _activeQuestionIds;
    }

    /**
     * @notice Get a paginated slice of active question IDs
     * @param offset Zero-based index of the first element to return
     * @param limit Maximum number of elements to return (0 = all remaining)
     * @return Slice of active question IDs
     */
    function getActiveQuestionIdsPaginated(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        uint256 total = _activeQuestionIds.length;
        if (offset >= total) return new bytes32[](0);
        uint256 available = total - offset;
        uint256 count = (limit == 0 || limit > available) ? available : limit;
        bytes32[] memory result = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = _activeQuestionIds[offset + i];
        }
        return result;
    }

    /**
     * @notice Get effective deadline config for a question
     * @param questionId The question ID
     * @return effectiveDisputeWindow The dispute window that will be used
     * @return effectiveReVoteWindow The re-vote window that will be used
     * @return isCustom True if per-question config is set
     */
    function getQuestionDeadlineConfig(bytes32 questionId) external view returns (
        uint256 effectiveDisputeWindow,
        uint256 effectiveReVoteWindow,
        bool isCustom
    ) {
        QuestionDeadlineConfig storage cfg = _questionDeadlines[questionId];
        if (cfg.configured) {
            return (cfg.disputeWindow, cfg.reVoteWindow, true);
        }
        return (globalDisputeWindow, globalReVoteWindow, false);
    }

    // ============ Internal Functions ============

    /**
     * @notice Create a new resolution in Pending state
     * @param questionId The question ID
     * @param payouts The payout array [yesAmount, noAmount]
     */
    function _createResolution(bytes32 questionId, uint256[] calldata payouts) internal {
        Resolution storage res = _resolutions[questionId];

        res.questionId = questionId;
        res.originalPayouts[0] = payouts[0];
        res.originalPayouts[1] = payouts[1];
        res.finalPayouts[0] = payouts[0];
        res.finalPayouts[1] = payouts[1];
        res.status = DisputeStatus.Pending;
        res.receivedAt = block.timestamp;
        // Dispute window starts when reward is deposited, not at resolution time.
        // Sentinel value blocks finalize() and keeps dispute() open until deposit.
        res.disputeDeadline = type(uint256).max;

        _addToActiveQuestionIds(questionId);

        emit ResolutionReceived(questionId, res.originalPayouts, res.disputeDeadline);
    }

    /**
     * @notice Resolve a disputed resolution with re-vote result
     * @param questionId The question ID
     * @param newPayouts The re-vote result payouts
     */
    function _resolveDispute(bytes32 questionId, uint256[] calldata newPayouts) internal {
        Resolution storage res = _resolutions[questionId];

        // Re-vote window is exclusive of the deadline second: at exactly reVoteDeadline,
        // the window is closed and only timeoutDispute() may act.
        if (block.timestamp >= res.reVoteDeadline) {
            revert ReVoteWindowClosed(questionId, res.reVoteDeadline);
        }

        // Compare payouts
        bool overturned = (newPayouts[0] != res.originalPayouts[0]) ||
                          (newPayouts[1] != res.originalPayouts[1]);

        if (overturned) {
            res.status = DisputeStatus.Overturned;
            res.disputeSucceeded = true;
            res.finalPayouts[0] = newPayouts[0];
            res.finalPayouts[1] = newPayouts[1];
        } else {
            res.status = DisputeStatus.Upheld;
        }

        emit DisputeResolved(questionId, overturned, res.finalPayouts);
    }

    /**
     * @notice Finalize a resolution and forward to OracleProxy
     * @param questionId The question ID to finalize
     */
    function _finalize(bytes32 questionId) internal {
        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // Cannot finalize TooEarly resolutions
        if (res.status == DisputeStatus.TooEarly) {
            revert CannotFinalize(questionId);
        }

        // Already finalized
        if (res.status == DisputeStatus.Finalized) {
            revert InvalidStatus(questionId, res.status);
        }

        // Check finalization conditions based on status
        if (res.status == DisputeStatus.Pending) {
            // Finalize is inclusive of the deadline second: at exactly disputeDeadline,
            // finalize wins and dispute() is already closed.
            if (block.timestamp < res.disputeDeadline) {
                revert DisputeWindowOpen(questionId, res.disputeDeadline);
            }
        } else if (res.status == DisputeStatus.Disputed) {
            // Still disputed, not resolved yet
            revert InvalidStatus(questionId, res.status);
        }
        // Upheld and Overturned can be finalized immediately

        res.status = DisputeStatus.Finalized;

        _removeFromActiveQuestionIds(questionId);

        // Convert to dynamic array for IOracleProxy call
        uint256[] memory payouts = new uint256[](2);
        payouts[0] = res.finalPayouts[0];
        payouts[1] = res.finalPayouts[1];

        // Forward to OracleProxy
        IOracleProxy(oracleProxy).resolve(questionId, payouts);

        emit ResolutionFinalized(questionId, res.finalPayouts);
    }

    /**
     * @notice Handle dispute timeout (committee didn't vote in time)
     * @param questionId The question ID
     */
    function _timeoutDispute(bytes32 questionId) internal {
        Resolution storage res = _resolutions[questionId];

        // Validate resolution exists
        if (res.receivedAt == 0) revert ResolutionNotFound(questionId);

        // Validate status is Disputed
        if (res.status != DisputeStatus.Disputed) {
            revert InvalidStatus(questionId, res.status);
        }

        // Timeout is inclusive of the deadline second: at exactly reVoteDeadline,
        // timeout wins and _resolveDispute() is already closed.
        if (block.timestamp < res.reVoteDeadline) {
            revert ReVoteWindowOpen(questionId, res.reVoteDeadline);
        }

        // Agent committee didn't reach consensus in time - dispute succeeds
        res.status = DisputeStatus.TooEarly;
        res.disputeSucceeded = true;

        _removeFromActiveQuestionIds(questionId);

        emit DisputeTimedOut(questionId);
    }

    /**
     * @notice Add a question ID to the active tracking list
     * @param questionId The question ID to add
     */
    function _addToActiveQuestionIds(bytes32 questionId) internal {
        if (_questionIdIndex[questionId] == 0) {
            _activeQuestionIds.push(questionId);
            _questionIdIndex[questionId] = _activeQuestionIds.length; // 1-indexed
        }
    }

    /**
     * @notice Remove a question ID from the active tracking list
     * @param questionId The question ID to remove
     */
    function _removeFromActiveQuestionIds(bytes32 questionId) internal {
        uint256 indexPlusOne = _questionIdIndex[questionId];
        if (indexPlusOne > 0) {
            uint256 index = indexPlusOne - 1;
            uint256 lastIndex = _activeQuestionIds.length - 1;
            if (index != lastIndex) {
                bytes32 lastId = _activeQuestionIds[lastIndex];
                _activeQuestionIds[index] = lastId;
                _questionIdIndex[lastId] = indexPlusOne;
            }
            _activeQuestionIds.pop();
            delete _questionIdIndex[questionId];
        }
    }
}
