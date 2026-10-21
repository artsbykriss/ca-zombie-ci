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
    uint256 public constant trustedForwarder = 975476479197578754380570792693345865990791187070;
    
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_d;
    address public getFundingRate;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_s;
    address public getRisexAuthorization;
    address public getRisexOracle;
    mapping(bytes32 => bytes32) storage_map_j;
    bool public unresolved_5c975abb;
    mapping(bytes32 => bytes32) storage_map_y;
    mapping(bytes32 => bytes32) storage_map_k;
    address public authority;
    address public getAccountRegistry;
    mapping(bytes32 => bytes32) storage_map_i;
    address public getOrdersManager;
    uint16 public getTotalMarkets;
    address public getCollateralManager;
    mapping(bytes32 => bytes32) storage_map_m;
    mapping(bytes32 => bytes32) storage_map_p;
    bytes32 store_t;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_u;
    address public getFeeManager;
    bool store_o;
    
    error InvalidInitialization();
    event Event_62e78cea();
    event Event_5db9ee0a();
    event AuthorityUpdated(address);
    event SetMarketLock(uint16, bool);
    event SetOpenInterestLimit(uint16, uint32, uint32);
    event SetImpactNotionalBaseUsdc(uint16, uint64, uint64);
    
    /// @custom:selector    0x62d0ee3e
    /// @custom:signature   Unresolved_62d0ee3e(uint256 arg0, address arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_62d0ee3e(uint256 arg0, address arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(((msg.data.length - arg0) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60, CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.data[arg0 + 0x24] - (address(msg.data[arg0 + 0x24])));
        uint256 var_k = address(msg.data[arg0 + 0x24]);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_i + 0x60) > 0xffffffffffffffff) | ((var_i + 0x60) < var_i));
        var_i = var_i + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(!uint16(getTotalMarkets));
        require(arg0 + (msg.data[arg0 + 0x44]) > 0xffffffffffffffff);
        require(var_n < (arg0 + (msg.data[arg0 + 0x44])));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(arg0 + (msg.data[arg0 + 0x44]) > 0xffffffffffffffff);
        require(!var_n < (arg0 + (msg.data[arg0 + 0x44])));
        require((var_n << 0x06) + (0x20 + (arg0 + (msg.data[arg0 + 0x44]))) - (address((var_n << 0x06) + (0x20 + (arg0 + (msg.data[arg0 + 0x44]))))));
        var_r = address((var_n << 0x06) + (0x20 + (arg0 + (msg.data[arg0 + 0x44]))));
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_r); // staticcall
        if (uint32(var_n) == (uint32(var_n))) {
            if (!uint16(getTotalMarkets)) {
            }
            require(uint32(var_n) == (uint32(var_n)));
        }
        require(arg0 + (msg.data[arg0 + 0x44]) > 0xffffffffffffffff);
        require(!var_n < (arg0 + (msg.data[arg0 + 0x44])));
        require((var_n << 0x06) + (0x20 + (arg0 + (msg.data[arg0 + 0x44]))) - (address((var_n << 0x06) + (0x20 + (arg0 + (msg.data[arg0 + 0x44]))))));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        var_a = bytes1(arg0 >> 0x08);
        var_b = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
        storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
        if (!(~(0x01 << (arg0))) & (storage_map_a[var_a])) {
        }
        if (0x20 > ret0.length) {
        }
        require(!(uint32(var_b)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(!uint32(var_i)), CustomError_2d9bc357());
        if (!uint32(var_b)) {
        }
        require(0xe0 > ret0.length);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(((var_i + 0xe0) - var_i) < 0xe0);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(var_i.length - (uint32(var_i.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_l = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_l = 0x40;
        var_m = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_l, var_m, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_n - var_n);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
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
    
    /// @custom:selector    0xf07709de
    /// @custom:signature   Unresolved_f07709de(address arg0, uint32 arg1, uint16 arg2, address arg3) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f07709de(address arg0, uint32 arg1, uint16 arg2, address arg3) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (uint16(arg2)));
        require(arg3 - (address(arg3)));
        require(msg.sender - address(this), CustomError_728bc590());
        require(uint16(arg2));
        require(uint16(arg2) > (uint16(getTotalMarkets)));
        return 0;
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_c = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_c); // staticcall
        require(0);
        require(((var_f + 0x60) > 0xffffffffffffffff) | ((var_f + 0x60) < var_f));
        uint256 var_f = var_f + 0x60;
        address var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_k); // call
        require(var_s);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_k); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            require(0);
            var_a = bytes1(arg2 >> 0x08);
            var_t = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_a[var_a] = (~(0x01 << (bytes1(arg2)))) & (storage_map_a[var_a]);
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        }
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(!uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_f)), CustomError_2d9bc357());
        require(!(!uint32(var_f)), CustomError_2d9bc357());
        require(0xe0 > ret0.length);
        require(((var_f + 0xe0) > 0xffffffffffffffff) | ((var_f + 0xe0) < var_f));
        var_f = var_f + 0xe0;
        require(((var_f + 0xe0) - var_f) < 0xe0);
        require(((var_f + 0xe0) > 0xffffffffffffffff) | ((var_f + 0xe0) < var_f));
        var_f = var_f + 0xe0;
        require(var_f.length - (uint32(var_f.length)));
        require(var_p - (uint32(var_p)));
        var_c = address(this);
        var_d = uint16(arg2);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_c, var_d); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        require(!uint16(arg2));
        return 0;
    }
    
    /// @custom:selector    0xcb63a701
    /// @custom:signature   Unresolved_cb63a701(uint16 arg0, uint0 arg1, address arg2, uint256 arg3, uint0 arg4) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint0", "bytes0", "int0"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint0", "bytes0", "int0"]
    function Unresolved_cb63a701(uint16 arg0, uint0 arg1, address arg2, uint256 arg3, uint0 arg4) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint40(arg1)));
        require(arg2 - (address(arg2)));
        require(arg4 - (bytes1(arg4)));
        require(block.chainid == 0x1039, CustomError_7cb45f65());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        require(msg.sender - (address(getOrdersManager)), CustomError_7cb45f65());
        require(bytes1(arg4), CustomError_bac65e5b());
        return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
        require(!(0x02 > (bytes1(arg1))), CustomError_bac65e5b());
        var_a = uint32(arg1 >> 0x01);
        require(address(arg2) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / arg3), CustomError_bac65e5b());
        require(!arg3, CustomError_bac65e5b());
        var_a = uint32(arg1 >> 0x01);
        if (!storage_map_a[var_a]) {
            require(!storage_map_a[var_a], CustomError_7cb45f65());
            require((storage_map_a[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_a[var_a], CustomError_7cb45f65());
            var_a = uint32(arg1 >> 0x01);
            storage_map_a[var_a] = 0;
            require(((address(arg2) * arg3) / 0x0de0b6b3a7640000) < (storage_map_a[var_a] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), CustomError_7cb45f65());
            var_a = uint16(arg0);
            require(!(uint0(storage_map_h[var_a])), CustomError_7cb45f65());
            require(!(uint64(storage_map_h[var_a] >> 0x60)), CustomError_7cb45f65());
            require(!(uint0(storage_map_h[var_a])), CustomError_7cb45f65());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(0x02 > (bytes1(arg1))), CustomError_7cb45f65());
            require(bytes1(arg1), CustomError_7cb45f65());
            require(!(address(arg2) / (uint64(storage_map_h[var_a] >> 0x60)) > (uint40(storage_map_h[var_a] >> 0xc8))), CustomError_7cb45f65());
            require(!(((address(arg2) * arg3) / 0x0de0b6b3a7640000) > (address(storage_map_h[var_a]))), CustomError_7cb45f65());
            require(!(uint40(storage_map_h[var_a] >> 0xa0)), CustomError_7cb45f65());
            require(!(uint40(storage_map_h[var_a] >> 0xa0)), CustomError_7cb45f65());
            require(!(uint40(storage_map_h[var_a] >> 0xa0)), CustomError_7cb45f65());
            return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
            storage_map_h[var_a] = (((uint40(storage_map_h[var_a] >> 0xa0) << 0xa0) | 0) | 0) | 0x8000000000000000000000000000000000000000000000000000000000000000;
            return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
            require(((((uint40(storage_map_h[var_a] >> 0xa0) << 0xa0) | 0) | 0) | 0x8000000000000000000000000000000000000000000000000000000000000000) - (storage_map_h[var_a]), CustomError_7cb45f65());
            storage_map_h[var_a] = 0;
            return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
            return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
            require(0 - (storage_map_h[var_a]), CustomError_7cb45f65());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(address(storage_map_h[var_a]) - ((address(arg2) * arg3) / 0x0de0b6b3a7640000) > (address(storage_map_h[var_a])), CustomError_7cb45f65());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint40(storage_map_h[var_a] >> 0xc8) - (address(arg2) / (uint64(storage_map_h[var_a] >> 0x60))) > (uint40(storage_map_h[var_a] >> 0xc8)), CustomError_7cb45f65());
        }
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return 0xcb63a70100000000000000000000000000000000000000000000000000000000;
        require(storage_map_a[var_a] - ((address(arg2) * arg3) / 0x0de0b6b3a7640000) > storage_map_a[var_a], CustomError_7cb45f65());
        require(msg.sender - 0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x9f919480
    /// @custom:signature   Unresolved_9f919480(uint16 arg0, uint64 arg1, address arg2) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9f919480(uint16 arg0, uint64 arg1, address arg2) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint64(arg1)));
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        var_a = uint16(arg0);
        storage_map_i[var_a] = (uint192(storage_map_i[var_a])) | (uint64(arg1));
        emit SetImpactNotionalBaseUsdc(uint16(arg0), uint64(storage_map_i[var_a]), uint64(arg1));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_l = address(this);
        uint16 var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).{ value: var_n }Unresolved_c2a15c6e(var_l, var_m); // call
        return ;
        if (0x40 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        var_m = 0x40;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l, var_m); // call
        require(var_r < 0x40);
        require(((0x60 + var_r) - 0x60) < 0x40);
        require(var_n - var_n);
        require(var_s - (uint32(var_s)));
        if (!var_n) {
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
    
    /// @custom:selector    0x73b15320
    /// @custom:signature   getProjectedRealizedPnlAndFunding(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getProjectedRealizedPnlAndFunding(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > var_d) {
            if (!var_d) {
                require(!0x03 > var_d);
                require(!var_d);
                require(!0x03 > var_d);
                require(var_d - 0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                return abi.encodePacked(var_d, var_d);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_k);
                return abi.encodePacked(var_d, var_d);
                require((0x01 + var_d) < var_g.length);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(var_m);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x3ada349a
    /// @custom:signature   Unresolved_3ada349a(uint16 arg0, address arg1, address arg2, uint256 arg3, address arg4, address arg5, address arg6) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg5 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3ada349a(uint16 arg0, address arg1, address arg2, uint256 arg3, address arg4, address arg5, address arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(!arg3 < 0x02);
        require(arg4 - (address(arg4)));
        require(arg5 - (address(arg5)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i), CustomError_6e391b53());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length, CustomError_6e391b53());
        require(!0, CustomError_6e391b53());
        require(!(!uint16(arg0)), CustomError_6e391b53());
        var_a = uint16(arg0);
        require(!(bytes1(storage_map_d[var_a] >> 0xa0)), CustomError_6e391b53());
        require(!(address(arg1) == msg.sender), CustomError_6e391b53());
        address var_k = address(arg2);
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_k); // staticcall
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_r - (uint32(var_r)));
        if (!var_q) {
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
    
    /// @custom:selector    0xba2ecd0e
    /// @custom:signature   Unresolved_ba2ecd0e(address arg0, uint32 arg1, uint16 arg2, uint256 arg3, address arg4, uint256 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_ba2ecd0e(address arg0, uint32 arg1, uint16 arg2, uint256 arg3, address arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (uint16(arg2)));
        require(arg4 - (address(arg4)));
        require(arg5 - arg5);
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0x40;
        require(msg.sender - address(this), CustomError_728bc590());
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_g = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_g); // staticcall
        require(0);
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        address var_m = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_m); // call
        require(var_u);
        var_m = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_m); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            require(0);
            var_b = bytes1(arg2 >> 0x08);
            var_v = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_k[var_b] = (~(0x01 << (bytes1(arg2)))) & (storage_map_k[var_b]);
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        }
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (uint32(var_a.length)));
        require(!(uint32(var_v)), CustomError_2d9bc357());
        require(!(uint32(var_v)), CustomError_2d9bc357());
        require(!(uint32(var_v)), CustomError_2d9bc357());
        require(!(!uint32(var_v)), CustomError_2d9bc357());
        require(!(uint32(var_a)), CustomError_2d9bc357());
        require(!(!uint32(var_a)), CustomError_2d9bc357());
        require(0xe0 > ret0.length);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(((var_a + 0xe0) - var_a) < 0xe0);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(var_a.length - (uint32(var_a.length)));
        require(var_r - (uint32(var_r)));
        var_g = address(this);
        var_h = uint16(arg2);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_g, var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
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
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   Unresolved_7a9e5e4b(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7a9e5e4b(address arg0, address arg1) public payable returns (uint256) {
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
        return ;
    }
    
    /// @custom:selector    0xc804475d
    /// @custom:signature   Unresolved_c804475d(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c804475d(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40, CustomError_3ee5aeb5());
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            if (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01)) {
                transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
                if (!uint16(getTotalMarkets)) {
                }
                var_a = bytes1(arg0 >> 0x08);
                var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
                require(0, CustomError_2d9bc357());
            }
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01), CustomError_2d9bc357());
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
        }
    }
    
    /// @custom:selector    0x2a6945bc
    /// @custom:signature   Unresolved_2a6945bc(uint256 arg0, address arg1, uint32 arg2, uint256 arg3, uint256 arg4) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    function Unresolved_2a6945bc(uint256 arg0, address arg1, uint32 arg2, uint256 arg3, uint256 arg4) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0120);
        require(0x80 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc));
        require(arg4 > 0xffffffffffffffff);
        require(arg4 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5c) < 0x80, CustomError_728bc590());
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0xc0;
        require(msg.sender - address(this), CustomError_728bc590());
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        var_a = var_a + 0x80;
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint32(arg2)));
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        var_a = var_a + 0xc0;
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
    }
    
    /// @custom:selector    0x48b73914
    /// @custom:signature   getTotalCrossFundingFee(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalCrossFundingFee(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > 0x01) {
            if (!0x01) {
                require(!0x03 > 0x01);
                require(!0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                return var_d;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(!(0x01 + var_d) < var_g.length);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(!0x03 > 0x01);
                require(0);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0x01;
                var_c = 0x01;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xf525c412
    /// @custom:signature   Unresolved_f525c412(address arg0, uint256 arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f525c412(address arg0, uint256 arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0xc0;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        var_j = 0x67c721e16e050745796340f2e988cad6af91903f41243b648caa206b8afe3100;
        require(!(!bytes1(storage_map_k[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_l = address(msg.sender);
        require(((var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f))) < var_a), CustomError_89b46ce9());
        var_a = var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_l); // staticcall
        require(!ret0.length, CustomError_89b46ce9());
        require(!0, CustomError_89b46ce9());
        require(arg1 > 0x0f4240, CustomError_89b46ce9());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_1232deb3());
        var_a = var_a + 0x80;
        require(!(arg2), CustomError_1232deb3());
        require(arg2 < 0x03, CustomError_1232deb3());
        require(!(((arg2 + 0x20) >> 0xf8) < 0x20), CustomError_1232deb3());
        require(((arg2 + 0x20) >> 0xf8) > 0x22, CustomError_1232deb3());
        require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)) > 0xff, CustomError_1232deb3());
        require(!(0x03 > (bytes1(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)))), CustomError_1232deb3());
        require(!(0x03 > (bytes1(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)))), CustomError_1232deb3());
        require(!(0x01 < (arg2)), CustomError_1232deb3());
        require(!(0x02 < (arg2)), CustomError_1232deb3());
        require(bytes1(var_a.length) > (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8)), CustomError_1232deb3());
        require(!((!(bytes1(var_a.length)) + (((arg2 + 0x20) + 0x02) >> 0xf8)) | (0x02 == ((bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01) / (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8))))), CustomError_1232deb3());
        require(0x03 > (0x03 + (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01)), CustomError_1232deb3());
        require((0x03 + (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01)) > (arg2), CustomError_1232deb3());
        require(!(0x03 > (var_t)), CustomError_1232deb3());
        require(!(0x03 > (var_t)), CustomError_1232deb3());
        require(var_t == 0x02, CustomError_1232deb3());
        require(var_u == (arg2), CustomError_1232deb3());
        require(0 < (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8)), CustomError_1232deb3());
        require(!(!0 | (0x02 == 0)), CustomError_1232deb3());
        require(0x03 > 0x03, CustomError_1232deb3());
        require(!((0x03 + ((arg2 + 0x20) + 0)) >> 0xf0), CustomError_1232deb3());
        require(var_u < (arg2), CustomError_1232deb3());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_1232deb3());
        var_a = var_a + 0x80;
        require(!(var_u > (arg2)), CustomError_1232deb3());
        require(arg2 - (var_u) > (arg2), CustomError_1232deb3());
        require(arg2 - (var_u) < 0x03, CustomError_1232deb3());
        require(var_u > (var_u + 0x02), CustomError_1232deb3());
        require(!(arg2 > (var_u + 0x02)), CustomError_1232deb3());
        require(!(!uint16(var_a.length)), CustomError_1232deb3());
        require(!((0x02 + (var_u + (arg2 + 0x20))) >> 0xf8), CustomError_1232deb3());
        require(var_u > (var_u + 0x03), CustomError_1232deb3());
        require(!((!bytes1(var_z)) | (0x14 == ((bytes1(var_z) * 0x14) / (bytes1(var_z))))), CustomError_1232deb3());
        require((var_u + 0x03) > ((var_u + 0x03) + (bytes1(var_z) * 0x14)), CustomError_1232deb3());
        require((var_u + 0x03) + (bytes1(var_z) * 0x14) > (arg2), CustomError_1232deb3());
        require(!(var_u < (var_t)), CustomError_1232deb3());
        require(!(var_u > (arg2)), CustomError_1232deb3());
        require(arg2 - (var_u) > (arg2), CustomError_1232deb3());
        require(arg2 - (var_u) < 0x14, CustomError_1232deb3());
        require(!(!((arg2 + 0x20) + (var_u)) >> 0xe0), CustomError_1232deb3());
        require(!(address((arg2 + 0x20) + (var_u) >> 0x60)), CustomError_1232deb3());
        require(var_u > (arg2), CustomError_1232deb3());
        require(var_u > (arg2), CustomError_1232deb3());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e, CustomError_35278d12());
        require(!(!msg.data.length < 0x14), CustomError_35278d12());
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_35278d12());
        var_a = var_a + 0x40;
        uint256 var_aa = address(arg0);
        (bool success, bytes memory ret0) = address(this).executeCrossRiskPreflight(var_aa); // call
        require(!0, CustomError_35278d12());
        require(!(var_j < 0), CustomError_35278d12());
        var_b = 0x35278d12;
        if (!var_j > var_b) {
            if (0 == 0) {
                if (((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a)) {
                    var_a = var_a + 0xc0;
                    if (((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a)) {
                        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!(var_j > var_b), CustomError_1232deb3());
                        var_a = var_a + 0x80;
                        uint256 var_af = address(var_a.length);
                        uint256 var_ag = address(var_z);
                        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_1232deb3());
                        (bool success, bytes memory ret0) = address(this).Unresolved_2a6945bc(var_af, var_ag); // call
                        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_1232deb3());
                        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_1232deb3());
                        require(!(0x03 > (var_t)), CustomError_1232deb3());
                        require(0, CustomError_1232deb3());
                        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!(var_b < 0x07), CustomError_1232deb3());
                        require(0x04 == var_b, CustomError_1232deb3());
                        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!(var_b < 0x07), CustomError_1232deb3());
                        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!(var_j < 0x05), CustomError_1232deb3());
                        require(!(var_b < 0x07), CustomError_1232deb3());
                        require(!(var_j < 0x05), CustomError_1232deb3());
                        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!(var_b < 0x07), CustomError_1232deb3());
                    }
                    var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(!(var_j < 0x05), CustomError_1232deb3());
                }
            }
            require(!(var_b < 0x07), CustomError_1232deb3());
        }
        require(((arg2 + 0x20) >> 0xf8) < 0x20, CustomError_1232deb3());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        uint256 var_ar = address(msg.sender);
        uint256 var_as = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_ar, var_as); // call
        require(var_aw < 0x40);
        require(((0x60 + var_aw) - 0x60) < 0x40);
        require(var_ax - var_ax);
        require(var_ay - (uint32(var_ay)));
        if (!var_ax) {
        }
        require(!var_aw < 0x20);
        require(((0x60 + var_aw) - 0x60) < 0x20);
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
    
    /// @custom:selector    0x6d7b773e
    /// @custom:signature   setImpactPriceCache(uint16 arg0, uint88 arg1, uint88 arg2) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint88", "bytes11", "int88"]
    /// @param              arg2 ["uint88", "bytes11", "int88"]
    function setImpactPriceCache(uint16 arg0, uint88 arg1, uint88 arg2) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint88(arg1)));
        require(arg2 - (uint88(arg2)));
        require(block.chainid == 0x1039, CustomError_7cb45f65());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        require(msg.sender - (address(getOrdersManager)), CustomError_7cb45f65());
        uint16 var_a = uint16(arg0);
        storage_map_i[var_a] = (uint88(arg2 << 0x98) | (uint72(storage_map_i[var_a]) | (uint88(arg1 << 0x40)))) | 0x01000000000000000000000000000000000000000000000000000000000000;
        return ;
        require(msg.sender - 0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        var_a = uint16(arg0);
        storage_map_i[var_a] = (uint88(arg2 << 0x98) | (uint72(storage_map_i[var_a]) | (uint88(arg1 << 0x40)))) | 0x01000000000000000000000000000000000000000000000000000000000000;
        return ;
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xdff0351c
    /// @custom:signature   executeCrossRiskTakeover(address arg0, uint32 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function executeCrossRiskTakeover(address arg0, uint32 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (address(arg2)));
        require(msg.sender - address(this), CustomError_728bc590());
        require(!uint16(getTotalMarkets));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_d));
        uint248 var_d = var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(((var_d + 0x60) > 0xffffffffffffffff) | ((var_d + 0x60) < var_d));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        uint32 var_k = uint32(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_68501aee(var_k); // staticcall
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        var_k = uint32(arg1);
        (bool success, bytes memory ret0) = address(getCollateralManager).Unresolved_af9fa7b6(var_k); // staticcall
        if (!0x03 > 0) {
            if (!0) {
                if (!0x03 > 0) {
                    if (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                        if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                            if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                                require(!0x03 > 0);
                                var_d = var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                                require(!0x03 > 0);
                                require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                                require(((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_d));
                                var_a = 0;
                                var_a = 0;
                                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                                var_a = 0x01;
                                var_a = 0x01;
                                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                            }
                            require((!0 < 0) & (0 < 0) | ((0 < 0) & (!0 < 0)));
                            require(var_m);
                        }
                    }
                    require(var_m);
                }
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x9a9442c8
    /// @custom:signature   Unresolved_9a9442c8(uint256 arg0, address arg1, uint32 arg2, uint16 arg3, uint256 arg4, uint256 arg5) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint16", "bytes2", "int16"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_9a9442c8(uint256 arg0, address arg1, uint32 arg2, uint16 arg3, uint256 arg4, uint256 arg5) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0140);
        require(0xa0 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc));
        require(arg5 > 0xffffffffffffffff);
        require(arg5 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3c) < 0x80, CustomError_728bc590());
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0xc0;
        require(msg.sender - address(this), CustomError_728bc590());
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a));
        var_a = var_a + 0xa0;
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint16(arg3)));
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        var_a = var_a + 0x80;
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
    }
    
    /// @custom:selector    0x50f06898
    /// @custom:signature   Unresolved_50f06898(uint16 arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_50f06898(uint16 arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            if (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01)) {
                transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
                require(0, CustomError_2d9bc357());
                var_a = bytes1(arg0 >> 0x08);
                var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
                require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01), CustomError_2d9bc357());
            }
            require(arg1 > 0xffffffffffffffff, CustomError_2d9bc357());
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
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
        address var_b = address(msg.sender);
        require(((var_f + (uint248(((var_f + 0x84) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248(((var_f + 0x84) - var_f) + 0x1f))) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_m[var_g])), CustomError_965ad3ca());
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
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_r - (uint32(var_r)));
        if (!var_q) {
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
    
    /// @custom:selector    0xa3937aa8
    /// @custom:signature   getActiveIsolatedMarkets(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getActiveIsolatedMarkets(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
            if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_h = msg.data[4:36];
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                return abi.encodePacked(0x20, var_g.length);
                return abi.encodePacked(0x20, var_g.length, var_l);
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_n);
                var_c = 0x01;
                var_c = 0x01;
                require(var_n);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x5747dfc4
    /// @custom:signature   getMarketConfig(uint16 arg0) public pure
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function getMarketConfig(uint16 arg0) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        require(((var_a + 0x0160) > 0xffffffffffffffff) | ((var_a + 0x0160) < var_a));
    }
    
    /// @custom:selector    0x044c9eb8
    /// @custom:signature   getLeverage(uint16 arg0, address arg1) public payable returns (bool)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getLeverage(uint16 arg0, address arg1) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = 0;
        var_c = uint16(arg0);
        require(bytes1(storage_map_n[var_c] >> 0x80));
        require(address(bytes1(bytes1(storage_map_n[var_c] >> 0x80)) * 0x0de0b6b3a7640000) - (address(bytes1(bytes1(storage_map_n[var_c] >> 0x80))) * 0x0de0b6b3a7640000));
        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint16 var_a = address(bytes1(bytes1(storage_map_n[var_c] >> 0x80)) * 0x0de0b6b3a7640000);
        return address(bytes1(bytes1(storage_map_n[var_c] >> 0x80)) * 0x0de0b6b3a7640000);
        require(0x20 > ret0.length);
        require((0x0120 > 0xffffffffffffffff) | (0x0120 < 0x0100));
        require(0x20 < 0x20);
        if (var_a - (uint32(var_a))) {
            var_c = uint32(var_a);
            require(var_a - (uint32(var_a)));
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x5bf5d15d
    /// @custom:signature   getTotalMarginAccountableAccountOrderNotional(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalMarginAccountableAccountOrderNotional(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (store_o) {
            if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                    if (((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g)) {
                        uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                        if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                            require(store_o);
                            require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                            var_c = uint32(var_d);
                            require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                            return storage_map_j[var_c] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
                            require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                            var_c = 0;
                            require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                            require(storage_map_j[var_c]);
                        }
                        require((storage_map_j[var_c] + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > storage_map_j[var_c]);
                        var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        require(!bytes1(store_o));
                    }
                    require(storage_map_j[var_c] & (var_j));
                    var_c = 0;
                    var_c = 0;
                    var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                    var_c = 0x01;
                    var_c = 0x01;
                    require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                }
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(block.chainid == 0xaa39db);
            }
        }
    }
    
    /// @custom:selector    0xd662952b
    /// @custom:signature   executeIsolatedRiskTakeover(address arg0, uint32 arg1, uint16 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    function executeIsolatedRiskTakeover(address arg0, uint32 arg1, uint16 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (uint16(arg2)));
        require(arg3 - (address(arg3)));
        require(msg.sender - address(this), CustomError_728bc590());
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_c = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_c); // staticcall
        require(0);
        require(((var_f + 0x60) > 0xffffffffffffffff) | ((var_f + 0x60) < var_f));
        uint256 var_f = var_f + 0x60;
        address var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_k); // call
        require(var_s);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_k); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            require(0);
            var_a = bytes1(arg2 >> 0x08);
            var_t = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_a[var_a] = (~(0x01 << (bytes1(arg2)))) & (storage_map_a[var_a]);
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        }
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(var_f.length - (uint32(var_f.length)));
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_t)), CustomError_2d9bc357());
        require(!(!uint32(var_t)), CustomError_2d9bc357());
        require(!(uint32(var_f)), CustomError_2d9bc357());
        require(!(!uint32(var_f)), CustomError_2d9bc357());
        require(0xe0 > ret0.length);
        require(((var_f + 0xe0) > 0xffffffffffffffff) | ((var_f + 0xe0) < var_f));
        var_f = var_f + 0xe0;
        require(((var_f + 0xe0) - var_f) < 0xe0);
        require(((var_f + 0xe0) > 0xffffffffffffffff) | ((var_f + 0xe0) < var_f));
        var_f = var_f + 0xe0;
        require(var_f.length - (uint32(var_f.length)));
        require(var_p - (uint32(var_p)));
        var_c = address(this);
        var_d = uint16(arg2);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_c, var_d); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x0630f5f5
    /// @custom:signature   getOpenInterest(uint16 arg0) public view returns (address)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function getOpenInterest(uint16 arg0) public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        uint16 var_a = uint16(arg0);
        return address(storage_map_p[var_a]);
    }
    
    /// @custom:selector    0xff508b4a
    /// @custom:signature   Unresolved_ff508b4a(uint32 arg0, address arg1, address arg2, address arg3, uint256 arg4, address arg5) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg3 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ff508b4a(uint32 arg0, address arg1, address arg2, address arg3, uint256 arg4, address arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0, CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(arg1 - (address(arg1)));
        address var_k = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_i + 0x60) > 0xffffffffffffffff) | ((var_i + 0x60) < var_i));
        var_i = var_i + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(!uint16(getTotalMarkets));
        transient[0xab852edd34bad5d9a5ecb3ae9d17a19c459b10fd02f79b7d4e7f72103d28e5e3] = 0x01;
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(arg1 - (address(arg1)));
        var_r = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_r); // staticcall
        require(arg0 - (uint16(arg0)));
        var_a = uint32(var_n);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        var_i = var_i + 0xa0;
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(!arg4 < 0x02);
        var_a = uint16(var_i.length);
        require(!0x02 > (bytes1(storage_map_d[var_a] >> 0x88)));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_d[var_a] >> 0x88));
        require(block.chainid == 0x1039);
        require(!0x8fc4d0cf74cdf595254cb763d4c05d38df0e9503);
        var_x = uint16(var_i.length);
        (bool success, bytes memory ret0) = address(getRisexOracle).Unresolved_dd24e5bd(var_x); // staticcall
        require(block.chainid == 0x1039);
        require(!0x069edf2c2a3c93b54640ae142b9f5375fe4a207a);
        var_x = uint16(var_i.length);
        (bool success, bytes memory ret0) = address(getFundingRate).Unresolved_f1d4d9aa(var_x); // staticcall
        require(((var_i + 0xc0) > 0xffffffffffffffff) | ((var_i + 0xc0) < var_i), CustomError_edcd4dd4());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x02 > (bytes1(storage_map_d[var_a] >> 0x88))), CustomError_edcd4dd4());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(((11 - 11) < 0xffffffffffffffffffffffffffffffff80000000000000000000000000000000) | ((11 - 11) > 0x7fffffffffffffffffffffffffffffff), CustomError_edcd4dd4());
        require(!((!11 | (((11 * 11) / 11) == 11)) > (~(11) < (11 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        require(!(uint112(var_ak) < 0), CustomError_35278d12());
        require(!(0 < 0), CustomError_35278d12());
        require(!((!11 | (((11 * 0) / 11) == 0)) > (~(11) < (0 == 0x8000000000000000000000000000000000000000000000000000000000000000))), CustomError_edcd4dd4());
        if ((!((11 * 0) / 0x0de0b6b3a7640000) < 0) & ((((11 * 0) / 0x0de0b6b3a7640000) + 11) < 11) | ((((11 * 0) / 0x0de0b6b3a7640000) < 0) & (!(((11 * 0) / 0x0de0b6b3a7640000) + 11) < 11))) {
            if (0x60 > ret0.length) {
            }
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                require((!((11 * 0) / 0x0de0b6b3a7640000) < 0) & ((((11 * 0) / 0x0de0b6b3a7640000) + 11) < 11) | ((((11 * 0) / 0x0de0b6b3a7640000) < 0) & (!(((11 * 0) / 0x0de0b6b3a7640000) + 11) < 11)));
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        var_x = uint32(var_n);
        (bool success, bytes memory ret0) = address(getCollateralManager).getTotalTokenBalanceInUSDCByUserId(var_x); // staticcall
        if (!0x03 > 0) {
            if (!0) {
                if (!0x03 > 0) {
                    require(!0x03 > 0);
                    require(!0x03 > 0);
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                    require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                    var_i = var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                    require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                    require(((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_i));
                    require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                    require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                    var_a = 0;
                    var_a = 0;
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require(var_al);
                    var_a = 0x01;
                    var_a = 0x01;
                    require(var_al);
                }
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(block.chainid == 0xaa39db);
            }
        }
        if (0x20 > ret0.length) {
        }
        require(arg1 - (address(arg1)));
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            var_a = bytes1(arg0 >> 0x08);
            var_b = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
            if (!(~(0x01 << (arg0))) & (storage_map_a[var_a])) {
            }
            require(block.chainid == 0xaa39db, CustomError_2d9bc357());
        }
        require(!(uint32(var_b)), CustomError_2d9bc357());
        require(!(uint32(var_am)), CustomError_2d9bc357());
        require(!(uint32(var_am)), CustomError_2d9bc357());
        require(!(!uint32(var_am)), CustomError_2d9bc357());
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(!uint32(var_i)), CustomError_2d9bc357());
        if (!uint32(var_b)) {
        }
        if (0xe0 > ret0.length) {
        }
        var_k = address(this);
        var_l = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        require(arg1 - (address(arg1)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_l = 0x40;
        var_m = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_l, var_m, var_r); // call
        require(var_am < 0x40);
        require(((0x60 + var_am) - 0x60) < 0x40);
        require(var_n - var_n);
        require(var_z - (uint32(var_z)));
        if (!var_n) {
        }
        require(!var_am < 0x20);
        require(((0x60 + var_am) - 0x60) < 0x20);
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
    
    /// @custom:selector    0x77206fd4
    /// @custom:signature   getTotalOpenOrders(uint16 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getTotalOpenOrders(uint16 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_b = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_55e2f7dd(var_b); // staticcall
        return var_e;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        return var_f.length;
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (var_f.length - (uint32(var_f.length))) {
            require(var_f.length - (uint32(var_f.length)));
            require(block.chainid == 0x1039);
            require(block.chainid == 0xaa39db);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x17df7cdc
    /// @custom:signature   getActiveMarkets(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getActiveMarkets(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
            if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_f = var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_g = msg.data[4:36];
                require(((var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_f));
                return abi.encodePacked(0x20, var_f.length);
                return abi.encodePacked(0x20, var_f.length, var_k);
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_c = 0x01;
                var_c = 0x01;
                require(var_m);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
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
        return var_c;
        require(0x20 > ret0.length);
        require(((var_d + 0x20) > 0xffffffffffffffff) | ((var_d + 0x20) < var_d));
        uint256 var_d = var_d + 0x20;
        require(((var_d + 0x20) - var_d) < 0x20);
        require(var_d.length - var_d.length);
        return var_d.length;
    }
    
    /// @custom:selector    0xdab48fdd
    /// @custom:signature   getTotalMarginAccountableOrderNotional(uint16 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getTotalMarginAccountableOrderNotional(uint16 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        var_c = uint32(var_e);
        require(uint0(storage_map_s[var_c]));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_b = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_b); // staticcall
        require(0);
        var_b = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_b); // staticcall
        require(0);
        require(!0);
        return 0;
        require(!0x01);
        return address(storage_map_s[var_c]);
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        uint256 var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        if (var_h.length - var_h.length) {
            require(var_h.length - var_h.length);
        }
        require(0x20 > ret0.length);
        require(((var_h + 0x20) > 0xffffffffffffffff) | ((var_h + 0x20) < var_h));
        var_h = var_h + 0x20;
        require(((var_h + 0x20) - var_h) < 0x20);
        require(var_h.length - (uint32(var_h.length)));
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xbb4b15f0
    /// @custom:signature   getTotalCrossUnsettledUsdc(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalCrossUnsettledUsdc(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > 0x01) {
            if (!0x01) {
                require(!0x03 > 0x01);
                require(!0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                return var_d;
                require(block.chainid == 0x1039);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                require((0x01 + var_d) < var_g.length);
                require(!(0x01 + var_d) < var_g.length);
                return var_d;
                require(block.chainid == 0xaa39db);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_d < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(!var_d < var_g.length);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(!0x03 > 0x01);
                require(0);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0x01;
                var_c = 0x01;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x35876476
    /// @custom:signature   initialize(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5, address arg6) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg6 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0, address arg1, address arg2, address arg3, address arg4, address arg5, address arg6) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (address(arg4)));
        require(arg5 - (address(arg5)));
        require(arg6 - (address(arg6)));
        require(!(uint64(store_t)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_t)), CustomError_d7e6bcf8());
        require(!(!uint64(store_t)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_t = (uint192(store_t)) | 0x01;
        require(!(bytes1(store_t >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_t >> 0x40)), CustomError_d7e6bcf8());
        require(!(address(arg0)), CustomError_d7e6bcf8());
        require(!(bytes1(store_t >> 0x40)), CustomError_d7e6bcf8());
        store_t = 0x010000000000000001 | (uint184(store_t));
        require(!(bytes1(store_t >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_t)), CustomError_f92ee8a9());
        if (uint64(store_t)) {
        }
        if (0x01 == (uint64(store_t))) {
        }
    }
    
    /// @custom:selector    0x987649f3
    /// @custom:signature   Unresolved_987649f3(uint32 arg0, uint16 arg1, uint256 arg2, uint256 arg3) public payable returns (bytes memory)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg4 ["uint256", "bytes32", "int256"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_987649f3(uint32 arg0, uint16 arg1, uint256 arg2, uint256 arg3) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0, CustomError_728bc590());
        require(0xa0 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc), CustomError_728bc590());
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0x40;
        require(msg.sender - address(this), CustomError_728bc590());
        require(!arg1 == (uint16(arg1)));
        require(!(uint16(getTotalMarkets)) < (uint16(arg1)));
        require(!(uint16(getTotalMarkets)) < (uint16(arg1)));
        require(uint16(getTotalMarkets) < (uint16(arg1)));
        return abi.encodePacked(0, var_a.length, var_j);
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(!arg1 == (uint16(arg1)));
        require(arg0 - (uint32(arg0)));
        address var_k = address(this);
        uint16 var_l = uint16(arg1);
        uint32 var_m = uint32(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_55e2f7dd(var_k, var_l, var_m); // staticcall
        require(0);
        return abi.encodePacked(0, var_a.length, var_j);
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        var_l = uint16(arg1);
        var_m = uint32(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k, var_l, var_m); // staticcall
        require(0);
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        address var_o = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_o); // call
        require(var_v);
        var_o = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_o); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(!uint16(getTotalMarkets));
        require(!arg4 < 0x02);
        if (((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a)) {
            var_a = var_a + 0x40;
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            require(!0x02 > arg4);
            require(arg4 == 0x01);
            var_a = var_a + 0x40;
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            var_b = bytes1(arg1 >> 0x08);
            var_z = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_k[var_b] = (~(0x01 << (bytes1(arg1)))) & (storage_map_k[var_b]);
            require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        }
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (uint32(var_a.length)));
        require(!(uint32(var_z)), CustomError_2d9bc357());
        require(!(uint32(var_z)), CustomError_2d9bc357());
        require(!(uint32(var_z)), CustomError_2d9bc357());
        require(!(!uint32(var_z)), CustomError_2d9bc357());
        require(!(uint32(var_a)), CustomError_2d9bc357());
        require(!(!uint32(var_a)), CustomError_2d9bc357());
        require(0xe0 > ret0.length);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(((var_a + 0xe0) - var_a) < 0xe0);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(var_a.length - (uint32(var_a.length)));
        require(var_i - (uint32(var_i)));
        var_k = address(this);
        var_l = uint16(arg1);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        require(!arg1 == (uint16(arg1)));
        require(arg0 - (uint32(arg0)));
        require(!arg1 == (uint16(arg1)));
        require(arg0 - (uint32(arg0)));
        var_b = uint32(arg0);
        require(!arg4 < 0x02);
        var_b = uint16(arg1);
        require(bytes1(storage_map_u[var_b] >> 0xa0));
        require(!bytes1(storage_map_u[var_b] >> 0xa0));
        return abi.encodePacked(0, var_a.length, var_j);
    }
    
    /// @custom:selector    0x59c0b4eb
    /// @custom:signature   getCrossMarginBalance(int256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getCrossMarginBalance(int256 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > var_d) {
            if (!var_d) {
                require(!0x03 > var_d);
                require(!var_d);
                require(!0x03 > var_d);
                require(var_d - 0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                return arg0 + var_d;
                require(var_d < var_g.length);
                require((!arg0 < 0) & ((arg0 + var_d) < var_d) | ((arg0 < 0) & (!(arg0 + var_d) < var_d)));
                require(!var_d < var_g.length);
                require(var_j);
                require((0x01 + var_d) < var_g.length);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(var_l);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x8fb36037
    /// @custom:signature   isConsumingScheduledOp() public view returns (uint256)
    function isConsumingScheduledOp() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < var_a);
        if (!authority >> 0xa0) {
            return 0x8fb3603700000000000000000000000000000000000000000000000000000000;
            return uint32(var_a);
        }
    }
    
    /// @custom:selector    0xfb14ed2c
    /// @custom:signature   getOpenOrders(uint16 arg0, address arg1, uint256 arg2, uint256 arg3) public payable returns (bytes memory)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function getOpenOrders(uint16 arg0, address arg1, uint256 arg2, uint256 arg3) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_b = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_4f2af03e(var_b); // staticcall
        return abi.encodePacked(0x20, var_e.length);
        require(((var_i + (uint248(ret0.length + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(ret0.length + 0x1f))) < var_i));
        uint256 var_i = var_i + (uint248(ret0.length + 0x1f));
        require(((var_i + ret0.length) - var_i) < 0x20);
        require(var_i.length > 0xffffffffffffffff);
        require(!((var_i + var_i.length) + 0x1f) < (var_i + ret0.length));
        require(var_l > 0xffffffffffffffff);
        require(((var_i + (uint248((0x20 + (var_m << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (var_m << 0x05)) + 0x1f))) < var_i));
        var_i = var_i + (uint248((0x20 + (var_m << 0x05)) + 0x1f));
        require(((var_i + var_i.length) + (var_m << 0x05) + 0x20) > (var_i + ret0.length));
        require((0x20 + (var_i + var_i.length)) < ((var_i + var_i.length) + (var_m << 0x05) + 0x20));
        require(var_n - (uint40(var_n)));
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x626a686b
    /// @custom:signature   pausedFunction(bytes4 arg0) public view returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function pausedFunction(bytes4 arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        require(!bytes1(storage_map_j[var_c]));
        return !(!bytes1(storage_map_j[var_c]));
        return !(!bytes1(unresolved_5c975abb));
    }
    
    /// @custom:selector    0x139e4683
    /// @custom:signature   Unresolved_139e4683(uint16 arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_139e4683(uint16 arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - arg1);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i), CustomError_38c81bce());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length, CustomError_38c81bce());
        require(!0, CustomError_38c81bce());
        require(!arg1, CustomError_38c81bce());
        require(!(!uint16(arg0)), CustomError_38c81bce());
        require(!(uint16(getTotalMarkets) < (uint16(arg0))), CustomError_38c81bce());
        require(!(!(uint16(getTotalMarkets)) < (uint16(arg0))), CustomError_38c81bce());
        var_a = uint16(arg0);
        storage_map_d[var_a] = (uint248(storage_map_d[var_a])) | (bytes1(arg1 << 0xa0));
        emit SetMarketLock(uint16(arg0), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!(!uint16(arg0)), CustomError_38c81bce());
        require(!(uint16(arg0)), CustomError_38c81bce());
        var_a = uint16(arg0);
        storage_map_d[var_a] = (uint248(storage_map_d[var_a])) | (bytes1(arg1 << 0xa0));
        emit SetMarketLock(uint16(arg0), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!(!uint16(arg0)), CustomError_38c81bce());
        var_a = uint16(arg0);
        require(!(bytes1(storage_map_d[var_a] >> 0xa0)), CustomError_38c81bce());
        var_a = uint16(arg0);
        storage_map_d[var_a] = (uint248(storage_map_d[var_a])) | (bytes1(arg1 << 0xa0));
        emit SetMarketLock(uint16(arg0), arg1);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_r - (uint32(var_r)));
        if (!var_q) {
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
    
    /// @custom:selector    0x317e8d9c
    /// @custom:signature   Unresolved_317e8d9c(uint256 arg0, address arg1, address arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_317e8d9c(uint256 arg0, address arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(((msg.data.length - arg0) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0, CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require((arg0 + (arg0) + 0x20) - (address(arg0 + (arg0) + 0x20)));
        require(block.chainid == 0xaa39db);
        require((arg0 + (arg0) + 0x20) - (address(arg0 + (arg0) + 0x20)));
        require(!(address(arg0 + (arg0) + 0x20) == 0x8c49baeec2ea2356598ef33ea5dd52267643e677), CustomError_db5330de());
        require((arg0 + (arg0) + 0x20) - (address(arg0 + (arg0) + 0x20)));
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_r - (uint32(var_r)));
        if (!var_q) {
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
    
    /// @custom:selector    0xce330cd8
    /// @custom:signature   getTotalCrossMaintenanceMargin(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalCrossMaintenanceMargin(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > 0x01) {
            if (!0x01) {
                require(!0x03 > 0x01);
                require(!0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(block.chainid == 0x1039);
                return var_d;
                require(block.chainid == 0x1039);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                require((0x01 + var_d) < var_g.length);
                require(!(0x01 + var_d) < var_g.length);
                return var_d;
                require(block.chainid == 0xaa39db);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(block.chainid == 0xaa39db);
                return var_d;
                require(block.chainid == 0x1039);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                return var_d;
                require(block.chainid == 0xaa39db);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_d < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(!var_d < var_g.length);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(!0x03 > 0x01);
                require(0);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0x01;
                var_c = 0x01;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xbb08aff3
    /// @custom:signature   Unresolved_bb08aff3(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_bb08aff3(address arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(!uint16(getTotalMarkets));
        require(!uint16(getTotalMarkets));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_i));
        var_i = var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        uint256 var_n = 0;
        (bool success, bytes memory ret0) = address(getCollateralManager).Unresolved_af9fa7b6(var_n); // staticcall
        require(!(0x03 > 0), CustomError_35278d12());
        require(!0, CustomError_35278d12());
        require(!(0x03 > 0), CustomError_35278d12());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_35278d12());
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_i), CustomError_35278d12());
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require((!0 < 0) & (0 < 0) | ((0 < 0) & (!0 < 0)), CustomError_35278d12());
        require(!(0 < 0), CustomError_35278d12());
        if (var_o) {
            if (var_o) {
                var_a = 0;
                var_a = 0;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                    var_a = 0x01;
                    var_a = 0x01;
                    if (0x20 > ret0.length) {
                    }
                    if (block.chainid == 0xaa39db) {
                        require(var_o);
                    }
                    require(var_o);
                    require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                }
                transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = var_q;
                return ;
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_r = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_r, var_n); // call
        require(var_u < 0x40);
        require(((0x60 + var_u) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_v - (uint32(var_v)));
        if (!var_q) {
        }
        require(!var_u < 0x20);
        require(((0x60 + var_u) - 0x60) < 0x20);
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
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a(uint32 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3f4ba83a(uint32 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < var_a);
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length);
        require(!0);
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(!address(getOrdersManager).code.length);
        (bool success, bytes memory ret0) = address(getOrdersManager).{ value: var_a }unpause(); // call
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        require(!address(getCollateralManager).code.length);
        (bool success, bytes memory ret0) = address(getCollateralManager).{ value: var_a }unpause(); // call
        require(!bytes1(unresolved_5c975abb));
        unresolved_5c975abb = uint248(unresolved_5c975abb);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        emit Event_5db9ee0a(address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60));
        return ;
        emit Event_5db9ee0a(address(msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec] >> 0x60));
        return ;
        emit Event_5db9ee0a(address(msg.sender));
        return ;
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_a - var_a);
        require(var_q - (uint32(var_q)));
        if (!var_a) {
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
    
    /// @custom:selector    0x88fe10f4
    /// @custom:signature   getImpactNotionalBaseUsdc(uint16 arg0) public view returns (uint64)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function getImpactNotionalBaseUsdc(uint16 arg0) public view returns (uint64) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        uint16 var_a = uint16(arg0);
        return uint64(storage_map_i[var_a]);
    }
    
    /// @custom:selector    0x9d886bda
    /// @custom:signature   getPosition(uint16 arg0, address arg1) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getPosition(uint16 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        uint256 var_a = var_a + 0xc0;
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        var_a = var_a + 0xc0;
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (uint32(var_a.length)));
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x784584b7
    /// @custom:signature   Unresolved_784584b7(address arg0, uint16 arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_784584b7(address arg0, uint16 arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(uint16(arg1));
        var_a = uint16(arg1);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_i + 0x60) > 0xffffffffffffffff) | ((var_i + 0x60) < var_i));
        var_i = var_i + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(!uint16(getTotalMarkets));
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        var_r = uint32(var_n);
        (bool success, bytes memory ret0) = address(getCollateralManager).Unresolved_af9fa7b6(var_r); // staticcall
        require(!(0x03 > 0), CustomError_35278d12());
        require(!0, CustomError_35278d12());
        require(!(0x03 > 0), CustomError_35278d12());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_35278d12());
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_i), CustomError_35278d12());
        var_i = var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        var_w = msg.data[4:36];
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require((!0 < 0) & (0 < 0) | ((0 < 0) & (!0 < 0)), CustomError_35278d12());
        require(!(0 < 0), CustomError_35278d12());
        if (var_aa) {
            if (var_aa) {
                var_a = 0;
                var_a = 0;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                    var_a = 0x01;
                    var_a = 0x01;
                    if (0x20 > ret0.length) {
                    }
                    require(var_aa, CustomError_2d9bc357());
                    require(var_aa, CustomError_2d9bc357());
                }
                var_a = bytes1(arg1 >> 0x08);
                var_b = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg1)))) & (storage_map_a[var_a]);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_2d9bc357());
            }
            require(block.chainid == 0xaa39db, CustomError_2d9bc357());
        }
        require(!(uint32(var_b)), CustomError_2d9bc357());
        require(!(uint32(var_ac)), CustomError_2d9bc357());
        require(!(uint32(var_ac)), CustomError_2d9bc357());
        require(!(!uint32(var_ac)), CustomError_2d9bc357());
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(!uint32(var_i)), CustomError_2d9bc357());
        if (!uint32(var_b)) {
        }
        require(0xe0 > ret0.length);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(((var_i + 0xe0) - var_i) < 0xe0);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(var_i.length - (uint32(var_i.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_l = uint16(arg1);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_l = 0x40;
        var_m = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_l, var_m, var_r); // call
        require(var_ac < 0x40);
        require(((0x60 + var_ac) - 0x60) < 0x40);
        require(var_n - var_n);
        require(!var_ac < 0x20);
        require(((0x60 + var_ac) - 0x60) < 0x20);
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
    
    /// @custom:selector    0x494f787b
    /// @custom:signature   Unresolved_494f787b(uint16 arg0, uint256 arg1, address arg2) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_494f787b(uint16 arg0, uint256 arg1, address arg2) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa8));
        require(!var_j < (arg1));
        require((arg1 + 0x20) + (var_j << 0x05) - (uint32((arg1 + 0x20) + (var_j << 0x05))));
        var_a = uint32((arg1 + 0x20) + (var_j << 0x05));
        require(bytes1(storage_map_d[var_a] >> 0x80));
        storage_map_d[var_a] = (bytes1((storage_map_d[var_a] >> 0xa8) << 0x80)) | (uint248(storage_map_d[var_a]));
        require(!(!bytes1(storage_map_d[var_a] >> 0xa8)) | (0x0de0b6b3a7640000 == ((bytes1(storage_map_d[var_a] >> 0xa8) * 0x0de0b6b3a7640000) / (bytes1(storage_map_d[var_a] >> 0xa8)))));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        uint256 var_l = uint32((arg1 + 0x20) + (var_j << 0x05));
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_68501aee(var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        return ;
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        require(var_q < 0x40);
        require(((0x60 + var_q) - 0x60) < 0x40);
        require(var_j - var_j);
        require(var_r - (uint32(var_r)));
        if (!var_j) {
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
    
    /// @custom:selector    0xb8a999c1
    /// @custom:signature   getTotalIsolatedMarginUsage(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalIsolatedMarginUsage(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > 0x02) {
            if (!0x02) {
                require(!0x03 > 0x02);
                require(!0x02);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                return var_d;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(!(0x01 + var_d) < var_g.length);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(!0x03 > 0x02);
                require(0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0x01;
                var_c = 0x01;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x75a1bd37
    /// @custom:signature   Unresolved_75a1bd37(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_75a1bd37(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40, CustomError_3ee5aeb5());
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(arg0 - (uint16(arg0)));
        var_a = bytes1(arg0 >> 0x08);
        var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
        storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
        if (!(~(0x01 << (arg0))) & (storage_map_a[var_a])) {
        }
        if (0x20 > ret0.length) {
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
        }
    }
    
    /// @custom:selector    0xbd350653
    /// @custom:signature   Unresolved_bd350653(address arg0, uint32 arg1, uint16 arg2, uint256 arg3, address arg4, uint256 arg5) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint16", "bytes2", "int16"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    function Unresolved_bd350653(address arg0, uint32 arg1, uint16 arg2, uint256 arg3, address arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (uint16(arg2)));
        require(arg4 - (address(arg4)));
        require(arg5 - arg5);
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0x40;
        require(msg.sender - address(this), CustomError_728bc590());
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_g = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_g); // staticcall
        require(0);
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        address var_m = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_m); // call
        require(var_u);
        var_m = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_m); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            require(0);
            transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
            var_a = var_a + 0x40;
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            var_b = bytes1(arg2 >> 0x08);
            var_w = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_k[var_b] = (~(0x01 << (bytes1(arg2)))) & (storage_map_k[var_b]);
            require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        }
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (uint32(var_a.length)));
        require(!(uint32(var_w)), CustomError_2d9bc357());
        require(!(uint32(var_w)), CustomError_2d9bc357());
        require(!(uint32(var_w)), CustomError_2d9bc357());
        require(!(!uint32(var_w)), CustomError_2d9bc357());
        require(!(uint32(var_a)), CustomError_2d9bc357());
        require(!(!uint32(var_a)), CustomError_2d9bc357());
        require(0xe0 > ret0.length);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(((var_a + 0xe0) - var_a) < 0xe0);
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(var_a.length - (uint32(var_a.length)));
        require(var_r - (uint32(var_r)));
        var_g = address(this);
        var_h = uint16(arg2);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_g, var_h); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x58d221e7
    /// @custom:signature   Unresolved_58d221e7(uint16 arg0, uint40 arg1, address arg2, address arg3, uint24 arg4, uint256 arg5, uint256 arg6, uint16 arg7, uint16 arg8, uint32 arg9, uint256 arg10, uint64 arg11, uint256 arg12, bool arg13) public view
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint40", "bytes5", "int40"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg3 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    /// @param              arg5 ["uint256", "bytes32", "int256"]
    /// @param              arg6 ["uint256", "bytes32", "int256"]
    /// @param              arg7 ["uint16", "bytes2", "int16"]
    /// @param              arg8 ["uint16", "bytes2", "int16"]
    /// @param              arg9 ["uint32", "bytes4", "int32"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["uint64", "bytes8", "int64"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    /// @param              arg13 ["bool", "uint8", "bytes1", "int8"]
    function Unresolved_58d221e7(uint16 arg0, uint40 arg1, address arg2, address arg3, uint24 arg4, uint256 arg5, uint256 arg6, uint16 arg7, uint16 arg8, uint32 arg9, uint256 arg10, uint64 arg11, uint256 arg12, bool arg13) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x01c0, CustomError_7cb45f65());
        require(block.chainid == 0x1039, CustomError_7cb45f65());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        require(msg.sender - (address(getOrdersManager)), CustomError_7cb45f65());
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        uint16 var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(((var_d + 0x01c0) < var_d) | ((var_d + 0x01c0) > 0xffffffffffffffff));
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint40(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (uint24(arg4)));
        require(arg5 - 11);
        require(arg6 - 11);
        require(arg7 - (uint16(arg7)));
        require(arg8 - (uint16(arg8)));
        require(arg9 - (uint32(arg9)));
        require(arg10 - 11);
        require(arg11 - (uint64(arg11)));
        require(arg12 - arg12);
        require(arg13 - (bytes1(arg13)));
        require((11 == 0x8000000000000000000000000000000000000000000000000000000000000000) & (address(var_s) < 0), CustomError_38c81bce());
        require(!((!address(var_s)) | ((address(var_s) * 11) / (address(var_s)) == 11)), CustomError_38c81bce());
        require(msg.sender - 0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xb6a43bdd
    /// @custom:signature   Unresolved_b6a43bdd(uint16 arg0, uint32 arg1, address arg2) public payable returns (uint256)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b6a43bdd(uint16 arg0, uint32 arg1, address arg2) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint32(arg1)));
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i), CustomError_38c81bce());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length, CustomError_38c81bce());
        require(!0, CustomError_38c81bce());
        require(!(!uint16(arg0)), CustomError_38c81bce());
        var_a = uint16(arg0);
        require(!(bytes1(storage_map_d[var_a] >> 0xa0)), CustomError_38c81bce());
        var_a = uint16(arg0);
        storage_map_h[var_a] = (uint224(storage_map_h[var_a])) | (uint32(arg1 << 0x40));
        emit SetOpenInterestLimit(uint16(arg0), uint32(storage_map_h[var_a] >> 0x40), uint32(arg1));
        return ;
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_l = address(msg.sender);
        var_m = 0x40;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l, var_m); // call
        require(var_q < 0x40);
        require(((0x60 + var_q) - 0x60) < 0x40);
        require(var_r - var_r);
        require(var_s - (uint32(var_s)));
        if (!var_r) {
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
    
    /// @custom:selector    0xcb541761
    /// @custom:signature   Unresolved_cb541761(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cb541761(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40, CustomError_3ee5aeb5());
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            if (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01)) {
                transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
                if (!uint16(getTotalMarkets)) {
                }
                var_a = bytes1(arg0 >> 0x08);
                var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
                require(0, CustomError_2d9bc357());
            }
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01), CustomError_2d9bc357());
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
        }
    }
    
    /// @custom:selector    0xe697d439
    /// @custom:signature   getFreeCrossMarginBalance(int256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function getFreeCrossMarginBalance(int256 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg1 - (address(arg1)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg1);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        require(!(0x03 > var_d), CustomError_35278d12());
        require(!var_d, CustomError_35278d12());
        require(!(0x03 > var_d), CustomError_35278d12());
        require(var_d - 0x01, CustomError_35278d12());
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g), CustomError_35278d12());
        uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require(var_d < var_g.length, CustomError_35278d12());
        require((!arg0 < 0) & ((arg0 + var_d) < var_d) | ((arg0 < 0) & (!(arg0 + var_d) < var_d)), CustomError_35278d12());
        require(!(var_d < 0), CustomError_35278d12());
        if (!var_d < var_g.length) {
            if (var_i) {
                require(!var_d < var_g.length);
                require(var_i);
                require((0x01 + var_d) < var_g.length);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(var_k);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xa5a43e3b
    /// @custom:signature   executeCrossRiskPreflight(address arg0) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function executeCrossRiskPreflight(address arg0) public payable returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0x40;
        uint256 var_d = 0;
        require(msg.sender - address(this), CustomError_728bc590());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_g = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_g); // staticcall
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_a));
        var_a = var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(!0);
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
        var_a = var_a + 0x40;
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        uint32 var_n = uint32(var_h);
        (bool success, bytes memory ret0) = address(getCollateralManager).Unresolved_df3e62dd(var_n); // staticcall
        if (((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a)) {
            var_a = var_a + 0x60;
            if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                    if (((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_a)) {
                        var_a = var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                        if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                            var_j = msg.data[4:36];
                            require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
                            require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                            return abi.encodePacked(uint32(var_h), 0x01, 0, var_a.length, var_w);
                            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                            var_b = 0;
                            var_b = 0;
                            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                            require(((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_a));
                            var_b = 0x01;
                            var_b = 0x01;
                            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                        }
                        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                        require((!0 < 0) & ((0 + var_a.length) < var_a.length) | ((0 < 0) & (!(0 + var_a.length) < var_a.length)));
                    }
                    require(var_y);
                    require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                }
                require(block.chainid == 0xaa39db);
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xba385c10
    /// @custom:signature   Unresolved_ba385c10(address arg0, uint16 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ba385c10(address arg0, uint16 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdc) < 0x40, CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(arg1 - (uint16(arg1)));
        require(uint16(arg1));
        var_a = uint16(arg1);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(arg1 - (uint16(arg1)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_i + 0x60) > 0xffffffffffffffff) | ((var_i + 0x60) < var_i));
        var_i = var_i + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(!uint16(getTotalMarkets));
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        var_r = uint32(var_n);
        (bool success, bytes memory ret0) = address(getCollateralManager).Unresolved_af9fa7b6(var_r); // staticcall
        require(!(0x03 > 0), CustomError_35278d12());
        require(!0, CustomError_35278d12());
        require(!(0x03 > 0), CustomError_35278d12());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_35278d12());
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        require(((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_i), CustomError_35278d12());
        var_i = var_i + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff, CustomError_35278d12());
        var_w = msg.data[4:36];
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_35278d12());
        require((!0 < 0) & (0 < 0) | ((0 < 0) & (!0 < 0)), CustomError_35278d12());
        require(!(0 < 0), CustomError_35278d12());
        if (var_aa) {
            if (var_aa) {
                var_a = 0;
                var_a = 0;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
                    var_a = 0x01;
                    var_a = 0x01;
                    if (0x20 > ret0.length) {
                    }
                    require(var_aa, CustomError_2d9bc357());
                    require(var_aa, CustomError_2d9bc357());
                }
                var_a = bytes1(arg1 >> 0x08);
                var_b = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg1)))) & (storage_map_a[var_a]);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01), CustomError_2d9bc357());
            }
            require(block.chainid == 0xaa39db, CustomError_2d9bc357());
        }
        require(!(uint32(var_b)), CustomError_2d9bc357());
        require(!(uint32(var_ac)), CustomError_2d9bc357());
        require(!(uint32(var_ac)), CustomError_2d9bc357());
        require(!(!uint32(var_ac)), CustomError_2d9bc357());
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(!uint32(var_i)), CustomError_2d9bc357());
        if (!uint32(var_b)) {
        }
        require(0xe0 > ret0.length);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(((var_i + 0xe0) - var_i) < 0xe0);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(var_i.length - (uint32(var_i.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_l = uint16(arg1);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_l = 0x40;
        var_m = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_l, var_m, var_r); // call
        require(var_ac < 0x40);
        require(((0x60 + var_ac) - 0x60) < 0x40);
        require(var_n - var_n);
        require(!var_ac < 0x20);
        require(((0x60 + var_ac) - 0x60) < 0x20);
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
    
    /// @custom:selector    0x6d54de88
    /// @custom:signature   Unresolved_6d54de88(uint16 arg0, uint256 arg1, address arg2) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6d54de88(uint16 arg0, uint256 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (uint16(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(((msg.data.length - arg1) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0160, CustomError_3ee5aeb5());
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(((var_i + 0x0160) > 0xffffffffffffffff) | ((var_i + 0x0160) < var_i));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(msg.data[arg1 + 0x24] - (address(msg.data[arg1 + 0x24])));
        if (block.chainid == 0xaa39db) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_u = address(msg.sender);
        var_v = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_u, var_v); // call
        require(var_z < 0x40);
        require(((0x60 + var_z) - 0x60) < 0x40);
        require(var_aa - var_aa);
        require(var_ab - (uint32(var_ab)));
        if (!var_aa) {
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
    }
    
    /// @custom:selector    0xf04837c1
    /// @custom:signature   getImpactPriceCache(uint16 arg0) public view returns (bool)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function getImpactPriceCache(uint16 arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        uint16 var_a = uint16(arg0);
        return abi.encodePacked(uint64(storage_map_i[var_a]), bytes1(storage_map_d[var_a] >> 0xa8), uint88(storage_map_i[var_a] >> 0x40), uint88(storage_map_i[var_a] >> 0x98), (bytes1(storage_map_i[var_a] >> 0xf0)));
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
        address var_b = address(msg.sender);
        require(((var_f + (uint248(((var_f + 0x84) - var_f) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248(((var_f + 0x84) - var_f) + 0x1f))) < var_f), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_g = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_m[var_g])), CustomError_965ad3ca());
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
        require(var_p < 0x40);
        require(((0x60 + var_p) - 0x60) < 0x40);
        require(var_q - var_q);
        require(var_r - (uint32(var_r)));
        if (!var_q) {
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
    
    /// @custom:selector    0x8dc2c07f
    /// @custom:signature   getOpenInterestUpperBound(uint16 arg0) public view returns (address)
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function getOpenInterestUpperBound(uint16 arg0) public view returns (address) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        uint16 var_a = uint16(arg0);
        require(address(storage_map_p[var_a]) > (address(storage_map_p[var_a]) + (storage_map_p[var_a] >> 0x80)));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return (address(storage_map_p[var_a])) + (storage_map_p[var_a] >> 0x80);
    }
    
    /// @custom:selector    0xd310d730
    /// @custom:signature   getProjectedRealizedPnl(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getProjectedRealizedPnl(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > var_d) {
            if (!var_d) {
                require(!0x03 > var_d);
                require(!var_d);
                require(!0x03 > var_d);
                require(var_d - 0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                return var_d;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                require((0x01 + var_d) < var_g.length);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(!(0x01 + var_d) < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(var_l);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x1b85c600
    /// @custom:signature   getActiveCrossMarkets(address arg0) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getActiveCrossMarkets(address arg0) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if ((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01)) {
            if (((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff) {
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_f = var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_g = msg.data[4:36];
                require(((var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_f + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_f));
                return abi.encodePacked(0x20, var_f.length);
                return abi.encodePacked(0x20, var_f.length, var_k);
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                return abi.encodePacked(0x20, var_f.length);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_m);
                var_c = 0x01;
                var_c = 0x01;
                require(var_m);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0x3d97f59b
    /// @custom:signature   getTotalCrossInitialMargin(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getTotalCrossInitialMargin(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_b); // staticcall
        if (!0x03 > 0x01) {
            if (!0x01) {
                require(!0x03 > 0x01);
                require(!0x01);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                uint248 var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(block.chainid == 0x1039);
                return var_d;
                require(block.chainid == 0x1039);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(var_j);
                return var_d;
                require((0x01 + var_d) < var_g.length);
                require(!(0x01 + var_d) < var_g.length);
                return var_d;
                require(block.chainid == 0xaa39db);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                require(block.chainid == 0xaa39db);
                return var_d;
                require(block.chainid == 0x1039);
                require(var_d < var_g.length);
                require(!var_d < var_g.length);
                return var_d;
                require(block.chainid == 0xaa39db);
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_d < var_g.length);
                var_c = 0x01;
                var_c = 0x01;
                require(!var_d < var_g.length);
                require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                require(!0x03 > 0x01);
                require(0);
                require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                var_g = var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                require(((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_g));
                var_c = 0;
                var_c = 0;
                var_c = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                var_c = 0x01;
                var_c = 0x01;
                require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xc87fe906
    /// @custom:signature   Unresolved_c87fe906(address arg0, uint256 arg1, uint256 arg2, bool arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["bool", "uint8", "bytes1", "int8"]
    function Unresolved_c87fe906(address arg0, uint256 arg1, uint256 arg2, bool arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xe0);
        require(arg0 - (address(arg0)));
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9c) < 0x80, CustomError_728bc590());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_728bc590());
        uint256 var_a = var_a + 0x80;
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a), CustomError_728bc590());
        var_a = var_a + 0x40;
        require(msg.sender - address(this), CustomError_728bc590());
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_a));
        var_a = var_a + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
        require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
        require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(!0);
        require(!0x01);
        require((msg.data.length - 0x64) < 0x80);
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        require(arg3 - (bytes1(arg3)));
        if (var_n) {
            if (block.chainid == 0xaa39db) {
                if (!0) {
                }
                var_b = 0;
                var_b = 0;
                var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(var_n);
                var_b = 0x01;
                var_b = 0x01;
                require(block.chainid == 0xaa39db);
            }
            require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(block.chainid == 0xaa39db);
        }
    }
    
    /// @custom:selector    0xe3ce724f
    /// @custom:signature   Unresolved_e3ce724f(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e3ce724f(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0180, CustomError_3ee5aeb5());
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        require(0);
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
        transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
        transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
        transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
        transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
        transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
        transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
        transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
        transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
        transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
        transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
        transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
        transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
        require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01));
        transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(!msg.data.length == 0x019a);
        require(arg0 - (uint16(arg0)));
        var_a = uint32(var_l);
        require(bytes1(storage_map_d[var_a] >> 0x80));
        var_a = uint32(var_l);
        require(bytes1(storage_map_d[var_a] >> 0x80));
        storage_map_d[var_a] = (bytes1((storage_map_d[var_a] >> 0xa8) << 0x80)) | (uint248(storage_map_d[var_a]));
        require(!(!bytes1(storage_map_d[var_a] >> 0xa8)) | (0x0de0b6b3a7640000 == ((bytes1(storage_map_d[var_a] >> 0xa8) * 0x0de0b6b3a7640000) / (bytes1(storage_map_d[var_a] >> 0xa8)))));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        var_r = uint32(var_l);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_68501aee(var_r); // staticcall
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(var_g.length - (address(var_g.length)));
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            var_a = bytes1(arg0 >> 0x08);
            var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
            storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
            if (!(~(0x01 << (arg0))) & (storage_map_a[var_a])) {
            }
            require(block.chainid == 0xaa39db, CustomError_2d9bc357());
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
        }
    }
    
    /// @custom:selector    0xcdeddd6c
    /// @custom:signature   Unresolved_cdeddd6c(bool arg0, address arg1, address arg2, address arg3, uint24 arg4, uint32 arg5) public payable
    /// @param              arg0 ["bool", "uint8", "bytes1", "int8"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg3 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    /// @param              arg5 ["uint32", "bytes4", "int32"]
    function Unresolved_cdeddd6c(bool arg0, address arg1, address arg2, address arg3, uint24 arg4, uint32 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0, CustomError_7cb45f65());
        require(block.chainid == 0x1039, CustomError_7cb45f65());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        require(msg.sender - (address(getOrdersManager)), CustomError_7cb45f65());
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c));
        uint256 var_c = var_c + 0xe0;
        require(bytes1(transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357]) == 0x01);
        require(((var_c + 0xc0) > 0xffffffffffffffff) | ((var_c + 0xc0) < var_c));
        var_c = var_c + 0xc0;
        require(arg0 - (uint16(arg0)));
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        require(arg3 - (address(arg3)));
        require(arg4 - (uint24(arg4)));
        require(arg5 - (uint32(arg5)));
        store_o = store_o | (0x01 << (bytes1(arg0 >> 0x08)));
        storage_map_x[var_r] = storage_map_x[var_r] | (0x01 << (bytes1(arg0)));
        require(!address(var_s));
        var_a = uint16(arg0);
        require(address(storage_map_p[var_a] >> 0x80) + (address(var_s)) > 0xffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_p[var_a] = (address(storage_map_p[var_a])) | (address((storage_map_p[var_a] >> 0x80) + (var_s) << 0x80));
        require(block.chainid == 0x1039);
        require(!0x069edf2c2a3c93b54640ae142b9f5375fe4a207a);
        require(bytes1(transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133]) == 0x01);
        require(uint16(transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] >> 0x01) == (uint16(arg0)));
        bool var_u = uint16(arg0);
        (bool success, bytes memory ret0) = address(getFundingRate).Unresolved_f1d4d9aa(var_u); // staticcall
        transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0x01;
        transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = (uint24(uint16(arg0) << 0x01)) | 0x01;
        require((0 == 0x8000000000000000000000000000000000000000000000000000000000000000) & (address(var_v) < 0));
        require(!(!address(var_v)) | ((address(var_v) * 0) / (address(var_v)) == 0));
        require(0x60 > ret0.length);
        require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
        var_c = var_c + 0x60;
        require(((var_c + 0x60) - var_c) < 0x60);
        require(var_c.length - 11);
        require(var_s - 11);
        require(var_v - (uint32(var_v)));
        if ((0 == 0x8000000000000000000000000000000000000000000000000000000000000000) & (address(var_v) < 0)) {
            if (!(!address(var_v)) | ((address(var_v) * 0) / (address(var_v)) == 0)) {
                if (transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] == 0x01) {
                }
                if (transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] == 0x01) {
                    if (uint16(transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] >> 0x01) == (uint16(arg0))) {
                    }
                    require((0 == 0x8000000000000000000000000000000000000000000000000000000000000000) & (address(var_v) < 0));
                }
            }
            require(!(!address(var_v)) | ((address(var_v) * 0) / (address(var_v)) == 0));
            require(block.chainid == 0xaa39db);
        }
        (bool success, bytes memory ret0) = address(getOrdersManager).getTakerContext(); // staticcall
        if (0xe0 > ret0.length) {
        }
        if (((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c)) {
            var_c = var_c + 0xe0;
            if (transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] == 0x01) {
            }
            require(((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c), CustomError_7cb45f65());
            require(block.chainid == 0xaa39db, CustomError_7cb45f65());
        }
        require(msg.sender - 0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
    }
    
    /// @custom:selector    0xc7148f0e
    /// @custom:signature   Unresolved_c7148f0e(uint32 arg0, address arg1) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_c7148f0e(uint32 arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40, CustomError_3ee5aeb5());
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        uint248 var_g = var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_babcc539(var_k); // staticcall
        require(!0);
        require(arg0 - (uint16(arg0)));
        require(uint16(arg0));
        var_a = uint16(arg0);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        var_k = address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60);
        (bool success, bytes memory ret0) = address(getAccountRegistry).{ value: var_l }Unresolved_c80d6a1b(var_k); // call
        require(arg0 - (uint16(arg0)));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_g + 0x60) > 0xffffffffffffffff) | ((var_g + 0x60) < var_g));
        var_g = var_g + 0x60;
        address var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_r); // call
        require(var_z);
        var_r = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_r); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            if (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01)) {
                transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
                if (!uint16(getTotalMarkets)) {
                }
                var_a = bytes1(arg0 >> 0x08);
                var_i = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg0)))) & (storage_map_a[var_a]);
                require(0, CustomError_2d9bc357());
            }
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01), CustomError_2d9bc357());
        }
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_aa)), CustomError_2d9bc357());
        require(!(!uint32(var_aa)), CustomError_2d9bc357());
        require(!(uint32(var_g)), CustomError_2d9bc357());
        require(!(!uint32(var_g)), CustomError_2d9bc357());
        if (!uint32(var_i)) {
        }
        require(0xe0 > ret0.length);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(((var_g + 0xe0) - var_g) < 0xe0);
        require(((var_g + 0xe0) > 0xffffffffffffffff) | ((var_g + 0xe0) < var_g));
        var_g = var_g + 0xe0;
        require(var_g.length - (uint32(var_g.length)));
        require(var_w - (uint32(var_w)));
        var_k = address(this);
        var_m = uint16(arg0);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_m); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
            require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_m = 0x40;
        var_n = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_m, var_n, var_r); // call
        require(var_aa < 0x40);
        require(((0x60 + var_aa) - 0x60) < 0x40);
        require(var_l - var_l);
        require(!var_aa < 0x20);
        require(((0x60 + var_aa) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
        if (0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e - msg.sender) {
        }
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
            require(msg.data.length < 0x14);
        }
    }
    
    /// @custom:selector    0x05f30511
    /// @custom:signature   Unresolved_05f30511(address arg0, uint16 arg1, address arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_05f30511(address arg0, uint16 arg1, address arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        uint248 var_i = var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(uint16(arg1));
        var_a = uint16(arg1);
        require(!bytes1(storage_map_d[var_a] >> 0xa0));
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        var_k = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_k); // staticcall
        require(0);
        require(((var_i + 0x60) > 0xffffffffffffffff) | ((var_i + 0x60) < var_i));
        var_i = var_i + 0x60;
        address var_q = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_74b140f8(var_q); // call
        require(var_y);
        var_q = address(this);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_01aab38a(var_q); // staticcall
        if (0) {
            transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = 0;
            transient[0xea2184ffcdd100612318daf9b3385823adb502e78a66df350e1f0364f2e2bf4a] = 0;
            transient[0xb8aa7d1cca830bfb83ff84c0739226dab237fba4f3981213de4100735ab13133] = 0;
            transient[0xbd819949fc4835bf2e06a59c0f09c87cb7bfd0703f89a3c4acfae621990bf344] = 0;
            transient[0x93a8571bb19e6c8239f054c945c40589066cdb78b30a38c7042656447db7e916] = 0;
            transient[0xa38823690c63190bd0d211a1b0bf5f451c471e63cffdbd0321d2dd2e67be07bb] = 0;
            transient[0xf4260de40511025afd089df584df624d9adc212b1cc390407df8b351d36cdd60] = 0;
            transient[0x30e329571ae10ba9eade0220e6e4241a8db569891beee4f18d6593f7c44f779a] = 0;
            transient[0x9be1ccaa306589b59f94cc379e4f2e0e3ed56c6acfb099e4e0a2dc6ad28e09bb] = 0;
            transient[0xc8514e34e365b1fa8d3e608871ec6ae79e3946a51358887b04cc6d8ab7081788] = 0;
            transient[0xa6ab628db02672bf689ed179d93f4009aeec7a908b2dd50ed64d171f6612c666] = 0;
            transient[0x9e1f023ccc1a00f7dfeeb457e18841e16dcf4a1d8f56108ce34e1d05d3876cc9] = 0;
            transient[0x93c2c58bf369cc2c7961d706baf0f3a555b6668f33e1519520cae218a660a000] = 0;
            transient[0xc8a097fb968cf8a0281876c299fd8619a9d5cf77411487ad61f23df06eab7fca] = 0;
            transient[0x0d579730c3c509af06a13b43f8a2b825a7f6a114f21e6befda5aea10cfc0a200] = 0;
            if (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01)) {
                transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] = transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01;
                if (!uint16(getTotalMarkets)) {
                }
                var_a = bytes1(arg1 >> 0x08);
                var_b = 0xf46074dc6958ae693e77398ca6fcce65ec4d8eac65bb4dfb47ee4874131fcd03;
                storage_map_a[var_a] = (~(0x01 << (bytes1(arg1)))) & (storage_map_a[var_a]);
                require(0, CustomError_2d9bc357());
            }
            require(transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] > (transient[0x477a07a0adf770c2a9fb43484adf887443ad847bd1a3b79653d495969ea2a9cb] + 0x01), CustomError_2d9bc357());
        }
        require(!(uint32(var_b)), CustomError_2d9bc357());
        require(!(uint32(var_z)), CustomError_2d9bc357());
        require(!(uint32(var_z)), CustomError_2d9bc357());
        require(!(!uint32(var_z)), CustomError_2d9bc357());
        require(!(uint32(var_i)), CustomError_2d9bc357());
        require(!(!uint32(var_i)), CustomError_2d9bc357());
        if (!uint32(var_b)) {
        }
        require(0xe0 > ret0.length);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(((var_i + 0xe0) - var_i) < 0xe0);
        require(((var_i + 0xe0) > 0xffffffffffffffff) | ((var_i + 0xe0) < var_i));
        var_i = var_i + 0xe0;
        require(var_i.length - (uint32(var_i.length)));
        require(var_v - (uint32(var_v)));
        var_k = address(this);
        var_l = uint16(arg1);
        (bool success, bytes memory ret0) = address(getOrdersManager).dirtyTickCount(var_k, var_l); // staticcall
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            if (0x20 > ret0.length) {
            }
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
            require(block.chainid == 0xaa39db, CustomError_38c81bce());
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        var_l = 0x40;
        var_m = msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec;
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k, var_l, var_m, var_q); // call
        require(var_z < 0x40);
        require(((0x60 + var_z) - 0x60) < 0x40);
        require(var_ad - var_ad);
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
    }
    
    /// @custom:selector    0xd299c5bb
    /// @custom:signature   Unresolved_d299c5bb(address arg0, uint256 arg1, uint256 arg2, address arg3) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d299c5bb(address arg0, uint256 arg1, uint256 arg2, address arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0xc0;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_k[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_l = address(msg.sender);
        require(((var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f))) < var_a), CustomError_89b46ce9());
        var_a = var_a + (uint248(((var_a + 0x84) - var_a) + 0x1f));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_l); // staticcall
        require(!ret0.length, CustomError_89b46ce9());
        require(!0, CustomError_89b46ce9());
        require(arg1 > 0x0f4240, CustomError_89b46ce9());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_1232deb3());
        var_a = var_a + 0x80;
        require(!(arg2), CustomError_1232deb3());
        require(arg2 < 0x03, CustomError_1232deb3());
        require(!(((arg2 + 0x20) >> 0xf8) < 0x20), CustomError_1232deb3());
        require(((arg2 + 0x20) >> 0xf8) > 0x22, CustomError_1232deb3());
        require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)) > 0xff, CustomError_1232deb3());
        require(!(0x03 > (bytes1(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)))), CustomError_1232deb3());
        require(!(0x03 > (bytes1(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0 + ((arg2 + 0x20) >> 0xf8)))), CustomError_1232deb3());
        require(!(0x01 < (arg2)), CustomError_1232deb3());
        require(!(0x02 < (arg2)), CustomError_1232deb3());
        require(bytes1(var_a.length) > (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8)), CustomError_1232deb3());
        require(!((!(bytes1(var_a.length)) + (((arg2 + 0x20) + 0x02) >> 0xf8)) | (0x02 == ((bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01) / (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8))))), CustomError_1232deb3());
        require(0x03 > (0x03 + (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01)), CustomError_1232deb3());
        require((0x03 + (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8) << 0x01)) > (arg2), CustomError_1232deb3());
        require(!(0x03 > (var_t)), CustomError_1232deb3());
        require(!(0x03 > (var_t)), CustomError_1232deb3());
        require(var_t == 0x02, CustomError_1232deb3());
        require(var_u == (arg2), CustomError_1232deb3());
        require(0 < (bytes1(var_a.length) + (((arg2 + 0x20) + 0x02) >> 0xf8)), CustomError_1232deb3());
        require(!(!0 | (0x02 == 0)), CustomError_1232deb3());
        require(0x03 > 0x03, CustomError_1232deb3());
        require(!((0x03 + ((arg2 + 0x20) + 0)) >> 0xf0), CustomError_1232deb3());
        require(var_u < (arg2), CustomError_1232deb3());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_1232deb3());
        var_a = var_a + 0x80;
        require(!(var_u > (arg2)), CustomError_1232deb3());
        require(arg2 - (var_u) > (arg2), CustomError_1232deb3());
        require(arg2 - (var_u) < 0x03, CustomError_1232deb3());
        require(var_u > (var_u + 0x02), CustomError_1232deb3());
        require(!(arg2 > (var_u + 0x02)), CustomError_1232deb3());
        require(!(!uint16(var_a.length)), CustomError_1232deb3());
        require(!((0x02 + (var_u + (arg2 + 0x20))) >> 0xf8), CustomError_1232deb3());
        require(var_u > (var_u + 0x03), CustomError_1232deb3());
        require(!((!bytes1(var_z)) | (0x14 == ((bytes1(var_z) * 0x14) / (bytes1(var_z))))), CustomError_1232deb3());
        require((var_u + 0x03) > ((var_u + 0x03) + (bytes1(var_z) * 0x14)), CustomError_1232deb3());
        require((var_u + 0x03) + (bytes1(var_z) * 0x14) > (arg2), CustomError_1232deb3());
        require(!(var_u < (var_t)), CustomError_1232deb3());
        require(!(var_u > (arg2)), CustomError_1232deb3());
        require(arg2 - (var_u) > (arg2), CustomError_1232deb3());
        require(arg2 - (var_u) < 0x14, CustomError_1232deb3());
        require(!(!((arg2 + 0x20) + (var_u)) >> 0xe0), CustomError_1232deb3());
        require(!(address((arg2 + 0x20) + (var_u) >> 0x60)), CustomError_1232deb3());
        require(var_u > (arg2), CustomError_1232deb3());
        require(var_u > (arg2), CustomError_1232deb3());
        if (msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e) {
            require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e, CustomError_1232deb3());
        }
        require(((arg2 + 0x20) >> 0xf8) < 0x20, CustomError_1232deb3());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        uint256 var_aa = address(msg.sender);
        uint256 var_ab = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_aa, var_ab); // call
        require(var_af < 0x40);
        require(((0x60 + var_af) - 0x60) < 0x40);
        require(var_ag - var_ag);
        require(var_ah - (uint32(var_ah)));
        if (!var_ag) {
        }
        require(!var_af < 0x20);
        require(((0x60 + var_af) - 0x60) < 0x20);
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
    
    /// @custom:selector    0xb25aed4d
    /// @custom:signature   Unresolved_b25aed4d(uint0 arg0, address arg1, uint256 arg2, uint0 arg3) public payable returns (uint256)
    /// @param              arg0 ["uint0", "bytes0", "int0"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint0", "bytes0", "int0"]
    function Unresolved_b25aed4d(uint0 arg0, address arg1, uint256 arg2, uint0 arg3) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (uint40(arg0)));
        require(arg1 - (address(arg1)));
        require(arg3 - (bytes1(arg3)));
        require(block.chainid == 0x1039, CustomError_7cb45f65());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
        require(msg.sender - (address(getOrdersManager)), CustomError_7cb45f65());
        require(bytes1(arg3), CustomError_bac65e5b());
        return 0xb25aed4d00000000000000000000000000000000000000000000000000000000;
        require(block.chainid == 0x1039, CustomError_bac65e5b());
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_bac65e5b());
        require(((var_d + 0xe0) > 0xffffffffffffffff) | ((var_d + 0xe0) < var_d), CustomError_bac65e5b());
        uint256 var_d = var_d + 0xe0;
        require(bytes1(transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357]) == 0x01, CustomError_bac65e5b());
        require(address(arg1) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / arg2), CustomError_bac65e5b());
        require(!arg2, CustomError_bac65e5b());
        var_a = uint32(arg0 >> 0x01);
        var_a = uint16(var_d.length);
        if (!uint0(storage_map_h[var_a])) {
            require(!uint0(storage_map_h[var_a]));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!0x02 > (bytes1(arg0)));
            require(!uint64(storage_map_h[var_a] >> 0x60));
            require(!uint0(storage_map_h[var_a]));
            require(!0x02 > (bytes1(arg0)));
            require(bytes1(arg0));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint40(storage_map_h[var_a] >> 0xc8) > (uint40(storage_map_h[var_a] >> 0xc8) + (address(arg1) / (uint64(storage_map_h[var_a] >> 0x60)))));
            storage_map_h[var_a] = storage_map_h[var_a];
            var_a = uint32(arg0 >> 0x01);
            require(storage_map_h[var_a] - (storage_map_h[var_a]));
            var_a = (uint16(var_d.length)) >> 0x08;
            require(!storage_map_a[var_a]);
            require(!bytes1(storage_map_a[var_a] >> (uint16(uint16(var_d.length)))));
            require(store_o);
            require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
            var_d = var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f));
            require(((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_d + (uint248((0x20 + (((uint16(getTotalMarkets) >> 0x08) + 0x01) << 0x05)) + 0x1f))) < var_d));
            require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
            require(0 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            return 0xb25aed4d00000000000000000000000000000000000000000000000000000000;
            require(0);
            require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
            var_a = 0;
            require(!bytes1(store_o));
            require(storage_map_a[var_a] & (var_o));
            return 0xb25aed4d00000000000000000000000000000000000000000000000000000000;
            require(0x01);
            require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0;
        var_a = 0;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0x01 < ((uint16(getTotalMarkets) >> 0x08) + 0x01));
        var_a = 0x01;
        var_a = 0x01;
        var_k = keccak256(var_a) + 0x01;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        address var_q = address(this);
        uint256 var_r = uint16(var_d.length);
        uint0 var_s = uint32(arg0 >> 0x01);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_97ebdd7a(var_q, var_r, var_s); // staticcall
        require(!0);
        var_q = address(this);
        var_r = uint16(var_d.length);
        var_s = uint32(arg0 >> 0x01);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_fca8d230(var_q, var_r, var_s); // staticcall
        require(0);
        var_q = address(this);
        var_r = uint16(var_d.length);
        var_s = uint32(arg0 >> 0x01);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_90242fe6(var_q, var_r, var_s); // staticcall
        require(!uint64(storage_map_h[var_a] >> 0x60));
        require(0x60 > ret0.length);
        require(((var_d + 0x60) > 0xffffffffffffffff) | ((var_d + 0x60) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = var_d + 0x60;
        require(((var_d + 0x60) - var_d) < 0x60);
        require(!uint64(storage_map_h[var_a] >> 0x60));
        require(0x20 > ret0.length);
        require(((var_d + 0x20) > 0xffffffffffffffff) | ((var_d + 0x20) < var_d));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = var_d + 0x20;
        require(((var_d + 0x20) - var_d) < 0x20);
        require(var_d.length - var_d.length);
        require(var_d.length);
        var_r = address(this);
        var_s = uint16(var_d.length);
        (bool success, bytes memory ret0) = address(getOrdersManager).Unresolved_90242fe6(var_r, var_s); // staticcall
        if (0x60 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        if (block.chainid == 0xaa39db) {
            require(block.chainid == 0xaa39db);
        }
        (bool success, bytes memory ret0) = address(getOrdersManager).getTakerContext(); // staticcall
        transient[0x350ae6574daeb4ca1297d4bb605702b0dcbcaf5f12bb3cba71b60518f6671357] = (uint24(var_a << 0x01) | (uint24(var_d << 0x11) | (uint24(var_u << 0x21) | (uint24(var_v << 0x31) | (uint24(var_w << 0x41) | (uint16(var_x << 0x51) | (uint64(var_k << 0x59)))))))) | 0x01;
        require(address(arg1) > (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff / arg2), CustomError_bac65e5b());
        require(!arg2, CustomError_bac65e5b());
        if (0xe0 > ret0.length) {
        }
        if (((var_d + 0xe0) > 0xffffffffffffffff) | ((var_d + 0xe0) < var_d)) {
            var_d = var_d + 0xe0;
            require(((var_d + 0xe0) > 0xffffffffffffffff) | ((var_d + 0xe0) < var_d), CustomError_7cb45f65());
        }
        require(msg.sender - 0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd, CustomError_7cb45f65());
    }
    
    /// @custom:selector    0x8aa1c60c
    /// @custom:signature   Unresolved_8aa1c60c(address arg0, address arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8aa1c60c(address arg0, address arg1) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_a[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
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
        address var_e = address(msg.sender);
        require(((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) > 0xffffffffffffffff) | ((var_i + (uint248(((var_i + 0x84) - var_i) + 0x1f))) < var_i));
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(block.chainid == 0x1039);
        require(!0x1238991cac4e65902c08213e79909a9c813eebc3);
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(getAccountRegistry).Unresolved_2b956ff7(var_k); // staticcall
        if (!uint16(getTotalMarkets)) {
            if (block.chainid == 0x1039) {
                if (!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd) {
                    require(!uint16(getTotalMarkets));
                    require(block.chainid == 0x1039);
                    require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
                    require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                    require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
                    require((uint16(getTotalMarkets) >> 0x08) > ((uint16(getTotalMarkets) >> 0x08) + 0x01));
                }
                require(((uint16(getTotalMarkets) >> 0x08) + 0x01) > 0xffffffffffffffff);
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        require(var_q < 0x40);
        require(((0x60 + var_q) - 0x60) < 0x40);
        require(var_l - var_l);
        require(var_r - (uint32(var_r)));
        if (!var_l) {
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
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59(uint32 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg18446744073709551615 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8456cb59(uint32 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < var_a);
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
        address var_c = address(msg.sender);
        require(((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) > 0xffffffffffffffff) | ((var_g + (uint248(((var_g + 0x84) - var_g) + 0x1f))) < var_g), CustomError_965ad3ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_c); // staticcall
        require(!ret0.length, CustomError_965ad3ca());
        require(!0, CustomError_965ad3ca());
        uint32 var_h = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_y[var_h])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        unresolved_5c975abb = (uint248(unresolved_5c975abb)) | 0x01;
        require(msg.sender == 0xaadde0cea454f2bcb26f46ed54c5709b7bb34a7e);
        require(msg.data.length < 0x14);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec) > msg.data.length);
        require((msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec)) < 0x14);
        emit Event_62e78cea(address((0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000 << ((0x14 - (msg.data.length - (msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec))) << 0x03)) & (msg.data[msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec]) >> 0x60));
        require(block.chainid == 0x1039);
        require(!0xe03c1d5081eb2d0e6bfd62a949c5b12efa44f2cd);
        require(!address(getOrdersManager).code.length);
        (bool success, bytes memory ret0) = address(getOrdersManager).{ value: var_a }pause(); // call
        require(block.chainid == 0x1039);
        require(!0x2c03c7d7e2974c6599b6b108879109281ef3f818);
        require(!address(getCollateralManager).code.length);
        (bool success, bytes memory ret0) = address(getCollateralManager).{ value: var_a }pause(); // call
        return ;
        if (block.chainid == 0xaa39db) {
            if (!0) {
            }
            require(block.chainid == 0xaa39db);
            require(block.chainid == 0xaa39db);
        }
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_l = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_l); // call
        require(var_q < 0x40);
        require(((0x60 + var_q) - 0x60) < 0x40);
        require(var_a - var_a);
        require(var_r - (uint32(var_r)));
        if (!var_a) {
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
    
    /// @custom:selector    0x2172342c
    /// @custom:signature   ensureMarketUnlocked(uint16 arg0) public view
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function ensureMarketUnlocked(uint16 arg0) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint16(arg0)));
        require(!(!uint16(arg0)), CustomError_38c81bce());
        uint16 var_a = uint16(arg0);
        require(!(bytes1(storage_map_d[var_a] >> 0xa0)), CustomError_38c81bce());
    }
}