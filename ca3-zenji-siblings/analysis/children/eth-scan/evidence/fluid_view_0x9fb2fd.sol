
// ===== @openzeppelin/contracts/token/ERC20/IERC20.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ===== contracts/infiniteProxy/IProxy.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);
}

// ===== contracts/vault/common/bigMathMinified.sol =====
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title library that represents a number in BigNumber(coefficient and exponent) format to store in smaller bits.
/// @notice the number is divided into two parts: a coefficient and an exponent. This comes at a cost of losing some precision
/// at the end of the number because the exponent simply fills it with zeroes. This precision is oftentimes negligible and can
/// result in significant gas cost reduction due to storage space reduction.
/// Also note, a valid big number is as follows: if the exponent is > 0, then coefficient last bits should be occupied to have max precision.
/// @dev roundUp is more like a increase 1, which happens everytime for the same number.
/// roundDown simply sets trailing digits after coefficientSize to zero (floor), only once for the same number.
library BigMathMinified {
    /// @dev constants to use for `roundUp` input param to increase readability
    bool internal constant ROUND_DOWN = false;
    bool internal constant ROUND_UP = true;

    /// @dev converts `normal` number to BigNumber with `exponent` and `coefficient` (or precision).
    /// e.g.:
    /// 5035703444687813576399599 (normal) = (coefficient[32bits], exponent[8bits])[40bits]
    /// 5035703444687813576399599 (decimal) => 10000101010010110100000011111011110010100110100000000011100101001101001101011101111 (binary)
    ///                                     => 10000101010010110100000011111011000000000000000000000000000000000000000000000000000
    ///                                                                        ^-------------------- 51(exponent) -------------- ^
    /// coefficient = 1000,0101,0100,1011,0100,0000,1111,1011               (2236301563)
    /// exponent =                                            0011,0011     (51)
    /// bigNumber =   1000,0101,0100,1011,0100,0000,1111,1011,0011,0011     (572493200179)
    ///
    /// @param normal number which needs to be converted into Big Number
    /// @param coefficientSize at max how many bits of precision there should be (64 = uint64 (64 bits precision))
    /// @param exponentSize at max how many bits of exponent there should be (8 = uint8 (8 bits exponent))
    /// @param roundUp signals if result should be rounded down or up
    /// @return bigNumber converted bigNumber (coefficient << exponent)
    function toBigNumber(
        uint256 normal,
        uint256 coefficientSize,
        uint256 exponentSize,
        bool roundUp
    ) internal pure returns (uint256 bigNumber) {
        assembly {
            let lastBit_
            let number_ := normal
            if gt(number_, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                number_ := shr(0x80, number_)
                lastBit_ := 0x80
            }
            if gt(number_, 0xFFFFFFFFFFFFFFFF) {
                number_ := shr(0x40, number_)
                lastBit_ := add(lastBit_, 0x40)
            }
            if gt(number_, 0xFFFFFFFF) {
                number_ := shr(0x20, number_)
                lastBit_ := add(lastBit_, 0x20)
            }
            if gt(number_, 0xFFFF) {
                number_ := shr(0x10, number_)
                lastBit_ := add(lastBit_, 0x10)
            }
            if gt(number_, 0xFF) {
                number_ := shr(0x8, number_)
                lastBit_ := add(lastBit_, 0x8)
            }
            if gt(number_, 0xF) {
                number_ := shr(0x4, number_)
                lastBit_ := add(lastBit_, 0x4)
            }
            if gt(number_, 0x3) {
                number_ := shr(0x2, number_)
                lastBit_ := add(lastBit_, 0x2)
            }
            if gt(number_, 0x1) {
                lastBit_ := add(lastBit_, 1)
            }
            if gt(number_, 0) {
                lastBit_ := add(lastBit_, 1)
            }
            if lt(lastBit_, coefficientSize) {
                // for throw exception
                lastBit_ := coefficientSize
            }
            let exponent := sub(lastBit_, coefficientSize)
            let coefficient := shr(exponent, normal)
            if and(roundUp, gt(exponent, 0)) {
                // rounding up is only needed if exponent is > 0, as otherwise the coefficient fully holds the original number
                coefficient := add(coefficient, 1)
                if eq(shl(coefficientSize, 1), coefficient) {
                    // case were coefficient was e.g. 111, with adding 1 it became 1000 (in binary) and coefficientSize 3 bits
                    // final coefficient would exceed it's size. -> reduce coefficent to 100 and increase exponent by 1.
                    coefficient := shl(sub(coefficientSize, 1), 1)
                    exponent := add(exponent, 1)
                }
            }
            if iszero(lt(exponent, shl(exponentSize, 1))) {
                // if exponent is >= exponentSize, the normal number is too big to fit within
                // BigNumber with too small sizes for coefficient and exponent
                revert(0, 0)
            }
            bigNumber := shl(exponentSize, coefficient)
            bigNumber := add(bigNumber, exponent)
        }
    }

    /// @dev get `normal` number from `bigNumber`, `exponentSize` and `exponentMask`
    function fromBigNumber(
        uint256 bigNumber,
        uint256 exponentSize,
        uint256 exponentMask
    ) internal pure returns (uint256 normal) {
        assembly {
            let coefficient := shr(exponentSize, bigNumber)
            let exponent := and(bigNumber, exponentMask)
            normal := shl(exponent, coefficient)
        }
    }

    /// @dev gets the most significant bit `lastBit` of a `normal` number (length of given number of binary format).
    /// e.g.
    /// 5035703444687813576399599 = 10000101010010110100000011111011110010100110100000000011100101001101001101011101111
    /// lastBit =                   ^---------------------------------   83   ----------------------------------------^
    function mostSignificantBit(uint256 normal) internal pure returns (uint lastBit) {
        assembly {
            let number_ := normal
            if gt(normal, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                number_ := shr(0x80, number_)
                lastBit := 0x80
            }
            if gt(number_, 0xFFFFFFFFFFFFFFFF) {
                number_ := shr(0x40, number_)
                lastBit := add(lastBit, 0x40)
            }
            if gt(number_, 0xFFFFFFFF) {
                number_ := shr(0x20, number_)
                lastBit := add(lastBit, 0x20)
            }
            if gt(number_, 0xFFFF) {
                number_ := shr(0x10, number_)
                lastBit := add(lastBit, 0x10)
            }
            if gt(number_, 0xFF) {
                number_ := shr(0x8, number_)
                lastBit := add(lastBit, 0x8)
            }
            if gt(number_, 0xF) {
                number_ := shr(0x4, number_)
                lastBit := add(lastBit, 0x4)
            }
            if gt(number_, 0x3) {
                number_ := shr(0x2, number_)
                lastBit := add(lastBit, 0x2)
            }
            if gt(number_, 0x1) {
                lastBit := add(lastBit, 1)
            }
            if gt(number_, 0) {
                lastBit := add(lastBit, 1)
            }
        }
    }
}

// ===== contracts/vault/common/dexHelpers.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./variablesBufferHelper.sol";
import {LiquidityCalcs} from "./liquidityCalcs.sol";
import {LiquiditySlotsLink} from "./liquiditySlotsLink.sol";
import {IFluidDexT1} from "./interfaces.sol";

contract DexHelpers is VariablesBufferHelper {
    /// @dev Retrieves collateral amount from liquidity layer for a given token
    /// @param supplyTokenSlot_ The storage slot for the supply token data
    /// @param exchangePriceSlot_ The storage slot for the exchange price of the token
    /// @return tokenSupply_ The calculated liquidity collateral amount
    function _getLiquidityCollateralAndDebt(
        bytes32 supplyTokenSlot_,
        bytes32 borrowTokenSlot_,
        bytes32 exchangePriceSlot_
    ) internal view returns (uint tokenSupply_, uint tokenDebt_) {
        uint tokenSupplyData_ = LIQUIDITY.readFromStorage(supplyTokenSlot_);
        uint tokenBorrowData_ = LIQUIDITY.readFromStorage(borrowTokenSlot_);

        tokenSupply_ =
            (tokenSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_AMOUNT) &
            LiquidityCalcs.X64;
        tokenSupply_ =
            (tokenSupply_ >> LiquidityCalcs.DEFAULT_EXPONENT_SIZE) <<
            (tokenSupply_ & LiquidityCalcs.DEFAULT_EXPONENT_MASK);

        tokenDebt_ =
            (tokenBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_AMOUNT) &
            LiquidityCalcs.X64;
        tokenDebt_ =
            (tokenDebt_ >> LiquidityCalcs.DEFAULT_EXPONENT_SIZE) <<
            (tokenDebt_ & LiquidityCalcs.DEFAULT_EXPONENT_MASK);

        (uint256 supplyExchangePrice_, uint256 borrowExchangePrice_) = LiquidityCalcs.calcExchangePrices(
            LIQUIDITY.readFromStorage(exchangePriceSlot_)
        );

        if (tokenSupplyData_ & 1 == 1) {
            // supply with interest is on
            unchecked {
                tokenSupply_ =
                    (tokenSupply_ * supplyExchangePrice_) /
                    LiquidityCalcs.EXCHANGE_PRICES_PRECISION;
            }
        }

        if (tokenBorrowData_ & 1 == 1) {
            // debt with interest is on
            unchecked {
                tokenDebt_ =
                    (tokenDebt_ * borrowExchangePrice_) /
                    LiquidityCalcs.EXCHANGE_PRICES_PRECISION;
            }
        }
    }

    function _getDexCollateralAndDebt()
        internal
        view
        returns (
            uint256 token0Collateral_,
            uint256 token0Debt_,
            uint256 token1Collateral_,
            uint256 token1Debt_
        )
    {
        IFluidDexT1.ConstantViews memory constantsView_ = FLUID_DEX
            .constantsView();

        // token1 is ETH & token0 is wstETH

        (token0Collateral_, token0Debt_) = _getLiquidityCollateralAndDebt(
            constantsView_.supplyToken0Slot,
            constantsView_.borrowToken0Slot,
            constantsView_.exchangePriceToken0Slot
        );

        (token1Collateral_, token1Debt_) = _getLiquidityCollateralAndDebt(
            constantsView_.supplyToken1Slot,
            constantsView_.borrowToken1Slot,
            constantsView_.exchangePriceToken1Slot
        );
    }

    function _getDexLiteNftCollateralAndDebt(
        uint256 supplyShares_,
        uint256 borrowShares_
    )
        internal
        view
        returns (
            uint256 token0Collateral_,
            uint256 token0Debt_,
            uint256 token1Collateral_,
            uint256 token1Debt_
        )
    {
        uint256 dexTotalSupplyShares_ = FLUID_DEX.readFromStorage(bytes32(uint(2))) &
            X128;

        uint256 dexTotalBorrowShares_ = FLUID_DEX.readFromStorage(bytes32(uint(4))) &
            X128;

        (
            token0Collateral_,
            token0Debt_,
            token1Collateral_,
            token1Debt_
        ) = _getDexCollateralAndDebt();

        token0Collateral_ =
            (token0Collateral_ * supplyShares_) /
            dexTotalSupplyShares_;
        token1Collateral_ =
            (token1Collateral_ * supplyShares_) /
            dexTotalSupplyShares_;

        token0Debt_ = (token0Debt_ * borrowShares_) / dexTotalBorrowShares_;
        token1Debt_ = (token1Debt_ * borrowShares_) / dexTotalBorrowShares_;
    }
}

// ===== contracts/vault/common/helpers.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces.sol";
import "../../infiniteProxy/IProxy.sol";
import {DexHelpers} from "./dexHelpers.sol";
import {TickMath} from "./tickmath.sol";

