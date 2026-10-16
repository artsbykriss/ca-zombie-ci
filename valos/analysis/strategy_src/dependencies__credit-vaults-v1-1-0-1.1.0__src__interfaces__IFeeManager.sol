// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IRecoverable} from "./IRecoverable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @notice The fee structure for a strategy
struct FeeStructure {
    /// @notice The establishment fee
    uint256 establishmentFee;
    /// @notice The management fee
    uint256 managementFee;
    /// @notice The performance fee
    uint256 performanceFee;
    /// @notice The manager performance fee split
    uint256 managerPerformanceFeeSplit;
    /// @notice The manager management fee split
    uint256 managerManagementFeeSplit;
    /// @notice Whether to override the default fees
    bool overrideDefaults;
}

interface IFeeManager is IRecoverable, IERC165 {
    /// @notice An event that is emitted when fees are collected
    event Collected(address indexed asset, address indexed strategy, uint256 performanceFee, uint256 managementFee, uint256 establishmentFee);

    /// @notice An event that is emitted when protocol fees are withdrawn
    event Withdraw(address indexed asset, address indexed strategy, address indexed receiver, uint256 amount);

    /// @notice An event that is emitted when the fee structure is set
    event FeeStructureSet(address indexed strategy, FeeStructure feeStructure);

    /// @notice An event that is emitted when the pending fee structure is set
    event PendingFeeStructureSet(address indexed strategy, FeeStructure feeStructure);

    /// @notice An event that is emitted when the performance fee is set
    event PerformanceFeeSet(address indexed strategy, uint256 performanceFee);

    /// @notice An event that is emitted when the prepayment fee is set
    event PrepaymentFeeSet(address indexed strategy, uint256 prepaymentFee);

    /// @notice An event that is emitted when the treasury is set
    event TreasurySet(address indexed oldTreasury, address indexed newTreasury);

    /// @notice Collects strategy fees
    /// @param asset The address of the asset
    /// @param performanceFee The performance fee
    /// @param managementFee The management fee
    /// @param establishmentFee The establishment fee
    function collect(address asset, uint256 performanceFee, uint256 managementFee, uint256 establishmentFee) external;

    /// @notice Approves the pending fee structure
    /// @param strategy The address of the strategy
    function approvePendingFeeStructure(address strategy) external;

    /// @notice Withdraws protocol fees
    /// @param asset The address of the asset
    function withdrawProtocolFee(address asset) external;

    /// @notice Withdraws manager fees
    /// @param receiver The address of the receiver
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy
    function withdrawManagerFee(address receiver, address asset, address strategy) external;

    /// @notice Sets the fee structure
    /// @param strategy The address of the strategy
    /// @param feeStructure The fee structure
    function setFeeStructure(address strategy, FeeStructure memory feeStructure) external;

    /// @notice Sets the pending fee structure
    /// @param strategy The address of the strategy
    /// @param feeStructure The fee structure
    function setPendingFeeStructure(address strategy, FeeStructure memory feeStructure) external;

    /// @notice Sets the performance fee
    /// @param strategy The address of the strategy
    /// @param performanceFee The performance fee
    function setPerformanceFee(address strategy, uint256 performanceFee) external;

    /// @notice Sets the prepayment fee
    /// @param strategy The address of the strategy
    /// @param prepaymentFee The prepayment fee
    function setPrepaymentFee(address strategy, uint256 prepaymentFee) external;

    /// @notice Sets the treasury
    /// @param treasury The address of the treasury
    function setTreasury(address treasury) external;

    /// @notice Returns the establishment fee
    /// @param strategy The address of the strategy
    /// @return The establishment fee
    function establishmentFee(address strategy) external view returns (uint256);

    /// @notice Returns the management fee
    /// @param strategy The address of the strategy
    /// @return The management fee
    function managementFee(address strategy) external view returns (uint256);

    /// @notice Returns the performance fee
    /// @param strategy The address of the strategy
    /// @return The performance fee
    function performanceFee(address strategy) external view returns (uint256);

    /// @notice Returns the manager split
    /// @param strategy The address of the strategy
    /// @param isPerformanceFee Whether the fee is a performance fee
    /// @return The manager split
    function managerSplit(address strategy, bool isPerformanceFee) external view returns (uint256);

    /// @notice Returns the protocol split
    /// @param strategy The address of the strategy
    /// @param isPerformanceFee Whether the fee is a performance fee
    /// @return The protocol split
    function protocolSplit(address strategy, bool isPerformanceFee) external view returns (uint256);

    /// @notice Returns the prepayment fee
    /// @param strategy The address of the strategy
    /// @return The prepayment fee
    function prepaymentFee(address strategy) external view returns (uint256);

    /// @notice Returns the fee structure
    /// @param strategy The address of the strategy
    /// @return The fees percentages for the strategy
    function feeStructure(address strategy) external view returns (FeeStructure memory);

    /// @notice Returns the pending fee structure
    /// @param strategy The address of the strategy
    /// @return The pending fee structure
    function pendingFeeStructure(address strategy) external view returns (FeeStructure memory);

    /// @notice Returns the treasury
    /// @return The treasury
    function treasury() external view returns (address);

    /// @notice Returns the manager fees
    /// @param manager The address of the manager
    /// @param asset The address of the asset
    /// @param strategy The address of the strategy
    /// @return The manager fees of a given strategy
    function managerFees(address manager, address asset, address strategy) external view returns (uint256);

    /// @notice Returns the total manager fees
    /// @param manager The address of the manager
    /// @param asset The address of the asset
    /// @param strategies The addresses of the strategies
    /// @return The total manager fees of a given asset and strategies
    function managerTotalFees(address manager, address asset, address[] calldata strategies)
        external
        view
        returns (uint256);

    /// @notice Returns the protocol fees
    /// @param asset The address of the asset
    /// @return The protocol fees
    function protocolFees(address asset) external view returns (uint256);

    /// @notice The basis points for the fee manager
    /// @return The basis points
    function BASIS_POINTS() external pure returns (uint256);
}
