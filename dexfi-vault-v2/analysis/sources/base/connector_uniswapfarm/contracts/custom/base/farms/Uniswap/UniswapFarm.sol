// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Swap} from "../../../utils/Uniswap/libraries/custom/Swap.sol";
import {Oracle} from "../../../utils/Uniswap/libraries/custom/Oracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Helpers} from "../../../utils/Uniswap/libraries/custom/Helpers.sol";
import {TickMath} from "../../../utils/Uniswap/libraries/TickMath.sol";
import {DexFiFarm} from "../../../../core/abstracts/DexFiFarm.sol";
import {Constants} from "../../../utils/Uniswap/libraries/Constants.sol";
import {IUniswapV3Pool} from "../../../utils/Uniswap/interfaces/IUniswapV3Pool.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {PriceManagement} from "../../../utils/Uniswap/libraries/custom/PriceManagement.sol";
import {LiquidityAmounts} from "../../../utils/Uniswap/libraries/LiquidityAmounts.sol";
import {IUniswapV3Factory} from "../../../utils/Uniswap/interfaces/IUniswapV3Factory.sol";
import {RewardsManagement} from "../../../utils/Uniswap/libraries/custom/RewardsManagement.sol";
import {LiquidityManagement} from "../../../utils/Uniswap/libraries/custom/LiquidityManagement.sol";
import {SafeERC20, IERC20, Address} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexFiUniversalRouterBytes} from "../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {INonfungiblePositionManager} from "../../../utils/Uniswap/interfaces/INonfungiblePositionManager.sol";
import {IDexFiVault, IDexFiVaultFactory} from "../../../../core/interfaces/IDexFiVault.sol";

