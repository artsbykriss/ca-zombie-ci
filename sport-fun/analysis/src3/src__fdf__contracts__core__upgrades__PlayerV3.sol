// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC1155Upgradeable} from "@openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155HolderUpgradeable} from "@openzeppelin-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IPlayerV3} from "../../interfaces/upgrades/IPlayerV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFeeManager} from "../../interfaces/IFeeManager.sol";
import {IFDFPair} from "../../interfaces/IFDFPair.sol";
import {IFDFPairV3} from "../../interfaces/upgrades/IFDFPairV3.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PlayerV3 - V3 upgrade for Player contract
 * @notice Extends PlayerV2 by binding signed buy/sell/swap fee inputs into the V3 execution flow
 * @dev This contract is an **upgrade-only** implementation. It does not include the original
 * `initialize()` function (removed to reclaim bytecode space) and therefore cannot be deployed
 * behind a fresh proxy. It must be used exclusively as a UUPS upgrade to an existing Player/PlayerV2
 * proxy that has already been initialized.
 */
contract PlayerV3 is Initializable, ERC1155Upgradeable, ERC1155HolderUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, EIP712Upgradeable, IPlayerV3 {  

    using SafeERC20 for IERC20;
    using Strings for uint256;

    //Roles.
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SUPPLY_MANAGER = keccak256("SUPPLY_MANAGER");

    //EIP-712 TypeHash for selling authorisation.
    bytes32 internal constant SELL_TYPEHASH = keccak256(
        "SellTokensV3(address from,uint256[] playerTokenIds,uint256[] amounts,uint256 minCurrencyToReceive,uint256[] feeRateBps,int256[] discountFeeBps,uint256[] surgeEpochs,uint256 deadline,uint256 nonce)"
    );

    //EIP-712 TypeHash for swap authorisation.
    bytes32 internal constant SWAP_TYPEHASH = keccak256(
        "SwapTokensV3(address from,uint256[] playerTokenIdsIn,uint256[] playerTokenAmountsIn,uint256[] playerTokenIdsOut,uint256[] playerTokenAmountsOut,uint256[] sellFeeRateBps,int256[] sellDiscountFeeBps,uint256[] buyFeeRateBps,int256[] buyDiscountFeeBps,uint256[] surgeEpochsIn,address recepient,uint256 deadline,uint256 nonce)"
    );
    
    //Contracts.
    address public playerPack; //PlayerPack CA.
    address public fdfPair; //DEX CA.
    address public developmentPlayers; //DevelopmentPlayers CA.
    IERC20 public currencyToken; // Reference to ERC20 currency
    IFeeManager public feeManager; // FeeManager contract.

    //Transaction signer addresses from app.
    address[] public txSigners;

    //Base URI for player metadata.
    string public baseURI;

    //Player info.
    struct PlayerInfo {
        bool exists; //Does the player exist
        bool isBuyable; //Can this player be bought
        bool isSellable; //Can this player be sold
        bool isInActiveList; //Is this player in the activePlayerIds array
    }

    //Tracks all of the FDF players. playerId => PlayerInfo
    mapping(uint256 => PlayerInfo) public players;

    //Tracks all of the active player ids.
    uint256[] private activePlayerIds;

    //Fractional amount of each player.
    uint256 private mintAmount; //25M tokens.

    //Mapping to track whitelisted addresses that can send/receive tokens.
    mapping(address => bool) public whitelistedAddresses;

    //Used nonces for replay protection (UUID).
    mapping(address => uint256) public usedNonces;

    //Minimum thresholds for player creation
    uint256 public minPlayerSharesDeposit; // Minimum player token shares to deposit
    uint256 public minCurrencyDepositForPlayer; // Minimum currency deposit per player

    // V2 addition: version tracking
    uint256 public upgradeVersion;
    
    // V2 addition: swaps enabled from timestamp
    uint256 public swapsEnabledFrom;

    // Storage gap for future upgrades (unchanged from V2 because V3 adds no new storage)
    uint256[48] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the V3 upgrade
     * @dev This function should be called after upgrading to V3
     * @dev V3 is a pure execution/auth upgrade and intentionally preserves the V2 storage layout
     */
    function initializeV3() external onlyRole(GOVERNOR_ROLE) {
        require(upgradeVersion == 2, "V3 already initialized");
        upgradeVersion = 3;
    }

    /**
     * Create/mint multiple players at once and transfer them to the DEX.
     * @param _playerIds The playerIds to create.
     * @param _amounts Array of token amounts to transfer to DEX.
     * @param _maxCurrencyDeposit Array of currency reserve for each playerId.
     * @param _deadline Timestamp after which this transaction will be reverted.
     */
    function createPlayers(
        uint256[] calldata _playerIds, 
        uint256[] calldata _amounts, 
        uint256[] calldata _maxCurrencyDeposit, 
        uint256 _deadline
    ) external onlyRole(MINTER_ROLE) {
        _requirePlayerIdsNotEmpty(_playerIds);
        _requireMatchingLength(_playerIds.length, _amounts.length);
        _requireMatchingLength(_playerIds.length, _maxCurrencyDeposit.length);

        //1: Create and activate all players.
        for (uint256 i = 0; i < _playerIds.length;) {
            if(_amounts[i] < minPlayerSharesDeposit) revert InvalidAmount();
            if(_maxCurrencyDeposit[i] < minCurrencyDepositForPlayer) revert InvalidCurrencyDeposit();
            if(players[_playerIds[i]].exists) revert PlayerAlreadyExist();

            _createAndActivatePlayer(_playerIds[i]);
            
            unchecked { i++; }
        }

        //2: Transfer to DEX.
        _transferToExchange(_playerIds, _amounts, _maxCurrencyDeposit, _deadline);
    }

    /**
     * Create a player.
     * @param _playerId The playerId of the player.
     */
    function _createAndActivatePlayer(uint256 _playerId) internal {
        //Mint the player to the contract.
        _mint(address(this), _playerId, mintAmount, "");

        players[_playerId] = PlayerInfo({
            exists: true,
            isBuyable: false, //Untradeable on mint.
            isSellable: false, //Untradeable on mint.
            isInActiveList: true
        });
        
        activePlayerIds.push(_playerId);

        emit PlayerActivated(_playerId);
    }

    /**
     * Transfer tokens to the FDFPair contract.
     * @param _playerIds Array of playerIds.
     * @param _amounts Array of token amounts.
     * @param _maxCurrencyDeposit Array of currency reserve for each playerId provided in _playerIds.
     * @param _deadline Timestamp after which this transaction will be reverted.
     */
    function _transferToExchange(uint256[] calldata _playerIds, uint256[] calldata _amounts, uint256[] calldata _maxCurrencyDeposit, uint256 _deadline) internal {
        _requirePlayerIdsNotEmpty(_playerIds);
        _requireMatchingLength(_playerIds.length, _amounts.length);
        _requireMatchingLength(_playerIds.length, _maxCurrencyDeposit.length);
        if (_deadline < block.timestamp) revert InvalidDeadline();

        //Encode the data for addLiquidity.
        bytes memory data = abi.encode(
            IFDFPair(fdfPair).ADDLIQUIDITY_SIG(),
            IFDFPair.AddLiquidityObj({
                maxCurrencyToDeposit: _maxCurrencyDeposit,
                deadline: _deadline
            })
        );

        //Calculate the total amount of currency to deposit.
        uint256 totalCurrencyDeposit = 0;
        for (uint256 i = 0; i < _maxCurrencyDeposit.length; i++) {
            totalCurrencyDeposit += _maxCurrencyDeposit[i];
        }

        //Send currency to the Player contract for this funding.
        currencyToken.safeTransferFrom(msg.sender, address(this), totalCurrencyDeposit);
                
        //Transfer tokens to the FDFPair contract.
        this.safeBatchTransferFrom(address(this), fdfPair, _playerIds, _amounts, data);

        emit PlayerSentToExchange(_playerIds, _amounts, _maxCurrencyDeposit);
    }

    /**
     * @notice Returns supply of shares for one or more players.
     * @dev Only callable by addresses with the SUPPLY_MANAGER role.
     * @param _playerIds Array of player IDs.
     * @param _shares Array of shares to allocate per player.
     */
    function returnSupply(uint256[] calldata _playerIds, uint256[] calldata _shares) external onlyRole(SUPPLY_MANAGER) {
        _requirePlayerIdsNotEmpty(_playerIds);
        _requireMatchingLength(_playerIds.length, _shares.length);

        for (uint256 i = 0; i < _playerIds.length;) {
            if(!players[_playerIds[i]].exists) revert PlayerDoesNotExist();
            unchecked { i++; }
        }

        //Transfer tokens to the Player contract. Skips override function.
        _safeBatchTransferFrom(msg.sender, address(this), _playerIds, _shares, "");

        emit SupplyReturned(_playerIds, _shares);
    }

    /**
     * @notice pulls supply of shares for one or more players
     * @dev V2 CHANGE: Now protected by MINTER_ROLE instead of SUPPLY_MANAGER
     * @param _playerIds Array of player IDs
     * @param _shares Array of shares to allocate per player
     */
    function requestSupply(uint256[] calldata _playerIds, uint256[] calldata _shares) external onlyRole(MINTER_ROLE) {
        _requirePlayerIdsNotEmpty(_playerIds);
        _requireMatchingLength(_playerIds.length, _shares.length);

        for (uint256 i = 0; i < _playerIds.length;) {
            if(!players[_playerIds[i]].exists) revert PlayerDoesNotExist();
            unchecked { i++; }
        }

        //Transfer tokens to the fetcher wallet. Skips override function.
        _safeBatchTransferFrom(address(this), msg.sender, _playerIds, _shares, "");

        emit SupplyPulled(_playerIds, _shares);
    }

    /**
     * Bulk enable trading (buying and selling) for a list of players.
     * @param _playerIds Array of playerIds.
     */
    function enableForTrading(uint256[] calldata _playerIds) external onlyRole(GOVERNOR_ROLE) {
        _requirePlayerIdsNotEmpty(_playerIds);
        
        for (uint256 i = 0; i < _playerIds.length;) {
            _requirePlayerExists(_playerIds[i]);
            if(players[_playerIds[i]].isBuyable) revert PlayerAlreadyBuyable();
            if(players[_playerIds[i]].isSellable) revert PlayerAlreadySellable();

            players[_playerIds[i]].isBuyable = true;
            players[_playerIds[i]].isSellable = true;

            emit PlayerTradingEnabled(_playerIds[i]);
            unchecked { i++; }
        }
    }

    /**
     * Bulk disable trading (buying and selling) for a list of players.
     * @param _playerIds Array of playerIds.
     */
    function deactivateForTrading(uint256[] calldata _playerIds) external onlyRole(GOVERNOR_ROLE) {
        _requirePlayerIdsNotEmpty(_playerIds);
        
        for (uint256 i = 0; i < _playerIds.length;) {
            _requirePlayerExists(_playerIds[i]);
            if(!players[_playerIds[i]].isBuyable) revert PlayerAlreadyNotBuyable();
            if(!players[_playerIds[i]].isSellable) revert PlayerAlreadyNotSellable();

            players[_playerIds[i]].isBuyable = false;
            players[_playerIds[i]].isSellable = false;

            emit PlayerTradingDisabled(_playerIds[i]);
            unchecked { i++; }
        }
    }

    /**
     * Reactivate a player that has been deactivated (retired).
     * @param _playerId The playerId of the player.
     */
    function reactivatePlayer(uint256 _playerId) external onlyRole(GOVERNOR_ROLE) {
        _requirePlayerExists(_playerId);
        if(players[_playerId].isInActiveList) revert PlayerAlreadyActive();

        //Add to activePlayerIds.
        activePlayerIds.push(_playerId);
        players[_playerId].isInActiveList = true;        

        emit PlayerReactivated(_playerId);
    }
    
    /**
     * Deactivate a player.
     * @param _playerId The playerId of the player.
     */
    function deactivatePlayer(uint256 _playerId) external onlyRole(GOVERNOR_ROLE) {
        _requirePlayerExists(_playerId);
        if(!players[_playerId].isInActiveList) revert PlayerAlreadyDeactivated();

        for (uint256 i = 0; i < activePlayerIds.length;) {
            if (activePlayerIds[i] == _playerId) {
                activePlayerIds[i] = activePlayerIds[activePlayerIds.length - 1];
                activePlayerIds.pop();
                break;
            }
            unchecked { i++; }
        }

        players[_playerId].isInActiveList = false;

        emit PlayerDeactivated(_playerId);
    }

    /**
     * Functions for prevention of direct contract calls/OTC trades.
     */

    /**
     * Authorised sell function that requires signature verification.
     * This is the ONLY way users can sell tokens to the DEX.
     * @param _playerTokenIds Array of token IDs to sell.
     * @param _amounts Array of amounts to sell.
     * @param _minCurrencyToReceive Minimum currency to receive from the sale.
     * @param _feeRateBps Signed base fee rate per sold player id (drives surge epoch).
     * @param _discountFeeBps Signed per-user fee adjustment per sold player id (negative = discount, positive = surcharge).
     * @param _surgeEpochs Signed surge epoch per sold player id.
     * @param _deadline Deadline after which signature expires.
     * @param _signature Signature from the game backend authorising this sale.
     * @param _nonce Nonce for replay protection.
     */
    function sellTokens(
        uint256[] calldata _playerTokenIds,
        uint256[] calldata _amounts,
        uint256 _minCurrencyToReceive,
        uint256[] calldata _feeRateBps,
        int256[] calldata _discountFeeBps,
        uint256[] calldata _surgeEpochs,
        uint256 _deadline,
        bytes calldata _signature,
        uint256 _nonce
    ) external {
        _requirePlayerIdsNotEmpty(_playerTokenIds);
        _requireMatchingLength(_playerTokenIds.length, _amounts.length);
        _requireMatchingLength(_playerTokenIds.length, _feeRateBps.length);
        _requireMatchingLength(_playerTokenIds.length, _discountFeeBps.length);
        _requireMatchingLength(_playerTokenIds.length, _surgeEpochs.length);
        if (block.timestamp > _deadline) revert InvalidDeadline();
        if (_nonce <= usedNonces[msg.sender]) revert InvalidNonce();

        //Check if all players are active.
        for (uint256 i = 0; i < _playerTokenIds.length;) {
            if (!isSellable(_playerTokenIds[i])) revert PlayerNotSellable();
            unchecked { i++; }
        }

        bytes32 structHash = keccak256(abi.encode(
            SELL_TYPEHASH,
            msg.sender,
            keccak256(abi.encodePacked(_playerTokenIds)),
            keccak256(abi.encodePacked(_amounts)),
            _minCurrencyToReceive,
            keccak256(abi.encodePacked(_feeRateBps)),
            keccak256(abi.encodePacked(_discountFeeBps)),
            keccak256(abi.encodePacked(_surgeEpochs)),
            _deadline,
            _nonce
        ));

        _verifySignature(structHash, _signature);

        bytes memory sellData = abi.encode(
            IFDFPairV3(fdfPair).SELLTOKENS_SIG_V3(),
            IFDFPairV3.SellTokensV3Obj({
                recipient: msg.sender,
                minCurrencyToReceive: _minCurrencyToReceive,
                feeRateBps: _feeRateBps,
                discountFeeBps: _discountFeeBps,
                surgeEpochs: _surgeEpochs,
                deadline: _deadline
            })
        );

        _safeBatchTransferFrom(msg.sender, fdfPair, _playerTokenIds, _amounts, sellData);
        usedNonces[msg.sender] = _nonce;

        emit AuthorisedSellTokens(msg.sender, _playerTokenIds, _amounts, _minCurrencyToReceive);
    }

    /**
     * Authorised swap function that requires signature verification.
     * This is the ONLY way users can swap tokens through the DEX.
     * @param params SwapTokensV3Params struct containing all swap parameters.
     * @dev V3 binds both sell-side and buy-side signed fee inputs into the user signature.
     */
    function swapTokens(IFDFPairV3.SwapTokensV3Params calldata params) external {
        if (block.timestamp < swapsEnabledFrom) revert SwapsNotEnabled();
        _validateSwapTokens(params);
        usedNonces[msg.sender] = params.nonce;
        _safeBatchTransferFrom(
            msg.sender,
            fdfPair,
            params.playerTokenIdsIn,
            params.playerTokenAmountsIn,
            abi.encode(IFDFPairV3(fdfPair).SWAP_TOKENS_SIG_V3(), abi.encode(params))
        );
    }

    /**
     * Private function to verify EIP-712 signature validity.
     * @param structHash The EIP-712 structured hash to verify.
     * @param signature The signature to verify.
     */
    function _verifySignature(bytes32 structHash, bytes calldata signature) internal view {
        address recoveredSigner = ECDSA.recover(_hashTypedDataV4(structHash), signature);
        for (uint256 i = 0; i < txSigners.length;) {
            if (recoveredSigner == txSigners[i]) return;
            unchecked { i++; }
        }
        revert InvalidSignature();
    }

    /**
     * Internal function to validate swap token parameters.
     * @param params SwapTokensV3Params struct containing all swap parameters.
     * @dev The current swap implementation still supports a single in/out player leg only.
     */
    function _validateSwapTokens(IFDFPairV3.SwapTokensV3Params calldata params) internal view {
        _requireLengthOne(params.playerTokenIdsIn.length);
        _requireLengthOne(params.playerTokenAmountsIn.length);
        _requireLengthOne(params.playerTokenIdsOut.length);
        _requireLengthOne(params.playerTokenAmountsOut.length);
        _requireLengthOne(params.sellFeeRateBps.length);
        _requireLengthOne(params.sellDiscountFeeBps.length);
        _requireLengthOne(params.buyFeeRateBps.length);
        _requireLengthOne(params.buyDiscountFeeBps.length);
        _requireLengthOne(params.surgeEpochsIn.length);
        if (block.timestamp > params.deadline) revert InvalidDeadline();
        if (params.nonce <= usedNonces[msg.sender]) revert InvalidNonce();
        _requireNonZeroAddress(params.recipient);

        if (!isSellable(params.playerTokenIdsIn[0])) revert PlayerNotSellable();
        if (!isBuyable(params.playerTokenIdsOut[0])) revert PlayerNotBuyable();

        bytes32 structHash = keccak256(abi.encode(
            SWAP_TYPEHASH,
            msg.sender,
            keccak256(abi.encodePacked(params.playerTokenIdsIn)),
            keccak256(abi.encodePacked(params.playerTokenAmountsIn)),
            keccak256(abi.encodePacked(params.playerTokenIdsOut)),
            keccak256(abi.encodePacked(params.playerTokenAmountsOut)),
            keccak256(abi.encodePacked(params.sellFeeRateBps)),
            keccak256(abi.encodePacked(params.sellDiscountFeeBps)),
            keccak256(abi.encodePacked(params.buyFeeRateBps)),
            keccak256(abi.encodePacked(params.buyDiscountFeeBps)),
            keccak256(abi.encodePacked(params.surgeEpochsIn)),
            params.recipient,
            params.deadline,
            params.nonce
        ));

        _verifySignature(structHash, params.signature);
    }

    /**
     * @dev Override safeBatchTransferFrom to prevent OTC trades.
     * Allows: Only whitelisted contracts can call this function.
     * Blocks: Direct user-to-user transfers.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, 
        uint256[] memory amounts, bytes memory data) public override(ERC1155Upgradeable, IERC1155) {
        //Only allow if 'from' address is whitelisted (contracts like DEX, PlayerPack, etc.)
        if (!whitelistedAddresses[from]) {
            revert UnauthorisedTransfer();
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        emit PlayerBatchTransfer(from, to, ids, amounts);
    }

    /**
     * @dev Override safeTransferFrom to prevent OTC trades.
     * Allows: Only whitelisted contracts can call this function.
     * Blocks: Direct user-to-user transfers.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override(ERC1155Upgradeable, IERC1155) {
        //Only allow if 'from' address is whitelisted (contracts like DEX, PlayerPack, etc.)
        if (!whitelistedAddresses[from]) {
            revert UnauthorisedTransfer();
        }

        super.safeTransferFrom(from, to, id, amount, data);

        emit PlayerTransfer(from, to, id, amount);
    }

    /**
     * Admin.
     */

    /**
     * @notice Reset the nonce for a user.
     * @param _user The user to reset the nonce for.
     * @param _newNonce The new nonce to set.
     */
    function resetUserNonce(address _user, uint256 _newNonce) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_user);

        usedNonces[_user] = _newNonce;

        emit NonceReset(_user, _newNonce);
    }

    /**
     * Checks.
     */

    /**
     * Check if a player exists in the pool.
     * @param _playerId playerId of the player.
     * @return True if the player exists in the pool, false otherwise.
     */
    function existsInPool(uint256 _playerId) public view returns (bool) {
        if(_playerId == 0) revert PlayerIdCannotBeZero();

        return players[_playerId].exists;
    }

    function _requirePlayerExists(uint256 _playerId) internal view {
        if(_playerId == 0) revert PlayerIdCannotBeZero();
        if(!players[_playerId].exists) revert PlayerDoesNotExist();
    }

    function _requireNonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddress();
    }

    function _requirePlayerIdsNotEmpty(uint256[] calldata _ids) internal pure {
        if (_ids.length == 0) revert PlayerIdsCannotBeEmpty();
    }

    function _requireMatchingLength(uint256 _a, uint256 _b) internal pure {
        if (_a != _b) revert ArrayLengthMismatch();
    }

    function _requireLengthOne(uint256 _len) internal pure {
        if (_len != 1) revert ArrayLengthMismatch();
    }

    /**
     * Check if a player is buyable.
     * @param _playerId playerId of the player.
     * @return True if the player is buyable, false otherwise.
     */
    function isBuyable(uint256 _playerId) public view returns (bool) {
        _requirePlayerExists(_playerId);

        return players[_playerId].isBuyable;
    }

    /**
     * Check if a player is sellable.
     * @param _playerId playerId of the player.
     * @return True if the player is sellable, false otherwise.
     */
    function isSellable(uint256 _playerId) public view returns (bool) {
        _requirePlayerExists(_playerId);

        return players[_playerId].isSellable;
    }

    /**
     * Check if a player is active (both buyable and sellable).
     * @param _playerId playerId of the player.
     * @return True if the player is active, false otherwise.
     */
    function isActive(uint256 _playerId) public view returns (bool) {
        _requirePlayerExists(_playerId);

        return players[_playerId].isInActiveList;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId The token ID to get the URI for.
     * @return The URI string for the token.
     * 
     * This overrides the ERC1155Upgradeable uri function to:
     * 1. Check that the token (player) exists
     * 2. Concatenate the base URI with the token ID
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        if(!players[_tokenId].exists) revert PlayerDoesNotExist();

        return string.concat(baseURI, _tokenId.toString());
    }

    /**
     * Getters.
     */
    /**
     * Get the current nonce for a user.
     * @param _user The user to get the nonce for.
     * @return The current nonce for the user.
     */
    function getCurrentNonce(address _user) external view returns (uint256) {
        _requireNonZeroAddress(_user);

        return usedNonces[_user];
    }

    /**
     * Get the number of active players.
     * @return The number of active players.
     */
    function getActivePlayerCount() external view returns (uint256) {
        return activePlayerIds.length;
    }

    /**
     * Get the active playerId by index.
     * @param _index The index of the active player.
     * @return The active playerId.
     */
    function getActivePlayerByIndex(uint256 _index) external view returns (uint256) {
        if(_index >= activePlayerIds.length) revert PlayerIndexOutOfBounds();

        return activePlayerIds[_index];
    }

    /**
     * Get the active player ids.
     * @return The active player ids.
     */
    function getActivePlayerIds() external view returns (uint256[] memory) {
        return activePlayerIds;
    }

    /**
     * Get the txSigners.
     * @return The txSigners.
     */
    function getTxSigners() external view returns (address[] memory) {
        return txSigners;
    }

    /**
     * Setters.
     */

    /**
     * Add or remove an address from the whitelist.
     * @param _account The address to whitelist/unwhitelist.
     * @param _whitelisted True to whitelist, false to remove from whitelist.
     */
    function setWhitelistedAddress(address _account, bool _whitelisted) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_account);
        
        whitelistedAddresses[_account] = _whitelisted;
        emit AddressWhitelisted(_account, _whitelisted);
    }

    /**
     * Add a new txSigner address for signature verification.
     * @param _newTxSigner the new txSigner address.
     */
    function addTxSigner(address _newTxSigner) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_newTxSigner);

        //Check if the txSigner is already in the array.
        for (uint256 i = 0; i < txSigners.length;) {
            if (txSigners[i] == _newTxSigner) revert TxSignerAlreadyExists();
            unchecked { i++; }
        }

        txSigners.push(_newTxSigner);
        emit TxSignerAdded(_newTxSigner);
    }

    /**
     * Remove a txSigner address for signature verification.
     * @param _txSigner the txSigner address to remove.
     */
    function removeTxSigner(address _txSigner) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_txSigner);
        if (txSigners.length == 1) revert TxSignerCannotBeRemoved();

        for (uint256 i = 0; i < txSigners.length;) {
            if (txSigners[i] == _txSigner) {
                txSigners[i] = txSigners[txSigners.length - 1];
                txSigners.pop();
                break;
            }

            if (i == txSigners.length - 1) revert TxSignerNotFound();

            unchecked { i++; }
        }

        emit TxSignerRemoved(_txSigner);
    }

    /**
     * Sets the minimum player shares deposit threshold
     * @param _minPlayerSharesDeposit the new minimum player shares deposit
     */
    function setMinPlayerSharesDeposit(uint256 _minPlayerSharesDeposit) external onlyRole(GOVERNOR_ROLE) {
        if (_minPlayerSharesDeposit == 0) revert InvalidAmount();

        minPlayerSharesDeposit = _minPlayerSharesDeposit;
        emit MinPlayerSharesDepositChanged(_minPlayerSharesDeposit);
    }

    /**
     * Sets the minimum currency deposit per player threshold
     * @param _minCurrencyDepositForPlayer the new minimum currency deposit per player
     */
    function setMinCurrencyDepositForPlayer(uint256 _minCurrencyDepositForPlayer) external onlyRole(GOVERNOR_ROLE) {
        if (_minCurrencyDepositForPlayer == 0) revert InvalidCurrencyDeposit();

        minCurrencyDepositForPlayer = _minCurrencyDepositForPlayer;
        emit MinCurrencyDepositForPlayerChanged(_minCurrencyDepositForPlayer);
    }

    /**
     * @notice Grant the SUPPLY_MANAGER role to an address.
     * @param _address The address to grant the SUPPLY_MANAGER role to.
     */
    function grantSupplyManagerRole(address _address) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_address);
        
        _grantRole(SUPPLY_MANAGER, _address);
        emit SupplyManagerRoleGranted(_address);
    }

    /**
     * @notice Revoke the SUPPLY_MANAGER role from an address.
     * @param _address The address to revoke the SUPPLY_MANAGER role from.
     */
    function revokeSupplyManagerRole(address _address) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_address);
        
        _revokeRole(SUPPLY_MANAGER, _address);
        emit SupplyManagerRoleRevoked(_address);
    }

    /**
     * @notice Grant approval to a new pack issuer address
     * @param _packIssuer The address to grant pack issuer approval to
     * @dev This function allows adding new pack issuers without calling the full setApprovals function
     */
    function grantPackIssuerApproval(address _packIssuer) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_packIssuer);
        
        // Grant approval for token transfers
        this.setApprovalForAll(_packIssuer, true);
        
        // Add to whitelist
        whitelistedAddresses[_packIssuer] = true;
        
        emit ApprovalSet(_packIssuer, true);
        emit AddressWhitelisted(_packIssuer, true);
    }

    /**
     * @notice Revoke approval from a pack issuer address
     * @param _packIssuer The address to revoke pack issuer approval from
     * @dev This function allows removing pack issuers
     */
    function revokePackIssuerApproval(address _packIssuer) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_packIssuer);
        
        // Revoke approval for token transfers
        this.setApprovalForAll(_packIssuer, false);
        
        // Remove from whitelist
        whitelistedAddresses[_packIssuer] = false;
        
        emit ApprovalSet(_packIssuer, false);
        emit AddressWhitelisted(_packIssuer, false);
    }
    /**
     * Set the base URI for the player metadata if needed in the future.
     * @param _baseURI The new base URI for the player metadata.
     */
    function setBaseURI(string memory _baseURI) external onlyRole(GOVERNOR_ROLE) {
        if(bytes(_baseURI).length == 0) revert BaseURICannotBeEmpty();

        baseURI = _baseURI;

        emit URI(_baseURI, 0);
        emit BaseURIChanged(_baseURI);
    }

    /**
     * Sets the player pack address.
     * @param _playerPack The new player pack address.
     */
    function setPlayerPack(address _playerPack) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_playerPack);

        playerPack = _playerPack;
        emit PlayerPackContractChanged(_playerPack);
    }

    /**
     * Sets the FDF pair address.
     * @param _fdfPair The new FDF pair address.
     */
    function setFdfPair(address _fdfPair) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_fdfPair);

        fdfPair = _fdfPair;
        emit FdfPairContractChanged(_fdfPair);
    }

    /**
     * Sets the development players address.
     * @param _developmentPlayers The new development players address.
     */
    function setDevelopmentPlayers(address _developmentPlayers) external onlyRole(GOVERNOR_ROLE) {
        _requireNonZeroAddress(_developmentPlayers);

        developmentPlayers = _developmentPlayers;
        emit DevelopmentPlayersContractChanged(_developmentPlayers);
    }

    /**
     * @dev DEPRECATED in V3 — fee manager is no longer used. No-op retained for ABI compatibility.
     */
    function setFeeManager(address) external onlyRole(GOVERNOR_ROLE) {}

    /**
     * @notice Set the timestamp from which swaps are enabled
     * @param _swapsEnabledFrom The timestamp from which swaps are enabled
     */
    function setSwapsEnabledFrom(uint256 _swapsEnabledFrom) external onlyRole(GOVERNOR_ROLE) {
        swapsEnabledFrom = _swapsEnabledFrom;
        emit SwapsEnabledFromChanged(_swapsEnabledFrom);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Upgradeable, ERC1155HolderUpgradeable, AccessControlUpgradeable, IERC165) returns (bool) {
        return _interfaceId == type(IPlayerV3).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Required by the UUPSUpgradeable module
     * @dev Only allows admins to upgrade the implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(GOVERNOR_ROLE) {}
}
