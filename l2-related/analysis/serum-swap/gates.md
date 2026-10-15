# Serum Swap — value-moving paths: gates, live values, verdicts

Program `SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8`, deployed build
`solana-labs/solana-program-library@9281b6e82899` (2021-04-14, crate 2.1.0, `--features production`),
last upgrade slot 73,737,036 (blockTime 1,618,460,527 = 2021-04-15 04:22:07 UTC).
Categories: **E-U** extractable by an external unprivileged attacker · **H-O** holder-only ·
**P** privileged/key-gated · **S** stuck.

Deployed instruction set is **exactly six** instructions (`instruction.rs` tags 0–5); there is **no**
admin, fee-sweep, pause, or authority-transfer instruction:

| tag | instruction |
|---|---|
| 0 | `Initialize` |
| 1 | `Swap` |
| 2 | `DepositAllTokenTypes` |
| 3 | `WithdrawAllTokenTypes` |
| 4 | `DepositSingleTokenTypeExactAmountIn` |
| 5 | `WithdrawSingleTokenTypeExactAmountOut` |

Common gates applied to **every** non-init instruction (`processor.rs::check_accounts` /
`process_swap`):

* `swap_info.owner == program_id` (so a pool account can never be substituted);
* `authority_info.key == create_program_address([swap_info.key, stored_nonce], program_id)` — the
  vault-authority PDA is derived from the *pool account itself*, so vault signer rights cannot be
  redirected;
* `token_a`/`token_b` passed in **must equal the pool's stored `token_a`/`token_b`** accounts
  (`IncorrectSwapAccount`) — an attacker cannot substitute their own vaults;
* `pool_mint`, `pool_fee_account` and `token_program_id` must equal the stored values;
* funds leave a vault only via a CPI `transfer` signed by that PDA (`invoke_signed`) or via a CPI
  `burn`/`transfer` signed by the *user*, and the SPL Token program additionally enforces
  source/destination mint equality on every `transfer` (so a wrong-mint "source" account is rejected
  by Tokenkeg, not by the swap program).

## Per-path audit

