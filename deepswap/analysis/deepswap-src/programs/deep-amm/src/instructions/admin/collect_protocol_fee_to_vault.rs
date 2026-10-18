//! DEEP V1 (Phase 1): permissionless collection of DEEP's DeepSwap protocol fees into the fee
//! vault. New file, not in upstream (see NOTICE, modification 7).
//!
//! `amm_config.protocol_owner` can only be `deep_keys::FEE_VAULT` (update_config param 3 and
//! create_config are locked), and each recipient must be the protocol owner's associated token
//! account for that side's mint. The destination is therefore fixed by the build, so anyone may
//! trigger the move; the deep-curve fee splitter pays the builder its 10% before anyone else.
//!
//! Each side is collected on its own (security review F8): a side with nothing accrued, or
//! whose recipient cannot take the transfer right now (missing, not an initialized token account
//! of that mint, frozen), is skipped and stays accrued; it never blocks the other side. The
//! call fails with `NoFeeCollect` only when nothing at all could be moved.
use crate::error::ErrorCode;
use crate::states::*;
use crate::utils::*;
use anchor_lang::prelude::*;
use anchor_spl::associated_token::get_associated_token_address_with_program_id;
use anchor_spl::token::Token;
use anchor_spl::token_2022::spl_token_2022::{
    extension::StateWithExtensions,
    state::{Account as SplTokenAccount, AccountState},
};
use anchor_spl::token_interface::Mint;
use anchor_spl::token_interface::Token2022;
use anchor_spl::token_interface::TokenAccount;

#[derive(Accounts)]
pub struct CollectProtocolFeeToVault<'info> {
    /// CHECK: pool vault and lp mint authority
    #[account(
        seeds = [
            crate::AUTH_SEED.as_bytes(),
        ],
        bump,
    )]
    pub authority: UncheckedAccount<'info>,

    /// Pool state stores accumulated protocol fee amount
    #[account(mut)]
    pub pool_state: AccountLoader<'info, PoolState>,

    /// Amm config account stores the protocol owner (the fee vault)
    #[account(address = pool_state.load()?.amm_config)]
    pub amm_config: Account<'info, AmmConfig>,

    /// The address that holds pool tokens for token_0
    #[account(
        mut,
        constraint = token_0_vault.key() == pool_state.load()?.token_0_vault
    )]
    pub token_0_vault: Box<InterfaceAccount<'info, TokenAccount>>,

    /// The address that holds pool tokens for token_1
    #[account(
        mut,
        constraint = token_1_vault.key() == pool_state.load()?.token_1_vault
    )]
    pub token_1_vault: Box<InterfaceAccount<'info, TokenAccount>>,

    /// The mint of token_0 vault
    #[account(
        address = token_0_vault.mint
    )]
    pub vault_0_mint: Box<InterfaceAccount<'info, Mint>>,

    /// The mint of token_1 vault
    #[account(
        address = token_1_vault.mint
    )]
    pub vault_1_mint: Box<InterfaceAccount<'info, Mint>>,

    /// CHECK: must be ATA(vault_0_mint, protocol_owner) under vault_0_mint's token program
    /// (checked in the handler). When it cannot receive, token_0 fees stay accrued.
    #[account(mut)]
    pub recipient_token_0_account: UncheckedAccount<'info>,

    /// CHECK: must be ATA(vault_1_mint, protocol_owner) under vault_1_mint's token program
    /// (checked in the handler). When it cannot receive, token_1 fees stay accrued.
    #[account(mut)]
    pub recipient_token_1_account: UncheckedAccount<'info>,

    /// The SPL program to perform token transfers
    pub token_program: Program<'info, Token>,

    /// The SPL program 2022 to perform token transfers
    pub token_program_2022: Program<'info, Token2022>,
}

