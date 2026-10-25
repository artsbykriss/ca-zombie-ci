// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {UnitasAggregatorConfidentialUpgradeable, IUnitasProxy} from "./UnitasAggregatorConfidentialUpgradeable.sol";
import {IConfidentialERC20Converter} from "../converter/interfaces/IConfidentialERC20Converter.sol";

/**
 * @title UnitasMintAggregatorConfidential
 * @notice Confidential mint aggregator for the Unitas USDu Booster off-chain API.
 *
 * Route: eUSDT -> (unshield USDT, approve UnitasProxy, keeper calls mint_and_stake API) -> sUSDu ->
 * shield -> esUSDu. Users deposit eUSDT and claim esUSDu.
 *
 * The contract never calls UnitasProxy on-chain; it only approves UnitasProxy to pull the unshielded
 * USDT and re-shields the sUSDu once it arrives. 1:1 mint, so the exchange rate is ~1.
 *
 * Upgradeable: deployed behind a UUPS proxy via {initialize}.
 */
contract UnitasMintAggregatorConfidential is UnitasAggregatorConfidentialUpgradeable {
    /// @dev Keeps the `reinitializer` version aligned between `initialize` and any future `reinitializeVX`.
    uint64 private constant REINITIALIZER_VERSION = 1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the mint aggregator behind a UUPS proxy.
    /// @param eUSDT_ Confidential converter over USDT (input token).
    /// @param esUSDu_ Confidential converter over sUSDu (output token).
    /// @param unitasProxy_ UnitasProxy address (approve target + API `address`).
    /// @param keeper_ Exclusive caller of `dispatchAggregateCallback` (rotatable by the owner via
    ///   `setKeeper`).
    /// @param owner_ Owner authorized to update policy.
    /// @param minAggregateAge_ Minimum seconds an aggregate must age before dispatch.
    /// @param callbackDeadline_ Seconds after dispatch before the aggregate may cancel (e.g. 1 hour).
    /// @custom:oz-upgrades-validate-as-initializer
    function initialize(
        IConfidentialERC20Converter eUSDT_,
        IConfidentialERC20Converter esUSDu_,
        address unitasProxy_,
        address keeper_,
        address owner_,
        uint256 minAggregateAge_,
        uint256 callbackDeadline_
    ) public reinitializer(REINITIALIZER_VERSION) {
        // `vault_` holds UnitasProxy.staked() (sUSDu, a real ERC4626); validated in `_validateVaultAssetMatch`.
        // Slippage check is unused by this route (0 = disabled).
        __VaultAggregatorConfidential_init(
            eUSDT_, esUSDu_, IERC4626(IUnitasProxy(unitasProxy_).staked()), owner_, minAggregateAge_, callbackDeadline_, 0
        );
        __UnitasAggregatorConfidential_init(unitasProxy_, keeper_);
    }

    // ----------------------------------------------------------------------------------------------
    // Views
    // ----------------------------------------------------------------------------------------------

    /// @notice Human-readable summary of the mint route.
    /// @dev Two layers: users deposit/claim confidential tokens (eUSDT -> esUSDu); the underlying
    /// plaintext route inside `_executeUnitasStep` is USDT -> sUSDu via the off-chain Unitas API.
    function routeDescription() public pure override returns (string memory) {
        return "Unitas USDu Booster mint: eUSDT -> esUSDu (underlying USDT -> sUSDu via off-chain API).";
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    function _initialStep() internal pure override returns (Step) {
        return Step.MintInit;
    }

    /// @dev Override of the base claim: additionally grants the configured reward pool persistent
    /// access to the claimed esUSDu amount handle, so the pool's keeper can register the position via
    /// `UnitasRewardPool.enterBatch`. This aggregator holds access to `amountTransferred` (the token's
    /// `_update` grants `from`), and only an existing holder can re-grant — hence the grant must
    /// happen here, not in the pool.
    function _claim(uint256 aggregateId, address account) internal override returns (ve_uint64) {
        ve_uint64 amountTransferred = super._claim(aggregateId, account);
        address pool = _rewardPool();
        if (pool != address(0)) {
            FHE.accessPolicy(amountTransferred, pool);
        }
        return amountTransferred;
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev Mint awaits sUSDu as the OUTPUT of the route, so the staked token must be the `toToken_`
    /// (esUSDu) underlying. Requiring the input side instead would let a reversed converter pair pass
    /// initialization and then approve the wrong token to UnitasProxy.
    function _stakedTokenUnderlying(
        IConfidentialERC20Converter,
        IConfidentialERC20Converter toToken_
    ) internal view override returns (address) {
        return toToken_.underlying();
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev `amount` is in eUSDT converter units; `rawUSDT = amount * fromToken().rate()`. The off-chain
    /// API converts USDT 1:1 to USDu and deposits it into the sUSDu vault, returning sUSDu to this
    /// contract.
    function _executeUnitasStep(uint256 aggregateId, uint256 amount, Step step) internal override returns (ExecuteOutcome) {
        if (step == Step.MintInit) {
            // Commit the USDT to UnitasProxy. The keeper then calls the mint API; UnitasProxy pulls the
            // exact approved amount and returns sUSDu to this contract.
            UnitasAggregatorStorage storage $ = _getUnitasAggregatorStorage();
            uint256 rawUSDT = amount * fromToken().rate();
            SafeERC20.forceApprove(IERC20(fromToken().underlying()), $._unitasProxy, rawUSDT);
            $._aggregateStep[aggregateId] = Step.MintAwaitOutput;
            emit StepAdvanced(aggregateId, Step.MintAwaitOutput);
            return ExecuteOutcome.Partial;
        }

        // MintAwaitOutput: the keeper only re-enters this callback once the off-chain API has delivered
        // the sUSDu, so reaching this step means the output is present — finalize. If the callback runs
        // before delivery, the base `Complete` branch reverts on a zero exchange rate (no sUSDu to shield),
        // leaving the aggregate `Dispatched` for the keeper to retry.
        return ExecuteOutcome.Complete;
    }

    /// @inheritdoc UnitasAggregatorConfidentialUpgradeable
    /// @dev Mint approved USDT to UnitasProxy when the batch entered `MintAwaitOutput`; no other step
    /// holds an allowance.
    function _revokeProxyAllowance(Step step) internal override {
        if (step == Step.MintAwaitOutput) {
            SafeERC20.forceApprove(IERC20(fromToken().underlying()), _unitasProxy(), 0);
        }
    }
}
