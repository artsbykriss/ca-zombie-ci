//! Deep Curve — DEEP's bonding-curve launch program.
//!
//! The same source is the devnet build (Cargo feature `devnet`, 600 s Pyth price age) and the
//! mainnet release candidate (default features). See docs/PROGRAMS.md, docs/SECURITY.md and docs/KNOWN_ISSUES.md.

use anchor_lang::prelude::*;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::program::invoke_signed;
use anchor_lang::system_program;
use anchor_spl::associated_token::{self, get_associated_token_address, AssociatedToken};
use anchor_spl::metadata::{
    create_metadata_accounts_v3, mpl_token_metadata::types::DataV2, CreateMetadataAccountsV3,
    Metadata,
};
use anchor_spl::token::{self, Burn, Mint, MintTo, SetAuthority, Token, TokenAccount, Transfer};

pub mod math;
pub mod pyth;
pub mod splitter;

pub use splitter::*;

use math::{Curve, Fees, FeesV1, MathError};

#[cfg(not(feature = "no-entrypoint"))]
solana_security_txt::security_txt! {
    name: "deep-curve",
    project_url: "https://deepliquidity.fun",
    contacts: "email:security@deepliquidity.fun,link:https://github.com/Deep-Liquidity/contracts/security/advisories/new",
    policy: "https://github.com/Deep-Liquidity/contracts/blob/main/SECURITY.md",
    source_code: "https://github.com/Deep-Liquidity/contracts",
    preferred_languages: "en"
}

declare_id!("7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA");

pub const CONFIG_SEED: &[u8] = b"config";
pub const CURVE_SEED: &[u8] = b"curve";
pub const TREASURY_SEED: &[u8] = b"treasury";
pub const PENDING_CONFIG_SEED: &[u8] = b"pending_config";

/// Upper bound for `Config.timelock_seconds` (30 days).
pub const MAX_TIMELOCK_SECONDS: u32 = 30 * 24 * 3600;
/// Recommended mainnet timelock (48h). Devnet/localnet may use 0.
pub const RECOMMENDED_MAINNET_TIMELOCK_SECONDS: u32 = 48 * 3600;
/// A queued change must be applied within this window after its eta, or it goes
/// stale and has to be cancelled and re-queued (so an old, forgotten change cannot
/// be applied by surprise months later).
pub const CONFIG_UPDATE_GRACE_SECONDS: i64 = 14 * 24 * 3600;
/// System-owned, data-less PDA that pays for and signs the AMM pool creation.
/// (The curve PDA cannot: it carries data, so it cannot fund system `create_account`.)
/// The seed is used ALONE (one address for every graduation). deep-amm compiles this address
/// in (`deep_amm::deep_keys::GRADUATION_PAYER`, pinned by a test here and in the SDK): for it
/// `initialize_with_permission[_v1]` needs no `Permission` account, ignores the AmmConfig's
/// `disable_create_pool`, and its `Permission` cannot be closed. It holds funds only inside
/// `graduate`, which ends by sweeping it to the DEEP fee vault.
pub const POOL_CREATOR_SEED: &[u8] = b"pool_creator";
/// deep_curve PDA used as the AMM `pool_state` address (signed via seeds), so the
/// pool address cannot be squatted by a third party before graduation.
pub const RAYDIUM_POOL_SEED: &[u8] = b"raydium_pool";

/// Graduation target: DeepSwap's own CPMM, `deep-amm` (a fork of Raydium cp-swap,
/// programs/deep-amm, see its NOTICE). The program id and the create-pool fee
/// receiver come from the deep-amm crate, so they always match the deep-amm build
/// (its fee receiver is fixed at build time via DEEP_AMM_CREATE_POOL_FEE_RECEIVER).
/// The CPI stays hand-encoded (account order of deep-amm `initialize_with_permission`).
pub mod amm {
    use anchor_lang::prelude::Pubkey;
    pub const CP_SWAP_PROGRAM_ID: Pubkey = deep_amm::ID;
    pub const CREATE_POOL_FEE_RECEIVER: Pubkey = deep_amm::create_pool_fee_reveiver::ID;
    pub const AUTH_SEED: &[u8] = b"vault_and_lp_mint_auth_seed";
    pub const POOL_LP_MINT_SEED: &[u8] = b"pool_lp_mint";
    pub const POOL_VAULT_SEED: &[u8] = b"pool_vault";
    pub const OBSERVATION_SEED: &[u8] = b"observation";
    /// deep-amm `Permission` PDA: [PERMISSION_SEED, payer].
    pub const PERMISSION_SEED: &[u8] = b"permission";
    /// sha256("global:initialize_with_permission")[..8]: the pool-creation instruction
    /// that records a pool creator and enables the creator fee.
    pub const INITIALIZE_WITH_PERMISSION_DISCRIMINATOR: [u8; 8] =
        [63, 55, 254, 65, 49, 178, 89, 121];
    /// sha256("global:initialize_with_permission_v1")[..8]: the DEEP V1 pool creation
    /// (same accounts; two more arguments, the reward model (u8) and the reward rate (u64,
    /// per 1e6)). Used when the configured AmmConfig is a V1 config.
    pub const INITIALIZE_WITH_PERMISSION_V1_DISCRIMINATOR: [u8; 8] =
        [71, 171, 234, 147, 157, 34, 230, 103];
    /// Borsh tags of deep-amm `CreatorFeeOn` (states/pool.rs).
    pub const CREATOR_FEE_ON_ONLY_TOKEN_0: u8 = 1;
    pub const CREATOR_FEE_ON_ONLY_TOKEN_1: u8 = 2;
    /// deep-amm `AmmConfig.fee_model` (byte offset in the account, and its two values).
    pub const AMM_CONFIG_FEE_MODEL_OFFSET: usize = deep_amm::states::AMM_CONFIG_FEE_MODEL_OFFSET;
    pub const FEE_MODEL_LEGACY: u8 = deep_amm::states::FEE_MODEL_LEGACY;
    pub const FEE_MODEL_V1: u8 = deep_amm::states::FEE_MODEL_V1;
    /// deep-amm rates are per 1e6, curve rates are bps: 1 bps = 100 per 1e6.
    pub const RATE_PER_BPS: u64 = 100;
}
/// Back-compat alias (account/field names still say `raydium_*`; layouts unchanged).
pub use amm as raydium;

/// DEEP builder wallet (owner decision 2026-10-06, DEEP V1): receives exactly 10%
/// (`splitter::BUILDER_SPLIT_BPS`) of ALL DEEP revenue through the fee splitter's permissionless
/// `distribute`. Fixed at BUILD time from env `DEEP_BUILDER_WALLET` through deep-amm's
/// `deep_keys` (one key for both programs, so they cannot disagree within a build). No
/// instruction can change it or the rate: only a program upgrade, signed through the Squads
/// vault, can. Unset: the system program id, which is not a system-owned wallet, so
/// `distribute` fails (fails closed).
pub const BUILDER_WALLET: Pubkey = deep_amm::deep_keys::BUILDER;

/// Hard cap for Config.launch_fee_usd_cents ($20.00), enforced on-chain.
pub const MAX_LAUNCH_FEE_USD_CENTS: u16 = 2_000;
/// Suggested launch fee ($2.00). Set through the timelock, never by migration.
pub const DEFAULT_LAUNCH_FEE_USD_CENTS: u16 = 200;
/// Account sizes before the v2 layout (deployed on devnet as of 49aba17).
pub const CONFIG_V1_SIZE: usize = 213;
pub const PENDING_CONFIG_V1_SIZE: usize = 165;
pub const BONDING_CURVE_V1_SIZE: usize = 177;
/// Account sizes of the v2 layout (launch fee + protocol fees on the curve; devnet before V1
/// Phase 2).
pub const CONFIG_V2_SIZE: usize = 215;
pub const PENDING_CONFIG_V2_SIZE: usize = 167;
pub const BONDING_CURVE_V2_SIZE: usize = 185;
/// v3 (DEEP V1 Phase 2) sizes; equal to `8 + INIT_SPACE` (unit-tested below).
pub const CONFIG_V3_SIZE: usize = 221;
pub const PENDING_CONFIG_V3_SIZE: usize = 173;
pub const BONDING_CURVE_V3_SIZE: usize = 196;

/// Byte offsets the v2 -> v3 migrations read and write (appended fields only).
mod layout {
    /// Config.protocol_fee_bps
    pub const CONFIG_PROTOCOL_FEE_BPS: usize = 136;
    /// Config.sell_protocol_fee_bps (first v3 field)
    pub const CONFIG_SELL_PROTOCOL_FEE_BPS: usize = super::CONFIG_V2_SIZE;
    /// PendingConfig.params (disc 8 | active 1 | eta 8 | queued_at 8)
    pub const PENDING_PARAMS: usize = 25;
    /// ConfigParams.protocol_fee_bps, relative to the params
    pub const PARAMS_PROTOCOL_FEE_BPS: usize = 64;
    /// ConfigParams.sell_protocol_fee_bps (first v3 field), relative to the params
    pub const PARAMS_SELL_PROTOCOL_FEE_BPS: usize = 141;
    /// BondingCurve.protocol_fee_bps / creator_fee_bps
    pub const CURVE_PROTOCOL_FEE_BPS: usize = 120;
    pub const CURVE_CREATOR_FEE_BPS: usize = 122;
    /// BondingCurve.sell_protocol_fee_bps / reward_model (first v3 fields)
    pub const CURVE_SELL_PROTOCOL_FEE_BPS: usize = super::BONDING_CURVE_V2_SIZE;
    pub const CURVE_REWARD_MODEL: usize = super::BONDING_CURVE_V2_SIZE + 2;
}

/// deep-rewards (Holder Rewards distributor, programs/deep-rewards). deep-curve needs only its
/// program id and the holder-vault seed: a Holder token's curve reward fees are credited to
/// `PDA([HOLDER_VAULT_SEED, mint], DEEP_REWARDS_PROGRAM_ID)`, a system-owned, data-less account
/// only deep-rewards can sign for (docs/V1_FEES.md 4.5). Pinned to the SDK and through it to
/// deep-rewards by fixtures/ix-vectors.json (`sweep_holder_fees`).
pub const DEEP_REWARDS_PROGRAM_ID: Pubkey =
    Pubkey::from_str_const("4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2");
pub const HOLDER_VAULT_SEED: &[u8] = b"holder_vault";

/// The holder vault of `mint`: where `sweep_holder_fees` pays, and what a Holder token's
/// DeepSwap pool records as its `pool_creator`.
pub fn holder_vault_address(mint: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(
        &[HOLDER_VAULT_SEED, mint.as_ref()],
        &DEEP_REWARDS_PROGRAM_ID,
    )
    .0
}

/// The one address a token's DeepSwap reward fees can go to, recorded at graduation as the
/// pool's `pool_creator`: the token's holder vault for a Holder token, the token's creator
/// otherwise (a Standard pool never accrues a reward, the creator is recorded all the same).
pub fn reward_recipient_address(curve: &BondingCurve) -> Pubkey {
    if curve.reward_model == math::REWARD_MODEL_HOLDER {
        holder_vault_address(&curve.mint)
    } else {
        curve.creator
    }
}

pub const MAX_NAME_LEN: usize = 32;
pub const MAX_SYMBOL_LEN: usize = 10;
pub const MAX_URI_LEN: usize = 200;

#[program]
pub mod deep_curve {
    use super::*;

    /// One-time protocol setup. The signer becomes admin and must be this program's
    /// upgrade authority (prevents front-running the config PDA after deploy).
    pub fn initialize_config(ctx: Context<InitializeConfig>, params: ConfigParams) -> Result<()> {
        params.validate()?;
        ctx.accounts.treasury.bump = ctx.bumps.treasury;
        let cfg = &mut ctx.accounts.config;
        cfg.admin = ctx.accounts.admin.key();
        cfg.pending_admin = Pubkey::default();
        cfg.bump = ctx.bumps.config;
        cfg.paused = false;
        cfg.apply(&params);
        emit!(ConfigUpdated { admin: cfg.admin });
        Ok(())
    }

