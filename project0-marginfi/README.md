# Project 0 (marginfi-v2) — Solana — deployed-build verification + unprivileged-path audit

**Date:** 2026-10-25 · **Chain:** Solana mainnet-beta · **Lane:** ZH4 pass-7, Solana rows 4/5/7 (Target 1)
**Status:** READ-ONLY. No transaction signed or sent. Only public JSON-RPC reads and
`simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`) on attacker-built messages.
No secrets, no keyed RPC URLs.

> **Prior-partial flag:** this target is the **marginfi-v2** open-source codebase
> (`0dotxyz/marginfi-v2` = `mrgnlabs/marginfi-v2`, docs `docs.marginfi.com`, app `app.0.xyz`). The
> repo README literally opens *"# Project 0 (P0): Built on the Marginfi v2 Program"*. The
> marginfi lineage was **excluded** from the campaign; it is kept here only to answer the specific
> question *does the deployed program byte-differ from the audited source?*

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **Project 0 / marginfi-v2** program `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` (~$59.0M supplied / ~$35.0M idle) | **$0** | Deployed ELF is **byte-identical** (solana-verify / OtterSec) to open-source commit `c5d440f6` = the **0.1.12 consolidated update**; every value-moving/config path requires an off-curve PDA signer; the only permissionless path (`pulse_bank_price_cache`) is **strictly oracle-bound** (proven by simulation) | P-class only: upgrade authority `J3oBk…` (off-curve) and group admins are governance multisig vaults |

## 2. Total live extractable now: **$0.00 (E-U)** — confidence **high**

No external unprivileged attacker can extract value from the live Project 0 deployment. The
deployed program is the well-audited open-source marginfi-v2 0.1.12 release, verified byte-for-byte,
with all authority paths held by off-curve governance PDAs.

---

## 3. Mechanism / question in exact terms

The mandate was: *is the **deployed** program a faithful build of the audited open-source
marginfi-v2, or does it byte-differ (e.g. a fork with modified lending accounting, oracle/keeper or
liquidation logic)?* This is the decisive question for a "fork of an excluded lineage": if the
on-chain bytes match the public repo, there is no novel hidden code to audit and the finding reduces
to the (already-covered) marginfi risk profile.

Answer: **it matches.** Three independent lines of evidence:

1. **OtterSec / solana-verify registry** — `GET https://verify.osec.io/status/MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA`
   returns `is_verified: true`, `on_chain_hash == executable_hash == eb7618369bec08691a7a4003e04f8fb34d95e7301e2b3b0c5439528e2b38cdab`,
   `commit = c5d440f62365de503c89cf6ec39fb6673494cc7c`, `last_verified_at 2026-10-14T12:01:08Z`.
2. **Independent on-chain hash reproduction** — `analysis/onchain_hash.py` reads the live
   `programdata` account `4Q8u2ny8YYgytJEncwZQfVWbd5axZtfgDxYKHehvPQR7`, strips the 45-byte
   `UpgradeableLoaderState::ProgramData` header, and computes `sha256(elf.rstrip(0x00))` =
   `eb7618369bec08691a7a4003e04f8fb34d95e7301e2b3b0c5439528e2b38cdab` — **an exact match to the
   registry's `on_chain_hash`**. So the hash the registry verified is the hash of the bytes that are
   live right now.
3. **Deployed commit vs HEAD is doc-only.** `git diff --stat c5d440f6..HEAD` (HEAD `aeafee70`,
   2026-10-14) = `SECURITY.md (+105)`, `guides/ADMIN/DEPLOY_GUIDE.md (+6)` — **zero code changes**.
   The deployed commit `c5d440f6` *is* "0.1.12 consolidated update" (2026-10-12T15:24:03Z), matching
   the deploy slot 456,093,551 = 2026-10-12T15:18:53Z.

The deployed ELF also contains the expected 0.1.12 instruction symbols
(`LendingPoolPulseBankPriceCache`, `LendingPoolSetOraclePrice`, `KeeperCloseOrder`,
`StartExecuteOrder`, `PlaceOrder`, `LendingPoolAddBankPermissionless`, …), and executing it on the
live cluster logs `Instruction: LendingPoolPulseBankPriceCache` — i.e. the running binary is 0.1.12.

---

## 4. Live-state assessment (all read-only)

