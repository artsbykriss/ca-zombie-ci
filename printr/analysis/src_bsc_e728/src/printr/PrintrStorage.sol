// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ITreasury } from "../interfaces/ITreasury.sol";
import { IPrintrStorage } from "../interfaces/printr/IPrintrStorage.sol";
import { IPrintrTrading } from "../interfaces/printr/IPrintrTrading.sol";
import { IPrintrTeleportingTelecoin } from "../interfaces/telecoin/IPrintrTeleportingTelecoin.sol";
import { ITelecoinFactory } from "../interfaces/telecoin/ITelecoinFactory.sol";

import { Bytes32ToString } from "../libs/Bytes32String.sol";

/**
 * @title PrintrStorage Base Contract
 * @notice Base storage contract for creating and managing tokens with linear bonding curves
 * @dev Implements upgradeable pattern with ERC7201 namespaced storage for state isolation
 *      Provides immutable configuration and shared constants for all Printr contracts
 */
abstract contract PrintrStorage is IPrintrStorage, PausableUpgradeable {

    using Bytes32ToString for bytes32;

    /// @notice Scalar used for price calculations to handle decimals
    /// @dev Set to 1e18 to maintain precision in calculations
    uint256 public constant PRECISION = 10 ** 18;

    /// @notice Scalar for fee calculations (100% = 10000)
    uint256 public constant BIPS_SCALAR = 10_000;

    /// @notice Scalar for Uniswap V3 fee tiers (100% = 1_000_000; 3000 = 0.30%, 10000 = 1.00%)
    /// @dev Used when converting an AMM-returned fee tier into a monetary fee amount.
    ///      Distinct from BIPS_SCALAR because Uniswap V3 fee tiers use 1/1_000_000 units.
    uint256 public constant UNISWAP_FEE_SCALAR = 1_000_000;

    /**
     * @notice Main storage structure for the Printr contract
     * @custom:storage-location erc7201:printr.storage.PrintrStorage
     */
    struct Storage {
        /// @notice Mapping of token addresses to their configuration and state
        mapping(address => Curve) curves;
        /// @notice Mapping of base pair addresses to their collected protocol fees
        mapping(address => uint256) collectedFees;
        /// @notice Mapping of token addresses to their liquidity lock parameters
        mapping(address => uint256[2]) liquidityLocks;
        /// @notice Bitmap of globally enabled teleport protocols (bit position = TeleportProtocol enum value)
        bytes32 teleportProtocolWhitelist;
        /// @notice Mapping from telecoin ID to bitmap of disabled protocols (blacklist)
        mapping(bytes32 => bytes32) telecoinProtocolBlacklist;
    }

    /// @dev ERC7201 storage location for Storage
    /// @dev keccak256(abi.encode(uint256(keccak256("printr.storage.PrintrStorage")) - 1)) &
    /// ~bytes32(uint256(0xff))
    bytes32 private constant PRINTR_STORAGE_LOCATION =
        0x4115e7e53fb5d2198d5cadf1cb530b9c70f06c4e1b4565d7cc7245d4040dcb00;

    /**
     * @dev Retrieves pointer to the contract's storage location
     * @return $ Storage pointer to PrintrStorage
     */
    function _storage() internal pure returns (Storage storage $) {
        assembly {
            $.slot := PRINTR_STORAGE_LOCATION
        }
    }

    /// @notice Hash of the current chain's name, used for cross-chain deployment routing
    bytes32 public immutable currentChainHash;

    /// @notice Trading fee percentage in basis points (BIPs)
    uint16 public immutable tradingFee;
    /// @notice Treasury contract that holds all tokens
    ITreasury public immutable treasury;
    /// @notice Legacy treasury contract for migration (address(0) if no migration needed)
    ITreasury public immutable legacyTreasury;

    /// @notice Address of the main token factory contract (for lock/unlock tokens)
    address public immutable mainTelecoinFactory;
    /// @notice Address of the teleporting token factory contract (for mint/burn tokens)
    address public immutable teleportingTelecoinFactory;
    /// @notice Address of the wrapped native token contract
    address public immutable wrappedNativeToken;
    /// @notice Dev NFT contract
    address public immutable printrDev;
    /// @notice First legacy dev NFT contract for migration from V1 - oldest original (address(0) if no migration
    /// needed)
    address public immutable legacyPrintrDev;
    /// @notice Second legacy dev NFT contract for migration from V2 - without base64 fix (address(0) if no migration
    /// needed)
    address public immutable legacyPrintrDev2;
    /// @notice Address of the liquidity module contract
    address public immutable liquidityModule;
    /// @notice Address of the locker contract
    address public immutable locker;
    /// @notice Address of the CREATE3 deployer used for deterministic LZChannel deployments
    address public immutable create3Deployer;

    // Fee distribution addresses and configuration
    /// @notice Memecoin Growth Fund address
    address public immutable growthFund;
    /// @notice $PRINT Buyback address
    address public immutable buybackFund;
    /// @notice Team Treasury address
    address public immutable teamTreasuryFund;
    /// @notice Staking address for token LP fees
    address public immutable stakingFund;
    /// @notice PrintrStaking contract address
    address public immutable stakingContract;

    // Fee distribution percentages (immutable for gas efficiency)
    /// @notice Fee percentage for growth fund in basis points (BIPs)
    uint256 public immutable feePercentGrowth;
    /// @notice Fee percentage for buyback in basis points (BIPs)
    uint256 public immutable feePercentBuyback;
    /// @notice Fee percentage for team treasury in basis points (BIPs)
    uint256 public immutable feePercentTeam;
    /// @notice Fee percentage for creator in basis points (BIPs)
    uint256 public immutable feePercentCreator;
    /// @notice Protocol share of V2 telecoin trading fees in basis points (0-10000)
    uint256 public immutable protocolTelecoinShareBps;

    /**
     * @dev Constructor that sets up all immutable addresses and configuration values
     * @param params DeploymentParams struct containing:
     *        - chainName: Name of the current blockchain
     *        - treasury: Treasury contract address
     *        - tokenFactory: TelecoinFactory contract address
     *        - its: Interchain Token Service address
     *        - liquidityModule: Module for DEX interactions
     *        - Fee distribution addresses and percentages
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(
        DeploymentParams memory params
    ) {
        _disableInitializers();

        currentChainHash = keccak256(bytes(params.chainName));
        treasury = ITreasury(params.treasury);
        legacyTreasury = ITreasury(params.legacyTreasury);
        mainTelecoinFactory = params.mainTelecoinFactory;
        teleportingTelecoinFactory = params.teleportingTelecoinFactory;
        wrappedNativeToken = params.wrappedNativeToken;
        locker = params.locker;
        liquidityModule = params.liquidityModule;
        create3Deployer = params.create3Deployer;
        growthFund = params.growthFund;
        buybackFund = params.buybackFund;
        teamTreasuryFund = params.teamTreasuryFund;
        stakingFund = params.stakingFund;
        stakingContract = params.stakingContract;
        printrDev = params.printrDev;
        legacyPrintrDev = params.legacyPrintrDev;
        legacyPrintrDev2 = params.legacyPrintrDev2;
        tradingFee = params.tradingFee;

        // Validate trading fee
        if (params.tradingFee > BIPS_SCALAR / 100) {
            revert FeeIsTooHigh(params.tradingFee);
        }

        // Set fee percentages
        feePercentGrowth = params.feePercentGrowth;
        feePercentBuyback = params.feePercentBuyback;
        feePercentTeam = params.feePercentTeam;
        feePercentCreator = params.feePercentCreator;

        // Ensure fee percentages add up to 10000 basis points (100%)
        if (feePercentGrowth + feePercentBuyback + feePercentTeam + feePercentCreator != BIPS_SCALAR) {
            revert FeePercentagesMustSum();
        }

        // Validate and set protocol telecoin share (independent of base-pair 4-way split)
        if (params.protocolTelecoinShareBps > BIPS_SCALAR) {
            revert InvalidProtocolTelecoinShare();
        }
        protocolTelecoinShareBps = params.protocolTelecoinShareBps;
    }

    /**
     * @notice Generates a unique identifier for a telecoin based on its parameters
     * @dev Creates a deterministic hash of the token parameters for cross-chain identification
     * @param tokenParams The TelecoinParams struct including name, symbol, pricing, and chain configurations
     * @return bytes32 The unique telecoin identifier hash
     */
    function _getTelecoinId(
        TelecoinParams calldata tokenParams
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenParams));
    }

    /**
     * @notice Computes the deployed token address for a given telecoin ID
     * @dev Both factories use CREATE3 with the same salt, so they compute the same address
     * @param telecoinId The unique telecoin identifier
     * @return tokenAddress The address where the token is deployed
     */
    function _getTokenAddress(
        bytes32 telecoinId
    ) internal view returns (address tokenAddress) {
        // Both factories use CREATE3 with the same salt, so they compute the same address
        // We can query either factory - using mainTelecoinFactory here
        tokenAddress = ITelecoinFactory(mainTelecoinFactory).tokenAddress(address(this), telecoinId);
    }

    /**
     * @notice Unpacks compressed bonding curve parameters from a bytes32 value
     * @dev Efficiently extracts multiple parameters from a single storage slot using bit shifting
     * @param packedParams The compressed parameters as a bytes32 value
     * @return unpacked The unpacked parameters struct containing:
     *         - maxTokenSupplyE: Maximum token supply exponent (8 bits)
     *         - completionThreshold: Completion threshold in basis points (16 bits)
     *         - initialPrice: Initial token price in wei (112 bits)
     *         - initialBuySpending: Initial buy spending amount in wei (120 bits)
     */
    function _unpackParams(
        bytes32 packedParams
    ) internal pure returns (UnpackedParams memory unpacked) {
        unpacked.maxTokenSupplyE = uint8(uint256(packedParams));
        unpacked.completionThreshold = uint16(uint256(packedParams) >> 8);
        unpacked.initialPrice = uint112(uint256(packedParams) >> 24);
        unpacked.initialBuySpending = uint120(uint256(packedParams) >> 136);
    }

    /**
     * @notice Refunds any remaining native value to the recipient
     * @dev Transfers any remaining ETH to the recipient
     * @param recipient Address to receive the refund
     */
    function _refundNativeValue(
        address recipient
    ) internal {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            // slither-disable-next-line arbitrary-send-eth
            (bool success,) = recipient.call{ value: balance }("");
            require(success, RefundFailed());
        }
    }

    /**
     * @notice Gets the maximum amount available for spending when amount is uint256.max
     * @dev Handles both native ETH and ERC20 tokens
     * @param token The token address to check
     * @param sender The address of the sender
     * @return The maximum amount available to spend (limited by balance and allowance)
     */
    function _getMaxAmount(
        address token,
        address sender
    ) internal view returns (uint256) {
        // If token is wrapped native and ETH was sent, use the contract's ETH balance
        if (token == wrappedNativeToken && msg.value > 0) {
            return address(this).balance;
        } else {
            uint256 balance = IERC20(token).balanceOf(sender);
            uint256 allowance = IERC20(token).allowance(sender, address(this));
            return allowance < balance ? allowance : balance;
        }
    }

    /**
     * @notice Calculates the token amount based on the bonding curve and base spend
     * @dev Must be implemented by derived contracts to handle specific curve logic
     * @param curve The bonding curve parameters
     * @param baseSpend The amount of base currency being spent
     * @param tradingFee The trading fee percentage in basis points
     * @return tokenAmount The calculated amount of tokens to be received
     */
    function _quoteTokenAmount(
        Curve memory curve,
        uint256 baseSpend,
        uint16 tradingFee
    ) internal pure virtual returns (uint256 tokenAmount);

    /**
     * @notice Executes a buy operation on the bonding curve
     * @dev Virtual function that must be implemented by derived contracts to handle token purchases
     * @param curve The bonding curve parameters and state
     * @param params The trade parameters including amounts, recipient, and cross-chain routing
     */
    function _buy(
        Curve memory curve,
        IPrintrTrading.TradeParams memory params
    ) internal virtual;

    /**
     * @notice Migrates token balance from legacy treasury to new treasury
     * @dev Automatically called before any treasury withdrawal to ensure tokens are in new treasury
     *      Only performs migration if legacy treasury exists and has non-zero balance
     *      Handles both ERC20 tokens and native/wrapped tokens
     * @param token Address of the token to migrate (address(0) for native token)
     */
    function _migrateTreasury(
        address token
    ) internal {
        // Skip migration if no legacy treasury configured
        if (address(legacyTreasury) == address(0)) {
            return;
        }

        uint256 balance = IERC20(token).balanceOf(address(legacyTreasury));

        // Only migrate if there's a non-zero balance
        if (balance > 0) {
            // Pull tokens from legacy treasury to new treasury
            legacyTreasury.withdraw(token, address(treasury), balance);
        }
    }

}
