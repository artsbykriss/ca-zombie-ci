// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Poseidon2T4Unrolled} from "poseidon2-lib/Poseidon2T4Unrolled.sol";

/// @title Benchmark wrapper for Poseidon2T4Unrolled
contract Poseidon2T4UnrolledBenchmark {
    function hash1(uint a) public pure returns (uint) {
        return Poseidon2T4Unrolled.hash1(a);
    }

    function hash2(uint a, uint b) public pure returns (uint) {
        return Poseidon2T4Unrolled.hash2(a, b);
    }

    function hash3(uint a, uint b, uint c) public pure returns (uint) {
        return Poseidon2T4Unrolled.hash3(a, b, c);
    }

    function hashMany(uint[] memory inputs) public pure returns (uint) {
        return Poseidon2T4Unrolled.hashMany(inputs);
    }
}
