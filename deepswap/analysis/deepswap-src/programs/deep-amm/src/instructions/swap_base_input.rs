use crate::curve::calculator::CurveCalculator;
use crate::error::ErrorCode;
use crate::states::*;
use crate::utils::token::*;
use anchor_lang::prelude::*;
use anchor_lang::solana_program;
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct Swap<'info> {
    /// The user performing the swap
    pub payer: Signer<'info>,

    /// CHECK: pool vault and lp mint authority
    #[account(
        seeds = [
            crate::AUTH_SEED.as_bytes(),
        ],
        bump,
    )]
    pub authority: UncheckedAccount<'info>,

    /// The factory state to read protocol fees
    #[account(address = pool_state.load()?.amm_config)]
    pub amm_config: Box<Account<'info, AmmConfig>>,

    /// The program account of the pool in which the swap will be performed
    #[account(mut)]
    pub pool_state: AccountLoader<'info, PoolState>,

    /// The user token account for input token
    #[account(mut)]
    pub input_token_account: Box<InterfaceAccount<'info, TokenAccount>>,

    /// The user token account for output token
    #[account(mut)]
    pub output_token_account: Box<InterfaceAccount<'info, TokenAccount>>,

    /// The vault token account for input token
    #[account(
        mut,
        constraint = input_vault.key() == pool_state.load()?.token_0_vault || input_vault.key() == pool_state.load()?.token_1_vault
    )]
    pub input_vault: Box<InterfaceAccount<'info, TokenAccount>>,

    /// The vault token account for output token
    #[account(
        mut,
        constraint = output_vault.key() == pool_state.load()?.token_0_vault || output_vault.key() == pool_state.load()?.token_1_vault
    )]
    pub output_vault: Box<InterfaceAccount<'info, TokenAccount>>,

    /// SPL program for input token transfers
    pub input_token_program: Interface<'info, TokenInterface>,

    /// SPL program for output token transfers
    pub output_token_program: Interface<'info, TokenInterface>,

    /// The mint of input token
    #[account(
        address = input_vault.mint
    )]
    pub input_token_mint: Box<InterfaceAccount<'info, Mint>>,

    /// The mint of output token
    #[account(
        address = output_vault.mint
    )]
    pub output_token_mint: Box<InterfaceAccount<'info, Mint>>,
    /// The program account for the most recent oracle observation
    #[account(mut, address = pool_state.load()?.observation_key)]
    pub observation_state: AccountLoader<'info, ObservationState>,
}

/// DEEP V1: the fee model a swap is priced with. The pool and its AmmConfig must agree (a
/// config's model never changes and a pool takes it at creation, so a mismatch means
/// corrupted state): a legacy pool is never priced with V1 rates and vice versa.
pub fn swap_fee_model(pool_state: &PoolState, amm_config: &AmmConfig) -> Result<u8> {
    let fee_model = pool_state.fee_model;
    require_eq!(
        fee_model,
        amm_config.fee_model,
        ErrorCode::FeeModelMismatch
    );
    require!(
        fee_model == FEE_MODEL_LEGACY || fee_model == FEE_MODEL_V1,
        ErrorCode::FeeModelMismatch
    );
    Ok(fee_model)
}

/// DEEP V1: the fee parts of one V1 swap, all in the quote token (see `SwapFeesV1`).
pub fn emit_swap_fees_v1(
    pool_id: Pubkey,
    pool_state: &PoolState,
    result: &crate::curve::calculator::SwapResult,
    is_buy: bool,
    quote_mint: Pubkey,
) {
    emit!(SwapFeesV1 {
        pool_id,
        is_buy,
        quote_mint,
        lp_fee: u64::try_from(result.trade_fee - result.protocol_fee).unwrap(),
        protocol_fee: u64::try_from(result.protocol_fee).unwrap(),
        reward_fee: u64::try_from(result.creator_fee).unwrap(),
        reward_model: pool_state.reward_model,
    });
}

