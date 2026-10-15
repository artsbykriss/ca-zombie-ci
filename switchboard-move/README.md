# Z3-C2 · Switchboard "Move" oracle (Sui / Aptos) — deep dive: live E-U, consumer census, chain-native verification

**Date:** 2026-10-16 · **Chains:** Sui, Aptos (IOTA/Movement suspended) · **Status:** read-only research; no transactions signed or sent; no secrets in this folder; all RPCs public/keyless.
**Method:** live-state reads + deployed-bytecode disassembly (Move binary format) + chain-native simulation (Aptos `transactions/simulate`) + event forensics across all 6 published Sui package versions. CI: `ci/run.sh` re-runs every check (see §8).

---

## TL;DR

| Target | Live extractable (unprivileged, today) | Why closed / open | Latent risk |
|---|---|---|---|
| **Sui queues + package family** (`0xc3c7e6eb…`, 6 versions; queues `0x6e43354b…` / `0x662f5642…`) | **$0** | **State-blocked + partial patch.** All 48 oracles expired (0 valid); main queue paused (`fee_types=[]` = pause flag in v6); no price flow since 2026-08-29. v6 price path now requires `oracle.secp256k1_key.length()==64` (blocks empty-key signatures). Attestation path still contains the **empty-comparand bypass**, but requires a *valid guardian* (`expiration_time_ms > now`) — none exists. | **CRITICAL latent**: any future oracle with (expiration>now ∧ empty secp key) in a non-paused queue re-arms the hijack instantly (one tx: 3 self-registered guardians → `enable_oracle` → attacker key → prices). Vendor controls re-arm via `queue_override_oracle_action` (authority `0x697998fa…`). |
| **Aptos package + queues** (`0xfea54925…`, `0x7fdf7235…`, `0x3434a451…`) | **$0** | **No bypass in deployed code + dead path.** Unguarded `oracle_init_action::run` is live (verified by simulation), but `oracle_attest_action::validate` compares a 64-byte recovered pubkey to a 32-byte `oracle_key` with exact `!=` → **always false** (attestations can never validate; no self-registration escalation). Update path uses exact 64-byte compare. Feeds stale since 2026-08-29. | None unprivileged; `oracle_init_action` remains callable (spam/DoS-ish only — oracle objects are shared and unique-key-checked). |
| **Historic (2026-08-29)** | **Executed on Sui production** | Attacker `0x9104d073e1fdfd…` ran the full chain (3 fresh guardians → 3 attestations → `AttestationResolved` on production oracle `0x0f307cb2…`); vendor contained it in ~5 h (all main-queue oracles disabled 06:03/06:35 UTC; v5 published 06:37; v6 09:29). No price submissions through the hijacked oracle and no fund loss on Sui in the on-chain record. | — |

**Total live extractable now: $0.00 (E-U), confidence HIGH** on both chains. Value behind the Sui feeds while operational (corpus): ~$26M (Bucket CDP ≈$15.8M + Scallop Lend ≈$10.2M) — *latent*, not extractable in the current state; the $26M figure is a corpus number, not re-verified here.

---

## 1. Scope & target set (exhaustive)

**Sui package family** (Sui object model: one *original* package ID + 5 upgrade objects; all versions callable through the original ID):

| ver | package object ID | published (UTC) |
|---|---|---|
| v1 | `0xc3c7e6eb7202e9fb0389a2f7542b91cc40e4f7a33c02554fec11c4c92f938ea3` | 2025-01-21 16:19 |
| v2 | `0xe6717fb7c9d44706bf8ce8a651e25c0a7902d32cb0ff40c0976251ce8ac25655` | 2025-01-21 19:53 |
| v3 | `0x846e4d912db89d9db299db0cc7f56f281846ce058fb336ba76e39927836da0ac` | 2025-10-16 05:13 |
| v4 | `0xa81086572822d67a1559942f23481de9a60c7709c08defafbb1ca8dffc44e210` | 2025-10-27 20:54 |
| v5 | `0x1d5a2e826bdab3cce5cb2493aa36dcf058aa0017c4118738e6967df8821060bf` | **2026-08-29 06:37** |
| v6 | `0xf347253e6aa6f81e9da16e841c089fb09c42f7b6ec9514eeee1b5606e23f64f9` | **2026-08-29 09:29** (current) |

