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
import {ConfidentialSafeMath} from "../utils/ConfidentialSafeMath.sol";
import {ConfidentialERC20Utils} from "../utils/ConfidentialERC20Utils.sol";
import {ConfidentialFeeable} from "../utils/ConfidentialFeeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IConfidentialERC20} from "./interfaces/IConfidentialERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @dev Upgradeable reference implementation of {IConfidentialERC20}.
 *
 * A fungible token whose balances and transfers are encrypted with the Primus FHE library, so amounts
 * stay private. Values live as encrypted 64-bit integers (`ve_uint64`) that only authorized parties can
 * decrypt.
 *
 * Highlights:
 *
 * - Encrypted balances end to end
 * - Transfer amounts are never exposed
 * - Time-bounded operators for delegated transfers
 * - Transfer-and-call flow
 * - Overflow/underflow-safe encrypted arithmetic
 */
abstract contract ConfidentialERC20Upgradeable is Initializable, IConfidentialERC20, ERC165Upgradeable, ConfidentialFeeable {
    /// @custom:storage-location erc7201:primus.fhetransform.storage.ConfidentialERC20Upgradeable
    struct ConfidentialERC20Storage {
        mapping(address holder => ve_uint64 balance) _balances;
        mapping(address holder => mapping(address spender => uint48 validUntilTimestamp)) _operators;
        ve_uint64 _totalSupply;
        string _name;
        string _symbol;
        string _contractURI;
    }

    /// @dev A public reveal of encrypted handle `handle` was requested by `requester`.
    event RevealRequested(ve_uint64 indexed handle, address indexed requester);

    /// @dev Invalid receiver `receiver` for a transfer.
    error ConfidentialERC20InvalidReceiver(address receiver);

    /// @dev Invalid sender `sender` for a transfer.
    error ConfidentialERC20InvalidSender(address sender);

    /// @dev `holder` has not authorized `spender` to spend on its behalf.
    error ConfidentialERC20UnauthorizedSpender(address holder, address spender);

    /// @dev `holder` tried to move tokens with a zero balance.
    error ConfidentialERC20ZeroBalance(address holder);

    /**
     * @dev Caller `user` lacks access to encrypted amount `amount`.
     *
     * NOTE: use the transfer variant that takes an encrypted input instead.
     */
    error ConfidentialERC20UnauthorizedUseOfEncryptedAmount(ve_uint64 amount, address user);

    /// @dev Caller `caller` is not allowed to perform the current operation.
    error ConfidentialERC20UnauthorizedCaller(address caller);

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.ConfidentialERC20Upgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ConfidentialERC20StorageLocation =
        0xdff6107832cfc50968939589d0cd65e29380445c454617e102bf512649ba0800;

    function _getConfidentialERC20Storage() internal pure returns (ConfidentialERC20Storage storage $) {
        assembly {
            $.slot := ConfidentialERC20StorageLocation
        }
    }

    function __ConfidentialERC20_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        __ConfidentialERC20_init_unchained(name_, symbol_, contractURI_);
    }

    function __ConfidentialERC20_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        ConfidentialERC20Storage storage $ = _getConfidentialERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
        $._contractURI = contractURI_;
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IConfidentialERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IConfidentialERC20
    function name() public view virtual returns (string memory) {
        return _getConfidentialERC20Storage()._name;
    }

    /// @inheritdoc IConfidentialERC20
    function symbol() public view virtual returns (string memory) {
        return _getConfidentialERC20Storage()._symbol;
    }

    /// @inheritdoc IConfidentialERC20
    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    /// @inheritdoc IConfidentialERC20
    function contractURI() public view virtual returns (string memory) {
        return _getConfidentialERC20Storage()._contractURI;
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialTotalSupply() public view virtual returns (ve_uint64) {
        return _getConfidentialERC20Storage()._totalSupply;
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialBalanceOf(address account) public view virtual returns (ve_uint64) {
        return _getConfidentialERC20Storage()._balances[account];
    }

    /// @inheritdoc IConfidentialERC20
    function isOperator(address holder, address spender) public view virtual returns (bool) {
        ConfidentialERC20Storage storage $ = _getConfidentialERC20Storage();
        return holder == spender || block.timestamp <= $._operators[holder][spender];
    }

    /// @inheritdoc IConfidentialERC20
    function setOperator(address operator, uint48 until) public virtual {
        _setOperator(msg.sender, operator, until);
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialTransfer(
        address to,
        uve_uint64 calldata encryptedAmount
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64) {
        return _transfer(msg.sender, to, FHE.fromUnverified(encryptedAmount));
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialTransfer(address to, ve_uint64 amount) public payable virtual chargeFeeIfExternal returns (ve_uint64) {
        require(FHE.isAllowed(amount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(amount, msg.sender));
        return _transfer(msg.sender, to, amount);
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialTransferFrom(
        address from,
        address to,
        uve_uint64 calldata encryptedAmount
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        require(isOperator(from, msg.sender), ConfidentialERC20UnauthorizedSpender(from, msg.sender));
        transferred = _transfer(from, to, FHE.fromUnverified(encryptedAmount));
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /// @inheritdoc IConfidentialERC20
    function confidentialTransferFrom(
        address from,
        address to,
        ve_uint64 amount
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        require(FHE.isAllowed(amount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(amount, msg.sender));
        require(isOperator(from, msg.sender), ConfidentialERC20UnauthorizedSpender(from, msg.sender));
        transferred = _transfer(from, to, amount);
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /**
     * @inheritdoc IConfidentialERC20
     * @dev The returned `transferred` is a fresh `sent - refund` ciphertext produced in {_transferAndCall};
     * only a transient allowance is granted to `msg.sender` for it. Persistent access to `sent` and `refund`
     * still flows through {_update}, but not to this net amount.
     */
    function confidentialTransferAndCall(
        address to,
        uve_uint64 calldata encryptedAmount,
        bytes calldata data
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        transferred = _transferAndCall(msg.sender, to, FHE.fromUnverified(encryptedAmount), data);
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /**
     * @inheritdoc IConfidentialERC20
     * @dev See the encrypted-input variant for the access semantics of `transferred`.
     */
    function confidentialTransferAndCall(
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        require(FHE.isAllowed(amount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(amount, msg.sender));
        transferred = _transferAndCall(msg.sender, to, amount, data);
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /**
     * @inheritdoc IConfidentialERC20
     * @dev See the encrypted-input variant for the access semantics of `transferred`.
     */
    function confidentialTransferFromAndCall(
        address from,
        address to,
        uve_uint64 calldata encryptedAmount,
        bytes calldata data
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        require(isOperator(from, msg.sender), ConfidentialERC20UnauthorizedSpender(from, msg.sender));
        transferred = _transferAndCall(from, to, FHE.fromUnverified(encryptedAmount), data);
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /**
     * @inheritdoc IConfidentialERC20
     * @dev See the encrypted-input variant for the access semantics of `transferred`.
     */
    function confidentialTransferFromAndCall(
        address from,
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) public payable virtual chargeFeeIfExternal returns (ve_uint64 transferred) {
        require(FHE.isAllowed(amount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(amount, msg.sender));
        require(isOperator(from, msg.sender), ConfidentialERC20UnauthorizedSpender(from, msg.sender));
        transferred = _transferAndCall(from, to, amount, data);
        FHE.accessPolicy(transferred, msg.sender, PermissionType.Transient);
    }

    /**
     * @dev Starts a public reveal of encrypted amount `encryptedAmount` by marking it publicly decryptable.
     * Emits {RevealRequested}.
     *
     * NOTE: both `msg.sender` and `address(this)` must already have access to `encryptedAmount`.
     */
    function requestReveal(ve_uint64 encryptedAmount) public virtual {
        require(FHE.isAllowed(encryptedAmount, msg.sender), ConfidentialERC20UnauthorizedUseOfEncryptedAmount(encryptedAmount, msg.sender));

        FHE.makePubliclyDecryptable(encryptedAmount);
        emit RevealRequested(encryptedAmount, msg.sender);
    }

    /**
     * @dev Publicly reveals an encrypted value by supplying its cleartext and a matching decryption proof, which
     * is verified in this call. Emits {Revealed}.
     *
     * NOTE: this need not be tied to a prior {requestReveal}.
     */
    function reveal(
        ve_uint64 encryptedAmount,
        uint64 cleartextAmount,
        bytes memory decryptionProof
    ) public virtual {
        bytes32[] memory handles = new bytes32[](1);
        handles[0] = ve_uint64.unwrap(encryptedAmount);

        bytes memory cleartexts = abi.encode(cleartextAmount);

        FHE.checkSignatures(handles, cleartexts, decryptionProof);
        emit Revealed(encryptedAmount, cleartextAmount);
    }

    function _setOperator(address holder, address operator, uint48 until) internal virtual {
        ConfidentialERC20Storage storage $ = _getConfidentialERC20Storage();
        $._operators[holder][operator] = until;
        emit OperatorSet(holder, operator, until);
    }

    function _mint(address to, ve_uint64 amount) internal returns (ve_uint64) {
        require(to != address(0), ConfidentialERC20InvalidReceiver(address(0)));
        return _update(address(0), to, amount);
    }

    function _burn(address from, ve_uint64 amount) internal returns (ve_uint64 transferred) {
        require(from != address(0), ConfidentialERC20InvalidSender(address(0)));
        return _update(from, address(0), amount);
    }

    function _transfer(address from, address to, ve_uint64 amount) internal returns (ve_uint64 transferred) {
        require(from != address(0), ConfidentialERC20InvalidSender(address(0)));
        require(to != address(0), ConfidentialERC20InvalidReceiver(address(0)));
        return _update(from, to, amount);
    }

    /**
     * @dev WARNING: the refund attempted when {ConfidentialERC20Utils-checkOnTransferReceived} returns an
     * encrypted false is best-effort. A receiver that spends or burns its balance during the hook can still
     * return false, and the refund would then move zero tokens — leaving the amount with the recipient.
     */
    function _transferAndCall(
        address from,
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) internal returns (ve_uint64 transferred) {
        // Try to transfer amount and replace input with the amount actually moved.
        ve_uint64 sent = _transfer(from, to, amount);

        // Run the receiver callback.
        ve_bool success = ConfidentialERC20Utils.checkOnTransferReceived(msg.sender, from, to, sent, data);

        // Refund on callback failure.
        ve_uint64 refund = _update(to, from, FHE.select(success, FHE.asVEUint64(0), sent));
        transferred = FHE.sub(sent, refund);
    }

    /**
     * @dev Moves up to `amount` from `from` to `to`, or mints/burns when either side is the zero address.
     * Emits {ConfidentialTransfer} with the amount actually moved.
     *
     * NOTE: if `from` has never held tokens its balance handle is uninitialized and the call reverts with
     * {ConfidentialERC20ZeroBalance}.
     */
    function _update(address from, address to, ve_uint64 amount) internal virtual returns (ve_uint64 transferred) {
        ConfidentialERC20Storage storage $ = _getConfidentialERC20Storage();

        ve_bool success;
        ve_uint64 ptr;

        if (from == address(0)) {
            (success, ptr) = ConfidentialSafeMath.tryIncrease($._totalSupply, amount);
            FHE.accessPolicy(ptr, address(this));
            $._totalSupply = ptr;
        } else {
            ve_uint64 fromBalance = $._balances[from];
            require(FHE.isInitialized(fromBalance), ConfidentialERC20ZeroBalance(from));
            (success, ptr) = ConfidentialSafeMath.tryDecrease(fromBalance, amount);
            FHE.accessPolicy(ptr, address(this));
            FHE.accessPolicy(ptr, from);
            $._balances[from] = ptr;
        }

        transferred = FHE.select(success, amount, FHE.asVEUint64(0));

        if (to == address(0)) {
            ptr = FHE.sub($._totalSupply, transferred);
            FHE.accessPolicy(ptr, address(this));
            $._totalSupply = ptr;
        } else {
            ptr = FHE.add($._balances[to], transferred);
            FHE.accessPolicy(ptr, address(this));
            FHE.accessPolicy(ptr, to);
            $._balances[to] = ptr;
        }

        if (from != address(0)) FHE.accessPolicy(transferred, from);
        if (to != address(0)) FHE.accessPolicy(transferred, to);
        FHE.accessPolicy(transferred, address(this));
        emit ConfidentialTransfer(from, to, transferred);
    }
}
