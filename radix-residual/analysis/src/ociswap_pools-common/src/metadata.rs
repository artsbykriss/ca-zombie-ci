use scrypto::prelude::*;

pub fn assert_component_packages_are_approved(
    metadata_key: &str,
    component_addresses: Vec<ComponentAddress>,
) {
    let metadata_package_addresses = addresses_from_metadata(&metadata_key);

    for component_address in component_addresses {
        let blueprint_id = ScryptoVmV1Api::object_get_blueprint_id(&component_address.into());
        assert!(
            metadata_package_addresses.contains(&blueprint_id.package_address),
            "The package address of {} is not approved under the key {} in the pool package metadata.",
            Runtime::bech32_encode_address(component_address),
            metadata_key
        );
    }
}

pub fn assert_components_are_approved(
    metadata_key: &str,
    component_addresses: Vec<ComponentAddress>,
) {
    let metadata_component_addresses = addresses_from_metadata(&metadata_key);

    for component_address in component_addresses {
        assert!(
            metadata_component_addresses.contains(&component_address),
            "{} is not approved under the key {} in the pool package metadata.",
            Runtime::bech32_encode_address(component_address),
            metadata_key
        );
    }
}

pub fn addresses_from_metadata<T>(key: &str) -> Vec<T>
where
    T: TryFrom<GlobalAddress>,
{
    let own_package: Package = Runtime::package_address().into();
    let metadata_value: Option<Vec<GlobalAddress>> = own_package.get_metadata(key).ok().flatten();

    metadata_value
        .into_iter()
        .flatten()
        .filter_map(|address| address.try_into().ok())
        .collect()
}

pub fn address_from_metadata<T>(key: &str) -> Option<T>
where
    T: TryFrom<GlobalAddress>,
{
    let own_package: Package = Runtime::package_address().into();
    let metadata_value: Option<GlobalAddress> = own_package.get_metadata(key).ok().flatten();

    metadata_value.and_then(|address| address.try_into().ok())
}
