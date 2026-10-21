// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IStakeManager {
    function getRate() external view returns (uint256);
    function rate() external view returns (uint256);
    function totalProtocolFee() external view returns (uint256);
    function latestEra() external view returns (uint256);
    function currentEra() external view returns (uint256);
    function eraSeconds() external view returns (uint256);
    function eraOffset() external view returns (uint256);
    function unbondingDuration() external view returns (uint256);
    function minStakeAmount() external view returns (uint256);
    function rateChangeLimit() external view returns (uint256);
    function protocolFeeCommission() external view returns (uint256);
    function lsdToken() external view returns (address);
    function nextUnstakeIndex() external view returns (uint256);
    function owner() external view returns (address);
    function getBondedPools() external view returns (address[] memory);
    function getValidatorsOf(address pool) external view returns (address[] memory);
    function poolInfoOf(address pool)
        external
        view
        returns (uint256 era, uint256 bond, uint256 unbond, uint256 active);
    function getUnstakeIndexListOf(address staker) external view returns (uint256[] memory);
    function unstakeAtIndex(uint256 index)
        external
        view
        returns (uint256 era, address pool, address receiver, uint256 amount);
    function eraRate(uint256 era) external view returns (uint256);

    function stake(string calldata memo) external payable;
    function stakeWithPool(address pool, string calldata memo) external payable;
    function stakeWithPoolReceiver(address pool, address receiver, string calldata memo) external payable;
    function unstake(uint256 lsdAmount) external;
    function unstakeWithPool(address pool, uint256 lsdAmount) external;
    function withdraw() external;
    function withdrawWithPool(address pool) external;
    function newEra() external;
    function setRateChangeLimit(uint256 limit) external;
    function setProtocolFeeCommission(uint256 commission) external;
    function withdrawProtocolFee(address to) external;
    function addStakePool(address pool) external;
    function upgradeTo(address impl) external;
}

interface IStakePool {
    function getTotalDelegated(address[] calldata validators) external view returns (uint256);
    function getDelegated(address validator) external view returns (uint256);
    function pendingBond() external view returns (uint256);
    function reservedFee() external view returns (uint256);
    function stakeManagerAddress() external view returns (address);
    function updateValidators(address[] calldata validators) external;
    function delegateMulti(address[] calldata validators, uint256 amount) external;
    function undelegateMulti(address[] calldata validators, uint256 amount) external;
    function withdrawForStaker(address staker, uint256 amount) external;
}

interface IValidator {
    function delegatorShares() external view returns (uint256);
    function tokens() external view returns (uint256);
    function getDelegation(address delegator) external view returns (uint256, uint256);
}
