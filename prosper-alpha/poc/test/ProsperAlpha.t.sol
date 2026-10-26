// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IMarket {
    function quoteBuy(uint256) external view returns (uint256 usedGross, uint256 fee, uint256 netAmountIn, uint256 pTokenOut);
    function quoteSell(uint256) external view returns (uint256 grossOut, uint256 fee, uint256 netOut);
    function pToken() external view returns (address);
    function externalPair() external view returns (address);
    function migrationEscrow() external view returns (address);
    function wrappedNative() external view returns (address);
    function curveK() external view returns (uint256);
    function phase() external view returns (uint8);
    function startedAt() external view returns (uint64);
    function endsAt() external view returns (uint64);
    function accessController() external view returns (address);
    function globalConfig() external view returns (address);
    function refreshPhase() external returns (uint8);
    function realWrappedNativeReserve() external view returns (uint256);
    function virtualNativeReserve() external view returns (uint256);
    function virtualTokenReserve() external view returns (uint256);
}

interface IRouter {
    function buyInnerNative(address market, uint256 minPTokenOut, uint256 deadline) external payable returns (uint256, uint256);
    function sellInner(address market, uint256 pTokenIn, uint256 minOut, uint256 deadline, bool nativeOut) external returns (uint256);
}

interface IMigrationEscrow {
    function finalizeFailure(address vault) external returns (uint256, uint256);
    function migrateToExternal(address vault) external;
    function addLiquidity(address vault, bool allowExistingPair, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f) external returns (address, uint256);
    function wrappedNative() external view returns (address);
    function lpTimeLock() external view returns (address);
    function v2Factory() external view returns (address);
    function registrar() external view returns (address);
    function rewardClaim() external view returns (address);
}

interface ILpTimeLock {
    function owner() external view returns (address);
    function claim(address token, address to) external returns (uint256);
    function register(address token, uint64 duration) external returns (uint64);
    function unlockAt(address token) external view returns (uint256);
}

interface IBuyback {
    function withdrawUsdc(bytes32, uint256) external returns (uint256);
    function fund(bytes32, uint256) external returns (uint256);
    function usdc() external view returns (address);
}

interface IPTokenClaim {
    function claim(address r25Vault, address account, uint256 totalAllocation, bytes32[] calldata proof) external returns (uint256);
    function claimable(address r25Vault, address account, uint256 totalAllocation) external view returns (uint256);
    function claimedAmount(address r25Vault, address account) external view returns (uint256);
}

interface IUUPS {
    function upgradeToAndCall(address newImpl, bytes calldata data) external payable;
    function proxiableUUID() external view returns (bytes32);
}

