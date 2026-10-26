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

/// @title USDCUSDYOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for USDC/USDY
interface IRUSDY {
    function oracle() external view returns (address);
}

interface IUSDYOracle {
    function getPriceData() external view returns (uint256, uint256);
}

contract USDCUSDYOracle {
    IRUSDY private constant RUSDY = IRUSDY(0xaf37c1167910ebC994e266949387d2c7C326b879);
    address private constant USDC_USD_CHAINLINK = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    uint8 public constant DECIMALS = 18;

    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error CHAINLINK_BAD_PRICE();
    error REDSTONE_BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price between USDC and USDY
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // Get USDC price from chainlink
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(USDC_USD_CHAINLINK)
            .latestRoundData();     // USDC/USD     decimals 8
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        (uint256 usdyPriceInUSD, uint256 timestamp) = IUSDYOracle(RUSDY.oracle()).getPriceData();   // USDY/USD decimals 18
        // If data is stale or negative, set bad data to true and return
        if (block.timestamp - timestamp > MAX_ORACLE_DELAY) {
            revert CHAINLINK_BAD_PRICE();
        }

        // _answer is 8 decimals, + 10 decimals - USDC decimals + USDY decimals + oracle decimals 10-6+18+18=40
        uint256 rate = uint256(_answer) * 1e40 / usdyPriceInUSD;     // USDC/USDY

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}