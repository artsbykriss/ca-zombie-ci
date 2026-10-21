// Decompiled WithdrawalPool implementation 0x8512Eed984234e197F8b32ef8f589E6eEb8Bc9e2
// Source: heimdall-rs v0.9.2, `heimdall decompile 0x8512... --include-sol --skip-resolving`
// Story mainnet (chainId 1514), proxy 0x2a7935E926C65Ef2671D5807760e2421adf992d8 (v2.0.0)
//
// IMPORTANT: this decompilation is LOSSY. Variable/storage names are aliased across
// functions and some branches are rendered as `require(...)` incorrectly. It is used
// here only to recover the ABI and to locate the handleBalance/withdraw control flow;
// the destination of handleBalance() surplus was settled dynamically on an anvil fork
// (call trace in analysis/handleBalance-trace.txt), not from this text.
//
// Key recovered selectors:
//   0x3428d8ea addWithdrawal(address,uint256,uint256)   onlyStakePool
//   0x5600231a handleBalance()                          onlyAdminOrStakePool
//   0x3ccfd60b withdraw()                               self-service claim
//   0xb60d4288 fund()                                   payable
//   0x10877ac1 getTotalPendingWithdrawals()
//   0xf126044e getTotalWithdrawalPool()                 address(this).balance
//   0x14a6bf0f (insurance pool) remaining capacity      (25,000 IP cap - balance)
//
// handleBalance() (from trace, exact):
//   reads selector.stakePool(), selector.insurancePoolByComponent(this),
//   insurancePool.remainingCapacity(), stakePool.getUnstaked(),
//   computes surplus = address(this).balance - totalPendingWithdrawals - getUnstaked(),
//   then calls insurancePool.fund{value: min(surplus, capacity)}().
//   It NEVER calls the StakePool and never increases the StakePool balance.

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
    
    uint256 store_b;
    bytes32 store_d;
    bytes32 store_a;
    bytes32 store_c;
    uint256 store_e;
    mapping(bytes32 => bytes32) storage_map_f;
    uint256 storage_map_i[storage_map_f[var_a] << 0x01];
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_i;
    address storage_map_j[(storage_map_f[var_a] << 0x01) + keccak256(var_a)];
    mapping(bytes32 => bytes32) storage_map_j;
    
    event Event_54e46127();
    event Event_4e3e2721();
    event Event_62e78cea();
    error CustomError_00000000();
    event Event_5db9ee0a();
    event Event_6a32d7cc();
    event Event_d3f990dd();
    event Event_89939b31();
    event Event_8be0079c();
    
    /// @custom:selector    0x788bc78c
    /// @custom:signature   Unresolved_788bc78c(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_788bc78c(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((arg0 + (arg0)) + 0x24) > msg.data.length, CustomError_02e286cf());
        require(!(msg.sender == (address(store_a))), CustomError_02e286cf());
        require(arg0 > 0xffffffffffffffff, CustomError_a9146eeb());
        require(((var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f))) < var_c), CustomError_a9146eeb());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg0))) + 0x1f));
        uint256 var_d = (arg0);
        require((0x24 + arg0) + var_d > msg.data.length, CustomError_a9146eeb());
        var_e = msg.data[36:36];
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), CustomError_a9146eeb());
        var_c = var_c + 0x60;
        require(!var_c.length, CustomError_a9146eeb());
        require(bytes1(var_i) == 0x7600000000000000000000000000000000000000000000000000000000000000, CustomError_a9146eeb());
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), CustomError_a9146eeb());
        var_c = var_c + 0x60;
        require(bytes1(var_m) == 0x2e00000000000000000000000000000000000000000000000000000000000000, CustomError_a9146eeb());
        require(0, CustomError_a9146eeb());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_a9146eeb());
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_a9146eeb());
        require((bytes1(var_m >> 0xf8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd0) > 0xff, CustomError_a9146eeb());
        require(bytes1((var_m >> 0xf8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd0) > 0x09, CustomError_a9146eeb());
        require(!(!0 | (0x0a == 0)), CustomError_a9146eeb());
        require(0 > (0 + (bytes1((var_m >> 0xf8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd0))), CustomError_a9146eeb());
        require(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe, CustomError_a9146eeb());
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c), CustomError_a9146eeb());
        var_c = var_c + 0x60;
        require(var_c.length - var_c.length, CustomError_a9146eeb());
        require(!(var_c.length < var_c.length), CustomError_a9146eeb());
        store_b = var_c.length;
        store_c = var_e;
        store_d = var_q;
        store_e = block.timestamp;
        var_r = msg.data[36:36];
        emit Event_6a32d7cc(keccak256(var_r));
        if (var_e - (var_e)) {
            require(var_e - (var_e), CustomError_a9146eeb());
        }
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return !(!bytes1(store_a));
    }
    
    /// @custom:selector    0x451979e7
    /// @custom:signature   Unresolved_451979e7(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_451979e7(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(address(arg0) - arg0);
        var_a = var_a;
        require(storage_map_f[var_a] > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f))) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        address var_d = var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f));
        var_a = keccak256(var_a);
        require(0 < storage_map_f[var_a]);
        require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d));
        return abi.encodePacked(0x20, var_d.length);
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
    
    /// @custom:selector    0x034899bc
    /// @custom:signature   Unresolved_034899bc() public view returns (address)
    function Unresolved_034899bc() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x3ccfd60b
    /// @custom:signature   Unresolved_3ccfd60b() public payable
    function Unresolved_3ccfd60b() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(store_a == 0x02, CustomError_3ee5aeb5());
        store_a = 0x02;
        require(bytes1(store_a), CustomError_d93c0665());
        var_a = var_a;
        require(!storage_map_f[var_a]);
        require(!0 < storage_map_f[var_a]);
        require(!0 < storage_map_f[var_a]);
        var_a = keccak256(var_a);
        require(!(storage_map_g[0 + keccak256(var_a)]) > block.timestamp);
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0 < storage_map_f[var_a]);
        var_a = keccak256(var_a);
        require(0 > (0 + (storage_map_h[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((storage_map_f[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_f[var_a]);
        require(!0);
        require(0 > address(this).balance);
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(store_a).Unresolved_3e323df2(var_e); // staticcall
        require((0 - address(this).balance) > 0);
        require(!address(0).code.length);
        var_e = 0 - address(this).balance;
        (bool success, bytes memory ret0) = address(0).Unresolved_379607f5(var_e); // call
        require((store_a - 0) > store_a, CustomError_1c43b976());
        store_a = store_a - 0;
        emit Event_d3f990dd(msg.sender, 0);
        (bool success, bytes memory ret0) = address(msg.sender).transfer(0);
        require(!ret0.length, CustomError_1c43b976());
        store_a = 0x01;
        if (ret0.length > 0xffffffffffffffff) {
            require(ret0.length > 0xffffffffffffffff, CustomError_55c301aa());
            require(((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_h), CustomError_55c301aa());
        }
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
    
    /// @custom:selector    0x10877ac1
    /// @custom:signature   Unresolved_10877ac1() public view returns (uint256)
    function Unresolved_10877ac1() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return store_a;
    }
    
    /// @custom:selector    0xf126044e
    /// @custom:signature   Unresolved_f126044e() public view returns (uint256)
    function Unresolved_f126044e() public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(this).balance;
    }
    
    /// @custom:selector    0xe30c3978
    /// @custom:signature   Unresolved_e30c3978() public view returns (address)
    function Unresolved_e30c3978() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_a);
    }
    
    /// @custom:selector    0x704b6c02
    /// @custom:signature   Unresolved_704b6c02(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_704b6c02(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(address(arg0) - arg0);
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
    
    /// @custom:selector    0x4e973330
    /// @custom:signature   Unresolved_4e973330(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4e973330(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(address(arg0) - arg0);
        var_a = var_a;
        require(storage_map_f[var_a] > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f))) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        address var_d = var_d + (uint248((0x20 + (storage_map_f[var_a] << 0x05)) + 0x1f));
        require(storage_map_f[var_a] > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 < ((0x20 + (storage_map_f[var_a] << 0x05)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0));
        require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 < storage_map_f[var_a]);
        require(!0 < storage_map_f[var_a]);
        var_a = keccak256(var_a);
        require(!(storage_map_g[0 + keccak256(var_a)]) > block.timestamp);
        require(!0 < storage_map_f[var_a]);
        require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = var_d + 0x40;
        return abi.encodePacked(0x20, var_d.length);
    }
    
    /// @custom:selector    0x5e3e244e
    /// @custom:signature   Unresolved_5e3e244e(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5e3e244e(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(address(arg0) - arg0);
        require(!(address(store_a) == msg.sender), CustomError_02e286cf());
        store_a = (address(arg0)) | (uint96(store_a));
        emit Event_4e3e2721(address(arg0));
    }
    
    /// @custom:selector    0x3428d8ea
    /// @custom:signature   Unresolved_3428d8ea(address arg0, uint256 arg1, uint256 arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_3428d8ea(address arg0, uint256 arg1, uint256 arg2) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(address(arg0) - arg0);
        (bool success, bytes memory ret0) = address(store_a).Unresolved_f8ea4756(var_c); // staticcall
        require(msg.sender - 0, CustomError_8622fd9d());
        require(bytes1(store_a), CustomError_d93c0665());
        var_a = var_a;
        require(block.timestamp > (block.timestamp + arg2));
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_f = var_f + 0x40;
        require(!storage_map_f[var_a] < 0x010000000000000000);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_f[var_a] = storage_map_f[var_a] + 0x01;
        require(!storage_map_f[var_a] < storage_map_f[var_a]);
        require(0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_i[storage_map_f[var_a] << 0x01] = var_f.length;
        storage_map_j[(storage_map_f[var_a] << 0x01) + keccak256(var_a)] = var_h;
        require(store_a > (store_a + arg1));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(address(var_f.length) - var_f.length);
    }
    
    /// @custom:selector    0x53b290ce
    /// @custom:signature   Unresolved_53b290ce(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_53b290ce(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(((msg.data.length - arg0) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20, CustomError_d7e6bcf8());
        require(!(uint64(store_a)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_a)), CustomError_d7e6bcf8());
        require(!(!uint64(store_a)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_a = (uint192(store_a)) | 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = uint96(store_a);
        store_a = (address(msg.sender)) | (uint96(store_a));
        emit Event_8be0079c(address(store_a), address(msg.sender));
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = 0x01;
        require(!(bytes1(store_a >> 0x40)), CustomError_d7e6bcf8());
        store_a = (uint248(store_a)) | 0x010000000000000000;
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
    
    /// @custom:selector    0x5600231a
    /// @custom:signature   Unresolved_5600231a() public payable
    function Unresolved_5600231a() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        (bool success, bytes memory ret0) = address(store_a).Unresolved_f8ea4756(var_c); // staticcall
        require(!(address(store_a) == msg.sender), CustomError_f36646ed());
        require(!(msg.sender == 0), CustomError_f36646ed());
        address var_c = address(this);
        (bool success, bytes memory ret0) = address(store_a).Unresolved_3e323df2(var_c); // staticcall
        (bool success, bytes memory ret0) = address(0).Unresolved_14a6bf0f(var_c); // staticcall
        (bool success, bytes memory ret0) = address(store_a).Unresolved_f8ea4756(var_c); // staticcall
        (bool success, bytes memory ret0) = address(0).Unresolved_6c21157a(var_c); // staticcall
        require(store_a > (store_a + 0));
        require((store_a + 0) < address(this).balance);
        require(0);
        require(!0 > 0);
        require(!address(0).code.length);
        (bool success, bytes memory ret0) = address(0).Unresolved_b60d4288(var_c); // call
        require(((var_f + 0) > 0xffffffffffffffff) | ((var_f + 0) < var_f));
        uint256 var_f = var_f + 0;
        require((var_f - var_f) < 0);
        require((address(this).balance - store_a) > address(this).balance);
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(address(var_f.length) - var_f.length);
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
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
