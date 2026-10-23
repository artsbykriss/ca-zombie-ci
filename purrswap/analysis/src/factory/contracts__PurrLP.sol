// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 DODO ZOO.
pragma solidity >=0.8.0;

import {Ownable} from "@solady/auth/Ownable.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {SafeCastLib} from "@solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solady/utils/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {PurrLPFees} from "./PurrLPFees.sol";
import {DecimalMath} from "./libraries/DecimalMath.sol";
import {Math} from "./libraries/Math.sol";
import {PMMPricing} from "./libraries/PMMPricing.sol";
import {IPurrLPOracle} from "./interfaces/IPurrLPOracle.sol";

/// @title Purrswap PurrLp
/// @author Adapted from Abracadabra.money MagicLP https://github.com/Abracadabra-money/abracadabra-money-contracts/tree/main/src/mimswap/MagicLP.sol
/// @author External Fee claiming support adapted from Solidly codebase
/// @author Adapted from DODOEX DSP https://github.com/DODOEX/contractV2/tree/main/contracts/DODOStablePool
contract PurrLP is ERC20, ReentrancyGuard, Ownable {
    using Math for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for address;

    event BuyShares(address to, uint256 increaseShares, uint256 totalShares);
    event SellShares(address payer, address to, uint256 decreaseShares, uint256 totalShares);
    event Swap(address fromToken, address toToken, uint256 fromAmount, uint256 toAmount, address trader, address receiver);
    event RChange(PMMPricing.RState newRState);
    event Claim(address indexed sender, address indexed receiver, uint256 claimed0, uint256 claimed1);
    event FeesCollected(address indexed to, uint256 baseAmount, uint256 quoteAmount);
    event AutoCompoundFeesChanged(bool autoCompoundFees);
    event TreasuryChanged(address treasury);
    event TreasuryFeeChanged(uint256 treasuryFee);

    error ErrInitialized();
    error ErrBaseQuoteSame();
    error ErrInvalidI();
    error ErrInvalidK();
    error ErrExpired();
    error ErrNoBaseInput();
    error ErrZeroAddress();
    error ErrZeroQuoteAmount();
    error ErrZeroQuoteTarget();
    error ErrMintAmountNotEnough();
    error ErrNotEnough();
    error ErrWithdrawNotEnough();
    error ErrSellBackNotAllowed();
    error ErrInvalidLPFeeRate();
    error ErrNotImplementation();
    error ErrNotClone();
    error ErrOverflow();
    error ErrNotImplementationOwner();
    error ErrInvalidTreasuryFee();

    PurrLP public immutable implementation;

    uint256 public constant MAX_I = 10 ** 36;
    uint256 public constant MAX_K = 10 ** 18;
    uint256 public constant MIN_LP_FEE_RATE = 1e14; // 0.01%
    uint256 public constant MAX_LP_FEE_RATE = 1e16; // 1%
    uint256 public constant BIPS = 10_000;

    bool internal _INITIALIZED_;
    address public _BASE_TOKEN_;
    address public _QUOTE_TOKEN_;
    uint112 public _BASE_RESERVE_;
    uint112 public _QUOTE_RESERVE_;
    uint112 public _BASE_TARGET_;
    uint112 public _QUOTE_TARGET_;
    uint32 public _RState_;
    uint256 public _LP_FEE_RATE_;
    uint256 public _K_;
    uint256 public _I_;
    address public _ORACLE_;
    bool public _AUTO_COMPOUND_FEES_;

    // Fee Tracking
    address public treasury;
    uint256 public treasuryFeeBips;
    address public fees;
    uint256 public index0 = 0;
    uint256 public index1 = 0;
    mapping(address => uint256) public supplyIndex0;
    mapping(address => uint256) public supplyIndex1;
    mapping(address => uint256) public claimable0;
    mapping(address => uint256) public claimable1;

    constructor(address owner_) {
        _initializeOwner(owner_);
        implementation = this;

        _AUTO_COMPOUND_FEES_ = true;

        // prevents the implementation contract initialization
        _INITIALIZED_ = true;
    }

    function init(address baseTokenAddress, address quoteTokenAddress, uint256 lpFeeRate, uint256 i, uint256 k, address oracle) external {
        if (_INITIALIZED_) {
            revert ErrInitialized();
        }
        if (baseTokenAddress == address(0) || quoteTokenAddress == address(0)) {
            revert ErrZeroAddress();
        }
        if (baseTokenAddress == quoteTokenAddress) {
            revert ErrBaseQuoteSame();
        }
        if (i == 0 || i > MAX_I) {
            revert ErrInvalidI();
        }
        if (k > MAX_K) {
            revert ErrInvalidK();
        }
        if (lpFeeRate < MIN_LP_FEE_RATE || lpFeeRate > MAX_LP_FEE_RATE) {
            revert ErrInvalidLPFeeRate();
        }

        _INITIALIZED_ = true;
        _BASE_TOKEN_ = baseTokenAddress;
        _QUOTE_TOKEN_ = quoteTokenAddress;
        _I_ = i;
        _K_ = k;
        _ORACLE_ = oracle;
        _LP_FEE_RATE_ = lpFeeRate;

        fees = address(new PurrLPFees(_BASE_TOKEN_, _QUOTE_TOKEN_));

        /// @notice Treat any pre-deployed tokens as malicious and transfer them to the treasury as fees
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));
        if (baseBalance > 0) {
            _BASE_TOKEN_.safeTransfer(treasury, baseBalance);
        }
        if (quoteBalance > 0) {
            _QUOTE_TOKEN_.safeTransfer(treasury, quoteBalance);
        }

        _afterInitialized();
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// PUBLIC - CLONES ONLY
    //////////////////////////////////////////////////////////////////////////////////////

    function correctRState() external onlyClones nonReentrant {
        if (_RState_ == uint32(PMMPricing.RState.BELOW_ONE) && _BASE_RESERVE_ < _BASE_TARGET_) {
            _RState_ = uint32(PMMPricing.RState.ONE);
            _BASE_TARGET_ = _BASE_RESERVE_;
            _QUOTE_TARGET_ = _QUOTE_RESERVE_;
        }
        if (_RState_ == uint32(PMMPricing.RState.ABOVE_ONE) && _QUOTE_RESERVE_ < _QUOTE_TARGET_) {
            _RState_ = uint32(PMMPricing.RState.ONE);
            _BASE_TARGET_ = _BASE_RESERVE_;
            _QUOTE_TARGET_ = _QUOTE_RESERVE_;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// IMPLEMENTATION ADMIN ONLY
    //////////////////////////////////////////////////////////////////////////////////////

    function setAutoCompoundFees(bool autoCompoundFees) external onlyImplementation onlyImplementationOwner {
        _AUTO_COMPOUND_FEES_ = autoCompoundFees;
        emit AutoCompoundFeesChanged(_AUTO_COMPOUND_FEES_);
    }

    function setTreasury(address treasury_) external onlyImplementation onlyImplementationOwner {
        require(treasury_ != address(0), ErrZeroAddress());
        treasury = treasury_;
        emit TreasuryChanged(treasury);
    }

    function setTreasuryFeeBips(uint256 _treasuryFeeBips) external onlyImplementation onlyImplementationOwner {
        require(_treasuryFeeBips <= BIPS, ErrInvalidTreasuryFee());
        treasuryFeeBips = _treasuryFeeBips;
        emit TreasuryFeeChanged(treasuryFeeBips);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// IMPLEMENTATION ADMIN ONLY / CLONES ONLY
    //////////////////////////////////////////////////////////////////////////////////////

    function sync() external nonReentrant onlyClones onlyImplementationOwner {
        _sync(getEffectiveI());
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// VIEWS
    //////////////////////////////////////////////////////////////////////////////////////

    function name() public view override returns (string memory) {
        return string(abi.encodePacked("PurrLP ", IERC20Metadata(_BASE_TOKEN_).symbol(), "/", IERC20Metadata(_QUOTE_TOKEN_).symbol()));
    }

    function symbol() public pure override returns (string memory) {
        return "PurrLp";
    }

    function decimals() public view override returns (uint8) {
        return IERC20Metadata(_BASE_TOKEN_).decimals();
    }

    function querySellBase(
        PMMPricing.PMMState memory state,
        address /*trader*/,
        uint256 payBaseAmount
    ) public view returns (uint256 receiveQuoteAmount, uint256 fee, PMMPricing.RState newRState, uint256 newBaseTarget) {
        (receiveQuoteAmount, newRState) = PMMPricing.sellBaseToken(state, payBaseAmount);
        fee = DecimalMath.mulFloor(receiveQuoteAmount, _LP_FEE_RATE_);
        receiveQuoteAmount = receiveQuoteAmount - fee;
        newBaseTarget = state.B0;
    }

    function querySellQuote(
        PMMPricing.PMMState memory state,
        address /*trader*/,
        uint256 payQuoteAmount
    ) public view returns (uint256 receiveBaseAmount, uint256 fee, PMMPricing.RState newRState, uint256 newQuoteTarget) {
        (receiveBaseAmount, newRState) = PMMPricing.sellQuoteToken(state, payQuoteAmount);
        fee = DecimalMath.mulFloor(receiveBaseAmount, _LP_FEE_RATE_);
        receiveBaseAmount = receiveBaseAmount - fee;
        newQuoteTarget = state.Q0;
    }

    function getEffectiveI() public view returns (uint256) {
        if (_ORACLE_ != address(0)) {
            uint256 i = IPurrLPOracle(_ORACLE_).price(address(_BASE_TOKEN_));
            if (i == 0 || i > MAX_I) {
                revert ErrInvalidI();
            }
            return i;
        } else {
            return _I_;
        }
    }

    function getPMMState() public view returns (PMMPricing.PMMState memory state) {
        state.i = getEffectiveI();
        state.K = _K_;
        state.B = _BASE_RESERVE_;
        state.Q = _QUOTE_RESERVE_;
        state.B0 = _BASE_TARGET_; // will be calculated in adjustedTarget
        state.Q0 = _QUOTE_TARGET_;
        state.R = PMMPricing.RState(_RState_);
        PMMPricing.adjustedTarget(state);
    }

    function getPMMStateForCall() external view returns (uint256 i, uint256 K, uint256 B, uint256 Q, uint256 B0, uint256 Q0, uint256 R) {
        PMMPricing.PMMState memory state = getPMMState();
        i = state.i;
        K = state.K;
        B = state.B;
        Q = state.Q;
        B0 = state.B0;
        Q0 = state.Q0;
        R = uint256(state.R);
    }

    function getReserves() external view returns (uint256 baseReserve, uint256 quoteReserve) {
        baseReserve = _BASE_RESERVE_;
        quoteReserve = _QUOTE_RESERVE_;
    }

    function getBaseInput() public view nonReadReentrant returns (uint256 input) {
        return _BASE_TOKEN_.balanceOf(address(this)) - uint256(_BASE_RESERVE_);
    }

    function getQuoteInput() public view nonReadReentrant returns (uint256 input) {
        return _QUOTE_TOKEN_.balanceOf(address(this)) - uint256(_QUOTE_RESERVE_);
    }

    function version() external pure virtual returns (string memory) {
        return "PurrLp 1.0.0";
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// TRADE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////////////

    function sellBase(address to) external nonReentrant onlyClones returns (uint256 receiveQuoteAmount) {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));
        uint256 baseInput = baseBalance - uint256(_BASE_RESERVE_);
        uint256 quoteFee;
        uint256 newBaseTarget;
        PMMPricing.RState newRState;
        PMMPricing.PMMState memory state = getPMMState();

        (receiveQuoteAmount, quoteFee, newRState, newBaseTarget) = querySellBase(state, tx.origin, baseInput);
        _transferQuoteOut(to, receiveQuoteAmount);

        if (quoteFee > 0) {
            _updateQuoteFees(quoteFee);
        }

        // update TARGET
        if (_RState_ != uint32(newRState)) {
            _BASE_TARGET_ = newBaseTarget.toUint112();
            _RState_ = uint32(newRState);
            emit RChange(newRState);
        }

        _setReserve(baseBalance, _QUOTE_TOKEN_.balanceOf(address(this)));
        _adjustTarget(state.i);

        emit Swap(address(_BASE_TOKEN_), address(_QUOTE_TOKEN_), baseInput, receiveQuoteAmount, msg.sender, to);
    }

    function sellQuote(address to) external nonReentrant onlyClones returns (uint256 receiveBaseAmount) {
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));
        uint256 quoteInput = quoteBalance - uint256(_QUOTE_RESERVE_);
        uint256 baseFee;
        uint256 newQuoteTarget;
        PMMPricing.RState newRState;
        PMMPricing.PMMState memory state = getPMMState();

        (receiveBaseAmount, baseFee, newRState, newQuoteTarget) = querySellQuote(state, tx.origin, quoteInput);

        _transferBaseOut(to, receiveBaseAmount);

        if (baseFee > 0) {
            _updateBaseFees(baseFee);
        }

        // update TARGET
        if (_RState_ != uint32(newRState)) {
            _QUOTE_TARGET_ = newQuoteTarget.toUint112();
            _RState_ = uint32(newRState);
            emit RChange(newRState);
        }

        _setReserve(_BASE_TOKEN_.balanceOf(address(this)), quoteBalance);
        _adjustTarget(state.i);

        emit Swap(address(_QUOTE_TOKEN_), address(_BASE_TOKEN_), quoteInput, receiveBaseAmount, msg.sender, to);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// BUY & SELL SHARES
    //////////////////////////////////////////////////////////////////////////////////////

    // buy shares [round down]
    function buyShares(address to) external nonReentrant onlyClones returns (uint256 shares, uint256 baseInput, uint256 quoteInput) {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));
        uint256 baseReserve = _BASE_RESERVE_;
        uint256 quoteReserve = _QUOTE_RESERVE_;

        baseInput = baseBalance - baseReserve;
        quoteInput = quoteBalance - quoteReserve;

        if (baseInput == 0) {
            revert ErrNoBaseInput();
        }

        uint256 _i = getEffectiveI();

        // Round down when withdrawing. Therefore, never be a situation occurring balance is 0 but totalsupply is not 0
        // But May Happen，reserve >0 But totalSupply = 0
        if (totalSupply() == 0) {
            // case 1. initial supply
            if (quoteBalance == 0) {
                revert ErrZeroQuoteAmount();
            }

            shares = quoteBalance < DecimalMath.mulFloor(baseBalance, _i) ? DecimalMath.divFloor(quoteBalance, _i) : baseBalance;
            _BASE_TARGET_ = shares.toUint112();
            _QUOTE_TARGET_ = DecimalMath.mulFloor(shares, _i).toUint112();

            if (_QUOTE_TARGET_ == 0) {
                revert ErrZeroQuoteTarget();
            }

            if (shares <= 2001) {
                revert ErrMintAmountNotEnough();
            }

            _mint(address(0), 1001);
            shares -= 1001;
        } else if (baseReserve > 0 && quoteReserve > 0) {
            // case 2. normal case
            uint256 baseInputRatio = DecimalMath.divFloor(baseInput, baseReserve);
            uint256 quoteInputRatio = DecimalMath.divFloor(quoteInput, quoteReserve);
            uint256 mintRatio = quoteInputRatio < baseInputRatio ? quoteInputRatio : baseInputRatio;
            shares = DecimalMath.mulFloor(totalSupply(), mintRatio);

            _BASE_TARGET_ = (uint256(_BASE_TARGET_) + DecimalMath.mulFloor(uint256(_BASE_TARGET_), mintRatio)).toUint112();
            _QUOTE_TARGET_ = (uint256(_QUOTE_TARGET_) + DecimalMath.mulFloor(uint256(_QUOTE_TARGET_), mintRatio)).toUint112();
        }

        _mint(to, shares);
        _setReserve(baseBalance, quoteBalance);
        _adjustTarget(_i);

        emit BuyShares(to, shares, balanceOf(to));
    }

    // sell shares [round down]
    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint256 deadline
    ) external nonReentrant onlyClones returns (uint256 baseAmount, uint256 quoteAmount) {
        if (deadline < block.timestamp) {
            revert ErrExpired();
        }
        if (shareAmount > balanceOf(msg.sender)) {
            revert ErrNotEnough();
        }
        if (to == address(this)) {
            revert ErrSellBackNotAllowed();
        }

        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));
        uint256 totalShares = totalSupply();

        baseAmount = (baseBalance * shareAmount) / totalShares;
        quoteAmount = (quoteBalance * shareAmount) / totalShares;

        _BASE_TARGET_ = uint112(uint256(_BASE_TARGET_) - (uint256(_BASE_TARGET_) * shareAmount).divCeil(totalShares));
        _QUOTE_TARGET_ = uint112(uint256(_QUOTE_TARGET_) - (uint256(_QUOTE_TARGET_) * shareAmount).divCeil(totalShares));

        if (baseAmount < baseMinAmount || quoteAmount < quoteMinAmount) {
            revert ErrWithdrawNotEnough();
        }

        // this will call _beforeTokenTransfer(from: msg.sender, to: address(0), amount: shareAmount)
        _burn(msg.sender, shareAmount);

        _transferBaseOut(to, baseAmount);
        _transferQuoteOut(to, quoteAmount);

        _sync(getEffectiveI());

        emit SellShares(msg.sender, to, shareAmount, balanceOf(msg.sender));
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// FEE HANDLING
    //////////////////////////////////////////////////////////////////////////////////////

    function _updateBaseFees(uint256 amount) internal {
        address _treasury = implementation.treasury();
        uint256 _treasuryFeeBips = implementation.treasuryFeeBips();

        if (!implementation._AUTO_COMPOUND_FEES_()) {
            _BASE_TOKEN_.safeTransfer(fees, amount);
            uint256 _ratio = (amount * 1e18) / totalSupply();
            if (_ratio > 0) {
                index0 += _ratio;
            }
            emit FeesCollected(fees, amount, 0);
        } else if (_treasuryFeeBips > 0) {
            uint256 treasuryAmount = (amount * _treasuryFeeBips) / BIPS;
            _BASE_TOKEN_.safeTransfer(_treasury, treasuryAmount);
            emit FeesCollected(_treasury, treasuryAmount, 0);
        }
    }

    function _updateQuoteFees(uint256 amount) internal {
        address _treasury = implementation.treasury();
        uint256 _treasuryFeeBips = implementation.treasuryFeeBips();

        if (!implementation._AUTO_COMPOUND_FEES_()) {
            _QUOTE_TOKEN_.safeTransfer(fees, amount);
            uint256 _ratio = (amount * 1e18) / totalSupply();
            if (_ratio > 0) {
                index1 += _ratio;
            }
            emit FeesCollected(fees, 0, amount);
        } else if (_treasuryFeeBips > 0) {
            uint256 treasuryAmount = (amount * _treasuryFeeBips) / BIPS;
            _QUOTE_TOKEN_.safeTransfer(_treasury, treasuryAmount);
            emit FeesCollected(_treasury, 0, treasuryAmount);
        }
    }

    function claimFees() external onlyClones returns (uint256 claimed0, uint256 claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            PurrLPFees(fees).claimFeesFor(msg.sender, claimed0, claimed1);
            emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    function _updateFor(address recipient) internal {
        uint256 _supplied = balanceOf(recipient);

        if (_supplied > 0) {
            uint256 _supplyIndex0 = supplyIndex0[recipient];
            uint256 _supplyIndex1 = supplyIndex1[recipient];
            uint256 _index0 = index0; // get global index0 for accumulated fees
            uint256 _index1 = index1;

            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;

            uint256 _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint256 _delta1 = _index1 - _supplyIndex1;

            if (_delta0 > 0) {
                uint256 _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }

            if (_delta1 > 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// INTERNALS
    //////////////////////////////////////////////////////////////////////////////////////

    function _setReserve(uint256 baseReserve, uint256 quoteReserve) internal {
        _BASE_RESERVE_ = baseReserve.toUint112();
        _QUOTE_RESERVE_ = quoteReserve.toUint112();
    }

    function _sync(uint256 _i) internal {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));

        if (baseBalance != _BASE_RESERVE_) {
            _BASE_RESERVE_ = baseBalance.toUint112();
        }
        if (quoteBalance != _QUOTE_RESERVE_) {
            _QUOTE_RESERVE_ = quoteBalance.toUint112();
        }
        _adjustTarget(_i);
    }

    function _transferBaseOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _BASE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function _transferQuoteOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _QUOTE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function _mint(address to, uint256 amount) internal override {
        if (amount <= 1000) {
            revert ErrMintAmountNotEnough();
        }

        // this will call _beforeTokenTransfer(from: address(0), to: to, amount: amount)
        super._mint(to, amount);
    }

    function _adjustTarget(uint256 _i) internal {
        if (PMMPricing.RState(_RState_) == PMMPricing.RState.BELOW_ONE) {
            _QUOTE_TARGET_ = Math._SolveQuadraticFunctionForTarget(_QUOTE_RESERVE_, _BASE_RESERVE_ - _BASE_TARGET_, _i, _K_).toUint112();
        } else if (PMMPricing.RState(_RState_) == PMMPricing.RState.ABOVE_ONE) {
            _BASE_TARGET_ = Math
                ._SolveQuadraticFunctionForTarget(_BASE_RESERVE_, _QUOTE_RESERVE_ - _QUOTE_TARGET_, DecimalMath.reciprocalFloor(_i), _K_)
                .toUint112();
        }
    }

    function _afterInitialized() internal virtual {}

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal override {
        if (from != address(0)) {
            _updateFor(from);
        }
        if (to != address(0)) {
            _updateFor(to);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// MODIFIERS
    //////////////////////////////////////////////////////////////////////////////////////

    /// @dev can only be called on the implementation contract
    modifier onlyImplementation() {
        if (address(this) != address(implementation)) {
            revert ErrNotImplementation();
        }
        _;
    }

    modifier onlyImplementationOwner() {
        if (msg.sender != implementation.owner()) {
            revert ErrNotImplementationOwner();
        }
        _;
    }

    /// @dev can only be called on a clone contract
    modifier onlyClones() {
        if (address(this) == address(implementation)) {
            revert ErrNotClone();
        }
        _;
    }
}
