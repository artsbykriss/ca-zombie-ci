// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {VaultV2} from "vault-v2/VaultV2.sol";

interface IERC20Like {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

/// @title Read-only, fork-only PoC for the World Chain "AgentBank Deposit Vault" (Morpho VaultV2 code).
/// No transactions are ever sent to a real chain; everything runs against an anvil fork.
contract VaultV2PoC is Test {
    address constant VAULT = 0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1;
    address constant WLD = 0x2cFc85d8E48F8EAB294be644d9E25C3030863003;
    address constant OWNER = 0x148677e5fDd232adA601CF9e1b8194431D3E31b5; // Gnosis Safe 2-of-2
    address constant ATK = address(0xBEEF00000000000000000000000000000000BEEf);
    address constant RANDOM2 = address(0x1234567890AbcdEF1234567890aBcdef12345678);
    address constant NO_ADAPTER = address(0xdeAD00000000000000000000000000000000dEAd);

    VaultV2 v;
    IERC20Like wld;

    function _fork() internal {
        string[3] memory urls = [
            vm.envOr("WORLD_RPC_URL", string("https://worldchain-mainnet.g.alchemy.com/public")),
            "https://worldchain.drpc.org",
            "https://worldchain-mainnet.g.alchemy.com/public"
        ];
        for (uint256 i; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) {
                return;
            } catch {}
        }
        revert("no world chain rpc");
    }

    function setUp() public {
        _fork();
        v = VaultV2(VAULT);
        wld = IERC20Like(WLD);
        vm.deal(ATK, 100 ether);
        vm.deal(RANDOM2, 100 ether);
    }

    /* ---------------- identity ---------------- */

    function test_identity() public view {
        assertEq(v.name(), "AgentBank Deposit Vault");
        assertEq(v.symbol(), "abWLD");
        assertEq(v.asset(), WLD);
        assertEq(v.decimals(), 18);
        assertEq(v.virtualShares(), 1);
        assertEq(v.owner(), OWNER);
        assertEq(v.curator(), OWNER);
        assertTrue(v.isSentinel(OWNER));
        assertFalse(v.isAllocator(OWNER));
        // gates all disabled
        assertEq(v.receiveSharesGate(), address(0));
        assertEq(v.sendSharesGate(), address(0));
        assertEq(v.receiveAssetsGate(), address(0));
        assertEq(v.sendAssetsGate(), address(0));
        // no adapters, no liquidity adapter, no fees, no rate
        assertEq(v.adaptersLength(), 0);
        assertEq(v.liquidityAdapter(), address(0));
        assertEq(v.maxRate(), 0);
        assertEq(v.performanceFee(), 0);
        assertEq(v.managementFee(), 0);
        // accounting: totalAssets == totalSupply => share price exactly 1.0
        assertEq(v.totalAssets(), v.totalSupply());
        assertEq(v.totalAssets(), wld.balanceOf(VAULT)); // no adapters => real == idle (or >=)
    }

    function test_live_money() public {
        uint256 ta = v.totalAssets();
        emit log_named_decimal_uint("totalAssets (WLD)", ta, 18);
        emit log_named_decimal_uint("totalSupply (shares)", v.totalSupply(), 18);
        emit log_named_decimal_uint("vault WLD balance", wld.balanceOf(VAULT), 18);
        emit log_named_uint("dust (balance - totalAssets) wei", wld.balanceOf(VAULT) - ta);
        assertGt(ta, 0);
    }

    /* ---------------- unprivileged value-moving paths ---------------- */

    function test_atk_deposit_is_allowed_but_no_value_gain() public {
        // gates are open: anyone can deposit
        vm.startPrank(ATK);
        deal(WLD, ATK, 1000e18);
        wld.approve(VAULT, type(uint256).max);
        uint256 before = wld.balanceOf(ATK);
        uint256 shares = v.deposit(1000e18, ATK);
        assertEq(shares, 1000e18); // 1:1, virtualShares=1
        assertEq(wld.balanceOf(ATK), before - 1000e18);
        // redeem immediately -> cannot get more than deposited
        uint256 got = v.redeem(shares, ATK, ATK);
        vm.stopPrank();
        emit log_named_decimal_uint("deposited WLD", 1000e18, 18);
        emit log_named_decimal_uint("redeemed  WLD", got, 18);
        assertLe(got, 1000e18); // no profit
    }

