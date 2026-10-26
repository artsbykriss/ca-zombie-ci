// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IBaseLeverage {
  enum FlashLoanType {
    AAVE,
    BALANCER
  }

  enum SwapType {
    NONE,
    STAKE,
    UNSTAKE,
    DEPOSIT,
    WITHDRAW,
    UNISWAP,
    BALANCER,
    CURVE
  }

  struct MultipSwapPath {
    address[9] routes;
    uint256[3][4] routeParams;
    // uniswap/balancer/curve
    SwapType swapType;
    uint256 poolCount;
    address swapFrom;
    address swapTo;
    uint256 inAmount;
    uint256 outAmount;
  }

  struct BiDirectSwapInfo {
    MultipSwapPath[4] paths;
    MultipSwapPath[4] reversePaths;
    uint256 pathLength;
  }

  struct UniDirectSwapInfo {
    MultipSwapPath[4] paths;
    uint256 pathLength;
  }

  struct FlashLoanParams {
    bool isEnterPosition;
    uint256 minRequiredAmount;
    address user;
    address collateralAsset;
    address silo;
    BiDirectSwapInfo borrowAssetAndCollateral;
    BiDirectSwapInfo borrowAssetAndSiloAsset;
  }

  struct LeverageParams {
    address user;
    uint256 principal;
    uint256 leverage;
    address borrowAsset;
    address collateralAsset;
    address silo;
    FlashLoanType flashLoanType;
    BiDirectSwapInfo borrowAssetAndCollateral;
    BiDirectSwapInfo borrowAssetAndSiloAsset;
  }

  function enterPositionWithFlashloan(
    uint256 _principal,
    uint256 _leverage,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    FlashLoanType _flashLoanType,
    BiDirectSwapInfo calldata _borrowAssetAndCollateral,
    BiDirectSwapInfo calldata _borrowAssetAndSiloAsset
  ) external;

  function withdrawWithFlashloan(
    uint256 _repayAmount,
    uint256 _requiredAmount,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    FlashLoanType _flashLoanType,
    BiDirectSwapInfo calldata _borrowAssetAndSiloAsset,
    BiDirectSwapInfo calldata _borrowAssetAndCollateral
  ) external;
}
