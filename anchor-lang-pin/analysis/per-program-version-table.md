# Per-program deployed anchor-lang version table — P5-08 (CVE-2026-45137)

All reads: Solana mainnet, 2026-10-23, finalized slot ~460,352,xxx. `anchor_family` from ELF `.rodata` version markers; exact version from OtterSec verified-build attestation / repo `Anchor.toml`+`Cargo.lock` pin / last-deploy date.
`1.0.x` markers are identical for 1.0.0–1.0.3, so `ANCHOR_1_0_X` alone does not imply vulnerable; the vulnerable set is `1.0.0`/`1.0.1` only.

## A. The eight pass-5-named repos

| repo | program | program id | exists | anchor_family | exact version | last deploy (UTC) | upgrade authority | on 1.0.0/1.0.1? | evidence |
|---|---|---|---|---|---|---|---|---|---|
| marginfi-v2 | marginfi | `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA` | ✅ | ANCHOR_1_0_X | **1.0.2** | 2026-10-12 15:18 | `J3oBkTkDXU3TcAggJEa3YeBZE5om5yNAdTtLVNXFD47` | **No** | OtterSec verified build @ `c5d440f6` (is_verified=true, on_chain_hash=executable_hash); `Anchor.toml`=1.0.2; `Cargo.lock` anchor-lang 1.0.2 |
| raydium-clmm | CLMM | `CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK` | ✅ | ANCHOR_1_0_X | **1.0.2** | 2026-10-22 06:24 | `FytDrVzDybM1TwFQPGb8qaxZR7dBCzNeqT3vtQsceZQK` | **No** | `anchor-lang = "=1.0.2"`; Anchor.toml 1.0.2 since `ed1eb41519` (2026-09-29); never used 1.0.0/1.0.1 (0.32.1→1.0.2) |
| raydium-clmm | wrapper | `DRayAUgENGQBKVaX8owNhgzkEDyoHTGVEGHVJT1E9pfH` | ❌ (devnet id) | — | — | — | — | n/a | not deployed on mainnet |
| raydium-cp-swap | CPMM | `CPMMoo8…` | ✅ | ANCHOR_1_0_X | **1.0.2** | 2026-10-01 | `FytDrVz…` | **No** | `anchor-lang = "=1.0.2"` |
| raydium-launchpad | launchpad | `LanMV9s…` | ✅ | ANCHOR_1_0_X | 1.0.x (≥1.0.2 by date) | 2026-09-11 | `FytDrVz…` | **No** | deploy after 2026-05-02 fix |
| mpl-bubblegum | bubblegum | `BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY` | ✅ | ANCHOR_0_30_0_32 | ≤0.30 | 2026-09-22 | `bfQVv6niKVgEURYqQ1beJmiEQQN7MrvLRvk3mZGFubb` | **No** | `8 byte instruction identifier` (≤0.30 marker) |
| openbook | v2 | `opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb` | ✅ | ANCHOR_0_30_0_32 | ≤0.30 | 2024-02-27 | — | **No** | ≤0.30 markers |
| openbook | v1 (Serum fork) | `srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX` | ✅ | — | native Serum | 2022-12-20 | — | **No** | not an anchor program |
| light-protocol | system | `SySTEM1eSU2p4BGQfQpimFEWWSC1XDFeun3Nqzz3rT7` | ✅ | — | Pinocchio | 2026-03-12 | `7PeqkcCXeqgsp5Mi15gjJh8qvSLk7n3dgNuyfPhJJgqY` | **No** | Pinocchio entrypoint |
| light-protocol | registry | `Lighton6oQpVkeewmo2mcPTQQp7kYHr4fWpAgJyEmDX` | ✅ | ANCHOR_0_30_0_32 | 0.31–0.32 | 2026-03-18 | `7Peqkc…` | **No** | 0.31+ markers |
| light-protocol | account-compression | `compr6CUsB5m2jS4Y3831ztGSTnDpnKJTKS95d64XVq` | ✅ | ANCHOR_0_30_0_32 | 0.31–0.32 | 2026-09-24 | `7Peqkc…` | **No** | 0.31+ markers |
| light-protocol | compressed-token | `cTokenmWW8bLPjZEBAUgYy3zKxQZW6VKi7bqNFEVv3m` | ✅ | ANCHOR_0_30_0_32 | 0.31–0.32 | 2026-03-12 | `7Peqkc…` | **No** | 0.31+ markers |
| chainlink-solana | OCR2 / data-feeds | `HEvSKofvBgfaexv23kMabbYqxasxU3mQ4ibBMEmJWHny` | ✅ | ANCHOR_0_30_0_32 | ≤0.30 | 2022-11-02 | `BMKk78WEmZCQPptNYET8jdwf4EnsXY4WS74TBWjiSAbb` | **No** | ≤0.30 markers |
| chainlink-solana | OCR2 (historic) | `cjg3oHmg9uuPsP8D6g29NWvhySJkdYdAo9D25PRbKXJ` | ✅ | ANCHOR_0_30_0_32 | ≤0.30 | 2022-11-01 | `BMKk78…` | **No** | ≤0.30 markers |
| chainlink-solana | access-controller | `9xi644bRR8birboDGdTiwBq3C7VEeR7VuamRYYXCubUW` | ✅ | ANCHOR_0_30_0_32 | ≤0.30 | 2022-03-31 | `EzbKFFP5yWXVCjRGk6KGK5rnZtSVCJSPrZHkurgtFN4d` | **No** | ≤0.30 markers |
| chainlink-solana | mock-forwarder / cre-simulate-receiver | `7kuEAA3m…` / `EJwYCKxQ…` | ✅ | ANCHOR_0_30_0_32 | 0.31–0.32 | 2026-07-13 | `Av3xZHYn…` | **No** | 0.31+ markers |
| helium | 19 programs (sub-daos `hdao…`, data-credits `cred…`, lazy-distributor `1azy…`, treasury `treaf…`, mem `mem…`, fanout, mini-fanout, price/rewards-oracle, hexboosting, circuit-breaker, dc-auto-top, entity-manager, voter-stake-registry, welcome-pack, lazy-transactions, no-emit, tuktuk-dca, hpl-crons, proposals) | ✅ | ANCHOR_0_30_0_32 | 0.31–0.32 | 2025–2026 | `pULUgsYtKvT7qhsL8QJ2oJXYQUeCCdjtfawPnBqEr3U` | **No** | 0.31+ markers; full 72-row table in `child1/program_table.md` |
| manifest | main / wrapper / ui-wrapper | `MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms` (+`wMNFST…`,`UMnFSt…`) | ✅ | — | custom entrypoint | 2026-10-20 | — | **No** | zero anchor error strings in ELF; `src/entrypoint/mod.rs` |

