// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IPriceProvider } from "./interfaces/IPriceProvider.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol"; // bytes memory encodedData = abi.encodeWithSelector(

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { DepositReceiver } from "./DepositReceiver.sol";

contract Pricer is Auth {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for address;

    address public immutable baseAsset;
    address public immutable vaultToken;
    uint8 public immutable vaultTokenDecimals;
    uint8 public immutable baseAssetDecimals;
    uint8 public immutable decimals;
    address public depositReceiver;

    struct AssetConfig {
        IPriceProvider priceProvider;
        uint8 decimals;
        uint8 priceProviderDecimals;
    }

    struct PricerParams {
        address feeRecipient;
        uint96 highwaterMark;
        uint128 feesAccumulatedInBaseAsset;
        uint256 totalSharesLastUpdate;
        uint96 exchangeRate;
        uint16 allowedExchangeRateChangeUpper;
        uint16 allowedExchangeRateChangeLower;
        uint64 lastUpdateTimestamp;
        uint24 minimumUpdateDelayInSeconds;
        uint16 managementFee;
        uint16 performanceFee;
    }

    mapping(address => AssetConfig) public assetConfigs;
    PricerParams public pricerParams;

    error Pricer__PriceProviderNotSet(address _token);
    error Pricer__UpperBoundTooSmall();
    error Pricer__LowerBoundTooLarge();
    error Pricer__ManagementFeeTooLarge();
    error Pricer__PerformanceFeeTooLarge();
    error Pricer__ZeroAddress();
    error Pricer__ExchangeRateChecks();

    event MinimumUpdateDelayInSecondsUpdated(uint24 oldDelay, uint24 newDelay);
    event UpperBoundUpdated(uint16 oldBound, uint16 newBound);
    event LowerBoundUpdated(uint16 oldBound, uint16 newBound);
    event ManagementFeeUpdated(uint16 oldFee, uint16 newFee);
    event PerformanceFeeUpdated(uint16 oldFee, uint16 newFee);
    event FeeRecipientUpdated(address oldPayout, address newPayout);
    event ExchangeRateUpdated(uint256 oldExchangeRate, uint256 newExchangeRate, uint256 newFeesAccumulatedInBaseAsset);
    event DepositReceiverUpdated(address oldDepositReceiver, address newDepositReceiver);
    event FeesClaimed(address token, uint256 feesInToken, uint256 feesAccumulatedInBaseAsset);

    constructor(
        address _owner,
        address _baseAsset,
        address _vaultToken,
        address _feeRecipient,
        uint16 allowedExchangeRateChangeUpper,
        uint16 allowedExchangeRateChangeLower,
        uint24 minimumUpdateDelayInSeconds,
        uint16 managementFee,
        uint16 performanceFee
    )
        Auth(_owner, Authority(address(0)))
    {
        baseAsset = _baseAsset;
        vaultToken = _vaultToken;
        decimals = 8;
        vaultTokenDecimals = IERC20Metadata(vaultToken).decimals();
        baseAssetDecimals = IERC20Metadata(baseAsset).decimals();
        pricerParams = PricerParams({
            feeRecipient: _feeRecipient,
            highwaterMark: 1e8,
            feesAccumulatedInBaseAsset: 0,
            totalSharesLastUpdate: IERC20Metadata(vaultToken).totalSupply(),
            exchangeRate: 1e8,
            allowedExchangeRateChangeUpper: allowedExchangeRateChangeUpper,
            allowedExchangeRateChangeLower: allowedExchangeRateChangeLower,
            lastUpdateTimestamp: uint64(block.timestamp),
            minimumUpdateDelayInSeconds: minimumUpdateDelayInSeconds,
            managementFee: managementFee,
            performanceFee: performanceFee
        });
    }

    /**
     * @notice Gets the vault token amount for the given token and amount
     * @param _token The address of the token
     * @param _amount The amount of tokens
     * @return The amount of vault tokens
     */
    function getVaultTokenAmount(address _token, uint256 _amount) external view returns (uint256) {
        if (_token == baseAsset) {
            return _convertDecimals(
                _amount.mulDiv(10 ** decimals, pricerParams.exchangeRate), baseAssetDecimals, vaultTokenDecimals
            );
        }
        AssetConfig memory assetConfig = assetConfigs[_token];

        if (address(assetConfig.priceProvider) == address(0)) {
            revert Pricer__PriceProviderNotSet(_token);
        }
        return _convertDecimals(
            _amount * assetConfig.priceProvider.getPrice() / pricerParams.exchangeRate,
            assetConfig.decimals + assetConfig.priceProviderDecimals - decimals,
            vaultTokenDecimals
        );
    }

    /**
     * @notice Gets the asset amount for the given token and vault token amount
     * @param _token The address of the token
     * @param _vaultTokenAmount The amount of vault tokens
     * @return The amount of assets
     */
    function getAssetAmount(address _token, uint256 _vaultTokenAmount) external view returns (uint256) {
        if (_token == baseAsset) {
            return _convertDecimals(
                _vaultTokenAmount.mulDiv(pricerParams.exchangeRate, 10 ** decimals),
                vaultTokenDecimals,
                baseAssetDecimals
            );
        }
        AssetConfig memory assetConfig = assetConfigs[_token];
        if (address(assetConfig.priceProvider) == address(0)) {
            revert Pricer__PriceProviderNotSet(_token);
        }
        return _convertDecimals(
            _vaultTokenAmount.mulDiv(pricerParams.exchangeRate, assetConfig.priceProvider.getPrice()),
            vaultTokenDecimals + decimals - assetConfig.priceProviderDecimals,
            assetConfig.decimals
        );
    }

    /**
     * @notice Updates the exchange rate
     * @dev Only callable by addresses with UPDATE_EXCHANGE_RATE_ROLE
     * @param _newExchangeRate The new exchange rate
     */
    function updateExchangeRate(uint96 _newExchangeRate) external requiresAuth {
        (
            bool shouldRevert,
            PricerParams storage state,
            uint64 currentTime,
            uint256 currentExchangeRate,
            uint256 currentTotalShares
        ) = _exchangeRateChecks(_newExchangeRate);
        if (shouldRevert) revert Pricer__ExchangeRateChecks();
        uint256 newFeesAccumulatedInBaseAsset =
            _calculateFeesOwed(state, _newExchangeRate, currentTotalShares, currentTime);
        if (newFeesAccumulatedInBaseAsset > 0) {
            uint256 respectiveExchangeRate = _convertDecimals(
                newFeesAccumulatedInBaseAsset.mulDiv(10 ** vaultTokenDecimals, currentTotalShares),
                baseAssetDecimals,
                decimals
            );
            _newExchangeRate -= respectiveExchangeRate.toUint96();
        }
        pricerParams.exchangeRate = _newExchangeRate;
        pricerParams.lastUpdateTimestamp = currentTime;
        pricerParams.totalSharesLastUpdate = currentTotalShares;
        emit ExchangeRateUpdated(currentExchangeRate, _newExchangeRate, newFeesAccumulatedInBaseAsset);
    }

    /**
     * @notice Claims the fees accumulated in the base asset
     * @dev Only callable by addresses with FEE_CLAIMER_ROLE
     */
    function claimFees(address _token) external requiresAuth {
        uint256 feesAccumulatedInBaseAsset = pricerParams.feesAccumulatedInBaseAsset;
        pricerParams.feesAccumulatedInBaseAsset = 0;
        uint256 feesToSend = feesAccumulatedInBaseAsset;
        if (_token != baseAsset) {
            AssetConfig memory assetConfig = assetConfigs[_token];
            if (address(assetConfig.priceProvider) == address(0)) {
                revert Pricer__PriceProviderNotSet(_token);
            }
            feesToSend = _convertDecimals(
                feesAccumulatedInBaseAsset.mulDiv(
                    10 ** assetConfig.priceProviderDecimals, assetConfig.priceProvider.getPrice()
                ),
                baseAssetDecimals,
                assetConfig.decimals
            );
        }
        DepositReceiver(depositReceiver).sendFees(pricerParams.feeRecipient, _token, feesToSend);
        emit FeesClaimed(_token, feesToSend, feesAccumulatedInBaseAsset);
    }

    /**
     * @notice Sets the asset config
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _token The address of the token
     * @param _priceProvider The price provider
     */
    function setAssetConfig(address _token, IPriceProvider _priceProvider) external requiresAuth {
        assetConfigs[_token] = AssetConfig({
            priceProvider: _priceProvider,
            decimals: IERC20Metadata(_token).decimals(),
            priceProviderDecimals: _priceProvider.decimals()
        });
    }

    /**
     * @notice Updates the minimum update delay in seconds
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param minimumUpdateDelayInSeconds The minimum update delay in seconds
     */
    function updateDelay(uint24 minimumUpdateDelayInSeconds) external requiresAuth {
        uint24 oldDelay = pricerParams.minimumUpdateDelayInSeconds;
        pricerParams.minimumUpdateDelayInSeconds = minimumUpdateDelayInSeconds;
        emit MinimumUpdateDelayInSecondsUpdated(oldDelay, minimumUpdateDelayInSeconds);
    }

    /**
     * @notice Update the allowed upper bound change of exchange rate between `updateExchangeRateCalls`.
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param allowedExchangeRateChangeUpper The allowed exchange rate change upper
     */
    function updateUpper(uint16 allowedExchangeRateChangeUpper) external requiresAuth {
        if (allowedExchangeRateChangeUpper < 1e4) revert Pricer__UpperBoundTooSmall();
        uint16 oldBound = pricerParams.allowedExchangeRateChangeUpper;
        pricerParams.allowedExchangeRateChangeUpper = allowedExchangeRateChangeUpper;
        emit UpperBoundUpdated(oldBound, allowedExchangeRateChangeUpper);
    }

    /**
     * @notice Update the allowed lower bound change of exchange rate between `updateExchangeRateCalls`.
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param allowedExchangeRateChangeLower The allowed exchange rate change lower
     */
    function updateLower(uint16 allowedExchangeRateChangeLower) external requiresAuth {
        if (allowedExchangeRateChangeLower > 1e4) revert Pricer__LowerBoundTooLarge();
        uint16 oldBound = pricerParams.allowedExchangeRateChangeLower;
        pricerParams.allowedExchangeRateChangeLower = allowedExchangeRateChangeLower;
        emit LowerBoundUpdated(oldBound, allowedExchangeRateChangeLower);
    }

    /**
     * @notice Update the platform fee to a new value.
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param managementFee The management fee
     */
    function updateManagementFee(uint16 managementFee) external requiresAuth {
        if (managementFee > 0.2e4) revert Pricer__ManagementFeeTooLarge();
        uint16 oldFee = pricerParams.managementFee;
        pricerParams.managementFee = managementFee;
        emit ManagementFeeUpdated(oldFee, managementFee);
    }

    /**
     * @notice Update the performance fee to a new value.
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param performanceFee The performance fee
     */
    function updatePerformanceFee(uint16 performanceFee) external requiresAuth {
        if (performanceFee > 0.5e4) revert Pricer__PerformanceFeeTooLarge();
        uint16 oldFee = pricerParams.performanceFee;
        pricerParams.performanceFee = performanceFee;
        emit PerformanceFeeUpdated(oldFee, performanceFee);
    }

    /**
     * @notice Update the payout address fees are sent to.
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param feeRecipient The fee recipient
     */
    function updateFeeRecipient(address feeRecipient) external requiresAuth {
        if (feeRecipient == address(0)) revert Pricer__ZeroAddress();
        address oldFeeRecipient = pricerParams.feeRecipient;
        pricerParams.feeRecipient = feeRecipient;
        emit FeeRecipientUpdated(oldFeeRecipient, feeRecipient);
    }

    /**
     * @notice Update the deposit receiver
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _depositReceiver The deposit receiver
     */
    function updateDepositReceiver(address _depositReceiver) external requiresAuth {
        address oldDepositReceiver = depositReceiver;
        depositReceiver = _depositReceiver;
        emit DepositReceiverUpdated(oldDepositReceiver, _depositReceiver);
    }

    /*
     * @notice Get this Pricer's current rate in the base.
     * @return The current rate in the base asset
     */
    function getRate() public view returns (uint128 rate) {
        rate = pricerParams.exchangeRate;
    }

    /**
     * @notice Calculate platform fees.
     */
    function _calculateManagementFee(
        uint64 lastUpdateTimestamp,
        uint16 managementFee,
        uint96 currentExchangeRate,
        uint96 newExchangeRate,
        uint256 totalSharesSupply,
        uint256 totalSharesSupplyLastUpdate,
        uint64 currentTime
    )
        internal
        view
        returns (uint256 managementFeesAccumulatedInBaseAsset)
    {
        uint256 sharesToUse =
            totalSharesSupply < totalSharesSupplyLastUpdate ? totalSharesSupply : totalSharesSupplyLastUpdate;
        if (managementFee > 0) {
            uint256 timeDelta = currentTime - lastUpdateTimestamp;
            uint256 totalAssets = currentExchangeRate > newExchangeRate
                ? _convertDecimals(sharesToUse * newExchangeRate, vaultTokenDecimals + decimals, baseAssetDecimals)
                : _convertDecimals(sharesToUse * currentExchangeRate, vaultTokenDecimals + decimals, baseAssetDecimals);
            uint256 managementFeesAnnual = totalAssets.mulDiv(managementFee, 1e4);
            managementFeesAccumulatedInBaseAsset = managementFeesAnnual.mulDiv(timeDelta, 365 days);
        }
    }
    /**
     * @notice Calculate performance fees.
     */

    function _calculatePerformanceFee(
        uint96 newExchangeRate,
        uint256 shareTotalSupply,
        uint96 oldExchangeRate,
        uint16 performanceFee
    )
        internal
        view
        returns (uint256 performanceFeesAccumulatedInBaseAsset, uint256 yieldEarned)
    {
        uint256 changeInExchangeRate = newExchangeRate - oldExchangeRate;
        yieldEarned = _convertDecimals(
            changeInExchangeRate.mulDiv(shareTotalSupply, 10 ** vaultTokenDecimals), decimals, baseAssetDecimals
        );
        if (performanceFee > 0) {
            performanceFeesAccumulatedInBaseAsset = yieldEarned.mulDiv(performanceFee, 1e4);
        }
    }

    /**
     * @notice Check if the new exchange rate is outside of the allowed bounds or if not enough time has passed.
     */
    function _exchangeRateChecks(uint96 newExchangeRate)
        internal
        view
        returns (
            bool shouldRevert,
            PricerParams storage state,
            uint64 currentTime,
            uint256 currentExchangeRate,
            uint256 currentTotalShares
        )
    {
        state = pricerParams;
        currentTime = block.timestamp.toUint64();
        currentExchangeRate = state.exchangeRate;
        currentTotalShares = IERC20Metadata(vaultToken).totalSupply();

        shouldRevert = currentTime < state.lastUpdateTimestamp + state.minimumUpdateDelayInSeconds
            || newExchangeRate > currentExchangeRate.mulDiv(state.allowedExchangeRateChangeUpper, 1e4)
            || newExchangeRate < currentExchangeRate.mulDiv(state.allowedExchangeRateChangeLower, 1e4);
    }

    function _calculateFeesOwed(
        PricerParams storage state,
        uint96 newExchangeRate,
        uint256 currentTotalShares,
        uint64 currentTime
    )
        internal
        virtual
        returns (uint256 newFeesAccumulatedInBaseAsset)
    {
        // Update fee accounting.
        newFeesAccumulatedInBaseAsset = _calculateManagementFee(
            state.lastUpdateTimestamp,
            state.managementFee,
            state.exchangeRate,
            newExchangeRate,
            currentTotalShares,
            state.totalSharesLastUpdate,
            currentTime
        );

        // Account for performance fees.
        if (newExchangeRate > state.highwaterMark) {
            (uint256 performanceFeesAccumulatedInBaseAsset,) =
                _calculatePerformanceFee(newExchangeRate, currentTotalShares, state.highwaterMark, state.performanceFee);

            // Add performance fees to fees owed.
            newFeesAccumulatedInBaseAsset += performanceFeesAccumulatedInBaseAsset;

            state.highwaterMark = newExchangeRate;
        }

        state.feesAccumulatedInBaseAsset += newFeesAccumulatedInBaseAsset.toUint128();
    }

    /**
     * @notice Convert the decimals of the amount.
     * @param _amount The amount to change the decimals of.
     * @param _fromDecimals The decimals of the amount.
     * @param _toDecimals The decimals to change the amount to.
     * @return The amount with the new decimals.
     */
    function _convertDecimals(
        uint256 _amount,
        uint8 _fromDecimals,
        uint8 _toDecimals
    )
        internal
        pure
        returns (uint256)
    {
        if (_fromDecimals == _toDecimals) {
            return _amount;
        }
        unchecked {
            return _fromDecimals > _toDecimals
                ? _amount / 10 ** (_fromDecimals - _toDecimals)
                : _amount * 10 ** (_toDecimals - _fromDecimals);
        }
    }
}
