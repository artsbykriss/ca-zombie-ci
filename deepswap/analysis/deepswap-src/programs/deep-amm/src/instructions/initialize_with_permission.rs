use crate::curve::CurveCalculator;
use crate::error::ErrorCode;
use crate::initialize::create_pool;
use crate::states::*;
use crate::utils::*;
use anchor_lang::{
    accounts::interface_account::InterfaceAccount,
    prelude::*,
    solana_program::{clock, program::invoke, system_instruction},
};
use anchor_spl::token_2022::spl_token_2022;
use anchor_spl::{
    associated_token::AssociatedToken,
    token::spl_token,
    token::Token,
    token_interface::{Mint, TokenAccount, TokenInterface},
};
use std::ops::Deref;

#[derive(Accounts)]
pub struct InitializeWithPermission<'info> {
    /// Address paying to create the pool. Can be anyone
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: creator of pool
    pub creator: UncheckedAccount<'info>,

    /// Which config the pool belongs to.
    pub amm_config: Box<Account<'info, AmmConfig>>,

    /// CHECK:
    /// pool vault and lp mint authority
    #[account(
        seeds = [
            crate::AUTH_SEED.as_bytes(),
        ],
        bump,
    )]
    pub authority: UncheckedAccount<'info>,

    /// CHECK: Initialize an account to store the pool state
    /// PDA account:
    /// seeds = [
    ///     POOL_SEED.as_bytes(),
    ///     amm_config.key().as_ref(),
    ///     token_0_mint.key().as_ref(),
    ///     token_1_mint.key().as_ref(),
    /// ],
    ///
    /// Or random account: must be signed by cli
    #[account(mut)]
    pub pool_state: UncheckedAccount<'info>,

    /// Token_0 mint, the key must smaller than token_1 mint.
    #[account(
        constraint = token_0_mint.key() < token_1_mint.key(),
        mint::token_program = token_0_program,
    )]
    pub token_0_mint: Box<InterfaceAccount<'info, Mint>>,

    /// Token_1 mint, the key must grater then token_0 mint.
    #[account(
        mint::token_program = token_1_program,
    )]
    pub token_1_mint: Box<InterfaceAccount<'info, Mint>>,

    /// pool lp mint
    #[account(
        init,
        seeds = [
            POOL_LP_MINT_SEED.as_bytes(),
            pool_state.key().as_ref(),
        ],
        bump,
        mint::decimals = 9,
        mint::authority = authority,
        payer = payer,
        mint::token_program = token_program,
    )]
    pub lp_mint: Box<InterfaceAccount<'info, Mint>>,

    /// payer token0 account
    #[account(
        mut,
        token::mint = token_0_mint,
        token::authority = payer,
    )]
    pub payer_token_0: Box<InterfaceAccount<'info, TokenAccount>>,

    /// payer token1 account
    #[account(
        mut,
        token::mint = token_1_mint,
        token::authority = payer,
    )]
    pub payer_token_1: Box<InterfaceAccount<'info, TokenAccount>>,

    /// payer lp token account
    #[account(
        init,
        associated_token::mint = lp_mint,
        associated_token::authority = payer,
        payer = payer,
        token::token_program = token_program,
    )]
    pub payer_lp_token: Box<InterfaceAccount<'info, TokenAccount>>,

    /// CHECK: Token_0 vault for the pool, created by contract
    #[account(
        mut,
        seeds = [
            POOL_VAULT_SEED.as_bytes(),
            pool_state.key().as_ref(),
            token_0_mint.key().as_ref()
        ],
        bump,
    )]
    pub token_0_vault: UncheckedAccount<'info>,

    /// CHECK: Token_1 vault for the pool, created by contract
    #[account(
        mut,
        seeds = [
            POOL_VAULT_SEED.as_bytes(),
            pool_state.key().as_ref(),
            token_1_mint.key().as_ref()
        ],
        bump,
    )]
    pub token_1_vault: UncheckedAccount<'info>,

    /// create pool fee account
    #[account(
        mut,
        address= crate::create_pool_fee_reveiver::ID,
    )]
    pub create_pool_fee: Box<InterfaceAccount<'info, TokenAccount>>,

    /// an account to store oracle observations
    #[account(
        init,
        seeds = [
            OBSERVATION_SEED.as_bytes(),
            pool_state.key().as_ref(),
        ],
        bump,
        payer = payer,
        space = ObservationState::LEN
    )]
    pub observation_state: AccountLoader<'info, ObservationState>,

    /// CHECK: the payer's `Permission` PDA (address checked by the seeds). It must be an
    /// initialized `Permission` account of this program (owner, discriminator and layout are
    /// checked in the handler, `check_permission`, exactly what `Account<Permission>` did),
    /// EXCEPT for deep-curve's graduation payer (`deep_keys::GRADUATION_PAYER`), which needs
    /// none (DEEP, F2): a graduation cannot be blocked by a missing or closed permission.
    #[account(
        seeds = [
            PERMISSION_SEED.as_bytes(),
            payer.key().as_ref(),
        ],
        bump,
    )]
    pub permission: UncheckedAccount<'info>,

    /// Program to create mint account and mint tokens
    pub token_program: Program<'info, Token>,
    /// Spl token program or token program 2022
    pub token_0_program: Interface<'info, TokenInterface>,
    /// Spl token program or token program 2022
    pub token_1_program: Interface<'info, TokenInterface>,
    /// Program to create an ATA for receiving position NFT
    pub associated_token_program: Program<'info, AssociatedToken>,
    /// To create a new program account
    pub system_program: Program<'info, System>,
    // remaining account
    // #[account(
    //     seeds = [
    //     SUPPORT_MINT_SEED.as_bytes(),
    //     token_0_mint.key().as_ref(),
    // ],
    //     bump
    // )]
    // pub support_mint0_associated: Account<'info, SupportMintAssociated>,

    // #[account(
    //     seeds = [
    //     SUPPORT_MINT_SEED.as_bytes(),
    //     token_1_mint.key().as_ref(),
    // ],
    //     bump
    // )]
    // pub support_mint1_associated: Account<'info, SupportMintAssociated>,
}

