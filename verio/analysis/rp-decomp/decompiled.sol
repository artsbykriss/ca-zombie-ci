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
    uint256 public constant unresolved_b60d4288 = ;
    
    address public unresolved_034899bc;
    bytes32 store_a;
    bytes32 store_d;
    bytes32 store_c;
    bytes32 store_e;
    
    event Event_0fdafe3d();
    event Event_4e3e2721();
    event Event_62e78cea();
    event Event_b1d234dd();
    event Event_5db9ee0a();
    event Event_54e46127();
    error CustomError_00000000();
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
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable returns (uint256)
    function Unresolved_715018a6() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(store_a)), CustomError_118cdaa7());
        store_a = uint96(store_a);
        store_a = uint96(store_a);
        emit Event_8be0079c(address(store_a), 0);
        return ;
    }
    
    /// @custom:selector    0x72c27b62
    /// @custom:signature   Unresolved_72c27b62(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_72c27b62(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_02e286cf());
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(arg0 > 0x09c4, CustomError_9bd9ef86());
        store_a = arg0;
        emit Event_0fdafe3d(arg0, store_a);
        return ;
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public payable returns (uint256)
    function Unresolved_79ba5097() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(address(store_a) - msg.sender, CustomError_118cdaa7());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
        return ;
    }
    
    /// @custom:selector    0x6e9960c3
    /// @custom:signature   Unresolved_6e9960c3() public view returns (address)
    function Unresolved_6e9960c3() public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x2c928098
    /// @custom:signature   Unresolved_2c928098() public view returns (uint256)
    function Unresolved_2c928098() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return store_a;
    }
    
    /// @custom:selector    0x47e25d93
    /// @custom:signature   Unresolved_47e25d93() public payable
    function Unresolved_47e25d93() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_d7e6bcf8());
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
        store_a = 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = 0x010000000000000001 | (uint184(store_a));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_a)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public payable returns (uint256)
    function Unresolved_3f4ba83a() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(!(bytes1(store_a)), CustomError_8dfc202b());
        store_a = uint248(store_a);
        emit Event_5db9ee0a(msg.sender);
        return ;
    }
    
    /// @custom:selector    0xe30c3978
    /// @custom:signature   Unresolved_e30c3978() public view returns (address)
    function Unresolved_e30c3978() public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x704b6c02
    /// @custom:signature   Unresolved_704b6c02(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_704b6c02(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(store_a)), CustomError_118cdaa7());
        store_a = (address(arg0)) | (uint96(store_a));
        emit Event_54e46127(address(arg0));
        return ;
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
    
    /// @custom:selector    0x372500ab
    /// @custom:signature   Unresolved_372500ab() public payable
    function Unresolved_372500ab() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(store_a == 0x02, CustomError_3ee5aeb5());
        store_a = 0x02;
        (bool success, bytes memory ret0) = address(unresolved_034899bc).Unresolved_f8ea4756(var_c); // staticcall
        require(msg.sender - 0, CustomError_8622fd9d());
        address var_c = address(this);
        (bool success, bytes memory ret0) = address(unresolved_034899bc).Unresolved_3e323df2(var_c); // staticcall
        (bool success, bytes memory ret0) = address(unresolved_034899bc).Unresolved_61d027b3(var_c); // staticcall
        require(!(((address(this).balance * store_a) / address(this).balance == store_a) | !address(this).balance), CustomError_a3c0499c());
        (bool success, bytes memory ret0) = address(0).transfer((address(this).balance * store_a) / 0x2710);
        require(!ret0.length, CustomError_a3c0499c());
        (bool success, bytes memory ret0) = address(0).Unresolved_14a6bf0f(var_c); // staticcall
        require(0);
        require(!0 > address(this).balance);
        require(!address(0).code.length);
        (bool success, bytes memory ret0) = address(0).{ value: address(this).balance }Unresolved_b60d4288(var_c); // call
        require(store_a > (store_a + address(this).balance));
        require(((var_f + 0) > 0xffffffffffffffff) | ((var_f + 0) < var_f));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length);
        require(!var_f.length > address(this).balance);
        require(!address(0).code.length);
        if (ret0.length > 0xffffffffffffffff) {
            if (((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_f)) {
                if (0x20 > ret0.length) {
                }
                if (0x20 > ret0.length) {
                }
                if (0x20 > ret0.length) {
                }
            }
        }
    }
    
    /// @custom:selector    0x5e3e244e
    /// @custom:signature   Unresolved_5e3e244e(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5e3e244e(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        unresolved_034899bc = (address(arg0)) | (uint96(unresolved_034899bc));
        emit Event_4e3e2721(address(arg0));
        return ;
    }
    
    /// @custom:selector    0x0572b0cc
    /// @custom:signature   Unresolved_0572b0cc() public view returns (uint256)
    function Unresolved_0572b0cc() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(this).balance;
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public payable returns (uint256)
    function Unresolved_8456cb59() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        require(bytes1(store_a), CustomError_d93c0665());
        store_a = (uint248(store_a)) | 0x01;
        emit Event_62e78cea(msg.sender);
        return ;
    }
    
    /// @custom:selector    0x8da5cb5b
    /// @custom:signature   Unresolved_8da5cb5b() public view returns (address)
    function Unresolved_8da5cb5b() public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x973f8e56
    /// @custom:signature   Unresolved_973f8e56() public view returns (uint256)
    function Unresolved_973f8e56() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return store_a;
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        return !(!bytes1(store_a));
    }
}