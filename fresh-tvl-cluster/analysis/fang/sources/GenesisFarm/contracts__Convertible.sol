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

// @title FANG Convertible: launch-price conversion of genesis principal into pre-funded FANG
// @notice Only GenesisFarm may convert, during CONVERT_WINDOW after poolEndTime, which the farm gates.
//         Prices and per-token caps are posted by the owner, prices in USD; the conversion is capped to
//         the contract balance and the token's cap, with a per-user cap that doubles every CAP_DOUBLING_PERIOD.
// @dev    Not a fork. OpenZeppelin Ownable, ReentrancyGuard and SafeERC20.
// Built for Robinhood Chain

**************************************************************************************************************************************************/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

interface IGmcdToken is IERC20 {
    function burn(uint256 _amount) external;
}

interface IGenesisFarm {
    function poolEndTime() external view returns (uint256);
    function CONVERT_WINDOW() external view returns (uint256);
}

contract Convertible is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant CAP_DOUBLING_PERIOD = 30 minutes;

    address public immutable gmcd;
    address public immutable genesisFarm;
    uint256 public immutable initialMaxMcdOutPerUser;
    address public treasury;
    uint256 public mcdPriceUsd = 1e18;
    mapping(address => uint256) public tokenPriceUsd;
    mapping(address => uint256) public userMcdOut;
    mapping(address => uint256) public tokenMaxMcdOut;
    mapping(address => uint256) public tokenMcdOut;
    uint256 public totalConverted;

    event Converted(address indexed user, address indexed token, uint256 amount, uint256 gmcdOut);
    event McdPriceUsdUpdated(uint256 price);
    event TokenPriceUsdUpdated(address indexed token, uint256 price);
    event TokenMaxMcdOutUpdated(address indexed token, uint256 maxMcdOut);
    event TreasuryUpdated(address indexed treasury);
    event GmcdWithdrawn(address indexed to, uint256 amount);
    event GmcdBurned(uint256 amount);

    modifier onlyFarm() {
        require(msg.sender == genesisFarm, "Convertible: caller is not the farm");
        _;
    }

    constructor(
        address _gmcd,
        address _genesisFarm,
        address _treasury,
        uint256 _initialMaxMcdOutPerUser,
        address _owner
    ) {
        require(_gmcd != address(0), "Convertible: gmcd is zero");
        require(_genesisFarm != address(0), "Convertible: farm is zero");
        require(_treasury != address(0), "Convertible: treasury is zero");
        require(
            _initialMaxMcdOutPerUser > 0 && _initialMaxMcdOutPerUser <= type(uint128).max,
            "Convertible: initial cap out of range"
        );
        require(_owner != address(0), "Convertible: owner is zero");
        _transferOwnership(_owner);
        gmcd = _gmcd;
        genesisFarm = _genesisFarm;
        treasury = _treasury;
        initialMaxMcdOutPerUser = _initialMaxMcdOutPerUser;
    }

    /// @notice gMCD `_amount` of `_token` converts into, applying decimal scaling.
    function quote(address _token, uint256 _amount) public view returns (uint256 gmcdOut) {
        uint256 mcdPrice = mcdPriceUsd;
        require(mcdPrice > 0, "Convertible: MCD price not set");
        uint256 tokenPrice = tokenPriceUsd[_token];
        require(tokenPrice > 0, "Convertible: token price not set");
        uint256 scale = _scale(IERC20Decimals(_token).decimals());
        require(scale > 0, "Convertible: unsupported decimals");
        gmcdOut = _amount * scale * tokenPrice / mcdPrice;
    }

    function _scale(uint8 _decimals) internal pure returns (uint256) {
        return _decimals <= 18 ? 10 ** (18 - _decimals) : 0;
    }

    /// @notice gMCD this contract still holds to convert.
    function remainingMcdOut() public view returns (uint256) {
        return IGmcdToken(gmcd).balanceOf(address(this));
    }

    /// @notice Per-user cap on gMCD out: the initial cap, doubled every CAP_DOUBLING_PERIOD since the window opened; no cap once closed.
    function maxMcdOutPerUser() public view returns (uint256) {
        (uint256 start, uint256 end) = convertWindow();
        if (block.timestamp <= start) return initialMaxMcdOutPerUser;
        if (block.timestamp >= end) return type(uint256).max;
        return initialMaxMcdOutPerUser * 2 ** ((block.timestamp - start) / CAP_DOUBLING_PERIOD);
    }

    /// @notice gMCD still available to `_user`: the smaller of the per-user remainder and the balance.
    function remainingMcdOutFor(address _user) public view returns (uint256) {
        uint256 cap = maxMcdOutPerUser();
        uint256 userRemaining = cap > userMcdOut[_user] ? cap - userMcdOut[_user] : 0;
        uint256 remaining = remainingMcdOut();
        return userRemaining < remaining ? userRemaining : remaining;
    }

    /// @notice gMCD still payable against `_token`: the smaller of the token's cap remainder and the balance.
    function remainingMcdOutForToken(address _token) public view returns (uint256) {
        uint256 cap = tokenMaxMcdOut[_token];
        uint256 tokenRemaining = cap > tokenMcdOut[_token] ? cap - tokenMcdOut[_token] : 0;
        uint256 remaining = remainingMcdOut();
        return tokenRemaining < remaining ? tokenRemaining : remaining;
    }

    /// @notice Largest `_token` amount `_user` can convert without exceeding a cap; 0 when closed, unpriced or the token's cap is spent.
    function maxTokenIn(address _token, address _user) external view returns (uint256) {
        uint256 tokenPrice = tokenPriceUsd[_token];
        if (!isOpen() || tokenPrice == 0 || mcdPriceUsd == 0) return 0;
        uint256 scale = _scale(IERC20Decimals(_token).decimals());
        if (scale == 0) return 0;
        uint256 userRemaining = remainingMcdOutFor(_user);
        uint256 tokenRemaining = remainingMcdOutForToken(_token);
        uint256 room = userRemaining < tokenRemaining ? userRemaining : tokenRemaining;
        return room * mcdPriceUsd / tokenPrice / scale;
    }

    /// @notice The conversion window read from GenesisFarm: poolEndTime to poolEndTime + CONVERT_WINDOW.
    function convertWindow() public view returns (uint256 start, uint256 end) {
        start = IGenesisFarm(genesisFarm).poolEndTime();
        end = start + IGenesisFarm(genesisFarm).CONVERT_WINDOW();
    }

    /// @notice True while the farm conversion window is open and gMCD remains to convert.
    function isOpen() public view returns (bool) {
        (uint256 start, uint256 end) = convertWindow();
        return start <= block.timestamp && block.timestamp < end && remainingMcdOut() > 0;
    }

    /// @notice Sets the USD price of MCD, 1e18 fixed point.
    function setMcdPriceUsd(uint256 _price) external onlyOwner {
        mcdPriceUsd = _price;
        emit McdPriceUsdUpdated(_price);
    }

    /// @notice Sets the USD price of one deposit token, 1e18 fixed point per whole token.
    function setTokenPriceUsd(address _token, uint256 _price) public onlyOwner {
        require(_token != address(0), "Convertible: token is zero");
        tokenPriceUsd[_token] = _price;
        emit TokenPriceUsdUpdated(_token, _price);
    }

    /// @notice Sets the USD price of several deposit tokens in one call.
    function setTokenPricesUsd(address[] calldata _tokens, uint256[] calldata _prices) external onlyOwner {
        require(_tokens.length == _prices.length, "Convertible: length mismatch");
        for (uint256 i; i < _tokens.length; ++i) {
            setTokenPriceUsd(_tokens[i], _prices[i]);
        }
    }

    /// @notice Sets the gMCD cap paid out against each deposit token; type(uint256).max means no cap.
    function setTokenMaxMcdOuts(address[] calldata _tokens, uint256[] calldata _maxMcdOuts) external onlyOwner {
        require(_tokens.length == _maxMcdOuts.length, "Convertible: length mismatch");
        for (uint256 i; i < _tokens.length; ++i) {
            require(_tokens[i] != address(0), "Convertible: token is zero");
            tokenMaxMcdOut[_tokens[i]] = _maxMcdOuts[i];
            emit TokenMaxMcdOutUpdated(_tokens[i], _maxMcdOuts[i]);
        }
    }

    /// @notice Sets the address receiving converted principal.
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Convertible: treasury is zero");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice Sends gMCD out of this contract, lowering what is left to convert.
    function withdrawGmcd(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Convertible: to is zero");
        emit GmcdWithdrawn(_to, _amount);
        IERC20(gmcd).safeTransfer(_to, _amount);
    }

    /// @notice Converts all of `_amount` of `_token` held by the farm into gMCD for `_user`, or reverts.
    function convert(
        address _token,
        uint256 _amount,
        address _user
    ) external onlyFarm nonReentrant returns (uint256 gmcdOut) {
        gmcdOut = quote(_token, _amount);
        require(gmcdOut > 0, "Convertible: nothing converted");
        require(gmcdOut <= remainingMcdOutFor(_user), "Convertible: cap reached");
        require(gmcdOut <= remainingMcdOutForToken(_token), "Convertible: token cap reached");

        userMcdOut[_user] += gmcdOut;
        tokenMcdOut[_token] += gmcdOut;
        totalConverted += gmcdOut;
        emit Converted(_user, _token, _amount, gmcdOut);

        IERC20(_token).safeTransferFrom(msg.sender, treasury, _amount);
        IERC20(gmcd).safeTransfer(_user, gmcdOut);
    }

    /// @notice Burns the gMCD still held here once the conversion window has closed.
    function burnConverted() external nonReentrant onlyOwner {
        (, uint256 end) = convertWindow();
        require(block.timestamp >= end, "Convertible: window still open");
        uint256 amount = remainingMcdOut();
        require(amount > 0, "Convertible: nothing to burn");
        emit GmcdBurned(amount);
        IGmcdToken(gmcd).burn(amount);
    }
}
