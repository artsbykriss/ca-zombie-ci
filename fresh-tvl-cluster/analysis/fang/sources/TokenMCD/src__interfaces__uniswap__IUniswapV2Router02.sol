// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IUniswapV2Router02
/// @notice Minimal Uniswap V2 router surface.
interface IUniswapV2Router02 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external;

    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}
