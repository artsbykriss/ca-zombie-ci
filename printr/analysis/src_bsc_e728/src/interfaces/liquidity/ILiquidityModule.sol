// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintr } from "../IPrintr.sol";
import { ITreasury } from "../ITreasury.sol";

/**
 * @title Liquidity Module Interface
 * @notice Interface for managing AMM liquidity pools and swap operations
 * @dev Defines core functionality for pool creation, liquidity deployment, and token swaps
 */
interface ILiquidityModule {

    error InvalidTokenPair();
    error InvalidFeeTier();
    error InvalidQuoteResult();
    error QuoterRequired();
    error SignatureTooShort();
    error InsufficientOutputAmount();
    error PoolDoesNotExist();
    error Log2InvalidInput();
    error Exp2Overflow();

    /**
     * @notice Enumeration of supported liquidity module types
     * @dev Used to identify which DEX protocol implementation to use
     */
    enum ModuleType {
        UNISWAP_V3, // 0: Standard Uniswap V3 compatible DEX
        PANCAKE, // 1: PancakeSwap V3 compatible DEX
        FLUXION_WITH_DUAL_LEGACY // 2: Fluxion V3 with dual legacy router support (Uniswap + Oku.trade for Mantle)
    }

    /**
     * @notice Configuration for GoPlus locker integration
     * @param signature Signature for verifying custom fee structures
     * @param feeName Name of the fee structure to use
     * @param lpFee Fee for LP operations
     * @param collectFee Fee for collection operations (in basis points)
     */
    struct GoPlusConfig {
        bytes signature;
        string feeName;
        uint256 lpFee;
        uint256 collectFee;
    }

    /**
     * @notice Parameters for executing a token swap
     * @param tokenIn Address of token being sold
     * @param tokenOut Address of token being bought
     * @param amountIn Amount of input token to swap
     * @param amountOutMinimum Minimum amount of output token to receive
     * @param sqrtPriceLimitX96 Price limit for the swap in Q64.96 format
     * @param recipient Address to receive the output tokens
     */
    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        address recipient;
    }

    /**
     * @notice Parameters for deploying liquidity to an AMM pool
     * @param curve Bonding curve parameters defining the pool
     * @param token Address of the token for liquidity provision
     * @param issuedSupply Current issued supply of the token from the bonding curve
     * @param treasury Treasury contract managing the assets
     */
    struct LiquidityDeployParams {
        IPrintr.Curve curve;
        address token;
        uint256 issuedSupply;
        ITreasury treasury;
    }

    /**
     * @notice Results from liquidity deployment
     * @param lockId0 ID of the first locked liquidity position
     * @param lockId1 ID of the second locked liquidity position
     * @param feeCollected Amount of fees collected during deployment
     */
    struct DeployResult {
        uint256 lockId0;
        uint256 lockId1;
        uint256 feeCollected;
    }

    /**
     * @notice Creates a new AMM pool for a token pair
     * @dev Initializes pool with specified price if it doesn't exist
     * @param curve Bonding curve parameters for the pool
     * @param tokenAddress Address of the token to pair with curve.basePair
     * @param completionPrice Initial price for pool initialization
     * @return poolAddress Address of the created or existing pool
     */
    function createPool(
        IPrintr.Curve memory curve,
        address tokenAddress,
        uint256 completionPrice
    ) external payable returns (address poolAddress);

    /**
     * @notice Executes a token swap through the AMM
     * @dev Handles both ERC20 and wrapped native token swaps
     * @param params Swap parameters including tokens and amounts
     * @return amountOut Amount of output tokens received from the swap
     */
    function executeSwap(
        SwapParams memory params
    ) external payable returns (uint256 amountOut);

    /**
     * @notice Deploys liquidity to AMM pools according to curve parameters
     * @dev Creates and locks liquidity positions in the AMM
     * @param params Parameters for liquidity deployment
     * @return result Structure containing lock IDs and fee information
     */
    function deployLiquidity(
        LiquidityDeployParams memory params
    ) external payable returns (DeployResult memory result);

    /**
     * @notice Gets a quote for exact input swap without execution
     * @dev Returns the expected output amount for a given input
     * @param params Swap parameters with exact input amount
     * @return amountOut Expected output amount
     * @return priceAfter The price after the swap
     * @return fee The fee tier of the pool in basis points
     */
    function quoteExactInput(
        SwapParams memory params
    ) external payable returns (uint256 amountOut, uint256 priceAfter, uint256 fee);

    /**
     * @notice Gets a quote for exact output swap without execution
     * @dev Returns the required input amount for a desired output
     *      Payable to support delegatecall from contexts with msg.value
     * @param params Swap parameters with exact output amount
     * @return amountIn Required input amount
     * @return priceAfter The price after the swap
     * @return fee The fee tier of the pool in basis points
     */
    function quoteExactOutput(
        SwapParams memory params
    ) external payable returns (uint256 amountIn, uint256 priceAfter, uint256 fee);

    /**
     * @notice Collects accumulated fees from a locked liquidity position
     * @dev Delegates to the appropriate locker contract (GoPlus, generic, etc.)
     *      Returns amounts in convention order: basePair first, token second
     * @param lockId Unique identifier of the locked LP position
     * @param token Address of the token in the trading pair
     * @param basePair Address of the base pair token
     * @param recipient Address that will receive the collected trading fees
     * @return baseAmount Amount of basePair token collected
     * @return tokenAmount Amount of token collected
     */
    function collectLiquidityFees(
        uint256 lockId,
        address token,
        address basePair,
        address recipient
    ) external returns (uint256 baseAmount, uint256 tokenAmount);

}
