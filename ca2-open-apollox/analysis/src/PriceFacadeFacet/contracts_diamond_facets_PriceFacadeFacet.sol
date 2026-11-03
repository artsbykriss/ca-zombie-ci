// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../security/OnlySelf.sol";
import "../../utils/Constants.sol";
import "../../utils/PythHelper.sol";
import "../interfaces/IPriceFacade.sol";
import "../libraries/LibPriceFacade.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "../libraries/LibAccessControlEnumerable.sol";

contract PriceFacadeFacet is IPriceFacade, OnlySelf {

    IPyth private immutable PYTH;

    constructor(IPyth pyth) {
        PYTH = pyth;
    }

    function initPriceFacadeFacet(uint16 lowPriceGapP, uint16 highPriceGapP, uint16 maxPriceDelay) external {
        LibAccessControlEnumerable.checkRole(Constants.DEPLOYER_ROLE);
        require(lowPriceGapP > 0 && highPriceGapP > lowPriceGapP && maxPriceDelay > 0, "PriceFacadeFacet: Invalid parameters");
        LibPriceFacade.initialize(lowPriceGapP, highPriceGapP, maxPriceDelay);
    }

    // 0 means no update
    function setLowAndHighPriceGapP(uint16 lowPriceGapP, uint16 highPriceGapP) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        require(lowPriceGapP > 0 || highPriceGapP > 0, "PriceFacadeFacet: Update at least one");
        LibPriceFacade.setLowAndHighPriceGapP(lowPriceGapP, highPriceGapP);
    }

    function setTriggerLowAndHighPriceGapP(uint16 triggerLowPriceGapP, uint16 triggerHighPriceGapP) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        require(triggerLowPriceGapP > 0 || triggerHighPriceGapP > 0, "PriceFacadeFacet: Update at least one");
        LibPriceFacade.setTriggerLowAndHighPriceGapP(triggerLowPriceGapP, triggerHighPriceGapP);
    }

    function setMaxDelay(uint16 maxDelay) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        require(maxDelay > 0, "PriceFacadeFacet: maxDelay must be greater than 0");
        LibPriceFacade.setMaxDelay(maxDelay);
    }

    function getPriceFacadeConfig() external view override returns (Config memory) {
        LibPriceFacade.PriceFacadeStorage storage pfs = LibPriceFacade.priceFacadeStorage();
        return Config(pfs.lowPriceGapP, pfs.highPriceGapP, pfs.maxDelay, pfs.triggerLowPriceGapP, pfs.triggerHighPriceGapP);
    }

    function getPrice(address token) external view override returns (uint256) {
        return LibPriceFacade.getPrice(token);
    }

    function getPriceFromCacheOrOracle(address token) external view override returns (uint64 price, uint40 updatedAt) {
        return LibPriceFacade.getPriceFromCacheOrOracle(token);
    }

    function requestPrice(bytes32 tradeHash, address token, RequestType requestType, int256 qty) external onlySelf override {
        LibPriceFacade.requestPrice(tradeHash, token, requestType, qty);
    }

    function requestPriceCallback(bytes32 requestId, uint64 price) external override {
        LibAccessControlEnumerable.checkRole(Constants.PRICE_FEEDER_ROLE);
        require(price > 0, "PriceFacadeFacet: Invalid price");
        LibPriceFacade.requestPriceCallback(requestId, price);
    }

    function requestPriceCallback(bytes32 requestId, bytes32 priceId, bytes calldata priceUpdateData) external override {
        LibAccessControlEnumerable.checkRole(Constants.PYTH_PRICE_FEEDER_ROLE);
        LibPriceFacade.requestPriceCallback(requestId, PythHelper.getPriceByPyth(PYTH, priceId, priceUpdateData));
    }

    function batchRequestPriceCallback(PriceCallbackParam[] calldata params) external override {
        LibAccessControlEnumerable.checkRole(Constants.PRICE_FEEDER_ROLE);
        for (uint256 i; i < params.length;) {
            require(params[i].price > 0, "PriceFacadeFacet: Invalid price");
            LibPriceFacade.requestPriceCallback(params[i].requestId, params[i].price);
            unchecked {++i;}
        }
    }

    function batchRequestPriceCallback(PriceCallbackPythParamV1[] calldata params) external override {
        LibAccessControlEnumerable.checkRole(Constants.PYTH_PRICE_FEEDER_ROLE);
        for (uint256 i; i < params.length;) {
            PriceCallbackPythParamV1 calldata param = params[i];
            LibPriceFacade.requestPriceCallback(param.requestId, PythHelper.getPriceByPyth(PYTH, param.priceId, param.priceUpdateData));
            unchecked {++i;}
        }
    }

    function batchRequestPriceCallback(PriceCallbackPythParam[] calldata requests, bytes[] calldata priceUpdateData) external payable override {
        LibAccessControlEnumerable.checkRole(Constants.PRICE_FEEDER_ROLE);
        if (priceUpdateData.length > 0) {
            PythHelper.updatePythPrice(PYTH, priceUpdateData);
        }
        for (uint256 i; i < requests.length;) {
            PriceCallbackPythParam calldata request = requests[i];
            uint64 price = 0;
            if (request.price > 0) {
                price = request.price;
            } else {
                price = PythHelper.getPrice(PYTH, request.priceId);
                if (request.reciprocalPrice) {
                    price = PythHelper.reciprocalPrice(price);
                }
            }
            LibPriceFacade.requestPriceCallback(request.requestId, price);
            unchecked {++i;}
        }
    }

    function confirmTriggerPrice(address token, uint64 price) external onlySelf override returns (bool available, uint64 upper, uint64 lower) {
        LibPriceFacade.PriceFacadeStorage storage pfs = LibPriceFacade.priceFacadeStorage();
        (uint64 beforePrice,) = LibPriceFacade.getPriceFromCacheOrOracle(pfs, token);
        uint64 priceGap = price > beforePrice ? price - beforePrice : beforePrice - price;
        uint gapPercentage = priceGap * 1e4 / beforePrice;
        if (gapPercentage > pfs.triggerHighPriceGapP) {
            return (false, 0, 0);
        }
        pfs.callbackPrices[token] = LibPriceFacade.LatestCallbackPrice(price, uint40(block.timestamp));

        (upper, lower) = (price, price);
        if (gapPercentage >= pfs.triggerLowPriceGapP) {
            (upper, lower) = price > beforePrice ? (price, beforePrice) : (beforePrice, price);
        }
        return (true, upper, lower);
    }
}
