use crate::curve::fees::FEE_RATE_DENOMINATOR_VALUE;
use crate::error::ErrorCode;
use crate::states::*;
use anchor_lang::prelude::*;

#[derive(Accounts)]
pub struct UpdateAmmConfig<'info> {
    /// The amm config owner or admin
    #[account(address = crate::admin::ID @ ErrorCode::InvalidOwner)]
    pub owner: Signer<'info>,

    /// Amm config account to be changed
    #[account(mut)]
    pub amm_config: Account<'info, AmmConfig>,
}

pub fn update_amm_config(ctx: Context<UpdateAmmConfig>, param: u8, value: u64) -> Result<()> {
    let amm_config = &mut ctx.accounts.amm_config;
    // DEEP V1: each fee model has its own rate parameters. A config's fee model itself has
    // no parameter: it is fixed at creation, because switching it would leave every pool of
    // the config unpriceable.
    let is_v1 = amm_config.fee_model == FEE_MODEL_V1;
    match param {
        0 | 1 | 7 | 8 => require!(!is_v1, ErrorCode::FeeModelMismatch),
        10..=14 => require!(is_v1, ErrorCode::FeeModelMismatch),
        _ => {}
    }
    let match_param = Some(param);
    match match_param {
        Some(0) => update_trade_fee_rate(amm_config, value),
        Some(1) => update_protocol_fee_rate(amm_config, value),
        // DEEP: the fund fee is locked; only the compiled-in rate (V1: 0) and owner can be set.
        Some(2) => {
            require!(
                value == crate::deep_keys::BUILDER_FUND_FEE_RATE,
                ErrorCode::BuilderFeeLocked
            );
            update_fund_fee_rate(amm_config, value)
        }
        // DEEP V1: protocol_owner is locked to the fee vault. Only the compiled-in key can be
        // set (idempotent, so an existing AmmConfig can be moved to it once).
        Some(3) => {
            let new_procotol_owner = *ctx
                .remaining_accounts
                .iter()
                .next()
                .ok_or(ErrorCode::InvalidInput)?
                .key;
            require_keys_eq!(
                new_procotol_owner,
                crate::deep_keys::FEE_VAULT,
                ErrorCode::ProtocolOwnerLocked
            );
            set_new_protocol_owner(amm_config, new_procotol_owner)?;
        }
        Some(4) => {
            let new_fund_owner = *ctx.remaining_accounts.iter().next().unwrap().key;
            require_keys_eq!(
                new_fund_owner,
                crate::deep_keys::BUILDER,
                ErrorCode::BuilderFeeLocked
            );
            set_new_fund_owner(amm_config, new_fund_owner)?;
        }
        // DEEP (F2/F4): the create-pool fee has a hard cap, so it can neither block a
        // graduation nor surprise a pool creator.
        Some(5) => {
            require!(
                value <= crate::deep_keys::MAX_CREATE_POOL_FEE,
                ErrorCode::CreatePoolFeeAboveCap
            );
            amm_config.create_pool_fee = value
        }
        Some(6) => amm_config.disable_create_pool = if value == 0 { false } else { true },
        Some(7) => update_creator_fee_rate(amm_config, value),
        Some(8) => update_creator_fee_share_rate(amm_config, value),
        Some(10) => amm_config.buy_lp_fee_rate = value,
        Some(11) => amm_config.buy_protocol_fee_rate = value,
        Some(12) => amm_config.sell_lp_fee_rate = value,
        Some(13) => amm_config.sell_protocol_fee_rate = value,
        Some(14) => amm_config.max_reward_rate = value,
        _ => return err!(ErrorCode::InvalidInput),
    }
    if is_v1 {
        // DEEP V1: the 10% hard cap per side on the V1 rates, whatever was changed, and the
        // legacy fields kept as their mirror.
        amm_config.validate_v1_rates()?;
        amm_config.sync_legacy_mirror();
    }
    // DEEP V1: the 10% hard cap per side, whatever was changed.
    require!(
        amm_config.trade_fee_rate + amm_config.creator_fee_rate
            <= crate::deep_keys::MAX_TOTAL_FEE_RATE,
        ErrorCode::FeeRateAboveCap
    );

    Ok(())
}

fn update_protocol_fee_rate(amm_config: &mut Account<AmmConfig>, protocol_fee_rate: u64) {
    assert!(protocol_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
    assert!(protocol_fee_rate + amm_config.fund_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
    amm_config.protocol_fee_rate = protocol_fee_rate;
}

fn update_trade_fee_rate(amm_config: &mut Account<AmmConfig>, trade_fee_rate: u64) {
    assert!(trade_fee_rate + amm_config.creator_fee_rate < FEE_RATE_DENOMINATOR_VALUE);
    amm_config.trade_fee_rate = trade_fee_rate;
}

fn update_fund_fee_rate(amm_config: &mut Account<AmmConfig>, fund_fee_rate: u64) {
    assert!(fund_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
    assert!(fund_fee_rate + amm_config.protocol_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
    amm_config.fund_fee_rate = fund_fee_rate;
}

fn update_creator_fee_rate(amm_config: &mut Account<AmmConfig>, creator_fee_rate: u64) {
    assert!(creator_fee_rate + amm_config.trade_fee_rate < FEE_RATE_DENOMINATOR_VALUE);
    amm_config.creator_fee_rate = creator_fee_rate;
}

fn update_creator_fee_share_rate(
    amm_config: &mut Account<AmmConfig>,
    creator_fee_share_rate: u64,
) {
    assert!(creator_fee_share_rate <= FEE_RATE_DENOMINATOR_VALUE);
    amm_config.creator_fee_share_rate = creator_fee_share_rate;
}

fn set_new_protocol_owner(amm_config: &mut Account<AmmConfig>, new_owner: Pubkey) -> Result<()> {
    require_keys_neq!(new_owner, Pubkey::default());
    #[cfg(feature = "enable-log")]
    msg!(
        "amm_config, old_protocol_owner:{}, new_owner:{}",
        amm_config.protocol_owner.to_string(),
        new_owner.key().to_string()
    );
    amm_config.protocol_owner = new_owner;
    Ok(())
}

fn set_new_fund_owner(amm_config: &mut Account<AmmConfig>, new_fund_owner: Pubkey) -> Result<()> {
    require_keys_neq!(new_fund_owner, Pubkey::default());
    #[cfg(feature = "enable-log")]
    msg!(
        "amm_config, old_fund_owner:{}, new_fund_owner:{}",
        amm_config.fund_owner.to_string(),
        new_fund_owner.key().to_string()
    );
    amm_config.fund_owner = new_fund_owner;
    Ok(())
}
