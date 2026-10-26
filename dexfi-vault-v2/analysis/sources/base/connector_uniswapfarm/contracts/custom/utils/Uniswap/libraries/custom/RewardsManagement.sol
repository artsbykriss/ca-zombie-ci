// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Swap} from "./Swap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexFiUniversalRouterBytes} from "../../../../common/interfaces/IDexFiUniversalRouterBytes.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";

library RewardsManagement {
    using Swap for Swap.SwapPair[];

    struct HarvestDebt {
        uint256 debt0;
        uint256 debt1;
    }

    function processRewards(
        HarvestDebt storage self,
        IDexFiUniversalRouterBytes universalRouter,
        INonfungiblePositionManager positionManager,
        uint256 positionId,
        address recipient,
        bool transferAllowed,
        Swap.SwapData storage swapData
    ) external returns (uint256 nativeAmount) {
        if (positionId > 0) {
            (uint256 reward0, uint256 reward1) = positionManager.collect(
                INonfungiblePositionManager.CollectParams(
                    positionId,
                    address(this),
                    type(uint128).max,
                    type(uint128).max
                )
            );
            self.debt0 += reward0;
            self.debt1 += reward1;
            uint256 balanceToken0 = IERC20(swapData.swapsToken0ToNative[0].tokenIn).balanceOf(address(this));
            uint256 balanceToken1 = IERC20(swapData.swapsToken1ToNative[0].tokenIn).balanceOf(address(this));
            if (self.debt0 > balanceToken0) self.debt0 = balanceToken0;
            if (self.debt1 > balanceToken1) self.debt1 = balanceToken1;
            if (transferAllowed) {
                if (self.debt0 >= swapData.minSwapAmountToken0) {
                    nativeAmount += swapData.swapsToken0ToNative.swap(
                        universalRouter,
                        self.debt0,
                        recipient,
                        swapData.minSwapAmountToken0
                    );
                    self.debt0 = 0;
                }
                if (self.debt1 >= swapData.minSwapAmountToken1) {
                    nativeAmount += swapData.swapsToken1ToNative.swap(
                        universalRouter,
                        self.debt1,
                        recipient,
                        swapData.minSwapAmountToken1
                    );
                    self.debt1 = 0;
                }
            }
        }
    }
}
