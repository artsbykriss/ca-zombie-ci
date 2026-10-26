// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./abstracts/utils/DexFiInitializable.sol";
import "./interfaces/IDexFiVaultProfitStorage.sol";
import "./interfaces/IDexFiVault.sol";

/**
 * @title DexFiVaultProfitStorage
 * @dev Contract for managing profit distribution and claiming for a DexFiVault.
 */
contract DexFiVaultProfitStorage is IDexFiVaultProfitStorage, DexFiInitializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public native;
    IDexFiVaultFactory public factory;
    uint256 public divider;
    address public vault;
    uint256 public fund;
    address public profitToken;
    IDexFiProfit public profitTokenConnector;
    mapping(address => uint256) public availableToClaim;

    EnumerableSet.AddressSet private _users;
    mapping(address => UserSharesInfo) private _usersSharesInfo;

    /**
     * @dev Get the user at a specific index in the users set.
     * @param index The index of the user to retrieve.
     * @return The address of the user at the given index.
     */
    function users(uint256 index) external view returns (address) {
        return _users.at(index);
    }

    /**
     * @dev Get the total number of users in the users set.
     * @return The total number of users.
     */
    function usersCount() external view returns (uint256) {
        return _users.length();
    }

    /**
     * @dev Check if a user is present in the users set.
     * @param user The address of the user to check.
     * @return true if the user is present in the users set.
     */
    function usersContains(address user) external view returns (bool) {
        return _users.contains(user);
    }

    /**
     * @dev Get the shares information for a specific user.
     * @param user The address of the user to get shares information for.
     * @return UserSharesInfo struct containing user shares information.
     */
    function usersSharesInfo(address user) external view returns (UserSharesInfo memory) {
        return _usersSharesInfo[user];
    }

    /**
     * @dev Constructor to initialize the DexFiVaultProfitStorage contract.
     * Disables initializers to prevent multiple initialization calls.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract with the DexFiVaultFactory and profit token address.
     * @param factory_ The DexFiVaultFactory instance.
     * @param profitToken_ The address of the profit token.
     * @return true if initialization is successful.
     */
    function initialize(IDexFiVaultFactory factory_, address profitToken_) external initializer returns (bool) {
        factory = factory_;
        divider = factory.DIVIDER();
        vault = msg.sender;
        native = IERC20(factory.native());
        _updateProfitToken(profitToken_);
        return true;
    }

    /**
     * @dev Update users' synthetic balances based on the provided UserSyntheticAmount array.
     * @param usersSyntheticAmount An array containing UserSyntheticAmount information.
     * @return true if the update is successful.
     */
    function updateUsersSharesBalance(
        UserSyntheticAmount[] memory usersSyntheticAmount
    ) external onlyInitialized onlyVault returns (bool) {
        for (uint256 i = 0; i < usersSyntheticAmount.length; i++) {
            UserSyntheticAmount memory updateInfo = usersSyntheticAmount[i];
            address user_ = updateInfo.user;
            if (updateInfo.amount > 0 && !_users.contains(user_)) {
                _users.add(user_);
                emit UserAdded(user_);
            }
            if (_usersSharesInfo[user_].lastSyntheticBalance == 0) {
                _usersSharesInfo[user_].lastRewardBlock = block.number;
                _usersSharesInfo[user_].lastSyntheticBalance = updateInfo.amount;
            } else {
                uint256 time = block.number - _usersSharesInfo[user_].lastRewardBlock;
                uint256 addShares = _usersSharesInfo[user_].lastSyntheticBalance * time;
                _usersSharesInfo[user_].accShares += addShares;
                _usersSharesInfo[user_].lastSyntheticBalance = updateInfo.amount;
                _usersSharesInfo[user_].lastRewardBlock = block.number;
            }
        }
        return true;
    }

    /**
     * @dev Allocate profits based on users' synthetic balances and other parameters.
     * @return true if the allocation is successful.
     */
    function allocate() external onlyInitialized returns (bool) {
        native.forceApprove(address(profitTokenConnector), fund);
        (uint256 amount, uint256 fundSubtrahend) = profitTokenConnector.swapNativeToProfit(fund);
        fund -= fundSubtrahend;
        address publisher = IDexFiVault(vault).publishData().publisher;
        if (publisher != address(0)) {
            uint256 publisherPart = (amount * factory.profitConfig().vaultOwnerProfit) / divider;
            availableToClaim[publisher] += publisherPart;
            amount -= publisherPart;
        }
        uint256 usersCount_ = _users.length();
        uint256 totalAccShares = 0;
        for (uint256 i = 0; i < usersCount_; i++) {
            address user_ = _users.at(i);
            uint256 time = block.number - _usersSharesInfo[user_].lastRewardBlock;
            uint256 addShares = _usersSharesInfo[user_].lastSyntheticBalance * time;
            _usersSharesInfo[user_].accShares += addShares;
            totalAccShares += _usersSharesInfo[user_].accShares;
        }
        bool totalAccSharesIsPositive = totalAccShares > 0;
        if (usersCount_ > 0) {
            for (uint256 i = usersCount_ - 1; i >= 0; i--) {
                address user_ = _users.at(i);
                if (totalAccSharesIsPositive) {
                    availableToClaim[user_] += (amount * _usersSharesInfo[user_].accShares) / totalAccShares;
                    _usersSharesInfo[user_].accShares = 0;
                }
                _usersSharesInfo[user_].lastRewardBlock = block.number;
                if (_usersSharesInfo[user_].lastSyntheticBalance == 0) {
                    _users.remove(user_);
                    emit UserRemoved(user_);
                }
                if (i == 0) break;
            }
        }
        return true;
    }

    /**
     * @dev Add native funds to the profit storage.
     * @param amount The amount of native funds to add.
     * @return true if the addition is successful.
     */
    function addProfitFunds(uint256 amount) external onlyInitialized returns (bool) {
        if (amount == 0) revert AddProfitFundsAmountZero();
        native.safeTransferFrom(msg.sender, address(this), amount);
        fund += amount;
        emit ProfitFundsAdded(amount);
        return true;
    }

    /**
     * @dev Claim profits from the storage.
     * @param amount The amount of profits to claim.
     * @param from The address from which to claim profits.
     * @return true if the claim is successful.
     */
    function claim(uint256 amount, address from) external onlyInitialized nonReentrant returns (bool) {
        if (msg.sender != factory.integrationConfig().profitClaimer) from = msg.sender;
        _claim(from, amount);
        return true;
    }

    /**
     * @dev Update the profit token and claim available profits for the vault owner.
     * @param profitToken_ The new profit token address.
     * @return true if the update is successful.
     */
    function updateProfitToken(address profitToken_) external onlyInitialized onlyVault returns (bool) {
        if (IDexFiVault(vault).publishData().published) revert UpdateProfitTokenVaultPublished();
        address vaultOwner = Ownable(vault).owner();
        _claim(vaultOwner, availableToClaim[vaultOwner]);
        _updateProfitToken(profitToken_);
        return true;
    }

    /**
     * @dev Internal function to claim profits for a user.
     * @param user The address of the user claiming profits.
     * @param amount The amount of profits to claim.
     */
    function _claim(address user, uint256 amount) private {
        if (amount > availableToClaim[user]) revert ClaimAmountOverflow(amount, availableToClaim[user]);
        availableToClaim[user] -= amount;
        IERC20(profitTokenConnector.underlying()).safeTransfer(user, amount);
        emit Claimed(user, profitToken, amount);
    }

    /**
     * @dev Internal function to update the profit token and connector.
     * @param profitToken_ The new profit token address.
     */
    function _updateProfitToken(address profitToken_) private {
        if (!factory.profitTokensWhitelistContains(profitToken_)) revert UpdateProfitTokenUnsupported(profitToken_);
        profitToken = profitToken_;
        profitTokenConnector = factory.profitTokenConnector(profitToken_);
        emit ProfitTokenUpdated(profitToken_);
    }

    /**
     * @dev Modifier to restrict function access to the vault only.
     */
    modifier onlyVault() {
        if (msg.sender != vault) revert CallerNotVault(msg.sender, vault);
        _;
    }
}
