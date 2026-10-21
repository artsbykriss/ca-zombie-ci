// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IPlayer interface
 * @notice Interface for Player.sol contract
 */
interface IPlayer is IERC1155 {

    // Events
    event BaseURIChanged(string newBaseURI);
    event PlayerActivated(uint256 indexed playerId);
    event PlayerDeactivated(uint256 indexed playerId);
    event PlayerBuyingEnabled(uint256 indexed playerId);
    event PlayerBuyingDisabled(uint256 indexed playerId);
    event PlayerSellingEnabled(uint256 indexed playerId);
    event PlayerSellingDisabled(uint256 indexed playerId);
    event PlayerTransfer(address indexed from, address indexed to, uint256 indexed id, uint256 amount);
    event PlayerBatchTransfer(address indexed from, address indexed to, uint256[] ids, uint256[] amounts);
    event PlayerPackSet(address indexed playerPack);
    event PlayerReactivated(uint256 indexed playerId);
    event ApprovalSet(address indexed operator, bool approved);
    event PlayerSentToExchange(uint256[] playerIds, uint256[] amounts, uint256[] maxCurrencyDeposit);
    event AddressWhitelisted(address indexed account, bool whitelisted);
    event AllTradingToggled(bool allowAllTrading);
    event TxSignerAdded(address indexed newTxSigner);
    event TxSignerRemoved(address indexed removedTxSigner);
    event AuthorisedSellTokens(address indexed from, uint256[] playerTokenIds, uint256[] amounts, uint256 minCurrencyToReceive);
    event NonceReset(address indexed user, uint256 newNonce);
    event MinPlayerSharesDepositChanged(uint256 newMinPlayerSharesDeposit);
    event MinCurrencyDepositForPlayerChanged(uint256 newMinCurrencyDepositForPlayer);
    event SupplyManagerRoleGranted(address indexed depositor);
    event SupplyManagerRoleRevoked(address indexed depositor);
    event SupplyReturned(uint256[] playerIds, uint256[] shares);
    event SupplyPulled(uint256[] playerIds, uint256[] shares);
    event PlayerPackContractChanged(address indexed newPlayerPack);
    event FdfPairContractChanged(address indexed newFdfPair);
    event DevelopmentPlayersContractChanged(address indexed newDevelopmentPlayers);
    event CurrencyTokenContractChanged(address indexed newCurrencyToken);
    event FeeManagerContractChanged(address indexed newFeeManager);
    event PlayerTradingEnabled(uint256 indexed playerId);

    // Errors
    error ZeroAddress();
    error PlayerIdCannotBeZero();
    error PlayerDoesNotExist();
    error PlayerAlreadyActive();
    error PlayerAlreadyBuyable();
    error PlayerAlreadySellable();
    error PlayerAlreadyNotBuyable();
    error PlayerAlreadyNotSellable();
    error PlayerAlreadyExist();
    error PlayerAlreadyDeactivated();
    error PlayerNotBuyable();
    error PlayerNotSellable();
    error BaseURIMustBeEmpty();
    error BaseURICannotBeEmpty();
    error PlayerIdsCannotBeEmpty();
    error ApprovalFailed();
    error PlayerIndexOutOfBounds();
    error InvalidSignature();
    error UnauthorisedTransfer();
    error InvalidDeadline();
    error ArrayLengthMismatch();
    error InvalidNonce();
    error InvalidAmount();
    error InvalidCurrencyDeposit();
    error TxSignerAlreadyExists();
    error TxSignerCannotBeRemoved();
    error TxSignerNotFound();
    
    /**
     * @notice Create multiple players and transfer them to the DEX.
     * @param _playerIds The player ids of the players.
     * @param _amounts The amounts of the players.
     * @param _maxCurrencyDeposit The max currency deposit of the players.
     * @param _deadline The deadline of the transaction.
     */
    function createPlayers(
        uint256[] calldata _playerIds, 
        uint256[] calldata _amounts, 
        uint256[] calldata _maxCurrencyDeposit, 
        uint256 _deadline
    ) external;

    /**
     * @notice Returns player shares back into the pool.
     * @param _playerIds Array of player ids.
     * @param _amounts Array of amounts.
     */
    function returnSupply(uint256[] calldata _playerIds, uint256[] calldata _amounts) external;

    /**
     * @notice Pulls supply of shares for one or more players.
     * @dev Only callable by addresses with the SUPPLY_MANAGER role.
     * @param _playerIds Array of player IDs.
     * @param _shares Array of shares to allocate per player.
     */
    function requestSupply(uint256[] calldata _playerIds, uint256[] calldata _shares) external;

    /**
     * @notice Reactivate a player
     * @param playerId The player id of the player
     */
    function reactivatePlayer(uint256 playerId) external;

    /**
     * @notice Deactivate a player
     * @param playerId The player id of the player
     */
    function deactivatePlayer(uint256 playerId) external;

