// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function approve(address, uint256) external returns (bool);
}

/// @dev Only the externally-reachable surface actually used by the PoC.
interface IWildcatMarket {
    function version() external pure returns (string memory);
    function asset() external view returns (address);
    function borrower() external view returns (address);
    function sentinel() external view returns (address);
    function factory() external view returns (address);
    function archController() external view returns (address);
    function feeRecipient() external view returns (address);
    function hooks() external view returns (uint256);
    function isClosed() external view returns (bool);
    function totalAssets() external view returns (uint256);
    function totalDebts() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function borrowableAssets() external view returns (uint256);
    function coverageLiquidity() external view returns (uint256);
    function accruedProtocolFees() external view returns (uint256);
    function maximumDeposit() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function getUnpaidBatchExpiries() external view returns (uint32[] memory);
    function deposit(uint256) external;
    function depositUpTo(uint256) external returns (uint256);
    function borrow(uint256) external;
    function repay(uint256) external;
    function closeMarket() external;
    function rescueTokens(address) external;
    function nukeFromOrbit(address) external;
    function collectFees() external;
    function queueWithdrawal(uint256) external returns (uint32);
    function queueFullWithdrawal() external returns (uint32);
    function executeWithdrawal(address, uint32) external returns (uint256);
    function setMaxTotalSupply(uint256) external;
    function setAnnualInterestAndReserveRatioBips(uint16, uint16) external;
    function setProtocolFeeBips(uint16) external;
}

interface IWildcatHooks {
    function version() external view returns (string memory);
    function borrower() external view returns (address);
    function factory() external view returns (address);
    /// @dev OpenTermHooks.HookedMarket
    function getHookedMarket(
        address marketAddress
    ) external view returns (bool isHooked, bool transferRequiresAccess, bool depositRequiresAccess, uint128 minimumDeposit, bool transfersDisabled);
}

interface IWildcatHooksFactory {
    function name() external view returns (string memory);
    function archController() external view returns (address);
    function sanctionsSentinel() external view returns (address);
    function isHooksTemplate(address) external view returns (bool);
    function getHooksTemplates() external view returns (address[] memory);
}

interface IWildcatArchController {
    function owner() external view returns (address);
    function getRegisteredMarkets() external view returns (address[] memory);
    function isRegisteredBorrower(address) external view returns (bool);
    function getRegisteredBorrowers() external view returns (address[] memory);
}

interface IWildcatSanctionsEscrow {
    function canReleaseEscrow() external view returns (bool);
    function releaseEscrow() external;
    function escrowedAsset() external view returns (address, uint256);
}
