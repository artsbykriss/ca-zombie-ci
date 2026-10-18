use anchor_lang::prelude::*;

pub const AMM_CONFIG_SEED: &str = "amm_config";

/// Holds the current owner of the factory
#[account]
#[derive(Default, Debug)]
pub struct AmmConfig {
    /// Bump to identify PDA
    pub bump: u8,
    /// Status to control if new pool can be create
    pub disable_create_pool: bool,
    /// Config index
    pub index: u16,
    /// The trade fee, denominated in hundredths of a bip (10^-6)
    pub trade_fee_rate: u64,
    /// The protocol fee
    pub protocol_fee_rate: u64,
    /// The fund fee, denominated in hundredths of a bip (10^-6)
    pub fund_fee_rate: u64,
    /// Fee for create a new pool
    pub create_pool_fee: u64,
    /// Address of the protocol fee owner
    pub protocol_owner: Pubkey,
    /// Address of the fund fee owner
    pub fund_owner: Pubkey,
    /// The pool creator fee, denominated in hundredths of a bip (10^-6)
    pub creator_fee_rate: u64,
    /// The share of the creator fee retained by the protocol, denominated in
    /// hundredths of a bip (10^-6). Zero means the creator receives the whole creator fee.
    /// Overridden by a `CreatorFeeShare` account when one exists for the pool creator.
    pub creator_fee_share_rate: u64,
    /// DEEP V1: 0 = legacy (upstream cp-swap fee semantics, the fields above), 1 = V1
    /// (side-dependent absolute rates, the fields below). Set when the config is created and
    /// never changed: a pool is always priced with the model it was created under.
    pub fee_model: u8,
    pub padding0: [u8; 7],
    /// DEEP V1, absolute rates per 1e6 (not shares of a trade fee). "Buy" = the input is the
    /// pool's quote token (SOL on TOKEN/SOL), "sell" = the output is. The LP part stays in
    /// the pool; the protocol part is DEEP's and accrues in the quote token.
    pub buy_lp_fee_rate: u64,
    pub buy_protocol_fee_rate: u64,
    pub sell_lp_fee_rate: u64,
    pub sell_protocol_fee_rate: u64,
    /// DEEP V1: the CURRENT maximum reward rate (per 1e6) of a pool opened with
    /// `initialize_v1`, at most `deep_keys::MAX_REWARD_RATE`. It applies to NEW pools only: a
    /// pool's own rate (`PoolState::reward_rate_snapshot`) never changes, and
    /// `initialize_with_permission_v1` (graduation) is not subject to it.
    pub max_reward_rate: u64,
    /// padding
    pub padding: [u64; 8],
}

/// `AmmConfig::fee_model` / `PoolState::fee_model` values.
pub const FEE_MODEL_LEGACY: u8 = 0;
pub const FEE_MODEL_V1: u8 = 1;

/// Byte offsets (including the 8-byte discriminator) of the V1 fields, for raw readers
/// (deep-curve `graduate`, the SDK, the Jupiter adapter). Unit-tested below.
pub const AMM_CONFIG_FEE_MODEL_OFFSET: usize = 124;
pub const AMM_CONFIG_BUY_LP_FEE_RATE_OFFSET: usize = 132;
pub const AMM_CONFIG_BUY_PROTOCOL_FEE_RATE_OFFSET: usize = 140;
pub const AMM_CONFIG_SELL_LP_FEE_RATE_OFFSET: usize = 148;
pub const AMM_CONFIG_SELL_PROTOCOL_FEE_RATE_OFFSET: usize = 156;
pub const AMM_CONFIG_MAX_REWARD_RATE_OFFSET: usize = 164;

impl AmmConfig {
    pub const LEN: usize = 8 + 1 + 1 + 2 + 4 * 8 + 32 * 2 + 8 + 8 + 8 * 14;

