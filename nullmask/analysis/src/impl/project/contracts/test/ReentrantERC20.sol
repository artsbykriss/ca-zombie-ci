// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ReentrantERC20
 * @notice Test token whose `transferFrom` calls back into a target contract before moving
 *         any balance, and bubbles the callback's revert. Used to show that the pool's
 *         entry points cannot be re-entered from inside a token pull.
 * @dev Not for production.
 */
contract ReentrantERC20 is ERC20 {
    address public reenterTarget;
    bytes public reenterData;

    constructor() ERC20("Reentrant", "REE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Arm the callback. An empty `data` disarms it.
    function setReentry(address target, bytes calldata data) external {
        reenterTarget = target;
        reenterData = data;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (reenterData.length != 0) {
            (bool ok, bytes memory ret) = reenterTarget.call(reenterData);
            if (!ok) {
                assembly {
                    revert(add(ret, 32), mload(ret))
                }
            }
        }
        return super.transferFrom(from, to, value);
    }
}
