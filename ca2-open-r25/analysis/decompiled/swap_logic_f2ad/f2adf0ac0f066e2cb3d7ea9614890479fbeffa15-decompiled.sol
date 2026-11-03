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
    uint256 public constant unresolved_54fd4d50 = 1;
    bytes public constant myHash = bce316f0d9d2a3affa97de1d99bb2aac0538e2666d0d8545545ead241ef0ccab;
    bytes public constant contractName = 0xBytes([83, 119, 97, 112]);
    uint256 public constant DEFAULT_ADMIN_ROLE = 0;
    
    address public share;
    uint256 public pendingWithdrawAmount;
    mapping(bytes32 => bytes32) storage_map_q;
    mapping(bytes32 => bytes32) storage_map_a;
    bytes32 store_m;
    bytes public unresolved_28f1d58f;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_s;
    uint256 public withdrawFee;
    bool public unresolved_17321539;
    bytes32 store_c;
    uint256 public conversionRatio;
    mapping(bytes32 => bytes32) storage_map_p;
    uint256 public depositFee;
    uint256 public depositMin;
    address public issuer;
    uint256 public withdrawMin;
    address public getImplementation;
    address public asset;
    mapping(bytes32 => bytes32) storage_map_o;
    
    event Withdraw(address, address, address, uint256, uint256);
    event Event_8d39ef82();
    event Event_ac0e57a5();
    error CustomError_00000000();
    event Event_2ff61d9f();
    event RoleGranted(bytes32, address, address);
    event Event_5db9ee0a();
    event Deposit(address, address, uint256, uint256);
    event Event_408236e9();
    event IssuerSet(address, address);
    event RoleRevoked(bytes32, address, address);
    event Event_62e78cea();
    event Event_922e7695();
    event WithdrawFeeSet(uint256, uint256);
    event Event_0505a228();
    event Event_22e6dd52();
    event DepositFeeSet(uint256, uint256);
    
    /// @custom:selector    0x745ec1f8
    /// @custom:signature   Unresolved_745ec1f8(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_745ec1f8(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - arg0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        unresolved_17321539 = (bytes1(arg0)) | (uint248(unresolved_17321539));
        emit Event_408236e9(arg0);
    }
    
    /// @custom:selector    0x394257cd
    /// @custom:signature   mintByAgent(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function mintByAgent(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(((arg1 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * 0) == (((arg1 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * 0)), CustomError_c7838b0c());
        require(!(conversionRatio > (((arg1 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * 0) - (((arg1 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * 0)))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0x01 < 0x04), CustomError_c7838b0c());
        require(0x01 == 0x01, CustomError_c7838b0c());
        require(((arg1 * 0) / conversionRatio) > (((arg1 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!(((arg1 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!depositFee, CustomError_c7838b0c());
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000, CustomError_c7838b0c());
        require(!(((arg1 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!arg1, CustomError_ed28d089());
        require(!(address(arg0)), CustomError_ed28d089());
        require(depositMin, CustomError_ed28d089());
        require(0 == (bytes1(unresolved_17321539)), CustomError_ed28d089());
        require(arg1 < depositMin, CustomError_ed28d089());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_d = address(arg0);
        address var_e = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_d, var_e); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        var_g = var_g;
        require(!address(share).code.length);
        address var_i = address(arg0);
        (bool success, bytes memory ret0) = address(share).Unresolved_40c10f19(var_i); // call
        emit Deposit(msg.sender, address(arg0), ((arg1 * 0) / conversionRatio) + (0x01 == 0x01), arg1);
        return ((arg1 * 0) / conversionRatio) + (0x01 == 0x01);
        require(((var_g + 0) > 0xffffffffffffffff) | ((var_g + 0) < var_g));
        emit Deposit(msg.sender, address(arg0), ((arg1 * 0) / conversionRatio) + (0x01 == 0x01), arg1);
        return ((arg1 * 0) / conversionRatio) + (0x01 == 0x01);
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        require(!conversionRatio, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(!var_g.length, CustomError_4dfba023());
    }
    
    /// @custom:selector    0x0a28a477
    /// @custom:signature   previewWithdraw(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewWithdraw(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(withdrawFee);
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000);
        var_b = 0x11;
        require(((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0x0de0b6b3a7640000) == (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0x0de0b6b3a7640000)));
        require(!(0x0de0b6b3a7640000 - withdrawFee) > (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0x0de0b6b3a7640000) - (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0x0de0b6b3a7640000))));
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) > ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        require((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)), CustomError_4dfba023());
        require(!(0 > ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)))), CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
        require((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)));
        require(!var_e.length > ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio))));
        require(!var_e.length);
        require(!0x01 < 0x04);
        require(0x01 == 0x01);
        require(!var_e.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x2d15c45e
    /// @custom:signature   Unresolved_2d15c45e(uint256 arg0, uint256 arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_2d15c45e(uint256 arg0, uint256 arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        address var_a = msg.sender;
        require(!bytes1(storage_map_a[var_a]));
        address var_d = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_70a08231(var_d); // staticcall
        var_d = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_dd62ed3e(var_d); // staticcall
        require(0 > 0);
        require(0 > arg1);
        require(store_m < unresolved_28f1d58f);
        require(!arg1);
        require(!0 < arg0);
        require(((var_f + 0xa0) > 0xffffffffffffffff) | ((var_f + 0xa0) < var_f));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_f = var_f + 0xa0;
        require(arg1 < (storage_map_o[var_a]));
        pendingWithdrawAmount = pendingWithdrawAmount;
        store_m = store_m;
        require((pendingWithdrawAmount - (storage_map_o[var_a])) > pendingWithdrawAmount);
        pendingWithdrawAmount = pendingWithdrawAmount;
        store_m = store_m;
        pendingWithdrawAmount = pendingWithdrawAmount;
        store_m = store_m;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xd547741f
    /// @custom:signature   revokeRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function revokeRole(bytes32 arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        storage_map_a[var_a] = uint248(storage_map_a[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
        var_a = 0xe2517d3f00000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xd905777e
    /// @custom:signature   maxRedeem(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxRedeem(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(share).Unresolved_70a08231(var_b); // staticcall
        return 0;
        require(0x20 > ret0.length);
        require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
        uint256 var_c = var_c + 0x20;
        require(((var_c + 0x20) - var_c) < 0x20);
        return var_c.length;
    }
    
    /// @custom:selector    0x91d14854
    /// @custom:signature   hasRole(bytes32 arg0, address arg1) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function hasRole(bytes32 arg0, address arg1) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        var_a = var_a;
        var_a = address(arg1);
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0x2f2ff15d
    /// @custom:signature   grantRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function grantRole(bytes32 arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        var_a = var_a;
        var_a = var_a;
        var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        require(bytes1(storage_map_a[var_a]), CustomError_e2517d3f());
        var_a = var_a;
        var_a = address(arg1);
        storage_map_a[var_a] = 0x01 | (uint248(storage_map_a[var_a]));
        emit RoleGranted(arg0, address(arg1), msg.sender);
        var_a = 0xe2517d3f00000000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x01ffc9a7
    /// @custom:signature   supportsInterface(bytes4 arg0) public pure returns (bool)
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    function supportsInterface(bytes4 arg0) public pure returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (uint32(arg0)));
        require(!(uint32(arg0)) == 0x2f0a18c500000000000000000000000000000000000000000000000000000000);
        return !(!(uint32(arg0)) == 0x2f0a18c500000000000000000000000000000000000000000000000000000000);
        require(!(uint32(arg0)) == 0x7965db0b00000000000000000000000000000000000000000000000000000000);
        return !(!(uint32(arg0)) == 0x7965db0b00000000000000000000000000000000000000000000000000000000);
        return !(!0x01ffc9a700000000000000000000000000000000000000000000000000000000 == (uint32(arg0)));
    }
    
    /// @custom:selector    0xb6ac642a
    /// @custom:signature   setWithdrawFee(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setWithdrawFee(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_7f9c1405());
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_7f9c1405());
        require(!(arg0 < 0x0de0b6b3a7640000), CustomError_7f9c1405());
        withdrawFee = arg0;
        emit WithdrawFeeSet(withdrawFee, arg0);
    }
    
    /// @custom:selector    0xb460af94
    /// @custom:signature   withdraw(uint256 arg0, address arg1, address arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function withdraw(uint256 arg0, address arg1, address arg2) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        require(withdrawFee);
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000);
        var_c = 0x11;
        require(((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0x0de0b6b3a7640000) == (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0x0de0b6b3a7640000)));
        require(!(0x0de0b6b3a7640000 - withdrawFee) > (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0x0de0b6b3a7640000) - (((arg0 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0x0de0b6b3a7640000))));
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) > ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        require((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)), CustomError_4dfba023());
        require(!(0 > ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)))), CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
        require((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)));
        require(!var_e.length > ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg0 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg0 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio))));
        require(!var_e.length);
        require(!0x01 < 0x04);
        require(0x01 == 0x01);
        require(!var_e.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x07a2d13a
    /// @custom:signature   convertToAssets(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToAssets(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) == (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)), CustomError_c7838b0c());
        require(!(conversionRatio > (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) - (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0 < 0x04), CustomError_c7838b0c());
        require(0 == 0x01, CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(((arg0 * 0) / conversionRatio) > (((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_c7838b0c());
        require(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_c7838b0c());
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
    }
    
    /// @custom:selector    0x0f60eafc
    /// @custom:signature   Unresolved_0f60eafc(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_0f60eafc(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - arg0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        unresolved_17321539 = (uint248(unresolved_17321539)) | (bytes1(arg0 << 0x08));
        emit Event_ac0e57a5(!(!bytes1(unresolved_17321539 >> 0x08)), arg0);
    }
    
    /// @custom:selector    0x402d267d
    /// @custom:signature   maxDeposit(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxDeposit(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        (bool success, bytes memory ret0) = address(share).cap(); // staticcall
        require(!0);
        (bool success, bytes memory ret0) = address(share).totalSupply(var_b); // staticcall
        require(!0 > 0);
        require(0 > 0);
        var_d = 0x11;
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(0 == (0 < 0), CustomError_c7838b0c());
        require(!(conversionRatio > (0 - (0 < 0))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0x01 < 0x04), CustomError_c7838b0c());
        require(0x01 == 0x01, CustomError_c7838b0c());
        require((0 / conversionRatio) > ((0 / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!((0 / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!depositFee, CustomError_4dfba023());
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000, CustomError_4dfba023());
        return (0 / conversionRatio) + (0x01 == 0x01);
        require(!conversionRatio, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(!var_f.length, CustomError_4dfba023());
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xef8b30f7
    /// @custom:signature   previewDeposit(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewDeposit(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(depositFee);
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000);
        var_b = 0x11;
        require(((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) == (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))));
        require(!0x0de0b6b3a7640000 > (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee)))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_fc8c8063());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)), CustomError_fc8c8063());
        require(!(0 > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)))), CustomError_fc8c8063());
        require(!0, CustomError_fc8c8063());
        require(!(0 < 0x04), CustomError_fc8c8063());
        require(0 == 0x01, CustomError_fc8c8063());
        require(!0, CustomError_fc8c8063());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_fc8c8063());
        require(!((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_fc8c8063());
        return (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0);
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)));
        require(!var_e.length > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio))));
        require(!var_e.length);
        require(!0 < 0x04);
        require(0 == 0x01);
        require(!var_e.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x36568abe
    /// @custom:signature   renounceRole(bytes32 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function renounceRole(bytes32 arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        require(address(arg1) - msg.sender, CustomError_6697b232());
        var_a = var_a;
        var_a = address(arg1);
        require(!bytes1(storage_map_a[var_a]));
        var_a = var_a;
        var_a = address(arg1);
        storage_map_a[var_a] = uint248(storage_map_a[var_a]);
        emit RoleRevoked(arg0, address(arg1), msg.sender);
    }
    
    /// @custom:selector    0x1b116d0e
    /// @custom:signature   Unresolved_1b116d0e(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1b116d0e(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        require(depositFee);
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000);
        var_c = 0x11;
        require(((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) == (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))));
        require(!0x0de0b6b3a7640000 > (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee)))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_ed28d089());
        require((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)), CustomError_ed28d089());
        require(!(0 > ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)))), CustomError_ed28d089());
        require(!0, CustomError_ed28d089());
        require(!(0 < 0x04), CustomError_ed28d089());
        require(0 == 0x01, CustomError_ed28d089());
        require(!0, CustomError_ed28d089());
        require((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) > ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!arg1, CustomError_ed28d089());
        require(!((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!(address(arg0)), CustomError_ed28d089());
        require(depositMin, CustomError_ed28d089());
        require(0 == (bytes1(unresolved_17321539)), CustomError_ed28d089());
        require((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0) < depositMin, CustomError_ed28d089());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_c = address(arg0);
        address var_e = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_c, var_e); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        var_g = var_g;
        require(!address(share).code.length);
        address var_i = address(arg0);
        (bool success, bytes memory ret0) = address(share).Unresolved_40c10f19(var_i); // call
        emit Deposit(msg.sender, address(arg0), arg1, (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0));
        return (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0);
        require(((var_g + 0) > 0xffffffffffffffff) | ((var_g + 0) < var_g));
        emit Deposit(msg.sender, address(arg0), arg1, (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0));
        return (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0);
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(!var_g.length, CustomError_4dfba023());
        require((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)));
        require(!var_g.length > ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg1 * (0x0de0b6b3a7640000 - depositFee)) - ((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg1 * (0x0de0b6b3a7640000 - depositFee)) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg1 * (0x0de0b6b3a7640000 - depositFee))) - (((arg1 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg1 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio))));
        require(!var_g.length);
        require(!0 < 0x04);
        require(0 == 0x01);
        require(!var_g.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x594d86a9
    /// @custom:signature   Unresolved_594d86a9(uint256 arg0, address arg1) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_594d86a9(uint256 arg0, address arg1) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(((msg.data.length - arg0) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x01a0);
        require(!uint64(store_c));
        require(0x01 == (uint64(store_c)));
        require(uint64(store_c));
        require(address(this).code.length);
        store_c = 0x01 | (uint192(store_c));
        require(!bytes1(store_c >> 0x40));
        require(!bytes1(store_c >> 0x40));
        require(!bytes1(store_c >> 0x40));
        require(!bytes1(store_c >> 0x40));
        require(!bytes1(store_c >> 0x40));
        require(arg0 + (arg0) > 0xffffffffffffffff);
        require(!(arg0) + (arg0));
        require(arg0 + (arg0) > 0xffffffffffffffff);
        require(!0 < (arg0 + (arg0)));
        require(arg0 + (arg0) > 0xffffffffffffffff);
        require(!0 < (arg0 + (arg0)));
        require((0 + (0x20 + (arg0 + (arg0)))) - (address(0 + (0x20 + (arg0 + (arg0))))));
        if (!address(0 + (0x20 + (arg0 + (arg0))))) {
            require(!(address(0 + (0x20 + (arg0 + (arg0))))), CustomError_d92e233d());
        }
        store_c = 0x010000000000000001 | (uint184(store_c));
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(bytes1(store_c >> 0x40)), CustomError_d7e6bcf8());
        require(!(!uint64(store_c)), CustomError_f92ee8a9());
    }
    
    /// @custom:selector    0xac9650d8
    /// @custom:signature   Unresolved_ac9650d8(uint256 arg0, uint256 arg1) public payable returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_ac9650d8(uint256 arg0, uint256 arg1) public payable returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((arg0 + (arg0 << 0x05)) + 0x24) > msg.data.length);
        require(((var_a + 0x20) > 0xffffffffffffffff) | ((var_a + 0x20) < var_a));
        uint256 var_a = var_a + 0x20;
        require(arg0 > 0xffffffffffffffff);
        require(((var_a + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_a));
        var_a = var_a + (uint248((0x20 + (arg0 << 0x05)) + 0x1f));
        require(arg0 > 0xffffffffffffffff);
        require(0 < ((0x20 + (arg0 << 0x05)) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0));
        require(!0 < (arg0));
        require(!(msg.data[(arg0 + 0) + 0x24]) < (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbd + (msg.data.length - arg0)));
        require(msg.data[(arg0 + (msg.data[(arg0 + 0) + 0x24])) + 0x24] > 0xffffffffffffffff);
        require((0x44 + (arg0 + (msg.data[(arg0 + 0) + 0x24]))) > (msg.data.length - (msg.data[(arg0 + (msg.data[(arg0 + 0) + 0x24])) + 0x24])), CustomError_d6bda275());
        require(((var_a + (uint248(((((var_a + (msg.data[(arg0 + (msg.data[(arg0 + 0) + 0x24])) + 0x24])) + var_a.length) + 0x20) - var_a) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248(((((var_a + (msg.data[(arg0 + (msg.data[(arg0 + 0) + 0x24])) + 0x24])) + var_a.length) + 0x20) - var_a) + 0x1f))) < var_a), CustomError_d6bda275());
        (bool success, bytes memory ret0) = address(this).Unresolved_(var_i); // delegatecall
        require(!ret0.length, CustomError_d6bda275());
        var_a = (var_a + ret0.length) + 0x20;
        if (ret0.length) {
        }
        return abi.encodePacked(0x20, var_a.length);
    }
    
    /// @custom:selector    0x94bf804d
    /// @custom:signature   mint(uint256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function mint(uint256 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) == (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)), CustomError_c7838b0c());
        require(!(conversionRatio > (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) - (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0x01 < 0x04), CustomError_c7838b0c());
        require(0x01 == 0x01, CustomError_c7838b0c());
        require(((arg0 * 0) / conversionRatio) > (((arg0 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!(((arg0 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!depositFee, CustomError_c7838b0c());
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000, CustomError_c7838b0c());
        require(!(((arg0 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!arg0, CustomError_ed28d089());
        require(!(address(arg1)), CustomError_ed28d089());
        require(depositMin, CustomError_ed28d089());
        require(0 == (bytes1(unresolved_17321539)), CustomError_ed28d089());
        require(arg0 < depositMin, CustomError_ed28d089());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_d = address(msg.sender);
        address var_e = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_d, var_e); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        var_g = var_g;
        require(!address(share).code.length);
        address var_i = address(arg1);
        (bool success, bytes memory ret0) = address(share).Unresolved_40c10f19(var_i); // call
        emit Deposit(msg.sender, address(arg1), ((arg0 * 0) / conversionRatio) + (0x01 == 0x01), arg0);
        return ((arg0 * 0) / conversionRatio) + (0x01 == 0x01);
        require(((var_g + 0) > 0xffffffffffffffff) | ((var_g + 0) < var_g));
        emit Deposit(msg.sender, address(arg1), ((arg0 * 0) / conversionRatio) + (0x01 == 0x01), arg0);
        return ((arg0 * 0) / conversionRatio) + (0x01 == 0x01);
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        require(!conversionRatio, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(!var_g.length, CustomError_4dfba023());
    }
    
    /// @custom:selector    0xb3d7f6b9
    /// @custom:signature   previewMint(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewMint(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) == (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)), CustomError_c7838b0c());
        require(!(conversionRatio > (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) - (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0x01 < 0x04), CustomError_c7838b0c());
        require(0x01 == 0x01, CustomError_c7838b0c());
        require(((arg0 * 0) / conversionRatio) > (((arg0 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!(((arg0 * 0) / conversionRatio) + (0x01 == 0x01)), CustomError_c7838b0c());
        require(!depositFee, CustomError_4dfba023());
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000, CustomError_4dfba023());
        return ((arg0 * 0) / conversionRatio) + (0x01 == 0x01);
        require(!conversionRatio, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
    }
    
    /// @custom:selector    0xba087652
    /// @custom:signature   redeem(uint256 arg0, address arg1, address arg2) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["address", "uint160", "bytes20", "int160"]
    function redeem(uint256 arg0, address arg1, address arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg1 - (address(arg1)));
        require(arg2 - (address(arg2)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_73949988());
        require(((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) == (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)), CustomError_73949988());
        require(!(conversionRatio > (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) - (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)))), CustomError_73949988());
        require(!conversionRatio, CustomError_73949988());
        require(!(0 < 0x04), CustomError_73949988());
        require(0 == 0x01, CustomError_73949988());
        require(!conversionRatio, CustomError_73949988());
        require(((arg0 * 0) / conversionRatio) > (((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_73949988());
        require(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_73949988());
        require(!withdrawFee, CustomError_73949988());
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000, CustomError_73949988());
        require(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_73949988());
        require(!arg0, CustomError_73949988());
        require(!(address(arg1)), CustomError_73949988());
        require(withdrawMin, CustomError_73949988());
        require(!(bytes1(unresolved_17321539)), CustomError_73949988());
        require(arg0 < withdrawMin, CustomError_73949988());
        require(address(msg.sender) - (address(arg2)), CustomError_8a109193());
        require(!address(share).code.length);
        address var_f = address(arg2);
        (bool success, bytes memory ret0) = address(share).Unresolved_79cc6790(var_f); // call
        require(!bytes1(unresolved_17321539 >> 0x08));
        emit Withdraw(address(msg.sender), address(arg1), address(arg2), ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio), arg0);
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        var_f = address(issuer);
        (bool success, bytes memory ret0) = address(asset).balanceOf(var_f); // staticcall
        var_f = address(issuer);
        var_g = address(this);
        (bool success, bytes memory ret0) = address(asset).Unresolved_dd62ed3e(var_f, var_g); // staticcall
        require(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio) > 0), CustomError_5274afe7());
        require(!(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)) > 0), CustomError_5274afe7());
        require(((var_i + 0xa0) > 0xffffffffffffffff) | ((var_i + 0xa0) < var_i), CustomError_5274afe7());
        uint256 var_i = var_i + 0xa0;
        var_a = unresolved_28f1d58f;
        storage_map_a[var_a] = (address(var_i.length)) | (uint96(storage_map_a[var_a]));
        storage_map_s[var_a] = var_m;
        storage_map_p[var_a] = var_n;
        storage_map_q[var_a] = var_o;
        storage_map_r[var_a] = var_p;
        require(unresolved_28f1d58f > (unresolved_28f1d58f + 0x01), CustomError_5274afe7());
        unresolved_28f1d58f = unresolved_28f1d58f + 0x01;
        require(pendingWithdrawAmount > (pendingWithdrawAmount + (((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio))), CustomError_5274afe7());
        pendingWithdrawAmount = pendingWithdrawAmount + (((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio));
        emit Event_0505a228(address(arg1), address(issuer), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio), unresolved_28f1d58f);
        emit Withdraw(address(msg.sender), address(arg1), address(arg2), ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio), arg0);
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_d = address(issuer);
        address var_e = address(arg1);
        uint256 var_t = ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_d, var_e, var_t); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        emit Withdraw(address(msg.sender), address(arg1), address(arg2), ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio), arg0);
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        require(bytes1(!success));
        var_i = var_i;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        emit Withdraw(address(msg.sender), address(arg1), address(arg2), ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio), arg0);
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        require(0x20 > ret0.length);
        require(((var_i + 0x20) > 0xffffffffffffffff) | ((var_i + 0x20) < var_i));
        var_i = var_i + 0x20;
        require(((var_i + 0x20) - var_i) < 0x20);
        if (!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)) > 0) {
        }
        require(0x20 > ret0.length);
        require(((var_i + 0x20) > 0xffffffffffffffff) | ((var_i + 0x20) < var_i));
        var_i = var_i + 0x20;
        require(((var_i + 0x20) - var_i) < 0x20);
        var_g = address(issuer);
        address var_v = address(this);
        (bool success, bytes memory ret0) = address(asset).allowance(var_g, var_v); // staticcall
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xc3609c29
    /// @custom:signature   Unresolved_c3609c29(uint256 arg0, address arg1, uint256 arg2) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_c3609c29(uint256 arg0, address arg1, uint256 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg1 - (address(arg1)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_73949988());
        require(((arg2 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg2 * 0) == (((arg2 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg2 * 0)), CustomError_73949988());
        require(!(conversionRatio > (((arg2 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg2 * 0) - (((arg2 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg2 * 0)))), CustomError_73949988());
        require(!conversionRatio, CustomError_73949988());
        require(!(0 < 0x04), CustomError_73949988());
        require(0 == 0x01, CustomError_73949988());
        require(!conversionRatio, CustomError_73949988());
        require(((arg2 * 0) / conversionRatio) > (((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio)), CustomError_73949988());
        require(!(((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio)), CustomError_73949988());
        require(!withdrawFee, CustomError_73949988());
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000, CustomError_73949988());
        require(!(((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio)), CustomError_73949988());
        require(!arg2, CustomError_73949988());
        require(!(address(arg1)), CustomError_73949988());
        require(withdrawMin, CustomError_73949988());
        require(!(bytes1(unresolved_17321539)), CustomError_73949988());
        require(arg2 < withdrawMin, CustomError_73949988());
        require(!address(share).code.length);
        address var_f = address(arg1);
        (bool success, bytes memory ret0) = address(share).Unresolved_79cc6790(var_f); // call
        require(!bytes1(unresolved_17321539 >> 0x08));
        emit Withdraw(address(msg.sender), address(arg1), address(arg1), ((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio), arg2);
        require(arg0 + 0x01);
        return ((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio);
        emit Event_8d39ef82(address(arg1), arg0, ((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio), arg2);
        return ((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio);
        var_f = address(issuer);
        (bool success, bytes memory ret0) = address(asset).balanceOf(var_f); // staticcall
        var_f = address(issuer);
        var_g = address(this);
        (bool success, bytes memory ret0) = address(asset).allowance(var_f, var_g); // staticcall
        require(!(((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio) > 0), CustomError_5274afe7());
        require(!(!(((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio)) > 0), CustomError_5274afe7());
        require(((var_j + 0xa0) > 0xffffffffffffffff) | ((var_j + 0xa0) < var_j), CustomError_5274afe7());
        uint256 var_j = var_j + 0xa0;
        var_a = unresolved_28f1d58f;
        storage_map_a[var_a] = (address(var_j.length)) | (uint96(storage_map_a[var_a]));
        storage_map_s[var_a] = var_m;
        storage_map_p[var_a] = var_n;
        storage_map_q[var_a] = var_o;
        storage_map_r[var_a] = var_p;
        require(unresolved_28f1d58f > (unresolved_28f1d58f + 0x01), CustomError_5274afe7());
        unresolved_28f1d58f = unresolved_28f1d58f + 0x01;
        require(pendingWithdrawAmount > (pendingWithdrawAmount + (((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio))), CustomError_5274afe7());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_d = address(issuer);
        address var_e = address(arg1);
        uint256 var_q = ((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_d, var_e, var_q); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        require(bytes1(!success));
        var_j = var_j;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        require(0x20 > ret0.length);
        require(((var_j + 0x20) > 0xffffffffffffffff) | ((var_j + 0x20) < var_j));
        var_j = var_j + 0x20;
        require(((var_j + 0x20) - var_j) < 0x20);
        if (!(((arg2 * 0) / conversionRatio) + ((arg2 * 0) % conversionRatio)) > 0) {
        }
        require(0x20 > ret0.length);
        require(((var_j + 0x20) > 0xffffffffffffffff) | ((var_j + 0x20) < var_j));
        var_j = var_j + 0x20;
        require(((var_j + 0x20) - var_j) < 0x20);
        var_g = address(issuer);
        address var_s = address(this);
        (bool success, bytes memory ret0) = address(asset).allowance(var_g, var_s); // staticcall
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x7e48e7a5
    /// @custom:signature   Unresolved_7e48e7a5(uint256 arg0, address arg1, uint256 arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_7e48e7a5(uint256 arg0, address arg1, uint256 arg2) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg1 - (address(arg1)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        require(withdrawFee);
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000);
        var_c = 0x11;
        require(((arg2 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg2 * 0x0de0b6b3a7640000) == (((arg2 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg2 * 0x0de0b6b3a7640000)));
        require(!(0x0de0b6b3a7640000 - withdrawFee) > (((arg2 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg2 * 0x0de0b6b3a7640000) - (((arg2 * 0x0de0b6b3a7640000) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg2 * 0x0de0b6b3a7640000))));
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require(!0x0de0b6b3a7640000 - withdrawFee);
        require((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) > ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        require((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)), CustomError_4dfba023());
        require(!(0 > ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)))), CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(!(0x01 < 0x04), CustomError_4dfba023());
        require(0x01 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
        require((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) == ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio)));
        require(!var_e.length > ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) - ((((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((arg2 * 0x0de0b6b3a7640000) / (0x0de0b6b3a7640000 - withdrawFee) + ((arg2 * 0x0de0b6b3a7640000) % (0x0de0b6b3a7640000 - withdrawFee)) * conversionRatio))));
        require(!var_e.length);
        require(!0x01 < 0x04);
        require(0x01 == 0x01);
        require(!var_e.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0xc6e6f592
    /// @custom:signature   convertToShares(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function convertToShares(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_fc8c8063());
        require(((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) == (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)), CustomError_fc8c8063());
        require(!(0 > (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)))), CustomError_fc8c8063());
        require(!(0 < 0x04), CustomError_fc8c8063());
        require(0 == 0x01, CustomError_fc8c8063());
        require(!0, CustomError_fc8c8063());
        require((((arg0 * conversionRatio) - ((arg0 * conversionRatio) % 0) / 0) | (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)) - (((arg0 * conversionRatio) % 0) > (arg0 * conversionRatio)) * 0x01) * 0x80) > ((((arg0 * conversionRatio) - ((arg0 * conversionRatio) % 0) / 0) | (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)) - (((arg0 * conversionRatio) % 0) > (arg0 * conversionRatio)) * 0x01) * 0x80) + ((arg0 * conversionRatio) % 0)), CustomError_fc8c8063());
        require(!((((arg0 * conversionRatio) - ((arg0 * conversionRatio) % 0) / 0) | (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)) - (((arg0 * conversionRatio) % 0) > (arg0 * conversionRatio)) * 0x01) * 0x80) + ((arg0 * conversionRatio) % 0)), CustomError_fc8c8063());
        return (((arg0 * conversionRatio) - ((arg0 * conversionRatio) % 0) / 0) | (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)) - (((arg0 * conversionRatio) % 0) > (arg0 * conversionRatio)) * 0x01) * 0x80) + ((arg0 * conversionRatio) % 0);
        require(!0, CustomError_4dfba023());
        require(!(0 < 0x04), CustomError_4dfba023());
        require(0 == 0x01, CustomError_4dfba023());
        require(!0, CustomError_4dfba023());
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
        require(((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) == (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio)));
        require(!var_e.length > (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * conversionRatio) - (((arg0 * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * conversionRatio))));
        require(!var_e.length);
        require(!0 < 0x04);
        require(0 == 0x01);
        require(!var_e.length);
    }
    
    /// @custom:selector    0x3f4ba83a
    /// @custom:signature   Unresolved_3f4ba83a() public payable
    function Unresolved_3f4ba83a() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_8dfc202b());
        require(!(bytes1(store_c)), CustomError_8dfc202b());
        require(!(bytes1(store_c)), CustomError_8dfc202b());
        store_c = uint248(store_c);
        emit Event_5db9ee0a(msg.sender);
    }
    
    /// @custom:selector    0x248a9ca3
    /// @custom:signature   getRoleAdmin(bytes32 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getRoleAdmin(bytes32 arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        var_a = var_a;
        return storage_map_o[var_a];
    }
    
    /// @custom:selector    0x490ae210
    /// @custom:signature   setDepositFee(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setDepositFee(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_8327d836());
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_8327d836());
        require(!(arg0 < 0x0de0b6b3a7640000), CustomError_8327d836());
        depositFee = arg0;
        emit DepositFeeSet(depositFee, arg0);
    }
    
    /// @custom:selector    0x6e553f65
    /// @custom:signature   deposit(uint256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function deposit(uint256 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg1 - (address(arg1)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        require(depositFee);
        require((0x0de0b6b3a7640000 - depositFee) > 0x0de0b6b3a7640000);
        var_c = 0x11;
        require(((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) == (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))));
        require(!0x0de0b6b3a7640000 > (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee)))));
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_ed28d089());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)), CustomError_ed28d089());
        require(!(0 > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)))), CustomError_ed28d089());
        require(!0, CustomError_ed28d089());
        require(!(0 < 0x04), CustomError_ed28d089());
        require(0 == 0x01, CustomError_ed28d089());
        require(!0, CustomError_ed28d089());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!arg0, CustomError_ed28d089());
        require(!((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0)), CustomError_ed28d089());
        require(!(address(arg1)), CustomError_ed28d089());
        require(depositMin, CustomError_ed28d089());
        require(0 == (bytes1(unresolved_17321539)), CustomError_ed28d089());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0) < depositMin, CustomError_ed28d089());
        var_a = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
        var_c = address(msg.sender);
        address var_e = address(issuer);
        (bool success, bytes memory ret0) = address(asset).Unresolved_23b872dd(var_c, var_e); // call
        require(!(success & (var_a == 0x01)), CustomError_5274afe7());
        var_g = var_g;
        require(!address(share).code.length);
        address var_i = address(arg1);
        (bool success, bytes memory ret0) = address(share).Unresolved_40c10f19(var_i); // call
        emit Deposit(msg.sender, address(arg1), arg0, (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0));
        return (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0);
        require(((var_g + 0) > 0xffffffffffffffff) | ((var_g + 0) < var_g));
        emit Deposit(msg.sender, address(arg1), arg0, (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0));
        return (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) / 0) + (((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0);
        require(bytes1(!success));
        var_g = var_g;
        require(!((!ret0.length) & (address(asset).code.length) & (success)), CustomError_5274afe7());
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(!var_g.length, CustomError_4dfba023());
        require((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) == ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio)));
        require(!var_g.length > ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) - ((((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < ((((arg0 * (0x0de0b6b3a7640000 - depositFee)) - ((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) / 0x040000) | (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * (0x0de0b6b3a7640000 - depositFee)) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * (0x0de0b6b3a7640000 - depositFee))) - (((arg0 * (0x0de0b6b3a7640000 - depositFee)) % 0x0de0b6b3a7640000) > (arg0 * (0x0de0b6b3a7640000 - depositFee))) * 0x400000000000000000000000000000000000000000000000000000000000) * 0xaccb18165bd6fe31ae1cf318dc5b51eee0e1ba569b88cd74c1773b91fac10669) * conversionRatio))));
        require(!var_g.length);
        require(!0 < 0x04);
        require(0 == 0x01);
        require(!var_g.length);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x4cdad506
    /// @custom:signature   previewRedeem(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function previewRedeem(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) == (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)), CustomError_c7838b0c());
        require(!(conversionRatio > (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (arg0 * 0) - (((arg0 * 0) % 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < (arg0 * 0)))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0 < 0x04), CustomError_c7838b0c());
        require(0 == 0x01, CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(((arg0 * 0) / conversionRatio) > (((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_c7838b0c());
        require(!(((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio)), CustomError_c7838b0c());
        require(!withdrawFee, CustomError_c7838b0c());
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000, CustomError_c7838b0c());
        return ((arg0 * 0) / conversionRatio) + ((arg0 * 0) % conversionRatio);
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(!var_e.length, CustomError_4dfba023());
    }
    
    /// @custom:selector    0x951d4eca
    /// @custom:signature   Unresolved_951d4eca() public payable
    function Unresolved_951d4eca() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_f6fc7daa());
        require(!(store_m < unresolved_28f1d58f), CustomError_f6fc7daa());
        require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c), CustomError_f6fc7daa());
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        uint256 var_c = var_c + 0xa0;
        var_a = store_m;
        storage_map_a[var_a] = 0;
        storage_map_o[var_a] = 0;
        storage_map_p[var_a] = 0;
        storage_map_q[var_a] = 0;
        storage_map_r[var_a] = 0;
        store_m = store_m + 0x01;
        require((pendingWithdrawAmount - (var_j)) > pendingWithdrawAmount, CustomError_f6fc7daa());
        pendingWithdrawAmount = pendingWithdrawAmount - (var_j);
        emit Event_22e6dd52(store_m + 0x01, address(var_c.length), address(issuer), var_n, var_o);
    }
    
    /// @custom:selector    0x9343ed32
    /// @custom:signature   setDepositMin(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setDepositMin(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_e2517d3f());
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        depositMin = arg0;
        emit Event_922e7695(depositMin, arg0);
    }
    
    /// @custom:selector    0x5c975abb
    /// @custom:signature   Unresolved_5c975abb() public view returns (bool)
    function Unresolved_5c975abb() public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        return !(!bytes1(store_c));
    }
    
    /// @custom:selector    0x68da153c
    /// @custom:signature   getPendingWithdraw(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getPendingWithdraw(uint256 arg0) public view {
        require(msg.value);
        if ((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20) {
            require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
            uint256 var_c = var_c + 0xa0;
            require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
            require(store_m > (store_m + arg0));
        }
    }
    
    /// @custom:selector    0xc63d75b6
    /// @custom:signature   maxMint(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxMint(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        (bool success, bytes memory ret0) = address(share).cap(); // staticcall
        require(!0);
        (bool success, bytes memory ret0) = address(share).totalSupply(var_b); // staticcall
        require(!0 > 0);
        require(0 > 0);
        return 0;
        return 0;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        return 0;
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x55cc4e57
    /// @custom:signature   setIssuer(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function setIssuer(address arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d92e233d());
        require(!(address(arg0)), CustomError_d92e233d());
        issuer = (address(arg0)) | (uint96(issuer));
        emit IssuerSet(address(issuer), address(arg0));
    }
    
    /// @custom:selector    0x581c9f24
    /// @custom:signature   setWithdrawMin(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function setWithdrawMin(uint256 arg0) public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, CustomError_e2517d3f());
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_e2517d3f());
        withdrawMin = arg0;
        emit Event_2ff61d9f(withdrawMin, arg0);
    }
    
    /// @custom:selector    0xce96cb77
    /// @custom:signature   maxWithdraw(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function maxWithdraw(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_b = address(arg0);
        (bool success, bytes memory ret0) = address(share).Unresolved_70a08231(var_b); // staticcall
        (bool success, bytes memory ret0) = address(share).getPrice(); // staticcall
        require(!0, CustomError_c7838b0c());
        require(0 == (0 < 0), CustomError_c7838b0c());
        require(!(conversionRatio > (0 - (0 < 0))), CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require(!(0 < 0x04), CustomError_c7838b0c());
        require(0 == 0x01, CustomError_c7838b0c());
        require(!conversionRatio, CustomError_c7838b0c());
        require((0 / conversionRatio) > ((0 / conversionRatio) + 0), CustomError_c7838b0c());
        require(!((0 / conversionRatio) + 0), CustomError_c7838b0c());
        require(!withdrawFee, CustomError_c7838b0c());
        require((0x0de0b6b3a7640000 - withdrawFee) > 0x0de0b6b3a7640000, CustomError_c7838b0c());
        return (0 / conversionRatio) + 0;
        require(0x20 > ret0.length);
        require(((var_f + 0x20) > 0xffffffffffffffff) | ((var_f + 0x20) < var_f));
        uint256 var_f = var_f + 0x20;
        require(((var_f + 0x20) - var_f) < 0x20);
        require(!var_f.length, CustomError_4dfba023());
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x8456cb59
    /// @custom:signature   Unresolved_8456cb59() public payable
    function Unresolved_8456cb59() public payable {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0);
        address var_a = msg.sender;
        require(!(bytes1(storage_map_a[var_a])), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        require(bytes1(store_c), CustomError_d93c0665());
        store_c = (uint248(store_c)) | 0x01;
        emit Event_62e78cea(msg.sender);
    }
}