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
    uint256 public constant unresolved_f9759518 = 10000;
    uint256 public constant unresolved_305d442e = 10000;
    uint256 public constant unresolved_52d1902d = 3963877391197344453575983046348115674221700746820753546331534351508065746944;
    
    address public unresolved_7656419f;
    address public unresolved_3fc8cef3;
    address public unresolved_8da5cb5b;
    bytes32 store_c;
    address public unresolved_0e5b8c77;
    address store_f;
    address store_g;
    bytes32 store_h;
    
    error CustomError_00000000();
    event Event_bc7cd75a();
    event Event_8be0079c();
    
    /// @custom:selector    0x992ebfc6
    /// @custom:signature   Unresolved_992ebfc6(address arg0, address arg1, uint256 arg2, uint24 arg3, uint256 arg4) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint24", "bytes3", "int24"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function Unresolved_992ebfc6(address arg0, address arg1, uint256 arg2, uint24 arg3, uint256 arg4) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg3 - (uint24(arg3)));
        require(!(!store_c == 0x02), "ReentrancyGuard: reentrant call");
        store_c = 0x02;
        require(arg4 > 0x2710, CustomError_334ee9a1());
        require(!address(arg0));
        require(!address(arg1));
        require(!arg2);
        require(!uint24(arg3));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_b); // staticcall
        address var_c = address(msg.sender);
        uint256 var_a = ((0x60 + (var_h + 0x24)) - var_h) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        require(((var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f))) < var_h) | ((var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f))) > 0xffffffffffffffff), "Address: call to non-contract");
        uint248 var_h = var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f));
        require(((var_h + 0x40) < var_h) | ((var_h + 0x40) > 0xffffffffffffffff), "Address: call to non-contract");
        var_h = var_h + 0x40;
        require(!(address(arg0).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_23b872dd(var_c); // call
        require(!ret0.length);
        require(!var_p);
        require(var_p, "SafeERC20: ERC20 operation did not succeed");
        require(((0x60 + var_p) - 0x60) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_a - var_a, "SafeERC20: ERC20 operation did not succeed");
        require(!var_a, "SafeERC20: ERC20 operation did not succeed");
        require(ret0.length > 0xffffffffffffffff);
        require(((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_h) | ((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff));
        var_h = var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_h.length);
        if (var_h.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(address(arg0)), "Ownable: new owner is the zero address");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0xbb013289
    /// @custom:signature   Unresolved_bb013289(address arg0, address arg1, address arg2, uint256 arg3, uint24 arg4, uint24 arg5, uint256 arg6) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    /// @param              arg5 ["uint24", "bytes3", "int24"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    function Unresolved_bb013289(address arg0, address arg1, address arg2, uint256 arg3, uint24 arg4, uint24 arg5, uint256 arg6) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg4 - (uint24(arg4)));
        require(arg5 - (uint24(arg5)));
        require(!(!store_c == 0x02), "ReentrancyGuard: reentrant call");
        store_c = 0x02;
        require(arg6 > 0x2710, CustomError_334ee9a1());
        require(!address(arg0));
        require(!address(arg1));
        require(!address(arg2));
        require(!arg3);
        require(uint24(arg4));
        require(!uint24(arg5));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_b); // staticcall
        address var_c = address(msg.sender);
        uint256 var_a = ((0x60 + (var_h + 0x24)) - var_h) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        require(((var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f))) < var_h) | ((var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f))) > 0xffffffffffffffff), "Address: call to non-contract");
        uint248 var_h = var_h + (uint248(((0x60 + (var_h + 0x24)) - var_h) + 0x1f));
        require(((var_h + 0x40) < var_h) | ((var_h + 0x40) > 0xffffffffffffffff), "Address: call to non-contract");
        var_h = var_h + 0x40;
        require(!(address(arg0).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_23b872dd(var_c); // call
        require(!ret0.length);
        require(!var_p);
        require(var_p, "SafeERC20: ERC20 operation did not succeed");
        require(((0x60 + var_p) - 0x60) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_a - var_a, "SafeERC20: ERC20 operation did not succeed");
        require(!var_a, "SafeERC20: ERC20 operation did not succeed");
        require(ret0.length > 0xffffffffffffffff);
        require(((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_h) | ((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff));
        var_h = var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_h.length);
        if (var_h.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(!((arg1 + 0x23) < msg.data.length), "Function must be called through delegatecall");
        require(arg1 > 0xffffffffffffffff, "Function must be called through delegatecall");
        require(((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) < var_c) | ((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) > 0xffffffffffffffff), "Function must be called through delegatecall");
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f));
        require(((arg1 + (arg1)) + 0x24) > msg.data.length, "Function must be called through delegatecall");
        require(!(!0x2be0125f8bf3f6e55ea30a9fa3d336030c68b5f5 == address(this)), "Function must be called through delegatecall");
        var_a = var_a;
        require(!(address(store_f) == 0x2be0125f8bf3f6e55ea30a9fa3d336030c68b5f5), "Ownable: caller is not the owner");
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(bytes1(store_f)), "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_g = 0x20;
        store_f = (address(arg0)) | (uint96(store_f));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        var_a = var_a;
        require(var_a - 0, "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_f = (address(arg0)) | (uint96(store_f));
        emit Event_bc7cd75a(address(arg0));
        require(!var_c.length, "Address: delegate call to non-contract");
        require(var_c.length, "Address: delegate call to non-contract");
        require(!address(arg0).code.length, "Address: delegate call to non-contract");
        var_a = var_a;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_k); // delegatecall
        require(!ret0.length, "ERC1967Upgrade: unsupported proxiableUUID");
        require(ret0.length > 0xffffffffffffffff, "ERC1967Upgrade: unsupported proxiableUUID");
        require(((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_c) | ((var_c + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff), "ERC1967Upgrade: unsupported proxiableUUID");
        require(0x01, "ERC1967Upgrade: unsupported proxiableUUID");
        var_a = var_a;
        require(0x20 > ret0.length);
        require(((var_c + 0x20) < var_c) | ((var_c + 0x20) > 0xffffffffffffffff));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        var_a = var_a;
        var_a = var_a;
    }
    
    /// @custom:selector    0x3659cfe6
    /// @custom:signature   Unresolved_3659cfe6(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3659cfe6(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(!0x2be0125f8bf3f6e55ea30a9fa3d336030c68b5f5 == address(this)), "Function must be called through delegatecall");
        var_d = var_d;
        require(!(address(store_g) == 0x2be0125f8bf3f6e55ea30a9fa3d336030c68b5f5), "Ownable: caller is not the owner");
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(((var_g + 0x20) < var_g) | ((var_g + 0x20) > 0xffffffffffffffff), "ERC1967: new implementation is not a contract");
        uint256 var_g = var_g + 0x20;
        require(!(bytes1(store_g)), "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_c = 0x20;
        store_g = (address(arg0)) | (uint96(store_g));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_c); // staticcall
        var_d = var_d;
        var_d = var_d;
        require(var_d - 0, "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_g = (address(arg0)) | (uint96(store_g));
        emit Event_bc7cd75a(address(arg0));
        require(!var_g.length, "Address: delegate call to non-contract");
        require(var_g.length, "Address: delegate call to non-contract");
        require(!address(arg0).code.length, "Address: delegate call to non-contract");
        var_d = var_d;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_l); // delegatecall
        require(!ret0.length);
        require(((var_g + 0x60) < var_g) | ((var_g + 0x60) > 0xffffffffffffffff));
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = var_g + 0x60;
        require(!var_o);
        require(ret0.length > 0xffffffffffffffff, "ERC1967Upgrade: unsupported proxiableUUID");
        var_d = var_d;
        require(0x20 > ret0.length);
        require(((var_g + 0x20) < var_g) | ((var_g + 0x20) > 0xffffffffffffffff));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        var_d = var_d;
        var_d = var_d;
    }
    
    /// @custom:selector    0xc0c53b8b
    /// @custom:signature   Unresolved_c0c53b8b(address arg0, address arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c0c53b8b(address arg0, address arg1, address arg2) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(address(this).code.length, "Initializable: contract is not initializing");
        require(!(bytes1(store_h) == 0x01), "Initializable: contract is not initializing");
        store_h = 0x01 | (uint248(store_h));
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        store_h = 0x0101 | (uint240(store_h));
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_h >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_h >> 0x08)), "Initializable: contract is already initialized");
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable
    function Unresolved_715018a6() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        unresolved_8da5cb5b = uint96(unresolved_8da5cb5b);
        emit Event_8be0079c(address(unresolved_8da5cb5b), 0);
    }
}