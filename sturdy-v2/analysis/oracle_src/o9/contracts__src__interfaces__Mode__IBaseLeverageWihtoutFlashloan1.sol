// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IBaseLeverageWihtoutFlashloan1 {

  struct LeverageParams {
    uint256 principal;
    uint256 iterations;
    address borrowAsset;
    address collateralAsset;
    address silo;
  }
}