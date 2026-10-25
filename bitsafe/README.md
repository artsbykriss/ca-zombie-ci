# BitSafe CBTC (Canton) — live extractability of the Bitcoin reserve

**Date:** 2026-10-25 · **Chains:** Bitcoin (L1 custody) + Canton Network (token/mint/burn, private)
· **Status:** read-only research; **no transaction was ever signed or broadcast**; PoC is a
read-only on-chain verification (no EVM contract exists to fork). This folder is self-contained.

**Target (verified identity):** this is the **Canton-Network** CBTC issued by **DLC-Link, Inc. dba BitSafe**
(`bitsafe.finance`), *not* the Canton/BitGo "CBTC" and *not* the EVM `dLCBTC`/`IBTC` products.
DefiLlama slug `bitsafe-cbtc`, category "Decentralized BTC", chain `Bitcoin`, TVL ≈ **$3.29M**.

---

## 1. TL;DR

| Layer | Live extractable by an external, unprivileged attacker | Why open / closed |
|---|---|---|
| **Bitcoin L1 reserve custody** (728 P2TR outputs, ~40.8 BTC) | **$0** | **CLOSED, code-clear.** Every output is a Taproot output whose key path is the **BIP-341 NUMS key H** (provably unspendable) and whose only script leaf is `<FROST-group-key> OP_CHECKSIG`. Spending requires a Schnorr signature from the FROST group key — no keyless branch, no hashlock, no timelock, no anyone-can-spend leaf. |
| **Canton token / mint / burn / withdrawal** | **$0** | **CLOSED by construction (and tooling-blocked).** The Daml source (shipped in the public `cbtc-1.2.1.dar`) shows mint = **registrar-only** (`CompleteDeposit`, controller `registrar`), burn/withdraw = **owner-only** (`Withdraw`, controller `owner`), BTC-tx recording = registrar-only, and **every** operation additionally requires a registrar-issued `hasCBTCRole: Minter` credential. The ledger is private, so it is also unobservable. |
| **Off-chain coordinator / custody operations** | unknown | **Tooling-blocked:** the FROST coordinator, attestor signing software and any off-chain custody books are not observable on-chain. |

**Total live extractable now (E-U): $0. Confidence: HIGH** for the Bitcoin L1 custody (cryptographically
closed, independently reproduced) and for the Daml authorization model (source-read). **MEDIUM** for the
"nothing else exists" claim, because the Canton-side state and off-chain operations are unobservable.

The reserve itself is real and large — **≈40.8 BTC ≈ $3.29M** held at the 728 derived addresses (matches
Chainlink PoR `40.8028 BTC` and DefiLlama `$3,286,340`). The honest headline is $0 because that value is
**not** behind any unprivileged path: it is behind a threshold signature and a permissioned Canton
workflow. The residual risk is **P-class trust**, not E-U (see §8).

---

## 2. What BitSafe CBTC actually is (verified)

BitSafe CBTC is **not** a Bitcoin-script-native, ordinal/Runes, or EVM protocol. It is a **wrapped-BTC
asset on the Canton Network** with **FROST threshold custody on Bitcoin L1**:

* **Bitcoin side.** Each Canton *deposit account* maps deterministically to a unique **P2TR** address.
  The reserve is held as UTXOs at these addresses. Spending requires a **single aggregated Schnorr
  signature** from the FROST threshold group key (Taproot script-path).
* **Canton side.** CBTC is a **CIP-56 / Canton Token Standard** instrument issued by a decentralized
  **registrar** party (`cbtc-network::12205af3…`) with a `BurnMintFactory` and `InstrumentConfiguration`.
  Deposits mint CBTC; burns request BTC withdrawals. Mint/burn are Daml choices governed by a threshold
  of Attestors (the `CBTCGovernanceRules`).

### 2.1 The exact Bitcoin custody construction (read from the public tooling + on-chain)

