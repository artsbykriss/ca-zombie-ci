// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title RobinhoodChain
/// @notice Robinhood Chain mainnet addresses, read on chain and checksummed.
library RobinhoodChain {
    address internal constant UNISWAP_V2_FACTORY = 0x8bcEaA40B9AcdfAedF85AdF4FF01F5Ad6517937f;
    bytes32 internal constant UNISWAP_V2_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    address internal constant UNISWAP_V2_ROUTER = 0x89e5DB8B5aA49aA85AC63f691524311AEB649eba;
    address internal constant WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73;
    address internal constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address internal constant UNISWAP_V4_POOL_MANAGER = 0x8366a39CC670B4001A1121B8F6A443A643e40951;

    /// @notice The Uniswap V2 pair address for `_tokenA`/`_tokenB`, whether or not it has been created yet.
    function _uniswapV2PairFor(address _tokenA, address _tokenB) internal pure returns (address) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        return address(
            uint160(
                uint256(keccak256(abi.encodePacked(hex"ff", UNISWAP_V2_FACTORY, salt, UNISWAP_V2_PAIR_INIT_CODE_HASH)))
            )
        );
    }
}
