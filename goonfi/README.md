# Z3-H2 · GoonFi v2 (Solana prop-AMM) — deep dive: live E-U determination

**Date:** 2026-10-16 · **Chain:** Solana mainnet · **Status:** read-only; all execution in local LiteSVM clones; **no transactions signed or sent**; no secrets.
**Program:** `goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE` (GoonFi v2, proprietary AMM, no public IDL/docs) · **ProgramData:** `124gUYwjVnJQ4sJsFug9gHPzPLEtwCbAQC5LkbaDgx9s` · **Upgrade authority:** off-curve PDA `BBvfpKqYovhzEjS4Ch1xZXFdxkaoUiXsujR9kgN1t8iR` (also authority of the oracle-relay program — one fleet).

## TL;DR

| Target | Live extractable (unprivileged, today) | Why closed | Latent risk |
|---|---|---|---|
| GoonFi v2 (36 markets, **$5.18M** TVL) — Mar-28 mispricing class (caller-supplied "oracle-relay" price) | **$0** | Current build (2026-10-06, sha256 `a24aa13a…`) **binds** the oracle account to the pool (`Custom(32)`), **enforces freshness** (`Custom(21)`), **bounds the price** (`Custom(36)`), **clamps size/capacity** (`Custom(36)`), and the oracle accounts themselves are **write-gated to the keeper key** (`MissingRequiredSignature` for anyone else) | Keeper misquote is instantly consumable by any watcher (bounded per-trade by the +-price band); MM stopping updates freezes the pool (freshness), does not drain it |
| GoonFi v1 `goonERTdGsjnkZqWuVjs73BZ3Pb9qoCUdBUL17BnS5j` (pre-incident build, last upgrade 2025-12-26) | $0 | Program has **0 accounts and 0 recent activity** — dead deployment | none |

**Total live extractable now: $0.00 (E-U), high confidence.** 36 funded markets were swept; every one of them has a fresh, bound, keeper-updated oracle. The March-28 exploit conditions **are not reproducible** against the current build (LiteSVM, cloned live state).

---

## 1. What actually happened on 2026-03-28 (reconstruction)

Tx `5A1YuYHff5RYiZd57M4Ko7PaqoX1GMsYGny9AVaVn826bS1w4nxwbRDyHs4bqJgV6yZfRVQAjmGFDRp9kL6aMGV2` (slot 409,430,505) drained **GoonFi's WSOL vault and BisonFi's USDC vault in one atomic tx**:

| Leg | In | Out | Implied price |
|---|---|---|---|
| GoonFi pool `GMCJvYGf…` (WSOL/USDC) | 4,096.000000 USDC | **1,539.265798532 WSOL** | **$2.661007 / SOL** |
| BisonFi (attacker dumps the WSOL) | 1,539.265798532 WSOL | 127,286.030966 USDC | $82.6917 / SOL |
| **Attacker net** | 4,096 USDC + 1 SOL tip | 127,286.03 USDC | **+123,190.03 USDC** |

Cross-checks:
- Market SOL on 2026-03-28 = **$82.6694** (DefiLlama historical) → BisonFi's leg was priced at market; **GoonFi's leg was 31.1× below market**.
- The GoonFi swap price is read from a caller-supplied 32-byte **oracle-relay** account (see §2). The incident's effective quote = `P/denom = 2.661007` (exact solve: `P = in_B × 1e9 / out_A = 2,661,007`).
- The only GoonFi-market token near $2.661 on that date was **TRUMP = $2.9768** (all others: SOL $82.67, HYPE $40.16, JLP $3.67, ETH $1,999, WBTC $66k, …). Best-fit class: **cross-pool oracle confusion** — the WSOL/USDC pool was priced with another market's oracle (TRUMP/USDC best candidate), i.e. the swap trusted a caller-supplied oracle account without binding it to the pool. Alternative consistent story: the pool's oracle *field* pointed at the wrong oracle at the time, or the keeper pushed a bad value to GMCJ's own oracle. Public data cannot distinguish these three; all three are the same class ("the swap price came from an oracle-relay account that was not validated against the pool's pair").
- The build that was live during the incident (upgrade 2026-03-25 07:02, slot 408,715,553) was replaced **72 hours later** (2026-03-31 10:26, slot 410,071,314) and ~20 more times since; the current build is 2026-10-06 (slot 453,915,006). The March build's ELF is not retrievable from public RPCs (no historical program-bytecode service) — the patch is evidenced behaviorally (§3), not by byte diff.

## 2. Mechanism in exact terms (reverse-engineered + live-verified)

The program has no IDL and no source. Everything below was reconstructed from live accounts/transactions, cross-checked against a public third-party reverse-engineering (github `ivs-ug/goonfi-v2-pool-quote`; Eco SDK `@eco-incorp/sauce` goonfi-v2 adapter) and **verified by executing the real ELF against cloned live state in LiteSVM**.

