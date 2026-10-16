// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IActionHandler} from "../../interface/IActionHandler.sol";
import {ActionType} from "../../share/Enums.sol";
import {InvalidNonce, InvalidSigner, SignerNotFound, SubaccountNotFound} from "../../share/Errors.sol";
import {ActionId} from "../../share/UserDefinedTypes.sol";
import {Deposit} from "./Deposit.sol";
import {Withdraw} from "./Withdraw.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

library Account {
    using Account for Account.Data;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCastLib for uint128;
    using SafeCastLib for uint256;
    using SafeCastLib for int256;
    using SafeCastLib for int128;

    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.Account.Data"));

    // --- Storage --- //

    struct DataGlobal {
        /// Exchange settlement stablecoin address
        address usdToken;
        // Total backed balance across all concrete tokens, excludes virtual/synthetic tokens.
        mapping(address token => uint256 amount) totalBackedBalance;
        /// Total token deposit balance across all accounts
        mapping(address token => uint256 amount) totalBalance;
        /// Total pending token deposit balance across all accounts
        mapping(address token => uint256 amount) totalPendingBalance;
        /// Signer to the msg.sender (account) address (one-time linking)
        mapping(address signer => address account) linkedSignersToAccount;
        /// Whether a Signer has already been used or is excluded from being a Signer
        mapping(address signer => bool excluded) excludedSigners;
        /// Whether an Account is forbidden from trading related operations (trade, deposit, withdraw)
        mapping(address account => bool excluded) excludedAccounts;
    }

    struct Data {
        /// The account owner address
        address sender;
        /// Count of registered subaccounts after finalized deposit.
        uint32 registeredSubaccounts;
        /// Token deposit balance of account by subaccount
        mapping(bytes32 subaccount => mapping(address token => uint256 amount)) balance;
        /// Whether the subaccount has ever had a prior deposit
        mapping(bytes32 subaccount => bool hasDeposited) hasRegistered;
        /// Whether the nonce of the sender (account or signer) has been used (by actionType)
        mapping(address sender => mapping(ActionType => mapping(uint64 nonce => bool hasUsed))) usedNonces;
        /// Linked signer by subaccount approved for tx signing
        mapping(bytes32 subaccount => EnumerableSet.AddressSet linkedSigner) linkedSigners;
        /// Number of open positions by subaccount
        mapping(bytes32 subaccount => uint128 amount) openPositions;
        /// Number of open positions by subaccount and quote token
        mapping(bytes32 subaccount => mapping(address quoteToken => uint128 amount)) openPositionsByQuoteToken;
        /// Mapping of subaccount to a pending deposit
        mapping(bytes32 subaccount => Deposit.Data pendingDeposit) pendingDeposit;
        /// Mapping of the withdraw digest to a pending withdraw
        mapping(bytes32 digest => Withdraw.Data pendingWithdraw) pendingWithdraw;
        /// @dev Mapping of pending signer revocations that failed signature validation.
        /// When a revoke signature fails validation in `_handleRevokeLinkedSigner`, the attempted
        /// revocation is recorded here and marked as pending. The revocation remains pending until
        /// `finalizeRevokeLinkedSigner` is called.
        mapping(bytes32 subaccount => mapping(address signer => bool pending)) pendingSignerRevoke;
    }

    // --- Load --- //

    function load() internal pure returns (DataGlobal storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }

    function load(address account) internal pure returns (Data storage $) {
        bytes32 s = keccak256(abi.encode("xyz.meridian.Account.Data", account));
        assembly {
            $.slot := s
        }
    }

    // --- Global --- //

    /// @dev Given an account address or signer address, return the associated account.
    function resolveAccount(DataGlobal storage self, address accountOrSigner) internal view returns (Data storage) {
        address accountAddress = self.linkedSignersToAccount[accountOrSigner];

        // 0x eq no linked signer, so it's an account (which or may or may not exist).
        if (accountAddress == address(0)) {
            return Account.load(accountOrSigner);
        }
        return Account.load(accountAddress);
    }

    /// @notice This function assumes signature validations have been performed externally.
    /// @dev Links a signer, marks nonce as used, and return true if success, false otherwise.
    function linkSigner(DataGlobal storage self, IActionHandler.LinkSignerMessage memory message, ActionId id)
        internal
        returns (bool)
    {
        Account.Data storage account = Account.load(message.sender);

        if (account.isNonceUsed(message.sender, ActionType.LinkSigner, message.nonce)) {
            revert InvalidNonce(id, message.nonce);
        }

        // Excluded addresses cannot be linked (e.g. subaccounts, system accounts).
        if (self.excludedSigners[message.signer]) {
            // Deposits automatically add `msg.sender` to an excluded signers mapping as accounts cannot be
            // used as a linked signer for another account. Here we verify that if the signer is an account then
            // flag `nonce` used and return false.
            //
            // However, if we are attempting to relink and previously revoked signer then throw a revert.
            if (Account.load(message.signer).sender != address(0)) {
                account.usedNonces[message.sender][ActionType.LinkSigner][message.nonce] = true;
                return false;
            }
            revert InvalidSigner(id, message.signer);
        }

        if (!account.isSubaccountRegistered(message.subaccount)) {
            revert SubaccountNotFound(id, message.sender, message.subaccount);
        }

        self.linkedSignersToAccount[message.signer] = message.sender;
        self.excludedSigners[message.signer] = true;

        account.linkedSigners[message.subaccount].add(message.signer);
        account.usedNonces[message.sender][ActionType.LinkSigner][message.nonce] = true;

        return true;
    }

    /// @notice Revokes a signer from a subaccount and marks the given nonce as used.
    /// @dev Once revoked the signer cannot be be relinked to another subaccount.
    function revokeSigner(DataGlobal storage self, IActionHandler.RevokeLinkedSignerMessage memory message, ActionId id)
        internal
    {
        Account.Data storage account = Account.load(message.sender);

        if (!account.isSubaccountRegistered(message.subaccount)) {
            revert SubaccountNotFound(id, message.sender, message.subaccount);
        }
        if (account.isNonceUsed(message.sender, ActionType.RevokeLinkedSigner, message.nonce)) {
            revert InvalidNonce(id, message.nonce);
        }
        if (!account.linkedSigners[message.subaccount].remove(message.signer)) {
            revert SignerNotFound(id, message.sender, message.subaccount, message.signer);
        }

        delete self.linkedSignersToAccount[message.signer];
        account.usedNonces[message.sender][ActionType.RevokeLinkedSigner][message.nonce] = true;
        self.excludedAccounts[message.signer] = true;
    }

    // --- Instance --- //

    /// @dev Returns true if subaccount has been registered, false otherwise.
    function isSubaccountRegistered(Data storage self, bytes32 subaccount) internal view returns (bool) {
        return self.hasRegistered[subaccount];
    }

    /// @dev Returns true if nonce has been used, false otherwise.
    function isNonceUsed(Data storage self, address sender, ActionType actionType, uint64 nonce)
        internal
        view
        returns (bool)
    {
        return self.usedNonces[sender][actionType][nonce];
    }

    /// @dev Updates the open positions by subaccount and quote token.
    function updateOpenPositions(Data storage self, bytes32 subaccount, address quoteToken, int128 delta) internal {
        self.openPositions[subaccount] = (self.openPositions[subaccount].toInt128() + delta).toUint256().toUint128();
        self.openPositionsByQuoteToken[subaccount][quoteToken] =
            (self.openPositionsByQuoteToken[subaccount][quoteToken].toInt128() + delta).toUint256().toUint128();
    }
}
