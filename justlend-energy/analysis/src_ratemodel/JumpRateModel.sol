// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IRateModel.sol";

contract JumpRateModel is IRateModel {

    address public owner;

    // rate per second
    uint256 public baseRate;

    uint256 public multiplier;

    uint256 public jumpMultiplier;

    uint256 public kink;

    event NewInterestParams(uint256 baseRatePerSecond, uint256 multiplierPerSecond, uint256 jumpMultiplierPerSecond, uint256 kink);

    event OwnerUpdated(address oldOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "permission denied: not owner");
        _;
    }

    constructor(
        uint256 _baseRatePerDay,
        uint256 _multiplierPerDay,
        uint256 _jumpMultiplierPerDay,
        uint256 _kink,
        address _owner
    )
    {
        require(_owner != address(0), "owner is zero address");
        owner = _owner;

        updateJumpRateModelInternal(_baseRatePerDay, _multiplierPerDay, _jumpMultiplierPerDay, _kink);
    }

    function replaceOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is zero address");
        address oldOwner = owner;
        owner = newOwner;

        emit OwnerUpdated(oldOwner, newOwner);
    }

    function renounceOwner() external onlyOwner {
        address oldOwner = owner;
        owner = address(0);

        emit OwnerUpdated(oldOwner, address(0));
    }

    // TODO: 在更新参数时必须先在 STRX 合约触发 updateIndex，否则 index 记录会出错.
    function updateJumpRateModel(
        uint256 _baseRate,
        uint256 _multiplier,
        uint256 _jumpMultiplier,
        uint256 _kink
    )
        external
        onlyOwner
    {
        updateJumpRateModelInternal(_baseRate, _multiplier, _jumpMultiplier, _kink);
    }

    function getRentalRate(uint256 supply, uint256 borrows) external view returns (uint256) {
        uint256 util = utilizationRate(supply, borrows);

        if (util <= kink) {
            return util * multiplier / 1e18 + baseRate;
        } else {
            uint256 _kink = kink;
            uint256 normalRate = _kink * multiplier /  1e18 + baseRate;
            uint256 excessUtil = util - _kink;
            return excessUtil * jumpMultiplier / 1e18 + normalRate;
        }
    }

    function updateJumpRateModelInternal(
        uint256 _baseRatePerDay,
        uint256 _multiplierPerDay,
        uint256 _jumpMultiplierPerDay,
        uint256 _kink
    )
        internal
    {
        baseRate = _baseRatePerDay / 1 days;
        multiplier = _multiplierPerDay * 1e18 / (1 days * _kink);
        jumpMultiplier = _jumpMultiplierPerDay / 1 days;
        kink = _kink;

        emit NewInterestParams(baseRate, multiplier, jumpMultiplier, _kink);
    }

    function utilizationRate(uint256 supply, uint256 borrows) internal pure returns (uint256) {
        if (supply == 0 || borrows == 0) {
            return 0;
        }

        return borrows * 1e18 / supply;
    }

}