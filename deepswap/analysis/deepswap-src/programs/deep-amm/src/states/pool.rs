use crate::states::creator_fee_share::split_creator_fee_shared_amount;
use crate::{curve::TradeDirection, error::ErrorCode};
use anchor_lang::prelude::*;
use anchor_spl::token_interface::Mint;
use std::ops::{BitAnd, BitOr, BitXor};
/// Seed to derive account address and signature
pub const POOL_SEED: &str = "pool";
pub const POOL_LP_MINT_SEED: &str = "pool_lp_mint";
pub const POOL_VAULT_SEED: &str = "pool_vault";

pub const Q32: u128 = (u32::MAX as u128) + 1; // 2^32

pub enum PoolStatusBitIndex {
    Deposit,
    Withdraw,
    Swap,
}

#[derive(PartialEq, Eq)]
pub enum PoolStatusBitFlag {
    Enable,
    Disable,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq, Eq)]
pub enum CreatorFeeOn {
    /// Both token0 and token1 can be used as trade fees.
    /// It depends on what the input token is.
    BothToken,
    /// Only token0 can be used as trade fees.
    OnlyToken0,
    /// Only token1 can be used as trade fees.
    OnlyToken1,
}

impl CreatorFeeOn {
    fn from_u8(value: u8) -> Result<Self> {
        match value {
            0 => Ok(CreatorFeeOn::BothToken),
            1 => Ok(CreatorFeeOn::OnlyToken0),
            2 => Ok(CreatorFeeOn::OnlyToken1),
            _ => Err(ErrorCode::InvalidFeeModel.into()),
        }
    }

    pub fn to_u8(&self) -> u8 {
        match self {
            CreatorFeeOn::BothToken => 0u8,
            CreatorFeeOn::OnlyToken0 => 1u8,
            CreatorFeeOn::OnlyToken1 => 2u8,
        }
    }
}

pub struct SwapParams {
    pub trade_direction: TradeDirection,
    pub total_input_token_amount: u64,
    pub total_output_token_amount: u64,
    pub token_0_price_x64: u128,
    pub token_1_price_x64: u128,
    pub is_creator_fee_on_input: bool,
}

#[account(zero_copy(unsafe))]
#[repr(C, packed)]
#[derive(Default, Debug)]
pub struct PoolState {
    /// Which config the pool belongs
    pub amm_config: Pubkey,
    /// pool creator
    pub pool_creator: Pubkey,
    /// Token A
    pub token_0_vault: Pubkey,
    /// Token B
    pub token_1_vault: Pubkey,

    /// Pool tokens are issued when A or B tokens are deposited.
    /// Pool tokens can be withdrawn back to the original A or B token.
    pub lp_mint: Pubkey,
    /// Mint information for token A
    pub token_0_mint: Pubkey,
    /// Mint information for token B
    pub token_1_mint: Pubkey,

    /// token_0 program
    pub token_0_program: Pubkey,
    /// token_1 program
    pub token_1_program: Pubkey,

    /// observation account to store oracle data
    pub observation_key: Pubkey,

    pub auth_bump: u8,
    /// Bitwise representation of the state of the pool
    /// bit0, 1: disable deposit(value is 1), 0: normal
    /// bit1, 1: disable withdraw(value is 2), 0: normal
    /// bit2, 1: disable swap(value is 4), 0: normal
    pub status: u8,

    pub lp_mint_decimals: u8,
    /// mint0 and mint1 decimals
    pub mint_0_decimals: u8,
    pub mint_1_decimals: u8,

    /// True circulating supply without burns and lock ups
    pub lp_supply: u64,
    /// The amounts of token_0 and token_1 that are owed to the liquidity provider.
    pub protocol_fees_token_0: u64,
    pub protocol_fees_token_1: u64,

    pub fund_fees_token_0: u64,
    pub fund_fees_token_1: u64,

    /// The timestamp allowed for swap in the pool.
    pub open_time: u64,
    /// recent epoch
    pub recent_epoch: u64,

