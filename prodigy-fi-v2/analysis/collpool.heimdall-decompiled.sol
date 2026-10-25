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
    bytes public constant UPGRADE_INTERFACE_VERSION = 0xBytes([53, 46, 48, 46, 48]);
    uint256 public constant unresolved_52d1902d = e07c8dba;
    bytes public constant unresolved_715018a6 = ;
    
    address public factory;
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_e;
    address store_c;
    mapping(bytes32 => bytes32) storage_map_d;
    
    event WhitelistedTokenSet(address, bool);
    error CustomError_00000000();
    event FactorySet(address);
    event VaultApproved(address, bool);
    event Upgraded(address);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x5bb47808
    /// @custom:signature   setFactory(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setFactory(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        factory = (address(arg0)) | (uint96(factory));
        emit FactorySet(address(arg0));
    }
    
    /// @custom:selector    0xe7f02017
    /// @custom:signature   useCollateral(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function useCollateral(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_c == 0x02, CustomError_3ee5aeb5());
        store_c = 0x02;
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), "CollateralPool: Vault is not created by factory");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!(bytes1(storage_map_d[var_a])), "CollateralPool: Vault is not created by factory");
    }
    
    /// @custom:selector    0x2703ee85
    /// @custom:signature   getCollateralBalance(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getCollateralBalance(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        var_a = address(arg0);
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0xc4d66de8
    /// @custom:signature   initialize(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(uint64(store_c)), CustomError_1e4fbdf7());
        require(0x01 == (uint64(store_c)), CustomError_1e4fbdf7());
        require(!(!uint64(store_c)), CustomError_1e4fbdf7());
        require(address(this).code.length, CustomError_1e4fbdf7());
        store_c = 0x01 | (uint192(store_c));
        require(!(bytes1(store_c >> 0x40)), CustomError_1e4fbdf7());
        require(!(bytes1(store_c >> 0x40)), CustomError_1e4fbdf7());
        require(!(bytes1(store_c >> 0x40)), CustomError_1e4fbdf7());
        require(!(address(arg0)), CustomError_1e4fbdf7());
        store_c = 0x010000000000000001 | (uint184(store_c));
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_c)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0x47e7ef24
    /// @custom:signature   deposit(address arg0, uint256 arg1) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function deposit(address arg0, uint256 arg1) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), CustomError_1f2a2005());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!(bytes1(storage_map_d[var_a])), CustomError_1f2a2005());
        require(!arg1, CustomError_1f2a2005());
    }
    
    /// @custom:selector    0xef0f0ec3
    /// @custom:signature   registeredVaults(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function registeredVaults(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_d[var_a]));
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_1e4fbdf7());
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0x8340f549
    /// @custom:signature   deposit(address arg0, address arg1, uint256 arg2) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function deposit(address arg0, address arg1, uint256 arg2) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), CustomError_1f2a2005());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!(bytes1(storage_map_d[var_a])), CustomError_1f2a2005());
        require(!arg2, CustomError_1f2a2005());
    }
    
    /// @custom:selector    0x8b84841b
    /// @custom:signature   vaultOwners(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function vaultOwners(address arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return address(storage_map_d[var_a]);
    }
    
    /// @custom:selector    0x76ce28f1
    /// @custom:signature   Unresolved_76ce28f1(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_76ce28f1(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - arg1);
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        address var_a = address(arg0);
        storage_map_d[var_a] = (bytes1(arg1)) | (uint248(storage_map_d[var_a]));
        emit WhitelistedTokenSet(address(arg0), arg1);
    }
    
    /// @custom:selector    0x9747b466
    /// @custom:signature   Unresolved_9747b466(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9747b466(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a), "CollateralPool: Caller is not factory");
        uint256 var_a = var_a + 0x60;
        require(!(msg.sender == (address(factory))), "CollateralPool: Caller is not factory");
        address var_b = address(arg0);
        storage_map_e[var_b] = 0x01 | (uint248(storage_map_e[var_b]));
    }
    
    /// @custom:selector    0x4b473be4
    /// @custom:signature   Unresolved_4b473be4(address arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4b473be4(address arg0, address arg1) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        var_a = address(arg1);
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0xf3fef3a3
    /// @custom:signature   withdraw(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function withdraw(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_c == 0x02, CustomError_3ee5aeb5());
        store_c = 0x02;
        require(!arg1, "CollateralPool: Insufficient balance");
        var_a = address(arg0);
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), "CollateralPool: Insufficient balance");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!(!storage_map_d[var_a] < arg1), "CollateralPool: Insufficient balance");
        var_a = address(arg0);
        require((storage_map_d[var_a] - arg1) > storage_map_d[var_a], CustomError_1f2a2005());
    }
    
    /// @custom:selector    0xaf7a060c
    /// @custom:signature   approvedVaults(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function approvedVaults(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_d[var_a]));
    }
    
    /// @custom:selector    0xdaf9c210
    /// @custom:signature   whitelistedTokens(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function whitelistedTokens(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_d[var_a]));
    }
    
    /// @custom:selector    0x3e99414e
    /// @custom:signature   Unresolved_3e99414e(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_3e99414e(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - arg1);
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!bytes1(storage_map_d[var_a]));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_8da5cb5b(var_i); // staticcall
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), "CollateralPool: Only vault owner can approve");
        var_c = var_c + 0x60;
        require(!(0 == msg.sender), "CollateralPool: Only vault owner can approve");
        uint256 var_o = 0;
        if (!arg1) {
            var_a = address(arg0);
            storage_map_d[var_a] = var_o | (uint96(storage_map_d[var_a]));
            var_a = address(arg0);
            storage_map_d[var_a] = (uint248(storage_map_d[var_a])) | (bytes1(arg1));
            emit VaultApproved(address(arg0), arg1);
            var_a = address(arg0);
            storage_map_d[var_a] = var_o | (uint96(storage_map_d[var_a]));
            var_a = address(arg0);
            storage_map_d[var_a] = (uint248(storage_map_d[var_a])) | (bytes1(arg1));
            emit VaultApproved(address(arg0), arg1);
            require(!arg1, "CollateralPool: Vault is not created by factory");
        }
    }
    
    /// @custom:selector    0x39ecf9ba
    /// @custom:signature   collateralBalances(address arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function collateralBalances(address arg0, address arg1) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        var_a = address(arg1);
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(!((arg1 + 0x23) < msg.data.length), CustomError_e07c8dba());
        require(arg1 > 0xffffffffffffffff, CustomError_e07c8dba());
        require(((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) < var_c), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f));
        require(((arg1 + (arg1)) + 0x24) > msg.data.length, CustomError_e07c8dba());
        require(!(0x863af80be1d6b8ac31322b8e6db196f3dcec45d5 == address(this)), CustomError_e07c8dba());
        require(0x863af80be1d6b8ac31322b8e6db196f3dcec45d5 == address(this), CustomError_e07c8dba());
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        require(0 - var_a, CustomError_4c9c8ce3());
        require(!address(arg0).code.length, CustomError_4c9c8ce3());
        store_c = (address(arg0)) | (uint96(store_c));
        emit Upgraded(address(arg0));
        require(!var_c.length);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_h); // delegatecall
        require(!ret0.length);
        require(!var_i);
        require(!var_i, CustomError_9996b315());
        require(!var_i, CustomError_9996b315());
        require(!address(arg0).code.length, CustomError_9996b315());
        require(ret0.length > 0xffffffffffffffff, CustomError_d6bda275());
        require(((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_c), CustomError_d6bda275());
        var_c = var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_c.length, CustomError_d6bda275());
        require(!var_c.length, CustomError_9996b315());
        require(!address(arg0).code.length, CustomError_9996b315());
        require(msg.value, CustomError_b398979f());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(!(address(store_c) == 0x863af80be1d6b8ac31322b8e6db196f3dcec45d5), CustomError_e07c8dba());
    }
}