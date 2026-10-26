// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "@pendle/core-v2/contracts/oracles/PendlePtOracleLib.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title ETHEETHPendlePTOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/eETH Pendle PT
interface IWeETH {
    function getWeETHByeETH(uint256 _eETHAmount) external view returns (uint256);
}

contract ETHEETHPendlePTOracle {
    using PendlePtOracleLib for IPMarket;

    address private constant WEETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address private constant REDSTONE_WEETH_ETH_PRICE = 0x8751F736E94F6CD167e8C5B97E245680FbD9CC36;
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
        uint256 weETHRate = IWeETH(WEETH).getWeETHByeETH(1e18);     //  eETH/weETH
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(REDSTONE_WEETH_ETH_PRICE).latestRoundData();
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert REDSTONE_BAD_PRICE();
        }
        uint256 rate = weETHRate * uint256(_answer) / 1e8;       // eETH/ETH, redstone price decimal is 8
        uint256 ptRate = IPMarket(PENDLE_PT).getPtToAssetRate(TWAP_DURATION);
        rate = (rate * ptRate) / 1e18;       //  PT/ETH
        rate = 1e36 / rate;     // ETH/PT

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
