// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Auth, Authority } from "solmate/auth/Auth.sol";

contract VaultToken is ERC20, Auth {
    address public minter;
    address public burner;
    uint8 public baseAssetDecimals;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _baseAsset
    )
        ERC20(_name, _symbol)
        Auth(_owner, Authority(address(0)))
    {
        baseAssetDecimals = IERC20Metadata(_baseAsset).decimals();
    }

    /**
     * @notice Mints tokens to an address
     * @dev Only callable by addresses with MINTER_ROLE
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external requiresAuth {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns tokens from an address
     * @dev Only callable by addresses with BURNER_ROLE
     * @param _from The address to burn tokens from
     * @param _amount The amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external requiresAuth {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return baseAssetDecimals;
    }
}
