// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* ------------------------------------------------------------------ */
/*  CGO Finance (Cronos chain 25) — CGOFarm / Cougar MasterChef fork  */
/*  Read-only fork PoC.  No real-chain transactions.                  */
/*  RPC-light by design: the CI fork RPC rate-limits (HTTP 429).      */
/* ------------------------------------------------------------------ */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function owner() external view returns (address);
    function mint(address, uint256) external;
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function swap(uint256, uint256, address, bytes calldata) external;
}

interface IStrategy {
    function wantAddress() external view returns (address);
    function sharesTotal() external view returns (uint256);
    function wantLockedTotal() external view returns (uint256);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function userLength() external view returns (uint256);
    function users(uint256) external view returns (address);
}

interface IFarm {
    function poolLength() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function owner() external view returns (address);
    function CGOToken() external view returns (address);
    function CGOPerBlock() external view returns (uint256);
    function startBlock() external view returns (uint256);
    function ownerCGOReward() external view returns (uint256);
    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256, address);
    function userInfo(uint256, address) external view returns (uint256, uint256);
    function pendingCGO(uint256, address) external view returns (uint256);
    function stakedWantTokens(uint256, address) external view returns (uint256);
    function updatePool(uint256) external;
    function massUpdatePools() external;
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function withdrawAll(uint256) external;
    function emergencyWithdraw(uint256) external;
    function add(uint256, address, bool, address) external;
    function set(uint256, uint256, bool) external;
    function inCaseTokensGetStuck(address, uint256) external;
    function updateStartBlock(uint256) external;
    function transferOwnership(address) external;
}

