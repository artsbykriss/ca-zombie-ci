# BitSafe CBTC — mechanism, derivation and authorization (evidence notes)

## 1. Identity

* `bitsafe.finance` → "BitSafe builds institutional assets and infrastructure on **Canton Network**.
  Home of **CBTC** and the open-source Decentralization Manager." Operated by **DLC-Link, Inc. dba
  BitSafe**.
* This is the **Canton-Network** CBTC (successor to DLC.Link's `dLCBTC`/`IBTC`), **not** the BitGo/Canton
  "CBTC" and **not** an EVM asset.
* DefiLlama: slug `bitsafe-cbtc`, category `Decentralized BTC`, chain `Bitcoin`, TVL ≈ $3.29M.
  Adapter chain: `registries/bitcoin.js` → `projects/helper/bitcoin-book/fetchers.js` (`bitsafeCBTC`).

## 2. Reserve address feed (operator API, public)

```
GET https://api.mainnet.bitsafe.finance/cbtc/v1/address-calculation-data
{ "status":"ready", "bitcoin_network":"bitcoin",
  "chains":[ { "chain":"canton-mainnet",
               "xpub":"xpub6GRcASRzGcNLhsaTsX28aV1JmNZSdUFKHsXgSjwX4ykk8X3j58gznGf73mBe1k35A69K7JNZfwZhmQHjZGd8f5ine2ztkbW3yiayRHFRFKL",
               "addresses":[ {"id":"<138-hex deposit-account id>","address_for_verification":"bc1p…"}, … ] } ] }
```
728 addresses, all `bc1p…` (P2TR), one chain group. (One account has `id == "change"` — the
consolidation account `bc1ppp6ft…`.)

Other endpoints seen: `/cbtc/v1/bitcoin-address/{account_id}`, `/cbtc/v1/account-contract-rules`,
`/cbtc/v1/token-standard-contracts`.

`GET /cbtc/v1/bitcoin-address/test` returns
`{"bitcoin_address":"bc1p5suevq5ggv9q9t43l999kexmyq4rl22ddn0g0796kya6ncsq7n3q0xns2t","attestors_requested":4,"attestors_responded":3}`
— the address is exactly the derivation for `id="test"` (verified locally), and it exposes the live
**3-of-4** attestor threshold.

## 3. Bitcoin custody construction (from DLC-link/cbtc-por-tools, re-implemented)

For deposit account `id`:
```
cc            = SHA256(utf8(id))
internal_key  = BIP32_ckd_pub( NUMS_H , cc ) at m/0/0      # NUMS_H = BIP341 H, no known dlog
leaf_script   = <xonly(FROST_group_key)> OP_CHECKSIG        # 0x20||32B||0xac
leaf_hash     = TaggedHash("TapLeaf", 0xc0 || 0x22 || leaf_script)
t             = TaggedHash("TapTweak", internal_key || leaf_hash)
Q             = lift_x(internal_key) + t*G                  # P2TR output key
address       = bech32m("bc", 1, Q)
```
* `NUMS_H = 0250929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0`
  (= x-only `50929b74…803ac0`), the **BIP-341 NUMS key H** used as `BIP341_NUMS_KEY` in BIP-443,
  Blockstream Simplicity, bdk-cli, etc. — provably unspendable.
* Group key (from the published xpub's pubkey, x-only):
  `2b26a99ecaf2b616e60efa01c3036c55417b0700972575ca5ccd948e05a13332`.
* **Spend paths:** key path = `d(NUMS-derived) + t` (unknown, unspendable); script path = a Schnorr
  signature for the group key. **No other leaf, no hashlock/timelock/keyless condition.**

`analysis/verify_derivation.py` reproduces all 728 reported addresses exactly (`MATCH 728/728`) and the
live `test` address, using only the public xpub + deposit ids.

## 4. On-chain spend census

Every historical spend of a reserve address observed is a **script-path** spend:
`witness = [64-byte Schnorr sig, 202b26a9…ac, c0||internal_key]`, with `internal_key` equal to the
NUMS-derived key for that address. No key-path spend was seen. Example:
tx `148fb29e7416747c909c20442c2f522be7e332b01d258836eb4e36b526fb84b1` (spends `bc1ppp6ft…`):
witness `[e0fa52d9…, 202b26a9…ac, c0272e40…16ab7]`, internal key `272e40c3…16ab7`.

## 5. Canton Daml authorization (from the public `cbtc-1.2.1.dar`)

Source files (copied to `daml-source/`): `CBTC/DepositAccount.daml`, `CBTC/WithdrawAccount.daml`,
`CBTC/WithdrawRequest.daml`, `CBTC/Credentials.daml`, `Common/Common.daml`.

* `CBTCDepositAccount` — signatory `registrar, owner`.
  * `CBTCDepositAccount_CompleteDeposit` — **controller `registrar`**; requires Minter credential,
    positive amount, limits, `bitcoinBlock > lastProcessedBitcoinBlock`; mints via
    `BurnMintFactory_BurnMint` with `expectedAdmin = registrar`. ⇒ **mint is registrar-only.**
* `CBTCDepositAccountRules_CreateDepositAccount` — controller `owner`, requires registrar-issued
  `hasCBTCRole: Minter` credential. ⇒ onboarding is permissioned.
* `CBTCWithdrawAccount` — signatory `registrar, owner`.
  * `CBTCWithdrawAccount_Withdraw` — **controller `owner`**; checks each holding's `owner == owner`,
    correct instrument, not locked; burns them and adds to `pendingBalance`. ⇒ **burn is owner-only.**
  * `CBTCWithdrawAccount_UpdateDestinationAddress` — controller `owner`.
  * `CBTCWithdrawAccount_CreateWithdrawRequest` — **controller `registrar`** (records `btcTxId`).
* `CBTCWithdrawRequest` — signatory `registrar, owner`; `CompleteWithdrawal` controller `registrar`.
* `CBTC.Credentials.getCBTCOperationRequirements registrar = [issuer=registrar, claims=[("hasCBTCRole","Minter")]]`
  — required for account creation, deposit and withdraw.

⇒ No unprivileged path to mint, to burn another party's CBTC, to move BTC, or to redirect a withdrawal.

## 6. Audits & PoR

* Quantstamp audit of CBTC Daml (2025-10-13…17): **0 High**, 2 Medium (CBTC-1 Withdraw Amount May Change
  During Confirmation Process [Fixed]; CBTC-2 Transaction Order Dependence [Mitigated]), 4 Low
  (CBTC-3…CBTC-6, Fixed/Mitigated). Governance threshold invariant: `>= floor(n/2)+1`.
* Chainlink CBTC PoR Data Stream: AUM **40.8028 BTC**, NAV 2026-10-25 20:04 UTC.
* DefiLlama TVL 2026-10-25: **$3,286,340**.

## 7. Residual (P-class) risks, not E-U

* **3-of-4 threshold** with BitSafe operating 1 of 4 ⇒ BitSafe + 2 external operators (or 3 externals)
  can move the entire reserve. Docs are inconsistent ("7-of-10", "9 external + 1 BitSafe",
  "3 external + 1 BitSafe").
* One group key across all 728 addresses ⇒ no per-account isolation.
* PoR completeness is trust-based (deposit-id list is operator-published).
* Off-chain FROST coordinator / attestor software not auditable from outside.
