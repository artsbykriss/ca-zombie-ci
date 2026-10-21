// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Fun
 * @dev An ERC20 token contract using OpenZeppelin UUPSUpgradeable module
 */
contract Fun is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    // Constants
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    
    // Roles
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Prevents initialization of the implementation contract
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param owner The address that will receive the initial supply and become the owner
     */
    function initialize(
        string memory name,
        string memory symbol,
        address owner
    ) public initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _setRoleAdmin(GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        
        _mint(owner, MAX_SUPPLY);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(GOVERNOR_ROLE, owner);
    }

    /**
     * @notice Required by the UUPSUpgradeable module
     * @dev Only allows governors to upgrade the implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(GOVERNOR_ROLE) {}
}
