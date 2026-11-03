# CA2 OPEN-7 — Wanchain Cardano↔BNB bridge: `TreasuryCheck` non-injective message encoding

**Date:** 2026-11-03 · **Chain:** Cardano mainnet (tip block **14,152,985**, epoch 665)
**Status:** read-only; no transactions signed or sent; PoC is off-chain (encoding + on-chain signature verification). No secrets in this folder.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---:|---|---|
| Wanchain `TreasuryCheck` (Cardano side of the Cardano↔BNB bridge) | **$0** | Replacement Plutus V3 check script `8c027908…` builds the signed digest as `sha3_256(serialiseData(ConstrData …))`; it contains **no `AppendByteString` builtin at all**. The storeman key in the reference `GroupInfo` was rotated (2026-10-09 04:00:38 UTC, block 14,044,468), so no signature over the *legacy raw-concat* digest exists. | The superseded V2 script `485aa1…` is **not** hard-disabled by the migration: it reads the current `GroupInfo` (NFT-authenticated) and verifies against the **current** GPK. But **52/52 storeman signatures since the V3 migration (24/24 since the current-key rotation) are V3 `serialiseData` and 0 are legacy** — the trigger is not inducible by a user; it requires a signer-side regression (`TRIGGER-ANALYSIS.md`, verdict **(b)**). |

### Total live extractable now: **$0** (confidence: **high**)

The treasury is **not empty**: **218,156.077399 ADA + 11,837,345.212388 NIGHT + 30 CNTs** across **306 UTxOs** ≈ **$541,650.80** (ADA $0.190144, NIGHT $0.04238435, CoinGecko 2026-11-03; CI re-read at tip 14,153,013: **$545,762.96**). That value is **privileged-controlled** (`P`), not extractable by an unprivileged attacker.

---

## 2. The bug, in exact terms

**Incident.** 2026-07-20 14:46:50 UTC, four transactions (`0a4861be…2ea1`, `ba4edf84…2305`, `e4ff7b12…f1d7`, `fe9e9de0…af3d`) drained **515,206,545.426856 NIGHT** from the Cardano treasury; the canonical tx alone moved **203,001,692.164714 NIGHT** against a signed authorisation for ~3,110 NIGHT.

**Mechanism.** Plutus V2 `TreasuryCheck` `485aa10343f63bcc2a43f1625dc841093488e4685ba607cc187ba495` (15,989 B). Source recovered (`analysis/TreasuryCheck_485a.hs`, `Types_485a.hs`):

```haskell
tmp1 = appendByteString (appendByteString (appendByteString (appendByteString
         (appendByteString toPkhPay toPkhStk) policy) assetName) (packInteger amount)) (packInteger adaAmount)
tmp2 = appendByteString (appendByteString (appendByteString tmp1 txHash) (packInteger index)) (packInteger mode)
tmp3 = appendByteString tmp2 uniqueId
tmp4 = appendByteString tmp3 (packInteger txType)
tmp5 = appendByteString tmp4 (packInteger ttl)
tmp6 = appendByteString tmp5 (packInteger outputCount)
hashRedeemer = sha3_256 tmp6
```

`packInteger` (decompiled and confirmed): `0 → #00`, positive → minimal big-endian, negative → `#80`-prefixed. Two adjacent variable-length integers therefore let the boundary move:

| Tuple | `amount` | `adaAmount` | bytes `packInteger(amount)‖packInteger(adaAmount)` |
|---|---:|---:|---|
| Attack (on-chain) | 203,001,692.164714 NIGHT | 16 | `b8a103c0 126a` ‖ `10` = `b8a103c0126a10` |
| Compatible smaller | 3,097.56 NIGHT | 1,206,800 | `b8a103c0` ‖ `126a10` = `b8a103c0126a10` |

**Verified end-to-end in this run:** the exploit redeemer's real 64-byte ECDSA signature verifies against `sha3_256(170-byte raw concatenation)` under the exploit-era GroupInfo key `0335664e…d98a`, and **fails** under the current key `022af717…100e9e`. A second signature verifies against the *same* preimage with the smaller tuple, i.e. the collision is exploitable exactly as reported. (`poc/poc_encoding.py`.)

**The replacement.** `8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e` — Plutus **V3**, 6,501 B, deployed in tx `0729300f…` (block 13,807,055, ≈2026-08-13). Decompiled (Aiken, 25 trace strings). Digest path:

