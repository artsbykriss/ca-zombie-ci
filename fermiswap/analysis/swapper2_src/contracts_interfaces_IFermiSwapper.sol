// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "./IFermiEngine.sol";
import "./IPropAMMExactOut.sol";

interface IFermiSwapper is IPropAMMExactOut {
    function fermi() external view returns (IFermiEngine);
    function traderVault() external view returns (address payable);
    function isEnabled(address tokenIn, address tokenOut) external view returns (bool);
    function getPairsWithStatus() external view returns (IFermiEngine.PairInfo[] memory pairs);

    function quoteAmounts(address tokenIn, address tokenOut, int256 amountSpecified)
        external
        view
        returns (uint256 amountIn, uint256 amountOut);

    function fermiSwapWithAllowances(
        address tokenIn,
        address tokenOut,
        int256 amountSpecified,
        uint256 amountCheck,
        address recipient
    ) external returns (uint256 amountIn, uint256 amountOut);

    function fermiSwapWithCallback(
        address tokenIn,
        address tokenOut,
        int256 amountSpecified,
        uint256 amountCheck,
        address recipient,
        bytes calldata callbackData
    ) external returns (uint256 amountIn, uint256 amountOut);
}
