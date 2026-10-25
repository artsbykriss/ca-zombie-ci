// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Governed} from "../access/Governed.sol";
import {ProtocolConfig} from "../config/ProtocolConfig.sol";
import {IFeeSink} from "../interfaces/IFeeSink.sol";

/// @title  FeeRouter
/// @notice Routes the outbound trade-fee slices (spec §10): platform → `treasury`, LP → the
///         settable `lpFeeDestination` (LP yield day one), creator → the market creator. The
///         **depth** slice never reaches here — it is retained by the spot engine as the market's
///         liquidity reserve (funds autoExpandB). **No buyback / no token logic** (founder
///         correction): the platform slice simply lands at the treasury address and stops.
/// @dev    A fee source (the spot engine, later the order book) transfers the three outbound
///         slices to this contract and calls {route}. The creator transfer is wrapped in a
///         try/catch (Phase 1 audit fix H-PM-1): a malicious creator that reverts on receipt
///         cannot brick trading — their slice is redirected to the treasury instead.
///
///         Audit fix H-1 (2026-07-18): the treasury itself is now a non-bricking sink. Mainnet
///         USDC is blacklistable, and the treasury was the destination for the platform slice AND
///         for the creator/LP redirect fallbacks — so a blacklisted treasury would revert {route}
///         and halt ALL trading until a timelocked {ProtocolConfig-setTreasury}. Every treasury
///         payment now goes through {_payTreasury}: it tries to push, and on any revert accrues the
///         amount to {platformAccrued} for a later governance {sweepAccrued}. Fees can never brick
///         trading; nothing is lost.
contract FeeRouter is Governed {
    using SafeERC20 for IERC20;

    bytes32 public constant FEE_SOURCE_ROLE = keccak256("FEE_SOURCE_ROLE");

    ProtocolConfig public immutable config;
    IERC20 public immutable usdc;

    /// @notice USDC that could not be delivered to the treasury (e.g. a blacklisted treasury) and
    ///         is held here pending a governance {sweepAccrued}. Trading is never blocked by it.
    uint256 public platformAccrued;

    /// @notice Monotonic lifetime count of platform-slice fees that passed through this router.
    ///         Advanced on EVERY successful `_payTreasury` call AND on every accrual (so a
    ///         blacklisted treasury doesn't make this metric lie). Readable in one view call
    ///         by Dune / DefiLlama / dashboards — no indexer required.
    uint256 public totalPlatformFees;

    event FeesRouted(address indexed creator, uint256 platform, uint256 creator_, uint256 lp);
    event CreatorFeeRedirected(address indexed creator, uint256 amount);
    event LpFeeRedirected(address indexed sink, uint256 amount);
    event TreasuryPaymentAccrued(uint256 amount, uint256 totalAccrued);
    event AccruedSwept(address indexed to, uint256 amount);
    event PlatformFeeBooked(uint256 amount, uint256 lifetime);

    error ZeroAddress();
    error OnlySelf();

    constructor(address accessController_, address config_, address usdc_) Governed(accessController_) {
        if (config_ == address(0) || usdc_ == address(0)) revert ZeroAddress();
        config = ProtocolConfig(config_);
        usdc = IERC20(usdc_);
    }

    /// @notice Distribute pre-funded slices. The caller (FEE_SOURCE_ROLE) must have transferred
    ///         `platformAmt + creatorAmt + lpAmt` USDC to this contract immediately prior.
    function route(address creator, uint256 platformAmt, uint256 creatorAmt, uint256 lpAmt)
        external
        onlyRole(FEE_SOURCE_ROLE)
    {
        if (platformAmt > 0) _payTreasury(platformAmt);
        if (lpAmt > 0) _routeLpSlice(config.lpFeeDestination(), lpAmt);
        if (creatorAmt > 0) {
            try this.sendCreatorFee(creator, creatorAmt) {
                // delivered to the creator
            } catch {
                _payTreasury(creatorAmt);
                emit CreatorFeeRedirected(creator, creatorAmt);
            }
        }
        emit FeesRouted(creator, platformAmt, creatorAmt, lpAmt);
    }

    /// @dev Pay the treasury WITHOUT ever reverting the caller. Mainnet USDC can blacklist an
    ///      address, which would make a direct transfer revert and — since {route} runs on every
    ///      trade — brick all trading. Push via an external self-call so the revert is catchable;
    ///      on any failure, accrue the amount for a later governance {sweepAccrued}. This is the
    ///      single choke point for every treasury-bound slice (platform + creator/LP fallbacks).
    ///
    ///      We also advance `totalPlatformFees` here unconditionally. The counter is a lifetime
    ///      INFLOW tally — fees that passed through, regardless of whether they reached the
    ///      treasury on the first try or ended up in {platformAccrued} for a later sweep. This
    ///      keeps the public revenue metric honest even if a treasury blacklist ever stalls a
    ///      delivery.
    function _payTreasury(uint256 amount) internal {
        totalPlatformFees += amount;
        emit PlatformFeeBooked(amount, totalPlatformFees);
        try this.pushTo(config.treasury(), amount) {
            // delivered to the treasury
        } catch {
            platformAccrued += amount;
            emit TreasuryPaymentAccrued(amount, platformAccrued);
        }
    }

    /// @dev External self-call so {route}/{_payTreasury} can isolate a revertable transfer.
    function pushTo(address to, uint256 amount) external {
        if (msg.sender != address(this)) revert OnlySelf();
        usdc.safeTransfer(to, amount);
    }

    /// @notice Drain fees that couldn't be delivered to the treasury (see {platformAccrued}) once
    ///         it can receive again — or to a replacement address. Governance-only; CEI-ordered.
    function sweepAccrued(address to) external onlyGovernance {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = platformAccrued;
        platformAccrued = 0;
        usdc.safeTransfer(to, amount);
        emit AccruedSwept(to, amount);
    }

    /// @dev External self-call so {route} can isolate a revertable creator transfer.
    function sendCreatorFee(address creator, uint256 amount) external {
        if (msg.sender != address(this)) revert OnlySelf();
        usdc.safeTransfer(creator, amount);
    }

    /// @dev Route the LP slice to `sink` as LP yield via {IFeeSink.notifyFee} (pull) when `sink`
    ///      is a contract; otherwise (a plain address, e.g. the placeholder treasury) fall back to
    ///      a direct transfer so the funds still land there. The code-length check avoids calling
    ///      a function on a code-less address (which reverts uncatchably).
    function _routeLpSlice(address sink, uint256 amount) internal {
        if (sink.code.length > 0) {
            usdc.forceApprove(sink, amount);
            // Isolate the sink like the creator slice (H-PM-1): a reverting/misconfigured LP sink
            // must NOT be able to brick fee routing — and therefore all trading. On failure, clear
            // the dangling approval and redirect the slice to the treasury so it still lands somewhere.
            try IFeeSink(sink).notifyFee(amount) {
                // delivered to the LP sink as yield
            } catch {
                usdc.forceApprove(sink, 0);
                _payTreasury(amount);
                emit LpFeeRedirected(sink, amount);
            }
        } else {
            usdc.safeTransfer(sink, amount);
        }
    }
}