    /// DEEP V1: the pool's own side of the fee, LP + DEEP, leaves room for the largest reward
    /// rate a pool can hold: `lp + protocol + MAX_REWARD_RATE <= MAX_TOTAL_FEE_RATE` on each
    /// side. So every pool's total stays at or under the 10% hard cap for good, and no rate
    /// change can make a pool unpriceable or a graduation fail. The current maximum reward
    /// rate for new pools stays at or under its ceiling.
    pub fn validate_v1_rates(&self) -> Result<()> {
        require!(
            self.max_reward_rate <= crate::deep_keys::MAX_REWARD_RATE,
            crate::error::ErrorCode::InvalidRewardRate
        );
        let cap = crate::deep_keys::MAX_TOTAL_FEE_RATE - crate::deep_keys::MAX_REWARD_RATE;
        for (lp, protocol) in [
            (self.buy_lp_fee_rate, self.buy_protocol_fee_rate),
            (self.sell_lp_fee_rate, self.sell_protocol_fee_rate),
        ] {
            let total = lp
                .checked_add(protocol)
                .ok_or(crate::error::ErrorCode::FeeRateAboveCap)?;
            require!(total <= cap, crate::error::ErrorCode::FeeRateAboveCap);
        }
        Ok(())
    }

    /// DEEP V1: keeps the legacy fee fields of a V1 config at the closest legacy equivalent
    /// of its buy side (trade fee = LP + protocol, the protocol's share of it, no creator
    /// fee). No V1 code path reads them; a binary from before V1 (a rollback) would, and must
    /// not price V1 pools at 0%.
    pub fn sync_legacy_mirror(&mut self) {
        let trade = self
            .buy_lp_fee_rate
            .saturating_add(self.buy_protocol_fee_rate);
        self.trade_fee_rate = trade;
        self.protocol_fee_rate = if trade == 0 {
            0
        } else {
            ((self.buy_protocol_fee_rate as u128)
                * (crate::curve::fees::FEE_RATE_DENOMINATOR_VALUE as u128)
                / (trade as u128)) as u64
        };
        self.creator_fee_rate = 0;
        self.creator_fee_share_rate = 0;
    }
}

#[cfg(test)]
mod config_test {
    use super::*;

    /// The share rate field is carved out of the existing padding, so the account length
    /// must stay the same for already deployed configs to keep deserializing.
    #[test]
    fn amm_config_size_is_unchanged() {
        assert_eq!(AmmConfig::LEN, 236);
    }

    /// The V1 fields are carved out of the padding: the serialized size is still LEN, every
    /// field sits at its published offset, and an account written before V1 (zero padding)
    /// reads as a legacy config with every V1 rate 0.
    #[test]
    fn v1_fields_are_carved_from_padding_at_fixed_offsets() {
        let cfg = AmmConfig {
            bump: 1,
            disable_create_pool: true,
            index: 0x0302,
            trade_fee_rate: 4,
            protocol_fee_rate: 5,
            fund_fee_rate: 6,
            create_pool_fee: 7,
            protocol_owner: Pubkey::new_from_array([8; 32]),
            fund_owner: Pubkey::new_from_array([9; 32]),
            creator_fee_rate: 10,
            creator_fee_share_rate: 11,
            fee_model: FEE_MODEL_V1,
            padding0: [0; 7],
            buy_lp_fee_rate: 12,
            buy_protocol_fee_rate: 13,
            sell_lp_fee_rate: 14,
            sell_protocol_fee_rate: 15,
            max_reward_rate: 16,
            padding: [0; 8],
        };
        let mut data = Vec::new();
        cfg.try_serialize(&mut data).unwrap();
        assert_eq!(data.len(), AmmConfig::LEN);
        let u64_at = |o: usize| u64::from_le_bytes(data[o..o + 8].try_into().unwrap());
        assert_eq!(u64_at(108), 10);
        assert_eq!(u64_at(116), 11);
        assert_eq!(data[AMM_CONFIG_FEE_MODEL_OFFSET], FEE_MODEL_V1);
        assert_eq!(data[125..132], [0u8; 7]);
        assert_eq!(u64_at(AMM_CONFIG_BUY_LP_FEE_RATE_OFFSET), 12);
        assert_eq!(u64_at(AMM_CONFIG_BUY_PROTOCOL_FEE_RATE_OFFSET), 13);
        assert_eq!(u64_at(AMM_CONFIG_SELL_LP_FEE_RATE_OFFSET), 14);
        assert_eq!(u64_at(AMM_CONFIG_SELL_PROTOCOL_FEE_RATE_OFFSET), 15);
        assert_eq!(u64_at(AMM_CONFIG_MAX_REWARD_RATE_OFFSET), 16);
        assert_eq!(data[172..], [0u8; 64]);

        // a pre-V1 account: same bytes with the old padding all zero
        let mut old = data.clone();
        old[124..].fill(0);
        let legacy = AmmConfig::try_deserialize(&mut &old[..]).unwrap();
        assert_eq!(legacy.fee_model, FEE_MODEL_LEGACY);
        assert_eq!(legacy.creator_fee_share_rate, 11);
        assert_eq!(
            (
                legacy.buy_lp_fee_rate,
                legacy.buy_protocol_fee_rate,
                legacy.sell_lp_fee_rate,
                legacy.sell_protocol_fee_rate,
                legacy.max_reward_rate,
            ),
            (0, 0, 0, 0, 0)
        );
    }

