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
    bytes public constant unresolved_b60d4288 = ;
    
    address public unresolved_034899bc;
    bytes32 store_a;
    bytes32 store_d;
    bytes32 store_c;
    bytes32 store_e;
    bytes32 store_f;
    
    event Event_54e46127();
    event Event_4e3e2721();
    event Event_62e78cea();
    event Event_38d16b8c();
    event Event_5db9ee0a();
    event Event_db4ea3a7();
    event Event_be808664();
    error CustomError_00000000();
    event Event_d1ecb6c4();
    event Event_030a01aa();
    event Event_8be0079c();
    
    /// @custom:selector    0x788bc78c
    /// @custom:signature   Unresolved_788bc78c(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_788bc78c(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((arg0 + (arg0)) + 0x24) > msg.data.length, CustomError_02e286cf());
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        if (arg0 > 0xffffffffffffffff) {
            require(arg0 > 0xffffffffffffffff);
            uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f));
            require(((var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f))) < var_c));
            var_c = var_c + 0x60;
            require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
            require(!var_c.length);
        }
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return !(!bytes1(store_a));
    }
    
    /// @custom:selector    0xf00e6a2a
    /// @custom:signature   Unresolved_f00e6a2a() public view returns (uint256)
    function Unresolved_f00e6a2a() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return store_a;
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public payable
    function Unresolved_79ba5097() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(address(store_a) - msg.sender, CustomError_118cdaa7());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
    }
    
    /// @custom:selector    0x6e9960c3
    /// @custom:signature   Unresolved_6e9960c3() public view returns (address)
    function Unresolved_6e9960c3() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(store_a)), CustomError_118cdaa7());
        store_a = (address(arg0)) | (uint96(store_a));
        emit Event_38d16b8c(address(store_a), address(arg0));
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public payable
    function Unresolved_3f4ba83a() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(!(bytes1(store_a)), CustomError_8dfc202b());
        store_a = uint248(store_a);
        emit Event_5db9ee0a(msg.sender);
    }
    
    /// @custom:selector    0x77b34927
    /// @custom:signature   Unresolved_77b34927() public payable
    function Unresolved_77b34927() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, CustomError_d7e6bcf8());
        require(!(uint64(store_a)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_a)), CustomError_d7e6bcf8());
        require(!(!uint64(store_a)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_a = 0x01 | (uint192(store_a));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_c = 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = 0x010000000000000001 | (uint184(store_a));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_c = 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_a)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0x704b6c02
    /// @custom:signature   Unresolved_704b6c02(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_704b6c02(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(store_a)), CustomError_118cdaa7());
        store_a = (address(arg0)) | (uint96(store_a));
        emit Event_54e46127(address(arg0));
    }
    
    /// @custom:selector    0x0d8e6e2c
    /// @custom:signature   Unresolved_0d8e6e2c() public view
    function Unresolved_0d8e6e2c() public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        if (((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a)) {
            uint256 var_a = var_a + 0x60;
            if (!var_a.length < 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) {
                if (!(var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) < 0x04ee2d6d415b85acef8100000000) {
                    if (!((var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) < 0x2386f26fc10000) {
                        if (!(((var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) < 0x05f5e100) {
                            if (!((((var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) < 0x2710) {
                                if (!(((((var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) / 0x2710) < 0x64) {
                                    if (!((((((var_a.length / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) / 0x2710) / 0x64) < 0x0a) {
                                        if (0x80 > 0xffffffffffffffff) {
                                            if (((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a)) {
                                                var_a = var_a + 0xa0;
                                                if (0x80 > 0xffffffffffffffff) {
                                                    var_h = msg.data[4:132];
                                                    if (!var_a.length / 0x0a) {
                                                        if (!(var_h) < 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) {
                                                            if (!(var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) < 0x04ee2d6d415b85acef8100000000) {
                                                                if (!((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) < 0x2386f26fc10000) {
                                                                    if (!(((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) < 0x05f5e100) {
                                                                        if (!((((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) < 0x2710) {
                                                                            if (!(((((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) / 0x2710) < 0x64) {
                                                                                if (!((((((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) / 0x2710) / 0x64) < 0x0a) {
                                                                                    if (0x80 > 0xffffffffffffffff) {
                                                                                        if (((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a)) {
                                                                                            if (0x80 > 0xffffffffffffffff) {
                                                                                                var_h = msg.data[4:132];
                                                                                                if (!(var_h) / 0x0a) {
                                                                                                }
                                                                                                if (!(((((var_h / 0x184f03e93ff9f4daa797ed6e38ed64bf6a1f010000000000000000) / 0x04ee2d6d415b85acef8100000000) / 0x2386f26fc10000) / 0x05f5e100) / 0x2710) < 0x0a) {
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x09978854
    /// @custom:signature   Unresolved_09978854(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_09978854(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_034899bc)), CustomError_1e22798e());
        require(!(!address(arg0)), CustomError_5f5df31d());
        require(!(!(address(arg0)) == address(this)), CustomError_5f5df31d());
        store_a = (address(arg0)) | (uint96(store_a));
        emit Event_be808664(address(arg0), store_a);
    }
    
    /// @custom:selector    0x775a25e3
    /// @custom:signature   Unresolved_775a25e3() public view returns (uint256)
    function Unresolved_775a25e3() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(this).balance;
    }
    
    /// @custom:selector    0x379607f5
    /// @custom:signature   Unresolved_379607f5(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_379607f5(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_143abd98());
        require(msg.sender - (address(store_a)), CustomError_143abd98());
        require(!(!arg0 > address(this).balance), CustomError_03eb8b54());
        (bool success, bytes memory ret0) = address(msg.sender).transfer(arg0);
        require(!ret0.length, CustomError_1c43b976());
        emit Event_d1ecb6c4(msg.sender, arg0);
        require(ret0.length > 0xffffffffffffffff);
        require(((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_f));
    }
    
    /// @custom:selector    0x5e3e244e
    /// @custom:signature   Unresolved_5e3e244e(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5e3e244e(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        unresolved_034899bc = (address(arg0)) | (uint96(unresolved_034899bc));
        emit Event_4e3e2721(address(arg0));
    }
    
    /// @custom:selector    0x14a6bf0f
    /// @custom:signature   Unresolved_14a6bf0f() public view returns (uint256)
    function Unresolved_14a6bf0f() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        if (!store_a > address(this).balance) {
            if ((store_a - address(this).balance) > store_a) {
                return store_a - address(this).balance;
                return 0;
            }
        }
    }
    
    /// @custom:selector    0xb480eac0
    /// @custom:signature   Unresolved_b480eac0(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_b480eac0(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_02e286cf());
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(!arg0, CustomError_f63f18ef());
        store_a = arg0;
        emit Event_be808664(address(store_a), arg0);
    }
    
    /// @custom:selector    0xe30c3978
    /// @custom:signature   Unresolved_e30c3978() public view returns (address)
    function Unresolved_e30c3978() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x2e1a7d4d
    /// @custom:signature   Unresolved_2e1a7d4d(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_2e1a7d4d(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_02e286cf());
        require(!(msg.sender == (address(store_a))), CustomError_02e286cf());
        require(!(!arg0 > address(this).balance), CustomError_03eb8b54());
        (bool success, bytes memory ret0) = address(msg.sender).transfer(arg0);
        require(!ret0.length, CustomError_1c43b976());
        emit Event_030a01aa(msg.sender, arg0);
        require(ret0.length > 0xffffffffffffffff);
        require(((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_f));
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public payable
    function Unresolved_8456cb59() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(bytes1(store_a), CustomError_d93c0665());
        store_a = (uint248(store_a)) | 0x01;
        emit Event_62e78cea(msg.sender);
    }
    
    /// @custom:selector    0x8da5cb5b
    /// @custom:signature   Unresolved_8da5cb5b() public view returns (address)
    function Unresolved_8da5cb5b() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable
    function Unresolved_715018a6() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(msg.sender - (address(store_a)), CustomError_118cdaa7());
        store_a = uint96(store_a);
        store_a = uint96(store_a);
        emit Event_8be0079c(address(store_a), 0);
    }
}