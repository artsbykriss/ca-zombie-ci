// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IEarnVault {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function totalPrincipal() external view returns (uint256);
    function onYield(uint256 amount) external;
    function claimReserve() external view returns (uint256);
    function claimable(address user) external view returns (uint256);
    function accrued(address user) external view returns (uint256);
    function principal(address user) external view returns (uint256);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function pauser() external view returns (address);
    function isBlacklisted(address user) external view returns (bool);
    function getVersion() external pure returns (string memory);
    function globalIndex() external view returns (uint256);
}

interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function take(address currency, address to, uint256 amount) external;
    function sync(address currency) external;
    function settle() external payable returns (uint256);
}

interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}

interface IRewardRedistributor {
    function snapshotVaultTVLs() external;
    function distribute() external;
    function lastSnapshotTimestamp() external view returns (uint256);
    function lastSnapshotBlockNumber() external view returns (uint256);
    function lastEarnTVL() external view returns (uint256);
    function fee_on_yield_bps() external view returns (uint16);
    function snapshotMaxAge() external view returns (uint256);
    function paused() external view returns (bool);
    function treasury() external view returns (address);
    function previewSplitCurrent()
        external
        view
        returns (
            uint256 couldBeMinted,
            uint256 feeToStartale,
            uint256 toEarn,
            uint256 toOn,
            uint256 toStartaleExtra,
            uint256 S_base,
            uint256 T_earn,
            uint256 T_yield
        );
}