    /// Creator fee collect mode
    /// 0: both token_0 and token_1 can be used as trade fees. It depends on what the input token is when swapping
    /// 1: only token_0 as trade fee
    /// 2: only token_1 as trade fee
    pub creator_fee_on: u8,
    pub enable_creator_fee: bool,
    pub padding1: [u8; 6],
    pub creator_fees_token_0: u64,
    pub creator_fees_token_1: u64,
    /// DEEP V1: 0 = legacy (upstream fee semantics), 1 = V1 (side-dependent fees taken in the
    /// quote token). Set at creation from the AmmConfig, never changed.
    pub fee_model: u8,
    /// DEEP V1: 0 Standard, 1 Creator, 2 Holder. Set at creation, never changed. The reward
    /// part of the fee accrues in `creator_fees_token_<quote>` for `pool_creator` (the
    /// token's creator, or the token's holder vault).
    pub reward_model: u8,
    pub padding2: [u8; 6],
    /// DEEP V1: the reward rate (per 1e6, each side) this pool charges on top of its
    /// config's LP + DEEP rates: the token's own rate, chosen by its creator at launch and
    /// carried here when the pool is created (deep-curve `graduate`). Never changed. 0 for
    /// Standard.
    pub reward_rate_snapshot: u64,
    /// padding for future updates
    pub padding: [u64; 26],
}

/// `PoolState::reward_model` values (the same numbers as deep-curve `math::REWARD_MODEL_*`).
pub const REWARD_MODEL_STANDARD: u8 = 0;
pub const REWARD_MODEL_CREATOR: u8 = 1;
pub const REWARD_MODEL_HOLDER: u8 = 2;

/// Byte offsets (including the 8-byte discriminator) of the V1 fields, for raw readers (the
/// SDK, the Jupiter adapter). Unit-tested below.
pub const POOL_STATE_FEE_MODEL_OFFSET: usize = 413;
pub const POOL_STATE_REWARD_MODEL_OFFSET: usize = 414;
pub const POOL_STATE_REWARD_RATE_SNAPSHOT_OFFSET: usize = 421;

/// The per-1e6 rates one V1 swap is charged at.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct V1Rates {
    pub lp: u64,
    pub protocol: u64,
    pub reward: u64,
}

impl V1Rates {
    pub fn total(&self) -> u64 {
        // lp + protocol + reward <= MAX_TOTAL_FEE_RATE (`v1_rates`)
        self.lp + self.protocol + self.reward
    }
}

impl PoolState {
    pub const LEN: usize = 8 + 10 * 32 + 1 * 5 + 8 * 7 + 1 * 2 + 6 * 1 + 2 * 8 + 8 * 28;

    /// DEEP V1: turns a freshly initialized pool into a V1 pool. `quote_on` is the side the
    /// fees are taken in (never `BothToken`); it is stored in `creator_fee_on`, so "the
    /// creator fee is on the input" means "the input is the quote token", i.e. a buy.
    pub fn set_v1(
        &mut self,
        quote_on: CreatorFeeOn,
        reward_model: u8,
        reward_rate: u64,
    ) -> Result<()> {
        require!(
            quote_on != CreatorFeeOn::BothToken,
            ErrorCode::InvalidQuoteSide
        );
        require!(
            reward_model <= REWARD_MODEL_HOLDER,
            ErrorCode::InvalidRewardModel
        );
        // A Standard pool has no reward; a reward rate is at most MAX_REWARD_RATE.
        let standard = reward_model == REWARD_MODEL_STANDARD;
        require!(
            reward_rate <= crate::deep_keys::MAX_REWARD_RATE && !(standard && reward_rate != 0),
            ErrorCode::InvalidRewardRate
        );
        self.fee_model = crate::states::FEE_MODEL_V1;
        self.reward_model = reward_model;
        self.padding2 = [0u8; 6];
        self.reward_rate_snapshot = reward_rate;
        self.creator_fee_on = quote_on.to_u8();
        self.enable_creator_fee = !standard;
        Ok(())
    }

    /// DEEP V1: the rates of one swap of this pool. LP and protocol (DEEP) rates are the
    /// config's rates of that side (together at most `MAX_TOTAL_FEE_RATE - MAX_REWARD_RATE`);
    /// the reward rate is the pool's own, fixed at creation (at most `MAX_REWARD_RATE`). No
    /// config change can alter a pool's reward rate, and their sum never exceeds the 10% cap.
    pub fn v1_rates(
        &self,
        amm_config: &crate::states::AmmConfig,
        is_buy: bool,
    ) -> Result<V1Rates> {
        let (lp, protocol) = if is_buy {
            (
                amm_config.buy_lp_fee_rate,
                amm_config.buy_protocol_fee_rate,
            )
        } else {
            (
                amm_config.sell_lp_fee_rate,
                amm_config.sell_protocol_fee_rate,
            )
        };
        let cap = crate::deep_keys::MAX_TOTAL_FEE_RATE - crate::deep_keys::MAX_REWARD_RATE;
        let base = lp.checked_add(protocol).ok_or(ErrorCode::MathOverflow)?;
        require_gte!(cap, base, ErrorCode::FeeRateAboveCap);
        let reward = if self.reward_model == REWARD_MODEL_STANDARD {
            0
        } else {
            self.reward_rate_snapshot
        };
        require_gte!(
            crate::deep_keys::MAX_REWARD_RATE,
            reward,
            ErrorCode::InvalidRewardRate
        );
        Ok(V1Rates {
            lp,
            protocol,
            reward,
        })
    }