    /// Timelocked config change, step 1 (admin). Validates `params` now and stores them
    /// with `eta = now + config.timelock_seconds` (the delay in force at queue time, so
    /// shortening the timelock is itself delayed by the current timelock). Only one
    /// change can be pending; cancel it first to replace it.
    pub fn queue_config_update(
        ctx: Context<QueueConfigUpdate>,
        params: ConfigParams,
    ) -> Result<()> {
        params.validate()?;
        let pending = &mut ctx.accounts.pending_config;
        require!(!pending.active, DeepError::ConfigUpdatePending);
        let now = Clock::get()?.unix_timestamp;
        let eta = now
            .checked_add(ctx.accounts.config.timelock_seconds as i64)
            .ok_or(DeepError::Overflow)?;
        pending.active = true;
        pending.eta = eta;
        pending.queued_at = now;
        pending.params = params.clone();
        pending.bump = ctx.bumps.pending_config;
        emit!(ConfigUpdateQueued {
            eta,
            queued_at: now,
            params,
        });
        Ok(())
    }

    /// Timelocked config change, step 2. PERMISSIONLESS: the params and eta were fixed
    /// and published when queued, so anyone may execute once `now >= eta` (and before
    /// eta + grace). The admin cannot time a known change opportunistically, and a
    /// change everyone has been warned about cannot be withheld; the admin keeps
    /// `cancel_config_update` as the veto.
    pub fn apply_config_update(ctx: Context<ApplyConfigUpdate>) -> Result<()> {
        let pending = &mut ctx.accounts.pending_config;
        require!(pending.active, DeepError::NoPendingConfigUpdate);
        let now = Clock::get()?.unix_timestamp;
        require!(now >= pending.eta, DeepError::TimelockNotElapsed);
        require!(
            now <= pending.eta.saturating_add(CONFIG_UPDATE_GRACE_SECONDS),
            DeepError::ConfigUpdateExpired
        );
        let params = pending.params.clone();
        params.validate()?;
        pending.active = false;
        let cfg = &mut ctx.accounts.config;
        cfg.apply(&params);
        emit!(ConfigUpdated { admin: cfg.admin });
        Ok(())
    }

    /// Admin veto for a queued config change (also the only way to drop a stale one).
    pub fn cancel_config_update(ctx: Context<CancelConfigUpdate>) -> Result<()> {
        let pending = &mut ctx.accounts.pending_config;
        require!(pending.active, DeepError::NoPendingConfigUpdate);
        pending.active = false;
        emit!(ConfigUpdateCancelled { eta: pending.eta });
        Ok(())
    }

    /// Emergency pause. Blocks create/buy/sell; does not block creator fee claims.
    pub fn set_paused(ctx: Context<AdminOnly>, paused: bool) -> Result<()> {
        ctx.accounts.config.paused = paused;
        emit!(PauseChanged { paused });
        Ok(())
    }

    /// Two-step admin transfer, step 1.
    pub fn propose_admin(ctx: Context<AdminOnly>, new_admin: Pubkey) -> Result<()> {
        ctx.accounts.config.pending_admin = new_admin;
        Ok(())
    }

    /// Two-step admin transfer, step 2 — must be signed by the proposed admin.
    pub fn accept_admin(ctx: Context<AcceptAdmin>) -> Result<()> {
        let cfg = &mut ctx.accounts.config;
        cfg.admin = cfg.pending_admin;
        cfg.pending_admin = Pubkey::default();
        emit!(ConfigUpdated { admin: cfg.admin });
        Ok(())
    }

    /// Creates a fixed-supply mint, its metadata, and the bonding curve that sells it.
    /// The creator chooses the token's reward terms, both immutable: `reward_model`
    /// (0 Standard, 1 Creator, 2 Holder) and `reward_bps`, the reward rate charged on every
    /// buy and sell on top of DEEP's protocol fee, on this curve and later on the token's
    /// DeepSwap pool. Standard: `reward_bps` must be 0. Creator / Holder: at least 1, at
    /// most the admin's current maximum (`Config.max_reward_bps`, itself at most the hard
    /// ceiling `math::MAX_REWARD_BPS`, 500), and DEEP's protocol fee plus the reward rate at
    /// most 1000 bps on each side. They are stored on the curve together with DEEP's protocol
    /// rates in force now; later changes of the maximum or of the rates never touch it.
    ///
    /// `max_launch_fee_lamports`: the most the creator agrees to pay as launch fee. The fee is
    /// set in USD and converted at the Pyth SOL/USD price inside this instruction; if that
    /// comes to more lamports than this limit the transaction fails with `LaunchFeeAboveMax`
    /// and nothing is charged (security review F9).
    pub fn create_token(
        ctx: Context<CreateToken>,
        name: String,
        symbol: String,
        uri: String,
        reward_model: u8,
        reward_bps: u16,
        max_launch_fee_lamports: u64,
    ) -> Result<()> {
        let cfg = &ctx.accounts.config;
        require!(!cfg.paused, DeepError::Paused);
        require!(
            reward_model <= math::REWARD_MODEL_HOLDER,
            DeepError::InvalidRewardModel
        );
        require!(
            math::validate_launch_reward(reward_model, reward_bps).is_ok(),
            DeepError::InvalidRewardRate
        );
        // the admin's current maximum, for NEW launches only
        require!(
            reward_bps <= cfg.max_reward_bps,
            DeepError::RewardRateAboveMax
        );
        // the total cap per side: DEEP's protocol fee + the reward rate <= 10%
        math::validate_fees_v1(&FeesV1 {
            buy_protocol_fee_bps: cfg.protocol_fee_bps,
            sell_protocol_fee_bps: cfg.sell_protocol_fee_bps,
            reward_bps,
            reward_model,
        })
        .map_err(DeepError::from)?;
        require!(
            name.len() <= MAX_NAME_LEN && !name.is_empty(),
            DeepError::InvalidMetadata
        );
        require!(
            symbol.len() <= MAX_SYMBOL_LEN && !symbol.is_empty(),
            DeepError::InvalidMetadata
        );
        require!(uri.len() <= MAX_URI_LEN, DeepError::InvalidMetadata);

        // Launch fee in USD, priced with Pyth SOL/USD (fail closed). It accrues on the
        // new curve (protocol_fees_unclaimed) like trade fees, so launches don't write
        // any global account either; sweep_protocol_fees moves it to the fee vault later.
        let now = Clock::get()?.unix_timestamp;
        let mut launch_fee = 0u64;
        if cfg.launch_fee_usd_cents > 0 {
            let info = &ctx.accounts.price_update;
            require_keys_eq!(
                *info.owner,
                pyth::RECEIVER_PROGRAM_ID,
                DeepError::PriceFeedInvalid
            );
            let p = pyth::decode_price_update(&info.try_borrow_data()?).map_err(DeepError::from)?;
            pyth::validate(&p, now).map_err(DeepError::from)?;
            #[cfg(feature = "devnet")]
            msg!(pyth::DEVNET_BUILD_MARKER);
            launch_fee = pyth::launch_fee_lamports(cfg.launch_fee_usd_cents, p.price, p.exponent)
                .map_err(DeepError::from)?;
            require!(
                launch_fee <= max_launch_fee_lamports,
                DeepError::LaunchFeeAboveMax
            );
            emit!(LaunchFeeCharged {
                mint: ctx.accounts.mint.key(),
                creator: ctx.accounts.creator.key(),
                usd_cents: cfg.launch_fee_usd_cents,
                lamports: launch_fee,
                price: p.price,
                exponent: p.exponent,
                publish_time: p.publish_time,
            });
        }

        let mint_key = ctx.accounts.mint.key();
        let curve = &mut ctx.accounts.curve;
        curve.mint = mint_key;
        curve.creator = ctx.accounts.creator.key();
        curve.virtual_sol_reserves = cfg.initial_virtual_sol;
        curve.virtual_token_reserves = cfg.initial_virtual_token;
        curve.real_sol_reserves = 0;
        curve.real_token_reserves = cfg.curve_supply;
        curve.curve_supply = cfg.curve_supply;
        curve.token_total_supply = cfg.token_total_supply;
        // Fee snapshot (DEEP V1): the buy and sell protocol rates, and the reward rate of the
        // chosen model in `creator_fee_bps` (the field name is kept from v1/v2; for a Standard
        // token it is the legacy creator fee).
        curve.protocol_fee_bps = cfg.protocol_fee_bps;
        curve.sell_protocol_fee_bps = cfg.sell_protocol_fee_bps;
        curve.creator_fee_bps = reward_bps;
        curve.reward_model = reward_model;
        curve.holder_fees_unclaimed = 0;
        curve.migration_fee_bps = cfg.migration_fee_bps;
        curve.creator_fees_unclaimed = 0;
        curve.complete = false;
        curve.graduated = false;
        curve.created_at = now;
        curve.bump = ctx.bumps.curve;
        curve.pool = Pubkey::default();
        curve.protocol_fees_unclaimed = launch_fee;

        let bump = [curve.bump];
        let seeds: &[&[u8]] = &[CURVE_SEED, mint_key.as_ref(), &bump];
        let signer = &[seeds];
        if launch_fee > 0 {
            system_program::transfer(
                CpiContext::new(
                    ctx.accounts.system_program.key(),
                    system_program::Transfer {
                        from: ctx.accounts.creator.to_account_info(),
                        to: ctx.accounts.curve.to_account_info(),
                    },
                ),
                launch_fee,
            )?;
        }

        // Mint the full supply to the curve vault.
        token::mint_to(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.key(),
                MintTo {
                    mint: ctx.accounts.mint.to_account_info(),
                    to: ctx.accounts.vault.to_account_info(),
                    authority: ctx.accounts.curve.to_account_info(),
                },
                signer,
            ),
            cfg.token_total_supply,
        )?;

        create_metadata_accounts_v3(
            CpiContext::new_with_signer(
                ctx.accounts.token_metadata_program.key(),
                CreateMetadataAccountsV3 {
                    metadata: ctx.accounts.metadata.to_account_info(),
                    mint: ctx.accounts.mint.to_account_info(),
                    mint_authority: ctx.accounts.curve.to_account_info(),
                    payer: ctx.accounts.creator.to_account_info(),
                    update_authority: ctx.accounts.curve.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
                signer,
            ),
            DataV2 {
                name: name.clone(),
                symbol: symbol.clone(),
                uri: uri.clone(),
                seller_fee_basis_points: 0,
                creators: None,
                collection: None,
                uses: None,
            },
            false, // immutable metadata
            true,
            None,
        )?;

        // Revoke mint authority: supply is fixed forever.
        token::set_authority(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.key(),
                SetAuthority {
                    current_authority: ctx.accounts.curve.to_account_info(),
                    account_or_mint: ctx.accounts.mint.to_account_info(),
                },
                signer,
            ),
            anchor_spl::token::spl_token::instruction::AuthorityType::MintTokens,
            None,
        )?;

