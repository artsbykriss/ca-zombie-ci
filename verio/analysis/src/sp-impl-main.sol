// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./abstract/VerioComponent.sol";
import "./interfaces/IStakePool.sol";
import "./interfaces/IDelegator.sol";
import "./interfaces/IWithdrawalPool.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IVerioIP.sol";

/// @title Stake Pool Implementation
/// @notice Implements staking logic for IP to vIP conversion and delegation
/// @dev Implements IStakePool interface with upgradeable OpenZeppelin contracts
contract StakePool is IStakePool, VerioComponent {
    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.StakePool.StakePoolState")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant STAKE_POOL_STATE = 0xe41b22deefae2f9a6392ef27a1127c46110b60ec2d4f6d998d8b7863795f6700;

    // 5% maximum mint fee bps
    uint256 public constant MAX_MINT_FEE_BPS = 500;
    // 5% maximum burn fee bps
    uint256 public constant MAX_BURN_FEE_BPS = 500;

    /// @notice Storage slot for stake pool state
    function _stakePoolState() internal pure returns (StakePoolState storage $) {
        assembly {
            $.slot := STAKE_POOL_STATE
        }
    }

    // --- INITIALIZER ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with configuration
    /// @param _config Initial configuration parameters
    function initialize(StakePoolConfig calldata _config) public initializer {
        _init(msg.sender);
        _trySetStakePoolState(_config);
    }

    /// @notice Internal function to validate and set configuration
    /// @param _stakePoolConfig New configuration to set
    /// @dev Validates fee parameters before setting
    function _trySetStakePoolState(StakePoolConfig calldata _stakePoolConfig) internal {
        require(_stakePoolConfig.singularity > 0, InvalidSingularity());
        require(_stakePoolConfig.maxStakeIterations > 0, InvalidMaxStakeIterations());
        require(_stakePoolConfig.delegationSize > 0, InvalidDelegationSize());
        require(_stakePoolConfig.minStake > 0, InvalidMinStake());

        StakePoolState storage stakePoolState = _stakePoolState();

        if (_stakePoolConfig.mintFeeEnabled) {
            require(_isValidMintFee(_stakePoolConfig.mintFeeBps), MaxMintFeeExceeded(MAX_MINT_FEE_BPS));
            stakePoolState.mintFeeBps = _stakePoolConfig.mintFeeBps;
            stakePoolState.mintFeeEnabled = _stakePoolConfig.mintFeeEnabled;
        }

        if (_stakePoolConfig.burnFeeEnabled) {
            require(_isValidBurnFee(_stakePoolConfig.burnFeeBps), MaxBurnFeeExceeded(MAX_BURN_FEE_BPS));
            stakePoolState.burnFeeBps = _stakePoolConfig.burnFeeBps;
            stakePoolState.burnFeeEnabled = _stakePoolConfig.burnFeeEnabled;
        }

        stakePoolState.singularity = _stakePoolConfig.singularity;
        stakePoolState.maxStakeIterations = _stakePoolConfig.maxStakeIterations;
        stakePoolState.maxStake = _stakePoolConfig.maxStake;
        stakePoolState.minStake = _stakePoolConfig.minStake;
        stakePoolState.delegationSize = _stakePoolConfig.delegationSize;
        stakePoolState.unbondingPeriod = _stakePoolConfig.unbondingPeriod;

        require(_isValidMaxStake(_stakePoolConfig.maxStake), InvalidMaxStake());
        require(_isValidMinStake(_stakePoolConfig.minStake), InvalidMinStake());
        require(_isValidDelegationSize(_stakePoolConfig.delegationSize), InvalidDelegationSize());

        emit StakePoolStateUpdated(stakePoolState);
    }

    function _isValidMintFee(uint256 _mintFeeBps) internal pure returns (bool) {
        return _mintFeeBps <= MAX_MINT_FEE_BPS;
    }

    function _isValidBurnFee(uint256 _burnFeeBps) internal pure returns (bool) {
        return _burnFeeBps <= MAX_BURN_FEE_BPS;
    }

    function _isValidMaxStake(uint256 _maxStake) internal view returns (bool) {
        return _maxStake > 0 && _maxStake >= _stakePoolState().minStake;
    }

    function _isValidMinStake(uint256 _minStake) internal view returns (bool) {
        return _minStake > 0 && _minStake <= _stakePoolState().delegationSize;
    }

    function _isValidDelegationSize(uint256 _delegationSize) internal view returns (bool) {
        return _delegationSize > 0 && _delegationSize <= _stakePoolState().maxStake
            && _delegationSize >= _stakePoolState().minStake;
    }

    // --- BUSINESS LOGIC ---

    /// @inheritdoc IStakePool
    function fund() external payable override {
        if (msg.value > 0) {
            emit RewardReceived(msg.value);
        }
    }

    /// @inheritdoc IStakePool
    function stake(bool _evaluate) external payable override nonReentrant whenNotPaused {
        require(msg.value % 1 gwei == 0, StakeNotGweiMultiple());
        _stake(msg.sender, msg.value);
        _restake();
        if (_evaluate) _evaluateStakePool();
    }

    function evaluateStakePool() external override nonReentrant whenNotPaused {
        _evaluateStakePool();
    }

    /// @notice Internal staking logic
    /// @param _staker Address of the staker
    /// @param _stakeAmount Amount being staked (in IP)
    /// @dev Handles minting of vIP tokens and fees
    function _stake(address _staker, uint256 _stakeAmount) internal {
        StakePoolState storage stakePoolState = _stakePoolState();

        require(_stakeAmount >= stakePoolState.minStake, StakeLessThanMinimum(stakePoolState.minStake));
        emit Staked(_staker, _stakeAmount);

        uint256 vIPToMint = _calculateVIPMint(_stakeAmount);

        uint256 mintFee = stakePoolState.mintFeeEnabled ? vIPToMint * stakePoolState.mintFeeBps / 10000 : 0;
        vIPToMint -= mintFee;

        IVerioIP vIP = _selector().verioIP();
        address treasury = _selector().treasury();

        if (mintFee > 0) {
            vIP.mint(treasury, mintFee);
        }

        vIP.mint(_staker, vIPToMint);
    }

    /// @notice Evaluates and processes pending stakes
    /// @dev Iteratively delegates stakes up to maxStakeIterations
    function _evaluateStakePool() internal {
        StakePoolState storage stakePoolState = _stakePoolState();
        for (
            uint256 i = 0;
            i < stakePoolState.maxStakeIterations && address(this).balance >= stakePoolState.delegationSize;
            i++
        ) {
            uint256 amountToStake = _scaleStakeSize();
            _selector().delegator().handleStake{value: amountToStake}();
        }
    }

    /// @notice Calculates optimal stake size
    /// @return Scaled stake amount based on available balance and max stake limit
    function _scaleStakeSize() internal view returns (uint256) {
        StakePoolState storage stakePoolState = _stakePoolState();
        uint256 scaledStakeAmount = stakePoolState.delegationSize;
        while (scaledStakeAmount * 10 <= address(this).balance && scaledStakeAmount * 10 <= stakePoolState.maxStake) {
            scaledStakeAmount *= 10;
        }
        return scaledStakeAmount;
    }

    /// @inheritdoc IStakePool
    function adminStake(bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity)
        external
        payable
        override
        onlyAdmin
    {
        uint256 delegationSize = _stakePoolState().delegationSize;
        require(msg.value >= delegationSize, AdminStakeLessThanDelegationSize(delegationSize));
        _adminStake(msg.value, _validator, _maturity);
    }

    /// @notice Internal function to handle admin staking
    /// @param _amount Amount of IP to stake
    /// @param _validator Validator identification bytes
    /// @param _maturity Staking period enum value
    /// @dev Mints vIP tokens and delegates stake to specified validator
    function _adminStake(uint256 _amount, bytes calldata _validator, IIPTokenStaking.StakingPeriod _maturity)
        internal
    {
        emit Staked(msg.sender, _amount);
        uint256 vIPToMint = _calculateVIPMint(_amount);
        _selector().verioIP().mint(msg.sender, vIPToMint);
        _selector().delegator().handleAdminStake{value: _amount}(_validator, _maturity);
    }

    /// @inheritdoc IStakePool
    function restake() external override nonReentrant whenNotPaused {
        _restake();
    }

    /// @notice Internal function to claim rewards and restake
    function _restake() internal {
        _selector().rewardPool().claimRewards();
    }

    /// @inheritdoc IStakePool
    function unstake(uint256 _vIPAmount) external override nonReentrant whenNotPaused {
        _unstake(msg.sender, _vIPAmount);
    }

    /// @notice Internal unstaking logic
    /// @param _unstaker Address of the user unstaking
    /// @param _vIPAmount Amount of vIP tokens to unstake
    /// @dev Handles burn fees, withdrawal creation, and excess unstake management
    function _unstake(address _unstaker, uint256 _vIPAmount) internal {
        StakePoolState storage stakePoolState = _stakePoolState();
        require(block.number > stakePoolState.singularity, CannotUnstakeBeforeSingularity(stakePoolState.singularity));

        uint256 burnFee = stakePoolState.burnFeeEnabled ? _vIPAmount * stakePoolState.burnFeeBps / 10000 : 0;

        // user will unstake based on the amount after burn fee if there is one
        uint256 ipToWithdraw = _calculateIPWithdrawal(_vIPAmount - burnFee);
        require(ipToWithdraw > 0, CannotUnstakeZeroIP());
        emit Unstaked(_unstaker, ipToWithdraw);

        IVerioIP vIP = _selector().verioIP();
        IDelegator delegator = _selector().delegator();
        IWithdrawalPool withdrawalPool = _selector().withdrawalPool();
        address treasury = _selector().treasury();

        // rather than transferring the fee, we just mint it to the treasury
        if (burnFee > 0) {
            vIP.mint(treasury, burnFee);
        }

        // add the owed IP to the pending unstake
        stakePoolState.pendingUnstake += ipToWithdraw;

        // try to use up the remaining excessUnstake before actually unstaking
        if (stakePoolState.excessUnstake > stakePoolState.pendingUnstake) {
            stakePoolState.excessUnstake -= stakePoolState.pendingUnstake;
            stakePoolState.pendingUnstake = 0;
        } else {
            stakePoolState.pendingUnstake -= stakePoolState.excessUnstake;
            stakePoolState.excessUnstake = 0;
        }

        // if there's still pending unstake, let the delegator handle it
        if (stakePoolState.pendingUnstake >= stakePoolState.delegationSize) {
            uint256 excessUnstake = delegator.handleUnstake(stakePoolState.pendingUnstake);
            stakePoolState.pendingUnstake = 0;
            stakePoolState.excessUnstake += excessUnstake;
        }

        // we still burn the full amount
        vIP.burn(_unstaker, _vIPAmount);

        withdrawalPool.addWithdrawal(_unstaker, ipToWithdraw, stakePoolState.unbondingPeriod);
        withdrawalPool.handleBalance();
    }

    /// @inheritdoc IStakePool
    function calculateVIPMint(uint256 _ipAmount) external view override returns (uint256) {
        uint256 totalStakedIP = _getTotalStake();
        uint256 totalSupply = _getTotalSupply();
        if (totalSupply == 0) {
            return _ipAmount; // ignore the case where there's rewards in pool, treat this as initial state.
        }
        uint256 newVIPTotalSupply =
            totalSupply * (totalStakedIP + _ipAmount + address(this).balance) / (totalStakedIP + address(this).balance);
        return newVIPTotalSupply - totalSupply;
    }

    /// @notice Internal calculation of vIP minting amount
    /// @param _ipAmount Amount of IP to calculate vIP for
    /// @return Amount of vIP to mint
    /// @dev Uses different formula than external calculation
    function _calculateVIPMint(uint256 _ipAmount) internal view returns (uint256) {
        uint256 totalStakedIP = _getTotalStake();
        uint256 totalSupply = _getTotalSupply();
        if (totalSupply == 0) {
            return _ipAmount; // ignore the case where there's rewards in pool, treat this as initial state.
        }
        uint256 newVIPTotalSupply =
            totalSupply * (totalStakedIP + address(this).balance) / (totalStakedIP + address(this).balance - _ipAmount);
        return newVIPTotalSupply - totalSupply;
    }

    /// @inheritdoc IStakePool
    function calculateIPWithdrawal(uint256 _vIPAmount) external view override returns (uint256) {
        return _calculateIPWithdrawal(_vIPAmount);
    }

    /// @notice Internal calculation of IP withdrawal amount
    function _calculateIPWithdrawal(uint256 _vIPAmount) internal view returns (uint256) {
        uint256 totalStakedIP = _getTotalStake();
        uint256 totalSupply = _getTotalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        if (totalSupply == _vIPAmount) {
            return totalStakedIP + address(this).balance;
        }

        /**
         * Make sure dust is swept in favor of the protocol.
         * By adding denominator - 1 to the numerator, the calculation
         * always rounds up the dust value.
         */
        uint256 totalIPAfterUnstake =
            ((totalStakedIP + address(this).balance) * (totalSupply - _vIPAmount) + totalSupply - 1) / totalSupply;
        return totalStakedIP + address(this).balance - totalIPAfterUnstake;
    }

    // --- GETTERS & SETTERS---

    /// @inheritdoc IStakePool
    function getTotalStake() external view override returns (uint256) {
        return _getTotalStake();
    }

    /// @notice Internal function to get total stake
    /// @return Total amount of IP staked across all validators
    function _getTotalStake() internal view returns (uint256) {
        StakePoolState storage stakePoolState = _stakePoolState();
        return _selector().delegator().getGlobalDistributionTotal() + stakePoolState.excessUnstake
            - stakePoolState.pendingUnstake;
    }

    /// @notice Internal function to get total supply
    /// @return Total amount of vIP tokens in circulation
    function _getTotalSupply() internal view returns (uint256) {
        return _selector().verioIP().getTotalSupply();
    }

    /// @inheritdoc IStakePool
    function getStakePoolAmount() external view override returns (uint256) {
        return address(this).balance;
    }

    /// @inheritdoc IStakePool
    function getMinStake() external view override returns (uint256) {
        return _stakePoolState().minStake;
    }

    /// @inheritdoc IStakePool
    function setMinStake(uint256 _minStake) external override onlyAdmin {
        require(_isValidMinStake(_minStake), InvalidMinStake());
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.minStake = _minStake;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getMintFeeBps() external view override returns (uint256) {
        return _stakePoolState().mintFeeBps;
    }

    /// @inheritdoc IStakePool
    function setMintFeeBps(uint256 _mintFeeBps) external override onlyAdmin {
        require(_isValidMintFee(_mintFeeBps), MaxMintFeeExceeded(500));
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.mintFeeBps = _mintFeeBps;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getBurnFeeBps() external view override returns (uint256) {
        return _stakePoolState().burnFeeBps;
    }

    /// @inheritdoc IStakePool
    function setBurnFeeBps(uint256 _burnFeeBps) external override onlyAdmin {
        require(_isValidBurnFee(_burnFeeBps), MaxBurnFeeExceeded(500));
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.burnFeeBps = _burnFeeBps;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getMintFeeEnabled() external view override returns (bool) {
        return _stakePoolState().mintFeeEnabled;
    }

    /// @inheritdoc IStakePool
    function setMintFeeEnabled(bool _mintFeeEnabled) external override onlyAdmin {
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.mintFeeEnabled = _mintFeeEnabled;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getBurnFeeEnabled() external view override returns (bool) {
        return _stakePoolState().burnFeeEnabled;
    }

    /// @inheritdoc IStakePool
    function setBurnFeeEnabled(bool _burnFeeEnabled) external override onlyAdmin {
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.burnFeeEnabled = _burnFeeEnabled;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getDelegationSize() external view override returns (uint256) {
        return _stakePoolState().delegationSize;
    }

    /// @inheritdoc IStakePool
    function setDelegationSize(uint256 _delegationSize) external override onlyAdmin {
        require(_isValidDelegationSize(_delegationSize), InvalidDelegationSize());
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.delegationSize = _delegationSize;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getUnbondingPeriod() external view override returns (uint256) {
        return _stakePoolState().unbondingPeriod;
    }

    /// @inheritdoc IStakePool
    function setUnbondingPeriod(uint256 _unbondingPeriod) external override onlyAdmin {
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.unbondingPeriod = _unbondingPeriod;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getMaxStakeIterations() external view override returns (uint256) {
        return _stakePoolState().maxStakeIterations;
    }

    /// @inheritdoc IStakePool
    function setMaxStakeIterations(uint256 _maxStakeIterations) external override onlyAdmin {
        require(_maxStakeIterations > 0, InvalidMaxStakeIterations());
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.maxStakeIterations = _maxStakeIterations;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getMaxStake() external view override returns (uint256) {
        return _stakePoolState().maxStake;
    }

    /// @inheritdoc IStakePool
    function setMaxStake(uint256 _maxStake) external override onlyAdmin {
        require(_isValidMaxStake(_maxStake), InvalidMaxStake());
        StakePoolState storage stakePoolState = _stakePoolState();
        stakePoolState.maxStake = _maxStake;
        emit StakePoolStateUpdated(stakePoolState);
    }

    /// @inheritdoc IStakePool
    function getPendingUnstake() external view override returns (uint256) {
        return _stakePoolState().pendingUnstake;
    }

    /// @inheritdoc IStakePool
    function getUnstaked() external view override returns (uint256) {
        return _stakePoolState().excessUnstake;
    }

    // --- RECEIVER ---

    /// @notice Receive function to handle incoming ETH
    /// @dev Emits RewardReceived event for received ETH
    receive() external payable {
        if (msg.value > 0) {
            emit RewardReceived(msg.value);
        }
    }
}
