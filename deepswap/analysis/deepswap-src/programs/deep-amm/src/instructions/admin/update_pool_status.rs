use crate::error::ErrorCode;
use crate::states::*;
use anchor_lang::prelude::*;

/// DEEP (F4): the only status bits the admin can set: deposits and swaps. The withdraw bit
/// (and every unknown bit) is rejected, and `withdraw` no longer reads the status at all, so an
/// LP can always exit, whatever a pool's stored status is. Fee collection never read it.
pub const SETTABLE_POOL_STATUS_BITS: u8 =
    (1 << PoolStatusBitIndex::Deposit as u8) | (1 << PoolStatusBitIndex::Swap as u8);

#[derive(Accounts)]
pub struct UpdatePoolStatus<'info> {
    #[account(
        address = crate::admin::ID
    )]
    pub authority: Signer<'info>,

    #[account(mut)]
    pub pool_state: AccountLoader<'info, PoolState>,
}

pub fn update_pool_status(ctx: Context<UpdatePoolStatus>, status: u8) -> Result<()> {
    require_gte!(255, status);
    require!(
        status & !SETTABLE_POOL_STATUS_BITS == 0,
        ErrorCode::InvalidPoolStatus
    );
    let mut pool_state = ctx.accounts.pool_state.load_mut()?;
    pool_state.set_status(status);
    pool_state.recent_epoch = Clock::get()?.epoch;
    Ok(())
}