        emit!(TokenCreated {
            mint: mint_key,
            creator: ctx.accounts.creator.key(),
            name,
            symbol,
            uri,
            curve_supply: cfg.curve_supply,
            token_total_supply: cfg.token_total_supply,
            reward_model,
            reward_bps,
        });
        Ok(())
    }

    /// Buy with an exact SOL budget. Charges less if capped by remaining supply.
    pub fn buy(ctx: Context<Trade>, sol_in: u64, min_tokens_out: u64, deadline: i64) -> Result<()> {
        require!(!ctx.accounts.config.paused, DeepError::Paused);
        check_deadline(deadline)?;

        let curve = &ctx.accounts.curve;
        let q = math::quote_buy(&curve.to_math(), sol_in, &curve.fees(true), min_tokens_out)
            .map_err(DeepError::from)?;

        // user → curve: net + reward fee + protocol fee (`q.fees.creator` is the reward part,
        // whatever the model). All fees are held on the curve PDA (creator: until claimed;
        // holder: until swept to the holder vault; protocol: until swept to the fee vault),
        // so trades on different tokens share no writable account.
        system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.key(),
                system_program::Transfer {
                    from: ctx.accounts.user.to_account_info(),
                    to: ctx.accounts.curve.to_account_info(),
                },
            ),
            q.sol_to_curve
                .checked_add(q.fees.creator)
                .and_then(|v| v.checked_add(q.fees.protocol))
                .ok_or(DeepError::Overflow)?,
        )?;

        let mint_key = ctx.accounts.mint.key();
        let bump = [ctx.accounts.curve.bump];
        let seeds: &[&[u8]] = &[CURVE_SEED, mint_key.as_ref(), &bump];
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.key(),
                Transfer {
                    from: ctx.accounts.vault.to_account_info(),
                    to: ctx.accounts.user_token.to_account_info(),
                    authority: ctx.accounts.curve.to_account_info(),
                },
                &[seeds],
            ),
            q.tokens_out,
        )?;

        let curve = &mut ctx.accounts.curve;
        curve.set_from_math(&q.next);
        let routed = curve.accrue_fees(&q.fees)?;
        curve.assert_solvent()?;

        emit!(TradeEvent {
            mint: mint_key,
            trader: ctx.accounts.user.key(),
            is_buy: true,
            sol_amount: q.sol_in,
            token_amount: q.tokens_out,
            protocol_fee: routed.protocol,
            creator_fee: routed.creator,
            virtual_sol_reserves: curve.virtual_sol_reserves,
            virtual_token_reserves: curve.virtual_token_reserves,
            real_sol_reserves: curve.real_sol_reserves,
            real_token_reserves: curve.real_token_reserves,
            timestamp: Clock::get()?.unix_timestamp,
            reward_model: curve.reward_model,
            holder_fee: routed.holder,
        });
        if curve.complete {
            emit!(CurveCompleted {
                mint: mint_key,
                real_sol_reserves: curve.real_sol_reserves,
            });
        }
        Ok(())
    }

    /// Sell an exact token amount for at least `min_sol_out` lamports.
    pub fn sell(
        ctx: Context<Trade>,
        tokens_in: u64,
        min_sol_out: u64,
        deadline: i64,
    ) -> Result<()> {
        require!(!ctx.accounts.config.paused, DeepError::Paused);
        check_deadline(deadline)?;

        let curve = &ctx.accounts.curve;
        let q = math::quote_sell(&curve.to_math(), tokens_in, &curve.fees(false), min_sol_out)
            .map_err(DeepError::from)?;

        token::transfer(
            CpiContext::new(
                ctx.accounts.token_program.key(),
                Transfer {
                    from: ctx.accounts.user_token.to_account_info(),
                    to: ctx.accounts.vault.to_account_info(),
                    authority: ctx.accounts.user.to_account_info(),
                },
            ),
            tokens_in,
        )?;

        // Curve PDA is program-owned: move lamports directly.
        // sol_from_curve = sol_out + protocol + reward; both fee parts stay in the PDA.
        ctx.accounts
            .curve
            .to_account_info()
            .sub_lamports(q.sol_out)?;
        ctx.accounts
            .user
            .to_account_info()
            .add_lamports(q.sol_out)?;

        let mint_key = ctx.accounts.mint.key();
        let curve = &mut ctx.accounts.curve;
        curve.set_from_math(&q.next);
        let routed = curve.accrue_fees(&q.fees)?;
        curve.assert_solvent()?;

        emit!(TradeEvent {
            mint: mint_key,
            trader: ctx.accounts.user.key(),
            is_buy: false,
            sol_amount: q.sol_out,
            token_amount: tokens_in,
            protocol_fee: routed.protocol,
            creator_fee: routed.creator,
            virtual_sol_reserves: curve.virtual_sol_reserves,
            virtual_token_reserves: curve.virtual_token_reserves,
            real_sol_reserves: curve.real_sol_reserves,
            real_token_reserves: curve.real_token_reserves,
            timestamp: Clock::get()?.unix_timestamp,
            reward_model: curve.reward_model,
            holder_fee: routed.holder,
        });
        Ok(())
    }

    /// Sends what is left in the legacy treasury PDA to `config.fee_recipient`. Admin only;
    /// the treasury always stays rent-exempt. DEEP V1: nothing credits the Treasury any more
    /// (all revenue goes to the fee vault); this only drains the pre-V1 devnet balance.
    pub fn withdraw_protocol_fees(ctx: Context<WithdrawProtocolFees>, amount: u64) -> Result<()> {
        require!(amount > 0, DeepError::ZeroAmount);
        let info = ctx.accounts.treasury.to_account_info();
        let rent = Rent::get()?.minimum_balance(info.data_len());
        let available = info.lamports().saturating_sub(rent);
        require!(amount <= available, DeepError::InsufficientTreasury);
        info.sub_lamports(amount)?;
        ctx.accounts
            .fee_recipient
            .to_account_info()
            .add_lamports(amount)?;
        emit!(ProtocolFeesWithdrawn {
            recipient: ctx.accounts.fee_recipient.key(),
            amount,
        });
        Ok(())
    }

    /// PERMISSIONLESS: moves a curve's accrued protocol fees (trade + launch) to the DEEP fee
    /// vault, where `distribute` splits them (builder 10%, destinations 90%). Batched off the
    /// hot path so buys/sells never write a global account.
    pub fn sweep_protocol_fees(ctx: Context<SweepProtocolFees>) -> Result<()> {
        let amount = ctx.accounts.curve.protocol_fees_unclaimed;
        require!(amount > 0, DeepError::ZeroAmount);
        ctx.accounts.curve.protocol_fees_unclaimed = 0;
        ctx.accounts.curve.to_account_info().sub_lamports(amount)?;
        ctx.accounts
            .fee_vault
            .to_account_info()
            .add_lamports(amount)?;
        ctx.accounts.curve.assert_solvent()?;
        let mint = ctx.accounts.curve.mint;
        emit!(ProtocolFeesSwept { mint, amount });
        Ok(())
    }

    /// PERMISSIONLESS: moves a Holder token's accrued curve reward fees to its holder vault,
    /// the deep-rewards PDA `["holder_vault", mint]` (system-owned; deep-rewards pays them to
    /// holders by Merkle claim). Works before and after graduation. The vault must end at or
    /// above the 0-byte rent minimum: once `init_distributor` has run it always does; before
    /// that, the call succeeds as soon as the accrued amount alone covers it. Until then the
    /// fees stay on the curve, counted in `holder_fees_unclaimed`, never lost.
    pub fn sweep_holder_fees(ctx: Context<SweepHolderFees>) -> Result<()> {
        let amount = ctx.accounts.curve.holder_fees_unclaimed;
        require!(amount > 0, DeepError::ZeroAmount);
        require!(
            ctx.accounts.curve.reward_model == math::REWARD_MODEL_HOLDER,
            DeepError::InvalidRewardModel
        );
        let vault = ctx.accounts.holder_vault.to_account_info();
        let after = vault
            .lamports()
            .checked_add(amount)
            .ok_or(DeepError::Overflow)?;
        require!(
            after >= Rent::get()?.minimum_balance(0),
            DeepError::HolderVaultBelowRent
        );
        ctx.accounts.curve.holder_fees_unclaimed = 0;
        ctx.accounts.curve.to_account_info().sub_lamports(amount)?;
        vault.add_lamports(amount)?;
        ctx.accounts.curve.assert_solvent()?;
        emit!(HolderFeesSwept {
            mint: ctx.accounts.curve.mint,
            holder_vault: vault.key(),
            amount,
        });
        Ok(())
    }

    /// PERMISSIONLESS, idempotent: grows a v1 (213 B) or v2 (215 B) Config and, if present, a
    /// v1 (165 B) or v2 (167 B) PendingConfig to the v3 layout. No-op when already v3.
    /// New fields: the launch fee (v2) starts at 0; `sell_protocol_fee_bps` (v3) is set to the
    /// account's own `protocol_fee_bps`, so sells keep paying what they paid before; the
    /// current maximum reward rate (v3, `max_reward_bps`) starts at the ceiling, 500. Every
    /// other value is then set through the timelock.
    pub fn migrate_config(ctx: Context<MigrateConfig>) -> Result<()> {
        let payer = ctx.accounts.payer.to_account_info();
        let sys = ctx.accounts.system_program.to_account_info();
        let cfg = ctx.accounts.config.to_account_info();
        require_keys_eq!(*cfg.owner, crate::ID, DeepError::InvalidParams);
        require!(
            cfg.try_borrow_data()?[..8] == *Config::DISCRIMINATOR,
            DeepError::InvalidParams
        );
        let old_len = cfg.data_len();
        require!(
            matches!(old_len, CONFIG_V1_SIZE | CONFIG_V2_SIZE | CONFIG_V3_SIZE),
            DeepError::InvalidParams
        );
        if old_len < CONFIG_V3_SIZE {
            grow(&cfg, &payer, &sys, CONFIG_V3_SIZE)?; // appended bytes are zero
            let mut d = cfg.try_borrow_mut_data()?;
            let p = layout::CONFIG_PROTOCOL_FEE_BPS;
            d.copy_within(p..p + 2, layout::CONFIG_SELL_PROTOCOL_FEE_BPS);
            let m = layout::CONFIG_SELL_PROTOCOL_FEE_BPS + 2;
            d[m..m + 2].copy_from_slice(&math::MAX_REWARD_BPS.to_le_bytes());
        }

        let pc = ctx.accounts.pending_config.to_account_info();
        let pc_len = pc.data_len();
        if pc.owner == &crate::ID
            && matches!(pc_len, PENDING_CONFIG_V1_SIZE | PENDING_CONFIG_V2_SIZE)
        {
            require!(
                pc.try_borrow_data()?[..8] == *PendingConfig::DISCRIMINATOR,
                DeepError::InvalidParams
            );
            // v1: disc | active | eta | queued_at | ConfigParams(139) | bump
            // v2: disc | active | eta | queued_at | ConfigParams(141) | bump
            // v3: disc | active | eta | queued_at | ConfigParams(147) | bump
            let bump = pc.try_borrow_data()?[pc_len - 1];
            grow(&pc, &payer, &sys, PENDING_CONFIG_V3_SIZE)?;
            let mut d = pc.try_borrow_mut_data()?;
            // The old bump slot is the first byte of the new fields: clear it, so every new
            // field reads 0 (launch fee for v1, reward rates), then give the queued change the
            // same sell-rate rule as the Config and put the bump at the end.
            d[pc_len - 1] = 0;
            let p = layout::PENDING_PARAMS + layout::PARAMS_PROTOCOL_FEE_BPS;
            let s = layout::PENDING_PARAMS + layout::PARAMS_SELL_PROTOCOL_FEE_BPS;
            d.copy_within(p..p + 2, s);
            d[s + 2..s + 4].copy_from_slice(&math::MAX_REWARD_BPS.to_le_bytes());
            d[PENDING_CONFIG_V3_SIZE - 1] = bump;
        }
        Ok(())
    }

    /// PERMISSIONLESS, idempotent: grows a v1 (177 B) or v2 (185 B) BondingCurve to v3 (196 B).
    /// No-op when already v3. `protocol_fees_unclaimed` (v2) and `holder_fees_unclaimed` (v3)
    /// start at 0. The v3 fee fields keep the token's economics unchanged:
    /// `sell_protocol_fee_bps` = its `protocol_fee_bps`, and `reward_model` = Creator when it
    /// charges a creator fee (which keeps accruing to the creator), otherwise Standard. The
    /// payer funds the rent difference, so the curve stays solvent.
    pub fn migrate_curve(ctx: Context<MigrateCurve>) -> Result<()> {
        let curve = ctx.accounts.curve.to_account_info();
        require_keys_eq!(*curve.owner, crate::ID, DeepError::InvalidParams);
        require!(
            curve.try_borrow_data()?[..8] == *BondingCurve::DISCRIMINATOR,
            DeepError::InvalidParams
        );
        let old_len = curve.data_len();
        require!(
            matches!(
                old_len,
                BONDING_CURVE_V1_SIZE | BONDING_CURVE_V2_SIZE | BONDING_CURVE_V3_SIZE
            ),
            DeepError::InvalidParams
        );
        if old_len == BONDING_CURVE_V3_SIZE {
            return Ok(());
        }
        grow(
            &curve,
            &ctx.accounts.payer.to_account_info(),
            &ctx.accounts.system_program.to_account_info(),
            BONDING_CURVE_V3_SIZE,
        )?;
        let mut d = curve.try_borrow_mut_data()?;
        let p = layout::CURVE_PROTOCOL_FEE_BPS;
        d.copy_within(p..p + 2, layout::CURVE_SELL_PROTOCOL_FEE_BPS);
        let c = layout::CURVE_CREATOR_FEE_BPS;
        let creator_fee_bps = u16::from_le_bytes([d[c], d[c + 1]]);
        d[layout::CURVE_REWARD_MODEL] = if creator_fee_bps > 0 {
            math::REWARD_MODEL_CREATOR
        } else {
            math::REWARD_MODEL_STANDARD
        };
        Ok(())
    }

    pub fn claim_creator_fees(ctx: Context<ClaimCreatorFees>) -> Result<()> {
        let amount = ctx.accounts.curve.creator_fees_unclaimed;
        require!(amount > 0, DeepError::ZeroAmount);
        ctx.accounts.curve.creator_fees_unclaimed = 0;
        ctx.accounts.curve.to_account_info().sub_lamports(amount)?;
        ctx.accounts
            .creator
            .to_account_info()
            .add_lamports(amount)?;
        ctx.accounts.curve.assert_solvent()?;
        emit!(CreatorFeesClaimed {
            mint: ctx.accounts.curve.mint,
            creator: ctx.accounts.creator.key(),
            amount,
        });
        Ok(())
    }

    // ───────────── DEEP V1 fee splitter (src/splitter.rs) ─────────────

    /// One-time (admin): creates the SplitterConfig with the initial 90% destinations, funds
    /// the fee vault to its rent minimum and creates the vault's WSOL ATA (payer = admin).
    /// Fails unless this build's deep-amm locks its protocol owner and create-pool fee receiver
    /// to this vault.
    pub fn initialize_splitter(
        ctx: Context<InitializeSplitter>,
        params: SplitterParams,
    ) -> Result<()> {
        splitter::initialize_splitter_handler(ctx, params)
    }

    /// Timelocked splitter change, step 1 (admin). Delay = `Config.timelock_seconds`.
    pub fn queue_splitter_update(
        ctx: Context<QueueSplitterUpdate>,
        params: SplitterParams,
    ) -> Result<()> {
        splitter::queue_splitter_update_handler(ctx, params)
    }

    /// Timelocked splitter change, step 2. PERMISSIONLESS after eta (within the grace window).
    pub fn apply_splitter_update(ctx: Context<ApplySplitterUpdate>) -> Result<()> {
        splitter::apply_splitter_update_handler(ctx)
    }

    /// Admin veto for a queued splitter change.
    pub fn cancel_splitter_update(ctx: Context<CancelSplitterUpdate>) -> Result<()> {
        splitter::cancel_splitter_update_handler(ctx)
    }

    /// PERMISSIONLESS: unwraps the vault's WSOL, pays the builder exactly 10% of all revenue
    /// over time and the rest to the configured destinations by bps. Destinations follow in
    /// `remaining_accounts`, writable, in config order.
    pub fn distribute<'info>(ctx: Context<'info, Distribute<'info>>) -> Result<()> {
        splitter::distribute_handler(ctx)
    }

    /// Admin: moves non-WSOL tokens that reached the fee vault (legacy token-side DeepSwap
    /// protocol fees) to a token account of `config.fee_recipient`. Outside the 10% split
    /// (docs/V1_FEES.md Q12); WSOL can only leave through `distribute`.
    pub fn withdraw_vault_tokens(ctx: Context<WithdrawVaultTokens>, amount: u64) -> Result<()> {
        splitter::withdraw_vault_tokens_handler(ctx, amount)
    }

    /// Graduates a completed curve into a deep-amm (DeepSwap CPMM) pool, non-custodially:
    /// the pool is created via CPI with `lp_sol` (as WSOL) and `lp_tokens` from
    /// `math::graduation_allocation`, every LP token received is burned (permanent
    /// lock), and reserve tokens not needed for the pool are burned.
    ///
    /// DEEP V1: when the configured AmmConfig is a V1 config the pool is created through
    /// deep-amm `initialize_with_permission_v1` with the token's immutable reward model and
    /// reward rate (`curve.reward_model`, `curve.creator_fee_bps`: the same rate the curve
    /// charged) and SOL as its quote: every DeepSwap fee of the pool is taken in
    /// SOL, and the reward part (Creator / Holder tokens) accrues for `reward_recipient`, the
    /// token's creator or the token's holder vault, which is recorded as the pool's
    /// `pool_creator`. A Holder token's curve reward fees are swept to its holder vault here
    /// when the vault can hold them (same rule as `sweep_holder_fees`; skipped, never failed,
    /// otherwise, and they stay sweepable). When the configured AmmConfig is still a legacy
    /// one, the pool is created through `initialize_with_permission` exactly as before V1
    /// (the AmmConfig's creator fee, in SOL), with the same `reward_recipient`.
    ///
    /// PERMISSIONLESS (security review F2): a completed curve's SOL has no other way out, so
    /// no key can withhold it. The instruction has no signer account at all; whoever sends
    /// the transaction pays its network fee and nothing else, and receives nothing. Every
    /// account is pinned by seeds or address, and every lamport and token has a fixed
    /// destination: the pool (LP burned), the burn, the reward recipient's holder vault
    /// (a Holder token's curve fees) and the DEEP fee vault (everything else: the
    /// migration fee minus the pool costs, the rent of the two temporary token accounts,
    /// SOL or WSOL anyone donated to them or to `pool_creator`). `Config.migration_authority`
    /// is not read. deep-amm cannot be made to refuse the pool: for this payer it needs no
    /// `Permission`, ignores `disable_create_pool` and caps the create-pool fee.
    ///
    /// Pool creation costs (deep-amm create-pool fee + rent, and the temporary accounts'
    /// rent until they are closed here) are paid out of the migration fee; the rest goes to
    /// the DEEP fee vault. If the migration fee does not cover the costs, anyone can
    /// top up the `pool_creator` PDA with SOL and retry (that PDA is shared by every
    /// graduation, and each one sweeps what is left of it to the fee vault, so top up in
    /// the same transaction or right before the retry). Idempotent: a second call
    /// fails with `AlreadyGraduated`.
    pub fn graduate(ctx: Context<Graduate>) -> Result<()> {
        let curve = &ctx.accounts.curve;
        require!(curve.complete, DeepError::CurveNotComplete);
        require!(!curve.graduated, DeepError::AlreadyGraduated);
        let alloc = math::graduation_allocation(&curve.to_math(), curve.migration_fee_bps)
            .map_err(DeepError::from)?;

        // Flip state first; any CPI failure below reverts the whole transaction.
        let pool_key = ctx.accounts.pool_state.key();
        ctx.accounts.curve.graduated = true;
        ctx.accounts.curve.real_sol_reserves = 0;
        ctx.accounts.curve.pool = pool_key;

        let mint_key = ctx.accounts.mint.key();
        let curve_bump = [ctx.accounts.curve.bump];
        let curve_seeds: &[&[u8]] = &[CURVE_SEED, mint_key.as_ref(), &curve_bump];
        let pc_bump = [ctx.bumps.pool_creator];
        let pc_seeds: &[&[u8]] = &[POOL_CREATOR_SEED, &pc_bump];
        let pool_bump = [ctx.bumps.pool_state];
        let pool_seeds: &[&[u8]] = &[RAYDIUM_POOL_SEED, mint_key.as_ref(), &pool_bump];
        let pc_signer: &[&[&[u8]]] = &[pc_seeds];
        let a = ctx.accounts;
        let token_program = a.token_program.key();

        // 1. SOL: curve PDA → pool creator (direct; the curve is program-owned). The pool
        //    creator then pays for everything, so no caller fronts or receives a lamport.
        //    Its first payment is `lp_sol` plus the token-account rent to the WSOL account's
        //    address. The curve is appended to that system transfer's account list so the
        //    runtime syncs the direct debit together with the credit (otherwise the CPI
        //    fails with UnbalancedInstruction).
        a.curve.to_account_info().sub_lamports(alloc.raised_sol)?;
        a.pool_creator
            .to_account_info()
            .add_lamports(alloc.raised_sol)?;
        // An account that already holds its rent (created or pre-funded by anyone) needs
        // none; whatever it holds beyond `lp_sol` ends in the fee vault (step 5).
        let token_account_rent = Rent::get()?.minimum_balance(TokenAccount::LEN);
        let wsol_rent = token_account_rent.saturating_sub(a.creator_wsol.lamports());
        let mut ix = anchor_lang::solana_program::system_instruction::transfer(
            &a.pool_creator.key(),
            &a.creator_wsol.key(),
            alloc
                .lp_sol
                .checked_add(wsol_rent)
                .ok_or(DeepError::Overflow)?,
        );
        ix.accounts.push(AccountMeta::new(a.curve.key(), false));
        invoke_signed(
            &ix,
            &[
                a.pool_creator.to_account_info(),
                a.creator_wsol.to_account_info(),
                a.curve.to_account_info(),
                a.system_program.to_account_info(),
            ],
            pc_signer,
        )?;

        // 2. The pool creator's two temporary token accounts (its WSOL and token ATAs),
        //    created here if they do not exist yet, payer = the pool creator. The WSOL
        //    account is already funded, so its creation costs nothing and it starts with
        //    at least `lp_sol` WSOL; `sync_native` covers one that existed before.
        for (ata, mint) in [
            (&a.creator_wsol, a.wsol_mint.to_account_info()),
            (&a.creator_token, a.mint.to_account_info()),
        ] {
            associated_token::create_idempotent(CpiContext::new_with_signer(
                a.associated_token_program.key(),
                associated_token::Create {
                    payer: a.pool_creator.to_account_info(),
                    associated_token: ata.to_account_info(),
                    authority: a.pool_creator.to_account_info(),
                    mint,
                    system_program: a.system_program.to_account_info(),
                    token_program: a.token_program.to_account_info(),
                },
                pc_signer,
            ))?;
        }
        token::sync_native(CpiContext::new(
            token_program,
            token::SyncNative {
                account: a.creator_wsol.to_account_info(),
            },
        ))?;

        // tokens for the pool → pool creator; burn the unneeded reserve.
        token::transfer(
            CpiContext::new_with_signer(
                token_program,
                Transfer {
                    from: a.vault.to_account_info(),
                    to: a.creator_token.to_account_info(),
                    authority: a.curve.to_account_info(),
                },
                &[curve_seeds],
            ),
            alloc.lp_tokens,
        )?;
        if alloc.burn_tokens > 0 {
            token::burn(
                CpiContext::new_with_signer(
                    token_program,
                    Burn {
                        mint: a.mint.to_account_info(),
                        from: a.vault.to_account_info(),
                        authority: a.curve.to_account_info(),
                    },
                    &[curve_seeds],
                ),
                alloc.burn_tokens,
            )?;
        }

        // 3. deep-amm initialize_with_permission[_v1] (hand-encoded; token_0 < token_1 by
        //    pubkey). Fees are taken in WSOL only: on the input of a buy and on the output
        //    of a sell, so DEEP and the reward recipient earn SOL, never the token.
        //    The AmmConfig (pinned in Config) decides the pool's fee model.
        let amm_fee_model = {
            let cfg = a.amm_config.to_account_info();
            require_keys_eq!(
                *cfg.owner,
                raydium::CP_SWAP_PROGRAM_ID,
                DeepError::InvalidPool
            );
            let data = cfg.try_borrow_data()?;
            *data
                .get(raydium::AMM_CONFIG_FEE_MODEL_OFFSET)
                .ok_or(DeepError::InvalidPool)?
        };
        let reward_model = a.curve.reward_model;
        // The pool charges the token's own reward rate, the one the curve charged (bps ->
        // per 1e6); a Standard token has none.
        // It is NOT checked against the current maximum (`Config.max_reward_bps`, a rule for
        // new launches): lowering the maximum can never block a graduation. The `min` only
        // matters for a hypothetical pre-V1 curve whose creator fee was above the ceiling.
        let reward_rate = if reward_model == math::REWARD_MODEL_STANDARD {
            0
        } else {
            u64::from(a.curve.creator_fee_bps.min(math::MAX_REWARD_BPS)) * raydium::RATE_PER_BPS
        };
        let wsol_first = a.wsol_mint.key() < mint_key;
        let creator_fee_on = if wsol_first {
            raydium::CREATOR_FEE_ON_ONLY_TOKEN_0
        } else {
            raydium::CREATOR_FEE_ON_ONLY_TOKEN_1
        };
        let (m0, m1, c0, c1, amt0, amt1) = if wsol_first {
            (
                a.wsol_mint.to_account_info(),
                a.mint.to_account_info(),
                a.creator_wsol.to_account_info(),
                a.creator_token.to_account_info(),
                alloc.lp_sol,
                alloc.lp_tokens,
            )
        } else {
            (
                a.mint.to_account_info(),
                a.wsol_mint.to_account_info(),
                a.creator_token.to_account_info(),
                a.creator_wsol.to_account_info(),
                alloc.lp_tokens,
                alloc.lp_sol,
            )
        };
        let mut data = Vec::with_capacity(42);
        match amm_fee_model {
            raydium::FEE_MODEL_V1 => {
                data.extend_from_slice(&raydium::INITIALIZE_WITH_PERMISSION_V1_DISCRIMINATOR)
            }
            raydium::FEE_MODEL_LEGACY => {
                data.extend_from_slice(&raydium::INITIALIZE_WITH_PERMISSION_DISCRIMINATOR)
            }
            _ => return err!(DeepError::InvalidPool),
        }
        data.extend_from_slice(&amt0.to_le_bytes());
        data.extend_from_slice(&amt1.to_le_bytes());
        data.extend_from_slice(&0u64.to_le_bytes()); // open_time 0 → cp-swap uses now + 1
        data.push(creator_fee_on); // V1: the quote side (WSOL)
        if amm_fee_model == raydium::FEE_MODEL_V1 {
            data.push(reward_model);
            data.extend_from_slice(&reward_rate.to_le_bytes());
        }
        let ix = Instruction {
            program_id: raydium::CP_SWAP_PROGRAM_ID,
            accounts: vec![
                AccountMeta::new(a.pool_creator.key(), true),
                // PoolState.pool_creator: the reward recipient (never a signer).
                AccountMeta::new_readonly(a.reward_recipient.key(), false),
                AccountMeta::new_readonly(a.amm_config.key(), false),
                AccountMeta::new_readonly(a.raydium_authority.key(), false),
                AccountMeta::new(pool_key, true),
                AccountMeta::new_readonly(m0.key(), false),
                AccountMeta::new_readonly(m1.key(), false),
                AccountMeta::new(a.lp_mint.key(), false),
                AccountMeta::new(c0.key(), false),
                AccountMeta::new(c1.key(), false),
                AccountMeta::new(a.creator_lp_token.key(), false),
                AccountMeta::new(a.token_0_vault.key(), false),
                AccountMeta::new(a.token_1_vault.key(), false),
                AccountMeta::new(a.create_pool_fee.key(), false),
                AccountMeta::new(a.observation_state.key(), false),
                AccountMeta::new_readonly(a.permission.key(), false),
                AccountMeta::new_readonly(token_program, false),
                AccountMeta::new_readonly(token_program, false),
                AccountMeta::new_readonly(token_program, false),
                AccountMeta::new_readonly(a.associated_token_program.key(), false),
                AccountMeta::new_readonly(a.system_program.key(), false),
            ],
            data,
        };
        invoke_signed(
            &ix,
            &[
                a.pool_creator.to_account_info(),
                a.reward_recipient.to_account_info(),
                a.amm_config.to_account_info(),
                a.raydium_authority.to_account_info(),
                a.pool_state.to_account_info(),
                m0,
                m1,
                a.lp_mint.to_account_info(),
                c0,
                c1,
                a.creator_lp_token.to_account_info(),
                a.token_0_vault.to_account_info(),
                a.token_1_vault.to_account_info(),
                a.create_pool_fee.to_account_info(),
                a.observation_state.to_account_info(),
                a.permission.to_account_info(),
                a.token_program.to_account_info(),
                a.associated_token_program.to_account_info(),
                a.system_program.to_account_info(),
                a.cp_swap_program.to_account_info(),
            ],
            &[pc_seeds, pool_seeds],
        )?;

        // 4. Burn every LP token received (permanent lock) and close the LP account.
        let lp = {
            let data = a.creator_lp_token.try_borrow_data()?;
            TokenAccount::try_deserialize(&mut &data[..])?
        };
        require_keys_eq!(lp.mint, a.lp_mint.key(), DeepError::InvalidPool);
        require_keys_eq!(lp.owner, a.pool_creator.key(), DeepError::InvalidPool);
        if lp.amount > 0 {
            token::burn(
                CpiContext::new_with_signer(
                    token_program,
                    Burn {
                        mint: a.lp_mint.to_account_info(),
                        from: a.creator_lp_token.to_account_info(),
                        authority: a.pool_creator.to_account_info(),
                    },
                    pc_signer,
                ),
                lp.amount,
            )?;
        }
        close_token_account(
            token_program,
            a.creator_lp_token.to_account_info(),
            a.pool_creator.to_account_info(),
            a.pool_creator.to_account_info(),
            pc_signer,
        )?;

        // 5. Clean up the pool creator's token accounts. Leftover meme tokens (e.g. sent to
        //    the ATA by a third party) are burned so the close cannot be blocked. Both
        //    accounts are closed to the pool creator: their rent, and any WSOL beyond
        //    `lp_sol` (donated, or the rent of a pre-funded account), reach the fee vault
        //    in step 6. Nothing goes to the sender of the transaction.
        let leftover = {
            let data = a.creator_token.try_borrow_data()?;
            let acc = TokenAccount::try_deserialize(&mut &data[..])?;
            require_keys_eq!(acc.mint, mint_key, DeepError::InvalidPool);
            require_keys_eq!(acc.owner, a.pool_creator.key(), DeepError::InvalidPool);
            acc.amount
        };
        if leftover > 0 {
            token::burn(
                CpiContext::new_with_signer(
                    token_program,
                    Burn {
                        mint: a.mint.to_account_info(),
                        from: a.creator_token.to_account_info(),
                        authority: a.pool_creator.to_account_info(),
                    },
                    pc_signer,
                ),
                leftover,
            )?;
        }
        close_token_account(
            token_program,
            a.creator_token.to_account_info(),
            a.pool_creator.to_account_info(),
            a.pool_creator.to_account_info(),
            pc_signer,
        )?;
        close_token_account(
            token_program,
            a.creator_wsol.to_account_info(),
            a.pool_creator.to_account_info(),
            a.pool_creator.to_account_info(),
            pc_signer,
        )?;

        // 6. Whatever is left with the pool creator (migration fee minus pool costs, the
        //    closed accounts' rent and surplus, plus any top-up) is DEEP revenue: it goes to
        //    the fee vault (the splitter).
        let rest = a.pool_creator.lamports();
        if rest > 0 {
            system_program::transfer(
                CpiContext::new_with_signer(
                    a.system_program.key(),
                    system_program::Transfer {
                        from: a.pool_creator.to_account_info(),
                        to: a.fee_vault.to_account_info(),
                    },
                    pc_signer,
                ),
                rest,
            )?;
        }
        // The curve's accrued protocol fees go to the fee vault too (no CPI follows, so
        // the direct lamport moves here are safe).
        let swept = a.curve.protocol_fees_unclaimed;
        if swept > 0 {
            a.curve.protocol_fees_unclaimed = 0;
            a.curve.to_account_info().sub_lamports(swept)?;
            a.fee_vault.to_account_info().add_lamports(swept)?;
            emit!(ProtocolFeesSwept {
                mint: mint_key,
                amount: swept
            });
        }
        // A Holder token's curve reward fees go to its holder vault (`reward_recipient`),
        // under the same rule as `sweep_holder_fees`: the vault must end at or above the
        // 0-byte rent minimum. When it would not (or the caller passed the vault read-only),
        // this step is skipped, never failed: the fees stay on the curve, counted in
        // `holder_fees_unclaimed`, and `sweep_holder_fees` moves them later.
        let held = a.curve.holder_fees_unclaimed;
        if held > 0 && reward_model == math::REWARD_MODEL_HOLDER {
            let vault = a.reward_recipient.to_account_info();
            let rent_min = Rent::get()?.minimum_balance(0);
            let fits = vault.is_writable
                && vault.owner == &system_program::ID
                && vault
                    .lamports()
                    .checked_add(held)
                    .is_some_and(|after| after >= rent_min);
            if fits {
                a.curve.holder_fees_unclaimed = 0;
                a.curve.to_account_info().sub_lamports(held)?;
                vault.add_lamports(held)?;
                emit!(HolderFeesSwept {
                    mint: mint_key,
                    holder_vault: vault.key(),
                    amount: held,
                });
            }
        }
        a.curve.assert_solvent()?;

        emit!(Graduated {
            mint: mint_key,
            lp_sol: alloc.lp_sol,
            lp_tokens: alloc.lp_tokens,
            burned_tokens: alloc.burn_tokens,
            migration_fee: alloc.migration_fee,
            timestamp: Clock::get()?.unix_timestamp,
        });
        Ok(())
    }
}