pub fn initialize_with_permission(
    ctx: Context<InitializeWithPermission>,
    init_amount_0: u64,
    init_amount_1: u64,
    open_time: u64,
    creator_fee_on: CreatorFeeOn,
) -> Result<()> {
    // DEEP V1: this instruction creates LEGACY pools only. Under a V1 config it would create
    // a pool no swap could price (the pool and its config must share a fee model).
    require!(
        ctx.accounts.amm_config.fee_model == FEE_MODEL_LEGACY,
        ErrorCode::FeeModelMismatch
    );
    initialize_pool_with_permission(
        ctx,
        init_amount_0,
        init_amount_1,
        open_time,
        creator_fee_on,
        None,
    )
}

/// DEEP V1: creates a V1 pool (`fee_model = 1`) under a V1 AmmConfig, with the token's
/// reward model. Same accounts and permission as `initialize_with_permission`.
///
/// * `creator_fee_on` names the QUOTE side (never `BothToken`): the token every fee of this
///   pool is taken in. When the pair has WSOL it must be the WSOL side.
/// * `reward_model`: 0 Standard, 1 Creator, 2 Holder. Immutable.
/// * `reward_rate`: the token's reward rate per 1e6 (deep-curve passes the rate the token's
///   creator chose at launch), charged on both sides on top of the config's LP + DEEP rates.
///   0 for Standard, at most `MAX_REWARD_RATE`. Immutable: no config change touches it.
/// * the `creator` account is recorded as `pool_creator`, the only possible recipient of the
///   pool's reward fees: the token's creator (Creator), the token's deep-rewards holder vault
///   (Holder). A Standard pool never accrues a reward.
pub fn initialize_with_permission_v1(
    ctx: Context<InitializeWithPermission>,
    init_amount_0: u64,
    init_amount_1: u64,
    open_time: u64,
    creator_fee_on: CreatorFeeOn,
    reward_model: u8,
    reward_rate: u64,
) -> Result<()> {
    let amm_config = &ctx.accounts.amm_config;
    require!(
        amm_config.fee_model == FEE_MODEL_V1,
        ErrorCode::FeeModelMismatch
    );
    require!(
        reward_model <= REWARD_MODEL_HOLDER,
        ErrorCode::InvalidRewardModel
    );
    let wsol = spl_token::native_mint::ID;
    let quote_ok = match creator_fee_on {
        CreatorFeeOn::BothToken => false,
        CreatorFeeOn::OnlyToken0 => ctx.accounts.token_1_mint.key() != wsol,
        CreatorFeeOn::OnlyToken1 => ctx.accounts.token_0_mint.key() != wsol,
    };
    require!(quote_ok, ErrorCode::InvalidQuoteSide);
    require!(
        reward_rate <= crate::deep_keys::MAX_REWARD_RATE
            && !(reward_model == REWARD_MODEL_STANDARD && reward_rate != 0),
        ErrorCode::InvalidRewardRate
    );
    // DEEP (F3): a Holder pool quoted in anything but SOL needs the deep-rewards distributor
    // of (token, quote) to exist already (remaining account). Its reward fees reach the
    // token's holder vault as that quote token, and a token without a distributor there is
    // "stray" to deep-rewards `recover_stray`: with the distributor in place before the pool
    // exists, a waiting reward balance can never be swept. A SOL-quoted pool is exempt, so a
    // graduation never depends on a distributor: WSOL is never stray, it waits for
    // `init_distributor` (deep-rewards refuses to sweep it).
    if reward_model == REWARD_MODEL_HOLDER {
        let (m0, m1) = (
            ctx.accounts.token_0_mint.key(),
            ctx.accounts.token_1_mint.key(),
        );
        let (quote_mint, base_mint) = if creator_fee_on == CreatorFeeOn::OnlyToken0 {
            (m0, m1)
        } else {
            (m1, m0)
        };
        require!(
            quote_mint == wsol
                || crate::deep_keys::has_distributor(
                    ctx.remaining_accounts,
                    &base_mint,
                    &quote_mint
                ),
            ErrorCode::HolderRewardsNeedDistributor
        );
    }
    initialize_pool_with_permission(
        ctx,
        init_amount_0,
        init_amount_1,
        open_time,
        creator_fee_on,
        Some((reward_model, reward_rate)),
    )
}

