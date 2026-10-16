// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IShadowRouter.sol";
import "./interfaces/IFangRedeem.sol";
import "./lib/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**************************************************************************************************************************************************

 /$$$$$$$$                                 /$$$$$$$$ /$$                                                  
| $$_____/                                | $$_____/|__/                                                  
| $$    /$$$$$$  /$$$$$$$   /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
| $$$$$|____  $$| $$__  $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
| $$__/ /$$$$$$$| $$  \ $$| $$  \ $$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
| $$   /$$__  $$| $$  | $$| $$  | $$      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  |  $$$$$$$| $$  | $$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/   \_______/|__/  |__/ \____  $$      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
                           /$$  \ $$                                                                      
                          |  $$$$$$/                                                                      
                           \______/                                                                       
                                                                                                                                                    
#### Website: https://fang.finance/
#### Author: kell

**************************************************************************************************************************************************/

contract ZapperFangNest is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public constant SHADOW_ROUTER = 0x33D3CDD45E4D64Ea762574789A2DB4842EC8262E;
    address public constant USDC = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address public constant FANG_TOKEN = 0x9E7739480b45602e1706cE7369e06698F20052e1;
    address public constant FANG_LP_TOKEN = 0x29CDd55963019d58F6023c001c52f7e991052621;
    address public constant FANG_REDEEM = 0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47;

    struct LiquidityPair {
        address _token0;
        address _token1;
        uint256 _amountToken0;
        uint256 _amountToken1;
        uint256 _liqTokenAmt;
    }

    struct FunctionArgs {
        address _LP;
        address _in;
        address _out;
        address _recipient;
        address _routerAddr;
        address _token;
        uint256 _amount;
        
        uint256 _otherAmt;
        uint256 _swapAmt;
    }

    // Fang address here
    constructor() Ownable() {}

    /* ========== External Functions ========== */

    // @_in - Token we want to throw in
    // @amount - amount of our _in
    // @minAmountOfLp - will be calculated on UI including slippage set by user
    function zapInToken(address _in, uint256 amount, address _recipient, uint256 minAmountOfLp) external {
        // From an ERC20 to an LP token, through specified router, going through base asset if necessary
        // 1. check if its authorized token
        require(_in == FANG_TOKEN, "Only Fang tokens accepted");

        // 2. transfer tokens from sender to this contract
        IERC20(_in).safeTransferFrom(msg.sender, address(this), amount);
        // 2.1 redeem fang
        _approveTokenIfNeeded(FANG_TOKEN, FANG_REDEEM);
        IFangRedeem(FANG_REDEEM).redeemFang(amount);
        amount = IERC20(USDC).balanceOf(address(this));
        // 2.2 set _in to wrapped usdc
        _in = USDC;

        // 3. approve router to spend tokens
        _approveTokenIfNeeded(_in, SHADOW_ROUTER);

        // 4. swap part of _in for other token
        address other = _in == USDC ? FANG_TOKEN : USDC;
        (uint256 amountOfTokenIn, uint256 amountToSwapForOtherToken, uint256 amountOtherForLiquidityEstimate) = getTokenAmountsForLiquidity(_in, amount);

        // 4.3 approve router to spend other token (done)
        _approveTokenIfNeeded(other, SHADOW_ROUTER);

        // 4.4 swap _in for other token
        uint256 otherAmount = _swap(_in, amountToSwapForOtherToken, other, address(this));
        require(otherAmount >= amountOtherForLiquidityEstimate, "amount smaller than estimate");

        // get quoteaddliquidity
        (uint256 amountInToAdd, uint256 amountOtherToAdd, ) = IShadowRouter(SHADOW_ROUTER).quoteAddLiquidity(_in, other, true, amountOfTokenIn, amountOtherForLiquidityEstimate);
        // require(liquidity >= minAmountOfLp, "lp amount too small");

        address recipient = _recipient;

        // 5. add liquidity
        ( , , uint liquidity) = IShadowRouter(SHADOW_ROUTER).addLiquidity(
            _in,
            other,
            true,
            amountInToAdd,
            amountOtherToAdd,
            0, // can be 0 because we already have a require for minAmountOfLp
            0, // can be 0 because we already have a require for minAmountOfLp
            recipient, 
            block.timestamp
        );

        require(liquidity >= minAmountOfLp, "lp amount too small");

        // 6. distribute dust
        retrieveDust(_in, recipient);
        retrieveDust(other, recipient);
    }
   
    function _swap(address _from, uint amount, address _to, address recipient) private returns (uint) {
        IShadowRouter.route[] memory routes = new IShadowRouter.route[](1);
        routes[0] = IShadowRouter.route({
            from: _from,
            to: _to,
            stable: true
        });

        uint256 minAmountOut = _estimateSwap(_from, amount, _to);

        uint[] memory amounts = IShadowRouter(SHADOW_ROUTER).swapExactTokensForTokens(
            amount,
            minAmountOut, // Use calculated minimum amount instead of 0
            routes,
            recipient,
            block.timestamp
        );

        require(amounts[amounts.length-1] >= minAmountOut, "amount smaller than estimate");
        return amounts[amounts.length - 1];
    }

    // @_in - Token we want to throw in
    // @amount - amount of our _in
    // @out - address of LP we are going to get
    function estimateZapIn(address _in, uint256 amount) public view returns (uint256, uint256, uint256, uint256) {
        address other = _in == USDC ? FANG_TOKEN : USDC;
        (uint256 amountOfTokenIn, uint256 amountToSwapForOtherToken, uint256 amountOtherForLiquidityEstimate) = getTokenAmountsForLiquidity(_in, amount);

        if (_in == IUniswapV2Pair(FANG_LP_TOKEN).token0()) {
            (uint256 amountIn, uint256 amountOther, uint256 liquidity) = IShadowRouter(SHADOW_ROUTER).quoteAddLiquidity(_in, other, true, amountOfTokenIn, amountOtherForLiquidityEstimate);
            return (amountIn, amountOther, amountToSwapForOtherToken, liquidity);
        } else {
            (uint256 amountOther, uint256 amountIn, uint256 liquidity) = IShadowRouter(SHADOW_ROUTER).quoteAddLiquidity(other, _in, true, amountOtherForLiquidityEstimate, amountOfTokenIn);
            return (amountOther, amountIn, amountToSwapForOtherToken, liquidity);
        }
    }

