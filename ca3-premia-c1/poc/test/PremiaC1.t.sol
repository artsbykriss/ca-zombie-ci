// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IERC20, IPool, IPoolFactory, IVault, IOracleAdapter} from "../src/IPremia.sol";

/// @notice Premia V3 C-1 correction PoC.
///         Fork-only. No mainnet transaction is signed or broadcast.
///
/// Result proven here:
///   1. The 06 NOV 2026 08:00 UTC maturity is real and the factory is permissionless.
///   2. The six vaults' shorts sit in pools that the 2026-11-01 attack drained.
///   3. At the first post-expiry block, settle() reverts Pool__InsufficientFunds()
///      on all six vaults. trade(), deposit(), redeem() and withdraw() all call
///      _settle() first, so they revert too: the vaults are bricked.
///   4. To revive WBTC-C, an attacker must top up the three drained pools with
///      the full 3.8701 WBTC of unbacked collateral. The write premium on the
///      revived vault (~0.0625 WBTC) exceeds the only free value (~0.00077 WBTC),
///      so the revive is net-negative.
contract PremiaC1Test is Test {
    address constant FACTORY = 0xAE4fB6622F25f397587F11638dA8CE88C27b5645;
    address constant ORACLE = 0x68BDA63662b16550e86Ad16160625eb293AC3d5F;

    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant AWBTC = 0x078f358208685046a11C85e8ad32895DED33A249;

    address constant V_WBTC_C = 0x45dF5EA836A15B561937Ae8373ab9eE984aea531;
    address constant V_WETH_C = 0xbae43c546DFADC69576aE73C68e0694A54F08e1B;
    address constant V_WETH_P = 0xD46993F25D298ebbCD31E941156C66f7e628A52a;
    address constant V_WBTC_P = 0x6A1FC0E1c60BA6564CDe4910A425F1F1a1d18C1F;
    address constant V_ARB_C = 0xDC631d88dbB5eb39f5c4Bf8B4e5298d098912fFf;
    address constant V_ARB_P = 0xBe3E229319f86F5EE96EE1Dc0B6D55e8b68a439e;

    uint256 constant MATURITY_06NOV = 1793952000; // 2026-11-06 08:00:00 UTC
    uint256 constant MATURITY_13NOV = 1794556800; // 2026-11-13 08:00:00 UTC (Friday)
    uint256 constant POST_EXPIRY = 1793952001;    // first second after maturity
    uint256 constant SPOT = 77_308e18;            // Premia oracle spot used for the OTM settlement

    IPoolFactory constant factory = IPoolFactory(FACTORY);

    function setUp() public {
        string memory url = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://arb1.arbitrum.io/rpc";
        vm.createSelectFork(url);
    }

    function _key(
        address base,
        address quote,
        uint256 strike,
        uint256 maturity,
        bool isCall
    ) internal pure returns (IPoolFactory.PoolKey memory) {
        return IPoolFactory.PoolKey({
            base: base,
            quote: quote,
            oracleAdapter: ORACLE,
            strike: strike,
            maturity: maturity,
            isCallPool: isCall
        });
    }

    function _postExpiry() internal {
        vm.warp(POST_EXPIRY);
        vm.mockCall(
            ORACLE,
            abi.encodeWithSelector(IOracleAdapter.getPriceAt.selector),
            abi.encode(SPOT)
        );
    }

    /// 1. Permissionless factory: an arbitrary EOA can deploy a new pool.
    function test_factoryPermissionless() public {
        IPoolFactory.PoolKey memory k = _key(WBTC, USDC, 89_000e18, MATURITY_13NOV, true);
        vm.prank(address(0xBEEF));
        address pool = factory.deployPool(k);
        assertGt(pool.code.length, 0, "pool not deployed");
        (address got, bool deployed) = factory.getPoolAddress(k);
        assertEq(got, pool, "factory address mismatch");
        assertTrue(deployed, "isDeployed false");
    }

    /// 2. The six vaults settle at 06 NOV 2026 08:00 UTC but the drained pools cannot pay.
    function test_settleRevertsAllSix() public {
        _postExpiry();
        address[6] memory vaults = [V_WBTC_C, V_WETH_C, V_WETH_P, V_WBTC_P, V_ARB_C, V_ARB_P];
        for (uint256 i; i < vaults.length; i++) {
            vm.expectRevert(IPool.Pool__InsufficientFunds.selector);
            IVault(vaults[i]).settle();
        }
    }

    /// 3. trade() calls _settle() first, so the new-write attack is blocked.
    function test_tradeRevertsPostExpiry() public {
        _postExpiry();
        IPoolFactory.PoolKey memory k = _key(WBTC, USDC, 82_000e18, MATURITY_13NOV, true);
        vm.expectRevert(IPool.Pool__InsufficientFunds.selector);
        IVault(V_WBTC_C).trade(k, 1e12, true, type(uint256).max, address(0));
    }

    /// 4. Depositor exits also call _settle(), so H-O is zero too.
    function test_depositorExitReverts() public {
        _postExpiry();
        address me = address(0xA11CE);
        vm.startPrank(me);
        vm.expectRevert(IPool.Pool__InsufficientFunds.selector);
        IVault(V_WBTC_C).deposit(1e6, me);
        vm.expectRevert(IPool.Pool__InsufficientFunds.selector);
        IVault(V_WBTC_C).redeem(1e18, me, me);
        vm.expectRevert(IPool.Pool__InsufficientFunds.selector);
        IVault(V_WBTC_C).withdraw(1e6, me, me);
        vm.stopPrank();
    }

    /// 5. Revival economics for WBTC-C (analytical, using the measured quote).
    ///    To revive the vault the attacker must replace the full 3.8701 WBTC of
    ///    unbacked short collateral.  The write premium (all-in 1.616% at the
    ///    delta-0.2 strike 83,000 / 13 NOV, measured on the same snapshot) is
    ///    far larger than the only free value (vault balance + surviving pool
    ///    cash), so the revive is net-negative.
    function test_reviveWBTCNegative() public {
        _postExpiry();
        uint256 ta = IVault(V_WBTC_C).totalAssets();          // 8-dec
        bytes32 baseSlot = bytes32(uint256(keccak256("premia.contracts.storage.UnderwriterVaultStorage")));
        uint256 spread = uint256(vm.load(V_WBTC_C, bytes32(uint256(baseSlot) + 20))) / 1e10; // 8-dec
        uint256 real = IERC20(WBTC).balanceOf(V_WBTC_C);
        uint256 poolCash = IERC20(WBTC).balanceOf(_pool(78_000e18))
            + IERC20(WBTC).balanceOf(_pool(79_000e18))
            + IERC20(WBTC).balanceOf(_pool(80_000e18));

        // all-in premium rate 1.616% (premium + cLevel spread + 0.3% fee),
        // measured at 83,000e18 / 13 NOV 2026 in the analysis quote scan.
        uint256 premium8 = ((ta - spread) * 1616) / 100_000;

        emit log_named_uint("vault_real_wei", real);
        emit log_named_uint("pool_cash_wei", poolCash);
        emit log_named_uint("premium_lowerbound_wei", premium8);
        assertGt(premium8, real + poolCash, "revive was profitable");
    }

    function _pool(uint256 strike18) internal view returns (address) {
        return _poolMaturity(strike18, MATURITY_06NOV);
    }

    function _poolMaturity(uint256 strike18, uint256 maturity) internal view returns (address) {
        IPoolFactory.PoolKey memory k = _key(WBTC, USDC, strike18, maturity, true);
        (address p, bool deployed) = factory.getPoolAddress(k);
        require(deployed, "pool not deployed");
        return p;
    }

    /// Top up a drained call pool so that its short collateral can be paid.
    function _topUp(address pool, address vault, uint8 tokenDecimals, uint256 buffer) internal returns (uint256 need) {
        uint256 short18 = IPool(pool).balanceOf(vault, 0);
        uint256 collateralToken = short18 / (10 ** (18 - tokenDecimals));
        uint256 bal = IERC20(WBTC).balanceOf(pool);
        require(collateralToken > bal, "pool already backed");
        need = collateralToken - bal + buffer;
        vm.prank(AWBTC);
        IERC20(WBTC).transfer(pool, need);
    }

    /// 6. Incident reconciliation: the original attack net is ~$435.3k at the
    ///    2026-11-01 03:15 UTC prices, matching DefiLlama's $437k (0.4%).
    function test_incidentReconciliation() public {
        // token nets = gross ClaimFees - LP deposits - premium paid to the vault
        uint256 wbtcNet = 3.62485382e18;
        uint256 wethNet = 43.23754567731517e18;
        uint256 usdcNet = 48_229.408725e18;
        uint256 arbNet = 45_971.42861632883e18;

        // DefiLlama historical, 2026-11-01 ~03:15 UTC (18-dec USD prices)
        uint256 usd = (wbtcNet * 77_649_914_298_265_470_000_000) / 1e36;
        usd += (wethNet * 2_266_243_786_865_712_500_000) / 1e36;
        usd += (usdcNet * 1_000_067_061_117_909_000) / 1e36;
        usd += (arbNet * 164_915_882_659_396_270) / 1e36;

        emit log_named_uint("incident_net_usd", usd);
        assertGt(usd, 430_000, "below $430k");
        assertLt(usd, 445_000, "above $445k");
    }

    /// 7. The live implementation is 0xb539, not 0x81d9, and has no paused().
    function test_liveImplAndNoPause() public view {
        assertEq(IVault(V_WBTC_C).getImplementation(), 0xb539fF8563974D407Fd6d717ff2f930e99093d21);
        (bool ok, ) = V_WBTC_C.staticcall(abi.encodeWithSignature("paused()"));
        assertFalse(ok, "paused() exists");
    }
}
