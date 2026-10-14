// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// Nsure "Underwriting" (0x1a66f065...) and "Treasury" (0xfd0d2853...) share the same code
interface IPool {
    function owner() external view returns (address);
    function operator() external view returns (address);
    function signer() external view returns (address);
    function Nsure() external view returns (address);
    function name() external view returns (string memory);
    function version() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function claimAt(address) external view returns (uint256);
    function claimDuration() external view returns (uint256);
    function deadlineDuration() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function divCurrencies(uint256) external view returns (address divCurrency, uint256 limit);
    function getDivCurrencyLength() external view returns (uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 _amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function claim(uint256 _amount, uint256 currency, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function setSigner(address) external;
    function setOperator(address) external;
    function payouts(address payable _to, uint256 _amount, address token) external;
}

interface ISurplus {
    function owner() external view returns (address);
    function operator() external view returns (address);
    function payouts(address payable _to, uint256 _amount, address token) external;
    function setOperator(address) external;
}

interface ICapitalStake {
    function owner() external view returns (address);
    function operator() external view returns (address);
    function signer() external view returns (address);
    function paused() external view returns (bool);
    function canDeposit() external view returns (bool);
    function poolLength() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function nsurePerBlock() external view returns (uint256);
    function pendingDuration() external view returns (uint256);
    function pendingNsure(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt, uint256 reward, uint256 pendingWithdrawal, uint256 pendingAt);
    function poolInfo(uint256) external view returns (uint256 amount, address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accNsurePerShare, uint256 pending);
    function deposit(uint256 _pid, uint256 _amount) external;
    function unstake(uint256 _pid, uint256 _amount, uint8 v, bytes32 r, bytes32 s, uint256 deadline) external;
    function withdraw(uint256 _pid) external;
    function claim(uint256 _pid) external;
    function updatePool(uint256 _pid) external;
    function massUpdatePools() external;
}

interface ICapitalConverter {
    function owner() external view returns (address);
    function operator() external view returns (address);
    function paused() external view returns (bool);
    function token() external view returns (address);
    function maxConvert() external view returns (uint256);
    function smartBalance() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function depositAt(address) external view returns (uint256);
    function convert(uint256 _amount) external payable;
    function exit(uint256 _value) external;
    function payouts(address payable _to, uint256 _amount) external;
    function setOperator(address) external;
}

interface IBuy {
    function owner() external view returns (address);
    function signer() external view returns (address);
    function underWriting() external view returns (address);
    function surplus() external view returns (address);
    function treasury() external view returns (address);
    function product() external view returns (address);
    function WETH() external view returns (address);
    function orderIndex() external view returns (uint256);
    function buyInsurance(
        uint256 _productId, uint256 _amount, uint256 _cost, uint256 period,
        uint8 v, bytes32 r, bytes32 s, uint256 deadline, uint256 currency
    ) external payable;
}

interface INsureToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function owner() external view returns (address);
    function getMinterLength() external view returns (uint256);
    function isMinter(address) external view returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
}
