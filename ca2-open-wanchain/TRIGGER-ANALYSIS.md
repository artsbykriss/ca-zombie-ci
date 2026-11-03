# TRIGGER ANALYSIS — Wanchain Cardano `TreasuryCheck` (~$542k)

**Question:** the residual risk in `README.md` is "a legacy-format signature under the current GPK drains the treasury". Is that trigger attacker-inducible, or does it require a storeman operational mistake?

**Answer (short):** **(b) — only reachable through a storeman/signing-flow mistake.** Since the V3 migration there are **52 storeman-signed Cardano transactions (49 treasury releases + 3 mint-check), 52/52 in the V3 `serialiseData` encoding and 0 in the legacy raw-concat encoding**; 24 of them post-date the current-key rotation, also 24/24 V3. The live signer demonstrably uses the V3 encoder. No user-callable path to a *legacy* signature was found.

Read-only, no secrets. Tip at capture: block 14,153,013 (2026-11-03). Machine-readable census: `ci-out/signature_census.json`.

---

## 1. Signatures since the GPK rotation

**Key timeline (three keys, not one).** The exploit-era `GroupInfo` (`e4cb1352…#0`, old holder address) carried GPK `0335664e…d98a` and the V2 check script `485aa1…`. The bridge then moved to a new `GroupInfo` address (`addr1w9vxq85q…`) and the V3 check script:

| Block | Time (UTC) | GPK slot | Check script | Note |
|---:|---|---|---|---|
| (July) | 2026-07-20 | `0335664e…d98a` | `485aa1…` | exploit-era config |
| **13,997,675** | **2026-09-28 04:27:24** | `03486efc…aca8` | `8c02…` | **V3 era begins** (interim key) |
| **14,027,655** | **2026-10-05 04:24:34** | `03486efc…aca8` | `8c02…` | datum carries pending-next-key record `[022af717…, 1,791,600,629,000]` |
| **14,044,468** | **2026-10-09 04:00:38** | **`022af717…0e9e`** | `8c02…` | **current key installed** (`GroupInfo` `2211c2a0…#0`) |

So the direct `0335664e → 022af717` replacement happened in two steps; the **current-key rotation block is 14,044,468**, and the V3 encoding was already in use from block 13,997,675. A first `8c02` treasury spend appears at block 14,044,163, still before the current-key rotation.

**Census.** Enumerated every transaction at the six `TCheckCoin`-holding check-script addresses and at the current mint-check validator, for two windows: since the V3 migration (block 13,997,675) and since the current-key rotation (block 14,044,468) (`poc/signature_census.py`):

| Validator | Type | `AppendByteString` | `SerialiseData` | Since V3 migration | Post-rotation |
|---|---|---:|---:|---:|---:|
| `8c027908…` treasury check (current) | PlutusV3 | **0** | 2 | **49** | **22** |
| `4730b708…` mint check (current) | PlutusV3 | **0** | 2 | **3** | **2** |
| `485aa1…` treasury check (exploited) | PlutusV2 | 1 | 1 | **0** | **0** |
| `cfd786f4…`, `4efc0be6…`, `41b2a43a…`, `8d4c43c5…` (superseded) | V3/V2 | — | — | **0** | **0** |

**Total since the V3 migration: 52 signed transactions, 52/52 V3; since the current-key rotation: 24, 24/24 V3; legacy: 0; spends on `485aa1…` or any older check script: 0.**

The 22 treasury releases after the current-key rotation (the 27 earlier V3-era releases at the same address have the same structure; details in `ci-out/signature_census.json`):