contract ProsperAlphaTest is Test {
    // ---- deployment (verified on-chain 2026-10-25, block 21240221) ----
    address constant FACTORY   = 0xEfdbb0eA7647B0e21AEf7A3b7a5D6A632c3116C8;
    address constant ACCESS    = 0x3C22060C99EE18097029151113478b4264041Bdb;
    address constant GLOBALCFG = 0x0303eE1F0409588DE499aD0538618C5da46EC5D7;
    address constant ROUTER    = 0x63FfADf944583D8e4Fdc30144EFdfe3bdC2122f5;
    address constant MIGESCROW = 0xc8F6D453D3C3ceA8A046f6D4AB683B0c4DB9a4D5;
    address constant TIMELOCK  = 0x152Ecca16F86FAa5d1FC2eD0a1B2bAF5AACd794B;
    address constant CLAIM     = 0x158432EeD50E944B4148D46b5e7df5D083706811;
    address constant WPROS     = 0x52C48d4213107b20bC583832b0d951FB9CA8F0B0;

    uint256 constant FORK_BLOCK = 21240221;

    address attacker = address(0xA11CE);

    // (market, pToken, phase)
    address[3] activeMarkets = [
        0x39630b3c2874276cd664823C44Ab23aA69Dde80A, // pPika phase0
        0x5c3E0e4B1BE0851DCbC5F6a5cc04d799AcbE8B7F, // pMusk phase0
        0xe534Dadb1E32A9DF075ffcAE0D636fF472A040db  // pPeng phase0
    ];
    address[3] activePTokens = [
        0x5Fbc014461758A4D62D7626e4129F442d85CD0bF,
        0xE318ac4113324841265d270Dc2393f1Bf742A7f8,
        0xc927DEf5467B85876310f1ef80d1C276b8f8a3AA
    ];
    // failed-inner-only (phase 3) market + pToken
    address constant FAILED_MARKET = 0x21E1C2dD76CF9C3223dC38fE53bB63b4F1234D8a; // pBANA
    address constant FAILED_PTOKEN = 0xC44c3519BaF35ea9437Ab1EeA8ED487720C9B394;
    address constant FAILED_VAULT  = 0x2F1cBC9D23b2e8E2Edb2c1110f5cC0C4e2Ad4e75;

    function setUp() public {
        string memory rpc = vm.envOr("PHAROS_RPC_URL", string("https://rpc.pharos.xyz"));
        // NOTE: the public Pharos RPC rejects numeric historical block tags for state
        // ("failed to parse block hash or number"), so fork at latest unless a block is given.
        uint256 fb = vm.envOr("PHAROS_FORK_BLOCK", uint256(0));
        if (fb == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, fb);
        }
        console2.log("fork block", block.number);
        vm.deal(attacker, 10_000 ether);
        vm.label(attacker, "attacker");
    }

    // ------------------------------------------------------------------
    // 1. Pure-view: quoteBuy -> quoteSell round trip must never profit
    // ------------------------------------------------------------------
    function test_quote_roundtrip_never_profits() public {
        uint256[7] memory xs = [uint256(1e6), 1e12, 1e15, 1e17, 1e18, 1e19, 1e20];
        for (uint256 m = 0; m < activeMarkets.length; m++) {
            address mk = activeMarkets[m];
            for (uint256 i = 0; i < xs.length; i++) {
                uint256 x = xs[i];
                (, , , uint256 pOut) = IMarket(mk).quoteBuy(x);
                (, , uint256 netBack) = IMarket(mk).quoteSell(pOut);
                console2.log(string.concat("market ", vm.toString(mk), " in ", vm.toString(x), " pOut ", vm.toString(pOut), " back ", vm.toString(netBack)));
                assertLe(netBack, x, "quote roundtrip profit");
            }
        }
    }

    // ------------------------------------------------------------------
    // 2. Fork: real buy then sell must never profit (all sizes)
    // ------------------------------------------------------------------
    function test_fork_buy_sell_never_profits() public {
        address mk = activeMarkets[0];
        address pt = activePTokens[0];
        uint256[5] memory xs = [uint256(1e12), 1e15, 1e17, 1e18, 1e19];
        for (uint256 i = 0; i < xs.length; i++) {
            uint256 x = xs[i];
            vm.startPrank(attacker);
            IERC20(pt).approve(ROUTER, type(uint256).max);
            uint256 before = attacker.balance;
            IRouter(ROUTER).buyInnerNative{value: x}(mk, 0, block.timestamp + 600);
            uint256 bought = IERC20(pt).balanceOf(attacker);
            IRouter(ROUTER).sellInner(mk, bought, 0, block.timestamp + 600, true);
            uint256 afterBal = attacker.balance;
            vm.stopPrank();
            console2.log(string.concat("in ", vm.toString(x), " bought ", vm.toString(bought), " delta ", vm.toString(afterBal >= before ? afterBal - before : 0), " neg? ", afterBal < before ? "yes" : "no"));
            assertLe(afterBal, before, "fork roundtrip profit");
        }
    }

    // ------------------------------------------------------------------
    // 3. FailedInnerOnly (phase 3) market: can a pToken holder still sell?
    //    (H-O recovery check)
    // ------------------------------------------------------------------
    function test_failed_market_holder_can_sell() public {
        uint256 phase = IMarket(FAILED_MARKET).phase();
        console2.log("FAILED_MARKET phase", phase);
        uint256 supply = IERC20(FAILED_PTOKEN).totalSupply();
        uint256 bal = IERC20(FAILED_PTOKEN).balanceOf(FAILED_MARKET);
        console2.log("pToken totalSupply", supply, "market pToken bal", bal);
        (, , uint256 netOut) = IMarket(FAILED_MARKET).quoteSell(1e18);
        console2.log("quoteSell(1e18) netOut", netOut);
        // deal a holder some pTokens and try to sell through the router
        address holder = address(0xB0B);
        vm.deal(holder, 1 ether);
        deal(FAILED_PTOKEN, holder, 1000e18, false);
        uint256 hBefore = holder.balance;
        vm.startPrank(holder);
        IERC20(FAILED_PTOKEN).approve(ROUTER, type(uint256).max);
        try IRouter(ROUTER).sellInner(FAILED_MARKET, 1000e18, 0, block.timestamp + 600, true) returns (uint256 out) {
            console2.log(string.concat("FAILED sell succeeded, out ", vm.toString(out), " deltaSign ", holder.balance >= hBefore ? "+" : "-"));
        } catch (bytes memory reason) {
            console2.log("FAILED sell reverted");
            console2.logBytes(reason);
        }
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 4. Access control: privileged value movers revert for attacker
    // ------------------------------------------------------------------
    function test_migrateToExternal_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IMigrationEscrow(MIGESCROW).migrateToExternal(FAILED_VAULT);
    }

    function test_addLiquidity_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IMigrationEscrow(MIGESCROW).addLiquidity(FAILED_VAULT, true, 0, 0, 0, 0, 0, block.timestamp + 600);
    }

    function test_timelock_claim_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        ILpTimeLock(TIMELOCK).claim(address(0xdead), attacker);
    }

    function test_timelock_register_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        ILpTimeLock(TIMELOCK).register(address(0xdead), 1);
    }

    function test_buyback_withdraw_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IBuyback(0x484Ec8A653f35bFBe0F4FF04387F109a70bFB53d).withdrawUsdc(bytes32(uint256(1)), 1);
    }

    function test_factory_upgrade_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUUPS(FACTORY).upgradeToAndCall(address(0xBEEF), "");
    }

    function test_access_controller_upgrade_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        IUUPS(ACCESS).upgradeToAndCall(address(0xBEEF), "");
    }

    // ------------------------------------------------------------------
    // 5. PTokenClaim: forged allocation with empty proof must revert
    // ------------------------------------------------------------------
    function test_ptokenclaim_forged_reverts() public {
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(attacker);
        vm.expectRevert();
        IPTokenClaim(CLAIM).claim(FAILED_VAULT, attacker, 1e30, proof);
    }

    // ------------------------------------------------------------------
    // 6. Refresh phase is permissionless but must not move value
    // ------------------------------------------------------------------
    function test_refresh_phase_no_value_move() public {
        address mk = activeMarkets[0];
        uint256 escrowBefore = IERC20(WPROS).balanceOf(MIGESCROW);
        uint256 atkBefore = IERC20(WPROS).balanceOf(attacker);
        vm.prank(attacker);
        try IMarket(mk).refreshPhase() returns (uint8 p) {
            console2.log("refreshPhase ok, phase", p);
        } catch {
            console2.log("refreshPhase reverted (ok)");
        }
        assertEq(IERC20(WPROS).balanceOf(MIGESCROW), escrowBefore, "escrow moved");
        assertEq(IERC20(WPROS).balanceOf(attacker), atkBefore, "attacker gained");
    }
}
