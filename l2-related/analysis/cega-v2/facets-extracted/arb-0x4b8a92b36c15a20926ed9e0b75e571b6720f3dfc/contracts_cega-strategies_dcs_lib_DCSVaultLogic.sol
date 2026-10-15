// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    MMNFTMetadata
} from "../../../Structs.sol";
import { DCSProduct, DCSVault, DCSOptionType } from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../../aux/interfaces/IACLManager.sol";
import { Errors } from "../../../utils/Errors.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import { IDCSEvents, ICommonEvents } from "../interfaces/IDCSEvents.sol";

library DCSVaultLogic {
    using SafeCast for uint256;

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    /**
     * @notice Calculates the current yield of a vault up to a specified end date.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param endDate The end date for the yield calculation.
     * @return uint128 The calculated yield.
     */
    function getCurrentYield(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint40 endDate
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];

        return
            VaultLogic.calculateAmountFromApr(
                vault.totalAssets - dcsVault.totalYield,
                vault.tradeStartDate,
                dcsVault.aprBps,
                endDate
            );
    }

    // Duplicates DCSProductEntry.sol
    function getProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    function calculateLateFee(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint40 tradeStartDate = vault.tradeStartDate;
        uint128 totalYield = getCurrentYield(
            cgs,
            vaultAddress,
            tradeStartDate + dcsProduct.tenorInSeconds
        );

        return
            VaultLogic.calculateLateFee(
                totalYield,
                tradeStartDate,
                dcsProduct.lateFeeBps,
                dcsProduct.hoursToStartLateFees,
                dcsProduct.hoursToStartAuctionDefault
            );
    }

    // MUTATIVE FUNCTIONS

    /**
     * @notice Sets whether the payoff for a vault is in the deposit asset.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param value True if the payoff is in the deposit asset, false otherwise.
     */
    function setIsPayoffInDepositAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        bool value
    ) internal {
        cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset = value;
        emit IDCSEvents.DCSIsPayoffInDepositAssetUpdated(vaultAddress, value);
    }

    /**
     * @notice Rolls over a vault to the next trading period or marks it as a zombie vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function rolloverVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.WithdrawalQueueProcessed,
            Errors.INVALID_VAULT_STATUS
        );
        uint40 tradeEndDate = vault.tradeStartDate + dcsProduct.tenorInSeconds;

        require(tradeEndDate != 0, Errors.INVALID_TRADE_END_DATE);

        if (cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset) {
            bytes32 assetCode = VaultLogic.getAssetCode(address(0));
            delete cgs.oraclePriceOverride[vaultAddress][assetCode][
                vault.tradeStartDate
            ];
            delete cgs.oraclePriceOverride[vaultAddress][assetCode][
                tradeEndDate
            ];

            vault.tradeStartDate = 0;
            vault.auctionWinner = address(0);
            vault.auctionWinnerTokenId = 0;

            dcsVault.aprBps = 0;
            dcsVault.initialSpotPrice = 0;
            dcsVault.strikePrice = 0;
            dcsVault.totalYield = 0;

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.DepositsOpen
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Zombie);
        }

        emit IDCSEvents.DCSVaultRolledOver(vaultAddress);
    }

    /**
     * @notice Submits a dispute for a vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param tradeWinnerNFT The NFT representing the trade winner.
     * @param aclManager The ACL manager contract.
     */
    function disputeVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        IACLManager aclManager
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        uint256 tradeStartDate = vault.tradeStartDate;
        uint256 tradeEndDate = vault.tradeStartDate + product.tenorInSeconds;
        uint256 currentTime = block.timestamp;
        VaultStatus vaultStatus = vault.vaultStatus;

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);

        if (currentTime < tradeEndDate) {
            require(
                msg.sender == vault.auctionWinner ||
                    aclManager.isTraderAdmin(msg.sender),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );

            require(
                currentTime > tradeStartDate &&
                    currentTime <
                    tradeStartDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.Auctioned,
                Errors.INVALID_VAULT_STATUS
            );
        } else {
            require(
                msg.sender ==
                    IERC721(tradeWinnerNFT).ownerOf(
                        vault.auctionWinnerTokenId
                    ) ||
                    aclManager.isTraderAdmin((msg.sender)),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );
            require(
                currentTime <
                    tradeEndDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.AwaitingSettlement ||
                    (dcsVault.isPayoffInDepositAsset &&
                        vaultStatus == VaultStatus.Settled),
                Errors.INVALID_VAULT_STATUS
            );
        }

        vault.isInDispute = true;

        emit IDCSEvents.DCSDisputeSubmitted(vaultAddress);
    }

    /**
     * @notice Processes a dispute for a vault, potentially overriding the oracle price.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param newPrice The new price to set if the dispute is accepted.
     */
    function processDispute(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 newPrice
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        require(vault.isInDispute, Errors.VAULT_NOT_IN_DISPUTE);

        uint40 timestamp;
        if (newPrice != 0) {
            VaultStatus vaultStatus = vault.vaultStatus;

            if (vaultStatus == VaultStatus.Auctioned) {
                timestamp = vault.tradeStartDate;
            } else {
                timestamp = vault.tradeStartDate + product.tenorInSeconds;

                VaultLogic.setVaultStatus(
                    cgs,
                    vaultAddress,
                    VaultStatus.AwaitingSettlement
                );
                setIsPayoffInDepositAsset(cgs, vaultAddress, true);
            }

            VaultLogic.overrideOraclePrice(
                cgs,
                vaultAddress,
                address(0),
                timestamp,
                newPrice
            );
        }

        vault.isInDispute = false;

        emit IDCSEvents.DCSDisputeProcessed(
            vaultAddress,
            newPrice != 0,
            timestamp,
            newPrice
        );
    }
}
