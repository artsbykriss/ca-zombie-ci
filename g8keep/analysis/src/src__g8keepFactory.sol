// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {g8keepToken} from "./g8keepToken.sol";
import {g8keepPenaltyReceiver} from "./g8keepPenaltyReceiver.sol";
import {g8keepFactoryConfiguration} from "./g8keepFactoryConfiguration.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IG8keepFactory} from "./interfaces/IG8keepFactory.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/**
 * @title   g8keepFactory
 * @notice  Factory for managing deployment parameters, deploying g8keep
 * @notice  token contracts, locking initial liquidity, and managing token fees.
 */
contract g8keepFactory is IG8keepFactory, Ownable {

    /// @dev Wrapped native token contract for token deployments using native currency.
    address public immutable WETH;
    /// @dev Uniswap V2 router address for the chain.
    address public immutable UNISWAP_V2_ROUTER;
    /// @dev Vesting contract to be used when deployer tokens are subject to vesting restrictions.
    address public g8keepTokenVesting;
    /// @dev Fee wallet to receive initial liquidity fees.
    address public g8keepFeeWallet;
    /// @dev Address that will receive penalty tax tokens.
    address public penaltyReceiver;
    /// @dev Fee in BPS assessed on token trades, paid to g8keep. Initial value: 1.0%
    uint16 public g8keepFee = 100;
    /// @dev Fee in BPS assessed on initial liquidity supplied. Initial value: 2.0%
    uint16 public g8keepInitialLiquidityFee = 200;
    /// @dev Maximum buy fee in BPS assessed on token trades, paid to token deployer. Initial value: 5.0%
    uint16 public maxBuyFee = 500;
    /// @dev Maximum sell fee in BPS assessed on token trades, paid to token deployer. Initial value: 5.0%
    uint16 public maxSellFee = 500;
    /// @dev Minimum time in seconds that a deployer's share of tokens must be vested over. Initial value: 1 day
    uint24 public minimumDeployVestTime = 1 days;
    /// @dev Minimum time in seconds that a deployed token must have snipe protection enabled.
    uint24 public minimumSnipeProtectionSeconds = 30 minutes;
    /// @dev Maximum time in seconds that a deployed token may have snipe protection enabled.
    uint24 public maximumSnipeProtectionSeconds = 30 days;
    /// @dev Minimum time in seconds that a deployed token must have heavy snipe protection enabled.
    uint24 public minimumHeavySnipeProtectionSeconds = 30 minutes;
    /// @dev Maximum time in seconds that a deployed token may have heavy snipe protection enabled.
    uint24 public maximumHeavySnipeProtectionSeconds = 1 days;
    /// @dev Minimum exponent that a deployed token must have for heavy snipe penalties.
    uint8 public minimumHeavySnipeExponent = 20;
    /// @dev Maximum exponent that a deployed token may have for heavy snipe penalties.
    uint8 public maximumHeavySnipeExponent = 60;

    /// @dev Guardrail for `g8keepFee` to prevent it from being set over 100 BPS.
    uint16 private constant MAX_SETTING_G8KEEP_FEE = 100;
    /// @dev Guardrail for `g8keepInitialLiquidityFee` to prevent it from being set over 200 BPS.
    uint16 private constant MAX_SETTING_G8KEEP_INITIAL_LIQUIDITY_FEE = 200;
    /// @dev Guardrail for `maxBuyFee` to prevent it from being set over 500 BPS.
    uint16 private constant MAX_SETTING_BUY_FEE = 500;
    /// @dev Guardrail for `maxSellFee` to prevent it from being set over 500 BPS.
    uint16 private constant MAX_SETTING_SELL_FEE = 500;
    /// @dev Guardrail for `minimumDeployVestTime` to prevent it from being set over 90 days.
    uint40 private constant MAX_SETTING_MINIMUM_DEPLOY_VEST_TIME = 90 days;
    /// @dev Guardrail for `minimumSnipeProtectionSeconds` to prevent it from being set over 7 days.
    uint40 private constant MAX_SETTING_MINIMUM_SNIPE_PROTECTION_SECONDS = 7 days;
    /// @dev Guardrail for `maximumSnipeProtectionSeconds` to prevent it from being set over 365 days.
    uint40 private constant MAX_SETTING_MAXIMUM_SNIPE_PROTECTION_SECONDS = 365 days;
    /// @dev Guardrail for `minimumHeavySnipeProtectionSeconds` to prevent it from being set over 1 days.
    uint40 private constant MAX_SETTING_MINIMUM_HEAVY_SNIPE_PROTECTION_SECONDS = 1 days;
    /// @dev Guardrail for `maximumHeavySnipeProtectionSeconds` to prevent it from being set over 5 days.
    uint40 private constant MAX_SETTING_MAXIMUM_HEAVY_SNIPE_PROTECTION_SECONDS = 5 days;
    /// @dev Guardrail for `minimumHeavySnipeExponent` to prevent it from being set under 2.
    uint8 private constant MIN_SETTING_MINIMUM_HEAVY_SNIPE_EXPONENT = 2;
    /// @dev Guardrail for `minimumHeavySnipeExponent` to prevent it from being set over 20.
    uint8 private constant MAX_SETTING_MINIMUM_HEAVY_SNIPE_EXPONENT = 20;
    /// @dev Guardrail for `maximumHeavySnipeExponent` to prevent it from being set over 100.
    uint8 private constant MAX_SETTING_MAXIMUM_HEAVY_SNIPE_EXPONENT = 100;
    /// @dev Constant value for BPS.
    uint16 private constant BPS = 10_000;

    /// @dev Mapping to flag a token address as an allowed pair token for g8keep token deployments.
    mapping(address => bool) public allowedPairs;
    /// @dev Mapping of the minimum initial liquidity to be provided for a paired token.
    mapping(address => uint256) public pairedTokenMinimumLiquidity;
    /// @dev Mapping of tokens that are locked to prevent sale or withdrawal.
    mapping(address => bool) private lockedTokens;

    /// @dev Emitted when a token is deployed.
    event TokenDeployed(
        address indexed token,
        address indexed pair,
        address indexed deployer,
        string symbol
    );

    /// @dev Emitted when the g8keepFactory owner updates deployment settings.
    event DeploymentSettingsUpdated(
        uint16 maxBuyFee,
        uint16 maxSellFee,
        uint24 minimumDeployVestTime,
        uint24 minimumSnipeProtectionSeconds,
        uint24 maximumSnipeProtectionSeconds,
        uint24 minimumHeavySnipeProtectionSeconds,
        uint24 maximumHeavySnipeProtectionSeconds,
        uint8 minimumHeavySnipeExponent,
        uint8 maximumHeavySnipeExponent
    );

    /// @dev Emitted when the g8keepFactory owner updates a paired token settings.
    event PairedTokenSettingsUpdated(
        address indexed pairedToken,
        bool allowed,
        uint256 minimumLiquidity
    );

    /// @dev Emitted when the g8keepFactory owner updates a penalty receiver.
    event PenaltyReceiverUpdated(
        address indexed penaltyReceiver
    );

    /// @dev Thrown when arrays must match in length and they do not.
    error ArrayLengthMismatch();
    /// @dev Thrown when selling tokens and the deadline for the sale has passed.
    error DeadlinePassed();
    /// @dev Thrown when the deposit to the WETH contract for initial liquidity fails.
    error FailedToDepositWETH();
    /// @dev Thrown when deploying a token and the parameters are not compliant with deployment settings.
    error InvalidDeploymentParameters();
    /// @dev Thrown when the g8keepFactory owner is updating deployment settings and they are not compliant
    /// @dev with the constant guardrails or when setting a penalty receiver that is the current receiver.
    error InvalidSettings();
    /// @dev Thrown when deploying a token and the initial liquidity is less than the minimum required.
    error NotEnoughInitialLiquidity();
    /// @dev Thrown when deploying a token with a paired token that is not allowed.
    error PairNotAllowed();
    /// @dev Thrown when attempting to withdraw a token that is locked.
    error TokenLocked();
    /// @dev Thrown when native value is sent with a token deployment that does not use wrapped native.
    error ValueNotAllowedForNonWETHPairs();
    /// @dev Thrown when deploying a token and the value sent exceeds the initial liquidity specified.
    error ValueSentNotValid();
    /// @dev Thrown when withdrawing native token from the contract and the withdrawal fails.
    error WithdrawalFailed();
    /// @dev Thrown when a supplied address that must be non-zero is zero.
    error ZeroAddress();

    /// @dev Struct used for defining token sale parameters.
    struct TokenSale {
        address tokenAddress; // Address of the token to sell.
        uint256 amountToSell; // Amount of the token to sell.
        uint256 amountOutMin; // Minimum amount of paired token to receive.
        address recipient;    // Address to receive the sale value at.
    }

    /**
     * @dev Constructs the g8keepFactory contract.
     * @dev Initialization parameters are retrieved from a configuration contract so that
     * @dev the g8keepFactory may be deterministically deployed on EVM chains at the same
     * @dev address. 
     * 
     * @param _g8keepFactoryConfiguration  The address of the factory configuration contract to retrieve configuration parameters.
     */
    constructor(address _g8keepFactoryConfiguration) {
        g8keepFactoryConfiguration config = g8keepFactoryConfiguration(_g8keepFactoryConfiguration);
        (
            address _defaultOwner,
            address _g8keepFeeWallet,
            address _uniswapV2Router,
            address _WETH,
            uint256 _minimumWETHLiquidity
        ) = config.getFactoryConfiguration();

        if (
            _defaultOwner == address(0)
            || _g8keepFeeWallet == address(0)
            || _uniswapV2Router == address(0)
            || _WETH == address(0)
        ) {
            revert ZeroAddress();
        }

        _initializeOwner(_defaultOwner);
        allowedPairs[_WETH] = true;
        pairedTokenMinimumLiquidity[_WETH] = _minimumWETHLiquidity;
        WETH = _WETH;
        UNISWAP_V2_ROUTER = _uniswapV2Router;
        g8keepFeeWallet = _g8keepFeeWallet;
        
        penaltyReceiver = address(new g8keepPenaltyReceiver(_defaultOwner));

        SafeTransferLib.safeApprove(_WETH, _uniswapV2Router, type(uint256).max);
    }

    /////////// PUBLIC FUNCTIONS ///////////

    /**
     * @notice Deploys a g8keepToken contract, creates and funds the LP, locks initial liquidity.
     *
     * @dev    Parameters must be within ranges defined by the factory settings.
     * @dev    Token salt value must be calculated to generate a token deployment address
     * @dev    that is greater than the `_pairedToken` address.
     *
     * @param _initialLiquidity        Amount of paired token to supply as liquidity in the LP.
     * @param _name                    Name of the token being deployed.
     * @param _symbol                  Symbol of the token being deployed.
     * @param _totalSupply             Total supply to be minted during deployment.
     * @param _treasuryWallet          Address that will receive deployer buy and sell fees.
     * @param _buyFee                  Buy fee in BPS.
     * @param _sellFee                 Sell fee in BPS.
     * @param _pairedToken             Address of the token to pair with in the LP.
     * @param _deployReserve           Amount of total supply in BPS to allocate to deployer.
     * @param _deployVestTime          Time in seconds to vest the deployer's allocation.
     * @param _snipeProtectionSeconds  Amount of time in seconds that snipe protection will be enabled.
     * @param _heavySnipeSeconds       Amount of time in seconds that heavy snipe penalty is enabled.
     * @param _heavySnipeExponent      Starting exponent for heavy snipe penalty.
     * @param _tokenSalt               Salt for token deployment to generate a deterministic address.
     */
    function deployToken(
        uint256 _initialLiquidity,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _treasuryWallet,
        uint16 _buyFee,
        uint16 _sellFee,
        address _pairedToken,
        uint256 _deployReserve,
        uint256 _deployVestTime,
        uint256 _snipeProtectionSeconds,
        uint256 _heavySnipeSeconds,
        uint256 _heavySnipeExponent,
        bytes32 _tokenSalt
    ) external payable returns (address _tokenAddress) {
        if (!allowedPairs[_pairedToken]) revert PairNotAllowed();
        if (
            _buyFee > maxBuyFee || _sellFee > maxSellFee || _deployVestTime < minimumDeployVestTime
                || (_deployVestTime > 0 && g8keepTokenVesting == address(0))
                || _snipeProtectionSeconds < minimumSnipeProtectionSeconds
                || _snipeProtectionSeconds > maximumSnipeProtectionSeconds 
                || _heavySnipeSeconds < minimumHeavySnipeProtectionSeconds
                || _heavySnipeSeconds > maximumHeavySnipeProtectionSeconds 
                || _heavySnipeExponent < minimumHeavySnipeExponent
                || _heavySnipeExponent > maximumHeavySnipeExponent
                || lockedTokens[_pairedToken]
                || _treasuryWallet == address(0)
        ) {
            revert InvalidDeploymentParameters();
        }

        if (_pairedToken == WETH) {
            if (msg.value > _initialLiquidity) {
                revert ValueSentNotValid();
            }

            // Deposit native tokens to WETH
            if (msg.value > 0) {
                (bool success,) = WETH.call{value: msg.value}("");
                if (!success) revert FailedToDepositWETH();
            }
            // If value is insufficient for liquidity, attempt to transfer WETH
            if (msg.value < _initialLiquidity) {
                unchecked {
                    SafeTransferLib.safeTransferFrom(
                        WETH,
                        msg.sender,
                        address(this),
                        _initialLiquidity - msg.value
                    );
                }
            }
        } else if (msg.value > 0) {
            revert ValueNotAllowedForNonWETHPairs();
        } else {
            uint256 balanceBefore = IERC20(_pairedToken).balanceOf(address(this));
            SafeTransferLib.safeTransferFrom(_pairedToken, msg.sender, address(this), _initialLiquidity);
            uint256 balanceAfter = IERC20(_pairedToken).balanceOf(address(this));
            if (balanceAfter > balanceBefore) {
                unchecked {
                    _initialLiquidity = balanceAfter - balanceBefore;
                }
            } else {
                _initialLiquidity = 0;
            }
        }

        g8keepToken token = new g8keepToken{salt: _tokenSalt}(
            msg.sender,
            _name,
            _symbol,
            _totalSupply,
            _treasuryWallet,
            penaltyReceiver,
            _buyFee,
            _sellFee,
            g8keepFee,
            UNISWAP_V2_ROUTER,
            _pairedToken,
            _deployReserve,
            _deployVestTime,
            _snipeProtectionSeconds,
            _heavySnipeSeconds,
            _heavySnipeExponent
        );

        address pairAddress = token.UNISWAP_V2_PAIR();

        if (IERC20(_pairedToken).balanceOf(pairAddress) > 0) {
            uint256 balanceBefore = IERC20(_pairedToken).balanceOf(address(this));
            IUniswapV2Pair(pairAddress).skim(address(this));
            uint256 balanceAfter = IERC20(_pairedToken).balanceOf(address(this));
            if (balanceAfter > balanceBefore) {
                unchecked {
                    _initialLiquidity = _initialLiquidity + balanceAfter - balanceBefore;
                }
            }
        }

        if (_initialLiquidity < pairedTokenMinimumLiquidity[_pairedToken]) revert NotEnoughInitialLiquidity();

        //Prevent sales of the LP token
        lockedTokens[pairAddress] = true;

        uint256 valueToG8keep = (_initialLiquidity * g8keepInitialLiquidityFee) / BPS;
        if (valueToG8keep > 0) {
            SafeTransferLib.safeTransfer(_pairedToken, g8keepFeeWallet, valueToG8keep);
        }


        // add liquidity to LP
        IUniswapV2Router02(UNISWAP_V2_ROUTER).addLiquidity(
            _pairedToken,
            address(token),
            _initialLiquidity - valueToG8keep,
            token.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        // emit Event for UI to store token details
        emit TokenDeployed(address(token), pairAddress, msg.sender, _symbol);

        return address(token);
    }

    /////////// OWNER FUNCTIONS ///////////

    /**
     * @notice Admin function to configure a paired token.
     *
     * @param pairedToken       Address of the paired token to configure.
     * @param allowed           True if the token is allowed as a paired token, false if not.
     * @param minimumLiquidity  Minimum amount of token that may be supplied as initial liquidity.
     */
    function setPairedTokenSettings(
        address pairedToken,
        bool allowed,
        uint256 minimumLiquidity
    ) external onlyOwner {
        uint256 allowanceAmount;
        if (allowed) {
            allowanceAmount = type(uint256).max;
        }

        _setPairedTokenSettings(pairedToken, allowed, minimumLiquidity, allowanceAmount);
    }

    /**
     * @notice Admin function to configure a paired token with a specific allowance amount.
     *
     * @dev    Used for certain ERC20 tokens that have unusual approval methods.
     *
     * @param pairedToken       Address of the paired token to configure.
     * @param allowed           True if the token is allowed as a paired token, false if not.
     * @param minimumLiquidity  Minimum amount of token that may be supplied as initial liquidity.
     * @param allowanceAmount   Amount to set for the allowance to the Uniswap Router.
     */
    function setPairedTokenSettingsWithAllowance(
        address pairedToken,
        bool allowed,
        uint256 minimumLiquidity,
        uint256 allowanceAmount
    ) external onlyOwner {
        _setPairedTokenSettings(pairedToken, allowed, minimumLiquidity, allowanceAmount);
    }

    /**
     * @notice  Admin function to configure deployment parameters.
     *
     * @dev     Settings parameters must be within the constant guardrails defined.
     * 
     * @param _maxBuyFee                           Maximum buy fee in BPS.
     * @param _maxSellFee                          Maximum sell fee in BPS.
     * @param _minimumDeployVestTime               Minimum time in seconds that a deployer tokens must vest over.
     * @param _minimumSnipeProtectionSeconds       Minimum time in seconds for snipe protection to be enabled.
     * @param _maximumSnipeProtectionSeconds       Maximum time in seconds for snipe protection to be enabled.
     * @param _minimumHeavySnipeProtectionSeconds  Minimum time in seconds for heavy snipe protection to be enabled.
     * @param _maximumHeavySnipeProtectionSeconds  Maximum time in seconds for heavy snipe protection to be enabled.
     * @param _minimumHeavySnipeExponent           Minimum exponent penalty during heavy snipe protection.
     * @param _maximumHeavySnipeExponent           Maximum exponent penalty during heavy snipe protection.
     */
    function setDeploymentSettings(
        uint16 _maxBuyFee,
        uint16 _maxSellFee,
        uint24 _minimumDeployVestTime,
        uint24 _minimumSnipeProtectionSeconds,
        uint24 _maximumSnipeProtectionSeconds,
        uint24 _minimumHeavySnipeProtectionSeconds,
        uint24 _maximumHeavySnipeProtectionSeconds,
        uint8 _minimumHeavySnipeExponent,
        uint8 _maximumHeavySnipeExponent
    ) external onlyOwner {
        if (
            _maxBuyFee > MAX_SETTING_BUY_FEE || _maxSellFee > MAX_SETTING_SELL_FEE
                || _minimumDeployVestTime > MAX_SETTING_MINIMUM_DEPLOY_VEST_TIME
                || (_minimumDeployVestTime > 0 && g8keepTokenVesting == address(0))
                || _minimumSnipeProtectionSeconds > MAX_SETTING_MINIMUM_SNIPE_PROTECTION_SECONDS
                || _maximumSnipeProtectionSeconds > MAX_SETTING_MAXIMUM_SNIPE_PROTECTION_SECONDS
                || _minimumSnipeProtectionSeconds > _maximumSnipeProtectionSeconds
                || _minimumHeavySnipeProtectionSeconds > MAX_SETTING_MINIMUM_HEAVY_SNIPE_PROTECTION_SECONDS
                || _maximumHeavySnipeProtectionSeconds > MAX_SETTING_MAXIMUM_HEAVY_SNIPE_PROTECTION_SECONDS
                || _minimumHeavySnipeProtectionSeconds > _maximumHeavySnipeProtectionSeconds
                || _minimumHeavySnipeExponent < MIN_SETTING_MINIMUM_HEAVY_SNIPE_EXPONENT
                || _minimumHeavySnipeExponent > MAX_SETTING_MINIMUM_HEAVY_SNIPE_EXPONENT
                || _maximumHeavySnipeExponent > MAX_SETTING_MAXIMUM_HEAVY_SNIPE_EXPONENT
                || _minimumHeavySnipeExponent > _maximumHeavySnipeExponent
        ) {
            revert InvalidSettings();
        }

        maxBuyFee = _maxBuyFee;
        maxSellFee = _maxSellFee;
        minimumDeployVestTime = _minimumDeployVestTime;
        minimumSnipeProtectionSeconds = _minimumSnipeProtectionSeconds;
        maximumSnipeProtectionSeconds = _maximumSnipeProtectionSeconds;
        minimumHeavySnipeProtectionSeconds = _minimumHeavySnipeProtectionSeconds;
        maximumHeavySnipeProtectionSeconds = _maximumHeavySnipeProtectionSeconds;
        minimumHeavySnipeExponent = _minimumHeavySnipeExponent;
        maximumHeavySnipeExponent = _maximumHeavySnipeExponent;

        emit DeploymentSettingsUpdated(
            _maxBuyFee,
            _maxSellFee,
            _minimumDeployVestTime,
            _minimumSnipeProtectionSeconds,
            _maximumSnipeProtectionSeconds,
            _minimumHeavySnipeProtectionSeconds,
            _maximumHeavySnipeProtectionSeconds,
            _minimumHeavySnipeExponent,
            _maximumHeavySnipeExponent
        );
    }

    /**
     * @notice  Admin function to set the g8keep fee that will be assessed on token trades.
     *
     * @dev     Fee must be less than the constant guardrail settings.
     *
     * @param _g8keepFee  Fee in BPS to assess on token trades.
     */
    function setG8keepFee(uint16 _g8keepFee) external onlyOwner {
        if (_g8keepFee > MAX_SETTING_G8KEEP_FEE) {
            revert InvalidSettings();
        }

        g8keepFee = _g8keepFee;
    }

    /**
     * @notice  Admin function to set the g8keep fee that will be assessed on initial liquidity.
     *
     * @dev     Fee must be less than the constant guardrail settings.
     *
     * @param _g8keepInitialLiquidityFee  Fee in BPS to assess on initial liquidity.
     */
    function setG8keepInitialLiquidityFee(uint16 _g8keepInitialLiquidityFee) external onlyOwner {
        if (_g8keepInitialLiquidityFee > MAX_SETTING_G8KEEP_INITIAL_LIQUIDITY_FEE) {
            revert InvalidSettings();
        }

        g8keepInitialLiquidityFee = _g8keepInitialLiquidityFee;
    }

    /**
     * @notice  Admin function to set the g8keep vesting contract address.
     *
     * @dev     The vesting contract address may only be set to the zero address when minimum vesting time is set to zero.
     *
     * @param _g8keepTokenVesting  Address of the g8keep token vesting contract.
     */
    function setG8keepTokenVestingAddress(address _g8keepTokenVesting) external onlyOwner {
        if (_g8keepTokenVesting == address(0) && minimumDeployVestTime > 0) {
            revert InvalidSettings();
        }

        g8keepTokenVesting = _g8keepTokenVesting;
    }

    /**
     * @notice  Admin function to set the g8keep fee wallet to receive initial liquidity fees.
     *
     * @dev     The fee wallet cannot be set to the zero address.
     * 
     * @param _g8keepFeeWallet  Address of the g8keep fee wallet.
     */
    function setG8keepFeeWallet(address _g8keepFeeWallet) external onlyOwner {
        if (_g8keepFeeWallet == address(0)) {
            revert ZeroAddress();
        }

        g8keepFeeWallet = _g8keepFeeWallet;
    }

    /**
     * @notice  Admin function to set the penalty receiver address.
     *
     * @dev     The penalty receiver cannot be set to the zero address.
     * 
     * @param _penaltyReceiver  Address of the penalty receiver.
     */
    function setPenaltyReceiver(address _penaltyReceiver) external onlyOwner {
        if (_penaltyReceiver == address(0)) {
            revert ZeroAddress();
        }

        address currentPenaltyReceiver = penaltyReceiver;
        if (currentPenaltyReceiver == _penaltyReceiver) {
            revert InvalidSettings();
        }

        penaltyReceiver = _penaltyReceiver;
        emit PenaltyReceiverUpdated(_penaltyReceiver);
    }

    /**
     * @notice  Admin function to update approvals to the Uniswap router.
     *
     * @dev     Used to update or revoke approvals in case there is an unusual approval
     * @dev     mechanism on a paired ERC20 token.
     * 
     * @param tokenAddresses        Array of tokens to set approvals on.
     * @param approved              Array specifying whether to approve or revoke approval.
     * @param approvalRevokeAmount  Amount to use when revoking approvals.
     */
    function setApprovalToUniswapRouter(
        address[] calldata tokenAddresses,
        bool[] calldata approved,
        uint256 approvalRevokeAmount
    ) external onlyOwner {
        if (tokenAddresses.length != approved.length) {
            revert ArrayLengthMismatch();
        }
        
        for (uint256 i; i < tokenAddresses.length; ++i) {
            address tokenAddress = tokenAddresses[i];
            //skip locked tokens
            if (lockedTokens[tokenAddress]) continue;

            if (approved[i]) {
                SafeTransferLib.safeApproveWithRetry(tokenAddress, UNISWAP_V2_ROUTER, type(uint256).max);
            } else {
                SafeTransferLib.safeApproveWithRetry(tokenAddress, UNISWAP_V2_ROUTER, approvalRevokeAmount);
            }
        }
    }

    /**
     * @notice  Admin function to sell the tokens collected as fees on the g8keep platform.
     * 
     * @dev     Locked tokens supplied in `sellParameters` will be skipped without reverting.
     *
     * @param sellParameters  Array of token sale parameters to execute on the Uniswap router.
     * @param deadline        Timestamp that the transaction must execute by or revert.
     */
    function sellTokens(TokenSale[] calldata sellParameters, uint256 deadline) external onlyOwner {
        if (deadline < block.timestamp) {
            revert DeadlinePassed();
        }
        
        for (uint256 i; i < sellParameters.length; ++i) {
            TokenSale calldata sale = sellParameters[i];
            address tokenAddress = sale.tokenAddress;
            if (lockedTokens[tokenAddress]) {
                // skip locked LP tokens
                continue;
            }
            if (sale.recipient == address(0)) {
                revert ZeroAddress();
            }
            
            address[] memory path = new address[](2);
            path[0] = tokenAddress;
            path[1] = g8keepToken(tokenAddress).PAIRED_TOKEN();
            try IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sale.amountToSell, sale.amountOutMin, path, sale.recipient, block.timestamp
            ) {} catch {}
        }
    }

    /**
     * @notice  Admin function to withdraw a token that is held by the factory contract.
     * 
     * @dev     Withdrawing a locked token will revert the transaction.
     * @dev     Will withdraw the entire balance of the token.
     * 
     * @param tokenAddress  Address of the token to withdraw.
     * @param to            Address to withdraw the token to.
     */
    function withdrawToken(address tokenAddress, address to) external onlyOwner {
        if (lockedTokens[tokenAddress]) {
            revert TokenLocked();
        }
        uint256 _contractBalance = IERC20(tokenAddress).balanceOf(address(this));
        SafeTransferLib.safeTransfer(tokenAddress, to, _contractBalance);
    }

    /**
     * @notice  Admin function to withdraw a token that is held by the factory contract.
     * 
     * @dev     Withdrawing a locked token will revert the transaction.
     * @dev     Will withdraw the specified `amount` of token.
     * 
     * @param tokenAddress  Address of the token to withdraw.
     * @param to            Address to withdraw the token to.
     * @param amount        Amount of the token to withdraw.
     */
    function withdrawToken(address tokenAddress, address to, uint256 amount) external onlyOwner {
        if (lockedTokens[tokenAddress]) {
            revert TokenLocked();
        }
        SafeTransferLib.safeTransfer(tokenAddress, to, amount);
    }

    /**
     * @notice  Admin function to withdraw native token that is held by the factory contract.
     * 
     * @dev     Will withdraw the entire balance.
     * 
     * @param to            Address to withdraw the token to.
     */
    function withdrawETH(address to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();

        (bool success,) = to.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    /////////// INTERNAL FUNCTIONS ///////////

    /**
     * @dev  Internal function for `setPairedTokenSettings` and `setPairedTokenSettingsWithAllowance`.
     *
     * @param pairedToken       Address of the paired token to configure.
     * @param allowed           True if the token is allowed as a paired token, false if not.
     * @param minimumLiquidity  Minimum amount of token that may be supplied as initial liquidity.
     * @param allowanceAmount   Amount to set for the allowance to the Uniswap Router.
     */
    function _setPairedTokenSettings(address pairedToken, bool allowed, uint256 minimumLiquidity, uint256 allowanceAmount) internal {
        if (lockedTokens[pairedToken]) revert TokenLocked();

        allowedPairs[pairedToken] = allowed;
        pairedTokenMinimumLiquidity[pairedToken] = minimumLiquidity;
        SafeTransferLib.safeApproveWithRetry(pairedToken, UNISWAP_V2_ROUTER, allowanceAmount);

        emit PairedTokenSettingsUpdated(
            pairedToken,
            allowed,
            minimumLiquidity
        );
    }
}
