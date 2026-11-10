// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Minimal fake "snapshot token" used as the caller-supplied `proRataToken`.
///         FeeDisbursal only ever calls currentSnapshotId(), totalSupplyAt() and
///         balanceOfAt() on it, and never validates that it is a real token.
///         currentSnapshotId() advances with block.number so that the disbursal
///         created in block N is claimable from block N+1 onwards (FeeDisbursal
///         refuses to pay out disbursals recorded against the *current* snapshot).
contract FakeSnapshotToken {
    uint256 public immutable claimAmount;

    constructor(uint256 claimAmount_) {
        claimAmount = claimAmount_;
    }

    function currentSnapshotId() external view returns (uint256) {
        return block.number;
    }

    function totalSupplyAt(uint256) external pure returns (uint256) {
        return 1;
    }

    function balanceOfAt(address, uint256) external view returns (uint256) {
        return claimAmount;
    }

    // Present only so the contract looks token-ish to casual readers.
    function totalSupply() external pure returns (uint256) {
        return 1;
    }

    function balanceOf(address) external view returns (uint256) {
        return claimAmount;
    }
}
