# Z3-C4 deep-dive — BisonFi (Solana prop-AMM / "dark-amm" RFQ v3): live E-U, patch-level verdict, LiteSVM replay

**Date:** 2026-10-16 · **Chain:** Solana mainnet-beta · **Status:** read-only; PoC fork-verified only (LiteSVM, in-process); **no mainnet transactions signed or sent** · **CI:** GitHub Actions `artsbykriss/ca-zombie-ci` (public)

**Target:** program `BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi` · ProgramData `42snJ7ip4zKKsip3EtaMoBo8wzoRsQJSzgUSFXAVJFfG`
**Live funds measured (slot 457,433,682):** pool `8FnX3xo2yYw3EUE6w3nQA4GfXGS9wpK6oj3veJpbFzLo` ("SOL-USDC-Pool2") = **21,259.57 WSOL + 2,395,920.92 USDC ≈ $4,637,065** (SOL $105.4159 from the venue's own publisher feed); 29 POOLSTAT accounts total ≈$18.6M cached fleet value.

---

## TL;DR

| Question | Answer | Evidence |
|---|---|---|
| **Live E-U (external unprivileged extraction)** | **$0** at measured prices. No mispricing path reproduced against the live pool. | LiteSVM replay against cloned mainnet state: swaps execute at $105.32–105.41/SOL (publisher oracle $105.4159); 3% deviation bound + ≤2-slot state freshness + authority-gated state updates (PoC T1–T10, CI) |
| Was BisonFi the victim on 2026-03-28? | **No — BisonFi paid the fair market price.** Its leg: 127,286.030966 USDC paid for 1,539.265798532 WSOL = **$82.6926/WSOL vs market $82.7311** (DefiLlama historical, blockTime 1774701844). The mispricing was on the **GoonFi leg ($2.6610/WSOL)**; GoonFi lost ≈$123.2k, BisonFi net ≈ **+$59** (it received fair value). | exploit tx `5A1YuYHf…MGV2` (slot 409,430,505) token deltas + DefiLlama |
| Patch level (Mar-28 build → today) | **Code-level evolution, not a single config flip**: the program was upgraded **many times** (authority-gated upgrades; ≥10 upgrades pre-incident in the scanned window, ≥15 post-handover; last upgrade slot 456,982,351 = 2026-10-13). The current build carries hard in-code controls (freshness gate, 3% oracle deviation, publisher-signed feed, restart-ack vote account that the March build did not pass). No config-only "fix" can explain the observed interface change (9→10 accounts). | upgrade-authority history (156 txs), ProgramData last-deploy slot, live log strings + LiteSVM differential |
| Single-EOA upgrade key | **P-class risk**: `6dDjBZdpafRKe7WuVHYTF1HphW1BWiKqioMD5eBGYipS` is the sole upgrade authority (on-curve EOA, **4.096 SOL** — the corpus' "4,095.96 SOL" was a lamports/SOL units error, corrected here) and operates a fleet of programs (BisonFi + 2 sibling programs + many buffers). | on-chain ProgramData header + authority tx history |
| Old pool `51FQwjr` ($4.94M, frozen 2026-04-23) | **Not swappable** — current program refuses (zero-path, status 18). No extraction. | PoC T10a/T10b |
| Residual risk | MM-priced venues are only as safe as (a) the publisher feed key `FTp1BybZ…` (single key, 17.96 SOL) and (b) the upgrade key. Both are **P**-class, not E-U. | T5c/T5d: feed write requires the updater key's signature (`MissingRequiredSignature` otherwise) |

---

## 1. What the program is

The current ELF (sha256 `9b36724d…`) is a **hand-optimised Pinocchio 0.9.3 "dark-amm" prop-AMM** (source paths embedded in rodata: `dark-amm/program/src/{pricing_v3,state,cpi_guard,instructions/*}.rs`, built by user `svc_labubu` with nightly-2026-08-24). Instruction surface (discriminators observed live): `2` swap (user), `7` reserve/internal swap variant, `16` per-pool config/book update, `19` inventory ops, `20`/`27` **oracle/tick batch updates** (MM), plus init/admin ops.

Pricing is **"RFQ v3"**: the MM posts tick/inventory + oracle snapshots into the 2,048-byte POOLSTAT account via disc 20/27 (batched, every few slots); the swap computes the output from that state and enforces (log strings in the binary, all paths verified): market-tick required, price-impact ≤3%, **output deviation ≤3% from oracle**, NBBO/quantization, **order-marking staleness**, oracle staleness, pool-version/size checks, restart-ack ("pool has not acknowledged the cluster restart"), pool-paused, min-amount-out.

POOLSTAT layout (decoded, offsets): `0 "POOLSTAT"`, `8 u32 version=3`, `16 authority pubkey (MM, must sign state updates)`, `48 cached WSOL balance`, `56 cached quote balance`, `72/80 last/prev update slot`, `88 ns timestamp`, `120 WSOL vault`, `152 quote vault`, `184 WSOL mint`, `216 quote mint`, `256 name`, `1400 acknowledged LastRestartSlot` (mainnet value 246,464,040 = the live `SysvarLastRestartS1ot` value).

## 2. Live-state assessment (all reads at explicit slots)

| Object | Address | State (slot) |
|---|---|---|
| Pool state (target) | `8FnX3xo2…` | POOLSTAT v3; authority `Gs7aQqWz…`; last update 457,426,443 (ts 1,792,108,133) |
| WSOL vault | `ATRsNGv2…` | 21,259,573,168,278 lamports = **21,259.57 WSOL** (457,433,682) |
| USDC vault | `2Y7HATmn…` | **2,395,920.921534 USDC** (457,433,682) |
| Old pool state | `51FQwjr…` | POOLSTAT v3, frozen 2026-04-23 (slot 415,219,064); vaults still hold **25,583.39 WSOL + 2,241,714.06 USDC ≈ $4.94M** |
| Publisher feed | `7yecFG22…` (owner `dijkbk…`) | 32-byte feed; SOL/USD 105.415868, feed slot 457,433,686 |
| Feed program | `dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu` (ProgramData `7btzN5NE…`, 512-byte hand-written SBF, updater key hard-coded) | write requires updater `FTp1BybZ…` **signature** (verified in LiteSVM) |
| Upgrade authority | `6dDjBZdp…` | sole authority since slot 423,831,228 (took over from `UfSM2ZFR…`); **4.096 SOL**; last BisonFi upgrade 456,982,351 (2026-10-13) |
| 29 POOLSTAT accounts | fleet | ≈$18.6M cached value: SOL-USDC/UDST/USD1 pools, cbBTC/whETH/HYPE pools, 14 tokenized-equity (de*) pools, 6 dormant pools |

## 3. The March 28, 2026 incident — what actually happened (value attribution)

Tx `5A1YuYHff5RYiZd57M4Ko7PaqoX1GMsYGny9AVaVn826bS1w4nxwbRDyHs4bqJgV6yZfRVQAjmGFDRp9kL6aMGV2` (slot 409,430,505, Jito bundle, 1 SOL tip), router `MsefSitidh…` CPIs into GoonFi then BisonFi:

| Leg | In | Out | Implied price | Market (blockTime 1774701844) | Value P&L |
|---|---|---|---|---|---|
| GoonFi | 4,096.000000 USDC | 1,539.265798532 WSOL | **$2.6610/WSOL** | $82.7311 | **−$123,250 (victim)** |
| BisonFi | 1,539.265798532 WSOL | 127,286.030966 USDC | **$82.6926/WSOL** | $82.7311 | **+$59 (fair, slightly favourable)** |

Attacker net: +123,190.03 USDC (~$123.1k). **Conclusion: the Z3-C4 premise "BisonFi drained via a mispricing" is a vault-movement artifact, not a value loss.** BisonFi was the exit venue at fair value; the exploitable mispricing sat on GoonFi's side (Z3-H2's target). This matters for the E-U: the March replay template does **not** carry a BisonFi-side profit.

## 4. What an attacker can / cannot do today (fresh-attacker standard)

**Cannot (all tested in LiteSVM against cloned live state, CI):**
- **Replay the March trade for profit** — BisonFi's leg is oracle-bounded; selling WSOL yields $105.32–105.41/SOL (oracle $105.4159); buying WSOL costs $105.33–106.26/SOL depending on size. No side pays better than oracle.
- **Write the pool state / price**: disc 20/27/16 from an unauthorized signer → `Custom(2)`/`Custom(0)`, **state unchanged** (T4a/T4c/T4d). The state stores the MM authority pubkey; only it can update.
- **Spoof the publisher feed**: `dijkbk` write requires the updater key `FTp1BybZ…` as a **signer** (`MissingRequiredSignature` without it) — verified T5c vs T5d; the data write is byte-exact the instruction data.
- **Trade a stale quote**: the swap refuses (zero-path) when the state is older than **~2 slots** relative to the clock (T7: +0/+1/+2 succeed, +3 fails). This kills replay-of-old-quote attacks and makes the old $4.94M pool unreachable (T10).
- **Drain by size**: single-swap size is capped (500 SOL ≈ $52.7k failed with `Custom(1)` after prior trades; the cap behaviour is state-consistency dependent — see caveats). Output-side liquidity bounds the other direction (500k USDC → 4,705 SOL, price $106.26, within the 3% band).

**Could (net of costs):** nothing profitable. Best-case measured execution = oracle − 0.09%; no fee-free round-trip exists (0.001%-scale fees charged on the WSOL leg in live txs).

## 5. PoC / verification (LiteSVM)

`poc/` — Rust + litesvm 0.18 (Agave 4.3), clones mainnet accounts from committed fixtures (public on-chain data only) and executes transactions in-process with sigverify off. Key results (full log in `ci-out/poc-output.txt`; CI run URLs below):

| Test | Result |
|---|---|
| T0–T2 (swap 1 SOL / exact-replay data / 1000 USDC) | SUCCESS; **1 SOL → 105.318952 USDC** (price $105.3190) |
| T3 (March 9-account layout) | zero-path (no vote account) |
| T4 (12-account layout with mints) | SUCCESS |
| T7 (+0/+1/+2 slots) | SUCCESS; **+3/+4/+8 → zero-path** (freshness gate ≈ ≤2 slots) |
| Ladder SOL→USDC | 1/10/100 SOL → $105.319/105.317/105.316 per SOL |
| Ladder USDC→WSOL | 1k/10k/100k/500k USDC → $105.33/105.33/105.41/106.26 per SOL |
| T8 (byte-exact replay of a real successful swap, real user + ATAs) | SUCCESS at the right clock; zero-path when stale |
| T4a/T4c/T4d (MM updates from attacker) | FAIL `Custom(2)` / `Custom(2)` / `Custom(0)`; state unchanged |
| T5a/T5b (feed write, attacker) | no-op (4 CU), unchanged |
| T5c (feed write, updater key as non-signer) | FAIL `MissingRequiredSignature` |
| T5d (feed write, updater key as signer) | SUCCESS (24 CU — exactly mainnet's CU), **32 bytes written** |
| T10a/T10b (old $4.94M pool, now / April clock) | zero-path, status 18 — no trade |

The harness needed two mainnet-mirroring fixes that are themselves findings for anyone replaying this program: LiteSVM's `LastRestartSlot` sysvar must be set to mainnet's `246,464,040` (the pool stores the acknowledged value and the swap gates on it), and the Clock must be within ~2 slots of the state's last update.

## 6. Patch-level verdict (code vs config)

**Verdict: code-level evolution — a config-only patch cannot explain the observed state.** Timeline evidence:
- BisonFi ProgramData upgrades (authority-signed) in the scanned pre-incident window: slots 378,372,044 · 378,603,174 · 382,496,099 · 390,007,231 · 394,851,336 · 396,781,613 · 397,651,303 · 397,875,243 · 399,410,452 · 399,419,934 … continuing through the incident and after (full list in `analysis/oldauth-loader-ops.jsonl`; post-handover upgrades from `analysis/authority-txs.json`).
- The current authority `6dDjBZdp…` took over the ProgramData at slot 423,831,228 and has since pushed ≥15 BisonFi upgrades (last 456,982,351, 2026-10-13).
- Interface-level change visible in the incident tx vs live txs: March swap = **9 accounts** (no vote account); current = **10 accounts** (restart-ack vote account) with 12-account variant for mints — an instruction-surface change only a code upgrade produces.
- In-code controls (freshness ≤2 slots, 3% oracle-deviation, restart-ack) are enforced by the current ELF (verified by differential execution, not just strings).

What this does **not** claim: we did not reconstruct the exact March-era ELF (buffer chunks for the pre-incident builds are recoverable from the authority's WriteBuffer txs — see `analysis/oldauth-loader-ops.jsonl` for buffer accounts — but the byte-diff was out of scope given the harness evidence above).

## 7. Verdict and residual risk

- **E-U: $0** (high confidence) for the live $4.64M pool and the fleet — the swap path is oracle-bounded, freshness-gated, and all state-mutation paths are authority-gated; the March template yields no BisonFi-side profit.
- **P: the entire fleet** — single EOA upgrade key `6dDjBZdp…` (4.096 SOL) can replace any program in the fleet (including pushing code that pays out vaults); the publisher feed key `FTp1BybZ…` (17.96 SOL) can post arbitrary prices for GoonFi and any feed consumer. Both are single points of failure over ≈$18.6M. **Monitor both keys and the ProgramData last-deploy slot.**
- **S: $4.94M** in the abandoned `51FQwjr` pool (frozen since 2026-04-23) — not extractable by an unprivileged attacker today because the live program refuses stale states; if the MM ever re-acknowledges that state (or an old build is restored), it becomes tradable at an April-2026 price basis (latent, monitor).
- **Latent:** if the MM bot ever posts a quote ≥3% off its own oracle snapshot in an attacker's favour, up to 3% × trade size is extractable per refresh window — that is an MM-operational risk, not an attacker capability.

## 8. Methodology & sources

Read-only RPC (`api.mainnet-beta`, `solana-rpc.publicnode.com`), getProgramAccounts/getSignaturesForAddress/getTransaction; DefiLlama historical prices; hand-rolled sBPF ELF parser + lddw reference search + syscall-hash mapping (all scripts in `analysis/`); LiteSVM 0.18 (Agave 4.3) in-process execution with cloned accounts. All fixtures are public on-chain data; no secrets anywhere in this folder.

**Caveats:** (1) LiteSVM CU accounting differs slightly from mainnet (4 vs 24 CU on the no-code path); conclusions use success/failure + state diffs, not CU. (2) The size-cap `Custom(1)` observed after cumulative in-process trades may be a vault/state consistency guard — it appeared once and did not reproduce after opposite-direction flow; it never produced an extraction. (3) Cached fleet balances are from the snapshot slot 457,421,830 (±trading); headline pool numbers are fresh at slot 457,433,682. (4) The March-era ELF was not byte-diffed (buffer reconstruction left as a documented follow-up).

## 9. Files

- `analysis/exploit-analysis.txt` — full decode of the 2026-03-28 tx (accounts, transfers, logs)
- `analysis/pool-states-decoded.json` + `pool-states-2048.json` — 29 POOLSTAT map (authority, vaults, cached balances, last-update slots)
- `analysis/history-old-authority.json`, `history-upgrade-authority.json`, `authority-txs.json`, `oldauth-loader-ops.jsonl` — upgrade/authority timeline
- `analysis/elf-strings.txt`, `log_sites.py`, `scan_calls.py`, `find_refs.py`, `elf.py` — ELF forensics
- `analysis/oracle-program-raw.elf` — the 512-byte publisher program; `oracle-strings.txt`
- `poc/src/main.rs` — LiteSVM harness (T0–T10); `poc/fixtures/` — cloned accounts
- `ci/run.sh` — CI job; `ci-out/poc-output.txt` — full run log
