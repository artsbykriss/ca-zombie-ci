// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "solady/auth/Ownable.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

/**
 * @title   g8keepFactoryConfiguration
 * @notice  Settings contract for initial deployment of g8keepFactory to allow
 * @notice  for a deterministic address across EVM blockchains where the
 * @notice  initial configuration settings may differ by chain.
 */
contract g8keepFactoryConfiguration is Ownable {
    /// @dev Address that will be the initial owner of the g8keepFactory
    address private g8keepFactoryAdmin;
    /// @dev Address that will be the initial fee recipient of initial liquidity fees.
    address private g8keepFeeWallet;
    /// @dev Address of the Uniswap V2 Router.
    address private uniswapV2Router;
    /// @dev Initial minimum liquidity setting for native tokens.
    uint256 private minimumWETHLiquidity;

    /// @dev Thrown when setting a configuration address to the zero address.
    error ZeroAddress();

    /**
     * @notice  Constructs the g8keepFactoryConfiguration contract with an initial owner.
     * 
     * @param _configurationOwner  Address that owns the configuration contract.
     */
    constructor(address _configurationOwner) {
        _initializeOwner(_configurationOwner);
    }

    /**
     * @notice  Admin function to set the initial configuration parameters for the g8keepFactory.
     * 
     * @param _g8keepFactoryAdmin    Address that will be the initial owner of the g8keepFactory.
     * @param _g8keepFeeWallet       Address that will be the initial recipient of initial liquidity fees.
     * @param _uniswapV2Router       Address of the Uniswap V2 Router.
     * @param _minimumWETHLiquidity  Initial minimum liquidity setting for native tokens.
     */
    function setFactoryConfiguration(
        address _g8keepFactoryAdmin,
        address _g8keepFeeWallet,
        address _uniswapV2Router,
        uint256 _minimumWETHLiquidity
    ) external onlyOwner {
        if (
            _g8keepFactoryAdmin == address(0)
            || _g8keepFeeWallet == address(0)
            || _uniswapV2Router == address(0)
        ) {
            revert ZeroAddress();
        }

        g8keepFactoryAdmin = _g8keepFactoryAdmin;
        g8keepFeeWallet = _g8keepFeeWallet;
        uniswapV2Router = _uniswapV2Router;
        minimumWETHLiquidity = _minimumWETHLiquidity;
    }

    /**
     * @notice  Returns the factory configuration settings in one call for gas efficiency.
     * 
     * @dev     WETH address is retrieved from the Uniswap V2 Router for compliance with ETH<->Token
     * @dev     swaps with native wrapping and unwrapping.
     * 
     * @return _g8keepFactoryAdmin    Address that will be the initial owner of the g8keepFactory.
     * @return _g8keepFeeWallet       Address that will be the initial recipient of initial liquidity fees.
     * @return _uniswapV2Router       Address of the Uniswap V2 Router.
     * @return _WETH                  Address of the WETH contract from Uniswap V2 Router.
     * @return _minimumWETHLiquidity  Initial minimum liquidity setting for native tokens.
     */
    function getFactoryConfiguration() external view returns(
        address _g8keepFactoryAdmin,
        address _g8keepFeeWallet,
        address _uniswapV2Router,
        address _WETH,
        uint256 _minimumWETHLiquidity
    ) {
        _g8keepFactoryAdmin = g8keepFactoryAdmin;
        _g8keepFeeWallet = g8keepFeeWallet;
        _uniswapV2Router = uniswapV2Router;
        _WETH = IUniswapV2Router02(_uniswapV2Router).WETH();
        _minimumWETHLiquidity = minimumWETHLiquidity;
    }
}