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
    bool public constant unresolved_6b9f9fef = 0xBool(true);
    
    address public unresolved_8da5cb5b;
    address public unresolved_bf7e214f;
    
    error CustomError_00000000();
    event Event_a3396fd7();
    event Event_8be0079c();
    
    /// @custom:selector    0x72faf4a4
    /// @custom:signature   Unresolved_72faf4a4(uint32 arg0, address arg1, address arg2) public payable
    /// @param              arg0 ["uint32", "bytes4", "int32"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg8 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_72faf4a4(uint32 arg0, address arg1, address arg2) public payable {
        require(arg8 == (address(arg8)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        require(!0x20 < 0x20);
        require(arg1 == (address(arg1)));
        require(address(arg1) == msg.sender, CustomError_3279bc30());
        var_e = var_e + 0x0100;
        require(0);
        var_e = var_e + 0x0100;
        require(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        require(!((var_e + 0x0100) < var_e) | ((var_e + 0x0100) > 0xffffffffffffffff));
        require(arg0 == (uint96(arg0)));
        require(arg1 == (address(arg1)));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
    
    /// @custom:selector    0x7a9e5e4b
    /// @custom:signature   Unresolved_7a9e5e4b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7a9e5e4b(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(msg.sender == (address(unresolved_8da5cb5b)));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!((var_e + ret0.length) - var_e) < 0x20);
        require(var_e.length == var_e.length);
        require(var_e.length);
        unresolved_bf7e214f = (address(arg0)) | (uint96(unresolved_bf7e214f));
        emit Event_a3396fd7(msg.sender, address(arg0));
    }
    
    /// @custom:selector    0xbc9961f7
    /// @custom:signature   Unresolved_bc9961f7(uint256 arg0, address arg1) public pure
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_bc9961f7(uint256 arg0, address arg1) public pure {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(arg1 == (address(arg1)));
    }
    
    /// @custom:selector    0x67aa0416
    /// @custom:signature   Unresolved_67aa0416(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_67aa0416(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0xac9650d8
    /// @custom:signature   Unresolved_ac9650d8(uint256 arg0, uint256 arg1) public payable returns (bytes memory)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_ac9650d8(uint256 arg0, uint256 arg1) public payable returns (bytes memory) {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        var_b = var_b + (0x20 + (0x20 * (arg0)));
        require(!arg0);
        require(arg0 - 0x01);
        require(!0 < (arg0));
        require(0 < (arg0));
        require(!((0x20 + (arg0)) + ((0x20 + (arg0)) + 0)) > 0xffffffffffffffff);
        (bool success, bytes memory ret0) = address(this).Unresolved_(var_i); // delegatecall
        require(ret0.length == 0);
        require(!var_j);
        require(var_j, CustomError_9996b315());
        require(var_j, CustomError_9996b315());
        require(0x01, CustomError_9996b315());
        require(!(!address(this).code.length), CustomError_9996b315());
        var_b = var_b + (uint248(ret0.length + 0x3f));
        require(!var_b.length, CustomError_1425ea42());
        require(var_b.length, CustomError_9996b315());
        require(!(!address(this).code.length), CustomError_9996b315());
        return abi.encodePacked(0x20, var_b.length);
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   Unresolved_f2fde38b(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_f2fde38b(address arg0) public payable {
        require(arg0 == (address(arg0)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(msg.sender, address(arg0));
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        unresolved_8da5cb5b = (address(arg0)) | (uint96(unresolved_8da5cb5b));
        emit Event_8be0079c(msg.sender, address(arg0));
    }
    
    /// @custom:selector    0x57376198
    /// @custom:signature   Unresolved_57376198(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_57376198(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        require(arg1 - 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_c = address(this);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_70a08231(var_c); // staticcall
        var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "TRANSFER_FAILED");
        var_d = address(msg.sender);
        (bool success, bytes memory ret0) = address(arg0).Unresolved_a9059cbb(var_d); // call
        require(((var_i == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success), "TRANSFER_FAILED");
        var_c = address(msg.sender);
        var_d = arg1;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_a9059cbb(var_c, var_d); // call
        require(((var_i == 0x01) & (ret0.length > 0x1f) | !ret0.length) & (success), "TRANSFER_FAILED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
        require(!(!address(unresolved_bf7e214f)), "UNAUTHORIZED");
    }
    
    /// @custom:selector    0x5ff8a71f
    /// @custom:signature   Unresolved_5ff8a71f(uint256 arg0, address arg1, uint256 arg2) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_5ff8a71f(uint256 arg0, address arg1, uint256 arg2) public payable {
        require(!arg0 > 0xffffffffffffffff);
        require(!(arg0) > 0xffffffffffffffff);
        require(arg1 == (address(arg1)));
        require(arg2 == arg2);
        require(!address(unresolved_bf7e214f));
        address var_b = address(msg.sender);
        (bool success, bytes memory ret0) = address(unresolved_bf7e214f).Unresolved_b7009613(var_b); // staticcall
        uint256 var_e = var_e + (uint248(ret0.length + 0x1f));
        require(!(((var_e + ret0.length) - var_e) < 0x20), "UNAUTHORIZED");
        require(var_e.length == var_e.length, "UNAUTHORIZED");
        require(var_e.length, "UNAUTHORIZED");
        require(address(unresolved_8da5cb5b) == (address(msg.sender)), "UNAUTHORIZED");
        require(0 < 0x02);
        var_e = (0x20 + var_e) + 0xa0;
        var_p = 0x60;
        require(!0 < (arg0));
        require((arg0 + 0x20) == (uint96(arg0 + 0x20)));
        require(((arg0 + 0x20) + 0x20) == (address((arg0 + 0x20) + 0x20)));
        require(address(0xffdcc73ac9f8f46a8fcb0b648afdf1cb03345e50).code.length);
        (bool success, bytes memory ret0) = address(0xffdcc73ac9f8f46a8fcb0b648afdf1cb03345e50).Unresolved_412638dc(var_p); // call
        require(address(unresolved_bf7e214f));
        require(address(unresolved_bf7e214f));
        require(0 < 0x02);
        require(!0 < (arg0));
        require((arg0 + 0x20) == (uint96(arg0 + 0x20)));
    }
    
    /// @custom:selector    0x8f386608
    /// @custom:signature   Unresolved_8f386608(address arg0) public pure
    /// @param              arg8 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8f386608(address arg0) public pure {
        require(arg8 == (address(arg8)));
    }
}