    function test_atk_cannot_withdraw_without_shares() public {
        vm.prank(ATK);
        vm.expectRevert();
        v.withdraw(1e18, ATK, RANDOM2); // no shares / no allowance
    }

    function test_atk_allocate_reverts() public {
        vm.prank(ATK);
        vm.expectRevert(); // Unauthorized (not allocator)
        v.allocate(NO_ADAPTER, "", 1e18);
    }

    function test_atk_deallocate_reverts() public {
        vm.prank(ATK);
        vm.expectRevert(); // Unauthorized
        v.deallocate(NO_ADAPTER, "", 1e18);
    }

    function test_atk_forceDeallocate_reverts_no_adapter() public {
        vm.prank(ATK);
        vm.expectRevert(); // NotAdapter
        v.forceDeallocate(NO_ADAPTER, "", 1e18, ATK);
    }

    function test_atk_setLiquidityAdapter_reverts() public {
        vm.prank(ATK);
        vm.expectRevert(); // Unauthorized
        v.setLiquidityAdapterAndData(NO_ADAPTER, "");
    }

    function test_atk_setMaxRate_reverts() public {
        vm.prank(ATK);
        vm.expectRevert(); // Unauthorized
        v.setMaxRate(1);
    }

    function test_atk_admin_functions_revert() public {
        vm.startPrank(ATK);
        vm.expectRevert(); v.setOwner(ATK);
        vm.expectRevert(); v.setCurator(ATK);
        vm.expectRevert(); v.setIsSentinel(ATK, true);
        vm.expectRevert(); v.addAdapter(NO_ADAPTER);
        vm.expectRevert(); v.setAdapterRegistry(NO_ADAPTER);
        vm.expectRevert(); v.setIsAllocator(ATK, true);
        vm.expectRevert(); v.setReceiveSharesGate(ATK);
        vm.expectRevert(); v.setSendSharesGate(ATK);
        vm.expectRevert(); v.setReceiveAssetsGate(ATK);
        vm.expectRevert(); v.setSendAssetsGate(ATK);
        vm.expectRevert(); v.setPerformanceFee(1);
        vm.expectRevert(); v.setManagementFee(1);
        vm.stopPrank();
    }

    /// @dev Timelocked curator calls cannot be executed without the curator first submitting the exact calldata.
    function test_atk_timelocked_without_submit_reverts() public {
        vm.startPrank(ATK);
        vm.expectRevert(); // DataNotTimelocked
        v.removeAdapter(NO_ADAPTER);
        vm.expectRevert();
        v.abdicate(bytes4(0x12345678));
        vm.expectRevert();
        v.increaseAbsoluteCap("", 1e18);
        vm.stopPrank();
    }

    /* ---------------- donation / inflation ---------------- */

    function test_donation_does_not_inflate_share_price() public {
        // maxRate == 0 => realAssets are capped at stored _totalAssets => donations are NOT recognised.
        // attacker seeds a tiny position
        vm.startPrank(ATK);
        deal(WLD, ATK, 1000e18);
        wld.approve(VAULT, type(uint256).max);
        uint256 shares = v.deposit(1e18, ATK);
        uint256 taAfterDeposit = v.totalAssets(); // includes the 1e18 deposit, excludes donation
        // donate a large amount directly to the vault
        wld.transfer(VAULT, 500e18);
        // donation must NOT be recognised
        assertEq(v.totalAssets(), taAfterDeposit);
        assertEq(v.previewRedeem(shares), 1e18); // attacker gains nothing
        uint256 got = v.redeem(shares, ATK, ATK);
        vm.stopPrank();
        emit log_named_decimal_uint("donated then redeemed", got, 18);
        assertLe(got, 1e18); // attacker LOST the 500 WLD donation
    }

    /// @dev Even redeeming every outstanding share leaves the unrecognised dust in the vault.
    function test_full_redeem_leaves_dust_stuck() public {
        uint256 ts = v.totalSupply();
        uint256 ta = v.totalAssets();
        uint256 bal = wld.balanceOf(VAULT);
        assertGe(bal, ta);
        // theoretical max any holder can pull out == ta (all shares), dust stays behind
        emit log_named_uint("dust that no share can claim (wei)", bal - ta);
        assertEq(ts, ta); // 1:1
    }

