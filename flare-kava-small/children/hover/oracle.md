# Hover oracle deep-dive (Kava EVM, chain 2222)

**Contract:** `0xE8Ae943de7f036Cfa505127641Eee7c5b6606878` (unverified, 6,771 B runtime) — a **Pyth asset-config oracle**, Compound-convention `getUnderlyingPrice(cToken)`.
**Owner/admin:** `0xcecC934494adED6c0c82C52656a845862176ceeE` (Gnosis Safe v1.3.0, 2-of-8). `pendingOwner = 0`.
**State read at block 23,034,510.**

## 1. What it is (bytecode-derived)

Strings: `invalid Pyth oracle address`, `max stale period cannot be 0`, `asset config doesn't exist`, `invalid price`, `can't be zero address`, `Ownable2Step: caller is not the owner`.
Selectors (PUSH4 table): `0xfc57d4df getUnderlyingPrice(address)`, `0x127ffda0 setUnderlyingPrice(address,uint256)`, `0x27187991 setEtherPrice(uint256)`, `0xca7c4dba getEtherPrice()`, `0x5e9a523c assetPrices(address)`, `0x4f810bb7 tokenConfigs(string)`, `0x41976e09 getPrice(address)`, `0xa4ae35e0 getPriceNoOlderThan(bytes32,uint256)`, `0x703ae1b9 setUnderlyingPythOracle(address)`, plus Ownable2Step.

Storage: slot 0 = owner (Safe); slot 5 = Pyth oracle `0xa2aa501b19aff244d90cc15a4cf739d2725b5729`.

## 2. Price source resolution

`tokenConfigs(string)` maps a **token key** to `{address token, bytes32 pythFeedId, uint32 maxStalePeriod}`. Verified entries (block 23,034,510):

| key | token | Pyth feed id | maxStalePeriod |
|---|---|---|---|
| `"hKAVA"` (native market; no `underlying()`) | `0x0` (native) | `0xa6e905d4e85ab66046def2ef0ce66a7ea2a60871e68ae54aed50ec2fd96d8584` = **KAVA/USD** | 0x4ec = 1260 s |
| `"ATOM"` | `0x15932E26…` (uATOM) | `0xb00b60f88b03a6a625a8d1c048c3f66653edf217439983d037e7222c4e612819` = **ATOM/USD** | 1260 s |
| `"USDt"` | `0x919C1c26…` (uUSDT) | `0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b` = **USDT/USD** | 1260 s |

(`tokenConfigs("KAVA"/"USDT"/"uATOM"/"WKAVA")` are empty — the mapping is keyed by the *underlying's* symbol, and by the *market* symbol only for the native market.)

## 3. Live status: STALE

| Probe | Result |
|---|---|
| `oracle.getUnderlyingPrice(hKAVA / hATOM / hUSDT)` | **reverts `0x19abf40e` = `StalePrice()`** (custom error propagated from Pyth `getPriceNoOlderThan`) |
| `Pyth.getPriceUnsafe(KAVA/USD)` | price 5,403,048 × 1e-8 = **$0.05403**, conf 10,769, publishTime **1774775979** (~2026-03-29) |
| `Pyth.getPriceUnsafe(ATOM/USD)` | 165,717,178 × 1e-8 = **$1.65717**, publishTime 1774775979 |
| `Pyth.getPriceUnsafe(USDT/USD)` | 99,920,425 × 1e-8 = **$0.99920**, publishTime 1774775979 |
| chain time at read | 1,792,064,506 (2026-10-15) → **≈200 days stale** vs the 1,260 s freshness window |
| Pyth contract | proxy `0xa2aa501b…` → UUPS impl `0x36825bf3…`; `version()="1.3.0"`; `getValidTimePeriod()=60`; **`singleUpdateFeeInWei()=0`** |

**Consequence:** every oracle-dependent path reverts — `getAccountLiquidity()`, liquidation, member redeem/transfer, borrow (already paused). Only non-members' `redeem` bypasses the oracle (`redeemAllowedInternal` skips the liquidity check when the redeemer is not in the market).

## 4. Is it manipulable by an unprivileged attacker?

**No — and it does not matter today.** Three independent reasons:

1. **Source is signed Pyth data, not a spot DEX**: prices are only what the Pyth price feeds say. Setting prices requires `setUnderlyingPrice`/`setEtherPrice`/`setUnderlyingPythOracle` → `onlyOwner` (Safe). There is no public push function, no TWAP, no DEX spot read to move.
2. **`Pyth.updatePriceFeeds(bytes[])` is permissionless but not manipulable**: the calldata must carry Pyth-signed VAAs, so an attacker can only *publish the real price* (earlier), never a false one. (And publishing is currently an *upgrade* for liquidation: see §5.)
3. **Borrow is paused** (`borrowGuardianPaused == true` → `borrowAllowed` reverts `"BP"`), so the classic "dust collateral → inflated price → borrow" extraction has **zero** borrow capacity today, regardless of price.

**Quantified borrow capacity with dust collateral (what a fresh attacker could borrow if borrows were ever unpaused with a fresh oracle):** bounded by `collateralFactor × collateral − debt`, per market CF: hKAVA 0.60, hATOM 0.35, hUSDT 0.85. The protocol's entire free liquidity is 28,572.17 KAVA ($1,957.48) + 179.03 ATOM ($301.88) + 0.00001 USDT — i.e. even in the hypothetical unpaused state, the *maximum* borrowable out of the protocol is ~$2,259 before the interest-rate model spikes. No price manipulation is needed or possible for that; it is a pure pause-state question.

## 5. Tripwire: refresh is free and re-arms the bots

- `Pyth.updatePriceFeeds(bytes[])` costs **0 wei** of fee (`singleUpdateFeeInWei()==0`) — only gas (~1M) — and can be called by anyone.
- Fresh VAA data: Pyth Hermes/Benchmarks `/v2/updates/price/latest` now returns **401 unauthorized** without an API key (checked 2026-10-15); the price-feed *metadata* endpoint still works. So the refresh is permissionless at the contract level and gated only by obtaining (free) signed data.
- Effect of a refresh (fork-proven with a mocked fresh oracle, `test_T4`): `liquidateBorrowAllowed(hUSDT, hKAVA, BOT2, underwaterBorrower, 1e6)` returns `0` (NO_ERROR) for the **whitelisted bot**, while the external attacker still receives `1` (UNAUTHORIZED). The estimated gross liquidation bonus available in that window is **≈$136.77** (see README §4).

## 6. Divergence vs real market (for the record)

| Asset | oracle-eligible last Pyth price (2026-03-29) | DefiLlama live price (2026-10-15) | divergence |
|---|---|---|---|
| KAVA | $0.0540305 | $0.0685086 | +26.8% |
| ATOM | $1.6571718 | $1.6864362 | +1.8% |
| USDT | $0.9992043 | $0.9991027 | −0.01% |

Because the oracle **reverts** rather than serving the stale values, there is no live "stale-price extraction" surface (contrast: Bastion/Aurigami in the same campaign, where a frozen-but-serving oracle is a tripwire; Hover's oracle fails closed).
