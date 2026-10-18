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
import './LiquidityMath.sol';
import './SqrtPriceMath.sol';
import './TickMath.sol';
import '../interfaces/IEnosysDexV3Pool.sol';
import '../interfaces/IHistoryStateTrackerBase.sol';

/// @title Liquidity Underlying Token Balance Tracker Library
/// @notice Library for tracking underlying liquidity token balances of NFTs (positions) and total supply of this token in EnosysDex V3 pools
library LiquidityBalanceHelper {
    using SafeMath for uint256;

    enum SnapshotType {PriceAndTick, TokenTotalSupply}

    /// @notice Updates the sqrt price and tick snapshot for a pool at the current block number at historyStateTracker
    /// @param historyStateTracker The address of the history state tracker
    /// @param pool The address of the pool to update the snapshot for
    /// @param sqrtPriceX96 The current sqrt price x96 of the pool
    /// @param tick The current tick of the pool
    function updateSqrtPriceX96AndTickSnapshot(
        address historyStateTracker,
        address pool,
        uint160 sqrtPriceX96,
        int24 tick
    ) public {
        IHistoryStateTrackerBase(historyStateTracker).updateHistoryState(
            _getKey(SnapshotType.PriceAndTick, pool),
            uint256(_packUint160AndInt24ToUint256(sqrtPriceX96, tick))
        );
    }

    /// @notice Updates the token total supply snapshot for a pool at the current block number at historyStateTracker
    /// @dev The updated value represent the token that corresponds to the liquidity in the pools
    /// and doesn't include the token that is going to be paid as collected fees
    /// @param historyStateTracker The address of the history state tracker
    /// @param pool The address of the pool to update the token snapshot for
    /// @param token The address of the underlying token
    /// @param tokenDelta The change in token supply
    /// @param isIncrease A boolean indicating whether the token supply is increasing or decreasing
    function updateTokenTotalSupply(
        address historyStateTracker,
        address pool,
        address token,
        uint256 tokenDelta,
        bool isIncrease
    ) public {
        bytes32 key = _getKey(SnapshotType.TokenTotalSupply, pool, token);
        uint256 tokenTotalSupply = IHistoryStateTrackerBase(historyStateTracker).stateOfAtNow(key);
        tokenTotalSupply = isIncrease ? tokenTotalSupply.add(tokenDelta) : tokenTotalSupply.sub(tokenDelta);
        IHistoryStateTrackerBase(historyStateTracker).updateHistoryState(key, tokenTotalSupply);
    }

    /// @notice Updates the liquidity snapshot for an NFT at the current block number at historyStateTracker
    /// @param historyStateTracker The address of the history state tracker
    /// @param nft The address of the NonfungiblePositionManager
    /// @param nftId The ID of the NFT
    /// @param liquidity The liquidity amoun of the NFT (position)
    function updateLiquiditySnapshot(
        address historyStateTracker,
        address nft,
        uint256 nftId,
        uint256 liquidity
    ) public {
        IHistoryStateTrackerBase(historyStateTracker).updateHistoryState(_getKey(nft, nftId), liquidity);
    }

    /// @notice Returns the balance of underlying ERC20 token of an NFT (position) at a specific block number
    /// @param historyStateTracker The address of the history state tracker
    /// @param token The address of the underlying token of NFT for which history balance should be tracked
    /// @param nft The address of the NonfungiblePositionManager
    /// @param nftId The ID of the NFT
    /// @param pool The address of the pool corresponding to the provided NFT
    /// @param tickLower The lower tick of the NFT (position)
    /// @param tickUpper The upper tick of the NFT (position)
    /// @param blockNumber The block number to get the token balance at
    /// @return The ubderlying token balance of the NFT at the specified block number
    function getTokenBalanceOfAt(
        address historyStateTracker,
        address token,
        address nft,
        uint256 nftId,
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 blockNumber
    ) public view returns (uint256) {
        int128 liquidity = int128(_getLiquidityAt(historyStateTracker, nft, nftId, blockNumber));
        (uint160 sqrtPriceX96, int24 tick) = _getSqrtPriceX96AndTickAt(historyStateTracker, pool, blockNumber);

        int256 tokenAmount;
        if (IEnosysDexV3Pool(pool).token0() == token) {
            if (tick < tickLower) {
                tokenAmount = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidity
                );
            } else if (tick < tickUpper) {
                tokenAmount = SqrtPriceMath.getAmount0Delta(
                    sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidity
                );
            }
        } else if (IEnosysDexV3Pool(pool).token1() == token) {
            if (tick >= tickLower && tick < tickUpper) {
                tokenAmount = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    sqrtPriceX96,
                    liquidity
                );
            } else if (tick >= tickUpper) {
                tokenAmount = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidity
                );
            }
        }
        require(tokenAmount >= 0, 'LiquidityBalanceHelper: token amount cannot be negative');
        return uint256(tokenAmount);
    }

    /// @notice Returns the total token total supply at the current block number
    /// @dev The returned value represent the token that corresponds to the liquidity in the pools
    /// (and doesn't include the token that is going to be paid as collected fees)
    /// @param historyStateTracker The address of the history state tracker
    /// @param pool The address of the pool
    /// @return The total token liquidity supply at the current block number
    function getTokenTotalSupplyAt(
        address historyStateTracker,
        address pool,
        address token,
        uint256 blockNumber
    ) public view returns (uint256) {
        return
            IHistoryStateTrackerBase(historyStateTracker).stateOfAt(
                _getKey(SnapshotType.TokenTotalSupply, pool, token),
                blockNumber
            );
    }

    /// @notice Get key for the snapshot type for the pool
    /// @param snapshotType The type of the snapshot
    /// @param pool The address of the pool
    /// @return The bytes32 representation of input parameters
    function _getKey(SnapshotType snapshotType, address pool) internal pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, pool));
    }

    /// @notice Get key for the snapshot type for the pool
    /// @param snapshotType The type of the snapshot
    /// @param pool The address of the pool
    /// @param token The address of the underlying token (token0 or token1)
    /// @return The bytes32 representation of input parameters
    function _getKey(
        SnapshotType snapshotType,
        address pool,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(snapshotType, pool, token));
    }

    /// @notice Get key for the snapshot type for the NFT
    /// @param nft The address of the NonfungiblePositionManager
    /// @param nftId The ID of the NFT
    /// @return The bytes32 representation of input parameters
    function _getKey(address nft, uint256 nftId) internal pure returns (bytes32) {
        return keccak256(abi.encode(nft, nftId));
    }

    /// @notice Returns the sqrt price and tick at the specified block number
    /// @param historyStateTracker The address of the history state tracker
    /// @param pool The address of the pool
    /// @param blockNumber The block number to get the sqrt price and tick at
    /// @return The sqrt price and tick at the specified block number
    function _getSqrtPriceX96AndTickAt(
        address historyStateTracker,
        address pool,
        uint256 blockNumber
    ) internal view returns (uint160, int24) {
        uint256 packedValue =
            uint256(
                IHistoryStateTrackerBase(historyStateTracker).stateOfAt(
                    _getKey(SnapshotType.PriceAndTick, pool),
                    blockNumber
                )
            );
        return _unpackUint256ToUint160AndInt24(packedValue);
    }

    /// @notice Returns the liquidity of an NFT at the specified block number
    /// @param historyStateTracker The address of the history state tracker
    /// @param nft The address of the NonfungiblePositionManager
    /// @param nftId The ID of the NFT
    /// @param blockNumber The block number to get the liquidity at
    /// @return The liquidity of the NFT at the specified block number
    function _getLiquidityAt(
        address historyStateTracker,
        address nft,
        uint256 nftId,
        uint256 blockNumber
    ) internal view returns (uint256) {
        return IHistoryStateTrackerBase(historyStateTracker).stateOfAt(_getKey(nft, nftId), blockNumber);
    }

    /// @notice Packs uint160 and int24 into uint256
    /// @dev The uint160 is used to store the sqrt price x96 and the int24 is used to store the tick
    /// @dev The uint8 is used to store the sign of the int24
    /// @param _uint160 The uint160 to pack
    /// @param _int24 The int24 to pack
    /// @return The uint256 representation of the input parameters
    function _packUint160AndInt24ToUint256(uint160 _uint160, int24 _int24) internal pure returns (uint256) {
        uint256 isPositive = _int24 >= 0 ? 1 : 0; //1 - is positive, 0 - is negative
        uint256 _uint24 = isPositive == 1 ? uint256(_int24) : uint256(-_int24); //save int24 as positive
        return ((uint256(_uint160) << 96) | (_uint24 << 8)) | isPositive;
    }

    /// @notice Unpacks uint256 into uint160 and int24
    /// @dev The uint160 is used to store the sqrt price x96 and the int24 is used to store the tick
    /// @param packed The uint256 to unpack
    /// @return _uint160 The uint160 value (sqrtPriceX96)
    /// @return _int24 The int24 value (tick)
    function _unpackUint256ToUint160AndInt24(uint256 packed) internal pure returns (uint160 _uint160, int24 _int24) {
        _uint160 = uint160(packed >> 96);
        _int24 = int24(packed >> 8);
        uint8 isPositive = uint8(packed);
        if (isPositive == 0) _int24 = -_int24; //int value saved as positive, so we need to convert it back to negative
    }
}
