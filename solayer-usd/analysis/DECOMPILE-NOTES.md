# Reverse-engineering notes — Solayer `usdc-pool-program`

## 1. Identifying the target

DefiLlama's `solayer-usd` entry has `address = LAYER4xPpTCb3QL8S9u41EAhAX7mhBn8Q6xMTwY2Yzc`, which is the
**LAYER governance mint** (decimals 9, Metaplex metadata name "Solayer"), *not* sUSD and *not* a program.
The adapter `projects/solayer-susd/index.js` sums two tokens owned by
`FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG`. `getProgramAccounts` on the Token / Token-2022 programs
with `memcmp(offset=32, bytes=FhVcY…)` shows that account owns:

* USDC `DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ` (708,102.87 USDC)
* sUSD `FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds` (20,671,325 raw, withdraw escrow)
* sUSD reserve `93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK` (3,707,526 raw)
* cUSDO vaults `cusdzR5s…`, `2pR6cGbr…` (both 0 — redeemed)
* other token vaults (4MmJVdw…, BKMp8wXf…pump — dust/spam)

`FhVcY…` is owned by program `s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA` (BPFLoaderUpgradeable).

## 2. Recovering the interface

* `getProgramAccounts(PROG)` returns 33 accounts. Grouping by the first 8 bytes (Anchor discriminator) and
  matching `sha256("account:<Name>")[:8]` yields: `Pool` (379B), `DepositProof` (621B, ×21), `WithdrawProof`
  (621B, ×3), `MigratedDepositProof` (137B, ×2), `OpenedenInfo` (409B), `SunsetInfo` (42B),
  `SusdSupplyOffset` (16B). One discriminator (`184662bf3a907b9e`) is **not** in the IDL name set.
* That unknown account (`3wgB6vYowPy9PeqmZeFBM3o5R5zHGSmNamViuLrGxGeo`, 2397B) is
  `disc(8) + inner_pubkey(32) + u32_len(4) + zlib(data)`. Decompressing yields an 18,628-byte JSON —
  **the program's Anchor IDL** (`{"version":"0.1.0","name":"usdc_pool_program",…}`). Saved as `idl.json`.
  The 4340-byte account `BSWq7LBr…` holds the same IDL (a buffer).
* `strings solayer_susd.so` gives the instruction log names and the source paths
  (`programs/usdc-pool-program/src/contexts/*.rs`), the full error list, and the account/constraint names.
* Instruction discriminators = `sha256("global:<snake_case>")[:8]` (see `discriminators.json`).
  The three `sunset_*` instructions are **not** in the on-chain IDL; their discriminators were taken from
  real tx data: `sunset_redeem_all 40a1f4cc25a8add9`, `sunset_finalize affb14ab86af289c`,
  `sunset_initiate_batch_withdraw 8cd5c5f227c853a8`.
* `getSignaturesForAddress(PROG)` + `getTransaction` → `Program log: Instruction: X` gives real account
  layouts for `deposit`, `withdraw`, `initiate_batch_withdraw`, `resolve_batch_withdraw`, `collect_fee`,
  `update_susd_rate`, `sunset_redeem_all`, `sunset_finalize`.

## 3. `Pool` layout (379 bytes, verified end-to-end)

```
disc f19a6d0411b16dbc
u8   bump
pk   manager                 = 7671j7qp… (Squads vault)
pk   operator                = AxnDY6nekRa4hEY1rm1g11A51EPPU29iAXXxh8vAqpM8
pk   rateAuthority           = uRwMu2114gN23NZVFxkjM6Dwk1iqSc1LLQsHMmiT6Lr
u64  fee.numerator  = 5
u64  fee.denominator= 1000
pk   fee.recipient           = 3NC1UF4pus6ditVzbcJCLFCVyBLVJm2kxKMhb3mPAoaz
i64  poolCreationTimestampSeconds
i64  lastFeeCollectionTimestampSeconds
pk   usdcMint                = EPjFWdd5…
pk   poolUsdcMainVault       = DN2KzAei…
pk   susdMint                = susdabGD…
pk   poolSusdVault           = FfELPrBp…
u8   batchDepositStatus      = 2      (deployed code has ≥3 variants; IDL shows only 2)
u64  currentDepositId / currentDepositUsdcAmount / batchDepositRemainingUsdcAmount
u8   batchWithdrawStatus     = 1
u64  currentWithdrawId / currentWithdrawSusdAmount / batchWithdrawRemainingSusdAmount
pk   openedenInfo            = 9HhZLsdF…
```

## 4. Why there is no unprivileged extraction

* `deposit` (the free-mint path) reverts `DepositClosed (6039)` — the pool is sunsetting.
* `withdraw` only escrows the caller's own sUSD into `poolSusdVault`; **no USDC moves**. The proof PDA is
  seed-bound to `["withdraw_proof", pool, signer, nonce]`, so proofs cannot be reused/forged, and the
  escrowed token account must be owned by the signer (`ConstraintTokenOwner`).
* Every USDC-moving instruction (`initiate/resolve_batch_*`, `collect_fee`, `emergency_transfer_rwa_token`,
  `sunset_finalize`) requires the operator/manager signer and is protected by Anchor `has_one`
  (`ConstraintHasOne 2001` for a foreign signer).
* `claim_with_migrated_deposit_proof` requires both `user_susd_vault` = the proof's vault (`ConstraintRaw 2003`)
  and ownership by `proof.from` (`ConstraintTokenOwner 2015`).
* `handle_frozen_accounts` reverts `InvalidStatus (6026)` in the current batch state.

## 5. Reproduce

```
python3 analysis/recon1c.py        # account inventory
python3 analysis/recon4.py         # instruction histogram + real layouts
python3 analysis/idl_find.py       # (also) confirms no separate IDL account
python3 analysis/decompress_blob.py# -> idl.json
python3 analysis/decode_pool.py    # -> pool_decoded.json
python3 analysis/battery_local.py analysis/battery2.py analysis/battery3.py analysis/battery4.py analysis/battery5b.py
python3 analysis/final_state.py    # -> final_state.json
bash ci/run.sh                     # full matrix (CI)
```
