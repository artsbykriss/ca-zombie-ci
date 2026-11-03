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
    bytes public constant contractName = 0xBytes([87, 105, 116, 104, 100, 114, 97, 119, 81, 117, 101, 117, 101]);
    uint256 public constant MAX_REQUEST_BATCH = 50;
    
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 public getLastProcessedRequestId;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_r;
    address public getProxyImplementation;
    bytes32 store_a;
    uint256 public getLastRequestId;
    mapping(bytes32 => bytes32) storage_map_b;
    address public payer;
    mapping(bytes32 => bytes32) storage_map_i;
    address public getProxyAdmin;
    address public asset;
    mapping(bytes32 => bytes32) storage_map_m;
    mapping(bytes32 => bytes32) storage_map_l;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_o;
    
    error CustomError_00000000();
    event RoleRevoked(bytes32, address, address);
    event RoleGranted(bytes32, address, address);
    event PayerUpdated(address, address);
    
    /// @custom:selector    0x485cc955
    /// @custom:signature   Unresolved_485cc955(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_485cc955(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x483cab58
    /// @custom:signature   fulfillSpecificRequest(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function fulfillSpecificRequest(uint256 arg0) public payable {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_a, CustomError_3ee5aeb5());
        store_a = 0x02;
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]), CustomError_c969e0f2());
        require(!arg0, CustomError_c969e0f2());
        require(!(arg0 > getLastRequestId), CustomError_c969e0f2());
        var_a = var_a;
        require(!(bytes1(storage_map_d[var_a] / 0x010000000000)), CustomError_502746dc());
        require(address(payer), CustomError_8ab07f30());
        require(!((arg0 - 0x01) > arg0), CustomError_8ab07f30());
        require(arg0, CustomError_c969e0f2());
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
        require(!bytes1(storage_map_f[var_b]));
        var_b = arg0;
        var_b = address(arg1);
        storage_map_f[var_b] = uint248(storage_map_f[var_b]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(arg1 == (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_b[var_a]));
    }
    
    /// @custom:selector    0x43e6cb8e
    /// @custom:signature   fulfillPendingWithdrawals(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function fulfillPendingWithdrawals(uint256 arg0) public payable {
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + store_a, CustomError_3ee5aeb5());
        store_a = 0x02;
        var_a = var_a;
        address var_a = address(msg.sender);
        require(bytes1(storage_map_b[var_a]));
        require(address(payer));
        address var_h = address(payer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_70a08231(var_h); // staticcall
        var_d = var_d + (uint248(ret0.length + 0x1f));
        require(!((var_d + ret0.length) - var_d) < 0x20);
        require(!var_d.length < arg0);
        address var_j = address(payer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_70a08231(var_j); // staticcall
        var_j = address(payer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_dd62ed3e(var_j); // staticcall
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
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_b[var_a])), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_b[var_a] = uint248(storage_map_b[var_a]);
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
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        var_a = var_a;
        return storage_map_i[var_a];
    }
    
    /// @custom:selector    0xb70d8fab
    /// @custom:signature   skipWithdrawalRequest(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function skipWithdrawalRequest(uint256 arg0) public view {
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_l[var_d]), CustomError_c969e0f2());
        require(!arg0, CustomError_c969e0f2());
        require(!(arg0 > getLastRequestId), CustomError_c969e0f2());
        var_d = var_d;
        require(!(bytes1(storage_map_m[var_d] / 0x010000000000)), CustomError_502746dc());
        require(!((arg0 - 0x01) > arg0), CustomError_c969e0f2());
        require(arg0, CustomError_c969e0f2());
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
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_b[var_a]), CustomError_e2517d3f());
        var_a = arg0;
        var_a = address(arg1);
        storage_map_b[var_a] = 0x01 | (uint248(storage_map_b[var_a]));
        emit RoleGranted(arg0, address(arg1), address(msg.sender));
    }
    
    /// @custom:selector    0xd55e6975
    /// @custom:signature   setPayer(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setPayer(address arg0) public payable {
        require(arg0 == (address(arg0)));
        var_d = var_d;
        address var_d = address(msg.sender);
        require(bytes1(storage_map_l[var_d]), CustomError_b4fa3fb3());
        require(address(arg0), CustomError_b4fa3fb3());
        payer = (address(arg0)) | (uint96(payer));
        emit PayerUpdated(address(payer), address(arg0));
    }
    
    /// @custom:selector    0x340c59c5
    /// @custom:signature   Unresolved_340c59c5(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_340c59c5(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xb8c4b85a
    /// @custom:signature   Unresolved_b8c4b85a(uint256 arg0, uint256 arg1) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_b8c4b85a(uint256 arg0, uint256 arg1) public view returns (bytes memory) {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!(arg0 > 0xffffffffffffffff), CustomError_c969e0f2());
        require(!(arg0), CustomError_c969e0f2());
        var_d = var_d + 0xe0;
        require(arg0 + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_c969e0f2());
        require(!(0 < (arg0)), CustomError_c969e0f2());
        require(0 < (arg0), CustomError_c969e0f2());
        require(!(0 + (0x20 + (arg0))), CustomError_c969e0f2());
        require(!((0 + (0x20 + (arg0))) > getLastRequestId), CustomError_c969e0f2());
        var_a = var_a;
        require(!(((0 + (0x20 + (arg0))) - 0x01) > (0 + (0x20 + (arg0)))), CustomError_c969e0f2());
        var_a = (0 + (0x20 + (arg0))) - 0x01;
        var_d = 0xe0 + var_d;
        require(!(storage_map_n[var_a] - (storage_map_n[var_a]) > (storage_map_n[var_a])), CustomError_c969e0f2());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!0 + (0x20 + (arg0))), CustomError_c969e0f2());
        return abi.encodePacked(0x20, var_d.length);
    }
    
    /// @custom:selector    0x7d031b65
    /// @custom:signature   getWithdrawalRequests(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getWithdrawalRequests(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        var_a = var_a;
        address var_c = var_c + (0x20 + (0x20 * (storage_map_n[var_a])));
        require(!storage_map_n[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_n[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
}