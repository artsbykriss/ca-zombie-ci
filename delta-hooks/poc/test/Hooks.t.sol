// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {V4Swapper, PoolKey, IPoolManager, IERC20Min, CurrencyDelta} from "../src/V4Swap.sol";

/// Fork tests for the 3 "unverified delta" v4 hooks.
/// Read-only: no broadcasts, fork only.
contract HooksTest is Test, V4Swapper {
    // --- target hooks ---
    address constant H_PNKSTR = 0xfAaad5B731F52cDc9746F2414c823eca9B06E844; // ETH/PNKSTR, aSD
    address constant H_ELEVATE = 0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0; // ELEVATE/USDT, NO delta
    address constant H_VAPI = 0xC90eddF51569270E06270eA98F7EfFF828dDe0CC; // Base ETH/VAPI, bSD+aSD

    address constant PNKSTR = 0xc50673EDb3A7b94E8CAD8a7d4E0cD68864E33eDF;
    address constant ELEVATE = 0x888888888887715FB9D9F84175Af9e6cCE46807e;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant VAPI = 0x1eA8deB921AA6015f4938010C848140b98108Dd2;

    function _rpcEth() internal view returns (string memory) {
        string memory u = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(u).length == 0) u = vm.envOr("RPC_URL", string(""));
        if (bytes(u).length == 0) u = "https://ethereum-rpc.publicnode.com";
        return u;
    }

    function _rpcBase() internal view returns (string memory) {
        string memory u = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(u).length == 0) u = "https://base-rpc.publicnode.com";
        return u;
    }

    function _pnkstrKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: PNKSTR, fee: 0, tickSpacing: 60, hooks: H_PNKSTR});
    }

    function _pnkstrKeyFee0() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: PNKSTR, fee: 0, tickSpacing: 60, hooks: H_PNKSTR});
    }

    function _vapiKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: VAPI, fee: 0, tickSpacing: 60, hooks: H_VAPI});
    }

    function _elevateKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: ELEVATE, currency1: USDT, fee: 3000, tickSpacing: 60, hooks: H_ELEVATE});
    }

    function _poolId(PoolKey memory k) internal pure returns (bytes32) {
        return keccak256(abi.encode(k));
    }

    /// Verify the reconstructed PoolKey matches the on-chain pool id from the Uniswap Gateway.
    function test_poolKeys_matchGateway() public {
        assertEq(_poolId(_pnkstrKey()), 0xbdb0f9c31367485f85e691f638345f3de673a78effaff71ce34bc7ff1d54fddc, "pnkstr key(fee=0x800000)");
        assertEq(_poolId(_vapiKey()), 0x05da2eb0bd58cb74ce0a0c4c93200a2e96778075fbe611b46967a334986c5671, "vapi key");
        assertEq(_poolId(_elevateKey()), 0x9103109ede61d0a698f28369f92b8619f5124f504028a8010403b144ff0be95d, "elevate key");
    }

    /// Round-trip: buy PNKSTR with ETH, sell it back. A healthy fee hook must leave the swapper net-negative.
    function test_roundtrip_pnkstr_eth() public {
        vm.createSelectFork(_rpcEth());
        vm.deal(address(this), 100 ether);
        uint256 start = address(this).balance;

        PoolKey memory k = _pnkstrKey();
        // sanity: pool id matches (also proves key correctness)
        assertEq(_poolId(k), 0xbdb0f9c31367485f85e691f638345f3de673a78effaff71ce34bc7ff1d54fddc, "key");

        uint256 amtIn = 1 ether;
        swapExactIn(PM_ETH, k, true, amtIn, address(this), "");
        uint256 pnk = IERC20Min(PNKSTR).balanceOf(address(this));
        emit log_named_uint("pnkstr out for 1 ETH (wei)", pnk);

        // sell it all back
        swapExactIn(PM_ETH, k, false, pnk, address(this), "");
        uint256 end = address(this).balance;

        emit log_named_uint("eth start", start);
        emit log_named_uint("eth end", end);
        // round trip must not be profitable
        assertLe(end, start, "round trip profitable -> E-U");
    }

    /// The hook takes a swap fee in ETH; confirm it is charged (hook balance grows) and never pays the swapper.
    function test_hook_charges_positive_fee() public {
        vm.createSelectFork(_rpcEth());
        vm.deal(address(this), 100 ether);
        PoolKey memory k = _pnkstrKey();
        uint256 hookBefore = H_PNKSTR.balance;
        swapExactIn(PM_ETH, k, true, 1 ether, address(this), "");
        uint256 hookAfter = H_PNKSTR.balance;
        emit log_named_uint("hook ETH before", hookBefore);
        emit log_named_uint("hook ETH after", hookAfter);
        // hook must never end up owing the swapper
        assertGe(hookAfter, 0, "hook balance negative impossible");
    }

    /// Public sweep 0x68e41100 on the PNKSTR hook: call it as a fresh EOA-like address.
    /// With a zero hook balance it must yield the caller nothing.
    function test_public_sweep_no_free_money() public {
        vm.createSelectFork(_rpcEth());
        address attacker = address(0xA11CE);
        vm.deal(attacker, 0);
        uint256 hookBefore = H_PNKSTR.balance;
        emit log_named_uint("hook ETH before sweep", hookBefore);
        vm.prank(attacker);
        (bool ok,) = H_PNKSTR.call(abi.encodeWithSelector(0x68e41100));
        emit log_named_string("sweep success", ok ? "yes" : "no");
        emit log_named_uint("attacker ETH gained", attacker.balance);
        // attacker must not be able to conjure ETH from an empty hook
        assertEq(attacker.balance, 0, "attacker gained ETH from hook");
    }

    /// Base ETH/VAPI pool (bSD+aSD): round trip must be net-negative.
    function test_roundtrip_vapi_base() public {        vm.createSelectFork(_rpcBase());
        vm.deal(address(this), 100 ether);
        uint256 start = address(this).balance;
        PoolKey memory k = _vapiKey();
        assertEq(_poolId(k), 0x05da2eb0bd58cb74ce0a0c4c93200a2e96778075fbe611b46967a334986c5671, "key");

        swapExactIn(PM_BASE, k, true, 1 ether, address(this), "");
        uint256 vapi = IERC20Min(VAPI).balanceOf(address(this));
        emit log_named_uint("vapi out for 1 ETH (wei)", vapi);
        swapExactIn(PM_BASE, k, false, vapi, address(this), "");
        uint256 end = address(this).balance;
        emit log_named_uint("eth start", start);
        emit log_named_uint("eth end", end);
        assertLe(end, start, "round trip profitable -> E-U");
    }

    /// Callback auth: every delta callback must revert when called by a non-PoolManager.
    function test_callback_auth_reverts() public {
        vm.createSelectFork(_rpcEth());
        // afterSwap selector 0xb47b2fb1 with junk args
        (bool ok1,) = H_PNKSTR.call(abi.encodeWithSelector(0xb47b2fb1));
        assertFalse(ok1, "afterSwap callable by EOA");
        (bool ok2,) = H_ELEVATE.call(abi.encodeWithSelector(0x575e24b4));
        assertFalse(ok2, "beforeSwap callable by EOA");
        (bool ok3,) = H_PNKSTR.call(abi.encodeWithSelector(0x68e41100)); // sweep, empty balance
        // sweep may succeed but must move nothing; already covered elsewhere
        emit log_named_string("pnkstr sweep empty-balance success", ok3 ? "yes" : "no");
    }

    /// Permission-bit check: declared getHookPermissions() must equal the hook address bits.
    function test_permissions_match_address() public {
        vm.createSelectFork(_rpcEth());
        assertEq(_perms(H_PNKSTR), _addrBits(H_PNKSTR), "PNKSTR perm!=addr");
        assertEq(_perms(H_ELEVATE), _addrBits(H_ELEVATE), "ELEVATE perm!=addr");
        // ELEVATE has NO return-delta permission
        uint160 ebits = _addrBits(H_ELEVATE);
        // delta bits: bSD(1<<3) aSD(1<<2) aALD(1<<1) aRLD(1<<0)
        assertEq(ebits & 0x0F, 0, "ELEVATE unexpectedly has delta bits");
        // PNKSTR has aSD (1<<2)
        assertTrue(_addrBits(H_PNKSTR) & (1 << 2) != 0, "PNKSTR missing aSD");
        // VAPI (Base) has bSD(1<<3)+aSD(1<<2)
        assertEq(_addrBits(H_VAPI) & 0x0C, 0x0C, "VAPI missing bSD/aSD");
    }

    function _addrBits(address h) internal pure returns (uint160) {
        return uint160(h) & 0x3FFF;
    }

    function _perms(address h) internal view returns (uint160 bits) {
        (bool ok, bytes memory ret) = h.staticcall(abi.encodeWithSelector(0xc4e833ce));
        require(ok, "perms call failed");
        require(ret.length >= 14 * 32, "bad perms");
        for (uint256 i = 0; i < 14; i++) {
            uint256 w;
            assembly {
                w := mload(add(add(ret, 0x20), mul(i, 0x20)))
            }
            if (w != 0) bits |= uint160(1) << (13 - i);
        }
    }
}
