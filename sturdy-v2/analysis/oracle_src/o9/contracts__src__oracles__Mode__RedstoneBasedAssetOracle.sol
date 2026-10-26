// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

/// @title RedstoneBasedAssetOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for assets based on redstone

interface IPriceCalculator {
  function priceOf(address asset) external view returns (uint256);

  function priceOfETH() external view returns (uint256);

  function getTimestampsFromLatestUpdate() external view returns (uint128 dataTimestamp, uint128 blockTimestamp);
}

contract RedstoneBasedAssetOracle {
    address private constant REDSTONE_ORACLE = 0x7C1DAAE7BB0688C9bfE3A918A4224041c7177256;
    address private constant WETH = 0x4200000000000000000000000000000000000006;

    uint8 public constant DECIMALS = 18;
    
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;
    address public immutable BORROW_ASSET;
    address public immutable COLLATERAL_ASSET;

    string public name;

    error BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        address _borrowAsset,
        address _collateralAsset,
        string memory _name
    ) {
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
        BORROW_ASSET = _borrowAsset;
        COLLATERAL_ASSET = _collateralAsset;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 borrowAssetPrice = _getPriceOfAsset(BORROW_ASSET);              // borrowAsset/USD   decimal 18
        uint256 collateralAssetPrice = _getPriceOfAsset(COLLATERAL_ASSET);      // collateralAsset/USD
        uint256 rate = borrowAssetPrice * 1e18 / collateralAssetPrice;          // borrowAsset/collateralAsset

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    function _getPriceOfAsset(address _asset) internal view returns (uint256) {
        (, uint128 blockTimestamp) = IPriceCalculator(REDSTONE_ORACLE).getTimestampsFromLatestUpdate();
        // If data is stale, revert
        if (block.timestamp - blockTimestamp > MAX_ORACLE_DELAY) {
            revert BAD_PRICE();
        }

        if (_asset == WETH) {
            return IPriceCalculator(REDSTONE_ORACLE).priceOfETH();
        }

        return IPriceCalculator(REDSTONE_ORACLE).priceOf(_asset);
    }
}
