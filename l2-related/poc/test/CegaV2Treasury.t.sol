// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

/// Cega V2 Treasury (EIP173ProxyWithReceive -> Treasury) gate proofs.
/// Read-only fork tests: prove that a fresh unprivileged attacker cannot move value.
/// Ethereum proxy:  0xA8AB795731fbBFDd1Fbc57ca11e6f722e7783642
/// Arbitrum proxy:  0x475C4AF369B28997B25bd756eF92797AD3F69593
/// Ethereum AM:     0x1DdF7C4C98a78b492bb4a2881358f183d94c9806
/// Arbitrum AM:     0x25b7A20B8E9B0676E596eDF4329d38459c3f9a87
contract CegaV2TreasuryTest is Test {
    // --- Ethereum ---
    address constant ETH_TREASURY = 0xA8AB795731fbBFDd1Fbc57ca11e6f722e7783642;
    address constant ETH_AM = 0x1DdF7C4C98a78b492bb4a2881358f183d94c9806;
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ETH_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant ETH_WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant ETH_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // --- Arbitrum ---
    address constant ARB_TREASURY = 0x475C4AF369B28997B25bd756eF92797AD3F69593;
    address constant ARB_AM = 0x25b7A20B8E9B0676E596eDF4329d38459c3f9a87;
    address constant ARB_USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant ARB_USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address attacker = address(0xBADBEEF);

    function _ethRpc() internal view returns (string memory) {
        string memory u = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(u).length == 0) return "https://ethereum-rpc.publicnode.com";
        return u;
    }
    function _arbRpc() internal view returns (string memory) {
        string memory u = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(u).length == 0) return "https://arb1.arbitrum.io/rpc";
        return u;
    }

    // ---------- Ethereum ----------

    function test_eth_live_state_and_gates() public {
        vm.createSelectFork(_ethRpc());
        emit log_named_uint("ETH fork block", block.number);

        // 1) live custody at pinned block
        uint256 usdc = IERC20(ETH_USDC).balanceOf(ETH_TREASURY);
        uint256 usdt = IERC20(ETH_USDT).balanceOf(ETH_TREASURY);
        uint256 wst = IERC20(ETH_WSTETH).balanceOf(ETH_TREASURY);
        uint256 wbtc = IERC20(ETH_WBTC).balanceOf(ETH_TREASURY);
        uint256 eth = ETH_TREASURY.balance;
        emit log_named_uint("ETH treasury USDC", usdc);
        emit log_named_uint("ETH treasury USDT", usdt);
        emit log_named_uint("ETH treasury wstETH", wst);
        emit log_named_uint("ETH treasury WBTC", wbtc);
        emit log_named_uint("ETH treasury native", eth);
        assertGt(usdc, 0);
        assertGt(usdt, 0);
        assertGt(eth, 0);

        // 2) proxy owner() is the EIP-173 upgrade authority
        (bool ok, bytes memory ret) = ETH_TREASURY.staticcall(abi.encodeWithSignature("owner()"));
        assertTrue(ok, "owner() must exist");
        address owner = abi.decode(ret, (address));
        emit log_named_address("ETH proxy owner (upgrade authority)", owner);
        assertTrue(owner != attacker, "attacker is not owner");

        // 3) address manager wiring
        (ok, ret) = ETH_TREASURY.staticcall(abi.encodeWithSignature("addressManager()"));
        assertTrue(ok, "addressManager()");
        address am = abi.decode(ret, (address));
        assertEq(am, ETH_AM, "AM address");
        (ok, ret) = ETH_AM.staticcall(abi.encodeWithSignature("getCegaEntry()"));
        address cegaEntry = ok ? abi.decode(ret, (address)) : address(0);
        (ok, ret) = ETH_AM.staticcall(abi.encodeWithSignature("getRedepositManager()"));
        address redeposit = ok ? abi.decode(ret, (address)) : address(0);
        emit log_named_address("CegaEntry", cegaEntry);
        emit log_named_address("RedepositManager", redeposit);
        assertTrue(cegaEntry != attacker && redeposit != attacker, "attacker not authorized");

        // 4) fresh attacker cannot withdraw (onlyCegaEntryOrRedepositManager)
        vm.prank(attacker);
        (bool succ, ) = ETH_TREASURY.call(
            abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_USDC, attacker, usdc, true)
        );
        assertFalse(succ, "fresh attacker withdraw must revert");
        assertEq(IERC20(ETH_USDC).balanceOf(attacker), 0, "attacker got nothing");

        // 5) withdrawStuckAssets: attacker has no stuck balance -> no value moved
        vm.prank(attacker);
        (succ, ) = ETH_TREASURY.call(
            abi.encodeWithSignature("withdrawStuckAssets(address,address)", ETH_USDC, attacker)
        );
        // call may "succeed" with amount 0 (USDC transfer of 0) - value must not move
        assertEq(IERC20(ETH_USDC).balanceOf(attacker), 0, "no stuck funds for attacker");
        assertEq(IERC20(ETH_USDC).balanceOf(ETH_TREASURY), usdc, "treasury balance unchanged");

        // 6) an arbitrary contract cannot impersonate the gate either
        AttackerContract ac = new AttackerContract();
        bool gateOk = ac.tryWithdraw(ETH_TREASURY, ETH_USDC, usdc);
        assertFalse(gateOk, "contract attacker blocked by gate");
        assertEq(IERC20(ETH_USDC).balanceOf(address(ac)), 0, "contract got nothing");

        // 7) no leftover allowances from the treasury to known routers/aggregators
        address[5] memory spenders = [
            0x1111111254EEB25477B68fb85Ed929f73A960582, // 1inch v5
            0xDef1C0ded9bec7F1a1670819833240f027b25EfF, // 0x exchange proxy
            0x0000000000001fF3684f28c67538d4D072C22734, // 0x AllowanceHolder
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, // Uniswap V2 router
            0xE592427A0AEce92De3Edee1F18E0157C05861564  // Uniswap V3 router
        ];
        for (uint256 i = 0; i < spenders.length; i++) {
            assertEq(IERC20(ETH_USDC).allowance(ETH_TREASURY, spenders[i]), 0, "no USDC allowance");
            assertEq(IERC20(ETH_USDT).allowance(ETH_TREASURY, spenders[i]), 0, "no USDT allowance");
        }
    }

    // ---------- Arbitrum ----------

    function test_arb_live_state_and_gates() public {
        vm.createSelectFork(_arbRpc());
        emit log_named_uint("ARB fork block", block.number);

        uint256 usdc = IERC20(ARB_USDC).balanceOf(ARB_TREASURY);
        uint256 usdt = IERC20(ARB_USDT).balanceOf(ARB_TREASURY);
        uint256 eth = ARB_TREASURY.balance;
        emit log_named_uint("ARB treasury USDC", usdc);
        emit log_named_uint("ARB treasury USDT", usdt);
        emit log_named_uint("ARB treasury native", eth);
        assertGt(usdc, 0);
        assertGt(eth, 0);

        (bool ok, bytes memory ret) = ARB_TREASURY.staticcall(abi.encodeWithSignature("owner()"));
        assertTrue(ok);
        address owner = abi.decode(ret, (address));
        emit log_named_address("ARB proxy owner (upgrade authority)", owner);
        assertTrue(owner != attacker);

        (ok, ret) = ARB_TREASURY.staticcall(abi.encodeWithSignature("addressManager()"));
        assertTrue(ok);
        address am = abi.decode(ret, (address));
        assertEq(am, ARB_AM);
        (ok, ret) = ARB_AM.staticcall(abi.encodeWithSignature("getCegaEntry()"));
        address cegaEntry = ok ? abi.decode(ret, (address)) : address(0);
        (ok, ret) = ARB_AM.staticcall(abi.encodeWithSignature("getRedepositManager()"));
        address redeposit = ok ? abi.decode(ret, (address)) : address(0);
        emit log_named_address("ARB CegaEntry", cegaEntry);
        emit log_named_address("ARB RedepositManager", redeposit);
        assertTrue(cegaEntry != attacker && redeposit != attacker);

        vm.prank(attacker);
        (bool succ, ) = ARB_TREASURY.call(
            abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ARB_USDC, attacker, usdc, true)
        );
        assertFalse(succ, "fresh attacker withdraw must revert");
        assertEq(IERC20(ARB_USDC).balanceOf(attacker), 0);

        vm.prank(attacker);
        (succ, ) = ARB_TREASURY.call(
            abi.encodeWithSignature("withdrawStuckAssets(address,address)", ARB_USDC, attacker)
        );
        assertEq(IERC20(ARB_USDC).balanceOf(ARB_TREASURY), usdc, "treasury balance unchanged");
    }
}

