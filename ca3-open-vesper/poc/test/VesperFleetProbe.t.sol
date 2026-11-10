// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IVPool {
    function totalSupply() external view returns (uint256);
    function totalValue() external view returns (uint256);
    function pricePerShare() external view returns (uint256);
    function tokensHere() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function token() external view returns (address);
    function poolAccountant() external view returns (address);
    function governor() external view returns (address);
    function paused() external view returns (bool);
    function stopEverything() external view returns (bool);
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function withdrawETH(uint256) external;
    function reportEarning(uint256, uint256, uint256) external;
    function reportLoss(uint256) external;
    function migrateStrategy(address, address) external;
    function sweepERC20(address) external;
    function pause() external;
    function shutdown() external;
    function updateUniversalFee(uint256) external;
    function updatePoolRewards(address) external;
    function transferGovernorship(address) external;
    function acceptGovernorship() external;
    function getStrategies() external view returns (address[] memory);
}

interface IAccountant {
    function getStrategies() external view returns (address[] memory);
    function totalDebtOf(address) external view returns (uint256);
    function externalDepositFee() external view returns (uint256);
    function strategy(address)
        external
        view
        returns (bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}

/// @title Vesper V2 fleet — read-only privilege / economics probe.
/// @notice Every test is a simulation on a local fork. No mainnet transaction is signed or sent.
contract VesperFleetProbe is Test {
    address constant ATTACKER = address(0xBAD5EED);
    address constant VICTIM = address(0xCAFE01);

    struct P {
        string sym;
        address pool;
    }

    P[] internal v5Pools;
    P[] internal legacyPools;

    function _rpc() internal view returns (string memory) {
        string memory v = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(v).length == 0) v = vm.envOr("RPC_URL", string(""));
        if (bytes(v).length == 0) v = "https://ethereum-rpc.publicnode.com";
        return v;
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
        // pin to a 32-block-old height: public load-balanced RPCs can disagree on the head
        if (block.number > 100) vm.rollFork(block.number - 32);
        // 11 v5 prod pools (Ethereum) — api.vesper.finance/pools?stages=prod, 2026-11-10
        v5Pools.push(P("vaCBETH", 0x650CD45DEdb19c33160Acc522aD1a82D9701036a));
        v5Pools.push(P("vaDAI", 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee));
        v5Pools.push(P("vaETH", 0xd1C117319B3595fbc39b471AB1fd485629eb05F2));
        v5Pools.push(P("vaFRAX", 0xc14900dFB1Aa54e7674e1eCf9ce02b3b35157ba5));
        v5Pools.push(P("vaLINK", 0xef4F4604106de23CDadfEAE08fcC34602cB475C1));
        v5Pools.push(P("vamsETH", 0xCa7c607C590ad16007CCBbba9D26f4df656a36C2));
        v5Pools.push(P("vamsUSD", 0x4C73F025a1947ec770327B9956Fc61f535F72C22));
        v5Pools.push(P("vaRETH", 0xDD9F61a85fFE73E41eF889817972f0B0AaE6D6Dd));
        v5Pools.push(P("vaSTETH", 0x4Dbe3f01aBe271D3E65432c74851625a8c30Aa7B));
        v5Pools.push(P("vaUSDC", 0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452));
        v5Pools.push(P("vaWBTC", 0x01e1d41C1159b745298724c5Fd3eAfF3da1C6efD));
        // 3 legacy v2.0.0 pools (2020), different architecture (immutable controller)
        legacyPools.push(P("vETH", 0x103cc17C2B1586e5Cd9BaD308690bCd0BBe54D5e));
        legacyPools.push(P("vUSDC", 0x0C49066C0808Ee8c673553B7cbd99BCC9ABf113d));
        legacyPools.push(P("vWBTC", 0x4B2e76EbBc9f2923d83F5FBDe695D8733db1a17B));
    }

    // ---------------------------------------------------------------- helpers

    function _callMustRevert(address target, bytes memory data, string memory label) internal returns (bytes memory) {
        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = target.call(data);
        require(!ok, string.concat("UNEXPECTED SUCCESS: ", label, " @", vm.toString(target)));
        require(ret.length >= 4, string.concat("no revert data: ", label, " @", vm.toString(target)));
        return ret;
    }

    /// @dev Some registered strategies are legacy/v1 contracts that do not implement the v6
    ///      selector at all; for those a bare revert (no data) is still a closed path.
    function _callMustRevertLoose(address target, bytes memory data, string memory label) internal {
        vm.prank(ATTACKER, ATTACKER);
        (bool ok,) = target.call(data);
        require(!ok, string.concat("UNEXPECTED SUCCESS: ", label, " @", vm.toString(target)));
    }

