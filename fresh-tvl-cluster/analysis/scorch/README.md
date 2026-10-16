# Z3-H17 · Scorch (Solana) — single-key upgrade authority on a routed DEX vault custodian

**Date:** 2026-10-16 · **Chain:** Solana mainnet-beta · **Status:** read-only; keyless public RPC only; no transactions, no keys
**Scope:** router/vault-custodian program `SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn` (upgradeable, single-key authority) + its vault PDA `EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP` (51 SPL/Token-2022 accounts, ≈$4.26 M) + adjacent programs `ojh19ojaKduoJZuaJADhcVGp4xt1TcdAvZmpVsCorch` (SCORCH core) and `proVF4pMXVaYqmy4NjniPh4pqKNfMmsihgd4wdkCX3u`.
**Method:** Solana JSON-RPC reads (public endpoint), independent PDA derivation with `@solana/web3.js`, router IDL recovery (`bitquery/solana-idl-lib`), instruction-surface census over recent successful txs, upgrade-history reconstruction, DL API cross-check. No forge test for Solana (skipped by design; there is no EVM component — see §7).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | risk class |
|---|---|---|---|
| Router program `SCoRcH…` instruction surface (`swap`, `swap2022`) | **$0 — no concrete unprivileged path found** | IDL (shank, address-matched) shows **only two swap instructions**, both requiring a `userTokenAuthority` **signer** and both moving tokens in/out of the caller; no withdraw/claim/admin/close instruction exists. Census of 28 recent successful invocations: instruction tags only `0x01/0x02`, all 34-byte args, account counts 13/17, **every tx has ≥1 non-program signer** | E-U (surface), residual unknown in pricing internals |
| Upgrade authority of the router | **$0 for an outside attacker; $4.26 M for the key holder** | authority `6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ` is a **plain single keypair** (system-owned, 0 data, 7.75 SOL, top-level tx signer at slot 454,866,345 — not a multisig/PDA). A malicious upgrade replaces the program and can move the whole vault PDA inventory | **P** |
| Vault PDA `EHcege7dok…` (51 token accounts) | **$0 via any enumerated route** | token accounts are SPL/Token-2022 accounts owned by a PDA derived under the router program — **only the router program can sign for them**; the router's only instructions are swaps at backend-determined pricing. No instruction moves vault funds without an in-side user transfer | H-O? / P (see §6) |
| Core AMM `ojh19oja…Corch` (pricing engine) | **not verifiable (no IDL/source)** | separate upgradeable program, own single-key authority `F6qazjHEsMwHowDpLEVbwyJrtczPBecgYtFFTeptz862`; pricing correctness cannot be audited from public data | residual E-U unknown (documented) |

**Headline: E-U $0 — no concrete unprivileged extraction path found; P = the full ~$4,276,000 inventory PDA (single-key upgrades of the router, and secondarily the core).** E-U confidence: **medium** (instruction surface and signer model high-confidence; swap-pricing internals and the core program unverified).

## 2. What Scorch actually is (mechanism, in exact terms)

