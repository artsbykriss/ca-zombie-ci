// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ICurvePool
/// @notice Interface for Curve Finance stablecoin pools
/// @dev Minimal interface for 3pool interactions
interface ICurvePool {
    /// @notice Deposit coins into the pool
    /// @param amounts Array of amounts to deposit (one per coin)
    /// @param min_mint_amount Minimum amount of LP tokens to mint
    /// @dev Returns NOTHING. 3pool is Vyper 0.1.x and its `add_liquidity` has an
    ///      empty output list (verified against the deployed ABI at
    ///      0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7). This was previously
    ///      declared `returns (uint256)`, which made every call revert in the
    ///      ABI decoder on empty returndata — silently, since only fork tests
    ///      reach the real pool. Read the LP balance delta instead.
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    /// @notice Withdraw coins from the pool
    /// @param _amount Amount of LP tokens to burn
    /// @param min_amounts Minimum amounts of each coin to receive
    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    /// @notice Withdraw a single coin from the pool
    /// @param _token_amount Amount of LP tokens to burn
    /// @param i Index of coin to receive
    /// @param min_amount Minimum amount of coin to receive
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount)
        external;

    /// @notice Get the balance of a specific coin in the pool
    /// @param i Index of the coin
    /// @return Balance of the coin
    function balances(uint256 i) external view returns (uint256);

    /// @notice Get the address of a specific coin
    /// @param i Index of the coin
    /// @return Address of the coin
    function coins(uint256 i) external view returns (address);

    /// @notice Calculate the amount of LP tokens received for a deposit
    /// @param amounts Array of amounts to deposit
    /// @param deposit True for deposit, false for withdrawal
    /// @return Amount of LP tokens
    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    /// @notice Get the virtual price of the LP token
    /// @return Virtual price scaled by 1e18
    function get_virtual_price() external view returns (uint256);
}
