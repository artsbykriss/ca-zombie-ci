// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFDFPair} from "../IFDFPair.sol";

/**
 * @title IFDFPairV3
 * @notice Interface for FDFPairV3 contract with signed-fee buy/sell/swap execution
 * @dev Extends IFDFPair with V3 signed fee, discount, and surge guard features
 */
interface IFDFPairV3 is IFDFPair {

    function SWAP_TOKENS_SIG() external pure returns (bytes4);

    function SELLTOKENS_SIG_V3() external pure returns (bytes4);

    function SWAP_TOKENS_SIG_V3() external pure returns (bytes4);

    // ═══════════════════════════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════════════════════════

    error FEE_TOO_HIGH();
    error STALE_SURGE_EPOCH(uint256 playerId, uint256 expectedEpoch, uint256 actualEpoch);
    error EFFECTIVE_FEE_NEGATIVE();
    error BASE_FEE_OUT_OF_RANGE();
    error EFFECTIVE_FEE_OUT_OF_RANGE();

    // ═══════════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when a player's surge epoch advances due to a fee rate change
     * @param playerId The player token ID whose surge epoch advanced
     * @param newEpoch The new surge epoch value
     * @param feeRate The base fee rate (feeRateBps) that triggered the advance
     */
    event SurgeEpochAdvanced(uint256 indexed playerId, uint256 newEpoch, uint256 feeRate);

    /**
     * @notice Emitted on every trade to expose the full fee breakdown per player
     * @param user The address executing the trade
     * @param playerTokenIds Array of player token IDs involved
     * @param feeRateBps Array of base fee rates (drives surge epoch)
     * @param discountFeeBps Array of per-user fee adjustments (negative = discount, positive = surcharge)
     * @param effectiveFeeBps Array of effective fee rates (feeRateBps + discountFeeBps)
     */
    event FeeBreakdown(
        address indexed user,
        uint256[] playerTokenIds,
        uint256[] feeRateBps,
        int256[] discountFeeBps,
        uint256[] effectiveFeeBps
    );

    /**
     * @notice Emitted when tokens are swapped between two player pools
     * @param swapper Address initiating the swap
     * @param recipient Address receiving the output tokens
     * @param playerTokenIdsIn Array of player token IDs being sold
     * @param playerTokenAmountsIn Array of amounts of input tokens
     * @param playerTokenIdsOut Array of player token IDs being bought
     * @param playerTokenAmountsOut Array of amounts of output tokens received
     * @param currencyReceivedArr Array of currency received
     * @param sellFeeAmounts Array of sell fees paid
     */
    event TokensSwapped(
        address indexed swapper,
        address indexed recipient,
        uint256[] playerTokenIdsIn,
        uint256[] playerTokenAmountsIn,
        uint256[] playerTokenIdsOut,
        uint256[] playerTokenAmountsOut,
        uint256[] currencyReceivedArr,
        uint256[] sellFeeAmounts
    );

    event FeeGuardrailsUpdated(FeeGuardrails guardrails);

    // ═══════════════════════════════════════════════════════════════════════════════════
    // STRUCTS
    // ═══════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Governor-configurable fee guardrails packed into a single storage slot.
     * @dev uint64 is more than sufficient for basis points (max value ~1.8e19 vs MAX_FEE_BPS = 40,000).
     *      Effective fee = feeRateBps + discountFeeBps.
     */
    struct FeeGuardrails {
        uint64 minEffectiveFeeBps; // Min effective fee (0 = allow zero-fee buybacks)
        uint64 maxEffectiveFeeBps; // Max effective fee (cannot exceed MAX_FEE_BPS)
        uint64 minBaseFeeBps;      // Min base fee rate (constrains surge epoch driver)
        uint64 maxBaseFeeBps;      // Max base fee rate (constrains surge epoch driver)
    }

    /**
     * @notice Parameters for swapping player tokens
     * @dev Used in swapTokens function
     */
    struct SwapTokensParams {
        uint256[] playerTokenIdsIn;      // Array of player token IDs to sell
        uint256[] playerTokenAmountsIn;  // Array of amounts to sell
        uint256[] playerTokenIdsOut;     // Array of player token IDs to buy
        uint256[] playerTokenAmountsOut; // Array of minimum amounts to receive
        uint256 deadline;                // Transaction deadline timestamp
        address recipient;               // Address to receive output tokens (address(0) = msg.sender)
        bytes signature;                 // EIP-712 signature for authorization
        uint256 nonce;                   // Unique nonce for replay protection
    }

    struct SellTokensV3Obj {
        address recipient;
        uint256 minCurrencyToReceive;
        uint256[] feeRateBps;
        int256[] discountFeeBps;
        uint256[] surgeEpochs;
        uint256 deadline;
    }

