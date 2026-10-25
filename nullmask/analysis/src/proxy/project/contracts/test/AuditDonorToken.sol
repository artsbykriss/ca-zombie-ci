// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice AUDIT-ONLY: ERC20 that donates `donateToken` to `victim` on every transfer.
contract AuditDonorToken {
    string public name = "Donor";
    string public symbol = "DON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public victim;
    address public donateToken;
    uint256 public donateAmount;

    constructor(uint256 supply) {
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    function arm(address _victim, address _donateToken, uint256 _amount) external {
        victim = _victim;
        donateToken = _donateToken;
        donateAmount = _amount;
    }

    function _hook() internal {
        if (donateAmount > 0 && donateToken != address(0)) {
            uint256 amt = donateAmount;
            donateAmount = 0; // only once
            IERC20(donateToken).transfer(victim, amt);
        }
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        _hook();
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        _hook();
        return true;
    }
}
