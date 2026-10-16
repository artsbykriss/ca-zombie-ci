// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20Extend} from "./IERC20Extend.sol";

library ERC20Helpers {
    uint8 constant MAX_PRECISION = 9; // 1e9

    /// @dev Scales a non-9 decimal ERC20 amount up or down to 9 decimals.
    function normalize(IERC20Extend token, uint256 amount) internal view returns (uint256) {
        uint8 tokenDecimals = token.decimals();
        if (tokenDecimals > MAX_PRECISION) {
            return amount / (10 ** (tokenDecimals - MAX_PRECISION));
        } else if (tokenDecimals < MAX_PRECISION) {
            return amount * (10 ** (MAX_PRECISION - tokenDecimals));
        } else {
            return amount;
        }
    }

    /// @dev Converts normalized 9-decimal amounts back down to original decimals.
    function denormalize(IERC20Extend token, uint256 amount) internal view returns (uint256) {
        uint8 tokenDecimals = token.decimals();
        if (tokenDecimals == MAX_PRECISION) {
            return amount;
        } else if (tokenDecimals < MAX_PRECISION) {
            return amount / 10 ** (MAX_PRECISION - tokenDecimals);
        } else {
            return amount * 10 ** (tokenDecimals - MAX_PRECISION);
        }
    }

    /// @dev Returns true if `token` is ERC20 compatible, false otherwise.
    function isERC20(address token) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) {
            return false;
        }
        try IERC20Extend(token).totalSupply() returns (uint256) {}
        catch {
            return false;
        }
        try IERC20Extend(token).balanceOf(address(this)) returns (uint256) {}
        catch {
            return false;
        }
        try IERC20Extend(token).decimals() returns (uint8) {}
        catch {
            return false;
        }
        return true;
    }
}
