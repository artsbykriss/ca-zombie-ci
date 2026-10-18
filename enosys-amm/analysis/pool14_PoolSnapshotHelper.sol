// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

/**
 * Copyright (C) 2024 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IHistoryStateTrackerByEpoch.sol';
import '../interfaces/INonfungiblePositionManager.sol';
import '../interfaces/pool/IEnosysDexV3PoolState.sol';
import './Position.sol';
import './FullMath.sol';

library PoolSnapshotHelper {
    using SafeMath for uint256;
    using FullMath for uint256;
    using SafeMath for uint128;

    enum SnapshotType {
        TotalSwapFees0,
        TotalSwapFees1,
        FeeGrowthGlobal0X128,
        FeeGrowthGlobal1X128,
        TickFeeGrowthOutside0X128ForEpoch,
        TickFeeGrowthOutside1X128ForEpoch,
        PositionFeeGrowthInside0LastX128,
        PositionFeeGrowthInside1LastX128,
        PositionLiquidity,
        TickForEpoch,
        Liquidity,
        PositionTotalSwapFees0,
        PositionTotalSwapFees1
    }

    /**
     * @dev Incerement pool's swap fees after each swap.
     * Should be called from pool and as value pass `State.feeAmount` based on `zeroForOne` value.
     * @param historyStateTrackerByEpoch Address of HistoryStateTrackerByEpoch contract
     * @param pool Address of pool for which fees should be incremented
     * @param feesFromSwap0 Fees from swap for token0, value of `State.feeAmount` if `zeroForOne` is true
     * @param feesFromSwap1 Fees from swap for token1, value of `State.feeAmount` if `zeroForOne` is false
     */
    function snapshotPoolFees(
        address historyStateTrackerByEpoch,
        address pool,
        uint256 feesFromSwap0,
        uint256 feesFromSwap1
    ) public {
        IHistoryStateTrackerByEpoch historyStateTracker = IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch);

        uint256 feesFromSwap0Before = historyStateTracker.stateOfAtNow(_getKey(SnapshotType.TotalSwapFees0, pool));
        uint256 feesFromSwap1Before = historyStateTracker.stateOfAtNow(_getKey(SnapshotType.TotalSwapFees1, pool));

        historyStateTracker.updateHistoryState(
            _getKey(SnapshotType.TotalSwapFees0, pool),
            feesFromSwap0.add(feesFromSwap0Before)
        );
        historyStateTracker.updateHistoryState(
            _getKey(SnapshotType.TotalSwapFees1, pool),
            feesFromSwap1.add(feesFromSwap1Before)
        );
    }

    function snapshotPositionMint(
        address historyStateTracker,
        address nftManager,
        uint256 nftId,
        address pool
    ) public {
        IHistoryStateTrackerByEpoch historyStateTrackerByEpoch = IHistoryStateTrackerByEpoch(historyStateTracker);
        historyStateTrackerByEpoch.updatePositionOnMint(nftId, pool);
        snapshotPositionFees(historyStateTracker, nftManager, nftId, pool);
    }

    /**
     * @dev Required to snapshot position right before it's update,
     * since feeGrowthInside0LastX128 and feeGrowthInside1LastX128 variables stays up-to-date only for one value of liquidity,
     * and once liquidity for position will change, those values will be updated
     * @param historyStateTracker Address of HistoryStateTrackerByEpoch contract
     * @param nftId NFT ID of positon on NonfungiblePositionManager
     * @param pool Address of pool for position.
     */
    function snapshotPositionState(
        address historyStateTracker,
        uint256 nftId,
        address pool
    ) public {
        IHistoryStateTrackerByEpoch historyStateTrackerByEpoch = IHistoryStateTrackerByEpoch(historyStateTracker);
        historyStateTrackerByEpoch.updatePositionStateIfNecessary(nftId, pool);
    }

    function snapshotPositionFees(
        address historyStateTrackerByEpoch,
        address nftManager,
        uint256 nftId,
        address pool
    ) public {
        IHistoryStateTrackerByEpoch historyStateTracker = IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch);
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            // fee growth with previous values of liquidity
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            ,

        ) = INonfungiblePositionManager(nftManager).positions(nftId);

        historyStateTracker.updateLiquiditySnapshots(
            nftId,
            liquidity,
            feeGrowthInside0LastX128,
            feeGrowthInside1LastX128
        );
    }

    function snapshotTickState(
        address historyStateTrackerByEpoch,
        address pool,
        int24 tickIdx
    ) public {
        IHistoryStateTrackerByEpoch historyStateTracker = IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch);

        (, , uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, , , , ) =
            IEnosysDexV3PoolState(pool).ticks(tickIdx);

        historyStateTracker.updateHistoryState(
            _getTickKey(SnapshotType.TickFeeGrowthOutside0X128ForEpoch, pool, tickIdx),
            feeGrowthOutside0X128
        );
        historyStateTracker.updateHistoryState(
            _getTickKey(SnapshotType.TickFeeGrowthOutside1X128ForEpoch, pool, tickIdx),
            feeGrowthOutside1X128
        );
    }

    function snapshotPoolState(address historyStateTrackerByEpoch, address pool) public {
        IHistoryStateTrackerByEpoch historyStateTracker = IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch);

        (uint160 sqrtPriceX96, int24 currentTick, , , , , ) = IEnosysDexV3PoolState(pool).slot0();
        uint256 feeGrowthGlobal0X128 = IEnosysDexV3PoolState(pool).feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = IEnosysDexV3PoolState(pool).feeGrowthGlobal1X128();

        historyStateTracker.updateHistoryState(
            _getKey(SnapshotType.TickForEpoch, pool),
            uint256(_packUint160AndInt24ToUint192(sqrtPriceX96, currentTick))
        );
        historyStateTracker.updateHistoryState(
            getPoolSnapshotKey(SnapshotType.FeeGrowthGlobal0X128, pool),
            feeGrowthGlobal0X128
        );
        historyStateTracker.updateHistoryState(
            getPoolSnapshotKey(SnapshotType.FeeGrowthGlobal1X128, pool),
            feeGrowthGlobal1X128
        );
    }

    function getTotalSwapFeesForPoolAtEpoch(
        address historyStateTrackerByEpoch,
        address pool,
        uint256 epoch
    ) public view returns (uint256, uint256) {
        return (
            IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch).stateOfAt(
                _getKey(SnapshotType.TotalSwapFees0, pool),
                epoch
            ),
            IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch).stateOfAt(
                _getKey(SnapshotType.TotalSwapFees1, pool),
                epoch
            )
        );
    }

    function getPoolPriceAndTickAtEpoch(
        address historyStateTrackerByEpoch,
        address pool,
        uint256 epoch
    ) public view returns (uint160, int24) {
        uint192 packedValue =
            uint192(
                IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch).stateOfAt(
                    _getKey(SnapshotType.TickForEpoch, pool),
                    epoch
                )
            );
        return _unpackUint192ToUint160AndInt24(packedValue);
    }

    function getPositionLiquidityAtEpoch(
        address historyStateTrackerByEpoch,
        address nft,
        uint256 nftId,
        uint256 epoch
    ) public view returns (uint128) {
        return
            uint128(
                IHistoryStateTrackerByEpoch(historyStateTrackerByEpoch).stateOfAt(
                    _getPositionKey(SnapshotType.PositionLiquidity, nft, nftId),
                    epoch
                )
            );
    }

    function getPoolSnapshotKey(SnapshotType snapshotType, address pool) public pure returns (bytes32) {
        return _getKey(snapshotType, pool);
    }

    function getPositionSnapshotKey(
        SnapshotType snapshotType,
        address nft,
        uint256 nftId
    ) public pure returns (bytes32) {
        return _getPositionKey(snapshotType, nft, nftId);
    }

    function getTickSnapshotKey(
        SnapshotType snapshotType,
        address pool,
        int24 tickIdx
    ) public pure returns (bytes32) {
        return _getTickKey(snapshotType, pool, tickIdx);
    }

    /// @notice Get key for the snapshot type for the pool
    /// @param snapshotType The type of the snapshot
    /// @param pool The address of the pool
    /// @return The bytes32 representation of input parameters
    function _getKey(SnapshotType snapshotType, address pool) public pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, pool));
    }

    /// @notice Get key for the snapshot type for the NFT
    /// @param nft The address of the NonfungiblePositionManager
    /// @param nftId The ID of the NFT
    /// @return The bytes32 representation of input parameters
    function _getPositionKey(
        SnapshotType snapshotType,
        address nft,
        uint256 nftId
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, nft, nftId));
    }

    function _getTickKey(
        SnapshotType snapshotType,
        address pool,
        int24 tickIdx
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, pool, tickIdx));
    }

    function _getCurrentTickKey(SnapshotType snapshotType, address pool) public pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, pool));
    }

    /// @notice Packs uint160 and int24 into uint192
    /// @dev The uint160 is used to store the sqrt price x96 and the int24 is used to store the tick
    /// @dev The uint8 is used to store the sign of the int24
    /// @param _uint160 The uint160 to pack
    /// @param _int24 The int24 to pack
    /// @return The uint192 representation of the input parameters
    function _packUint160AndInt24ToUint192(uint160 _uint160, int24 _int24) public pure returns (uint192) {
        uint192 isPositive = _int24 >= 0 ? 1 : 0; //1 - is positive, 0 - is negpublicative
        uint192 _uint24 = isPositive == 1 ? uint192(_int24) : uint192(-_int24); //save int24 as positive
        return ((uint192(_uint160) << 32) | (_uint24 << 8)) | isPositive;
    }

    /// @notice Unpacks uint192 into uint160 and int24
    /// @dev The uint160 is used to store the sqrt price x96 and the int24 is used to store the tick
    /// @param packed The uint192 to unpack
    /// @return _uint160 The uint160 value (sqrtPriceX96)
    /// @return _int24 The int24 value (tick)
    function _unpackUint192ToUint160AndInt24(uint192 packed) public pure returns (uint160 _uint160, int24 _int24) {
        _uint160 = uint160(packed >> 32);
        _int24 = int24(packed >> 8);
        uint8 isPositive = uint8(packed);
        if (isPositive == 0) _int24 = -_int24; //int value saved as positive, so we need to convert it back to negative
    }
}
