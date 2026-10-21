// =============================================================================
//  Gimo st0G — StakeManager implementation 0x7a5e1b999a665f2b89e5f6eae32df9471de193c7
//  0G chain (chainId 16661).  Decompiled with heimdall-rs v0.9.2 from the public
//  runtime bytecode at block 47,841,263.  Bytecode is public; nothing here is secret.
//
//  IMPORTANT — this decompile is LOSSY (heimdall drops loop accumulators and
//  renders many constants as 0).  It is kept only as a cross-check of the
//  SELECTOR SET and CONTROL FLOW.  All security conclusions in ../README.md are
//  based on the *verified source* (analysis/StakeManager_source.sol), which was
//  proven byte-identical to the deployed code in CI (ci-out/source_verify.json).
//
//  How the source was recovered (the 0G explorer is a JS SPA and Sourcify 404s):
//      GET https://chainscan-api.0g.ai/v1/contract/0x7a5e1b999a665f2b89e5f6eae32df9471de193c7
//  -> result.sourceCode (112,783 bytes), result.verify {name: StakeManager,
//     version: v0.8.19+commit.7dd6d404, optimization: 1, runs: 200,
//     exactMatch: True}.  Recompiled and compared in CI.
// =============================================================================

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
    uint256 public constant MAX_RATE_CHANGE_LIMIT = 5000000000000000;
    uint256 public constant MAX_ERA_SECONDS = 172800;
    uint256 public constant MAX_UNBONDING_DURATION = 32;
    uint256 public constant MAX_VALIDATORS_LEN = 30;
    uint256 public constant MIN_ERA_SECONDS = 3600;
    uint256 public constant unresolved_52d1902d = 3963877391197344453575983046348115674221700746820753546331534351508065746944;
    uint256 public constant MAX_PROTOCOL_FEE_COMMISSION = 200000000000000000;
    uint256 public constant UNSTAKE_TIMES_LIMIT = 100;
    
    mapping(bytes32 => bytes32) storage_map_c;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_w;
    address public lsdToken;
    mapping(bytes32 => bytes32) storage_map_am;
    mapping(bytes32 => bytes32) storage_map_ak;
    bool public version;
    address storage_map_j[storage_map_c[var_a] - 0x01];
    mapping(bytes32 => bytes32) storage_map_j;
    bytes32 store_a;
    mapping(bytes32 => bytes32) storage_map_k;
    bytes32 store_ag;
    uint256 public eraOffset;
    mapping(bytes32 => bytes32) storage_map_b;
    address storage_map_y[storage_map_p[var_b] - 0x01];
    uint256 public nextUnstakeIndex;
    mapping(bytes32 => bytes32) storage_map_x;
    uint256 public minStakeAmount;
    address store_af;
    uint256 public unbondingDuration;
    uint256 public totalProtocolFee;
    uint256 public latestEra;
    uint256 public eraSeconds;
    mapping(bytes32 => bytes32) storage_map_z;
    mapping(bytes32 => bytes32) storage_map_v;
    bytes32 store_ac;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_g;
    mapping(bytes32 => bytes32) storage_map_ad;
    address public pendingOwner;
    mapping(bytes32 => bytes32) storage_map_aa;
    mapping(bytes32 => bytes32) storage_map_y;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_m;
    uint256 public rate;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_l;
    uint256 public rateChangeLimit;
    address store_ah;
    mapping(bytes32 => bytes32) storage_map_aj;
    uint256 public protocolFeeCommission;
    
    event SetUnbondingDuration(uint256);
    error PoolNotEmpty();
    event ExecuteNewEra(uint256, uint256);
    event Upgraded(address);
    event Withdraw(address, address, uint256, int256[]);
    event Initialized(uint8);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x3ccfd60b
    /// @custom:signature   withdraw() public
    function withdraw() public {
        require(0 < store_a, CustomError_219055cc());
        address var_a = address(msg.sender);
        address var_c = var_c + (0x20 + (0x20 * (storage_map_b[var_a])));
        require(!(storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_b[var_a])) > (0x20 + (0x20 + var_c)), CustomError_219055cc());
        var_a = msg.sender;
        require(!(storage_map_c[var_a] > 0xffffffffffffffff), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!storage_map_c[var_a], CustomError_219055cc());
        require(eraSeconds, CustomError_219055cc());
        require(!(((block.timestamp / eraSeconds) - eraOffset) > (block.timestamp / eraSeconds)), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0 < storage_map_c[var_a]), CustomError_219055cc());
        var_a = var_h;
        var_c = var_c + 0x80;
        require(!(storage_map_c[var_a] > (unbondingDuration + storage_map_c[var_a])), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((unbondingDuration + storage_map_c[var_a]) > ((block.timestamp / eraSeconds) - eraOffset), CustomError_219055cc());
        require(!((unbondingDuration + storage_map_c[var_a]) > ((block.timestamp / eraSeconds) - eraOffset)), CustomError_219055cc());
        require(0x01, CustomError_219055cc());
        var_a = var_h;
        require(!storage_map_c[var_a], CustomError_219055cc());
        require(!((storage_map_c[var_a] - 0x01) > storage_map_c[var_a]), CustomError_219055cc());
        require(!((storage_map_c[var_a] - 0x01) > storage_map_c[var_a]), CustomError_219055cc());
        require((storage_map_c[var_a] - 0x01) == (storage_map_c[var_a] - 0x01), CustomError_219055cc());
        require((storage_map_c[var_a] - 0x01) < (storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        require((storage_map_c[var_a] - 0x01) < (storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        storage_map_j[storage_map_c[var_a] - 0x01] = storage_map_k[var_a];
        var_a = storage_map_l[var_a];
        storage_map_c[var_a] = storage_map_c[var_a];
        require(storage_map_c[var_a], CustomError_219055cc());
        var_a = keccak256(var_a);
        storage_map_l[var_a] = 0;
        storage_map_c[var_a] = storage_map_c[var_a] - 0x01;
        var_a = var_h;
        storage_map_c[var_a] = 0;
        require(0x01, CustomError_219055cc());
        require(0, CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 > 0);
        address var_n = msg.sender;
        uint256 var_o = 0;
        require(address(storage_map_m[var_a]).code.length);
        (bool success, bytes memory ret0) = address(storage_map_m[var_a]).{ value: storage_map_l[var_a] ether }withdrawForStaker(var_n, var_o); // call
        emit Withdraw(address(msg.sender), address(storage_map_m[var_a]), 0, 0x80, var_c.length);
    }
    
    /// @custom:selector    0xaf737e60
    /// @custom:signature   setProtocolFeeCommission(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setProtocolFeeCommission(uint256 arg0) public {
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(!(arg0 > 0x02c68af0bb140000), CustomError_1f4c147b());
        protocolFeeCommission = arg0;
    }
    
    /// @custom:selector    0x8b9686a9
    /// @custom:signature   setEraParams(uint256 arg0, uint256 arg1) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function setEraParams(uint256 arg0, uint256 arg1) public {
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(0 - eraSeconds, CustomError_b421651f());
        require(!(arg0 < 0x0e10), CustomError_b421651f());
        require(!(arg0 > 0x02a300), CustomError_b421651f());
        require(arg0, CustomError_b7d4c00b());
        require(!(((block.timestamp / arg0) - arg1) > (block.timestamp / arg0)), CustomError_b7d4c00b());
        require(eraSeconds, CustomError_b7d4c00b());
        require(!(((block.timestamp / eraSeconds) - eraOffset) > (block.timestamp / eraSeconds)), CustomError_b7d4c00b());
        require(((block.timestamp / eraSeconds) - eraOffset) == ((block.timestamp / arg0) - arg1), CustomError_b7d4c00b());
        eraSeconds = arg0;
        eraOffset = arg1;
    }
    
    /// @custom:selector    0x97b2ee85
    /// @custom:signature   pendingMigration(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function pendingMigration(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_b = arg0;
        return storage_map_p[var_b];
    }
    
    /// @custom:selector    0x668fb6dc
    /// @custom:signature   withdrawProtocolFee(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function withdrawProtocolFee(address arg0) public {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        var_a = 0x70a0823100000000000000000000000000000000000000000000000000000000;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(lsdToken).Unresolved_70a08231(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), "Address: insufficient balance for call");
        var_c = 0x40 + var_c;
        require(!(address(this).balance < 0), "Address: insufficient balance for call");
        var_l = 0x20;
        uint256 var_n = 0;
        (bool success, bytes memory ret0) = address(lsdToken).{ value: var_n ether }Unresolved_08c379a0(var_l); // call
        require(ret0.length == 0);
        require(!var_p);
        require(0 - var_p, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_p, "SafeERC20: ERC20 operation did not succeed");
        require(!(((0x80 + var_p) - 0x80) < 0x20), "SafeERC20: ERC20 operation did not succeed");
        require(var_a == var_a, "SafeERC20: ERC20 operation did not succeed");
        require(var_a, "SafeERC20: ERC20 operation did not succeed");
        require(address(lsdToken).code.length, "Address: call to non-contract");
        var_c = var_c + (uint248(ret0.length + 0x3f));
        require(!var_c.length);
        require(0 - var_c.length, "Address: call to non-contract");
        require(address(lsdToken).code.length, "Address: call to non-contract");
        require(0 == var_c.length, "SafeERC20: ERC20 operation did not succeed");
        require(0 == var_c.length, "SafeERC20: ERC20 operation did not succeed");
    }
    
    /// @custom:selector    0xf160599a
    /// @custom:signature   Unresolved_f160599a(address arg0, uint256 arg1) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_f160599a(address arg0, uint256 arg1) public view {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(!(msg.value < minStakeAmount), CustomError_41524be2());
        address var_b = address(arg0);
        require(storage_map_p[var_b], CustomError_4ce08c32());
        require((0x0de0b6b3a7640000 == ((0x0de0b6b3a7640000 * msg.value) / msg.value)) | !msg.value, CustomError_4ce08c32());
        require(rate, CustomError_4ce08c32());
        var_b = address(arg0);
        require(!(storage_map_u[var_b] > (msg.value + (storage_map_u[var_b]))), CustomError_4ce08c32());
    }
    
    /// @custom:selector    0xb608b458
    /// @custom:signature   unstakeWithPool(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function unstakeWithPool(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(0 - arg1, CustomError_e7c9b467());
        address var_a = address(arg0);
        require(storage_map_c[var_a], CustomError_e7c9b467());
        var_a = msg.sender;
        require(storage_map_c[var_a] < 0x64, CustomError_e7c9b467());
        require((rate == ((rate * arg1) / arg1)) | !arg1);
        require(0x0de0b6b3a7640000);
        var_a = address(arg0);
        require(!(storage_map_g[var_a]) > (((rate * arg1) / 0x0de0b6b3a7640000) + (storage_map_g[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_g[var_a] = ((rate * arg1) / 0x0de0b6b3a7640000) + (storage_map_g[var_a]);
        require(!(storage_map_h[var_a] - ((rate * arg1) / 0x0de0b6b3a7640000)) > (storage_map_h[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_h[var_a] = (storage_map_h[var_a]) - ((rate * arg1) / 0x0de0b6b3a7640000);
        address var_e = msg.sender;
        require(address(lsdToken).code.length);
        (bool success, bytes memory ret0) = address(lsdToken).{ value: 0 ether }Unresolved_79cc6790(var_e); // call
    }
    
    /// @custom:selector    0x58c76ca8
    /// @custom:signature   rmStakePool(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function rmStakePool(address arg0) public {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        address var_b = address(arg0);
        require(!(!storage_map_w[var_b]), CustomError_334b0656());
        require(!(!storage_map_w[var_b]), CustomError_334b0656());
        require(!(storage_map_w[var_b]), CustomError_334b0656());
        var_b = address(arg0);
        var_d = var_d + (0x20 + (0x20 * (storage_map_x[var_b])));
        require(!storage_map_x[var_b]);
        var_b = 0 + keccak256(var_b);
        require((0x20 + var_d) + (0x20 * (storage_map_x[var_b])) > (0x20 + (0x20 + var_d)));
        address var_j = address(var_k);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_56f0b57e(var_j); // staticcall
        var_d = var_d + (uint248(ret0.length + 0x1f));
        require(!(((var_d + ret0.length) - var_d) < 0x20), CustomError_1f817ee1());
        require(!var_d.length, CustomError_1f817ee1());
        var_b = address(var_k);
        require(!storage_map_p[var_b], CustomError_1f817ee1());
        require(!((storage_map_p[var_b] - 0x01) > storage_map_p[var_b]), CustomError_1f817ee1());
        require(!((storage_map_p[var_b] - 0x01) > storage_map_p[var_b]), CustomError_1f817ee1());
        require((storage_map_p[var_b] - 0x01) == (storage_map_p[var_b] - 0x01), CustomError_1f817ee1());
        require((storage_map_p[var_b] - 0x01) < (storage_map_x[var_b]), CustomError_1f817ee1());
        var_b = 0 + keccak256(var_b);
        require((storage_map_p[var_b] - 0x01) < (storage_map_x[var_b]), CustomError_1f817ee1());
        var_b = 0 + keccak256(var_b);
        storage_map_y[storage_map_p[var_b] - 0x01] = storage_map_z[var_b];
        var_b = storage_map_aa[var_b];
        storage_map_p[var_b] = storage_map_p[var_b];
        require(storage_map_p[var_b], CustomError_1f817ee1());
        var_b = keccak256(var_b);
        storage_map_aa[var_b] = 0;
        storage_map_p[var_b] = storage_map_p[var_b] - 0x01;
        var_b = address(var_k);
        storage_map_p[var_b] = 0;
        require(0x01, CustomError_1f817ee1());
    }
    
    /// @custom:selector    0xd417624a
    /// @custom:signature   initialize(address arg0, address arg1, address[] arg2, uint256 arg3) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function initialize(address arg0, address arg1, address[] arg2, uint256 arg3) public {
        require(arg0 == (address(arg0)));
        require(arg1 == (address(arg1)));
        require(!arg2 > 0xffffffffffffffff);
        require(!(arg2) > 0xffffffffffffffff);
        require(!((var_c + (uint248(((arg2 << 0x05) + 0x20) + 0x1f))) < var_c) | ((var_c + (uint248(((arg2 << 0x05) + 0x20) + 0x1f))) > 0xffffffffffffffff));
        uint256 var_c = var_c + (uint248(((arg2 << 0x05) + 0x20) + 0x1f));
        require(!(0x20 + (0x04 + arg2)) < (0x20 + ((0x04 + arg2) + (arg2 << 0x05))));
        require((0x20 + (arg2)) == (address(0x20 + (arg2))));
        require(!(!bytes1(version / 0x0100)), CustomError_611746eb());
        require(!(bytes1(version / 0x0100)), CustomError_611746eb());
        require(address(this).code.length, CustomError_611746eb());
        require(0x01 == (bytes1(version)), CustomError_611746eb());
        version = 0x01 | (uint248(version));
        require(!(!bytes1(version / 0x0100)), CustomError_611746eb());
        require(bytes1(version / 0x0100), CustomError_611746eb());
        version = (uint96(version)) | (0x010000 * (address(msg.sender)));
        require(bytes1(version / 0x0100), CustomError_611746eb());
        require(bytes1(version / 0x0100), CustomError_611746eb());
        require(address(arg0), CustomError_611746eb());
        lsdToken = (address(arg0)) | (uint96(lsdToken));
        protocolFeeCommission = 0x016345785d8a0000;
        require(bytes1(version / 0x0100), CustomError_611746eb());
        eraSeconds = arg3;
        require(arg3, CustomError_611746eb());
        eraOffset = block.timestamp / arg3;
        require(bytes1(version / 0x0100), CustomError_611746eb());
        require(!(0 > 0x11c37937e08000), CustomError_611746eb());
        rateChangeLimit = 0;
        rate = 0x0de0b6b3a7640000;
        store_ac = 0x0de0b6b3a7640000;
        require(bytes1(version / 0x0100), CustomError_c651392a());
        require(address(arg1), CustomError_c651392a());
        var_a = address(arg1);
        require(storage_map_c[var_a], CustomError_c651392a());
        require(0, CustomError_c651392a());
        require(bytes1(version / 0x0100), CustomError_c651392a());
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffea, CustomError_c651392a());
        require(!(0x16 > 0x20), CustomError_e5ba5a0a());
        unbondingDuration = 0x16;
        emit SetUnbondingDuration(0x16);
        minStakeAmount = 0x038d7ea4c68000;
        require(0 - var_c.length, CustomError_ab0b620f());
        require(!(!bytes1(version / 0x0100)), CustomError_ab0b620f());
        version = uint248(version);
        emit Initialized(0x01);
        store_a = 0x01 + store_a;
        var_a = 0x09;
        storage_map_ad[var_a] = address(arg1);
        var_a = address(arg1);
        storage_map_c[var_a] = store_a;
        require(0x01, CustomError_a9ceed51());
        version = 0x0100 | (uint248(version));
        require(bytes1(version / 0x0100), "Initializable: contract is not initializing");
        version = (uint96(version)) | (0x010000 * (address(msg.sender)));
        require(bytes1(version / 0x0100), "Initializable: contract is not initializing");
        require(bytes1(version / 0x0100), "Initializable: contract is not initializing");
        require(!(bytes1(version / 0x0100)), "Initializable: contract is already initialized");
    }
    
    /// @custom:selector    0xeb8ad76e
    /// @custom:signature   eraRate(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function eraRate(uint256 arg0) public view returns (uint256) {
        uint256 var_b = arg0;
        return storage_map_p[var_b];
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public
    function Unresolved_79ba5097() public {
        require(address(pendingOwner) == msg.sender, CustomError_2af07d20());
        version = (uint96(version)) | (0x010000 * (address(pendingOwner)));
        pendingOwner = uint96(pendingOwner);
        emit OwnershipTransferred(address(version / 0x010000), address(uint96(version) | (0x010000 * (pendingOwner)) / 0x010000));
    }
    
    /// @custom:selector    0xcdf1432e
    /// @custom:signature   Unresolved_cdf1432e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cdf1432e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x19826e71
    /// @custom:signature   setRateChangeLimit(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setRateChangeLimit(uint256 arg0) public {
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(!(arg0 > 0x11c37937e08000), CustomError_611746eb());
        rateChangeLimit = arg0;
    }
    
    /// @custom:selector    0xf737abac
    /// @custom:signature   withdrawWithPool(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function withdrawWithPool(address arg0) public {
        require(arg0 == (address(arg0)));
        address var_a = address(msg.sender);
        address var_c = var_c + (0x20 + (0x20 * (storage_map_b[var_a])));
        require(!(storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_b[var_a])) > (0x20 + (0x20 + var_c)), CustomError_219055cc());
        var_a = msg.sender;
        require(!(storage_map_c[var_a] > 0xffffffffffffffff), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!storage_map_c[var_a], CustomError_219055cc());
        require(eraSeconds, CustomError_219055cc());
        require(!(((block.timestamp / eraSeconds) - eraOffset) > (block.timestamp / eraSeconds)), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0 < storage_map_c[var_a]), CustomError_219055cc());
        var_a = var_h;
        var_c = var_c + 0x80;
        require(!(storage_map_c[var_a] > (unbondingDuration + storage_map_c[var_a])), CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require((unbondingDuration + storage_map_c[var_a]) > ((block.timestamp / eraSeconds) - eraOffset), CustomError_219055cc());
        require(!((unbondingDuration + storage_map_c[var_a]) > ((block.timestamp / eraSeconds) - eraOffset)), CustomError_219055cc());
        require(0x01, CustomError_219055cc());
        var_a = var_h;
        require(!storage_map_c[var_a], CustomError_219055cc());
        require(!((storage_map_c[var_a] - 0x01) > storage_map_c[var_a]), CustomError_219055cc());
        require(!((storage_map_c[var_a] - 0x01) > storage_map_c[var_a]), CustomError_219055cc());
        require((storage_map_c[var_a] - 0x01) == (storage_map_c[var_a] - 0x01), CustomError_219055cc());
        require((storage_map_c[var_a] - 0x01) < (storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        require((storage_map_c[var_a] - 0x01) < (storage_map_b[var_a]), CustomError_219055cc());
        var_a = 0 + keccak256(var_a);
        storage_map_j[storage_map_c[var_a] - 0x01] = storage_map_k[var_a];
        var_a = storage_map_l[var_a];
        storage_map_c[var_a] = storage_map_c[var_a];
        require(storage_map_c[var_a], CustomError_219055cc());
        var_a = keccak256(var_a);
        storage_map_l[var_a] = 0;
        storage_map_c[var_a] = storage_map_c[var_a] - 0x01;
        var_a = var_h;
        storage_map_c[var_a] = 0;
        require(0x01, CustomError_219055cc());
        require(0, CustomError_219055cc());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 > 0);
        address var_n = msg.sender;
        uint256 var_o = 0;
        require(address(arg0).code.length);
        (bool success, bytes memory ret0) = address(arg0).{ value: storage_map_l[var_a] ether }withdrawForStaker(var_n, var_o); // call
        emit Withdraw(address(msg.sender), address(arg0), 0, 0x80, var_c.length);
    }
    
    /// @custom:selector    0x301b97b0
    /// @custom:signature   getValidatorsOf(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getValidatorsOf(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        address var_c = var_c + (0x20 + (0x20 * (storage_map_b[var_a])));
        require(!storage_map_b[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_b[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0x130ae7ea
    /// @custom:signature   Unresolved_130ae7ea(address arg0, uint256 arg1) public view
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_130ae7ea(address arg0, uint256 arg1) public view {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(0 < store_a, CustomError_41524be2());
        require(!(msg.value < minStakeAmount), CustomError_41524be2());
        address var_a = address(storage_map_m[var_a]);
        require(storage_map_c[var_a], CustomError_4ce08c32());
        require((0x0de0b6b3a7640000 == ((0x0de0b6b3a7640000 * msg.value) / msg.value)) | !msg.value, CustomError_4ce08c32());
        require(rate, CustomError_4ce08c32());
        var_a = address(storage_map_m[var_a]);
        require(!(storage_map_f[var_a] > (msg.value + (storage_map_f[var_a]))), CustomError_4ce08c32());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xfd852c1b
    /// @custom:signature   Unresolved_fd852c1b(address arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_fd852c1b(address arg0, uint256 arg1, uint256 arg2) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(0 - arg2);
        address var_b = address(arg0);
        require(storage_map_p[var_b]);
        require(!0 < (arg1));
        require(0 < (arg1));
        require(!(((0 + (0x20 + (0x04 + arg1))) + 0x20) - (0 + (0x20 + (0x04 + arg1)))) < 0x20);
        require((0 + (0x20 + (arg1))) == (address(0 + (0x20 + (arg1)))));
        var_b = address(0 + (0x20 + (arg1)));
        require(storage_map_p[var_b], CustomError_92fbbd30());
        require(0x01, CustomError_92fbbd30());
        var_e = 0x40;
        require(!0 < (arg1));
        require((0x20 + (arg1)) == (address(0x20 + (arg1))));
        require(address(arg0).code.length);
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_64af066b(var_e); // call
        var_b = address(arg0);
        require(!(storage_map_p[var_b] > (arg2 + storage_map_p[var_b])), CustomError_4ce08c32());
    }
    
    /// @custom:selector    0x62b8e169
    /// @custom:signature   Unresolved_62b8e169(address arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_62b8e169(address arg0, uint256 arg1, uint256 arg2) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(0 - arg2, CustomError_e8d2d1d9());
        address var_b = address(arg0);
        require(storage_map_p[var_b], CustomError_e8d2d1d9());
        var_b = address(arg0);
        require(!(arg2 > storage_map_p[var_b]), CustomError_e8d2d1d9());
        require(!0 < (arg1));
        require(0 < (arg1));
        require(!(((0 + (0x20 + (0x04 + arg1))) + 0x20) - (0 + (0x20 + (0x04 + arg1)))) < 0x20);
        require((0 + (0x20 + (arg1))) == (address(0 + (0x20 + (arg1)))));
        var_b = address(0 + (0x20 + (arg1)));
        require(storage_map_p[var_b], CustomError_92fbbd30());
        require(0x01, CustomError_92fbbd30());
        var_b = address(arg0);
        require(!(storage_map_p[var_b] - arg2) > storage_map_p[var_b]);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_p[var_b] = storage_map_p[var_b] - arg2;
        var_e = 0x40;
        require(!0 < (arg1));
        require((0x20 + (arg1)) == (address(0x20 + (arg1))));
        require(address(arg0).code.length);
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_ef652037(var_e); // call
    }
    
    /// @custom:selector    0x40decaad
    /// @custom:signature   setUnbondingDuration(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setUnbondingDuration(uint256 arg0) public {
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(0 - arg0, CustomError_e5ba5a0a());
        require(!(arg0 > 0x20), CustomError_e5ba5a0a());
        unbondingDuration = arg0;
        emit SetUnbondingDuration(arg0);
    }
    
    /// @custom:selector    0x89a407c9
    /// @custom:signature   Unresolved_89a407c9(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_89a407c9(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1 > 0xffffffffffffffff), "Function must be called through delegatecall");
        require(!(((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) < var_c) | ((var_c + (uint248((0x20 + (arg1 + 0x1f)) + 0x1f))) > 0xffffffffffffffff)), "Function must be called through delegatecall");
        require(address(this) - 0x7a5e1b999a665f2b89e5f6eae32df9471de193c7, "Function must be called through delegatecall");
        require(address(store_af) == 0x7a5e1b999a665f2b89e5f6eae32df9471de193c7, CustomError_2af07d20());
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(!(bytes1(store_ag)), "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_g = 0x20;
        store_af = (address(arg0)) | (uint96(store_af));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        var_a = var_a;
        require(0x01 == var_a, "ERC1967: new implementation is not a contract");
        require(address(0x0fb2).code.length, "ERC1967: new implementation is not a contract");
        store_af = 0x0fb2 | (uint96(store_af));
        emit Upgraded(0x0fb2);
        require(var_k > 0);
        require(!var_k > 0);
        var_c = 0x60 + var_c;
        require(!0 < var_k);
        (bool success, bytes memory ret0) = address(0x0fb2).Unresolved_(var_n); // delegatecall
        require(ret0.length == 0);
        require(!var_o);
        require(0 - var_o, "Address: call to non-contract");
        require(address(0x0fb2).code.length, "Address: call to non-contract");
        var_c = var_c + (uint248(ret0.length + 0x3f));
        require(!var_c.length);
        require(0 - var_c.length, "Address: call to non-contract");
        require(address(0x0fb2).code.length, "Address: call to non-contract");
        require(!var_c, "ERC1967Upgrade: unsupported proxiableUUID");
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), "ERC1967Upgrade: new implementation is not UUPS");
        require(0x01, "ERC1967Upgrade: new implementation is not UUPS");
        var_a = var_a;
        require(var_c.length == var_a, "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_af = (address(arg0)) | (uint96(store_af));
        emit Upgraded(address(arg0));
        require(var_c.length > 0, "ERC1967Upgrade: unsupported proxiableUUID");
        require(!(var_c.length > 0), "ERC1967Upgrade: unsupported proxiableUUID");
        require(!0x01, "ERC1967Upgrade: unsupported proxiableUUID");
    }
    
    /// @custom:selector    0x3659cfe6
    /// @custom:signature   upgradeTo(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function upgradeTo(address arg0) public {
        require(arg0 == (address(arg0)));
        require(address(this) - 0x7a5e1b999a665f2b89e5f6eae32df9471de193c7, "Function must be called through delegatecall");
        require(address(store_ah) == 0x7a5e1b999a665f2b89e5f6eae32df9471de193c7, CustomError_2af07d20());
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(!(bytes1(store_ag)), "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        var_c = 0x20;
        store_ah = (address(arg0)) | (uint96(store_ah));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_c); // staticcall
        var_f = var_f;
        require(0 == var_f, "ERC1967: new implementation is not a contract");
        require(address(0x0ad3).code.length, "ERC1967: new implementation is not a contract");
        store_ah = 0x0ad3 | (uint96(store_ah));
        emit Upgraded(0x0ad3);
        require(var_j > 0);
        require(!var_j > 0);
        var_g = 0x60 + var_g;
        require(!0 < var_j);
        (bool success, bytes memory ret0) = address(0x0ad3).Unresolved_(var_m); // delegatecall
        require(ret0.length == 0);
        require(!var_n);
        require(0 - var_n, "Address: call to non-contract");
        require(address(0x0ad3).code.length, "Address: call to non-contract");
        var_g = var_g + (uint248(ret0.length + 0x3f));
        require(!var_g.length);
        require(0 - var_g.length, "Address: call to non-contract");
        require(address(0x0ad3).code.length, "Address: call to non-contract");
        require(!var_g, "ERC1967Upgrade: unsupported proxiableUUID");
        var_g = var_g + (uint248(ret0.length + 0x1f));
        require(!(((var_g + ret0.length) - var_g) < 0x20), "ERC1967Upgrade: new implementation is not UUPS");
        require(0x01, "ERC1967Upgrade: new implementation is not UUPS");
        var_f = var_f;
        require(var_g.length == var_f, "ERC1967: new implementation is not a contract");
        require(address(arg0).code.length, "ERC1967: new implementation is not a contract");
        store_ah = (address(arg0)) | (uint96(store_ah));
        emit Upgraded(address(arg0));
        require(var_g.length > 0, "ERC1967Upgrade: unsupported proxiableUUID");
        require(!(var_g.length > 0), "ERC1967Upgrade: unsupported proxiableUUID");
    }
    
    /// @custom:selector    0xeb4af045
    /// @custom:signature   setMinStakeAmount(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setMinStakeAmount(uint256 arg0) public {
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        minStakeAmount = arg0;
    }
    
    /// @custom:selector    0x2e17de78
    /// @custom:signature   unstake(uint256 arg0) public
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function unstake(uint256 arg0) public {
        require(0 < store_a, CustomError_e7c9b467());
        require(0 - arg0, CustomError_e7c9b467());
        address var_a = address(storage_map_m[var_a]);
        require(storage_map_c[var_a], CustomError_e7c9b467());
        var_a = msg.sender;
        require(storage_map_c[var_a] < 0x64, CustomError_e7c9b467());
        require((rate == ((rate * arg0) / arg0)) | !arg0);
        require(0x0de0b6b3a7640000);
        var_a = address(storage_map_m[var_a]);
        require(!(storage_map_g[var_a]) > (((rate * arg0) / 0x0de0b6b3a7640000) + (storage_map_g[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_g[var_a] = ((rate * arg0) / 0x0de0b6b3a7640000) + (storage_map_g[var_a]);
        require(!(storage_map_h[var_a] - ((rate * arg0) / 0x0de0b6b3a7640000)) > (storage_map_h[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_h[var_a] = (storage_map_h[var_a]) - ((rate * arg0) / 0x0de0b6b3a7640000);
        address var_e = msg.sender;
        require(address(lsdToken).code.length);
        (bool success, bytes memory ret0) = address(lsdToken).{ value: 0 ether }Unresolved_79cc6790(var_e); // call
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(address(arg0), CustomError_2b53784e());
        pendingOwner = (address(arg0)) | (uint96(pendingOwner));
    }
    
    /// @custom:selector    0xb1819c2b
    /// @custom:signature   Unresolved_b1819c2b(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b1819c2b(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x46f45b8d
    /// @custom:signature   Unresolved_46f45b8d(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_46f45b8d(uint256 arg0) public view {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(0 < store_a, CustomError_41524be2());
        require(!(msg.value < minStakeAmount), CustomError_41524be2());
        address var_a = address(storage_map_m[var_a]);
        require(storage_map_c[var_a], CustomError_4ce08c32());
        require((0x0de0b6b3a7640000 == ((0x0de0b6b3a7640000 * msg.value) / msg.value)) | !msg.value, CustomError_4ce08c32());
        require(rate, CustomError_4ce08c32());
        var_a = address(storage_map_m[var_a]);
        require(!(storage_map_f[var_a] > (msg.value + (storage_map_f[var_a]))), CustomError_4ce08c32());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x0f772a1d
    /// @custom:signature   addStakePool(address arg0) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addStakePool(address arg0) public {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(version / 0x010000)), CustomError_2af07d20());
        require(address(arg0), CustomError_a9ceed51());
        address var_b = address(arg0);
        require(storage_map_p[var_b], CustomError_a9ceed51());
        require(0, CustomError_a9ceed51());
        store_a = 0x01 + store_a;
        var_b = 0x09;
        storage_map_aj[var_b] = address(arg0);
        var_b = address(arg0);
        storage_map_p[var_b] = store_a;
        require(0x01, CustomError_a9ceed51());
    }
    
    /// @custom:selector    0x58af8bf0
    /// @custom:signature   getBondedPools() public view returns (bytes memory)
    function getBondedPools() public view returns (bytes memory) {
        uint256 var_a = var_a + (0x20 + (0x20 * store_a));
        if (!store_a) {
            var_c = 0x09;
            if ((0x20 + var_a) + (0x20 * store_a) > (0x20 + (0x20 + var_a))) {
                return abi.encodePacked(0x20, var_a.length);
            }
        }
    }
    
    /// @custom:selector    0x6e436c6e
    /// @custom:signature   unstakeAtIndex(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function unstakeAtIndex(uint256 arg0) public view returns (bytes memory) {
        uint256 var_b = arg0;
        return abi.encodePacked(storage_map_p[var_b], address(storage_map_u[var_b]), address(storage_map_v[var_b]), storage_map_w[var_b]);
    }
    
    /// @custom:selector    0x12dd4cb6
    /// @custom:signature   Unresolved_12dd4cb6(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_12dd4cb6(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x615acc36
    /// @custom:signature   getUnstakeIndexListOf(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getUnstakeIndexListOf(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        address var_c = var_c + (0x20 + (0x20 * (storage_map_b[var_a])));
        require(!storage_map_b[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_b[var_a])) > (0x20 + (0x20 + var_c)));
        return abi.encodePacked(0x20, var_c.length);
    }
    
    /// @custom:selector    0x7b207727
    /// @custom:signature   newEra() public
    function newEra() public {
        require(!0x01 > (latestEra + 0x01));
        require(eraSeconds);
        require(!((block.timestamp / eraSeconds) - eraOffset) > (block.timestamp / eraSeconds));
        require(!((block.timestamp / eraSeconds) - eraOffset) < (latestEra + 0x01));
        latestEra = latestEra + 0x01;
        uint256 var_c = var_c + (0x20 + (0x20 * store_a));
        require(!store_a);
        var_a = 0x09;
        require((0x20 + var_c) + (0x20 * store_a) > (0x20 + (0x20 + var_c)));
        address var_a = address(var_f);
        var_c = var_c + (0x20 + (0x20 * (storage_map_b[var_a])));
        require(!storage_map_b[var_a]);
        var_a = 0 + keccak256(var_a);
        require((0x20 + var_c) + (0x20 * (storage_map_b[var_a])) > (0x20 + (0x20 + var_c)));
        var_i = 0x20;
        require(address(var_f).code.length);
        (bool success, bytes memory ret0) = address(var_f).{ value: 0 ether }Unresolved_e71731e4(var_i); // call
        var_a = address(var_f);
        var_c = var_c + 0x80;
        require(!(storage_map_f[var_a]) > (storage_map_g[var_a]));
        require(!(var_f - (var_n)) > (var_f));
        var_p = 0x40;
        require(address(var_f).code.length);
        (bool success, bytes memory ret0) = address(var_f).{ value: 0 ether }Unresolved_ef652037(var_p); // call
        if (!(var_f) < (var_n)) {
        }
        require(0 - rate);
        require(!0);
        require((protocolFeeCommission == ((protocolFeeCommission * 0) / 0)) | !0);
        require(rate);
        require(!(protocolFeeCommission * 0) / rate);
        require(!totalProtocolFee > (((protocolFeeCommission * 0) / rate) + totalProtocolFee));
        totalProtocolFee = ((protocolFeeCommission * 0) / rate) + totalProtocolFee;
        address var_s = address(this);
        uint256 var_i = (protocolFeeCommission * 0) / rate;
        require(address(lsdToken).code.length);
        (bool success, bytes memory ret0) = address(lsdToken).{ value: 0 ether }mint(var_s, var_i); // call
        (bool success, bytes memory ret0) = address(lsdToken / 0x01).totalSupply(var_s); // staticcall
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6098ba0a());
        require(0 - var_c.length, CustomError_6098ba0a());
        require(!rateChangeLimit, CustomError_6098ba0a());
        require(0x0de0b6b3a7640000 > rate, CustomError_6098ba0a());
        require(!((rate - 0x0de0b6b3a7640000) > rate), CustomError_6098ba0a());
        require((0x0de0b6b3a7640000 == ((0x0de0b6b3a7640000 * (rate - 0x0de0b6b3a7640000)) / (rate - 0x0de0b6b3a7640000))) | (!rate - 0x0de0b6b3a7640000), CustomError_6098ba0a());
        require(rate, CustomError_6098ba0a());
        require(!(((0x0de0b6b3a7640000 * (rate - 0x0de0b6b3a7640000)) / rate) > rateChangeLimit), CustomError_6098ba0a());
        rate = 0x0de0b6b3a7640000;
        var_a = latestEra + 0x01;
        storage_map_c[var_a] = 0x0de0b6b3a7640000;
        emit ExecuteNewEra(latestEra + 0x01, 0x0de0b6b3a7640000);
        rate = 0x0de0b6b3a7640000;
        var_a = latestEra + 0x01;
        storage_map_c[var_a] = 0x0de0b6b3a7640000;
        emit ExecuteNewEra(latestEra + 0x01, 0x0de0b6b3a7640000);
        if ((0x0de0b6b3a7640000 == 0) | !0) {
            if (var_c.length) {
                require((0x0de0b6b3a7640000 == 0) | !0);
                require(var_c.length);
                require(!(0 / var_c.length) < 0x0de0b6b3a7640000);
                require(!(0 / var_c.length) < 0x0de0b6b3a7640000);
            }
            rate = 0 / var_c.length;
            var_a = latestEra + 0x01;
            storage_map_c[var_a] = 0 / var_c.length;
            emit ExecuteNewEra(latestEra + 0x01, 0 / var_c.length);
            require(!rateChangeLimit);
            require(!(0x0de0b6b3a7640000 - (0 / var_c.length)) > 0x0de0b6b3a7640000);
        }
    }
}