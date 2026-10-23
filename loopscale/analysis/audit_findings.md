# Exponent Vaults (the program behind "Loopscale Curation") — audit-finding inventory

Sources (public, from `github.com/exponent-finance/exponent-audits`, fetched read-only 2026-10-23):

| Report | Date | Scope | Result |
|---|---|---|---|
| `ExponentVaults_Audit_adevar.pdf` | 2026-04-13 | Exponent Vaults (whole program) | H01–H03, M01–M13, L01–L04 — 18 Resolved, 2 Acknowledged |
| `exponent_vaults_audit_extension_adevar.pdf` | 2026-05-25 | Exponent Vaults (extension) | H01, M01–M09, L01–L09 — 18 Resolved, 2 Acknowledged |
| `exponent_vaults_audit_may_ottersec.pdf` | 2026-05-29 | Exponent Vaults | OS-EXV-ADV-00…37 (medium/low) — all resolved except a few acknowledged LOW |

Deployed program `sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD` was **last upgraded slot 456,916,574 = 2026-10-14T17:11:12Z**,
i.e. **after every audit above**. The deployed binary also contains the fix markers (see `ci-out/fix_markers.txt`):
`Cannot remove the last price manager` (ADV-09 / PR#3695), `Invalid vault creator` + `YVault creators capacity exceeded`
(ADV-26 / PR#3828), `Live wrapper setup only supports additive strategy position changes` (ADV-28),
`Direct policy changes require an empty vault (total AUM must be zero)`.

## Findings that are NOT external-unprivileged (privileged "manager/allocator/policy-executor" paths)
Adevar ext M01–M09 / L01–L09 and Adevar H01/M01/M03/M05/M07/M13 are all phrased *"A manager can …"* — they require the
vault **manager/allocator** role. For the 13 Loopscale-curated vaults that role is Loopscale's own key
`bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN` (verified live). They are **P** (privileged), not **E-U**.

## Findings with an unprivileged flavour (all Resolved unless noted)
- **Adevar H02** — 1-token donation to a newly initialized vault (lp_supply==0) permanently blocks deposits. *Griefing/DoS, Resolved.*
- **Adevar M04** — Manipulable CLMM token composition in vault AUM → *"allow attackers to drain vault reserves"*. **Resolved.**
- **Adevar M08** — Withdrawal-queue DoS (cycle queue/cancel to block manager ops). *DoS, Resolved.*
- **Adevar M11/M12** — opt-out unfillable / sentinel takeover unreachable. *Liveness, Resolved.*
- **OtterSec ADV-08** — permissionless `initialize_prices` could let an arbitrary caller take the global price-registry manager role. **Resolved (PR#3694)**; verified live: `initialize_prices` now returns `UnauthorizedRole 6005`.
- **OtterSec ADV-09** — singleton price-registry re-initialization takeover. **Resolved (PR#3695)**; fix marker present in ELF.
- **OtterSec ADV-26** — permissionless `initialize_vault` may pin shared prices. **Resolved (PR#3828)**; allowlist marker present.
- **OtterSec ADV-27** — direct entrypoints bypass role semantics. **Resolved (PR#3829)**; live `manage_vault_settings` enforces role (`UnauthorizedRole 6005`).
- **OtterSec ADV-29** — delegated accounts accepted as withdrawal sources. **Resolved (PR#3831).**
- **OtterSec ADV-31** — zero-mint bypasses price validation. **Acknowledged** (LOW). Post-ADV-26 vault creation is allowlisted, so only an authorized creator can reach it; it distorts that creator's own vault, no third-party theft.
- **OtterSec ADV-32** — pre-funded PDAs block account creation (seed-specific DoS). **Acknowledged** (LOW). Griefing only; no profit.
- **OtterSec ADV-19** — withdrawal fees rounded away by splitting. Fee-avoidance (protocol loses fees), not extraction from others.
- **OtterSec ADV-25 / ADV-18 / ADV-21** — AUM staleness in locked-withdrawal / post-fill / AUM-sensitive checks. Resolved.

## Residual (documented, not E-U)
- `update_price` (tag 0x07) and `refresh_aum` (tag 0x27) are **permissionless cranks by design** — verified live (a fresh
  payer reaches the body; `update_price` with an empty update list succeeds as a no-op). Any price actually written must
  match configured oracle interface accounts and pass TWAP-divergence / heuristic / confidence checks, and users set their
  own `min_lp_out` / slippage. No unprivileged extraction path was found.
- The program source repo is private; the deployed-vs-audit comparison is by deploy date + string markers, not byte-diff.
