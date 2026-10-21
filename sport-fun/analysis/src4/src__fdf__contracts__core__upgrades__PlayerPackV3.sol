// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IPlayer} from "src/fdf/contracts/interfaces/IPlayer.sol";
import {IPlayerPack} from "src/fdf/contracts/interfaces/IPlayerPack.sol";

/**
 * @title PlayerPackV3 contract.
 */
contract PlayerPackV3 is Initializable, AccessControlUpgradeable, UUPSUpgradeable, IPlayerPack {
    // Roles.
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PACK_ISSUER_ROLE = keccak256("PACK_ISSUER_ROLE");

    // Enable or disable the pack sale.
    bool public saleEnabled;

    // Number of players in a pack.
    uint32 public packSize;

    // PackType to share limits.
    mapping(PackType => uint256[]) public packTypeToShareLimits;

    //Player integration
    IPlayer public playerContract;

    // DevelopmentPlayers contract address
    address public developmentPlayersContract;

    // Salt for hashing
    uint256 private packNonce;

    // V2 addition: version tracking
    uint256 public upgradeVersion;

    // Max pack size for off-chain pack opening
    uint256 public maxPackSize;

    // Max shares allowed per player in off-chain pack opening
    uint256 public maxSharesPerPlayer;

    // Identifiers of processed requests
    mapping(uint256 => bool) public processedRequestIds;

    // Storage gap for future upgrades
    uint256[46] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the V3 upgrade
     * @dev This function should be called after upgrading to V3
     */
    function initializeV3() external onlyRole(GOVERNOR_ROLE) {
        require(upgradeVersion == 2, "Already initialized");
        upgradeVersion = 3;

        maxPackSize = 3;
        maxSharesPerPlayer = 50_000 * 10 ** 18;
    }

    /**
     * Open a player pack and mint players to their wallet.
     * @param _packType The type of the pack being opened.
     * @param _packBuyerAddress The address to send the players to.
     */
    function openPlayerPack(PackType _packType, address _packBuyerAddress) external onlyRole(PACK_ISSUER_ROLE) {
        if (!saleEnabled) revert SaleNotEnabled();
        if (_packType == PackType.UNASSIGNED) revert InvalidPackType();
        if (_packBuyerAddress == address(0)) revert ZeroAddress();

        uint256 activePlayersLength = playerContract.getActivePlayerCount();
        if (activePlayersLength < packSize) revert InsufficientPlayers();

        packNonce++;

        _distributePlayers(_packType, _packBuyerAddress, packNonce, activePlayersLength);
    }

    /**
     * @notice Open a player pack using off-chain selected players and share amounts.
     * @param _packBuyerAddress The address to send the players to.
     * @param _playerIds The player IDs to distribute.
     * @param _amounts The share amounts for each player.
     * @param _requestId Request Id for idempotency
     */
    function openPlayerPackV2(
        address _packBuyerAddress,
        uint256[] calldata _playerIds,
        uint256[] calldata _amounts,
        uint256 _requestId
    ) external onlyRole(PACK_ISSUER_ROLE) {
        if (!saleEnabled) revert SaleNotEnabled();
        if (processedRequestIds[_requestId]) revert RequestAlreadyProcessed();
        if (_packBuyerAddress == address(0)) revert ZeroAddress();

        uint256 length = _playerIds.length;
        if (length == 0 || length > maxPackSize) revert InvalidPackSize();
        if (_amounts.length != length) {
            revert InvalidPackSize();
        }

        _validatePackInputs(_playerIds, _amounts, length);

        processedRequestIds[_requestId] = true;

        playerContract.safeBatchTransferFrom(address(playerContract), _packBuyerAddress, _playerIds, _amounts, "");

        emit PackOpened(_packBuyerAddress, _playerIds, _amounts, new uint256[](length));

        emit RequestProcessed(_requestId);
    }

    /**
     * @notice Set the maximum allowed pack size for off-chain pack opening.
     * @param _maxPackSize The new max pack size.
     */
    function setMaxPackSize(uint256 _maxPackSize) external onlyRole(GOVERNOR_ROLE) {
        if (_maxPackSize == 0) revert InvalidPackSize();
        maxPackSize = _maxPackSize;
    }

    /**
     * @notice Set the maximum shares allowed per player for off-chain pack opening.
     * @param _maxSharesPerPlayer The new max shares per player.
     */
    function setMaxSharesPerPlayer(uint256 _maxSharesPerPlayer) external onlyRole(GOVERNOR_ROLE) {
        if (_maxSharesPerPlayer == 0) revert InvalidShares();
        maxSharesPerPlayer = _maxSharesPerPlayer;
    }

    /**
     * Optimized function to distribute players using on-chain randomness.
     * Combines randomness generation and distribution to save gas.
     * Ensures unique players per pack.
     * @param _packType The type of the pack being opened
     * @param _packBuyerAddress The address to send the players to
     * @param _nonce The nonce used for this pack (used as a salt)
     * @param _activePlayersLength The length of the active players array.
     */
    function _distributePlayers(
        PackType _packType,
        address _packBuyerAddress,
        uint256 _nonce,
        uint256 _activePlayersLength
    ) internal {
        // Create arrays in memory
        uint256[] memory playerIds = new uint256[](packSize);
        uint256[] memory shares = new uint256[](packSize);
        uint256[] memory randomNumbers = new uint256[](packSize);

        // Track selected pack players to prevent duplicates.
        bool[] memory isPlayerSelected = new bool[](_activePlayersLength);

        // Initial entropy seed
        uint256 entropy = uint256(keccak256(abi.encodePacked(_nonce, block.timestamp, block.prevrandao, msg.sender)));

        uint256 minShares = packTypeToShareLimits[_packType][0];
        uint256 maxShares = packTypeToShareLimits[_packType][1];

        // Fill the pack with unique random playerIds and shares
        for (uint256 i = 0; i < packSize;) {
            uint256 attempts = 0;
            uint256 randomIndex;
            uint256 finalRandomWord; // Store the final random word used

            // Keep trying until we find a unique player
            do {
                // Get blockhash-based randomness
                uint256 randomWord =
                    uint256(blockhash(block.number > (entropy & 0xff) + 1 ? block.number - 1 - (entropy & 0xff) : 0));

                // Store the random word used for the selection
                finalRandomWord = randomWord;

                // Generate random playerId index
                randomIndex =
                    uint256(keccak256(abi.encodePacked(_nonce, randomWord, i, attempts))) % _activePlayersLength;

                // Roll entropy for next iteration
                entropy = uint256(keccak256(abi.encodePacked(_nonce, entropy, randomWord, i, attempts)));

                attempts++;

                // Safety check to prevent infinite loops (should never happen)
                if (attempts > 50) {
                    revert InfiniteLoopSafeGuard();
                }
            } while (isPlayerSelected[randomIndex]);

            //Mark this player index as selected.
            isPlayerSelected[randomIndex] = true;

            //Store the random word used in an array.
            randomNumbers[i] = finalRandomWord;

            playerIds[i] = playerContract.getActivePlayerByIndex(randomIndex);

            shares[i] = minShares
                + (uint256(keccak256(abi.encodePacked(_nonce, finalRandomWord, i))) % (maxShares - minShares + 1));

            // Roll entropy for next iteration using the final random word
            entropy = uint256(keccak256(abi.encodePacked(_nonce, entropy, finalRandomWord, i)));

            unchecked {
                i++;
            }
        }

        //Encode pack openers address
        bytes memory transferData = abi.encode(_packBuyerAddress);

        //Send players to development players contract.
        playerContract.safeBatchTransferFrom(
            address(playerContract), developmentPlayersContract, playerIds, shares, transferData
        );

        emit PackOpened(_packBuyerAddress, playerIds, shares, randomNumbers);
    }

    function _validatePackInputs(uint256[] calldata _playerIds, uint256[] calldata _amounts, uint256 length)
        internal
        view
    {
        for (uint256 i = 0; i < length;) {
            if (_amounts[i] == 0) revert InvalidShares();
            if (_amounts[i] > maxSharesPerPlayer) revert InvalidShares();
            for (uint256 j = i + 1; j < length;) {
                if (_playerIds[i] == _playerIds[j]) revert InvalidPackSize();
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * Get the min and max shares range that can be set for the pack type.
     * @param _packType The pack type.
     * @return _minShares The minimum shares per player for the pack type.
     * @return _maxShares The maximum shares per player for the pack type.
     */
    function getPackTypeToSharesPerPlayer(PackType _packType) external view returns (uint256, uint256) {
        if (_packType == PackType.UNASSIGNED) revert InvalidPackType();

        return (packTypeToShareLimits[_packType][0], packTypeToShareLimits[_packType][1]);
    }

    /**
     * Allow admins to set the share limits for different pack types.
     * @param _packType The pack type.
     * @param _minShares The minimum shares per player for the pack type.
     * @param _maxShares The maximum shares per player for the pack type.
     */
    function setPackTypeToShareLimits(PackType _packType, uint256 _minShares, uint256 _maxShares)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (_packType == PackType.UNASSIGNED) revert InvalidPackType();
        if (_minShares == 0 || _maxShares == 0 || _minShares > _maxShares || _minShares < 10 ** 18) {
            revert InvalidShares();
        }

        packTypeToShareLimits[_packType] = [_minShares, _maxShares];

        emit PackTypeToShareLimitsSet(_packType, _minShares, _maxShares);
    }

    /**
     * Allow governors to set the address of the Player contract.
     * @param _playerContract Player.sol address.
     */
    function setPlayerContract(address _playerContract) external onlyRole(GOVERNOR_ROLE) {
        if (_playerContract == address(0)) revert ZeroAddress();

        playerContract = IPlayer(_playerContract);

        emit PlayerContractSet(_playerContract);
    }

    /**
     * Allow governors to set the address of the DevelopmentPlayers contract.
     * @param _contractAddress DevelopmentPlayers.sol address.
     */
    function setDevelopmentPlayersContract(address _contractAddress) external onlyRole(GOVERNOR_ROLE) {
        if (_contractAddress == address(0)) revert ZeroAddress();

        developmentPlayersContract = _contractAddress;

        emit DevelopmentPlayersContractSet(_contractAddress);
    }

    /**
     * Allow admins to set the pack configuration.
     * @param _packSize The total number of players in a pack.
     */
    function setPackSize(uint32 _packSize) external onlyRole(GOVERNOR_ROLE) {
        if (_packSize == 0) revert InvalidPackSize();

        packSize = _packSize;

        emit PackSizeSet(_packSize);
    }

    /**
     * Allow admins to set the sale enabled status.
     * @param _saleEnabled The new sale enabled status.
     */
    function setSaleEnabled(bool _saleEnabled) external onlyRole(ADMIN_ROLE) {
        saleEnabled = _saleEnabled;

        emit SaleEnabled(_saleEnabled);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IPlayerPack).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Authorize upgrade function (required by UUPSUpgradeable).
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(GOVERNOR_ROLE) {}
}
