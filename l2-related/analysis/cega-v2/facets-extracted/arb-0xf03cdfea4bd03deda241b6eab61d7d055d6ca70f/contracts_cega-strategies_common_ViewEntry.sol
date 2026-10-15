// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IViewEntry } from "./interfaces/IViewEntry.sol";
import {
    Vault,
    Withdrawer,
    WithdrawalQueue,
    DCS_STRATEGY_ID,
    FCN_STRATEGY_ID,
    SFN_STRATEGY_ID,
    ProductMetadata,
    DepositQueue,
    VaultStatus,
    RotationStrategy
} from "../../Structs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { CegaGlobalStorage } from "../../storage/CegaStorage.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "./EntryBase.sol";
import { VaultLogic } from "./lib/VaultLogic.sol";
import { ProductLogic } from "./lib/ProductLogic.sol";
import { DCSVaultLogic } from "../dcs/lib/DCSVaultLogic.sol";
import { DCSLogic } from "../dcs/lib/DCSLogic.sol";
import { FCNVaultLogic } from "../fcn/lib/FCNVaultLogic.sol";
import { SFNVaultLogic } from "../sfn/lib/SFNVaultLogic.sol";

contract ViewEntry is IViewEntry, EntryBase {
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // VIEW FUNCTIONS

    function getVaultUsersWithRotations(
        address vaultAddress
    ) external view returns (address[] memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.vaultRotationData[vaultAddress].usersWithRotations;
    }

    function getIsUserAddedToVaultRotationList(
        address user,
        address vaultAddress
    ) external view returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.vaultRotationData[vaultAddress].userHasRotation[user];
    }

    function getUserRotationStrategy(
        address user,
        uint32 productId
    ) external view returns (RotationStrategy memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.rotationStrategies[user][productId];
    }

    // TODO make two functions one for DCS and one for FCN
    /**
     * @notice Retrieves the overridden oracle price for a specific vault at a given timestamp.
     * @param vaultAddress The address of the vault.
     * @param timestamp The timestamp for which the price is overridden.
     * @return The overridden oracle price.
     */
    function getOraclePriceOverride(
        address vaultAddress,
        uint40 timestamp
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();

        return
            cgs.oraclePriceOverride[vaultAddress][
                VaultLogic.getAssetCode(address(0))
            ][timestamp];
    }

    /**
     * @notice Retrieves the details of a specific vault.
     * @param vaultAddress The address of the vault.
     * @return A `Vault` struct containing details of the vault.
     */
    function getVault(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (Vault memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.vaults[vaultAddress];
    }

    /**
     * @notice Retrieves the product ID associated with a given vault.
     * @param vault The address of the vault.
     * @return The product ID of the vault.
     */
    function getVaultProductId(address vault) external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();

        return cgs.vaults[vault].productId;
    }

    /**
     * @notice Checks if a specific vault is defaulted.
     * @param vaultAddress The address of the vault.
     * @return True if the vault is defaulted, otherwise false.
     */
    function getIsAuctionDefaulted(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategy = cgs.strategyOfProduct[productId];
        uint8 hoursToStartAuctionDefault;

        if (strategy == DCS_STRATEGY_ID) {
            hoursToStartAuctionDefault = cgs
                .dcsProducts[productId]
                .hoursToStartAuctionDefault;
        } else if (strategy == FCN_STRATEGY_ID) {
            hoursToStartAuctionDefault = cgs
                .fcnProducts[productId]
                .hoursToStartAuctionDefault;
        } else if (strategy == SFN_STRATEGY_ID) {
            hoursToStartAuctionDefault = cgs
                .sfnProducts[productId]
                .hoursToStartAuctionDefault;
        }

        return
            VaultLogic.getIsAuctionDefaulted(
                cgs,
                vaultAddress,
                hoursToStartAuctionDefault
            );
    }

    /**
     * @notice Calculates the number of days a specific vault is late.
     * @param vaultAddress The address of the vault.
     * @return The number of days the vault is late.
     */
    function getHoursLate(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.getHoursLate(cgs.vaults[vaultAddress].tradeStartDate);
    }

    /**
     * @notice Retrieves the total assets held by a specific vault.
     * @param vaultAddress The address of the vault.
     * @return The total assets of the vault.
     */
    function totalAssets(address vaultAddress) external view returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.totalAssets(cgs, vaultAddress);
    }

    /**
     * @notice Converts a specified amount of shares to assets for a given vault.
     * @param vaultAddress The address of the vault.
     * @param shares The number of shares to convert.
     * @return The equivalent asset amount.
     */
    function convertToAssets(
        address vaultAddress,
        uint256 shares
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.convertToAssets(cgs, vaultAddress, shares);
    }

    /**
     * @notice Converts a specified amount of assets to shares for a given vault.
     * @param vaultAddress The address of the vault.
     * @param assets The amount of assets to convert.
     * @return The equivalent number of shares.
     */
    function convertToShares(
        address vaultAddress,
        uint128 assets
    ) external view returns (uint256) {
        CegaGlobalStorage storage cgs = getStorage();

        uint256 _totalSupply = IERC20(vaultAddress).totalSupply();
        uint128 _totalAssets = VaultLogic.totalAssets(cgs, vaultAddress);

        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategy = cgs.strategyOfProduct[productId];
        address depositAsset;
        if (strategy == DCS_STRATEGY_ID) {
            depositAsset = DCSVaultLogic.getProductDepositAsset(
                cgs.dcsProducts[productId]
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            depositAsset = cgs.fcnProducts[productId].underlyingAsset;
        } else if (strategy == SFN_STRATEGY_ID) {
            depositAsset = cgs.sfnProducts[productId].underlyingAsset;
        }

        return
            VaultLogic.convertToShares(
                _totalSupply,
                _totalAssets,
                VaultLogic.getAssetDecimals(depositAsset),
                assets
            );
    }

    function getWithdrawalQueue(
        address vaultAddress
    )
        external
        view
        returns (
            Withdrawer[] memory withdrawers,
            uint256[] memory amounts,
            bool[] memory withProxy,
            uint256 totalAmount
        )
    {
        WithdrawalQueue storage queue = getStorage().withdrawalQueues[
            vaultAddress
        ];

        uint256 index = queue.processedIndex;
        uint256 withdrawersLength = queue.withdrawers.length - index;

        withdrawers = new Withdrawer[](withdrawersLength);
        amounts = new uint256[](withdrawersLength);
        withProxy = new bool[](withdrawersLength);

        for (uint256 i = 0; i < withdrawersLength; i++) {
            Withdrawer memory withdrawer = queue.withdrawers[index + i];
            withdrawers[i] = withdrawer;
            address account = withdrawer.account;
            uint32 nextProductId = withdrawer.nextProductId;
            amounts[i] = queue.amounts[account][nextProductId];
            if (nextProductId == 0) {
                withProxy[i] = queue.withdrawingWithProxy[account];
            }
        }
        totalAmount = queue.queuedWithdrawalSharesAmount;
    }

    function isWithdrawalPossible(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.isWithdrawalPossible(cgs, vaultAddress);
    }

    /**
     * @notice Retrieves the strategy ID associated with a given product.
     * @param productId The ID of the product.
     * @return The strategy ID of the specified product.
     */
    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.strategyOfProduct[productId];
    }

    function getProductDepositAsset(
        uint32 productId
    ) external view returns (address) {
        CegaGlobalStorage storage cgs = getStorage();
        return ProductLogic.getProductDepositAsset(cgs, productId);
    }

    /**
     * @notice Gets the ID of the latest product created.
     * @return The ID of the latest product.
     */
    function getLatestProductId() external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.productIdCounter;
    }

    /**
     * @notice Fetches metadata for a specific product.
     * @param productId The ID of the product.
     * @return A `ProductMetadata` struct containing metadata of the product.
     */
    function getProductMetadata(
        uint32 productId
    ) external view returns (ProductMetadata memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.productMetadata[productId];
    }

    function getIsProtocolPaused() external view returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();

        return cgs.protocolPauseConfig == 1;
    }

    function getDepositQueue(
        uint32 productId
    )
        external
        view
        returns (
            address[] memory depositors,
            uint128[] memory amounts,
            uint128 totalAmount
        )
    {
        DepositQueue storage queue = getStorage().depositQueues[productId];
        uint256 index = queue.processedIndex;
        uint256 depositorsLength = queue.depositors.length - index;

        amounts = new uint128[](depositorsLength);
        depositors = new address[](depositorsLength);

        for (uint256 i = 0; i < depositorsLength; i++) {
            depositors[i] = queue.depositors[index + i];
            amounts[i] = queue.amounts[depositors[i]];
        }
        totalAmount = queue.queuedDepositsTotalAmount;
    }

    function getBondAllowList(address receiver) external view returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.bondAllowList[receiver];
    }

    function calculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategyId = cgs.strategyOfProduct[productId];
        if (strategyId == DCS_STRATEGY_ID) {
            return
                DCSLogic.calculateVaultFinalPayoff(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else if (strategyId == FCN_STRATEGY_ID) {
            return
                FCNVaultLogic.calculateVaultFinalPayoff(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else if (strategyId == SFN_STRATEGY_ID) {
            return
                SFNVaultLogic.calculateVaultFinalPayoff(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function getVaultSettlementAsset(
        address vaultAddress
    ) external view returns (address) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategyId = cgs.strategyOfProduct[productId];
        if (strategyId == DCS_STRATEGY_ID) {
            return DCSLogic.getVaultSettlementAsset(cgs, vaultAddress);
        } else if (strategyId == FCN_STRATEGY_ID) {
            return cgs.fcnProducts[productId].underlyingAsset;
        } else if (strategyId == SFN_STRATEGY_ID) {
            return cgs.sfnProducts[productId].underlyingAsset;
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function calculateLateFee(
        address vaultAddress
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategyId = cgs.strategyOfProduct[productId];
        if (strategyId == DCS_STRATEGY_ID) {
            return DCSVaultLogic.calculateLateFee(cgs, vaultAddress);
        } else if (strategyId == FCN_STRATEGY_ID) {
            return FCNVaultLogic.calculateLateFee(cgs, vaultAddress);
        } else if (strategyId == SFN_STRATEGY_ID) {
            return SFNVaultLogic.calculateLateFee(cgs, vaultAddress);
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function getCouponPayment(
        address vaultAddress
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategyId = cgs.strategyOfProduct[productId];
        if (strategyId == DCS_STRATEGY_ID) {
            uint40 endDate = cgs.vaults[vaultAddress].tradeStartDate +
                cgs.dcsProducts[productId].tenorInSeconds;
            return DCSVaultLogic.getCurrentYield(cgs, vaultAddress, endDate);
        } else if (strategyId == FCN_STRATEGY_ID) {
            return FCNVaultLogic.getVaultCouponPayment(cgs, vaultAddress);
        } else if (strategyId == SFN_STRATEGY_ID) {
            return SFNVaultLogic.getVaultCouponPayment(cgs, vaultAddress);
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function calculateVaultSettlementAmount(
        address vaultAddress
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;
        uint32 strategyId = cgs.strategyOfProduct[productId];
        if (strategyId == DCS_STRATEGY_ID) {
            require(
                cgs.vaults[vaultAddress].vaultStatus ==
                    VaultStatus.AwaitingSettlement,
                Errors.INVALID_VAULT_STATUS
            );
            return
                DCSLogic.calculateVaultFinalPayoff(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else if (strategyId == FCN_STRATEGY_ID) {
            return
                FCNVaultLogic.calculateVaultSettlementAmount(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else if (strategyId == SFN_STRATEGY_ID) {
            return
                SFNVaultLogic.calculateVaultSettlementAmount(
                    cgs,
                    addressManager,
                    vaultAddress
                );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }
}
