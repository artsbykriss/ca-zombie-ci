//! Pyth SOL/USD (sponsored `PriceUpdateV2` push feed, hand-decoded) and the USD valuation used
//! by the AUTO-SEND threshold. The decoder is the same layout as programs/deep-curve/src/pyth.rs
//! (same repository, MIT); see that file for the layout source and the on-chain verification.
//!
//! The price only decides WHETHER a push may happen (unclaimed worth >= the threshold). It never
//! changes HOW MUCH anyone receives, so a bad price can at worst delay or advance a push.

use anchor_lang::prelude::Pubkey;

/// Pyth Solana receiver program (owner of PriceUpdateV2 accounts). Same on devnet/mainnet.
pub const RECEIVER_PROGRAM_ID: Pubkey =
    Pubkey::from_str_const("rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ");
/// Sponsored SOL/USD PriceUpdateV2 account (shard 0). Same on devnet/mainnet.
pub const SOL_USD_PRICE_UPDATE: Pubkey =
    Pubkey::from_str_const("7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE");
/// Crypto.SOL/USD feed id.
pub const SOL_USD_FEED_ID: [u8; 32] = [
    0xef, 0x0d, 0x8b, 0x6f, 0xda, 0x2c, 0xeb, 0xa4, 0x1d, 0xa1, 0x5d, 0x40, 0x95, 0xd1, 0xda, 0x39,
    0x2a, 0x0d, 0x2f, 0x8e, 0xd0, 0xc6, 0xc7, 0xbc, 0x0f, 0x4c, 0xfa, 0xc8, 0xc2, 0x80, 0xb5, 0x6d,
];
/// sha256("account:PriceUpdateV2")[..8]
pub const PRICE_UPDATE_V2_DISCRIMINATOR: [u8; 8] = [34, 241, 35, 99, 157, 126, 244, 205];
/// Reject when conf / price > 2%.
pub const MAX_CONF_BPS: u128 = 200;
/// Upper bound for `RewardsConfig.max_price_age_seconds` (devnet's sponsored feed refreshes
/// about every 5 minutes; mainnet should use 120).
pub const MAX_PRICE_AGE_CAP_SECONDS: u32 = 600;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PriceView {
    pub feed_id: [u8; 32],
    pub fully_verified: bool,
    pub price: i64,
    pub conf: u64,
    pub exponent: i32,
    pub publish_time: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PriceError {
    Malformed,
    WrongFeed,
    NotFullyVerified,
    Stale,
    NonPositive,
    ConfidenceTooWide,
    Unsupported,
}

fn rd<const N: usize>(d: &[u8], o: usize) -> Result<[u8; N], PriceError> {
    d.get(o..o + N)
        .and_then(|s| s.try_into().ok())
        .ok_or(PriceError::Malformed)
}

pub fn decode_price_update(data: &[u8]) -> Result<PriceView, PriceError> {
    if rd::<8>(data, 0)? != PRICE_UPDATE_V2_DISCRIMINATOR {
        return Err(PriceError::Malformed);
    }
    let mut o = 8 + 32;
    let fully_verified = match rd::<1>(data, o)?[0] {
        0 => {
            o += 2;
            false
        }
        1 => {
            o += 1;
            true
        }
        _ => return Err(PriceError::Malformed),
    };
    let feed_id = rd::<32>(data, o)?;
    o += 32;
    let price = i64::from_le_bytes(rd::<8>(data, o)?);
    let conf = u64::from_le_bytes(rd::<8>(data, o + 8)?);
    let exponent = i32::from_le_bytes(rd::<4>(data, o + 16)?);
    let publish_time = i64::from_le_bytes(rd::<8>(data, o + 20)?);
    Ok(PriceView {
        feed_id,
        fully_verified,
        price,
        conf,
        exponent,
        publish_time,
    })
}

pub fn validate(p: &PriceView, now: i64, max_age_seconds: u32) -> Result<(), PriceError> {
    if p.feed_id != SOL_USD_FEED_ID {
        return Err(PriceError::WrongFeed);
    }
    if !p.fully_verified {
        return Err(PriceError::NotFullyVerified);
    }
    if now.saturating_sub(p.publish_time) > max_age_seconds as i64 {
        return Err(PriceError::Stale);
    }
    if p.price <= 0 {
        return Err(PriceError::NonPositive);
    }
    if (p.conf as u128) * 10_000 > (p.price as u128) * MAX_CONF_BPS {
        return Err(PriceError::ConfidenceTooWide);
    }
    if !(-18..=18).contains(&p.exponent) {
        return Err(PriceError::Unsupported);
    }
    Ok(())
}

/// USD value of `lamports` in micro-dollars (1e-6 USD), rounded DOWN (a push needs the full
/// threshold): `lamports / 1e9 · price · 10^expo · 1e6 = lamports · price · 10^expo / 1e3`.
pub fn lamports_usd_micros(lamports: u64, price: i64, exponent: i32) -> Option<u128> {
    if price <= 0 || !(-18..=18).contains(&exponent) {
        return None;
    }
    let pow = 10u128.checked_pow(exponent.unsigned_abs())?;
    let num = (lamports as u128).checked_mul(price as u128)?;
    if exponent <= 0 {
        Some(num / pow.checked_mul(1_000)?)
    } else {
        Some(num.checked_mul(pow)? / 1_000)
    }
}

/// USD value of `amount` base units of a USD stablecoin with `decimals`, valued at face
/// ($1 per whole token), in micro-dollars, rounded down.
pub fn stable_usd_micros(amount: u64, decimals: u8) -> Option<u128> {
    let pow = 10u128.checked_pow(decimals as u32)?;
    Some((amount as u128).checked_mul(1_000_000)? / pow)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sol_valuation() {
        // 0.1 SOL at $200.00000000 (expo -8) = $20 exactly
        assert_eq!(
            lamports_usd_micros(100_000_000, 20_000_000_000, -8),
            Some(20_000_000)
        );
        // one lamport less is below $20
        assert!(lamports_usd_micros(99_999_999, 20_000_000_000, -8).unwrap() < 20_000_000);
        assert_eq!(lamports_usd_micros(1_000_000_000, 1, 2), Some(100_000_000));
        assert_eq!(lamports_usd_micros(1, 0, -8), None);
        assert_eq!(lamports_usd_micros(1, 1, 19), None);
        assert_eq!(
            lamports_usd_micros(u64::MAX, i64::MAX, -8).map(|_| ()),
            Some(())
        );
    }

    #[test]
    fn stable_valuation() {
        assert_eq!(stable_usd_micros(20_000_000, 6), Some(20_000_000));
        assert_eq!(stable_usd_micros(19_999_999, 6), Some(19_999_999));
        assert_eq!(stable_usd_micros(2_000_000_000, 8), Some(20_000_000));
        assert_eq!(stable_usd_micros(1, 9), Some(0));
    }

    fn fresh(t: i64) -> PriceView {
        PriceView {
            feed_id: SOL_USD_FEED_ID,
            fully_verified: true,
            price: 12_000_000_000,
            conf: 1_000_000,
            exponent: -8,
            publish_time: t,
        }
    }

    #[test]
    fn price_checks() {
        assert_eq!(validate(&fresh(1_000), 1_120, 120), Ok(()));
        assert_eq!(validate(&fresh(1_000), 1_121, 120), Err(PriceError::Stale));
        let mut p = fresh(1_000);
        p.fully_verified = false;
        assert_eq!(validate(&p, 1_000, 120), Err(PriceError::NotFullyVerified));
        let mut p = fresh(1_000);
        p.conf = p.price as u64; // 100%
        assert_eq!(validate(&p, 1_000, 120), Err(PriceError::ConfidenceTooWide));
        let mut p = fresh(1_000);
        p.feed_id[0] ^= 1;
        assert_eq!(validate(&p, 1_000, 120), Err(PriceError::WrongFeed));
    }
}