| # | path | exact gate / mechanism in the deployed code | live value that enables/blocks it | verdict |
|---|---|---|---|---|
| 1 | **Withdraw without LP** (tags 3, 5) | `token_burn(… authority = user_transfer_authority_info …)` — Tokenkeg burns from the caller's LP account; the caller must own the LP and the burn reverts if the balance is short | `AmHUjHK…` holds $143.5 k of wSOL+USDC; a fresh attacker LP account has 0 LP | **blocked — proven by simulation** (`custom program error 0x1` in Tokenkeg burn). `E-U $0` |
| 2 | **Withdraw all with LP** (tag 3) | proportional `pool_tokens_to_trading_tokens(..., RoundDirection::Floor)` (rounding favours the pool), 0 % owner-withdraw fee, `min(reserve, amount)` clamp | LP supply 12.264e12 in `AmHUjHK…`; attacker share = what they paid in | **fair; H-O** (LP holders can redeem, incl. the fee-account holder) |
| 3 | **Withdraw single exact-out** (tag 5) | LP burn + **pre-#1794 over-charging math**: `burn = ceil(L·(√(1+D′/(S−D))−1))`, D′ = D − fee(D/2) | same LP gate | **blocked (no LP) / loss-making with LP** — proven by simulation: observed burn matches the deployed formula to 2.5e-11 and is **2.54 % higher** than the later "fair" (#1794) formula. `E-U $0` |
| 4 | **Deposit all** (tag 2) | tokens in via user-signed `transfer`s; `RoundDirection::Ceiling` on the tokens required per LP minted (favours pool) | needs real tokens (owned by the caller) | **fair; no gain** (`E-U $0`) |
| 5 | **Deposit single exact-in** (tag 4) | `trading_tokens_to_pool_tokens(..., Floor)` with fee on half the input | needs real tokens in | **fair (floor); no gain** |
| 6 | **Swap** (tag 1) | curve price + 25/10000 trade fee + 5/10000 owner fee; output rounded via `checked_ceil_div` (pool keeps the remainder); `minimum_amount_out` is the caller's own choice | deep reserves; trades are live today (aggregator routes at slots 457,161,704–457,163,289) | **open by design (normal AMM trading), not a bug**: quantified separately at **$4.22** realizable / $15,186.78 under DefiLlama prices (see `state-summary.md` §3) |
| 7 | **Host fee self-claim** (optional account #10 of `Swap`) | trader may name **any** token account of the pool mint as `host fee account`; 20 % of the *owner* fee is **minted** to it | owner fee = 5/10000 of input; host share = 1/10000 of input minted as LP | **net loss for the trader** (pays ≥ 25/10000 + 4/10000 of the owner fee for a 1/10000 LP rebate, plus price impact). `E-U $0` |
| 8 | **Initialize with someone else's vaults** (tag 0) | vaults must be token accounts **owned by `PDA([new_pool, nonce])`**; attacker can create token accounts owned by any PDA (owner needn't sign) but the PDA is keyed to *their own* new pool account | the 292 live vaults are owned by the PDA of their own pool; a collision requires grinding `create_program_address([new_pool, nonce]) == existing_authority` (2²⁵⁶ work) | **blocked**; the 48 uninitialised accounts hold only rent (0.151 SOL total) → `S` |
| 9 | **Initialize today** (tag 0) | `production` constraints: `fee_account.owner == HfoTxFR1…` (hard-coded), minimum fees, curve ∈ {ConstantProduct, ConstantPrice}; mint must have supply 0, no freeze authority, `mint_authority == PDA` | an attacker *can* create a new pool, but only with their own funded vaults — that is not extraction | **no value capture** |
| 10 | **Initialize with a fake token program** | `Initialize` stores `token_program_id = <account passed>` **without checking it is spl-token**; later instructions CPI into whatever was stored | a pool built this way has vaults under the attacker's fake program only if they hold no real tokens: any *real* value sits in Tokenkeg accounts, which the fake program cannot debit; the PDA's signer privilege does not let a fake program move another pool's vaults (they belong to a different PDA) | **not an extraction path for a third party** (self-inflicted pool only). Note for completeness: the live pools all store the genuine `Tokenkeg…` |
| 11 | **Fee account LP** | the accumulated owner fee is minted as LP into `pool_fee_account`, owned by `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN`; redeeming it needs that key's signature (`SourceInfo` burn authority) | **$140,698.78 realizable (68.9 % of live value)**, e.g. 7,854,478,786,491 of 12,264,607,061,681 LP in `AmHUjHK…` | **P** (third-party key; that key is active on-chain, 0.8 SOL, txs in 2026-09) |
| 12 | **Zero-supply pools** (85 pools, 11 with balance) | pre-#1637 build: `pool_tokens_to_trading_tokens` divides by `pool_mint.supply` → `ZeroTradingTokens`; single-sided deposit also returns 0 LP → `ZeroTradingTokens` | dust only: **$0.0486** | **S** (stuck; nobody, incl. the attacker, can revive them) |
| 13 | **Upgrade** | `BPFLoaderUpgradeab1e` with `upgrade_authority = DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn` (not revoked; account unfunded; key active 2022-03 → 2024-02). An earlier third-party upgrade attempt at slot 61,737,896 failed with `IncorrectAuthority` | the whole $204 k of pool value is upgradeable by that key holder; also all instructions/fees could change | **P** (privileged risk, not an E-U path) |
| 14 | Uninitialised pool accounts' rent | owned by the program; no close instruction exists | 48 × ~0.00315 SOL = 0.1509972 SOL (~$15.5) | **S** |

## The mission's specific questions

