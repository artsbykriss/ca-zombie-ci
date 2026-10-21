// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IFeeManager {
    
    // Dynamic Fee System Constants
    struct FeeTier {
        uint256 threshold;      // Price drop threshold in basis points (1000 = 10%)
        uint256 fee;           // Fee rate in basis points (500 = 5%)
        uint256 cooldown;   // Cooldown time in seconds
    }

    // Events
    event DynamicFeeActivated(uint256 indexed tokenId, uint256 fee, uint256 duration);
    event DefaultFeeActivated(uint256 indexed tokenId, uint256 fee, uint256 duration);
    event FlashSaleFeeActivated(uint256 indexed tokenId, uint256 fee, uint256 cooldownEnd);
    event PriceUpdated(uint256 indexed tokenId, uint256 price, uint256 emaPrice);
    event FeeTierUpdated(uint256 indexed index, FeeTier newTier);
    event FeeTiersUpdated(FeeTier[5] newTiers);
    event FlashSaleParamsUpdated(uint256 newThreshold, uint256 newFee, uint256 newCooldown);
    event EMAParamsUpdated(uint256 newPeriod, uint256 newAlpha, uint256 newDenominator);
    event NormalFeeUpdated(uint256 newFee);
    event FeeManagerRoleGranted(address indexed account);
    event FeeManagerRoleRevoked(address indexed account);
    event CalculateFeeRoleGranted(address indexed account);
    event CalculateFeeRoleRevoked(address indexed account);

    // Errors
    error InvalidIndex();
    error PlayerIdCannotBeZero();
    error InvalidTierIndex();
    error InvalidThreshold();
    error InvalidFee();
    error InvalidCooldown();
    error InvalidDenominator();
    error InvalidAlpha();
    error ZeroAddress();
    
    // Initialization
    function initialize(address _owner) external;

    // Fee calculation
    function calculateSellFee(uint256 tokenId, uint256 currentPrice, uint256 tokenReserve, uint256 sellAmount, address seller) external returns (uint256 feeRate, uint8 feeType);
    function calculateSellFeeSimulated(uint256 tokenId, uint256 currentPrice, uint256 tokenReserve, uint256 sellAmount, address seller) external view returns (uint256 feeRate, uint8 feeType);
    function getBuyFeeAndUpdateEMA(uint256 tokenId, uint256 currentPrice) external returns (uint256);
    function getBuyFeeSimulated() external view returns (uint256, uint8);
    function calculateCurrentPrice(uint256 currencyReserve, uint256 tokenReserve) external pure returns (uint256);
    
    // Getters
    function getEMAPrice(uint256 tokenId) external view returns (uint256);
    function getActiveFeeInfo(uint256 tokenId, address seller) external view returns (uint256 fee, uint256 remainingTime);
    function getNormalFee() external view returns (uint256);
    function getLastEMAUpdateTime(uint256 tokenId) external view returns (uint256);
    function getFlashSaleCooldownEnd(uint256 tokenId, address seller) external view returns (uint256);
    function flashSaleThreshold() external view returns (uint256);
    function flashSaleFee() external view returns (uint256);
    function flashSaleCooldown() external view returns (uint256);
    function emaPeriod() external view returns (uint256);
    function emaAlpha() external view returns (uint256);
    function alphaDenominator() external view returns (uint256);
    function feeTiers(uint256 index) external view returns (uint256 threshold, uint256 fee, uint256 minDuration);
    
    // Admin functions
    function activateDefaultFeeTier(uint256 tokenId) external;
    function updateFeeTier(uint256 index, FeeTier memory newTier) external;
    function setFeeTiers(FeeTier[5] memory newTiers) external;
    function setNormalFee(uint256 newFee) external;
    function setFlashSaleParams(uint256 newThreshold, uint256 newFee, uint256 newCooldown) external;
    function setEMAParams(uint256 newPeriod, uint256 newAlpha, uint256 newDenominator) external;
    function grantFeeManagerRole(address _account) external;
    function revokeFeeManagerRole(address _account) external;
    function grantCalculateFeeRole(address _account) external;
    function revokeCalculateFeeRole(address _account) external;
} 