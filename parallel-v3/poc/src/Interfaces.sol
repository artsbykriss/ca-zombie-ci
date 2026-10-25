// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IERC4626 {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function pricePerShare() external view returns (uint256);
    function asset() external view returns (address);
}

interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function aggregator() external view returns (address);
}

interface IMorphoOracle {
    function price() external view returns (uint256);
}

interface IMorphoChainlinkOracleV2 {
    function price() external view returns (uint256);
    function BASE_VAULT() external view returns (address);
    function BASE_VAULT_CONVERSION_SAMPLE() external view returns (uint256);
    function BASE_FEED_1() external view returns (address);
    function QUOTE_VAULT() external view returns (address);
    function QUOTE_FEED_1() external view returns (address);
    function SCALE_FACTOR() external view returns (uint256);
}

struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

interface IParallelizer {
    // --- loupe ---
    function facetAddresses() external view returns (address[] memory);
    function facetFunctionSelectors(address) external view returns (bytes4[] memory);
    function facetAddress(bytes4) external view returns (address);

    // --- getters ---
    function tokenP() external view returns (address);
    function getCollateralList() external view returns (address[] memory);
    function getCollateralRatio() external view returns (uint64 collatRatio, uint256 stablecoinsIssued);
    function getTotalIssued() external view returns (uint256);
    function getStablecoinCap(address) external view returns (uint256);
    function getIssuedByCollateral(address) external view returns (uint256, uint256);
    function isPaused(address, uint8) external view returns (bool);
    function isWhitelistedCollateral(address) external view returns (bool);
    function getCollateralMintFees(address) external view returns (uint64[] memory, int64[] memory);
    function getCollateralBurnFees(address) external view returns (uint64[] memory, int64[] memory);
    function getOracle(address)
        external
        view
        returns (uint8 oracleType, uint8 targetType, bytes memory oracleData, bytes memory targetData, bytes memory hyperparameters);
    function getOracleValues(address)
        external
        view
        returns (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption);
    function getSwapRouter() external view returns (address);
    function accessManager() external view returns (address);

    // --- swapper (permissionless money path) ---
    function quoteIn(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256 amountOut);
    function quoteOut(uint256 amountOut, address tokenIn, address tokenOut) external view returns (uint256 amountIn);
    function swapExactInput(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    // --- redeemer (permissionless money path) ---
    function quoteRedemptionCurve(uint256 amount) external view returns (address[] memory tokens, uint256[] memory amounts);
    function redeem(
        uint256 amount,
        address receiver,
        uint256 deadline,
        uint256[] memory minAmountOuts,
        bytes32 expectedTokensHash
    ) external returns (address[] memory tokens, uint256[] memory amounts);
}