contract Helpers is DexHelpers {    
    struct ConversionRates {
        uint256 eEthPerWeETH;
        uint256 stETHPerWstETH;
    }

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsAaveV3 {
        uint256 wstETH; // supply
        uint256 weETH; // supply
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH supply converted to stETH
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsFluidWeETH {
        uint256 weETH; // supply
        uint256 wstETH; // borrow
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH borrow converted to stETH
    }

    struct ProtocolAssetsInDexWstETH {
        uint256 wstETHSupply;
        uint256 ethSupply;
        uint256 wstETHBorrow;
        uint256 stETHBorrow;
        uint256 ethBorrow;
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 eETH;
        uint256 weETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsAaveV3 aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH spark;
        ProtocolAssetsInWstETH fluidNew;
        ProtocolAssetsInWstETH aaveV3Lido;
        ProtocolAssetsInDexWstETH fluidDex;
        ProtocolAssetsFluidWeETH fluidWeETH;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Aave V3 in terms of `WETH` and `(STETH + EETH)`.
    function getRatioAaveV3(
        uint256 eEthPerWeETH_,
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 weEthAmount_,
            uint256 eEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(A_WSTETH_ADDRESS_AAVEV3).balanceOf(
            address(vaultDSA)
        );

        weEthAmount_ = IERC20(A_WEETH_ADDRESS_AAVEV3).balanceOf(
            address(vaultDSA)
        );

        if (eEthPerWeETH_ > 0) {
            eEthAmount_ = (weEthAmount_ * eEthPerWeETH_) / 1e18;
        } else {
            eEthAmount_ = WEETH_CONTRACT.getEETHByWeETH(weEthAmount_);
        }

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }

        ethAmount_ = IERC20(D_WETH_ADDRESS_AAVEV3).balanceOf(address(vaultDSA));

        ratio_ = (stEthAmount_ + eEthAmount_) == 0
            ? 0
            : (ethAmount_ * 1e6) / (stEthAmount_ + eEthAmount_);
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Compound V3 in terms of `ETH` and `STETH`.
    function getRatioCompoundV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        ethAmount_ = COMP_ETH_MARKET_CONTRACT.borrowBalanceOf(
            address(vaultDSA)
        );

        ICompoundMarket.UserCollateral
            memory collateralData_ = COMP_ETH_MARKET_CONTRACT.userCollateral(
                address(vaultDSA),
                WSTETH_ADDRESS
            );

        wstEthAmount_ = uint256(collateralData_.balance);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Spark in terms of `WETH` and `STETH`.
    function getRatioSpark(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(SP_WSTETH_ADDRESS_SPARK).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_SPARK).balanceOf(address(vaultDSA));

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @notice Calculating the slot ID for Liquidity contract for single mapping
    function calculateStorageSlotUintMapping(
        uint256 slot_,
        uint256 key_
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(key_, slot_));
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Fluid in terms of `ETH` and `STETH`.
    function getRatioFluidNew(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        uint256 positionData_ = FLUID_VAULT_NEW.readFromStorage(
            calculateStorageSlotUintMapping(3, FLUID_NFT_ID_NEW)
        );

        bool isSupplyPosition_ = (positionData_ & 1) == 1;

        wstEthAmount_ = (positionData_ >> 45) & X64;
        wstEthAmount_ = (wstEthAmount_ >> 8) << (wstEthAmount_ & X8);

        if (!isSupplyPosition_) {
            uint256 dustBorrow_ = (positionData_ >> 109) & X64;
            // Converting big number into normal number
            dustBorrow_ = (dustBorrow_ >> 8) << (dustBorrow_ & X8);

            int tick_ = (positionData_ & 2) == 2
                ? int((positionData_ >> 2) & X19)
                : -int((positionData_ >> 2) & X19);

            ethAmount_ = (TickMath.getRatioAtTick(tick_) * wstEthAmount_) >> 96;

            ethAmount_ = ethAmount_ - dustBorrow_;
        }

        (
            ,
            ,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        ) = FLUID_VAULT_NEW.updateExchangePrices(
                FLUID_VAULT_NEW.readFromStorage(bytes32(uint256(1)))
            );

        wstEthAmount_ = (wstEthAmount_ * vaultSupplyExPrice_) / 1e12;
        ethAmount_ = (ethAmount_ * vaultBorrowExPrice_) / 1e12;

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param eEthPerWeETH_ Amount of eETH for one weETH.
    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// `eEthPerWeETH_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Fluid in terms of `eETH` and `STETH`.
    function getRatioFluidWeETHWstETH(
        uint256 eEthPerWeETH_,
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 weEthAmount_,
            uint256 wstEthAmount_,
            uint256 eEthAmount_,
            uint256 stEthAmount_,
            uint256 ratio_
        )
    {
        uint256 positionData_ = FLUID_VAULT_WEETH_WSTETH.readFromStorage(
            calculateStorageSlotUintMapping(3, FLUID_NFT_WEETH_WSTETH)
        );

        bool isSupplyPosition_ = (positionData_ & 1) == 1;

        weEthAmount_ = (positionData_ >> 45) & X64;
        weEthAmount_ = (weEthAmount_ >> 8) << (weEthAmount_ & X8);

        if (!isSupplyPosition_) {
            uint256 dustBorrow_ = (positionData_ >> 109) & X64;
            // Converting big number into normal number
            dustBorrow_ = (dustBorrow_ >> 8) << (dustBorrow_ & X8);

            int tick_ = (positionData_ & 2) == 2
                ? int((positionData_ >> 2) & X19)
                : -int((positionData_ >> 2) & X19);

            wstEthAmount_ =
                (TickMath.getRatioAtTick(tick_) * weEthAmount_) >>
                96;

            wstEthAmount_ = wstEthAmount_ - dustBorrow_;
        }

        (
            ,
            ,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        ) = FLUID_VAULT_WEETH_WSTETH.updateExchangePrices(
                FLUID_VAULT_WEETH_WSTETH.readFromStorage(bytes32(uint256(1)))
            );

        weEthAmount_ = (weEthAmount_ * vaultSupplyExPrice_) / 1e12;
        wstEthAmount_ = (wstEthAmount_ * vaultBorrowExPrice_) / 1e12;

        if (eEthPerWeETH_ > 0) {
            eEthAmount_ = (weEthAmount_ * eEthPerWeETH_) / 1e18;
        } else {
            eEthAmount_ = WEETH_CONTRACT.getEETHByWeETH(weEthAmount_);
        }

        if (stEthPerWsteth_ > 0) {
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }

        // Assume stETH:eETH = 1:1 (D/C Ratio)
        ratio_ = eEthAmount_ == 0 ? 0 : (stEthAmount_ * 1e6) / eEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Aave V3 in terms of `WETH` and `STETH`.
    function getRatioAaveV3Lido(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(A_WSTETH_ADDRESS_AAVEV3_LIDO).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_AAVEV3_LIDO).balanceOf(
            address(vaultDSA)
        );

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    struct RatioFluidDex {
        uint256 positionData;
        bool isSupplyPosition;
        int tick;
        uint256 colSharesAmt;
        uint256 debtSharesAmt;
        uint256 dustBorrow;
        uint256 vaultSupplyExPrice;
        uint256 vaultBorrowExPrice;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Fluid in terms of `ETH` and `STETH`.
    function getRatioFluidDex(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthColAmount_,
            uint256 stEthColAmount_,
            uint256 ethColAmount_,
            uint256 wstEthDebtAmount_,
            uint256 stEthDebtAmount_,
            uint256 ethDebtAmount_,
            uint256 ratio_
        )
    {
        RatioFluidDex memory m_;
        m_.positionData = FLUID_VAULT_T4.readFromStorage(
            calculateStorageSlotUintMapping(3, fluidDexNFT)
        );

        m_.isSupplyPosition = (m_.positionData & 1) == 1;

        m_.colSharesAmt = (m_.positionData >> 45) & X64;
        m_.colSharesAmt = (m_.colSharesAmt >> 8) << (m_.colSharesAmt & X8);

        if (!m_.isSupplyPosition) {
            m_.dustBorrow = (m_.positionData >> 109) & X64;
            // Converting big number into normal number
            m_.dustBorrow = (m_.dustBorrow >> 8) << (m_.dustBorrow & X8);

            m_.tick = (m_.positionData & 2) == 2
                ? int((m_.positionData >> 2) & X19)
                : -int((m_.positionData >> 2) & X19);

            m_.debtSharesAmt =
                (TickMath.getRatioAtTick(m_.tick) * m_.colSharesAmt) >>
                96;

            m_.debtSharesAmt = m_.debtSharesAmt - m_.dustBorrow;
        }

        (, , m_.vaultSupplyExPrice, m_.vaultBorrowExPrice) = FLUID_VAULT_T4
            .updateExchangePrices(
                FLUID_VAULT_T4.readFromStorage(bytes32(uint256(1)))
            );

        m_.colSharesAmt = (m_.colSharesAmt * m_.vaultSupplyExPrice) / 1e12;
        m_.debtSharesAmt = (m_.debtSharesAmt * m_.vaultBorrowExPrice) / 1e12;

        (
            wstEthColAmount_,
            wstEthDebtAmount_,
            ethColAmount_,
            ethDebtAmount_
        ) = _getDexLiteNftCollateralAndDebt(m_.colSharesAmt, m_.debtSharesAmt);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthColAmount_ = (wstEthColAmount_ * stEthPerWsteth_) / 1e18;
            stEthDebtAmount_ = (wstEthDebtAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthColAmount_ = WSTETH_CONTRACT.getStETHByWstETH(
                wstEthColAmount_
            );
            stEthDebtAmount_ = WSTETH_CONTRACT.getStETHByWstETH(
                wstEthDebtAmount_
            );
        }

        ratio_ = stEthColAmount_ == 0
            ? 0
            : ((ethDebtAmount_ + stEthDebtAmount_) * 1e6) /
                (ethColAmount_ + stEthColAmount_);
    }

    function getProtocolRatio(
        uint8 protocolId_
    ) public view returns (uint256 ratio_) {
        if (protocolId_ == 2) {
            // wstETH & weETH based protocol
            uint256 eEthPerWeETH_ = WEETH_CONTRACT.getEETHByWeETH(1e18);
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , , , ratio_) = getRatioAaveV3(eEthPerWeETH_, stEthPerWsteth_);
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioCompoundV3(stEthPerWsteth_);
        } else if (protocolId_ == 7) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioSpark(stEthPerWsteth_);
        } else if (protocolId_ == 9) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioFluidNew(stEthPerWsteth_);
        } else if (protocolId_ == 10) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioAaveV3Lido(stEthPerWsteth_);
        } else if (protocolId_ == 11) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , , , , ratio_) = getRatioFluidDex(stEthPerWsteth_);
        } else if (protocolId_ == 12) {
            // weETH based protocol
            uint256 eEthPerWeETH_ = WEETH_CONTRACT.getEETHByWeETH(1e18);
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , , ratio_) = getRatioFluidWeETHWstETH(
                eEthPerWeETH_,
                stEthPerWsteth_
            );
        } else {
            // @notice Support for protocolId_ == 1, 4, 5, 6, 8 is removed in July 2025 release.
            // @dev Calling this function with any of these protocolId_ will revert.
            revert Helpers__UnsupportedProtocolId();
        }
    }

    function getNetAssets()
        public
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) including revenue
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Revenue
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - Revenue))
            NetAssetsHelper memory assets_
        )
    {
        ConversionRates memory conversionRates_;
        conversionRates_.eEthPerWeETH = WEETH_CONTRACT.getEETHByWeETH(1e18);
        conversionRates_.stETHPerWstETH = WSTETH_CONTRACT.stEthPerToken();

        // Calculate collateral and debt values for all the protocols

        // wstETH & weETH based protocols
        (
            assets_.aaveV3.wstETH,
            assets_.aaveV3.weETH,
            assets_.aaveV3.eETH,
            assets_.aaveV3.stETH,
            assets_.aaveV3.wETH,
            /* ratio_ */
        ) = getRatioAaveV3(
            conversionRates_.eEthPerWeETH,
            conversionRates_.stETHPerWstETH
        );

        // wstETH based protocols
        (
            assets_.compoundV3.wstETH,
            ,
            assets_.compoundV3.wETH,
            /* ratio_ */
        ) = getRatioCompoundV3(conversionRates_.stETHPerWstETH);

        // wstETH based protocols
        (assets_.spark.wstETH, , assets_.spark.wETH, /* ratio_ */) = getRatioSpark(
            conversionRates_.stETHPerWstETH
        );

        // wstETH based protocols
        (assets_.fluidNew.wstETH, , assets_.fluidNew.wETH, /* ratio_ */) = getRatioFluidNew(
            conversionRates_.stETHPerWstETH
        );

        // wstETH based protocols
        (
            assets_.aaveV3Lido.wstETH,
            ,
            assets_.aaveV3Lido.wETH,
            /* ratio_ */
        ) = getRatioAaveV3Lido(conversionRates_.stETHPerWstETH);

        // Dex wstETH based protocols
        (
            assets_.fluidDex.wstETHSupply,
            ,
            assets_.fluidDex.ethSupply,
            assets_.fluidDex.wstETHBorrow,
            assets_.fluidDex.stETHBorrow,
            assets_.fluidDex.ethBorrow,
            /* ratio_ */
        ) = getRatioFluidDex(conversionRates_.stETHPerWstETH);

        // weETH based protocol
        (
            assets_.fluidWeETH.weETH,
            assets_.fluidWeETH.wstETH,
            assets_.fluidWeETH.eETH,
            assets_.fluidWeETH.stETH,
            /* ratio_ */
        ) = getRatioFluidWeETHWstETH(
            conversionRates_.eEthPerWeETH,
            conversionRates_.stETHPerWstETH
        );

        // Ideal wstETH balances in vault and DSA
        assets_.vaultBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal weETH balances in vault and DSA
        assets_.vaultBalances.weETH = IERC20(WEETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.weETH = IERC20(WEETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal eETH balances in vault and DSA
        assets_.vaultBalances.eETH = IERC20(EETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.eETH = IERC20(EETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal stETH balances in vault and DSA
        assets_.vaultBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal wETH balances in vault and DSA
        assets_.vaultBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(this)
        );
        assets_.dsaBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Net assets are always calculated as (stETH + eETH) supplied - ETH borrowed.
        totalAssets_ = _calculateTotalAssets(assets_);

        // Aggregating total wETH debt from protocols
        totalDebt_ = _calculateTotalDebts(assets_);

        // Assuming wETH 1:1 stETH
        netAssets_ = totalAssets_ - totalDebt_ - revenue;
        aggregatedRatio_ = totalAssets_ == 0
            ? 0
            : ((totalDebt_ * 1e6) / (totalAssets_ - revenue));
    }

    /// @notice Internal function to calculate the total assets of the vault.
    /// @param assets_ The assets of the vault.
    /// @return totalAssets_ The total assets of the vault.
    function _calculateTotalAssets(
        NetAssetsHelper memory assets_
    ) internal view returns (uint256 totalAssets_) {
        // Aggregating total stETH + eETH + wETH including revenue
        totalAssets_ =
            // Ideal stETH balances
            assets_.vaultBalances.stETH +
            assets_.dsaBalances.stETH +

            // Convert all wstETH to stETH to get the same base token.
            IWstETH(WSTETH_ADDRESS).getStETHByWstETH(
                _calculateTotalWstEthCollateral(assets_)
            ) +

            // eETH balances, assuming eETH 1:1 stETH
            // Aave V3 weETH collateral in terms of eETH
            assets_.aaveV3.eETH +
            // Fluid weETH collateral in terms of eETH
            assets_.fluidWeETH.eETH +
            // eETH in vault
            assets_.vaultBalances.eETH +
            // eETH in DSA
            assets_.dsaBalances.eETH +

            // Converting weETH to eETH
            IWeEth(WEETH_ADDRESS).getEETHByWeETH(
                assets_.dsaBalances.weETH + 
                assets_.vaultBalances.weETH
            ) +

            // Fluid Dex ETH supply
            assets_.fluidDex.ethSupply +
            
            // Ideal wETH balance and assuming wETH 1:1 stETH
            assets_.vaultBalances.wETH +
            assets_.dsaBalances.wETH +
            // Lido queued withdraw assets
            queuedWithdrawStEth;
    }

    /// @notice Internal function to calculate the total wstETH collateral of the vault.
    /// @param assets_ The assets of the vault.
    /// @return totalWstEthCollateral_ The total wstETH collateral of the vault.
    function _calculateTotalWstEthCollateral(
        NetAssetsHelper memory assets_
    ) internal view returns (uint256 totalWstEthCollateral_) {
        totalWstEthCollateral_ =
            assets_.aaveV3.wstETH +
            assets_.compoundV3.wstETH +
            assets_.spark.wstETH +
            assets_.fluidNew.wstETH +
            assets_.aaveV3Lido.wstETH +
            assets_.fluidDex.wstETHSupply +
            // Ideal wstETH balances
            assets_.vaultBalances.wstETH +
            assets_.dsaBalances.wstETH +

            // Allocation to team multisig
            allocationToTeamMultisig;
    }

    /// @notice Internal function to calculate the total debts of the vault.
    /// @param assets_ The assets of the vault.
    /// @return totalDebt_ The total debts of the vault.
    function _calculateTotalDebts(
        NetAssetsHelper memory assets_
    ) internal view returns (uint256 totalDebt_) {
        totalDebt_ =
            assets_.aaveV3.wETH +
            assets_.compoundV3.wETH +
            assets_.spark.wETH +
            assets_.fluidNew.wETH +
            assets_.aaveV3Lido.wETH +
            assets_.fluidDex.ethBorrow +
            // DEX - (wstETH already converted to stETH)
            assets_.fluidDex.stETHBorrow + // Assuming stETH 1:1 wETH
            // Fluid wstETH borrowings in terms of stETH
            // T1 - (wstETH already converted to stETH)
            assets_.fluidWeETH.stETH; // Assuming stETH 1:1 wETH
    }

    /// @notice calculates the withdraw fee: max(percentage amount, absolute amount)
    /// @param stETHAmount_ the amount of assets being withdrawn
    /// @return the withdraw fee amount in assets
    function getWithdrawFee(
        uint256 stETHAmount_
    ) public view returns (uint256) {
        // percentage is in 1e4(1% is 10_000) here we want to have 100% as denominator
        uint256 withdrawFee = (stETHAmount_ * withdrawalFeePercentage) / 1e6;

        if (withdrawFeeAbsoluteMin > withdrawFee) {
            return withdrawFeeAbsoluteMin;
        }
        return withdrawFee;
    }
}

// ===== contracts/vault/common/interfaces.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IWeEth {
    function getEETHByWeETH(
        uint256 _weETHAmount
    ) external view returns (uint256);

    function getWeETHByeETH(
        uint256 _eETHAmount
    ) external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}
interface ILidoWithdrawalQueue {
    // code below from Lido WithdrawalQueueBase.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueueBase.sol

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    /// @notice length of the checkpoints. Last possible value for the claim hint
    function getLastCheckpointIndex() external view returns (uint256);

    // code below from Lido WithdrawalQueue.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueue.sol

    /// @notice Request the sequence of stETH withdrawals according to passed `withdrawalRequestInputs` data
    /// @param amounts an array of stETH amount values. The standalone withdrawal request will
    ///  be created for each item in the passed list.
    /// @param _owner address that will be able to transfer or claim the request.
    ///  If `owner` is set to `address(0)`, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal requests
    function requestWithdrawals(
        uint256[] calldata amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @notice Claim a batch of withdrawal requests once finalized (claimable) sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id.
    ///   Can be retrieved with `findCheckpointHints()`
    /// @dev
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /// @notice Returns all withdrawal requests that belongs to the `_owner` address
    ///
    /// WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`. NB! Array of request ids should be sorted
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range
    /// @param _lastIndex right boundary of the search range
    /// @return hintIds the hints for `claimWithdrawal` to find the checkpoint for the passed request ids
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);

    /// @notice Returns statuses for the array of request ids
    /// @param _requestIds array of withdrawal request ids
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    function balanceOf(address) external view returns (uint);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IWeth {
    function deposit() external payable;

    function transfer(address dst, uint wad) external returns (bool);
}

interface IFluidVaultT1 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );

    function operate(
        uint256 nftId_, // if 0 then new position
        int256 newCol_, // if negative then withdraw
        int256 newDebt_, // if negative then payback
        address to_ // address at which the borrow & withdraw amount should go to. If address(0) then it'll go to msg.sender
    )
        external
        payable
        returns (
            uint256, // nftId_
            int256, // final supply amount. if - then withdraw
            int256 // final borrow amount. if - then payback
        );
}

