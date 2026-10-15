# Phase Stake (YIELD) — on-chain state report

**Scope**: read-only mainnet analysis of the Phase Stake pool family (C2-41 Phase Stake deep-dive, subagent deliverable).
**Data collected**: 2026-10-15 ~13:00–14:10 UTC (chain time). All numbers are exact raw values from mainnet-beta RPC.
**RPC**: keyless public endpoints only — `https://api.mainnet-beta.solana.com` (deep history required), `https://solana-rpc.publicnode.com`, `https://solana.api.onfinality.io/public`. No keys, no signing, no writes outside `phase-stake/analysis/`.
**Methods used**: `getAccountInfo` (base64+jsonParsed), `getSignaturesForAddress` (paginated), `getTransaction` (jsonParsed, maxSupportedTransactionVersion 0), `getProgramAccounts` (dataSize+memcmp filters, dataSlice), `getTokenSupply`, `getEpochInfo`, `getBlockTime`. `getTokenLargestAccounts` could not be obtained (persistent HTTP 429 on mainnet-beta; "indexed requests require a personal token" on publicnode/onfinality) — full holder distribution was instead recovered with a **Token-program `getProgramAccounts`** query (see §1).

---

## 0. Executive summary — the "young pool" premise is an artifact; NAV is normal for its age

1. **The Phase YIELD pool is old, not young.** Created **2024-04-17 23:06:58 UTC** (slot 260,739,588; ~epoch 604) by `phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit`; the YIELD mint was created 2024-04-15 18:00:23 UTC. Age at collection: **910.66 days ≈ 2.493 years**.
2. **NAV 1.194186202 SOL/YIELD is explained by ordinary staking rewards**, not a donation/burn: the implied compounded rate is **7.377 %/yr** over 2.493 years — squarely in the normal Solana staking yield band, and consistent with the pool's own fee schedule (epoch fee **0 %**, deposit fee **0 %** today, 0.1 % withdrawal fees).
   - Excess over 1:1 = 4,878.652810061 SOL. No large donation or burn had to be invoked; the only "extra" inflow found is a **141.586756 SOL Jito MEV tip claim** into the pool's stake account on 2026-10-15 03:44:35 UTC (0.47 % of TVL), swept to the reserve by the pool 66 s later.
   - The earlier "pool is young / ~1 day of history" impression comes from **publicnode's truncated `getSignaturesForAddress` index (~24 h)**. mainnet-beta shows the pool account alone has **>41,000 signatures** (fetched 41 k, not exhausted), the reserve has **14,468** (complete), the mint **38,281** (complete), the validator list **12,878** (complete).
3. **Concentration is extreme**: 4,261 YIELD accounts; **top-1 = 41.28 %** (a marginfi v2 lending-market vault), **top-2 = 78.39 %**, **top-5 = 97.28 %**. ~48 % of supply sits in **Loopscale** program accounts, ~41 % in the marginfi vault, 0.08 % in Sanctum Infinity (S-controller), the rest in EOAs/PDAs.
4. **Control change 3 days before collection**: on **2026-10-12 02:28–05:33 UTC** the team created a **Squads v4 multisig** (`GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v`, threshold 3, 24 h timelock) and executed `SetManager` on **four pools at once** (YIELD + hy1o×2 + prt1s), moving their manager to the multisig's vault `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1`. The **manager fee account is an EOA-owned token account** (`GAGMZfQ…`, owner `Gutj91DY…`) that came into use at the same moment and is *not* the vault's ATA.
5. Sanity: the pool's stake account holds *exactly* delegation + rent (no undelegated lamports), YIELD holder balances sum **exactly** to the mint supply, and the pool's stored `last_epoch` figures reconcile with the current totals. No evidence of mis-accounting.

---

## 1. Task 1 — YIELD holder distribution (full, not a sample)

Method: `getProgramAccounts(TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA, {dataSize:165, memcmp offset 0 = mint, dataSlice 32..88})` → **4,261 token accounts**, raw amounts sum to **25,123,581,135,630 = mint supply exactly** (cross-checked with `getTokenSupply`). Owners classified with `getAccountInfo`; on-curve test via ed25519 decompression.