/// Cega V2 user-flow / gate proofs on the CegaEntry diamond + RedepositManager.
contract CegaV2EntryGatesTest is Test {
    address constant ETH_ENTRY = 0x7a67D5Eb2D6684d3e899575aAAA5AB31b79890c2;
    address constant ETH_REDEPOSIT = 0xF8a62c2eD5588df7aBa4713f79B4b4Af56fEb8f4;
    address constant ETH_TREASURY = 0xA8AB795731fbBFDd1Fbc57ca11e6f722e7783642;
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // a DCS vault that still has nonzero share supply (dcsUSDC, zombie status)
    address constant DCS_VAULT = 0xf173Aee4cfb3512F4fCb70dD71262978ED4690E5;

    address attacker = address(0xB0B);

    function _ethRpc() internal view returns (string memory) {
        string memory u = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(u).length == 0) return "https://ethereum-rpc.publicnode.com";
        return u;
    }

    function test_eth_entry_and_redeposit_gates() public {
        vm.createSelectFork(_ethRpc());
        emit log_named_uint("ETH fork block (entry gates)", block.number);

        // 1) permissionless addToWithdrawalQueue with zero shares must revert (no free claims)
        vm.prank(attacker);
        (bool ok, ) = ETH_ENTRY.call(
            abi.encodeWithSignature("addToWithdrawalQueue(address,uint128,uint32)", DCS_VAULT, uint128(1), uint32(0))
        );
        assertFalse(ok, "addToWithdrawalQueue with 0 shares must revert");

        // 2) RedepositManager.redeposit is onlyCegaEntry
        vm.prank(attacker);
        (ok, ) = ETH_REDEPOSIT.call(
            abi.encodeWithSignature(
                "redeposit(address,uint32,address,uint128,address)",
                ETH_TREASURY, uint32(1), ETH_USDC, uint128(1), attacker
            )
        );
        assertFalse(ok, "redeposit must be onlyCegaEntry");

        // 3) trader-only queue processing must revert for a fresh caller
        vm.prank(attacker);
        (ok, ) = ETH_ENTRY.call(
            abi.encodeWithSignature("fcnProcessWithdrawalQueue(address,uint256)", DCS_VAULT, uint256(1))
        );
        assertFalse(ok, "fcnProcessWithdrawalQueue must be onlyTraderAdmin");

        vm.prank(attacker);
        (ok, ) = ETH_ENTRY.call(abi.encodeWithSignature("sfnSettleVault(address)", DCS_VAULT));
        assertFalse(ok, "sfnSettleVault must fail for a fresh caller on a DCS vault");

        // 4) nothing moved to the attacker
        assertEq(IERC20(ETH_USDC).balanceOf(attacker), 0, "attacker gained nothing");
    }
}

contract AttackerContract {
    function tryWithdraw(address treasury, address asset, uint256 amount) external returns (bool ok) {
        (ok, ) = treasury.call(
            abi.encodeWithSignature("withdraw(address,address,uint256,bool)", asset, address(this), amount, true)
        );
    }
    receive() external payable {}
}
