//! Pyth SOL/USD via the sponsored `PriceUpdateV2` push feed, hand-decoded.
//!
//! We don't depend on `pyth-solana-receiver-sdk` (Apache-2.0, fine license-wise) because
//! it pins its own Anchor version via the pyth-crosschain workspace; the layout below is
//! taken from pyth-crosschain `target_chains/solana/pyth_solana_receiver_sdk/src/
//! price_update.rs` and `pythnet/pythnet_sdk/src/messages.rs`:
//!
//! ```text
//! PriceUpdateV2 (anchor account "account:PriceUpdateV2")
//!   write_authority: Pubkey
//!   verification_level: enum { Partial { num_signatures: u8 } = 0, Full = 1 }  (borsh)
//!   price_message: PriceFeedMessage {
//!     feed_id: [u8; 32], price: i64, conf: u64, exponent: i32, publish_time: i64,
//!     prev_publish_time: i64, ema_price: i64, ema_conf: u64 }
//!   posted_slot: u64
//! ```
//!
//! Verified read-only on devnet and mainnet (2026-10-03): account
//! 7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE (push-oracle PDA [shard 0 u16 LE, feed_id]
//! of pythWSnswVUd12oZpeFP8e9CVaEqJg25g1Vtc2biRsT) exists on both, is owned by the
//! receiver rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ, verification Full, expo -8.

use anchor_lang::prelude::Pubkey;

/// Pyth Solana receiver program (owner of PriceUpdateV2 accounts). Same on devnet/mainnet.
pub const RECEIVER_PROGRAM_ID: Pubkey =
    Pubkey::from_str_const("rec5EKMGg6MxZYaMdyBfgwp4d5rB9T1VQH5pJv5LtFJ");
/// Sponsored SOL/USD PriceUpdateV2 account (shard 0). Same on devnet/mainnet.
pub const SOL_USD_PRICE_UPDATE: Pubkey =
    Pubkey::from_str_const("7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE");
/// Crypto.SOL/USD feed id (hermes.pyth.network/v2/price_feeds).
pub const SOL_USD_FEED_ID: [u8; 32] = [
    0xef, 0x0d, 0x8b, 0x6f, 0xda, 0x2c, 0xeb, 0xa4, 0x1d, 0xa1, 0x5d, 0x40, 0x95, 0xd1, 0xda, 0x39,
    0x2a, 0x0d, 0x2f, 0x8e, 0xd0, 0xc6, 0xc7, 0xbc, 0x0f, 0x4c, 0xfa, 0xc8, 0xc2, 0x80, 0xb5, 0x6d,
];
/// sha256("account:PriceUpdateV2")[..8]
pub const PRICE_UPDATE_V2_DISCRIMINATOR: [u8; 8] = [34, 241, 35, 99, 157, 126, 244, 205];
/// Maximum price age of every build except a `devnet` one (seconds). Mainnet uses this.
pub const DEFAULT_MAX_PRICE_AGE_SECONDS: i64 = 120;
/// Maximum price age of a build compiled with the `devnet` Cargo feature (seconds). Pyth
/// refreshes the sponsored account on devnet only about every 5 minutes, so with 120 s most
/// launches would fail there while a USD launch fee is set (owner decision 2026-10-06).
pub const DEVNET_MAX_PRICE_AGE_SECONDS: i64 = 600;
/// Reject prices older than this (seconds, vs. Clock::unix_timestamp). 120 s unless the
/// program is built with `--features devnet`, which only the devnet release build
/// (scripts/deploy-deepswap-devnet.mjs) enables. A plain `cargo build-sbf` / `anchor build`
/// gets 120 s, so a mainnet build cannot pick up 600 s by accident; mainnet-preflight also
/// FAILs on a binary that contains `DEVNET_BUILD_MARKER`.
#[cfg(not(feature = "devnet"))]
pub const MAX_PRICE_AGE_SECONDS: i64 = DEFAULT_MAX_PRICE_AGE_SECONDS;
#[cfg(feature = "devnet")]
pub const MAX_PRICE_AGE_SECONDS: i64 = DEVNET_MAX_PRICE_AGE_SECONDS;
/// Logged by `create_token` when a devnet build charges a launch fee. The bytes exist only
/// in a `devnet` binary, which is how mainnet-preflight recognizes one (SDK mirror:
/// packages/sdk/src/pyth.ts `DEEP_CURVE_DEVNET_BUILD_MARKER`).
pub const DEVNET_BUILD_MARKER: &str = "DEEP devnet build: Pyth max price age 600 s";
/// Reject when conf / price > 2%.
pub const MAX_CONF_BPS: u128 = 200;

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
    /// wrong discriminator, truncated data, bad enum tag
    Malformed,
    WrongFeed,
    NotFullyVerified,
    Stale,
    NonPositive,
    ConfidenceTooWide,
    /// exponent outside ±18 or arithmetic overflow
    Unsupported,
}