interface IFluidVaultT4 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );
}

interface IFluidDexT1 {
    function getRatio() external view returns (uint256 ratio_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    struct Implementations {
        address shift;
        address admin;
        address colOperations;
        address debtOperations;
        address perfectOperationsAndOracle;
    }

    struct ConstantViews {
        uint256 dexId;
        address liquidity;
        address factory;
        Implementations implementations;
        address deployerContract;
        address token0;
        address token1;
        bytes32 supplyToken0Slot;
        bytes32 borrowToken0Slot;
        bytes32 supplyToken1Slot;
        bytes32 borrowToken1Slot;
        bytes32 exchangePriceToken0Slot;
        bytes32 exchangePriceToken1Slot;
        uint256 oracleMapping;
    }

    function constantsView()
        external
        view
        returns (ConstantViews memory constantsView_);
}

interface ILiquidity {
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
}

// ===== contracts/vault/common/liquidityCalcs.sol =====
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LiquiditySlotsLink } from "./liquiditySlotsLink.sol";
import { BigMathMinified } from "./bigMathMinified.sol";

/// @notice implements calculation methods used for Fluid liquidity such as updated exchange prices,
/// borrow rate, withdrawal / borrow limits, revenue amount.
library LiquidityCalcs {
    error FluidLiquidityCalcsError(uint256 errorId_);

    /// @notice emitted if the calculated borrow rate surpassed max borrow rate (16 bits) and was capped at maximum value 65535
    event BorrowRateMaxCap();

    /// @dev constants as from Liquidity variables.sol
    uint256 internal constant EXCHANGE_PRICES_PRECISION = 1e12;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
    // constants used for BigMath conversion from and to storage
    uint256 internal constant DEFAULT_EXPONENT_SIZE = 8;
    uint256 internal constant DEFAULT_EXPONENT_MASK = 0xFF;

    uint256 internal constant FOUR_DECIMALS = 1e4;
    uint256 internal constant TWELVE_DECIMALS = 1e12;
    uint256 internal constant X14 = 0x3fff;
    uint256 internal constant X15 = 0x7fff;
    uint256 internal constant X16 = 0xffff;
    uint256 internal constant X18 = 0x3ffff;
    uint256 internal constant X24 = 0xffffff;
    uint256 internal constant X33 = 0x1ffffffff;
    uint256 internal constant X64 = 0xffffffffffffffff;

    ///////////////////////////////////////////////////////////////////////////
    //////////                  CALC EXCHANGE PRICES                  /////////
    ///////////////////////////////////////////////////////////////////////////

    /// @dev calculates interest (exchange prices) for a token given its' exchangePricesAndConfig from storage.
    /// @param exchangePricesAndConfig_ exchange prices and config packed uint256 read from storage
    /// @return supplyExchangePrice_ updated supplyExchangePrice
    /// @return borrowExchangePrice_ updated borrowExchangePrice
    function calcExchangePrices(
        uint256 exchangePricesAndConfig_
    ) internal view returns (uint256 supplyExchangePrice_, uint256 borrowExchangePrice_) {
        // Extracting exchange prices
        supplyExchangePrice_ =
            (exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_SUPPLY_EXCHANGE_PRICE) &
            X64;
        borrowExchangePrice_ =
            (exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_BORROW_EXCHANGE_PRICE) &
            X64;

        if (supplyExchangePrice_ == 0 || borrowExchangePrice_ == 0) {
            revert();
        }

        uint256 temp_ = exchangePricesAndConfig_ & X16; // temp_ = borrowRate

        unchecked {
            // last timestamp can not be > current timestamp
            uint256 secondsSinceLastUpdate_ = block.timestamp -
                ((exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_LAST_TIMESTAMP) & X33);

            uint256 borrowRatio_ = (exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_BORROW_RATIO) &
                X15;
            if (secondsSinceLastUpdate_ == 0 || temp_ == 0 || borrowRatio_ == 1) {
                // if no time passed, borrow rate is 0, or no raw borrowings: no exchange price update needed
                // (if borrowRatio_ == 1 means there is only borrowInterestFree, as first bit is 1 and rest is 0)
                return (supplyExchangePrice_, borrowExchangePrice_);
            }

            // calculate new borrow exchange price.
            // formula borrowExchangePriceIncrease: previous price * borrow rate * secondsSinceLastUpdate_.
            // nominator is max uint112 (uint64 * uint16 * uint32). Divisor can not be 0.
            borrowExchangePrice_ +=
                (borrowExchangePrice_ * temp_ * secondsSinceLastUpdate_) /
                (SECONDS_PER_YEAR * FOUR_DECIMALS);

            // FOR SUPPLY EXCHANGE PRICE:
            // all yield paid by borrowers (in mode with interest) goes to suppliers in mode with interest.
            // formula: previous price * supply rate * secondsSinceLastUpdate_.
            // where supply rate = (borrow rate  - revenueFee%) * ratioSupplyYield. And
            // ratioSupplyYield = utilization * supplyRatio * borrowRatio
            //
            // Example:
            // supplyRawInterest is 80, supplyInterestFree is 20. totalSupply is 100. BorrowedRawInterest is 50.
            // BorrowInterestFree is 10. TotalBorrow is 60. borrow rate 40%, revenueFee 10%.
            // yield is 10 (so half a year must have passed).
            // supplyRawInterest must become worth 89. totalSupply must become 109. BorrowedRawInterest must become 60.
            // borrowInterestFree must still be 10. supplyInterestFree still 20. totalBorrow 70.
            // supplyExchangePrice would have to go from 1 to 1,125 (+ 0.125). borrowExchangePrice from 1 to 1,2 (+0.2).
            // utilization is 60%. supplyRatio = 20 / 80 = 25% (only 80% of lenders receiving yield).
            // borrowRatio = 10 / 50 = 20% (only 83,333% of borrowers paying yield):
            // x of borrowers paying yield = 100% - (20 / (100 + 20)) = 100% - 16.6666666% = 83,333%.
            // ratioSupplyYield = 60% * 83,33333% * (100% + 20%) = 62,5%
            // supplyRate = (40% * (100% - 10%)) * = 36% * 62,5% = 22.5%
            // increase in supplyExchangePrice, assuming 100 as previous price.
            // 100 * 22,5% * 1/2 (half a year) = 0,1125.
            // cross-check supplyRawInterest worth = 80 * 1.1125 = 89. totalSupply worth = 89 + 20.

            // -------------- 1. calculate ratioSupplyYield --------------------------------
            // step1: utilization * supplyRatio (or actually part of lenders receiving yield)

            // temp_ => supplyRatio (in 1e2: 100% = 10_000; 1% = 100 -> max value 16_383)
            // if first bit 0 then ratio is supplyInterestFree / supplyWithInterest (supplyWithInterest is bigger)
            // else ratio is supplyWithInterest / supplyInterestFree (supplyInterestFree is bigger)
            temp_ = (exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_SUPPLY_RATIO) & X15;

            if (temp_ == 1) {
                // if no raw supply: no exchange price update needed
                // (if supplyRatio_ == 1 means there is only supplyInterestFree, as first bit is 1 and rest is 0)
                return (supplyExchangePrice_, borrowExchangePrice_);
            }

            // ratioSupplyYield precision is 1e27 as 100% for increased precision when supplyInterestFree > supplyWithInterest
            if (temp_ & 1 == 1) {
                // ratio is supplyWithInterest / supplyInterestFree (supplyInterestFree is bigger)
                temp_ = temp_ >> 1;

                // Note: case where temp_ == 0 (only supplyInterestFree, no yield) already covered by early return
                // in the if statement a little above.

                // based on above example but supplyRawInterest is 20, supplyInterestFree is 80. no fee.
                // supplyRawInterest must become worth 30. totalSupply must become 110.
                // supplyExchangePrice would have to go from 1 to 1,5. borrowExchangePrice from 1 to 1,2.
                // so ratioSupplyYield must come out as 2.5 (250%).
                // supplyRatio would be (20 * 10_000 / 80) = 2500. but must be inverted.
                temp_ = (1e27 * FOUR_DECIMALS) / temp_; // e.g. 1e31 / 2500 = 4e27. (* 1e27 for precision)
                // e.g. 5_000 * (1e27 + 4e27) / 1e27 = 25_000 (=250%).
                temp_ =
                    // utilization * (100% + 100% / supplyRatio)
                    (((exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_UTILIZATION) & X14) *
                        (1e27 + temp_)) / // extract utilization (max 16_383 so there is no way this can overflow).
                    (FOUR_DECIMALS);
                // max possible value of temp_ here is 16383 * (1e27 + 1e31) / 1e4 = ~1.64e31
            } else {
                // ratio is supplyInterestFree / supplyWithInterest (supplyWithInterest is bigger)
                temp_ = temp_ >> 1;
                // if temp_ == 0 then only supplyWithInterest => full yield. temp_ is already 0

                // e.g. 5_000 * 10_000 + (20 * 10_000 / 80) / 10_000 = 5000 * 12500 / 10000 = 6250 (=62.5%).
                temp_ =
                    // 1e27 * utilization * (100% + supplyRatio) / 100%
                    (1e27 *
                        ((exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_UTILIZATION) & X14) * // extract utilization (max 16_383 so there is no way this can overflow).
                        (FOUR_DECIMALS + temp_)) /
                    (FOUR_DECIMALS * FOUR_DECIMALS);
                // max possible temp_ value: 1e27 * 16383 * 2e4 / 1e8 = 3.2766e27
            }
            // from here temp_ => ratioSupplyYield (utilization * supplyRatio part) scaled by 1e27. max possible value ~1.64e31

            // step2 of ratioSupplyYield: add borrowRatio (only x% of borrowers paying yield)
            if (borrowRatio_ & 1 == 1) {
                // ratio is borrowWithInterest / borrowInterestFree (borrowInterestFree is bigger)
                borrowRatio_ = borrowRatio_ >> 1;
                // borrowRatio_ => x of total bororwers paying yield. scale to 1e27.

                // Note: case where borrowRatio_ == 0 (only borrowInterestFree, no yield) already covered
                // at the beginning of the method by early return if `borrowRatio_ == 1`.

                // based on above example but borrowRawInterest is 10, borrowInterestFree is 50. no fee. borrowRatio = 20%.
                // so only 16.66% of borrowers are paying yield. so the 100% - part of the formula is not needed.
                // x of borrowers paying yield = (borrowRatio / (100 + borrowRatio)) = 16.6666666%
                // borrowRatio_ => x of total bororwers paying yield. scale to 1e27.
                borrowRatio_ = (borrowRatio_ * 1e27) / (FOUR_DECIMALS + borrowRatio_);
                // max value here for borrowRatio_ is (1e31 / (1e4 + 1e4))= 5e26 (= 50% of borrowers paying yield).
            } else {
                // ratio is borrowInterestFree / borrowWithInterest (borrowWithInterest is bigger)
                borrowRatio_ = borrowRatio_ >> 1;

                // borrowRatio_ => x of total bororwers paying yield. scale to 1e27.
                // x of borrowers paying yield = 100% - (borrowRatio / (100 + borrowRatio)) = 100% - 16.6666666% = 83,333%.
                borrowRatio_ = (1e27 - ((borrowRatio_ * 1e27) / (FOUR_DECIMALS + borrowRatio_)));
                // borrowRatio can never be > 100%. so max subtraction can be 100% - 100% / 200%.
                // or if borrowRatio_ is 0 -> 100% - 0. or if borrowRatio_ is 1 -> 100% - 1 / 101.
                // max value here for borrowRatio_ is 1e27 - 0 = 1e27 (= 100% of borrowers paying yield).
            }

            // temp_ => ratioSupplyYield. scaled down from 1e25 = 1% each to normal percent precision 1e2 = 1%.
            // max nominator value is ~1.64e31 * 1e27 = 1.64e58. max result = 1.64e8
            temp_ = (FOUR_DECIMALS * temp_ * borrowRatio_) / 1e54;

            // 2. calculate supply rate
            // temp_ => supply rate (borrow rate  - revenueFee%) * ratioSupplyYield.
            // division part is done in next step to increase precision. (divided by 2x FOUR_DECIMALS, fee + borrowRate)
            // Note that all calculation divisions for supplyExchangePrice are rounded down.
            // Note supply rate can be bigger than the borrowRate, e.g. if there are only few lenders with interest
            // but more suppliers not earning interest.
            temp_ = ((exchangePricesAndConfig_ & X16) * // borrow rate
                temp_ * // ratioSupplyYield
                (FOUR_DECIMALS - ((exchangePricesAndConfig_ >> LiquiditySlotsLink.BITS_EXCHANGE_PRICES_FEE) & X14))); // revenueFee
            // fee can not be > 100%. max possible = 65535 * ~1.64e8 * 1e4 =~1.074774e17.

            // 3. calculate increase in supply exchange price
            supplyExchangePrice_ += ((supplyExchangePrice_ * temp_ * secondsSinceLastUpdate_) /
                (SECONDS_PER_YEAR * FOUR_DECIMALS * FOUR_DECIMALS * FOUR_DECIMALS));
            // max possible nominator = max uint 64 * 1.074774e17 * max uint32 = ~8.52e45. Denominator can not be 0.
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    //////////                     CALC REVENUE                       /////////
    ///////////////////////////////////////////////////////////////////////////

    /// @dev gets the `revenueAmount_` for a token given its' totalAmounts and exchangePricesAndConfig from storage
    /// and the current balance of the Fluid liquidity contract for the token.
    /// @param totalAmounts_ total amounts packed uint256 read from storage
    /// @param exchangePricesAndConfig_ exchange prices and config packed uint256 read from storage
    /// @param liquidityTokenBalance_   current balance of Liquidity contract (IERC20(token_).balanceOf(address(this)))
    /// @return revenueAmount_ collectable revenue amount
    function calcRevenue(
        uint256 totalAmounts_,
        uint256 exchangePricesAndConfig_,
        uint256 liquidityTokenBalance_
    ) internal view returns (uint256 revenueAmount_) {
        // @dev no need to super-optimize this method as it is only used by admin

        // calculate the new exchange prices based on earned interest
        (uint256 supplyExchangePrice_, uint256 borrowExchangePrice_) = calcExchangePrices(exchangePricesAndConfig_);

        // total supply = interest free + with interest converted from raw
        uint256 totalSupply_ = getTotalSupply(totalAmounts_, supplyExchangePrice_);

        if (totalSupply_ > 0) {
            // available revenue: balanceOf(token) + totalBorrowings - totalLendings.
            revenueAmount_ = liquidityTokenBalance_ + getTotalBorrow(totalAmounts_, borrowExchangePrice_);
            // ensure there is no possible case because of rounding etc. where this would revert,
            // explicitly check if >
            revenueAmount_ = revenueAmount_ > totalSupply_ ? revenueAmount_ - totalSupply_ : 0;
            // Note: if utilization > 100% (totalSupply < totalBorrow), then all the amount above 100% utilization
            // can only be revenue.
        } else {
            // if supply is 0, then rest of balance can be withdrawn as revenue so that no amounts get stuck
            revenueAmount_ = liquidityTokenBalance_;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    //////////                      CALC LIMITS                       /////////
    ///////////////////////////////////////////////////////////////////////////

    /// @dev calculates withdrawal limit before an operate execution:
    /// amount of user supply that must stay supplied (not amount that can be withdrawn).
    /// i.e. if user has supplied 100m and can withdraw 5M, this method returns the 95M, not the withdrawable amount 5M
    /// @param userSupplyData_ user supply data packed uint256 from storage
    /// @param userSupply_ current user supply amount already extracted from `userSupplyData_` and converted from BigMath
    /// @return currentWithdrawalLimit_ current withdrawal limit updated for expansion since last interaction.
    ///         returned value is in raw for with interest mode, normal amount for interest free mode!
    function calcWithdrawalLimitBeforeOperate(
        uint256 userSupplyData_,
        uint256 userSupply_
    ) internal view returns (uint256 currentWithdrawalLimit_) {
        // @dev must support handling the case where timestamp is 0 (config is set but no interactions yet).
        // first tx where timestamp is 0 will enter `if (lastWithdrawalLimit_ == 0)` because lastWithdrawalLimit_ is not set yet.
        // returning max withdrawal allowed, which is not exactly right but doesn't matter because the first interaction must be
        // a deposit anyway. Important is that it would not revert.

        // Note the first time a deposit brings the user supply amount to above the base withdrawal limit, the active limit
        // is the fully expanded limit immediately.

        // extract last set withdrawal limit
        uint256 lastWithdrawalLimit_ = (userSupplyData_ >>
            LiquiditySlotsLink.BITS_USER_SUPPLY_PREVIOUS_WITHDRAWAL_LIMIT) & X64;
        lastWithdrawalLimit_ =
            (lastWithdrawalLimit_ >> DEFAULT_EXPONENT_SIZE) <<
            (lastWithdrawalLimit_ & DEFAULT_EXPONENT_MASK);
        if (lastWithdrawalLimit_ == 0) {
            // withdrawal limit is not activated. Max withdrawal allowed
            return 0;
        }

        uint256 maxWithdrawableLimit_;
        uint256 temp_;
        unchecked {
            // extract max withdrawable percent of user supply and
            // calculate maximum withdrawable amount expandPercentage of user supply at full expansion duration elapsed
            // e.g.: if 10% expandPercentage, meaning 10% is withdrawable after full expandDuration has elapsed.

            // userSupply_ needs to be atleast 1e73 to overflow max limit of ~1e77 in uint256 (no token in existence where this is possible).
            maxWithdrawableLimit_ =
                (((userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_PERCENT) & X14) * userSupply_) /
                FOUR_DECIMALS;

            // time elapsed since last withdrawal limit was set (in seconds)
            // @dev last process timestamp is guaranteed to exist for withdrawal, as a supply must have happened before.
            // last timestamp can not be > current timestamp
            temp_ =
                block.timestamp -
                ((userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_LAST_UPDATE_TIMESTAMP) & X33);
        }
        // calculate withdrawable amount of expandPercent that is elapsed of expandDuration.
        // e.g. if 60% of expandDuration has elapsed, then user should be able to withdraw 6% of user supply, down to 94%.
        // Note: no explicit check for this needed, it is covered by setting minWithdrawalLimit_ if needed.
        temp_ =
            (maxWithdrawableLimit_ * temp_) /
            // extract expand duration: After this, decrement won't happen (user can withdraw 100% of withdraw limit)
            ((userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_DURATION) & X24); // expand duration can never be 0
        // calculate expanded withdrawal limit: last withdrawal limit - withdrawable amount.
        // Note: withdrawable amount here can grow bigger than userSupply if timeElapsed is a lot bigger than expandDuration,
        // which would cause the subtraction `lastWithdrawalLimit_ - withdrawableAmount_` to revert. In that case, set 0
        // which will cause minimum (fully expanded) withdrawal limit to be set in lines below.
        unchecked {
            // underflow explicitly checked & handled
            currentWithdrawalLimit_ = lastWithdrawalLimit_ > temp_ ? lastWithdrawalLimit_ - temp_ : 0;
            // calculate minimum withdrawal limit: minimum amount of user supply that must stay supplied at full expansion.
            // subtraction can not underflow as maxWithdrawableLimit_ is a percentage amount (<=100%) of userSupply_
            temp_ = userSupply_ - maxWithdrawableLimit_;
        }
        // if withdrawal limit is decreased below minimum then set minimum
        // (e.g. when more than expandDuration time has elapsed)
        if (temp_ > currentWithdrawalLimit_) {
            currentWithdrawalLimit_ = temp_;
        }
    }

    /// @dev calculates withdrawal limit after an operate execution:
    /// amount of user supply that must stay supplied (not amount that can be withdrawn).
    /// i.e. if user has supplied 100m and can withdraw 5M, this method returns the 95M, not the withdrawable amount 5M
    /// @param userSupplyData_ user supply data packed uint256 from storage
    /// @param userSupply_ current user supply amount already extracted from `userSupplyData_` and added / subtracted with the executed operate amount
    /// @param newWithdrawalLimit_ current withdrawal limit updated for expansion since last interaction, result from `calcWithdrawalLimitBeforeOperate`
    /// @return withdrawalLimit_ updated withdrawal limit that should be written to storage. returned value is in
    ///                          raw for with interest mode, normal amount for interest free mode!
    function calcWithdrawalLimitAfterOperate(
        uint256 userSupplyData_,
        uint256 userSupply_,
        uint256 newWithdrawalLimit_
    ) internal pure returns (uint256) {
        // temp_ => base withdrawal limit. below this, maximum withdrawals are allowed
        uint256 temp_ = (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT) & X18;
        temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);

        // if user supply is below base limit then max withdrawals are allowed
        if (userSupply_ < temp_) {
            return 0;
        }
        // temp_ => withdrawal limit expandPercent (is in 1e2 decimals)
        temp_ = (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_PERCENT) & X14;
        unchecked {
            // temp_ => minimum withdrawal limit: userSupply - max withdrawable limit (userSupply * expandPercent))
            // userSupply_ needs to be atleast 1e73 to overflow max limit of ~1e77 in uint256 (no token in existence where this is possible).
            // subtraction can not underflow as maxWithdrawableLimit_ is a percentage amount (<=100%) of userSupply_
            temp_ = userSupply_ - ((userSupply_ * temp_) / FOUR_DECIMALS);
        }
        // if new (before operation) withdrawal limit is less than minimum limit then set minimum limit.
        // e.g. can happen on new deposits. withdrawal limit is instantly fully expanded in a scenario where
        // increased deposit amount outpaces withrawals.
        if (temp_ > newWithdrawalLimit_) {
            return temp_;
        }
        return newWithdrawalLimit_;
    }

    /// @dev calculates borrow limit before an operate execution:
    /// total amount user borrow can reach (not borrowable amount in current operation).
    /// i.e. if user has borrowed 50M and can still borrow 5M, this method returns the total 55M, not the borrowable amount 5M
    /// @param userBorrowData_ user borrow data packed uint256 from storage
    /// @param userBorrow_ current user borrow amount already extracted from `userBorrowData_`
    /// @return currentBorrowLimit_ current borrow limit updated for expansion since last interaction. returned value is in
    ///                             raw for with interest mode, normal amount for interest free mode!
    function calcBorrowLimitBeforeOperate(
        uint256 userBorrowData_,
        uint256 userBorrow_
    ) internal view returns (uint256 currentBorrowLimit_) {
        // @dev must support handling the case where timestamp is 0 (config is set but no interactions yet) -> base limit.
        // first tx where timestamp is 0 will enter `if (maxExpandedBorrowLimit_ < baseBorrowLimit_)` because `userBorrow_` and thus
        // `maxExpansionLimit_` and thus `maxExpandedBorrowLimit_` is 0 and `baseBorrowLimit_` can not be 0.

        // temp_ = extract borrow expand percent (is in 1e2 decimals)
        uint256 temp_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_PERCENT) & X14;

        uint256 maxExpansionLimit_;
        uint256 maxExpandedBorrowLimit_;
        unchecked {
            // calculate max expansion limit: Max amount limit can expand to since last interaction
            // userBorrow_ needs to be atleast 1e73 to overflow max limit of ~1e77 in uint256 (no token in existence where this is possible).
            maxExpansionLimit_ = ((userBorrow_ * temp_) / FOUR_DECIMALS);

            // calculate max borrow limit: Max point limit can increase to since last interaction
            maxExpandedBorrowLimit_ = userBorrow_ + maxExpansionLimit_;
        }

        // currentBorrowLimit_ = extract base borrow limit
        currentBorrowLimit_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18;
        currentBorrowLimit_ =
            (currentBorrowLimit_ >> DEFAULT_EXPONENT_SIZE) <<
            (currentBorrowLimit_ & DEFAULT_EXPONENT_MASK);

        if (maxExpandedBorrowLimit_ < currentBorrowLimit_) {
            return currentBorrowLimit_;
        }
        // time elapsed since last borrow limit was set (in seconds)
        unchecked {
            // temp_ = timeElapsed_ (last timestamp can not be > current timestamp)
            temp_ =
                block.timestamp -
                ((userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_LAST_UPDATE_TIMESTAMP) & X33); // extract last update timestamp
        }

        // currentBorrowLimit_ = expandedBorrowableAmount + extract last set borrow limit
        currentBorrowLimit_ =
            // calculate borrow limit expansion since last interaction for `expandPercent` that is elapsed of `expandDuration`.
            // divisor is extract expand duration (after this, full expansion to expandPercentage happened).
            ((maxExpansionLimit_ * temp_) /
                ((userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_DURATION) & X24)) + // expand duration can never be 0
            //  extract last set borrow limit
            BigMathMinified.fromBigNumber(
                (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_PREVIOUS_BORROW_LIMIT) & X64,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            );

        // if timeElapsed is bigger than expandDuration, new borrow limit would be > max expansion,
        // so set to `maxExpandedBorrowLimit_` in that case.
        // also covers the case where last process timestamp = 0 (timeElapsed would simply be very big)
        if (currentBorrowLimit_ > maxExpandedBorrowLimit_) {
            currentBorrowLimit_ = maxExpandedBorrowLimit_;
        }
        // temp_ = extract hard max borrow limit. Above this user can never borrow (not expandable above)
        temp_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18;
        temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);

        if (currentBorrowLimit_ > temp_) {
            currentBorrowLimit_ = temp_;
        }
    }

    /// @dev calculates borrow limit after an operate execution:
    /// total amount user borrow can reach (not borrowable amount in current operation).
    /// i.e. if user has borrowed 50M and can still borrow 5M, this method returns the total 55M, not the borrowable amount 5M
    /// @param userBorrowData_ user borrow data packed uint256 from storage
    /// @param userBorrow_ current user borrow amount already extracted from `userBorrowData_` and added / subtracted with the executed operate amount
    /// @param newBorrowLimit_ current borrow limit updated for expansion since last interaction, result from `calcBorrowLimitBeforeOperate`
    /// @return borrowLimit_ updated borrow limit that should be written to storage.
    ///                      returned value is in raw for with interest mode, normal amount for interest free mode!
    function calcBorrowLimitAfterOperate(
        uint256 userBorrowData_,
        uint256 userBorrow_,
        uint256 newBorrowLimit_
    ) internal pure returns (uint256 borrowLimit_) {
        // temp_ = extract borrow expand percent
        uint256 temp_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_PERCENT) & X14; // (is in 1e2 decimals)

        unchecked {
            // borrowLimit_ = calculate maximum borrow limit at full expansion.
            // userBorrow_ needs to be at least 1e73 to overflow max limit of ~1e77 in uint256 (no token in existence where this is possible).
            borrowLimit_ = userBorrow_ + ((userBorrow_ * temp_) / FOUR_DECIMALS);
        }

        // temp_ = extract base borrow limit
        temp_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18;
        temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);

        if (borrowLimit_ < temp_) {
            // below base limit, borrow limit is always base limit
            return temp_;
        }
        // temp_ = extract hard max borrow limit. Above this user can never borrow (not expandable above)
        temp_ = (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18;
        temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);

        // make sure fully expanded borrow limit is not above hard max borrow limit
        if (borrowLimit_ > temp_) {
            borrowLimit_ = temp_;
        }
        // if new borrow limit (from before operate) is > max borrow limit, set max borrow limit.
        // (e.g. on a repay shrinking instantly to fully expanded borrow limit from new borrow amount. shrinking is instant)
        if (newBorrowLimit_ > borrowLimit_) {
            return borrowLimit_;
        }
        return newBorrowLimit_;
    }

    ///////////////////////////////////////////////////////////////////////////
    //////////                      CALC RATES                        /////////
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Calculates new borrow rate from utilization for a token
    /// @param rateData_ rate data packed uint256 from storage for the token
    /// @param utilization_ totalBorrow / totalSupply. 1e4 = 100% utilization
    /// @return rate_ rate for that particular token in 1e2 precision (e.g. 5% rate = 500)
    function calcBorrowRateFromUtilization(uint256 rateData_, uint256 utilization_) internal returns (uint256 rate_) {
        // extract rate version: 4 bits (0xF) starting from bit 0
        uint256 rateVersion_ = (rateData_ & 0xF);

        if (rateVersion_ == 1) {
            rate_ = calcRateV1(rateData_, utilization_);
        } else if (rateVersion_ == 2) {
            rate_ = calcRateV2(rateData_, utilization_);
        } else {
            revert();
        }

        if (rate_ > X16) {
            // hard cap for borrow rate at maximum value 16 bits (65535) to make sure it does not overflow storage space.
            // this is unlikely to ever happen if configs stay within expected levels.
            rate_ = X16;
            // emit event to more easily become aware
            emit BorrowRateMaxCap();
        }
    }

    /// @dev calculates the borrow rate based on utilization for rate data version 1 (with one kink) in 1e2 precision
    /// @param rateData_ rate data packed uint256 from storage for the token
    /// @param utilization_  in 1e2 (100% = 1e4)
    /// @return rate_ rate in 1e2 precision
    function calcRateV1(uint256 rateData_, uint256 utilization_) internal pure returns (uint256 rate_) {
        /// For rate v1 (one kink) ------------------------------------------------------
        /// Next 16  bits =>  4 - 19 => Rate at utilization 0% (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  20- 35 => Utilization at kink1 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  36- 51 => Rate at utilization kink1 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  52- 67 => Rate at utilization 100% (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Last 188 bits =>  68-255 => blank, might come in use in future

        // y = mx + c.
        // y is borrow rate
        // x is utilization
        // m = slope (m can also be negative for declining rates)
        // c is constant (c can be negative)

        uint256 y1_;
        uint256 y2_;
        uint256 x1_;
        uint256 x2_;

        // extract kink1: 16 bits (0xFFFF) starting from bit 20
        // kink is in 1e2, same as utilization, so no conversion needed for direct comparison of the two
        uint256 kink1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V1_UTILIZATION_AT_KINK) & X16;
        if (utilization_ < kink1_) {
            // if utilization is less than kink
            y1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_ZERO) & X16;
            y2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_KINK) & X16;
            x1_ = 0; // 0%
            x2_ = kink1_;
        } else {
            // else utilization is greater than kink
            y1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_KINK) & X16;
            y2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_MAX) & X16;
            x1_ = kink1_;
            x2_ = FOUR_DECIMALS; // 100%
        }

        int256 constant_;
        int256 slope_;
        unchecked {
            // calculating slope with twelve decimal precision. m = (y2 - y1) / (x2 - x1).
            // utilization of x2 can not be <= utilization of x1 (so no underflow or 0 divisor)
            // y is in 1e2 so can not overflow when multiplied with TWELVE_DECIMALS
            slope_ = (int256(y2_ - y1_) * int256(TWELVE_DECIMALS)) / int256((x2_ - x1_));

            // calculating constant at 12 decimal precision. slope is already in 12 decimal hence only multiple with y1. c = y - mx.
            // maximum y1_ value is 65535. 65535 * 1e12 can not overflow int256
            // maximum slope is 65535 - 0 * TWELVE_DECIMALS / 1 = 65535 * 1e12;
            // maximum x1_ is 100% (9_999 actually) => slope_ * x1_ can not overflow int256
            // subtraction most extreme case would be  0 - max value slope_ * x1_ => can not underflow int256
            constant_ = int256(y1_ * TWELVE_DECIMALS) - (slope_ * int256(x1_));

            // calculating new borrow rate
            // - slope_ max value is 65535 * 1e12,
            // - utilization max value is let's say 500% (extreme case where borrow rate increases borrow amount without new supply)
            // - constant max value is 65535 * 1e12
            // so max values are 65535 * 1e12 * 50_000 + 65535 * 1e12 -> 3.2768*10^21, which easily fits int256
            // divisor TWELVE_DECIMALS can not be 0
            slope_ = (slope_ * int256(utilization_)) + constant_; // reusing `slope_` as variable for gas savings
            if (slope_ < 0) {
                revert();
            }
            rate_ = uint256(slope_) / TWELVE_DECIMALS;
        }
    }

    /// @dev calculates the borrow rate based on utilization for rate data version 2 (with two kinks) in 1e4 precision
    /// @param rateData_ rate data packed uint256 from storage for the token
    /// @param utilization_  in 1e2 (100% = 1e4)
    /// @return rate_ rate in 1e4 precision
    function calcRateV2(uint256 rateData_, uint256 utilization_) internal pure returns (uint256 rate_) {
        /// For rate v2 (two kinks) -----------------------------------------------------
        /// Next 16  bits =>  4 - 19 => Rate at utilization 0% (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  20- 35 => Utilization at kink1 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  36- 51 => Rate at utilization kink1 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  52- 67 => Utilization at kink2 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  68- 83 => Rate at utilization kink2 (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Next 16  bits =>  84- 99 => Rate at utilization 100% (in 1e2: 100% = 10_000; 1% = 100 -> max value 65535)
        /// Last 156 bits => 100-255 => blank, might come in use in future

        // y = mx + c.
        // y is borrow rate
        // x is utilization
        // m = slope (m can also be negative for declining rates)
        // c is constant (c can be negative)

        uint256 y1_;
        uint256 y2_;
        uint256 x1_;
        uint256 x2_;

        // extract kink1: 16 bits (0xFFFF) starting from bit 20
        // kink is in 1e2, same as utilization, so no conversion needed for direct comparison of the two
        uint256 kink1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_UTILIZATION_AT_KINK1) & X16;
        if (utilization_ < kink1_) {
            // if utilization is less than kink1
            y1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_ZERO) & X16;
            y2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK1) & X16;
            x1_ = 0; // 0%
            x2_ = kink1_;
        } else {
            // extract kink2: 16 bits (0xFFFF) starting from bit 52
            uint256 kink2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_UTILIZATION_AT_KINK2) & X16;
            if (utilization_ < kink2_) {
                // if utilization is less than kink2
                y1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK1) & X16;
                y2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK2) & X16;
                x1_ = kink1_;
                x2_ = kink2_;
            } else {
                // else utilization is greater than kink2
                y1_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK2) & X16;
                y2_ = (rateData_ >> LiquiditySlotsLink.BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_MAX) & X16;
                x1_ = kink2_;
                x2_ = FOUR_DECIMALS;
            }
        }

        int256 constant_;
        int256 slope_;
        unchecked {
            // calculating slope with twelve decimal precision. m = (y2 - y1) / (x2 - x1).
            // utilization of x2 can not be <= utilization of x1 (so no underflow or 0 divisor)
            // y is in 1e2 so can not overflow when multiplied with TWELVE_DECIMALS
            slope_ = (int256(y2_ - y1_) * int256(TWELVE_DECIMALS)) / int256((x2_ - x1_));

            // calculating constant at 12 decimal precision. slope is already in 12 decimal hence only multiple with y1. c = y - mx.
            // maximum y1_ value is 65535. 65535 * 1e12 can not overflow int256
            // maximum slope is 65535 - 0 * TWELVE_DECIMALS / 1 = 65535 * 1e12;
            // maximum x1_ is 100% (9_999 actually) => slope_ * x1_ can not overflow int256
            // subtraction most extreme case would be  0 - max value slope_ * x1_ => can not underflow int256
            constant_ = int256(y1_ * TWELVE_DECIMALS) - (slope_ * int256(x1_));

            // calculating new borrow rate
            // - slope_ max value is 65535 * 1e12,
            // - utilization max value is let's say 500% (extreme case where borrow rate increases borrow amount without new supply)
            // - constant max value is 65535 * 1e12
            // so max values are 65535 * 1e12 * 50_000 + 65535 * 1e12 -> 3.2768*10^21, which easily fits int256
            // divisor TWELVE_DECIMALS can not be 0
            slope_ = (slope_ * int256(utilization_)) + constant_; // reusing `slope_` as variable for gas savings
            if (slope_ < 0) {
                revert();
            }
            rate_ = uint256(slope_) / TWELVE_DECIMALS;
        }
    }

    /// @dev reads the total supply out of Liquidity packed storage `totalAmounts_` for `supplyExchangePrice_`
    function getTotalSupply(
        uint256 totalAmounts_,
        uint256 supplyExchangePrice_
    ) internal pure returns (uint256 totalSupply_) {
        // totalSupply_ => supplyInterestFree
        totalSupply_ = (totalAmounts_ >> LiquiditySlotsLink.BITS_TOTAL_AMOUNTS_SUPPLY_INTEREST_FREE) & X64;
        totalSupply_ = (totalSupply_ >> DEFAULT_EXPONENT_SIZE) << (totalSupply_ & DEFAULT_EXPONENT_MASK);

        uint256 totalSupplyRaw_ = totalAmounts_ & X64; // no shifting as supplyRaw is first 64 bits
        totalSupplyRaw_ = (totalSupplyRaw_ >> DEFAULT_EXPONENT_SIZE) << (totalSupplyRaw_ & DEFAULT_EXPONENT_MASK);

        // totalSupply = supplyInterestFree + supplyRawInterest normalized from raw
        totalSupply_ += ((totalSupplyRaw_ * supplyExchangePrice_) / EXCHANGE_PRICES_PRECISION);
    }

    /// @dev reads the total borrow out of Liquidity packed storage `totalAmounts_` for `borrowExchangePrice_`
    function getTotalBorrow(
        uint256 totalAmounts_,
        uint256 borrowExchangePrice_
    ) internal pure returns (uint256 totalBorrow_) {
        // totalBorrow_ => borrowInterestFree
        // no & mask needed for borrow interest free as it occupies the last bits in the storage slot
        totalBorrow_ = (totalAmounts_ >> LiquiditySlotsLink.BITS_TOTAL_AMOUNTS_BORROW_INTEREST_FREE);
        totalBorrow_ = (totalBorrow_ >> DEFAULT_EXPONENT_SIZE) << (totalBorrow_ & DEFAULT_EXPONENT_MASK);

        uint256 totalBorrowRaw_ = (totalAmounts_ >> LiquiditySlotsLink.BITS_TOTAL_AMOUNTS_BORROW_WITH_INTEREST) & X64;
        totalBorrowRaw_ = (totalBorrowRaw_ >> DEFAULT_EXPONENT_SIZE) << (totalBorrowRaw_ & DEFAULT_EXPONENT_MASK);

        // totalBorrow = borrowInterestFree + borrowRawInterest normalized from raw
        totalBorrow_ += ((totalBorrowRaw_ * borrowExchangePrice_) / EXCHANGE_PRICES_PRECISION);
    }
}

