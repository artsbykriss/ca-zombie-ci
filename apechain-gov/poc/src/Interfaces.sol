// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Minimal read/call interfaces for the ApeChain targets (no transactions are ever sent).
/// All calls in the tests are executed on a local fork only.

interface IAPEPredicts {
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function gameCount() external view returns (uint256);
    function getTotalPlayers() external view returns (uint256);
    function withdraw(uint256 amount) external;
    function resolveGame(uint256 gameId, uint8 winner, uint256 finalPrice) external;
    function cancelGame(uint256 gameId) external;
    function updateGameStatus(uint256 gameId, uint256 newStatus) external;
    function pause() external;
    function updateFeePercentage(uint256 newFee) external;
    function deposit(uint256 gameId, uint8 option) external payable;
    function claim(uint256 gameId) external;
    function refund(uint256 gameId) external;
}

interface IGovernanceManager {
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function house() external view returns (address);
    function paused() external view returns (bool);
    function changeOwner(address newOwner) external;
    function setHouse(address house_) external;
    function setPaused(bool p) external;
    function setRNG(address rng) external;
    function setIsAdmin(address admin, bool isAdmin_) external;
    function setFeeReceiver(address r) external;
}

interface IHouse {
    function totalShares() external view returns (uint256);
    function calculatePrice() external view returns (uint256);
    function migrator() external view returns (address);
    function manager() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external returns (uint256);
    function migrate(bytes calldata data) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICashOrCrash {
    error NotInitOwner();
    error InvalidInitialization();
    function owner() external view returns (address);
    function isAdmin(address a) external view returns (bool);
    function gameCounter() external view returns (uint256);
    function initialize(string calldata _messagePrefix) external;
    function withdrawFunds(address token, bool isNative, uint256 amount, address payable recipient) external;
    function addAdmin(address newAdmin) external;
    function setMessagePrefix(string memory _messagePrefix) external;
}

interface IMigrator {
    function v1House() external view returns (address);
    function houseV2() external view returns (address);
    function migrate(address user, bytes calldata data) external payable;
}

interface ISafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function VERSION() external view returns (string memory);
}
