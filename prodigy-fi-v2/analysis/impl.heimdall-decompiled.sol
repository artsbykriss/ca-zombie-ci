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
    uint256 public constant unresolved_715018a6 = ;
    bytes public constant UPGRADE_INTERFACE_VERSION = 0xBytes([53, 46, 48, 46, 48]);
    bytes public constant unresolved_43b78412 = 0xBytes([]);
    uint256 public constant unresolved_52d1902d = e07c8dba;
    
    address public unresolved_467c94ec;
    uint256 store_p;
    mapping(bytes32 => bytes32) storage_map_w;
    mapping(bytes32 => bytes32) storage_map_d;
    bytes32 store_k;
    address public weth;
    uint256 public getDeployedVaultCount;
    mapping(bytes32 => bytes32) storage_map_s;
    bool public unresolved_655bfd59;
    address public collateralPool;
    bytes32 store_j;
    address public unresolved_8da5cb5b;
    mapping(bytes32 => bytes32) storage_map_b;
    address public unresolved_309dfe1b;
    address store_f;
    address store_g;
    bytes32 store_h;
    address public vaultImplementation;
    mapping(bytes32 => bytes32) storage_map_l;
    bytes public unresolved_249b492c;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_x;
    bytes32 store_v;
    mapping(bytes32 => bytes32) storage_map_c;
    
    error CustomError_00000000();
    event Event_62e78cea();
    event Event_7b6dbde8();
    event Initialized(uint64);
    event Event_5db9ee0a();
    event Upgraded(address);
    event Event_1fdc1341();
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x9d509f38
    /// @custom:signature   Unresolved_9d509f38(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9d509f38(address arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg1).decimals(); // staticcall
        require((0x12 + (bytes1(var_d))) > 0xff);
        (bool success, bytes memory ret0) = address(arg0).decimals(); // staticcall
        require(bytes1(0x12 + (var_d)) - (bytes1(var_d)) > 0xff, CustomError_d25598a0());
        require(!(bytes1((0x12 + (var_d)) - (var_d))), CustomError_d25598a0());
        require(((var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f))) < var_g));
        uint248 var_g = var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f));
        storage_map_b[var_j] = (uint248(storage_map_b[var_j])) | (bytes1((0x12 + (var_d)) - (var_d)));
        return ;
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(var_g.length - (bytes1(var_g.length)));
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x7159c42e
    /// @custom:signature   Unresolved_7159c42e(address arg0, address arg1, address arg2, uint256 arg3) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function Unresolved_7159c42e(address arg0, address arg1, address arg2, uint256 arg3) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) < var_f));
        uint248 var_f = var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f));
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f));
        var_f = var_f + 0x40;
        storage_map_c[var_k] = (uint96(storage_map_c[var_k])) | (address(var_f.length));
        storage_map_d[var_k] = var_i;
        return ;
    }
    
    /// @custom:selector    0x7c08b964
    /// @custom:signature   changeFeeReceiver(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function changeFeeReceiver(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(address(arg0) == (address(store_f)), CustomError_d92e233d());
        require(!(address(arg0)), CustomError_d92e233d());
        store_f = (uint96(store_f)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xc4d66de8
    /// @custom:signature   initialize(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(uint64(store_g)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_g)), CustomError_d7e6bcf8());
        require(!(!uint64(store_g)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_g = (uint192(store_g)) | 0x01;
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(address(arg0)), CustomError_d7e6bcf8());
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), address(arg0));
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        store_h = 0xa8c0;
        require(((var_c + 0x80) > 0xffffffffffffffff) | ((var_c + 0x80) < var_c), CustomError_d7e6bcf8());
        unresolved_249b492c = 0x470de4df820000;
        store_j = var_b;
        store_f = (uint96(store_f)) | (address(arg0));
        store_k = var_b;
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        return ;
        store_g = uint248(store_g);
        emit Initialized(0x01);
        return ;
        store_g = (uint248(store_g)) | 0x010000000000000000;
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_g >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_g)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0xf9a1db44
    /// @custom:signature   Unresolved_f9a1db44(uint256 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_f9a1db44(uint256 arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        return !(!bytes1(storage_map_l[var_d]));
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   unpause() public payable
    function unpause() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(bytes1(store_g)), CustomError_8dfc202b());
        store_g = uint248(store_g);
        emit Event_5db9ee0a(msg.sender);
    }
    
    /// @custom:selector    0x3242edfc
    /// @custom:signature   changeDepositDeadlineOffset(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function changeDepositDeadlineOffset(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_118cdaa7());
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!arg0, CustomError_6a68fb3b());
        store_p = arg0;
    }
    
    /// @custom:selector    0xfda4ba9e
    /// @custom:signature   Unresolved_fda4ba9e(uint256 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_fda4ba9e(uint256 arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        return bytes1(storage_map_l[var_d]);
    }
    
    /// @custom:selector    0xeef20b1b
    /// @custom:signature   Unresolved_eef20b1b(uint256 arg0) public view returns (uint64)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_eef20b1b(uint256 arg0) public view returns (uint64) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        return uint64(storage_map_l[var_d]);
    }
    
    /// @custom:selector    0xc05c0da5
    /// @custom:signature   depositDeadlineOffset() public view returns (uint256)
    function depositDeadlineOffset() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < var_a);
        return store_g;
    }
    
    /// @custom:selector    0x4ce92445
    /// @custom:signature   Unresolved_4ce92445(address arg0, uint64 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_4ce92445(address arg0, uint64 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_5539d97b(var_d); // staticcall
        require(uint64(arg1) == 0, CustomError_e04e5f76());
        require(uint64(arg1) > 0x7080, CustomError_e04e5f76());
        require(!address(arg0).code.length);
        uint64 var_d = uint64(arg1);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_08031eba(var_d); // call
        return ;
        require(((var_e + 0) > 0xffffffffffffffff) | ((var_e + 0) < var_e), CustomError_49e6d35c());
        uint256 var_e = var_e + 0;
        return ;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(uint64(arg1) == var_e.length, CustomError_49e6d35c());
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public returns (uint256) {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(!((arg1 + 0x23) < msg.data.length), CustomError_e07c8dba());
        require(arg1 > 0xffffffffffffffff, CustomError_e07c8dba());
        require(((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) < var_c), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f));
        require(((arg1 + (arg1)) + 0x24) > msg.data.length, CustomError_e07c8dba());
        require(!(0xb1522e3514adfa6cbacd6675378fce03e1b97dd8 == address(this)), CustomError_e07c8dba());
        require(0xb1522e3514adfa6cbacd6675378fce03e1b97dd8 == address(this), CustomError_e07c8dba());
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_h); // staticcall
        var_a = var_a;
        require(var_g - var_a, CustomError_4c9c8ce3());
        require(!address(arg0).code.length, CustomError_4c9c8ce3());
        store_g = (address(arg0)) | (uint96(store_g));
        emit Upgraded(address(arg0));
        require(!var_c.length);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_i); // delegatecall
        require(!ret0.length);
        require(!var_j);
        require(!var_j, CustomError_9996b315());
        require(!var_j, CustomError_9996b315());
        return ;
        require(!address(arg0).code.length, CustomError_9996b315());
        return ;
        require(ret0.length > 0xffffffffffffffff, CustomError_d6bda275());
        require(((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_c), CustomError_d6bda275());
        var_c = var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_c.length, CustomError_d6bda275());
        require(!var_c.length, CustomError_9996b315());
        require(!address(arg0).code.length, CustomError_9996b315());
        return ;
        return ;
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(!(address(store_g) == 0xb1522e3514adfa6cbacd6675378fce03e1b97dd8), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0xda4f0f30
    /// @custom:signature   Unresolved_da4f0f30(address arg0, uint64 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function Unresolved_da4f0f30(address arg0, uint64 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).minConfidenceRatio(); // staticcall
        require(uint64(arg1) == (uint64(var_d)), CustomError_9301988f());
        require(!(!uint64(arg1)), CustomError_9301988f());
        require(uint64(arg1) > 0x2710, CustomError_9301988f());
        require(!address(arg0).code.length);
        uint64 var_e = uint64(arg1);
        (bool success, bytes memory ret0) = address(arg0).{ value: var_d }Unresolved_65de4b2a(var_e); // call
        return ;
        require(((var_f + (uint248(var_d + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248(var_d + 0x1f))) < var_f));
        uint248 var_f = var_f + (uint248(var_d + 0x1f));
        require(var_d);
        return ;
        require(!(uint64(arg1)), CustomError_9301988f());
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint64(var_f.length)));
    }
    
    /// @custom:selector    0x8fdaf71c
    /// @custom:signature   Unresolved_8fdaf71c(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_8fdaf71c(uint256 arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        return abi.encodePacked(address(storage_map_l[var_d]), storage_map_s[var_d]);
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < var_a);
        return !(!bytes1(store_h));
    }
    
    /// @custom:selector    0xc8d60b42
    /// @custom:signature   setVaultImplementation(address arg0, uint8 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["bool", "uint8", "bytes1", "int8"]
    function setVaultImplementation(address arg0, uint8 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (bytes1(arg1)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!address(arg0));
        (bool success, bytes memory ret0) = address(arg0).version(); // staticcall
        require(!(bytes1(arg1) == 0x02), CustomError_3a00a9c3());
        require(!(bytes1(unresolved_655bfd59 >> 0xa0) > (bytes1(var_d))), CustomError_3a00a9c3());
        require(!(bytes1(unresolved_655bfd59 >> 0xa0) > (bytes1(var_d))), CustomError_3a00a9c3());
        require(bytes1(unresolved_655bfd59 >> 0xa0) > (bytes1(var_d)), CustomError_3a00a9c3());
        if (!(arg1) == 0x02) {
            unresolved_655bfd59 = (uint88(unresolved_655bfd59) | (bytes1(var_d << 0xa0))) | (address(arg0));
            emit Event_7b6dbde8(bytes1(arg1), bytes1(var_d));
            return ;
            unresolved_309dfe1b = (uint248(unresolved_309dfe1b)) | (bytes1(var_d << 0xa0));
            vaultImplementation = (uint96(vaultImplementation)) | (address(arg0));
            emit Event_7b6dbde8(bytes1(arg1), bytes1(var_d));
            return ;
            require(!(bytes1(arg1) == 0x02), CustomError_3a00a9c3());
        }
        require(!(bytes1(arg1) == 0x02), CustomError_3a00a9c3());
        require(!(bytes1(var_d) < 0xc8), CustomError_3a00a9c3());
        require(bytes1(var_d) < 0xc8, CustomError_3a00a9c3());
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (var_f.length - (var_f.length)) {
            require(var_f.length - (bytes1(var_f.length)));
        }
    }
    
    /// @custom:selector    0xe12799b1
    /// @custom:signature   initializeUpgrade() public payable returns (uint256)
    function initializeUpgrade() public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < var_a);
        require(!(bytes1(store_h >> 0x40)), CustomError_f92ee8a9());
        require(bytes1(store_h >> 0x40), CustomError_f92ee8a9());
        store_h = (uint192(store_h)) | 0x08;
        unresolved_309dfe1b = (uint248(unresolved_309dfe1b)) | 0x08000000000000000000000000000000000000000000;
        emit Event_1fdc1341(0x08);
        store_h = uint248(store_h);
        emit Initialized(0x08);
        return ;
    }
    
    /// @custom:selector    0x43470ad5
    /// @custom:signature   Unresolved_43470ad5(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_43470ad5(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_118cdaa7());
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(arg0 == unresolved_249b492c, CustomError_274ac08b());
        require(arg0 > 0x0de0b6b3a7640000, CustomError_274ac08b());
        unresolved_249b492c = arg0;
    }
    
    /// @custom:selector    0x1c2a75b9
    /// @custom:signature   Unresolved_1c2a75b9(address arg0, address arg1, uint256 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_1c2a75b9(address arg0, address arg1, uint256 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - arg2);
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(arg2, CustomError_367558c3());
        require(address(arg1) == (address(arg0)), CustomError_367558c3());
        require(((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) < var_f), CustomError_367558c3());
        var_a = keccak256(var_g);
        storage_map_u[var_a] = (bytes1(arg2)) | (uint248(storage_map_u[var_a]));
        return ;
        require(arg2, CustomError_367558c3());
    }
    
    /// @custom:selector    0x1ba28878
    /// @custom:signature   setCollateralPool(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCollateralPool(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        collateralPool = (uint96(collateralPool)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_1e4fbdf7());
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), address(arg0));
        return ;
    }
    
    /// @custom:selector    0xf6e5eb67
    /// @custom:signature   Unresolved_f6e5eb67(uint256 arg0, address arg1, address arg2, uint256 arg3, uint256 arg4, uint256 arg5, uint256 arg6, bool arg7, uint256 arg8, uint256 arg9) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    function Unresolved_f6e5eb67(uint256 arg0, address arg1, address arg2, uint256 arg3, uint256 arg4, uint256 arg5, uint256 arg6, bool arg7, uint256 arg8, uint256 arg9) public view {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x01a0);
        require(0x0180 > (0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length));
        require(arg12 > 0xffffffffffffffff);
        require(!(arg12 + 0x23) < msg.data.length);
        require(arg12 > 0xffffffffffffffff);
        require((((arg12 << 0x05) + arg12) + 0x24) > msg.data.length);
        require(arg10 - arg10);
        require(arg10);
        require(arg8 - arg8);
        require(!arg8, CustomError_61daae86());
        require(arg8, CustomError_61daae86());
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(!(address(weth) == (address(arg1))), CustomError_504e83e7());
        require(address(arg2) == (address(weth)), CustomError_504e83e7());
        require(bytes1(store_g), CustomError_d93c0665());
        require((address(this).balance - msg.value) > address(this).balance);
        require((address(this).balance - msg.value) > address(this).balance);
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(((var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f))) < var_g));
        uint248 var_g = var_g + (uint248((((var_g + 0x20) + 0x28) - var_g) + 0x1f));
        require(arg9 - (bytes1(arg9)));
        require(bytes1(arg9) - 0x01);
        require(!address(vaultImplementation));
        require(arg8 - arg8);
        require(arg8);
        require(!address(collateralPool));
        require(!arg7);
        require(!arg5);
        require(block.timestamp > (block.timestamp + store_v));
        require(!arg3 > (block.timestamp + store_v));
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(arg0)), CustomError_a8c81623());
        require(0 == (!bytes1(storage_map_c[var_k])));
        require(address(storage_map_c[var_k]));
        require(0 == (!uint64(storage_map_c[var_k])));
        require(!bytes1(storage_map_c[var_k]));
        require(((var_g + 0x0260) > 0xffffffffffffffff) | ((var_g + 0x0260) < var_g));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg8, CustomError_dcb70d56());
        require(arg9 - (bytes1(arg9)));
        require(bytes1(arg9) - 0x02, CustomError_e617b5da());
        require(!(address(unresolved_655bfd59)), CustomError_e617b5da());
        require(address(unresolved_467c94ec), CustomError_e617b5da());
    }
    
    /// @custom:selector    0x8d58b216
    /// @custom:signature   setCollateralPoolV2(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setCollateralPoolV2(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        unresolved_467c94ec = (uint96(unresolved_467c94ec)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xdfe15bac
    /// @custom:signature   setMinDepositAmount(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function setMinDepositAmount(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        storage_map_l[var_d] = arg1;
        return ;
    }
    
    /// @custom:selector    0xd17e970d
    /// @custom:signature   Unresolved_d17e970d(address arg0, address arg1, uint64 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint64", "bytes8", "int64"]
    function Unresolved_d17e970d(address arg0, address arg1, uint64 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint64(arg2)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((((var_f + 0x20) + 0x28) - var_f) + 0x1f))) < var_f));
        storage_map_w[var_i] = (uint192(storage_map_w[var_i])) | (uint64(arg2));
        return ;
    }
    
    /// @custom:selector    0x32c3c1b6
    /// @custom:signature   Unresolved_32c3c1b6(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_32c3c1b6(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg0)), CustomError_d92e233d());
        unresolved_309dfe1b = (uint96(unresolved_309dfe1b)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x5b769f3c
    /// @custom:signature   setWETH(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setWETH(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(address(arg0) == (address(weth)), CustomError_d92e233d());
        require(!(address(arg0)), CustomError_d92e233d());
        weth = (uint96(weth)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xbb3696dc
    /// @custom:signature   Unresolved_bb3696dc(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_bb3696dc(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        (bool success, bytes memory ret0) = address(arg0).minDepositAmount(); // staticcall
        require(arg1 == var_d);
        (bool success, bytes memory ret0) = address(arg0).quantity(); // staticcall
        (bool success, bytes memory ret0) = address(arg0).depositTotal(); // staticcall
        require((var_d - var_d) > var_d, CustomError_d54ede0f());
        require(arg1 > (var_d - var_d), CustomError_d54ede0f());
        require(!address(arg0).code.length);
        uint256 var_e = arg1;
        (bool success, bytes memory ret0) = address(arg0).{ value: var_d }Unresolved_8caad7b5(var_e); // call
        return ;
        require(((var_f + (uint248(var_d + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248(var_d + 0x1f))) < var_f));
        uint248 var_f = var_f + (uint248(var_d + 0x1f));
        require(var_d);
        return ;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if ((var_d - var_f.length) > var_d) {
            require((var_d - var_f.length) > var_d, CustomError_e8350c02());
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   pause() public payable returns (uint256)
    function pause() public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < var_a);
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(bytes1(store_h), CustomError_d93c0665());
        store_h = (uint248(store_h)) | 0x01;
        emit Event_62e78cea(msg.sender);
        return ;
    }
    
    /// @custom:selector    0x722ec76f
    /// @custom:signature   minDepositAmount(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function minDepositAmount(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        return storage_map_l[var_d];
    }
    
    /// @custom:selector    0x0ac214df
    /// @custom:signature   deployedVaults(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function deployedVaults(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(!arg0 < getDeployedVaultCount);
        require(!arg0 < getDeployedVaultCount);
        var_a = 0x09;
        return address(storage_map_x[var_a] >> 0);
    }
    
    /// @custom:selector    0xba0bdff0
    /// @custom:signature   getDeployedVaults(uint256 arg0, uint256 arg1) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function getDeployedVaults(uint256 arg0, uint256 arg1) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, CustomError_0f3151d2());
        require(arg0 > (arg0 + arg1), CustomError_0f3151d2());
        require(!((arg0 + arg1) > getDeployedVaultCount), CustomError_0f3151d2());
        require((arg0 + arg1) > getDeployedVaultCount, CustomError_0f3151d2());
        require(arg1 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f));
        require(arg1 > 0xffffffffffffffff);
        require(var_f < arg1);
        require(arg0 > (arg0 + var_f));
        require(!(arg0 + var_f) < getDeployedVaultCount);
        require(!var_f < var_c.length);
        require(var_f < var_c.length);
        return abi.encodePacked(0x20, var_c.length);
        require((getDeployedVaultCount + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > getDeployedVaultCount);
    }
}