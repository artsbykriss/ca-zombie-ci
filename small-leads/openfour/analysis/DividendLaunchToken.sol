// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidityHelper} from "../interfaces/ILiquidityHelper.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {TokenConstants} from "../libs/TokenConstants.sol";

contract DividendLaunchToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 private constant MAGNITUDE = 2 ** 128;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public launched;
    uint16 public taxRateBps;
    bool private _dispatching;
    uint256 private _accruedTax;

    string public metaURI;
    address public taxRecipient;
    uint16 public recipientBps;
    uint16 public dividendBps;
    uint16 public burnBps;
    uint16 public lpBps;
    address public dexFactory;
    address public dexRouter;
    address public quoteToken;
    address public liquidityHelper;

    uint256 public minimumShareBalance;
    uint256 public minDispatch;
    uint256 public totalShares;
    uint256 public feePerShare;
    uint256 public quoteClaimed;

    EnumerableSet.AddressSet private _users;
    mapping(address => uint256) public shareOf;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public pendingBalance;

    event FeeClaimed(address indexed account, uint256 amount);

    error TransferDisabled();
    error InvalidTaxDistribution();
    error InsufficientQuoteBalance();
    error InvalidTaxRate();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        string memory metaURI_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init(owner_);
        _mint(owner_, TokenConstants.MAX_SUPPLY);

        metaURI = metaURI_;
        minDispatch = TokenConstants.MAX_SUPPLY / 25000;
    }

    function setLaunched(bool value) external onlyOwner {
        launched = value;
    }

    function configureTaxAndDistribution(
        uint16 taxRateBps_,
        address recipient,
        uint16 recipientBps_,
        uint16 dividendBps_,
        uint16 burnBps_,
        uint16 lpBps_,
        uint256 minimumShareBalance_,
        address dexFactory_,
        address dexRouter_,
        address quoteToken_,
        address liquidityHelper_
    ) external onlyOwner {
        if (taxRateBps_ > 10000) revert InvalidTaxRate();
        if (
            uint256(recipientBps_) +
                uint256(dividendBps_) +
                uint256(burnBps_) +
                uint256(lpBps_) !=
            100
        ) {
            revert InvalidTaxDistribution();
        }
        // when recipientBps > 0, recipient must be non-zero
        if (recipientBps_ > 0 && recipient == address(0))
            revert InvalidTaxDistribution();
        // when dividendBps > 0, minimumShareBalance must be non-zero
        if (dividendBps_ > 0 && minimumShareBalance_ == 0)
            revert InvalidTaxDistribution();
        // anyway dexFactory, dexRouter, quoteToken, liquidityHelper must be non-zero
        if (
            dexFactory_ == address(0) ||
            dexRouter_ == address(0) ||
            quoteToken_ == address(0) ||
            liquidityHelper_ == address(0)
        ) {
            revert InvalidTaxDistribution();
        }

        taxRateBps = taxRateBps_;
        taxRecipient = recipient;
        recipientBps = recipientBps_;
        dividendBps = dividendBps_;
        burnBps = burnBps_;
        lpBps = lpBps_;
        minimumShareBalance = minimumShareBalance_;
        dexFactory = dexFactory_;
        dexRouter = dexRouter_;
        quoteToken = quoteToken_;
        liquidityHelper = liquidityHelper_;
    }

    /**
     * @dev Claims the fee for the caller.
     */
    function claimFee() external {
        _claimFee(msg.sender);
    }

    /**
     * @dev Claims the fee for multiple accounts.
     * @param accounts The accounts to claim the fee for.
     */
    function claimFee(address[] memory accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            _claimFee(accounts[i]);
        }
    }

    /**
     * @dev Returns the withdrawable dividend of a user.
     * @param user The user to query.
     * @return The withdrawable dividend of the user.
     */
    function withdrawableDividendOf(
        address user
    ) external view returns (uint256) {
        return _withdrawableDividendOf(user);
    }

    /**
     * @dev Returns the accrued tax.
     * @return The accrued tax.
     */
    function accruedTax() external view returns (uint256) {
        return _accruedTax;
    }

    /**
     * @dev Returns the number of users.
     * @return The number of users.
     */
    function userCount() external view returns (uint256) {
        return _users.length();
    }

    /**
     * @dev Returns the users.
     * @param index The index to start from.
     * @param count The number of users to return.
     * @param minClaimable The minimum claimable amount.
     * @return accounts The accounts.
     */
    function users(
        uint256 index,
        uint256 count,
        uint256 minClaimable
    ) external view returns (address[] memory accounts) {
        accounts = new address[](count);
        uint256 length = _users.length();
        for (uint256 i = 0; i < count; i++) {
            if (index >= length) {
                break;
            }

            address account = _users.at(index);
            uint256 claimable = _withdrawableDividendOf(account);
            if (minClaimable == 0 || claimable >= minClaimable) {
                accounts[i] = account;
            }
            index++;
        }
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (!launched && from != address(0) && to != address(0)) {
            address owner_ = owner();
            bool allowed = (from == owner_ || to == owner_);
            if (!allowed) revert TransferDisabled();
        }

        address pair = _pair();
        bool launchedTransfer = launched &&
            !_dispatching &&
            from != address(0) &&
            to != address(0);
        bool taxable = launchedTransfer &&
            taxRateBps > 0 &&
            pair != address(0) &&
            (from == pair || to == pair) &&
            from != owner() &&
            to != owner();
        bool shouldDispatch = launchedTransfer && from != pair;

        if (taxable) {
            uint256 taxAmount = (value * uint256(taxRateBps)) / 10000;
            if (taxAmount > 0) {
                _accruedTax += taxAmount;
                super._update(from, address(this), taxAmount);
                value -= taxAmount;
            }
        }

        if (shouldDispatch) {
            _dispatchTax();
        }

        super._update(from, to, value);

        if (_shouldTrack(from)) {
            _setShare(from, balanceOf(from));
        }
        if (_shouldTrack(to) && to != from) {
            _setShare(to, balanceOf(to));
        }

        if (
            launchedTransfer && from != pair && to != pair && msg.sender != pair
        ) {
            _claimFee(from);
        }
    }

    function _dispatchTax() internal {
        uint256 total = _accruedTax;
        if (total < minDispatch) {
            return;
        }

        uint256 toRecipient = (total * recipientBps) / 100;
        uint256 toDividend = (total * dividendBps) / 100;
        uint256 toBurn = (total * burnBps) / 100;
        uint256 toLP = (total * lpBps) / 100;

        uint256 consumed = toRecipient + toDividend + toBurn + toLP;
        if (consumed < total) {
            toRecipient += (total - consumed);
        }

        _dispatching = true;
        _accruedTax = 0;

        if (toRecipient > 0) {
            if (taxRecipient == address(0)) revert InvalidTaxDistribution();
            _approve(address(this), liquidityHelper, toRecipient);
            ILiquidityHelper(liquidityHelper).swapForQuote(
                address(this),
                dexRouter,
                quoteToken,
                taxRecipient,
                toRecipient
            );
        }

        if (toDividend > 0) {
            if (totalShares > 0) {
                _approve(address(this), liquidityHelper, toDividend);
                uint256 quoteForHolders = ILiquidityHelper(liquidityHelper)
                    .swapForQuote(
                        address(this),
                        dexRouter,
                        quoteToken,
                        address(this),
                        toDividend
                    );
                feePerShare += (quoteForHolders * MAGNITUDE) / totalShares;
            } else {
                _accruedTax += toDividend;
                toDividend = 0;
            }
        }

        if (toBurn > 0) {
            super._update(address(this), DEAD, toBurn);
        }
        if (toLP > 0) {
            _approve(address(this), liquidityHelper, toLP);
            ILiquidityHelper(liquidityHelper).addLiquidity(
                address(this),
                dexFactory,
                dexRouter,
                quoteToken,
                toLP,
                DEAD
            );
        }

        _dispatching = false;
    }

    function _claimFee(address user) internal {
        _accrue(user);
        uint256 amount = pendingBalance[user];
        if (amount == 0) {
            return;
        }

        uint256 quoteBalance = IERC20(quoteToken).balanceOf(address(this));
        if (amount > quoteBalance) revert InsufficientQuoteBalance();

        pendingBalance[user] = 0;
        if (shareOf[user] == 0) {
            _users.remove(user);
        }
        IERC20(quoteToken).safeTransfer(user, amount);
        quoteClaimed += amount;
        emit FeeClaimed(user, amount);
    }

    function _setShare(address user, uint256 balance) internal {
        _accrue(user);

        uint256 prev = shareOf[user];
        uint256 next = balance >= minimumShareBalance ? balance : 0;
        shareOf[user] = next;

        if (next > 0 || pendingBalance[user] > 0) {
            _users.add(user);
        } else {
            _users.remove(user);
        }

        if (next >= prev) {
            totalShares += (next - prev);
        } else {
            totalShares -= (prev - next);
        }

        rewardDebt[user] = (next * feePerShare) / MAGNITUDE;
    }

    function _accrue(address user) internal {
        uint256 share = shareOf[user];
        uint256 accrued = (share * feePerShare) / MAGNITUDE;
        uint256 debt = rewardDebt[user];
        if (accrued > debt) {
            pendingBalance[user] += (accrued - debt);
        }
        rewardDebt[user] = accrued;
    }

    function _withdrawableDividendOf(
        address user
    ) internal view returns (uint256) {
        uint256 share = shareOf[user];
        uint256 accrued = (share * feePerShare) / MAGNITUDE;
        uint256 debt = rewardDebt[user];
        uint256 pending = pendingBalance[user];
        if (accrued <= debt) {
            return pending;
        }
        return pending + (accrued - debt);
    }

    function _shouldTrack(address account) internal view returns (bool) {
        return
            dividendBps > 0 &&
            account != address(0) &&
            account.code.length == 0 &&
            account != address(this) &&
            account != owner() &&
            account != DEAD &&
            account != liquidityHelper &&
            account != _pair();
    }

    function _pair() internal view returns (address) {
        if (dexFactory == address(0) || quoteToken == address(0)) {
            return address(0);
        }
        return IUniswapV2Factory(dexFactory).getPair(address(this), quoteToken);
    }
}
