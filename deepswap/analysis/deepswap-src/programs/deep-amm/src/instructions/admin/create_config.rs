use crate::error::ErrorCode;
use crate::states::*;
use anchor_lang::prelude::*;
use std::ops::DerefMut;

#[derive(Accounts)]
#[instruction(index: u16)]
pub struct CreateAmmConfig<'info> {
    /// Address to be set as protocol owner.
    #[account(
        mut,
        address = crate::admin::ID @ ErrorCode::InvalidOwner
    )]
    pub owner: Signer<'info>,

    /// Initialize config state account to store protocol owner address and fee rates.
    #[account(
        init,
        seeds = [
            AMM_CONFIG_SEED.as_bytes(),
            &index.to_be_bytes()
        ],
        bump,
        payer = owner,
        space = AmmConfig::LEN
    )]
    pub amm_config: Account<'info, AmmConfig>,

    pub system_program: Program<'info, System>,
}

pub fn create_amm_config(
    ctx: Context<CreateAmmConfig>,
    index: u16,
    trade_fee_rate: u64,
    protocol_fee_rate: u64,
    fund_fee_rate: u64,
    create_pool_fee: u64,
    creator_fee_rate: u64,
) -> Result<()> {
    // DEEP V1: the fund fee is retired (rate 0, BUILDER_FUND_FEE_RATE; the owner stays the
    // builder, fund_fee_owner::ID below); protocol_owner is the fee vault (protocol_fee_owner::ID).
    require!(
        fund_fee_rate == crate::deep_keys::BUILDER_FUND_FEE_RATE,
        ErrorCode::BuilderFeeLocked
    );
    require!(
        trade_fee_rate.saturating_add(creator_fee_rate) <= crate::deep_keys::MAX_TOTAL_FEE_RATE,
        ErrorCode::FeeRateAboveCap
    );
    require!(
        create_pool_fee <= crate::deep_keys::MAX_CREATE_POOL_FEE,
        ErrorCode::CreatePoolFeeAboveCap
    );
    let amm_config = ctx.accounts.amm_config.deref_mut();
    amm_config.protocol_owner = crate::protocol_fee_owner::ID;
    amm_config.bump = ctx.bumps.amm_config;
    amm_config.disable_create_pool = false;
    amm_config.index = index;
    amm_config.trade_fee_rate = trade_fee_rate;
    amm_config.protocol_fee_rate = protocol_fee_rate;
    amm_config.fund_fee_rate = fund_fee_rate;
    amm_config.create_pool_fee = create_pool_fee;
    amm_config.fund_owner = crate::fund_fee_owner::ID;
    amm_config.creator_fee_rate = creator_fee_rate;
    Ok(())
}

/// DEEP V1: creates a V1 AmmConfig. New instruction, not in upstream (NOTICE, modification 8).
pub fn create_amm_config_v1(
    ctx: Context<CreateAmmConfig>,
    index: u16,
    create_pool_fee: u64,
    buy_lp_fee_rate: u64,
    buy_protocol_fee_rate: u64,
    sell_lp_fee_rate: u64,
    sell_protocol_fee_rate: u64,
) -> Result<()> {
    require!(
        create_pool_fee <= crate::deep_keys::MAX_CREATE_POOL_FEE,
        ErrorCode::CreatePoolFeeAboveCap
    );
    let amm_config = ctx.accounts.amm_config.deref_mut();
    amm_config.protocol_owner = crate::protocol_fee_owner::ID;
    amm_config.bump = ctx.bumps.amm_config;
    amm_config.disable_create_pool = false;
    amm_config.index = index;
    amm_config.fund_fee_rate = crate::deep_keys::BUILDER_FUND_FEE_RATE;
    amm_config.create_pool_fee = create_pool_fee;
    amm_config.fund_owner = crate::fund_fee_owner::ID;
    amm_config.fee_model = FEE_MODEL_V1;
    amm_config.buy_lp_fee_rate = buy_lp_fee_rate;
    amm_config.buy_protocol_fee_rate = buy_protocol_fee_rate;
    amm_config.sell_lp_fee_rate = sell_lp_fee_rate;
    amm_config.sell_protocol_fee_rate = sell_protocol_fee_rate;
    // the current maximum reward rate for new pools starts at the ceiling (param 14 lowers it)
    amm_config.max_reward_rate = crate::deep_keys::MAX_REWARD_RATE;
    amm_config.validate_v1_rates()?;
    amm_config.sync_legacy_mirror();
    Ok(())
}
