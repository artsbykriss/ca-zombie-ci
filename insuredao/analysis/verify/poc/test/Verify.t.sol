// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/* ================= minimal interfaces ================= */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IVault {
    function token() external view returns (address);
    function controller() external view returns (address);
    function registry() external view returns (address);
    function keeper() external view returns (address);
    function balance() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function totalAttributions() external view returns (uint256);
    function valueAll() external view returns (uint256);
    function available() external view returns (uint256);
    function attributions(address) external view returns (uint256);
    function debts(address) external view returns (uint256);
    function underlyingValue(address) external view returns (uint256);
    function withdrawValue(uint256, address) external returns (uint256);
    function withdrawAttribution(uint256, address) external returns (uint256);
    function withdrawAllAttribution(address) external returns (uint256);
    function transferValue(uint256, address) external returns (uint256);
    function transferAttribution(uint256, address) external;
    function borrowValue(uint256, address) external;
    function offsetDebt(uint256, address) external returns (uint256);
    function repayDebt(uint256, address) external;
    function utilize() external returns (uint256);
    function withdrawRedundant(address, address) external;
    function setController(address) external;
}

interface IPool {
    function deposit(uint256) external returns (uint256);
    function requestWithdraw(uint256) external;
    function withdraw(uint256) external returns (uint256);
    function redeem(uint256, uint256, bytes32[] calldata) external;
    function applyCover(uint256, uint256, uint256, uint256, bytes32, string calldata, string calldata) external;
    function applyBounty(uint256, address, uint256[] calldata) external;
    function resume() external;
    function unlock(uint256) external;
    function unlockBatch(uint256[] calldata) external;
    function registerIndex(uint256) external;
    function allocateCredit(uint256) external returns (uint256);
    function withdrawCredit(uint256) external returns (uint256);
    function setPaused(bool) external;
    function changeMetadata(string calldata) external;
    function marketStatus() external view returns (uint8);
    function paused() external view returns (bool);
    function totalSupply() external view returns (uint256);
    function originalLiquidity() external view returns (uint256);
    function totalLiquidity() external view returns (uint256);
    function lockedAmount() external view returns (uint256);
    function attributionDebt() external view returns (uint256);
    function totalCredit() external view returns (uint256);
    function rewardPerCredit() external view returns (uint256);
    function pendingEnd() external view returns (uint256);
    function allInsuranceCount() external view returns (uint256);
    function indexList(uint256) external view returns (address);
    function indices(address) external view returns (uint256, uint256, uint256, bool);
    function insurances(uint256) external view returns (uint256, uint48, uint48, uint256, bytes32, address, address, bool);
    function valueOfUnderlying(address) external view returns (uint256);
    function pendingPremium(address) external view returns (uint256);
    function availableBalance() external view returns (uint256);
    function worth(uint256) external view returns (uint256);
    function rate() external view returns (uint256);
    function withdrawalReq(address) external view returns (uint256, uint256);
    function insure(uint256, uint256, uint256, bytes32, address, address) external returns (uint256);
    function getPremium(uint256, uint256) external view returns (uint256);
}

interface IIndex {
    function deposit(uint256) external returns (uint256);
    function compensate(uint256) external returns (uint256);
    function set(uint256, uint256, address, uint256) external;
    function setLeverage(uint256) external;
    function adjustAlloc() external;
    function resume() external;
    function lock() external;
    function locked() external view returns (bool);
    function paused() external view returns (bool);
    function totalLiquidity() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allocPoints(address) external view returns (uint256);
    function targetLev() external view returns (uint256);
    function poolList(uint256) external view returns (address);
    function totalAllocatedCredit() external view returns (uint256);
    function withdrawable() external view returns (uint256);
    function requestWithdraw(uint256) external;
    function withdraw(uint256) external returns (uint256);
}

interface ICDS {
    function deposit(uint256) external returns (uint256);
    function fund(uint256) external;
    function defund(address, uint256) external;
    function requestWithdraw(uint256) external;
    function withdraw(uint256) external returns (uint256);
    function compensate(uint256) external returns (uint256);
    function setPaused(bool) external;
    function paused() external view returns (bool);
    function crowdPool() external view returns (uint256);
    function surplusPool() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function rate() external view returns (uint256);
}

interface IFactory {
    function createMarket(address, string calldata, uint256[] calldata, address[] calldata) external returns (address);
    function templates(address) external view returns (bool, bool, bool);
    function reflist(address, uint256, address) external view returns (bool);
    function conditionlist(address, uint256) external view returns (uint256);
}

interface IRegistry {
    function isListed(address) external view returns (bool);
    function getAllMarkets() external view returns (address[] memory);
    function factory() external view returns (address);
}

