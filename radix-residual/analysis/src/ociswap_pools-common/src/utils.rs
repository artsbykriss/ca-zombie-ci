use scrypto::prelude::*;

pub fn assert_within_bounds<T: PartialOrd + Display>(
    value: T,
    min_value: T,
    max_value: T,
    value_name: &str,
) {
    assert!(
        min_value <= value && value <= max_value,
        "The provided {} is not in the allowed interval.\n Allowed: [{}, {}]\n Provided: {}",
        value_name,
        min_value.to_string(),
        max_value.to_string(),
        value.to_string()
    );
}

pub fn assert_fee_rate_within_bounds(fee_rate: Decimal, fee_rate_max: Decimal, fee_name: &str) {
    assert_within_bounds(fee_rate, dec!(0), fee_rate_max, fee_name);
}

pub fn sort_buckets(a_bucket: Bucket, b_bucket: Bucket) -> (Bucket, Bucket) {
    if a_bucket.resource_address() < b_bucket.resource_address() {
        return (a_bucket, b_bucket);
    }
    (b_bucket, a_bucket)
}