    /// DEEP V1: books one swap's DEEP and reward parts. Both are in the QUOTE token (the
    /// input of a buy, the output of a sell), so both go to that side's accumulators,
    /// whatever the trade direction. The LP part is not booked: it stays in the vault as
    /// reserve.
    pub fn update_fees_v1(
        &mut self,
        protocol_fee: u64,
        reward_fee: u64,
        direction: TradeDirection,
        is_buy: bool,
    ) -> Result<()> {
        if self.reward_model == REWARD_MODEL_STANDARD {
            require_eq!(reward_fee, 0);
        }
        let quote_is_token_0 = match (direction, is_buy) {
            (TradeDirection::ZeroForOne, true) | (TradeDirection::OneForZero, false) => true,
            _ => false,
        };
        if quote_is_token_0 {
            self.protocol_fees_token_0 = self
                .protocol_fees_token_0
                .checked_add(protocol_fee)
                .ok_or(ErrorCode::MathOverflow)?;
            self.creator_fees_token_0 = self
                .creator_fees_token_0
                .checked_add(reward_fee)
                .ok_or(ErrorCode::MathOverflow)?;
        } else {
            self.protocol_fees_token_1 = self
                .protocol_fees_token_1
                .checked_add(protocol_fee)
                .ok_or(ErrorCode::MathOverflow)?;
            self.creator_fees_token_1 = self
                .creator_fees_token_1
                .checked_add(reward_fee)
                .ok_or(ErrorCode::MathOverflow)?;
        }
        Ok(())
    }

    pub fn initialize(
        &mut self,
        auth_bump: u8,
        lp_supply: u64,
        open_time: u64,
        pool_creator: Pubkey,
        amm_config: Pubkey,
        token_0_vault: Pubkey,
        token_1_vault: Pubkey,
        token_0_mint: &InterfaceAccount<Mint>,
        token_1_mint: &InterfaceAccount<Mint>,
        lp_mint: Pubkey,
        lp_mint_decimals: u8,
        observation_key: Pubkey,
        creator_fee_on: CreatorFeeOn,
        enable_creator_fee: bool,
    ) {
        self.amm_config = amm_config.key();
        self.pool_creator = pool_creator.key();
        self.token_0_vault = token_0_vault;
        self.token_1_vault = token_1_vault;
        self.lp_mint = lp_mint.key();
        self.token_0_mint = token_0_mint.key();
        self.token_1_mint = token_1_mint.key();
        self.token_0_program = *token_0_mint.to_account_info().owner;
        self.token_1_program = *token_1_mint.to_account_info().owner;
        self.observation_key = observation_key;
        self.auth_bump = auth_bump;
        self.lp_mint_decimals = lp_mint_decimals;
        self.mint_0_decimals = token_0_mint.decimals;
        self.mint_1_decimals = token_1_mint.decimals;
        self.lp_supply = lp_supply;
        self.protocol_fees_token_0 = 0;
        self.protocol_fees_token_1 = 0;
        self.fund_fees_token_0 = 0;
        self.fund_fees_token_1 = 0;
        self.open_time = open_time;
        self.recent_epoch = Clock::get().unwrap().epoch;
        self.creator_fee_on = creator_fee_on.to_u8();
        self.enable_creator_fee = enable_creator_fee;
        self.padding1 = [0u8; 6];
        self.creator_fees_token_0 = 0;
        self.creator_fees_token_1 = 0;
        // DEEP V1: a pool starts legacy (all zero, as upstream's padding); `set_v1` turns it
        // into a V1 pool in the same instruction.
        self.fee_model = 0;
        self.reward_model = 0;
        self.padding2 = [0u8; 6];
        self.reward_rate_snapshot = 0;
        self.padding = [0u64; 26];
    }

    pub fn set_status(&mut self, status: u8) {
        self.status = status
    }

