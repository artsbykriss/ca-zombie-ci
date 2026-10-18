//! DEEP V1 side-dependent swap math. New file, not in upstream (see NOTICE, modification 8).
//! `calculator.rs`, `fees.rs` and `constant_product.rs` are untouched: legacy pools keep
//! upstream's math byte for byte.
//!
//! A V1 pool has a QUOTE token (SOL on TOKEN/SOL). Every fee is taken in it:
//!
//! * buy  (quote in):  the fee comes off the input before the curve;
//! * sell (quote out): the fee comes off the curve's output before the trader is paid.
//!
//! The fee is one total at `lp + protocol + reward` (rates per 1e6), split into three parts:
//! the LP part stays in the pool as reserve, the protocol part is DEEP's, the reward part is
//! the pool's reward recipient's (0 for a Standard pool).
//!
//! Rounding (CLAUDE.md): the fee total rounds UP; the LP and reward parts are floored and
//! DEEP takes the remainder, so `lp + protocol + reward == total` to the unit; what the
//! trader receives rounds DOWN and what the trader must pay rounds UP. Everything is checked
//! `u128`; any overflow, division by zero or impossible trade is `None`, never a panic.
//!
//! Mirrors: `packages/curve-math/src/deepswap.ts` and `integrations/jupiter/src/math.rs`,
//! pinned together by `fixtures/deepswap-v1-vectors.json`.

use crate::curve::calculator::SwapResult;
use crate::curve::fees::FEE_RATE_DENOMINATOR_VALUE;

/// THE cap: the largest total rate (LP + DEEP + reward) the math accepts, 10% per side.
pub const MAX_TOTAL_FEE_RATE: u64 = crate::deep_keys::MAX_TOTAL_FEE_RATE;
/// The ceiling of a pool's reward rate, 5% (checked where a pool is created and in
/// `PoolState::v1_rates`, not by the math).
pub const MAX_REWARD_RATE: u64 = crate::deep_keys::MAX_REWARD_RATE;

/// One fee total and its three parts; `lp + protocol + reward == total`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct FeeParts {
    pub total: u128,
    pub lp: u128,
    pub protocol: u128,
    pub reward: u128,
}

/// `lp_rate + protocol_rate + reward_rate`, or `None` above the hard cap: the one check of
/// the 10% total per side.
pub fn total_rate(lp_rate: u64, protocol_rate: u64, reward_rate: u64) -> Option<u64> {
    let total = lp_rate
        .checked_add(protocol_rate)?
        .checked_add(reward_rate)?;
    if total > MAX_TOTAL_FEE_RATE {
        return None;
    }
    Some(total)
}

/// `ceil(amount * total_rate / 1e6)`: the fee on a gross amount.
pub fn fee_on(amount: u128, total_rate: u64) -> Option<u128> {
    let d = u128::from(FEE_RATE_DENOMINATOR_VALUE);
    amount
        .checked_mul(u128::from(total_rate))?
        .checked_add(d - 1)?
        .checked_div(d)
}

/// `ceil(net * 1e6 / (1e6 - total_rate))`: the smallest gross amount that leaves at least
/// `net` after the fee.
pub fn gross_up(net: u128, total_rate: u64) -> Option<u128> {
    if total_rate == 0 {
        return Some(net);
    }
    let d = u128::from(FEE_RATE_DENOMINATOR_VALUE);
    let keep = d.checked_sub(u128::from(total_rate))?;
    if keep == 0 {
        return None;
    }
    net.checked_mul(d)?.checked_add(keep - 1)?.checked_div(keep)
}