fn close_token_account<'info>(
    token_program: Pubkey,
    account: AccountInfo<'info>,
    destination: AccountInfo<'info>,
    authority: AccountInfo<'info>,
    signer: &[&[&[u8]]],
) -> Result<()> {
    token::close_account(CpiContext::new_with_signer(
        token_program,
        token::CloseAccount {
            account,
            destination,
            authority,
        },
        signer,
    ))
}

/// Grows a program-owned account to `new_len` (zero-filled), topping up rent from
/// `payer` first. No-op if it is already at least that large.
fn grow<'info>(
    account: &AccountInfo<'info>,
    payer: &AccountInfo<'info>,
    system_program: &AccountInfo<'info>,
    new_len: usize,
) -> Result<()> {
    if account.data_len() >= new_len {
        return Ok(());
    }
    // The payer always funds the rent DELTA. Comparing the new rent against the
    // account's total balance would be wrong for a curve: its balance also holds the
    // SOL reserves and unclaimed fees, so the extra rent would silently come out of
    // them and the curve would fail `assert_solvent` afterwards.
    let rent = Rent::get()?;
    let top_up = rent
        .minimum_balance(new_len)
        .saturating_sub(rent.minimum_balance(account.data_len()));
    if top_up > 0 {
        system_program::transfer(
            CpiContext::new(
                system_program.key(),
                system_program::Transfer {
                    from: payer.clone(),
                    to: account.clone(),
                },
            ),
            top_up,
        )?;
    }
    account.resize(new_len)?;
    Ok(())
}

