
// ===== contracts/credit/CreditFacadeV3.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

// THIRD-PARTY
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

// INTERFACES
import {IBotListV3} from "../interfaces/IBotListV3.sol";
import {AllowanceAction} from "../interfaces/ICreditConfiguratorV3.sol";
import {DebtLimits, FullCheckParams, ICreditFacadeV3, MultiCall} from "../interfaces/ICreditFacadeV3.sol";
import "../interfaces/ICreditFacadeV3Multicall.sol";
import {
    CollateralCalcTask,
    CollateralDebtData,
    ICreditManagerV3,
    ManageDebtAction
} from "../interfaces/ICreditManagerV3.sol";
import "../interfaces/IExceptions.sol";
import {IPoolV3} from "../interfaces/IPoolV3.sol";
import {IPriceOracleV3} from "../interfaces/IPriceOracleV3.sol";
import {IAddressProvider} from "../interfaces/base/IAddressProvider.sol";
import {IDegenNFT} from "../interfaces/base/IDegenNFT.sol";
import {ILossPolicy} from "../interfaces/base/ILossPolicy.sol";
import {IPhantomToken, IPhantomTokenWithdrawer} from "../interfaces/base/IPhantomToken.sol";
import {IPriceFeedStore, PriceUpdate} from "../interfaces/base/IPriceFeedStore.sol";
import {IWETH} from "../interfaces/external/IWETH.sol";

// LIBRARIES
import {Balance, BalanceDelta, BalanceWithMask, BalancesLogic, Comparison} from "../libraries/BalancesLogic.sol";
import {BitMask} from "../libraries/BitMask.sol";
import {
    AP_PRICE_FEED_STORE,
    BOT_PERMISSIONS_SET_FLAG,
    INACTIVE_CREDIT_ACCOUNT_ADDRESS,
    NO_VERSION_CONTROL,
    PERCENTAGE_FACTOR,
    UNDERLYING_TOKEN_MASK,
    DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER
} from "../libraries/Constants.sol";
import {MarketHelper} from "../libraries/MarketHelper.sol";
import {OptionalCall} from "../libraries/OptionalCall.sol";

// TRAITS
import {ACLTrait} from "../traits/ACLTrait.sol";
import {ReentrancyGuardTrait} from "../traits/ReentrancyGuardTrait.sol";
import {SanityCheckTrait} from "../traits/SanityCheckTrait.sol";

