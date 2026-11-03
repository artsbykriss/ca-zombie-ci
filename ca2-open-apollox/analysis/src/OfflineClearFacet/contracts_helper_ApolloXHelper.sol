// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../diamond/interfaces/IPairsManager.sol";
import "../diamond/interfaces/IVault.sol";
import 'hardhat/console.sol';

contract ApolloXHelper is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {

    address public immutable ApolloX;

    struct PairInfo {
        string name;
        address pairAddress;
    }

    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint balance;
        uint allowance;
        uint8 decimals;
    }

    constructor(address apolloX) {
        ApolloX = apolloX;
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
    }

    function fetchPrepareDataForTrade(address user) external view returns (PairInfo[] memory pairs, TokenInfo[] memory tokens) {
        console.log(ApolloX);
        IPairsManager.PairView[] memory pairViews = IPairsManager(ApolloX).pairsV4();
        pairs = new PairInfo[](pairViews.length);
        for (uint i = 0; i < pairViews.length; i ++) {
            pairs[i].name = pairViews[i].name;
            pairs[i].pairAddress = pairViews[i].base;
        }
        IVault.Token[] memory vaultTokens = IVault(ApolloX).tokensV3();
        tokens = new TokenInfo[](vaultTokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            tokens[i].tokenAddress = vaultTokens[i].tokenAddress;
            tokens[i].symbol = ERC20(vaultTokens[i].tokenAddress).symbol();
            tokens[i].balance = ERC20(vaultTokens[i].tokenAddress).balanceOf(user);
            tokens[i].allowance = ERC20(vaultTokens[i].tokenAddress).allowance(user, ApolloX);
            tokens[i].decimals = ERC20(vaultTokens[i].tokenAddress).decimals();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
