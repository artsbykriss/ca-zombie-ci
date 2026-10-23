// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

contract PurrLPFees {
    using SafeTransferLib for address;
    error ErrInvalidSender();

    address internal immutable pair;
    address public immutable token0;
    address public immutable token1;

    constructor(address token0_, address token1_) {
        pair = msg.sender;
        token0 = token0_;
        token1 = token1_;
    }

    function claimFeesFor(address recipient, uint256 amount0, uint256 amount1) external {
        require(msg.sender == pair, ErrInvalidSender());

        if (amount0 > 0) {
            token0.safeTransfer(recipient, amount0);
        }
        if (amount1 > 0) {
            token1.safeTransfer(recipient, amount1);
        }
    }
}