contract UniswapFarm is DexFiFarm, IERC721Receiver {
    using PriceManagement for PriceManagement.PriceRangesData;
    using LiquidityManagement for INonfungiblePositionManager;
    using LiquidityAmounts for uint160;
    using Swap for Swap.SwapPair[];
    using SafeERC20 for IERC20;

    struct StakingTokenData {
        string stakingTokenType;
        IUniswapV3Pool pool;
        address token0;
        address token1;
        uint24 fee;
    }

    struct StakingTokenInitData {
        string stakingTokenType;
        uint24 fee;
        uint256 approxToRangeLimitLowPercent;
        uint256 approxToRangeLimitUpPercent;
        uint256 defaultDeviationPercentLow;
        uint256 defaultDeviationPercentUp;
        uint256 minSwapAmountNative;
        uint256 minSwapAmountToken0;
        uint256 minSwapAmountToken1;
        Swap.SwapPair[] swapsToken0ToNative;
        Swap.SwapPair[] swapsToken1ToNative;
        Swap.SwapPair[] swapsToken0ToToken1;
    }

    struct ReinitializationData {
        address oldStorageCleaner;
        address universalRouter;
        address nonfungiblePositionManager;
        StakingTokenInitData stakingToken;
        Oracle.OracleData oracleData;
    }

    uint256 public tokenId;
    IDexFiUniversalRouterBytes public universalRouter;

    IERC20 private _native;
    INonfungiblePositionManager private _stakingToken;
    StakingTokenData private _stakingTokenData;
    PriceManagement.PriceRangesData private _priceRangesData;
    Oracle.OracleData private _oracleData;
    Swap.SwapData private _swapData;
    RewardsManagement.HarvestDebt private _harvestDebt;

    function native() external view override returns (address) {
        return address(_native);
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function stakingTokenData() external view returns (StakingTokenData memory) {
        return _stakingTokenData;
    }

    function priceRangesData() external view returns (PriceManagement.PriceRangesData memory) {
        return _priceRangesData;
    }

    function swapData() external view returns (Swap.SwapData memory) {
        return _swapData;
    }

    function rewardTokens(uint256) external view override returns (address token_) {}

    function rewardTokensCount() external pure override returns (uint256 count_) {}

    function harvestDebt() external view returns (RewardsManagement.HarvestDebt memory) {
        return _harvestDebt;
    }

    function oracleData() external view returns (Oracle.OracleData memory) {
        return _oracleData;
    }

    function farm() external view override returns (address farm_) {}

    function stakingTokenType() external view override returns (string memory) {
        return _stakingTokenData.stakingTokenType;
    }

    function rewardTokenType(address) external view override returns (string memory type_) {}

    function stakingTokenApproveData(address to, uint256 tokenId_) external view override returns (bytes memory data) {
        data = abi.encodeWithSelector(_stakingToken.approve.selector, to, tokenId_);
    }

    function stakingTokenTransferFromData(
        address from,
        address to,
        uint256 tokenId_
    ) external view override returns (bytes memory data) {
        data = abi.encodeWithSelector(_stakingToken.transferFrom.selector, from, to, tokenId_);
    }

    function timeUnit() external pure override returns (TimeUnit) {
        return TimeUnit.SECOND;
    }

    function sharePerTimeUnit(address) external view override returns (uint256 share_) {}

    function pendingRewards(address, address) external view override returns (uint256 rewards_) {}

    function decodeAndValidateReinitialize(bytes memory params) external pure override returns (bool) {
        _decodeAndValidateReinitialize(params);
        return true;
    }

    function dexVersion() external pure override returns (uint256) {
        return 4;
    }

    function stakingTokenLiquidity(uint256 inputTokenId) external override returns (uint256 liquidity_) {
        if (tokenId > 0 && inputTokenId > 0) {
            if (inputTokenId == tokenId) {
                (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(inputTokenId);
            } else {
                Swap.SwapData storage swapData_ = _swapData;
                liquidity_ = PriceManagement.calculateNewLiquidityFromOldPosition(
                    universalRouter,
                    _stakingToken,
                    inputTokenId,
                    tokenId,
                    swapData_.swapsToken0ToNative,
                    swapData_.swapsToken1ToNative
                );
            }
        }
    }

    function liquidity(address) public view override returns (uint256 liquidity_) {
        if (tokenId > 0) (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(tokenId);
    }

    function _getAmountOutStakingTokenToNative(uint256 amountIn) internal override returns (uint256 nativeAmount) {
        (uint160 sqrtPriceX96, , , , , , ) = _stakingTokenData.pool.slot0();
        (uint256 amount0, uint256 amount1) = sqrtPriceX96.getAmountsForLiquidity(
            uint160(_priceRangesData.sqrtPriceX96Low),
            uint160(_priceRangesData.sqrtPriceX96Up),
            uint128(amountIn)
        );
        Swap.SwapData storage swapData_ = _swapData;
        nativeAmount += swapData_.swapsToken0ToNative.getAmountOut(universalRouter, amount0);
        nativeAmount += swapData_.swapsToken1ToNative.getAmountOut(universalRouter, amount1);
    }

    function _getAmountOutRewardTokenToNative(address, uint256) internal override returns (uint256 nativeAmount) {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    event PriceRangesShiftPercentUpdated(uint256 low, uint256 up, uint256 approxLow, uint256 approxUp);

    error DecodeReinitializeDataUniversalRouterZero();
    error DecodeReinitializeDataNonfungiblePositionManagerZero();
    error DepositConvertlessPoolIsInvalid();
    error ReinitializeOracleZero();
    error ReinitializePoolZero();
    error UpdatePriceRangesShiftPercentCallerNotAuthorized(address caller);
    error UpdatePriceRangesShiftPercentMinNativeBalanceVaultLtMin(
        uint256 nativeBalanceVault,
        uint256 minNativeBalanceVault
    );
    error UpdatePriceRangesShiftPercentAmount0LtMin(uint256 amount0, uint256 minAmount0);
    error UpdatePriceRangesShiftPercentAmount1LtMin(uint256 amount1, uint256 minAmount1);
    error DecodeReinitializeDataFarmZero();

    function updatePriceRangesShiftPercent(
        uint256 lowPercent,
        uint256 upPercent,
        uint256 approxToRangeLowPercent,
        uint256 approxToRangeUpPercent,
        uint256 minNativeBalanceVault,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 nativeBalanceVault, uint256 amount0, uint256 amount1) {
        address vault_ = vault;
        if (
            msg.sender != Ownable(vault_).owner() &&
            msg.sender != IDexFiVaultFactory(IDexFiVault(vault_).factory()).integrationConfig().harvester
        ) revert UpdatePriceRangesShiftPercentCallerNotAuthorized(msg.sender);
        bool forcedReassembly;
        PriceManagement.PriceRangesData storage priceRangesData_ = _priceRangesData;
        if (
            priceRangesData_.deviationPercentLow != lowPercent ||
            priceRangesData_.deviationPercentUp != upPercent ||
            priceRangesData_.approxToRangeLimitLowPercent != approxToRangeLowPercent ||
            priceRangesData_.approxToRangeLimitUpPercent != approxToRangeUpPercent
        ) {
            PriceManagement.validateDeviationPercent(lowPercent, upPercent);
            PriceManagement.validateApproxToRangeLimitPercent(approxToRangeLowPercent, approxToRangeUpPercent);
            forcedReassembly = true;
            priceRangesData_.deviationPercentLow = lowPercent;
            priceRangesData_.deviationPercentUp = upPercent;
            priceRangesData_.approxToRangeLimitLowPercent = approxToRangeLowPercent;
            priceRangesData_.approxToRangeLimitUpPercent = approxToRangeUpPercent;
        }
        uint256 liquidity_ = liquidity(address(0));
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        (uint160 sqrtPriceX96, , , , , , ) = stakingTokenData_.pool.slot0();
        if (tokenId > 0) {
            uint256 nativeBalanceVaultBefore = _native.balanceOf(vault_);
            RewardsManagement.processRewards(
                _harvestDebt,
                universalRouter,
                _stakingToken,
                tokenId,
                vault_,
                false,
                _swapData
            );
            if (
                (sqrtPriceX96 <= priceRangesData_.sqrtPriceX96LowLimit ||
                    sqrtPriceX96 >= priceRangesData_.sqrtPriceX96UpLimit ||
                    forcedReassembly) && liquidity_ > 0
            ) {
                (uint256 amountOut0, uint256 amountOut1) = _stakingToken.decreaseLiquidity(
                    tokenId,
                    address(this),
                    liquidity_,
                    true
                );
                priceRangesData_.updatePriceRanges(stakingTokenData_.pool);
                _updateLiquidity(0, amountOut0, amountOut1, false, address(0));
            }
            liquidity_ = liquidity(address(0));
            nativeBalanceVault = _native.balanceOf(vault_) - nativeBalanceVaultBefore;
            (sqrtPriceX96, , , , , , ) = stakingTokenData_.pool.slot0();
            (amount0, amount1) = sqrtPriceX96.getAmountsForLiquidity(
                uint160(priceRangesData_.sqrtPriceX96Low),
                uint160(priceRangesData_.sqrtPriceX96Up),
                uint128(liquidity_)
            );
            if (nativeBalanceVault < minNativeBalanceVault)
                revert UpdatePriceRangesShiftPercentMinNativeBalanceVaultLtMin(
                    nativeBalanceVault,
                    minNativeBalanceVault
                );
            if (amount0 < minAmount0) revert UpdatePriceRangesShiftPercentAmount0LtMin(amount0, minAmount0);
            if (amount1 < minAmount1) revert UpdatePriceRangesShiftPercentAmount1LtMin(amount1, minAmount1);
            PriceManagement.validateSqrtPriceX96(
                priceRangesData_.sqrtPriceX96LowLimit,
                priceRangesData_.sqrtPriceX96UpLimit,
                sqrtPriceX96
            );
            emit PriceRangesShiftPercentUpdated(lowPercent, upPercent, approxToRangeLowPercent, approxToRangeUpPercent);
        }
    }

    function _reinitialize(bytes memory params) internal override {
        ReinitializationData memory data = _decodeAndValidateReinitialize(params);
        if (data.oldStorageCleaner != address(0))
            Address.functionDelegateCall(data.oldStorageCleaner, abi.encodeWithSelector(bytes4(keccak256("clear()"))));
        address native_ = address(IDexFiVault(vault).native());
        _native = IERC20(native_);
        StakingTokenInitData memory stakingTokenInitData = data.stakingToken;
        if (address(data.oracleData.oracle) == address(0)) revert ReinitializeOracleZero();
        Oracle.validateDeviations(data.oracleData.acceptableDeviationPool, data.oracleData.acceptableDeviationSwap);
        data.oracleData.lastValidatePriceTimestamp = 0;
        _oracleData = data.oracleData;
        address token0 = stakingTokenInitData.swapsToken0ToNative[0].tokenIn;
        address token1 = stakingTokenInitData.swapsToken1ToNative[0].tokenIn;
        stakingTokenInitData.swapsToken0ToNative.validateSwapPath(token0, native_);
        stakingTokenInitData.swapsToken1ToNative.validateSwapPath(token1, native_);
        stakingTokenInitData.swapsToken0ToToken1.validateSwapPath(token0, token1);
        universalRouter = IDexFiUniversalRouterBytes(data.universalRouter);
        _stakingToken = INonfungiblePositionManager(data.nonfungiblePositionManager);
        PriceManagement.validateDeviationPercent(
            stakingTokenInitData.defaultDeviationPercentLow,
            stakingTokenInitData.defaultDeviationPercentUp
        );
        PriceManagement.validateApproxToRangeLimitPercent(
            stakingTokenInitData.approxToRangeLimitLowPercent,
            stakingTokenInitData.approxToRangeLimitUpPercent
        );
        address pool_ = IUniswapV3Factory(_stakingToken.factory()).getPool(token0, token1, stakingTokenInitData.fee);
        if (pool_ == address(0)) revert ReinitializePoolZero();
        PriceManagement.PriceRangesData storage priceRangesData_ = _priceRangesData;
        priceRangesData_.approxToRangeLimitLowPercent = stakingTokenInitData.approxToRangeLimitLowPercent;
        priceRangesData_.approxToRangeLimitUpPercent = stakingTokenInitData.approxToRangeLimitUpPercent;
        priceRangesData_.deviationPercentLow = priceRangesData_.deviationPercentLow;
        priceRangesData_.deviationPercentUp = priceRangesData_.deviationPercentUp;
        priceRangesData_.defaultDeviationPercentLow = stakingTokenInitData.defaultDeviationPercentLow;
        priceRangesData_.defaultDeviationPercentUp = stakingTokenInitData.defaultDeviationPercentUp;
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        stakingTokenData_.stakingTokenType = stakingTokenInitData.stakingTokenType;
        stakingTokenData_.pool = IUniswapV3Pool(pool_);
        stakingTokenData_.token0 = token0;
        stakingTokenData_.token1 = token1;
        stakingTokenData_.fee = data.stakingToken.fee;
        Swap.SwapData storage swapData_ = _swapData;
        swapData_.minSwapAmountNative = stakingTokenInitData.minSwapAmountNative;
        swapData_.minSwapAmountToken0 = stakingTokenInitData.minSwapAmountToken0;
        swapData_.minSwapAmountToken1 = stakingTokenInitData.minSwapAmountToken1;
        swapData_.swapsToken0ToNative = stakingTokenInitData.swapsToken0ToNative;
        swapData_.swapsToken1ToNative = stakingTokenInitData.swapsToken1ToNative;
        swapData_.swapsToken0ToToken1 = stakingTokenInitData.swapsToken0ToToken1;
        swapData_.swapsNativeToToken0 = stakingTokenInitData.swapsToken0ToNative.reverseSwapPath();
        swapData_.swapsNativeToToken1 = stakingTokenInitData.swapsToken1ToNative.reverseSwapPath();
        swapData_.swapsToken1ToToken0 = stakingTokenInitData.swapsToken0ToToken1.reverseSwapPath();
    }

    function _deposit(uint256 nativeAmount) internal override returns (uint256 stakingAmount) {
        _native.safeTransferFrom(vault, address(this), nativeAmount);
        uint256 liquidity_;
        if (tokenId > 0) (, , , , , , , liquidity_, , , , ) = _stakingToken.positions(tokenId);
        if (liquidity_ == 0) {
            _priceRangesData.updatePriceRanges(_stakingTokenData.pool);
            stakingAmount = _updateLiquidity(nativeAmount, 0, 0, false, address(0));
        } else {
            stakingAmount = _updateLiquidity(nativeAmount, 0, 0, true, address(0));
        }
    }

    function _depositConvertless(
        uint256 tokenIdConvertless,
        uint256 depositLiquidityAmount,
        uint256 feeLiquidityAmount,
        address feeRecipient,
        address residualRecipient
    ) internal override {
        uint256 precision = Constants.PRECISION;
        INonfungiblePositionManager stakingToken_ = _stakingToken;
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        Swap.SwapData storage swapData_ = _swapData;
        (, , address token0, address token1, , , , uint256 liquidity_, , , , ) = _stakingToken.positions(
            tokenIdConvertless
        );
        if (token0 != stakingTokenData_.token0 || token1 != stakingTokenData_.token1)
            revert DepositConvertlessPoolIsInvalid();
        stakingToken_.safeTransferFrom(vault, address(this), tokenIdConvertless);
        uint256 calculatedLiquidity = PriceManagement.calculateNewLiquidityFromOldPosition(
            universalRouter,
            stakingToken_,
            tokenIdConvertless,
            tokenId,
            swapData_.swapsToken0ToNative,
            swapData_.swapsToken1ToNative
        );
        (uint256 amountOut0, uint256 amountOut1) = _stakingToken.decreaseLiquidity(
            tokenIdConvertless,
            address(this),
            liquidity_,
            true
        );
        uint256 totalLiquidity = depositLiquidityAmount + feeLiquidityAmount;
        uint256 addedRate = (totalLiquidity * precision) / calculatedLiquidity;
        uint256 addedAmount0 = (amountOut0 * addedRate) / precision;
        uint256 addedAmount1 = (amountOut1 * addedRate) / precision;
        uint256 refundAmount0 = amountOut0 - addedAmount0;
        uint256 refundAmount1 = amountOut1 - addedAmount1;
        if (refundAmount0 > 0) IERC20(stakingTokenData_.token0).safeTransfer(residualRecipient, refundAmount0);
        if (refundAmount1 > 0) IERC20(stakingTokenData_.token1).safeTransfer(residualRecipient, refundAmount1);
        uint256 feeRate = (feeLiquidityAmount * precision) / totalLiquidity;
        uint256 feeAmount0 = (addedAmount0 * feeRate) / precision;
        uint256 feeAmount1 = (addedAmount1 * feeRate) / precision;
        if (feeRate > 0) {
            swapData_.swapsToken0ToNative.swap(
                universalRouter,
                feeAmount0,
                feeRecipient,
                swapData_.minSwapAmountToken0
            );
            swapData_.swapsToken1ToNative.swap(
                universalRouter,
                feeAmount1,
                feeRecipient,
                swapData_.minSwapAmountToken1
            );
        }
        _updateLiquidity(0, addedAmount0 - feeAmount0, addedAmount1 - feeAmount1, true, residualRecipient);
    }

    function _harvest() internal override returns (uint256 nativeAmount) {
        if (tokenId > 0) {
            nativeAmount = RewardsManagement.processRewards(
                _harvestDebt,
                universalRouter,
                _stakingToken,
                tokenId,
                vault,
                true,
                _swapData
            );
        }
    }

    function _withdraw(uint256 stakingAmount) internal override returns (uint256 nativeAmount) {
        if (tokenId > 0) {
            address vault_ = vault;
            uint256 balanceBefore = _native.balanceOf(vault_);
            (uint256 amountOut0, uint256 amountOut1) = _stakingToken.decreaseLiquidity(
                tokenId,
                address(this),
                stakingAmount,
                false
            );
            _swapPairTokensToNative(amountOut0, amountOut1, vault);
            nativeAmount = (_native.balanceOf(vault_) - balanceBefore);
        }
    }

    function _withdrawConvertless(uint256 stakingAmount, address recipient) internal override {
        if (tokenId > 0) _stakingToken.decreaseLiquidity(tokenId, recipient, stakingAmount, false);
    }

    function _emergencyWithdraw(uint256 stakingAmount, address recipient) internal override {
        _withdrawConvertless(stakingAmount, recipient);
    }

    function _decodeAndValidateReinitialize(
        bytes memory params
    ) private pure returns (ReinitializationData memory data) {
        data = abi.decode(params, (ReinitializationData));
        if (data.universalRouter == address(0)) revert DecodeReinitializeDataUniversalRouterZero();
        if (data.nonfungiblePositionManager == address(0))
            revert DecodeReinitializeDataNonfungiblePositionManagerZero();
    }

    function _updateLiquidity(
        uint256 inputNativeAmount,
        uint256 inputAmount0,
        uint256 inputAmount1,
        bool increase,
        address residualRecipient
    ) private returns (uint256 liquidity_) {
        StakingTokenData storage stakingTokenData_ = _stakingTokenData;
        PriceManagement.PriceRangesData storage priceRangesData_ = _priceRangesData;
        address token0 = stakingTokenData_.token0;
        address token1 = stakingTokenData_.token1;
        (uint256 amount0, uint256 amount1) = Helpers.calculateAndSwapByRatesPosition(
            universalRouter,
            stakingTokenData_.pool,
            inputNativeAmount,
            inputAmount0,
            inputAmount1,
            _swapData,
            _oracleData,
            priceRangesData_
        );
        if (increase) {
            uint256 amount0Real;
            uint256 amount1Real;
            (liquidity_, amount0Real, amount1Real) = _stakingToken.increaseLiquidity(
                priceRangesData_,
                stakingTokenData_.pool,
                tokenId,
                token0,
                token1,
                amount0,
                amount1
            );
            if (residualRecipient != address(0)) {
                amount0Real = amount0 - amount0Real;
                amount1Real = amount1 - amount1Real;
                if (amount0Real > 0) IERC20(token0).safeTransfer(residualRecipient, amount0Real);
                if (amount1Real > 0) IERC20(token1).safeTransfer(residualRecipient, amount1Real);
            }
        } else {
            (tokenId, liquidity_) = _stakingToken.addLiquidity(
                priceRangesData_,
                stakingTokenData_.pool,
                token0,
                token1,
                stakingTokenData_.fee,
                priceRangesData_.tickLower,
                priceRangesData_.tickUpper,
                amount0,
                amount1
            );
        }
        _swapPairTokensToNative(
            IERC20(token0).balanceOf(address(this)) - _harvestDebt.debt0,
            IERC20(token1).balanceOf(address(this)) - _harvestDebt.debt1,
            vault
        );
        IERC20 native_ = _native;
        uint256 balanceNativeThis = native_.balanceOf(address(this));
        if (address(native_) != token0 && address(native_) != token1 && balanceNativeThis > 0)
            native_.safeTransfer(vault, balanceNativeThis);
    }

    function _swapPairTokensToNative(uint256 amount0, uint256 amount1, address recipient) private {
        Swap.SwapData storage swapData_ = _swapData;
        IDexFiUniversalRouterBytes universalRouter_ = universalRouter;
        swapData_.swapsToken0ToNative.swap(universalRouter_, amount0, recipient, swapData_.minSwapAmountToken0);
        swapData_.swapsToken1ToNative.swap(universalRouter_, amount1, recipient, swapData_.minSwapAmountToken1);
    }
}
