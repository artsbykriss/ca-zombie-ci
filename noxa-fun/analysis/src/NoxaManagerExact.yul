/// @use-src 0:"@openzeppelin/contracts/access/Ownable.sol", 7:"@openzeppelin/contracts/utils/Context.sol", 9:"@openzeppelin/contracts/utils/ReentrancyGuard.sol", 11:"src/v144_literal_bool.sol"
// NOXA FUN CORE CONTRACTS
//   Launch Factory: 0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB
//   Launch Locker: 0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85
//   Manager: 0x9eFdC1A8e6E94f16A228e44f3025E1f346EE0417
//   Token: 0xe0b7a0674bb161fe0a1e7c7af3fd238bbaafdf48

object "NoxaManagerV116_1209" {
    code {
        {
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            let _1 := memoryguard(0xa0)
            if callvalue() { revert(0, 0) }
            let programSize := datasize("NoxaManagerV116_1209")
            let argSize := sub(codesize(), programSize)
            let newFreePtr := add(_1, and(add(argSize, 31), not(31)))
            if or(gt(newFreePtr, sub(shl(64, 1), 1)), lt(newFreePtr, _1))
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                mstore(4, 0x41)
                revert(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
            }
            mstore(64, newFreePtr)
            codecopy(_1, programSize, argSize)
            if slt(sub(add(_1, argSize), _1), 96)
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            let value0 := abi_decode_address_fromMemory(_1)
            let value1 := abi_decode_address_fromMemory(add(_1, 32))
            let value := mload(add(_1, 64))
            /// @src 0:1269:1364  "if (initialOwner == address(0)) {..."
            if /** @src 0:1273:1299  "initialOwner == address(0)" */ iszero(/** @src 11:9079:9089  "msg.sender" */ caller())
            /// @src 0:1269:1364  "if (initialOwner == address(0)) {..."
            {
                /// @src 0:1322:1353  "OwnableInvalidOwner(address(0))"
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:1322:1353  "OwnableInvalidOwner(address(0))" */ shl(224, 0x1e4fbdf7))
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                mstore(/** @src 0:1322:1353  "OwnableInvalidOwner(address(0))" */ 4, /** @src -1:-1:-1 */ 0)
                /// @src 0:1322:1353  "OwnableInvalidOwner(address(0))"
                revert(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 36)
            }
            let _2 := sload(/** @src -1:-1:-1 */ 0)
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            sstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ or(and(_2, not(sub(shl(160, 1), 1))), /** @src 11:9079:9089  "msg.sender" */ caller()))
            /// @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)"
            let _3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
            /// @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)"
            log3(/** @src -1:-1:-1 */ 0, 0, /** @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)" */ 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(_2, sub(shl(160, 1), 1)), /** @src 11:9079:9089  "msg.sender" */ caller())
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            sstore(1, 1)
            let _4 := and(/** @src 11:9105:9128  "_treasury == address(0)" */ value1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
            /// @src 11:9101:9150  "if (_treasury == address(0)) revert ZeroAddress()"
            if /** @src 11:9105:9128  "_treasury == address(0)" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _4)
            /// @src 11:9101:9150  "if (_treasury == address(0)) revert ZeroAddress()"
            {
                /// @src 11:9137:9150  "ZeroAddress()"
                mstore(/** @src -1:-1:-1 */ 0, /** @src 11:9137:9150  "ZeroAddress()" */ shl(224, 0xd92e233d))
                revert(/** @src -1:-1:-1 */ 0, /** @src 11:9137:9150  "ZeroAddress()" */ 4)
            }
            /// @src 11:9160:9215  "if (_protocolShare > 100) revert InvalidProtocolShare()"
            if /** @src 11:9164:9184  "_protocolShare > 100" */ gt(value, /** @src 11:9181:9184  "100" */ 0x64)
            /// @src 11:9160:9215  "if (_protocolShare > 100) revert InvalidProtocolShare()"
            {
                /// @src 11:9193:9215  "InvalidProtocolShare()"
                mstore(/** @src -1:-1:-1 */ 0, /** @src 11:9193:9215  "InvalidProtocolShare()" */ shl(226, 0x079fbb7f))
                revert(/** @src -1:-1:-1 */ 0, /** @src 11:9193:9215  "InvalidProtocolShare()" */ 4)
            }
            /// @src 11:9226:9257  "locker = ILaunchLocker(_locker)"
            mstore(128, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:9235:9257  "ILaunchLocker(_locker)" */ value0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)))
            sstore(/** @src 11:9267:9287  "treasury = _treasury" */ 0x02, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ or(and(sload(/** @src 11:9267:9287  "treasury = _treasury" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ not(sub(shl(160, 1), 1))), _4))
            sstore(/** @src 11:9297:9327  "protocolShare = _protocolShare" */ 0x03, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ value)
            sstore(/** @src 11:9337:9386  "tokenTreasuryShare = DEFAULT_TOKEN_TREASURY_SHARE" */ 0x04, /** @src 11:4866:4868  "20" */ 0x14)
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            let _5 := datasize("NoxaManagerV116_1209_deployed")
            codecopy(_3, dataoffset("NoxaManagerV116_1209_deployed"), _5)
            setimmutable(_3, "113", mload(/** @src 11:9226:9257  "locker = ILaunchLocker(_locker)" */ 128))
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            return(_3, _5)
        }
        function abi_decode_address_fromMemory(offset) -> value
        {
            value := mload(offset)
            if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
        }
    }
    /// @use-src 0:"@openzeppelin/contracts/access/Ownable.sol", 5:"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol", 7:"@openzeppelin/contracts/utils/Context.sol", 9:"@openzeppelin/contracts/utils/ReentrancyGuard.sol", 11:"src/v144_literal_bool.sol"
    object "NoxaManagerV116_1209_deployed" {
        code {
            {
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                mstore(64, memoryguard(0x80))
                if iszero(lt(calldatasize(), 4))
                {
                    let _1 := 0
                    switch shr(224, calldataload(0))
                    case 0x01681a62 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(0, 0) }
                        let value0 := abi_decode_address()
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let cleaned := and(sload(/** @src 11:11593:11601  "treasury" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        let _2 := and(/** @src 11:11629:11642  "IERC20(token)" */ value0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        let _3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        mstore(_3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x70a08231))
                        mstore(/** @src 11:11629:11667  "IERC20(token).balanceOf(address(this))" */ add(_3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), /** @src 11:11661:11665  "this" */ address())
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        let _4 := staticcall(gas(), _2, _3, 36, _3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        if iszero(_4)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        let expr := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                        /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                        if _4
                        {
                            let _5 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:11629:11667  "IERC20(token).balanceOf(address(this))"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:11629:11667  "IERC20(token).balanceOf(address(this))" */ returndatasize()) { _5 := returndatasize() }
                            finalize_allocation(_3, _5)
                            let value0_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                            if slt(sub(/** @src 11:11629:11667  "IERC20(token).balanceOf(address(this))" */ add(_3, _5), _3), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32) { revert(0, 0) }
                            value0_1 := mload(/** @src 11:11629:11667  "IERC20(token).balanceOf(address(this))" */ _3)
                            expr := value0_1
                        }
                        /// @src 11:11715:11722  "balance"
                        fun_safeTransfer(_2, cleaned, expr)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(0, 0)
                    }
                    case 0x03fd2a45 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos := mload(64)
                        mstore(memPos, /** @src 11:4469:4511  "0x000000000000000000000000000000000000dEaD" */ 0xdead)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(memPos, 32)
                    }
                    case 0x06ec16f8 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(0, 0) }
                        let value0_2 := abi_decode_address()
                        /// @src 9:2698:2784  "if (_status == ENTERED) {..."
                        if /** @src 9:2702:2720  "_status == ENTERED" */ eq(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sload(/** @src 9:2702:2709  "_status" */ 0x01), /** @src 9:1899:1900  "2" */ 0x02)
                        /// @src 9:2698:2784  "if (_status == ENTERED) {..."
                        {
                            /// @src 9:2743:2773  "ReentrancyGuardReentrantCall()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, /** @src 9:2743:2773  "ReentrancyGuardReentrantCall()" */ shl(224, 0x3ee5aeb5))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, 4)
                        }
                        sstore(/** @src 9:2702:2709  "_status" */ 0x01, /** @src 9:1899:1900  "2" */ 0x02)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _6 := and(/** @src 11:14463:14469  "locker" */ loadimmutable("113"), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        /// @src 11:14463:14493  "locker.getLaunchedToken(token)"
                        let _7 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:14463:14493  "locker.getLaunchedToken(token)"
                        mstore(_7, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x1e7945ad))
                        let _8 := and(value0_2, sub(shl(160, 1), 1))
                        mstore(/** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ add(_7, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), _8)
                        /// @src 11:14463:14493  "locker.getLaunchedToken(token)"
                        let _9 := staticcall(gas(), _6, _7, 36, _7, 416)
                        if iszero(_9)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_1 := mload(64)
                            returndatacopy(pos_1, 0, returndatasize())
                            revert(pos_1, returndatasize())
                        }
                        /// @src 11:14463:14493  "locker.getLaunchedToken(token)"
                        let expr_mpos := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                        /// @src 11:14463:14493  "locker.getLaunchedToken(token)"
                        if _9
                        {
                            let _10 := 416
                            if gt(_10, returndatasize()) { _10 := returndatasize() }
                            finalize_allocation(_7, _10)
                            expr_mpos := abi_decode_struct_LaunchInfo_fromMemory(_7, add(_7, _10))
                        }
                        /// @src 11:14503:14543  "if (!info.exists) revert TokenNotFound()"
                        if /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ iszero(mload(/** @src 11:14508:14519  "info.exists" */ add(expr_mpos, 352)))
                        /// @src 11:14503:14543  "if (!info.exists) revert TokenNotFound()"
                        {
                            /// @src 11:14528:14543  "TokenNotFound()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, /** @src 11:14528:14543  "TokenNotFound()" */ shl(228, 0x0cbdb7b3))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, 4)
                        }
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        let _11 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        mstore(_11, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x4b059351))
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        let _12 := staticcall(gas(), _6, _11, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4, /** @src 11:14586:14611  "locker.protocolFeeShare()" */ _11, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        if iszero(_12)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_2 := mload(64)
                            returndatacopy(pos_2, 0, returndatasize())
                            revert(pos_2, returndatasize())
                        }
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        let expr_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                        /// @src 11:14586:14611  "locker.protocolFeeShare()"
                        if _12
                        {
                            let _13 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:14586:14611  "locker.protocolFeeShare()"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:14586:14611  "locker.protocolFeeShare()" */ returndatasize()) { _13 := returndatasize() }
                            finalize_allocation(_11, _13)
                            let value0_3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                            if slt(sub(/** @src 11:14586:14611  "locker.protocolFeeShare()" */ add(_11, _13), _11), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32) { revert(0, 0) }
                            value0_3 := mload(/** @src 11:14586:14611  "locker.protocolFeeShare()" */ _11)
                            expr_1 := value0_3
                        }
                        /// @src 11:14586:14618  "locker.protocolFeeShare() != 100"
                        let _14 := eq(expr_1, /** @src 11:14615:14618  "100" */ 0x64)
                        /// @src 11:14586:14668  "locker.protocolFeeShare() != 100 || locker.protocolFeeRecipient() != address(this)"
                        let expr_2 := /** @src 11:14586:14618  "locker.protocolFeeShare() != 100" */ iszero(_14)
                        /// @src 11:14586:14668  "locker.protocolFeeShare() != 100 || locker.protocolFeeRecipient() != address(this)"
                        if _14
                        {
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            let _15 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            mstore(_15, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x326f824f))
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            let _16 := staticcall(gas(), _6, _15, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4, /** @src 11:14622:14651  "locker.protocolFeeRecipient()" */ _15, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            if iszero(_16)
                            {
                                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                let pos_3 := mload(64)
                                returndatacopy(pos_3, 0, returndatasize())
                                revert(pos_3, returndatasize())
                            }
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            let expr_3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                            /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                            if _16
                            {
                                let _17 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                                /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                                if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:14622:14651  "locker.protocolFeeRecipient()" */ returndatasize()) { _17 := returndatasize() }
                                finalize_allocation(_15, _17)
                                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                if slt(sub(/** @src 11:14622:14651  "locker.protocolFeeRecipient()" */ add(_15, _17), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _15), 32) { revert(0, 0) }
                                /// @src 11:14622:14651  "locker.protocolFeeRecipient()"
                                expr_3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ abi_decode_address_fromMemory(_15)
                            }
                            /// @src 11:14586:14668  "locker.protocolFeeShare() != 100 || locker.protocolFeeRecipient() != address(this)"
                            expr_2 := /** @src 11:14622:14668  "locker.protocolFeeRecipient() != address(this)" */ iszero(eq(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:14622:14668  "locker.protocolFeeRecipient() != address(this)" */ expr_3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)), /** @src 11:14663:14667  "this" */ address()))
                        }
                        /// @src 11:14582:14723  "if (locker.protocolFeeShare() != 100 || locker.protocolFeeRecipient() != address(this)) {..."
                        if expr_2
                        {
                            /// @src 11:14691:14712  "InvalidFeeRecipient()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, /** @src 11:14691:14712  "InvalidFeeRecipient()" */ shl(225, 0x7c706f63))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, 4)
                        }
                        let cleaned_1 := and(mload(/** @src 11:14802:14818  "info.pairedToken" */ add(expr_mpos, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 64)), sub(shl(160, 1), 1))
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        let _18 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        mstore(_18, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x70a08231))
                        mstore(/** @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))" */ add(_18, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), /** @src 11:14963:14967  "this" */ address())
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        let _19 := staticcall(gas(), _8, _18, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36, /** @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))" */ _18, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        if iszero(_19)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_4 := mload(64)
                            returndatacopy(pos_4, 0, returndatasize())
                            revert(pos_4, returndatasize())
                        }
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        let expr_4 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                        /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                        if _19
                        {
                            let _20 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))" */ returndatasize()) { _20 := returndatasize() }
                            finalize_allocation(_18, _20)
                            let value0_4 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                            if slt(sub(/** @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))" */ add(_18, _20), _18), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32) { revert(0, 0) }
                            value0_4 := mload(/** @src 11:14930:14969  "IERC20(token1).balanceOf(address(this))" */ _18)
                            expr_4 := value0_4
                        }
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        let _21 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        mstore(_21, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x70a08231))
                        mstore(/** @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))" */ add(_21, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), /** @src 11:14963:14967  "this" */ address())
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        let _22 := staticcall(gas(), cleaned_1, _21, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36, /** @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))" */ _21, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        if iszero(_22)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_5 := mload(64)
                            returndatacopy(pos_5, 0, returndatasize())
                            revert(pos_5, returndatasize())
                        }
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        let expr_5 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                        /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                        if _22
                        {
                            let _23 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))" */ returndatasize()) { _23 := returndatasize() }
                            finalize_allocation(_21, _23)
                            let value0_5 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                            if slt(sub(/** @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))" */ add(_21, _23), _21), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32) { revert(0, 0) }
                            value0_5 := mload(/** @src 11:14997:15036  "IERC20(token0).balanceOf(address(this))" */ _21)
                            expr_5 := value0_5
                        }
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        if iszero(extcodesize(_6))
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            revert(0, 0)
                        }
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        let _24 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        mstore(_24, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0xa480ca79))
                        mstore(/** @src 11:15130:15155  "locker.collectFees(token)" */ add(_24, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), _8)
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        let _25 := call(gas(), _6, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0, /** @src 11:15130:15155  "locker.collectFees(token)" */ _24, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36, /** @src 11:15130:15155  "locker.collectFees(token)" */ _24, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0)
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        if iszero(_25)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_6 := mload(64)
                            returndatacopy(pos_6, 0, returndatasize())
                            revert(pos_6, returndatasize())
                        }
                        /// @src 11:15130:15155  "locker.collectFees(token)"
                        if _25
                        {
                            finalize_allocation(_24, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0)
                            _1 := 0
                        }
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        let _26 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        mstore(_26, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x70a08231))
                        mstore(/** @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))" */ add(_26, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), /** @src 11:14963:14967  "this" */ address())
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        let _27 := staticcall(gas(), _8, _26, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36, /** @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))" */ _26, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        if iszero(_27)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_7 := mload(64)
                            returndatacopy(pos_7, _1, returndatasize())
                            revert(pos_7, returndatasize())
                        }
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        let expr_6 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                        if _27
                        {
                            let _28 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))" */ returndatasize()) { _28 := returndatasize() }
                            finalize_allocation(_26, _28)
                            let value0_6 := /** @src -1:-1:-1 */ 0
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            if slt(sub(/** @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))" */ add(_26, _28), _26), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                            {
                                revert(/** @src -1:-1:-1 */ 0, 0)
                            }
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            value0_6 := mload(/** @src 11:15226:15265  "IERC20(token1).balanceOf(address(this))" */ _26)
                            expr_6 := value0_6
                        }
                        /// @src 11:15226:15275  "IERC20(token1).balanceOf(address(this)) - before1"
                        let expr_7 := checked_sub_uint256(expr_6, expr_4)
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        let _29 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        mstore(_29, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x70a08231))
                        mstore(/** @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))" */ add(_29, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), /** @src 11:14963:14967  "this" */ address())
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        let _30 := staticcall(gas(), cleaned_1, _29, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36, /** @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))" */ _29, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        if iszero(_30)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_8 := mload(64)
                            returndatacopy(pos_8, _1, returndatasize())
                            revert(pos_8, returndatasize())
                        }
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        let expr_8 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                        if _30
                        {
                            let _31 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32
                            /// @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))"
                            if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))" */ returndatasize()) { _31 := returndatasize() }
                            finalize_allocation(_29, _31)
                            let value0_7 := /** @src -1:-1:-1 */ 0
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            if slt(sub(/** @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))" */ add(_29, _31), _29), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                            {
                                revert(/** @src -1:-1:-1 */ 0, 0)
                            }
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            value0_7 := mload(/** @src 11:15306:15345  "IERC20(token0).balanceOf(address(this))" */ _29)
                            expr_8 := value0_7
                        }
                        /// @src 11:15306:15355  "IERC20(token0).balanceOf(address(this)) - before0"
                        let expr_9 := checked_sub_uint256(expr_8, expr_5)
                        /// @src 11:15418:15440  "uint256 treasuryAmount"
                        let var_treasuryAmount := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15418:15440  "uint256 treasuryAmount"
                        var_treasuryAmount := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15450:15468  "uint256 burnAmount"
                        let var_burnAmount := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15450:15468  "uint256 burnAmount"
                        var_burnAmount := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:15693:16081  "if (collected1 > 0) {..."
                        if /** @src 11:15697:15711  "collected1 > 0" */ iszero(iszero(expr_7))
                        /// @src 11:15693:16081  "if (collected1 > 0) {..."
                        {
                            /// @src 11:15727:15781  "treasuryAmount = collected1 * tokenTreasuryShare / 100"
                            var_treasuryAmount := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ div(/** @src 11:15744:15775  "collected1 * tokenTreasuryShare" */ checked_mul_uint256(expr_7, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sload(4)), /** @src 11:14615:14618  "100" */ 0x64)
                            /// @src 11:15795:15835  "burnAmount = collected1 - treasuryAmount"
                            var_burnAmount := /** @src 11:15808:15835  "collected1 - treasuryAmount" */ checked_sub_uint256(expr_7, var_treasuryAmount)
                            /// @src 11:15850:15960  "if (treasuryAmount > 0) {..."
                            if /** @src 11:15854:15872  "treasuryAmount > 0" */ iszero(iszero(var_treasuryAmount))
                            /// @src 11:15850:15960  "if (treasuryAmount > 0) {..."
                            {
                                /// @src 11:15930:15944  "treasuryAmount"
                                fun_safeTransfer(_8, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(sload(/** @src 9:1899:1900  "2" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)), /** @src 11:15930:15944  "treasuryAmount" */ var_treasuryAmount)
                            }
                            /// @src 11:15973:16071  "if (burnAmount > 0) {..."
                            if /** @src 11:15977:15991  "burnAmount > 0" */ iszero(iszero(var_burnAmount))
                            /// @src 11:15973:16071  "if (burnAmount > 0) {..."
                            {
                                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                                let expr_mpos_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                                let _32 := add(expr_mpos_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)
                                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                                mstore(_32, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0xa9059cbb))
                                mstore(/** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ add(expr_mpos_1, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36), /** @src 11:4469:4511  "0x000000000000000000000000000000000000dEaD" */ 0xdead)
                                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                mstore(add(/** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ expr_mpos_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 68), var_burnAmount)
                                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                                mstore(expr_mpos_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 68)
                                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                                finalize_allocation(expr_mpos_1, /** @src 11:14615:14618  "100" */ 0x64)
                                /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                                if iszero(call(gas(), _8, /** @src -1:-1:-1 */ _1, /** @src 5:7875:8296  "assembly (\"memory-safe\") {..." */ _32, mload(expr_mpos_1), /** @src -1:-1:-1 */ _1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32))
                                /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                                {
                                    let usr$ptr := mload(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 64)
                                    /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                                    returndatacopy(usr$ptr, /** @src -1:-1:-1 */ _1, /** @src 5:7875:8296  "assembly (\"memory-safe\") {..." */ returndatasize())
                                    revert(usr$ptr, returndatasize())
                                }
                                let var_returnSize := returndatasize()
                                let var_returnValue := mload(/** @src -1:-1:-1 */ _1)
                                /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                                let expr_10 := /** @src -1:-1:-1 */ _1
                                /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                                switch /** @src 5:8310:8325  "returnSize == 0" */ iszero(var_returnSize)
                                case /** @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1" */ 0 {
                                    expr_10 := /** @src 5:8362:8378  "returnValue != 1" */ iszero(eq(var_returnValue, /** @src 9:2702:2709  "_status" */ 0x01))
                                }
                                default /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                                {
                                    expr_10 := /** @src 5:8328:8359  "address(token).code.length == 0" */ iszero(/** @src 5:8328:8354  "address(token).code.length" */ extcodesize(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _8))
                                }
                                /// @src 5:8306:8452  "if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {..."
                                if expr_10
                                {
                                    /// @src 5:8401:8441  "SafeERC20FailedOperation(address(token))"
                                    mstore(/** @src -1:-1:-1 */ _1, /** @src 5:8401:8441  "SafeERC20FailedOperation(address(token))" */ shl(224, 0x5274afe7))
                                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                    mstore(4, _8)
                                    /// @src 5:8401:8441  "SafeERC20FailedOperation(address(token))"
                                    revert(/** @src -1:-1:-1 */ _1, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36)
                                }
                            }
                        }
                        /// @src 11:16312:16331  "uint256 protocolFee"
                        let var_protocolFee := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:16312:16331  "uint256 protocolFee"
                        var_protocolFee := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:16341:16362  "uint256 distributable"
                        let var_distributable := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:16341:16362  "uint256 distributable"
                        var_distributable := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:16372:17526  "if (collected0 > 0) {..."
                        if /** @src 11:16376:16390  "collected0 > 0" */ iszero(iszero(expr_9))
                        /// @src 11:16372:17526  "if (collected0 > 0) {..."
                        {
                            /// @src 11:16434:16480  "protocolFee = collected0 * protocolShare / 100"
                            var_protocolFee := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ div(/** @src 11:16448:16474  "collected0 * protocolShare" */ checked_mul_uint256(expr_9, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sload(/** @src 11:16461:16474  "protocolShare" */ 0x03)), /** @src 11:14615:14618  "100" */ 0x64)
                            /// @src 11:16494:16534  "distributable = collected0 - protocolFee"
                            var_distributable := /** @src 11:16510:16534  "collected0 - protocolFee" */ checked_sub_uint256(expr_9, var_protocolFee)
                            /// @src 11:16594:16698  "if (protocolFee > 0) {..."
                            if /** @src 11:16598:16613  "protocolFee > 0" */ iszero(iszero(var_protocolFee))
                            /// @src 11:16594:16698  "if (protocolFee > 0) {..."
                            {
                                /// @src 11:16671:16682  "protocolFee"
                                fun_safeTransfer(cleaned_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(sload(/** @src 9:1899:1900  "2" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)), /** @src 11:16671:16682  "protocolFee" */ var_protocolFee)
                            }
                            /// @src 11:16777:17516  "if (distributable > 0) {..."
                            if /** @src 11:16781:16798  "distributable > 0" */ iszero(iszero(var_distributable))
                            /// @src 11:16777:17516  "if (distributable > 0) {..."
                            {
                                /// @src 11:16879:16900  "_getLaunchData(token)"
                                let expr_component_mpos, expr_component_mpos_1, expr_component := fun_getLaunchData(value0_2)
                                /// @src 11:16935:16951  "receivers.length"
                                let expr_11 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(/** @src 11:16935:16951  "receivers.length" */ expr_component_mpos)
                                /// @src 11:16969:16988  "uint256 distributed"
                                let var_distributed := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                                /// @src 11:16969:16988  "uint256 distributed"
                                var_distributed := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                                /// @src 11:17011:17024  "uint256 i = 0"
                                let var_i := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                                let diff := add(expr_11, not(0))
                                let _33 := gt(diff, expr_11)
                                /// @src 11:17006:17502  "for (uint256 i = 0; i < length; i++) {..."
                                for { }
                                /** @src 11:17026:17036  "i < length" */ lt(var_i, expr_11)
                                /// @src 11:17011:17024  "uint256 i = 0"
                                {
                                    /// @src 11:17038:17041  "i++"
                                    var_i := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ add(/** @src 11:17038:17041  "i++" */ var_i, /** @src 9:2702:2709  "_status" */ 0x01)
                                }
                                /// @src 11:17038:17041  "i++"
                                {
                                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                    if _33
                                    {
                                        mstore(_1, shl(224, 0x4e487b71))
                                        mstore(4, 0x11)
                                        revert(_1, /** @src 11:14463:14493  "locker.getLaunchedToken(token)" */ 36)
                                    }
                                    /// @src 11:17082:17215  "i == length - 1..."
                                    let expr_12 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                                    /// @src 11:17082:17215  "i == length - 1..."
                                    switch /** @src 11:17082:17097  "i == length - 1" */ eq(var_i, diff)
                                    case /** @src 11:17082:17215  "i == length - 1..." */ 0 {
                                        expr_12 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ div(/** @src 11:17178:17209  "distributable * shareAmounts[i]" */ checked_mul_uint256(var_distributable, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(mload(/** @src 11:17194:17209  "shareAmounts[i]" */ memory_array_index_access_array_uint8_dyn(expr_component_mpos_1, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0xff)), /** @src 11:14615:14618  "100" */ 0x64)
                                    }
                                    default /// @src 11:17082:17215  "i == length - 1..."
                                    {
                                        expr_12 := /** @src 11:17124:17151  "distributable - distributed" */ checked_sub_uint256(var_distributable, var_distributed)
                                    }
                                    /// @src 11:17237:17258  "distributed += amount"
                                    var_distributed := checked_add_uint256(var_distributed, expr_12)
                                    /// @src 11:17280:17484  "if (amount > 0) {..."
                                    if /** @src 11:17284:17294  "amount > 0" */ iszero(iszero(expr_12))
                                    /// @src 11:17280:17484  "if (amount > 0) {..."
                                    {
                                        /// @src 11:17364:17370  "amount"
                                        fun_safeTransfer(cleaned_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(mload(/** @src 11:17350:17362  "receivers[i]" */ memory_array_index_access_array_uint8_dyn(expr_component_mpos, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)), /** @src 11:17364:17370  "amount" */ expr_12)
                                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                                        let cleaned_2 := and(mload(/** @src 11:17423:17435  "receivers[i]" */ memory_array_index_access_array_uint8_dyn(expr_component_mpos, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                                        let cleaned_3 := and(mload(/** @src 11:17437:17452  "shareAmounts[i]" */ memory_array_index_access_array_uint8_dyn(expr_component_mpos_1, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0xff)
                                        /// @src 11:17402:17461  "ReceiverPaid(token1, receivers[i], shareAmounts[i], amount)"
                                        let _34 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                                        mstore(_34, cleaned_3)
                                        mstore(add(_34, 32), expr_12)
                                        /// @src 11:17402:17461  "ReceiverPaid(token1, receivers[i], shareAmounts[i], amount)"
                                        log3(_34, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 64, /** @src 11:17402:17461  "ReceiverPaid(token1, receivers[i], shareAmounts[i], amount)" */ 0xf17b3ca546bd4f25a9ea8fb8fe7080586d8fe0b0603396579f7d952e818d7025, _8, cleaned_2)
                                    }
                                }
                            }
                        }
                        /// @src 11:17541:17753  "FeesRouted(..."
                        let _35 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        mstore(_35, cleaned_1)
                        mstore(add(_35, 32), var_burnAmount)
                        mstore(add(_35, 64), var_treasuryAmount)
                        mstore(add(_35, 96), expr_9)
                        mstore(add(_35, 128), var_protocolFee)
                        mstore(add(_35, 160), var_distributable)
                        /// @src 11:17541:17753  "FeesRouted(..."
                        log3(_35, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 192, /** @src 11:17541:17753  "FeesRouted(..." */ 0x6076d43b5b32e6c957729288a7be16fad5fa7c4fc38b80f32d7f4d648d27729f, _8, /** @src 11:17585:17595  "msg.sender" */ caller())
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        sstore(/** @src 9:2702:2709  "_status" */ 0x01, 0x01)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0x0a5e1a50 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let _37 := and(abi_decode_address(), sub(shl(160, 1), 1))
                        mstore(_1, _37)
                        mstore(32, /** @src 11:19352:19360  "_configs" */ 0x05)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let dataSlot := keccak256(_1, 64)
                        mstore(_1, _37)
                        mstore(32, /** @src 11:19352:19360  "_configs" */ 0x05)
                        /// @src 11:19379:19401  "_configs[token].shares"
                        let _38 := add(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ keccak256(_1, 64), /** @src 11:19379:19401  "_configs[token].shares" */ 1)
                        /// @src 11:19344:19402  "return (_configs[token].receivers, _configs[token].shares)"
                        let var_mpos := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_address_dyn(/** @src 11:19344:19402  "return (_configs[token].receivers, _configs[token].shares)" */ dataSlot)
                        let var_mpos_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_uint8_dyn(/** @src 11:19344:19402  "return (_configs[token].receivers, _configs[token].shares)" */ _38)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let memPos_3 := mload(64)
                        return(memPos_3, sub(abi_encode_array_address_dyn_array_uint8_dyn(memPos_3, var_mpos, var_mpos_1), memPos_3))
                    }
                    case 0x0effce65 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let memPos_1 := mload(64)
                        mstore(memPos_1, /** @src 11:4616:4618  "10" */ 0x0a)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(memPos_1, 32)
                    }
                    case 0x1103f315 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let _36 := sload(/** @src 11:5416:5444  "uint256 public protocolShare" */ 3)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let memPos_2 := mload(64)
                        mstore(memPos_2, _36)
                        return(memPos_2, 32)
                    }
                    case 0x1e249585 {
                        if callvalue() { revert(_1, _1) }
                        let param, param_1, param_2, param_3, param_4 := abi_decode_addresst_array_address_dyn_calldatat_array_uint8_dyn_calldata(calldatasize())
                        /// @src 11:12730:12760  "locker.getLaunchedToken(token)"
                        let _39 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:12730:12760  "locker.getLaunchedToken(token)"
                        mstore(_39, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x1e7945ad))
                        let _40 := and(param, sub(shl(160, 1), 1))
                        mstore(/** @src 11:12730:12760  "locker.getLaunchedToken(token)" */ add(_39, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 4), _40)
                        /// @src 11:12730:12760  "locker.getLaunchedToken(token)"
                        let _41 := staticcall(gas(), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:12730:12736  "locker" */ loadimmutable("113"), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)), /** @src 11:12730:12760  "locker.getLaunchedToken(token)" */ _39, 36, _39, 416)
                        if iszero(_41)
                        {
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            let pos_9 := mload(64)
                            returndatacopy(pos_9, _1, returndatasize())
                            revert(pos_9, returndatasize())
                        }
                        /// @src 11:12730:12760  "locker.getLaunchedToken(token)"
                        let expr_mpos_2 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        /// @src 11:12730:12760  "locker.getLaunchedToken(token)"
                        if _41
                        {
                            let _42 := 416
                            if gt(_42, returndatasize()) { _42 := returndatasize() }
                            finalize_allocation(_39, _42)
                            expr_mpos_2 := abi_decode_struct_LaunchInfo_fromMemory(_39, add(_39, _42))
                        }
                        /// @src 11:12770:12810  "if (!info.exists) revert TokenNotFound()"
                        if /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ iszero(mload(/** @src 11:12775:12786  "info.exists" */ add(expr_mpos_2, 352)))
                        /// @src 11:12770:12810  "if (!info.exists) revert TokenNotFound()"
                        {
                            /// @src 11:12795:12810  "TokenNotFound()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 11:14528:14543  "TokenNotFound()" */ shl(228, 0x0cbdb7b3))
                            /// @src 11:12795:12810  "TokenNotFound()"
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 4)
                        }
                        let cleaned_4 := and(mload(/** @src 11:12824:12837  "info.deployer" */ add(expr_mpos_2, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32)), sub(shl(160, 1), 1))
                        /// @src 11:12820:12873  "if (info.deployer != msg.sender) revert NotDeployer()"
                        if /** @src 11:12824:12851  "info.deployer != msg.sender" */ iszero(eq(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ cleaned_4, /** @src 11:12841:12851  "msg.sender" */ caller()))
                        /// @src 11:12820:12873  "if (info.deployer != msg.sender) revert NotDeployer()"
                        {
                            /// @src 11:12860:12873  "NotDeployer()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 11:12860:12873  "NotDeployer()" */ shl(224, 0x8b906c97))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 4)
                        }
                        /// @src 11:12916:12922  "shares"
                        fun_validateShareConfig(param_1, param_2, param_3, param_4)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        mstore(_1, _40)
                        mstore(32, /** @src 11:12954:12962  "_configs" */ 0x05)
                        /// @src 11:12933:12989  "_storeReceiverConfig(_configs[token], receivers, shares)"
                        fun_storeReceiverConfig(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ keccak256(_1, 64), /** @src 11:12933:12989  "_storeReceiverConfig(_configs[token], receivers, shares)" */ param_1, param_2, param_3, param_4)
                        /// @src 11:13004:13050  "ConfigUpdated(token, false, receivers, shares)"
                        let _43 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:13004:13050  "ConfigUpdated(token, false, receivers, shares)"
                        log3(_43, sub(abi_encode_array_address_dyn_calldata_array_uint8_dyn_calldata(_43, param_1, param_2, param_3, param_4), _43), 0x7c75122b2871a91e189a762c2400b0ac22d1261162795bdce11a676ca010efba, _40, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1)
                        return(_1, _1)
                    }
                    case 0x558b6a9a {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let memPos_4 := mload(64)
                        mstore(memPos_4, /** @src 11:4866:4868  "20" */ 0x14)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(memPos_4, 32)
                    }
                    case 0x61d027b3 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let value := and(sload(/** @src 11:5350:5373  "address public treasury" */ 2), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        let memPos_5 := mload(64)
                        mstore(memPos_5, value)
                        return(memPos_5, 32)
                    }
                    case 0x715018a6 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _44 := sload(_1)
                        sstore(_1, and(_44, shl(160, 0xffffffffffffffffffffffff)))
                        /// @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)"
                        log3(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, _1, /** @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)" */ 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(_44, sub(shl(160, 1), 1)), _1)
                        return(_1, _1)
                    }
                    case 0x8da5cb5b {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let cleaned_5 := and(sload(_1), sub(shl(160, 1), 1))
                        let memPos_6 := mload(64)
                        mstore(memPos_6, cleaned_5)
                        return(memPos_6, 32)
                    }
                    case 0x968daa2c {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value_1 := calldataload(4)
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:10435:10487  "if (_share > 100) revert InvalidTokenTreasuryShare()"
                        if /** @src 11:10439:10451  "_share > 100" */ gt(value_1, /** @src 11:10448:10451  "100" */ 0x64)
                        /// @src 11:10435:10487  "if (_share > 100) revert InvalidTokenTreasuryShare()"
                        {
                            /// @src 11:10460:10487  "InvalidTokenTreasuryShare()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 11:10460:10487  "InvalidTokenTreasuryShare()" */ shl(224, 0x7f4b7465))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 4)
                        }
                        sstore(4, value_1)
                        /// @src 11:10539:10572  "TokenTreasuryShareUpdated(_share)"
                        let _45 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        mstore(_45, value_1)
                        /// @src 11:10539:10572  "TokenTreasuryShareUpdated(_share)"
                        log1(_45, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:10539:10572  "TokenTreasuryShareUpdated(_share)" */ 0x770a2b3172173f27549fe408b2b6c436ad5bbcb7f8be1f04fc48c3e5768a45af)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0xa138549b {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let _46 := and(abi_decode_address(), sub(shl(160, 1), 1))
                        mstore(_1, _46)
                        mstore(32, /** @src 11:19004:19014  "_overrides" */ 0x06)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let dataSlot_1 := keccak256(_1, 64)
                        mstore(_1, _46)
                        mstore(32, /** @src 11:19004:19014  "_overrides" */ 0x06)
                        /// @src 11:19033:19057  "_overrides[token].shares"
                        let _47 := add(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ keccak256(_1, 64), /** @src 11:19033:19057  "_overrides[token].shares" */ 1)
                        /// @src 11:18996:19058  "return (_overrides[token].receivers, _overrides[token].shares)"
                        let var_mpos_2 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_address_dyn(/** @src 11:18996:19058  "return (_overrides[token].receivers, _overrides[token].shares)" */ dataSlot_1)
                        let var_mpos_3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_uint8_dyn(/** @src 11:18996:19058  "return (_overrides[token].receivers, _overrides[token].shares)" */ _47)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let memPos_7 := mload(64)
                        return(memPos_7, sub(abi_encode_array_address_dyn_array_uint8_dyn(memPos_7, var_mpos_2, var_mpos_3), memPos_7))
                    }
                    case 0xab803a76 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let cleaned_6 := and(sload(/** @src 11:11898:11906  "treasury" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        /// @src 11:11898:11945  "treasury.call{value: address(this).balance}(\"\")"
                        let expr_component_1 := call(gas(), cleaned_6, /** @src 11:11919:11940  "address(this).balance" */ selfbalance(), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, _1, _1, _1)
                        /// @src 11:11898:11945  "treasury.call{value: address(this).balance}(\"\")"
                        let data := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1
                        switch returndatasize()
                        case 0 { data := 96 }
                        default {
                            let _48 := returndatasize()
                            if gt(_48, 0xffffffffffffffff)
                            {
                                mstore(_1, shl(224, 0x4e487b71))
                                mstore(4, 0x41)
                                revert(_1, 0x24)
                            }
                            let memPtr := mload(64)
                            finalize_allocation(memPtr, add(and(add(_48, 31), not(31)), 0x20))
                            mstore(memPtr, _48)
                            data := memPtr
                            returndatacopy(add(memPtr, 0x20), _1, returndatasize())
                        }
                        if iszero(expr_component_1)
                        {
                            let memPtr_1 := mload(64)
                            mstore(memPtr_1, shl(229, 4594637))
                            mstore(add(memPtr_1, 4), 32)
                            mstore(add(memPtr_1, 36), 19)
                            mstore(add(memPtr_1, 68), "native sweep failed")
                            revert(memPtr_1, 100)
                        }
                        return(_1, _1)
                    }
                    case 0xce9c0bb7 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value_2 := calldataload(4)
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:10078:10125  "if (_share > 100) revert InvalidProtocolShare()"
                        if /** @src 11:10082:10094  "_share > 100" */ gt(value_2, /** @src 11:10091:10094  "100" */ 0x64)
                        /// @src 11:10078:10125  "if (_share > 100) revert InvalidProtocolShare()"
                        {
                            /// @src 11:10103:10125  "InvalidProtocolShare()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 11:10103:10125  "InvalidProtocolShare()" */ shl(226, 0x079fbb7f))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 4)
                        }
                        sstore(/** @src 11:10135:10157  "protocolShare = _share" */ 0x03, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ value_2)
                        /// @src 11:10172:10200  "ProtocolShareUpdated(_share)"
                        let _49 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        mstore(_49, value_2)
                        /// @src 11:10172:10200  "ProtocolShareUpdated(_share)"
                        log1(_49, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:10172:10200  "ProtocolShareUpdated(_share)" */ 0xd82bf55fab0a06d972b148305a6b58062e33e048f53695742fc3e9f075852592)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0xd7b96d4e {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let memPos_8 := mload(64)
                        mstore(memPos_8, and(/** @src 11:5088:5125  "ILaunchLocker public immutable locker" */ loadimmutable("113"), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)))
                        return(memPos_8, 32)
                    }
                    case 0xdcbccc8a {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), _1) { revert(_1, _1) }
                        let _50 := sload(4)
                        let memPos_9 := mload(64)
                        mstore(memPos_9, _50)
                        return(memPos_9, 32)
                    }
                    case 0xe1a67bf7 {
                        if callvalue() { revert(_1, _1) }
                        let param_5, param_6, param_7, param_8, param_9 := abi_decode_addresst_array_address_dyn_calldatat_array_uint8_dyn_calldata(calldatasize())
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:11031:11037  "shares"
                        fun_validateShareConfig(param_6, param_7, param_8, param_9)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _51 := and(param_5, sub(shl(160, 1), 1))
                        mstore(_1, _51)
                        mstore(0x20, /** @src 11:11069:11079  "_overrides" */ 0x06)
                        /// @src 11:11048:11106  "_storeReceiverConfig(_overrides[token], receivers, shares)"
                        fun_storeReceiverConfig(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ keccak256(_1, 64), /** @src 11:11048:11106  "_storeReceiverConfig(_overrides[token], receivers, shares)" */ param_6, param_7, param_8, param_9)
                        /// @src 11:11121:11166  "ConfigUpdated(token, true, receivers, shares)"
                        let _52 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        /// @src 11:11121:11166  "ConfigUpdated(token, true, receivers, shares)"
                        log3(_52, sub(abi_encode_array_address_dyn_calldata_array_uint8_dyn_calldata(_52, param_6, param_7, param_8, param_9), _52), 0x7c75122b2871a91e189a762c2400b0ac22d1261162795bdce11a676ca010efba, _51, /** @src 11:11142:11146  "true" */ 0x01)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0xe96a4d76 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value0_8 := abi_decode_address()
                        let memPtr_2 := mload(64)
                        let newFreePtr := add(memPtr_2, 128)
                        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr_2))
                        {
                            mstore(/** @src -1:-1:-1 */ _1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                            mstore(4, 0x41)
                            revert(/** @src -1:-1:-1 */ _1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                        }
                        mstore(64, newFreePtr)
                        mstore(memPtr_2, _1)
                        let offset := add(memPtr_2, 32)
                        mstore(offset, 96)
                        let _53 := add(memPtr_2, 64)
                        mstore(_53, 96)
                        let _54 := add(memPtr_2, 96)
                        mstore(_54, _1)
                        /// @src 11:18560:18581  "_getLaunchData(token)"
                        let expr_component_mpos_2, expr_component_mpos_3, expr_component_2 := fun_getLaunchData(value0_8)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        mstore(memPtr_2, sload(/** @src 11:18615:18628  "protocolShare" */ 0x03))
                        /// @src 11:18638:18667  "routing.receivers = receivers"
                        mstore(/** @src 11:18638:18655  "routing.receivers" */ offset, /** @src 11:18638:18667  "routing.receivers = receivers" */ expr_component_mpos_2)
                        /// @src 11:18677:18704  "routing.percents = percents"
                        mstore(/** @src 11:18677:18693  "routing.percents" */ _53, /** @src 11:18677:18704  "routing.percents = percents" */ expr_component_mpos_3)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        mstore(_54, iszero(iszero(expr_component_2)))
                        let memPos_10 := mload(64)
                        mstore(memPos_10, 32)
                        let tail := add(memPos_10, 160)
                        mstore(add(memPos_10, 32), mload(memPtr_2))
                        let memberValue0 := mload(offset)
                        mstore(add(memPos_10, 64), 128)
                        let pos_10 := tail
                        let length := mload(memberValue0)
                        mstore(tail, length)
                        pos_10 := add(memPos_10, 192)
                        let srcPtr := add(memberValue0, 32)
                        let i := _1
                        for { } lt(i, length) { i := add(i, 1) }
                        {
                            mstore(pos_10, and(mload(srcPtr), sub(shl(160, 1), 1)))
                            pos_10 := add(pos_10, 32)
                            srcPtr := add(srcPtr, 32)
                        }
                        let memberValue0_1 := mload(_53)
                        mstore(add(memPos_10, 96), add(sub(pos_10, memPos_10), not(31)))
                        let pos_11 := pos_10
                        let length_1 := mload(memberValue0_1)
                        mstore(pos_10, length_1)
                        pos_11 := add(pos_10, 32)
                        let srcPtr_1 := add(memberValue0_1, 32)
                        let i_1 := _1
                        for { } lt(i_1, length_1) { i_1 := add(i_1, 1) }
                        {
                            mstore(pos_11, and(mload(srcPtr_1), 0xff))
                            pos_11 := add(pos_11, 32)
                            srcPtr_1 := add(srcPtr_1, 32)
                        }
                        mstore(add(memPos_10, 128), iszero(iszero(mload(_54))))
                        return(memPos_10, sub(pos_11, memPos_10))
                    }
                    case 0xf0f44260 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value0_9 := abi_decode_address()
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _55 := and(/** @src 11:9759:9782  "_treasury == address(0)" */ value0_9, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        /// @src 11:9755:9804  "if (_treasury == address(0)) revert ZeroAddress()"
                        if /** @src 11:9759:9782  "_treasury == address(0)" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _55)
                        /// @src 11:9755:9804  "if (_treasury == address(0)) revert ZeroAddress()"
                        {
                            /// @src 11:9791:9804  "ZeroAddress()"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 11:9791:9804  "ZeroAddress()" */ shl(224, 0xd92e233d))
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 4)
                        }
                        sstore(/** @src 11:9814:9834  "treasury = _treasury" */ 0x02, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ or(and(sload(/** @src 11:9814:9834  "treasury = _treasury" */ 0x02), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(160, 0xffffffffffffffffffffffff)), _55))
                        /// @src 11:9849:9875  "TreasuryUpdated(_treasury)"
                        let _56 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                        mstore(_56, _55)
                        /// @src 11:9849:9875  "TreasuryUpdated(_treasury)"
                        log1(_56, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 32, /** @src 11:9849:9875  "TreasuryUpdated(_treasury)" */ 0x7dae230f18360d76a040c81f050aa14eb9d6dc7901b20fc5d855e2a20fe814d1)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0xf2fde38b {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value0_10 := abi_decode_address()
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _57 := and(/** @src 0:2627:2649  "newOwner == address(0)" */ value0_10, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                        /// @src 0:2623:2714  "if (newOwner == address(0)) {..."
                        if /** @src 0:2627:2649  "newOwner == address(0)" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _57)
                        /// @src 0:2623:2714  "if (newOwner == address(0)) {..."
                        {
                            /// @src 0:2672:2703  "OwnableInvalidOwner(address(0))"
                            mstore(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, /** @src 0:2672:2703  "OwnableInvalidOwner(address(0))" */ shl(224, 0x1e4fbdf7))
                            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                            mstore(4, _1)
                            /// @src 0:2672:2703  "OwnableInvalidOwner(address(0))"
                            revert(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, 36)
                        }
                        let _58 := sload(/** @src 0:3004:3010  "_owner" */ _1)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        sstore(/** @src 0:3004:3010  "_owner" */ _1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ or(and(_58, shl(160, 0xffffffffffffffffffffffff)), _57))
                        /// @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)"
                        log3(/** @src 0:3004:3010  "_owner" */ _1, _1, /** @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)" */ 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(_58, sub(shl(160, 1), 1)), /** @src 0:3052:3092  "OwnershipTransferred(oldOwner, newOwner)" */ _57)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                    case 0xfff6ec61 {
                        if callvalue() { revert(_1, _1) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_1, _1) }
                        let value0_11 := abi_decode_address()
                        /// @src 0:1500:1562  "modifier onlyOwner() {..."
                        fun_checkOwner()
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let _59 := and(value0_11, sub(shl(160, 1), 1))
                        mstore(_1, _59)
                        mstore(32, /** @src 11:11353:11363  "_overrides" */ 0x06)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let dataSlot_2 := keccak256(_1, 64)
                        storage_set_to_zero_array_address_dyn(dataSlot_2)
                        storage_set_to_zero_array_uint8_dyn(add(dataSlot_2, 1))
                        /// @src 11:11385:11407  "OverrideCleared(token)"
                        log2(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1, _1, /** @src 11:11385:11407  "OverrideCleared(token)" */ 0x6e432ad4ea7d000b53a53e6b725af5b8fbac86f7797aee9cbd38020c9a63ea39, _59)
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        return(_1, _1)
                    }
                }
                if iszero(calldatasize()) { stop() }
                revert(0, 0)
            }
            function abi_decode_address() -> value
            {
                value := calldataload(4)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
            }
            function abi_encode_array_address_dyn_array_uint8_dyn(headStart, value0, value1) -> tail
            {
                let tail_1 := add(headStart, 64)
                mstore(headStart, 64)
                let pos := tail_1
                let length := mload(value0)
                mstore(tail_1, length)
                pos := add(headStart, 96)
                let srcPtr := add(value0, 0x20)
                let i := 0
                for { } lt(i, length) { i := add(i, 1) }
                {
                    mstore(pos, and(mload(srcPtr), sub(shl(160, 1), 1)))
                    pos := add(pos, 0x20)
                    srcPtr := add(srcPtr, 0x20)
                }
                mstore(add(headStart, 0x20), sub(pos, headStart))
                let pos_1 := pos
                let length_1 := mload(value1)
                mstore(pos, length_1)
                pos_1 := add(pos, 0x20)
                let srcPtr_1 := add(value1, 0x20)
                let i_1 := 0
                for { } lt(i_1, length_1) { i_1 := add(i_1, 1) }
                {
                    mstore(pos_1, and(mload(srcPtr_1), 0xff))
                    pos_1 := add(pos_1, 0x20)
                    srcPtr_1 := add(srcPtr_1, 0x20)
                }
                tail := pos_1
            }
            function abi_decode_array_address_dyn_calldata(offset, end) -> arrayPos, length
            {
                if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
                length := calldataload(offset)
                if gt(length, 0xffffffffffffffff) { revert(0, 0) }
                arrayPos := add(offset, 0x20)
                if gt(add(add(offset, shl(5, length)), 0x20), end) { revert(0, 0) }
            }
            function abi_decode_addresst_array_address_dyn_calldatat_array_uint8_dyn_calldata(dataEnd) -> value0, value1, value2, value3, value4
            {
                if slt(add(dataEnd, not(3)), 96) { revert(0, 0) }
                let value := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                value := calldataload(4)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
                value0 := value
                let offset := calldataload(36)
                if gt(offset, 0xffffffffffffffff) { revert(0, 0) }
                let value1_1, value2_1 := abi_decode_array_address_dyn_calldata(add(4, offset), dataEnd)
                value1 := value1_1
                value2 := value2_1
                let offset_1 := calldataload(68)
                if gt(offset_1, 0xffffffffffffffff) { revert(0, 0) }
                let value3_1, value4_1 := abi_decode_array_address_dyn_calldata(add(4, offset_1), dataEnd)
                value3 := value3_1
                value4 := value4_1
            }
            function finalize_allocation(memPtr, size)
            {
                let newFreePtr := add(memPtr, and(add(size, 31), not(31)))
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                    mstore(4, 0x41)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                }
                mstore(64, newFreePtr)
            }
            function abi_decode_address_fromMemory(offset) -> value
            {
                value := mload(offset)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
            }
            function abi_decode_bool_fromMemory(offset) -> value
            {
                value := mload(offset)
                if iszero(eq(value, iszero(iszero(value)))) { revert(0, 0) }
            }
            function abi_decode_struct_LaunchInfo_fromMemory(headStart, dataEnd) -> value0
            {
                let _1 := slt(sub(dataEnd, headStart), 416)
                if _1 { revert(0, 0) }
                _1 := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let memPtr := mload(64)
                let newFreePtr := add(memPtr, 416)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                    mstore(4, 0x41)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                }
                mstore(64, newFreePtr)
                mstore(memPtr, abi_decode_address_fromMemory(headStart))
                mstore(add(memPtr, 32), abi_decode_address_fromMemory(add(headStart, 32)))
                mstore(add(memPtr, 64), abi_decode_address_fromMemory(add(headStart, 64)))
                mstore(add(memPtr, 96), abi_decode_address_fromMemory(add(headStart, 96)))
                mstore(add(memPtr, 128), mload(add(headStart, 128)))
                mstore(add(memPtr, 160), mload(add(headStart, 160)))
                mstore(add(memPtr, 192), mload(add(headStart, 192)))
                mstore(add(memPtr, 224), mload(add(headStart, 224)))
                mstore(add(memPtr, 256), mload(add(headStart, 256)))
                mstore(add(memPtr, 288), abi_decode_bool_fromMemory(add(headStart, 288)))
                let value := mload(add(headStart, 320))
                if iszero(eq(value, and(value, 0xffffff)))
                {
                    revert(/** @src -1:-1:-1 */ 0, 0)
                }
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                mstore(add(memPtr, 320), value)
                mstore(add(memPtr, 352), abi_decode_bool_fromMemory(add(headStart, 352)))
                mstore(add(memPtr, 384), mload(add(headStart, 384)))
                value0 := memPtr
            }
            function checked_sub_uint256(x, y) -> diff
            {
                diff := sub(x, y)
                if gt(diff, x)
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            function checked_mul_uint256(x, y) -> product
            {
                product := mul(x, y)
                if iszero(or(iszero(x), eq(y, div(product, x))))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            function memory_array_index_access_uint8_dyn(baseRef) -> addr
            {
                if iszero(mload(baseRef))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                addr := add(baseRef, 32)
            }
            function memory_array_index_access_array_uint8_dyn(baseRef, index) -> addr
            {
                if iszero(lt(index, mload(baseRef)))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                addr := add(add(baseRef, shl(5, index)), 32)
            }
            function checked_add_uint256(x, y) -> sum
            {
                sum := add(x, y)
                if gt(x, sum)
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            function copy_array_from_storage_to_memory_array_address_dyn(slot) -> memPtr
            {
                memPtr := mload(64)
                let pos := memPtr
                let length := sload(slot)
                mstore(memPtr, length)
                pos := add(memPtr, 0x20)
                mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ slot)
                let srcPtr := keccak256(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                let i := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                for { } lt(i, length) { i := add(i, 1) }
                {
                    mstore(pos, and(sload(srcPtr), sub(shl(160, 1), 1)))
                    pos := add(pos, 0x20)
                    srcPtr := add(srcPtr, 1)
                }
                finalize_allocation(memPtr, sub(pos, memPtr))
            }
            function copy_array_from_storage_to_memory_array_uint8_dyn(slot) -> memPtr
            {
                memPtr := mload(64)
                let pos := memPtr
                let length := sload(slot)
                mstore(memPtr, length)
                pos := add(memPtr, 0x20)
                mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ slot)
                let srcPtr := keccak256(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                let itemCounter := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                for { }
                lt(add(itemCounter, 31), length)
                {
                    itemCounter := add(itemCounter, 0x20)
                }
                {
                    let data := sload(srcPtr)
                    mstore(pos, and(data, 0xff))
                    mstore(add(pos, 0x20), and(shr(8, data), 0xff))
                    mstore(add(pos, 64), and(shr(16, data), 0xff))
                    mstore(add(pos, 96), and(shr(24, data), 0xff))
                    mstore(add(pos, 128), and(shr(0x20, data), 0xff))
                    mstore(add(pos, 160), and(shr(40, data), 0xff))
                    mstore(add(pos, 192), and(shr(48, data), 0xff))
                    mstore(add(pos, 224), and(shr(56, data), 0xff))
                    mstore(add(pos, 256), and(shr(64, data), 0xff))
                    mstore(add(pos, 288), and(shr(72, data), 0xff))
                    mstore(add(pos, 320), and(shr(80, data), 0xff))
                    mstore(add(pos, 352), and(shr(88, data), 0xff))
                    mstore(add(pos, 384), and(shr(96, data), 0xff))
                    mstore(add(pos, 416), and(shr(104, data), 0xff))
                    mstore(add(pos, 448), and(shr(112, data), 0xff))
                    mstore(add(pos, 480), and(shr(120, data), 0xff))
                    mstore(add(pos, 512), and(shr(128, data), 0xff))
                    mstore(add(pos, 544), and(shr(136, data), 0xff))
                    mstore(add(pos, 576), and(shr(144, data), 0xff))
                    mstore(add(pos, 608), and(shr(152, data), 0xff))
                    mstore(add(pos, 640), and(shr(160, data), 0xff))
                    mstore(add(pos, 672), and(shr(168, data), 0xff))
                    mstore(add(pos, 704), and(shr(176, data), 0xff))
                    mstore(add(pos, 736), and(shr(184, data), 0xff))
                    mstore(add(pos, 768), and(shr(192, data), 0xff))
                    mstore(add(pos, 800), and(shr(200, data), 0xff))
                    mstore(add(pos, 832), and(shr(208, data), 0xff))
                    mstore(add(pos, 864), and(shr(216, data), 0xff))
                    mstore(add(pos, 896), and(shr(224, data), 0xff))
                    mstore(add(pos, 928), and(shr(232, data), 0xff))
                    mstore(add(pos, 960), and(shr(240, data), 0xff))
                    mstore(add(pos, 992), shr(248, data))
                    pos := add(pos, 1024)
                    srcPtr := add(srcPtr, 1)
                }
                let data_1 := sload(srcPtr)
                if lt(itemCounter, length)
                {
                    mstore(pos, and(data_1, 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(8, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(16, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(24, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(0x20, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(40, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(48, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(56, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(64, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(72, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(80, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(88, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(96, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(104, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(112, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(120, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(128, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(136, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(144, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(152, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(160, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(168, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(176, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(184, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(192, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(200, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(208, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(216, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(224, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(232, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, and(shr(240, data_1), 0xff))
                    pos := add(pos, 0x20)
                    itemCounter := add(itemCounter, 1)
                }
                if lt(itemCounter, length)
                {
                    mstore(pos, shr(248, data_1))
                    pos := add(pos, 0x20)
                }
                finalize_allocation(memPtr, sub(pos, memPtr))
            }
            function abi_encode_array_address_dyn_calldata_array_uint8_dyn_calldata(headStart, value0, value1, value2, value3) -> tail
            {
                let tail_1 := add(headStart, 64)
                mstore(headStart, 64)
                let pos := tail_1
                mstore(tail_1, value1)
                pos := add(headStart, 96)
                let srcPtr := value0
                let i := 0
                for { } lt(i, value1) { i := add(i, 1) }
                {
                    let value := /** @src -1:-1:-1 */ 0
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    value := calldataload(srcPtr)
                    if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
                    mstore(pos, and(value, sub(shl(160, 1), 1)))
                    pos := add(pos, 0x20)
                    srcPtr := add(srcPtr, 0x20)
                }
                mstore(add(headStart, 0x20), sub(pos, headStart))
                let pos_1 := pos
                mstore(pos, value3)
                pos_1 := add(pos, 0x20)
                let srcPtr_1 := value2
                let i_1 := 0
                for { } lt(i_1, value3) { i_1 := add(i_1, 1) }
                {
                    let value_1 := calldataload(srcPtr_1)
                    let _1 := and(value_1, 0xff)
                    if iszero(eq(value_1, _1)) { revert(0, 0) }
                    mstore(pos_1, _1)
                    pos_1 := add(pos_1, 0x20)
                    srcPtr_1 := add(srcPtr_1, 0x20)
                }
                tail := pos_1
            }
            function clear_storage_range_address(start, end)
            {
                for { } lt(start, end) { start := add(start, 1) }
                { sstore(start, 0) }
            }
            function storage_set_to_zero_array_address_dyn(slot)
            {
                let offset := 0
                offset := 0
                let oldLen := sload(slot)
                sstore(slot, /** @src -1:-1:-1 */ 0)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                if iszero(iszero(oldLen))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ slot)
                    let data := keccak256(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                    clear_storage_range_address(data, add(data, oldLen))
                }
            }
            function storage_set_to_zero_array_uint8_dyn(slot)
            {
                let offset := 0
                offset := 0
                let oldLen := sload(slot)
                sstore(slot, /** @src -1:-1:-1 */ 0)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                if iszero(iszero(oldLen))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ slot)
                    let data := keccak256(/** @src -1:-1:-1 */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                    clear_storage_range_address(data, add(data, shr(5, add(oldLen, 31))))
                }
            }
            /// @ast-id 1294 @src 0:1796:1958  "function _checkOwner() internal view virtual {..."
            function fun_checkOwner()
            {
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let cleaned := and(sload(/** @src 0:1710:1716  "_owner" */ 0x00), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                /// @src 0:1851:1952  "if (owner() != _msgSender()) {..."
                if /** @src 0:1855:1878  "owner() != _msgSender()" */ iszero(eq(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ cleaned, /** @src 7:735:745  "msg.sender" */ caller()))
                /// @src 0:1851:1952  "if (owner() != _msgSender()) {..."
                {
                    /// @src 0:1901:1941  "OwnableUnauthorizedAccount(_msgSender())"
                    mstore(/** @src 0:1710:1716  "_owner" */ 0x00, /** @src 0:1901:1941  "OwnableUnauthorizedAccount(_msgSender())" */ shl(224, 0x118cdaa7))
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    mstore(/** @src 0:1901:1941  "OwnableUnauthorizedAccount(_msgSender())" */ 4, /** @src 7:735:745  "msg.sender" */ caller())
                    /// @src 0:1901:1941  "OwnableUnauthorizedAccount(_msgSender())"
                    revert(/** @src 0:1710:1716  "_owner" */ 0x00, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 36)
                }
            }
            /// @ast-id 1404 @src 5:1271:1431  "function safeTransfer(IERC20 token, address to, uint256 value) internal {..."
            function fun_safeTransfer(var_token_address, var_to, var_value)
            {
                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                let expr_1400_mpos := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(64)
                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                let _1 := add(expr_1400_mpos, 0x20)
                mstore(_1, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0xa9059cbb))
                mstore(/** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ add(expr_1400_mpos, 36), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(var_to, sub(shl(160, 1), 1)))
                mstore(add(/** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ expr_1400_mpos, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 68), var_value)
                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                mstore(expr_1400_mpos, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 68)
                /// @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))"
                finalize_allocation(expr_1400_mpos, 100)
                /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                if iszero(call(gas(), var_token_address, /** @src -1:-1:-1 */ 0, /** @src 5:7875:8296  "assembly (\"memory-safe\") {..." */ _1, mload(expr_1400_mpos), /** @src -1:-1:-1 */ 0, /** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ 0x20))
                /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                {
                    let usr$ptr := mload(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 64)
                    /// @src 5:7875:8296  "assembly (\"memory-safe\") {..."
                    returndatacopy(usr$ptr, /** @src -1:-1:-1 */ 0, /** @src 5:7875:8296  "assembly (\"memory-safe\") {..." */ returndatasize())
                    revert(usr$ptr, returndatasize())
                }
                let var_returnSize := returndatasize()
                let var_returnValue := mload(/** @src -1:-1:-1 */ 0)
                /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                let expr := /** @src -1:-1:-1 */ 0
                /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                switch /** @src 5:8310:8325  "returnSize == 0" */ iszero(var_returnSize)
                case /** @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1" */ 0 {
                    expr := /** @src 5:8362:8378  "returnValue != 1" */ iszero(eq(var_returnValue, /** @src 5:8377:8378  "1" */ 0x01))
                }
                default /// @src 5:8310:8378  "returnSize == 0 ? address(token).code.length == 0 : returnValue != 1"
                {
                    expr := /** @src 5:8328:8359  "address(token).code.length == 0" */ iszero(/** @src 5:8328:8354  "address(token).code.length" */ extcodesize(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 5:8328:8342  "address(token)" */ var_token_address, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))))
                }
                /// @src 5:8306:8452  "if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {..."
                if expr
                {
                    /// @src 5:8401:8441  "SafeERC20FailedOperation(address(token))"
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 5:8401:8441  "SafeERC20FailedOperation(address(token))" */ shl(224, 0x5274afe7))
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    mstore(/** @src 5:8401:8441  "SafeERC20FailedOperation(address(token))" */ 4, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 5:8426:8440  "address(token)" */ var_token_address, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)))
                    /// @src 5:8401:8441  "SafeERC20FailedOperation(address(token))"
                    revert(/** @src -1:-1:-1 */ 0, /** @src 5:1380:1423  "abi.encodeCall(token.transfer, (to, value))" */ 36)
                }
            }
            /// @ast-id 1065 @src 11:19867:21130  "function _getLaunchData(address token)..."
            function fun_getLaunchData(var_token) -> var_receivers_mpos, var_shares_mpos, var_isOverridden
            {
                /// @src 11:20043:20065  "bool      isOverridden"
                var_isOverridden := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                let _1 := and(var_token, sub(shl(160, 1), 1))
                mstore(0, _1)
                mstore(0x20, /** @src 11:20167:20177  "_overrides" */ 0x06)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let dataSlot := keccak256(0, 0x40)
                /// @src 11:20194:20371  "if (override_.receivers.length > 0) {..."
                if /** @src 11:20198:20228  "override_.receivers.length > 0" */ iszero(iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sload(/** @src 11:20198:20224  "override_.receivers.length" */ dataSlot)))
                /// @src 11:20194:20371  "if (override_.receivers.length > 0) {..."
                {
                    /// @src 11:20244:20275  "receivers = override_.receivers"
                    let var_receivers_mpos_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_address_dyn(/** @src 11:20244:20275  "receivers = override_.receivers" */ dataSlot)
                    /// @src 11:20289:20314  "shares = override_.shares"
                    let var_shares_mpos_1 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_uint8_dyn(/** @src 11:20298:20314  "override_.shares" */ add(dataSlot, 1))
                    /// @src 11:20328:20360  "return (receivers, shares, true)"
                    var_receivers_mpos := var_receivers_mpos_1
                    var_shares_mpos := var_shares_mpos_1
                    var_isOverridden := /** @src 11:20298:20314  "override_.shares" */ 1
                    /// @src 11:20328:20360  "return (receivers, shares, true)"
                    leave
                }
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                mstore(0, _1)
                mstore(0x20, /** @src 11:20456:20464  "_configs" */ 0x05)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let dataSlot_1 := keccak256(0, 0x40)
                /// @src 11:20481:20653  "if (config_.receivers.length > 0) {..."
                if /** @src 11:20485:20513  "config_.receivers.length > 0" */ iszero(iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sload(/** @src 11:20485:20509  "config_.receivers.length" */ dataSlot_1)))
                /// @src 11:20481:20653  "if (config_.receivers.length > 0) {..."
                {
                    /// @src 11:20529:20558  "receivers = config_.receivers"
                    let var_receivers_mpos_2 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_address_dyn(/** @src 11:20529:20558  "receivers = config_.receivers" */ dataSlot_1)
                    /// @src 11:20572:20595  "shares = config_.shares"
                    let var_shares_mpos_2 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ copy_array_from_storage_to_memory_array_uint8_dyn(/** @src 11:20581:20595  "config_.shares" */ add(dataSlot_1, 1))
                    /// @src 11:20609:20642  "return (receivers, shares, false)"
                    var_receivers_mpos := var_receivers_mpos_2
                    var_shares_mpos := var_shares_mpos_2
                    var_isOverridden := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                    /// @src 11:20609:20642  "return (receivers, shares, false)"
                    leave
                }
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let _2 := and(/** @src 11:20745:20751  "locker" */ loadimmutable("113"), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1))
                /// @src 11:20745:20767  "locker.getToken(token)"
                let _3 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(0x40)
                /// @src 11:20745:20767  "locker.getToken(token)"
                mstore(_3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x6e73c061))
                mstore(/** @src 11:20745:20767  "locker.getToken(token)" */ add(_3, 4), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1)
                /// @src 11:20745:20767  "locker.getToken(token)"
                let _4 := staticcall(gas(), _2, _3, 36, _3, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                /// @src 11:20745:20767  "locker.getToken(token)"
                if iszero(_4)
                {
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    let pos := mload(0x40)
                    returndatacopy(pos, 0, returndatasize())
                    revert(pos, returndatasize())
                }
                /// @src 11:20745:20767  "locker.getToken(token)"
                let expr := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                /// @src 11:20745:20767  "locker.getToken(token)"
                if _4
                {
                    let _5 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20
                    /// @src 11:20745:20767  "locker.getToken(token)"
                    if gt(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20, /** @src 11:20745:20767  "locker.getToken(token)" */ returndatasize()) { _5 := returndatasize() }
                    finalize_allocation(_3, _5)
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    if slt(sub(/** @src 11:20745:20767  "locker.getToken(token)" */ add(_3, _5), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _3), 0x20) { revert(0, 0) }
                    /// @src 11:20745:20767  "locker.getToken(token)"
                    expr := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ abi_decode_address_fromMemory(_3)
                }
                /// @src 11:20724:20767  "address tokenOwner = locker.getToken(token)"
                let var_tokenOwner := expr
                /// @src 11:20777:20992  "if (tokenOwner == address(0)) {..."
                if /** @src 11:20781:20805  "tokenOwner == address(0)" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:20781:20805  "tokenOwner == address(0)" */ expr, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)))
                /// @src 11:20777:20992  "if (tokenOwner == address(0)) {..."
                {
                    /// @src 11:20911:20941  "locker.getLaunchedToken(token)"
                    let _6 := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ mload(0x40)
                    /// @src 11:20911:20941  "locker.getLaunchedToken(token)"
                    mstore(_6, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(225, 0x1e7945ad))
                    mstore(/** @src 11:20911:20941  "locker.getLaunchedToken(token)" */ add(_6, /** @src 11:20745:20767  "locker.getToken(token)" */ 4), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1)
                    /// @src 11:20911:20941  "locker.getLaunchedToken(token)"
                    let _7 := staticcall(gas(), _2, _6, /** @src 11:20745:20767  "locker.getToken(token)" */ 36, /** @src 11:20911:20941  "locker.getLaunchedToken(token)" */ _6, 416)
                    if iszero(_7)
                    {
                        /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                        let pos_1 := mload(0x40)
                        returndatacopy(pos_1, 0, returndatasize())
                        revert(pos_1, returndatasize())
                    }
                    /// @src 11:20911:20941  "locker.getLaunchedToken(token)"
                    let expr_mpos := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0
                    /// @src 11:20911:20941  "locker.getLaunchedToken(token)"
                    if _7
                    {
                        let _8 := 416
                        if gt(_8, returndatasize()) { _8 := returndatasize() }
                        finalize_allocation(_6, _8)
                        expr_mpos := abi_decode_struct_LaunchInfo_fromMemory(_6, add(_6, _8))
                    }
                    /// @src 11:20955:20981  "tokenOwner = info.deployer"
                    var_tokenOwner := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(mload(/** @src 11:20968:20981  "info.deployer" */ add(expr_mpos, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)), sub(shl(160, 1), 1))
                }
                let size := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let _9 := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                _9 := /** @src -1:-1:-1 */ 0
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                size := 64
                let memPtr := mload(size)
                finalize_allocation(memPtr, size)
                mstore(memPtr, /** @src 11:21028:21029  "1" */ 0x01)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let _10 := add(size, not(31))
                calldatacopy(add(memPtr, 0x20), calldatasize(), _10)
                /// @src 11:21002:21030  "receivers = new address[](1)"
                var_receivers_mpos := memPtr
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                let memPtr_1 := mload(size)
                finalize_allocation(memPtr_1, size)
                mstore(memPtr_1, /** @src 11:21028:21029  "1" */ 0x01)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                calldatacopy(add(memPtr_1, 0x20), calldatasize(), _10)
                /// @src 11:21040:21063  "shares = new uint8[](1)"
                var_shares_mpos := memPtr_1
                /// @src 11:21073:21098  "receivers[0] = tokenOwner"
                let _11 := memory_array_index_access_uint8_dyn(memPtr)
                /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                mstore(_11, and(var_tokenOwner, sub(shl(160, 1), 1)))
                mstore(/** @src 11:21108:21123  "shares[0] = 100" */ memory_array_index_access_uint8_dyn(memPtr_1), /** @src 11:21120:21123  "100" */ 0x64)
            }
            /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
            function calldata_array_index_access_address_dyn_calldata(base_ref, length, index) -> addr
            {
                if iszero(lt(index, length))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                addr := add(base_ref, shl(5, index))
            }
            function read_from_calldatat_address(ptr) -> returnValue
            {
                let value := calldataload(ptr)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
                returnValue := value
            }
            function read_from_calldatat_uint8(ptr) -> returnValue
            {
                let value := calldataload(ptr)
                if iszero(eq(value, and(value, 0xff))) { revert(0, 0) }
                returnValue := value
            }
            /// @ast-id 1148 @src 11:21371:21960  "function _validateShareConfig(..."
            function fun_validateShareConfig(var_receivers_offset, var_receivers_1069_length, var_shares_offset, var_shares_1072_length)
            {
                /// @src 11:21508:21565  "receivers.length == 0 || receivers.length > MAX_RECEIVERS"
                let expr := /** @src 11:21508:21529  "receivers.length == 0" */ iszero(var_receivers_1069_length)
                /// @src 11:21508:21565  "receivers.length == 0 || receivers.length > MAX_RECEIVERS"
                if iszero(expr)
                {
                    expr := /** @src 11:21533:21565  "receivers.length > MAX_RECEIVERS" */ gt(var_receivers_1069_length, /** @src 11:4616:4618  "10" */ 0x0a)
                }
                /// @src 11:21504:21588  "if (receivers.length == 0 || receivers.length > MAX_RECEIVERS) revert InvalidSplit()"
                if expr
                {
                    /// @src 11:21574:21588  "InvalidSplit()"
                    mstore(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ shl(224, 0xbcd55b0f))
                    revert(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ 4)
                }
                /// @src 11:21598:21658  "if (shares.length != receivers.length) revert InvalidSplit()"
                if /** @src 11:21602:21635  "shares.length != receivers.length" */ iszero(eq(/** @src 11:21602:21615  "shares.length" */ var_shares_1072_length, /** @src 11:21602:21635  "shares.length != receivers.length" */ var_receivers_1069_length))
                /// @src 11:21598:21658  "if (shares.length != receivers.length) revert InvalidSplit()"
                {
                    /// @src 11:21644:21658  "InvalidSplit()"
                    mstore(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ shl(224, 0xbcd55b0f))
                    /// @src 11:21644:21658  "InvalidSplit()"
                    revert(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21644:21658  "InvalidSplit()" */ 4)
                }
                /// @src 11:21669:21682  "uint256 total"
                let var_total := /** @src 11:21528:21529  "0" */ 0x00
                /// @src 11:21669:21682  "uint256 total"
                var_total := /** @src 11:21528:21529  "0" */ 0x00
                /// @src 11:21697:21710  "uint256 i = 0"
                let var_i := /** @src 11:21528:21529  "0" */ 0x00
                /// @src 11:21692:21904  "for (uint256 i = 0; i < receivers.length; i++) {..."
                for { }
                /** @src 11:21712:21732  "i < receivers.length" */ lt(var_i, var_receivers_1069_length)
                /// @src 11:21697:21710  "uint256 i = 0"
                {
                    /// @src 11:21734:21737  "i++"
                    var_i := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ add(/** @src 11:21734:21737  "i++" */ var_i, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 1)
                }
                /// @src 11:21734:21737  "i++"
                {
                    /// @src 11:21753:21806  "if (receivers[i] == address(0)) revert InvalidSplit()"
                    if /** @src 11:21757:21783  "receivers[i] == address(0)" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:21757:21769  "receivers[i]" */ read_from_calldatat_address(calldata_array_index_access_address_dyn_calldata(var_receivers_offset, var_receivers_1069_length, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ sub(shl(160, 1), 1)))
                    /// @src 11:21753:21806  "if (receivers[i] == address(0)) revert InvalidSplit()"
                    {
                        /// @src 11:21792:21806  "InvalidSplit()"
                        mstore(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ shl(224, 0xbcd55b0f))
                        /// @src 11:21792:21806  "InvalidSplit()"
                        revert(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21792:21806  "InvalidSplit()" */ 4)
                    }
                    /// @src 11:21820:21861  "if (shares[i] == 0) revert InvalidSplit()"
                    if /** @src 11:21824:21838  "shares[i] == 0" */ iszero(/** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:21824:21833  "shares[i]" */ read_from_calldatat_uint8(calldata_array_index_access_address_dyn_calldata(var_shares_offset, var_shares_1072_length, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0xff))
                    /// @src 11:21820:21861  "if (shares[i] == 0) revert InvalidSplit()"
                    {
                        /// @src 11:21847:21861  "InvalidSplit()"
                        mstore(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ shl(224, 0xbcd55b0f))
                        /// @src 11:21847:21861  "InvalidSplit()"
                        revert(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21847:21861  "InvalidSplit()" */ 4)
                    }
                    /// @src 11:21875:21893  "total += shares[i]"
                    var_total := checked_add_uint256(var_total, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ and(/** @src 11:21884:21893  "shares[i]" */ read_from_calldatat_uint8(calldata_array_index_access_address_dyn_calldata(var_shares_offset, var_shares_1072_length, var_i)), /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0xff))
                }
                /// @src 11:21914:21953  "if (total != 100) revert InvalidSplit()"
                if /** @src 11:21918:21930  "total != 100" */ iszero(eq(var_total, /** @src 11:21927:21930  "100" */ 0x64))
                /// @src 11:21914:21953  "if (total != 100) revert InvalidSplit()"
                {
                    /// @src 11:21939:21953  "InvalidSplit()"
                    mstore(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21574:21588  "InvalidSplit()" */ shl(224, 0xbcd55b0f))
                    /// @src 11:21939:21953  "InvalidSplit()"
                    revert(/** @src 11:21528:21529  "0" */ 0x00, /** @src 11:21939:21953  "InvalidSplit()" */ 4)
                }
            }
            /// @ast-id 1203 @src 11:22041:22491  "function _storeReceiverConfig(..."
            function fun_storeReceiverConfig(var_config_slot, var_receivers_1155_offset, var_receivers_length, var_shares_1158_offset, var_shares_length)
            {
                /// @src 11:22242:22266  "delete config_.receivers"
                storage_set_to_zero_array_address_dyn(var_config_slot)
                /// @src 11:22283:22297  "config_.shares"
                let _1 := add(var_config_slot, 1)
                /// @src 11:22276:22297  "delete config_.shares"
                storage_set_to_zero_array_uint8_dyn(_1)
                /// @src 11:22338:22351  "uint256 i = 0"
                let var_i := /** @src 11:22249:22266  "config_.receivers" */ 0
                /// @src 11:22333:22485  "for (uint256 i = 0; i < receivers.length; i++) {..."
                for { }
                /** @src 11:22353:22373  "i < receivers.length" */ lt(var_i, /** @src 11:22357:22373  "receivers.length" */ var_receivers_length)
                /// @src 11:22338:22351  "uint256 i = 0"
                {
                    /// @src 11:22375:22378  "i++"
                    var_i := /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ add(/** @src 11:22375:22378  "i++" */ var_i, /** @src 11:22283:22297  "config_.shares" */ 1)
                }
                /// @src 11:22375:22378  "i++"
                {
                    /// @src 11:22417:22429  "receivers[i]"
                    let _2 := read_from_calldatat_address(calldata_array_index_access_address_dyn_calldata(var_receivers_1155_offset, var_receivers_length, var_i))
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    let oldLen := sload(var_config_slot)
                    if iszero(lt(oldLen, 18446744073709551616))
                    {
                        mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                        mstore(4, 0x41)
                        revert(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                    }
                    let _3 := add(oldLen, /** @src 11:22283:22297  "config_.shares" */ 1)
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    sstore(var_config_slot, _3)
                    if iszero(lt(oldLen, _3))
                    {
                        mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                        mstore(4, 0x32)
                        revert(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                    }
                    mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ var_config_slot)
                    let slot := add(keccak256(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20), oldLen)
                    sstore(slot, or(and(sload(slot), shl(160, 0xffffffffffffffffffffffff)), and(_2, sub(shl(160, 1), 1))))
                    /// @src 11:22464:22473  "shares[i]"
                    let _4 := read_from_calldatat_uint8(calldata_array_index_access_address_dyn_calldata(var_shares_1158_offset, var_shares_length, var_i))
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    let oldLen_1 := sload(_1)
                    if iszero(lt(oldLen_1, 18446744073709551616))
                    {
                        mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                        mstore(4, 0x41)
                        revert(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                    }
                    let _5 := add(oldLen_1, /** @src 11:22283:22297  "config_.shares" */ 1)
                    /// @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..."
                    sstore(_1, _5)
                    if iszero(lt(oldLen_1, _5))
                    {
                        mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ shl(224, 0x4e487b71))
                        mstore(4, 0x32)
                        revert(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x24)
                    }
                    mstore(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ _1)
                    let data := keccak256(/** @src 11:22249:22266  "config_.receivers" */ 0, /** @src 11:2937:23078  "contract NoxaManagerV116 is Ownable, ReentrancyGuard {..." */ 0x20)
                    let slot_1 := add(data, shr(5, oldLen_1))
                    let _6 := sload(slot_1)
                    let shiftBits := and(shl(3, oldLen_1), 248)
                    sstore(slot_1, or(and(_6, not(shl(shiftBits, 0xff))), shl(shiftBits, and(_4, 0xff))))
                }
            }
        }
        data ".metadata" hex"a164736f6c634300081e000a"
    }
}