    pub fn set_status_by_bit(&mut self, bit: PoolStatusBitIndex, flag: PoolStatusBitFlag) {
        let s = u8::from(1) << (bit as u8);
        if flag == PoolStatusBitFlag::Disable {
            self.status = self.status.bitor(s);
        } else {
            let m = u8::from(255).bitxor(s);
            self.status = self.status.bitand(m);
        }
    }

    /// Get status by bit, if it is `noraml` status, return true
    pub fn get_status_by_bit(&self, bit: PoolStatusBitIndex) -> bool {
        let status = u8::from(1) << (bit as u8);
        self.status.bitand(status) == 0
    }

    /// Settle the accrued creator fee at `share_rate`: the protocol's share is booked on
    /// the pool and stays in the vault until the admin collects it through
    /// `collect_protocol_fee`, and the amounts owed to the creator are returned.
    pub fn settle_creator_fee(&mut self, share_rate: u64) -> Result<(u64, u64)> {
        // DEEP V1: the reward fee of a V1 pool is 100% its recipient's (the creator or the
        // holder vault). Neither the config's share rate nor a CreatorFeeShare override
        // applies, so nobody can skim it.
        let share_rate = if self.fee_model == crate::states::FEE_MODEL_V1 {
            0
        } else {
            share_rate
        };
        let (creator_amount_0, shared_amount_0) =
            split_creator_fee_shared_amount(self.creator_fees_token_0, share_rate)?;
        let (creator_amount_1, shared_amount_1) =
            split_creator_fee_shared_amount(self.creator_fees_token_1, share_rate)?;

        let protocol_fees_token_0 = self.protocol_fees_token_0;
        let protocol_fees_token_1 = self.protocol_fees_token_1;
        self.protocol_fees_token_0 = protocol_fees_token_0
            .checked_add(shared_amount_0)
            .ok_or(ErrorCode::MathOverflow)?;
        self.protocol_fees_token_1 = protocol_fees_token_1
            .checked_add(shared_amount_1)
            .ok_or(ErrorCode::MathOverflow)?;

        self.creator_fees_token_0 = 0;
        self.creator_fees_token_1 = 0;

        Ok((creator_amount_0, creator_amount_1))
    }

    pub fn vault_amount_without_fee(&self, vault_0: u64, vault_1: u64) -> Result<(u64, u64)> {
        let fees_token_0 = self
            .protocol_fees_token_0
            .checked_add(self.fund_fees_token_0)
            .ok_or(ErrorCode::MathOverflow)?
            .checked_add(self.creator_fees_token_0)
            .ok_or(ErrorCode::MathOverflow)?;
        let fees_token_1 = self
            .protocol_fees_token_1
            .checked_add(self.fund_fees_token_1)
            .ok_or(ErrorCode::MathOverflow)?
            .checked_add(self.creator_fees_token_1)
            .ok_or(ErrorCode::MathOverflow)?;
        Ok((
            vault_0
                .checked_sub(fees_token_0)
                .ok_or(ErrorCode::InsufficientVault)?,
            vault_1
                .checked_sub(fees_token_1)
                .ok_or(ErrorCode::InsufficientVault)?,
        ))
    }

    pub fn token_price_x32(&self, vault_0: u64, vault_1: u64) -> Result<(u128, u128)> {
        let (token_0_amount, token_1_amount) = self.vault_amount_without_fee(vault_0, vault_1)?;
        Ok((
            token_1_amount as u128 * Q32 as u128 / token_0_amount as u128,
            token_0_amount as u128 * Q32 as u128 / token_1_amount as u128,
        ))
    }

    pub fn update_lp_supply(
        &mut self,
        liquidity_delta: u64,
        add: bool,
        recent_epoch: u64,
    ) -> Result<()> {
        if add {
            self.lp_supply = self
                .lp_supply
                .checked_add(liquidity_delta)
                .ok_or(ErrorCode::MathOverflow)?;
        } else {
            self.lp_supply = self
                .lp_supply
                .checked_sub(liquidity_delta)
                .ok_or(ErrorCode::MathOverflow)?;
        }
        self.recent_epoch = recent_epoch;
        Ok(())
    }

    // Determine the method used by the creator to calculate transaction fees
    pub fn is_creator_fee_on_input(&self, direction: TradeDirection) -> Result<bool> {
        let fee_on = CreatorFeeOn::from_u8(self.creator_fee_on)?;
        Ok(match (fee_on, direction) {
            (CreatorFeeOn::BothToken, _) => true,
            (CreatorFeeOn::OnlyToken0, TradeDirection::ZeroForOne) => true,
            (CreatorFeeOn::OnlyToken1, TradeDirection::OneForZero) => true,
            _ => false,
        })
    }

