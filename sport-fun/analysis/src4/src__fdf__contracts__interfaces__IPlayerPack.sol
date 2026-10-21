// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IPlayerPack {

    // All of the pack types.
    enum PackType { UNASSIGNED, PRO, EPIC, LEGENDARY }

    // Events
    event PackOpened(
        address indexed destinationAddress,
        uint256[] playerIds,
        uint256[] amounts,
        uint256[] randomNumbers
    );
    event RequestProcessed(
        uint256 indexed requestId
    );
    event PackTypeToShareLimitsSet(PackType indexed packType, uint256 minShares, uint256 maxShares);
    event PlayerContractSet(address indexed playerContract);
    event DevelopmentPlayersContractSet(address indexed developmentPlayersContract);
    event PackIssuerRoleSet(address indexed packIssuer);
    event PackSizeSet(uint32 packSize);
    event PacksDistributorSet(address indexed packDistributor);
    event SaleEnabled(bool saleEnabled);

    // Errors
    error InvalidPackSize();
    error InsufficientPlayers();
    error InvalidPackType();
    error InvalidShares();
    error SaleNotEnabled();
    error ZeroAddress();
    error InfiniteLoopSafeGuard();
    error RequestAlreadyProcessed();

    // Functions
    function openPlayerPack(PackType _packType, address _packBuyerAddress) external;
    function getPackTypeToSharesPerPlayer(PackType _packType) external view returns (uint256, uint256);
    function setPackTypeToShareLimits(PackType _packType, uint256 _minShares, uint256 _maxShares) external;
    function setPlayerContract(address _playerContract) external;
    function setDevelopmentPlayersContract(address _contractAddress) external;
    function setPackSize(uint32 _packSize) external;
    function setSaleEnabled(bool _saleEnabled) external;
}