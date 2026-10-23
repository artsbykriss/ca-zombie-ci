// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");    
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IU {
    function getTopLine(address user) external view returns(address[] memory);
    function getUserTop(address user)external view returns (address);
}
interface IToken is IERC20 {
    function recycle(uint256 amount) external;
}
interface IReward {
    function getDynamicAmt(address account) external view returns (uint256);
    function getRewardRate()external view returns (uint256);
}
contract Stake is Ownable, ReentrancyGuard {
    using Address for address;

    uint256 public constant decimals = 18;
    string public constant name = "LV";
    string public constant symbol = "LV";
    uint256 private constant REWARD_PRECISION = 1e18;

    address public immutable USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public immutable WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public immutable deadAddress = address(0xdead);
    IUniswapV2Router02 public uniswapV2Router;
    IToken private token;
    IERC20 private usd = IERC20(USDT);
    IU private uc;
    IReward rc;
    address pair;

    uint256 addRate = 100;
    uint256 minInAmt = 50 ether;
    uint256 maxInAmt = 3000 ether;
    uint256 validAmt = 100 ether;

    uint256 rewardId = 1;
    uint256 nextCalculateTime;
    uint256 rewardRate = 20;
    uint256 dynamicRate = 500;
    uint256 rewardInterval = 1 days;
    uint256 topRate = 120;

    uint256 maxSellAmt = 2000000 ether;
    address commAddr;
    uint256 commRate = 30;
    address markAddr;
    uint256 markRate = 20;

    address lpRewardAddr;

    uint256 totalInAmt;
    uint256 totalOutAmt;
    uint256 totalStakeAmt;

    struct Order {
        uint128 inAmt;
        uint128 outAmt;
        bool status;
    }

    struct Reward {
        uint256 pAmt;
        uint256 tAmt;
        uint256 totalInAmt;
    }
    mapping(uint256 => uint256) private accRewardPerIn;

    struct User {
        uint128 inAmt;
        uint128 outAmt;
        uint128 stakeAmt;
        uint64 claimId;
        uint64 resetId;
    }

    mapping(address => uint256) private balances;
    mapping(address => Order[]) orderInfo;
    mapping(address => uint256) orderIndex;
    mapping(address => uint256) stakeCount;
    mapping(address => uint256) stakeCountResetId;
    mapping(address => uint256) stakeIndex;
    mapping(address => bool) isStake;
    mapping(address => uint256) userDynamicAmt;
    mapping(uint256 => Reward) rewardInfo;
    mapping(address => User) userInfo;

    address[] stakeList;

    uint256 resetId = 1;
    uint256 resetTime = 90 days;
    uint256 resetAmt = 20000 ether;
    uint256 nextResetTime;
    constructor() Ownable(_msgSender()) {
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usd.approve(address(uniswapV2Router), type(uint256).max);
        nextResetTime = block.timestamp + resetTime;
    }

    function setBaseContracts(address _token, address _uc,  address _commAddr,address _markAddr,address _lpRewardAddr,address _rc,address _pair) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_uc != address(0), "Invalid uc address");
        require(_commAddr != address(0), "Invalid comm address");
        require(_lpRewardAddr != address(0), "Invalid rc address");
        require(_rc != address(0), "Invalid rc address");
        require(_pair != address(0), "Invalid pair address");
        token = IToken(_token);
        uc = IU(_uc);
        commAddr = _commAddr;
        markAddr = _markAddr;
        require(token.approve(address(uniswapV2Router), type(uint256).max), "Approve token failed");

        lpRewardAddr = _lpRewardAddr;

        rc = IReward(_rc);
        pair = _pair;
    }

    function setAmountConfig(uint256 _minInAmt, uint256 _maxInAmt, uint256 _validAmt, uint256 _maxSellAmt) external onlyOwner {
        require(_minInAmt > 0, "Invalid min amount");
        require(_maxInAmt >= _minInAmt, "Invalid max amount");
        require(_validAmt > 0, "Invalid valid amount");
        require(_maxSellAmt > 0, "Invalid max sell amount");

        minInAmt = _minInAmt;
        maxInAmt = _maxInAmt;
        validAmt = _validAmt;
        maxSellAmt = _maxSellAmt;
    }

    function setRateConfig(
        uint256 _addRate,
        uint256 _rewardRate,
        uint256 _commRate,
        uint256 _markRate,
        uint256 _topRate,
        uint256 _dynamicRate
    ) external onlyOwner {
        require(_addRate > 0 && _addRate <= 500, "Invalid add rate");
        require(_rewardRate > 0, "Invalid reward rate");
        require(_commRate <= 1000, "Invalid comm rate");
        require(_topRate <= 1000, "Invalid top rate");
        require(_dynamicRate <= 1000, "Invalid dynamic rate");

        addRate = _addRate;
        rewardRate = _rewardRate;
        commRate = _commRate;
        markRate = _markRate;
        topRate = _topRate;
        dynamicRate = _dynamicRate;
    }

    function setTimeConfig(uint256 _rewardInterval,uint256 _resetTime,uint256 _resetAmt,uint256 _nextResetTime) external onlyOwner {
        require(_rewardInterval > 100, "Invalid reward interval");
        require(_resetTime > 0, "Invalid reset interval");
        require(_resetAmt > 0, "Invalid reset amount");
        require(_nextResetTime > 0, "Invalid next reset time");
        rewardInterval = _rewardInterval;
        resetTime = _resetTime;
        resetAmt = _resetAmt;
        nextResetTime = block.timestamp + _nextResetTime;
    }

    function setAddUsersOrder(address[] calldata accounts,uint256[] calldata inAmts)external onlyOwner{
        uint256 len = accounts.length;
        require(len > 0, "len fail");
        require(len == inAmts.length,"len fail");
        for (uint256 i = 0; i < len; ) {
            address account = accounts[i];
            uint256 inAmt = inAmts[i];
            require(account != address(0), "account fail");
            require(inAmt > 0, "amount fail");

            uint256 stakeU = inAmt * 90 / 100;
            uint256 out = inAmt * 2;
            _addUserOrder(account,stakeU,inAmt,out);
            unchecked { ++i; }
        }
    }
    function getInConfig()external view returns (uint256,uint256){
        return (minInAmt,maxInAmt);
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        uint256 allReward = getAllReward(account);
        if(allReward > 3 ether){
            return allReward;
        }else {
            return 3 ether;
        }
    }
    function getAllReward(address account)public view returns (uint256){
        User storage u = userInfo[account];
        if(u.resetId != resetId) return 0;
        uint256 staticRew = staticReward(u.claimId,u.inAmt);
        return balances[account] + staticRew + dynamicReward(account);
    }

    function getRewardConfig() external view returns (uint256, uint256, uint256) {
        return (rewardId, nextCalculateTime, rewardInterval);
    }
    function getResetConfig()external view returns (uint256,uint256,uint256,uint256){
        return (resetId,resetTime,resetAmt,nextResetTime);
    }
    function getRewardId()external view returns (uint256){
        return rewardId;
    }

    function getTotalInfo() external view returns (uint256, uint256, uint256, uint256) {
        return (totalInAmt, totalOutAmt, totalStakeAmt, stakeList.length);
    }
    function getIsStake(address account)external view returns (bool){
        return _isCurrentStake(account);
    }
    function getUserInfo(address account) external view returns (User memory u,uint256,uint256,uint256, bool, uint256) {
        u = userInfo[account];
        return (u, staticReward(u.claimId,u.inAmt),balances[account], dynamicReward(account), _isCurrentStake(account), _currentStakeCount(account));
    }

    function getOrderIndex(address account)external view returns (uint256){
        return orderIndex[account];
    }
    function getUserDynamicAmt(address account) external view returns (uint256) {
        return userDynamicAmt[account];
    }

    function getUserOrders(address account) external view returns (Order[] memory os) {
        Order[] storage orders = orderInfo[account];
        uint256 startIndex = orderIndex[account];
        uint256 endIndex = orders.length;
        if (startIndex >= endIndex) {
            return new Order[](0);
        }

        uint256 len = endIndex - startIndex;
        if(len >30){
            len = 30;
            endIndex = startIndex +30;
        }
        os = new Order[](len);
        for (uint256 i = 0; i < len; ) {
            os[i] = orders[startIndex + i];
            unchecked { ++i; }
        }
    }

    function getUserOrderInfo(address account, uint256 index) external view returns (Order memory) {
        return orderInfo[account][index];
    }

    function getRewardInfo(uint256 id) external view returns (Reward memory) {
        return rewardInfo[id];
    }

    function getLastRewardInfo() external view returns (uint256,Reward memory,uint256) {
        return (rewardId,rewardInfo[rewardId],accRewardPerIn[rewardId]);
    }

    receive() external payable nonReentrant {
        address account = _msgSender();
        uint256 val = msg.value;
        require(val > 0, "val is 0");

        uint256 beforeUSDT = usd.balanceOf(address(this));
        _swapBNBForToken(val);
        uint256 deltaUSDT = usd.balanceOf(address(this)) - beforeUSDT;
        require(deltaUSDT > 0, "no usdt in");

        _addStakeOrder(account, deltaUSDT);
    }

    function usdtForAddStakeOrder(uint256 inAmt) external nonReentrant {
        require(inAmt >= minInAmt && inAmt <= maxInAmt, "amount fail");

        address account = _msgSender();
        require(tx.origin == account, "account fail");
        require(usd.balanceOf(account) >= inAmt, "user balance fail");

        require(usd.transferFrom(account, address(this), inAmt), "TransferFrom failed");
        _addStakeOrder(account, inAmt);
    }

    function calculateReward() external nonReentrant{
        checkReset();
        triggerReward();
    }
    function triggerReward()private {
        if (block.timestamp < nextCalculateTime + rewardInterval - 20) return;
        if(totalInAmt == 0) return;
        uint256 latestRewardRate = rc.getRewardRate();
        require(latestRewardRate > 0, "Invalid reward rate");
        if(latestRewardRate != rewardRate ){
            rewardRate = latestRewardRate;
        }
        uint256 daysReward = (totalInAmt * rewardRate) / 1000;
        uint256 bal = getTokenAmountByPairPrice(daysReward);

        uint256 rewardPerIn = (bal * REWARD_PRECISION) / totalInAmt;
        nextCalculateTime = block.timestamp;

        rewardId++;
        Reward storage r = rewardInfo[rewardId];
        r.pAmt = bal;
        r.tAmt = bal * dynamicRate / 1000;
        r.totalInAmt = totalInAmt;
        accRewardPerIn[rewardId] = accRewardPerIn[rewardId - 1] + rewardPerIn;
    }
    function checkReset()private {
        if (block.timestamp < nextResetTime) return;
        if (pair == address(0)) return;
        nextResetTime = block.timestamp + resetTime;
        if(usd.balanceOf(pair) < resetAmt){
            resetId ++;
            totalInAmt = 0;
            totalOutAmt = 0;
            nextCalculateTime = block.timestamp;
            delete stakeList;
        }
    }

    function transfer(address to, uint256 value) public virtual nonReentrant returns (bool) {
        address account = _msgSender();
        require(!isContract(account) && tx.origin == account, "not is contract");
        require(to != address(9),"to fail");
        checkReset();
        
        if(value == 3 ether){
            redeemOrder(account);
        }else {
            sell(account);
        }
        triggerReward();
        return true;
    }
    
    function dynamicReward(address account)private view returns (uint256){
        uint256 damt = rc.getDynamicAmt(account);

        if(userDynamicAmt[account] < damt){
            return damt - userDynamicAmt[account];
        }else {
            return 0;
        }
    }
    function _addStakeOrder(address account, uint256 inAmt) private {
        checkReset();
        
        User memory u = userInfo[account];
        if(u.resetId != 0 && u.resetId != resetId){
            require(u.stakeAmt == 0,"stake amount not 0");
            _clearExpiredUser(account);
            u = userInfo[account];
        }
        require(u.claimId == 0 || rewardId == u.claimId || (u.inAmt == 0 && u.outAmt == 0), "pending rewards fail");
        require(inAmt >= minInAmt && inAmt <= maxInAmt, "amount fail");
        require(tx.origin == account, "account fail");
        require(!isContract(account), "account fail");

        uint256 inAmtOrTokenAmt = getTokenOut(USDT,address(token), inAmt);

        uint256 usdtToTokenAmount = (inAmt * addRate) / 1000;
        uint256 beforeToken = token.balanceOf(address(this));
        if (usdtToTokenAmount > 0) {
            swapTokensForTokens(USDT, address(token), usdtToTokenAmount);
        }
        uint256 deltaToken = token.balanceOf(address(this)) - beforeToken;

        _addLiquify(usdtToTokenAmount, deltaToken);

        uint256 stakeU = inAmt - (usdtToTokenAmount * 2);
        uint256 out = inAmt * 2;
        _addUserOrder(account,stakeU,inAmt,out);

        uint256 _topReward = (inAmtOrTokenAmt * topRate) / 1000 / 15;
        topReward(account, _topReward);

        triggerReward();
    }
    function resetUser()external nonReentrant {
        address account = _msgSender();
        User storage u = userInfo[account];
        require(u.resetId != 0, "no user");
        require(u.stakeAmt == 0,"stake amount fail");
        require(u.resetId != resetId,"reset id ==");
        if (balances[account] > 0) {
            delete balances[account];
        }
        
        userDynamicAmt[account] = rc.getDynamicAmt(account);
        
        if (_isCurrentStake(account)) {
            isStake[account] = false;
            stakeQuit(account);
            address top = uc.getUserTop(account);
            if (top != address(0)) {
                _decreaseStakeCount(top);
            }
        } else if (isStake[account]) {
            isStake[account] = false;
        }
        delete orderInfo[account];
        delete orderIndex[account];
        delete userInfo[account];
    }
    function redeemOrder(address account)private {
        
        User storage u = userInfo[account];
        require(u.stakeAmt > 0,"stake amount fail");

        uint256 stakeAmt = u.stakeAmt;
        uint256 inAmt = u.inAmt;
        uint256 outAmt = u.outAmt;
        bool currentRound = u.resetId == resetId;
        require(usd.balanceOf(address(this)) >= stakeAmt,"this usdt balance fail");

        if (balances[account] > 0) {
            delete balances[account];
        }
        
        userDynamicAmt[account] = rc.getDynamicAmt(account);
    
        if (currentRound) {
            totalInAmt = totalInAmt >= inAmt ? totalInAmt - inAmt : 0;
            totalOutAmt = totalOutAmt >= outAmt ? totalOutAmt - outAmt : 0;
        }
        totalStakeAmt = totalStakeAmt >= stakeAmt ? totalStakeAmt - stakeAmt : 0;
        
        if (_isCurrentStake(account)) {
            isStake[account] = false;
            stakeQuit(account);
            address top = uc.getUserTop(account);
            if (top != address(0)) {
                _decreaseStakeCount(top);
            }
        } else if (isStake[account]) {
            isStake[account] = false;
        }
        delete orderInfo[account];
        delete orderIndex[account];
        delete userInfo[account];

        require(usd.transfer(account, stakeAmt), "Transfer failed");
    }

    function _addUserOrder(address account, uint256 stakeU,uint256 inAmt,uint256 out)private {
        require(account != address(0), "account fail");
        require(inAmt > 0, "amount fail");
        if (totalInAmt == 0 && nextCalculateTime == 0) {
            nextCalculateTime = block.timestamp;
        }

        Order[] storage os = orderInfo[account];

        Order memory o = Order({
            inAmt: uint128(inAmt),
            outAmt: uint128(out),
            status: true
        });
        os.push(o);

        User storage u = userInfo[account];
        
        u.inAmt += uint128(inAmt);
        u.outAmt += uint128(out);
        u.stakeAmt += uint128(stakeU);

        u.claimId = uint64(rewardId);
        u.resetId = uint64(resetId);

        totalInAmt += inAmt;
        totalOutAmt += out;
        totalStakeAmt += stakeU;

        if (!_isCurrentStake(account) && u.inAmt >= validAmt) {
            isStake[account] = true;
            stakeJoin(account);
            address top = uc.getUserTop(account);
            if (top != address(0)) {
                _increaseStakeCount(top);
            }
        }
    }

    function stakeJoin(address account) private {
        stakeIndex[account] = stakeList.length;
        stakeList.push(account);
    }

    function stakeQuit(address account) private {
        uint256 index = stakeIndex[account];
        address last = stakeList[stakeList.length - 1];
        stakeList[index] = last;
        stakeIndex[last] = index;
        stakeList.pop();
        delete stakeIndex[account];
    }

    function _isCurrentStake(address account) private view returns (bool) {
        return isStake[account] && userInfo[account].resetId == resetId;
    }

    function _currentStakeCount(address account) private view returns (uint256) {
        if (stakeCountResetId[account] != resetId) {
            return 0;
        }
        return stakeCount[account];
    }

    function _increaseStakeCount(address account) private {
        if (stakeCountResetId[account] != resetId) {
            stakeCountResetId[account] = resetId;
            stakeCount[account] = 0;
        }
        unchecked {
            stakeCount[account]++;
        }
    }

    function _decreaseStakeCount(address account) private {
        if (stakeCountResetId[account] != resetId) {
            return;
        }
        if (stakeCount[account] > 0) {
            unchecked {
                stakeCount[account]--;
            }
        }
    }

    function _clearExpiredUser(address account) private {
        if (balances[account] > 0) {
            delete balances[account];
        }
        userDynamicAmt[account] = rc.getDynamicAmt(account);
        if (isStake[account]) {
            isStake[account] = false;
        }
        delete orderInfo[account];
        delete orderIndex[account];
        delete userInfo[account];
    }

    function staticReward(uint256 cid, uint256 amt) private view returns(uint256){
        
        if (cid == 0) {
            return 0;
        }
        if (cid >= rewardId || amt == 0) return 0;
        return ((accRewardPerIn[rewardId] - accRewardPerIn[cid]) * amt) / REWARD_PRECISION;
    }

    function sell(address account) private {
        uint256 sellAmt = getAllReward(account);
        userDynamicAmt[account] = rc.getDynamicAmt(account);
        require(sellAmt > 0, "sell amount fail");

        User storage u = userInfo[account];
        require(u.resetId == resetId,"reset id fail");
        u.claimId = uint64(rewardId);
        require(u.outAmt > 0, "out amount fail");
        balances[account] = 0;
        if (sellAmt > maxSellAmt) {
            sellAmt = maxSellAmt;
        }

        uint256 maxU = getTokenOut(address(token), USDT, sellAmt);
        require(token.balanceOf(address(this)) >= sellAmt,"sell balance fail");
        uint256 deltaU;
        if (maxU > u.outAmt) {
            uint256 beforeU = usd.balanceOf(address(this));
            sellAmt = outSwapTokensForTokens(u.outAmt, sellAmt);
            deltaU = usd.balanceOf(address(this)) - beforeU;

            require(deltaU <= u.outAmt, "out usdt fail");
            totalOutAmt = totalOutAmt >= u.outAmt ? totalOutAmt - u.outAmt : 0;

            u.outAmt = 0;
            uint256 last = orderIndex[account];
            outOrder(account, last, 0, true);

            totalInAmt = totalInAmt >= u.inAmt ? totalInAmt - u.inAmt : 0;
            u.inAmt = 0;
            if (_isCurrentStake(account)) {
                isStake[account] = false;
                stakeQuit(account);
                address top = uc.getUserTop(account);
                if (top != address(0)) {
                    _decreaseStakeCount(top);
                }
            }
        } else {
            uint256 beforeU = usd.balanceOf(address(this));
            swapTokensForTokens(address(token), USDT, sellAmt);
            deltaU = usd.balanceOf(address(this)) - beforeU;

            require(deltaU <= u.outAmt, "out usdt fail");
            totalOutAmt = totalOutAmt >= deltaU ? totalOutAmt - deltaU : 0;
            u.outAmt -= uint128(deltaU);

            uint256 last = orderIndex[account];
            uint256 addInAmt = outOrder(account, last, deltaU, false);
            totalInAmt = totalInAmt >= addInAmt ? totalInAmt - addInAmt : 0;
            u.inAmt -= uint128(addInAmt);
        }

        uint256 cfee = deltaU * commRate / 1000;
        uint256 mfee = deltaU * markRate / 1000;
        uint256 userU = deltaU - cfee - mfee;
        require(usd.transfer(commAddr, cfee), "Transfer fee failed");
        require(usd.transfer(markAddr, mfee), "Transfer fee failed");
        require(usd.transfer(account, userU), "Transfer user failed");
        token.recycle(sellAmt);

        if (u.stakeAmt > 0) {
            uint256 stakeReduce;
            if (deltaU > u.stakeAmt) {
                stakeReduce = u.stakeAmt;
                u.stakeAmt = 0;
            } else {
                stakeReduce = deltaU;
                u.stakeAmt -= uint128(deltaU);
            }
            totalStakeAmt = totalStakeAmt >= stakeReduce ? totalStakeAmt - stakeReduce : 0;
            uint256 beforeToken = token.balanceOf(address(this));
            swapTokensForTokens(USDT, address(token), stakeReduce);
            uint256 deltaToken = (token.balanceOf(address(this)) - beforeToken) / 2;
            
            require(token.transfer(lpRewardAddr, deltaToken), "Transfer lp reward failed");
            require(token.transfer(deadAddress, deltaToken), "Transfer dead Address failed");
        }
    }

    function outOrder(address account, uint256 startId, uint256 outAmt, bool isOut) private returns (uint256 addInAmt) {
        Order[] storage os = orderInfo[account];
        require(os.length > 0, "not order");

        uint256 i = startId;
        for (; i < os.length; ) {
            Order storage o = os[i];
            if (!o.status || o.outAmt == 0) {
                unchecked { ++i; }
                continue;
            }
            if (isOut) {
                o.outAmt = 0;
                o.status = false;
            } else if (outAmt > 0 && outAmt >= o.outAmt) {
                uint256 orderOutAmt = o.outAmt;
                outAmt -= orderOutAmt;
                o.outAmt = 0;
                o.status = false;

                addInAmt += o.inAmt;
            } else if (outAmt > 0 && outAmt < o.outAmt) {
                o.outAmt -= uint128(outAmt);
                outAmt = 0;
                break;
            } else {
                break;
            }

            unchecked { ++i; }
        }
        if (i > orderIndex[account]) {
            orderIndex[account] = i;
        }
        return addInAmt;
    }

    function topReward(address user, uint256 amount) private {
        address[] memory line = uc.getTopLine(user);
        uint256 L = line.length;
        if (amount == 0 || L <= 1) return;

        uint256 ancestors = L - 1;
        uint256 maxLevels = ancestors > 15 ? 15 : ancestors;
        uint256 start = ancestors - maxLevels;
        for (uint256 i = start; i < ancestors; ) {
            address upline = line[i];
            if (upline != address(0)) {
                uint256 d = (L - 1) - i;
                if (_currentStakeCount(upline) >= d && _isCurrentStake(upline)) {
                    balances[upline] += amount;
                }
            }
            unchecked { ++i; }
        }
    }

    function getTokenOut(address token0, address token1, uint256 amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            amount,
            path
        );
        return price[1];
    }

    function getTokenAmountByPairPrice(uint256 usdtAmount) internal view returns (uint256) {
        if (usdtAmount == 0) {
            return 0;
        }
        require(pair != address(0), "Pair not set");

        IUniswapV2Pair p = IUniswapV2Pair(pair);
        address token0 = p.token0();
        address token1 = p.token1();
        require(
            (token0 == USDT && token1 == address(token)) || (token0 == address(token) && token1 == USDT),
            "Invalid pair tokens"
        );

        (uint112 reserve0, uint112 reserve1,) = p.getReserves();
        uint256 reserveU = token0 == USDT ? uint256(reserve0) : uint256(reserve1);
        uint256 reserveT = token0 == USDT ? uint256(reserve1) : uint256(reserve0);
        require(reserveU > 0 && reserveT > 0, "Invalid pair reserves");

        return (usdtAmount * reserveT) / reserveU;
    }

    function swapTokensForTokens(address tokenIn, address tokenOut, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }
    function outSwapTokensForTokens(uint256 outAmt, uint256 maxTokenIn) private returns (uint256){
        require(outAmt > 0, "out amount fail");
        require(maxTokenIn > 0, "token amount fail");

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = USDT;
        uint256 bal = token.balanceOf(address(this));
        uniswapV2Router.swapTokensForExactTokens(
            outAmt,
            maxTokenIn,
            path,
            address(this),
            block.timestamp + 300
        );
        return bal - token.balanceOf(address(this));
    }

    function _swapBNBForToken(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = USDT;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function _addLiquify(uint256 usdtAmount, uint256 tokenAmount) private {
        uniswapV2Router.addLiquidity(
            address(token),
            USDT,
            tokenAmount,
            usdtAmount,
            0,
            0,
            deadAddress,
            block.timestamp + 300
        );
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function withdrawBNB(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid receiver address");
        require(amount > 0, "Invalid amount");
        Address.sendValue(payable(to), amount);
    }

    function withdrawToken(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid receiver address");
        require(amount > 0, "Invalid amount");
        require(IERC20(tokenAddress).transfer(to, amount), "Withdraw token failed");
    }
}
