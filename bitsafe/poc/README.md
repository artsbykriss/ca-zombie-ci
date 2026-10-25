# `poc/` — not applicable (no EVM/Foundry proof)

BitSafe **CBTC is not an EVM protocol**. It is a Canton-Network wrapped-BTC
whose Bitcoin-side custody is a set of Taproot (P2TR) outputs on Bitcoin L1,
spendable only through a FROST threshold script leaf. There is no Solidity
target, so a Foundry `forge test` PoC does not apply and none is provided.

The equivalent "proof" for this target is a **read-only on-chain verification**,
which lives in `../analysis/` and is executed in CI (`../ci/run.sh`):

- `../analysis/ec.py` — dependency-free secp256k1 (BIP32 + BIP341 taproot).
- `../analysis/verify_derivation.py` — independently re-derives **all 728**
  deposit addresses from the published threshold xpub + deposit ids and asserts
  they equal the operator-reported ones (`MATCH 728/728`).
- `../analysis/scan.py` — reads every address's balance and spend history from a
  keyless public Esplora endpoint, decodes every spend witness, and asserts that
  (a) every spend is a **script-path** spend of the constant
  `<group_key> OP_CHECKSIG` leaf, and (b) every control-block internal key equals
  the independently-derived **BIP-341 NUMS** (unspendable) key for that deposit id.

No transaction was ever signed or broadcast; the whole job is read-only.
