// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {ForkEnv} from "../src/ForkEnv.sol";

contract ForkProbe is ForkEnv {
    function test_probe() public {
        string memory rpc = _rpc("ARB_RPC_URL", "https://arb1.arbitrum.io/rpc");
        vm.createSelectFork(rpc);
        emit log_named_uint("chainid", block.chainid);
        emit log_named_uint("block_number", block.number);
        emit log_named_uint("timestamp", block.timestamp);
        bytes memory b = vm.rpc("eth_blockNumber", "[]");
        emit log_named_bytes("eth_blockNumber", b);
        emit log_named_uint("getBlockNumber", vm.getBlockNumber());
    }
}
