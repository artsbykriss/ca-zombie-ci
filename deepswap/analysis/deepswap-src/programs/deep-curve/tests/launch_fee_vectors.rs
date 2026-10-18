//! fixtures/launch-fee-vectors.json is shared with packages/sdk (quoteLaunchFeeLamports);
//! both must produce identical lamports / errors.

use deep_curve::pyth::{launch_fee_lamports, PriceError};
use serde_json::Value;

const VECTORS: &str = include_str!("../../../fixtures/launch-fee-vectors.json");

#[test]
fn launch_fee_matches_shared_vectors() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let cases = v["cases"].as_array().unwrap();
    assert!(cases.len() >= 10);
    for c in cases {
        let cents = c["usdCents"].as_u64().unwrap() as u16;
        let price: i64 = c["price"].as_str().unwrap().parse().unwrap();
        let expo = c["exponent"].as_i64().unwrap() as i32;
        let got = launch_fee_lamports(cents, price, expo);
        match c["expect"]["lamports"].as_str() {
            Some(l) => assert_eq!(got, Ok(l.parse().unwrap()), "{c}"),
            None => {
                let want = match c["expect"]["error"].as_str().unwrap() {
                    "NonPositive" => PriceError::NonPositive,
                    "Unsupported" => PriceError::Unsupported,
                    e => panic!("unknown error {e}"),
                };
                assert_eq!(got, Err(want), "{c}");
            }
        }
    }
}
