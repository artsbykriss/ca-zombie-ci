// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWETH9Deposit {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title RouterParker
/// @notice Test-only: wraps the ETH sent, transfers the WETH to `router`, then calls `target` with `data`.
contract RouterParker {
    function parkAndCall(address weth, address router, address target, bytes calldata data) external payable {
        IWETH9Deposit(weth).deposit{value: msg.value}();
        require(IWETH9Deposit(weth).transfer(router, msg.value), "RouterParker: WETH transfer failed");
        (bool ok, bytes memory ret) = target.call(data);
        if (!ok) {
            assembly {
                revert(add(ret, 32), mload(ret))
            }
        }
    }
}
