//! deep-rewards — DEEP Holder Rewards distributor (docs/V1_FEES.md section 4, PROGRAMS.md).
//!
//! The same source runs on devnet and is the mainnet release candidate (no build-time keys, no
//! cluster feature). See docs/PROGRAMS.md, docs/SECURITY.md and docs/KNOWN_ISSUES.md.
//!
//! One `Distributor` per (token mint, reward asset). The reward asset is the pool's paired
//! asset: native SOL (reward mint = the WSOL mint; WSOL deposits are unwrapped by
//! `unwrap_wsol`) or an SPL Token / Token-2022 quote mint (e.g. USDC for stock pairs).
//!
//! Funds live under ONE system-owned, data-less PDA per token mint, the holder vault
//! `["holder_vault", mint]`: its lamports are the SOL rewards, and its associated token
//! accounts hold token rewards. Only this program can sign for it, and the only instructions
//! that move funds out are `claim_*` / `push_*` (to the leaf's claimant) and `unwrap_wsol`
//! (WSOL → lamports of the same vault). There is no admin withdrawal.
//!
//! An off-chain job (apps/api/src/indexer/holder-rewards.ts) snapshots holders and publishes a
//! Merkle root of CUMULATIVE amounts per wallet (`propose_root`, root authority). A claimant
//! receives `cumulative − already claimed`, so missed rounds roll forward and nothing expires.
//! A root can never promise more than the vault holds:
//! `max_total_claim ≤ total_claimed + available`.
//!
//! What the program cannot check is WHO a root pays: only the root's hash is on chain, so a new
//! root may move not-yet-claimed amounts between wallets and the program has nothing to compare
//! it with. The control is time and a second key (security review F1): every root waits
//! `root_delay_seconds` (at least `MIN_ROOT_DELAY_SECONDS`, 12 h) as pending, in public, and
//! during that time the admin OR the guardian can discard it (`veto_root`) and pause
//! publication (`set_paused`). The guardian is a veto-only key: it cannot propose, activate,
//! change a setting or move funds.

use anchor_lang::prelude::*;
use anchor_lang::system_program;
use anchor_spl::associated_token::{
    self, get_associated_token_address_with_program_id, AssociatedToken,
};
use anchor_spl::token::{self, Token};
use anchor_spl::token_2022::spl_token_2022::{
    self,
    extension::{
        non_transferable::NonTransferable, transfer_fee::TransferFeeAmount,
        transfer_hook::TransferHook, BaseStateWithExtensions, StateWithExtensions,
    },
};
use anchor_spl::token_interface::{self, Mint, TokenAccount, TokenInterface};

pub mod merkle;
pub mod pyth;

#[cfg(not(feature = "no-entrypoint"))]
solana_security_txt::security_txt! {
    name: "deep-rewards",
    project_url: "https://deepliquidity.fun",
    contacts: "email:security@deepliquidity.fun,link:https://github.com/Deep-Liquidity/contracts/security/advisories/new",
    policy: "https://github.com/Deep-Liquidity/contracts/blob/main/SECURITY.md",
    source_code: "https://github.com/Deep-Liquidity/contracts",
    preferred_languages: "en"
}

declare_id!("4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2");

pub const REWARDS_CONFIG_SEED: &[u8] = b"rewards_config";
pub const HOLDER_VAULT_SEED: &[u8] = b"holder_vault";
pub const DISTRIBUTOR_SEED: &[u8] = b"distributor";
pub const CLAIM_SEED: &[u8] = b"claim";
pub const WSOL_UNWRAP_SEED: &[u8] = b"wsol_unwrap";
pub const PENDING_CONFIG_SEED: &[u8] = b"pending_rewards_config";

/// The reward mint that means "native SOL" (WSOL deposits are unwrapped into lamports).
pub const NATIVE_MINT: Pubkey = anchor_spl::token::spl_token::native_mint::ID;

pub const PAYOUT_MODE_CLAIM: u8 = 0;
pub const PAYOUT_MODE_AUTO_SEND: u8 = 1;
/// Upper bound for `root_delay_seconds` (7 days).
pub const MAX_ROOT_DELAY_SECONDS: u32 = 7 * 24 * 3600;
/// Lower bound for `root_delay_seconds` on EVERY cluster (12 h; was 1 h): a new root, and every
/// settings change, is public for at least this long before it takes effect, so the published
/// tree file can be verified (packages/sdk/scripts/verify-rewards-root.ts) and a person can
/// veto it. 12 h is longer than a night: whenever a bad root is published, the people who hold
/// the guardian key get working hours inside the window to see the alert, check the tree and
/// sign the veto. Mainnet starts at 24 h; this floor is how far the delay can ever be lowered.
pub const MIN_ROOT_DELAY_SECONDS: u32 = 12 * 3600;
/// A queued settings change must be applied within this window after its eta, or it goes stale
/// and has to be cancelled and re-queued.
pub const CONFIG_UPDATE_GRACE_SECONDS: i64 = 14 * 24 * 3600;
pub const MAX_STABLE_MINTS: usize = 4;
/// Default AUTO-SEND threshold: $20 (owner decision 2026-10-06).
pub const DEFAULT_PUSH_MIN_USD_MICROS: u64 = 20_000_000;
/// Default minimum holding to qualify at a snapshot: about $10 (owner decision 2026-10-06).
/// Enforced off-chain by the snapshot job; stored here so it is public and admin-governed.
pub const DEFAULT_MIN_HOLDING_USD_MICROS: u64 = 10_000_000;
pub const MIN_PUSH_MIN_USD_MICROS: u64 = 1_000_000;
pub const MAX_USD_MICROS: u64 = 1_000_000_000_000;
const SPL_TOKEN_ACCOUNT_LEN: u64 = 165;
/// `PendingRewardsConfig` size before the guardian was added to its params (devnet).
pub const PENDING_CONFIG_V1_SIZE: usize = 280;
/// `PendingRewardsConfig` size now (`8 + INIT_SPACE`, unit-tested).
pub const PENDING_CONFIG_V2_SIZE: usize = PENDING_CONFIG_V1_SIZE + 32;

#[program]
pub mod deep_rewards {
    use super::*;

    /// Creates the RewardsConfig. Only the program's upgrade authority may call it (blocks
    /// deploy-time front-running); the signer becomes `admin`.
    pub fn initialize(ctx: Context<Initialize>, params: RewardsConfigParams) -> Result<()> {
        let admin = ctx.accounts.admin.key();
        params.validate(&admin)?;
        let cfg = &mut ctx.accounts.config;
        cfg.version = 1;
        cfg.bump = ctx.bumps.config;
        cfg.admin = admin;
        cfg.pending_admin = Pubkey::default();
        cfg.paused = false;
        cfg.apply(&params);
        let pending = &mut ctx.accounts.pending_config;
        pending.bump = ctx.bumps.pending_config;
        pending.active = false;
        pending.params = params.clone();
        emit!(RewardsConfigUpdated {
            admin,
            root_authority: cfg.root_authority,
            payout_mode: cfg.payout_mode,
            root_delay_seconds: cfg.root_delay_seconds,
            push_min_usd_micros: cfg.push_min_usd_micros,
            min_holding_usd_micros: cfg.min_holding_usd_micros,
        });
        emit!(GuardianSet {
            guardian: cfg.guardian
        });
        Ok(())
    }

    /// PERMISSIONLESS, idempotent: brings a RewardsConfig and PendingRewardsConfig written
    /// before the guardian existed (devnet) to the current rules. Moves no funds.
    ///
    /// * `PendingRewardsConfig` grows from 280 to 312 bytes (the payer funds the rent
    ///   difference). Its params are re-written in the new layout with NO guardian (the zero
    ///   key), so a change that was queued before the upgrade can no longer be applied: the
    ///   admin cancels it and queues it again with a guardian. Until this instruction has
    ///   run, `queue_config_update`, `apply_config_update` and `cancel_config_update` fail
    ///   with `ConfigNotMigrated`.
    /// * `RewardsConfig` keeps its size (the guardian takes 32 of its reserved bytes, so it
    ///   reads as "no guardian" until the admin's next settings change sets one), and its
    ///   `root_delay_seconds` is raised to the new minimum if it is below it. Nothing is ever
    ///   lowered.
    ///
    /// A second call changes nothing.
    pub fn migrate_config(ctx: Context<MigrateConfig>) -> Result<()> {
        let pc = ctx.accounts.pending_config.to_account_info();
        require_keys_eq!(*pc.owner, crate::ID, RewardsError::InvalidParams);
        require!(
            pc.try_borrow_data()?
                .get(..8)
                .is_some_and(|d| d == PendingRewardsConfig::DISCRIMINATOR),
            RewardsError::InvalidParams
        );
        match pc.data_len() {
            PENDING_CONFIG_V2_SIZE => {}
            PENDING_CONFIG_V1_SIZE => {
                let old = {
                    let data = pc.try_borrow_data()?;
                    PendingRewardsConfigV1::deserialize(&mut &data[8..])
                        .map_err(|_| RewardsError::InvalidParams)?
                };
                let rent = Rent::get()?;
                let top_up = rent
                    .minimum_balance(PENDING_CONFIG_V2_SIZE)
                    .saturating_sub(pc.lamports());
                if top_up > 0 {
                    system_program::transfer(
                        CpiContext::new(
                            ctx.accounts.system_program.key(),
                            system_program::Transfer {
                                from: ctx.accounts.payer.to_account_info(),
                                to: pc.clone(),
                            },
                        ),
                        top_up,
                    )?;
                }
                pc.resize(PENDING_CONFIG_V2_SIZE)?;
                let new = PendingRewardsConfig {
                    bump: old.bump,
                    active: old.active,
                    eta: old.eta,
                    queued_at: old.queued_at,
                    params: old.params.with_guardian(Pubkey::default()),
                };
                let mut data = pc.try_borrow_mut_data()?;
                // stale bytes of an older, longer params value must not survive
                data[8..].fill(0);
                new.serialize(&mut &mut data[8..])
                    .map_err(|_| RewardsError::InvalidParams)?;
            }
            _ => return err!(RewardsError::InvalidParams),
        }
        let cfg = &mut ctx.accounts.config;
        if cfg.root_delay_seconds < MIN_ROOT_DELAY_SECONDS {
            cfg.root_delay_seconds = MIN_ROOT_DELAY_SECONDS;
            emit!(RewardsConfigUpdated {
                admin: cfg.admin,
                root_authority: cfg.root_authority,
                payout_mode: cfg.payout_mode,
                root_delay_seconds: cfg.root_delay_seconds,
                push_min_usd_micros: cfg.push_min_usd_micros,
                min_holding_usd_micros: cfg.min_holding_usd_micros,
            });
        }
        Ok(())
    }

