// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Pellar + LightLink 2022

interface ISummonChampion {
  // mint
  function mintTo(address _owner, string memory _uri) external returns (uint256);

  function getCurrentId() external view returns (uint256);
}
