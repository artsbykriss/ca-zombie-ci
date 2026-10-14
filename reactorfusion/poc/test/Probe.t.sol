// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

contract Probe is Test {
    function _rpc() internal view returns (string memory) {
        string memory e = vm.envOr("ERA_RPC_URL", string(""));
        if (bytes(e).length > 0) return e;
        string memory k = vm.envOr("DRPC_API_KEY", string(""));
        if (bytes(k).length > 0) return string.concat("https://lb.drpc.org/ogrpc?network=zksync-era&dkey=", k);
        return "https://mainnet.era.zksync.io";
    }

    function test_probe() public {
        vm.createSelectFork(_rpc(), 72_485_663);
        address impl = 0xF3CaF0bE62a0E6Ff6569004af55F57A0B9440434;
        address unitroller = 0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2;
        address oracle = 0x1d54DD49218333125C858c0239bbdA424db55C43;
        address rfeth = 0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6;
        emit log_named_uint("impl code len", impl.code.length);
        emit log_named_uint("unitroller code len", unitroller.code.length);
        emit log_named_uint("oracle code len", oracle.code.length);
        emit log_named_uint("rfeth code len", rfeth.code.length);
        (bool ok1, bytes memory r1) = oracle.staticcall(abi.encodeWithSignature("owner()"));
        emit log_named_string("oracle.owner ok", ok1 ? "true" : "false");
        emit log_named_bytes("oracle.owner ret", r1);
        (bool ok2, bytes memory r2) = rfeth.staticcall(abi.encodeWithSignature("getCash()"));
        emit log_named_string("rfeth.getCash ok", ok2 ? "true" : "false");
        emit log_named_bytes("rfeth.getCash ret", r2);
        (bool ok3, bytes memory r3) = unitroller.staticcall(abi.encodeWithSignature("closeFactorMantissa()"));
        emit log_named_string("unitroller.closeFactor ok", ok3 ? "true" : "false");
        emit log_named_bytes("unitroller.closeFactor ret", r3);
        // read the unitroller's implementation slot (0x0 for Compound Unitroller is comptrollerImplementation)
        bytes32 slot;
        assembly { slot := sload(0) }
        emit log_named_bytes32("slot0", slot);
    }
}
