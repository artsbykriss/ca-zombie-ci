// File: contracts/strx/interface/ITRC20.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface ITRC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    /**
     * @return the number of decimals for getting user representation of a token amount.
     */
    function decimals() external pure returns (uint8);

    /**
     * @return the name of the token.
     */
    function name() external pure returns (string memory);

    /**
     * @return the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external pure returns (string memory);

}

// File: contracts/strx/src/AdminStorage.sol

pragma solidity ^0.8.18;

contract AdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of this contract
    */
    address public implementation;

    /**
    * @notice Pending brains of this contract
    */
    address public pendingImplementation;
}

// File: contracts/strx/interface/IRateModel.sol

pragma solidity ^0.8.18;

interface IRateModel {
    function getRentalRate(uint256 supply, uint256 borrows) external view returns (uint256);
}

// File: contracts/strx/src/BaseStrxStorage.sol

pragma solidity ^0.8.18;

contract BaseStrxStorage is AdminStorage {

    // ----------------------------- TOKEN related storages -----------------------------
    uint256 internal _totalUnderlying;

    uint256 internal _totalSupply;

    mapping(address => uint256) internal _balance;

    mapping(address => mapping(address => uint256)) internal _allowances;

}

// File: contracts/strx/interface/IMarketForSTRX.sol

pragma solidity ^0.8.18;

interface IMarketForSTRX {
    function claimRental() external returns (uint256);

    function repayBadDebt() external payable;

    function updateRentRate() external;

    function badDebtGap() external view returns (uint256);
}

// File: contracts/strx/src/STRXV1Storage.sol

pragma solidity ^0.8.18;




contract STRXV1Storage is BaseStrxStorage {

    struct UnfreezingInfo {
        uint128 placeHolder;
        uint64 round;
        // REVIEW: rename underlying
        uint64 underlyingToClaim;
    }

    struct UnfreezingIndex {
        // REIVEW: rename
        uint32 withdrawIndex; 
        uint32 claimIndex;
    }

    struct ReserveFactor {
        uint128 rentFactor;
        uint128 rewardFactor;
    }

    // ----------------------------- constant params -----------------------------
    uint32 public constant CHAIN_UNFREEZE_MAX_TIMES = 32;

    uint32 public constant USER_UNFREEZE_MAX_TIMES = 34;

    // ----------------------------- Logic related storages, need initial -----------------------------

    bool public initialized;

    IMarketForSTRX public market;

    address payable public reserveAdmin;

    address public voteOperator;

    ReserveFactor public reserveFactor;

    uint256 public round;

    uint256 public minFreezeAmount;

    uint256 public maxAmountForEnergy;

    // ----------------------------- Logic related storages, no need to initial -----------------------------

    // account -> UnfreezingInfos
    mapping(address => UnfreezingInfo[USER_UNFREEZE_MAX_TIMES]) public userUnfreezingInfos;

    mapping(address => UnfreezingIndex) public userUnfreezingIndex;

    mapping(uint256 => uint256) public roundEndTime;

    uint256 public unfreezeCalmDownTime;

    uint256 public reserves;

    uint256 public claimedReserves;

    uint256 public totalRentIncome;

    uint256 private claimable_;

    uint256 private withdrawal_;

    uint256 private balanceToUnfreeze_;

    uint256 private balanceToFreeze_;

    function claimable() public view returns (uint256) {
        return claimable_ - 1;
    }

    function withdrawal() public view returns (uint256) {
        return withdrawal_ - 1;
    }

    function balanceToUnfreeze() public view returns (uint256) {
        return balanceToUnfreeze_ - 1;
    }

    function balanceToFreeze() public view returns (uint256) {
        return balanceToFreeze_ - 1;
    }

    function setClaimable(uint256 value) internal {
        claimable_ = value + 1;
    }

    function setBalanceToUnfreeze(uint256 value) internal {
        balanceToUnfreeze_ = value + 1;
    }

    function setBalanceToFreeze(uint256 value) internal {
        balanceToFreeze_ = value + 1;
    }

    function setWithdrawal(uint256 value) internal {
        withdrawal_ = value + 1;
    }

}

// File: contracts/strx/src/BaseSTRX.sol

pragma solidity ^0.8.18;