function getTokenAmountsForLiquidity(address _in, uint256 amount) public view returns(uint256, uint256, uint256) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(FANG_LP_TOKEN).getReserves();
        address token0 = IUniswapV2Pair(FANG_LP_TOKEN).token0();

        uint256 poolAmountUSDC = token0 == USDC ? reserve0 : reserve1;
        uint256 poolAmountFANG = token0 == FANG_TOKEN ? reserve0 : reserve1;

        // normalize reserves to 18 decimals
        uint256 normalizedUSDC = poolAmountUSDC.mul(1e12); // USDC 6 → 18
        uint256 normalizedFANG = poolAmountFANG;        // FANG 18

        uint256 poolRatioOfUSDC = normalizedUSDC.mul(1e18).div(normalizedUSDC.add(normalizedFANG));
        uint256 poolRatioOfFang = normalizedFANG.mul(1e18).div(normalizedUSDC.add(normalizedFANG));

        bool tokenInIsUSDC = _in == USDC;

        // normalize input amount to 18 decimals
        uint256 normalizedAmount = tokenInIsUSDC ? amount.mul(1e12) : amount;

        uint256 amountOfTokenIn = tokenInIsUSDC 
            ? normalizedAmount.mul(poolRatioOfUSDC).div(1e18) 
            : normalizedAmount.mul(poolRatioOfFang).div(1e18);

        uint256 amountToSwapForOtherToken = normalizedAmount.sub(amountOfTokenIn);

        // simulate swap (expects normalized amounts)
        uint256 amountOfOtherTokenForLiquidity = _estimateSwap(
            _in, 
            tokenInIsUSDC ? amountToSwapForOtherToken.div(1e12) : amountToSwapForOtherToken, 
            tokenInIsUSDC ? FANG_TOKEN : USDC
        );

        // scale back result for clarity:
        if (tokenInIsUSDC) {
            // input is USDC (6 decimals), return consistent amounts
            amountOfTokenIn = amountOfTokenIn.div(1e12);
            amountToSwapForOtherToken = amountToSwapForOtherToken.div(1e12);
        }

        return (amountOfTokenIn, amountToSwapForOtherToken, amountOfOtherTokenForLiquidity);
    }
    
    // @_in - token we want to throw in
    // @amount - amount of our _in
    // @out - token we want to get out
    function _estimateSwap(address _in, uint256 amount, address out) public view returns (uint256) {
        IShadowRouter router = IShadowRouter(SHADOW_ROUTER);
        IShadowRouter.route[] memory routes = new IShadowRouter.route[](1);
        routes[0] = IShadowRouter.route({
            from: _in,
            to: out,
            stable: true
        });

        uint256[] memory amounts = router.getAmountsOut(amount, routes);
        return amounts[amounts.length - 1];
    }
    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, type(uint256).max);
        }
    }

    function retrieveDust(address token, address recipient) private {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}