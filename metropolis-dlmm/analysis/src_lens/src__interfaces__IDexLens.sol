// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IJoeFactory} from "joe-v2/interfaces/IJoeFactory.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2/interfaces/ILBLegacyFactory.sol";
import {ISafeAccessControlEnumerable} from "solrary/access/ISafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Swapline Dex Lens contract
/// @author Swapline, Original Author: Trader Joe
/// @notice The interface needed to interract with the Swapline Dex Lens contract
interface IDexLens is ISafeAccessControlEnumerable {
    error DexLens__UnknownDataFeedType();
    error DexLens__CollateralNotInPair(address pair, address collateral);
    error DexLens__TokenNotInPair(address pair, address token);
    error DexLens__SameTokens();
    error DexLens__DataFeedAlreadyAdded(address token, address dataFeed);
    error DexLens__DataFeedNotInSet(address token, address dataFeed);
    error DexLens__LengthsMismatch();
    error DexLens__NullWeight();
    error DexLens__InvalidChainLinkPrice();
    error DexLens__V1ContractNotSet();
    error DexLens__V2ContractNotSet();
    error DexLens__V2_1ContractNotSet();
    error DexLens__V2_2ContractNotSet();
    error DexLens__AlreadyInitialized();
    error DexLens__InvalidDataFeed();
    error DexLens__ZeroAddress();
    error DexLens__EmptyDataFeeds();
    error DexLens__SameDataFeed();
    error DexLens__ExceedsMaxLevels();
    error DexLens__InvalidLevel();
    error DexLens__NoDataFeeds(address token);
    error DexLens__ExceedsMaxTokensPerLevel();

    /// @notice Enumerators of the different data feed types
    enum DataFeedType {
        V1,
        V2,
        V2_1,
        V2_2,
        CHAINLINK
    }

    /**
     * @notice Structure for data feeds, contains the data feed's address and its type.
     * For V1/V2, the`dfAddress` should be the address of the pair
     * For chainlink, the `dfAddress` should be the address of the aggregator
     */
    struct DataFeed {
        address collateralAddress;
        address dfAddress;
        uint88 dfWeight;
        DataFeedType dfType;
    }

    /**
     * @notice Structure for a set of data feeds
     * `datafeeds` is the list of all the data feeds
     * `indexes` is a mapping linking the address of a data feed to its index in the `datafeeds` list.
     */
    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    /**
     * @notice List of trusted tokens
     */
    struct TrustedTokens {
        address[] tokens;
    }

    event DataFeedAdded(address token, DataFeed dataFeed);

    event DataFeedsWeightSet(address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address token, address dfAddress);

    event TrustedTokensSet(uint256 indexed level, address[] tokens);

    function getWNative() external view returns (address wNative);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getLegacyFactoryV2() external view returns (ILBLegacyFactory legacyFactoryV2);

    function getFactoryV2_1() external view returns (ILBFactory factoryV2);

    function getFactoryV2_2() external view returns (ILBFactory factoryV2_2);

    function getDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getLPPriceUSD (address pair) external view returns (uint256);

    function addDataFeed(address token, DataFeed calldata dataFeed) external;

    function setDataFeedWeight(address token, address dfAddress, uint88 newWeight) external;

    function removeDataFeed(address token, address dfAddress) external;

    function setTrustedTokensAt(uint256 level, address[] calldata tokens) external;

    function addDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;
}
