[2m2026-10-25T19:39:10.150153Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T19:39:10.293825Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T19:39:10.441294Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T19:39:10.548320Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T19:39:11.049787Z[0m [33m WARN[0m couldn't find any resolved matches for '25bc378e'
[2m2026-10-25T19:39:11.101575Z[0m [33m WARN[0m couldn't find any resolved matches for 'c0b568e1'
[2m2026-10-25T19:39:11.116788Z[0m [33m WARN[0m calldata is not a standard size. if decoding fails, consider using the `--truncate-calldata` flag.
[2m2026-10-25T19:39:11.116917Z[0m [33m WARN[0m couldn't find any resolved matches for '52d1902d'
ABI:

[
  {
    "type": "function",
    "name": "UPGRADE_INTERFACE_VERSION",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes"
      }
    ],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "Unresolved_441ad120",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "uint256"
      }
    ],
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
    "name": "Unresolved_4f1ef286",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "Unresolved_52d1902d",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "Unresolved_71799fb8",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Unresolved_7ab4339d",
    "inputs": [
      {
        "name": "arg0",
        "type": "uint256"
      },
      {
        "name": "arg1",
        "type": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "Unresolved_ec449597",
    "inputs": [
      {
        "name": "arg0",
        "type": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "accessController",
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
    "name": "cancelDepositRequest",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "uint256"
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
    "name": "requestDeposit",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      },
      {
        "name": "arg1",
        "type": "uint256"
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
    "type": "event",
    "name": "Event_68c9283ed2da979fc7907e8f6a6f3eb594ddd02f41ef7759b99b3302abe4c7de",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Event_8c8f2be802f4ea4d53518b3c96cae28355483654baef0a2ba556ee7a8d1fd239",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Initialized",
    "inputs": [
      {
        "name": "arg0",
        "type": "uint64",
        "indexed": false
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Upgraded",
    "inputs": [
      {
        "name": "arg0",
        "type": "address",
        "indexed": false
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AddressEmptyCode",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC1967InvalidImplementation",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ERC1967NonPayable",
    "inputs": []
  },
  {
    "type": "error",
    "name": "FailedCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidAccessController",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidAmount",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidInitialization",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotInitializing",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "UUPSUnauthorizedCallContext",
    "inputs": []
  },
  {
    "type": "error",
    "name": "UUPSUnsupportedProxiableUUID",
    "inputs": [
      {
        "name": "arg0",
        "type": "bytes32"
      }
    ]
  },
  {
    "type": "error",
    "name": "UnauthorizedOwner",
    "inputs": [
      {
        "name": "arg0",
        "type": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "UnauthorizedRequestOwner",
    "inputs": []
  },
  {
    "type": "error",
    "name": "UnknownRequest",
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
    bytes public constant UPGRADE_INTERFACE_VERSION = 0xBytes([53, 46, 48, 46, 48]);
    uint256 public constant unresolved_52d1902d = e07c8dba;
    
    mapping(bytes32 => bytes32) storage_map_a;
    bytes32 store_b;
    
    event Event_8c8f2be8();
    error InvalidInitialization();
    event Event_68c9283e();
    event Initialized(uint64);
    event Upgraded(address);
    
    /// @custom:selector    0x441ad120
    /// @custom:signature   Unresolved_441ad120(address arg0, uint256 arg1) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_441ad120(address arg0, uint256 arg1) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        var_a = arg1;
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0xec449597
    /// @custom:signature   Unresolved_ec449597(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_ec449597(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        (bool success, bytes memory ret0) = address(store_b).defaultAdmin(); // staticcall
        require(0 - msg.sender, CustomError_dc599aea());
        require(!(arg0), CustomError_2c5211c6());
        require(!(bytes1(store_b)), CustomError_2c5211c6());
        require(((store_b >> 0x01) < 0x20) == (bytes1(store_b)), CustomError_2c5211c6());
        require(!(bytes1(store_b)), CustomError_2c5211c6());
        require(0x01 == (bytes1(store_b)), CustomError_2c5211c6());
        require(0 < (store_b >> 0x01), CustomError_2c5211c6());
        require(((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) < var_d), CustomError_2c5211c6());
        uint248 var_d = var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f));
        require(arg0 > 0xffffffffffffffff, CustomError_2c5211c6());
        require(((var_d + (uint248((0 - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0 - var_d) + 0x1f))) < var_d), CustomError_2c5211c6());
        require(0x20 > ret0.length);
        require(((var_d + 0x20) > 0xffffffffffffffff) | ((var_d + 0x20) < var_d));
        var_d = var_d + 0x20;
        require(((var_d + 0x20) - var_d) < 0x20);
        require(var_d.length - (address(var_d.length)));
    }
    
    /// @custom:selector    0xd76cca03
    /// @custom:signature   cancelDepositRequest(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function cancelDepositRequest(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_b == 0x02, CustomError_3ee5aeb5());
        store_b = 0x02;
        require(!(address(arg0)), CustomError_583d7b07());
        var_a = arg1;
        require(!(address(storage_map_a[var_a])), CustomError_583d7b07());
        require(address(storage_map_a[var_a]) - msg.sender, CustomError_583d7b07());
        uint256 var_d = arg1;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_c0b568e1(var_d); // call
        var_a = arg1;
        storage_map_a[var_a] = uint96(storage_map_a[var_a]);
        emit Event_8c8f2be8(address(arg0), arg1, address(storage_map_a[var_a]), 0);
        store_b = 0x01;
        return 0;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        var_a = arg1;
        storage_map_a[var_a] = uint96(storage_map_a[var_a]);
        emit Event_8c8f2be8(address(arg0), arg1, address(storage_map_a[var_a]), var_e.length);
        store_b = 0x01;
        return var_e.length;
    }
    
    /// @custom:selector    0x71799fb8
    /// @custom:signature   Unresolved_71799fb8() public view returns (bytes memory)
    function Unresolved_71799fb8() public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        if (!store_b) {
            if (((store_b >> 0x01) < 0x20) == (store_b)) {
                if (!store_b) {
                    if (0x01 == (store_b)) {
                        if (0 < (store_b >> 0x01)) {
                            if (((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) < var_d)) {
                                uint248 var_d = var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f));
                                return abi.encodePacked(0x20, var_d.length);
                                if (((var_d + (uint248((0 - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0 - var_d) + 0x1f))) < var_d)) {
                                    var_d = var_d + (uint248((0 - var_d) + 0x1f));
                                    var_d = 0;
                                    return abi.encodePacked(0x20, var_d.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x5696bdae
    /// @custom:signature   requestDeposit(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function requestDeposit(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(store_b == 0x02, CustomError_3ee5aeb5());
        store_b = 0x02;
        require(!address(arg0));
        require(!arg1);
        require(!bytes1(store_b));
        require(((store_b >> 0x01) < 0x20) == (bytes1(store_b)));
        require(!bytes1(store_b));
        require(0x01 == (bytes1(store_b)));
        require(0 < (store_b >> 0x01));
        require(((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) < var_d));
        uint248 var_d = var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f));
        uint256 var_f = arg1;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_25bc378e(var_f); // call
        var_a = 0;
        require(address(storage_map_a[var_a]), CustomError_2c5211c6());
        var_a = 0;
        storage_map_a[var_a] = (uint96(storage_map_a[var_a])) | msg.sender;
        emit Event_68c9283e(address(arg0), 0, msg.sender, arg1, 0x40, var_d.length);
        store_b = 0x01;
        return 0;
        require(0x20 > ret0.length);
        require(((var_d + 0x20) > 0xffffffffffffffff) | ((var_d + 0x20) < var_d));
        var_d = var_d + 0x20;
        require(((var_d + 0x20) - var_d) < 0x20);
        var_a = var_d.length;
        require(address(storage_map_a[var_a]), CustomError_2c5211c6());
        var_a = var_d.length;
        storage_map_a[var_a] = (uint96(storage_map_a[var_a])) | msg.sender;
        emit Event_68c9283e(address(arg0), var_d.length, msg.sender, arg1, 0x40, var_d.length);
        store_b = 0x01;
        return var_d.length;
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
        require(((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) < var_c), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f));
        require(((arg1 + (arg1)) + 0x24) > msg.data.length, CustomError_e07c8dba());
        require(!(0xb3c011977c21d0f40e9884d250b638e4eed6ad91 == address(this)), CustomError_e07c8dba());
        require(0xb3c011977c21d0f40e9884d250b638e4eed6ad91 == address(this), CustomError_e07c8dba());
        (bool success, bytes memory ret0) = address(store_b).defaultAdmin(); // staticcall
        require(0 - msg.sender, CustomError_dc599aea());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        require(0 - var_a, CustomError_4c9c8ce3());
        require(!address(arg0).code.length, CustomError_4c9c8ce3());
        store_b = (address(arg0)) | (uint96(store_b));
        emit Upgraded(address(arg0));
        require(!var_c.length, CustomError_d6bda275());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_h); // delegatecall
        require(!ret0.length, CustomError_d6bda275());
        var_c = (var_c + ret0.length) + 0x20;
        if (ret0.length) {
        }
        require(msg.value, CustomError_b398979f());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        if (0x20 > ret0.length) {
        }
        require(!(address(store_b) == 0xb3c011977c21d0f40e9884d250b638e4eed6ad91), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0x7ab4339d
    /// @custom:signature   Unresolved_7ab4339d(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7ab4339d(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(arg1 - (address(arg1)));
        require(!(uint64(store_b)), CustomError_199b44e5());
        require(0x01 == (uint64(store_b)), CustomError_199b44e5());
        require(!(!uint64(store_b)), CustomError_199b44e5());
        require(address(this).code.length, CustomError_199b44e5());
        store_b = 0x01 | (uint192(store_b));
        require(!(bytes1(store_b >> 0x40)), CustomError_199b44e5());
        require(!(arg0), CustomError_199b44e5());
        require(!(bytes1(store_b >> 0x40)), CustomError_199b44e5());
        require(!(!address(arg1)), CustomError_199b44e5());
        require(!address(arg1).code.length, CustomError_199b44e5());
        store_b = (uint96(store_b)) | (address(arg1));
        if (arg0 > 0xffffffffffffffff) {
            require(arg0 > 0xffffffffffffffff, CustomError_199b44e5());
            require(!(bytes1(store_b)), CustomError_199b44e5());
            require(((store_b >> 0x01) < 0x20) == (bytes1(store_b)), CustomError_199b44e5());
            require((store_b >> 0x01) > 0x1f, CustomError_199b44e5());
            var_a = var_a;
            require(arg0 < 0x20, CustomError_199b44e5());
            require((var_a + ((arg0 + 0x1f) >> 0x05)) < (var_a + ((0x1f + (store_b >> 0x01)) >> 0x05)), CustomError_199b44e5());
            require(0x01 == (arg0 > 0x1f), CustomError_199b44e5());
            require(0 < (uint248(arg0)), CustomError_199b44e5());
            store_b = (~(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >> (bytes1(arg0 << 0x03)))) & (0 + (arg0 + 0x20));
            store_b = (arg0 << 0x01) + 0x01;
            require(uint248(arg0) < (arg0), CustomError_199b44e5());
            store_b = uint248(store_b);
            emit Initialized(0x01);
            require(!(bytes1(store_b >> 0x40)), CustomError_199b44e5());
        }
        require(!(address(arg1)), CustomError_199b44e5());
        require(!(!uint64(store_b)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0xbc43cbaf
    /// @custom:signature   accessController() public view returns (address)
    function accessController() public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return address(store_b);
    }
}
