// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IStakePool.sol";
import "./IInsurancePool.sol";
import "./IDelegator.sol";
import "./IWithdrawalPool.sol";
import "./IRewardPool.sol";
import "./IVerioIP.sol";
import "./IVerioComponent.sol";
import "./IVersionable.sol";
import "./Story/IIPTokenStaking.sol";

/// @title Component Selector Interface
/// @notice Manages references to all upgradeable components in the system
/// @dev Provides centralized version management and component addressing
interface IComponentSelector is IVersionable {
    /// @notice State for the component selector contract
    /// @param admin Address of the admin
    /// @param ipTokenStaking IP token staking contract
    /// @param delegator Delegator contract
    /// @param stakePool Stake pool contract
    /// @param withdrawalPool Withdrawal pool contract
    /// @param rewardPool Reward pool contract
    /// @param verioIP VerioIP token contract
    /// @param isComponent Mapping of valid component addresses
    /// @param insurancePoolByComponent Mapping of components to their corresponding insurance pool addresses
    /// @custom:storage-location erc7201:VerioIP.ComponentSelector.ComponentSelectorState
    struct ComponentSelectorState {
        address treasury;
        IIPTokenStaking ipTokenStaking;
        IVerioIP verioIP;
        IDelegator delegator;
        IStakePool stakePool;
        IWithdrawalPool withdrawalPool;
        IRewardPool rewardPool;
        mapping(address => bool) isComponent;
        mapping(address => IInsurancePool) insurancePoolByComponent;
    }

    /// @notice Configuration for all component addresses
    /// @param admin Address of the admin
    /// @param treasury Address of the treasury
    /// @param stakePool Address of the stake pool contract
    /// @param ipTokenStaking Address of the IP token staking contract
    /// @param delegator Address of the delegator contract
    /// @param withdrawalPool Address of the withdrawal pool contract
    /// @param rewardPool Address of the reward pool contract
    /// @param verioIP Address of the VerioIP token contract
    /// @dev Associating insurance pools to components is done via the `setInsurancePoolByComponent` function
    struct ComponentSelectorConfig {
        address treasury;
        address stakePool;
        address ipTokenStaking;
        address delegator;
        address withdrawalPool;
        address rewardPool;
        address verioIP;
    }

    /// @notice Emitted when a component address is updated
    /// @param componentName Name of the updated component
    /// @param oldAddress Previous address of the component
    /// @param oldVersion Version of the component before the update
    /// @param newAddress New address of the component
    /// @param newVersion Version of the component after the update
    event ComponentUpdated(
        string componentName, address oldAddress, string oldVersion, address newAddress, string newVersion
    );

    /// @notice Emitted when an insurance pool address is updated for a component
    /// @param componentAddress Address of the component
    /// @param insurancePoolAddress New address of the insurance pool
    event ComponentInsurancePoolUpdated(address componentAddress, address insurancePoolAddress);

    /// @notice Gets the current stake pool implementation
    /// @return Address of the current stake pool contract
    function stakePool() external view returns (IStakePool);

    /// @notice Gets the current IP token staking implementation
    /// @return Address of the current IP token staking contract
    function ipTokenStaking() external view returns (IIPTokenStaking);

    /// @notice Gets the current insurance pool implementation
    /// @return Address of the current insurance pool contract
    function insurancePoolByComponent(address _componentAddress) external view returns (IInsurancePool);

    /// @notice Gets the current delegator implementation
    /// @return Address of the current delegator contract
    function delegator() external view returns (IDelegator);

    /// @notice Gets the current withdrawal pool implementation
    /// @return Address of the current withdrawal pool contract
    function withdrawalPool() external view returns (IWithdrawalPool);

    /// @notice Gets the current reward pool implementation
    /// @return Address of the current reward pool contract
    function rewardPool() external view returns (IRewardPool);

    /// @notice Gets the current VerioIP token implementation
    /// @return Address of the current VerioIP token contract
    function verioIP() external view returns (IVerioIP);

    /// @notice Updates the stake pool implementation
    /// @param _stakePool New stake pool address
    function setStakePool(address _stakePool) external;

    /// @notice Updates the IP token staking implementation
    /// @param _ipTokenStaking New IP token staking address
    function setIPTokenStaking(address _ipTokenStaking) external;

    /// @notice Gets the treasury address
    /// @return Address of the treasury
    function treasury() external view returns (address);

    /// @notice Updates the insurance pool implementation for a component
    /// @param _componentAddress Address of the component
    /// @param _insurancePool New insurance pool
    /// @param _componentIsClaimant Whether the component is the claimant for the insurance pool
    function setInsurancePoolByComponent(
        address _componentAddress,
        IInsurancePool _insurancePool,
        bool _componentIsClaimant
    ) external;

    /// @notice Updates the delegator implementation
    /// @param _delegator New delegator address
    function setDelegator(address _delegator) external;

    /// @notice Updates the withdrawal pool implementation
    /// @param _withdrawalPool New withdrawal pool address
    function setWithdrawalPool(address _withdrawalPool) external;

    /// @notice Updates the reward pool implementation
    /// @param _rewardPool New reward pool address
    function setRewardPool(address _rewardPool) external;

    /// @notice Updates the VerioIP token implementation
    /// @param _verioIP New VerioIP token address
    function setVerioIP(address _verioIP) external;

    /// @notice Updates the treasury address
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    /// @notice Gets the semantic version of a component
    /// @param _component Address of the component
    /// @return version SemanticVersion of the component
    function getComponentVersion(address _component) external view returns (string memory);

    // --- CUSTOM ERRORS ---
    /// @notice Error when component address is invalid
    error InvalidComponentAddress();

    /// @notice Error when address is not a Verio component
    error AddressNotVerioComponent();

    /// @notice Error when funds are sent to the contract
    error NoFundsAccepted();
}
