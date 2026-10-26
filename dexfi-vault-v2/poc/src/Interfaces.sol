// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function deposit() external payable;
    function transfer(address, uint256) external returns (bool);
}

interface IDexFiVault {
    struct Farm { address beacon; uint256 percent; bytes data; }
    function native() external view returns (address);
    function owner() external view returns (address);
    function factory() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function profit() external view returns (uint256);
    function publishData() external view returns (bool, address);
    function farmsCount() external view returns (uint256);
    function farms(uint256) external view returns (Farm memory);
    function farmConnector(address) external view returns (address);
    function harvesterDebt() external view returns (uint256);
    function lastHarvestTimestamp() external view returns (uint256);
    function deposit(uint256 amount, address to, uint256 minMint) external returns (uint256);
    function withdraw(uint256 amount, address from, uint256 minNative) external returns (uint256);
    function harvest(uint256 minRestaking) external returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function emergencyWithdraw() external returns (uint256[] memory);
    function updateFarms(Farm[] memory, uint256) external returns (uint256, uint256);
    function publish(uint256) external returns (uint256);
}

interface IDexFiFarm {
    function vault() external view returns (address);
    function harvest() external returns (uint256);
    function deposit(uint256) external returns (uint256);
    function withdraw(uint256) external returns (uint256);
    function withdrawConvertless(uint256, address) external;
    function emergencyWithdraw(uint256, address) external;
    function initialize(bytes memory) external returns (bool);
    function reinitialize(bytes memory) external returns (bool);
    function liquidity(address) external view returns (uint256);
    function stakingToken() external view returns (address);
    function tokenId() external view returns (uint256);
}

interface IDexFiVaultFactory {
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function vaultsCount() external view returns (uint256);
    function vaults(uint256) external view returns (address);
    function farmsWhitelistCount() external view returns (uint256);
    function farmsWhitelist(uint256) external view returns (address);
    function farmCalculationConnector(address) external view returns (address);
    function defaultFarmsInitializeData(address) external view returns (bytes memory);
    function harvesterBlacklistContains(address) external view returns (bool);
    function createVault(string memory, string memory, uint256, address, IDexFiVault.Farm[] memory) external returns (address);
}