// ===== contracts/vault/common/liquiditySlotsLink.sol =====
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @notice library that helps in reading / working with storage slot data of Fluid Liquidity.
/// @dev as all data for Fluid Liquidity is internal, any data must be fetched directly through manual
/// slot reading through this library or, if gas usage is less important, through the FluidLiquidityResolver.
library LiquiditySlotsLink {
    /// @dev storage slot for status at Liquidity
    uint256 internal constant LIQUIDITY_STATUS_SLOT = 1;
    /// @dev storage slot for auths mapping at Liquidity
    uint256 internal constant LIQUIDITY_AUTHS_MAPPING_SLOT = 2;
    /// @dev storage slot for guardians mapping at Liquidity
    uint256 internal constant LIQUIDITY_GUARDIANS_MAPPING_SLOT = 3;
    /// @dev storage slot for user class mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_CLASS_MAPPING_SLOT = 4;
    /// @dev storage slot for exchangePricesAndConfig mapping at Liquidity
    uint256 internal constant LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT = 5;
    /// @dev storage slot for rateData mapping at Liquidity
    uint256 internal constant LIQUIDITY_RATE_DATA_MAPPING_SLOT = 6;
    /// @dev storage slot for totalAmounts mapping at Liquidity
    uint256 internal constant LIQUIDITY_TOTAL_AMOUNTS_MAPPING_SLOT = 7;
    /// @dev storage slot for user supply double mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_SUPPLY_DOUBLE_MAPPING_SLOT = 8;
    /// @dev storage slot for user borrow double mapping at Liquidity
    uint256 internal constant LIQUIDITY_USER_BORROW_DOUBLE_MAPPING_SLOT = 9;
    /// @dev storage slot for listed tokens array at Liquidity
    uint256 internal constant LIQUIDITY_LISTED_TOKENS_ARRAY_SLOT = 10;
    /// @dev storage slot for listed tokens array at Liquidity
    uint256 internal constant LIQUIDITY_CONFIGS2_MAPPING_SLOT = 11;

    // --------------------------------
    // @dev stacked uint256 storage slots bits position data for each:

    // ExchangePricesAndConfig
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_RATE = 0;
    uint256 internal constant BITS_EXCHANGE_PRICES_FEE = 16;
    uint256 internal constant BITS_EXCHANGE_PRICES_UTILIZATION = 30;
    uint256 internal constant BITS_EXCHANGE_PRICES_UPDATE_THRESHOLD = 44;
    uint256 internal constant BITS_EXCHANGE_PRICES_LAST_TIMESTAMP = 58;
    uint256 internal constant BITS_EXCHANGE_PRICES_SUPPLY_EXCHANGE_PRICE = 91;
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_EXCHANGE_PRICE = 155;
    uint256 internal constant BITS_EXCHANGE_PRICES_SUPPLY_RATIO = 219;
    uint256 internal constant BITS_EXCHANGE_PRICES_BORROW_RATIO = 234;
    uint256 internal constant BITS_EXCHANGE_PRICES_USES_CONFIGS2 = 249;

    // RateData:
    uint256 internal constant BITS_RATE_DATA_VERSION = 0;
    // RateData: V1
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_ZERO = 4;
    uint256 internal constant BITS_RATE_DATA_V1_UTILIZATION_AT_KINK = 20;
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_KINK = 36;
    uint256 internal constant BITS_RATE_DATA_V1_RATE_AT_UTILIZATION_MAX = 52;
    // RateData: V2
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_ZERO = 4;
    uint256 internal constant BITS_RATE_DATA_V2_UTILIZATION_AT_KINK1 = 20;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK1 = 36;
    uint256 internal constant BITS_RATE_DATA_V2_UTILIZATION_AT_KINK2 = 52;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_KINK2 = 68;
    uint256 internal constant BITS_RATE_DATA_V2_RATE_AT_UTILIZATION_MAX = 84;

    // TotalAmounts
    uint256 internal constant BITS_TOTAL_AMOUNTS_SUPPLY_WITH_INTEREST = 0;
    uint256 internal constant BITS_TOTAL_AMOUNTS_SUPPLY_INTEREST_FREE = 64;
    uint256 internal constant BITS_TOTAL_AMOUNTS_BORROW_WITH_INTEREST = 128;
    uint256 internal constant BITS_TOTAL_AMOUNTS_BORROW_INTEREST_FREE = 192;

    // UserSupplyData
    uint256 internal constant BITS_USER_SUPPLY_MODE = 0;
    uint256 internal constant BITS_USER_SUPPLY_AMOUNT = 1;
    uint256 internal constant BITS_USER_SUPPLY_PREVIOUS_WITHDRAWAL_LIMIT = 65;
    uint256 internal constant BITS_USER_SUPPLY_LAST_UPDATE_TIMESTAMP = 129;
    uint256 internal constant BITS_USER_SUPPLY_EXPAND_PERCENT = 162;
    uint256 internal constant BITS_USER_SUPPLY_EXPAND_DURATION = 176;
    uint256 internal constant BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT = 200;
    uint256 internal constant BITS_USER_SUPPLY_IS_PAUSED = 255;

    // UserBorrowData
    uint256 internal constant BITS_USER_BORROW_MODE = 0;
    uint256 internal constant BITS_USER_BORROW_AMOUNT = 1;
    uint256 internal constant BITS_USER_BORROW_PREVIOUS_BORROW_LIMIT = 65;
    uint256 internal constant BITS_USER_BORROW_LAST_UPDATE_TIMESTAMP = 129;
    uint256 internal constant BITS_USER_BORROW_EXPAND_PERCENT = 162;
    uint256 internal constant BITS_USER_BORROW_EXPAND_DURATION = 176;
    uint256 internal constant BITS_USER_BORROW_BASE_BORROW_LIMIT = 200;
    uint256 internal constant BITS_USER_BORROW_MAX_BORROW_LIMIT = 218;
    uint256 internal constant BITS_USER_BORROW_IS_PAUSED = 255;

    // Configs2
    uint256 internal constant BITS_CONFIGS2_MAX_UTILIZATION = 0;

    // --------------------------------

    /// @notice Calculating the slot ID for Liquidity contract for single mapping at `slot_` for `key_`
    function calculateMappingStorageSlot(uint256 slot_, address key_) internal pure returns (bytes32) {
        return keccak256(abi.encode(key_, slot_));
    }

    /// @notice Calculating the slot ID for Liquidity contract for double mapping at `slot_` for `key1_` and `key2_`
    function calculateDoubleMappingStorageSlot(
        uint256 slot_,
        address key1_,
        address key2_
    ) internal pure returns (bytes32) {
        bytes32 intermediateSlot_ = keccak256(abi.encode(key1_, slot_));
        return keccak256(abi.encode(key2_, intermediateSlot_));
    }
}

