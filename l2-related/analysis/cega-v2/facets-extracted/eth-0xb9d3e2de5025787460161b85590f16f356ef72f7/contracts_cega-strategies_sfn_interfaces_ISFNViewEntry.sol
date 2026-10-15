// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { SFNProduct, SFNVault } from "../SFNStructs.sol";

interface ISFNViewEntry {
    function sfnGetProduct(
        uint32 productId
    ) external view returns (SFNProduct memory);

    function sfnGetProductDepositAsset(
        uint32 productId
    ) external view returns (address);

    function sfnGetVault(
        address vaultAddress
    ) external view returns (SFNVault memory);

    function sfnGetCouponPayment(
        address vaultAddress
    ) external view returns (uint128);

    function sfnCalculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128);

    function sfnCalculateVaultSettlementAmount(
        address vaultAddress
    ) external view returns (uint128);

    function sfnCalculateLateFee(
        address vaultAddress
    ) external view returns (uint128);
}
