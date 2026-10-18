// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ITokenStreamEmitter} from "contracts/reward/interfaces/ITokenStreamEmitter.sol";
import {ERC4626} from "openzeppelin-v5/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin-v5/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-v5/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20} from "openzeppelin-v5/token/ERC20/ERC20.sol";
import {ReentrancyGuardTransient} from "openzeppelin-v5/utils/ReentrancyGuardTransient.sol";

/// @dev ERC4626 vault that compounds rewards from a TokenStreamEmitter emitting the same asset.
contract CompoundingTokenStreamVault is ERC4626, ReentrancyGuardTransient {
    event Compounded(uint256 amount);
    event RewardSource(address source);

    error ZeroAddress();
    error RewardTokenNotSupported(address token, address source);

    IERC20 public immutable rewardToken;
    ITokenStreamEmitter public immutable rewardSource;

    constructor(IERC20 asset_, ITokenStreamEmitter rewardSource_)
        ERC20(_vaultName(asset_), _vaultSymbol(asset_))
        ERC4626(asset_)
    {
        if (address(asset_) == address(0) || address(rewardSource_) == address(0)) revert ZeroAddress();
        rewardToken = asset_;
        rewardSource = rewardSource_;
        _validateRewardSource(asset_, rewardSource_);
        emit RewardSource(address(rewardSource_));
    }

    function pendingRewards() public view returns (uint256) {
        return uint256(rewardSource.collectableAmount(address(rewardToken), address(this)));
    }

    function totalAssets() public view override returns (uint256) {
        return rewardToken.balanceOf(address(this)) + pendingRewards();
    }

    function compound() external nonReentrant returns (uint256 amount) {
        amount = _compound();
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        _compound();
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        _compound();
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        _compound();
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        _compound();
        return super.redeem(shares, receiver, owner);
    }

    function _compound() internal returns (uint256 amount) {
        amount = uint256(rewardSource.collect(address(rewardToken), address(this), type(uint128).max));
        if (amount > 0) emit Compounded(amount);
    }

    function _validateRewardSource(IERC20 asset_, ITokenStreamEmitter rewardSource_) private view {
        address[] memory tokens = rewardSource_.outputTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(asset_)) return;
        }
        revert RewardTokenNotSupported(address(asset_), address(rewardSource_));
    }

    function _vaultName(IERC20 asset_) private view returns (string memory) {
        string memory baseName = _tryGetString(asset_, IERC20Metadata.name.selector, "Token");
        return string.concat("Compounding ", baseName, " Vault");
    }

    function _vaultSymbol(IERC20 asset_) private view returns (string memory) {
        string memory baseSymbol = _tryGetString(asset_, IERC20Metadata.symbol.selector, "TKN");
        return string.concat("c", baseSymbol);
    }

    function _tryGetString(IERC20 asset_, bytes4 selector, string memory fallbackValue) private view returns (string memory) {
        (bool success, bytes memory data) = address(asset_).staticcall(abi.encodeWithSelector(selector));
        if (success && data.length >= 32) {
            return abi.decode(data, (string));
        }
        return fallbackValue;
    }
}

