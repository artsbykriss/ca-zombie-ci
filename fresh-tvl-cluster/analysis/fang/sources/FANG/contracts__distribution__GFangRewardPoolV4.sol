// SPDX-License-Identifier: BUSL-1.1

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IBasisAsset.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/farming/IGigadexGauge.sol";
import "../interfaces/farming/IAlandaleGauge.sol";
import "../interfaces/farming/IUpdexGauge.sol";

import "../interfaces/farming/IGigadexVoter.sol";
import "../interfaces/farming/IAlandaleVoter.sol";
import "../interfaces/farming/IUpdexVoter.sol";

contract GFangRewardPoolV4 is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    enum GaugeDex {
        NONE, // 0
        GIGADEX, // 1
        ALANDALE, // 2
        UPDEX // 3
    }

    struct GaugeInfo {
        bool isGauge;   // If this is a gauge
        address gauge;  // The gauge
        GaugeDex gaugeDex; // The type of gauge (None or Gigadex)
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 depFee; // deposit fee that is applied to created pool.
        uint256 allocPoint; // How many allocation points assigned to this pool. GFANGs to distribute per block.
        uint256 lastRewardTime; // Last time that GFANGs distribution occurs.
        uint256 accGfangPerShare; // Accumulated GFANGs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        GaugeInfo gaugeInfo; // Gauge info (does this pool have a gauge and where is it)
        uint256 poolGfangPerSec; // rewards per second for pool (acts as allocPoint)
    }

    address public constant USDC = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    IERC20 public gfang;
    IOracle public gfangOracle;
    bool public claimGaugeRewardsOnUpdatePool = false;
    mapping(uint256 => bool) public pegStabilityModuleFeeEnabled; // pid => is enabled
    mapping(uint256 => uint256) public pegStabilityModuleFee; // pid => fee in basis points (1000 = 100%)
    uint256 public minClaimThreshold = 1e12; // 0.000001 GFANG

    IGigadexVoter public gigadexVoter;
    IAlandaleVoter public alandaleVoter;
    IUpdexVoter public updexVoter;

    address public bribesSafe;
    address public msigWallet;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Pending rewards for each user in each pool (pending rewards accrued since last deposit/withdrawal)
    mapping(uint256 => mapping(address => uint256)) public pendingRewards;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when GFANG mining starts.
    uint256 public poolStartTime;

    // The time when GFANG mining ends.
    uint256 public poolEndTime;
    uint256 public sharePerSecond = 0 ether;
    uint256 public runningTime = 730 days;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _gfang,
        address _bribesSafe,
        uint256 _poolStartTime,
        address _gigadexVoter,
        address _alandaleVoter,
        address _updexVoter
    ) {
        require(block.timestamp < _poolStartTime, "pool cant be started in the past");
        if (_gfang != address(0)) gfang = IERC20(_gfang);
        if(_bribesSafe != address(0)) bribesSafe = _bribesSafe;

        poolStartTime = _poolStartTime;
        poolEndTime = _poolStartTime + runningTime;
        operator = msg.sender;
        gigadexVoter = IGigadexVoter(_gigadexVoter);
        alandaleVoter = IAlandaleVoter(_alandaleVoter);
        updexVoter = IUpdexVoter(_updexVoter);
        bribesSafe = _bribesSafe;
        msigWallet = _bribesSafe;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "GFangRewardPool: caller is not the operator");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "GFangRewardPool: existing pool?");
        }
    }

    // bulk add pools
    function addBulk(uint256[] calldata _allocPoints, uint256[] calldata _depFees, IERC20[] calldata _tokens, bool _withUpdate, uint256 _lastRewardTime) external onlyOperator {
        require(_allocPoints.length == _depFees.length && _allocPoints.length == _tokens.length, "FangGenesisRewardPool: invalid length");
        for (uint256 i = 0; i < _allocPoints.length; i++) {
            add(_allocPoints[i], _depFees[i], _tokens[i], _withUpdate, _lastRewardTime);
        }
    }

    // Add new lp to the pool. Can only be called by operator.
    function add(
        uint256 _allocPoint,
        uint256 _depFee,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token: _token,
            depFee: _depFee,
            allocPoint: _allocPoint,
            poolGfangPerSec: _allocPoint,
            lastRewardTime: _lastRewardTime,
            accGfangPerShare: 0,
            isStarted: _isStarted,
            gaugeInfo: GaugeInfo(false, address(0), GaugeDex.NONE) // default to no gauge
        }));
        // enableGauge(poolInfo.length - 1);

        pegStabilityModuleFeeEnabled[poolInfo.length - 1] = true; // default to false
        pegStabilityModuleFee[poolInfo.length - 1] = 300; // default to 30%
        
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
            sharePerSecond = sharePerSecond.add(_allocPoint);
        }
    }

    // Update the given pool's GFANG allocation point. Can only be called by the operator.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depFee) public onlyOperator {
        massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];
        require(_depFee < 200);  // deposit fee cant be more than 2%;
        pool.depFee = _depFee;

        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
            sharePerSecond = sharePerSecond.sub(pool.poolGfangPerSec).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
        pool.poolGfangPerSec = _allocPoint;
    }

    function bulkSet(uint256[] calldata _pids, uint256[] calldata _allocPoints, uint256[] calldata _depFees) external onlyOperator {
        require(_pids.length == _allocPoints.length && _pids.length == _depFees.length, "GFangRewardPool: invalid length");
        for (uint256 i = 0; i < _pids.length; i++) {
            set(_pids[i], _allocPoints[i], _depFees[i]);
        }
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(sharePerSecond);
            return poolEndTime.sub(_fromTime).mul(sharePerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(sharePerSecond);
            return _toTime.sub(_fromTime).mul(sharePerSecond);
        }
    }

    // View function to see pending GFANGs on frontend.
    function pendingShare(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGfangPerShare = pool.accGfangPerShare;
        uint256 tokenSupply = pool.gaugeInfo.isGauge ? IERC20(pool.gaugeInfo.gauge).balanceOf(address(this)) : pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _gfangReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accGfangPerShare = accGfangPerShare.add(_gfangReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accGfangPerShare).div(1e18).sub(user.rewardDebt);
    }

    // View function to see pending GFANGs on frontend and any other pending rewards accumulated.
    function pendingShareAndPendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        uint256 _pendingShare = pendingShare(_pid, _user);
        return _pendingShare.add(pendingRewards[_pid][_user]);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
            updatePoolWithGaugeDeposit(pid);
        }
    }

    // massUpdatePoolsInRange
    function massUpdatePoolsInRange(uint256 _fromPid, uint256 _toPid) public {
        require(_fromPid <= _toPid, "GFangRewardPool: invalid range");
        for (uint256 pid = _fromPid; pid <= _toPid; ++pid) {
            updatePool(pid);
            updatePoolWithGaugeDeposit(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) private {
        updatePoolWithGaugeDeposit(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.gaugeInfo.isGauge ? IERC20(pool.gaugeInfo.gauge).balanceOf(address(this)) : pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
            sharePerSecond = sharePerSecond.add(pool.poolGfangPerSec);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _gfangReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accGfangPerShare = pool.accGfangPerShare.add(_gfangReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
        if (claimGaugeRewardsOnUpdatePool) {claimGaugeRewards(_pid);}
    }
    
    // Deposit LP tokens to earn rewards
    function updatePoolWithGaugeDeposit(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        address gauge = pool.gaugeInfo.gauge;
        uint256 balance = pool.token.balanceOf(address(this));
        // Do nothing if this pool doesn't have a gauge
        if (pool.gaugeInfo.isGauge) {
            // Do nothing if the LP token in the MC is empty
            if (balance > 0) {
                // Approve to the gauge
                if (pool.token.allowance(address(this), gauge) < balance ){
                    pool.token.approve(gauge, type(uint256).max);
                }
                // Deposit to the gauge
                _depositToGauge(_pid, balance);
            }
        }
    }

    function _depositToGauge(uint256 _pid, uint256 _balance) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.gaugeInfo.gaugeDex == GaugeDex.GIGADEX) {
            IGigadexGauge(pool.gaugeInfo.gauge).deposit(_balance);
        }
        if (pool.gaugeInfo.gaugeDex == GaugeDex.ALANDALE) {
            IAlandaleGauge(pool.gaugeInfo.gauge).deposit(_balance);
        }
        if (pool.gaugeInfo.gaugeDex == GaugeDex.UPDEX) {
            IUpdexGauge(pool.gaugeInfo.gauge).deposit(_balance);
        }
    }

    // Claim rewards to treasury
    function claimGaugeRewards(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.gaugeInfo.isGauge) {
            if (pool.gaugeInfo.gaugeDex == GaugeDex.GIGADEX) {
                _claimGigadexRewards(_pid);
            }
            if (pool.gaugeInfo.gaugeDex == GaugeDex.ALANDALE) {
                _claimAlandaleRewards(_pid);
            }
            if (pool.gaugeInfo.gaugeDex == GaugeDex.UPDEX) {
                _claimUpdexRewards(_pid);
            }
        }
    }

    function claimAllFarmRewards() public onlyOperator {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            claimGaugeRewards(pid);
        }
    }

    function _claimGigadexRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory gaugeRewardTokens = IGigadexGauge(pool.gaugeInfo.gauge).rewardsList();
        IGigadexGauge(pool.gaugeInfo.gauge).getReward(address(this), gaugeRewardTokens);

        for (uint256 i = 0; i < gaugeRewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(gaugeRewardTokens[i]);
            uint256 rewardAmount = rewardToken.balanceOf(address(this));

            if (rewardAmount > 0) {
                rewardToken.safeTransfer(bribesSafe, rewardAmount);
            }
        }
    }

    function _claimAlandaleRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory gaugeRewardTokens = IAlandaleGauge(pool.gaugeInfo.gauge).rewardsList();
        IAlandaleGauge(pool.gaugeInfo.gauge).getReward(address(this), gaugeRewardTokens);

        for (uint256 i = 0; i < gaugeRewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(gaugeRewardTokens[i]);
            uint256 rewardAmount = rewardToken.balanceOf(address(this));

            if (rewardAmount > 0) {
                rewardToken.safeTransfer(bribesSafe, rewardAmount);
            }
        }
    }

    function _claimUpdexRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory gaugeRewardTokens = IUpdexGauge(pool.gaugeInfo.gauge).rewardsList();
        IUpdexGauge(pool.gaugeInfo.gauge).getReward(address(this), gaugeRewardTokens);

        for (uint256 i = 0; i < gaugeRewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(gaugeRewardTokens[i]);
            uint256 rewardAmount = rewardToken.balanceOf(address(this));

            if (rewardAmount > 0) {
                rewardToken.safeTransfer(bribesSafe, rewardAmount);
            }
        }
    }

    function enableGauge(uint256 _pid, GaugeDex _gaugeDex) public onlyOperator {
        if (_gaugeDex == GaugeDex.GIGADEX) {
            _enableGaugeGigadex(_pid);
        }
    }

    // GIGADEX
    function _enableGaugeGigadex(uint256 _pid) internal {
        address gauge = gigadexVoter.gaugeForPool(address(poolInfo[_pid].token));
        if (gauge != address(0)) {
            poolInfo[_pid].gaugeInfo = GaugeInfo(true, gauge, GaugeDex.GIGADEX);
        }
    }

    // ALANDALE
    function _enableGaugeAlandale(uint256 _pid) internal {
        address gauge = alandaleVoter.poolToGauge(address(poolInfo[_pid].token));
        if (gauge != address(0)) {
            poolInfo[_pid].gaugeInfo = GaugeInfo(true, gauge, GaugeDex.ALANDALE);
        }
    }

    // UPDEX
    function _enableGaugeUpdex(uint256 _pid) internal {
        address gauge = updexVoter.poolToGauge(address(poolInfo[_pid].token));
        if (gauge != address(0)) {
            poolInfo[_pid].gaugeInfo = GaugeInfo(true, gauge, GaugeDex.UPDEX);
        }
    }

    function disableGauge(uint256 _pid) public onlyOperator {
        _withdrawAllFromGauge(_pid);
        poolInfo[_pid].gaugeInfo = GaugeInfo(false, address(0), GaugeDex.NONE);
    }

    function _withdrawAllFromGauge(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.gaugeInfo.gaugeDex == GaugeDex.GIGADEX) {
            IGigadexGauge(pool.gaugeInfo.gauge).withdrawAll();
        }
        if (pool.gaugeInfo.gaugeDex == GaugeDex.ALANDALE) {
            IAlandaleGauge(pool.gaugeInfo.gauge).withdrawAll();
        }
        if (pool.gaugeInfo.gaugeDex == GaugeDex.UPDEX) {
            IUpdexGauge(pool.gaugeInfo.gauge).withdrawAll();
        }
    }

    // Withdraw LP from the gauge
    function withdrawFromGauge(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        // Do nothing if this pool doesn't have a gauge
        if (pool.gaugeInfo.isGauge) {
            // Withdraw from the gauge
            if (pool.gaugeInfo.gaugeDex == GaugeDex.GIGADEX) {
                IGigadexGauge(pool.gaugeInfo.gauge).withdraw(_amount);
            }
            if (pool.gaugeInfo.gaugeDex == GaugeDex.ALANDALE) {
                IAlandaleGauge(pool.gaugeInfo.gauge).withdraw(_amount);
            }
            if (pool.gaugeInfo.gaugeDex == GaugeDex.UPDEX) {
                IUpdexGauge(pool.gaugeInfo.gauge).withdraw(_amount);
            }
        }
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accGfangPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                // safeGfangTransfer(_sender, _pending);
                // emit RewardPaid(_sender, _pending);

                // accrue pending rewards to be claimed later
                pendingRewards[_pid][_sender] = pendingRewards[_pid][_sender].add(_pending);
            }
        }
        if (_amount > 0 ) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            uint256 depositDebt = _amount.mul(pool.depFee).div(10000);
            user.amount = user.amount.add(_amount.sub(depositDebt));
            pool.token.safeTransfer(bribesSafe, depositDebt);
        }
        updatePoolWithGaugeDeposit(_pid);
        user.rewardDebt = user.amount.mul(pool.accGfangPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        updatePoolWithGaugeDeposit(_pid);
        uint256 _pending = user.amount.mul(pool.accGfangPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            // safeGfangTransfer(_sender, _pending);
            // emit RewardPaid(_sender, _pending);

            // accrue pending rewards to be claimed later
            pendingRewards[_pid][_sender] = pendingRewards[_pid][_sender].add(_pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            withdrawFromGauge(_pid, _amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accGfangPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    function harvest(uint256 _pid) public nonReentrant { 
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];

        // Ensure rewards are updated
        updatePool(_pid);
        updatePoolWithGaugeDeposit(_pid);

        // Calculate the latest pending rewards
        uint256 _pending = user.amount.mul(pool.accGfangPerShare).div(1e18).sub(user.rewardDebt);
        uint256 _accumulatedPending = pendingRewards[_pid][_sender];
        uint256 _rewardsToClaim = _pending.add(_accumulatedPending);

        // Ensure that the user is claiming an amount above the minimum threshold
        require(_rewardsToClaim >= minClaimThreshold, "Claim amount below minimum threshold");

        if (_rewardsToClaim > 0) {
            pendingRewards[_pid][_sender] = 0;

            uint256 amountUSDCToPay = 0;
            if (pegStabilityModuleFeeEnabled[_pid]) {
                uint256 currentGFANGPriceInUSDC = gfangOracle.twap(address(gfang), 1e18);
                amountUSDCToPay = ((currentGFANGPriceInUSDC.mul(_rewardsToClaim).div(1e18)).mul(pegStabilityModuleFee[_pid]).div(1000)).div(1e12); // convert to 6 decimals
                IERC20(USDC).safeTransferFrom(_sender, address(this), amountUSDCToPay);
                IERC20(USDC).safeTransfer(msigWallet, amountUSDCToPay);
            }

            safeGfangTransfer(_sender, _rewardsToClaim);
            emit RewardPaid(_sender, _rewardsToClaim);
        }
        // Update the user’s reward debt
        user.rewardDebt = user.amount.mul(pool.accGfangPerShare).div(1e18);
    }

    function harvestAll() public nonReentrant {
        address _sender = msg.sender;
        uint256 length = poolInfo.length;
        uint256 totalUserRewardsToClaim = 0;
        uint256 amountUSDCToPay = 0;

        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][_sender];

            // Ensure rewards are updated
            updatePool(pid);
            updatePoolWithGaugeDeposit(pid);

            // Calculate the latest pending rewards
            uint256 _pending = user.amount.mul(pool.accGfangPerShare).div(1e18).sub(user.rewardDebt);
            uint256 _accumulatedPending = pendingRewards[pid][_sender];
            uint256 _rewardsToClaim = _pending.add(_accumulatedPending);

            if (_rewardsToClaim > 0) {
                pendingRewards[pid][_sender] = 0;
                totalUserRewardsToClaim = totalUserRewardsToClaim.add(_rewardsToClaim);

                if (pegStabilityModuleFeeEnabled[pid]) {
                    uint256 currentGFANGPriceInUSDC = gfangOracle.twap(address(gfang), 1e18);
                    amountUSDCToPay = amountUSDCToPay.add((currentGFANGPriceInUSDC.mul(_rewardsToClaim).div(1e18)).mul(pegStabilityModuleFee[pid]).div(1000));
                }
            }
            // Update the user’s reward debt
            user.rewardDebt = user.amount.mul(pool.accGfangPerShare).div(1e18);
        }

        // Ensure that the user is claiming an amount above the minimum threshold
        require(totalUserRewardsToClaim >= minClaimThreshold, "Claim amount below minimum threshold");
        if (amountUSDCToPay != 0) {
            amountUSDCToPay = amountUSDCToPay.div(1e12); // convert to 6 decimals
            IERC20(USDC).safeTransferFrom(_sender, address(this), amountUSDCToPay);
            IERC20(USDC).safeTransfer(msigWallet, amountUSDCToPay);
        }

        if (totalUserRewardsToClaim > 0) {
            safeGfangTransfer(_sender, totalUserRewardsToClaim);
            emit RewardPaid(_sender, totalUserRewardsToClaim);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        withdrawFromGauge(_pid, _amount);
        pendingRewards[_pid][msg.sender] = 0;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe gfang transfer function, just in case if rounding error causes pool to not have enough GFANGs.
    function safeGfangTransfer(address _to, uint256 _amount) internal {
        uint256 _gfangBal = gfang.balanceOf(address(this));
        if (_gfangBal > 0) {
            if (_amount > _gfangBal) {
                gfang.safeTransfer(_to, _gfangBal);
            } else {
                gfang.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBribesSafe(address _bribesSafe) public onlyOperator {
        bribesSafe = _bribesSafe;
    }

    function setMsigWallet(address _msigWallet) public onlyOperator {
        msigWallet = _msigWallet;
    }

    function setPegStabilityModuleFee(uint256 _pegStabilityModuleFee, uint256 _pid) external onlyOperator {
        require(_pegStabilityModuleFee <= 750, "GFangRewardPool: invalid peg stability module fee"); // max 75%
        pegStabilityModuleFee[_pid] = _pegStabilityModuleFee;
    }

    function setGFangOracle(IOracle _gfangOracle) external onlyOperator {
        gfangOracle = _gfangOracle;
    }

    function setPegStabilityModuleFeeEnabled(bool _enabled, uint256 _pid) external onlyOperator {
        pegStabilityModuleFeeEnabled[_pid] = _enabled;
    }

    function setMinClaimThreshold(uint256 _minClaimThreshold) external onlyOperator {
        require(_minClaimThreshold >= 0, "GFangRewardPool: invalid min claim threshold");
        require(_minClaimThreshold <= 1e18, "GFangRewardPool: invalid max claim threshold");
        minClaimThreshold = _minClaimThreshold;
    }

    function setClaimGaugeRewardsOnUpdatePool(bool _claimGaugeRewardsOnUpdatePool) external onlyOperator {
        claimGaugeRewardsOnUpdatePool = _claimGaugeRewardsOnUpdatePool;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(_token != pool.token, "ShareRewardPool: Token cannot be pool token");
        }
        _token.safeTransfer(to, amount);
    }

    /**
     * @notice Collects the Eth.
     * @param amount The amount of Eth to collect
     */

    function collectEth(uint256 amount) public onlyOperator {
        (bool sent,) = bribesSafe.call{value: amount}("");
        require(sent, "failed to send Eth");
    }

    function collectEthMsig(uint256 amount) public onlyOperator {
        (bool sent,) = msigWallet.call{value: amount}("");
        require(sent, "failed to send Eth");
    }
}
