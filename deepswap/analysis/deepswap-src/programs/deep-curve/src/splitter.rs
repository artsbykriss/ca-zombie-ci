//! DEEP V1 fee splitter (Phase 1, docs/V1_FEES.md section 1.1).
//!
//! Every lamport of DEEP revenue lands in ONE program-owned vault, `fee_vault` (a system-owned,
//! data-less PDA ["fee_vault"] of this program, so it can sign system transfers):
//! curve protocol fees and launch fees (`sweep_protocol_fees`), the migration-fee remainder and
//! the swept fees at graduation (`graduate`), DEEP's DeepSwap protocol fees (deep-amm
//! `collect_protocol_fee_to_vault`, into the vault's WSOL ATA) and the DeepSwap create-pool fee
//! (deep-amm's build-time receiver is the vault's WSOL ATA).
//!
//! `distribute` (PERMISSIONLESS) pays, out of every lamport that reached the vault:
//! * the builder (`BUILDER_WALLET`, build-time) exactly `BUILDER_SPLIT_BPS` / 10_000 = 10% over
//!   time, never more: `builder_due = floor(base_total * 1000 / 10000) - builder_paid_total`
//!   (cumulative floor, so rounding never accumulates in anyone's favour); no setter, no delay;
//! * the remaining 90% to up to `MAX_DESTINATIONS` wallets by bps (summing to 10_000 of the
//!   remainder), configured by the admin through a timelock (`queue_splitter_update` /
//!   `apply_splitter_update`, delay = `Config.timelock_seconds`).
//!
//! Rounding dust of the 90% split is `retained` in the vault and added to the next round's
//! 90% pool (it is NOT counted as new revenue again, so the builder never earns twice on it).
//! A destination that would stay below rent exemption is credited to its `owed` instead of
//! failing the whole distribution; `owed` is paid as soon as it can be. The same holds for the
//! builder wallet (`builder_owed`), also when it is not a plain system account.
use crate::{
    Config, DeepError, CONFIG_SEED, PENDING_CONFIG_SEED, POOL_CREATOR_SEED, TREASURY_SEED,
};
use anchor_lang::prelude::*;
use anchor_lang::system_program;
use anchor_spl::associated_token::{get_associated_token_address, AssociatedToken};
use anchor_spl::token::{self, Mint, Token, TokenAccount};
use anchor_spl::token_interface;

pub const FEE_VAULT_SEED: &[u8] = b"fee_vault";
pub const SPLITTER_SEED: &[u8] = b"splitter";
pub const PENDING_SPLITTER_SEED: &[u8] = b"pending_splitter";
/// Temporary WSOL account `distribute` creates and closes in the same instruction to unwrap
/// the vault's WSOL into lamports (the vault's ATA itself is never closed).
pub const WSOL_UNWRAP_SEED: &[u8] = b"wsol_unwrap";

/// The builder's share of all DEEP revenue, in bps of 10_000. Compiled in: no setter.
pub const BUILDER_SPLIT_BPS: u16 = 1_000;
pub const SPLIT_BPS_DENOMINATOR: u16 = 10_000;
pub const MAX_DESTINATIONS: usize = 8;
/// Default minimum new revenue per `distribute` (0.01 SOL).
pub const DEFAULT_MIN_DISTRIBUTE_LAMPORTS: u64 = 10_000_000;
/// Hard cap on `min_distribute_lamports` (10 SOL): the admin cannot hold back the builder's
/// (and everyone's) payouts by setting an unreachable minimum.
pub const MAX_MIN_DISTRIBUTE_LAMPORTS: u64 = 10_000_000_000;
const SPL_TOKEN_ACCOUNT_LEN: u64 = 165;

/// The build-time builder wallet (same key as deep-amm's `deep_keys::BUILDER`).
use crate::BUILDER_WALLET;

// ───────────────────────────── pure maths ─────────────────────────────

