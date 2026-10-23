// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Minimal interfaces for the BulbaSwap V3 (Uniswap V3 fork, Morph L2) recon PoC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IUniswapV3Factory {
    function owner() external view returns (address);
    function feeAmountTickSpacing(uint24) external view returns (int24);
    function getPool(address, address, uint24) external view returns (address);
    function createPool(address, address, uint24) external returns (address);
    function setOwner(address) external;
    function enableFeeAmount(uint24, int24) external;
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function positions(bytes32)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external
        returns (uint128, uint128);
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128, uint128);
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint128, uint128);
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        returns (uint256, uint256);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256, int256);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function skim(address recipient) external;
    function increaseObservationCardinalityNext(uint16) external;
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory, uint160[] memory);
    function snapshotCumulativesInside(int24, int24) external view returns (int56, uint160, uint32);
    function maxLiquidityPerTick() external view returns (uint128);
}

interface INonfungiblePositionManager {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function factory() external view returns (address);
    function WETH9() external view returns (address);
    function positions(uint256)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external payable returns (uint256 amount0, uint256 amount1);
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
    function refundETH() external payable;

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    // note: v1.0.0 periphery collect() has NO deadline; decreaseLiquidity() DOES.
    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
}
