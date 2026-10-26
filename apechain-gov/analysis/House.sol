//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;



interface IGovernanceManager {

    function RNG() external view returns (address);

    function owner() external view returns (address);

    function referralManager() external view returns (address);

    function feeReceiver() external view returns (address);

    function claimManager() external view returns (address);

    function house() external view returns (address);

    function isGame(address game) external view returns (bool);

    function userInfoTracker() external view returns (address);

    function canPlayForOthers(address addr) external view returns (bool);

    function paused() external view returns (bool);

    function isAdmin(address admin) external view returns (bool);

}



interface IRNG {

    function requestRandom(bytes32 userRandomNumber, uint8 numWords) external payable returns (uint64);

    function getFee() external view returns (uint256);

}



contract ApeOwnable {



    // Governance Manager

    IGovernanceManager public constant manager = IGovernanceManager(0x8632f22e5A921C751CFbBFF92F058A3b11E96b8a);



    modifier onlyOwner() {

        require(

            msg.sender == manager.owner(),

            'Only Owner'

        );

        _;

    }



    modifier onlyGame() {

        require(

            manager.isGame(msg.sender),

            'UnAuthorized'

        );

        _;

    }



    modifier onlyRNG() {

        require(

            msg.sender == manager.RNG(),

            'Only RNG Contract'

        );

        _;

    }



    modifier validatePlayer(address player) {

        if (player != msg.sender) {

            require(

                manager.canPlayForOthers(msg.sender),

                'UnAuthorized To Play For Others'

            );

        }

        _;

    }



    modifier notPaused() {

        require(

            manager.paused() == false,

            'All Games Paused'

        );

        _;

    }



    modifier onlyAdmin() {

        require(

            manager.isAdmin(msg.sender),

            'UnAuthorized'

        );

        _;

    }

}



interface IERC20 {



    function totalSupply() external view returns (uint256);

    

    function symbol() external view returns(string memory);

    

    function name() external view returns(string memory);



    /**

     * @dev Returns the amount of tokens owned by `account`.

     */

    function balanceOf(address account) external view returns (uint256);

    

    /**

     * @dev Returns the number of decimal places

     */

    function decimals() external view returns (uint8);



    /**

     * @dev Moves `amount` tokens from the caller's account to `recipient`.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transfer(address recipient, uint256 amount) external returns (bool);



    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address owner, address spender) external view returns (uint256);



    /**

     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * IMPORTANT: Beware that changing an allowance with this method brings the risk

     * that someone may use both the old and the new allowance by unfortunate

     * transaction ordering. One possible solution to mitigate this race

     * condition is to first reduce the spender's allowance to 0 and set the

     * desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     *

     * Emits an {Approval} event.

     */

    function approve(address spender, uint256 amount) external returns (bool);



    /**

     * @dev Moves `amount` tokens from `sender` to `recipient` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    /**

     * @dev Emitted when `value` tokens are moved from one account (`from`) to

     * another (`to`).

     *

     * Note that `value` may be zero.

     */

    event Transfer(address indexed from, address indexed to, uint256 value);



    /**

     * @dev Emitted when the allowance of a `spender` for an `owner` is set by

     * a call to {approve}. `value` is the new allowance.

     */

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false

library TransferHelper {

    function safeApprove(

        address token,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('approve(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            'TransferHelper::safeApprove: approve failed'

        );

    }



    function safeTransfer(

        address token,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            'TransferHelper::safeTransfer: transfer failed'

        );

    }



    function safeTransferFrom(

        address token,

        address from,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            'TransferHelper::transferFrom: transferFrom failed'

        );

    }



    function safeTransferETH(address to, uint256 value) internal {

        (bool success, ) = to.call{value: value}(new bytes(0));

        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');

    }

}



interface IClaimManager {

    function credit(

        uint256 GAME_ID,

        address user

    ) external payable;

}



interface IHouse {

    

    /**

        House has profited from game, call this to send value into the house and emit the correct event for SubGraphs

     */

    function houseProfit(uint256 GAME_ID) external payable;



    /**

        Function Games Call to tell the house that a user has won the bet

     */

    function payout(uint256 GAME_ID, address user, uint256 value) external;

    

    /**

        Read function to determine the maximum payout allowed by the house at the current time

     */

    function maxPayout() external view returns (uint256);