/// Result of splitting one round (`split_round`). Amounts in lamports.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SplitRound {
    /// Paid to the builder this round.
    pub builder: u64,
    /// The 90% pool of this round: `revenue - builder + retained_in`.
    pub pool: u64,
    /// Share of each destination, `floor(pool * bps / 10_000)`, config order.
    pub shares: Vec<u64>,
    /// Dust kept in the vault for the next round: `pool - sum(shares)`.
    pub retained: u64,
    pub base_total: u128,
    pub builder_paid_total: u64,
}

/// One round of the splitter on `revenue` NEW lamports (never counted before).
/// `retained_in` is the dust carried from the previous round (already counted in `base_total`).
/// The builder's cumulative pay is `floor(base_total * 1000 / 10000)`: exact over time, and
/// never more than 10% of everything that reached the vault.
pub fn split_round(
    revenue: u64,
    retained_in: u64,
    base_total: u128,
    builder_paid_total: u64,
    bps: &[u16],
) -> Option<SplitRound> {
    let base_total = base_total.checked_add(revenue as u128)?;
    let due_total =
        base_total.checked_mul(BUILDER_SPLIT_BPS as u128)? / SPLIT_BPS_DENOMINATOR as u128;
    let due_total = u64::try_from(due_total).ok()?;
    let builder = due_total.checked_sub(builder_paid_total)?;
    let pool = revenue.checked_sub(builder)?.checked_add(retained_in)?;
    let mut shares = Vec::with_capacity(bps.len());
    let mut paid = 0u64;
    for b in bps {
        let s = (pool as u128).checked_mul(*b as u128)? / SPLIT_BPS_DENOMINATOR as u128;
        let s = u64::try_from(s).ok()?;
        paid = paid.checked_add(s)?;
        shares.push(s);
    }
    Some(SplitRound {
        builder,
        pool,
        retained: pool.checked_sub(paid)?,
        shares,
        base_total,
        builder_paid_total: due_total,
    })
}

// ───────────────────────────── state ─────────────────────────────

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, Default, InitSpace, Debug, PartialEq)]
pub struct Destination {
    pub wallet: Pubkey,
    /// Share of the 90% remainder, bps of 10_000.
    pub bps: u16,
    /// Lamports due but not yet paid (the wallet would have stayed below rent exemption).
    pub owed: u64,
    /// Lamports paid to this wallet since it was added.
    pub paid_total: u64,
}

#[account]
#[derive(InitSpace)]
pub struct SplitterConfig {
    pub bump: u8,
    pub vault_bump: u8,
    /// Number of configured destinations (1..=8); `destinations[count..]` are zero.
    pub count: u8,
    pub destinations: [Destination; 8],
    /// Every lamport of revenue that has entered the split, ever.
    pub base_total: u128,
    /// Every lamport credited to the builder, ever (= floor(base_total / 10)); of it,
    /// `builder_owed` may still be waiting to be transferred.
    pub builder_paid_total: u64,
    /// Rounding dust of the 90% split, kept in the vault for the next round.
    pub retained: u64,
    /// Minimum NEW revenue for a `distribute` (default 0.01 SOL, at most 10 SOL).
    pub min_distribute_lamports: u64,
    pub distributions: u64,
    pub last_distribute_at: i64,
    /// Lamports paid to the 90% destinations, ever (removed destinations included).
    pub destinations_paid_total: u64,
    /// Builder pay that is due (counted in `builder_paid_total`) but not yet transferred,
    /// because the builder wallet would have stayed below rent exemption. Paid first on the
    /// next `distribute` that can; never lost and never re-split.
    pub builder_owed: u64,
    pub padding: [u8; 56],
}

impl SplitterConfig {
    pub fn active(&self) -> &[Destination] {
        &self.destinations[..self.count as usize]
    }

    pub fn owed_total(&self) -> Option<u64> {
        self.active()
            .iter()
            .try_fold(0u64, |acc, d| acc.checked_add(d.owed))
    }

