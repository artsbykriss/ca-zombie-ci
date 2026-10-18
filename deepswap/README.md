# DeepSwap (Solana cp-swap fork) — Wave B1 deep-dive

**Date:** 2026-10-18 · **Chain:** Solana mainnet · **Status:** read-only; no transactions signed or sent; no keyed RPC URLs or secrets in this folder.
**Target:** DefiLlama “DeepSwap” ($78.7k) — program `HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP`, a fork of Raydium cp-swap. One live pool: `F3fSrURu58o7n5iNqGRyPgzZPo5VfMtVrWggMD2TeFdp` (WSOL/DEEP).

## TL;DR

| Item | Live value | Why |
|---|---:|---|
| **E-U (external unprivileged)** | **$0** | LP mint supply is **0** (all graduation LP was minted then burned); there is no LP to withdraw. `withdraw` requires the LP owner’s signature and LP tokens; `deposit`/`withdraw` round trips are value-neutral; swap math is the audited Raydium curve; fee-claim paths pay the fixed creator/protocol recipients. |
| **H-O (holder-only)** | **$4.76** | 0.046019147 SOL of accrued holder reward (`creator_fees_token_0`) is claimable via the deep-rewards holder vault — for DEEP holders, not an attacker. |
| **P (privileged)** | **$37,085.89** | The Squads multisig (`yYb55…`, threshold 2, 48 h timelock) can replace the program and recover/drain the pool’s 358.467893506 SOL. Not E-U. |
| **S (stuck)** | **$0 if the P key is live; ~$37.1k if it is lost** | The pool is a graduated pool with burned LP; without the upgrade key the SOL is permanently locked. |

**Headline: an external unprivileged attacker can extract $0 live. Confidence: high.** The $78.7k DefiLlama figure is a two-sided valuation; the hard asset is 358.47 SOL (~$37.1k), and it is locked by burned LP, not attacker-extractable.

## 1. Program identity and source

| Item | Value |
|---|---|
| Program ID | `HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP` |
| Program data account | `CiWMKfJDcZhGtaYx9kM1bZ3byrxDZVRZXKN5hd5oBuj8` (827,200 bytes; ELF 827,155 bytes) |
| ELF sha256 | `2c8251b92925ec7d5e3bf3d5bddcbd4aa297a6434537aeaf4bb3ecd77497359e` |
| Upgrade authority | `4vEQmhpGxVJNiLaYz16NVaYQqcp7GbZMwd5TR3cZtQqu` — System-Program-owned, space 0 (normal for a **Squads vault PDA**); controlled by Squads multisig `yYb55Wc4wE6jvjBMmWANKoFHMGs49seZ71GFetcXzWr` (threshold 2, `time_lock = 172,800 s = 48 h`; repo comment describes 2-of-3) |
| Source | `github.com/OxForged/deepswap`, commit `110d475` (2026-10-15); `programs/deep-amm` |
| Security text | “Fork of raydium-cp-swap (see NOTICE); the fork itself is not audited.” |
| Upstream | `raydium-io/raydium-cp-swap` commit `b3187ae` (2026-10-02), `programs/cp-swap` |

`SECURITY.md` claims the upgrade authority is “DEEP’s Squads multisig, with a 48-hour time lock on every upgrade.” This is **supported on-chain**: `4vEQ…` is a system-owned Squads vault PDA, and the multisig account `yYb55Wc4wE6jvjBMmWANKoFHMGs49seZ71GFetcXzWr` is owned by the Squads program (`SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf`, 231 bytes). Decoding its `Multisig` header gives `threshold = 2`, `time_lock = 0x0002a300 = 172,800 s = 48 h` (the repo comment describes a 2-of-3). Upgrades therefore require a 2-of-3 (repo) proposal plus 48 h; this is **P**, not E-U, and the key is not a raw single key.

## 2. Live pool state (exact)

Pool `F3fSrURu58o7n5iNqGRyPgzZPo5VfMtVrWggMD2TeFdp`, account size 637, read at Solana slot **458,340,992** (2026-10-18). Decoder: `analysis/decode_pool.py`; raw JSON: `analysis/pool_decoded.json`.

