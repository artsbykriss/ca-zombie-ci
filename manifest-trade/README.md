# Manifest Trade (Solana) — global-seat eviction + Token-2022 fee delta

**Date:** 2026-10-21 · **Chain:** Solana mainnet-beta · **Program:** `MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms`
**Status:** read-only. Nothing signed or broadcast. `simulateTransaction` only (never submitted). No secrets in this folder.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Global seat eviction (`global_evict`) | **$0** | Eviction requires `num_seats_claimed >= 999`; **all 6 live global accounts have 0 seats** and **all 6 global vaults hold 0 tokens** (slot 459,675,283). Live simulation of the exact instruction returns `InvalidEvict` ("Eviction is only allowed when global is at capacity"). Even at capacity the path pays the evictee **their own full balance** and requires the evictor to deposit **more** than that balance — no value or authority moves to the evictor. | A future bug in the CLOB itself; upgrade authority. |
| Token-2022 transfer-fee delta | **$0** | Every inbound credit is measured as the **actual vault balance delta** (`after - before`), so a fee mint credits only what arrived. `global_evict` re-measures after its own deposit. Outbound debits are nominal and the recipient bears the fee. No inflation, no double-count. | None found. |
| Whole program (4,257 markets) | **$0** | All value paths (`withdraw`, `swap`, `claim_seat`, `global_*`, `defrag`) are bound to the caller's own seat/vault; no state read or simulation moves another trader's funds. | Upgrade authority `CDFU8tEW…3Cbf` is a single key (privileged). |

**Total live extractable now: $0 (E-U).** Confidence: **high**.

---

## 2. What the program is, and what "at risk" means here

Manifest is a fully permissionless central-limit order book. Makers deposit tokens into per-market PDAs
(`vault` seeds `[b"vault", market, mint]`), claim a seat, and rest orders. The $17.28M DefiLlama figure is
**maker collateral backing resting orders**, not a custody pool: the only way to receive it is to trade
against those orders at their prices. A bug would have to let someone *withdraw* another trader's deposit.

Live on-chain measurement at **slot 459,675,283** (`analysis/scan_markets.py`):

| Metric | Value |
|---|---|
| Markets enumerated (`getProgramAccounts`, discriminator `4859840929024028656`) | **4,257** |
| Market vaults with a non-zero balance | **2,441** |
| Distinct mints with a balance | **1,120** |
| Priced value (875/1,120 mints; DeFiLlama + Jupiter, 2026-10-21) | **$12,848,220.57** |
| Unpriced remainder (382 long-tail/memecoin mints) | not valued (DL total $17.28M includes them) |
| Largest single vault | USDC `EPjFWdd5…Dt1v`, **4,391,273.58** (~$4.389M) |
| Global (cross-market) vaults | **6 accounts, all balance 0** |

---

## 3. The deployed build: byte-for-byte release v3.0.26

The lead was "program upgraded 3.6 h before the pass-3 read". Verified:

| Item | Evidence |
|---|---|
| Programdata | `G92J4ZFggKZ9LbsQ2zBpajRvRto7ed7uRuJJqWsX4BhJ`, account len 486,669 |
| Last deploy slot | **459,237,697** (2026-10-20 12:55 UTC; upgrade tx `4ta3y1DnCtt5Arpp…`) |
| Upgrade authority | `CDFU8tEWsVU2ZMiek57Sgk3Huha2yBNcSHLAts3V3Cbf` |
| ELF size / sha256 | 360,232 B of ELF + zero padding; **sha256 `31ac04c9159fa7090430759ec47e13f6a901cd708464656131be2addb5c36996`** |
| Upstream release | `program-v3.0.26` `manifest.so` = **same sha256** (GitHub `CKS-Systems/manifest`, tag `program-v3.0.26`, 2026-10-16) |
| Source commit | `c51120b` "Lenient market index hints, independently budgeted defrag, collector-only global clean (#764)" |

`cmp` over the first 360,232 bytes is identical; the remaining 126,392 bytes are zeros from the oversized
programdata account. **The deployed bytecode is exactly the published v3.0.26 release.**

Upgrade history of the authority (`getSignaturesForAddress`): 2026-07-13, 2026-07-24, 2026-09-16,
2026-10-15, **2026-10-20**. So the 2026-10-20 upgrade replaced the 2026-10-15 build (v3.0.25 lineage) with v3.0.26.

### What v3.0.26 changed (diff `program-v3.0.25..v3.0.26`)

