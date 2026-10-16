// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUpdexVoter {
    function poolToGauge(address pool) external view returns (address);
}
