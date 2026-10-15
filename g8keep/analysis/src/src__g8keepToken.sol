// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IG8keepDeployerVesting} from "./interfaces/IG8keepDeployerVesting.sol";
import {IG8keepFactory} from "./interfaces/IG8keepFactory.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/**
 * @title   g8keepToken
 * @notice  An ERC20 implementation for the g8keep platform.
 * @notice  Key features of g8keepToken include: 
 * @notice  - Fee collection for deployers and guardrails for traders.
 * @notice  - Fees may only be lowered by the deployer, never raised.
 * @notice  - Automated snipe protection with a linear release of tokens 
 * @notice    without snipe penalties and exponential increase of penalty
 * @notice    based on the purchase amount.
 */
contract g8keepToken is Ownable {
    /// @dev Name of the token.
    string public name;
    /// @dev Symbol of the token.
    string public symbol;
    /// @dev Token decimals.
    uint8 public constant decimals = 18;
    /// @dev Total supply of the token.
    uint256 public immutable totalSupply;

    /// @dev g8keep factory address to deposit g8keep fees.
    address private immutable G8KEEP;
    /// @dev Address that will receive penalty taxes.
    address private immutable PENALTY_TAX_RECEIVER;
    /// @dev Address of the Uniswap V2 pair.
    address public immutable UNISWAP_V2_PAIR;
    /// @dev Address of the paired token.
    address public immutable PAIRED_TOKEN;

    /// @dev Constant value for BPS.
    uint16 private constant BPS = 10_000;
    /// @dev Constant value for the maximum deployer reserve of total supply in BPS.
    uint16 private constant MAX_DEPLOYER_RESERVE = 300;
    /// @dev Timestamp of the token deployment - used for calculating snipe protection.
    uint40 private immutable GENESIS_TIME;
    /// @dev The base penalty exponent for snipe protection.
    uint8 private constant SNIPE_PENALTY_BASE_EXPONENT = 2;
    /// @dev Amount of time in seconds that snipe protection is enabled for.
    uint40 public immutable SNIPE_PROTECTION_SECONDS;
    /// @dev Timestamp of when snipe protection for the token ends.
    uint40 public immutable SNIPE_PROTECTION_END;
    /// @dev Starting exponent for heavy snipe penalties.
    uint8 public immutable SNIPE_PROTECTION_HEAVY_EXPONENT_START;
    /// @dev Amount of time in seconds that heavy snipe penalties are enabled for.
    uint40 public immutable SNIPE_PROTECTION_HEAVY_PENALTY_SECONDS;
    /// @dev Fee in BPS assessed by g8keep for trades.
    uint16 public immutable G8KEEP_FEE;

    /// @dev Fee in BPS assessed by the deployer for buys.
    uint16 public buyFee;
    /// @dev Fee in BPS assessed by the deployer for sells.
    uint16 public sellFee;
    /// @dev Address that will receive deployer trading fees.
    address public treasuryWallet;
    /// @dev Mapping of token balances for token owners.
    mapping(address => uint256) private _balances;
    /// @dev Mapping of spender approvals.
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev Baseline balance of the LP - used for calculating snipe protection.
    uint256 private lpBalanceBaseline;
    /// @dev Amount of LP token total supply last recorded - used for calculating `thirdPartyLPAmount`.
    uint256 private lastLPTotalSupply;
    /// @dev Amount of token added to the LP by third parties.
    uint112 private thirdPartyLPAmount;
    /// @dev Cached value of the LP token reserve - used for calculating `thirdPartyLPAmount`.
    uint112 private cachedLPReserve1;

    /// @dev Thrown when attempting to burn an LP position during snipe protection.
    error CannotBurnLiquidityDuringSnipeProtection();
    /// @dev Thrown when deployer attempts to set fees higher than the current settings.
    error CannotIncreaseFees();
    /// @dev Thrown when attempting to transfer tokens from and to the Uniswap V2 Pair.
    error CannotTransferFromAndToUniswapV2Pair();
    /// @dev Thrown when the transfer amount on a buy exceeds the value the Uniswap V2 Router calculates.
    error ExcessiveAmountOut();
    /// @dev Thrown when the spender does not have a sufficient allowance for the transfer being made.
    error InsufficientAllowance();
    /// @dev Thrown when a transfer amount exceeds the sender's balance.
    error InsufficientBalance();
    /// @dev Thrown during snipe protection when purchasing tokens and the paired token balance decreases.
    error InsufficientPoolInput();
    /// @dev Thrown during deployment if the heavy snipe exponent exceeds type(uint8).max or is less than the base snipe exponent.
    error InvalidHeavySnipeParameters();
    /// @dev Thrown when calculating maximum amount out and the reserve balances are zero.
    error InvalidReserves();
    /// @dev Thrown during deployment if the token address is not greater than the paired token address.
    error InvalidTokenAddress();
    /// @dev Thrown during deployment if the deployer requests a deployer reserve greater than the maximum setting.
    error ReserveExceedsMax();
    /// @dev Thrown during deployment if the snipe protection time will overflow a uint40 value.
    error SnipeProtectionTimeOverflow();
    /// @dev Thrown when attempting to set the treasury wallet address to the zero address or the Uniswap V2 pair.
    error InvalidTreasuryAddress();
    /// @dev Thrown during deployment if the supply exceeds the maximum allowed by Uniswap V2.
    error SupplyExceedsMax();
    /// @dev Thrown when setting an approval or attempting to transfer tokens to the zero address.
    error ZeroAddress();

    /// @dev Emitted when an approval is updated.
    event Approval(address indexed owner, address indexed spender, uint256 value);
    /// @dev Emitted when deployer fees are updated.
    event DeployerFeesUpdated(uint16 buyFee, uint16 sellFee);
    /// @dev Emitted when a token balance is transfered.
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @dev Emitted when the treasury wallet is updated.
    event TreasuryWalletUpdated(address treasuryWallet);

    /**
     * @notice Constructs the g8keep token.
     *
     * @param _deployer                Address of the deployer of the token.
     * @param _name                    Name of the token being deployed.
     * @param _symbol                  Symbol of the token being deployed.
     * @param _totalSupply             Total supply to be minted during deployment.
     * @param _treasuryWallet          Address that will receive deployer buy and sell fees.
     * @param _penaltyTaxReceiver      Address that will receive penalty taxes.
     * @param _buyFee                  Buy fee in BPS.
     * @param _sellFee                 Sell fee in BPS.
     * @param _g8keepFee               Fee assessed by g8keep for trades in BPS.
     * @param _uniswapV2Router         Address of the Uniswap V2 Router.
     * @param _pairedToken             Address of the token to pair with in the LP.
     * @param _deployReserve           Amount of total supply in BPS to allocate to deployer.
     * @param _deployVestTime          Time in seconds to vest the deployer's allocation.
     * @param _snipeProtectionSeconds  Amount of time in seconds that snipe protection will be enabled.
     * @param _heavySnipeSeconds       Amount of time in seconds that heavy snipe penalty is enabled.
     * @param _heavySnipeExponent      Starting exponent for heavy snipe penalty.
     */
    constructor(
        address _deployer,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _treasuryWallet,
        address _penaltyTaxReceiver,
        uint16 _buyFee,
        uint16 _sellFee,
        uint16 _g8keepFee,
        address _uniswapV2Router,
        address _pairedToken,
        uint256 _deployReserve,
        uint256 _deployVestTime,
        uint256 _snipeProtectionSeconds,
        uint256 _heavySnipeSeconds,
        uint256 _heavySnipeExponent
    ) {
        if (_deployReserve > MAX_DEPLOYER_RESERVE) revert ReserveExceedsMax();
        if (_snipeProtectionSeconds + block.timestamp > type(uint40).max || _heavySnipeSeconds > _snipeProtectionSeconds) revert SnipeProtectionTimeOverflow();
        if (_totalSupply > type(uint112).max) revert SupplyExceedsMax();
        if (_heavySnipeExponent > type(uint8).max || _heavySnipeExponent < SNIPE_PENALTY_BASE_EXPONENT) revert InvalidHeavySnipeParameters();

        _initializeOwner(_deployer);

        G8KEEP = msg.sender;
        PENALTY_TAX_RECEIVER = _penaltyTaxReceiver;
        GENESIS_TIME = uint40(block.timestamp);
        SNIPE_PROTECTION_SECONDS = uint40(_snipeProtectionSeconds);
        SNIPE_PROTECTION_END = uint40(_snipeProtectionSeconds + block.timestamp);
        G8KEEP_FEE = _g8keepFee;
        PAIRED_TOKEN = _pairedToken;
        SNIPE_PROTECTION_HEAVY_PENALTY_SECONDS = uint40(_heavySnipeSeconds);
        SNIPE_PROTECTION_HEAVY_EXPONENT_START = uint8(_heavySnipeExponent - SNIPE_PENALTY_BASE_EXPONENT);
        buyFee = _buyFee;
        sellFee = _sellFee;

        //Revert if deployment address is less than the paired token address
        //Token must be "token1" in the v2 pool so that snipe protection can
        //evaluate the paired token balance of the pool while transferring
        //this token to the buyer.
        if (uint160(address(this)) < uint160(_pairedToken)) {
            revert InvalidTokenAddress();
        }

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        treasuryWallet = _treasuryWallet;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        address uniswapV2Pair;
        try 
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(_pairedToken, address(this))
            returns (address _uniswapV2Pair) {
            uniswapV2Pair = _uniswapV2Pair;
        } catch {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(_pairedToken, address(this));
        }
        UNISWAP_V2_PAIR = uniswapV2Pair;

        if (_treasuryWallet == uniswapV2Pair) {
            revert InvalidTreasuryAddress();
        }

        uint256 tokensToDeployer = _totalSupply * _deployReserve / BPS;
        uint256 tokensToLP = _totalSupply - tokensToDeployer;
        lpBalanceBaseline = tokensToLP;

        // Transfer tokens for LP to factory, set allowance to router
        _balances[msg.sender] = tokensToLP;
        emit Transfer(address(0), msg.sender, tokensToLP);
        _allowances[msg.sender][_uniswapV2Router] = type(uint256).max;
        emit Approval(msg.sender, _uniswapV2Router, type(uint256).max);

        if (tokensToDeployer > 0) {
            if (_deployVestTime == 0) {
                // Transfer deployer tokens to deployer
                _balances[_deployer] = tokensToDeployer;
                emit Transfer(address(0), _deployer, tokensToDeployer);
            } else {
                address g8keepVester = IG8keepFactory(msg.sender).g8keepTokenVesting();
                _balances[g8keepVester] = tokensToDeployer;
                emit Transfer(address(0), g8keepVester, tokensToDeployer);

                IG8keepDeployerVesting(g8keepVester).deploymentVest(_deployer, tokensToDeployer, _deployVestTime);
            }
        }
    }

    /////////// EXTERNAL FUNCTIONS ///////////

    /**
     * @notice  Calculates the amount of tokens that may be purchased without a snipe
     * @notice  protection penalty.
     *
     * @return _amount  The amount of tokens that may be purchased without a snipe penalty.
     */
    function maxSnipeProtectionBuyWithoutPenalty() external view returns (uint256 _amount) {
        _amount = _balances[UNISWAP_V2_PAIR];
        if (block.timestamp < SNIPE_PROTECTION_END) {
            // Adjust balance for amounts added to the LP by third parties
            (,,uint256 cachedThirdPartyLPAmount) = _checkLPForIncreaseView();

            if (cachedThirdPartyLPAmount > 0) {
                if (cachedThirdPartyLPAmount > _amount) {
                    _amount = 0;
                } else {
                    unchecked {
                        _amount = _amount - cachedThirdPartyLPAmount;
                    }
                }
            }

            uint256 elapsedSeconds = block.timestamp - GENESIS_TIME;
            uint256 cachedLPBalanceBaseline = lpBalanceBaseline;
            uint256 expectedBalance1 =
                cachedLPBalanceBaseline - cachedLPBalanceBaseline * elapsedSeconds / SNIPE_PROTECTION_SECONDS;

            if (_amount < expectedBalance1) {
                _amount = 0;
            } else {
                _amount = _amount - expectedBalance1;
            }
        }
    }

    /**
     * @notice  Calculates the expected output amounts to buyer, penalty and fees for 
     * @notice  the `amount0In`, accounts for snipe protection penalties and current fee settings.
     *
     * @param amount0In  The amount of paired token that will be input to the pool.
     *
     * @return amount1Out         The amount the buyer will receive.
     * @return penaltyAmount1Out  The amount that will be sent to the penalty receiver.
     * @return feesAmount1Out     The total fees to g8keep and deployer treasury.
     */
    function expectedAmount1Out(uint256 amount0In) external view returns (uint256 amount1Out, uint256 penaltyAmount1Out, uint256 feesAmount1Out) {
        (uint256 reserve0, uint256 reserve1, uint256 cachedThirdPartyLPAmount) = _checkLPForIncreaseView();
        amount1Out = _getAmountOut(amount0In, reserve0, reserve1);

        if (block.timestamp < SNIPE_PROTECTION_END) {
            (amount1Out, penaltyAmount1Out) = _adjustAmountOut(amount1Out, cachedThirdPartyLPAmount, lpBalanceBaseline);
        }
        
        unchecked {
            uint256 deployerFee = buyFee;
            if (deployerFee > 0) {
                feesAmount1Out += (amount1Out * deployerFee) / BPS;
            }

            if (G8KEEP_FEE > 0) {
                feesAmount1Out += (amount1Out * G8KEEP_FEE) / BPS;
            }

            amount1Out = amount1Out - feesAmount1Out;
        }
    }

    /**
     * @notice  Returns the token balance of `account`.
     *
     * @param account  Address to retrieve the balance of.
     * 
     * @return _balance  The token balance of `account`.
     */
    function balanceOf(address account) public view returns (uint256 _balance) {
        _balance = _balances[account];
    }

    /**
     * @notice  Returns the amount `owner` has authorized `spender` to transfer.
     * 
     * @dev     An allowance of `type(uint256).max` is considered an unlimited allowance.
     * 
     * @param owner    The owner of the tokens `spender` is allowed to transfer.
     * @param spender  The account authorized by `owner` to spend tokens on behalf of.
     *
     * @return _allowance  The amount of tokens of `owner` that `spender` is allowed to transfer.
     */
    function allowance(address owner, address spender) public view returns (uint256 _allowance) {
        _allowance = _allowances[owner][spender];
    }

    /**
     * @notice  Sets the allowed amount that `spender` may transfer on behalf of the caller.
     *
     * @dev     An `amount` of `type(uint256).max` is considered an unlimited allowance.
     * 
     * @param spender  Address of the account that the caller is authorizing.
     * @param amount   Amount of tokens the caller is authorizing `spender` to transfer.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice  Transfers `amount` of tokens from the caller to `recipient`.
     *
     * @param recipient  Address that will receive the tokens from the caller.
     * @param amount     Amount of tokens to transfer to `recipient`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice  Transfers `amount` of tokens from `sender` to `recipient` if the
     * @notice  caller has a sufficient allowance set by `sender`.
     *
     * @param sender     Account to send the tokens from.
     * @param recipient  Address that will receive the tokens from `sender`.
     * @param amount     Amount of tokens to transfer to `recipient` from `sender`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /////////// OWNER FUNCTIONS ///////////

    /**
     * @notice  Admin function for the token owner to set a new treasury wallet to receive fees.
     *
     * @dev     The address may not be set to the zero address or the Uniswap V2 Pair.
     *
     * @param newAddress  Address to set as the treasury wallet.
     */
    function updateTreasuryWallet(address newAddress) external onlyOwner {
        if (newAddress == address(0) || newAddress == UNISWAP_V2_PAIR) {
            revert InvalidTreasuryAddress();
        }
        treasuryWallet = newAddress;

        emit TreasuryWalletUpdated(newAddress);
    }

    /**
     * @notice  Admin function for the token owner to set new buy and sell fees.
     *
     * @dev     The buy and sell fees may not be set higher than the current fees.
     *
     * @param _buyFee   Fee in BPS to assess on token buys.
     * @param _sellFee  Fee in BPS to assess on token sells.
     */
    function updateFees(uint16 _buyFee, uint16 _sellFee) external onlyOwner {
        uint16 _oldBuyFee = buyFee;
        uint16 _oldSellfee = sellFee;
        if (_oldBuyFee < _buyFee || _oldSellfee < _sellFee) {
            revert CannotIncreaseFees();
        }
        
        buyFee = _buyFee;
        sellFee = _sellFee;

        emit DeployerFeesUpdated(_buyFee, _sellFee);
    }

    /**
     * @notice  Admin function for the token owner to recover tokens mistakenly sent 
     * @notice  to the token contract.
     * 
     * @dev     Will withdraw the entire balance of the token.
     * 
     * @param tokenAddress  Address of the token to withdraw.
     * @param to            Address to withdraw the token to.
     */
    function withdrawToken(address tokenAddress, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(tokenAddress).balanceOf(address(this));
        SafeTransferLib.safeTransfer(tokenAddress, to, _contractBalance);
    }

    /**
     * @notice  Admin function for the token owner to recover tokens mistakenly sent 
     * @notice  to the token contract.
     * 
     * @dev     Will withdraw the specified `amount` of token.
     * 
     * @param tokenAddress  Address of the token to withdraw.
     * @param to            Address to withdraw the token to.
     * @param amount        Amount of the token to withdraw.
     */
    function withdrawToken(address tokenAddress, address to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransfer(tokenAddress, to, amount);
    }

    /////////// INTERNAL FUNCTIONS ///////////

    /**
     * @dev  Internal function to handle approvals. 
     * @dev  Updates the `_allowances` mapping and emits an `Approval` event.
     * 
     * @param owner    Account that owns the tokens being authorized. This will always be the caller.
     * @param spender  Address of the account that the caller is authorizing.
     * @param amount   Amount of tokens the caller is authorizing `spender` to transfer.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev  Internal function to handle transfers. 
     * @dev  Adjusts `amount` based on snipe protection calculations while enabled.
     * @dev  Applies fees when the transfer is going to or coming from the Uniswap V2 Pair.
     * @dev  Updates the `_balances` mapping for `from` and `to` and emits a `Transfer` event.
     * 
     * @param from    Address of the account to transfer tokens from.
     * @param to      Address of the account to transfer tokens to.
     * @param amount  Amount of tokens to transfer from `from` to `to`.
     */
    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        amount = _applySnipeProtection(from, to, amount);

        uint256 senderBalance = _balances[from];
        if (senderBalance < amount) revert InsufficientBalance();
        unchecked {
            _balances[from] = senderBalance - amount;
        }

        uint256 toAmount = amount;
        if (from != G8KEEP) {
            if (to == UNISWAP_V2_PAIR) {
                toAmount = _applyFees(from, amount, sellFee);
            } else if (from == UNISWAP_V2_PAIR) {
                toAmount = _applyFees(from, amount, buyFee);
            }
        }

        unchecked {
            _balances[to] += toAmount;
            emit Transfer(from, to, toAmount);
        }
    }

    /**
     * @dev  Internal function to apply buy and sell fees.
     * @dev  Updates the `_balances` mapping for `_treasuryWallet` and `G8KEEP`
     * @dev  and emits `Transfer` events if their calculated fees are greater than zero.
     * 
     * @param from         Address of the account to transfer tokens from.
     * @param amount       Amount of tokens to transfer from `from`.
     * @param deployerFee  Fee in BPS being assessed by the deployer.
     * 
     * @return toAmount  Amount of tokens to transfer to the recipient after fees are applied.
     */
    function _applyFees(
        address from,
        uint256 amount,
        uint256 deployerFee
    ) internal returns (uint256 toAmount) {
        unchecked {
            uint256 deployerFees;
            if (deployerFee > 0) {
                deployerFees = (amount * deployerFee) / BPS;

                address _treasuryWallet = treasuryWallet;
                _balances[_treasuryWallet] += deployerFees;
                emit Transfer(from, _treasuryWallet, deployerFees);
            }

            uint256 g8keepFees;
            if (G8KEEP_FEE > 0) {
                g8keepFees = (amount * G8KEEP_FEE) / BPS;
                _balances[G8KEEP] += g8keepFees;
                emit Transfer(from, G8KEEP, g8keepFees);
            }

            toAmount = amount - deployerFees - g8keepFees;
        }
    }

    /**
     * @dev  Internal function to check if snipe protection is enabled and adjust the output
     * @dev  amount if it is and the `amount` exceeds the maximum buy without a snipe penalty.
     *
     * @param from        Address of the account to transfer tokens from.
     * @param to          Address of the account to transfer tokens to.
     * @param amount1Out  Amount of tokens to transfer from `from` to `to`.
     *
     * @param adjustedAmount1Out  Amount of tokens to transfer after applying snipe protection.
     */
    function _applySnipeProtection(
        address from,
        address to,
        uint256 amount1Out
    ) internal returns (uint256 adjustedAmount1Out) {
        adjustedAmount1Out = amount1Out;
        if (block.timestamp < SNIPE_PROTECTION_END) {
            (uint256 reserve0, uint256 reserve1, uint256 cachedThirdPartyLPAmount) = _checkLPForIncrease();
            if (from == UNISWAP_V2_PAIR) {
                if (to == UNISWAP_V2_PAIR) {
                    revert CannotTransferFromAndToUniswapV2Pair();
                }

                // Early return to avoid revert on skims
                if (amount1Out == 0) return 0;

                // Check paired token balance for increase in pool, must increase during buy transaction
                uint256 balance0 = IERC20(PAIRED_TOKEN).balanceOf(UNISWAP_V2_PAIR);
                if (balance0 < reserve0) {
                    revert InsufficientPoolInput();
                }
                uint256 amount0In;
                unchecked {
                    amount0In = balance0 - reserve0;
                }
                
                // Calculate max output for input, transfer request cannot be more than calculated output
                uint256 maxAmount1Out = _getAmountOut(amount0In, reserve0, reserve1);
                if (amount1Out > maxAmount1Out) {
                    revert ExcessiveAmountOut();
                }

                // Adjust outputs for snipe protection, transfer penalty tokens to penalty receiver
                uint256 penaltyAmount1Out;
                uint256 cachedLPBalanceBaseline = lpBalanceBaseline;
                (adjustedAmount1Out, penaltyAmount1Out) = _adjustAmountOut(amount1Out, cachedThirdPartyLPAmount, cachedLPBalanceBaseline);
                if (penaltyAmount1Out > 0) {
                    lpBalanceBaseline = cachedLPBalanceBaseline - penaltyAmount1Out;
                    _balances[from] -= penaltyAmount1Out; // from is UNISWAP_V2_PAIR, optimizing bytecode by using stack
                    _balances[PENALTY_TAX_RECEIVER] += penaltyAmount1Out;
                    emit Transfer(from, PENALTY_TAX_RECEIVER, penaltyAmount1Out);
                }
            }
        }
    }

    /**
     * @dev  Internal function used during snipe protection to determine if tokens
     * @dev  have been added to the LP by a third party so that snipe protection can
     * @dev  be applied appropriately.
     * @dev  Returns the LP reserves for use in `_adjustAmountOut` for efficiency.
     * @dev  Returns the third party LP amount for use in `_adjustAmountOut` for efficiency.
     *
     * @return reserve0                  The reserve of `token0` in the LP when the token transfer is called.
     * @return reserve1                  The reserve of `token1` in the LP when the token transfer is called.
     * @return cachedThirdPartyLPAmount  Amount of tokens added to the LP by a third party.
     */
    function _checkLPForIncrease() internal returns (uint256 reserve0, uint256 reserve1, uint256 cachedThirdPartyLPAmount) {
        (reserve0, reserve1) = _getTokenReserves();
        cachedThirdPartyLPAmount = thirdPartyLPAmount;
        uint256 _cachedLPReserve1 = cachedLPReserve1;
        // Cache new reserve1 for future transactions
        cachedLPReserve1 = uint112(reserve1);

        uint256 _lpTotalSupply = IERC20(UNISWAP_V2_PAIR).totalSupply();
        uint256 _lastLPTotalSupply = lastLPTotalSupply;
        if (_lpTotalSupply != _lastLPTotalSupply) {
            // Check if LP has been burned
            if (_lpTotalSupply < _lastLPTotalSupply) {
                revert CannotBurnLiquidityDuringSnipeProtection();
            }

            lastLPTotalSupply = _lpTotalSupply;

            // Skip update on first change to LP total supply
            if (_lastLPTotalSupply != 0) {
                if (reserve1 > _cachedLPReserve1) {
                    // Underflow already checked
                    // Cannot overflow since total supply is limited to type(uint112).max
                    unchecked {
                        cachedThirdPartyLPAmount = cachedThirdPartyLPAmount + 
                            (_lpTotalSupply - _lastLPTotalSupply) * 
                            _cachedLPReserve1 / _lastLPTotalSupply;

                        thirdPartyLPAmount = uint112(cachedThirdPartyLPAmount);
                    }
                }
            }
        }
    }

    /**
     * @dev  Internal function used in view functions to determine if tokens
     * @dev  have been added to the LP by a third party so that snipe protection
     * @dev  calculations can be applied appropriately.
     * @dev  Returns the LP reserves for use in `_adjustAmountOut` for efficiency.
     * @dev  Returns the third party LP amount for use in `_adjustAmountOut` for efficiency.
     *
     * @return reserve0                  The reserve of `token0` in the LP when the view function is called.
     * @return reserve1                  The reserve of `token1` in the LP when the view function is called.
     * @return cachedThirdPartyLPAmount  Amount of tokens added to the LP by a third party.
     */
    function _checkLPForIncreaseView() internal view returns (uint256 reserve0, uint256 reserve1, uint256 cachedThirdPartyLPAmount) {
        cachedThirdPartyLPAmount = thirdPartyLPAmount;
        (reserve0,reserve1) = _getTokenReserves();

        uint256 _lpTotalSupply = IERC20(UNISWAP_V2_PAIR).totalSupply();
        if (!(_lpTotalSupply == lastLPTotalSupply || lastLPTotalSupply == 0)) {
            uint256 _cachedLPReserve1 = cachedLPReserve1;
            if (reserve1 > _cachedLPReserve1) {
                // Underflow already checked
                // Cannot overflow since total supply is limited to type(uint112).max
                unchecked {
                    cachedThirdPartyLPAmount = cachedThirdPartyLPAmount + reserve1 - _cachedLPReserve1;
                }
            }
        }
    }

    /**
     * @dev  Internal function to adjust the amount of tokens being purchased from the
     * @dev  Uniswap V2 Pair during snipe protection when the purchase amount exceeds the
     * @dev  maximum amount that can be purchased without a penalty.
     *
     * @dev  Tokens are released for purchase without snipe protection penalty linearly during
     * @dev  the snipe protection window and penalties increase exponentially when exceeding the
     * @dev  expected balance of the Uniswap V2 Pair.
     * @dev  For example: A token with 100,000 tokens in the initial LP and snipe protection time 
     * @dev    of 60 minutes will have 25,000 tokens available to purchase without penalty after
     * @dev    the token has been deployed for 15 minutes for an expected LP balance of 75,000 tokens.
     * @dev    A buyer that attempts to purchase 62,500 tokens would result in a 37,500 token balance
     * @dev    in the LP which is 50% of expected balance.
     * @dev    Their adjustedAmount1Out would equal 62,500 * 0.5^2 = 15,625 tokens (75% penalty).
     * @dev    Instead of attempting to buy 62,500 tokens, the user should buy the 25,000 tokens
     * @dev    that are available without snipe protection to avoid penalty.
     * @dev  Within the regular snipe protection window there is also a heavy penalty window. During
     * @dev  the heavy penalty window the exponent for applying the penalty starts at a higher value
     * @dev  and decreases linearly until it reaches the base exponent of 2.
     * @dev  For example: Using the example from above with a heavy snipe window of 10 minutes and
     * @dev    a starting penalty exponent of 12. After 6 minutes, there will be 10,000 tokens available
     * @dev    to purchase, expected balance 90,000 tokens, and the snipe penalty exponent will be 6. A 
     * @dev    buyer that attempts to purchase 55,000 tokens would result in a 45,000 token balance
     * @dev    in the LP which is 50% of the expected balance.
     * @dev    Their adjustedAmount1Out would equal 55,000 * 0.5^6 = 859.375 tokens (98.5% penalty).
     * @dev    Instead of attempting to purchase 55,0000 tokens, the user should buy the 10,000 tokens
     * @dev    that are available without snipe protection to avoid penalty.
     *
     * @param amount1Out                Amount of the token being purchased through the Uniswap V2 Pair.
     * @param cachedThirdPartyLPAmount  Amount of tokens added to the LP by a third party.
     * @param cachedLPBalanceBaseline   The baseline balance of the LP for snipe protection.
     *
     * @return adjustedAmount1Out  The amount out after adjusting for snipe protection.
     * @return penaltyAmount1Out   The amount out to the penalty receiver.
     */
    function _adjustAmountOut(
        uint256 amount1Out,
        uint256 cachedThirdPartyLPAmount,
        uint256 cachedLPBalanceBaseline
    ) internal view returns (uint256 adjustedAmount1Out, uint256 penaltyAmount1Out) {
        // Get balance, adjust by amount out
        uint256 balance1 = _balances[UNISWAP_V2_PAIR];
        if (amount1Out > balance1) {
            revert InsufficientBalance();
        }
        
        adjustedAmount1Out = amount1Out;
        uint256 adjustedBalance1;
        unchecked {
            adjustedBalance1 = balance1 - adjustedAmount1Out;
        }

        // Adjust balance for amounts added to the LP by third parties
        if (cachedThirdPartyLPAmount > 0) {
            if (cachedThirdPartyLPAmount > adjustedBalance1) {
                adjustedBalance1 = 0;
            } else {
                unchecked {
                    adjustedBalance1 = adjustedBalance1 - cachedThirdPartyLPAmount;
                }
            }
        }

        // Calculate expected balance based on elapsed time
        uint256 elapsedSeconds = block.timestamp - GENESIS_TIME;
        uint256 expectedBalance1 =
            cachedLPBalanceBaseline - cachedLPBalanceBaseline * elapsedSeconds / SNIPE_PROTECTION_SECONDS;

        // Apply snipe penalties if adjusted balance is less than expected
        if (expectedBalance1 > adjustedBalance1) {
            uint256 exponentPenalty = SNIPE_PENALTY_BASE_EXPONENT;
            if (elapsedSeconds < SNIPE_PROTECTION_HEAVY_PENALTY_SECONDS) {
                unchecked {
                    exponentPenalty += 
                        SNIPE_PROTECTION_HEAVY_EXPONENT_START * 
                        (SNIPE_PROTECTION_HEAVY_PENALTY_SECONDS - elapsedSeconds) / 
                        SNIPE_PROTECTION_HEAVY_PENALTY_SECONDS;
                }
            }
            for (uint256 i; i < exponentPenalty; ++i) {
                adjustedAmount1Out = 
                    adjustedAmount1Out * adjustedBalance1 / expectedBalance1;
            }

            unchecked {
                penaltyAmount1Out = amount1Out - adjustedAmount1Out;
            }
        }
    }

    /**
     * @dev Internal function to get the token reserve balances from the Uniswap V2 Pair.
     *
     * @return reserve0  The reserve of `token0` in the LP.
     * @return reserve1  The reserve of `token1` in the LP.
     */
    function _getTokenReserves() internal view returns (uint256 reserve0, uint256 reserve1) {
        (reserve0,reserve1,) = IUniswapV2Pair(UNISWAP_V2_PAIR).getReserves();
    }

    /**
     * @dev  Internal function to calculate the amount of tokens expected to be received
     * @dev  from a purchase with `amountIn`. This is the same formula used by the 
     * @dev  Uniswap V2 Router when calculating output amount.
     * 
     * @param amountIn    The amount of tokens input to the pair.
     * @param reserveIn   The LP reserve of the input token.
     * @param reserveOut  The LP reserve of the token being purchased.
     *
     * @return amountOut  The calculated amount of output tokens.
     */
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (reserveIn == 0 || reserveOut == 0) revert InvalidReserves();
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}