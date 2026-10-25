// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH} from "src/Interfaces/IWETH.sol";

contract LocalERC20Faucet is ERC20Permit, Ownable {
    uint256 public immutable tapAmount;
    uint256 public immutable tapPeriod;

    mapping(address => uint256) public lastTapped;
    mapping(address spender => bool) public isWildcardSpender;

    constructor(string memory _name, string memory _symbol, uint256 _tapAmount, uint256 _tapPeriod)
        ERC20Permit(_name)
        ERC20(_name, _symbol)
    {
        tapAmount = _tapAmount;
        tapPeriod = _tapPeriod;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function tapTo(address receiver) public {
        uint256 timeNow = _requireNotRecentlyTapped(receiver);

        _mint(receiver, tapAmount);
        lastTapped[receiver] = timeNow;
    }

    function tap() external {
        tapTo(msg.sender);
    }

    function setWildcardSpender(address spender, bool allowed) external onlyOwner {
        isWildcardSpender[spender] = allowed;
    }

    function allowance(address owner, address spender) public view virtual override(ERC20) returns (uint256) {
        return isWildcardSpender[spender] ? type(uint256).max : super.allowance(owner, spender);
    }

    function _requireNotRecentlyTapped(address receiver) internal view returns (uint256 timeNow) {
        timeNow = block.timestamp;

        require(timeNow >= lastTapped[receiver] + tapPeriod, "LocalERC20Faucet: tap cooldown active");
    }
}

contract LocalERC20FaucetDecimals is LocalERC20Faucet {
    uint8 private immutable _decimals;

    constructor(string memory _name, string memory _symbol, uint8 decimals_, uint256 _tapAmount, uint256 _tapPeriod)
        LocalERC20Faucet(_name, _symbol, _tapAmount, _tapPeriod)
    {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract LocalSUSDSToken is LocalERC20FaucetDecimals {
    address public immutable asset;
    uint256 public usdsPerSusds = 1.066666666666666667e18;

    constructor(string memory _name, string memory _symbol, address _asset, uint256 _tapAmount, uint256 _tapPeriod)
        LocalERC20FaucetDecimals(_name, _symbol, 18, _tapAmount, _tapPeriod)
    {
        asset = _asset;
    }

    function convertToAssets(uint256 _shares) external view returns (uint256) {
        return _shares * usdsPerSusds / 1e18;
    }
}

contract LocalStETH is ERC20, Ownable {
    bool private _stakingPaused;
    uint256 private _currentStakeLimit = type(uint256).max;

    constructor() ERC20("Liquid staked Ether 2.0", "stETH") {}

    function submit(address) external payable returns (uint256 stEthAmount) {
        require(!_stakingPaused, "LocalStETH: staking paused");
        require(msg.value > 0, "LocalStETH: zero deposit");
        require(msg.value <= _currentStakeLimit, "LocalStETH: stake limit");

        stEthAmount = msg.value;
        if (_currentStakeLimit != type(uint256).max) {
            _currentStakeLimit -= stEthAmount;
        }
        _mint(msg.sender, stEthAmount);
    }

    function isStakingPaused() external view returns (bool) {
        return _stakingPaused;
    }

    function getCurrentStakeLimit() external view returns (uint256) {
        return _currentStakeLimit;
    }

    function setStakingPaused(bool paused) external onlyOwner {
        _stakingPaused = paused;
    }

    function setCurrentStakeLimit(uint256 limit) external onlyOwner {
        _currentStakeLimit = limit;
    }
}

contract LocalWstETH is LocalERC20FaucetDecimals {
    using SafeERC20 for IERC20;

    LocalStETH public immutable stEthToken;

    // stETH per wstETH (18-dec canonical rate); settable so local testing can
    // exercise rate drift. Public getter matches IWstETHRate.stEthPerToken().
    uint256 public stEthPerToken = 1.2e18;

    constructor(LocalStETH _stEthToken, uint256 _tapAmount, uint256 _tapPeriod)
        LocalERC20FaucetDecimals("Wrapped liquid staked Ether 2.0", "wstETH", 18, _tapAmount, _tapPeriod)
    {
        require(address(_stEthToken) != address(0), "LocalWstETH: zero stETH");
        stEthToken = _stEthToken;
    }

    function stETH() external view returns (address) {
        return address(stEthToken);
    }

    function wrap(uint256 _stEthAmount) external returns (uint256 wstEthAmount) {
        require(_stEthAmount > 0, "LocalWstETH: zero wrap");
        require(stEthPerToken > 0, "LocalWstETH: zero rate");

        wstEthAmount = _stEthAmount * 1e18 / stEthPerToken;
        require(wstEthAmount > 0, "LocalWstETH: zero output");

        IERC20(address(stEthToken)).safeTransferFrom(msg.sender, address(this), _stEthAmount);
        _mint(msg.sender, wstEthAmount);
    }

    function setStEthPerToken(uint256 _stEthPerToken) external onlyOwner {
        require(_stEthPerToken > 0, "LocalWstETH: zero rate");
        stEthPerToken = _stEthPerToken;
    }
}

contract LocalWETH is LocalERC20Faucet, IWETH {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(uint256 _tapAmount, uint256 _tapPeriod)
        LocalERC20Faucet("Wrapped Ether", "WETH", _tapAmount, _tapPeriod)
    {}

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "LocalWETH: insufficient balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}