Sui queues (from the live state object `0x93d2a8222bb2006d16285ac858ec2ae5f644851917504b94debde8032664a791::on_demand::State`):
- **Mainnet Oracle Queue** `0x6e43354b8ea2dfad98eadb33db94dcc9b1175e70ee82e42abc605f6b7de9e910` — 23 oracles, `min_attestations=3`, validity 604 800 000 ms, authority `0x697998fab24bb575840bc66c4d176a63e7db1830c7c9494cbe9a807752cf00a5`, guardian queue → Guardian Queue, **`fee_types=[]` ⇒ paused (v6 pause flag)**, `last_queue_override_ms=1787985317708` (2026-08-28 07:55 UTC).
- **Mainnet Guardian Queue** `0x662f5642dc730289b5c8084b67e4e092428e825a97071c5cb5c691dfb2cc88f7` — 17 oracles, `min_attestations=3`, validity 157 680 000 000 ms, **self-referential guardian queue**, not paused.
- 7 third-party test queues `weiss-repro-queue / weiss-w2 / weiss-release` (authority `0xadc948a1d32c59…`, `min_attestations=1`, self-guardian, created 2026-09-13/14, 1 oracle + 3 feeds each — all expired today).

**Aptos package** `0xfea54925b5ac1912331e2e62049849b37842efaea298118b66f85a59057752b8` (21 modules; on-chain `PackageRegistry`, source not published):
- **Mainnet Oracle Queue** `0x7fdf7235bf3bd872ad093927deb2ff5f1645d1b6dabbfd4a03c3e0442788ce12` — 23 oracles, 58 aggregators, `min_attestations=3`, authority `0xfa416028d48a85cd7791c8a93c438ce8a750af333a53fde55b276fd4aa16275f`.
- **Mainnet Guardian Queue** `0x3434a45114f5f8fc577557a9a3dda54c1799fee5271313f2599a1093c4a8ba01` — 14 oracles, self-referential guardian queue.

IOTA / Movement deployments: treated as **suspended** per the vendor post-mortem (2026-09-18); not reachable with the tooling used here — not assessed.

---

## 2. The mechanism, in exact terms (verified against deployed bytecode)

### 2.1 Sui — empty-comparand signature bypass + unguarded oracle creation

Deployed code (v6 disassembly; v4 identical in the relevant parts) — `oracle_init_action::run(oracle_key, queue: &mut Queue, ctx)`:
- **public entry, no authority check**; `validate` = `queue.version()==1` + `!queue.existing_oracles_contains(oracle_key)` (v6; v1–v4 additionally checked key length — irrelevant). `actuate` → `oracle::new(...)` → `Oracle{ secp256k1_key: vector::empty(), expiration_time_ms: 0, valid_attestations: [] }` + `queue.add_existing_oracle`.

`oracle_attest_action::run(oracle, queue, guardian, ts, mr_enclave, secp256k1_key, signature, clock)`:
- v4: checked **target** oracle expiration (`oracle.expiration_time_ms() > now`) and `assert!(hash::check_subvec(&recovered_pubkey, &guardian.secp256k1_key(), 1), EInvalidSignature)`.
- v6: now checks `!queue.is_paused()`, target ∈ queue, **guardian** `expiration_time_ms > now`, then the *same* `check_subvec(&recovered_pubkey, &guardian.secp256k1_key(), 1)`.
- `hash::check_subvec(v1, v2, start)` iterates `len(v2)` times ⇒ **`v2 == empty` ⇒ `true`** (as long as `len(v1) ≥ start`). A freshly created guardian has an empty `secp256k1_key` ⇒ **any 65-byte ecrecover-valid signature passes**.
- `actuate`: `add_attestation` (dedup per guardian) → if `valid_attestation_count(key) ≥ queue.min_attestations()` (3) → `enable_oracle(oracle, key, mr_enclave, now + validity)` — **installs the caller-chosen key on the target oracle**.

`aggregator_submit_result_action::run<T>(aggregator, queue, value, neg, ts, oracle, signature, clock, fee)`:
- v4: `check_subvec(&recovered_pubkey, &oracle.secp256k1_key(), 1)` — empty key ⇒ any signature.
- **v6 fix:** `assert!(oracle.secp256k1_key().length() == 64)` before the comparison ⇒ empty-key oracle cannot be used for price submission.

⇒ **Attack chain (unprivileged, one keypair):** create 3 oracles in the guardian queue (empty keys, unguarded) → attest any *valid* production oracle 3× with the attacker's own `secp256k1_key` (signatures pass via empty guardian keys) → `enable_oracle` installs the attacker's key → sign arbitrary prices. On v4 the target only needed to be non-expired; on v6 the *guardian* must be non-expired.

### 2.2 Aptos — no bypass; broken comparison kills the attestation path

