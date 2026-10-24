// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BulbaProbe, IERC20, IUniswapV3PoolMinimal} from "../src/BulbaProbe.sol";

/// @title BulbaSwap V3 (Morph) — code-identity + accounting PoC
/// @notice Read-only. Runs entirely on local forks of Morph mainnet and Ethereum mainnet.
///         No transaction is ever signed or broadcast to a live network.
contract BulbaV3Test is Test {
    // Morph mainnet
    address constant FACTORY_MORPH = 0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD;
    address constant POOL_MORPH = 0x5191035D329f481eFf0143e690e0a4e366Dd1e0c; // WETH/USDT 0.05%
    address constant WETH_MORPH = 0x5300000000000000000000000000000000000011;
    address constant USDT_MORPH = 0xc7D67A9cBB121b3b0b9c053DD9f469523243379A;

    // Ethereum mainnet canonical Uniswap V3
    address constant FACTORY_ETH = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant POOL_ETH = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8; // USDC/WETH 0.3%

    uint256 constant MORPH_BLOCK = 28_776_889;

    uint256 morphFork;
    uint256 ethFork;

    function setUp() public {
        string memory morphRpc = vm.envOr("MORPH_RPC_URL", string("https://rpc.morphl2.io"));
        string memory ethRpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        morphFork = vm.createFork(morphRpc, MORPH_BLOCK);
        ethFork = vm.createFork(ethRpc);
    }

    // ---------------------------------------------------------------------
    // 1. The factory bytecode is canonical UniswapV3Factory, byte-for-byte,
    //    except the NoDelegateCall `original` immutable (its own address).
    //    Because pools are deployed from the factory's embedded creation code,
    //    this alone implies every pool is canonical bytecode.
    // ---------------------------------------------------------------------
    function test_factory_code_is_canonical() public {
        vm.selectFork(ethFork);
        bytes memory ethFactory = FACTORY_ETH.code;
        vm.selectFork(morphFork);
        bytes memory morphFactory = FACTORY_MORPH.code;

        assertEq(ethFactory.length, morphFactory.length, "factory code length differs");
        assertEq(ethFactory.length, 24_535, "unexpected factory code length");

        bytes memory e = blank(ethFactory, FACTORY_ETH);
        bytes memory m = blank(morphFactory, FACTORY_MORPH);
        assertEq(keccak256(e), keccak256(m), "factory differs beyond the self-address immutable");
    }

    // ---------------------------------------------------------------------
    // 2. The pool runtime code equals a canonical mainnet pool modulo the
    //    immutable words (token0, token1, factory, pool self) plus the
    //    fee/tickSpacing-derived constants.
    // ---------------------------------------------------------------------
    function test_pool_code_is_canonical_modulo_immutables() public {
        vm.selectFork(ethFork);
        bytes memory ethPool = POOL_ETH.code;
        uint256 ethLen = ethPool.length;
        ethPool = blankPool(ethPool, POOL_ETH);
        vm.selectFork(morphFork);
        bytes memory morphPool = POOL_MORPH.code;
        uint256 morphLen = morphPool.length;
        morphPool = blankPool(morphPool, POOL_MORPH);

        assertEq(ethLen, morphLen, "pool code length differs");
        assertEq(morphLen, 22_142, "unexpected pool code length");

        uint256 residual = diffCount(ethPool, morphPool);
        // Residual = the fee (3000 vs 500), tickSpacing (60 vs 10) and the derived
        // maxLiquidityPerTick uint128 constant. Anything larger would mean real code drift.
        emit log_named_uint("residual differing bytes (fee/tickSpacing constants only)", residual);
        assertLt(residual, 80, "pool code differs beyond immutables/fee constants");
    }

    // ---------------------------------------------------------------------
    // 3. Behavioral: a swap out-and-back must be net-negative (pool keeps fees).
    // ---------------------------------------------------------------------
    function test_swap_roundtrip_no_free_value() public {
        vm.selectFork(morphFork);
        BulbaProbe probe = new BulbaProbe(POOL_MORPH);

        deal(WETH_MORPH, address(probe), 10 ether);
        uint256 wethStart = IERC20(WETH_MORPH).balanceOf(address(probe));
        assertGt(wethStart, 0, "weth deal failed");

        // WETH -> USDT
        (int256 d0, int256 d1) = probe.doSwap(true, int256(1 ether));
        require(d0 > 0, "expected to pay token0");
        uint256 usdtGot = uint256(-d1);
        assertGt(usdtGot, 0, "no usdt out");

        // USDT -> WETH (all of it)
        probe.doSwap(false, int256(usdtGot));

        uint256 wethEnd = IERC20(WETH_MORPH).balanceOf(address(probe));
        emit log_named_uint("weth start", wethStart);
        emit log_named_uint("weth end  ", wethEnd);
        assertLt(wethEnd, wethStart, "roundtrip produced free value");
    }

    // ---------------------------------------------------------------------
    // 4. Behavioral: flash() charges exactly the pool fee; the pool cannot
    //    be made to lose value.
    // ---------------------------------------------------------------------
    function test_flash_charges_exactly_pool_fee() public {
        vm.selectFork(morphFork);
        BulbaProbe probe = new BulbaProbe(POOL_MORPH);
        deal(WETH_MORPH, address(probe), 10 ether);

        uint256 balBefore = IERC20(WETH_MORPH).balanceOf(POOL_MORPH);
        uint24 feePips = IUniswapV3PoolMinimal(POOL_MORPH).fee();
        uint256 amount = 1 ether;
        uint256 owed = (amount * (uint256(1e6) + feePips) + 1e6 - 1) / 1e6;

        probe.doFlash(amount, 0);

        uint256 balAfter = IERC20(WETH_MORPH).balanceOf(POOL_MORPH);
        emit log_named_uint("pool weth delta", balAfter - balBefore);
        emit log_named_uint("expected fee    ", owed - amount);
        assertEq(balAfter - balBefore, owed - amount, "flash fee mismatch");
    }

    // ------------------------------------------------------------------ helpers
    function blankPool(bytes memory code, address pool) internal view returns (bytes memory) {
        code = blank(code, IUniswapV3PoolMinimal(pool).token0());
        code = blank(code, IUniswapV3PoolMinimal(pool).token1());
        code = blank(code, IUniswapV3PoolMinimal(pool).factory());
        code = blank(code, pool);
        return code;
    }

    /// @dev zero every 20-byte occurrence of `a`
    function blank(bytes memory code, address a) internal pure returns (bytes memory out) {
        out = code;
        bytes20 needle = bytes20(a);
        if (code.length < 20) return out;
        for (uint256 i = 0; i + 20 <= code.length; i++) {
            bool hit = true;
            for (uint256 j = 0; j < 20; j++) {
                if (out[i + j] != needle[j]) {
                    hit = false;
                    break;
                }
            }
            if (hit) for (uint256 j = 0; j < 20; j++) out[i + j] = 0x00;
        }
    }

    function diffCount(bytes memory a, bytes memory b) internal pure returns (uint256 n) {
        require(a.length == b.length, "length");
        for (uint256 i = 0; i < a.length; i++) if (a[i] != b[i]) n++;
    }
}