    /// Admin, step 1 of EVERY settings change (root authority, guardian, payout mode, root
    /// delay, thresholds, caps, price account, stablecoins, stray recipient). Validates now and
    /// waits `config.root_delay_seconds` (the delay in force at queue time, at least 12 h) before
    /// anyone can apply it, so a key rotation or a payout change is public before it bites.
    /// One change at a time; cancel to replace it. Never touches funds.
    pub fn queue_config_update(
        ctx: Context<QueueConfigUpdate>,
        params: RewardsConfigParams,
    ) -> Result<()> {
        let cfg = &ctx.accounts.config;
        params.validate(&cfg.admin)?;
        let p = &mut ctx.accounts.pending_config;
        require!(!p.active, RewardsError::ConfigUpdatePending);
        let now = Clock::get()?.unix_timestamp;
        let eta = now
            .checked_add(cfg.root_delay_seconds as i64)
            .ok_or(RewardsError::Overflow)?;
        p.active = true;
        p.eta = eta;
        p.queued_at = now;
        p.params = params.clone();
        emit!(ConfigUpdateQueued {
            eta,
            root_authority: params.root_authority,
            payout_mode: params.payout_mode,
            root_delay_seconds: params.root_delay_seconds,
            stray_recipient: params.stray_recipient,
        });
        emit!(GuardianChangeQueued {
            eta,
            guardian: params.guardian,
        });
        Ok(())
    }

    /// PERMISSIONLESS once the queued change's eta has passed (and within the 14-day grace).
    pub fn apply_config_update(ctx: Context<ApplyConfigUpdate>) -> Result<()> {
        let now = Clock::get()?.unix_timestamp;
        let p = &mut ctx.accounts.pending_config;
        require!(p.active, RewardsError::NoPendingConfigUpdate);
        require!(now >= p.eta, RewardsError::ConfigUpdateNotReady);
        require!(
            now <= p.eta.saturating_add(CONFIG_UPDATE_GRACE_SECONDS),
            RewardsError::ConfigUpdateExpired
        );
        let params = p.params.clone();
        p.active = false;
        let cfg = &mut ctx.accounts.config;
        // re-checked against the CURRENT admin (an admin transfer may have happened)
        params.validate(&cfg.admin)?;
        cfg.apply(&params);
        emit!(RewardsConfigUpdated {
            admin: cfg.admin,
            root_authority: cfg.root_authority,
            payout_mode: cfg.payout_mode,
            root_delay_seconds: cfg.root_delay_seconds,
            push_min_usd_micros: cfg.push_min_usd_micros,
            min_holding_usd_micros: cfg.min_holding_usd_micros,
        });
        emit!(GuardianSet {
            guardian: cfg.guardian
        });
        Ok(())
    }

    /// Admin: drops the queued settings change.
    pub fn cancel_config_update(ctx: Context<CancelConfigUpdate>) -> Result<()> {
        let p = &mut ctx.accounts.pending_config;
        require!(p.active, RewardsError::NoPendingConfigUpdate);
        p.active = false;
        emit!(ConfigUpdateCancelled { eta: p.eta });
        Ok(())
    }

    /// Admin or guardian: pauses (or resumes) root publication and pushes. Claims are NEVER
    /// paused. Moves no funds.
    pub fn set_paused(ctx: Context<AdminOrGuardian>, paused: bool) -> Result<()> {
        ctx.accounts.config.paused = paused;
        emit!(PausedSet { paused });
        Ok(())
    }

    /// Admin transfer, step 1. `Pubkey::default()` cancels.
    pub fn propose_admin(ctx: Context<AdminOnly>, new_admin: Pubkey) -> Result<()> {
        ctx.accounts.config.pending_admin = new_admin;
        emit!(AdminProposed { new_admin });
        Ok(())
    }

    /// Admin transfer, step 2 (signed by the proposed admin).
    pub fn accept_admin(ctx: Context<AcceptAdmin>) -> Result<()> {
        let cfg = &mut ctx.accounts.config;
        let new_admin = ctx.accounts.new_admin.key();
        require_keys_eq!(cfg.pending_admin, new_admin, RewardsError::Unauthorized);
        // The admin must never also be the root authority (separation of duties).
        require_keys_neq!(cfg.root_authority, new_admin, RewardsError::InvalidParams);
        cfg.admin = new_admin;
        cfg.pending_admin = Pubkey::default();
        emit!(AdminAccepted { admin: new_admin });
        Ok(())
    }

    /// Creates the distributor for (`mint`, `reward_mint`). Admin or root authority (the
    /// keeper inits Holder-Rewards tokens). For SOL the payer funds the holder vault's 0-byte
    /// rent minimum (kept as `vault_reserve`, so every lamport already deposited stays
    /// distributable) and the vault's WSOL ATA; for a token it funds the vault's ATA.
    pub fn init_distributor(ctx: Context<InitDistributor>) -> Result<()> {
        let a = &ctx.accounts;
        let cfg = &a.config;
        let signer = a.authority.key();
        require!(
            signer == cfg.admin || signer == cfg.root_authority,
            RewardsError::Unauthorized
        );
        let reward_mint = a.reward_mint.key();
        let is_sol = reward_mint == NATIVE_MINT;
        if is_sol {
            require_keys_eq!(
                a.reward_token_program.key(),
                token::ID,
                RewardsError::UnsupportedRewardMint
            );
        } else {
            check_reward_mint_extensions(&a.reward_mint.to_account_info())?;
        }

        // the vault's token account for the reward mint (WSOL ATA for SOL), idempotent
        associated_token::create_idempotent(CpiContext::new(
            a.associated_token_program.key(),
            associated_token::Create {
                payer: a.authority.to_account_info(),
                associated_token: a.vault_token_account.to_account_info(),
                authority: a.holder_vault.to_account_info(),
                mint: a.reward_mint.to_account_info(),
                system_program: a.system_program.to_account_info(),
                token_program: a.reward_token_program.to_account_info(),
            },
        ))?;

        let reserve = if is_sol {
            let rent = Rent::get()?.minimum_balance(0);
            system_program::transfer(
                CpiContext::new(
                    a.system_program.key(),
                    system_program::Transfer {
                        from: a.authority.to_account_info(),
                        to: a.holder_vault.to_account_info(),
                    },
                ),
                rent,
            )?;
            rent
        } else {
            0
        };

        let d = &mut ctx.accounts.distributor;
        d.version = 1;
        d.bump = ctx.bumps.distributor;
        d.vault_bump = ctx.bumps.holder_vault;
        d.mint = ctx.accounts.mint.key();
        d.reward_mint = reward_mint;
        d.reward_token_program = ctx.accounts.reward_token_program.key();
        d.reward_decimals = ctx.accounts.reward_mint.decimals;
        d.holder_vault = ctx.accounts.holder_vault.key();
        d.token_vault = ctx.accounts.vault_token_account.key();
        d.vault_reserve = reserve;
        d.round = 0;
        d.root = [0; 32];
        d.max_total_claim = 0;
        d.total_claimed = 0;
        d.snapshot_slot = 0;
        d.data_hash = [0; 32];
        d.activated_at = 0;
        d.has_pending = false;
        d.created_by = signer;
        emit!(DistributorInitialized {
            distributor: d.key(),
            mint: d.mint,
            reward_mint,
            holder_vault: d.holder_vault,
            token_vault: d.token_vault,
            vault_reserve: reserve,
        });
        Ok(())
    }