fn check_deadline(deadline: i64) -> Result<()> {
    require!(
        Clock::get()?.unix_timestamp <= deadline,
        DeepError::DeadlineExceeded
    );
    Ok(())
}

// ───────────────────────────── state ─────────────────────────────

#[account]
#[derive(InitSpace)]
pub struct Config {
    pub admin: Pubkey,
    pub pending_admin: Pubkey,
    pub fee_recipient: Pubkey,
    /// NO AUTHORITY ANY MORE (security review F2): `graduate` is permissionless and no
    /// instruction reads this field. It is kept for layout compatibility and names, by
    /// convention only, the key DEEP's own graduation crank signs with. It must still be
    /// non-zero (`ConfigParams::validate`, unchanged).
    pub migration_authority: Pubkey,
    pub protocol_fee_bps: u16,
    pub creator_fee_bps: u16,
    pub migration_fee_bps: u16,
    pub initial_virtual_sol: u64,
    pub initial_virtual_token: u64,
    pub curve_supply: u64,
    pub token_total_supply: u64,
    pub decimals: u8,
    pub paused: bool,
    pub bump: u8,
    /// deep-amm AmmConfig that graduated pools are created under (appended field).
    pub raydium_amm_config: Pubkey,
    /// Delay for queued config changes, seconds (appended field).
    pub timelock_seconds: u32,
    /// Launch fee in US cents, priced in SOL via Pyth at create_token (appended, v2).
    /// 0 = no fee. Capped at MAX_LAUNCH_FEE_USD_CENTS.
    pub launch_fee_usd_cents: u16,
    /// DEEP V1 (appended, v3). Protocol fee on SELLS; `protocol_fee_bps` is the BUY rate.
    pub sell_protocol_fee_bps: u16,
    /// The CURRENT maximum reward rate a creator may choose at `create_token` (eighth round,
    /// 2026-10-07), at most the hard ceiling `math::MAX_REWARD_BPS` (500). Changed through the
    /// config timelock. It applies to new launches only: a live curve keeps its rate, and
    /// `graduate` never looks at it.
    pub max_reward_bps: u16,
    /// RESERVED (v3 layout): stored, read by no instruction.
    pub reserved_bps: u16,
}

