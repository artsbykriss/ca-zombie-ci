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
import {
    FCNProduct,
    FCNVault,
    FCNOptionBarrier,
    FCNVaultBarrierData,
    FCNOptionBarrierType
} from "../FCNStructs.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { ITradeWinnerNFT } from "../../../aux/interfaces/ITradeWinnerNFT.sol";
import { IFCNEvents } from "../interfaces/IFCNEvents.sol";
import { IACLManager } from "../../../aux/interfaces/IACLManager.sol";
import { Errors } from "../../../utils/Errors.sol";
import { FCNProductLogic } from "./FCNProductLogic.sol";
import { Transfers } from "../../../utils/Transfers.sol";

library FCNVaultLogic {
    using Transfers for address;
    using SafeCast for uint256;
    using SafeCast for uint40;

    // CONSTANTS

    uint128 internal constant LARGE_CONSTANT = 1e18;

    uint128 internal constant DAYS_IN_YEAR = 365;

    uint128 internal constant BPS_DECIMALS = 1e4;

    // FUNCTIONS

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

    function expRatio(
        uint256 num,
        uint256 denom,
        uint8 exp
    ) internal pure returns (uint256 result) {
        num = (num * LARGE_CONSTANT) / denom;
        result = num;
        for (uint8 i = 1; i < exp; i++) {
            result = (result * num) / LARGE_CONSTANT;
        }
    }

    function getVaultLostCapital(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];

        if (!fcnVault.isKnockedIn) {
            return 0;
        }

        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        uint256 knockInRatio = LARGE_CONSTANT;
        uint256 barriersLength = fcnVault.barrierData.length;
        uint40 tradeEndDate = vault.tradeStartDate + fcnProduct.tenorInSeconds;

        FCNVaultBarrierData memory barrierData;
        FCNOptionBarrier memory optionBarrier;
        uint256 initialSpotPrice;
        uint256 finalSpotPrice;

        for (uint256 i = 0; i < barriersLength; i++) {
            barrierData = fcnVault.barrierData[i];
            optionBarrier = fcnProduct.optionBarriers[i];

            initialSpotPrice = barrierData.initialSpotPrice;
            finalSpotPrice = getSpotPriceAt(
                cgs,
                vaultAddress,
                oracleEntry,
                optionBarrier.asset,
                barrierData.dataSource,
                tradeEndDate
            );

            if (finalSpotPrice < initialSpotPrice) {
                uint256 currentRatio = expRatio(
                    finalSpotPrice,
                    initialSpotPrice,
                    optionBarrier.exponent
                );
                if (currentRatio < knockInRatio) {
                    knockInRatio = currentRatio;
                }
            }
        }

        uint256 principalLostRatio = Math.min(
            (LARGE_CONSTANT - knockInRatio) * fcnProduct.leverage,
            LARGE_CONSTANT
        );
        return
            ((fcnVault.notional * principalLostRatio) / LARGE_CONSTANT)
                .toUint128();
    }

    function calculateVaultFinalPayoff(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        require(
            vaultStatus == VaultStatus.AwaitingSettlement ||
                vaultStatus == VaultStatus.Settled,
            Errors.INVALID_VAULT_STATUS
        );

        return
            fcnVault.notional +
            fcnVault.totalYield -
            getVaultLostCapital(cgs, addressManager, vaultAddress);
    }

    function calculateRepaidBond(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];

        require(fcnProduct.isBondOption, Errors.NOT_BOND_OPTION);

        VaultStatus vaultStatus = vault.vaultStatus;
        if (
            vaultStatus == VaultStatus.Traded ||
            vaultStatus == VaultStatus.AwaitingSettlement
        ) {
            return vault.totalAssets - fcnVault.totalYield;
        } else {
            return fcnVault.notional;
        }
    }

    function calculateVaultSettlementAmount(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement,
            Errors.INVALID_VAULT_STATUS
        );

        uint128 lostCapital = getVaultLostCapital(
            cgs,
            addressManager,
            vaultAddress
        );

        uint128 unpaidBond;
        if (fcnProduct.isBondOption) {
            unpaidBond =
                fcnVault.notional -
                calculateRepaidBond(cgs, vaultAddress);
        }

        if (lostCapital > unpaidBond) {
            return 0;
        } else {
            return unpaidBond - lostCapital;
        }
    }

    function getVaultCouponPayment(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        uint128 notional;
        if (vault.auctionWinnerTokenId != 0) {
            notional = fcnVault.notional;
        } else {
            notional = vault.totalAssets;
        }

        uint40 tradeStartDate = vault.tradeStartDate;
        uint40 tenorInSeconds = fcnProduct.tenorInSeconds;
        return
            VaultLogic.calculateAmountFromApr(
                notional,
                tradeStartDate,
                fcnVault.aprBps,
                tradeStartDate + tenorInSeconds
            );
    }

    function calculateLateFee(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        uint128 totalYield = getVaultCouponPayment(cgs, vaultAddress);
        return
            VaultLogic.calculateLateFee(
                totalYield,
                vault.tradeStartDate,
                fcnProduct.lateFeeBps,
                fcnProduct.hoursToStartLateFees,
                fcnProduct.hoursToStartAuctionDefault
            );
    }

    function endAuction(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        address auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        IOracleEntry.DataSource[] calldata dataSources
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        require(
            fcnProduct.optionBarriers.length == dataSources.length,
            Errors.INVALID_ARRAY_LENGTH
        );
        require(
            vaultStatus == VaultStatus.PreAuction ||
                vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );

        require(tradeStartDate != 0, Errors.VALUE_IS_ZERO);

        vault.auctionWinner = auctionWinner;
        vault.tradeStartDate = tradeStartDate;

        fcnVault.aprBps = aprBps;
        uint128[] memory initialSpotPrices = new uint128[](dataSources.length);

        if (fcnVault.barrierData.length == 0) {
            fcnVault.barrierData = new FCNVaultBarrierData[](
                dataSources.length
            );
        }

        for (uint256 index = 0; index < dataSources.length; index++) {
            initialSpotPrices[index] = FCNVaultLogic.getSpotPriceAt(
                cgs,
                vaultAddress,
                IOracleEntry(addressManager.getCegaOracle()),
                fcnProduct.optionBarriers[index].asset,
                dataSources[index],
                tradeStartDate
            );

            fcnVault.barrierData[index] = FCNVaultBarrierData({
                dataSource: dataSources[index],
                initialSpotPrice: initialSpotPrices[index]
            });
        }

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Auctioned);

        emit IFCNEvents.FCNAuctionEnded(
            vaultAddress,
            auctionWinner,
            tradeStartDate,
            aprBps,
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
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];

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

        require(
            !VaultLogic.getIsAuctionDefaulted(
                cgs,
                vaultAddress,
                fcnProduct.hoursToStartAuctionDefault
            ),
            Errors.TRADE_DEFAULTED
        );

        // Transfer the premium + any applicable late fee
        uint40 tradeStartDate = vault.tradeStartDate;
        address depositAsset = FCNProductLogic.fcnGetProductDepositAsset(
            fcnProduct
        );
        uint128 totalAssets = vault.totalAssets;
        uint16 aprBps = fcnVault.aprBps;
        uint40 tenorInSeconds = fcnProduct.tenorInSeconds;

        // prices are 0 until we modify the NFT Metadata
        nftMetadata = MMNFTMetadata({
            vaultAddress: vaultAddress,
            tradeStartDate: tradeStartDate,
            tradeEndDate: tradeStartDate + tenorInSeconds,
            notional: totalAssets,
            aprBps: aprBps,
            initialSpotPrice: 0,
            strikePrice: 0,
            extraData: bytes("")
        });

        uint128 totalYield = VaultLogic.calculateAmountFromApr(
            totalAssets,
            tradeStartDate,
            aprBps,
            tradeStartDate + tenorInSeconds
        );
        fcnVault.totalYield = totalYield;
        uint128 lateFee = VaultLogic.calculateLateFee(
            totalYield,
            tradeStartDate,
            fcnProduct.lateFeeBps,
            fcnProduct.hoursToStartLateFees,
            fcnProduct.hoursToStartAuctionDefault
        );

        fcnVault.notional = totalAssets;

        if (fcnProduct.isBondOption) {
            require(
                cgs.bondAllowList[msg.sender],
                Errors.UNAUTHORIZED_BOND_RECEIVER
            );

            vault.totalAssets = totalYield;
            treasury.withdraw(depositAsset, msg.sender, totalAssets, false);
        } else {
            vault.totalAssets = totalAssets + totalYield;
        }

        if (lateFee > 0) {
            nativeValueReceived = depositAsset.receiveTo(
                addressManager.getCegaFeeReceiver(),
                lateFee
            );
            emit IFCNEvents.FCNLateFeePaid(vaultAddress, lateFee);
        }

        nativeValueReceived += depositAsset.receiveTo(
            address(treasury),
            totalYield
        );

        fcnProduct.sumVaultUnderlyingAmounts += totalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Traded);

        if (tradeWinnerNFT != address(0)) {
            uint256 tokenId = ITradeWinnerNFT(tradeWinnerNFT).mint(
                msg.sender,
                nftMetadata
            );
            vault.auctionWinnerTokenId = tokenId.toUint64();
        }

        emit IFCNEvents.FCNTradeStarted(
            vaultAddress,
            msg.sender,
            totalAssets,
            totalYield
        );
    }

    function checkTradeExpiry(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;
        if (
            vaultStatus != VaultStatus.Traded &&
            vaultStatus != VaultStatus.AwaitingSettlement
        ) {
            return;
        }

        uint40 tenorInSeconds = fcnProduct.tenorInSeconds;
        uint40 tradeStartDate = vault.tradeStartDate;
        uint256 currentTime = block.timestamp;
        if (currentTime <= tradeStartDate + tenorInSeconds) {
            return;
        }

        (bool isKnockedIn, ) = checkBarriers(
            cgs,
            addressManager,
            vaultAddress,
            type(uint16).max
        );

        if (
            isKnockedIn ||
            vault.totalAssets < fcnVault.notional + fcnVault.totalYield
        ) {
            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.AwaitingSettlement
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
        }
    }

    function checkBarriers(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint16 maxObservations
    ) internal returns (bool isKnockedIn, uint16 observationsCount) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        require(
            vault.vaultStatus == VaultStatus.Traded,
            Errors.INVALID_VAULT_STATUS
        );

        uint40 tradeStartDate = vault.tradeStartDate;
        uint40 tradeEndDate = tradeStartDate + fcnProduct.tenorInSeconds;
        uint40 observationInterval = fcnProduct.observationIntervalInSeconds;
        uint40 observationsDone = fcnVault.observationsDone;
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
            return (fcnVault.isKnockedIn, 0);
        }

        observationsCount = ((observationEnd - observationStart) /
            observationInterval +
            1).toUint16();

        uint256 barriersLength = fcnVault.barrierData.length;

        FCNOptionBarrier memory optionBarrier;
        uint128 barrierAbsoluteValue;

        for (uint256 i = 0; i < barriersLength; i++) {
            if (
                fcnProduct.optionBarriers[i].barrierType ==
                FCNOptionBarrierType.KnockIn
            ) {
                optionBarrier = fcnProduct.optionBarriers[i];
                barrierAbsoluteValue =
                    (fcnVault.barrierData[i].initialSpotPrice *
                        optionBarrier.barrierBps) /
                    BPS_DECIMALS;
                IOracleEntry.DataSource dataSource = fcnVault
                    .barrierData[i]
                    .dataSource;

                for (
                    uint40 observationTime = observationStart;
                    observationTime <= observationEnd;
                    observationTime += observationInterval
                ) {
                    uint128 observationSpotPrice = getSpotPriceAt(
                        cgs,
                        vaultAddress,
                        oracleEntry,
                        optionBarrier.asset,
                        dataSource,
                        observationTime
                    );
                    if (observationSpotPrice <= barrierAbsoluteValue) {
                        isKnockedIn = true;
                        break;
                    }
                }
                if (isKnockedIn) {
                    break;
                }
            } else {
                revert(Errors.UNKNOWN_BARRIER_TYPE);
            }
        }

        if (isKnockedIn) {
            fcnVault.observationsDone = type(uint16).max;
            fcnVault.isKnockedIn = true;
        } else {
            fcnVault.observationsDone += observationsCount;
        }

        emit IFCNEvents.FCNIsKnockedInUpdated(vaultAddress, isKnockedIn);
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
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        if (vault.isDefaulted) {
            return;
        }

        uint256 hoursLate = VaultLogic.getHoursLate(
            vault.tradeStartDate + fcnProduct.tenorInSeconds
        );
        if (
            hoursLate >= fcnProduct.hoursToStartSettlementDefault &&
            vault.vaultStatus == VaultStatus.AwaitingSettlement
        ) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
            if (fcnProduct.isBondOption) {
                uint128 unpaidBond = fcnVault.notional +
                    fcnVault.totalYield -
                    vault.totalAssets;
                fcnProduct.sumVaultUnderlyingAmounts -= unpaidBond;
            }
        }
    }

    function repayBond(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        address vaultAddress,
        uint128 amount
    ) internal returns (uint256 nativeValueReceived) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        require(fcnProduct.isBondOption, Errors.INVALID_VAULT);
        require(
            vault.vaultStatus == VaultStatus.Traded,
            Errors.INVALID_VAULT_STATUS
        );
        uint128 currentAssets = vault.totalAssets;
        require(
            currentAssets + amount <= fcnVault.notional + fcnVault.totalYield,
            Errors.VALUE_TOO_LARGE
        );

        vault.totalAssets = currentAssets + amount;
        nativeValueReceived = fcnProduct.underlyingAsset.receiveTo(
            address(treasury),
            amount
        );

        emit IFCNEvents.FCNBondRepaid(vaultAddress, amount);
    }

    function settleVault(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress
    ) internal returns (uint256 nativeValueReceived) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement,
            Errors.INVALID_VAULT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >
                vault.tradeStartDate +
                    fcnProduct.tenorInSeconds +
                    (uint256(fcnProduct.disputeGraceDelayInHours) * 1 hours),
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

        uint128 bondAmount;
        if (fcnProduct.isBondOption) {
            bondAmount =
                fcnVault.notional +
                fcnVault.totalYield -
                vault.totalAssets;
        }
        uint128 lostCapital = getVaultLostCapital(
            cgs,
            addressManager,
            vaultAddress
        );

        fcnProduct.sumVaultUnderlyingAmounts -= lostCapital;

        if (bondAmount > lostCapital) {
            vault.totalAssets += (bondAmount - lostCapital);
            nativeValueReceived = fcnProduct.underlyingAsset.receiveTo(
                address(treasury),
                bondAmount - lostCapital
            );
        } else {
            vault.totalAssets -= (lostCapital - bondAmount);
            treasury.withdraw(
                fcnProduct.underlyingAsset,
                msg.sender,
                lostCapital - bondAmount,
                false
            );
        }

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
    }

    function rolloverVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.WithdrawalQueueProcessed,
            Errors.INVALID_VAULT_STATUS
        );
        uint40 tradeEndDate = vault.tradeStartDate + fcnProduct.tenorInSeconds;

        require(tradeEndDate != 0, Errors.INVALID_TRADE_END_DATE);

        if (!vault.isDefaulted) {
            uint256 barriersLength = fcnVault.barrierData.length;

            for (uint256 i = 0; i < barriersLength; i++) {
                delete cgs.oraclePriceOverride[vaultAddress][
                    VaultLogic.getAssetCode(fcnProduct.optionBarriers[i].asset)
                ][tradeEndDate];
            }

            vault.tradeStartDate = 0;
            vault.auctionWinner = address(0);
            vault.auctionWinnerTokenId = 0;

            delete fcnVault.barrierData;
            fcnVault.aprBps = 0;
            fcnVault.observationsDone = 0;
            fcnVault.totalYield = 0;
            fcnVault.notional = 0;
            fcnVault.isKnockedIn = false;

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.DepositsOpen
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Zombie);
        }

        emit IFCNEvents.FCNVaultRolledOver(vaultAddress);
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
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];

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
                    fcnProduct.tenorInSeconds +
                    (uint256(fcnProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        uint128 totalAssets = vault.totalAssets;
        uint128 notional = fcnVault.notional;
        uint128 profit = totalAssets > notional ? totalAssets - notional : 0;

        (
            uint128 totalFees,
            uint128 managementFee,
            uint128 yieldFee
        ) = VaultLogic.calculateFees(
                cgs,
                vaultAddress,
                fcnProduct.tenorInSeconds,
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
            FCNProductLogic.fcnGetProductDepositAsset(fcnProduct),
            addressManager.getCegaFeeReceiver(),
            totalFees,
            true
        );

        fcnProduct.sumVaultUnderlyingAmounts -= uint128(totalFees);

        emit IFCNEvents.FCNVaultFeesCollected(
            vaultAddress,
            totalFees,
            managementFee,
            yieldFee
        );
    }

    function checkAuctionDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        uint32 productId = cgs.vaults[vaultAddress].productId;

        bool isDefaulted = VaultLogic.getIsAuctionDefaulted(
            cgs,
            vaultAddress,
            cgs.fcnProducts[productId].hoursToStartAuctionDefault
        );
        if (isDefaulted) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
        }
    }

    function checkSingleBarrier(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp
    ) internal returns (bool isKnockedIn) {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vault.productId];

        IOracleEntry oracleEntry = IOracleEntry(addressManager.getCegaOracle());

        FCNVaultBarrierData memory barrierData = fcnVault.barrierData[
            barrierIndex
        ];
        FCNOptionBarrier memory optionBarrier = fcnProduct.optionBarriers[
            barrierIndex
        ];

        if (optionBarrier.barrierType == FCNOptionBarrierType.KnockIn) {
            uint128 barrierAbsoluteValue = (barrierData.initialSpotPrice *
                optionBarrier.barrierBps) / BPS_DECIMALS;

            uint128 observationSpotPrice = getSpotPriceAt(
                cgs,
                vaultAddress,
                oracleEntry,
                optionBarrier.asset,
                barrierData.dataSource,
                timestamp
            );
            if (observationSpotPrice <= barrierAbsoluteValue) {
                isKnockedIn = true;
                fcnVault.isKnockedIn = isKnockedIn;
                emit IFCNEvents.FCNIsKnockedInUpdated(
                    vaultAddress,
                    isKnockedIn
                );
            }
        } else {
            revert(Errors.UNKNOWN_BARRIER_TYPE);
        }
    }

    function disputeVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp,
        IAddressManager addressManager
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
        FCNProduct storage product = cgs.fcnProducts[vault.productId];

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
                        timestamp < currentTime &&
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

            require(
                vaultStatus == VaultStatus.AwaitingSettlement ||
                    (!fcnVault.isKnockedIn &&
                        vaultStatus == VaultStatus.Settled),
                Errors.INVALID_VAULT_STATUS
            );
        }

        vault.isInDispute = true;

        emit IFCNEvents.FCNDisputeSubmitted(
            vaultAddress,
            barrierIndex,
            timestamp
        );
    }

    function processDispute(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp,
        uint128 newPrice
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        FCNProduct storage product = cgs.fcnProducts[vault.productId];

        require(vault.isInDispute, Errors.VAULT_NOT_IN_DISPUTE);

        if (newPrice != 0) {
            VaultStatus vaultStatus = vault.vaultStatus;

            address asset = product.optionBarriers[barrierIndex].asset;
            VaultLogic.overrideOraclePrice(
                cgs,
                vaultAddress,
                asset,
                timestamp,
                newPrice
            );

            bool isKnockedIn = checkSingleBarrier(
                cgs,
                addressManager,
                vaultAddress,
                barrierIndex,
                timestamp
            );

            if (vaultStatus == VaultStatus.Traded) {
                FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
                fcnVault.isKnockedIn = isKnockedIn;
                emit IFCNEvents.FCNIsKnockedInUpdated(
                    vaultAddress,
                    isKnockedIn
                );

                if (!isKnockedIn) {
                    // rerun all observations as we don't know which timestamp knocked-out aside from this one.
                    fcnVault.observationsDone = 0;
                }
            } else if (vaultStatus == VaultStatus.Settled && isKnockedIn) {
                VaultLogic.setVaultStatus(
                    cgs,
                    vaultAddress,
                    VaultStatus.AwaitingSettlement
                );
            } else if (
                vaultStatus == VaultStatus.AwaitingSettlement && !isKnockedIn
            ) {
                FCNVault storage fcnVault = cgs.fcnVaults[vaultAddress];
                // rerun all observations as we don't know which timestamp KnockedIn aside from this one.
                fcnVault.observationsDone = 0;

                fcnVault.isKnockedIn = isKnockedIn;
                emit IFCNEvents.FCNIsKnockedInUpdated(
                    vaultAddress,
                    isKnockedIn
                );

                // to force check expiry again
                VaultLogic.setVaultStatus(
                    cgs,
                    vaultAddress,
                    VaultStatus.Traded
                );
            }
        }

        vault.isInDispute = false;

        emit IFCNEvents.FCNDisputeProcessed(
            vaultAddress,
            newPrice != 0,
            barrierIndex,
            timestamp,
            newPrice
        );
    }
}
