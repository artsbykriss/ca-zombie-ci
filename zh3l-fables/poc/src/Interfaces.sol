// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

interface IPoolManager {
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
    function extsload(bytes32 slot) external view returns (bytes32);
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function getLiquidity(bytes32 id) external view returns (uint128);
    function unlock(bytes calldata data) external returns (bytes memory);
    function donate(PoolKey calldata key, uint256 amount0, uint256 amount1, bytes calldata data) external;
    function sync(address currency) external;
    function settle() external payable returns (uint256);
    function take(address currency, address to, uint256 amount) external;
}

interface IFablesLedger {
    function sweepClaimFee(address currency) external;
    function sweepDistributor(address currency) external;
    function claimFeeOwed(address currency) external view returns (uint256);
    function distributorOwed(address currency) external view returns (uint256);
    function distributor() external view returns (address);
    function claimFeeRecipient() external view returns (address);
    function ffFeeSink() external view returns (address);
    function ballotGate() external view returns (address);
    function pausedUntil() external view returns (uint256);
    function paused() external view returns (bool);
    function pausedFor(bytes32 poolId) external view returns (bool);
    function authority() external view returns (address);
    function ABSOLUTE_MAX_FEE() external view returns (uint24);
    function poolManager() external view returns (address);
    function maxFee(bytes32 poolId) external view returns (uint24);
    function pokeFee(bytes32 poolId, uint24 fee0For1, uint24 fee1For0, uint40 ttl) external;
    function clearPoke(bytes32 poolId) external;
    function setPaused(uint256 duration) external;
    function pause(uint256 duration) external;
    function setPoolPaused(PoolKey calldata key, uint256 duration) external;
    function pausePool(PoolKey calldata key, uint256 duration) external;
    function setBallotGate(address gate) external;
    function setDistributor(address[] calldata settleFirst, address distributor_) external;
    function setClaimFee(PoolKey calldata key, address[] calldata settleFirst, uint16 bps, address recipient) external;
    function deposit(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint128 amount0Max,
        uint128 amount1Max,
        uint256 deadline
    ) external payable;
    function withdraw(
        PoolKey calldata key,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        uint128 amount0Min,
        uint128 amount1Min,
        uint256 deadline
    ) external;
    function claimFees(PoolKey calldata key, int24 tickLower, int24 tickUpper, address to, uint16 maxFeeBps)
        external;
    function stake(PoolKey calldata key, int24 tickLower, int24 tickUpper, uint128 shares, uint256 minGaugeWeight)
        external;
    function unstake(PoolKey calldata key, int24 tickLower, int24 tickUpper, uint128 shares) external;
    function syncRanges(uint256 tokenId, uint256[] calldata ids) external;
    function rangeState(uint256 id) external view returns (
        uint128 totalShares,
        uint128 totalStaked,
        uint256 accFee0X128,
        uint256 accFee1X128,
        uint256 accStaked0X128,
        uint256 accStaked1X128,
        uint128 stakedResidual0,
        uint128 stakedResidual1,
        uint64 collectionSeq,
        uint64 resetSeq
    );
}

interface IAccessManager {
    function canCall(address caller, address target, bytes4 selector) external view returns (bool, uint32);
    function hasRole(uint64 roleId, address account) external view returns (bool, uint32);
    function getTargetFunctionRole(address target, bytes4 selector) external view returns (uint64);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IERC6909 {
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);
}

interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}
