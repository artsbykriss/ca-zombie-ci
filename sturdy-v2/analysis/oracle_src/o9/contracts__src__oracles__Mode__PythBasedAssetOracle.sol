// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title PythBasedAssetOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for assets based on pyth

interface IPyth {
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    function getPriceUnsafe(bytes32 id) external view returns (Price memory price);
}

contract PythBasedAssetOracle {
    address private constant PYTH_ORACLE = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    uint8 public constant DECIMALS = 18;
    
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;
    uint256 public immutable NORMALIZATION;
    bytes32 public immutable BORROW_ASSET_PRICE_ID;
    bytes32 public immutable COLLATERAL_ASSET_PRICE_ID;

    string public name;

    error BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        address _borrowAsset,
        address _collateralAsset,
        bytes32 _borrowAssetPriceId,
        bytes32 _collateralAssetPriceId,
        string memory _name
    ) {
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
        BORROW_ASSET_PRICE_ID = _borrowAssetPriceId;
        COLLATERAL_ASSET_PRICE_ID = _collateralAssetPriceId;
        
        uint8 _multiplyDecimals = uint8(uint32(-IPyth(PYTH_ORACLE).getPriceUnsafe(BORROW_ASSET_PRICE_ID).expo));
        uint8 _divideDecimals = uint8(uint32(-IPyth(PYTH_ORACLE).getPriceUnsafe(COLLATERAL_ASSET_PRICE_ID).expo));
        NORMALIZATION =
            10 **
                (18 +
                    _multiplyDecimals -
                    _divideDecimals +
                    IERC20Metadata(_borrowAsset).decimals() -
                    IERC20Metadata(_collateralAsset).decimals());
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        IPyth.Price memory price1 = IPyth(PYTH_ORACLE).getPriceUnsafe(BORROW_ASSET_PRICE_ID);     // borrowAsset/USD
        // If data is stale or negative, set bad data to true and return
        if (price1.price <= 0 || (block.timestamp - price1.publishTime > MAX_ORACLE_DELAY)) {
            revert BAD_PRICE();
        }

        IPyth.Price memory price2 = IPyth(PYTH_ORACLE).getPriceUnsafe(COLLATERAL_ASSET_PRICE_ID);   // collateralAsset/USD
        // If data is stale or negative, set bad data to true and return
        if (price2.price <= 0 || (block.timestamp - price2.publishTime > MAX_ORACLE_DELAY)) {
            revert BAD_PRICE();
        }

        uint256 rate = uint256(1e36) * uint256(uint64(price1.price)) / uint256(uint64(price2.price)) / NORMALIZATION;    //borrowAsset/collateralAsset

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
