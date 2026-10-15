use scrypto::prelude::*;

pub trait AttoDecimal {
    const ATTO: Decimal;
}

impl AttoDecimal for Decimal {
    const ATTO: Self = Self::from_attos(I192::ONE);
}

pub trait AttoPreciseDecimal {
    const ATTO: PreciseDecimal;
}

impl AttoPreciseDecimal for PreciseDecimal {
    const ATTO: Self = Self::from_precise_subunits(I256::ONE);
}

pub trait DivisibilityRounding {
    fn floor_to(&self, decimal_places: u8) -> Decimal;
    fn ceil_to(&self, decimal_places: u8) -> Decimal;
}

impl DivisibilityRounding for Decimal {
    fn floor_to(&self, decimal_places: u8) -> Decimal {
        self.checked_round(decimal_places, RoundingMode::ToNegativeInfinity)
            .unwrap()
    }

    fn ceil_to(&self, decimal_places: u8) -> Decimal {
        self.checked_round(decimal_places, RoundingMode::ToPositiveInfinity)
            .unwrap()
    }
}

impl DivisibilityRounding for PreciseDecimal {
    fn floor_to(&self, decimal_places: u8) -> Decimal {
        self.checked_round(decimal_places, RoundingMode::ToNegativeInfinity)
            .unwrap()
            .try_into()
            .unwrap()
    }

    fn ceil_to(&self, decimal_places: u8) -> Decimal {
        self.checked_round(decimal_places, RoundingMode::ToPositiveInfinity)
            .unwrap()
            .try_into()
            .unwrap()
    }
}