    /// Applies validated `params`: destinations that stay keep their `owed` and `paid_total`.
    /// A removed destination's unpaid `owed` (it could not receive: below rent exemption or an
    /// executable account) is not stranded: it moves to `retained` and is split among the new
    /// destinations on the next `distribute`, so every lamport still has a payout path.
    fn apply(&mut self, p: &SplitterParams) -> Result<()> {
        let mut next = [Destination::default(); MAX_DESTINATIONS];
        for (i, d) in p.destinations.iter().enumerate() {
            let prev = self.active().iter().find(|o| o.wallet == d.wallet);
            next[i] = Destination {
                wallet: d.wallet,
                bps: d.bps,
                owed: prev.map(|o| o.owed).unwrap_or(0),
                paid_total: prev.map(|o| o.paid_total).unwrap_or(0),
            };
        }
        let mut orphaned = 0u64;
        for old in self.active() {
            if !p.destinations.iter().any(|d| d.wallet == old.wallet) {
                orphaned = orphaned.checked_add(old.owed).ok_or(DeepError::Overflow)?;
            }
        }
        self.retained = self
            .retained
            .checked_add(orphaned)
            .ok_or(DeepError::Overflow)?;
        self.destinations = next;
        self.count = p.destinations.len() as u8;
        self.min_distribute_lamports = p.min_distribute_lamports;
        Ok(())
    }
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, InitSpace, Debug, PartialEq)]
pub struct DestinationParams {
    pub wallet: Pubkey,
    pub bps: u16,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, InitSpace, Debug, PartialEq)]
pub struct SplitterParams {
    #[max_len(8)]
    pub destinations: Vec<DestinationParams>,
    pub min_distribute_lamports: u64,
}

impl SplitterParams {
    pub fn validate(&self, program_id: &Pubkey) -> Result<()> {
        let n = self.destinations.len();
        require!(
            (1..=MAX_DESTINATIONS).contains(&n),
            DeepError::InvalidSplitterParams
        );
        require!(
            self.min_distribute_lamports > 0
                && self.min_distribute_lamports <= MAX_MIN_DISTRIBUTE_LAMPORTS,
            DeepError::InvalidSplitterParams
        );
        let never = never_a_destination(program_id);
        let mut sum = 0u32;
        for (i, d) in self.destinations.iter().enumerate() {
            require!(d.bps > 0, DeepError::InvalidSplitterParams);
            sum += d.bps as u32;
            require!(
                d.wallet != BUILDER_WALLET && !never.contains(&d.wallet),
                DeepError::InvalidSplitterParams
            );
            require!(
                !self.destinations[..i].iter().any(|o| o.wallet == d.wallet),
                DeepError::InvalidSplitterParams
            );
        }
        require!(
            sum == SPLIT_BPS_DENOMINATOR as u32,
            DeepError::InvalidSplitterParams
        );
        Ok(())
    }
}

/// Addresses that can never be a 90% destination, because nobody could ever sign for what they
/// receive (security review F10): the zero key (also the system program id); this program's
/// own accounts and PDAs (the fee vault and its WSOL account, the splitter config and its
/// pending change, Config and PendingConfig, the temporary unwrap account, the legacy treasury,
/// the graduation pool payer); and the programs and the mint this program works with. A
/// destination set to one of them would swallow its share of all revenue.
pub fn never_a_destination(program_id: &Pubkey) -> Vec<Pubkey> {
    let pda = |seed: &[u8]| Pubkey::find_program_address(&[seed], program_id).0;
    let vault = pda(FEE_VAULT_SEED);
    let wsol = anchor_spl::token::spl_token::native_mint::ID;
    vec![
        Pubkey::default(),
        vault,
        get_associated_token_address(&vault, &wsol),
        pda(SPLITTER_SEED),
        pda(PENDING_SPLITTER_SEED),
        pda(CONFIG_SEED),
        pda(PENDING_CONFIG_SEED),
        pda(WSOL_UNWRAP_SEED),
        pda(TREASURY_SEED),
        pda(POOL_CREATOR_SEED),
        *program_id,
        deep_amm::ID,
        crate::DEEP_REWARDS_PROGRAM_ID,
        token::ID,
        anchor_spl::token_2022::ID,
        anchor_spl::associated_token::ID,
        wsol,
    ]
}

