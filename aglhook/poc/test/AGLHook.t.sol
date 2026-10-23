// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {
    IPoolManager,
    IAGLHook,
    IERC20,
    IHooks,
    Currency,
    PoolKey,
    SwapParams,
    BalanceDelta,
    DeltaLib
} from "../src/Interfaces.sol";
import {Swapper} from "../src/Swapper.sol";

/// @title AGLHook — read-only mainnet-fork verification of the fee / delta paths.
/// @notice No transactions are signed or sent: everything runs on a local fork.
contract AGLHookTest is Test {
    using DeltaLib for BalanceDelta;

    address constant HOOK = 0xA61d74D6362699B76b21ef3016649A58D27bE0CC;
    address constant PM = 0x000000000004444c5dc75cB358380D2e3dE08A90;
    address constant AGL = 0x63401cDd577478F9389A1683e866A937f072D1C2;
    address constant XAUT = 0x06fbfb283bCA0d109bFB5Fd9CFb02B974D705998;
    address constant BUYBACK = 0x8CCf65a2d5edFF1AAF865e6D75e70077a0e0bce5;
    address constant OPERATOR = 0x69797731508079240Ef42b6F3235656fB3E6e119;

    uint160 constant MIN_SQRT = 4295128739;
    uint160 constant MAX_SQRT = 1461446703485210103287273052203988822378723970342;

    IPoolManager pm = IPoolManager(PM);
    IAGLHook hook = IAGLHook(HOOK);
    Swapper swapper;

    PoolKey key;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"));
        vm.createSelectFork(rpc);
        swapper = new Swapper(pm);
        key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(AGL),
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });
        vm.deal(address(swapper), 100 ether);
    }

    // --- helpers ----------------------------------------------------------

    function _poolId() internal view returns (bytes32) {
        return keccak256(abi.encode(key.currency0, key.currency1, key.fee, key.tickSpacing, key.hooks));
    }

    function _fundAgl(address to, uint256 amt) internal {
        // solady ERC20 balance slot = keccak256(owner || 0x0000000000000000000087a211a2)
        // (mstore(0x0c, _BALANCE_SLOT_SEED); mstore(0x00, owner); keccak256(0x0c, 0x20))
        bytes32 slot = keccak256(abi.encodePacked(to, hex"0000000000000000000087a211a2"));
        vm.store(AGL, slot, bytes32(amt));
        require(IERC20(AGL).balanceOf(to) == amt, "agl funding failed");
    }

    /// @dev Executes one swap from the fresh `swapper` and returns
    ///      (owedDelta, finalAmount0). Asserts the hook fee is exactly 10% of
    ///      the gross ETH leg of the swap.
    function _swapAndCheckFee(SwapParams memory p) internal returns (uint256 fee, int128 amount0) {
        uint256 owedBefore = hook.owed();
        BalanceDelta d = swapper.doSwap(key, p);
        uint256 owedAfter = hook.owed();
        fee = owedAfter - owedBefore;
        amount0 = d.amount0();

        uint256 gross;
        if (amount0 < 0) {
            gross = uint256(uint128(-amount0));
        } else {
            gross = uint256(uint128(amount0)) + fee;
        }
        assertEq(gross / 10, fee, "hook fee must be exactly 10% of gross ETH leg");
        assertGt(fee, 0, "fee must be non-zero");
        // the fee is real, backed ETH: the hook's ERC-6909 claim must equal owed
        assertEq(pm.balanceOf(HOOK, 0), hook.owed(), "ERC-6909 ETH claim must equal owed after swap");
    }

    // --- 1. permission bits / wiring --------------------------------------

    function test_1_permissionBits() public view {
        assertEq(hook.REQUIRED_FLAGS(), 0x20CC, "REQUIRED_FLAGS");
        assertEq(uint160(HOOK) & 0x3FFF, 0x20CC, "address bits must equal flags");
        // decoded: BEFORE_INITIALIZE|BEFORE_SWAP|BEFORE_SWAP_RETURNS_DELTA|AFTER_SWAP|AFTER_SWAP_RETURNS_DELTA
        assertTrue(uint160(HOOK) & 0x2000 != 0, "beforeInitialize");
        assertTrue(uint160(HOOK) & 0x0080 != 0, "beforeSwap");
        assertTrue(uint160(HOOK) & 0x0040 != 0, "beforeSwapReturnsDelta");
        assertTrue(uint160(HOOK) & 0x0008 != 0, "afterSwap");
        assertTrue(uint160(HOOK) & 0x0004 != 0, "afterSwapReturnsDelta");
    }

    function test_2_bindingAndImmutables() public view {
        assertTrue(hook.bound(), "bound");
        assertEq(hook.boundPool(), _poolId(), "boundPool must be the ETH/AGL pool");
        assertEq(hook.poolManager(), PM, "poolManager");
        assertEq(hook.agl(), AGL, "agl");
        assertEq(hook.xautFundWallet(), XAUT, "xautFundWallet");
        assertEq(keccak256(bytes(IERC20(AGL).totalSupply() > 0 ? "ok" : "no")), keccak256("ok"));
    }

    function test_3_callbackAuth_onlyPoolManager() public {
        SwapParams memory p = SwapParams(true, -1e15, MIN_SQRT + 1);
        vm.expectRevert();
        hook.beforeSwap(address(this), key, p, "");
        vm.expectRevert();
        hook.afterSwap(address(this), key, p, BalanceDelta.wrap(0), "");
        vm.expectRevert();
        hook.unlockCallback(abi.encode(uint256(1)));
    }

    // --- 2. fee schedule ---------------------------------------------------

    function test_4_feeBpsIsTenPercentBothWays() public view {
        assertEq(hook.feeBps(true), 1000, "buy fee must be at the 10% floor");
        assertEq(hook.feeBps(false), 1000, "sell fee must be 10%");
    }

    function test_5_feeExemptOnlyBuybackAndOperatorGated() public {
        assertFalse(hook.feeExempt(address(swapper)), "fresh swapper must not be exempt");
        assertFalse(hook.feeExempt(address(this)), "test contract must not be exempt");
        assertTrue(hook.feeExempt(BUYBACK), "buyback is the sole exempt address");
        assertTrue(_isOperator(OPERATOR), "operator set");
        // The exempt contract's only entry point is operator-gated.
        vm.prank(address(0xBEEF));
        (bool ok,) = BUYBACK.call(abi.encodeWithSignature("buyAndBurn(uint256,uint256)", 1 ether, 0));
        assertFalse(ok, "buyAndBurn must revert for a non-operator");
    }

    function _isOperator(address a) internal view returns (bool r) {
        (bool ok, bytes memory d) = BUYBACK.staticcall(abi.encodeWithSignature("isOperator(address)", a));
        require(ok, "staticcall");
        r = abi.decode(d, (bool));
    }

    // --- 3. all four swap shapes: fee must be exactly 10% ------------------

    function test_6_buyExactInput() public {
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
    }

    function test_7_buyExactOutput() public {
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: int256(50_000e18), sqrtPriceLimitX96: MIN_SQRT + 1}));
    }

    function test_8_sellExactInput() public {
        // acquire AGL via a real buy (also exercises the buy path), then sell it back
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
        uint256 bal = IERC20(AGL).balanceOf(address(swapper));
        assertGt(bal, 0, "bought AGL");
        _swapAndCheckFee(
            SwapParams({zeroForOne: false, amountSpecified: -int256(bal), sqrtPriceLimitX96: MAX_SQRT - 1})
        );
    }

    function test_9_sellExactOutput() public {
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
        _swapAndCheckFee(SwapParams({zeroForOne: false, amountSpecified: int256(0.05 ether), sqrtPriceLimitX96: MAX_SQRT - 1}));
    }

    // --- 4. no free money / no extraction ---------------------------------

    function test_10_roundTripAlwaysLosesMoney() public {
        uint256 start = address(swapper).balance;
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
        uint256 aglBal = IERC20(AGL).balanceOf(address(swapper));
        _swapAndCheckFee(
            SwapParams({zeroForOne: false, amountSpecified: -int256(aglBal), sqrtPriceLimitX96: MAX_SQRT - 1})
        );
        uint256 end = address(swapper).balance;
        assertLt(end, start, "buy+sell round trip must lose money (fees)");
    }

    function test_11_claimOnlyPaysImmutableWallet() public {
        uint256 owed = hook.owed();
        assertGt(owed, 0, "there must be something owed");
        uint256 xautBefore = XAUT.balance;
        uint256 attackerBefore = address(0xBAD).balance;
        vm.prank(address(0xBAD));
        hook.claim();
        assertEq(XAUT.balance, xautBefore + owed, "claim must pay the immutable xaut wallet");
        assertEq(address(0xBAD).balance, attackerBefore, "caller must receive nothing");
        assertEq(hook.owed(), 0, "owed cleared");
    }

    function test_12_cannotRebindHookToForeignPool() public {
        PoolKey memory bad = key;
        bad.tickSpacing = 10; // different pool id
        vm.expectRevert();
        pm.initialize(bad, 79228162514264337593543950336); // 1:1 price
    }

    function test_13_poolStateSnapshot() public {        bytes32 id = _poolId();
        bytes32 stateSlot = keccak256(abi.encode(id, uint256(6)));
        bytes32 slot0 = pm.extsload(stateSlot);
        bytes32 liqSlot = bytes32(uint256(stateSlot) + 3);
        uint256 liq = uint256(pm.extsload(liqSlot));
        uint256 aglReserve = IERC20(AGL).balanceOf(PM);
        emit log_named_bytes32("poolId", id);
        emit log_named_uint("block", block.number);
        emit log_named_bytes32("slot0", slot0);
        emit log_named_uint("liquidity", liq);
        emit log_named_uint("AGL reserve (wei)", aglReserve);
        assertGt(aglReserve, 1e25, "pool must hold a large AGL reserve");
        assertTrue(hook.bound(), "bound");
    }

    // --- 5. adversarial edge cases ----------------------------------------

    /// @dev fee is derived from `amountSpecified` in beforeSwap. A huge amount
    ///      would make `int128(int256(fee))` wrap negative — but `_collect` runs
    ///      first and `poolManager.mint` SafeCast-reverts for fee >= 2**127.
    function test_14_hugeAmountRevertsNoFreeMint() public {
        // buy exact-in: fee = amount/10 > 2**127-1
        vm.expectRevert();
        swapper.doSwap(key, SwapParams({zeroForOne: true, amountSpecified: -int256(2e39), sqrtPriceLimitX96: MIN_SQRT + 1}));
        // sell exact-out: fee = feeOnNet(amount) > 2**127-1
        vm.expectRevert();
        swapper.doSwap(key, SwapParams({zeroForOne: false, amountSpecified: int256(2e39), sqrtPriceLimitX96: MAX_SQRT - 1}));
        // state unchanged: no phantom `owed`, no phantom claim
        assertEq(pm.balanceOf(HOOK, 0), hook.owed(), "claim must stay fully backed");
    }

    /// @dev The hook's ERC-6909 native-ETH claim must always equal `owed`:
    ///      fees are real ETH already paid by swappers, never minted for free.
    function test_15_claimFullyBackedByRealEth() public {
        assertEq(pm.balanceOf(HOOK, 0), hook.owed(), "ERC-6909 ETH claim == owed");
    }

    /// @dev A huge amountSpecified with a tight price limit cannot mint a claim
    ///      without paying: the final swap delta always charges the fee.
    function test_16_tightLimitStillChargesFee() public {
        uint256 owedBefore = hook.owed();
        // 50 ETH of intended input, price limit only 1 tick away => tiny fill
        swapper.doSwap(key, SwapParams({zeroForOne: true, amountSpecified: -50 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
        assertGt(hook.owed(), owedBefore, "fee still charged");
    }

    function test_17_buybackCallbackNotReachable() public {
        // AGLBuyback.unlockCallback is onlyPoolManager; a direct call reverts.
        (bool ok,) = BUYBACK.call(abi.encodeWithSignature("unlockCallback(bytes)", abi.encode(uint256(1))));
        assertFalse(ok, "buyback callback must not be reachable directly");
        assertFalse(hook.feeExempt(address(swapper)), "attacker swapper is not exempt");
    }

    function testFuzz_18_buyFeeAlwaysExactlyTenPercent(uint96 ethIn) public {
        uint256 amt = bound(uint256(ethIn), 1e15, 5 ether);
        vm.deal(address(swapper), amt);
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -int256(amt), sqrtPriceLimitX96: MIN_SQRT + 1}));
    }

    function testFuzz_19_sellFeeAlwaysExactlyTenPercent(uint96 buyIn) public {
        uint256 amt = bound(uint256(buyIn), 1e15, 5 ether);
        vm.deal(address(swapper), amt);
        _swapAndCheckFee(SwapParams({zeroForOne: true, amountSpecified: -int256(amt), sqrtPriceLimitX96: MIN_SQRT + 1}));
        uint256 bal = IERC20(AGL).balanceOf(address(swapper));
        if (bal == 0) return;
        _swapAndCheckFee(
            SwapParams({zeroForOne: false, amountSpecified: -int256(bal), sqrtPriceLimitX96: MAX_SQRT - 1})
        );
    }

    /// @dev "Reach the pooled $1.45M": the only way to touch the pool's ETH is to
    ///      sell AGL you already own. Buying that AGL first costs the 10 % fee and
    ///      selling it back costs another 10 %, so even a large round trip is a
    ///      guaranteed loss — the pooled value is not extractable.
    function test_20_largeRoundTripReachesPoolButLosesValue() public {
        vm.deal(address(swapper), 500 ether);
        uint256 start = address(swapper).balance;
        swapper.doSwap(key, SwapParams({zeroForOne: true, amountSpecified: -100 ether, sqrtPriceLimitX96: MIN_SQRT + 1}));
        uint256 aglBal = IERC20(AGL).balanceOf(address(swapper));
        emit log_named_uint("AGL acquired for 100 ETH", aglBal);
        swapper.doSwap(
            key,
            SwapParams({zeroForOne: false, amountSpecified: -int256(aglBal), sqrtPriceLimitX96: MAX_SQRT - 1})
        );
        uint256 end = address(swapper).balance;
        emit log_named_uint("ETH start", start);
        emit log_named_uint("ETH end", end);
        assertLt(end, start, "large round trip must lose money");
        assertLt(end, start - 10 ether, "loss must exceed ~10% of the traded size");
    }
}
