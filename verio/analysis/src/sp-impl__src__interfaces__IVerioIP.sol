// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IVersionable.sol";

/// @title VerioIP Token Interface
/// @notice Interface for the VerioIP token contract which handles IP token operations
/// @dev This interface defines the core functionality for minting, burning, and managing VerioIP tokens
interface IVerioIP is IVersionable {
    /// @notice Emitted when tokens are minted
    event Minted(address indexed to, uint256 amount);

    /// @notice Emitted when tokens are burned
    event Burned(address indexed from, uint256 amount);

    /// @notice Error when amount is zero
    error CannotMintZeroAmount();

    /// @notice Error when amount is zero
    error CannotBurnZeroAmount();

    /// @notice Error when caller is not authorized
    /// @param stakePool The authorized stake pool address
    /// @param holder The token holder address
    error OnlyStakePoolOrHolder(address stakePool, address holder);

    /// @notice Error when funds are sent to the contract
    error CannotReceiveFunds();

    /// @notice Mints new VerioIP tokens
    /// @dev Only callable by the stake pool contract
    /// @param _to Address to receive the minted tokens
    /// @param _amount Amount of tokens to mint
    function mint(address _to, uint256 _amount) external;

    /// @notice Burns VerioIP tokens
    /// @dev Can be called by stake pool or token holder
    /// @param _from Address from which to burn tokens
    /// @param _amount Amount of tokens to burn
    function burn(address _from, uint256 _amount) external;

    /// @notice Returns the name of the token
    /// @return The full name of the token
    function getName() external view returns (string memory);

    /// @notice Returns the symbol of the token
    /// @return The token symbol
    function getSymbol() external view returns (string memory);

    /// @notice Returns the total supply of the token
    /// @return The current total supply
    function getTotalSupply() external view returns (uint256);
}
