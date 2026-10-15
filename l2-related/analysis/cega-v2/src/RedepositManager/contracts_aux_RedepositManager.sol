// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IViewEntry
} from "../cega-strategies/common/interfaces/IViewEntry.sol";
import {
    IProductEntry
} from "../cega-strategies/common/interfaces/IProductEntry.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";
import { Transfers } from "../utils/Transfers.sol";
import { IRedepositManager } from "./interfaces/IRedepositManager.sol";
import { Errors } from "../utils/Errors.sol";

contract RedepositManager is IRedepositManager {
    using Transfers for address;

    // CONSTANTS

    address public immutable cegaEntry;

    // MODIFIERS

    modifier onlyCegaEntry() {
        require(msg.sender == cegaEntry, Errors.NOT_CEGA_ENTRY);
        _;
    }

    // CONSTRUCTOR

    constructor(address _cegaEntry) {
        cegaEntry = _cegaEntry;
    }

    // FUNCTIONS

    receive() external payable {}

    function redeposit(
        ITreasury treasury,
        uint32 productId,
        address asset,
        uint128 amount,
        address receiver
    ) external onlyCegaEntry {
        try IViewEntry(cegaEntry).getProductDepositAsset(productId) returns (
            address productDepositAsset
        ) {
            if (productDepositAsset == asset) {
                // Redeposit
                treasury.withdraw(asset, address(this), amount, true);
                uint256 value = asset.ensureApproval(cegaEntry, amount);
                try
                    IProductEntry(cegaEntry).addToDepositQueue{ value: value }(
                        productId,
                        amount,
                        receiver
                    )
                {
                    emit Redeposited(productId, asset, amount, receiver, true);
                    return;
                } catch {
                    // Return asset to treasury for withdrawal
                    require(
                        asset.transfer(address(treasury), amount),
                        Errors.TRANSFER_FAILED
                    );
                }
            }
        } catch {}

        // If execution reached this line, then impossible to redeposit, transfer to receiver
        treasury.withdraw(asset, receiver, amount, false);
        emit Redeposited(productId, asset, amount, receiver, false);
    }
}
