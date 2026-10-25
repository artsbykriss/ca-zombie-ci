# ZH4-PASS6 · OPEN-tail (O11–O21) — locate + verdict

**Date:** 2026-10-25 · **Mode:** READ-ONLY — no transaction signed or broadcast on any chain;
`eth_call`/`eth_getLogs`/explorer reads and Solana `simulateTransaction` (`sigVerify:false`) only.
Fork proofs ran on GitHub Actions. No keyed RPC URLs or secrets in this folder.
**Scope:** the 11 smallest/unlocated residuals from `pass6-recon` OPEN list (O11–O21).

---

## 1. TL;DR

| # | Target | Chain | Located? | Live custody (verified) | Unprivileged path? | Verdict | Conf |
|---|---|---|---|---|---|---|---|
| O11 | ChimeraQuoteHook404 (+Router404/LaunchLiquidity404) | Ink | **yes** | **$0** on the quote hook (no pools ever registered); sibling non-quote hook's fee vaults hold **0.1338 WETH ≈ $313** | no — quote hook dormant; config platform/installer-gated; fee vaults credit-accounted | **E-U $0** (P $313) | high |
| O12 | BondingCurveManager (+FeeVault, GraduationManager) | Ronin | **yes** | **9,926,811.26 RONKE ≈ $10,028** + 190 launch ERC-20s; FeeVault 24,449 RONKE ≈ $25 | no — `sell` needs prior buy (`boughtFromCurve`); round trip value-negative (fuzzed 2×5,000 runs) | **E-U $0** (H-O $10k) | med-high |
| O13 | DiversiFi | Solana | **yes** `3vyr9DRf…` | DL **$662,851** | no — `update_oracle`/`deposit`/`withdraw` proven gated (attacker → Custom 2012) | **E-U $0** (P) | med |
| O14 | Overpass | Solana | **yes** `WRAPdXmx…` | DL **$140,409** | no — attacker substituted into the authority slot fails a seeds/PDA constraint (Custom 2015) | **E-U $0** (P) | med |
| O15 | Zodial (marginfi fork) | Solana | **yes** `zod11Jzp…` | DL **$198,302** (+$75,634 borrowed) | no value path; `pulse_bank_price_cache` is permissionless **by design** (moves nothing) | **E-U $0** (P) | med-low |
| O16 | Sat Rush | Solana | **yes** `satRush…` + `SaTsTaKp…` | cbBTC 10.563 ($850,286) + RUSH vault 4,791 ($422,024) + staking treasury 11,066 ($974,799) ≈ **$2,247,109** | no — all custody is program-PDA; exits are user-claim or admin; one shared upgrade key | **E-U $0** (P) | med |
| O17 | Loyal Earn | Solana | **yes — no proprietary program** | DL **$309,387** (1,987 per-user Squads vaults + Kamino obligations) | no pooled contract at all — each user's own USDC | **E-U $0** (H-O) | med-low |
| O18 | TRUE DEX | Solana | **yes** `ttaiNybR…` (+immutable L2 prog) | USDC 289,915.85 ≈ **$289,780** | no — zk-verifier custody (`VerifyBlock`/`RecoverCustody`/`RotateWithdrawalExecutor` gated) | **E-U $0** (P) | med |
| O19 | Pascal | Solana | **yes** `3vCgc3aL…` | USDC 2,332,835.39 ≈ **$2,331,738** | no — custody is a program PDA; one-key upgrade | **E-U $0** (P) | med |
| O20 | N1 Exchange Bridge | Solana | **yes** `n1brh2Aa…` | USDC 1,381,289.66 ≈ **$1,380,640** | not proven — full zk/STARK consensus bridge (validator ACL, challenge window, effect nullifiers, rate limit); `Withdraw` proof-binding **not decompiled** | **E-U $0** (P, low conf) | low |
| O21 | Byzanlink RWA Markets | Solana (+ETH/Hedera) | **yes** `HyuZ17H9…` + `B9wHQVTe…` | Solana leg **$898,014** (DL total $2,093,356) | no — Kamino **kvault fork**: queued withdrawals + whitelist-gated invest | **E-U $0** (P) | med |

