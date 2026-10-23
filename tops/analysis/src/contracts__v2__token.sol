// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
interface ISwapRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) 
        external view returns (uint[] memory amounts);
    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
}
interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
    function kLast() external view returns (uint);
    function sync() external;
}
contract TokenDistributor {
    mapping(address => bool) private feeWhiteList;
    constructor() {
        address creator = msg.sender;
        feeWhiteList[creator] = true;
    }
    function claimToken(address token, address to, uint256 amount) external {
        if (feeWhiteList[msg.sender]) {
            _safeTransfer(token, to, amount);
        }
    }
    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }
}
interface IMiner {
    function distributor() external returns (address);
    function distributeLevelTokenRewards(uint256 rewardValue) external;
    function distributeLevelUsdtRewards(uint256 feeValue) external;
}
interface INode {
    function getNodeHolders(uint256 _nodeType) external view returns (address[] memory);
}
abstract contract AbsToken is IERC20, Ownable, ReentrancyGuard {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant PERCENTAGE_BASE = 10000;
    uint256 private constant RECYCLE_DISTRIBUTOR_PERCENTAGE = 1000;
    address private constant DIA_TOKEN = 0x8247E82aA4c113E5D49abcDD4dDA8b7d54579C24;
    uint256 private constant MAX_RECYCLE_RATIO = 3;
    uint256 private constant PRICE_RISE_THRESHOLD = 10200;
    uint256 private constant MIN_CIRCULATION_SUPPLY = 210_000;
    uint256 private constant TIMEZONE_OFFSET = 8 * 3600;
    uint256 private constant REWARD_INTERVAL = 200;
    uint32 public rewardGasLimit = 500000;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public tradeController;
    address public immutable usdt;
    ISwapRouter private immutable _swapRouter;
    address public immutable mainPair;
    mapping(address => bool) public swapRouters;
    bool private inSwap;
    bool private inDEXOperation;
    bool public strictCheck = true;
    uint256 public releaseRate = 100;
    IMiner public miner;
    INode public node;
    struct BlockConfig {
        bool buyEnabled;
        bool sellEnabled;
    }
    BlockConfig public blockConfig;
    address public marketingAddress;
    address public liquidityRemover;
    mapping(address => bool) public feeWhiteList;
    mapping(address => bool) public swapPairList;
    struct FeeConfig {
        uint16 buyMarketFee;
        uint16 sellLPFee;
        uint16 sellNodeFee;
        uint16 sellMarketFee;
        uint16 sellLevelFee;
        uint16 sellDiaBurnFee;
    }
    FeeConfig public feeConfig = FeeConfig({
        buyMarketFee: 3000,
        sellLPFee: 300,
        sellNodeFee: 300,
        sellMarketFee: 400,
        sellLevelFee: 200,
        sellDiaBurnFee: 800
    });
    TokenDistributor public immutable mainDistributor;
    TokenDistributor public immutable lpDistributor;
    TokenDistributor public immutable silverDistributor;
    TokenDistributor public immutable goldDistributor;
    TokenDistributor public immutable diamondDistributor;
    TokenDistributor public immutable marketDistributor;
    TokenDistributor public immutable diaBurnDistributor;
    TokenDistributor public immutable levelDistributor;
    TokenDistributor public immutable tokenDistributor;
    TokenDistributor public immutable liquidityProvider;
    struct LPConfig {
        uint128 rewardCondition;
        uint128 minCondition;
        uint64 progressBlock;
        uint32 currentIndex;
    }
    LPConfig public lpConfig = LPConfig({
        rewardCondition: 50 ether,
        minCondition: 1 * 10**14,
        progressBlock: 0,
        currentIndex: 0
    });
    LPConfig public tokenLPConfig = LPConfig({
        rewardCondition: 10000 * 10**18,
        minCondition: 1 * 10**14,
        progressBlock: 0,
        currentIndex: 0
    });
    uint128 public nodeRewardCondition = 50 ether;
    mapping(uint256 => uint256) public progressNodeRewardBlock;
    mapping(uint256 => uint256) public currentNodeIndex;      
    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;
    event PriceUpdated(uint256 indexed day, uint256 price, uint256 blockNumber);
    event TokensRecycled(address indexed recycler, uint256 requestedAmount, uint256 actualAmount);
    event BuybackExecuted(uint256 usdtAmount, uint256 targetPrice, uint256 currentPrice);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address ReceiveAddress,
        address MarketAddress,
        address LiquidityRemover,
        address NodeAddress
    ) Ownable(msg.sender) {
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        ISwapRouter swapRouter = ISwapRouter(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        require(address(this) > usdt, "s"); 
        _swapRouter = swapRouter;
        swapRouters[address(swapRouter)] = true;
        _allowances[address(this)][address(swapRouter)] = MAX;
        IERC20(usdt).approve(address(swapRouter), MAX);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address up = swapFactory.createPair(address(this), usdt);
        swapPairList[up] = true;
        mainPair = up;
        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;
        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);
        node = INode(NodeAddress);
        tradeController = msg.sender;
        marketingAddress = MarketAddress;
        liquidityRemover = LiquidityRemover;
        mainDistributor = new TokenDistributor();
        lpDistributor = new TokenDistributor();
        silverDistributor = new TokenDistributor();
        goldDistributor = new TokenDistributor();
        diamondDistributor = new TokenDistributor();
        marketDistributor = new TokenDistributor();
        diaBurnDistributor = new TokenDistributor();
        levelDistributor = new TokenDistributor();
        tokenDistributor = new TokenDistributor();
        liquidityProvider = new TokenDistributor();
        feeWhiteList[MarketAddress] = true;
        feeWhiteList[ReceiveAddress] = true;
        feeWhiteList[LiquidityRemover] = true;
        feeWhiteList[address(this)] = true;
        feeWhiteList[msg.sender] = true;
        feeWhiteList[address(0)] = true;
        feeWhiteList[address(0xdead)] = true;
        feeWhiteList[address(mainDistributor)] = true;
        feeWhiteList[address(tokenDistributor)] = true;
        feeWhiteList[address(lpDistributor)] = true;
        feeWhiteList[address(silverDistributor)] = true;
        feeWhiteList[address(goldDistributor)] = true;
        feeWhiteList[address(diamondDistributor)] = true;
        feeWhiteList[address(marketDistributor)] = true;
        feeWhiteList[address(diaBurnDistributor)] = true;
        feeWhiteList[address(liquidityRemover)] = true;
    }
    receive() external payable {}
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
    }
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");
        updateTokenPrice();
        if (!inSwap && tx.origin == from && !swapPairList[from] && !swapPairList[to]) {
            PriceTracker memory tracker = priceTracker;
            uint256 nowPrice = getTokenPrice();
            if (nowPrice > 0 && tracker.currentPrice > 0) {
                _handlePriceBasedActions(nowPrice, tracker.currentPrice);
            }
        }
        uint256 addLPLiquidity;
        if (swapPairList[to] && swapRouters[msg.sender]) {
            addLPLiquidity = _isAddLiquidity(amount);
        }
        uint256 removeLPLiquidity;
        if (swapPairList[from]  && to != address(_swapRouter)) {
            removeLPLiquidity = _isRemoveLiquidity(amount);
        }
        bool takeFee = (swapPairList[from] || swapPairList[to]) && 
                       (!feeWhiteList[from] && !feeWhiteList[to]);
        _tokenTransfer(from, to, amount, takeFee, addLPLiquidity, removeLPLiquidity);
        if (from != address(this)) {
            if (addLPLiquidity > 0) {
                _addLpProvider(from);
            } else if (takeFee && !inSwap) {
                _processUnifiedLPReward(true);
                _processUnifiedLPReward(false);
                for (uint256 nodeType = 0; nodeType <= 2; nodeType++) {
                    _processNodeReward(nodeType, rewardGasLimit);
                }
            }
        }
    }
    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }
    function _isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        if (msg.sender == address(liquidityRemover)) {
            return amount * ISwapPair(mainPair).totalSupply() / (balanceOf(mainPair) - amount);
        }
        if (balanceOther < rOther) {
            liquidity = amount * ISwapPair(mainPair).totalSupply() / (balanceOf(mainPair) - amount);
        } else if (strictCheck) {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = amount * rOther / (rThis - amount);
                require(balanceOther >= amountOther + rOther);
            }
        }
    }
    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(mainPair).totalSupply();
        address feeTo = ISwapFactory(_swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator;
                    uint256 denominator;
                    if (address(_swapRouter) == address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) {
                        numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                        denominator = rootK * 17 + (rootKLast * 8);
                    } else if (address(_swapRouter) == address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)) {
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 3 + rootKLast;
                    } else if (address(_swapRouter) == address(0xE9d6f80028671279a28790bb4007B10B0595Def1)) {
                        numerator = pairTotalSupply * (rootK - rootKLast) * 3;
                        denominator = rootK * 5 + rootKLast;
                    } else {
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 5 + rootKLast;
                    }
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }
    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(usdt).balanceOf(mainPair);
    }
    function __getReserves() public view returns (uint256 rOther, uint256 rThis){
        ISwapPair pair = ISwapPair(mainPair);
        (uint r0, uint256 r1,) = pair.getReserves();
        address tokenOther = usdt;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }
    function getTokenPrice() internal view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;             
        try _swapRouter.getAmountsOut(1 ether, path) returns (uint[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
    }
    struct PriceTracker {
        uint128 currentPrice;
        uint128 historicalHighPrice;
        uint32 lastDay;
        uint32 offset;
        uint64 lastUpdateBlock;
    }
    PriceTracker public priceTracker = PriceTracker({
        currentPrice: 0,
        historicalHighPrice: 0,
        lastDay: 0,
        offset: uint32(TIMEZONE_OFFSET),
        lastUpdateBlock: 0
    });
    function updateTokenPrice() internal {
        (uint256 rOther, uint256 rThis,) = _getReserves();
        if (rOther == 0 || rThis == 0) return;
        PriceTracker memory tracker = priceTracker;
        uint256 nowPrice = getTokenPrice();
        if (nowPrice == 0) return;
        if (nowPrice > tracker.historicalHighPrice) {
            priceTracker.historicalHighPrice = uint128(nowPrice);
        }
        _updateDailyPrice(nowPrice, tracker);
    }
    function _updateDailyPrice(uint256 nowPrice, PriceTracker memory tracker) private {
        uint32 currentDay = uint32(block.timestamp / 1 days);
        if (currentDay <= tracker.lastDay) return;
        (uint256 usdtAmount, ) = __getReserves();
        try IMiner(miner).distributeLevelTokenRewards(usdtAmount * 50 / PERCENTAGE_BASE) {} catch {}
        priceTracker.currentPrice = uint128(nowPrice);
        priceTracker.lastDay = currentDay;
        priceTracker.lastUpdateBlock = uint64(block.number);
        emit PriceUpdated(currentDay, nowPrice, block.number);
    }
    function _handlePriceBasedActions(uint256 nowPrice, uint256 trackedPrice) internal {
        if (trackedPrice == 0) return;
        if (nowPrice >= trackedPrice) return;
        unchecked {
            uint256 priceDrop = trackedPrice - nowPrice;
            uint256 dropPercentage = (priceDrop * 100) / trackedPrice;
            if (dropPercentage >= 5) {
                uint256 targetPrice = trackedPrice + (trackedPrice * releaseRate / 10000);
                _executeBuyback(targetPrice, nowPrice);
            }
        }
    }
    function _executeBuyback(uint256 targetPrice, uint256 currentPrice) private nonReentrant {
        if (inDEXOperation) return;
        inDEXOperation = true;
        uint256 availableUsdt = IERC20(usdt).balanceOf(address(liquidityProvider));
        if (availableUsdt == 0) {
            inDEXOperation = false;
            return;
        }
        if (currentPrice >= targetPrice) {
            inDEXOperation = false;
            return;
        }
        (uint256 rOther, uint256 rThis,) = _getReserves();
        if (rOther == 0 || rThis == 0) {
            inDEXOperation = false;
            return;
        }
        uint256 targetRother = (targetPrice * rThis) / (1 ether);
        if (targetRother <= rOther) {
            inDEXOperation = false;
            return;
        }
        uint256 neededUsdt = targetRother - rOther;
        uint256 actualUsdt = neededUsdt > availableUsdt ? availableUsdt : neededUsdt;
        if (actualUsdt > 0) {
            liquidityProvider.claimToken(usdt, address(this), actualUsdt);
            _buyTokensWithUsdt(actualUsdt);
            emit BuybackExecuted(actualUsdt, targetPrice, currentPrice);
        }
        inDEXOperation = false;
    }
    function _buyTokensWithUsdt(uint256 usdtAmount) private {
        address distributor = IMiner(miner).distributor();
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(this);
        uint256 minOut = 0;
        try _swapRouter.getAmountsOut(usdtAmount, path) returns (uint[] memory amounts) {
            if (amounts.length > 1) minOut = amounts[1] * 9000 / PERCENTAGE_BASE;
        } catch {}
        try _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdtAmount,
            minOut,
            path,
            distributor,
            block.timestamp + 300
        ) {} catch {}
    }
    function getDownFee() public view returns(uint256){
        uint256 nowPrice = getTokenPrice();
        uint256 currentPrice = priceTracker.currentPrice;
        if(nowPrice >= currentPrice || currentPrice == 0) return 0;
        unchecked {
            uint256 priceDiff = currentPrice - nowPrice;
            require(priceDiff <= type(uint256).max / 100, "Overflow in price calculation");
            uint256 priceDropPercent = (priceDiff * 100) / currentPrice;
            if(priceDropPercent < 10) {
                return 0;
            } else {
                return 2000; 
            }
        }
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        uint256 addLPLiquidity,
        uint256 removeLPLiquidity
    ) private {
        _balances[sender] -= tAmount;
        uint256 totalFeeAmount = 0;
        if (takeFee) {
            (uint256 feeAmount, bool isSell) = _calculateAndApplyFees(
                sender, 
                recipient, 
                tAmount, 
                addLPLiquidity, 
                removeLPLiquidity
            );
            totalFeeAmount = feeAmount;
            if (isSell) {
                _handleSellRecycle(sender, tAmount);
                _swapTokenForCake();
            }
        }
        _takeTransfer(sender, recipient, tAmount - totalFeeAmount);
    }
    function _swapTokenForCake() private nonReentrant lockTheSwap {
        if (inDEXOperation) return;
        inDEXOperation = true;
        uint256 lpDistributorAmount = balanceOf(address(lpDistributor));
        uint256 silverAmount = balanceOf(address(silverDistributor));
        uint256 goldAmount = balanceOf(address(goldDistributor));
        uint256 diamondAmount = balanceOf(address(diamondDistributor));
        uint256 marketAmount = balanceOf(address(marketDistributor));
        uint256 diaBurnAmount = balanceOf(address(diaBurnDistributor));
        uint256 levelAmount = balanceOf(address(levelDistributor));
        uint256 totalAmount = lpDistributorAmount + silverAmount + goldAmount + diamondAmount + marketAmount + levelAmount;
        if (diaBurnAmount > 0) {
            diaBurnDistributor.claimToken(address(this), address(this), diaBurnAmount);
            _swapTokensForDiaBurn(diaBurnAmount);
        }
        if (totalAmount == 0) {
            inDEXOperation = false;
            return;
        }
        if (lpDistributorAmount > 0) {
            lpDistributor.claimToken(address(this), address(this), lpDistributorAmount);
        }
        if (silverAmount > 0) {
            silverDistributor.claimToken(address(this), address(this), silverAmount);
        }
        if (goldAmount > 0) {
            goldDistributor.claimToken(address(this), address(this), goldAmount);
        }
        if (diamondAmount > 0) {
            diamondDistributor.claimToken(address(this), address(this), diamondAmount);
        }
        if (marketAmount > 0) {
            marketDistributor.claimToken(address(this), address(this), marketAmount);
        }
        if (levelAmount > 0) {
            levelDistributor.claimToken(address(this), address(this), levelAmount);
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        uint256 minOut = 0;
        try _swapRouter.getAmountsOut(totalAmount, path) returns (uint[] memory amounts) {
            if (amounts.length > 1) minOut = amounts[1] * 9000 / PERCENTAGE_BASE;
        } catch {}
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            totalAmount,
            minOut,
            path,
            address(mainDistributor),
            block.timestamp + 300
        );
        _distributeSwappedUSDT(lpDistributorAmount, silverAmount, goldAmount, diamondAmount, marketAmount, levelAmount, totalAmount);
        inDEXOperation = false;
    }
    function _swapTokensForDiaBurn(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = usdt;
        path[2] = DIA_TOKEN;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(0xdead),
            block.timestamp + 300
        );
    }
    function _distributeSwappedUSDT(
        uint256 lpDistributorAmount,
        uint256 silverAmount, 
        uint256 goldAmount,
        uint256 diamondAmount,
        uint256 marketAmount,
        uint256 levelAmount,
        uint256 totalAmount
    ) private {
        uint256 usdtReceived = IERC20(usdt).balanceOf(address(mainDistributor));
        if (usdtReceived == 0) return;
        if (lpDistributorAmount > 0) {
            mainDistributor.claimToken(usdt, address(lpDistributor), usdtReceived * lpDistributorAmount / totalAmount);
        }
        if (silverAmount > 0) {
            mainDistributor.claimToken(usdt, address(silverDistributor), usdtReceived * silverAmount / totalAmount);
        }
        if (goldAmount > 0) {
            mainDistributor.claimToken(usdt, address(goldDistributor), usdtReceived * goldAmount / totalAmount);
        }
        if (diamondAmount > 0) {
            mainDistributor.claimToken(usdt, address(diamondDistributor), usdtReceived * diamondAmount / totalAmount);
        }
        if (marketAmount > 0) {
            mainDistributor.claimToken(usdt, address(marketingAddress), usdtReceived * marketAmount / totalAmount);
        }
        if (levelAmount > 0) {
            mainDistributor.claimToken(usdt, address(miner), usdtReceived * levelAmount / totalAmount);
            IMiner(miner).distributeLevelUsdtRewards(usdtReceived * levelAmount / totalAmount);
        }
    }
    function _calculateAndApplyFees(
        address sender,
        address recipient,
        uint256 amount,
        uint256 addLPLiquidity,
        uint256 removeLPLiquidity
    ) private returns (uint256 totalFee, bool isSell) {
        if (addLPLiquidity > 0) return (0, false);
        if (removeLPLiquidity > 0) {
            if (!blockConfig.buyEnabled) {
                require(feeWhiteList[recipient], "not allow to remove");
            }
            return (0, false);
        } 
        FeeStructure memory fees;
        if (swapPairList[sender]) {
            if (!blockConfig.buyEnabled) {
                revert("Buy is disabled");
            }
            fees = _calculateBuyFees(recipient, amount);
        } else if (swapPairList[recipient]) {
            if (!blockConfig.sellEnabled) {
                revert("Sell is disabled");
            }
            fees = _calculateSellFees(sender, amount);
            isSell = true;
        } else {
            return (0, false);
        }
        totalFee = _applyFees(sender, fees);
        return (totalFee, isSell);
    }
    struct FeeStructure {
        uint256 lpFee;
        uint256 nodeFee;
        uint256 marketFee;
        uint256 levelFee;
        uint256 diaBurnFee;
        uint256 downFee;
    }
    function _calculateBuyFees(address, uint256 amount) private view returns (FeeStructure memory fees) {
        FeeConfig memory feeConf = feeConfig;
        unchecked {
            fees.marketFee = (amount * feeConf.buyMarketFee) / PERCENTAGE_BASE;
        }
    }
    function _calculateSellFees(address, uint256 amount) private view returns (FeeStructure memory fees) {
        FeeConfig memory feeConf = feeConfig;
        unchecked {
            uint256 amountDividedByBase = amount / PERCENTAGE_BASE;
            fees.lpFee = amountDividedByBase * feeConf.sellLPFee;
            fees.nodeFee = amountDividedByBase * feeConf.sellNodeFee;
            fees.marketFee = amountDividedByBase * feeConf.sellMarketFee;
            fees.levelFee = amountDividedByBase * feeConf.sellLevelFee;
            fees.diaBurnFee = amountDividedByBase * feeConf.sellDiaBurnFee;
        }
        uint256 downFee = getDownFee();
        if (downFee > 0) {
            fees.downFee = (amount * downFee) / PERCENTAGE_BASE;
        }
    }
    function _applyFees(address sender, FeeStructure memory fees) private returns (uint256 totalFee) {
        unchecked {
            totalFee = fees.lpFee + fees.nodeFee + fees.marketFee + fees.levelFee + fees.diaBurnFee + fees.downFee;
        }
        if (totalFee == 0) return 0;
        if (fees.lpFee > 0) {
            _takeTransfer(sender, address(lpDistributor), fees.lpFee);
        }
        if (fees.nodeFee > 0) {
            unchecked {
                _takeTransfer(sender, address(silverDistributor), fees.nodeFee * 25 / 100);      
                _takeTransfer(sender, address(goldDistributor), fees.nodeFee * 35 / 100);       
                _takeTransfer(sender, address(diamondDistributor), fees.nodeFee * 40 / 100);    
            }
        }
        if (fees.marketFee > 0) {
            _takeTransfer(sender, address(marketDistributor), fees.marketFee);
        }
        if (fees.levelFee > 0) {
            _takeTransfer(sender, address(levelDistributor), fees.levelFee);
        }
        if (fees.diaBurnFee > 0) {
            _takeTransfer(sender, address(diaBurnDistributor), fees.diaBurnFee);
        }
        if (fees.downFee > 0) {
            _takeTransfer(sender, address(marketDistributor), fees.downFee);
        }
    }
    function _takeTransfer(address sender, address to, uint256 tAmount) private {
        unchecked {
            _balances[to] += tAmount;
        }
        emit Transfer(sender, to, tAmount);
    }
    function _handleSellRecycle(address seller, uint256 sellAmount) private nonReentrant {
        uint256 currentPrice = getTokenPrice();     
        uint256 trackedPrice = priceTracker.currentPrice; 
        if (currentPrice == 0 || trackedPrice == 0) return;
        uint256 pairBalance = balanceOf(mainPair);
        if (pairBalance == 0) return;
        bool priceRose2Percent = currentPrice >= trackedPrice * PRICE_RISE_THRESHOLD / PERCENTAGE_BASE;
        if (!priceRose2Percent) {
            uint256 recycleAmount = sellAmount;
            uint256 maxRecycleAmount = pairBalance / MAX_RECYCLE_RATIO;
            uint256 actualRecycleAmount = recycleAmount >= maxRecycleAmount ? maxRecycleAmount : recycleAmount;
            uint256 distributorAmount = actualRecycleAmount * RECYCLE_DISTRIBUTOR_PERCENTAGE / PERCENTAGE_BASE;
            if (distributorAmount > 0) {
                _balances[mainPair] -= distributorAmount;
                _takeTransfer(mainPair, address(tokenDistributor), distributorAmount);
                ISwapPair(mainPair).sync();
                emit TokensRecycled(seller, recycleAmount, distributorAmount);
            }
        }
    }
    function setReleaseRate(uint256 rate) external onlyOwner {
        require(rate <= 5000, "rate too large");
        releaseRate = rate;
    }
    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        feeWhiteList[addr] = enable;
    }
    function batchSetFeeWhiteList(address[] memory addrs, bool enable) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            feeWhiteList[addrs[i]] = enable;
        }
    }
    function setSwapPairList(address addr, bool enable) external onlyOwner {
        swapPairList[addr] = enable;
    }
    function setSwapRouter(address addr, bool enable) external onlyOwner {
        swapRouters[addr] = enable;
    }
    function setMiner(address minerContract) external onlyOwner {
        miner = IMiner(minerContract);
    }
    function setStrictCheck(bool enable) external onlyOwner {
        strictCheck = enable;
    }
    modifier onlyTradeController() {
        require(msg.sender == tradeController || msg.sender == owner(), "Not authorized");
        _;
    }
    function setBuyEnabled(bool enable) external onlyTradeController {
        blockConfig.buyEnabled = enable;
    }
    function setSellEnabled(bool enable) external onlyTradeController {
        blockConfig.sellEnabled = enable;
    }
    function getPriceInfo() external view returns (
        uint128 currentPrice,
        uint128 historicalHighPrice,
        uint32 lastDay,
        uint32 offset,
        uint64 lastUpdateBlock,
        uint256 realTimePrice
    ) {
        PriceTracker memory tracker = priceTracker;
        return (
            tracker.currentPrice,
            tracker.historicalHighPrice,
            tracker.lastDay,
            tracker.offset,
            tracker.lastUpdateBlock,
            getTokenPrice()
        );
    }
    function _addLpProvider(address addr) private {
        if (addr == address(0) || addr == address(0xdead)) return;
        if (excludeLpProvider[addr]) return;
        if (lpProviderIndex[addr] == 0) {
            if (lpProviders.length == 0 || lpProviders[0] != addr) {
                lpProviderIndex[addr] = lpProviders.length;
                lpProviders.push(addr);
            }
        }
    }
    function _processUnifiedLPReward(bool isUsdtReward) private {
        LPConfig storage config = isUsdtReward ? lpConfig : tokenLPConfig;
        if (config.progressBlock + REWARD_INTERVAL > block.number) {
            return;
        }
        uint256 rewardCondition = config.rewardCondition;
        uint256 availableBalance;
        TokenDistributor distributor;
        address rewardToken;
        if (isUsdtReward) {
            distributor = lpDistributor;
            rewardToken = usdt;
            availableBalance = IERC20(usdt).balanceOf(address(lpDistributor));
        } else {
            distributor = tokenDistributor;
            rewardToken = address(this);
            availableBalance = balanceOf(address(tokenDistributor));
        }
        if (availableBalance < rewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply() - holdToken.balanceOf(address(0xdead));
        if (holdTokenTotal == 0) {
            return;
        }
        address shareHolder;
        uint256 pairBalance;
        uint256 amount;
        uint256 shareholderCount = lpProviders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < rewardGasLimit && iterations < shareholderCount) {
            if (config.currentIndex >= shareholderCount) {
                config.currentIndex = 0;
            }
            shareHolder = lpProviders[config.currentIndex];
            if (!excludeLpProvider[shareHolder] && shareHolder != address(0xdead)) {
                pairBalance = holdToken.balanceOf(shareHolder);
                if (pairBalance > 0) {
                    if (isUsdtReward) {
                        unchecked {
                            amount = (rewardCondition * pairBalance) / holdTokenTotal;
                        }
                    } else {
                        amount = rewardCondition * pairBalance / holdTokenTotal;
                    }
                    if (amount > 0) {
                        distributor.claimToken(rewardToken, shareHolder, amount);
                    }
                }
            }
            gasUsed += (gasLeft - gasleft());
            gasLeft = gasleft();
            config.currentIndex++;
            iterations++;
        }
        config.progressBlock = uint64(block.number);
    }
    function _processNodeReward(uint256 nodeType, uint256 gas) private {
        if (address(node) == address(0)) return;
        if (progressNodeRewardBlock[nodeType] + REWARD_INTERVAL > block.number) {
            return;
        }
        address distributorAddress;
        if (nodeType == 0) distributorAddress = address(silverDistributor);      
        else if (nodeType == 1) distributorAddress = address(goldDistributor);   
        else if (nodeType == 2) distributorAddress = address(diamondDistributor); 
        else return;
        uint256 balance = IERC20(usdt).balanceOf(distributorAddress);
        if (balance < nodeRewardCondition) return;
        address[] memory holders = node.getNodeHolders(nodeType);
        uint256 totalHolders = holders.length;
        if (totalHolders == 0) return;
        uint256 amount = nodeRewardCondition / totalHolders;
        if (amount == 0) return;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        progressNodeRewardBlock[nodeType] = block.number;
        while (gasUsed < gas && iterations < totalHolders) {
            if (currentNodeIndex[nodeType] >= totalHolders) {
                currentNodeIndex[nodeType] = 0;
            }
            address holder = holders[currentNodeIndex[nodeType]];
            if (holder != address(0) && holder != address(0xdead)) {
                TokenDistributor(distributorAddress).claimToken(usdt, holder, amount);
            }
            gasUsed += (gasLeft - gasleft());
            gasLeft = gasleft();
            currentNodeIndex[nodeType]++;
            iterations++;
        }
    }
    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpConfig.rewardCondition = uint128(amount);
    }
    function setLPCondition(uint256 amount) external onlyOwner {
        lpConfig.minCondition = uint128(amount);
    }
    function setTokenLPRewardCondition(uint256 amount) external onlyOwner {
        tokenLPConfig.rewardCondition = uint128(amount);
    }
    function setTokenLPCondition(uint256 amount) external onlyOwner {
        tokenLPConfig.minCondition = uint128(amount);
    }
    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }
    function setNode(address addr) external onlyOwner {
        node = INode(addr);
    }
    function setNodeRewardCondition(uint256 condition) external onlyOwner {
        nodeRewardCondition = uint128(condition);
    }
    function setRewardGasLimit(uint256 gas) external onlyOwner {
        require(gas >= 200000 && gas <= 2000000, "Gas must be 200k-2M");
        rewardGasLimit = uint32(gas);
    }
    function getDistributors() external view returns (
        address marketingAddr,
        address lpDistributorAddr,
        address silverDistributorAddr,
        address goldDistributorAddr,
        address diamondDistributorAddr,
        address liquidityProviderAddr
    ) {
        return (
            marketingAddress,
            address(lpDistributor),
            address(silverDistributor),
            address(goldDistributor),
            address(diamondDistributor),
            address(liquidityProvider)
        );
    }
}
contract Token is AbsToken {
    constructor()
        AbsToken(
            "TOPS",
            "TOPS", 
            18,
            210_000_000,
            address(0x8f8785924cbbC7df57e5aBC3ed12277126A2Fb34),
            address(0xaa7c01f9DE1f14001Ad4aa4e8EBEf4Cc07cb1513),
            address(0x4aC4Dcc85895c762dF28726f52484dDE83789CD1),
            address(0x6bf0c0F1a8D3a6068e99B6D34E9bC99389e57c9e)
        )
    {}
}
