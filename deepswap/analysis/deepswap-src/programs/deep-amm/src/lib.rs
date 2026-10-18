pub mod curve;
pub mod error;
pub mod instructions;
pub mod states;
pub mod utils;
use crate::curve::fees::FEE_RATE_DENOMINATOR_VALUE;
use anchor_lang::prelude::*;
use instructions::*;
pub use states::CreatorFeeOn;

#[cfg(not(feature = "no-entrypoint"))]
solana_security_txt::security_txt! {
    name: "deep-amm",
    project_url: "https://deepliquidity.fun",
    contacts: "email:security@deepliquidity.fun,link:https://github.com/Deep-Liquidity/contracts/security/advisories/new",
    policy: "https://github.com/Deep-Liquidity/contracts/blob/main/SECURITY.md",
    source_code: "https://github.com/Deep-Liquidity/contracts",
    preferred_languages: "en"
}

// DEEP: one program id on every cluster (keypair: target/deploy/deep_amm-keypair.json).
declare_id!("HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP");

/// DEEP: every privileged key is fixed at BUILD time from environment variables, the
/// same mechanism upstream uses for its `localnet` admin (`env!`). Only the constant
/// definitions changed; every upstream access-control check is untouched.
///
/// * `DEEP_AMM_ADMIN`        admin (create/update AmmConfig, pool status, permission
///                             PDAs, creator-fee shares, support-mint, excess lamports)
/// * `DEEP_AMM_FEE_OWNER`    the shared creator-fee owner (upstream `shared_creator_fee_owner`)
/// * `DEEP_FEE_VAULT`        the DEEP fee vault (deep-curve PDA ["fee_vault"]): the ONLY
///                             protocol_owner an AmmConfig can have (DEEP V1, see FEE_VAULT)
/// * `DEEP_AMM_CREATE_POOL_FEE_RECEIVER`  WSOL token account receiving create-pool fees
///                             (DEEP V1: ATA(WSOL, DEEP_FEE_VAULT), so the fee is DEEP revenue
///                             that goes through the deep-curve fee splitter)
///
/// * `DEEP_BUILDER_WALLET`  the DEEP builder wallet: the ONLY fund_owner an AmmConfig can
///                             have, the only signer of `collect_fund_fee` (see BUILDER below)
///
/// Unset → the system program id, which nobody can sign for and which is not a token
/// account: an unconfigured build has NO admin and cannot create pools (fails closed).
pub mod deep_keys {
    use super::Pubkey;
    const UNSET: Pubkey = Pubkey::from_str_const("11111111111111111111111111111111");
    const fn key(v: Option<&'static str>) -> Pubkey {
        match v {
            Some(s) => Pubkey::from_str_const(s),
            None => UNSET,
        }
    }
    pub const ADMIN: Pubkey = key(option_env!("DEEP_AMM_ADMIN"));
    pub const FEE_OWNER: Pubkey = key(option_env!("DEEP_AMM_FEE_OWNER"));
    pub const CREATE_POOL_FEE_RECEIVER: Pubkey = key(option_env!("DEEP_AMM_CREATE_POOL_FEE_RECEIVER"));
    /// The DEEP builder wallet. DEEP V1 (Phase 1): the builder is paid 10% of ALL DEEP revenue
    /// by the deep-curve fee splitter (`distribute`), no longer through the fund fee. It stays
    /// the only possible `fund_owner` and the only signer of `collect_fund_fee`, so fund fees
    /// accrued before V1 (devnet) remain collectable by the builder alone. deep-curve compiles
    /// the same key (`deep_curve::BUILDER_WALLET`).
    pub const BUILDER: Pubkey = key(option_env!("DEEP_BUILDER_WALLET"));
    /// The only fund_fee_rate an AmmConfig can hold: 0. DEEP V1 retired the builder fund fee;
    /// the builder's 10% comes out of everything that reaches the fee vault.
    pub const BUILDER_FUND_FEE_RATE: u64 = 0;
    /// DEEP V1: the DEEP fee vault, deep-curve's system-owned PDA ["fee_vault"]
    /// (8a2XakVBzdMRJ6gMY6u8mvebzJGgbmG6nVBVPB8uwBVZ for deep-curve 7czUR...CDtA, on every
    /// cluster). The ONLY `protocol_owner` an AmmConfig can have, so DEEP's DeepSwap protocol
    /// fees can only be collected into the vault's token accounts
    /// (`collect_protocol_fee_to_vault`, permissionless), where the splitter pays the builder
    /// 10% before anyone else. Unset: the system program id, so no protocol fee can be
    /// collected and no AmmConfig can point anywhere else (fails closed).
    pub const FEE_VAULT: Pubkey = key(option_env!("DEEP_FEE_VAULT"));
    /// THE hard cap (owner decisions 2026-10-06 Q15 and 2026-10-07 eighth round): a trader
    /// never pays more than 10% in fees on one side. Legacy configs: `trade_fee_rate +
    /// creator_fee_rate <= 100_000` (per 1e6). V1 pools: `lp + protocol + reward <= 100_000`,
    /// checked in one place, `curve::v1::total_rate`. Rates are adjustable below it; the cap
    /// itself only changes with a program upgrade.
    pub const MAX_TOTAL_FEE_RATE: u64 = 100_000;
    /// DEEP V1: the hard ceiling of a pool's REWARD rate, the per-side rate chosen by the
    /// token's creator at launch or by the pool's creator: 5% (deep-curve `MAX_REWARD_BPS`,
    /// 500 bps). Only a program upgrade changes it; the admin sets the CURRENT maximum for
    /// new pools at or under it (`AmmConfig::max_reward_rate`). A V1 config's own side
    /// (LP + DEEP) is limited to `MAX_TOTAL_FEE_RATE - MAX_REWARD_RATE`, so no pool, whatever
    /// its reward rate, can ever be pushed above the 10% total by a later rate change.
    pub const MAX_REWARD_RATE: u64 = 50_000;
    /// deep-rewards (Holder Rewards distributor, programs/deep-rewards): the program whose PDA
    /// `["holder_vault", token_mint]` is the only reward recipient of a Holder pool opened with
    /// `initialize_v1`. One fixed id on every cluster; deep-curve compiles in the same one
    /// (`deep_curve::DEEP_REWARDS_PROGRAM_ID`, pinned by its tests).
    pub const DEEP_REWARDS_PROGRAM_ID: Pubkey =
        Pubkey::from_str_const("4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2");
    pub const HOLDER_VAULT_SEED: &[u8] = b"holder_vault";
    /// deep-rewards `Distributor` seed: `["distributor", token_mint, reward_mint]`.
    pub const DISTRIBUTOR_SEED: &[u8] = b"distributor";

