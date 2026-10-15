# child-b REPORT — SPL Stake Pool history + Phase/AeroPool/pdSOL research

Author: child-b subagent · Date: 2026-10-15 · All checks read-only; no transactions; no secrets.
(Persisted by the parent session: the child had no file-write tool.)

**PARENT RESOLUTION of the two cross-checks requested below (2026-10-15):**
1. *Deployed hash vs v2.2.0*: resolved. Deployed SPoo1 ELF (slot 457,273,511) sha256 `ec2dfefa…d7e1` == official **v2.1.0** release asset. The 2026-10-06 upgrade-authority tx was a `SetAuthority` on a **buffer** `EmR4UhwTPoEwKe9JNnVaHqSgmup3ebeBMyogY5fR9bgf` whose content sha256 `40ff0779…44c7` == official **v2.2.0** release asset (`spl_stake_pool.so`, 328,264 B) — i.e. a **prepared, not-yet-executed** v2.2.0 upgrade (buffer authority = Squads vault `dPpFfahS…`). See README §3.3.
2. *pool_state.json fee misalignment*: resolved. The early scratch decode was wrong; the final decoder (analysis/verify_all.py, 29/29 PASS) confirms epoch_fee 5%, stake/sol deposit+withdrawal fees 0.05%, all Option fields None, deposit authority = default PDA `4Y6XeEZ2…` (set), no sol withdraw authority.

**Verification legend:** `[V]` = verified from a primary/authoritative source · `[S]` = secondary/market data · `[P]` = provided by parent, not re-verified here · `[R]` = rumor/unverified.

---

## 1. Program-level context

- Pool program: canonical SPL Stake Pool `SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy`. `[V]`
- Repo: `github.com/solana-program/stake-pool` (moved from solana-labs/solana-program-library); releases tagged `program@vX.Y.Z`, each listing a solana-verify build hash. `[V]`
- Version timeline `[V]`:
  - `program@v2.0.4` — 2025-12-04 — "contains important bug fixes discovered during an audit and formal verification… Known deployments have already been notified and upgraded."
  - `program@v2.1.0` — tag 2026-07-09 (security commits authored 2026-05-08) — "important bug fix and caps the maximum withdrawal fee increase to 50 basis points." Announced in the official Solana Changelog 2026-07-16.
  - `program@v2.1.1` — 2026-09-09 (version bumps only; source identical to v2.1.0).
  - `program@v2.2.0` — 2026-10-06 (freeze-authority mints for new pools, 1-SOL-minimum support, slippage-check move; build hash `d18a2cdc…`).

## 2. Exploit/advisory history for SPL Stake Pool

### 2.1 Official posture `[V]`
- `github.com/solana-program/stake-pool/security/advisories`: "There aren't any published security advisories" (2026-10-15).
- No GHSA/CVE for spl-stake-pool found. DefiLlama's hacks DB (1,302 incidents) contains no Solana stake pool / LST entry. Vendor material: "There has never been a documented successful exploit of a stake pool on Solana." `[S]`

### 2.2 Real vulnerabilities (all fixed before the pool's deployed version)
| # | Date | Source | Mechanism | Unprivileged? | Fixed in |
|---|---|---|---|---|---|
| A | 2021-12-17 | Soteria/sec3 X-Ray | `Initialize` didn't mint tokens for lamports pre-funded in the reserve; front-runner could steal the creator's excess reserve lamports (PoC 97.99 SOL) | **Yes** | PR #2636 (2021) |
| B | 2023-01 | OtterSec audit | `OS-SSP-ADV-00` [high] manager front-runs deposits; `OS-SSP-ADV-01` [med] fee-update delay bypass — both resolved | Manager | 2023 |
| C | 2023-01/2023-12 | Halborn audits | HAL-01s (low): fee update before epoch; small-deposit fee avoidance (solved 2024-01-22); unwraps/overflow-checks (info) | Mixed | 2023–2024 |
| D | 2025-09 (blog 2026-07) | **Certora** audit + formal verification | **H-03: `WithdrawStake` could drain/hijack the reserve stake account (loss of funds)**; H-01/H-02 accounting; M-01 cluster-restart stake hijack; M-02; L-01/L-05 | **Yes (permissionless class)** | **v2.0.4 (2025-12-04)** |
| E | 2025-12-04 | v2.0.4 commit `0e56295` | Batch: cluster-restart stake hijacks; transient-stake hijack accounting; removed-validator lamport spikes; WithdrawStake reserve-cap; preferred-validator bricking of withdrawals; reward-payout mispricing; 20k-validator cap | Mixed | v2.0.4 |
| F | 2026-07-09 | **v2.1.0** (commits 2026-05-08) | (1) `Fee::check_withdrawal` used `Option::map` instead of `and_then` → withdrawal-fee-increase limit could be **bypassed**; (2) added the +50 bps/epoch cap on top of the 1.5×/epoch factor | Manager only | **v2.1.0** |
| G | 2026-10-02 | Neodyme review of PRs #883/#884 (= v2.2.0) | No vulnerabilities found; notes new freeze-authority trust assumption applies only to newly created pools | n/a | n/a |

