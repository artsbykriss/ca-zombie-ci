// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;
pragma abicoder v2;

interface IEtherexVoter {
    /// @notice returns the address of the pool's gauge, if any
    /// @param pool pool address
    /// @return gauge address
    function gaugeForPool(address pool) external view returns (address);
}