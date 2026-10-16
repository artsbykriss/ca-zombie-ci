// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {FablesRWA} from "./FablesRWA.sol";
import {FablesLedger} from "./base/FablesLedger.sol";
import {FablesBaseHook} from "./base/FablesBaseHook.sol";
import {FablesNativeETH, IWETH9} from "./base/FablesNativeETH.sol";

contract FablesRWAETH is FablesRWA, FablesNativeETH {
    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_, IWETH9 weth_)
        FablesRWA(poolManager_, authority_, absoluteMaxFee_)
        FablesNativeETH(weth_)
    {}

    function _nativeAllowed() internal pure virtual override(FablesBaseHook, FablesNativeETH) returns (bool) {
        return FablesNativeETH._nativeAllowed();
    }

    function _sweepDistributor(Currency currency) internal virtual override(FablesLedger, FablesNativeETH) {
        FablesNativeETH._sweepDistributor(currency);
    }

    function _sweepClaimFee(Currency currency) internal virtual override(FablesLedger, FablesNativeETH) {
        FablesNativeETH._sweepClaimFee(currency);
    }
}