/// Splits a fee total: LP and reward parts floored pro rata, DEEP takes the remainder.
pub fn split_fee(
    total: u128,
    lp_rate: u64,
    protocol_rate: u64,
    reward_rate: u64,
) -> Option<FeeParts> {
    let rate = u128::from(total_rate(lp_rate, protocol_rate, reward_rate)?);
    if rate == 0 {
        // no rate, no fee
        if total != 0 {
            return None;
        }
        return Some(FeeParts {
            total: 0,
            lp: 0,
            protocol: 0,
            reward: 0,
        });
    }
    let lp = total.checked_mul(u128::from(lp_rate))?.checked_div(rate)?;
    let reward = total
        .checked_mul(u128::from(reward_rate))?
        .checked_div(rate)?;
    let protocol = total.checked_sub(lp)?.checked_sub(reward)?;
    Some(FeeParts {
        total,
        lp,
        protocol,
        reward,
    })
}

/// `floor(input * out_reserve / (in_reserve + input))`.
fn curve_out(input: u128, in_reserve: u128, out_reserve: u128) -> Option<u128> {
    input
        .checked_mul(out_reserve)?
        .checked_div(in_reserve.checked_add(input)?)
}

/// `ceil(in_reserve * output / (out_reserve - output))`; `None` unless `output < out_reserve`.
fn curve_in(output: u128, in_reserve: u128, out_reserve: u128) -> Option<u128> {
    let left = out_reserve.checked_sub(output)?;
    if left == 0 {
        return None;
    }
    in_reserve
        .checked_mul(output)?
        .checked_add(left - 1)?
        .checked_div(left)
}

fn result(
    new_input_vault_amount: u128,
    new_output_vault_amount: u128,
    input_amount: u128,
    output_amount: u128,
    fee: FeeParts,
) -> Option<SwapResult> {
    Some(SwapResult {
        new_input_vault_amount,
        new_output_vault_amount,
        input_amount,
        output_amount,
        // SwapResult keeps upstream's field meanings as far as they go: `trade_fee` is the
        // pool fee (LP + DEEP), `protocol_fee` DEEP's part of it, `creator_fee` the reward.
        trade_fee: fee.lp.checked_add(fee.protocol)?,
        protocol_fee: fee.protocol,
        fund_fee: 0,
        creator_fee: fee.reward,
    })
}

/// Exact input. `is_buy`: the input is the quote token.
///
/// * buy:  `total = ceil(in * T / 1e6)`, `net = in - total`,
///         `out = floor(net * out_reserve / (in_reserve + net))`;
/// * sell: `gross = floor(in * out_reserve / (in_reserve + in))`,
///         `total = ceil(gross * T / 1e6)`, `out = gross - total`.
///
/// `new_*_vault_amount` are the reserves the invariant check uses, as upstream: they count
/// no part of the fee, so `k` is checked without the LP part's help.
pub fn swap_base_input_v1(
    input_amount: u128,
    input_vault_amount: u128,
    output_vault_amount: u128,
    lp_rate: u64,
    protocol_rate: u64,
    reward_rate: u64,
    is_buy: bool,
) -> Option<SwapResult> {
    let rate = total_rate(lp_rate, protocol_rate, reward_rate)?;
    if is_buy {
        let total = fee_on(input_amount, rate)?;
        let fee = split_fee(total, lp_rate, protocol_rate, reward_rate)?;
        let net = input_amount.checked_sub(total)?;
        let out = curve_out(net, input_vault_amount, output_vault_amount)?;
        result(
            input_vault_amount.checked_add(net)?,
            output_vault_amount.checked_sub(out)?,
            input_amount,
            out,
            fee,
        )
    } else {
        let gross = curve_out(input_amount, input_vault_amount, output_vault_amount)?;
        let total = fee_on(gross, rate)?;
        let fee = split_fee(total, lp_rate, protocol_rate, reward_rate)?;
        result(
            input_vault_amount.checked_add(input_amount)?,
            output_vault_amount.checked_sub(gross)?,
            input_amount,
            gross.checked_sub(total)?,
            fee,
        )
    }
}