    /// Anyone: adds `amount` SOL to a SOL distributor's holder vault (Phase 2–3 may CPI this
    /// or credit the vault directly; see docs/V1_FEES.md section 4.5).
    pub fn deposit_sol(ctx: Context<DepositSol>, amount: u64) -> Result<()> {
        require!(amount > 0, RewardsError::ZeroAmount);
        system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.key(),
                system_program::Transfer {
                    from: ctx.accounts.depositor.to_account_info(),
                    to: ctx.accounts.holder_vault.to_account_info(),
                },
            ),
            amount,
        )?;
        emit!(RewardsDeposited {
            distributor: ctx.accounts.distributor.key(),
            depositor: ctx.accounts.depositor.key(),
            amount,
        });
        Ok(())
    }

    /// Anyone: adds `amount` of the reward token to a token distributor's vault.
    pub fn deposit_token(ctx: Context<DepositToken>, amount: u64) -> Result<()> {
        require!(amount > 0, RewardsError::ZeroAmount);
        token_interface::transfer_checked(
            CpiContext::new(
                ctx.accounts.token_program.key(),
                token_interface::TransferChecked {
                    from: ctx.accounts.depositor_token.to_account_info(),
                    mint: ctx.accounts.reward_mint.to_account_info(),
                    to: ctx.accounts.token_vault.to_account_info(),
                    authority: ctx.accounts.depositor.to_account_info(),
                },
            ),
            amount,
            ctx.accounts.reward_mint.decimals,
        )?;
        emit!(RewardsDeposited {
            distributor: ctx.accounts.distributor.key(),
            depositor: ctx.accounts.depositor.key(),
            amount,
        });
        Ok(())
    }

    /// PERMISSIONLESS: turns the WSOL in ATA(WSOL, holder_vault) (DeepSwap reward fees) into
    /// lamports of the holder vault, through a temporary WSOL account created and closed here.
    /// The caller fronts the temporary account's rent and gets it back in the same
    /// instruction; the vault's ATA is never closed (deep-amm pays into it).
    pub fn unwrap_wsol(ctx: Context<UnwrapWsol>) -> Result<()> {
        let a = &ctx.accounts;
        let amount = a.wsol_vault.amount;
        require!(amount > 0, RewardsError::ZeroAmount);
        let mint_key = a.distributor.mint;
        let vault_bump = [a.distributor.vault_bump];
        let vault_seeds: &[&[u8]] = &[HOLDER_VAULT_SEED, mint_key.as_ref(), &vault_bump];
        let dist_key = a.distributor.key();
        let tmp_bump = [ctx.bumps.wsol_unwrap];
        let tmp_seeds: &[&[u8]] = &[WSOL_UNWRAP_SEED, dist_key.as_ref(), &tmp_bump];
        let tmp = a.wsol_unwrap.to_account_info();
        let vault = a.holder_vault.to_account_info();
        let payer = a.payer.to_account_info();
        let sys = a.system_program.key();
        let rent = Rent::get()?.minimum_balance(SPL_TOKEN_ACCOUNT_LEN as usize);

        let fronted = if tmp.lamports() == 0 {
            system_program::create_account(
                CpiContext::new_with_signer(
                    sys,
                    system_program::CreateAccount {
                        from: payer.clone(),
                        to: tmp.clone(),
                    },
                    &[tmp_seeds],
                ),
                rent,
                SPL_TOKEN_ACCOUNT_LEN,
                &token::ID,
            )?;
            rent
        } else {
            // Pre-funded by someone (griefing): top up, allocate and assign. The extra lamports
            // end up in the vault as rewards; the caller is refunded only what it fronted.
            let short = rent.saturating_sub(tmp.lamports());
            if short > 0 {
                system_program::transfer(
                    CpiContext::new(
                        sys,
                        system_program::Transfer {
                            from: payer.clone(),
                            to: tmp.clone(),
                        },
                    ),
                    short,
                )?;
            }
            system_program::allocate(
                CpiContext::new_with_signer(
                    sys,
                    system_program::Allocate {
                        account_to_allocate: tmp.clone(),
                    },
                    &[tmp_seeds],
                ),
                SPL_TOKEN_ACCOUNT_LEN,
            )?;
            system_program::assign(
                CpiContext::new_with_signer(
                    sys,
                    system_program::Assign {
                        account_to_assign: tmp.clone(),
                    },
                    &[tmp_seeds],
                ),
                &token::ID,
            )?;
            short
        };
        let tp = a.token_program.key();
        token::initialize_account3(CpiContext::new(
            tp,
            token::InitializeAccount3 {
                account: tmp.clone(),
                mint: a.wsol_mint.to_account_info(),
                authority: vault.clone(),
            },
        ))?;
        token::transfer(
            CpiContext::new_with_signer(
                tp,
                token::Transfer {
                    from: a.wsol_vault.to_account_info(),
                    to: tmp.clone(),
                    authority: vault.clone(),
                },
                &[vault_seeds],
            ),
            amount,
        )?;
        token::close_account(CpiContext::new_with_signer(
            tp,
            token::CloseAccount {
                account: tmp,
                destination: vault.clone(),
                authority: vault.clone(),
            },
            &[vault_seeds],
        ))?;
        if fronted > 0 {
            system_program::transfer(
                CpiContext::new_with_signer(
                    sys,
                    system_program::Transfer {
                        from: vault,
                        to: payer,
                    },
                    &[vault_seeds],
                ),
                fronted,
            )?;
        }
        emit!(WsolUnwrapped {
            distributor: dist_key,
            amount,
        });
        Ok(())
    }

    /// Root authority: publishes the next cumulative root. It always waits as pending
    /// (replacing any older pending root) for `root_delay_seconds`, until `activate_root`; the
    /// admin or the guardian may veto it meanwhile. No root is ever active at once: the delay
    /// is at least `MIN_ROOT_DELAY_SECONDS` (params validation and `migrate_config`), and this
    /// instruction has no path that activates.
    pub fn propose_root(
        ctx: Context<ProposeRoot>,
        root: [u8; 32],
        max_total_claim: u64,
        snapshot_slot: u64,
        data_hash: [u8; 32],
    ) -> Result<()> {
        let cfg = &ctx.accounts.config;
        require!(!cfg.paused, RewardsError::Paused);
        require!(root != [0u8; 32], RewardsError::InvalidParams);
        let available = available_of(
            &ctx.accounts.distributor,
            ctx.accounts.holder_vault.lamports(),
            ctx.accounts.token_vault.amount,
        );
        let clock = Clock::get()?;
        let d = &mut ctx.accounts.distributor;
        require!(
            max_total_claim >= d.max_total_claim,
            RewardsError::RootNotMonotonic
        );
        let funded = d
            .total_claimed
            .checked_add(available)
            .ok_or(RewardsError::Overflow)?;
        require!(max_total_claim <= funded, RewardsError::RootUnfunded);
        require!(
            snapshot_slot > d.snapshot_slot && snapshot_slot <= clock.slot,
            RewardsError::StaleSnapshot
        );
        let eta = clock
            .unix_timestamp
            .checked_add(cfg.root_delay_seconds as i64)
            .ok_or(RewardsError::Overflow)?;
        d.pending_root = root;
        d.pending_max_total_claim = max_total_claim;
        d.pending_snapshot_slot = snapshot_slot;
        d.pending_data_hash = data_hash;
        d.pending_eta = eta;
        d.has_pending = true;
        emit!(RootProposed {
            distributor: d.key(),
            root,
            max_total_claim,
            snapshot_slot,
            data_hash,
            eta,
        });
        Ok(())
    }

    /// PERMISSIONLESS after the pending root's eta. Re-checks the funding bound.
    pub fn activate_root(ctx: Context<ActivateRoot>) -> Result<()> {
        let available = available_of(
            &ctx.accounts.distributor,
            ctx.accounts.holder_vault.lamports(),
            ctx.accounts.token_vault.amount,
        );
        let now = Clock::get()?.unix_timestamp;
        let d = &mut ctx.accounts.distributor;
        require!(d.has_pending, RewardsError::NoPendingRoot);
        require!(now >= d.pending_eta, RewardsError::RootNotReady);
        let funded = d
            .total_claimed
            .checked_add(available)
            .ok_or(RewardsError::Overflow)?;
        require!(
            d.pending_max_total_claim <= funded,
            RewardsError::RootUnfunded
        );
        require!(
            d.pending_max_total_claim >= d.max_total_claim,
            RewardsError::RootNotMonotonic
        );
        let key = d.key();
        activate(d, key, now)
    }

    /// Admin or guardian: discards the pending root. Moves no funds; the active root stays.
    pub fn veto_root(ctx: Context<VetoRoot>) -> Result<()> {
        let d = &mut ctx.accounts.distributor;
        require!(d.has_pending, RewardsError::NoPendingRoot);
        let root = d.pending_root;
        clear_pending(d);
        emit!(RootVetoed {
            distributor: d.key(),
            root,
        });
        Ok(())
    }

    /// The claimant (signer) takes `cumulative_amount − claimed` lamports from a SOL
    /// distributor. Never paused. `ClaimStatus` is created on first claim (claimant pays).
    pub fn claim_sol(
        ctx: Context<ClaimSol>,
        cumulative_amount: u64,
        proof: Vec<[u8; 32]>,
    ) -> Result<()> {
        let max_proof = ctx.accounts.config.max_proof_len;
        let claimant = ctx.accounts.claimant.key();
        let payer = claimant;
        let dist_key = ctx.accounts.distributor.key();
        let pay = settle(
            &mut ctx.accounts.distributor,
            &mut ctx.accounts.claim_status,
            ctx.bumps.claim_status,
            dist_key,
            claimant,
            payer,
            cumulative_amount,
            &proof,
            max_proof,
        )?;
        pay_sol(
            &ctx.accounts.distributor,
            &ctx.accounts.holder_vault.to_account_info(),
            &ctx.accounts.claimant.to_account_info(),
            &ctx.accounts.system_program,
            pay,
        )?;
        emit_claimed(&ctx.accounts.distributor, dist_key, claimant, payer, pay, cumulative_amount, false);
        Ok(())
    }

    /// The claimant (signer) takes `cumulative_amount − claimed` of the reward token into a
    /// token account it owns. Never paused.
    pub fn claim_token(
        ctx: Context<ClaimToken>,
        cumulative_amount: u64,
        proof: Vec<[u8; 32]>,
    ) -> Result<()> {
        let max_proof = ctx.accounts.config.max_proof_len;
        let claimant = ctx.accounts.claimant.key();
        let dist_key = ctx.accounts.distributor.key();
        let pay = settle(
            &mut ctx.accounts.distributor,
            &mut ctx.accounts.claim_status,
            ctx.bumps.claim_status,
            dist_key,
            claimant,
            claimant,
            cumulative_amount,
            &proof,
            max_proof,
        )?;
        pay_token(
            &ctx.accounts.distributor,
            &ctx.accounts.holder_vault.to_account_info(),
            &ctx.accounts.token_vault.to_account_info(),
            &ctx.accounts.reward_mint,
            &ctx.accounts.claimant_token.to_account_info(),
            &ctx.accounts.token_program,
            pay,
        )?;
        emit_claimed(&ctx.accounts.distributor, dist_key, claimant, claimant, pay, cumulative_amount, false);
        Ok(())
    }

    /// AUTO-SEND (PERMISSIONLESS crank, payout mode 1 only): pushes a holder's unclaimed SOL
    /// when it is worth at least `push_min_usd_micros` at the Pyth SOL/USD price. The recipient
    /// must be a plain system account (a wallet) that ends rent-exempt; otherwise the
    /// instruction fails, nothing changes, and the amount stays claimable.
    pub fn push_sol(
        ctx: Context<PushSol>,
        cumulative_amount: u64,
        proof: Vec<[u8; 32]>,
    ) -> Result<()> {
        let cfg = &ctx.accounts.config;
        require!(
            cfg.payout_mode == PAYOUT_MODE_AUTO_SEND,
            RewardsError::PushDisabled
        );
        require!(!cfg.paused, RewardsError::Paused);
        let max_proof = cfg.max_proof_len;
        let max_age = cfg.max_price_age_seconds;
        let push_min = cfg.push_min_usd_micros;
        let claimant_info = ctx.accounts.claimant.to_account_info();
        // recipient checks BEFORE any state change
        require!(
            claimant_info.owner == &system_program::ID
                && !claimant_info.executable
                && claimant_info.data_is_empty(),
            RewardsError::RecipientNotEligible
        );
        let claimant = claimant_info.key();
        let payer = ctx.accounts.cranker.key();
        let dist_key = ctx.accounts.distributor.key();
        let pay = settle(
            &mut ctx.accounts.distributor,
            &mut ctx.accounts.claim_status,
            ctx.bumps.claim_status,
            dist_key,
            claimant,
            payer,
            cumulative_amount,
            &proof,
            max_proof,
        )?;
        // value check
        let price_info = ctx.accounts.price_update.to_account_info();
        require_keys_eq!(
            *price_info.owner,
            pyth::RECEIVER_PROGRAM_ID,
            RewardsError::PriceInvalid
        );
        let data = price_info.try_borrow_data()?;
        let p = pyth::decode_price_update(&data).map_err(|_| RewardsError::PriceInvalid)?;
        drop(data);
        let now = Clock::get()?.unix_timestamp;
        pyth::validate(&p, now, max_age).map_err(|_| RewardsError::PriceInvalid)?;
        let usd = pyth::lamports_usd_micros(pay, p.price, p.exponent)
            .ok_or(RewardsError::PriceInvalid)?;
        require!(usd >= push_min as u128, RewardsError::BelowPushThreshold);
        let rent_min = Rent::get()?.minimum_balance(0);
        let after = claimant_info
            .lamports()
            .checked_add(pay)
            .ok_or(RewardsError::Overflow)?;
        require!(after >= rent_min, RewardsError::RecipientNotEligible);
        pay_sol(
            &ctx.accounts.distributor,
            &ctx.accounts.holder_vault.to_account_info(),
            &claimant_info,
            &ctx.accounts.system_program,
            pay,
        )?;
        emit_claimed(&ctx.accounts.distributor, dist_key, claimant, payer, pay, cumulative_amount, true);
        Ok(())
    }

    /// AUTO-SEND for a token distributor whose reward mint is a configured USD stablecoin
    /// (valued at face). Other assets are claim-only. Creates the claimant's ATA idempotently
    /// (cranker pays); a frozen recipient account fails the instruction (stays claimable).
    pub fn push_token(
        ctx: Context<PushToken>,
        cumulative_amount: u64,
        proof: Vec<[u8; 32]>,
    ) -> Result<()> {
        let cfg = &ctx.accounts.config;
        require!(
            cfg.payout_mode == PAYOUT_MODE_AUTO_SEND,
            RewardsError::PushDisabled
        );
        require!(!cfg.paused, RewardsError::Paused);
        let reward_mint = ctx.accounts.reward_mint.key();
        require!(cfg.is_stable(&reward_mint), RewardsError::PushUnsupportedAsset);
        let max_proof = cfg.max_proof_len;
        let push_min = cfg.push_min_usd_micros;
        let claimant = ctx.accounts.claimant.key();
        let payer = ctx.accounts.cranker.key();
        let dist_key = ctx.accounts.distributor.key();
        let pay = settle(
            &mut ctx.accounts.distributor,
            &mut ctx.accounts.claim_status,
            ctx.bumps.claim_status,
            dist_key,
            claimant,
            payer,
            cumulative_amount,
            &proof,
            max_proof,
        )?;
        let usd = pyth::stable_usd_micros(pay, ctx.accounts.reward_mint.decimals)
            .ok_or(RewardsError::Overflow)?;
        require!(usd >= push_min as u128, RewardsError::BelowPushThreshold);

        associated_token::create_idempotent(CpiContext::new(
            ctx.accounts.associated_token_program.key(),
            associated_token::Create {
                payer: ctx.accounts.cranker.to_account_info(),
                associated_token: ctx.accounts.claimant_token.to_account_info(),
                authority: ctx.accounts.claimant.to_account_info(),
                mint: ctx.accounts.reward_mint.to_account_info(),
                system_program: ctx.accounts.system_program.to_account_info(),
                token_program: ctx.accounts.token_program.to_account_info(),
            },
        ))?;
        // recipient check: the ATA program verified owner/mint; refuse a frozen account
        {
            let info = ctx.accounts.claimant_token.to_account_info();
            let data = info.try_borrow_data()?;
            let st = StateWithExtensions::<spl_token_2022::state::Account>::unpack(&data)
                .map_err(|_| RewardsError::RecipientNotEligible)?;
            require!(
                st.base.state == spl_token_2022::state::AccountState::Initialized,
                RewardsError::RecipientFrozen
            );
            require_keys_eq!(st.base.owner, claimant, RewardsError::RecipientNotEligible);
            require_keys_eq!(st.base.mint, reward_mint, RewardsError::RecipientNotEligible);
        }
        pay_token(
            &ctx.accounts.distributor,
            &ctx.accounts.holder_vault.to_account_info(),
            &ctx.accounts.token_vault.to_account_info(),
            &ctx.accounts.reward_mint,
            &ctx.accounts.claimant_token.to_account_info(),
            &ctx.accounts.token_program,
            pay,
        )?;
        emit_claimed(&ctx.accounts.distributor, dist_key, claimant, payer, pay, cumulative_amount, true);
        Ok(())
    }

    /// PERMISSIONLESS: moves a token balance that is NOT a reward asset out of a holder vault
    /// token account (e.g. the rewarded token itself sent to the vault, or an airdrop) to
    /// `config.stray_recipient` (its ATA, created idempotently, caller pays), then closes the
    /// emptied account with its rent to the stray recipient. Reward assets (native SOL / WSOL,
    /// configured stablecoins, any mint with a distributor for this token) are refused, so this
    /// can never take holder rewards.
    pub fn recover_stray(ctx: Context<RecoverStray>) -> Result<()> {
        recover_stray_impl(ctx)
    }
}