    /**
     * @notice Enable buying for a player
     * @param playerId The player id of the player
     */
    function enableBuying(uint256 playerId) external;

    /**
     * @notice Enable selling for a player
     * @param playerId The player id of the player
     */
    function enableSelling(uint256 playerId) external;

    /**
     * @notice Disable buying for a player
     * @param playerId The player id of the player
     */
    function disableBuying(uint256 playerId) external;

    /**
     * @notice Disable selling for a player
     * @param playerId The player id of the player
     */
    function disableSelling(uint256 playerId) external;

    /**
     * Authorised sell function that requires signature verification.
     * This is the ONLY way users can sell tokens to the DEX.
     * @param _playerTokenIds Array of token IDs to sell.
     * @param _amounts Array of amounts to sell.
     * @param _minCurrencyToReceive Minimum currency to receive from the sale.
     * @param _deadline Deadline after which signature expires.
     * @param _signature Signature from the game backend authorising this sale.
     * @param _nonce Nonce for replay protection.
     */
    function sellTokens(uint256[] calldata _playerTokenIds, uint256[] calldata _amounts, uint256 _minCurrencyToReceive, uint256 _deadline, bytes calldata _signature, uint256 _nonce) external;

    /**
     * @notice Reset the nonce for a user.
     * @param _user The user to reset the nonce for.
     * @param _newNonce The new nonce to set.
     */
    function resetUserNonce(address _user, uint256 _newNonce) external;

    /**
     * Get the current nonce for a user.
     * @param _user The user to get the nonce for.
     * @return The current nonce for the user.
     */
    function getCurrentNonce(address _user) external view returns (uint256);
    
    /**
     * @notice Get the number of active players
     * @return The number of active players
     */
    function getActivePlayerCount() external view returns (uint256);

    /**
     * @notice Get the active player ids
     * @return The active player ids
     */
    function getActivePlayerIds() external view returns (uint256[] memory);

    /**
     * @notice Get the active player by index
     * @param _index The index of the active player
     * @return The active player id
     */
    function getActivePlayerByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Check if a player exists in the pool
     * @param playerId The player id of the player
     * @return True if the player exists in the pool, false otherwise
     */
    function existsInPool(uint256 playerId) external view returns (bool);
    
    /**
     * Check if a player is active.
     * @param _playerId playerId of the player.
     * @return True if the player is active, false otherwise.
     */
    function isActive(uint256 _playerId) external view returns (bool);

    /**
     * Check if a player is buyable.
     * @param _playerId playerId of the player.
     * @return True if the player is buyable, false otherwise.
     */
    function isBuyable(uint256 _playerId) external view returns (bool);

    /**
     * Check if a player is sellable.
     * @param _playerId playerId of the player.
     * @return True if the player is sellable, false otherwise.
     */
    function isSellable(uint256 _playerId) external view returns (bool);

    /**
     * Get the minimum player shares deposit threshold.
     * @return The minimum player shares deposit.
     */
    function getMinPlayerSharesDeposit() external view returns (uint256);

    /**
     * Get the minimum currency deposit per player threshold.
     * @return The minimum currency deposit per player.
     */
    function getMinCurrencyDepositForPlayer() external view returns (uint256);

    /**
     * Get the txSigners.
     * @return The txSigners.
     */
    function getTxSigners() external view returns (address[] memory);

    /**
     * @notice Grant the SUPPLY_MANAGER role to an address.
     * @param _address The address to grant the SUPPLY_MANAGER role to.
     */
    function grantSupplyManagerRole(address _address) external;

    /**
     * @notice Revoke the SUPPLY_MANAGER role from an address.
     * @param _address The address to revoke the SUPPLY_MANAGER role from.
     */
    function revokeSupplyManagerRole(address _address) external;

    /**
     * @notice Add a new txSigner address for signature verification
     * @param _newTxSigner the new txSigner address
     */
    function addTxSigner(address _newTxSigner) external;

    /**
     * @notice Remove a txSigner address for signature verification
     * @param _txSigner the txSigner address to remove
     */
    function removeTxSigner(address _txSigner) external;

    /**
     * Sets the player pack address.
     * @param _playerPack The new player pack address.
     */
    function setPlayerPack(address _playerPack) external;

    /**
     * Sets the FDF pair address.
     * @param _fdfPair The new FDF pair address.
     */
    function setFdfPair(address _fdfPair) external;

    /**
     * Sets the development players address.
     * @param _developmentPlayers The new development players address.
     */
    function setDevelopmentPlayers(address _developmentPlayers) external;

    /**
     * Sets the currency token address.
     * @param _currencyToken The new currency token address.
     */
    function setCurrencyToken(address _currencyToken) external;

    /**
     * Sets the fee manager address.
     * @param _feeManager The new fee manager address.
     */
    function setFeeManager(address _feeManager) external;
}