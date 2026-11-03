// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
}

interface IApolloXDiamond {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
    struct LpItem {
        address tokenAddress;
        int256 value;
        uint8 decimals;
        int256 valueUsd;
        uint16 targetWeight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        bool dynamicFee;
    }
    struct CommissionInfo {
        address token;
        uint256 total;
        uint256 pending;
    }
    struct TraderAsset {
        uint8 purpose;
        address token;
        uint256 value;
    }
    struct PriceFeedInfo {
        address token;
        address feedAddress;
        string description;
        uint8 decimals;
    }
    struct FacetCut {
        address facetAddress;
        uint8 action;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory);
    function facetAddress(bytes4) external view returns (address);
    function itemValue(address token) external view returns (LpItem memory);
    function getTotalValueUsd() external view returns (int256);
    function revenues(address[] calldata tokens) external view returns (CommissionInfo[] memory);
    function traderAssets(address[] calldata tokens) external view returns (TraderAsset[] memory);
    function burnAlp(address tokenOut, uint256 alpAmount, uint256 minOut, address receiver) external;
    function withdrawRevenue(address[] calldata tokens) external;
    function paused() external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function coolingDuration() external view returns (uint256);
    function alpPrice() external view returns (uint256);
    function ALP() external view returns (address);
    function queueTransaction(string calldata functionSignature, bytes calldata data) external;
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
    function chainlinkPriceFeeds() external view returns (PriceFeedInfo[] memory);
    function getPrice(address token) external view returns (uint256);
}

interface IAggregatorV3 {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

interface ISafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
    function VERSION() external view returns (string memory);
}
