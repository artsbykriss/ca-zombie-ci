// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Poseidon2T4Unrolled} from "poseidon2-lib/Poseidon2T4Unrolled.sol";

/// @title Poseidon Benchmark Contract
/// @dev Wrapper contract to expose Poseidon library functions for gas benchmarking
contract PoseidonBenchmark {
    function hash2(uint a, uint b) public pure returns (uint) {
        return Poseidon2T4Unrolled.hash2(a, b);
    }

    function hashMany(uint[] memory inputs) public pure returns (uint) {
        return Poseidon2T4Unrolled.hashMany(inputs);
    }
}
