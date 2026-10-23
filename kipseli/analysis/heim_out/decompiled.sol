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
    uint256 public constant MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 public constant weth = 376793390874373408599387495934666716005045108742;
    
    address public unresolved_8da5cb5b;
    bytes32 store_c;
    mapping(bytes32 => bytes32) storage_map_b;
    mapping(bytes32 => bytes32) storage_map_d;
    uint256 public numberOperators;
    address public unresolved_61acbdcb;
    bytes32 store_h;
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_e;
    bytes32 store_k;
    mapping(bytes32 => bytes32) storage_map_l;
    bytes32 store_j;
    mapping(bytes32 => bytes32) storage_map_m;
    
    event Event_b0f5cdd7();
    event OperatorsRemoved(address[]);
    event WithdrawFunds(address, uint256, address);
    event Event_1886ee5e();
    event OperatorsAdded(address[]);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable
    function Unresolved_715018a6() public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        unresolved_8da5cb5b = uint96(unresolved_8da5cb5b);
        emit OwnershipTransferred(address(unresolved_8da5cb5b), 0);
    }
    
    /// @custom:selector    0x6d70f7ae
    /// @custom:signature   isOperator(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isOperator(address arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xa908183d
    /// @custom:signature   Unresolved_a908183d(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a908183d(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        require((0x20 + (0x04 + arg0)) < ((0x04 + arg0) + (arg0 << 0x05) + 0x20));
        require(address(0x20 + (arg0)) - (0x20 + (arg0)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        address var_a = address(var_i);
        if (storage_map_b[var_a]) {
            require(storage_map_b[var_a]);
            require(0);
            store_c = store_c + 0x01;
            require(!store_c < 0x010000000000000000);
            var_a = 0x9d;
            storage_map_d[var_a] = (0 & (storage_map_d[var_a])) | (address(var_i) << 0);
            var_a = address(var_i);
            storage_map_b[var_a] = store_c;
            require(!store_c < store_c);
        }
    }
    
    /// @custom:selector    0x8594ac40
    /// @custom:signature   Unresolved_8594ac40(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function Unresolved_8594ac40(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        address var_a = msg.sender;
        require(!storage_map_b[var_a]);
        require((arg0 + 0x20) - (address(arg0 + 0x20)));
        require(address(arg0 + 0x20) < block.timestamp);
        require(address(arg0) - (arg0));
        require(!(address(arg0) == msg.sender), "Incorrect sender");
        require(arg0 + (arg0 + 0x60) > 0xffffffffffffffff);
        require(0 < (arg0 + (arg0 + 0x60)));
        require(address((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))) - ((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))));
        require(((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60))) + 0x40) + ((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))) > 0xffffffffffffffff);
        require(((var_j + (uint248((((var_j + 0x20) + (arg0 + (arg0 + 0x60) << 0x05) + 0x40) - var_j) + 0x1f))) > 0xffffffffffffffff) | ((var_j + (uint248((((var_j + 0x20) + (arg0 + (arg0 + 0x60) << 0x05) + 0x40) - var_j) + 0x1f))) < var_j));
    }
    
    /// @custom:selector    0xa07aea1c
    /// @custom:signature   Unresolved_a07aea1c(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a07aea1c(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(0 < (arg0));
        require(!0 < (arg0));
        require(address(0 + (arg0 + 0x20)) - (0 + (arg0 + 0x20)));
        uint256 var_e = address(0 + (arg0 + 0x20));
        require(storage_map_e[var_e]);
        require(!numberOperators < 0x010000000000000000);
        numberOperators = numberOperators + 0x01;
        require(!numberOperators < numberOperators);
        require(0 < (arg0));
        require(address(arg0 + 0x20) - (arg0 + 0x20));
        emit OperatorsAdded(0x20, (arg0));
    }
    
    /// @custom:selector    0x69328dec
    /// @custom:signature   withdraw(address arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function withdraw(address arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(address(arg0) - arg0);
        require(address(arg2) - arg2);
        address var_a = msg.sender;
        require(!storage_map_b[var_a]);
        var_a = address(arg2);
        require(!storage_map_b[var_a]);
        require(0 == (address(arg0) == 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee));
        require(!address(0x4200000000000000000000000000000000000006).code.length);
        uint256 var_d = arg1;
        (bool success, bytes memory ret0) = address(0x4200000000000000000000000000000000000006).Unresolved_2e1a7d4d(var_d); // call
        (bool success, bytes memory ret0) = address(arg2).transfer(arg1);
        require(!ret0.length, "withdraw eth failed");
        emit WithdrawFunds(address(arg0), address(arg2), arg1);
        require(ret0.length > 0xffffffffffffffff, "transfer failed");
        require(((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_h), "transfer failed");
        require(address(arg0), "transfer failed");
        (bool success, bytes memory ret0) = address(arg2).transfer(arg1);
        require(!ret0.length, "transfer failed");
        emit WithdrawFunds(address(arg0), address(arg2), arg1);
        require(ret0.length > 0xffffffffffffffff, "destination is not approved");
        require(((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_h + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_h), "destination is not approved");
    }
    
    /// @custom:selector    0x14b7c124
    /// @custom:signature   Unresolved_14b7c124() public view returns (bytes memory)
    function Unresolved_14b7c124() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (0 < store_c) {
            if (((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) < var_c)) {
                uint248 var_c = var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f));
                return abi.encodePacked(0x20, var_c.length);
            }
        }
    }
    
    /// @custom:selector    0x4cf3fe9c
    /// @custom:signature   Unresolved_4cf3fe9c(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function Unresolved_4cf3fe9c(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3) public view {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        address var_a = msg.sender;
        require(!storage_map_b[var_a]);
        require((arg0 + 0x20) - (address(arg0 + 0x20)));
        require(address(arg0 + 0x20) < block.timestamp);
        require(address(arg0) - (arg0));
        require(!(address(arg0) == msg.sender), "Incorrect sender");
        require(arg0 + (arg0 + 0x60) > 0xffffffffffffffff);
        require(0 < (arg0 + (arg0 + 0x60)));
        require(address((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))) - ((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))));
        require(((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60))) + 0x20) + ((0x20 + (arg0 + (arg0 + 0x60))) + (0x20 + (arg0 + (arg0 + 0x60)))) > 0xffffffffffffffff);
        require(((var_j + (uint248((((var_j + 0x20) + (arg0 + (arg0 + 0x60) << 0x05) + 0x40) - var_j) + 0x1f))) > 0xffffffffffffffff) | ((var_j + (uint248((((var_j + 0x20) + (arg0 + (arg0 + 0x60) << 0x05) + 0x40) - var_j) + 0x1f))) < var_j));
    }
    
    /// @custom:selector    0x61bb41a7
    /// @custom:signature   Unresolved_61bb41a7(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_61bb41a7(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        unresolved_61acbdcb = (uint96(unresolved_61acbdcb)) | (address(arg0));
        emit Event_b0f5cdd7(address(arg0));
    }
    
    /// @custom:selector    0x9e165a78
    /// @custom:signature   Unresolved_9e165a78() public view returns (bytes memory)
    function Unresolved_9e165a78() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (0 < store_h) {
            if (((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) < var_c)) {
                uint248 var_c = var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f));
                return abi.encodePacked(0x20, var_c.length);
            }
        }
    }
    
    /// @custom:selector    0x1626ba7e
    /// @custom:signature   Unresolved_1626ba7e(uint256 arg0, uint256 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1626ba7e(uint256 arg0, uint256 arg1) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg1 > 0xffffffffffffffff);
        require(!(arg1 + 0x23) < msg.data.length);
        require(arg1 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg1))) + 0x1f))) < var_c));
        uint256 var_d = (arg1);
        require((arg1 + 0x24) + var_d > msg.data.length);
    }
    
    /// @custom:selector    0x7dadbe8c
    /// @custom:signature   Unresolved_7dadbe8c(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7dadbe8c(uint256 arg0, address arg1) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        require((0x20 + (0x04 + arg0)) < ((0x04 + arg0) + (arg0 << 0x05) + 0x20));
        require(address(0x20 + (arg0)) - (0x20 + (arg0)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        address var_a = address(var_i);
        require(!storage_map_b[var_a]);
        require((storage_map_b[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_b[var_a]);
        require((store_c + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > store_c);
        require((store_c + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_b[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        require(!(store_c + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < store_c);
        require(!store_c);
        require(0);
    }
    
    /// @custom:selector    0x26142335
    /// @custom:signature   operatorAt(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function operatorAt(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(!arg0 < numberOperators);
        var_a = 0x65;
        return address(storage_map_i[var_a] >> 0);
    }
    
    /// @custom:selector    0xe3fa62d6
    /// @custom:signature   Unresolved_e3fa62d6(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e3fa62d6(address arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x567aa1ba
    /// @custom:signature   Unresolved_567aa1ba(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_567aa1ba(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        require(0 == (bytes1(store_j >> 0x08)), "Initializable: contract is not initializing");
        require(address(this).code.length, "Initializable: contract is not initializing");
        require(!(bytes1(store_j >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_j >> 0x08)), "Initializable: contract is not initializing");
        store_j = (uint248(store_j)) | 0x0100;
        store_j = (uint248(store_j)) | 0x01;
        require(!(bytes1(store_j >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_j)), "Initializable: contract is already initialized");
    }
    
    /// @custom:selector    0xd911c632
    /// @custom:signature   getAllOperators() public view
    function getAllOperators() public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (numberOperators > 0xffffffffffffffff) {
            if (((var_c + (uint248((0x20 + (numberOperators << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (numberOperators << 0x05)) + 0x1f))) < var_c)) {
            }
        }
    }
    
    /// @custom:selector    0x0eb9142f
    /// @custom:signature   Unresolved_0eb9142f(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_0eb9142f(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        address var_e = address(arg0);
        require(storage_map_e[var_e]);
        require(0);
        emit Event_1886ee5e(address(arg0));
        require(!store_k < 0x010000000000000000);
        store_k = store_k + 0x01;
        require(!store_k < store_k);
        var_e = 0xa1;
        storage_map_l[var_e] = (0 & (storage_map_l[var_e])) | (address(arg0) << 0);
        var_e = address(arg0);
        storage_map_e[var_e] = store_k;
        require(0x01);
        emit Event_1886ee5e(address(arg0));
    }
    
    /// @custom:selector    0x95ccea67
    /// @custom:signature   emergencyWithdraw(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function emergencyWithdraw(address arg0, uint256 arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(address(arg0) - arg0);
        require(!(address(unresolved_8da5cb5b) == msg.sender), "Ownable: caller is not the owner");
        require(address(arg0), "Address: call to non-contract");
        address var_c = address(unresolved_8da5cb5b);
        uint256 var_a = ((var_f + 0x64) - var_f) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        require(((var_f + (uint248(((var_f + 0x64) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248(((var_f + 0x64) - var_f) + 0x1f))) < var_f), "Address: call to non-contract");
        uint248 var_f = var_f + (uint248(((var_f + 0x64) - var_f) + 0x1f));
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f), "Address: call to non-contract");
        var_f = var_f + 0x40;
        require(!(address(arg0).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(arg0).Unresolved_a9059cbb(var_c); // call
        require(!ret0.length);
        require(!var_o);
        require(var_o, "SafeERC20: ERC20 operation did not succeed");
        require((((0x60 + var_o) + 0x20) - 0x80) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_a - var_a, "SafeERC20: ERC20 operation did not succeed");
        require(!var_a, "SafeERC20: ERC20 operation did not succeed");
        require(ret0.length > 0xffffffffffffffff, "SafeERC20: low-level call failed");
        require(((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_f), "SafeERC20: low-level call failed");
        var_f = var_f + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_f.length, "SafeERC20: low-level call failed");
        require(var_f.length);
    }
    
    /// @custom:selector    0x9f273fbc
    /// @custom:signature   Unresolved_9f273fbc(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9f273fbc(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        require((0x20 + (0x04 + arg0)) < ((0x04 + arg0) + (arg0 << 0x05) + 0x20));
        require(address(0x20 + (arg0)) - (0x20 + (arg0)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        address var_a = address(var_i);
        if (storage_map_b[var_a]) {
            require(storage_map_b[var_a]);
            require(0);
            store_h = store_h + 0x01;
            require(!store_h < 0x010000000000000000);
            var_a = 0x9b;
            storage_map_m[var_a] = (0 & (storage_map_m[var_a])) | (address(var_i) << 0);
            var_a = address(var_i);
            storage_map_b[var_a] = store_h;
            require(!store_h < store_h);
        }
    }
    
    /// @custom:selector    0xd365a377
    /// @custom:signature   Unresolved_d365a377(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d365a377(uint256 arg0, address arg1) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(0 < (arg0));
        require(!0 < (arg0));
        require(address(0 + (arg0 + 0x20)) - (0 + (arg0 + 0x20)));
        uint256 var_e = address(0 + (arg0 + 0x20));
        require(!storage_map_e[var_e]);
        require((storage_map_e[var_e] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_e[var_e]);
        require((numberOperators + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > numberOperators);
        require((numberOperators + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_e[var_e] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        require(!(numberOperators + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < numberOperators);
        require(!numberOperators);
        require(0 < (arg0));
        require(address(arg0 + 0x20) - (arg0 + 0x20));
        emit OperatorsRemoved(0x20, (arg0));
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(address(arg0) - arg0);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(!(address(arg0)), "Ownable: new owner is the zero address");
        unresolved_8da5cb5b = (uint96(unresolved_8da5cb5b)) | (address(arg0));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0xf00baf3e
    /// @custom:signature   convertETH(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertETH(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        address var_a = msg.sender;
        require(!storage_map_b[var_a]);
        require(!address(0x4200000000000000000000000000000000000006).code.length);
        (bool success, bytes memory ret0) = address(0x4200000000000000000000000000000000000006).{ value: arg0 }deposit(); // call
        return ;
        require(((var_d + 0) > 0xffffffffffffffff) | ((var_d + 0) < var_d), "caller is not operator");
    }
    
    /// @custom:selector    0x34efb1e9
    /// @custom:signature   setAllowance(address[] arg0, address arg1, uint256 arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function setAllowance(address[] arg0, address arg1, uint256 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(address(arg1) - arg1);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(0 < (arg0));
        require(!0 < (arg0));
        require(address(0 + (arg0 + 0x20)) - (0 + (arg0 + 0x20)));
        require(arg2);
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(0 + (arg0 + 0x20)).Unresolved_dd62ed3e(var_b); // staticcall
        require(0, "SafeERC20: approve from non-zero to non-zero allowance");
        var_c = address(arg1);
        uint256 var_a = ((var_g + 0x64) - var_g) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0;
        require(((var_g + (uint248(((var_g + 0x64) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x64) - var_g) + 0x1f))) < var_g), "Address: call to non-contract");
        uint248 var_g = var_g + (uint248(((var_g + 0x64) - var_g) + 0x1f));
        require(((var_g + 0x40) > 0xffffffffffffffff) | ((var_g + 0x40) < var_g), "Address: call to non-contract");
        var_g = var_g + 0x40;
        require(!(address(0 + (arg0 + 0x20)).code.length), "Address: call to non-contract");
        (bool success, bytes memory ret0) = address(0 + (arg0 + 0x20)).Unresolved_095ea7b3(var_c); // call
        require(!ret0.length);
        require(!var_p);
        require(var_p, "SafeERC20: ERC20 operation did not succeed");
        require((((0x60 + var_p) + 0x20) - 0x80) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_a - var_a, "SafeERC20: ERC20 operation did not succeed");
        require(!var_a, "SafeERC20: ERC20 operation did not succeed");
        require(ret0.length > 0xffffffffffffffff, "SafeERC20: low-level call failed");
        require(((var_g + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f))) < var_g), "SafeERC20: low-level call failed");
        var_g = var_g + (uint248((0x20 + (0x1f + ret0.length)) + 0x1f));
        require(!var_g.length, "SafeERC20: low-level call failed");
        if (var_g.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xaf38bf11
    /// @custom:signature   Unresolved_af38bf11(uint256 arg0, uint32 arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    function Unresolved_af38bf11(uint256 arg0, uint32 arg1) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f));
        require(((arg0 + (arg0 << 0x05)) + 0x24) > msg.data.length);
        require((0x24 + arg0) < ((arg0 + (arg0 << 0x05)) + 0x24));
        require(uint32(msg.data[0x24 + arg0]) - (msg.data[0x24 + arg0]));
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) < var_c));
        var_c = var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f));
        require((0x20 + (0x04 + arg1)) < ((0x04 + arg1) + (arg1 << 0x05) + 0x20));
        require(address(0x20 + (arg1)) - (0x20 + (arg1)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(!(var_c.length == var_c.length), "Executor: invalid length");
    }
    
    /// @custom:selector    0x7d6a4568
    /// @custom:signature   Unresolved_7d6a4568(uint32 arg0) public view returns (address)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_7d6a4568(uint32 arg0) public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(uint32(arg0) - arg0);
        uint32 var_a = uint32(arg0);
        return address(storage_map_b[var_a]);
    }
    
    /// @custom:selector    0x388bb62c
    /// @custom:signature   Unresolved_388bb62c(uint256 arg0, uint32 arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    function Unresolved_388bb62c(uint256 arg0, uint32 arg1) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f));
        require(((arg0 + (arg0 << 0x05)) + 0x24) > msg.data.length);
        require((0x24 + arg0) < ((arg0 + (arg0 << 0x05)) + 0x24));
        require(uint32(msg.data[0x24 + arg0]) - (msg.data[0x24 + arg0]));
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) < var_c));
        var_c = var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f));
        require((0x20 + (0x04 + arg1)) < ((0x04 + arg1) + (arg1 << 0x05) + 0x20));
        require(address(0x20 + (arg1)) - (0x20 + (arg1)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        require(!(var_c.length == var_c.length), "Executor: invalid length");
    }
    
    /// @custom:selector    0xb9f9fc41
    /// @custom:signature   Unresolved_b9f9fc41(uint256 arg0, address arg1) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b9f9fc41(uint256 arg0, address arg1) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        require((0x20 + (0x04 + arg0)) < ((0x04 + arg0) + (arg0 << 0x05) + 0x20));
        require(address(0x20 + (arg0)) - (0x20 + (arg0)));
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        address var_a = address(var_i);
        require(!storage_map_b[var_a]);
        require((storage_map_b[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_b[var_a]);
        require((store_h + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > store_h);
        require((store_h + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_b[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        require(!(store_h + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < store_h);
        require(!store_h);
        require(0);
    }
    
    /// @custom:selector    0xab06e403
    /// @custom:signature   Unresolved_ab06e403(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_ab06e403(address arg0, uint256 arg1) public payable {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(address(arg0) - arg0);
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(!(msg.sender == (address(unresolved_8da5cb5b))), "Ownable: caller is not the owner");
        (bool success, bytes memory ret0) = address(arg0).transfer(msg.value);
    }
}