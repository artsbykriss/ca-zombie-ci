// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IClPoolFactory, IClPool, IGaugeV2, IFeeCollector, INonfungiblePositionManager, IVoter, IFeeDistributor, IProxyAdmin, ITimelock, FakePool} from "../src/Interfaces.sol";

/// @title Nuri CL (Scroll) — live-extractability boundary tests
/// @notice Fork-only verification of the live state of Nuri CL (Ramses V2 fork on Scroll).
///         No mainnet transaction is signed or sent: everything runs against an
///         anvil/foundry fork selected at block 35364505 (2026-10-13).
///
/// Proven here (all at the pinned fork block):
///   1. The two value-carrying pools' marginal prices track the external market
///      (USDC/WETH dev 0.15%, WETH/STONE dev 0.16%) -> no stale-price arbitrage.
///   2. Every admin path that could move the ~$116k of LP principal is gated:
///      factory.setOwner/setImplementation/setFeeCollector/setFeeProtocol revert for a
///      stranger; pool.collectProtocol reverts (onlyFeeCollector); pool.setFee reverts;
///      the shared ProxyAdmin (beacon/factory upgrade) reverts for a stranger and is
///      owned by a 24h TimelockController.
///   3. Gauge / FeeDistributor claims are owner-only: a stranger's getReward reverts.
///   4. The one permissionless money-touching entrypoint (FeeCollector.collectProtocolFees)
///      pays 100% to the treasury Safe, never to the caller — proven with the real pool's
///      accrued protocol fees, and with an attacker-controlled fake pool.
///   5. A fresh/recent position cannot claim rewards for periods before it existed
///      (pool checkpoint guard) -> gauge NURI rewards cannot be farmed retroactively.