/// @title Credit facade V3
/// @notice Provides a user interface to open, close and liquidate leveraged positions in the credit manager,
///         and implements the main entry-point for credit accounts management: multicall.
/// @notice Multicall allows account owners to batch all the desired operations (adding or withdrawing collateral,
///         changing debt size, interacting with external protocols via adapters or increasing quotas) into one call,
///         followed by the collateral check that ensures that account is sufficiently collateralized.
///         For more details on what one can achieve with multicalls, see `_multicall` and  `ICreditFacadeV3Multicall`.
/// @notice Users can also let external bots manage their accounts via `botMulticall`. Bots can be relatively general,
///         the facade only ensures that they can do no harm to the protocol by running the collateral check after the
///         multicall and checking the permissions given to them by users. See `BotListV3` for additional details.
/// @notice Credit facade implements a few safeguards on top of those present in the credit manager, including
///         - debt and quota size validation
///         - degen NFT whitelist mode
///         - policies on how liquidations with loss are performed
///         - forbidden tokens (they count towards account value, but having them enabled as collateral restricts allowed
///         actions and triggers a safer version of collateral check, incentivizing users to decrease exposure to them).
contract CreditFacadeV3 is ICreditFacadeV3, Pausable, ACLTrait, ReentrancyGuardTrait, SanityCheckTrait {
    using Address for address;
    using BitMask for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MarketHelper for ICreditManagerV3;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Contract type
    bytes32 public constant override contractType = "CREDIT_FACADE";

    /// @notice Maximum quota size, as a multiple of `maxDebt`
    uint256 public constant override maxQuotaMultiplier = 2;

    /// @notice Credit manager connected to this credit facade
    address public immutable override creditManager;

    /// @notice Credit manager's underlying token
    address public immutable override underlying;

    /// @notice Pool's treasury to pay fees to
    address public immutable override treasury;

    /// @notice Price feed store to update price feeds on-demand
    address public immutable override priceFeedStore;

    /// @notice Whether credit facade is expirable
    bool public immutable override expirable;

    /// @notice WETH token address
    address public immutable override weth;

    /// @notice Degen NFT address
    address public immutable override degenNFT;

    /// @notice Expiration timestamp
    uint40 public override expirationDate;

    /// @notice Maximum amount that can be borrowed by a credit manager in a single block, as a multiple of `maxDebt`
    uint8 public override maxDebtPerBlockMultiplier = DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER;

    /// @dev Last block when underlying was borrowed by a credit manager
    uint64 internal lastBlockBorrowed;

    /// @dev The total amount borrowed by a credit manager in `lastBlockBorrowed`
    uint128 internal totalBorrowedInBlock;

    /// @notice Bot list address
    address public immutable override botList;

    /// @notice Credit account debt limits packed into a single slot
    DebtLimits public override debtLimits;

    /// @notice Bit mask encoding a set of forbidden tokens
    uint256 public override forbiddenTokenMask;

    /// @notice Contract that enforces a policy on how liquidations with loss are performed
    address public override lossPolicy;

    /// @dev Ensures that function caller is credit configurator
    modifier creditConfiguratorOnly() {
        _checkCreditConfigurator();
        _;
    }

    /// @dev Ensures that function caller is `creditAccount`'s owner
    modifier creditAccountOwnerOnly(address creditAccount) {
        _checkCreditAccountOwner(creditAccount);
        _;
    }

    /// @dev Ensures that function can't be called when the contract is paused, unless
    ///      caller is an approved emergency liquidator
    modifier whenNotPausedOrEmergency() {
        require(!paused() || _hasRole("EMERGENCY_LIQUIDATOR", msg.sender), "Pausable: paused");
        _;
    }

    /// @dev Ensures that function can't be called when the contract is expired
    modifier whenNotExpired() {
        _checkExpired();
        _;
    }

    /// @dev Wraps any ETH sent in a function call and sends it back to the caller
    modifier wrapETH() {
        _wrapETH();
        _;
    }

    /// @notice Constructor
    /// @param _addressProvider Address provider contract address
    /// @param _creditManager Credit manager to connect this facade to
    /// @param _lossPolicy Loss policy address
    /// @param _botList Bot list address
    /// @param _weth WETH token address
    /// @param _degenNFT Degen NFT address or `address(0)`
    /// @param _expirable Whether this facade should be expirable. If `true`, the expiration date remains unset,
    ///        and facade never expires, until the date is set via `setExpirationDate` in the configurator.
    constructor(
        address _addressProvider,
        address _creditManager,
        address _lossPolicy,
        address _botList,
        address _weth,
        address _degenNFT,
        bool _expirable
    ) ACLTrait(ICreditManagerV3(_creditManager).getACL()) nonZeroAddress(_lossPolicy) nonZeroAddress(_botList) {
        creditManager = _creditManager; // U:[FA-1]
        lossPolicy = _lossPolicy; // U:[FA-1]
        botList = _botList; // U:[FA-1]
        weth = _weth; // U:[FA-1]
        degenNFT = _degenNFT; // U:[FA-1]
        expirable = _expirable; // U:[FA-1]

        underlying = ICreditManagerV3(_creditManager).underlying(); // U:[FA-1]
        treasury = ICreditManagerV3(_creditManager).getTreasury(); // U:[FA-1]
        priceFeedStore = IAddressProvider(_addressProvider).getAddressOrRevert(AP_PRICE_FEED_STORE, NO_VERSION_CONTROL); // U:[FA-1]
    }

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    /// @notice Opens a new credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - If Degen NFT is enabled, burns one from the caller
    ///         - Opens an account in the credit manager
    ///         - Performs a multicall (all calls allowed except debt decrease)
    ///         - Runs the collateral check
    /// @param onBehalfOf Address on whose behalf to open the account
    /// @param calls List of calls to perform after opening the account
    /// @param referralCode Referral code to use for potential rewards, 0 if no referral code is provided
    /// @return creditAccount Address of the newly opened account
    /// @dev Reverts if credit facade is paused or expired
    /// @dev Reverts if `onBehalfOf` is not caller while Degen NFT is enabled
    function openCreditAccount(address onBehalfOf, MultiCall[] calldata calls, uint256 referralCode)
        external
        payable
        override
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
        returns (address creditAccount)
    {
        if (degenNFT != address(0)) {
            if (msg.sender != onBehalfOf) {
                revert ForbiddenInWhitelistedModeException(); // U:[FA-9]
            }
            IDegenNFT(degenNFT).burn(onBehalfOf, 1); // U:[FA-9]
        }

        creditAccount = ICreditManagerV3(creditManager).openCreditAccount({onBehalfOf: onBehalfOf}); // U:[FA-10]

        emit OpenCreditAccount(creditAccount, onBehalfOf, msg.sender, referralCode); // U:[FA-10]

        if (calls.length != 0) {
            _multicall({
                creditAccount: creditAccount,
                calls: calls,
                enabledTokensMask: UNDERLYING_TOKEN_MASK,
                flags: OPEN_CREDIT_ACCOUNT_PERMISSIONS
            }); // U:[FA-10]
        }
    }

    /// @notice Closes a credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - Performs a multicall (all calls are allowed except debt increase)
    ///         - Closes a credit account in the credit manager
    ///         - Erases all bots permissions
    /// @param creditAccount Account to close
    /// @param calls List of calls to perform before closing the account
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager by caller
    /// @dev Reverts if facade is paused
    /// @dev Reverts if account's debt is not zero after executing `calls`
    function closeCreditAccount(address creditAccount, MultiCall[] calldata calls)
        external
        payable
        override
        creditAccountOwnerOnly(creditAccount) // U:[FA-5]
        whenNotPaused // U:[FA-2]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
    {
        if (calls.length != 0) {
            _multicall({
                creditAccount: creditAccount,
                calls: calls,
                enabledTokensMask: _enabledTokensMaskOf(creditAccount),
                flags: CLOSE_CREDIT_ACCOUNT_PERMISSIONS | SKIP_COLLATERAL_CHECK_FLAG
            }); // U:[FA-11]
        }

        if (_flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG != 0) {
            IBotListV3(botList).eraseAllBotPermissions(creditAccount); // U:[FA-11]
        }

        ICreditManagerV3(creditManager).closeCreditAccount(creditAccount); // U:[FA-11]

        emit CloseCreditAccount(creditAccount, msg.sender); // U:[FA-11]
    }

    /// @notice Liquidates a credit account
    ///         - Updates price feeds before running all computations if such call is present in the multicall
    ///         - Evaluates account's collateral and debt to determine whether liquidated account is unhealthy or expired
    ///         - If account has bad debt, liquidation is only allowed when it doesn't violate the loss policy,
    ///           further borrowing through the facade is forbidden in this case
    ///         - Performs a multicall (only `addCollateral`, `withdrawCollateral` and adapter calls are allowed)
    ///         - Liquidates a credit account in the credit manager, which repays debt to the pool, removes quotas, and
    ///           transfers underlying to the liquidator
    /// @notice The function computes account’s total value (oracle value of enabled tokens), discounts it by liquidator’s
    ///         premium, and uses this value to compute funds due to the pool and owner.
    ///         Debt to the pool must be repaid in underlying, while funds due to owner might be covered by underlying
    ///         as well as by tokens that counted towards total value calculation, with the only condition that balance
    ///         of such tokens can’t be increased in the multicall.
    ///         Typically, a liquidator would swap all holdings on the account to underlying via multicall and receive
    ///         the premium in underlying.
    ///         An alternative strategy would be to add underlying collateral to repay debt and withdraw desired tokens
    ///         to handle them in another way, while remaining tokens would cover funds due to owner.
    /// @param creditAccount Account to liquidate
    /// @param to Address to transfer underlying left after liquidation
    /// @param calls List of calls to perform before liquidating the account
    /// @param lossPolicyData Additional data to pass to the loss policy contract
    /// @dev If facade is paused, reverts if caller is not an approved emergency liquidator
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager
    /// @dev Reverts if account has no debt or is neither unhealthy nor expired
    /// @dev Reverts if remaining token balances increase during the multicall
    /// @dev Liquidator can fully seize non-enabled tokens so it's highly recommended to avoid holding them.
    ///      Since adapter calls are allowed, unclaimed rewards from integrated protocols are also at risk;
    ///      bots can be used to claim and withdraw them.
    function liquidateCreditAccount(
        address creditAccount,
        address to,
        MultiCall[] calldata calls,
        bytes memory lossPolicyData
    )
        public
        override
        whenNotPausedOrEmergency // U:[FA-2,12]
        nonReentrant // U:[FA-4]
    {
        uint256 flags = LIQUIDATE_CREDIT_ACCOUNT_PERMISSIONS | SKIP_COLLATERAL_CHECK_FLAG;
        if (
            calls.length != 0 && calls[0].target == address(this)
                && bytes4(calls[0].callData) == ICreditFacadeV3Multicall.onDemandPriceUpdates.selector
        ) {
            _onDemandPriceUpdates(calls[0].callData[4:]);
            flags |= SKIP_PRICE_UPDATES_CALL_FLAG;
        }

        (CollateralDebtData memory collateralDebtData, bool isUnhealthy) = _revertIfNotLiquidatable(creditAccount); // U:[FA-13,14]
        if (isUnhealthy && _hasBadDebt(collateralDebtData)) {
            ILossPolicy.Params memory params = ILossPolicy.Params({
                totalDebtUSD: collateralDebtData.totalDebtUSD,
                twvUSD: collateralDebtData.twvUSD,
                extraData: lossPolicyData
            });
            if (!ILossPolicy(lossPolicy).isLiquidatableWithLoss(creditAccount, msg.sender, params)) {
                revert CreditAccountNotLiquidatableWithLossException(); // U:[FA-17]
            }
            maxDebtPerBlockMultiplier = 0; // U:[FA-17]
        }

        BalanceWithMask[] memory initialBalances = BalancesLogic.storeBalances({
            creditAccount: creditAccount,
            tokensMask: collateralDebtData.enabledTokensMask.disable(UNDERLYING_TOKEN_MASK),
            getTokenByMaskFn: _getTokenByMask
        });

        _multicall(creditAccount, calls, collateralDebtData.enabledTokensMask, flags); // U:[FA-14]

        address failedToken = BalancesLogic.compareBalances({
            creditAccount: creditAccount,
            tokensMask: collateralDebtData.enabledTokensMask.disable(UNDERLYING_TOKEN_MASK),
            balances: initialBalances,
            comparison: Comparison.LESS_OR_EQUAL
        });
        if (failedToken != address(0)) revert RemainingTokenBalanceIncreasedException(failedToken); // U:[FA-14A]

        collateralDebtData.enabledTokensMask = collateralDebtData.enabledTokensMask.enable(UNDERLYING_TOKEN_MASK); // U:[FA-14]

        (uint256 remainingFunds,) = ICreditManagerV3(creditManager).liquidateCreditAccount({
            creditAccount: creditAccount,
            collateralDebtData: collateralDebtData,
            to: to,
            isExpired: !isUnhealthy
        }); // U:[FA-14]

        emit LiquidateCreditAccount(creditAccount, msg.sender, to, remainingFunds); // U:[FA-14]
    }

    /// @dev Deprecated method that preserves liquidation signature from v3.0.x by using empty loss policy data
    function liquidateCreditAccount(address creditAccount, address to, MultiCall[] calldata calls) external override {
        liquidateCreditAccount(creditAccount, to, calls, "");
    }

    /// @notice Partially liquidates credit account's debt in exchange for discounted collateral
    ///         - Updates price feeds before running all computations
    ///         - Evaluates account's collateral and debt to determine whether liquidated account is unhealthy or expired
    ///         - Transfers underlying from the caller (requires approval to the credit manager) and uses it to repay
    ///           account's debt and pay fees to the treasury
    ///         - Transfers chosen collateral token at discounted oracle price to the liquidator (liquidation discount
    ///         and fee are the same as for full liquidations, though fees are not deposited into the pool)
    ///         - Runs the collateral check
    /// @param creditAccount Credit account to liquidate
    /// @param token Collateral token to seize
    /// @param repaidAmount Amount of underlying token to repay
    /// @param minSeizedAmount Minimum amount of `token` to seize from `creditAccount`
    /// @param to Account to withdraw seized `token` to
    /// @param priceUpdates On-demand price feed updates to apply before calculations, see `PriceUpdate` for details
    /// @return seizedAmount Amount of `token` seized
    /// @dev If facade is paused, reverts if caller is not an approved emergency liquidator
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager
    /// @dev Reverts if account has no debt or is neither unhealthy nor expired
    /// @dev Reverts if `token` is underlying or if `token` is a phantom token and its `depositedToken` is underlying
    /// @dev If `token` is a phantom token, it's withdrawn first, and its `depositedToken` is then sent to the liquidator.
    ///      Both `seizedAmount` and `minSeizedAmount` refer to `depositedToken` in this case.
    /// @dev Like in full liquidations, liquidator can seize non-enabled tokens from the credit account, although here
    ///      they are actually used to repay debt. Unclaimed rewards are safe since adapter calls are not allowed.
    function partiallyLiquidateCreditAccount(
        address creditAccount,
        address token,
        uint256 repaidAmount,
        uint256 minSeizedAmount,
        address to,
        PriceUpdate[] calldata priceUpdates
    )
        external
        override
        whenNotPausedOrEmergency // U:[FA-2,12]
        nonReentrant // U:[FA-4]
        returns (uint256 seizedAmount)
    {
        if (priceUpdates.length != 0) _updatePrices(priceUpdates);

        (CollateralDebtData memory cdd, bool isUnhealthy) = _revertIfNotLiquidatable(creditAccount); // U:[FA-13,16]

        uint256 balanceBefore = IERC20(underlying).safeBalanceOf(creditAccount);
        _addCollateral(creditAccount, underlying, repaidAmount); // U:[FA-16]
        repaidAmount = IERC20(underlying).safeBalanceOf(creditAccount) - balanceBefore;

        uint256 feeAmount;
        (repaidAmount, feeAmount, seizedAmount) = _calcPartialLiquidationPayments(repaidAmount, token, !isUnhealthy); // U:[FA-15]

        uint256 flags;
        (token, seizedAmount, flags) = _tryWithdrawPhantomToken(creditAccount, token, seizedAmount, 0); // U:[FA-16A]
        if (token == underlying) revert UnderlyingIsNotLiquidatableException(); // U:[FA-16,16A]
        if (seizedAmount < minSeizedAmount) revert SeizedLessThanRequiredException(seizedAmount); // U:[FA-16,16A]
        if (flags & EXTERNAL_CONTRACT_WAS_CALLED_FLAG != 0) _unsetActiveCreditAccount(); // U:[FA-16A]

        _manageDebt(creditAccount, repaidAmount, cdd.enabledTokensMask, ManageDebtAction.DECREASE_DEBT); // U:[FA-16]
        _withdrawCollateral(creditAccount, underlying, feeAmount, treasury); // U:[FA-16]
        _withdrawCollateral(creditAccount, token, seizedAmount, to); // U:[FA-16]
        _fullCollateralCheck({
            creditAccount: creditAccount,
            enabledTokensMask: cdd.enabledTokensMask,
            collateralHints: new uint256[](0),
            minHealthFactor: PERCENTAGE_FACTOR,
            useSafePrices: false
        }); // U:[FA-16]

        emit PartiallyLiquidateCreditAccount(creditAccount, token, msg.sender, repaidAmount, seizedAmount, feeAmount); // U:[FA-16]
    }

    /// @notice Executes a batch of calls allowing user to manage their credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - Performs a multicall (all calls are allowed)
    ///         - Runs the collateral check
    /// @param creditAccount Account to perform the calls on
    /// @param calls List of calls to perform
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager by caller
    /// @dev Reverts if credit facade is paused or expired
    function multicall(address creditAccount, MultiCall[] calldata calls)
        external
        payable
        override
        creditAccountOwnerOnly(creditAccount) // U:[FA-5]
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
    {
        _multicall(creditAccount, calls, _enabledTokensMaskOf(creditAccount), ALL_PERMISSIONS); // U:[FA-18]
    }

    /// @notice Executes a batch of calls allowing bot to manage a credit account
    ///         - Performs a multicall (allowed calls are determined by permissions given by account's owner)
    ///         - Runs the collateral check
    /// @param creditAccount Account to perform the calls on
    /// @param calls List of calls to perform
    /// @dev Reverts if credit facade is paused or expired
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager
    /// @dev Reverts if calling bot is forbidden or has no permissions to manage `creditAccount`
    function botMulticall(address creditAccount, MultiCall[] calldata calls)
        external
        override
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
    {
        _getBorrowerOrRevert(creditAccount); // U:[FA-5]

        (uint256 botPermissions, bool forbidden) =
            IBotListV3(botList).getBotStatus({bot: msg.sender, creditAccount: creditAccount});

        if (forbidden || botPermissions == 0 || _flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG == 0) {
            revert NotApprovedBotException(msg.sender); // U:[FA-19]
        }

        _multicall(creditAccount, calls, _enabledTokensMaskOf(creditAccount), botPermissions); // U:[FA-19, 20]
    }

    // --------- //
    // MULTICALL //
    // --------- //

    /// @dev Multicall implementation
    /// @param creditAccount Account to perform actions with
    /// @param calls Array of `(target, callData)` tuples representing a sequence of calls to perform
    ///        - if `target` is this contract's address, `callData` must be an ABI-encoded calldata of a method
    ///          from `ICreditFacadeV3Multicall`, which is dispatched and handled appropriately
    ///        - otherwise, `target` must be an allowed adapter, which is called with `callData`, and returns a flag
    ///          that indicates whether safety measures should apply (which include safe pricing in collateral check
    ///          and a check that there are no enabled forbidden tokens by the end of the multicall)
    /// @param enabledTokensMask Bitmask of account's enabled collateral tokens before the multicall
    /// @param flags Flags that dictate multicall behaviour, including what methods are allowed to be called and
    ///        whether to execute collateral check after calls
    function _multicall(address creditAccount, MultiCall[] calldata calls, uint256 enabledTokensMask, uint256 flags)
        internal
    {
        // impossible value of forbidden tokens mask to indicate emptiness, see `_forbiddenTokensMaskRoE`
        uint256 forbiddenTokensMask = type(uint256).max;

        FullCheckParams memory fullCheckParams;
        BalanceWithMask[] memory forbiddenBalances;
        if (flags & SKIP_COLLATERAL_CHECK_FLAG == 0) {
            fullCheckParams.minHealthFactor = PERCENTAGE_FACTOR;
            forbiddenTokensMask = _forbiddenTokensMaskRoE(forbiddenTokensMask);
            forbiddenBalances = BalancesLogic.storeBalances({
                creditAccount: creditAccount,
                tokensMask: forbiddenTokensMask & enabledTokensMask,
                getTokenByMaskFn: _getTokenByMask
            });
        }

        emit StartMultiCall({creditAccount: creditAccount, caller: msg.sender}); // U:[FA-18]

        Balance[] memory expectedBalances;
        unchecked {
            uint256 len = calls.length;
            for (uint256 i; i < len; ++i) {
                MultiCall calldata mcall = calls[i];

                // credit facade calls
                if (mcall.target == address(this)) {
                    bytes4 method = bytes4(mcall.callData);

                    // onDemandPriceUpdates
                    if (method == ICreditFacadeV3Multicall.onDemandPriceUpdates.selector) {
                        if (i != 0) revert UnknownMethodException(method); // U:[FA-22]
                        if (flags & SKIP_PRICE_UPDATES_CALL_FLAG == 0) _onDemandPriceUpdates(mcall.callData[4:]); // U:[FA-25]
                    }
                    // storeExpectedBalances
                    else if (method == ICreditFacadeV3Multicall.storeExpectedBalances.selector) {
                        if (expectedBalances.length != 0) revert ExpectedBalancesAlreadySetException(); // U:[FA-23]
                        BalanceDelta[] memory balanceDeltas = abi.decode(mcall.callData[4:], (BalanceDelta[])); // U:[FA-23]
                        expectedBalances = BalancesLogic.storeBalances(creditAccount, balanceDeltas); // U:[FA-23]
                    }
                    // compareBalances
                    else if (method == ICreditFacadeV3Multicall.compareBalances.selector) {
                        if (expectedBalances.length == 0) revert ExpectedBalancesNotSetException(); // U:[FA-23]
                        address failedToken =
                            BalancesLogic.compareBalances(creditAccount, expectedBalances, Comparison.GREATER_OR_EQUAL);
                        if (failedToken != address(0)) revert BalanceLessThanExpectedException(failedToken); // U:[FA-23]
                        expectedBalances = new Balance[](0); // U:[FA-23]
                    }
                    // addCollateral
                    else if (method == ICreditFacadeV3Multicall.addCollateral.selector) {
                        _revertIfNoPermission(flags, ADD_COLLATERAL_PERMISSION); // U:[FA-21]
                        _addCollateral(creditAccount, mcall.callData[4:]); // U:[FA-26A]
                    }
                    // addCollateralWithPermit
                    else if (method == ICreditFacadeV3Multicall.addCollateralWithPermit.selector) {
                        _revertIfNoPermission(flags, ADD_COLLATERAL_PERMISSION); // U:[FA-21]
                        _addCollateralWithPermit(creditAccount, mcall.callData[4:]); // U:[FA-26B]
                    }
                    // updateQuota
                    else if (method == ICreditFacadeV3Multicall.updateQuota.selector) {
                        _revertIfNoPermission(flags, UPDATE_QUOTA_PERMISSION); // U:[FA-21]
                        (enabledTokensMask, forbiddenTokensMask) =
                            _updateQuota(creditAccount, mcall.callData[4:], enabledTokensMask, forbiddenTokensMask); // U:[FA-34]
                    }
                    // withdrawCollateral
                    else if (method == ICreditFacadeV3Multicall.withdrawCollateral.selector) {
                        _revertIfNoPermission(flags, WITHDRAW_COLLATERAL_PERMISSION); // U:[FA-21]
                        flags = _withdrawCollateral(creditAccount, mcall.callData[4:], flags); // U:[FA-36]
                    }
                    // increaseDebt
                    else if (method == ICreditFacadeV3Multicall.increaseDebt.selector) {
                        _revertIfNoPermission(flags, INCREASE_DEBT_PERMISSION); // U:[FA-21]
                        uint256 amount = abi.decode(mcall.callData[4:], (uint256)); // U:[FA-27]
                        _manageDebt(creditAccount, amount, enabledTokensMask, ManageDebtAction.INCREASE_DEBT); // U:[FA-27]
                        flags |= REVERT_ON_FORBIDDEN_TOKENS_FLAG; // U:[FA-45]
                    }
                    // decreaseDebt
                    else if (method == ICreditFacadeV3Multicall.decreaseDebt.selector) {
                        _revertIfNoPermission(flags, DECREASE_DEBT_PERMISSION); // U:[FA-21]
                        uint256 amount = abi.decode(mcall.callData[4:], (uint256)); // U:[FA-31]
                        _manageDebt(creditAccount, amount, enabledTokensMask, ManageDebtAction.DECREASE_DEBT); // U:[FA-31]
                    }
                    // setBotPermissions
                    else if (method == ICreditFacadeV3Multicall.setBotPermissions.selector) {
                        _revertIfNoPermission(flags, SET_BOT_PERMISSIONS_PERMISSION); // U:[FA-21]
                        _setBotPermissions(creditAccount, mcall.callData[4:]); // U:[FA-37]
                    }
                    // setFullCheckParams
                    else if (method == ICreditFacadeV3Multicall.setFullCheckParams.selector) {
                        if (flags & SKIP_COLLATERAL_CHECK_FLAG != 0) revert UnknownMethodException(method); // U:[FA-22]
                        _setFullCheckParams(fullCheckParams, mcall.callData[4:]); // U:[FA-24]
                    }
                    // unknown method
                    else {
                        revert UnknownMethodException(method); // U:[FA-22]
                    }
                }
                // adapter calls
                else {
                    _revertIfNoPermission(flags, EXTERNAL_CALLS_PERMISSION); // U:[FA-21]
                    flags = _externalCall({
                        creditAccount: creditAccount,
                        target: ICreditManagerV3(creditManager).adapterToContract(mcall.target),
                        adapter: mcall.target,
                        callData: mcall.callData,
                        flags: flags
                    }); // U:[FA-38]
                }
            }
        }
        if (expectedBalances.length != 0) {
            address failedToken =
                BalancesLogic.compareBalances(creditAccount, expectedBalances, Comparison.GREATER_OR_EQUAL);
            if (failedToken != address(0)) revert BalanceLessThanExpectedException(failedToken); // U:[FA-23]
        }

        if (flags & EXTERNAL_CONTRACT_WAS_CALLED_FLAG != 0) _unsetActiveCreditAccount(); // U:[FA-38]

        emit FinishMultiCall(); // U:[FA-18]
        if (flags & SKIP_COLLATERAL_CHECK_FLAG != 0) return;

        // `forbiddenTokensMask` is non-empty at this point, so no need for `_forbiddenTokensMaskRoE`
        uint256 enabledForbiddenTokensMask = enabledTokensMask & forbiddenTokensMask;
        if (enabledForbiddenTokensMask != 0) {
            if (flags & REVERT_ON_FORBIDDEN_TOKENS_FLAG != 0) {
                revert ForbiddenTokensException(enabledForbiddenTokensMask);
            } // U:[FA-45]

            address failedToken = BalancesLogic.compareBalances({
                creditAccount: creditAccount,
                tokensMask: enabledForbiddenTokensMask,
                balances: forbiddenBalances,
                comparison: Comparison.LESS_OR_EQUAL
            });
            if (failedToken != address(0)) revert ForbiddenTokenBalanceIncreasedException(failedToken); // U:[FA-45]

            flags |= USE_SAFE_PRICES_FLAG; // U:[FA-45]
        }

        _fullCollateralCheck({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMask,
            collateralHints: fullCheckParams.collateralHints,
            minHealthFactor: fullCheckParams.minHealthFactor,
            useSafePrices: flags & USE_SAFE_PRICES_FLAG != 0
        }); // U:[FA-24,34,45]
    }

    /// @dev `ICreditFacadeV3Multicall.setFullCheckParams` implementation
    function _setFullCheckParams(FullCheckParams memory fullCheckParams, bytes calldata callData) internal pure {
        (fullCheckParams.collateralHints, fullCheckParams.minHealthFactor) = abi.decode(callData, (uint256[], uint16)); // U:[FA-24]

        if (fullCheckParams.minHealthFactor < PERCENTAGE_FACTOR) {
            revert CustomHealthFactorTooLowException(); // U:[FA-24]
        }

        uint256 hintsLen = fullCheckParams.collateralHints.length;
        unchecked {
            for (uint256 j; j < hintsLen; ++j) {
                uint256 mask = fullCheckParams.collateralHints[j];
                if (mask <= UNDERLYING_TOKEN_MASK || mask & mask - 1 != 0) {
                    revert InvalidCollateralHintException(mask); // U:[FA-24]
                }
            }
        }
    }

    /// @dev `ICreditFacadeV3Multicall.onDemandPriceUpdates` implementation
    function _onDemandPriceUpdates(bytes calldata callData) internal {
        PriceUpdate[] memory updates = abi.decode(callData, (PriceUpdate[])); // U:[FA-25]

        _updatePrices(updates); // U:[FA-25]
    }

    /// @dev `ICreditFacadeV3Multicall.addCollateral` implementation
    function _addCollateral(address creditAccount, bytes calldata callData) internal {
        (address token, uint256 amount) = abi.decode(callData, (address, uint256)); // U:[FA-26A]
        if (amount == 0) revert AmountCantBeZeroException(); // U:[FA-26A]

        _addCollateral(creditAccount, token, amount); // U:[FA-26A]
    }

    /// @dev `ICreditFacadeV3Multicall.addCollateralWithPermit` implementation
    function _addCollateralWithPermit(address creditAccount, bytes calldata callData) internal {
        (address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) =
            abi.decode(callData, (address, uint256, uint256, uint8, bytes32, bytes32)); // U:[FA-26B]
        if (amount == 0) revert AmountCantBeZeroException(); // U:[FA-26B]

        // `token` is only validated later in `addCollateral`, but to benefit off of it the attacker would have to make
        // it recognizable as collateral in the credit manager, which requires gaining configurator access rights
        try IERC20Permit(token).permit(msg.sender, creditManager, amount, deadline, v, r, s) {} catch {} // U:[FA-26B]

        _addCollateral(creditAccount, token, amount); // U:[FA-26B]
    }

    /// @dev `ICreditFacadeV3Multicall.{increase|decrease}Debt` implementation
    function _manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        internal
    {
        if (amount == 0) revert AmountCantBeZeroException(); // U:[FA-27,31]
        if (action == ManageDebtAction.INCREASE_DEBT) {
            _revertIfOutOfDebtPerBlockLimit(amount); // U:[FA-28]
        }

        (uint256 newDebt,,) =
            ICreditManagerV3(creditManager).manageDebt(creditAccount, amount, enabledTokensMask, action); // U:[FA-27,31]

        _revertIfOutOfDebtLimits(newDebt, action); // U:[FA-28,32,33]
    }

    /// @dev `ICreditFacadeV3Multicall.updateQuota` implementation
    function _updateQuota(
        address creditAccount,
        bytes calldata callData,
        uint256 enabledTokensMask,
        uint256 forbiddenTokensMask
    ) internal returns (uint256, uint256) {
        (address token, int96 quotaChange, uint96 minQuota) = abi.decode(callData, (address, int96, uint96)); // U:[FA-34]
        if (token == underlying) revert TokenIsNotQuotedException(); // U:[FA-34]
        if (quotaChange == 0) revert AmountCantBeZeroException(); // U:[FA-34]

        if (quotaChange > 0) {
            forbiddenTokensMask = _forbiddenTokensMaskRoE(forbiddenTokensMask);
            if (forbiddenTokensMask != 0 && _getTokenMaskOrRevert(token) & forbiddenTokensMask != 0) {
                revert ForbiddenTokenQuotaIncreasedException(token); // U:[FA-45]
            }
        }

        (uint256 tokensToEnable, uint256 tokensToDisable) = ICreditManagerV3(creditManager).updateQuota({
            creditAccount: creditAccount,
            token: token,
            quotaChange: quotaChange != type(int96).min
                ? quotaChange / int96(uint96(PERCENTAGE_FACTOR)) * int96(uint96(PERCENTAGE_FACTOR))
                : quotaChange,
            minQuota: minQuota,
            maxQuota: uint96(Math.min(type(uint96).max, maxQuotaMultiplier * debtLimits.maxDebt))
        }); // U:[FA-34]
        enabledTokensMask = enabledTokensMask.enableDisable(tokensToEnable, tokensToDisable); // U:[FA-34]
        return (enabledTokensMask, forbiddenTokensMask);
    }

    /// @dev `ICreditFacadeV3Multicall.withdrawCollateral` implementation
    function _withdrawCollateral(address creditAccount, bytes calldata callData, uint256 flags)
        internal
        returns (uint256)
    {
        (address token, uint256 amount, address to) = abi.decode(callData, (address, uint256, address)); // U:[FA-36]

        if (amount == type(uint256).max) {
            amount = IERC20(token).safeBalanceOf(creditAccount);
            if (amount >= 1) {
                unchecked {
                    --amount;
                }
            }
        }
        if (amount == 0) revert AmountCantBeZeroException(); // U:[FA-36]

        (token, amount, flags) = _tryWithdrawPhantomToken(creditAccount, token, amount, flags); // U:[FA-36A]
        _withdrawCollateral(creditAccount, token, amount, to); // U:[FA-36]
        return flags | REVERT_ON_FORBIDDEN_TOKENS_FLAG | USE_SAFE_PRICES_FLAG; // U:[FA-36,45]
    }

    /// @dev `ICreditFacadeV3Multicall.setBotPermissions` implementation
    function _setBotPermissions(address creditAccount, bytes calldata callData) internal {
        (address bot, uint192 permissions) = abi.decode(callData, (address, uint192));

        uint192 allowedPermissions = ALL_PERMISSIONS & ~SET_BOT_PERMISSIONS_PERMISSION;
        uint192 unexpectedPermissions = permissions & ~allowedPermissions;
        if (unexpectedPermissions != 0) revert UnexpectedPermissionsException(unexpectedPermissions); // U:[FA-37]

        uint256 remainingBots =
            IBotListV3(botList).setBotPermissions({bot: bot, creditAccount: creditAccount, permissions: permissions}); // U:[FA-37]

        if (remainingBots == 0) {
            _setFlagFor({creditAccount: creditAccount, flag: BOT_PERMISSIONS_SET_FLAG, value: false}); // U:[FA-37]
        } else if (_flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG == 0) {
            _setFlagFor({creditAccount: creditAccount, flag: BOT_PERMISSIONS_SET_FLAG, value: true}); // U:[FA-37]
        }
    }

    /// @dev Phantom token withdrawal implementation
    function _tryWithdrawPhantomToken(address creditAccount, address token, uint256 amount, uint256 flags)
        internal
        returns (address, uint256, uint256)
    {
        // NOTE: Some external tokens without `getPhantomTokenInfo` may have a fallback function that changes state,
        // which can cause a `THROW` that burns all gas, or does not change state and instead returns empty data.
        // To handle these cases, we use a special call construction with a strict gas limit.
        (bool success, bytes memory returnData) = OptionalCall.staticCallOptionalSafe({
            target: token,
            data: abi.encodeWithSelector(IPhantomToken.getPhantomTokenInfo.selector),
            gasAllowance: 30_000
        });
        if (!success) return (token, amount, flags); // U:[FA-36B]

        (address target, address depositedToken) = abi.decode(returnData, (address, address));

        // ensure that `token` is recognized by the credit manager
        _getTokenMaskOrRevert(token); // U:[FA-36A]

        uint256 balanceBefore = IERC20(depositedToken).safeBalanceOf(creditAccount);
        flags = _externalCall({
            creditAccount: creditAccount,
            target: target,
            adapter: ICreditManagerV3(creditManager).contractToAdapter(target),
            callData: abi.encodeCall(IPhantomTokenWithdrawer.withdrawPhantomToken, (token, amount)),
            flags: flags
        }); // U:[FA-36A]

        emit WithdrawPhantomToken(creditAccount, token, amount); // U:[FA-36A]
        return (depositedToken, IERC20(depositedToken).safeBalanceOf(creditAccount) - balanceBefore, flags);
    }

    /// @dev Adapter call implementation
    function _externalCall(address creditAccount, address target, address adapter, bytes memory callData, uint256 flags)
        internal
        returns (uint256)
    {
        if (adapter == address(0) || target == address(0)) revert TargetContractNotAllowedException(); // U:[FA-38]

        if (flags & EXTERNAL_CONTRACT_WAS_CALLED_FLAG == 0) {
            _setActiveCreditAccount(creditAccount); // U:[FA-38]
            flags |= EXTERNAL_CONTRACT_WAS_CALLED_FLAG; // U:[FA-38]
        }

        bool useSafePrices = abi.decode(adapter.functionCall(callData), (bool)); // U:[FA-38]
        if (useSafePrices) flags |= REVERT_ON_FORBIDDEN_TOKENS_FLAG | USE_SAFE_PRICES_FLAG; // U:[FA-38,45]

        emit Execute({creditAccount: creditAccount, targetContract: target}); // U:[FA-38]
        return flags;
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Sets the credit facade expiration timestamp
    /// @param newExpirationDate New expiration timestamp
    /// @dev Reverts if caller is not credit configurator
    /// @dev Reverts if credit facade is not expirable
    function setExpirationDate(uint40 newExpirationDate)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        if (!expirable) {
            revert NotAllowedWhenNotExpirableException(); // U:[FA-48]
        }
        expirationDate = newExpirationDate; // U:[FA-48]
    }

    /// @notice Sets debt limits per credit account
    /// @param newMinDebt New minimum debt amount per credit account
    /// @param newMaxDebt New maximum debt amount per credit account
    /// @param newMaxDebtPerBlockMultiplier New max debt per block multiplier, `type(uint8).max` to disable the check
    /// @dev Reverts if caller is not credit configurator
    /// @dev Reverts if `maxDebt * maxDebtPerBlockMultiplier` doesn't fit into `uint128`
    /// @dev Prevents further borrowing in the current block unless this check is disabled
    function setDebtLimits(uint128 newMinDebt, uint128 newMaxDebt, uint8 newMaxDebtPerBlockMultiplier)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        if ((uint256(newMaxDebtPerBlockMultiplier) * newMaxDebt) > type(uint128).max) {
            revert IncorrectParameterException(); // U:[FA-49]
        }

        debtLimits.minDebt = newMinDebt; // U:[FA-49]
        debtLimits.maxDebt = newMaxDebt; // U:[FA-49]
        maxDebtPerBlockMultiplier = newMaxDebtPerBlockMultiplier; // U:[FA-49]
        lastBlockBorrowed = uint64(block.number); // U:[FA-49]
        totalBorrowedInBlock = type(uint128).max; // U:[FA-49]
    }

    /// @notice Sets the new loss policy
    /// @param newLossPolicy New loss policy
    /// @dev Reverts if caller is not credit configurator
    function setLossPolicy(address newLossPolicy)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        lossPolicy = newLossPolicy; // U:[FA-51]
    }

    /// @notice Changes token's forbidden status
    /// @param token Token to change the status for
    /// @param allowance Status to set
    /// @dev Reverts if caller is not credit configurator
    function setTokenAllowance(address token, AllowanceAction allowance)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        uint256 tokenMask = _getTokenMaskOrRevert(token); // U:[FA-52]

        forbiddenTokenMask = (allowance == AllowanceAction.ALLOW)
            ? forbiddenTokenMask.disable(tokenMask)
            : forbiddenTokenMask.enable(tokenMask); // U:[FA-52]
    }

    /// @notice Pauses contract, can only be called by an account with pausable admin role
    /// @dev Pause blocks all user entrypoints to the contract.
    ///      Liquidations remain open only to emergency liquidators.
    /// @dev Reverts if contract is already paused
    function pause() external override pausableAdminsOnly {
        _pause();
    }

    /// @notice Unpauses contract, can only be called by an account with unpausable admin role
    /// @dev Reverts if contract is already unpaused
    function unpause() external override unpausableAdminsOnly {
        _unpause();
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Ensures that amount borrowed by credit manager in the current block does not exceed the limit
    /// @dev Skipped when `maxDebtPerBlockMultiplier == type(uint8).max`
    function _revertIfOutOfDebtPerBlockLimit(uint256 amount) internal {
        uint8 _maxDebtPerBlockMultiplier = maxDebtPerBlockMultiplier; // U:[FA-43]
        if (_maxDebtPerBlockMultiplier == type(uint8).max) return; // U:[FA-43]

        uint256 newDebtInCurrentBlock;
        if (lastBlockBorrowed == block.number) {
            newDebtInCurrentBlock = amount + totalBorrowedInBlock; // U:[FA-43]
        } else {
            newDebtInCurrentBlock = amount;
            lastBlockBorrowed = uint64(block.number); // U:[FA-43]
        }

        if (newDebtInCurrentBlock > uint256(_maxDebtPerBlockMultiplier) * debtLimits.maxDebt) {
            revert BorrowedBlockLimitException(); // U:[FA-43]
        }

        // the conversion is safe because of the check in `setDebtLimits`
        totalBorrowedInBlock = uint128(newDebtInCurrentBlock); // U:[FA-43]
    }

    /// @dev Ensures that account's debt principal takes allowed values:
    ///      - for borrowing, new debt must be within allowed limits
    ///      - for repayment, new debt must be above allowed minimum or zero
    function _revertIfOutOfDebtLimits(uint256 debt, ManageDebtAction action) internal view {
        if (debt == 0 && action == ManageDebtAction.DECREASE_DEBT) return;
        uint256 minDebt;
        uint256 maxDebt;

        // minDebt = debtLimits.minDebt;
        // maxDebt = debtLimits.maxDebt;
        assembly {
            let data := sload(debtLimits.slot)
            maxDebt := shr(128, data)
            minDebt := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        if (debt < minDebt || debt > maxDebt && action == ManageDebtAction.INCREASE_DEBT) {
            revert BorrowAmountOutOfLimitsException(); // U:[FA-44]
        }
    }

    /// @dev Ensures that `flags` has the `permission` bit enabled
    function _revertIfNoPermission(uint256 flags, uint256 permission) internal pure {
        if (flags & permission == 0) {
            revert NoPermissionException(permission); // U:[FA-39]
        }
    }

    /// @dev Ensures that `creditAccount` is liquidatable
    function _revertIfNotLiquidatable(address creditAccount)
        internal
        view
        returns (CollateralDebtData memory cdd, bool isUnhealthy)
    {
        cdd = ICreditManagerV3(creditManager).calcDebtAndCollateral(creditAccount, CollateralCalcTask.DEBT_COLLATERAL);
        isUnhealthy = cdd.twvUSD < cdd.totalDebtUSD; // U:[FA-13]
        if (cdd.debt == 0 || !isUnhealthy && !_isExpired()) revert CreditAccountNotLiquidatableException(); // U:[FA-13]
    }

    /// @dev Whether account's total value (minus liquidator's premium) is below its outstanding debt
    function _hasBadDebt(CollateralDebtData memory cdd) internal view returns (bool) {
        (,, uint16 liquidationDiscount,,) = ICreditManagerV3(creditManager).fees();
        // NOTE: this formula does not account for transfer fees for simplicity, so there might be edge
        // cases when liquidation bypasses the loss policy, however loss size is bounded by the fee
        return cdd.totalValue * liquidationDiscount < (cdd.debt + cdd.accruedInterest) * PERCENTAGE_FACTOR;
    }

    /// @dev Calculates and returns partial liquidation payment amounts:
    ///      - amount of underlying that should go towards repaying debt
    ///      - amount of underlying that should go towards liquidation fees
    ///      - amount of collateral that should be sent to the liquidator
    function _calcPartialLiquidationPayments(uint256 amount, address token, bool isExpired)
        internal
        view
        returns (uint256 repaidAmount, uint256 feeAmount, uint256 seizedAmount)
    {
        address priceOracle = ICreditManagerV3(creditManager).priceOracle();
        (
            ,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        ) = ICreditManagerV3(creditManager).fees();
        seizedAmount = IPriceOracleV3(priceOracle).convert(amount, underlying, token) * PERCENTAGE_FACTOR
            / (isExpired ? liquidationDiscountExpired : liquidationDiscount); // U:[FA-15]
        feeAmount = amount * (isExpired ? feeLiquidationExpired : feeLiquidation) / PERCENTAGE_FACTOR; // U:[FA-15]
        unchecked {
            // unchecked subtraction is safe because credit configurator ensures that liquidation fee is below 100%
            repaidAmount = amount - feeAmount; // U:[FA-15]
        }
    }

    /// @dev Read-on-empty function to read forbidden tokens mask at most once if it's needed, returns its argument
    ///      if it's not empty or `forbiddenTokenMask` otherwise
    /// @dev Non-empty forbidden tokens mask always has its LSB set to 0 since underlying can't be forbidden,
    ///      so we can use `type(uint256).max` as indicator that value is not yet initialized
    function _forbiddenTokensMaskRoE(uint256 forbiddenTokensMaskOrEmpty) internal view returns (uint256) {
        return forbiddenTokensMaskOrEmpty == type(uint256).max ? forbiddenTokenMask : forbiddenTokensMaskOrEmpty;
    }

    /// @dev Wraps any ETH sent in the function call and sends it back to `msg.sender`
    function _wrapETH() internal {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}(); // U:[FA-7]
            IERC20(weth).safeTransfer(msg.sender, msg.value); // U:[FA-7]
        }
    }

    /// @dev Whether credit facade has expired (`false` if it's not expirable or expiration timestamp is not set)
    function _isExpired() internal view returns (bool) {
        if (!expirable) return false; // U:[FA-46]
        uint40 _expirationDate = expirationDate;
        return _expirationDate != 0 && block.timestamp >= _expirationDate; // U:[FA-46]
    }

    /// @dev Internal wrapper for `priceFeedStore.updatePrices` call to reduce contract size
    function _updatePrices(PriceUpdate[] memory updates) internal {
        IPriceFeedStore(priceFeedStore).updatePrices(updates);
    }

    /// @dev Internal wrapper for `creditManager.addCollateral` call to reduce contract size
    function _addCollateral(address creditAccount, address token, uint256 amount) internal {
        ICreditManagerV3(creditManager).addCollateral({
            payer: msg.sender,
            creditAccount: creditAccount,
            token: token,
            amount: amount
        });
        emit AddCollateral(creditAccount, token, amount);
    }

    /// @dev Internal wrapper for `creditManager.withdrawCollateral` call to reduce contract size
    function _withdrawCollateral(address creditAccount, address token, uint256 amount, address to) internal {
        ICreditManagerV3(creditManager).withdrawCollateral({
            creditAccount: creditAccount,
            token: token,
            amount: amount,
            to: to
        });
        emit WithdrawCollateral(creditAccount, token, amount, to);
    }

    /// @dev Internal wrapper for `creditManager.fullCollateralCheck` call to reduce contract size
    function _fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] memory collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    ) internal {
        // older credit managers do not enable underlying token upon opening an account so it is done here
        ICreditManagerV3(creditManager).fullCollateralCheck({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMask.enable(UNDERLYING_TOKEN_MASK),
            collateralHints: collateralHints,
            minHealthFactor: minHealthFactor,
            useSafePrices: useSafePrices
        });
    }

    /// @dev Internal wrapper for `creditManager.getBorrowerOrRevert` call to reduce contract size
    function _getBorrowerOrRevert(address creditAccount) internal view returns (address) {
        return ICreditManagerV3(creditManager).getBorrowerOrRevert({creditAccount: creditAccount});
    }

    /// @dev Internal wrapper for `creditManager.getTokenMaskOrRevert` call to reduce contract size
    function _getTokenMaskOrRevert(address token) internal view returns (uint256) {
        return ICreditManagerV3(creditManager).getTokenMaskOrRevert(token);
    }

    /// @dev Internal wrapper for `creditManager.getTokenByMask` call to reduce contract size
    function _getTokenByMask(uint256 mask) internal view returns (address) {
        return ICreditManagerV3(creditManager).getTokenByMask(mask);
    }

    /// @dev Internal wrapper for `creditManager.flagsOf` call to reduce contract size
    function _flagsOf(address creditAccount) internal view returns (uint16) {
        return ICreditManagerV3(creditManager).flagsOf(creditAccount);
    }

    /// @dev Internal wrapper for `creditManager.setFlagFor` call to reduce contract size
    function _setFlagFor(address creditAccount, uint16 flag, bool value) internal {
        ICreditManagerV3(creditManager).setFlagFor(creditAccount, flag, value);
    }

    /// @dev Internal wrapper for `creditManager.setActiveCreditAccount` call to reduce contract size
    function _setActiveCreditAccount(address creditAccount) internal {
        ICreditManagerV3(creditManager).setActiveCreditAccount(creditAccount);
    }

    /// @dev Same as above but unsets active credit account
    function _unsetActiveCreditAccount() internal {
        _setActiveCreditAccount(INACTIVE_CREDIT_ACCOUNT_ADDRESS);
    }

    /// @dev Internal wrapper for `creditManager.enabledTokensMaskOf` call to reduce contract size
    function _enabledTokensMaskOf(address creditAccount) internal view returns (uint256) {
        return ICreditManagerV3(creditManager).enabledTokensMaskOf(creditAccount);
    }

    /// @dev Reverts if `msg.sender` is not credit configurator
    function _checkCreditConfigurator() internal view {
        if (msg.sender != ICreditManagerV3(creditManager).creditConfigurator()) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Reverts if `msg.sender` is not `creditAccount` owner
    function _checkCreditAccountOwner(address creditAccount) internal view {
        if (msg.sender != _getBorrowerOrRevert(creditAccount)) {
            revert CallerNotCreditAccountOwnerException();
        }
    }

    /// @dev Reverts if credit facade is expired
    function _checkExpired() internal view {
        if (_isExpired()) {
            revert NotAllowedAfterExpirationException();
        }
    }
}