    function _sel(string memory sig) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    // ------------------------------------------------------- 1. pool auth map

    function test_eth_pool_registry_and_state() public view {
        console2.log("fork block", block.number);
        for (uint256 i; i < v5Pools.length; ++i) {
            IVPool p = IVPool(v5Pools[i].pool);
            console2.log("---------------------------------------------");
            console2.log(v5Pools[i].sym, v5Pools[i].pool);
            console2.log("  totalValue ", p.totalValue());
            console2.log("  totalSupply", p.totalSupply());
            console2.log("  pps        ", p.pricePerShare());
            console2.log("  tokensHere ", p.tokensHere());
            console2.log("  totalDebt  ", p.totalDebt());
            console2.log("  paused/stop", p.paused(), p.stopEverything());
            address acct = p.poolAccountant();
            address[] memory s = IAccountant(acct).getStrategies();
            console2.log("  strategies ", s.length);
            for (uint256 j; j < s.length; ++j) {
                console2.log("    ", s[j], IAccountant(acct).totalDebtOf(s[j]));
            }
        }
        for (uint256 i; i < legacyPools.length; ++i) {
            address pool = legacyPools[i].pool;
            console2.log("---------------------------------------------");
            console2.log("[legacy v2]", legacyPools[i].sym, pool);
            console2.log("  totalValue ", IVPool(pool).totalValue());
            console2.log("  totalSupply", IVPool(pool).totalSupply());
        }
    }

    /// @notice `reportEarning`/`reportLoss` are unguarded at the pool and rely on the accountant
    ///         proving msg.sender is a registered strategy. A fresh EOA must fail on every pool.
    function test_reportEarning_reportLoss_revert_all_pools() public {
        for (uint256 i; i < v5Pools.length; ++i) {
            address pool = v5Pools[i].pool;
            _callMustRevert(
                pool,
                abi.encodeWithSelector(_sel("reportEarning(uint256,uint256,uint256)"), 1, 0, 0),
                string.concat(v5Pools[i].sym, ":reportEarning")
            );
            _callMustRevert(
                pool, abi.encodeWithSelector(_sel("reportLoss(uint256)"), 1), string.concat(v5Pools[i].sym, ":reportLoss")
            );
        }
    }

    /// @notice Every governor/keeper-gated value path must revert for a fresh EOA.
    function test_admin_paths_revert_all_pools() public {
        for (uint256 i; i < v5Pools.length; ++i) {
            address pool = v5Pools[i].pool;
            string memory s = v5Pools[i].sym;
            _callMustRevert(
                pool,
                abi.encodeWithSelector(_sel("migrateStrategy(address,address)"), ATTACKER, ATTACKER),
                string.concat(s, ":migrateStrategy")
            );
            _callMustRevert(
                pool, abi.encodeWithSelector(_sel("sweepERC20(address)"), ATTACKER), string.concat(s, ":sweepERC20")
            );
            _callMustRevert(pool, abi.encodeWithSelector(_sel("pause()")), string.concat(s, ":pause"));
            _callMustRevert(pool, abi.encodeWithSelector(_sel("shutdown()")), string.concat(s, ":shutdown"));
            _callMustRevert(
                pool,
                abi.encodeWithSelector(_sel("transferGovernorship(address)"), ATTACKER),
                string.concat(s, ":transferGovernorship")
            );
            _callMustRevert(
                pool, abi.encodeWithSelector(_sel("acceptGovernorship()")), string.concat(s, ":acceptGovernorship")
            );
            _callMustRevert(
                pool,
                abi.encodeWithSelector(_sel("updateUniversalFee(uint256)"), 10_000),
                string.concat(s, ":updateUniversalFee")
            );
            _callMustRevert(
                pool,
                abi.encodeWithSelector(_sel("updatePoolRewards(address)"), ATTACKER),
                string.concat(s, ":updatePoolRewards")
            );
        }
    }

    // -------------------------------------------------- 2. strategy auth map

