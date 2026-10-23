/// Copyright 2021 DODO ZOO.
/// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IPurrLPOracle {
    function price(address base) external view returns (uint256);
}