**Conclusion:** no unprivileged theft from a properly configured canonical-program pool is documented on mainnet; the permissionless drain/hijack classes were fixed in v2.0.4 and the fee-cap bypass in v2.1.0 — **both included in the deployed v2.1.0 build** (hash-verified). "Fake stake pool 2021" and "2022 withdraw incidents" `[R]` — no primary sources found (phishing/drainer scams and the 2022 Slope/Phantom key-leak are unrelated).

## 3. Phase / AeroPool / pdSOL history `[V/S]`

- Phase (phase.cc) is the rebranded AeroPool: mint `aeroXvCT6…` still in Sanctum's curated list as legacy "aeroSOL" (logo under `phaselabscrypto`); pool/mint/vlist accounts use `aero…`; `aeropool.io` archived 2024-07→2025-05.
- Team: Brandon Geraldi (CEO), Adam Carter (CTO), Dan Trilo (CFO), Gabriel Hicks (Head of Staking), et al. Claims "SOC-2 Type II", "EST. 2021", "$700M+ staked", X `@phase_` ("1M+ SOL delegated across 100+ validators").
- Two LSTs: **YIELD** (Phase Stake; Phase's own validators, 0% commission) and **pdSOL** (Phase Delegation; merit-based via Index Power Score; validator-side Phase Bonds; relaunch blog 2026-04-07).
- **No incident, depeg, redemption halt, stuck-withdrawal report or key-rotation report found for aeroSOL/pdSOL** (negative finding across Reddit/X/blogs/DefiLlama/Ketju/SolanaCompass). `[R]`
- Third-party diligence: DefiLlama lists Phase Delegation (Liquid Staking) from 2026-08-27, TVL ≈ $111.9M; **no recorded audit**; Ketju Research memo 2026-09-15 "Not approved — another provider of the same kind was chosen" (selection policy, not a defect) noting thin public control evidence and that under stress the real exit is secondary-market depth. `[S]`
- Hygiene items: `phase.cc/legal` 404; `/delegation` data-load failure from a datacenter IP (possibly IP/JS blocking); archived `/delegation/stake` (2026-04-13) advertised Stake/Unstake UI. `[V, caveat]`

## 4. Other pools / mechanism transferability

- Program users: JitoSOL, BlazeStake bSOL, JPool jSOL, Binance bnSOL, Sanctum pools/Infinity, plus branded LSTs (Phase sells this as a service). `[V/S]`
- **Lido on Solana sunset (2023-10-16; front end stopped unstaking 2024-02)** — business wind-down, not an exploit; lesson = venue/exit risk (holders can rely on third-party UIs/routes after a provider leaves).
- Certora H-03 / M-01 classes apply to **every pool deployed at ≤ v2.0.3** — fixed in this pool's v2.1.0. Preferred-validator/transient-lamport withdrawal dead-ends likewise fixed in v2.0.4.
- JIP-9 "Interceptor Liquidity Defense" — economic (toxic flow) defense for LSTs; relevant to thin LSTs like pdSOL, not a program exploit.
- Squads-vault manager removes single-key manager risk but not staker-EOA risk nor the upgrade-authority root trust.

## 5. pdSOL market status (2026-10-15)

- Mint `aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF` (9 dec, freeze authority none): supply 952,415.11, mcap ≈ $112.46M, price $118.08, **241 holders**; 24h: 3 traders, 2 buys/1 sell, sell volume ≈ $637; organic score "low". `[V]`
- **No DEX pairs** (DexScreener empty); only route = **Sanctum** (Infinity + Router + VaultLiquidUnstake). `[V]`
- Jupiter quotes (100 bps, 2026-10-15): 1k pdSOL → 1,155 SOL; 10k → 11,525; 30k → 34,511; 35k → 40,260 (−0.44% vs NAV); **40k → 1,471 SOL (96.8% impact); 50k/100k same 1,471** (route flips). Buy side works (50k SOL → 43,226 pdSOL). **Interpretation: ~$4M can exit near NAV via Sanctum; larger exits must use the pool's native WithdrawStake/WithdrawSol (epoch latency) or be split.** Quotes ≠ fills. `[V quotes]`
- Sanctum lists the mint under the stale name "aeroSOL"; Sanctum sol-value API returns 1.1303 SOL vs pool NAV 1.1554–1.156 (≈2.2% gap, cause unverified). `[V value]`
- No sunset notice; deposits demonstrably still open (buy quotes imply working mint); fees per Solana Compass: rewards 5%, deposits/withdrawals 0.05% (matches parent decode). APY ≈ 4.6%. `[S]`

## 6. Risk assessment for THIS pool

| Risk | Applies here? | Basis |
|---|---|---|
| Permissionless reserve drain/hijack (Certora H-03), cluster-restart/transient hijacks | **No** — fixed in v2.0.4 ≤ deployed v2.1.0 | Certora + v2.0.4 commits |
| Withdrawal bricking (preferred validator, >20k validators, reward-payout mispricing) | **No** — fixed v2.0.4 | v2.0.4 commits |
| Withdrawal-fee cap bypass (overflow) + compounding fee increases | **No** — fixed v2.1.0 | `ae43045`, `54cdced` |
| Manager fee/privilege abuse | Bounded (caps; 3-of-4 Squads vault) | v2.1.0 caps; parent decode |
| Staker-EOA compromise (validator churn; no principal theft) | **Yes, low** | program semantics |
| Program upgrade authority (Squads) | **Yes — root trust, systemic**; a v2.2.0 upgrade is prepared (buffer hash-verified) and not yet executed | parent + buffer check |
| Secondary-market exit depth | **Yes** — ~$4M near NAV, then cliff | Jupiter quote probe |
| Operator transparency (no published audit, stale Sanctum name, /legal 404, 241 holders) | **Yes (op/exit risk, not theft)** | DefiLlama/Ketju/site checks |
| Token freeze risk | **No** (no freeze authority; program-level option only affects new pools) | parent + Neodyme |

## 7. Sources (accessed 2026-10-15)
github.com/solana-program/stake-pool (releases, advisories page, commits `0e562954…`, `ae430458…`, `54cdceda…`); sec3.dev X-Ray blog (2021-12-17); anza-xyz/security-audits inventory (Kudelski 2021, Neodyme 2021/2022/2023/2026-10-02, Quantstamp 2021, OtterSec 2023, Halborn 2023-01/2023-12, Certora FV 2025-09-15); certora.com reports/blog (2026-07-16); solana.com changelog 2026-07-16; phase.cc + Wayback (aeropool.io CDX, /delegation/stake 2026-04-13, blog posts 2026-04-07/04-22); x.com/phase_; solanacompass pool page; api.llama.fi (protocols, yields, hacks); lite-api.jup.ag (tokens + quotes); api.dexscreener.com; igneous-labs/sanctum-lst-list; extra-api.sanctum.so; ketjuresearch.com (2026-09-15); blog.lido.fi sunset (2023-10-16); forum.jito.network JIP-9.

## 8. Verified vs rumor
Verified: no published advisories; audit/fix history as tabled; v2.1.0 fee fixes; Phase = rebranded AeroPool with two LSTs; pdSOL market data + ~$4M depth cliff; deposits open. Unverified/rumor: 2021 "fake stake pool" program bug; any 2022 withdraw incident; Sanctum sol-value gap; any Phase incident/key rotation (none found); Phase's SOC-2/$700M claims.
