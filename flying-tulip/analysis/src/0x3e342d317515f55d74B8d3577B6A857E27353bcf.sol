pragma solidity ^0.8.30;

import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV3Interface} from "./OracleRouterChainlink.sol";

/// @title ERC4626UsdOracle
/// @notice Values one vault share in USD WAD using its assets and an underlying/USD feed.
/// @dev Only use with reviewed vaults whose conversion rate resists donation manipulation.
///      convertToAssets reports accounting redemption value, not executable market liquidity,
///      withdrawal fees or slippage. Round metadata and timestamps describe the base USD feed
///      only; the vault conversion rate is observed when latestRoundData is called.
contract ERC4626UsdOracle is AggregatorV3Interface, Ownable2Step, Pausable {
    using SafeCast for uint256;

    error InvalidContract(address target);
    error InvalidAsset(address actualAsset);
    error InvalidDecimals(address target, uint8 decimals);
    error MetadataChanged();
    error InvalidMaxStaleness();
    error InvalidPrice();
    error InvalidRound();
    error StalePrice();

    event MaxStalenessSet(uint32 previousMaxStaleness, uint32 newMaxStaleness);

    IERC4626 public immutable vault;
    IERC20Metadata public immutable underlyingAsset;
    AggregatorV3Interface public immutable baseFeed;
    uint8 public immutable shareDecimals;
    uint8 public immutable assetDecimals;
    uint8 public immutable baseFeedDecimals;
    uint256 public immutable shareUnit;
    uint256 public immutable assetUnit;
    uint256 private immutable priceDivisor;
    uint256 private immutable priceMultiplier;

    uint32 public maxStaleness;

    /// @param vault_ Reviewed ERC4626 share token to value.
    /// @param expectedAsset Expected underlying token; must match vault.asset().
    /// @param baseFeed_ USD feed for expectedAsset, with at most 18 decimals.
    /// @param initialOwner Governance that can pause the oracle and update feed freshness.
    /// @param maxStaleness_ Maximum age of the base USD feed in seconds; must be nonzero.
    constructor(
        address vault_,
        address expectedAsset,
        address baseFeed_,
        address initialOwner,
        uint32 maxStaleness_
    )
        Ownable(initialOwner)
    {
        if (vault_.code.length == 0) revert InvalidContract(vault_);
        if (expectedAsset.code.length == 0) revert InvalidContract(expectedAsset);
        if (baseFeed_.code.length == 0) revert InvalidContract(baseFeed_);
        if (maxStaleness_ == 0) revert InvalidMaxStaleness();

        vault = IERC4626(vault_);
        underlyingAsset = IERC20Metadata(expectedAsset);
        baseFeed = AggregatorV3Interface(baseFeed_);
        address actualAsset = vault.asset();
        if (actualAsset != expectedAsset) revert InvalidAsset(actualAsset);

        uint8 sharesDecimals_ = vault.decimals();
        uint8 assetDecimals_ = underlyingAsset.decimals();
        uint8 feedDecimals_ = baseFeed.decimals();
        if (sharesDecimals_ > 36) revert InvalidDecimals(vault_, sharesDecimals_);
        if (assetDecimals_ > 36) revert InvalidDecimals(expectedAsset, assetDecimals_);
        if (feedDecimals_ > 18) revert InvalidDecimals(baseFeed_, feedDecimals_);
        shareDecimals = sharesDecimals_;
        assetDecimals = assetDecimals_;
        baseFeedDecimals = feedDecimals_;
        shareUnit = 10 ** sharesDecimals_;
        assetUnit = 10 ** assetDecimals_;

        // Combine the decimal scales before division to retain full WAD precision.
        uint256 combinedDecimals = uint256(assetDecimals_) + feedDecimals_;
        priceDivisor = combinedDecimals >= 18 ? 10 ** (combinedDecimals - 18) : 1;
        priceMultiplier = combinedDecimals < 18 ? 10 ** (18 - combinedDecimals) : 1;
        maxStaleness = maxStaleness_;
        emit MaxStalenessSet(0, maxStaleness_);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function setMaxStaleness(uint32 maxStaleness_) external onlyOwner {
        if (maxStaleness_ == 0) revert InvalidMaxStaleness();
        uint32 previousMaxStaleness = maxStaleness;
        maxStaleness = maxStaleness_;
        emit MaxStalenessSet(previousMaxStaleness, maxStaleness_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Propagates dependency failures. A base-feed round ID does not version vault yield.
    function latestRoundData()
        external
        view
        whenNotPaused
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        // Fail closed if a dependency upgrade changes any cached unit or the underlying asset.
        if (
            vault.asset() != address(underlyingAsset) || vault.decimals() != shareDecimals
                || underlyingAsset.decimals() != assetDecimals
                || baseFeed.decimals() != baseFeedDecimals
        ) revert MetadataChanged();

        (roundId, answer, startedAt, updatedAt, answeredInRound) = baseFeed.latestRoundData();
        if (answer <= 0) revert InvalidPrice();
        if (
            roundId == 0 || answeredInRound < roundId || startedAt == 0 || updatedAt == 0
                || startedAt > updatedAt || updatedAt > block.timestamp
        ) revert InvalidRound();
        if (block.timestamp - updatedAt > maxStaleness) revert StalePrice();

        uint256 assets = vault.convertToAssets(shareUnit);
        uint256 priceWad = Math.mulDiv(assets, uint256(answer), priceDivisor) * priceMultiplier;
        if (priceWad == 0) revert InvalidPrice();
        answer = priceWad.toInt256();
    }
}
