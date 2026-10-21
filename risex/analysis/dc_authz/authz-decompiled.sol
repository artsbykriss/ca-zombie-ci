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
    uint256 public constant ENABLE_PERMISSION_TYPEHASH = 32686004208080689254134148723634596904482549541582580585859137212640119034136;
    uint256 public constant VERIFY_WITNESS_TYPEHASH = 2428391852296024813129299205649600501369514432879442034193394838679051135009;
    uint256 public constant PERMIT_SINGLE_TYPEHASH = 3374964296087280547562342694107250178966423951527096650078408439201275838705;
    uint256 public constant REGISTER_SIGNER_TYPEHASH = 74700459630984648930019120834523252737818208241785549752341312636300409212770;
    uint256 public constant DISABLE_PERMISSION_TYPEHASH = 94145442337386011518835715315773472443704536156124054909466317187476010104983;
    uint256 public constant REVOKE_SIGNER_TYPEHASH = 24812711394170310783840920302755841460366145569940642218988052271105873969152;
    uint256 public constant VERIFY_SIGNER_TYPEHASH = 34901508741423062561169085194959955009441930677300236431764335144427850646064;
    
    bool public unresolved_5c975abb;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_d;
    address public getAccountRegistry;
    address public authority;
    bytes32 store_g;
    mapping(bytes32 => bytes32) storage_map_a;
    bytes32 store_h;
    bytes32 store_i;
    bytes32 store_j;
    
    error ZeroAddress();
    event AllowanceConsumed(address, address, uint256, uint96);
    event Event_62e78cea();
    event AllowanceLocked(address, address);
    event Event_5db9ee0a();
    event AuthorityUpdated(address);
    
    /// @custom:selector    0x626a686b
    /// @custom:signature   pausedFunction(bytes4 arg0) public view returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function pausedFunction(bytes4 arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        uint32 var_a = uint32(arg0);
        require(!bytes1(storage_map_a[var_a]));
        return !(!bytes1(storage_map_a[var_a]));
        return !(!bytes1(unresolved_5c975abb));
    }
    
    /// @custom:selector    0xdd962cb2
    /// @custom:signature   getSessionKeyStatus(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getSessionKeyStatus(address arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = address(arg1);
        if (!0x04 > (storage_map_d[var_c] >> 0x40)) {
            var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            if ((storage_map_d[var_c] >> 0x40) == 0x01) {
                var_c = address(arg1);
                if (block.timestamp > (uint32(storage_map_d[var_c]))) {
                }
                require(!0x04 > (bytes1(storage_map_d[var_c] >> 0x40)));
            }
        }
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (var_f.length - (uint32(var_f.length))) {
            var_c = address(arg1);
            if (!0x04 > (storage_map_d[var_c] >> 0x40)) {
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if ((storage_map_d[var_c] >> 0x40) == 0x01) {
                    var_c = address(arg1);
                    require(var_f.length - (uint32(var_f.length)));
                }
                require(!0x04 > (bytes1(storage_map_d[var_c] >> 0x40)));
            }
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x96ade1f9
    /// @custom:signature   sessionKeys(address arg0, address arg1) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function sessionKeys(address arg0, address arg1) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = address(arg1);
        require(!0x04 > (bytes1(storage_map_d[var_c] >> 0x40)));
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return abi.encodePacked(uint32(storage_map_d[var_c]), uint32(storage_map_d[var_c] >> 0x20), bytes1(storage_map_d[var_c] >> 0x40));
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        uint256 var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - (uint32(var_h.length)));
        var_c = address(arg1);
        require(!0x04 > (bytes1(storage_map_d[var_c] >> 0x40)));
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return abi.encodePacked(uint32(storage_map_d[var_c]), uint32(storage_map_d[var_c] >> 0x20), bytes1(storage_map_d[var_c] >> 0x40));
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - (uint32(var_h.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_3f4ba83a(uint32 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_8dfc202b());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_8dfc202b());
        require(!0, CustomError_8dfc202b());
        require(!(bytes1(unresolved_5c975abb)), CustomError_8dfc202b());
        unresolved_5c975abb = uint248(unresolved_5c975abb);
        emit Event_5db9ee0a(msg.sender);
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_j = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_j); // call
        if (var_o < 0x40) {
            require(var_o < 0x40);
            require(((0x60 + var_o) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_o < 0x20);
        require(((0x60 + var_o) - 0x60) < 0x20);
        if (ret0.length > 0xffffffffffffffff) {
        }
    }
    
    /// @custom:selector    0x06991816
    /// @custom:signature   Unresolved_06991816(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4, uint256 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint48", "bytes6", "int48"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_06991816(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint48(arg2)));
        require(arg3 - (bytes1(arg3)));
        require(!arg4 < 0x05);
        require(arg5 > 0xffffffffffffffff);
        require(arg5 > 0xffffffffffffffff, CustomError_3ee5aeb5());
        require(((var_c + (uint248((0x20 + (0x1f + (arg5))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg5))) + 0x1f))) < var_c), CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_g); // staticcall
        var_a = address(arg1);
        if (!0x04 > (storage_map_a[var_a] >> 0x40)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                var_a = address(arg1);
                if (block.timestamp > (uint32(storage_map_a[var_a]))) {
                }
                if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                }
            }
            if (0x20 > ret0.length) {
            }
            require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_fa5cd00f());
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x4c579318
    /// @custom:signature   Unresolved_4c579318(address arg0, address arg1, uint48 arg2, bool arg3, uint32 arg4, uint256 arg5, uint256 arg6) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["uint48", "bytes6", "int48"]
    /// @param              arg4 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg5 ["uint32", "bytes4", "int32"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    function Unresolved_4c579318(address arg0, address arg1, uint48 arg2, bool arg3, uint32 arg4, uint256 arg5, uint256 arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0100);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg3 - (uint48(arg3)));
        require(arg4 - (bytes1(arg4)));
        require(arg5 - (uint32(arg5)));
        require(!arg6 < 0x05);
        require(arg7 > 0xffffffffffffffff);
        require(arg7 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (0x1f + (arg7))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg7))) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg7))) + 0x1f));
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(uint32(arg5) < block.timestamp);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_c80d6a1b(var_g); // call
        require(!(bytes1(arg4) < 0xd0), CustomError_65dd4cb8());
        var_a = 0;
        if (uint48(arg3) == (storage_map_a[var_a] >> 0xd0)) {
            if ((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (uint48(arg3) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01))) {
                    var_a = 0;
                    storage_map_a[var_a] = (uint48(arg3 << 0xd0)) | (uint208(0x01 << (bytes1(arg4))));
                    require(uint48(arg3) == (storage_map_a[var_a] >> 0xd0), CustomError_d57596f1());
                    var_a = address(arg1);
                    require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_d57596f1());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(uint48(arg3) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_d57596f1());
                    var_a = address(arg1);
                    require(address(arg1) - (address(arg0)), CustomError_d57596f1());
                }
                require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_d57596f1());
            }
        }
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg4)))), CustomError_63731371());
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_cd21db4f());
        }
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - var_c.length, CustomError_fa5cd00f());
        require(!var_c.length, CustomError_fa5cd00f());
    }
    
    /// @custom:selector    0xdcd621a2
    /// @custom:signature   isNonceUsed(address arg0, uint48 arg1, uint8 arg2) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint48", "bytes6", "int48"]
    /// @param              arg2 ["bool", "uint8", "bytes1", "int8"]
    function isNonceUsed(address arg0, uint48 arg1, uint8 arg2) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint48(arg1)));
        require(arg2 - (bytes1(arg2)));
        require(!(bytes1(arg2)) < 0xd0);
        return 0x01;
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        uint256 var_c = 0;
        require(uint48(arg1) < (storage_map_d[var_c] >> 0xd0));
        return 0x01;
        require((uint48(storage_map_d[var_c] >> 0xd0) + 0x01) > 0xffffffffffff);
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint48(arg1) > (uint48((storage_map_d[var_c] >> 0xd0) + 0x01)));
        return 0x01;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        return 0;
        require(!0x01);
        return 0;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x8a10cb9e
    /// @custom:signature   Unresolved_8a10cb9e(address arg0, address arg1, uint256 arg2, uint48 arg3, bool arg4, uint32 arg5, uint256 arg6) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint48", "bytes6", "int48"]
    /// @param              arg4 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg5 ["uint32", "bytes4", "int32"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    function Unresolved_8a10cb9e(address arg0, address arg1, uint256 arg2, uint48 arg3, bool arg4, uint32 arg5, uint256 arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 > 0xffffffffffffffff);
        require(!(arg2 + 0x23) < msg.data.length);
        require(arg2 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (0x1f + (arg2))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg2))) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg2))) + 0x1f));
        uint256 var_d = (arg2);
        require((arg2 + 0x24) + var_d > msg.data.length);
        require(arg3 - (uint48(arg3)));
        require(arg4 - (bytes1(arg4)));
        require(arg5 - (uint32(arg5)));
        require(arg6 > 0xffffffffffffffff);
        require(arg6 > 0xffffffffffffffff, CustomError_3ee5aeb5());
        require(((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) < var_c), CustomError_3ee5aeb5());
        var_c = var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_h = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_h); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_h = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_c80d6a1b(var_h); // call
        require(!(bytes1(arg4) < 0xd0), CustomError_65dd4cb8());
        var_a = 0;
        require(uint48(arg3) == (storage_map_a[var_a] >> 0xd0), CustomError_d57596f1());
        require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_d57596f1());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint48(arg3) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_d57596f1());
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg4)))), CustomError_63731371());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - (uint32(var_c.length)), CustomError_65dd4cb8());
        require(!(bytes1(arg4) < 0xd0), CustomError_65dd4cb8());
        var_a = uint32(var_c.length);
        require(uint48(arg3) == (storage_map_a[var_a] >> 0xd0), CustomError_d57596f1());
        require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_d57596f1());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint48(arg3) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_d57596f1());
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg4)))), CustomError_63731371());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x66262a3c
    /// @custom:signature   Unresolved_66262a3c(address arg0, address arg1, uint256 arg2, uint96 arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint96", "bytes12", "int96"]
    function Unresolved_66262a3c(address arg0, address arg1, uint256 arg2, uint96 arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(!arg2 < 0x05);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        address var_j = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_j); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_f[var_g])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_j = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_j); // staticcall
        var_g = address(arg1);
        require(!(!(uint32(storage_map_f[var_g] >> 0xa8)) < block.timestamp), CustomError_232d4af2());
        require(!(arg2 < 0x05), CustomError_232d4af2());
        require(arg2 == 0x01, CustomError_232d4af2());
        var_g = address(arg1);
        require(!(0xffffffff == (uint32(storage_map_f[var_g] >> 0x20))), CustomError_232d4af2());
        require(!(uint96(storage_map_f[var_g] >> 0x48)), CustomError_232d4af2());
        require(!(!(uint96(storage_map_f[var_g] >> 0x48)) < arg3), CustomError_232d4af2());
        require(!(arg3 < 0x01000000000000000000000000), CustomError_35278d12());
        var_g = 0x35278d12;
        require(uint96(storage_map_f[var_g] >> 0x48) - (uint96(arg3)) > 0xffffffffffffffffffffffff, CustomError_399a2cdc());
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_f[var_g] = (uint96((storage_map_f[var_g] >> 0x48) - (arg3) << 0x48)) | (address(storage_map_f[var_g]));
        emit AllowanceConsumed(address(arg0), address(arg1), arg3, uint96(storage_map_f[var_g] >> 0x48));
        require(!(arg2 < 0x05), CustomError_fa0d2e66());
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_j = address(msg.sender);
        var_l = 0x40;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_j, var_l); // call
        if (var_t < 0x40) {
            require(var_t < 0x40);
            require(((0x60 + var_t) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_t < 0x20);
        require(((0x60 + var_t) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x03b42263
    /// @custom:signature   Unresolved_03b42263(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint48", "bytes6", "int48"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function Unresolved_03b42263(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint48(arg2)));
        require(arg3 - (bytes1(arg3)));
        require(arg4 > 0xffffffffffffffff);
        require(arg4 > 0xffffffffffffffff, CustomError_3ee5aeb5());
        require(((var_c + (uint248((0x20 + (0x1f + (arg4))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg4))) + 0x1f))) < var_c), CustomError_3ee5aeb5());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg4))) + 0x1f));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_g); // staticcall
        var_a = address(arg1);
        if (!0x04 > (storage_map_a[var_a] >> 0x40)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                var_a = address(arg1);
                if (block.timestamp > (uint32(storage_map_a[var_a]))) {
                }
                if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                }
            }
            if (0x20 > ret0.length) {
            }
            require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_fa5cd00f());
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - var_c.length, CustomError_fa5cd00f());
        require(!var_c.length, CustomError_fa5cd00f());
    }
    
    /// @custom:selector    0x5092411a
    /// @custom:signature   Unresolved_5092411a(address arg0, uint256 arg1, uint96 arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint96", "bytes12", "int96"]
    function Unresolved_5092411a(address arg0, uint256 arg1, uint96 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(!arg1 < 0x05);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_b); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_c = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_c])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = address(msg.sender);
        require(!(!(uint32(storage_map_d[var_c] >> 0xa8)) < block.timestamp), CustomError_232d4af2());
        require(!(arg1 < 0x05), CustomError_232d4af2());
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(arg1 == 0x01, CustomError_232d4af2());
        require(!(uint32(storage_map_d[var_c] >> 0x20) == 0xffffffff), CustomError_232d4af2());
        require(!(!(uint96(storage_map_d[var_c] >> 0x48)) < arg2), CustomError_232d4af2());
        require(!(arg2 < 0x01000000000000000000000000), CustomError_35278d12());
        var_c = 0x35278d12;
        require(uint96(storage_map_d[var_c] >> 0x48) - (uint96(arg2)) > 0xffffffffffffffffffffffff, CustomError_fa0d2e66());
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_d[var_c] = (uint96((storage_map_d[var_c] >> 0x48) - (arg2) << 0x48)) | (address(storage_map_d[var_c]));
        emit AllowanceConsumed(address(arg0), msg.sender, arg2, uint96(storage_map_d[var_c] >> 0x48));
        require(!(arg1 < 0x05), CustomError_fa0d2e66());
        require(0x20 > ret0.length);
        require(((var_l + 0x20) > 0xffffffffffffffff) | ((var_l + 0x20) < var_l));
        uint256 var_l = var_l + 0x20;
        require(((var_l + 0x20) - var_l) < 0x20);
        require(var_l.length - (uint32(var_l.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x84b0196e
    /// @custom:signature   eip712Domain() public view returns (uint256)
    function eip712Domain() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!store_g, "EIP712: Uninitialized");
        require(store_g, "EIP712: Uninitialized");
        if (!store_h) {
            if (((store_h >> 0x01) < 0x20) == (store_h)) {
                if (!store_h) {
                    if (0x01 == (store_h)) {
                        if (0 < (store_h >> 0x01)) {
                            if (((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) < var_g)) {
                                uint248 var_g = var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f));
                                if (!store_i) {
                                    if (((store_i >> 0x01) < 0x20) == (store_i)) {
                                        if (!store_i) {
                                            if (0x01 == (store_i)) {
                                                if (0 < (store_i >> 0x01)) {
                                                    if (((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) < var_g)) {
                                                        var_g = var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f));
                                                        if (((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g)) {
                                                            var_g = var_g + 0x20;
                                                            return abi.encodePacked(0x0f00000000000000000000000000000000000000000000000000000000000000, 0xe0, (uint248(var_g.length + 0x1f) + (var_g + 0xe0) + 0x20) - var_g, block.chainid, address(this), 0, (uint248(var_g.length + 0x1f) + (uint248(var_g.length + 0x1f) + (var_g + 0xe0) + 0x20) + 0x20) - var_g, var_g.length, var_g.length, var_g.length);
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
    
    /// @custom:selector    0x60494359
    /// @custom:signature   registerSenderSigner(address arg0, uint48 arg1, uint8 arg2, uint32 arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint48", "bytes6", "int48"]
    /// @param              arg2 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    function registerSenderSigner(address arg0, uint48 arg1, uint8 arg2, uint32 arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint48(arg1)));
        require(arg2 - (bytes1(arg2)));
        require(arg3 - (uint32(arg3)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_c = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_c); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_c = address(msg.sender);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_c80d6a1b(var_c); // call
        require(!(bytes1(arg2) < 0xd0), CustomError_65dd4cb8());
        var_a = 0;
        if (uint48(arg1) == (storage_map_a[var_a] >> 0xd0)) {
            if ((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (uint48(arg1) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01))) {
                    var_a = 0;
                    storage_map_a[var_a] = (uint48(arg1 << 0xd0)) | (uint208(0x01 << (bytes1(arg2))));
                    require(uint48(arg1) == (storage_map_a[var_a] >> 0xd0), CustomError_035c098b());
                    var_a = address(arg0);
                    require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_035c098b());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(uint48(arg1) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_035c098b());
                    var_a = address(arg0);
                    require(!(!(uint32(arg3)) < block.timestamp), CustomError_035c098b());
                }
                require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_035c098b());
            }
        }
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg2)))), CustomError_63731371());
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        uint256 var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - (uint32(var_h.length)), CustomError_65dd4cb8());
        require(!(bytes1(arg2) < 0xd0), CustomError_65dd4cb8());
        var_a = uint32(var_h.length);
        if (uint48(arg1) == (storage_map_a[var_a] >> 0xd0)) {
            if ((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (uint48(arg1) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01))) {
                    var_a = uint32(var_h.length);
                    storage_map_a[var_a] = (uint48(arg1 << 0xd0)) | (uint208(0x01 << (bytes1(arg2))));
                    require(uint48(arg1) == (storage_map_a[var_a] >> 0xd0), CustomError_035c098b());
                    var_a = address(arg0);
                    require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_035c098b());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(uint48(arg1) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_035c098b());
                    var_a = address(arg0);
                    require(!(!(uint32(arg3)) < block.timestamp), CustomError_035c098b());
                }
                require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_035c098b());
            }
        }
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg2)))), CustomError_63731371());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - var_h.length, CustomError_fa5cd00f());
        require(!var_h.length, CustomError_fa5cd00f());
    }
    
    /// @custom:selector    0x77007534
    /// @custom:signature   Unresolved_77007534(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4, uint256 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint48", "bytes6", "int48"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_77007534(address arg0, address arg1, uint48 arg2, bool arg3, uint256 arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint48(arg2)));
        require(arg3 - (bytes1(arg3)));
        require(!arg4 < 0x05);
        require(arg5 > 0xffffffffffffffff);
        require(arg5 > 0xffffffffffffffff, CustomError_3ee5aeb5());
        require(((var_c + (uint248((0x20 + (0x1f + (arg5))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg5))) + 0x1f))) < var_c), CustomError_3ee5aeb5());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg5))) + 0x1f));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_g); // staticcall
        var_a = address(arg1);
        if (!0x04 > (storage_map_a[var_a] >> 0x40)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                var_a = address(arg1);
                if (block.timestamp > (uint32(storage_map_a[var_a]))) {
                }
                if ((storage_map_a[var_a] >> 0x40) == 0x01) {
                }
            }
            if (0x20 > ret0.length) {
            }
            require(!(0x04 > (bytes1(storage_map_a[var_a] >> 0x40))), CustomError_fa5cd00f());
            require(block.chainid == 0xaa39db, CustomError_fa5cd00f());
        }
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - var_c.length, CustomError_fa5cd00f());
        require(!var_c.length, CustomError_fa5cd00f());
    }
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   setAuthority(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setAuthority(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(authority)), CustomError_068ca9d8());
        require(!address(arg0).code.length, CustomError_c2f31e5e());
        authority = (uint96(authority)) | (address(arg0));
        emit AuthorityUpdated(address(arg0));
    }
    
    /// @custom:selector    0x8ec0d3fe
    /// @custom:signature   Unresolved_8ec0d3fe(address arg0, uint48 arg1, bool arg2, uint32 arg3, uint256 arg4, uint256 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint48", "bytes6", "int48"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg4 ["uint32", "bytes4", "int32"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    function Unresolved_8ec0d3fe(address arg0, uint48 arg1, bool arg2, uint32 arg3, uint256 arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg2 - (uint48(arg2)));
        require(arg3 - (bytes1(arg3)));
        require(arg4 - (uint32(arg4)));
        require(!arg5 < 0x05);
        require(arg6 > 0xffffffffffffffff);
        require(arg6 > 0xffffffffffffffff);
        require(((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) < var_c));
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f));
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!(!block.timestamp > (uint32(arg4))), CustomError_cd21db4f());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - var_c.length, CustomError_fa5cd00f());
        require(!var_c.length, CustomError_fa5cd00f());
    }
    
    /// @custom:selector    0xed82f4b8
    /// @custom:signature   hasPermission(address arg0, address arg1, uint8 arg2) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["bool", "uint8", "bytes1", "int8"]
    function hasPermission(address arg0, address arg1, uint8 arg2) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(!arg2 < 0x05);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!arg2 < 0x05);
        require(arg2 == 0x01);
        var_c = address(arg1);
        return !(!0xffffffff == (uint32(storage_map_d[var_c] >> 0x20)));
        var_c = address(arg1);
        return !(!(uint32(0x01 << (bytes1(arg2)))) == (uint32((storage_map_d[var_c] >> 0x20) & (0x01 << (bytes1(arg2))))));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        require(!arg2 < 0x05);
        require(arg2 == 0x01);
        var_c = address(arg1);
        return !(!0xffffffff == (uint32(storage_map_d[var_c] >> 0x20)));
        var_c = address(arg1);
        return !(!(uint32(0x01 << (bytes1(arg2)))) == (uint32((storage_map_d[var_c] >> 0x20) & (0x01 << (bytes1(arg2))))));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        return 0;
        require(!0x01);
        return 0;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x05b57d89
    /// @custom:signature   unpauseFunction(bytes4 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function unpauseFunction(bytes4 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_f[var_g])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!(!(uint32(arg0)) == 0x2dd1e5f800000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x05b57d8900000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x8456cb5900000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x3f4ba83a00000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        if (var_p < 0x40) {
            require(var_p < 0x40);
            require(((0x60 + var_p) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_p < 0x20);
        require(((0x60 + var_p) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x485cc955
    /// @custom:signature   initialize(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(!(uint64(store_j)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_j)), CustomError_d7e6bcf8());
        require(!(!uint64(store_j)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_j = (uint192(store_j)) | 0x01;
        require(!(bytes1(store_j >> 0x40)), CustomError_d7e6bcf8());
        require(!(address(arg0)), CustomError_d7e6bcf8());
        require(!(address(arg1)), CustomError_d7e6bcf8());
        require(!(bytes1(store_j >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_j >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_j >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_j)), CustomError_f92ee8a9());
        if (uint64(store_j)) {
        }
        if (0x01 == (uint64(store_j))) {
        }
    }
    
    /// @custom:selector    0x8c1009b5
    /// @custom:signature   getNonceState(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getNonceState(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        uint256 var_c = 0;
        return abi.encodePacked(uint48(storage_map_d[var_c] >> 0xd0), uint208(storage_map_d[var_c]));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        var_c = uint32(var_f.length);
        return abi.encodePacked(uint48(storage_map_d[var_c] >> 0xd0), uint208(storage_map_d[var_c]));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        return abi.encodePacked(0, 0);
        require(!0x01);
        return abi.encodePacked(0, 0);
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x2dd1e5f8
    /// @custom:signature   pauseFunction(bytes4 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function pauseFunction(bytes4 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_f[var_g])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!(!(uint32(arg0)) == 0x2dd1e5f800000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x05b57d8900000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x8456cb5900000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!(!(uint32(arg0)) == 0x3f4ba83a00000000000000000000000000000000000000000000000000000000), CustomError_12ba286f());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        if (var_p < 0x40) {
            require(var_p < 0x40);
            require(((0x60 + var_p) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_p < 0x20);
        require(((0x60 + var_p) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xf8219d90
    /// @custom:signature   Unresolved_f8219d90(address arg0, address arg1, uint96 arg2, uint32 arg3, uint48 arg4, bool arg5, uint256 arg6) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint96", "bytes12", "int96"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    /// @param              arg4 ["uint48", "bytes6", "int48"]
    /// @param              arg5 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    function Unresolved_f8219d90(address arg0, address arg1, uint96 arg2, uint32 arg3, uint48 arg4, bool arg5, uint256 arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint96(arg2)));
        require(arg3 - (uint32(arg3)));
        require(arg4 - (uint48(arg4)));
        require(arg5 - (bytes1(arg5)));
        require(arg6 > 0xffffffffffffffff);
        require(arg6 > 0xffffffffffffffff, CustomError_3ee5aeb5());
        require(((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f))) < var_c), CustomError_3ee5aeb5());
        uint256 var_c = var_c + (uint248((0x20 + (0x1f + (arg6))) + 0x1f));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_g); // staticcall
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!address(arg1));
        require(!uint96(arg2));
        require(!(uint32(arg3)) > block.timestamp);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_c80d6a1b(var_g); // call
        var_a = address(arg1);
        require(!(!uint32(storage_map_a[var_a] >> 0xa8)), CustomError_65dd4cb8());
        require(!(bytes1(arg5) < 0xd0), CustomError_65dd4cb8());
        var_a = 0;
        require(uint48(arg4) == (storage_map_a[var_a] >> 0xd0), CustomError_d57596f1());
        require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_d57596f1());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint48(arg4) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_d57596f1());
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg5)))), CustomError_63731371());
        require(!(bytes1(arg5) < 0xd0), CustomError_65dd4cb8());
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - (uint32(var_c.length)), CustomError_65dd4cb8());
        var_a = address(arg1);
        require(!(!uint32(storage_map_a[var_a] >> 0xa8)), CustomError_65dd4cb8());
        require(!(bytes1(arg5) < 0xd0), CustomError_65dd4cb8());
        var_a = uint32(var_c.length);
        require(uint48(arg4) == (storage_map_a[var_a] >> 0xd0), CustomError_d57596f1());
        require((uint48(storage_map_a[var_a] >> 0xd0) + 0x01) > 0xffffffffffff, CustomError_d57596f1());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint48(arg4) == (uint48((storage_map_a[var_a] >> 0xd0) + 0x01)), CustomError_d57596f1());
        var_a = 0xd57596f100000000000000000000000000000000000000000000000000000000;
        require(uint208(storage_map_a[var_a] & (0x01 << (bytes1(arg5)))), CustomError_63731371());
        require(!(bytes1(arg5) < 0xd0), CustomError_65dd4cb8());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_035c098b());
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xbabcc539
    /// @custom:signature   isAllowed(address arg0) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isAllowed(address arg0) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_b); // staticcall
        return 0;
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        uint256 var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        require(var_c.length - var_c.length);
        return var_c.length;
    }
    
    /// @custom:selector    0x0af4187d
    /// @custom:signature   getAllowance(address arg0, address arg1) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getAllowance(address arg0, address arg1) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = address(arg1);
        return abi.encodePacked(uint96(storage_map_d[var_c] >> 0x48), uint32(storage_map_d[var_c] >> 0xa8));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        var_c = address(arg1);
        return abi.encodePacked(uint96(storage_map_d[var_c] >> 0x48), uint32(storage_map_d[var_c] >> 0xa8));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x8fb36037
    /// @custom:signature   isConsumingScheduledOp() public view returns (uint256)
    function isConsumingScheduledOp() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (!authority >> 0xa0) {
            return 0x8fb3603700000000000000000000000000000000000000000000000000000000;
            return 0;
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_8456cb59(uint32 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_f[var_g])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        unresolved_5c975abb = (uint248(unresolved_5c975abb)) | 0x01;
        emit Event_62e78cea(msg.sender);
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        if (var_p < 0x40) {
            require(var_p < 0x40);
            require(((0x60 + var_p) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_p < 0x20);
        require(((0x60 + var_p) - 0x60) < 0x20);
        if (ret0.length > 0xffffffffffffffff) {
        }
    }
    
    /// @custom:selector    0x44689341
    /// @custom:signature   lockdownAllowance(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function lockdownAllowance(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = address(arg0);
        storage_map_d[var_c] = address(storage_map_d[var_c]);
        storage_map_d[var_c] = uint224(storage_map_d[var_c]);
        emit AllowanceLocked(msg.sender, address(arg0));
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - (uint32(var_e.length)));
        var_c = address(arg0);
        storage_map_d[var_c] = address(storage_map_d[var_c]);
        storage_map_d[var_c] = uint224(storage_map_d[var_c]);
        emit AllowanceLocked(msg.sender, address(arg0));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
}