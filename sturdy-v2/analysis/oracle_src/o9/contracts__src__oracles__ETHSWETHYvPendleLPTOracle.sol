// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "@pendle/core-v2/contracts/oracles/PendleLpOracleLib.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC4626 } from "../interfaces/IERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title ETHSWETHYvPendleLPTOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/Yearn Vault swETH Pendle LPT
interface IswETH {
    function swETHToETHRate() external view returns (uint256);
}

contract ETHSWETHYvPendleLPTOracle {
    using PendleLpOracleLib for IPMarket;

    address private constant SWETH = 0xf951E335afb289353dc249e82926178EaC7DEd78;
    address private constant REDSTONE_SWETH_ETH_PRICE = 0x061bB36F8b67bB922937C102092498dcF4619F86;
    uint8 public constant DECIMALS = 18;
    
    address public immutable PENDLE_LPT;
    address public immutable YEARN_VAULT;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;
    uint32 public immutable TWAP_DURATION;
    uint8 public immutable ASSET_DECIMALS;

    string public name;

    error REDSTONE_BAD_PRICE();

    constructor(
        address _yearnVaultOfpendleLPT, 
        uint32 _twapDuration, 
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        YEARN_VAULT = _yearnVaultOfpendleLPT;
        PENDLE_LPT = IERC4626(YEARN_VAULT).asset();
        ASSET_DECIMALS = IERC20Metadata(PENDLE_LPT).decimals();
        TWAP_DURATION = _twapDuration;
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 swETHRate = IswETH(SWETH).swETHToETHRate();
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(REDSTONE_SWETH_ETH_PRICE).latestRoundData();
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert REDSTONE_BAD_PRICE();
        }
        swETHRate = Math.min(uint256(_answer) * 1e10, swETHRate);       // redstone price decimal is 8
        
        uint256 lpRate = IPMarket(PENDLE_LPT).getLpToAssetRate(TWAP_DURATION);
        uint256 rate = (swETHRate * lpRate) / 1e18;       //  LPT/ETH
        rate = IERC4626(YEARN_VAULT).convertToShares(10 ** ASSET_DECIMALS) * rate / 1e18;       //YV_LP/ETH
        rate = 1e36 / rate;     // ETH/YV_LP

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