- Scorch is a **Solana DEX venue** ("constant-product" per Eco's SDK), routed by **Jupiter** (`JUP6Lk…`) and other aggregator programs. Observed route (tx `48GDpicL…`, slot 457,493,911): Jupiter → Raydium LaunchLab (`LBUZKhRx…`) → **`SCoRcH…` swap** (inner CPI, 17 accounts) → core (`ojh19oja…Corch`, 8 accounts) → PumpSwap (`pAMMBay6…`).
- **Eco SDK mapping (docs.eco.com):** `SCORCH_CORE_PROGRAM_ID = ojh19ojaKduoJZuaJADhcVGp4xt1TcdAvZmpVsCorch` (pool state + pricing engine) · `SCORCH_ROUTER_PROGRAM_ID = SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn` (**"the real custodian; the swap CPI's actual CALL target"**) · `SCORCH_HAIRCUT_PPM = 300000` (Eco quotes keep only 70 % of naive constant-product output — i.e., they treat raw vault-reserve pricing as *unreliable*).
- **Router IDL** (`analysis/scorch/scorch_idl.json`, origin `shank`, embedded address matches the program): exactly two instructions, no others:
  - `swap` — accounts: `vaultAuthority`, `userTokenAuthority` (signer), `userTokenIn`, `userTokenOut`, `vaultTokenIn`, `vaultTokenOut`, `tokenProgram`, `backendProgram`, `backendAccount1..3`, `market`, `sysvarInstructions`, account13. Args: `id: u128`, `mode: ExactIn|ExactOut`, `amount: u64`, `other_amount_threshold: u64`.
  - `swap2022` — same for Token-2022 with `tokenInMint`/`tokenOutMint`/two token programs/`memoProgram`.
- The **custody model**: every pool vault is a token account whose owner is the single PDA `["authority"]` derived under the router program (`EHcege7dok…`, bump 255). The router signs outflow via its PDA only inside a `swap` that also pulls the in-side from `userTokenIn` (the caller's own account). There is no router instruction to transfer vault funds anywhere else.
- **Empirical surface census** (`analysis/scorch/raw/surface_census.json`, 35 recent successful program txs): 28 invocations, tags `{0x02: 27, 0x01: 1}`, all 34-byte data (1-byte tag + 16+1+8+8 args), 17 or 13 accounts, **all transactions user-signed**. Matches the IDL exactly; no unknown instruction has been observed live.

## 3. Live-state assessment (2026-10-16; slots cited per read)

- **Program** `SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn` — executable, `owner = BPFLoaderUpgradeab1e…` (upgradeable), lamports 1,693,443; programData `5TXQj77qXxFR4USAwkR3A5LQVnXyPxWCSUutj8R1fwdp`; **last deploy slot 425,743,288**; **upgrade authority `6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ`** (read live from ProgramData, slot 457,485,334).
- **Upgrade authority class — verified plain key**: system-owned, `space = 0`, no data, 7,751,122,829 lamports (~7.75 SOL); it appears as a **top-level signer** (with a valid ed25519 signature, tx succeeded) in slot 454,866,345. A PDA can never be a top-level signer, and a Squads multisig vault is a PDA → **not a multisig, not a PDA — a single hot/dev keypair**. Its recent activity was a direct program interaction (slot 454,866,345), not an upgrade.
- **Upgrade history** (ProgramData signatures): ≥9 successful deployments; most recent at slot 425,743,288 (~147 days before the current slot 457.5 M); one failed upgrade attempt at slot 431,605,757. The program is actively developed/upgraded by the key holder.
- **Vault PDA** `EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP` (verified `PDA(["authority"], SCoRcH…)`, bump 255, via `@solana/web3.js`; my first in-session pure-Python derivation disagreed — the JS library result was then confirmed on-chain by the token-account set, see §8 caveats).
  - PDA *state* account: owner = router program, 800 bytes, discriminator `55804784ed6943fe` (no common Anchor account-name match — shank/custom layout), lamports 7,658,915.
  - **51 token accounts (38 SPL + 13 Token-2022)**, enumerated at slot 457,493,475/479. Priced with DefiLlama (`solana:<mint>`): **$4,259,772.38** (re-run: $4,260,937.73) vs **DL TVL $4,275,230.49** — reproduced (±0.36 %; 9 of 51 mints unpriced, incl. a Pons-style PEPE token). Full table: `analysis/scorch/raw/tvl_reproduction.json`.
  - Largest legs: wSOL 5,916.34 ($621.6 k) · USDC 561,082.24 ($560.8 k) · wNEAR 74,288.80 ($386.3 k) · USDT 298,919.23 ($298.6 k) · cbBTC 3.3217 ($272.1 k) · PUMP 53.68 M ($242.2 k) · ZEC 169.44 ($203.6 k) · LIT 61,656.13 ($188.2 k) · PENGU 17.19 M ($130.7 k) · 2Z 3.71 M · USELESS · JUP 356,532 · DOGE 1.33 M · FARTCOIN · STRK · SPCX/SPCXX/CRCLX (tokenized equities) · BONK 20.39 B · KMNO · TRUMP · ACT · MET · GRASS · ENA · TAO · RAY · HYPE · SKR · USD1 · STC · … (35 priced symbols).
  - The PDA's tokens move **during swaps only**: sampled txs show net dual-sided flows (e.g., slot 457,493,669: −192.99 USDC / +1.83 wSOL; slot 457,493,668: −15.98 USDC / +91.75 USELESS) — balanced exchange of inventory vs user funds at backend pricing.
- **Adjacent programs:** core `ojh19oja…Corch` (programData `2LG7p9rf…`, last deploy slot 449,987,639, authority `F6qazjHEsMwHowDpLEVbwyJrtczPBecgYtFFTeptz862`) · `proVF4pM…` (last deploy 454,781,973, authority `CjoV5B96…`) — both upgradeable, both present in Scorch routes; neither authority was further classified.
- **No on-chain Anchor IDL**: both candidate IDL PDAs (`F6Sw7Vx6…` anchor:idl, `HcRQNK5Z…` idl) are missing; no `security.txt` PDA either. The IDL used here is the community-published shank IDL for the exact program address.

## 4. What an attacker can / cannot do (exact paths)

Can (all verified; none profitable):

- Call `swap`/`swap2022` directly or via any CPI-ing program, as an unprivileged signer with their own tokens: swap in `userTokenIn` → `vaultTokenIn`, receive `vaultTokenOut` → `userTokenOut` at backend pricing, bounded by `other_amount_threshold`. This is the entire unprivileged instruction surface.
- Observe that the vault's 51 accounts are rotated through by normal trading — anyone can be the counterparty of a swap.

Cannot:

- Move vault funds anywhere other than a swap counterparty: no instruction on the router transfers from `vaultToken*` without an associated in-side transfer from a user-signed token account; the token accounts' owner is a PDA that only the router program can sign for; the core AMM program (`ojh19oja…`) **cannot** move them either (delegation/ownership is under the router's PDA).
- Extract via direct program invocation: census shows no unknown instruction tags live; direct/CPI invocations all resolve to the two IDL instructions.
- Use someone else's tokens as the in-side: the token program enforces that `userTokenAuthority` (the signer the router passes) owns/delegates `userTokenIn` — pulled from the caller only.
- (Not tested / not verifiable here): an unbalanced swap caused by a bug in the **core pricing engine** or in the router↔core account-validation would be the only unprivileged monetization left, but (a) no such behavior was observed in sampling, (b) the core program has no public IDL/source, (c) Eco's SDK explicitly applies a 30 % haircut to naive CP math — an internal acknowledgment that raw vault-ratio pricing is not trustworthy at quote time. This is stated as **unknown**, not as a found path.

## 5. Upgrade / P-class analysis

- **Single key** `6km771w…` can deploy arbitrary bytecode to the router program (BPFLoaderUpgradeab1e `Upgrade`), which then signs for the vault PDA. **Full inventory ≈ $4.26 M (+9 unpriced mints) is at risk of one signed transaction** (deploy drainer → sweep 51 accounts). No timelock, no multisig, no on-chain governance observed. The key is an active hot key (recent direct program interaction, ~7.75 SOL balance).
- Secondary P: the **core** program's authority `F6qazjHEsMwHowDpLEVbwyJrtczPBecgYtFFTeptz862` can change pricing logic; combined with the router it can drain via mispriced swaps. Also upgradeable: `proVF4pM…` (authority `CjoV5B96…`).
- This matches the screening hypothesis (P-class single-key upgrade) and **upgrades it with a verified, non-multisig key and a live 51-account inventory**.

## 6. Verdict and monitor

- **E-U (external unprivileged, live): $0 — no concrete unprivileged path found. Confidence medium.** The router's *instruction surface* claim is high-confidence (IDL + census + SPL ownership model); the *pricing/internal* claim is not auditable from public sources → E-U cannot be positively excluded for the core AMM math, but the only spendable instruction requires the attacker's own tokens and a signer.
- **E-U-conditional: none identified.**
- **P: ≈$4,259,772 (priced; DL $4,275,230) — the entire vault PDA inventory via single-key program upgrades** (router primary; core secondary). Confidence high on the upgradeability + key class; the value is point-in-time.
- **S / H-O: 0 identified.** The vault inventory is not shown to be user-withdrawable by any router instruction; whether LPs have exits lives in the unverified core program (`ojh19oja…`) — flagged as unknown, not classified.
- **Monitor conditions (exact):**
  1. `ProgramData 5TXQj77qXxFR4USAwkR3A5LQVnXyPxWCSUutj8R1fwdp` — `authority` field change away from `6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ`, or any new successful deploy (slot > 425,743,288); watch `getSignaturesForAddress(5TXQj77q…, limit 1)`.
  2. Program write-lock (`authority = None`) would *reduce* P risk.
  3. Unexpected large one-sided outflows of the 51 PDA token accounts without matching user-side inflows (subscription diff on `getTokenAccountsByOwner(EHcege7dok…)`).
  4. New instruction tag ≠ {0x01, 0x02} in `SCoRcH` invocations (would indicate a new/upgraded surface).

## 7. PoC / testing section

- No forge test for Scorch: **Solana program, no EVM-side component** (verified — no EVM addresses in the integration; the Chain-4663 "Fang" work is entirely separate). Per the task instructions, no `poc/test/Scorch.t.sol` was created.
- Evidence tooling instead: **`analysis/scorch/scorch_evidence.sh`** — keyless, re-runnable endpoint script (public RPC only) that dumps: program account, ProgramData (authority + last-deploy slot), authority account + signatures, PDA state, **all 51 token accounts**, IDL-account probes, upgrade history, recent activity, and the priced TVL reproduction. Raw JSON in `analysis/scorch/raw/` (scorch_program_getaccountinfo.json, programdata_getaccountinfo.json, solana_auth_getaccountinfo.json, auth_signatures.json, pda_correct_getaccountinfo.json, pda_correct_spl_accounts.json, pda_correct_t22_accounts.json, tvl_reproduction.json, idl_accounts_correct.json, programdata_signatures.json, program_signatures_1000.json, surface_census.json, scorch_cpi_tx.json, dl_protocol_scorch.json) + `analysis/scorch/scorch_idl.json`.
- Independent-derivation note: the PDA was computed with `@solana/web3.js@1` `findProgramAddressSync([b"authority"], SCoRcH…)` → `EHcege7dok…` bump 255; the on-chain evidence (51 accounts, matching DL tokens) confirms it. (An in-session hand-rolled ed25519 check produced a wrong candidate first — discarded; the JS-library value was adopted and verified on-chain.)

## 8. Methodology, sources, caveats

- Read-only: Solana JSON-RPC (getAccountInfo/getSignaturesForAddress/getTransaction/getTokenAccountsByOwner/getMultipleAccounts), `@solana/web3.js` for PDA math, DefiLlama `coins.llama.fi` for prices, DefiLlama protocol API + live adapter (`projects/scorch/index.js`) for TVL cross-check, Eco SDK docs for venue architecture, `bitquery/solana-idl-lib/scorch/scorch.json` for the IDL, Dune Spellbook (`scorch_solana_stg_raw_swaps.sql`) corroborating the 2-tag model (`data[0] ∈ {0x01,0x02}`, accounts > 10).
- Caveats: (a) **no source/bytecode audit** — the core pricing engine `ojh19oja…` has no IDL/source available, so a *swap-math* E-U bug cannot be positively excluded; (b) the IDL is community-published, not on-chain — it matches live behavior but is not cryptographic proof; (c) the 800-byte PDA state layout is unidentified (custom/shank, discriminator `55804784ed6943fe`); (d) token prices are point-in-time; 9 mints unpriced (~0.3 % of value); (e) slots grow ~0.4 s — value citations are slot-stamped; (f) the other two programs in the route (`ojh19oja`, `proVF4pM`) were not deep-audited (their upgrade authorities were read but not classified).
- **Files:** `README.md` · `summary.json` · `scorch_evidence.sh` · `scorch_idl.json` · `raw/**` (all RPC dumps listed in §7).
