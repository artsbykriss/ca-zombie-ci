// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PythError} from "./Errors.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

library PythHelper {

    function updatePythPrice(IPyth pyth, bytes[] calldata priceUpdateData) internal {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        if (msg.value > fee) {
            (bool success, ) = msg.sender.call{value: msg.value - fee}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function updatePythPriceWithMemory(IPyth pyth, bytes[] memory priceUpdateData) internal {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        if (msg.value > fee) {
            (bool success, ) = msg.sender.call{value: msg.value - fee}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function getPrice(IPyth pyth, bytes32 priceId) internal view returns (uint64) {
        PythStructs.Price memory price = pyth.getPrice(priceId);
        if (price.price <= 0) {
            revert PythError.InvalidPrice(priceId, price.price);
        }
        return _convertPrice(price);
    }

    function getPriceByPyth(IPyth pyth, bytes32 priceId, bytes calldata priceUpdateData) internal returns (uint64) {
        bytes[] memory data = new bytes[](1);
        data[0] = priceUpdateData;
        uint fee = pyth.getUpdateFee(data);
        pyth.updatePriceFeeds{value: fee}(data);
        PythStructs.Price memory price = pyth.getPrice(priceId);
        if (price.price <= 0) revert PythError.InvalidPrice(priceId, price.price);
        return _convertPrice(price);
    }

    function updateAndGetHistoryPrice(
        IPyth pyth, bytes32[] memory priceIds, uint64[] memory publishTimes, bytes[] memory priceUpdateDatas
    ) internal returns (uint64[] memory) {
        //priceIds.length == publishTimes.length == priceUpdateDatas.length
        uint64[] memory prices = new uint64[](priceIds.length);
        uint totalFee = 0;
        for (uint i = 0; i < priceIds.length; i ++) {
            bytes[] memory data = new bytes[](1);
            data[0] = priceUpdateDatas[i];
            uint fee = pyth.getUpdateFee(data);
            totalFee += fee;
            bytes32[] memory priceId = new bytes32[](1);
            priceId[0] = priceIds[i];
            PythStructs.PriceFeed[] memory priceFeeds = pyth.parsePriceFeedUpdates{value: fee}(data, priceId, publishTimes[i], publishTimes[i] + 5);
            PythStructs.Price memory price = priceFeeds[0].price;
            if (price.price <= 0) revert PythError.InvalidHistoryPrice(priceIds[i], publishTimes[i], price.price);
            prices[i] = _convertPrice(price);
        }
        if (msg.value > totalFee) {
            (bool success, ) = msg.sender.call{value: msg.value - totalFee}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
        return prices;
    }

    function reciprocalPrice(uint64 price) internal pure returns (uint64) {
        return 1e16 / price;
    }

    function _convertPrice(PythStructs.Price memory priceData) private pure returns (uint64) {
        int64 price = priceData.price;
        int32 expo = priceData.expo;
        if (expo > 0) revert PythError.InvalidExpo(price, expo);
        // If the expo is -8, directly cast the price to uint64
        if (expo == -8) {
            return uint64(price);
        } else if (expo > -8){
            return uint64(price) * uint64(10 ** uint32(8 + expo));
        } else {
            return uint64(price) / uint64(10 ** uint32(-(8 + expo)));
        }
    }
}
