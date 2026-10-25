// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

library MainnetProductionTimelockPolicy {
    address internal constant PILOT_TIMELOCK = 0xEd33edB1eA442475eFd076e1AE2C9da9EdaB86f6;
    address internal constant ADMIN_SAFE = 0xA8331cFA52BC67a468D6126b4A18419C6D830b4E;
    address internal constant GUARDIAN_SAFE = 0xC89592b35278B6Bbba2b710acd463E7A3C8D0Eb0;
    address internal constant ALLOCATOR_SAFE = 0x34b8Edd6E6B8032cCDb930722486edd2Ac9134B5;
    address internal constant TREASURY_SAFE = 0x739b9e6BeB4C278DFc327523880fdBafe4BD129D;
    address internal constant PIL_RECIPIENT_SAFE = 0x3CC1e7987a1459c7374AfBAEe104d1D65F07E658;
    uint256 internal constant MIN_DELAY = 12 hours;
    uint256 internal constant RUNTIME_CODE_LENGTH = 7_454;
    bytes32 internal constant RUNTIME_CODEHASH = 0xfbb8dca0ef620c28593dafd8ead5162f233db640a9ebfdc4d47a7920cc06b2af;

    error PilotTimelockForbidden();
    error RuntimeCodehashMismatch();
    error MinDelayMismatch(uint256 actual);
    error RoleMismatch();
    error RoleHolderMismatch();
    error GovernanceEvidenceMismatch();

    function requireValid(address timelockAddress) internal view {
        if (timelockAddress == PILOT_TIMELOCK) revert PilotTimelockForbidden();
        if (timelockAddress.code.length != RUNTIME_CODE_LENGTH || timelockAddress.codehash != RUNTIME_CODEHASH) {
            revert RuntimeCodehashMismatch();
        }
        uint256 delay = TimelockController(payable(timelockAddress)).getMinDelay();
        if (delay != MIN_DELAY) revert MinDelayMismatch(delay);
        TimelockController timelock = TimelockController(payable(timelockAddress));
        if (
            !timelock.hasRole(timelock.PROPOSER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.EXECUTOR_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.CANCELLER_ROLE(), ADMIN_SAFE)
                || !timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), timelockAddress)
                || timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), ADMIN_SAFE)
                || timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0))
        ) revert RoleMismatch();
    }

    function requireGovernanceEvidenceBinding(
        bytes memory evidence,
        bytes32 expectedSha256,
        address evidenceTimelock,
        address expectedTimelock
    ) internal pure {
        if (expectedSha256 == bytes32(0) || sha256(evidence) != expectedSha256 || evidenceTimelock != expectedTimelock) revert GovernanceEvidenceMismatch();
    }

    function requireRoleHolders(
        address treasury,
        address interestRouterRecipient,
        address guardian,
        address allocator,
        address writeoff,
        address priceFeedOwner
    ) internal pure {
        if (
            treasury != TREASURY_SAFE || interestRouterRecipient != PIL_RECIPIENT_SAFE || guardian != GUARDIAN_SAFE
                || allocator != ALLOCATOR_SAFE || writeoff != ADMIN_SAFE || priceFeedOwner != ADMIN_SAFE
        ) revert RoleHolderMismatch();
    }
}
