import {ITokenStreamEmitter} from "./ITokenStreamEmitter.sol";
import {IERC4626} from "openzeppelin-v5/interfaces/IERC4626.sol";

interface IERC4626TokenStreamSplitter is IERC4626, ITokenStreamEmitter {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {StakingMath} from "contracts/lib/StakingMath.sol";
import {TokenStreamConsumer} from "contracts/reward/TokenStreamConsumer.sol";
import {TokenStreamEmitter} from "contracts/reward/TokenStreamEmitter.sol";
import {IRewardSource} from "contracts/reward/interfaces/IRewardSource.sol";
import {IERC20} from "openzeppelin-v5/token/ERC20/IERC20.sol";
import {Context} from "openzeppelin-v5/utils/Context.sol";
import {SlotDerivation} from "openzeppelin-v5/utils/SlotDerivation.sol";
import {TransientSlot} from "openzeppelin-v5/utils/TransientSlot.sol";
import {Math} from "openzeppelin-v5/utils/math/Math.sol";

abstract contract TokenStreamSplitter is TokenStreamConsumer, TokenStreamEmitter {
    error ReceiverNotWhitelisted();

    using TransientSlot for bytes32;
    using TransientSlot for TransientSlot.Uint256Slot;
    using SlotDerivation for bytes32;
    using StakingMath for StakingMath.Ledger;

    StakingMath.Ledger private ledger;
    mapping(address => uint128) private lastSeenPendingInputAmounts;

    uint256 private transient distributeCount;
    bytes32 private immutable distributeCountAtLastPoke;

    constructor() {
        distributeCountAtLastPoke = SlotDerivation.erc7201Slot("TokenStreamEmitter.DCALP");
    }

    function _poke(address account) private {
        TransientSlot.Uint256Slot slot = distributeCountAtLastPoke.deriveMapping(account).asUint256();
        if (slot.tload() == distributeCount) return;
        ledger.poke(_inputTokens(), account);
        slot.tstore(distributeCount);
    }

    function _increaseWeight(address account, uint128 amount) internal {
        require(_whitelisted(account), ReceiverNotWhitelisted());
        _distribute();
        _poke(account);
        ledger.stake(account, amount);
    }

    function _decreaseWeight(address account, uint128 amount) internal {
        _distribute();
        _poke(account);
        ledger.unstake(account, amount);
    }

    function getWeight(address account) public view returns (uint128) {
        return ledger.effectiveStakes(account);
    }

    function getTotalWeight() public view returns (uint256) {
        return ledger.totalStakes;
    }

    function _outputTokens() internal view override returns (address[] memory) {
        return _inputTokens();
    }

    function _disable(address account) internal {
        _distribute();
        _poke(account);
        ledger.disable(account);
    }

    function _enable(address account) internal {
        _distribute();
        _poke(account);
        ledger.enable(account);
    }

    function _distribute() internal {
        if (!_shouldDistribute()) return;
        distributeCount += 1;
        address[] memory inputTokens = _inputTokens();
        for (uint256 i = 0; i < inputTokens.length; i++) {
            address token = inputTokens[i];
            uint128 pendingAmount = _pendingInputAmountWithUpdate(token);
            uint128 lastSeen = lastSeenPendingInputAmounts[token];
            if (pendingAmount > lastSeen) {
                ledger.distribute(token, pendingAmount - lastSeen);
                lastSeenPendingInputAmounts[token] = pendingAmount;
            }
        }
    }

    function _pendingOutputAmount(address token, address account) internal view override returns (uint128 amount) {
        uint128 pendingAmount = _pendingInputAmount(token);
        uint128 lastSeen = lastSeenPendingInputAmounts[token];
        if (pendingAmount <= lastSeen) return 0;
        return ledger.claimable(token, pendingAmount - lastSeen, account);
    }

    function _pendingOutputAmountWithUpdate(address token, address account) internal override returns (uint128 amount) {
        _distribute();
        _poke(account);
        return ledger.owed(token, account);
    }

    function _sendOutput(address token, address account, address recipient, uint128 maxAmount) internal override returns (uint128 amount) {
        _distribute();
        _poke(account);
        amount = ledger.collect(token, account, maxAmount);
        lastSeenPendingInputAmounts[token] -= amount;
        _takeInput(token, recipient, amount);
        return amount;
    }

    function _tokenOutputPerSecondX128(address token, address account) internal view override returns (uint256) {
        uint256 balance = ledger.effectiveStakes(account);
        if (balance == 0) return 0;
        return Math.mulDiv(_tokenInputPerSecondX128(token), balance, ledger.totalStakes);
    }

    function _shouldDistribute() internal view virtual returns (bool) {
        return distributeCount == 0;
    }

    function _whitelisted(address) internal view virtual returns (bool) {
        return true;
    }

    function _collectUndistributed(address token, address recipient) internal {
        _distribute();
        uint128 amt = ledger.collectUndistributed(token);
        if (amt > 0) {
            lastSeenPendingInputAmounts[token] -= amt;
            _takeInput(token, recipient, amt);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {TokenStreamSplitter} from "./TokenStreamSplitter.sol";
import {IERC4626TokenStreamSplitter} from "contracts/reward/interfaces/IERC4626TokenStreamSplitter.sol";
import {IERC20} from "openzeppelin-v5/token/ERC20/IERC20.sol";
import {ERC4626} from "openzeppelin-v5/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-v5/utils/math/Math.sol";

abstract contract ERC4626TokenStreamSplitter is ERC4626, TokenStreamSplitter {
    constructor(IERC20 asset) ERC4626(asset) {}

    function totalAssets() public view virtual override returns (uint256) {
        return _convertToAssets(totalSupply(), Math.Rounding.Floor);
    }

    function _convertToShares(uint256 assets, Math.Rounding) internal view virtual override returns (uint256) {
        return assets;
    }

    function _convertToAssets(uint256 shares, Math.Rounding) internal view virtual override returns (uint256) {
        return shares;
    }

    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override nonReentrant returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        require(value <= type(uint128).max, "value too large");
        if (value != 0) {
            if (from != address(0)) _decreaseWeight(from, uint128(value));
            if (to != address(0)) _increaseWeight(to, uint128(value));
        }
    }
}