// ─────────────────────────── helpers ───────────────────────────

/// Body of `recover_stray` (see the instruction's doc comment).
fn recover_stray_impl(ctx: Context<RecoverStray>) -> Result<()> {
    let a = &ctx.accounts;
    let mint = a.mint.key();
    let stray = a.stray_mint.key();
    // Never a reward asset. The rewarded token itself can never be one (init_distributor refuses
    // mint == reward_mint). Any other mint is stray only if it is not native SOL (always a
    // reward asset, credited before any distributor may exist), not a configured stablecoin
    // (the quote assets of stock pairs) and has no distributor for this token.
    //
    // A reward balance that still WAITS for its distributor is never sweepable (security review
    // F3): the only source of rewards in another token is a DeepSwap Holder pool quoted in it,
    // and deep-amm creates such a pool only when the (token, quote) distributor already exists
    // (`HolderRewardsNeedDistributor`); the one exemption is a SOL quote, refused right here.
    // Distributors are never closed, so once a pool can pay a quote token into this vault the
    // check below refuses that token for good.
    if stray != mint {
        require!(
            stray != NATIVE_MINT && !a.config.is_stable(&stray),
            RewardsError::NotStray
        );
        let d = a.reward_distributor.to_account_info();
        require!(
            d.lamports() == 0 && d.data_is_empty(),
            RewardsError::NotStray
        );
    }
    let amount = a.vault_token.amount;
    let bump = [ctx.bumps.holder_vault];
    let seeds: &[&[u8]] = &[HOLDER_VAULT_SEED, mint.as_ref(), &bump];
    if amount > 0 {
        associated_token::create_idempotent(CpiContext::new(
            a.associated_token_program.key(),
            associated_token::Create {
                payer: a.cranker.to_account_info(),
                associated_token: a.recipient_token.to_account_info(),
                authority: a.stray_recipient.to_account_info(),
                mint: a.stray_mint.to_account_info(),
                system_program: a.system_program.to_account_info(),
                token_program: a.token_program.to_account_info(),
            },
        ))?;
        token_interface::transfer_checked(
            CpiContext::new_with_signer(
                a.token_program.key(),
                token_interface::TransferChecked {
                    from: a.vault_token.to_account_info(),
                    mint: a.stray_mint.to_account_info(),
                    to: a.recipient_token.to_account_info(),
                    authority: a.holder_vault.to_account_info(),
                },
                &[seeds],
            ),
            amount,
            a.stray_mint.decimals,
        )?;
    }
    // Close the now-empty account, rent to the stray recipient, unless Token-2022 still holds
    // withheld transfer fees in it (those belong to the mint's withdraw authority; closing would
    // fail). It can be closed by a later call once they are harvested.
    let closable = {
        let info = a.vault_token.to_account_info();
        let data = info.try_borrow_data()?;
        match StateWithExtensions::<spl_token_2022::state::Account>::unpack(&data) {
            Ok(st) => match st.get_extension::<TransferFeeAmount>() {
                Ok(fee) => u64::from(fee.withheld_amount) == 0,
                Err(_) => true,
            },
            Err(_) => false,
        }
    };
    if closable {
        token_interface::close_account(CpiContext::new_with_signer(
            a.token_program.key(),
            token_interface::CloseAccount {
                account: a.vault_token.to_account_info(),
                destination: a.stray_recipient.to_account_info(),
                authority: a.holder_vault.to_account_info(),
            },
            &[seeds],
        ))?;
    }
    emit!(StrayRecovered {
        mint,
        stray_mint: stray,
        token_account: a.vault_token.key(),
        recipient: a.stray_recipient.key(),
        amount,
        closed: closable,
    });
    Ok(())
}

/// Funds the vault can still pay out: SOL = lamports above the reserved rent minimum;
/// token = the vault ATA's balance.
pub fn available_of(d: &Distributor, vault_lamports: u64, token_vault_amount: u64) -> u64 {
    if d.reward_mint == NATIVE_MINT {
        vault_lamports.saturating_sub(d.vault_reserve)
    } else {
        token_vault_amount
    }
}

fn clear_pending(d: &mut Distributor) {
    d.pending_root = [0; 32];
    d.pending_max_total_claim = 0;
    d.pending_snapshot_slot = 0;
    d.pending_data_hash = [0; 32];
    d.pending_eta = 0;
    d.has_pending = false;
}

fn activate(d: &mut Distributor, dist_key: Pubkey, now: i64) -> Result<()> {
    d.root = d.pending_root;
    d.max_total_claim = d.pending_max_total_claim;
    d.snapshot_slot = d.pending_snapshot_slot;
    d.data_hash = d.pending_data_hash;
    d.round = d.round.checked_add(1).ok_or(RewardsError::Overflow)?;
    d.activated_at = now;
    clear_pending(d);
    emit!(RootActivated {
        distributor: dist_key,
        round: d.round,
        root: d.root,
        max_total_claim: d.max_total_claim,
        snapshot_slot: d.snapshot_slot,
        data_hash: d.data_hash,
    });
    Ok(())
}

/// Verifies the leaf against the ACTIVE root and books the payment. Returns the amount due.
#[allow(clippy::too_many_arguments)]
fn settle(
    d: &mut Distributor,
    status: &mut ClaimStatus,
    status_bump: u8,
    dist_key: Pubkey,
    claimant: Pubkey,
    payer: Pubkey,
    cumulative_amount: u64,
    proof: &[[u8; 32]],
    max_proof_len: u8,
) -> Result<u64> {
    require!(d.round > 0, RewardsError::NoRoot);
    require!(
        proof.len() <= max_proof_len as usize && proof.len() <= merkle::MAX_PROOF_LEN,
        RewardsError::ProofTooLong
    );
    let leaf = merkle::leaf_hash(&dist_key, &claimant, cumulative_amount);
    require!(
        merkle::verify(proof, &d.root, leaf),
        RewardsError::InvalidProof
    );
    if status.claimant == Pubkey::default() {
        status.version = 1;
        status.bump = status_bump;
        status.distributor = dist_key;
        status.claimant = claimant;
        status.payer = payer;
        status.claimed = 0;
    } else {
        require_keys_eq!(status.distributor, dist_key, RewardsError::InvalidClaimStatus);
        require_keys_eq!(status.claimant, claimant, RewardsError::InvalidClaimStatus);
    }
    require!(
        cumulative_amount > status.claimed,
        RewardsError::NothingToClaim
    );
    let pay = cumulative_amount - status.claimed;
    let total = d
        .total_claimed
        .checked_add(pay)
        .ok_or(RewardsError::Overflow)?;
    require!(total <= d.max_total_claim, RewardsError::ExceedsMaxTotal);
    status.claimed = cumulative_amount;
    status.last_claim_at = Clock::get()?.unix_timestamp;
    d.total_claimed = total;
    Ok(pay)
}

