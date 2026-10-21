// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IFDFPair {
    
    // Role Constants
    function GOVERNOR_ROLE() external pure returns (bytes32);
    function ADMIN_ROLE() external pure returns (bytes32);
    function LIQUIDITY_PROVIDER_ROLE() external pure returns (bytes32);
    
    // Constants for onERC1155Received/onERC1155BatchReceived
    function SELLTOKENS_SIG() external pure returns (bytes4);
    function ADDLIQUIDITY_SIG() external pure returns (bytes4);

    // Errors
    error INVALID_INPUT();
    error DEADLINE_EXCEEDED();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error ZERO_TOKENS_BOUGHT();
    error ZERO_TOKENS_SOLD();
    error ZERO_MAX_CURRENCY();
    error ZERO_TOKENS_AMOUNT();
    error INSUFFICIENT_CURRENCY_AMOUNT();
    error MAX_CURRENCY_AMOUNT_EXCEEDED();
    error INVALID_CURRENCY_AMOUNT();
    error ZERO_TOTAL_LIQUIDITY();
    error INSUFFICIENT_TOKENS();
    error INSUFFICIENT_LIQUIDITY();
    error ARRAY_LENGTH_MISMATCH();
    error INVALID_CURRENCY_IDS_AMOUNT();
    error INVALID_TOKENS_AMOUNT();
    error INVALID_TOKENS_TRANSFERRED();
    error INVALID_METHOD();
    error UNSORTED_OR_DUPLICATE_TOKEN_IDS(); 
    error INVALID_FROM_ADDRESS();
    error K_INVARIANT_VIOLATED();
    error V2_ALREADY_INITIALIZED();
    error ONLY_ALLOWED_TOKENS();
    error INVALID_ONRECEIVED_MESSAGE();

    // Contract Address Events
    event TreasuryAddressSet(address indexed treasury);
    event FeeManagerSet(address indexed feeManager);
    event PlayerTokenSet(address indexed playerToken);
    event UserNonceReset(address indexed user, uint256 nonce);
    event LiquidityProviderRoleSet(address indexed liquidityProvider);
    event MinCurrencyAmountForNewPoolsSet(uint256 minCurrencyAmountForNewPools);

    event PlayerTokensPurchase(
        address indexed buyer,
        address indexed recipient,
        uint256[] playerTokenIds,
        uint256[] playerTokenAmountsToBuy,
        uint256[] currencySpent,
        uint256[] newPlayerPrices,
        uint256[] feeAmounts
    );

    event CurrencyPurchase(
        address indexed buyer,
        address indexed recipient,
        uint256[] playerTokenIds,
        uint256[] playerTokenAmounts,
        uint256[] currencyReceived,
        uint256[] newPlayerPrices,
        uint256[] feeAmounts
    );

    event LiquidityAdded(
        address indexed liquidityProviderAddr, 
        uint256[] playerTokenIds, 
        uint256[] playerTokenAmounts, 
        uint256[] currencyAmountsDeposited
    );

    struct SellTokensObj {
        address recipient; // Who receives the currency
        uint256 minCurrencyToReceive; // Total minimum number of currency  expected for all tokens sold
        uint256 deadline; // Timestamp after which the tx isn't valid anymore
    }

    struct AddLiquidityObj {
        uint256[] maxCurrencyToDeposit; // Maximum number of currency to deposit with tokens
        uint256 deadline; // Timestamp after which the tx isn't valid anymore
        // address liquidityProvider; // Address that should receive the LP tokens
    }

    struct SellTradeVars {
        uint256 playerId;
        uint256 saleAmount;
        uint256 currentPlayerTokenReserve;
        uint256 currentCurrencyReserve;
        uint256 sellPriceForOneToken;
        uint256 sellFeeRate;
        uint256 sellFeeType;
        uint256 newPlayerTokenReserve;
        uint256 newCurrencyReserve;
    }

    /**
     * @notice Convert currency to Player tokens per id and transfers Player tokens to recipient.
     * @dev User specifies MAXIMUM to spend on transaction (_maxCurrencySpend).
     * @dev Assumes that all trades will be successful, or revert the whole tx.
     * @dev Exceeding currency sent will be refunded to recipient.
     * @dev Sorting IDs is mandatory for efficient way of preventing duplicated IDs (which would lead to exploit).
     * @param _playerTokenIds Array of player ids that are being bought.
     * @param _playerTokenAmountsToBuy Amount of token being bought for each corresponding player id in _playerTokenIds.
     * @param _maxCurrencySpend Total maximum amount of currency to spend for all player ids.
     * @param _deadline Timestamp after which this transaction will be reverted.
     * @param _recipient The address that receives Player token and refund.
     * @param _signature Signature from the game backend authorising this purchase.
     * @param _nonce UUID nonce for replay protection.
     * @return CurrencySpent How much currency was actually sold.
     */
    function buyTokens(
        uint256[] memory _playerTokenIds,
        uint256[] memory _playerTokenAmountsToBuy,
        uint256 _maxCurrencySpend,
        uint256 _deadline,
        address _recipient,
        bytes calldata _signature,
        uint256 _nonce
    ) external returns (uint256[] memory);

    /**
     * @notice Handle which method is being called on Token transfer
     * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
     * where bytes4 argument is the MethodObj object signature passed as defined
     * in the `Signatures for onReceive control logic` section above
     * @param _operator The address which called the `safeTransferFrom` function
     * @param _from     The address which previously owned the token
     * @param _id       The id of the token being transferred
     * @param _amount   The amount of tokens being transferred
     * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data)
        external
        returns (bytes4);

    /**
     * @notice Handle which method is being called on transfer
     * @dev `_data` must be encoded as follow: abi.encode(bytes4, MethodObj)
     * where bytes4 argument is the MethodObj object signature passed as defined
     * in the `Signatures for onReceive control logic` section above
     * @param _from     The address which previously owned the Token
     * @param _ids      An array containing ids of each Token being transferred
     * @param _amounts  An array containing amounts of each Token being transferred
     * @param _data     Method signature and corresponding encoded arguments for method to call on *this* contract
     * @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")
     */
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4);

    //
    // Getter Functions
    //
    /**
     * @notice Get amount of currency in reserve for each Token _id in _ids
     * @param _playerTokenIds Array of ID sto query currency reserve of
     * @return CurrencyReserves of currency in reserve for each Token _id
     */
    function getCurrencyReserves(uint256[] calldata _playerTokenIds) external view returns (uint256[] memory);

    /**
     * @notice The user can specify the amount of tokens to buy, or the amount of currency to spend, and they will get the amount of tokens that can be bought or the amount of currency needed to buy the tokens.
     * @param _playerTokenIds Array of player ids of Player tokens being bought.
     * @param _playerTokenAmountsToBuy Amount of Player tokens being bought.
     * @param _currencyAmountsToSpend Amount of currency to spend.
     * @return amountsToReceive Amount of tokens that can be bought for each ID, or the amount of currency needed to buy the tokens for each ID.
     * @return feeAmounts Amount of fee amount for each player id.
     * @return feeRates Fee rates applied for each player id (in basis points).
     * @return feeTypes Fee types applied for each player id (0=NORMAL, 1=FLASH_SALE, 2=TIER_1, etc.).
     */
    function getBuyPrice(
        uint256[] calldata _playerTokenIds,
        uint256[] calldata _playerTokenAmountsToBuy,
        uint256[] calldata _currencyAmountsToSpend
    ) external view returns (
        uint256[] memory amountsToReceive, 
        uint256[] memory feeAmounts,
        uint256[] memory feeRates,
        uint8[] memory feeTypes
    );

    /**
     * @notice Get the current price for 1 token of each player id.
     * @param _playerTokenIds Array of player ids of Player tokens being bought.
     * @return amountsToReceive Returns the buy prices for each player id.
     */
    function getPrices(
        uint256[] memory _playerTokenIds
    ) external view returns (uint256[] memory amountsToReceive);

    /**
     * @notice The user can specify the amount of tokens to sell, or the amount of currency they want to receive, and they will get the amount of currency they will receive or the amount of tokens they will sell.
     * @param _playerTokenIds Array of player ids of Player tokens sold.
     * @param _playerTokenAmountsToSell Array of amount of each Player token sold.
     * @return amountsToReceive Amount of currency that the user will receive for each ID
     * @return feeAmounts Amount of fee amount for each player id.
     * @return feeRates Fee rates applied for each player id (in basis points).
     * @return feeTypes Fee types applied for each player id (0=NORMAL, 1=FLASH_SALE, 2=FEE_TIER, etc.).
     */
    function getSellPrice(
        uint256[] memory _playerTokenIds, 
        uint256[] memory _playerTokenAmountsToSell
    ) external view returns (
        uint256[] memory amountsToReceive, 
        uint256[] memory feeAmounts,
        uint256[] memory feeRates,
        uint8[] memory feeTypes
    );

     /**
     * @notice Get the currency reserves and player token reserves for a given array of player token IDs.
     * @param _playerTokenIds Array of player token IDs to query.
     * @return _currencyReserves Array of currency reserves for each player token ID.
     * @return _playerTokenReserves Array of player token reserves for each player token ID.
     */
    function getPoolInfo(uint256[] memory _playerTokenIds) external view returns (uint256[] memory _currencyReserves, uint256[] memory _playerTokenReserves);

    /**
     * Get the address of the Player token contract.
     * @return Address of Player token contract.
     */
    function getPlayerTokenAddress() external view returns (address);

    /**
     * @return Address of the currency contract that is used as currency
     */
    function getCurrencyInfo() external view returns (address);

    /**
     * @notice Get all player IDs that have been added to the exchange.
     * @return Array of all player IDs in the exchange.
     */
    function getAllPlayerIds() external view returns (uint256[] memory);

    /**
     * @notice Set the treasury wallet address.
     * @param _treasury Address of the treasury.
     */
    function setTreasuryAddress(address _treasury) external;

    /**
     * @notice Set the player token address.
     * @param _playerToken Address of the player token contract.
     */
    function setPlayerToken(address _playerToken) external;

    /**
     * @notice Set the fee manager address.
     * @param _feeManager Address of the fee manager contract.
     */
    function setFeeManager(address _feeManager) external;

    /**
     * @notice Set the liquidity provider role.
     * @param _liquidityProvider Address of the liquidity provider.
     */
    function setLiquidityProviderRole(address _liquidityProvider) external;

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
     * @notice Get the address of the fee manager contract.
     * @return Address of the fee manager contract.
     */
    function getFeeManager() external view returns (address);

    /**
     * @return Address of the treasury wallet
     */
    function treasury() external view returns (address);
}