    /**

        Randomness has been requested, withdrawals are paused until it is resolved by called `randomRequestResolved()`

     */

    function randomRequested() external;



    /**

        Resolves a random request from chainlink, allowing house users to withdraw

     */

    function randomRequestResolved() external;



}



interface IArbInfo {

    function configureAutomaticYield() external;

    function configureVoidYield() external;

    function configureDelegateYield(address delegate) external;

}



abstract contract OnChainYieldManager {

    IArbInfo private constant ArbInfo = IArbInfo(0x0000000000000000000000000000000000000065);



    function _configureAutomaticYield() internal {

        ArbInfo.configureAutomaticYield();

    }



    function _configureVoidYield() internal {

        ArbInfo.configureVoidYield();

    }



    function _configureDelegateYield(address _delegate) internal {

        ArbInfo.configureDelegateYield(_delegate);

    }

}





contract HouseDataTracking {



    struct PriceChange {

        uint256 price;

        uint256 timestamp;

    }



    uint256 internal priceChangeIndex;



    mapping ( uint256 => PriceChange ) private priceChanges;



    function log(uint256 price) internal {

        priceChanges[priceChangeIndex] = PriceChange(price, block.timestamp);

        unchecked {

            ++priceChangeIndex;

        }

    }



    function getPriceChange(uint256 index) external view returns (uint256, uint256) {

        return (priceChanges[index].price, priceChanges[index].timestamp);

    }



    function getPriceChangeCount() external view returns (uint256) {

        return priceChangeIndex;

    }



    function batchGetPriceChange(uint256 startIndex, uint256 endIndex) external view returns (uint256[] memory, uint256[] memory) {

        if (endIndex > priceChangeIndex) {

            endIndex = priceChangeIndex;

        }

        if (startIndex >= endIndex || priceChangeIndex == 0) {

            return (new uint256[](0), new uint256[](0));

        }



        uint256[] memory prices = new uint256[](endIndex - startIndex);

        uint256[] memory timestamps = new uint256[](endIndex - startIndex);



        for (uint256 i = startIndex; i < endIndex;) {

            prices[i - startIndex] = priceChanges[i].price;

            timestamps[i - startIndex] = priceChanges[i].timestamp;

            unchecked { ++i; }

        }



        return (prices, timestamps);

    }



    function getListOfPriceChanges(uint256[] calldata indexes) external view returns (uint256[] memory, uint256[] memory) {

        uint len = indexes.length;

        uint256[] memory prices = new uint256[](len);

        uint256[] memory timestamps = new uint256[](len);



        for (uint256 i = 0; i < len;) {

            prices[i] = priceChanges[indexes[i]].price;

            timestamps[i] = priceChanges[indexes[i]].timestamp;

            unchecked { ++i; }

        }



        return (prices, timestamps);

    }



    function getEvenlySplitPriceChanges(uint256 numDataPoints) external view returns (uint256[] memory, uint256[] memory) {

        if (priceChangeIndex == 0) {

            return (new uint256[](0), new uint256[](0));

        }



        if (numDataPoints > priceChangeIndex) {

            numDataPoints = priceChangeIndex;

        }



        uint256[] memory prices = new uint256[](numDataPoints);

        uint256[] memory timestamps = new uint256[](numDataPoints);



        // calculate step, how many price changes to skip

        uint256 step = priceChangeIndex / ( numDataPoints - 1 );



        for (uint256 i = 0; i < numDataPoints - 1;) {

            prices[i] = priceChanges[i * step].price;

            timestamps[i] = priceChanges[i * step].timestamp;

            unchecked { ++i; }

        }



        // set most recent prices

        prices[numDataPoints - 1] = priceChanges[priceChangeIndex - 1].price;

        timestamps[numDataPoints - 1] = priceChanges[priceChangeIndex - 1].timestamp;



        return (prices, timestamps);

    }



    function getApproxAverageEvenlySplitPriceChanges(uint256 numDataPoints, uint256 averageCount) external view returns (uint256[] memory, uint256[] memory) {

        if (priceChangeIndex == 0) {

            return (new uint256[](0), new uint256[](0));

        }



        if (numDataPoints > priceChangeIndex) {

            numDataPoints = priceChangeIndex;

        }



        // create arrays to store prices and timestamps

        uint256[] memory prices = new uint256[](numDataPoints);

        uint256[] memory timestamps = new uint256[](numDataPoints);



        // calculate step, how many price changes to skip

        uint256 step = priceChangeIndex / ( numDataPoints - 1 );

        if (step <= averageCount) {

            averageCount = step - 1;

        }



        // loop through data points, determining average price changes around each step

        for (uint256 i = 0; i < numDataPoints - 1;) {

            

            // find average price changes around each step

            uint256 sumPrice = 0;

            uint256 sumTimestamp = 0;

            for (uint j = 0; j < averageCount;) {

                unchecked { 

                    sumPrice += priceChanges[(i * step) + j].price;

                    sumTimestamp += priceChanges[(i * step) + j].timestamp;

                    ++j; 

                }

            }



            prices[i] = sumPrice / averageCount;

            timestamps[i] = sumTimestamp / averageCount;

            unchecked { ++i; }

        }



        // set most recent prices

        prices[numDataPoints - 1] = priceChanges[priceChangeIndex - 1].price;

        timestamps[numDataPoints - 1] = priceChanges[priceChangeIndex - 1].timestamp;



        return (prices, timestamps);

    }



    function getAverageTimeAndPrice(uint256[] calldata indexes) external view returns (uint256, uint256) {

        uint len = indexes.length;

        uint256 sumPrice;

        uint256 sumTimestamp;



        for (uint256 i = 0; i < len;) {

            unchecked {

                sumPrice += priceChanges[indexes[i]].price;

                sumTimestamp += priceChanges[indexes[i]].timestamp;

                ++i;

            }

        }



        return (sumPrice / len, sumTimestamp / len);

    }

}