fn pay_sol<'info>(
    d: &Distributor,
    holder_vault: &AccountInfo<'info>,
    to: &AccountInfo<'info>,
    system: &Program<'info, System>,
    amount: u64,
) -> Result<()> {
    // The reserve can never be paid out: the root funding bound keeps
    // total_claimed ≤ max_total_claim ≤ total_claimed_before + (lamports − reserve).
    let after = holder_vault
        .lamports()
        .checked_sub(amount)
        .ok_or(RewardsError::VaultShort)?;
    require!(after >= d.vault_reserve, RewardsError::VaultShort);
    let bump = [d.vault_bump];
    let seeds: &[&[u8]] = &[HOLDER_VAULT_SEED, d.mint.as_ref(), &bump];
    system_program::transfer(
        CpiContext::new_with_signer(
            system.key(),
            system_program::Transfer {
                from: holder_vault.clone(),
                to: to.clone(),
            },
            &[seeds],
        ),
        amount,
    )
}

fn pay_token<'info>(
    d: &Distributor,
    holder_vault: &AccountInfo<'info>,
    token_vault: &AccountInfo<'info>,
    mint: &InterfaceAccount<'info, Mint>,
    to: &AccountInfo<'info>,
    token_program: &Interface<'info, TokenInterface>,
    amount: u64,
) -> Result<()> {
    let bump = [d.vault_bump];
    let seeds: &[&[u8]] = &[HOLDER_VAULT_SEED, d.mint.as_ref(), &bump];
    token_interface::transfer_checked(
        CpiContext::new_with_signer(
            token_program.key(),
            token_interface::TransferChecked {
                from: token_vault.clone(),
                mint: mint.to_account_info(),
                to: to.clone(),
                authority: holder_vault.clone(),
            },
            &[seeds],
        ),
        amount,
        mint.decimals,
    )
}

fn emit_claimed(
    d: &Distributor,
    dist_key: Pubkey,
    claimant: Pubkey,
    payer: Pubkey,
    amount: u64,
    cumulative_amount: u64,
    pushed: bool,
) {
    emit!(RewardClaimed {
        distributor: dist_key,
        mint: d.mint,
        reward_mint: d.reward_mint,
        claimant,
        payer,
        amount,
        cumulative_amount,
        total_claimed: d.total_claimed,
        round: d.round,
        pushed,
    });
}

/// Token-2022 reward mints: refuse extensions under which a payout could fail for every
/// holder (an active transfer hook needs extra accounts we do not forward; a non-transferable
/// mint cannot be paid out at all).
fn check_reward_mint_extensions(mint: &AccountInfo) -> Result<()> {
    if mint.owner != &spl_token_2022::ID {
        return Ok(());
    }
    let data = mint.try_borrow_data()?;
    let st = StateWithExtensions::<spl_token_2022::state::Mint>::unpack(&data)
        .map_err(|_| RewardsError::UnsupportedRewardMint)?;
    if let Ok(hook) = st.get_extension::<TransferHook>() {
        let program: Option<Pubkey> = hook.program_id.into();
        require!(program.is_none(), RewardsError::UnsupportedRewardMint);
    }
    require!(
        st.get_extension::<NonTransferable>().is_err(),
        RewardsError::UnsupportedRewardMint
    );
    Ok(())
}

// ─────────────────────────── state ───────────────────────────

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq, Eq, InitSpace)]
pub struct RewardsConfigParams {
    /// Hot key of the snapshot job; publishes roots. Must differ from the admin.
    pub root_authority: Pubkey,
    pub payout_mode: u8,
    pub root_delay_seconds: u32,
    pub max_proof_len: u8,
    pub push_min_usd_micros: u64,
    pub min_holding_usd_micros: u64,
    pub max_price_age_seconds: u32,
    pub sol_usd_price_update: Pubkey,
    #[max_len(4)]
    pub stable_mints: Vec<Pubkey>,
    /// Receives NON-reward tokens swept out of holder vaults by `recover_stray` (default: the
    /// admin; DEEP V1 Phase 1 sets it to the deep-curve fee vault).
    pub stray_recipient: Pubkey,
    /// Veto-only key (appended; security review F1): may sign `veto_root` and `set_paused`,
    /// nothing else. Meant to be a key that can act faster than the admin (mainnet: the
    /// instant "pause" Squads vault, while the admin sits behind a 48 h time lock). Never the
    /// root authority, never the zero key.
    pub guardian: Pubkey,
}

/// `RewardsConfigParams` as stored before the guardian existed (devnet), read once by
/// `migrate_config`.
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq, Eq)]
pub struct RewardsConfigParamsV1 {
    pub root_authority: Pubkey,
    pub payout_mode: u8,
    pub root_delay_seconds: u32,
    pub max_proof_len: u8,
    pub push_min_usd_micros: u64,
    pub min_holding_usd_micros: u64,
    pub max_price_age_seconds: u32,
    pub sol_usd_price_update: Pubkey,
    pub stable_mints: Vec<Pubkey>,
    pub stray_recipient: Pubkey,
}

impl RewardsConfigParamsV1 {
    pub fn with_guardian(self, guardian: Pubkey) -> RewardsConfigParams {
        RewardsConfigParams {
            root_authority: self.root_authority,
            payout_mode: self.payout_mode,
            root_delay_seconds: self.root_delay_seconds,
            max_proof_len: self.max_proof_len,
            push_min_usd_micros: self.push_min_usd_micros,
            min_holding_usd_micros: self.min_holding_usd_micros,
            max_price_age_seconds: self.max_price_age_seconds,
            sol_usd_price_update: self.sol_usd_price_update,
            stable_mints: self.stable_mints,
            stray_recipient: self.stray_recipient,
            guardian,
        }
    }
}

/// `PendingRewardsConfig` body (after the discriminator) before the guardian existed.
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq, Eq)]
pub struct PendingRewardsConfigV1 {
    pub bump: u8,
    pub active: bool,
    pub eta: i64,
    pub queued_at: i64,
    pub params: RewardsConfigParamsV1,
}

impl RewardsConfigParams {
    pub fn validate(&self, admin: &Pubkey) -> Result<()> {
        require!(
            self.root_authority != Pubkey::default() && self.root_authority != *admin,
            RewardsError::InvalidParams
        );
        // The guardian exists to stop the root authority: it is never that key, and never
        // missing. (It may be the admin: the admin holds both powers anyway.)
        require!(
            self.guardian != Pubkey::default() && self.guardian != self.root_authority,
            RewardsError::InvalidParams
        );
        require!(
            self.payout_mode <= PAYOUT_MODE_AUTO_SEND,
            RewardsError::InvalidParams
        );
        require!(
            (MIN_ROOT_DELAY_SECONDS..=MAX_ROOT_DELAY_SECONDS).contains(&self.root_delay_seconds),
            RewardsError::InvalidParams
        );
        require!(
            self.stray_recipient != Pubkey::default(),
            RewardsError::InvalidParams
        );
        require!(
            self.max_proof_len >= 1 && self.max_proof_len as usize <= merkle::MAX_PROOF_LEN,
            RewardsError::InvalidParams
        );
        require!(
            (MIN_PUSH_MIN_USD_MICROS..=MAX_USD_MICROS).contains(&self.push_min_usd_micros),
            RewardsError::InvalidParams
        );
        require!(
            self.min_holding_usd_micros <= MAX_USD_MICROS,
            RewardsError::InvalidParams
        );
        require!(
            self.max_price_age_seconds >= 1
                && self.max_price_age_seconds <= pyth::MAX_PRICE_AGE_CAP_SECONDS,
            RewardsError::InvalidParams
        );
        require!(
            self.sol_usd_price_update != Pubkey::default(),
            RewardsError::InvalidParams
        );
        require!(
            self.stable_mints.len() <= MAX_STABLE_MINTS,
            RewardsError::InvalidParams
        );
        for (i, m) in self.stable_mints.iter().enumerate() {
            require!(
                *m != Pubkey::default() && *m != NATIVE_MINT,
                RewardsError::InvalidParams
            );
            require!(
                !self.stable_mints[..i].contains(m),
                RewardsError::InvalidParams
            );
        }
        Ok(())
    }
}

#[account]
#[derive(InitSpace)]
pub struct RewardsConfig {
    pub version: u8,
    pub bump: u8,
    pub admin: Pubkey,
    pub pending_admin: Pubkey,
    pub root_authority: Pubkey,
    pub payout_mode: u8,
    /// Blocks `propose_root` and pushes. Claims are never paused.
    pub paused: bool,
    pub root_delay_seconds: u32,
    pub max_proof_len: u8,
    pub push_min_usd_micros: u64,
    pub min_holding_usd_micros: u64,
    pub max_price_age_seconds: u32,
    pub sol_usd_price_update: Pubkey,
    pub stable_count: u8,
    pub stable_mints: [Pubkey; MAX_STABLE_MINTS],
    pub stray_recipient: Pubkey,
    /// Veto-only key: `veto_root` and `set_paused` (security review F1). Takes the first 32 of
    /// the 64 bytes that were reserved, so the account size is unchanged and a config written
    /// before it existed reads as the zero key, i.e. no guardian.
    pub guardian: Pubkey,
    pub reserved: [u8; 32],
}

/// The queued settings change (`queue_config_update` → `apply_config_update` after eta).
#[account]
#[derive(InitSpace)]
pub struct PendingRewardsConfig {
    pub bump: u8,
    pub active: bool,
    pub eta: i64,
    pub queued_at: i64,
    pub params: RewardsConfigParams,
}

impl RewardsConfig {
    fn apply(&mut self, p: &RewardsConfigParams) {
        self.root_authority = p.root_authority;
        self.payout_mode = p.payout_mode;
        self.root_delay_seconds = p.root_delay_seconds;
        self.max_proof_len = p.max_proof_len;
        self.push_min_usd_micros = p.push_min_usd_micros;
        self.min_holding_usd_micros = p.min_holding_usd_micros;
        self.max_price_age_seconds = p.max_price_age_seconds;
        self.sol_usd_price_update = p.sol_usd_price_update;
        self.stray_recipient = p.stray_recipient;
        self.guardian = p.guardian;
        self.stable_mints = [Pubkey::default(); MAX_STABLE_MINTS];
        for (i, m) in p.stable_mints.iter().enumerate() {
            self.stable_mints[i] = *m;
        }
        self.stable_count = p.stable_mints.len() as u8;
    }

    /// The two keys that may veto a root and pause: the admin, and the guardian when one is
    /// set (the zero key is "no guardian" and can never match a signer).
    pub fn is_admin_or_guardian(&self, key: &Pubkey) -> bool {
        *key == self.admin || (self.guardian != Pubkey::default() && *key == self.guardian)
    }

    pub fn is_stable(&self, mint: &Pubkey) -> bool {
        self.stable_mints[..(self.stable_count as usize).min(MAX_STABLE_MINTS)].contains(mint)
    }
}