/// The single queued splitter change (same timelock rules as `PendingConfig`).
#[account]
#[derive(InitSpace)]
pub struct PendingSplitterUpdate {
    pub active: bool,
    pub eta: i64,
    pub queued_at: i64,
    pub params: SplitterParams,
    pub bump: u8,
}

// ─────────────────────────── handlers ───────────────────────────

pub fn initialize_splitter_handler(
    ctx: Context<InitializeSplitter>,
    params: SplitterParams,
) -> Result<()> {
    params.validate(&crate::ID)?;
    // One build, one vault: deep-amm must lock its protocol owner and create-pool fee receiver
    // to THIS vault, or DEEP revenue could bypass the split.
    let vault = ctx.accounts.fee_vault.key();
    require_keys_eq!(
        deep_amm::deep_keys::FEE_VAULT,
        vault,
        DeepError::InvalidFeeVault
    );
    require_keys_eq!(
        crate::raydium::CREATE_POOL_FEE_RECEIVER,
        ctx.accounts.fee_vault_wsol.key(),
        DeepError::InvalidFeeVault
    );
    // The vault must always hold its 0-byte rent minimum (read at runtime, never hard-coded).
    let rent_min = Rent::get()?.minimum_balance(0);
    let top_up = rent_min.saturating_sub(ctx.accounts.fee_vault.lamports());
    if top_up > 0 {
        system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.key(),
                system_program::Transfer {
                    from: ctx.accounts.admin.to_account_info(),
                    to: ctx.accounts.fee_vault.to_account_info(),
                },
            ),
            top_up,
        )?;
    }
    let s = &mut ctx.accounts.splitter;
    s.bump = ctx.bumps.splitter;
    s.vault_bump = ctx.bumps.fee_vault;
    s.apply(&params)?;
    emit_updated(s);
    Ok(())
}

pub fn queue_splitter_update_handler(
    ctx: Context<QueueSplitterUpdate>,
    params: SplitterParams,
) -> Result<()> {
    params.validate(&crate::ID)?;
    let pending = &mut ctx.accounts.pending_splitter;
    require!(!pending.active, DeepError::SplitterUpdatePending);
    let now = Clock::get()?.unix_timestamp;
    let eta = now
        .checked_add(ctx.accounts.config.timelock_seconds as i64)
        .ok_or(DeepError::Overflow)?;
    pending.active = true;
    pending.eta = eta;
    pending.queued_at = now;
    pending.params = params.clone();
    pending.bump = ctx.bumps.pending_splitter;
    emit!(SplitterUpdateQueued {
        eta,
        queued_at: now,
        params,
    });
    Ok(())
}

pub fn apply_splitter_update_handler(ctx: Context<ApplySplitterUpdate>) -> Result<()> {
    let pending = &mut ctx.accounts.pending_splitter;
    require!(pending.active, DeepError::NoPendingSplitterUpdate);
    let now = Clock::get()?.unix_timestamp;
    require!(now >= pending.eta, DeepError::TimelockNotElapsed);
    require!(
        now <= pending
            .eta
            .saturating_add(crate::CONFIG_UPDATE_GRACE_SECONDS),
        DeepError::ConfigUpdateExpired
    );
    let params = pending.params.clone();
    params.validate(&crate::ID)?;
    pending.active = false;
    let s = &mut ctx.accounts.splitter;
    s.apply(&params)?;
    emit_updated(s);
    Ok(())
}

pub fn cancel_splitter_update_handler(ctx: Context<CancelSplitterUpdate>) -> Result<()> {
    let pending = &mut ctx.accounts.pending_splitter;
    require!(pending.active, DeepError::NoPendingSplitterUpdate);
    pending.active = false;
    emit!(SplitterUpdateCancelled { eta: pending.eta });
    Ok(())
}

fn emit_updated(s: &SplitterConfig) {
    emit!(SplitterUpdated {
        wallets: s.active().iter().map(|d| d.wallet).collect(),
        bps: s.active().iter().map(|d| d.bps).collect(),
        min_distribute_lamports: s.min_distribute_lamports,
    });
}

