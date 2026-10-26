// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface IDexFiProfit {
    function MIN_AMOUNT_OUT() external pure returns (uint256);

    function initializationVersion() external view returns (uint8);

    function factory() external view returns (address);

    function native() external view returns (address);

    function underlying() external view returns (address);

    function underlyingType() external view returns (string memory);

    function decodeAndValidateReinitialize(bytes memory params) external view returns (bool);

    error ReinitalizeCallerNotFactory(address caller, address factory);

    function getAmountOutUnderlyingToNative(uint256 underlyingAmount) external returns (uint256 nativeAmount);

    function initialize(bytes memory params) external returns (bool);

    function reinitialize(bytes memory params) external returns (bool);

    function swapNativeToProfit(uint256 nativeAmount) external returns (uint256 profitAmount, uint256 usedNativeAmount);
}