// ===== lib/@1inch/solidity-utils/contracts/libraries/SafeERC20.sol =====
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../interfaces/IPermit2.sol";
import "../interfaces/IWETH.sol";
import "../libraries/RevertReasonForwarder.sol";

/**
 * @title Implements efficient safe methods for ERC20 interface.
 * @notice Compared to the standard ERC20, this implementation offers several enhancements:
 * 1. more gas-efficient, providing significant savings in transaction costs.
 * 2. support for different permit implementations
 * 3. forceApprove functionality
 * 4. support for WETH deposit and withdraw
 */
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();
    error Permit2TransferAmountTooHigh();

    // Uniswap Permit2 address
    address private constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes4 private constant _PERMIT_LENGTH_ERROR = 0x68275857;  // SafePermitBadLength.selector
    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    /**
     * @notice Fetches the balance of a specific ERC20 token held by an account.
     * Consumes less gas then regular `ERC20.balanceOf`.
     * @param token The IERC20 token contract for which the balance will be fetched.
     * @param account The address of the account whose token balance will be fetched.
     * @return tokenBalance The balance of the specified ERC20 token held by the account.
     */
    function safeBalanceOf(
        IERC20 token,
        address account
    ) internal view returns(uint256 tokenBalance) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            mstore(0x00, selector)
            mstore(0x04, account)
            let success := staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20)
            tokenBalance := mload(0)

            if or(iszero(success), lt(returndatasize(), 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another.
     * @dev If permit2 is true, uses the Permit2 standard; otherwise uses the standard ERC20 transferFrom. 
     * Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     * @param permit2 If true, uses the Permit2 standard for the transfer; otherwise uses the standard ERC20 transferFrom.
     */
    function safeTransferFromUniversal(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        bool permit2
    ) internal {
        if (permit2) {
            safeTransferFromPermit2(token, from, to, amount);
        } else {
            safeTransferFrom(token, from, to, amount);
        }
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another using the ERC20 standard.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /**
     * @notice Attempts to safely transfer tokens from one address to another using the Permit2 standard.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFromPermit2(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > type(uint160).max) revert Permit2TransferAmountTooHigh();
        bytes4 selector = IPermit2.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            mstore(add(data, 0x64), token)
            success := call(gas(), _PERMIT2, 0, data, 0x84, 0x0, 0x0)
            if success {
                success := gt(extcodesize(_PERMIT2), 0)
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /**
     * @notice Attempts to safely transfer tokens to another address.
     * @dev Either requires `true` in return data, or requires target to be smart-contract and empty return data.
     * @param token The IERC20 token contract from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to transfer.
     */
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /**
     * @notice Attempts to approve a spender to spend a certain amount of tokens.
     * @dev If `approve(from, to, amount)` fails, it tries to set the allowance to zero, and retries the `approve` call.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /**
     * @notice Safely increases the allowance of a spender.
     * @dev Increases with safe math check. Checks if the increased allowance will overflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /**
     * @notice Safely decreases the allowance of a spender.
     * @dev Decreases with safe math check. Checks if the decreased allowance will underflow, if yes, then it reverts the transaction.
     * Then uses `forceApprove` to increase the allowance.
     * @param token The IERC20 token contract on which the call will be made.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with the sender and contract as parameters.
     * Permit type is determined automatically based on permit calldata (IERC20Permit, IDaiLikePermit, and IPermit2).
     * @dev Wraps `tryPermit` function and forwards revert reason if permit fails.
     * @param token The IERC20 token to execute the permit function on.
     * @param permit The permit data to be used in the function call.
     */
    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, msg.sender, address(this), permit)) RevertReasonForwarder.reRevert();
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with custom owner and spender parameters. 
     * Permit type is determined automatically based on permit calldata (IERC20Permit, IDaiLikePermit, and IPermit2).
     * @dev Wraps `tryPermit` function and forwards revert reason if permit fails.
     * @param token The IERC20 token to execute the permit function on.
     * @param owner The owner of the tokens for which the permit is made.
     * @param spender The spender allowed to spend the tokens by the permit.
     * @param permit The permit data to be used in the function call.
     */
    function safePermit(IERC20 token, address owner, address spender, bytes calldata permit) internal {
        if (!tryPermit(token, owner, spender, permit)) RevertReasonForwarder.reRevert();
    }

    /**
     * @notice Attempts to execute the `permit` function on the provided token with the sender and contract as parameters.
     * @dev Invokes `tryPermit` with sender as owner and contract as spender.
     * @param token The IERC20 token to execute the permit function on.
     * @param permit The permit data to be used in the function call.
     * @return success Returns true if the permit function was successfully executed, false otherwise.
     */
    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool success) {
        return tryPermit(token, msg.sender, address(this), permit);
    }

    /**
     * @notice The function attempts to call the permit function on a given ERC20 token.
     * @dev The function is designed to support a variety of permit functions, namely: IERC20Permit, IDaiLikePermit, and IPermit2.
     * It accommodates both Compact and Full formats of these permit types.
     * Please note, it is expected that the `expiration` parameter for the compact Permit2 and the `deadline` parameter 
     * for the compact Permit are to be incremented by one before invoking this function. This approach is motivated by
     * gas efficiency considerations; as the unlimited expiration period is likely to be the most common scenario, and 
     * zeros are cheaper to pass in terms of gas cost. Thus, callers should increment the expiration or deadline by one
     * before invocation for optimized performance.
     * @param token The address of the ERC20 token on which to call the permit function.
     * @param owner The owner of the tokens. This address should have signed the off-chain permit.
     * @param spender The address which will be approved for transfer of tokens.
     * @param permit The off-chain permit data, containing different fields depending on the type of permit function.
     * @return success A boolean indicating whether the permit call was successful.
     */
    function tryPermit(IERC20 token, address owner, address spender, bytes calldata permit) internal returns(bool success) {
        // load function selectors for different permit standards
        bytes4 permitSelector = IERC20Permit.permit.selector;
        bytes4 daiPermitSelector = IDaiLikePermit.permit.selector;
        bytes4 permit2Selector = IPermit2.permit.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // Switch case for different permit lengths, indicating different permit standards
            switch permit.length
            // Compact IERC20Permit
            case 100 {
                mstore(ptr, permitSelector)     // store selector
                mstore(add(ptr, 0x04), owner)   // store owner
                mstore(add(ptr, 0x24), spender) // store spender

                // Compact IERC20Permit.permit(uint256 value, uint32 deadline, uint256 r, uint256 vs)
                {  // stack too deep
                    let deadline := shr(224, calldataload(add(permit.offset, 0x20))) // loads permit.offset 0x20..0x23
                    let vs := calldataload(add(permit.offset, 0x44))                 // loads permit.offset 0x44..0x63

                    calldatacopy(add(ptr, 0x44), permit.offset, 0x20)            // store value     = copy permit.offset 0x00..0x19
                    mstore(add(ptr, 0x64), sub(deadline, 1))                     // store deadline  = deadline - 1
                    mstore(add(ptr, 0x84), add(27, shr(255, vs)))                // store v         = most significant bit of vs + 27 (27 or 28)
                    calldatacopy(add(ptr, 0xa4), add(permit.offset, 0x24), 0x20) // store r         = copy permit.offset 0x24..0x43
                    mstore(add(ptr, 0xc4), shr(1, shl(1, vs)))                   // store s         = vs without most significant bit
                }
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            // Compact IDaiLikePermit
            case 72 {
                mstore(ptr, daiPermitSelector)  // store selector
                mstore(add(ptr, 0x04), owner)   // store owner
                mstore(add(ptr, 0x24), spender) // store spender

                // Compact IDaiLikePermit.permit(uint32 nonce, uint32 expiry, uint256 r, uint256 vs)
                {  // stack too deep
                    let expiry := shr(224, calldataload(add(permit.offset, 0x04))) // loads permit.offset 0x04..0x07
                    let vs := calldataload(add(permit.offset, 0x28))               // loads permit.offset 0x28..0x47

                    mstore(add(ptr, 0x44), shr(224, calldataload(permit.offset))) // store nonce   = copy permit.offset 0x00..0x03
                    mstore(add(ptr, 0x64), sub(expiry, 1))                        // store expiry  = expiry - 1
                    mstore(add(ptr, 0x84), true)                                  // store allowed = true
                    mstore(add(ptr, 0xa4), add(27, shr(255, vs)))                 // store v       = most significant bit of vs + 27 (27 or 28)
                    calldatacopy(add(ptr, 0xc4), add(permit.offset, 0x08), 0x20)  // store r       = copy permit.offset 0x08..0x27
                    mstore(add(ptr, 0xe4), shr(1, shl(1, vs)))                    // store s       = vs without most significant bit
                }
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            // IERC20Permit
            case 224 {
                mstore(ptr, permitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            // IDaiLikePermit
            case 256 {
                mstore(ptr, daiPermitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            // Compact IPermit2
            case 96 {
                // Compact IPermit2.permit(uint160 amount, uint32 expiration, uint32 nonce, uint32 sigDeadline, uint256 r, uint256 vs)
                mstore(ptr, permit2Selector)  // store selector
                mstore(add(ptr, 0x04), owner) // store owner
                mstore(add(ptr, 0x24), token) // store token

                calldatacopy(add(ptr, 0x50), permit.offset, 0x14)             // store amount = copy permit.offset 0x00..0x13
                // and(0xffffffffffff, ...) - conversion to uint48 
                mstore(add(ptr, 0x64), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x14))), 1))) // store expiration = ((permit.offset 0x14..0x17 - 1) & 0xffffffffffff)
                mstore(add(ptr, 0x84), shr(224, calldataload(add(permit.offset, 0x18)))) // store nonce = copy permit.offset 0x18..0x1b
                mstore(add(ptr, 0xa4), spender)                               // store spender
                // and(0xffffffffffff, ...) - conversion to uint48
                mstore(add(ptr, 0xc4), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x1c))), 1))) // store sigDeadline = ((permit.offset 0x1c..0x1f - 1) & 0xffffffffffff)
                mstore(add(ptr, 0xe4), 0x100)                                 // store offset = 256
                mstore(add(ptr, 0x104), 0x40)                                 // store length = 64
                calldatacopy(add(ptr, 0x124), add(permit.offset, 0x20), 0x20) // store r      = copy permit.offset 0x20..0x3f
                calldatacopy(add(ptr, 0x144), add(permit.offset, 0x40), 0x20) // store vs     = copy permit.offset 0x40..0x5f
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            // IPermit2
            case 352 {
                mstore(ptr, permit2Selector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length) // copy permit calldata
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            // Unknown
            default {
                mstore(ptr, _PERMIT_LENGTH_ERROR)
                revert(ptr, 4)
            }
        }
    }

    /**
     * @dev Executes a low level call to a token contract, making it resistant to reversion and erroneous boolean returns.
     * @param token The IERC20 token contract on which the call will be made.
     * @param selector The function signature that is to be called on the token contract.
     * @param to The address to which the token amount will be transferred.
     * @param amount The token amount to be transferred.
     * @return success A boolean indicating if the call was successful. Returns 'true' on success and 'false' on failure. 
     * In case of success but no returned data, validates that the contract code exists.
     * In case of returned data, ensures that it's a boolean `true`.
     */
    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    /**
     * @notice Safely deposits a specified amount of Ether into the IWETH contract. Consumes less gas then regular `IWETH.deposit`.
     * @param weth The IWETH token contract.
     * @param amount The amount of Ether to deposit into the IWETH contract.
     */
    function safeDeposit(IWETH weth, uint256 amount) internal {
        if (amount > 0) {
            bytes4 selector = IWETH.deposit.selector;
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(0, selector)
                if iszero(call(gas(), weth, amount, 0, 4, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @notice Safely withdraws a specified amount of wrapped Ether from the IWETH contract. Consumes less gas then regular `IWETH.withdraw`.
     * @dev Uses inline assembly to interact with the IWETH contract.
     * @param weth The IWETH token contract.
     * @param amount The amount of wrapped Ether to withdraw from the IWETH contract.
     */
    function safeWithdraw(IWETH weth, uint256 amount) internal {
        bytes4 selector = IWETH.withdraw.selector;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(0, selector)
            mstore(4, amount)
            if iszero(call(gas(), weth, 0, 0, 0x24, 0, 0)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @notice Safely withdraws a specified amount of wrapped Ether from the IWETH contract to a specified recipient.
     * Consumes less gas then regular `IWETH.withdraw`.
     * @param weth The IWETH token contract.
     * @param amount The amount of wrapped Ether to withdraw from the IWETH contract.
     * @param to The recipient of the withdrawn Ether.
     */
    function safeWithdrawTo(IWETH weth, uint256 amount, address to) internal {
        safeWithdraw(weth, amount);
        if (to != address(this)) {
            assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                if iszero(call(_RAW_CALL_GAS_LIMIT, to, amount, 0, 0, 0, 0)) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }
}

// ===== lib/@openzeppelin/contracts/token/ERC20/IERC20.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ===== lib/@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// ===== lib/@openzeppelin/contracts/utils/Address.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// ===== lib/@openzeppelin/contracts/utils/math/Math.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// ===== lib/@openzeppelin/contracts/utils/structs/EnumerableSet.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// ===== lib/@openzeppelin/contracts/security/Pausable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// ===== contracts/interfaces/IBotListV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./base/IVersion.sol";

/// @notice Bot info
/// @param forbidden Whether bot is forbidden
/// @param permissions Mapping credit manager => credit account => bot's permissions
struct BotInfo {
    bool forbidden;
    mapping(address => mapping(address => uint192)) permissions;
}

interface IBotListV3Events {
    // ----------- //
    // PERMISSIONS //
    // ----------- //

    /// @notice Emitted when new `bot`'s permissions are set for `creditAccount` in `creditManager`
    event SetBotPermissions(
        address indexed bot, address indexed creditManager, address indexed creditAccount, uint192 permissions
    );

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Emitted when `bot` is forbidden
    event ForbidBot(address indexed bot);
}

/// @title Bot list V3 interface
interface IBotListV3 is IBotListV3Events, IVersion {
    // ----------- //
    // PERMISSIONS //
    // ----------- //

    function botPermissions(address bot, address creditAccount) external view returns (uint192);

    function activeBots(address creditAccount) external view returns (address[] memory);

    function getBotStatus(address bot, address creditAccount)
        external
        view
        returns (uint192 permissions, bool forbidden);

    function setBotPermissions(address bot, address creditAccount, uint192 permissions)
        external
        returns (uint256 activeBotsRemaining);

    function eraseAllBotPermissions(address creditAccount) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function botForbiddenStatus(address bot) external view returns (bool);

    function forbidBot(address bot) external;
}

// ===== contracts/interfaces/ICreditConfiguratorV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IACLTrait} from "./base/IACLTrait.sol";
import {IVersion} from "./base/IVersion.sol";

enum AllowanceAction {
    FORBID,
    ALLOW
}

interface ICreditConfiguratorV3Events {
    // ------ //
    // TOKENS //
    // ------ //

    /// @notice Emitted when a token is made recognizable as collateral in the credit manager
    event AddCollateralToken(address indexed token);

    /// @notice Emitted when a new collateral token liquidation threshold is set
    event SetTokenLiquidationThreshold(address indexed token, uint16 liquidationThreshold);

    /// @notice Emitted when a collateral token liquidation threshold ramping is scheduled
    event ScheduleTokenLiquidationThresholdRamp(
        address indexed token,
        uint16 liquidationThresholdInitial,
        uint16 liquidationThresholdFinal,
        uint40 timestampRampStart,
        uint40 timestampRampEnd
    );

    /// @notice Emitted when a collateral token is forbidden
    event ForbidToken(address indexed token);

    /// @notice Emitted when a previously forbidden collateral token is allowed
    event AllowToken(address indexed token);

    // -------- //
    // ADAPTERS //
    // -------- //

    /// @notice Emitted when a new adapter and its target contract are allowed in the credit manager
    event AllowAdapter(address indexed targetContract, address indexed adapter);

    /// @notice Emitted when adapter and its target contract are forbidden in the credit manager
    event ForbidAdapter(address indexed targetContract, address indexed adapter);

    // -------------- //
    // CREDIT MANAGER //
    // -------------- //

    /// @notice Emitted when new fee parameters are set in the credit manager
    event UpdateFees(
        uint16 feeLiquidation, uint16 liquidationPremium, uint16 feeLiquidationExpired, uint16 liquidationPremiumExpired
    );

    // -------- //
    // UPGRADES //
    // -------- //

    /// @notice Emitted when a new price oracle is set in the credit manager
    event SetPriceOracle(address indexed priceOracle);

    /// @notice Emitted when a new facade is connected to the credit manager
    event SetCreditFacade(address indexed creditFacade);

    /// @notice Emitted when credit manager's configurator contract is upgraded
    event CreditConfiguratorUpgraded(address indexed creditConfigurator);

    // ------------- //
    // CREDIT FACADE //
    // ------------- //

    /// @notice Emitted when new debt principal limits are set
    event SetBorrowingLimits(uint256 minDebt, uint256 maxDebt);

    /// @notice Emitted when a new max debt per block multiplier is set
    event SetMaxDebtPerBlockMultiplier(uint8 maxDebtPerBlockMultiplier);

    /// @notice Emitted when new loss policy is set
    event SetLossPolicy(address indexed lossPolicy);

    /// @notice Emitted when a new expiration timestamp is set in the credit facade
    event SetExpirationDate(uint40 expirationDate);
}

/// @title Credit configurator V3 interface
interface ICreditConfiguratorV3 is IVersion, IACLTrait, ICreditConfiguratorV3Events {
    function creditManager() external view returns (address);

    function creditFacade() external view returns (address);

    function underlying() external view returns (address);

    // ------ //
    // TOKENS //
    // ------ //

    function makeAllTokensQuoted() external;

    function addCollateralToken(address token, uint16 liquidationThreshold) external;

    function setLiquidationThreshold(address token, uint16 liquidationThreshold) external;

    function rampLiquidationThreshold(
        address token,
        uint16 liquidationThresholdFinal,
        uint40 rampStart,
        uint24 rampDuration
    ) external;

    function forbidToken(address token) external;

    function allowToken(address token) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function allowedAdapters() external view returns (address[] memory);

    function allowAdapter(address adapter) external;

    function forbidAdapter(address adapter) external;

    // -------------- //
    // CREDIT MANAGER //
    // -------------- //

    function setFees(
        uint16 feeLiquidation,
        uint16 liquidationPremium,
        uint16 feeLiquidationExpired,
        uint16 liquidationPremiumExpired
    ) external;

    // -------- //
    // UPGRADES //
    // -------- //

    function setPriceOracle(address newPriceOracle) external;

    function setCreditFacade(address newCreditFacade, bool migrateParams) external;

    function upgradeCreditConfigurator(address newCreditConfigurator) external;

    // ------------- //
    // CREDIT FACADE //
    // ------------- //

    function setDebtLimits(uint128 newMinDebt, uint128 newMaxDebt) external;

    function setMaxDebtPerBlockMultiplier(uint8 newMaxDebtLimitPerBlockMultiplier) external;

    function forbidBorrowing() external;

    function setLossPolicy(address newLossPolicy) external;

    function setExpirationDate(uint40 newExpirationDate) external;
}

// ===== contracts/interfaces/ICreditFacadeV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {AllowanceAction} from "./ICreditConfiguratorV3.sol";
import "./ICreditFacadeV3Multicall.sol";
import {IACLTrait} from "./base/IACLTrait.sol";
import {PriceUpdate} from "./base/IPriceFeedStore.sol";
import {IVersion} from "./base/IVersion.sol";

/// @notice Multicall element
/// @param target Call target, which is either credit facade or adapter
/// @param callData Call data
struct MultiCall {
    address target;
    bytes callData;
}

/// @notice Debt limits packed into a single slot
/// @param minDebt Minimum debt amount per credit account
/// @param maxDebt Maximum debt amount per credit account
struct DebtLimits {
    uint128 minDebt;
    uint128 maxDebt;
}

/// @notice Collateral check params
/// @param collateralHints Optional array of token masks to check first to reduce the amount of computation
///        when known subset of account's collateral tokens covers all the debt
/// @param minHealthFactor Min account's health factor in bps in order not to revert
struct FullCheckParams {
    uint256[] collateralHints;
    uint16 minHealthFactor;
}

interface ICreditFacadeV3Events {
    /// @notice Emitted when a new credit account is opened
    event OpenCreditAccount(
        address indexed creditAccount, address indexed onBehalfOf, address indexed caller, uint256 referralCode
    );

    /// @notice Emitted when account is closed
    event CloseCreditAccount(address indexed creditAccount, address indexed borrower);

    /// @notice Emitted when account is liquidated
    event LiquidateCreditAccount(
        address indexed creditAccount, address indexed liquidator, address to, uint256 remainingFunds
    );

    /// @notice Emitted when account is partially liquidated
    event PartiallyLiquidateCreditAccount(
        address indexed creditAccount,
        address indexed token,
        address indexed liquidator,
        uint256 repaidDebt,
        uint256 seizedCollateral,
        uint256 fee
    );

    /// @notice Emitted when collateral is added to account
    event AddCollateral(address indexed creditAccount, address indexed token, uint256 amount);

    /// @notice Emitted when collateral is withdrawn from account
    event WithdrawCollateral(address indexed creditAccount, address indexed token, uint256 amount, address to);

    /// @notice Emitted when a multicall is started
    event StartMultiCall(address indexed creditAccount, address indexed caller);

    /// @notice Emitted when phantom token is withdrawn by account
    event WithdrawPhantomToken(address indexed creditAccount, address indexed token, uint256 amount);

    /// @notice Emitted when a call from account to an external contract is made during a multicall
    event Execute(address indexed creditAccount, address indexed targetContract);

    /// @notice Emitted when a multicall is finished
    event FinishMultiCall();
}

/// @title Credit facade V3 interface
interface ICreditFacadeV3 is IVersion, IACLTrait, ICreditFacadeV3Events {
    function creditManager() external view returns (address);

    function underlying() external view returns (address);

    function treasury() external view returns (address);

    function priceFeedStore() external view returns (address);

    function degenNFT() external view returns (address);

    function weth() external view returns (address);

    function botList() external view returns (address);

    function maxDebtPerBlockMultiplier() external view returns (uint8);

    function maxQuotaMultiplier() external view returns (uint256);

    function expirable() external view returns (bool);

    function expirationDate() external view returns (uint40);

    function debtLimits() external view returns (uint128 minDebt, uint128 maxDebt);

    function lossPolicy() external view returns (address);

    function forbiddenTokenMask() external view returns (uint256);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf, MultiCall[] calldata calls, uint256 referralCode)
        external
        payable
        returns (address creditAccount);

    function closeCreditAccount(address creditAccount, MultiCall[] calldata calls) external payable;

    function liquidateCreditAccount(
        address creditAccount,
        address to,
        MultiCall[] calldata calls,
        bytes memory lossPolicyData
    ) external;

    function liquidateCreditAccount(address creditAccount, address to, MultiCall[] calldata calls) external;

    function partiallyLiquidateCreditAccount(
        address creditAccount,
        address token,
        uint256 repaidAmount,
        uint256 minSeizedAmount,
        address to,
        PriceUpdate[] calldata priceUpdates
    ) external returns (uint256 seizedAmount);

    function multicall(address creditAccount, MultiCall[] calldata calls) external payable;

    function botMulticall(address creditAccount, MultiCall[] calldata calls) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setExpirationDate(uint40 newExpirationDate) external;

    function setDebtLimits(uint128 newMinDebt, uint128 newMaxDebt, uint8 newMaxDebtPerBlockMultiplier) external;

    function setLossPolicy(address newLossPolicy) external;

    function setTokenAllowance(address token, AllowanceAction allowance) external;

    function pause() external;

    function unpause() external;
}

// ===== contracts/interfaces/ICreditFacadeV3Multicall.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {BalanceDelta} from "../libraries/BalancesLogic.sol";
import {PriceUpdate} from "./base/IPriceFeedStore.sol";

// ----------- //
// PERMISSIONS //
// ----------- //

// NOTE: permissions 1 << 3, 1 << 4 and 1 << 7 were used by now deprecated methods, thus non-consecutive values

uint192 constant ADD_COLLATERAL_PERMISSION = 1 << 0;
uint192 constant INCREASE_DEBT_PERMISSION = 1 << 1;
uint192 constant DECREASE_DEBT_PERMISSION = 1 << 2;
uint192 constant WITHDRAW_COLLATERAL_PERMISSION = 1 << 5;
uint192 constant UPDATE_QUOTA_PERMISSION = 1 << 6;
uint192 constant SET_BOT_PERMISSIONS_PERMISSION = 1 << 8;
uint192 constant EXTERNAL_CALLS_PERMISSION = 1 << 16;

uint192 constant ALL_PERMISSIONS = ADD_COLLATERAL_PERMISSION | WITHDRAW_COLLATERAL_PERMISSION | UPDATE_QUOTA_PERMISSION
    | INCREASE_DEBT_PERMISSION | DECREASE_DEBT_PERMISSION | SET_BOT_PERMISSIONS_PERMISSION | EXTERNAL_CALLS_PERMISSION;
uint192 constant OPEN_CREDIT_ACCOUNT_PERMISSIONS = ALL_PERMISSIONS & ~DECREASE_DEBT_PERMISSION;
uint192 constant CLOSE_CREDIT_ACCOUNT_PERMISSIONS = ALL_PERMISSIONS & ~INCREASE_DEBT_PERMISSION;
uint192 constant LIQUIDATE_CREDIT_ACCOUNT_PERMISSIONS =
    EXTERNAL_CALLS_PERMISSION | ADD_COLLATERAL_PERMISSION | WITHDRAW_COLLATERAL_PERMISSION;

// ----- //
// FLAGS //
// ----- //

/// @dev Indicates that collateral check after the multicall can be skipped, set to true on account closure or liquidation
uint256 constant SKIP_COLLATERAL_CHECK_FLAG = 1 << 192;

/// @dev Indicates that external calls from credit account to adapters were made during multicall,
///      set to true on the first call to the adapter
uint256 constant EXTERNAL_CONTRACT_WAS_CALLED_FLAG = 1 << 193;

/// @dev Indicates that the price updates call should be skipped, set to true on liquidation when the first call
///      of the multicall is `onDemandPriceUpdates`
uint256 constant SKIP_PRICE_UPDATES_CALL_FLAG = 1 << 194;

/// @dev Indicates that collateral check must revert if any forbidden token is encountered on the account,
///      set to true after risky operations, such as `increaseDebt` or `withdrawCollateral`
uint256 constant REVERT_ON_FORBIDDEN_TOKENS_FLAG = 1 << 195;

/// @dev Indicates that collateral check must be performed using safe prices, set to true on `withdrawCollateral`
///      or if account has enabled forbidden tokens
uint256 constant USE_SAFE_PRICES_FLAG = 1 << 196;

/// @title Credit facade V3 multicall interface
/// @dev Unless specified otherwise, all these methods are only available in `openCreditAccount`,
///      `closeCreditAccount`, `multicall`, and, with account owner's permission, `botMulticall`
interface ICreditFacadeV3Multicall {
    /// @notice Applies on-demand price feed updates
    /// @param updates Array of price updates, see `PriceUpdate` for details
    /// @dev Reverts if placed not at the first position in the multicall
    /// @dev This method is available in all kinds of multicalls
    function onDemandPriceUpdates(PriceUpdate[] calldata updates) external;

    /// @notice Stores expected token balances (current balance + delta) after operations for a slippage check.
    ///         Normally, a check is performed automatically at the end of the multicall, but more fine-grained
    ///         behavior can be achieved by placing `storeExpectedBalances` and `compareBalances` where needed.
    /// @param balanceDeltas Array of (token, minBalanceDelta) pairs, deltas are allowed to be negative
    /// @dev Reverts if expected balances are already set
    /// @dev This method is available in all kinds of multicalls
    function storeExpectedBalances(BalanceDelta[] calldata balanceDeltas) external;

    /// @notice Performs a slippage check ensuring that current token balances are greater than saved expected ones
    /// @dev Resets stored expected balances
    /// @dev Reverts if expected balances are not stored
    /// @dev This method is available in all kinds of multicalls
    function compareBalances() external;

    /// @notice Adds collateral to account.
    ///         Only the underlying token counts towards account's collateral value by default, while all other tokens
    ///         must be enabled as collateral by "purchasing" quota for it. Holding non-enabled token on account with
    ///         non-zero debt poses a risk of losing it entirely to the liquidator. Adding non-enabled tokens is still
    ///         supported to allow users to later swap them into enabled ones in the same multicall.
    /// @param token Token to add
    /// @param amount Amount to add
    /// @dev Requires token approval from caller to the credit manager
    /// @dev This method can also be called during liquidation
    function addCollateral(address token, uint256 amount) external;

    /// @notice Adds collateral to account using signed EIP-2612 permit message.
    ///         Only the underlying token counts towards account's collateral value by default, while all other tokens
    ///         must be enabled as collateral by "purchasing" quota for it. Holding non-enabled token on account with
    ///         non-zero debt poses a risk of losing it entirely to the liquidator. Adding non-enabled tokens is still
    ///         supported to allow users to later swap them into enabled ones in the same multicall.
    /// @param token Token to add
    /// @param amount Amount to add
    /// @param deadline Permit deadline
    /// @dev `v`, `r`, `s` must be a valid signature of the permit message from caller to the credit manager
    /// @dev This method can also be called during liquidation
    function addCollateralWithPermit(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /// @notice Increases account's debt
    /// @param amount Underlying amount to borrow
    /// @dev Increasing debt is prohibited when closing an account
    /// @dev Increasing debt is prohibited if it was previously updated in the same block
    /// @dev The resulting debt amount must be within allowed limits
    /// @dev Increasing debt is prohibited if there are forbidden tokens enabled as collateral on the account
    /// @dev After debt increase, total amount borrowed by the credit manager in the current block must not exceed
    ///      the limit defined in the facade
    function increaseDebt(uint256 amount) external;

    /// @notice Decreases account's debt
    /// @param amount Underlying amount to repay, value above account's total debt indicates full repayment
    /// @dev Decreasing debt is prohibited when opening an account
    /// @dev Decreasing debt is prohibited if it was previously updated in the same block
    /// @dev The resulting debt amount must be above allowed minimum or zero (maximum is not checked here
    ///      to allow small repayments and partial liquidations in case configurator lowers it)
    /// @dev Full repayment brings account into a special mode that skips collateral checks and thus requires
    ///      an account to have no potential debt sources, e.g., all quotas must be disabled
    function decreaseDebt(uint256 amount) external;

    /// @notice Updates account's quota for a token
    /// @param token Collateral token to update the quota for (can't be underlying)
    /// @param quotaChange Desired quota change in underlying token units (`type(int96).min` to disable quota)
    /// @param minQuota Minimum resulting account's quota for token required not to revert
    /// @dev Enables token as collateral if quota is increased from zero, disables if decreased to zero
    /// @dev Quota increase is prohibited for forbidden tokens
    /// @dev Quota update is prohibited if account has zero debt
    /// @dev Resulting account's quota for token must not exceed the limit defined in the facade
    function updateQuota(address token, int96 quotaChange, uint96 minQuota) external;

    /// @notice Withdraws collateral from account
    /// @param token Token to withdraw
    /// @param amount Amount to withdraw, `type(uint256).max` to withdraw all balance
    /// @param to Token recipient
    /// @dev This method can also be called during liquidation
    /// @dev Withdrawals are prohibited in multicalls if there are forbidden tokens enabled as collateral on the account
    /// @dev Withdrawals activate safe pricing (min of main and reserve feeds) in collateral check
    /// @dev If `token` is a phantom token, it's withdrawn first, and its `depositedToken` is then sent to the recipient.
    ///      No slippage prevention mechanism is provided as withdrawals are assumed to happen at non-manipulatable rate.
    ///      Although an adapter call is made in process, permission for external calls is not required.
    function withdrawCollateral(address token, uint256 amount, address to) external;

    /// @notice Sets advanced collateral check parameters
    /// @param collateralHints Optional array of token masks to check first to reduce the amount of computation
    ///        when known subset of account's collateral tokens covers all the debt. Underlying token is always
    ///        checked last so it's forbidden to pass its mask.
    /// @param minHealthFactor Min account's health factor in bps in order not to revert, must be at least 10000
    /// @dev This method can't be called during closure or liquidation
    function setFullCheckParams(uint256[] calldata collateralHints, uint16 minHealthFactor) external;

    /// @notice Sets `bot`'s permissions to manage account to `permissions`
    /// @param bot Bot to set permissions for
    /// @param permissions A bitmask encoding bot permissions
    /// @dev Reverts if `permissions` has unexpected bits enabled or doesn't match permissions required by `bot`
    function setBotPermissions(address bot, uint192 permissions) external;
}

// ===== contracts/interfaces/ICreditManagerV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./base/IVersion.sol";

/// @notice Debt management type
///         - `INCREASE_DEBT` borrows additional funds from the pool, updates account's debt and cumulative interest index
///         - `DECREASE_DEBT` repays debt components (quota interest and fees -> base interest and fees -> debt principal)
///           and updates all corresponding state variables (base interest index, quota interest and fees, debt).
///           When repaying all the debt, ensures that account has no enabled quotas.
enum ManageDebtAction {
    INCREASE_DEBT,
    DECREASE_DEBT
}

/// @notice Collateral/debt calculation mode
///         - `GENERIC_PARAMS` returns generic data like account debt and cumulative indexes
///         - `DEBT_ONLY` is same as `GENERIC_PARAMS` but includes more detailed debt info, like accrued base/quota
///           interest and fees
///         - `FULL_COLLATERAL_CHECK_LAZY` checks whether account is sufficiently collateralized in a lazy fashion,
///           i.e. it stops iterating over collateral tokens once TWV reaches the desired target.
///           Since it may return underestimated TWV, it's only available for internal use.
///         - `DEBT_COLLATERAL` is same as `DEBT_ONLY` but also returns total value and total LT-weighted value of
///           account's tokens, this mode is used during account liquidation
///         - `DEBT_COLLATERAL_SAFE_PRICES` is same as `DEBT_COLLATERAL` but uses safe prices from price oracle
enum CollateralCalcTask {
    GENERIC_PARAMS,
    DEBT_ONLY,
    FULL_COLLATERAL_CHECK_LAZY,
    DEBT_COLLATERAL,
    DEBT_COLLATERAL_SAFE_PRICES
}

struct CreditAccountInfo {
    uint256 debt;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint128 quotaFees;
    uint256 enabledTokensMask;
    uint16 flags;
    uint64 lastDebtUpdate;
    address borrower;
}

struct CollateralDebtData {
    uint256 debt;
    uint256 cumulativeIndexNow;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint256 accruedInterest;
    uint256 accruedFees;
    uint256 totalDebtUSD;
    uint256 totalValue;
    uint256 totalValueUSD;
    uint256 twvUSD;
    uint256 enabledTokensMask;
    uint256 quotedTokensMask;
    address[] quotedTokens;
    address _poolQuotaKeeper;
}

struct CollateralTokenData {
    address token;
    uint16 ltInitial;
    uint16 ltFinal;
    uint40 timestampRampStart;
    uint24 rampDuration;
}

interface ICreditManagerV3Events {
    /// @notice Emitted when new credit configurator is set
    event SetCreditConfigurator(address indexed newConfigurator);
}

/// @title Credit manager V3 interface
interface ICreditManagerV3 is IVersion, ICreditManagerV3Events {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    function creditFacade() external view returns (address);

    function creditConfigurator() external view returns (address);

    function accountFactory() external view returns (address);

    function name() external view returns (string memory);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf) external returns (address);

    function closeCreditAccount(address creditAccount) external;

    function liquidateCreditAccount(
        address creditAccount,
        CollateralDebtData calldata collateralDebtData,
        address to,
        bool isExpired
    ) external returns (uint256 remainingFunds, uint256 loss);

    function manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        external
        returns (uint256 newDebt, uint256, uint256);

    function addCollateral(address payer, address creditAccount, address token, uint256 amount)
        external
        returns (uint256);

    function withdrawCollateral(address creditAccount, address token, uint256 amount, address to)
        external
        returns (uint256);

    function externalCall(address creditAccount, address target, bytes calldata callData)
        external
        returns (bytes memory result);

    function approveToken(address creditAccount, address token, address spender, uint256 amount) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function adapterToContract(address adapter) external view returns (address targetContract);

    function contractToAdapter(address targetContract) external view returns (address adapter);

    function execute(bytes calldata data) external returns (bytes memory result);

    function approveCreditAccount(address token, uint256 amount) external;

    function setActiveCreditAccount(address creditAccount) external;

    function getActiveCreditAccountOrRevert() external view returns (address creditAccount);

    // ----------------- //
    // COLLATERAL CHECKS //
    // ----------------- //

    function priceOracle() external view returns (address);

    function fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] calldata collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    ) external returns (uint256);

    function isLiquidatable(address creditAccount, uint16 minHealthFactor) external view returns (bool);

    function calcDebtAndCollateral(address creditAccount, CollateralCalcTask task)
        external
        view
        returns (CollateralDebtData memory cdd);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotedTokensMask() external view returns (uint256);

    function updateQuota(address creditAccount, address token, int96 quotaChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------------------- //
    // CREDIT MANAGER PARAMS //
    // --------------------- //

    function maxEnabledTokens() external view returns (uint8);

    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    function collateralTokensCount() external view returns (uint8);

    function getTokenMaskOrRevert(address token) external view returns (uint256 tokenMask);

    function getTokenByMask(uint256 tokenMask) external view returns (address token);

    function liquidationThresholds(address token) external view returns (uint16 lt);

    function ltParams(address token)
        external
        view
        returns (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration);

    function collateralTokenByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    // ------------ //
    // ACCOUNT INFO //
    // ------------ //

    function creditAccountInfo(address creditAccount)
        external
        view
        returns (
            uint256 debt,
            uint256 cumulativeIndexLastUpdate,
            uint128 cumulativeQuotaInterest,
            uint128 quotaFees,
            uint256 enabledTokensMask,
            uint16 flags,
            uint64 lastDebtUpdate,
            address borrower
        );

    function getBorrowerOrRevert(address creditAccount) external view returns (address borrower);

    function flagsOf(address creditAccount) external view returns (uint16);

    function setFlagFor(address creditAccount, uint16 flag, bool value) external;

    function enabledTokensMaskOf(address creditAccount) external view returns (uint256);

    function creditAccounts() external view returns (address[] memory);

    function creditAccounts(uint256 offset, uint256 limit) external view returns (address[] memory);

    function creditAccountsLen() external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function addToken(address token) external;

    function setCollateralTokenData(
        address token,
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint24 rampDuration
    ) external;

    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        uint16 feeLiquidationExpired,
        uint16 liquidationDiscountExpired
    ) external;

    function setContractAllowance(address adapter, address targetContract) external;

    function setCreditFacade(address creditFacade) external;

    function setPriceOracle(address priceOracle) external;

    function setCreditConfigurator(address creditConfigurator) external;
}

// ===== contracts/interfaces/IExceptions.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when attempting to connect a gauge to an incompatible pool quota keeper
error IncompatibleGaugeException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

/// @notice Thrown if new credit configurator's set of allowed adapters differs from the current one
error IncorrectAdaptersSetException();

/// @notice Thrown if attempting to schedule a token's LT ramping that is too short in duration
error RampDurationTooShortException();

/// @notice Thrown if attempting to set liquidation fees such that the sum of premium and fee changes
error InconsistentLiquidationFeesException();

/// @notice Thrown if attempting to set expired liquidation fees such that the sum of premium and fee changes
error InconsistentExpiredLiquidationFeesException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException(bytes4 selector);

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if a liquidator tries to liquidate an account with loss but violates the loss policy
error CreditAccountNotLiquidatableWithLossException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException(address token);

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException(uint256 forbiddenTokensMask);

/// @notice Thrown when forbidden token quota is increased during the multicall
error ForbiddenTokenQuotaIncreasedException(address token);

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException(address token);

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException(address token);

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException(address bot);

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException(uint256 permissions);

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException(uint256 mask);

/// @notice Thrown when trying to seize underlying token during partial liquidation
error UnderlyingIsNotLiquidatableException();

/// @notice Thrown when amount of collateral seized during partial liquidation is less than required
error SeizedLessThanRequiredException(uint256 seizedAmount);

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden bot
error InvalidBotException();

/// @notice Thrown when attempting to set permissions for a bot that don't meet its requirements
error IncorrectBotPermissionsException();

/// @notice Thrown when attempting to set non-zero permissions for too many bots
error TooManyActiveBotsException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when trying to apply an on-demand price update to a non-updatable price feed
error PriceFeedIsNotUpdatableException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// ===== contracts/interfaces/IPoolV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;
pragma abicoder v1;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IACLTrait} from "./base/IACLTrait.sol";
import {IContractsRegisterTrait} from "./base/IContractsRegisterTrait.sol";
import {IVersion} from "./base/IVersion.sol";

interface IPoolV3Events {
    /// @notice Emitted when depositing liquidity with referral code
    event Refer(address indexed onBehalfOf, uint256 indexed referralCode, uint256 amount);

    /// @notice Emitted when credit account borrows funds from the pool
    event Borrow(address indexed creditManager, address indexed creditAccount, uint256 amount);

    /// @notice Emitted when credit account's debt is repaid to the pool
    event Repay(address indexed creditManager, uint256 borrowedAmount, uint256 profit, uint256 loss);

    /// @notice Emitted when incurred loss can't be fully covered by burning treasury's shares
    event IncurUncoveredLoss(address indexed creditManager, uint256 loss);

    /// @notice Emitted when new interest rate model contract is set
    event SetInterestRateModel(address indexed newInterestRateModel);

    /// @notice Emitted when new pool quota keeper contract is set
    event SetPoolQuotaKeeper(address indexed newPoolQuotaKeeper);

    /// @notice Emitted when new total debt limit is set
    event SetTotalDebtLimit(uint256 limit);

    /// @notice Emitted when new credit manager is connected to the pool
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when new debt limit is set for a credit manager
    event SetCreditManagerDebtLimit(address indexed creditManager, uint256 newLimit);

    /// @notice Emitted when new withdrawal fee is set
    event SetWithdrawFee(uint256 fee);
}

/// @title Pool V3 interface
interface IPoolV3 is IVersion, IACLTrait, IContractsRegisterTrait, IPoolV3Events, IERC4626, IERC20Permit {
    function underlyingToken() external view returns (address);

    function treasury() external view returns (address);

    function withdrawFee() external view returns (uint16);

    function creditManagers() external view returns (address[] memory);

    function availableLiquidity() external view returns (uint256);

    function expectedLiquidity() external view returns (uint256);

    function expectedLiquidityLU() external view returns (uint256);

    // ---------------- //
    // ERC-4626 LENDING //
    // ---------------- //

    function depositWithReferral(uint256 assets, address receiver, uint256 referralCode)
        external
        returns (uint256 shares);

    function mintWithReferral(uint256 shares, address receiver, uint256 referralCode)
        external
        returns (uint256 assets);

    // --------- //
    // BORROWING //
    // --------- //

    function totalBorrowed() external view returns (uint256);

    function totalDebtLimit() external view returns (uint256);

    function creditManagerBorrowed(address creditManager) external view returns (uint256);

    function creditManagerDebtLimit(address creditManager) external view returns (uint256);

    function creditManagerBorrowable(address creditManager) external view returns (uint256 borrowable);

    function lendCreditAccount(uint256 borrowedAmount, address creditAccount) external;

    function repayCreditAccount(uint256 repaidAmount, uint256 profit, uint256 loss) external;

    // ------------- //
    // INTEREST RATE //
    // ------------- //

    function interestRateModel() external view returns (address);

    function baseInterestRate() external view returns (uint256);

    function supplyRate() external view returns (uint256);

    function baseInterestIndex() external view returns (uint256);

    function baseInterestIndexLU() external view returns (uint256);

    function lastBaseInterestUpdate() external view returns (uint40);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotaRevenue() external view returns (uint256);

    function lastQuotaRevenueUpdate() external view returns (uint40);

    function updateQuotaRevenue(int256 quotaRevenueDelta) external;

    function setQuotaRevenue(uint256 newQuotaRevenue) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setInterestRateModel(address newInterestRateModel) external;

    function setPoolQuotaKeeper(address newPoolQuotaKeeper) external;

    function setTotalDebtLimit(uint256 newLimit) external;

    function setCreditManagerDebtLimit(address creditManager, uint256 newLimit) external;

    function setWithdrawFee(uint256 newWithdrawFee) external;

    function pause() external;

    function unpause() external;
}

// ===== contracts/interfaces/IPriceOracleV3.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IACLTrait} from "./base/IACLTrait.sol";
import {IVersion} from "./base/IVersion.sol";

/// @notice Price feed params
/// @param priceFeed Price feed address
/// @param stalenessPeriod Period (in seconds) after which price feed's answer should be considered stale
/// @param skipCheck Whether price feed implements its own safety and staleness checks
/// @param tokenDecimals Token decimals
struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
    bool skipCheck;
    uint8 tokenDecimals;
}

interface IPriceOracleV3Events {
    /// @notice Emitted when new price feed is set for token
    event SetPriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);

    /// @notice Emitted when new reserve price feed is set for token
    event SetReservePriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);
}