    pub fn get_swap_params(
        &self,
        input_vault_key: Pubkey,
        output_vault_key: Pubkey,
        input_vault_amount: u64,
        output_vault_amount: u64,
    ) -> Result<SwapParams> {
        let (
            trade_direction,
            total_input_token_amount,
            total_output_token_amount,
            token_0_price_x64,
            token_1_price_x64,
            is_creator_fee_on_input,
        ) = if input_vault_key == self.token_0_vault && output_vault_key == self.token_1_vault {
            let (total_input_token_amount, total_output_token_amount) =
                self.vault_amount_without_fee(input_vault_amount, output_vault_amount)?;
            let (token_0_price_x64, token_1_price_x64) =
                self.token_price_x32(input_vault_amount, output_vault_amount)?;

            (
                TradeDirection::ZeroForOne,
                total_input_token_amount,
                total_output_token_amount,
                token_0_price_x64,
                token_1_price_x64,
                self.is_creator_fee_on_input(TradeDirection::ZeroForOne)?,
            )
        } else if input_vault_key == self.token_1_vault && output_vault_key == self.token_0_vault {
            let (total_output_token_amount, total_input_token_amount) =
                self.vault_amount_without_fee(output_vault_amount, input_vault_amount)?;
            let (token_0_price_x64, token_1_price_x64) =
                self.token_price_x32(output_vault_amount, input_vault_amount)?;

            (
                TradeDirection::OneForZero,
                total_input_token_amount,
                total_output_token_amount,
                token_0_price_x64,
                token_1_price_x64,
                self.is_creator_fee_on_input(TradeDirection::OneForZero)?,
            )
        } else {
            return err!(ErrorCode::InvalidVault);
        };
        Ok(SwapParams {
            trade_direction,
            total_input_token_amount,
            total_output_token_amount,
            token_0_price_x64,
            token_1_price_x64,
            is_creator_fee_on_input,
        })
    }

    pub fn adjust_creator_fee_rate(&self, creator_fee_rate: u64) -> u64 {
        if self.enable_creator_fee {
            creator_fee_rate
        } else {
            0
        }
    }

    pub fn update_fees(
        &mut self,
        protocol_fee: u64,
        fund_fee: u64,
        creator_fee: u64,
        direction: TradeDirection,
    ) -> Result<()> {
        if !self.enable_creator_fee {
            require_eq!(creator_fee, 0)
        }
        let is_creator_fee_on_input = self.is_creator_fee_on_input(direction)?;
        match direction {
            TradeDirection::ZeroForOne => {
                self.protocol_fees_token_0 = self
                    .protocol_fees_token_0
                    .checked_add(protocol_fee)
                    .unwrap();
                self.fund_fees_token_0 = self.fund_fees_token_0.checked_add(fund_fee).unwrap();

                if is_creator_fee_on_input {
                    self.creator_fees_token_0 =
                        self.creator_fees_token_0.checked_add(creator_fee).unwrap();
                } else {
                    self.creator_fees_token_1 =
                        self.creator_fees_token_1.checked_add(creator_fee).unwrap();
                }
            }
            TradeDirection::OneForZero => {
                self.protocol_fees_token_1 = self
                    .protocol_fees_token_1
                    .checked_add(protocol_fee)
                    .unwrap();
                self.fund_fees_token_1 = self.fund_fees_token_1.checked_add(fund_fee).unwrap();
                if is_creator_fee_on_input {
                    self.creator_fees_token_1 =
                        self.creator_fees_token_1.checked_add(creator_fee).unwrap();
                } else {
                    self.creator_fees_token_0 =
                        self.creator_fees_token_0.checked_add(creator_fee).unwrap();
                }
            }
        };
        Ok(())
    }
}

#[cfg(test)]
pub mod pool_test {
    use super::*;

    #[test]
    fn pool_state_size_test() {
        assert_eq!(std::mem::size_of::<PoolState>(), PoolState::LEN - 8)
    }

    /// The shared creator fee fields are carved out of the existing padding, so the
    /// account length must stay the same for already deployed pools to keep loading.
    #[test]
    fn pool_state_size_is_unchanged() {
        assert_eq!(PoolState::LEN, 637);
    }

