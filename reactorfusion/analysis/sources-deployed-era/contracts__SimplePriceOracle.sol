// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

interface PriceFeed {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

contract SimplePriceOracle is PriceOracle, Ownable {
    using SafeCast for int256; 
    mapping(CToken => PriceFeed) priceFeeds;

    constructor() {
        priceFeeds[
            CToken(0x894cccB9908A0319381c305f947aD0EF44838591)
        ] = PriceFeed(0xB615075979AE1836B476F651f1eB79f0Cd3956a9);
        priceFeeds[
            CToken(0x04e9Db37d8EA0760072e1aCE3F2A219988Fdac29)
        ] = PriceFeed(0x1824D297C6d6D311A204495277B63e943C2D376E);
        priceFeeds[
            CToken(0x0a976E1E7D3052bEb46085AcBE1e0DAccF4A19CF)
        ] = PriceFeed(0x4Cba285c15e3B540C474A114a7b135193e4f1EA6);
        priceFeeds[
            CToken(0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6)
        ] = PriceFeed(0x6D41d1dc818112880b40e26BD6FD347E41008eDA);
    }

    function setPriceFeed(CToken ct, PriceFeed pf) external onlyOwner {
        priceFeeds[ct] = pf;
    }

    function getUnderlyingPrice(
        CToken cToken
    ) public view override returns (uint256) {
        return
            priceFeeds[cToken].latestAnswer().toUint256() *
            (10 ** (36 - priceFeeds[cToken].decimals() - cToken.decimals()));
    }
}
