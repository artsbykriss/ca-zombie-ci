# Serum Swap (SPL token-swap) — live on-chain state summary

**Scope:** the program `SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8` (DefiLlama slug `serum-swap`).
**Date:** 2026-10-15. **Read-only.** No transaction was signed or sent; all RPC calls are `get*`/
`simulateTransaction` only, against the keyless public endpoint `https://api.mainnet-beta.solana.com`.
**Snapshot:** state read at slots ≈ 457,162,187 – 457,166,000 (raw dumps in `pools-raw.json`,
`raw-program-accounts.json`; individual reads cited below with their slots).

---

## 1. Enumeration method and raw counts

| step | call | result |
|---|---|---|
| program account | `getAccountInfo(SwaPpA9…, finalized)` @ slot 457,162,187 | executable, owner `BPFLoaderUpgradeab1e…`, 36 bytes, 1,141,446 lamports |
| programdata | `getAccountInfo(FV9WWFWYzWHDpAc8oxiFKV1LmFUyWw7HGdo4GK19MiZW)` @ slot 457,162,688 | 619,629 bytes; header `state=3 (ProgramData)`, `last_deploy_slot=73,737,036`, `upgrade_authority=Some(DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn)`; ELF magic `7f454c46` at byte 45 (confirms the 45-byte header) |
| all accounts owned by program | `getProgramAccounts(SwaPpA9…, base64, finalized)` | **340 accounts** |
| full data re-fetch | same, for decoding | 224 KB, stored in `raw-program-accounts.json` |

**Account-size histogram:** `324 bytes × 339`, `323 bytes × 1`.
`324 = 1 + 323 = SwapVersion::LATEST_LEN = 1 + SwapV1::LEN` (version byte + `SwapV1`).
`is_initialized` byte: `1 × 292`, `0 × 48` (the 323-byte account is uninitialized).
So: **292 initialized pools**, 48 empty (rent-funded) accounts.

### Verified state layout (byte offsets, from the deployed build's own `Pack` impl)

Matched against `solana-labs/solana-program-library@9281b6e82899` (2021-04-14),
`token-swap/program/src/state.rs` — `mut_array_refs![1,1,32,32,32,32,32,32,32,64,33]`:

| offset | field |
|---|---|
| 0 | `version` (=1, `SwapVersion` tag) |
| 1 | `is_initialized` |
| 2 | `nonce` (PDA bump stored at init) |
| 3, 35, 67, 99, 131, 163, 195 | `token_program_id`, `token_a`, `token_b`, `pool_mint`, `token_a_mint`, `token_b_mint`, `pool_fee_account` (32 B each) |
| 227 | `fees` = 4× (num,den) u64 pairs = trade 25/10000, owner-trade 5/10000, owner-withdraw 0/0, host 20/100 |
| 291 | `swap_curve` = 1 B curve-type (`0`=ConstantProduct, `1`=ConstantPrice) + 32 B params |

Empirical confirmation of the offsets: byte 3 of every initialized pool decodes to
`TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`, bytes 35/67 decode to the *creator's* token accounts
(correct mints), byte 99 to the LP mint, 195 to a token account holding the LP mint, and byte 2 is
the PDA nonce (e.g. `0xfe` for the sample pool `12FgKuYmh23rYdWUJpgn7QFWjNek7Jkfo8quNq6shuEb`).

### Authority / PDA verification (all 292 pools, from the live state)

* `Pubkey::find_program_address([pool], SwaPpA9…)` (solders) reproduces the authority; **292/292**
  pools have `vault_a.owner == vault_b.owner == PDA([pool], stored nonce)` and
  `pool_mint.mint_authority == PDA`.
* Every pool's `token_program_id` is the real SPL Token program (`Tokenkeg…`); every vault is a
  165-byte Tokenkeg account. **No pool has vaults owned by anything else** (no mis-initialised pool,
  no foreign token program).
* `pool_fee_account` is deterministic per pool and, in **292/292** cases, is a Tokenkeg account
  **owned by `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN`** (the SPL/Serum program-owner fee
  address). That address holds 0.800000018 SOL and has recent on-chain activity
  (signatures at slots 428,231,971–428,232,036 and 448,722,414).

### Fee-structure histogram (no absurd values anywhere)

| trade num/den | owner-trade | owner-withdraw | host | pools |
|---|---|---|---|---|
| 25/10000 | 5/10000 | 0/0 | 20/100 | 286 |
| 0/10000 | 5/10000 | 0/0 | 20/100 | 6 (ConstantPrice test pools) |