```
sha3_256( serialiseData( ConstrData(0, [redeemer fields …]) ) )
```

Builtin inventory: **`AppendByteString` = 0**, `SerialiseData` ≥ 1, `Sha3_256` = 1, one each of ECDSA/Schnorr/Ed25519 verify. Canonical CBOR of Plutus `Data` is prefix-free and typed, so distinct tuples cannot share a preimage.

The script is **parameterised** (final argument of the program):

```
Constr 0 [
  Constr 0 [
    Constr 0 [#1ddf09a9…541, "GroupInfoTokenCoin"],   -- GroupInfo NFT policy/name
    Constr 0 [#53cc8f42…1af, "AdminNFTCoin"],          -- Admin NFT
    Constr 0 [#526d2460…be6, "TCheckCoin"]             -- check token
  ],
  #1cfb41dc…5234 ]                                     -- treasury script hash
```

and it checks: the `GroupInfo` reference input holds that NFT (`getGroupInfo` equivalent), `Script(own_hash) = own_input.output.address.payment_credential` with `own_hash` from `GroupInfo[TreasuryCheckVH]`, the `TCheckCoin`, the signature, balance, treasury input, tx in/out, TTL, and change values. **GroupInfo forgery is therefore blocked** (the NFT, not the datum, is the anchor) — this is the same construction as V2 (`Types_485a.hs`: `getGroupInfo` filters reference inputs by `assetClassValueOf … groupInfoCurrency groupInfoTokenName > 0`, requiring exactly one).

---

## 3. Live-state assessment (all reads at tip 14,152,985 unless stated)

| Item | Value / evidence |
|---|---|
| Treasury address | `addr1xyw0kswupwx38ljnvq8pwpvae0x69krywdr7cffg3d84ydp9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsw5rzpd` = script payment `1cfb41dc…5234` + script stake `259b187a…14f1` |
| Treasury balance | **218,156.077399 ADA**, 306 UTxOs; **11,837,345.212388 NIGHT**; plus XER 72,913,809.68, HOSKY 116,142,883,259, COCK 20,289,164, etc. |
| Last treasury movement | **34 transactions between blocks 14,044,163 and 14,048,512 (2026-10-09/10)**; the sampled ones (14,044,163 · 14,044,639 · 14,048,332 · 14,048,512) all spend `1cfb41dc` + `8c02` and one `TCheckCoin` |
| Treasury value validator | `1cfb41dc…` Plutus V2, 1,343 B. Source (`analysis/Treasury_1cfb.hs`): its **only** check is `traceIfFalse "hat" (valueOf totalInputValue checkTokenSymbol checkTokenName == 1)` — exactly one `TCheckCoin` across all inputs. No signature; no address check. |
| Check script (current) | `8c027908…` Plutus V3, 6,501 B, `TCheckCoin` UTxOs at its address: **14** |
| Check script (exploited) | `485aa1…` Plutus V2, 15,989 B; `TCheckCoin` UTxOs still parked: **14**; last activity block **13,703,937** (2026-07-21) |
| Other superseded check scripts | `cfd786f4…` (V3, 6,501 B, last block 13,774,679), `8d4c43c5…` (V2, 14,254 B, 12,763,984), `41b2a43a…` (V2, 15,871 B, 12,306,491), `4efc0be6…` (V2, 15,103 B, 11,358,127) — each parks 7–14 `TCheckCoin` |
| `TCheckCoin` | policy `526d2460…` (Plutus V2 minting policy, 3,862 B), name `TCheckCoin`, supply **63** across **6 script addresses** (all with stake `259b187a…`), 0 burned, 7 mints since 2023. No token sits at a pubkey address. The policy has **no signature/hash builtins** and references the Admin NFT policy `53cc8f42…` + GroupInfo NFT policy `1ddf09a9…`; no unprivileged mint path identified. |
| Current `GroupInfo` | UTxO `2211c2a0…#0` (block 14,044,468, 2,749,780 lovelace + 1 `GroupInfoTokenCoin`, inline datum Constr 0 [19 params]): GPK slot = `022af717…100e9e`, TreasuryCheckVH slot = `8c027908…` |
| Exploit-era `GroupInfo` | UTxO `e4cb1352…#0`: GPK = `0335664e…d98a`, TreasuryCheckVH slot = `485aa1…` — **key rotated, script repointed** |
| Exploit tx | `0a4861be…2ea1`, block 13,702,781; redeemer signature 64 B; signed tuple amount 203,001,692.164714 NIGHT, adaAmount 16 |

