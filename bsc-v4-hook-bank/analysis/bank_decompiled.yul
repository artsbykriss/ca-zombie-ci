/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.9.2
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid yul code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

object "DecompiledContract" {
    object "runtime" {
        code {
            
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
            
            function castToAddress(x) -> a {
                a := and(x, 0xffffffffffffffffffffffffffffffffffffffff)
            }
            
            switch selector()
            
            /*
            * @custom:signature    Unresolved_67f7a98a(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x67f7a98a {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_f35ca728(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xf35ca728 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_d1e57635(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xd1e57635 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    PCS_V4_VAULT() public pure returns (uint256)
            */
            case 0xd330ca5e {
                if iszero(callvalue()) { revert(0, 0); } else {
                    mstore(0x80, 0x238a358808379702088667322f80ac48bad5e6c4)
                    return(mload(0x40), sub(add(0x20, mload(0x40)), mload(0x40)))
                }
            }
            
            /*
            * @custom:signature    Unresolved_444fe41b(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x444fe41b {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_483bd75e(uint256 arg0, address arg1) public pure
            * @param                arg6 ["uint256", "bytes32", "int256"]
            * @param                arg7 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x483bd75e {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x01a0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            if eq(calldataload(0xe4), and(calldataload(0xe4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    BANK_ADDRESS() public pure returns (uint256)
            */
            case 0x0a5f7886 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    mstore(0x80, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                    return(mload(0x40), sub(add(0x20, mload(0x40)), mload(0x40)))
                }
            }
            
