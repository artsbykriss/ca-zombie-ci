// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { VaultStatus, Vault, VaultCreationParams } from "../../../Structs.sol";
import { DCSVault } from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { ISwapManager } from "../../../swaps/interfaces/ISwapManager.sol";

interface IDCSVaultEntry {
    // FUNCTIONS

    /**
     * @notice Creates a new vault with specified parameters.
     * @param _productId The product ID associated with the vault.
     * @param creationParams The params of the vault.
     * @return vaultAddress The address of the newly created vault.
     */
    function dcsCreateVault(
        uint32 _productId,
        VaultCreationParams calldata creationParams
    ) external returns (address vaultAddress);

    /**
     * @notice Ends the auction for a vault and sets it up for trading.
     * @param vaultAddress The address of the vault.
     * @param _auctionWinner The address of the auction winner.
     * @param _tradeStartDate The start date of the trade.
     * @param _aprBps The annual percentage rate in basis points.
     * @param dataSource The data source for the oracle.
     */
    function dcsEndAuction(
        address vaultAddress,
        address _auctionWinner,
        uint40 _tradeStartDate,
        uint16 _aprBps,
        IOracleEntry.DataSource dataSource
    ) external;

    /**
     * @notice Starts trading for a vault.
     * @param vaultAddress The address of the vault to start trading.
     */
    function dcsStartTrade(address vaultAddress) external payable;

    /**
     * @notice Settles a vault.
     * @param vaultAddress The address of the vault to settle.
     */
    function dcsSettleVault(address vaultAddress) external payable;

    /**
     * @notice Swaps vaults funds on DEX and settles trade
     * @param vaultAddress Address of the vault to settle
     * @param swapProtocol Protocol to use for swap
     * @param swapData Swap params
     */
    function dcsSwapAndSettleVault(
        address vaultAddress,
        ISwapManager.SwapProtocol swapProtocol,
        ISwapManager.SwapData calldata swapData
    ) external payable;

    /**
     * @notice Rolls over a vault to a new period.
     * @param vaultAddress The address of the vault to roll over.
     */
    function dcsRolloverVault(
        address vaultAddress,
        uint256 maxProcessCount
    ) external returns (uint256 processCount);

    /**
     * @notice Sets whether the payoff for a vault is in the deposit asset.
     * @param vaultAddress The address of the vault.
     * @param newState True if the payoff is in the deposit asset, false otherwise.
     */
    function dcsSetIsPayoffInDepositAsset(
        address vaultAddress,
        bool newState
    ) external;

    /**
     * @notice Checks if an auction default has occurred for a specific vault.
     * @param vaultAddress The address of the vault to check.
     */
    function dcsCheckAuctionDefault(address vaultAddress) external;
}