| rank | owner | owner type | YIELD | share |
|---:|---|---|---:|---:|
| 1 | `5zqnB8kRX687APdVXaffaJPmDkPrYfZgsF1xEr1ejMRk` | off-curve PDA (no account); controls token acct `BvN7jJrLSzv…` whose activity is **marginfi v2** (`MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA`) flashloan/borrow/`LendingAccountDeposit` flows — consistent with a lending-market vault | 10,372.073075 | **41.284 %** |
| 2 | `3xBNjR6Nxd6Ug8W9saF4daYamgzeY8boYQAyRhNyGgWY` | **Loopscale** account (`1oopBoJG58Dg…`, 1,658 B) | 9,323.460275 | **37.110 %** |
| 3 | `7Rea8Tphwp7iGUnT9A3vwPJHdAbTeA1ruuCgbC4sCWc2` | Loopscale (1,658 B) | 2,174.781876 | 8.656 % |
| 4 | `7zcsmq1xmcQknrgd48sVNwjt7kfd9EfqV3Jy6ueZVc7G` | system-owned 0-data off-curve PDA (program vault) | 1,730.221032 | 6.887 % |
| 5 | `5wSGgc4v2wjXYnSuindjyZvi6ZR4L7YSHQtFCNNXmgzY` | on-curve EOA (48.95 SOL) | 840.851273 | 3.347 % |
| 6 | `26xfq9tTTAZbbCMyFp4G3Ai6TGUxJk9CSBSJxqeADon8` | Loopscale | 189.610833 | 0.755 % |
| 7 | `GePrEa9uCE6w6v8SvdDuNdQnPCktN2L8EzxhY6q631vt` | Loopscale | 58.177353 | 0.232 % |
| 8 | `H3jVN7YyVCu14psLuPtnNm7tsjH1zxakLoYt5nobe7aY` | Loopscale | 55.637795 | 0.221 % |
| 9 | `7zap4PJaL7gia2uuhBb1xQTmrUyP8DHb95KxbWB9mmQA` | on-curve EOA (397.85 SOL) | 55.320601 | 0.220 % |
| 10 | `HAu3J6YuruMrPn9wyqVn5zNdpRiVRXfZfK1rdENRb8j2` | Loopscale | 45.630810 | 0.182 % |
| 11 | `HLnpSz9h2S4hiLQ43rnSD9XkcUThA7B8hQMKmDaiTLcC` | off-curve PDA (177.74 SOL) | 43.713780 | 0.174 % |
| 12 | `DxyyRaCJjwV3kmNpnZ5dn1DMs8VT8NEwVBjp563GFi8V` | Loopscale | 26.861774 | 0.107 % |
| 13 | `5uTitbv7vPQy4PW8jSvXefheSSa85YJGYB4Z4TBRKa8Y` | Loopscale | 26.655837 | 0.106 % |
| 14 | `AYhux5gJzCoeoc1PoJ1VxwPDe22RwcvpHviLDD1oCGvW` | **Sanctum S-Controller (INF)** program account (`5ocnV1qiCgaQ…`) | 20.151535 | 0.080 % |
| 15 | `AeTG5pfJ8v223i9PH7tcoz5CjPSt7W4HCSjQcGJWGdDm` | on-curve EOA | 17.237806 | 0.069 % |

Concentration: top1 41.284 %, top2 78.395 %, top3 87.051 %, top4 93.938 %, **top5 97.285 %**, top10 98.894 %, top25 99.803 %, top50 99.915 %. Pool **manager fee account** `GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U` holds 2.01457808 YIELD (≈ rank 26). Old fee account `3Y3bNqaR…` (ATA of the creator) holds 0.

Interpretation: >89 % of YIELD is locked in **program vaults used as lending liquidity/collateral** (Loopscale ~47.6 % across 8 accounts; marginfi v2 41.3 %; Sanctum INF 0.08 %); only ~4 % is in plain wallets. Free float is thin — relevant for any oracle/manipulation analysis.

---

## 2. Task 2 — Pool history and the NAV question (exact numbers)

### 2.1 Birth certificate and early history