/// DEEP (F2): what `Account<'info, Permission>` verified, in the same order and with the same
/// errors, for every payer except deep-curve's graduation payer: the account exists
/// (`AccountNotInitialized`), is owned by this program (`AccountOwnedByWrongProgram`), carries
/// the `Permission` discriminator and deserializes. (Its address is already pinned by the
/// `seeds` constraint.)
fn check_permission(payer: &Pubkey, permission: &AccountInfo) -> Result<()> {
    if *payer == crate::deep_keys::GRADUATION_PAYER {
        return Ok(());
    }
    if permission.owner == &anchor_lang::system_program::ID && permission.lamports() == 0 {
        return err!(anchor_lang::error::ErrorCode::AccountNotInitialized);
    }
    require_keys_eq!(
        *permission.owner,
        crate::id(),
        anchor_lang::error::ErrorCode::AccountOwnedByWrongProgram
    );
    let data = permission.try_borrow_data()?;
    Permission::try_deserialize(&mut &data[..])?;
    Ok(())
}

/// The body of upstream's `initialize_with_permission`, unchanged except for the DEEP steps:
/// the permission check above, the graduation payer's exemption from `disable_create_pool`,
/// the capped create-pool fee, and the last step: with `v1 = Some((reward_model,
/// reward_rate))` the new pool is turned into a V1 pool.
fn initialize_pool_with_permission(
    ctx: Context<InitializeWithPermission>,
    init_amount_0: u64,
    init_amount_1: u64,
    open_time: u64,
    creator_fee_on: CreatorFeeOn,
    v1: Option<(u8, u64)>,
) -> Result<()> {
    let mint0_associated_is_initialized = support_mint_associated_is_initialized(
        &ctx.remaining_accounts,
        &ctx.accounts.token_0_mint,
    )?;
    let mint1_associated_is_initialized = support_mint_associated_is_initialized(
        &ctx.remaining_accounts,
        &ctx.accounts.token_1_mint,
    )?;
    if !(is_supported_mint(&ctx.accounts.token_0_mint, mint0_associated_is_initialized).unwrap()
        && is_supported_mint(&ctx.accounts.token_1_mint, mint1_associated_is_initialized).unwrap())
    {
        return err!(ErrorCode::NotSupportMint);
    }

    check_permission(
        ctx.accounts.payer.key,
        &ctx.accounts.permission.to_account_info(),
    )?;
    // DEEP (F2): `disable_create_pool` stops every pool creation except a graduation, the
    // only exit of a completed curve's SOL.
    if ctx.accounts.amm_config.disable_create_pool
        && ctx.accounts.payer.key() != crate::deep_keys::GRADUATION_PAYER
    {
        return err!(ErrorCode::NotApproved);
    }
    let mut open_time = open_time;
    let block_timestamp = clock::Clock::get()?.unix_timestamp as u64;
    if open_time <= block_timestamp {
        open_time = block_timestamp + 1;
    }
    // due to stack/heap limitations, we have to create redundant new accounts ourselves.
    create_token_account(
        &ctx.accounts.authority.to_account_info(),
        &ctx.accounts.payer.to_account_info(),
        &ctx.accounts.token_0_vault.to_account_info(),
        &ctx.accounts.token_0_mint.to_account_info(),
        &ctx.accounts.system_program.to_account_info(),
        &ctx.accounts.token_0_program.to_account_info(),
        &[
            POOL_VAULT_SEED.as_bytes(),
            ctx.accounts.pool_state.key().as_ref(),
            ctx.accounts.token_0_mint.key().as_ref(),
            &[ctx.bumps.token_0_vault][..],
        ],
    )?;

    create_token_account(
        &ctx.accounts.authority.to_account_info(),
        &ctx.accounts.payer.to_account_info(),
        &ctx.accounts.token_1_vault.to_account_info(),
        &ctx.accounts.token_1_mint.to_account_info(),
        &ctx.accounts.system_program.to_account_info(),
        &ctx.accounts.token_1_program.to_account_info(),
        &[
            POOL_VAULT_SEED.as_bytes(),
            ctx.accounts.pool_state.key().as_ref(),
            ctx.accounts.token_1_mint.key().as_ref(),
            &[ctx.bumps.token_1_vault][..],
        ],
    )?;

    let pool_state_loader = create_pool(
        &ctx.accounts.payer.to_account_info(),
        &ctx.accounts.pool_state.to_account_info(),
        &ctx.accounts.amm_config.to_account_info(),
        &ctx.accounts.token_0_mint.to_account_info(),
        &ctx.accounts.token_1_mint.to_account_info(),
        &ctx.accounts.system_program.to_account_info(),
    )?;
    let pool_state = &mut pool_state_loader.load_init()?;

    let mut observation_state = ctx.accounts.observation_state.load_init()?;
    observation_state.pool_id = ctx.accounts.pool_state.key();

    transfer_from_user_to_pool_vault(
        ctx.accounts.payer.to_account_info(),
        ctx.accounts.payer_token_0.to_account_info(),
        ctx.accounts.token_0_vault.to_account_info(),
        ctx.accounts.token_0_mint.to_account_info(),
        ctx.accounts.token_0_program.to_account_info(),
        init_amount_0,
        ctx.accounts.token_0_mint.decimals,
    )?;

    transfer_from_user_to_pool_vault(
        ctx.accounts.payer.to_account_info(),
        ctx.accounts.payer_token_1.to_account_info(),
        ctx.accounts.token_1_vault.to_account_info(),
        ctx.accounts.token_1_mint.to_account_info(),
        ctx.accounts.token_1_program.to_account_info(),
        init_amount_1,
        ctx.accounts.token_1_mint.decimals,
    )?;

    let token_0_vault =
        spl_token_2022::extension::StateWithExtensions::<spl_token_2022::state::Account>::unpack(
            ctx.accounts
                .token_0_vault
                .to_account_info()
                .try_borrow_data()?
                .deref(),
        )?
        .base;
    let token_1_vault =
        spl_token_2022::extension::StateWithExtensions::<spl_token_2022::state::Account>::unpack(
            ctx.accounts
                .token_1_vault
                .to_account_info()
                .try_borrow_data()?
                .deref(),
        )?
        .base;

    CurveCalculator::validate_supply(token_0_vault.amount, token_1_vault.amount)?;

    let liquidity = U128::from(token_0_vault.amount)
        .checked_mul(token_1_vault.amount.into())
        .unwrap()
        .integer_sqrt()
        .as_u64();
    let lock_lp_amount = 100;
    msg!(
        "liquidity:{}, lock_lp_amount:{}, vault_0_amount:{},vault_1_amount:{}",
        liquidity,
        lock_lp_amount,
        token_0_vault.amount,
        token_1_vault.amount
    );
    token::token_mint_to(
        ctx.accounts.authority.to_account_info(),
        ctx.accounts.token_program.to_account_info(),
        ctx.accounts.lp_mint.to_account_info(),
        ctx.accounts.payer_lp_token.to_account_info(),
        liquidity
            .checked_sub(lock_lp_amount)
            .ok_or(ErrorCode::InitLpAmountTooLess)?,
        &[&[crate::AUTH_SEED.as_bytes(), &[ctx.bumps.authority]]],
    )?;

    // Charge the fee to create a pool
    // DEEP (F2/F4): never more than the hard cap, whatever the config holds.
    let create_pool_fee =
        crate::deep_keys::create_pool_fee_to_charge(ctx.accounts.amm_config.create_pool_fee);
    if create_pool_fee != 0 {
        invoke(
            &system_instruction::transfer(
                ctx.accounts.payer.key,
                &ctx.accounts.create_pool_fee.key(),
                create_pool_fee,
            ),
            &[
                ctx.accounts.payer.to_account_info(),
                ctx.accounts.create_pool_fee.to_account_info(),
                ctx.accounts.system_program.to_account_info(),
            ],
        )?;
        invoke(
            &spl_token::instruction::sync_native(
                ctx.accounts.token_program.key,
                &ctx.accounts.create_pool_fee.key(),
            )?,
            &[
                ctx.accounts.token_program.to_account_info(),
                ctx.accounts.create_pool_fee.to_account_info(),
            ],
        )?;
    }

    pool_state.initialize(
        ctx.bumps.authority,
        liquidity,
        open_time,
        ctx.accounts.creator.key(),
        ctx.accounts.amm_config.key(),
        ctx.accounts.token_0_vault.key(),
        ctx.accounts.token_1_vault.key(),
        &ctx.accounts.token_0_mint,
        &ctx.accounts.token_1_mint,
        ctx.accounts.lp_mint.key(),
        ctx.accounts.lp_mint.decimals,
        ctx.accounts.observation_state.key(),
        creator_fee_on.clone(),
        true,
    );
    if let Some((reward_model, reward_rate)) = v1 {
        pool_state.set_v1(creator_fee_on, reward_model, reward_rate)?;
    }

    Ok(())
}
