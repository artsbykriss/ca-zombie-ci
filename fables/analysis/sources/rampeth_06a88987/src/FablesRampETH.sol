// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FablesRamp} from "./FablesRamp.sol";
import {LedgerLib} from "./libraries/LedgerLib.sol";
import {DistributorSwept} from "./base/LedgerTypes.sol";

/// @notice The one WETH surface this hook needs: wrap. Unwrapping never happens here — native ETH
///         only ever LEAVES through the PoolManager's own `take`, and the single place the hook
///         itself must hand ETH to an ERC20-only consumer (the epoch distributor) is a wrap.
interface IWETH9 {
    function deposit() external payable;
}

/// @title FablesRampETH
/// @notice `FablesRamp` for pools whose currency0 is NATIVE ETH. Robinhood Chain's real ETH
///         liquidity is quoted in native ETH, not WETH — the WETH pools are dead — so an ETH desk
///         that wants the flow must speak native. Same flat-fee-plus-poke pricing, same ledger,
///         same roles; this contract adds only the machinery that native currency requires.
/// @dev WHAT NATIVE ACTUALLY TOUCHES. Uniswap v4 already moves native ETH itself on every payout
///      (`take` pays LPs' withdrawals and claims directly), and swappers settle with the
///      PoolManager, never with the hook. Exactly three seams remain, and they live in three
///      places:
///        1. pay-in — `LedgerLib._resolvePrincipal` settles a native deposit with
///           `settle{value:}` from the hook's balance, prepaid by the depositor
///           (`FablesLedger.deposit` is payable, requires `msg.value >= amount0Max`, and refunds
///           the unspent remainder in full at the end);
///        2. the gate — `_nativeAllowed()` is the coupled switch: overriding it to true is what
///           lets `beforeInitialize`/`_checkKey` admit native pools on THIS hook while every
///           ERC20-only hook keeps refusing them;
///        3. revenue — the epoch distributor speaks only ERC20, so the NATIVE currency's
///           staked-fee sweep wraps into WETH at this boundary (`_sweepDistributor` override) and
///           everything downstream (distributor, settlement indexer, merkle claims) stays
///           ERC20-pure. LP-facing money (withdraw, claimFees) stays native: LPs deposited ETH
///           and get ETH back.
///
///      WHAT THIS HOOK NEVER DOES: hold ETH between transactions. Deposits refund their whole
///      remaining balance in the same call; the sweep wraps and forwards within its own call. A
///      nonzero balance at rest is a stranger's forced transfer, and the next native deposit
///      returns it to circulation via the full-balance refund.
///
///      `receive()` is allowlisted to the PoolManager — the only counterparty that legitimately
///      pays this contract ETH (`take` during the wrap-sweep). WETH9 never sends ETH here
///      (`deposit` is a one-way wrap and nothing ever calls `withdraw`), and unsolicited transfers
///      are refused outright rather than silently absorbed.
///
///      ERC20 pools still work on this hook unchanged — `_nativeAllowed` ADDS native capability,
///      it does not require it. Whether to point ERC20 pools here or keep them on per-pool
///      `FablesRamp` instances is a deployment (blast-radius) decision, not a code one.
contract FablesRampETH is FablesRamp {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    error UnauthorizedETHSender();

    /// @notice Emitted when a NATIVE staked-fee sweep is delivered to the distributor as WETH.
    /// @dev Pairs with the `DistributorSwept(address(0), distributor, amount)` that fires alongside
    ///      it. The two describe one event from two sides, and BOTH are load-bearing for the
    ///      off-chain settlement indexer: the `DistributorSwept` clears the ledger's NATIVE
    ///      `distributorOwed` accrual (which is denominated in address(0), matching the
    ///      `FeesCollected` events that fed it), while THIS event states the delivered token —
    ///      the distributor speaks only ERC20 and receives `amount` of `weth`, never native ETH.
    ///      An indexer reconciling the distributor's on-chain token balances MUST credit WETH from
    ///      this event, not native ETH from the `DistributorSwept`, or native staked-fee revenue is
    ///      mis-attributed in the merkle. Making the conversion an explicit on-chain fact removes
    ///      the alternative — an undocumented `address(0) -> weth` convention the indexer had to
    ///      just know.
    event NativeRevenueWrappedToWeth(address indexed distributor, address indexed weth, uint256 amount);

    /// @notice The canonical wrapped-ETH contract native revenue is wrapped into for the
    ///         ERC20-only distributor. Immutable: a mutable WETH would be a mutable custodian of
    ///         every future native sweep.
    IWETH9 public immutable weth;

    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_, IWETH9 weth_)
        FablesRamp(poolManager_, authority_, absoluteMaxFee_)
    {
        if (address(weth_) == address(0)) revert ZeroAddress();
        weth = weth_;
    }

    /// @notice Native pools are admitted on this hook — the override travels with the payable
    ///         deposit, the `settle{value:}` pay-in and the wrap-sweep that make them work.
    function _nativeAllowed() internal pure override returns (bool) {
        return true;
    }

    /// @notice ETH may arrive only from the PoolManager (its `take` during the wrap-sweep). The
    ///         depositor's own prepay arrives as `msg.value` on `deposit`, not through here.
    receive() external payable {
        if (msg.sender != address(poolManager)) revert UnauthorizedETHSender();
    }

    /// @dev The NATIVE currency's staked-fee sweep: same bookkeeping as the library's
    ///      (`LedgerLib.sweepDistributor`), different last hop — take the ETH to this contract,
    ///      wrap it, and forward WETH, because the distributor cannot receive or hold native. The
    ///      FF-sink fork in the library is deliberately absent here: FF is an ERC20, so the native
    ///      currency can never be it. Every other currency falls through to the library path
    ///      untouched. Pull-shaped like the original: an unset distributor keeps the accrual
    ///      waiting rather than reverting.
    function _sweepDistributor(Currency currency) internal override {
        if (!currency.isAddressZero()) {
            super._sweepDistributor(currency);
            return;
        }
        uint256 amount = distributorOwed[currency];
        if (amount == 0) return;
        address to = distributor;
        if (to == address(0)) return; // unset sink: the accrual simply keeps waiting
        distributorOwed[currency] = 0;
        // Burns the hook's claims and takes real ETH to this contract (allowed by `receive`),
        // inside the same PAYOUT unlock the library uses.
        LedgerLib.payout(poolManager, currency, currency, amount, 0, address(this));
        weth.deposit{value: amount}();
        IERC20(address(weth)).safeTransfer(to, amount);
        // Two sides of one sweep: `DistributorSwept` clears the native accrual (see the base
        // library, which the ERC20 currencies still route through), `NativeRevenueWrappedToWeth`
        // names the token the distributor actually received. See the event's NatSpec.
        emit DistributorSwept(currency, to, amount);
        emit NativeRevenueWrappedToWeth(to, address(weth), amount);
    }
}
