# childA — Solana/Sui live sanity check (pass7 uncovered leads)

**Mode:** READ-ONLY. No tx signed/sent, no keys, no CI, no builds. **Date:** 2026-10-25.
**RPC:** Solana `https://api.mainnet-beta.solana.com` (JSON-RPC `getAccountInfo` base64/jsonParsed, `getSignaturesForAddress`), slot **≈461,355,500–461,360,000**. Sui `https://graphql.mainnet.sui.io/graphql` (epoch 1291). Public RPC JSON-RPC on Sui is deprecated → used GraphQL only.
**Method:** raw JSON-RPC via a local Node script (`/tmp/opencode/p7/sol2.js`, `sig.js`); upgrade authority = decode `ProgramData` header (tag@0, authority@13..45) of the program's programdata account; on-curve = ed25519 point decompression on the 32-byte pubkey. Sui package IDs resolved from the DefiLlama adapters + object `type.repr`, then `packageVersionsBefore/After` to detect upgrades. Web: DefiLlama adapters (raw), docs/search. Web content treated as untrusted data.

**Bottom line:** every named program **EXISTS and is live**; **none is a fresh discovery that changes the pass7 picture.** Two corrections stand out: (a) **TurboFlow Perps is the only live plain-key (on-curve) upgrade authority** in the set — P-class, and (b) the **Sui "fresh cluster" packages are versioned/upgradable** (AlphaLend v7, Kai 17 versions, Bluefin margin_bank 24 versions), so they are **not** immutable-safe. **AlphaFi is winding down** (ALPHA-oracle bad debt, Sui Foundation covered the shortfall; withdrawals-only), so its $2.32M is draining, not a live E-U target. Loopscale Curation's on-chain surface is **Exponent's** strategy-vault program with a **Loopscale curator role**, not a Loopscale program (PRIOR-PARTIAL vs pass5 core). The pass6-open-tail names (Sat Rush/Loyal Earn/TRUE DEX/Pascal/N1/Byzanlink) are **CLOSED, E-U $0** — no work here.

---

## A. Solana

### 1. Project 0 (marginfi-v2 fork) — `MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA`
`EXISTS`, executable, BPFLoaderUpgradeable; programdata `4Q8u2ny8YYgytJEncwZQfVWbd5axZtfgDxYKHehvPQR7` (10 MiB alloc), deployed slot 176,528,154 (**2023-02-07**), last upgrade slot 456,861,410 (**2026-10-14**, 95 upgrades). **Upgrade authority `J3oBkTkDXU3TcAggJEa3YeBZE5om5yNAdTtLVNXFD47` = OFF-CURVE PDA** (system-owned, 7.22 SOL) → gov/multisig, **not** P-class. Confirms the lane: this **is** the marginfi-v2 open-source codebase (`0dotxyz/marginfi-v2`). Prior-covered: **PRIOR-PARTIAL** (fork of the excluded marginfi lineage).

| Field | Read |
|---|---|
| Exists / live custody | yes · **$59.0M** (DL `project-0`, 2026-10-25) |
| Upgrade authority | `J3oBkTk…` off-curve PDA → gov/multisig |
| Prior verdict | PRIOR-PARTIAL (marginfi-v2 fork) |

### 2. GMX Solana / GMTrade (gmsol-labs)
`EXISTS` — store `Gmso1uvJnLbawvw7yezdfCDcPydwW2s2iqG3w6MDucLo`, treasury `GTuvYD5SxkTq4FLG6JV1FQ5dkczr1AfgDcBHaFsBdtBg`, LP `LPMWczEVgXyQ3979XaqqEttanCXmYGvtJqPVtw1PvC8`. All three share **one upgrade authority `6qp7veALWas5rxXJRQXUEbffRtDyhB8koxenBpS51SrA` = OFF-CURVE PDA** (system-owned, 5.74 SOL) → gmsol **timelock/gov**, not P-class. Store programdata `CSp2sB68THdrJP6N7Au4Y5u89VJ1E1ebaqZ2soHhQvav`, deployed 2025-02-11, last upgrade 2026-10-21. Open source (`gmsol-labs/gmx-solana`), audited (Zenith 2026-01-20; lane cites 2026-10-09), role-based `Store`. No prior verdict in our trackers.