| Block | Tx | Amount (XER units) | ADA | Recipient `toPkh` | TTL (ms) |
|---:|---|---:|---:|---|---:|
| 14,044,514 | `503cf9740c93…` | 64,271,200,000 | 1,215,420 | `667b7071…1763` | 1,791,519,944,000 |
| 14,044,518 | `da9c18719153…` | 63,648,448,000 | 1,215,420 | `667b7071…1763` | 1,791,520,003,000 |
| 14,044,529 | `f2e4d6f861e7…` | 64,271,200,000 | 1,215,420 | `667b7071…1763` | 1,791,520,189,000 |
| 14,044,535 | `30257a6645bf…` | 62,082,586,000 | 1,215,420 | `667b7071…1763` | 1,791,520,301,000 |
| 14,044,555 | `7f7103bc6704…` | 63,872,000,000 | 1,215,420 | `667b7071…1763` | 1,791,520,751,000 |
| 14,044,559 | `8634fd26df03…` | 33,262,342,000 | 1,215,420 | `667b7071…1763` | 1,791,520,900,000 |
| 14,044,605 | `39a988ed3bb2…` | 63,872,000,000 | 1,215,420 | `667b7071…1763` | 1,791,521,635,000 |
| 14,044,610 | `df769ee5dd46…` | 59,918,922,000 | 1,215,420 | `667b7071…1763` | 1,791,521,711,000 |
| 14,044,639 | `06a5eee2cdfe…` | 63,872,000,000 | 1,215,420 | `667b7071…1763` | 1,791,522,303,000 |
| 14,044,641 | `1e32a98227d1…` | 58,683,398,000 | 1,215,420 | `667b7071…1763` | 1,791,522,390,000 |
| 14,044,716 | `604504b27306…` | 62,874,000,000 | 1,215,420 | `667b7071…1763` | 1,791,524,126,000 |
| 14,044,724 | `f4c1a7ae62b2…` | 31,120,634,000 | 1,215,420 | `667b7071…1763` | 1,791,524,245,000 |
| 14,044,743 | `cc1d363a3c6e…` | 62,874,000,000 | 1,215,420 | `667b7071…1763` | 1,791,524,494,000 |
| 14,044,745 | `f13ade02393d…` | 56,571,630,000 | 1,215,420 | `667b7071…1763` | 1,791,524,560,000 |
| 14,044,756 | `5af4e3ad3db0…` | 62,874,000,000 | 1,215,420 | `667b7071…1763` | 1,791,524,784,000 |
| 14,044,759 | `42609cea06b8…` | 55,144,490,000 | 1,215,420 | `667b7071…1763` | 1,791,524,850,000 |
| 14,048,332 | `3ae00eae292f…` | 56,586,600,000 | 1,215,420 | `667b7071…1763` | 1,791,597,006,000 |
| 14,048,338 | `267e3e91ba04…` | 34,408,046,000 | 1,215,420 | `667b7071…1763` | 1,791,597,125,000 |
| 14,048,413 | `4f8560cbfced…` | 60,357,183,896 | 1,215,420 | `667b7071…1763` | 1,791,598,662,000 |
| 14,048,415 | `a4aefbb2735c…` | 55,255,128,105 | 1,215,420 | `667b7071…1763` | 1,791,598,662,000 |
| 14,048,510 | `fc7af8d8efd4…` | 60,108,894,671 | 1,215,420 | `667b7071…1763` | 1,791,600,562,000 |
| 14,048,512 | `64a9859da603…` | 54,252,923,330 | 1,215,420 | `667b7071…1763` | 1,791,600,629,000 |

All 22: `purpose=spend`, `valid_contract=true`, mode 0 (ECDSA), one signature field of 64 bytes, one change output, TTL ≈ block time + 9 minutes. Total **1,250,181.626002 XER**. Two batches: 16 txs on 2026-10-09, 6 on 2026-10-10. **Every one pays the same recipient** `667b70713c2ac14e83fbf860e40baa5e2172c9613291289fde201763`.

The 2 mint-check txs (`ef71111d1aee…`, `d70b31c726a8…`, blocks 14,092,338/342) carry a **different** 11-field message (mint proof) and also validate under a V3, `serialiseData`-only script — they cannot feed the treasury V2 path.

**How the encoding was determined.** We did not need to re-derive the digest. The V3 validators have exactly one signature path — `sha3_256(serialiseData(ConstrData …))` — and contain no `AppendByteString`; a legacy raw-concat digest cannot satisfy them. A transaction that validates under `8c02` therefore proves the signer produced a V3-format digest. Conversely, zero transactions validated under `485aa1` (the only script on this treasury that computes the legacy digest). The address itself fixes the validator (script payment credential), so the 49 treasury releases at `addr1xxxqy7gg…` are 49 independent V3 signatures. The census was produced from the accepting validators in `plutus_contracts[]`, cross-checked against the redeemer's 14-field structure and 64-byte signature.

---

## 2. What induces a storeman signature?