impl Config {
    fn apply(&mut self, p: &ConfigParams) {
        self.fee_recipient = p.fee_recipient;
        self.migration_authority = p.migration_authority;
        self.protocol_fee_bps = p.protocol_fee_bps;
        self.creator_fee_bps = p.creator_fee_bps;
        self.migration_fee_bps = p.migration_fee_bps;
        self.initial_virtual_sol = p.initial_virtual_sol;
        self.initial_virtual_token = p.initial_virtual_token;
        self.curve_supply = p.curve_supply;
        self.token_total_supply = p.token_total_supply;
        self.decimals = p.decimals;
        self.raydium_amm_config = p.raydium_amm_config;
        self.timelock_seconds = p.timelock_seconds;
        self.launch_fee_usd_cents = p.launch_fee_usd_cents;
        self.sell_protocol_fee_bps = p.sell_protocol_fee_bps;
        self.max_reward_bps = p.max_reward_bps;
        self.reserved_bps = p.reserved_bps;
    }
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace)]
pub struct ConfigParams {
    pub fee_recipient: Pubkey,
    pub migration_authority: Pubkey,
    pub protocol_fee_bps: u16,
    pub creator_fee_bps: u16,
    pub migration_fee_bps: u16,
    pub initial_virtual_sol: u64,
    pub initial_virtual_token: u64,
    pub curve_supply: u64,
    pub token_total_supply: u64,
    pub decimals: u8,
    pub raydium_amm_config: Pubkey,
    /// Delay applied to every later config change (0..=MAX_TIMELOCK_SECONDS).
    pub timelock_seconds: u32,
    /// Launch fee in US cents (0..=MAX_LAUNCH_FEE_USD_CENTS). Appended in v2.
    pub launch_fee_usd_cents: u16,
    /// Appended in v3 (DEEP V1): sell-side protocol fee; `protocol_fee_bps` is the buy side.
    pub sell_protocol_fee_bps: u16,
    /// Appended in v3: the current maximum reward rate for new launches (<= 500).
    pub max_reward_bps: u16,
    /// Appended in v3. RESERVED: stored, read by no instruction.
    pub reserved_bps: u16,
}

impl ConfigParams {
    pub fn validate(&self) -> Result<()> {
        // Hard caps (only a program upgrade changes them): DEEP's protocol fee on each side
        // (plus the legacy creator fee, unused by new launches) <= MAX_TOTAL_FEE_BPS (10%);
        // the current maximum reward rate <= MAX_REWARD_BPS (5%). A launch then checks its own
        // reward rate against both.
        math::validate_fee_schedule(
            self.protocol_fee_bps,
            self.sell_protocol_fee_bps,
            self.creator_fee_bps,
            0,
            0,
        )
        .map_err(DeepError::from)?;
        require!(
            self.max_reward_bps <= math::MAX_REWARD_BPS,
            DeepError::InvalidRewardRate
        );
        require!(self.migration_fee_bps <= 500, DeepError::InvalidParams);
        require!(self.decimals <= 9, DeepError::InvalidParams);
        // Tokens must be left for the pool (`curve_supply < token_total_supply`), and a
        // completed curve must always have SOL and tokens for it (security review F5): a
        // Config under which no curve could graduate would lock every curve's SOL for good.
        require!(
            self.curve_supply > 0 && self.curve_supply < self.token_total_supply,
            DeepError::InvalidParams
        );
        require!(
            self.initial_virtual_token > self.curve_supply,
            DeepError::InvalidParams
        );
        require!(self.initial_virtual_sol > 0, DeepError::InvalidParams);
        require!(
            math::validate_graduation_params(
                self.initial_virtual_sol,
                self.initial_virtual_token,
                self.curve_supply,
                self.token_total_supply,
                self.migration_fee_bps,
            )
            .is_ok(),
            DeepError::GraduationImpossible
        );
        require!(
            self.timelock_seconds <= MAX_TIMELOCK_SECONDS,
            DeepError::InvalidParams
        );
        require!(
            self.launch_fee_usd_cents <= MAX_LAUNCH_FEE_USD_CENTS,
            DeepError::LaunchFeeAboveCap
        );
        require!(
            self.fee_recipient != Pubkey::default()
                && self.migration_authority != Pubkey::default()
                && self.raydium_amm_config != Pubkey::default(),
            DeepError::InvalidParams
        );
        Ok(())
    }
}

/// The single queued config change (reused; `active` marks whether one is pending).
#[account]
#[derive(InitSpace)]
pub struct PendingConfig {
    pub active: bool,
    /// Earliest unix time `apply_config_update` succeeds.
    pub eta: i64,
    pub queued_at: i64,
    pub params: ConfigParams,
    pub bump: u8,
}

/// Program-owned PDA that accrues protocol trade fees and migration fees.
#[account]
#[derive(InitSpace)]
pub struct Treasury {
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct BondingCurve {
    pub mint: Pubkey,
    pub creator: Pubkey,
    pub virtual_sol_reserves: u64,
    pub virtual_token_reserves: u64,
    pub real_sol_reserves: u64,
    pub real_token_reserves: u64,
    pub curve_supply: u64,
    pub token_total_supply: u64,
    /// Fees are snapshotted at launch so config changes never affect live curves.
    pub protocol_fee_bps: u16,
    pub creator_fee_bps: u16,
    pub migration_fee_bps: u16,
    pub creator_fees_unclaimed: u64,
    pub complete: bool,
    pub graduated: bool,
    pub created_at: i64,
    pub bump: u8,
    /// deep-amm pool created at graduation (default until graduated). Appended field.
    pub pool: Pubkey,
    /// Protocol fees (trade + launch) held on this PDA until sweep_protocol_fees.
    /// Appended in v2.
    pub protocol_fees_unclaimed: u64,
    /// DEEP V1 (appended, v3). Protocol fee on SELLS, snapshotted at launch;
    /// `protocol_fee_bps` is the BUY rate.
    pub sell_protocol_fee_bps: u16,
    /// 0 Standard, 1 Creator, 2 Holder (`math::REWARD_MODEL_*`). Chosen at `create_token`,
    /// never changed afterwards. Graduation carries it into the DeepSwap pool (Phase 3).
    /// `creator_fee_bps` is this token's reward rate on both sides.
    pub reward_model: u8,
    /// Holder-model reward fees held on this PDA until `sweep_holder_fees`.
    pub holder_fees_unclaimed: u64,
}

impl BondingCurve {
    pub fn to_math(&self) -> Curve {
        Curve {
            virtual_sol_reserves: self.virtual_sol_reserves,
            virtual_token_reserves: self.virtual_token_reserves,
            real_sol_reserves: self.real_sol_reserves,
            real_token_reserves: self.real_token_reserves,
            curve_supply: self.curve_supply,
            token_total_supply: self.token_total_supply,
            complete: self.complete,
        }
    }

    pub fn fees_v1(&self) -> FeesV1 {
        FeesV1 {
            buy_protocol_fee_bps: self.protocol_fee_bps,
            sell_protocol_fee_bps: self.sell_protocol_fee_bps,
            reward_bps: self.creator_fee_bps,
            reward_model: self.reward_model,
        }
    }

    /// The fees of one side of this token's trades.
    pub fn fees(&self, is_buy: bool) -> Fees {
        math::side_fees(&self.fees_v1(), is_buy)
    }

    /// Books one trade's fee: the protocol part, and the reward part to the creator
    /// (Standard, Creator) or to the holders (Holder). Returns where each lamport went.
    fn accrue_fees(&mut self, fees: &math::FeeSplit) -> Result<math::FeeRouting> {
        let r = math::route_fees(self.reward_model, fees).map_err(DeepError::from)?;
        self.creator_fees_unclaimed = self
            .creator_fees_unclaimed
            .checked_add(r.creator)
            .ok_or(DeepError::Overflow)?;
        self.holder_fees_unclaimed = self
            .holder_fees_unclaimed
            .checked_add(r.holder)
            .ok_or(DeepError::Overflow)?;
        self.protocol_fees_unclaimed = self
            .protocol_fees_unclaimed
            .checked_add(r.protocol)
            .ok_or(DeepError::Overflow)?;
        Ok(r)
    }

    fn set_from_math(&mut self, c: &Curve) {
        self.virtual_sol_reserves = c.virtual_sol_reserves;
        self.virtual_token_reserves = c.virtual_token_reserves;
        self.real_sol_reserves = c.real_sol_reserves;
        self.real_token_reserves = c.real_token_reserves;
        self.complete = c.complete;
    }
}

trait Solvency {
    fn assert_solvent(&self) -> Result<()>;
}

impl<'info> Solvency for Account<'info, BondingCurve> {
    /// The PDA must always hold rent + real reserves + unclaimed creator, holder and protocol
    /// fees.
    fn assert_solvent(&self) -> Result<()> {
        let info = self.to_account_info();
        let rent = Rent::get()?.minimum_balance(info.data_len());
        let owed = (rent as u128)
            + (self.real_sol_reserves as u128)
            + (self.creator_fees_unclaimed as u128)
            + (self.holder_fees_unclaimed as u128)
            + (self.protocol_fees_unclaimed as u128);
        require!((info.lamports() as u128) >= owed, DeepError::InsolventCurve);
        Ok(())
    }
}

// ─────────────────────────── accounts ───────────────────────────

#[derive(Accounts)]
pub struct InitializeConfig<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(init, payer = admin, space = 8 + Config::INIT_SPACE, seeds = [CONFIG_SEED], bump)]
    pub config: Account<'info, Config>,
    #[account(init, payer = admin, space = 8 + Treasury::INIT_SPACE, seeds = [TREASURY_SEED], bump)]
    pub treasury: Account<'info, Treasury>,
    #[account(constraint = program.programdata_address()? == Some(program_data.key()) @ DeepError::Unauthorized)]
    pub program: Program<'info, crate::program::DeepCurve>,
    #[account(constraint = program_data.upgrade_authority_address == Some(admin.key()) @ DeepError::Unauthorized)]
    pub program_data: Account<'info, ProgramData>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct WithdrawProtocolFees<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Account<'info, Config>,
    #[account(mut, seeds = [TREASURY_SEED], bump = treasury.bump)]
    pub treasury: Account<'info, Treasury>,
    /// CHECK: destination only; must equal config.fee_recipient.
    #[account(mut, address = config.fee_recipient @ DeepError::InvalidFeeRecipient)]
    pub fee_recipient: UncheckedAccount<'info>,
}