| Field | Read |
|---|---|
| Exists / live custody | yes · **$26.5M** (DL `gmx-solana`) |
| Upgrade authority | `6qp7veAL…` off-curve PDA → gov/multisig (shared by store/treasury/LP) |
| Prior verdict | none (fresh); audited + OSS, no path proven |

### 3. Perena / Numeraire — `NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P`
`EXISTS`, programdata `64h2hsxpnUprJu87bwH7HcYxoVtbidw95bZ7m5JTXGp`, deployed 2024-10-09, last upgrade 2025-03-27. **Upgrade authority `CPJo7euWKrEETLmGJsctRnrXxbikFsb6KLN59moNN88K` = OFF-CURVE** (confirmed: on-curve=false; system-owned, 0.679 SOL) → gov/multisig, not P-class. Hinted-swap risk (`SwapExactInHinted`, "hints do not bound swap amounts") remains **unproven either way**; 2 audits.

| Field | Read |
|---|---|
| Exists / live custody | yes · **$14.67M** vaults + $0.57M dex (DL `perena-vaults`) |
| Upgrade authority | `CPJo7euW…` off-curve (NOT plain key) |
| Prior verdict | none (fresh) |

### 4. Streamflow — `STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH` + `STREAMribRwybYpMmSYoCsQUdr6MZNXEqHgm7p1gu9M`
`EXISTS`; stake programdata `Furs1qmRoTtb7E8qae53sKqmWCc9tRio4GPABDehPHh6`, deployed 2024-10-02, last upgrade 2025-12-10 (36 upgrades). **Upgrade authority `5u7o2WGgHckh18opTfPsqKb8E3nhDKcReBrbzUeXg2n7` = OFF-CURVE** (system-owned, 1.65 SOL). STREAM mint: **supply 299,999,808.7 (dec 6), mint & freeze authority REVOKED (NONE)**. No fresh surface observed (old, audited vesting/staking). No prior verdict in our trackers.

| Field | Read |
|---|---|
| Exists / live custody | yes · **$13.3M** (DL `streamflow`) |
| Upgrade authority | `5u7o2WGg…` off-curve; STREAM mint auth revoked |
| Prior verdict | none (fresh) |

### 5. TurboFlow Perps — `HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg`
`EXISTS`, programdata `7jn8SF6uUubRsLQP1FHbzzRnQhFAUMFSiw9B6TQN34iC`, deployed 2025-09-25, last upgrade 2026-07-27. **Upgrade authority `HJbtKYPEum9bMVorEs8DEJUXLXv5XCi3mYuzJ45bYCxK` = ON-CURVE = true and has NO on-chain account → a plain keypair (P-class plain-key upgrade authority).** Bridge authority PDA `8iquHJQyXUq8ykTEKZjtS4wSHKnxiw4ghGWUNzPnA9Q4` = off-curve, **owned by the TurboFlow program** (datalen 0) → program PDA. This is the single most notable item: an EOA-style upgrade key over a $6.7M live perp+bridge. (Note: this is **P-class**, i.e. key-compromise risk, not a proven unprivileged drain.)

| Field | Read |
|---|---|
| Exists / live custody | yes · **$6.7M** (DL `turboflow-perps`) |
| Upgrade authority | `HJbtKYPE…` **ON-CURVE plain key (P-class)**; bridge PDA `8iquHJQy…` program-owned |
| Prior verdict | none (fresh) |

### 6. Loopscale Curation — (no Loopscale program; = Exponent vault curator role)
The DefiLlama `loopscale-curation` adapter does **not** read a Loopscale program: it reads **Exponent's strategy-vault program `sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD`** (vault layout exposes `navAumCircuitBreakerState, squadsSettings, squadsVault`), filtered to vaults whose `roles.curator` = **`bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN`**. Reads: Exponent program `EXISTS`, programdata `36EV3EKoArMVsWQNonccP68eEN2jRoQdPxj46JjmC4cA`, **upgrade auth `62zLwJ1xBfsUkhLuBtxgdd8xvhrJ19suDBxviXG95baN` off-curve**. The curator key `bs1PuRvB…` is **ON-CURVE = true** (plain keypair, system account, 1.47 SOL) — but it is a *role* key inside Exponent vaults, not an upgrade authority. Context: **Orca + Loopscale merged to form "Formation" (announced 2026-10-07)**. Prior-covered: pass5 assigned "Loopscale $7.49M" **core**; the curation/roles module is distinct → **PRIOR-PARTIAL**.

