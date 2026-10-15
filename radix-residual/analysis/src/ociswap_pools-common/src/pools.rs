use scrypto::prelude::*;

#[derive(ScryptoSbor, ManifestSbor, Clone, Copy, Debug, PartialEq)]
pub enum SwapType {
    BuyX,
    SellX,
}

pub fn check_and_sort_addresses(
    a_address: ResourceAddress,
    b_address: ResourceAddress,
) -> (ResourceAddress, ResourceAddress) {
    assert_ne!(
        a_address, b_address,
        "Sorting addresses failed: The token addresses must be different."
    );

    if a_address < b_address {
        (a_address, b_address)
    } else {
        (b_address, a_address)
    }
}

pub fn lp_address(liquidity_pool: &Global<TwoResourcePool>) -> Option<ResourceAddress> {
    let lp_address_global = liquidity_pool
        .get_metadata::<&str, GlobalAddress>("pool_unit")
        .ok()??;
    lp_address_global.try_into().ok()
}

pub fn token_symbol(token_address: ResourceAddress) -> Option<String> {
    ResourceManager::from_address(token_address)
        .get_metadata::<&str, String>("symbol")
        .ok()?
}
