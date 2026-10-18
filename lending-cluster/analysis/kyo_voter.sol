// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingMath} from "contracts/lib/StakingMath.sol";

import {SingleStreamConsumer} from "contracts/reward/SingleStreamConsumer.sol";
import {TokenStreamSplitter} from "contracts/reward/TokenStreamSplitter.sol";

import {IERC4626TokenStreamSplitter} from "contracts/reward/interfaces/IERC4626TokenStreamSplitter.sol";
import {ITokenStreamEmitter} from "contracts/reward/interfaces/ITokenStreamEmitter.sol";

import {IVoter} from "contracts/voting/interfaces/IVoter.sol";
import {Ownable} from "openzeppelin-v5/access/Ownable.sol";
import {IERC20} from "openzeppelin-v5/token/ERC20/IERC20.sol";

import {Context} from "openzeppelin-v5/utils/Context.sol";
import {ReentrancyGuardTransient} from "openzeppelin-v5/utils/ReentrancyGuardTransient.sol";
import {ERC6909} from "solmate/tokens/ERC6909.sol";

abstract contract Voter is ReentrancyGuardTransient, ERC6909, SingleStreamConsumer, TokenStreamSplitter, Ownable {
    event Vote(address indexed gauge, address indexed by, uint256 amount);
    event Unvote(address indexed gauge, address indexed by, uint256 amount);

    IERC20 public immutable ballot;
    IERC4626TokenStreamSplitter private immutable rewardSource;

    function totalSupply(uint256 id) external view returns (uint256) {
        if (id > type(uint160).max) return 0;
        return getWeight(address(uint160(id)));
    }

    constructor(IERC4626TokenStreamSplitter source_) SingleStreamConsumer(source_) {
        rewardSource = source_;
        ballot = IERC20(rewardSource.asset());
        ballot.approve(address(rewardSource), type(uint256).max);
    }

    function vote(address gauge, uint256 amount, address recipient) external nonReentrant {
        if (amount == 0) return;
        require(amount <= type(uint128).max, "Voter: amount cannot be larger than type(uint128).max");
        ballot.transferFrom(msg.sender, address(this), amount);
        rewardSource.deposit(amount, address(this));
        _increaseWeight(gauge, uint128(amount));
        _mint(recipient, uint160(gauge), amount);
        emit Vote(gauge, msg.sender, amount);
    }

    function unvote(address gauge, uint256 amount, address recipient) external nonReentrant {
        if (amount == 0) return;
        require(amount <= type(uint128).max, "Voter: amount cannot be larger than type(uint128).max");
        _decreaseWeight(gauge, uint128(amount));
        rewardSource.withdraw(amount, recipient, address(this));
        _burn(msg.sender, uint160(gauge), amount);
        emit Unvote(gauge, msg.sender, amount);
    }

    function disable(address gauge) external nonReentrant onlyOwner {
        _disable(gauge);
    }

    function enable(address gauge) external nonReentrant onlyOwner {
        _enable(gauge);
    }
}

