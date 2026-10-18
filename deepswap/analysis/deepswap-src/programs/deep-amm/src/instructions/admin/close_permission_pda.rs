use crate::error::ErrorCode;
use crate::states::*;
use anchor_lang::prelude::*;

#[derive(Accounts)]
pub struct ClosePermissionPda<'info> {
    #[account(
        mut,
        constraint = (owner.key() == crate::admin::ID || owner.key() == crate::create_permission_pda_owner::ID) @ ErrorCode::InvalidOwner
    )]
    pub owner: Signer<'info>,

    /// CHECK: permission account authority. DEEP (F2): never deep-curve's graduation payer,
    /// whose permission is permanent.
    #[account(
        constraint = permission_authority.key() != crate::deep_keys::GRADUATION_PAYER @ ErrorCode::GraduationPermissionLocked
    )]
    pub permission_authority: UncheckedAccount<'info>,

    /// Initialize config state account to store protocol owner address and fee rates.
    #[account(
        mut,
        seeds = [
            PERMISSION_SEED.as_bytes(),
            permission_authority.key().as_ref()
        ],
        bump,
        close = owner
    )]
    pub permission: Account<'info, Permission>,

    pub system_program: Program<'info, System>,
}

pub fn close_permission_pda(_ctx: Context<ClosePermissionPda>) -> Result<()> {
    Ok(())
}
