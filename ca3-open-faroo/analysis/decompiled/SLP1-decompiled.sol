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
    uint256 public constant unresolved_7a997ab7 = 99711885265833003116899082224403523972572152566696767984750437965401541207904;
    uint256 public constant unresolved_97610f30 = 371084400103549569075154352056868735459514122240;
    uint256 public constant unresolved_a217fddf = 0;
    
    uint256 public unresolved_6f83f6a2;
    mapping(bytes32 => bytes32) storage_map_w;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_d;
    address public unresolved_e23ddec5;
    uint256 storage_map_n[storage_map_d[var_b] - 0x01];
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_g;
    uint256 storage_map_i[storage_map_a[var_a] - 0x01];
    bytes32 store_m;
    mapping(bytes32 => bytes32) storage_map_s;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_j;
    mapping(bytes32 => bytes32) storage_map_r;
    uint256 public unresolved_7578b296;
    mapping(bytes32 => bytes32) storage_map_k;
    bytes32 store_c;
    address public unresolved_fca2b359;
    mapping(bytes32 => bytes32) storage_map_i;
    uint256 public unresolved_44d96e95;
    uint256 public unresolved_c296527a;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_l;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_o;
    
    event Event_6ce733e7();
    event Event_3e32cabb();
    event Event_f6391f5c();
    error CustomError_00000000();
    event Event_2f878811();
    event Event_fa773061();
    event Event_fdd3770b();
    event Event_43d57162();
    event Event_9b01158d();
    event Event_1745f6cb();
    event Event_9548b764();
    event Event_dfe866d7();
    
    /// @custom:selector    0x44ddc961
    /// @custom:signature   Unresolved_44ddc961(uint256 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_44ddc961(uint256 arg0) public view returns (bool) {
        uint256 var_a = arg0;
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x42853aac
    /// @custom:signature   Unresolved_42853aac(address arg0, uint256 arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_42853aac(address arg0, uint256 arg1) public pure {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(!((var_c + (uint248((arg1 << 0x05) + 0x3f))) > 0xffffffffffffffff) | ((var_c + (uint248((arg1 << 0x05) + 0x3f))) < var_c));
        require(!((0x04 + arg1) + 0x20) < (0x20 + ((0x04 + arg1) + (arg1 << 0x05))));
        require((arg1 + 0x20) == (address(arg1 + 0x20)));
    }
    
    /// @custom:selector    0x2fd1c2cd
    /// @custom:signature   Unresolved_2fd1c2cd(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_2fd1c2cd(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        var_b = arg0;
        require(storage_map_d[var_b]);
        uint256 var_d = arg0;
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_9b0dc6ce(var_d); // call
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x40);
        require(!unresolved_7578b296 > (var_e.length + unresolved_7578b296));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        unresolved_7578b296 = var_e.length + unresolved_7578b296;
        emit Event_fdd3770b(msg.sender, arg0, var_h, var_e.length);
        store_c = 0x01;
    }
    
    /// @custom:selector    0xca15c873
    /// @custom:signature   Unresolved_ca15c873(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_ca15c873(uint256 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0xebcb0b7a
    /// @custom:signature   Unresolved_ebcb0b7a(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ebcb0b7a(address arg0) public {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e6c4247b());
        require(address(arg0), CustomError_e6c4247b());
        unresolved_fca2b359 = (address(arg0)) | (uint96(unresolved_fca2b359));
        emit Event_3e32cabb(msg.sender, address(arg0));
    }
    
    /// @custom:selector    0x51f93215
    /// @custom:signature   Unresolved_51f93215(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_51f93215(uint256 arg0, uint256 arg1) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]), CustomError_69949e58());
        var_b = arg0;
        require(storage_map_d[var_b], CustomError_69949e58());
        require(!(arg1 > address(this).balance), CustomError_69949e58());
        uint256 var_d = arg0;
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: arg1 }Unresolved_c3254c23(var_d); // call
        require(!(unresolved_44d96e95 > (arg1 + unresolved_44d96e95)), CustomError_9a570671());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        unresolved_44d96e95 = arg1 + unresolved_44d96e95;
        emit Event_9548b764(msg.sender, arg0, arg1);
        store_c = 0x01;
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   Unresolved_91d14854(uint256 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_91d14854(uint256 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   Unresolved_d547741f(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d547741f(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = uint248(storage_map_a[var_a]);
        emit Event_f6391f5c(arg0, address(arg1), msg.sender);
        require(!0x01, CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        require(!storage_map_a[var_a], CustomError_e2517d3f());
        require(!((storage_map_a[var_a] - 0x01) > storage_map_a[var_a]), CustomError_e2517d3f());
        require(!((storage_map_a[var_a] - 0x01) > storage_map_a[var_a]), CustomError_e2517d3f());
        require((storage_map_a[var_a] - 0x01) == (storage_map_a[var_a] - 0x01), CustomError_e2517d3f());
        require((storage_map_a[var_a] - 0x01) < (storage_map_h[var_a]), CustomError_e2517d3f());
        var_a = 0 + keccak256(var_a);
        require((storage_map_a[var_a] - 0x01) < (storage_map_h[var_a]), CustomError_e2517d3f());
        var_a = 0 + keccak256(var_a);
        storage_map_i[storage_map_a[var_a] - 0x01] = storage_map_j[var_a];
        var_a = storage_map_k[var_a];
        storage_map_a[var_a] = storage_map_a[var_a];
        require(storage_map_a[var_a], CustomError_e2517d3f());
        var_a = keccak256(var_a);
        storage_map_k[var_a] = 0;
        storage_map_a[var_a] = storage_map_a[var_a] - 0x01;
        var_a = address(arg1);
        storage_map_a[var_a] = 0;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0, CustomError_e2517d3f());
    }
    
    /// @custom:selector    0xa3246ad3
    /// @custom:signature   Unresolved_a3246ad3(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_a3246ad3(uint256 arg0) public view returns (bytes memory) {
        var_a = var_a;
        uint256 var_c = var_c + (0x20 + (0x20 * (storage_map_h[var_a])));
        require(!storage_map_h[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_h[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0x73512734
    /// @custom:signature   Unresolved_73512734(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_73512734(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        var_b = arg0;
        require(storage_map_d[var_b]);
        uint256 var_d = arg0;
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_73512734(var_d); // call
        store_c = 0x01;
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   Unresolved_2f2ff15d(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2f2ff15d(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        require(!0, CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        require(storage_map_a[var_a], CustomError_e2517d3f());
        storage_map_a[var_a] = 0x01 + storage_map_a[var_a];
        var_a = keccak256(var_a);
        storage_map_l[var_a] = address(arg1);
        var_a = address(arg1);
        storage_map_a[var_a] = storage_map_a[var_a];
        var_a = arg0;
        var_a = address(arg1);
        storage_map_a[var_a] = 0x01 | (uint248(storage_map_a[var_a]));
        emit Event_2f878811(arg0, address(arg1), address(msg.sender));
        require(!0x01, CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        require(storage_map_a[var_a], CustomError_e2517d3f());
        storage_map_a[var_a] = 0x01 + storage_map_a[var_a];
        var_a = keccak256(var_a);
        storage_map_l[var_a] = address(arg1);
        var_a = address(arg1);
        storage_map_a[var_a] = storage_map_a[var_a];
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   Unresolved_01ffc9a7(uint32 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_01ffc9a7(uint32 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x5a05180f00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x5a05180f00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!(uint32(arg0)) == 0x01ffc9a700000000000000000000000000000000000000000000000000000000);
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   Unresolved_248a9ca3(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_248a9ca3(uint256 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_g[var_a];
    }
    
    /// @custom:selector    0x62ed5f4e
    /// @custom:signature   Unresolved_62ed5f4e(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_62ed5f4e(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        var_b = arg0;
        require(storage_map_d[var_b]);
        uint256 var_d = arg0;
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_62ed5f4e(var_d); // call
        store_c = 0x01;
    }
    
    /// @custom:selector    0xaf44956e
    /// @custom:signature   Unresolved_af44956e(uint256 arg0, uint256 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_af44956e(uint256 arg0, uint256 arg1) public pure {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!arg1 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x677b7fa3
    /// @custom:signature   Unresolved_677b7fa3(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_677b7fa3(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]), CustomError_9a570671());
        var_b = arg0;
        require(!storage_map_d[var_b], CustomError_9a570671());
        require(!((storage_map_d[var_b] - 0x01) > storage_map_d[var_b]), CustomError_9a570671());
        require(!((store_m - 0x01) > store_m), CustomError_9a570671());
        require((storage_map_d[var_b] - 0x01) == (store_m - 0x01), CustomError_9a570671());
        require((store_m - 0x01) < store_m, CustomError_9a570671());
        var_b = 0xa0268512d1ad72d0bd2136fed798eeda2422eb8b727c15d33589fbbf5c9a8d00;
        require((storage_map_d[var_b] - 0x01) < store_m, CustomError_9a570671());
        var_b = 0xa0268512d1ad72d0bd2136fed798eeda2422eb8b727c15d33589fbbf5c9a8d00;
        storage_map_n[storage_map_d[var_b] - 0x01] = storage_map_o[var_b];
        var_b = storage_map_o[var_b];
        storage_map_d[var_b] = storage_map_d[var_b];
        require(store_m, CustomError_9a570671());
        var_b = 0xa0268512d1ad72d0bd2136fed798eeda2422eb8b727c15d33589fbbf5c9a8d00;
        storage_map_o[var_b] = 0;
        store_m = store_m - 0x01;
        var_b = arg0;
        storage_map_d[var_b] = 0;
        require(0x01, CustomError_9a570671());
        emit Event_fa773061(msg.sender, arg0);
        store_c = 0x01;
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0, CustomError_9a570671());
        emit Event_fa773061(msg.sender, arg0);
        store_c = 0x01;
    }
    
    /// @custom:selector    0x784f707b
    /// @custom:signature   Unresolved_784f707b(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_784f707b(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        require(!0 < (arg0));
        require(0 < (arg0));
        var_b = (0 + (arg0 + 0x20));
        require(storage_map_d[var_b]);
        require(0 < (arg0));
        uint256 var_d = (0 + (arg0 + 0x20));
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).Unresolved_2cc0b49c(var_d); // staticcall
        uint256 var_f = var_f + (uint248(ret0.length + 0x1f));
        require(!((var_f + ret0.length) - var_f) < 0x20);
        require(!var_f.length);
        require(0 < (arg0));
        var_e = (0 + (arg0 + 0x20));
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_f5414023(var_e); // call
        var_f = var_f + (uint248(ret0.length + 0x1f));
        require(!((var_f + ret0.length) - var_f) < 0x20);
        require(!0 > (var_f.length + 0));
        require(0 < (arg0));
        require(!(unresolved_6f83f6a2 > (0 + unresolved_6f83f6a2)), CustomError_e2517d3f());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        unresolved_6f83f6a2 = 0 + unresolved_6f83f6a2;
        store_c = 0x01;
    }
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   Unresolved_36568abe(uint256 arg0, address arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_36568abe(uint256 arg0, address arg1) public {
        require(arg1 == (address(arg1)));
        require(msg.sender == (address(arg1)), CustomError_6697b232());
        var_b = var_b;
        var_b = address(arg1);
        require(!bytes1(storage_map_d[var_b]));
        var_b = arg0;
        var_b = address(arg1);
        storage_map_d[var_b] = uint248(storage_map_d[var_b]);
        emit Event_f6391f5c(arg0, address(arg1), msg.sender);
        require(!0x01);
        var_b = arg0;
        var_b = address(arg1);
        require(!storage_map_d[var_b]);
        require(!(storage_map_d[var_b] - 0x01) > storage_map_d[var_b]);
        require(!(storage_map_d[var_b] - 0x01) > storage_map_d[var_b]);
        require((storage_map_d[var_b] - 0x01) == (storage_map_d[var_b] - 0x01));
        require((storage_map_d[var_b] - 0x01) < (storage_map_q[var_b]));
        var_b = 0 + keccak256(var_b);
        require((storage_map_d[var_b] - 0x01) < (storage_map_q[var_b]));
        var_b = 0 + keccak256(var_b);
        storage_map_n[storage_map_d[var_b] - 0x01] = storage_map_r[var_b];
        var_b = storage_map_s[var_b];
        storage_map_d[var_b] = storage_map_d[var_b];
        require(storage_map_d[var_b]);
        var_b = keccak256(var_b);
        storage_map_s[var_b] = 0;
        storage_map_d[var_b] = storage_map_d[var_b] - 0x01;
        var_b = address(arg1);
        storage_map_d[var_b] = 0;
        require(!0);
    }
    
    /// @custom:selector    0x30bc5d2c
    /// @custom:signature   Unresolved_30bc5d2c(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_30bc5d2c(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]), CustomError_f4d678b8());
        require(!(arg0 > address(this).balance), CustomError_f4d678b8());
        require(!(unresolved_c296527a > (arg0 + unresolved_c296527a)), CustomError_cf479181());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        unresolved_c296527a = arg0 + unresolved_c296527a;
        require(!(address(this).balance < arg0), CustomError_cf479181());
        (bool success, bytes memory ret0) = address(unresolved_e23ddec5).transfer(arg0);
        require(ret0.length == 0);
        require(!var_g);
        emit Event_1745f6cb(msg.sender, arg0);
        store_c = 0x01;
        uint256 var_h = var_h + (uint248(ret0.length + 0x3f));
        require(!var_h.length, CustomError_d6bda275());
        emit Event_1745f6cb(msg.sender, arg0);
        store_c = 0x01;
    }
    
    /// @custom:selector    0xeae7236f
    /// @custom:signature   Unresolved_eae7236f(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_eae7236f(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]), CustomError_f4d678b8());
        require(!(arg0 > address(this).balance), CustomError_f4d678b8());
        require(!(address(this).balance < arg0), CustomError_cf479181());
        (bool success, bytes memory ret0) = address(unresolved_fca2b359).transfer(arg0);
        require(ret0.length == 0);
        require(!var_f);
        emit Event_43d57162(msg.sender, arg0);
        store_c = 0x01;
        uint256 var_g = var_g + (uint248(ret0.length + 0x3f));
        require(!var_g.length, CustomError_d6bda275());
        emit Event_43d57162(msg.sender, arg0);
        store_c = 0x01;
    }
    
    /// @custom:selector    0xbd66528a
    /// @custom:signature   Unresolved_bd66528a(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_bd66528a(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        var_b = arg0;
        require(storage_map_d[var_b]);
        uint256 var_d = arg0;
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_4007c5ad(var_d); // call
        require(!(address(this).balance - address(this).balance > address(this).balance), CustomError_9a570671());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        emit Event_9b01158d(address(msg.sender), arg0, address(this).balance - address(this).balance);
        store_c = 0x01;
    }
    
    /// @custom:selector    0xf5414023
    /// @custom:signature   Unresolved_f5414023(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_f5414023(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        var_b = arg0;
        require(storage_map_d[var_b]);
        uint256 var_d = arg0;
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_f5414023(var_d); // call
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(!unresolved_6f83f6a2 > (var_e.length + unresolved_6f83f6a2));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        unresolved_6f83f6a2 = var_e.length + unresolved_6f83f6a2;
        emit Event_dfe866d7(msg.sender, arg0, var_e.length);
        store_c = 0x01;
    }
    
    /// @custom:selector    0x8ae22ac4
    /// @custom:signature   Unresolved_8ae22ac4(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_8ae22ac4(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        require(!0 < (arg0));
        require(0 < (arg0));
        var_b = (0 + (arg0 + 0x20));
        require(storage_map_d[var_b]);
        require(0 < (arg0));
        uint256 var_d = (0 + (arg0 + 0x20));
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_73512734(var_d); // call
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        store_c = 0x01;
    }
    
    /// @custom:selector    0xf5b8f3dc
    /// @custom:signature   Unresolved_f5b8f3dc(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_f5b8f3dc(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        require(!0 < (arg0));
        require(0 < (arg0));
        var_b = (0 + (arg0 + 0x20));
        require(storage_map_d[var_b]);
        require(0 < (arg0));
        uint256 var_d = (0 + (arg0 + 0x20));
        require(address(0x4100000000000000000000000000000000000000).code.length);
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_4007c5ad(var_d); // call
        require(!(address(this).balance - address(this).balance > address(this).balance), CustomError_9a570671());
        require(0 < (arg0), CustomError_9a570671());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        store_c = 0x01;
    }
    
    /// @custom:selector    0x9010d07c
    /// @custom:signature   Unresolved_9010d07c(uint256 arg0, uint256 arg1) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_9010d07c(uint256 arg0, uint256 arg1) public view returns (address) {
        var_a = var_a;
        require(arg1 < (storage_map_h[var_a]));
        var_a = 0 + keccak256(var_a);
        return address(storage_map_v[var_a]);
    }
    
    /// @custom:selector    0x63410dca
    /// @custom:signature   Unresolved_63410dca(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_63410dca(uint256 arg0) public {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]), CustomError_0ac1851a());
        var_b = arg0;
        require(storage_map_d[var_b], CustomError_0ac1851a());
        require(0, CustomError_0ac1851a());
        emit Event_6ce733e7(msg.sender, arg0);
        store_c = 0x01;
        store_m = store_c + store_m;
        var_b = 0xa0268512d1ad72d0bd2136fed798eeda2422eb8b727c15d33589fbbf5c9a8d00;
        storage_map_w[var_b] = arg0;
        var_b = arg0;
        storage_map_d[var_b] = store_m;
        require(0x01, CustomError_0ac1851a());
        emit Event_6ce733e7(msg.sender, arg0);
        store_c = 0x01;
    }
    
    /// @custom:selector    0x0acace0a
    /// @custom:signature   Unresolved_0acace0a(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_0acace0a(uint256 arg0, uint256 arg1) public {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_c, CustomError_3ee5aeb5());
        store_c = 0x02;
        var_b = var_b;
        address var_b = address(msg.sender);
        require(bytes1(storage_map_d[var_b]));
        require(!0 < (arg0));
        require(0 < (arg0));
        var_b = (0 + (arg0 + 0x20));
        require(storage_map_d[var_b]);
        require(0 < (arg0));
        uint256 var_d = (0 + (arg0 + 0x20));
        (bool success, bytes memory ret0) = address(0x4100000000000000000000000000000000000000).{ value: 0 ether }Unresolved_9b0dc6ce(var_d); // call
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x40);
        require(!0 > (var_e.length + 0));
        require(0 < (arg0));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x063eb469
    /// @custom:signature   Unresolved_063eb469() public view returns (bytes memory)
    function Unresolved_063eb469() public view returns (bytes memory) {
        uint256 var_a = var_a + (0x20 + (0x20 * store_m));
        if (!store_m) {
            var_c = 0xa0268512d1ad72d0bd2136fed798eeda2422eb8b727c15d33589fbbf5c9a8d00;
            if ((0x20 + var_a) + (0x20 * store_m) > (0x20 + (0x20 + var_a))) {
                return abi.encodePacked(0x20, var_a.length);
            }
        }
    }
}