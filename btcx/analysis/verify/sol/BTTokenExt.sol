//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
interface IToken{
    /// @notice 用户信息
    struct User {
        address superior;           // 上级地址
        uint8   nodeLevel;          // 节点等级 0=无，1=V1，2=V2，3=V3, 4=v4, 5=v5
        uint256 lpAmount;           // LP 代币数量
        uint256 usdtValue;          // USDT 面值
        uint256 depositCycle;       // 入场周期
        uint256 hashrateStatic;     // 静态算力
        uint256 hashrateDynamic;    // 动态算力
        uint256 staticReceived;     // 静态已领取（累计）
        uint256 dynamicReceived;    // 动态已领取（累计）
        uint256 nodeWBTCReceived;   // 节点WBTC已领取
        uint256 nodeBTReceived;    // 节点OG已领取
        uint256 validReferralCount; // 有效下级数量（直推且已入金的用户）
        uint256 hashrateReward;
    }
    /// @notice 用户领奖周期记录
    struct UserLast {
        uint256 lastStaticCycle;    // 上次静态领奖周期
        uint256 lastDynamicCycle;   // 上次动态领奖周期
        uint256 lastNodeWBTCCycle;  // 上次节点WBTC领奖周期
        uint256 lastNodeBTCycle;   // 上次节点OG领奖周期
    }
    function getHourlyCycle()external view returns(uint256);
    function hourlyCycleStaticHashrate(uint256 p)external view returns(uint256);
    function dailyCycleDynamicHashrate(uint256 p)external view returns(uint256);
    function hourlyCycleStaticReward(uint256 p)external view returns(uint256);
    function dailyCycleDynamicReward(uint256 p)external view returns(uint256);
    function usersCycleStaticHashrate(address u,uint256 p)external view returns(uint256);
    function usersCyclelDynamicHashrate(address u,uint256 p)external view returns(uint256);
    function getDailyCycle()external view returns(uint256);
    function pancakePair()external view returns(address);
    function users(address ur)external view returns(User memory);
    function userLasts(address ur)external view returns(UserLast memory);
    function balanceOf(address ur)external view returns(uint256);
    function wbtcReward(address ur)external view returns(uint256);
    function usersCyclelNodeLevel(address u,uint256 p)external view returns(uint256);
    function dailyCycleNodeCount(uint256 u,uint256 p)external view returns(uint256);
    function dailyCycleNodeRewards(uint256 u,uint256 p)external view returns(uint256);
    function pricePerHour(uint u)external view returns(uint256);
    function userReward(address u)external view returns(uint256);
    function userLastSellTime(address u)external view returns(uint256);
    function userSellAmount(address u)external view returns(uint256);
}
contract BTTokenExt{
    /// @notice 用于计算用户队列排在第几天。
    uint256 [] public currentLimit = [100, 210, 331, 464, 610, 770, 946, 1134, 1322];
    /// @notice 基础比例分母
    uint256 private constant BASE = 100000;
    address public BT_TOKEN;
    address public pancakePair;
    /// @notice PancakeSwap Router V2 (BSC Mainnet)
    address public immutable ROUTER ;
    
    /// @notice USDT 代币地址 (BSC)
    address public immutable USDT ;
    
    /// @notice WBTC 代币地址 (BSC)
    address public immutable WBTC ;

    address public immutable WBNB ;

    /// @notice 5TH token address (持仓检查)
    address public constant FIFTH_TOKEN = 0x850026ad9Ece0505A45148b843CC338a77405555;
    
    address public constant PANCAKE_V3_ROUTER = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    
    /// @notice 早期用户分红记账
    uint256 public earlierUserRewardPerShare;

    mapping(address =>uint256) public rewardOfuser;
    uint256 public userNumber;

    mapping(address =>bool) public isEarlierUser;
    mapping(uint256=>uint256) public numberOfDay;

    constructor(address _BTToken){
        BT_TOKEN =  _BTToken;
        pancakePair=IToken(BT_TOKEN).pancakePair();
        WBTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;  // BSC WBTC
        ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;      // PancakeSwap Router V2
        USDT= 0x55d398326f99059fF775485246999027B3197955;
        WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }
    /**
     * @notice 24小时最高单价
     * @return highPrice 最高单价
     */
    function gethighPrice(uint256 currentCycle)public view returns(uint256 highPrice){
        highPrice = IToken(BT_TOKEN).pricePerHour(currentCycle);
        if (currentCycle==0) return highPrice;
        for(uint256 cycle = currentCycle-1; cycle>0 ; cycle--){
            if (IToken(BT_TOKEN).pricePerHour(cycle)>highPrice) highPrice=IToken(BT_TOKEN).pricePerHour(cycle);
            if(currentCycle > 24) {
                if (cycle < currentCycle - 24) break;
            }
        }
    }
    function _limitAtDay(uint256 day) internal view returns (uint256) {
        uint256 lastLimit = currentLimit[8]; // 10626
        if (day <= 8) return currentLimit[day];
        return lastLimit + (day - 8) * 188;
    }
    
    function _approveWBTC(address spender, uint256 amount) internal {
        IERC20(WBTC).approve(spender, amount);
    }

    function buyBT(uint256 wbtcAmount) public returns (uint256) {
        require(msg.sender == BT_TOKEN, "caller is not BT token");
        // 设置交易路径：WBTC → BT
        address[] memory path = new address[](2);
        path[0] = WBTC;
        path[1] = BT_TOKEN;

        // 授权Router使用WBTC
        _approveWBTC(ROUTER, wbtcAmount);

        uint256[] memory amounts = IPancakeRouter(ROUTER).swapExactTokensForTokens(
            wbtcAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        return amounts[1];
    }
    function buyWBTC(uint256 btAmount) public returns (uint256) {
        // 设置交易路径：BT → WBTC
        require(msg.sender == BT_TOKEN, "caller is not BT token");
        address[] memory path = new address[](2);
        path[1] = WBTC;
        path[0] = BT_TOKEN;

        // 授权Router使用BT
        IERC20(BT_TOKEN).approve(ROUTER, btAmount);
        // 先swap到中间地址，避免INVALID_TO错误
        // PancakeSwap不允许直接swap到代币合约自身，所以需要中间地址
        uint256[] memory amounts = IPancakeRouter(ROUTER).swapExactTokensForTokens(
            btAmount ,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        return amounts[1];
    }
    function swapWBTC(uint256 wbnbAmount) internal returns(uint256){
        return buyBTCBWithWBNB(wbnbAmount,0,address(this),500);
    }
    /**
     * @notice 处理bnb分配和构建LP
     * @dev 入金BNB的60%用于构建LP池，其中一半购买BT，一半保留WBTC
     * @dev 剩余的代币会转入LP池并同步，确保不浪费
     * @param bnbAmount 总bnb金额
     * @param user 入金用户地址
     * @return liquidity 返回获得的LP代币数量
     */
    function processBuildLP(uint256 bnbAmount, address user,uint8 flag) public returns (uint256,uint256) {
        require(msg.sender == BT_TOKEN, "Only main contract");
        uint btcvalue = swapWBTC(bnbAmount);

        // 60% 的 wbtc 用于构建 LP 池
        uint256 lpwbtc = (btcvalue * 60) / 100;
        if(flag == 0) lpwbtc = btcvalue;

        // 将 LP 用的 wbtc 分成两半：一半买 BT，一半保留 WBTC
        uint256 buyBTAmount = lpwbtc / 2;  // 30% 的总金额

        // 用 wbtc 在 PancakeSwap 上购买 BT 代币
        uint256 btAmount = buyBT(buyBTAmount);
        
        // 添加流动性：将 BT 和 WBTC 配对添加到 LP 池
        // 返回实际使用的 BT、WBTC 数量和获得的 LP 代币数量
        (uint256 usedBT, uint256 usedWBTC, uint256 liquidity) = _addLiquidity(btAmount, buyBTAmount, user);
        // 回转 40% 主合约分配
        if(flag > 0) IERC20(WBTC).transfer(BT_TOKEN, btcvalue * 40 / 100 );

        // 计算剩余的代币（由于价格波动，可能不会全部使用）
        uint256 remainingBT = btAmount >= usedBT ? btAmount - usedBT : 0;
        uint256 remainingWBTC = buyBTAmount >= usedWBTC ? buyBTAmount - usedWBTC : 0;
        
        uint256 store = IERC20(WBTC).balanceOf(address(this));
        if(remainingWBTC<store) remainingWBTC = store;
        
        // 将剩余代币转入交易对并同步，避免资金浪费
        // 这些剩余代币会增加 LP 池的深度，但不会产生新的 LP 代币
        bool needSync = false;
        if (remainingBT > 0) {
            IERC20(BT_TOKEN).transfer(pancakePair, remainingBT);
            needSync = true;
        }
        if (remainingWBTC > 0) {
            IERC20(WBTC).transfer(pancakePair, remainingWBTC);
            needSync = true;
        }
        // 如果有剩余代币转入，需要同步 LP 池的储备量
        if (needSync) {
            IPancakePair(pancakePair).sync();
        }

        return (liquidity,btcvalue);
    }
    function addLiquidity(uint256 btAmount, uint256 wbtcAmount, address lpReceiver) public returns (uint256, uint256, uint256){
        require(msg.sender == BT_TOKEN, "Only main contract");
        (uint256 usedBT, uint256 usedWBTC, uint256 liquidity) = _addLiquidity(btAmount, wbtcAmount, lpReceiver);
        // 计算剩余的代币（由于价格波动，可能不会全部使用）
        uint256 remainingBT = btAmount >= usedBT ? btAmount - usedBT : 0;
        uint256 remainingWBTC = wbtcAmount >= usedWBTC ? wbtcAmount - usedWBTC : 0;
        
        // 将剩余代币转入交易对并同步，避免资金浪费
        // 这些剩余代币会增加 LP 池的深度，但不会产生新的 LP 代币
        bool needSync = false;
        if (remainingBT > 0) {
            IERC20(BT_TOKEN).transfer(pancakePair, remainingBT);
            needSync = true;
        }
        if (remainingWBTC > 0) {
            IERC20(WBTC).transfer(pancakePair, remainingWBTC);
            needSync = true;
        }
        // 如果有剩余代币转入，需要同步 LP 池的储备量
        if (needSync) {
            IPancakePair(pancakePair).sync();
        }
        return(btAmount,wbtcAmount,liquidity);
    }
    function _addLiquidity(uint256 btAmount, uint256 wbtcAmount, address lpReceiver) internal returns (uint256, uint256, uint256) {
        // 授权Router使用BT和WBTC
        IERC20(BT_TOKEN).approve(ROUTER, btAmount);
        //require(btAmount <= IERC20(BT_TOKEN).balanceOf(address(this)));
        _approveWBTC(ROUTER, wbtcAmount);
        //require(wbtcAmount <= IERC20(WBTC).balanceOf(address(this)));

        // 添加流动性
        (uint256 usedBT, uint256 usedWBTC, uint256 liquidity) = IPancakeRouter(ROUTER).addLiquidity(
            BT_TOKEN,          // tokenA: BT
            WBTC,                   // tokenB: WBTC
            btAmount,              // amountADesired: 期望的BT数量
            wbtcAmount,             // amountBDesired: 期望的WBTC数量
            0,                      // amountAMin: BT最小数量
            0,                      // amountBMin: WBTC最小数量
            lpReceiver,             // to: LP代币接收地址（改为用户地址）
            block.timestamp + 300   // deadline: 截止时间
        );

        return (usedBT, usedWBTC, liquidity);
    }
    event QueueDay(uint256 index, uint256 currentDay);
    function getDay(uint256 index, uint256 currentDay) public returns (uint256){
        require(msg.sender == BT_TOKEN, "caller is not OG token");
        require(currentDay > 0, "currentDay=0");
        // currentDay 是“今天+1”
        uint256 today = currentDay - 1;
        
        uint todaylimit = numberOfDay[today];
        
        if (today>1) todaylimit+=_limitAtDay(today-1);

        if(todaylimit<_limitAtDay(today)){
            //今天的人数加1
            numberOfDay[today]+=1;
            return today;
        }
        uint i = currentDay;
        while(true){
            if((numberOfDay[i] + _limitAtDay(i-1)) < _limitAtDay(i)){
                numberOfDay[i] += 1;
                emit QueueDay(index,i);
                return i;
            }
            i+=1;
            require(i<currentDay+20,"Only 20 days");
        }
        return 0;
    }
    
    function getUserInfo(address user) public view returns (
        address superior,
        uint256 lpAmount,
        uint256 usdtValue,
        uint256 hashrateStatic,
        uint256 hashrateDynamic,
        uint8 nodeLevel,
        uint256 validReferralCount,
        uint256 usdtValueOfHashRateReward
    ) {
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        return (
            u.superior,
            u.lpAmount,
            u.usdtValue,
            u.hashrateStatic,
            u.hashrateDynamic,
            u.nodeLevel,
            u.validReferralCount,
            u.hashrateReward
        );
    }
    function getPendingRewards(address user) public view returns (
        uint256 staticReward,
        uint256 dynamicReward,
        uint256 nodeWBTCReward,
        uint256 nodeBTReward
    ) {
        // 使用统一的计算方法
        (staticReward,) = calculateStaticReward(user);
        dynamicReward = calculateDynamicReward(user);
        nodeWBTCReward = calculateNodeWBTCReward(user);
        nodeBTReward = calculateNodeBTReward(user);
    }
    function despositForEarlyUser(uint256 total,address user,uint8 control) public returns(uint256){
        require(msg.sender == BT_TOKEN,"caller is not OG token");
        //
        if(user!=address(0) && !isEarlierUser[user]) {
            // 首期建设者，最先达到C2的前100个用户。
            if(userNumber<100){
                isEarlierUser[user]=true;
                userNumber+=1;
                rewardOfuser[user] = earlierUserRewardPerShare;
            }
        }
        if(control==2 && isEarlierUser[user] ) rewardOfuser[user] = earlierUserRewardPerShare;
        // 将分配的资金 按人头均分
        if(total>0 && userNumber>0 ) earlierUserRewardPerShare += total/userNumber;
        return userNumber;
    }
    // ============ 核心功能：奖励计算 ============
    /**
     * @notice 计算节点 WBTC 奖励（周期）
     * @dev WBTC奖励来源：入金金额的5%，平均分配给C1/C2/C3/C4/C5五个等级
     * @dev 分配方式：按人数平分，每个节点用户获得相同数量的奖励
     * @dev 节点等级：
     * @dev 领取逻辑：只领取已完成燃烧的周期（currentDay - 1）
     * @param user 用户地址
     * @return 待领取的节点WBTC奖励数量
     */
    function calculateNodeWBTCReward(address user) public view returns (uint256) {
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        if (u.nodeLevel == 0) return 0;
        
        uint256 currentDay = IToken(BT_TOKEN).getDailyCycle();
        IToken.UserLast memory info = IToken(BT_TOKEN).userLasts(user);
        uint256 lastDay = info.lastNodeWBTCCycle;//userLasts[user].lastNodeWBTCCycle;
        
        // 第0周期不计算奖励
        if (currentDay == 0) return 0;
        
        // 只计算到 currentDay - 1（已完成燃烧的周期）
        uint256 calculateUntilDay = currentDay;
        if (lastDay >= calculateUntilDay) return 0; // 没有可计算的周期
        
        uint256 totalReward = 0;
        
        // 从上次领奖周期+1到当前周期-1
        for (uint256 day = lastDay; day < calculateUntilDay; day++) {
            // 获取用户在该周期的节点等级
            uint256 userNodeLevel = IToken(BT_TOKEN).usersCyclelNodeLevel(user,day);
            if (userNodeLevel == 0) continue; // 该周期不是节点，跳过
            
            uint256 nodeIdx = userNodeLevel - 1; // V1=0, V2=1, V3=2 V4=3, V5=4
            uint256 nodeCount = IToken(BT_TOKEN).dailyCycleNodeCount(day,nodeIdx);
            uint256 reward = IToken(BT_TOKEN).dailyCycleNodeRewards(day,nodeIdx);
            
            // 如果人数大于0且有奖励，则平分
            if (nodeCount > 0 && reward > 0) {
                totalReward += reward / nodeCount;
            }
        }
        
        return totalReward;
    }
    
    /**
     * @notice 计算节点 BT 奖励（周期）
     * @dev BT奖励来源：每小时底池燃烧量的0.5% × 5
     * @dev 分配方式：按人数平分，每个节点用户获得相同数量的奖励
     * @dev 节点等级：
     * @dev 领取逻辑：只领取已完成燃烧的周期（currentDay - 1）
     * @dev 如果周期未执行销毁，则累积模拟计算
     * @param user 用户地址
     * @return 待领取的节点BT奖励数量
     */
    function calculateNodeBTReward(address user) public view returns (uint256) {
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        if (u.nodeLevel == 0) return 0;
        
        uint256 currentDay = IToken(BT_TOKEN).getDailyCycle();
        IToken.UserLast memory info = IToken(BT_TOKEN).userLasts(user);
        uint256 lastDay = info.lastNodeBTCycle;//userLasts[user].lastNodeBTCycle;
        
        // 第0周期不计算奖励
        if (currentDay == 0) return 0;
        
        // 只计算到 currentDay - 1（已完成燃烧的周期）
        uint256 calculateUntilDay = currentDay;
        if (lastDay >= calculateUntilDay) return 0; // 没有可计算的周期
        
        uint256 totalReward = 0;
        
        // 用于累积模拟的池子余额
        uint256 simulatedPoolBalance = IToken(BT_TOKEN).balanceOf(pancakePair);//super.balanceOf(pancakePair);
        
        // 从上次领奖周期到当前周期
        for (uint256 day = lastDay; day < calculateUntilDay; day++) {
            // 获取用户在该周期的节点等级
            uint256 userNodeLevel = IToken(BT_TOKEN).usersCyclelNodeLevel(user,day);
            if (userNodeLevel == 0) continue; // 该周期不是节点，跳过
            
            uint256 nodeIdx = userNodeLevel - 1; 
            uint256 rewardIdx = nodeIdx + 5; 
            uint256 nodeCount = IToken(BT_TOKEN).dailyCycleNodeCount(day,nodeIdx);
            uint256 reward = IToken(BT_TOKEN).dailyCycleNodeRewards(day,rewardIdx);
            
            // 如果奖励未记录，累积模拟计算（1天）
            if (reward == 0 && nodeCount > 0) {
                uint256[10] memory nodeRewards;
                (nodeRewards, simulatedPoolBalance) = simulateNodeBTRewardsWithBalance(simulatedPoolBalance);
                reward = nodeRewards[rewardIdx];
            }
            
            // 如果人数大于0且有奖励，则平分
            if (nodeCount > 0 && reward > 0) {
                totalReward += reward / nodeCount;
            }
        }
        
        return totalReward;
    }
    
    /**
     * @notice 计算动态奖励（周期）
     * @dev 动态奖励来源：每底池燃烧量的15%
     * @dev 分配方式：按用户动态算力占比分配
     * @dev 动态算力获取：通过推荐下级入金获得（直推16%，2-3代8%，4-20代4%）
     * @dev 领取逻辑：只领取已完成燃烧的周期（currentDay - 1）
     * @dev 如果周期未执行销毁，则累积模拟计算
     * @param user 用户地址
     * @return totalReward 待领取的动态奖励BT数量
     */
    function calculateDynamicReward(address user) public view returns (uint256 totalReward) {
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        if (u.hashrateDynamic == 0||u.hashrateStatic == 0) return 0;
        
        uint256 currentDay = IToken(BT_TOKEN).getDailyCycle();
        IToken.UserLast memory info = IToken(BT_TOKEN).userLasts(user);
        uint256 lastDay = info.lastDynamicCycle;
        
        // 第0周期不计算奖励
        if (currentDay == 0) return 0;
        
        // 只计算到 currentDay - 1（已完成燃烧的周期）
        uint256 calculateUntilDay = currentDay;
        if (lastDay >= calculateUntilDay) return 0; // 没有可计算的周期
        
        uint256 farstHashrate = IToken(BT_TOKEN).dailyCycleDynamicHashrate(lastDay);
        uint256 farstUserHashrate = IToken(BT_TOKEN).usersCyclelDynamicHashrate(user,lastDay);

        if(farstUserHashrate == 0 && u.dynamicReceived > 0) farstUserHashrate = u.hashrateDynamic;
        
        totalReward = __calculateDynamicReward(user,lastDay,calculateUntilDay,farstHashrate,farstUserHashrate);
        
        totalReward = _calculateValue(user,totalReward);

        return totalReward;
    }
    function __calculateDynamicReward(address user,uint lastDay,uint calculateUntilDay,uint farstHashrate,uint farstUserHashrate)internal view returns(uint256 totalReward){
        // 用于累积模拟的池子余额
        uint256 simulatedPoolBalance = IToken(BT_TOKEN).balanceOf(pancakePair);
        uint times = 0;
        for (uint256 day = lastDay; day < calculateUntilDay ; day++) {
            uint256 hashrate = IToken(BT_TOKEN).dailyCycleDynamicHashrate(day);
            uint256 reward = IToken(BT_TOKEN).dailyCycleDynamicReward(day);
            uint256 userHashrate = IToken(BT_TOKEN).usersCyclelDynamicHashrate(user,day);
            
            // 如果算力未填充，使用历史算力
            if (hashrate == 0) {
                hashrate = farstHashrate;
            } else {
                farstHashrate = hashrate;
            }
            
            if (userHashrate == 0) {
                userHashrate = farstUserHashrate;
            } else {
                farstUserHashrate = userHashrate;
            }
            
            // 如果奖励未记录，累积模拟计算（1天）
            if (reward == 0 && hashrate > 0) {
                (reward, simulatedPoolBalance) = simulateDailyBurnWithBalance(simulatedPoolBalance);
            }
            
            // 计算用户应得奖励
            if (hashrate > 0 && reward > 0 && userHashrate > 0) {
                totalReward += (userHashrate * reward) / hashrate;
                times += 1;
            }
            
            if(times > 9) break;
        }
    }
    function _calculateValue(address user,uint totalReward) public view returns(uint256){
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        
        //modify
        uint userSellAmount = IToken(BT_TOKEN).userSellAmount(user);
        uint userLastSellTime = IToken(BT_TOKEN).userLastSellTime(user);
        uint currentHour = IToken(BT_TOKEN).getHourlyCycle();
        if ((u.hashrateReward > 0 &&
            (currentHour - userLastSellTime > 14 * 24 ||
            userSellAmount * 100 < u.hashrateReward * 20) ||
            getFifthTokenUSDTValue(user) < 30 ether)){
            return 0;
        }

        uint256 maxReward = 3 * u.usdtValue;

        if (maxReward <= IToken(BT_TOKEN).wbtcReward(user)) return 0;
        else maxReward -= IToken(BT_TOKEN).wbtcReward(user);
        
        uint value = _getBTAmountOutOfUSDT(1e18);
        
        uint rewardGaiavalue = u.hashrateReward * value / 1e18;
        
        if(rewardGaiavalue >= maxReward) return 0;

        uint totalRewardValue = totalReward * value / 1e18;
        
        if(rewardGaiavalue + totalRewardValue > maxReward){
            totalRewardValue = maxReward - rewardGaiavalue;
            return totalRewardValue * 1e18 / value;
        }
        return totalReward;
    }
    /**
     * @notice 计算静态奖励（小时周期）
     * @dev 静态奖励来源：每小时底池燃烧量的30%
     * @dev 分配方式：按用户静态算力占比分配
     * @dev 领取逻辑：只领取已完成燃烧的周期（currentHour - 1）
     * @dev 如果周期未执行销毁，则累积模拟计算
     * @param user 用户地址
     * @return totalReward 待领取的静态奖励BT数量
     */
    function calculateStaticReward(address user) public view returns (uint256 totalReward,uint256 nextHour) {
        IToken.User memory u = IToken(BT_TOKEN).users(user);
        if (u.hashrateStatic == 0) return (0,0);
        
        uint256 currentHour = IToken(BT_TOKEN).getHourlyCycle();
        IToken.UserLast memory info = IToken(BT_TOKEN).userLasts(user);
        uint256 lastHour = info.lastStaticCycle;//userLasts[user]
        
        // 第0周期不计算奖励
        if (currentHour == 0) return (0,0);
        
        // 只计算到 currentHour - 1（已完成燃烧的周期）
        uint256 calculateUntilHour = currentHour;
        if (lastHour >= calculateUntilHour) return (0,0); // 没有可计算的周期
        
        uint256 farstHashrate = IToken(BT_TOKEN).hourlyCycleStaticHashrate(lastHour);
        uint256 farstUserHashrate = IToken(BT_TOKEN).usersCycleStaticHashrate(user,lastHour);

        if (farstUserHashrate == 0) farstUserHashrate = u.hashrateStatic;
        
        // 用于累积模拟的池子余额
        uint256 simulatedPoolBalance = IToken(BT_TOKEN).balanceOf(pancakePair);
        //
        (totalReward,nextHour) = _calculateStaticRewardHours(user, lastHour, calculateUntilHour, farstHashrate, farstUserHashrate, simulatedPoolBalance);
        nextHour = calculateUntilHour;
        totalReward = _calculateValue(user,totalReward);

        return (totalReward,nextHour);
    }
    
    
    function _calculateStaticRewardHours(address user,uint lastHour,uint calculateUntilHour,uint farstHashrate,uint farstUserHashrate,uint simulatedPoolBalance)
        internal view 
        returns (uint256 totalReward,uint nextHour){
        uint256 hour = lastHour;
        
        if (hour + 10*24 < calculateUntilHour){
            calculateUntilHour = hour + 10*24;
        }
        nextHour = calculateUntilHour;
        for (; hour < calculateUntilHour; hour++) {
            uint256 hashrate = IToken(BT_TOKEN).hourlyCycleStaticHashrate(hour);
            uint256 reward = IToken(BT_TOKEN).hourlyCycleStaticReward(hour);
            uint256 userHashrate = IToken(BT_TOKEN).usersCycleStaticHashrate(user,hour);
            // 如果算力未填充，使用历史算力
            if (hashrate == 0) {
                hashrate = farstHashrate;
            } else {
                farstHashrate = hashrate;
            }
            
            if (userHashrate == 0) {
                userHashrate = farstUserHashrate;
            } else {
                farstUserHashrate = userHashrate;
            }
            
            // 如果奖励未记录，累积模拟计算
            if (reward == 0 && hashrate > 0) {
                (reward, simulatedPoolBalance) = _simulateHourlyBurnWithBalance(simulatedPoolBalance);
            }
            
            // 计算用户应得奖励
            if (hashrate > 0 && reward > 0 && userHashrate > 0) {
                totalReward += (userHashrate * reward) / hashrate;
            }
        }
    }
    
    /**
     * @notice 模拟一天的销毁，返回节点BT奖励数组和新余额
     * @dev 测试环境下1小时=1天，返回累积的节点BT奖励
     * @param poolBalance 当前模拟的池子余额
     * @return nodeRewards 节点奖励数组
     * @return newPoolBalance 所有销毁后的新余额
     */
    function simulateNodeBTRewardsWithBalance(
        uint256 poolBalance
    ) public view returns (uint256[10] memory nodeRewards, uint256 newPoolBalance) {
        // 生产环境：24小时 = 1天
        uint256 hoursPerDay = 24;
        
        // 初始化奖励数组
        nodeRewards = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
        newPoolBalance = poolBalance;
        
        for (uint256 i = 0; i < hoursPerDay; i++) {
            if (newPoolBalance == 0) break;
            
            uint256 burnRate = calculateBurnRate();
            uint256 burnAmount = (newPoolBalance * burnRate) / BASE;
            if (burnAmount == 0) break;
            
            // 累积节点BT奖励（各1%）
            nodeRewards[5] += (burnAmount * 1000) / BASE; // V1 BT
            nodeRewards[6] += (burnAmount * 1000) / BASE; // V2 BT
            nodeRewards[7] += (burnAmount * 1000) / BASE; // V3 BT
            nodeRewards[8] += (burnAmount * 1000) / BASE; // V4 BT
            nodeRewards[9] += (burnAmount * 1000) / BASE; // V5 BT
            
            // 更新余额（防止溢出）
            if (newPoolBalance >= burnAmount) {
                newPoolBalance -= burnAmount;
            } else {
                newPoolBalance = 0;
            }
        }
        
        return (nodeRewards, newPoolBalance);
    }
    /**
     * @notice 计算燃烧比例（每小时）
     * @dev 设计为每天燃烧1%-3%，需要除以24转换为每小时比例
     */
    function calculateBurnRate() public view returns (uint256) {
        uint256 daysElapsed = IToken(BT_TOKEN).getDailyCycle();
        uint256 dailyRate;
        dailyRate = 1000 + (daysElapsed / 10 * 150);
        if(dailyRate > 3000){
            dailyRate = 3000;
        }
        return dailyRate / 24;
    }
    // ============ 辅助功能：累积模拟销毁 ============
    /**
     * @notice 模拟单个小时周期的销毁，并返回新的余额
     * @dev 用于在奖励计算时模拟未执行的销毁周期
     * @param poolBalance 当前模拟的池子余额
     * @return staticReward 该周期的静态奖励
     * @return newPoolBalance 销毁后的新余额
     */
    
    function _simulateHourlyBurnWithBalance(
        uint256 poolBalance
    ) internal view returns (uint256 staticReward, uint256 newPoolBalance) {
        if (poolBalance == 0) return (0, 0);
        
        // 计算燃烧比例
        uint256 burnRate = calculateBurnRate();
        
        // 计算燃烧数量
        uint256 burnAmount = (poolBalance * burnRate) / BASE;
        if (burnAmount == 0) return (0, poolBalance);
        
        // 计算静态奖励（30%）
        staticReward = (burnAmount * 30000) / BASE;
        
        // 返回销毁后的新余额
        newPoolBalance = poolBalance - burnAmount;
        
        return (staticReward, newPoolBalance);
    }
    /**
     * @notice 模拟一天的销毁（累积所有小时），并返回新的余额
     * @dev 测试环境下1小时=1天，生产环境需要累积24小时
     * @param poolBalance 当前模拟的池子余额
     * @return dailyDynamicReward 该天的累积动态奖励
     * @return newPoolBalance 所有销毁后的新余额
     */
    function simulateDailyBurnWithBalance(
        uint256 poolBalance
    ) public view returns (uint256 dailyDynamicReward, uint256 newPoolBalance) {
        // 测试环境：1小时 = 1天
        // 生产环境：需要累积24小时的销毁
        uint256 hoursPerDay = 24; // 生产环境：一天周期
        
        dailyDynamicReward = 0;
        newPoolBalance = poolBalance;
        
        for (uint256 i = 0; i < hoursPerDay; i++) {
            if (newPoolBalance == 0) break;
            
            uint256 burnRate = calculateBurnRate();
            uint256 burnAmount = (newPoolBalance * burnRate) / BASE;
            if (burnAmount == 0) break;
            
            // 累积动态奖励（15%）
            dailyDynamicReward += (burnAmount * 15000) / BASE;
            
            // 更新余额（防止溢出）
            if (newPoolBalance >= burnAmount) {
                newPoolBalance -= burnAmount;
            } else {
                newPoolBalance = 0;
            }
        }
        
        return (dailyDynamicReward, newPoolBalance);
    }
    
    /**
     * @notice 将查询BT对WBTC的价格
     */

    function _getBTAmountOutOfUSDT(uint256 amountIn) public view returns(uint256){
        uint wbtcAmount = _getAmountOut(BT_TOKEN,WBTC,amountIn);
        return _getAmountOut(WBTC,USDT,wbtcAmount);
    }
    function _getUSDTAmountOutOfBT(uint256 amountIn) public view returns(uint256){
        uint wbtcAmount = _getAmountOut(USDT,WBTC,amountIn);
        return _getAmountOut(WBTC,BT_TOKEN,wbtcAmount);
    }
    
    /**
     * @notice 查询用户持有的5TH代币的USDT价值
     */
    function getFifthTokenUSDTValue(address user) public view returns (uint256 usdtValue) {
        uint256 balance = IERC20(FIFTH_TOKEN).balanceOf(user);
        uint valueofwbnb = _getAmountOut(FIFTH_TOKEN,WBNB,1e18);
        uint value = _getAmountOut(WBNB,USDT,valueofwbnb);
        usdtValue = balance * value / 1e18;

    }
    function _getAmountOut(address token0,address token1,uint256 amountIn) internal view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256[] memory amounts = IPancakeRouter(ROUTER).getAmountsOut(amountIn, path);
        return amounts[1];
    }
    function buyBTCBWithWBNB(
        uint256 amountInWbnb,
        uint256 minBtcbOut,
        address recv,
        uint24 poolfee
    ) internal returns (uint256 amountOut) {
        
        // 1. 授权 Router 使用 WBNB
        require(
            IERC20(WBNB).approve(PANCAKE_V3_ROUTER, amountInWbnb),
            "approve WBNB failed"
        );
        // 2. WBNB -> BTCB
        IPancakeV3SwapRouter.ExactInputSingleParams memory params =
            IPancakeV3SwapRouter.ExactInputSingleParams({
                tokenIn: WBNB,
                tokenOut: WBTC,
                fee: poolfee,
                recipient: recv,
                amountIn: amountInWbnb,
                amountOutMinimum: minBtcbOut,
                sqrtPriceLimitX96: 0
            });

        amountOut = IPancakeV3SwapRouter(PANCAKE_V3_ROUTER)
            .exactInputSingle(params);
    }
}
// ============ 接口定义 ============
interface IPancakeV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}
interface IPancakePair {
    function sync() external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
}
interface IPancakeRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}