| event | slot | blockTime | UTC | detail |
|---|---|---|---|---|
| YIELD mint created | 260,308,631 | 1713204023 | 2024-04-15 18:00:23 | `InitializeMint` (9 decimals), authority = `phaseGat2…`; tx `3nPvU9XT…` |
| reserve top-up test | 260,731,422 | 1713391603 | 2024-04-17 22:06:43 | +0.01 SOL plain transfer into `phaseECAe…` |
| reserve created+initialized | 260,733,987 | 1713392740 | 2024-04-17 22:25:40 | 200 B stake account, 0.00556576 SOL (rent + 3,282,880 seed) |
| **pool + validator list created** | **260,739,588** | **1713395218** | **2024-04-17 23:06:58** | `Initialize stake pool` (SPMBzs) + `SetAuthority` mint→`9HYjrCF5…`; rent 0.00514344 (pool) + 2.00786952 (vlist). Tx `4YRfsPUw43kDXcPFsWpffVdg8FKrcQ6YzRyYnjGjLZynqBvJxnZiDgmZMEMeFZyjXVA65RUtYcu1kbxrYyR36Y2G` |
| init mint | — | — | same tx | 3,282,880 raw (0.00328288 YIELD) minted to the original fee account `3Y3bNqaR…` |
| first stake deposit | 260,748,473+ | 1713401112 | 2024-04-18 00:45:12 | `DepositStake`, minted **510.270080016 YIELD** |
| early SOL deposits (samples) | — | 1714204179 / 1714227029 | 2024-04-27 | minted **998.743528** (997.744784 user + 0.998744 fee = 0.1 %) and **43.185796** (43.142610 + 0.043186) |

Historical fees: April 2024 had a **0.1 % SOL-deposit fee** (fee tokens minted to the then fee account = ATA of the creator). Current state (2026-10-15): `epoch_fee 0/100 = 0 %`, `sol_deposit_fee 0/1000`, `stake_deposit_fee 0/1000`, `stake_withdrawal_fee 1/1000 = 0.1 %`, `sol_withdrawal_fee 1/1000 = 0.1 %`.

### 2.2 Current state (2026-10-15, epoch 1058)

| item | value |
|---|---|
| pool total_lamports | 30,002,233,945,691 (30,002.233945691 SOL) |
| pool_token_supply | 25,123,581,135,630 (25,123.58113563 YIELD) |
| NAV | **1.194186202 SOL/YIELD** (redemption after 0.1 % w-fee: 1.192992016) |
| excess over 1:1 | 4,878.652810061 SOL |
| last_epoch_total_lamports / supply | 29,997,808,108,053 / 25,123,581,135,630 (NAV_last 1.194011908) |
| reserve stake `phaseECAe…` | 86,131,699,596 lamports; staker=withdrawer=`9HYjrCF5…`; initialized (not delegated) |
| validator stake `8QtQ1U34…` | 29,916,104,528,975 lamports = delegation **29,916,102,246,095** + rent 2,282,880 → **no undelegated lamports** (rules out accumulated direct donations sitting in the stake account) |
| stake delegation | voter `CiTYUYPAP…`, activationEpoch **952** (account first used 2026-04-06 18:08:16 UTC via `AddValidatorToPool`), deactivationEpoch = max, creditsObserved 2,088,183,129 |
| validator list `phaseeExd…` | vec_len **1** (re-verified with correct layout; the earlier "7 entries at epochs 953/954" parse was wrong — see §5) |
| fee account `GAGMZfQ…` | 2.01457808 YIELD, authority `Gutj91DY…` (EOA) |

### 2.3 Why NAV ≈ 1.194 (and not 1.00–1.02)

