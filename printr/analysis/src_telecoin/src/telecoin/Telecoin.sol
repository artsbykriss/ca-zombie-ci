// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IPrintrTeleport } from "../interfaces/printr/IPrintrTeleport.sol";
import { ITelecoin } from "../interfaces/telecoin/ITelecoin.sol";

import { ERC20 } from "./ERC20.sol";
import { ERC20Witness } from "./ERC20Witness.sol";
import { OftStandard } from "./OftStandard.sol";

/**
 * @title Telecoin
 * @notice Base ERC20 token with teleport capabilities and witness permit functionality
 * @dev Extends ERC20Witness and OftStandard to provide cross-chain teleport functionality via LayerZero
 */
contract Telecoin is ITelecoin, ERC20Witness, OftStandard {

    /// @notice Base URL for the off-chain metadata JSON, keyed by telecoinId
    string private constant METADATA_BASE_URL = "https://cdn.printr.money/t/";

    /// @notice Trailing path appended after the telecoinId in the metadata URL
    string private constant METADATA_SUFFIX = "/media/icon";

    /// @notice Printr Telecoin ID
    bytes32 public immutable telecoinId;

    /// @notice Maximum total supply of the token
    uint256 public immutable maxSupply;

    /// @notice Address of the Printr contract that created this token
    address public immutable printr;

    /**
     * @notice Constructor for Telecoin
     * @param params Deployment parameters struct containing token configuration
     */
    constructor(
        TelecoinDeployParams memory params
    ) ERC20Witness(params.name, params.symbol, 18) {
        if (params.printr == address(0)) {
            revert ZeroAddress();
        }

        telecoinId = params.telecoinId;
        maxSupply = params.maxSupply;
        printr = params.printr;
    }

    /**
     * @notice Quotes the total teleport fee for any protocol (external interface)
     * @param params The teleport parameters struct (includes protocol)
     * @return totalNativeFee The total fee in native currency (protocol fee + bridge fee)
     * @return basePairFee The fee in base pair tokens (0 if base pair is native)
     * @return basePair The base pair address (address(0) if native)
     * @return bridgeFee The bridge-specific gas fee (LZ messaging fee)
     */
    function quoteTeleportFee(
        IPrintrTeleport.TeleportParams memory params
    )
        public
        override(ITelecoin)
        returns (uint256 totalNativeFee, uint256 basePairFee, address basePair, uint256 bridgeFee)
    {
        return _quoteTeleportFee(params);
    }

    /**
     * @notice Teleports tokens from sender to a destination chain
     * @dev Routes to LayerZero based on params.protocol. ITS is deprecated.
     * @param params The teleport parameters struct (includes protocol)
     */
    function teleport(
        IPrintrTeleport.TeleportParams calldata params
    ) public payable virtual {
        if (params.protocol == IPrintrTeleport.TeleportProtocol.UNSPECIFIED) {
            revert InvalidProtocol();
        }

        if (params.protocol == IPrintrTeleport.TeleportProtocol.ITS) {
            revert ITSDeprecated();
        }

        _lzTeleport(msg.sender, params);
    }

    /**
     * @notice Teleports tokens from a specified address to a destination chain
     * @dev Routes to LayerZero based on params.protocol. ITS is deprecated.
     * @param from The sender of the tokens (must have approved msg.sender)
     * @param params The teleport parameters struct (includes protocol)
     */
    function teleportFrom(
        address from,
        IPrintrTeleport.TeleportParams calldata params
    ) public payable virtual {
        if (params.protocol == IPrintrTeleport.TeleportProtocol.UNSPECIFIED) {
            revert InvalidProtocol();
        }

        if (params.protocol == IPrintrTeleport.TeleportProtocol.ITS) {
            revert ITSDeprecated();
        }

        _lzTeleport(from, params);
    }

    /**
     * @notice Returns the URL of the off-chain metadata JSON for this telecoin
     * @dev Built from telecoinId so the URL is stable across chains and free of storage cost.
     *      Format: https://cdn.printr.money/t/<telecoinId>/media/icon
     * @return URL of the metadata JSON
     */
    function contractURI() public view virtual returns (string memory) {
        return string.concat(METADATA_BASE_URL, Strings.toHexString(uint256(telecoinId), 32), METADATA_SUFFIX);
    }

    /**
     * @notice Returns the URL of the off-chain metadata JSON for this telecoin
     * @dev Alias of contractURI() that mirrors Solana/Metaplex naming.
     * @return URL of the metadata JSON (identical to contractURI())
     */
    function metadataURI() external view virtual returns (string memory) {
        return contractURI();
    }

    /**
     * @notice Internal function to decrease allowance
     * @dev Preserves infinite allowance when value is max uint256
     * @param sender Address owning the tokens
     * @param spender Address spending the tokens
     * @param value Amount to decrease allowance by
     */
    function _decreaseAllowance(
        address sender,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 _allowance = allowance[sender][spender];

        if (_allowance < value) {
            revert ERC20InsufficientAllowance(spender, _allowance, value);
        }

        if (_allowance != type(uint256).max) {
            allowance[sender][spender] = _allowance - value;
        }
    }

    /**
     * @notice Internal fee quote implementation for OftStandard
     * @dev Overrides OftStandard's virtual function, delegates to PrintrTeleport
     * @param params The teleport parameters struct (includes protocol)
     * @return totalNativeFee The total fee in native currency (protocol fee + bridge fee)
     * @return basePairFee The fee in base pair tokens (0 if base pair is native)
     * @return basePair The base pair address (address(0) if native)
     * @return bridgeFee The bridge-specific gas fee (LZ messaging fee)
     */
    function _quoteTeleportFee(
        IPrintrTeleport.TeleportParams memory params
    ) internal override returns (uint256 totalNativeFee, uint256 basePairFee, address basePair, uint256 bridgeFee) {
        return IPrintrTeleport(printr).quoteTeleportFee(address(this), params);
    }

    /**
     * @notice Internal LayerZero teleport execution logic
     * @dev Handles protocol routing for teleport(), teleportFrom(), and OftStandard's send()
     * @param from The address sending the tokens
     * @param params The teleport parameters (memory to support both calldata and memory callers)
     */
    function _lzTeleport(
        address from,
        IPrintrTeleport.TeleportParams memory params
    ) internal override returns (bytes memory receipt) {
        // For LayerZero protocols, consume allowance if sender is not msg.sender
        // This prevents unauthorized teleportFrom calls from consuming other users' approvals
        if (from != msg.sender) {
            _decreaseAllowance(from, msg.sender, params.amount);
        }

        // For LZ protocols
        if (
            params.protocol == IPrintrTeleport.TeleportProtocol.LZ_FAST
                || params.protocol == IPrintrTeleport.TeleportProtocol.LZ_SECURE
                || params.protocol == IPrintrTeleport.TeleportProtocol.LZ_SLOW
        ) {
            // Use LayerZero for teleportation via PrintrTeleport
            return IPrintrTeleport(printr).transmitLzSend{ value: msg.value }(telecoinId, from, params);
        }

        revert InvalidProtocol();
    }

}
