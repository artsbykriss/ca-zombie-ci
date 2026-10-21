// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {IOAppComposer} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol";
import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {IRISExComposer, IOFT} from "src/interfaces/remote/IRISExComposer.sol";

/// @title RISExComposer
/// @notice Receives bridged tokens via lzCompose and executes a whitelisted call.
///         If the call fails, queues the funds for the receiver to claim later.
///         Supports multiple OFTs — resolves the token from the calling OFT.
///
/// @dev Flow:
///   1. OFT mints tokens to this contract on _lzReceive
///   2. Executor calls lzCompose on this contract
///   3. We resolve the token from the OFT, decode target + calldata from composeMsg
///   4. Verify target + selector are whitelisted, target is not the token itself
///   5. Approve target (scoped to amountLD), call, revoke
///   6a. On success: queue leftover tokens (scoped to amountLD) for receiver to claim via claimFunds()
///   6b. On failure: queue amountLD for receiver to claim via claimFunds()
contract RISExComposer is IRISExComposer, IOAppComposer, AccessManaged, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    address private immutable i_endpoint;

    mapping(address oft => OFTConfig config) private s_oftConfig;
    mapping(address receiver => mapping(address token => uint256 amount)) private s_claimable;
    mapping(address token => TokenInfo info) private s_tokenInfoByToken;

    constructor(address endpoint, address accessManager) AccessManaged(accessManager) {
        i_endpoint = endpoint;
    }

    /// @inheritdoc IRISExComposer
    function setOFTWhitelist(address oft, bool allowed) external restricted {
        OFTConfig storage $ = s_oftConfig[oft];
        if ($.whitelisted == allowed) return;

        $.whitelisted = allowed;

        if (allowed) {
            address token = IOFT(oft).token();
            require(token != address(0), OFTTokenNotSet(oft));

            $.token = token;
            ++s_tokenInfoByToken[token].oftCount;
        } else {
            address token = $.token;
            delete $.token;
            TokenInfo storage s_info = s_tokenInfoByToken[token];
            uint16 newCount = --s_info.oftCount;

            // When the last OFT for this token is delisted, snapshot the unaccounted
            // balance as in-flight protected to prevent rescue() from sweeping funds
            // that are still awaiting lzCompose() execution.
            if (newCount == 0) {
                uint256 balance = IERC20(token).balanceOf(address(this));
                uint256 unaccounted = balance > s_info.totalClaimable ? balance - s_info.totalClaimable : 0;
                if (unaccounted > 0) {
                    s_info.inflightProtected = (uint256(s_info.inflightProtected) + unaccounted).toUint120();
                    emit InflightProtectionSet(token, unaccounted);
                }
            }
        }

        emit OFTWhitelistUpdated(oft, allowed);
    }

    /// @inheritdoc ILayerZeroComposer
    function lzCompose(address from, bytes32, bytes calldata message, address, bytes calldata)
        external
        payable
        override
        nonReentrant
    {
        uint256 amountLD = OFTComposeMsgCodec.amountLD(message);

        (address receiver, address target, bytes memory data) =
            _safeDecodeComposeMsg(OFTComposeMsgCodec.composeMsg(message));

        uint32 srcEid = OFTComposeMsgCodec.srcEid(message);
        IERC20 token = IERC20(_validateInput(from, srcEid, target, data));

        // Snapshot balance before call to isolate this message's funds
        // baseline = pre-existing balance that does NOT belong to this message
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amountLD, InsufficientBalance(balance, amountLD));
        uint256 baseline = balance - amountLD;

        // Approve scoped to bridged amount, call, revoke
        token.forceApprove(target, amountLD);
        (bool success, bytes memory reason) = target.call(data);
        token.forceApprove(target, 0);

        if (!success) {
            s_claimable[receiver][address(token)] += amountLD;
            TokenInfo storage s_info = s_tokenInfoByToken[address(token)];
            s_info.totalClaimable = (uint256(s_info.totalClaimable) + amountLD).toUint120();
            emit ComposeCallFailed({
                receiver: receiver,
                token: address(token),
                amount: amountLD,
                target: target,
                selector: bytes4(data),
                reason: reason
            });
            return;
        }

        // Refund only this message's unconsumed tokens (never touch baseline)
        _refundLeftover(token, receiver, baseline, amountLD);
    }

    /// @inheritdoc IRISExComposer
    function decodeComposeMsg(bytes calldata composeMsg)
        external
        pure
        returns (address receiver, address target, bytes memory data)
    {
        (receiver, target, data) = abi.decode(composeMsg, (address, address, bytes));
    }

    /// @inheritdoc IRISExComposer
    function rescue(address token, address to, uint256 amount) external restricted {
        TokenInfo storage s_info = s_tokenInfoByToken[token];
        require(s_info.oftCount == 0, ProtectedToken(token));

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 reserved = uint256(s_info.totalClaimable) + uint256(s_info.inflightProtected);
        uint256 available = balance > reserved ? balance - reserved : 0;
        require(amount <= available, RescueExceedsAvailable(available, amount));

        IERC20(token).safeTransfer(to, amount);
        emit TokensRescued(token, to, amount);
    }

    /// @inheritdoc IRISExComposer
    function clearInflightProtection(address token, uint256 amount) external restricted {
        uint256 current = s_tokenInfoByToken[token].inflightProtected;
        require(amount <= current, ClearExceedsInflight(current, amount));

        s_tokenInfoByToken[token].inflightProtected = (current - amount).toUint120();
        emit InflightProtectionCleared(token, amount);
    }

    /// @inheritdoc IRISExComposer
    function claimFunds(address token) external nonReentrant {
        uint256 amount = s_claimable[msg.sender][token];
        require(amount > 0, NothingToClaim(msg.sender, token));

        s_claimable[msg.sender][token] = 0;
        s_tokenInfoByToken[token].totalClaimable -= amount.toUint120();

        IERC20(token).safeTransfer(msg.sender, amount);
        emit FundsClaimed(msg.sender, token, amount);
    }

    /// @notice Validates caller, OFT, source chain, target, and call policy.
    /// @return token The resolved underlying ERC-20 address for the calling OFT.
    function _validateInput(address from, uint32 srcEid, address target, bytes memory data)
        internal
        view
        returns (address token)
    {
        require(msg.value == 0, NativeTokenNotAccepted());
        require(msg.sender == i_endpoint, InvalidCaller(msg.sender));

        token = s_oftConfig[from].token;
        require(token != address(0), OFTTokenNotSet(from));
        require(s_oftConfig[from].whitelisted, OFTNotWhitelisted(from));
        require(IOFT(from).peers(srcEid) != bytes32(0), SrcEidNotAllowed(srcEid));
        require(target != token && target != from && target != address(this), InvalidTarget(target));

        bytes4 selector = bytes4(data);
        (bool allowed, uint32 delay) = IAccessManager(authority()).canCall(address(this), target, selector);
        require(allowed && delay == 0, CallNotWhitelisted(target, selector));
    }

    /// @notice Decodes composeMsg with a meaningful revert on malformed input.
    function _safeDecodeComposeMsg(bytes memory composeMsg)
        internal
        view
        returns (address receiver, address target, bytes memory data)
    {
        try this.decodeComposeMsg(composeMsg) returns (address receiver_, address target_, bytes memory data_) {
            return (receiver_, target_, data_);
        } catch {
            revert InvalidComposeMsg();
        }
    }

    /// @inheritdoc IRISExComposer
    function getEndpoint() external view returns (address) {
        return i_endpoint;
    }

    /// @inheritdoc IRISExComposer
    function getOFTToken(address oft) external view returns (address) {
        return s_oftConfig[oft].token;
    }

    /// @inheritdoc IRISExComposer
    function isProtectedToken(address token) external view returns (bool) {
        return s_tokenInfoByToken[token].oftCount != 0;
    }

    /// @inheritdoc IRISExComposer
    function getWhitelistedOFT(address oft) external view returns (bool) {
        return s_oftConfig[oft].whitelisted;
    }

    /// @inheritdoc IRISExComposer
    function getClaimable(address receiver, address token) external view returns (uint256) {
        return s_claimable[receiver][token];
    }

    /// @inheritdoc IRISExComposer
    function getTotalClaimable(address token) external view returns (uint256) {
        return s_tokenInfoByToken[token].totalClaimable;
    }

    /// @inheritdoc IRISExComposer
    function getInflightProtected(address token) external view returns (uint256) {
        return s_tokenInfoByToken[token].inflightProtected;
    }

    /// @inheritdoc IRISExComposer
    function getTokenInfo(address token) external view returns (TokenInfo memory) {
        return s_tokenInfoByToken[token];
    }

    // ── Private helpers ─────────────────────────────────────────────────────

    /// @notice Queues unconsumed tokens for the receiver to claim after a successful compose call.
    /// @dev Uses the same pull-based s_claimable pattern as the failure path for consistency.
    /// @param token The ERC-20 token.
    /// @param receiver The refund recipient.
    /// @param baseline The pre-compose token balance (funds that predate this message).
    /// @param amountLD The bridged amount that caps the refund.
    function _refundLeftover(IERC20 token, address receiver, uint256 baseline, uint256 amountLD) private {
        uint256 balanceAfter = token.balanceOf(address(this));
        if (balanceAfter == baseline) return;

        uint256 remaining = balanceAfter - baseline;
        uint256 refund = remaining < amountLD ? remaining : amountLD;
        if (refund == 0) return;

        s_claimable[receiver][address(token)] += refund;
        TokenInfo storage s_info = s_tokenInfoByToken[address(token)];
        s_info.totalClaimable = (uint256(s_info.totalClaimable) + refund).toUint120();
        emit LeftoverQueued({receiver: receiver, token: address(token), amount: refund});
    }
}
