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
    uint256 public constant unresolved_f3b97784 = 1193341974788526296072818703775488833234173927424;
    uint256 public constant unresolved_b7d122b5 = 1000000;
    uint256 public constant unresolved_4fb3ccc5 = 659369368286436488732577142202224786739049479960;
    
    address public unresolved_8da5cb5b;
    address public unresolved_bf7e214f;
    bytes32 store_d;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_k;
    bool public unresolved_b187bd26;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_e;
    mapping(bytes32 => bytes32) storage_map_j;
    mapping(bytes32 => bytes32) storage_map_c;
    
    event Event_3be638a5();
    event Event_2eb08ebd();
    error CustomError_00000000();
    event Event_a3396fd7();
    event Event_f1abf38a();
    event Event_9e87fac8();
    event Event_a45f47fd();
    event Event_8be0079c();
    
    /// @custom:selector    0x74732728
    /// @custom:signature   Unresolved_74732728(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_74732728(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        address var_h = address(arg0);
        storage_map_c[var_h] = uint248(storage_map_c[var_h]);
        emit Event_f1abf38a(address(arg0));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        var_h = address(arg0);
        storage_map_c[var_h] = uint248(storage_map_c[var_h]);
        emit Event_f1abf38a(address(arg0));
    }
    
    /// @custom:selector    0x4a2dc5e4
    /// @custom:signature   Unresolved_4a2dc5e4(uint96 arg0, address arg1) public pure
    /// @param              arg0 ["uint96", "bytes12", "int96"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4a2dc5e4(uint96 arg0, address arg1) public pure {
        require(!((var_a + 0x0100) < var_a) | ((var_a + 0x0100) > 0xffffffffffffffff));
        require(arg0 == (uint96(arg0)));
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xac33a273
    /// @custom:signature   Unresolved_ac33a273() public view returns (bytes memory)
    function Unresolved_ac33a273() public view returns (bytes memory) {
        uint256 var_a = var_a + (0x20 + (0x20 * store_d));
        if (!store_d) {
            var_c = 0x03;
            if ((0x20 + var_a) + (0x20 * store_d) > (0x20 + (0x20 + var_a))) {
                return abi.encodePacked(0x20, var_a.length);
            }
        }
    }
    
    /// @custom:selector    0xa5672fd7
    /// @custom:signature   Unresolved_a5672fd7(uint96 arg0, address arg1) public pure
    /// @param              arg0 ["uint96", "bytes12", "int96"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a5672fd7(uint96 arg0, address arg1) public pure {
        require(!((var_a + 0x0100) < var_a) | ((var_a + 0x0100) > 0xffffffffffffffff));
        require(arg0 == (uint96(arg0)));
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xeed4b3f8
    /// @custom:signature   Unresolved_eed4b3f8(address arg0, uint24 arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint24", "bytes3", "int24"]
    function Unresolved_eed4b3f8(address arg0, uint24 arg1) public pure {
        require(arg0 == (address(arg0)));
        require(arg1 == (uint24(arg1)));
    }
    
    /// @custom:selector    0x9fff7e2a
    /// @custom:signature   Unresolved_9fff7e2a(uint256 arg0, uint96 arg1, address arg2) public payable returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint96", "bytes12", "int96"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9fff7e2a(uint256 arg0, uint96 arg1, address arg2) public payable returns (bytes memory) {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        require(!(arg0) > 0xffffffffffffffff);
        var_e = var_e + (0x20 + (0x20 * (arg0)));
        require(!arg0);
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!((var_e + 0x0100) < var_e) | ((var_e + 0x0100) > 0xffffffffffffffff));
        var_e = var_e + 0x0100;
        require((0 + (arg0 + 0x20)) == (uint96(0 + (arg0 + 0x20))));
        require(((0 + (arg0 + 0x20)) + 0x20) == (address((0 + (arg0 + 0x20)) + 0x20)));
        return abi.encodePacked(0x20, var_e.length);
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
    
    /// @custom:selector    0xe69a31c2
    /// @custom:signature   Unresolved_e69a31c2(address arg0, address arg1, uint16 arg2) public payable returns (uint16)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    function Unresolved_e69a31c2(address arg0, address arg1, uint16 arg2) public payable returns (uint16) {
        require(arg0 == (address(arg0)));
        require(arg1 == (address(arg1)));
        require(arg2 == (uint16(arg2)));
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(0x737f2522d09e58a3ea9dccfdb127dd0df5eb3f18).Unresolved_820973da(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(!(0x2710 - (uint16(arg2))) > 0xffff);
        require(0x2710 * (!(uint16(0x2710 - (arg2))) * (var_c.length > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / (uint16(0x2710 - (arg2)))))));
        require(0x0f4240 * (!((var_c.length * (uint16(0x2710 - (arg2)))) / 0x2710) * (address(arg1) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / ((var_c.length * (uint16(0x2710 - (arg2)))) / 0x2710)))));
        require(!((address(arg1) * ((var_c.length * (uint16(0x2710 - (arg2)))) / 0x2710) / 0x0f4240) > 0xffffffffffffffffffffffffffffffff), CustomError_56371231());
        return address(arg1 * ((var_c.length * (uint16(0x2710 - (uint16(arg2))))) / 0x2710) / 0x0f4240);
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(msg.sender, address(arg0));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(msg.sender, address(arg0));
    }
    
    /// @custom:selector    0xe260780c
    /// @custom:signature   Unresolved_e260780c(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_e260780c(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        address var_h = address(arg0);
        storage_map_f[var_h] = arg1;
        emit Event_3be638a5(address(arg0), arg1);
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        var_h = address(arg0);
        storage_map_f[var_h] = arg1;
        emit Event_3be638a5(address(arg0), arg1);
    }
    
    /// @custom:selector    0x0bf6cab7
    /// @custom:signature   Unresolved_0bf6cab7(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_0bf6cab7(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_3f4ba83a(uint32 arg0) public payable {
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        unresolved_b187bd26 = uint248(unresolved_b187bd26);
        emit Event_a45f47fd();
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        unresolved_b187bd26 = uint248(unresolved_b187bd26);
        emit Event_a45f47fd();
    }
    
    /// @custom:selector    0xaa5a0ffd
    /// @custom:signature   Unresolved_aa5a0ffd(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_aa5a0ffd(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return abi.encodePacked(!(!bytes1(storage_map_h[var_b])), uint24(storage_map_h[var_b] / 0x0100), uint24(storage_map_h[var_b] / 0x0100000000), uint16(storage_map_h[var_b] / 0x0100000000000000), uint16(storage_map_h[var_b] / 0x01000000000000000000), uint96(storage_map_h[var_b] / 0x010000000000000000000000), storage_map_i[var_b]);
    }
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   Unresolved_7a9e5e4b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7a9e5e4b(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(var_e.length == var_e.length);
        require(var_e.length);
        unresolved_bf7e214f = (address(arg0)) | (uint96(unresolved_bf7e214f));
        emit Event_a3396fd7(msg.sender, address(arg0));
    }
    
    /// @custom:selector    0xb22ed42a
    /// @custom:signature   Unresolved_b22ed42a(uint96 arg0, address arg1, address arg2, address arg3) public pure
    /// @param              arg0 ["uint96", "bytes12", "int96"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint128", "bytes16", "int128"]
    function Unresolved_b22ed42a(uint96 arg0, address arg1, address arg2, address arg3) public pure {
        require(arg0 == (uint96(arg0)));
        require(arg1 == (address(arg1)));
        require(arg2 == (address(arg2)));
        require(arg3 == (address(arg3)));
    }
    
    /// @custom:selector    0x412638dc
    /// @custom:signature   Unresolved_412638dc(uint256 arg0, uint256 arg1, address arg2, address arg3, address arg4, uint40 arg5, uint24 arg6, uint24 arg7) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg6 ["uint40", "bytes5", "int40"]
    /// @param              arg7 ["uint24", "bytes3", "int24"]
    /// @param              arg8 ["uint24", "bytes3", "int24"]
    function Unresolved_412638dc(uint256 arg0, uint256 arg1, address arg2, address arg3, address arg4, uint40 arg5, uint24 arg6, uint24 arg7) public payable {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(arg2 == (address(arg2)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        require(!(bytes1(unresolved_b187bd26 / 0x01000000000000000000000000)), CustomError_2b162fc6());
        require(0 < (arg0));
        require(!(((0x40 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0x40 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0x40 + (0 + (arg0 + 0x20))) == (address(0x40 + (0 + (arg0 + 0x20)))));
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0x40 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0x40 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0x40 + (0 + (arg0 + 0x20))) == (address(0x40 + (0 + (arg0 + 0x20)))));
        require(address(0x40 + (0 + (arg0 + 0x20))) == (address(0x40 + (0 + (arg0 + 0x20)))), CustomError_c7d66d64());
        require(0 < (arg0));
        require(!(((0xc0 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0xc0 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0xc0 + (0 + (arg0 + 0x20))) == (uint24(0xc0 + (0 + (arg0 + 0x20)))));
        require(0 < (arg0));
        require(!(((0xa0 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0xa0 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0xa0 + (0 + (arg0 + 0x20))) == (uint40(0xa0 + (0 + (arg0 + 0x20)))));
        require(!(uint40(uint24(0xc0 + (0 + (arg0 + 0x20)))) + (uint40(0xa0 + (0 + (arg0 + 0x20)))) > 0xffffffffff), CustomError_32924a49());
        require(!(block.timestamp < (uint40(uint24(0xc0 + (0 + (arg0 + 0x20))) + (0xa0 + (0 + (arg0 + 0x20)))))), CustomError_32924a49());
        require(0 < (arg0));
        require(!(((0xe0 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0xe0 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0xe0 + (0 + (arg0 + 0x20))) == (uint24(0xe0 + (0 + (arg0 + 0x20)))));
        require(!(uint40(uint24(0xc0 + (0 + (arg0 + 0x20))) + (0xa0 + (0 + (arg0 + 0x20))))) > (uint24(0xe0 + (0 + (arg0 + 0x20))) + (uint40(uint24(0xc0 + (0 + (arg0 + 0x20))) + (0xa0 + (0 + (arg0 + 0x20)))))));
        require(!block.timestamp > (uint24(0xe0 + (0 + (arg0 + 0x20))) + (uint40(uint24(0xc0 + (0 + (arg0 + 0x20))) + (0xa0 + (0 + (arg0 + 0x20)))))));
        require(0 < (arg0));
        require(!(((0x80 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0x80 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0x80 + (0 + (arg0 + 0x20))) == (address(0x80 + (0 + (arg0 + 0x20)))));
        var_h = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = address(arg2);
        (bool success, bytes memory ret0) = address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).Unresolved_a9059cbb(var_c); // call
        require(((var_h == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success));
        require(!arg1);
        var_c = address(msg.sender);
        require(address(arg2).code.length);
        (bool success, bytes memory ret0) = address(arg2).Unresolved_67aa0416(var_c); // call
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0x20 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0x20 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0x20 + (0 + (arg0 + 0x20))) == (address(0x20 + (0 + (arg0 + 0x20)))));
        require(0 < (arg0));
        require(!(((0x80 + (0 + ((0x04 + arg0) + 0x20))) + 0x20) - (0x80 + (0 + ((0x04 + arg0) + 0x20)))) < 0x20);
        require((0x80 + (0 + (arg0 + 0x20))) == (address(0x80 + (0 + (arg0 + 0x20)))));
        var_c = address(arg2);
        (bool success, bytes memory ret0) = address(0x40 + (0 + (arg0 + 0x20))).Unresolved_23b872dd(var_c); // call
        require(((var_h == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success), "TRANSFER_FROM_FAILED");
        require(0x01, "TRANSFER_FROM_FAILED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_8456cb59(uint32 arg0) public payable {
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        unresolved_b187bd26 = 0x01000000000000000000000000 | (uint248(unresolved_b187bd26));
        emit Event_9e87fac8();
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        unresolved_b187bd26 = 0x01000000000000000000000000 | (uint248(unresolved_b187bd26));
        emit Event_9e87fac8();
    }
    
    /// @custom:selector    0x581b4920
    /// @custom:signature   Unresolved_581b4920(address arg0, address arg1, uint16 arg2, uint24 arg3, uint256 arg4, bool arg5, uint256 arg6, uint256 arg7) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["uint24", "bytes3", "int24"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    function Unresolved_581b4920(address arg0, address arg1, uint16 arg2, uint24 arg3, uint256 arg4, bool arg5, uint256 arg6, uint256 arg7) public payable returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (address(arg1)));
        require(arg2 == (uint16(arg2)));
        require(arg3 == (uint24(arg3)));
        require(arg5 == (bytes1(arg5)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        address var_h = address(arg0);
        require(!(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > (storage_map_j[var_h])), CustomError_2b162fc6());
        var_h = address(arg0);
        var_e = var_e + 0xe0;
        require(!(bytes1(unresolved_b187bd26 / 0x01000000000000000000000000)), CustomError_2b162fc6());
        require(var_e.length, CustomError_a800f195());
        require(uint16(arg2) < (uint16(var_q)), CustomError_a800f195());
        require(!(uint16(arg2) < (uint16(var_q))), CustomError_a800f195());
        require(!(address(arg1) < (uint96(var_r))), CustomError_060a21aa());
        require(!(uint24(arg3) < (uint24(var_s))), CustomError_94fb53cb());
        address var_t = msg.sender;
        require(address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).code.length);
        (bool success, bytes memory ret0) = address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).Unresolved_d505accf(var_t); // call
        var_t = msg.sender;
        (bool success, bytes memory ret0) = address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).Unresolved_dd62ed3e(var_t); // staticcall
        var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), CustomError_4bfd8d1d());
        require(!(var_e.length < (address(arg1))), CustomError_4bfd8d1d());
        var_u = address(msg.sender);
        (bool success, bytes memory ret0) = address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).Unresolved_23b872dd(var_u); // call
        require(((var_h == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success));
        unresolved_b187bd26 = (uint96(unresolved_b187bd26 + 0x01)) | (address(unresolved_b187bd26));
        address var_aj = address(arg0);
        (bool success, bytes memory ret0) = address(0x737f2522d09e58a3ea9dccfdb127dd0df5eb3f18).Unresolved_820973da(var_aj); // staticcall
        var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(!(0x2710 - (uint16(arg2))) > 0xffff);
        require(0x2710 * (!(uint16(0x2710 - (arg2))) * (var_e.length > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / (uint16(0x2710 - (arg2)))))));
        require(0x0f4240 * (!((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710) * (address(arg1) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / ((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710)))));
        require(!((address(arg1) * ((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710) / 0x0f4240) > 0xffffffffffffffffffffffffffffffff), CustomError_56371231());
        var_e = 0x0100 + var_e;
        var_e = (0x20 + var_e) + 0x0100;
        var_h = keccak256(var_aw);
        require(storage_map_c[var_h], CustomError_a0513036());
        require(0, CustomError_a0513036());
        emit Event_2eb08ebd(keccak256(var_aw), address(msg.sender), address(arg0), uint96(unresolved_b187bd26), address(arg1), address(arg1 * ((var_e.length * (uint16(0x2710 - (uint16(arg2))))) / 0x2710) / 0x0f4240), uint40(block.timestamp), uint24(var_bq), uint24(arg3));
        return keccak256(var_aw);
        store_d = 0x01 + store_d;
        var_h = 0x03;
        storage_map_k[var_h] = keccak256(var_aw);
        var_h = keccak256(var_aw);
        storage_map_c[var_h] = store_d;
        require(0x01, CustomError_a0513036());
        emit Event_2eb08ebd(keccak256(var_aw), address(msg.sender), address(arg0), uint96(unresolved_b187bd26), address(arg1), address(arg1 * ((var_e.length * (uint16(0x2710 - (uint16(arg2))))) / 0x2710) / 0x0f4240), uint40(block.timestamp), uint24(var_bq), uint24(arg3));
        return keccak256(var_aw);
        require(!(storage_map_f[var_h] < (address(arg1))), CustomError_c092fd53());
        require(!(storage_map_f[var_h] - (address(arg1))) > (storage_map_f[var_h]));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
    
    /// @custom:selector    0x6bb3b476
    /// @custom:signature   Unresolved_6bb3b476(address arg0, address arg1, uint16 arg2, uint24 arg3) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["uint24", "bytes3", "int24"]
    function Unresolved_6bb3b476(address arg0, address arg1, uint16 arg2, uint24 arg3) public payable returns (uint256) {
        require(arg0 == (address(arg0)));
        require(arg1 == (address(arg1)));
        require(arg2 == (uint16(arg2)));
        require(arg3 == (uint24(arg3)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        address var_h = address(arg0);
        require(!(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > (storage_map_j[var_h])), CustomError_2b162fc6());
        var_h = address(arg0);
        var_e = var_e + 0xe0;
        require(!(bytes1(unresolved_b187bd26 / 0x01000000000000000000000000)), CustomError_2b162fc6());
        require(var_e.length, CustomError_a800f195());
        require(uint16(arg2) < (uint16(var_q)), CustomError_a800f195());
        require(!(uint16(arg2) < (uint16(var_q))), CustomError_a800f195());
        require(!(address(arg1) < (uint96(var_r))), CustomError_060a21aa());
        require(!(uint24(arg3) < (uint24(var_s))), CustomError_94fb53cb());
        address var_t = address(msg.sender);
        (bool success, bytes memory ret0) = address(0xd1074e0ae85610ddba0147e29ebe0d8e5873a000).Unresolved_23b872dd(var_t); // call
        require(((var_h == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success));
        unresolved_b187bd26 = (uint96(unresolved_b187bd26 + 0x01)) | (address(unresolved_b187bd26));
        address var_ae = address(arg0);
        (bool success, bytes memory ret0) = address(0x737f2522d09e58a3ea9dccfdb127dd0df5eb3f18).Unresolved_820973da(var_ae); // staticcall
        var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(!(0x2710 - (uint16(arg2))) > 0xffff);
        require(0x2710 * (!(uint16(0x2710 - (arg2))) * (var_e.length > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / (uint16(0x2710 - (arg2)))))));
        require(0x0f4240 * (!((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710) * (address(arg1) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / ((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710)))));
        require(!((address(arg1) * ((var_e.length * (uint16(0x2710 - (arg2)))) / 0x2710) / 0x0f4240) > 0xffffffffffffffffffffffffffffffff), CustomError_56371231());
        var_e = 0x0100 + var_e;
        var_e = (0x20 + var_e) + 0x0100;
        var_h = keccak256(var_ar);
        require(storage_map_c[var_h], CustomError_a0513036());
        require(0, CustomError_a0513036());
        emit Event_2eb08ebd(keccak256(var_ar), address(msg.sender), address(arg0), uint96(unresolved_b187bd26), address(arg1), address(arg1 * ((var_e.length * (uint16(0x2710 - (uint16(arg2))))) / 0x2710) / 0x0f4240), uint40(block.timestamp), uint24(var_bl), uint24(arg3));
        return keccak256(var_ar);
        store_d = 0x01 + store_d;
        var_h = 0x03;
        storage_map_k[var_h] = keccak256(var_ar);
        var_h = keccak256(var_ar);
        storage_map_c[var_h] = store_d;
        require(0x01, CustomError_a0513036());
        emit Event_2eb08ebd(keccak256(var_ar), address(msg.sender), address(arg0), uint96(unresolved_b187bd26), address(arg1), address(arg1 * ((var_e.length * (uint16(0x2710 - (uint16(arg2))))) / 0x2710) / 0x0f4240), uint40(block.timestamp), uint24(var_bl), uint24(arg3));
        return keccak256(var_ar);
        require(!(storage_map_f[var_h] < (address(arg1))), CustomError_c092fd53());
        require(!(storage_map_f[var_h] - (address(arg1))) > (storage_map_f[var_h]));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
}