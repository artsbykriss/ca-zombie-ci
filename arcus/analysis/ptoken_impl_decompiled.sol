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
    uint256 public constant unresolved_93c5afaf = 604800;
    uint256 public constant version = 2;
    uint256 public constant unresolved_8880123a = 3600;
    uint256 public constant accountIndex = 0;
    uint256 public constant unresolved_320a9dad = 3600;
    uint256 public constant unresolved_e56492d7 = 2592000;
    address public constant share = 0xAddress(0x0000000000000000000000000000000000000000);
    uint256 public constant unresolved_0ed1ddbf = 500;
    
    mapping(bytes32 => bytes32) storage_map_ax;
    mapping(bytes32 => bytes32) storage_map_ay;
    uint256 public unresolved_039b1a2c;
    mapping(bytes32 => bytes32) storage_map_am;
    mapping(bytes32 => bytes32) storage_map_al;
    mapping(bytes32 => bytes32) storage_map_ak;
    mapping(bytes32 => bytes32) storage_map_av;
    mapping(bytes32 => bytes32) storage_map_aw;
    bytes32 store_az;
    mapping(bytes32 => bytes32) storage_map_bb;
    bytes32 store_ap;
    bytes32 store_a;
    uint256 public reservedAssets;
    mapping(bytes32 => bytes32) storage_map_i;
    mapping(bytes32 => bytes32) storage_map_b;
    mapping(bytes32 => bytes32) storage_map_an;
    address public bridgeVault;
    uint16 public depositFeeBps;
    bytes32 store_l;
    bytes32 store_s;
    mapping(bytes32 => bytes32) storage_map_e;
    address public assetToken;
    mapping(bytes32 => bytes32) storage_map_n;
    mapping(bytes32 => bytes32) storage_map_ae;
    uint256 public netDeposited;
    mapping(bytes32 => bytes32) storage_map_o;
    uint64 public unresolved_879a9f94;
    mapping(bytes32 => bytes32) storage_map_z;
    address store_ai;
    mapping(bytes32 => bytes32) storage_map_d;
    address public factory;
    mapping(bytes32 => bytes32) storage_map_ah;
    mapping(bytes32 => bytes32) storage_map_ab;
    mapping(bytes32 => bytes32) storage_map_h;
    uint256 public nextRequestId;
    mapping(bytes32 => bytes32) storage_map_ad;
    mapping(bytes32 => bytes32) storage_map_aq;
    uint256 public totalAssets;
    mapping(bytes32 => bytes32) storage_map_as;
    uint256 public nextRedeemRequestId;
    mapping(bytes32 => bytes32) storage_map_aa;
    bytes32 store_aj;
    mapping(bytes32 => bytes32) storage_map_y;
    uint256 store_ao;
    mapping(bytes32 => bytes32) storage_map_at;
    bytes32 store_x;
    mapping(bytes32 => bytes32) storage_map_p;
    mapping(bytes32 => bytes32) storage_map_m;
    bytes32 store_t;
    bool public decimals;
    mapping(bytes32 => bytes32) storage_map_au;
    mapping(bytes32 => bytes32) storage_map_u;
    mapping(bytes32 => bytes32) storage_map_ba;
    mapping(bytes32 => bytes32) storage_map_c;
    
    error NotManager(address, address);
    event OperatorSet(address, address, bool);
    event CancelDepositRequest(address, uint256, address);
    event Deposit(address, address, uint256, uint256);
    event Initialized(uint64);
    event Approval(address, address, uint256);
    event Event_53d13c6c();
    event Event_a62cffd1();
    event DepositFeeUpdated(uint16, uint16);
    event Transfer(address, address, uint256);
    event Event_9fb50361();
    event Event_8b41b705();
    event CancelRedeemRequest(address, uint256, address);
    event Event_8f0c59ba();
    
    /// @custom:selector    0x18160ddd
    /// @custom:signature   totalSupply() public view returns (uint256)
    function totalSupply() public view returns (uint256) {
        return store_a;
    }
    
    /// @custom:selector    0xeaed1d07
    /// @custom:signature   claimableRedeemRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claimableRedeemRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(!(address(storage_map_b[var_a])) == (address(arg1)));
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        var_a = address(arg1);
        return storage_map_c[var_a];
        require(storage_map_d[var_a]);
        var_a = address(arg1);
        return storage_map_c[var_a];
        return 0;
    }
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_94280d62());
        require(address(arg0), CustomError_94280d62());
        address var_a = address(msg.sender);
        var_a = address(arg0);
        storage_map_b[var_a] = arg1;
        require(!0x01, CustomError_94280d62());
        return 0x01;
        emit Approval(address(msg.sender), address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x995ea21a
    /// @custom:signature   claimableDepositRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claimableDepositRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(!(address(storage_map_b[var_a])) == (address(arg1)));
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        var_a = address(arg1);
        return storage_map_b[var_a];
        require(storage_map_e[var_a]);
        var_a = address(arg1);
        return storage_map_b[var_a];
        return 0;
    }
    
    /// @custom:selector    0x558a7297
    /// @custom:signature   Unresolved_558a7297(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_558a7297(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        var_a = address(arg0);
        storage_map_b[var_a] = (uint248(storage_map_b[var_a])) | arg1;
        emit OperatorSet(msg.sender, address(arg0), arg1);
        return 0x01;
    }
    
    /// @custom:selector    0x9479c6c5
    /// @custom:signature   Unresolved_9479c6c5(uint64 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_9479c6c5(uint64 arg0) public view returns (bytes memory) {
        require(arg0 == (uint64(arg0)));
        uint64 var_d = uint64(arg0);
        var_a = 0x40 + var_a;
        require(!(bytes1(storage_map_i[var_d])) > 0x03);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_i[var_d])) > 0x03);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_j < 0x04);
        return abi.encodePacked(var_a.length, var_l);
    }
    
    /// @custom:selector    0x69d77a44
    /// @custom:signature   Unresolved_69d77a44(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_69d77a44(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x7c1b50c4
    /// @custom:signature   pendingCancelRedeemRequest(uint256 arg0, address arg1) public pure returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function pendingCancelRedeemRequest(uint256 arg0, address arg1) public pure returns (bool) {
        require(arg1 == (address(arg1)));
        return 0;
    }
    
    /// @custom:selector    0xe8a3d485
    /// @custom:signature   contractURI() public payable returns (bytes memory)
    function contractURI() public payable returns (bytes memory) {
        (bool success, bytes memory ret0) = address(factory).metadataBaseURI(); // staticcall
        uint256 var_b = var_b + (uint248(ret0.length + 0x1f));
        if (!((var_b + ret0.length) - var_b) < 0x20) {
            if (!var_b.length > 0xffffffffffffffff) {
                if ((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f)) {
                    if (!(var_c) > 0xffffffffffffffff) {
                        require(!((var_b + ret0.length) - var_b) < 0x20);
                        var_b = var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f));
                        require(!var_b.length > 0xffffffffffffffff);
                        require((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f));
                        require(!(var_c) > 0xffffffffffffffff);
                        var_b = var_b + (0x20 + (((0x1f + (store_l >> 0x01)) / 0x20) * 0x20));
                        require(!((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) < var_b) | ((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) > 0xffffffffffffffff));
                        require(!((var_b + var_b.length) + (var_f) + 0x20) > (var_b + ret0.length));
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        var_d = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a04;
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        require(!store_l >> 0x01);
                        var_b = var_b + (0x20 + (uint248(0x1f + (var_b.length * 0x03))));
                        require(0x1f < (store_l >> 0x01));
                        require((0x20 + var_b) + (store_l >> 0x01) > (0x20 + (0x20 + var_b)));
                        require((var_b.length == ((var_b.length * 0x03) / 0x03)) | !0x03);
                        require(!(var_b.length * 0x03) > 0xffffffffffffffff);
                        require(!var_b.length * 0x03);
                        require(bytes1(var_k) < 0x3000000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x3900000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x4100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x5a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x6100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(0x01);
                        require(0x01);
                        require(bytes1(var_k >> 0xfc) < 0x0a);
                        require(!(bytes1(var_k >> 0xfc) + 0x37) > 0xff);
                        require(0x02);
                    }
                    require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                }
                require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
            }
            require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
        }
        var_b = 0x05 + (((0x20 + var_b) + var_b.length) + var_b.length);
        return abi.encodePacked(0x20, var_b.length);
    }
    
    /// @custom:selector    0xd905777e
    /// @custom:signature   maxRedeem(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxRedeem(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0xf15b65b1
    /// @custom:signature   pendingCancelDepositRequest(uint256 arg0, address arg1) public pure returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function pendingCancelDepositRequest(uint256 arg0, address arg1) public pure returns (bool) {
        require(arg1 == (address(arg1)));
        return 0;
    }
    
    /// @custom:selector    0x3c130d90
    /// @custom:signature   tokenURI() public payable returns (bytes memory)
    function tokenURI() public payable returns (bytes memory) {
        (bool success, bytes memory ret0) = address(factory).metadataBaseURI(); // staticcall
        uint256 var_b = var_b + (uint248(ret0.length + 0x1f));
        if (!((var_b + ret0.length) - var_b) < 0x20) {
            if (!var_b.length > 0xffffffffffffffff) {
                if ((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f)) {
                    if (!(var_c) > 0xffffffffffffffff) {
                        require(!((var_b + ret0.length) - var_b) < 0x20);
                        var_b = var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f));
                        require(!var_b.length > 0xffffffffffffffff);
                        require((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f));
                        require(!(var_c) > 0xffffffffffffffff);
                        var_b = var_b + (0x20 + (((0x1f + (store_l >> 0x01)) / 0x20) * 0x20));
                        require(!((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) < var_b) | ((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) > 0xffffffffffffffff));
                        require(!((var_b + var_b.length) + (var_f) + 0x20) > (var_b + ret0.length));
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        var_d = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a04;
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        require(!store_l >> 0x01);
                        var_b = var_b + (0x20 + (uint248(0x1f + (var_b.length * 0x03))));
                        require(0x1f < (store_l >> 0x01));
                        require((0x20 + var_b) + (store_l >> 0x01) > (0x20 + (0x20 + var_b)));
                        require((var_b.length == ((var_b.length * 0x03) / 0x03)) | !0x03);
                        require(!(var_b.length * 0x03) > 0xffffffffffffffff);
                        require(!var_b.length * 0x03);
                        require(bytes1(var_k) < 0x3000000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x3900000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x4100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x5a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x6100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(0x01);
                        require(0x01);
                        require(bytes1(var_k >> 0xfc) < 0x0a);
                        require(!(bytes1(var_k >> 0xfc) + 0x37) > 0xff);
                        require(0x02);
                    }
                    require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                }
                require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
            }
            require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
        }
        var_b = 0x05 + (((0x20 + var_b) + var_b.length) + var_b.length);
        return abi.encodePacked(0x20, var_b.length);
    }
    
    /// @custom:selector    0xd505accf
    /// @custom:signature   Unresolved_d505accf(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_d505accf(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x2b9d9c1f
    /// @custom:signature   cancelRedeemRequest(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function cancelRedeemRequest(uint256 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(arg1) == msg.sender, CustomError_9388c14f());
        var_b = msg.sender;
        require(!(!bytes1(storage_map_m[var_b])), CustomError_9388c14f());
        var_b = arg0;
        require(!(bytes1(storage_map_m[var_b] / 0x010000000000000000000000000000000000000000) > 0x02), CustomError_9388c14f());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_m[var_b] / 0x010000000000000000000000000000000000000000) == 0x01, CustomError_9388c14f());
        require(address(storage_map_m[var_b]) == (address(arg1)), CustomError_9388c14f());
        require(!(block.timestamp < (uint64(storage_map_m[var_b] / 0x01000000000000000000000000000000000000000000))), CustomError_67d6d68d());
        require(!(storage_map_n[var_b] - (storage_map_o[var_b]) > (storage_map_n[var_b])), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_m[var_b] = 0x020000000000000000000000000000000000000000 | (uint248(storage_map_m[var_b]));
        require(!(storage_map_n[var_b] - (storage_map_o[var_b])), CustomError_5cab937e());
        var_b = address(arg1);
        require(!(storage_map_m[var_b] > (storage_map_n[var_b] - (storage_map_o[var_b]) + storage_map_m[var_b])), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_m[var_b] = (storage_map_n[var_b] - (storage_map_o[var_b])) + storage_map_m[var_b];
        emit Event_8b41b705(arg0, address(arg1), (storage_map_n[var_b]) - (storage_map_o[var_b]));
        emit CancelRedeemRequest(address(arg1), arg0, msg.sender);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        emit Event_8b41b705(arg0, address(arg1), (storage_map_n[var_b]) - (storage_map_o[var_b]));
        emit CancelRedeemRequest(address(arg1), arg0, msg.sender);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(0x01 < 0x03, CustomError_5cab937e());
        require(!(!(address(arg1)) == msg.sender), CustomError_5cab937e());
    }
    
    /// @custom:selector    0x0a28a477
    /// @custom:signature   previewWithdraw(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdraw(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0x724958fd
    /// @custom:signature   Unresolved_724958fd(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_724958fd(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_d = address(arg0);
        var_a = 0x40 + var_a;
        return abi.encodePacked(var_a.length, var_k);
    }
    
    /// @custom:selector    0x5a446215
    /// @custom:signature   Unresolved_5a446215(uint256 arg0, uint256 arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_5a446215(uint256 arg0, uint256 arg1) public pure {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!arg1 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x0fe21264
    /// @custom:signature   setDepositFee(uint16 arg0) public payable
    /// @param              arg0 ["uint16", "bytes2", "int16"]
    function setDepositFee(uint16 arg0) public payable {
        require(arg0 == (uint16(arg0)));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(!(uint16(arg0) > 0x01f4), CustomError_3c057d7b());
        depositFeeBps = (uint16(arg0)) | (uint240(depositFeeBps));
        emit DepositFeeUpdated(uint16(depositFeeBps), uint16(arg0));
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(arg0 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        require(0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x2f0a18c500000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
        return !(!0x01ffc9a700000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
    }
    
    /// @custom:selector    0xb460af94
    /// @custom:signature   Unresolved_b460af94(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b460af94(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x85b77f45
    /// @custom:signature   Unresolved_85b77f45(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_85b77f45(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x1626ba7e
    /// @custom:signature   Unresolved_1626ba7e(uint256 arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1626ba7e(uint256 arg0, uint256 arg1) public payable returns (uint256) {
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (address(var_c.length)));
        var_c = var_c + (0x20 + (((0x1f + (arg1)) / 0x20) * 0x20));
        require(0 - (address(var_c.length).code.length));
        require(0x41 - var_c.length);
        require(!(var_g) > 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0);
        require(!0x03 > 0x03);
        require(!0x03 == 0);
        require(!0 == (address(var_c.length)));
        return 0xffffffff00000000000000000000000000000000000000000000000000000000;
        return 0x1626ba7e00000000000000000000000000000000000000000000000000000000;
        require(!0x03 == 0);
        return 0x1626ba7e00000000000000000000000000000000000000000000000000000000;
        return 0xffffffff00000000000000000000000000000000000000000000000000000000;
        require(var_q);
        if (address(var_r)) {
        }
    }
    
    /// @custom:selector    0xcffba3e7
    /// @custom:signature   Unresolved_cffba3e7(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cffba3e7(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xaabb5922
    /// @custom:signature   claimableCancelDepositRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claimableCancelDepositRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        require(!(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000) == 0x02);
        require(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000) == 0x02);
        var_a = address(arg1);
        return storage_map_b[var_a];
        return 0;
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        if (store_l) {
            if (store_l - ((store_l >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_l >> 0x01)) / 0x20) * 0x20));
                if (store_l) {
                    if (store_l - ((store_l >> 0x01) < 0x20)) {
                        if (!store_l >> 0x01) {
                            if (0x1f < (store_l >> 0x01)) {
                                var_a = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a04;
                                if ((0x20 + var_c) + (store_l >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xef8b30f7
    /// @custom:signature   previewDeposit(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDeposit(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0x402d267d
    /// @custom:signature   maxDeposit(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxDeposit(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x359ce775
    /// @custom:signature   Unresolved_359ce775(uint256 arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    function Unresolved_359ce775(uint256 arg0, uint256 arg1, uint256 arg2) public pure {
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(!arg13 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x07a2d13a
    /// @custom:signature   convertToAssets(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToAssets(uint256 arg0) public view returns (uint256) {
        require(!totalAssets > (unresolved_039b1a2c + totalAssets));
        require(!store_a > (store_s + store_a));
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(store_s + store_a);
        require(0 - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((unresolved_039b1a2c + totalAssets) * arg0) - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((unresolved_039b1a2c + totalAssets) * arg0))));
        require((store_s + store_a) > (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((unresolved_039b1a2c + totalAssets) * arg0) - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((unresolved_039b1a2c + totalAssets) * arg0))));
        require(store_s + store_a);
        require(!(((unresolved_039b1a2c + totalAssets) * arg0) / (store_s + store_a)) > (((arg0 * (unresolved_039b1a2c + totalAssets)) % (store_s + store_a) > 0) + (((unresolved_039b1a2c + totalAssets) * arg0) / (store_s + store_a))));
        require(store_t);
        return (((arg0 * (unresolved_039b1a2c + totalAssets)) % (store_s + store_a) > 0) + (((unresolved_039b1a2c + totalAssets) * arg0) / (store_s + store_a))) / store_t;
        require(0 - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((unresolved_039b1a2c + totalAssets) * arg0) - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((unresolved_039b1a2c + totalAssets) * arg0))));
        require((store_s + store_a) > (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((unresolved_039b1a2c + totalAssets) * arg0) - (((arg0 * (unresolved_039b1a2c + totalAssets)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((unresolved_039b1a2c + totalAssets) * arg0))));
        require(store_s + store_a);
    }
    
    /// @custom:selector    0xb9cf0634
    /// @custom:signature   cancelDepositRequest(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function cancelDepositRequest(uint256 arg0, address arg1) public payable {
        require(arg1 == (address(arg1)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(arg1) == msg.sender, CustomError_9388c14f());
        var_b = msg.sender;
        require(!(!bytes1(storage_map_m[var_b])), CustomError_9388c14f());
        var_b = arg0;
        require(!(bytes1(storage_map_m[var_b] / 0x010000000000000000000000000000000000000000) > 0x02), CustomError_9388c14f());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_m[var_b] / 0x010000000000000000000000000000000000000000) == 0x01, CustomError_9388c14f());
        require(address(storage_map_m[var_b]) == (address(arg1)), CustomError_9388c14f());
        require(!(storage_map_n[var_b] - (storage_map_u[var_b]) > (storage_map_n[var_b])), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_m[var_b] = 0x020000000000000000000000000000000000000000 | (uint248(storage_map_m[var_b]));
        require(!(storage_map_n[var_b] - (storage_map_u[var_b])), CustomError_5cab937e());
        require(!((netDeposited - (storage_map_n[var_b] - (storage_map_u[var_b]))) > netDeposited), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        netDeposited = netDeposited - (storage_map_n[var_b] - (storage_map_u[var_b]));
        var_b = address(arg1);
        require(!(storage_map_m[var_b] > (storage_map_n[var_b] - (storage_map_u[var_b]) + storage_map_m[var_b])), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_m[var_b] = (storage_map_n[var_b] - (storage_map_u[var_b])) + storage_map_m[var_b];
        emit Event_53d13c6c(arg0, address(arg1), (storage_map_n[var_b]) - (storage_map_u[var_b]));
        emit CancelDepositRequest(address(arg1), arg0, msg.sender);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        emit Event_53d13c6c(arg0, address(arg1), (storage_map_n[var_b]) - (storage_map_u[var_b]));
        emit CancelDepositRequest(address(arg1), arg0, msg.sender);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(0x01 < 0x03, CustomError_5cab937e());
        require(!(!(address(arg1)) == msg.sender), CustomError_5cab937e());
    }
    
    /// @custom:selector    0x3644e515
    /// @custom:signature   fopwCDKKK() public view
    function fopwCDKKK() public view {
        if (store_x) {
            if (store_x - ((store_x >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_x >> 0x01)) / 0x20) * 0x20));
                if (store_x) {
                    if (store_x - ((store_x >> 0x01) < 0x20)) {
                        if (!store_x >> 0x01) {
                            if (0x1f < (store_x >> 0x01)) {
                                var_a = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a03;
                                if ((0x20 + var_c) + (store_x >> 0x01) > (0x20 + (0x20 + var_c))) {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x0690a09d
    /// @custom:signature   Unresolved_0690a09d(uint64 arg0) public payable
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_0690a09d(uint64 arg0) public payable {
        require(arg0 == (uint64(arg0)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        uint64 var_b = uint64(arg0);
        require(!(bytes1(storage_map_y[var_b])) > 0x03);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_y[var_b]) == 0x01);
        var_b = storage_map_m[var_b];
        address var_e = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_e); // staticcall
        uint256 var_f = var_f + (uint248(ret0.length + 0x1f));
        require(!(((var_f + ret0.length) - var_f) < 0x20), CustomError_5cab937e());
        require(var_f.length == (address(var_f.length)), CustomError_5cab937e());
        require(address(msg.sender) == (address(var_f.length)), CustomError_5cab937e());
        require(address(storage_map_m[var_b]) == msg.sender, CustomError_5cab937e());
        var_b = msg.sender;
        require(!(!bytes1(storage_map_m[var_b])), CustomError_5cab937e());
        storage_map_y[var_b] = 0x03 | (uint248(storage_map_y[var_b]));
        require(!(storage_map_z[var_b] > (storage_map_m[var_b] + (storage_map_z[var_b]))), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_z[var_b] = storage_map_m[var_b] + (storage_map_z[var_b]);
        require(!((netDeposited - storage_map_m[var_b]) > netDeposited), CustomError_5cab937e());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(!(address(storage_map_m[var_b])) == msg.sender), CustomError_5cab937e());
        require(0x01 < 0x04);
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        if (store_x) {
            if (store_x - ((store_x >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_x >> 0x01)) / 0x20) * 0x20));
                if (store_x) {
                    if (store_x - ((store_x >> 0x01) < 0x20)) {
                        if (!store_x >> 0x01) {
                            if (0x1f < (store_x >> 0x01)) {
                                var_a = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a03;
                                if ((0x20 + var_c) + (store_x >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x56478360
    /// @custom:signature   Unresolved_56478360(uint64 arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    /// @param              arg14 ["uint256", "bytes32", "int256"]
    function Unresolved_56478360(uint64 arg0, uint256 arg1, uint256 arg2) public pure {
        require(arg0 == (uint64(arg0)));
        require(!(msg.data.length - 0x24) < 0x0180);
        require(!arg13 > 0xffffffffffffffff);
        require(!(arg13) > 0xffffffffffffffff);
        require(!arg14 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x4c22fd49
    /// @custom:signature   Unresolved_4c22fd49(uint256 arg0, uint64 arg1, uint256 arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint64", "bytes8", "int64"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_4c22fd49(uint256 arg0, uint64 arg1, uint256 arg2) public payable {
        require(arg1 == (uint64(arg1)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(0 - arg2, CustomError_bc90c9f7());
        uint256 var_g = arg0;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) > 0x02), CustomError_bc90c9f7());
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) == 0x01, CustomError_bc90c9f7());
        var_g = uint64(arg1);
        require(!(bytes1(storage_map_ab[var_g]) > 0x03), CustomError_bc90c9f7());
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_ab[var_g]) == 0, CustomError_bc90c9f7());
        (bool success, bytes memory ret0) = address(bridgeVault).bridgeVault(); // staticcall
        var_e = uint64(arg1);
        (bool success, bytes memory ret0) = address(bridgeVault).Unresolved_e9e417a3(var_e); // staticcall
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x80);
        require(!((var_c + 0x80) < var_c) | ((var_c + 0x80) > 0xffffffffffffffff));
        var_c = var_c + 0x80;
        require(var_c.length == (address(var_c.length)));
        require(0x01 < 0x03, CustomError_1f2a2005());
    }
    
    /// @custom:selector    0xe610da0b
    /// @custom:signature   Unresolved_e610da0b(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_e610da0b(uint32 arg0) public payable {
        require(arg0 == (uint32(arg0)));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(uint32(arg0) < 0x0e10, CustomError_70bcf746());
        require(!(uint32(arg0) > 0x278d00), CustomError_70bcf746());
        depositFeeBps = (uint224(depositFeeBps)) | (0x010000000000000000000000000000000000000000000000 * (uint32(arg0)));
        emit Event_8f0c59ba(uint32(depositFeeBps / 0x010000000000000000000000000000000000000000000000), uint32(arg0));
        require(!(uint32(arg0) < 0x0e10), CustomError_70bcf746());
        depositFeeBps = (uint224(depositFeeBps)) | (0x010000000000000000000000000000000000000000000000 * (uint32(arg0)));
        emit Event_8f0c59ba(uint32(depositFeeBps / 0x010000000000000000000000000000000000000000000000), uint32(arg0));
    }
    
    /// @custom:selector    0xac6ac9a0
    /// @custom:signature   Unresolved_ac6ac9a0(uint64 arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    /// @param              arg14 ["uint256", "bytes32", "int256"]
    function Unresolved_ac6ac9a0(uint64 arg0, uint256 arg1, uint256 arg2) public pure {
        require(arg0 == (uint64(arg0)));
        require(!(msg.data.length - 0x24) < 0x0180);
        require(!arg13 > 0xffffffffffffffff);
        require(!(arg13) > 0xffffffffffffffff);
        require(!arg14 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xf17bcffb
    /// @custom:signature   Unresolved_f17bcffb(uint32 arg0) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function Unresolved_f17bcffb(uint32 arg0) public payable {
        require(arg0 == (uint32(arg0)));
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(uint32(arg0) < 0x0e10, CustomError_035b321c());
        require(!(uint32(arg0) > 0x093a80), CustomError_035b321c());
        unresolved_879a9f94 = (uint224(unresolved_879a9f94)) | (0x010000000000000000 * (uint32(arg0)));
        emit Event_a62cffd1(uint32(unresolved_879a9f94 / 0x010000000000000000), uint32(arg0));
        require(!(uint32(arg0) < 0x0e10), CustomError_035b321c());
        unresolved_879a9f94 = (uint224(unresolved_879a9f94)) | (0x010000000000000000 * (uint32(arg0)));
        emit Event_a62cffd1(uint32(unresolved_879a9f94 / 0x010000000000000000), uint32(arg0));
    }
    
    /// @custom:selector    0x23eaf9bb
    /// @custom:signature   Unresolved_23eaf9bb(uint64 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_23eaf9bb(uint64 arg0) public view returns (bytes memory) {
        require(arg0 == (uint64(arg0)));
        uint64 var_d = uint64(arg0);
        var_a = 0x40 + var_a;
        require(!(bytes1(storage_map_i[var_d])) > 0x03);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_i[var_d])) > 0x03);
        var_d = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_j < 0x04);
        return abi.encodePacked(var_a.length, var_l);
    }
    
    /// @custom:selector    0x26c6f96c
    /// @custom:signature   pendingDepositRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function pendingDepositRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        require(!(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000) == 0x01);
        require(!(storage_map_c[var_a] - (storage_map_ad[var_a])) > (storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(storage_map_ad[var_a] - (storage_map_ae[var_a])) > (storage_map_ad[var_a]));
    }
    
    /// @custom:selector    0x4204bef9
    /// @custom:signature   Unresolved_4204bef9(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_4204bef9(uint256 arg0) public payable {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(0 - arg0);
        var_e = address(this);
        (bool success, bytes memory ret0) = address(assetToken).Unresolved_70a08231(var_e); // staticcall
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_1900b024());
        require(!((var_c.length - reservedAssets) > var_c.length), CustomError_1900b024());
        require(!(arg0 > (var_c.length - reservedAssets)), CustomError_1900b024());
        var_g = 0x095ea7b300000000000000000000000000000000000000000000000000000000;
        address var_h = address(bridgeVault);
        uint256 var_k = arg0;
        (bool success, bytes memory ret0) = address(assetToken).Unresolved_095ea7b3(var_h, var_k); // call
        require(success & (var_g == 0x01));
        var_f = address(this);
        (bool success, bytes memory ret0) = address(bridgeVault).Unresolved_43ecb268(var_f); // call
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (uint64(var_c.length)));
        require(!(!success) & (0));
        if (success & ((!ret0.length) & (address(assetToken).code.length > 0))) {
        }
    }
    
    /// @custom:selector    0xb04a5e05
    /// @custom:signature   claimableCancelRedeemRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function claimableCancelRedeemRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(!(address(storage_map_b[var_a])) == (address(arg1)));
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        var_a = address(arg1);
        return storage_map_b[var_a];
        require(!(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000) == 0x02);
        var_a = address(arg1);
        return storage_map_b[var_a];
        return 0;
    }
    
    /// @custom:selector    0x94bf804d
    /// @custom:signature   mint(uint256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function mint(uint256 arg0, address arg1) public payable returns (uint256) {
        require(arg1 == (address(arg1)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender) == msg.sender, CustomError_6565c4ec());
        var_b = msg.sender;
        require(!(!bytes1(storage_map_m[var_b])), CustomError_6565c4ec());
        require(address(arg1), CustomError_6565c4ec());
        require(0 - arg0, CustomError_6565c4ec());
        var_b = address(msg.sender);
        require(!(arg0 > (storage_map_y[var_b])), CustomError_6565c4ec());
        require(!(0x01 > 0x03), CustomError_e450d38c());
        require(0x02, CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == 0x01), CustomError_e450d38c());
        require(0 - (((arg0 * (storage_map_ah[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ah[var_b] * arg0) - (((arg0 * (storage_map_ah[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ah[var_b] * arg0))), CustomError_e450d38c());
        require(storage_map_y[var_b] > (((arg0 * (storage_map_ah[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_ah[var_b] * arg0) - (((arg0 * (storage_map_ah[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_ah[var_b] * arg0))), CustomError_e450d38c());
        var_b = 0x4e487b71;
        require(storage_map_y[var_b], CustomError_e450d38c());
        require(!((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b]) > ((0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b])))), CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!((storage_map_y[var_b] - arg0) > (storage_map_y[var_b])), CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_y[var_b] = (storage_map_y[var_b]) - arg0;
        require(!(storage_map_m[var_b] - ((0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b]))) > storage_map_m[var_b]), CustomError_e450d38c());
        storage_map_m[var_b] = storage_map_m[var_b] - ((0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b])));
        require(address(this), CustomError_e450d38c());
        require(address(arg1), CustomError_e450d38c());
        require(address(this), CustomError_e450d38c());
        var_b = address(this);
        require(!(storage_map_m[var_b] < arg0), CustomError_e450d38c());
        uint256 var_g = arg0;
        var_b = address(this);
        storage_map_m[var_b] = storage_map_m[var_b] - arg0;
        require(address(arg1), CustomError_ec442f05());
        var_b = address(arg1);
        storage_map_m[var_b] = var_g + storage_map_m[var_b];
        emit Transfer(address(this), address(arg1), arg0);
        emit Deposit(address(msg.sender), address(arg1), (0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b])), arg0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return (0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b]));
        store_ai = (store_ai) - arg0;
        emit Transfer(address(this), address(arg1), arg0);
        emit Deposit(address(msg.sender), address(arg1), (0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b])), arg0);
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return (0x01 == 0x01) + ((storage_map_ah[var_b] * arg0) / (storage_map_y[var_b]));
        require(!(store_aj > (arg0 + (store_aj))), CustomError_ec442f05());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(storage_map_y[var_b], CustomError_1f2a2005());
        require(!(!(address(msg.sender)) == msg.sender), CustomError_5cab937e());
    }
    
    /// @custom:selector    0x2e2d2984
    /// @custom:signature   Unresolved_2e2d2984(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2e2d2984(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xb3d7f6b9
    /// @custom:signature   previewMint(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMint(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0xba087652
    /// @custom:signature   Unresolved_ba087652(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_ba087652(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x42cc5a88
    /// @custom:signature   bridgeDeposit(uint256 arg0, uint256 arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function bridgeDeposit(uint256 arg0, uint256 arg1) public payable {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        require(0 - arg1, CustomError_a912d557());
        uint256 var_g = arg0;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) > 0x02), CustomError_a912d557());
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) == 0x01, CustomError_a912d557());
        require(!(uint64(storage_map_ak[var_g]) < block.timestamp), CustomError_a912d557());
        require(!(storage_map_al[var_g] - (storage_map_am[var_g]) > (storage_map_al[var_g])), CustomError_a912d557());
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(arg1 > (storage_map_al[var_g] - (storage_map_am[var_g]))), CustomError_a912d557());
        var_f = arg1;
        require(!(storage_map_am[var_g]) > (arg1 + (storage_map_am[var_g])));
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_am[var_g] = var_f + (storage_map_am[var_g]);
        require(!(reservedAssets - arg1) > reservedAssets);
        reservedAssets = reservedAssets - arg1;
        var_g = 0x095ea7b300000000000000000000000000000000000000000000000000000000;
        address var_i = address(bridgeVault);
        uint256 var_k = arg1;
        (bool success, bytes memory ret0) = address(assetToken).approve(var_i, var_k); // call
        require(success & (var_g == 0x01));
        var_e = address(this);
        (bool success, bytes memory ret0) = address(bridgeVault).Unresolved_43ecb268(var_e); // call
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (uint64(var_c.length)));
        require(!(!success) & (0));
        if (success & ((!ret0.length) & (address(assetToken).code.length > 0))) {
        }
        require(0x01 < 0x03, CustomError_1f2a2005());
    }
    
    /// @custom:selector    0xf5a23d8d
    /// @custom:signature   pendingRedeemRequest(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function pendingRedeemRequest(uint256 arg0, address arg1) public view returns (uint256) {
        require(arg1 == (address(arg1)));
        uint256 var_a = arg0;
        require(address(storage_map_b[var_a]) == (address(arg1)));
        return 0;
        require(!(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_b[var_a] / 0x010000000000000000000000000000000000000000) == 0x01);
        require(!(storage_map_c[var_a] - (storage_map_an[var_a])) > (storage_map_c[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        return (storage_map_c[var_a]) - (storage_map_an[var_a]);
        return 0;
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   transfer(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function transfer(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_e450d38c());
        require(address(arg0), CustomError_e450d38c());
        require(address(msg.sender), CustomError_e450d38c());
        address var_a = address(msg.sender);
        require(!(storage_map_b[var_a] < arg1), CustomError_e450d38c());
        uint256 var_f = arg1;
        var_a = address(msg.sender);
        storage_map_b[var_a] = storage_map_b[var_a] - arg1;
        require(address(arg0), CustomError_ec442f05());
        var_a = address(arg0);
        storage_map_b[var_a] = var_f + storage_map_b[var_a];
        emit Transfer(address(msg.sender), address(arg0), arg1);
        return 0x01;
        store_ao = (store_ao) - arg1;
        emit Transfer(address(msg.sender), address(arg0), arg1);
        return 0x01;
        require(!(store_ap > (arg1 + (store_ap))), CustomError_ec442f05());
    }
    
    /// @custom:selector    0x3d7c1ceb
    /// @custom:signature   Unresolved_3d7c1ceb(uint64 arg0, uint32 arg1) public view returns (bool)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    /// @param              arg1 ["uint32", "bytes4", "int32"]
    function Unresolved_3d7c1ceb(uint64 arg0, uint32 arg1) public view returns (bool) {
        require(arg0 == (uint64(arg0)));
        require(arg1 == (uint32(arg1)));
        var_e = keccak256(var_f);
        return !(!bytes1(storage_map_aq[var_e]));
    }
    
    /// @custom:selector    0x7799c654
    /// @custom:signature   Unresolved_7799c654(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7799c654(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0xe39cba87
    /// @custom:signature   Unresolved_e39cba87(address arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_e39cba87(address arg0, uint256 arg1, uint256 arg2) public pure {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(!arg2 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0xc6e6f592
    /// @custom:signature   convertToShares(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToShares(uint256 arg0) public view returns (uint256) {
        require((store_t == ((store_t * arg0) / arg0)) | !arg0);
        require(!store_a > (store_s + store_a));
        require(!totalAssets > (unresolved_039b1a2c + totalAssets));
        require(!0 > 0x03);
        require(0x02);
        require(!0x01 == 0);
        require(unresolved_039b1a2c + totalAssets);
        require(0 - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((store_s + store_a) * (store_t * arg0)) - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((store_s + store_a) * (store_t * arg0)))));
        require((unresolved_039b1a2c + totalAssets) > (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((store_s + store_a) * (store_t * arg0)) - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((store_s + store_a) * (store_t * arg0)))));
        require(unresolved_039b1a2c + totalAssets);
        require(!((store_s + store_a) * (store_t * arg0) / (unresolved_039b1a2c + totalAssets)) > (((store_t * arg0) * (store_s + store_a) % (unresolved_039b1a2c + totalAssets) > 0) + ((store_s + store_a) * (store_t * arg0) / (unresolved_039b1a2c + totalAssets))));
        return ((store_t * arg0) * (store_s + store_a) % (unresolved_039b1a2c + totalAssets) > 0) + ((store_s + store_a) * (store_t * arg0) / (unresolved_039b1a2c + totalAssets));
        require(0 - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((store_s + store_a) * (store_t * arg0)) - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((store_s + store_a) * (store_t * arg0)))));
        require((unresolved_039b1a2c + totalAssets) > (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((store_s + store_a) * (store_t * arg0)) - (((store_t * arg0) * (store_s + store_a) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((store_s + store_a) * (store_t * arg0)))));
        require(unresolved_039b1a2c + totalAssets);
    }
    
    /// @custom:selector    0x7ecebe00
    /// @custom:signature   nonces(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function nonces(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x8152068c
    /// @custom:signature   Unresolved_8152068c(uint256 arg0, uint256 arg1, uint256 arg2) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg12 ["uint256", "bytes32", "int256"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    function Unresolved_8152068c(uint256 arg0, uint256 arg1, uint256 arg2) public pure {
        require(!arg12 > 0xffffffffffffffff);
        require(!(arg12) > 0xffffffffffffffff);
        require(!arg13 > 0xffffffffffffffff);
    }
    
    /// @custom:selector    0x53131ea1
    /// @custom:signature   rejectDepositRequest(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function rejectDepositRequest(uint256 arg0) public payable {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        uint256 var_g = arg0;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) == 0x01);
        require(!(storage_map_al[var_g] - (storage_map_am[var_g])) > (storage_map_al[var_g]));
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_aa[var_g] = 0x020000000000000000000000000000000000000000 | (uint248(storage_map_aa[var_g]));
        require(!(storage_map_al[var_g]) - (storage_map_am[var_g]));
        require(!(netDeposited - (storage_map_al[var_g] - (storage_map_am[var_g]))) > netDeposited);
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        netDeposited = netDeposited - (storage_map_al[var_g] - (storage_map_am[var_g]));
        var_g = address(storage_map_aa[var_g]);
        require(!storage_map_aa[var_g] > (storage_map_al[var_g] - (storage_map_am[var_g]) + storage_map_aa[var_g]));
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_aa[var_g] = (storage_map_al[var_g] - (storage_map_am[var_g])) + storage_map_aa[var_g];
        emit Event_53d13c6c(arg0, address(storage_map_aa[var_g]), (storage_map_al[var_g]) - (storage_map_am[var_g]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        emit Event_53d13c6c(arg0, address(storage_map_aa[var_g]), (storage_map_al[var_g]) - (storage_map_am[var_g]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(0x01 < 0x03);
    }
    
    /// @custom:selector    0x6e553f65
    /// @custom:signature   deposit(uint256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function deposit(uint256 arg0, address arg1) public payable returns (uint256) {
        require(arg1 == (address(arg1)));
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        require(address(msg.sender) == msg.sender, CustomError_6565c4ec());
        var_b = msg.sender;
        require(!(!bytes1(storage_map_m[var_b])), CustomError_6565c4ec());
        require(address(arg1), CustomError_6565c4ec());
        require(0 - arg0, CustomError_6565c4ec());
        var_b = address(msg.sender);
        require(!(arg0 > storage_map_m[var_b]), CustomError_6565c4ec());
        require(!(0 > 0x03), CustomError_e450d38c());
        require(0x02, CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(0x01 == 0), CustomError_e450d38c());
        require(storage_map_m[var_b], CustomError_e450d38c());
        require(0 - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_n[var_b] * arg0) - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_n[var_b] * arg0))), CustomError_e450d38c());
        require(storage_map_m[var_b] > (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_n[var_b] * arg0) - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_n[var_b] * arg0))), CustomError_e450d38c());
        var_b = 0x4e487b71;
        require(storage_map_m[var_b], CustomError_e450d38c());
        require(!((storage_map_n[var_b] * arg0) / storage_map_m[var_b] > (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]))), CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 - (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b])), CustomError_e450d38c());
        require(!((storage_map_m[var_b] - arg0) > storage_map_m[var_b]), CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_m[var_b] = storage_map_m[var_b] - arg0;
        require(!(storage_map_y[var_b] - (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b])) > (storage_map_y[var_b])), CustomError_e450d38c());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_y[var_b] = (storage_map_y[var_b]) - (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        require(address(this), CustomError_e450d38c());
        require(address(arg1), CustomError_e450d38c());
        require(address(this), CustomError_e450d38c());
        var_b = address(this);
        require(!(storage_map_m[var_b] < (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]))), CustomError_e450d38c());
        var_b = address(this);
        storage_map_m[var_b] = storage_map_m[var_b] - (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        require(address(arg1), CustomError_ec442f05());
        var_b = address(arg1);
        storage_map_m[var_b] = (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b])) + storage_map_m[var_b];
        emit Transfer(address(this), address(arg1), ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        emit Deposit(address(msg.sender), address(arg1), arg0, ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]);
        store_ai = (store_ai) - (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        emit Transfer(address(this), address(arg1), ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        emit Deposit(address(msg.sender), address(arg1), arg0, ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        return ((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]);
        require(!(store_aj > (((arg0 * (storage_map_n[var_b])) % storage_map_m[var_b] > 0) + ((storage_map_n[var_b] * arg0) / storage_map_m[var_b]) + (store_aj))), CustomError_ec442f05());
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(0 - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_n[var_b] * arg0) - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_n[var_b] * arg0))), CustomError_1f2a2005());
        require(storage_map_m[var_b] > (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (storage_map_n[var_b] * arg0) - (((arg0 * (storage_map_n[var_b])) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (storage_map_n[var_b] * arg0))), CustomError_1f2a2005());
        var_b = 0x4e487b71;
        require(storage_map_m[var_b], CustomError_1f2a2005());
        require(!(!(address(msg.sender)) == msg.sender), CustomError_5cab937e());
    }
    
    /// @custom:selector    0xda39b3e7
    /// @custom:signature   Unresolved_da39b3e7(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_da39b3e7(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x1c481e2d
    /// @custom:signature   Unresolved_1c481e2d(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_1c481e2d(uint256 arg0) public payable {
        require(arg0 == arg0);
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        depositFeeBps = (arg0 * 0x0100000000000000000000000000000000000000000000) | (uint248(depositFeeBps));
        emit Event_9fb50361(!(!bytes1(depositFeeBps / 0x0100000000000000000000000000000000000000000000)), arg0);
    }
    
    /// @custom:selector    0x8e9bf9d2
    /// @custom:signature   depositRequest(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function depositRequest(uint256 arg0) public view returns (bytes memory) {
        uint256 var_l = arg0;
        var_a = var_a + 0x0140;
        require(!(bytes1(storage_map_as[var_l] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_l = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_as[var_l] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_l = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_z < 0x03);
        return abi.encodePacked(address(var_a.length), var_ar, uint16(var_as), uint64(var_at), var_au, var_av, uint64(var_aw), var_ax, var_ay, var_az);
    }
    
    /// @custom:selector    0x84b0196e
    /// @custom:signature   eip712Domain() public view
    function eip712Domain() public view {
        if (store_x) {
            if (store_x - ((store_x >> 0x01) < 0x20)) {
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_x >> 0x01)) / 0x20) * 0x20));
                if (store_x) {
                    if (store_x - ((store_x >> 0x01) < 0x20)) {
                        if (!store_x >> 0x01) {
                            if (0x1f < (store_x >> 0x01)) {
                                var_a = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a03;
                                if ((0x20 + var_c) + (store_x >> 0x01) > (0x20 + (0x20 + var_c))) {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x4cdad506
    /// @custom:signature   previewRedeem(uint256 arg0) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeem(uint256 arg0) public pure {
    }
    
    /// @custom:selector    0x6c2eb350
    /// @custom:signature   reinitialize() public payable
    function reinitialize() public payable {
        require(bytes1(store_az / 0x010000000000000000), CustomError_f92ee8a9());
        require(!(bytes1(store_az / 0x010000000000000000)), CustomError_f92ee8a9());
        store_az = 0x010000000000000000 | (0x02 | (uint184(store_az)));
        if (0 - (uint32(depositFeeBps / 0x010000000000000000000000000000000000000000000000))) {
            if (0 - (uint32(unresolved_879a9f94 / 0x010000000000000000))) {
                if (0 - nextRedeemRequestId) {
                    store_az = uint248(store_az);
                    emit Initialized(0x02);
                    nextRedeemRequestId = 0x01;
                    store_az = uint248(store_az);
                    emit Initialized(0x02);
                }
            }
        }
    }
    
    /// @custom:selector    0x67605787
    /// @custom:signature   metaURI() public payable returns (bytes memory)
    function metaURI() public payable returns (bytes memory) {
        (bool success, bytes memory ret0) = address(factory).metadataBaseURI(); // staticcall
        uint256 var_b = var_b + (uint248(ret0.length + 0x1f));
        if (!((var_b + ret0.length) - var_b) < 0x20) {
            if (!var_b.length > 0xffffffffffffffff) {
                if ((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f)) {
                    if (!(var_c) > 0xffffffffffffffff) {
                        require(!((var_b + ret0.length) - var_b) < 0x20);
                        var_b = var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f));
                        require(!var_b.length > 0xffffffffffffffff);
                        require((var_b + ret0.length) > ((var_b + var_b.length) + 0x1f));
                        require(!(var_c) > 0xffffffffffffffff);
                        var_b = var_b + (0x20 + (((0x1f + (store_l >> 0x01)) / 0x20) * 0x20));
                        require(!((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) < var_b) | ((var_b + (uint248((0x20 + (var_f + 0x1f)) + 0x1f))) > 0xffffffffffffffff));
                        require(!((var_b + var_b.length) + (var_f) + 0x20) > (var_b + ret0.length));
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        var_d = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a04;
                        require(bytes1(store_l));
                        require(bytes1(store_l) - ((store_l >> 0x01) < 0x20));
                        require(!store_l >> 0x01);
                        var_b = var_b + (0x20 + (uint248(0x1f + (var_b.length * 0x03))));
                        require(0x1f < (store_l >> 0x01));
                        require((0x20 + var_b) + (store_l >> 0x01) > (0x20 + (0x20 + var_b)));
                        require((var_b.length == ((var_b.length * 0x03) / 0x03)) | !0x03);
                        require(!(var_b.length * 0x03) > 0xffffffffffffffff);
                        require(!var_b.length * 0x03);
                        require(bytes1(var_k) < 0x3000000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x3900000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x4100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x5a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) < 0x6100000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(bytes1(var_k) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(!(bytes1(var_k)) == 0x2d00000000000000000000000000000000000000000000000000000000000000);
                        require(0x01);
                        require(0x01);
                        require(bytes1(var_k >> 0xfc) < 0x0a);
                        require(!(bytes1(var_k >> 0xfc) + 0x37) > 0xff);
                        require(0x02);
                    }
                    require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
                }
                require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
            }
            require(!(bytes1(var_k)) > 0x7a00000000000000000000000000000000000000000000000000000000000000);
        }
        var_b = 0x05 + (((0x20 + var_b) + var_b.length) + var_b.length);
        return abi.encodePacked(0x20, var_b.length);
    }
    
    /// @custom:selector    0x402914f5
    /// @custom:signature   claimable(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function claimable(address arg0) public view returns (bytes memory) {
        require(arg0 == (address(arg0)));
        address var_d = address(arg0);
        var_a = 0x40 + var_a;
        return abi.encodePacked(var_a.length, var_k);
    }
    
    /// @custom:selector    0xc63d75b6
    /// @custom:signature   maxMint(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxMint(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_c[var_a];
    }
    
    /// @custom:selector    0x07542d2e
    /// @custom:signature   Unresolved_07542d2e(uint64 arg0) public view returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_07542d2e(uint64 arg0) public view returns (uint256) {
        require(arg0 == (uint64(arg0)));
        uint64 var_a = uint64(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x7d41c86e
    /// @custom:signature   Unresolved_7d41c86e(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7d41c86e(uint256 arg0, address arg1) public pure {
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0xb6363cf2
    /// @custom:signature   Unresolved_b6363cf2(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_b6363cf2(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xce96cb77
    /// @custom:signature   maxWithdraw(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxWithdraw(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x4a1dc092
    /// @custom:signature   redemption(uint256 arg0) public view returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function redemption(uint256 arg0) public view returns (bytes memory) {
        uint256 var_g = arg0;
        var_a = var_a + 0xa0;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(var_p < 0x03);
        return abi.encodePacked(address(var_a.length), var_x, uint64(var_y), var_z, var_aa);
    }
    
    /// @custom:selector    0x481c6a75
    /// @custom:signature   manager() public payable returns (address)
    function manager() public payable returns (address) {
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (address(var_c.length)));
        return address(var_c.length);
    }
    
    /// @custom:selector    0x748e20ef
    /// @custom:signature   rejectRedeemRequest(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function rejectRedeemRequest(uint256 arg0) public payable {
        require(!transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00], CustomError_3ee5aeb5());
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0x01;
        address var_b = address(this);
        (bool success, bytes memory ret0) = address(factory).Unresolved_7f41826b(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!(((var_c + ret0.length) - var_c) < 0x20), CustomError_6c981570());
        require(var_c.length == (address(var_c.length)), CustomError_6c981570());
        require(address(var_c.length) == msg.sender, CustomError_6c981570());
        uint256 var_g = arg0;
        require(!(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000)) > 0x02);
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        require(bytes1(storage_map_aa[var_g] / 0x010000000000000000000000000000000000000000) == 0x01);
        require(!(storage_map_al[var_g] - (storage_map_bb[var_g])) > (storage_map_al[var_g]));
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_aa[var_g] = 0x020000000000000000000000000000000000000000 | (uint248(storage_map_aa[var_g]));
        require(!(storage_map_al[var_g]) - (storage_map_bb[var_g]));
        var_g = address(storage_map_aa[var_g]);
        require(!storage_map_aa[var_g] > (storage_map_al[var_g] - (storage_map_bb[var_g]) + storage_map_aa[var_g]));
        var_g = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        storage_map_aa[var_g] = (storage_map_al[var_g] - (storage_map_bb[var_g])) + storage_map_aa[var_g];
        emit Event_8b41b705(arg0, address(storage_map_aa[var_g]), (storage_map_al[var_g]) - (storage_map_bb[var_g]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        emit Event_8b41b705(arg0, address(storage_map_aa[var_g]), (storage_map_al[var_g]) - (storage_map_bb[var_g]));
        transient[0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00] = 0;
        require(0x01 < 0x03);
    }
    
    /// @custom:selector    0xd150163b
    /// @custom:signature   Unresolved_d150163b(uint64 arg0) public view returns (uint256)
    /// @param              arg0 ["uint64", "bytes8", "int64"]
    function Unresolved_d150163b(uint64 arg0) public view returns (uint256) {
        require(arg0 == (uint64(arg0)));
        uint64 var_a = uint64(arg0);
        return storage_map_b[var_a];
    }
}