Maximum trade fee anywhere = **0.25 %**, maximum owner fee 0.05 %, no withdrawal fee, no pool with
`trade_fee_numerator >= trade_fee_denominator` (which `Fees::validate()` would reject).

### Pools with no LP supply (dust traps)

85 pools have `pool_mint.supply == 0`; 11 of them still hold non-zero vault balances, total **$0.05**
(realizable prices) of dust. Deposits into a zero-supply pool **revert** in this build (see
`gates.md` §Pre-#1637 behaviour), so that dust is unrecoverable by anyone (`S`).

---

## 2. Live value (prices and totals)

### Prices used

* **DefiLlama** `coins.llama.fi/prices/current/solana:<mint>` (2026-10-15) for all 73 mints with
  non-zero balances → `llama_prices.json` snapshot values in `pools.json`.
* **"Realizable"** price: the live DexScreener price of the deepest pair for that mint **if that
  pair has ≥ $1,000 liquidity**, else DefiLlama for the deep majors (SOL/USDC/USDT), else **$0**
  (token has no observable market). Snapshot: `dexscreener_full.json`.

Key divergences (why two numbers are reported):

| mint | token | DefiLlama | live DEX | liquidity |
|---|---|---|---|---|
| `CWE8jPTUYhd…` | soLINK (Sollet) | $12.11 | **$1.32** | $2,173 |
| `BQcdHdAQW1hc…` | soUSDT (Sollet) | $0.9991 | **no market** → $0 | — |
| `3JSf5tPeusc…` | soYFI (Sollet) | $2,194.48 | **no market** → $0 | — |
| `AGFEad2et2ZJ…` | soFTT (Sollet) | $0.2480 | $0.5811 | $3,653 |
| `So111111…112` | SOL | $102.97 | $103.07 | $27.5 M |
| `EPjFWdd5…` | USDC | $0.99963 | $1.00 | $23.1 M |

### Totals (292 pools)

| metric | value |
|---|---|
| **Σ vault value — DefiLlama prices** | **$259,285.47** |
| **Σ vault value — realizable prices** | **$204,350.99** |
| DefiLlama protocol page (`api.llama.fi/protocol/serum-swap`) | $221,430.68 |
| LP value attributable to the program-owner fee account (`HfoTxFR1…`) | $182,343.34 = 70.3 % of the llama total; $140,698.78 = **68.9 %** of the realizable total |
| LP value attributable to all other LP holders | — / $63,652.21 = 31.1 % |
| pools with non-zero vaults | 218 |
| pools with non-zero value (realizable) | 189 |

The DefiLlama page figure ($221 k) sits between the two — its own adapter does not include the
largest pool's SOL side ($71.7 k in `AmHUjHK…`); see caveats in §6.

### Top pools (full table: `pools.json`; 292 rows)

| # | pool | curve | vault A | vault B | USD llama | USD realizable |
|---|---|---|---|---|---|---|
| 1 | `AmHUjHKfSFP34D4VgPsviFNjWrvTN761Yazvv2eKAsSz` | ConstantProduct | 696.794 wSOL | 71,728.83 USDC | $143,453.95 | $143,548.11 |
| 2 | `HChRYaZ38LLk4CjZZrKJh6AYxfSSpoMUWkmi7My4xoMr` | ConstantProduct | 140.230 wSOL | 14,453.99 USDT | $28,880.52 | $28,907.69 |
| 3 | `Cy7H3umyRa6FLrcgTnJcpKj2VVNm8AKgL56583TBVy7E` | ConstantProduct | 46.393 wSOL | 17,463.62 soUSDT | $22,224.42 | $4,781.73 |
| 4 | `GX6EbhfboagJVtpb7zNhKpJBwZzkidjdizDtQppz2tb5` | ConstantProduct | 2,181.89 USDC | 8,005.86 soUSDT | $10,179.39 | $2,181.89 |
| 5 | `9Jv8DVVocLaNT8hVp8mMPUXgTSTAg2YYeZDfWXwrmMuM` | ConstantProduct | 0.984 soYFI | 6,842.85 soUSDT | $8,995.95 | $0.00 |
| 6 | `GdgnDYJ9mk9oQR9FXWKennphd67cjCihahb54NfKezHY` | ConstantProduct | 541.26 soLINK | 715.24 USDT | $7,269.84 | $1,429.70 |
| 7 | `CegiBTejBzcQPwY8mXRWznU8kJu2o5acu4NQCqDcqNQc` | ConstantProduct | 498.19 soLINK | 657.13 USDC | $6,690.59 | $1,314.75 |
| 8 | `2QvejGqx1yAx5CwTPczaC5XRC7YPGtRM7ApzWNCTCZ9Q` | ConstantProduct | 12.720 wSOL | 1,310.97 USDC | $2,620.31 | $2,622.03 |
| 9 | `9FNrmdX1SogNsERixVd14c1nG5YTTAgV3UVBt23osz6p` | ConstantPrice (price 1) | 2,455.57 soUSDT | 0.382 USDT | $2,453.63 | $0.38 |
| 10 | `E2VW1AjtT2GrhqkEm9bnH7y7wa99EKqbj3mcby2mgbVZ` | ConstantProduct | 85,470.6 (no-market) | 2,147.87 USDC | $2,147.07 | $2,147.87 |

**Bulk of the value:** 2 SOL/USDC(SDT) pools (`AmHUjHK…`, `HChRYaZ…`) = **$172.5 k / $172.5 k**, i.e.
~66 % of the llama total and ~84 % of the realizable total. Their vault balances were re-verified
independently with `getTokenAccountBalance` (e.g. `3vnX3jx5…` = `696.794210803` SOL raw
`696,794,210,803`, `34YKkqGe…` = `71728.828918` USDC) — see §5 for slots.

### Pool activity is live

`getSignaturesForAddress` on the top pools returned signatures at the **current** slot range
(457,128,801 – 457,163,289, blockTime 1,792,043,975 – 1,792,051,294 = today). Decoding them shows
third-party **aggregator-routed swaps** touching the vaults (e.g. slot 457,163,236: vault A of
`AmHUjHK…` −33,687,962 lamports, vault B +3,478,145 USDC-units). The pools are therefore live,
tradeable, and arbited continuously — relevant to §3.

---

## 3. Arbitrage reality (NOT a bug — separate note)

Anyone can trade at curve prices. The question "what is a *bug* extractable" is answered in
`gates.md`: **$0**. The question "is there still free money for an arbitrageur because reserves are
stale vs. market" is answered here:

| metric | value |
|---|---|
| Σ max arbitrage profit at **DefiLlama** prices (both directions, fees 0.30 % applied, exact deployed integer math) | **$15,186.78** |
| Σ max arbitrage profit at **realizable** prices (input must be bought at its live DEX price) | **$4.22** |
| Collapse of the two numbers | the $15 k is concentrated in 3 pools whose *other* side is an unmarketable Sollet token (`soUSDT` `BQcdHdAQ…`, `soYFI` `3JSf5tPe…`): `Cy7H3umy…` $3,952, `GdgnDYJ…` $2,937, `CegiBTej…` $2,705, `GX6Ebhf…` $1,820, `9Jv8DVV…` $1,306. Under DefiLlama prices these tokens are "worth" their underlying; in reality they have no observable market |
| Real side at risk against an unmarketable side (sum of the *valuable* side of pools whose other side has no market) | $13,414.58 — extractable **only by someone who already holds the dead token** (they must pay it in), capped by the pool's valuable reserve |
| The $4.22 that survives a "must buy the input token at market" assumption | 4 ConstantPrice pools (see below) |

ConstantPrice mispricing (fixed-rate pools, so a stale rate can be drained on one side):
`8yhLe8FA…` (USDC ⇄ wUSDC_v1 at 1:1) $3.52; `9FNrmdX1…` (soUSDT ⇄ USDT at 1:1) $0.38;
`Hv1NE8gU…`, `CQSemsem…`, `DRetx8Fw…` $0.10 each. **Total $4.22.** All other ConstantPrice pools are
balanced at their fixed rate or hold ≤ $0.01.

Interpretation: the constant-product pools are efficiently arbitraged already (a 0.30 % round-trip
cost kills the residual), and the only genuine mis-pricings are trivially small. The $13.4 k
"unmarketable-side" figure is a *liquidity/valuation* fact, not a protocol flaw: it is the value a
holder of dead Sollet tokens could extract by selling them into these pools — a normal AMM sale.

---

## 4. Program version analysis (what is actually deployed)

**Deployed build fingerprint**

* ELF: 619,584 bytes, sha256 `f86b866c8717f4a052bd61b36bfd1dee203d32673a0bb5cb1fbd8b99f8e65719`
  (extracted from programdata FV9WWFWY… at slot 457,162,688).
* `strings` shows source paths from the developer's machine:
  `/home/armaniferrante/Documents/code/src/github.com/solana-labs/solana-program-library/…` and
  modules `token-swap/program/src/{processor.rs,state.rs,curve/{base,constant_product,constant_price,stable,offset,fees}.rs}`,
  `libraries/math/src/uint.rs` — i.e. the **multi-curve token-swap** line of SPL.
* The error-message set matches `token-swap/program/src/error.rs` byte-for-byte in wording
  (28 messages incl. "Error: The provided fee does not match the program owner's constraints",
  "Error: Given pool token amount results in zero trading tokens",
  "Error: The fee calculation failed due to overflow, underflow, or unexpected 0").
* The account layout the live accounts actually use (`SwapVersion` version byte + `SwapV1` = 324 B,
  `fees` as 64 B of numerator/denominator pairs, `swap_curve` 33 B) matches that commit **exactly**.
* The ELF contains the literal `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN`, which is only embedded
  when the crate is compiled with the **`production` feature** (`constraints.rs`:
  `env!("SWAP_PROGRAM_OWNER_FEE_ADDRESS")`). That explains why every one of the 292 live pools has a
  fee account owned by exactly that address and why only `ConstantProduct`/`ConstantPrice` pools exist
  (the production constraint whitelists those two curve types, requires the owner fee address, and
  enforces minimum fees 0/10000, 5/10000, 0/0, 20/100 — all satisfied by the live fee structures).
* Deploy slot **73,737,036** → `getBlock` blockTime **1,618,460,527 = 2021-04-15 04:22:07 UTC**.
  The last `token-swap` commit merged before that time is
  **`9281b6e82899` "feat: adjust fee constraints (#1596)" (2021-04-14 18:33 UTC)**, ~10 h earlier.
  The crate version at that commit is 2.1.0.

**Conclusion:** the live program is the SPL token-swap @ `9281b6e82899` (2021-04-14), built with
`--features production`. Confidence: **high** (layout + string set + date + the behavioural proof in
§5 + the production-only literal).

**Upgrade history** (`getSignaturesForAddress(FV9WWFWY…)`):

| slot | tx | note |
|---|---|---|
| 61,731,957 | `4u1hR4rPeLs5WgiF6gBzurGi6pyPAxG7B42LQaqhMWa9arqKhh` | initial program write |
| 61,737,964 | `58kccyWp5yHDH3MKBRLzVAkNTzMrUxVdULQ4n2AKgSmvRKvTfa` | upgrade |
| **61,737,896** | `2UYXSMxLgoFRQmk4BUuHAyPoftM34jjbjMN22EUmTp7aZbVHJ3` | **failed upgrade, `IncorrectAuthority`** — an unauthorised upgrade attempt was rejected |
| **73,737,036** | `4iDNVHQKuL7a6s3QfESoNWZxkiK4hKbztXupZw2KfcAFb9rr6e` | last upgrade; signer + log `Upgraded program SwaPpA9…`; signer = the authority below |

**Upgrade authority.** The programdata header decodes to
`Some(DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn)`. That address has real on-chain history
(signatures at slots 125,435,062 / 132,118,831 / 151,721,171 / 247,347,437 / 250,475,496, i.e.
2022-03 → 2024-02), but its account **does not currently exist** (`getAccountInfo` → `null`, 0
lamports), so it cannot pay fees unless re-funded; it signed the last upgrade, so the authority is
**not revoked** (`Option = Some`). It is a single key, not a multisig program.
**Discrepancy with the task brief:** the brief states the upgrade authority is
`7orsQE9oBJfD73N4sBekkJmcZuAAxH1siWa2R2qzZuD`. That address has **no signatures and no account**
(`getSignaturesForAddress` → empty; `getAccountInfo` → null) — the authoritative decode of the live
programdata is `DpWjxjJE2SC…`. This is reported to the parent as a correction; both are privileged
(neither is an unprivileged attack surface).

**Known post-deploy fixes (checked against the live build)**

| PR / commit | date | what it fixes | status of the live build |
|---|---|---|---|
| **#1637** `0f4f2b8de9` | 2021-04-29 | zero-supply pools: allow a first deposit (`new_pool_supply()` fallback); move the `min(reserve, amount)` clamp before the slippage check | **predates it.** Consequence: deposits into `supply==0` pools revert (`ZeroTradingTokens`) → the dust in the 11 zero-LP pools is locked (`S`); the clamp ordering in the live build is *stricter* (only ever reverts) |
| **#1714** `58221fc9ae` | 2021-05-12 | CPI program-id checks | **predates it**, but for `token-swap` the commit is **test-only** (fakes `TOKEN_PROGRAM_ID` → `spl_token::id()`); the value paths already bind `token_program_id` per pool and the SPL token program itself enforces mint equality on `transfer` |
| **#1794** `5f692a0b61` | 2021-05-25 | "make single token withdrawal fair": separate `deposit_single_token_type` from `withdraw_single_token_type_exact_out` (`L·(1−√(1−D/S))`) | **predates it — proven live by simulation, §5.** The live build uses `L·(√(1+D′/(S−D))−1)`, which burns **more** LP than the "fair" version for the same output (2.54 % more at 5 % of the reserve). Over-charging the withdrawer cannot be exploited; the residual is a *user loss*, never a gain |
| #2363 `867417306a` | 2021-08-31 | use `find_program_address` on-chain at init (client-chosen nonce before) | predates it; no value impact (authority is always an off-curve PDA the attacker cannot sign for; grinding a new pool key whose PDA collides with an existing pool's authority is a 2²⁵⁶ pre-image) |
| #2590 `f83240a868` | 2021-11-17 | block single-sided deposits for curves whose `allows_deposits()==false` | predates it; **only `OffsetCurve` sets `allows_deposits=false`** in the API and there are **zero** Stable/Offset pools live (production constraints don't even allow them) |
| #2942 `d557474ff9`, #3334 `042da2b687` | 2022 | Stable-curve rounding/ceiling; huge-swap allowance | Stable curve only; no Stable pools live |
| #3484 / mint-close-authority steps | 2022-08 | Token-2022 fee-account handling, mint close authority | live pools are all classic Tokenkeg; no Token-2022 pool exists |

**No live path uses any of the un-fixed code in a way that pays the attacker** (details in
`gates.md`).

---

## 5. Behavioural proof of the deployed math (read-only simulation)

`simulateTransaction` (`sigVerify=false`, `replaceRecentBlockhash=true`, **never sent**) on the
largest pool `AmHUjHK…`, withdrawing an exact 3,586,441,445 raw USDC (5 % of the B reserve) via
`WithdrawSingleTokenTypeExactAmountOut`:

| quantity | value |
|---|---|
| pool-mint supply (snapshot `pools-raw.json`) | 12,264,607,061,681 |
| vault B before → after | 71,728,828,918 → 68,142,387,473 (−3,586,441,445) |
| LP balance of the LP source before → after | 7,854,478,786,491 → 7,536,257,737,888 |
| **LP burned (observed)** | **318,221,048,603** |
| deployed (pre-#1794) formula `ceil(L·(√(1+D′/(S−D))−1))` | 318,221,048,611 → **Δ = 8 (2.5×10⁻¹¹ rel.)** |
| post-fix (#1794) formula `ceil(L·(1−√(1−D′/S)))` | 310,153,567,464 → Δ = 8.07×10⁹ (**2.54 %**) |

Details, instruction bytes and raw response: `simulations.md`, `sim-raw-version-probe.json`,
`sim-version-probe-analysis.json`.

**Gate proofs:** withdrawing with the attacker's *own empty* LP account fails inside the Tokenkeg
`burn` CPI with `custom program error: 0x1` ("insufficient funds") for both `WithdrawAllTokenTypes`
and `WithdrawSingleTokenTypeExactAmountOut` — see `simulations.md`.

---

## 6. Caveats / limitations

1. **Two price layers.** DefiLlama prices Sollet-wrapped tokens (`soUSDT`, `soYFI`, `soLINK`, …) at
   their underlying value; live DEX prices for them are 0–$1.32. Every total is therefore reported
   twice. The mission-specified DefiLlama-only figure is $259,285.47 (TVL) / $15,186.78 (arb).
2. **DefiLlama's own page** reports $221,430.68 for this program; its per-token breakdown omits the
   largest pool's 696.79 SOL side, so the on-chain enumeration in `pools.json` should be treated as
   the ground truth.
3. **LP-holder census** beyond the fee account was not completed (the public RPC rate-limited
   `getTokenLargestAccounts`). The fee-account LP share (68.9 % of realizable value) is from the
   on-chain pool accounts + `getMultipleAccounts`; the remaining 31.1 % is "other LP holders" by
   subtraction, not by enumerating them.
4. `getProgramAccounts` did not return a context slot; adjacent `getAccountInfo` calls returned
   457,162,187 / 457,162,688. Live trades were decoded at slots 457,161,704–457,163,289.
5. Value figures move continuously (the pools are being traded); a re-run of `fetch_state.py` +
   `analyze_value.py` refreshes them.
6. The version probe marked a third-party LP account as a signer **inside a simulated message only**
   (possible because `sigVerify=false`); nothing was signed, sent, or changed on-chain. It is used
   solely to fingerprint the deployed math, and the account it "used" cannot be used by an attacker.