- Age × rate: 1.194186202^(1/2.4932) − 1 = **7.377 %/yr compounded**; gross staking yields of ~7 %+ with MEV tips over Apr-2024→Oct-2026 make this the expected value, especially with 0 % epoch fee. Cross-check with the same operator's pool `prt1s…` (NAV 1.0578 over ≈1.22 yr = 4.70 %/yr, presumably higher fee/different history) and `hy1oDeVCV…` (NAV 1.0803; ≥169 days old, ≤18.2 %/yr cap, consistent with ~6.7–8 %/yr for its plausible age).
- Observable reward delta: the two stored snapshots in the pool account differ by **+4.425837638 SOL** (`last_epoch_total_lamports` 29,997,808,108,053 → `total_lamports` 30,002,233,945,691, the latter written by the 2026-10-15 03:45:41 UTC update). Stored snapshots are only written by `UpdateStakePoolBalance` calls at irregular intervals, so this single delta is not by itself a rate; the aggregate NAV CAGR (7.377 %/yr) is the robust figure.
- **Donation/burn check (bounded)**: all 44 unique txs in the last-24 h window were decoded (JSON in `history_analysis.json`); 10 oldest + 4 mid-history reserve transactions and the 4 oldest stake-account transactions were decoded (total ~30 full txs) — all are ordinary `DepositSol` / `DepositStake` / `WithdrawStake` / `Update*` / Jito-tip / router flows. No direct lamport donation to reserve or stake account was found in any decoded transaction. No YIELD `Burn` instruction was observed in any fully-decoded window. Residual uncertainty: the pool's full 41 k-signature history was fetched but not decoded tx-by-tx (RPC-budget bound); the 141.586756 SOL Jito tip (below) is the only non-deposit inflow observed.
- **Jito MEV tip inflow** (previously unreported): tx `2tv5LCTr…` at slot 457,092,223, 2026-10-15 03:44:35 UTC — a **Jito Tip Router / Tip Distribution claim** credited the pool's stake account `8QtQ1U34…` with **+141,586,756 lamports** coming from the validator's tip distribution account `BQ8bbWj747JrvctiHeqrHyxfTprMyQA7x3X4paRW4Cyg` (−141,586,756), via inner ix `4R3gSG8BpU…` (Jito Tip Distribution, creating ClaimStatus `CWWqtUVn…`). 66 s later the pool's `UpdateValidatorListBalance` swept it to the reserve. This is a genuine NAV-accretive inflow to all YIELD holders (0.47 % of TVL in one claim).
- Reconstructed reference flows in the last 24 h (all decoded): 962.461856 SOL deposit minting 806.075178 YIELD at NAV 1.194012 (tx `5VNdYKoc…`, payer `thorXA…` via Sanctum Router `stkitr…` + `8F2VM13kdMBa…`; YIELD routed onward through Jupiter `JUP6Lkb…`); stake→reserve sweep 141.586756 SOL; Loopscale collateral-check txs; Sanctum S-controller txs; marginfi flashloan routed into `DepositSol`.

---

## 3. Task 3 — SPMBzs program scan (56 pools) and the Phase family

`getProgramAccounts(SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn, {dataSize:611, memcmp offset0=0x01, dataSlice 0..300})` → **56 stake-pool accounts** (mainnet-beta; the only working endpoint). Full table in `pools_scan.json`.

- Largest: jupSOL `8VpRhuxa…` 5,216,413.90 SOL TVL, NAV 1.2145; `Bvbu55B9…` 311,368.67 SOL NAV 1.1041; `3aUmJDNp…` 213,345.46 NAV 1.1041; `hy1oDeVCV…` 193,734.48 NAV 1.0803.
- **Phase-relevant rows** (manager = `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1`, the Squads vault):

| pool | mint | TVL (SOL) | supply (raw) | NAV | last upd epoch |
|---|---|---:|---:|---:|---:|
| `phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG` (YIELD) | `phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG` | 30,002.23 | 25,123,581,135,630 | 1.1942 | 1058 |
| `hy1oDeVCVRDGkxS26qLVDvRhDpZGfWJ6w9AMvwMegwL` | `hy1oXYgrBW6PVcJ4s6s2FKavRdwgWTXdfE69AxT7kPT` | 193,734.48 | 179,341,097,610,800 | 1.0803 | 1058 |
| `hy1o2kiYu9rUDFqHJSqwJH4j5ZkM23tBJsaEmqkP9sT` | `hy1opf2bqRDwAxoktyWAj6f3UpeHcLydzEdKjMYGs2u` | 10,871.93 | 10,871,826,861,647 | 1.0000 | 1058 |
| `prt1stdbFCFXpEcx9rxwJK63zhYo43V5JCXzGWXkPGn` | `prt1sxymaSoH5R6ZFyAnmMrqp9XbuyDXbBWnHg3XuLJ` | 1,187.19 | 1,122,284,074,508 | 1.0578 | 1058 |

