// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import { ICurvePool } from "../interfaces/Curve/ICurvePool.sol";
import { IYearnVault } from "../interfaces/Yearn/IYearnVault.sol";

/// @title PxETHYvStETHPxETHOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for PxETH/YvStETHPxETH

contract PxETHYvStETHPxETHOracle {
    address public constant STETH_CHAINLINK = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;
    address public constant CURVE_PXETH_STETH_POOL = 0x6951bDC4734b9f7F3E1B74afeBC670c736A0EDB6;
    address public constant YEARN_PXETH_STETH_VAULT = 0x2c8a33C66c00264316Ea4E4433e86A386Eb6ECBf;
    uint8 public constant DECIMALS = 18;

    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error CHAINLINK_BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 rate = _getYvStETHPxETHPrice();    // Assume 1PxETH = 1ETH
        rate = 1e36 / rate;     // PxETH/YvStETHPxETH

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    /**
     * @dev Get price for Yearn Curve-stETH-pxETH LP Token, 1 pxETH <= 1ETH
     */
    function _getYvStETHPxETHPrice() internal view returns (uint256) {
        // Get stETH price from chainlink
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(STETH_CHAINLINK)
            .latestRoundData();     // stETH/ETH
        // If data is stale or negative, set bad data to true and return
        // if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
        //     revert CHAINLINK_BAD_PRICE();
        // }

        uint256 minPrice = Math.min(uint256(_answer), 1e18);
        uint256 curveLPTokenPrice = (ICurvePool(CURVE_PXETH_STETH_POOL).get_virtual_price() * minPrice) / 1e18;

        return curveLPTokenPrice;
    }
}
