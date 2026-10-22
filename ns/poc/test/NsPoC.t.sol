// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ---------------------------------------------------------------------------
// ZH4-PASS4 Tier-3 deep-dive : NS  (NASH Token)  burn-from-pair + sync()
// Read-only. Fork simulation only. No mainnet tx signed/sent.
//
// NS token : 0x33F1c4Fbb7e4E040F4F4E6Bc492e4Fedf750FD41
// NS pair  : 0xF1a5896D91C1E2372b159455ad013B2D17c0BB0b  (PancakeV2 NS/USDT)
// gate     : burnNsFromPair(uint256) -> `if (msg.sender != pairBurnOperator)
//            revert Unauthorized();`  + 1-day cooldown, max 5% of pair per call
// ---------------------------------------------------------------------------

interface IERC20m {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function sync() external;
}

interface INStoken {
    function pairBurnOperator() external view returns (address);
    function governance() external view returns (address);
    function owner() external view returns (address);
    function lastPairBurnTime() external view returns (uint256);
    function pairBurnSequence() external view returns (uint256);
    function MIN_TOTAL_SUPPLY() external view returns (uint256);
    function burnNsFromPair(uint256 burnBps) external;
    function burn(uint256 amount) external returns (uint256);
}

contract NsPoC is Test {
    address constant NS = 0x33F1c4Fbb7e4E040F4F4E6Bc492e4Fedf750FD41;
    address constant NS_PAIR = 0xF1a5896D91C1E2372b159455ad013B2D17c0BB0b;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant SAFE_SINGLETON = 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762; // Gnosis Safe v1.3.0

    address constant ATT = address(0xdEADbeEF00000000000000000000000000000001);

    uint256 forkBlock;

    function setUp() public {
        string[3] memory urls = [
            "https://bsc-rpc.publicnode.com",
            "https://bsc.drpc.org",
            "https://bsc.blockrazor.xyz"
        ];
        bool ok = false;
        string memory env = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(env).length > 0) {
            try vm.createSelectFork(env) {
                ok = true;
            } catch {}
        }
        if (!ok) {
            for (uint256 i = 0; i < urls.length; i++) {
                try vm.createSelectFork(urls[i]) {
                    ok = true;
                    break;
                } catch {}
            }
        }
        require(ok, "no working BSC fork rpc");
        forkBlock = block.number;
    }

    function test_ns_live_state() public {
        (uint112 r0, uint112 r1,) = IPair(NS_PAIR).getReserves();
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("NS pair reserve NS   (1e18)", r0);
        emit log_named_uint("NS pair reserve USDT (1e18)", r1);
        emit log_named_uint("NS pair balanceOf(NS)", IERC20m(NS).balanceOf(NS_PAIR));
        assertEq(uint256(r0), IERC20m(NS).balanceOf(NS_PAIR), "reserve0 == real NS balance (no desync)");
        assertEq(IPair(NS_PAIR).token0(), NS);
        assertEq(IPair(NS_PAIR).token1(), USDT);
        assertEq(INStoken(NS).pairBurnSequence(), 0, "never burned since launch");
    }

    // gate #1 : msg.sender != pairBurnOperator  ->  Unauthorized()
    function test_ns_gate_reverts_unauthorized() public {
        vm.prank(ATT);
        (bool ok, bytes memory ret) = NS.call(abi.encodeWithSelector(INStoken.burnNsFromPair.selector, uint256(500)));
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(0x82b42900), "Unauthorized()");
        emit log_named_address("NS pairBurnOperator", INStoken(NS).pairBurnOperator());
        emit log_named_address("NS governance", INStoken(NS).governance());
        emit log_named_address("NS owner()", INStoken(NS).owner());
    }

    // the operator (and governance) is a Gnosis Safe multisig proxy
    function test_ns_operator_is_gnosis_safe() public {
        address op = INStoken(NS).pairBurnOperator();
        assertEq(op, INStoken(NS).governance(), "operator == governance");
        (bool ok, bytes memory ret) = op.staticcall(abi.encodeWithSelector(bytes4(0xa619486e))); // masterCopy()
        assertTrue(ok, "proxy exposes masterCopy()");
        assertEq(abi.decode(ret, (address)), SAFE_SINGLETON, "Gnosis Safe v1.3.0 singleton");
    }

    // argument bound + cooldown (still privileged, documents the exact shape)
    function test_ns_arg_and_cooldown_bounds() public {
        address op = INStoken(NS).pairBurnOperator();
        vm.prank(op);
        (bool ok,) = NS.call(abi.encodeWithSelector(INStoken.burnNsFromPair.selector, uint256(501)));
        assertFalse(ok, "burnBps > MAX_PAIR_BURN_BPS(500) reverts InvalidValue");
    }

    // LATENT (privileged) : what a compromised/rogue operator could do
    function test_ns_latent_if_operator_compromised() public {
        address op = INStoken(NS).pairBurnOperator();
        (uint112 a0, uint112 a1,) = IPair(NS_PAIR).getReserves();

        vm.prank(op);
        INStoken(NS).burnNsFromPair(500); // 5% of the pair's NS, then sync()

        (uint112 b0, uint112 b1,) = IPair(NS_PAIR).getReserves();
        emit log_named_uint("NS reserve before", a0);
        emit log_named_uint("NS reserve after", b0);
        assertLt(uint256(b0), uint256(a0));
        assertEq(uint256(b1), uint256(a1), "USDT reserve unchanged");
        assertEq(uint256(b0), IERC20m(NS).balanceOf(NS_PAIR), "sync() ran");

        // second call within 1 day reverts PairBurnCooldownActive (0x4c154b5f)
        vm.prank(op);
        (bool ok, bytes memory ret) = NS.call(abi.encodeWithSelector(INStoken.burnNsFromPair.selector, uint256(500)));
        assertFalse(ok);
        assertEq(bytes4(ret), bytes4(0x4c154b5f), "PairBurnCooldownActive()");
    }

    // public burn(uint256) is permissionless but only burns the CALLER's own NS
    function test_ns_public_burn_is_self_burn_only() public {
        vm.prank(ATT);
        (bool ok, bytes memory ret) = NS.call(abi.encodeWithSelector(INStoken.burn.selector, uint256(1e18)));
        assertFalse(ok, "attacker has 0 NS");
        assertEq(bytes4(ret), bytes4(0xe450d38c), "ERC20InsufficientBalance");
        // burning your own tokens is not extraction; the pair reserve is untouched
    }
}