#[account]
#[derive(InitSpace)]
pub struct Distributor {
    pub version: u8,
    pub bump: u8,
    pub vault_bump: u8,
    /// The token whose holders are rewarded.
    pub mint: Pubkey,
    /// The paired asset paid out; `NATIVE_MINT` means native SOL.
    pub reward_mint: Pubkey,
    /// Token program of `reward_mint` (SPL Token for SOL's WSOL ATA).
    pub reward_token_program: Pubkey,
    pub reward_decimals: u8,
    /// `["holder_vault", mint]`: holds SOL rewards and owns the token vaults.
    pub holder_vault: Pubkey,
    /// ATA(reward_mint, holder_vault): the token vault (SOL: the WSOL ATA to unwrap).
    pub token_vault: Pubkey,
    /// SOL only: the vault's rent-exempt minimum, funded by `init_distributor`'s payer.
    pub vault_reserve: u64,
    /// Number of roots activated so far (0 = none yet).
    pub round: u32,
    pub root: [u8; 32],
    /// Sum of all cumulative leaves of the active root.
    pub max_total_claim: u64,
    pub total_claimed: u64,
    pub snapshot_slot: u64,
    /// sha256 of the published tree file for the active root.
    pub data_hash: [u8; 32],
    pub activated_at: i64,
    pub has_pending: bool,
    pub pending_root: [u8; 32],
    pub pending_max_total_claim: u64,
    pub pending_snapshot_slot: u64,
    pub pending_data_hash: [u8; 32],
    pub pending_eta: i64,
    pub created_by: Pubkey,
    pub reserved: [u8; 64],
}

/// Per (distributor, claimant): the cumulative amount already paid. Permanent: closing it
/// would let the same cumulative leaf be claimed again.
#[account]
#[derive(InitSpace)]
pub struct ClaimStatus {
    pub version: u8,
    pub bump: u8,
    pub distributor: Pubkey,
    pub claimant: Pubkey,
    /// Who paid this account's rent (the claimant, or the AUTO-SEND cranker).
    pub payer: Pubkey,
    pub claimed: u64,
    pub last_claim_at: i64,
}

// ─────────────────────────── accounts ───────────────────────────

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(init, payer = admin, space = 8 + RewardsConfig::INIT_SPACE, seeds = [REWARDS_CONFIG_SEED], bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(init, payer = admin, space = 8 + PendingRewardsConfig::INIT_SPACE, seeds = [PENDING_CONFIG_SEED], bump)]
    pub pending_config: Box<Account<'info, PendingRewardsConfig>>,
    #[account(constraint = program.programdata_address()? == Some(program_data.key()) @ RewardsError::Unauthorized)]
    pub program: Program<'info, crate::program::DeepRewards>,
    #[account(constraint = program_data.upgrade_authority_address == Some(admin.key()) @ RewardsError::Unauthorized)]
    pub program_data: Account<'info, ProgramData>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AdminOnly<'info> {
    pub admin: Signer<'info>,
    #[account(mut, seeds = [REWARDS_CONFIG_SEED], bump = config.bump, has_one = admin @ RewardsError::Unauthorized)]
    pub config: Box<Account<'info, RewardsConfig>>,
}

/// `set_paused`: the admin or the guardian.
#[derive(Accounts)]
pub struct AdminOrGuardian<'info> {
    pub authority: Signer<'info>,
    #[account(
        mut,
        seeds = [REWARDS_CONFIG_SEED], bump = config.bump,
        constraint = config.is_admin_or_guardian(&authority.key()) @ RewardsError::Unauthorized,
    )]
    pub config: Box<Account<'info, RewardsConfig>>,
}

#[derive(Accounts)]
pub struct MigrateConfig<'info> {
    /// Anyone; funds the rent difference of the grown PendingRewardsConfig.
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(mut, seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// CHECK: raw PendingRewardsConfig in the old or the new layout; owner, discriminator and
    /// size are checked in the handler.
    #[account(mut, seeds = [PENDING_CONFIG_SEED], bump)]
    pub pending_config: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct QueueConfigUpdate<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump, has_one = admin @ RewardsError::Unauthorized)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// Must be in the current layout: a PendingRewardsConfig written before the guardian
    /// existed is refused until the permissionless `migrate_config` has re-written it, so its
    /// old bytes are never read as a guardian.
    #[account(
        mut,
        seeds = [PENDING_CONFIG_SEED], bump = pending_config.bump,
        constraint = pending_config.to_account_info().data_len() == PENDING_CONFIG_V2_SIZE @ RewardsError::ConfigNotMigrated,
    )]
    pub pending_config: Box<Account<'info, PendingRewardsConfig>>,
}

#[derive(Accounts)]
pub struct ApplyConfigUpdate<'info> {
    #[account(mut, seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// Must be in the current layout: a PendingRewardsConfig written before the guardian
    /// existed is refused until the permissionless `migrate_config` has re-written it, so its
    /// old bytes are never read as a guardian.
    #[account(
        mut,
        seeds = [PENDING_CONFIG_SEED], bump = pending_config.bump,
        constraint = pending_config.to_account_info().data_len() == PENDING_CONFIG_V2_SIZE @ RewardsError::ConfigNotMigrated,
    )]
    pub pending_config: Box<Account<'info, PendingRewardsConfig>>,
}

#[derive(Accounts)]
pub struct CancelConfigUpdate<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump, has_one = admin @ RewardsError::Unauthorized)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// Must be in the current layout: a PendingRewardsConfig written before the guardian
    /// existed is refused until the permissionless `migrate_config` has re-written it, so its
    /// old bytes are never read as a guardian.
    #[account(
        mut,
        seeds = [PENDING_CONFIG_SEED], bump = pending_config.bump,
        constraint = pending_config.to_account_info().data_len() == PENDING_CONFIG_V2_SIZE @ RewardsError::ConfigNotMigrated,
    )]
    pub pending_config: Box<Account<'info, PendingRewardsConfig>>,
}

#[derive(Accounts)]
pub struct RecoverStray<'info> {
    /// Anyone; pays the stray recipient's ATA rent if it does not exist.
    #[account(mut)]
    pub cranker: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// CHECK: only its address is used (the holder vault seed).
    pub mint: UncheckedAccount<'info>,
    #[account(seeds = [HOLDER_VAULT_SEED, mint.key().as_ref()], bump)]
    pub holder_vault: SystemAccount<'info>,
    /// CHECK: the would-be distributor (mint, stray_mint); must NOT exist (checked in handler).
    #[account(seeds = [DISTRIBUTOR_SEED, mint.key().as_ref(), stray_mint.key().as_ref()], bump)]
    pub reward_distributor: UncheckedAccount<'info>,
    #[account(mint::token_program = token_program)]
    pub stray_mint: Box<InterfaceAccount<'info, Mint>>,
    /// Any token account of `stray_mint` owned by the holder vault.
    #[account(
        mut,
        token::mint = stray_mint,
        token::authority = holder_vault,
        token::token_program = token_program,
    )]
    pub vault_token: Box<InterfaceAccount<'info, TokenAccount>>,
    /// CHECK: config.stray_recipient (address checked); receives the closed account's rent.
    #[account(mut, address = config.stray_recipient @ RewardsError::InvalidParams)]
    pub stray_recipient: UncheckedAccount<'info>,
    /// CHECK: ATA(stray_mint, stray_recipient) (address checked), created idempotently.
    #[account(
        mut,
        address = get_associated_token_address_with_program_id(
            &stray_recipient.key(), &stray_mint.key(), &token_program.key()
        ) @ RewardsError::InvalidParams,
    )]
    pub recipient_token: UncheckedAccount<'info>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AcceptAdmin<'info> {
    pub new_admin: Signer<'info>,
    #[account(mut, seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
}

#[derive(Accounts)]
pub struct InitDistributor<'info> {
    /// Admin or root authority; pays rent.
    #[account(mut)]
    pub authority: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    /// The token whose holders are rewarded (SPL Token or Token-2022).
    #[account(constraint = mint.key() != reward_mint.key() @ RewardsError::InvalidMint)]
    pub mint: Box<InterfaceAccount<'info, Mint>>,
    /// The paired asset (WSOL mint for native SOL).
    #[account(mint::token_program = reward_token_program)]
    pub reward_mint: Box<InterfaceAccount<'info, Mint>>,
    #[account(mut, seeds = [HOLDER_VAULT_SEED, mint.key().as_ref()], bump)]
    pub holder_vault: SystemAccount<'info>,
    #[account(
        init,
        payer = authority,
        space = 8 + Distributor::INIT_SPACE,
        seeds = [DISTRIBUTOR_SEED, mint.key().as_ref(), reward_mint.key().as_ref()],
        bump,
    )]
    pub distributor: Box<Account<'info, Distributor>>,
    /// CHECK: ATA(reward_mint, holder_vault, reward_token_program) (address checked), created
    /// idempotently in the handler.
    #[account(
        mut,
        address = get_associated_token_address_with_program_id(
            &holder_vault.key(), &reward_mint.key(), &reward_token_program.key()
        ) @ RewardsError::InvalidVault,
    )]
    pub vault_token_account: UncheckedAccount<'info>,
    pub reward_token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct DepositSol<'info> {
    #[account(mut)]
    pub depositor: Signer<'info>,
    #[account(constraint = distributor.reward_mint == NATIVE_MINT @ RewardsError::NotSolDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(mut, address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct DepositToken<'info> {
    pub depositor: Signer<'info>,
    #[account(constraint = distributor.reward_mint != NATIVE_MINT @ RewardsError::NotTokenDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(address = distributor.reward_mint @ RewardsError::InvalidMint)]
    pub reward_mint: Box<InterfaceAccount<'info, Mint>>,
    #[account(mut, token::mint = reward_mint, token::authority = depositor, token::token_program = token_program)]
    pub depositor_token: Box<InterfaceAccount<'info, TokenAccount>>,
    #[account(mut, address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub token_vault: Box<InterfaceAccount<'info, TokenAccount>>,
    #[account(address = distributor.reward_token_program @ RewardsError::InvalidVault)]
    pub token_program: Interface<'info, TokenInterface>,
}

#[derive(Accounts)]
pub struct UnwrapWsol<'info> {
    /// Fronts the temporary account's rent; refunded in the same instruction.
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(constraint = distributor.reward_mint == NATIVE_MINT @ RewardsError::NotSolDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(mut, address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    #[account(mut, address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub wsol_vault: Box<Account<'info, token::TokenAccount>>,
    /// CHECK: temporary WSOL account, created and closed inside the instruction.
    #[account(mut, seeds = [WSOL_UNWRAP_SEED, distributor.key().as_ref()], bump)]
    pub wsol_unwrap: UncheckedAccount<'info>,
    #[account(address = NATIVE_MINT @ RewardsError::InvalidMint)]
    pub wsol_mint: Box<Account<'info, token::Mint>>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ProposeRoot<'info> {
    pub root_authority: Signer<'info>,
    #[account(
        seeds = [REWARDS_CONFIG_SEED], bump = config.bump,
        has_one = root_authority @ RewardsError::Unauthorized,
    )]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    #[account(address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub token_vault: Box<InterfaceAccount<'info, TokenAccount>>,
}