contract BaseSTRX is BaseStrxStorage, ITRC20 {

    uint256 public constant SCALE = 1e18;

    uint256 public constant INITIAL_EXCHANGE_RATE = 1e18;

    uint256 public constant DECIMAL_MULTIPLIER = 1e30;

    event UpdateTotalUnderlying(
        uint256 oldTotalUnderlying,
        uint256 newTotalUnderlying
    );

    // -------------------------------- public write functions --------------------------------

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO");
        _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance > 0, "ZERO_ALLOWANCE");
        require(currentAllowance >= _amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance - _amount);
        return true;
    }

    // -------------------------------- public view functions --------------------------------

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balance[_account];
    }

    function totalUnderlying() public view returns (uint256) {
        return _totalUnderlying;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function exchangeRate() public view returns (uint256) {
        if (_totalSupply == 0) {
            return INITIAL_EXCHANGE_RATE;
        }

        return _totalUnderlying * DECIMAL_MULTIPLIER / _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    //TODO strx token name
    function name() external pure returns (string memory) {
        return "staked TRX";
    }

    // TODO strx symbol
    function symbol() external pure returns (string memory) {
        return "sTRX";
    }

    // -------------------------------- internal functions --------------------------------

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _doTransferOut(address payable to, uint256 amount) internal {
        require(address(this).balance >= amount, "transfer: balance not enough");
        to.transfer(amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderTokens = _balance[_sender];
        require(_amount <= currentSenderTokens, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");

        _balance[_sender] = currentSenderTokens - _amount;
        _balance[_recipient] = _balance[_recipient] + _amount;

        emit Transfer(_sender, _recipient, _amount);
    }

    function depositInternal(address user, uint256 depositAmount) internal returns (uint256) {

        uint256 exchangeTokens = depositAmount * DECIMAL_MULTIPLIER / exchangeRate();
        _balance[user] += exchangeTokens;
        _totalSupply += exchangeTokens;
        uint256 oldDeposits = _totalUnderlying;
        _totalUnderlying = oldDeposits + depositAmount;

        emit Transfer(address(0), user, exchangeTokens);
        emit UpdateTotalUnderlying(oldDeposits, _totalUnderlying);
        return exchangeTokens;
    }

    function updateExchangeRate(uint256 increasedAmount) internal {
        if (increasedAmount == 0) {
            return;
        }

        uint256 oldUnderlying = _totalUnderlying;
        uint256 newDeposits = oldUnderlying + increasedAmount;
        _totalUnderlying = newDeposits;

        emit UpdateTotalUnderlying(oldUnderlying, newDeposits);
    }

    function withdrawInternal(address user, uint256 withdrawTokens) internal returns (uint256) {
        uint256 withdrawDeposits = withdrawTokens * exchangeRate() / DECIMAL_MULTIPLIER;
        updateTokensAndDeposits(user, withdrawTokens, withdrawDeposits);

        return withdrawDeposits;
    }

    function withdrawExactInternal(address user, uint256 withdrawDeposits) internal returns (uint256) {
        uint256 rate = exchangeRate();
        uint256 withdrawTokens = (withdrawDeposits * DECIMAL_MULTIPLIER + (rate - 1)) / rate;
        updateTokensAndDeposits(user, withdrawTokens, withdrawDeposits);

        return withdrawTokens;
    }

    function updateTokensAndDeposits(address user, uint256 withdrawTokens, uint256 withdrawDeposits) private {
        require(withdrawTokens <= _balance[user], "withdrawExactInternal: balance not enough for withdraw");

        _balance[user] -= withdrawTokens;
        _totalSupply -= withdrawTokens;
        emit Transfer(user, address(0), withdrawTokens);

        uint256 oldDeposits = _totalUnderlying;
        _totalUnderlying = oldDeposits - withdrawDeposits;
        emit UpdateTotalUnderlying(oldDeposits, _totalUnderlying);
    }

}

// File: contracts/strx/interface/ISTRX.sol

pragma solidity ^0.8.18;

interface ISTRX {

    /**
     * @notice Event emitted when user deposits
     */
    event Deposit(address indexed user, uint256 trxAmount, uint256 strxAmount, uint256 balance);

    /**
     * @notice Event emitted when user withdraw
     */
    event Withdraw(address indexed user, uint256 strxAmount, uint256 trxAmount, uint256 balance);

    /**
     * @notice Event emitted when trx is frozen
     */
    event BalanceFrozen(uint256 trxAmount);

    /**
     * @notice Event emitted when trx is unfrozen
     */
    event BalanceUnfrozen(uint256 trxAmount);

    /**
     * @notice Event emitted when resource is obtained
     */
    event ResourceObtained(uint256 trxAmount, uint256 resourceType);

    /**
     * @notice Event emitted when resource is released
     */
    event ResourceReleased(uint256 trxAmount, uint256 resourceType);

    /**
     * @notice Event emitted when user claim
     */
    event Claim(address indexed user, uint256 trxAmount);

    /**
     * @notice Sender deposits msg.value of trx into the contract
     * @return strxAmount the amount of strx to mint for sender
     */
    function deposit() external payable returns (uint256 strxAmount);

    /**
     * @notice Sender requests to withdraw a specific amount of strx
     * @param strxAmount the amount of strx to withdraw
     * @return trxAmount the amount of trx sender will obtain
     */
    function withdraw(uint256 strxAmount) external returns (uint256 trxAmount);

    /**
     * @notice Sender requests to withdraw for a specific amount of trx
     * @param trxAmount the amount of trx to withdraw for
     * @return strxAmount the amount of strx to be burn
     */
    function withdrawExact(uint256 trxAmount) external returns (uint256 strxAmount);

    /**
     * @notice Sender requests to claim the earliest round of withdrawn trx
     * @return trxAmount the amount of trx claimed by sender
     */
    function claim() external returns (uint256 trxAmount);

    /**
     * @notice Sender requests to claim all ready-to-claim withdrawn trx
     * @return trxAmount the amount of trx claimed by sender
     */
    function claimAll() external returns (uint256 trxAmount);
}

// File: contracts/strx/interface/ISTRXForMarket.sol

pragma solidity ^0.8.18;

interface ISTRXForMarket {

    function marketDelegateResource(address payable renter, uint256 amount, uint256 resourceType) external;

    function marketUndelegateResource(address payable renter, uint256 amount, uint256 resourceType) external;

    function receiveRental() external payable;

    function getBalanceToUnfreeze() external view returns (uint256);
}

// File: contracts/strx/interface/IProxy.sol

pragma solidity ^0.8.18;

interface IProxy {
    function _acceptImplementation() external;
    function admin() external view returns (address);
}

// File: contracts/strx/interface/ITRC165.sol

pragma solidity ^0.8.18;

interface ITRC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/strx/src/TRC165.sol

pragma solidity ^0.8.18;

abstract contract TRC165 is ITRC165 {

    // ITRC165 interfaceId: 0x01ffc9a7
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(ITRC165).interfaceId;
    }
}

// File: contracts/strx/src/STRXG2.sol

pragma solidity ^0.8.18;

contract STRXG2 is STRXV1Storage, ISTRX, BaseSTRX, ISTRXForMarket, TRC165 {

    uint256 public constant ONE_TRX = 1e6;

    event RoundWithdraw(address user, uint256 round, uint256 amount);

    event RoundClaim(address user, uint256 round, uint256 amount);

    event RoundUnfreeze(uint256 round, uint256 bandwidth, uint256 energy);

    event RentFactorUpdated(uint256 oldFactor, uint256 newFactor);

    event RewardFactorUpdated(uint256 oldFactor, uint256 newFactor);

    event ReservesAdded(uint256 add, uint256 total);

    event ReservesClaimed(address receiver, bool payBadDebt, uint256 claim, uint256 total);

    event ReserveAdminUpdated(address oldReserveAdmin, address newReserveAdmin);

    event VoteOperatorUpdated(address oldVoteOperator, address newVoteOperator);

    event RentSupplied(uint256 amount, uint256 total);

    event SrListUpdated(address[] oldSrs, address[] newSrs);

    event MinFreezeAmountUpdated(uint256 oldAmount, uint256 newAmount);

    event MaxAmountForEnergyUpdated(uint256 oldAmount, uint256 newAmount);

    event Vote(address operator, address[] addresses, uint256[] votes);

    event Income(uint256 fromRent, uint256 fromVote);

    // operator, freeze balance, resource type
    event FreezeBalance(address operator, uint256 trxAmount, uint256 resourceType);

    // operator, unfreeze balance, resource type
    event UnfreezeBalance(address operator, uint256 trxAmount, uint256 resourceType);

    // -------------------------------- modifiers --------------------------------

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */

    modifier onlyAdmin() {
        require(msg.sender == admin, "permission denied: not admin");
        _;
    }

    modifier onlyReserveAdmin() {
        require(msg.sender == reserveAdmin, "permission denied: not reserveAdmin");
        _;
    }

    modifier onlyVoteOperatorOrAdmin() {
        require(msg.sender == voteOperator || msg.sender == admin, "permission denied: not voteOperator or admin");
        _;
    }

    modifier onlyVoteOperator() {
        require(msg.sender == voteOperator, "permission denied: not voteOperator");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == address(market), "permission denied: not market");
        _;
    }

    modifier _updateIndex() {
        _withdrawRewardRentalAndUpdateIndex();
        _;
        market.updateRentRate();
    }

    receive() payable external {
        _deposit(msg.sender, msg.value);
    }

    fallback() payable external {
        _deposit(msg.sender, msg.value);
    }

    function init(
        address _market,
        address payable _reserveAdmin,
        address _voteOperator,
        uint256 _rentFactor,
        uint256 _rewardFactor,
        uint256 _maxAmountForEnergy
    )
    external
    payable
    onlyAdmin
    {
        require(!initialized, "only initialize once");
        require(msg.value >= ONE_TRX, "init must provide at least 1 TRX");
        initialized = true;

        round = 1;

        uint256 _delayDays = getUnfreezeDelayDays();
        uint256 unfreezeTimeSpan = _delayDays * 1 days / CHAIN_UNFREEZE_MAX_TIMES;
        unfreezeCalmDownTime = block.timestamp + unfreezeTimeSpan;

        ReserveFactor memory factor = ReserveFactor(uint128(_rentFactor), uint128(_rewardFactor));
        reserveFactor = factor;
        require(_market != address(0), "market can't be empty");
        market = IMarketForSTRX(_market);
        reserveAdmin = _reserveAdmin;
        voteOperator = _voteOperator;
        minFreezeAmount = ONE_TRX;
        maxAmountForEnergy = _maxAmountForEnergy;

        setClaimable(0);
        setWithdrawal(0);
        setBalanceToFreeze(0);
        setBalanceToUnfreeze(0);

        _deposit(address(this), msg.value);
    }

    function _become(IProxy strx) external {
        require(msg.sender == strx.admin(), "only admin can change brains");
        strx._acceptImplementation();
    }

    function deposit() external payable returns (uint256) {
        return _deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 tokenAmount) external _updateIndex returns (uint256) {

        require(tokenAmount != 0, "ZERO_WITHDRAW");
        uint256 withdrawAmount = withdrawInternal(msg.sender, tokenAmount);
        require(withdrawAmount != 0, "ZERO_WITHDRAW_TRX");
        require(withdrawAmount + balanceToUnfreeze() <= totalUnfreezable(), "not enough balance to unfreeze");

        _updateWithdrawList(msg.sender, withdrawAmount);

        setWithdrawal(withdrawal() + withdrawAmount);
        setBalanceToUnfreeze(balanceToUnfreeze() + withdrawAmount);
        // unfreeze
        _unfreezeBalance();

        emit Withdraw(msg.sender, tokenAmount, withdrawAmount, balanceOf(msg.sender));
        return withdrawAmount;
    }

    function withdrawExact(uint256 trxAmount) external _updateIndex returns (uint256) {
        require(trxAmount != 0, "ZERO_WITHDRAW");
        uint256 tokenAmount = withdrawExactInternal(msg.sender, trxAmount);
        require(trxAmount + balanceToUnfreeze() <= totalUnfreezable(), "not enough balance to unfreeze");

        _updateWithdrawList(msg.sender, trxAmount);

        setWithdrawal(withdrawal() + trxAmount);
        setBalanceToUnfreeze(balanceToUnfreeze() + trxAmount);
        // unfreeze
        _unfreezeBalance();

        emit Withdraw(msg.sender, tokenAmount, trxAmount, balanceOf(msg.sender));
        return tokenAmount;
    }

    //    function cancelWithdraw() external _updateIndex returns (uint256, uint256) {
    //        return _cancelLastWithdrawAndDeposit(msg.sender);
    //    }


    function claim() external returns (uint256) {
        uint256 curTimestamp = block.timestamp;
        if (address(this).expireUnfreezeBalanceV2(curTimestamp) > 0) {
            setClaimable(claimable() + withdrawexpireunfreeze());
        }

        UnfreezingIndex memory index = userUnfreezingIndex[msg.sender];
        uint32 _claim = index.claimIndex;

        _claim = (_claim + 1) % USER_UNFREEZE_MAX_TIMES;

        UnfreezingInfo memory unfreezingInfo = userUnfreezingInfos[msg.sender][_claim];
        uint256 _round = uint256(unfreezingInfo.round);
        require(_round != 0, "No unfreeze to claim");

        uint256 _endTime = roundEndTime[_round];
        require(_endTime != 0 && curTimestamp >= _endTime, "Not time to claim");

        uint256 _amount = uint256(unfreezingInfo.underlyingToClaim);

        unfreezingInfo.round = 0;
        unfreezingInfo.underlyingToClaim = 0;
        userUnfreezingInfos[msg.sender][_claim] = unfreezingInfo;
        userUnfreezingIndex[msg.sender].claimIndex = _claim;

        _updateClaimableAndTransfer(msg.sender, _amount);
        emit RoundClaim(msg.sender, _round, _amount);
        return _amount;
    }

    function claimAll() external returns (uint256) {
        uint256 curTimestamp = block.timestamp;

        if (address(this).expireUnfreezeBalanceV2(curTimestamp) > 0) {
            setClaimable(claimable() + withdrawexpireunfreeze());
        }

        UnfreezingIndex memory index = userUnfreezingIndex[msg.sender];
        uint32 _claim = index.claimIndex;
        uint32 _nextClaim = _claim;

        uint256 _amount;
        UnfreezingInfo memory unfreezingInfo;
        uint256 _endTime;
        uint256 _round;
        uint256 _depositsToClaim;

        while (true) {

            _claim = (_claim + 1) % USER_UNFREEZE_MAX_TIMES;

            unfreezingInfo = userUnfreezingInfos[msg.sender][_claim];
            _round = uint256(unfreezingInfo.round);
            _endTime = roundEndTime[_round];
            if (_endTime == 0 || curTimestamp < _endTime) {
                break;
            } else {
                _depositsToClaim = uint256(unfreezingInfo.underlyingToClaim);
                _amount += _depositsToClaim;
                emit RoundClaim(msg.sender, _round, _depositsToClaim);

                unfreezingInfo.round = 0;
                unfreezingInfo.underlyingToClaim = 0;
                userUnfreezingInfos[msg.sender][_claim] = unfreezingInfo;
                _nextClaim = _claim;
            }
        }

        if (_nextClaim != index.claimIndex) {
            userUnfreezingIndex[msg.sender].claimIndex = _nextClaim;
        }

        _updateClaimableAndTransfer(msg.sender, _amount);
        return _amount;
    }

    function voteSrs(address[] calldata srs, uint256[] calldata percents) external onlyVoteOperator {
        uint256 srCount = srs.length;
        require(srCount != 0, "sr list can not be empty");
        require(srCount == percents.length, "sr list and percent list length not match");

        if (balanceToFreeze() >= minFreezeAmount){
            _withdrawRewardRentalAndUpdateIndex();
            _freezeBalance(0);
            market.updateRentRate();
        }

        uint256 _totalVoteCount = totalVoteCount(address(this));
        if (_totalVoteCount == 0) {
            return;
        }

        uint256[] memory votes = new uint256[](srCount);

        uint256 i;
        uint256 voted;
        for ( ; i < srCount - 1; i++) {
            votes[i] = _totalVoteCount * percents[i] / SCALE;
            voted += votes[i];
        }
        votes[srCount - 1] = _totalVoteCount - voted;

        vote(srs, votes);
        emit Vote(msg.sender, srs, votes);
    }

    function receiveRental() external payable onlyMarket {
        uint256 totalRent = totalRentIncome + msg.value;
        totalRentIncome = totalRent;
        emit RentSupplied(msg.value, totalRent);
    }

    function marketDelegateResource(
        address payable renter,
        uint256 amount,
        uint256 resourceType
    )
    external
    onlyMarket
    {
        renter.delegateResource(amount, resourceType);
    }

    function marketUndelegateResource(
        address payable renter,
        uint256 amount,
        uint256 resourceType
    )
    external
    onlyMarket
    {
        renter.unDelegateResource(amount, resourceType);
    }

    // add ability to unfreeze directly.
    // after unfreeze, the rate of each resource is changed, so _updateIndex is required.
    function unfreezeBalance() external _updateIndex returns (uint256, uint256) {
        return _unfreezeBalance();
    }

    // add ability to freeze directly.
    // after freeze, the rate of each resource is changed, so _updateIndex is required.
    function freezeBalance() external _updateIndex {
        _freezeBalance(0);
    }

    // add ability to updateIndex directly, useful when rate model params need to change.
    function updateIndex() external _updateIndex {
    }

    // -------------------------------- admin management functions --------------------------------

    function setReserveFactors(uint256 _newRentFactor, uint256 _newRewardFactor) external onlyAdmin _updateIndex {
        require(_newRentFactor <= SCALE, "rent factor exceed scale limit!");
        require(_newRewardFactor <= SCALE, "reward factor exceed scale limit!");

        ReserveFactor memory factor = reserveFactor;

        uint256 oldRentFactor = uint256(factor.rentFactor);
        if (oldRentFactor != _newRentFactor) {
            factor.rentFactor = uint128(_newRentFactor);
            emit RentFactorUpdated(oldRentFactor, _newRentFactor);
        }

        uint256 oldRewardFactor = uint256(factor.rewardFactor);
        if (oldRewardFactor != _newRewardFactor) {
            factor.rewardFactor = uint128(_newRewardFactor);
            emit RewardFactorUpdated(oldRewardFactor, _newRewardFactor);
        }

        reserveFactor = factor;
    }

    function setReserveAdmin(address payable _reserveAdmin) external onlyAdmin {
        address oldReserveAdmin = reserveAdmin;
        reserveAdmin = _reserveAdmin;

        emit ReserveAdminUpdated(oldReserveAdmin, _reserveAdmin);
    }

    function setVoteOperator(address _voteOperator) external onlyVoteOperatorOrAdmin {
        emit VoteOperatorUpdated(voteOperator, _voteOperator);
        voteOperator = _voteOperator;
    }

    function setMinFreezeAmount(uint256 amount) external onlyVoteOperator {
        require(amount >= ONE_TRX, "minimal freeze amount must be no less than 1 TRX");
        emit MinFreezeAmountUpdated(minFreezeAmount, amount);

        minFreezeAmount = amount;
    }

    function setMaxAmountForEnergy(uint256 amount) external onlyAdmin {
        emit MaxAmountForEnergyUpdated(maxAmountForEnergy, amount);

        maxAmountForEnergy = amount;
    }

    function claimReserves(uint256 amount) external onlyReserveAdmin {
        require(amount > 0, "claim amount should be larger than 0");
        uint256 totalReserves = reserves;
        uint256 claimed = claimedReserves;
        require(totalReserves >= claimed + amount, "reserves not enough");

        claimed += amount;
        claimedReserves = claimed;

        address payable receiver = reserveAdmin;
        _doTransferOut(receiver, amount);
        emit ReservesClaimed(receiver, false, amount, claimed);
    }

    function reservePayBadDebt(uint256 amount) external onlyReserveAdmin {

        require(amount > 0, "pay badDebt amount should be larger than 0");
        require(address(market) != address(0), "market is empty");

        uint256 totalReserves = reserves;
        uint256 claimed = claimedReserves;
        require(totalReserves >= claimed + amount, "reserves not enough");

        uint256 gap = market.badDebtGap();
        require(gap > 0, "badDebt gap is zero");
        if (amount > gap) {
            amount = gap;
        }

        claimed += amount;
        claimedReserves = claimed;

        market.repayBadDebt{value: amount}();
        emit ReservesClaimed(msg.sender, true, amount, claimed);
    }

    function balanceOfUnderlying(address _account) external _updateIndex returns (uint256) {
        return viewBalanceOfUnderlying(_account);
    }

    function balanceStructure() external _updateIndex returns (uint256, uint256, uint256, uint256) {
        return viewBalanceStructure();
    }

    function assetsStructure() external _updateIndex returns
    (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    )
    {
        return viewAssetsStructure();
    }

    // ISTRX interfaceId: 0x6a2af32e
    // ITRC20 interfaceId: 0x942e8b22
    // ITRC165 interfaceId: 0x01ffc9a7
    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return interfaceID == type(ISTRX).interfaceId ||
        interfaceID == type(ITRC20).interfaceId ||
        super.supportsInterface(interfaceID);
    }

    // -------------------------------- public write functions --------------------------------

    // -------------------------------- public view functions --------------------------------
    function viewBalanceOfUnderlying(address _account) public view returns (uint256) {
        return _balance[_account] * exchangeRate() / DECIMAL_MULTIPLIER;
    }

    function viewBalanceStructure() public view returns (uint256, uint256, uint256, uint256) {
        return (address(this).balance, claimable(), reserves - claimedReserves, balanceToFreeze());
    }

    function viewAssetsStructure() public view returns
    (
        uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256
    )
    {
        return (
        totalUnderlying(),
        withdrawal(),
        totalFrozen(),
        withdrawal() - claimable() - balanceToUnfreeze(),
        address(this).balance,
        claimable(),
        reserves - claimedReserves,
        balanceToFreeze()
        );
    }

    function totalDelegated() public view returns (uint256) {
        return address(this).totalDelegatedResource(0) + address(this).totalDelegatedResource(1);
    }

    function totalUnfreezable() public view returns (uint256) {
        return address(this).unfreezableBalanceV2(0) + address(this).unfreezableBalanceV2(1);
    }

    function totalFrozen() public view returns (uint256) {
        return totalDelegated() + totalUnfreezable();
    }

    function totalFrozenOfType(uint256 resourceType) public view returns (uint256) {
        return address(this).totalDelegatedResource(resourceType) + address(this).unfreezableBalanceV2(resourceType);
    }

    function getBalanceToUnfreeze() public view returns (uint256) {
        return balanceToUnfreeze();
    }

    function availableUnfreezeSize() public view returns (uint256) {
        return address(this).availableUnfreezeV2Size();
    }

    function getUnfreezeDelayDays() public view returns (uint256) {
        return chain.unfreezeDelayDays;
    }

    function getVoteRewardAmount() public view returns (uint256) {
        return rewardBalance();
    }

    /**
    * @notice Send funds to the pool and exchange tokens
    * @return Amount of sTRX shares generated
    */
    function _deposit(address user, uint256 amount) internal _updateIndex returns (uint256) {
        require(initialized, "not initialized");
        require(amount != 0, "zero deposit");

        uint256 tokens = depositInternal(user, amount);
        _freezeBalance(amount);
        emit Deposit(user, amount, tokens, balanceOf(user));
        // return tokens
        return tokens;
    }

    function _settleIncome(uint256 rental, uint256 reward) internal {
        emit Income(rental, reward);

        uint256 income = rental + reward;
        ReserveFactor memory factor = reserveFactor;

        uint256 newReserves = (rental * uint256(factor.rentFactor) + reward * uint256(factor.rewardFactor)) / SCALE;
        _addReserves(newReserves);

        uint256 remain = income - newReserves;
        updateExchangeRate(remain);

        setBalanceToFreeze(balanceToFreeze() + remain);
    }

    function _addReserves(uint256 add) internal {
        if (add == 0) {
            return;
        }
        uint256 all = reserves + add;
        reserves = all;
        emit ReservesAdded(add, all);
    }

    function _updateWithdrawList(address user, uint256 withdrawAmount) internal {
        UnfreezingIndex memory index = userUnfreezingIndex[user];
        uint32 _withdraw = index.withdrawIndex;

        UnfreezingInfo memory unfreezingInfo = userUnfreezingInfos[user][_withdraw];
        uint256 curRound = round;
        if (unfreezingInfo.round == curRound) {
            unfreezingInfo.underlyingToClaim += uint64(withdrawAmount);
            userUnfreezingInfos[user][_withdraw] = unfreezingInfo;
            emit RoundWithdraw(user, curRound, unfreezingInfo.underlyingToClaim);
        } else {
            _withdraw = (_withdraw + 1) % USER_UNFREEZE_MAX_TIMES;
            require(_withdraw != index.claimIndex, "MAX withdraw length");
            UnfreezingInfo memory info = UnfreezingInfo(1, uint64(curRound), uint64(withdrawAmount));
            userUnfreezingInfos[user][_withdraw] = info;
            userUnfreezingIndex[user].withdrawIndex = _withdraw;
            emit RoundWithdraw(user, curRound, withdrawAmount);
        }
    }

    function _withdrawRewardRentalAndUpdateIndex() internal {
        uint256 rental;

        if (address(market) != address(0)) {
            uint256 prev = totalRentIncome;
            market.claimRental();
            rental = totalRentIncome - prev;
        }

        uint256 reward;
        if (rewardBalance() > 0) {
            reward = withdrawreward();
        }

        if (rental > 0 || reward > 0) {
            _settleIncome(rental, reward);
        }
    }

    function _updateClaimableAndTransfer(address _user, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        setClaimable(claimable() - _amount);

        setWithdrawal(withdrawal() - _amount);

        _doTransferOut(payable(_user), _amount);
        emit Claim(_user, _amount);
    }

    function _freezeBalance(uint256 amount) private {
        uint256 toFreeze = balanceToFreeze() + amount;

        // freeze balance must be no less than 1TRX
        if (toFreeze >= minFreezeAmount) {
            (uint256 toFreezeBandwidth, uint256 toFreezeEnergy) = _getFreezeAmountForResourceType(toFreeze);

            if (toFreezeBandwidth > 0) {
                freezebalancev2(toFreezeBandwidth, 0);
                emit ResourceObtained(toFreezeBandwidth, 0);
                emit FreezeBalance(msg.sender, toFreezeBandwidth, 0);
            }

            if (toFreezeEnergy > 0) {
                freezebalancev2(toFreezeEnergy, 1);
                emit ResourceObtained(toFreezeEnergy, 1);
                emit FreezeBalance(msg.sender, toFreezeEnergy, 1);
            }

            emit BalanceFrozen(toFreeze);
            toFreeze = 0;
        }

        if (balanceToFreeze() != toFreeze) {
            setBalanceToFreeze(toFreeze);
        }
    }

    function _unfreezeBalance() private returns (uint256, uint256) {
        uint256 blockTimestamp = block.timestamp;
        uint256 _balanceToUnfreeze = balanceToUnfreeze();
        if (blockTimestamp <= unfreezeCalmDownTime || _balanceToUnfreeze == 0 ||
            address(this).availableUnfreezeV2Size() == 0) {
            return (0, 0);
        }

        (uint256 bandwidthToUnfreeze, uint256 energyToUnfreeze) = _getUnfreezeResourceAmount(_balanceToUnfreeze);

        uint256 unfreezeTimeSpan;
        uint256 _delayDays = getUnfreezeDelayDays();

        uint256 prevBalance = address(this).balance;

        if (bandwidthToUnfreeze > 0) {
            unfreezebalancev2(bandwidthToUnfreeze, 0);
            emit BalanceUnfrozen(bandwidthToUnfreeze);
            emit ResourceReleased(bandwidthToUnfreeze, 0);
            emit UnfreezeBalance(msg.sender, bandwidthToUnfreeze, 0);
            unfreezeTimeSpan += _delayDays * 1 days / CHAIN_UNFREEZE_MAX_TIMES;
        }

        if (energyToUnfreeze > 0) {
            if (address(this).availableUnfreezeV2Size() == 0) {
                energyToUnfreeze = 0;
            }
            else {
                unfreezebalancev2(energyToUnfreeze, 1);
                emit BalanceUnfrozen(energyToUnfreeze);
                emit ResourceReleased(energyToUnfreeze, 1);
                emit UnfreezeBalance(msg.sender, energyToUnfreeze, 1);
                unfreezeTimeSpan += _delayDays * 1 days / CHAIN_UNFREEZE_MAX_TIMES;
            }
        }

        uint256 afterBalance = address(this).balance;
        if (afterBalance > prevBalance) {
            setClaimable(claimable() + afterBalance - prevBalance);
        }

        setBalanceToUnfreeze(_balanceToUnfreeze - energyToUnfreeze - bandwidthToUnfreeze);

        uint256 _round = round;
        roundEndTime[_round] = blockTimestamp + _delayDays * 1 days;
        round = _round + 1;

        unfreezeCalmDownTime = blockTimestamp + unfreezeTimeSpan;

        emit RoundUnfreeze(_round, bandwidthToUnfreeze, energyToUnfreeze);
        return (bandwidthToUnfreeze, energyToUnfreeze);
    }

    function _getFreezeAmountForResourceType(uint256 amount) private view returns (uint256, uint256) {
        uint256 _frozenEnergy = totalFrozenOfType(1);
        uint256 _maxAmountForEnergy = maxAmountForEnergy;

        if (_frozenEnergy + ONE_TRX > _maxAmountForEnergy) {
            return (amount, 0);
        }

        uint256 total = _frozenEnergy + amount;
        if (total <= _maxAmountForEnergy) {
            return (0, amount);
        }

        uint256 bandwidthToFreeze = total - _maxAmountForEnergy;
        if (bandwidthToFreeze < ONE_TRX) {
            bandwidthToFreeze = ONE_TRX;
        }
        uint256 energyToFreeze = amount - bandwidthToFreeze;
        if (energyToFreeze < ONE_TRX) {
            bandwidthToFreeze += energyToFreeze;
            energyToFreeze = 0;
        }
        return (bandwidthToFreeze, energyToFreeze);
    }

    function _getUnfreezeResourceAmount(uint256 totalAmount) private view returns (uint256, uint256) {

        uint256 energyToUnfreeze;
        uint256 totalToUnfreeze = totalAmount;
        uint256 totalFrozenEnergy = totalFrozenOfType(1);
        uint256 unfreezableEnergy = address(this).unfreezableBalanceV2(1);
        if (totalFrozenEnergy > maxAmountForEnergy) {
            energyToUnfreeze = totalFrozenEnergy - maxAmountForEnergy;
            if (energyToUnfreeze > unfreezableEnergy) {
                energyToUnfreeze = unfreezableEnergy;
            }
            if (totalToUnfreeze <= energyToUnfreeze) {
                return (0, totalToUnfreeze);
            }
            totalToUnfreeze -= energyToUnfreeze;
        }

        uint256 unfreezableBandwidth = address(this).unfreezableBalanceV2(0);
        if (totalToUnfreeze <= unfreezableBandwidth) {
            return (totalToUnfreeze, energyToUnfreeze);
        }

        energyToUnfreeze = totalAmount - unfreezableBandwidth;
        if (energyToUnfreeze > unfreezableEnergy) {
            energyToUnfreeze = unfreezableEnergy;
        }
        return (unfreezableBandwidth, energyToUnfreeze);
    }

}
