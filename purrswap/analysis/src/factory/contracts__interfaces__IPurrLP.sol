// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPurrLP {
    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _BASE_RESERVE_() external view returns (uint112);

    function _QUOTE_RESERVE_() external view returns (uint112);

    function _BASE_TARGET_() external view returns (uint112);

    function _QUOTE_TARGET_() external view returns (uint112);

    function getEffectiveI() external view returns (uint256);
    
    function getReserves() external view returns (uint256 baseReserve, uint256 quoteReserve);

    function totalSupply() external view returns (uint256 totalSupply);

    function init(
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        address oracle
    ) external;

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function buyShares(address to) external returns (uint256 shares, uint256 baseInput, uint256 quoteInput);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function MIN_LP_FEE_RATE() external view returns (uint256);

    function MAX_LP_FEE_RATE() external view returns (uint256);

    function _PAUSED_() external view returns (bool);

    function setPaused(bool paused) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
}
