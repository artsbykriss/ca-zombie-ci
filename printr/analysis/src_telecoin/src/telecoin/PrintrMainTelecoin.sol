// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrinted } from "../interfaces/telecoin/IPrinted.sol";
import { IPrintrMainTelecoin } from "../interfaces/telecoin/IPrintrMainTelecoin.sol";

import { ERC20 } from "./ERC20.sol";
import { Printed } from "./Printed.sol";
import { Telecoin } from "./Telecoin.sol";

/**
 * @title PrintrMainTelecoin
 * @notice Implementation of a Main Telecoin with teleport interface and interchain functionality
 * @dev Extends Telecoin to provide cross-chain functionality via LayerZero
 * @dev Bridging is only possible with lock/unlock/transferFrom, there are no mint/burn mechanisms
 */
contract PrintrTelecoin is IPrintrMainTelecoin, Printed, Telecoin {

    /**
     * @notice Initializes the token with its basic parameters
     * @param params The deployment parameters for the telecoin
     * @param treasury Address to receive the initial token supply
     * @param initialSupply The initial supply to mint
     */
    constructor(
        TelecoinDeployParams memory params,
        address treasury,
        uint256 initialSupply
    ) Printed(params.printr, treasury, initialSupply, IPrinted.TeleportType.Main) Telecoin(params) { }

    /**
     * @notice Internal function to handle token transfers with additional restrictions
     * @dev Override of ERC20._update that includes Printed contract restrictions.
     *      First checks if the transfer violates bonding curve completion rules,
     *      then performs the actual balance update. This ensures tokens cannot be
     *      added to liquidity pools before the bonding curve is completed.
     * @param from The address tokens are being transferred from (address(0) for minting)
     * @param to The address tokens are being transferred to (address(0) for burning)
     * @param amount The amount of tokens being transferred
     * @custom:throws CurveIsNotComplete if attempting to add tokens to restricted pool before completion
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(Printed, ERC20) {
        // Check Liquidity position opening restrictions
        Printed._update(from, to, amount);
        // Update balances
        ERC20._update(from, to, amount);
    }

}