    /// The deep-rewards distributor of (`token_mint`, `reward_mint`). It exists (owned by
    /// deep-rewards) only once DEEP's admin or root authority ran `init_distributor`, i.e. once
    /// DEEP has opted in to paying that token's holders in that reward asset.
    pub fn distributor_address(token_mint: &Pubkey, reward_mint: &Pubkey) -> Pubkey {
        Pubkey::find_program_address(
            &[DISTRIBUTOR_SEED, token_mint.as_ref(), reward_mint.as_ref()],
            &DEEP_REWARDS_PROGRAM_ID,
        )
        .0
    }

    /// True when `accounts` contains the deep-rewards distributor of (`token_mint`,
    /// `reward_mint`): the account at that PDA, owned by deep-rewards and holding data. Only
    /// deep-rewards can create an account it owns at its own PDA (`init_distributor`).
    pub fn has_distributor(
        accounts: &[anchor_lang::prelude::AccountInfo],
        token_mint: &Pubkey,
        reward_mint: &Pubkey,
    ) -> bool {
        let expected = distributor_address(token_mint, reward_mint);
        accounts.iter().any(|a| {
            *a.key == expected && *a.owner == DEEP_REWARDS_PROGRAM_ID && !a.data_is_empty()
        })
    }

    /// deep-curve's graduation pool payer: its system-owned PDA `["pool_creator"]`
    /// (deep-curve 7czUR...CDtA, the same on every cluster), the `payer` of every
    /// `initialize_with_permission[_v1]` that `graduate` sends. Only deep-curve can sign for
    /// it, and it does so only inside `graduate`. A completed curve's SOL has no other way out
    /// than that pool creation, so for THIS payer the admin's switches do not apply: it needs
    /// no `Permission` account, its `Permission` cannot be closed, and an AmmConfig's
    /// `disable_create_pool` does not stop it. Pinned to deep-curve's derivation by
    /// programs/deep-curve tests and to the SDK by packages/sdk tests.
    pub const GRADUATION_PAYER: Pubkey =
        Pubkey::from_str_const("GwW8P2V5mxfPosGEwtcNuUuzx6FVdzPZrapApn8ufYZF");

