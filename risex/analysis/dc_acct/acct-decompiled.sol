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
    mapping(bytes32 => bytes32) storage_map_a;
    address public authority;
    bytes32 store_c;
    uint32 public getTotalAccounts;
    mapping(bytes32 => bytes32) storage_map_d;
    
    event AccountRegistered(address, uint32);
    error UserIdNotRegistered(uint32);
    event Initialized(uint64);
    event AuthorityUpdated(address);
    
    /// @custom:selector    0x2b956ff7
    /// @custom:signature   getUserId(address arg0) public view returns (uint32)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getUserId(address arg0) public view returns (uint32) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        require(!(uint32(storage_map_a[var_a])), CustomError_a3f7445d());
        return uint32(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   setAuthority(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setAuthority(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(authority)), CustomError_068ca9d8());
        require(!address(arg0).code.length, CustomError_c2f31e5e());
        authority = (uint96(authority)) | (address(arg0));
        emit AuthorityUpdated(address(arg0));
    }
    
    /// @custom:selector    0xc4d66de8
    /// @custom:signature   initialize(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(uint64(store_c)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_c)), CustomError_d7e6bcf8());
        require(!(!uint64(store_c)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_c = (uint192(store_c)) | 0x01;
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(address(arg0)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        authority = (uint96(authority)) | (address(arg0));
        emit AuthorityUpdated(address(arg0));
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        store_c = uint248(store_c);
        emit Initialized(0x01);
        require(!(!uint64(store_c)), CustomError_f92ee8a9());
        if (uint64(store_c)) {
        }
        if (0x01 == (uint64(store_c))) {
        }
    }
    
    /// @custom:selector    0xc80d6a1b
    /// @custom:signature   getOrRegister(address arg0) public payable returns (uint32)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getOrRegister(address arg0) public payable returns (uint32) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = msg.sender;
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_a3f7445d());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_a3f7445d());
        require(!0, CustomError_a3f7445d());
        require(!(address(arg0)), CustomError_a3f7445d());
        address var_g = address(arg0);
        require(uint32(storage_map_d[var_g]), CustomError_a3f7445d());
        return uint32(storage_map_d[var_g]);
        require(uint32(getTotalAccounts) == 0xffffffff, CustomError_a3f7445d());
        getTotalAccounts = (uint224(getTotalAccounts)) | (uint32(getTotalAccounts + 0x01));
        var_g = address(arg0);
        storage_map_d[var_g] = (uint224(storage_map_d[var_g])) | (uint32(getTotalAccounts + 0x01));
        require((uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint32(getTotalAccounts + 0x01)), CustomError_a3f7445d());
        var_g = (0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05;
        require(0 == (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) > 0x0c), CustomError_a3f7445d());
        storage_map_d[var_g] = (~((0x01 << ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (storage_map_d[var_g])) | (arg0 >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)));
        var_g = ((0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05) + 0x01;
        storage_map_d[var_g] = ((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) & (storage_map_d[var_g])) | (((0x01 << (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (arg0) << (((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03) + 0x60));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        storage_map_d[var_g] = (~(0xffffffffffffffffffffffffffffffffffffffff << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) & (storage_map_d[var_g])) | (arg0 << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = msg.sender;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        authority = uint248(authority);
        require(!(address(arg0)), CustomError_a3f7445d());
        var_g = address(arg0);
        require(uint32(storage_map_d[var_g]), CustomError_a3f7445d());
        return uint32(storage_map_d[var_g]);
        require(uint32(getTotalAccounts) == 0xffffffff, CustomError_a3f7445d());
        getTotalAccounts = (uint224(getTotalAccounts)) | (uint32(getTotalAccounts + 0x01));
        var_g = address(arg0);
        storage_map_d[var_g] = (uint224(storage_map_d[var_g])) | (uint32(getTotalAccounts + 0x01));
        require((uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint32(getTotalAccounts + 0x01)), CustomError_a3f7445d());
        var_g = (0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05;
        require(0 == (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) > 0x0c), CustomError_a3f7445d());
        storage_map_d[var_g] = (~((0x01 << ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (storage_map_d[var_g])) | (arg0 >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)));
        var_g = ((0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05) + 0x01;
        storage_map_d[var_g] = ((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) & (storage_map_d[var_g])) | (((0x01 << (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (arg0) << (((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03) + 0x60));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        storage_map_d[var_g] = (~(0xffffffffffffffffffffffffffffffffffffffff << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) & (storage_map_d[var_g])) | (arg0 << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        require(var_p < 0x40, CustomError_a3f7445d());
        require(((0x60 + var_p) - 0x60) < 0x40, CustomError_a3f7445d());
        require(var_e - var_e, CustomError_a3f7445d());
        require(var_a - (uint32(var_a)), CustomError_a3f7445d());
        require(!var_e, CustomError_a3f7445d());
        require(!(address(arg0)), CustomError_a3f7445d());
        var_g = address(arg0);
        require(uint32(storage_map_d[var_g]), CustomError_a3f7445d());
        return uint32(storage_map_d[var_g]);
        require(uint32(getTotalAccounts) == 0xffffffff, CustomError_a3f7445d());
        getTotalAccounts = (uint224(getTotalAccounts)) | (uint32(getTotalAccounts + 0x01));
        var_g = address(arg0);
        storage_map_d[var_g] = (uint224(storage_map_d[var_g])) | (uint32(getTotalAccounts + 0x01));
        require((uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint32(getTotalAccounts + 0x01)), CustomError_a3f7445d());
        var_g = (0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05;
        require(0 == (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) > 0x0c), CustomError_a3f7445d());
        storage_map_d[var_g] = (~((0x01 << ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (storage_map_d[var_g])) | (arg0 >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)));
        var_g = ((0x14 * (uint32(getTotalAccounts + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) >> 0x05) + 0x01;
        storage_map_d[var_g] = ((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) & (storage_map_d[var_g])) | (((0x01 << (0xa0 - ((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03))) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) & (arg0) << (((0x20 - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03) + 0x60));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        storage_map_d[var_g] = (~(0xffffffffffffffffffffffffffffffffffffffff << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03)) & (storage_map_d[var_g])) | (arg0 << ((0x0c - (bytes1(0x14 * (uint32(uint32(getTotalAccounts) + 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))) << 0x03));
        emit AccountRegistered(address(arg0), uint32(getTotalAccounts + 0x01));
        return uint32(getTotalAccounts + 0x01);
        require(!var_p < 0x20);
        require(((0x60 + var_p) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x8fb36037
    /// @custom:signature   isConsumingScheduledOp() public view returns (uint256)
    function isConsumingScheduledOp() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (!authority >> 0xa0) {
            return 0x8fb3603700000000000000000000000000000000000000000000000000000000;
            return 0;
        }
    }
    
    /// @custom:selector    0x68501aee
    /// @custom:signature   getAddress(uint32 arg0) public view
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function getAddress(uint32 arg0) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        if (!uint32(arg0)) {
            require(!(uint32(arg0)), CustomError_cc4e0b15());
            require((uint32(arg0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint32(arg0)), CustomError_cc4e0b15());
        }
    }
}