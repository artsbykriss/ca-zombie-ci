// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ISettings } from "../interfaces/ISettings.sol";
import { EpochInfo } from "./Structs.sol";
import { IConsensus } from "../interfaces/IConsensus.sol";

import { SettingsConstants } from "../libs/SettingsConstants.sol";
import { TacInitializable } from "./TacInitializable.sol";

contract Consensus is TacInitializable, UUPSUpgradeable, AccessControlUpgradeable, IConsensus {

    // === ERRORS ===
    error OnlyVoter(address voter);
    error OnlyGroupAdmin(address admin);
    error ZeroAddress();
    error InvalidGroupId();
    error GroupAlreadyAdded(bytes32 groupId);
    error GroupDoesntExist(bytes32 groupId);
    error GroupIsNotEmpty(bytes32 groupId);
    error VoterAlreadyAdded(bytes32 groupId, address voter);
    error VoterAlreadyRemoved(address voter);
    error VotingIsNotActive();
    error VoterAlreadyVoted(address voter);

    // === EVENTS ===
    event ConsensusReached(uint64 currEpochStartTime, bytes32 merkleRoot);
    event ConsensusEpochStarted(EpochInfo epochInfo);
    event GroupAdded(bytes32 groupId);
    event VoterAdded(bytes32 groupId, address voterAddress);
    event VoterRemoved(address voterAddress);
    event DKGSessionStart(int64 startTimestamp);

    // === CONSTANTS ===

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant EPOCH_MANAGER = keccak256("EPOCH_MANAGER");

    // === STATE VARIABLES ===

    /**
     * @dev contract with protocol settings
     */
    ISettings internal _settings;

    // groups info
    struct GroupInfo {
        bytes32 groupId;
        address admin;
    }
    GroupInfo[] groupsToAdd;
    /**
     * @dev map with group's admin addresses
     */
    mapping(bytes32 groupId => address admin) public groupsAdmins;
    /**
     * @dev array, contains each group id
     */
    bytes32[] groupIds;

    // Voter info
    struct VoterInfo{
        bytes32 groupId;
        address voterAddress;
    }
    VoterInfo[] votersToAdd;
    address[] votersToRemove;
    /**
     * @dev mapping of voter's group id
     */
    mapping(address voter => bytes32 groupId) public voterToGroupId;
    /**
     * @dev mapping of total number of voters on each group
     */
    mapping(bytes32 groupId => uint256 num) public inGroupVotersNum;

    /**
     * @dev EVM consensus votes number for each group
     * @dev value = abi.encodePacked(evmEpochNum,evmMerkleRoot);
    */
    mapping(bytes value => mapping (bytes32 groupId => uint256 num)) public consensusVotesNumber;

    /**
     * @dev EVM and TVM consensus voters wich has already voted for specified value
    */
    mapping(bytes value => mapping (address => bool)) public hasVoted;

    // mapping of all approved merkle roots
    mapping(bytes32 root => uint256 validUntil) public _roots;

    // current merkle root
    bytes32 _currentRoot;

    // epoch
    uint64 private _prevMessageCollectEndTime;
    uint64 private _messageCollectEndTime;
    uint64 private _prevEpochStartTime;
    uint64 private _currEpochStartTime;
    uint64 private _nextVotingTime;

    // === END OF STATE VARIABLES ===

    /**
     * @dev Initializer function to initialize the contract with initial state.
     * @param adminAddress Admin address.
     * @param settingsAddress Settings contract address.
     */
    function initialize(address adminAddress, address settingsAddress) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _settings = ISettings(settingsAddress);

        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(EPOCH_MANAGER, ADMIN);
        _grantRole(ADMIN, adminAddress);
        _grantRole(EPOCH_MANAGER, adminAddress);

        _startEpoch();
    }

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN) {}

    /**
     * @dev Modifier to restrict access to vote
     */
    modifier onlyVoter() {
        if (voterToGroupId[msg.sender] == bytes32(0)) revert OnlyVoter(msg.sender);
        _;
    }

    /**
     * @dev Modifier to restrict access to group admins
     */
    modifier onlyGroupAdmin(bytes32 groupId) {
        if (groupsAdmins[groupId] != msg.sender) revert OnlyGroupAdmin(msg.sender);
        _;
    }

    //================================================================
    // INTERNAL FUNCTIONS
    //================================================================

    function _addGroup(bytes32 groupId, address adminAddress) internal {
        if (groupsAdmins[groupId] != address(0)) return;
        groupsAdmins[groupId] = adminAddress;
        groupIds.push(groupId);
    }


    function _addVoter(bytes32 groupId, address voterAddress) internal {
        if (voterToGroupId[voterAddress] != bytes32(0)) return;
        voterToGroupId[voterAddress] = groupId;
        inGroupVotersNum[groupId]++;
    }

    function _removeVoter(address voterAddress) internal {
        if (voterToGroupId[voterAddress] == bytes32(0)) return;

        bytes32 groupId = voterToGroupId[voterAddress];
        voterToGroupId[voterAddress] = bytes32(0);
        inGroupVotersNum[groupId]--;
    }

    function _checkInGroupConsensus(bytes memory value, bytes32 groupId) internal view returns (bool) {
        if (inGroupVotersNum[groupId] == 0) return false;

        uint requiredQuorum = _settings.getUintSetting(SettingsConstants.CONSENSUS_THRESHOLD_IN_GROUP_KEY) * inGroupVotersNum[groupId];
        if (consensusVotesNumber[value][groupId] * SettingsConstants.RATE_DECIMALS >= requiredQuorum) {
            return true;
        }
        else {
            return false;
        }
    }

    function _checkConsensus(bytes memory value) internal view returns (bool) {
        uint inGroupConsensusReached;
        uint requiredQuorum = _settings.getUintSetting(SettingsConstants.CONSENSUS_THRESHOLD_GROUPS_KEY) * groupIds.length;

        for (uint i; i < groupIds.length;) {
            // check consensus inside group
            inGroupConsensusReached += _checkInGroupConsensus(value, groupIds[i]) ? 1 : 0;
            if (inGroupConsensusReached * SettingsConstants.RATE_DECIMALS >= requiredQuorum) {
                return true;
            }
            unchecked { i++; }
        }
        return false;
    }

    /**
     * @dev Starts a new epoch if needed, performs delayed adding and removing groups and voters.
     */
    function _startEpoch() internal {

        uint i;

        for (; i < groupsToAdd.length;) {
            _addGroup(groupsToAdd[i].groupId, groupsToAdd[i].admin);
            unchecked { i++; }
        }
        delete groupsToAdd;
        delete i;

        for (; i < votersToAdd.length;) {
            _addVoter(votersToAdd[i].groupId, votersToAdd[i].voterAddress);
            unchecked{ i++; }
        }
        delete votersToAdd;
        delete i;

        for (; i < votersToRemove.length;) {
            _removeVoter(votersToRemove[i]);
            unchecked { i++; }
        }
        delete votersToRemove;
        delete i;

        _prevEpochStartTime = _currEpochStartTime;
        _currEpochStartTime = uint64(block.timestamp);

        uint64 epochDelay = _settings.getUintSetting(SettingsConstants.EPOCH_DELAY_KEY);
        _nextVotingTime = _currEpochStartTime + epochDelay;

        emit ConsensusEpochStarted(getCurrentEpochInfo());
    }

    //================================================================
    // ADMIN FUNCTIONS
    //================================================================

    /**
     * @dev Add new voter's group
     * @param groupId group id
     * @param adminAddress group admin address
     */
    function addGroup(bytes32 groupId, address adminAddress) external onlyRole(ADMIN) {
        if (groupId == bytes32(0)) revert InvalidGroupId();
        if (adminAddress == address(0)) revert ZeroAddress();
        if (groupsAdmins[groupId] != address(0)) revert GroupAlreadyAdded(groupId);

        for (uint i; i < groupsToAdd.length;) {
            if (groupsToAdd[i].groupId == groupId) revert GroupAlreadyAdded(groupId);
            unchecked { i++; }
        }

        groupsToAdd.push(GroupInfo(groupId, adminAddress));
    }

    /**
     * @dev removing of existing group
     * remove only if group is empty (no voters in group)
     * @param groupId group id to remove
     */
    function removeGroup(bytes32 groupId) external onlyRole(ADMIN) {
        if (groupId == bytes32(0)) revert InvalidGroupId();
        if (groupsAdmins[groupId] == address(0)) revert GroupDoesntExist(groupId);
        if (inGroupVotersNum[groupId] != 0) revert GroupIsNotEmpty(groupId);

        groupsAdmins[groupId] = address(0);

        bytes32[] memory newGroups = new bytes32[](groupIds.length);
        uint n;
        uint i;
        while (i < groupIds.length) {
            if (groupIds[i] != groupId) {
                newGroups[n++] = groupIds[i];
            }
            unchecked { i++; }
        }
        assembly {
            mstore(newGroups, n)
        }
        groupIds = newGroups;
    }

    function forceEpoch() external onlyRole(EPOCH_MANAGER) {
        if (_currEpochStartTime + _settings.getUintSetting(SettingsConstants.MAX_EPOCH_DURATION_KEY) <= block.timestamp) {
            _startEpoch();
        }
    }

    function startDKGSession(int64 startTimestamp) external onlyRole(ADMIN) {
        emit DKGSessionStart(startTimestamp);
    }

    //================================================================
    // GROUP ADMIN FUNCTIONS
    //================================================================

    /**
     * Set new group admin address
     * @param groupId group id
     * @param newAdminAddress new admin address
     */
    function setGroupAdmin(bytes32 groupId, address newAdminAddress) external onlyGroupAdmin(groupId) {
        if (newAdminAddress == address(0)) revert ZeroAddress();
        groupsAdmins[groupId] = newAdminAddress;
    }

    /**
     * @dev Adds a new voter.
     * @param groupId voter group id
     * @param voterAddress voter evm address
     */
    function addVoter(bytes32 groupId, address voterAddress) external onlyGroupAdmin(groupId) {
        if (voterAddress == address(0)) revert ZeroAddress();
        if (voterToGroupId[voterAddress] != bytes32(0)) revert VoterAlreadyAdded(voterToGroupId[voterAddress], voterAddress);

        for (uint i; i < votersToAdd.length;) {
            if (votersToAdd[i].voterAddress == voterAddress) revert VoterAlreadyAdded(votersToAdd[i].groupId, voterAddress);
            unchecked { i++; }
        }

        votersToAdd.push(VoterInfo(groupId, voterAddress));

        emit VoterAdded(groupId, voterAddress);
    }

    /**
     * @dev Remove voter.
     * @param voterAddress Address of the voter to remove.
     */
    function removeVoter(address voterAddress) external onlyGroupAdmin(voterToGroupId[voterAddress]) {
        for (uint i; i < votersToRemove.length;) {
            if (votersToRemove[i] == voterAddress) revert VoterAlreadyRemoved(voterAddress);
            unchecked { i++; }
        }

        votersToRemove.push(voterAddress);

        emit VoterRemoved(voterAddress);
    }

    //================================================================
    // VOTER FUNCTIONS
    //================================================================

    /**
     * @dev Vote for a new root value.
     * @param messageCollectEndTime Message collect end time for current vote.
     * @param newRoot New root to vote for.
     */
    function vote(uint64 messageCollectEndTime, bytes32 newRoot) external onlyVoter {
        // inconsistent message collect time
        if (messageCollectEndTime < _nextVotingTime) return;

        // execution delay in progress
        if (block.timestamp < _nextVotingTime) revert VotingIsNotActive();

        bytes memory value = abi.encodePacked(messageCollectEndTime, newRoot);
        address voter = msg.sender;

        // voter already voted for this root
        if (hasVoted[value][voter]) revert VoterAlreadyVoted(voter);

        // in group consensus reached
        if (_checkInGroupConsensus(value, voterToGroupId[voter])) return;

        consensusVotesNumber[value][voterToGroupId[voter]]++;
        hasVoted[value][voter] = true;

        if (_checkConsensus(value)) {
            _currentRoot = newRoot;
            _prevMessageCollectEndTime = _messageCollectEndTime;
            _messageCollectEndTime = messageCollectEndTime;
            _roots[newRoot] = block.timestamp + _settings.getUintSetting(SettingsConstants.VALIDITY_DURATION_KEY);
            emit ConsensusReached(_currEpochStartTime, newRoot);
            _startEpoch();
        }
    }

    // ================================================================
    // VIEW FUNCTIONS
    // ================================================================

    /**
     * @dev Returns current epoch info.
     * @return Epoch info.
     */
    function getCurrentEpochInfo() public view returns (EpochInfo memory) {
        return EpochInfo({
            merkleRoot: _currentRoot,
            prevMessageCollectEndTime: _prevMessageCollectEndTime,
            messageCollectEndTime: _messageCollectEndTime,
            prevEpochStartTime: _prevEpochStartTime,
            currEpochStartTime: _currEpochStartTime,
            nextVotingTime: _nextVotingTime
        });
    }

    /**
     * @dev Gets total number of active gropus.
     * @return uint Total number of active groups.
     */
    function totalGroups() public view returns (uint) {
        return groupIds.length;
    }

    function getGroups() public view returns (bytes32[] memory) {
        return groupIds;
    }

    /**
     * @dev Gets total number of active voters.
     * @return num Total number of active voters.
     */
    function totalVoters() public view returns (uint256 num) {
        for(uint i; i < groupIds.length;){
            num += inGroupVotersNum[groupIds[i]];
            unchecked { i++; }
        }
    }

    function getValue() public view returns (bytes32) {
        return _currentRoot;
    }

    function checkMerkleRoot(bytes32 merkleRoot) public view returns (bool) {
        return _roots[merkleRoot] > block.timestamp;
    }
}