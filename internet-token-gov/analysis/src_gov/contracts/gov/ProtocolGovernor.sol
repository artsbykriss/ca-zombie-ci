// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

import "../role/RoleModule.sol";

contract ProtocolGovernor is
    RoleModule,
    Governor,
    GovernorSettings,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{

    event CancelWithReason(string reason);

    struct ConstructorParams {
        string name;
        string version;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
        uint256 quorumNumeratorValue;
    }

    string private _version;

    constructor(
        RoleStore _roleStore,
        IVotes token_,
        TimelockController timelock_,
        ConstructorParams memory params
    )
        RoleModule(_roleStore)
        Governor(params.name)
        GovernorVotes(token_)
        GovernorSettings(params.votingDelay, params.votingPeriod, params.proposalThreshold)
        GovernorVotesQuorumFraction(params.quorumNumeratorValue)
        GovernorTimelockControl(timelock_)
    {
        _version = params.version;
    }

    function clock() public view override(GovernorVotes, IGovernor) returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view override(GovernorVotes, IGovernor) returns (string memory) {
        // Check that the clock was not modified
        require(clock() == block.timestamp, "ERC20Votes: broken clock mode");
        return "mode=timestamp";
    }

    function version() public view override(Governor, IGovernor) returns (string memory) {
        return _version;
    }

    // allows cancellation of malicious proposals until the DAO is fully setup
    function cancelWithReason(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        string memory reason
    ) public onlyRole(Role.PROPOSAL_ADMIN)  returns (uint256) {
        emit CancelWithReason(reason);
        // the _cancel function validates that the proposal
        // state is not Canceled, Expired, Executed
        return _cancel(targets, values, calldatas, descriptionHash);
    }

    // The functions below are overrides required by Solidity.

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function state(
        uint256 proposalId
    ) public view override(Governor, IGovernor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.cancel(targets, values, calldatas, descriptionHash);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, IERC165, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
