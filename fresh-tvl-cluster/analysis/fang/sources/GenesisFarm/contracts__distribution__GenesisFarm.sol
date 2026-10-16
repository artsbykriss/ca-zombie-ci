// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

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
#### Author: kell (adaptions)

// @title Fang Finance Genesis: Modified from TombGenesisRewardPool (originally from SushiSwap MasterChef)
// @notice Genesis farm: stake listed assets for a fixed xGFANG budget over [poolStartTime, poolEndTime],
//         optionally convert staked principal into xGFANG at the launch price after farming period ends
// @dev    Modifications:
// Modern Solidity
// OpenZeppelin Ownable (instead of Tomb operator) and ReentrancyGuard
// Per-pool deposit fee (forked from SpiritSwap MasterChef's depositFeeBP block)
// Owner may reschedule genesis before it starts, preserving duration and reward budget
// After farming period ends: no more deposits. Farm is whitelist for launch
// Optional conversion of principal via Convertible.sol (capped launch, up to 24h, fcfs)
// Built for Robinhood Chain

**************************************************************************************************************************************************/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IConvertible {
    function convert(address _token, uint256 _amount, address _user) external returns (uint256 xgfangOut);
}

contract GenesisFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ************************************************************************************************
    // FORK: tomb.finance TombGenesisRewardPool, with SpiritSwap MasterChef's depositFeeBP block
    //
    // Upstream code, Tomb's order. Only lines marked MODIFIED (Tomb: ...) or MODIFIED (SpiritSwap: ...)
    // differ from upstream, beyond the mechanical changes the file header lists.
    // ************************************************************************************************

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. xGFANG to distribute.
        uint256 lastRewardTime; // Last time that xGFANG distribution occurs.
        uint256 accRewardPerShare; // Accumulated xGFANG per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        uint16 depositFeeBP; // Deposit fee in basis points // MODIFIED (SpiritSwap: the field)
    }

    IERC20 public immutable rewardToken; // MODIFIED (Tomb: IERC20 public tomb)

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when xGFANG mining starts.
    uint256 public poolStartTime; // MODIFIED (owner may reschedule before genesis starts)

    // The time when xGFANG mining ends.
    uint256 public poolEndTime; // Always poolStartTime + runningTime

    // MODIFIED (set in constructor instead of constants)
    uint256 public immutable runningTime;
    uint256 public immutable totalRewards;
    uint256 public immutable rewardPerSecond;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event PoolStartTimeUpdated(uint256 previousStartTime, uint256 newStartTime, uint256 newEndTime);

    constructor(
        address _rewardToken,
        uint256 _poolStartTime,
        address _owner,
        uint256 _runningTime,
        uint256 _totalRewards
    ) {
        require(block.timestamp < _poolStartTime, "GenesisFarm: late");
        require(_rewardToken != address(0), "GenesisFarm: zero address");
        rewardToken = IERC20(_rewardToken);
        poolStartTime = _poolStartTime;
        require(_runningTime > 0, "GenesisFarm: zero runningTime");
        runningTime = _runningTime;
        poolEndTime = _poolStartTime + runningTime;
        totalRewards = _totalRewards;
        rewardPerSecond = totalRewards / runningTime; // rounds down: the farm ends with dust, never short
        require(_owner != address(0), "GenesisFarm: owner is zero"); // MODIFIED (Tomb: the deployer is the operator)
        _transferOwnership(_owner); // MODIFIED (Tomb: operator = msg.sender)
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Moves genesis earlier or later, provided the current and new start times are still in the future.
    /// @dev Preserves the duration, emission rate, allocations and deposits. No rewards have accrued yet.
    function setPoolStartTime(uint256 _poolStartTime) external onlyOwner {
        require(block.timestamp < poolStartTime, "GenesisFarm: already started");
        require(block.timestamp < _poolStartTime, "GenesisFarm: start must be in future");

        uint256 previousStartTime = poolStartTime;
        poolStartTime = _poolStartTime;
        poolEndTime = _poolStartTime + runningTime;

        // MODIFIED (all pools added before genesis start together; add disallows delayed starts).
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardTime = _poolStartTime;
        }

        emit PoolStartTimeUpdated(previousStartTime, _poolStartTime, poolEndTime);
    }

    function _checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "GenesisFarm: existing pool?");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint16 _depositFeeBP,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOwner {
        _checkPoolDuplicate(_token);
        require(_token != rewardToken, "GenesisFarm: reward token"); // MODIFIED (Tomb: no such check)
        require(_depositFeeBP <= 500, "GenesisFarm: add: invalid deposit fee basis points");
        require(_lastRewardTime == 0, "GenesisFarm: add: delayed start"); // MODIFIED (Tomb: no such check)
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
        require(_lastRewardTime <= poolEndTime, "GenesisFarm: add: late"); // MODIFIED (Tomb: no such check)
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accRewardPerShare: 0,
                isStarted: _isStarted,
                depositFeeBP: _depositFeeBP
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint + _allocPoint;
        }
    }

    // Update the given pool's xGFANG allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 500, "GenesisFarm: set: invalid deposit fee basis points");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        }
        pool.allocPoint = _allocPoint;
        pool.depositFeeBP = _depositFeeBP;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return (poolEndTime - poolStartTime) * rewardPerSecond;
            return (poolEndTime - _fromTime) * rewardPerSecond;
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return (_toTime - poolStartTime) * rewardPerSecond;
            return (_toTime - _fromTime) * rewardPerSecond;
        }
    }

    // View function to see pending xGFANG on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _reward = _generatedReward * pool.allocPoint / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + _reward * 1e18 / tokenSupply;
        }
        return user.amount * accRewardPerShare / 1e18 - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint + pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _reward = _generatedReward * pool.allocPoint / totalAllocPoint;
            pool.accRewardPerShare = pool.accRewardPerShare + _reward * 1e18 / tokenSupply;
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(block.timestamp < poolEndTime, "GenesisFarm: deposits closed"); // MODIFIED (Tomb: deposits never close)
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount * pool.accRewardPerShare / 1e18 - user.rewardDebt;
            if (_pending > 0) {
                _safeRewardTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            // MODIFIED (Fee block from SpiritSwap MasterChef, instead of Tomb's fixed 1% fee on shiba)
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount * pool.depositFeeBP / 10000;
                pool.token.safeTransfer(owner(), depositFee);
                user.amount = user.amount + _amount - depositFee;
            } else {
                user.amount = user.amount + _amount;
            }
        }
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        _withdraw(_pid, _amount, true); // MODIFIED (Tomb: the body of _withdraw was inline here)
    }

    // MODIFIED (Tomb: withdraw's body, with _toUser deciding whether the principal leaves the farm)
    function _withdraw(uint256 _pid, uint256 _amount, bool _toUser) internal {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "GenesisFarm: withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount * pool.accRewardPerShare / 1e18 - user.rewardDebt;
        if (_pending > 0) {
            _safeRewardTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            if (_toUser) pool.token.safeTransfer(_sender, _amount); // MODIFIED (Tomb: unconditional)
        }
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe xGFANG transfer function, just in case if rounding error causes pool to not have enough xGFANGs.
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 _rewardBalance = rewardToken.balanceOf(address(this));
        if (_rewardBalance > 0) {
            if (_amount > _rewardBalance) {
                rewardToken.safeTransfer(_to, _rewardBalance);
            } else {
                rewardToken.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOwner {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (xGFANG or lps) if less than 90 days after pool ends
            require(_token != rewardToken, "GenesisFarm: xGFANG");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "GenesisFarm: pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }

    // ************************************************************************************************
    // END OF FORK
    // ************************************************************************************************

    // ************************************************************************************************
    // MERIDIAN MODIFICATIONS
    //
    // Additive: conversion of staked principal into xGFANG through Convertible during CONVERT_WINDOW
    // after poolEndTime, built on the fork's own _withdraw.
    // ************************************************************************************************

    uint256 public constant CONVERT_WINDOW = 24 hours;
    address public convertible;

    event ConvertibleUpdated(address indexed convertible);
    event Convert(address indexed user, uint256 indexed pid, uint256 amount, uint256 xgfangOut);

    modifier onlyConvertWindow() {
        require(convertible != address(0), "GenesisFarm: convertible not set");
        require(
            block.timestamp >= poolEndTime && block.timestamp < poolEndTime + CONVERT_WINDOW,
            "GenesisFarm: convert window closed"
        );
        _;
    }

    /// @notice Sets the Convertible contract.
    function setConvertible(address _convertible) external onlyOwner {
        convertible = _convertible;
        emit ConvertibleUpdated(_convertible);
    }

    /// @notice Converts `_amount` of the caller's staked principal in pool `_pid` into xGFANG at the launch price.
    function convert(uint256 _pid, uint256 _amount) external onlyConvertWindow nonReentrant returns (uint256 pegTokenOut) {
        require(_amount > 0, "GenesisFarm: convert: not good");
        _withdraw(_pid, _amount, false); // Standard withdraw plus keep tokens in farm contract to convert
        IERC20 token = poolInfo[_pid].token;
        token.forceApprove(convertible, _amount);
        pegTokenOut = IConvertible(convertible).convert(address(token), _amount, msg.sender);
        emit Convert(msg.sender, _pid, _amount, pegTokenOut);
    }

    // Frontend helper for claim.
    function harvest(uint256[] calldata _pid) external {
        for (uint256 i = 0; i < _pid.length; ++i) {
            withdraw(_pid[i], 0);
        }
    }
}