| Field | Read |
|---|---|
| Exists / live custody | yes · **$7.07M** (DL `loopscale-curation`) |
| Program | Exponent `sVau1tX…` (upgrade auth `62zLwJ1…` off-curve) + curator role `bs1PuRvB…` (on-curve key) |
| Prior verdict | **PRIOR-PARTIAL** (pass5 core; curation module distinct) |

### 7. RateX — registry is an ALT, not a program
`eP8LuPmLaF1wavSbaB4gbDAZ8vENqfWCL5KaJ2BRVyV` is **NOT a program**: owner `AddressLookupTab1e1111111111111111111111111`, executable=false, 7,480 B. The DL adapter confirms it is a **snapshot lookup table of (vault authority, mint) pairs**. Actual RateX market programs (per docs) e.g. `RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D` (SOL), `RATEuvat8kBBvomUgsbGDS2EV4KjKCoMKCP3DpxYmF8` (JLP) — both `EXISTS`, **share upgrade authority `AbkPd7MssyeQmEfF4fDusoJTn2um4LArZHvk4wms4pig` = OFF-CURVE** (system-owned, 0.999 SOL) → gov/multisig. PT/YT pricing surface untested. No prior verdict.

| Field | Read |
|---|---|
| Exists / live custody | yes · **$2.37M** (DL `ratex-dex`) |
| Upgrade authority | `AbkPd7Ms…` off-curve (shared across RateX market programs) |
| Prior verdict | none (fresh) |

### 8. Oro Finance · Solayer USD · Omnipair
- **Oro Finance ($2.30M):** on-chain **INTI program `iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop`** (`EXISTS`, programdata `HR1faCkgBnGFwzg6hS14S5QGe5SDEbLdFU8WsG7TsQFb`, **upgrade auth `6W3gBk9Ush9oyiyJkjQhu47KCr1aHEZv2hFy8TkGQcJc` off-curve**). GOLD mint `GoLDppdjB1vDTPSGxyMJFqdnj134yH6Prg9eqsGDiw6A`: **supply 576,211,592 (dec 6) = 576.21 oz ≈ $2.3M**, **mint authority `HKMT2i4k…` = a PDA of the INTI program** (off-curve). Custody model is **custodial/off-chain** (Brinks vaults, GRAIL partner+user co-signed API; DL TVL = tokens minted) → not a pooled-contract E-U surface.
- **Solayer USD — mint `LAYER4xPpTCb3QL8S9u41EAhAX7mhBn8Q6xMTwY2Yzc`:** supply 999,998,140.18 (dec 9); **mint & freeze authority `7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru` = OFF-CURVE** (system-owned). Underlying Solayer program `sSo1iU21jBrU9VaJ8PJib1MtorefUV4fzC9GURa2KNn` `EXISTS` (upgrade auth `GcYvLKKEWpxQMqFe9HUcDJYMGvXt7kwf8gfBvjnW4wnm` off-curve). DL "address" is a mint, not a program.
- **Omnipair — LP mint `omfgRBnxHsNJh6YeGbGAmWenNkenzsXyBXm3WDhmeta`:** supply 13,799,973.88 (dec 6); **mint authority `8s6Jdoh7tgUqmU3D2EmpNJHSvuN5U4NybpLAdsiMitwB` = OFF-CURVE** (system-owned). Audited (Offside/Ackee). DL "address" is a mint, not a program.

| Target | Exists / custody | Authority | Prior | Verdict |
|---|---|---|---|---|
| Oro Finance | yes · **$2.30M** (DL; 576.21 oz GOLD) | INTI prog `iNtiXEFg…`, upgrade auth `6W3gBk9U…` off-curve; mint auth = INTI PDA | none | **NOT-A-PROTOCOL** (off-chain/custodial gold custody) |
| Solayer USD | yes · **$0.71M** (DL) | mint auth `7671j7qp…` off-curve; prog `sSo1iU21…` off-curve gov | none | **OPEN (residual, LOW)** — mint-level lead |
| Omnipair | yes · **$0.66M** (DL) | LP mint auth `8s6Jdoh7…` off-curve | none | **OPEN (residual, LOW)** — mint-level lead |