    /// A packed struct cannot hand out references to its fields, so the assertions read
    /// the values into locals first.
    #[test]
    fn settle_creator_fee_books_the_shared_part_and_accumulates() {
        let mut pool_state = PoolState::default();
        pool_state.creator_fees_token_0 = 1_000;
        pool_state.creator_fees_token_1 = 9;

        // 20% of 1_000 is 200; 20% of 9 rounds down to 1
        let owed = pool_state.settle_creator_fee(200_000).unwrap();
        assert_eq!(owed, (800, 8));
        let fees = (
            pool_state.creator_fees_token_0,
            pool_state.creator_fees_token_1,
            pool_state.protocol_fees_token_0,
            pool_state.protocol_fees_token_1,
        );
        assert_eq!(fees, (0, 0, 200, 1));

        // a second settlement adds to what is already booked
        pool_state.creator_fees_token_0 = 500;
        assert_eq!(pool_state.settle_creator_fee(200_000).unwrap(), (400, 0));
        let shared_0 = pool_state.protocol_fees_token_0;
        assert_eq!(shared_0, 300);
    }

    #[test]
    fn settle_creator_fee_reports_overflow_of_the_booked_share() {
        let mut pool_state = PoolState::default();
        pool_state.protocol_fees_token_0 = u64::MAX;
        pool_state.creator_fees_token_0 = 1_000;

        assert!(pool_state.settle_creator_fee(200_000).is_err());
    }

    /// The V1 fields are carved out of the padding: same size, fixed offsets, and a pool
    /// written before V1 (zero padding) reads as legacy / Standard / no reward.
    #[test]
    fn v1_fields_are_carved_from_padding_at_fixed_offsets() {
        let mut pool_state = PoolState::default();
        pool_state.creator_fees_token_1 = 0x1111_1111_1111_1111;
        pool_state.fee_model = 0xA1;
        pool_state.reward_model = 0xB2;
        pool_state.reward_rate_snapshot = 0x0807_0605_0403_0201;
        // SAFETY: PoolState is `repr(C, packed)` plain data with no padding bytes.
        let bytes = unsafe {
            std::slice::from_raw_parts(
                &pool_state as *const PoolState as *const u8,
                std::mem::size_of::<PoolState>(),
            )
        };
        assert_eq!(bytes.len() + 8, PoolState::LEN);
        let at = |o: usize| o - 8; // the constants include the discriminator
        assert_eq!(bytes[at(405)..at(413)], [0x11u8; 8]);
        assert_eq!(bytes[at(POOL_STATE_FEE_MODEL_OFFSET)], 0xA1);
        assert_eq!(bytes[at(POOL_STATE_REWARD_MODEL_OFFSET)], 0xB2);
        assert_eq!(bytes[at(415)..at(421)], [0u8; 6]);
        assert_eq!(
            bytes[at(POOL_STATE_REWARD_RATE_SNAPSHOT_OFFSET)..at(429)],
            [1, 2, 3, 4, 5, 6, 7, 8]
        );
        assert_eq!(bytes[at(429)..], [0u8; 208]);

        let legacy = PoolState::default();
        let v = (
            legacy.fee_model,
            legacy.reward_model,
            legacy.reward_rate_snapshot,
        );
        assert_eq!(v, (0, 0, 0));
    }

    fn v1_config() -> crate::states::AmmConfig {
        crate::states::AmmConfig {
            fee_model: crate::states::FEE_MODEL_V1,
            buy_lp_fee_rate: 1_000,
            buy_protocol_fee_rate: 2_500,
            sell_lp_fee_rate: 1_000,
            sell_protocol_fee_rate: 6_500,
            ..Default::default()
        }
    }