Source of truth: `DLC-link/cbtc-por-tools/calculate-bitcoin-addresses.ts` (verified at commit
`90496260…`, referenced by BitSafe's own PoR docs) and `DLC-link/cbtc-lib` (Rust). For each deposit
account with identifier `id`:

```
internal_key   = BIP32_ckd_pub( BIP341_NUMS_H , chaincode = SHA256(id) ) at m/0/0   # unspendable
script_leaf    = <xonly(FROST_group_key)> OP_CHECKSIG                               # threshold spend
output_key Q   = taproot_tweak(internal_key, TapLeaf(0xc0, script_leaf))
address        = bech32m(1, Q)                        # bc1p…
```

* `BIP341_NUMS_H = 0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0` — the
  **BIP-341 NUMS key H**, "provably unspendable" with no known discrete log (confirmed as
  `BIP341_NUMS_KEY` in BIP-443 / Blockstream Simplicity / bdk-cli references). The per-account internal
  key is a **non-hardened BIP32 child** of H, so its discrete log is also unknown ⇒ **the key path is
  unspendable for every reserve address**.
* The **only** spend path is the script leaf, requiring a valid Schnorr signature for the **FROST group
  key**. That key is published (as the xpub's public key) but its private key is not — and it is a
  *threshold* key, never assembled in one place.

The published threshold xpub is:
```
xpub6GRcASRzGcNLhsaTsX28aV1JmNZSdUFKHsXgSjwX4ykk8X3j58gznGf73mBe1k35A69K7JNZfwZhmQHjZGd8f5ine2ztkbW3yiayRHFRFKL
  pubkey (x-only) = 2b26a99ecaf2b616e60efa01c3036c55417b0700972575ca5ccd948e05a13332   <-- the CHECKSIG key
tapscript leaf    = 202b26a99ecaf2b616e60efa01c3036c55417b0700972575ca5ccd948e05a13332ac
```

> Note: the published xpub **is** the threshold group key used in the tapscript leaf. Publishing it is
> safe (a public key cannot sign) but it does let anyone enumerate every deposit address — a privacy
> note, not an extraction path.

### 2.2 Independent reproduction (the core proof)

`analysis/verify_derivation.py` re-implements the algorithm from scratch (dependency-free secp256k1,
`analysis/ec.py`) and **re-derives every address from the published xpub + deposit ids**, asserting it
equals the operator-reported `address_for_verification`. Result: **MATCH 728/728** (run in CI, see §7).
The operator therefore cannot hide or add reserve addresses for the *listed* deposit ids; the address
set is a deterministic function of the public inputs.

---

## 3. Live-state assessment (checkpoint)

* **Bitcoin checkpoint height:** `<BLOCK_HEIGHT>` (see `ci-out/summary.json`).
* **Deposit accounts / reserve addresses:** **728** (all `bc1p…` P2TR), one Canton chain group
  (`canton-mainnet`), one threshold xpub.
* **Independently reproduced addresses:** **728 / 728**.
* **Reserve total:** **`<RESERVE_BTC>` BTC ≈ $`<RESERVE_USD>`** (6-confirmation UTXOs, read from public
  Esplora). Cross-checks: Chainlink PoR **40.8028 BTC** (NAV 2026-10-25 20:04 UTC); DefiLlama
  **$3,286,340** (2026-10-25). BTC/USD `$<BTC_PRICE>` (DefiLlama `coins.llama.fi`).
* **Spend-witness census:** every historical spend of any reserve address is a **script-path** spend of
  the constant leaf above (`<SPEND_TOTAL>` spends inspected: `<SPEND_SCRIPT>` script-path, 0 key-path,
  0 unexpected leaf); and every control-block internal key equals the independently-derived NUMS key
  (`<INTERNAL_OK>`/`<SPEND_TOTAL>` match). See `ci-out/spends.csv`, `ci-out/scripts.json`.
* **Example evidence tx** (consolidation/withdrawal of the largest address `bc1ppp6ft…`):
  `148fb29e7416747c909c20442c2f522be7e332b01d258836eb4e36b526fb84b1` — witness =
  `[64-byte Schnorr sig, 202b26a9…ac, c0272e40…]` ⇒ script-path `<groupkey> CHECKSIG`, control block
  internal key `272e40c3…16ab7` = the NUMS-derived key. No key-path spend observed anywhere.
* **Canton contracts (from the operator API + public DAR):** registrar party
  `cbtc-network::12205af3b949a04776fc48cdcc05a060f6bda2e470632935f375d1049a8546a3b262`; instrument
  `CBTC`; `BurnMintFactory`, `InstrumentConfiguration`, `IssuerCredential` contract ids published at
  `api.mainnet.bitsafe.finance/cbtc/v1/token-standard-contracts`. All CBTC operations require a
  registrar-issued `hasCBTCRole: Minter` credential.
* **Observed threshold config:** `GET /cbtc/v1/bitcoin-address/test` returns
  `{"attestors_requested":4,"attestors_responded":3}` ⇒ the live FROST threshold is **3-of-4**, and the
  Quantstamp audit states the governance threshold is `floor(n/2)+1` (≥3 for n=4).

---

## 4. What an attacker can and cannot do

**Cannot (all verified):**
* **Spend reserve BTC via the key path** — the internal key is a NUMS-derived child with no known
  discrete log (BIP-341 H). Confirmed by 728/728 reproduction and by the fact that no historical spend
  uses the key path.
* **Spend reserve BTC via the script path** — requires a Schnorr signature for the FROST group key; no
  hashlock/timelock/`OP_TRUE`/constant-push leaf exists (all observed leaves are exactly
  `<groupkey> OP_CHECKSIG`).
* **Mint CBTC without a real deposit** — `CBTCDepositAccount_CompleteDeposit` is `controller registrar`
  and requires the registrar's authority plus a Minter credential; the `BurnMintFactory_BurnMint` choice
  is admin-gated (`expectedAdmin = registrar`).
* **Burn/move someone else's CBTC** — `CBTCWithdrawAccount_Withdraw` checks `holdingView.owner == owner`
  and correct instrument and unlocked; controller is `owner`.
* **Redirect a withdrawal to yourself** — the destination is `controller owner` on the owner's own
  account; the BTC tx id is recorded by the registrar.
* **Obtain a Minter credential** — issued by the registrar party (permissioned onboarding).

**Can (holder-only, H-O — not E-U):**
* A CBTC holder can burn their own tokens and request BTC to their own chosen address
  (`Withdraw` → `CreateWithdrawRequest` → FROST-signed BTC tx). That is self-service redemption of
  *their own* funds, gated by the threshold, not an external extraction.

**Capital/cost notes:** no path exists that requires capital, so gas/flash-loan economics do not apply.
The only "cost" of the non-existent key path would be forging a Schnorr signature (2^128-class work).

---

## 5. Tooling limits (first-class deliverable)

| Question | Tool used | Result / limit |
|---|---|---|
| Reserve addresses + balances | `api.mainnet.bitsafe.finance/cbtc/v1/address-calculation-data`, then `mempool.space`/`blockstream.info` Esplora | **Fully readable.** 728 addresses enumerated, balances summed, all UTXOs visible. |
| Spend conditions of reserve outputs | Esplora `/tx/{txid}` witness decode | **Readable for spent addresses** (all script-path, leaf + internal key verified). **Unreadable for never-spent addresses** — the tapscript tree is hidden on-chain until spent — **but derivable** from the public algorithm, which reproduces all 728 outputs exactly. |
| Canton-side state (holdings, deposit/withdraw accounts, mint history) | Canton is a **private** ledger; sub-transaction privacy limits visibility to entitled parties. Public explorers (`cantonscan.com`) show network/validator/Canton-Coin activity, not CBTC contract state. | **Unobservable.** Cannot enumerate CBTC holders, pending withdrawals, or verify the 1:1 liability side. |
| Canton contract *logic* | Public `cbtc-1.2.1.dar` (Daml source shipped in the DAR) + Quantstamp audit | **Readable.** Authorization model confirmed (see §2/§4). `CBTCGovernanceRules` itself is a separate package (not in this DAR) — its threshold logic is only known from the audit description. |
| Off-chain coordinator / attestor software / custody books | none (no public artefact) | **Unobservable.** FROST signing software, key lifecycle, and any manual custody steps cannot be audited from outside. |
| Liability completeness (is every deposit account published?) | `cbtc-por-tools` + BitSafe docs | **Trust-limited by design.** The PoR proves BTC at the *listed* accounts; it does **not** prove the deposit-id list is complete (BitSafe's own docs state this). A dishonest operator could omit accounts. This is a *hiding/liability* risk, not an extraction path. |

---

## 6. Why this is $0 and not a missed bug

1. The Bitcoin custody is a textbook **Taproot script-path-only threshold** construction: NUMS internal
   key (unspendable key path) + a single `<threshold-key> OP_CHECKSIG` leaf. There is no second leaf, no
   fallback, and no keyless condition. I checked this **empirically** on every historical spend of every
   reserve address, not just on the documented algorithm.
2. The address derivation is deterministic and publicly reproducible (728/728), so no address can be
   "secretly" of a different (weaker) form.
3. The Canton authorization is source-verified: mint is registrar-only, burn is owner-only, all
   credentialed. Even in the worst case (a Daml logic bug), exploitation requires a Canton participant
   node and registrar-issued credentials on a private ledger — outside the "external unprivileged"
   model, and unobservable to us regardless.
4. No public incident, exploit, or open advisory for BitSafe CBTC was found (audit: 0 High, all findings
   fixed/mitigated; DLC-link repos have no CBTC security advisory).

---

## 7. Verification / CI

All heavy work ran on GitHub Actions (public repo `artsbykriss/ca-zombie-ci`); local work was limited to
light RPC reads. Files: `analysis/ec.py`, `analysis/verify_derivation.py`, `analysis/scan.py`,
`ci/run.sh`; results in `ci-out/`.

* **CI run:** `<CI_RUN_URL>`
* **`analysis/verify_derivation.py`** → `MATCH 728/728` (see `ci-out/derive.log`).
* **`analysis/scan.py`** → reserve sum + full spend-witness census (`ci-out/summary.json`,
  `balances.csv`, `spends.csv`, `scripts.json`).
* No Foundry PoC: there is no EVM target (see `poc/README.md`).

---

## 8. Verdict, residual & latent risk

* **E-U (external unprivileged extractable): $0. Confidence HIGH** (Bitcoin custody code-clear and
  independently reproduced; Daml authorization source-read).
* **H-O (holder-only recoverable):** the circulating CBTC held by credentialed holders can be redeemed
  1:1 for BTC through the threshold workflow — this is the intended self-service path, not extraction.
* **P (privileged):** the **entire ~40.8 BTC reserve is movable by the FROST threshold group**.
* **S (stuck):** none identified.

**Latent / trust risks (not E-U):**
1. **Low threshold (3-of-4).** The live config is 3-of-4 (and BitSafe operates 1 of the 4 attestors per
   its own docs). Marketing text elsewhere says "7-of-10" and "9 external + 1 BitSafe" — the docs are
   inconsistent. With 3-of-4, **BitSafe + any 2 external operators** (or any 3 externals) can move the
   whole reserve. The audit's `floor(n/2)+1` invariant makes 3 the minimum, so the threshold is at the
   floor. This is a material **centralization/collusion** exposure worth flagging.
2. **Single group key across all 728 addresses.** One key compromise drains the entire reserve at once
   (no per-account isolation).
3. **PoR completeness is trust-based.** The address set is derived from operator-published deposit ids;
   the PoR cannot prove no accounts were omitted.
4. **Off-chain coordinator.** FROST signing software and the transaction-construction service are not
   auditable from outside; a compromise there is the realistic path to the funds (still P-class).

---

## 9. Methodology & sources; caveats; files

**Method.** Identify the protocol (site/docs/GitHub), locate the DefiLlama adapter
(`DefiLlama-Adapters/registries/bitcoin.js` → `projects/helper/bitcoin-book/fetchers.js` key
`bitsafeCBTC` → `api.mainnet.bitsafe.finance/cbtc/v1/address-calculation-data`), read the open PoR tool
and Rust client, unzip the public `cbtc-1.2.1.dar` to read the Daml source, then independently
re-derive all 728 addresses and census every spend witness on Bitcoin L1. Read-only throughout.

**Sources.** `bitsafe.finance`; `docs.bitsafe.finance` (CBTC, Security, PoR, Architecture, Attestor/FROST);
`github.com/DLC-link/{cbtc-por-tools,cbtc-lib,bitsafe-token-lib}`; `cbtc-1.2.1.dar`; Quantstamp audit
(`certificate.quantstamp.com/full/cbtc/…`, Daml, Oct 2025); Chainlink CBTC PoR Data Stream
(`data.chain.link/streams/cbtc-por-nav-datalink`); DefiLlama (`api.llama.fi/protocol/bitsafe-cbtc`,
`coins.llama.fi`); `mempool.space` / `blockstream.info` Esplora; BIP-341/BIP-443 (NUMS key H).

**Caveats.**
* Canton-side state is private and unobservable; the Daml *logic* is source-read but the deployed
  package hash is assumed to match the public DAR (the on-chain package hash was not verified against
  the ledger, which we cannot query).
* Reserve total is a snapshot at the stated Bitcoin block; balances and BTC price drift.
* The PoR/liability completeness (1:1 vs circulating supply) is out of scope here and trust-based.
* The `CBTCGovernanceRules` threshold logic is known only from the audit summary, not from a public DAR.

**Files.**
```
README.md                       this report
summary.json                    machine-readable summary
analysis/ec.py                  dependency-free secp256k1 (BIP32 + BIP341)
analysis/verify_derivation.py   re-derives all 728 addresses (MATCH 728/728)
analysis/scan.py                reserve sum + spend-witness census
analysis/cbtc_addresses_api.json  operator address feed snapshot
analysis/cbtc_reserve_addresses.txt  728 addresses
analysis/example_spend_tx_3da59338.json, analysis/example_reserve_txs.json   sample evidence
poc/README.md                   why no EVM PoC
ci/run.sh, ci/README.md         heavy job
ci-out/                         CI results (summary.json, balances.csv, spends.csv, scripts.json, logs)
ci-log.txt, ci-artifacts/       CI log + downloaded artifacts
```
