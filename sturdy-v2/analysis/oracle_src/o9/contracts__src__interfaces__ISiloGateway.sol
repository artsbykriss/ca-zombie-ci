// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface ISiloGateway {
    function borrowAsset(
        address _silo,
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _collateralAsset,
        address _borrower,
        address _receiver
    ) external;
}