    #[test]
    fn set_v1_stores_the_model_and_the_quote_side() {
        let mut pool_state = PoolState::default();
        assert!(pool_state
            .set_v1(CreatorFeeOn::BothToken, REWARD_MODEL_CREATOR, 10_000)
            .is_err());
        assert!(pool_state.set_v1(CreatorFeeOn::OnlyToken0, 3, 10_000).is_err());
        let untouched = pool_state.fee_model;
        assert_eq!(untouched, 0);

        pool_state
            .set_v1(CreatorFeeOn::OnlyToken1, REWARD_MODEL_HOLDER, 10_000)
            .unwrap();
        let v = (
            pool_state.fee_model,
            pool_state.reward_model,
            pool_state.reward_rate_snapshot,
            pool_state.creator_fee_on,
            pool_state.enable_creator_fee,
        );
        assert_eq!(v, (1, REWARD_MODEL_HOLDER, 10_000, 2, true));
        // token 1 is the quote: token1 -> token0 is a buy
        assert!(pool_state
            .is_creator_fee_on_input(TradeDirection::OneForZero)
            .unwrap());
        assert!(!pool_state
            .is_creator_fee_on_input(TradeDirection::ZeroForOne)
            .unwrap());

        // Standard has no reward rate and never accrues one; a reward rate has its own cap
        let mut standard = PoolState::default();
        assert!(standard
            .set_v1(CreatorFeeOn::OnlyToken0, REWARD_MODEL_STANDARD, 1)
            .is_err());
        for model in [REWARD_MODEL_CREATOR, REWARD_MODEL_HOLDER] {
            let mut p = PoolState::default();
            assert!(p.set_v1(CreatorFeeOn::OnlyToken0, model, 50_001).is_err());
            for rate in [0, 100, 50_000] {
                p.set_v1(CreatorFeeOn::OnlyToken0, model, rate).unwrap();
                let v = p.reward_rate_snapshot;
                assert_eq!(v, rate);
            }
        }
        standard
            .set_v1(CreatorFeeOn::OnlyToken0, REWARD_MODEL_STANDARD, 0)
            .unwrap();
        let v = (standard.reward_rate_snapshot, standard.enable_creator_fee);
        assert_eq!(v, (0, false));
        assert!(standard
            .update_fees_v1(5, 1, TradeDirection::ZeroForOne, true)
            .is_err());
    }

    #[test]
    fn v1_rates_pick_the_side_and_never_exceed_the_cap() {
        let cfg = v1_config();
        let mut pool_state = PoolState::default();
        pool_state
            .set_v1(CreatorFeeOn::OnlyToken0, REWARD_MODEL_CREATOR, 10_000)
            .unwrap();
        let buy = pool_state.v1_rates(&cfg, true).unwrap();
        let sell = pool_state.v1_rates(&cfg, false).unwrap();
        assert_eq!((buy.lp, buy.protocol, buy.reward), (1_000, 2_500, 10_000));
        assert_eq!((sell.lp, sell.protocol, sell.reward), (1_000, 6_500, 10_000));
        assert_eq!((buy.total(), sell.total()), (13_500, 17_500));

        // the pool's own LP + DEEP side follows the config; the reward rate never does. With
        // the config at its 5% limit and the pool at the 5% reward ceiling a side costs
        // exactly the 10% cap, never more
        let mut high = cfg.clone();
        high.sell_protocol_fee_rate = 49_000;
        assert!(high.validate_v1_rates().is_ok());
        let sell = pool_state.v1_rates(&high, false).unwrap();
        assert_eq!((sell.lp, sell.protocol, sell.reward), (1_000, 49_000, 10_000));
        let mut max = PoolState::default();
        max.set_v1(CreatorFeeOn::OnlyToken0, REWARD_MODEL_HOLDER, 50_000)
            .unwrap();
        assert_eq!(
            max.v1_rates(&high, false).unwrap().total(),
            crate::deep_keys::MAX_TOTAL_FEE_RATE
        );
        // the config's current maximum for NEW pools does not touch an existing pool
        high.max_reward_rate = 100;
        assert_eq!(max.v1_rates(&high, false).unwrap().reward, 50_000);
        // a config above its limit (cannot be stored) or a reward above its ceiling (cannot
        // be stored either) is refused, not priced
        high.sell_protocol_fee_rate = 49_001;
        assert!(pool_state.v1_rates(&high, false).is_err());
        max.reward_rate_snapshot = 50_001;
        assert!(max.v1_rates(&cfg, true).is_err());

        let mut standard = PoolState::default();
        standard
            .set_v1(CreatorFeeOn::OnlyToken0, REWARD_MODEL_STANDARD, 0)
            .unwrap();
        assert_eq!(standard.v1_rates(&cfg, false).unwrap().total(), 7_500);
        // a Standard pool never charges a reward, whatever its stored bytes say
        standard.reward_rate_snapshot = 10_000;
        assert_eq!(standard.v1_rates(&cfg, false).unwrap().reward, 0);
    }

