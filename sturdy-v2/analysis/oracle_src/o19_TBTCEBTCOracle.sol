// SPDX-License-Identifier: AGPL-v3.0
pragma solidity ^0.8.21;


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title TBTCEBTCOracle
/// @author Jason (Sturdy) https://github.com/iris112
// @notice  An oracle for tBTC/eBTC
interface IRateProvider {
    function getRate() external view returns (uint256);
}

contract TBTCEBTCOracle {
    address private constant TBTC_USD_CHAINLINK = 0x8350b7De6a6a2C1368E7D4Bd968190e13E354297;
    address private constant BTC_USD_CHAINLINK = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address private constant EBTC_BTC_CHAINLINK = 0x56c08bF6Ab8e08A7eADeb4E053DA653334E8E549;

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

    /// @notice The ```getPrices``` function is intended to return price of collateral asset based on the lending asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // Get TBTC price from chainlink
        (, int256 _answer1, , uint256 _updatedAt1, ) = AggregatorV3Interface(TBTC_USD_CHAINLINK)
            .latestRoundData();     // TBTC/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer1 <= 0 || (block.timestamp - _updatedAt1 > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }

        // Get BTC price from chainlink
        (, int256 _answer2, , uint256 _updatedAt2, ) = AggregatorV3Interface(BTC_USD_CHAINLINK)
            .latestRoundData();     // BTC/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer2 <= 0 || (block.timestamp - _updatedAt2 > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }

        // Get EBTC price from chainlink
        (, int256 _answer3, ,  , ) = AggregatorV3Interface(EBTC_BTC_CHAINLINK)
            .latestRoundData();     // EBTC/BTC
        // If data is stale or negative, set bad data to true and return
        if (_answer3 <= 0) {
            revert CHAINLINK_BAD_PRICE();
        }

        uint256 rate = uint256(_answer3) * uint256(_answer2) / 1e8;          // EBTC/USD

        // - TBTC decimals + EBTC decimals + oracle decimals -18+8+18=8
        rate = uint256(_answer1) * 1e8 / rate;          // TBTC/EBTC

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}