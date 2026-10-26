// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "@pendle/core-v2/contracts/oracles/PendlePtOracleLib.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title ETHRSWETHPendlePTOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/rswETH Pendle PT
interface IrswETH {
    function rswETHToETHRate() external view returns (uint256);
}

contract ETHRSWETHPendlePTOracle {
    using PendlePtOracleLib for IPMarket;

    address private constant TOKEN = 0xFAe103DC9cf190eD75350761e95403b7b8aFa6c0;
    uint8 public constant DECIMALS = 18;
    
    address public immutable PENDLE_PT;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;
    uint32 public immutable TWAP_DURATION;

    string public name;

    error REDSTONE_BAD_PRICE();

    constructor(
        address _pendlePT,
        uint32 _twapDuration, 
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        name = _name;
        PENDLE_PT = _pendlePT;
        TWAP_DURATION = _twapDuration;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 rate = IrswETH(TOKEN).rswETHToETHRate();       // rswETH/ETH
        uint256 ptRate = IPMarket(PENDLE_PT).getPtToAssetRate(TWAP_DURATION);
        rate = (rate * ptRate) / 1e18;       //  PT/ETH

        rate = 1e36 / rate;     //  ETH/PT

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