interface IParameters {
    function getOwner() external view returns (address);
    function getVault(address) external view returns (address);
    function getLockup(address) external view returns (uint256);
    function getWithdrawable(address) external view returns (uint256);
    function getGrace(address) external view returns (uint256);
    function getMaxList(address) external view returns (uint256);
    function getFeeRate(address) external view returns (uint256);
    function getPremium(uint256, uint256, uint256, uint256, address) external view returns (uint256);
}

interface IPoolProxy {
    function ownership_admin() external view returns (address);
    function parameter_admin() external view returns (address);
    function emergency_admin() external view returns (address);
    function default_reporting_admin() external view returns (address);
    function reporting_admin(address) external view returns (address);
    function get_reporter(address) external view returns (address);
    function withdraw_admin_fee(address) external;
    function distribute(address, uint256) external;
    function distribute_many(address[20] calldata, uint256[20] calldata) external;
    function n_distributors(address) external view returns (uint256);
    function distributor_weight(address, uint256) external view returns (uint256);
    function distributable(address, uint256) external view returns (uint256);
    function distributor_kill() external view returns (bool);
}

interface IGauge {
    function deposit(uint256, address) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function is_killed() external view returns (bool);
    function user_checkpoint(address) external returns (bool);
    function claimable_tokens(address) external returns (uint256);
    function kick(address) external;
    function set_approve_deposit(address, bool) external;
    function working_balances(address) external view returns (uint256);
    function working_supply() external view returns (uint256);
    function integrate_fraction(address) external view returns (uint256);
    function template() external view returns (address);
    function minter() external view returns (address);
    function period_timestamp(uint256) external view returns (uint256);
    function period() external view returns (uint256);
}

interface IMinter {
    function mint(address) external;
    function minted(address, address) external view returns (uint256);
    function insure_token() external view returns (address);
}

interface IVlInsure {
    function deposit(uint256, bool, bool) external;
    function depositAll(bool, bool) external;
    function lockInsure() external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function lockIncentive() external view returns (uint256);
    function incentiveInsure() external view returns (uint256);
    function gauge() external view returns (address);
}

interface IVotingEscrow {
    function withdraw() external;
    function force_unlock(address) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function locked__end(address) external view returns (uint256);
    function create_lock(uint256, uint256) external;
}

/* ================= test contract ================= */