/// @title Price oracle V3 interface
interface IPriceOracleV3 is IVersion, IACLTrait, IPriceOracleV3Events {
    function getTokens() external view returns (address[] memory);

    function priceFeeds(address token) external view returns (address priceFeed);

    function reservePriceFeeds(address token) external view returns (address);

    function priceFeedParams(address token) external view returns (PriceFeedParams memory);

    function reservePriceFeedParams(address token) external view returns (PriceFeedParams memory);

    // ---------- //
    // CONVERSION //
    // ---------- //

    function getPrice(address token) external view returns (uint256);

    function getSafePrice(address token) external view returns (uint256);

    function getReservePrice(address token) external view returns (uint256);

    function convertToUSD(uint256 amount, address token) external view returns (uint256);

    function convertFromUSD(uint256 amount, address token) external view returns (uint256);

    function convert(uint256 amount, address tokenFrom, address tokenTo) external view returns (uint256);

    function safeConvertToUSD(uint256 amount, address token) external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setPriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;

    function setReservePriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;
}

// ===== contracts/interfaces/base/IAddressProvider.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IAddressProvider {
    function getAddressOrRevert(bytes32 key, uint256 version) external view returns (address);
}

// ===== contracts/interfaces/base/IDegenNFT.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./IVersion.sol";
import {IStateSerializer} from "./IStateSerializer.sol";