**What changed after the exploit:** new V3 check script (Aug 13); migration to it by early October (first `8c02` treasury spend block 14,044,163); new `GroupInfo` UTxO `2211c2a0` on Oct 9/10 with a **rotated GPK**; the old script's `TCheckCoin` UTxOs were left untouched. Every sampled post-migration treasury spend uses `1cfb41dc` + `8c02` and one `TCheckCoin`.

---

## 4. What an attacker can / cannot do

**Cannot (today):**
1. **Re-use a signature against the current script.** The digest is `sha3_256(serialise_data(Constr …))`; canonical CBOR is injective, and the script has no `AppendByteString`. The exploit-era signature does not verify under the rotated key.
2. **Forge a `GroupInfo`.** The reference input is filtered by the `GroupInfoTokenCoin` NFT (policy `1ddf09a9…` is a script parameter). An attacker cannot mint it.
3. **Spend the treasury without a `TCheckCoin`.** The treasury value validator requires exactly one across all inputs, and all 63 live tokens sit at check-script addresses.
4. **Use the old V2 script with a current signature.** The signer produces V3 (`serialiseData`) digests; the old script recomputes the legacy raw-concat digest, so a V3 signature cannot verify there.

**Could (latent only):**
- **A single legacy-format signature under the current GPK drains the treasury.** The old `485aa1` script reads the *current* `GroupInfo` (the NFT is the only anchor) and does **not** check that `GroupInfo[TreasuryCheckVH]` equals its own hash. Its only requirements are: one `TCheckCoin` in its own output (14 UTxOs are parked), a valid `hasUTxO` nonce, and a signature over the legacy digest under the current GPK. The public SDK (`fridayback/contracts-sdk`, last commit **2026-05-28**, pre-exploit) *still* computes exactly that legacy digest in `TreasuryScript.caculateRedeemDataHash`. If any operator/client ever signs a withdrawal with that code — even if the transaction then fails against the V3 script — the signature is in the mempool and can be lifted into an old-script spend.
- A future migration that leaves the legacy check scripts armed and the signing flow unchanged re-opens the same class.

**Costs:** forging is not a gas/capital problem — it is a signature-availability problem. There is no legacy signature in circulation today.