    fn v1(buy: (u64, u64), sell: (u64, u64)) -> AmmConfig {
        AmmConfig {
            fee_model: FEE_MODEL_V1,
            buy_lp_fee_rate: buy.0,
            buy_protocol_fee_rate: buy.1,
            sell_lp_fee_rate: sell.0,
            sell_protocol_fee_rate: sell.1,
            ..Default::default()
        }
    }

    #[test]
    fn v1_rates_leave_room_for_the_reward_under_the_ten_percent_cap() {
        // the owner's V1 schedule
        assert!(v1((1_000, 2_500), (1_000, 6_500)).validate_v1_rates().is_ok());
        // LP + DEEP up to 5% on a side (10% minus the 5% reward ceiling), not one more
        assert!(v1((1_000, 49_000), (0, 0)).validate_v1_rates().is_ok());
        assert!(v1((1_000, 49_001), (0, 0)).validate_v1_rates().is_err());
        assert!(v1((0, 0), (25_000, 25_000)).validate_v1_rates().is_ok());
        assert!(v1((0, 0), (25_000, 25_001)).validate_v1_rates().is_err());
        // rates near 100% (and overflowing sums) are rejected, never wrapped
        assert!(v1((999_999, 0), (0, 0)).validate_v1_rates().is_err());
        assert!(v1((u64::MAX, 1), (0, 0)).validate_v1_rates().is_err());
        assert!(v1((0, 0), (1, u64::MAX)).validate_v1_rates().is_err());
        // the current maximum reward rate: at most the 5% ceiling
        let mut cfg = v1((1_000, 2_500), (1_000, 6_500));
        for (max, ok) in [(0, true), (10_000, true), (50_000, true), (50_001, false)] {
            cfg.max_reward_rate = max;
            assert_eq!(cfg.validate_v1_rates().is_ok(), ok, "{max}");
        }
    }

    #[test]
    fn legacy_mirror_tracks_the_buy_side() {
        let mut cfg = v1((1_000, 2_500), (1_000, 6_500));
        cfg.creator_fee_rate = 9;
        cfg.creator_fee_share_rate = 9;
        cfg.sync_legacy_mirror();
        assert_eq!(cfg.trade_fee_rate, 3_500);
        assert_eq!(cfg.protocol_fee_rate, 714_285);
        assert_eq!((cfg.creator_fee_rate, cfg.creator_fee_share_rate), (0, 0));
        let mut zero = v1((0, 0), (0, 0));
        zero.sync_legacy_mirror();
        assert_eq!((zero.trade_fee_rate, zero.protocol_fee_rate), (0, 0));
    }
}
