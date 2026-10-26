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

/// @title ETHRedStoneOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/asset (has RedStone price)
contract ETHRedStoneOracle {
    uint8 public constant DECIMALS = 18;
    
    address public immutable REDSTONE_ASSET_ETH_PRICE;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error REDSTONE_BAD_PRICE();

    constructor(
        address _redstoneAddress,
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        name = _name;
        REDSTONE_ASSET_ETH_PRICE = _redstoneAddress;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(REDSTONE_ASSET_ETH_PRICE).latestRoundData();
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert REDSTONE_BAD_PRICE();
        }
        uint256 rate = 1e26 / uint256(_answer);       // ETH/ASSET, redstone price decimal is 8

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}