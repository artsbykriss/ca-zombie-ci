// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    IERC721AUpgradeable
} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    MMNFTMetadata,
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams,
    ProcessQueueParams,
    RotationStrategyParams
} from "../../../Structs.sol";
import { ITradeWinnerNFT } from "../../../aux/interfaces/ITradeWinnerNFT.sol";
import { DCSProduct, DCSVault, DCSOptionType } from "../DCSStructs.sol";
import { Transfers } from "../../../utils/Transfers.sol";
import { Errors } from "../../../utils/Errors.sol";
import { AddressManagement } from "../../../utils/AddressManagement.sol";
import { DCSVaultLogic } from "./DCSVaultLogic.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { ICegaVault } from "../../../vaults/interfaces/ICegaVault.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import {
    IRedepositManager
} from "../../../aux/interfaces/IRedepositManager.sol";
import { IWrappingProxy } from "../../../proxies/interfaces/IWrappingProxy.sol";
import { ISwapManager } from "../../../swaps/interfaces/ISwapManager.sol";
import { IDCSEvents } from "../interfaces/IDCSEvents.sol";

library DCSLogic {
    using Transfers for address;
    using SafeCast for uint256;
    using AddressManagement for IAddressManager;

    // CONSTANTS

    uint128 private constant BPS_DECIMALS = 1e4;

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    function getProductSwapAsset(
        CegaGlobalStorage storage cgs,
        uint32 productId
    ) internal view returns (address) {
        DCSProduct storage product = cgs.dcsProducts[productId];
        return
            product.dcsOptionType == DCSOptionType.BuyLow
                ? product.baseAssetAddress
                : product.quoteAssetAddress;
    }

    /**
     * @dev Retrieves the deposit asset for a given DCS product.
     * @param dcsProduct The DCS product.
     * @return The address of the deposit asset.
     */
    function dcsGetProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    /**
     * @dev Gets the deposit and swap assets for a given DCS product.
     * @param dcsProduct The DCS product.
     * @return depositAsset The address of the deposit asset.
     * @return swapAsset The address of the swap asset.
     * @return dcsOptionType The option type of the DCS product.
     */
    function getDCSProductDepositAndSwapAsset(
        DCSProduct storage dcsProduct
    )
        internal
        view
        returns (
            address depositAsset,
            address swapAsset,
            DCSOptionType dcsOptionType
        )
    {
        dcsOptionType = dcsProduct.dcsOptionType;

        if (dcsOptionType == DCSOptionType.BuyLow) {
            depositAsset = dcsProduct.quoteAssetAddress;
            swapAsset = dcsProduct.baseAssetAddress;
        } else {
            depositAsset = dcsProduct.baseAssetAddress;
            swapAsset = dcsProduct.quoteAssetAddress;
        }
    }

    /**
     * @dev Retrieves the settlement asset for a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return address The address of the settlement asset.
     */
    function getVaultSettlementAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (address) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        if (dcsProduct.dcsOptionType == DCSOptionType.BuyLow) {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.quoteAssetAddress
                    : dcsProduct.baseAssetAddress;
        } else {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.baseAssetAddress
                    : dcsProduct.quoteAssetAddress;
        }
    }

    /**
     * @dev Gets the spot price at a given timestamp.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param addressManager The address manager.
     * @param priceTimestamp The timestamp for the price.
     * @return The spot price at the given timestamp.
     */
    function getSpotPriceAt(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        IAddressManager addressManager,
        uint40 priceTimestamp
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint128 price = cgs.oraclePriceOverride[vaultAddress][
            VaultLogic.getAssetCode(address(0))
        ][priceTimestamp];

        if (price > 0) {
            return price;
        }

        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // We always use baseAsset, even if the deposit asset is quote asset, because we
        // need to express the units of quote asset in terms of base asset
        return
            iOracleEntry.getPrice(
                dcsProduct.baseAssetAddress,
                dcsProduct.quoteAssetAddress,
                priceTimestamp,
                vault.dataSource
            );
    }

    /**
     * @dev Converts deposit units to swap asset units.
     * @param amountToConvert The amount to convert.
     * @param addressManager The address manager.
     * @param conversionPrice The conversion price.
     * @param depositAssetDecimals The decimals of the deposit asset.
     * @param swapAssetDecimals The decimals of the swap asset.
     * @param dcsOptionType The DCS option type.
     * @return uint128 The converted amount.
     */
    function convertDepositUnitsToSwap(
        uint256 amountToConvert,
        IAddressManager addressManager,
        uint128 conversionPrice,
        uint8 depositAssetDecimals,
        uint8 swapAssetDecimals,
        DCSOptionType dcsOptionType
    ) internal view returns (uint128) {
        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // Calculating the notionalInSwapAsset is different because finalSpotPrice is always
        // in units of quote / base.
        uint256 convertedAmount;
        if (dcsOptionType == DCSOptionType.BuyLow) {
            convertedAmount =
                (
                    (amountToConvert *
                        10 **
                            (swapAssetDecimals +
                                iOracleEntry.getTargetDecimals()))
                ) /
                (conversionPrice * 10 ** depositAssetDecimals);
        } else {
            convertedAmount = ((amountToConvert *
                conversionPrice *
                10 ** (swapAssetDecimals)) /
                (10 **
                    (depositAssetDecimals + iOracleEntry.getTargetDecimals())));
        }
        return convertedAmount.toUint128();
    }

    /**
     * @dev Checks if a swap is occurring based on option type and price conditions.
     * @param finalSpotPrice The final spot price.
     * @param strikePrice The strike price.
     * @param dcsOptionType The DCS option type.
     * @return bool True if a swap is occurring, false otherwise.
     */
    function isSwapOccurring(
        uint128 finalSpotPrice,
        uint128 strikePrice,
        DCSOptionType dcsOptionType
    ) internal pure returns (bool) {
        if (dcsOptionType == DCSOptionType.BuyLow) {
            return finalSpotPrice < strikePrice;
        } else {
            return finalSpotPrice > strikePrice;
        }
    }

    /**
     * @dev Calculates the final payoff for a vault.
     * @param cgs The Cega global storage.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     * @return uint128 The final payoff amount.
     */
    function calculateVaultFinalPayoff(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement ||
                vault.vaultStatus == VaultStatus.Settled,
            Errors.INVALID_VAULT_STATUS
        );

        if (
            !dcsVault.isPayoffInDepositAsset &&
            vault.vaultStatus != VaultStatus.Settled
        ) {
            (
                address depositAsset,
                address swapAsset,

            ) = getDCSProductDepositAndSwapAsset(dcsProduct);
            uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(
                depositAsset
            );
            uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

            return
                convertDepositUnitsToSwap(
                    vault.totalAssets,
                    addressManager,
                    dcsVault.strikePrice,
                    depositAssetDecimals,
                    swapAssetDecimals,
                    dcsProduct.dcsOptionType
                );
        } else {
            // totalAssets already has totalYield included inside, because premium is paid upfront
            return vault.totalAssets;
        }
    }

    // MUTATIVE FUNCTIONS

    function endAuction(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        address _auctionWinner,
        uint40 _tradeStartDate,
        uint16 _aprBps,
        IOracleEntry.DataSource _dataSource
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        require(
            vaultStatus == VaultStatus.PreAuction ||
                vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );

        require(_tradeStartDate != 0, Errors.VALUE_IS_ZERO);

        vault.auctionWinner = _auctionWinner;
        vault.tradeStartDate = _tradeStartDate;
        vault.dataSource = _dataSource;

        dcsVault.aprBps = _aprBps;
        uint128 initialSpotPrice = getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            vault.tradeStartDate
        );
        dcsVault.initialSpotPrice = initialSpotPrice;

        uint128 strikePrice = (dcsVault.initialSpotPrice *
            dcsProduct.strikeBarrierBps) / BPS_DECIMALS;
        dcsVault.strikePrice = strikePrice;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Auctioned);

        emit IDCSEvents.DCSAuctionEnded(
            vaultAddress,
            _auctionWinner,
            _tradeStartDate,
            _aprBps,
            initialSpotPrice,
            strikePrice
        );
    }

    /**
     * @dev Checks for trade expiry for a specific vault.
     * @param cgs The Cega global storage.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     */
    function checkTradeExpiry(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        if (
            (vaultStatus != VaultStatus.Traded &&
                vaultStatus != VaultStatus.AwaitingSettlement) ||
            vault.isInDispute
        ) {
            return;
        }

        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;
        uint40 tradeStartDate = vault.tradeStartDate;
        uint256 currentTime = block.timestamp;
        if (currentTime <= tradeStartDate + tenorInSeconds) {
            return;
        }

        uint128 finalSpotPrice = getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            tradeStartDate + tenorInSeconds
        );
        if (
            isSwapOccurring(
                finalSpotPrice,
                dcsVault.strikePrice,
                dcsProduct.dcsOptionType
            )
        ) {
            DCSVaultLogic.setIsPayoffInDepositAsset(cgs, vaultAddress, false);

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.AwaitingSettlement
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
        }
    }

    /**
     * @dev Checks for settlement default for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function checkSettlementDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint256 hoursLate = VaultLogic.getHoursLate(
            vault.tradeStartDate + dcsProduct.tenorInSeconds
        );
        if (
            hoursLate >= dcsProduct.hoursToStartSettlementDefault &&
            vault.vaultStatus == VaultStatus.AwaitingSettlement
        ) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
            DCSVaultLogic.setIsPayoffInDepositAsset(cgs, vaultAddress, true);
        }
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
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived, MMNFTMetadata memory nftMetadata)
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;

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
                dcsProduct.hoursToStartAuctionDefault
            ),
            Errors.TRADE_DEFAULTED
        );

        // Transfer the premium + any applicable late fee
        uint40 tradeStartDate = vault.tradeStartDate;
        address depositAsset = dcsGetProductDepositAsset(dcsProduct);
        uint128 totalAssets = vault.totalAssets;
        uint16 aprBps = dcsVault.aprBps;

        nftMetadata = MMNFTMetadata({
            vaultAddress: vaultAddress,
            tradeStartDate: tradeStartDate,
            tradeEndDate: tradeStartDate + tenorInSeconds,
            notional: totalAssets,
            aprBps: aprBps,
            initialSpotPrice: dcsVault.initialSpotPrice,
            strikePrice: dcsVault.strikePrice,
            extraData: bytes("")
        });

        uint128 totalYield = VaultLogic.calculateAmountFromApr(
            totalAssets,
            tradeStartDate,
            aprBps,
            tradeStartDate + tenorInSeconds
        );
        dcsVault.totalYield = totalYield;
        uint128 lateFee = VaultLogic.calculateLateFee(
            totalYield,
            tradeStartDate,
            dcsProduct.lateFeeBps,
            dcsProduct.hoursToStartLateFees,
            dcsProduct.hoursToStartAuctionDefault
        );
        // Send deposit to treasury, and late fee to fee recipient
        if (lateFee > 0) {
            nativeValueReceived = depositAsset.receiveTo(
                addressManager.getCegaFeeReceiver(),
                lateFee
            );
            emit IDCSEvents.DCSLateFeePaid(vaultAddress, lateFee);
        }

        nativeValueReceived += depositAsset.receiveTo(
            address(treasury),
            totalYield
        );
        // Late fee is not used for coupon payment or for user payouts
        uint128 notionalAmount = vault.totalAssets;
        vault.totalAssets = notionalAmount + totalYield;
        dcsProduct.sumVaultUnderlyingAmounts += totalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Traded);

        if (tradeWinnerNFT != address(0)) {
            uint256 tokenId = ITradeWinnerNFT(tradeWinnerNFT).mint(
                msg.sender,
                nftMetadata
            );
            vault.auctionWinnerTokenId = tokenId.toUint64();
        }

        emit IDCSEvents.DCSTradeStarted(
            vaultAddress,
            msg.sender,
            notionalAmount,
            totalYield
        );
    }

    /**
     * @dev Checks for auction default for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function checkAuctionDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        uint32 productId = cgs.vaults[vaultAddress].productId;

        bool isDefaulted = VaultLogic.getIsAuctionDefaulted(
            cgs,
            vaultAddress,
            cgs.dcsProducts[productId].hoursToStartAuctionDefault
        );
        if (isDefaulted) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
        }
    }

    /**
     * @dev Settles a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @return nativeValueReceived The native value received.
     */
    function settleVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived)
    {
        (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        ) = prepareSettleVault(cgs, addressManager, vaultAddress);

        // After converting units, we actually transfer the depositAsset to nftHolder and receive swapAsset from nftHolder
        treasury.withdraw(depositAsset, msg.sender, depositTotalAssets, false);
        nativeValueReceived = swapAsset.receiveTo(
            address(treasury),
            convertedTotalAssets
        );

        emit IDCSEvents.DCSVaultSettled(
            vaultAddress,
            msg.sender,
            convertedTotalAssets,
            depositTotalAssets
        );
    }

    function swapAndSettleVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        ISwapManager.SwapProtocol swapProtocol,
        ISwapManager.SwapData calldata swapData,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived)
    {
        (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        ) = prepareSettleVault(cgs, addressManager, vaultAddress);

        ISwapManager swapManager = ISwapManager(
            addressManager.getSwapManager()
        );
        treasury.withdraw(
            depositAsset,
            swapManager.swapProtocolAdapters(swapProtocol),
            depositTotalAssets,
            true
        );
        uint128 outputAmount = ISwapManager(swapManager).swap(
            depositAsset,
            swapAsset,
            depositTotalAssets,
            address(treasury),
            swapProtocol,
            swapData
        );

        if (outputAmount > convertedTotalAssets) {
            treasury.withdraw(
                swapAsset,
                msg.sender,
                outputAmount - convertedTotalAssets,
                false
            );
        } else if (outputAmount < convertedTotalAssets) {
            nativeValueReceived = swapAsset.receiveTo(
                address(treasury),
                convertedTotalAssets - outputAmount
            );
        }

        emit IDCSEvents.DCSVaultSettled(
            vaultAddress,
            msg.sender,
            convertedTotalAssets,
            depositTotalAssets
        );
    }

    function prepareSettleVault(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    )
        internal
        returns (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        )
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
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
        require(
            dcsVault.isPayoffInDepositAsset == false,
            Errors.TRADE_NOT_CONVERTED
        );
        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement,
            Errors.INVALID_VAULT_STATUS
        );

        require(
            block.timestamp >
                vault.tradeStartDate +
                    dcsProduct.tenorInSeconds +
                    (uint256(dcsProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        checkSettlementDefault(cgs, vaultAddress);

        require(!vault.isDefaulted, Errors.TRADE_DEFAULTED);

        DCSOptionType dcsOptionType;
        (
            depositAsset,
            swapAsset,
            dcsOptionType
        ) = getDCSProductDepositAndSwapAsset(dcsProduct);

        // First, store the totalAssets and totalYield in depositAsset units
        depositTotalAssets = vault.totalAssets;
        uint128 depositTotalYield = dcsVault.totalYield;
        uint128 strikePrice = dcsVault.strikePrice;
        uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(depositAsset);
        uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

        // Then, calculate the totalAssets and totalYield in swapAsset units
        convertedTotalAssets = convertDepositUnitsToSwap(
            depositTotalAssets,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );
        uint128 convertedTotalYield = convertDepositUnitsToSwap(
            depositTotalYield,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );

        // Then, update state. Store the new converted amounts of totalAssets and totalYield
        // and subtract assets from sumVaultUnderlyingAmounts. We've converted, so this vault
        // no longer applies to sumVaultUnderlyingAmounts
        dcsProduct.sumVaultUnderlyingAmounts -= depositTotalAssets;
        vault.totalAssets = convertedTotalAssets;
        dcsVault.totalYield = convertedTotalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
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
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;

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
                    tenorInSeconds +
                    (uint256(dcsProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        uint128 totalYield = dcsVault.totalYield;

        (
            uint128 totalFees,
            uint128 managementFee,
            uint128 yieldFee
        ) = VaultLogic.calculateFees(
                cgs,
                vaultAddress,
                tenorInSeconds,
                vault.totalAssets - totalYield,
                totalYield
            );

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.FeesCollected);
        vault.totalAssets -= totalFees;

        treasury.withdraw(
            getVaultSettlementAsset(cgs, vaultAddress),
            addressManager.getCegaFeeReceiver(),
            totalFees,
            true
        );

        if (dcsVault.isPayoffInDepositAsset) {
            dcsProduct.sumVaultUnderlyingAmounts -= uint128(totalFees);
        }

        emit IDCSEvents.DCSVaultFeesCollected(
            vaultAddress,
            totalFees,
            managementFee,
            yieldFee
        );
    }

    function dcsDecreaseSumVaultUnderlyingAmounts(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 assetAmount
    ) internal {
        cgs.dcsProducts[productId].sumVaultUnderlyingAmounts -= assetAmount;
    }

    function dcsAddToWithdrawalQueueHook(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assetAmount
    ) internal {
        if (
            cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset ||
            cgs.vaults[vaultAddress].isDefaulted
        ) {
            cgs
                .dcsProducts[cgs.vaults[vaultAddress].productId]
                .sumVaultUnderlyingAmounts -= assetAmount;
        }
    }

    function dcsProcessDepositQueueHook(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 totalDepositsAmount
    ) internal {
        cgs
            .dcsProducts[productId]
            .sumVaultUnderlyingAmounts += totalDepositsAmount;
    }

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address treasury,
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] memory rotationStrategyParams
    ) internal {
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        ProductLogic.addToDepositQueue(
            cgs,
            addressManager,
            treasury,
            AddToDepositQueueParams({
                productId: productId,
                amount: amount,
                receiver: receiver,
                depositAsset: dcsGetProductDepositAsset(dcsProduct),
                isDepositQueueOpen: dcsProduct.isDepositQueueOpen,
                minDepositAmount: dcsProduct.minDepositAmount,
                sumVaultUnderlyingAmounts: dcsProduct.sumVaultUnderlyingAmounts,
                maxUnderlyingAmountLimit: dcsProduct.maxUnderlyingAmountLimit,
                rotationStrategyParams: rotationStrategyParams
            })
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        uint32 productId,
        uint128 amount
    ) internal {
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        ProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            RemoveFromDepositQueueParams({
                productId: productId,
                amount: amount,
                depositor: msg.sender,
                depositAsset: dcsGetProductDepositAsset(dcsProduct),
                minDepositAmount: dcsProduct.minDepositAmount
            })
        );
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vaultData.productId];
        ProductLogic.withdrawOrAddToWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            sharesAmount,
            nextProductId,
            useProxy,
            dcsProduct.minWithdrawalAmount,
            getVaultSettlementAsset(cgs, vaultAddress),
            DCSLogic.dcsAddToWithdrawalQueueHook
        );
    }
}