**(i) Can anyone withdraw from a pool's vaults without LP tokens?**
No. Both withdraw instructions perform an SPL-token `burn` from the caller-supplied LP account with
the caller as authority *before* any vault transfer. Proven on the live program by simulation
(`GATE-A`, `GATE-B` in `simulations.md`): `Tokenkeg … Error: insufficient funds`, tx error
`InstructionError [3, Custom(1)]`. The vault transfers are additionally PDA-signed, and the vaults
are pinned to the pool's stored accounts.
The only shape that would break this — a pool whose vault authority is *not* the derived PDA — does
not exist: **292/292** pools have `vault_a.owner == vault_b.owner == PDA([pool], nonce)` and
`pool_mint.mint_authority == PDA` (verified with an independent `solders` PDA derivation).

**(ii) Any mis-initialised pool / foreign authority?**
No. All 292 pools: `token_program_id = Tokenkeg…`, vaults are 165-byte Tokenkeg token accounts owned
by the PDA, `pool_mint` is a Tokenkeg mint with `mint_authority = PDA` and 0 freeze authority.
22 pools have a local "no market" side but that is a *market* property, not a state defect.

**(iii) Is the upgrade authority a live key / multisig?**
It is a **single key** `DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn` (not a multisig program
account). It signed the last upgrade (slot 73,737,036) and has activity as recently as slot
250,475,496 (2024-02-26); its account currently holds 0 lamports. It is **not** revoked.
(The brief's `7orsQE9o…` has no account and no signatures at all — see `state-summary.md` §4.)

**(iv) Are the fee accounts live, and who owns them?**
Yes — **all 292** `pool_fee_account`s are owned by `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN`
(0.8 SOL, txs in 2026-08/09). 188 pools have non-zero LP accrued in their fee account; by value the
fee accounts hold **$140.7 k of the $204.4 k** realizable TVL (68.9 %). That value is only
withdrawable by that key holder.

**(v) Any pool with absurd fees?**
No. 286 pools: trade 25/10000 (0.25 %), owner-trade 5/10000, owner-withdraw 0, host 20/100. 6 pools:
trade 0/10000, rest identical. No fee ≥ 100 %, no negative/garbage numerators, and the `production`
build in any case rejects fee structures below its minimums at `Initialize`.

**(vi) Rounding in the single-sided exact-out withdrawal — can it extract more than the LP burned is worth?**
No — the opposite. The deployed formula is the *pre-#1794* one, and the #1794 commit exists precisely
because it charged *more* than the "withdraw-both-then-swap" benchmark:
for a withdrawal of a fraction x = D/S of a reserve,
`deployed = √(1/(1−x)) − 1` vs `fair = 1 − √(1−x)`; the ratio is `1/√(1−x) > 1` (41 % more at x = 50 %).
The live program was verified to implement exactly this (observed burn 318,221,048,603 vs deployed
formula 318,221,048,611, i.e. 2.5×10⁻¹¹ relative; the post-fix formula would be 310,153,567,464,
2.54 % lower). Round-tripping a single-sided withdraw is therefore a *loss* to the attacker.

Related rounding facts (all in the pool's favour, none exploitable):
`pool_tokens_to_trading_tokens(..., Ceiling)` for deposits, `Floor` for withdrawals,
`checked_ceil_div` in the swap output, `calculate_fee` clamping a 0 fee up to **1 raw unit**, and
`map_zero_to_none` rejecting zero-output swaps.

## Summary

| category | amount | note |
|---|---|---|
| **E-U (external unprivileged, protocol bug)** | **$0** | every value-moving path is either gated by LP burn, priced fairly by the curve, or pays the attacker less than it costs |
| E-U (normal AMM arbitrage against stale reserves) | **$4.22** realizable | separate note, not a bug; $15,186.78 if dead Sollet tokens are valued at DefiLlama prices |
| H-O (LP holders redeem their share) | $63,652.21 | 31.1 % of realizable TVL is held by non-fee LP holders |
| P (program-owner fee key) | $140,698.78 | LP in `HfoTxFR1…`-owned fee accounts — needs that key |
| P (upgrade authority) | whole program | key `DpWjxjJE2SC…`, not revoked |
| S (stuck) | $0.0486 + 0.151 SOL rent | dust in 11 zero-supply pools + 48 uninitialised accounts |