/// @title Degen NFT interface
/// @notice Generic interface for a Degen NFT contract that can be used to restrict
///         non-whitelisted users from opening accounts through the credit facade
/// @dev Degen NFTs must have type `DEGEN_NFT::{POSTFIX}`
interface IDegenNFT is IVersion, IStateSerializer {
    function burn(address from, uint256 amount) external;
}

// ===== contracts/interfaces/base/ILossPolicy.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./IVersion.sol";
import {IStateSerializer} from "./IStateSerializer.sol";

/// @title Loss policy interface
/// @notice Generic interface for a loss policy that dictates conditions under which a bad debt liquidation can proceed.
/// @dev Loss policies must have type `LOSS_POLICY::{POSTFIX}`
interface ILossPolicy is IVersion, IStateSerializer {
    /// @notice Parameters passed to the loss policy
    /// @param totalDebtUSD Account's total debt in USD
    /// @param twvUSD Account's total weighted value in USD
    /// @param extraData Optional field that can be used to pass some off-chain data specific to implementation
    struct Params {
        uint256 totalDebtUSD;
        uint256 twvUSD;
        bytes extraData;
    }

    /// @notice Access mode for loss liquidations
    enum AccessMode {
        Permissionless,
        Permissioned,
        Forbidden
    }

    /// @notice Emitted when the loss policy access mode is set
    event SetAccessMode(AccessMode mode);