pub fn swap_base_input(ctx: Context<Swap>, amount_in: u64, minimum_amount_out: u64) -> Result<()> {
    let block_timestamp = solana_program::clock::Clock::get()?.unix_timestamp as u64;
    let pool_id = ctx.accounts.pool_state.key();
    let pool_state = &mut ctx.accounts.pool_state.load_mut()?;
    if !pool_state.get_status_by_bit(PoolStatusBitIndex::Swap)
        || block_timestamp < pool_state.open_time
    {
        return err!(ErrorCode::NotApproved);
    }

    let transfer_fee =
        get_transfer_fee(&ctx.accounts.input_token_mint.to_account_info(), amount_in)?;
    // Take transfer fees into account for actual amount transferred in
    let actual_amount_in = amount_in.saturating_sub(transfer_fee);
    require_gt!(actual_amount_in, 0);

    let SwapParams {
        trade_direction,
        total_input_token_amount,
        total_output_token_amount,
        token_0_price_x64,
        token_1_price_x64,
        is_creator_fee_on_input,
    } = pool_state.get_swap_params(
        ctx.accounts.input_vault.key(),
        ctx.accounts.output_vault.key(),
        ctx.accounts.input_vault.amount,
        ctx.accounts.output_vault.amount,
    )?;
    let constant_before = u128::from(total_input_token_amount)
        .checked_mul(u128::from(total_output_token_amount))
        .unwrap();

    // DEEP V1: a pool is priced with the fee model it was created under, and only by a
    // config of that same model. A V1 pool's fee side is its quote token, so "creator fee on
    // input" reads "the input is the quote token": a buy.
    let is_v1 = swap_fee_model(pool_state, &ctx.accounts.amm_config)? == FEE_MODEL_V1;
    let result = if is_v1 {
        let rates = pool_state.v1_rates(&ctx.accounts.amm_config, is_creator_fee_on_input)?;
        crate::curve::v1::swap_base_input_v1(
            u128::from(actual_amount_in),
            u128::from(total_input_token_amount),
            u128::from(total_output_token_amount),
            rates.lp,
            rates.protocol,
            rates.reward,
            is_creator_fee_on_input,
        )
    } else {
        let creator_fee_rate =
            pool_state.adjust_creator_fee_rate(ctx.accounts.amm_config.creator_fee_rate);
        CurveCalculator::swap_base_input(
            u128::from(actual_amount_in),
            u128::from(total_input_token_amount),
            u128::from(total_output_token_amount),
            ctx.accounts.amm_config.trade_fee_rate,
            creator_fee_rate,
            ctx.accounts.amm_config.protocol_fee_rate,
            ctx.accounts.amm_config.fund_fee_rate,
            is_creator_fee_on_input,
        )
    }
    .ok_or(ErrorCode::ZeroTradingTokens)?;

    let constant_after = u128::from(result.new_input_vault_amount)
        .checked_mul(u128::from(result.new_output_vault_amount))
        .unwrap();
    #[cfg(feature = "enable-log")]
    msg!(
        "input_amount:{}, output_amount:{}, trade_fee:{}, input_transfer_fee:{}, constant_before:{},constant_after:{}, is_creator_fee_on_input:{}, creator_fee:{}",
        result.input_amount,
        result.output_amount,
        result.trade_fee,
        transfer_fee,
        constant_before,
        constant_after,
        is_creator_fee_on_input,
        result.creator_fee,
    );
    require_eq!(
        u64::try_from(result.input_amount).unwrap(),
        actual_amount_in
    );
    let (input_transfer_amount, input_transfer_fee) = (amount_in, transfer_fee);
    let (output_transfer_amount, output_transfer_fee) = {
        let amount_out = u64::try_from(result.output_amount).unwrap();
        let transfer_fee = get_transfer_fee(
            &ctx.accounts.output_token_mint.to_account_info(),
            amount_out,
        )?;
        let amount_received = amount_out.checked_sub(transfer_fee).unwrap();
        require_gt!(amount_received, 0);
        require_gte!(
            amount_received,
            minimum_amount_out,
            ErrorCode::ExceededSlippage
        );
        (amount_out, transfer_fee)
    };

    if is_v1 {
        pool_state.update_fees_v1(
            u64::try_from(result.protocol_fee).unwrap(),
            u64::try_from(result.creator_fee).unwrap(),
            trade_direction,
            is_creator_fee_on_input,
        )?;
    } else {
        pool_state.update_fees(
            u64::try_from(result.protocol_fee).unwrap(),
            u64::try_from(result.fund_fee).unwrap(),
            u64::try_from(result.creator_fee).unwrap(),
            trade_direction,
        )?;
    }

    emit!(SwapEvent {
        pool_id,
        input_vault_before: total_input_token_amount,
        output_vault_before: total_output_token_amount,
        input_amount: u64::try_from(result.input_amount).unwrap(),
        output_amount: u64::try_from(result.output_amount).unwrap(),
        input_transfer_fee,
        output_transfer_fee,
        base_input: true,
        input_mint: ctx.accounts.input_token_mint.key(),
        output_mint: ctx.accounts.output_token_mint.key(),
        trade_fee: u64::try_from(result.trade_fee).unwrap(),
        creator_fee: u64::try_from(result.creator_fee).unwrap(),
        creator_fee_on_input: is_creator_fee_on_input,
    });
    if is_v1 {
        emit_swap_fees_v1(
            pool_id,
            pool_state,
            &result,
            is_creator_fee_on_input,
            if is_creator_fee_on_input {
                ctx.accounts.input_token_mint.key()
            } else {
                ctx.accounts.output_token_mint.key()
            },
        );
    }
    require_gte!(constant_after, constant_before);

    transfer_from_user_to_pool_vault(
        ctx.accounts.payer.to_account_info(),
        ctx.accounts.input_token_account.to_account_info(),
        ctx.accounts.input_vault.to_account_info(),
        ctx.accounts.input_token_mint.to_account_info(),
        ctx.accounts.input_token_program.to_account_info(),
        input_transfer_amount,
        ctx.accounts.input_token_mint.decimals,
    )?;

    transfer_from_pool_vault_to_user(
        ctx.accounts.authority.to_account_info(),
        ctx.accounts.output_vault.to_account_info(),
        ctx.accounts.output_token_account.to_account_info(),
        ctx.accounts.output_token_mint.to_account_info(),
        ctx.accounts.output_token_program.to_account_info(),
        output_transfer_amount,
        ctx.accounts.output_token_mint.decimals,
        &[&[crate::AUTH_SEED.as_bytes(), &[pool_state.auth_bump]]],
    )?;

    // update the previous price to the observation
    ctx.accounts.observation_state.load_mut()?.update(
        oracle::block_timestamp(),
        token_0_price_x64,
        token_1_price_x64,
    )?;
    pool_state.recent_epoch = Clock::get()?.epoch;

    Ok(())
}