fn rd<const N: usize>(d: &[u8], o: usize) -> Result<[u8; N], PriceError> {
    d.get(o..o + N)
        .and_then(|s| s.try_into().ok())
        .ok_or(PriceError::Malformed)
}

/// Decodes the fields we use from a PriceUpdateV2 account's data.
pub fn decode_price_update(data: &[u8]) -> Result<PriceView, PriceError> {
    if rd::<8>(data, 0)? != PRICE_UPDATE_V2_DISCRIMINATOR {
        return Err(PriceError::Malformed);
    }
    let mut o = 8 + 32; // discriminator + write_authority
    let fully_verified = match rd::<1>(data, o)?[0] {
        0 => {
            o += 2; // Partial { num_signatures: u8 }
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

/// All the checks create_token applies, in order (fail closed).
pub fn validate(p: &PriceView, now: i64) -> Result<(), PriceError> {
    if p.feed_id != SOL_USD_FEED_ID {
        return Err(PriceError::WrongFeed);
    }
    if !p.fully_verified {
        return Err(PriceError::NotFullyVerified);
    }
    if now.saturating_sub(p.publish_time) > MAX_PRICE_AGE_SECONDS {
        return Err(PriceError::Stale);
    }
    if p.price <= 0 {
        return Err(PriceError::NonPositive);
    }
    // conf / price <= 2%  ⇔  conf * 10_000 <= price * 200
    if (p.conf as u128) * 10_000 > (p.price as u128) * MAX_CONF_BPS {
        return Err(PriceError::ConfidenceTooWide);
    }
    Ok(())
}

/// Lamports for `usd_cents` at a SOL/USD price of `price · 10^exponent` USD per SOL,
/// rounded UP (protocol's favour):
///
/// ```text
/// lamports = usd_cents/100 · 1e9 / (price · 10^expo) = usd_cents · 10^7 · 10^-expo / price
/// ```
pub fn launch_fee_lamports(usd_cents: u16, price: i64, exponent: i32) -> Result<u64, PriceError> {
    if price <= 0 {
        return Err(PriceError::NonPositive);
    }
    if !(-18..=18).contains(&exponent) {
        return Err(PriceError::Unsupported);
    }
    let pow = 10u128.pow(exponent.unsigned_abs());
    let (num, den) = if exponent <= 0 {
        ((usd_cents as u128) * 10_000_000 * pow, price as u128)
    } else {
        ((usd_cents as u128) * 10_000_000, (price as u128) * pow)
    };
    u64::try_from(num.div_ceil(den)).map_err(|_| PriceError::Unsupported)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fresh(publish_time: i64) -> PriceView {
        PriceView {
            feed_id: SOL_USD_FEED_ID,
            fully_verified: true,
            price: 12_000_000_000,
            conf: 1_000_000,
            exponent: -8,
            publish_time,
        }
    }

    /// Default build (mainnet and every build without `--features devnet`): 120 s.
    #[cfg(not(feature = "devnet"))]
    #[test]
    fn default_build_max_price_age_is_120_seconds() {
        assert_eq!(MAX_PRICE_AGE_SECONDS, 120);
        assert_eq!(validate(&fresh(1_000), 1_120), Ok(()));
        assert_eq!(validate(&fresh(1_000), 1_121), Err(PriceError::Stale));
        assert_eq!(validate(&fresh(1_000), 1_300), Err(PriceError::Stale));
    }

    /// `cargo test -p deep-curve --features devnet`: the devnet build accepts up to 600 s.
    #[cfg(feature = "devnet")]
    #[test]
    fn devnet_build_max_price_age_is_600_seconds() {
        assert_eq!(MAX_PRICE_AGE_SECONDS, 600);
        assert_eq!(validate(&fresh(1_000), 1_300), Ok(()));
        assert_eq!(validate(&fresh(1_000), 1_600), Ok(()));
        assert_eq!(validate(&fresh(1_000), 1_601), Err(PriceError::Stale));
    }

    #[test]
    fn fee_examples() {
        // $2 at $120.30243981 (expo -8) = 0.0166247668... SOL, rounded up
        assert_eq!(launch_fee_lamports(200, 12_030_243_981, -8), Ok(16_624_767));
        assert_eq!(launch_fee_lamports(0, 12_030_243_981, -8), Ok(0));
        // $20 at exactly $100.00000000 → 0.2 SOL
        assert_eq!(
            launch_fee_lamports(2_000, 10_000_000_000, -8),
            Ok(200_000_000)
        );
        // positive exponent path: price 1 · 10^2 = $100
        assert_eq!(launch_fee_lamports(2_000, 1, 2), Ok(200_000_000));
        assert_eq!(launch_fee_lamports(1, 0, -8), Err(PriceError::NonPositive));
        assert_eq!(launch_fee_lamports(1, 1, 19), Err(PriceError::Unsupported));
    }
}
