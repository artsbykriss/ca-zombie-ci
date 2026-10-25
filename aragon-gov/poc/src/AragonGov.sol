// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Minimal interfaces + Aragon EVM-script encoder for the P7-01 PoC.
/// Read-only against mainnet state; all state-changing calls happen on a local fork.

interface IACL {
    function getPermissionManager(address _app, bytes32 _role) external view returns (address);
    function hasPermission(address _who, address _where, bytes32 _what, bytes calldata _how)
        external view returns (bool);
    function grantPermission(address _entity, address _app, bytes32 _role) external;
}

interface IVoting {
    function newVote(bytes calldata _executionScript, string calldata _metadata) external returns (uint256);
    function vote(uint256 _voteId, bool _supports, bool _executesIfDecided) external;
    function executeVote(uint256 _voteId) external;
    function votesLength() external view returns (uint256);
    function voteTime() external view returns (uint64);
    function supportRequiredPct() external view returns (uint64);
    function minAcceptQuorumPct() external view returns (uint64);
    function canForward(address _sender, bytes calldata _evmScript) external view returns (bool);
}

interface IAgent {
    function transfer(address _token, address _to, uint256 _value) external;
}

interface ITokenManager {
    function forward(bytes calldata _evmScript) external;
    function canForward(address _sender, bytes calldata _evmScript) external view returns (bool);
}

interface IMiniMeToken {
    function generateTokens(address _to, uint256 _amount) external returns (bool);
    function controller() external view returns (address);
    function balanceOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);
    function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

library Script {
    /// aragonOS CallsScript: [uint32 specId=1][to(20)][len(4)][data]...
    function encodeCalls(address[] memory to, bytes[] memory data) internal pure returns (bytes memory script) {
        script = abi.encodePacked(uint32(1));
        for (uint256 i = 0; i < to.length; i++) {
            script = abi.encodePacked(script, to[i], uint32(data[i].length), data[i]);
        }
    }
}