#[derive(Accounts)]
pub struct QueueConfigUpdate<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Account<'info, Config>,
    #[account(
        init_if_needed,
        payer = admin,
        space = 8 + PendingConfig::INIT_SPACE,
        seeds = [PENDING_CONFIG_SEED],
        bump,
    )]
    pub pending_config: Account<'info, PendingConfig>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ApplyConfigUpdate<'info> {
    #[account(mut, seeds = [CONFIG_SEED], bump = config.bump)]
    pub config: Account<'info, Config>,
    #[account(mut, seeds = [PENDING_CONFIG_SEED], bump = pending_config.bump)]
    pub pending_config: Account<'info, PendingConfig>,
}

#[derive(Accounts)]
pub struct CancelConfigUpdate<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Account<'info, Config>,
    #[account(mut, seeds = [PENDING_CONFIG_SEED], bump = pending_config.bump)]
    pub pending_config: Account<'info, PendingConfig>,
}

#[derive(Accounts)]
pub struct AdminOnly<'info> {
    pub admin: Signer<'info>,
    #[account(mut, seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Account<'info, Config>,
}

#[derive(Accounts)]
pub struct AcceptAdmin<'info> {
    pub pending_admin: Signer<'info>,
    #[account(
        mut,
        seeds = [CONFIG_SEED],
        bump = config.bump,
        constraint = config.pending_admin == pending_admin.key() @ DeepError::Unauthorized,
        constraint = config.pending_admin != Pubkey::default() @ DeepError::Unauthorized,
    )]
    pub config: Account<'info, Config>,
}

#[derive(Accounts)]
pub struct CreateToken<'info> {
    #[account(mut)]
    pub creator: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, Config>>,
    #[account(
        init,
        payer = creator,
        mint::decimals = config.decimals,
        mint::authority = curve,
    )]
    pub mint: Box<Account<'info, Mint>>,
    #[account(
        init,
        payer = creator,
        space = 8 + BondingCurve::INIT_SPACE,
        seeds = [CURVE_SEED, mint.key().as_ref()],
        bump,
    )]
    pub curve: Box<Account<'info, BondingCurve>>,
    #[account(
        init,
        payer = creator,
        associated_token::mint = mint,
        associated_token::authority = curve,
    )]
    pub vault: Box<Account<'info, TokenAccount>>,
    /// CHECK: created by the Metaplex program; address verified via seeds.
    #[account(
        mut,
        seeds = [b"metadata", token_metadata_program.key().as_ref(), mint.key().as_ref()],
        bump,
        seeds::program = token_metadata_program.key(),
    )]
    pub metadata: UncheckedAccount<'info>,
    /// CHECK: Pyth SOL/USD PriceUpdateV2 (sponsored feed, address pinned). Owner, feed id,
    /// verification level, staleness and confidence are checked in the handler (only
    /// when the launch fee is non-zero).
    #[account(address = pyth::SOL_USD_PRICE_UPDATE @ DeepError::PriceFeedInvalid)]
    pub price_update: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_metadata_program: Program<'info, Metadata>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct Trade<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, Config>>,
    pub mint: Box<Account<'info, Mint>>,
    #[account(
        mut,
        seeds = [CURVE_SEED, mint.key().as_ref()],
        bump = curve.bump,
        has_one = mint,
    )]
    pub curve: Box<Account<'info, BondingCurve>>,
    #[account(mut, associated_token::mint = mint, associated_token::authority = curve)]
    pub vault: Box<Account<'info, TokenAccount>>,
    #[account(
        init_if_needed,
        payer = user,
        associated_token::mint = mint,
        associated_token::authority = user,
    )]
    pub user_token: Box<Account<'info, TokenAccount>>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct SweepProtocolFees<'info> {
    #[account(mut, seeds = [CURVE_SEED, curve.mint.as_ref()], bump = curve.bump)]
    pub curve: Account<'info, BondingCurve>,
    /// The DEEP fee vault (system-owned PDA, funded to its rent minimum by
    /// `initialize_splitter`).
    #[account(mut, seeds = [FEE_VAULT_SEED], bump)]
    pub fee_vault: SystemAccount<'info>,
}

#[derive(Accounts)]
pub struct SweepHolderFees<'info> {
    #[account(mut, seeds = [CURVE_SEED, curve.mint.as_ref()], bump = curve.bump)]
    pub curve: Account<'info, BondingCurve>,
    /// The token's holder vault: the deep-rewards PDA `["holder_vault", mint]`, system-owned
    /// and data-less (deep-rewards never allocates it). Any other account is rejected.
    #[account(
        mut,
        seeds = [HOLDER_VAULT_SEED, curve.mint.as_ref()],
        bump,
        seeds::program = DEEP_REWARDS_PROGRAM_ID,
    )]
    pub holder_vault: SystemAccount<'info>,
}

#[derive(Accounts)]
pub struct MigrateConfig<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    /// CHECK: raw v1/v2/v3 Config; owner, discriminator and size checked in the handler.
    #[account(mut, seeds = [CONFIG_SEED], bump)]
    pub config: UncheckedAccount<'info>,
    /// CHECK: raw PendingConfig (may not exist); owner/size/discriminator checked.
    #[account(mut, seeds = [PENDING_CONFIG_SEED], bump)]
    pub pending_config: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct MigrateCurve<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    /// CHECK: only used for the curve PDA seeds.
    pub mint: UncheckedAccount<'info>,
    /// CHECK: raw v1/v2/v3 BondingCurve; owner, discriminator and size checked in the handler.
    #[account(mut, seeds = [CURVE_SEED, mint.key().as_ref()], bump)]
    pub curve: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ClaimCreatorFees<'info> {
    #[account(mut)]
    pub creator: Signer<'info>,
    #[account(
        mut,
        seeds = [CURVE_SEED, curve.mint.as_ref()],
        bump = curve.bump,
        has_one = creator @ DeepError::Unauthorized,
    )]
    pub curve: Account<'info, BondingCurve>,
}

/// PERMISSIONLESS: no signer account. Every account is pinned by seeds or address, here or by
/// deep-amm; the transaction's fee payer is not part of the instruction and gains nothing.
#[derive(Accounts)]
pub struct Graduate<'info> {
    #[account(seeds = [CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, Config>>,
    /// The DEEP fee vault (DEEP V1; was the Treasury, same position).
    #[account(mut, seeds = [FEE_VAULT_SEED], bump)]
    pub fee_vault: SystemAccount<'info>,
    #[account(mut)]
    pub mint: Box<Account<'info, Mint>>,
    #[account(
        mut,
        seeds = [CURVE_SEED, mint.key().as_ref()],
        bump = curve.bump,
        has_one = mint,
    )]
    pub curve: Box<Account<'info, BondingCurve>>,
    #[account(mut, associated_token::mint = mint, associated_token::authority = curve)]
    pub vault: Box<Account<'info, TokenAccount>>,
    /// CHECK: the only address this token's DeepSwap reward fees can go to
    /// (`reward_recipient_address`): the token's holder vault (deep-rewards PDA
    /// `["holder_vault", mint]`) for a Holder token, the token's creator otherwise. Recorded
    /// as the pool's `pool_creator`. Never signs. For a Holder token pass it WRITABLE so the
    /// curve's holder fees can be swept to it here (read-only: that sweep is skipped); it
    /// receives nothing else in this instruction.
    #[account(address = reward_recipient_address(&curve) @ DeepError::InvalidPool)]
    pub reward_recipient: UncheckedAccount<'info>,
    #[account(mut, seeds = [POOL_CREATOR_SEED], bump)]
    pub pool_creator: SystemAccount<'info>,
    /// CHECK: ATA(mint, pool_creator) (address checked). Temporary: created by the handler if
    /// missing (payer = `pool_creator`), verified (mint, owner) and closed in the same
    /// instruction.
    #[account(
        mut,
        address = get_associated_token_address(&pool_creator.key(), &mint.key()) @ DeepError::InvalidPool,
    )]
    pub creator_token: UncheckedAccount<'info>,
    #[account(address = anchor_spl::token::spl_token::native_mint::ID @ DeepError::InvalidPool)]
    pub wsol_mint: Box<Account<'info, Mint>>,
    /// CHECK: ATA(WSOL, pool_creator) (address checked). Temporary, as `creator_token`; the
    /// token program and deep-amm verify it when it is used.
    #[account(
        mut,
        address = get_associated_token_address(&pool_creator.key(), &wsol_mint.key()) @ DeepError::InvalidPool,
    )]
    pub creator_wsol: UncheckedAccount<'info>,
    /// CHECK: ATA(pool_creator, lp_mint); created by cp-swap, mint/owner verified after CPI.
    #[account(mut)]
    pub creator_lp_token: UncheckedAccount<'info>,
    /// CHECK: deep_curve PDA used as the deep-amm pool_state; initialized by deep-amm.
    #[account(mut, seeds = [RAYDIUM_POOL_SEED, mint.key().as_ref()], bump)]
    pub pool_state: UncheckedAccount<'info>,
    /// CHECK: pinned in config; deserialized and validated by cp-swap.
    #[account(address = config.raydium_amm_config @ DeepError::InvalidPool)]
    pub amm_config: UncheckedAccount<'info>,
    /// CHECK: deep-amm `Permission` PDA of `pool_creator`; deep-amm verifies its address.
    /// It does not have to exist: deep-amm requires no permission from this payer.
    pub permission: UncheckedAccount<'info>,
    /// CHECK: cp-swap vault/LP-mint authority PDA; seeds verified by cp-swap.
    pub raydium_authority: UncheckedAccount<'info>,
    /// CHECK: seeds ["pool_lp_mint", pool_state] verified and initialized by cp-swap.
    #[account(mut)]
    pub lp_mint: UncheckedAccount<'info>,
    /// CHECK: seeds ["pool_vault", pool_state, token_0_mint] verified by cp-swap.
    #[account(mut)]
    pub token_0_vault: UncheckedAccount<'info>,
    /// CHECK: seeds ["pool_vault", pool_state, token_1_mint] verified by cp-swap.
    #[account(mut)]
    pub token_1_vault: UncheckedAccount<'info>,
    /// CHECK: deep-amm create-pool fee WSOL account; address checked here and by deep-amm.
    #[account(mut, address = raydium::CREATE_POOL_FEE_RECEIVER @ DeepError::InvalidPool)]
    pub create_pool_fee: UncheckedAccount<'info>,
    /// CHECK: seeds ["observation", pool_state] verified and initialized by cp-swap.
    #[account(mut)]
    pub observation_state: UncheckedAccount<'info>,
    /// CHECK: executable; address pinned to deep-amm.
    #[account(address = raydium::CP_SWAP_PROGRAM_ID @ DeepError::InvalidPool)]
    pub cp_swap_program: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

// ──────────────────────────── events ────────────────────────────

#[event]
pub struct ConfigUpdated {
    pub admin: Pubkey,
}

#[event]
pub struct ConfigUpdateQueued {
    pub eta: i64,
    pub queued_at: i64,
    pub params: ConfigParams,
}

#[event]
pub struct ConfigUpdateCancelled {
    pub eta: i64,
}

#[event]
pub struct PauseChanged {
    pub paused: bool,
}

#[event]
pub struct TokenCreated {
    pub mint: Pubkey,
    pub creator: Pubkey,
    pub name: String,
    pub symbol: String,
    pub uri: String,
    pub curve_supply: u64,
    pub token_total_supply: u64,
    /// Appended (DEEP V1): 0 Standard, 1 Creator, 2 Holder.
    pub reward_model: u8,
    /// Appended (DEEP V1, sixth round): the reward rate the creator chose, bps per side.
    pub reward_bps: u16,
}

#[event]
pub struct TradeEvent {
    pub mint: Pubkey,
    pub trader: Pubkey,
    pub is_buy: bool,
    pub sol_amount: u64,
    pub token_amount: u64,
    pub protocol_fee: u64,
    pub creator_fee: u64,
    pub virtual_sol_reserves: u64,
    pub virtual_token_reserves: u64,
    pub real_sol_reserves: u64,
    pub real_token_reserves: u64,
    pub timestamp: i64,
    /// Appended (DEEP V1). The token's reward model.
    pub reward_model: u8,
    /// Appended (DEEP V1). The reward part of the fee when the model is Holder (then
    /// `creator_fee` is 0); 0 otherwise. `protocol_fee + creator_fee + holder_fee` is the
    /// whole fee of the trade.
    pub holder_fee: u64,
}