pub fn distribute_handler<'info>(ctx: Context<'info, Distribute<'info>>) -> Result<()> {
    let a = &ctx.accounts;
    let vault_bump = [a.splitter.vault_bump];
    let vault_seeds: &[&[u8]] = &[FEE_VAULT_SEED, &vault_bump];

    // 1. Unwrap the vault's WSOL (DeepSwap protocol fees, create-pool fees) into lamports.
    let wsol_amount = {
        let data = a.fee_vault_wsol.try_borrow_data()?;
        TokenAccount::try_deserialize(&mut &data[..])?.amount
    };
    if wsol_amount > 0 {
        unwrap_vault_wsol(a, wsol_amount, vault_seeds, ctx.bumps.wsol_unwrap)?;
    }

    // 2. New revenue = vault balance above rent, owed payouts and carried dust.
    let rent = Rent::get()?;
    let vault_rent = rent.minimum_balance(0);
    let s = &a.splitter;
    let owed_total = s.owed_total().ok_or(DeepError::Overflow)?;
    let reserved = vault_rent
        .checked_add(owed_total)
        .and_then(|v| v.checked_add(s.retained))
        .and_then(|v| v.checked_add(s.builder_owed))
        .ok_or(DeepError::Overflow)?;
    let available = a
        .fee_vault
        .lamports()
        .checked_sub(reserved)
        .ok_or(DeepError::Overflow)?;
    // Below the minimum, a call still pays out anything owed (so owed lamports never wait on
    // new revenue); the small new revenue stays in the vault for a later round.
    let outstanding = owed_total > 0 || s.builder_owed > 0;
    let revenue = if available >= s.min_distribute_lamports {
        available
    } else {
        require!(outstanding, DeepError::BelowMinDistribute);
        0
    };

    // Check every recipient before moving anything: right key, in config order, writable.
    let retained_in = s.retained;
    let count = s.count as usize;
    require!(
        ctx.remaining_accounts.len() == count,
        DeepError::InvalidDestination
    );
    for (i, info) in ctx.remaining_accounts.iter().enumerate() {
        require_keys_eq!(
            info.key(),
            s.destinations[i].wallet,
            DeepError::InvalidDestination
        );
        require!(info.is_writable, DeepError::InvalidDestination);
    }

    // 3./4. Builder exact over time, then the 90% by bps.
    let bps: Vec<u16> = s.active().iter().map(|d| d.bps).collect();
    let round = split_round(
        revenue,
        s.retained,
        s.base_total,
        s.builder_paid_total,
        &bps,
    )
    .ok_or(DeepError::Overflow)?;

    let pay = |to: &AccountInfo<'info>, amount: u64| -> Result<()> {
        system_program::transfer(
            CpiContext::new_with_signer(
                a.system_program.key(),
                system_program::Transfer {
                    from: a.fee_vault.to_account_info(),
                    to: to.clone(),
                },
                &[vault_seeds],
            ),
            amount,
        )
    };

    // A recipient that cannot take a system transfer right now (it would stay below rent
    // exemption, or is executable) is credited to its `owed` instead, so one bad wallet never
    // fails the distribution or strands anyone else's share.
    let payable = |info: &AccountInfo, amount: u64| {
        amount > 0
            && !info.executable
            && info.lamports().saturating_add(amount) >= rent.minimum_balance(info.data_len())
    };

    // The builder is paid only while its address is a plain system account, as before; if it
    // is ever owned by another program, its share accrues to `builder_owed` like any other
    // unpayable case instead of failing account validation and with it every distribution
    // (security review F7). It is paid in full once the address is a system account again.
    let builder_info = a.builder.to_account_info();
    let builder_due = a
        .splitter
        .builder_owed
        .checked_add(round.builder)
        .ok_or(DeepError::Overflow)?;
    let builder_payable =
        builder_info.owner == &system_program::ID && payable(&builder_info, builder_due);
    let (builder_paid, builder_owed) = if builder_payable {
        pay(&builder_info, builder_due)?;
        (builder_due, 0)
    } else {
        (0, builder_due)
    };

    let mut wallets = Vec::with_capacity(count);
    let mut amounts = Vec::with_capacity(count);
    let mut owed = Vec::with_capacity(count);
    let mut next = a.splitter.destinations;
    let mut paid_round = 0u64;
    for (i, info) in ctx.remaining_accounts.iter().enumerate() {
        let d = &mut next[i];
        let due = d
            .owed
            .checked_add(round.shares[i])
            .ok_or(DeepError::Overflow)?;
        let mut paid = 0;
        if payable(info, due) {
            pay(info, due)?;
            paid = due;
            d.owed = 0;
            d.paid_total = d.paid_total.checked_add(due).ok_or(DeepError::Overflow)?;
            paid_round = paid_round.checked_add(due).ok_or(DeepError::Overflow)?;
        } else {
            d.owed = due;
        }
        wallets.push(d.wallet);
        amounts.push(paid);
        owed.push(d.owed);
    }

    let now = Clock::get()?.unix_timestamp;
    let s = &mut ctx.accounts.splitter;
    s.destinations = next;
    s.base_total = round.base_total;
    s.builder_paid_total = round.builder_paid_total;
    s.builder_owed = builder_owed;
    s.retained = round.retained;
    s.distributions = s.distributions.checked_add(1).ok_or(DeepError::Overflow)?;
    s.last_distribute_at = now;
    s.destinations_paid_total = s
        .destinations_paid_total
        .checked_add(paid_round)
        .ok_or(DeepError::Overflow)?;

    emit!(RevenueDistributed {
        base: revenue,
        retained_in,
        builder_amount: builder_paid,
        builder_owed,
        builder_paid_total: s.builder_paid_total,
        base_total: s.base_total,
        wallets,
        amounts,
        owed,
        retained: s.retained,
        wsol_unwrapped: wsol_amount,
        timestamp: now,
    });
    Ok(())
}

