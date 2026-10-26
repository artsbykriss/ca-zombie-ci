// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IBaseLeverageWihtoutFlashloan {

  enum SwapType {
    NONE,
    DEPOSIT,
    WITHDRAW,
    SUPSWAP
  }

  struct LeverageParams {
    uint256 principal;
    uint256 iterations;
    address borrowAsset;
    address collateralAsset;
    address silo;
    BiDirectSwapInfo borrowAssetAndCollateral;
  }

  struct MultipSwapPath {
    address[9] routes;
    uint256[3][4] routeParams;
    // supswap
    SwapType swapType;
    uint256 poolCount;
    address swapFrom;
    address swapTo;
    uint256 inAmount;
    uint256 outAmount;
  }

  struct BiDirectSwapInfo {
    MultipSwapPath[3] paths;
    MultipSwapPath[3] reversePaths;
    uint256 pathLength;
  }

  struct UniDirectSwapInfo {
    MultipSwapPath[3] paths;
    uint256 pathLength;
  }
}
