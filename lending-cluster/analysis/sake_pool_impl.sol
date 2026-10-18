// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from '../libraries/helpers/Errors.sol';
import {L2Pool} from './L2Pool.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';


/**
 * @title MainPool5
 * @author SakeFinance
 * @notice
 */
contract MainPool5 is L2Pool {

  constructor(IPoolAddressesProvider provider) L2Pool(provider) {}

  function initialize(IPoolAddressesProvider provider) external virtual override initializer {
    require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return 5;
  }

  function poolRevision() public pure returns (uint256) {
    return 5;
  }
}
