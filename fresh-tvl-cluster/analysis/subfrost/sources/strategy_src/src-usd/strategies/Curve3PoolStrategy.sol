// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMultiAssetStrategy} from "../interfaces/IMultiAssetStrategy.sol";
import {ICurvePool} from "../interfaces/ICurvePool.sol";

/// @dev The slice of `VaultImpl` this strategy reads. The vault's asset registry
///      is the SOURCE OF TRUTH for what `assetId` means — see `registeredIds`.
interface IAssetVault {
    function assets(uint8 assetId) external view returns (address);
    function assetRegistered(uint8 assetId) external view returns (bool);
    function assetCount() external view returns (uint8);
}

/// @title Curve3PoolStrategy
/// @notice Curve 3pool yield strategy: the vault's USDC and USDT are held as ONE
///         Curve 3pool (DAI/USDC/USDT) LP position.
///
/// @dev WHY LP, RATHER THAN A ONE-SIDED SAVINGS POSITION.
///      3pool holds USDC and USDT natively, so a payout in either is a single
///      `remove_liquidity_one_coin` against the same LP — no swap, no second
///      venue, no third-party router in the withdrawal path. That is precisely
///      what lets ONE vault honour a burn that names either asset: the backing
///      is not denominated in USDC or in USDT, it is denominated in pool shares,
///      and the choice of payout token is made at withdrawal time.
///
///      The previous design routed everything through USDC -> crvUSD -> scrvUSD
///      and swapped back out via Uniswap for the USDT leg. It could only serve
///      one asset per instance (it inferred the asset from `msg.sender`), and
///      every USDT round-trip crossed two extra venues.
///
///      MARKET-NEUTRAL: every position is a ~$1 stablecoin claim, so there is no
///      directional exposure. The variance is the pool's imbalance fee (3pool
///      charges 1bp) plus divergence between the three legs. Yield is the 3pool
///      trading fee, which accrues INTO `get_virtual_price` — no reward claiming
///      and no reward token to sell.
///
///      RESIDUAL RISK worth stating plainly: 3pool contains DAI, so the position
///      is exposed to a DAI depeg pro-rata, and USDC/USDT remain freezable at
///      their issuers. This strategy buys yield and dual-asset redemption, not
///      censorship resistance. The crvUSD variant traded the opposite way.
///
/// @dev AUTHORITY. `owner` configures (pause, slippage) and can trigger the
///      escape hatch, but CANNOT take custody: every exit path pays the
///      `vault`, and `vault` is `immutable`. So a compromised owner key can stop
///      the strategy and force it back to plain custody, and that is all.
///
///      Ownership is TRANSFERABLE (OZ `Ownable`) so a Safe or timelock can be
///      migrated without redeploying, but NOT renounceable — see
///      `renounceOwnership`.
contract Curve3PoolStrategy is IMultiAssetStrategy, Ownable {
    using SafeERC20 for IERC20;

    // ---- Immutable wiring ----

    /// @notice Curve 3pool (DAI=0, USDC=1, USDT=2).
    ICurvePool public immutable pool;

    /// @notice The 3pool LP token (3Crv).
    /// @dev Supplied at construction because 3pool exposes no `lp_token()`
    ///      getter to read it from (verified against the deployed ABI).
    IERC20 public immutable lpToken;

    /// @dev Number of coins in 3pool. The pool's array arguments are fixed-size
    /// `uint256[3]`, so this cannot be made generic without a different ABI.
    uint256 private constant N_COINS = 3;

    /// @dev Basis-point denominator.
    uint256 private constant BPS = 10000;

    /// @dev Hard ceiling on `slippageBps`. Above this the peg anchors below stop
    /// being a meaningful bound and the strategy would accept an arbitrarily bad
    /// fill; `owner` is not trusted with custody and must not be able to create
    /// one by widening tolerance.
    uint256 private constant MAX_SLIPPAGE_BPS = 500; // 5%

    // ---- Config ----

    /// @notice The ONE vault this strategy serves. Set at construction, forever.
    ///
    /// `immutable` because it is the only address funds can ever leave to. If the
    /// owner could repoint it, the owner could point it at themselves and call
    /// `withdrawAll` — the entire access-control model collapses to "trust the
    /// owner key". The compiler enforces that here; nothing at runtime has to.
    ///
    /// Taking it in the constructor rather than a later `setVault` is free: the
    /// wiring is one-directional (the vault's `setStrategy` is a separate
    /// FROST-signed call), so the vault always exists first and its address is
    /// known before this contract is deployed. That also removes the window in
    /// which a deployed strategy sits unwired.
    address public immutable vault;

    /// @notice Whether the strategy accepts deposits. Owner kill-switch.
    /// @dev Only gates DEPOSITS. Withdrawals must keep working while paused or
    ///      pausing would strand the backing.
    ///
    ///      ACTIVE BY DEFAULT, so a deployment needs no owner call to finish and
    ///      the owner can be set straight to its final address at construction.
    ///      Safe because being active is not the same as being reachable: every
    ///      fund movement is `onlyVault`, and the vault does not know this
    ///      strategy exists until a FROST-signed `setStrategy` points it here. An
    ///      active strategy nothing references is inert.
    bool public isActive = true;

    /// @notice Slippage tolerance applied to every pool interaction, in bps.
    uint256 public slippageBps = 50; // 0.5%

    /// @notice Per-asset wiring: which 3pool coin an `assetId` maps to.
    /// @dev Every field is DERIVED at construction — nothing here is supplied by
    ///      the deployer. See `registeredIds`.
    struct AssetInfo {
        IERC20 token; // read from the vault's registry
        uint8 coinIndex; // located by scanning pool.coins() for that token
        uint8 decimals; // read from the token
        bool registered;
    }

    /// @notice `assetId` (the vault's / the burn's id) -> 3pool coin.
    mapping(uint8 => AssetInfo) public assetInfo;

    /// @notice Ids this strategy serves, mirrored from the vault at construction.
    ///
    /// @dev THE VAULT IS THE SOURCE OF TRUTH for what an `assetId` means, and the
    ///      whole registry is derived from it rather than supplied alongside it.
    uint8[] public registeredIds;

    /// @notice Each asset's claim on the shared position, denominated in LP.
    ///
    /// @dev The position is SHARED: one LP balance backs both assets. To report
    ///      `totalAssets(assetId)` without double-counting, it is split pro-rata
    ///      by these shares, so yield accrues to each asset in proportion to
    ///      what it is holding.
    ///
    ///      DENOMINATED IN LP, deliberately — this was originally contributed
    ///      principal in USD, which is wrong. A share credited in USD but
    ///      debited by an LP burn diverges as soon as yield accrues: withdrawing
    ///      exactly what was deposited drives the recorded total to zero while
    ///      the yield is still sitting in the pool, and that residual then reads
    ///      as `totalAssets == 0` — invisible to the vault, undrainable by
    ///      `withdrawAll`, and a false "empty" for the vault's `StrategyNotEmpty`
    ///      guard. Crediting the LP minted and debiting the LP burned keeps both
    ///      sides in the same unit, so the ratio stays exact and yield simply
    ///      remains attributed to whoever still holds shares.
    mapping(uint8 => uint256) public shares;

    /// @notice Sum of `shares` over all registered assets.
    /// @dev Tracked separately rather than read off the LP balance: a
    ///      cross-asset exit (paying USDT out of a USDC-funded position) burns
    ///      LP that no share backed, so the two legitimately diverge.
    uint256 public totalShares;

    // ---- Events ----
    event AssetRegistered(
        uint8 indexed assetId,
        address indexed token,
        uint8 coinIndex
    );
    /// @dev Emitted once, from the constructor — `vault` is immutable.
    event VaultSet(address indexed vault);
    event Deposited(uint8 indexed assetId, uint256 amountIn, uint256 lpMinted);
    event Withdrawn(uint8 indexed assetId, uint256 amountOut, uint256 lpBurned);
    event ActiveSet(bool active);
    event SlippageUpdated(uint256 oldBps, uint256 newBps);
    event EmergencyWithdrawn(address indexed vault, uint256 lpBurned);

    // ---- Errors ----
    error NotVault();
    error StrategyInactive();
    error ZeroAmount();
    error ZeroAddress();
    error UnknownAsset();
    error UnsupportedDecimals();
    error SlippageTooHigh();
    error RenounceDisabled();
    error NoSupportedAssets();

    /// Every mutating fund movement is vault-only. `vault` is immutable and
    /// non-zero, so there is no state in which this gate is open.
    modifier onlyVault() {
        if (msg.sender != vault) revert NotVault();
        _;
    }

    /// @notice Wires the strategy and mirrors the vault's asset registry.
    ///
    /// @dev Takes NO asset arguments. Every id the vault serves that 3pool can
    ///      hold is registered here, with its coin index located by scanning
    ///      `pool.coins()` for the token the VAULT says that id means. There is
    ///      no deployer input left for the two registries to disagree on.
    ///
    ///      Assets the pool cannot hold (a WETH id, say) are SKIPPED rather than
    ///      rejected: the vault is general-purpose and this strategy serves the
    ///      3pool subset of it. Skipping is safe precisely because nothing is
    ///      supplied — a skip means the vault genuinely holds an asset 3pool does
    ///      not, never that someone mistyped an index. If NOTHING matches, the
    ///      strategy would be inert and the deployment is a mistake, so it fails.
    ///
    /// @param _owner Reverts `OwnableInvalidOwner` on address(0) — see `Ownable`.
    constructor(
        address _pool,
        address _lpToken,
        address _vault,
        address _owner
    ) Ownable(_owner) {
        if (
            _pool == address(0) ||
            _lpToken == address(0) ||
            _vault == address(0)
        ) {
            revert ZeroAddress();
        }
        pool = ICurvePool(_pool);
        lpToken = IERC20(_lpToken);
        vault = _vault;
        emit VaultSet(_vault);

        IAssetVault v = IAssetVault(_vault);
        uint8 n = v.assetCount();
        for (uint8 id = 0; id < n; id++) {
            if (!v.assetRegistered(id)) continue;

            address token = v.assets(id);
            (uint8 coinIndex, bool inPool) = _coinIndexOf(token);
            if (!inPool) continue; // not a 3pool coin — not ours to serve

            uint8 dec = IERC20Metadata(token).decimals();
            // `_toUsd18` scales UP by (18 - decimals); a >18-decimal coin would
            // underflow it. 3pool has none, but the check keeps that a fact about
            // the pool rather than an assumption in the arithmetic.
            if (dec > 18) revert UnsupportedDecimals();

            assetInfo[id] = AssetInfo({
                token: IERC20(token),
                coinIndex: coinIndex,
                decimals: dec,
                registered: true
            });
            registeredIds.push(id);
            emit AssetRegistered(id, token, coinIndex);
        }

        if (registeredIds.length == 0) revert NoSupportedAssets();
    }

    /// Locate `token` among the pool's coins.
    ///
    /// @dev Scanned ONCE, at construction, and cached. Both inputs to this
    ///      mapping are fixed for the life of their contracts — the vault's asset
    ///      set is settled at its `initialize`, and 3pool's `coins` are set in its
    ///      Vyper constructor with no setter — so the cached index cannot go
    ///      stale, and re-deriving it on every deposit would spend three
    ///      staticcalls per operation to recompute a constant.
    function _coinIndexOf(address token) internal view returns (uint8, bool) {
        for (uint256 i = 0; i < N_COINS; i++) {
            if (pool.coins(i) == token) return (uint8(i), true);
        }
        return (0, false);
    }

    // ============ Owner config ============

    /// @notice Disabled. Ownership can be TRANSFERRED but never abandoned.
    ///
    /// @dev `owner` holds the `setActive` kill-switch and `emergencyWithdraw`,
    ///      which is the only path that forces the position back to plain
    ///      custody. Renouncing would strand both permanently, leaving a
    ///      strategy that can never be paused or unwound — for no benefit, since
    ///      the owner cannot take custody anyway (every exit pays `vault`).
    ///      `transferOwnership` to a Safe or timelock is the supported move.
    function renounceOwnership() public view override onlyOwner {
        revert RenounceDisabled();
    }

    function setActive(bool a) external onlyOwner {
        isActive = a;
        emit ActiveSet(a);
    }

    function setSlippage(uint256 bps) external onlyOwner {
        if (bps > MAX_SLIPPAGE_BPS) revert SlippageTooHigh();
        emit SlippageUpdated(slippageBps, bps);
        slippageBps = bps;
    }

    // ============ Views ============

    function asset(uint8 assetId) external view override returns (address) {
        return address(_info(assetId).token);
    }

    /// @notice Value attributable to `assetId`, in that asset's own base units.
    ///
    /// @dev The whole LP position valued at `get_virtual_price`, then split
    ///      pro-rata by `shares`. Returning the FULL position for each id
    ///      instead would double-count the backing, since the vault adds this to
    ///      its idle balance once per asset.
    ///
    ///      Uses `get_virtual_price` (invariant / LP supply), not
    ///      `calc_withdraw_one_coin`: the former is monotone in fees and cannot
    ///      be pushed down by imbalancing the pool within a transaction, so an
    ///      attacker cannot make the vault under-report its own backing. It
    ///      therefore excludes the imbalance fee an actual one-sided exit pays —
    ///      an accounting estimate, which is why `withdraw` accounts against the
    ///      amount it MEASURES rather than this.
    function totalAssets(uint8 assetId) public view override returns (uint256) {
        if (!assetInfo[assetId].registered) return 0;
        uint256 ts = totalShares;
        if (ts == 0) return 0;

        uint256 lpBal = lpToken.balanceOf(address(this));
        if (lpBal == 0) return 0;

        uint256 value18 = (lpBal * pool.get_virtual_price()) / 1e18;
        return _fromUsd18(assetId, (value18 * shares[assetId]) / ts);
    }

    /// @notice Total 3pool LP held (both assets' backing combined).
    function lpBalance() external view returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function registeredIdCount() external view returns (uint256) {
        return registeredIds.length;
    }

    // ============ Deposit ============

    /// @notice Pull `amount` of `assetId` from the vault and LP it into 3pool.
    function deposit(
        uint8 assetId,
        uint256 amount
    ) external override onlyVault {
        if (!isActive) revert StrategyInactive();
        AssetInfo memory a = _info(assetId);
        if (amount == 0) revert ZeroAmount();

        // Credit what ARRIVED, not what was asked for: USDT carries a dormant,
        // owner-toggleable transfer fee, and crediting the request would record
        // a share this strategy never received.
        uint256 balBefore = a.token.balanceOf(address(this));
        a.token.safeTransferFrom(vault, address(this), amount);
        uint256 received = a.token.balanceOf(address(this)) - balBefore;
        if (received == 0) revert ZeroAmount();

        uint256[3] memory amounts;
        amounts[a.coinIndex] = received;

        a.token.forceApprove(address(pool), received);
        uint256 lpBefore = lpToken.balanceOf(address(this));
        pool.add_liquidity(amounts, _minLpForDeposit(assetId, received));
        uint256 minted = lpToken.balanceOf(address(this)) - lpBefore;
        // A pool that pulled less than approved would otherwise keep a standing
        // allowance over this strategy's balance.
        a.token.forceApprove(address(pool), 0);

        shares[assetId] += minted;
        totalShares += minted;

        emit Deposited(assetId, received, minted);
    }

    // ============ Withdraw ============

    /// @notice Return `amount` of `assetId` to the vault, burning LP for it.
    ///
    /// Delivers whatever the single-coin exit actually realized, which is
    /// normally a little MORE than requested (the LP burn is over-estimated by
    /// `slippageBps` so the exit clears `amount` even after the imbalance fee).
    /// The surplus goes to the vault rather than being left loose here, where it
    /// would sit outside `totalAssets` and read as a loss.
    function withdraw(
        uint8 assetId,
        uint256 amount
    ) external override onlyVault returns (uint256 actualAmount) {
        AssetInfo memory a = _info(assetId);
        if (amount == 0) revert ZeroAmount();

        uint256 lpBal = lpToken.balanceOf(address(this));
        // Nothing deployed. Return 0 rather than reverting: the vault treats a
        // short delivery as `InsufficientAssets` at the point it actually
        // matters, and a strategy with an empty position must not brick the
        // vault's payout path.
        if (lpBal == 0) return 0;

        uint256[3] memory amounts;
        amounts[a.coinIndex] = amount;
        // `calc_token_amount` ignores fees, so it UNDER-states the LP needed for
        // a one-sided exit. Over-burn by the slippage tolerance so the exit
        // clears `amount`; the surplus is delivered, not kept.
        uint256 lpNeeded = pool.calc_token_amount(amounts, false);
        lpNeeded += (lpNeeded * slippageBps) / BPS;
        if (lpNeeded > lpBal) lpNeeded = lpBal;

        actualAmount = _exitOneCoin(assetId, a, lpNeeded);
        _burnShares(assetId, lpNeeded);

        a.token.safeTransfer(vault, actualAmount);
        emit Withdrawn(assetId, actualAmount, lpNeeded);
    }

    /// @notice Return everything attributable to `assetId` to the vault.
    ///
    /// @dev Burns only THIS asset's pro-rata slice of the shared LP position —
    ///      the other asset's backing stays invested. Draining the whole
    ///      position here would silently liquidate an asset the caller did not
    ///      name and leave the vault's `inStrategy` for it overstated.
    function withdrawAll(
        uint8 assetId
    ) external override onlyVault returns (uint256 amount) {
        AssetInfo memory a = _info(assetId);

        uint256 lpBal = lpToken.balanceOf(address(this));
        uint256 ts = totalShares;
        uint256 share = shares[assetId];
        if (lpBal == 0 || ts == 0 || share == 0) return 0;

        // `>=` rather than `==`: a cross-asset exit burns LP without burning any
        // share, so `totalShares` can exceed the LP balance and the last
        // remaining asset's share can equal the whole total. Cap at the balance.
        uint256 lpShare = share >= ts ? lpBal : (lpBal * share) / ts;

        amount = _exitOneCoin(assetId, a, lpShare);

        totalShares = ts - share;
        shares[assetId] = 0;

        a.token.safeTransfer(vault, amount);
        emit Withdrawn(assetId, amount, lpShare);
    }

    /// @notice Escape hatch: exit the whole LP position to the VAULT.
    ///
    /// @dev Pays the vault, never `owner` — this is what makes the owner key a
    ///      configuration authority rather than a custody one. A compromised
    ///      owner can force the backing home; it cannot take it.
    ///
    ///      Uses a BALANCED `remove_liquidity`, which takes a pro-rata slice of
    ///      all three coins: no swap, no imbalance fee, and no price to
    ///      manipulate — so it still works when a leg of the pool is dislocated
    ///      and the one-sided paths would be refusing on their slippage bound.
    ///      That is also why zero minimums are acceptable HERE and nowhere else:
    ///      there is no exchange rate for a sandwicher to move.
    ///
    ///      The vault receives DAI too. It has no `assetId` for DAI, so that leg
    ///      is not withdrawable through the normal path and is left for
    ///      governance to unwind — deliberate, since the alternative is swapping
    ///      it inside an emergency path that must not depend on a working venue.
    function emergencyWithdraw() external onlyOwner {
        address dest = vault;

        uint256 lpBal = lpToken.balanceOf(address(this));
        if (lpBal > 0) {
            uint256[3] memory minAmounts; // all zero — see above
            pool.remove_liquidity(lpBal, minAmounts);
        }

        for (uint256 i = 0; i < N_COINS; i++) {
            IERC20 coin = IERC20(pool.coins(i));
            uint256 bal = coin.balanceOf(address(this));
            if (bal > 0) coin.safeTransfer(dest, bal);
        }

        // Reset attribution. Stale shares against an empty position would
        // over-attribute anything deposited afterwards.
        uint256 n = registeredIds.length;
        for (uint256 i = 0; i < n; i++) {
            shares[registeredIds[i]] = 0;
        }
        totalShares = 0;

        // Deposits stop until the owner deliberately re-enables. An emergency
        // exit that left the front door open would re-accumulate into whatever
        // condition triggered it.
        isActive = false;
        emit ActiveSet(false);
        emit EmergencyWithdrawn(dest, lpBal);
    }

    // ============ Internal ============

    function _info(uint8 assetId) internal view returns (AssetInfo memory a) {
        a = assetInfo[assetId];
        if (!a.registered) revert UnknownAsset();
    }

    /// Burn `lpAmount` for a single coin and return what actually arrived.
    function _exitOneCoin(
        uint8 assetId,
        AssetInfo memory a,
        uint256 lpAmount
    ) internal returns (uint256 received) {
        if (lpAmount == 0) return 0;
        uint256 balBefore = a.token.balanceOf(address(this));
        pool.remove_liquidity_one_coin(
            lpAmount,
            int128(uint128(a.coinIndex)),
            _minOutForLp(assetId, lpAmount)
        );
        received = a.token.balanceOf(address(this)) - balBefore;
    }

    /// Debit this asset's share by the LP actually burned.
    ///
    /// Floored at the recorded share because an exit may burn LP this asset
    /// never contributed — paying USDT out of a USDC-funded position is the
    /// supported case, not an error, and an unfloored subtraction would revert
    /// on the underflow. The effect is that the burn falls on the remaining
    /// shareholders, which is correct: the LP is one pot backing one liability.
    function _burnShares(uint8 assetId, uint256 lpBurned) internal {
        uint256 s = shares[assetId];
        uint256 consumed = lpBurned > s ? s : lpBurned;
        shares[assetId] = s - consumed;
        totalShares -= consumed;
    }

    /// Minimum LP to accept for a one-sided deposit, anchored to the LP's
    /// virtual price rather than to a same-transaction quote.
    ///
    /// `get_virtual_price` is invariant/supply: it only moves up as fees accrue
    /// and cannot be pushed down by imbalancing the pool inside the transaction.
    /// A `calc_token_amount` floor would float with a sandwicher's manipulation
    /// and bound nothing.
    function _minLpForDeposit(
        uint8 assetId,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 value18 = _toUsd18(assetId, amount);
        uint256 expectedLp = (value18 * 1e18) / pool.get_virtual_price();
        return (expectedLp * (BPS - slippageBps)) / BPS;
    }

    /// Minimum coin to accept for burning `lpAmount`. Peg-anchored, same reason.
    function _minOutForLp(
        uint8 assetId,
        uint256 lpAmount
    ) internal view returns (uint256) {
        uint256 value18 = (lpAmount * pool.get_virtual_price()) / 1e18;
        return _fromUsd18(assetId, (value18 * (BPS - slippageBps)) / BPS);
    }

    /// Asset base units -> 18-decimal USD. Decimals are capped at 18 by the
    /// constructor's registration loop, so the exponent cannot underflow.
    function _toUsd18(
        uint8 assetId,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * (10 ** uint256(18 - assetInfo[assetId].decimals));
    }

    /// 18-decimal USD -> asset base units.
    function _fromUsd18(
        uint8 assetId,
        uint256 value18
    ) internal view returns (uint256) {
        return value18 / (10 ** uint256(18 - assetInfo[assetId].decimals));
    }
}