- `global_clean` (tag 12) becomes **collector-only** (`payer == B6dmr2UAn2wgjdm3T4N1Vjd8oPYRRTguByW7AEngkeL6`).
  Before, anyone could remove an *unbacked* global order and claim its 5,000-lamport gas prepayment.
- `defrag` becomes callable (collector-only, same key).
- Index hints become "lenient": a stale/out-of-bounds hint falls back to the canonical tree lookup instead of
  reverting. The fallback re-validates `(node type, trader pubkey, sequence number)` before use — see
  `state/market.rs:967-1012` (`resolve_trader_index`, `resolve_order_index`), so a hint is never authorization.
- No change to `global_evict.rs`, `global.rs`, `deposit.rs`, `withdraw.rs`.

Net: the upgrade **removed** a (tiny) permissionless payout, it did not add an unprivileged path.

---

## 4. Lead A — can an outsider evict a seat and take the funds/authority?

Code (`programs/manifest/src/program/processor/global_evict.rs`):

1. `charge_eviction_fee` — evictor pays rent×2 + `10_000 × 5_000` lamports into the **global account**.
2. Capacity gate: `require!(global.needs_eviction())` where `needs_eviction() = num_seats_claimed >= MAX_GLOBAL_SEATS`
   (`MAX_GLOBAL_SEATS = 999`, `state/constants.rs:55`).
3. Lowest-balance gate: `verify_min_balance_at_deposit_index` requires the evictee to be the **minimum**
   depositor (`deposit_index == global_deposits_max_index`).
4. **Withdraw**: `reduce_at_deposit_index(evictee, evictee_balance)` then
   `spl_token_transfer_from_global_vault_to_evictee(..., evictee_balance)` — the evictee's full balance is paid
   to **the evictee's own token account** (owner field must equal the seat owner).
5. **Evict + take seat**: `evict_and_take_seat` requires `existing_global_atoms_deposited == 0` (satisfied by step 4)
   and moves the seat/deposit slot to the evictor. A seat is only a `(pubkey → deposit_index)` record: it holds no
   authority over any other account.
6. **Deposit**: evictor transfers `amount_atoms`, the vault delta is measured, and
   `require!(evictee_balance < deposited_amount)`.

So the evictor must deposit **strictly more** than the evicted balance, and the evicted trader is made whole
before the seat is reassigned. There is no branch in which the evictor receives the evictee's tokens.

**Live state — the gate cannot even be reached:**

```
6 global accounts (getProgramAccounts, dataSize 96), slot 459,675,283
  YWE5YVRb…4bM  mint GkdbD4Kj…JTM  seats 0  vault XCBApZcW…Gad  amount 0
  3B7x1opT…Zmp  mint HoRK5WCs…MfA  seats 0  vault HrWt3WMQ…594  amount 0
  7SVenoiA…uhy  mint upJiToEq…aPL  seats 0  vault 3xoT34Gn…1ZZ  amount 0
  A8yKjzZo…tga  mint CRWVJeR2…Fmi  seats 0  vault 9kPCHUGB…P8G  amount 0   (Token-2022)
  DFL4YjUx…ahX  mint FxieKLFn…sfn  seats 0  vault 6M7HngSM…Lbq  amount 0
  FqTMBBFR…Si3  mint XsGAnis8…Jya  seats 0  vault BPBjyQTX…gX2  amount 0   (Token-2022)
```

**Live simulation** (`analysis/sim_evict.json`, `simulateTransaction`, `sigVerify:false`, never submitted):
payer `8MaVa9kd…8D5` (a real holder of `GkdbD4Kj…`), amount 1,000,000,000,000 atoms, slot 459,686,127:

```
Program log: global_evict.rs:93 Eviction is only allowed when global is at capacity
Program MNFSTqtC…1Ms failed: custom program error: 0x14 (InvalidEvict)
unitsConsumed 3043
```

To arm the path someone would first have to claim 999 seats (~1.5 SOL of rent) — and even then the payout is
zero-sum: the evictor pays the evictee in full and deposits more than the evicted balance. The only harm is that
the evictee's resting **global** orders become unbacked (their 5,000-lamport/order prepayment is forfeit, now
collector-only).

---

## 5. Lead B — Token-2022 transfer-fee delta

Manifest supports Token-2022 (2 of the 6 globals are Token-2022 vaults). Fee-bearing mints are handled by
measuring the vault, never by trusting the instruction amount:

