// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;
import {FheType, Operator} from "./FheType.sol";

interface IAlphatrionRewardSettlement {
    function distributeRevenue(address user, address token, address[] calldata recipients, uint256[] calldata amounts) external;
}

interface IFeeManager {
    function chargeFee(address user) external payable;
    function claimReward() external;
    function getClaimableReward(address account) external view returns (uint256);
    // DISABLED
    // function refundFee(address user, uint256 amount) external;
    // function balanceOfFee(address user) external view returns (uint256);
}

interface IExecutorAdmin {
    function setACL(address addr) external;
    function setAlphatrionReward(address _alphatrionReward) external;
    function setCiphertextVerification(address _ciphertextVerification) external;
    function setDecryption(address _decryption) external;
    function setSpaceBridgeConfig(address _spaceBridgeConfig) external;
    function setChainKeys(uint256[] calldata chainIds, uint8[] calldata chainKeys) external;
    function setOpBasePrices(Operator[] calldata ops, uint256[] calldata prices) external;
}

interface IExecutorView {
    function getACLAddress() external view returns (address);
    function getAlphatrionRewardAddress() external view returns (address);
    function getCiphertextVerificationAddress() external view returns (address);
    function getDecryptionAddress() external view returns (address);
    function getSpaceBridgeConfigAddress() external view returns (address);
    function getChainKeys(uint256[] calldata chainIds) external view returns (uint8[] memory chainKeys);

    function getHandleVersion() external pure returns (uint8);
    function getVersion() external pure returns (string memory);
}

interface IFHEExecutor {
    function fheAdd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheSub(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheMul(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheDiv(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheBitAnd(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheBitOr(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheBitXor(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheBitNot(bytes32 lhs) external returns (bytes32 result);
    function fheEq(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheNe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheGe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheGt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheLe(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheLt(bytes32 lhs, bytes32 rhs, bytes1 scalarByte) external returns (bytes32 result);
    function fheIfThenElse(bytes32 control, bytes32 ifTrue, bytes32 ifFalse) external returns (bytes32 result);

    function trivialEncrypt(uint256 ct, FheType toType) external returns (bytes32 result);
    function verifyAttestation(bytes32 inputHandle, address userAddress, bytes memory inputData, FheType inputType) external returns (bytes32 result);
    function fheCast(bytes32 ct, FheType toType) external returns (bytes32 result);
    // function cleanTransientStorage() external;
}