**Pool account** (36 live, 2,048 B, discriminator `30bc2f353458329a`):
| offset | field |
|---|---|
| 8/16 | capacity_a / capacity_b (rolling trade budget) |
| 32/40 | last update slots |
| 48 | updater key `updapqBoqhn48uaVxD7oKyFVEwEcHmqbgQa1GvHaUuX` |
| 80 / 112 | mint_a / mint_b |
| 144 / 176 | vault_a / vault_b (SPL, owned by the pool PDA) |
| 208 | **oracle-relay account** (32 B, owned by `dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu`) |
| 248… | 9-entry fee-ppm ladder; 1560… size tiers |

**Swap instruction** (tag 1): `[1][direction u8][amount_in u64 LE][min_out u64 LE]`, 13 accounts `[user(s,w), pool(w), userA-ATA(w), userB-ATA(w), vaultA(w), vaultB(w), mintA, mintB, oracle, global(719 kB), ix-sysvar, token, token]` (a 14-account form adds a vote account; the live Jupiter/Titan routes use 13).

**Oracle-relay account** (32 B): `[u64 P1][u64 P2][u32 slot][u32 denom][u64 ts_ms]`; price = `P/denom` in mintB per mintA (denom = 1,000,000 on live pools). Updated **many times per second** by keeper EOAs (e.g. `FTp1BybZ51NiZKbnZH6MsrV3tUZNauhpQMbBcqYUEr5f`) via the `dijkbk` program, whose instruction data (32 B) is copied verbatim into the target account (512-byte ELF; account 0 must be a signer).

**Live price formula (LiteSVM-verified):** `xToY: out_B = in_A × P × 10^(dB−dA) / denom`; `yToX: out_A = in_B × denom × 10^(dA−dB) / P`. Baseline check: sell 1 WSOL → 105.097386 USDC against oracle mid 105.282717 (fee ≈ 176 ppm).

**The `dijkbk` write gate (the crux):** executing the real 512-byte oracle program in LiteSVM:
- keeper pubkey as signer → write succeeds (account data becomes the instruction payload);
- attacker / fresh key as signer (writable or readonly) → `InstructionError(0, MissingRequiredSignature)`, no write.
The oracle accounts therefore cannot be forged by an unprivileged actor; only the keeper key(s) can move prices.

## 3. Live-state assessment + fresh-attacker tests (LiteSVM, cloned mainnet state)

Snapshot: slot ≈ 457,439,272 (2026-10-16), fixtures in `poc/fixtures/`. Current program ELF sha256 `a24aa13a0a9a4d7d1c8752cc9d9a566a5fae3bc20ba0ca3ba11368abd613e43c` (292,384 B; ProgramData last deploy slot 453,915,006).

PoC result matrix (all executed locally + in CI; output `ci-out/poc-output.txt`):

