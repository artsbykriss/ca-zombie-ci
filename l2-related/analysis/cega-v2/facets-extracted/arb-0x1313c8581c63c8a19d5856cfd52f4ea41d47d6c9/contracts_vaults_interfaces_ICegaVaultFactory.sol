// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface ICegaVaultFactory {
    function deployCegaVault(
        string memory tokenName,
        string memory tokenSymbol
    ) external returns (address);
}
