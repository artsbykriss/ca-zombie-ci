// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ILiquidityModule } from "../interfaces/liquidity/ILiquidityModule.sol";
import { IPrintrPrinting } from "../interfaces/printr/IPrintrPrinting.sol";
import { IPrintrTrading } from "../interfaces/printr/IPrintrTrading.sol";
import { IPrintrStaking } from "../interfaces/staking/IPrintrStaking.sol";
import { IPrintrDev } from "../interfaces/telecoin/IPrintrDev.sol";

import { IPrintrTeleportingTelecoin } from "../interfaces/telecoin/IPrintrTeleportingTelecoin.sol";
import { ITelecoin } from "../interfaces/telecoin/ITelecoin.sol";
import { ITelecoinFactory } from "../interfaces/telecoin/ITelecoinFactory.sol";

import { AddressBytes32 } from "../libs/AddressBytes32.sol";
import { Bytes32ToString } from "../libs/Bytes32String.sol";

import { PrintrStorage } from "./PrintrStorage.sol";

/**
 * @title Printr Printing
 * @notice Implementation of token printing and curve management functionality
 * @dev Implements UUPS proxy pattern with namespaced storage for upgradeability
 *      Uses ERC7201 for structured storage layout
 *      All price calculations use PRECISION (1e18) for accurate floating point math
 *      Supports multi-chain token deployment through token factory integration
 */
