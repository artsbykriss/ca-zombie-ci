// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**************************************************************************************************************************************************

 /$$$$$$$$                                 /$$$$$$$$ /$$                                                  
| $$_____/                                | $$_____/|__/                                                  
| $$    /$$$$$$  /$$$$$$$   /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
| $$$$$|____  $$| $$__  $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
| $$__/ /$$$$$$$| $$  \ $$| $$  \ $$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
| $$   /$$__  $$| $$  | $$| $$  | $$      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  |  $$$$$$$| $$  | $$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/   \_______/|__/  |__/ \____  $$      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
                           /$$  \ $$                                                                      
                          |  $$$$$$/                                                                      
                           \______/                                                                       
                                                                                                                                                    
#### Website: https://fang.finance/
#### Author: kell (adaptions)

// @title Genesis GFANG: Modified from escrowed-token model tokens (e.g. xGRAIL, xKDK)
// @notice Non-transferable escrowed token convertible 1:1 from GFANG. xGFANG is fully redeemable to GFANG
//         within 3 days, or sooner with a forfeit (user's choice). Forfeited GFANG is burned.
// @dev    Modifications:
// Modern Solidity
// The usage plugin system (allocate / deallocate) is removed. xGFANG utility is managed separately.
// xGFANG is available as reward token before TGE. After TGE, xGFANG can only be 1:1 converted from GFANG.
// Built for Robinhood Chain

**************************************************************************************************************************************************/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IGfangToken is IERC20 {
    function burn(uint256 amount) external;
}