/// Exact output: `output_amount` is what the trader receives.
///
/// * buy  (exact tokens out): `swapped = ceil(in_reserve * out / (out_reserve - out))`,
///         `in = ceil(swapped * 1e6 / (1e6 - T))`, `total = in - swapped`;
/// * sell (exact quote out):  `gross = ceil(out * 1e6 / (1e6 - T))`, `total = gross - out`,
///         `in = ceil(in_reserve * gross / (out_reserve - gross))`; `gross` must be less
///         than the output reserve.
pub fn swap_base_output_v1(
    output_amount: u128,
    input_vault_amount: u128,
    output_vault_amount: u128,
    lp_rate: u64,
    protocol_rate: u64,
    reward_rate: u64,
    is_buy: bool,
) -> Option<SwapResult> {
    let rate = total_rate(lp_rate, protocol_rate, reward_rate)?;
    if is_buy {
        let swapped = curve_in(output_amount, input_vault_amount, output_vault_amount)?;
        let input = gross_up(swapped, rate)?;
        let fee = split_fee(
            input.checked_sub(swapped)?,
            lp_rate,
            protocol_rate,
            reward_rate,
        )?;
        result(
            input_vault_amount.checked_add(swapped)?,
            output_vault_amount.checked_sub(output_amount)?,
            input,
            output_amount,
            fee,
        )
    } else {
        let gross = gross_up(output_amount, rate)?;
        let fee = split_fee(
            gross.checked_sub(output_amount)?,
            lp_rate,
            protocol_rate,
            reward_rate,
        )?;
        let input = curve_in(gross, input_vault_amount, output_vault_amount)?;
        result(
            input_vault_amount.checked_add(input)?,
            output_vault_amount.checked_sub(gross)?,
            input,
            output_amount,
            fee,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    const SOL: u128 = 1_000_000_000;
    // The owner's V1 schedule (per 1e6).
    const LP: u64 = 1_000;
    const BUY: u64 = 2_500;
    const SELL: u64 = 6_500;
    const REWARD: u64 = 10_000;

    fn parts(r: &SwapResult) -> (u128, u128, u128) {
        (r.trade_fee - r.protocol_fee, r.protocol_fee, r.creator_fee)
    }

    /// docs/V1_FEES.md section 5, "Worked examples".
    #[test]
    fn worked_examples() {
        let (x, y) = (100 * SOL, 1_000_000_000_000_000u128);
        // buy, 1 SOL in, Standard: 3,500,000 = LP 1,000,000 + DEEP 2,500,000
        let r = swap_base_input_v1(SOL, x, y, LP, BUY, 0, true).unwrap();
        assert_eq!(parts(&r), (1_000_000, 2_500_000, 0));
        assert_eq!(r.new_input_vault_amount - x, 996_500_000);
        assert_eq!(r.output_amount, 996_500_000 * y / (x + 996_500_000));
        // buy, 1 SOL in, Creator: 13,500,000 = LP 1,000,000 + reward 10,000,000 + DEEP 2,500,000
        let r = swap_base_input_v1(SOL, x, y, LP, BUY, REWARD, true).unwrap();
        assert_eq!(parts(&r), (1_000_000, 2_500_000, 10_000_000));
        assert_eq!(r.new_input_vault_amount - x, 986_500_000);

        // sell with a gross output of exactly 1 SOL: tokens in t = y / 99 into (y, 100 SOL)
        // gives floor(t * 100 SOL / (y + t)) = 1 SOL when y is a multiple of 99.
        let y = 990_000_000_000_000u128;
        let t = y / 99;
        // Standard: 7,500,000 = LP 1,000,000 + DEEP 6,500,000; the trader receives 992,500,000
        let r = swap_base_input_v1(t, y, x, LP, SELL, 0, false).unwrap();
        assert_eq!(x - r.new_output_vault_amount, SOL);
        assert_eq!(parts(&r), (1_000_000, 6_500_000, 0));
        assert_eq!(r.output_amount, 992_500_000);
        // Holder: 17,500,000 = LP 1,000,000 + reward 10,000,000 + DEEP 6,500,000 -> 982,500,000
        let r = swap_base_input_v1(t, y, x, LP, SELL, REWARD, false).unwrap();
        assert_eq!(parts(&r), (1_000_000, 6_500_000, 10_000_000));
        assert_eq!(r.output_amount, 982_500_000);
    }

    #[test]
    fn rounding_boundaries() {
        // the total rounds up: 1 unit at 0.35% still pays 1
        assert_eq!(fee_on(1, 3_500), Some(1));
        assert_eq!(fee_on(0, 3_500), Some(0));
        assert_eq!(fee_on(1_000_000, 3_500), Some(3_500));
        assert_eq!(fee_on(1_000_001, 3_500), Some(3_501));
        // parts are floored, DEEP takes the remainder
        let f = split_fee(1, LP, BUY, REWARD).unwrap();
        assert_eq!((f.lp, f.reward, f.protocol), (0, 0, 1));
        let f = split_fee(27, LP, BUY, REWARD).unwrap(); // 27 * 1000/13500 = 2, 27 * 10000/13500 = 20
        assert_eq!((f.lp, f.reward, f.protocol), (2, 20, 5));
        let f = split_fee(26, LP, BUY, REWARD).unwrap(); // 1.92 -> 1, 19.25 -> 19, rest 6
        assert_eq!((f.lp, f.reward, f.protocol), (1, 19, 6));
        // gross_up is the exact inverse bound of fee_on
        assert_eq!(gross_up(996_500, 3_500), Some(1_000_000));
        assert_eq!(gross_up(996_501, 3_500), Some(1_000_002));
        assert_eq!(gross_up(5, 0), Some(5));
        // zero rates: no fee at all
        let r = swap_base_input_v1(1_000, 1_000, 1_000, 0, 0, 0, true).unwrap();
        assert_eq!((r.output_amount, r.trade_fee, r.creator_fee), (500, 0, 0));
        let r = swap_base_output_v1(500, 1_000, 1_000, 0, 0, 0, false).unwrap();
        assert_eq!((r.input_amount, r.trade_fee, r.creator_fee), (1_000, 0, 0));
        assert_eq!(split_fee(1, 0, 0, 0), None);
    }

    #[test]
    fn dust_and_reserve_edges() {
        // 1 unit buy: the whole unit is fee, nothing is priced, nothing comes out
        let r = swap_base_input_v1(1, 1_000, 1_000, LP, BUY, REWARD, true).unwrap();
        assert_eq!((r.output_amount, r.protocol_fee, r.creator_fee), (0, 1, 0));
        // 1 unit sell that prices to 0: no fee, nothing out
        let r = swap_base_input_v1(1, 1_000_000, 1_000, LP, SELL, REWARD, false).unwrap();
        assert_eq!((r.output_amount, r.trade_fee, r.creator_fee), (0, 0, 0));
        // empty reserves: no trade
        assert_eq!(swap_base_input_v1(0, 0, 10, LP, BUY, 0, true), None);
        // asking for the whole output reserve (or more) is impossible in both directions
        assert_eq!(
            swap_base_output_v1(1_000, 1_000, 1_000, LP, BUY, 0, true),
            None
        );
        assert_eq!(
            swap_base_output_v1(1_001, 1_000, 1_000, LP, BUY, 0, true),
            None
        );
        // sell: the GROSS output must fit, so the largest net output is below the reserve
        assert_eq!(
            swap_base_output_v1(999, 1_000, 1_000, LP, SELL, REWARD, false),
            None
        );
        assert!(swap_base_output_v1(981, 1_000, 1_000, LP, SELL, REWARD, false).is_some());
        // a huge input never empties the output side
        let r = swap_base_input_v1(u64::MAX as u128, 5 * SOL, 1_000_000, LP, BUY, REWARD, true)
            .unwrap();
        assert!(r.new_output_vault_amount > 0);
    }

    #[test]
    fn rates_above_the_cap_are_rejected() {
        // one cap: the total of a side is at most 10%
        assert_eq!(total_rate(1_000, 49_000, 50_000), Some(100_000));
        assert_eq!(total_rate(1_000, 49_001, 50_000), None);
        assert_eq!(total_rate(1_000, 6_500, 50_000), Some(57_500));
        assert_eq!(total_rate(u64::MAX, 1, 0), None);
        assert_eq!(total_rate(0, 0, u64::MAX), None);
        for is_buy in [true, false] {
            assert!(swap_base_input_v1(SOL, SOL, SOL, 1_000, 49_000, 50_000, is_buy).is_some());
            assert_eq!(
                swap_base_input_v1(SOL, SOL, SOL, 1_000, 49_001, 50_000, is_buy),
                None
            );
            assert_eq!(
                swap_base_output_v1(1_000, SOL, SOL, 1_000, 49_000, 50_001, is_buy),
                None
            );
            // near 100% and above
            assert_eq!(
                swap_base_input_v1(SOL, SOL, SOL, 999_999, 0, 0, is_buy),
                None
            );
            assert_eq!(
                swap_base_output_v1(1_000, SOL, SOL, 0, 1_000_000, 0, is_buy),
                None
            );
            assert_eq!(
                swap_base_input_v1(SOL, SOL, SOL, 0, 0, u64::MAX, is_buy),
                None
            );
        }
        assert_eq!(gross_up(1, 1_000_000), None);
        assert_eq!(gross_up(1, 1_000_001), None);
    }

    /// `k` after the swap is at least `k` before. A product beyond u128 is larger than any
    /// `x * y` of two u64 reserves.
    fn k_never_decreases(r: &SwapResult, x: u128, y: u128) -> bool {
        match r
            .new_input_vault_amount
            .checked_mul(r.new_output_vault_amount)
        {
            Some(k) => k >= x * y,
            None => true,
        }
    }

    fn rates() -> impl Strategy<Value = (u64, u64, u64)> {
        // any split of any total up to the cap
        (0u64..=MAX_TOTAL_FEE_RATE).prop_flat_map(|total| {
            (0..=total).prop_flat_map(move |lp| {
                (0..=total - lp).prop_map(move |protocol| (lp, protocol, total - lp - protocol))
            })
        })
    }

    proptest! {
        #![proptest_config(ProptestConfig::with_cases(2_000))]

        #[test]
        fn exact_in_properties(
            amount in 1u64..=u64::MAX,
            x in 1u64..=u64::MAX,
            y in 1u64..=u64::MAX,
            (lp, protocol, reward) in rates(),
            is_buy in any::<bool>(),
        ) {
            let (a, x, y) = (amount as u128, x as u128, y as u128);
            let r = swap_base_input_v1(a, x, y, lp, protocol, reward, is_buy).unwrap();
            let t = (lp + protocol + reward) as u128;
            let (lp_fee, protocol_fee, reward_fee) = parts(&r);
            let total = lp_fee + protocol_fee + reward_fee;
            // k never decreases, even without counting the LP part
            prop_assert!(k_never_decreases(&r, x, y));
            prop_assert_eq!(r.input_amount, a);
            // the parts are floored pro rata, DEEP holds the remainder
            if t > 0 {
                prop_assert_eq!(lp_fee, total * lp as u128 / t);
                prop_assert_eq!(reward_fee, total * reward as u128 / t);
            } else {
                prop_assert_eq!(total, 0);
            }
            if is_buy {
                // total = ceil(in * T / 1e6), the rest is priced, the output is floored
                prop_assert_eq!(total, (a * t + 999_999) / 1_000_000);
                let net = a - total;
                prop_assert_eq!(r.new_input_vault_amount, x + net);
                prop_assert_eq!(r.output_amount, net * y / (x + net));
                prop_assert_eq!(r.new_output_vault_amount, y - r.output_amount);
            } else {
                // the fee comes off the floored gross output
                let gross = a * y / (x + a);
                prop_assert_eq!(total, (gross * t + 999_999) / 1_000_000);
                prop_assert_eq!(r.output_amount, gross - total);
                prop_assert_eq!(r.new_input_vault_amount, x + a);
                prop_assert_eq!(r.new_output_vault_amount, y - gross);
            }
            // the trader never gets the whole reserve
            prop_assert!(r.output_amount < y);
        }

        #[test]
        fn exact_out_properties(
            out in 1u64..=u64::MAX,
            x in 1u64..=u64::MAX,
            y in 100u64..=u64::MAX,
            (lp, protocol, reward) in rates(),
            is_buy in any::<bool>(),
        ) {
            let (x, y) = (x as u128, y as u128);
            // keep the request inside what the pool can pay (10% fee headroom on sells)
            let out = 1 + (out as u128) % (y - y / 9 - 2);
            let Some(r) = swap_base_output_v1(out, x, y, lp, protocol, reward, is_buy) else {
                // the only way to fail here: a buy whose curve input is far beyond u64
                prop_assert!(is_buy);
                let swapped = (x * out + (y - out - 1)) / (y - out);
                prop_assert!(swapped > u64::MAX as u128);
                return Ok(());
            };
            let t = (lp + protocol + reward) as u128;
            let (lp_fee, protocol_fee, reward_fee) = parts(&r);
            let total = lp_fee + protocol_fee + reward_fee;
            prop_assert!(k_never_decreases(&r, x, y));
            prop_assert_eq!(r.output_amount, out);
            if t > 0 {
                prop_assert_eq!(lp_fee, total * lp as u128 / t);
                prop_assert_eq!(reward_fee, total * reward as u128 / t);
            } else {
                prop_assert_eq!(total, 0);
            }
            // the fee is never less than the exact-in fee on the same gross amount
            if is_buy {
                prop_assert_eq!(r.new_input_vault_amount - x, r.input_amount - total);
                prop_assert!(total >= (r.input_amount * t + 999_999) / 1_000_000);
            } else {
                let gross = y - r.new_output_vault_amount;
                prop_assert_eq!(gross, out + total);
                prop_assert!(total >= (gross * t + 999_999) / 1_000_000);
            }
            // paying the exact-out input through exact-in yields at least the requested
            // output: exact-out never undercharges relative to exact-in
            if r.input_amount <= u64::MAX as u128 {
                let back =
                    swap_base_input_v1(r.input_amount, x, y, lp, protocol, reward, is_buy).unwrap();
                prop_assert!(back.output_amount >= out);
                // and one unit less of input can never buy MORE than that
                if r.input_amount > 1 {
                    let less = swap_base_input_v1(
                        r.input_amount - 1, x, y, lp, protocol, reward, is_buy,
                    )
                    .unwrap();
                    prop_assert!(less.output_amount <= back.output_amount);
                }
            }
        }

        /// A buy followed by selling everything bought never returns more quote than was
        /// paid: no free round trip, with or without fees.
        #[test]
        fn round_trip_never_profits(
            amount in 1u64..=1_000_000_000_000u64,
            x in 1_000u64..=1_000_000_000_000_000u64,
            y in 1_000u64..=u64::MAX,
            (lp, protocol, reward) in rates(),
        ) {
            let (a, x, y) = (amount as u128, x as u128, y as u128);
            let buy = swap_base_input_v1(a, x, y, lp, protocol, reward, true).unwrap();
            // reserves after the buy: the LP part joins the quote reserve
            let lp_fee = buy.trade_fee - buy.protocol_fee;
            let (x1, y1) = (buy.new_input_vault_amount + lp_fee, buy.new_output_vault_amount);
            if buy.output_amount == 0 {
                return Ok(());
            }
            let sell =
                swap_base_input_v1(buy.output_amount, y1, x1, lp, protocol, reward, false).unwrap();
            prop_assert!(sell.output_amount <= a);
        }
    }
}
