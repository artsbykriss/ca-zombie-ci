// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IAlphatrionReward } from "./interfaces/IAlphatrionReward.sol";
import { ICiphertextDigests } from "./interfaces/ICiphertextDigests.sol";
import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";
import { SpaceBridgeConfigGuards } from "./SpaceBridgeConfigGuards.sol";
import { SpaceBridgeOwnable } from "./SpaceBridgeOwnable.sol";
import { Pausable } from "./Pausable.sol";

/**
 * @notice External: FHEExecutor.settlement()
 * @dev Mirror of ISpaceBridgeSettlement in fheexecutor
 *      Signature must match: distributeRevenue(address,address,address[],uint256[])
 */
interface ISettlement {
    function distributeRevenue(
        address user,
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    function getFeeUserOf(bytes32 handle) external view returns (address);

    function getFeePaidOf(bytes32 handle) external view returns (uint256);
}

/**
 * @title AlphatrionReward contract
 * @notice Manages reward distribution to Alphatrions for computation work
 * @dev Only registered Alphatrions can call distribution functions
 */
contract AlphatrionReward is IAlphatrionReward, SpaceBridgeConfigGuards, SpaceBridgeOwnable,
                            UUPSUpgradeable, Pausable, ReentrancyGuardTransient {
     /**
     * @notice Basis points denominator (100% = 10000)
     * @dev Using basis points for precision to avoid floating point issues
     */
    uint256 private constant BASIS_POINTS = 10000;

    /**
    * @notice Default reward split: 75% for computation participants
    * @notice Default reward split: 5% for transaction caller
    * @notice Default reward split: 20% for protocol reserve
    */
    uint256 private constant DEFAULT_COMPUTATION_SHARE = 7500;
    uint256 private constant DEFAULT_CALLER_INCENTIVE = 500;
    uint256 private constant DEFAULT_PROTOCOL_RESERVE = 2000;

    /**
     * @dev The following constants are used for versioning the contract.
     */
    string private constant CONTRACT_NAME = "AlphatrionReward";
    uint256 private constant MAJOR_VERSION = 0;
    uint256 private constant MINOR_VERSION = 1;
    uint256 private constant PATCH_VERSION = 0;

    /**
     * @dev Storage location has been computed using the following command:
     * keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.AlphatrionReward")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 private constant ALPHATRION_REWARD_STORAGE_LOCATION =
        0xf362472a7053cb497b597af266fefe4646e07dde0a0ca8beec2f96c16734c900;

    /**
     * @notice Configuration for reward split ratios
     * @param computationShare Percentage for computation participants (basis points)
     * @param callerIncentive Percentage for transaction caller (basis points)
     * @param protocolReserve Percentage for protocol reserve (basis points)
     */
    struct RewardSplitConfig {
        uint256 computationShare;   
        uint256 callerIncentive; 
        uint256 protocolReserve;
    }

    /**
     * @notice The contract's variable storage struct
     */
    struct AlphatrionRewardStorage {
        /// @notice The FHEExecutor contract that handles token transfers
        ISettlement fheOpSettle;
        /// @notice The CiphertextDigests contract that get consensus tx sender from the handles
        ICiphertextDigests cipherDigests;
        /// @notice The SpaceBridgeConfig contract that get alphatrion sizes
        ISpaceBridgeConfig spacebridgeConfig;
        
        /// @notice Current reward split configuration
        RewardSplitConfig rewardSplitConfig;
        /// @notice Track which jobIds have been distributed to prevent double distribution
        mapping(bytes32 jobId => bool isDistributed) distributedJobs;
        /// @notice A handle's fee may be distributed at most once, ever
        mapping(bytes32 handle => bool isDistributed) distributedHandles;
        /// @notice Total distributed rewards for each Alphatrion
        mapping(address alphatrionAddress => uint256 totalDistributed) totalDistributedRewards;

        /// @notice Address to receive protocol reserve rewards
        address protocolFeeRecipient;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract
     * @param _spaceBridgeConfigAddress The address of the SpaceBridgeConfig contract
     * @param _fheExecutorAddress The address of the FHEExecutor contract
     * @param _cipherDigestAddress The address of the CiphertextDigests contract
     * @param _protocolFeeRecipient The address to receive protocol reserve rewards
     */
    function initialize(
        address _spaceBridgeConfigAddress,
        address _fheExecutorAddress,
        address _cipherDigestAddress,
        address _protocolFeeRecipient
    ) public initializer {
        __SpaceBridgeConfigGuards_init(_spaceBridgeConfigAddress);
        __SpaceBridgeOwnable_init(_spaceBridgeConfigAddress);
        __PausableWithSpaceBridge_init(_spaceBridgeConfigAddress);

        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        require(_fheExecutorAddress != address(0), "Invalid FHEExecutor address");
        $.fheOpSettle = ISettlement(_fheExecutorAddress);

        require(_cipherDigestAddress != address(0), "Invalid CiphertextDigest address");
        $.cipherDigests = ICiphertextDigests(_cipherDigestAddress);

        require(_spaceBridgeConfigAddress != address(0), "Invalid SpaceBridgeConfig address");
        $.spacebridgeConfig = ISpaceBridgeConfig(_spaceBridgeConfigAddress);

        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        $.protocolFeeRecipient = _protocolFeeRecipient;

        // Initialize with default split
        $.rewardSplitConfig.computationShare = DEFAULT_COMPUTATION_SHARE;
        $.rewardSplitConfig.callerIncentive = DEFAULT_CALLER_INCENTIVE;
        $.rewardSplitConfig.protocolReserve = DEFAULT_PROTOCOL_RESERVE;
    }

    /**
     * @notice Checks if the sender is authorized to upgrade the contract and reverts otherwise.
     */
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlySpaceBridgeOwner {}

    /**
     * @notice See {IAlphatrionReward-distributeComputationReward}.
     * @dev The jobId identifies a single transaction and distribution is
     *      all-or-nothing: the transaction must have reached consensus —
     *      proven by any one of its handles having a non-empty consensus
     *      sender list, since only allow-permission handles are committed
     *      on-chain — and every rewarded handle must pass the on-chain
     *      fee-ledger checks, otherwise the whole call reverts and neither
     *      the job nor any handle is marked distributed.
     *
     *      Each rewarded handle is split into three legs per `rewardSplitConfig`:
     *      - computation leg: divided evenly among the transaction's
     *        consensus transaction senders;
     *      - caller incentive leg: paid to `msg.sender`, whether or not the
     *        caller appears in any consensus sender list;
     *      - protocol reserve leg: paid to `protocolFeeRecipient`.
     *
     *      Rounding is fully deterministic: the computation leg is computed by
     *      subtraction (so the three legs always sum exactly to the handle
     *      reward) and the division dust of the even split is credited to
     *      `protocolFeeRecipient`. A conservation check before settlement
     *      asserts that the recipient amounts sum exactly to the total reward,
     *      so no remainder can be stranded in the payer's accrued-revenue
     *      ledger (audit N5) and the configured split is always enforced
     *      (audit N2).
     */
    function distributeComputationReward(
        bytes32 jobId,
        address rewardPayer,
        address rewardToken,
        bytes32[] calldata ctHandles,
        uint256[] calldata rewards
    ) external virtual whenNotPaused onlyAlphatrionTxSender nonReentrant {
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();

        // Prevent double distribution
        if ($.distributedJobs[jobId]) {
            revert RewardDistributionFailed("Job already distributed");
        }

        // Validate inputs
        if (rewardPayer == address(0)) {
            revert RewardDistributionFailed("Invalid reward payer");
        }
        if (ctHandles.length == 0) {
            revert RewardDistributionFailed("Empty ciphertext handle list");
        }
        if (ctHandles.length != rewards.length) {
            revert RewardDistributionFailed("handles and rewards length mismatch");
        }

        RewardSplitConfig memory split = $.rewardSplitConfig;

        // Consensus is reached at the transaction level: every handle of one
        // job shares the same consensus tx sender list. To save gas, only the
        // transaction's allow-permission handles are committed via
        // addCiphertextDigest — intermediate handles return an empty sender
        // list. A single non-empty sender list therefore proves the whole
        // transaction reached consensus; revert only when every handle's
        // sender list is empty.
        address[] memory txSenders;
        for (uint256 i = 0; i < ctHandles.length; i++) {
            txSenders = $.cipherDigests.getCiphertextDigestConsensusTxSenders(ctHandles[i]);
            if (txSenders.length != 0) break;
        }
        if (txSenders.length == 0) {
            revert RewardDistributionFailed("handle consensus not reached");
        }

        // Verify the txSenders are registered Alphatrion tx senders once —
        // the same list is shared by every rewarded handle below.
        for (uint256 j = 0; j < txSenders.length; j++) {
            if (!$.spacebridgeConfig.isAlphatrionTxSender(txSenders[j])) {
                revert RewardDistributionFailed("Invalid alphatrion transaction sender");
            }
        }

        uint256 alphatrionSizes = $.spacebridgeConfig.getAlphatrionTxSenders().length;
        // +1: protocolFeeRecipient is not necessarily a registered Alphatrion
        // sender. Consensus participants and the caller are all registered
        // Alphatrion senders, so they occupy at most alphatrionSizes entries.
        address[] memory participants = new address[](alphatrionSizes + 1);
        uint256[] memory accRewards = new uint256[](alphatrionSizes + 1);
        uint256 participantCount = 0;
        uint256 callerLegTotal = 0;
        uint256 protocolLegTotal = 0;
        uint256 expectedTotal = 0;

        // Verify and split each rewarded handle in a single pass. Any failure
        // reverts the whole transaction, so the handle markings below are only
        // ever committed when every rewarded handle has passed every check:
        // - the job's transaction must have reached consensus (checked above)
        // - the handle must have a recorded fee payer equal to rewardPayer
        // - a handle's fee may be distributed at most once, ever
        // - the reward is capped by the fee actually charged for that handle
        for (uint256 i = 0; i < ctHandles.length; i++) {
            if (rewards[i] == 0) continue;

            address payer = $.fheOpSettle.getFeeUserOf(ctHandles[i]);
            if (payer == address(0)) {
                revert RewardDistributionFailed("handle has no fee payer");
            }
            if (payer != rewardPayer) {
                revert RewardDistributionFailed("rewardPayer mismatch with handle payer");
            }
            if ($.distributedHandles[ctHandles[i]]) {
                revert RewardDistributionFailed("handle fee already distributed");
            }
            // Exact settlement: the reward must equal the fee actually charged
            // for the handle. A caller-chosen partial amount may not consume the
            // handle's one-shot distribution flag and strand the remainder of
            // the fee in the payer's accrued-revenue ledger forever (audit N12).
            if (rewards[i] != $.fheOpSettle.getFeePaidOf(ctHandles[i])) {
                revert RewardDistributionFailed("reward differs from fee charged for handle");
            }
            $.distributedHandles[ctHandles[i]] = true;

            // Split the handle reward into computation / caller-incentive /
            // protocol-reserve legs. The computation leg is computed by
            // subtraction so the three legs always sum exactly to rewards[i].
            uint256 protocolLeg = (rewards[i] * split.protocolReserve) / BASIS_POINTS;
            uint256 callerLeg = (rewards[i] * split.callerIncentive) / BASIS_POINTS;
            uint256 computationLeg = rewards[i] - protocolLeg - callerLeg;

            callerLegTotal += callerLeg;
            protocolLegTotal += protocolLeg;
            expectedTotal += rewards[i];

            // Division dust of the even split goes to the protocol reserve: a
            // deterministic destination that always exists, so no remainder can
            // be stranded regardless of who submits the settlement.
            uint256 share = computationLeg / txSenders.length;
            protocolLegTotal += computationLeg % txSenders.length;

            for (uint256 j = 0; j < txSenders.length; j++) {
                participantCount = _accumulateReward(participants, accRewards, participantCount, txSenders[j], share);
            }
        }
        if (expectedTotal == 0) {
            revert RewardDistributionFailed("no rewarded handles");
        }

        // The caller incentive is paid to msg.sender even when the caller did
        // not participate in any consensus sender list.
        if (callerLegTotal > 0) {
            participantCount = _accumulateReward(participants, accRewards, participantCount, msg.sender, callerLegTotal);
        }
        // The protocol reserve also receives all rounding dust.
        if (protocolLegTotal > 0) {
            participantCount =
                _accumulateReward(participants, accRewards, participantCount, $.protocolFeeRecipient, protocolLegTotal);
        }

        // Conservation invariant: the recipients receive exactly the sum of the
        // rewarded handles — no dust is omitted, nothing is overpaid.
        uint256 distributedTotal = 0;
        for (uint256 i = 0; i < participantCount;) {
            distributedTotal += accRewards[i];
            unchecked { ++i; }
        }
        if (distributedTotal != expectedTotal) {
            revert RewardDistributionFailed("reward conservation violated");
        }

        // EFFECT: Immediately mark job as distributed
        // This prevents concurrent calls from multiple Alphatrions
        // If any subsequent operation fails, the entire transaction reverts
        // and this state change is also reverted (atomicity)
        $.distributedJobs[jobId] = true;

        // Resizing arrays (avoiding memory copy)
        assembly ("memory-safe") {
            mstore(participants, participantCount)
            mstore(accRewards, participantCount)
        }

        // Update total rewards
        for (uint256 i = 0; i < participantCount;) {
            $.totalDistributedRewards[participants[i]] += accRewards[i];
            unchecked { ++i; }
        }

        // Invoke ISettlement distributeRevenue function to distribute rewards
        $.fheOpSettle.distributeRevenue(rewardPayer, rewardToken, participants, accRewards);

        // Emit ComputationRewardDistributed event
        emit ComputationRewardDistributed(jobId, participants, accRewards);
    }

    /**
     * @notice Accumulates `amount` into the reward entry for `who`, appending a
     *         new entry when `who` is not already among the participants.
     * @return The (possibly incremented) participant count.
     */
    function _accumulateReward(
        address[] memory participants,
        uint256[] memory accRewards,
        uint256 participantCount,
        address who,
        uint256 amount
    ) internal pure returns (uint256) {
        for (uint256 k = 0; k < participantCount; k++) {
            if (participants[k] == who) {
                accRewards[k] += amount;
                return participantCount;
            }
        }
        participants[participantCount] = who;
        accRewards[participantCount] = amount;
        return participantCount + 1;
    }

    /**
     * @notice See {IAlphatrionReward-isJobDistributed}.
     */
    function isJobDistributed(bytes32 jobId) external view virtual returns (bool isDistributed) {
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        return $.distributedJobs[jobId];
    }

    /**
     * @notice See {IAlphatrionReward-getTotalDistributedRewards}.
     */
    function getTotalDistributedRewards(address alphatrionAddress) external view virtual returns (uint256 amount) {
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        return $.totalDistributedRewards[alphatrionAddress];
    }

    /**
     * @notice See {IAlphatrionReward-updateRewardSplit}.
     */
    function updateRewardSplit(
        uint256 _computationShare,
        uint256 _callerIncentive,
        uint256 _protocolReserve
    ) external virtual onlySpaceBridgeOwner {
        // Validate that split ratios sum to 100%
        if (_computationShare + _callerIncentive + _protocolReserve != BASIS_POINTS) {
            revert InvalidSplitRatio("Split ratios must sum to 100%");
        }
        
        // Update configuration
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        $.rewardSplitConfig.computationShare = _computationShare;
        $.rewardSplitConfig.callerIncentive = _callerIncentive;
        $.rewardSplitConfig.protocolReserve = _protocolReserve;
        
        emit RewardSplitUpdated(_computationShare, _callerIncentive, _protocolReserve);
    }

    /**
     * @notice See {IAlphatrionReward-getVersion}.
     */
    function getVersion() external pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    CONTRACT_NAME,
                    " v",
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }

    
    
    
    
    /**
     * @notice Updates the protocol fee recipient that receives protocol reserve rewards.
     * @dev Only callable by SpaceBridge owner.
     * @param _protocolFeeRecipient The new protocol fee recipient.
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external virtual onlySpaceBridgeOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        $.protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @notice Returns the current protocol fee recipient that receives protocol reserve rewards.
     * @return The current protocol fee recipient address.
     */
    function getProtocolFeeRecipient() external view virtual returns (address) {
        AlphatrionRewardStorage storage $ = _getAlphatrionRewardStorage();
        return $.protocolFeeRecipient;
    }

    /**
     * @notice Returns the AlphatrionReward storage location.
     */
    function _getAlphatrionRewardStorage() internal pure returns (AlphatrionRewardStorage storage $) {
        assembly {
            $.slot := ALPHATRION_REWARD_STORAGE_LOCATION
        }
    }
}
