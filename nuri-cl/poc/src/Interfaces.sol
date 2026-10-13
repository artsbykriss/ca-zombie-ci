// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @dev Minimal interfaces for the live Nuri (Ramses V2 fork) deployment on Scroll.
/// Addresses verified on-chain at block 35364505 (2026-10-13).

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IClPoolFactory {
    function owner() external view returns (address);
    function feeSetter() external view returns (address);
    function feeCollector() external view returns (address);
    function implementation() external view returns (address);
    function feeProtocol() external view returns (uint8);
    function setOwner(address) external;
    function setImplementation(address) external;
    function setFeeCollector(address) external;
    function setFeeProtocol(uint8) external;
    function enableFeeAmount(uint24, int24) external;
    function getPool(address, address, uint24) external view returns (address);
}

interface IClPool {
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
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function protocolFees() external view returns (uint128, uint128);
    function collectProtocol(address, uint128, uint128) external returns (uint128, uint128);
    function setFee(uint24) external;
    function setFeeProtocol() external;
    function positionPeriodSecondsInRange(
        uint256,
        address,
        uint256,
        int24,
        int24
    ) external view returns (uint256);
}

interface IGaugeV2 {
    function pool() external view returns (address);
    function voter() external view returns (address);
    function feeCollector() external view returns (address);
    function firstPeriod() external view returns (uint256);
    function getReward(uint256, address[] memory) external;
    function getRewardForOwner(uint256, address[] memory) external;
    function earned(address, uint256) external view returns (uint256);
    function periodEarned(uint256, address, uint256) external view returns (uint256);
}

interface IFeeCollector {
    function treasury() external view returns (address);
    function treasuryFees() external view returns (uint256);
    function isTokenLive() external view returns (bool);
    function collectProtocolFees(IClPool) external;
}

interface INonfungiblePositionManager {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
}

interface IVoter {
    function gauges(address) external view returns (address);
    function feeDistributors(address) external view returns (address);
    function isAlive(address) external view returns (bool);
}

interface IFeeDistributor {
    function pairFees() external view returns (address);
    function getReward(uint256, address[] memory) external;
    function getRewardForOwner(uint256, address[] memory) external;
}

interface IVotingEscrow {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
}

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgrade(address, address) external;
}

interface ITimelock {
    function getMinDelay() external view returns (uint256);
}

/// @dev Attacker-controlled "pool" used to probe the permissionless
///      FeeCollector.collectProtocolFees entrypoint. It advertises WETH/USDC and
///      a no-op collectProtocol so the call cannot move anything.
contract FakePool {
    address public immutable weth;
    address public immutable usdc;

    constructor(address _weth, address _usdc) {
        weth = _weth;
        usdc = _usdc;
    }

    function token0() external view returns (address) {
        return weth;
    }

    function token1() external view returns (address) {
        return usdc;
    }

    function collectProtocol(address, uint128, uint128) external pure returns (uint128, uint128) {
        return (0, 0);
    }
}
