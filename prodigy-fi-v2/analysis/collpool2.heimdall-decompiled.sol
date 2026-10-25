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
    uint256 public constant unresolved_325d3430 = 2;
    uint256 public constant unresolved_52d1902d = e07c8dba;
    bytes public constant unresolved_715018a6 = ;
    
    address public factory;
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_k;
    mapping(bytes32 => bytes32) storage_map_d;
    mapping(bytes32 => bytes32) storage_map_i;
    bytes32 store_f;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_e;
    mapping(bytes32 => bytes32) storage_map_l;
    mapping(bytes32 => bytes32) storage_map_j;
    mapping(bytes32 => bytes32) storage_map_c;
    
    error CustomError_00000000();
    event VaultApproved(address, bool);
    event Upgraded(address);
    event WhitelistedTokenSet(address, bool);
    event Event_88521496();
    event FactorySet(address);
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
    
    /// @custom:selector    0x349fe487
    /// @custom:signature   Unresolved_349fe487(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_349fe487(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return abi.encodePacked(storage_map_c[var_a], storage_map_d[var_a], storage_map_e[var_a]);
    }
    
    /// @custom:selector    0xa4bc9c2d
    /// @custom:signature   Unresolved_a4bc9c2d(bool arg0) public payable
    /// @param              arg0 ["bool", "uint8", "bytes1", "int8"]
    function Unresolved_a4bc9c2d(bool arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (bytes1(arg0)));
        address var_a = msg.sender;
        require(!bytes1(storage_map_c[var_a]));
        require(!bytes1(arg0));
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!storage_map_c[var_a]);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_8da5cb5b(var_i); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).investmentToken(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).linkedToken(); // staticcall
        var_a = 0;
        var_a = 0;
        require((storage_map_d[var_a] - var_c.length) > (storage_map_d[var_a]));
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - (address(var_c.length)));
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x1ea734b6
    /// @custom:signature   processUserDeposit(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function processUserDeposit(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_f == 0x02, CustomError_3ee5aeb5());
        store_f = 0x02;
        address var_a = msg.sender;
        require(!bytes1(storage_map_c[var_a]));
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        require(!bytes1(storage_map_c[var_a]));
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_8da5cb5b(var_i); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).investmentToken(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).linkedToken(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_87110ffc(var_i); // staticcall
        var_a = 0;
        require(bytes1(storage_map_c[var_a]));
        var_a = 0;
        require(!bytes1(storage_map_c[var_a]));
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_641786ad(var_i); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_f54642f8(var_i); // staticcall
        require(!(((arg1 * 0) / arg1) == 0) | !arg1);
        require(!0);
        require(0x0de0b6b3a7640000 > 0x0de0b6b3a7640000);
        require(0x0de0b6b3a7640000 > 0x0de0b6b3a7640000);
        require(!(((arg1 * 0x0de0b6b3a7640000) / arg1) == 0x0de0b6b3a7640000) | !arg1);
        require((((arg1 * 0x0de0b6b3a7640000) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0x0de0b6b3a7640000) * 0) == ((((arg1 * 0x0de0b6b3a7640000) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0x0de0b6b3a7640000) * 0)));
        require(!0xc097ce7bc90715b34b9f1000000000 > ((((arg1 * 0x0de0b6b3a7640000) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0x0de0b6b3a7640000) * 0) - ((((arg1 * 0x0de0b6b3a7640000) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0x0de0b6b3a7640000) * 0))));
        (bool success, bytes memory ret0) = address(msg.sender).tradingFeeRate(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_fccc9c42(var_i); // staticcall
        require(0 < 0, CustomError_a8ce4432());
        require(0 == 0);
        require(!(((arg1 * 0) / arg1) == 0) | !arg1);
        require((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) == ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)));
        require(!0xc097ce7bc90715b34b9f1000000000 > ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0))));
        address var_k = address(msg.sender);
        require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
        var_c = var_c + 0xa0;
        (bool success, bytes memory ret0) = address(0).Unresolved_23b872dd(var_k); // call
        require(ret0.length, CustomError_5274afe7());
        require(!address(0).code.length, CustomError_5274afe7());
        require((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711);
        require(!0);
        var_a = 0;
        require(!storage_map_c[var_a] < ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711));
        var_a = 0;
        require(!bytes1(storage_map_c[var_a]));
        require(((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) - storage_map_c[var_a] > ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) - storage_map_c[var_a] > (((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) - storage_map_c[var_a] + (storage_map_g[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) - storage_map_c[var_a] + (storage_map_g[var_a]) > (storage_map_d[var_a]));
        require(!0);
        (bool success, bytes memory ret0) = address(msg.sender).feeReceiver(); // staticcall
        uint256 var_p = 0;
        require(((var_c + 0x80) > 0xffffffffffffffff) | ((var_c + 0x80) < var_c));
        var_c = var_c + 0x80;
        (bool success, bytes memory ret0) = address(0).Unresolved_a9059cbb(var_p); // call
        require(ret0.length, CustomError_5274afe7());
        require(!address(0).code.length, CustomError_5274afe7());
        var_a = 0;
        require(storage_map_c[var_a] - (storage_map_c[var_a] ^ (((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) ^ storage_map_c[var_a] * (((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) < storage_map_c[var_a]))) > storage_map_c[var_a], CustomError_24775e06());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_c[var_a] = storage_map_c[var_a] - (storage_map_c[var_a] ^ (((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) ^ storage_map_c[var_a] * (((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) < storage_map_c[var_a])));
        require(((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) > 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_24775e06());
        var_a = 0x24775e0600000000000000000000000000000000000000000000000000000000;
        require(storage_map_h[var_a] - ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) < (storage_map_h[var_a]) & (0 > ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711)) | (storage_map_h[var_a] - ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711) > (storage_map_h[var_a]) & (!0 > ((((arg1 * 0) * 0) - (((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) >> 0x24) | ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg1 * 0) * 0) - ((((arg1 * 0) * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg1 * 0) * 0)) - ((((arg1 * 0) * 0) % 0xc097ce7bc90715b34b9f1000000000) > ((arg1 * 0) * 0)) << 0xdc) * 0x356317ffa45f828d2a41175b2aed3a20e7fdd4a4e46cc11944d93b01be7b1711))), CustomError_5274afe7());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == var_a), CustomError_5274afe7());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - (address(var_c.length)));
        require(!0x01, "CollateralPoolV2: insufficient LP feeToken balance");
        var_a = 0;
        var_a = 0;
        if (storage_map_d[var_a] > (storage_map_d[var_a] + arg1)) {
            if (!(((arg1 * 0) / arg1) == 0) | !arg1) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(storage_map_d[var_a] > (storage_map_d[var_a] + arg1));
            }
            require(!(((arg1 * 0) / arg1) == 0) | !arg1);
        }
        (bool success, bytes memory ret0) = address(msg.sender).tradingFeeRate(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_fccc9c42(var_i); // staticcall
        require(0 < 0, CustomError_a8ce4432());
        if (0 == 0) {
            if (!(((arg1 * 0) / arg1) == 0) | !arg1) {
                if (0x20 > ret0.length) {
                }
                if (0x20 > ret0.length) {
                }
                require(0 == 0, "CollateralPoolV2: tokens not whitelisted");
            }
            require(!((((arg1 * 0) / arg1) == 0) | !arg1), "CollateralPoolV2: tokens not whitelisted");
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xc4d66de8
    /// @custom:signature   initialize(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(uint64(store_f)), CustomError_1e4fbdf7());
        require(0x01 == (uint64(store_f)), CustomError_1e4fbdf7());
        require(!(!uint64(store_f)), CustomError_1e4fbdf7());
        require(address(this).code.length, CustomError_1e4fbdf7());
        store_f = 0x01 | (uint192(store_f));
        require(!(bytes1(store_f >> 0x40)), CustomError_1e4fbdf7());
        require(!(bytes1(store_f >> 0x40)), CustomError_1e4fbdf7());
        require(!(bytes1(store_f >> 0x40)), CustomError_1e4fbdf7());
        require(!(address(arg0)), CustomError_1e4fbdf7());
        store_f = 0x010000000000000001 | (uint184(store_f));
        require(!(bytes1(store_f >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_f >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_f)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0x47e7ef24
    /// @custom:signature   deposit(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function deposit(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_f == 0x02, CustomError_3ee5aeb5());
        store_f = 0x02;
        address var_a = address(arg0);
        require(!bytes1(storage_map_c[var_a]));
        require(!arg1);
        address var_d = address(msg.sender);
        require(((var_h + 0xa0) > 0xffffffffffffffff) | ((var_h + 0xa0) < var_h));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_23b872dd(var_d); // call
        require(ret0.length, CustomError_5274afe7());
        require(!(address(arg0).code.length), CustomError_5274afe7());
        var_a = address(arg0);
        require(storage_map_g[var_a] - (storage_map_g[var_a] ^ ((arg1 ^ (storage_map_g[var_a])) * (arg1 < (storage_map_g[var_a])))) > (storage_map_g[var_a]), CustomError_5274afe7());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == var_a), CustomError_5274afe7());
    }
    
    /// @custom:selector    0x0283344a
    /// @custom:signature   Unresolved_0283344a(address arg0, bool arg1, address arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_0283344a(address arg0, bool arg1, address arg2) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (bytes1(arg1)));
        require(arg2 - (address(arg2)));
        var_a = address(arg2);
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(storage_map_e[var_a] > (storage_map_e[var_a] + storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(arg1) - 0x01);
        return abi.encodePacked(storage_map_d[var_a], 0);
        require(0x02 - (bytes1(arg1)));
        return abi.encodePacked(0, (storage_map_e[var_a]) + storage_map_c[var_a]);
        return abi.encodePacked(storage_map_d[var_a], (storage_map_e[var_a]) + storage_map_c[var_a]);
    }
    
    /// @custom:selector    0xef0f0ec3
    /// @custom:signature   registeredVaults(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function registeredVaults(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0x05c4fdf9
    /// @custom:signature   registerVault(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function registerVault(address arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a), "CollateralPool: Caller is not factory");
        uint256 var_a = var_a + 0x60;
        require(!(msg.sender == (address(factory))), "CollateralPool: Caller is not factory");
        var_h = 0x20;
        address var_b = address(arg1);
        storage_map_i[var_b] = (uint248(storage_map_i[var_b])) | 0x01;
        (bool success, bytes memory ret0) = address(arg1).Unresolved_8da5cb5b(var_h); // staticcall
        var_b = 0;
        require(!(bytes1(storage_map_i[var_b])), "CollateralPoolV2: vault owner is not whitelisted");
        require(address(arg0) == 0, "CollateralPoolV2: vault owner is not whitelisted");
        var_b = address(arg1);
        storage_map_i[var_b] = (uint248(storage_map_i[var_b])) | 0x01;
        emit VaultApproved(address(arg1), 0x01);
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xaf7a060c
    /// @custom:signature   approvedVaults(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function approvedVaults(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0xdaf9c210
    /// @custom:signature   whitelistedTokens(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function whitelistedTokens(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_c[var_a]));
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
        address var_a = address(arg0);
        require(!bytes1(storage_map_c[var_a]));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_8da5cb5b(var_d); // staticcall
        require(msg.sender - 0, "CollateralPoolV2: approve with not vault owner");
        var_a = address(arg0);
        storage_map_c[var_a] = (bytes1(arg1)) | (uint248(storage_map_c[var_a]));
        emit VaultApproved(address(arg0), arg1);
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        uint256 var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - (address(var_h.length)));
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
        require(!(0x50c0be4490fa490e01029fdfb03df206189f0d3f == address(this)), CustomError_e07c8dba());
        require(0x50c0be4490fa490e01029fdfb03df206189f0d3f == address(this), CustomError_e07c8dba());
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        require(0 - var_a, CustomError_4c9c8ce3());
        require(!address(arg0).code.length, CustomError_4c9c8ce3());
        store_f = (address(arg0)) | (uint96(store_f));
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
        require(!(address(store_f) == 0x50c0be4490fa490e01029fdfb03df206189f0d3f), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0x1749aa26
    /// @custom:signature   Unresolved_1749aa26(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1749aa26(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - arg1);
        var_a = address(arg0);
        require(((var_c + 0x0100) > 0xffffffffffffffff) | ((var_c + 0x0100) < var_c), CustomError_3ee5aeb5());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x0100;
        require(storage_map_j[var_a] > (storage_map_j[var_a] + (storage_map_k[var_a])), CustomError_3ee5aeb5());
        var_a = address(msg.sender);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_3ee5aeb5());
        require(arg1, CustomError_3ee5aeb5());
        require(!(var_m > (storage_map_j[var_a] + (storage_map_k[var_a]))), CustomError_3ee5aeb5());
        require(0, CustomError_3ee5aeb5());
        require(store_f == 0x02, CustomError_3ee5aeb5());
        store_f = 0x02;
        var_a = address(arg0);
        require(!bytes1(storage_map_c[var_a]));
        require(!0);
        address var_o = address(msg.sender);
        require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_23b872dd(var_o); // call
        require(ret0.length, CustomError_5274afe7());
        require(!(address(arg0).code.length), CustomError_5274afe7());
        var_a = address(arg0);
        require(storage_map_g[var_a] - (storage_map_g[var_a] ^ ((0 ^ (storage_map_g[var_a])) * (0 < (storage_map_g[var_a])))) > (storage_map_g[var_a]), CustomError_5274afe7());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == var_a), CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        if (!storage_map_c[var_a]) {
        }
    }
    
    /// @custom:selector    0x2094e792
    /// @custom:signature   Unresolved_2094e792(address arg0, address arg1) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2094e792(address arg0, address arg1) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        var_a = address(arg1);
        return abi.encodePacked(storage_map_c[var_a], storage_map_d[var_a], storage_map_e[var_a], storage_map_j[var_a], storage_map_k[var_a], storage_map_g[var_a], storage_map_l[var_a], storage_map_h[var_a]);
    }
    
    /// @custom:selector    0xdad5bf0e
    /// @custom:signature   Unresolved_dad5bf0e(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dad5bf0e(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0x9d73d725
    /// @custom:signature   Unresolved_9d73d725(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_9d73d725(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - arg1);
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        address var_a = address(arg0);
        storage_map_c[var_a] = (bytes1(arg1)) | (uint248(storage_map_c[var_a]));
        emit Event_88521496(address(arg0), arg1);
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
        storage_map_c[var_a] = (bytes1(arg1)) | (uint248(storage_map_c[var_a]));
        emit WhitelistedTokenSet(address(arg0), arg1);
    }
    
    /// @custom:selector    0xbeebc117
    /// @custom:signature   Unresolved_beebc117(address arg0, address arg1, uint256 arg2) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_beebc117(address arg0, address arg1, uint256 arg2) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - arg2);
        var_a = address(arg1);
        if (((var_c + 0x0100) > 0xffffffffffffffff) | ((var_c + 0x0100) < var_c)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            uint256 var_c = var_c + 0x0100;
            require(((var_c + 0x0100) > 0xffffffffffffffff) | ((var_c + 0x0100) < var_c));
            var_a = address(arg0);
            require(storage_map_j[var_a] > (storage_map_j[var_a] + (storage_map_k[var_a])));
            require(bytes1(storage_map_c[var_a]));
            require(arg2);
            return 0;
            require(!(var_n) > (storage_map_j[var_a] + (storage_map_k[var_a])));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            return (storage_map_j[var_a] + (storage_map_k[var_a])) - (var_n);
            require(storage_map_j[var_a] + (storage_map_k[var_a]) - (var_n) > (storage_map_j[var_a] + (storage_map_k[var_a])));
        }
    }
    
    /// @custom:selector    0x2c082527
    /// @custom:signature   Unresolved_2c082527(address arg0, address arg1) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2c082527(address arg0, address arg1) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        var_a = address(arg1);
        return abi.encodePacked(storage_map_c[var_a], storage_map_d[var_a], storage_map_e[var_a]);
    }
    
    /// @custom:selector    0xf3fef3a3
    /// @custom:signature   withdraw(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function withdraw(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_f == 0x02, CustomError_3ee5aeb5());
        store_f = 0x02;
        require(!arg1, "CollateralPoolV2: amount is zero");
        require(((var_b + 0x60) > 0xffffffffffffffff) | ((var_b + 0x60) < var_b), "CollateralPoolV2: amount is zero");
        uint256 var_b = var_b + 0x60;
        var_a = address(arg0);
        require(((var_b + 0x0100) > 0xffffffffffffffff) | ((var_b + 0x0100) < var_b), "CollateralPoolV2: amount is zero");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(storage_map_j[var_a] > (storage_map_j[var_a] + (storage_map_k[var_a])), "CollateralPoolV2: amount is zero");
    }
    
    /// @custom:selector    0xd5735e7d
    /// @custom:signature   Unresolved_d5735e7d(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d5735e7d(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(store_f == 0x02, CustomError_3ee5aeb5());
        store_f = 0x02;
        address var_a = msg.sender;
        require(!bytes1(storage_map_c[var_a]));
        var_a = address(arg0);
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x60;
        (bool success, bytes memory ret0) = address(msg.sender).state(); // staticcall
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_8da5cb5b(var_i); // staticcall
        require(!0x01 == 0);
        (bool success, bytes memory ret0) = address(msg.sender).linkedToken(); // staticcall
        require(!(0x01 == 0), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(!(var_j), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0;
        var_a = address(arg0);
        storage_map_c[var_a] = 0;
        storage_map_d[var_a] = 0;
        storage_map_e[var_a] = 0;
        require(0 == (0x01 == 0), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(storage_map_k[var_a] - (var_j) > (storage_map_k[var_a]), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_k[var_a] = (storage_map_k[var_a]) - (var_j);
        require(!(0x01 == 0), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(!(0x01 == 0), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_c = var_c + 0x60;
        var_a = 0;
        require(0 == (bytes1(storage_map_c[var_a])), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0;
        require(!(storage_map_c[var_a] < (var_j)), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0;
        require(!(bytes1(storage_map_c[var_a])), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(var_j - storage_map_c[var_a] > (var_j), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_j - storage_map_c[var_a] > (var_j - storage_map_c[var_a] + (storage_map_g[var_a])), "CollateralPoolV2: insufficient linkedToken balance for vault");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_j - storage_map_c[var_a] + (storage_map_g[var_a]) > (storage_map_d[var_a]), "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(!0, "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(!0x01, "CollateralPoolV2: insufficient linkedToken balance for vault");
        require(!(!storage_map_c[var_a] < (var_j)), "CollateralPoolV2: insufficient linkedToken balance for vault");
        if (((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c)) {
            if (!0x01 == 0) {
            }
            store_f = 0x01;
            require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        }
        (bool success, bytes memory ret0) = address(msg.sender).investmentToken(); // staticcall
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
}