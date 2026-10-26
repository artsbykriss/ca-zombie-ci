// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDexFiUniversalRouterBytes {
    struct DatasetItem {
        uint256 position;
        bytes data;
    }

    struct DataConfiguration {
        address tokenIn;
        address tokenOut;
        DatasetItem[] swapDataset;
        DatasetItem[] getAmountInDataset;
        DatasetItem[] getAmountOutDataset;
    }

    struct GetConfiguration {
        bytes4 signature;
        uint256 amountPosition;
        uint256 addressSenderPosition;
        uint256 dataWordsLength;
        uint256 responseNum;
    }

    struct FeeConfiguration {
        uint256 swapFee;
        uint256 divider;
    }

    struct PairConfiguration {
        address router;
        bytes4 signatureSwap;
        uint256 amountInPositionSwap;
        uint256 amountOutMinPositionSwap;
        uint256 receiverPositionSwap;
        uint256 deadlinePositionSwap;
        uint256 dataWordsLengthSwap;
        address quoter;
        GetConfiguration getAmountInConfiguration;
        GetConfiguration getAmountOutConfiguration;
        FeeConfiguration feeConfiguration;
    }

    struct Configuration {
        address tokenIn;
        address tokenOut;
        PairConfiguration pairConfiguration;
    }

    function pairConfiguration(
        address tokenIn,
        address tokenOut
    ) external view returns (PairConfiguration memory result);

    function swapConfigurationData(address, address, uint256) external view returns (bytes memory);

    function getAmountInConfigurationData(address, address, uint256) external view returns (bytes memory);

    function getAmountOutConfigurationData(address, address, uint256) external view returns (bytes memory);

    event ConfigurationUpdated(address indexed tokenIn, address indexed tokenOut, PairConfiguration config);
    event ConfigurationSwapDataUpdated(address indexed tokenIn, address indexed tokenOut, DatasetItem[] dataset);
    event ConfigurationGetAmountInDataUpdated(address indexed tokenIn, address indexed tokenOut, DatasetItem[] dataset);
    event ConfigurationGetAmountOutDataUpdated(
        address indexed tokenIn,
        address indexed tokenOut,
        DatasetItem[] dataset
    );

    error UniversalRouterWrongParameters();
    error UniversalRouterSwapTokensNotSupported();

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (bool);

    function getAmountOut(uint256 _amountIn, address _tokenIn, address _tokenOut) external returns (uint256 amountOut);

    function getAmountIn(uint256 _amountOut, address _tokenIn, address _tokenOut) external returns (uint256 amountIn);
}