| Field | Value |
|---|---|
| `amm_config` | `8UY49GiUH4jR9RkUYTCHPpuKu5WQsFaf6KCTeUxQojoS` |
| `pool_creator` | `2Nk8Hx8hsXoSMhLPVPAiKg6Crn3zxjT83mxzKhZJnUrC` (deep-rewards holder vault for DEEP) |
| `token_0_mint` | `So11111111111111111111111111111111111111112` (WSOL, 9 dp) |
| `token_1_mint` | `DpyVL7crxmDAgKuCZ6heGVkPzGAWyx7fkRDRrASadeep` (DEEP, 6 dp) |
| `token_0_vault` | `F4dgCnntQ6pdCmNPAf7F8hB7qNFHueQ3thfyA3KGcrCy` — **358.467893506 SOL** |
| `token_1_vault` | `2cUjCeH5uzZGFnjBmnAE8mFP8GuqZEFFi3ZHvJ63zXCH` — **78,884,379.116951 DEEP** |
| `lp_mint` | `8biCLkwhPXfs2Wkw1NFAKjaVMGbFU1fdivdUeqEH5DyA` |
| LP mint supply | **0** (Tokenkeg mint, decimals 9; `getTokenSupply` = 0; 0 token accounts) |
| `lp_supply` in pool state | **5,312,897,514,527 raw = 5,312.897514527 LP** (stale phantom accounting) |
| `status` | 0 (deposit/swap/withdraw all enabled) |
| `fee_model` | 1 (DEEP V1 side-dependent fees) |
| `reward_model` | 2 (Holder) |
| `reward_rate_snapshot` | 10,000 (1%) |
| `creator_fee_on` | 1 (`OnlyToken0` = WSOL) |
| `creator_fees_token_0` | **46,019,147 lamports = 0.046019147 SOL** |
| `protocol_fees_token_0/1` | 0 / 0 |
| `fund_fees_token_0/1` | 0 / 0 |
| `lp_supply` vs actual | mismatch: 5,312.897 LP accounted, 0 LP minted |

### Why the LP is zero — intentional graduation burn

The pool was created by **deep-curve** (`7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA`) in tx `5joCMBhcAsEE3UM9kuPZCvVBCe2axKASdPwPT8XVhUjfMKrfKPRjWUZgiWvCS8hYByBWVPzgd9kHoj1yphjHVge4` (block time 1,791,803,513). The inner instructions include:

1. `transferChecked` 178.2 SOL + DEEP into the new vaults;
2. `mintTo` the pool LP;
3. `burn` the freshly minted LP;
4. `closeAccount` the temporary accounts.

The LP mint has only that one signature and no holders. This is the standard “burn the graduation LP” design: liquidity is locked forever by construction, and the pool remains swappable with no LP claimants. It is **not** a bug in the withdraw path.

## 3. Unprivileged-path checks

### 3.1 Withdraw — no LP to withdraw

`Withdraw` requires `owner: Signer`, `owner_lp_token` with `token::authority = owner`, and `owner_lp_token.amount >= lp_token_amount`. The LP mint supply is 0 and there are no LP token accounts, so no one — attacker or otherwise — can pass the LP balance check. The pool’s 358.47 SOL is not withdrawable via `withdraw`.

### 3.2 Deposit/withdraw round trip is value-neutral

A new depositor can mint LP (the mint authority is the pool authority PDA), but the pool state still uses the phantom `lp_supply = 5,312.897`. The program rounds deposit token amounts **up** and withdrawal amounts **down**. Simulating the exact formulas over the live reserves for LP sizes 1, 1e3, 1e6, 1e9, S/2, S, 2S and 10S produces `delta ≤ 0` in both tokens for every size; the full-size round trip returns exactly the deposit. There is no positive round-trip and no way to claim the phantom LP’s share. Evidence: `analysis/lp_roundtrip.py`, `analysis/lp_roundtrip.json`.

### 3.3 Swap math is the audited Raydium curve

- `src/curve/{calculator,fees,constant_product}.rs` are **not modified** from upstream (NOTICE §8).
- The new V1 math (`src/curve/v1.rs`) takes the fee off the input on a buy and off the curve output on a sell; `split_fee` sends LP+protocol+reward exactly to the unit; `new_*_vault_amount` exclude accrued fees, so the k-check is conservative.
- `swap_base_output` rejects `amount_out >= output_reserve` before the curve (`InsufficientVault`), closing upstream’s panic path.
- The pool’s only live pair is WSOL/DEEP; no callback/flash-swap path is exposed (`swap` has no callback; input must be transferred first).

### 3.4 Fee-claim paths pay fixed recipients

| Instruction | Who can call | Who is paid |
|---|---|---|
| `collect_creator_fee` | pool creator (signer) | creator |
| `collect_creator_fee_permissionless` | anyone | **creator** (constrained to `pool_state.pool_creator`); caller only pays ATA rent |
| `collect_protocol_fee` | `amm_config.protocol_owner` (locked to the deep-curve fee vault) | protocol owner |
| `collect_protocol_fee_to_vault` | anyone | **fixed** ATA of `FEE_VAULT`; sides that cannot receive are skipped |
| `collect_fund_fee` | builder only | builder |
| `collect_excess_lamports` | admin/collect wallet only | admin |

