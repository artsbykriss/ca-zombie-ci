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
    uint256 public constant MAX_OPEN_TICKETS = 64;
    uint256 public constant NUM_OPTIONS = 4;
    uint256 public constant MAX_PURGE_RESIDUAL = 1000000;
    uint256 public constant unresolved_52d1902d = e07c8dba;
    uint256 public constant UNSTAKE_DRIP = 2592000;
    uint256 public constant MAX_BOOST_BPS = 100000;
    uint256 public constant MAX_REWARD_TOKENS = 32;
    
    uint256 public rewardTokensLength;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_c;
    mapping(bytes32 => bytes32) storage_map_v;
    address public treasury;
    mapping(bytes32 => bytes32) storage_map_a;
    mapping(bytes32 => bytes32) storage_map_g;
    address public unresolved_8da5cb5b;
    bytes32 store_q;
    address store_w;
    address public rewardNotifier;
    address public legacyRouter;
    uint256 public totalEffectiveStake;
    mapping(bytes32 => bytes32) storage_map_k;
    mapping(bytes32 => bytes32) storage_map_p;
    address storage_map_x[rewardTokensLength * 0x01];
    bytes32 store_t;
    address public moto;
    address public pendingOwner;
    address public feeRouter;
    mapping(bytes32 => bytes32) storage_map_e;
    address public upgradeAuthority;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_x;
    mapping(bytes32 => bytes32) storage_map_o;
    
    error ZeroAddress();
    event UpgradesRenounced();
    event OwnershipTransferStarted(address, address);
    event Upgraded(address);
    event UpgradeAuthoritySet(address, address);
    event RewardTokenAdded(address);
    event Unstaked(address, uint256);
    event RewardNotifierSet(address);
    event Claimed(address, address, uint256);
    event RewardTokenRemoved(address);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0xa068e6aa
    /// @custom:signature   Unresolved_a068e6aa(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a068e6aa(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x99eabeb9
    /// @custom:signature   rewardOwed(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function rewardOwed(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_a[var_a] >> 0;
    }
    
    /// @custom:selector    0x1e83409a
    /// @custom:signature   claim(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function claim(address arg0) public payable returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_a = address(msg.sender);
        require(0x2710 > (0x2710 + (storage_map_c[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a]))) | !storage_map_a[var_a]);
        require(!0x2710);
        require(!0 < rewardTokensLength);
        require(!0 < rewardTokensLength);
        var_a = address(storage_map_e[var_a] >> 0);
        require((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) > 0);
        require(storage_map_a[var_a] > storage_map_a[var_a]);
        require(storage_map_a[var_a] - storage_map_a[var_a] > storage_map_a[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) == (storage_map_a[var_a] - storage_map_a[var_a])) | (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710));
        require(!0x0c9f2c9cd04674edea40000000);
        var_a = address(storage_map_e[var_a] >> 0);
        require(storage_map_a[var_a] > (storage_map_a[var_a] + ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / 0x0c9f2c9cd04674edea40000000)));
        var_a = address(arg0);
        require(storage_map_a[var_a] > 0);
        require(storage_map_a[var_a] > 0);
        address var_e = address(msg.sender);
        require(((var_h + (uint248(0x1f + ((((var_h + 0x20) + 0x04) + 0x40) - var_h)))) > 0xffffffffffffffff) | ((var_h + (uint248(0x1f + ((((var_h + 0x20) + 0x04) + 0x40) - var_h)))) < var_h));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_a9059cbb(var_e); // call
        require(ret0.length - 0, CustomError_5274afe7());
        require(address(arg0).code.length == 0, CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        emit Claimed(address(msg.sender), address(arg0), storage_map_a[var_a]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return storage_map_a[var_a];
        require(!(var_a == 0x01), CustomError_5274afe7());
        emit Claimed(address(msg.sender), address(arg0), storage_map_a[var_a]);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return storage_map_a[var_a];
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x70ca5bbe
    /// @custom:signature   ticketCount(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function ticketCount(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x685abbe6
    /// @custom:signature   claimableUnstaked(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function claimableUnstaked(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        require(!0 < storage_map_a[var_a]);
        require(!0 < storage_map_a[var_a]);
        var_a = keccak256(var_a);
        require((block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) > block.timestamp);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) < 0x278d00);
        require(!(storage_map_g[0 + keccak256(var_a)] * (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) / (storage_map_g[0 + keccak256(var_a)]) == (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)])))) | (!storage_map_g[0 + keccak256(var_a)]));
        require(!0x278d00);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0 < storage_map_a[var_a]);
        return 0;
    }
    
    /// @custom:selector    0xb5fd73f8
    /// @custom:signature   isRewardToken(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isRewardToken(address arg0) public view returns (bool) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return !(!bytes1(storage_map_a[var_a] >> 0));
    }
    
    /// @custom:selector    0x6ac0ca13
    /// @custom:signature   Unresolved_6ac0ca13(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_6ac0ca13(uint256 arg0) public pure {
        require(msg.value);
        require(arg0 - arg0);
    }
    
    /// @custom:selector    0x7da0831f
    /// @custom:signature   Unresolved_7da0831f(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7da0831f(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x4e71d92d
    /// @custom:signature   claim() public view
    function claim() public view {
        require(msg.value);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_a = address(msg.sender);
        if (0x2710 > (0x2710 + (storage_map_c[var_a]))) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            if (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a]))) | !storage_map_a[var_a]) {
                if (!0x2710) {
                    if (!0 < rewardTokensLength) {
                        if (!0 < rewardTokensLength) {
                            var_a = address(storage_map_e[var_a] >> 0);
                            if ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) > 0) {
                                if (storage_map_a[var_a] > storage_map_a[var_a]) {
                                    if (storage_map_a[var_a] - storage_map_a[var_a] > storage_map_a[var_a]) {
                                        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                        if (!((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) == (storage_map_a[var_a] - storage_map_a[var_a])) | (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710)) {
                                            if (!0x0c9f2c9cd04674edea40000000) {
                                                var_a = address(storage_map_e[var_a] >> 0);
                                                if (storage_map_a[var_a] > (storage_map_a[var_a] + ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / 0x0c9f2c9cd04674edea40000000))) {
                                                    if (!0 < rewardTokensLength) {
                                                        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
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
    
    /// @custom:selector    0x7bb7bed1
    /// @custom:signature   rewardTokens(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function rewardTokens(uint256 arg0) public view returns (address) {
        require(msg.value);
        require(arg0 - arg0);
        require(!arg0 < rewardTokensLength);
        require(!arg0 < rewardTokensLength);
        return address(storage_map_k[arg0 * 0x01] >> 0);
    }
    
    /// @custom:selector    0xb6bac01b
    /// @custom:signature   Unresolved_b6bac01b(bool arg0) public pure
    /// @param              arg0 ["bool", "uint8", "bytes1", "int8"]
    function Unresolved_b6bac01b(bool arg0) public pure {
        require(msg.value);
        require(bytes1(arg0) - arg0);
    }
    
    /// @custom:selector    0xca78533d
    /// @custom:signature   pendingClaims(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function pendingClaims(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_a[var_a] >> 0;
    }
    
    /// @custom:selector    0x29aed87c
    /// @custom:signature   Unresolved_29aed87c(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_29aed87c(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0xe0ae165e
    /// @custom:signature   appendStake(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function appendStake(uint256 arg0) public view {
        require(msg.value);
        require(arg0 - arg0);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(arg0 == 0, CustomError_abf0f034());
        address var_a = address(msg.sender);
        require(storage_map_a[var_a] == 0, CustomError_abf0f034());
        var_a = address(msg.sender);
        require(0x2710 > (0x2710 + (storage_map_c[var_a])), CustomError_abf0f034());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a])) | !storage_map_a[var_a]), CustomError_abf0f034());
        require(!0x2710, CustomError_abf0f034());
        require(!(0 < rewardTokensLength), CustomError_abf0f034());
        require(!(0 < rewardTokensLength), CustomError_abf0f034());
        var_a = address(storage_map_e[var_a] >> 0);
        require((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) > 0, CustomError_abf0f034());
        require(storage_map_a[var_a] > storage_map_a[var_a], CustomError_abf0f034());
        require(storage_map_a[var_a] - storage_map_a[var_a] > storage_map_a[var_a], CustomError_abf0f034());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) == (storage_map_a[var_a] - storage_map_a[var_a]) | (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710)), CustomError_abf0f034());
        require(!0x0c9f2c9cd04674edea40000000, CustomError_abf0f034());
        var_a = address(storage_map_e[var_a] >> 0);
        require(storage_map_a[var_a] > (storage_map_a[var_a] + ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / 0x0c9f2c9cd04674edea40000000)), CustomError_abf0f034());
    }
    
    /// @custom:selector    0x52a61c2e
    /// @custom:signature   claimUnstakedFrom(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function claimUnstakedFrom(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require(arg0 - arg0);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(arg0 == 0);
        address var_a = address(msg.sender);
        require(0 < storage_map_a[var_a]);
        require(!0 < arg0);
        require(!0 < storage_map_a[var_a]);
        var_a = keccak256(var_a);
        require((block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) > block.timestamp);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) < 0x278d00);
        require(!(storage_map_g[0 + keccak256(var_a)] * (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) / (storage_map_g[0 + keccak256(var_a)]) == (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)])))) | (!storage_map_g[0 + keccak256(var_a)]));
        require(!0x278d00);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!0 < storage_map_a[var_a]);
        require(0 > 0);
        address var_e = address(msg.sender);
        require(((var_h + (uint248(0x1f + ((((var_h + 0x20) + 0x04) + 0x40) - var_h)))) > 0xffffffffffffffff) | ((var_h + (uint248(0x1f + ((((var_h + 0x20) + 0x04) + 0x40) - var_h)))) < var_h));
        (bool success, bytes memory ret0) = address(moto).Unresolved_a9059cbb(var_e); // call
        require(ret0.length - 0, CustomError_5274afe7());
        require(address(moto).code.length == 0, CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        emit Unstaked(address(msg.sender), 0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        require(!(var_a == 0x01), CustomError_5274afe7());
        emit Unstaked(address(msg.sender), 0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
    }
    
    /// @custom:selector    0x79ba5097
    /// @custom:signature   Unresolved_79ba5097() public payable
    function Unresolved_79ba5097() public payable {
        require(msg.value);
        require(address(pendingOwner) - (address(msg.sender)), CustomError_118cdaa7());
        pendingOwner = 0 | (uint96(pendingOwner));
        unresolved_8da5cb5b = (address(msg.sender)) | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), address(msg.sender));
    }
    
    /// @custom:selector    0x7102b728
    /// @custom:signature   vested(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function vested(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        require(storage_map_n[var_a] == 0);
        require(!block.timestamp > (uint64(storage_map_o[var_a] >> 0x08)));
        return 0;
        require((block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) > block.timestamp);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) < (storage_map_p[var_a]));
        require(!(storage_map_n[var_a] * (block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) / (storage_map_n[var_a]) == (block.timestamp - (uint64(storage_map_o[var_a] >> 0x08)))) | (!storage_map_n[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!storage_map_p[var_a]);
        return (storage_map_n[var_a] * (block.timestamp - (uint64(storage_map_o[var_a] >> 0x08)))) / (storage_map_p[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return storage_map_n[var_a];
        return 0;
    }
    
    /// @custom:selector    0x27c19748
    /// @custom:signature   bulkImport(address[] arg0, uint256[] arg1, uint8[] arg2) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function bulkImport(address[] arg0, uint256[] arg1, uint8[] arg2) public pure {
        require(msg.value);
        require(arg0 > 0xffffffffffffffff);
        require(arg0 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xc705d0af
    /// @custom:signature   wasRewardToken(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function wasRewardToken(address arg0) public view returns (bool) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return !(!bytes1(storage_map_a[var_a] >> 0));
    }
    
    /// @custom:selector    0x1459457a
    /// @custom:signature   Unresolved_1459457a(address arg0, address arg1, address arg2, address arg3) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg3 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1459457a(address arg0, address arg1, address arg2, address arg3) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
        require(address(arg1) - arg1);
        require(address(arg2) - arg2);
        require(address(arg3) - arg3);
    }
    
    /// @custom:selector    0xd27f4376
    /// @custom:signature   boostBps(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function boostBps(uint256 arg0) public view returns (uint256) {
        require(msg.value);
        require(arg0 - arg0);
        require(!arg0 < 0x04);
        require(!arg0 < 0x04);
        return (store_q) >> 0;
    }
    
    /// @custom:selector    0x3d509c97
    /// @custom:signature   removeRewardToken(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function removeRewardToken(address arg0) public payable {
        require(msg.value);
        require(address(arg0) - arg0);
        require(address(unresolved_8da5cb5b) - (address(msg.sender)), CustomError_118cdaa7());
        address var_a = address(arg0);
        require(!(bytes1(storage_map_a[var_a])), CustomError_804543b5());
        var_a = address(arg0);
        storage_map_a[var_a] = (bytes1(0)) | (uint248(storage_map_a[var_a]));
        var_a = address(arg0);
        storage_map_a[var_a] = (bytes1(0x01)) | (uint248(storage_map_a[var_a]));
        emit RewardTokenRemoved(address(arg0));
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   Unresolved_715018a6() public payable
    function Unresolved_715018a6() public payable {
        require(msg.value);
        require(address(unresolved_8da5cb5b) - (address(msg.sender)), CustomError_118cdaa7());
        pendingOwner = 0 | (uint96(pendingOwner));
        unresolved_8da5cb5b = 0 | (uint96(unresolved_8da5cb5b));
        emit OwnershipTransferred(address(unresolved_8da5cb5b), 0);
    }
    
    /// @custom:selector    0xdae7a13c
    /// @custom:signature   Unresolved_dae7a13c(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dae7a13c(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x2415500d
    /// @custom:signature   accRewardPerEffShare(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function accRewardPerEffShare(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_a[var_a] >> 0;
    }
    
    /// @custom:selector    0xe3247180
    /// @custom:signature   Unresolved_e3247180(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e3247180(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x14a3d90b
    /// @custom:signature   claimAsMoto(address arg0, uint256 arg1, address[] arg2, uint256 arg3) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    function claimAsMoto(address arg0, uint256 arg1, address[] arg2, uint256 arg3) public payable returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        require(arg1 - arg1);
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(arg3 - arg3);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_a = address(msg.sender);
        require(0x2710 > (0x2710 + (storage_map_c[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a]))) | !storage_map_a[var_a]);
        require(!0x2710);
        require(!0 < rewardTokensLength);
        require(!0 < rewardTokensLength);
        var_a = address(storage_map_e[var_a] >> 0);
        require((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) > 0);
        require(storage_map_a[var_a] > storage_map_a[var_a]);
        require(storage_map_a[var_a] - storage_map_a[var_a] > storage_map_a[var_a]);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) == (storage_map_a[var_a] - storage_map_a[var_a])) | (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710));
        require(!0x0c9f2c9cd04674edea40000000);
        var_a = address(storage_map_e[var_a] >> 0);
        require(storage_map_a[var_a] > (storage_map_a[var_a] + ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / 0x0c9f2c9cd04674edea40000000)));
        var_a = address(arg0);
        require(storage_map_a[var_a] > 0);
        require(storage_map_a[var_a] == 0);
        require(address(arg0) == (address(moto)));
        require(!(arg2) < 0x02);
        require(!0 < (arg2));
        require(address(0 + (0x20 + (arg2))) - (0 + (0x20 + (arg2))));
        require(!(!(address(0 + (0x20 + (arg2)))) == (address(arg0))), CustomError_64325c91());
        require(!(address(0 + (0x20 + (arg2))) == (address(arg0))), CustomError_64325c91());
        var_a = 0x64325c9100000000000000000000000000000000000000000000000000000000;
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_e); // staticcall
        var_e = address(msg.sender);
        (bool success, bytes memory ret0) = address(moto).Unresolved_70a08231(var_e); // staticcall
        address var_g = address(feeRouter);
        require(((var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)))) > 0xffffffffffffffff) | ((var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)))) < var_i));
        uint248 var_i = var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_095ea7b3(var_g); // call
        address var_k = address(feeRouter);
        require(((var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)))) > 0xffffffffffffffff) | ((var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)))) < var_i));
        var_i = var_i + (uint248(0x1f + ((((var_i + 0x20) + 0x04) + 0x40) - var_i)));
        (bool success, bytes memory ret0) = address(arg0).Unresolved_095ea7b3(var_k); // call
        require(ret0.length - 0, CustomError_5274afe7());
        require(address(arg0).code.length == 0, CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        require(!(var_a == 0x01), CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        address var_n = storage_map_a[var_a];
        var_k = arg1;
        require(0 < (arg2));
        require(address(0x20 + (arg2)) - (0x20 + (arg2)));
        (bool success, bytes memory ret0) = address(feeRouter).Unresolved_38ed1739(var_n, var_k); // call
        if (ret0.length - 0) {
            if (!var_a == 0x01) {
            }
            if (0x20 > ret0.length) {
            }
            require(ret0.length - 0, CustomError_64325c91());
        }
        require(!(arg2 < 0x02), CustomError_64325c91());
        require(arg2 < 0x02, CustomError_64325c91());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
    }
    
    /// @custom:selector    0xbc20a7af
    /// @custom:signature   durations(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function durations(uint256 arg0) public view returns (uint256) {
        require(msg.value);
        require(arg0 - arg0);
        require(!arg0 < 0x04);
        require(!arg0 < 0x04);
        return (store_t) >> 0;
    }
    
    /// @custom:selector    0x23095721
    /// @custom:signature   requestUnstake(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function requestUnstake(uint256 arg0) public view {
        require(msg.value);
        require(arg0 - arg0);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(arg0 == 0, CustomError_bb1e8fa7());
        address var_a = address(msg.sender);
        require(storage_map_n[var_a] - (storage_map_u[var_a]) > (storage_map_n[var_a]), CustomError_bb1e8fa7());
        var_a = address(msg.sender);
        require(storage_map_n[var_a] == 0, CustomError_bb1e8fa7());
        require(!(block.timestamp > (uint64(storage_map_o[var_a] >> 0x08))), CustomError_bb1e8fa7());
        require(!(0 > (storage_map_n[var_a] - (storage_map_u[var_a]))), CustomError_bb1e8fa7());
        require(!(0 > (storage_map_v[var_a])), CustomError_bb1e8fa7());
        require(!(0 > (storage_map_u[var_a])), CustomError_bb1e8fa7());
        require(arg0 > (storage_map_u[var_a]), CustomError_bb1e8fa7());
        var_a = address(msg.sender);
        require(0x2710 > (0x2710 + (storage_map_c[var_a])), CustomError_1f2a2005());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a])) | !storage_map_a[var_a]), CustomError_1f2a2005());
        require(!0x2710, CustomError_1f2a2005());
        require(!(0 < rewardTokensLength), CustomError_1f2a2005());
        require(!(0 < rewardTokensLength), CustomError_1f2a2005());
        var_a = address(storage_map_e[var_a] >> 0);
        require((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) > 0, CustomError_1f2a2005());
        require(storage_map_a[var_a] > storage_map_a[var_a], CustomError_1f2a2005());
        require(storage_map_a[var_a] - storage_map_a[var_a] > storage_map_a[var_a], CustomError_1f2a2005());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) == (storage_map_a[var_a] - storage_map_a[var_a]) | (!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710)), CustomError_1f2a2005());
        require(!0x0c9f2c9cd04674edea40000000, CustomError_1f2a2005());
        var_a = address(storage_map_e[var_a] >> 0);
        require(storage_map_a[var_a] > (storage_map_a[var_a] + ((storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / 0x2710) * (storage_map_a[var_a] - storage_map_a[var_a]) / 0x0c9f2c9cd04674edea40000000)), CustomError_1f2a2005());
    }
    
    /// @custom:selector    0x4953c782
    /// @custom:signature   Unresolved_4953c782(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4953c782(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x48ee6395
    /// @custom:signature   setUpgradeAuthority(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setUpgradeAuthority(address arg0) public payable {
        require(msg.value);
        require(address(arg0) - arg0);
        require(bytes1(upgradeAuthority), CustomError_86eb7ce1());
        require(address(upgradeAuthority >> 0x08) - 0, CustomError_ca8f1305());
        require(address(msg.sender) - (address(upgradeAuthority >> 0x08)), CustomError_ca8f1305());
        require(address(arg0) - 0, CustomError_32ae8a82());
        require(address(arg0).code.length == 0, CustomError_32ae8a82());
        upgradeAuthority = (bytes1(0x01 << 0xa8)) | (uint248(upgradeAuthority));
        emit UpgradeAuthoritySet(address(upgradeAuthority >> 0x08), address(arg0));
        upgradeAuthority = (address(arg0 << 0x08)) | (uint96(upgradeAuthority));
        require(bytes1(upgradeAuthority >> 0xa8), CustomError_c7f291ca());
        emit UpgradeAuthoritySet(address(upgradeAuthority >> 0x08), address(arg0));
        upgradeAuthority = (address(arg0 << 0x08)) | (uint96(upgradeAuthority));
    }
    
    /// @custom:selector    0x9ced7e76
    /// @custom:signature   Unresolved_9ced7e76(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9ced7e76(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x4f1ef286
    /// @custom:signature   Unresolved_4f1ef286(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_4f1ef286(address arg0, uint256 arg1) public payable {
        require(address(arg0) - arg0);
        require(arg1 > 0xffffffffffffffff);
        require(arg1 > 0xffffffffffffffff, CustomError_e07c8dba());
        require(((var_c + (uint248(0x1f + ((0x1f + (arg1)) + 0x20)))) > 0xffffffffffffffff) | ((var_c + (uint248(0x1f + ((0x1f + (arg1)) + 0x20)))) < var_c), CustomError_e07c8dba());
        uint256 var_c = var_c + (uint248(0x1f + ((0x1f + (arg1)) + 0x20)));
        require(!(address(this) == 0xb2b1a53d5dc5b5f655d4f4ede4f4517c2a5521f6), CustomError_e07c8dba());
        require(address(this) == 0xb2b1a53d5dc5b5f655d4f4ede4f4517c2a5521f6, CustomError_e07c8dba());
        require(bytes1(upgradeAuthority), CustomError_86eb7ce1());
        require(address(upgradeAuthority >> 0x08) - 0, CustomError_ca8f1305());
        require(address(msg.sender) - (address(upgradeAuthority >> 0x08)), CustomError_ca8f1305());
        (bool success, bytes memory ret0) = address(arg0).Unresolved_52d1902d(var_g); // staticcall
        require(0xc9f76b5ec45e5cdef99837d7b6d2467235c1df8933c8ca56df5c35afa2c7d444, CustomError_4c9c8ce3());
        require(address(arg0).code.length == 0, CustomError_4c9c8ce3());
        store_w = (address(arg0)) | (uint96(store_w));
        emit Upgraded(address(arg0));
        require(!var_c.length > 0);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_h); // delegatecall
        require(!ret0.length);
        require(!var_i > 0);
        require(var_i == 0, CustomError_9996b315());
        require(var_i == 0, CustomError_9996b315());
        require(address(arg0).code.length == 0, CustomError_9996b315());
        require(ret0.length > 0xffffffffffffffff, CustomError_d6bda275());
        require(((var_c + (uint248(0x1f + ((0x1f + ret0.length) + 0x20)))) > 0xffffffffffffffff) | ((var_c + (uint248(0x1f + ((0x1f + ret0.length) + 0x20)))) < var_c), CustomError_d6bda275());
        var_c = var_c + (uint248(0x1f + ((0x1f + ret0.length) + 0x20)));
        require(!(var_c.length > 0), CustomError_d6bda275());
        require(var_c.length == 0, CustomError_9996b315());
        require(address(arg0).code.length == 0, CustomError_9996b315());
        require(msg.value > 0, CustomError_b398979f());
        if (0x20 > ret0.length) {
        }
        require(!(address(store_w) == 0xb2b1a53d5dc5b5f655d4f4ede4f4517c2a5521f6), CustomError_e07c8dba());
    }
    
    /// @custom:selector    0x1d030ac9
    /// @custom:signature   Unresolved_1d030ac9(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_1d030ac9(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0xb9d3933f
    /// @custom:signature   everRewardToken(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function everRewardToken(address arg0) public view returns (bool) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return !(!bytes1(storage_map_a[var_a] >> 0));
    }
    
    /// @custom:selector    0x2e880ace
    /// @custom:signature   setRewardNotifier(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setRewardNotifier(address arg0) public payable {
        require(msg.value);
        require(address(arg0) - arg0);
        require(address(unresolved_8da5cb5b) - (address(msg.sender)), CustomError_118cdaa7());
        require(address(arg0) == 0, CustomError_d92e233d());
        rewardNotifier = (address(arg0)) | (uint96(rewardNotifier));
        emit RewardNotifierSet(address(arg0));
    }
    
    /// @custom:selector    0x4f579a14
    /// @custom:signature   ticketsLength(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function ticketsLength(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(msg.value);
        require(address(arg0) - arg0);
        require(address(unresolved_8da5cb5b) - (address(msg.sender)), CustomError_118cdaa7());
        pendingOwner = (address(arg0)) | (uint96(pendingOwner));
        emit OwnershipTransferStarted(address(unresolved_8da5cb5b), address(arg0));
    }
    
    /// @custom:selector    0x55f57510
    /// @custom:signature   positions(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function positions(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        return abi.encodePacked(storage_map_a[var_a], storage_map_n[var_a], bytes1(storage_map_o[var_a]), uint64(storage_map_o[var_a] >> 0x08), storage_map_c[var_a], storage_map_p[var_a], storage_map_v[var_a]);
    }
    
    /// @custom:selector    0xd276290d
    /// @custom:signature   claimUnstaked() public payable returns (uint256)
    function claimUnstaked() public payable returns (uint256) {
        require(msg.value);
        require(transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_a = address(msg.sender);
        require(0 < storage_map_a[var_a]);
        require(!0 < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        require(0 > 0);
        address var_d = address(msg.sender);
        require(((var_g + (uint248(0x1f + ((((var_g + 0x20) + 0x04) + 0x40) - var_g)))) > 0xffffffffffffffff) | ((var_g + (uint248(0x1f + ((((var_g + 0x20) + 0x04) + 0x40) - var_g)))) < var_g));
        (bool success, bytes memory ret0) = address(moto).Unresolved_a9059cbb(var_d); // call
        require(ret0.length - 0, CustomError_5274afe7());
        require(address(moto).code.length == 0, CustomError_5274afe7());
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        emit Unstaked(address(msg.sender), 0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        require(!(var_a == 0x01), CustomError_5274afe7());
        emit Unstaked(address(msg.sender), 0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        var_a = 0x5274afe700000000000000000000000000000000000000000000000000000000;
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return 0;
        if (!0 < storage_map_a[var_a]) {
            var_a = keccak256(var_a);
            if ((block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) > block.timestamp) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                if (!(block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) < 0x278d00) {
                    if (!(storage_map_g[0 + keccak256(var_a)] * (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)]))) / (storage_map_g[0 + keccak256(var_a)]) == (block.timestamp - (uint64(storage_map_f[0 + keccak256(var_a)])))) | (!storage_map_g[0 + keccak256(var_a)])) {
                        if (!0x278d00) {
                            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                            if (!0 < storage_map_a[var_a]) {
                                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                if (!0 < storage_map_a[var_a]) {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x1c03e6cc
    /// @custom:signature   addRewardToken(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addRewardToken(address arg0) public payable {
        require(msg.value);
        require(address(arg0) - arg0);
        require(address(unresolved_8da5cb5b) - (address(msg.sender)), CustomError_118cdaa7());
        require(address(arg0) == 0, CustomError_35ac0002());
        address var_a = address(arg0);
        require(bytes1(storage_map_a[var_a]), CustomError_35ac0002());
        var_a = address(arg0);
        require(bytes1(storage_map_a[var_a]), CustomError_1da66d0d());
        require(!(rewardTokensLength < 0x20), CustomError_f4512bff());
        var_a = address(arg0);
        storage_map_a[var_a] = (bytes1(0x01)) | (uint248(storage_map_a[var_a]));
        var_a = address(arg0);
        storage_map_a[var_a] = (bytes1(0x01)) | (uint248(storage_map_a[var_a]));
        require(!(rewardTokensLength < 0x010000000000000000), CustomError_d92e233d());
        rewardTokensLength = rewardTokensLength + 0x01;
        require(!(rewardTokensLength < rewardTokensLength), CustomError_d92e233d());
        storage_map_x[rewardTokensLength * 0x01] = (address(arg0 << 0)) | (uint96(storage_map_x[rewardTokensLength * 0x01]));
        emit RewardTokenAdded(address(arg0));
    }
    
    /// @custom:selector    0x170e5fb7
    /// @custom:signature   renounceUpgradeability() public payable
    function renounceUpgradeability() public payable {
        require(msg.value);
        require(bytes1(upgradeAuthority), CustomError_86eb7ce1());
        require(address(upgradeAuthority >> 0x08) - 0, CustomError_ca8f1305());
        require(address(msg.sender) - (address(upgradeAuthority >> 0x08)), CustomError_ca8f1305());
        upgradeAuthority = (bytes1(0x01)) | (uint248(upgradeAuthority));
        emit UpgradesRenounced();
    }
    
    /// @custom:selector    0xd6299d7d
    /// @custom:signature   effectiveStakeOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function effectiveStakeOf(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        require(0x2710 > (0x2710 + (storage_map_c[var_a])));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a])) / storage_map_a[var_a] == (0x2710 + (storage_map_c[var_a]))) | !storage_map_a[var_a]);
        require(!0x2710);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return (storage_map_a[var_a] * (0x2710 + (storage_map_c[var_a]))) / 0x2710;
    }
    
    /// @custom:selector    0x0840ba72
    /// @custom:signature   Unresolved_0840ba72(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_0840ba72(address arg0) public pure {
        require(msg.value);
        require(address(arg0) - arg0);
    }
    
    /// @custom:selector    0x10098ad5
    /// @custom:signature   available(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function available(address arg0) public view returns (uint256) {
        require(msg.value);
        require(address(arg0) - arg0);
        address var_a = address(arg0);
        require(storage_map_n[var_a] - (storage_map_u[var_a]) > (storage_map_n[var_a]));
        var_a = address(arg0);
        require(storage_map_n[var_a] == 0);
        require(!block.timestamp > (uint64(storage_map_o[var_a] >> 0x08)));
        require(!0 > (storage_map_n[var_a] - (storage_map_u[var_a])));
        require(!0 > (storage_map_v[var_a]));
        require(!0 > (storage_map_u[var_a]));
        return storage_map_u[var_a];
        return 0;
        require((block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) > block.timestamp);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) < (storage_map_p[var_a]));
        require(!(storage_map_n[var_a] * (block.timestamp - (uint64(storage_map_o[var_a] >> 0x08))) / (storage_map_n[var_a]) == (block.timestamp - (uint64(storage_map_o[var_a] >> 0x08)))) | (!storage_map_n[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!storage_map_p[var_a]);
    }
    
    /// @custom:selector    0x10087fb1
    /// @custom:signature   Unresolved_10087fb1(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_10087fb1(uint256 arg0) public pure {
        require(msg.value);
        require(arg0 - arg0);
    }
}