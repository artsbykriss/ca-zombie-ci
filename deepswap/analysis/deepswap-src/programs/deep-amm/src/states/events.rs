use anchor_lang::prelude::*;

/// Emitted when deposit and withdraw
#[event]
#[cfg_attr(feature = "client", derive(Debug))]
pub struct LpChangeEvent {
    pub pool_id: Pubkey,
    pub lp_amount_before: u64,
    /// pool vault sub trade fees
    pub token_0_vault_before: u64,
    /// pool vault sub trade fees
    pub token_1_vault_before: u64,
    /// calculate result without transfer fee
    pub token_0_amount: u64,
    /// calculate result without transfer fee
    pub token_1_amount: u64,
    pub token_0_transfer_fee: u64,
    pub token_1_transfer_fee: u64,
    // 0: deposit, 1: withdraw
    pub change_type: u8,
}

/// Emitted when swap
#[event]
#[cfg_attr(feature = "client", derive(Debug))]
pub struct SwapEvent {
    pub pool_id: Pubkey,
    /// pool vault sub trade fees
    pub input_vault_before: u64,
    /// pool vault sub trade fees
    pub output_vault_before: u64,
    /// calculate result without transfer fee
    pub input_amount: u64,
    /// calculate result without transfer fee
    pub output_amount: u64,
    pub input_transfer_fee: u64,
    pub output_transfer_fee: u64,
    pub base_input: bool,
    pub input_mint: Pubkey,
    pub output_mint: Pubkey,
    pub trade_fee: u64,
    /// Amount of fee tokens going to creator
    pub creator_fee: u64,
    pub creator_fee_on_input: bool,
}

/// DEEP V1: emitted right after `SwapEvent` by every swap of a V1 pool (`fee_model == 1`),
/// with the exact fee parts of that swap. All three amounts are in `quote_mint` (the input
/// token of a buy, the output token of a sell). `SwapEvent` itself is unchanged; for a V1
/// swap its `trade_fee` is `lp_fee + protocol_fee`, its `creator_fee` is `reward_fee` and its
/// `creator_fee_on_input` is `is_buy`.
#[event]
#[cfg_attr(feature = "client", derive(Debug))]
pub struct SwapFeesV1 {
    pub pool_id: Pubkey,
    /// true: quote token in (the fee came off the input); false: quote token out (the fee
    /// came off the output, and `SwapEvent::output_amount` is already net of it).
    pub is_buy: bool,
    /// The token all three fee amounts are in.
    pub quote_mint: Pubkey,
    /// Stays in the pool as reserve (liquidity providers).
    pub lp_fee: u64,
    /// DEEP's part, accrued in `protocol_fees_token_<quote>`; leaves through
    /// `collect_protocol_fee_to_vault` to the DEEP fee vault.
    pub protocol_fee: u64,
    /// The reward part, accrued in `creator_fees_token_<quote>` for `pool_creator`; 0 for a
    /// Standard pool.
    pub reward_fee: u64,
    /// 0 Standard, 1 Creator, 2 Holder.
    pub reward_model: u8,
}
