// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SatoHook} from "../src/SatoHook.sol";
import {SatoToken} from "../src/SatoToken.sol";
import {Curve} from "../src/lib/Curve.sol";

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";

/// @notice Thin external wrapper so the internal Curve library can be called from the test.
contract CurveHarness {
    function ethAt(uint256 total) external pure returns (uint256) {
        return Curve.ethAt(total);
    }

    function burnFor(uint256 currentTotal, uint256 satoIn) external pure returns (uint256) {
        return Curve.burnFor(currentTotal, satoIn);
    }

    function totalMinted(uint256 eth) external pure returns (uint256) {
        return Curve.totalMinted(eth);
    }

    function mintFor(uint256 ethBefore, uint256 eth) external pure returns (uint256) {
        return Curve.mintFor(ethBefore, eth);
    }
}

/// @title SatoHook live-state gate verification (fork only; no transaction is broadcast)
/// @notice Proves the two load-bearing facts behind the LOW verdict:
///         1. A sell can never pay more than Curve.ethAt(totalMintedFair), because
///            satoFairIn = satoIn * totalMintedFair / totalSupply is capped at totalMintedFair
///            and burnFor(T, T) == ethAt(T). At the pinned block that is 443.776 ETH gross,
///            442.445 ETH net of the 0.3% fee - not the 1,011.02 ETH balance.
///         2. The hookData-supplied `swapper` is unauthenticated: it can be poisoned for any
///            address (blocking that address's sell for one block) and bypassed by using a
///            different address on the sell leg.
contract SatoGateTest is Test {
    address payable constant HOOK = payable(0x0000f07d2B5F1Ddf3244b8780F972f306EFd2888);
    address constant PM = 0x000000000004444c5dc75cB358380D2e3dE08A90;
    address constant SATO = 0x829f4B62EEBE12Af653b4dD4fFc480966F7d7f09;

    // Pinned live block used for every read/call below.
    uint256 constant FORK_BLOCK = 26_334_425;

    // Live values at FORK_BLOCK (cross-checked with cast call in analysis/).
    uint256 constant T_LIVE = 12_355_100_230_207_324_979_556_616; // totalMintedFair
    uint256 constant BAL_LIVE = 1_011_022_719_561_378_179_640; // hook balance
    uint256 constant FEES_LIVE = 101_090_288_603_355_685_539; // feesAccrued

    PoolKey key;
    CurveHarness curve;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://eth.drpc.org")), FORK_BLOCK);
        key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(SATO),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });
        curve = new CurveHarness();
    }

    // ------------------------------------------------------------------ helpers

    function _mockPoolManager() internal {
        vm.mockCall(PM, abi.encodeWithSelector(IPoolManager.take.selector), abi.encode(uint256(0)));
        vm.mockCall(PM, abi.encodeWithSelector(IPoolManager.settle.selector), abi.encode(uint256(0)));
        vm.mockCall(PM, abi.encodeWithSelector(IPoolManager.sync.selector), abi.encode(uint256(0)));
    }

    function _setSatoBalance(address who, uint256 amount) internal {
        // OZ ERC20: _balances is storage slot 0, _totalSupply is slot 2.
        vm.store(SATO, keccak256(abi.encode(who, uint256(0))), bytes32(amount));
    }

    function _sell(uint256 satoIn, address swapper) internal returns (int128 specified, int128 unspecified) {
        vm.prank(PM);
        (, BeforeSwapDelta delta,) = SatoHook(HOOK).beforeSwap(
            address(this),
            key,
            SwapParams({zeroForOne: false, amountSpecified: -int256(satoIn), sqrtPriceLimitX96: 0}),
            abi.encode(swapper)
        );
        specified = BeforeSwapDeltaLibrary.getSpecifiedDelta(delta);
        unspecified = BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta);
    }

    function _buy(uint256 ethIn, address swapper) internal returns (int128 specified, int128 unspecified) {
        vm.prank(PM);
        (, BeforeSwapDelta delta,) = SatoHook(HOOK).beforeSwap(
            address(this),
            key,
            SwapParams({zeroForOne: true, amountSpecified: -int256(ethIn), sqrtPriceLimitX96: 0}),
            abi.encode(swapper)
        );
        specified = BeforeSwapDeltaLibrary.getSpecifiedDelta(delta);
        unspecified = BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta);
    }

    // ------------------------------------------------------------------ pure gate math

    function test_gate_math_burnForFullSupplyEqualsEthAt() public view {
        uint256 gross = curve.burnFor(T_LIVE, T_LIVE);
        uint256 net = (gross * 997) / 1000;
        console2.log("ethAt(totalMintedFair) gross ETH", gross);
        console2.log("0.3%-net ETH", net);
        assertEq(gross, curve.ethAt(T_LIVE), "burnFor(T,T) != ethAt(T)");
        assertApproxEqAbs(gross, 443.776 ether, 0.001 ether, "gross != 443.776 ETH");
        assertApproxEqAbs(net, 442.445 ether, 0.001 ether, "net != 442.445 ETH");
        // The 466.156 ETH phantom reserve is exactly ethCum - ethAt(T).
        assertApproxEqAbs(BAL_LIVE - FEES_LIVE - gross, 466.156 ether, 0.01 ether, "offset != 466.156");
    }

    // ------------------------------------------------------------------ live gate

    function test_fork_fullSupplySellPaysOnly443Not1011() public {
        uint256 supply = SatoToken(SATO).totalSupply();
        _setSatoBalance(HOOK, supply);
        _mockPoolManager();

        uint256 balBefore = HOOK.balance;
        (int128 specified, int128 unspecified) = _sell(supply, address(this));
        uint256 ethOut = uint256(uint128(-unspecified));

        console2.log("sell satoIn", supply);
        console2.log("hook balance ETH", balBefore);
        console2.log("ethOut ETH", ethOut);

        assertEq(uint256(uint128(specified)), supply, "specified delta != satoIn");
        assertApproxEqAbs(ethOut, 442.445 ether, 0.01 ether, "max payout != 442.445 ETH");
        assertLt(ethOut, balBefore, "payout must be below balance");
        assertApproxEqAbs(balBefore - ethOut, 568.578 ether, 0.02 ether, "residual stuck != 568.58 ETH");
    }

    function test_fork_sellTwiceSupplyStillPaysOnly443() public {
        uint256 supply = SatoToken(SATO).totalSupply();
        uint256 doubled = supply * 2;
        vm.store(SATO, bytes32(uint256(2)), bytes32(doubled)); // totalSupply = 2x
        _setSatoBalance(HOOK, doubled);
        _mockPoolManager();

        (int128 specified, int128 unspecified) = _sell(doubled, address(this));
        uint256 ethOut = uint256(uint128(-unspecified));

        console2.log("sell satoIn (2x supply)", doubled);
        console2.log("ethOut ETH", ethOut);

        assertEq(uint256(uint128(specified)), doubled, "specified delta != satoIn");
        // satoFairIn is capped at totalMintedFair; the payout cannot exceed ethAt(T).
        assertApproxEqAbs(ethOut, 442.445 ether, 0.01 ether, "2x sell must still cap at ethAt(T)");
    }

    function test_fork_buyThenSellIsAlwaysALoss() public {
        _mockPoolManager();
        uint256 ethIn = 5 ether; // MAX_BUY_WEI
        (int128 buySpecified, int128 buyUnspecified) = _buy(ethIn, address(this));
        uint256 minted = uint256(uint128(-buyUnspecified));

        console2.log("buy ethIn", ethIn);
        console2.log("minted SATO", minted);
        assertEq(uint256(uint128(buySpecified)), ethIn, "buy specified delta != ethIn");

        // Give the hook the minted tokens so the sell leg can burn them.
        _setSatoBalance(HOOK, minted);
        // Respect the honest cooldown (the bypass is demonstrated separately).
        vm.roll(block.number + 1);
        (, int128 sellUnspecified) = _sell(minted, address(this));
        uint256 ethOut = uint256(uint128(-sellUnspecified));

        console2.log("sell proceeds ETH", ethOut);
        assertLt(ethOut, ethIn, "round trip must lose ETH");
        // The loss is large because buys price at ethCum (909.93 ETH) while sells price at
        // ethAt(totalMintedFair) (443.78 ETH); the offset is 466.16 ETH.
        assertLt(ethOut, ethIn * 45 / 100, "expected >55% loss");
    }

    // ------------------------------------------------------------------ cooldown control

    function test_fork_cooldownPoisonAndBypass() public {
        address victim = address(0xBEEF);
        address other = address(0xCAFE);
        _mockPoolManager();

        // A 1-wei buy by anyone can write lastBuyBlock[victim] for the current block.
        _buy(1, victim);
        assertEq(SatoHook(HOOK).lastBuyBlock(victim), block.number, "victim not poisoned");

        // The poisoned victim's sell in the same block reverts.
        _setSatoBalance(HOOK, 1 ether);
        vm.expectRevert(SatoHook.CooldownActive.selector);
        _sell(1 ether, victim);

        // The same sell succeeds when a different swapper is supplied in hookData.
        (int128 specified,) = _sell(1 ether, other);
        assertEq(uint256(uint128(specified)), 1 ether, "bypass sell did not execute");
    }

    function test_fork_noOwnerWithdrawPath() public {
        (bool ok,) = HOOK.call(abi.encodeWithSignature("owner()"));
        assertFalse(ok, "owner() must not exist");
        (ok,) = HOOK.call(abi.encodeWithSignature("withdraw()"));
        assertFalse(ok, "withdraw() must not exist");
        (ok,) = HOOK.call(abi.encodeWithSignature("sweep()"));
        assertFalse(ok, "sweep() must not exist");
        (ok,) = HOOK.call(abi.encodeWithSignature("rescue(address,uint256)"));
        assertFalse(ok, "rescue() must not exist");
    }
}
