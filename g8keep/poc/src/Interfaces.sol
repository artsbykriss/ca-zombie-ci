// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Minimal interfaces for the live g8keep contracts (Base mainnet).

interface IG8keepFactory {
    struct TokenSale {
        address tokenAddress;
        uint256 amountToSell;
        uint256 amountOutMin;
        address recipient;
    }

    function sellTokens(TokenSale[] calldata sellParameters, uint256 deadline) external;
    function owner() external view returns (address);
    function WETH() external view returns (address);
    function UNISWAP_V2_ROUTER() external view returns (address);
    function g8keepFeeWallet() external view returns (address);
    function penaltyReceiver() external view returns (address);
    function g8keepTokenVesting() external view returns (address);
    function g8keepFee() external view returns (uint16);
    function g8keepInitialLiquidityFee() external view returns (uint16);
    function allowedPairs(address) external view returns (bool);
    function pairedTokenMinimumLiquidity(address) external view returns (uint256);
    function withdrawToken(address tokenAddress, address to) external;
    function withdrawETH(address to) external;
    function deployToken(
        uint256 _initialLiquidity,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _treasuryWallet,
        uint16 _buyFee,
        uint16 _sellFee,
        address _pairedToken,
        uint256 _deployReserve,
        uint256 _deployVestTime,
        uint256 _snipeProtectionSeconds,
        uint256 _heavySnipeSeconds,
        uint256 _heavySnipeExponent,
        bytes32 _tokenSalt
    ) external payable returns (address);
}

interface IG8keepToken {
    function PAIRED_TOKEN() external view returns (address);
    function UNISWAP_V2_PAIR() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function SNIPE_PROTECTION_END() external view returns (uint40);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(address to) external returns (uint256, uint256);
    function skim(address to) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IG8keepPenaltyReceiver {
    function transferToken(address tokenAddress, address to, uint256 amount) external;
    function allowedTransferers(address) external view returns (uint256);
}

interface IG8keepVester {
    function claim(uint256 id) external;
    function nextVestingId() external view returns (uint256);
    function vested(uint256 id) external view returns (uint256);
}
