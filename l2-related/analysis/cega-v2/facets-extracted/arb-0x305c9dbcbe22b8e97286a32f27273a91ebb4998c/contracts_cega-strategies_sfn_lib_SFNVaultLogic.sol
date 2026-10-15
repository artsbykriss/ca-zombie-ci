// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    IERC721AUpgradeable
} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    MMNFTMetadata
} from "../../../Structs.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";
import { IACLManager } from "../../../aux/interfaces/IACLManager.sol";
import { Transfers } from "../../../utils/Transfers.sol";
import { Errors } from "../../../utils/Errors.sol";
import { ITradeWinnerNFT } from "../../../aux/interfaces/ITradeWinnerNFT.sol";

import {
    SFNProduct,
    SFNTrackedAssetsData,
    SFNVault,
    SFNPayoffType,
    SFNOptionType,
    SFNSpecificMMNFTMetadata,
    SFNEndAuctionParams
} from "../SFNStructs.sol";
import { ISFNEvents } from "../interfaces/ISFNEvents.sol";
import { SFNProduct, SFNTrackedAssetsData, SFNVault } from "../SFNStructs.sol";
import { SFNProductLogic } from "./SFNProductLogic.sol";

library SFNVaultLogic {
    using Transfers for address;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for uint40;

    // CONSTANTS

    uint128 internal constant LARGE_CONSTANT = 1e18;

    uint128 internal constant DAYS_IN_YEAR = 365;

    uint128 internal constant BPS_DECIMALS = 1e4;

    // VIEW FUNCTIONS

    function getSpotPriceAt(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        IOracleEntry oracleEntry,
        address asset,
        IOracleEntry.DataSource dataSource,
        uint40 priceTimestamp
    ) internal view returns (uint128) {
        uint128 priceOverride = cgs.oraclePriceOverride[vaultAddress][
            VaultLogic.getAssetCode(asset)
        ][priceTimestamp];

        if (priceOverride > 0) {
            return priceOverride;
        }

        return oracleEntry.getSinglePrice(asset, priceTimestamp, dataSource);
    }

    function calculateCompositeChange(
        uint32[] memory priceChanges,
        SFNPayoffType payoffType
    ) internal pure returns (uint32) {
        if (payoffType == SFNPayoffType.Average) {
            uint32 sum;
            for (uint256 i = 0; i < priceChanges.length; i++) {
                sum += priceChanges[i];
            }
            return (sum / priceChanges.length).toUint32();
        } else if (payoffType == SFNPayoffType.BestOf) {
            uint32 max;
            for (uint256 i = 0; i < priceChanges.length; i++) {
                if (priceChanges[i] > max) {
                    max = priceChanges[i];
                }
            }
            return max;
        } else if (payoffType == SFNPayoffType.WorstOf) {
            uint32 min = type(uint32).max;
            for (uint256 i = 0; i < priceChanges.length; i++) {
                if (priceChanges[i] < min) {
                    min = priceChanges[i];
                }
            }
            return min;
        } else {
            // Impossible branch
            return 0;
        }
    }

    // MUTATIVE FUNCTIONS

    function endAuction(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        SFNEndAuctionParams calldata params
    ) internal {
        Vault storage vault = cgs.vaults[params.vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[params.vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        require(
            sfnProduct.trackedAssets.length == params.dataSources.length,
            Errors.INVALID_ARRAY_LENGTH
        );
        require(
            vaultStatus == VaultStatus.PreAuction ||
                vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );

        require(params.tradeStartDate != 0, Errors.VALUE_IS_ZERO);

        vault.auctionWinner = params.auctionWinner;
        vault.tradeStartDate = params.tradeStartDate;

        sfnVault.lendingAprBps = params.lendingAprBps;
        sfnVault.maxAprBps = params.maxAprBps;
        uint128[] memory initialSpotPrices = new uint128[](
            params.dataSources.length
        );

        if (sfnVault.trackedAssetsData.length == 0) {
            sfnVault.trackedAssetsData = new SFNTrackedAssetsData[](
                params.dataSources.length
            );
        }

        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        for (uint256 index = 0; index < params.dataSources.length; index++) {
            initialSpotPrices[index] = VaultLogic.getSingleSpotPriceAt(
                cgs,
                params.vaultAddress,
                oracleEntry,
                sfnProduct.trackedAssets[index],
                params.dataSources[index],
                params.tradeStartDate
            );

            sfnVault.trackedAssetsData[index] = SFNTrackedAssetsData({
                dataSource: params.dataSources[index],
                initialSpotPrice: initialSpotPrices[index]
            });
        }

        VaultLogic.setVaultStatus(
            cgs,
            params.vaultAddress,
            VaultStatus.Auctioned
        );

        emit ISFNEvents.SFNAuctionEnded(
            params.vaultAddress,
            params.auctionWinner,
            params.tradeStartDate,
            params.lendingAprBps,
            params.maxAprBps,
            initialSpotPrices
        );
    }

    /**
     * @dev Starts a trade for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param tradeWinnerNFT The address of the trade winner NFT contract.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @return nativeValueReceived The native value received.
     * @return nftMetadata The metadata for the minted NFT.
     */
    function startTrade(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        returns (uint256 nativeValueReceived, MMNFTMetadata memory nftMetadata)
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];

        require(msg.sender == vault.auctionWinner, Errors.NOT_TRADE_WINNER);
        require(
            vault.vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >= vault.tradeStartDate,
            Errors.TRADE_NOT_STARTED
        );

        // TODO switch SFN and DCS to hours as well
        require(
            !VaultLogic.getIsAuctionDefaulted(
                cgs,
                vaultAddress,
                sfnProduct.hoursToStartAuctionDefault
            ),
            Errors.TRADE_DEFAULTED
        );

        // Transfer the premium + any applicable late fee
        uint40 tradeStartDate = vault.tradeStartDate;
        address depositAsset = SFNProductLogic.sfnGetProductDepositAsset(
            sfnProduct
        );
        uint128 totalAssets = vault.totalAssets;
        uint40 tenorInSeconds = sfnProduct.tenorInSeconds;

        // prices are 0 until we modify the NFT Metadata
        nftMetadata = MMNFTMetadata({
            vaultAddress: vaultAddress,
            tradeStartDate: tradeStartDate,
            tradeEndDate: tradeStartDate + tenorInSeconds,
            notional: totalAssets,
            aprBps: 0,
            initialSpotPrice: 0,
            strikePrice: 0,
            extraData: abi.encode(
                SFNSpecificMMNFTMetadata({
                    lendingAprBps: sfnVault.lendingAprBps,
                    maxAprBps: sfnVault.maxAprBps
                })
            )
        });

        uint128 totalYield = VaultLogic.calculateAmountFromApr(
            totalAssets,
            tradeStartDate,
            sfnVault.lendingAprBps,
            tradeStartDate + tenorInSeconds
        );

        sfnVault.totalYield = totalYield;

        uint128 lateFee = VaultLogic.calculateLateFee(
            totalYield,
            tradeStartDate,
            sfnProduct.lateFeeBps,
            sfnProduct.hoursToStartLateFees,
            sfnProduct.hoursToStartAuctionDefault
        );

        sfnVault.notional = totalAssets;

        require(
            cgs.bondAllowList[msg.sender],
            Errors.UNAUTHORIZED_BOND_RECEIVER
        );

        vault.totalAssets = totalYield;

        treasury.withdraw(depositAsset, msg.sender, totalAssets, false);

        if (lateFee > 0) {
            nativeValueReceived = depositAsset.receiveTo(
                addressManager.getCegaFeeReceiver(),
                lateFee
            );
            emit ISFNEvents.SFNLateFeePaid(vaultAddress, lateFee);
        }

        nativeValueReceived += depositAsset.receiveTo(
            address(treasury),
            totalYield
        );

        sfnProduct.sumVaultUnderlyingAmounts += totalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Traded);

        if (tradeWinnerNFT != address(0)) {
            uint256 tokenId = ITradeWinnerNFT(tradeWinnerNFT).mint(
                msg.sender,
                nftMetadata
            );
            vault.auctionWinnerTokenId = tokenId.toUint64();
        }

        emit ISFNEvents.SFNTradeStarted(
            vaultAddress,
            msg.sender,
            totalAssets,
            totalYield
        );
    }

    function checkBarriers(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint16 maxObservations
    ) internal returns (bool isKnockedOut, uint16 observationsCount) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];
        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        require(
            vault.vaultStatus == VaultStatus.Traded,
            Errors.INVALID_VAULT_STATUS
        );

        uint40 tradeStartDate = vault.tradeStartDate;
        uint40 tradeEndDate = tradeStartDate + sfnProduct.tenorInSeconds;
        uint40 observationInterval = sfnProduct.observationIntervalInSeconds;
        uint40 observationsDone = sfnVault.observationsDone;
        uint40 observationStart = tradeStartDate +
            (observationsDone + 1) *
            observationInterval;

        uint40 observationEnd = tradeStartDate +
            (observationsDone + maxObservations) *
            observationInterval;
        if (tradeEndDate < observationEnd) {
            observationEnd = tradeEndDate;
        }
        if (block.timestamp < observationEnd) {
            observationEnd = block.timestamp.toUint40();
        }
        if (observationEnd < observationStart) {
            return (sfnVault.isKnockedOut, 0);
        }
        observationsCount = ((observationEnd - observationStart) /
            observationInterval +
            1).toUint16();

        uint256 trackedAssetsLength = sfnVault.trackedAssetsData.length;
        address[] memory assets = new address[](trackedAssetsLength);
        IOracleEntry.DataSource[]
            memory dataSources = new IOracleEntry.DataSource[](
                trackedAssetsLength
            );
        uint128[] memory initialPrices = new uint128[](trackedAssetsLength);
        for (uint256 i = 0; i < trackedAssetsLength; i++) {
            assets[i] = sfnProduct.trackedAssets[i];
            dataSources[i] = sfnVault.trackedAssetsData[i].dataSource;
            initialPrices[i] = sfnVault.trackedAssetsData[i].initialSpotPrice;
        }
        uint24 knockOutBps = sfnProduct.knockOutBps;
        SFNPayoffType payoffType = sfnProduct.payoffType;
        SFNOptionType optionType = sfnProduct.optionType;

        // We use uint32 to store priceChanges as max(uint16) can be not enough for actual price change (~650%)
        uint32[] memory priceChangesBps = new uint32[](trackedAssetsLength);

        for (
            uint40 observationTime = observationStart;
            observationTime <= observationEnd;
            observationTime += observationInterval
        ) {
            for (uint256 i = 0; i < trackedAssetsLength; i++) {
                uint128 spotPrice = getSpotPriceAt(
                    cgs,
                    vaultAddress,
                    oracleEntry,
                    assets[i],
                    dataSources[i],
                    observationTime
                );
                priceChangesBps[i] = ((spotPrice * BPS_DECIMALS) /
                    initialPrices[i]).toUint32();
            }
            uint32 compositePriceChangeBps = calculateCompositeChange(
                priceChangesBps,
                payoffType
            );
            if (
                (optionType == SFNOptionType.Bull &&
                    compositePriceChangeBps >= knockOutBps) ||
                (optionType == SFNOptionType.Bear &&
                    compositePriceChangeBps <= knockOutBps)
            ) {
                isKnockedOut = true;
                break;
            }
        }

        if (isKnockedOut) {
            sfnVault.observationsDone = type(uint16).max;
            sfnVault.isKnockedOut = true;
        } else {
            sfnVault.observationsDone += observationsCount;
        }

        emit ISFNEvents.SFNIsKnockedOutUpdated(vaultAddress, isKnockedOut);
    }

    function checkTradeExpiry(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;
        if (vaultStatus != VaultStatus.Traded) {
            return;
        }

        uint40 tenorInSeconds = sfnProduct.tenorInSeconds;
        uint40 tradeStartDate = vault.tradeStartDate;
        uint256 currentTime = block.timestamp;
        if (currentTime <= tradeStartDate + tenorInSeconds) {
            return;
        }

        checkBarriers(cgs, addressManager, vaultAddress, type(uint16).max);

        VaultLogic.setVaultStatus(
            cgs,
            vaultAddress,
            VaultStatus.AwaitingSettlement
        );
    }

    /**
     * @dev Collects fees from a specific vault.
     * @param cgs The Cega global storage.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     */
    function collectVaultFees(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;

        require(
            vaultStatus == VaultStatus.Settled ||
                (vaultStatus == VaultStatus.AwaitingSettlement &&
                    vault.isDefaulted),
            Errors.INVALID_VAULT_STATUS
        );

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >
                vault.tradeStartDate +
                    sfnProduct.tenorInSeconds +
                    (uint256(sfnProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        uint128 totalAssets = vault.totalAssets;
        uint128 notional = sfnVault.notional;
        uint128 profit = totalAssets > notional ? totalAssets - notional : 0;

        (
            uint128 totalFees,
            uint128 managementFee,
            uint128 yieldFee
        ) = VaultLogic.calculateFees(
                cgs,
                vaultAddress,
                sfnProduct.tenorInSeconds,
                notional,
                profit
            );
        if (totalFees > totalAssets) {
            totalFees = totalAssets;
            managementFee = totalAssets;
            yieldFee = 0;
        }

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.FeesCollected);
        vault.totalAssets = totalAssets - totalFees;

        treasury.withdraw(
            SFNProductLogic.sfnGetProductDepositAsset(sfnProduct),
            addressManager.getCegaFeeReceiver(),
            totalFees,
            true
        );

        sfnProduct.sumVaultUnderlyingAmounts -= uint128(totalFees);

        emit ISFNEvents.SFNVaultFeesCollected(
            vaultAddress,
            totalFees,
            managementFee,
            yieldFee
        );
    }

    function rolloverVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.WithdrawalQueueProcessed,
            Errors.INVALID_VAULT_STATUS
        );
        uint40 tradeEndDate = vault.tradeStartDate + sfnProduct.tenorInSeconds;

        require(tradeEndDate != 0, Errors.INVALID_TRADE_END_DATE);

        if (!vault.isDefaulted) {
            uint256 trackedAssetsLength = sfnProduct.trackedAssets.length;
            for (uint256 i = 0; i < trackedAssetsLength; i++) {
                delete cgs.oraclePriceOverride[vaultAddress][
                    VaultLogic.getAssetCode(sfnProduct.trackedAssets[i])
                ][tradeEndDate];
            }

            vault.tradeStartDate = 0;
            vault.auctionWinner = address(0);
            vault.auctionWinnerTokenId = 0;

            delete sfnVault.trackedAssetsData;
            sfnVault.maxAprBps = 0;
            sfnVault.lendingAprBps = 0;
            sfnVault.observationsDone = 0;
            sfnVault.totalYield = 0;
            sfnVault.notional = 0;
            sfnVault.isKnockedOut = false;

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.DepositsOpen
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Zombie);
        }

        emit ISFNEvents.SFNVaultRolledOver(vaultAddress);
    }

    function disputeVault(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint40 timestamp
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage product = cgs.sfnProducts[vault.productId];

        uint256 tradeStartDate = vault.tradeStartDate;
        uint256 tradeEndDate = tradeStartDate + product.tenorInSeconds;
        uint256 currentTime = block.timestamp;
        VaultStatus vaultStatus = vault.vaultStatus;

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        if (vaultStatus == VaultStatus.Auctioned) {
            require(
                (msg.sender == vault.auctionWinner) ||
                    IACLManager(addressManager.getACLManager()).isTraderAdmin(
                        (msg.sender)
                    ),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );
        } else {
            require(
                IACLManager(addressManager.getACLManager()).isTraderAdmin(
                    (msg.sender)
                ) ||
                    msg.sender ==
                    IERC721(addressManager.getTradeWinnerNFT()).ownerOf(
                        vault.auctionWinnerTokenId
                    ),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );
        }

        if (currentTime < tradeEndDate) {
            if (vaultStatus == VaultStatus.Auctioned) {
                require(
                    currentTime > tradeStartDate &&
                        currentTime <
                        tradeStartDate +
                            (uint256(product.disputePeriodInHours) * 1 hours),
                    Errors.OUTSIDE_DISPUTE_PERIOD
                );

                require(
                    timestamp == tradeStartDate,
                    Errors.OUTSIDE_DISPUTE_PERIOD
                );
            } else {
                require(
                    timestamp > tradeStartDate &&
                        timestamp <= currentTime &&
                        (timestamp - tradeStartDate) %
                            product.observationIntervalInSeconds ==
                        0,
                    Errors.OUTSIDE_DISPUTE_PERIOD
                );
            }
        } else {
            require(
                currentTime <
                    tradeEndDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );

            require(
                timestamp > tradeStartDate &&
                    timestamp <= tradeEndDate &&
                    (timestamp - tradeStartDate) %
                        product.observationIntervalInSeconds ==
                    0,
                Errors.OUTSIDE_DISPUTE_PERIOD
            );

            // Because of bond, SFN always needs settlement
            require(
                vaultStatus == VaultStatus.AwaitingSettlement,
                Errors.INVALID_VAULT_STATUS
            );
        }

        vault.isInDispute = true;

        emit ISFNEvents.SFNDisputeSubmitted(vaultAddress, timestamp);
    }

    function doSingleObservation(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint40 timestamp
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];
        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        uint256 trackedAssetsLength = sfnVault.trackedAssetsData.length;
        address[] memory assets = new address[](trackedAssetsLength);
        IOracleEntry.DataSource[]
            memory dataSources = new IOracleEntry.DataSource[](
                trackedAssetsLength
            );
        uint128[] memory initialPrices = new uint128[](trackedAssetsLength);
        for (uint256 i = 0; i < trackedAssetsLength; i++) {
            assets[i] = sfnProduct.trackedAssets[i];
            dataSources[i] = sfnVault.trackedAssetsData[i].dataSource;
            initialPrices[i] = sfnVault.trackedAssetsData[i].initialSpotPrice;
        }
        uint24 knockOutBps = sfnProduct.knockOutBps;
        SFNOptionType optionType = sfnProduct.optionType;

        uint32[] memory priceChangesBps = new uint32[](trackedAssetsLength);

        for (uint256 i = 0; i < trackedAssetsLength; i++) {
            uint128 spotPrice = getSpotPriceAt(
                cgs,
                vaultAddress,
                oracleEntry,
                assets[i],
                dataSources[i],
                timestamp
            );
            priceChangesBps[i] = ((spotPrice * BPS_DECIMALS) / initialPrices[i])
                .toUint32();
        }
        uint32 compositePriceChangeBps = calculateCompositeChange(
            priceChangesBps,
            sfnProduct.payoffType
        );
        return
            (optionType == SFNOptionType.Bull &&
                compositePriceChangeBps >= knockOutBps) ||
            (optionType == SFNOptionType.Bear &&
                compositePriceChangeBps <= knockOutBps);
    }

    function processDispute(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint40 timestamp,
        bool accept,
        uint128[] calldata newPrices
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage product = cgs.sfnProducts[vault.productId];

        require(vault.isInDispute, Errors.VAULT_NOT_IN_DISPUTE);

        if (accept) {
            require(
                newPrices.length == product.trackedAssets.length,
                Errors.INVALID_ARRAY_LENGTH
            );

            for (uint256 i = 0; i < newPrices.length; i++) {
                if (newPrices[i] != 0) {
                    VaultLogic.overrideOraclePrice(
                        cgs,
                        vaultAddress,
                        product.trackedAssets[i],
                        timestamp,
                        newPrices[i]
                    );
                }
            }

            VaultStatus vaultStatus = vault.vaultStatus;
            if (
                vaultStatus == VaultStatus.AwaitingSettlement ||
                vaultStatus == VaultStatus.Traded
            ) {
                bool isKnockedOut = doSingleObservation(
                    cgs,
                    addressManager,
                    vaultAddress,
                    timestamp
                );

                SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
                sfnVault.isKnockedOut = isKnockedOut;
                emit ISFNEvents.SFNIsKnockedOutUpdated(
                    vaultAddress,
                    isKnockedOut
                );

                if (!isKnockedOut) {
                    // rerun all observations as we don't know which timestamp knocked-out aside from this one.
                    sfnVault.observationsDone = 0;
                    // to force check expiry again
                    VaultLogic.setVaultStatus(
                        cgs,
                        vaultAddress,
                        VaultStatus.Traded
                    );
                }
            }
        } else {
            require(newPrices.length == 0, Errors.INVALID_ARRAY_LENGTH);
        }

        vault.isInDispute = false;

        emit ISFNEvents.SFNDisputeProcessed(
            vaultAddress,
            timestamp,
            accept,
            newPrices
        );
    }

    /**
     * @dev Checks for settlement default for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function checkSettlementDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        if (vault.isDefaulted) {
            return;
        }

        uint256 hoursLate = VaultLogic.getHoursLate(
            vault.tradeStartDate + sfnProduct.tenorInSeconds
        );
        if (
            hoursLate >= sfnProduct.hoursToStartSettlementDefault &&
            vault.vaultStatus == VaultStatus.AwaitingSettlement
        ) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);

            sfnProduct.sumVaultUnderlyingAmounts -= sfnVault.notional;
        }
    }

    function checkAuctionDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        uint32 productId = cgs.vaults[vaultAddress].productId;

        bool isDefaulted = VaultLogic.getIsAuctionDefaulted(
            cgs,
            vaultAddress,
            cgs.sfnProducts[productId].hoursToStartAuctionDefault
        );
        if (isDefaulted) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
        }
    }

    function settleVault(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress
    ) internal returns (uint256 nativeValueReceived) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement,
            Errors.INVALID_VAULT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >
                vault.tradeStartDate +
                    sfnProduct.tenorInSeconds +
                    (uint256(sfnProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        {
            uint256 auctionWinnerTokenId = vault.auctionWinnerTokenId;
            require(auctionWinnerTokenId != 0, Errors.TRADE_HAS_NO_WINNER);
            require(
                msg.sender ==
                    IERC721AUpgradeable(addressManager.getTradeWinnerNFT())
                        .ownerOf(auctionWinnerTokenId),
                Errors.NOT_TRADE_WINNER
            );
        }

        checkSettlementDefault(cgs, vaultAddress);
        require(!vault.isDefaulted, Errors.TRADE_DEFAULTED);

        uint128 netPaymentAmount = calculateVaultSettlementAmount(
            cgs,
            addressManager,
            vaultAddress
        );

        nativeValueReceived = sfnProduct.underlyingAsset.receiveTo(
            address(treasury),
            netPaymentAmount
        );

        vault.totalAssets += netPaymentAmount;

        uint128 notional = cgs.sfnVaults[vaultAddress].notional;
        sfnProduct.sumVaultUnderlyingAmounts =
            sfnProduct.sumVaultUnderlyingAmounts +
            netPaymentAmount -
            notional;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
    }

    function calculateVaultFinalPayoff(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        require(
            vaultStatus == VaultStatus.AwaitingSettlement ||
                vaultStatus == VaultStatus.Settled,
            Errors.INVALID_VAULT_STATUS
        );

        uint128 netPaymentAmount = calculateVaultSettlementAmount(
            cgs,
            addressManager,
            vaultAddress
        );

        return sfnVault.totalYield + netPaymentAmount;
    }

    function calculateVaultSettlementAmount(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        uint40 tradeStartDate = vault.tradeStartDate;
        uint40 tenorInSeconds = sfnProduct.tenorInSeconds;

        uint40 tradeEndDate = tradeStartDate + tenorInSeconds;

        uint128 notional = sfnVault.notional;
        uint24 lendingApr = sfnVault.lendingAprBps;
        uint24 fromMMApr;
        uint24 toMMApr;

        if (sfnVault.isKnockedOut) {
            uint24 rebateApr = getAprFromRatio(
                lendingApr,
                sfnProduct.rebateAprRatioBps
            );
            toMMApr = lendingApr - rebateApr;
        } else {
            uint256 trackedAssetsLength = sfnVault.trackedAssetsData.length;
            address[] memory assets = new address[](trackedAssetsLength);
            IOracleEntry.DataSource[]
                memory dataSources = new IOracleEntry.DataSource[](
                    trackedAssetsLength
                );
            uint128[] memory initialPrices = new uint128[](trackedAssetsLength);
            for (uint256 i = 0; i < trackedAssetsLength; i++) {
                assets[i] = sfnProduct.trackedAssets[i];
                dataSources[i] = sfnVault.trackedAssetsData[i].dataSource;
                initialPrices[i] = sfnVault
                    .trackedAssetsData[i]
                    .initialSpotPrice;
            }

            uint24 knockOutBps = sfnProduct.knockOutBps;
            uint24 strikeBps = sfnProduct.strikeBps;

            SFNPayoffType payoffType = sfnProduct.payoffType;
            SFNOptionType optionType = sfnProduct.optionType;

            uint32[] memory priceChangesBps = new uint32[](trackedAssetsLength);

            IOracleEntry oracleEntry = IOracleEntry(
                addressManager.getCegaOracle()
            );

            for (uint256 i = 0; i < trackedAssetsLength; i++) {
                uint128 spotPrice = getSpotPriceAt(
                    cgs,
                    vaultAddress,
                    oracleEntry,
                    assets[i],
                    dataSources[i],
                    tradeEndDate
                );
                priceChangesBps[i] = ((spotPrice * BPS_DECIMALS) /
                    initialPrices[i]).toUint32();
            }
            uint32 compositePriceChangeBps = calculateCompositeChange(
                priceChangesBps,
                payoffType
            );

            if (
                (optionType == SFNOptionType.Bull &&
                    compositePriceChangeBps < strikeBps) ||
                (optionType == SFNOptionType.Bear &&
                    compositePriceChangeBps > strikeBps)
            ) {
                uint24 guaranteedApr = getAprFromRatio(
                    lendingApr,
                    sfnProduct.guaranteedAprRatioBps
                );
                toMMApr = lendingApr - guaranteedApr;
            } else {
                uint24 minAprBps = getAprFromRatio(
                    lendingApr,
                    sfnProduct.minAprRatioBps
                );
                uint24 guaranteedApr = getAprFromRatio(
                    lendingApr,
                    sfnProduct.guaranteedAprRatioBps
                );
                uint24 finalApr;

                if (optionType == SFNOptionType.Bull) {
                    finalApr = calculateFinalApr(
                        compositePriceChangeBps,
                        strikeBps,
                        knockOutBps,
                        minAprBps,
                        sfnVault.maxAprBps
                    );
                } else {
                    finalApr = calculateFinalApr(
                        compositePriceChangeBps,
                        knockOutBps,
                        strikeBps,
                        minAprBps,
                        sfnVault.maxAprBps
                    );
                }

                toMMApr = lendingApr - guaranteedApr;
                fromMMApr = finalApr - guaranteedApr;
            }
        }

        uint128 netPaymentAmount;

        if (toMMApr > fromMMApr) {
            uint128 aprAmount = VaultLogic.calculateAmountFromApr(
                notional,
                tradeStartDate,
                toMMApr - fromMMApr,
                tradeEndDate
            );

            netPaymentAmount = notional - aprAmount;
        } else {
            uint128 aprAmount = VaultLogic.calculateAmountFromApr(
                notional,
                tradeStartDate,
                fromMMApr - toMMApr,
                tradeEndDate
            );
            netPaymentAmount = notional + aprAmount;
        }

        return netPaymentAmount;
    }

    function getAprFromRatio(
        uint256 baseAprBps,
        uint256 ratioBps
    ) internal pure returns (uint24) {
        return uint24((baseAprBps * ratioBps) / BPS_DECIMALS);
    }

    function calculateFinalApr(
        uint256 ux,
        uint256 ux1,
        uint256 ux2,
        uint256 uy1,
        uint256 uy2
    ) internal pure returns (uint24) {
        int256 x = int256(ux);
        int256 x1 = int256(ux1);
        int256 x2 = int256(ux2);
        int256 y1 = int256(uy1);
        int256 y2 = int256(uy2);

        require(x1 != x2, "x1 and x2 cannot be equal");
        int128 largeConstant = int128(LARGE_CONSTANT);
        int256 numerator = (y2 - y1);
        int256 denominator = (x2 - x1);
        int256 m = (numerator * largeConstant) / denominator;

        // Calculate y using the point-slope form of the line equation
        int256 y = (y1 * largeConstant) + (m * (x - x1)); // Adjusted for fixed-point precision
        y /= largeConstant; // Divide by 1e18 to get the actual y value

        return uint24(uint256(y));
    }

    function getVaultCouponPayment(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNVault storage sfnVault = cgs.sfnVaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        uint128 notional;
        if (vault.auctionWinnerTokenId != 0) {
            notional = sfnVault.notional;
        } else {
            notional = vault.totalAssets;
        }

        uint40 tradeStartDate = vault.tradeStartDate;
        uint40 tenorInSeconds = sfnProduct.tenorInSeconds;
        return
            VaultLogic.calculateAmountFromApr(
                notional,
                tradeStartDate,
                sfnVault.lendingAprBps,
                tradeStartDate + tenorInSeconds
            );
    }

    function calculateLateFee(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vault.productId];

        uint128 totalYield = SFNVaultLogic.getVaultCouponPayment(
            cgs,
            vaultAddress
        );
        return
            VaultLogic.calculateLateFee(
                totalYield,
                vault.tradeStartDate,
                sfnProduct.lateFeeBps,
                sfnProduct.hoursToStartLateFees,
                sfnProduct.hoursToStartAuctionDefault
            );
    }
}