    /// DEEP's part and the reward part are booked on the QUOTE side in both directions, and
    /// the reserves (`vault_amount_without_fee`) exclude exactly those two.
    #[test]
    fn update_fees_v1_books_both_parts_on_the_quote_side() {
        for (quote_on, buy_direction) in [
            (CreatorFeeOn::OnlyToken0, TradeDirection::ZeroForOne),
            (CreatorFeeOn::OnlyToken1, TradeDirection::OneForZero),
        ] {
            let mut pool_state = PoolState::default();
            pool_state
                .set_v1(quote_on.clone(), REWARD_MODEL_HOLDER, 10_000)
                .unwrap();
            let is_buy = |d| pool_state.is_creator_fee_on_input(d).unwrap();
            assert!(is_buy(buy_direction));
            assert!(!is_buy(buy_direction.opposite()));
            pool_state.update_fees_v1(25, 100, buy_direction, true).unwrap();
            pool_state
                .update_fees_v1(65, 100, buy_direction.opposite(), false)
                .unwrap();
            let fees = (
                pool_state.protocol_fees_token_0,
                pool_state.creator_fees_token_0,
                pool_state.protocol_fees_token_1,
                pool_state.creator_fees_token_1,
                pool_state.fund_fees_token_0,
                pool_state.fund_fees_token_1,
            );
            let reserves = pool_state.vault_amount_without_fee(1_000, 1_000).unwrap();
            if quote_on == CreatorFeeOn::OnlyToken0 {
                assert_eq!(fees, (90, 200, 0, 0, 0, 0));
                assert_eq!(reserves, (710, 1_000));
            } else {
                assert_eq!(fees, (0, 0, 90, 200, 0, 0));
                assert_eq!(reserves, (1_000, 710));
            }
            pool_state.protocol_fees_token_0 = u64::MAX;
            pool_state.protocol_fees_token_1 = u64::MAX;
            assert!(pool_state.update_fees_v1(1, 0, buy_direction, true).is_err());
        }
    }

    /// A V1 pool's reward is never shared with the protocol, whatever share rate the caller
    /// resolved (AmmConfig or a CreatorFeeShare override); a legacy pool keeps its share.
    #[test]
    fn settle_creator_fee_pays_a_v1_reward_in_full() {
        let mut pool_state = PoolState::default();
        pool_state
            .set_v1(CreatorFeeOn::OnlyToken1, REWARD_MODEL_CREATOR, 10_000)
            .unwrap();
        pool_state.creator_fees_token_1 = 1_001;
        pool_state.protocol_fees_token_1 = 7;
        assert_eq!(pool_state.settle_creator_fee(1_000_000).unwrap(), (0, 1_001));
        let fees = (
            pool_state.creator_fees_token_1,
            pool_state.protocol_fees_token_1,
        );
        assert_eq!(fees, (0, 7));

        let mut legacy = PoolState::default();
        legacy.creator_fees_token_1 = 1_001;
        assert_eq!(legacy.settle_creator_fee(500_000).unwrap(), (0, 501));
    }

    mod pool_status_test {
        use super::*;

        #[test]
        fn get_set_status_by_bit() {
            let mut pool_state = PoolState::default();
            pool_state.set_status(4); // 0000100
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Swap),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Deposit),
                true
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Withdraw),
                true
            );

            // disable -> disable, nothing to change
            pool_state.set_status_by_bit(PoolStatusBitIndex::Swap, PoolStatusBitFlag::Disable);
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Swap),
                false
            );

            // disable -> enable
            pool_state.set_status_by_bit(PoolStatusBitIndex::Swap, PoolStatusBitFlag::Enable);
            assert_eq!(pool_state.get_status_by_bit(PoolStatusBitIndex::Swap), true);

            // enable -> enable, nothing to change
            pool_state.set_status_by_bit(PoolStatusBitIndex::Swap, PoolStatusBitFlag::Enable);
            assert_eq!(pool_state.get_status_by_bit(PoolStatusBitIndex::Swap), true);
            // enable -> disable
            pool_state.set_status_by_bit(PoolStatusBitIndex::Swap, PoolStatusBitFlag::Disable);
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Swap),
                false
            );

            pool_state.set_status(5); // 0000101
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Swap),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Deposit),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Withdraw),
                true
            );

            pool_state.set_status(7); // 0000111
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Swap),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Deposit),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Withdraw),
                false
            );

            pool_state.set_status(3); // 0000011
            assert_eq!(pool_state.get_status_by_bit(PoolStatusBitIndex::Swap), true);
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Deposit),
                false
            );
            assert_eq!(
                pool_state.get_status_by_bit(PoolStatusBitIndex::Withdraw),
                false
            );
        }
    }
}
