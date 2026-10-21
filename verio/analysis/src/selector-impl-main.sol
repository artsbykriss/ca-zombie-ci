// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./abstract/VerioComponent.sol";
import "./interfaces/IComponentSelector.sol";
import "./interfaces/IStakePool.sol";
import "./interfaces/IInsurancePool.sol";
import "./interfaces/IDelegator.sol";
import "./interfaces/IWithdrawalPool.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IVerioIP.sol";
import "./interfaces/Story/IIPTokenStaking.sol";

/// @title Component Selector Implementation
/// @notice Manages references to all upgradeable components in the system
/// @dev Implements IComponentSelector interface
contract ComponentSelector is IComponentSelector, VerioComponent {
    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.ComponentSelector.ComponentSelectorState")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant COMPONENT_SELECTOR_STATE =
        0x256044682fb9f4ed80e42d2ac3be5e3cfa2159166d98684a5a52f76068ea3100;

    /// @dev Storage slot for component selector state
    function _componentSelectorState() internal pure returns (ComponentSelectorState storage $) {
        assembly {
            $.slot := COMPONENT_SELECTOR_STATE
        }
    }

    // --- MODIFIERS ---

    /// @notice Restricts function access to Verio components only
    /// @dev Throws if called with an invalid component address
    modifier onlyVerioComponent(address _component) {
        require(_componentSelectorState().isComponent[_component], AddressNotVerioComponent());
        _;
    }

    // --- INITIALIZATION ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the component selector contract
    /// @dev This function replaces the constructor for upgradeable contracts
    /// @param _config Initial configuration for the component selector
    function initialize(ComponentSelectorConfig calldata _config) external initializer {
        _init(msg.sender);
        _trySetComponentSelectorState(_config);
    }

    function _trySetComponentSelectorState(ComponentSelectorConfig calldata _config) internal {
        require(_isValidAddress(_config.treasury), InvalidComponentAddress());
        require(_isValidAddress(_config.stakePool), InvalidComponentAddress());
        require(_isValidAddress(_config.ipTokenStaking), InvalidComponentAddress());
        require(_isValidAddress(_config.delegator), InvalidComponentAddress());
        require(_isValidAddress(_config.withdrawalPool), InvalidComponentAddress());
        require(_isValidAddress(_config.rewardPool), InvalidComponentAddress());
        require(_isValidAddress(_config.verioIP), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        componentSelectorState.treasury = _config.treasury;
        componentSelectorState.stakePool = IStakePool(_config.stakePool);
        componentSelectorState.ipTokenStaking = IIPTokenStaking(_config.ipTokenStaking);
        componentSelectorState.delegator = IDelegator(_config.delegator);
        componentSelectorState.withdrawalPool = IWithdrawalPool(_config.withdrawalPool);
        componentSelectorState.rewardPool = IRewardPool(_config.rewardPool);
        componentSelectorState.verioIP = IVerioIP(_config.verioIP);
        componentSelectorState.isComponent[_config.stakePool] = true;
        componentSelectorState.isComponent[_config.delegator] = true;
        componentSelectorState.isComponent[_config.withdrawalPool] = true;
        componentSelectorState.isComponent[_config.rewardPool] = true;
        componentSelectorState.isComponent[_config.verioIP] = true;
    }

    function _isValidAddress(address _componentAddress) internal pure returns (bool) {
        return _componentAddress != address(0);
    }

    // --- GETTERS ---

    /// @inheritdoc IComponentSelector
    function stakePool() external view override returns (IStakePool) {
        return _componentSelectorState().stakePool;
    }

    /// @inheritdoc IComponentSelector
    function ipTokenStaking() external view override returns (IIPTokenStaking) {
        return _componentSelectorState().ipTokenStaking;
    }

    /// @inheritdoc IComponentSelector
    function insurancePoolByComponent(address _componentAddress) external view override returns (IInsurancePool) {
        return _componentSelectorState().insurancePoolByComponent[_componentAddress];
    }

    /// @inheritdoc IComponentSelector
    function delegator() external view override returns (IDelegator) {
        return _componentSelectorState().delegator;
    }

    /// @inheritdoc IComponentSelector
    function withdrawalPool() external view override returns (IWithdrawalPool) {
        return _componentSelectorState().withdrawalPool;
    }

    /// @inheritdoc IComponentSelector
    function rewardPool() external view override returns (IRewardPool) {
        return _componentSelectorState().rewardPool;
    }

    /// @inheritdoc IComponentSelector
    function verioIP() external view override returns (IVerioIP) {
        return _componentSelectorState().verioIP;
    }

    function treasury() external view override returns (address) {
        return _componentSelectorState().treasury;
    }

    // --- SETTERS ---

    /// @inheritdoc IComponentSelector
    function setStakePool(address _stakePool) external override onlyAdmin {
        require(_isValidAddress(_stakePool), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IStakePool oldStakePool = componentSelectorState.stakePool;
        string memory oldVersion = address(oldStakePool) != address(0) ? oldStakePool.getVersion() : "0.0.0";
        componentSelectorState.stakePool = IStakePool(_stakePool);
        componentSelectorState.isComponent[address(oldStakePool)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.stakePool)] = true;
        emit ComponentUpdated(
            "StakePool",
            address(oldStakePool),
            oldVersion,
            address(componentSelectorState.stakePool),
            componentSelectorState.stakePool.getVersion()
        );
    }

    /// @inheritdoc IComponentSelector
    /// @dev Story does not version the IPTokenStaking contract yet
    function setIPTokenStaking(address _ipTokenStaking) external override onlyAdmin {
        require(_isValidAddress(_ipTokenStaking), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IIPTokenStaking oldIPTokenStaking = componentSelectorState.ipTokenStaking;
        componentSelectorState.ipTokenStaking = IIPTokenStaking(_ipTokenStaking);
        componentSelectorState.isComponent[address(oldIPTokenStaking)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.ipTokenStaking)] = true;
        emit ComponentUpdated(
            "IPTokenStaking",
            address(oldIPTokenStaking),
            "0.0.0",
            address(componentSelectorState.ipTokenStaking),
            "0.0.0"
        );
    }

    /// @inheritdoc IComponentSelector
    function setInsurancePoolByComponent(
        address _componentAddress,
        IInsurancePool _insurancePool,
        bool _componentIsClaimant
    ) external override onlyAdmin {
        require(
            _isValidAddress(_componentAddress) && _isValidAddress(address(_insurancePool)), InvalidComponentAddress()
        );
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        componentSelectorState.insurancePoolByComponent[_componentAddress] = _insurancePool;
        if (_componentIsClaimant) {
            _insurancePool.setClaimant(_componentAddress);
        }
        componentSelectorState.isComponent[address(_insurancePool)] = true;
        emit ComponentInsurancePoolUpdated(_componentAddress, address(_insurancePool));
    }

    /// @inheritdoc IComponentSelector
    function setDelegator(address _delegator) external override onlyAdmin {
        require(_isValidAddress(_delegator), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IDelegator oldDelegator = componentSelectorState.delegator;
        string memory oldVersion = address(oldDelegator) != address(0) ? oldDelegator.getVersion() : "0.0.0";
        componentSelectorState.delegator = IDelegator(_delegator);
        componentSelectorState.isComponent[address(oldDelegator)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.delegator)] = true;
        emit ComponentUpdated(
            "Delegator",
            address(oldDelegator),
            oldVersion,
            address(componentSelectorState.delegator),
            componentSelectorState.delegator.getVersion()
        );
    }

    /// @inheritdoc IComponentSelector
    function setWithdrawalPool(address _withdrawalPool) external override onlyAdmin {
        require(_isValidAddress(_withdrawalPool), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IWithdrawalPool oldWithdrawalPool = componentSelectorState.withdrawalPool;
        string memory oldVersion = address(oldWithdrawalPool) != address(0) ? oldWithdrawalPool.getVersion() : "0.0.0";
        componentSelectorState.withdrawalPool = IWithdrawalPool(_withdrawalPool);
        componentSelectorState.isComponent[address(oldWithdrawalPool)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.withdrawalPool)] = true;
        emit ComponentUpdated(
            "WithdrawalPool",
            address(oldWithdrawalPool),
            oldVersion,
            address(componentSelectorState.withdrawalPool),
            componentSelectorState.withdrawalPool.getVersion()
        );
    }

    /// @inheritdoc IComponentSelector
    function setRewardPool(address _rewardPool) external override onlyAdmin {
        require(_isValidAddress(_rewardPool), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IRewardPool oldRewardPool = componentSelectorState.rewardPool;
        string memory oldVersion = address(oldRewardPool) != address(0) ? oldRewardPool.getVersion() : "0.0.0";
        componentSelectorState.rewardPool = IRewardPool(_rewardPool);
        componentSelectorState.isComponent[address(oldRewardPool)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.rewardPool)] = true;
        emit ComponentUpdated(
            "RewardPool",
            address(oldRewardPool),
            oldVersion,
            address(componentSelectorState.rewardPool),
            componentSelectorState.rewardPool.getVersion()
        );
    }

    /// @inheritdoc IComponentSelector
    function setVerioIP(address _verioIP) external override onlyAdmin {
        require(_isValidAddress(_verioIP), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        IVerioIP oldVerioIP = componentSelectorState.verioIP;
        string memory oldVersion = address(oldVerioIP) != address(0) ? oldVerioIP.getVersion() : "0.0.0";
        componentSelectorState.verioIP = IVerioIP(_verioIP);
        componentSelectorState.isComponent[address(oldVerioIP)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.verioIP)] = true;
        emit ComponentUpdated(
            "VerioIP",
            address(oldVerioIP),
            oldVersion,
            address(componentSelectorState.verioIP),
            componentSelectorState.verioIP.getVersion()
        );
    }

    /// @inheritdoc IComponentSelector
    /// @dev We do not version the treasury
    function setTreasury(address _treasury) external override onlyAdmin {
        require(_isValidAddress(_treasury), InvalidComponentAddress());
        ComponentSelectorState storage componentSelectorState = _componentSelectorState();
        address oldTreasury = componentSelectorState.treasury;
        componentSelectorState.treasury = _treasury;
        componentSelectorState.isComponent[address(oldTreasury)] = false;
        componentSelectorState.isComponent[address(componentSelectorState.treasury)] = true;
        emit ComponentUpdated(
            "Treasury", address(oldTreasury), "0.0.0", address(componentSelectorState.treasury), "0.0.0"
        );
    }

    // --- VERSIONABLE ---

    /// @inheritdoc IComponentSelector
    function getComponentVersion(address _component)
        external
        view
        override
        onlyVerioComponent(_component)
        returns (string memory version)
    {
        return IVersionable(_component).getVersion();
    }

    // --- RECEIVER ---

    receive() external payable {
        revert("ComponentSelector: no funds accepted");
    }
}
