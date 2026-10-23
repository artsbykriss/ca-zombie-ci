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
    uint256 public constant unresolved_dc4c90d3 = 419733649789348433379733432377375100525561064235;
    uint256 public constant unresolved_bc063e1a = 300;
    bool public constant unresolved_c4e833ce = 0xBool(true);
    
    address public unresolved_61d027b3;
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_f;
    bool public unresolved_b3133767;
    mapping(bytes32 => bytes32) storage_map_b;
    address public unresolved_e30c3978;
    mapping(bytes32 => bytes32) storage_map_i;
    bytes public unresolved_bd41293e;
    uint256 store_h;
    uint256 public unresolved_b3aa388c;
    
    event Event_dc86ea80();
    error CustomError_00000000();
    event Event_8be0079c();
    event Event_738c2f05();
    event Event_a8d6add1();
    event Event_18e568a1();
    event Event_cc7a80db();
    event Event_badb5f5c();
    event Event_3c864541();
    event Event_2aa00670();
    event Event_38d16b8c();
    event Event_3a0b35dc();
    event Event_9228efbc();
    event Event_5a8cf666();
    
    /// @custom:selector    0x9f063efc
    /// @custom:signature   Unresolved_9f063efc(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    function Unresolved_9f063efc(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0x8ebfc796
    /// @custom:signature   Unresolved_8ebfc796(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_8ebfc796(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        address var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        emit Event_5a8cf666(address(arg0), arg1);
    }
    
    /// @custom:selector    0xdc98354e
    /// @custom:signature   Unresolved_dc98354e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dc98354e(address arg0) public pure {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
    }
    
    /// @custom:selector    0x83f49d8c
    /// @custom:signature   Unresolved_83f49d8c(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_83f49d8c(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(bytes1(unresolved_b3133767)), CustomError_632f4992());
        require(address(arg0), CustomError_d92e233d());
        address var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        emit Event_3a0b35dc(address(arg0), arg1);
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public view
    function Unresolved_715018a6() public view {
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
    }
    
    /// @custom:selector    0x427745f9
    /// @custom:signature   Unresolved_427745f9(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_427745f9(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_f[var_b];
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
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0x62091a9d
    /// @custom:signature   Unresolved_62091a9d(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_62091a9d(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0x398daa85
    /// @custom:signature   Unresolved_398daa85(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_398daa85(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0xda46aeb4
    /// @custom:signature   Unresolved_da46aeb4(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_da46aeb4(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x625e15ae
    /// @custom:signature   Unresolved_625e15ae(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_625e15ae(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0x15f69012
    /// @custom:signature   Unresolved_15f69012(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_15f69012(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(bytes1(unresolved_b3133767)), CustomError_e8f318eb());
        require(!arg1, CustomError_e8f318eb());
        require(address(arg0), CustomError_e8f318eb());
        require(address(this) == (address(arg0)), CustomError_e8f318eb());
        require(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b, CustomError_e8f318eb());
        require(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b, CustomError_e8f318eb());
        require(!(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b), CustomError_e8f318eb());
        address var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        uint256 var_a = arg1;
        emit Event_dc86ea80(address(arg0), arg1);
        require(address(unresolved_61d027b3) == (address(arg0)), CustomError_e8f318eb());
        require(!(address(unresolved_61d027b3) == (address(arg0))), CustomError_e8f318eb());
        var_c = address(arg0);
        storage_map_b[var_c] = var_a | (uint248(storage_map_b[var_c]));
        emit Event_dc86ea80(address(arg0), arg1);
        if (address(this) == (address(arg0))) {
        }
        var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        emit Event_dc86ea80(address(arg0), arg1);
    }
    
    /// @custom:selector    0xd0fb2483
    /// @custom:signature   Unresolved_d0fb2483(uint256 arg0, uint256 arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_d0fb2483(uint256 arg0, uint256 arg1) public payable {
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!arg1, CustomError_561ce9bb());
        require(!(arg0 > arg1), CustomError_561ce9bb());
        unresolved_bd41293e = arg0;
        store_h = arg1;
        emit Event_2aa00670(arg0, arg1);
    }
    
    /// @custom:selector    0xd30af7ff
    /// @custom:signature   Unresolved_d30af7ff(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d30af7ff(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0x575e24b4
    /// @custom:signature   Unresolved_575e24b4(address arg0, address arg1, uint256 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    function Unresolved_575e24b4(address arg0, address arg1, uint256 arg2) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x60);
        require(!arg9 > 0xffffffffffffffff);
        require(!(arg9) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender);
        address var_a = address(arg0);
        require(!bytes1(storage_map_i[var_a]));
        return abi.encodePacked(0x575e24b400000000000000000000000000000000000000000000000000000000, 0, 0);
        require(!((0x24 + (msg.data.length - 0x24)) - 0x24) < 0xa0);
        require(!((var_f + 0xa0) < var_f) | ((var_f + 0xa0) > 0xffffffffffffffff));
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x4fdc4c20
    /// @custom:signature   Unresolved_4fdc4c20(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_4fdc4c20(uint256 arg0) public view returns (address) {
        uint256 var_b = arg0;
        return address(storage_map_f[var_b]);
    }
    
    /// @custom:selector    0xdef3c8ba
    /// @custom:signature   Unresolved_def3c8ba(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_def3c8ba(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_f[var_b];
    }
    
    /// @custom:selector    0xfec9f27d
    /// @custom:signature   Unresolved_fec9f27d(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_fec9f27d(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0xb47b2fb1
    /// @custom:signature   Unresolved_b47b2fb1(address arg0, address arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_b47b2fb1(address arg0, address arg1, uint256 arg2, uint256 arg3) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x60);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender);
        require(!((0x24 + (msg.data.length - 0x24)) - 0x24) < 0xa0);
        require(!((var_a + 0xa0) < var_a) | ((var_a + 0xa0) > 0xffffffffffffffff));
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        unresolved_e30c3978 = (address(arg0)) | (uint96(unresolved_e30c3978));
        emit Event_38d16b8c(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0xe744092e
    /// @custom:signature   Unresolved_e744092e(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e744092e(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0xb9f5adee
    /// @custom:signature   Unresolved_b9f5adee(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b9f5adee(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        address var_c = address(arg0);
        require(!storage_map_b[var_c], CustomError_aab0f695());
        var_c = address(arg0);
        require(!(!bytes1(storage_map_b[var_c])), CustomError_aab0f695());
        require(!(bytes1(storage_map_b[var_c])), CustomError_aab0f695());
        var_c = address(arg0);
        storage_map_b[var_c] = 0x01 | (uint248(storage_map_b[var_c]));
        emit Event_18e568a1(address(arg0), storage_map_b[var_c]);
        var_c = address(arg0);
        require(storage_map_b[var_c] > storage_map_b[var_c], CustomError_aab0f695());
        var_c = address(arg0);
        storage_map_b[var_c] = 0x01 | (uint248(storage_map_b[var_c]));
        emit Event_18e568a1(address(arg0), storage_map_b[var_c]);
        if (!storage_map_b[var_c]) {
        }
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public payable
    function Unresolved_79ba5097() public payable {
        require(msg.sender == (address(unresolved_e30c3978)), CustomError_118cdaa7());
        unresolved_e30c3978 = uint96(unresolved_e30c3978);
        unresolved_8da5cb5b = (address(msg.sender)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(msg.sender));
    }
    
    /// @custom:selector    0xf0f44260
    /// @custom:signature   Unresolved_f0f44260(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f0f44260(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_14bcf5c8());
        require(address(this) == (address(arg0)), CustomError_14bcf5c8());
        address var_c = address(arg0);
        require(bytes1(storage_map_b[var_c]), CustomError_14bcf5c8());
        require(bytes1(storage_map_b[var_c]), CustomError_14bcf5c8());
        require(!(bytes1(storage_map_b[var_c])), CustomError_14bcf5c8());
        unresolved_61d027b3 = (address(arg0)) | (uint96(unresolved_61d027b3));
        emit Event_3c864541(address(arg0));
        require(address(this) == (address(arg0)), CustomError_14bcf5c8());
        require(address(this) == (address(arg0)), CustomError_14bcf5c8());
        require(!(address(this) == (address(arg0))), CustomError_14bcf5c8());
        unresolved_61d027b3 = (address(arg0)) | (uint96(unresolved_61d027b3));
        emit Event_3c864541(address(arg0));
    }
    
    /// @custom:selector    0x88354047
    /// @custom:signature   Unresolved_88354047(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_88354047(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x6fe7e6eb
    /// @custom:signature   Unresolved_6fe7e6eb(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6fe7e6eb(address arg0) public pure {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
    }
    
    /// @custom:selector    0x259982e5
    /// @custom:signature   Unresolved_259982e5(address arg0, uint256 arg1) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_259982e5(address arg0, uint256 arg1) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0x357783ee
    /// @custom:signature   Unresolved_357783ee(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_357783ee(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(bytes1(unresolved_b3133767)), CustomError_e8f318eb());
        require(!arg1, CustomError_e8f318eb());
        require(address(this) == (address(arg0)), CustomError_e8f318eb());
        require(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b, CustomError_e8f318eb());
        require(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b, CustomError_e8f318eb());
        require(!(address(arg0) == 0x498581ff718922c3f8e6a244956af099b2652b2b), CustomError_e8f318eb());
        address var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        uint256 var_a = arg1;
        emit Event_cc7a80db(address(arg0), arg1);
        require(address(unresolved_61d027b3) == (address(arg0)), CustomError_e8f318eb());
        require(!(address(unresolved_61d027b3) == (address(arg0))), CustomError_e8f318eb());
        var_c = address(arg0);
        storage_map_b[var_c] = var_a | (uint248(storage_map_b[var_c]));
        emit Event_cc7a80db(address(arg0), arg1);
        if (address(this) == (address(arg0))) {
        }
        var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        emit Event_cc7a80db(address(arg0), arg1);
    }
    
    /// @custom:selector    0x408af472
    /// @custom:signature   Unresolved_408af472(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_408af472(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x16c74154
    /// @custom:signature   Unresolved_16c74154(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_16c74154(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        require(!storage_map_i[var_a]);
        var_a = address(arg0);
        require(bytes1(storage_map_i[var_a]));
        return !(bytes1(storage_map_i[var_a]));
        var_a = address(arg0);
        return !(!storage_map_i[var_a] > storage_map_i[var_a]);
        require(!storage_map_i[var_a]);
        var_a = address(arg0);
        return !(!storage_map_i[var_a] > storage_map_i[var_a]);
        return storage_map_i[var_a];
    }
    
    /// @custom:selector    0x1e1b9d8e
    /// @custom:signature   Unresolved_1e1b9d8e(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1e1b9d8e(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(0 - arg1, CustomError_3d9bdc4b());
        address var_c = address(arg0);
        require(!(bytes1(storage_map_b[var_c])), CustomError_3d9bdc4b());
        var_c = address(arg0);
        require(!storage_map_b[var_c], CustomError_c97f7e0e());
        var_c = address(arg0);
        storage_map_b[var_c] = arg1;
        emit Event_badb5f5c(address(arg0), arg1);
    }
    
    /// @custom:selector    0xeabb5622
    /// @custom:signature   Unresolved_eabb5622(uint24 arg0) public payable
    /// @param              arg0 ["uint24", "bytes3", "int24"]
    function Unresolved_eabb5622(uint24 arg0) public payable {
        require(arg0 == (uint24(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(uint24(arg0) > 0x012c), CustomError_71b0df8f());
        unresolved_61d027b3 = (uint24(arg0) * 0x010000000000000000000000000000000000000000) | (uint232(unresolved_61d027b3));
        emit Event_a8d6add1(uint24(arg0));
    }
    
    /// @custom:selector    0x7c21331b
    /// @custom:signature   Unresolved_7c21331b(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7c21331b(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x6c2bbe7e
    /// @custom:signature   Unresolved_6c2bbe7e(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    function Unresolved_6c2bbe7e(address arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0xa5a0d4c8
    /// @custom:signature   Unresolved_a5a0d4c8(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_a5a0d4c8(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(address(arg0), CustomError_d92e233d());
        address var_c = address(arg0);
        require(arg1 == (bytes1(storage_map_b[var_c])), CustomError_d92e233d());
        var_c = address(arg0);
        storage_map_b[var_c] = arg1 | (uint248(storage_map_b[var_c]));
        require(!arg1, CustomError_d92e233d());
        require(unresolved_b3aa388c + 0x01, CustomError_d92e233d());
        unresolved_b3aa388c = 0x01 + unresolved_b3aa388c;
        emit Event_738c2f05(address(arg0), arg1);
        require(unresolved_b3aa388c, CustomError_d92e233d());
        unresolved_b3aa388c = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + unresolved_b3aa388c;
        emit Event_738c2f05(address(arg0), arg1);
        emit Event_738c2f05(address(arg0), arg1);
    }
    
    /// @custom:selector    0x21d0ee70
    /// @custom:signature   Unresolved_21d0ee70(address arg0, uint256 arg1) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_21d0ee70(address arg0, uint256 arg1) public view {
        require(arg0 == (address(arg0)));
        require(!(msg.data.length - 0x24) < 0xa0);
        require(!(msg.data.length - 0xc4) < 0x80);
        require(!arg10 > 0xffffffffffffffff);
        require(!(arg10) > 0xffffffffffffffff);
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
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
        require(0x498581ff718922c3f8e6a244956af099b2652b2b == msg.sender, CustomError_0a85dc29());
    }
    
    /// @custom:selector    0xbc052756
    /// @custom:signature   Unresolved_bc052756(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_bc052756(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_f[var_b]));
    }
    
    /// @custom:selector    0x02eb7976
    /// @custom:signature   Unresolved_02eb7976() public payable
    function Unresolved_02eb7976() public payable {
        require(msg.sender == (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(bytes1(unresolved_b3133767)), CustomError_632f4992());
        unresolved_b3133767 = 0x01 | (uint248(unresolved_b3133767));
        emit Event_9228efbc();
    }
}