**Bridge flow (BNB → Cardano release, the direction that spends the treasury).** The user redeems a wrapped asset on BNB; the Wanchain bridge burns/locks the wrapped token and emits a cross-chain request; the 25-node storeman set observes it, reaches threshold (17/25), and signs the Cardano release message (the 13-field `TreasuryCheckProof`) that the treasury check script verifies. The reverse direction (Cardano → BNB) is the mint-check path (2 txs) and produces a different 11-field message.

**BSC contracts verified in this pass:**
- Wrapped NIGHT (ERC-20): `0xFe930c2d63AeD9b82fC4DBC801920dD2c1a3224F` — `WrappedToken`, `owner()` = `0x39af91cba3aed00e9b356ecc3675c7ef309017dd`.
- Owner = Wanchain `TokenManagerProxy` `0x39af91cba3aed00e9b356ecc3675c7ef309017dd`, implementation `0xeeaaf9f4bc94031544c3ea94a8cef2fe1291b997` (`TokenManagerDelegateV2`).
- `mintToken(token,to,value)` and `burnToken(token,from,value)` are **`onlyAdmin`** — not user-callable. The storeman group is represented by `GroupApprove` `0x5a809f774a2f9fb2587aeca7e380e3d67522e15f` (owner of the TokenManager).

**User-callable entry point.** Wanchain's architecture puts a separate **CrossChain router** in front of the TokenManager; that router's BSC address was **not recovered** from public data in this pass (BscScan account APIs are paywalled on the free tier; the AddAdmin log search over the ranges tried returned nothing). What *is* observable is the behaviour: all 22 Cardano releases go to **one** recipient in two batches of 31k–64k XER — consistent with operator/market-maker settlement or batched redemption, not open retail flow.

**Consequence.** Even if a user can induce a signing request through the router, the signature produced is a V3 `serialiseData` signature (proven by 24/24 on-chain acceptance). It is useless to the V2 script. There is no observable user-callable path that produces a *legacy* signature.

---

## 3. Are the 14 "armed TCheckCoin UTxOs" actually spendable?

**Yes, they are spendable inputs — but they are authorisation/check tokens, not a value pot.**