#[derive(Accounts)]
pub struct ActivateRoot<'info> {
    #[account(mut)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    #[account(address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub token_vault: Box<InterfaceAccount<'info, TokenAccount>>,
}

#[derive(Accounts)]
pub struct VetoRoot<'info> {
    /// The admin or the guardian.
    pub authority: Signer<'info>,
    #[account(
        seeds = [REWARDS_CONFIG_SEED], bump = config.bump,
        constraint = config.is_admin_or_guardian(&authority.key()) @ RewardsError::Unauthorized,
    )]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut)]
    pub distributor: Box<Account<'info, Distributor>>,
}

#[derive(Accounts)]
pub struct ClaimSol<'info> {
    #[account(mut)]
    pub claimant: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut, constraint = distributor.reward_mint == NATIVE_MINT @ RewardsError::NotSolDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(
        mut,
        address = distributor.holder_vault @ RewardsError::InvalidVault,
        constraint = holder_vault.key() != claimant.key() @ RewardsError::RecipientNotEligible,
    )]
    pub holder_vault: SystemAccount<'info>,
    #[account(
        init_if_needed,
        payer = claimant,
        space = 8 + ClaimStatus::INIT_SPACE,
        seeds = [CLAIM_SEED, distributor.key().as_ref(), claimant.key().as_ref()],
        bump,
    )]
    pub claim_status: Box<Account<'info, ClaimStatus>>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ClaimToken<'info> {
    #[account(mut)]
    pub claimant: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut, constraint = distributor.reward_mint != NATIVE_MINT @ RewardsError::NotTokenDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    #[account(address = distributor.reward_mint @ RewardsError::InvalidMint)]
    pub reward_mint: Box<InterfaceAccount<'info, Mint>>,
    #[account(mut, address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub token_vault: Box<InterfaceAccount<'info, TokenAccount>>,
    /// Any token account of the reward mint owned by the claimant.
    #[account(
        mut,
        token::mint = reward_mint,
        token::authority = claimant,
        token::token_program = token_program,
        constraint = claimant_token.key() != token_vault.key() @ RewardsError::RecipientNotEligible,
    )]
    pub claimant_token: Box<InterfaceAccount<'info, TokenAccount>>,
    #[account(
        init_if_needed,
        payer = claimant,
        space = 8 + ClaimStatus::INIT_SPACE,
        seeds = [CLAIM_SEED, distributor.key().as_ref(), claimant.key().as_ref()],
        bump,
    )]
    pub claim_status: Box<Account<'info, ClaimStatus>>,
    #[account(address = distributor.reward_token_program @ RewardsError::InvalidVault)]
    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct PushSol<'info> {
    /// Anyone; pays the ClaimStatus rent on a first push and the fee.
    #[account(mut)]
    pub cranker: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut, constraint = distributor.reward_mint == NATIVE_MINT @ RewardsError::NotSolDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(mut, address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    /// CHECK: the leaf's wallet; must be a plain system account (checked in the handler).
    #[account(mut, constraint = claimant.key() != holder_vault.key() @ RewardsError::RecipientNotEligible)]
    pub claimant: UncheckedAccount<'info>,
    #[account(
        init_if_needed,
        payer = cranker,
        space = 8 + ClaimStatus::INIT_SPACE,
        seeds = [CLAIM_SEED, distributor.key().as_ref(), claimant.key().as_ref()],
        bump,
    )]
    pub claim_status: Box<Account<'info, ClaimStatus>>,
    /// CHECK: Pyth PriceUpdateV2 (address = config; owner and contents checked in the handler).
    #[account(address = config.sol_usd_price_update @ RewardsError::PriceInvalid)]
    pub price_update: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct PushToken<'info> {
    #[account(mut)]
    pub cranker: Signer<'info>,
    #[account(seeds = [REWARDS_CONFIG_SEED], bump = config.bump)]
    pub config: Box<Account<'info, RewardsConfig>>,
    #[account(mut, constraint = distributor.reward_mint != NATIVE_MINT @ RewardsError::NotTokenDistributor)]
    pub distributor: Box<Account<'info, Distributor>>,
    #[account(address = distributor.holder_vault @ RewardsError::InvalidVault)]
    pub holder_vault: SystemAccount<'info>,
    #[account(address = distributor.reward_mint @ RewardsError::InvalidMint)]
    pub reward_mint: Box<InterfaceAccount<'info, Mint>>,
    #[account(mut, address = distributor.token_vault @ RewardsError::InvalidVault)]
    pub token_vault: Box<InterfaceAccount<'info, TokenAccount>>,
    /// CHECK: the leaf's wallet (authority of the ATA below).
    #[account(constraint = claimant.key() != holder_vault.key() @ RewardsError::RecipientNotEligible)]
    pub claimant: UncheckedAccount<'info>,
    /// CHECK: ATA(reward_mint, claimant) (address checked); created idempotently, then checked.
    #[account(
        mut,
        address = get_associated_token_address_with_program_id(
            &claimant.key(), &reward_mint.key(), &token_program.key()
        ) @ RewardsError::RecipientNotEligible,
    )]
    pub claimant_token: UncheckedAccount<'info>,
    #[account(
        init_if_needed,
        payer = cranker,
        space = 8 + ClaimStatus::INIT_SPACE,
        seeds = [CLAIM_SEED, distributor.key().as_ref(), claimant.key().as_ref()],
        bump,
    )]
    pub claim_status: Box<Account<'info, ClaimStatus>>,
    #[account(address = distributor.reward_token_program @ RewardsError::InvalidVault)]
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

// ─────────────────────────── events ───────────────────────────

#[event]
pub struct RewardsConfigUpdated {
    pub admin: Pubkey,
    pub root_authority: Pubkey,
    pub payout_mode: u8,
    pub root_delay_seconds: u32,
    pub push_min_usd_micros: u64,
    pub min_holding_usd_micros: u64,
}

#[event]
pub struct ConfigUpdateQueued {
    pub eta: i64,
    pub root_authority: Pubkey,
    pub payout_mode: u8,
    pub root_delay_seconds: u32,
    pub stray_recipient: Pubkey,
}

#[event]
pub struct ConfigUpdateCancelled {
    pub eta: i64,
}

/// The guardian a queued settings change would set (emitted with `ConfigUpdateQueued`).
#[event]
pub struct GuardianChangeQueued {
    pub eta: i64,
    pub guardian: Pubkey,
}

/// The guardian in force (emitted with `RewardsConfigUpdated` by `initialize` and
/// `apply_config_update`).
#[event]
pub struct GuardianSet {
    pub guardian: Pubkey,
}

#[event]
pub struct StrayRecovered {
    pub mint: Pubkey,
    pub stray_mint: Pubkey,
    pub token_account: Pubkey,
    pub recipient: Pubkey,
    pub amount: u64,
    pub closed: bool,
}

#[event]
pub struct PausedSet {
    pub paused: bool,
}

#[event]
pub struct AdminProposed {
    pub new_admin: Pubkey,
}

#[event]
pub struct AdminAccepted {
    pub admin: Pubkey,
}

#[event]
pub struct DistributorInitialized {
    pub distributor: Pubkey,
    pub mint: Pubkey,
    pub reward_mint: Pubkey,
    pub holder_vault: Pubkey,
    pub token_vault: Pubkey,
    pub vault_reserve: u64,
}

#[event]
pub struct RewardsDeposited {
    pub distributor: Pubkey,
    pub depositor: Pubkey,
    pub amount: u64,
}

#[event]
pub struct WsolUnwrapped {
    pub distributor: Pubkey,
    pub amount: u64,
}

#[event]
pub struct RootProposed {
    pub distributor: Pubkey,
    pub root: [u8; 32],
    pub max_total_claim: u64,
    pub snapshot_slot: u64,
    pub data_hash: [u8; 32],
    pub eta: i64,
}

#[event]
pub struct RootActivated {
    pub distributor: Pubkey,
    pub round: u32,
    pub root: [u8; 32],
    pub max_total_claim: u64,
    pub snapshot_slot: u64,
    pub data_hash: [u8; 32],
}

#[event]
pub struct RootVetoed {
    pub distributor: Pubkey,
    pub root: [u8; 32],
}

#[event]
pub struct RewardClaimed {
    pub distributor: Pubkey,
    pub mint: Pubkey,
    pub reward_mint: Pubkey,
    pub claimant: Pubkey,
    pub payer: Pubkey,
    pub amount: u64,
    pub cumulative_amount: u64,
    pub total_claimed: u64,
    pub round: u32,
    pub pushed: bool,
}

// ─────────────────────────── errors ───────────────────────────

/// Append-only: never renumber (the SDK maps codes 6000+).
#[error_code]
pub enum RewardsError {
    #[msg("unauthorized")]
    Unauthorized,
    #[msg("invalid parameters")]
    InvalidParams,
    #[msg("paused (claims are never paused)")]
    Paused,
    #[msg("invalid mint")]
    InvalidMint,
    #[msg("unsupported reward mint")]
    UnsupportedRewardMint,
    #[msg("not a SOL distributor")]
    NotSolDistributor,
    #[msg("not a token distributor")]
    NotTokenDistributor,
    #[msg("invalid vault account")]
    InvalidVault,
    #[msg("no root has been activated yet")]
    NoRoot,
    #[msg("proof too long")]
    ProofTooLong,
    #[msg("invalid Merkle proof")]
    InvalidProof,
    #[msg("nothing to claim")]
    NothingToClaim,
    #[msg("claim exceeds the root's total")]
    ExceedsMaxTotal,
    #[msg("new root total is below the active one")]
    RootNotMonotonic,
    #[msg("root promises more than the vault holds")]
    RootUnfunded,
    #[msg("snapshot slot not newer than the active one, or in the future")]
    StaleSnapshot,
    #[msg("no pending root")]
    NoPendingRoot,
    #[msg("pending root not yet activatable")]
    RootNotReady,
    #[msg("auto-send is disabled (payout mode is CLAIM)")]
    PushDisabled,
    #[msg("unclaimed amount below the auto-send threshold")]
    BelowPushThreshold,
    #[msg("auto-send is not supported for this reward asset (claim only)")]
    PushUnsupportedAsset,
    #[msg("recipient cannot receive this payout")]
    RecipientNotEligible,
    #[msg("recipient token account is frozen")]
    RecipientFrozen,
    #[msg("Pyth SOL/USD price missing, stale or invalid")]
    PriceInvalid,
    #[msg("arithmetic overflow")]
    Overflow,
    #[msg("amount must be > 0")]
    ZeroAmount,
    #[msg("claim status does not match")]
    InvalidClaimStatus,
    #[msg("vault cannot cover this payout")]
    VaultShort,
    #[msg("a settings change is already queued")]
    ConfigUpdatePending,
    #[msg("no settings change is queued")]
    NoPendingConfigUpdate,
    #[msg("the queued settings change is not yet applicable")]
    ConfigUpdateNotReady,
    #[msg("the queued settings change expired; cancel and re-queue")]
    ConfigUpdateExpired,
    #[msg("this token is a reward asset, not stray")]
    NotStray,
    #[msg("PendingRewardsConfig is in the old layout; run migrate_config first")]
    ConfigNotMigrated,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn params(root_authority: Pubkey) -> RewardsConfigParams {
        RewardsConfigParams {
            root_authority,
            payout_mode: PAYOUT_MODE_CLAIM,
            root_delay_seconds: MIN_ROOT_DELAY_SECONDS,
            max_proof_len: 24,
            push_min_usd_micros: DEFAULT_PUSH_MIN_USD_MICROS,
            min_holding_usd_micros: DEFAULT_MIN_HOLDING_USD_MICROS,
            max_price_age_seconds: 120,
            sol_usd_price_update: pyth::SOL_USD_PRICE_UPDATE,
            stable_mints: vec![Pubkey::new_from_array([7; 32])],
            stray_recipient: Pubkey::new_from_array([1; 32]),
            guardian: Pubkey::new_from_array([9; 32]),
        }
    }

