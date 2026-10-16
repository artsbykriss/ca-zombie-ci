// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of UNCX VestingManager (V2) as deployed on ETH/BSC/Base/... and the
///         older "secondary" 14.4KB build (0xBcD6aee8...). Signatures verified against Etherscan
///         verified sources (VestingManager.sol, solc 0.8.27).
interface IVestingManager {
    struct TimeAmount {
        uint256 time;
        uint256 amount;   // cumulative amount until this time
        uint8 eqType;     // 0 LINEAR, 1 EXPONENTIAL, 2 INTERVAL, 3 QUADRATIC
    }

    struct VestingSchedule {
        address token;
        address creator;
        address beneficiary;
        uint256 totalAmount;
        uint256 released;
        bool isSoft;
        bool isNftized;
        bool isTopable;
        bool cancelled;
        uint8 vestingType;
        TimeAmount[] tranches;
    }

    function createVesting(
        address token,
        TimeAmount[] calldata tranches,
        address beneficiary,
        bool isSoft,
        bool isNftized,
        bool isTransferable,
        bool isTopable
    ) external payable returns (uint256);

    function createAirdropVesting(
        address token,
        TimeAmount[] calldata tranches,
        address[] calldata beneficiaries,
        bool isSoft,
        bool isNftized,
        bool isTransferable,
        bool isTopable
    ) external payable returns (uint256[] memory);

    function createDailySoftVesting(
        address token,
        TimeAmount[] calldata tranches,
        address beneficiary
    ) external payable returns (uint256);

    function topUpVesting(uint256 vestingId, TimeAmount[] calldata additionalTranches) external;
    function cancel(uint256 vestingId) external;
    function release(uint256 vestingId) external;

    function getVestingSchedule(uint256 vestingId) external view returns (VestingSchedule memory);
    function getVestedAmount(uint256 vestingId) external view returns (uint256);
    function getReleasableAmount(uint256 vestingId) external view returns (uint256);
    function _getReleasableShares(uint256 vestingId) external view returns (uint256);

    function nextVestingId() external view returns (uint256);
    function flatFee() external view returns (uint256);
    function feePercentage() external view returns (uint256);
    function feeCollector() external view returns (address);
    function owner() external view returns (address);
    function calculator() external view returns (address);
}
