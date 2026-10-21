// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./Versionable.sol";
import "./AdminControlled.sol";
import "../interfaces/IVerioComponent.sol";

import "../../library/SemanticVersion.sol";

abstract contract VerioComponent is
    IVerioComponent,
    Versionable,
    AdminControlled,
    Initializable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SemanticVersion for string;
    using SemanticVersion for SemanticVersion.V;

    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.VerioComponent.ComponentState")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant COMPONENT_STATE = 0x032cfaf9e34dcc56cd95b1e9fb8947a9d8fc8b2b7e48e6bd023f13ba3e52d700;

    function _componentState() internal pure returns (ComponentState storage $) {
        assembly {
            $.slot := COMPONENT_STATE
        }
    }

    // --- MODIFIERS ---

    modifier onlyDelegator() {
        address delegator = address(_selector().delegator());
        require(msg.sender == delegator, OnlyDelegator(delegator));
        _;
    }

    modifier onlyStakePool() {
        address stakePool = address(_selector().stakePool());
        require(msg.sender == stakePool, OnlyStakePool(stakePool));
        _;
    }

    modifier onlySelector() {
        address selector = address(_selector());
        require(msg.sender == selector, OnlySelector(selector));
        _;
    }

    // --- INITIALIZATION ---

    function _init(address sender) internal {
        __Ownable2Step_init();
        _transferOwnership(sender);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // --- GETTERS ---

    function _selector() internal view returns (IComponentSelector) {
        return _componentState().selector;
    }

    /// @inheritdoc IVerioComponent
    function getSelector() external view returns (IComponentSelector) {
        return _selector();
    }

    // --- SETTERS ---

    /// @inheritdoc IVerioComponent
    function setSelector(IComponentSelector _componentSelector) external onlyAdmin {
        _componentState().selector = _componentSelector;
        emit SelectorUpdated(address(_componentSelector));
    }

    // --- VERSIONABLE ---

    /// @inheritdoc IVersionable
    function setVersion(string calldata _nextVersion) external onlyAdmin {
        IVersionable.Version storage version = _version();
        SemanticVersion.V memory next = _nextVersion.parse();
        require(version.v.validateNextVersion(next), InvalidVersion());
        version.v = next;
        version.t = block.timestamp;
        emit VersionUpdated(_nextVersion);
    }

    // --- PAUSABLE ---

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    // --- ADMIN CONTROLLED ---

    /// @inheritdoc IAdminControlled
    function setAdmin(address _admin) external onlyOwner {
        _adminState().admin = _admin;
        emit AdminUpdated(_admin);
    }
}
