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
    uint256 public constant unresolved_996b2c2e = 86400;
    uint256 public constant unresolved_a2a9b1ae = 2592000;
    uint256 public constant unresolved_9676a602 = 4;
    
    address public unresolved_452a9320;
    address public unresolved_8da5cb5b;
    bytes32 store_r;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_a;
    mapping(bytes32 => bytes32) storage_map_k;
    address public unresolved_ac03e9f0;
    mapping(bytes32 => bytes32) storage_map_b;
    address public unresolved_7dc0d1d0;
    uint256 public unresolved_996e5c06;
    uint256 store_g;
    mapping(bytes32 => bytes32) storage_map_x;
    bytes32 store_h;
    bytes32 store_s;
    uint256 public unresolved_12b58349;
    mapping(bytes32 => bytes32) storage_map_n;
    bytes32 store_ae;
    address public unresolved_02824acc;
    address public unresolved_e30c3978;
    bool public unresolved_313ce567;
    mapping(bytes32 => bytes32) storage_map_z;
    bytes32 store_ac;
    uint256 public unresolved_6cf6d675;
    mapping(bytes32 => bytes32) storage_map_t;
    mapping(bytes32 => bytes32) storage_map_aa;
    mapping(bytes32 => bytes32) storage_map_y;
    mapping(bytes32 => bytes32) storage_map_m;
    uint256 public unresolved_dc692cd7;
    mapping(bytes32 => bytes32) storage_map_l;
    uint256 public unresolved_7c815a5a;
    
    error CustomError_00000000();
    event Event_a14fc14d();
    event Event_6b7aec09();
    event Event_dcbc1c05();
    event Event_5db9ee0a();
    event Event_1b00dbfa();
    event Event_8c5be1e5();
    event Event_85d75176();
    event Event_5184366d();
    event Event_44ffe61d();
    event Event_ddf252ad();
    event Event_62e78cea();
    event Event_38d16b8c();
    event Event_8be0079c();
    
    /// @custom:selector    0x18160ddd
    /// @custom:signature   Unresolved_18160ddd() public view returns (uint256)
    function Unresolved_18160ddd() public view returns (uint256) {
        return store_a;
    }
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   Unresolved_095ea7b3(address arg0, uint256 arg1) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_095ea7b3(address arg0, uint256 arg1) public returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_94280d62());
        require(address(arg0), CustomError_94280d62());
        address var_a = address(msg.sender);
        var_a = address(arg0);
        storage_map_b[var_a] = arg1;
        require(!0x01, CustomError_94280d62());
        return 0x01;
        emit Event_8c5be1e5(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x55221bd3
    /// @custom:signature   Unresolved_55221bd3(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_55221bd3(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x0a28a477
    /// @custom:signature   Unresolved_0a28a477(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_0a28a477(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0x01 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_98a90900(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0xadeb0ed8
    /// @custom:signature   Unresolved_adeb0ed8(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_adeb0ed8(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(!(bytes1(store_a)), CustomError_d93c0665());
        require(msg.sender == (address(unresolved_7dc0d1d0)), CustomError_df4f8240());
        require(address(arg0), CustomError_e450d38c());
        require(0 - arg1, CustomError_e450d38c());
        require(address(arg0), CustomError_e450d38c());
        require(0, CustomError_e450d38c());
        uint256 var_a = 0;
        require(!(storage_map_b[var_a] < arg1), CustomError_e450d38c());
        uint256 var_f = arg1;
        var_a = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - arg1;
        require(address(arg0), CustomError_ec442f05());
        var_a = address(arg0);
        storage_map_b[var_a] = var_f + storage_map_b[var_a];
        emit Event_ddf252ad(0, address(arg0), arg1);
        emit Event_85d75176(msg.sender, address(arg0), arg1);
        store_g = (store_g) - arg1;
        emit Event_ddf252ad(0, address(arg0), arg1);
        emit Event_85d75176(msg.sender, address(arg0), arg1);
        require(!(store_h > (arg1 + (store_h))), CustomError_ec442f05());
    }
    
    /// @custom:selector    0x52a630b9
    /// @custom:signature   Unresolved_52a630b9(address arg0) public returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_52a630b9(address arg0) public returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(!var_c.length > (unresolved_12b58349 + var_c.length));
        address var_d = address(arg0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        require(!0);
        require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_j[var_d] - storage_map_j[var_d]) < 0);
        var_d = storage_map_j[var_d];
        var_c = var_c + 0xa0;
        require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
        return abi.encodePacked(0, 0, 0);
        require(!(unresolved_12b58349 + var_c.length) > var_c.length);
        return abi.encodePacked(0, 0, 0);
        require(!((unresolved_12b58349 + var_c.length) - var_c.length) > (unresolved_12b58349 + var_c.length));
        require(!((unresolved_12b58349 + var_c.length) - var_c.length) < (var_o));
        require(!0 > (((unresolved_12b58349 + var_c.length) - var_c.length) + 0));
        return abi.encodePacked(((unresolved_12b58349 + var_c.length) - var_c.length) + 0, 0, (unresolved_12b58349 + var_c.length) - var_c.length);
        return abi.encodePacked(0, 0, 0);
        require(0);
        return abi.encodePacked(0, 0, 0);
        var_d = address(arg0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        require(!0);
        require(0);
        return abi.encodePacked(0, 0, 0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        return abi.encodePacked(0, 0, 0);
    }
    
    /// @custom:selector    0x240f5579
    /// @custom:signature   Unresolved_240f5579(address arg0, uint256 arg1) public returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_240f5579(address arg0, uint256 arg1) public returns (bytes memory) {
        require(arg0 == (address(arg0)));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(!var_c.length > (unresolved_12b58349 + var_c.length));
        address var_d = address(arg0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        require(!arg1);
        require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_j[var_d] - storage_map_j[var_d]) < arg1);
        var_d = storage_map_j[var_d];
        var_c = var_c + 0xa0;
        require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
        return abi.encodePacked(0, 0, 0);
        require(!(unresolved_12b58349 + var_c.length) > var_c.length);
        return abi.encodePacked(0, 0, 0);
        require(!((unresolved_12b58349 + var_c.length) - var_c.length) > (unresolved_12b58349 + var_c.length));
        require(!((unresolved_12b58349 + var_c.length) - var_c.length) < (var_o));
        require(!0 > (((unresolved_12b58349 + var_c.length) - var_c.length) + 0));
        return abi.encodePacked(((unresolved_12b58349 + var_c.length) - var_c.length) + 0, 0, (unresolved_12b58349 + var_c.length) - var_c.length);
        return abi.encodePacked(0, 0, 0);
        require(arg1);
        return abi.encodePacked(0, 0, 0);
        var_d = address(arg0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        require(!arg1);
        require(arg1);
        return abi.encodePacked(0, 0, 0);
        require(!storage_map_j[var_d] < storage_map_j[var_d]);
        return abi.encodePacked(0, 0, 0);
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   Unresolved_01ffc9a7(uint32 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_01ffc9a7(uint32 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x87dfe5a000000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x87dfe5a000000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x87dfe5a000000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!(uint32(arg0)) == 0x01ffc9a700000000000000000000000000000000000000000000000000000000);
    }
    
    /// @custom:selector    0xd905777e
    /// @custom:signature   Unresolved_d905777e(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d905777e(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xc1e2f5a4
    /// @custom:signature   Unresolved_c1e2f5a4(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c1e2f5a4(uint256 arg0) public returns (uint256) {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!arg0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < arg0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!arg0) {
                if (arg0) {
                }
                require(!arg0, CustomError_8ee13f80());
            }
        }
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xb460af94
    /// @custom:signature   Unresolved_b460af94(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b460af94(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x07a2d13a
    /// @custom:signature   Unresolved_07a2d13a(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_07a2d13a(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   Unresolved_06fdde03() public view returns (string memory)
    function Unresolved_06fdde03() public view returns (string memory) {
        if (store_r) {
            if (store_r - ((store_r >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_r >> 0x01)) / 0x20) * 0x20));
                if (store_r) {
                    if (store_r - ((store_r >> 0x01) < 0x20)) {
                        if (!store_r >> 0x01) {
                            if (0x1f < (store_r >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace03;
                                if ((0x20 + var_c) + (store_r >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   Unresolved_95d89b41() public view returns (string memory)
    function Unresolved_95d89b41() public view returns (string memory) {
        if (store_s) {
            if (store_s - ((store_s >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_s >> 0x01)) / 0x20) * 0x20));
                if (store_s) {
                    if (store_s - ((store_s >> 0x01) < 0x20)) {
                        if (!store_s >> 0x01) {
                            if (0x1f < (store_s >> 0x01)) {
                                var_a = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace04;
                                if ((0x20 + var_c) + (store_s >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x402d267d
    /// @custom:signature   Unresolved_402d267d(address arg0) public pure returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_402d267d(address arg0) public pure returns (uint256) {
        require(arg0 == (address(arg0)));
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }
    
    /// @custom:selector    0xef8b30f7
    /// @custom:signature   Unresolved_ef8b30f7(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_ef8b30f7(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_98a90900(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0x62e78eff
    /// @custom:signature   Unresolved_62e78eff(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_62e78eff(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_t[var_b];
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public
    function Unresolved_79ba5097() public {
        require(address(unresolved_e30c3978) == msg.sender, CustomError_118cdaa7());
        unresolved_e30c3978 = uint96(unresolved_e30c3978);
        unresolved_8da5cb5b = (address(msg.sender)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(msg.sender));
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x7018b08e
    /// @custom:signature   Unresolved_7018b08e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7018b08e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   Unresolved_70a08231(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_70a08231(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xcbdb463a
    /// @custom:signature   Unresolved_cbdb463a(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cbdb463a(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_t[var_b];
    }
    
    /// @custom:selector    0x94bf804d
    /// @custom:signature   Unresolved_94bf804d(uint256 arg0, address arg1) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_94bf804d(uint256 arg0, address arg1) public returns (uint256) {
        require(arg1 == (address(arg1)));
        require(!(bytes1(store_a)), CustomError_d93c0665());
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_c = address(unresolved_313ce567);
        require(0x01 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_c); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!(((var_g + ret0.length) - var_g) < 0x20), CustomError_5274afe7());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        address var_h = address(this);
        (bool success, bytes memory ret0) = address(unresolved_313ce567).Unresolved_23b872dd(var_e, var_h); // call
        require(success & (var_a == 0x01), CustomError_5274afe7());
        var_g = var_g;
        require(address(arg1), CustomError_e450d38c());
        require(0, CustomError_e450d38c());
        uint256 var_a = 0;
        require(!(storage_map_b[var_a] < arg0), CustomError_e450d38c());
        uint256 var_m = arg0;
        var_a = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - arg0;
        require(address(arg1));
        var_a = address(arg1);
        storage_map_b[var_a] = var_m + storage_map_b[var_a];
        emit Event_ddf252ad(0, address(arg1), arg0);
        var_d = address(unresolved_313ce567);
        var_f = var_g.length;
        require(address(unresolved_7dc0d1d0).code.length);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_4166dfa6(var_d); // call
        require(address(unresolved_02824acc), CustomError_90b8ec18());
        require(!0x01, CustomError_90b8ec18());
        (bool success, bytes memory ret0) = address(unresolved_02824acc).transfer(var_g.length);
        require(ret0.length == 0, CustomError_90b8ec18());
        emit Event_dcbc1c05(address(msg.sender), address(arg1), var_g.length, arg0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return var_g.length;
        var_d = var_g.length;
        require(address(unresolved_313ce567).code.length);
        (bool success, bytes memory ret0) = address(unresolved_313ce567).Unresolved_2e1a7d4d(var_d, var_f); // call
        require(!(store_h > (arg0 + (store_h))), CustomError_ec442f05());
        require(!bytes1(!success));
        require(success & ((!ret0.length) & (address(unresolved_313ce567).code.length > 0)), CustomError_5274afe7());
    }
    
    /// @custom:selector    0x114eaf55
    /// @custom:signature   Unresolved_114eaf55(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_114eaf55(uint256 arg0) public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(!(arg0 < 0x015180), CustomError_d5136d18());
        require(!(arg0 > 0x278d00), CustomError_d5136d18());
        unresolved_6cf6d675 = arg0;
        emit Event_6b7aec09(unresolved_6cf6d675, arg0);
    }
    
    /// @custom:selector    0xa4622df7
    /// @custom:signature   Unresolved_a4622df7(address arg0) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a4622df7(address arg0) public returns (uint256) {
        require(arg0 == (address(arg0)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(arg0));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < 0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!0) {
                if (0) {
                }
                require(!0, CustomError_8ee13f80());
            }
        }
    }
    
    /// @custom:selector    0x3a2b643a
    /// @custom:signature   Unresolved_3a2b643a(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3a2b643a(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        require(!(storage_map_b[var_a] - storage_map_b[var_a]) > storage_map_b[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_b[var_a] - storage_map_b[var_a]) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!storage_map_b[var_a] - storage_map_b[var_a]);
        var_e = 0xa0 + var_e;
        uint256 var_i = 0;
        require(storage_map_b[var_a] - storage_map_b[var_a] - 0x01);
        require(!0 < (storage_map_b[var_a] - storage_map_b[var_a]));
        var_a = address(arg0);
        require(!storage_map_b[var_a] > (0 + storage_map_b[var_a]));
        var_a = var_i + storage_map_b[var_a];
        var_e = var_e + 0xa0;
        return abi.encodePacked(0x20, var_e.length);
    }
    
    /// @custom:selector    0xba087652
    /// @custom:signature   Unresolved_ba087652(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ba087652(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x01e1d114
    /// @custom:signature   Unresolved_01e1d114() public
    function Unresolved_01e1d114() public {
        (bool success, bytes memory ret0) = address(this).Unresolved_18160ddd(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        address var_e = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_e); // staticcall
    }
    
    /// @custom:selector    0xb3d7f6b9
    /// @custom:signature   Unresolved_b3d7f6b9(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_b3d7f6b9(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0x01 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0x2e6cb841
    /// @custom:signature   Unresolved_2e6cb841() public returns (uint256)
    function Unresolved_2e6cb841() public returns (uint256) {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < 0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!0) {
                if (0) {
                }
                require(!0, CustomError_8ee13f80());
            }
        }
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public view
    function Unresolved_715018a6() public view {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   Unresolved_a9059cbb(address arg0, uint256 arg1) public returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_a9059cbb(address arg0, uint256 arg1) public returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_e450d38c());
        require(address(arg0), CustomError_e450d38c());
        require(address(msg.sender), CustomError_e450d38c());
        address var_a = address(msg.sender);
        require(!(storage_map_b[var_a] < arg1), CustomError_e450d38c());
        uint256 var_f = arg1;
        var_a = address(msg.sender);
        storage_map_b[var_a] = storage_map_b[var_a] - arg1;
        require(address(arg0), CustomError_ec442f05());
        var_a = address(arg0);
        storage_map_b[var_a] = var_f + storage_map_b[var_a];
        emit Event_ddf252ad(address(msg.sender), address(arg0), arg1);
        return 0x01;
        store_g = (store_g) - arg1;
        emit Event_ddf252ad(address(msg.sender), address(arg0), arg1);
        return 0x01;
        require(!(store_h > (arg1 + (store_h))), CustomError_ec442f05());
    }
    
    /// @custom:selector    0xc6e6f592
    /// @custom:signature   Unresolved_c6e6f592(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c6e6f592(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_98a90900(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0xebcb0b7a
    /// @custom:signature   Unresolved_ebcb0b7a(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ebcb0b7a(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(address(arg0), CustomError_e6c4247b());
        unresolved_ac03e9f0 = (address(arg0)) | (uint96(unresolved_ac03e9f0));
        emit Event_5184366d(address(unresolved_ac03e9f0), address(arg0));
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public
    function Unresolved_3f4ba83a() public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(bytes1(store_ac), CustomError_8dfc202b());
        store_ac = uint248(store_ac);
        emit Event_5db9ee0a(address(msg.sender));
    }
    
    /// @custom:selector    0x6e553f65
    /// @custom:signature   Unresolved_6e553f65(uint256 arg0, address arg1) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6e553f65(uint256 arg0, address arg1) public returns (uint256) {
        require(arg1 == (address(arg1)));
        require(!(bytes1(store_a)), CustomError_d93c0665());
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_c = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_98a90900(var_c); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!(((var_g + ret0.length) - var_g) < 0x20), CustomError_5274afe7());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        address var_h = address(this);
        (bool success, bytes memory ret0) = address(unresolved_313ce567).Unresolved_23b872dd(var_e, var_h); // call
        require(success & (var_a == 0x01), CustomError_5274afe7());
        var_g = var_g;
        require(address(arg1));
        require(0);
        uint256 var_a = 0;
        require(!storage_map_b[var_a] < var_g.length);
        var_a = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - var_g.length;
        require(address(arg1));
        var_a = address(arg1);
        storage_map_b[var_a] = var_g.length + storage_map_b[var_a];
        emit Event_ddf252ad(0, address(arg1), var_g.length);
        var_d = address(unresolved_313ce567);
        var_f = arg0;
        require(address(unresolved_7dc0d1d0).code.length);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_4166dfa6(var_d); // call
        require(address(unresolved_02824acc), CustomError_90b8ec18());
        require(!0x01, CustomError_90b8ec18());
        (bool success, bytes memory ret0) = address(unresolved_02824acc).transfer(arg0);
        require(ret0.length == 0, CustomError_90b8ec18());
        emit Event_dcbc1c05(address(msg.sender), address(arg1), arg0, var_g.length);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return var_g.length;
        var_d = arg0;
        require(address(unresolved_313ce567).code.length);
        (bool success, bytes memory ret0) = address(unresolved_313ce567).Unresolved_2e1a7d4d(var_d, var_f); // call
        require(!(store_h > (var_g.length + (store_h))), CustomError_ec442f05());
        require(!bytes1(!success));
        require(success & ((!ret0.length) & (address(unresolved_313ce567).code.length > 0)), CustomError_5274afe7());
    }
    
    /// @custom:selector    0x2b80a95d
    /// @custom:signature   Unresolved_2b80a95d(address arg0, uint256 arg1) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_2b80a95d(address arg0, uint256 arg1) public returns (uint256) {
        require(arg0 == (address(arg0)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(arg0));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!arg1);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < arg1);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!arg1) {
                if (arg1) {
                }
                require(!arg1, CustomError_8ee13f80());
            }
        }
    }
    
    /// @custom:selector    0x266a3bce
    /// @custom:signature   Unresolved_266a3bce() public returns (uint256)
    function Unresolved_266a3bce() public returns (uint256) {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < 0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!0) {
                if (0) {
                }
                require(!0, CustomError_8ee13f80());
            }
        }
    }
    
    /// @custom:selector    0x4cdad506
    /// @custom:signature   Unresolved_4cdad506(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_4cdad506(uint256 arg0) public returns (uint256) {
        address var_b = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_b); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        return var_g.length;
    }
    
    /// @custom:selector    0xdbae0292
    /// @custom:signature   Unresolved_dbae0292(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dbae0292(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xe64dcf43
    /// @custom:signature   Unresolved_e64dcf43(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e64dcf43(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(address(arg0), CustomError_e6c4247b());
        unresolved_02824acc = (address(arg0)) | (uint96(unresolved_02824acc));
        emit Event_1b00dbfa(address(unresolved_02824acc), address(arg0));
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        return !(!bytes1(store_a));
    }
    
    /// @custom:selector    0xc63d75b6
    /// @custom:signature   Unresolved_c63d75b6(address arg0) public pure returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c63d75b6(address arg0) public pure returns (uint256) {
        require(arg0 == (address(arg0)));
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
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
    
    /// @custom:selector    0x6d67d5d4
    /// @custom:signature   Unresolved_6d67d5d4(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_6d67d5d4(uint256 arg0) public {
        require(address(unresolved_8da5cb5b) == msg.sender, CustomError_118cdaa7());
        require(!arg0, CustomError_db8d37d9());
        require(!(arg0 > 0x20), CustomError_db8d37d9());
        unresolved_dc692cd7 = arg0;
        emit Event_44ffe61d(arg0);
        require(arg0, CustomError_db8d37d9());
        unresolved_dc692cd7 = arg0;
        emit Event_44ffe61d(arg0);
    }
    
    /// @custom:selector    0xce96cb77
    /// @custom:signature   Unresolved_ce96cb77(address arg0) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ce96cb77(address arg0) public returns (uint256) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        address var_d = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_a71b35ab(var_d); // staticcall
        uint256 var_h = var_h + (uint248(ret0.length + 0x1f));
        require(!((var_h + ret0.length) - var_h) < 0x20);
        return var_h.length;
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public
    function Unresolved_8456cb59() public {
        require(!(!(address(msg.sender)) == (address(unresolved_8da5cb5b))), CustomError_0fd901ef());
        require(!(!(address(msg.sender)) == (address(unresolved_452a9320))), CustomError_0fd901ef());
        require(!(bytes1(store_ae)), CustomError_d93c0665());
        store_ae = 0x01 | (uint248(store_ae));
        emit Event_62e78cea(address(msg.sender));
    }
    
    /// @custom:selector    0xb4430b99
    /// @custom:signature   Unresolved_b4430b99() public payable returns (uint256)
    function Unresolved_b4430b99() public payable returns (uint256) {
        require(!(bytes1(store_a)), CustomError_d93c0665());
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(0 - msg.value);
        address var_c = address(unresolved_313ce567);
        require(0 < 0x04);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_98a90900(var_c); // staticcall
        uint256 var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!((var_g + ret0.length) - var_g) < 0x20);
        require(address(msg.sender));
        require(0);
        uint256 var_a = 0;
        require(!storage_map_b[var_a] < var_g.length);
        var_a = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - var_g.length;
        require(address(msg.sender));
        var_a = address(msg.sender);
        storage_map_b[var_a] = var_g.length + storage_map_b[var_a];
        emit Event_ddf252ad(0, address(msg.sender), var_g.length);
        var_d = address(unresolved_313ce567);
        require(address(unresolved_7dc0d1d0).code.length);
        (bool success, bytes memory ret0) = address(unresolved_7dc0d1d0).Unresolved_4166dfa6(var_d); // call
        require(address(unresolved_02824acc));
        require(!0);
        var_d = msg.value;
        require(address(unresolved_313ce567).code.length);
        (bool success, bytes memory ret0) = address(unresolved_313ce567).Unresolved_2e1a7d4d(var_d); // call
        (bool success, bytes memory ret0) = address(unresolved_02824acc).transfer(msg.value);
        require(ret0.length == 0, CustomError_90b8ec18());
        emit Event_dcbc1c05(msg.sender, msg.sender, msg.value, var_g.length);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return var_g.length;
        require(!(store_h > (var_g.length + (store_h))), CustomError_ec442f05());
    }
    
    /// @custom:selector    0xabc9653e
    /// @custom:signature   Unresolved_abc9653e(uint256 arg0) public returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_abc9653e(uint256 arg0) public returns (uint256) {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender));
        require(address(unresolved_ac03e9f0));
        require(address(unresolved_ac03e9f0));
        address var_b = address(unresolved_313ce567);
        (bool success, bytes memory ret0) = address(unresolved_ac03e9f0).Unresolved_f8b2cb4f(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        if (!((var_c + ret0.length) - var_c) < 0x20) {
            require(!((var_c + ret0.length) - var_c) < 0x20);
            address var_d = msg.sender;
            require(!var_c.length > (unresolved_12b58349 + var_c.length));
            require(!storage_map_j[var_d] < storage_map_j[var_d]);
            require(!arg0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) > storage_map_j[var_d]);
            var_d = storage_map_j[var_d];
            require(!(storage_map_j[var_d] - storage_map_j[var_d]) < arg0);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_l[var_d]) > (storage_map_m[var_d] + (storage_map_l[var_d])));
            require(!block.timestamp < (storage_map_m[var_d] + (storage_map_l[var_d])));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return 0;
            require(0);
            require((unresolved_12b58349 + var_c.length) > storage_map_j[var_d]);
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (unresolved_12b58349 + var_c.length));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) > (storage_map_q[var_d]));
            require(!address(storage_map_n[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            storage_map_q[var_d] = (storage_map_q[var_d]) - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]);
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!storage_map_j[var_d] > ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d] + storage_map_j[var_d]));
            require(!((unresolved_12b58349 + var_c.length) - storage_map_j[var_d]) < (storage_map_q[var_d]));
            var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(storage_map_q[var_d] - ((unresolved_12b58349 + var_c.length) - storage_map_j[var_d])) > (storage_map_q[var_d]));
        }
        var_d = msg.sender;
        if (!storage_map_j[var_d] < storage_map_j[var_d]) {
            if (!arg0) {
                if (arg0) {
                }
                require(!arg0, CustomError_8ee13f80());
            }
        }
    }
}