// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
// NOTE: `import {ForkHelper} from "../src/ForkHelper.sol";` is the intended base, but the vendored
// ForkHelper.sol does NOT compile against forge-std 1.9.6 (it redeclares the inherited VM_ADDRESS
// constant -> Error 9097). See analysis/narausd/FORKHELPER-BLOCKER.md. Until the parent lands the
// 1-line fix, this file carries the byte-identical keyless-fork logic inline (H17TestBase.h17Fork).

abstract contract NaraUsdH17ForkBase is Test {
    address internal constant H17_VM = address(uint160(uint256(keccak256("hevm cheat code"))));

    function h17Fork(string memory envKey, string[] memory fallbacks) internal returns (string memory url) {
        string memory override_ = vm.envOr(envKey, string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = H17_VM.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return override_;
        }
        for (uint256 i = 0; i < fallbacks.length; i++) {
            if (bytes(fallbacks[i]).length == 0) continue;
            (bool ok,) = H17_VM.call(abi.encodeWithSignature("createSelectFork(string)", fallbacks[i]));
            if (ok) return fallbacks[i];
        }
        revert("NaraUsdH17ForkBase: no reachable RPC");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/// @dev USDT's approve() returns NO data (non-standard) — declaring `returns (bool)` breaks decoding.
interface IUSDTLike {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface IMCT {
    function getSupportedAssets() external view returns (address[] memory);
    function isSupportedAsset(address) external view returns (bool);
    function collateralBalance(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function mint(address, uint256, address) external returns (uint256);
    function redeem(address, uint256, address) external returns (uint256);
    function mintWithoutCollateral(address, uint256) external;
    function withdrawCollateral(address, uint256, address) external;
}

interface INaraUSD {
    function mintWithCollateral(address, uint256) external returns (uint256);
    function redeem(address, uint256, bool) external returns (uint256, bool);
    function mintWithoutCollateral(address, uint256) external;
    function cancelRedeem() external;
    function hasValidCredentials(address) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function paused() external view returns (bool);
    function previewRedeem(address, uint256) external view returns (uint256);
    function maxInstantRedeem(address, address) external view returns (uint256);
    function keyringAddress() external view returns (address);
    function keyringPolicyId() external view returns (uint256);
    function keyringWhitelist(address) external view returns (bool);
}

interface INaraUSDPlus {
    function deposit(uint256, address) external returns (uint256);
    function redeem(uint256, address, address) external returns (uint256);
    function cooldownShares(uint256) external returns (uint256);
    function unstake(address) external;
    function previewRedeem(uint256) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function cooldownDuration() external view returns (uint24);
}

interface IAccountant {
    function getRate() external view returns (uint256);
    function updateExchangeRate(uint96) external;
    function setRateProviderData(address, bool, address) external;
}

interface IBoringVault {
    function totalSupply() external view returns (uint256);
    function enter(address, address, uint256, address, uint256) external;
    function exit(address, address, uint256, address, uint256) external;
    function manage(address, bytes calldata, uint256) external returns (bytes memory);
}

interface ISilo {
    function withdraw(address, uint256) external;
}

/// @title Z3-H17 NaraUSD — adversarial fork suite (read-only mainnet fork)
/// @notice Proves the E-U negatives: keyring-gated + exact-par mint/redeem, role gates,
///         silo gates, rate path closed, no-profit even under a hypothetical keyring bypass.
contract NaraUsdH17Test is NaraUsdH17ForkBase {
    address constant MCT = 0x4eD90999f558Fdc28606b7F7f9AFc7044befb803;
    address constant NARAUSD = 0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7;
    address constant NARAUSD_PLUS = 0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6;
    address constant BV = 0x15e2579B1F0cBe973889a76826D3a2313b6509c6;
    address constant ACCOUNTANT = 0xda594876BA13BCC22065E03fFcFB24A22E5c6724;
    address constant SAFE = 0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F;
    address constant SILO1 = 0x69e0e02b31B5623c6db029b531d4D55837098326; // NaraUSDRedeemSilo
    address constant SILO2 = 0x12E4915C52E2d02e1c5477582577727E6fA35d13; // NaraUSDPlusSilo
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant KEYRING = 0xb0B5E2176E10B12d70e60E3a68738298A7DFe666;
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant ADMIN_ROLE = 0x00;

    IMCT mct = IMCT(MCT);
    INaraUSD nara = INaraUSD(NARAUSD);
    INaraUSDPlus plus = INaraUSDPlus(NARAUSD_PLUS);

    address attacker;

    function setUp() public {
        string[] memory fb = new string[](3);
        fb[0] = "https://ethereum-rpc.publicnode.com";
        fb[1] = "https://eth.drpc.org";
        fb[2] = "https://1rpc.io/eth";
        h17Fork("FORK_RPC", fb);
        attacker = makeAddr("attacker");
        console2.log("FORK BLOCK", block.number);
    }

    /* ---------- T1: live state / structural facts ---------- */
    function test_T1_liveState() public {
        address[] memory sup = mct.getSupportedAssets();
        console2.log("supported assets:", sup.length);
        for (uint256 i; i < sup.length; i++) console2.log("  asset", sup[i]);
        console2.log("MCT supply (18dp)", mct.totalSupply());
        console2.log("NaraUSD supply", nara.totalSupply());
        console2.log("booked USDC collateral (6dp)", mct.collateralBalance(USDC));
        console2.log("booked USDT collateral (6dp)", mct.collateralBalance(USDT));
        console2.log("MCT USDC balance (6dp)", IERC20(USDC).balanceOf(MCT));
        console2.log("MCT USDT balance (6dp)", IERC20(USDT).balanceOf(MCT));
        console2.log("accountant getRate (18dp)", IAccountant(ACCOUNTANT).getRate());
        console2.log("BV totalSupply (6dp)", IBoringVault(BV).totalSupply());
        console2.log(string.concat("paused: ", nara.paused() ? "true" : "false"));
        // structural asserts
        assertEq(sup.length, 2, "only USDC+USDT collateral");
        assertEq(mct.totalSupply(), nara.totalSupply(), "MCT supply == NaraUSD supply");
        assertEq(mct.collateralBalance(USDC), IERC20(USDC).balanceOf(MCT), "USDC booked==actual");
        assertEq(mct.collateralBalance(USDT), IERC20(USDT).balanceOf(MCT), "USDT booked==actual");
        // the BoringVault share is NOT a collateral asset -> teller round-trip hypothesis dead
        assertFalse(mct.isSupportedAsset(BV), "BV share not collateral");
        assertFalse(mct.isSupportedAsset(0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD), "sUSDS not collateral");
    }

    /* ---------- T2: MCT role gates ---------- */
    function test_T2_mctRoleGates() public {
        assertTrue(mct.hasRole(MINTER_ROLE, NARAUSD), "NaraUSD holds MINTER on MCT");
        assertFalse(mct.hasRole(MINTER_ROLE, NARAUSD_PLUS), "NaraUSD+ has no MINTER");
        assertTrue(mct.hasRole(ADMIN_ROLE, SAFE), "Safe is MCT admin");
        vm.startPrank(attacker);
        vm.expectRevert();
        mct.mint(USDC, 1e6, attacker);
        vm.expectRevert();
        mct.mintWithoutCollateral(attacker, 1e18);
        vm.expectRevert();
        mct.redeem(USDC, 1e18, attacker);
        vm.expectRevert();
        mct.withdrawCollateral(USDC, 1, attacker);
        vm.stopPrank();
    }

    /* ---------- T3: keyring gate on NaraUSD mint/redeem ---------- */
    function test_T3_keyringGates() public {
        assertFalse(nara.hasValidCredentials(attacker), "fresh attacker not credentialed");
        assertFalse(nara.keyringWhitelist(attacker), "attacker not whitelisted");
        // even a well-known address is not credentialed
        assertFalse(nara.hasValidCredentials(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045), "vitalik not credentialed");

        // mint blocked
        deal(address(USDC), attacker, 1_000e6);
        vm.startPrank(attacker);
        IERC20(USDC).approve(NARAUSD, 1_000e6);
        vm.expectRevert();
        nara.mintWithCollateral(USDC, 1_000e6);
        vm.stopPrank();

        // redeem blocked even holding NaraUSD
        deal(NARAUSD, attacker, 1_000e18);
        vm.startPrank(attacker);
        vm.expectRevert();
        nara.redeem(USDC, 1_000e18, false);
        vm.stopPrank();
    }

    /* ---------- T4: NaraUSD admin gates ---------- */
    function test_T4_naraAdminGates() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        nara.mintWithoutCollateral(attacker, 1e18);
        vm.expectRevert();
        INaraUSDAdmin(NARAUSD).pause();
        vm.expectRevert();
        INaraUSDAdmin(NARAUSD).setKeyringConfig(address(0), 0);
        vm.expectRevert();
        INaraUSDAdmin(NARAUSD).redistributeLockedAmount(attacker, attacker);
        vm.expectRevert();
        INaraUSDAdmin(NARAUSD).setFeeTreasury(attacker);
        vm.stopPrank();
    }

    /* ---------- T5: NaraUSD+ deposit is open (no keyring) but the round-trip pays only staking yield ---------- */
    function test_T5_plusRoundTrip() public {
        assertTrue(plus.cooldownDuration() > 0, "cooldown on");
        deal(NARAUSD, attacker, 1_000e18);
        uint256 before = IERC20(NARAUSD).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(NARAUSD).approve(NARAUSD_PLUS, type(uint256).max);
        uint256 shares = plus.deposit(1_000e18, attacker);
        // ERC4626 redeem/withdraw disabled while cooldown is on
        vm.expectRevert();
        plus.redeem(shares, attacker, attacker);
        plus.cooldownShares(shares);
        vm.stopPrank();
        vm.warp(block.timestamp + uint256(plus.cooldownDuration()) + 1);
        vm.prank(attacker);
        plus.unstake(attacker);
        uint256 afterBal = IERC20(NARAUSD).balanceOf(attacker);
        console2.log("plus bought shares", shares);
        console2.log("NaraUSD before", before);
        console2.log("NaraUSD after ", afterBal);
        // The only gain is the protocol's vesting reward stream over 7 locked days (measured ~0.224%):
        // it is yield for staked capital, not extraction. Bound it tightly to prove no windfall.
        assertGt(afterBal, before, "staking yield accrues");
        assertLt(afterBal, before + before / 100, "gain bounded to <1% for 7d (yield only)");
    }

    /* ---------- T6: silo gates ---------- */
    function test_T6_siloGates() public {
        deal(NARAUSD, attacker, 100e18);
        vm.startPrank(attacker);
        vm.expectRevert();
        ISilo(SILO1).withdraw(attacker, 1);
        vm.expectRevert();
        ISilo(SILO2).withdraw(attacker, 1);
        vm.stopPrank();
    }

    /* ---------- T7: accountant rate path + BoringVault are closed ---------- */
    function test_T7_ratePathClosed() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IAccountant(ACCOUNTANT).updateExchangeRate(1e18);
        vm.expectRevert();
        IAccountant(ACCOUNTANT).setRateProviderData(USDC, true, attacker);
        vm.expectRevert();
        IBoringVault(BV).manage(USDC, abi.encodeWithSelector(IERC20.approve.selector, attacker, 1), 0);
        vm.expectRevert();
        IBoringVault(BV).enter(attacker, USDC, 0, attacker, 1e6);
        vm.expectRevert();
        IBoringVault(BV).exit(attacker, USDC, 1e6, attacker, 1e6);
        vm.stopPrank();
    }

    /* ---------- T8: hypothetical keyring bypass -> still zero profit (exact par) ---------- */
    function test_T8_keyringBypassNoProfit() public {
        // simulate a full keyring compromise: the external credential check returns true
        uint256 pid = nara.keyringPolicyId();
        vm.mockCall(
            KEYRING,
            abi.encodeWithSignature("checkCredential(uint256,address)", pid, attacker),
            abi.encode(true)
        );
        assertTrue(nara.hasValidCredentials(attacker), "mock active");

        deal(address(USDC), attacker, 1_000e6);
        vm.startPrank(attacker);
        IERC20(USDC).approve(NARAUSD, 1_000e6);
        uint256 minted = nara.mintWithCollateral(USDC, 1_000e6);
        console2.log("minted NaraUSD for 1000 USDC", minted);
        assertEq(minted, 1_000e18, "par mint: 1000 USDC -> 1000 NaraUSD");
        (uint256 out, bool queued) = nara.redeem(USDC, 1_000e18, false);
        vm.stopPrank();
        console2.log("redeemed USDC (6dp)", out);
        console2.log(string.concat("queued: ", queued ? "true" : "false"));
        assertEq(out, 1_000e6, "par redeem: 1000 NaraUSD -> 1000 USDC");
        assertEq(IERC20(USDC).balanceOf(attacker), 1_000e6, "attacker delta == 0");
        console2.log("attacker USDC after round-trip", IERC20(USDC).balanceOf(attacker));
    }

    /* ---------- T9: instant-redeem cap engages beyond booked collateral ---------- */
    function test_T9_instantRedeemCap() public {
        uint256 pid2 = nara.keyringPolicyId();
        vm.mockCall(
            KEYRING,
            abi.encodeWithSignature("checkCredential(uint256,address)", pid2, attacker),
            abi.encode(true)
        );
        uint256 booked = mct.collateralBalance(USDC);
        console2.log("booked USDC collateral (6dp)", booked);
        deal(address(USDT), attacker, 5_000e6); // buy-side with USDT collateral instead
        deal(address(USDC), attacker, 10_000e6);
        vm.startPrank(attacker);
        IUSDTLike(USDT).approve(NARAUSD, 5_000e6);
        uint256 minted = nara.mintWithCollateral(USDT, 5_000e6);
        console2.log("minted NaraUSD via 5000 USDT", minted);
        assertGt(minted, booked * 1e12, "minted exceeds booked USDC collateral");
        // no instant USDC redeem possible -> queues (or reverts with allowQueue=false)
        vm.expectRevert();
        nara.redeem(USDC, minted, false);
        (uint256 out2, bool queued2) = nara.redeem(USDC, minted, true);
        assertEq(out2, 0, "queued, nothing paid instantly");
        assertTrue(queued2, "wasQueued");
        nara.cancelRedeem();
        vm.stopPrank();
        console2.log("after cancel, attacker USDT", IERC20(USDT).balanceOf(attacker));
        assertEq(IERC20(USDT).balanceOf(attacker), 0, "all USDT went into the mint");
        assertEq(IERC20(NARAUSD).balanceOf(attacker), minted, "NaraUSD escrow returned on cancel");
    }
}

interface INaraUSDAdmin {
    function pause() external;
    function setKeyringConfig(address, uint256) external;
    function redistributeLockedAmount(address, address) external;
    function setFeeTreasury(address) external;
}
