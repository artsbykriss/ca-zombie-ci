// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

/* ------------------------------------------------------------------ */
/* USX.Capital / Scroll                                                */
/* ------------------------------------------------------------------ */

interface ITreasury {
    function USDC() external view returns (address);
    function USX() external view returns (address);
    function sUSX() external view returns (address);
    function admin() external view returns (address);
    function governance() external view returns (address);
    function allocator() external view returns (address);
    function reporter() external view returns (address);
    function assetManager() external view returns (address);
    function assetManagerUSDC() external view returns (uint256);
    function netDeposits() external view returns (uint256);
    function netEpochProfits() external view returns (uint256);
    function setAdmin(address) external;
    function setGovernance(address) external;
    function addFacet(address, bytes4[] calldata) external;
    function transferUSDCtoAssetManager(uint256) external;
    function transferUSDCFromAssetManager(uint256) external;
    function transferUSDCForWithdrawal() external;
}

interface IAssetManager {
    function withdraw(uint256) external;
    function deposit(uint256) external;
    function getWeights() external view returns (address[] memory, uint256[] memory);
    function treasury() external view returns (address);
}

interface IUSXToken {
    function deposit(uint256) external;
    function requestUSDC(uint256) external;
    function whitelistedUsers(address) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function admin() external view returns (address);
    function governance() external view returns (address);
    function paused() external view returns (bool);
    function totalOutstandingWithdrawalAmount() external view returns (uint256);
    function totalMatchedWithdrawalAmount() external view returns (uint256);
}

interface IGateway {
    struct EncryptedReceiver {
        bytes receiver;
        uint256 keyId;
    }

    function transferUSDC(
        uint256 amount,
        EncryptedReceiver calldata usxReceiver,
        EncryptedReceiver calldata usdcReceiver
    ) external;

    function transferToken(
        address token,
        uint256 swapAmount,
        address swapRouter,
        bytes calldata swapData,
        EncryptedReceiver calldata usxReceiver,
        EncryptedReceiver calldata usdcReceiver
    ) external payable;

    function expectedUSDCReceiver() external view returns (bytes memory, uint256);
    function getLatestEncryptionKey() external view returns (uint256, bytes memory);
    function withdrawTokens(address, address, uint256) external;
    function nonce() external view returns (uint256);
    function USDC() external view returns (address);
    function USX() external view returns (address);
    function counterpart() external view returns (address);
    function erc20Gateway() external view returns (address);
    function minUSDCAmount() external view returns (uint256);
}

interface IOldGateway {
    function expectedUSDCReceiver() external view returns (bytes memory, uint256);
}

/* ------------------------------------------------------------------ */
/* Mezzanine / Ethereum                                                */
/* ------------------------------------------------------------------ */

interface IVault {
    struct TrancheInfo {
        address tranche;
        uint16 riskPremiumBps;
        bool enabled;
    }

    function tranchesLength() external view returns (uint256);
    function getTranches(
        uint256 start,
        uint256 count
    ) external view returns (address[] memory, uint16[] memory, bool[] memory);
    function getTrancheOrder() external view returns (address[] memory);
    function getTrancheOrderAndPairs() external view returns (address[] memory, bool[] memory);
    function tranchePairedTo(address) external view returns (address);
    function epochDuration() external view returns (uint64);
    function epochStart() external view returns (uint48);
    function currentEpochId() external view returns (uint64);
    function mzusd() external view returns (address);
    function usdc() external view returns (address);
    function lossManager() external view returns (address);
    function navOracle() external view returns (address);
    function pauseManager() external view returns (address);
    function setTrancheConfig(
        TrancheInfo[] calldata _tranches,
        bool[] calldata _isPairedWithNext,
        uint16 _baseRewardBps
    ) external;
    function advanceEpoch() external returns (uint256);
    function distributeYield(uint256 usdcReported) external;
    function rebalance() external;
}

interface INavOracle {
    function submitNav() external;
    function performUpkeep(bytes calldata performData) external;
    function rejectPendingNav() external;
    function hasPendingNav() external view returns (bool);
    function pendingDeltaUSDC() external view returns (uint128);
    function pendingIsYield() external view returns (bool);
    function pendingReadyAt() external view returns (uint48);
    function navOracle() external view returns (address);
    function totalSupplyOracle() external view returns (address);
    function vetoPeriod() external view returns (uint32);
    function maxAnswerStaleness() external view returns (uint32);
    function authority() external view returns (address);
}

interface ILossManager {
    function applyLoss(uint256 usdcLoss) external;
    function maxLossPerTxUSDC() external view returns (uint256);
}

interface ITranche {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function requestWithdrawal(uint256 shares) external;
    function finalizeEpoch(uint256 epochId) external;
    function claim(address user, uint256 epochId) external;
    function userSharesByEpoch(address, uint256) external view returns (uint256);
    function unstakeDelayEpochs() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function asset() external view returns (address);
    function directWithdrawEnabled() external view returns (bool);
}

interface IMZUSD {
    function deposit(uint256 amountUSDC) external;
    function requestWithdrawal(uint256 amountMZ) external;
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

interface IFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
