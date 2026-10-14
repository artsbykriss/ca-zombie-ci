// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ITreasury } from "../ITreasury.sol";

/**
 * @title Printr Storage Interface
 * @notice Interface for the Printr contract, which manages tokens with linear bonding curves
 * @dev All price calculations use PRECISION_SCALAR (1e18) for accurate floating point math
 *      Implements cross-chain token deployment through ITelecoinFactory integration
 *      This interface defines the core storage and view functions for the Printr system
 */
interface IPrintrStorage {

    /// @notice Custom errors for the Printr contract
    error FeeIsTooHigh(uint256 fee);
    error InvalidProtocolTelecoinShare();
    error WrongChainName();
    error InsufficientPayment();
    error InsufficientInitialBuy();
    error InvalidBasePairDecimals();
    error InvalidBasePrices();
    error InvalidBasePairs();
    error InvalidCreatorAddress();
    error InvalidInitialPrice();
    error InvalidLength();
    error TooHighThreshold();
    error ZeroAmount();
    error PoolCreationFailed();
    error TokenNotFound();
    error SwapFailed();
    error LiquidityAlreadyDeployed();
    error LiquidityDeploymentFailed();
    error InvalidQuoteResult();
    error PriceExceedsLimit();
    error RefundFailed();
    error RenounceOwnershipDisabled();
    error InvalidImplementation();
    error FeePercentagesMustSum();
    error UnauthorizedCaller();
    error Create3AddressMismatch();

    /**
     * @notice Parameters structure for telecoin deployment
     * @dev Uses bytes32 for efficient storage and cross-chain compatibility
     * @param salt Unique identifier for deployment
     * @param creatorAddresses Creator addresses for different chains encoded as bytes
     * @param name Telecoin name encoded as bytes32, 31 characters max
     * @param symbol Telecoin symbol encoded as bytes32, 31 characters max
     * @param packedParams Packed parameters bit layout:
     *                     [0-7]     uint8   maxTokenSupplyE (power of 10)
     *                     [8-23]    uint16  completionThreshold (basis points, max 10000)
     *                     [24-135]  uint112 initialPrice, assuming 18 decimal places for both tokens
     *                     [136-255] uint120 initialBuySpending, assuming 18 decimal places
     * @param chains Chain names encoded as bytes32, first chain is the home chain
     * @param basePairs Base currency token addresses encoded as bytes32
     * @param basePrices Initial prices in base currency per chain as uint128 packed in bytes, 18 decimals for both
     */
    struct TelecoinParams {
        bytes32 salt;
        bytes creatorAddresses;
        bytes32 name;
        bytes32 symbol;
        bytes32 packedParams;
        bytes32[] chains;
        bytes32[] basePairs;
        bytes basePrices;
    }

    /**
     * @notice Unpacked version of the packedParams for easier handling
     * @dev Packed bytes32 converted into individual parameters
     * @param maxTokenSupplyE Maximum token supply as power of 10
     * @param completionThreshold Completion threshold in basis points (max 10000) of max supply
     * @param initialPrice Initial token price, assuming 18 decimal places for both tokens
     * @param initialBuySpending Initial buy amount, assuming 18 decimal places
     */
    struct UnpackedParams {
        uint8 maxTokenSupplyE;
        uint256 completionThreshold;
        uint256 initialPrice;
        uint256 initialBuySpending;
    }

    /**
     * @notice Comprehensive information about a token's configuration and state
     * @dev Whole struct is packed into 2 storage slots for efficiency
     * @param basePair Address of the base currency token (160 bits)
     * @param totalCurves Number of curves across all chains (16 bits)
     * @param maxTokenSupplyE Maximum token supply as pow of 10 (8 bits)
     * @param virtualReserveE Precision scalar for virtualReserve (8 bits)
     * @param virtualReserve Compressed virtual reserve balance for bonding curve (64 bits)
     * @param reserve Current reserve balance of the base currency token (192 bits)
     * @param completionThreshold Threshold for curve completion as percentage of total supply (64 bits)
     */
    struct Curve {
        /// @dev Slot 1: immutable (160 + 16 + 8 + 8 + 64 = 256 bits, fits in 1 slot)
        address basePair;
        uint16 totalCurves;
        uint8 maxTokenSupplyE;
        uint8 virtualReserveE;
        uint64 virtualReserve;
        /// @dev Slot 2: mutable (192 + 64 = 256 bits)
        uint192 reserve;
        uint64 completionThreshold;
    }

