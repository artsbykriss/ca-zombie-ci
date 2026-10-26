// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDexFiVaultFactory.sol";
import "./IDexFiVault.sol";
import "./IDexFiProfit.sol";

interface IDexFiVaultProfitStorage {
    struct UserSyntheticAmount {
        address user;
        uint256 amount;
    }

    struct UserSharesInfo {
        uint256 accShares;
        uint256 lastRewardBlock;
        uint256 lastSyntheticBalance;
    }

    function divider() external view returns (uint256);

    function factory() external view returns (IDexFiVaultFactory);

    function vault() external view returns (address);

    function profitToken() external view returns (address);

    function profitTokenConnector() external view returns (IDexFiProfit);

    function usersSharesInfo(address user) external view returns (UserSharesInfo memory);

    function availableToClaim(address) external view returns (uint256);

    function fund() external view returns (uint256);

    function native() external view returns (IERC20);

    function users(uint256 index) external view returns (address);

    function usersCount() external view returns (uint256);

    function usersContains(address user) external view returns (bool);

    event ProfitFundsAdded(uint256 amount);
    event ProfitTokenUpdated(address profitToken);
    event Claimed(address indexed user, address indexed token, uint256 amount);
    event UserAdded(address indexed user);
    event UserRemoved(address indexed user);

    error CallerNotVault(address caller, address vault);
    error AddProfitFundsAmountZero();
    error UpdateProfitTokenVaultPublished();
    error ClaimAmountOverflow(uint256 amount, uint256 max);
    error UpdateProfitTokenUnsupported(address token);

    function initialize(IDexFiVaultFactory factory_, address profitToken_) external returns (bool);

    function updateUsersSharesBalance(UserSyntheticAmount[] memory usersSyntheticAmount) external returns (bool);

    function allocate() external returns (bool);

    function addProfitFunds(uint256 amount) external returns (bool);

    function claim(uint256 amount, address from) external returns (bool);

    function updateProfitToken(address profitToken_) external returns (bool);
}
