// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "../constants/Errors.sol";

import {IAuthorizable, TxAuthData, VerifyManyData} from "../interfaces/IAccess.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/// @title Authorizable - A signature based transaction authorization mechanism
/// @notice This contract is used to authorize transactions using a signature
/// @dev See IAuthorizable for detailed interface documentation
/// @custom:security-contact security@accountable.capital
abstract contract Authorizable is IAuthorizable, EIP712 {
    /// @notice EIP-712 typehash for TxAuthData
    bytes32 private constant _TXAUTH_TYPEHASH = keccak256(
        "TxAuthData(bytes functionCallData,address contractAddress,address account,uint256 nonce,uint256 blockExpiration)"
    );

    constructor() EIP712("Authorizable", "1") {}

    /// @notice These are used to decompose msgData
    uint256 private constant _BYTES_32_LENGTH = 32;

    /// @notice This is the length for the expected signature
    uint256 private constant _SIGNATURE_LENGTH = 65;

    /// @notice The offset for the extra data in the calldata
    uint256 private constant _EXTRA_DATA_LENGTH = _SIGNATURE_LENGTH + _BYTES_32_LENGTH;

    /// @notice The address of the off-chain signer
    address public signer;

    /// @notice Mapping to track the nonces to prevent replay attacks
    /// @dev Maps a user address to their current nonce
    mapping(address user => uint256 nonce) public nonces;

    /// @inheritdoc IAuthorizable
    function setSigner(address signer_) public virtual {
        if (signer_ == address(0)) revert ZeroAddress();
        _setSigner(signer_);
    }

    /// @inheritdoc IAuthorizable
    function getMessageHash(TxAuthData calldata txAuthData) public view returns (bytes32) {
        return _getTypedDataHash(txAuthData);
    }

    /// @dev Verify transaction authentication data
    /// @param account The account that is being verified
    /// @param msgData The message data of the transaction
    /// @return True if the transaction authentication data is valid, reverts otherwise
    function _verify(address account, bytes calldata msgData) internal returns (bool) {
        address signer_ = signer;

        if (account == address(0)) revert ZeroAddress();
        if (signer_ == address(0)) revert InvalidSigner();
        if (msgData.length < _EXTRA_DATA_LENGTH) revert InvalidMsgDataLength();

        bytes calldata argsWithSelector = msgData[:msgData.length - _EXTRA_DATA_LENGTH];

        uint256 blockExpiration =
            uint256(bytes32(msgData[msgData.length - _EXTRA_DATA_LENGTH:msgData.length - _SIGNATURE_LENGTH]));

        bytes calldata signature = msgData[msgData.length - _SIGNATURE_LENGTH:];

        if (block.number >= blockExpiration) revert InvalidBlockExpiration();

        uint256 nonce = nonces[account]++;

        TxAuthData memory txAuthData = TxAuthData({
            functionCallData: argsWithSelector,
            contractAddress: address(this),
            account: account,
            nonce: nonce,
            blockExpiration: blockExpiration
        });

        bytes32 digest = _getTypedDataHash(txAuthData);

        emit TxAuthDataVerified(block.chainid, nonce, blockExpiration, address(this), account, argsWithSelector);

        if (!SignatureChecker.isValidSignatureNow(signer_, digest, signature)) revert InvalidSignature();

        return true;
    }

    /// @dev Verify transaction authentication data for multiple accounts
    /// @param accounts Array of accounts that are being verified in the transaction
    /// @param msgData [functionCallData][blockExpiration][signature1][signature2]...[signatureN][length]
    /// @return True if all transaction authentication data is valid, false otherwise
    function _verifyMany(address[] memory accounts, bytes calldata msgData) internal returns (bool) {
        address signer_ = signer;

        if (signer_ == address(0)) revert InvalidSigner();
        if (accounts.length == 0) revert EmptyAccountsArray();
        if (msgData.length < _EXTRA_DATA_LENGTH) revert InvalidMsgDataLength();

        VerifyManyData memory data = _parseVerifyManyData(accounts, msgData);

        if (block.number >= data.blockExpiration) revert InvalidBlockExpiration();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) revert ZeroAddress();

            if (!_verifySingle(signer_, accounts[i], data, i, msgData)) {
                revert InvalidSignature();
            }
        }
        return true;
    }

    /// @dev Parse msgData for _verifyMany function
    function _parseVerifyManyData(address[] memory accounts, bytes calldata msgData)
        private
        pure
        returns (VerifyManyData memory data)
    {
        data.numSignatures = uint256(bytes32(msgData[msgData.length - _BYTES_32_LENGTH:]));
        if (data.numSignatures != accounts.length) revert ArrayLengthMismatch();

        uint256 extraDataLength = _BYTES_32_LENGTH + (data.numSignatures * _SIGNATURE_LENGTH) + _BYTES_32_LENGTH;
        if (msgData.length < extraDataLength) revert InvalidMsgDataLength();

        data.argsWithSelector = msgData[:msgData.length - extraDataLength];

        uint256 blockExpirationStart = msgData.length - extraDataLength;
        data.blockExpiration = uint256(bytes32(msgData[blockExpirationStart:blockExpirationStart + _BYTES_32_LENGTH]));
        data.signaturesStart = blockExpirationStart + _BYTES_32_LENGTH;
    }

    /// @dev Verify a single signature within verifyMany
    function _verifySingle(address signer_, address account, VerifyManyData memory data, uint256 index, bytes calldata msgData)
        private
        returns (bool)
    {
        uint256 nonce = nonces[account]++;

        bytes32 digest = _getTypedDataHash(
            TxAuthData({
                functionCallData: data.argsWithSelector,
                contractAddress: address(this),
                account: account,
                nonce: nonce,
                blockExpiration: data.blockExpiration
            })
        );

        emit TxAuthDataVerified(
            block.chainid, nonce, data.blockExpiration, address(this), account, data.argsWithSelector
        );

        bytes calldata signature = msgData[
            data.signaturesStart + (index * _SIGNATURE_LENGTH):data.signaturesStart + ((index + 1) * _SIGNATURE_LENGTH)
        ];

        return SignatureChecker.isValidSignatureNow(signer_, digest, signature);
    }

    /// @dev Compute EIP-712 typed data digest for TxAuthData
    function _getTypedDataHash(TxAuthData memory txAuthData) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                _TXAUTH_TYPEHASH,
                keccak256(txAuthData.functionCallData),
                txAuthData.contractAddress,
                txAuthData.account,
                txAuthData.nonce,
                txAuthData.blockExpiration
            )
        );
        return _hashTypedDataV4(structHash);
    }

    /// @dev Sets the signer address
    function _setSigner(address signer_) internal {
        address oldSigner = signer;
        signer = signer_;
        emit SignerChanged(oldSigner, signer_);
    }
}
