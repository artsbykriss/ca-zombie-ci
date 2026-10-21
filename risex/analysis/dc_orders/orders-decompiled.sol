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
    bytes public constant getTakerContext = 0xBytes([]);
    
    mapping(bytes32 => bytes32) storage_map_w;
    bytes32 store_u;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_s;
    mapping(bytes32 => bytes32) storage_map_ac;
    mapping(bytes32 => bytes32) storage_map_j;
    uint16 public getEpochBucketSize;
    mapping(bytes32 => bytes32) storage_map_k;
    bytes32 store_c;
    mapping(bytes32 => bytes32) storage_map_i;
    address public authority;
    bool public unresolved_5c975abb;
    bytes32 store_l;
    mapping(bytes32 => bytes32) storage_map_e;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_ae;
    mapping(bytes32 => bytes32) storage_map_o;
    mapping(bytes32 => bytes32) storage_map_z;
    mapping(bytes32 => bytes32) storage_map_v;
    mapping(bytes32 => bytes32) storage_map_d;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_aa;
    mapping(bytes32 => bytes32) storage_map_y;
    mapping(bytes32 => bytes32) storage_map_p;
    bytes32 store_x;
    mapping(bytes32 => bytes32) storage_map_m;
    bytes32 store_t;
    
    error EpochConfigNotInitialized();
    event HooksRegistered(address, bytes32);
    event Event_62e78cea();
    event Event_5db9ee0a();
    event AuthorityUpdated(address);
    event Event_37a8aa76();
    event OrderbookChecksum(address, uint16, bytes32);
    
    /// @custom:selector    0x01aab38a
    /// @custom:signature   dirtyTickCount(address arg0, uint16 arg1) public view returns (uint32)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function dirtyTickCount(address arg0, uint16 arg1) public view returns (uint32) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        return uint32(storage_map_a[var_a] >> 0x20);
    }
    
    /// @custom:selector    0xe56df623
    /// @custom:signature   initialize(address arg0, uint64 arg1, uint32 arg2, uint16 arg3, address arg4) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint16", "bytes2", "int16"]
    /// @param              arg4 ["address", "uint160", "bytes20", "int160"]
    function initialize(address arg0, uint64 arg1, uint32 arg2, uint16 arg3, address arg4) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint16(arg3)));
        require(arg4 - (address(arg4)));
        require(!(uint64(store_c)), CustomError_d7e6bcf8());
        require(0x01 == (uint64(store_c)), CustomError_d7e6bcf8());
        require(!(!uint64(store_c)), CustomError_d7e6bcf8());
        require(address(this).code.length, CustomError_d7e6bcf8());
        store_c = (uint192(store_c)) | 0x01;
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(address(arg0)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_c)), CustomError_f92ee8a9());
        if (uint64(store_c)) {
        }
        if (0x01 == (uint64(store_c))) {
        }
    }
    
    /// @custom:selector    0xbcd8be68
    /// @custom:signature   getReduceOnlyOpenOrderSizes(address arg0, uint16 arg1, uint32 arg2) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getReduceOnlyOpenOrderSizes(address arg0, uint16 arg1, uint32 arg2) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
    }
    
    /// @custom:selector    0x81009a95
    /// @custom:signature   mayHaveProjectedFills(address arg0, uint16 arg1, uint32 arg2) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function mayHaveProjectedFills(address arg0, uint16 arg1, uint32 arg2) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        require(!uint32(storage_map_a[var_a] >> 0x20));
        var_a = uint32(arg2);
        require(!address(storage_map_d[var_a]));
        return !(!address(storage_map_d[var_a]));
        return !(!storage_map_d[var_a] >> 0x80);
        return 0;
    }
    
    /// @custom:selector    0x83c8a4d2
    /// @custom:signature   getProjectedFillChunksV2(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getProjectedFillChunksV2(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        address var_b = keccak256(var_a);
        if (((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            uint256 var_c = var_c + 0x60;
            if (uint32(storage_map_a[var_a] >> 0x20) == 0x01) {
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(uint32(storage_map_a[var_a] >> 0x20) == 0x01);
                var_a = var_b + 0x05;
                require(!storage_map_e[var_a]);
                var_e = 0;
                require(!storage_map_e[var_a]);
                var_a = uint32(arg2);
                require(!0x01);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = var_c + 0x40;
                require(!uint32(var_c.length));
                require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
                require(!address(var_c.length));
                var_c = var_c + 0x60;
                require(!address(var_c.length));
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(var_m);
                var_c = var_c + 0xa0;
                require(((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c));
                var_c = var_c + 0x60;
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                var_c = var_c + 0x20;
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
                require(address(var_c.length));
                require(address(var_m));
                require(!uint32(var_ad));
                var_c = var_c + 0x40;
                require(uint40(var_m));
                require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
                require(0 < 0x20);
                var_c = var_c + 0xa0;
                require(!var_c.length);
                var_c = var_c + 0x60;
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                var_c = var_c + 0x20;
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
            }
            require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
            require(!var_aq);
            require(0 < var_ap);
            return abi.encodePacked(0x20, var_ap);
            require(!0x02 > (var_at));
        }
    }
    
    /// @custom:selector    0xfbdf36ed
    /// @custom:signature   getHookBitmap(address arg0) public view returns (uint224)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getHookBitmap(address arg0) public view returns (uint224) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        return uint224(storage_map_d[var_a]);
    }
    
    /// @custom:selector    0xbb8f72bb
    /// @custom:signature   getUserSelfSizeSteps(address arg0, uint16 arg1, uint24 arg2, uint32 arg3) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint24", "bytes3", "int24"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    function getUserSelfSizeSteps(address arg0, uint16 arg1, uint24 arg2, uint32 arg3) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint24(arg2)));
        require(arg3 - (uint32(arg3)));
        var_a = uint16(arg1);
        var_a = uint32(arg3);
        if (!0x02 > 0) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!0x02 > 0);
            require(!address(storage_map_d[var_a]));
        }
    }
    
    /// @custom:selector    0x70367683
    /// @custom:signature   Unresolved_70367683(address arg0, uint16 arg1, uint256 arg2, uint256 arg3, uint64 arg4) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint64", "bytes8", "int64"]
    function Unresolved_70367683(address arg0, uint16 arg1, uint256 arg2, uint256 arg3, uint64 arg4) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(!arg2 < 0x02);
        require(arg4 - (uint64(arg4)));
        var_a = uint16(arg1);
        require(!(0x02 > arg2), CustomError_4f3d7def());
        var_a = arg2;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        require(!(0x02 > arg2), CustomError_4f3d7def());
        require(arg2, CustomError_4f3d7def());
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        return 0;
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
    
    /// @custom:selector    0xc545e747
    /// @custom:signature   rebalanceReduceOnlyOrdersBothSides(uint16 arg0, uint32 arg1, uint64 arg2, uint64 arg3) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint64", "bytes8", "int64"]
    /// @param              arg3 ["uint64", "bytes8", "int64"]
    function rebalanceReduceOnlyOrdersBothSides(uint16 arg0, uint32 arg1, uint64 arg2, uint64 arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint32(arg1)));
        require(arg2 - (uint64(arg2)));
        require(arg3 - (uint64(arg3)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        var_d = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        var_h = 0x64;
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        uint256 var_i = var_i + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        var_a = uint16(arg0);
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_q = address(msg.sender);
        var_r = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_q, var_r); // call
        if (var_v < 0x40) {
            require(var_v < 0x40);
            require(((0x60 + var_v) - 0x60) < 0x40);
            require(var_h - var_h);
            require(var_d - (uint32(var_d)));
        }
        require(!var_v < 0x20);
        require(((0x60 + var_v) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x9f719817
    /// @custom:signature   getOrder(address arg0, uint16 arg1, uint40 arg2) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint40", "bytes5", "int40"]
    function getOrder(address arg0, uint16 arg1, uint40 arg2) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint40(arg2)));
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a), CustomError_4e23d035());
        var_b = uint16(arg1);
        var_b = uint40(arg2);
        require(!(uint32(storage_map_h[var_b])), CustomError_4e23d035());
        var_b = uint24(storage_map_h[var_b] >> 0x60);
        require(!(uint32(storage_map_h[var_b])), CustomError_4e23d035());
        require(uint32(storage_map_h[var_b]) - (uint32(storage_map_h[var_b] >> 0x20)) > 0xffffffff, CustomError_4e23d035());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint64(uint32(uint32(uint32(storage_map_h[var_b])) - (uint32(uint32(storage_map_h[var_b] >> 0x20)))))), CustomError_4e23d035());
        require(!(uint64((storage_map_i[var_b] >> 0x50) < (storage_map_i[var_b] >> 0x10) * ((storage_map_i[var_b] >> 0x10) - (storage_map_i[var_b] >> 0x50)))), CustomError_4e23d035());
        require(uint16(storage_map_h[var_b] >> 0xa8) > 0x8000, CustomError_4e23d035());
        var_b = 0x4e23d03500000000000000000000000000000000000000000000000000000000;
        require(!uint16(storage_map_h[var_b] >> 0xa8));
        require((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint16(storage_map_h[var_b] >> 0xa8)));
        require((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c);
        require(((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) > (uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)));
        require(((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) > (uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)));
        require(uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (uint16(storage_map_h[var_b] >> 0xa8)));
        require(!(uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) < storage_map_h[var_b]);
        require(!(uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) < storage_map_h[var_b]);
        var_b = keccak256(var_b);
        require(!uint40(storage_map_j[uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x06] >> (((uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) % 0x06) * 0x05) << 0x03)));
        var_b = uint40(storage_map_j[uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x06] >> (((uint248(uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) % 0x06) * 0x05) << 0x03));
        require(uint32(storage_map_h[var_b]) - (uint32(storage_map_h[var_b] >> 0x20)) > 0xffffffff);
        require(0 > 0);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((0 - (uint64(uint32(uint32(uint32(storage_map_h[var_b])) - (uint32(uint32(storage_map_h[var_b] >> 0x20))))))) > 0xffffffffffffffff);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)) < ((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04));
        require(0 > 0);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) < ((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04));
        require(!(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) / 0x07) < 0x0125);
        require((uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) < 0x07);
        require(!(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) < 0x07);
        require((uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) / 0x07) == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)) % 0x07) | (0x24 == (((uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) * 0x24) / (uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07))));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 > (0 + (uint40((storage_map_k[(keccak256(var_b) + 0x01) + 0x18] >> 0) >> ((uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) * 0x24)))));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint248((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)) < ((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08));
        require(uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) < ((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08));
        require(!(uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) / 0x06) < 0x16);
        require((uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) < 0x06);
        require(!(uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) < 0x06);
        require(!(!(uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)) % 0x06) | (0x28 == (((uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) * 0x28) / (uint240((uint16(uint16(storage_map_h[var_b] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06))));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c);
        require(0 < ((uint16(storage_map_h[var_b] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c));
        require(!0 < 0x02);
        require(0 < 0x05);
        require(!0 < 0x05);
        require(0 | (0x2c == 0));
    }
    
    /// @custom:selector    0xf52b6528
    /// @custom:signature   pumpForUser(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    /// @param              arg4 ["uint32", "bytes4", "int32"]
    function pumpForUser(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint32(arg3)));
        require(arg4 - (uint32(arg4)));
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0x80;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_h[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(store_l), CustomError_965ad3ca());
        if (((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a)) {
            var_a = var_a + 0x60;
            require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
            require(uint32(arg3));
            require(uint32(arg4));
            require((0xffffffff - (uint32(arg3))) > 0xffffffff);
            require(!(uint32(arg4)) > (uint32(0xffffffff - (arg3))));
            var_a = var_a + 0x60;
            require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
            var_a = var_a + 0xe0;
            var_b = uint16(arg1);
            require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
            var_a = var_a + 0x40;
            var_b = uint32(arg2);
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_a = var_a + 0x40;
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            require(!address(var_a.length));
            require(!address(var_a.length));
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_a = var_a + 0x60;
            require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
            require(uint32(storage_map_m[var_b] >> 0x20) == 0x01);
            require(!storage_map_n[var_b]);
            var_b = keccak256(var_b) + 0x05;
            require(!storage_map_n[var_b]);
            require(!0x01);
            require(!uint32(var_a.length));
            require(!uint32(var_ac));
            var_a = var_a + 0x80;
            require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
            var_a = var_a + 0x80;
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            return abi.encodePacked(uint32(var_a.length), uint32(var_as), uint32(var_at), (var_au));
            require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a));
        }
        require(uint32(arg3) + (uint32(arg4)) > 0xffffffff);
    }
    
    /// @custom:selector    0x9783ff0d
    /// @custom:signature   Unresolved_9783ff0d(address arg0, uint16 arg1, uint256 arg2, uint64 arg3) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint64", "bytes8", "int64"]
    function Unresolved_9783ff0d(address arg0, uint16 arg1, uint256 arg2, uint64 arg3) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(!arg2 < 0x02);
        require(arg3 - (uint64(arg3)));
        var_a = uint16(arg1);
        require(!(0x02 > arg2), CustomError_4f3d7def());
        var_a = arg2;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        require(!(0x02 > arg2), CustomError_4f3d7def());
        require(arg2, CustomError_4f3d7def());
        var_a = 0x01;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        return 0;
    }
    
    /// @custom:selector    0x74b140f8
    /// @custom:signature   Unresolved_74b140f8(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4, uint32 arg5) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    /// @param              arg4 ["uint32", "bytes4", "int32"]
    /// @param              arg5 ["uint32", "bytes4", "int32"]
    function Unresolved_74b140f8(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4, uint32 arg5) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9c) < 0x60, CustomError_3ee5aeb5());
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0xe0;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_h[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        require(arg3 - (uint32(arg3)));
        require(arg4 - (uint32(arg4)));
        require(arg5 - (uint32(arg5)));
        if (((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a)) {
            var_a = var_a + 0xe0;
            var_b = uint16(arg1);
            require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
            var_a = var_a + 0x40;
            var_b = uint32(arg2);
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_a = var_a + 0x40;
            require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
            require(!address(var_a.length));
            require(!address(var_a.length));
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_a = var_a + 0x60;
            require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
            require(uint32(storage_map_m[var_b] >> 0x20) == 0x01);
            require(!storage_map_n[var_b]);
            var_b = keccak256(var_b) + 0x05;
            require(!storage_map_n[var_b]);
            require(!0x01);
            require(!uint32(var_a.length));
            transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
            require(!uint32(var_ae));
            return abi.encodePacked(uint32(var_a.length), uint32(var_ap), uint32(var_aq), uint32(var_ar), uint32(var_as), !(!var_at), var_au);
            require(!(var_ao) < 0x05);
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
        require(!(!bytes1(storage_map_o[var_g])), CustomError_965ad3ca());
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
    
    /// @custom:selector    0x0a8e135c
    /// @custom:signature   getMarginAccountableOpenOrderNotional(address arg0, uint16 arg1, uint32 arg2) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getMarginAccountableOpenOrderNotional(address arg0, uint16 arg1, uint32 arg2) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x40;
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = var_c + 0x40;
        require(address(var_c.length));
        require(address(var_i));
        require(0 > 0);
        return 0;
    }
    
    /// @custom:selector    0x938bf2f4
    /// @custom:signature   getTickLevelInfo(address arg0, uint16 arg1, uint24 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint24", "bytes3", "int24"]
    function getTickLevelInfo(address arg0, uint16 arg1, uint24 arg2) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint24(arg2)));
        var_a = uint16(arg1);
        var_a = uint24(arg2);
        require(0 < 0x08);
        return abi.encodePacked(storage_map_d[var_a], uint16(storage_map_p[var_a]), 0);
        require(!0 < 0x02);
        require(0 < 0x05);
        require(!0 < 0x05);
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 < 0x08);
        return abi.encodePacked(storage_map_d[var_a], uint16(storage_map_p[var_a]), 0);
        require(0 | (0x2c == 0));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 > (0 + (uint48((storage_map_q[keccak256(var_a) + 0x01] >> 0) >> 0))));
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
    
    /// @custom:selector    0xae29ea43
    /// @custom:signature   peekNextSettlement(address arg0, uint16 arg1) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function peekNextSettlement(address arg0, uint16 arg1) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        address var_b = keccak256(var_a);
        require(!storage_map_e[var_a]);
        require(!storage_map_e[var_a]);
        require(!0x01);
        return abi.encodePacked(0, 0, 0, 0);
        var_a = uint24(storage_map_d[var_a]);
        var_a = uint32(storage_map_p[var_a] >> 0x90);
        require(uint32(storage_map_d[var_a]) - (uint32(storage_map_p[var_a] >> 0xd0)) > 0xffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return abi.encodePacked(0x01, uint24(storage_map_d[var_a]), uint32(storage_map_d[var_a] >> 0x20), uint32(storage_map_d[var_a] - (storage_map_p[var_a] >> 0xd0)));
        require(!0);
        return abi.encodePacked(0, 0, 0, 0);
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
    
    /// @custom:selector    0x7ea923c4
    /// @custom:signature   getExpiryQueueInfo(address arg0, uint16 arg1) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function getExpiryQueueInfo(address arg0, uint16 arg1) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        require(0 == (uint32(storage_map_r[var_a])), CustomError_35278d12());
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c), CustomError_35278d12());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x40;
        require(!(uint32(var_c.length)), CustomError_35278d12());
        require(uint32(block.timestamp) < (uint32(var_g)), CustomError_35278d12());
        return abi.encodePacked(!(!uint32(storage_map_r[var_a])), uint32(storage_map_r[var_a]), uint16(storage_map_s[var_a]), uint32(storage_map_s[var_a] >> 0x10), 0);
        require(uint32(block.timestamp) - (uint32(var_g)) > 0xffffffff, CustomError_35278d12());
        require(!(uint32(var_c.length)), CustomError_35278d12());
        require((uint32(block.timestamp - (var_g) / (var_c.length)) + 0x01) > 0xffffffff, CustomError_35278d12());
        require(!(uint32(block.timestamp - (var_g) / (var_c.length) + 0x01) < 0x0100000000), CustomError_35278d12());
        var_a = 0x35278d12;
        return abi.encodePacked(!(!uint32(storage_map_r[var_a])), uint32(storage_map_r[var_a]), uint16(storage_map_s[var_a]), uint32(storage_map_s[var_a] >> 0x10), uint32(block.timestamp - (var_g) / (var_c.length) + 0x01));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return abi.encodePacked(!(!uint32(storage_map_r[var_a])), uint32(storage_map_r[var_a]), uint16(storage_map_s[var_a]), uint32(storage_map_s[var_a] >> 0x10), 0);
        return abi.encodePacked(!(!uint32(storage_map_r[var_a])), uint32(storage_map_r[var_a]), uint16(storage_map_s[var_a]), uint32(storage_map_s[var_a] >> 0x10), 0);
    }
    
    /// @custom:selector    0x97ebdd7a
    /// @custom:signature   hasOpenOrders(address arg0, uint16 arg1, uint32 arg2) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function hasOpenOrders(address arg0, uint16 arg1, uint32 arg2) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(address(storage_map_d[var_a]));
        require(0);
        return 0x01;
        require(storage_map_d[var_a] >> 0x80);
        return 0;
    }
    
    /// @custom:selector    0xab79af4e
    /// @custom:signature   Unresolved_ab79af4e(uint224 arg0) public payable
    /// @param              arg0 ["uint224", "bytes28", "int224"]
    function Unresolved_ab79af4e(uint224 arg0) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_222c22ca());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_222c22ca());
        require(!0, CustomError_222c22ca());
        require(arg0 > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_222c22ca());
        address var_g = msg.sender;
        require(!storage_map_o[var_g] >> 0xe0);
        storage_map_o[var_g] = (uint32(storage_map_o[var_g])) | (uint224(arg0));
        emit HooksRegistered(msg.sender, arg0);
        require(uint32(store_t) == 0xffffffff);
        store_t = (uint224(store_t)) | (uint32(0x01 + (store_t)));
        var_g = address(msg.sender);
        storage_map_o[var_g] = (uint224(storage_map_o[var_g])) | (uint32((0x01 + (store_t)) << 0xe0));
        emit Event_37a8aa76(address(msg.sender), uint32(0x01 + (store_t)));
        storage_map_o[var_g] = (uint32(storage_map_o[var_g])) | (uint224(arg0));
        emit HooksRegistered(msg.sender, arg0);
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
    
    /// @custom:selector    0x4737bb9a
    /// @custom:signature   getOrderSeqId(address arg0, uint16 arg1, uint40 arg2) public view returns (uint16)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint40", "bytes5", "int40"]
    function getOrderSeqId(address arg0, uint16 arg1, uint40 arg2) public view returns (uint16) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint40(arg2)));
        var_a = uint16(arg1);
        var_a = uint40(arg2);
        return uint16(storage_map_d[var_a] >> 0xa8);
    }
    
    /// @custom:selector    0xe2765f70
    /// @custom:signature   Unresolved_e2765f70(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4, uint64 arg5) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    /// @param              arg5 ["uint64", "bytes8", "int64"]
    function Unresolved_e2765f70(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4, uint64 arg5) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xc0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(!arg3 < 0x02);
        require(arg4 - (uint24(arg4)));
        require(arg5 - (uint64(arg5)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        if (!0x02 > arg3) {
            require(!0x02 > arg3);
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
    
    /// @custom:selector    0x46022da1
    /// @custom:signature   getBookConfig(address arg0, uint16 arg1) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function getBookConfig(address arg0, uint16 arg1) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
    }
    
    /// @custom:selector    0x90242fe6
    /// @custom:signature   getMarginAccountableOpenOrderSizes(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getMarginAccountableOpenOrderSizes(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0x40;
        require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = var_c + 0x40;
        require(address(var_c.length));
        require(address(var_i));
        require(0 > 0);
        return abi.encodePacked(0, 0, 0);
    }
    
    /// @custom:selector    0xf4e868f0
    /// @custom:signature   cancelOrders(uint16 arg0, uint40[] arg1, uint32 arg2) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function cancelOrders(uint16 arg0, uint40[] arg1, uint32 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (uint16(arg0)));
        require(arg1 > 0xffffffffffffffff);
        require(!(arg1 + 0x23) < msg.data.length);
        require(arg1 > 0xffffffffffffffff);
        require(((arg1 + (arg1 << 0x05)) + 0x24) > msg.data.length);
        require(arg2 - (uint32(arg2)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        var_d = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        var_h = 0x64;
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        uint256 var_i = var_i + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(!arg1);
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_k = address(msg.sender);
        (bool success, bytes memory ret0) = address(authority).Unresolved_94c7d7ee(var_k); // call
        if (var_p < 0x40) {
            require(var_p < 0x40);
            require(((0x60 + var_p) - 0x60) < 0x40);
            require(var_h - var_h);
            require(var_d - (uint32(var_d)));
        }
        require(!var_p < 0x20);
        require(((0x60 + var_p) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x626a686b
    /// @custom:signature   pausedFunction(bytes4 arg0) public view returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function pausedFunction(bytes4 arg0) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (uint32(arg0)));
        uint32 var_a = uint32(arg0);
        require(!bytes1(storage_map_d[var_a]));
        return !(!bytes1(storage_map_d[var_a]));
        return !(!bytes1(unresolved_5c975abb));
    }
    
    /// @custom:selector    0x5d6ab07d
    /// @custom:signature   getEpochInterval() public view returns (bytes memory)
    function getEpochInterval() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if (((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a)) {
            uint256 var_a = var_a + 0x40;
            return abi.encodePacked(uint32(var_a.length), uint32(var_i));
        }
    }
    
    /// @custom:selector    0xc74a6d96
    /// @custom:signature   cleanExpiredEpochs(address arg0, uint16 arg1, uint32 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function cleanExpiredEpochs(address arg0, uint16 arg1, uint32 arg2) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        if (uint16(getEpochBucketSize)) {
            if (!uint32(store_u)) {
                if (!uint32(arg2)) {
                    var_a = uint16(arg1);
                    require(!(!uint16(getEpochBucketSize)), CustomError_4f3d7def());
                    require(!(uint32(store_u)), CustomError_4f3d7def());
                    require(!(uint32(arg2)), CustomError_4f3d7def());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    uint256 var_d = var_d + 0x40;
                    require(!(uint32(storage_map_r[var_a])), CustomError_4f3d7def());
                    require(!(uint32(storage_map_r[var_a])), CustomError_4f3d7def());
                    require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d), CustomError_4f3d7def());
                    require(!(uint32(var_d.length)), CustomError_4f3d7def());
                    require(uint32(block.timestamp) < (uint32(var_g)), CustomError_4f3d7def());
                    var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
                    require(!0, CustomError_4f3d7def());
                    var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff, CustomError_4f3d7def());
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff, CustomError_4f3d7def());
                }
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]), CustomError_4f3d7def());
                require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01), CustomError_4f3d7def());
                require(!0, CustomError_4f3d7def());
                require(0 == (0 > (uint32(arg2))), CustomError_4f3d7def());
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = var_d + 0x40;
                require(0 < (uint32(arg2)), CustomError_4f3d7def());
                require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d), CustomError_4f3d7def());
                require(!(uint32(var_d.length)), CustomError_4f3d7def());
                require(uint32(block.timestamp) < (uint32(var_g)), CustomError_4f3d7def());
                require(!0, CustomError_4f3d7def());
                var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
                require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff, CustomError_4f3d7def());
                var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
                require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff, CustomError_4f3d7def());
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]), CustomError_4f3d7def());
            }
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01), CustomError_4f3d7def());
            var_a = 0;
            require(!0, CustomError_4f3d7def());
            require(storage_map_d[var_a], CustomError_4f3d7def());
            require(0 < storage_map_d[var_a], CustomError_4f3d7def());
            var_a = keccak256(var_a);
            require(!(0 < storage_map_d[var_a]), CustomError_4f3d7def());
            var_a = keccak256(var_a);
            storage_map_w[var_a] = uint216(storage_map_w[var_a]);
            var_a = uint16(arg1);
            var_a = uint40(storage_map_w[var_a] >> 0);
            require(!(0 < storage_map_d[var_a]), CustomError_4f3d7def());
            require(!(uint32(storage_map_d[var_a])), CustomError_4f3d7def());
            var_d = var_d + 0x40;
            require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d), CustomError_4f3d7def());
            var_a = 0;
            storage_map_d[var_a] = 0;
            require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d), CustomError_4f3d7def());
            var_a = keccak256(var_a);
            require(storage_map_d[var_a], CustomError_4f3d7def());
            storage_map_v[keccak256(var_a) + 0x07] = (uint224(storage_map_v[keccak256(var_a) + 0x07])) | 0;
            var_a = 0;
            require(0 < ((storage_map_d[var_a] + 0x05) / 0x06), CustomError_4f3d7def());
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(!(bytes1(storage_map_d[var_a])), CustomError_4f3d7def());
            require(uint256(storage_map_d[var_a]), CustomError_4f3d7def());
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(0 == 0xffffffff, CustomError_4f3d7def());
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(uint256(storage_map_d[var_a]), CustomError_4f3d7def());
        }
        require(0, CustomError_4f3d7def());
        var_a = 0;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        var_a = 0x01;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = uint16(arg1);
        require(storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x4f3d7def00000000000000000000000000000000000000000000000000000000;
        require(storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x01;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x4f3d7def00000000000000000000000000000000000000000000000000000000;
        emit OrderbookChecksum(address(arg0), uint16(arg1), keccak256(var_a));
        address var_k = address(arg0);
        (bool success, bytes memory ret0) = address(this).Unresolved_c2a15c6e(var_k); // call
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        require(0x40 > ret0.length);
        require(((var_d + 0x40) > 0xffffffffffffffff) | ((var_d + 0x40) < var_d));
        var_d = var_d + 0x40;
        require(((var_d + 0x40) - var_d) < 0x40);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        require(uint32(block.timestamp) - (uint32(var_g)) > 0xffffffff, CustomError_c0ef84bf());
        require(!(uint32(var_d.length)), CustomError_c0ef84bf());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
    }
    
    /// @custom:selector    0xc54aca37
    /// @custom:signature   Unresolved_c54aca37(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    function Unresolved_c54aca37(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(!arg3 < 0x02);
        require(arg4 - (uint24(arg4)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(!0x02 > arg3);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(arg3);
        require(address(storage_map_d[var_a] >> 0x80));
        return abi.encodePacked(0, 0);
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
    
    /// @custom:selector    0xc201571d
    /// @custom:signature   Unresolved_c201571d(uint32 arg0, uint32 arg1, uint32 arg2, uint256 arg3, uint256 arg4, uint16 arg5, uint256 arg6, uint256 arg7, uint256 arg8) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg12 ["uint32", "bytes4", "int32"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    /// @param              arg14 ["uint256", "bytes32", "int256"]
    /// @param              arg15 ["uint16", "bytes2", "int16"]
    /// @param              arg16 ["uint256", "bytes32", "int256"]
    /// @param              arg17 ["uint256", "bytes32", "int256"]
    /// @param              arg18 ["uint256", "bytes32", "int256"]
    function Unresolved_c201571d(uint32 arg0, uint32 arg1, uint32 arg2, uint256 arg3, uint256 arg4, uint16 arg5, uint256 arg6, uint256 arg7, uint256 arg8) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0260);
        require(0x0180 > (msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc));
        require(arg12 - (uint32(arg12)));
        require(arg13 - 11);
        require(arg14 - 11);
        require(arg15 - (uint16(arg15)));
        require(arg16 - 11);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        var_d = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        var_h = 0x64;
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        uint256 var_i = var_i + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        require(arg1 - (uint32(arg1)));
        require(uint32(arg1) == 0xffffffff, CustomError_b4fe4100());
        require(arg0 - (uint16(arg0)));
        if (uint16(getEpochBucketSize)) {
            require(!(!uint16(getEpochBucketSize)), CustomError_6a8f9857());
            var_a = uint16(arg0);
            require(!(uint32(store_u)), CustomError_6a8f9857());
            require(!(uint32(storage_map_r[var_a])), CustomError_6a8f9857());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_i = var_i + 0x40;
            require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i), CustomError_6a8f9857());
            require(!(uint32(var_i.length)), CustomError_6a8f9857());
            require(uint32(block.timestamp) < (uint32(var_n)), CustomError_6a8f9857());
            require(!0, CustomError_6a8f9857());
            require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff, CustomError_6a8f9857());
            var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
            require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff, CustomError_6a8f9857());
            var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
            require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]), CustomError_6a8f9857());
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01), CustomError_6a8f9857());
        }
        require(!0, CustomError_6a8f9857());
        require(!0, CustomError_6a8f9857());
        require(0 > 0x05, CustomError_6a8f9857());
        var_a = 0x6a8f985700000000000000000000000000000000000000000000000000000000;
        if (!uint32(storage_map_r[var_a])) {
            if (((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i)) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_i = var_i + 0x40;
                if (!uint32(var_i.length)) {
                    require(!uint32(storage_map_r[var_a]));
                    require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
                    require(!uint32(var_i.length));
                    require(uint32(block.timestamp) < (uint32(var_n)));
                    var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
                    require(!0);
                    var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
                    require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff);
                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                    require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff);
                }
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]));
                require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01));
                require(!0);
                require(0 == (0 > 0));
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_i = var_i + 0x40;
                require(0 < 0);
                require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
                require(!uint32(var_i.length));
                require(uint32(block.timestamp) < (uint32(var_n)));
                require(!0);
                var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
                require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff);
                var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
                require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]));
            }
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01));
            var_a = 0;
            require(!0);
            require(storage_map_d[var_a]);
            require(0 < storage_map_d[var_a]);
            var_a = keccak256(var_a);
            require(!0 < storage_map_d[var_a]);
            var_a = keccak256(var_a);
            storage_map_w[var_a] = uint216(storage_map_w[var_a]);
            require(!0 < storage_map_d[var_a]);
            var_a = uint16(arg0);
            var_a = uint40(storage_map_w[var_a] >> 0);
            require(0x02 == 0x02);
            require(!uint32(storage_map_d[var_a]));
            var_i = var_i + 0x40;
            require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
            var_a = 0;
            storage_map_d[var_a] = 0;
            require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
            var_a = keccak256(var_a);
            require(storage_map_d[var_a]);
            storage_map_v[keccak256(var_a) + 0x07] = (uint224(storage_map_v[keccak256(var_a) + 0x07])) | 0;
            var_a = 0;
            require(0 < ((storage_map_d[var_a] + 0x05) / 0x06));
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(!bytes1(storage_map_d[var_a]));
            require(uint256(storage_map_d[var_a]));
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(0 == 0xffffffff);
            var_a = 0;
            storage_map_d[var_a] = uint256(storage_map_d[var_a]);
            require(uint256(storage_map_d[var_a]));
        }
        require(arg0 - (uint16(arg0)));
        require(uint32(block.timestamp) - (uint32(var_n)) > 0xffffffff, CustomError_c0ef84bf());
        require(!(uint32(var_i.length)), CustomError_c0ef84bf());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_t = address(msg.sender);
        var_u = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_t, var_u); // call
        if (var_y < 0x40) {
            require(var_y < 0x40);
            require(((0x60 + var_y) - 0x60) < 0x40);
            require(var_h - var_h);
            require(var_d - (uint32(var_d)));
        }
        require(!var_y < 0x20);
        require(((0x60 + var_y) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xad3bd55f
    /// @custom:signature   pumpDirtyLevels(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    /// @param              arg4 ["uint32", "bytes4", "int32"]
    function pumpDirtyLevels(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint32(arg3)));
        require(arg4 - (uint32(arg4)));
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0x80;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_h[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(bytes1(store_x), CustomError_965ad3ca());
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        require(uint32(arg2));
        require(uint32(arg3));
        require(uint32(arg4));
        require(0 == (uint32(arg4) < (uint32(arg2))));
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        var_b = uint16(arg1);
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
        var_a = var_a + 0x40;
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
    }
    
    /// @custom:selector    0xdaabc137
    /// @custom:signature   setHeaderVersion(uint8 arg0) public payable returns (uint256)
    /// @param              arg0 ["bool", "uint8", "bytes1", "int8"]
    function setHeaderVersion(uint8 arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (bytes1(arg0)));
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f), CustomError_98948a57());
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length, CustomError_98948a57());
        require(!0, CustomError_98948a57());
        address var_g = msg.sender;
        require(!(bytes1(arg0) > (bytes1(storage_map_y[var_g]))), CustomError_98948a57());
        storage_map_y[var_g] = (uint248(storage_map_y[var_g])) | (bytes1(arg0));
        var_g = bytes1(arg0);
        storage_map_o[var_g] = (uint192(storage_map_o[var_g])) | (uint64(block.number));
        return ;
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
    
    /// @custom:selector    0x461c1bf1
    /// @custom:signature   peekDirtyLevel(address arg0, uint16 arg1) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function peekDirtyLevel(address arg0, uint16 arg1) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        if (((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a)) {
            uint256 var_a = var_a + 0x60;
            var_b = uint16(arg1);
            address var_g = keccak256(var_b);
            if (!storage_map_n[var_b]) {
                require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
                var_b = var_g + 0x05;
                require(!storage_map_n[var_b]);
                require(!storage_map_n[var_b]);
                var_b = uint16(arg1);
                var_b = uint24(var_h);
                require(!0x01);
                var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                return abi.encodePacked(var_a.length, uint24(var_m), uint32(var_n));
                return abi.encodePacked(var_a.length, uint24(var_m), uint32(var_n));
                var_b = uint24(storage_map_h[var_b]);
                var_b = uint32(storage_map_z[var_b] >> 0x90);
                require(uint32(storage_map_z[var_b] >> 0xb0) - (uint32(storage_map_z[var_b] >> 0x90)) > 0xffffffff);
                var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(uint32(storage_map_h[var_b]) - (uint32(storage_map_z[var_b] >> 0xd0)) > 0xffffffff);
                return abi.encodePacked(var_a.length, uint24(var_m), uint32(var_n));
                require(!0x01);
            }
        }
    }
    
    /// @custom:selector    0x378513b7
    /// @custom:signature   Unresolved_378513b7(uint16 arg0, uint64 arg1, uint64 arg2) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    /// @param              arg2 ["uint64", "bytes8", "int64"]
    function Unresolved_378513b7(uint16 arg0, uint64 arg1, uint64 arg2) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (uint16(arg0)));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdc) < 0x40);
        var_a = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        var_e = 0x64;
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        uint256 var_f = var_f + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_b); // staticcall
        require(!ret0.length);
        require(!0);
        var_g = uint16(arg0);
        require(((var_f + 0x40) > 0xffffffffffffffff) | ((var_f + 0x40) < var_f));
        var_f = var_f + 0x40;
        require(arg1 - (uint64(arg1)));
        require(arg2 - (uint64(arg2)));
        require(!(uint64(arg1) * (uint64(arg2)) / (uint64(arg1)) == (uint64(arg2)) | (!uint64(arg1))), CustomError_5d81af2e());
        require(!(!(uint64(arg1)) * (uint64(arg2))), CustomError_5d81af2e());
        require(!(!(uint64(arg1) * (uint64(arg2))) % 0xd3c21bcecceda1000000), CustomError_5d81af2e());
        var_g = 0x5d81af2e00000000000000000000000000000000000000000000000000000000;
        storage_map_o[var_g] = (uint192(storage_map_o[var_g])) | (uint64(var_f.length));
        storage_map_o[var_g] = (uint192(storage_map_o[var_g])) | (uint64(var_m << 0x40));
        require(((var_f + 0x80) > 0xffffffffffffffff) | ((var_f + 0x80) < var_f), CustomError_4f3d7def());
        var_f = var_f + 0x80;
        uint16 var_s = uint16(arg0);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_f04837c1(var_s); // staticcall
        require(!0, CustomError_4f3d7def());
        var_g = uint16(arg0);
        require(!(var_t), CustomError_4f3d7def());
        var_g = 0;
        var_g = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_o[var_g], CustomError_4f3d7def());
        require(!(0x02 > 0), CustomError_4f3d7def());
        var_g = 0;
        require(!(0x02 > 0), CustomError_4f3d7def());
        require(0, CustomError_4f3d7def());
        var_g = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_o[var_g], CustomError_4f3d7def());
        var_g = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_o[var_g], CustomError_4f3d7def());
        require(!(var_t), CustomError_35278d12());
        var_g = 0x01;
        var_g = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_o[var_g], CustomError_35278d12());
        require(!(0 < 0x010000000000000000000000), CustomError_35278d12());
        require(!(0 < 0x010000000000000000000000), CustomError_35278d12());
        require(!address(msg.sender).code.length);
        var_s = uint16(arg0);
        (bool success, bytes memory ret0) = address(msg.sender).Unresolved_6d7b773e(var_s); // call
        if (0) {
            require(0, CustomError_5d81af2e());
            require(0x0de0b6b3a7640000, CustomError_5d81af2e());
            require(!((0 == 0) | !0), CustomError_5d81af2e());
            require(!0x01, CustomError_5d81af2e());
        }
        require(!(uint64(arg1) * (uint64(arg2))), CustomError_5d81af2e());
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_w = address(msg.sender);
        var_x = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_w, var_x); // call
        if (var_ab < 0x40) {
            require(var_ab < 0x40);
            require(((0x60 + var_ab) - 0x60) < 0x40);
            require(var_e - var_e);
            require(var_a - (uint32(var_a)));
        }
        require(!var_ab < 0x20);
        require(((0x60 + var_ab) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x4f2af03e
    /// @custom:signature   Unresolved_4f2af03e(address arg0, uint16 arg1, uint32 arg2) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function Unresolved_4f2af03e(address arg0, uint16 arg1, uint32 arg2) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
    }
    
    /// @custom:selector    0xd8138fda
    /// @custom:signature   Unresolved_d8138fda(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    /// @param              arg4 ["uint32", "bytes4", "int32"]
    function Unresolved_d8138fda(address arg0, uint16 arg1, uint32 arg2, uint32 arg3, uint32 arg4) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbc) < 0x60, CustomError_3ee5aeb5());
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0xe0;
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_b = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_h[var_b])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint32(arg3)));
        require(arg4 - (uint32(arg4)));
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        var_b = uint16(arg1);
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
        var_a = var_a + 0x40;
        require(((var_a + 0x40) > 0xffffffffffffffff) | ((var_a + 0x40) < var_a));
    }
    
    /// @custom:selector    0x9b816f88
    /// @custom:signature   computeImpactPrices(address arg0, uint16 arg1, uint256 arg2) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function computeImpactPrices(address arg0, uint16 arg1, uint256 arg2) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_4f3d7def());
        uint256 var_a = var_a + 0x80;
        uint16 var_i = uint16(arg1);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_f04837c1(var_i); // staticcall
        require(0, CustomError_4f3d7def());
        require(var_j, CustomError_4f3d7def());
        require(0 == (!uint88(var_a.length)), CustomError_4f3d7def());
        require(uint88(var_k), CustomError_4f3d7def());
        return abi.encodePacked(uint88(var_a.length), uint88(var_m));
        return abi.encodePacked(uint88(var_a.length), arg2);
        require(uint88(var_k), CustomError_4f3d7def());
        return abi.encodePacked(arg2, uint88(var_k));
        return abi.encodePacked(arg2, arg2);
        var_b = uint16(arg1);
        require(!(var_o), CustomError_4f3d7def());
        var_b = 0;
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        require(!(0x02 > 0), CustomError_4f3d7def());
        var_b = 0;
        require(!(0x02 > 0), CustomError_4f3d7def());
        require(0, CustomError_4f3d7def());
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        require(!var_o);
        var_b = 0x01;
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b]);
        return abi.encodePacked(arg2, arg2);
        return abi.encodePacked(arg2, arg2);
        var_i = uint16(arg1);
        (bool success, bytes memory ret0) = address(arg0).getMarketConfig(var_i); // staticcall
        var_i = uint16(arg1);
        (bool success, bytes memory ret0) = address(arg0).getImpactNotionalBaseUsdc(var_i); // staticcall
        require(0);
        require(0x0de0b6b3a7640000);
        require(!(((0 * (bytes1(var_p))) / 0) == (bytes1(var_p))) | !0);
        require(0x20 > ret0.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        var_a = var_a + 0x20;
        require(((var_a + 0x20) - var_a) < 0x20);
        require(var_a.length - (uint64(var_a.length)));
        require(0xa0 > ret0.length);
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a));
        var_a = var_a + 0xa0;
        require(((var_a + 0xa0) - var_a) < 0xa0);
    }
    
    /// @custom:selector    0xd0d97b59
    /// @custom:signature   getAllOpenOrders(address arg0, uint16 arg1, uint32 arg2) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getAllOpenOrders(address arg0, uint16 arg1, uint32 arg2) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
    }
    
    /// @custom:selector    0x8c4aab23
    /// @custom:signature   getEpochsBehind(address arg0, uint16 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function getEpochsBehind(address arg0, uint16 arg1) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        if (((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            uint256 var_c = var_c + 0x40;
            require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
            require(!uint32(var_c.length));
            require(uint32(block.timestamp) < (uint32(var_g)));
            require(!0);
            require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff > 0xffffffff);
            var_a = ((bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x10) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08));
            require((uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10) + 0x01) > 0xffffffff);
            var_a = (bytes1(((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x18) << 0x08)) | (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x10));
            require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff << (bytes1(uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01))) & (storage_map_d[var_a]));
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) > (bytes1((uint32(uint32(storage_map_v[keccak256(var_a) + 0x07] >> 0x10)) + 0x01) >> 0x08) + 0x01));
        }
        require(!0);
        return 0;
        require(uint32(block.timestamp) - (uint32(var_g)) > 0xffffffff);
        require(!uint32(var_c.length));
    }
    
    /// @custom:selector    0x7c264e2a
    /// @custom:signature   Unresolved_7c264e2a(uint16 arg0, uint32 arg1, uint256 arg2, uint24 arg3, uint64 arg4) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint24", "bytes3", "int24"]
    /// @param              arg4 ["uint64", "bytes8", "int64"]
    function Unresolved_7c264e2a(uint16 arg0, uint32 arg1, uint256 arg2, uint24 arg3, uint64 arg4) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint32(arg1)));
        require(!arg2 < 0x02);
        require(arg3 - (uint24(arg3)));
        require(arg4 - (uint64(arg4)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        var_d = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        var_h = 0x64;
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        uint256 var_i = var_i + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        var_a = uint16(arg0);
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_q = address(msg.sender);
        var_r = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_q, var_r); // call
        if (var_v < 0x40) {
            require(var_v < 0x40);
            require(((0x60 + var_v) - 0x60) < 0x40);
            require(var_h - var_h);
            require(var_d - (uint32(var_d)));
        }
        require(!var_v < 0x20);
        require(((0x60 + var_v) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xfca8d230
    /// @custom:signature   hasUserDeferredWork(address arg0, uint16 arg1, uint32 arg2) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function hasUserDeferredWork(address arg0, uint16 arg1, uint32 arg2) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        address var_b = keccak256(var_a);
        if (((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            uint256 var_c = var_c + 0x60;
            if (uint32(storage_map_a[var_a] >> 0x20) == 0x01) {
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(uint32(storage_map_a[var_a] >> 0x20) == 0x01);
                var_a = var_b + 0x05;
                require(!storage_map_e[var_a]);
                require(!storage_map_e[var_a]);
                var_a = uint32(arg2);
                require(!0x01);
                require(!uint32(var_c.length));
                require(!address(storage_map_d[var_a]));
                require(!address(storage_map_d[var_a]));
                return 0;
                require(address(storage_map_d[var_a]));
                return 0;
                return 0;
                return 0;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                require(storage_map_d[var_a] >> 0x80);
            }
        }
    }
    
    /// @custom:selector    0xc736de67
    /// @custom:signature   Unresolved_c736de67(uint16 arg0, uint32 arg1, uint256 arg2, uint64 arg3) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint64", "bytes8", "int64"]
    function Unresolved_c736de67(uint16 arg0, uint32 arg1, uint256 arg2, uint64 arg3) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint32(arg1)));
        require(!arg2 < 0x02);
        require(arg3 - (uint64(arg3)));
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint32 var_a = uint32(msg.data[0]);
        require(!(!bytes1(storage_map_d[var_a])), CustomError_965ad3ca());
        require(bytes1(unresolved_5c975abb), CustomError_d93c0665());
        var_d = 0xb700961300000000000000000000000000000000000000000000000000000000;
        address var_e = address(msg.sender);
        var_h = 0x64;
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i));
        uint256 var_i = var_i + 0xa0;
        (bool success, bytes memory ret0) = address(authority).Unresolved_b7009613(var_e); // staticcall
        require(!ret0.length);
        require(!0);
        var_a = uint16(arg0);
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        var_i = var_i + 0x40;
        require(((var_i + 0x40) > 0xffffffffffffffff) | ((var_i + 0x40) < var_i));
        require(!0);
        authority = 0x010000000000000000000000000000000000000000 | (uint248(authority));
        require(!address(authority).code.length);
        address var_q = address(msg.sender);
        var_r = 0x40;
        (bool success, bytes memory ret0) = address(authority).consumeScheduledOp(var_q, var_r); // call
        if (var_v < 0x40) {
            require(var_v < 0x40);
            require(((0x60 + var_v) - 0x60) < 0x40);
            require(var_h - var_h);
            require(var_d - (uint32(var_d)));
        }
        require(!var_v < 0x20);
        require(((0x60 + var_v) - 0x60) < 0x20);
        require(ret0.length > 0xffffffffffffffff);
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
        require(!(!bytes1(storage_map_o[var_g])), CustomError_965ad3ca());
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
    
    /// @custom:selector    0xa1fa35a2
    /// @custom:signature   Unresolved_a1fa35a2(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg4 ["uint24", "bytes3", "int24"]
    function Unresolved_a1fa35a2(address arg0, uint16 arg1, uint32 arg2, uint256 arg3, uint24 arg4) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0xa0);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        require(!arg3 < 0x02);
        require(arg4 - (uint24(arg4)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        require(!0x02 > arg3);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(arg3);
        require(address(storage_map_d[var_a] >> 0x80));
        return 0;
    }
    
    /// @custom:selector    0x703dc975
    /// @custom:signature   getHeaderVersion(address arg0, uint64 arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    function getHeaderVersion(address arg0, uint64 arg1) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint64(arg1)));
        address var_a = address(arg0);
        require(!bytes1(storage_map_a[var_a]));
        require(!(bytes1(storage_map_a[var_a])) > 0x01);
        var_a = bytes1(storage_map_a[var_a]);
        require(!(uint64(storage_map_d[var_a])) > (uint64(arg1)));
        require(!bytes1(storage_map_a[var_a]));
        require(!(bytes1(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (storage_map_a[var_a]))) > 0x01);
        return 0x01;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return bytes1(storage_map_a[var_a]);
        return 0x01;
        return 0x01;
    }
    
    /// @custom:selector    0xcfe7e2d7
    /// @custom:signature   getOrderFlags(address arg0, uint16 arg1, uint40 arg2) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint40", "bytes5", "int40"]
    function getOrderFlags(address arg0, uint16 arg1, uint40 arg2) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint40(arg2)));
        var_a = uint16(arg1);
        var_a = uint40(arg2);
        return bytes1(storage_map_d[var_a] >> 0xe8);
    }
    
    /// @custom:selector    0x7ca37f9e
    /// @custom:signature   pendingWorkCount(address arg0, uint16 arg1) public view returns (uint32)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function pendingWorkCount(address arg0, uint16 arg1) public view returns (uint32) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        return uint32(storage_map_a[var_a] >> 0x20);
    }
    
    /// @custom:selector    0x7df3c3cf
    /// @custom:signature   getOrdersInEpoch(address arg0, uint16 arg1, uint32 arg2) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getOrdersInEpoch(address arg0, uint16 arg1, uint32 arg2) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        var_a = uint32(arg2);
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0x55e2f7dd
    /// @custom:signature   getTotalOpenOrders(address arg0, uint16 arg1, uint32 arg2) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getTotalOpenOrders(address arg0, uint16 arg1, uint32 arg2) public pure {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
    }
    
    /// @custom:selector    0x7ff94633
    /// @custom:signature   getProjectedFillChunks(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    function getProjectedFillChunks(address arg0, uint16 arg1, uint32 arg2) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint32(arg2)));
        var_a = uint16(arg1);
        address var_b = keccak256(var_a);
        if (((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c)) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            uint256 var_c = var_c + 0x60;
            if (uint32(storage_map_a[var_a] >> 0x20) == 0x01) {
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(uint32(storage_map_a[var_a] >> 0x20) == 0x01);
                var_a = var_b + 0x05;
                require(!storage_map_e[var_a]);
                var_e = 0;
                require(!storage_map_e[var_a]);
                var_a = uint32(arg2);
                require(!0x01);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = var_c + 0x40;
                require(!uint32(var_c.length));
                require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
                require(!address(var_c.length));
                var_c = var_c + 0x60;
                require(!address(var_c.length));
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(var_m);
                var_c = var_c + 0xa0;
                require(((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c));
                var_c = var_c + 0x60;
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                var_c = var_c + 0x20;
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
                require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
                require(address(var_c.length));
                require(address(var_m));
                require(!uint32(var_ad));
                var_c = var_c + 0x40;
                require(uint40(var_m));
                require(((var_c + 0x40) > 0xffffffffffffffff) | ((var_c + 0x40) < var_c));
                require(0 < 0x20);
                var_c = var_c + 0xa0;
                require(!var_c.length);
                var_c = var_c + 0x60;
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                var_c = var_c + 0x20;
                require(((var_c + 0x60) > 0xffffffffffffffff) | ((var_c + 0x60) < var_c));
            }
            require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
            require(!var_ap);
            require(!var_aq);
            require(var_aq > 0xffffffffffffffff);
            require(0 < var_aq);
            return abi.encodePacked(0x20, var_aq);
            require(!0x02 > (var_as));
        }
    }
    
    /// @custom:selector    0xc2a15c6e
    /// @custom:signature   syncImpactPriceCache(address arg0, uint16 arg1) public payable returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    function syncImpactPriceCache(address arg0, uint16 arg1) public payable returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_4f3d7def());
        uint256 var_a = var_a + 0x80;
        uint16 var_i = uint16(arg1);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_f04837c1(var_i); // staticcall
        require(!0, CustomError_4f3d7def());
        var_b = uint16(arg1);
        require(!(var_k), CustomError_4f3d7def());
        var_b = 0;
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        require(!(0x02 > 0), CustomError_4f3d7def());
        var_b = 0;
        require(!(0x02 > 0), CustomError_4f3d7def());
        require(0, CustomError_4f3d7def());
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_4f3d7def());
        require(!(var_k), CustomError_35278d12());
        var_b = 0x01;
        var_b = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_h[var_b], CustomError_35278d12());
        require(!(0 < 0x010000000000000000000000), CustomError_35278d12());
        require(!(0 < 0x010000000000000000000000), CustomError_35278d12());
        require(!address(arg0).code.length);
        var_i = uint16(arg1);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_6d7b773e(var_i); // call
        return abi.encodePacked(0, 0);
        require(((var_a + 0) > 0xffffffffffffffff) | ((var_a + 0) < var_a));
        var_a = var_a + 0;
        return abi.encodePacked(0, 0);
        return abi.encodePacked(0, 0);
        require(0);
        require(0x0de0b6b3a7640000);
        require(!(0 == 0) | !0);
        require(!0x01);
        return abi.encodePacked(0, 0);
        require(0xa0 > ret0.length);
        require(((var_a + 0xa0) > 0xffffffffffffffff) | ((var_a + 0xa0) < var_a));
        var_a = var_a + 0xa0;
        require(((var_a + 0xa0) - var_a) < 0xa0);
        require(var_a.length - (uint64(var_a.length)));
        require(var_o - (bytes1(var_o)));
        require(var_k - (uint88(var_k)));
        require(var_p - (uint88(var_p)));
        require(var_q - (var_q));
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
        require(!(!bytes1(storage_map_o[var_g])), CustomError_965ad3ca());
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
    
    /// @custom:selector    0xb6bf1da7
    /// @custom:signature   getDeferredPending(address arg0, uint16 arg1, uint40 arg2) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint40", "bytes5", "int40"]
    function getDeferredPending(address arg0, uint16 arg1, uint40 arg2) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        require(arg2 - (uint40(arg2)));
        var_a = uint16(arg1);
        var_a = uint40(arg2);
        require(!(!uint32(storage_map_d[var_a])), CustomError_4e23d035());
        require(uint32(storage_map_d[var_a]) - (uint32(storage_map_d[var_a] >> 0x20)) > 0xffffffff, CustomError_4e23d035());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint32(storage_map_d[var_a] - (storage_map_d[var_a] >> 0x20))), CustomError_4e23d035());
        var_a = uint24(storage_map_d[var_a] >> 0x60);
        require(uint32(storage_map_d[var_a]) - (uint32(storage_map_d[var_a] >> 0x20)) > 0xffffffff, CustomError_4e23d035());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint64(uint32(uint32(uint32(storage_map_d[var_a])) - (uint32(uint32(storage_map_d[var_a] >> 0x20)))))), CustomError_4e23d035());
        require(!(uint64((storage_map_aa[var_a] >> 0x50) < (storage_map_aa[var_a] >> 0x10) * ((storage_map_aa[var_a] >> 0x10) - (storage_map_aa[var_a] >> 0x50)))), CustomError_4e23d035());
        require(uint16(storage_map_d[var_a] >> 0xa8) > 0x8000, CustomError_4e23d035());
        var_a = 0x4e23d03500000000000000000000000000000000000000000000000000000000;
        require(!uint16(storage_map_d[var_a] >> 0xa8));
        require((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > (uint16(storage_map_d[var_a] >> 0xa8)));
        require((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c);
        require(((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) > (uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)));
        require(((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) > (uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)));
        require(uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (uint16(storage_map_d[var_a] >> 0xa8)));
        require(!(uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) < storage_map_d[var_a]);
        require(!(uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) < storage_map_d[var_a]);
        var_a = keccak256(var_a);
        require(!uint40(storage_map_ab[uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x06] >> (((uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) % 0x06) * 0x05) << 0x03)));
        var_a = uint40(storage_map_ab[uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x06] >> (((uint248(uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) % 0x06) * 0x05) << 0x03));
        require(uint32(storage_map_d[var_a]) - (uint32(storage_map_d[var_a] >> 0x20)) > 0xffffffff);
        require(0 > 0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((0 - (uint64(uint32(uint32(uint32(storage_map_d[var_a])) - (uint32(uint32(storage_map_d[var_a] >> 0x20))))))) > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)) < ((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04));
        require(0 > 0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) < ((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04));
        require(!(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) / 0x07) < 0x0125);
        require((uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) < 0x07);
        require(!(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) < 0x07);
        require((uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) / 0x07) == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04)) % 0x07) | (0x24 == (((uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) * 0x24) / (uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07))));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 > (0 + (uint40((storage_map_ac[(keccak256(var_a) + 0x01) + 0x18] >> 0) >> ((uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) % 0x07) * 0x24)))));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint248((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x04) == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)) < ((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08));
        require(uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) < ((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08));
        require(!(uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) / 0x06) < 0x16);
        require((uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) < 0x06);
        require(!(uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) < 0x06);
        require(!(!(uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08)) % 0x06) | (0x28 == (((uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06) * 0x28) / (uint240((uint16(uint16(storage_map_d[var_a] >> 0xa8)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x08) % 0x06))));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c);
        require(0 < ((uint16(storage_map_d[var_a] >> 0xa8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) >> 0x0c));
        require(!0 < 0x02);
        require(0 < 0x05);
        require(!0 < 0x05);
        require(0 | (0x2c == 0));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(uint32(storage_map_d[var_a] >> 0xc8) - 0xffffffff);
        require(!uint0(storage_map_d[var_a] >> 0xe8));
        return abi.encodePacked(uint32(uint64((0 > 0xffffffff) * 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000001)), uint24(storage_map_d[var_a] >> 0x60), 11);
        return abi.encodePacked(uint32(uint64((0 > 0xfffffffe) * 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000002)), uint24(storage_map_d[var_a] >> 0x60), 11);
        require(uint32(storage_map_d[var_a] >> 0xc8));
        require((uint32(storage_map_d[var_a] >> 0xc8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > 0xffffffff);
        return abi.encodePacked(uint32(uint64((0 > (uint64((storage_map_d[var_a] >> 0xc8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))) * (0 - (uint64((storage_map_d[var_a] >> 0xc8) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))))), uint24(storage_map_d[var_a] >> 0x60), 11);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return abi.encodePacked(uint32(uint64((0 > 0) * 0)), uint24(storage_map_d[var_a] >> 0x60), 11);
        return abi.encodePacked(0, 0, 11);
    }
    
    /// @custom:selector    0xe8415d23
    /// @custom:signature   computeOrderbookChecksum(address arg0, uint16 arg1, uint256 arg2) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint16", "bytes2", "int16"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function computeOrderbookChecksum(address arg0, uint16 arg1, uint256 arg2) public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (uint16(arg1)));
        var_a = uint16(arg1);
        var_a = 0;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        var_a = 0x01;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = uint16(arg1);
        require(storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x4f3d7def00000000000000000000000000000000000000000000000000000000;
        require(storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x01;
        var_a = 0x7710c0702d438d37259561c892984b894ff622adfa3d98b5dfe5a9763f94b955;
        require(!storage_map_d[var_a], CustomError_4f3d7def());
        var_a = 0x4f3d7def00000000000000000000000000000000000000000000000000000000;
        return keccak256(var_a);
        return 0;
    }
    
    /// @custom:selector    0x1d0ec0a8
    /// @custom:signature   getCurrentFillBoundary(uint16 arg0, uint24 arg1, uint32 arg2, uint32 arg3) public view
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    /// @param              arg1 ["uint24", "bytes3", "int24"]
    /// @param              arg2 ["uint32", "bytes4", "int32"]
    /// @param              arg3 ["uint32", "bytes4", "int32"]
    function getCurrentFillBoundary(uint16 arg0, uint24 arg1, uint32 arg2, uint32 arg3) public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x80);
        require(arg0 - (uint16(arg0)));
        require(arg1 - (uint24(arg1)));
        require(arg2 - (uint32(arg2)));
        require(arg3 - (uint32(arg3)));
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_aa98edbf());
        uint256 var_a = var_a + 0xc0;
        var_b = uint16(arg0);
        var_b = uint24(arg1);
        require(!(uint32(storage_map_z[var_b] >> 0xb0)), CustomError_aa98edbf());
        require((uint32(storage_map_z[var_b] >> 0xb0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > 0xffffffff, CustomError_aa98edbf());
        var_b = uint32((storage_map_z[var_b] >> 0xb0) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        require(!(uint32(storage_map_h[var_b] >> 0x20) == (uint32(arg2))), CustomError_aa98edbf());
        var_b = 0xaa98edbf00000000000000000000000000000000000000000000000000000000;
        require(!(!uint32(arg3)), CustomError_b668422c());
        require(!(!(uint32(arg3)) > (uint32(storage_map_h[var_b]))), CustomError_b668422c());
        var_b = 0xb668422c00000000000000000000000000000000000000000000000000000000;
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a), CustomError_aa98edbf());
        var_a = var_a + 0xc0;
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_aa98edbf());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(uint64((storage_map_i[var_b] >> 0x50) < (storage_map_i[var_b] >> 0x10) * ((storage_map_i[var_b] >> 0x10) - (storage_map_i[var_b] >> 0x50)))) < (uint32(storage_map_h[var_b]))), CustomError_aa98edbf());
        var_b = 0xaa98edbf00000000000000000000000000000000000000000000000000000000;
        if (uint64(var_v) - (uint64(uint32(storage_map_h[var_b]))) > 0xffffffffffffffff) {
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint64(var_v) - (uint64(uint32(storage_map_h[var_b]))) > 0xffffffffffffffff, CustomError_b668422c());
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint64(var_v - (uint32(storage_map_h[var_b]))) + (uint64(uint32(arg3))) > 0xffffffffffffffff, CustomError_b668422c());
            require(0 < 0x08, CustomError_b668422c());
            require(0 < 0x10, CustomError_b668422c());
            require(0 > 0, CustomError_b668422c());
            require(0 < 0x10, CustomError_b668422c());
            require(!(0 < 0x0125), CustomError_b668422c());
            require(0 < 0x07, CustomError_b668422c());
            require(!(0 < 0x07), CustomError_b668422c());
            require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_b668422c());
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(!0 | (0x24 == 0)), CustomError_b668422c());
            require(!(uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3))) > (uint40((storage_map_ad[(keccak256(var_b) + 0x01) + 0x18] >> 0) >> 0))), CustomError_b668422c());
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3))) - (uint40((storage_map_ad[(keccak256(var_b) + 0x01) + 0x18] >> 0) >> 0)) > (uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3)))), CustomError_b668422c());
            require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_b668422c());
            require(!(0 < 0x16), CustomError_b668422c());
            require(0 < 0x06, CustomError_b668422c());
            require(!(0 < 0x06), CustomError_b668422c());
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(!(!0 | (0x28 == 0)), CustomError_b668422c());
            require(!(uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3))) > (uint40((storage_map_ae[(keccak256(var_b) + 0x01) + 0x02] >> 0) >> 0))), CustomError_b668422c());
            var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            require(uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3))) - (uint40((storage_map_ae[(keccak256(var_b) + 0x01) + 0x02] >> 0) >> 0)) > (uint64(var_v - (uint32(storage_map_h[var_b])) + (uint32(arg3)))), CustomError_b668422c());
            require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, CustomError_b668422c());
            require(!(0 < 0x02), CustomError_b668422c());
            require(0 < 0x05, CustomError_b668422c());
            require(!(0 < 0x05), CustomError_b668422c());
            require(!(!0 | (0x2c == 0)), CustomError_b668422c());
        }
        require(!(uint32(arg3)), CustomError_b668422c());
        var_b = 0xb668422c00000000000000000000000000000000000000000000000000000000;
    }
}