    struct SwapTokensV3Params {
        uint256[] playerTokenIdsIn;
        uint256[] playerTokenAmountsIn;
        uint256[] playerTokenIdsOut;
        uint256[] playerTokenAmountsOut;
        uint256[] sellFeeRateBps;
        int256[] sellDiscountFeeBps;
        uint256[] buyFeeRateBps;
        int256[] buyDiscountFeeBps;
        uint256[] surgeEpochsIn;
        uint256 deadline;
        address recipient;
        bytes signature;
        uint256 nonce;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get the expected output amounts and fees for a token swap operation
     * @dev Simulates the swap operation without executing it
     * @param _playerTokenIdsIn Array of player token IDs to sell
     * @param _playerTokenAmountsIn Array of amounts to sell
     * @param _playerTokenIdsOut Array of player token IDs to buy
     * @return amountsToReceive Array of output token amounts that will be received
     * @return feeAmounts Array of fee amounts (only applied on sell operation)
     * @return feeRates Array of fee rates (only applied on sell operation)
     * @return feeTypes Array of fee types (only applied on sell operation)
     */
    function getSwapPrice(
        uint256[] memory _playerTokenIdsIn,
        uint256[] memory _playerTokenAmountsIn,
        uint256[] memory _playerTokenIdsOut
    ) external view returns (uint256[] memory amountsToReceive, uint256[] memory feeAmounts, uint256[] memory feeRates, uint8[] memory feeTypes);

    /**
     * @notice Get buy quotes using caller-supplied fee rates and discounts (read-only math helper).
     * @param _playerTokenIds Array of player ids to quote.
     * @param _playerTokenAmountsToBuy Token amounts to buy (set _currencyAmountsToSpend empty).
     * @param _currencyAmountsToSpend Currency amounts to spend (set _playerTokenAmountsToBuy empty).
     * @param _feeRateBps Base fee rates per player id.
     * @param _discountFeeBps Per-user fee adjustments per player id (negative = discount, positive = surcharge).
     */
    function getBuyPrice(
        uint256[] calldata _playerTokenIds,
        uint256[] calldata _playerTokenAmountsToBuy,
        uint256[] calldata _currencyAmountsToSpend,
        uint256[] calldata _feeRateBps,
        int256[] calldata _discountFeeBps
    ) external view returns (uint256[] memory amountsToReceive, uint256[] memory feeAmounts, uint256[] memory feeRates, uint8[] memory feeTypes);

    /**
     * @notice Get sell quotes using caller-supplied fee rates and discounts (read-only math helper).
     * @param _playerTokenIds Array of player ids to quote.
     * @param _playerTokenAmountsToSell Token amounts to sell.
     * @param _feeRateBps Base fee rates per player id.
     * @param _discountFeeBps Per-user fee adjustments per player id (negative = discount, positive = surcharge).
     */
    function getSellPrice(
        uint256[] memory _playerTokenIds,
        uint256[] memory _playerTokenAmountsToSell,
        uint256[] memory _feeRateBps,
        int256[] memory _discountFeeBps
    ) external view returns (uint256[] memory amountsToReceive, uint256[] memory feeAmounts, uint256[] memory feeRates, uint8[] memory feeTypes);

    /**
     * @notice Get swap quotes using caller-supplied sell and buy fee rates with discounts (read-only math helper).
     * @param _playerTokenIdsIn Input player ids.
     * @param _playerTokenAmountsIn Input token amounts.
     * @param _playerTokenIdsOut Output player ids.
     * @param _sellFeeRateBps Sell-side base fee rates.
     * @param _sellDiscountFeeBps Sell-side per-user fee adjustments.
     * @param _buyFeeRateBps Buy-side base fee rates.
     * @param _buyDiscountFeeBps Buy-side per-user fee adjustments.
     */
    function getSwapPrice(
        uint256[] memory _playerTokenIdsIn,
        uint256[] memory _playerTokenAmountsIn,
        uint256[] memory _playerTokenIdsOut,
        uint256[] memory _sellFeeRateBps,
        int256[] memory _sellDiscountFeeBps,
        uint256[] memory _buyFeeRateBps,
        int256[] memory _buyDiscountFeeBps
    ) external view returns (uint256[] memory amountsToReceive, uint256[] memory feeAmounts, uint256[] memory feeRates, uint8[] memory feeTypes);

    function buyTokens(
        uint256[] memory _playerTokenIds,
        uint256[] memory _playerTokenAmountsToBuy,
        uint256 _maxCurrencySpend,
        uint256[] memory _feeRateBps,
        int256[] memory _discountFeeBps,
        uint256 _deadline,
        address _recipient,
        bytes calldata _signature,
        uint256 _nonce
    ) external returns (uint256[] memory);

    function surgeEpochByPlayerId(uint256 playerId) external view returns (uint256);

    function lastFeeRateByPlayerId(uint256 playerId) external view returns (uint256);

    // ═══════════════════════════════════════════════════════════════════════════════════
    // GOVERNOR SETTERS (FEE GUARDRAILS)
    // ═══════════════════════════════════════════════════════════════════════════════════

    function setFeeGuardrails(FeeGuardrails calldata _guardrails) external;

    function getFeeGuardrails() external view returns (FeeGuardrails memory);
}