- **pdSOL is NOT on SPMBzs.** `aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6` is owned by the **canonical SPL stake pool program `SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy`** (611 B, account_type 1). Its fields: mint `aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF`, manager `7LqSTwcw…` (same Squads vault), staker `QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk` (exists, on-curve), stake_deposit_authority `4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8` (absent, off-curve), **sol_withdraw_authority = None** (i.e., unset — permissionless SOL withdrawals per program semantics), total_lamports 1,101,114,884,155,839 (1.101 M SOL), supply 952,415,109,886,148, NAV 1.15613, vlist oldest fetched 143 days ago (≥143 days old).
- Other pools scanned (non-Phase) are listed in `pools_scan.json`; the only pools sharing the Phase manager are the four above.

---

## 4. Task 4 — Authority control mapping

### 4.1 Current authorities (YIELD pool, verified 2026-10-15)

| role | address | exists | on-curve | owner program | notes |
|---|---|---|---|---|---|
| manager | `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1` | yes (1,000,000 lamports) | **no** | system (0 data) | **Squads v4 vault**: PDA `["multisig", GRe1iCBE…, "vault", 0]` reproduced byte-for-byte (bump 255); signs via `SQDS4ep65T… VaultTransactionExecute` |
| staker | `DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK` | **no** | yes (keypair exists off-chain) | — | **active**: signed `SetManager` on 2026-10-12 04:07:46 UTC and moved 1.001919 YIELD to the new fee account |
| sol_withdraw_authority | `phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d` | yes (19,995,000 lamports) | yes | system | hot wallet |
| stake_deposit_authority | `DTws8vTwkJ1U1gpfgtbLsxydVgnDkLBoB9n1KYvw27BT` | no | no (PDA) | — | only used as deposit-auth PDA |
| manager_fee_account | `GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U` | yes (1,488,440 lamports) | no (token acct) | Token | authority = `Gutj91DY4ZS7TCJzCUVMRdDhT9U2ccsDy4fgn74WawgL` (EOA) — **not** the vault's ATA (vault ATA = `GXyaBh95…`); balance 2.01457808 YIELD; only 15 lifetime txs, oldest 2026-10-12 03:55:42 UTC |
| mint authority | `9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa` (= pool withdraw PDA) | yes (100,000,000 lamports) | no | system | standard SPL-stake-pool design |

### 4.2 The 2026-10-12 manager migration (exact sequence, all decoded)

1. **02:28:09 UTC** — `SQDS MultisigCreateV2` by `Gutj91DY…`: multisig `GRe1iCBEeAMdEeFmEMavgXJE8Uk8tU82pyxZ4iXXAD1v` (create_key `5VPERwbVnFFw2b95Szam2VHWbXQp8ks7SYQ9Xy3UfJTe`, **threshold 3, time_lock 86,400 s**, config_authority = system/none; 264 B account; **4 member keys decoded with permission mask 0x07** (full): `CQeJSnKkVyb6xrPm7obdp3uLHKoP3UgUC5uap6fPWKMH`, `E8S39HwmdoPity4wEQkDWZw7n6c3LCAFFdXEJNFXBHFD`, `GQJUoajR3gHfXJSSaTviAvRrMTUTmB9jiGE672KcFsUh`, `Gutj91DY4ZS7TCJzCUVMRdDhT9U2ccsDy4fgn74WawgL`). Vault[0] funded with 0.001 SOL in the same tx.
2. **03:55:42** — new fee ATA `GAGMZfQ…` created (owner `Gutj91DY…`, payer `4DgxbXBL…`).
3. **04:07:46** — `SPMBzs SetManager` (ix tag 10) — accounts `[pool, staker DxWfcgb2…, new_manager Gutj91DY…, fee GAGMZfQ…]`; signers `4DgxbXBL…` (payer), `DxWfcgb2…`, `Gutj91DY…`.
4. **04:10:45** — staker `DxWfcgb2…` transfers 1,001,919,179 raw (1.001919 YIELD) into the new fee account.
5. **05:33:11** — `SQDS VaultTransactionExecute` (multisig + vault `7LqSTwcw…`) running **`SetManager` for four pools in one transaction**: `phasejkG1…` (YIELD), `hy1oDeVCV…`, `hy1o2kiY…`, `prt1stdb…` → manager set to the vault `7LqSTwcw…` for all four (verified in current pool state). The transaction's account list carries the four pools' **new fee accounts**, now visible in state: YIELD → `GAGMZfQ…`, `hy1oDeVCV…` → `9mh4Y84YRaaT3EWdoEpkjZ2EVGycYmxvjuJ9krvGzAQx`, `hy1o2kiY…` → `GVraRwXx5UXJDHFUHyebBNySytkWdzUK7Z6QugbpZZEv`, `prt1stdb…` → `8BaXWNUJ8U2FM681WAKAtXhoZjizzWMY7rKFshfaAbk8`.
6. **2026-10-14 ~22:08–22:11** — the same vault executes four Squads `VaultTransactionExecute` payroll txs moving USDC (653.0, 666.75, 2,170.0, 1,418.04) from treasury account `9dXGg7EvQC7gX4TBcxbPYC6rrNHFApaywmudjbZFkBJz` to four recipients; vault's lifetime tx count: 10 (all ≥2026-10-12).