| Test | What it probes | Result |
|---|---|---|
| T0 / T0b | baseline 1 WSOL→USDC / 100 USDC→WSOL | **SUCCESS**, correct prices ($105.10 / $105.50 vs mid $105.28) |
| T1 / T1b | **incident replay**: 4,096 USDC→WSOL, 18- and 20-byte data forms | **SUCCESS** — pays 38.799742877 WSOL (price $105.57). The March outcome (1,539.27 WSOL) is **not reproducible** |
| T2 ×4 | swap with **other live oracles** (HYPE $82.07 / PENGU $0.0076 / cbBTC $82,288 / stale WSOL $83.6) | **REJECTED `Custom(32)`** — oracle must be the pool's own |
| T3/T4/T5 ×5 | byte-identical or repriced **copies** of the pool's oracle at other addresses (stale slot / denom=1 / $2.661 / $2,661 / PENGU-like) | **REJECTED `Custom(32)`** — binding is by account identity, not content |
| T7 | pool2 (TRUMP/USDC) with WSOL oracle | **REJECTED `Custom(32)`** |
| T8 | pool2 baseline with its own oracle | SUCCESS ($1.88 TRUMP) |
| T9a/b | bound oracle slot −1,000,000 / clock +1,000,000 | **REJECTED `Custom(21)`** — freshness enforced |
| T9c–g | bound oracle repriced ±1/5/20% | +1% OK, **+5%/+20% rejected `Custom(36)`**; −5%/−20% accepted (discounts in the pool's favour) |
| T9h | zero price | REJECTED `Custom(9)` |
| T10 | 10 / 1,000 WSOL trades | **REJECTED `Custom(36)`** — capacity/size clamp (1 WSOL OK) |
| T6a–f | **oracle write from attacker** (fresh + attacker signers, SW/S) | **`MissingRequiredSignature`**, no write; keeper signer → write succeeds |
| T6e | program with no accounts | access violation at input-region offset (mechanism confirmation) |

**Sweep of all 36 markets + 70 oracle accounts** (`analysis/market-sweep.json`, `tvl-sweep.json`): total TVL **$5,176,428** (Jupiter prices; DefiLlama lists $5.88M). Every market above $1k TVL has the pool's own oracle, fresh (age ≤ ~600 slots ≈ 4 min), denom exactly 1e6. The stale oracles (age 6M–56M slots, denom ≠ 1e6) belong to empty markets plus one $717 dust market (SOL/USDT) whose swaps the freshness check freezes (`Custom(21)`) — funds sit, nothing is extractable. Top exposures: SOL/USDC $762.6k, ZEC/USDC $636.5k, HYPE/USDC $528.4k, JLP/JupUSD $423.0k.

## 4. What an attacker can / cannot do

- **Cannot** write any oracle account (keeper-gated, §2) — so cannot inject a price.
- **Cannot** use any oracle other than the pool's own (binding, `Custom(32)`) — so cannot import a cheaper price from a sibling market (the March vector).
- **Cannot** use a stale oracle (freshness, `Custom(21)`) or a zero/over-priced quote (bounds, `Custom(9)/(36)`).
- **Cannot** exceed the pool's capacity budget per window (`Custom(36)`).
- The only unprivileged interaction is a normal swap at the keeper-quoted price — i.e. paying the market price (plus fee).
- Costs if a path existed: ~5,000 lamports/tx; no flash-loan requirement (atomic swap on the pool itself) — noted for completeness.

## 5. Verdict & residual risk

**Verdict: E-U = $0.00 (high confidence).** The March-28 mispricing class (caller-supplied oracle-relay price) is closed on the current build by four independent checks, and the oracle-write path is closed by a signer gate. The pre-incident sibling deployment (v1) is dead.

Residual / latent (monitor — not extractable today):
1. **Keeper key custody (P):** a misquote pushed by the keeper is instantly consumable by any watcher (the pool trades at the pushed price subject to bounds/freshness/capacity). The fleet key also controls both GoonFi v2 and the `dijkbk` oracle program via one upgrade-authority PDA.
2. **Liveness (S-adjacent):** if the keeper stops updating a funded pool's oracle, the freshness check freezes that pool's swaps (funds are not drained; they sit in the vaults until updates resume).
3. **Global 719 kB state `BNrK9LpEn…`** is maintained by updater key `updapqBoq…` (disc-0x07 txs); its internal layout is >98% zero-padded and not decoded — it is attached read-only to swaps; no unprivileged influence observed.

## 6. PoC / verification

- `poc/` — Rust + LiteSVM 0.18 harness (`src/main.rs`): clones live accounts from `poc/fixtures/accounts.json` (fetched 2026-10-16, slot ≈ 457,439,272), loads the real GoonFi ELF and the 512-byte `dijkbk` ELF, executes 35 labelled checks. Nothing is signed/sent; no network access at runtime.
- CI: GitHub Actions (public repo) — **run 38831975942, conclusion: success** — `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38831975942` (branch `goonfi`; artifact `result-goonfi`); full program output `ci-out/poc-output.txt` (816 lines, identical to the local run), URL list in `ci-out/ci-urls.txt`, raw log `ci-log.txt`.
- Local run outputs preserved in `analysis/` (see `analysis/run-notes.md`).
- Key numbers: baseline 1 WSOL → 105.097386 USDC; incident replay 4,096 USDC → 38.799742877 WSOL; all oracle-injection/oracle-swap tests rejected.
- Note on the T6 gate matrix: LiteSVM runs with `sigverify=false`, so the keeper-signature test proves the **logic gate** (keeper pubkey accepted, others → `MissingRequiredSignature`); on mainnet the keeper's real private key is additionally required — every real oracle-update tx observed is signed by a keeper EOA.

## 7. Methodology & sources

Live reads (getAccountInfo / getProgramAccounts / getSignaturesForAddress / getTransaction, keyless endpoints; mainnet-beta used only where publicnode lacks getProgramAccounts/history); upgrade-history pagination of both ProgramData accounts; raw wire-transaction decoding (incl. **v1 transactions** used by the keeper); byte-level disassembly of the 512-byte oracle program (30 SBF instructions) and empirical validation in LiteSVM; third-party RE cross-checks (`ivs-ug/goonfi-v2-pool-quote`, Eco SDK docs/npm); DefiLlama historical prices; Jupiter token API for mint identity.

**Caveats:** (1) the March build's ELF is not retrievable from public infrastructure — the "patched" verdict rests on behavioural rejection of the exact March conditions plus the upgrade timeline (Mar-25 build → Mar-31 + ~20 upgrades → Oct-6 build); (2) the March oracle identity is by elimination (TRUMP/USDC best fit, 10.6% below its DefiLlama print that day) — medium confidence on the token, high confidence on the class; (3) LiteSVM clones a point-in-time snapshot; re-verify before acting; (4) the keeper key set may include more than the one key observed (`FTp1BybZ…`) — only that key was positively confirmed.

## Files

```
goonfi/
├── README.md                  ← this file
├── summary.json               ← machine-readable summary
├── analysis/                  ← ELF + ProgramData, upgrade history, market sweep, sims, disassembly
├── poc/                       ← LiteSVM PoC (Rust) + live-state fixtures
├── ci/run.sh                  ← CI job
└── ci-out/                    ← CI output (poc-output.txt)
```
