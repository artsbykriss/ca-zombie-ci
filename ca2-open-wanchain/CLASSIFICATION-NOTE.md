# Classification note — Wanchain Cardano↔BNB bridge (CA2 OPEN-7)

**Live E-U today: $0.00 (high). KEPT as a conditional — the superseded V2 script still guards ~$542k of armed treasury UTxOs.**

## Treasury state
- `addr1xyw0ksw…` (payment `1cfb41dc…`, stake `259b187a…`): **218,156.077399 ADA + 11,837,345.212388 NIGHT + 30 CNTs in 306 UTxOs** ≈ **$541.7k–$545.8k** (ADA $0.1901, NIGHT $0.04238).
- Last movement block 14,048,512 (2026-10-10); the 34 Oct 9–10 txs use treasury `1cfb41dc` + check `8c02`.

## Replacement script — SOUND for this class
- `8c027908…` (PlutusV3, 6,501 B) is parameterised with the GroupInfo-NFT / Admin-NFT / TCheckCoin policies and the treasury hash.
- Its digest is **`sha3_256(serialiseData(Constr 0 fields))`** with **zero `AppendByteString`** ⇒ injective.
- GroupInfo is **NFT-authenticated**, and the storeman GPK was **rotated** (`0335664e…` → `022af717…`).
- **Exploit verified end-to-end:** the real July signature verifies over the 170-byte raw-concat preimage under the **old** GPK and **fails under the rotated key**; the two tuples collide (`b8a103c0126a10`) while the new serialisation separates them.

## Why E-U is $0
The replacement script is not forgeable; the rotated GPK invalidates the legacy signature; the treasury has not moved since 2026-10-10.

## The material latent (conditional)
- **Superseded V2 `485aa1…` is NOT self-disabling**: it reads the **current** NFT-authenticated GroupInfo, verifies against the **current** GPK, and **never binds its own hash**.
- It still holds **14 armed TCheckCoin UTxOs**.
- The **public SDK (last commit 2026-05-28) still computes the legacy digest**.
- ⇒ **Any legacy-format signature under the current GPK drains ~$542k.** This needs a storeman-signed legacy-format message (P/conditional), not a fresh attacker.
- **Recommended fix:** burn the stale TCheckCoin and add an own-hash binding to V2.

## Evidence
- `ca2-open-wanchain/` (README, summary.json, analysis/, poc/), CI `.../runs/41659282008` (7/7 structural checks).
- Tooling limit: no Cardano CEK evaluator; the V3 digest was not byte-reproduced (structural checks only).

## Monitor
Any spend of the **V2 script's 14 TCheckCoin UTxOs**, any **legacy-format** storeman signature, or an SDK release still computing the legacy digest.
