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
    uint256 public constant unresolved_9676a602 = 4;
    
    uint256 public unresolved_40d690a6;
    address public unresolved_452a9320;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    bytes32 store_m;
    mapping(bytes32 => bytes32) storage_map_j;
    address public unresolved_e30c3978;
    bytes32 store_a;
    address public unresolved_8da5cb5b;
    address public unresolved_aced1661;
    mapping(bytes32 => bytes32) storage_map_i;
    bytes32 store_f;
    mapping(bytes32 => bytes32) storage_map_l;
    uint256 storage_map_i[storage_map_g[var_c] - 0x01];
    
    error CustomError_00000000();
    event Event_62e78cea();
    event Event_a14fc14d();
    event Event_38d16b8c();
    event Event_5db9ee0a();
    event Event_068b48a2();
    event Event_8be0079c();
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        return !(!bytes1(store_a));
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public
    function Unresolved_79ba5097() public {
        require(address(unresolved_e30c3978) == msg.sender, CustomError_118cdaa7());
        unresolved_e30c3978 = uint96(unresolved_e30c3978);
        unresolved_8da5cb5b = (address(msg.sender)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(msg.sender));
    }
    
    /// @custom:selector    0x1c378573
    /// @custom:signature   Unresolved_1c378573(uint256 arg0, address arg1, uint256 arg2) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_1c378573(uint256 arg0, address arg1, uint256 arg2) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(msg.sender == (address(unresolved_aced1661)), CustomError_ccf79b67());
        require(!(bytes1(store_f)), CustomError_d93c0665());
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(0 - (arg0));
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        uint256 var_c = address(0 + (0x20 + (arg0)));
        require(storage_map_g[var_c], CustomError_1f2a2005());
        require(0 - (0x20 + (0 + (0x20 + (arg0)))), CustomError_1f2a2005());
        require(!(0 > (((0 + (0x20 + (arg0))) + 0x20) + 0)), CustomError_1f2a2005());
        require(!(0 > address(this).balance), CustomError_cf479181());
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        (bool success, bytes memory ret0) = address(0 + (0x20 + (arg0))).transfer(0x20 + (0 + (0x20 + (arg0))));
        require(ret0.length == 0);
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
    }
    
    /// @custom:selector    0xc6e6184a
    /// @custom:signature   Unresolved_c6e6184a(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_c6e6184a(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(arg1 == arg1);
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + ((0x04 + arg0) + 0x20)) + 0x20) - (0 + ((0x04 + arg0) + 0x20))) < 0x20);
        require((0 + (arg0 + 0x20)) == (address(0 + (arg0 + 0x20))));
        require(!(address(0 + (arg0 + 0x20))), CustomError_e6c4247b());
        require(!arg1, CustomError_e6c4247b());
        require(!(!address(0 + (arg0 + 0x20)).code.length), CustomError_e6c4247b());
        if (arg1) {
            uint256 var_c = address(0 + (arg0 + 0x20));
            if (storage_map_g[var_c]) {
                require(arg1, CustomError_e6c4247b());
            }
            unresolved_40d690a6 = 0x01 + unresolved_40d690a6;
            var_c = 0x01;
            storage_map_h[var_c] = address(0 + (arg0 + 0x20));
            var_c = address(0 + (arg0 + 0x20));
            storage_map_g[var_c] = unresolved_40d690a6;
            require(storage_map_g[var_c], CustomError_e6c4247b());
        }
        var_c = address(0 + (arg0 + 0x20));
        require(!storage_map_g[var_c], CustomError_e6c4247b());
        require(!((storage_map_g[var_c] - 0x01) > storage_map_g[var_c]), CustomError_e6c4247b());
        require(!((unresolved_40d690a6 - 0x01) > unresolved_40d690a6), CustomError_e6c4247b());
        require((storage_map_g[var_c] - 0x01) == (unresolved_40d690a6 - 0x01), CustomError_e6c4247b());
        require((unresolved_40d690a6 - 0x01) < unresolved_40d690a6, CustomError_e6c4247b());
        var_c = 0x01;
        require((storage_map_g[var_c] - 0x01) < unresolved_40d690a6, CustomError_e6c4247b());
        var_c = 0x01;
        storage_map_i[storage_map_g[var_c] - 0x01] = storage_map_j[var_c];
        var_c = storage_map_j[var_c];
        storage_map_g[var_c] = storage_map_g[var_c];
        require(unresolved_40d690a6, CustomError_e6c4247b());
        require(!(!address(0 + (arg0 + 0x20))), CustomError_e6c4247b());
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        unresolved_e30c3978 = (address(arg0)) | (uint96(unresolved_e30c3978));
        emit Event_38d16b8c(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0x8a0dac4a
    /// @custom:signature   Unresolved_8a0dac4a(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8a0dac4a(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_a6c1146b());
        require(!(address(arg0) == (address(unresolved_8da5cb5b))), CustomError_a6c1146b());
        emit Event_a14fc14d(address(unresolved_452a9320), address(arg0));
        unresolved_452a9320 = (address(arg0)) | (uint96(unresolved_452a9320));
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public
    function Unresolved_3f4ba83a() public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(bytes1(store_f), CustomError_8dfc202b());
        store_f = uint248(store_f);
        emit Event_5db9ee0a(address(msg.sender));
    }
    
    /// @custom:selector    0x73c4bdea
    /// @custom:signature   Unresolved_73c4bdea(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_73c4bdea(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_l[var_a];
    }
    
    /// @custom:selector    0x2bf80332
    /// @custom:signature   Unresolved_2bf80332(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2bf80332(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x73fe4ad8
    /// @custom:signature   Unresolved_73fe4ad8(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_73fe4ad8(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xf34d8c46
    /// @custom:signature   Unresolved_f34d8c46() public view returns (bytes memory)
    function Unresolved_f34d8c46() public view returns (bytes memory) {
        uint256 var_a = var_a + (0x20 + (0x20 * unresolved_40d690a6));
        if (!unresolved_40d690a6) {
            var_c = 0x01;
            if ((0x20 + var_a) + (0x20 * unresolved_40d690a6) > (0x20 + (0x20 + var_a))) {
                return abi.encodePacked(0x20, var_a.length);
            }
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public
    function Unresolved_8456cb59() public {
        require(!(!(address(msg.sender)) == (address(unresolved_8da5cb5b))), CustomError_0fd901ef());
        require(!(!(address(msg.sender)) == (address(unresolved_452a9320))), CustomError_0fd901ef());
        require(!(bytes1(store_m)), CustomError_d93c0665());
        store_m = 0x01 | (uint248(store_m));
        emit Event_62e78cea(address(msg.sender));
    }
    
    /// @custom:selector    0x748747e6
    /// @custom:signature   Unresolved_748747e6(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_748747e6(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(address(arg0), CustomError_e6c4247b());
        unresolved_aced1661 = (address(arg0)) | (uint96(unresolved_aced1661));
        emit Event_068b48a2(address(unresolved_aced1661), address(arg0));
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public view
    function Unresolved_715018a6() public view {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
    }
}