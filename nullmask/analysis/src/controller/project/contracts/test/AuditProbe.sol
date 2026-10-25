// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice AUDIT-ONLY probe: contract depositor that bounces any incoming ETH back to the pool.
contract AuditProbe {
    address public immutable nm;
    bool public bounce;

    constructor(address _nm) { nm = _nm; }

    function arm(bool v) external { bounce = v; }

    function depositTo(address recipient, uint256 amount) external payable {
        (bool ok, bytes memory d) = nm.call{value: msg.value}(
            abi.encodeWithSignature("depositTo(address,uint256,address)", recipient, amount, address(0))
        );
        if (!ok) { assembly { revert(add(d, 32), mload(d)) } }
    }

    receive() external payable {
        if (bounce) {
            (bool ok, bytes memory d) = nm.call{value: msg.value}("");
            if (!ok) { assembly { revert(add(d, 32), mload(d)) } }
        }
    }
}