contract xGFANG is Ownable, ReentrancyGuard, ERC20("Genesis GFANG", "xGFANG") {
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IGfangToken;

    struct XgfangBalance {
        uint256 redeemingAmount; // Total amount of xGFANG currently being redeemed
    }

    struct RedeemInfo {
        uint256 gfangAmount; // GFANG amount to receive when vesting has ended
        uint256 xgfangAmount; // xGFANG amount to redeem
        uint256 endTime;
    }

    IGfangToken public gfangToken; // GFANG token to convert to/from

    EnumerableSet.AddressSet private _whitelisters; // addresses allowed to whitelist/unwhitelist
    EnumerableSet.AddressSet private _transferWhitelist; // addresses allowed to send/receive xGFANG

    uint256 public constant MAX_FIXED_RATIO = 100; // 100%

    // Redeeming min/max settings
    uint256 public minRedeemRatio = 10; // 1:0.1
    uint256 public maxRedeemRatio = 100; // 1:1
    uint256 public minRedeemDuration = 0;
    uint256 public maxRedeemDuration = 3 days;

    mapping(address => XgfangBalance) public xgfangBalances; // User's xGFANG balances
    mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances

    constructor(address _owner) {
        require(_owner != address(0), "XGFANG: owner is zero");
        _transferOwnership(_owner);
        _transferWhitelist.add(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Convert(address indexed from, address to, uint256 amount);
    event SetGfangAddress(address gfangAddress);
    event UpdateRedeemSettings(
        uint256 minRedeemRatio, uint256 maxRedeemRatio, uint256 minRedeemDuration, uint256 maxRedeemDuration
    );
    event UpdateTransferWhitelist(address account, bool add);
    event UpdateWhitelister(address account, bool add);
    event Redeem(address indexed userAddress, uint256 xgfangAmount, uint256 gfangAmount, uint256 duration);
    event FinalizeRedeem(address indexed userAddress, uint256 xgfangAmount, uint256 gfangAmount);
    event CancelRedeem(address indexed userAddress, uint256 xgfangAmount);

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Check if gfang has been set
    modifier gfangActive() {
        require(address(gfangToken) != address(0), "XGFANG: GFANG not set");
        _;
    }

    /// @dev Check if caller is allowed to update the transfer whitelist
    modifier onlyWhiteLister() {
        require(isWhitelister(msg.sender), "XGFANG: onlyWhiteLister: not allowed");
        _;
    }

    /// @dev Check if a redeem entry exists
    modifier validateRedeem(address userAddress, uint256 redeemIndex) {
        require(redeemIndex < userRedeems[userAddress].length, "XGFANG: validateRedeem: redeem entry does not exist");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns user's xGFANG balances
    function getXgfangBalance(address userAddress) external view returns (uint256 redeemingAmount) {
        XgfangBalance storage balance = xgfangBalances[userAddress];
        return balance.redeemingAmount;
    }

    /// @dev returns redeemable GFANG for "amount" of xGFANG vested for "duration" seconds
    function getGfangByVestingDuration(uint256 amount, uint256 duration) public view returns (uint256) {
        if (duration < minRedeemDuration || address(gfangToken) == address(0)) {
            return 0;
        }

        // capped to maxRedeemDuration
        if (duration > maxRedeemDuration) {
            return amount.mul(maxRedeemRatio).div(100);
        }

        uint256 ratio = minRedeemRatio.add(
            (duration.sub(minRedeemDuration))
                .mul(maxRedeemRatio.sub(minRedeemRatio))
                .div(maxRedeemDuration.sub(minRedeemDuration))
        );

        return amount.mul(ratio).div(100);
    }

    /// @dev returns quantity of "userAddress" pending redeems
    function getUserRedeemsLength(address userAddress) external view returns (uint256) {
        return userRedeems[userAddress].length;
    }

    /// @dev returns "userAddress" info for a pending redeem identified by "redeemIndex"
    function getUserRedeem(
        address userAddress,
        uint256 redeemIndex
    )
        external
        view
        validateRedeem(userAddress, redeemIndex)
        returns (uint256 gfangAmount, uint256 xgfangAmount, uint256 endTime)
    {
        RedeemInfo storage _redeem = userRedeems[userAddress][redeemIndex];
        return (_redeem.gfangAmount, _redeem.xgfangAmount, _redeem.endTime);
    }

    /// @dev returns length of transferWhitelist array
    function transferWhitelistLength() external view returns (uint256) {
        return _transferWhitelist.length();
    }

    /// @dev returns transferWhitelist array item's address for "index"
    function transferWhitelist(uint256 index) external view returns (address) {
        return _transferWhitelist.at(index);
    }

    /// @dev returns if "account" is allowed to send/receive xGFANG
    function isTransferWhitelisted(address account) external view returns (bool) {
        return _transferWhitelist.contains(account);
    }

    /// @dev returns if "account" is allowed to update transfer whitelist
    function isWhitelister(address account) public view returns (bool) {
        return _whitelisters.contains(account) || account == owner();
    }

    /*//////////////////////////////////////////////////////////////
                          OWNABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Set the GFANG token address, can only be set once
    function setGfangAddress(address _gfang) external onlyOwner {
        require(address(gfangToken) == address(0), "XGFANG: GFANG already set");
        gfangToken = IGfangToken(_gfang);
        require(gfangToken.balanceOf(address(this)) == totalSupply(), "XGFANG: xGFANG not fully backed by GFANG");
        emit SetGfangAddress(_gfang);
    }

    /// @dev Allows owner to mint freely xGFANG (before GFANG is set)
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(address(gfangToken) == address(0), "XGFANG: GFANG already set, cannot mint anymore");
        _mint(recipient, amount);
    }

    /// @dev Updates all redeem ratios and durations
    function updateRedeemSettings(
        uint256 minRedeemRatio_,
        uint256 maxRedeemRatio_,
        uint256 minRedeemDuration_,
        uint256 maxRedeemDuration_
    ) external gfangActive onlyOwner {
        require(minRedeemRatio_ <= maxRedeemRatio_, "XGFANG: updateRedeemSettings: wrong ratio values");
        require(minRedeemDuration_ < maxRedeemDuration_, "XGFANG: updateRedeemSettings: wrong duration values");
        // should never exceed 100%
        require(maxRedeemRatio_ <= MAX_FIXED_RATIO, "XGFANG: updateRedeemSettings: wrong ratio values");

        minRedeemRatio = minRedeemRatio_;
        maxRedeemRatio = maxRedeemRatio_;
        minRedeemDuration = minRedeemDuration_;
        maxRedeemDuration = maxRedeemDuration_;

        emit UpdateRedeemSettings(minRedeemRatio_, maxRedeemRatio_, minRedeemDuration_, maxRedeemDuration_);
    }

    /// @dev Adds or removes addresses capable of updating the transfer whitelist
    function updateWhitelister(address account, bool add) external onlyOwner {
        require(account != owner(), "XGFANG: updateWhitelisters: Cannot add or remove owner from whitelisters");

        if (add) _whitelisters.add(account);
        else _whitelisters.remove(account);

        emit UpdateWhitelister(account, add);
    }

    /// @dev Adds or removes addresses from the transferWhitelist
    function updateTransferWhitelist(address account, bool add) external onlyWhiteLister {
        require(account != address(this), "XGFANG: updateTransferWhitelist: Cannot remove xGFANG from whitelist");

        if (add) _transferWhitelist.add(account);
        else _transferWhitelist.remove(account);

        emit UpdateTransferWhitelist(account, add);
    }

    /*//////////////////////////////////////////////////////////////
                      EXTERNAL PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Convert caller's "amount" of GFANG to xGFANG
    function convert(uint256 amount) external gfangActive nonReentrant {
        _convert(amount, msg.sender);
    }

    /// @dev Convert caller's "amount" of GFANG to xGFANG to "to" address
    function convertTo(uint256 amount, address to) external gfangActive nonReentrant {
        require(address(msg.sender).isContract(), "XGFANG: convertTo: not allowed");
        _convert(amount, to);
    }

    /// @dev Initiates redeem process (xGFANG to GFANG)
    function redeem(uint256 xgfangAmount, uint256 duration) external gfangActive nonReentrant {
        require(xgfangAmount > 0, "XGFANG: redeem: xgfangAmount cannot be null");
        require(duration >= minRedeemDuration, "XGFANG: redeem: duration too low");

        _transfer(msg.sender, address(this), xgfangAmount);
        XgfangBalance storage balance = xgfangBalances[msg.sender];

        // get corresponding GFANG amount
        uint256 gfangAmount = getGfangByVestingDuration(xgfangAmount, duration);
        emit Redeem(msg.sender, xgfangAmount, gfangAmount, duration);

        // if redeeming is not immediate, go through vesting process
        if (duration > 0) {
            // add to SBT total
            balance.redeemingAmount = balance.redeemingAmount.add(xgfangAmount);

            // add redeeming entry
            userRedeems[msg.sender].push(RedeemInfo(gfangAmount, xgfangAmount, _currentBlockTimestamp().add(duration)));
        } else {
            // immediately redeem for GFANG
            _finalizeRedeem(msg.sender, xgfangAmount, gfangAmount);
        }
    }

    /// @dev Finalizes redeem process when vesting duration has been reached
    /// @notice Can only be called by the redeem entry owner
    function finalizeRedeem(uint256 redeemIndex)
        external
        gfangActive
        nonReentrant
        validateRedeem(msg.sender, redeemIndex)
    {
        XgfangBalance storage balance = xgfangBalances[msg.sender];
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];
        require(_currentBlockTimestamp() >= _redeem.endTime, "XGFANG: finalizeRedeem: vesting duration has not ended yet");

        // remove from SBT total
        balance.redeemingAmount = balance.redeemingAmount.sub(_redeem.xgfangAmount);
        _finalizeRedeem(msg.sender, _redeem.xgfangAmount, _redeem.gfangAmount);

        // remove redeem entry
        _deleteRedeemEntry(redeemIndex);
    }

    /// @dev Cancels an ongoing redeem entry
    function cancelRedeem(uint256 redeemIndex) external gfangActive nonReentrant validateRedeem(msg.sender, redeemIndex) {
        XgfangBalance storage balance = xgfangBalances[msg.sender];
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

        // make redeeming xGFANG available again
        balance.redeemingAmount = balance.redeemingAmount.sub(_redeem.xgfangAmount);
        _transfer(address(this), msg.sender, _redeem.xgfangAmount);

        emit CancelRedeem(msg.sender, _redeem.xgfangAmount);

        // remove redeem entry
        _deleteRedeemEntry(redeemIndex);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Convert caller's "amount" of GFANG into xGFANG to "to"
    function _convert(uint256 amount, address to) internal {
        require(amount != 0, "XGFANG: convert: amount cannot be null");

        // mint new xGFANG
        _mint(to, amount);

        emit Convert(msg.sender, to, amount);
        gfangToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev Finalizes the redeeming process for "userAddress" by transferring him "gfangAmount" and removing "xgfangAmount" from supply
    /// @notice Any vesting check should be ran before calling this
    /// @notice GFANG excess is automatically burnt
    function _finalizeRedeem(address userAddress, uint256 xgfangAmount, uint256 gfangAmount) internal {
        uint256 gfangExcess = xgfangAmount.sub(gfangAmount);

        // sends due GFANG tokens
        gfangToken.safeTransfer(userAddress, gfangAmount);

        // burns GFANG excess if any
        gfangToken.burn(gfangExcess);
        _burn(address(this), xgfangAmount);

        emit FinalizeRedeem(userAddress, xgfangAmount, gfangAmount);
    }

    function _deleteRedeemEntry(uint256 index) internal {
        userRedeems[msg.sender][index] = userRedeems[msg.sender][userRedeems[msg.sender].length - 1];
        userRedeems[msg.sender].pop();
    }

    /// @dev Hook override to forbid transfers except from whitelisted addresses and minting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal view override {
        require(
            from == address(0) || _transferWhitelist.contains(from) || _transferWhitelist.contains(to),
            "XGFANG: transfer: not allowed"
        );
    }

    /// @dev dev Utility function to get the current block timestamp
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    // ************************************************************************************************
    // END OF FORK
    // ************************************************************************************************

    // ************************************************************************************************
    // MERIDIAN MODIFICATIONS
    //
    // New code, additive only. Upstream has no burn: its escrowed token leaves supply through a
    // redeem alone.
    // ************************************************************************************************

    event Burn(address indexed userAddress, uint256 xgfangAmount, uint256 gfangBurned);

    /// @notice Burns `_amount` of the caller's xGFANG, and the matching backing GFANG once GFANG is set
    function burn(uint256 _amount) external nonReentrant {
        require(_amount > 0, "XGFANG: amount cannot be null");

        uint256 gfangBurned = address(gfangToken) != address(0) ? _amount : 0;
        _burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount, gfangBurned);

        if (gfangBurned > 0) gfangToken.burn(gfangBurned);
    }
}
