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
    bytes public constant getEmergencyState = 0xBytes([]);
    uint256 public constant trustedForwarder = 975476479197578754380570792693345865990791187070;
    
    mapping(bytes32 => bytes32) storage_map_c;
    bytes32 store_ad;
    bytes32 store_r;
    mapping(bytes32 => bytes32) storage_map_q;
    bytes32 store_aa;
    mapping(bytes32 => bytes32) storage_map_al;
    address public getRisexOracle;
    mapping(bytes32 => bytes32) storage_map_af;
    mapping(bytes32 => bytes32) storage_map_ak;
    mapping(bytes32 => bytes32) storage_map_am;
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_b;
    bytes32 store_a;
    mapping(bytes32 => bytes32) storage_map_k;
    bytes32 store_e;
    bool public isEmergencyPaused;
    address public getFundingRate;
    address public authority;
    bytes32 store_l;
    bytes32 store_s;
    bytes32 store_i;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_ae;
    bool public unresolved_5c975abb;
    bytes32 store_ac;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_ah;
    bytes32 store_z;
    address public getOrdersManager;
    mapping(bytes32 => bytes32) storage_map_ai;
    address store_y;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_m;
    bytes32 store_t;
    mapping(bytes32 => bytes32) storage_map_ag;
    bytes32 store_ab;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_aj;
    address storage_map_ai[keccak256(var_g) + storage_map_x[var_g]];
    address public getPerpsManager;
    
    event EmergencyTriggered(address, address, uint256, bytes32, uint256);
    event FeeManagerUpdated(address, address);
    event EmergencyCleared(address, uint256);
    event Event_62e78cea();
    error InsufficientSupply(address, uint256, uint256);
    event Event_5db9ee0a();
    event AuthorityUpdated(address);
    event SupportedCollateralToken(address, address, bool);
    event WindowConfigured(uint256, uint256);
    event TransferTradingFees(address, address, uint256, address);
    
    /// @custom:selector    0xefeed9ad
    /// @custom:signature   getTokenRateLimitState(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTokenRateLimitState(address arg0) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a));
    }
    
    /// @custom:selector    0xd8f88787
    /// @custom:signature   getCumulativeWindowState() public view returns (bytes memory)
    function getCumulativeWindowState() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a), CustomError_65244e4e());
        uint256 var_a = var_a + 0xa0;
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a), CustomError_65244e4e());
        var_a = var_a + 0xa0;
        require(!(!uint64(store_a >> 0x80)), CustomError_65244e4e());
        require(!(!store_a >> 0xc0), CustomError_65244e4e());
        require(block.number > (uint64(store_a >> 0x80)), CustomError_65244e4e());
        require(!(!address(var_n)), CustomError_65244e4e());
        require(!(uint64(var_o)), CustomError_65244e4e());
        require(0 == (block.number > (uint64(var_p))), CustomError_65244e4e());
        require(!(0 < (uint64(var_o))), CustomError_65244e4e());
        require((uint64(var_o) - 0) > (uint64(var_o)), CustomError_65244e4e());
        require(!(address(var_n) * (uint64(var_o) - 0) / (address(var_n)) == (uint64(var_o) - 0) | (!address(var_n))), CustomError_65244e4e());
        require(!(uint64(var_o)), CustomError_65244e4e());
        require(address(var_a.length) > (address(var_a.length) + ((address(var_q) * (uint64(var_r) - 0) % (uint64(var_r))) + (address(var_q) * (uint64(var_r) - 0) / (uint64(var_r))))), CustomError_65244e4e());
        require(!(address(var_s) > (address(var_a.length) + ((address(var_q) * (uint64(var_r) - 0) % (uint64(var_r))) + (address(var_q) * (uint64(var_r) - 0) / (uint64(var_r)))))), CustomError_65244e4e());
        require(!(!uint64(var_p)), CustomError_65244e4e());
        require(!(uint64(var_o)), CustomError_65244e4e());
        require(0 == (block.number > (uint64(var_p))), CustomError_65244e4e());
        require(0 < (uint64(var_o)), CustomError_65244e4e());
        return abi.encodePacked(address(var_a.length) + ((address(var_q) * (uint64(var_r) - 0) % (uint64(var_r))) + (address(var_q) * (uint64(var_r) - 0) / (uint64(var_r)))), 0, 0);
        return abi.encodePacked(address(var_a.length) + ((address(var_q) * (uint64(var_r) - 0) % (uint64(var_r))) + (address(var_q) * (uint64(var_r) - 0) / (uint64(var_r)))), 0, 0);
        if (store_a >> 0xc0) {
        }
    }
    
    /// @custom:selector    0x626a686b
    /// @custom:signature   pausedFunction(bytes4 arg0) public view returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function pausedFunction(bytes4 arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        uint32 var_a = uint32(arg0);
        require(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(unresolved_5c975abb));
    }
    
    /// @custom:selector    0xcc2a9a5b
    /// @custom:signature   initialize(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (address(arg4)));
        require(arg5 - (address(arg5)));
        require(!(uint64(store_e)), CustomError_d92e233d());
        require(0x01 == (uint64(store_e)), CustomError_d92e233d());
        require(!(!uint64(store_e)), CustomError_d92e233d());
        require(address(this).code.length, CustomError_d92e233d());
        store_e = (uint192(store_e)) | 0x01;
        require(!(bytes1(store_e >> 0x40)), CustomError_d92e233d());
        require(!(address(arg0)), CustomError_d92e233d());
        require(!(address(arg1)), CustomError_d92e233d());
        require(!(address(arg2)), CustomError_d92e233d());
        require(!(!uint64(store_e)), CustomError_f92ee8a9());
        if (uint64(store_e)) {
        }
        if (0x01 == (uint64(store_e))) {
        }
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3f4ba83a(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require(!bytes1(unresolved_5c975abb));
        unresolved_5c975abb = uint248(unresolved_5c975abb);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        emit Event_5db9ee0a(address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60));
        emit Event_5db9ee0a(address(msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec] >> 0x60));
        emit Event_5db9ee0a(address(msg.sender));
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
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x7ecebe00
    /// @custom:signature   nonces(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function nonces(address arg0) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0x9bfc3ddb
    /// @custom:signature   Unresolved_9bfc3ddb(address arg0, uint256 arg1, address arg2, address arg3, address arg4) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg3 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9bfc3ddb(address arg0, uint256 arg1, address arg2, address arg3, address arg4) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdc) < 0x60);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        uint256 var_f = var_f + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require(((var_f + 0x60) > 0xffffffffffffffff) | ((var_f + 0x60) < var_f));
        var_f = var_f + 0x60;
        require(arg1 - arg1);
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(!var_f.length, CustomError_35be3ac8());
        require(address(var_m) < (address(var_n)), CustomError_35be3ac8());
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_35be3ac8());
        require(!(address(var_n)), CustomError_35be3ac8());
        require(!(!address(var_n)), CustomError_35be3ac8());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_o = address(msg.sender);
        var_p = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_o, var_p); // call
        if (var_t < 0x40) {
            require(var_t < 0x40);
            require(((0x60 + var_t) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_t < 0x20);
        require(((0x60 + var_t) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x8340f549
    /// @custom:signature   Unresolved_8340f549(address arg0, address arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8340f549(address arg0, address arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_b = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_c = address(msg.sender);
        var_f = 0x64;
        require(((var_g + 0xa0) > 0xffffffffffffffff) | ((var_g + 0xa0) < var_g), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!(address(arg0)), CustomError_f5a267f1());
        require(!(address(arg1)), CustomError_f5a267f1());
        require(address(arg1) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_a = 0xf5a267f1;
        require(!address(arg1));
        require(!uint96(storage_map_c[var_a]));
        var_a = address(arg1);
        require(!storage_map_c[var_a]);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(authority).Unresolved_e3f756de(var_k); // staticcall
        require(!0);
        require(!arg2);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_k = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_c80d6a1b(var_k); // call
        var_k = address(this);
        (bool success, bytes memory ret0) = address(arg1).Unresolved_70a08231(var_k); // staticcall
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_1f2a2005());
        }
        if (0x20 > ret0.length) {
        }
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        require((storage_map_c[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_j[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_k[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require(!0x01, CustomError_dc0394b7());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        if (!uint96(storage_map_c[var_a])) {
            require(!(uint96(storage_map_c[var_a])), CustomError_d92e233d());
            require((storage_map_c[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
            require((storage_map_j[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        if (var_q < 0x40) {
            require(var_q < 0x40);
            require(((0x60 + var_q) - 0x60) < 0x40);
            require(var_f - var_f);
            require(var_b - (uint32(var_b)));
        }
        require(!var_q < 0x20);
        require(((0x60 + var_q) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x572b6c05
    /// @custom:signature   isTrustedForwarder(address arg0) public pure returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isTrustedForwarder(address arg0) public pure returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        return (address(arg0)) == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e;
    }
    
    /// @custom:selector    0x30f28b7a
    /// @custom:signature   Unresolved_30f28b7a(uint256 arg0, uint256 arg1, address arg2, uint256 arg3, address arg4, uint256 arg5, address arg6) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg6 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg7 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_30f28b7a(uint256 arg0, uint256 arg1, address arg2, uint256 arg3, address arg4, uint256 arg5, address arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0100);
        require(0x80 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7c) < 0x40);
        require(arg6 - (address(arg6)));
        require(arg7 > 0xffffffffffffffff);
        require(arg7 > 0xffffffffffffffff);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_b = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_c = address(msg.sender);
        var_f = 0x64;
        require(((var_g + 0xa0) > 0xffffffffffffffff) | ((var_g + 0xa0) < var_g), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        address var_l = address(arg6);
        (bool success, bytes memory ret0) = address(authority).Unresolved_e3f756de(var_l); // staticcall
        require(!0);
        require(!address(arg6));
        require(arg4 - (address(arg4)));
        require(!address(arg4));
        require(arg0 - (address(arg0)));
        require(!(address(arg0)), CustomError_f5a267f1());
        require(address(arg0) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_a = 0xf5a267f1;
        require(!(address(arg0)), CustomError_3728b83d());
        require(!(uint96(storage_map_c[var_a])), CustomError_3728b83d());
        var_a = address(arg0);
        require(!storage_map_c[var_a], CustomError_3728b83d());
        require(!arg5, CustomError_3728b83d());
        require(arg5 > arg1, CustomError_3728b83d());
        require(arg0 - (address(arg0)));
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        require((storage_map_c[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require((storage_map_j[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require((storage_map_k[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require(!0x01, CustomError_dc0394b7());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        if (!uint96(storage_map_c[var_a])) {
            require(!(uint96(storage_map_c[var_a])), CustomError_d92e233d());
            require((storage_map_c[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
            require((storage_map_j[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        if (var_r < 0x40) {
            require(var_r < 0x40);
            require(((0x60 + var_r) - 0x60) < 0x40);
            require(var_f - var_f);
            require(var_b - (uint32(var_b)));
        }
        require(!var_r < 0x20);
        require(((0x60 + var_r) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x23babd85
    /// @custom:signature   getWithdrawableUSDCByUserId(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function getWithdrawableUSDCByUserId(uint32 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_b = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_m[var_b])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_m[var_b]) >> 0x01), CustomError_35278d12());
        uint96 var_e = (var_e + ((uint96(storage_map_m[var_b]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_b = uint32(arg0);
        require(!storage_map_m[var_b], CustomError_35278d12());
        require(!(storage_map_m[var_b] > 0), CustomError_35278d12());
        address var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_b = 0x35278d12;
        require(!((!storage_map_m[var_b] | ((storage_map_m[var_b] * 0) / storage_map_m[var_b] == 0)) > (~(storage_map_m[var_b]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_b = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!(var_e.length < 0), CustomError_35278d12());
        var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint32(arg0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_h = uint32(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_h); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_h = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_h); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(storage_map_m[var_b] >> 0x60);
            require(storage_map_p[var_b] >> 0x60);
        }
    }
    
    /// @custom:selector    0x4ee7b93f
    /// @custom:signature   getTokenBalanceByUserId(uint32 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getTokenBalanceByUserId(uint32 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint32(arg0)));
        require(arg1 - (address(arg1)));
        var_a = uint32(arg0);
        require(uint32(arg0));
        require(block.chainid == 0xaa39db);
        require(!(address(arg1)) == 0x8c49baeec2ea2356598ef33ea5dd52267643e677);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        uint32 var_d = uint32(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_d); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_d = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_d); // staticcall
        require((!storage_map_c[var_a] < 0) & ((storage_map_c[var_a] + 0) < 0) | ((storage_map_c[var_a] < 0) & (!(storage_map_c[var_a] + 0) < 0)));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((storage_map_c[var_a] + 0) - 0) < (storage_map_c[var_a] + 0) & (0 > 0) | (((storage_map_c[var_a] + 0) - 0) > (storage_map_c[var_a] + 0) & (!0 > 0)));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return (storage_map_c[var_a] + 0) - 0;
        require(0x40 > ret0.length);
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_f = var_f + 0x40;
        require(((var_f + 0x40) - var_f) < 0x40);
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0xdf3e62dd
    /// @custom:signature   getStoredTotalTokenBalanceInUSDCByUserId(uint32 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function getStoredTotalTokenBalanceInUSDCByUserId(uint32 arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_b = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_m[var_b])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_m[var_b]) >> 0x01), CustomError_35278d12());
        uint96 var_e = (var_e + ((uint96(storage_map_m[var_b]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_b = uint32(arg0);
        require(!storage_map_m[var_b], CustomError_35278d12());
        require(!(storage_map_m[var_b] > 0), CustomError_35278d12());
        address var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_b = 0x35278d12;
        require(!((!storage_map_m[var_b] | ((storage_map_m[var_b] * 0) / storage_map_m[var_b] == 0)) > (~(storage_map_m[var_b]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_b = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!(var_e.length < 0), CustomError_35278d12());
        var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return 0;
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
            require(storage_map_m[var_b] >> 0x60);
            require(storage_map_p[var_b] >> 0x60);
        }
    }
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   Unresolved_7a9e5e4b(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7a9e5e4b(address arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e, CustomError_068ca9d8());
        require(!(!msg.data.length < 0x14), CustomError_068ca9d8());
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length, CustomError_068ca9d8());
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length, CustomError_068ca9d8());
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14, CustomError_068ca9d8());
        require(address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60) - (address(authority)), CustomError_068ca9d8());
        require(!address(arg0).code.length, CustomError_c2f31e5e());
        authority = (uint96(authority)) | (address(arg0));
        emit AuthorityUpdated(address(arg0));
    }
    
    /// @custom:selector    0x7f4e759f
    /// @custom:signature   getSupportedCollateralTokens() public view returns (bytes memory)
    function getSupportedCollateralTokens() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        var_b = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        if (!uint96(storage_map_m[var_b])) {
            if (0x01 < (uint96(storage_map_m[var_b]) >> 0x01)) {
                uint96 var_e = (var_e + ((uint96(storage_map_m[var_b]) >> 0x01) << 0x05)) + 0x20;
                return abi.encodePacked(0x20, var_e.length);
                if (storage_map_m[var_b] >> 0x60) {
                    if (storage_map_p[var_b] >> 0x60) {
                        if (storage_map_q[var_b] >> 0x60) {
                            var_e = (var_e + 0x60) + 0x20;
                            return abi.encodePacked(0x20, var_e.length);
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x84b0196e
    /// @custom:signature   eip712Domain() public view returns (uint256)
    function eip712Domain() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!store_r, "EIP712: Uninitialized");
        require(store_r, "EIP712: Uninitialized");
        if (!store_s) {
            if (((store_s >> 0x01) < 0x20) == (store_s)) {
                if (!store_s) {
                    if (0x01 == (store_s)) {
                        if (0 < (store_s >> 0x01)) {
                            if (((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f))) < var_g)) {
                                uint248 var_g = var_g + (uint248((((var_g + 0) + 0x20) - var_g) + 0x1f));
                                if (!store_t) {
                                    if (((store_t >> 0x01) < 0x20) == (store_t)) {
                                        if (!store_t) {
                                            if (0x01 == (store_t)) {
                                                if (0 < (store_t >> 0x01)) {
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
    
    /// @custom:selector    0x3c930c0a
    /// @custom:signature   updateTokenBalanceByUserId(uint32 arg0, address arg1, int256 arg2) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function updateTokenBalanceByUserId(uint32 arg0, address arg1, int256 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (uint32(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039, CustomError_ca67ade8());
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852, CustomError_ca67ade8());
        require(msg.sender - (address(getPerpsManager)), CustomError_ca67ade8());
        var_a = uint32(arg0);
        require((!storage_map_c[var_a] < 0) & ((storage_map_c[var_a] + arg2) < arg2) | ((storage_map_c[var_a] < 0) & (!(storage_map_c[var_a] + arg2) < arg2)), CustomError_ca67ade8());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_c[var_a] = storage_map_c[var_a] + arg2;
        require(msg.sender - 0x53f10facfc8965750494e6965f5d6da39b41d852, CustomError_ca67ade8());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xd9caed12
    /// @custom:signature   Unresolved_d9caed12(address arg0, address arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d9caed12(address arg0, address arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_b = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_c = address(msg.sender);
        var_f = 0x64;
        require(((var_g + 0xa0) > 0xffffffffffffffff) | ((var_g + 0xa0) < var_g), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        require(!(address(arg0)), CustomError_f5a267f1());
        require(!(address(arg1)), CustomError_f5a267f1());
        require(address(arg1) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_a = 0xf5a267f1;
        require(!address(arg1));
        require(!uint96(storage_map_c[var_a]));
        var_a = address(arg1);
        require(!storage_map_c[var_a]);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_e3f756de(var_l); // staticcall
        require(!0, CustomError_fa5cd00f());
        if (0x20 > ret0.length) {
        }
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        require((storage_map_c[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_j[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_k[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require(!0x01, CustomError_dc0394b7());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        if (!uint96(storage_map_c[var_a])) {
            require(!(uint96(storage_map_c[var_a])), CustomError_d92e233d());
            require((storage_map_c[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
            require((storage_map_j[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        if (var_r < 0x40) {
            require(var_r < 0x40);
            require(((0x60 + var_r) - 0x60) < 0x40);
            require(var_f - var_f);
            require(var_b - (uint32(var_b)));
        }
        require(!var_r < 0x20);
        require(((0x60 + var_r) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0xb5d0538d
    /// @custom:signature   getWithdrawableUSDC(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getWithdrawableUSDC(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_b); // staticcall
        var_d = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_u[var_d])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_u[var_d]) >> 0x01), CustomError_35278d12());
        uint96 var_f = (var_f + ((uint96(storage_map_u[var_d]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_d = 0;
        require(!storage_map_u[var_d], CustomError_35278d12());
        require(!(storage_map_u[var_d] > 0), CustomError_35278d12());
        address var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_d = 0x35278d12;
        require(!((!storage_map_u[var_d] | ((storage_map_u[var_d] * 0) / storage_map_u[var_d] == 0)) > (~(storage_map_u[var_d]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_d = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(!(var_f.length < 0), CustomError_35278d12());
        var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        if (0x20 > ret0.length) {
        }
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_i = 0;
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_i); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_i = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_i); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                if (block.chainid == 0xaa39db) {
                    require(block.chainid == 0xaa39db);
                }
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
                require(storage_map_u[var_d] >> 0x60);
            }
            require(storage_map_v[var_d] >> 0x60);
        }
    }
    
    /// @custom:selector    0x792e6c4d
    /// @custom:signature   getAccountEquity(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getAccountEquity(address arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_b); // staticcall
        var_d = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_u[var_d])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_u[var_d]) >> 0x01), CustomError_35278d12());
        uint96 var_f = (var_f + ((uint96(storage_map_u[var_d]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_d = 0;
        require(!storage_map_u[var_d], CustomError_35278d12());
        require(!(storage_map_u[var_d] > 0), CustomError_35278d12());
        address var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_d = 0x35278d12;
        require(!((!storage_map_u[var_d] | ((storage_map_u[var_d] * 0) / storage_map_u[var_d] == 0)) > (~(storage_map_u[var_d]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_d = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(!(var_f.length < 0), CustomError_35278d12());
        var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        if (0x20 > ret0.length) {
        }
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_i = 0;
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_i); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_i = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_i); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                if (block.chainid == 0xaa39db) {
                    require(block.chainid == 0xaa39db);
                }
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
                require(storage_map_u[var_d] >> 0x60);
            }
            require(storage_map_v[var_d] >> 0x60);
        }
    }
    
    /// @custom:selector    0x05b57d89
    /// @custom:signature   Unresolved_05b57d89(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_05b57d89(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_x[var_g])), CustomError_965ad3ca());
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
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x5ea14114
    /// @custom:signature   creditLiquidationFee(uint32 arg0, address arg1, uint256 arg2) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function creditLiquidationFee(uint32 arg0, address arg1, uint256 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (uint32(arg0)));
        require(arg1 - (address(arg1)));
        require(!(msg.sender == (address(store_y))), CustomError_4a3010e6());
        require(!(uint32(arg0)), CustomError_cc4e0b15());
        var_a = uint32(arg0);
        require((!storage_map_c[var_a] < 0) & ((storage_map_c[var_a] + arg2) < arg2) | ((storage_map_c[var_a] < 0) & (!(storage_map_c[var_a] + arg2) < arg2)), CustomError_cc4e0b15());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_c[var_a] = storage_map_c[var_a] + arg2;
    }
    
    /// @custom:selector    0x2dd1e5f8
    /// @custom:signature   Unresolved_2dd1e5f8(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2dd1e5f8(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_x[var_g])), CustomError_965ad3ca());
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
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x3644e515
    /// @custom:signature   fopwCDKKK() public view
    function fopwCDKKK() public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (!store_s) {
            if (((store_s >> 0x01) < 0x20) == (store_s)) {
                if (!store_s) {
                    if (0x01 == (store_s)) {
                        if (0 < (store_s >> 0x01)) {
                            if (((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) < var_d)) {
                                uint248 var_d = var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f));
                                if (!var_d.length) {
                                    if (!store_t) {
                                        if (((store_t >> 0x01) < 0x20) == (store_t)) {
                                            if (!store_t) {
                                                if (0x01 == (store_t)) {
                                                    if (0 < (store_t >> 0x01)) {
                                                        if (((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f))) < var_d)) {
                                                            var_d = var_d + (uint248((((var_d + 0) + 0x20) - var_d) + 0x1f));
                                                            if (!var_d.length) {
                                                                if (!store_z) {
                                                                }
                                                                if (((var_d + (uint248((0 - var_d) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0 - var_d) + 0x1f))) < var_d)) {
                                                                    if (!store_r) {
                                                                        if (!store_t) {
                                                                        }
                                                                        if (!store_t) {
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
    
    /// @custom:selector    0xa98b91e5
    /// @custom:signature   Unresolved_a98b91e5(uint32 arg0, address arg1, address arg2, address arg3) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a98b91e5(uint32 arg0, address arg1, address arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        uint256 var_f = var_f + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(((var_f + 0x60) > 0xffffffffffffffff) | ((var_f + 0x60) < var_f));
        var_f = var_f + 0x60;
        require(arg0 - arg0);
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(!var_f.length, CustomError_35be3ac8());
        require(address(var_l) < (address(var_m)), CustomError_35be3ac8());
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_35be3ac8());
        require(!(address(var_m)), CustomError_35be3ac8());
        require(!(!address(var_m)), CustomError_35be3ac8());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_n = address(msg.sender);
        var_o = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_n, var_o); // call
        if (var_s < 0x40) {
            require(var_s < 0x40);
            require(((0x60 + var_s) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_s < 0x20);
        require(((0x60 + var_s) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0xfd694891
    /// @custom:signature   getTotalTokenBalanceInUSDC(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalTokenBalanceInUSDC(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_b); // staticcall
        var_d = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_u[var_d])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_u[var_d]) >> 0x01), CustomError_35278d12());
        uint96 var_f = (var_f + ((uint96(storage_map_u[var_d]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_d = 0;
        require(!storage_map_u[var_d], CustomError_35278d12());
        require(!(storage_map_u[var_d] > 0), CustomError_35278d12());
        address var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_d = 0x35278d12;
        require(!((!storage_map_u[var_d] | ((storage_map_u[var_d] * 0) / storage_map_u[var_d] == 0)) > (~(storage_map_u[var_d]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_d = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_u[var_d] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(!(var_f.length < 0), CustomError_35278d12());
        var_i = address(var_g);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_i); // staticcall
        if (0x20 > ret0.length) {
        }
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_i = 0;
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_i); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_i = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_i); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                return 0;
                if (block.chainid == 0xaa39db) {
                    require(block.chainid == 0xaa39db);
                }
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
                require(storage_map_u[var_d] >> 0x60);
            }
            require(storage_map_v[var_d] >> 0x60);
        }
    }
    
    /// @custom:selector    0x8fcae072
    /// @custom:signature   transferTradingFees(address arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function transferTradingFees(address arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg2 - (address(arg2)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(!(msg.sender == (address(store_y))), CustomError_4a3010e6());
        require(!arg1);
        require(!address(arg2));
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_e); // staticcall
        require(!(!0 < arg1), CustomError_508b733b());
        address var_i = address(arg2);
        require(((var_k + 0x80) > 0xffffffffffffffff) | ((var_k + 0x80) < var_k));
        uint256 var_k = var_k + 0x80;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_a9059cbb(var_i); // call
        require(ret0.length, CustomError_5274afe7());
        require(!(address(arg0).code.length), CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        emit TransferTradingFees(msg.sender, address(arg0), address(arg2), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!(0x01 == var_a), CustomError_5274afe7());
        emit TransferTradingFees(msg.sender, address(arg0), address(arg2), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(0x20 > ret0.length);
        require(((var_k + 0x20) > 0xffffffffffffffff) | ((var_k + 0x20) < var_k));
        var_k = var_k + 0x20;
        require(((var_k + 0x20) - var_k) < 0x20);
    }
    
    /// @custom:selector    0x472d35b9
    /// @custom:signature   Unresolved_472d35b9(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_472d35b9(address arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_d92e233d());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_d92e233d());
        require(!0, CustomError_d92e233d());
        require(!(address(arg0)), CustomError_d92e233d());
        store_y = (uint96(store_y)) | (address(arg0));
        emit FeeManagerUpdated(address(store_y), address(arg0));
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
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0xe90dc0f8
    /// @custom:signature   Unresolved_e90dc0f8(uint32 arg0, uint64 arg1, address arg2) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e90dc0f8(uint32 arg0, uint64 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        uint256 var_f = var_f + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f));
        var_f = var_f + 0x40;
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        require(!(!address(arg0)), CustomError_35278d12());
        require(!(uint64(arg1)), CustomError_35278d12());
        store_b = (address(store_b)) | (address(var_f.length));
        store_a = (uint192(store_a)) | (uint64(var_k << 0xc0));
        require(!(block.number < 0x010000000000000000), CustomError_35278d12());
        store_a = (uint192(store_a)) | (uint64(block.number << 0x80));
        store_a = address(store_a);
        store_b = address(store_b);
        emit WindowConfigured(address(var_f.length), uint64(var_n));
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_o = address(msg.sender);
        var_p = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_o, var_p); // call
        if (var_t < 0x40) {
            require(var_t < 0x40);
            require(((0x60 + var_t) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_t < 0x20);
        require(((0x60 + var_t) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x43b97d59
    /// @custom:signature   getGlobalRateLimitState() public view returns (bool)
    function getGlobalRateLimitState() public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a), CustomError_35278d12());
        uint256 var_a = var_a + 0xa0;
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a), CustomError_35278d12());
        var_a = var_a + 0xa0;
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a), CustomError_35278d12());
        var_a = var_a + 0xa0;
        require(!(uint64(var_s)), CustomError_35278d12());
        require((block.number - (uint64(var_s))) > block.number, CustomError_35278d12());
        require(!(block.number - (uint64(var_s))), CustomError_35278d12());
        return abi.encodePacked(address(var_a.length), address(var_ab), address(var_ac), uint64(var_ad), (var_ae));
        require(!((block.number - (uint64(var_s))) * (address(var_v)) / (block.number - (uint64(var_s))) == (address(var_v)) | (!block.number - (uint64(var_s)))), CustomError_35278d12());
        require(address(var_x) > (address(var_x) + ((block.number - (uint64(var_s))) * (address(var_v)))), CustomError_35278d12());
        require(address(var_x) + ((block.number - (uint64(var_s))) * (address(var_v))) > (address(var_a.length)), CustomError_35278d12());
        require(!(address(var_a.length) < 0x0100000000000000000000000000000000), CustomError_35278d12());
        require(!(block.number < 0x010000000000000000), CustomError_35278d12());
        return abi.encodePacked(address(var_a.length), address(var_ab), address(var_ac), uint64(var_ad), (var_ae));
    }
    
    /// @custom:selector    0xaf9fa7b6
    /// @custom:signature   getTotalTokenBalanceInUSDCByUserId(uint32 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function getTotalTokenBalanceInUSDCByUserId(uint32 arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_b = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_m[var_b])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_m[var_b]) >> 0x01), CustomError_35278d12());
        uint96 var_e = (var_e + ((uint96(storage_map_m[var_b]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_b = uint32(arg0);
        require(!storage_map_m[var_b], CustomError_35278d12());
        require(!(storage_map_m[var_b] > 0), CustomError_35278d12());
        address var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_b = 0x35278d12;
        require(!((!storage_map_m[var_b] | ((storage_map_m[var_b] * 0) / storage_map_m[var_b] == 0)) > (~(storage_map_m[var_b]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_b = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!(var_e.length < 0), CustomError_35278d12());
        var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint32(arg0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_h = uint32(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_h); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_h = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_h); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                return 0;
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(storage_map_m[var_b] >> 0x60);
            require(storage_map_p[var_b] >> 0x60);
        }
    }
    
    /// @custom:selector    0x137c29fe
    /// @custom:signature   Unresolved_137c29fe(uint256 arg0, uint256 arg1, address arg2, uint256 arg3, address arg4, uint256 arg5, uint256 arg6, address arg7) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg6 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_137c29fe(uint256 arg0, uint256 arg1, address arg2, uint256 arg3, address arg4, uint256 arg5, uint256 arg6, address arg7) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0140);
        require(0x80 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7c) < 0x40);
        require(arg6 - (address(arg6)));
        require(arg8 > 0xffffffffffffffff);
        require(arg8 > 0xffffffffffffffff);
        require(arg9 > 0xffffffffffffffff);
        require(arg9 > 0xffffffffffffffff);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_b = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_c = address(msg.sender);
        var_f = 0x64;
        require(((var_g + 0xa0) > 0xffffffffffffffff) | ((var_g + 0xa0) < var_g), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        address var_l = address(arg6);
        (bool success, bytes memory ret0) = address(authority).Unresolved_e3f756de(var_l); // staticcall
        require(!0);
        require(!address(arg6));
        require(arg4 - (address(arg4)));
        require(!address(arg4));
        require(arg0 - (address(arg0)));
        require(!(address(arg0)), CustomError_f5a267f1());
        require(address(arg0) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_a = 0xf5a267f1;
        require(!(address(arg0)), CustomError_3728b83d());
        require(!(uint96(storage_map_c[var_a])), CustomError_3728b83d());
        var_a = address(arg0);
        require(!storage_map_c[var_a], CustomError_3728b83d());
        require(!arg5, CustomError_3728b83d());
        require(arg5 > arg1, CustomError_3728b83d());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        require((storage_map_c[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require((storage_map_j[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require((storage_map_k[var_a] >> 0x60) == (address(arg0)), CustomError_dc0394b7());
        require(!0x01, CustomError_dc0394b7());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        if (!uint96(storage_map_c[var_a])) {
            require(!(uint96(storage_map_c[var_a])), CustomError_d92e233d());
            require((storage_map_c[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
            require((storage_map_j[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        if (var_r < 0x40) {
            require(var_r < 0x40);
            require(((0x60 + var_r) - 0x60) < 0x40);
            require(var_f - var_f);
            require(var_b - (uint32(var_b)));
        }
        require(!var_r < 0x20);
        require(((0x60 + var_r) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0xbe554f26
    /// @custom:signature   Unresolved_be554f26(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_be554f26(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        uint256 var_f = var_f + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require(bytes1(isEmergencyPaused));
        require(((var_f + 0xc0) > 0xffffffffffffffff) | ((var_f + 0xc0) < var_f));
        isEmergencyPaused = (uint248(isEmergencyPaused)) | 0x01;
        isEmergencyPaused = (uint32(isEmergencyPaused) | (uint64(block.timestamp << 0x08))) | (address(msg.sender << 0x48));
        store_l = arg0;
        store_ac = (address(store_ac)) | 0;
        store_ad = (uint96(store_ad)) | 0;
        emit EmergencyTriggered(address(msg.sender), 0, arg0, 0, block.timestamp);
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_q = address(msg.sender);
        var_r = 0x40;
        uint256 var_s = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_q, var_r, var_s, var_v); // call
        if (var_w < 0x40) {
            require(var_w < 0x40);
            require(((0x60 + var_w) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_w < 0x20);
        require(((0x60 + var_w) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
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
    
    /// @custom:selector    0x4fbb86a6
    /// @custom:signature   Unresolved_4fbb86a6(address arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4fbb86a6(address arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - arg1);
        require(!address(arg0));
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        require(!arg1);
        (bool success, bytes memory ret0) = address(arg0).decimals(); // staticcall
        require(0 > 0x12, CustomError_8ae4e0f3());
        require(address(arg0) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_g = 0xf5a267f1;
        if (!address(arg0)) {
            require(!(address(arg0)), CustomError_f5a267f1());
            address var_g = address(arg0);
            require(!(uint96(storage_map_x[var_g])), CustomError_f5a267f1());
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_x[var_g] = 0x01 + (uint96(storage_map_x[var_g]) >> 0x01);
            require(!storage_map_x[var_g], CustomError_f5a267f1());
            storage_map_ae[var_g] = (address(arg0)) << 0x60;
            storage_map_x[var_g] = 0x02 + storage_map_x[var_g];
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_x[var_g] = 0x03 | (address(arg0) << 0x60);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            require(!(uint96(storage_map_x[var_g]) >> 0x01), CustomError_f5a267f1());
            require(!(storage_map_x[var_g] >> 0x60), CustomError_f5a267f1());
            require((storage_map_x[var_g] >> 0x60) == (address(arg0)), CustomError_f5a267f1());
            require(!(storage_map_af[var_g] >> 0x60), CustomError_f5a267f1());
            require((storage_map_af[var_g] >> 0x60) == (address(arg0)), CustomError_f5a267f1());
            require(!(storage_map_ag[var_g] >> 0x60), CustomError_f5a267f1());
            var_g = storage_map_x[var_g] >> 0x60;
            storage_map_x[var_g] = 0x01;
            var_g = (storage_map_af[var_g]) >> 0x60;
            storage_map_x[var_g] = 0x02;
            var_g = (storage_map_ag[var_g]) >> 0x60;
            storage_map_x[var_g] = 0x03;
            var_g = address(arg0);
            require((storage_map_ag[var_g] >> 0x60) == (address(arg0)), CustomError_f5a267f1());
            storage_map_x[var_g] = 0x04;
            require(!storage_map_x[var_g], CustomError_f5a267f1());
            storage_map_x[var_g] = 0x03 | (address(arg0) << 0x60);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_ah[var_g] = (address(arg0)) << 0x60;
            storage_map_x[var_g] = 0x02 + (storage_map_x[var_g] | 0x07);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_ag[var_g] = (address(arg0)) << 0x60;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_af[var_g] = (address(arg0)) << 0x60;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_x[var_g] = (address(arg0)) << 0x60;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            require(!0x03, CustomError_f5a267f1());
            require(!(uint96(storage_map_x[var_g])), CustomError_f5a267f1());
            require(!(storage_map_x[var_g] >> 0x60), CustomError_f5a267f1());
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            require((storage_map_x[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
            require(!(storage_map_af[var_g] >> 0x60), CustomError_f5a267f1());
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            require((storage_map_af[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
            require(!(storage_map_ag[var_g] >> 0x60), CustomError_f5a267f1());
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_ag[var_g] = 0xfbb67fda52d4bfb8bf000000000000000000000000;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_af[var_g] = 0xfbb67fda52d4bfb8bf000000000000000000000000;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            storage_map_x[var_g] = 0xfbb67fda52d4bfb8bf000000000000000000000000;
            emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
            require((storage_map_ag[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        }
        require(address(arg0) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_g = 0xf5a267f1;
        require(!address(arg0));
        require(!uint96(storage_map_x[var_g]));
        var_g = address(arg0);
        require(!storage_map_x[var_g]);
        require((storage_map_x[var_g] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (uint96(storage_map_x[var_g] >> 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        storage_map_ai[keccak256(var_g) + storage_map_x[var_g]] = address(storage_map_aj[keccak256(var_g) + (uint96(storage_map_x[var_g] >> 0x01))]);
        var_g = (storage_map_ak[keccak256(var_g) + (uint96(storage_map_x[var_g] >> 0x01))]) >> 0x60;
        storage_map_x[var_g] = storage_map_x[var_g];
        storage_map_x[var_g] = (address(storage_map_x[var_g]) | ((uint96(storage_map_x[var_g] >> 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) << 0x01)) | 0x01;
        storage_map_x[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        storage_map_x[var_g] = (address(storage_map_x[var_g]) | ((uint96(storage_map_x[var_g] >> 0x01) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) << 0x01)) | 0x01;
        storage_map_x[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        require((storage_map_x[var_g] >> 0x60) == (address(arg0)));
        require((storage_map_af[var_g] >> 0x60) == (address(arg0)));
        require((storage_map_al[var_g] >> 0x60) == (address(arg0)));
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        storage_map_al[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        storage_map_af[var_g] = storage_map_al[var_g];
        storage_map_al[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        storage_map_x[var_g] = storage_map_af[var_g];
        storage_map_af[var_g] = storage_map_ag[var_g];
        storage_map_ag[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        require(!uint96(storage_map_x[var_g]));
        require((storage_map_x[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        storage_map_x[var_g] = storage_map_af[var_g];
        storage_map_af[var_g] = storage_map_ag[var_g];
        storage_map_ag[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        require((storage_map_af[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        storage_map_af[var_g] = storage_map_al[var_g];
        storage_map_al[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        require((storage_map_al[var_g] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        storage_map_al[var_g] = 0;
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        emit SupportedCollateralToken(msg.sender, address(arg0), arg1);
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        if (var_q < 0x40) {
            require(var_q < 0x40);
            require(((0x60 + var_q) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_q < 0x20);
        require(((0x60 + var_q) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0x49f1c2d2
    /// @custom:signature   getIsCollateralToken(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getIsCollateralToken(address arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_b = 0xf5a267f1;
        require(!address(arg0));
        require(!uint96(storage_map_m[var_b]));
        address var_b = address(arg0);
        return storage_map_m[var_b];
        require((storage_map_m[var_b] >> 0x60) == (address(arg0)));
        require((storage_map_p[var_b] >> 0x60) == (address(arg0)));
        require((storage_map_q[var_b] >> 0x60) == (address(arg0)));
        return 0;
        return 0x01;
        return 0x01;
        return 0x01;
        require(!uint96(storage_map_m[var_b]));
        var_b = 0xfbb67fda52d4bfb8bf;
        return storage_map_m[var_b];
        require((storage_map_m[var_b] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        return 0x01;
        require((storage_map_p[var_b] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        return 0x01;
        require((storage_map_q[var_b] >> 0x60) == 0xfbb67fda52d4bfb8bf);
        return 0x01;
        return 0;
    }
    
    /// @custom:selector    0x5699c7b1
    /// @custom:signature   getPendingWithdrawal(address arg0, address arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getPendingWithdrawal(address arg0, address arg1) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
    }
    
    /// @custom:selector    0xbf92f58d
    /// @custom:signature   getAccountEquityByUserId(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function getAccountEquityByUserId(uint32 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        var_b = 0x9225a2d8e25375b189f7676090bd6b2890860e3abde43b71ff154cb0823f4f00;
        require(!(uint96(storage_map_m[var_b])), CustomError_35278d12());
        require(0x01 < (uint96(storage_map_m[var_b]) >> 0x01), CustomError_35278d12());
        uint96 var_e = (var_e + ((uint96(storage_map_m[var_b]) >> 0x01) << 0x05)) + 0x20;
        require(block.chainid == 0x1039, CustomError_35278d12());
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503, CustomError_35278d12());
        var_b = uint32(arg0);
        require(!storage_map_m[var_b], CustomError_35278d12());
        require(!(storage_map_m[var_b] > 0), CustomError_35278d12());
        address var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        require(!(0 < 0), CustomError_35278d12());
        var_b = 0x35278d12;
        require(!((!storage_map_m[var_b] | ((storage_map_m[var_b] * 0) / storage_map_m[var_b] == 0)) > (~(storage_map_m[var_b]) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        var_b = 0xedcd4dd4;
        require((!0 < 0) & ((0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) | ((0 < 0) & (!(0 + ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000)) < ((storage_map_m[var_b] * 0) / 0x0de0b6b3a7640000))));
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!(var_e.length < 0), CustomError_35278d12());
        var_h = address(var_f);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!uint32(arg0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_h = uint32(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_68501aee(var_h); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_h = 0;
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_73b15320(var_h); // staticcall
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                require(block.chainid == 0xaa39db);
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(storage_map_m[var_b] >> 0x60);
            require(storage_map_p[var_b] >> 0x60);
        }
    }
    
    /// @custom:selector    0xc489744b
    /// @custom:signature   getTokenBalance(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getTokenBalance(address arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_b); // staticcall
        var_c = 0;
        require(0);
        require(block.chainid == 0xaa39db);
        require(!(address(arg1)) == 0x8c49baeec2ea2356598ef33ea5dd52267643e677);
        return storage_map_am[var_c];
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - (uint32(var_e.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8456cb59(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_x[var_g])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        unresolved_5c975abb = (uint248(unresolved_5c975abb)) | 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        emit Event_62e78cea(address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60));
        emit Event_62e78cea(address(msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec] >> 0x60));
        emit Event_62e78cea(address(msg.sender));
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
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
    
    /// @custom:selector    0xe248e964
    /// @custom:signature   Unresolved_e248e964(address arg0, address arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e248e964(address arg0, address arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_c[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        require(!(address(arg0)), CustomError_f5a267f1());
        require(!(address(arg1)), CustomError_f5a267f1());
        require(address(arg1) == 0xfbb67fda52d4bfb8bf, CustomError_f5a267f1());
        var_a = 0xf5a267f1;
        require(!address(arg1));
        require(!uint96(storage_map_c[var_a]));
        var_a = address(arg1);
        require(!storage_map_c[var_a]);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_e = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_f = address(msg.sender);
        var_i = 0x64;
        require(((var_j + 0xa0) > 0xffffffffffffffff) | ((var_j + 0xa0) < var_j));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_j = var_j + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_f); // staticcall
        require(!ret0.length);
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_l = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_l); // staticcall
        require(block.chainid == 0x1039);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        require(!0x53f10facfc8965750494e6965f5d6da39b41d852);
        var_l = address(arg0);
        (bool success, bytes memory ret0) = address(getPerpsManager).Unresolved_17df7cdc(var_l); // staticcall
        if (block.chainid == 0x1039) {
            require(block.chainid == 0x1039);
            require(0 < var_a);
            require(!0 < var_a);
        }
        var_a = address(arg1);
        require(!address(storage_map_c[var_a]));
        (bool success, bytes memory ret0) = address(arg1).decimals(); // staticcall
        require(!(!address(storage_map_c[var_a])) | (0x0de0b6b3a7640000 == ((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / (address(storage_map_c[var_a])))));
        require(0 > 0x4d);
        require(!0x01);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_l = address(this);
        (bool success, bytes memory ret0) = address(arg1).Unresolved_70a08231(var_l); // staticcall
        require(!(!0 < (address(storage_map_c[var_a]))), CustomError_508b733b());
        var_a = 0x508b733b00000000000000000000000000000000000000000000000000000000;
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_l = address(arg0);
        (bool success, bytes memory ret0) = address(store_i).Unresolved_2b956ff7(var_l); // staticcall
        var_a = 0;
        require(0, CustomError_35278d12());
        require(block.chainid == 0xaa39db, CustomError_35278d12());
        require(!(address(arg1) == 0x8c49baeec2ea2356598ef33ea5dd52267643e677), CustomError_35278d12());
        require(!(((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01) < 0), CustomError_35278d12());
        var_a = 0x35278d12;
        require(!(storage_map_c[var_a] < 0), CustomError_861da4bd());
        require(!(!storage_map_c[var_a] < ((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01)), CustomError_861da4bd());
        uint32 var_p = (address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01;
        require(block.chainid == 0x1039);
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503);
        var_l = address(arg1);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_d02641a0(var_l); // staticcall
        var_l = address(arg1);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_44e79a98(var_l); // staticcall
        require(0, CustomError_bac65e5b());
        require(((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01) > 0, CustomError_bac65e5b());
        require(!0, CustomError_bac65e5b());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        var_a = 0x1a40f9e600000000000000000000000000000000000000000000000000000000;
        require(0 == (((((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01) * 0) / 0x0de0b6b3a7640000) > 0xffffffffffffffffffffffffffffffff), CustomError_1a40f9e6());
        require(((var_j + 0xc0) > 0xffffffffffffffff) | ((var_j + 0xc0) < var_j), CustomError_1a40f9e6());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_j = var_j + 0xc0;
        isEmergencyPaused = (uint248(isEmergencyPaused)) | 0x01;
        isEmergencyPaused = (uint32(isEmergencyPaused) | (uint64(block.timestamp << 0x08))) | (address(this << 0x48));
        store_l = 0x4f5241434c455f44454752414445440000000000000000000000000000000000;
        store_ac = (address(store_ac)) | 0xffffffffffffffffffffffffffffffff;
        store_ad = (uint96(store_ad)) | (address(arg1));
        emit EmergencyTriggered(address(this), address(arg1), 0x4f5241434c455f44454752414445440000000000000000000000000000000000, (((address(storage_map_c[var_a]) * 0x0de0b6b3a7640000) / 0x01) * 0) / 0x0de0b6b3a7640000, block.timestamp);
        require(bytes1(isEmergencyPaused), CustomError_1a40f9e6());
        if (((var_j + 0xc0) > 0xffffffffffffffff) | ((var_j + 0xc0) < var_j)) {
            require(((var_j + 0xc0) > 0xffffffffffffffff) | ((var_j + 0xc0) < var_j));
        }
        require(0x20 > ret0.length);
        require(((var_j + 0x20) > 0xffffffffffffffff) | ((var_j + 0x20) < var_j));
        var_j = var_j + 0x20;
        require(((var_j + 0x20) - var_j) < 0x20);
        var_n = address(arg1);
        (bool success, bytes memory ret0) = address(getRisexOracle).isTokenOracleDegraded(var_n); // staticcall
        if (0) {
        }
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                require(block.chainid == 0xaa39db, CustomError_1f2a2005());
            }
            require(block.chainid == 0xaa39db, CustomError_1f2a2005());
        }
        if (block.chainid == 0xaa39db) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
                if (!0) {
                }
                if (!0) {
                }
            }
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        var_n = 0x40;
        var_o = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l, var_n, var_o, var_p); // call
        if (var_z < 0x40) {
            require(var_z < 0x40);
            require(((0x60 + var_z) - 0x60) < 0x40);
            require(var_i - var_i);
            require(var_e - (uint32(var_e)));
        }
        require(!var_z < 0x20);
        require(((0x60 + var_z) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        require((storage_map_c[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_j[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require((storage_map_k[var_a] >> 0x60) == (address(arg1)), CustomError_dc0394b7());
        require(!0x01, CustomError_dc0394b7());
        var_a = 0xdc0394b700000000000000000000000000000000000000000000000000000000;
        if (!uint96(storage_map_c[var_a])) {
            require(!(uint96(storage_map_c[var_a])), CustomError_d92e233d());
            require((storage_map_c[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
            require((storage_map_j[var_a] >> 0x60) == 0xfbb67fda52d4bfb8bf, CustomError_d92e233d());
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
    
    /// @custom:selector    0xc7a5a847
    /// @custom:signature   Unresolved_c7a5a847(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c7a5a847(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require(0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_93282d79());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_93282d79());
        require(!0, CustomError_93282d79());
        require(!(bytes1(isEmergencyPaused)), CustomError_93282d79());
        require((block.timestamp - (uint64(isEmergencyPaused >> 0x08))) > block.timestamp, CustomError_93282d79());
        isEmergencyPaused = 0;
        store_l = 0;
        store_ac = 0;
        store_ad = 0;
        emit EmergencyCleared(msg.sender, block.timestamp - (uint64(isEmergencyPaused >> 0x08)));
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
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
    }
}