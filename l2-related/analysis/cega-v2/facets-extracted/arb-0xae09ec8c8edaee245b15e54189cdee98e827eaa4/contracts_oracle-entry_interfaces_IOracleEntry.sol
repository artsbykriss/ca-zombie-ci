// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface IOracleEntry {
    enum DataSource {
        None,
        Pyth,
        Pendle
    }

    /**
     * @dev Emitted when a data source adapter is set.
     * @param dataSource The data source for which the adapter is set.
     * @param adapter The address of the adapter.
     */
    event DataSourceAdapterSet(DataSource dataSource, address adapter);

    event GlobalPriceOverrideSet(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp,
        uint128 price
    );

    /**
     * @notice Gets the price of an asset at a specific timestamp using a data source.
     * @param asset The address of the asset.
     * @param timestamp The timestamp for which the price is required.
     * @param dataSource The data source to use for fetching the price.
     * @return The price of the asset at the specified timestamp.
     */
    function getSinglePrice(
        address asset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /**
     * @notice Gets the price of a base asset in terms of a quote asset at a specific timestamp using a data source.
     * @param baseAsset The address of the base asset.
     * @param quoteAsset The address of the quote asset.
     * @param timestamp The timestamp for which the price is required.
     * @param dataSource The data source to use for fetching the price.
     * @return The price of the base asset in terms of the quote asset at the specified timestamp.
     */
    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /**
     * @notice Sets the adapter for a specific data source.
     * @param dataSource The data source for which to set the adapter.
     * @param adapter The address of the adapter.
     */
    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external;

    /**
     * @notice Returns the target number of decimals for price values.
     * @return The number of decimals.
     */
    function getTargetDecimals() external pure returns (uint8);

    /**
     * @notice Sets global price overrides for a set of base and quote assets.
     * @param baseAssets The addresses of the base assets.
     * @param quoteAssets The addresses of the quote assets.
     * @param timestamps The timestamps at which the prices are set.
     * @param prices The prices to set for each pair of base and quote assets.
     */
    function setGlobalPriceOverride(
        address[] calldata baseAssets,
        address[] calldata quoteAssets,
        uint40[] calldata timestamps,
        uint128[] calldata prices
    ) external;
}