Deployed bytecode (decoded with a purpose-built Move v9 disassembler, `analysis/move_disasm.py`):
- `oracle_init_action::run(queue, oracle_key)` — public entry, no authority check (`validate` = queue exists ∧ key length 32 ∧ key unused). **Live-verified via `transactions/simulate`: an arbitrary sender gets `OracleCreated` on the live main queue** (gas 10 350).
- `oracle_attest_action::validate` — checks guardian queue membership and **guardian** expiration (`timestamp::now_seconds() > guardian.expiration_time()` → reject), then `secp256k1::ecdsa_raw_public_key_to_bytes(recovered)` (`Neq`) `oracle::oracle_key(&guardian)`. The framework type is documented 64 bytes (`ECDSARawPublicKey`, aptos-stdlib) vs a 32-byte `oracle_key` (length enforced at creation) ⇒ **the comparison is always unequal ⇒ attestations can never validate** (dead path; no `check_subvec` call anywhere in the module — identifier pool + disassembly both confirm).
- `aggregator_submit_result_action::validate` — exact `Neq` of 64-byte `secp256k1_key` vs 64-byte recovered key; no subvec; requires oracle non-expired and queue match.
⇒ **No unprivileged escalation on Aptos.** `enable_oracle` is reachable only through `queue_override_oracle_action` (authority-gated) — how the vendor's keys were set.

---

## 3. Live-state assessment (all reads 2026-10-15/16 UTC)

### 3.1 Sui
- **Oracles: 48 total, 0 valid** (`expiration_time_ms > now`): 23 main-queue oracles `exp=1` (disabled; 20 with empty `secp256k1_key`), 17 guardian-queue oracles `exp=0` (all empty), 6 oracles in the weiss queues with real keys `exp≈1789365xxx` (2026-09-14, expired), 2 never-enabled. **42/48 have empty secp keys.**
- **Main queue paused** (`fee_types=[]`); guardian queue not paused (fee_types = SUI).
- **Feeds:** 160 aggregators total; **136 in the main queue across 30 authority wallets**. Last main-queue update: **2026-08-29T05:55Z** (feed `LBTC/USD` et al.); fresh feeds that day were owned by `0x5da3b6fb…` (9 feeds: SUI/USD, USDC/USD, DEEP/USD, LBTC/USD…), `0xb7e80c62…` (SAIL/USDC), `0x0…0` (8 "surge proxy" feeds, Switchboard-managed), `0x076d5cfc…` (4 feeds). 2026-08-25: `0x8c30bf5b…` (22 feeds: ALKIMI/USD, IKA/USD, DEEP/USD, ETH/USD…), `0xf89bf436…` (24 "FORK …" feeds), `0x9acf7b57…` (BTC/USD). Nothing since.
- **Historic feed names** (consumer demand): SUI/USD, USDC/USD, USDT/USD, BTC/USD, ETH/USD, DEEP/USD, WAL/USD, LBTC/USD, SAIL/USDC, SAIL AWAY, TimeVyn SUI/USD, IKA/USD, ALKIMI/USD, SuperSUI/USDC, mETH/USDC, mUSD/USDC, xBTC/USD, haSUI, vSUI, Volo LST, "zo slp"…
- Scallop core package `0xefe8b36d5b2e43728cc323298626b83177803521d195cfb11e15b910e892fddf` (20 modules) **does not reference the Switchboard package** in any module's address-identifier table (checked all 20 modules with the same parser). Bucket CDP's package was not pinned in this pass (see blockers).

### 3.2 Aptos
- **Oracles: 23 main + 14 guardian; every `expiration_time` is in the past** (values are in ms: 2024-12 → 2026-09-23; newest ≈ 2026-09-23 < now). All `secp256k1_key` are 64 bytes (130 hex chars) — no empty-key oracle exists.
- **Feeds: 58; last updates** — 15 feeds on 2026-08-29 (APT/USD, ETH/USD, USDT/USD, LSD_USD, THL_USD, AMI/USD, MKL_USD, GUI_USD, RESERVE_USD, APE/USD…), 5 on 2026-08-24, 2 on 2026-07-29, older/never for the rest. No flow since 2026-08-29.
- Feed names map to the Aptos consumer set: stAPT/sthAPT/amAPT/KAPT/MKL/LSD (Thala/Amnis family), TruAPT, sUSDa-USDa (**likely Superposition**), PAXG/USD, GLBTC_USD, CELL/USD (Cellana), MGPT, APETOS, GUI, AMI, MOVE_USD, CAKE/USD, USD1/USD, "Merkle LP"… **Feed owners (aggregator authority) = 13 distinct wallets**, the de-facto consumer census: `0x7aa8bfe5…` (20 feeds: APT/BTC/ETH/CELL/MGPT/AMI/APE/CAKE…), `0xef90534d…` (14 feeds: LSD/GLBTC/GUI/MOVE/CASH/DONK/MOOMOO/HAIR…), `0xaf268b43…` (5 feeds: sUSDa-USDa, stAPT-USD, sthAPT-*), `0x87b81983…` (5), `0xe862c13b…` (4), `0x47c05d87…` (2: KAPT, STKAPT), plus singles (PAXG, USDC, Merkle LP, MKL, stkapt) — none have had an update since 2026-08-29. (Exact consumer-contract binding not enumerated — see blockers.)

