# ZOMBIE-HUNT IV — Solana targets: Jupiter Offerbook & PiggyBank

Read-only investigation. No transactions were sent; all probes use `simulateTransaction`
with `sigVerify:false` / `replaceRecentBlockhash:true`. Scripts and raw dumps are in this
directory (`/home/heisenberg/CA/vaults-escrow-cluster/analysis/solana`).

Date: 2026-10-18. Working RPC: `https://api.mainnet-beta.solana.com` (finalized/confirmed).

---

## 0. Verdict table

| Target | Category | USD (today) | Confidence | Verdict |
|---|---|---:|---|---|
| **Jupiter Offerbook** | **E-U (extractable, unprivileged)** | **$0 identified** | **High** for tested paths / Medium overall | No third-party path found. Escrow withdraw, cancel, both fill sides, claim, repay, and token-program substitution are all bound to the correct party or rejected by the runtime. |
| Jupiter Offerbook | H-O (holder-only) | ~$1.34M TVL marked to Jupiter | Medium | Funds belong to makers/takers/lenders. `disable_repayment=1` and expired offers are holder risks, not third-party extraction. |
| Jupiter Offerbook | P (privileged) | ~$1.34M + $14.3k fees | High | Config admin + upgrade authority = `GpYnS3dP…4N79`, an off-curve system account executed through **Squads v4** (`SQDS4ep6…`). Program upgraded at slot **456,774,686**. |
| Jupiter Offerbook | S (stuck) | 2,704 expired open offers; 522 defaulted loans; illiquid memecoin collateral | Medium | Not stuck by code: makers can cancel/withdraw, lenders can claim after expiry once ATAs exist. |
| **PiggyBank (Pig1 + Pig2)** | **E-U** | **$0 identified** | **High** | Deposit and redeem use the *same* NAV (`total_shares` field); same-epoch round trip loses 1 raw unit to floor rounding. Claim is bound to `redemption.user`; attacker claim rejected. |
| PiggyBank | H-O | ~$1.74M managed | High | 96–99% of assets are **off-vault**, custodied by the admin; redemption is epoch-queued. |
| PiggyBank | P | ~$1.74M | High | Admin + upgrade authority = `C63SijJ…wx8K`, an **on-curve single key**; can upgrade, pause, change multiplier/transfer hook, and controls off-vault custody. |
| PiggyBank | S | ~$58k unclaimed redemptions | Medium | Queue of 1–2 epochs; claim works for mature epochs (verified), but idle on-chain liquidity is only 1–4% of NAV. |

**Headline E-U: $0 identified on both targets (confidence high for the paths exercised).**
These are *negative* results, not proof of absence. The Offerbook binary was upgraded ~7 days
before this review and contains yield instructions absent from the public IDL; the PiggyBank
source is private, so state/instruction layouts were recovered from on-chain data.

---

## 1. Jupiter Offerbook

### 1.1 On-chain identity (verified)

| Item | Value | Slot |
|---|---|---|
| Program | `offerbkFMvVfpQhL8ZQ5iromnjct5rz3r52B9ewu3ie` | 458,321,404 |
| ProgramData | `ANwCXRSc7vwD1WpdFE7LmsWTzjq9Xbp7R7JmATgAFXzA` | 458,321,404 |
| Upgrade authority | `GpYnS3dPdR4Abj6pf3XbtU2kC8kgN6Lz5y6CuyFt4N79` | 458,321,404 |
| Authority type | off-curve system account; upgrade tx at slot **456,774,686** executed via `SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf` (Squads v4) | 456,774,686 |
| Deploy/upgrade slot | 456,774,686 (~7.3 days before current slot 458.35M) | — |
| Config PDA | `5bjsMDacvtuRjtSD4j4ARsfP6Ras3dywyyuvsbbnXNQk` (derived `["config"]`, matches on-chain) | 458,326,422 |
| YieldMarket | `GSYR6JQ9YmwP35SaDbzxQnWJJ6heCCkteaUAQtSKasYV` (sole `YieldMarket` account) | 458,326,422 |

