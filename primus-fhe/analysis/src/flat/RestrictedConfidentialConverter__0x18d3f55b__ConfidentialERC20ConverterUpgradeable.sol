// SPDX-License-Identifier: MIT
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from OpenZeppelin Confidential Contracts. Copyright (c) OpenZeppelin.
// Modifications Copyright (c) 2026 Primus Labs.
// Full license terms: see the MIT notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ConfidentialERC20Upgradeable} from "../token/ConfidentialERC20Upgradeable.sol";
import {IConfidentialERC20} from "../token/interfaces/IConfidentialERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IConfidentialERC20Converter} from "./interfaces/IConfidentialERC20Converter.sol";

/**
 * @title ConfidentialERC20ConverterUpgradeable
 * @dev Upgradeable converter on top of {ConfidentialERC20Upgradeable} that turns a plain `ERC20` token into a
 * confidential one. It implements `IERC1363Receiver`, so users can push `ERC1363` tokens straight to the
 * converter and have them shielded through the callback.
 *
 * Unshielding is two-step: {unshield} burns the confidential amount and marks the resulting handle publicly
 * decryptable, recording the target recipient against the handle. The holder then decrypts off-chain and calls
 * {finalizeUnshield} with the cleartext and a matching decryption proof, which is verified synchronously before
 * the underlying tokens are released.
 *
 * WARNING: minting assumes the full underlying transfer was received, so fee-on-transfer or other deflationary
 * tokens are not supported.
 */