contract CGOFinanceTest is Test {
    address constant FARM = 0x5795BE23A2C330209849e0D1D19cc05755E23Ca2;
    address constant CGO  = 0x869c3e35Ef9E5F50003D9a2A80f1D61d670D4CB6;
    address constant WCRO = 0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23;
    address constant USDC = 0xc21223249CA28397B4B6541dfFaEcC539BfF0c59;
    address constant USDT = 0x66e428c3f67a68878562e79A0234c1F83c208770;
    address constant PAIR_CGO_USDC = 0x0803a4686800e30f0b4e310fCa1c6500953e1617;
    address constant PAIR_CGO_WCRO = 0xC794a7d974E5e8064FE59d4aabf78EA70F66c9c4;
    address constant PAIR_CGO_USDT = 0xF78D712E8cAc8c3A03119420C056940Ea0BEF447;
    address constant PAIR_VVS   = 0xF06abc17073c23b90b76Fa95Dd3D4f1373248ffa;
    address constant PAIR_CRONA = 0xDF949c0434Bd58A6A99B1dCBc63951Fb4aeE3307;

    address constant ATK = address(0xA77ACCE5);
    uint256 constant WCRO_PRICE_6DP = 54489;          // $0.0544889
    // CGO ERC20: _balances is storage slot 0 (verified: keccak(abi.encode(farm,0)) == farm balance)
    uint256 constant CGO_BAL_SLOT = 0;
    // 6 dormant pool-2 stakers found off-chain (analysis/dormant_stakers.json)
    address[6] DORMANT2 = [
        0x5Be4A5705e4fd2e842B3F95BBd24e1b2776E7cC2,
        0x07C5959D4408a37E71ee56589B77499DAa54F182,
        0x3E93f47B2a11c6b5Df6463bD03Aaca0Ba02f884A,
        0x77984Dc88AaB3D9c843256d7AaBDc82540c94F69,
        0x71404b6aa76F4b0FDF42b5D6A92a0a891C65fb50,
        0x1C4A3D02850a4c705644C9D0d7dbeCb434FbAeA5
    ];

    IFarm farm = IFarm(FARM);
    IERC20 cgo = IERC20(CGO);

    function setUp() public {
        string memory url = vm.envOr("CRONOS_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://evm.cronos.org";
        vm.createSelectFork(url);
    }

    /* ---------------- helpers ---------------- */

    function pairOut(address pair, address tokenIn, uint256 amountIn)
        internal view returns (uint256 out, uint256 outIdx)
    {
        IPair p = IPair(pair);
        address t0 = p.token0();
        (uint112 r0, uint112 r1,) = p.getReserves();
        uint256 rin  = tokenIn == t0 ? r0 : r1;
        uint256 rout = tokenIn == t0 ? r1 : r0;
        outIdx = tokenIn == t0 ? 1 : 0;
        uint256 inWithFee = amountIn * 997;
        out = (inWithFee * rout) / (rin * 1000 + inWithFee);
    }

    function sellCGO(address pair, uint256 amountIn) internal returns (uint256 out) {
        cgo.transfer(pair, amountIn);
        uint256 outIdx;
        (out, outIdx) = pairOut(pair, CGO, amountIn);
        if (outIdx == 0) IPair(pair).swap(out, 0, ATK, "");
        else             IPair(pair).swap(0, out, ATK, "");
    }

    function giveCGO(address to, uint256 amount) internal {
        vm.store(CGO, keccak256(abi.encode(to, CGO_BAL_SLOT)), bytes32(amount));
    }

    /* ---------------- 1. exit liquidity ---------------- */

    function test_01_CGO_exit_liquidity() public {
        (uint256 outUsdc,)  = pairOut(PAIR_CGO_USDC, CGO, 500_000_000e18);
        (uint256 outWcro,)  = pairOut(PAIR_CGO_WCRO, CGO, 500_000_000e18);
        (uint256 outUsdt,)  = pairOut(PAIR_CGO_USDT, CGO, 500_000_000e18);
        uint256 usd6 = outUsdc                        // USDC 6dp ~ $1
                     + (outWcro * WCRO_PRICE_6DP) / 1e18  // WCRO 18dp -> USD 6dp
                     + outUsdt;                       // USDT 6dp ~ $1
        emit log_named_uint("USDC out (6dp)", outUsdc);
        emit log_named_uint("WCRO out (18dp)", outWcro);
        emit log_named_uint("WCRO->USD (6dp)", (outWcro * WCRO_PRICE_6DP) / 1e18);
        emit log_named_uint("USDT out (6dp)", outUsdt);
        emit log_named_uint("TOTAL exit USD (6dp)", usd6);
        assertLt(usd6, 2_000_000_000, "CGO exit liquidity under $2000");
    }

    /* ---------------- 2. best-case dump of the farm's CGO ---------------- */

    function test_02_dump_farm_CGO_into_pairs() public {
        uint256 farmCgo = cgo.balanceOf(FARM);
        emit log_named_uint("farm CGO balance", farmCgo);
        giveCGO(ATK, farmCgo);
        assertEq(cgo.balanceOf(ATK), farmCgo, "attacker funded with the farm's whole CGO");

        vm.startPrank(ATK);
        sellCGO(PAIR_CGO_USDC, farmCgo / 2);
        sellCGO(PAIR_CGO_WCRO, farmCgo / 2);
        vm.stopPrank();

        uint256 usdcGain = IERC20(USDC).balanceOf(ATK);
        uint256 wcroGain = IERC20(WCRO).balanceOf(ATK);
        uint256 usd6 = usdcGain + (wcroGain * WCRO_PRICE_6DP) / 1e18;
        emit log_named_uint("USDC gained (6dp)", usdcGain);
        emit log_named_uint("WCRO gained (18dp)", wcroGain);
        emit log_named_uint("TOTAL gained USD (6dp)", usd6);
        assertLt(usd6, 2_000_000_000, "dumping ALL farm CGO yields < $2000");
    }

    /* ---------------- 3. permissionless mint ---------------- */

    function test_03_permissionless_mint() public {
        uint256 supplyBefore = cgo.totalSupply();
        uint256 farmBefore   = cgo.balanceOf(FARM);
        uint256 ownerBefore  = cgo.balanceOf(farm.owner());
        uint256 atkBefore    = cgo.balanceOf(ATK);

        vm.prank(ATK);
        farm.updatePool(2);                       // stale since block 43,036,337

        uint256 minted = cgo.totalSupply() - supplyBefore;
        emit log_named_uint("CGO minted by attacker updatePool(2)", minted);
        emit log_named_uint("farm CGO delta", cgo.balanceOf(FARM) - farmBefore);
        emit log_named_uint("owner CGO delta", cgo.balanceOf(farm.owner()) - ownerBefore);
        assertGt(minted, 1e25, "permissionless mint of >10M CGO");
        assertEq(cgo.balanceOf(ATK), atkBefore, "caller receives no CGO");

        // does the whole-farm sweep still work? (informational)
        vm.prank(ATK);
        try farm.massUpdatePools() { emit log("massUpdatePools() SUCCEEDED for the attacker"); }
        catch (bytes memory r) { emit log_named_bytes("massUpdatePools revert data", r); }
    }

    /* ---------------- 4. admin gating ---------------- */

    function test_04_admin_functions_are_onlyOwner() public {
        vm.startPrank(ATK);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.add(1, CGO, false, ATK);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.set(0, 1, false);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.inCaseTokensGetStuck(CGO, 1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.updateStartBlock(1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        farm.transferOwnership(ATK);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        cgo.mint(ATK, 1e18);
        vm.stopPrank();
    }

    /* ---------------- 5. deposit/withdraw round trip ---------------- */

    function test_05_deposit_withdraw_roundtrip_no_profit() public {
        giveCGO(ATK, 1_000e18);
        uint256 before = cgo.balanceOf(ATK);
        assertEq(before, 1_000e18, "attacker funded");

        vm.startPrank(ATK);
        cgo.approve(FARM, type(uint256).max);
        try farm.deposit(0, 1_000e18) {
            (uint256 shares,) = farm.userInfo(0, ATK);
            emit log_named_uint("shares after deposit", shares);
            emit log_named_uint("pending right after deposit", farm.pendingCGO(0, ATK));
        } catch (bytes memory r) { emit log_named_bytes("deposit(0) revert data", r); }
        vm.stopPrank();

        vm.warp(block.timestamp + 20 days);
        // withdrawAll() is nonReentrant and calls withdraw() (also nonReentrant) -> always reverts
        vm.prank(ATK);
        try farm.withdrawAll(0) { emit log("withdrawAll(0) SUCCEEDED"); }
        catch (bytes memory r) { emit log_named_bytes("withdrawAll(0) revert data", r); }

        // the real withdraw path
        (uint256 sh,) = farm.userInfo(0, ATK);
        vm.prank(ATK);
        try farm.withdraw(0, sh) { emit log("withdraw(0,shares) SUCCEEDED"); }
        catch (bytes memory r) { emit log_named_bytes("withdraw(0,shares) revert data", r); }

        uint256 after_ = cgo.balanceOf(ATK);
        emit log_named_uint("CGO before", before);
        emit log_named_uint("CGO after ", after_);
        assertLe(after_, before, "round trip yields no profit");
    }

    /* ---------------- 6. backdated mint is not capturable ---------------- */

    function test_06_backdated_mint_not_capturable() public {
        (,, uint256 lrb,,) = farm.poolInfo(2);
        emit log_named_uint("pool2 lastRewardBlock", lrb);
        emit log_named_uint("current block", block.number);
        assertLt(lrb, block.number - 1_000_000, "pool 2 is stale by >1M blocks");

        vm.prank(ATK);
        farm.updatePool(2);                        // triggers the accrual

        // a fresh depositor, after the accrual, has rewardDebt snapshotted -> 0 pending
        (address want,,,, ) = farm.poolInfo(2);
        deal(want, ATK, 1e15);
        vm.startPrank(ATK);
        IERC20(want).approve(FARM, type(uint256).max);
        farm.deposit(2, 1e15);
        uint256 pending = farm.pendingCGO(2, ATK);
        vm.stopPrank();
        emit log_named_uint("pending after depositing post-accrual", pending);
        assertEq(pending, 0, "backdated rewards not capturable by a fresh depositor");
    }

    /* ---------------- 7. dormant stakers hold unharvested CGO ---------------- */

    function test_07_dormant_stakers_have_pending() public {
        uint256 total;
        for (uint256 i = 0; i < DORMANT2.length; i++) {
            uint256 p = farm.pendingCGO(2, DORMANT2[i]);
            emit log_named_uint("dormant pool-2 pendingCGO", p);
            total += p;
        }
        emit log_named_uint("pool-2 dormant pendingCGO total", total);
        assertGt(total, 1e25, "dormant holders hold >10M CGO of unharvested rewards (H-O)");
    }

    /* ---------------- 8. emergencyWithdraw with no shares ---------------- */

    function test_08_emergencyWithdraw_no_shares_reverts() public {
        vm.prank(ATK);
        vm.expectRevert();
        farm.emergencyWithdraw(0);
    }

    /* ---------------- 9. farm holds no want tokens (sampled) ---------------- */

    function test_09_farm_holds_only_CGO() public {
        uint256[5] memory pids = [uint256(1), 2, 3, 5, 8];
        for (uint256 i = 0; i < pids.length; i++) {
            (address want,,,, ) = farm.poolInfo(pids[i]);
            uint256 b = IERC20(want).balanceOf(FARM);
            emit log_named_uint("farm want balance", b);
            assertEq(b, 0, "farm holds no staked want");
        }
        assertEq(cgo.balanceOf(FARM), 41825492335644395205316990, "farm's only asset is CGO");
    }

    /* ---------------- 10. strategies are farm-owned and live ---------------- */

    function test_10_strategies_owned_by_farm() public {
        uint256[5] memory pids = [uint256(0), 1, 2, 3, 5];
        for (uint256 i = 0; i < pids.length; i++) {
            (,,,, address strat) = farm.poolInfo(pids[i]);
            assertEq(IStrategy(strat).owner(), FARM, "strategy owned by farm");
            assertFalse(IStrategy(strat).paused(), "strategy live");
        }
    }
}