Config (decoded, slot 458,326,422): admin = upgrade authority; fee authority =
`Edt83Aw3RAELsorwJkt4DDkczrTpHsNeFGzty83TQzuy` (`["fee"]` PDA);
interest_fee 2500 bps (25%), repay_fee 1000 bps, liquidation_fee 10 bps,
referral 3000/referee 2000 bps, min principal/collateral 1000, max APY 5000 bps,
**is_paused=0, disable_repayment=1**.

### 1.2 IDL / layout recovery

* Public Anchor IDL account does **not** exist: `find_program_address(["anchor:idl"], program)`
  = `7LiMJwNpTTXZrBkmmpqFw2n94rSzHs1gqNTcGW7P3GSg` → no account (slot 458,321,8xx).
* Recovered a matching IDL from the public analytics repo
  `ario-57/solana-offerbook-analytics` (`idl/offerbook.json`, 122 KB), including all
  account discriminators:
  `Offer d27ZJAf7ENY`, `Loan 4URf4twWraU`, `User TfwwBiNJtao`, `Config SwB71qnXfS1`.
  Live census matched the IDL exactly (slot 458,326,223):
  3,196 Offer + 5,453 Loan + 2,980 User + 1 Config + 1 `YieldMarket`
  (`QViXieYJtyG` = sha256("account:YieldMarket")[:8]).
* IDL is **stale** for two things (verified behaviorally): `repay_token_loan` now takes an
  `Option<u64>` argument, and 5 yield instructions
  (`escrow_yield_deposit`, `escrow_yield_withdraw`, `escrow_yield_withdraw_all`,
  `create_yield_market`, `update_yield_market`, `set_yield_enabled`) exist in the
  deployed binary but not in the public IDL. Account layouts for the tested paths were
  confirmed with live successful transactions and simulation.

Account sizes / offsets used (zero-copy):
`Offer` 1224 B, `Loan` 808 B, `User` 208 B, `Config` 536 B, `YieldMarket` 464 B.
Offer fields: creator 8, side 40, status 41, principal Asset 48..313, collateral 320..585,
filter 592, amounts 864/872/880/888, apy 904, duration 908, times 912/920/928,
min_fill 936, fill_counter 944, flags 952–954, countered_offer 960.
Loan fields: lender 8, borrower 40, creator 72, offer 104, status 136, type 137,
fill_index 144, principal 152, collateral 424, amounts 704/712/720, expiry 736.
`Asset` enum: tag 1 = Token, then mint at +1, token_program at +33 (sizes 265; no alignment padding).

### 1.3 Live state and real escrow (not DefiLlama's number)

Read at slots 458,326,859 (offers), 458,327,957 (loans), 458,329,521 (users),
balances at 458,330,934 / 458,328,635. Prices: Jupiter `lite-api/price/v3`,
blockId 458,333,963 (first batch) and 458,348,990 (later).