abstract contract ConfidentialERC20ConverterUpgradeable is
    ConfidentialERC20Upgradeable,
    IConfidentialERC20Converter,
    IERC1363Receiver
{
    /// @custom:storage-location erc7201:primus.fhetransform.storage.ConfidentialERC20ConverterUpgradeable
    struct ConfidentialERC20ConverterStorage {
        IERC20 _underlying;
        uint8 _decimals;
        uint256 _rate;
        mapping(bytes32 unshieldRequestId => address recipient) _unshieldRequests;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.ConfidentialERC20ConverterUpgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CONFIDENTIAL_ERC20_CONVERTER_STORAGE_LOCATION =
        0x06506569a781abb94b4e0f3cc5bc37c9553b2c7bbdab344c23bdb78f98481400;

    /// @dev Thrown when referencing an unshield request that doesn't exist or was already processed
    error InvalidUnshieldRequest(bytes32 unshieldRequestId);

    /// @dev Thrown when total supply of the confidential token would overflow
    error ConfidentialERC20TotalSupplyOverflow();

    /// @dev Thrown when the underlying token address is zero.
    error ConfidentialERC20ConverterInvalidUnderlying();

    /// @dev Thrown when the underlying token's decimals cannot be read via staticcall.
    error ConfidentialERC20ConverterDecimalsUnavailable();

    /// @dev ERC-1363 push-shielding via {onTransferReceived} is disabled. The callback cannot charge an FHE
    /// fee (its caller is the plain underlying token, carrying no `msg.value`), so the `_mint` it would
    /// perform hits the executor's "no user locked in this tx" check. Use {shield} instead.
    error Erc1363ShieldingDisabled();

    /// @dev Emitted when plaintext tokens are shield into confidential tokens
    /// @param to Recipient of the confidential tokens
    /// @param roundedAmount Plaintext amount after rounding to match confidential precision
    /// @param encryptedShieldedAmount Encrypted amount of confidential tokens minted
    event Shield(address indexed to, uint256 roundedAmount, ve_uint64 encryptedShieldedAmount);

    /// @dev Returns a pointer to the ConfidentialERC20Converter storage struct
    function _getConfidentialERC20ConverterStorage() internal pure returns (ConfidentialERC20ConverterStorage storage $)
    {
        assembly {
            $.slot := CONFIDENTIAL_ERC20_CONVERTER_STORAGE_LOCATION
        }
    }

    /// @dev Initializes the converter with the underlying ERC20 token
    function __ConfidentialERC20Converter_init(IERC20 underlying_) internal onlyInitializing {
        __ConfidentialERC20Converter_init_unchained(underlying_);
    }

    /// @dev Unchained initializer: sets the underlying token and computes decimals/rate for converting
    function __ConfidentialERC20Converter_init_unchained(IERC20 underlying_) internal onlyInitializing {
        require(address(underlying_) != address(0), ConfidentialERC20ConverterInvalidUnderlying());
        ConfidentialERC20ConverterStorage storage $ = _getConfidentialERC20ConverterStorage();
        $._underlying = underlying_;

        uint8 tokenDecimals = _tryGetAssetDecimals(underlying_);
        uint8 maxDecimals = _maxDecimals();
        if (tokenDecimals > maxDecimals) {
            $._decimals = maxDecimals;
            $._rate = 10 ** (tokenDecimals - maxDecimals);
        } else {
            $._decimals = tokenDecimals;
            $._rate = 1;
        }
    }

    /**
     * @dev `ERC1363` callback. Disabled: this path is invoked by the plain underlying token, which carries no
     * `msg.value`, so the `_mint` it would perform cannot be charged and would revert in the executor. Use
     * {shield} instead. The {IERC1363Receiver} interface is still advertised via {supportsInterface} for
     * compatibility, but this entry always reverts.
     */
    function onTransferReceived(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        revert Erc1363ShieldingDisabled();
    }

    /**
     * @dev See {IConfidentialERC20Converter-shield}. Tokens convert at the fixed {rate}, so `amount / rate()`
     * confidential tokens are minted; the transferred-in amount is rounded down to a multiple of {rate}.
     *
     * Returns the encrypted amount minted.
     */
    function shield(address to, uint256 amount) public payable virtual override chargeFeeIfExternal returns (ve_uint64) {
        uint256 roundedAmount = amount - (amount % rate());
        // Pull the tokens in.
        SafeERC20.safeTransferFrom(IERC20(underlying()), msg.sender, address(this), roundedAmount);

        // Mint the confidential token.
        ve_uint64 shieldedAmountSent = _mint(to, FHE.asVEUint64(SafeCast.toUint64(amount / rate())));
        FHE.accessPolicy(shieldedAmountSent, msg.sender, PermissionType.Transient);

        emit Shield(to, roundedAmount, shieldedAmountSent);

        return shieldedAmountSent;
    }

    /**
     * @dev Unshield using an already-authorized encrypted amount. See the encrypted-input variant for details.
     */
    function unshield(address from, address to, ve_uint64 amount) public payable virtual chargeFeeIfExternal returns (bytes32) {
        require(FHE.isAllowed(amount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(amount, msg.sender));
        return _unshield(from, to, amount);
    }

    /**
     * @dev See {IConfidentialERC20Converter-unshield}. Ultimately releases `amount * rate()` underlying tokens
     * to `to`.
     *
     * NOTE: the request opened here must be settled with {finalizeUnshield}.
     */
    function unshield(
        address from,
        address to,
        uve_uint64 calldata encryptedAmount
    ) public payable virtual chargeFeeIfExternal returns (bytes32) {
        return _unshield(from, to, FHE.fromUnverified(encryptedAmount));
    }

    /**
     * @inheritdoc IConfidentialERC20Converter
     * @dev The caller supplies the `unshieldAmountCleartext` and a `decryptionProof`, which is verified
     * against the request handle before the underlying tokens are transferred.
     */
    function finalizeUnshield(
        bytes32 unshieldRequestId,
        uint64 unshieldAmountCleartext,
        bytes calldata decryptionProof
    ) public virtual {
        address to = unshieldRequester(unshieldRequestId);
        require(to != address(0), InvalidUnshieldRequest(unshieldRequestId));

        ve_uint64 unshieldAmount_ = ve_uint64.wrap(unshieldRequestId);
        ConfidentialERC20ConverterStorage storage $ = _getConfidentialERC20ConverterStorage();
        delete $._unshieldRequests[unshieldRequestId];

        bytes32[] memory handles = new bytes32[](1);
        handles[0] = ve_uint64.unwrap(unshieldAmount_);

        bytes memory cleartexts = abi.encode(unshieldAmountCleartext);

        FHE.checkSignatures(handles, cleartexts, decryptionProof);

        SafeERC20.safeTransfer(IERC20(underlying()), to, unshieldAmountCleartext * rate());

        emit UnshieldFinalized(to, unshieldRequestId, unshieldAmount_, unshieldAmountCleartext);
    }

    /// @inheritdoc ConfidentialERC20Upgradeable
    function decimals() public view virtual override(IConfidentialERC20, ConfidentialERC20Upgradeable) returns (uint8) {
        return _getConfidentialERC20ConverterStorage()._decimals;
    }

    /// @inheritdoc IConfidentialERC20Converter
    function rate() public view virtual returns (uint256) {
        return _getConfidentialERC20ConverterStorage()._rate;
    }

    /// @inheritdoc IConfidentialERC20Converter
    function underlying() public view virtual override returns (address) {
        return address(_getConfidentialERC20ConverterStorage()._underlying);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ConfidentialERC20Upgradeable) returns (bool) {
        return
            interfaceId == type(IConfidentialERC20Converter).interfaceId ||
            interfaceId == type(IERC1363Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Underlying balance divided by {rate}; an upper bound on the actual {confidentialTotalSupply}.
     *
     * NOTE: this can be inflated by sending underlying tokens straight to the converter. It also lags on the
     * way down since it updates on {finalizeUnshield} while {confidentialTotalSupply} updates on {unshield}.
     */
    function inferredTotalSupply() public view virtual returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this)) / rate();
    }

    /// @dev Maximum total supply supported by the encrypted datatype.
    function maxTotalSupply() public view virtual returns (uint256) {
        return type(uint64).max;
    }

    /**
     * @dev Recipient of the underlying tokens for a pending unshield `unshieldRequestId`, or `address(0)` if
     * none is pending.
     */
    function unshieldRequester(bytes32 unshieldRequestId) public view virtual returns (address) {
        return _getConfidentialERC20ConverterStorage()._unshieldRequests[unshieldRequestId];
    }

    /**
     * @inheritdoc IConfidentialERC20Converter
     * @dev Returns `true` once {finalizeUnshield} has deleted the request record and released the underlying
     * tokens. Because the record is only deleted inside {finalizeUnshield}, a `true` result signals that
     * settlement completed (tokens were transferred), not merely that the request no longer exists.
     */
    function isUnshieldSettled(bytes32 unshieldRequestId) public view virtual returns (bool) {
        return unshieldRequester(unshieldRequestId) == address(0);
    }

    /**
     * @dev Reverts when the new {confidentialTotalSupply} would overflow.
     *
     * NOTE: overflow is detectable here because converter holdings are public. It may revert even when the
     * confidential supply did not actually overflow.
     */
    function _checkConfidentialTotalSupply() internal virtual {
        require(inferredTotalSupply() <= maxTotalSupply(), ConfidentialERC20TotalSupplyOverflow());
    }

    /// @inheritdoc ConfidentialERC20Upgradeable
    function _update(address from, address to, ve_uint64 amount) internal virtual override returns (ve_uint64) {
        if (from == address(0)) {
            _checkConfidentialTotalSupply();
        }
        return super._update(from, to, amount);
    }

    /// @dev Core logic for opening an unshield request. Returns the request id.
    function _unshield(address from, address to, ve_uint64 amount) internal virtual returns (bytes32) {
        require(to != address(0), ConfidentialERC20InvalidReceiver(to));
        require(from == msg.sender || isOperator(from, msg.sender), ConfidentialERC20UnauthorizedSpender(from, msg.sender));

        // Burn and see how much was actually removed.
        ve_uint64 unshieldAmount_ = _burn(from, amount);
        FHE.makePubliclyDecryptable(unshieldAmount_);

        assert(unshieldRequester(ve_uint64.unwrap(unshieldAmount_)) == address(0));

        ConfidentialERC20ConverterStorage storage $ = _getConfidentialERC20ConverterStorage();

        // WARNING: reusing the ciphertext handle as the request id assumes handle uniqueness. It holds here
        // but is not universally guaranteed, so treat handle uniqueness carefully.
        bytes32 unshieldRequestId = ve_uint64.unwrap(unshieldAmount_);
        $._unshieldRequests[unshieldRequestId] = to;

        emit UnshieldRequested(to, unshieldRequestId, unshieldAmount_);
        return unshieldRequestId;
    }

    /**
     * @dev Upper bound the converter will use for {decimals}.
     */
    function _maxDecimals() internal pure virtual returns (uint8) {
        return 6;
    }

    function _tryGetAssetDecimals(IERC20 asset_) private view returns (uint8 assetDecimals) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length == 32) {
            return abi.decode(encodedDecimals, (uint8));
        }
        revert ConfidentialERC20ConverterDecimalsUnavailable();
    }
}