    /// @notice withdraw/onlyPool, rebalance+keeper-only, sweep/keeper-only, UUPS/onlyGovernor.
    function test_strategy_paths_revert_all_pools() public {
        for (uint256 i; i < v5Pools.length; ++i) {
            IVPool p = IVPool(v5Pools[i].pool);
            address acct = p.poolAccountant();
            address[] memory strats = IAccountant(acct).getStrategies();
            for (uint256 j; j < strats.length; ++j) {
                address s = strats[j];
                _callMustRevertLoose(s, abi.encodeWithSelector(_sel("withdraw(uint256)"), 1), "st:withdraw");
                _callMustRevertLoose(
                    s, abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max), "st:rebalance"
                );
                _callMustRevertLoose(s, abi.encodeWithSelector(_sel("sweep(address)"), ATTACKER), "st:sweep");
                _callMustRevertLoose(s, abi.encodeWithSelector(_sel("approveToken(uint256)"), 0), "st:approveToken");
                _callMustRevertLoose(
                    s, abi.encodeWithSelector(_sel("updateFeeCollector(address)"), ATTACKER), "st:updateFeeCollector"
                );
                _callMustRevertLoose(s, abi.encodeWithSelector(_sel("addKeeper(address)"), ATTACKER), "st:addKeeper");
                _callMustRevertLoose(
                    s, abi.encodeWithSelector(_sel("upgradeToAndCall(address,bytes)"), ATTACKER, ""), "st:upgrade"
                );
                // v6 strategies must additionally return the explicit Unauthorized() selector
                (bool ok2, bytes memory r2) =
                    s.staticcall(abi.encodeWithSelector(_sel("withdraw(uint256)"), 1));
                if (!ok2 && r2.length == 4) {
                    assertEq(bytes4(r2), bytes4(keccak256("Unauthorized()")), "unexpected strategy revert");
                }
            }
        }
    }

    // --------------------------------------------------------- 3. economics

    /// @notice Deposit -> immediate withdraw must never return more than was put in.
    function test_roundtrip_never_profitable_vaETH() public {
        // both exit paths of the VETH pool: withdraw() -> WETH, withdrawETH() -> native ETH
        address pool = 0xd1C117319B3595fbc39b471AB1fd485629eb05F2; // vaETH (VETH variant, payable deposit)
        vm.deal(ATTACKER, 100 ether);
        uint256 before = ATTACKER.balance;
        vm.startPrank(ATTACKER);
        (bool ok,) = pool.call{value: 10 ether}(abi.encodeWithSelector(_sel("deposit()")));
        require(ok, "deposit failed");
        uint256 shares = IERC20(pool).balanceOf(ATTACKER);
        IVPool(pool).withdrawETH(shares); // native-ETH exit path
        vm.stopPrank();
        uint256 afterBal = ATTACKER.balance;
        console2.log("vaETH roundtrip start/end", before, afterBal);
        console2.log("vaETH roundtrip profit (negative = loss)", int256(afterBal) - int256(before));
        assertLe(afterBal, before, "roundtrip produced free ETH");
    }

    /// @notice Donation then deposit+withdraw must never beat simply keeping the tokens.
    ///         vaETH: pool token == WETH, so a direct WETH transfer to the pool is a pure donation.
    function test_donation_attack_unprofitable_vaETH() public {
        address pool = 0xd1C117319B3595fbc39b471AB1fd485629eb05F2;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        deal(weth, ATTACKER, 1_000 ether);
        uint256 start = IERC20(weth).balanceOf(ATTACKER);
        vm.startPrank(ATTACKER);
        IERC20(weth).approve(pool, type(uint256).max);
        IVPool(pool).deposit(200 ether);
        IERC20(weth).transfer(pool, 50 ether); // donation -> inflates pps for everyone
        uint256 shares = IERC20(pool).balanceOf(ATTACKER);
        IVPool(pool).withdraw(shares);
        vm.stopPrank();
        uint256 end = IERC20(weth).balanceOf(ATTACKER);
        console2.log("vaETH donation+roundtrip start/end", start, end);
        assertLe(end, start, "donation roundtrip produced free WETH");
    }

    /// @notice First-depositor inflation: attacker mints, donates, a victim deposits, attacker exits.
    ///         Mint rounding is upward in VPool, so the attacker must lose.
    function test_inflation_attack_unprofitable_vaWBTC() public {
        address pool = 0x01e1d41C1159b745298724c5Fd3eAfF3da1C6efD;
        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        deal(wbtc, ATTACKER, 100e8);
        deal(wbtc, VICTIM, 100e8);
        uint256 start = IERC20(wbtc).balanceOf(ATTACKER);
        vm.startPrank(ATTACKER);
        IERC20(wbtc).approve(pool, type(uint256).max);
        IVPool(pool).deposit(1e5); // 0.001 WBTC
        IERC20(wbtc).transfer(pool, 2e6); // 0.02 WBTC donation
        vm.stopPrank();
        vm.startPrank(VICTIM);
        IERC20(wbtc).approve(pool, type(uint256).max);
        IVPool(pool).deposit(5e6); // 0.05 WBTC victim
        vm.stopPrank();
        uint256 atkShares = IERC20(pool).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IVPool(pool).withdraw(atkShares);
        uint256 end = IERC20(wbtc).balanceOf(ATTACKER);
        console2.log("vaWBTC inflation attacker start/end", start, end);
        assertLe(end, start, "inflation attack profited");
    }

    /// @notice JIT probe: park a large deposit, let the real keeper run rebalance, exit.
    ///         The credit-line rule re-lends the fresh deposit, so the exit is a partial
    ///         withdrawal. We log the attacker delta instead of asserting a direction.
    function test_jit_credit_line_probe_vaFRAX() public {
        address pool = 0xc14900dFB1Aa54e7674e1eCf9ce02b3b35157ba5;
        address frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
        address strat = 0x56797811D35af8d49e9d2a68B6E162C48b80FE8B;
        uint256 fund = 30_000_000e18;
        deal(frax, ATTACKER, fund);
        uint256 start = IERC20(frax).balanceOf(ATTACKER);
        vm.startPrank(ATTACKER);
        IERC20(frax).approve(pool, type(uint256).max);
        IVPool(pool).deposit(fund);
        vm.stopPrank();
        uint256 ppsBefore = IVPool(pool).pricePerShare();
        uint256 tvBefore = IVPool(pool).totalValue();
        // real keeper of this strategy (from keepers() on-chain)
        vm.prank(0xf7364E230EA0e5CC41E6Cd4E2a30A26Ca1850b73);
        (bool ok, bytes memory ret) =
            strat.call(abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max));
        uint256 ppsAfter = IVPool(pool).pricePerShare();
        uint256 tvAfter = IVPool(pool).totalValue();
        console2.log("keeper rebalance ok", ok);
        if (ok && ret.length >= 96) {
            (uint256 rp, uint256 rl, uint256 rpb) = abi.decode(ret, (uint256, uint256, uint256));
            console2.log("rebalance reported profit/loss/payback", rp, rl, rpb);
        }
        console2.log("vaFRAX totalValue before/after", tvBefore, tvAfter);
        uint256 jitShares = IERC20(pool).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IVPool(pool).withdraw(jitShares);
        uint256 end = IERC20(frax).balanceOf(ATTACKER);
        console2.log("vaFRAX ppsBefore/After", ppsBefore, ppsAfter);
        console2.log("vaFRAX JIT start/end", start, end);
        // measured ceiling: JIT capture is bounded to the profit actually realised in one
        // rebalance. Assert it stays economically irrelevant (< 5,000 FRAX ~ $5k).
        assertLe(end, start + 5_000e18, "JIT capture unexpectedly large");
    }

    /// @notice JIT probe #2 on the largest *liquid* pool: ETH is flash-loanable, so a
    ///         searcher can park a big deposit in front of the keeper and exit behind it.
    function test_jit_probe_vaETH_convex() public {
        address pool = 0xd1C117319B3595fbc39b471AB1fd485629eb05F2;
        address strat = 0x5E46dEe85572F482cA5185BD2e8ffB1F25871594; // Convex_ynETHx_WETH, 6.35 ETH pending
        vm.deal(ATTACKER, 20_000 ether);
        uint256 start = ATTACKER.balance;
        vm.startPrank(ATTACKER);
        (bool ok0,) = pool.call{value: 10_000 ether}(abi.encodeWithSelector(_sel("deposit()")));
        require(ok0, "deposit failed");
        vm.stopPrank();
        uint256 tvBefore = IVPool(pool).totalValue();
        vm.prank(0xf7364E230EA0e5CC41E6Cd4E2a30A26Ca1850b73);
        (bool ok, bytes memory ret) =
            strat.call(abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max));
        uint256 tvAfter = IVPool(pool).totalValue();
        console2.log("vaETH keeper rebalance ok", ok);
        if (ok && ret.length >= 96) {
            (uint256 rp, uint256 rl, uint256 rpb) = abi.decode(ret, (uint256, uint256, uint256));
            console2.log("vaETH rebalance profit/loss/payback", rp, rl, rpb);
        }
        console2.log("vaETH totalValue before/after", tvBefore, tvAfter);
        uint256 shares = IERC20(pool).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IVPool(pool).withdrawETH(shares);
        uint256 end = ATTACKER.balance;
        console2.log("vaETH JIT start/end", start, end);
        assertLe(end, start + 100 ether, "JIT capture unexpectedly large");
    }

    /// @notice Measure what each live keeper rebalance actually realises. The realised profit is
    ///         the exact upper bound on what a JIT depositor can dilute away in one event.
    function test_measure_rebalance_profit() public {
        for (uint256 i; i < v5Pools.length; ++i) {
            address acct = IVPool(v5Pools[i].pool).poolAccountant();
            address[] memory strats = IAccountant(acct).getStrategies();
            for (uint256 j; j < strats.length; ++j) {
                _probeRebalance(v5Pools[i].sym, acct, strats[j]);
            }
        }
    }

    function _probeRebalance(string memory sym, address acct, address s) internal {
        (bool active, , , , uint256 debt, , , , ) = IAccountant(acct).strategy(s);
        if (!active || debt == 0) return;
        (bool kok, bytes memory kr) = s.staticcall(abi.encodeWithSelector(_sel("keepers()")));
        if (!kok || kr.length < 64) return;
        address[] memory ks = abi.decode(kr, (address[]));
        if (ks.length == 0) return;
        vm.prank(ks[0]);
        (bool ok, bytes memory ret) =
            s.call(abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max));
        if (ok && ret.length >= 96) {
            (uint256 rp, uint256 rl, uint256 rpb) = abi.decode(ret, (uint256, uint256, uint256));
            console2.log("rebalance OK", sym, s);
            console2.log("   profit/loss/payback", rp, rl, rpb);
        } else {
            console2.log("rebalance REVERT", sym, s, ret.length);
        }
    }

    /// @notice Legacy V2 pool exposes a permissionless sweepErc20 — is there any value behind it?
    function test_legacy_sweepErc20_is_public_but_dust() public view {
        address pool = 0x103cc17C2B1586e5Cd9BaD308690bCd0BBe54D5e; // vETH (2020 pool)
        address hexToken = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
        console2.log("vETH HEX balance (1e8 units)", IERC20(hexToken).balanceOf(pool));
        assertLt(IERC20(hexToken).balanceOf(pool), 2e8, "unexpected HEX size");
    }

    /// @notice Phantom debt: dead "Dummy" strategies are still booked as active with debt,
    ///         inflating every pool's pricePerShare. Real backing is a fraction of NAV.
    function test_phantom_debt_dummy_strategies() public {
        address[4] memory dummies = [
            0x084aFb5e91A043C2959E70739B346416ea7F6f7F, // Rari_Dummy_DAI   -> vaDAI
            0xa407da5ad1802C7807d40c64aB5B33A1C7D65D59, // Sommelier_Dummy_ETH -> vaETH
            0xaDcE6FDdD868E865E4D56000832791fdeb29eeda, // Euler_Dummy_ETH  -> vaETH
            0x8F454223C6c59df903812a0C0d9375eDb6089d5F // Maker_Dummy_STETH -> vaSTETH
        ];
        for (uint256 i; i < dummies.length; ++i) {
            (bool ok, bytes memory r) = dummies[i].staticcall(abi.encodeWithSelector(_sel("tvl()")));
            require(ok, "dummy tvl() reverted");
            uint256 tvl = abi.decode(r, (uint256));
            console2.log("dummy", dummies[i], "tvl", tvl);
            assertEq(tvl, 0, "dummy still holds value");
        }
        // vaDAI: booked NAV vs liquid backing
        address vaDAI = 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee;
        uint256 nav = IVPool(vaDAI).totalValue();
        uint256 liquid = IVPool(vaDAI).tokensHere();
        uint256 dummyDebt = IAccountant(IVPool(vaDAI).poolAccountant()).totalDebtOf(dummies[0]);
        console2.log("vaDAI NAV / liquid / dummyDebt", nav, liquid, dummyDebt);
        assertGt(dummyDebt, (nav * 90) / 100, "dummy debt is not dominant");
    }

    /// @notice Legacy `rebalance()` is permissionless at the pool but the strategy's
    ///         `onlyKeeper` rejects the pool, so it can never be driven by an outsider.
    function test_legacy_rebalance_reverts() public {
        for (uint256 i; i < legacyPools.length; ++i) {
            _callMustRevert(legacyPools[i].pool, abi.encodeWithSelector(_sel("rebalance()")), "legacy:rebalance");
        }
    }
}
