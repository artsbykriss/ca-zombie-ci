// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.9.2
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid solidity code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

contract DecompiledContract {
    uint256 public constant unresolved_dc4c90d3 = 22154441650658625721468672576359056;
    bytes public constant unresolved_ad3cb1cc = 0xBytes([53, 46, 48, 46, 48]);
    uint256 public constant unresolved_54fd4d50 = 53458043598169069555907966783562313010239875311082982325942585142490863501312;
    bool public constant unresolved_c4e833ce = 0xBool(false);
    uint256 public constant unresolved_52d1902d = e07c8dba;
    
    bool public unresolved_d19d9ed6;
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_d;
    address store_e;
    address public unresolved_141a8dd8;
    mapping(bytes32 => bytes32) storage_map_c;
    
    error CustomError_00000000();
    event Event_a34581b4();
    event Event_bc7cd75a();
    event Event_8be0079c();
    
    /// @custom:selector    0x9f063efc
    /// @custom:signature   Unresolved_9f063efc(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    function Unresolved_9f063efc(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_ae18210a());
        return abi.encodePacked(0x9f063efc00000000000000000000000000000000000000000000000000000000, arg10);
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public
    function Unresolved_715018a6() public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_8da5cb5b = 0 | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), 0);
    }
    
    /// @custom:selector    0xdc98354e
    /// @custom:signature   Unresolved_dc98354e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dc98354e(address arg0) public pure {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
    }
    
    /// @custom:selector    0x3717f465
    /// @custom:signature   Unresolved_3717f465(bool arg0) public
    /// @param              arg0 ["bool", "uint8", "bytes1", "int8"]
    function Unresolved_3717f465(bool arg0) public {
        require(arg0 < 0x04);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(!arg0 > 0x03);
        unresolved_d19d9ed6 = (bytes1(arg0) * 0x01000000) | (uint248(unresolved_d19d9ed6));
    }
    
    /// @custom:selector    0x0cd55abf
    /// @custom:signature   Unresolved_0cd55abf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_0cd55abf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_c[var_b];
    }
    
    /// @custom:selector    0x8f3ed683
    /// @custom:signature   Unresolved_8f3ed683(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_8f3ed683(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        address var_c = address(arg0);
        storage_map_d[var_c] = arg1 | (uint248(storage_map_d[var_c]));
        emit Event_a34581b4(address(arg0), arg1, 0);
    }
    
    /// @custom:selector    0xe1b4af69
    /// @custom:signature   Unresolved_e1b4af69(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    function Unresolved_e1b4af69(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!arg8 > 0xffffffffffffffff);
        require(!(arg8) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0x8da995be
    /// @custom:signature   Unresolved_8da995be(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_8da995be(uint256 arg0) public {
        require(arg0 == arg0);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_d19d9ed6 = (uint248(unresolved_d19d9ed6)) | (0x010000 * arg0);
    }
    
    /// @custom:selector    0x80dd9a1f
    /// @custom:signature   Unresolved_80dd9a1f(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_80dd9a1f(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_c[var_b]));
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1 > 0xffffffffffffffff), CustomError_e07c8dba());
        require(!(((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) < var_c) | ((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) > 0xffffffffffffffff)), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f));
        require(0x521553991534f26b9aea7d3ac6d798ade0508fc0 == address(this), CustomError_e07c8dba());
        require(!(0x521553991534f26b9aea7d3ac6d798ade0508fc0 == address(this)), CustomError_e07c8dba());
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        address var_g = msg.sender;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        require(var_c == 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, CustomError_4c9c8ce3());
        require(0 - address(0x09dd).code.length, CustomError_4c9c8ce3());
        var_g = 0x09dd;
        store_e = var_g | (uint96(store_e));
        emit Event_bc7cd75a(0x09dd);
        require(!var_h);
        (bool success, bytes memory ret0) = address(0x09dd).Unresolved_(var_i); // delegatecall
        require(ret0.length == 0);
        require(!var_j);
        require(var_j, CustomError_9996b315());
        require(var_j, CustomError_9996b315());
        require(address(0x09dd).code.length, CustomError_9996b315());
        var_c = var_c + (uint248(ret0.length + 0x3f));
        require(!var_c.length, CustomError_d6bda275());
        require(var_c.length, CustomError_9996b315());
        require(address(0x09dd).code.length, CustomError_9996b315());
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_4c9c8ce3());
        require(0x01, CustomError_4c9c8ce3());
        require(var_c.length == 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, CustomError_4c9c8ce3());
        require(0 - (address(arg0).code.length), CustomError_4c9c8ce3());
        store_e = (address(arg0)) | (uint96(store_e));
        emit Event_bc7cd75a(address(arg0));
        require(!var_c.length);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_o); // delegatecall
        require(ret0.length == 0);
        require(!var_j);
        require(var_j, CustomError_9996b315());
        require(var_j, CustomError_9996b315());
        require(!(!address(arg0).code.length), CustomError_9996b315());
        var_c = var_c + (uint248(ret0.length + 0x3f));
        require(!var_c.length, CustomError_d6bda275());
        require(var_c.length, CustomError_9996b315());
        require(!(!address(arg0).code.length), CustomError_9996b315());
        require(!(!(address(store_e)) == 0x521553991534f26b9aea7d3ac6d798ade0508fc0), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0x92a88fa2
    /// @custom:signature   Unresolved_92a88fa2(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_92a88fa2(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_c[var_b]));
    }
    
    /// @custom:selector    0x575e24b4
    /// @custom:signature   Unresolved_575e24b4(address arg0, address arg1, uint256 arg2, uint256 arg3) public returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    function Unresolved_575e24b4(address arg0, address arg1, uint256 arg2, uint256 arg3) public returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x60);
        require(!arg9 > 0xffffffffffffffff);
        require(!(arg9) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender);
        require(bytes1(unresolved_d19d9ed6));
        require(!bytes1(unresolved_d19d9ed6 / 0x0100));
        address var_a = address(arg0);
        require(bytes1(storage_map_f[var_a]));
        require(!address(unresolved_141a8dd8));
        require(!((0x24 + (msg.data.length - 0x24)) - 0x24) < 0xa0);
        require(!((var_c + 0xa0) < var_c) | ((var_c + 0xa0) > 0xffffffffffffffff));
        require(arg1 == (address(arg1)));
        require(!0x20 < 0x20);
        require(arg6 == arg6);
        require(arg6, CustomError_82b42900());
        require(!(0x02 > 0x03), CustomError_82b42900());
        require(bytes1(unresolved_d19d9ed6 / 0x01000000) - 0x02, CustomError_82b42900());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_d737d0c7(var_f); // staticcall
        require(0, CustomError_82b42900());
        var_a = 0;
        require(bytes1(storage_map_f[var_a]), CustomError_82b42900());
        return abi.encodePacked(0x575e24b400000000000000000000000000000000000000000000000000000000, 0, 0);
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (address(var_c.length)));
        require(0x01);
        return abi.encodePacked(0x575e24b400000000000000000000000000000000000000000000000000000000, 0, 0);
    }
    
    /// @custom:selector    0xb47b2fb1
    /// @custom:signature   Unresolved_b47b2fb1(address arg0, uint256 arg1, uint256 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_b47b2fb1(address arg0, uint256 arg1, uint256 arg2) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x60);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_ae18210a());
        return abi.encodePacked(0xb47b2fb100000000000000000000000000000000000000000000000000000000, 11);
    }
    
    /// @custom:selector    0x51ad3ced
    /// @custom:signature   Unresolved_51ad3ced(address arg0, uint256 arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_51ad3ced(address arg0, uint256 arg1) public pure {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
    }
    
    /// @custom:selector    0x259982e5
    /// @custom:signature   Unresolved_259982e5(address arg0, uint256 arg1) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_259982e5(address arg0, uint256 arg1) public returns (uint256) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_82b42900());
        require(bytes1(unresolved_d19d9ed6), CustomError_82b42900());
        require(!(bytes1(unresolved_d19d9ed6 / 0x010000)), CustomError_82b42900());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_d737d0c7(var_b); // staticcall
        require(0, CustomError_82b42900());
        uint256 var_c = 0;
        require(bytes1(storage_map_d[var_c]), CustomError_82b42900());
        return 0x259982e500000000000000000000000000000000000000000000000000000000;
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(var_e.length == (address(var_e.length)));
        require(0x01);
        return 0x259982e500000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(address(arg0), CustomError_1e4fbdf7());
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0x6fe7e6eb
    /// @custom:signature   Unresolved_6fe7e6eb(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6fe7e6eb(address arg0) public pure {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
    }
    
    /// @custom:selector    0x328d8f72
    /// @custom:signature   Unresolved_328d8f72(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_328d8f72(uint256 arg0) public {
        require(arg0 == arg0);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_d19d9ed6 = arg0 | (uint248(unresolved_d19d9ed6));
    }
    
    /// @custom:selector    0xeed1cebd
    /// @custom:signature   Unresolved_eed1cebd(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_eed1cebd(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        address var_c = address(arg0);
        storage_map_d[var_c] = arg1 | (uint248(storage_map_d[var_c]));
        emit Event_a34581b4(address(arg0), arg1, 0x01);
    }
    
    /// @custom:selector    0x6c2bbe7e
    /// @custom:signature   Unresolved_6c2bbe7e(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    function Unresolved_6c2bbe7e(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_ae18210a());
        return abi.encodePacked(0x6c2bbe7e00000000000000000000000000000000000000000000000000000000, arg10);
    }
    
    /// @custom:selector    0x21d0ee70
    /// @custom:signature   Unresolved_21d0ee70(address arg0, uint256 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_21d0ee70(address arg0, uint256 arg1) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_75884cda());
        require(bytes1(unresolved_d19d9ed6), CustomError_75884cda());
        return 0x21d0ee7000000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xca039b9a
    /// @custom:signature   Unresolved_ca039b9a(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_ca039b9a(uint256 arg0) public {
        require(arg0 == arg0);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_d19d9ed6 = (uint248(unresolved_d19d9ed6)) | (0x0100 * arg0);
    }
    
    /// @custom:selector    0xb6a8b0fa
    /// @custom:signature   Unresolved_b6a8b0fa(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    function Unresolved_b6a8b0fa(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!arg8 > 0xffffffffffffffff);
        require(!(arg8) > 0xffffffffffffffff);
        require(0x04444c5dc75cb358380d2e3de08a90 == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0x3156560e
    /// @custom:signature   Unresolved_3156560e(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3156560e(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_141a8dd8 = (address(arg0)) | (uint96(unresolved_141a8dd8));
    }
}