// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { Fees } from "src/interfaces/exchanges/perps/engine/extensions/IPerpsHooks.sol";
import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";

/// @title IPerpsVaultManagement
/// @notice Interface for OTC (Over-The-Counter) vault trading functions
interface IPerpsVaultManagement {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct OtcParty {
        address account;
        IOrdersManager.OrderSide side;
        bool reduceOnly;
        bool skipMarginCheckAfterTrade;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when vault is not authorized for OTC transfers
    error UnauthorizedVault(address vault);

    /// @notice Thrown when OTC trade parties have the same address
    error OtcSamePartyAddress();

    /// @notice Thrown when OTC trade parties have the same side
    error OtcSameSide();

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an OTC trade is successfully matched
    event MatchOtcOrder(
        uint16 indexed marketId,
        address indexed maker,
        address indexed taker,
        IOrdersManager.OrderSide makerSide,
        uint256 size,
        uint256 price,
        Fees fees,
        int128 accumulatedFundingPayment
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Executes OTC trade between two vault addresses
    /// @param marketId The market ID
    /// @param makerAccount The maker vault address
    /// @param takerAccount The taker vault address
    /// @param side The order side
    /// @param size The trade size
    /// @param price The trade price
    function executeVaultOtc(
        uint16 marketId,
        address makerAccount,
        address takerAccount,
        IOrdersManager.OrderSide side,
        uint128 size,
        uint128 price
    ) external;
}
