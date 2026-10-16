// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IMeridianUSD} from "../interface/token/IMeridianUSD.sol";
import {InvalidParameter, P_ERR_BAD_ADDR, P_ERR_BAD_VAL, P_ERR_NOT_FOUND} from "../share/Errors.sol";
import {IERC20Extend} from "../share/tokens/IERC20Extend.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

import {Initializable} from "solady/utils/Initializable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";

contract MeridianUSD is ERC20, UUPSUpgradeable, Ownable, Initializable, IMeridianUSD {
    using SafeTransferLib for address;

    mapping(address => bool) public isWrappedToken;
    address public defaultWrappedToken;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        _initializeOwner(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function name() public pure override returns (string memory) {
        return "Meridian USD";
    }

    function symbol() public pure override returns (string memory) {
        return "merUSD";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function setWrappedToken(address token, bool enabled) external onlyOwner {
        if (token == address(0)) {
            revert InvalidParameter("token", P_ERR_BAD_ADDR);
        }
        if (enabled && IERC20Extend(token).decimals() != decimals()) {
            revert InvalidParameter("token", P_ERR_BAD_VAL);
        }

        bool oldEnabled = isWrappedToken[token];
        isWrappedToken[token] = enabled;
        if (!enabled && defaultWrappedToken == token) {
            address oldDefaultWrappedToken = defaultWrappedToken;
            defaultWrappedToken = address(0);
            emit DefaultWrappedTokenUpdated(oldDefaultWrappedToken, address(0));
        }
        emit WrappedTokenUpdated(token, oldEnabled, enabled);
    }

    function setDefaultWrappedToken(address token) external onlyOwner {
        if (!isWrappedToken[token]) {
            revert InvalidParameter("token", P_ERR_NOT_FOUND);
        }
        address oldDefaultWrappedToken = defaultWrappedToken;
        defaultWrappedToken = token;
        emit DefaultWrappedTokenUpdated(oldDefaultWrappedToken, token);
    }

    function wrap(address token, uint256 amount) external returns (uint256) {
        _verifyDefaultWrappedToken(token);

        token.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Wrapped(msg.sender, token, amount);
        return amount;
    }

    function unwrap(address token, uint256 amount) external returns (uint256) {
        _verifyDefaultWrappedToken(token);

        _burn(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
        emit Unwrapped(msg.sender, token, amount);
        return amount;
    }

    function _verifyDefaultWrappedToken(address token) private view {
        if (!isWrappedToken[token]) {
            revert InvalidParameter("token", P_ERR_NOT_FOUND);
        }
        if (token != defaultWrappedToken) {
            revert InvalidParameter("token", P_ERR_BAD_VAL);
        }
    }
}
