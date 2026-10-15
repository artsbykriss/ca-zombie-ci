# Evidence trace — C2-40 Saber (code + runtime citations)

All line numbers from the commits/files as inspected on 2026-10-15.

## Saber (saber-hq/stable-swap)

Deploy-era commit ≈ `91c6203` (2022-01-02). Post-deploy program/math logic change: `05650f9` (2022-02-25, "Patch rounding issue (#132)") — **not deployed** (last upgrade 2022-02-07).

| Claim | File | Evidence |
|---|---|---|
| Withdraw validates LP mint | `stable-swap-program/program/src/processor/swap.rs` (`process_withdraw`) | `check_keys_equal!(*pool_mint_info.key, token_swap.pool_mint, "Pool mint", SwapError::IncorrectMint)` — present at commit `5db776f` (2021-11-14) through HEAD |
| Withdraw has **no** `is_paused` check | same | only `process_swap`/`process_deposit`/`process_withdraw_one` check `is_paused` |
| Vaults/admin-fee accounts bound to stored state | `processor/checks.rs` (`check_withdraw_token_accounts`, `check_swap_token_destination_accounts`, `check_deposit_token_accounts`) | key equality against `SwapTokenInfo.reserves` / `.admin_fees` |
| Authority must be `PDA(swap, nonce)` | `processor/checks.rs` (`check_swap_authority`) + `processor/utils.rs` (`authority_id` = `create_program_address([swap, nonce])`) | called by swap/deposit/withdraw/withdraw_one/initialize |
| Admin gated by key + signer | `processor/checks.rs` (`check_has_admin_signer`), `processor/admin.rs` | no fund-moving admin instruction exists; admin transfer has 3-day timelock (`ADMIN_TRANSFER_DELAY = 259200`) |
| **token_program id validated by the SPL-Token SDK** | `processor/token.rs` + `spl-token` 3.x `src/lib.rs:82` | `token.rs` passes `token_program.key` into `spl_token::instruction::{transfer,mint_to,burn}`; each calls `check_program_account(token_program_id)?` → `Err(ProgramError::IncorrectProgramId)` for any id != Tokenkeg. Proven on the deployed bytecode: fake token program → `Error: IncorrectProgramId`, attacker program never invoked (PoC T2) |
| Rounding patch content | `stable-swap-math/src/curve.rs` @ `05650f9` | `- let dy = swap_destination_account.checked_sub(y)?;` → `+ …checked_sub(1)?` (only non-test change) |

## Agave runtime (CPI account rule)

| Claim | File | Evidence |
|---|---|---|
| SBF CPI path verifies accounts | `program-runtime/src/cpi.rs` (anza-xyz/agave, master @ 2026-10-15) | `invoke_context.build_instruction_frame(instruction)?; invoke_context.verify_instruction_accounts(&signers)?;` (lines 821–822) |
| Callee program account must be in caller's instruction accounts | `program-runtime/src/invoke_context.rs` (`verify_instruction_accounts`, lines ~379–392) | `let program_id_tx_idx = next_context.get_index_of_program_account_in_transaction()?; if instruction_context.get_index_of_account_in_instruction(program_id_tx_idx).is_err() { ic_msg!("Unknown program {}", …); return Err(InstructionError::MissingAccount); }` |
| Signer (PDA) privileges propagate only to callee accounts | same function, lines ~369–376 | "signer privilege escalated" check: callee signer requires caller signer or `invoke_signed` seeds |

## On-chain anchors (mainnet, slot 457,257,871 unless noted)

| Item | Value |
|---|---|
| Saber program | `SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ` (owner `BPFLoaderUpgradeab1e…`, executable) |
| Saber ProgramData | `54aePuBcYcf8G3CDrWWd2MEiw6Q7UGy2kjgQBDhqoMdt`; `slot=119721738`; bytecode 609,792 B |
| Last upgrade tx | `5ygvjFAXLwknuRLZVFNCCExmdPcvaTYEeYxHXv8JAWCT1cz6dgbnJ734mZaaCMcZeDQpdxFegrcwcwGKCratGiwb` (blockTime 1644216349 = 2022-02-07 08:05:49 UTC; logs "Upgraded program SSwpkEE…"; executed via Goki smart wallet `GokivDYuQ…`) |
| Upgrade authority | `EVmbDJCTGeExFGUKxmZwrfnzw4zpf7SPhPgfiLDJkUEV` (off-curve PDA, 13.319 SOL, 0 data) |
| SetAuthority tx | `3kGAgqXoA8EgDvSrdg9jzZL5oFNW3GpfwjzokQkEP63qAwn2PRy9zusUXak6wJXGZoVYHooe4MsXmd6fY5pZii5H` (slot 422,671,196; blockTime 1779951890; BPF-loader inner ix data `04000000` = SetAuthority; log "New authority Some(EVmbDJ…)") |
| SPL Token program | `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`; ProgramData `3gvYRKWyXRR9xKWe1ZjPhLY5ZJRN7KDB4rFZFGoJfFk2`; last ProgramData write slot 419,472,000; authority None; still accepts legacy 3-account `Transfer` (live Saber swap through Jupiter succeeds) |
| Example live swap | `3Y3f5GzQLA18PjWSuyBdTUHM8Q1iXGSrCzNDqBZUqUw2S21BDxjBEhRHYYsvG4V8WkQoBLxhq7RT5scCecQP7H4c` (slot 457,259,071; JUP6 route → Saber swap, 3 Tokenkeg CPIs, success) |
| Pool used in PoC | `YAkoNb6HKmSxQN9L8hiBE5tPJRsniSSMzND1boHmZxe` (USDC/USDT; nonce 255; authority `5C1k9yV7y4CjMnKv8eGYDgWND8P89Pdfj79Trk2qmfGo`; vaults `CfWX7o2T…` / `EnTrdMMp…`; LP mint `2poo1w1D…`) |
| Prior CASH context | Cashio (2022-03-23, ~$48–53M) was exploited via Cashio's own missing validation of Saber-LP `.mint` fields — the fake-LP tokens drained **Cashio**, not Saber; the CASH residue in Saber pools is dead (sCASH-8/9 ≈ $49.0M nominal at DefiLlama's stale $1 price) |
