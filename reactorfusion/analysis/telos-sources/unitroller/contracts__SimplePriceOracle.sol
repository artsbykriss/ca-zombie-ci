// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";

contract SimplePriceOracle is PriceOracle, MainDemoConsumerBase {
    mapping(bytes32 => uint256) rawPrices;

    function push(bytes32[] memory tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            rawPrices[tokens[i]] = getOracleNumericValueFromTxMsg(tokens[i]);
        }
    }

    function getUnderlyingPrice(
        CToken cToken
    ) public view override returns (uint256) {
        return
            rawPrices[cToken.redStoneFeedID()] *
            (10 ** (28 - cToken.decimals()));
    }
}