| Item | Value | Source |
|---|---|---|
| Program | `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` | `getAccountInfo` |
| ProgramData | `4Q8u2ny8YYgytJEncwZQfVWbd5axZtfgDxYKHehvPQR7`, space 10,485,760, ELF 3,860,792 B | `analysis/elf.py` |
| On-chain program hash | `eb7618…cdab` (= registry `executable_hash`) | `analysis/onchain_hash.json` |
| Upgrade authority | `J3oBkTkDXU3TcAggJEa3YeBZE5om5yNAdTtLVNXFD47` — **off-curve PDA**, not immutable | `analysis/elf.py` |
| Last deploy slot | 456,093,551 = **2026-10-12T15:18:53Z** | `getBlockTime` |
| Verified build commit | `c5d440f6` (0.1.12) | verify.osec.io |
| Groups / banks (program-wide) | 163 groups, 401 banks | `analysis/live_state.json` |
| **Main Project 0 group** | `4qp6Fx6tnZkY5Wropq9wUYgtFxXKwE6viZxFHg3rdAG8`, **165 banks** | `analysis/live_state.json` |
| Group `admin` + `global_fee_wallet` | `CYXEgwbPHu2f9cY3mcUkinzDoDcsSan7myh1uBvYRbEw` — **off-curve**, system-owned, 21.08 SOL (Squads-style vault) | `analysis/group_banks.json` |
| Idle liquidity (Σ liquidity-vault balances, 105/165 banks priced) | **$35,023,382.57** | `analysis/group_banks.json` |
| Insurance vaults | ~$102,242.91 | `analysis/group_banks.json` |
| DefiLlama `project-0` | TVL $59.0M, borrowed $23.5M (2026-10-25) | DefiLlama |

Largest single bank liquidity vaults: JitoSOL $7.37M, bSOL $5.07M, mSOL $4.31M, LSTxxx $2.97M,
JupSOL $2.35M, cbBTC $1.42M, JUP $1.29M.

---

## 5. What an attacker can / cannot do

**Permissionless entry that exists (and is safe): `lending_pool_pulse_bank_price_cache`.** The
instruction declares **no signer** and takes the bank's oracle accounts from `remaining_accounts`
(`pulse_bank_price_cache.rs` lines 42–50). This is the archetypal "caller-supplied oracle" primitive
— *if* the program trusted those accounts, an attacker could write a forged price into the bank's
cache and then borrow/liquidate against it. **It does not trust them:** every arm of
`OraclePriceFeedAdapter` (`state/price.rs`) binds `remaining_accounts[i]` to
`bank_config.oracle_keys[i]` via `check_primary_oracle_key` / `require_keys_eq!`. Proven by
simulation (§6): a substituted oracle is rejected with `WrongOracleAccountKeys`; the real oracle
succeeds.

**Everything that moves value requires a signer that the attacker is not:**
- `set_oracle_price` / `configure_bank*` / `configure_gov` → `has_one = governance_admin` (`Signer`).
- `withdraw` / `borrow` / `repay` → `is_signer_authorized(account, governance_admin, authority)` and
  `bank has_one = liquidity_vault` (vault is bound to the bank).
- `liquidate` → permissionless by design, but only against a *genuinely unhealthy* liquidatee, with
  oracles bound to the banks; it cannot be aimed at a healthy account.
- `handle_bankruptcy` → admin/risk-admin, **or** permissionless **only** on banks flagged
  `PERMISSIONLESS_BAD_DEBT_SETTLEMENT_FLAG` **and** only when the account is truly insolvent
  (CB-gated live-price check). It socialises a real loss; it is not a value source.
- order / keeper / rebalance surface (`PlaceOrder`, `KeeperCloseOrder`, `StartExecuteOrder`,
  `*Rebalance*`) → `has_one = authority` / `has_one = marginfi_account` + `has_one = executor`
  signer constraints throughout (`order.rs`, `rebalance.rs`).
- `panic_unpause_permissionless` / `add_bank_permissionless` → no funds moved (unpause after expiry;
  add a staked bank with sane defaults, stake-pool owner validated).

Costs: the price-cache refresh costs ~59k CU (~$0), and it only *refreshes a price from the
already-configured oracle* — no attacker benefit.

---

## 6. PoC / fork-verification (read-only simulations)

Attacker-built **legacy** messages, `simulateTransaction` with `sigVerify:false`,
`replaceRecentBlockhash:true`. Instruction accounts carry **no signer**; the fee-payer slot is a
placeholder only (never signed, never broadcast). Files: `analysis/sim_pulse.py`,
`analysis/sim_results.json`.

Bank used: Jito-SOL bank `Bohoc1ikHLD7xKJuzTyiTyCwzaL5N7ggJQu75A8mKYM8` (PythLST setup,
`oracle_keys[0]=7AviUf9nL62mcxNbQGKm4nKDQnPjswo6c5MX4D57HmyE` Pyth SOL/USD feed,
`oracle_keys[1]=Jito4APyf642JPZPx3hGc6WWJ8zPKtRbRs4P815Awbb` Jito stake pool).

| # | Instruction | Accounts | Result | Verdict |
|---|---|---|---|---|
| T1 | `lending_pool_pulse_bank_price_cache` | group, bank, **substituted** oracle (So111…/EPjFW… USDC) | **`Custom 6052` `WrongOracleAccountKeys`** — `Left: So1111…` / `Right: 7AviUf9n…` (36,391 CU) | **oracle substitution REJECTED** |
| T2 | same | group, bank, **real** oracle_keys[0..1] | **success** (err=null), 59,077 CU | path reachable by a non-authority |
| T2b | same, **neutral non-admin fee payer** (`H8sMJSC…`) | real oracle_keys[0..1] | **success** (err=null), 59,095 CU | not admin-gated |