    /// Hard cap of `AmmConfig::create_pool_fee`, in lamports: 0.15 SOL, the fee DeepSwap
    /// launches with. The admin can lower the fee, never raise it above this, so a pool
    /// creator is never charged more than the published 0.15 SOL (no `max_create_pool_fee`
    /// argument is needed) and a graduation's create-pool cost is bounded: the 1% migration
    /// fee of a default curve always covers it. Enforced when a config is created or updated
    /// AND when the fee is charged (`create_pool_fee_to_charge`), so a config written before
    /// the cap existed cannot charge more either. Only a program upgrade changes it.
    pub const MAX_CREATE_POOL_FEE: u64 = 150_000_000;

    /// What a pool creation is charged: the config's fee, never more than the cap.
    pub const fn create_pool_fee_to_charge(configured: u64) -> u64 {
        if configured > MAX_CREATE_POOL_FEE {
            MAX_CREATE_POOL_FEE
        } else {
            configured
        }
    }

    /// The holder vault of `token_mint` (system-owned, data-less; only deep-rewards signs).
    pub fn holder_vault_address(token_mint: &Pubkey) -> Pubkey {
        Pubkey::find_program_address(
            &[HOLDER_VAULT_SEED, token_mint.as_ref()],
            &DEEP_REWARDS_PROGRAM_ID,
        )
        .0
    }
}

pub mod admin {
    use super::Pubkey;
    pub const ID: Pubkey = crate::deep_keys::ADMIN;
}

pub mod create_pool_fee_reveiver {
    use super::Pubkey;
    pub const ID: Pubkey = crate::deep_keys::CREATE_POOL_FEE_RECEIVER;
}

pub mod collect_lamports {
    use super::Pubkey;
    pub const ID: Pubkey = crate::deep_keys::ADMIN;
}

pub mod fund_fee_owner {
    use super::Pubkey;
    pub const ID: Pubkey = crate::deep_keys::BUILDER;
}

pub mod protocol_fee_owner {
    use super::Pubkey;
    /// DEEP V1: the fee vault (was the fee owner).
    pub const ID: Pubkey = crate::deep_keys::FEE_VAULT;
}

pub mod shared_creator_fee_owner {
    use super::Pubkey;
    pub const ID: Pubkey = crate::deep_keys::FEE_OWNER;
}

pub const AUTH_SEED: &str = "vault_and_lp_mint_auth_seed";

#[program]
pub mod deep_amm {
    use super::*;

