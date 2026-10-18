// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IEmissionSchedule} from "contracts/interfaces/IEmissionSchedule.sol";
import {FixedTokenStreamEmitter} from "contracts/reward/FixedTokenStreamEmitter.sol";
import {Ownable} from "openzeppelin-v5/access/Ownable.sol";
import {IERC20} from "openzeppelin-v5/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-v5/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-v5/utils/math/Math.sol";

contract FixedEmission is FixedTokenStreamEmitter, Ownable {
    using SafeERC20 for IERC20;

    event EmissionSchedule(address);

    error TotalEmissionMustNotDecrease();

    IERC20 public immutable rewardToken;

    uint256 public totalEmitted;
    IEmissionSchedule public emissionSchedule;

    constructor(IERC20 rewardToken_, address rewardRecipient_, IEmissionSchedule schedule)
        Ownable(msg.sender)
        FixedTokenStreamEmitter(rewardRecipient_)
    {
        rewardToken = rewardToken_;
        emissionSchedule = schedule;
        emit EmissionSchedule(address(schedule));
    }

    function _pendingInputAmountUncached(address token) internal view override returns (uint128) {
        if (token != address(rewardToken)) return 0;
        uint256 currentTotalEmission = emissionSchedule.totalEmissionAt(block.timestamp);
        if (currentTotalEmission < totalEmitted) return 0;
        uint256 pending = Math.min(currentTotalEmission - totalEmitted, rewardToken.balanceOf(address(this)));
        return uint128(Math.min(type(uint128).max, pending));
    }

    function _pendingInputAmountWithUpdateUncached(address token) internal view override returns (uint128) {
        return _pendingInputAmountUncached(token);
    }

    function setSchedule(IEmissionSchedule newSchedule) external onlyOwner {
        require(newSchedule.totalEmissionAt(block.timestamp) >= emissionSchedule.totalEmissionAt(block.timestamp), TotalEmissionMustNotDecrease());
        emissionSchedule = newSchedule;
        emit EmissionSchedule(address(newSchedule));
    }

    function _tokenInputPerSecondX128(address token_) internal view override returns (uint256) {
        if (token_ != address(rewardToken)) return 0;
        return emissionSchedule.emissionRateAt(block.timestamp);
    }

    function _inputTokens() internal view override returns (address[] memory) {
        address[] memory r = new address[](1);
        r[0] = address(rewardToken);
        return r;
    }

    function _takeInputRaw(address token, address recipient, uint128 amount) internal override returns (uint128) {
        if (token != address(rewardToken)) return 0;
        totalEmitted += amount;
        rewardToken.safeTransfer(recipient, amount);
        return amount;
    }
}