// ===== contracts/vault/common/tickmath.sol =====
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title library that calculates number "tick" and "ratioX96" from this: ratioX96 = (1.0015^tick) * 2^96
/// @notice this library is used in Fluid Vault protocol for optimiziation.
/// @dev "tick" supports between -32767 and 32767. "ratioX96" supports between 37075072 and 169307877264527972847801929085841449095838922544595
library TickMath {
    /// The minimum tick that can be passed in getRatioAtTick. 1.0015**-32767
    int24 internal constant MIN_TICK = -32767;
    /// The maximum tick that can be passed in getRatioAtTick. 1.0015**32767
    int24 internal constant MAX_TICK = 32767;

    uint256 internal constant FACTOR00 = 0x100000000000000000000000000000000;
    uint256 internal constant FACTOR01 = 0xff9dd7de423466c20352b1246ce4856f; // 2^128/1.0015**1 = 339772707859149738855091969477551883631
    uint256 internal constant FACTOR02 = 0xff3bd55f4488ad277531fa1c725a66d0; // 2^128/1.0015**2 = 339263812140938331358054887146831636176
    uint256 internal constant FACTOR03 = 0xfe78410fd6498b73cb96a6917f853259; // 2^128/1.0015**4 = 338248306163758188337119769319392490073
    uint256 internal constant FACTOR04 = 0xfcf2d9987c9be178ad5bfeffaa123273; // 2^128/1.0015**8 = 336226404141693512316971918999264834163
    uint256 internal constant FACTOR05 = 0xf9ef02c4529258b057769680fc6601b3; // 2^128/1.0015**16 = 332218786018727629051611634067491389875
    uint256 internal constant FACTOR06 = 0xf402d288133a85a17784a411f7aba082; // 2^128/1.0015**32 = 324346285652234375371948336458280706178
    uint256 internal constant FACTOR07 = 0xe895615b5beb6386553757b0352bda90; // 2^128/1.0015**64 = 309156521885964218294057947947195947664
    uint256 internal constant FACTOR08 = 0xd34f17a00ffa00a8309940a15930391a; // 2^128/1.0015**128 = 280877777739312896540849703637713172762
    uint256 internal constant FACTOR09 = 0xae6b7961714e20548d88ea5123f9a0ff; // 2^128/1.0015**256 = 231843708922198649176471782639349113087
    uint256 internal constant FACTOR10 = 0x76d6461f27082d74e0feed3b388c0ca1; // 2^128/1.0015**512 = 157961477267171621126394973980180876449
    uint256 internal constant FACTOR11 = 0x372a3bfe0745d8b6b19d985d9a8b85bb; // 2^128/1.0015**1024 = 73326833024599564193373530205717235131
    uint256 internal constant FACTOR12 = 0x0be32cbee48979763cf7247dd7bb539d; // 2^128/1.0015**2048 = 15801066890623697521348224657638773661
    uint256 internal constant FACTOR13 = 0x8d4f70c9ff4924dac37612d1e2921e; // 2^128/1.0015**4096 = 733725103481409245883800626999235102
    uint256 internal constant FACTOR14 = 0x4e009ae5519380809a02ca7aec77; // 2^128/1.0015**8192 = 1582075887005588088019997442108535
    uint256 internal constant FACTOR15 = 0x17c45e641b6e95dee056ff10; // 2^128/1.0015**16384 = 7355550435635883087458926352

    /// The minimum value that can be returned from getRatioAtTick. Equivalent to getRatioAtTick(MIN_TICK). ~ Equivalent to `(1 << 96) * (1.0015**-32767)`
    uint256 internal constant MIN_RATIOX96 = 37075072;
    /// The maximum value that can be returned from getRatioAtTick. Equivalent to getRatioAtTick(MAX_TICK).
    /// ~ Equivalent to `(1 << 96) * (1.0015**32767)`, rounding etc. leading to minor difference
    uint256 internal constant MAX_RATIOX96 =
        169307877264527972847801929085841449095838922544595;

    uint256 internal constant ZERO_TICK_SCALED_RATIO =
        0x1000000000000000000000000; // 1 << 96 // 79228162514264337593543950336
    uint256 internal constant _1E26 = 1e26;

    /// @notice ratioX96 = (1.0015^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return ratioX96 ratio = (debt amount/collateral amount)
    function getRatioAtTick(int tick) internal pure returns (uint256 ratioX96) {
        assembly {
            let absTick_ := sub(xor(tick, sar(255, tick)), sar(255, tick))

            if gt(absTick_, MAX_TICK) {
                revert(0, 0)
            }
            let factor_ := FACTOR00
            if and(absTick_, 0x1) {
                factor_ := FACTOR01
            }
            if and(absTick_, 0x2) {
                factor_ := shr(128, mul(factor_, FACTOR02))
            }
            if and(absTick_, 0x4) {
                factor_ := shr(128, mul(factor_, FACTOR03))
            }
            if and(absTick_, 0x8) {
                factor_ := shr(128, mul(factor_, FACTOR04))
            }
            if and(absTick_, 0x10) {
                factor_ := shr(128, mul(factor_, FACTOR05))
            }
            if and(absTick_, 0x20) {
                factor_ := shr(128, mul(factor_, FACTOR06))
            }
            if and(absTick_, 0x40) {
                factor_ := shr(128, mul(factor_, FACTOR07))
            }
            if and(absTick_, 0x80) {
                factor_ := shr(128, mul(factor_, FACTOR08))
            }
            if and(absTick_, 0x100) {
                factor_ := shr(128, mul(factor_, FACTOR09))
            }
            if and(absTick_, 0x200) {
                factor_ := shr(128, mul(factor_, FACTOR10))
            }
            if and(absTick_, 0x400) {
                factor_ := shr(128, mul(factor_, FACTOR11))
            }
            if and(absTick_, 0x800) {
                factor_ := shr(128, mul(factor_, FACTOR12))
            }
            if and(absTick_, 0x1000) {
                factor_ := shr(128, mul(factor_, FACTOR13))
            }
            if and(absTick_, 0x2000) {
                factor_ := shr(128, mul(factor_, FACTOR14))
            }
            if and(absTick_, 0x4000) {
                factor_ := shr(128, mul(factor_, FACTOR15))
            }

            let precision_ := 0
            if iszero(
                and(
                    tick,
                    0x8000000000000000000000000000000000000000000000000000000000000000
                )
            ) {
                factor_ := div(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                    factor_
                )
                // we round up in the division so getTickAtRatio of the output price is always consistent
                if mod(factor_, 0x100000000) {
                    precision_ := 1
                }
            }
            ratioX96 := add(shr(32, factor_), precision_)
        }
    }

    /// @notice ratioX96 = (1.0015^tick) * 2^96
    /// @dev Throws if ratioX96 > max ratio || ratioX96 < min ratio
    /// @param ratioX96 The input ratio; ratio = (debt amount/collateral amount)
    /// @return tick The output tick for the above formula. Returns in round down form. if tick is 123.23 then 123, if tick is -123.23 then returns -124
    /// @return perfectRatioX96 perfect ratio for the above tick
    function getTickAtRatio(
        uint256 ratioX96
    ) internal pure returns (int tick, uint perfectRatioX96) {
        assembly {
            if or(gt(ratioX96, MAX_RATIOX96), lt(ratioX96, MIN_RATIOX96)) {
                revert(0, 0)
            }

            let cond := lt(ratioX96, ZERO_TICK_SCALED_RATIO)
            let factor_

            if iszero(cond) {
                // if ratioX96 >= ZERO_TICK_SCALED_RATIO
                factor_ := div(mul(ratioX96, _1E26), ZERO_TICK_SCALED_RATIO)
            }
            if cond {
                // ratioX96 < ZERO_TICK_SCALED_RATIO
                factor_ := div(mul(ZERO_TICK_SCALED_RATIO, _1E26), ratioX96)
            }

            // put in https://www.wolframalpha.com/ whole equation: (1.0015^tick) * 2^96 * 10^26 / 79228162514264337593543950336

            // for tick = 16384
            // ratioX96 = (1.0015^16384) * 2^96 = 3665252098134783297721995888537077351735
            // 3665252098134783297721995888537077351735 * 10^26 / 79228162514264337593543950336 =
            // 4626198540796508716348404308345255985.06131964639489434655721
            if iszero(lt(factor_, 4626198540796508716348404308345255985)) {
                tick := or(tick, 0x4000)
                factor_ := div(
                    mul(factor_, _1E26),
                    4626198540796508716348404308345255985
                )
            }
            // for tick = 8192
            // ratioX96 = (1.0015^8192) * 2^96 = 17040868196391020479062776466509865
            // 17040868196391020479062776466509865 * 10^26 / 79228162514264337593543950336 =
            // 21508599537851153911767490449162.3037648642153898377655505172
            if iszero(lt(factor_, 21508599537851153911767490449162)) {
                tick := or(tick, 0x2000)
                factor_ := div(
                    mul(factor_, _1E26),
                    21508599537851153911767490449162
                )
            }
            // for tick = 4096
            // ratioX96 = (1.0015^4096) * 2^96 = 36743933851015821532611831851150
            // 36743933851015821532611831851150 * 10^26 / 79228162514264337593543950336 =
            // 46377364670549310883002866648.9777607649742626173648716941385
            if iszero(lt(factor_, 46377364670549310883002866649)) {
                tick := or(tick, 0x1000)
                factor_ := div(
                    mul(factor_, _1E26),
                    46377364670549310883002866649
                )
            }
            // for tick = 2048
            // ratioX96 = (1.0015^2048) * 2^96 = 1706210527034005899209104452335
            // 1706210527034005899209104452335 * 10^26 / 79228162514264337593543950336 =
            // 2153540449365864845468344760.06357108484096046743300420319322
            if iszero(lt(factor_, 2153540449365864845468344760)) {
                tick := or(tick, 0x800)
                factor_ := div(
                    mul(factor_, _1E26),
                    2153540449365864845468344760
                )
            }
            // for tick = 1024
            // ratioX96 = (1.0015^1024) * 2^96 = 367668226692760093024536487236
            // 367668226692760093024536487236 * 10^26 / 79228162514264337593543950336 =
            // 464062544207767844008185024.950588990554136265212906454481127
            if iszero(lt(factor_, 464062544207767844008185025)) {
                tick := or(tick, 0x400)
                factor_ := div(mul(factor_, _1E26), 464062544207767844008185025)
            }
            // for tick = 512
            // ratioX96 = (1.0015^512) * 2^96 = 170674186729409605620119663668
            // 170674186729409605620119663668 * 10^26 / 79228162514264337593543950336 =
            // 215421109505955298802281577.031879604792139232258508172947569
            if iszero(lt(factor_, 215421109505955298802281577)) {
                tick := or(tick, 0x200)
                factor_ := div(mul(factor_, _1E26), 215421109505955298802281577)
            }
            // for tick = 256
            // ratioX96 = (1.0015^256) * 2^96 = 116285004205991934861656513301
            // 116285004205991934861656513301 * 10^26 / 79228162514264337593543950336 =
            // 146772309890508740607270614.667650899656438875541505058062410
            if iszero(lt(factor_, 146772309890508740607270615)) {
                tick := or(tick, 0x100)
                factor_ := div(mul(factor_, _1E26), 146772309890508740607270615)
            }
            // for tick = 128
            // ratioX96 = (1.0015^128) * 2^96 = 95984619659632141743747099590
            // 95984619659632141743747099590 * 10^26 / 79228162514264337593543950336 =
            // 121149622323187099817270416.157248837742741760456796835775887
            if iszero(lt(factor_, 121149622323187099817270416)) {
                tick := or(tick, 0x80)
                factor_ := div(mul(factor_, _1E26), 121149622323187099817270416)
            }
            // for tick = 64
            // ratioX96 = (1.0015^64) * 2^96 = 87204845308406958006717891124
            // 87204845308406958006717891124 * 10^26 / 79228162514264337593543950336 =
            // 110067989135437147685980801.568068573422377364214113968609839
            if iszero(lt(factor_, 110067989135437147685980801)) {
                tick := or(tick, 0x40)
                factor_ := div(mul(factor_, _1E26), 110067989135437147685980801)
            }
            // for tick = 32
            // ratioX96 = (1.0015^32) * 2^96 = 83120873769022354029916374475
            // 83120873769022354029916374475 * 10^26 / 79228162514264337593543950336 =
            // 104913292358707887270979599.831816586773651266562785765558183
            if iszero(lt(factor_, 104913292358707887270979600)) {
                tick := or(tick, 0x20)
                factor_ := div(mul(factor_, _1E26), 104913292358707887270979600)
            }
            // for tick = 16
            // ratioX96 = (1.0015^16) * 2^96 = 81151180492336368327184716176
            // 81151180492336368327184716176 * 10^26 / 79228162514264337593543950336 =
            // 102427189924701091191840927.762844039579442328381455567932128
            if iszero(lt(factor_, 102427189924701091191840928)) {
                tick := or(tick, 0x10)
                factor_ := div(mul(factor_, _1E26), 102427189924701091191840928)
            }
            // for tick = 8
            // ratioX96 = (1.0015^8) * 2^96 = 80183906840906820640659903620
            // 80183906840906820640659903620 * 10^26 / 79228162514264337593543950336 =
            // 101206318935480056907421312.890625
            if iszero(lt(factor_, 101206318935480056907421313)) {
                tick := or(tick, 0x8)
                factor_ := div(mul(factor_, _1E26), 101206318935480056907421313)
            }
            // for tick = 4
            // ratioX96 = (1.0015^4) * 2^96 = 79704602139525152702959747603
            // 79704602139525152702959747603 * 10^26 / 79228162514264337593543950336 =
            // 100601351350506250000000000
            if iszero(lt(factor_, 100601351350506250000000000)) {
                tick := or(tick, 0x4)
                factor_ := div(mul(factor_, _1E26), 100601351350506250000000000)
            }
            // for tick = 2
            // ratioX96 = (1.0015^2) * 2^96 = 79466025265172787701084167660
            // 79466025265172787701084167660 * 10^26 / 79228162514264337593543950336 =
            // 100300225000000000000000000
            if iszero(lt(factor_, 100300225000000000000000000)) {
                tick := or(tick, 0x2)
                factor_ := div(mul(factor_, _1E26), 100300225000000000000000000)
            }
            // for tick = 1
            // ratioX96 = (1.0015^1) * 2^96 = 79347004758035734099934266261
            // 79347004758035734099934266261 * 10^26 / 79228162514264337593543950336 =
            // 100150000000000000000000000
            if iszero(lt(factor_, 100150000000000000000000000)) {
                tick := or(tick, 0x1)
                factor_ := div(mul(factor_, _1E26), 100150000000000000000000000)
            }
            if iszero(cond) {
                // if ratioX96 >= ZERO_TICK_SCALED_RATIO
                perfectRatioX96 := div(mul(ratioX96, _1E26), factor_)
            }
            if cond {
                // ratioX96 < ZERO_TICK_SCALED_RATIO
                tick := not(tick)
                perfectRatioX96 := div(
                    mul(ratioX96, factor_),
                    100150000000000000000000000
                )
            }
        }
    }
}

