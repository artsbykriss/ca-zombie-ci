// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

bytes32 constant SSLOT_HYPERCORE_TREASURY = bytes32(uint256(keccak256("hypercore.treasury")) - 1);
bytes32 constant SSLOT_HYPERCORE_AUTHORIZER = bytes32(uint256(keccak256("hypercore.authorizer")) - 1);
bytes32 constant SSLOT_HYPERCORE_ROUTINGTABLE = bytes32(uint256(keccak256("hypercore.routingTable")) - 1);
bytes32 constant SSLOT_HYPERCORE_POOLBALANCES = bytes32(uint256(keccak256("hypercore.poolBalances")) - 1);
bytes32 constant SSLOT_HYPERCORE_USERBALANCES = bytes32(uint256(keccak256("hypercore.userBalances")) - 1);
bytes32 constant SSLOT_HYPERCORE_EMISSIONINFORMATION = bytes32(uint256(keccak256("hypercore.emissionInformation")) - 1);
bytes32 constant SSLOT_REENTRACNYGUARD_LOCKED = bytes32(uint256(keccak256("ReentrancyGuard.locked")) - 1);
bytes32 constant SSLOT_PAUSABLE_PAUSED = bytes32(uint256(keccak256("Pausable.paused")) - 1);

struct VelocoreOperation {
    bytes32 poolId;
    bytes32[] tokenInformations;
    bytes data;
}

interface IVault {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function execute(bytes32[] calldata tokenRef, int128[] memory deposit, VelocoreOperation[] calldata ops)
        external
        payable;
    function execute1(address pool, uint8 method, address t1, uint8 m1, int128 a1, bytes memory data)
        external
        payable
        returns (int128[] memory);

    function query1(address pool, uint8 method, address t1, uint8 m1, int128 a1, bytes memory data)
        external
        returns (int128[] memory);

    function execute2(
        address pool,
        uint8 method,
        address t1,
        uint8 m1,
        int128 a1,
        address t2,
        uint8 m2,
        int128 a2,
        bytes memory data
    ) external payable returns (int128[] memory);

    function query2(
        address pool,
        uint8 method,
        address t1,
        uint8 m1,
        int128 a1,
        address t2,
        uint8 m2,
        int128 a2,
        bytes memory data
    ) external returns (int128[] memory);

    function execute3(
        address pool,
        uint8 method,
        address t1,
        uint8 m1,
        int128 a1,
        address t2,
        uint8 m2,
        int128 a2,
        address t3,
        uint8 m3,
        int128 a3,
        bytes memory data
    ) external payable returns (int128[] memory);

    function query3(
        address pool,
        uint8 method,
        address t1,
        uint8 m1,
        int128 a1,
        address t2,
        uint8 m2,
        int128 a2,
        address t3,
        uint8 m3,
        int128 a3,
        bytes memory data
    ) external returns (int128[] memory);

    function getPair(address t0, address t1) external view returns (address);

    function allPairs(uint256 i) external view returns (address);

    function allPairsLength() external view returns (uint256);
}