| Bucket | Accounts | Marked USD | Hard USDC portion |
|---|---:|---:|---:|
| Open-offer escrow (maker's User-PDA ATA for the offered asset) | 325 unique ATAs | **$300,125** | 205,116.92 USDC = $205,070 |
| Loan collateral in loan-owned vaults (authority = loan PDA) | 294 funded of 350 active | **$980,638** | 0 USDC (collateral is memecoins/SOL/LSTs) |
| Borrower escrow residual (User-PDA ATA for loan collateral) | 178 funded | **$59,828** | 0 |
| **Total identifiable escrow** | | **≈$1,340,591** | **$205,070** |
| Fee authority (protocol revenue, admin-claimable) | 55 token accounts | **$14,287 USDC** + tokens | 14,290.24 USDC |
| Yield feature user positions (pb-style Jupiter Lend shares) | 6 User PDAs, 2 nonzero | **≈$91** | — |

DefiLlama: **$1,292,969** — ~3.6% below our mark-to-Jupiter total (methodology/prices).
The USDC-only hard floor is **$205k**; the rest is memecoin/LST collateral. Only 3.5% of the
loan-vault mark is in mints with <$100k Jupiter liquidity, but several positions are 9–13%
of their mint's liquidity, so a liquidation haircut of ~10–20% is realistic.

Notes:
* 2,704 of 3,196 open offers are past `expired_at`. They remain cancelable by the maker.
* 350 active loans, 522 defaulted, 4,581 repaid. Defaulted loans generally have empty vaults
  (already claimed).
* `disable_repayment=1` does **not** block repay in the deployed code (the repay simulation
  reached the token transfer, see 1.4).
* `Loan` PDA = `["loan", offer, fill_index_u64_le]` (confirmed against 5,453 live loans;
  the public IDL misleadingly shows `offer` twice). `loan_vault` = `["loan_vault", loan]`,
  and the vault token account's **authority is the loan PDA**, not the program.

### 1.4 Exploit probes (read-only simulation) — all blocked

Each simulation used live accounts. `sigVerify:false`; no signing/broadcast.

| Probe | Call | Result | Error |
|---|---|---|---|
| Third-party `escrow_token_withdraw` | signer=A `5At6…`, `signer_user`=victim `FhNA…`, victim escrow `WEQY…` (34,832 USDC) | **blocked** | Anchor 6013 `InvalidOwner` on `signer_user` |
| Control withdraw | signer/user/escrow all A's | succeeds (1 USDC moved in sim) | — |
| Third-party `cancel_offer` | creator=`13UH…` on offer `1Vcxm…` (creator `5At6…`) | **blocked** | 6013 `InvalidOwner` (logs print Left/Right) |
| Control cancel | creator of offer `1Vcxm…` | succeeds | — |
| `fill_token_principal_offer`, lender substitution | signer=A, `lender`=A but `lender_user`=creator's user `FhNA…` | **blocked** | 6013 `InvalidOwner` on `lender_user` |
| Control fill (principal) | lender=offer creator, `lender_user`=creator user | passes binding, fails later on empty taker collateral escrow (SPL `insufficient funds`) | — |
| `fill_token_collateral_offer`, borrower substitution | signer=A, `borrower`=third wallet, `borrower_user`=maker's user `BHZB…` | **blocked** | 6013 `InvalidOwner` on `borrower_user` |
| Control fill (collateral) | borrower=maker, `borrower_user`=maker user, 1e12 collateral | **succeeds** (≈13,333 USDC principal) | — |
| `claim_token_loan`, non-lender | borrower signs own loan `54Cn…` | **blocked** | 6003 `NotAuthorized` on `loan` |
| Control claim | lender `4mbW…` on past-expiry loan `54Cn…` | **succeeds** (0.1 SOL collateral → lender, fee to fee ATA) | — |
| Early claim | lender on active loan `GPmm…`, expiry 179,240,7285 > now 179,230,5xx | **blocked** | 6020 `LoanNotDue` at `state/loan.rs:126` |
| Repay, wrong amount | `Some(principal only)` = 34,000,000 vs owed 34,095,013 | **blocked** | 6026 `InvalidRepayAmount` (logs Left/Right) |
| Repay, fake token program | pass Memo program as `principal_token_program` | **blocked** | 3008 `InvalidProgramId` |
| Repay, full | `None` (Option tag 0) | passes checks, fails SPL `insufficient funds` on empty borrower ATA | — |
| `set_loan_extendable` | borrower signs | **blocked** | 6003 `NotAuthorized` |
| `set_loan_extendable` | lender signs | succeeds | — (by design: lender controls extension) |
| Yield `escrow_yield_withdraw_all` | attacker signer, victim `signer_user` | **blocked** | 2006 `ConstraintSeeds` (signer_user must equal `["user", signer]`) |
| Yield `escrow_yield_withdraw_all` | signer=victim, destination=attacker ATA | **blocked at seeds** (same check) | 2006 |

Conclusion: every value-moving path is bound to the on-chain party that owns the escrow
(`User.owner`, `Offer.creator`, `Loan.lender`, or the signer-derived User PDA). There is no
third-party accept/cancel/claim path. The `disable_repayment` flag is not enforced in the
current repay handler.

### 1.5 What still carries risk (not E-U)

* **P:** one Squads multisig controls upgrade + config admin. It can pause, change fees,
  and upgrade the program. The program was upgraded at 456,774,686; the new binary includes
  unaudited yield code (only ~$91 of user positions today, but a future upgrade could change
  value-bearing paths).
* **H-O:** makers can withdraw escrow with `escrow_token_withdraw` while an offer is open,
  leaving it unfunded (fill reverts atomically; taker loses only tx fees). Lenders rely on
  the 25%/10% fee schedule and on collateral liquidity.
* **S:** claim requires the lender's collateral ATA and the fee ATA to be initialized. They
  are permissionless to create (ATA idempotent), so funds are not permanently stuck, but a
  lender who never creates them cannot claim.
* Memecoin collateral is marked at Jupiter mid; realizable value is lower.

---

## 2. PiggyBank

### 2.1 On-chain identity (verified) — **two programs**

| Item | Pig1 | Pig2 |
|---|---|---|
| Program | `Pig1CsXnfDwN1NuoeNRBojohbjc14dogmJCXeb2vL3Y` | `Pig2ienhM3ukiTec3x8aCdnLASpU4z8yRPLgH9QxDvm` |
| ProgramData | `EjH3qrG8Ec9tJwmALytNSeKB62VHZzWPujrDKKbbcgHo` | `33Xg64wHTKSSZLCd41wiLu9nt7yU9sJGfb6Taemd6RDK` |
| Upgrade authority | `C63SijJLVtiMmzosPmZ23mft4GxXXXTxjmuuu98owx8K` | same `C63SijJ…wx8K` |
| Deploy slot | 375,549,954 | 375,594,599 |
| Vaults | pbUSDC `91LYov1N1j62Q3ipuBi8w2e5GVqjVxWTdJ757roiWXdy`; pbJITOSOL `6mzgN6fyqap4Um7bNoH7DNCqtib3CU7TfGvVTMBhaDhf` | pbSPYx `5CgRTdywEQ7LK7SRM5NAgsuSWxnswREW6VeZ4i9jHCRf` |
| Config | `GYsQqz2ySWc4xkTX3J1nTJf7Cv7wAnz8wkVqVESacsv7` | `AgQWJYhjAoAns5GCassi2DmP61z9S2252vVucPJA32qe` |
| Admin (config[8..40]) | `C63SijJ…wx8K` (on-curve EOA) | same |
| Paused | 0 | 0 |

Both configs are 42 B: `"PBKCONFG"` + admin(32) + bump + paused.
Program accounts (slot 458,342,380 / 458,347,xxx):
Pig1: 2 `PBKTOKEN` vaults, 1 `PBKCONFG`, 2,354 `REDEEMPT`.
Pig2: 1 `PBKTOKEN` vault, 1 `PBKCONFG`, 1,712 `REDEEMPT`.

The recon only named `Pig1…`; **pbSPYx is served by the second program `Pig2…`**, same
authority/admin. This was verified by account ownership before trusting it.

### 2.2 Layout recovery (no source available)

The repo `zsociety-io/piggybank-program` is private (audit PDF says private at audit time;
GitHub returns 404). Audit PDF: `evidence/piggybank_audit.pdf` (Formal Land, 2025-10-27).
We recovered layouts from live accounts and instruction data:

**Vault (`PBKTOKEN`, 210 B)** — verified on all 3 vaults:
```
0   "PBKTOKEN" (8)
8   share_mint (32)
40  underlying_mint (32)
72  total_shares u64          // NAV denominator
80  0
88  epoch u64
96  pending_redemptions u64   // bucket A
104 0
112 pending_claims u64        // bucket B (matches latest redeem log)
120 0
128 fees/residual u64
136..160 0
160 idle_underlying u64       // tracks on-chain vault ATA (slightly stale)
168 0
176 managed_assets u64        // NAV numerator (includes off-vault custody)
184 0
192 deposit_cap u64
200 flags/bump
```
**Redemption (`REDEEMPT`, 130 B)**:
```
0 "REDEEMPT"; 8 id[16]; 24 user(32); 56 vault(32);
88 shares u64; 96 0; 104 underlying u64; 112 0; 120 epoch u64; 128 claimed u8; 129 bump
```
Redemption PDA = `["redemption", vault, id16]` (verified against live account, Pig1).
Instruction tags observed: **0x03 = deposit(u64 amount)**, **0x04 = redeem(id16,u64 shares)**,
**0x06 = claim(id16)**. Pig1 deposit accounts: `[user, config, vault, share_mint,
user_underlying_ata, vault_underlying_ata, user_share_ata, system, token, ATA]`.
Pig2 adds the underlying mint: `[user, config, vault, share_mint, underlying_mint,
user_underlying_ata, vault_underlying_ata, user_share_ata, system, token, ATA]`.

`roll_epoch` signer is the admin `C63SijJ…wx8K` (verified tx slot 457,679,961); it logs
"Roll epoch: Admin deposited N tokens to vault for redemptions" and
"Epoch rolled from X. Performance: …, Processed redemptions: …".

### 2.3 NAV mechanics — the anomaly is real but not a mispricing

Decoded state at slot **458,343,675** (prices at blockId 458,348,990/713/548):

| Vault | share mint | epoch | total_shares (f72) | managed (f176) | pending A (f96) | pending B (f112) | idle (f160) | NAV/share |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| pbUSDC | F35yYmTR… | 179 | 1,126,462,826,426 | 1,143,707,275,075 | 17,052,792,956 | 0 | 12,829,660,831 | 1.00017 |
| pbJITOSOL | FWLk7bGA… | 154 | 2,138,337,460,483 | 2,074,199,148,507 | 34,846,564,231 | 6,529,674,430 | 64,300,820,093 | 0.95065 |
| pbSPYx | E65CoK96… (Token-2022) | 179 | 43,251,582,022 | 40,978,800,776 | 133,589,598 | 74,718,190 | 1,651,493,243 | 0.94264 |

NAV formula verified by simulation and by log arithmetic:
`NAV = (managed − pending_redemptions − pending_claims) / total_shares`.

Deposit and redeem both use this **same** `total_shares` field:
* pbSPYx deposit 100,000,000 raw → 106,085,474 shares (assets/share 0.942636).
* pbSPYx redeem 10,000,000 shares → 9,426,361 raw (0.9426361); predicted from f72
  0.9426359, predicted from actual mint supply 0.9454049 → **uses f72**.
* pbJITOSOL historical: 114,437,612 → 120,388,858 shares (0.95056);
  redeem 6,868,600,000 → 6,529,674,430 (0.95065). Product ≈ 1.0000.
* pbSPYx historical: 10,308 → 10,935 shares (0.94266); redeem 4,294,553 → 4,048,200
  (0.94253). Product ≈ 0.99986.

**Same-epoch round-trip test (live state, one transaction):**
* pbUSDC: deposit 1,000 → 999 shares → redeem 999 → **999** (loss 1 raw unit).
* pbSPYx: deposit 100,000,000 → 106,085,474 shares → redeem → **99,999,999**
  (loss 1 raw unit).
* pbJITOSOL: the same formula applies; no executable holder was available for a one-tx
  test (public RPC rate-limited holder discovery), but deposit/redeem logs give the same
  product ≈ 1.

So the headline 0.943/0.951 is the **vault's actual NAV per share** (losses), not a stale
deposit price. Both sides of the trade use it; a round trip loses only floor rounding.
The denominator is the vault's `total_shares` field, which is slightly **higher** than the
actual mint supply (pbUSDC +0.0013%, pbJITOSOL +0.81%, pbSPYx +0.29%). This makes NAV
slightly conservative (depositors mint a hair more, redeemers receive a hair less); it is
not exploitable in the direction tested. Whether the next `roll_epoch` resets `f72` to the
mint supply (which would create a small epoch-boundary dilution of ~0.3–0.8%, ≈$1–3k per
roll) could not be confirmed without an admin roll simulation; treat as a **low-confidence
residual (H-O/S)**, not an E-U.

### 2.4 Exploit probes (simulation) — blocked

| Probe | Call | Result |
|---|---|---|
| Deposit pricing | 1 SPYx → 106,085,474 shares (uses f72) | matches formula |
| Redeem pricing | 10,000,000 shares → 9,426,361 raw (uses f72) | matches formula |
| Round trip | deposit+redeem same tx, pbUSDC and pbSPYx | **−1 raw unit** |
| Claim by non-owner | attacker `5At6…` claims redemption `6uroen5…` (user `5ThBUL…`, 1,998,319.899 USDC) | **blocked**, custom error 1 |
| Control claim | owner signs, ATA created | **succeeds** ("Claimed redemption … for 1998319899 underlying tokens") |
| Early claim | epoch-178 record at vault epoch 179 | blocked, custom error 6 (not yet claimable) |
| Token substitution | deposit/redeem take explicit mint/token-program accounts; account owner/mint checks + SPL/Token-2022 Burn/TransferChecked enforce authority | no path found |
| Share theft | token program enforces burn authority (`Instruction: Burn`), so a victim's share ATA cannot be burned by another signer | no path |

### 2.5 Quantification and risk

Managed assets (slot 458,343,675; Jupiter prices blockId 458,348,990):
* pbUSDC: 1,143,707.275 USDC → **$1,143,464**
* pbJITOSOL: 2,074.199 JitoSOL × $135.14 → **$280,307**
* pbSPYx: 409.788 SPYx × $761.02 → **$311,857**
* **Total ≈ $1,735,629** (DefiLlama $1,712,682; Δ 1.3%).

**Off-vault custody** (idle on-chain / managed):
pbUSDC **1.13%** (12,881 USDC on-chain), pbJITOSOL **3.10%** (64.30 JitoSOL),
pbSPYx **4.05%** (16.61 SPYx). The remaining **96–99% sits with the admin** and is only
reflected in the `managed_assets` field. That is the dominant P risk: a single on-curve key
(`C63SijJ…wx8K`) is admin, upgrade authority, and custodian.

**Redemptions:** 102 unclaimed on Pig1 + 77 on Pig2:
* pbUSDC: 70 records, **$29,876** (some since epoch 3; claimable ones verified).
* pbJITOSOL: 32 records, **$14,281** (105.68 JitoSOL).
* pbSPYx: 77 records, **$14,153** (18.60 SPYx).
* Total **≈$58,310**, queue 1–2 epochs. Claims for mature records succeed; recent ones
  fail with "not yet claimable" (error 6), not a code lock.

**Admin-controlled roll (P, confirmed by simulation).** `roll_epoch` (tag `0x05`) takes
admin-supplied `performance` and `processed_redemptions` u64 arguments and, in simulation,
zeroed the pending buckets `f96`/`f112`, reset the fee/residual `f128` (51,131,906 USDC
withdrawn to the admin), increased `f176` by the same fee, and bumped epoch 179→180 while
leaving `f72` unchanged. That moved the naive NAV from 1.00017 to 1.01536 because `f96` was
zeroed without a corresponding `process_deposits`/`process_redemptions` call. A non-admin
signer is rejected (custom error 1). In normal operation the admin calls the process
instructions first; the point is that NAV and pending-liability accounting are
**admin-reported**, not trust-minimized. Combined with upgrade authority and off-vault
custody, this is the dominant risk on the target.

Other privileged controls: `update_admin`, `update_deposit_cap`, `pause/unpause`,
`update_multiplier` (pbSPYx Token-2022 multiplier = 1.0057145603, authority = vault PDA),
`update_transfer_hook` (currently null), and program upgrade.

---

## 3. Negative results / search log

* Offerbook Anchor IDL account absent; `anchor idl fetch` impossible (no Solana CLI). Recovered
  IDL from a public analytics repo and validated every discriminator against 11,631 live accounts.
* `jup-ag/offerbook-program` GitHub is 404/private (URL is embedded in the binary strings).
* PiggyBank GitHub `zsociety-io/piggybank-program` is private (404); audit PDF retrieved from
  DefiLlama's `audit_links`. No IDL (Pinocchio, not Anchor); layouts recovered on-chain.
* `getTokenLargestAccounts` and several alternate public RPCs were rate-limited/403 during
  holder discovery; the SPYx holder set was recovered with `getProgramAccounts` on Token-2022
  (231,252 accounts, dataSlice 72 B). JitoSOL holder discovery was ultimately not needed
  because deposit/redeem logs and the SPYx controlled test established the shared NAV formula.
* No transactions were signed or sent. All "success" results are simulation-only; state
  changes were not persisted.

## 4. Evidence index

| File | Contents |
|---|---|
| `evidence/program_meta.json` | program/programdata/upgrade authority/deploy slot for both targets |
| `evidence/offerbook_idl.json`, `offerbook_idl_old.json` | recovered IDLs |
| `evidence/offerbook_disc_summary.json` | 11,631-account discriminator census (slot 458,326,223) |
| `evidence/offers_decoded.json`, `loans_decoded.json`, `users_decoded.json` | decoded live state |
| `evidence/offerbook_state.json` | full state + balances + prices + escrow maps |
| `evidence/offerbook_summary.json` | corrected USD totals (slot + price source) |
| `evidence/offer_escrow_balances_v2.json`, `loan_balances.json` | token balances |
| `evidence/sim_withdraw.json`, `sim_cancel_*.json`, `sim_fill2_*.json`, `sim_fillcoll_*.json`, `sim_claim*.json`, `sim_repay_*.json`, `sim_setext_*.json`, `sim_yield2_*.json` | Offerbook simulations |
| `evidence/piggy_mints.json`, `piggy_disc.json`, `piggy_redemptions.json`, `pig2_redemptions.json` | PiggyBank accounts/redemptions |
| `evidence/sim_piggy_roundtrip_usdc.json`, `sim_pig2_roundtrip.json`, `sim_piggy_claim2.json`, `sim_piggy_claim_attack.json`, `sim_piggy_claim_early.json` | PiggyBank simulations |
| `evidence/piggy_prices.json`, `offerbook_vault_prices.json` | price snapshots (Jupiter) |
| `evidence/yield_market_txs.json`, `yield_share_holders.json` | Offerbook yield feature |

Scripts: `rpc.py`, `pda.py`, `txutil.py`, `sim.py`, `decode_offerbook.py`,
`collect_offerbook.py`.

## 5. Bottom line

* **Jupiter Offerbook:** no unprivileged extraction found. All tested state transitions are
  authority-bound; token-program substitution is rejected. Real escrow ≈ **$1.34M**
  ($205k USDC hard floor + memecoin/LST collateral). Risk is concentrated in the Squads
  admin/upgrade and in collateral liquidity, not in a third-party call path.
* **PiggyBank:** no unprivileged extraction found. Deposit/redeem share the same NAV;
  round trips lose 1 raw unit. Real managed TVL ≈ **$1.74M**, but **96–99% is off-vault with
  a single-key admin/upgrade authority**; ~$58k of redemptions are queued. The 0.943/0.951
  ratios are genuine NAV losses, not a stale-price arbitrage.
* **Headline E-U: $0 identified / confidence high for the paths exercised.** No P0/P1
  unprivileged drain was demonstrated on either target at slots ~458.32M–458.35M.