| Path | Code | Behaviour |
|---|---|---|
| `global_deposit` | `global_deposit.rs:76-103` | if vault is Token-2022: `before = vault.amount`, transfer, `after = vault.amount`, **credit = after − before** |
| market `deposit` | `deposit.rs:74-112` | same measured delta (`spl_token_2022_transfer_checked`) |
| `global_evict` deposit leg | `global_evict.rs:145-166` | always measures `after − before`, then enforces `evictee_balance < deposited_amount` **after** the fee |
| `global_withdraw` / market `withdraw` | `global_withdraw.rs:75-95`, `withdraw.rs` | debit `amount_atoms`, send `amount_atoms`; the fee is withheld from the recipient (they keep it as `withheld_amount`, claimable from the mint), the vault is not over-drawn |
| `get_balance_atoms` | `validation/token_checkers.rs` | reads SPL `amount` at offset 64..72, which excludes `withheld_amount` — no phantom credit |

So a 100 %-fee mint credits 0, a 10 %-fee mint credits 90 %, and the eviction threshold is computed on the net.
There is no `deposited_amount` that exceeds what the vault holds, hence no way to mint a claim against other
depositors' tokens.

---

## 6. What an attacker can and cannot do (exact)

| Call | Preconditions | Result |
|---|---|---|
| `global_evict` | 999 seats claimed **and** evictee is the minimum depositor **and** evictor deposits > evictee balance | evictee paid in full, evictor gets a seat worth exactly their deposit. **Net ≤ −fee.** Live: reverts `InvalidEvict`. |
| `global_clean` | caller == `B6dmr2UAn2…` | blocked for everyone else since v3.0.26 |
| `defrag` | caller == `B6dmr2UAn2…` | blocked |
| `withdraw` / `swap` | caller's own seat | pays the caller only; `trader_index` resolved by pubkey, hint re-validated |
| `claim_seat` | any signer | opens a seat on a market; no funds move |

---

## 7. PoC / verification

- **Byte identity:** `analysis/dump_elf.py` → `manifest_current.so`; `sha256` == release `program-v3.0.26`; `cmp` prefix identical.
- **Live state:** `analysis/scan_markets.py` (4,257 markets, 8,514 vaults, 6 globals) → `analysis/market_scan.json`,
  prices → `analysis/mint_usd.json`.
- **Instruction simulation:** `analysis/sim_evict.py` → `analysis/sim_evict.json` (custom error 0x14 + program log).
- **Negative results:** no global seats, no global orders, no non-zero global vault; `global_clean` and `defrag`
  gated on the collector key; no unbounded/arbitrary-call surface in the program (no `invoke` with user-supplied
  program ids; every CPI target is the token program or the system program, both validated).

---

## 8. Verdict

**$0 extractable by an external unprivileged attacker. Confidence: high.** The eviction path is both
economically zero-sum and, at the live state, unreachable (0/999 seats, empty vaults, live simulation reverts).
The Token-2022 fee accounting is delta-based on every inflow and cannot be inflated.

Residual/latent risk:
- **Upgrade authority** `CDFU8tEW…3Cbf` is a single key with no timelock on-chain — it can replace the program
  and take all $12.85M of priced vault value. Privileged (P), not E-U.
- A future CLOB logic bug (matching engine) would put maker collateral at risk, but none was found here; the
  Certora specs cover deposit/withdraw/swap/seat and the v3.0.26 diff only loosens hints with re-validation.
- The 0.05 SOL eviction fee makes seat-eviction griefing cost ~$6/seat even when armed.

---

## 9. Method, caveats, files

Read-only. `getAccountInfo`/`getProgramAccounts`/`getMultipleAccounts`/`simulateTransaction` against
`api.mainnet-beta.solana.com` and `solana-rpc.publicnode.com` (keyless). Prices: DeFiLlama `coins.llama.fi`
+ Jupiter `lite-api.jup.ag` on 2026-10-21; HYPE/SOL at that snapshot. No keyed RPC URL is stored in this folder.

Caveats: (1) 382 of 1,120 mints are unpriced, so $12.85M is a floor for the vault value; DL's $17.28M is not
independently confirmed. (2) `simulateTransaction` was run at a slot ~500 above the state snapshot; the global
accounts' seat counts and zero balances were read directly at slot 459,675,283 and re-read during simulation.
(3) No local validator/fork was used; the deployed ELF is verified by hash and exercised by the live simulator.

Files: `analysis/dump_elf.py`, `analysis/manifest_current.so`, `analysis/sigs_*.json`, `analysis/globals.py`,
`analysis/scan_markets.py`, `analysis/market_scan.json`, `analysis/mint_usd.json`, `analysis/sim_evict.py`,
`analysis/sim_evict.json`, `ci/run.sh`, `ci-out/manifest-verify.json`.
