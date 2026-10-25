// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAaveV3Pool, IAToken} from "src/Strategies/AaveV3Strategy.sol";

contract LocalAToken is IAToken {
    using SafeERC20 for IERC20;

    address public pool;
    mapping(address => uint256) internal _scaled;

    constructor(address _pool, address) {
        pool = _pool;
    }

    function setPool(address _pool) external {
        pool = _pool;
    }

    function scaledBalanceOf(address account) external view override returns (uint256) {
        return _scaled[account];
    }

    function balanceOf(address account) external view override returns (uint256) {
        uint256 index = LocalAavePool(pool).liquidityIndex();
        return (_scaled[account] * index) / 1e27;
    }

    function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
        return address(LocalAavePool(pool).asset());
    }

    function mintScaled(address to, uint256 amount) external {
        require(msg.sender == pool, "LocalAToken: only pool");
        _scaled[to] += amount;
    }

    function burnScaled(address from, uint256 amount) external {
        require(msg.sender == pool, "LocalAToken: only pool");
        _scaled[from] -= amount;
    }

    function transferUnderlyingTo(address to, uint256 amount) external {
        require(msg.sender == pool, "LocalAToken: only pool");
        IERC20(LocalAavePool(pool).asset()).safeTransfer(to, amount);
    }
}

contract LocalAavePool is IAaveV3Pool {
    using SafeERC20 for IERC20;

    uint256 internal constant RAY = 1e27;

    IERC20 public asset;
    LocalAToken public aToken;
    uint256 public liquidityIndex = RAY;

    function setAsset(IERC20 _asset) external {
        asset = _asset;
    }

    function setAToken(LocalAToken _aToken) external {
        aToken = _aToken;
    }

    function setLiquidityIndex(uint256 _index) external {
        liquidityIndex = _index;
    }

    function supply(address _asset, uint256 _amount, address _onBehalfOf, uint16) external override {
        require(_asset == address(asset), "LocalAavePool: asset mismatch");
        asset.safeTransferFrom(msg.sender, address(aToken), _amount);
        uint256 scaledAmt = (_amount * RAY) / liquidityIndex;
        aToken.mintScaled(_onBehalfOf, scaledAmt);
    }

    function withdraw(address _asset, uint256 _amount, address _to) external override returns (uint256) {
        require(_asset == address(asset), "LocalAavePool: asset mismatch");
        uint256 scaledBal = aToken.scaledBalanceOf(msg.sender);
        uint256 currentBal = (scaledBal * liquidityIndex) / RAY;

        uint256 amountOut = _amount > currentBal ? currentBal : _amount;
        uint256 scaledToBurn = (amountOut * RAY) / liquidityIndex;
        if (scaledToBurn > scaledBal) scaledToBurn = scaledBal;

        aToken.burnScaled(msg.sender, scaledToBurn);
        aToken.transferUnderlyingTo(_to, amountOut);
        return amountOut;
    }

    function getReserveNormalizedIncome(address) external view override returns (uint256) {
        return liquidityIndex;
    }
}