Previous (2024-04 → 2026-10-10) configuration: manager **`phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit`** (creator; on-curve wallet), fee account `3Y3bNqaRLFiG8w3wUUE82oEsbMwc8NjnJ5QLyn39APPU` (its ATA; last tx 2026-10-10 21:48:10, balance now 0).

### 4.3 Program upgrade authorities (all read on-chain; `program_authorities.json`)

| program (role) | upgrade authority | on-curve |
|---|---|---|
| `SPMBzs…` Sanctum SPL-multi stake pool (pool program) | `47SND7bGKvNXrqfP1bjsLCbwTgZhFBzAgmZ42QSkRScz` (Sanctum multisig) | no |
| `SPoo1Ku8…` canonical SPL stake pool (pdSOL) | `dPpFfahSWhm5M2RB3nVaHsXfnh9ooz5bWtR3WeUguDH` | no |
| `5ocnV1qiCgaQ…` Sanctum S-Controller (INF) | `47SND7bGKvNXrqfP1bjsLCbwTgZhFBzAgmZ42QSkRScz` | no |
| `stkitrT1Uoy…` Sanctum Router | `8VE2uJkoheDbJd9rCyKzfXmiMqAS4o1B3XGshEh86BGk` | no |
| `s1b6NRXj…` Sanctum Flat Slab | (Sanctum multisig per docs) | — |
| `ssmbu3KZxg…` / `sspUE1vrh7…` Sanctum SOL-value calculators | (Sanctum multisig) | — |
| `1oopBoJG58Dg…` Loopscale | `DwBXwJDZ4Av4miT62sEssWJUinkzwkmPPB4Fg3fKEfft` = Squads vault[0] of multisig `C4awuufiuL8DNT5wMDP27HneKKqbgynrsbCa4XYGSuPk` | no |
| `2rU1oCHtQ7WJ…` unidentified venue ("vault-liquid-unstake" per Eco SDK docs) | `F3yy3FVpwq9MV321AzALFcDWZp9XBBHbMas3t4AtEtCW` | no |
| `8F2VM13kdMBa…` unidentified (logs: "invalid vault-seed len!") | `7nVUx1oV3Dpo5MYVLHBCEv9yr7MMvXc9CokKqpY2dqxE` | **yes (EOA)** |
| `DRVSpZ2YUY…` unidentified | `6wdzUdicUXrBKhAJpZtmYVNq1tvopU3i8zVG383Rw24g` | no |
| `DeintXmrdZFg…` unidentified | `6EhmrJSgwCwRrF6aBAQ3ZJV3fWcJJbZLwQwyk96azAhj` | no |
| `FLUX6xBayG…` unidentified | `FLuxDycZB2eCzg4D4S7xvsLVqs43VqTnnpehP3o7syd9` | **yes (EOA)** |
| `HpNfyc2Saw…` PancakeSwap CLMM | `Em3wKQYD83ph9LmSt6xBZeB9DpozT55AcGa61EYxHRVh` | no |
| `T1TANpTeScy…` Titan Dex | `H92mY1R6CYDPpHjisrE3C7xqfgp7751f2R13aRoT4SbB` | no |
| `4R3gSG8BpU…` Jito Tip Distribution | (Jito) | — |
| `RouterBmuRBk…` Jito Tip Router | (Jito) | — |
| `SQDS4ep65T…` Squads v4 | none (immutable) | — |