**Reinterpretation attack considered and rejected.** One might try to make a *V3-signed* message verify under the old script by choosing legacy fields whose raw concatenation equals `serialiseData(Constr 0 [signed fields])`. The preimage would have to start with the CBOR header `d8798d581c…`, but the legacy encoding's first 28 bytes are `toPkhPay`, which the V2 script forces into `PubKeyHash toPkhPay` for the payout (`valuePaidTo'`). The attacker would therefore need a signing key whose blake2b-224 hash equals those exact 28 bytes (2^224), and could not receive the funds otherwise. The path is not viable.

---

## 5. PoC / verification

Files: `poc/poc_encoding.py` (collision + real ECDSA verification), `poc/scan_scripts.py` (on-chain fetch + UPLC disassembly + builtin inventory), `poc/live_state.py` (balances/GroupInfo/TCheckCoin).

- **Real signature verified.** The on-chain exploit signature `322c4b49…d839` verifies against `sha3_256(b8a103c0126a10 …)` under `0335664e…` (exploit GPK) and fails under `022af717…` (current GPK). The compatible smaller tuple produces the identical 170-byte preimage, so the same signature authorises the 203M-NIGHT withdrawal.
- **Encoding separation.** Replacement serialisation gives distinct digests for the two tuples (`0926fd4a…` vs `97f57589…`).
- **Bytecode inventory** (CI): old `485aa1` — `AppendByteString`=1, `SerialiseData`=1, `Sha3_256`=1; new `8c02` — `AppendByteString`=**0**, `SerialiseData`≥1, `Sha3_256`=1, verify builtins=1 each; parameter block carries the three NFT policies and the treasury hash.
- **Live state** (CI): treasury 218,156.077399 ADA / 11,837,345.212388 NIGHT / 306 UTxOs; 14 `TCheckCoin` at the new script, 14 at the old.
- CI run: see §8.

The V3 script's own digest was **not** byte-reproduced for the Oct 10 withdrawals (the exact Aiken field wrapping differs from our reconstruction); that does not affect the verdict, which rests on the builtin inventory (no `AppendByteString`), the parameter block, and the verified rotation on the V2 side.

---

## 6. Verdict and residual risk

**Verdict: CLOSED for live unprivileged extraction ($0).** The replacement check script eliminates the non-injective construction (structured CBOR serialisation, zero raw concatenation), the signing key was rotated, and the vulnerable path has been dormant since the day after the exploit.

**Residual / latent (material):**
- **49 `TCheckCoin` remain parked on 5 superseded check scripts.** The exploited V2 script (`485aa1`, source-verified) is **not self-disabling**: it reads the current NFT-authenticated `GroupInfo` and verifies against the current GPK, and it never compares `GroupInfo[TreasuryCheckVH]` with its own hash. Its security now rests entirely on the absence of legacy-format signatures under the current GPK. **Trigger resolved: 52/52 storeman signatures since the V3 migration (49 treasury + 3 mint-check; 24/24 after the current-key rotation) are V3 `serialiseData`, 0 legacy, 0 spends on `485aa1` — see `TRIGGER-ANALYSIS.md`. The trigger is (b) signer-side only, not attacker-inducible; a single legacy signature (stale SDK, retry tool, operator error) would still drain the signed asset's entire treasury balance — NIGHT ≈ $502k — within its ~9-minute TTL window.**
- Recommended fix for the operator: burn/migrate the stale `TCheckCoin` UTxOs, and add a `TreasuryCheckVH == own hash` check to any future check-script version.
- The treasury is controlled by a 17-of-25 storeman threshold; quorum compromise is the dominant systemic risk, outside this bug.
- The 49 stale check UTxOs carry ~59.8 ADA (~$11.4) of dust. It is unrecoverable without a storeman signature (`S`, immaterial and excluded from the $0 E-U headline).

---

## 7. Methodology, sources, limitations

**Sources:** Koios REST (`script_info`, `address_utxos`, `address_txs`, `tx_info`, `asset_addresses`, `asset_info`), CoinGecko, BlockSec Phalcon, DarkNavy `web3-exploit-analysis` (recovered Haskell source + exploit artifacts), `fridayback/contracts-sdk` (off-chain signer), Cexplorer. All balances re-read 2026-11-03 at tip 14,152,985; fixtures in `analysis/`.

**Tooling:** `uplc` (Python) disassembly of the deployed CBOR; builtin/trace extraction; a Plutus `Data`→CBOR encoder for the injectivity check; `ecdsa` verification of the real on-chain signature; `packInteger` decoded from the deployed V2 bytecode and confirmed against source.

**Limitations:**
1. No Cardano node or Plutus CEK evaluator; no transaction was simulated on-chain. The V3 digest for the Oct 10 withdrawals was not reproduced byte-for-byte (see §5).
2. The V2 `485aa1` source is a recovered candidate from the DarkNavy artifact, but it matches the deployed bytecode's trace/builtin inventory exactly (`treasurySpendCheckA`, `packInteger`, `AppendByteString`, `getGroupInfo`), and its reconstructed digest verifies the real on-chain signature — so the match is high-confidence.
3. `TCheckCoin` holder set comes from `asset_addresses` (6 addresses, supply 63, consistent with UTxO counts).
4. USD uses CoinGecko at 2026-11-03; CNTs other than NIGHT are unpriced.
5. The `GroupInfo` parameter list grew from 12 to 19 slots (7 empty); the new layout was mapped only by slot position (GPK=2, TreasuryCheckVH=4, StkVh=7, matching the SDK's `GroupNFT` enum).

---

## 8. Files / CI

```
ca2-open-wanchain/
├── README.md
├── TRIGGER-ANALYSIS.md   rotation block, post-rotation signature census, inducibility verdict
├── summary.json
├── analysis/      on-chain fixtures + recovered Haskell source + UPLC dumps + SDK excerpts
├── poc/           poc_encoding.py, scan_scripts.py, live_state.py
├── ci/run.sh      heavy job (UPLC disassembly + live state + PoC)
├── ci-out/        machine-readable results
└── ci-log.txt / ci-artifacts/
```

CI: `bash /home/heisenberg/CA/ci/ci-run.sh ca2-open-wanchain` → `artsbykriss/ca-zombie-ci`, workflow `poc.yml`. Run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41659282008** (success). The custom job disassembled all four scripts from their on-chain CBOR with `uplc` (2 s / 40 s / 2 s / 23 s) and returned 7/7 structural checks true — notably `replacement_has_no_raw_concat`, `replacement_serialises_message`, `replacement_param_block_ok`, `exploited_uses_raw_concat`.
