// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of UNCX VestingManager (V2), deployed build 18,010 bytes.
///         Field order matches the verified source / on-chain ABI:
///         vestingSchedules(uint256) returns
///         token, creator, beneficiary, totalAmount, released, isSoft, isNftized,
///         cancelled, isTopable, vestingType.
interface IVestingManager {
    struct TimeAmount {
        uint256 time;
        uint256 amount;
        uint8 eqType;
    }

    struct VestingSchedule {
        address token;
        address creator;
        address beneficiary;
        uint256 totalAmount;
        uint256 released;
        bool isSoft;
        bool isNftized;
        bool cancelled;
        bool isTopable;
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
    function transferVesting(uint256 vestingId, address newBeneficiary) external;
    function mintVestingNFT(uint256 vestingId) external;

    function getVestingSchedule(uint256 vestingId) external view returns (VestingSchedule memory);
    function vestingSchedules(uint256 vestingId)
        external
        view
        returns (
            address token,
            address creator,
            address beneficiary,
            uint256 totalAmount,
            uint256 released,
            bool isSoft,
            bool isNftized,
            bool cancelled,
            bool isTopable,
            uint8 vestingType
        );
    function getVestedAmount(uint256 vestingId) external view returns (uint256);
    function getReleasableAmount(uint256 vestingId) external view returns (uint256);
    function _getReleasableShares(uint256 vestingId) external view returns (uint256);

    function nextVestingId() external view returns (uint256);
    function flatFee() external view returns (uint256);
    function feePercentage() external view returns (uint256);
    function feeCollector() external view returns (address);
    function owner() external view returns (address);
    function calculator() external view returns (address);
    function feeExemptCreators(address creator) external view returns (bool);
    function feeExemptTokens(address token) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}