// ===== contracts/vault/common/variables.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces.sol";
import "../../infiniteProxy/IProxy.sol";

/// @title      Variables
/// @notice     Contains common storage variables of all modules of Infinite proxy.
contract ConstantVariables {
    address internal constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant RAY_MINUS_ONE = RAY - 1;
    uint256 internal constant MAX_UINT256_MINUS_RAY_MINUS_ONE =
        MAX_UINT256 - RAY_MINUS_ONE;

    IInstaIndex internal constant INSTA_INDEX_CONTRACT =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDRESS);
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDRESS);
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;
    address internal constant SP_WSTETH_ADDRESS_SPARK =
        0x12B54025C112Aa61fAce2CDB7118740875A566E9;
    address internal constant A_WSTETH_ADDRESS_AAVEV3_LIDO =
        0xC035a7cf15375cE2706766804551791aD035E0C2;

    /***********************************|
    |           EETH ADDRESSES        |
    |__________________________________*/
    address internal constant EETH_ADDRESS =
        0x35fA164735182de50811E8e2E824cFb9B6118ac2;

    /***********************************|
    |           WeETH ADDRESSES        |
    |__________________________________*/
    address internal constant WEETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    IWeEth internal constant WEETH_CONTRACT = IWeEth(WEETH_ADDRESS);
    address internal constant A_WEETH_ADDRESS_AAVEV3 =
        0xBdfa7b7893081B35Fb54027489e2Bc7A38275129;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant D_WETH_ADDRESS_SPARK =
        0x2e7576042566f8D6990e07A1B61Ad1efd86Ae70d;
    address internal constant D_WETH_ADDRESS_AAVEV3_LIDO =
        0x91b7d78BF92db564221f6B5AeE744D1727d1Dd1e;

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    address internal constant KING_ADDRESS =
        0x8F08B70456eb22f6109F57b8fafE862ED28E6040;

    ILiteVaultV1 internal constant LITE_VAULT_V1 = ILiteVaultV1(IETH_TOKEN_V1);

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    ILidoWithdrawalQueue internal constant LIDO_WITHDRAWAL_QUEUE =
        ILidoWithdrawalQueue(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

    ILiquidity internal constant LIQUIDITY =
        ILiquidity(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);

    IFluidVaultT1 internal constant FLUID_VAULT =
        IFluidVaultT1(FLUID_VAULT_ADDRESS);

    IFluidVaultT1 internal constant FLUID_VAULT_NEW =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_NEW);

    IFluidVaultT1 internal constant FLUID_VAULT_WEETH_WSTETH =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_WEETH_WSTETH);

    address internal constant FLUID_VAULT_ADDRESS =
        0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91;

    address internal constant FLUID_VAULT_ADDRESS_NEW =
        0x82B27fA821419F5689381b565a8B0786aA2548De;

    address internal constant FLUID_VAULT_ADDRESS_WEETH_WSTETH =
        0xeAEf563015634a9d0EE6CF1357A3b205C35e028D;

    uint256 internal constant FLUID_NFT_ID_NEW = 1566;

    uint256 internal constant FLUID_NFT_WEETH_WSTETH = 6486;

    address internal constant FLUID_DEX_ADDRESS =
        address(0x0B1a513ee24972DAEf112bC777a5610d4325C9e7);

    IFluidDexT1 internal constant FLUID_DEX = IFluidDexT1(FLUID_DEX_ADDRESS);

    address internal constant FLUID_DEX_VAULT_ADDRESS =
        0x528CF7DBBff878e02e48E83De5097F8071af768D;

    IFluidVaultT4 internal constant FLUID_VAULT_T4 =
        IFluidVaultT4(FLUID_DEX_VAULT_ADDRESS);

    uint256 internal constant X8 = 0xff;

    uint256 internal constant X19 = 0x7ffff;

    uint256 internal constant X64 = 0xffffffffffffffff;

    uint256 internal constant X128 = 0xffffffffffffffffffffffffffffffff;
}