/// Moves `amount` WSOL from the vault's ATA into lamports of the vault, through a temporary
/// WSOL account (["wsol_unwrap"]) created, filled and closed here. The vault's ATA is never
/// closed (deep-amm needs it to exist). The transaction's `payer` fronts the temporary
/// account's rent and is refunded exactly that from the vault once the account is closed into
/// it (security review F6): the vault itself never has to hold spare lamports, so revenue that
/// waits only as WSOL can always be distributed, also with the vault at its rent minimum.
fn unwrap_vault_wsol<'info>(
    a: &Distribute<'info>,
    amount: u64,
    vault_seeds: &[&[u8]],
    unwrap_bump: u8,
) -> Result<()> {
    let tmp = a.wsol_unwrap.to_account_info();
    let vault = a.fee_vault.to_account_info();
    let payer = a.payer.to_account_info();
    let sys = a.system_program.key();
    let unwrap_bump = [unwrap_bump];
    let tmp_seeds: &[&[u8]] = &[WSOL_UNWRAP_SEED, &unwrap_bump];
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
        // Someone pre-funded the address (griefing): top up, allocate and assign instead, as
        // Anchor's `init` does. The extra lamports end up in the vault as revenue; the payer
        // is refunded only what it fronted.
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
                from: a.fee_vault_wsol.to_account_info(),
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
    // The closed account's lamports (the fronted rent, the unwrapped WSOL, anything pre-funded)
    // are in the vault now: give the payer back exactly what it fronted.
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
    Ok(())
}

pub fn withdraw_vault_tokens_handler(ctx: Context<WithdrawVaultTokens>, amount: u64) -> Result<()> {
    require!(amount > 0, DeepError::ZeroAmount);
    let bump = [ctx.accounts.splitter.vault_bump];
    let seeds: &[&[u8]] = &[FEE_VAULT_SEED, &bump];
    token_interface::transfer_checked(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            token_interface::TransferChecked {
                from: ctx.accounts.vault_token.to_account_info(),
                mint: ctx.accounts.mint.to_account_info(),
                to: ctx.accounts.recipient_token.to_account_info(),
                authority: ctx.accounts.fee_vault.to_account_info(),
            },
            &[seeds],
        ),
        amount,
        ctx.accounts.mint.decimals,
    )?;
    emit!(VaultTokensWithdrawn {
        mint: ctx.accounts.mint.key(),
        recipient: ctx.accounts.recipient_token.key(),
        amount,
    });
    Ok(())
}