---

## 4. What an attacker can / cannot do today (exact call paths & preconditions)

**Sui — cannot extract.**
1. `oracle_init_action::run(key, queue, ctx)` — **allowed** (no authority check) on any queue, including the guardian queue. Verified in bytecode; spam-only (unique-key check ⇒ each call consumes a distinct key).
2. `oracle_attest_action::run(...)` — **blocked at the guardian-validity check**: requires a guardian oracle in `queue.guardian_queue_id()` with `expiration_time_ms > clock.timestamp_ms()`. All 17 guardian oracles have `expiration_time_ms = 0`. The only way to give an oracle a future expiration is `enable_oracle`, reachable only via (a) attestation quorum — needs ≥3 valid guardians (circular), or (b) `queue_override_oracle_action` — authority-only (`has_authority(queue, sender)`).
3. `aggregator_submit_result_action::run<T>(...)` — additionally blocked: main queue is paused (`fee_types=[]`), and every oracle is expired; even if an oracle were valid, the v6 length-64 check kills the empty-key bypass.
4. Authority-only revive paths (`queue_override_oracle_action`, `queue_set_configs_action`, `queue_add_fee_coin_action`) — the vendor key `0x697998fa…` holds both queues' authority.

**Aptos — cannot extract.** `oracle_init_action::run` is callable (verified by simulation) but inert; attestations can never validate (64≠32 exact compare); price submissions need a 64-byte key match with an enabled oracle.

**Cost:** a full re-armed attack on Sui ≈ 7 transactions (3 oracle creations + 3 attestations + hijack; ~0.01 SUI each) + price submissions. No capital, no flash loans, no custody.

---

## 5. The 2026-08-29 Sui incident (on-chain forensics, verified)

| time (UTC) | actor | action (events, tx digests) |
|---|---|---|
| 01:32:33 | `0x9104d073e1fdfd…` | `OracleCreated` `0x4ee9d2a2…` (guardian queue) — tx `C6qrKqP7cWxvHQTVhytz…` |
| 01:32:37 | " | `OracleCreated` `0xcbce2731…` — tx `ApmhrrM2xX9dbSykeMHY…` |
| 01:32:42 | " | `OracleCreated` `0x5c506926…` — tx `6NFxo3jbcHUfmDkpaHTe…` |
| 01:32:47–55 | " | 3× `AttestationCreated` + `AttestationResolved` on production oracle `0x0f307cb2c7e1fe98587f7022ed327e2b5e8372bfa17b8a7a5f1ce6f56f911b81` (main queue) with attacker key `ew8qAZ2l…` — txs `UsP84xhW6xs7u1hHAqGx…`, `Cd2iRJsJ2u5iZ3Ed4J6m…`, `H6d13yy4JdQKn764uhMS…` |
| 05:30–05:55 | oracle operators `0xd25347a4…`, `0xc2c7a6d1…`, `0xc456b310…` | normal `AggregatorUpdated` flow on *other* oracles (the hijacked oracle was never used to push prices in the visible record) |
| 06:03:17 / 06:35:17 | vendor `0x697998fa…` | `QueueOracleOverride` on **all** main-queue oracles (incl. `0x0f307cb2…`) — key cleared, `expiration=1` (containment) |
| 06:37:30 | vendor | **v5 published** |
| 09:29:11 | vendor | **v6 published** (current; partial patch) |

No `AggregatorUpdated` event ever carries `oracle_id = 0x0f307cb2…`; no fund loss on Sui is visible in the Switchboard event record.

---

## 6. Classification & numbers

