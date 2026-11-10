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
    
    address public unresolved_452a9320;
    address public unresolved_8da5cb5b;
    bytes32 store_d;
    bytes32 store_c;
    address public unresolved_e30c3978;
    mapping(bytes32 => bytes32) storage_map_i;
    address public unresolved_3fc8cef3;
    bytes32 store_g;
    uint256 public unresolved_b176ac57;
    mapping(bytes32 => bytes32) storage_map_j;
    
    error CustomError_00000000();
    event Event_62e78cea();
    event Event_a14fc14d();
    event Event_38d16b8c();
    event Event_5db9ee0a();
    event Event_8210728e();
    event Event_8be0079c();
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public
    function Unresolved_8456cb59() public {
        require(!(!(address(msg.sender)) == (address(unresolved_8da5cb5b))), CustomError_0fd901ef());
        require(!(!(address(msg.sender)) == (address(unresolved_452a9320))), CustomError_0fd901ef());
        require(!(bytes1(store_c)), CustomError_d93c0665());
        store_c = 0x01 | (uint248(store_c));
        emit Event_62e78cea(address(msg.sender));
    }
    
    /// @custom:selector    0x01e33667
    /// @custom:signature   Unresolved_01e33667(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_01e33667(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        return !(!bytes1(store_d));
    }
    
    /// @custom:selector    0xfb162e03
    /// @custom:signature   Unresolved_fb162e03(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_fb162e03(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public
    function Unresolved_79ba5097() public {
        require(address(unresolved_e30c3978) == msg.sender, CustomError_118cdaa7());
        unresolved_e30c3978 = uint96(unresolved_e30c3978);
        unresolved_8da5cb5b = (address(msg.sender)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(msg.sender));
    }
    
    /// @custom:selector    0xd6ac79ec
    /// @custom:signature   Unresolved_d6ac79ec() public
    function Unresolved_d6ac79ec() public {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(unresolved_3fc8cef3));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(unresolved_3fc8cef3).Unresolved_70a08231(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(!var_c.length);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        uint256 var_e = var_c.length;
        require(address(unresolved_3fc8cef3).code.length);
        (bool success, bytes memory ret0) = address(unresolved_3fc8cef3).Unresolved_2e1a7d4d(var_e); // call
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
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
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public
    function Unresolved_3f4ba83a() public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(bytes1(store_g), CustomError_8dfc202b());
        store_g = uint248(store_g);
        emit Event_5db9ee0a(address(msg.sender));
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
    
    /// @custom:selector    0xe63ea408
    /// @custom:signature   Unresolved_e63ea408(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e63ea408(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xf8b2cb4f
    /// @custom:signature   Unresolved_f8b2cb4f(address arg0) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f8b2cb4f(address arg0) public returns (uint256) {
        require(arg0 == (address(arg0)));
        require(!address(arg0));
        require(!address(unresolved_3fc8cef3));
        require(!(address(arg0)) == (address(unresolved_3fc8cef3)));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        return var_c.length;
        return address(this).balance;
        require(!address(unresolved_3fc8cef3));
        return address(this).balance;
    }
    
    /// @custom:selector    0x2bf80332
    /// @custom:signature   Unresolved_2bf80332(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2bf80332(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xbcbe2967
    /// @custom:signature   Unresolved_bcbe2967(address arg0, uint256 arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_bcbe2967(address arg0, uint256 arg1) public pure {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
    }
    
    /// @custom:selector    0xdcf8d38a
    /// @custom:signature   Unresolved_dcf8d38a(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dcf8d38a(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return !(!bytes1(storage_map_i[var_b]));
    }
    
    /// @custom:selector    0xf8d95313
    /// @custom:signature   Unresolved_f8d95313(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f8d95313(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_j[var_a]));
    }
    
    /// @custom:selector    0x4fd9b029
    /// @custom:signature   Unresolved_4fd9b029(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4fd9b029(address arg0) public view returns (address) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return address(storage_map_i[var_b]);
    }
    
    /// @custom:selector    0x1d765fa9
    /// @custom:signature   Unresolved_1d765fa9(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1d765fa9(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        address var_a = msg.sender;
        require(bytes1(storage_map_j[var_a]), CustomError_d93c0665());
        require(!(bytes1(store_d)), CustomError_d93c0665());
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(arg0));
        require(0 - arg1);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_38d52e0f(var_d); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), CustomError_73d390d3());
        require(var_e.length == (address(var_e.length)), CustomError_73d390d3());
        require(!(address(unresolved_3fc8cef3)), CustomError_73d390d3());
        require(!(!(address(unresolved_3fc8cef3)) == (address(var_e.length))), CustomError_73d390d3());
        require(!(arg1 > address(this).balance), CustomError_db42144d());
        var_g = address(unresolved_3fc8cef3);
        var_h = arg1;
        require(address(unresolved_3fc8cef3 / 0x01).code.length);
        (bool success, bytes memory ret0) = address(unresolved_3fc8cef3 / 0x01).{ value: var_h }Unresolved_d0e30db0(var_g); // call
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        address var_j = address(arg0);
        uint256 var_k = arg1;
        (bool success, bytes memory ret0) = address(unresolved_3fc8cef3).Unresolved_a9059cbb(var_j, var_k, var_l); // call
        require(success & (var_a == 0x01), CustomError_5274afe7());
        emit Event_8210728e(address(unresolved_3fc8cef3), address(arg0), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!bytes1(!success));
        var_e = var_e;
        require(success & ((!ret0.length) & (address(unresolved_3fc8cef3).code.length > 0)), CustomError_5274afe7());
        emit Event_8210728e(address(unresolved_3fc8cef3), address(arg0), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!(!address(unresolved_3fc8cef3)), CustomError_73d390d3());
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public view
    function Unresolved_715018a6() public view {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
    }
}