contract Variables is ConstantVariables {
    /****************************************************************************|
    |   @notice Ids associated with protocols at the time of deployment.         |
    |   New protocols might have been added or removed at the time of viewing.   |
    |                          AAVE_V2 => 1 // Disabled                          |
    |                          AAVE_V3 => 2                                      |
    |                          COMPOUND_V3 => 3                                  |
    |                          EULER => 4 // Disabled                            |
    |                          MORPHO_AAVE_V2 => 5 // Disabled                   |
    |                          MORPHO_AAVE_V3 => 6 // Disabled                   |
    |                          SPARK => 7                                        |
    |                          FLUID => 8 // Disabled                            |
    |                          FLUID_NEW => 9                                    |
    |                          AAVE V3 LIDO => 10                                |
    |                          FLUID_DEX => 11                                   |
    |                          FLUID_WEETH_WSTETH => 12                          |
    |___________________________________________________________________________*/

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    // 1: open; 2: closed
    uint8 internal _status;

    IDSA public vaultDSA;

    /// @notice Max limit (in wei) allowed for wsteth per eth unit amount.
    uint256 public leverageMaxUnitAmountLimit;

    /// @notice Secondary auth that only has the power to reduce max risk ratio.
    address public secondaryAuth;

    // Current exchange price.
    uint256 public exchangePrice;

    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public revenueExchangePrice;

    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;

    // Mapping of protocol id => max risk ratio, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    // 1 = Aave v2 // Disabled
    // 2 = Aave v3
    // 3 = Compound v3 (ETH market)
    // 4 = Euler // Disabled
    // 5 = Morpho Aave v2 // Disabled
    // 6 = Morpho Aave v3 // Disabled
    // 7 = Spark
    // 8 = Fluid // Disabled
    // 9 = Fluid New
    // 10 = Aave V3 Lido
    // 11 = Fluid Dex
    // 12 = Fluid WeETH WstETH
    mapping(uint8 => uint256) public maxRiskRatio;

    // Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    uint256 public aggrMaxVaultRatio;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    uint256 public withdrawalFeePercentage;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    uint256 public withdrawFeeAbsoluteMin; // in underlying base asset, i.e. stEth

    // charge from the profits, scaled to factor 4.
    // 100,000 would be 10% cut from profit
    uint256 public revenueFeePercentage;

    /// @notice Stores profit revenue and withdrawal fees collected.
    uint256 public revenue;

    /// @notice Revenue will be transffered to this address upon collection.
    address public treasury;

    /// @notice Tracker for amount of stETH queued for withdrawal.
    uint256 public queuedWithdrawStEth;

    /// @notice DSA's NFT ID for fluid vault T4.
    uint256 public fluidDexNFT;

    /// @notice allocation to team multisig - in wstETH
    uint256 public allocationToTeamMultisig;

    /// @notice max allocation to team multisig - in wstETH (for future use)
    uint256 public maxAllocationToTeamMultisig;

}

