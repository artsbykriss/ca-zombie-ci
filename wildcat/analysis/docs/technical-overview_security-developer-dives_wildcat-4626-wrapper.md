> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/technical-overview/security-developer-dives/wildcat-4626-wrapper.md).

# Wildcat 4626 Wrapper

Developer reference for the Wildcat4626Wrapper and its factory — functions, rounding, exchange-rate helpers and error codes.

The `Wildcat4626Wrapper` is a vault that wraps a Wildcat market's rebasing debt token with a non-rebasing ERC-4626 share token. Wrapper shares mirror the market's *scaled* balances while the underlying "asset" is the rebasing market token itself.

Make sure you understand the [scale factor](https://docs.wildcat.finance/technical-overview/security-developer-dives/the-scale-factor) before continuing: the wrapper leans on it heavily for all share/asset conversions.

Deployed addresses for factories can be found [here](https://docs.wildcat.finance/technical-overview/contract-deployments).

### TLDR

The 'wrapper' is itself an ERC-4626 vault where:

* The **asset** is the Wildcat market token (the rebasing debt token).
* **Shares** are equivalent to the market's *scaled* token amounts: 1 wrapper share represents `1 * scaleFactor` market tokens at any given time.
* The **exchange rate** between shares and assets is the market's `scaleFactor`. As interest accrues and the scale factor grows, each wrapper share becomes convertible to more market tokens, but the share balance itself does not change.

This means a holder of wrapper shares sees a stable balance that appreciates in *value* over time (via the increasing exchange rate), rather than a balance that constantly rebases upward.

### Contracts

#### `Wildcat4626Wrapper`

An ERC‑4626 vault where:

* **Asset** is the Wildcat market debt token (rebasing ERC‑20).
* **Shares** are a wrapper ERC‑20 that mirrors the market’s *scaled* accounting (non‑rebasing).

The wrapper uses the market's current `scaleFactor` as the exchange rate between shares and assets. Converting assets to shares means dividing the rebasing market-token amount by the scale factor, while converting shares back to assets means multiplying the share amount by that same factor. Because the scale factor grows as interest accrues, a holder's wrapper share balance stays constant while the amount of market tokens those shares can redeem for increases over time.

#### Metadata

**`name()`**

Returns `"<marketSymbol> [4626 Vault Shares]"`.

**`symbol()`**

Returns `"v-<marketSymbol>"`.

**`decimals()`**

Returns `wrappedMarket.decimals()` (same decimals as the market token / underlying asset).

#### Mutating functions

**`deposit(assets, receiver)`**

Deposits `assets` worth of market tokens from the caller and mints shares to `receiver`.

**`mint(shares, receiver)`**

Mints exactly `shares` to `receiver` and pulls the corresponding market tokens from the caller.

**`withdraw(assets, receiver, owner)`**

Burns shares from `owner` and sends `assets` worth of market tokens to `receiver`.

**`redeem(shares, receiver, owner)`**

Burns exactly `shares` from `owner` and sends the corresponding assets to `receiver`.

**`sweep(token, to)`**

Allows the market owner (borrower) to recover `token` sent to the wrapper contract. For the wrapped market token, only surplus above what is owed to share holders is sweepable.

#### Preview functions

**`convertToShares(assets)`**

Returns how many shares `assets` would convert to at the current `scaleFactor`, rounding down.

**`convertToAssets(shares)`**

Returns how many market tokens `shares` would convert to at the current `scaleFactor`, rounding down.

**`maxDeposit(receiver)`**

Returns the maximum amount of market tokens `receiver` can deposit before the wrapper hits the market's `maxTotalSupply`. Returns `0` for sanctioned receivers.

**`previewDeposit(assets)`**

Returns the number of shares a deposit of `assets` would mint, using ERC-4626 preview rounding.

**`maxMint(receiver)`**

Returns the maximum number of shares `receiver` can mint before the wrapper hits the market's `maxTotalSupply`. Returns `0` for sanctioned receivers.

**`previewMint(shares)`**

Returns the amount of market tokens required to mint `shares`, rounding up.

**`maxWithdraw(owner)`**

Returns the maximum amount of market tokens `owner` can withdraw with their current share balance. Returns `0` for sanctioned owners.

**`previewWithdraw(assets)`**

Returns the number of shares that would be burned to withdraw `assets`, rounding up.

**`maxRedeem(owner)`**

Returns the maximum number of shares `owner` can redeem. Returns `0` for sanctioned owners.

**`previewRedeem(shares)`**

Returns how many market tokens would be returned for redeeming `shares`, rounding down.

#### Sentinel

**`sanctionsSentinel`**

Returns the sanctions sentinel used by the wrapper. This is copied from the wrapped market during construction.

**Sanctions checks**

The wrapper uses the sentinel to block sanctioned addresses from interacting with the vault.

#### `Wildcat4626WrapperFactory`

A small factory contract that deploys `Wildcat4626Wrapper` instances and ensures there is at most one wrapper per market.

**`archController`**

Returns the `ArchController` used to verify that a market is registered before a wrapper can be deployed.

**`wrapperForMarket(market)`**

Returns the wrapper address for `market`, if one has already been deployed.

**`createWrapper(market)`**

Deploys a new wrapper for `market`. Reverts if `market` is the zero address, if a wrapper already exists, or if the market is not registered in the `ArchController`.

### Usage Notes

#### Do not transfer tokens directly to the vault

Direct token transfers do not mint shares in return. While there are pathways for recovery please just don't do this.

#### Allowances and approvals

Before calling `deposit` or `mint`, the caller must approve the wrapper to transfer the required amount of market tokens on their behalf. If there is insufficient allowance, the call will fail before any shares are minted. This approval is for the rebasing market token itself, not for the underlying base asset of the market.

#### Preview vs execution rounding

The preview functions follow standard ERC-4626 rounding conventions, which means `previewDeposit` and `previewRedeem` round down while `previewMint` and `previewWithdraw` round up. The actual state-changing functions are aligned to Wildcat's own conversion math and underlying transfer behaviour, so they may not return exactly the same values as the previews. In practice, this means a real `deposit` can mint slightly more shares than `previewDeposit` quoted, and a real `mint` can require slightly fewer assets than `previewMint` suggested. This is expected behaviour rather than slippage or accounting drift.

Previews are therefore suitable for upper- and lower-bound quoting, but should not be used as exact assertions in routers, tests, or accounting flows. If a caller needs deterministic settlement around a target amount, it should choose the state-changing function that fixes that side of the trade, such as `mint` for exact shares or `withdraw` for exact assets.

#### Exiting to the underlying asset

The wrapper does not interact with the underlying market's withdrawal queue at all. When you call `withdraw(assets, receiver, owner)` or `redeem(shares, receiver, owner)`, the wrapper burns your vault shares and executes a `safeTransfer` of the rebasing market token to the `receiver`.

If you subsequently want to convert those market tokens into the actual underlying asset (e.g., USDC), you must interact with the Wildcat market directly following the market’s withdrawal flow (withdrawal request → batch expiry → execution/claim). For more detail on that lifecycle, see [Core Behaviour](/technical-overview/security-developer-dives/core-behaviour.md) and the terminology entries for [Withdrawal Request](/using-wildcat/terminology.md#withdrawal-request) and [Claim](/using-wildcat/terminology.md#claim).

#### Raw exchange rate helpers

For integrators who want the raw exchange rate without picking an arbitrary sample size:

* `assetsPerShareRay()` — returns the market's `scaleFactor` directly. This is a ray value (`1e27 = 1.0`), so a return value of `1.05e27` means each share is currently worth `1.05` market tokens.
* `sharesPerAssetRay()` — returns the inverse (`RAY * RAY / scaleFactor`). Useful for computing how many shares a given deposit would yield.

### Errors

#### `Wildcat4626Wrapper`

**`ZeroAddress()`**

Thrown when the market address, borrower, or sentinel is zero at construction. Also thrown if `sweep` is called with a zero `token` or `to` address.

**`ZeroAssets()`**

Thrown when a `deposit` or `withdraw` amount is zero, when a `mint` or `redeem` request converts to zero assets, or when `sweep` finds no recoverable surplus or token balance.

**`ZeroShares()`**

Thrown when a `mint` or `redeem` amount is zero, or when a `deposit` or `withdraw` request would produce zero shares.

**`CapExceeded()`**

Thrown when a `deposit` or `mint` would push the wrapper past the market's `maxTotalSupply`.

**`SharesMismatch(expected, actual)`**

Thrown when the actual scaled balance delta after a transfer does not match the wrapper's prediction. This acts as a safety check against unexpected market behaviour or rounding mismatches.

**`NotMarketOwner()`**

Thrown when someone other than the borrower calls `sweep`.

**`SanctionedAccount(account)`**

Thrown when a sanctioned address is involved in the operation.

#### `Wildcat4626WrapperFactory`

**`WrapperAlreadyExists(market)`**

Thrown by `Wildcat4626WrapperFactory` when `createWrapper` is called for a market that already has a deployed wrapper.

**`NotRegisteredMarket(market)`**

Thrown by `Wildcat4626WrapperFactory` when `createWrapper` is called for a market that is not registered in the `ArchController`.
