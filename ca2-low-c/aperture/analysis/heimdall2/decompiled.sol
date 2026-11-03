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
    uint256 public constant permit2 = 180847076211518657644945212059388835;
    uint256 public constant positionManager = 1115489085710619414828654646022418608911583149704;
    
    bytes32 store_a;
    
    error ZeroLiquidityAmount();
    
    /// @custom:selector    0xd2e24ed5
    /// @custom:signature   Unresolved_d2e24ed5(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4, address arg5, address arg6, uint256 arg7, uint256 arg8) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg12 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    /// @param              arg14 ["uint256", "bytes32", "int256"]
    function Unresolved_d2e24ed5(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4, address arg5, address arg6, uint256 arg7, uint256 arg8) public payable {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0200);
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(arg3 > 0xffffffffffffffff);
        require(arg3 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7c) < 0xa0);
        require(arg9 > 0xffffffffffffffff);
        require(arg9 > 0xffffffffffffffff);
        require(arg10 - arg10);
        require(arg11 - (address(arg11)));
        require(arg12 - (address(arg12)));
        require(arg14 > 0xffffffffffffffff);
        require(arg14 > 0xffffffffffffffff);
        require(((var_a + 0x01e0) > 0xffffffffffffffff) | ((var_a + 0x01e0) < var_a), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0x01e0;
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a), CustomError_3ee5aeb5());
        var_a = var_a + 0xe0;
        require(store_a == 0x02, CustomError_3ee5aeb5());
        store_a = 0x02;
        uint256 var_aa = arg13;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).Unresolved_6352211e(var_aa); // staticcall
        require(0 - msg.sender, CustomError_82b42900());
        require(arg14);
        require(arg14 > 0xffffffffffffffff);
        require(((var_a + (uint248((0x20 + (0x1f + (arg14))) + 0x1f))) > 0xffffffffffffffff) | ((var_a + (uint248((0x20 + (0x1f + (arg14))) + 0x1f))) < var_a));
        var_a = var_a + (uint248((0x20 + (0x1f + (arg14))) + 0x1f));
        uint256 var_ab = msg.data[36:36];
        require(((var_a + var_a.length) - var_a) < 0x80);
        require(var_ad - (bytes1(var_ad)));
        require(!address(0xc36442b4a4522e871399cd717abdd847ab11fe88).code.length);
        uint256 var_ae = address(this);
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).Unresolved_7ac2ff7b(var_ae); // call
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        uint256 var_aw = arg13;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).Unresolved_99fbab88(var_aw); // staticcall
        require(!(address(var_ab) > (address(var_a.length))), CustomError_e9cfaf6a());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_e9cfaf6a());
        if (0x0180 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x6377633a
    /// @custom:signature   Unresolved_6377633a(uint256 arg0, address arg1, uint256 arg2, uint256 arg3, uint256 arg4, uint256 arg5) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint128", "bytes16", "int128"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg8 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    function Unresolved_6377633a(uint256 arg0, address arg1, uint256 arg2, uint256 arg3, uint256 arg4, uint256 arg5) public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x01a0);
        require(arg1 - (address(arg1)));
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9c) < 0xa0);
        require(arg8 - arg8);
        require(arg9 - arg9);
        require(arg10 > 0xffffffffffffffff);
        require(arg10 > 0xffffffffffffffff);
        require(((var_a + 0x0180) < var_a) | ((var_a + 0x0180) > 0xffffffffffffffff), CustomError_3ee5aeb5());
        uint256 var_a = var_a + 0x0180;
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a), CustomError_3ee5aeb5());
        var_a = var_a + 0xe0;
        require(store_a == 0x02, CustomError_3ee5aeb5());
        store_a = 0x02;
        require(!address(arg1));
        require(((var_a + 0xe0) > 0xffffffffffffffff) | ((var_a + 0xe0) < var_a));
        var_a = var_a + 0xe0;
        require(((var_a + 0x60) > 0xffffffffffffffff) | ((var_a + 0x60) < var_a));
        var_a = var_a + 0x60;
        uint256 var_ah = arg0;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).Unresolved_99fbab88(var_ah); // staticcall
        require(!(address(var_ai) > (address(var_a.length))), CustomError_e9cfaf6a());
        require(((var_a + 0x80) > 0xffffffffffffffff) | ((var_a + 0x80) < var_a), CustomError_e9cfaf6a());
        if (0x0180 > ret0.length) {
        }
    }
    
    /// @custom:selector    0x67b34120
    /// @custom:signature   Unresolved_67b34120(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4, address arg5, address arg6, uint256 arg7, uint256 arg8, uint256 arg9) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    /// @param              arg3 ["uint256", "bytes32", "int256"]
    /// @param              arg9 ["uint256", "bytes32", "int256"]
    /// @param              arg10 ["uint256", "bytes32", "int256"]
    /// @param              arg11 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg12 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg13 ["uint256", "bytes32", "int256"]
    /// @param              arg14 ["uint256", "bytes32", "int256"]
    /// @param              arg15 ["uint256", "bytes32", "int256"]
    function Unresolved_67b34120(uint256 arg0, uint256 arg1, uint256 arg2, uint256 arg3, uint256 arg4, address arg5, address arg6, uint256 arg7, uint256 arg8, uint256 arg9) public view {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x0220);
        require(arg2 > 0xffffffffffffffff);
        require(arg2 > 0xffffffffffffffff);
        require(arg3 > 0xffffffffffffffff);
        require(arg3 > 0xffffffffffffffff);
        require((msg.data.length + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7c) < 0xa0);
        require(arg9 > 0xffffffffffffffff);
        require(arg9 > 0xffffffffffffffff);
        require(arg10 - arg10);
        require(arg11 - (address(arg11)));
        require(arg12 - (address(arg12)));
        require(arg13 > 0xffffffffffffffff);
        require(arg13 > 0xffffffffffffffff);
        require(arg14 - 11);
        require(arg15 - 11);
        require(((var_c + 0x01e0) > 0xffffffffffffffff) | ((var_c + 0x01e0) < var_c), CustomError_3ee5aeb5());
        uint256 var_c = var_c + 0x01e0;
        require(((var_c + 0xe0) > 0xffffffffffffffff) | ((var_c + 0xe0) < var_c), CustomError_3ee5aeb5());
        require(store_a == 0x02, CustomError_3ee5aeb5());
    }
}