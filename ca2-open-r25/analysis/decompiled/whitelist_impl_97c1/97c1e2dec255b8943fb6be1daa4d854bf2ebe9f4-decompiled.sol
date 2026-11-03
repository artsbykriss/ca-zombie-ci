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
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    uint256 public constant unresolved_54fd4d50 = 1;
    bytes public constant contractName = 0xBytes([87, 104, 105, 116, 101, 108, 105, 115, 116]);
    uint256 public constant MAX_BATCH_SIZE = 50;
    
    bool public whitelistEnabled;
    bytes32 store_c;
    mapping(bytes32 => bytes32) storage_map_d;
    address public getProxyAdmin;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_e;
    address public getProxyImplementation;
    
    error InvalidInput();
    event RoleRevoked(bytes32, address, address);
    event WhitelistAdded(address);
    event Initialized(uint64);
    event WhitelistToggled(bool);
    event RoleGranted(bytes32, address, address);
    event WhitelistRemoved(address);
    
    /// @custom:selector    0xa6177139
    /// @custom:signature   Unresolved_a6177139(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a6177139(uint256 arg0, address arg1) public view {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        uint256 var_c = 0x28 + var_c;
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_a[var_d]), CustomError_f80a4845());
        require(!(arg0 > 0x32), CustomError_f80a4845());
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        var_d = var_d;
        var_d = address(msg.sender);
        if (storage_map_a[var_d]) {
            require(address(0 + (0x20 + (arg0))), CustomError_b4fa3fb3());
            var_d = address(0 + (0x20 + (arg0)));
            require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
        }
    }
    
    /// @custom:selector    0xc4d66de8
    /// @custom:signature   Unresolved_c4d66de8(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c4d66de8(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(!(!uint64(store_c)), CustomError_d7e6bcf8());
        require(!(0x01 == (uint64(store_c))), CustomError_d7e6bcf8());
        require(!(uint64(store_c)), CustomError_d7e6bcf8());
        require(!address(this).code.length, CustomError_d7e6bcf8());
        store_c = 0x01 | (uint192(store_c));
        require(!(!bytes1(store_c / 0x010000000000000000)), CustomError_d7e6bcf8());
        require(address(arg0), CustomError_d7e6bcf8());
        require(bytes1(store_c / 0x010000000000000000), CustomError_d7e6bcf8());
        var_a = var_a;
        var_a = address(arg0);
        require(bytes1(storage_map_d[var_a]), CustomError_d7e6bcf8());
        whitelistEnabled = uint248(whitelistEnabled);
        require(!(!bytes1(store_c / 0x010000000000000000)), CustomError_d7e6bcf8());
        store_c = uint248(store_c);
        emit Initialized(0x01);
        require(!(uint64(store_c)), CustomError_f92ee8a9());
        require(!(uint64(store_c)), CustomError_f92ee8a9());
        require(!(uint64(store_c)), CustomError_f92ee8a9());
        store_c = 0x01 | (uint192(store_c));
        require(!(!bytes1(store_c / 0x010000000000000000)), CustomError_d7e6bcf8());
        require(address(arg0), CustomError_d7e6bcf8());
        require(bytes1(store_c / 0x010000000000000000), CustomError_d7e6bcf8());
        var_a = var_a;
        var_a = address(arg0);
        require(bytes1(storage_map_d[var_a]), CustomError_d7e6bcf8());
        whitelistEnabled = uint248(whitelistEnabled);
        require(!(!bytes1(store_c / 0x010000000000000000)), CustomError_d7e6bcf8());
        store_c = uint248(store_c);
        emit Initialized(0x01);
        if (!0x01 == (uint64(store_c))) {
        }
    }
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   renounceRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function renounceRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(msg.sender == (address(arg1)), CustomError_6697b232());
        var_b = var_b;
        var_b = address(arg1);
        require(!bytes1(storage_map_e[var_b]));
        var_b = arg0;
        var_b = address(arg1);
        storage_map_e[var_b] = uint248(storage_map_e[var_b]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0xae5f1eb9
    /// @custom:signature   Unresolved_ae5f1eb9(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ae5f1eb9(uint256 arg0, address arg1) public view {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        uint256 var_c = 0x28 + var_c;
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_a[var_d]), CustomError_f80a4845());
        require(!(arg0 > 0x32), CustomError_f80a4845());
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!(((0 + (0x20 + (0x04 + arg0))) + 0x20) - (0 + (0x20 + (0x04 + arg0)))) < 0x20);
        require((0 + (0x20 + (arg0))) == (address(0 + (0x20 + (arg0)))));
        var_d = var_d;
        var_d = address(msg.sender);
        if (storage_map_a[var_d]) {
            require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
            require(address(0 + (0x20 + (arg0))), CustomError_b4fa3fb3());
        }
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_d[var_a]));
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_g[var_a];
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   grantRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function grantRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_d[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_d[var_a]), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_d[var_a] = 0x01 | (uint248(storage_map_d[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   revokeRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function revokeRole(bytes32 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = address(msg.sender);
        require(bytes1(storage_map_d[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_d[var_a])), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_d[var_a] = uint248(storage_map_d[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x7965db0b00000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!(uint32(arg0)) == 0x01ffc9a700000000000000000000000000000000000000000000000000000000);
    }
    
    /// @custom:selector    0x3af32abf
    /// @custom:signature   isWhitelisted(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isWhitelisted(address arg0) public view returns (bool) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_d[var_a]));
    }
    
    /// @custom:selector    0x80e3f1ad
    /// @custom:signature   Unresolved_80e3f1ad(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_80e3f1ad(uint256 arg0) public payable {
        require(arg0 == arg0);
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
        require(arg0 - (bytes1(whitelistEnabled)), CustomError_b4fa3fb3());
        whitelistEnabled = arg0 | (uint248(whitelistEnabled));
        emit WhitelistToggled(arg0);
    }
    
    /// @custom:selector    0xe43252d7
    /// @custom:signature   addToWhitelist(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addToWhitelist(address arg0) public payable {
        require(arg0 == (address(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        var_d = address(arg0);
        require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
        var_d = address(arg0);
        storage_map_a[var_d] = 0x01 | (uint248(storage_map_a[var_d]));
        emit WhitelistAdded(address(arg0));
    }
    
    /// @custom:selector    0x8ab1d681
    /// @custom:signature   removeFromWhitelist(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function removeFromWhitelist(address arg0) public payable {
        require(arg0 == (address(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_a[var_d]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        var_d = address(arg0);
        require(!(bytes1(storage_map_a[var_d])), CustomError_b4fa3fb3());
        var_d = address(arg0);
        storage_map_a[var_d] = uint248(storage_map_a[var_d]);
        emit WhitelistRemoved(address(arg0));
    }
}