pub fn collect_protocol_fee_to_vault(ctx: Context<CollectProtocolFeeToVault>) -> Result<()> {
    let owner = ctx.accounts.amm_config.protocol_owner;
    // A config not (yet) moved to the vault cannot be drained through this path.
    require_keys_eq!(
        owner,
        crate::deep_keys::FEE_VAULT,
        ErrorCode::InvalidProtocolFeeRecipient
    );

    let mint_0 = ctx.accounts.vault_0_mint.to_account_info();
    let mint_1 = ctx.accounts.vault_1_mint.to_account_info();
    let program_0 = if mint_0.owner == ctx.accounts.token_program.key {
        ctx.accounts.token_program.to_account_info()
    } else {
        ctx.accounts.token_program_2022.to_account_info()
    };
    let program_1 = if mint_1.owner == ctx.accounts.token_program.key {
        ctx.accounts.token_program.to_account_info()
    } else {
        ctx.accounts.token_program_2022.to_account_info()
    };
    require_keys_eq!(
        ctx.accounts.recipient_token_0_account.key(),
        get_associated_token_address_with_program_id(&owner, mint_0.key, program_0.key),
        ErrorCode::InvalidProtocolFeeRecipient
    );
    require_keys_eq!(
        ctx.accounts.recipient_token_1_account.key(),
        get_associated_token_address_with_program_id(&owner, mint_1.key, program_1.key),
        ErrorCode::InvalidProtocolFeeRecipient
    );

    // What each side moves: its accrued fee when the recipient can take it, otherwise 0.
    let can_0 = can_receive(
        &ctx.accounts.recipient_token_0_account,
        mint_0.key,
        program_0.key,
    );
    let can_1 = can_receive(
        &ctx.accounts.recipient_token_1_account,
        mint_1.key,
        program_1.key,
    );
    let amount_0: u64;
    let amount_1: u64;
    let auth_bump: u8;
    {
        let mut pool_state = ctx.accounts.pool_state.load_mut()?;
        amount_0 = if can_0 {
            pool_state.protocol_fees_token_0
        } else {
            0
        };
        amount_1 = if can_1 {
            pool_state.protocol_fees_token_1
        } else {
            0
        };
        require!(amount_0 > 0 || amount_1 > 0, ErrorCode::NoFeeCollect);
        // only a side that is transferred below is zeroed; a skipped side stays accrued
        pool_state.protocol_fees_token_0 -= amount_0;
        pool_state.protocol_fees_token_1 -= amount_1;
        auth_bump = pool_state.auth_bump;
        pool_state.recent_epoch = Clock::get()?.epoch;
    }

    // transfer_from_pool_vault_to_user is a no-op for 0.
    transfer_from_pool_vault_to_user(
        ctx.accounts.authority.to_account_info(),
        ctx.accounts.token_0_vault.to_account_info(),
        ctx.accounts.recipient_token_0_account.to_account_info(),
        mint_0,
        program_0,
        amount_0,
        ctx.accounts.vault_0_mint.decimals,
        &[&[crate::AUTH_SEED.as_bytes(), &[auth_bump]]],
    )?;
    transfer_from_pool_vault_to_user(
        ctx.accounts.authority.to_account_info(),
        ctx.accounts.token_1_vault.to_account_info(),
        ctx.accounts.recipient_token_1_account.to_account_info(),
        mint_1,
        program_1,
        amount_1,
        ctx.accounts.vault_1_mint.decimals,
        &[&[crate::AUTH_SEED.as_bytes(), &[auth_bump]]],
    )?;
    Ok(())
}

/// True when `recipient` can take a token transfer of `mint` right now: it is owned by the
/// mint's token program, is an initialized (not frozen) token account, and is of that mint.
/// Checked before anything moves, because a failed transfer CPI cannot be caught.
fn can_receive(recipient: &AccountInfo, mint: &Pubkey, token_program: &Pubkey) -> bool {
    if recipient.owner != token_program {
        return false;
    }
    let Ok(data) = recipient.try_borrow_data() else {
        return false;
    };
    match StateWithExtensions::<SplTokenAccount>::unpack(&data) {
        Ok(account) => {
            account.base.state == AccountState::Initialized && account.base.mint == *mint
        }
        Err(_) => false,
    }
}