---

## B. Sui fresh cluster (packages resolved)

Package IDs pinned from DefiLlama adapters + Sui GraphQL `type.repr`; **all are versioned (upgradable)** — `packageVersionsAfter` non-zero means newer versions exist and an **UpgradeCap** was/is held (holder not resolved this pass — do not read "Immutable object owner" as "not upgradable").

| Protocol | Package ID | Versions (before/after) | Live custody (DL) | Note |
|---|---|---|---|---|
| **AlphaFi Lending (AlphaLend)** | `0xd631cd66…` (v1) → latest `0xee754fc0c6d977403c9218cedbfffed033b4b42b50a65c2c3f1c7be13efeafd2` (v7) | 6 / 0 | **$2.32M** | **WINDING DOWN** — ALPHA-oracle misconfig → bad debt; Sui Foundation covered it; withdrawals-only, new deposits/loans halted. Oracle `0x39850d8d…`, LendingProtocol obj `0x01d9cf05d65fa3a9bb7163095139120e3c4e414dfbab153a49779a7d14010b93` |
| **DipCoin (AMM/spot)** | `0xdae28ab9ab072c647c4e8f2057a8f17dcc4847e42d6a8258df4b376ae183c872` (`manage::Pool`) | 0 / 0 (v1) | spot **$0.94M** | pools from `api.dipcoin.io`; e.g. SUI/USDC pool `0x7fbd7f60…` |
| **Bluefin Pro** | `margin_bank` `0xcb4e1ee2a3d6323c70e7b06a8638de6736982cbdc08317d33e6f098747e2b438`; `bluefin_vault` `0x9added62ef3a869653ef13e754d51fb62adc9f93e2717d2e23ba1214c4ef8d15` | 2/22 and 0/7 | **$1.58M** | BankV2 obj `0x39c65abe…`; USDC Vault obj `0x10d48e11…` |
| **Kai Finance** | `0x01c389a85310b47e7630a9361d4e71025bc35e4999d3a645949b1b68b26f2273` (`vault`) | 0 / 16 | **$0.93M** | many vault objects (wUSDC, SUI, USDY, DEEP, WAL, BTC…) |
| **Suigar** | `0xcbb0929f21450013ebe5e86e7139f2409da2e3ed212c51126a7e6448b795a43f` (`sweethouse`) | 0 / 1 | **$0.17M** | SweetHouse vault obj `0xa1549d73…` |

| Target | Exists / custody | Upgrade authority | Prior | Verdict |
|---|---|---|---|---|
| AlphaFi Lending | yes · **$2.32M** (DL) | upgradable (v7); **sunsetting** | none | **LANE-CLOSED** (external wind-down; withdrawals-only) |
| DipCoin spot/vault/perp | yes · **$0.94M/$1.58M/$1.92M** | upgradable (manage v1, 0 newer) | none | **OPEN (residual, LOW)** |
| Bluefin Pro | yes · **$1.58M** | upgradable (many versions) | none | **OPEN (residual, LOW)** |
| Kai Finance | yes · **$0.93M** | upgradable (17 versions) | none | **OPEN (residual, LOW)** |
| Suigar | yes · **$0.17M** | upgradable (v1→v2) | none | **OPEN (residual, LOW)** |

