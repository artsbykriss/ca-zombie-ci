// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Pellar + LightLink 2022

interface IZooKeeper {
  function transferERC20In(
    address _currency,
    address _from,
    uint256 _amount
  ) external;

  function transferERC20Out(
    address _currency,
    address _to,
    uint256 _amount
  ) external;

  function transferERC721In(
    address _currency,
    address _from,
    uint256 _tokenId
  ) external;

  function transferERC721Out(
    address _currency,
    address _to,
    uint256 _tokenId
  ) external;

  function transferERC1155In(
    address _currency,
    address _from,
    uint256 _id,
    uint256 _amount
  ) external;

  function transferERC1155Out(
    address _currency,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;
}