#[event]
pub struct HolderFeesSwept {
    pub mint: Pubkey,
    pub holder_vault: Pubkey,
    pub amount: u64,
}

#[event]
pub struct CurveCompleted {
    pub mint: Pubkey,
    pub real_sol_reserves: u64,
}

#[event]
pub struct CreatorFeesClaimed {
    pub mint: Pubkey,
    pub creator: Pubkey,
    pub amount: u64,
}

#[event]
pub struct ProtocolFeesWithdrawn {
    pub recipient: Pubkey,
    pub amount: u64,
}

#[event]
pub struct ProtocolFeesSwept {
    pub mint: Pubkey,
    pub amount: u64,
}

#[event]
pub struct LaunchFeeCharged {
    pub mint: Pubkey,
    pub creator: Pubkey,
    pub usd_cents: u16,
    pub lamports: u64,
    /// Pyth SOL/USD price · 10^exponent USD
    pub price: i64,
    pub exponent: i32,
    pub publish_time: i64,
}

#[event]
pub struct Graduated {
    pub mint: Pubkey,
    pub lp_sol: u64,
    pub lp_tokens: u64,
    pub burned_tokens: u64,
    pub migration_fee: u64,
    pub timestamp: i64,
}

// ──────────────────────────── errors ────────────────────────────

#[error_code]
pub enum DeepError {
    #[msg("Protocol is paused")]
    Paused,
    #[msg("Unauthorized")]
    Unauthorized,
    #[msg("Amount must be greater than zero")]
    ZeroAmount,
    #[msg("Bonding curve is complete")]
    CurveComplete,
    #[msg("Bonding curve is not complete")]
    CurveNotComplete,
    #[msg("Token already graduated")]
    AlreadyGraduated,
    #[msg("Insufficient curve reserves")]
    InsufficientReserves,
    #[msg("Slippage tolerance exceeded")]
    SlippageExceeded,
    #[msg("Quote deadline exceeded")]
    DeadlineExceeded,
    #[msg("Invalid fee configuration")]
    InvalidFee,
    #[msg("Invalid parameters")]
    InvalidParams,
    #[msg("Invalid token metadata")]
    InvalidMetadata,
    #[msg("Fee recipient does not match config")]
    InvalidFeeRecipient,
    #[msg("Arithmetic overflow")]
    Overflow,
    #[msg("Curve account would become insolvent")]
    InsolventCurve,
    #[msg("Withdrawal exceeds treasury balance above rent")]
    InsufficientTreasury,
    #[msg("Invalid AMM pool account")]
    InvalidPool,
    #[msg("Config update timelock has not elapsed")]
    TimelockNotElapsed,
    #[msg("No config update is queued")]
    NoPendingConfigUpdate,
    #[msg("A config update is already queued; cancel it first")]
    ConfigUpdatePending,
    #[msg("Queued config update expired; cancel and re-queue")]
    ConfigUpdateExpired,
    #[msg("Launch fee exceeds the hard cap")]
    LaunchFeeAboveCap,
    #[msg("Invalid Pyth price account (address, owner, layout or feed)")]
    PriceFeedInvalid,
    #[msg("Pyth price update is not fully verified")]
    PriceNotFullyVerified,
    #[msg("Pyth price is stale")]
    PriceStale,
    #[msg("Pyth price is not positive")]
    PriceNonPositive,
    #[msg("Pyth price confidence interval too wide")]
    PriceConfidenceTooWide,
    #[msg("Builder account is not the build-time builder wallet")]
    InvalidBuilder,
    #[msg("Builder wallet would stay below rent exemption; fund it once")]
    BuilderNotRentExempt,
    // ── DEEP V1 fee splitter (appended; never renumber) ──
    #[msg("Invalid splitter parameters")]
    InvalidSplitterParams,
    #[msg("A splitter update is already queued; cancel it first")]
    SplitterUpdatePending,
    #[msg("No splitter update is queued")]
    NoPendingSplitterUpdate,
    #[msg("New fee-vault revenue is below the minimum distribute amount")]
    BelowMinDistribute,
    #[msg("Destination accounts do not match the splitter config")]
    InvalidDestination,
    #[msg("A removed destination still has owed lamports; distribute first")]
    DestinationHasOwed,
    #[msg("Fee vault or its WSOL account does not match this build")]
    InvalidFeeVault,
    #[msg("WSOL leaves the fee vault only through distribute")]
    InvalidVaultToken,
    // ── DEEP V1 Phase 2: reward model on the curve (appended; never renumber) ──
    #[msg("Reward model must be 0 (Standard), 1 (Creator) or 2 (Holder)")]
    InvalidRewardModel,
    #[msg(
        "Holder vault would stay below rent exemption; init its distributor or wait for more fees"
    )]
    HolderVaultBelowRent,
    // ── DEEP V1, sixth round: the creator's reward rate (appended; never renumber) ──
    #[msg("Reward rate must be 0 for Standard and 1 to 500 bps for Creator and Holder")]
    InvalidRewardRate,
    #[msg("Reward rate is above the current maximum for new launches")]
    RewardRateAboveMax,
    // ── Security review before mainnet (appended; never renumber) ──
    #[msg("Launch fee in lamports is above the creator's limit (max_launch_fee_lamports)")]
    LaunchFeeAboveMax,
    #[msg("Parameters under which a completed curve could not graduate (no SOL or tokens left for the pool)")]
    GraduationImpossible,
}

impl From<pyth::PriceError> for DeepError {
    fn from(e: pyth::PriceError) -> Self {
        use pyth::PriceError::*;
        match e {
            Malformed | WrongFeed | Unsupported => DeepError::PriceFeedInvalid,
            NotFullyVerified => DeepError::PriceNotFullyVerified,
            Stale => DeepError::PriceStale,
            NonPositive => DeepError::PriceNonPositive,
            ConfidenceTooWide => DeepError::PriceConfidenceTooWide,
        }
    }
}

impl From<MathError> for DeepError {
    fn from(e: MathError) -> Self {
        match e {
            MathError::ZeroAmount => DeepError::ZeroAmount,
            MathError::CurveComplete => DeepError::CurveComplete,
            MathError::InsufficientReserves => DeepError::InsufficientReserves,
            MathError::SlippageExceeded => DeepError::SlippageExceeded,
            MathError::InvalidFee => DeepError::InvalidFee,
            MathError::InvalidParams => DeepError::InvalidParams,
            MathError::Overflow => DeepError::Overflow,
        }
    }
}

#[cfg(test)]
mod layout_tests {
    use super::*;

    #[test]
    fn v3_sizes_match_init_space() {
        assert_eq!(8 + Config::INIT_SPACE, CONFIG_V3_SIZE);
        assert_eq!(8 + PendingConfig::INIT_SPACE, PENDING_CONFIG_V3_SIZE);
        assert_eq!(8 + BondingCurve::INIT_SPACE, BONDING_CURVE_V3_SIZE);
        assert_eq!(CONFIG_V3_SIZE, CONFIG_V2_SIZE + 6);
        assert_eq!(PENDING_CONFIG_V3_SIZE, PENDING_CONFIG_V2_SIZE + 6);
        assert_eq!(BONDING_CURVE_V3_SIZE, BONDING_CURVE_V2_SIZE + 2 + 1 + 8);
        assert_eq!(
            ConfigParams::INIT_SPACE,
            layout::PARAMS_SELL_PROTOCOL_FEE_BPS + 6
        );
    }

    /// The offsets the migrations patch are the offsets Borsh writes.
    #[test]
    fn migration_offsets_match_borsh() {
        let k = |n: u8| Pubkey::new_from_array([n; 32]);
        let params = ConfigParams {
            fee_recipient: k(1),
            migration_authority: k(2),
            protocol_fee_bps: 0x1111,
            creator_fee_bps: 0x2222,
            migration_fee_bps: 0x3333,
            initial_virtual_sol: 1,
            initial_virtual_token: 2,
            curve_supply: 3,
            token_total_supply: 4,
            decimals: 6,
            raydium_amm_config: k(3),
            timelock_seconds: 5,
            launch_fee_usd_cents: 0x4444,
            sell_protocol_fee_bps: 0x5555,
            max_reward_bps: 0x6666,
            reserved_bps: 0x7777,
        };
        let mut p = Vec::new();
        params.serialize(&mut p).unwrap();
        assert_eq!(p.len(), ConfigParams::INIT_SPACE);
        let at = |d: &[u8], o: usize| u16::from_le_bytes([d[o], d[o + 1]]);
        assert_eq!(at(&p, layout::PARAMS_PROTOCOL_FEE_BPS), 0x1111);
        assert_eq!(at(&p, layout::PARAMS_SELL_PROTOCOL_FEE_BPS), 0x5555);
        assert_eq!(at(&p, layout::PARAMS_SELL_PROTOCOL_FEE_BPS + 4), 0x7777);

        let mut cfg = Config {
            admin: k(1),
            pending_admin: k(2),
            fee_recipient: k(3),
            migration_authority: k(4),
            protocol_fee_bps: 0,
            creator_fee_bps: 0,
            migration_fee_bps: 0,
            initial_virtual_sol: 0,
            initial_virtual_token: 0,
            curve_supply: 0,
            token_total_supply: 0,
            decimals: 0,
            paused: false,
            bump: 0,
            raydium_amm_config: k(5),
            timelock_seconds: 0,
            launch_fee_usd_cents: 0,
            sell_protocol_fee_bps: 0,
            max_reward_bps: 0,
            reserved_bps: 0,
        };
        cfg.apply(&params);
        let mut d = Vec::new();
        cfg.try_serialize(&mut d).unwrap();
        assert_eq!(d.len(), CONFIG_V3_SIZE);
        assert_eq!(at(&d, layout::CONFIG_PROTOCOL_FEE_BPS), 0x1111);
        assert_eq!(at(&d, layout::CONFIG_SELL_PROTOCOL_FEE_BPS), 0x5555);
        assert_eq!(at(&d, CONFIG_V3_SIZE - 2), 0x7777);

        let curve = BondingCurve {
            mint: k(1),
            creator: k(2),
            virtual_sol_reserves: 0,
            virtual_token_reserves: 0,
            real_sol_reserves: 0,
            real_token_reserves: 0,
            curve_supply: 0,
            token_total_supply: 0,
            protocol_fee_bps: 0x1111,
            creator_fee_bps: 0x2222,
            migration_fee_bps: 0,
            creator_fees_unclaimed: 0,
            complete: false,
            graduated: false,
            created_at: 0,
            bump: 0,
            pool: k(3),
            protocol_fees_unclaimed: 0,
            sell_protocol_fee_bps: 0x5555,
            reward_model: math::REWARD_MODEL_HOLDER,
            holder_fees_unclaimed: 0x0807_0605_0403_0201,
        };
        let mut d = Vec::new();
        curve.try_serialize(&mut d).unwrap();
        assert_eq!(d.len(), BONDING_CURVE_V3_SIZE);
        assert_eq!(at(&d, layout::CURVE_PROTOCOL_FEE_BPS), 0x1111);
        assert_eq!(at(&d, layout::CURVE_CREATOR_FEE_BPS), 0x2222);
        assert_eq!(at(&d, layout::CURVE_SELL_PROTOCOL_FEE_BPS), 0x5555);
        assert_eq!(d[layout::CURVE_REWARD_MODEL], math::REWARD_MODEL_HOLDER);
        assert_eq!(d[BONDING_CURVE_V3_SIZE - 8..], [1, 2, 3, 4, 5, 6, 7, 8]);
        assert_eq!(curve.fees(true).protocol_fee_bps, 0x1111);
        assert_eq!(curve.fees(false).protocol_fee_bps, 0x5555);
        assert_eq!(curve.fees(false).creator_fee_bps, 0x2222);
    }
}