No path lets an unprivileged caller redirect creator/protocol/fund fees to itself. `collect_creator_fee_permissionless` is the only permissionless one, and its `creator` is constrained by `#[account(address = pool_state.load()?.pool_creator)]`; `creator_token_0/1` are `init_if_needed` ATAs of that creator.

### 3.5 Upgrade authority is the only way to move the locked SOL

The program is upgradeable. The Squads vault can deploy a new program that transfers the vaults’ tokens to any destination; the 48 h timelock applies. That is **P**, not E-U. If the multisig is lost/unavailable, the 358.47 SOL becomes **S**.

## 4. What an attacker can / cannot do

**Can:** swap WSOL↔DEEP through the pool (normal AMM; pays the 1% holder reward + config LP/protocol fees), deposit and mint new LP, withdraw the LP they just minted, trigger `collect_creator_fee_permissionless` (pays the holder vault), create a permissioned pool (if they have a Permission PDA).

**Cannot:** withdraw the existing 358.47 SOL (no LP), redirect creator fees, mint DEEP (mint authority null), upgrade the program, or claim another user’s rewards.

**Cost:** a swap/deposit is gas + capital; there is no positive net extraction. The only way to move the locked SOL is the P upgrade key.

## 5. PoC / verification

- Source-level review of `programs/deep-amm` (commit `110d475`), diffed against upstream `raydium-cp-swap` (`diff -rq`): the only modified instruction surfaces are the admin/creator-fee/V1 ones listed in `NOTICE`; `withdraw` differs only by the removed status check (withdrawals always enabled); `deposit` and legacy swap math are upstream.
- Live-state proof: LP mint supply 0, 0 LP token accounts, pool_state `lp_supply` 5,312.897 (phantom); vault balances 358.467893506 SOL + 78,884,379.116951 DEEP.
- Exact round-trip simulation: no positive delta (`analysis/lp_roundtrip.json`).
- CI: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39106723208** (success; `ci/check.py` re-reads the pool/LP/vault/authority facts and writes `ci-out/validation.json`).

## 6. Verdict

| Category | USD | Confidence | Basis |
|---|---:|---|---|
| **E-U** | **0** | **high** | LP supply 0; withdraw requires LP; fee paths pay fixed recipients; swap math upstream/V1-audited; no redirect |
| E-U-conditional | 0 | high | would require a new bug in the V1 fee math or a missing account constraint; none found |
| H-O | 4.76 | high | 0.046019147 SOL holder reward to the deep-rewards holder vault, claimable by DEEP holders |
| P | 37,085.89 | high | 358.467893506 SOL at $103.65 via the Squads multisig (threshold 2, 48 h timelock); not E-U |
| S | 0 (37,085.89 if the P key is lost) | medium | burned graduation LP; no unprivileged withdrawal |

**Residual / latent risk:** (a) the upgrade authority is a Squads multisig (threshold 2, 48 h timelock); the residual risk is multisig compromise/collusion, not an external attacker; (b) the stale `lp_supply` (5,312.897 vs 0 actual) is a permanent accounting artifact; a future program upgrade that reads it naively could mis-mint, but the current deposit/withdraw math is value-neutral; (c) DEEP is not tradable on Jupiter (`TOKEN_NOT_TRADABLE`) and has no external market, so the DEEP side of the $78.7k DL figure is not a real exit; (d) the 0.046 SOL creator fee is claimable only to the holder vault.

## 7. Methodology / sources / files

- Program account / programdata via `getAccountInfo`; ELF extracted at offset 45; source from `github.com/OxForged/deepswap` (commit `110d475`); upstream `raydium-io/raydium-cp-swap` (`b3187ae`).
- Pool decoded from the 637-byte `PoolState` account (`getProgramAccounts` filter: dataSize 637 + discriminator `f7ede3f5d7c3de46`).
- Vaults via `getTokenAccountBalance`; LP mint via `getAccountInfo`/`getTokenSupply`/`getProgramAccounts` (0 holders); creation tx via `getTransaction` (jsonParsed).
- Price: CoinGecko SOL $103.65; DEEP has no Jupiter route (`TOKEN_NOT_TRADABLE`), so no external DEEP price is used.
- Files: `analysis/deepswap.elf`, `deepswap_programdata.bin`, `pool_decoded.json`, `pool_decoded` source, `lp_mint.json`, `lp_holders.json`, `create_tx.json`, `lp_roundtrip.json`, `deepswap-src/`, `raydium-cp-swap/`.
- Slot: 458,340,992 (read time); point-in-time.
- Caveats: no local Solana validator fork; source review + live account proof + exact math simulation; DEEP nominal value is not realizable.
- Nothing here is an instruction to transact.