    /// @notice Emitted when the loss policy checks are enabled or disabled
    event SetChecksEnabled(bool enabled);

    /// @notice Whether `creditAccount` can be liquidated with loss by `caller`
    function isLiquidatableWithLoss(address creditAccount, address caller, Params calldata params)
        external
        returns (bool);

    /// @notice Returns current access mode
    function accessMode() external view returns (AccessMode);

    /// @notice Returns whether policy checks are enabled
    function checksEnabled() external view returns (bool);

    /// @notice Sets access mode for loss liquidations
    function setAccessMode(AccessMode mode) external;

    /// @notice Enables or disables policy checks
    function setChecksEnabled(bool enabled) external;
}

// ===== contracts/interfaces/base/IPhantomToken.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./IVersion.sol";
import {IStateSerializer} from "./IStateSerializer.sol";

/// @title Phantom token interface
/// @notice Broadly speaking, by saying "phantom" we imply that token is not transferable. In Gearbox, we use such tokens
///         to track balances of non-tokenized positions in integrated protocols to allow those to be used as collateral.
/// @dev Phantom tokens must have type `PHANTOM_TOKEN::{POSTFIX}`
interface IPhantomToken is IVersion, IStateSerializer {
    /// @notice Returns phantom token's target contract and deposited token
    function getPhantomTokenInfo() external view returns (address target, address depositedToken);
}

