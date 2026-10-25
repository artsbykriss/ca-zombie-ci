// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from OpenZeppelin Confidential Contracts. Copyright (c) OpenZeppelin.
// Modifications Copyright (c) 2026 Primus Labs.
// Full license terms: see the MIT notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @dev Minimal interface for a confidential fungible token backed by the Primus FHE library.
///      Balances and transferred amounts are kept as encrypted `ve_uint64` values.
interface IConfidentialERC20 is IERC165 {
    /// @dev Operator `operator` may move tokens for `holder` until `until`.
    event OperatorSet(address indexed holder, address indexed operator, uint48 until);

    /// @dev A confidential transfer of encrypted `amount` moved from `from` to `to`.
    event ConfidentialTransfer(address indexed from, address indexed to, ve_uint64 indexed amount);

    /// @dev An encrypted handle `handle` has been revealed as cleartext `amount`.
    event Revealed(ve_uint64 indexed handle, uint64 amount);

    /// @dev Token name.
    function name() external view returns (string memory);

    /// @dev Token symbol.
    function symbol() external view returns (string memory);

    /// @dev Token decimals (6 is recommended).
    function decimals() external view returns (uint8);

    /// @dev Contract URI, see ERC-7572.
    function contractURI() external view returns (string memory);

    /// @dev Encrypted total supply.
    function confidentialTotalSupply() external view returns (ve_uint64);

    /// @dev Encrypted balance of `account`.
    function confidentialBalanceOf(address account) external view returns (ve_uint64);

    /// @dev Whether `spender` is an active operator for `holder`.
    function isOperator(address holder, address spender) external view returns (bool);

    /// @dev Approves `operator` for the caller until timestamp `until`.
    function setOperator(address operator, uint48 until) external;

    /// @dev Transfers a freshly submitted encrypted input to `to`. Returns the amount actually moved.
    function confidentialTransfer(address to, uve_uint64 calldata encryptedAmount) external payable returns (ve_uint64);

    /// @dev Transfers an already-authorized encrypted `amount` to `to`.
    function confidentialTransfer(address to, ve_uint64 amount) external payable returns (ve_uint64 transferred);

    /// @dev Operator transfer of a freshly submitted encrypted input from `from` to `to`.
    function confidentialTransferFrom(
        address from,
        address to,
        uve_uint64 calldata encryptedAmount
    ) external payable returns (ve_uint64);

    /// @dev Operator transfer of an already-authorized encrypted `amount` from `from` to `to`.
    function confidentialTransferFrom(address from, address to, ve_uint64 amount) external payable returns (ve_uint64 transferred);

    /// @dev Transfer of an encrypted input plus a callback to `to`.
    function confidentialTransferAndCall(
        address to,
        uve_uint64 calldata encryptedAmount,
        bytes calldata data
    ) external payable returns (ve_uint64 transferred);

    /// @dev Transfer of an authorized encrypted `amount` plus a callback to `to`.
    function confidentialTransferAndCall(
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) external payable returns (ve_uint64 transferred);

    /// @dev Operator transfer of an encrypted input plus a callback to `to`.
    function confidentialTransferFromAndCall(
        address from,
        address to,
        uve_uint64 calldata encryptedAmount,
        bytes calldata data
    ) external payable returns (ve_uint64 transferred);

    /// @dev Operator transfer of an authorized encrypted `amount` plus a callback to `to`.
    function confidentialTransferFromAndCall(
        address from,
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) external payable returns (ve_uint64 transferred);
}