- **E-U (external unprivileged, today): $0.00** — Sui: blocked by state (no valid guardian/oracle; main queue paused); Aptos: no bypass + dead attestation path. Confidence: **HIGH**.
- **H-O:** $0 (no holder-recoverable value in oracle infrastructure).
- **P (privileged):** the entire revive path (unpause + re-key) sits with the vendor authority keys (`0x697998fa…` Sui, `0xfa416028…` Aptos).
- **S (stuck):** n/a.
- **Latent (Sui):** v6 attestation path retains the empty-comparand bypass without a guardian-key length check ⇒ **if any oracle ever exists with `expiration_time_ms > now` and an empty `secp256k1_key` in a non-paused queue, a fresh attacker can hijack oracles in one transaction set**. The vendor's own disable operation *empties* keys, so a sloppy revive (setting expiration without a key) re-arms it. Consumer value behind the feeds while operational (corpus): ≈$26M on two covered consumers (Bucket CDP ≈$15.8M, Scallop Lend ≈$10.2M) — latent only.

---

## 7. What would change the verdict

1. Any oracle anywhere in the Sui family with `expiration_time_ms > now` **and** empty `secp256k1_key` (re-check with `analysis/ci_verify.py`).
2. Sui main queue unpaused (`fee_types` non-empty) **and** ≥1 valid+empty-key guardian → price path re-arms.
3. Vendor resume that revives oracles **with real keys** → attack stays closed (check_subvec requires the key), but the *price flow* resumes → the (fixed) price path is the only gate; monitor the length-64 check remains.
4. New package versions (v7+) — re-run the bytecode checks.

---

## 8. PoC / verification & CI

- **No fork PoC is possible for Move chains in this environment** (no local Sui/Aptos VM toolchain; Sui public JSON-RPC devInspect is deprecated and the GraphQL endpoint exposes no simulation mutation). Verification was therefore done with: (a) **deployed-bytecode disassembly** (Sui: GraphQL `MoveModule.disassembly`; Aptos: custom v9 disassembler `analysis/move_disasm.py`), (b) **Aptos chain-native simulation** (`transactions/simulate`, read-only dry run — 1 unguarded-creation test), and (c) **on-chain event/tx forensics** (the Aug-29 attack is itself the proof the v4 chain worked end-to-end).
- **CI job** (`ci/run.sh`, public repo): re-fetches live Sui/Aptos state, re-checks all 24 assertions (queues paused/expired, feed staleness, v6 vs v4 bytecode markers, attack events, Aptos simulation, Aptos disassembly markers) and writes `ci-out/verification.json` + `ci-out/SUMMARY.txt`. **All 24/24 PASS.**
- **CI run URL:** _filled in by ci-log.txt (see `ci-log.txt` / `ci-artifacts/` in this folder)_ — rerun command: `bash /home/heisenberg/CA/ci/ci-run.sh switchboard-move`.

Key evidence files: `analysis/sui_queues.json`, `analysis/sui_oracles.json`, `analysis/sui_aggregators.json`, `analysis/sui_events_all_versions.json`, `analysis/sui_attack_forensics.json`, `analysis/aptos_queue_census.json`, `analysis/aptos_aggregators.json`, `analysis/sui_bytecode/*` (deployed v4/v6 disassembly), `analysis/aptos_bytecode/*` (deployed module bytecode).

---

## 9. Methodology, caveats, limitations

- **Read-only throughout**; the only "write-like" actions were node-side dry runs (Aptos `simulate`, dummy signature, nothing submitted) — no transactions signed/sent; no keys used on-chain.
- **Sui event-index quirk:** the GraphQL `events` filter keys events by the package version that was latest when the event was indexed; all six version IDs were scanned (`analysis/sui_event_scan_all.py`) to recover the full history.
- **Aptos indexer** (`api.mainnet.aptoslabs.com/v1/graphql`) rate-limited (HTTP 429) during the consumer-transaction census → the per-transaction consumer census was replaced by feed-owner + feed-staleness evidence. This is the main open item: enumerating which consumer *contracts* still call `aggregator::current_result` on the Sui/Aptos feeds (code-level binding) was not completed for all integrators; Scallop's core package was checked (no reference).
- **Aptos oracle keys were set via authority override**, not attestation (the deployed attestation compare is always-false) — consistent with `last_queue_override` semantics; not independently confirmed by event scan (Aptos events not reachable through the indexer).
- IOTA/Movement not assessed (suspended per vendor; no tooling here).
- USD figures for consumer value are corpus numbers, not re-priced here (no live consumer value was extractable, so no price is realized).

**Files index:** `README.md` (this file) · `summary.json` · `analysis/` (scripts + evidence dumps + deployed bytecode) · `ci/run.sh` + `analysis/ci_verify.py` · `ci-out/` (verification.json, SUMMARY.txt, evidence copies) · `ci-log.txt`, `ci-artifacts/` (CI logs/artifacts).
