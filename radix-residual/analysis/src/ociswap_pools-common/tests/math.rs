#[cfg(test)]
mod math {
    use common::math::*;
    use pretty_assertions::assert_eq;
    use scrypto::prelude::*;

    #[test]
    fn test_precise_decimal_floor_to_decimal_positive() {
        assert_eq!(
            pdec!("0.0000000000000000016").floor_to(18),
            dec!("0.000000000000000001")
        )
    }

    #[test]
    fn test_precise_decimal_floor_to_decimal_negative() {
        assert_eq!(
            pdec!("-0.0000000000000000014").floor_to(18),
            dec!("-0.000000000000000002")
        )
    }

    #[test]
    fn test_precise_decimal_ceil_to_decimal_positive() {
        assert_eq!(
            pdec!("0.0000000000000000011").ceil_to(18),
            dec!("0.000000000000000002")
        )
    }

    #[test]
    fn test_precise_decimal_ceil_to_decimal_negative() {
        assert_eq!(
            pdec!("-0.0000000000000000016").ceil_to(18),
            dec!("-0.000000000000000001")
        )
    }
}