    // The configuration of AMM protocol, include trade fee and protocol fee
    /// # Arguments
    ///
    /// * `ctx`- The accounts needed by instruction.
    /// * `index` - The index of amm config, there may be multiple config.
    /// * `trade_fee_rate` - Trade fee rate, can be changed.
    /// * `protocol_fee_rate` - The rate of protocol fee within trade fee.
    /// * `fund_fee_rate` - The rate of fund fee within trade fee.
    ///
    pub fn create_amm_config(
        ctx: Context<CreateAmmConfig>,
        index: u16,
        trade_fee_rate: u64,
        protocol_fee_rate: u64,
        fund_fee_rate: u64,
        create_pool_fee: u64,
        creator_fee_rate: u64,
    ) -> Result<()> {
        assert!(trade_fee_rate + creator_fee_rate < FEE_RATE_DENOMINATOR_VALUE);
        assert!(protocol_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
        assert!(fund_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
        assert!(fund_fee_rate + protocol_fee_rate <= FEE_RATE_DENOMINATOR_VALUE);
        instructions::create_amm_config(
            ctx,
            index,
            trade_fee_rate,
            protocol_fee_rate,
            fund_fee_rate,
            create_pool_fee,
            creator_fee_rate,
        )
    }

    /// DEEP V1: creates a V1 AmmConfig (`fee_model = 1`): side-dependent absolute rates, all
    /// per 1e6. A config's fee model is fixed here and never changes. Each side's
    /// `lp + protocol` is capped at 5% (`MAX_TOTAL_FEE_RATE - MAX_REWARD_RATE`), which keeps
    /// every pool's total at or under 10% whatever its reward rate. A pool's reward rate is
    /// not a config value: it is fixed when the pool is created. The config's
    /// `max_reward_rate`, the current maximum for pools anyone opens, starts at the ceiling
    /// (`MAX_REWARD_RATE`). The protocol owner is the DEEP fee vault and there is no fund
    /// fee, as for every config.
    ///
    /// # Arguments
    ///
    /// * `ctx`- The accounts needed by instruction (the same as `create_amm_config`).
    /// * `index` - The index of amm config.
    /// * `create_pool_fee` - Lamports charged for creating a pool.
    /// * `buy_lp_fee_rate`, `buy_protocol_fee_rate` - LP and DEEP rates when the quote token is the input.
    /// * `sell_lp_fee_rate`, `sell_protocol_fee_rate` - LP and DEEP rates when the quote token is the output.
    ///
    pub fn create_amm_config_v1(
        ctx: Context<CreateAmmConfig>,
        index: u16,
        create_pool_fee: u64,
        buy_lp_fee_rate: u64,
        buy_protocol_fee_rate: u64,
        sell_lp_fee_rate: u64,
        sell_protocol_fee_rate: u64,
    ) -> Result<()> {
        instructions::create_amm_config_v1(
            ctx,
            index,
            create_pool_fee,
            buy_lp_fee_rate,
            buy_protocol_fee_rate,
            sell_lp_fee_rate,
            sell_protocol_fee_rate,
        )
    }

    /// Updates the owner of the amm config
    /// Must be called by the current owner or admin
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `trade_fee_rate`- The new trade fee rate of amm config, be set when `param` is 0
    /// * `protocol_fee_rate`- The new protocol fee rate of amm config, be set when `param` is 1
    /// * `fund_fee_rate`- The new fund fee rate of amm config, be set when `param` is 2
    /// * `new_owner`- The config's new owner, be set when `param` is 3
    /// * `new_fund_owner`- The config's new fund owner, be set when `param` is 4
    /// * `creator_fee_rate`- The new creator fee rate of amm config, be set when `param` is 7
    /// * `creator_fee_share_rate`- The new share of the creator fee retained by the
    ///   protocol, be set when `param` is 8
    /// * DEEP V1 configs only (`fee_model == 1`): `buy_lp_fee_rate` when `param` is 10,
    ///   `buy_protocol_fee_rate` 11, `sell_lp_fee_rate` 12, `sell_protocol_fee_rate` 13,
    ///   `max_reward_rate` 14 (the current maximum reward rate for NEW pools opened with
    ///   `initialize_v1`, at most `deep_keys::MAX_REWARD_RATE`; existing pools are not
    ///   affected). On a V1 config the legacy rate params 0, 1, 7 and 8 are rejected; on a
    ///   legacy config 10..=14 are. There is no param 9: a config's fee model cannot be changed.
    /// * `param`- The value can be 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 10..=14, otherwise will report a error
    ///
    pub fn update_amm_config(ctx: Context<UpdateAmmConfig>, param: u8, value: u64) -> Result<()> {
        instructions::update_amm_config(ctx, param, value)
    }

    /// Update pool status for given value
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `status` - The value of status
    ///
    pub fn update_pool_status(ctx: Context<UpdatePoolStatus>, status: u8) -> Result<()> {
        instructions::update_pool_status(ctx, status)
    }

    /// Collect the protocol fee accrued to the pool
    ///
    /// # Arguments
    ///
    /// * `ctx` - The context of accounts
    /// * `amount_0_requested` - The maximum amount of token_0 to send, can be 0 to collect fees in only token_1
    /// * `amount_1_requested` - The maximum amount of token_1 to send, can be 0 to collect fees in only token_0
    ///
    pub fn collect_protocol_fee(
        ctx: Context<CollectProtocolFee>,
        amount_0_requested: u64,
        amount_1_requested: u64,
    ) -> Result<()> {
        instructions::collect_protocol_fee(ctx, amount_0_requested, amount_1_requested)
    }

    /// DEEP V1: PERMISSIONLESS. Moves all of the pool's accrued protocol fees (both sides) to
    /// the associated token accounts of `amm_config.protocol_owner`, which deep-amm locks to
    /// the DEEP fee vault (`deep_keys::FEE_VAULT`). The destination is fixed by the config, so
    /// anyone (the fee keeper) may trigger it; no owner signature is needed.
    ///
    /// # Arguments
    ///
    /// * `ctx` - The context of accounts
    ///
    pub fn collect_protocol_fee_to_vault(ctx: Context<CollectProtocolFeeToVault>) -> Result<()> {
        instructions::collect_protocol_fee_to_vault(ctx)
    }

    /// Collect the fund fee accrued to the pool
    ///
    /// # Arguments
    ///
    /// * `ctx` - The context of accounts
    /// * `amount_0_requested` - The maximum amount of token_0 to send, can be 0 to collect fees in only token_1
    /// * `amount_1_requested` - The maximum amount of token_1 to send, can be 0 to collect fees in only token_0
    ///
    pub fn collect_fund_fee(
        ctx: Context<CollectFundFee>,
        amount_0_requested: u64,
        amount_1_requested: u64,
    ) -> Result<()> {
        instructions::collect_fund_fee(ctx, amount_0_requested, amount_1_requested)
    }

    /// Collect the creator fee
    ///
    /// # Arguments
    ///
    /// * `ctx` - The context of accounts
    ///
    pub fn collect_creator_fee(ctx: Context<CollectCreatorFee>) -> Result<()> {
        instructions::collect_creator_fee(ctx)
    }

    /// Collect the creator fee, anyone can call it since the fee is always sent to the
    /// pool creator, the payer only funds the creation of the creator's token accounts.
    ///
    /// # Arguments
    ///
    /// * `ctx` - The context of accounts
    ///
    pub fn collect_creator_fee_permissionless(
        ctx: Context<CollectCreatorFeePermissionless>,
    ) -> Result<()> {
        instructions::collect_creator_fee_permissionless(ctx)
    }

    /// Create a permission account
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    ///
    pub fn create_permission_pda(ctx: Context<CreatePermissionPda>) -> Result<()> {
        instructions::create_permission_pda(ctx)
    }

    /// Close a permission account
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    ///
    pub fn close_permission_pda(ctx: Context<ClosePermissionPda>) -> Result<()> {
        instructions::close_permission_pda(ctx)
    }

    /// Create a custom creator fee share account for a (creator, amm_config) pair.
    /// While it exists it overrides `AmmConfig::creator_fee_share_rate` when the
    /// creator fee of a pool created by `creator` on `amm_config` is collected.
    /// Must be called by the admin or the creator fee share owner.
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `share_rate` - The share of the creator fee retained by the protocol,
    ///   denominated in hundredths of a bip (10^-6)
    ///
    pub fn create_creator_fee_share(
        ctx: Context<CreateCreatorFeeShare>,
        share_rate: u64,
    ) -> Result<()> {
        instructions::create_creator_fee_share(ctx, share_rate)
    }

    /// Close a custom creator fee share account, the creator fee split falls back to the
    /// rate configured on the amm config afterwards.
    /// Must be called by the admin or the creator fee share owner.
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    ///
    pub fn close_creator_fee_share(ctx: Context<CloseCreatorFeeShare>) -> Result<()> {
        instructions::close_creator_fee_share(ctx)
    }

    /// Creates a pool for the given token pair and the initial price
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `init_amount_0` - the initial amount_0 to deposit
    /// * `init_amount_1` - the initial amount_1 to deposit
    /// * `open_time` - the timestamp allowed for swap
    ///
    pub fn initialize(
        ctx: Context<Initialize>,
        init_amount_0: u64,
        init_amount_1: u64,
        open_time: u64,
    ) -> Result<()> {
        instructions::initialize(ctx, init_amount_0, init_amount_1, open_time)
    }

    /// DEEP V1 (owner decision 2026-10-07, seventh round): creates a pool under a V1 AmmConfig
    /// whose creator chooses its reward terms, immutable afterwards. Permissionless, same
    /// accounts as `initialize`. (`initialize` itself, under a V1 config, opens a Standard
    /// pool with the default quote side.)
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `init_amount_0` - the initial amount_0 to deposit
    /// * `init_amount_1` - the initial amount_1 to deposit
    /// * `open_time` - the timestamp allowed for swap
    /// * `creator_fee_on` - the QUOTE side, the token every fee is taken in: 1: token0, 2: token1 (0 is rejected). WSOL when the pair has it
    /// * `reward_model` - 0: Standard, 1: Creator (the reward goes to `creator`, the account creating the pool), 2: Holder (to the deep-rewards holder vault of the non-quote token; WSOL-quoted pairs only)
    /// * `reward_rate` - per 1e6, on both sides on top of the config's rates; 0 for Standard, otherwise 1..=the config's `max_reward_rate` (at most `deep_keys::MAX_REWARD_RATE`)
    ///
    pub fn initialize_v1(
        ctx: Context<Initialize>,
        init_amount_0: u64,
        init_amount_1: u64,
        open_time: u64,
        creator_fee_on: CreatorFeeOn,
        reward_model: u8,
        reward_rate: u64,
    ) -> Result<()> {
        instructions::initialize_v1(
            ctx,
            init_amount_0,
            init_amount_1,
            open_time,
            creator_fee_on,
            reward_model,
            reward_rate,
        )
    }

    /// Create a pool with permission
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `init_amount_0` - the initial amount_0 to deposit
    /// * `init_amount_1` - the initial amount_1 to deposit
    /// * `open_time` - the timestamp allowed for swap
    /// * `creator_fee_on` - creator fee model, 0：both token0 and token1 (depends on the input), 1: only token0, 2: only token1
    ///
    pub fn initialize_with_permission(
        ctx: Context<InitializeWithPermission>,
        init_amount_0: u64,
        init_amount_1: u64,
        open_time: u64,
        creator_fee_on: CreatorFeeOn,
    ) -> Result<()> {
        instructions::initialize_with_permission(
            ctx,
            init_amount_0,
            init_amount_1,
            open_time,
            creator_fee_on,
        )
    }

    /// DEEP V1: create a V1 pool with permission (deep-curve `graduate` is the caller for
    /// every launched token). Same accounts as `initialize_with_permission`.
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `init_amount_0` - the initial amount_0 to deposit
    /// * `init_amount_1` - the initial amount_1 to deposit
    /// * `open_time` - the timestamp allowed for swap
    /// * `creator_fee_on` - the QUOTE side, the token every fee is taken in: 1: token0, 2: token1 (0 is rejected). WSOL when the pair has it
    /// * `reward_model` - 0: Standard, 1: Creator (reward to `creator`), 2: Holder (reward to `creator`, the token's holder vault)
    /// * `reward_rate` - the token's reward rate per 1e6, charged on both sides on top of the config's rates; 0 for Standard, at most `deep_keys::MAX_REWARD_RATE`. Immutable
    ///
    pub fn initialize_with_permission_v1(
        ctx: Context<InitializeWithPermission>,
        init_amount_0: u64,
        init_amount_1: u64,
        open_time: u64,
        creator_fee_on: CreatorFeeOn,
        reward_model: u8,
        reward_rate: u64,
    ) -> Result<()> {
        instructions::initialize_with_permission_v1(
            ctx,
            init_amount_0,
            init_amount_1,
            open_time,
            creator_fee_on,
            reward_model,
            reward_rate,
        )
    }

    /// Deposit lp token to the pool
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `lp_token_amount` - Increased number of LPs
    /// * `maximum_token_0_amount` -  Maximum token 0 amount to deposit, prevents excessive slippage
    /// * `maximum_token_1_amount` - Maximum token 1 amount to deposit, prevents excessive slippage
    ///
    pub fn deposit(
        ctx: Context<Deposit>,
        lp_token_amount: u64,
        maximum_token_0_amount: u64,
        maximum_token_1_amount: u64,
    ) -> Result<()> {
        instructions::deposit(
            ctx,
            lp_token_amount,
            maximum_token_0_amount,
            maximum_token_1_amount,
        )
    }

    /// Withdraw lp for token0 and token1
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `lp_token_amount` - Amount of pool tokens to burn. User receives an output of token a and b based on the percentage of the pool tokens that are returned.
    /// * `minimum_token_0_amount` -  Minimum amount of token 0 to receive, prevents excessive slippage
    /// * `minimum_token_1_amount` -  Minimum amount of token 1 to receive, prevents excessive slippage
    ///
    pub fn withdraw(
        ctx: Context<Withdraw>,
        lp_token_amount: u64,
        minimum_token_0_amount: u64,
        minimum_token_1_amount: u64,
    ) -> Result<()> {
        instructions::withdraw(
            ctx,
            lp_token_amount,
            minimum_token_0_amount,
            minimum_token_1_amount,
        )
    }

    /// Swap the tokens in the pool base input amount
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `amount_in` -  input amount to transfer, output to DESTINATION is based on the exchange rate
    /// * `minimum_amount_out` -  Minimum amount of output token, prevents excessive slippage
    ///
    pub fn swap_base_input(
        ctx: Context<Swap>,
        amount_in: u64,
        minimum_amount_out: u64,
    ) -> Result<()> {
        instructions::swap_base_input(ctx, amount_in, minimum_amount_out)
    }

    /// Swap the tokens in the pool base output amount
    ///
    /// # Arguments
    ///
    /// * `ctx`- The context of accounts
    /// * `max_amount_in` -  input amount prevents excessive slippage
    /// * `amount_out` -  amount of output token
    ///
    pub fn swap_base_output(ctx: Context<Swap>, max_amount_in: u64, amount_out: u64) -> Result<()> {
        instructions::swap_base_output(ctx, max_amount_in, amount_out)
    }

    /// Create support token22 mint account which can create pool and send rewards while ignoring unsupported extensions.
    pub fn create_support_mint_associated(ctx: Context<CreateSupportMintAssociated>) -> Result<()> {
        instructions::create_support_mint_associated(ctx)
    }

    /// Close support token22 mint account which can create pool and send rewards while ignoring unsupported extensions.
    pub fn close_support_mint_associated(ctx: Context<CloseSupportMintAssociated>) -> Result<()> {
        instructions::close_support_mint_associated(ctx)
    }

    /// Collect excess lamports, including accounts for SPL tokens owned by authority and Program PDA accounts.
    pub fn collect_excess_lamports<'info>(
        ctx: Context<'info, CollectExcessLamports<'info>>,
    ) -> Result<()> {
        instructions::collect_excess_lamports(ctx)
    }
}