*(Bucket Protocol V2 ($27.7M Sui) was assigned to the same wave but is out of this child's named scope; not checked here.)*

---

## C. pass6-open-tail names (target 10) — CLOSED, not OPEN
Grep of `ci/ZH4P6-RESULTS-TRACKER.md` + `pass6-recon/README.md` + `pass6-open-tail/README.md`: **Sat Rush, Loyal Earn, TRUE DEX, Pascal, N1 Exchange Bridge, Byzanlink** were all **located and closed by pass6-open-tail with E-U $0.00** (nominal custody ~$9.57M, entirely user-scoped or authority-gated; no E-U-conditional above dust). Pass7's lane row 14 ("not closed") is **stale** — the pass6-open-tail run (2026-10-25, CI 40203839) supersedes it. Verdict: **LANE-CLOSED**.

| Name | pass6-open-tail outcome | Verdict |
|---|---|---|
| Sat Rush (`satRushGBRY…`) | E-U $0 (P $2.25M PDA custody) | LANE-CLOSED |
| Loyal Earn | E-U $0 (no proprietary program; per-user Kamino) | LANE-CLOSED |
| TRUE DEX (`ttaiNybR…`) | E-U $0 (P $289.8k zk-verifier) | LANE-CLOSED |
| Pascal (`3vCgc3aL…`) | E-U $0 (P $2.33M PDA) | LANE-CLOSED |
| N1 Exchange Bridge (`n1brh2Aa…`) | E-U $0 (P $1.38M; proof-binding not decompiled) | LANE-CLOSED |
| Byzanlink (`HyuZ17H9…`) | E-U $0 (P; Kamino kvault fork) | LANE-CLOSED |

---

## Verdict line per target (1 line each)
1. **Project 0** — PRIOR-COVERED (marginfi-v2 fork; off-curve gov upgrade; not a novel codebase).
2. **GMX Solana** — OPEN (residual, LOW): $26.5M, audited OSS, off-curve gov upgrade, no path proven.
3. **Perena** — OPEN (residual, LOW): $14.67M hinted-swap; off-curve gov upgrade; not proven either way.
4. **Streamflow** — OPEN (residual, LOW): $13.3M, old/audited; off-curve gov upgrade; no fresh surface.
5. **TurboFlow Perps** — OPEN (P-class): $6.7M live perp+bridge with an **on-curve plain-key upgrade authority**.
6. **Loopscale Curation** — PRIOR-COVERED / PRIOR-PARTIAL: surface is Exponent `sVau1tX…` + Loopscale curator role.
7. **RateX** — OPEN (residual, LOW): $2.37M; registry is an ALT; market programs share off-curve gov upgrade.
8. **Oro Finance** — NOT-A-PROTOCOL (off-chain/custodial gold; INTI program off-curve gov). **Solayer USD** and **Omnipair** — OPEN (residual, LOW), mint-level leads (off-curve mint authorities).
9. **Sui cluster** — AlphaFi **LANE-CLOSED (external wind-down)**; DipCoin/Bluefin Pro/Kai/Suigar **OPEN (residual, LOW)** (all packages versioned/upgradable; UpgradeCap holder unresolved).
10. **Sat Rush / Loyal Earn / TRUE DEX / Pascal / N1 / Byzanlink** — **LANE-CLOSED** (pass6-open-tail E-U $0).

**Nothing here is a new live unprivileged drain.** Consistent with the lane: this is the 7th consecutive $0 E-U pass on the non-EVM surface.

---

## What ran locally
- Local Node JSON-RPC scripts (`getAccountInfo` base64 + jsonParsed, `getSignaturesForAddress`) against `api.mainnet-beta.solana.com`; on-curve check via in-process ed25519 decompression. Reads at slots ≈461,355,537–461,359,931.
- Sui GraphQL: `object{asMoveObject.contents.type.repr}`, `owner{__typename}`, `asMovePackage.packageVersionsBefore/After`, `objects(filter:{type:"0x2::package::UpgradeCap"})` probe. Epoch 1291.
- Web/API: DefiLlama adapter sources (raw GitHub: loopscale-curation, oro-finance, ratex/rate-x, solayer, kai, dipcoin, bluefin, suigar, alphafi), `api.dipcoin.io/api/pools`, docs/search (RateX addresses, GMX Solana program IDs, AlphaFi wind-down).
- Local trackers read (read-only): `ci/ZH4P6-RESULTS-TRACKER.md`, `ci/ZH4P7-RESULTS-TRACKER.md`, `pass6-recon/README.md`, `pass6-open-tail/README.md`, `zombie-hunt-iv/pass7/solana-sui.md`.
- **Not run:** no CI, no builds, no transaction signing/sending, no key material written. Existing pass7 second-wave folders (e.g. `gmx-solana/`, `perena/`, `turboflow/`, `sui-fresh/`) were **not modified**.