// ─────────────────────────── accounts ───────────────────────────

#[derive(Accounts)]
pub struct InitializeSplitter<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Box<Account<'info, Config>>,
    #[account(
        init,
        payer = admin,
        space = 8 + SplitterConfig::INIT_SPACE,
        seeds = [SPLITTER_SEED],
        bump,
    )]
    pub splitter: Box<Account<'info, SplitterConfig>>,
    #[account(mut, seeds = [FEE_VAULT_SEED], bump)]
    pub fee_vault: SystemAccount<'info>,
    #[account(
        init_if_needed,
        payer = admin,
        associated_token::mint = wsol_mint,
        associated_token::authority = fee_vault,
    )]
    pub fee_vault_wsol: Box<Account<'info, TokenAccount>>,
    #[account(address = anchor_spl::token::spl_token::native_mint::ID @ DeepError::InvalidParams)]
    pub wsol_mint: Box<Account<'info, Mint>>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct QueueSplitterUpdate<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Box<Account<'info, Config>>,
    #[account(seeds = [SPLITTER_SEED], bump = splitter.bump)]
    pub splitter: Box<Account<'info, SplitterConfig>>,
    #[account(
        init_if_needed,
        payer = admin,
        space = 8 + PendingSplitterUpdate::INIT_SPACE,
        seeds = [PENDING_SPLITTER_SEED],
        bump,
    )]
    pub pending_splitter: Box<Account<'info, PendingSplitterUpdate>>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ApplySplitterUpdate<'info> {
    #[account(mut, seeds = [SPLITTER_SEED], bump = splitter.bump)]
    pub splitter: Box<Account<'info, SplitterConfig>>,
    #[account(mut, seeds = [PENDING_SPLITTER_SEED], bump = pending_splitter.bump)]
    pub pending_splitter: Box<Account<'info, PendingSplitterUpdate>>,
}

#[derive(Accounts)]
pub struct CancelSplitterUpdate<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Box<Account<'info, Config>>,
    #[account(mut, seeds = [PENDING_SPLITTER_SEED], bump = pending_splitter.bump)]
    pub pending_splitter: Box<Account<'info, PendingSplitterUpdate>>,
}

/// PERMISSIONLESS. `remaining_accounts`: the configured destinations, writable, in config order.
#[derive(Accounts)]
pub struct Distribute<'info> {
    /// Anyone. Fronts the rent of the temporary WSOL-unwrap account when the vault holds WSOL
    /// and gets exactly that back in the same instruction; pays nothing else and receives
    /// nothing else.
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(mut, seeds = [SPLITTER_SEED], bump = splitter.bump)]
    pub splitter: Box<Account<'info, SplitterConfig>>,
    #[account(mut, seeds = [FEE_VAULT_SEED], bump = splitter.vault_bump)]
    pub fee_vault: SystemAccount<'info>,
    /// CHECK: ATA(WSOL, fee_vault) (address checked); read as a token account in the handler.
    #[account(
        mut,
        address = get_associated_token_address(&fee_vault.key(), &wsol_mint.key()) @ DeepError::InvalidFeeVault,
        owner = token::ID @ DeepError::InvalidFeeVault,
    )]
    pub fee_vault_wsol: UncheckedAccount<'info>,
    /// CHECK: temporary unwrap account, created and closed inside the instruction.
    #[account(mut, seeds = [WSOL_UNWRAP_SEED], bump)]
    pub wsol_unwrap: UncheckedAccount<'info>,
    #[account(address = anchor_spl::token::spl_token::native_mint::ID @ DeepError::InvalidParams)]
    pub wsol_mint: Box<Account<'info, Mint>>,
    /// CHECK: the build-time builder wallet (address checked). Expected to be a plain system
    /// account (e.g. a Squads vault PDA); the handler pays it only while it is one and
    /// otherwise books its share as `builder_owed`.
    #[account(mut, address = BUILDER_WALLET @ DeepError::InvalidBuilder)]
    pub builder: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct WithdrawVaultTokens<'info> {
    pub admin: Signer<'info>,
    #[account(seeds = [CONFIG_SEED], bump = config.bump, has_one = admin @ DeepError::Unauthorized)]
    pub config: Box<Account<'info, Config>>,
    #[account(seeds = [SPLITTER_SEED], bump = splitter.bump)]
    pub splitter: Box<Account<'info, SplitterConfig>>,
    #[account(seeds = [FEE_VAULT_SEED], bump = splitter.vault_bump)]
    pub fee_vault: SystemAccount<'info>,
    /// Any SPL Token or Token-2022 mint except WSOL (WSOL is revenue and only leaves through
    /// `distribute`).
    #[account(
        mint::token_program = token_program,
        constraint = mint.key() != anchor_spl::token::spl_token::native_mint::ID @ DeepError::InvalidVaultToken,
    )]
    pub mint: Box<InterfaceAccount<'info, token_interface::Mint>>,
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = fee_vault,
        associated_token::token_program = token_program,
    )]
    pub vault_token: Box<InterfaceAccount<'info, token_interface::TokenAccount>>,
    #[account(
        mut,
        token::mint = mint,
        token::token_program = token_program,
        constraint = recipient_token.owner == config.fee_recipient @ DeepError::InvalidFeeRecipient,
    )]
    pub recipient_token: Box<InterfaceAccount<'info, token_interface::TokenAccount>>,
    pub token_program: Interface<'info, token_interface::TokenInterface>,
}