## B. Every verified program that pins anchor-lang 1.0.0/1.0.1 (global sweep)

| program id | repo @ verified commit | anchor-lang | last verified | frozen? | forwards system-program key? |
|---|---|---|---|---|---|
| `2qEmhLEnTDu2RiabWT7XaQj5ksmbzDDs6Z7Mr2nBcU9C` | koshak01/tidex6 @ `f71575d8` | **1.0.0** | 2026-04-25 | **yes (immutable)** | No (safe `transfer` helper) |
| `Gt1duB4bPj2CmW9y7eiGzekeCfiR1UckjiyPGSbyWRVU` | koshak01/tidex6 @ `2965920f` | **1.0.0** | 2026-06-30 | **yes** | No |
| `gaszjG8797GGm8oACCzH2KLLifGp2nugKkLwaecwBjT` | axelar-amplifier-solana @ `3a1f2e7f` | **1.0.0** | 2026-05-05 | no | No (`system_program::transfer`) |
| `gtwqvLL93XK7pC2eMvfGamqokvs19AytzaVhrL2iKiz` | ″ | **1.0.0** | 2026-05-05 | no | No |
| `itsAUdHnV2K99ppbM6d6WUDac8MD54RAE7dUKHnw1Eg` | ″ | **1.0.0** | 2026-05-05 | no | No |
| `memtaCuA26EANM26matPAhiQGPnvsrYdJYrYcK8wcon` | ″ | **1.0.0** | 2026-05-05 | no | No |
| `opre2VP8uvjq3YS15NRhRagsWvsY5DybitvCeLPAwbK` | ″ | **1.0.0** | 2026-05-05 | no | No |
| `wocur7QRRMdzPZN52688gBa5iJD4mLkNWSxN5xGGRjY` | Woody4618/workflow-tutorial @ `88f139fb` | **1.0.1** | 2026-08-04 | no | No (tutorial, no system CPI) |
| `CSDD31Zmm3pRMHAMB8c3TBqsj9mbmH2rXBzV7jrsJhcd` | koshak01/tidex6 @ `37c2d308` | 1.1.2 (stale Anchor.toml says 1.0.0) | 2026-xx | no | n/a (not vulnerable) |
| `D1dCoBuiRehhT24XTF8Dmhm9cFERpmfANLB1bb3aGxLJ` | koshak01/tidex6 @ `33c6b08` | 1.1.2 (stale Anchor.toml says 1.0.0) | 2026-xx | no | n/a |

**Net: 0 of the live 1.0.0/1.0.1 programs exhibits the exploitable pattern** (raw `Instruction { program_id: <passed system_program>.key() }`). Sources: `ci-out/verified-programs-anchor.json`, `ci-out/pattern-scan.json`.

## C. Sentinel for future re-checks

A deployed program is a **candidate** iff its ELF carries a 1.0.x marker **and** its last deploy is **before 2026-05-02** (or its verified-build commit predates 1.0.2). Confirm by reading the `Anchor.toml`/`Cargo.lock` at the deployed/verified commit, then check for the forwarding pattern.
