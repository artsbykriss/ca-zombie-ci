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
    uint256 public constant unresolved_52d1902d = 3963877391197344453575983046348115674221700746820753546331534351508065746944;
    uint256 public constant unresolved_a0417bad = 601794791842136495730929048765528302211266341225;
    bytes public constant unresolved_f7c618c1 = 0xBytes([0]);
    
    address public unresolved_ba19131e;
    address store_k;
    address public unresolved_0e5b8c77;
    bytes32 store_n;
    address public unresolved_8da5cb5b;
    bytes32 store_b;
    address public unresolved_db5537e1;
    address public unresolved_7656419f;
    uint24 public unresolved_6d5f2b56;
    uint256 public unresolved_ddca3f43;
    address public unresolved_d4f35989;
    address public unresolved_39b70e38;
    address public unresolved_c55dae63;
    address store_i;
    
    error CustomError_00000000();
    event Event_bc7cd75a();
    event Event_8be0079c();
    
    /// @custom:selector    0x1c4b774b
    /// @custom:signature   Unresolved_1c4b774b(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_1c4b774b(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "ReentrancyGuard: reentrant call");
        require(!(!store_b == 0x02), "ReentrancyGuard: reentrant call");
        var_b = 0x20;
        store_b = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_d770adc7(var_b); // staticcall
        require(0, CustomError_44279255());
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_a701fe3d(var_b); // staticcall
        require(msg.sender - 0, CustomError_8084e5d1());
        require(arg0 > 0x2710, CustomError_334ee9a1());
        require(arg0 > 0x012c, CustomError_334ee9a1());
        require(((var_f + 0x40) < var_f) | ((var_f + 0x40) > 0xffffffffffffffff));
        uint256 var_f = var_f + 0x40;
        require(!var_f.length);
        address var_d = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).{ value: 0 ether }Unresolved_6b091695(var_d); // call
        if (var_f.length > 0xffffffffffffffff) {
            if (((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) < var_f) | ((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) > 0xffffffffffffffff)) {
                if (0x20 > ret0.length) {
                }
                require(var_f.length > 0xffffffffffffffff);
            }
            require(((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) < var_f) | ((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) > 0xffffffffffffffff));
        }
    }
    
    /// @custom:selector    0xe2c67439
    /// @custom:signature   Unresolved_e2c67439() public payable returns (uint256)
    function Unresolved_e2c67439() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_70a08231(var_b); // staticcall
        var_b = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_a4dbda3c(var_b); // staticcall
        require(0 > 0);
        require(!0);
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_833b1fce(var_b); // staticcall
        require(!0);
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_0dfe1681(var_b); // staticcall
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_d21220a7(var_b); // staticcall
        (bool success, bytes memory ret0) = address(0).Unresolved_313ce567(var_b); // staticcall
        (bool success, bytes memory ret0) = address(0).Unresolved_313ce567(var_b); // staticcall
        require(!(0 > 0x12), CustomError_4cfe69bd());
        require(0 > 0x12, CustomError_4cfe69bd());
        require(0 > 0x4d);
        var_b = 0;
        (bool success, bytes memory ret0) = address(0).Unresolved_87edbb8d(var_b); // staticcall
        require(0 > 0x4d);
        var_b = 0;
        (bool success, bytes memory ret0) = address(0).Unresolved_87edbb8d(var_b); // staticcall
        require(0, CustomError_4cfe69bd());
        require(!0, CustomError_4cfe69bd());
        require(0 > 0x4d, CustomError_4cfe69bd());
        require(!((0 == 0x01) | !0), CustomError_4cfe69bd());
        require(0x20 > ret0.length);
        require(((var_f + 0x20) < var_f) | ((var_f + 0x20) > 0xffffffffffffffff));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(0, CustomError_4cfe69bd());
        require(!var_f.length, CustomError_4cfe69bd());
        require(0 > 0x4d, CustomError_4cfe69bd());
        require(!((0 == 0x01) | !0), CustomError_4cfe69bd());
        require(!0, CustomError_4cfe69bd());
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        return 0;
        if (0x20 > ret0.length) {
        }
        return 0;
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x82b2e257
    /// @custom:signature   Unresolved_82b2e257() public payable returns (uint256)
    function Unresolved_82b2e257() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_70a08231(var_b); // staticcall
        var_b = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_a4dbda3c(var_b); // staticcall
        require(0 > 0);
        uint256 var_a = 0;
        return 0;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) < var_e) | ((var_e + 0x20) > 0xffffffffffffffff));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        if ((0 - var_e.length) > 0) {
            return var_a - var_e.length;
            if (0x20 > ret0.length) {
            }
        }
    }
    
    /// @custom:selector    0xe4a4b7b1
    /// @custom:signature   Unresolved_e4a4b7b1(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_e4a4b7b1(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, "ReentrancyGuard: reentrant call");
        require(!(!store_b == 0x02), "ReentrancyGuard: reentrant call");
        var_b = 0x20;
        store_b = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_d770adc7(var_b); // staticcall
        require(0, CustomError_44279255());
        require(arg0 > 0x2710, CustomError_334ee9a1());
        require(!msg.sender == (address(unresolved_39b70e38)));
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_a701fe3d(var_b); // staticcall
        require(!(msg.sender == 0), CustomError_d5b69543());
        require(arg0 > 0x012c, CustomError_334ee9a1());
        require(((var_f + 0x40) < var_f) | ((var_f + 0x40) > 0xffffffffffffffff));
        uint256 var_f = var_f + 0x40;
        require(!var_f.length);
        address var_d = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).{ value: 0 ether }Unresolved_6b091695(var_d); // call
        if (var_f.length > 0xffffffffffffffff) {
            if (((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) < var_f) | ((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) > 0xffffffffffffffff)) {
                if (0x20 > ret0.length) {
                }
                require(var_f.length > 0xffffffffffffffff);
            }
            require(((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) < var_f) | ((var_f + (uint248((0x20 + (var_f.length << 0x05)) + 0x1f))) > 0xffffffffffffffff));
        }
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable returns (uint256) {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(!((arg1 + 0x23) < msg.data.length), "Function must be called through delegatecall");
        require(arg1 > 0xffffffffffffffff, "Function must be called through delegatecall");
        require(((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) < var_c) | ((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) > 0xffffffffffffffff), "Function must be called through delegatecall");
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f));
        require(((arg1 + (arg1)) + 0x24) > msg.data.length, "Function must be called through delegatecall");
        require(!(!0xc6865dc8549a986ef02b1b72e2507ec9b5f8180e == address(this)), "Function must be called through delegatecall");
        var_a = var_a;
        require(!(address(store_i) == 0xc6865dc8549a986ef02b1b72e2507ec9b5f8180e), "Ownable: caller is not the owner");
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(bytes1(store_i)), "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_g = 0x20;
        store_i = (address(arg0)) | (uint96(store_i));
        return ;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        var_a = var_a;
        require(var_a - 0, "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_i = (address(arg0)) | (uint96(store_i));
        emit Event_bc7cd75a(address(arg0));
        require(!var_c.length, "Address: delegate call to non-contract");
        require(var_c.length, "Address: delegate call to non-contract");
        require(!address(arg0).code.length, "Address: delegate call to non-contract");
        var_a = var_a;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_k); // delegatecall
        if (!ret0.length) {
        }
        return ;
        require(0x01, "ERC1967Upgrade: unsupported proxiableUUID");
        return ;
        var_a = var_a;
        require(0x20 > ret0.length);
        require(((var_c + 0x20) < var_c) | ((var_c + 0x20) > 0xffffffffffffffff));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        var_a = var_a;
        var_a = var_a;
    }
    
    /// @custom:selector    0x3659cfe6
    /// @custom:signature   Unresolved_3659cfe6(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3659cfe6(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(!0xc6865dc8549a986ef02b1b72e2507ec9b5f8180e == address(this)), "Function must be called through delegatecall");
        var_d = var_d;
        require(!(address(store_k) == 0xc6865dc8549a986ef02b1b72e2507ec9b5f8180e), "Ownable: caller is not the owner");
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(((var_g + 0x20) < var_g) | ((var_g + 0x20) > 0xffffffffffffffff), "ERC1967: new implementation is not a contract");
        uint256 var_g = var_g + 0x20;
        require(!(bytes1(store_k)), "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_c = 0x20;
        store_k = (address(arg0)) | (uint96(store_k));
        return ;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_c); // staticcall
        var_d = var_d;
        require(0xc9f76b5ec45e5cdef99837d7b6d2467235c1df8933c8ca56df5c35afa2c7d444, "ERC1967: new implementation is not a contract");
        require(!address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_k = (address(arg0)) | (uint96(store_k));
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
        return ;
        require(ret0.length > 0xffffffffffffffff, "ERC1967Upgrade: unsupported proxiableUUID");
        return ;
        var_d = var_d;
        require(0x20 > ret0.length);
        require(((var_g + 0x20) < var_g) | ((var_g + 0x20) > 0xffffffffffffffff));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        var_d = var_d;
        var_d = var_d;
    }
    
    /// @custom:selector    0x5c966646
    /// @custom:signature   Unresolved_5c966646(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5c966646(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(address(arg0)), CustomError_e6c4247b());
        unresolved_39b70e38 = (uint96(unresolved_39b70e38)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x9012c4a8
    /// @custom:signature   Unresolved_9012c4a8(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_9012c4a8(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(arg0 > 0xffffff), CustomError_58d620b3());
        require(arg0 > 0xffffff, CustomError_58d620b3());
        unresolved_ddca3f43 = arg0;
        return ;
        require(!arg0, CustomError_58d620b3());
        unresolved_ddca3f43 = arg0;
        return ;
    }
    
    /// @custom:selector    0xcd8b5907
    /// @custom:signature   Unresolved_cd8b5907(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function Unresolved_cd8b5907(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x80, CustomError_d5b69543());
        require(0x40 > (0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length), CustomError_d5b69543());
        require(((var_a + 0x40) < var_a) | ((var_a + 0x40) > 0xffffffffffffffff), CustomError_d5b69543());
        uint256 var_a = var_a + 0x40;
        uint256 var_d = arg0;
        require(msg.sender - (address(unresolved_39b70e38)), CustomError_d5b69543());
        require(!(!store_b == 0x02), "ReentrancyGuard: reentrant call");
        var_g = 0x20;
        store_b = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_d770adc7(var_g); // staticcall
        require(0, CustomError_44279255());
        require(arg2 > 0x2710, CustomError_334ee9a1());
        require(arg3 > 0x2710, CustomError_334ee9a1());
        address var_g = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_70a08231(var_g); // staticcall
        var_g = address(this);
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).Unresolved_a4dbda3c(var_g); // staticcall
        require(0 > 0);
        require(!var_j);
        require(!address(unresolved_ba19131e).code.length);
        var_g = var_j;
        (bool success, bytes memory ret0) = address(unresolved_ba19131e).{ value: 0 ether }Unresolved_2e1a7d4d(var_g); // call
        var_g = address(this);
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_70a08231(var_g); // staticcall
        require(!0);
        require(!var_j);
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_1322d954(var_g); // staticcall
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_18160ddd(var_g); // staticcall
        address var_h = address(unresolved_d4f35989);
        uint256 var_i = 0;
        require(((var_a + 0x80) < var_a) | ((var_a + 0x80) > 0xffffffffffffffff), "Address: call to non-contract");
        var_a = var_a + 0x80;
        require(((var_a + 0x40) < var_a) | ((var_a + 0x40) > 0xffffffffffffffff), "Address: call to non-contract");
        var_a = var_a + 0x40;
        require(!(address(unresolved_db5537e1).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).{ value: var_i ether }Unresolved_095ea7b3(var_h); // call
        require(!ret0.length);
        require(!var_r);
        require(var_r);
        require((((0x60 + var_r) + 0x20) - 0x80) < 0x20);
        require(var_d - var_d);
        require(!var_d);
        require(var_j);
        address var_o = address(this);
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_dd62ed3e(var_o); // staticcall
        require(0, "SafeERC20: approve from non-zero to non-zero allowance");
        require(0x20 > ret0.length);
        require(((var_a + 0x20) < var_a) | ((var_a + 0x20) > 0xffffffffffffffff));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length, "SafeERC20: approve from non-zero to non-zero allowance");
        require(ret0.length > 0xffffffffffffffff);
        require(((var_a + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_a) | ((var_a + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff));
        var_a = var_a + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_a.length);
        if (var_a.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x40 > ret0.length) {
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
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(address(arg0)), "Ownable: new owner is the zero address");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(address(unresolved_8da5cb5b), address(arg0));
        return ;
    }
    
    /// @custom:selector    0x27bed8ee
    /// @custom:signature   Unresolved_27bed8ee(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_27bed8ee(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "ReentrancyGuard: reentrant call");
        require(!(!store_b == 0x02), "ReentrancyGuard: reentrant call");
        var_b = 0x20;
        store_b = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_d770adc7(var_b); // staticcall
        require(0, CustomError_44279255());
        require(!msg.sender == (address(unresolved_39b70e38)));
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_a701fe3d(var_b); // staticcall
        require(!msg.sender == 0);
        address var_b = msg.sender;
        (bool success, bytes memory ret0) = address(unresolved_7656419f).Unresolved_315a5755(var_b); // staticcall
        require(!0);
        require(!arg0);
        require(((var_f + 0x60) < var_f) | ((var_f + 0x60) > 0xffffffffffffffff));
        uint256 var_f = var_f + 0x60;
        var_a = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_0dfe1681(var_j); // staticcall
        (bool success, bytes memory ret0) = address(unresolved_db5537e1).Unresolved_d21220a7(var_j); // staticcall
        address var_j = address(this);
        (bool success, bytes memory ret0) = address(0).Unresolved_70a08231(var_j); // staticcall
        require(!var_f.length);
        uint256 var_k = 0;
        var_j = address(this);
        (bool success, bytes memory ret0) = address(0).Unresolved_70a08231(var_j); // staticcall
        address var_n = address(msg.sender);
        require(((var_f + (uint248(((0x60 + (var_f + 0x24)) - var_f) + 0x1f))) < var_f) | ((var_f + (uint248(((0x60 + (var_f + 0x24)) - var_f) + 0x1f))) > 0xffffffffffffffff), "Address: call to non-contract");
        var_f = var_f + (uint248(((0x60 + (var_f + 0x24)) - var_f) + 0x1f));
        require(((var_f + 0x40) < var_f) | ((var_f + 0x40) > 0xffffffffffffffff), "Address: call to non-contract");
        var_f = var_f + 0x40;
        require(!(address(unresolved_c55dae63).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(unresolved_c55dae63).{ value: var_k ether }Unresolved_23b872dd(var_n); // call
        require(!ret0.length);
        require(!var_w);
        require(var_w, "SafeERC20: ERC20 operation did not succeed");
        require((((0x60 + var_w) + 0x20) - 0x80) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_a - var_a, "SafeERC20: ERC20 operation did not succeed");
        require(!var_a, "SafeERC20: ERC20 operation did not succeed");
        require(ret0.length > 0xffffffffffffffff);
        require(((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_f) | ((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff));
        var_f = var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_f.length);
        if (var_f.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        require(!(msg.sender == 0), CustomError_d5b69543());
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xc5907c3b
    /// @custom:signature   Unresolved_c5907c3b() public payable returns (uint256)
    function Unresolved_c5907c3b() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        unresolved_6d5f2b56 = uint48(unresolved_6d5f2b56);
        return ;
    }
    
    /// @custom:selector    0x87674dea
    /// @custom:signature   Unresolved_87674dea(address arg0, uint24 arg1, uint24 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint24", "bytes3", "int24"]
    /// @param              arg2 ["uint24", "bytes3", "int24"]
    function Unresolved_87674dea(address arg0, uint24 arg1, uint24 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint24(arg1)));
        require(arg2 - (uint24(arg2)));
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        require(!(address(arg0)), CustomError_58d620b3());
        require(!(!uint24(arg1)), CustomError_58d620b3());
        require(!(uint24(arg2)), CustomError_58d620b3());
        unresolved_6d5f2b56 = (uint24(arg1 << 0xa0) | (uint48(unresolved_6d5f2b56) | (address(arg0)))) | (uint24(arg2 << 0xb8));
        return ;
    }
    
    /// @custom:selector    0x1460e390
    /// @custom:signature   Unresolved_1460e390(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1460e390(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (address(arg4)));
        require(arg5 - (address(arg5)));
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(address(this).code.length, "Initializable: contract is not initializing");
        require(!(bytes1(store_n) == 0x01), "Initializable: contract is not initializing");
        store_n = 0x01 | (uint248(store_n));
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        store_b = 0x01;
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        store_n = 0x0101 | (uint240(store_n));
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        store_b = 0x01;
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_n >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_n >> 0x08)), "Initializable: contract is already initialized");
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable returns (uint256)
    function Unresolved_715018a6() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(unresolved_8da5cb5b)), "Ownable: caller is not the owner");
        unresolved_8da5cb5b = uint96(unresolved_8da5cb5b);
        emit Event_8be0079c(address(unresolved_8da5cb5b), 0);
        return ;
    }
}