/// @title Phantom token withdrawer interface
/// @notice Though only the `balanceOf()` function is needed for token to serve as collateral, some services can suffer
///         from its non-transferability, including liquidators or bots that don't have permissions for external calls.
///         To mitigate this, phantom token withdrawals from credit accounts automatically start with withdrawal of
///         deposited token from the integrated protocol via an adapter call defined by this interface.
/// @dev While theoretically possible, we assume that phantom tokens can't be nested
interface IPhantomTokenWithdrawer {
    /// @notice Withdraws phantom token for its deposited token
    function withdrawPhantomToken(address token, uint256 amount) external returns (bool useSafePrices);
}

// ===== contracts/interfaces/base/IPriceFeedStore.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./IVersion.sol";

struct PriceUpdate {
    address priceFeed;
    bytes data;
}

interface IPriceFeedStore {
    function getStalenessPeriod(address priceFeed) external view returns (uint32);
    function updatePrices(PriceUpdate[] calldata updates) external;
}

// ===== contracts/interfaces/external/IWETH.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// ===== contracts/libraries/BalancesLogic.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {BitMask} from "./BitMask.sol";

struct Balance {
    address token;
    uint256 balance;
}

struct BalanceWithMask {
    address token;
    uint256 tokenMask;
    uint256 balance;
}

struct BalanceDelta {
    address token;
    int256 amount;
}

