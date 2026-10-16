// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FablesLedger} from "./FablesLedger.sol";
import {LedgerLib} from "../libraries/LedgerLib.sol";
import {DistributorSwept, ClaimFeeSwept} from "./LedgerTypes.sol";

/// @notice The one WETH surface this hook needs: wrap. Unwrapping never happens here — native ETH
///         only ever LEAVES through the PoolManager's own `take`, and the single place the hook
///         itself must hand ETH to an ERC20-only consumer (the epoch distributor) is a wrap.
interface IWETH9 {
    function deposit() external payable;
    /// @dev For WETH9 this IS the contract's ether balance — the identity the constructor probe
    ///      tests, and the cheapest available evidence that a candidate is the wrapper rather than
    ///      merely a token.
    function totalSupply() external view returns (uint256);
    /// @dev Read by the constructor purely to force an ABI DECODE — the value is discarded. A
    ///      payable catch-all returns empty returndata here and the decode reverts, which is the
    ///      only cheap way to tell a wrapper from a contract that merely swallows ether.
    function balanceOf(address) external view returns (uint256);
}

/// @title FablesNativeETH
/// @notice The native-currency machinery over `FablesLedger`, shared by every hook whose currency0
///         is NATIVE ETH. FOUR of them are deployable today, not two: `FablesRampETH`
///         (flat-fee-plus-poke) and `FablesRWAETH` (the session-floor calendar curve), plus their
///         `*Exclusive` variants. `FablesRampETH` — the only one live on mainnet — deploys from
///         `script/wave2/W2_01_DeployHooks.s.sol`; the other three have scripts in
///         `DeployAnyHook.s.sol`, whose own header says it covers the variants that had none. Robinhood Chain's real
///         ETH liquidity is quoted in native
///         ETH, not WETH — the WETH pools are dead — so an ETH desk that wants the flow must speak
///         native.
///
///         PRICING-AGNOSTIC, deliberately: this mixin adds only what native currency requires and
///         says nothing about how a fee is chosen. It was extracted from `FablesRampETH`, and this
///         header went on describing THAT contract ("Same flat-fee-plus-poke pricing") after
///         `FablesRWAETH` — a calendar hook — began inheriting it. THREE of the four leaves carry no
///         contract-level NatSpec at all (`FablesRampETH`, `FablesRWAETH`, `FablesRWAETHExclusive`),
///         so this is the only doc their readers get.
/// @dev WHAT NATIVE ACTUALLY TOUCHES. Uniswap v4 already moves native ETH itself on every payout
///      (`take` pays LPs' withdrawals and claims directly), and swappers settle with the
///      PoolManager, never with the hook. Exactly three seams remain — but seam 3 has TWO wrap
///      boundaries, not one, and the claim-fee wrap is the one whose ABSENCE was a round-2
///      defect (`test/AuditRegressionsR2.t.sol`), so it is named rather than implied:
///        1. pay-in — `LedgerLib._resolvePrincipal` settles a native deposit with
///           `settle{value:}` from the hook's balance, prepaid by the depositor
///           (`FablesLedger.deposit` is payable, requires `msg.value >= amount0Max`, and refunds
///           the unspent remainder in full at the end);
///        2. the gate — `_nativeAllowed()` is the coupled switch: overriding it to true is what
///           lets `beforeInitialize`/`_checkKey` admit native pools on THIS hook while every
///           ERC20-only hook keeps refusing them;
///        3. revenue — the epoch distributor and the claim-fee splitter both speak only ERC20, so
///           BOTH native sweeps wrap into WETH at this boundary — the staked-fee sweep
///           (`_sweepDistributor` override) and the claim-fee sweep (`_sweepClaimFee` override) —
///           and
///           everything downstream (distributor, settlement indexer, merkle claims) stays
///           ERC20-pure. LP-facing money (withdraw, claimFees, withdrawAndClaim) stays native: LPs deposited ETH
///           and get ETH back.
///
///      WHAT THIS HOOK NEVER DOES WITH ITS OWN MONEY: hold ETH between transactions. Deposits
///      refund their unspent remainder in the same call; the sweep wraps and forwards within its
///      own call. Every native balance the hook creates for itself is zero by the end of the
///      transaction that created it.
///
///      IT CAN STILL HOLD A STRANGER'S ETH, AND THAT ETH STAYS PUT. `selfdestruct` and a coinbase
///      payout reach the balance without running code, so "nobody can send it here" is not
///      available at any price. What IS available is choosing what happens to it next, and the
///      refund is where that is chosen. Refunding the whole balance — the obvious reading of
///      "return what is unspent" — made every parked wei payable to whoever deposited next, for
///      the cost of over-sending one wei. That is not recirculation; it is a race, and the only
///      reliable winner is whoever is watching hardest. `_refundNative` therefore measures the
///      balance the caller actually arrived with (`FablesLedger._foreignNative`) and returns the
///      delta, so a forced transfer is untouchable by everyone including the protocol — exactly for
///      ETH parked in a PRIOR transaction, which `_setForeignNative` snapshots. ETH arriving DURING
///      the deposit call is the one exception: `receive()` is PoolManager-only, but `SELFDESTRUCT`
///      moves a balance without invoking code (before and after EIP-6780), so a hostile pool
///      currency's `transferFrom` — reached inside `_resolvePrincipal` for the currency1 leg — can
///      raise this hook's balance mid-call and the delta then returns it to the depositor. No loss:
///      the attacker is recovering their own ETH, the currency must be admin-listed to be there at
///      all, and a stranger's earlier park stays unreachable. Stated because the absolute is what a
///      reader would otherwise build on. Stranding
///      it is the deliberate choice: unowned, unreachable ETH costs nothing, while a first-come
///      claim on it is a standing incentive to grief. Nothing here is a payout path, so there is
///      no rescue function to add — a rescue is the same extraction with a permission attached.
///
///      `receive()` is allowlisted to the PoolManager — the only counterparty that legitimately
///      pays this contract ETH (`take` during the wrap-sweep). WETH9 never sends ETH here
///      (`deposit` is a one-way wrap and nothing ever calls `withdraw`), and unsolicited transfers
///      are refused outright rather than silently absorbed.
///
///      ERC20 pools still work on this hook unchanged — `_nativeAllowed` ADDS native capability,
///      it does not require it. Whether to point ERC20 pools here or keep them on per-pool
///      `FablesRamp` instances is a deployment (blast-radius) decision, not a code one.
abstract contract FablesNativeETH is FablesLedger {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    error UnauthorizedETHSender();
    /// @dev The constructor's WETH probe refused the candidate. Named rather than left as the ABI
    ///      decoder's bare `revert(0,0)`, because this is an immutable on a CREATE2-bound hook: the
    ///      operator gets one chance to read the reason, and "failed to create runtime bytecode"
    ///      does not name WETH as the cause.
    error NotWrappedEther();

    /// @notice Emitted when a NATIVE revenue sweep is delivered to its sink as WETH.
    /// @dev DISTRIBUTOR ONLY, and this event alone — the claim-fee leg has its own,
    ///      `NativeClaimFeeWrappedToWeth`. An earlier version of this block opened by claiming the
    ///      opposite ("Fires on BOTH native sweeps"), left over from before the split. That was not
    ///      merely stale: solc CONCATENATES adjacent doc blocks with no separator, so the
    ///      published devdoc read "...MUST credit WETH from this event... just know.DISTRIBUTOR
    ///      ONLY." — the false instruction first, its retraction second. An integrator following the
    ///      first half over-credits the distributor by the claim-fee leg and under-credits the
    ///      claim-fee sink, which is precisely the mis-attribution the split below exists to
    ///      prevent. Two lenses reported it independently, one having measured it with
    ///      `forge inspect devdoc`.
    ///
    ///      It pairs with the clearing event that fired alongside it, `DistributorSwept(address(0),
    ///      distributor, amount)`. The two describe one sweep from two sides and BOTH are
    ///      load-bearing for the settlement indexer: the clearing event retires the ledger's NATIVE
    ///      accrual (denominated in `address(0)`, matching the `FeesCollected` events that fed it),
    ///      while THIS event states the token actually delivered. An indexer reconciling the
    ///      DISTRIBUTOR's balances MUST credit WETH from this event, not native ETH from the
    ///      clearing one.
    ///
    ///           WHY A SECOND EVENT RATHER THAN A WIDER ONE. When the claim-fee sweep also needed a wrap receipt, the
    ///           obvious move
    ///      was to widen this event to cover both sinks — but the signature and therefore the
    ///      topic0 would have been unchanged, so a consumer written against the old meaning ("the
    ///      distributor received WETH") would silently over-credit the distributor by the
    ///      claim-fee leg and under-credit the claim-fee sink, with nothing in the log to signal
    ///      the change. The ledger already solves exactly this by giving each sink its own
    ///      clearing event (`DistributorSwept` / `ClaimFeeSwept`); the wrap receipts now mirror
    ///      that, so an old consumer keeps decoding only what it always meant.
    event NativeRevenueWrappedToWeth(address indexed distributor, address indexed weth, uint256 amount);

    /// @notice Emitted when a NATIVE claim-fee sweep is delivered to its recipient as WETH.
    /// @dev The claim-fee twin of `NativeRevenueWrappedToWeth`, separate for the reason given
    ///      there. Pairs with the `ClaimFeeSwept(address(0), recipient, amount)` that fires
    ///      alongside it: that one retires the ledger's NATIVE `claimFeeOwed` accrual (denominated
    ///      in address(0), matching the `FeesCollected` events that fed it), while THIS one states
    ///      the token actually delivered. An indexer reconciling the claim-fee sink's on-chain
    ///      balances MUST credit WETH from here, not native ETH from the clearing event.
    event NativeClaimFeeWrappedToWeth(address indexed recipient, address indexed weth, uint256 amount);

    /// @notice The canonical wrapped-ETH contract native revenue is wrapped into for the
    ///         ERC20-only distributor. Immutable: a mutable WETH would be a mutable custodian of
    ///         every future native sweep.
    IWETH9 public immutable weth;

    constructor(IWETH9 weth_) {
        // A probe, not just a non-zero check. This is the only irreversible external dependency in
        // the family with no round-trip test, and it is `immutable` on a non-upgradeable hook whose
        // address is CREATE2-bound to its pools — so a wrong wrapper cannot be corrected, and every
        // native staked-fee accrual on it becomes permanently unsweepable (`distributorOwed` is
        // zeroed only inside the call that then reverts on `weth.deposit`). Every sibling wiring
        // write already probes: `setVoter` round-trips `ve()`, `setBallotGate` probes two selectors,
        // `setDistributor` try/catches `ff()`.
        //
        // THIS USED TO BE THE CODE-LENGTH TEST ALONE, and the comment above already claimed it was
        // a probe. It was not: any contract passed. The failure that let through is not a clean
        // revert, which is what makes it worth two lines instead of one. A wrong-but-payable
        // address makes `weth.deposit{value: amount}()` succeed and KEEP the ether, and SafeERC20
        // then treats the empty returndata from an address-with-code as success as well — so the
        // accrual is zeroed, `DistributorSwept` fires, and every wei of native revenue is silently
        // and permanently destroyed on a hook whose CREATE2 address is bound to its pools and
        // cannot be corrected.
        //
        // The reads below need no value and no try/catch: a bare payable fallback returns EMPTY
        // returndata, and the ABI decoder reverts trying to read a uint256 out of nothing. So the
        // first passes only for an address that genuinely answers `balanceOf`.
        //
        // THAT ALONE ESTABLISHES "SOME ERC20", NOT "THE ETHER WRAPPER", and the gap is not
        // academic: a contract with `balanceOf` AND a payable catch-all clears it and then
        // reproduces the silent-destruction path above in full — measured destroying 499999999999998
        // wei of native revenue with `DistributorSwept` firing as if it had worked. A plain ERC20
        // clears it too. So the second check tests WETH9's DEFINING IDENTITY instead: every unit
        // of supply is one wei of ether this contract is holding, so `totalSupply()` can never
        // exceed its own balance. That is an equality for the real wrapper, false for an ordinary
        // ERC20 with any supply, and false for the payable-fallback shape (which reports supply it
        // does not hold, or fails to decode at all). Anti-MISTAKE, not anti-adversary — a hostile
        // deployment can implement `totalSupply()` — and misconfiguration is the threat model for
        // an immutable constructor argument.
        //
        // ONE CHECK, NOT TWO, AND DELIBERATELY NOT `balanceOf(address(this)) == 0`. That second
        // check was tried and REMOVED: it discriminates nothing the supply identity does not
        // already reject, and it buys a permanent, front-runnable deploy brick. This hook's address
        // is CREATE2-mined — its low bits encode the v4 permission flags — so it is computable, and
        // publishable, before the code exists. Anyone could send ONE WEI of WETH to that
        // counterfactual address and revert the constructor at it forever, forcing a re-mine. A
        // check whose only effect is to let a stranger veto a deployment is worse than no check.
        //
        // The supply identity is not griefable the same way: force-sending ether to WETH RAISES its
        // balance, which makes `totalSupply() > balance` LESS likely to trip, not more.
        //
        // NOT a deposit/withdraw round-trip, deliberately: that needs a payable constructor holding
        // ether, which contradicts this contract's headline invariant that it never holds ETH
        // between transactions, and changes the deploy shape of every native hook. The deep
        // round-trip belongs in the deploy script (`W2_01._assertWeth`), and both are needed —
        // the script probe is deeper but bypassable and only runs where someone wrote it, while
        // this one is shallow but runs on every path that can ever construct the hook.
        //
        // WHAT NEITHER CATCHES: an honest, fully round-trippable WETH9 that is simply the WRONG
        // deployment — a second instance, a bridged wrapper, a dry-run leftover. Canonicality is a
        // fact about the world, not about the contract, so no on-chain probe of any depth decides
        // it. Only an explicit assertion against a known address in the deploy script, plus
        // post-deploy verification of `hook.weth()`, closes that one.
        if (address(weth_).code.length == 0) revert ZeroAddress();
        // TWO READS, AND BOTH ARE LOAD-BEARING FOR DIFFERENT SHAPES.
        //
        // The first is a DECODE probe: its value is discarded on purpose. A payable catch-all
        // returns EMPTY returndata for any call it does not implement, and the ABI decoder reverts
        // trying to read a uint256 out of nothing — so this rejects the shape that answers
        // `totalSupply` and swallows everything else, which is the one that reproduces the original
        // silent-destruction path in full: `deposit{value:}` lands on the fallback and keeps the
        // ether, SafeERC20 scores the empty returndata from an address-with-code as a successful
        // transfer, and the accrual is zeroed with `DistributorSwept` firing as if it had worked.
        // Measured at 499999999999999 wei on the distributor leg.
        //
        // This probe was ONCE WRITTEN AS `balanceOf(address(this)) != 0` and then deleted whole
        // when that comparison turned out to be a front-runnable deploy brick — one wei of WETH
        // sent to the mined CREATE2 address reverted the constructor there forever. Only the
        // COMPARISON was the defect; the read is what does the work, and removing both left the
        // hole above. Discarding the value keeps the check and drops the veto.
        //
        // The second tests WETH9's defining identity — every unit of supply is one wei of ether
        // this contract holds — so it rejects an ordinary ERC20 with any supply.
        //
        // `<=`, not `==`. Canonical WETH9 defines `totalSupply()` AS `address(this).balance`, so
        // for it the two are equal by construction and an equality test would also pass; the
        // inequality is what tolerates a STORED-SUPPLY variant, where ether force-sent to the
        // contract raises the balance without minting and a burn-then-send `withdraw` lowers the
        // supply first. Both are legitimate states that `==` would refuse.
        //
        // And deliberately not `totalSupply() != 0`: a freshly deployed, genuinely canonical WETH9
        // has zero supply. Refusing that is the same mistake as the deploy brick, inverted — a
        // check that rejects a correct configuration.
        weth_.balanceOf(address(this));
        if (weth_.totalSupply() > address(weth_).balance) revert NotWrappedEther();
        weth = weth_;
    }

    /// @notice Native pools are admitted on this hook — the override travels with the payable
    ///         deposit, the `settle{value:}` pay-in and the wrap-sweep that make them work.
    function _nativeAllowed() internal pure virtual override returns (bool) {
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
    function _sweepDistributor(Currency currency) internal virtual override {
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

    /// @dev The NATIVE currency's claim-fee sweep — the exact mirror of `_sweepDistributor` above,
    ///      and for the same reason. `LedgerLib.sweepClaimFee` ends in
    ///      `poolManager.take(currency, claimFeeRecipient, amount)`, which for native is a bare
    ///      `call`; the protocol's own designated sink for ledger claim fees,
    ///      `FablesTreasurySplitter`, is ERC20-only with no `receive`, so that call reverted and
    ///      the pool's claim-fee revenue was unsweepable by anyone, forever.
    ///
    ///      Deliberately pull-shaped like its sibling: an unset recipient parks the accrual instead
    ///      of reverting, so a hook with no claim-fee recipient configured — the shipped default —
    ///      never blocks `_settleSinks` and the admin rotations that run through it.
    function _sweepClaimFee(Currency currency) internal virtual override {
        if (!currency.isAddressZero()) {
            super._sweepClaimFee(currency);
            return;
        }
        uint256 amount = claimFeeOwed[currency];
        if (amount == 0) return;
        address to = claimFeeRecipient;
        if (to == address(0)) return; // unset sink: the accrual simply keeps waiting
        claimFeeOwed[currency] = 0;
        LedgerLib.payout(poolManager, currency, currency, amount, 0, address(this));
        weth.deposit{value: amount}();
        IERC20(address(weth)).safeTransfer(to, amount);
        // Same two-sided record as the distributor sweep: `ClaimFeeSwept` clears the native
        // accrual the `FeesCollected` stream fed (denominated in address(0)), while
        // `NativeClaimFeeWrappedToWeth` states the token the recipient actually received. An
        // indexer reconciling the sink's balances must credit WETH from the second event.
        //
        // NAMING THE RIGHT TOPIC MATTERS HERE SPECIFICALLY. The two wrap receipts are separate
        // topics on purpose — see their declarations — so that a consumer written against one
        // cannot over-credit the distributor and under-credit the claim-fee sink. This comment
        // used to name `NativeRevenueWrappedToWeth`, the DISTRIBUTOR's topic, which is the single
        // mistake that separation exists to prevent, in the one place an indexer author reads
        // while wiring this leg.
        emit ClaimFeeSwept(currency, to, amount);
        emit NativeClaimFeeWrappedToWeth(to, address(weth), amount);
    }
}
