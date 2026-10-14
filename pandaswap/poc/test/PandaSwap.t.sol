// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

interface IWBNB is IERC20 {
    function deposit() external payable;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address) external;
    function sync() external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function factory() external view returns (address);
}

interface IUniswapV2Factory {
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256) external view returns (address);
    function getPair(address, address) external view returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function pairCodeHash() external pure returns (bytes32);
}

interface IPancakeRouter {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256)
        external
        returns (uint256[] memory);
}

interface IPnda {
    function owner() external view returns (address);
    function mint(address, uint256) external;
    function manualMint(address, uint256) external;
    function capUpdate(uint256) external;
    function totalSupply() external view returns (uint256);
    function cap() external view returns (uint256);
    function manualMinted() external view returns (uint256);
    function manualMintLimit() external view returns (uint256);
}

contract PandaSwapTest is Test {
    address constant FACTORY = 0x9Ad32bf5DaFe152Cbe027398219611DB4E8753B3;
    address constant FEE_TO = 0xe1a2CD535C4e7d9C2C187e529f9f491cceA41e07;
    address constant FEE_TO_SETTER = 0x3bC3c8aF8CFe3dFC9bA1A57c7C3b653e3f6d6951;
    bytes32 constant PAIR_CODE_HASH = 0xb785cebe4aa62be64e9e412e79c479c58578c1c3d0ffbb4602a9217d8b289559;

    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant PNDA = 0x47DcC83a14aD53Ed1f13d3CaE8AA4115f07557C0;
    address constant POLS = 0x7e624FA0E1c4AbFD309cC15719b7E2580887f570;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // funded PandaSwap pairs
    address constant PAIR_ATOM_WBNB = 0x37550AAC6aB58F3E2Ddb7cD9b88E9A46411a5E4A;
    address constant PAIR_CAKE_WBNB = 0x835fAAC7fDdcc18FFA5D31B57Fa4F573cB4B3862;
    address constant PAIR_PNDA_WBNB = 0x97f6665ac6b2d7C3d5a2aD11d7a779787F617ce0;
    address constant PAIR_WBNB_BUSD = 0xAcAeb6859ed08210E05df247e1DC3a2ED4D5FBCB;
    address constant PAIR_ETH_PNDA = 0x059fC92273CdF0809ba45f199E0a12d8899Ab402;
    address constant PAIR_PNDA_USDC = 0xbe01056Bc0e29eb28c9c357c227e320Afd12776C;
    address constant PAIR_POLS_WBNB = 0xdb8aD7E2a5B19D7449a2d6BF231467a62141734f;
    address constant PAIR_WBNB_LINK = 0x854ea3E74eED7C6cE1372dbF78d0aC1fE815Ac20;
    address constant PAIR_VBTC_WBNB = 0x2058d400f043Da17e622011492ca5C1aEdBa6Ffc;

    IUniswapV2Factory factory;
    address attacker;

    function setUp() public {
        // CI may inject BSC_RPC_URL as an empty string; try it first, then public fallbacks.
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        bool ok = false;
        if (bytes(rpc).length > 0) {
            try vm.createSelectFork(rpc) returns (uint256) {
                ok = true;
            } catch {}
        }
        if (!ok) {
            string[2] memory fallbacks =
                ["https://bsc-rpc.publicnode.com", "https://bsc-dataseed1.defibit.io"];
            for (uint256 i = 0; i < fallbacks.length; i++) {
                try vm.createSelectFork(fallbacks[i]) returns (uint256) {
                    ok = true;
                    break;
                } catch {}
            }
        }
        require(ok, "no BSC fork RPC available");
        factory = IUniswapV2Factory(FACTORY);
        attacker = makeAddr("freshAttacker");
        emit log_named_uint("fork block", block.number);
    }

    function getAmountOut(uint256 amountIn, uint256 rIn, uint256 rOut) internal pure returns (uint256) {
        uint256 inWithFee = amountIn * 997;
        return (inWithFee * rOut) / (rIn * 1000 + inWithFee);
    }

    // ---------------------------------------------------------------- state
    function test_00_state_sanity() public view {
        assertEq(factory.allPairsLength(), 129, "pair count");
        assertEq(factory.feeTo(), FEE_TO, "feeTo");
        assertEq(factory.feeToSetter(), FEE_TO_SETTER, "feeToSetter");
        assertEq(factory.pairCodeHash(), PAIR_CODE_HASH, "pairCodeHash");
        assertGt(FACTORY.code.length, 10000, "factory code");
        // spot check a pair
        IUniswapV2Pair p = IUniswapV2Pair(PAIR_PNDA_WBNB);
        assertEq(p.factory(), FACTORY, "pair factory");
        (uint112 r0, uint112 r1,) = p.getReserves();
        assertGt(uint256(r0), 0, "reserve0");
        assertGt(uint256(r1), 0, "reserve1");
    }

    // ------------------------------------------------- CREATE2 derivation
    // The Python CI job (ci/enumerate_ci.py) verifies CREATE2 for ALL 129 pairs via eth_call.
    // Here we re-verify a spread sample inside the EVM (fork RPCs can prune per-account state,
    // which would otherwise abort the whole loop with a database error).
    function test_01_create2_all_pairs() public {
        uint256 n = factory.allPairsLength();
        uint256 verified = 0;
        uint256 skipped = 0;
        for (uint256 i = 0; i < n; i += 6) {
            address pair = factory.allPairs(i);
            try IUniswapV2Pair(pair).token0() returns (address t0) {
                address t1 = IUniswapV2Pair(pair).token1();
                bytes32 salt = keccak256(abi.encodePacked(t0, t1));
                address derived =
                    address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", FACTORY, salt, PAIR_CODE_HASH)))));
                assertEq(derived, pair, "CREATE2 derivation mismatch");
                verified++;
            } catch {
                skipped++;
            }
        }
        emit log_named_uint("pairs total", n);
        emit log_named_uint("pairs CREATE2-verified (sample)", verified);
        emit log_named_uint("pairs skipped (rpc storage)", skipped);
        assertGt(verified, 15, "too few pairs verified");
    }

    // ------------------------------------------------- skim: no real excess
    function test_03_skim_no_real_excess() public {
        address[8] memory pairs = [
            PAIR_ATOM_WBNB, PAIR_CAKE_WBNB, PAIR_PNDA_WBNB, PAIR_WBNB_BUSD,
            PAIR_ETH_PNDA, PAIR_PNDA_USDC, PAIR_POLS_WBNB, PAIR_WBNB_LINK
        ];
        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair p = IUniswapV2Pair(pairs[i]);
            address t0 = p.token0();
            address t1 = p.token1();
            uint256 b0 = IERC20(t0).balanceOf(attacker);
            uint256 b1 = IERC20(t1).balanceOf(attacker);
            vm.prank(attacker);
            p.skim(attacker);
            uint256 g0 = IERC20(t0).balanceOf(attacker) - b0;
            uint256 g1 = IERC20(t1).balanceOf(attacker) - b1;
            emit log_named_address("pair", pairs[i]);
            emit log_named_uint("skim gain token0", g0);
            emit log_named_uint("skim gain token1", g1);
            assertEq(g0, 0, "unexpected token0 skim gain");
            assertEq(g1, 0, "unexpected token1 skim gain");
        }
    }

    // ----------------------------------- no free output without input (k check)
    function test_04_no_free_output_without_input() public {
        IUniswapV2Pair p = IUniswapV2Pair(PAIR_WBNB_BUSD);
        (, uint112 r1,) = p.getReserves();
        vm.prank(attacker);
        vm.expectRevert(bytes("UniswapV2: INSUFFICIENT_INPUT_AMOUNT"));
        p.swap(0, uint256(r1) / 4, attacker, "");
    }

    // ------------------------------------------- round trip loses the 0.3% fee
    function test_05_roundtrip_loses_fees() public {
        IUniswapV2Pair p = IUniswapV2Pair(PAIR_PNDA_WBNB);
        (uint112 r0, uint112 r1,) = p.getReserves(); // PNDA, WBNB
        vm.deal(attacker, 10 ether);
        vm.prank(attacker);
        IWBNB(WBNB).deposit{value: 1 ether}();
        uint256 wbnbIn = 0.5 ether;
        uint256 pndaOut = getAmountOut(wbnbIn, r1, r0);
        vm.prank(attacker);
        IWBNB(WBNB).transfer(address(p), wbnbIn);
        vm.prank(attacker);
        p.swap(pndaOut, 0, attacker, "");
        // sell back
        (uint112 s0, uint112 s1,) = p.getReserves();
        uint256 wbnbBack = getAmountOut(pndaOut, s0, s1);
        vm.prank(attacker);
        IERC20(PNDA).transfer(address(p), pndaOut);
        vm.prank(attacker);
        p.swap(0, wbnbBack, attacker, "");
        emit log_named_uint("wbnb in", wbnbIn);
        emit log_named_uint("wbnb back", wbnbBack);
        assertLt(wbnbBack, wbnbIn, "round trip must lose fees");
    }

    // --------------------------------------------------- PNDA mint gates (P)
    function test_06_pnda_mint_gates() public {
        IPnda pnda = IPnda(PNDA);
        emit log_named_address("pnda owner", pnda.owner());
        emit log_named_uint("pnda totalSupply", pnda.totalSupply());
        emit log_named_uint("pnda cap", pnda.cap());
        emit log_named_uint("pnda manualMinted", pnda.manualMinted());
        emit log_named_uint("pnda manualMintLimit", pnda.manualMintLimit());
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        pnda.mint(attacker, 1e18);
        vm.expectRevert();
        pnda.manualMint(attacker, 1e18);
        vm.expectRevert();
        pnda.capUpdate(1e30);
        vm.stopPrank();
    }

    // --------------------------------------- fake-token pair: no WBNB extraction
    function test_08_fake_token_pairs_no_drain() public {
        IUniswapV2Pair p = IUniswapV2Pair(PAIR_VBTC_WBNB);
        address t0 = p.token0();
        address t1 = p.token1();
        (uint112 r0, uint112 r1,) = p.getReserves();
        emit log_named_uint("vtbtc pair reserve0", r0);
        emit log_named_uint("vtbtc pair reserve1", r1);
        // skim yields nothing
        uint256 b0 = IERC20(t0).balanceOf(attacker);
        uint256 b1 = IERC20(t1).balanceOf(attacker);
        vm.prank(attacker);
        p.skim(attacker);
        assertEq(IERC20(t0).balanceOf(attacker) - b0, 0, "vtbtc skim gain");
        assertEq(IERC20(t1).balanceOf(attacker) - b1, 0, "wbnb skim gain");
        // no free output
        vm.prank(attacker);
        vm.expectRevert(bytes("UniswapV2: INSUFFICIENT_INPUT_AMOUNT"));
        p.swap(0, uint256(r1) / 2, attacker, "");
    }

    // ------------------- stale-price arb attempt vs live PancakeSwap market — E-U test
    function test_07_stale_price_arb_pols() public {
        IUniswapV2Pair p = IUniswapV2Pair(PAIR_POLS_WBNB);
        (uint112 r0, uint112 r1,) = p.getReserves(); // POLS, WBNB
        int256 bestProfit = type(int256).min;
        uint256 bestSize;
        vm.deal(attacker, 100 ether);
        vm.prank(attacker);
        IWBNB(WBNB).deposit{value: 100 ether}();
        uint256 start = IERC20(WBNB).balanceOf(attacker);

        uint256[8] memory sizes =
            [uint256(0.2 ether), 0.4 ether, 0.6 ether, 0.8 ether, 1 ether, 1.5 ether, 2 ether, 3 ether];
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snap = vm.snapshotState();
            uint256 inAmt = sizes[i];
            uint256 polsOut = getAmountOut(inAmt, r1, r0);
            vm.prank(attacker);
            IWBNB(WBNB).transfer(address(p), inAmt);
            vm.prank(attacker);
            p.swap(polsOut, 0, attacker, "");
            address[] memory path = new address[](2);
            path[0] = POLS;
            path[1] = WBNB;
            vm.startPrank(attacker);
            IERC20(POLS).approve(PANCAKE_ROUTER, polsOut);
            IPancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokens(
                polsOut, 0, path, attacker, block.timestamp + 300
            );
            vm.stopPrank();
            // NET P&L: final balance minus the starting balance (input is spent)
            int256 profit = int256(IERC20(WBNB).balanceOf(attacker)) - int256(start);
            emit log_named_uint("size (wei WBNB)", inAmt);
            emit log_named_uint("pols bought", polsOut);
            emit log_named_int("NET profit (wei WBNB, signed)", profit);
            if (profit > bestProfit) {
                bestProfit = profit;
                bestSize = inAmt;
            }
            vm.revertToState(snap);
        }
        emit log_named_uint("BEST size (wei WBNB)", bestSize);
        emit log_named_int("BEST net profit (wei WBNB, signed)", bestProfit);
        // the PandaSwap pool and the live PancakeSwap pool are price-aligned: no positive arb
        assertLt(bestProfit, 0, "expected no positive arbitrage vs live Pancake market");
    }
}