interface IMigrator {

    function migrate(address user, bytes calldata data) external payable;

}



/**

    House Contract is responsible for managing House funds.

    Only games can interact with functions that affect the house balance.

 */

contract House is ApeOwnable, IHouse, IERC20, HouseDataTracking, OnChainYieldManager {



    // Trackable User Info

    struct UserInfo {

        uint256 balance;

        uint256 totalStaked;

        uint256 totalWithdrawn;

        uint256 unlockTime;

        bool isFeeExempt;

        uint256 maxContribution;

    }



    // User -> UserInfo

    mapping ( address => UserInfo ) public userInfo;



    // maps GAME_ID to max payout per game, if zero, use default maxPayoutPerGame variable

    mapping ( uint256 => uint256 ) public gameMaxPayout;



    // Whether or not staking is open to the public

    bool public publicStaking = true;



    // Fee Denom

    uint256 private constant FEE_DENOM = 10_000;



    // total supply of staked units

    uint256 public totalShares;



    // lock time

    uint256 public lockTime = 15 minutes;



    // precision factor

    uint256 private constant precision = 10**18;



    // Max Payout per game percentage

    uint256 public maxPayoutPerGame = 250; // 2.5% of total house balance



    // Exit Fee, reflected to house participants

    uint256 public exitFee = 200; // 2% exit fee, up to 10% max



    // Percentage of entry/exit fee that is reflected to the pool

    uint256 public reflectPercentage = 5000; // 50%



    // Halts Withdrawals While Randomness is being Requested

    uint256 public resolutionsPending;



    // Determines whether or not halting withdrawals while game resolutions are pending is permitted

    bool public enableInGamePausing = false;



    // The minimum price the house can fall to before PvH games are disabled

    // This value can be re-set if this occurs, allowing PvH games to continue

    // The idea for this is to allow time for devs to source a potential issue in a game that allowed the price to fall so low

    // This exists to protect house stakers from losing large sums of value too quickly

    uint256 public MIN_PRICE;



    // Migrator Contract, only will be set if there is a new house contract to migrate into

    IMigrator public migrator;



    // Log Index

    uint256 public logIndex = 5;



    // Reentrancy Guard

    uint256 private constant _NOT_ENTERED = 1;

    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    modifier nonReentrant() {

        require(_status != _ENTERED, "Reentrancy Guard call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;

    }



    // Events

    event Deposit(address depositor, uint256 amount);

    event Withdraw(address withdrawer, uint256 amount);

    event Migrate(address withdrawer, uint256 amount);

    event HouseWon(uint256 GAME_ID, uint256 profit);

    event HouseLost(uint256 GAME_ID, address user, uint256 loss);



    constructor() {



        // set reentrancy

        _status = _NOT_ENTERED;



        // enable automatic yield

        _configureAutomaticYield();



        emit Transfer(address(0), address(0), 0);

    }



    function name() external pure override returns (string memory) {

        return "APE House";

    }

    function symbol() external pure override returns (string memory) {

        return "House APE";

    }

    function decimals() external pure override returns (uint8) {

        return 18;

    }

    function totalSupply() external view override returns (uint256) {

        return address(this).balance;

    }



    function maxPayout() public view returns (uint256) {

        return ( address(this).balance * maxPayoutPerGame ) / FEE_DENOM;

    }



    function getMaxPayoutForGame(uint256 GAME_ID) public view returns (uint256) {

        uint256 maxPayout_ = gameMaxPayout[GAME_ID] > 0 ? gameMaxPayout[GAME_ID] : maxPayoutPerGame;

        return ( address(this).balance * maxPayout_ ) / FEE_DENOM;

    }



    /** Shows The Value In Native Of The Users House Native Tokens */

    function balanceOf(address account) public view override returns (uint256) {

        return ReflectionsFromContractBalance(userInfo[account].balance);

    }



    function allowance(address, address) external pure override returns (uint256) { 

        return 0;

    }

    

    function approve(address, uint256) public override returns (bool) {

        emit Approval(msg.sender, address(0), 0);

        return true;

    }

  

    function transfer(address recipient, uint256 amount) external override returns (bool) {

        if (recipient == msg.sender) {

            withdraw(amount);

        }

        return true;

    }

    function transferFrom(address, address recipient, uint256 amount) external override returns (bool) {

        if (recipient == msg.sender) {

            withdraw(amount);

        }        

        return true;

    }



    function setLockTime(uint256 newLockTime) external onlyOwner {

        require(

            newLockTime <= 100 days,

            'Lock Time Too Long'

        );

        lockTime = newLockTime;

    }



    function setMaxContribution(address user, uint256 max) external onlyOwner {

        userInfo[user].maxContribution = max;

    }



    function setFeeExemption(address user, bool isExempt) external onlyOwner {

        userInfo[user].isFeeExempt = isExempt;

    }



    function setPublicStaking(bool isPublic) external onlyOwner {

        publicStaking = isPublic;

    }



    function setExitFee(uint256 exitFee_) external onlyOwner {

        require(

            exitFee_ <= FEE_DENOM / 10,

            'Exit Fee Too High'

        );

        exitFee = exitFee_;

    }



    function setReflectionPercentage(uint256 newPercent) external onlyOwner {

        require(

            newPercent <= FEE_DENOM,

            'Reflect Percent Too High'

        );

        reflectPercentage = newPercent;

    }



    /**

        Just in case resolutionsPending gets stuck above zero due to an error with VRF, etc

        Cannot increase the value greater than it currently is -- that would lock people in the House for forever

        Can only reduce the value

     */

    function hardSetResolutionsPending(uint256 resolutionsPending_) external onlyOwner {

        require(

            resolutionsPending_ < resolutionsPending,

            'Cannot Manually Increase This Value'

        );

        resolutionsPending = resolutionsPending_;

    }



    /**

        Enables Pausing withdrawals while games are awaiting resolution from VRF

     */

    function setEnableInGamePausing(bool isEnabled) external onlyOwner {

        enableInGamePausing = isEnabled;

        if (isEnabled) {

            resolutionsPending = 0;

        }

    }



    function recoverForeignToken(address token) external onlyOwner {

        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));

    }

    

    function setMaxPayoutPerGame(uint256 newMaxPayout) external onlyOwner {

        require(

            newMaxPayout <= FEE_DENOM / 4,

            'Max Payout Percentage Too High'

        );

        maxPayoutPerGame = newMaxPayout;

    }



    function setGameMaxPayout(uint256 GAME_ID, uint256 newMaxPayout) external onlyOwner {

        require(

            newMaxPayout <= FEE_DENOM / 4,

            'Max Payout Percentage Too High'

        );

        gameMaxPayout[GAME_ID] = newMaxPayout;

    }



    function setMinPrice(uint256 percentOfCurrent) external onlyOwner {

        require(

            percentOfCurrent <= 999,

            'Min Price Cannot Exceed 99.9% Of Current Value'

        );

        MIN_PRICE = ( _calculatePrice() * percentOfCurrent ) / 1_000;

    }



    function setMigrator(address migrator_) external onlyOwner {

        migrator = IMigrator(migrator_);

    }



    function setLogIndex(uint256 newLogIndex) external onlyOwner {

        logIndex = newLogIndex;

    }



    function migrate(bytes calldata data) external nonReentrant {

        require(

            address(migrator) != address(0),

            'No Migrator'

        );



        // user amount

        uint256 userBalance = userInfo[msg.sender].balance;

        require(

            userBalance > 0,

            'Zero Balance'

        );



        // native amount from balance

        uint256 nativeAmount = ReflectionsFromContractBalance(userBalance);



        // burn user balance

        _burn(msg.sender, userBalance, nativeAmount);



        // increment total withdrawn

        unchecked {

            userInfo[msg.sender].totalWithdrawn += nativeAmount;

        }

        

        // emit Event

        emit Migrate(msg.sender, nativeAmount);



        // send value to user

        migrator.migrate{value: nativeAmount}(msg.sender, data);

    }



    /**

        Deposits Native From Sender

        Locks In Contract, Minting Native House Tokens

     */

    function deposit() external payable nonReentrant {

        require(

            msg.value > 0,

            'Zero Value'

        );

        require(

            address(migrator) == address(0),

            'Migration In Progress'

        );



        // Track Balance Before Deposit

        uint previousBalance = address(this).balance - msg.value;



        // mint appropriate balance to recipient

        if (totalShares == 0 || previousBalance == 0) {

            _registerFirstPurchase(msg.sender, msg.value);

        } else {

            _mintTo(msg.sender, msg.value, previousBalance);

        }



        if (publicStaking == false) {

            require(

                balanceOf(msg.sender) <= userInfo[msg.sender].maxContribution,

                'Max Contribution Exceeded'

            );

        }

    }



    /**

        Redeems `amount` of Native, As Seen From BalanceOf()

     */

    function withdraw(uint256 amount) public nonReentrant returns (uint256) {

        require(

            address(migrator) == address(0),

            'Migration In Progress'

        );



        // check for in-Game Pausing

        if (enableInGamePausing == true) {

            require(

                resolutionsPending == 0,

                'Game Resolutions Are Pending'

            );

        }



        // ensure lock time

        require(

            timeUntilUnlock(msg.sender) == 0,

            'Not Yet Time'

        );



        // get user balance as seen from balanceOf

        uint256 userBal = balanceOf(msg.sender);



        if (amount > userBal) {

            amount = userBal;

        }



        // Turn Native Amount Into Contract Balance Amount

        uint House_Amount = amount == userBal ? userInfo[msg.sender].balance : NativeToContractBalance(amount);



        require(

            userInfo[msg.sender].balance > 0 &&

            userInfo[msg.sender].balance >= House_Amount &&

            userBal >= amount &&

            amount > 0 &&

            House_Amount > 0,

            'Insufficient Funds'

        );



        // burn House Tokens From Sender

        _burn(msg.sender, House_Amount, amount);



        // increment total withdrawn

        unchecked {

            userInfo[msg.sender].totalWithdrawn += amount;

        }

        

        // emit Event

        emit Withdraw(msg.sender, amount);



        // if fees exist, apply them

        if (exitFee > 0 && userInfo[msg.sender].isFeeExempt == false) {



            // split up fee and nonReflected Fee

            uint256 fee = ( amount * exitFee ) / FEE_DENOM;

            uint256 nonReflectFee = ( fee * reflectPercentage ) / FEE_DENOM;



            if (nonReflectFee > 0) {

                // send fee to receiver

                TransferHelper.safeTransferETH(manager.feeReceiver(), nonReflectFee);

            }



            // send value to user

            TransferHelper.safeTransferETH(msg.sender, amount - fee);

        } else {

            // send value to user

            TransferHelper.safeTransferETH(msg.sender, amount);

        }



        // log price change

        log(_calculatePrice());

        

        // return send amount

        return amount;

    }



    receive() external payable {

        require(totalShares > 0, 'Zero Shares');

        require(_status != _ENTERED, "Reentrancy Guard call");

    }



    function randomRequested() external override nonReentrant onlyGame {

        require(

            _calculatePrice() >= MIN_PRICE,

            'PRICE TOO LOW, PvH GAMES PAUSED'

        );



        // randomly log price approximately every 8 games, no need to be exact

        if (block.number % logIndex == 0) {

            // log price change

            log(_calculatePrice());

        }



        if (enableInGamePausing == false) {

            return;

        }

        unchecked {

            ++resolutionsPending;

        }

    }



    function randomRequestResolved() external override nonReentrant onlyGame {

        if (enableInGamePausing == false) {

            return;

        }

        // subtract resolutions pending

        if (resolutionsPending > 0) {

            unchecked {

                --resolutionsPending;

            }

        }

    }



    /**

        Request A Payout from the house from a successful Game.

        Only callable by Game Contracts

     */

    function payout(uint256 GAME_ID, address user, uint256 value) external override nonReentrant onlyGame {



        // get max payout

        uint256 maxPayout_ = getMaxPayoutForGame(GAME_ID);



        // send amount

        uint256 sendAmount = value >= maxPayout_ ? maxPayout_ : value;



        // add to user's claim contract balance to avoid reentrancy

        IClaimManager(manager.claimManager()).credit{value: sendAmount}(

            GAME_ID,

            user

        );



        // emit house lost event

        emit HouseLost(GAME_ID, user, sendAmount);

    }



    function houseProfit(uint256 GAME_ID) external payable override onlyGame nonReentrant {

        emit HouseWon(GAME_ID, msg.value);

    }



    /**

        Registers the First Stake

     */

    function _registerFirstPurchase(address user, uint received) internal {

        

        // increment total staked

        userInfo[user].totalStaked += received;



        // mint House Tokens To Sender

        _mint(user, received, received);



        // log price change

        log(_calculatePrice());



        emit Deposit(user, received);

    }



    function _mintTo(address sender, uint256 received, uint256 previousBalance) internal {

        // Number Of House Tokens To Mint

        uint nToMint = ( totalShares * received ) / previousBalance;

        require(

            nToMint > 0,

            'Zero To Mint'

        );



        // increment total staked

        userInfo[sender].totalStaked += received;



        // mint House Tokens To Sender

        _mint(sender, nToMint, received);



        // log price change

        log(_calculatePrice());



        emit Deposit(sender, received);

    }





    /**

     * Burns `amount` of Contract Balance Token

     */

    function _burn(address from, uint256 amount, uint256 nativeAmount) private {



        // update balances

        userInfo[from].balance -= amount;

        totalShares -= amount;

        

        // emit Transfer

        emit Transfer(from, address(0), nativeAmount);

    }



    /**

     * Mints `amount` of Contract Balance Token

     */

    function _mint(address to, uint256 amount, uint256 nativeWorth) private {

        unchecked {

            userInfo[to].balance += amount;

            totalShares += amount;

        }

        userInfo[to].unlockTime = block.timestamp + lockTime;

        emit Transfer(address(0), to, nativeWorth);

    }



    /**

        Fetches the time until a user's staked amount can be withdrawn

     */

    function timeUntilUnlock(address user) public view returns (uint256) {

        return userInfo[user].unlockTime > block.timestamp ? userInfo[user].unlockTime - block.timestamp : 0;

    }



    /**

        Converts A Native Amount Into A House Amount

     */

    function NativeToContractBalance(uint256 amount) public view returns (uint256) {

        return ( ( amount * precision ) / _calculatePrice() );

    }



    /**

        Converts A House Amount Into A Native Amount

     */

    function ReflectionsFromContractBalance(uint256 amount) public view returns (uint256) {

        return ( ( amount * _calculatePrice() ) / precision );

    }



    /** Conversion Ratio For House -> Native */

    function calculatePrice() external view returns (uint256) {

        return _calculatePrice();

    }



    /** Returns Total Profit for User In Token From House */

    function getTotalProfits(address user) external view returns (int256) {

        uint top = balanceOf(user) + userInfo[user].totalWithdrawn;

        return int256(top) - int256(userInfo[user].totalStaked);

    }

    

    /** Conversion Ratio For House -> Native */

    function _calculatePrice() internal view returns (uint256) {

        return ( address(this).balance * precision ) / totalShares;

    }



}