abstract contract PrintrPrinting is IPrintrPrinting, PrintrStorage {

    using Bytes32ToString for bytes32;
    using AddressBytes32 for bytes32;

    bytes1 public constant EVM_ADDRESS_PREFIX = 0x0;
    bytes1 public constant EVM_STAKING_MODE_PREFIX = 0x03;

    // Struct to hold local variables and avoid stack too deep error
    struct PrintingData {
        bytes32 telecoinId;
        uint256 chainIndex;
        address creatorAddress;
        bool stakingEnabled;
        uint256 completionPrice;
    }

    /**
     * @notice Prints a new token with a bonding curve across multiple chains
     * @dev Deploys token with bonding curve on the current chain and initiates remote deployments
     *      Sets up liquidity pool and performs initial token purchase
     * @param initialSpending Initial amount of base currency to commit. Pass type(uint256).max to use
     *                        the maximum available amount (all approved tokens or all sent ETH)
     * @param telecoinParams Parameters for the token curve deployment
     * @return tokenAddress Address of the newly created token
     * @return telecoinId Unique identifier for cross-chain deployment
     */
    function print(
        uint256 initialSpending,
        TelecoinParams calldata telecoinParams
    ) external payable whenNotPaused returns (address tokenAddress, bytes32 telecoinId) {
        Storage storage $ = _storage();
        PrintingData memory tokenData;

        tokenData.telecoinId = _getTelecoinId(telecoinParams);
        tokenData.chainIndex = _getCurrentChainIndex(telecoinParams.chains);
        (tokenData.creatorAddress, tokenData.stakingEnabled) = _parseCreatorAddresses(telecoinParams.creatorAddresses);
        UnpackedParams memory unpacked = _unpackParams(telecoinParams.packedParams);

        // Validate parameter lengths
        if (telecoinParams.chains.length != telecoinParams.basePairs.length) {
            revert InvalidLength();
        }
        if (telecoinParams.chains.length != telecoinParams.basePrices.length / 16) {
            revert InvalidLength();
        }

        for (uint256 i; i < telecoinParams.chains.length; ++i) {
            uint256 basePrice = _getBasePriceAt(telecoinParams.basePrices, i);
            if (basePrice == 0) {
                revert InvalidBasePrices();
            }
            if (telecoinParams.basePairs[i] == bytes32(0)) {
                revert InvalidBasePairs();
            }
        }

        // Use the universal token ID
        telecoinId = tokenData.telecoinId;
        // isTeleporting is false for single chain token deployed on that chain
        tokenAddress = _deployToken(
            telecoinParams,
            tokenData.telecoinId,
            unpacked.completionThreshold == 0 ? tokenData.creatorAddress : address(treasury),
            telecoinParams.chains.length == 1 && tokenData.chainIndex == 0,
            tokenData.chainIndex != type(uint256).max
        );

        // Skip curve creation if current chain is not in the list or all supply is minted to creator
        if (tokenData.chainIndex == type(uint256).max || unpacked.completionThreshold == 0) {
            _refundNativeValue(tokenData.creatorAddress);
            return (tokenAddress, telecoinId);
        }

        Curve memory curve;
        {
            address basePair = telecoinParams.basePairs[tokenData.chainIndex].toAddress();
            uint256 basePrice = _getBasePriceAt(telecoinParams.basePrices, tokenData.chainIndex);
            uint256 maxSupply = 10 ** unpacked.maxTokenSupplyE * PRECISION;

            // Validate parameters
            if (unpacked.initialPrice == 0) {
                revert InvalidInitialPrice();
            }
            if (unpacked.completionThreshold >= BIPS_SCALAR) {
                revert TooHighThreshold();
            }
            try IERC20(basePair).balanceOf(address(treasury)) returns (uint256) { }
            catch {
                revert InvalidBasePairs();
            }

            // Calculate curve parameters
            unpacked.completionThreshold =
                unpacked.completionThreshold * PRECISION / BIPS_SCALAR / telecoinParams.chains.length;
            unpacked.initialPrice = PRECISION * unpacked.initialPrice / basePrice;

            {
                // Calculate required initial spending adjusted for chain-specific base price
                uint256 convertedInitialSpending =
                    PRECISION * unpacked.initialBuySpending / basePrice / telecoinParams.chains.length;

                try IERC20Metadata(basePair).decimals() returns (uint8 decimals) {
                    if (decimals < 18) {
                        convertedInitialSpending = convertedInitialSpending / 10 ** (18 - decimals);
                        unpacked.initialPrice = unpacked.initialPrice / 10 ** (18 - decimals);
                    }
                    if (decimals > 18) {
                        convertedInitialSpending = convertedInitialSpending * 10 ** (decimals - 18);
                        unpacked.initialPrice = unpacked.initialPrice * 10 ** (decimals - 18);
                    }
                } catch {
                    revert InvalidBasePairDecimals();
                }

                // Handle max amount for initial spending
                if (initialSpending == type(uint256).max) {
                    initialSpending = _getMaxAmount(basePair, msg.sender);
                }

                if (initialSpending < convertedInitialSpending) {
                    revert InsufficientInitialBuy();
                }
            }

            {
                uint256 initialTokenReserve = maxSupply / telecoinParams.chains.length;
                uint256 virtualReserve = initialTokenReserve * unpacked.initialPrice / PRECISION;
                uint256 completionTokenReserve =
                    initialTokenReserve - maxSupply * unpacked.completionThreshold / PRECISION;
                // Early division prevents overflow with small base prices
                tokenData.completionPrice = (PRECISION * virtualReserve / completionTokenReserve) * initialTokenReserve
                    / completionTokenReserve;

                // Initialize bonding curve parameters
                curve = Curve({
                    basePair: basePair,
                    totalCurves: uint16(telecoinParams.chains.length),
                    maxTokenSupplyE: unpacked.maxTokenSupplyE,
                    virtualReserveE: 0,
                    virtualReserve: 0,
                    reserve: 0,
                    completionThreshold: uint64(unpacked.completionThreshold)
                });

                // Compress virtualReserve if it exceeds uint64.max
                while (virtualReserve > type(uint64).max) {
                    virtualReserve /= 10;
                    curve.virtualReserveE++;
                }
                curve.virtualReserve = uint64(virtualReserve);
            }

            emit CurveCreated(tokenData.creatorAddress, tokenAddress, telecoinId);
            emit IPrintrTrading.TokenTrade(
                tokenAddress, tokenData.creatorAddress, true, 0, 0, unpacked.initialPrice, 0, 0
            );
        }

        // Mint Dev NFT to the creator
        IPrintrDev(printrDev).mint(telecoinId, tokenData.creatorAddress);

        // Enable staking for V2 telecoins
        if (tokenData.stakingEnabled && stakingContract != address(0)) {
            IPrintrStaking(stakingContract).enableStaking(tokenAddress, curve.basePair);
        }

        // Store curve configuration
        $.curves[tokenAddress] = curve;

        // Create and configure liquidity pool
        {
            (bool success, bytes memory data) = liquidityModule.delegatecall(
                abi.encodeWithSelector(
                    ILiquidityModule.createPool.selector, curve, tokenAddress, tokenData.completionPrice
                )
            );
            if (!success) {
                // Bubble up the actual liquidity module error
                if (data.length == 0) {
                    revert PoolCreationFailed();
                }
                assembly {
                    revert(add(data, 0x20), mload(data))
                }
            }
            address pool = abi.decode(data, (address));
            IPrintrTeleportingTelecoin(tokenAddress).setRestrictedPool(pool);
        }

        // Perform initial token purchase if specified
        if (initialSpending != 0) {
            uint256 tokenAmount = _quoteTokenAmount(curve, initialSpending, tradingFee);
            _buy(
                curve,
                IPrintrTrading.TradeParams(
                    msg.sender, tokenData.creatorAddress, tokenAddress, tokenAmount, 0, tradingFee
                )
            );
        }

        _refundNativeValue(tokenData.creatorAddress);
    }

    /**
     * @dev Deploys a new token contract via the TelecoinFactory
     * @param telecoinParams TelecoinParams struct containing deployment configuration
     * @param telecoinId Unique identifier for deterministic deployment address calculation
     * @param isMainTelecoin Boolean indicating whether token is main telecoin (true) or teleporting telecoin (false)
     * @return tokenAddress Address of the newly deployed token contract
     */
    function _deployToken(
        TelecoinParams calldata telecoinParams,
        bytes32 telecoinId,
        address mintTo,
        bool isMainTelecoin,
        bool hasLocalSupply
    ) internal returns (address tokenAddress) {
        UnpackedParams memory unpacked = _unpackParams(telecoinParams.packedParams);

        // Build token deployment params
        ITelecoin.TelecoinDeployParams memory deployParams = ITelecoin.TelecoinDeployParams({
            telecoinId: telecoinId,
            name: telecoinParams.name.toTrimmedString(),
            symbol: telecoinParams.symbol.toTrimmedString(),
            maxSupply: 10 ** unpacked.maxTokenSupplyE * PRECISION,
            printr: address(this)
        });

        address factory = isMainTelecoin ? mainTelecoinFactory : teleportingTelecoinFactory;
        uint256 initialSupply =
            hasLocalSupply ? 10 ** unpacked.maxTokenSupplyE * PRECISION / telecoinParams.chains.length : 0;

        (bool success, bytes memory data) = factory.delegatecall(
            abi.encodeWithSelector(
                ITelecoinFactory.deployToken.selector,
                deployParams,
                mintTo,
                initialSupply // initialSupply
            )
        );

        if (!success) {
            assembly {
                revert(add(data, 32), data)
            }
        }

        tokenAddress = abi.decode(data, (address));

        // Emit with universal telecoinId
        emit TelecoinPrinted(tokenAddress, telecoinId);
    }

    /**
     * @dev Returns the index of the current chain in the provided chains array
     * @param chains Array of chain names to search through
     * @return index Index of the current chain in the array, or max uint256 if not found
     */
    function _getCurrentChainIndex(
        bytes32[] memory chains
    ) internal view returns (uint256 index) {
        if (chains.length == 0) {
            revert InvalidLength();
        }

        for (uint256 i; i < chains.length; ++i) {
            if (keccak256(bytes(chains[i].toTrimmedString())) == currentChainHash) {
                return i;
            }
        }

        return type(uint256).max;
    }

    /**
     * @dev Parses encoded creator addresses to extract EVM address and staking flag
     * @param creatorAddresses Encoded creator addresses bytes with discriminator prefixes
     * @return creatorAddress The extracted EVM address of the token creator
     * @return stakingEnabled Whether this telecoin has staking enabled (discriminator 0x03)
     */
    function _parseCreatorAddresses(
        bytes calldata creatorAddresses
    ) internal pure returns (address creatorAddress, bool stakingEnabled) {
        // Legacy: bare 20-byte EVM address (no discriminator)
        if (creatorAddresses.length == 20) {
            return (address(bytes20(creatorAddresses)), false);
        }

        uint256 offset = 0;
        bool found = false;

        while (offset < creatorAddresses.length) {
            bytes1 discriminator = creatorAddresses[offset];

            if (discriminator == EVM_ADDRESS_PREFIX) {
                if (offset + 21 > creatorAddresses.length) {
                    revert InvalidCreatorAddress();
                }
                creatorAddress = address(bytes20(creatorAddresses[offset + 1:offset + 21]));
                stakingEnabled = false;
                found = true;
                offset += 21; // 1 discriminator + 20 address bytes
            } else if (discriminator == EVM_STAKING_MODE_PREFIX) {
                if (offset + 21 > creatorAddresses.length) {
                    revert InvalidCreatorAddress();
                }
                creatorAddress = address(bytes20(creatorAddresses[offset + 1:offset + 21]));
                stakingEnabled = true;
                found = true;
                offset += 21;
            } else if (discriminator == 0x01 || discriminator == 0x04) {
                if (offset + 33 > creatorAddresses.length) {
                    revert InvalidCreatorAddress();
                }
                offset += 33; // 1 discriminator + 32 Solana address bytes
            } else if (discriminator == 0x02) {
                if (offset + 33 > creatorAddresses.length) {
                    revert InvalidCreatorAddress();
                }
                offset += 33; // 1 discriminator + 32 Sui address bytes
            } else if (uint8(discriminator) >= 0x05 && uint8(discriminator) <= 0x09) {
                if (offset + 3 > creatorAddresses.length) {
                    revert InvalidCreatorAddress();
                }
                offset += 3; // 1 discriminator + 2 value bytes (BPS)
            } else {
                revert InvalidCreatorAddress();
            }
        }

        if (!found) {
            revert InvalidCreatorAddress();
        }
    }

    /**
     * @dev Retrieves the base price for a specific chain
     * @param basePrices Encoded base prices for all chains
     * @param index Index of the chain to retrieve the price for
     * @return basePrice Base price for the specified chain
     */
    function _getBasePriceAt(
        bytes calldata basePrices,
        uint256 index
    ) internal pure returns (uint256) {
        return uint128(bytes16(basePrices[index * 16:(index + 1) * 16]));
    }

}
