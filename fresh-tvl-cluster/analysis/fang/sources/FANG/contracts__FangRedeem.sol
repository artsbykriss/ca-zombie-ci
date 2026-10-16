// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FangRedeem
 * @notice Redeem FANG (18d) for USDC (6d) at a fixed 1 rate:
 *         1e18 FANG -> 1 * 1e6 USDC = 1_000_000 USDC units.
 */
contract FangRedeem is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable FANG;
    IERC20 public immutable USDC;

    // Decimal bridge: 18 (FANG) - 6 (USDC) = 12
    uint256 public constant DECIMALS_DIVISOR = 1e12;

    // Fixed rate: 1.00 USDC per 1 FANG (no adjustability)
    uint256 public constant RATE_NUMERATOR = 100;
    uint256 public constant RATE_DENOMINATOR = 100;

    event Redeem(address indexed user, uint256 fangAmount, uint256 usdcAmount);
    event Supply(uint256 usdcAmount);
    event Retrieve(uint256 usdcAmount);

    constructor(IERC20 _FANG, IERC20 _USDC) {
        FANG = _FANG;
        USDC = _USDC;
    }

    /**
     * @notice Redeem FANG for USDC at 1.00 rate, accounting for decimals.
     * @param fangAmount Amount of FANG (18 decimals).
     * @return usdcAmount Amount of USDC sent (6 decimals).
     *
     * Rounding: floors toward zero (standard integer math).
     * To avoid tiny dust, the amount must be a multiple of 1e12.
     */
    function redeemFang(uint256 fangAmount)
        external
        nonReentrant
        returns (uint256 usdcAmount)
    {
        require(fangAmount > 0, "Zero amount");
        // Enforce clean 18->6 conversion to avoid dust carryover
        require(fangAmount % DECIMALS_DIVISOR == 0, "Amount must be multiple of 1e12");

        // Convert 18d -> 6d first, then apply 1.00 rate with integer math
        uint256 usdcBase = fangAmount / DECIMALS_DIVISOR;          // now in USDC 6d units at 1:1
        usdcAmount = (usdcBase * RATE_NUMERATOR) / RATE_DENOMINATOR; // apply 1.00 rate

        require(USDC.balanceOf(address(this)) >= usdcAmount, "Insufficient USDC");

        // Pull FANG from user to owner (keeps your original flow)
        FANG.safeTransferFrom(msg.sender, owner(), fangAmount);

        // Send USDC to user
        USDC.safeTransfer(msg.sender, usdcAmount);

        emit Redeem(msg.sender, fangAmount, usdcAmount);
    }

    /**
     * @notice Owner supplies USDC liquidity for redemptions.
     * @param usdcAmount Amount of USDC (6 decimals).
     */
    function supplyUSDC(uint256 usdcAmount) external onlyOwner {
        require(usdcAmount > 0, "Zero amount");
        USDC.safeTransferFrom(msg.sender, address(this), usdcAmount);
        emit Supply(usdcAmount);
    }

    /**
     * @notice Owner retrieves excess USDC.
     * @param usdcAmount Amount of USDC (6 decimals).
     */
    function retrieveUSDC(uint256 usdcAmount) external onlyOwner {
        require(usdcAmount > 0, "Zero amount");
        require(USDC.balanceOf(address(this)) >= usdcAmount, "Insufficient USDC");
        USDC.safeTransfer(msg.sender, usdcAmount);
        emit Retrieve(usdcAmount);
    }

    /**
     * @notice Pure quote helper (no state read) for frontends/integrations.
     * @param fangAmount Amount of FANG (18 decimals).
     * @return usdcAmount Quoted USDC out (6 decimals), floored.
     */
    function quoteRedeem(uint256 fangAmount) external pure returns (uint256 usdcAmount) {
        if (fangAmount == 0) return 0;
        if (fangAmount < DECIMALS_DIVISOR) return 0; // prevents underflow on division
        uint256 usdcBase = fangAmount / DECIMALS_DIVISOR;
        return (usdcBase * RATE_NUMERATOR) / RATE_DENOMINATOR;
    }
}