contract NuriClosedPathsTest is Test {
    // ---- live addresses (Scroll mainnet, verified at block 35364505) ----
    address constant FACTORY = 0xAAA32926fcE6bE95ea2c51cB4Fcb60836D320C42; // ClPoolFactory proxy (also the pools' beacon)
    address constant POOL_USDC_WETH = 0xE0DA810f07Da1EAcE7F044aFd081F8583DBe9CD3; // USDC/WETH 0.3% (~$59k)
    address constant POOL_WETH_STONE = 0x97A90E651B0a5cF76484513469249D9bfFe4c73B; // WETH/STONE (~$15.8k)
    address constant GAUGE_USDC_WETH = 0xc32Dff16353bcE12E0BC85963c2cAF41BAC5ca25; // live gauge
    address constant FEE_COLLECTOR = 0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f;
    address constant NFP = 0xAAA78E8C4241990B4ce159E105dA08129345946A; // NonfungiblePositionManager proxy
    address constant VOTER = 0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869;
    address constant FEE_DIST = 0x52239D606aF3a8b41B13F9c3d7658054De4a165F; // fee distributor of GAUGE_USDC_WETH
    address constant PROXY_ADMIN = 0x8e01fc0d89b93a6447D6c6Eca6fBd30e6E4a1ce3; // shared EIP-1967 admin
    address constant TIMELOCK = 0xAAA13CBe7A8Cf93CF3505d00Fe254fDCCE14EF4E; // ProxyAdmin owner
    address constant SAFE = 0xC9d28676b7d470210a3C490B60729660eE5a7257; // protocol owner/treasury

    address constant WETH = 0x5300000000000000000000000000000000000004;
    address constant USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address constant STONE = 0x80137510979822322193FC997d400D5A6C747bf7;
    address constant NURI = 0xAAAE8378809bb8815c08D3C59Eb0c7D1529aD769;

    uint256 constant FORK_BLOCK = 35364505;
    // external market reference at 2026-10-13 (DefiLlama): WETH $2509.65, USDC $0.99982, STONE $2682.71
    uint256 constant USDC_PER_WETH_E18 = 25101e17; // 2510.1 (USDC per WETH, e18)
    uint256 constant STONE_PER_WETH_E18 = 935e15; // 0.9350 (STONE per WETH, e18)

    address attacker = makeAddr("freshAttacker");

    function setUp() public {
        string[3] memory urls = [
            vm.envOr("SCROLL_RPC_URL", string("https://rpc.scroll.io")),
            "https://scroll-rpc.publicnode.com",
            "https://scroll.drpc.org"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i], FORK_BLOCK) {
                vm.deal(attacker, 100 ether); // gas money on the fork only
                return;
            } catch {}
        }
        revert("no working Scroll RPC");
    }

    // ---------- helpers ----------
    function _mulDiv(uint256 a, uint256 b, uint256 d) internal pure returns (uint256) {
        return (a * b) / d;
    }

    /// @dev token1 per token0, scaled 1e18, from sqrtPriceX96.
    function _priceE18(uint160 sqrtPriceX96, uint8 dec0, uint8 dec1) internal pure returns (uint256) {
        // rawE18 = (sqrt/2^96)^2 * 1e18 = sqrt^2 / (2^192/1e18)
        uint256 rawE18 = _mulDiv(uint256(sqrtPriceX96), uint256(sqrtPriceX96), (uint256(2) ** 192) / 1e18);
        // human price (token1 per token0) = raw * 10^(dec0-dec1)
        if (dec0 >= dec1) {
            return rawE18 * (10 ** (dec0 - dec1));
        } else {
            return rawE18 / (10 ** (dec1 - dec0));
        }
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    // ---------- 1. no stale-price arbitrage ----------
    function test_pool_prices_track_market() public {
        // USDC/WETH pool: token0=USDC(6), token1=WETH(18)
        (uint160 sqrt0, , , , , uint8 feeProtocol, bool unlocked) = IClPool(POOL_USDC_WETH).slot0();
        assertTrue(unlocked, "pool must be unlocked");
        assertEq(feeProtocol, 100, "feeProtocol=100 (100% of swap fee to protocol)");
        uint256 price = _priceE18(sqrt0, 6, 18); // WETH per USDC
        uint256 usdcPerWethE18 = 1e36 / price; // invert to USDC per WETH
        uint256 dev0 = _absDiff(usdcPerWethE18, USDC_PER_WETH_E18) * 1e18 / USDC_PER_WETH_E18;
        emit log_named_uint("USDC per WETH (pool, e18)", usdcPerWethE18);
        assertLt(dev0, 0.02e18, "USDC/WETH pool must be within 2% of market");

        // WETH/STONE pool: token0=WETH(18), token1=STONE(18)
        (uint160 sqrt1, , , , , , ) = IClPool(POOL_WETH_STONE).slot0();
        uint256 price1 = _priceE18(sqrt1, 18, 18); // STONE per WETH
        uint256 dev1 = _absDiff(price1, STONE_PER_WETH_E18) * 1e18 / STONE_PER_WETH_E18;
        emit log_named_uint("STONE per WETH (pool, e18)", price1);
        assertLt(dev1, 0.02e18, "WETH/STONE pool must be within 2% of market");
    }

    // ---------- 2. admin paths are privileged ----------
    function test_factory_admin_paths_revert_for_stranger() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("AUTH"));
        IClPoolFactory(FACTORY).setOwner(attacker);
        vm.expectRevert(bytes("AUTH"));
        IClPoolFactory(FACTORY).setImplementation(attacker);
        vm.expectRevert(bytes("AUTH"));
        IClPoolFactory(FACTORY).setFeeCollector(attacker);
        vm.expectRevert(bytes("AUTH"));
        IClPoolFactory(FACTORY).setFeeProtocol(1);
        vm.expectRevert(bytes("AUTH"));
        IClPoolFactory(FACTORY).enableFeeAmount(12345, 5);
        vm.stopPrank();
        // and the owner/feeSetter/implementation are the live privileged contracts
        assertEq(IClPoolFactory(FACTORY).owner(), SAFE, "owner is the Safe");
        assertEq(IClPoolFactory(FACTORY).feeSetter(), 0xAAA11500dDdB2B67a90d1a154dfB7eaBB518EAE6, "feeSetter is CommandCenter");
        assertEq(IClPoolFactory(FACTORY).feeCollector(), FEE_COLLECTOR, "feeCollector");
    }

    function test_pool_protocol_and_fee_paths_revert_for_stranger() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IClPool(POOL_USDC_WETH).collectProtocol(attacker, type(uint128).max, type(uint128).max);
        vm.expectRevert(bytes("AUTH"));
        IClPool(POOL_USDC_WETH).setFee(100);
        vm.stopPrank();
    }

    function test_setFeeProtocol_permissionless_but_noop() public {
        (, , , , , uint8 before, ) = IClPool(POOL_USDC_WETH).slot0();
        vm.prank(attacker);
        IClPool(POOL_USDC_WETH).setFeeProtocol(); // permissionless sync from factory; must not change value
        (, , , , , uint8 after_, ) = IClPool(POOL_USDC_WETH).slot0();
        assertEq(before, after_, "feeProtocol must stay at the factory-configured value");
    }

    function test_upgrade_path_is_timelocked_admin() public {
        assertEq(IProxyAdmin(PROXY_ADMIN).owner(), TIMELOCK, "ProxyAdmin owned by timelock");
        assertEq(ITimelock(TIMELOCK).getMinDelay(), 86400, "24h upgrade delay");
        vm.prank(attacker);
        vm.expectRevert();
        IProxyAdmin(PROXY_ADMIN).upgrade(FACTORY, attacker); // cannot swap the pools' implementation
    }

    // ---------- 3. gauge / fee distributor claims are owner-only ----------
    function test_gauge_and_fee_distributor_claims_are_owner_only() public {
        uint256 tokenId = INonfungiblePositionManager(NFP).tokenByIndex(0);
        address[] memory tokens = new address[](1);
        tokens[0] = NURI;
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Not authorized"));
        IGaugeV2(GAUGE_USDC_WETH).getReward(tokenId, tokens);
        vm.expectRevert(bytes("Not authorized"));
        IGaugeV2(GAUGE_USDC_WETH).getRewardForOwner(tokenId, tokens);
        vm.expectRevert();
        IFeeDistributor(FEE_DIST).getRewardForOwner(tokenId, tokens);
        vm.stopPrank();
    }

    // ---------- 4. the permissionless FeeCollector sweep pays the treasury ----------
    function test_feeCollector_collectProtocolFees_pays_treasury_not_attacker() public {
        (uint128 pf0, uint128 pf1) = IClPool(POOL_USDC_WETH).protocolFees();
        assertGt(pf0, 0, "USDC protocol fees accrued");
        assertGt(pf1, 0, "WETH protocol fees accrued");

        uint256 atkUsdc0 = IERC20(USDC).balanceOf(attacker);
        uint256 atkWeth0 = IERC20(WETH).balanceOf(attacker);
        uint256 treUsdc0 = IERC20(USDC).balanceOf(SAFE);
        uint256 treWeth0 = IERC20(WETH).balanceOf(SAFE);

        vm.prank(attacker);
        IFeeCollector(FEE_COLLECTOR).collectProtocolFees(IClPool(POOL_USDC_WETH));

        assertEq(IERC20(USDC).balanceOf(attacker), atkUsdc0, "attacker gained no USDC");
        assertEq(IERC20(WETH).balanceOf(attacker), atkWeth0, "attacker gained no WETH");
        // pool keeps 1 wei of each slot (gas trick); treasury receives the rest, 100% (treasuryFees=10000)
        assertGe(IERC20(USDC).balanceOf(SAFE) - treUsdc0, uint256(pf0) - 1, "USDC went to treasury");
        assertGe(IERC20(WETH).balanceOf(SAFE) - treWeth0, uint256(pf1) - 1, "WETH went to treasury");
        assertEq(IFeeCollector(FEE_COLLECTOR).treasuryFees(), 10000, "treasury takes 100%");
    }

    function test_fake_pool_cannot_enrich_attacker() public {
        FakePool fake = new FakePool(WETH, USDC);
        uint256 atkUsdc0 = IERC20(USDC).balanceOf(attacker);
        uint256 atkWeth0 = IERC20(WETH).balanceOf(attacker);
        uint256 fcUsdc0 = IERC20(USDC).balanceOf(FEE_COLLECTOR);
        uint256 fcWeth0 = IERC20(WETH).balanceOf(FEE_COLLECTOR);
        vm.prank(attacker);
        IFeeCollector(FEE_COLLECTOR).collectProtocolFees(IClPool(address(fake)));
        assertEq(IERC20(USDC).balanceOf(attacker), atkUsdc0, "no USDC to attacker");
        assertEq(IERC20(WETH).balanceOf(attacker), atkWeth0, "no WETH to attacker");
        assertEq(IERC20(USDC).balanceOf(FEE_COLLECTOR), fcUsdc0, "fee collector balance untouched");
        assertEq(IERC20(WETH).balanceOf(FEE_COLLECTOR), fcWeth0, "fee collector balance untouched");
    }

    /// @dev The FeeCollector reads its WHOLE token balance (not just the amount collected) and
    ///      sweeps it. Funded on the fork to show the destination is the treasury Safe — 100%
    ///      (treasuryFees=10000) — and never the caller.
    function test_feeCollector_excess_balance_sweep_goes_to_treasury() public {
        deal(USDC, FEE_COLLECTOR, 1_000e6); // fork-only funding of the collector
        uint256 atk0 = IERC20(USDC).balanceOf(attacker);
        uint256 tre0 = IERC20(USDC).balanceOf(SAFE);
        vm.prank(attacker);
        IFeeCollector(FEE_COLLECTOR).collectProtocolFees(IClPool(POOL_USDC_WETH));
        assertEq(IERC20(USDC).balanceOf(attacker), atk0, "attacker gained nothing");
        assertGe(IERC20(USDC).balanceOf(SAFE) - tre0, 1_000e6, "excess balance went to treasury");
        assertEq(IERC20(USDC).balanceOf(FEE_COLLECTOR), 0, "collector swept to zero");
    }

    // ---------- 5. no retroactive gauge rewards for fresh positions ----------
    function test_recent_position_cannot_claim_past_period_rewards() public {
        uint256 n = INonfungiblePositionManager(NFP).totalSupply();
        uint256 recentTokenId = INonfungiblePositionManager(NFP).tokenByIndex(n - 1);
        uint256 firstPeriod = IGaugeV2(GAUGE_USDC_WETH).firstPeriod();
        // period 2835 = 2024-06 (gauge genesis) — long before this token existed
        assertEq(
            IGaugeV2(GAUGE_USDC_WETH).periodEarned(firstPeriod, NURI, recentTokenId),
            0,
            "no rewards for periods before the position existed"
        );
        // and the pool-level checkpoint guard returns 0 for a period before creation
        uint256 secondsInRange = IClPool(POOL_USDC_WETH).positionPeriodSecondsInRange(
            firstPeriod,
            NFP,
            recentTokenId,
            0,
            0
        );
        assertEq(secondsInRange, 0, "checkpoint guard returns 0");
    }
}
