// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IExchangeGateway} from "../../interface/IExchangeGateway.sol";
import {Account} from "./Account.sol";

library FeeCollector {
    bytes32 constant _SLOT_PATH = keccak256(abi.encode("xyz.meridian.FeeCollector.Data"));

    struct Data {
        /// Exchange fess are accrued in the feeCollectorAccount
        address account;
        /// The subaccount identifier for the address accruing the protocol fees
        bytes32 subaccount;
    }

    function load() internal pure returns (Data storage $) {
        bytes32 s = _SLOT_PATH;
        assembly {
            $.slot := s
        }
    }

    /// @notice All fees from the protocol are awarded to the fee collector.
    function accrueFees(Data storage self, address feeToken, uint256 amount, uint64 messageIdx) internal {
        address account = self.account;
        bytes32 subaccount = self.subaccount;
        Account.Data storage accountData = Account.load(account);
        uint256 balance = accountData.balance[subaccount][feeToken] + amount;
        accountData.balance[subaccount][feeToken] = balance;

        emit IExchangeGateway.FeeAccrued(account, subaccount, feeToken, amount, balance, messageIdx);
    }
}