- 14 UTxOs at `addr1x9y94ggrg0mrhnp2g0ckyhwggyynfz8ydpd6vp7vrpa6f9f9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsrlh4ng` = payment script **`485aa1…`** (the exploited V2 check script) + stake script `259b187a…14f1`.
- Each holds **exactly 1 `TCheckCoin`** (policy `526d2460…`, name `TCheckCoin`) + **1,219,730 lovelace**, inline datum `d8799f01ff` (`Constr 0 [1]`). Total: 14 NFTs, ~17.08 ADA of dust. Last touched block 13,703,937 (2026-07-21); still unspent at block 14,153,013.
- **What they authorise:** the treasury value validator (`1cfb41dc…`) requires only `valueOf(all inputs, TCheckCoin) == 1`; the check script then verifies the signed withdrawal. There is **no per-transaction cap and no binding to a specific treasury UTxO** — a single check input can authorise a transaction that spends **every treasury UTxO of the signed asset** (`treasuryInputValue` aggregates all inputs at the treasury address; `isValidValue` requires each to be ADA + exactly the target asset). Concretely: the **29 NIGHT UTxOs (11,837,345.21 NIGHT ≈ $502k) in one transaction**, the 25 lovelace-only UTxOs in another, the 34 XER UTxOs in another, and so on. The 14 tokens are 14 independent, interchangeable authorisations.
- **Consumed and recreated:** the V2 script requires exactly one `TCheckCoin` in its **own output** (`amountOfCheckTokeninOwnOutput == 1`, source-verified), so a spend consumes one and returns one to the same address. The exploit tx `0a4861be…` did exactly that (output #2 = 1,219,730 lovelace + 1 `TCheckCoin` back to the old address). The set is therefore **reusable indefinitely**, not one-shot.
- **Expiry:** none at the UTxO level. The signed message carries `ttl`, and `checkTtl` requires the transaction's validity interval to equal the interval derived from `ttl` — so a *leaked signature* is only usable inside its signed window (observed windows ≈ 9 minutes). The UTxOs themselves never expire.

So: they are an armed **authorisation capability**, not a pot of value. The value they can unlock is the $542k treasury, not the ~$17 of dust.

---

## 4. Live signer format — observable evidence

**Direct on-chain proof: the live signer produces V3 `serialiseData` digests.**

- 52/52 signed transactions since the V3 migration (24/24 since the current-key rotation) validated under V3 validators whose sole digest path is `sha3_256(serialiseData(…))` and which contain **zero `AppendByteString`** (`8c02`: sha3=1, serialiseData=2; `4730b708`: sha3=1, serialiseData=2).
- 0/52 validated under `485aa1` or any other `AppendByteString` script.
- If the signer were producing legacy raw-concat digests, every one of these transactions would have been rejected by the V3 script. They were not.

**Supporting / contradicting evidence:**
- The public SDK `fridayback/contracts-sdk` (last commit **2026-05-28**, pre-exploit) still implements the legacy encoder (`TreasuryScript.caculateRedeemDataHash`, raw concatenation of 14 fields). It is demonstrably **not** what the production signer uses today; it is a live regression hazard, not evidence of current behaviour.
- No operator announcement or post-mortem describing the new encoder was found (Wanchain had not published a full technical post-mortem).

**Limit.** We cannot inspect the signer binary or its configuration. The classification is behavioural: 24 on-chain signatures accepted only by `serialiseData` validators. That is strong (each is an independent signing event over 3.5 months), but it cannot prove the absence of a dormant legacy code path.

---

## 5. Verdict on inducibility

**(b) — only reachable via a storeman operational mistake / signing-flow regression. Not attacker-inducible today.**

| Claim | Status | Basis |
|---|---|---|
| 52 V3-era / 24 post-rotation storeman signatures exist | **Proven** | On-chain census, `ci-out/signature_census.json` |
| All 52 (and all 24) are V3 `serialiseData` | **Proven** | Accepted by `AppendByteString`-free validators; 0 accepted by `485aa1` |
| No legacy signature since the V3 migration | **Proven** | 0 spends at `485aa1` and 0 at the four older check scripts |
| A user can induce a storeman signature | **Unproven / not found** | Router address not recovered; observed releases are single-recipient batches; even if inducible, the output is V3 |
| The signer has no legacy code path | **Inferred** | 52/52 V3 over 5 weeks; cannot inspect the signer |
| A legacy signature would drain the signed asset's treasury balance | **Proven mechanism** | The July exploit signature verifies under the legacy digest; the V2 script is still armed with 14 reusable check tokens |

**Quantification.**
- **E-U today: $0.** There is no unprivileged action that yields a legacy-format signature, and the current validators reject everything else.
- **E-U-conditional: up to the signed asset's entire treasury balance per leaked signature** — **NIGHT ≈ $502k from one legacy NIGHT signature**; the full ~$542k would require further legacy signatures for the other assets (ADA-only, XER, …). The attacker would need to land each spend before the signed `ttl` (≈ 9 minutes in every observed message), so the practical requirement is mempool monitoring plus a signing-flow regression.
- **Category: P/latent** (operator/signer error), not E-U. The trigger is not a key compromise and not a user-callable bridge function.

**Considered and rejected — cross-schema reuse.** Could a *mint-check* signature (11-field legacy/other message) be replayed against the treasury V2 script? Both are concatenations, so a byte-equality collision would be needed between the two preimages. The treasury's `txHash` field (32 bytes) would have to equal the mint message's `packInteger(index)‖packInteger(mode)‖uniqueId[0:30]`, while `hasUTxO` simultaneously requires that value to be a real input reference. Aligning both is infeasible; the mint path is also V3 today.

**Bottom line.** The ~$542k trigger is *not* a live attacker capability. It is a one-signature-away operational failure mode: a stale SDK, retry tool, or misconfigured signer that emits the old encoder once. The operator-side fix is to burn/migrate the 49 stale `TCheckCoin` UTxOs (or at minimum the 14 at `485aa1`) and to add a `TreasuryCheckVH == own hash` binding to any future check script so a superseded script can never spend again.

---

## Reproduce

```bash
python3 poc/signature_census.py     # 22 + 2 signed txs, 0 legacy (this file's §1)
python3 poc/poc_encoding.py         # legacy collision + real ECDSA verification
```

CI: `bash /home/heisenberg/CA/ci/ci-run.sh ca2-open-wanchain` — step 4 runs the census.