**Conclusion:** the permissionless price-refresh entry is real but strictly bound to the bank's
configured oracle accounts — the caller-supplied-account-substitution primitive is **closed (proven)**.

**CI — independent reproducible build (run `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40228377966`).**
`ci/run.sh` installed `solana-verify 0.5.2`, fetched the live on-chain hash from a public RPC,
cloned `mrgnlabs/marginfi-v2` at `c5d440f6`, ran `solana-verify build --library-name marginfi --
--features mainnet-beta,custom-heap` (Docker, pinned toolchain), and compared:

```
10-onchain-hash.txt   : eb7618369bec08691a7a4003e04f8fb34d95e7301e2b3b0c5439528e2b38cdab   (from live RPC)
40-hash-compare.txt   : local_executable_hash=eb7618…cdab
                        expected_onchain_hash  =eb7618…cdab
                        RESULT=MATCH  (deployed ELF == reproducible build of c5d440f6)
                        sha256(marginfi.so) = 6f8184ac9c0d8bf5b48caa13111e307a8fd8d09fa51f08f7cda9c5ce766ba702
```

The raw `sha256` of the CI-built `.so` (`6f8184ac…`) is **identical** to the raw `sha256` of the
truncated live ELF computed locally — so the deployed bytes are the built bytes, not merely a
matching normalised hash. **Deployed program == reproducible build of the open-source commit.**

---

## 7. Verdict, residual & latent risk, blockers

- **Verdict:** **E-U = $0.00 (high confidence).** The deployed program is the verified open-source
  0.1.12 release of marginfi-v2; no byte divergence from the audited repo (only doc files changed up
  to HEAD); all authority is off-curve governance; the single permissionless value-adjacent path is
  oracle-bound.
- **P (privileged):** upgrade authority `J3oBk…` (off-curve PDA) can replace the program; group
  admins/governance admins are off-curve vaults. These are governance risks, not attacker paths.
- **Latent risk (low):** the 0.1.12 features (variable-borrow premium matrix, rebalance, fixed-price /
  PT oracles, circuit breaker, same-asset e-mode) are recent. They are covered by 2026 audits
  (Ackee full June-2026; Hashlock July-2026; Sec3 Aug/Sep-2026; Adevar Sep-2026 variable-borrow/
  rebalance/oracles; Sec3 Sep-2026 scope oracles; Sec3 fixed-price). A logic bug in one of these
  would be an E-U vector — none was found here.
- **Blockers:** none needed; this is a negative result. OtterSec verification is a third-party
  assertion (corroborated here by direct hash reproduction, a reproducible CI build, and runtime
  behaviour).

---

## 8. Methodology & sources

- Read-only RPC via `analysis/sol.py` (keyless public endpoints). No signing, no broadcast.
- Program/upgrade: `analysis/elf.py`; groups/banks: `analysis/live_state.py`;
  group roles + vault USD: `analysis/group_banks.py`; hash: `analysis/onchain_hash.py`;
  simulations: `analysis/sim_pulse.py`.
- Sources: `github.com/0dotxyz/marginfi-v2` (clone @ `c5d440f6` and HEAD `aeafee70`),
  `verify.osec.io/status/MFv2…`, `audits/` (15 PDFs, 2023–2026), DefiLlama `project-0`.

## 9. Caveats & limitations

- USD figures are point-in-time 2026-10-25 (DefiLlama prices); re-read before acting.
- The 105/165 priced banks cover the large vaults; 60 unpriced/zero banks are excluded from the USD
  sum (their absence does not change the verdict).
- OtterSec verification is a third-party assertion, corroborated here by direct on-chain hash
  reproduction and by the CI reproducible build.
- Nothing here is an instruction to transact.

## Files index
```
project0-marginfi/
├── README.md
├── summary.json
├── analysis/
│   ├── sol.py              # read-only RPC + base58/PDA/upgrade helpers
│   ├── elf.py              # programdata ELF + hash + upgrade authority
│   ├── onchain_hash.py     # reproduce solana-verify on-chain hash  -> onchain_hash.json
│   ├── live_state.py       # groups + banks                       -> live_state.json
│   ├── group_banks.py      # main-group roles + vault USD         -> group_banks.json
│   ├── sim_pulse.py        # attacker-message simulations         -> sim_results.json
│   ├── onchain_hash.json, osec_status.json, live_state.json, group_banks.json, sim_results.json
├── ci/run.sh               # solana-verify reproducible build + hash compare
├── ci-out/                 # CI results (hashes, logs)
└── ci-log.txt
```
