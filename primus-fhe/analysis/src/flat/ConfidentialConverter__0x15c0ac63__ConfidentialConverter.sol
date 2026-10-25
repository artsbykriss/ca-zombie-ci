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
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ConfidentialERC20ConverterUpgradeable} from "./ConfidentialERC20ConverterUpgradeable.sol";
import {PrimusConfigUpgradeable} from "@primuslabs/fhe-contracts/contracts/config/PrimusConfigUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title ConfidentialConverter
 * @dev Upgradeable converter over {ConfidentialERC20ConverterUpgradeable} that shields a plain `ERC20` token
 * into a confidential one. It implements `IERC1363Receiver`, so `ERC1363` tokens transferred directly here are
 * shielded through the callback. Adds an owner-managed denylist plus an optional passthrough to the underlying
 * token's own denylist.
 *
 * WARNING: minting assumes the entire underlying transfer was received, so fee-on-transfer or deflationary
 * tokens are not supported.
 *
 * @dev Releases are flat-file: each version is a git tag of this file. To upgrade, deploy the target tag's
 * implementation and call `upgradeToAndCall` with the right `reinitializeVX` calldata. Older initializers are
 * tombstoned.
 */
contract ConfidentialConverter is
    ConfidentialERC20ConverterUpgradeable,
    PrimusConfigUpgradeable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable
{
    /// @dev Context kept between {unshield} and {finalizeUnshield}.
    struct UnshieldContext {
        address from;
        address operator;
    }

    /// @custom:storage-location erc7201:primus.fhetransform.storage.ConfidentialConverter
    struct ConfidentialConverterStorage {
        mapping(address user => bool denied) _deniedUsers;
        mapping(bytes32 unshieldRequestId => UnshieldContext unshieldContext) _unshieldContexts;
        bytes4 _underlyingDenyListSelector;
        bool _hasUnderlyingDenyListSelector;
    }

    // keccak256(abi.encode(uint256(keccak256("primus.fhetransform.storage.ConfidentialConverter")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CONFIDENTIAL_CONVERTER_STORAGE_LOCATION =
        0xfafe033c77aa2336c53c8572a1bd5a325764a956ee0d9a288230fad87affa600;

    /// @dev Emitted when `user` is added to the denylist.
    event UserDenied(address indexed user);

    /// @dev Emitted when `user` is removed from the denylist.
    event UserAllowed(address indexed user);

    /// @dev Thrown when `user` is on the denylist and attempts a restricted operation.
    error DeniedUser(address user);

    /// @dev Thrown when denying a user already on the denylist.
    error UserAlreadyDenied(address user);

    /// @dev Thrown when allowing a user not on the denylist.
    error UserAlreadyAllowed(address user);

    /// @dev Thrown when the underlying denylist call reverts.
    error UnderlyingDenyListCallFailed();

    /// @dev Thrown when the underlying denylist call returns malformed data.
    error InvalidUnderlyingDenyListResponse();

    /// @dev Thrown when the underlying denylist reports `user` as denied.
    error UnderlyingDenyListedAddress(address user);

    /// @dev Thrown when probing a new underlying denylist selector fails.
    error UnderlyingDenyListSelectorProbeFailed();

    /// @dev Emitted when the underlying denylist selector configuration changes.
    event UnderlyingDenyListSelectorUpdated(bytes4 selector, bool enabled);

    /// @dev Keeps the `reinitializer` version aligned between `initialize` and `reinitializeV1`.
    uint64 private constant REINITIALIZER_VERSION = 1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _getConfidentialConverterStorage() internal pure returns (ConfidentialConverterStorage storage $) {
        assembly {
            $.slot := CONFIDENTIAL_CONVERTER_STORAGE_LOCATION
        }
    }

    /**
     * @notice Initializes the contract behind an empty proxy.
     * @dev Bumps the initializer version to {REINITIALIZER_VERSION} so earlier reinitializers cannot replay.
     */
    /// @custom:oz-upgrades-validate-as-initializer
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        IERC20 underlying_,
        address owner_,
        address[] memory deniedUsers,
        bytes4 underlyingDenyListSelector,
        bool hasUnderlyingDenyListSelector_
    ) public virtual reinitializer(REINITIALIZER_VERSION) {
        __ConfidentialConverter_init(name_, symbol_, contractURI_, underlying_, owner_);
        __ConfidentialConverterState_init(deniedUsers, underlyingDenyListSelector, hasUnderlyingDenyListSelector_);
    }

    function __ConfidentialConverter_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        IERC20 underlying_,
        address owner_
    ) internal onlyInitializing {
        __ConfidentialERC20_init(name_, symbol_, contractURI_);
        __ConfidentialERC20Converter_init(underlying_);
        __PrimusConfigUpgradeable_init();
        __Ownable_init(owner_);
        __Ownable2Step_init();
    }

    /**
     * @dev State setup for this contract. Optionally seeds the denylist with `deniedUsers`.
     * Reverts if any entry in `deniedUsers` appears more than once.
     */
    /// @custom:oz-upgrades-unsafe-allow missing-initializer-call
    function __ConfidentialConverterState_init(
        address[] memory deniedUsers,
        bytes4 underlyingDenyListSelector,
        bool hasUnderlyingDenyListSelector_
    ) internal onlyInitializing {
        uint256 length = deniedUsers.length;
        for (uint256 i = 0; i < length; i++) {
            _denyUser(deniedUsers[i]);
        }
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        $._underlyingDenyListSelector = underlyingDenyListSelector;
        $._hasUnderlyingDenyListSelector = hasUnderlyingDenyListSelector_;
    }

    /// @dev Adds `user` to the denylist.
    function denyUser(address user) external virtual onlyOwner {
        _denyUser(user);
    }

    /// @dev Removes `user` from the denylist. Reverts if `user` is not currently denied.
    function allowUser(address user) external virtual onlyOwner {
        _allowUser(user);
    }

    /// @dev Registers (`skip` = true) or removes an internal caller that skips the FHE fee because its own
    /// entry point already charged the EOA for the transaction. Used to whitelist a aggregator that calls
    /// {shield}/{unshield}/{confidentialTransfer} internally.
    function setFeeSkipCaller(address caller, bool skip) external virtual onlyOwner {
        _setFeeSkipCaller(caller, skip);
    }

    /// @dev Whether `user` is on the denylist.
    function isDenied(address user) public view virtual returns (bool) {
        return _getConfidentialConverterStorage()._deniedUsers[user];
    }

    /**
     * @dev Returns the underlying denylist configuration as `(isSet, selector)`, where `isSet` says whether an
     * underlying denylist check is enabled and `selector` is the 4-byte function to call on {underlying}.
     */
    function getUnderlyingDenyListSelector() public view virtual returns (bool isSet, bytes4 selector) {
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        return ($._hasUnderlyingDenyListSelector, $._underlyingDenyListSelector);
    }

    /**
     * @notice Updates or disables the underlying token denylist selector.
     * @dev When `enabled` is true, probes the new selector against `address(this)` to verify it
     * returns a valid 32-byte boolean before activation. This prevents bricking converter operations
     * if the underlying token changes its denylist ABI after deployment. When `enabled` is false,
     * the underlying denylist passthrough is disabled entirely, unblocking operations when the
     * underlying token has broken its denylist interface.
     */
    function setUnderlyingDenyListSelector(bytes4 selector, bool enabled) external virtual onlyOwner {
        if (enabled) {
            // Probe the new selector before activation to ensure the underlying token supports it.
            (bool success, bytes memory data) = underlying().staticcall(
                abi.encodeWithSelector(selector, address(this))
            );
            require(success && data.length == 32, UnderlyingDenyListSelectorProbeFailed());
        }
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        $._underlyingDenyListSelector = selector;
        $._hasUnderlyingDenyListSelector = enabled;
        emit UnderlyingDenyListSelectorUpdated(selector, enabled);
    }

    function _denyUser(address user) internal virtual {
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        require(!$._deniedUsers[user], UserAlreadyDenied(user));
        $._deniedUsers[user] = true;
        emit UserDenied(user);
    }

    function _allowUser(address user) internal virtual {
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        require($._deniedUsers[user], UserAlreadyAllowed(user));
        $._deniedUsers[user] = false;
        emit UserAllowed(user);
    }

    function _requireNotDenied(address user) internal view {
        // Skip the zero address so mints/burns are not denied, and because e.g. USDT.getBlackListStatus(0) is odd.
        if (user == address(0)) return;
        require(!isDenied(user), DeniedUser(user));
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        if ($._hasUnderlyingDenyListSelector) {
            (bool success, bytes memory data) = underlying().staticcall(
                abi.encodeWithSelector($._underlyingDenyListSelector, user)
            );
            require(success, UnderlyingDenyListCallFailed());
            require(data.length == 32, InvalidUnderlyingDenyListResponse());
            bool value = abi.decode(data, (bool));
            require(!value, UnderlyingDenyListedAddress(user));
        }
    }

    // ----- Denylist enforcement overrides -----

    /// @dev Catches confidential transfers (both parties), the shield recipient (mint), and the unshield holder (burn).
    function _update(address from, address to, ve_uint64 amount) internal virtual override returns (ve_uint64) {
        // Also deny operators on confidentialTransferFrom(AndCall).
        if (msg.sender != from) _requireNotDenied(msg.sender);
        _requireNotDenied(from);
        _requireNotDenied(to);
        return super._update(from, to, amount);
    }

    /// @dev Catches a denied depositor on the direct {shield} path; the recipient is covered via {_update}.
    function shield(address to, uint256 amount) public payable virtual override returns (ve_uint64) {
        // Needed because {_update} does not see msg.sender on a mint (from is the zero address).
        _requireNotDenied(msg.sender);
        return super.shield(to, amount);
    }

    /// @dev ERC-1363 push-shielding is disabled: {onTransferReceived} always reverts at the base layer
    /// ({Erc1363ShieldingDisabled}), because its caller (the plain underlying token) carries no `msg.value`,
    /// so the `_mint` it would perform cannot be charged. Users must call {shield} instead.
    ///
    /// It is moot while the base callback reverts, but documents how the denylist would be enforced on this path if ERC-1363 were
    /// re-enabled together with a chargeable entry. Uncommenting it alone would NOT restore the path — the
    /// base {onTransferReceived} must also stop reverting, and a fee mechanism for the callback must exist.
    /*
    function onTransferReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        // Needed because {_update} sees neither from nor operator on a mint (from is the zero address).
        _requireNotDenied(from);
        if (operator != from) _requireNotDenied(operator);
        return super.onTransferReceived(operator, from, amount, data);
    }
    */

    /// @dev Core logic for opening an unshield request. Records the from/operator context for use at finalization.
    function _unshield(address from, address to, ve_uint64 amount) internal virtual override returns (bytes32) {
        // Needed because {_update} does not see `to` on a burn (to is the zero address).
        _requireNotDenied(to);
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        bytes32 unshieldRequestId = super._unshield(from, to, amount);
        $._unshieldContexts[unshieldRequestId] = UnshieldContext(from, msg.sender);
        return unshieldRequestId;
    }

    /**
     * @dev Prevents settlement of the underlying transfer to a recipient (or its original holder/operator) that
     * became denied between {unshield} and {finalizeUnshield}.
     */
    function finalizeUnshield(
        bytes32 unshieldRequestId,
        uint64 unshieldAmountCleartext,
        bytes calldata decryptionProof
    ) public virtual override {
        // The confidential tokens were already burnt in {unshield}, so {_update} no longer runs here.
        _requireNotDenied(unshieldRequester(unshieldRequestId));
        // Also check both the original holder and the operator from the matching unshield call.
        ConfidentialConverterStorage storage $ = _getConfidentialConverterStorage();
        UnshieldContext memory unshieldContext = $._unshieldContexts[unshieldRequestId];
        _requireNotDenied(unshieldContext.from);
        if (unshieldContext.from != unshieldContext.operator) {
            _requireNotDenied(unshieldContext.operator);
        }
        delete $._unshieldContexts[unshieldRequestId];
        super.finalizeUnshield(unshieldRequestId, unshieldAmountCleartext, decryptionProof);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
