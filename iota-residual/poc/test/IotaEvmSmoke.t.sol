// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// @title IOTA EVM fork smoke test
/// @notice Validates that the CI runner can fork IOTA EVM (chain 8822) from a public keyless RPC
///         and read Deepr Finance's comptroller/markets. Read-only: no transactions are broadcast.
contract IotaEvmSmokeTest is Test {
    address constant COMPTROLLER = 0xee07121d97FDEA35675e02017837a7a43aeDa48F;

    function forkUrl() internal view returns (string memory) {
        return vm.envOr("IOTA_EVM_RPC", string("https://rpc.ankr.com/iota_evm"));
    }

    function test_fork_iota_evm_and_read_deepr_comptroller() public {
        string memory url = forkUrl();
        vm.createSelectFork(url);
        assertEq(block.chainid, 8822, "chain id must be IOTA EVM (8822)");

        (bool ok, bytes memory ret) = COMPTROLLER.staticcall(abi.encodeWithSignature("getAllMarkets()"));
        require(ok, "getAllMarkets() failed");
        address[] memory markets = abi.decode(ret, (address[]));
        emit log_named_uint("deepr markets", markets.length);
        emit log_named_uint("fork block", block.number);

        // read one market's cash + underlying
        if (markets.length > 0) {
            (bool ok2, bytes memory r2) = markets[0].staticcall(abi.encodeWithSignature("getCash()"));
            require(ok2, "getCash() failed");
            emit log_named_uint("market[0] cash", abi.decode(r2, (uint256)));
            (bool ok3, bytes memory r3) = markets[0].staticcall(abi.encodeWithSignature("underlying()"));
            require(ok3, "underlying() failed");
            emit log_named_address("market[0] underlying", abi.decode(r3, (address)));
        }
    }
}