No Phase-owned program was identified; the Phase stack uses Sanctum/SPL-stake-pool programs plus third-party protocols (Loopscale, marginfi, Jupiter, Titan, PancakeSwap CLMM, Jito).

---

## 5. Corrections to previously stated "known facts"

| prior claim | status |
|---|---|
| pool total_lamports 30,002,233,945,691; supply 25,123,581,135,630; NAV ≈1.1942 | **confirmed** (re-read twice) |
| YIELD decimals 9; mint authority `9HYjrCF5…` = withdraw PDA | **confirmed** |
| reserve 86.13 SOL | **confirmed** (86,131,699,596) |
| validator list vec_len=1, active validator `CiTYUYPAP…` 29,916,104,528,975 | **confirmed** with the correct entry layout (offset 9, 73 B entries) |
| "the pool is young" (implicit in the NAV-anomaly premise) | **refuted** — pool created 2024-04-17; the ~1-day appearance is publicnode's ~24 h index truncation |
| earlier parse showing vlist entries at epochs 953/954 ("ReadyForRemoval") | **wrong parse** — the real list holds a single entry; the separate true fact is the stake account's `activationEpoch = 952` (delegation to CiTY created 2026-04-06) |
| stake account `8QtQ1U34…` is the pool's CiTY stake account | **confirmed** — PDA `[vote, pool]`, bump 255, delegation 29,916.102246095 SOL |

## 6. Files (all in `/home/heisenberg/CA/phase-stake/analysis/`)

- `holders.json` — full holder distribution (4,261 accounts), top-20 detail, concentration, owner classification
- `token_gpa_holders.json` — raw GPA result (offset 32..88 slice per account)
- `holder_class.json` — top-15 owner accounts classification
- `history_summary.json` — consolidated history/authorities/timeline numbers
- `mb_sigs.json` — signature list per account (pool 41,000 not exhausted; reserve 14,468; mint 38,281; vlist 12,878; stake 4,056; fee 15; manager 10 — all complete except pool)
- `history_txs.json` + `history_analysis.json` — all 44 unique txs of the last-24 h window, decoded (instruction trees, SOL/YIELD deltas)
- `history_samples.json`, `history_early2.json`, `old_history.json` — reserve/stake/fee early + mid-history samples
- `creation_tx.json`, `final_targeted.json`, `msig_setmgr.json`, `setmanager_tx.json`, `squads_msig.json` — creation tx, mint creation, first CiTY stake ops, fee-account switch, SetManager txs, Squads decode
- `pools_scan.json` (56 SPMBzs pools), `program_authorities.json`, `auth_map.json`, `vlist_recheck.json`, `stake8QtQ.json`, `reserve_stake.json`, `pool_state_full.json`, `final_refs.json`, `sibling_ages.json`, `jupsol_state.json`, `trunc_test_jup.json` (publicnode truncation proof)
- scripts: `sub_*.py` (read-only; `sol_util.py` untouched)

## 7. Open items / residual uncertainty (be explicit when citing)

1. The pool's 41 k-signature history was fetched but not decoded tx-by-tx; a **donation/burn scan over the full history** (e.g., grep all 14,468 reserve txs for non-SPMBzs transfers) was not completed due to RPC budget. Sampled evidence shows none.
2. `getTokenLargestAccounts` never succeeded (429 / "indexed request" blocks); holder data comes from Token-program GPA on mainnet-beta (equivalent coverage, verified sum == supply).
3. Exact Squads member list: 4 member keys decoded with permission mask 7; one trailing 32-byte field in the 264-byte multisig account was not identified.
4. Per-epoch reward accrual across the whole life requires decoding all `UpdateStakePoolBalance` txs; the NAV CAGR (7.377 %/yr) is the aggregate result and is consistent with the pool's observable fees and the spot epoch delta.
5. The 141.586756 SOL Jito tip inflow (2026-10-15) should be re-checked for frequency (it is NAV-accretive to all holders, and any such inflow also instantaneously moves any NAV-based oracle).