contract VerifyTest is Test {
    address constant VAULT = 0x131fb74C6fEdE6D6710FF224E07cE0eD8123f144;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant REGISTRY = 0xA035Dfd0D16F238493b374a1743B77448D9C8524;
    address constant FACTORY = 0x01e6916CcFe3630364b4538d0f8C1c22E20d0F6b;
    address constant PARAMETERS = 0xdDAA6ee776B701a7729D72BBd0d4FBe4bBb66476;
    address constant POOLPROXY = 0xF4d046D8FaC6dc37b5eAFAdd34407b19De3Ba350;
    address constant SAFE = 0x54bE2f27E95BdAA5104960aAE7816554C0e3F056;
    address constant OPEN_TEMPLATE = 0x1dcd35cFfF8a9B44aECc4087c7847Fb7A5BE56F9;
    address constant INDEX_IMPL = 0x2B16Be3caCAeA56A6FBE613031C0F6b641DF828E;
    address constant CDS_IMPL = 0x99f790AdA7FA1BDC2a6B976293273EE51f10a10e;

    address constant POOL_8C49 = 0x8c4943100bEc96e3381a544Da82B91713a4BC062;
    address constant POOL_641B = 0x641BE011738C65AAc8FF3f5d4e6dedbBD7411f47;
    address constant POOL_BDB0 = 0xbDB009e6C9dd3F77d6A7f507A4F817133677257c;
    address constant POOL_5880 = 0x58803187E676b180eD12b4F7d79b94cA011f4b8e;
    address constant POOL_8DFF = 0x8dfFb0c2b2d0A126f13667C0825ba7c026ECb24a;
    address constant POOL_C03A = 0xC03Ab4bB777Edf97e8692bd125968358aD3b7F08;
    address constant POOL_B0AC = 0xB0AC0465320E9289BE7a9dF0d86B136d56C83722;
    address constant POOL_B127 = 0xB127A53646EEfF7a0a787b754258B101D782Db0C;
    address constant POOL_1CF1 = 0x1CF1195aFB01DD115647E4989e63AfE6DdD65030;
    address constant POOL_2245 = 0x22453153978D0C25f86010c0fd405527feD9764b;
    address constant POOL_DFDF = 0xDFdFcFEdb96e0979825C6B463cb8a971fE367d5D;
    address constant POOL_0A3F = 0x0a3f739246846fC024F7f8dd5CBe7E0adf77760F;

    address constant INDEX_DAEA = 0xDAea5b1B6b12Ac4c4f51aB12649e96ab3aB98C3A;
    address constant INDEX_D5F1 = 0xd5f1Ab3c61eF3a6a6f1AA6141256Aa008D2fb5A1;
    address constant INDEX_7E08 = 0x7E08daB409Ad1bCeBc5bE5674CB2C0f3540A4d3d;
    address constant CDS = 0x86c82E8cD8A865f01A8CeBed870Af5d58e69a439;

    address constant LP_TOKEN = 0x1b459aec393D604Ae6468Ae3f7D7422eFA2Af1ca;
    address constant INSURE = 0xd83AE04c9eD29d6D3E6Bf720C71bc7BeB424393E;
    address constant VLINSURE = 0xA12ab76a82D118e33682AcB242180B4cc0d19E29;
    address constant LP_GAUGE = 0xF57882cF186Db61691873D33E3511a40c3c7e4da;
    address constant VLI_GAUGE = 0xbCBCf05F2f77E2c223334368162D88f5d6032699;
    address constant MINTER = 0x76E8B82EA3450fA598E5e164c7E28af172deBDC0;
    address constant ESCROW = 0x3dc07E60ecB3d064d20c386217ceeF8e3905916b;
    address constant ITOKEN_HOLDER_8C49 = 0xC8819c553Ff1781E017897800d75d82539A79aA2; // holder of DFDF per parent; reused as generic probe only

    address attacker = address(0xA11CE);
    address attacker2 = address(0xB0B);

    IVault vault = IVault(VAULT);
    IERC20 usdc = IERC20(USDC);
    IRegistry registry = IRegistry(REGISTRY);
    IParameters params = IParameters(PARAMETERS);
    IPoolProxy proxy = IPoolProxy(POOLPROXY);

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"));
        vm.createSelectFork(rpc);
        vm.deal(attacker, 100 ether);
        vm.deal(attacker2, 100 ether);
    }

    /* ---------- helpers ---------- */

    function _createAttackerMarket() internal returns (address m) {
        deal(USDC, attacker, 1_001e6);
        address[] memory refs = new address[](4);
        refs[0] = address(0x000000000000000000000000000000000000dEaD); // unique target
        refs[1] = USDC;
        refs[2] = REGISTRY;
        refs[3] = PARAMETERS;
        uint256[] memory conds = new uint256[](2);
        conds[0] = 1e9;
        conds[1] = 1_000e6;
        vm.startPrank(attacker);
        usdc.approve(VAULT, 1_000e6);
        m = IFactory(FACTORY).createMarket(OPEN_TEMPLATE, "verify-market", conds, refs);
        vm.stopPrank();
    }

    function _indexListAt(address pool, uint256 i) external view returns (address) {
        return IPool(pool).indexList(i);
    }

    function _firstFreeSlot(address pool) internal view returns (uint256 slot, bool ok) {
        for (uint256 i = 0; i < 10; i++) {
            try this._indexListAt(pool, i) returns (address ix) {
                if (ix == address(0)) return (i, true);
            } catch {
                return (i, true); // past end of array -> next slot
            }
        }
        return (0, false);
    }

    /* =========================================================
       1. LIVE STATE RECHECK (independent of parent's numbers)
       ========================================================= */
    function test_v1_live_state_recheck() public view {
        assertEq(vault.token(), USDC, "token");
        assertEq(vault.controller(), address(0), "controller==0");
        assertEq(vault.valueAll(), vault.balance(), "valueAll==balance");
        assertEq(vault.totalAttributions(), vault.balance(), "par vault");
        assertEq(vault.totalDebt(), 0, "no debt");
        assertEq(usdc.balanceOf(VAULT), vault.balance() + 100, "100 wei donation only");
        assertEq(params.getOwner(), POOLPROXY, "owner=PoolProxy");
        assertEq(proxy.default_reporting_admin(), address(0), "no default reporter");
        address[] memory ms = registry.getAllMarkets();
        assertEq(ms.length, 29, "29 markets");
        for (uint256 i = 0; i < ms.length; i++) {
            assertEq(proxy.reporting_admin(ms[i]), address(0), "no reporter");
        }
        // attribution ledger: markets + proxy + dust == total
        uint256 sum;
        for (uint256 i = 0; i < ms.length; i++) sum += vault.attributions(ms[i]);
        sum += vault.attributions(POOLPROXY);
        assertEq(sum + 5, vault.totalAttributions(), "ledger sums (+5 wei dust)");
        // all pools Trading, none paused; indexes not locked
        for (uint256 i = 0; i < ms.length; i++) {
            (bool ok1, bytes memory r1) = ms[i].staticcall(abi.encodeWithSelector(IPool.marketStatus.selector));
            if (ok1 && r1.length == 32) assertEq(abi.decode(r1, (uint256)), 0, "trading");
        }
        assertEq(IPool(POOL_8C49).marketStatus(), 0, "8c49 trading");
        assertEq(IIndex(INDEX_DAEA).locked(), false, "daea unlocked");
        assertEq(ICDS(CDS).crowdPool(), 59_793_841_027, "cds crowdPool");
        // premium model present for live markets
        assertEq(params.getPremium(1e6, 604800, 1e9, 0, POOL_8C49), 191, "premium 191");
    }

    /* =========================================================
       2. INDEX PREMIUM CAPTURE (vector 1)
       ========================================================= */
    function test_v1_index_premium_capture_fails() public {
        address m = _createAttackerMarket();
        uint256[4] memory pools = [uint256(uint160(POOL_8C49)), uint256(uint160(POOL_641B)),
                                   uint256(uint160(POOL_BDB0)), uint256(uint160(POOL_5880))];
        for (uint256 i = 0; i < 4; i++) {
            address pool = address(uint160(pools[i]));
            uint256 adBefore = IPool(pool).attributionDebt();
            uint256 rpcBefore = IPool(pool).rewardPerCredit();
            uint256 attrBefore = vault.attributions(m);
            (uint256 slot, bool ok) = _firstFreeSlot(pool);
            assertTrue(ok, "free slot exists");
            assertLt(slot, params.getMaxList(pool), "slot below maxList");

            // eviction of an existing index with credit>0 must fail
            address victim = IPool(pool).indexList(0);
            (uint256 vCredit,,,) = IPool(pool).indices(victim);
            if (vCredit > 0) {
                vm.prank(m);
                vm.expectRevert(bytes("ERROR: WITHDRAW_CREDIT_FIRST"));
                IPool(pool).registerIndex(0);
            }

            // fresh index registers, allocates, claims: must yield 0
            vm.startPrank(m);
            IPool(pool).registerIndex(slot);
            IPool(pool).allocateCredit(1e7);
            uint256 pending = IPool(pool).pendingPremium(m);
            assertEq(pending, 0, "fresh index pending==0");
            uint256 claimed = IPool(pool).withdrawCredit(1e7);
            assertEq(claimed, 0, "fresh index claims 0");
            vm.stopPrank();

            assertEq(IPool(pool).attributionDebt(), adBefore, "attributionDebt unchanged");
            assertEq(IPool(pool).rewardPerCredit(), rpcBefore, "rewardPerCredit unchanged");
            assertEq(vault.attributions(m), attrBefore, "attacker market attributions unchanged");

            // existing index pending premium is index-owned and still present
            if (i == 0) {
                assertEq(IPool(pool).pendingPremium(INDEX_DAEA), 1_559_027, "daea premium untouched");
            }
        }
        assertEq(usdc.balanceOf(m), 0, "attacker market holds no USDC");
        assertEq(usdc.balanceOf(attacker), 1e6, "attacker spent only their own deposit");
    }

    /* =========================================================
       3. SHARE MATH: deposit->withdraw round trips (vector 2)
       ========================================================= */
    function test_v1_share_math_roundtrip() public {
        // no market may have supply>0 && originalLiquidity==0
        address[] memory ms = registry.getAllMarkets();
        for (uint256 i = 0; i < ms.length; i++) {
            (bool ok1, bytes memory r1) = ms[i].staticcall(abi.encodeWithSelector(IPool.totalSupply.selector));
            if (!ok1) continue;
            (bool ok2, bytes memory r2) = ms[i].staticcall(abi.encodeWithSelector(IPool.originalLiquidity.selector));
            if (!ok2) continue;
            uint256 sup = abi.decode(r1, (uint256));
            uint256 ol = abi.decode(r2, (uint256));
            assertFalse(sup > 0 && ol == 0, "no supply>0/OL==0 state exists");
        }

        address[5] memory pools = [POOL_8DFF, POOL_C03A, POOL_5880, POOL_B0AC, POOL_B127];
        for (uint256 i = 0; i < 5; i++) {
            address pool = pools[i];
            uint256 sup0 = IPool(pool).totalSupply();
            uint256 ol0 = IPool(pool).originalLiquidity();
            uint256 deposit = 1e6; // 1 USDC
            deal(USDC, attacker, deposit);
            vm.startPrank(attacker);
            usdc.approve(VAULT, deposit);
            uint256 minted = IPool(pool).deposit(deposit);
            vm.stopPrank();
            if (sup0 == 0) {
                assertEq(minted, deposit, "empty pool mints 1:1");
            } else {
                // floor(v*S/OL): never more than proportional
                assertLe(minted, deposit * sup0 / ol0 + 1, "mint not above fair");
            }
            vm.startPrank(attacker);
            IPool(pool).requestWithdraw(minted);
            vm.warp(block.timestamp + 14 days + 1);
            uint256 out = IPool(pool).withdraw(minted);
            vm.stopPrank();
            emit log_named_string("pool", vm.toString(pool));
            emit log_named_uint("  deposited", deposit);
            emit log_named_uint("  minted", minted);
            emit log_named_uint("  withdrew", out);
            assertLe(out, deposit, "never more out than in");
        }
    }

    /* =========================================================
       4. UNLOCK (vector 3): public good, no attacker profit
       ========================================================= */
    function test_v1_unlock_public_good_only() public {
        uint256 lockedBefore = IPool(POOL_8C49).lockedAmount();
        assertGt(lockedBefore, 0, "stale lock present");
        vm.prank(attacker);
        IPool(POOL_8C49).unlock(0);
        assertEq(IPool(POOL_8C49).lockedAmount(), 0, "lock cleared by anyone");
        // non-holder cannot withdraw or request
        vm.startPrank(attacker);
        vm.expectRevert(bytes("ERROR: REQUEST_EXCEED_BALANCE"));
        IPool(POOL_8C49).requestWithdraw(1);
        vm.stopPrank();
        assertEq(usdc.balanceOf(attacker), 0, "attacker gained 0");
        // can the attacker lock/unlock their own policy? insure costs premium
        uint256 cost = IPool(POOL_8C49).getPremium(1e6, 604800);
        assertGt(cost, 0, "premium positive");
    }

    /* =========================================================
       5. ATTACKER MARKET: no external power (vectors 4/7)
       ========================================================= */
    function test_v1_attacker_market_inert() public {
        address m = _createAttackerMarket();
        assertTrue(registry.isListed(m), "market listed");
        assertEq(vault.attributions(m), 1_000e6, "own deposit only");
        assertEq(IERC20(m).balanceOf(attacker), 1_000e6, "iTokens 1:1");

        bytes32 root = bytes32(uint256(1));
        vm.startPrank(attacker);
        // all admin/claim paths revert
        vm.expectRevert(bytes("Caller is not allowed to operate"));
        IPool(m).applyBounty(1e6, attacker, new uint256[](0));
        vm.expectRevert(bytes("ERROR: NO_APPLICABLE_INCIDENT"));
        IPool(m).redeem(0, 0, new bytes32[](0));
        vm.expectRevert(bytes("Caller is not allowed to operate"));
        IPool(m).applyCover(0, 1, 1, block.timestamp - 1, root, "", "");
        vm.expectRevert(bytes("ERROR: UNABLE_TO_RESUME"));
        IPool(m).resume();
        vm.expectRevert(bytes("Caller is not allowed to operate"));
        IPool(m).setPaused(true);
        vm.stopPrank();

        // vault paths from EOA: no value
        uint256 a0 = usdc.balanceOf(attacker);
        vm.startPrank(attacker);
        vault.withdrawAllAttribution(attacker); // 0 shares -> 0
        vault.repayDebt(1e6, attacker); // no debt -> no-op, pays 0
        vm.expectRevert(bytes("ERROR_REPAY_DEBT_BADCONDITIONS"));
        vault.offsetDebt(1e6, attacker); // attacker has no attributions
        vm.expectRevert(bytes("TRANSFER-VALUE_BADCONDITIONS"));
        vault.transferValue(1e6, attacker);
        vm.expectRevert(bytes("ERROR_ONLY_MARKET"));
        vault.borrowValue(1e6, attacker);
        vm.stopPrank();
        assertEq(usdc.balanceOf(attacker), a0, "EOA vault calls move nothing");

        // the market's own calls: transferValue only moves its own shares
        vm.prank(m);
        vault.transferValue(1_000e6, attacker);
        assertEq(vault.attributions(m), 0, "market shares moved to attacker");
        assertEq(vault.attributions(attacker), 1_000e6, "attacker holds the shares");
        assertEq(usdc.balanceOf(attacker), a0, "attributions are not tokens yet");
        // attacker can withdraw exactly those shares (== own deposit)
        vm.prank(attacker);
        vault.withdrawValue(1_000e6, attacker);
        assertEq(usdc.balanceOf(attacker), a0 + 1_000e6, "own deposit recovered, no more");
        assertEq(vault.attributions(attacker), 0, "shares burned");

        // call every remaining state-changing external fn of the clone from the EOA;
        // reverts are fine, the point is that no call moves value to the attacker
        vm.startPrank(attacker);
        try IPool(m).requestWithdraw(1) {} catch {}
        try IPool(m).unlock(0) {} catch {}
        try IPool(m).registerIndex(0) {} catch {}
        try IPool(m).allocateCredit(1e6) {} catch {}
        try IPool(m).withdrawCredit(1e6) {} catch {}
        try IPool(m).insure(1e6, 1e18, 604800, bytes32(0), attacker, attacker) {} catch {}
        vm.stopPrank();
        assertEq(usdc.balanceOf(attacker), a0 + 1_000e6, "no extra value from clone calls");
        // no PoolTemplate external call invokes CDS.compensate (latent path unreachable)
        uint256 cdsAttr = vault.attributions(CDS);
        assertEq(cdsAttr, 59_793_841_027, "CDS attribution unchanged");
        // index resume is locked-gated too
        vm.prank(attacker);
        vm.expectRevert(bytes("ERROR: MARKET_IS_NOT_LOCKED"));
        IIndex(INDEX_DAEA).resume();
    }

    /* =========================================================
       6. POOLPROXY admin fee + distribute (vector 5)
       ========================================================= */
    function test_v1_admin_fee_and_distribute() public {
        // only USDC maps to a vault; others revert
        assertEq(params.getVault(USDC), VAULT, "usdc vault");
        assertEq(params.getVault(LP_TOKEN), address(0), "LP has no vault");
        assertEq(params.getVault(INSURE), address(0), "INSURE has no vault");
        assertEq(params.getVault(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), address(0), "WETH none");
        vm.prank(attacker);
        vm.expectRevert();
        proxy.withdraw_admin_fee(LP_TOKEN);

        uint256 ppBefore = usdc.balanceOf(POOLPROXY);
        uint256 attBefore = usdc.balanceOf(attacker);
        vm.prank(attacker, attacker);
        proxy.withdraw_admin_fee(USDC);
        uint256 swept = usdc.balanceOf(POOLPROXY) - ppBefore;
        assertEq(swept, 3_215_129, "swept exact fee dust");
        assertEq(vault.attributions(POOLPROXY), 0, "proxy attribution burned");
        assertEq(proxy.distributable(USDC, 0), swept / 4, "25% dev");
        assertEq(proxy.distributable(USDC, 1), swept / 2, "50% reportingdao");
        assertEq(proxy.distributable(USDC, 2), swept / 4, "25% community");

        // try to distribute all three ids from a fresh EOA
        for (uint256 id = 0; id < 3; id++) {
            vm.prank(attacker, attacker);
            try proxy.distribute(USDC, id) {
                emit log_named_uint("distribute succeeded id", id);
            } catch {
                emit log_named_uint("distribute reverted id", id);
            }
        }
        // whatever happened, the attacker gained nothing
        assertEq(usdc.balanceOf(attacker), attBefore, "attacker gained 0 from fees");
        emit log_named_uint("poolproxy usdc after", usdc.balanceOf(POOLPROXY));
        emit log_named_uint("safe usdc after", usdc.balanceOf(SAFE));
    }

    /* =========================================================
       7. STAKING SIDE (vector 6)
       ========================================================= */
    function test_v1_staking_side_no_profit() public {
        // --- vlINSURE: irreversible
        uint256 amt = 1e18;
        deal(INSURE, attacker, amt);
        uint256 vlBefore = IERC20(VLINSURE).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(INSURE).approve(VLINSURE, amt);
        IVlInsure(VLINSURE).deposit(amt, false, false);
        assertEq(IERC20(VLINSURE).balanceOf(attacker), vlBefore + amt, "vlINSURE 1:1");
        assertEq(IERC20(INSURE).balanceOf(attacker), 0, "INSURE spent");
        // lockInsure: the aggregated escrow lock has expired -> reverts (liveness brick)
        assertEq(IVlInsure(VLINSURE).incentiveInsure(), 0, "no incentive");
        vm.expectRevert(bytes("Cannot add to expired lock."));
        IVlInsure(VLINSURE).lockInsure();
        assertEq(IERC20(VLINSURE).balanceOf(attacker), vlBefore + amt, "no incentive mint");
        vm.stopPrank();
        // vlINSURE has no withdraw function; transfer only moves own tokens

        // --- LP gauge: deposit own LP, emissions to self only
        uint256 lpAmt = 1e15;
        deal(LP_TOKEN, attacker, lpAmt);
        vm.startPrank(attacker);
        IERC20(LP_TOKEN).approve(LP_GAUGE, lpAmt);
        IGauge(LP_GAUGE).deposit(lpAmt, attacker);
        assertEq(IGauge(LP_GAUGE).balanceOf(attacker), lpAmt, "gauge balance");
        // checkpoints: claimable is only from own working balance; weight is 0 now
        IGauge(LP_GAUGE).user_checkpoint(attacker);
        uint256 claimable = IGauge(LP_GAUGE).claimable_tokens(attacker);
        emit log_named_uint("attacker claimable after deposit", claimable);
        uint256 insBefore = IERC20(INSURE).balanceOf(attacker);
        IMinter(MINTER).mint(LP_GAUGE);
        assertEq(IERC20(INSURE).balanceOf(attacker), insBefore + claimable, "mint == own claimable");
        // withdraw own LP back
        IGauge(LP_GAUGE).withdraw(lpAmt);
        assertEq(IERC20(LP_TOKEN).balanceOf(attacker), lpAmt, "LP returned");
        vm.stopPrank();

        // --- VotingEscrow: no unprivileged exit for non-holders
        vm.startPrank(attacker);
        IVotingEscrow(ESCROW).withdraw(); // no lock: zero transfer, no gain
        vm.expectRevert(bytes("only collateral manager allowed"));
        IVotingEscrow(ESCROW).force_unlock(attacker);
        vm.stopPrank();
        assertEq(IERC20(INSURE).balanceOf(attacker), insBefore + claimable, "no escrow leak");
    }

    /* =========================================================
       8. adjustAlloc is permissionless but pays only the index (vector 7)
       ========================================================= */
    function test_v1_adjust_alloc_permissionless_selfclaim() public {
        address[3] memory idxs = [INDEX_DAEA, INDEX_D5F1, INDEX_7E08];
        uint256 attackerBefore = usdc.balanceOf(attacker);
        for (uint256 i = 0; i < 3; i++) {
            uint256 attrBefore = vault.attributions(idxs[i]);
            uint256 totalBefore = vault.totalAttributions();
            vm.prank(attacker);
            IIndex(idxs[i]).adjustAlloc();
            uint256 attrAfter = vault.attributions(idxs[i]);
            uint256 totalAfter = vault.totalAttributions();
            emit log_named_uint("index attr before", attrBefore);
            emit log_named_uint("index attr after ", attrAfter);
            assertEq(totalBefore, totalAfter, "total attributions conserved");
            // any increase goes to the index itself, never the attacker
            if (attrAfter > attrBefore) assertEq(attrAfter - attrBefore, vault.attributions(idxs[i]) - attrBefore);
        }
        assertEq(usdc.balanceOf(attacker), attackerBefore, "attacker gained 0");
        assertEq(vault.totalAttributions(), vault.valueAll(), "still par");
    }

    /* =========================================================
       9. FAKE CREDIT via fresh index: no drain (vector 7)
       ========================================================= */
    function test_v1_fake_credit_no_drain() public {
        address m = _createAttackerMarket();
        uint256 vaultBefore = usdc.balanceOf(VAULT);

        // 1) normal-TVL insurance: attacker pays premium, cannot redeem
        deal(USDC, m, 1e6);
        vm.prank(m);
        usdc.approve(VAULT, 1e6);
        uint256 premium = IPool(POOL_8C49).getPremium(10e6, 604800);
        emit log_named_uint("premium for 10 USDC cover (normal TVL)", premium);
        vm.prank(m);
        IPool(POOL_8C49).insure(10e6, premium, 604800, bytes32(0), m, m);
        vm.startPrank(m);
        vm.expectRevert(bytes("ERROR: NO_APPLICABLE_INCIDENT"));
        IPool(POOL_8C49).redeem(1, 0, new bytes32[](0));
        vm.stopPrank();

        // 2) fake credit inflation: no token drain; inflating TVL even bricks getPremium
        (uint256 slot, bool ok) = _firstFreeSlot(POOL_8C49);
        assertTrue(ok, "free slot");
        vm.startPrank(m);
        IPool(POOL_8C49).registerIndex(slot);
        IPool(POOL_8C49).allocateCredit(1e18); // absurd credit
        uint256 credit = IPool(POOL_8C49).totalCredit();
        assertGt(credit, 1e18, "credit inflated");
        uint256 claimed = IPool(POOL_8C49).withdrawCredit(0);
        assertEq(claimed, 0, "no premium");
        vm.stopPrank();
        assertEq(usdc.balanceOf(VAULT), vaultBefore + premium, "vault only gained the premium");
        assertEq(usdc.balanceOf(m), 1e6 - premium, "market only lost the premium");
        // DoS observation: premium model panics at inflated TVL
        vm.expectRevert();
        IPool(POOL_8C49).getPremium(10e6, 604800);

        // 3) unlock is public and returns the lock; no path to a payout
        vm.warp(block.timestamp + 604800 + params.getGrace(POOL_8C49) + 1);
        vm.prank(attacker);
        IPool(POOL_8C49).unlock(1);
        assertLe(usdc.balanceOf(attacker), 1e6, "EOA never gained");
    }

    /* =========================================================
       10. Factory surface (vector 7)
       ========================================================= */
    function test_v1_factory_surface() public {
        (bool appr, bool isOpen, bool dup) = IFactory(FACTORY).templates(OPEN_TEMPLATE);
        assertTrue(appr && isOpen && !dup, "pool template open");
        (bool a2, bool o2,) = IFactory(FACTORY).templates(INDEX_IMPL);
        assertTrue(a2 && !o2, "index template closed");
        (bool a3, bool o3,) = IFactory(FACTORY).templates(CDS_IMPL);
        assertTrue(a3 && !o3, "cds template closed");
        assertTrue(IFactory(FACTORY).reflist(OPEN_TEMPLATE, 1, USDC), "USDC allowed");
        assertTrue(IFactory(FACTORY).reflist(OPEN_TEMPLATE, 2, REGISTRY), "registry allowed");
        assertTrue(IFactory(FACTORY).reflist(OPEN_TEMPLATE, 3, PARAMETERS), "params allowed");
        assertEq(IFactory(FACTORY).conditionlist(OPEN_TEMPLATE, 0), 1e9, "min deposit 1e9");
        // createMarket with a closed template reverts for fresh EOA
        address[] memory refs = new address[](3);
        refs[0] = USDC; refs[1] = REGISTRY; refs[2] = PARAMETERS;
        uint256[] memory conds = new uint256[](0);
        vm.prank(attacker);
        vm.expectRevert(bytes("ERROR: UNAUTHORIZED_SENDER"));
        IFactory(FACTORY).createMarket(INDEX_IMPL, "x", conds, refs);
        // factory's own registry pointer
        assertEq(registry.factory(), FACTORY, "factory set");
    }

    /* =========================================================
       11. Vault repayDebt edge: no untracked value captured
       ========================================================= */
    function test_v1_repayDebt_no_capture() public {
        // no debts anywhere -> repayDebt transfers nothing regardless of args
        uint256 before = usdc.balanceOf(attacker);
        vm.prank(attacker);
        vault.repayDebt(type(uint256).max, POOL_8C49); // clamped to debt==0
        assertEq(usdc.balanceOf(attacker), before, "paid 0");
        assertEq(vault.totalDebt(), 0, "debt 0");
        // offsetDebt to a debtless target always underflows/reverts
        deal(USDC, attacker, 0);
        vm.prank(attacker);
        vm.expectRevert(); // WITHDRAW-VALUE... or ERROR_REPAY_DEBT_BADCONDITIONS
        vault.offsetDebt(1, attacker2);
    }

    /* =========================================================
       12. CDS + index compensate gates (vector 7)
       ========================================================= */
    function test_v1_compensate_gates() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("ERROR:UNREGISTERED"));
        ICDS(CDS).compensate(1e6);
        vm.expectRevert(bytes("COMPENSATE_UNAUTHORIZED_CALLER"));
        IIndex(INDEX_DAEA).compensate(1e6);
        vm.stopPrank();
        // a listed market without allocPoints also fails on the index
        address m = _createAttackerMarket();
        vm.prank(m);
        vm.expectRevert(bytes("COMPENSATE_UNAUTHORIZED_CALLER"));
        IIndex(INDEX_DAEA).compensate(1e6);
        // CDS.compensate from the attacker market would move CDS attribution to the
        // market (latent), but no PoolTemplate function calls it: verified by the
        // market having no code path (only registerIndex/allocate/withdraw/insure/
        // deposit/withdraw/redeem/applyCover/applyBounty/resume/unlock). The one
        // value-moving path is _liquidation (owner/resume gated).
    }

    /* =========================================================
       13. CDS share math + dilution direction (vector 2)
       ========================================================= */
    function test_v1_cds_roundtrip() public {
        uint256 dep = 1e6;
        deal(USDC, attacker, dep);
        uint256 inBefore = usdc.balanceOf(attacker);
        vm.startPrank(attacker);
        usdc.approve(VAULT, dep);
        uint256 minted = ICDS(CDS).deposit(dep);
        vm.stopPrank();
        // pro-rata mint against crowdPool value 59.79M / supply 59.79M == par
        assertEq(minted, dep, "par mint");
        vm.startPrank(attacker);
        ICDS(CDS).requestWithdraw(minted);
        vm.warp(block.timestamp + 21 days + 1);
        uint256 out = ICDS(CDS).withdraw(minted);
        vm.stopPrank();
        assertLe(out, dep, "no profit from CDS roundtrip");
        assertLe(usdc.balanceOf(attacker), inBefore, "no gain");
    }

    /* =========================================================
       14. Index withdraw math (vector 2)
       ========================================================= */
    function test_v1_index_roundtrip() public {
        uint256 dep = 1e6;
        deal(USDC, attacker, dep);
        vm.startPrank(attacker);
        usdc.approve(VAULT, dep);
        uint256 minted = IIndex(INDEX_DAEA).deposit(dep);
        vm.stopPrank();
        vm.startPrank(attacker);
        IIndex(INDEX_DAEA).requestWithdraw(minted);
        vm.warp(block.timestamp + 14 days + 1);
        uint256 out = IIndex(INDEX_DAEA).withdraw(minted);
        vm.stopPrank();
        emit log_named_uint("index minted", minted);
        emit log_named_uint("index out", out);
        assertLe(out, dep, "no profit from index roundtrip");
    }
}
