//! Victim program from GHSA-c6rc-8jpp-2fgc (the advisory PoC, verbatim in spirit).
//!
//! It declares `system_program: Program<'info, System>` (which SHOULD pin the id
//! to the real system program) and then builds a system `Transfer` instruction
//! whose `program_id` is `ctx.accounts.system_program.key()`. On anchor-lang
//! 1.0.0 / 1.0.1 that key is never checked, so an attacker can pass their own
//! executable program and the "transfer" is redirected to it (payment bypass).
//!
//! The anchor-lang version is injected at build time (see ci/run.sh).
use anchor_lang::prelude::*;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::program::invoke;

declare_id!("2X5QMM3RqSfonKwgDntLRm5g4oeQGtVsMouoVkwsiEM1");

#[program]
pub mod victim {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, amount: u64) -> Result<()> {
        // Build a system Transfer instruction, but target whatever program the
        // caller passed as `system_program`.
        let mut data = Vec::new();
        data.extend_from_slice(&[2, 0, 0, 0]); // SystemInstruction::Transfer
        data.extend_from_slice(&amount.to_le_bytes());
        let accounts = vec![
            AccountMeta::new(ctx.accounts.sender.key(), true),
            AccountMeta::new(ctx.accounts.recipient.key(), false),
        ];
        let ix = Instruction {
            program_id: ctx.accounts.system_program.key(),
            accounts,
            data,
        };
        let infos = [
            ctx.accounts.sender.to_account_info(),
            ctx.accounts.recipient.to_account_info(),
            ctx.accounts.system_program.to_account_info(),
        ];
        invoke(&ix, &infos)?;
        msg!("victim: invoked 'system program' = {}", ctx.accounts.system_program.key());
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub sender: Signer<'info>,
    /// CHECK: any system-owned account
    #[account(mut)]
    pub recipient: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}
