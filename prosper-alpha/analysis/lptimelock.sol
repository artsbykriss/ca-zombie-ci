[2m2026-10-25T18:29:08.342540Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T18:29:08.343588Z[0m [33m WARN[0m couldn't find any resolved matches for '70a08231'
[2m2026-10-25T18:29:08.346251Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T18:29:08.346523Z[0m [33m WARN[0m couldn't find any resolved matches for '70a08231'
[2m2026-10-25T18:29:08.346845Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T18:29:08.967730Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
ABI:

[
  {
    "type": "function",
    "name": "Unresolved_715018a6",
    "inputs": [],
    "outputs": [],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "Unresolved_79ba5097",
    "inputs": [],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "Unresolved_7aac286b",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "Unresolved_8da5cb5b",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Unresolved_f2fde38b",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "claim",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "migrationEscrow",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pendingOwner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "register",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "uint64"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint64"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "unlockAt",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "Event_599f7ecb15ce0b7884b0ba1bce45e249c7c632c52a76bdac1ebf9da226202ccf",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Event_d8d5adc4f064fa2cee7e38ee8a7db1f97824199a8b9e4a02c4402ebf538f07a2",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "LpClaimed",
    "inputs": [
      {
        "name": "arg0",
        "type": "address",
        "indexed": false
      },
      {
        "name": "arg1",
        "type": "address",
        "indexed": false
      },
      {
        "name": "arg2",
        "type": "uint256",
        "indexed": false
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferStarted",
    "inputs": [
      {
        "name": "arg0",
        "type": "address",
        "indexed": false
      },
      {
        "name": "arg1",
        "type": "address",
        "indexed": false
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "arg0",
        "type": "address",
        "indexed": false
      },
      {
        "name": "arg1",
        "type": "address",
        "indexed": false
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AlreadyConfigured",
    "inputs": []
  },
  {
    "type": "error",
    "name": "AlreadyLocked",
    "inputs": []
  },
  {
    "type": "error",
    "name": "CustomError_00000000000000000000000000000000000000000000000000000000118cdaa7",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidDuration",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidPair",
    "inputs": []
  },
  {
    "type": "error",
    "name": "LockActive",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NothingToClaim",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SafeERC20FailedOperation",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "Unauthorized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAddress",
    "inputs": []
  }
]
Source:

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
    bytes public constant unresolved_715018a6 = 82b42900;
    
    address public unresolved_8da5cb5b;
    address public migrationEscrow;
    address public pendingOwner;
    mapping(bytes32 => bytes32) storage_map_c;
    
    event Event_d8d5adc4();
    error InvalidPair();
    event OwnershipTransferStarted(address, address);
    event Event_599f7ecb();
    event LpClaimed(address, address, uint256);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x7aac286b
    /// @custom:signature   Unresolved_7aac286b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7aac286b(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(address(migrationEscrow), CustomError_11b61b6a());
        require(!(address(arg0)), CustomError_d92e233d());
        migrationEscrow = (address(arg0)) | (uint96(migrationEscrow));
        emit Event_d8d5adc4(address(arg0));
    }
    
    /// @custom:selector    0x468d717c
    /// @custom:signature   register(address arg0, uint64 arg1) public payable returns (uint64)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function register(address arg0, uint64 arg1) public payable returns (uint64) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        require(msg.sender - (address(migrationEscrow)), CustomError_82b42900());
        require(!(uint64(arg1)), CustomError_1e4f7d8c());
        require(!(!address(arg0)), CustomError_1e4f7d8c());
        require(address(arg0).code.length, CustomError_1e4f7d8c());
        require(!address(arg0).code.length, CustomError_1e4f7d8c());
        address var_a = address(arg0);
        require(storage_map_c[var_a], CustomError_5f0ccd7c());
        require(block.timestamp > (block.timestamp + (uint64(arg1))));
        var_a = address(arg0);
        storage_map_c[var_a] = block.timestamp + (uint64(arg1));
        emit Event_599f7ecb(address(arg0), block.timestamp + (uint64(arg1)));
        return block.timestamp + (uint64(arg1));
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_e); // staticcall
        require(!0, CustomError_1e4f7d8c());
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (address(arg0)) {
        }
    }
    
    /// @custom:selector    0x21c0b342
    /// @custom:signature   claim(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claim(address arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        require(!(address(arg1)), CustomError_104a1b9e());
        address var_a = address(arg0);
        require(storage_map_c[var_a], CustomError_104a1b9e());
        require(block.timestamp < storage_map_c[var_a], CustomError_104a1b9e());
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_e); // staticcall
        require(!0, CustomError_5274afe7());
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        var_b = address(arg1);
        (bool success, bytes memory ret0) = address(arg0).many_msg_babbage(var_b); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        emit LpClaimed(address(arg0), address(arg1), 0);
        return 0;
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(arg0).code.length) & (success)), CustomError_5274afe7());
        emit LpClaimed(address(arg0), address(arg1), 0);
        return 0;
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        uint256 var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(!var_g.length, CustomError_969bf728());
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        var_b = address(arg1);
        var_f = var_g.length;
        (bool success, bytes memory ret0) = address(arg0).transfer(var_b, var_f); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        var_g = var_g;
        emit LpClaimed(address(arg0), address(arg1), var_g.length);
        return var_g.length;
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(arg0).code.length) & (success)), CustomError_5274afe7());
        emit LpClaimed(address(arg0), address(arg1), var_g.length);
        return var_g.length;
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        require(!storage_map_c[var_a], CustomError_104a1b9e());
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public payable
    function Unresolved_79ba5097() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        require(address(pendingOwner) - msg.sender, CustomError_118cdaa7());
        address var_b = msg.sender;
        pendingOwner = uint96(pendingOwner);
        unresolved_8da5cb5b = var_b | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), msg.sender);
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(unresolved_8da5cb5b)), CustomError_118cdaa7());
        pendingOwner = (uint96(pendingOwner)) | (address(arg0));
        emit OwnershipTransferStarted(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0x89b7e586
    /// @custom:signature   unlockAt(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function unlockAt(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return storage_map_c[var_a];
    }
}