            /*
            * @custom:signature    Unresolved_81e90bf2(address arg0, address arg1) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg5 ["address", "uint128", "bytes16", "int128"]
            */
            case 0x81e90bf2 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xa0)) {
                            mstore(0x40, add(0x80, mload(0x40)))
                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) {
                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x04, 0x41)
                                        mstore(0x40, add(mload(0x40), 0xa0))
                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_8eb1172f(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x8eb1172f {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_91dd7346(uint256 arg0, uint256 arg1, address arg2) public pure
            * @param                arg0 ["uint256", "bytes32", "int256"]
            * @param                arg1 ["uint256", "bytes32", "int256"]
            * @param                arg2 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x91dd7346 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x20)) {
                        if iszero(gt(calldataload(0x04), 0xffffffffffffffff)) { revert(0, 0); } else {
                            if slt(add(add(0x04, calldataload(0x04)), 0x1f), calldatasize()) {
                                if iszero(gt(calldataload(add(0x04, calldataload(0x04))), 0xffffffffffffffff)) { revert(0, 0); } else {
                                    if iszero(gt(add(add(add(0x04, calldataload(0x04)), calldataload(add(0x04, calldataload(0x04)))), 0x20), calldatasize())) {
                                        if iszero(slt(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(0x04, calldataload(0x04)), 0x20)), 0x0120)) {
                                            if iszero(slt(add(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(0x04, calldataload(0x04)), 0x20)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0), 0x0100)) {
                                                if iszero(or(lt(add(mload(0x40), 0x80), mload(0x40)), gt(add(mload(0x40), 0x80), 0xffffffffffffffff))) {
                                                    mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                    mstore(0x04, 0x41)
                                                    mstore(0x40, add(mload(0x40), 0x80))
                                                    if iszero(slt(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), 0xa0)) {
                                                        if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) {
                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x04, 0x41)
                                                            mstore(0x40, add(mload(0x40), 0xa0))
                                                            if eq(calldataload(add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), and(calldataload(add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
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
            
            /*
            * @custom:signature    Unresolved_fa461e33(uint256 arg0, uint256 arg1, uint256 arg2) public
            * @param                arg0 ["uint256", "bytes32", "int256"]
            * @param                arg1 ["uint256", "bytes32", "int256"]
            * @param                arg2 ["uint256", "bytes32", "int256"]
            */
            case 0xfa461e33 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if iszero(gt(calldataload(0x44), 0xffffffffffffffff)) { revert(0, 0); } else {
                            if slt(add(add(0x04, calldataload(0x44)), 0x1f), calldatasize()) {
                                if iszero(gt(calldataload(add(0x04, calldataload(0x44))), 0xffffffffffffffff)) { revert(0, 0); } else {
                                    if iszero(gt(add(add(add(0x04, calldataload(0x44)), calldataload(add(0x04, calldataload(0x44)))), 0x20), calldatasize())) {
                                        if eq(and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff), caller()) { revert(mload(0x40), sub(add(0x04, mload(0x40)), mload(0x40))); } else {
                                            mstore(0x80, 0x4b60273500000000000000000000000000000000000000000000000000000000)
                                            if iszero(sgt(calldataload(0x04), 0)) {
                                                mstore(0x80, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                                                mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                                mstore(0xa4, and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff))
                                                mstore(0xc4, calldataload(0x04))
                                                call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)
                                                if and(or(and(eq(mload(0), 0x01), gt(returndatasize(), 0x1f)), iszero(returndatasize())), call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)) { revert(mload(0x40), sub(add(0x04, mload(0x40)), mload(0x40))); } else {
                                                    mstore(0x80, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                                                    if iszero(sgt(calldataload(0x24), 0)) {
                                                        mstore(0x80, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                                                        mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                                        mstore(0xa4, and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff))
                                                        mstore(0xc4, calldataload(0x24))
                                                        call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)
                                                        if and(or(and(eq(mload(0), 0x01), gt(returndatasize(), 0x1f)), iszero(returndatasize())), call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)) { revert(0, 0); } else {
                                                            mstore(0x80, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x80, 0xa62a6d4200000000000000000000000000000000000000000000000000000000)
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
            
            /*
            * @custom:signature    Unresolved_a0965c16(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xa0965c16 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_43308267(address arg0, uint256 arg1, address arg2) public
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg5 ["uint256", "bytes32", "int256"]
            * @param                arg6 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x43308267 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xe0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xa0)) {
                            if eq(calldataload(0xc4), and(calldataload(0xc4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                if iszero(slt(0x20, 0x20)) { revert(0, 0); } else {
                                    if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        mstore(0x80, 0x70a0823100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                        staticcall(gas(), and(0xffffffffffffffffffffffffffffffffffffffff, calldataload(0x04)), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20)
                                        if iszero(iszero(staticcall(gas(), and(0xffffffffffffffffffffffffffffffffffffffff, calldataload(0x04)), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20))) { revert(0, returndatasize()); } else {
                                            returndatacopy(0, 0, returndatasize())
                                            mstore(0x40, add(mload(0x40), and(add(returndatasize(), 0x1f), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0)))
                                            if iszero(slt(sub(add(mload(0x40), returndatasize()), mload(0x40)), 0x20)) {
                                                if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                    mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                    mstore(0x04, 0x11)
                                                    if lt(calldataload(0xa4), sub(mload(mload(0x40)), 0x01)) {
                                                        if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x04, 0x11)
                                                            mstore(0x40, add(0x80, mload(0x40)))
                                                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) {
                                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                        mstore(0x04, 0x41)
                                                                        mstore(0x40, add(mload(0x40), 0xa0))
                                                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                                                            mstore(0x40, add(0x80, mload(0x40)))
                                                                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) { revert(0, 0); } else {
                                                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                                        mstore(0x04, 0x41)
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
            }
            
            /*
            * @custom:signature    PCS_V4_MANAGER() public pure returns (uint256)
            */
            case 0xee4b1585 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    mstore(0x80, 0xa0ffb9c1ce1fe56963b0321b32e7a0302114058b)
                    return(mload(0x40), sub(add(0x20, mload(0x40)), mload(0x40)))
                }
            }
            
            /*
            * @custom:signature    Unresolved_58dfff0f(address arg0, address arg1) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg5 ["address", "uint128", "bytes16", "int128"]
            */
            case 0x58dfff0f {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xa0)) {
                            mstore(0x40, add(0x80, mload(0x40)))
                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) {
                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x04, 0x41)
                                        mstore(0x40, add(mload(0x40), 0xa0))
                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    UNI_V4_MANAGER() public pure returns (uint256)
            */
            case 0x6cfee777 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    mstore(0x80, 0x28e2ea090877bf75740558f6bfb36a5ffee9e9df)
                    return(mload(0x40), sub(add(0x20, mload(0x40)), mload(0x40)))
                }
            }
            
            /*
            * @custom:signature    Unresolved_0ed2006f(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x0ed2006f {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_23a69e75(uint256 arg0, uint256 arg1, uint256 arg2) public
            * @param                arg0 ["uint256", "bytes32", "int256"]
            * @param                arg1 ["uint256", "bytes32", "int256"]
            * @param                arg2 ["uint256", "bytes32", "int256"]
            */
            case 0x23a69e75 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if iszero(gt(calldataload(0x44), 0xffffffffffffffff)) { revert(0, 0); } else {
                            if slt(add(add(0x04, calldataload(0x44)), 0x1f), calldatasize()) {
                                if iszero(gt(calldataload(add(0x04, calldataload(0x44))), 0xffffffffffffffff)) { revert(0, 0); } else {
                                    if iszero(gt(add(add(add(0x04, calldataload(0x44)), calldataload(add(0x04, calldataload(0x44)))), 0x20), calldatasize())) {
                                        if eq(and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff), caller()) { revert(mload(0x40), sub(add(0x04, mload(0x40)), mload(0x40))); } else {
                                            mstore(0x80, 0x4b60273500000000000000000000000000000000000000000000000000000000)
                                            if iszero(sgt(calldataload(0x04), 0)) {
                                                mstore(0x80, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                                                mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                                mstore(0xa4, and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff))
                                                mstore(0xc4, calldataload(0x04))
                                                call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)
                                                if and(or(and(eq(mload(0), 0x01), gt(returndatasize(), 0x1f)), iszero(returndatasize())), call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)) { revert(mload(0x40), sub(add(0x04, mload(0x40)), mload(0x40))); } else {
                                                    mstore(0x80, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                                                    if iszero(sgt(calldataload(0x24), 0)) {
                                                        mstore(0x80, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                                                        mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                                        mstore(0xa4, and(tload(0), 0xffffffffffffffffffffffffffffffffffffffff))
                                                        mstore(0xc4, calldataload(0x24))
                                                        call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)
                                                        if and(or(and(eq(mload(0), 0x01), gt(returndatasize(), 0x1f)), iszero(returndatasize())), call(gas(), tload(0x01), 0, mload(0x40), 0x64, 0, 0x20)) { revert(0, 0); } else {
                                                            mstore(0x80, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x80, 0xa62a6d4200000000000000000000000000000000000000000000000000000000)
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
            
            /*
            * @custom:signature    Unresolved_35230cd8(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x35230cd8 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_05e85860(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x05e85860 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_9a462d4a(address arg0, address arg1, uint256 arg2, address arg3) public
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg1 ["address", "uint160", "bytes20", "int160"]
            * @param                arg5 ["uint256", "bytes32", "int256"]
            * @param                arg6 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x9a462d4a {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xe0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xa0)) {
                            if eq(calldataload(0xc4), and(calldataload(0xc4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                if iszero(slt(0x20, 0x20)) { revert(0, 0); } else {
                                    if eq(calldataload(0x24), and(calldataload(0x24), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        mstore(0x80, 0x70a0823100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                        staticcall(gas(), and(0xffffffffffffffffffffffffffffffffffffffff, calldataload(0x24)), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20)
                                        if iszero(iszero(staticcall(gas(), and(0xffffffffffffffffffffffffffffffffffffffff, calldataload(0x24)), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20))) { revert(0, returndatasize()); } else {
                                            returndatacopy(0, 0, returndatasize())
                                            mstore(0x40, add(mload(0x40), and(add(returndatasize(), 0x1f), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0)))
                                            if iszero(slt(sub(add(mload(0x40), returndatasize()), mload(0x40)), 0x20)) {
                                                if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                    mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                    mstore(0x04, 0x11)
                                                    if lt(calldataload(0xa4), sub(mload(mload(0x40)), 0x01)) {
                                                        if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x04, 0x11)
                                                            mstore(0x40, add(0x80, mload(0x40)))
                                                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) {
                                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                        mstore(0x04, 0x41)
                                                                        mstore(0x40, add(mload(0x40), 0xa0))
                                                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                                                            mstore(0x40, add(0x80, mload(0x40)))
                                                                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xa0)) {
                                                                                    if iszero(or(lt(add(mload(0x40), 0xa0), mload(0x40)), gt(add(mload(0x40), 0xa0), 0xffffffffffffffff))) { revert(0, 0); } else {
                                                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                                        mstore(0x04, 0x41)
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
            }
            
            /*
            * @custom:signature    Unresolved_716629d5(uint256 arg0, address arg1) public pure
            * @param                arg6 ["uint256", "bytes32", "int256"]
            * @param                arg7 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x716629d5 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x01a0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            if eq(calldataload(0xe4), and(calldataload(0xe4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_d3a57c62(uint256 arg0, address arg1) public pure
            * @param                arg5 ["uint256", "bytes32", "int256"]
            * @param                arg6 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xd3a57c62 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0180)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xa0)) {
                            if eq(calldataload(0xc4), and(calldataload(0xc4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_29645a14(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x29645a14 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_f9125e2c(uint256 arg0) public
            * @param                arg0 ["uint256", "bytes32", "int256"]
            */
            case 0xf9125e2c {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x20)) {
                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                                if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                                    if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                                        if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                                            if eq(0xc6e2672b8e7adabbcad9ad1d694d0567c0927014, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                                                                                                                call(gas(), 0x7817dbf38e9d1c95671625f0052c147864692fe0, calldataload(0x04), mload(0x40), sub(mload(0x40), mload(0x40)), mload(0x40), 0)
                                                                                                                                if eq(returndatasize(), 0) {
                                                                                                                                    if call(gas(), 0x7817dbf38e9d1c95671625f0052c147864692fe0, calldataload(0x04), mload(0x40), sub(mload(0x40), mload(0x40)), mload(0x40), 0) { revert(0, 0); } else {
                                                                                                                                        mstore(0x80, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                                                                                                                                        mstore(0x80, 0x82b4290000000000000000000000000000000000000000000000000000000000)
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
            
            /*
            * @custom:signature    Unresolved_9e1941ca(address arg0, uint256 arg1, address arg2) public
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg6 ["uint256", "bytes32", "int256"]
            * @param                arg7 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x9e1941ca {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0100)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            if eq(calldataload(0xe4), and(calldataload(0xe4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                if iszero(slt(0x20, 0x20)) { revert(0, 0); } else {
                                    if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        if iszero(and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                            mstore(0x80, 0x70a0823100000000000000000000000000000000000000000000000000000000)
                                            mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                            staticcall(gas(), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20)
                                            if iszero(iszero(staticcall(gas(), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20))) { revert(0, returndatasize()); } else {
                                                returndatacopy(0, 0, returndatasize())
                                                mstore(0x40, add(mload(0x40), and(add(returndatasize(), 0x1f), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0)))
                                                if iszero(slt(sub(add(mload(0x40), returndatasize()), mload(0x40)), 0x20)) {
                                                    if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                        mstore(0x04, 0x11)
                                                        if lt(calldataload(0xc4), sub(mload(mload(0x40)), 0x01)) {
                                                            if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                                mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                mstore(0x04, 0x11)
                                                                mstore(0x40, add(0x80, mload(0x40)))
                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                    if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                        if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) {
                                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                            mstore(0x04, 0x41)
                                                                            mstore(0x40, add(mload(0x40), 0xc0))
                                                                            if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                                                                mstore(0x40, add(0x80, mload(0x40)))
                                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                                    if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                                        if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) { revert(0, 0); } else {
                                                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                                            mstore(0x04, 0x41)
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
                }
            }
            
            /*
            * @custom:signature    Unresolved_45353264(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x45353264 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    authorize(address arg0) public
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xb6a5d7de {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x20)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                            if eq(caller(), and(0xffffffffffffffffffffffffffffffffffffffff, sload(0))) { revert(0, 0); } else {
                                mstore(0x80, 0x82b4290000000000000000000000000000000000000000000000000000000000)
                                mstore(0, and(0xffffffffffffffffffffffffffffffffffffffff, calldataload(0x04)))
                                mstore(0x20, 0x01)
                                sstore(sha3(0, 0x40), or(0x01, and(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00, sload(sha3(0, 0x40)))))
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_f7a9bf57(address arg0, address arg1) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg6 ["address", "uint128", "bytes16", "int128"]
            */
            case 0xf7a9bf57 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xe0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            mstore(0x40, add(0x80, mload(0x40)))
                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                    if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) {
                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x04, 0x41)
                                        mstore(0x40, add(mload(0x40), 0xc0))
                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_95a8fcfb(address arg0, address arg1) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg6 ["address", "uint128", "bytes16", "int128"]
            */
            case 0x95a8fcfb {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0xe0)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            mstore(0x40, add(0x80, mload(0x40)))
                            if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                    if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) {
                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                        mstore(0x04, 0x41)
                                        mstore(0x40, add(mload(0x40), 0xc0))
                                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_a3f8ea7c(address arg0, address arg1, uint256 arg2, address arg3) public
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            * @param                arg1 ["address", "uint160", "bytes20", "int160"]
            * @param                arg6 ["uint256", "bytes32", "int256"]
            * @param                arg7 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xa3f8ea7c {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0100)) {
                        if iszero(slt(sub(calldatasize(), 0x04), 0xc0)) {
                            if eq(calldataload(0xe4), and(calldataload(0xe4), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                if iszero(slt(0x20, 0x20)) { revert(0, 0); } else {
                                    if eq(calldataload(0x24), and(calldataload(0x24), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                        if iszero(and(calldataload(0x24), 0xffffffffffffffffffffffffffffffffffffffff)) {
                                            mstore(0x80, 0x70a0823100000000000000000000000000000000000000000000000000000000)
                                            mstore(0x84, 0x7817dbf38e9d1c95671625f0052c147864692fe0)
                                            staticcall(gas(), and(calldataload(0x24), 0xffffffffffffffffffffffffffffffffffffffff), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20)
                                            if iszero(iszero(staticcall(gas(), and(calldataload(0x24), 0xffffffffffffffffffffffffffffffffffffffff), mload(0x40), sub(add(0x20, add(0x04, mload(0x40))), mload(0x40)), mload(0x40), 0x20))) { revert(0, returndatasize()); } else {
                                                returndatacopy(0, 0, returndatasize())
                                                mstore(0x40, add(mload(0x40), and(add(returndatasize(), 0x1f), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0)))
                                                if iszero(slt(sub(add(mload(0x40), returndatasize()), mload(0x40)), 0x20)) {
                                                    if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                        mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                        mstore(0x04, 0x11)
                                                        if lt(calldataload(0xc4), sub(mload(mload(0x40)), 0x01)) {
                                                            if iszero(gt(sub(mload(mload(0x40)), 0x01), mload(mload(0x40)))) {
                                                                mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                mstore(0x04, 0x11)
                                                                mstore(0x40, add(0x80, mload(0x40)))
                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                    if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                        if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) {
                                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                            mstore(0x04, 0x41)
                                                                            mstore(0x40, add(mload(0x40), 0xc0))
                                                                            if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                                                                                mstore(0x40, add(0x80, mload(0x40)))
                                                                                if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                                    if iszero(slt(sub(add(0x04, sub(calldatasize(), 0x04)), 0x04), 0xc0)) {
                                                                                        if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) { revert(0, 0); } else {
                                                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                                                            mstore(0x04, 0x41)
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
                }
            }
            
            /*
            * @custom:signature    Unresolved_ab6291fe(uint256 arg0, uint256 arg1, address arg2) public pure
            * @param                arg0 ["uint256", "bytes32", "int256"]
            * @param                arg1 ["uint256", "bytes32", "int256"]
            * @param                arg2 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xab6291fe {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x20)) {
                        if iszero(gt(calldataload(0x04), 0xffffffffffffffff)) { revert(0, 0); } else {
                            if slt(add(add(0x04, calldataload(0x04)), 0x1f), calldatasize()) {
                                if iszero(gt(calldataload(add(0x04, calldataload(0x04))), 0xffffffffffffffff)) { revert(0, 0); } else {
                                    if iszero(gt(add(add(add(0x04, calldataload(0x04)), calldataload(add(0x04, calldataload(0x04)))), 0x20), calldatasize())) {
                                        if iszero(slt(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(0x04, calldataload(0x04)), 0x20)), 0x0140)) {
                                            if iszero(slt(add(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(0x04, calldataload(0x04)), 0x20)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0), 0x0120)) {
                                                if iszero(or(lt(add(mload(0x40), 0x80), mload(0x40)), gt(add(mload(0x40), 0x80), 0xffffffffffffffff))) {
                                                    mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                    mstore(0x04, 0x41)
                                                    mstore(0x40, add(mload(0x40), 0x80))
                                                    if iszero(slt(sub(add(add(add(0x04, calldataload(0x04)), 0x20), calldataload(add(0x04, calldataload(0x04)))), add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), 0xc0)) {
                                                        if iszero(or(lt(add(mload(0x40), 0xc0), mload(0x40)), gt(add(mload(0x40), 0xc0), 0xffffffffffffffff))) {
                                                            mstore(0, 0x4e487b7100000000000000000000000000000000000000000000000000000000)
                                                            mstore(0x04, 0x41)
                                                            mstore(0x40, add(mload(0x40), 0xc0))
                                                            if eq(calldataload(add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), and(calldataload(add(add(add(0x04, calldataload(0x04)), 0x20), 0x20)), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
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
            
            /*
            * @custom:signature    Unresolved_e7dd6c65(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xe7dd6c65 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_2ad802d2(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x2ad802d2 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_47b148ef(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0x47b148ef {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_f98ef606(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xf98ef606 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_e336c026(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xe336c026 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x60)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_fad7c5c6(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xfad7c5c6 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x0120)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            
            /*
            * @custom:signature    Unresolved_fc102e12(address arg0) public pure
            * @param                arg0 ["address", "uint160", "bytes20", "int160"]
            */
            case 0xfc102e12 {
                if iszero(callvalue()) { revert(0, 0); } else {
                    if iszero(slt(sub(calldatasize(), 0x04), 0x80)) {
                        if eq(calldataload(0x04), and(calldataload(0x04), 0xffffffffffffffffffffffffffffffffffffffff)) { revert(0, 0); } else {
                        }
                    }
                }
            }
            default { revert(0, 0) }
        }
    }
}