    /**
     * @notice Readable format of curve information
     * @param basePair Base currency token address
     * @param totalCurves Total number of curves across chains
     * @param maxTokenSupply Maximum token supply
     * @param virtualReserve Virtual reserve for curve calculations (already scaled with virtualReserveE)
     * @param reserve Current base currency reserve
     * @param completionThreshold Completion threshold value
     */
    struct CurveInfo {
        address basePair;
        uint16 totalCurves;
        uint256 maxTokenSupply;
        uint256 virtualReserve;
        uint256 reserve;
        uint256 completionThreshold;
    }

    /**
     * @notice Parameters for deploying Printr contracts
     * @dev Used to avoid stack too deep errors in constructor
     * @param chainName Name of the blockchain network
     * @param treasury Address of the treasury contract
     * @param legacyTreasury Address of the legacy treasury contract (for migration)
     * @param mainTelecoinFactory Address of the main token factory contract
     * @param teleportingTelecoinFactory Address of the teleporting token factory contract
     * @param wrappedNativeToken Address of wrapped native token (e.g., WETH)
     * @param locker Address of the locker contract
     * @param liquidityModule Address of the liquidity module
     * @param create3Deployer Address of the CREATE3 deployer for deterministic LZChannel deployments
     * @param growthFundFund Address of the growth fund
     * @param buybackFund Address of the buyback
     * @param teamTreasuryFund Address of the team treasury
     * @param stakingFund Address of the staking
     * @param printrDev Address of the dev NFT contract
     * @param legacyPrintrDev Address of the first legacy dev NFT contract (for migration from V1 - oldest original)
     * @param legacyPrintrDev2 Address of the second legacy dev NFT contract (for migration from V2 - without base64
     * fix)
     * @param feePercentGrowth Fee percentage for growth fund in basis points
     * @param feePercentBuyback Fee percentage for buyback in basis points
     * @param feePercentTeam Fee percentage for team treasury in basis points
     * @param feePercentCreator Fee percentage for creator in basis points
     * @param protocolTelecoinShareBps Protocol share of V2 telecoin trading fees in basis points (0-10000)
     * @param tradingFee Trading fee percentage in basis points
     */
    struct DeploymentParams {
        string chainName;
        address treasury;
        address legacyTreasury;
        address mainTelecoinFactory;
        address teleportingTelecoinFactory;
        address wrappedNativeToken;
        address locker;
        address liquidityModule;
        address create3Deployer;
        address growthFund;
        address buybackFund;
        address teamTreasuryFund;
        address stakingFund;
        address stakingContract;
        address printrDev;
        address legacyPrintrDev;
        address legacyPrintrDev2;
        uint256 feePercentGrowth;
        uint256 feePercentBuyback;
        uint256 feePercentTeam;
        uint256 feePercentCreator;
        uint256 protocolTelecoinShareBps;
        uint16 tradingFee;
    }

    /// @notice Returns the current chain's hash identifier
    function currentChainHash() external view returns (bytes32);

    /// @notice Returns the treasury contract address
    function treasury() external view returns (ITreasury);

    /// @notice Returns the main token factory contract address
    function mainTelecoinFactory() external view returns (address);

    /// @notice Returns the teleporting token factory contract address
    function teleportingTelecoinFactory() external view returns (address);

    /// @notice Returns the wrapped native token address
    function wrappedNativeToken() external view returns (address);

    /// @notice Returns the liquidity module contract address
    function liquidityModule() external view returns (address);

    /// @notice Returns the locker contract address
    function locker() external view returns (address);

    /// @notice Returns the CREATE3 deployer address
    function create3Deployer() external view returns (address);

    /// @notice Returns the growth fund address
    function growthFund() external view returns (address);

    /// @notice Returns the buyback address
    function buybackFund() external view returns (address);

    /// @notice Returns the team treasury address
    function teamTreasuryFund() external view returns (address);

    /// @notice Returns the staking address
    function stakingFund() external view returns (address);

    /// @notice Returns the staking contract address
    function stakingContract() external view returns (address);

    /// @notice Returns the creator NFT contract address
    function printrDev() external view returns (address);

    /// @notice Returns the fee percentage for growth fund
    function feePercentGrowth() external view returns (uint256);

    /// @notice Returns the fee percentage for buyback
    function feePercentBuyback() external view returns (uint256);

    /// @notice Returns the fee percentage for team treasury
    function feePercentTeam() external view returns (uint256);

    /// @notice Returns the fee percentage for creator
    function feePercentCreator() external view returns (uint256);

    /// @notice Returns the protocol share of V2 telecoin trading fees in basis points
    function protocolTelecoinShareBps() external view returns (uint256);

    /// @notice Returns the trading fee percentage in basis points
    function tradingFee() external view returns (uint16);

}
