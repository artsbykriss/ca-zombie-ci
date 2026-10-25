// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Governed} from "../access/Governed.sol";
import {IFeeSink} from "../interfaces/IFeeSink.sol";

/// @title  InsuranceFund
/// @notice First-loss buffer in the house waterfall (spec §7.3/§7.4). **Scaffolded but UNFUNDED at
///         launch** (founder correction): it deploys and is wired as the FIRST absorber, but starts
///         at ZERO balance — so losses pass straight through to LP socialized loss today. The team
///         can fund it later via {fund} (or by routing the LP slice here) **without a redeploy**,
///         and it immediately begins absorbing first. It is **never seeded from treasury** here.
/// @dev    `coverLoss` is callable only by the wired `vault`; it sends whatever it can (≤ balance)
///         and returns the covered amount, so the vault socializes only the remainder.
contract InsuranceFund is Governed, IFeeSink {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    address public vault;

    event VaultSet(address indexed vault);
    event Funded(address indexed from, uint256 amount);
    event LossCovered(uint256 requested, uint256 covered);

    error ZeroAddress();
    error OnlyVault();

    constructor(address accessController_, address usdc_) Governed(accessController_) {
        if (usdc_ == address(0)) revert ZeroAddress();
        usdc = IERC20(usdc_);
    }

    function setVault(address vault_) external onlyGovernance {
        if (vault_ == address(0)) revert ZeroAddress();
        vault = vault_;
        emit VaultSet(vault_);
    }

    /// @notice Add USDC to the fund (team/treasury/anyone). The only way the fund gets a balance.
    function fund(uint256 amount) external {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(msg.sender, amount);
    }

    /// @notice LP-slice routing target (if pointed here later); accounted simply as balance.
    function notifyFee(uint256 amount) external {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(msg.sender, amount);
    }

    /// @notice Cover up to `amount` of a house loss, sending the covered USDC to the vault.
    /// @return covered The amount actually covered (≤ current balance). Remainder is the vault's
    ///         to socialize. At zero balance this returns 0 and the loss is fully LP-borne.
    function coverLoss(uint256 amount) external returns (uint256 covered) {
        if (msg.sender != vault) revert OnlyVault();
        uint256 bal = usdc.balanceOf(address(this));
        covered = amount < bal ? amount : bal;
        if (covered > 0) usdc.safeTransfer(vault, covered);
        emit LossCovered(amount, covered);
    }

    function balance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