    #[test]
    fn params_validation() {
        let admin = Pubkey::new_from_array([1; 32]);
        let auth = Pubkey::new_from_array([2; 32]);
        assert!(params(auth).validate(&admin).is_ok());
        assert!(params(admin).validate(&admin).is_err(), "root authority == admin");
        assert!(params(Pubkey::default()).validate(&admin).is_err());
        let mut p = params(auth);
        p.payout_mode = 2;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.max_proof_len = 33;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.max_proof_len = 0;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.push_min_usd_micros = 999_999;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.max_price_age_seconds = 601;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.root_delay_seconds = MAX_ROOT_DELAY_SECONDS + 1;
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.root_delay_seconds = MIN_ROOT_DELAY_SECONDS - 1;
        assert!(p.validate(&admin).is_err(), "root delay below 12 h");
        assert_eq!(MIN_ROOT_DELAY_SECONDS, 43_200);
        let mut p = params(auth);
        p.guardian = Pubkey::default();
        assert!(p.validate(&admin).is_err(), "no guardian");
        let mut p = params(auth);
        p.guardian = auth;
        assert!(p.validate(&admin).is_err(), "guardian == root authority");
        let mut p = params(auth);
        p.guardian = admin;
        assert!(p.validate(&admin).is_ok(), "the admin may also be the guardian");
        let mut p = params(auth);
        p.stray_recipient = Pubkey::default();
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.stable_mints = vec![NATIVE_MINT];
        assert!(p.validate(&admin).is_err());
        let mut p = params(auth);
        p.stable_mints = vec![Pubkey::new_from_array([7; 32]); 2];
        assert!(p.validate(&admin).is_err(), "duplicate stable mint");
        let mut p = params(auth);
        p.stable_mints = (0..5).map(|i| Pubkey::new_from_array([10 + i; 32])).collect();
        assert!(p.validate(&admin).is_err(), "too many stable mints");
    }

    #[test]
    fn config_apply_and_stable_lookup() {
        let mut c = RewardsConfig {
            version: 1,
            bump: 0,
            admin: Pubkey::default(),
            pending_admin: Pubkey::default(),
            root_authority: Pubkey::default(),
            payout_mode: 0,
            paused: false,
            root_delay_seconds: 0,
            max_proof_len: 0,
            push_min_usd_micros: 0,
            min_holding_usd_micros: 0,
            max_price_age_seconds: 0,
            sol_usd_price_update: Pubkey::default(),
            stable_count: 0,
            stable_mints: [Pubkey::default(); MAX_STABLE_MINTS],
            stray_recipient: Pubkey::default(),
            guardian: Pubkey::default(),
            reserved: [0; 32],
        };
        let admin = Pubkey::new_from_array([1; 32]);
        c.admin = admin;
        assert!(c.is_admin_or_guardian(&admin));
        assert!(
            !c.is_admin_or_guardian(&Pubkey::default()),
            "an unset guardian matches nobody"
        );
        let p = params(Pubkey::new_from_array([2; 32]));
        c.apply(&p);
        assert_eq!(c.guardian, Pubkey::new_from_array([9; 32]));
        assert!(c.is_admin_or_guardian(&Pubkey::new_from_array([9; 32])));
        assert!(!c.is_admin_or_guardian(&Pubkey::new_from_array([2; 32])));
        assert!(c.is_stable(&Pubkey::new_from_array([7; 32])));
        assert!(!c.is_stable(&Pubkey::default()), "unused slots never match");
        assert_eq!(c.stable_count, 1);
    }

    #[test]
    fn available_sol_vs_token() {
        let mut d = Distributor {
            version: 1,
            bump: 0,
            vault_bump: 0,
            mint: Pubkey::default(),
            reward_mint: NATIVE_MINT,
            reward_token_program: token::ID,
            reward_decimals: 9,
            holder_vault: Pubkey::default(),
            token_vault: Pubkey::default(),
            vault_reserve: 890_880,
            round: 0,
            root: [0; 32],
            max_total_claim: 0,
            total_claimed: 0,
            snapshot_slot: 0,
            data_hash: [0; 32],
            activated_at: 0,
            has_pending: false,
            pending_root: [0; 32],
            pending_max_total_claim: 0,
            pending_snapshot_slot: 0,
            pending_data_hash: [0; 32],
            pending_eta: 0,
            created_by: Pubkey::default(),
            reserved: [0; 64],
        };
        assert_eq!(available_of(&d, 1_890_880, 55), 1_000_000);
        assert_eq!(available_of(&d, 100, 55), 0);
        d.reward_mint = Pubkey::new_from_array([3; 32]);
        assert_eq!(available_of(&d, 1_890_880, 55), 55);
    }

    #[test]
    fn account_sizes() {
        // pinned so the SDK decoders (packages/sdk/src/rewards.ts) stay in sync
        assert_eq!(8 + RewardsConfig::INIT_SPACE, 8 + 2 + 32 * 3 + 2 + 4 + 1 + 8 + 8 + 4 + 32 + 1 + 32 * 4 + 32 + 64);
        assert_eq!(
            8 + PendingRewardsConfig::INIT_SPACE,
            8 + 1 + 1 + 8 + 8 + (32 + 1 + 4 + 1 + 8 + 8 + 4 + 32 + (4 + 32 * 4) + 32 + 32)
        );
        assert_eq!(8 + PendingRewardsConfig::INIT_SPACE, PENDING_CONFIG_V2_SIZE);
        assert_eq!(
            PENDING_CONFIG_V1_SIZE,
            8 + 1 + 1 + 8 + 8 + (32 + 1 + 4 + 1 + 8 + 8 + 4 + 32 + (4 + 32 * 4) + 32)
        );
        assert_eq!(
            8 + Distributor::INIT_SPACE,
            8 + 3 + 32 * 3 + 1 + 32 * 2 + 8 + 4 + 32 + 8 + 8 + 8 + 32 + 8 + 1 + 32 + 8 + 8 + 32 + 8 + 32 + 64
        );
        assert_eq!(8 + ClaimStatus::INIT_SPACE, 8 + 2 + 32 * 3 + 8 + 8);
    }

    /// The guardian takes 32 of the reserved bytes: a RewardsConfig written before it existed
    /// still deserializes, with no guardian, and every other field where it was.
    #[test]
    fn guardian_is_carved_from_the_reserved_bytes() {
        let c = RewardsConfig {
            version: 1,
            bump: 2,
            admin: Pubkey::new_from_array([1; 32]),
            pending_admin: Pubkey::default(),
            root_authority: Pubkey::new_from_array([2; 32]),
            payout_mode: 1,
            paused: true,
            root_delay_seconds: 3600,
            max_proof_len: 24,
            push_min_usd_micros: 5,
            min_holding_usd_micros: 6,
            max_price_age_seconds: 7,
            sol_usd_price_update: Pubkey::new_from_array([3; 32]),
            stable_count: 1,
            stable_mints: [Pubkey::new_from_array([4; 32]); MAX_STABLE_MINTS],
            stray_recipient: Pubkey::new_from_array([5; 32]),
            guardian: Pubkey::new_from_array([6; 32]),
            reserved: [0; 32],
        };
        let mut data = Vec::new();
        c.try_serialize(&mut data).unwrap();
        assert_eq!(data.len(), 8 + RewardsConfig::INIT_SPACE);
        let at = data.len() - 64;
        assert_eq!(&data[at..at + 32], &[6u8; 32]);
        assert_eq!(&data[at - 32..at], &[5u8; 32], "stray recipient right before");
        // the old layout: 64 reserved zero bytes
        data[at..].fill(0);
        let old = RewardsConfig::try_deserialize(&mut &data[..]).unwrap();
        assert_eq!(old.guardian, Pubkey::default());
        assert_eq!(old.stray_recipient, c.stray_recipient);
        assert_eq!(old.root_delay_seconds, 3600);
        assert!(old.is_admin_or_guardian(&c.admin));
        assert!(!old.is_admin_or_guardian(&Pubkey::default()));
    }

    /// `migrate_config` re-writes a queued change from the old params layout: every field
    /// survives, the guardian is unset, and such params no longer validate.
    #[test]
    fn old_pending_params_convert_without_a_guardian() {
        let auth = Pubkey::new_from_array([2; 32]);
        let new = params(auth);
        let old = RewardsConfigParamsV1 {
            root_authority: new.root_authority,
            payout_mode: new.payout_mode,
            root_delay_seconds: new.root_delay_seconds,
            max_proof_len: new.max_proof_len,
            push_min_usd_micros: new.push_min_usd_micros,
            min_holding_usd_micros: new.min_holding_usd_micros,
            max_price_age_seconds: new.max_price_age_seconds,
            sol_usd_price_update: new.sol_usd_price_update,
            stable_mints: new.stable_mints.clone(),
            stray_recipient: new.stray_recipient,
        };
        // the old serialization is a prefix of the new one
        let mut a = Vec::new();
        old.serialize(&mut a).unwrap();
        let mut b = Vec::new();
        new.serialize(&mut b).unwrap();
        assert_eq!(b.len(), a.len() + 32);
        assert_eq!(&b[..a.len()], &a[..]);
        let converted = old.with_guardian(Pubkey::default());
        assert_eq!(
            RewardsConfigParams {
                guardian: Pubkey::default(),
                ..new
            },
            converted
        );
        assert!(converted.validate(&Pubkey::new_from_array([1; 32])).is_err());
    }
}