/// @title      PrimaryHelpers
/// @notice     Contains common modifiers of all modules of Infinite proxy.
contract PrimaryHelpers is Variables {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();
    error Helpers__ProtocolDisabled();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyRebalancer() {
        if (
            !(isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert Helpers__NotRebalancer();
        }
        _;
    }

    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        if (_status == 2) revert Helpers__Reentrant();
        _status = 2;
        _;
        _status = 1;
    }

    /// @notice Implements a method to read uint256 data from storage at a bytes32 storage slot key.
    function readFromStorage(
        bytes32 slot_
    ) public view returns (uint256 result_) {
        assembly {
            result_ := sload(slot_) // read value from the storage slot
        }
    }
}

// ===== contracts/vault/common/variablesBuffer.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBuffer
/// @notice     Allocates space of 151 slots to maintain storage 
///             consistency with imported variables in VariablesPrimaryHelper.

contract VariablesBuffer {
    uint[151] internal __buffergap;
}
// ===== contracts/vault/common/variablesBufferHelper.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBufferHelper
/// @notice     Buffer Helper for variables that imports all the primary 
///             helpers from the storage slot 152.

import {VariablesBuffer} from "./variablesBuffer.sol";
import {PrimaryHelpers} from "./variables.sol";

// Buffer & variables
contract VariablesBufferHelper is VariablesBuffer, PrimaryHelpers {
}
// ===== contracts/vault/modules/viewModule/main.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../common/helpers.sol";

contract ViewModule is Helpers {
}