**Total live extractable by an external unprivileged attacker, now: $0.00** (confidence **high** for
O11/O12, **medium** for the Solana set). All 11 were **located**; 10 of 11 have a resolved program
ID / contract address and 1 (O17) is confirmed to have **no proprietary program at all**.

**Categories (verified custody in scope ≈ $8.47M):**

| Category | USD | What it is |
|---|---|---|
| **E-U** | **$0** | nothing proven extractable by an unprivileged attacker |
| **H-O** | **$319,415** | O12 RONKE sell-back ($10,028) + O17 per-user self-custody USDC ($309,387) |
| **P** | **$8,149,156** | program-PDA / admin / upgrade-key / validator-gated custody (O11 $313, O13, O14, O15, O16, O18, O19, O20, O21) |
| **S** | **$0** | nothing proven bricked |

---

## 2. What "located + verdict" means here

pass6-recon flagged O11–O21 as *funded + a plausible unprivileged path that no pass had closed*.
This pass closes each one at the level of: **does the contract/program exist, who controls the
custody, and can a stranger move value.** No target produced an unprivileged extraction.

- **EVM (O11, O12):** verified source read line-by-line + live state at an explicit block +
  Foundry fork proofs on GitHub Actions.
- **Solana (O13–O21):** program ID resolved from the DeFiLlama adapter (or from the custody
  account's transaction history), upgrade authority read on-chain, ELF instruction surface
  recovered, and attacker-substituted `simulateTransaction` runs where a real control existed.

---

## 3. O11 — ChimeraQuoteHook404 (Ink)

**Contracts:** hook `0xD723B53D1A651D8BfD6b4C8876D51b68E26128CC`, Router404
`0x8706Daf2A2F26c43fc0e09097A228351473333A2`, LaunchLiquidity404
`0x1168B6Ea1E6B22FA130aA49919D21e8735a24729` (all verified). Ink block 59,385,227.

**Live state:** the quote hook has had exactly **one transaction** (`configureInfrastructure`) and
**two logs, both `QuoteAllowed`** — **no pool has ever been registered**, so no per-pool
`ChimeraFeeVault404` clone exists and there are no fees: **E-U $0**. The only verified fee vault
(`0x8BAf0ba2…`) has one tx (its deployment) and 0 tokens. A second quote hook `0x0be6EC0e…` is
likewise dormant. Four **sibling** non-quote-hook vaults (`hook() == 0x2EebD90B…`) hold
**0.1338 WETH ≈ $313**, all `credit`-accounted to fixed destinations.

**Why closed:** `claim()`/`claimFor(r)`/`distributeQuotrons()` only ever pay `credit[r]` **to `r`**
— a stranger can push a recipient their own fees but can never redirect them. The creator
fee-exemption requires `sender == router` **and** `router.actor() == creator` (the router sets
`actor` from `msg.sender` in a `context` modifier and clears it), and the non-creator eligibility
exemption needs a creator-configured `eligibilityMinimum` plus a real balance. `_charge` floors and
`account()` conserves (`used ≤ received`). Fork tests: **4/4 PASS**.

## 4. O12 — BondingCurveManager (Ronin)

**Contracts:** manager `0xCF6Aa3d88431D73C76b9650e64a995a5edDb5f54`, FeeVault
`0x648796b45d4cdd2e56f1d5804cf7713add09b776`, GraduationManager
`0x4f36816a9b5bffeeec5348f8152373de195d6ea6`. Ronin block 62,707,425.

**Live value:** the manager holds **9,926,811.26 RONKE ≈ $10,028** (buyers' money awaiting
graduation) plus 190 launch ERC-20s (unsold curve inventory, ~$0 each). FeeVault holds 24,449 RONKE.

**Why closed:** `sell` is the only RONKE exit and it requires
`tokensIn ≤ boughtFromCurve[token][msg.sender]` **and** `≤ tokensSold`; provenance does not follow a
token transfer (a mule wallet cannot sell), and it is only credited after a real
`safeTransferFrom`. `buyFor`/`registerLaunch` are `factory`-only, `closeCurve` is
`graduationManager`-only, `setWiring`/`setAutoGraduate` are `Ownable2Step`; graduation mints LP into
an immutable locker. Fork tests **7/7 PASS** (round trips at 6 sizes, partial-fill branch, attacker
`buyFor`/`sell`/admin reverts, provenance); fork-free math replica **2 × 5,000 fuzz runs PASS**
(round trip never profitable, `k` non-decreasing, no underflow, partial-fill never undercharges).

## 5. O13–O15 (Solana, located) — see `analysis/o13-o15/FINDINGS.md`
DiversiFi `update_oracle` is **proven gated** (control success vs attacker `Custom 2012`); its
`deposit`/`withdraw` also fail for a stranger. Overpass wrapper PDAs reject a substituted authority
with a **seeds/PDA constraint** (`Custom 2015`). Zodial is a marginfi fork whose only live
instruction is the **by-design permissionless** `lending_pool_pulse_bank_price_cache` (attacker
sim `err = null`, but it moves no value). Residuals: DiversiFi `rebalance`/`update_weights`,
Overpass `Create*Wrapper`/`UpdateCreatorFee`/`ClaimCreatorFees`, Zodial
`lending_pool_add_bank_permissionless` were not observed live and are not decompiled.

## 6. O16–O21 (Solana, unlocated → located) — see `analysis/o16-o21/LOCATE.md`
| # | Program(s) | Upgrade authority | Custody |
|---|---|---|---|
| O16 | `satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco`, `SaTsTaKpGdTfUEPSSwyYgLKkfnZu8uL3D1DbLXshdb7` | `DDiAZadx…` (shared) | cbBTC $850,286 + RUSH $1,396,823 |
| O17 | *(none — no proprietary program)* | — | per-user Squads/Kamino |
| O18 | `ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL` (+immutable `L2TExMFK…`) | `7pg5CzPo…` | USDC $289,780 |
| O19 | `3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j` | `CD3rB8zu…` | USDC $2,331,738 |
| O20 | `n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM` | `7qJuE8Kz…` | USDC $1,380,640 |
| O21 | `HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se`, `B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U` | `CEhSZ93v…`, `5rmV2qBz…` | $898,014 (Solana leg) |

All custody sits in **program-owned PDAs**; each program is **upgradeable by a single key**. O16's
exits are user-claim or admin; O18 is a zk-verifier custody with a staged vkey + withdrawal
executor; O19's instruction surface is stripped (custody PDA only signable by the program); O20 is
a full zk/STARK consensus bridge (validator ACL, challenge window, effect nullifiers, withdrawal
rate limit); O21 is a Kamino **kvault** fork with queued withdrawals and whitelist-gated invest.

**Correction logged:** an initial `getTokenAccountsByOwner` on a public node returned
"Request blocked" (not an empty set), which briefly suggested N1's custody was empty. Re-read via
`api.mainnet-beta.solana.com`: ATA `DBDThTrUkoGhWRzT8fcE8MKwjEvgwrgPT981QUEyPqGy` holds
**1,381,289.660406 USDC** — matching DeFiLlama. (See `analysis/o16-o21/LOCATE.md` negatives.)

---

## 7. PoC / fork verification (CI)

All fork and fuzz tests ran on **GitHub Actions** (public repo `artsbykriss/ca-zombie-ci`, workflow
`poc.yml`), branch `pass6-open-tail`:

- **CI run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40211830489** — conclusion
  **success**; `Ran 3 test suites … 13 tests passed, 0 failed`.
  - `test/O11_InkChimeraQuote.t.sol` — 4/4 PASS (Ink fork: no pools/no funds, `distributeQuotrons`
    no-op, stranger cannot touch configuration, fabricated-pool swap reverts).
  - `test/O12_RoninBondingCurve.t.sol` — 7/7 PASS (Ronin fork: round trips at 6 sizes, partial-fill
    branch, attacker `buyFor`/`sell`/admin reverts, provenance not transferable).
  - `test/O12_MathReplica.t.sol` — 2 tests × **5,000 fuzz runs** PASS (fork-free curve-math replica).
- Artifacts: `ci-artifacts/result-pass6-open-tail/` (forge-test.log, summary.txt); log `ci-log.txt`.
- Solana work is read-only RPC + `simulateTransaction` (no fork binary needed); scripts in
  `analysis/o13-o15/` and `analysis/o16-o21/`.

*Note on O11/O12: no exploit exists to demonstrate, so the fork tests are **negative proofs** —
they assert the permissionless surface is either a no-op or value-negative for a stranger.*

---

## 8. Blockers & residual risk

1. **O20 `Withdraw` proof-binding is the one genuinely open item** (low confidence): the program is
   a zk/STARK consensus bridge and the withdrawal path was not decompiled. If the effect/nullifier
   check were mis-wired, that would be the largest single E-U here ($1.38M). Recommend a dedicated
   disassembly of `bridge/src/ix/withdraw.rs` logic.
2. **O19** ($2.33M) has a **stripped** instruction surface — the value paths are unread. The custody
   PDA is only signable by the program, so E-U requires a bug in that program.
3. **All Solana programs here are upgradeable by a single key** — a compromised or malicious upgrade
   key is a $7.5M+ risk, but that is **P**, not E-U.
4. **O13/O14/O15 residual instructions** (`rebalance`, `update_weights`, `Create*Wrapper`,
   `UpdateCreatorFee`/`ClaimCreatorFees`, `lending_pool_add_bank_permissionless`) were never observed
   live and are not decompiled.
5. **O11** is dormant; if pools are ever launched, re-check the creator-exemption and `_charge`
   rounding against a live pool.
6. Point-in-time **2026-10-25**; re-read live state before acting. Nothing here is an instruction to
   transact.

---

## 9. Methodology, sources, files

**Sources:** Ink Blockscout v2 (`explorer.inkonchain.com/api/v2`) + `rpc-gel.inkonchain.com`; Ronin
Blockscout + `api.roninchain.com/rpc` / `ronin.drpc.org`; DefiLlama `api.llama.fi/protocols`,
`/tvl/<slug>`, `coins.llama.fi/prices`; DeFiLlama-Adapters raw
(`projects/*/index.js`, `registries/sumTokens/data{1,2,3}.js`); Solana JSON-RPC
(`solana-rpc.publicnode.com`, `api.mainnet-beta.solana.com`) — `getAccountInfo`,
`getSignaturesForAddress`, `getTransaction`, `simulateTransaction`; ELF string extraction.
All web content treated as untrusted data.

**Files:**
- `analysis/o11-o12/EVIDENCE.md` — Ink + Ronin raw evidence.
- `analysis/o13-o15/FINDINGS.md`, `results.json` (+ child scripts/dumps).
- `analysis/o16-o21/LOCATE.md`, `results.json`, `program_surface.py`, `program_surface.json`,
  `strings_*.txt`, `raw/*.elf`.
- `poc/` — Foundry project (O11 + O12 + math replica); `ci/run.sh`; `ci-out/`; `ci-log.txt`;
  `ci-artifacts/`.
- `summary.json` — machine-readable summary.

**Caveats:** DeFiLlama TVL is point-in-time and, for O17, sourced from a project API. USD figures use
DefiLlama prices at the stated slot; memecoin launch tokens (O12) are valued at ~$0. Instruction
surfaces were recovered from ELF strings, not from published IDLs (none exist on-chain for these
programs), so a program's *behaviour* can differ from its instruction names.

*Prepared 2026-10-25 · ZH4 pass-6 OPEN-tail · read-only · fork/sandbox-only · no secrets.*