enum Comparison {
    GREATER_OR_EQUAL,
    LESS_OR_EQUAL
}

/// @title Balances logic library
/// @notice Implements functions for before-and-after balance comparisons
library BalancesLogic {
    using BitMask for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /// @dev Compares current `token` balance with `value`
    /// @param token Token to check balance for
    /// @param value Value to compare current token balance with
    /// @param comparison Whether current balance must be greater/less than or equal to `value`
    function checkBalance(address creditAccount, address token, uint256 value, Comparison comparison)
        internal
        view
        returns (bool)
    {
        uint256 current = IERC20(token).safeBalanceOf(creditAccount);
        return (comparison == Comparison.GREATER_OR_EQUAL && current >= value)
            || (comparison == Comparison.LESS_OR_EQUAL && current <= value); // U:[BLL-1]
    }

    /// @dev Returns an array of expected token balances after operations
    /// @param creditAccount Credit account to compute balances for
    /// @param deltas Array of expected token balance changes
    function storeBalances(address creditAccount, BalanceDelta[] memory deltas)
        internal
        view
        returns (Balance[] memory balances)
    {
        uint256 len = deltas.length;
        balances = new Balance[](len); // U:[BLL-2]
        for (uint256 i = 0; i < len;) {
            int256 balance = IERC20(deltas[i].token).safeBalanceOf(creditAccount).toInt256();
            balances[i] = Balance({token: deltas[i].token, balance: (balance + deltas[i].amount).toUint256()}); // U:[BLL-2]
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Compares current balances with the previously stored ones
    /// @param creditAccount Credit account to compare balances for
    /// @param balances Array of previously stored balances
    /// @param comparison Whether current balances must be greater/less than or equal to stored ones
    /// @return failedToken The first token for which the condition specified by `comparison` fails, if any
    function compareBalances(address creditAccount, Balance[] memory balances, Comparison comparison)
        internal
        view
        returns (address failedToken)
    {
        unchecked {
            uint256 len = balances.length;
            for (uint256 i; i < len; ++i) {
                if (!BalancesLogic.checkBalance(creditAccount, balances[i].token, balances[i].balance, comparison)) {
                    return balances[i].token; // U:[BLL-3]
                }
            }
        }
    }

    /// @dev Returns balances of specified tokens on the credit account
    /// @param creditAccount Credit account to compute balances for
    /// @param tokensMask Bit mask of tokens to compute balances for
    /// @param getTokenByMaskFn Function that returns token's address by its mask
    function storeBalances(
        address creditAccount,
        uint256 tokensMask,
        function (uint256) view returns (address) getTokenByMaskFn
    ) internal view returns (BalanceWithMask[] memory balances) {
        if (tokensMask == 0) return balances;

        balances = new BalanceWithMask[](tokensMask.calcEnabledTokens()); // U:[BLL-4]
        unchecked {
            uint256 i;
            while (tokensMask != 0) {
                uint256 tokenMask = tokensMask.lsbMask();
                tokensMask ^= tokenMask;

                address token = getTokenByMaskFn(tokenMask);
                balances[i] = BalanceWithMask({
                    token: token,
                    tokenMask: tokenMask,
                    balance: IERC20(token).safeBalanceOf(creditAccount)
                }); // U:[BLL-4]
                ++i;
            }
        }
    }

    /// @dev Compares current balances of specified tokens with the previously stored ones
    /// @param creditAccount Credit account to compare balances for
    /// @param tokensMask Bit mask of tokens to compare balances for
    /// @param balances Array of previously stored balances
    /// @param comparison Whether current balances must be greater/less than or equal to stored ones
    /// @return failedToken The first token for which the condition specified by `comparison` fails, if any
    /// @dev This function assumes that `tokensMask` encodes a subset of tokens from `balances`
    function compareBalances(
        address creditAccount,
        uint256 tokensMask,
        BalanceWithMask[] memory balances,
        Comparison comparison
    ) internal view returns (address failedToken) {
        if (tokensMask == 0) return address(0);

        unchecked {
            uint256 len = balances.length;
            for (uint256 i; i < len; ++i) {
                if (tokensMask & balances[i].tokenMask == 0) continue;
                if (!BalancesLogic.checkBalance(creditAccount, balances[i].token, balances[i].balance, comparison)) {
                    return balances[i].token; // U:[BLL-5]
                }
            }
        }
    }
}

// ===== contracts/libraries/BitMask.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IncorrectParameterException} from "../interfaces/IExceptions.sol";

/// @title Bit mask library
/// @notice Implements functions that manipulate bit masks
///         Bit masks are utilized extensively by Gearbox to efficiently store token sets (enabled tokens on accounts
///         or forbidden tokens) and check for set inclusion. A mask is a uint256 number that has its i-th bit set to
///         1 if i-th item is included into the set. For example, each token has a mask equal to 2**i, so set inclusion
///         can be checked by checking tokenMask & setMask != 0.
library BitMask {
    /// @dev Calculates the number of `1` bits
    /// @param enabledTokensMask Bit mask to compute the number of `1` bits in
    function calcEnabledTokens(uint256 enabledTokensMask) internal pure returns (uint256 totalTokensEnabled) {
        unchecked {
            while (enabledTokensMask > 0) {
                enabledTokensMask &= enabledTokensMask - 1; // U:[BM-3]
                ++totalTokensEnabled; // U:[BM-3]
            }
        }
    }

    /// @dev Enables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask of bits to enable
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable) internal pure returns (uint256) {
        return enabledTokenMask | bitsToEnable; // U:[BM-4]
    }

    /// @dev Disables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask of bits to disable
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable) internal pure returns (uint256) {
        return enabledTokenMask & ~bitsToDisable; // U:[BM-4]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    function enableDisable(uint256 enabledTokensMask, uint256 bitsToEnable, uint256 bitsToDisable)
        internal
        pure
        returns (uint256)
    {
        return (enabledTokensMask | bitsToEnable) & (~bitsToDisable); // U:[BM-5]
    }

    /// @dev Returns a mask with only the least significant bit of `mask` enabled
    /// @dev This function can be used to efficiently iterate over enabled bits in a mask
    function lsbMask(uint256 mask) internal pure returns (uint256) {
        unchecked {
            return mask & uint256(-int256(mask)); // U:[BM-6]
        }
    }
}

// ===== contracts/libraries/Constants.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

bytes32 constant AP_GEAR_TOKEN = "GLOBAL::GEAR_TOKEN";
bytes32 constant AP_INSTANCE_MANAGER_PROXY = "INSTANCE_MANAGER_PROXY";
bytes32 constant AP_CROSS_CHAIN_GOVERNANCE_PROXY = "CROSS_CHAIN_GOVERNANCE_PROXY";
bytes32 constant AP_PRICE_FEED_STORE = "PRICE_FEED_STORE";
uint256 constant NO_VERSION_CONTROL = 0;

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4;

uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant EPOCH_LENGTH = 7 days;
uint256 constant FIRST_EPOCH_TIMESTAMP = 1702900800;
uint256 constant EPOCHS_TO_WITHDRAW = 4;

uint8 constant MAX_SANE_ENABLED_TOKENS = 20;
uint256 constant MAX_SANE_EPOCH_LENGTH = 28 days;
uint256 constant MAX_SANE_ACTIVE_BOTS = 5;

uint8 constant MAX_WITHDRAW_FEE = 100;

uint8 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

uint8 constant BOT_PERMISSIONS_SET_FLAG = 1;

uint256 constant UNDERLYING_TOKEN_MASK = 1;

address constant INACTIVE_CREDIT_ACCOUNT_ADDRESS = address(1);

// ===== contracts/libraries/MarketHelper.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICreditManagerV3} from "../interfaces/ICreditManagerV3.sol";
import {IPoolV3} from "../interfaces/IPoolV3.sol";

interface IMarketConfigurator {
    function acl() external view returns (address);
    function contractsRegister() external view returns (address);
    function treasury() external view returns (address);
}

/// @title Market helper library
/// @notice Helper functions to retrieve ACL, contracts register and treasury from a pool or credit manager
/// @dev Accounts for different versions of markets within the new permissionless framework
library MarketHelper {
    /// @notice Retrieves the ACL address from a pool
    function getACL(IPoolV3 pool) internal view returns (address) {
        if (_version(pool) < 3_10) return _marketConfigurator(pool).acl();
        return pool.acl();
    }

    /// @notice Retrieves the ACL address from a credit manager
    function getACL(ICreditManagerV3 creditManager) internal view returns (address) {
        return getACL(_pool(creditManager));
    }

    /// @notice Retrieves the contracts register address from a pool
    function getContractsRegister(IPoolV3 pool) internal view returns (address) {
        if (_version(pool) < 3_10) return _marketConfigurator(pool).contractsRegister();
        return pool.contractsRegister();
    }

    /// @notice Retrieves the contracts register address from a credit manager
    function getContractsRegister(ICreditManagerV3 creditManager) internal view returns (address) {
        return getContractsRegister(_pool(creditManager));
    }

    /// @notice Retrieves the treasury address from a pool
    function getTreasury(IPoolV3 pool) internal view returns (address) {
        if (_version(pool) < 3_10) return _marketConfigurator(pool).treasury();
        return pool.treasury();
    }

    /// @notice Retrieves the treasury address from a credit manager
    function getTreasury(ICreditManagerV3 creditManager) internal view returns (address) {
        return getTreasury(_pool(creditManager));
    }

    /// @dev Retrieves the version of a pool
    function _version(IPoolV3 pool) private view returns (uint256) {
        return pool.version();
    }

    /// @dev Retrieves the market configurator (owner of both new and old ACLs) of a pool
    function _marketConfigurator(IPoolV3 pool) private view returns (IMarketConfigurator) {
        return IMarketConfigurator(Ownable(pool.acl()).owner());
    }

    /// @dev Retrieves the pool credit manager is connected to
    function _pool(ICreditManagerV3 creditManager) private view returns (IPoolV3) {
        return IPoolV3(creditManager.pool());
    }
}

// ===== contracts/libraries/OptionalCall.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title Optional call library
/// @notice Implements a function that calls a contract that may not have an expected selector.
///         Handles the case where the contract has a fallback function that may or may not change state.
library OptionalCall {
    function staticCallOptionalSafe(address target, bytes memory data, uint256 gasAllowance)
        internal
        view
        returns (bool, bytes memory)
    {
        (bool success, bytes memory returnData) = target.staticcall{gas: gasAllowance}(data);
        return returnData.length > 0 ? (success, returnData) : (false, returnData);
    }
}

// ===== contracts/traits/ACLTrait.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IACL} from "../interfaces/base/IACL.sol";
import {IACLTrait} from "../interfaces/base/IACLTrait.sol";
import {
    AddressIsNotContractException,
    CallerNotConfiguratorException,
    CallerNotPausableAdminException,
    CallerNotUnpausableAdminException,
    ZeroAddressException
} from "../interfaces/IExceptions.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is IACLTrait {
    using Address for address;

    /// @notice ACL contract address
    address public immutable override acl;

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Ensures that function caller has pausable admin role
    modifier pausableAdminsOnly() {
        _ensureCallerIsPausableAdmin();
        _;
    }

    /// @dev Ensures that function caller has unpausable admin role
    modifier unpausableAdminsOnly() {
        _ensureCallerIsUnpausableAdmin();
        _;
    }

    /// @notice Constructor
    /// @param _acl ACL contract address
    constructor(address _acl) {
        if (_acl == address(0)) revert ZeroAddressException();
        if (!_acl.isContract()) revert AddressIsNotContractException(_acl);
        acl = _acl;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator(msg.sender)) revert CallerNotConfiguratorException();
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }

    /// @dev Reverts if the caller is not pausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsPausableAdmin() internal view {
        if (!_hasRole("PAUSABLE_ADMIN", msg.sender)) revert CallerNotPausableAdminException();
    }

    /// @dev Reverts if the caller is not unpausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsUnpausableAdmin() internal view {
        if (!_hasRole("UNPAUSABLE_ADMIN", msg.sender)) revert CallerNotUnpausableAdminException();
    }

    /// @dev Whether account `account` has role `role`
    /// @dev Used to cut contract size on external calls
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return IACL(acl).hasRole(role, account);
    }
}

// ===== contracts/traits/ReentrancyGuardTrait.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/// @title Reentrancy guard trait
/// @notice Same as OpenZeppelin's `ReentrancyGuard` but the flag only uses 1 byte of storage instead of 32,
///         which allows to pack it with other frequently accessed state variables
abstract contract ReentrancyGuardTrait {
    uint8 internal _reentrancyStatus = NOT_ENTERED;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _ensureNotEntered();

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = NOT_ENTERED;
    }

    /// @dev Reverts if the contract is currently entered
    /// @dev Used to cut contract size on modifiers
    function _ensureNotEntered() internal view {
        require(_reentrancyStatus != ENTERED, "ReentrancyGuard: reentrant call");
    }
}

// ===== contracts/traits/SanityCheckTrait.sol =====
// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}

// ===== lib/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// ===== lib/@1inch/solidity-utils/contracts/interfaces/IDaiLikePermit.sol =====
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// ===== lib/@1inch/solidity-utils/contracts/interfaces/IPermit2.sol =====
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPermit2 {
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }
    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    /// @notice Packed allowance
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    function transferFrom(address user, address spender, uint160 amount, address token) external;

    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    function allowance(address user, address token, address spender) external view returns (PackedAllowance memory);
}

// ===== lib/@1inch/solidity-utils/contracts/interfaces/IWETH.sol =====
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed dst, uint wad);

    event Withdrawal(address indexed src, uint wad);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// ===== lib/@1inch/solidity-utils/contracts/libraries/RevertReasonForwarder.sol =====
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// ===== lib/@openzeppelin/contracts/utils/Context.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// ===== contracts/interfaces/base/IVersion.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title Version interface
/// @notice Defines contract version and type
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);

    /// @notice Contract type
    function contractType() external view returns (bytes32);
}

// ===== contracts/interfaces/base/IACLTrait.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IACLTrait {
    function acl() external view returns (address);
}

// ===== lib/@openzeppelin/contracts/interfaces/IERC4626.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// ===== contracts/interfaces/base/IContractsRegisterTrait.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IContractsRegisterTrait {
    function contractsRegister() external view returns (address);
}

// ===== contracts/interfaces/base/IStateSerializer.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title State serializer interface
/// @notice Generic interface for a contract that can serialize its state into a bytes array
interface IStateSerializer {
    /// @notice Serializes the state of the contract into a bytes array `serializedData`
    function serialize() external view returns (bytes memory serializedData);
}

// ===== lib/@openzeppelin/contracts/utils/math/SafeCast.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// ===== lib/@openzeppelin/contracts/access/Ownable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ===== contracts/interfaces/base/IACL.sol =====
// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IACL {
    function isConfigurator(address account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// ===== lib/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
