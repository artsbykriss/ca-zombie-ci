// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title IWETH
 * @notice Interface for Wrapped Ether (WETH) - an ERC20 token that wraps native ETH
 */
interface IWETH {

    /**
     * @notice Deposits native ETH into the contract to mint WETH tokens
     * @dev The amount of WETH minted equals the amount of ETH sent with the transaction
     */
    function deposit() external payable;

    /**
     * @notice Unwraps WETH back to ETH by burning tokens and transferring ETH
     * @param wad Amount of WETH to unwrap into ETH
     */
    function withdraw(
        uint256 wad
    ) external;

}
