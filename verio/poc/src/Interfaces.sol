// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStakePool {
    function stake(bool _evaluate) external payable;
    function unstake(uint256 _vIPAmount) external;
    function restake() external;
    function evaluateStakePool() external;
    function fund() external payable;
    function getTotalStake() external view returns (uint256);
    function getUnstaked() external view returns (uint256);
    function getPendingUnstake() external view returns (uint256);
    function getStakePoolAmount() external view returns (uint256);
    function calculateVIPMint(uint256 _ipAmount) external view returns (uint256);
    function calculateIPWithdrawal(uint256 _vIPAmount) external view returns (uint256);
    function getUnbondingPeriod() external view returns (uint256);
    function getDelegationSize() external view returns (uint256);
    function getBurnFeeBps() external view returns (uint256);
    function getBurnFeeEnabled() external view returns (bool);
    function getMintFeeBps() external view returns (uint256);
    function getMintFeeEnabled() external view returns (bool);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function getAdmin() external view returns (address);
    function setAdmin(address _admin) external;
    function getSelector() external view returns (address);
}

interface IWithdrawalPool {
    struct Withdrawal {
        uint256 amount;
        uint256 unbondedTimestamp;
    }

    function handleBalance() external;
    function withdraw() external;
    function addWithdrawal(address _recipient, uint256 _amount, uint256 _unbondingPeriod) external;
    function fund() external payable;
    function getTotalWithdrawalPool() external view returns (uint256);
    function getTotalPendingWithdrawals() external view returns (uint256);
    function getWithdrawalsByRecipient(address _recipient) external view returns (Withdrawal[] memory);
    function getUnbondedWithdrawalsByRecipient(address _recipient) external view returns (Withdrawal[] memory);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function getAdmin() external view returns (address);
    function getVersion() external view returns (string memory);
}

interface IVerioIP {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IDelegator {
    struct Delegation {
        bytes validator;
        uint256 id;
        uint8 maturity;
        uint256 amount;
        uint256 startTimestamp;
        uint256 duration;
        uint256 endTimestamp;
    }

    function getGlobalDistributionTotal() external view returns (uint256);
    function handleUnstake(uint256 _amount) external returns (uint256 excessUnstake);
    function handleUnstakeQueue() external;
    function setAdmin(address _admin) external;
    function setWithdrawalAddress() external;
    function getAdmin() external view returns (address);
    function owner() external view returns (address);
    function getUnstakeQueueValidators() external view returns (bytes[] memory);
    function getUnstakeQueueByValidator(bytes calldata _validator) external view returns (Delegation[] memory);
}

interface IComponentSelector {
    function stakePool() external view returns (address);
    function withdrawalPool() external view returns (address);
    function delegator() external view returns (address);
    function verioIP() external view returns (address);
    function treasury() external view returns (address);
    function rewardPool() external view returns (address);
    function insurancePoolByComponent(address _component) external view returns (address);
    function getAdmin() external view returns (address);
    function owner() external view returns (address);
    function setAdmin(address _admin) external;
    function setWithdrawalPool(address _withdrawalPool) external;
    function setStakePool(address _stakePool) external;
    function getVersion() external view returns (string memory);
}

interface IInsurancePool {
    function claim(uint256 _amount) external;
    function fund() external payable;
    function getBalance() external view returns (uint256);
    function available() external view returns (uint256);
    function getAdmin() external view returns (address);
    function owner() external view returns (address);
}

interface IRewardPool {
    function claimRewards() external;
    function getRewards() external view returns (uint256);
}
