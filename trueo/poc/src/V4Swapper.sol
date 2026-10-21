// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, IPoolManager, PoolKey, SwapParams} from "./Interfaces.sol";

/// @notice Minimal Uniswap v4 exact-input swapper (pulls input from msg.sender).
contract V4Swapper {
    IPoolManager public constant PM = IPoolManager(0x498581fF718922c3f8e6A244956aF099B2652b2b);
    uint160 internal constant MIN_SQRT = 4295128739;
    uint160 internal constant MAX_SQRT = 1461446703485210103287273052203988822378723970341;

    /// @param zeroForOne true = currency0 in / currency1 out
    function swapExactIn(PoolKey calldata key, bool zeroForOne, uint256 amountIn, address recipient)
        external
        returns (int256)
    {
        address input = zeroForOne ? key.currency0 : key.currency1;
        require(IERC20(input).transferFrom(msg.sender, address(this), amountIn), "pull failed");
        bytes memory ret = PM.unlock(abi.encode(key, zeroForOne, -int256(amountIn), recipient));
        return abi.decode(ret, (int256));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(PM), "not pool manager");
        (PoolKey memory key, bool zeroForOne, int256 amountSpecified, address recipient) =
            abi.decode(data, (PoolKey, bool, int256, address));

        uint160 limit = zeroForOne ? MIN_SQRT + 1 : MAX_SQRT - 1;
        int256 delta = PM.swap(key, SwapParams(zeroForOne, amountSpecified, limit), "");

        int128 a0 = int128(delta >> 128);
        int128 a1 = int128(uint128(uint256(delta)));

        // v4 convention: negative = caller pays, positive = caller receives
        if (a1 < 0) {
            PM.sync(key.currency1);
            IERC20(key.currency1).transfer(address(PM), uint256(uint128(-a1)));
            PM.settle();
        }
        if (a0 < 0) {
            PM.sync(key.currency0);
            IERC20(key.currency0).transfer(address(PM), uint256(uint128(-a0)));
            PM.settle();
        }
        if (a0 > 0) PM.take(key.currency0, recipient, uint256(uint128(a0)));
        if (a1 > 0) PM.take(key.currency1, recipient, uint256(uint128(a1)));
        return abi.encode(delta);
    }
}
