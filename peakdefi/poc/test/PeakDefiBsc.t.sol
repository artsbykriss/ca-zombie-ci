// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IPeakStaking, IPeakFund, IERC20} from "../src/IPeakDefi.sol";

/// @title PEAKDEFI BSC staking PoC (BNB Chain fork)
/// @notice Reproduces that the PEAK staking mint cap is exhausted, which closes
///         the permissionless "stake + referral-bonus" mint-farming path.
contract PeakDefiBscTest is Test {
    address constant STAKING = 0xe9428B8acaA6b9d7C3314D093975c291Ec59A009;
    address constant PEAK = 0x630d98424eFe0Ea27fB1b3Ab7741907DFFEaAd78; // 8 decimals
    address constant ATTACKER = address(0xA11CE);

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        forkBlock = vm.createSelectFork(rpc);
    }

    function test_H_bsc_mint_cap_exhausted_closes_staking() public {
        IPeakStaking st = IPeakStaking(STAKING);
        uint256 minted = st.mintedPeakTokens();
        uint256 cap = st.PEAK_MINT_CAP();
        uint256 headroom = cap - minted;

        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("mintedPeakTokens", minted);
        emit log_named_uint("PEAK_MINT_CAP", cap);
        emit log_named_uint("headroom (PEAK 8dp units)", headroom);

        assertLt(headroom, 1e6, "cap headroom >= 0.01 PEAK"); // < 0.01 PEAK left

        // the interest of even a minimal (1 PEAK / 10 day) stake exceeds the headroom,
        // so stake() reverts on `require(mintedPeakTokens <= PEAK_MINT_CAP)`
        uint256 interest1Peak10d = st.getInterestAmount(1e8, 10);
        emit log_named_uint("interest(1 PEAK, 10d)", interest1Peak10d);
        assertGt(interest1Peak10d, headroom, "cap would allow a 1 PEAK stake");

        // staking is initialized (init cannot be replayed) and holds the user stakes
        assertTrue(st.initialized(), "staking not initialized");
        vm.prank(ATTACKER);
        (bool ok, ) = STAKING.call(abi.encodeWithSignature("init(address)", ATTACKER));
        assertFalse(ok, "init() replayable");
        uint256 staked = IERC20(PEAK).balanceOf(STAKING);
        emit log_named_uint("PEAK held by staking (user stakes)", staked);
        assertGt(staked, 150_000_000 * 1e8, "staking PEAK balance unexpectedly low");
    }

    /// @dev direct proof: a fresh address cannot stake even 1 PEAK (cap revert)
    function test_I_bsc_fresh_stake_reverts() public {
        // give the attacker 1 PEAK on the fork (whale-free: storage write via deal)
        deal(PEAK, ATTACKER, 1e8);
        assertEq(IERC20(PEAK).balanceOf(ATTACKER), 1e8, "deal failed");
        vm.startPrank(ATTACKER);
        IERC20(PEAK).approve(STAKING, type(uint256).max);
        vm.expectRevert(); // "PeakStaking: reached cap"
        IPeakStaking(STAKING).stake(1e8, 10, address(0));
        vm.stopPrank();
    }
}
