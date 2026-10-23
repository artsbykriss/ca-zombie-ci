# SaucerSwap V2 — source review vs canonical Uniswap V3 (fork diff)

Verified source obtained from Sourcify v2 (`https://sourcify.dev/server/v2/contract/295/<addr>?fields=all`);
all four contracts are `exact_match`/`match` on Sourcify; compiler `0.8.12+commit.f00d7308`, optimizer
enabled runs 2000, evm `london`. Canonical UniV3 core (`0.7.6`) and periphery pulled from GitHub and
diffed function-by-function (normalised whitespace/comments).

## Core (`UniswapV3Factory.sol`, `UniswapV3Pool.sol`, libraries)

Semantically a faithful port. Differences:

| Area | Fork change | Security impact |
|---|---|---|
| `UniswapV3Pool.mint` | now `payable`; requires `msg.value >= HbarConversion.tinycentsToTinybars(factory.mintFee())`; HBAR retained in the pool | none E-U — HBAR only leaves via owner-gated `collectProtocol` |
| `UniswapV3Pool.collectProtocol` | after token payouts, sends `address(this).balance` to `factory.rentPayer()` | owner-only (`onlyFactoryOwner`) |
| `UniswapV3Pool.collect/swap/flash` | token moves via `TransferHelper.safeTransfer(token, address(this), recipient, amt)` → HTS precompile `transferToken` | caller is the pool (owner of the value) → allowed |
| Pool constructor | `AssociateHelper.safeAssociateTokens(address(this), [token0,token1])` | Hedera requirement; no auth surface |
| `UniswapV3Factory` | adds `rentPayer`, `poolCreateFee`, `mintFee`, `collectRent()`, `setPoolCreateFee`, `setMintFee`, `setRentPayer` | `collectRent()` is permissionless but only forwards factory HBAR to `rentPayer` (no theft) |
| libraries | 0.7.6 → 0.8.12 mechanical port: `LiquidityMath.addDelta` inlined as checked arithmetic; `unchecked` blocks added; `require`→custom errors; `TickMath`/`Oracle`/`Tick`/`TickBitmap`/`SqrtPriceMath`/`SwapMath`/`FullMath`/`BitMath` semantics preserved | audit UVP-02M (addDelta) re-checked: 0.8.12 checked arithmetic reverts on the same conditions as canonical → nullification valid |

## Periphery (`NonfungiblePositionManager.sol`, `SwapRouter.sol`, `QuoterV2.sol`)

| Area | Fork change | Security impact |
|---|---|---|
| `NonfungiblePositionManager` | **not** an ERC721 itself; the LP position NFT is an external HTS token (`nft`, set once by `deployer` via `createNonFungible`, guarded by `onlyOnce`) | `_isApprovedOrOwner` replaced by `isAuthorizedForToken` reading `IERC721(nft).ownerOf/getApproved/isApprovedForAll` on the HTS NFT. **Bound to this collection** — no cross-collection tokenId confusion; `nft` immutable after creation |
| `mint` | mints HTS NFT serial via precompile, assumes serial == `_nextSN++`, transfers to `params.recipient` | supplyKey = NFPM only → serials cannot desync |
| `increaseLiquidity` | no auth (canonical) | permissionless but only *adds* liquidity; cannot remove value |
| `decreaseLiquidity` / `collect` / `burn` | `isAuthorizedForToken` | NFT-owner/operator gated |
| `TransferHelper` (periphery) | `safeTransferFrom` calls HTS `transferToken(token, sender, receiver, amt)` directly (not ERC20 `transferFrom`) | **Network enforces allowance**: docs.hedera.com HSCS security model v2 — `transferToken` behaves as ERC20 `transfer` if caller owns the value, otherwise requires an owner-granted spender allowance. So equivalent to ERC20 `transferFrom`, **not** an arbitrary-`from` drain |
| `PeripheryPayments` | `receive()` restricted to WHBAR; `unwrapWHBAR`/`sweepToken`/`refundETH` remain `public` and permissionless | canonical UniV3 sweep helpers — only move balances already sitting in the contract |
| `SwapRouter` | adds `Ownable` + `associateSwapRouterToToken` (owner-only) | none E-U |
| `PoolInitializer.createAndInitializePoolIfNecessary` | payable; requires `address(this).balance >= poolCreateFee` | with `poolCreateFee≈$1M`, new pool creation is frozen |

## Negative results (do not re-investigate)

1. HTS `transferToken` with an explicit `sender` ≠ caller is allowance-gated by the Hedera network →
   no arbitrary-`from` drain through the router/NFPM `pay()`/`safeTransferFrom` paths.
2. `msg.sender` in `pay()`/`SwapCallbackData.payer`/`MintCallbackData.payer` is always the external
   caller (multicall uses `delegatecall`, preserving `msg.sender`) → no victim-as-payer injection.
3. LP-NFT `nft` address cannot be changed (deployer + `onlyOnce`); no admin/kyc/freeze/wipe/pause keys
   on the HTS NFT (mirror node) → no privileged NFT manipulation.
4. Pool positions are keyed by `msg.sender`; a stranger calling `pool.collect`/`burn` on another's tick
   range gets 0 (proven in PoC).
5. No EIP-1967 proxy on factory/NFPM/router/quoter (impl slot 0) → not upgradeable.
6. Library contracts are `public` and delegatecalled; on Hedera `SELFDESTRUCT` does not delete contract
   code, so library addresses are stable.
7. Fee-on-transfer tokens would revert `mint`/`swap` (balance-delta checks), not leak value.

## Prior audits

- Omniscia — SaucerSwap V2 **core** (2023-09-27) and **periphery** (final `ab9210c4a1`, 2023-07-30):
  all findings alleviated/acknowledged/nullified. UVP-01M (rent-fee distribution) fixed via the
  credit/`collectProtocol` model present in the deployed code. UVP-02M (addDelta) nullified.
- Halborn (2026-05) covers a *different, newer* stack (Universal Router / Permit2 / UniswapX) — not
  the V2 CLMM factory/pool/NFPM/router reviewed here.
