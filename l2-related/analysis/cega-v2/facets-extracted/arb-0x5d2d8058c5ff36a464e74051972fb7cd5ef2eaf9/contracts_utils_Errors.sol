// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

library Errors {
    string public constant NOT_CEGA_ENTRY = "1";
    string public constant NOT_CEGA_ADMIN = "2";
    string public constant NOT_TRADER_ADMIN = "3";
    string public constant NOT_TRADE_WINNER = "4";
    string public constant INVALID_VAULT = "5";
    string public constant INVALID_VAULT_STATUS = "6";
    string public constant VAULT_IN_ZOMBIE_STATE = "7";
    string public constant TRADE_DEFAULTED = "8";
    string public constant INVALID_SETTLEMENT_STATUS = "9";
    string public constant VAULT_IN_DISPUTE = "10";
    string public constant VAULT_NOT_IN_DISPUTE = "11";
    string public constant OUTSIDE_DISPUTE_PERIOD = "12";
    string public constant TRADE_HAS_NO_WINNER = "13";
    string public constant TRADE_NOT_CONVERTED = "14";
    string public constant TRADE_CONVERTED = "15";
    string public constant INVALID_TRADE_END_DATE = "16";
    string public constant INVALID_PRICE = "17";
    string public constant VALUE_TOO_SMALL = "18";
    string public constant VALUE_TOO_LARGE = "19";
    string public constant VALUE_IS_ZERO = "20";
    string public constant MAX_DEPOSIT_LIMIT_REACHED = "21";
    string public constant DEPOSIT_QUEUE_NOT_OPEN = "22";
    string public constant INVALID_QUOTE_OR_BASE_ASSETS = "23";
    string public constant INVALID_MIN_DEPOSIT_AMOUNT = "24";
    string public constant INVALID_MIN_WITHDRAWAL_AMOUNT = "25";
    string public constant INVALID_STRIKE_PRICE = "26";
    string public constant TRANSFER_FAILED = "27";
    string public constant NOT_AVAILABLE_DATA_SOURCE = "28";
    string public constant NO_PRICE_AVAILABLE = "29";
    string public constant NO_PRICE_FEED_SET = "30";
    string public constant INCOMPATIBLE_PRICE = "31";
    string public constant NOT_CEGA_ENTRY_OR_REDEPOSIT_MANAGER = "32";
    string public constant NO_PROXY_FOR_REDEPOSIT = "33";
    string public constant NOT_TRADE_WINNER_OR_TRADER_ADMIN = "34";
    string public constant TRADE_NOT_STARTED = "35";
    string public constant NOT_AVAILABLE_SWAP_TYPE = "36";
    string public constant NOT_AVAILABLE_SWAP_PATH = "37";
    string public constant PROTOCOL_PAUSED = "38";
    string public constant WRONG_STRATEGY = "39";
    string public constant INVALID_ARRAY_LENGTH = "40";
    string public constant UNKNOWN_BARRIER_TYPE = "41";
    string public constant NOT_BOND_OPTION = "42";
    string public constant UNAUTHORIZED_BOND_RECEIVER = "43";
    string public constant REMAINING_VALUE_TOO_SMALL = "44";
    string public constant VALUE_IN_DISPUTE_GRACE_DELAY = "45";
    string public constant NOT_SERVICE_ADMIN = "46";
    string public constant VALUE_NON_ZERO = "47";
    string public constant OUTSIDE_RANGE = "48";
    string public constant INVALID_SIGNATURE = "49";
    string public constant NOT_OPERATOR_ADMIN = "50";
    string public constant INCOMPATIBLE_PRODUCT = "51";
    string public constant CANT_SET_ROTATIONS_FOR_ANOTHER_USER = "52";
}