    /* ---------------- adversarial: first-depositor / inflation on a FRESH vault ---------------- */

    /// @dev With maxRate == 0 the vault caps recognised assets at the stored _totalAssets, so a
    ///      donation can never raise the share price => classic ERC4626 inflation attack fails.
    function test_fresh_vault_inflation_attack_fails() public {
        VaultV2 fresh = new VaultV2(address(this), WLD);
        address VICTIM = address(0x1111222233334444555566667777888899990000);

        // attacker seeds 1 wei
        deal(WLD, ATK, 200_000e18);
        vm.startPrank(ATK);
        wld.approve(address(fresh), type(uint256).max);
        uint256 seedShares = fresh.deposit(1, ATK);
        assertEq(seedShares, 1);
        // donate a large amount directly to the vault
        wld.transfer(address(fresh), 100_000e18);
        vm.stopPrank();

        // donation is not recognised (maxRate == 0)
        assertEq(fresh.totalAssets(), 1);

        // victim deposits 10_000 -> must receive exactly 10_000 shares (no dilution)
        deal(WLD, VICTIM, 10_000e18);
        vm.startPrank(VICTIM);
        wld.approve(address(fresh), type(uint256).max);
        uint256 vShares = fresh.deposit(10_000e18, VICTIM);
        assertEq(vShares, 10_000e18, "victim diluted!");
        // victim can immediately redeem the full amount back
        uint256 back = fresh.redeem(vShares, VICTIM, VICTIM);
        assertEq(back, 10_000e18);
        vm.stopPrank();

        // attacker can only ever get their 1 wei back, not the donation
        vm.prank(ATK);
        uint256 got = fresh.redeem(seedShares, ATK, ATK);
        assertLe(got, 1);
        emit log_named_uint("attacker redeemed (wei)", got);
    }

    /// @dev Real-holder round trip: impersonate an address that actually holds WLD and deposit+redeem.
    function test_real_holder_round_trip_is_1to1() public {
        // fund a fresh EOA via deal (fork) and do a full round trip against the LIVE vault
        deal(WLD, RANDOM2, 50_000e18);
        vm.startPrank(RANDOM2);
        wld.approve(VAULT, type(uint256).max);
        uint256 s = v.deposit(50_000e18, RANDOM2);
        uint256 back = v.redeem(s, RANDOM2, RANDOM2);
        vm.stopPrank();
        assertLe(back, 50_000e18);
        assertGe(back, 50_000e18 - 1); // 1:1 up to rounding
        emit log_named_decimal_uint("round trip redeemed", back, 18);
    }

    /// @dev A direct donation to the LIVE vault is not recognised either.
    function test_live_donation_not_recognised() public {
        uint256 ta0 = v.totalAssets();
        deal(WLD, RANDOM2, 1000e18);
        vm.prank(RANDOM2);
        wld.transfer(VAULT, 1000e18);
        assertEq(v.totalAssets(), ta0, "donation changed totalAssets");
    }

    /* ---------------- code identity ---------------- */

    function _stripMetadata(bytes memory code) internal pure returns (bytes memory) {
        uint256 n = code.length;
        require(n > 2, "short");
        uint256 L = (uint256(uint8(code[n - 2])) << 8) | uint256(uint8(code[n - 1]));
        uint256 keep = n - L - 2;
        bytes memory out = new bytes(keep);
        for (uint256 i; i < keep; i++) out[i] = code[i];
        return out;
    }

    /// @dev Deploy the exact dumped source with the same constructor args and compare runtime code to
    ///      the live contract, ignoring only the CBOR metadata suffix.
    function test_bytecode_matches_dumped_source() public {
        VaultV2 fresh = new VaultV2(OWNER, WLD);
        bytes memory local = address(fresh).code;
        bytes memory live = VAULT.code;
        emit log_named_uint("local code len", local.length);
        emit log_named_uint("live  code len", live.length);
        assertEq(local.length, live.length, "code length");
        assertEq(
            keccak256(_stripMetadata(local)),
            keccak256(_stripMetadata(live)),
            "runtime code (metadata-stripped)"
        );
    }
}