// ──────────────────────────── events ────────────────────────────

#[event]
pub struct SplitterUpdated {
    pub wallets: Vec<Pubkey>,
    pub bps: Vec<u16>,
    pub min_distribute_lamports: u64,
}

#[event]
pub struct SplitterUpdateQueued {
    pub eta: i64,
    pub queued_at: i64,
    pub params: SplitterParams,
}

#[event]
pub struct SplitterUpdateCancelled {
    pub eta: i64,
}

/// One `distribute`. `base` is the NEW revenue of this round; `amounts[i]` is what wallet `i`
/// received (its share plus any previously owed lamports), `owed[i]` what it is still owed.
#[event]
pub struct RevenueDistributed {
    pub base: u64,
    pub retained_in: u64,
    pub builder_amount: u64,
    /// Builder pay still due (the wallet could not receive yet); paid on a later round.
    pub builder_owed: u64,
    pub builder_paid_total: u64,
    pub base_total: u128,
    pub wallets: Vec<Pubkey>,
    pub amounts: Vec<u64>,
    pub owed: Vec<u64>,
    pub retained: u64,
    pub wsol_unwrapped: u64,
    pub timestamp: i64,
}

#[event]
pub struct VaultTokensWithdrawn {
    pub mint: Pubkey,
    pub recipient: Pubkey,
    pub amount: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builder_is_exactly_ten_percent_over_time_never_more() {
        let bps = [6_000u16, 3_000, 1_000];
        let (mut base, mut paid, mut retained) = (0u128, 0u64, 0u64);
        let mut builder_sum = 0u64;
        let mut dest_sum = 0u64;
        let mut revenue_sum = 0u64;
        for i in 1..5_000u64 {
            let rev = (i * 7_919) % 1_013 + 1; // dust-sized, never a multiple of 10
            let r = split_round(rev, retained, base, paid, &bps).unwrap();
            builder_sum += r.builder;
            dest_sum += r.shares.iter().sum::<u64>();
            revenue_sum += rev;
            base = r.base_total;
            paid = r.builder_paid_total;
            retained = r.retained;
            assert_eq!(builder_sum, (revenue_sum / 10));
            assert_eq!(builder_sum + dest_sum + retained, revenue_sum);
            assert!(retained < bps.len() as u64);
        }
    }

    #[test]
    fn worked_example() {
        let r = split_round(12_500_000, 0, 0, 0, &[10_000]).unwrap();
        assert_eq!(r.builder, 1_250_000);
        assert_eq!(r.shares, vec![11_250_000]);
        assert_eq!(r.retained, 0);
    }
}
