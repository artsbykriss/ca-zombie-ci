// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IMeridianUSD {
    /// @notice Emitted when an underlying wrapped USD asset is enabled or disabled.
    /// @param token Underlying wrapped USD asset address
    /// @param oldEnabled Previous enabled status
    /// @param newEnabled Updated enabled status
    event WrappedTokenUpdated(address indexed token, bool oldEnabled, bool newEnabled);

    /// @notice Emitted when the default wrapped USD asset is updated.
    /// @param oldToken Previous default underlying wrapped USD asset address
    /// @param newToken Updated default underlying wrapped USD asset address
    event DefaultWrappedTokenUpdated(address indexed oldToken, address indexed newToken);

    /// @notice Emitted when an account wraps an underlying USD asset into MeridianUSD.
    /// @param account Account that receives MeridianUSD
    /// @param token Underlying wrapped USD asset deposited
    /// @param amount Amount wrapped
    event Wrapped(address indexed account, address indexed token, uint256 amount);

    /// @notice Emitted when an account unwraps MeridianUSD into an underlying USD asset.
    /// @param account Account that burns MeridianUSD
    /// @param token Underlying wrapped USD asset withdrawn
    /// @param amount Amount unwrapped
    event Unwrapped(address indexed account, address indexed token, uint256 amount);

    /// @notice Returns whether `token` is approved as an underlying wrapped USD asset.
    /// @param token Underlying wrapped USD asset address
    function isWrappedToken(address token) external view returns (bool);

    /// @notice Returns the default wrapped USD asset used by default deposit and withdrawal flows.
    function defaultWrappedToken() external view returns (address);

    /// @notice Enables or disables an underlying wrapped USD asset.
    /// @param token Underlying wrapped USD asset address
    /// @param enabled Whether the token should be enabled
    function setWrappedToken(address token, bool enabled) external;

    /// @notice Updates the default wrapped USD asset.
    /// @param token Enabled wrapped USD asset to use by default
    function setDefaultWrappedToken(address token) external;

    /// @notice Wraps an approved underlying USD asset into MeridianUSD.
    /// @param token Underlying wrapped USD asset to deposit
    /// @param amount Amount to wrap
    function wrap(address token, uint256 amount) external returns (uint256);

    /// @notice Unwraps MeridianUSD into an approved underlying USD asset.
    /// @param token Underlying wrapped USD asset to withdraw
    /// @param amount Amount to unwrap
    function unwrap(address token, uint256 amount) external returns (uint256);
}
