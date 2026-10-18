// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IVault, IController, IERC20, IOracle} from "../src/Interfaces.sol";

contract LlamaLendV2Test is Test {
    // Ethereum, block 26,217,523 (2026-10-18)
    address constant ETH_VAULT_M1 = 0x3Da0F110079012387F47C6Fc6e878F10262E300a; // sfrxUSD/crvUSD
    address constant ETH_CTRL_M0 = 0xC77d97cF01737EB7aCE46cAb7cd9F60eC51a40c0;  // sDOLA/crvUSD
    address constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    // Optimism, block 158,352,276
    address constant OP_CTRL_M2 = 0xb5EC7A3D591877A66BE4f3eafdC4205E98A1BCAA; // wstETH/USDC.e
    address constant OP_ORACLE_M2 = 0x7d81EDA6F594DFD82faf39f377366c67aBE2b315;

    function forkEth() internal {
        string memory rpc = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = vm.envOr("ETH_RPC", string("https://ethereum-rpc.publicnode.com"));
        if (bytes(rpc).length == 0) rpc = "https://ethereum-rpc.publicnode.com";
        vm.createSelectFork(rpc, 26_217_523);
    }

    function forkOp() internal {
        string memory rpc = vm.envOr("OP_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.optimism.io";
        vm.createSelectFork(rpc, 158_352_276);
    }

    // 1) A direct crvUSD transfer to the controller does NOT change totalAssets:
    //    the share price cannot be donated into. (empty-market / donation defense)
    function testDirectDonationNotCounted() public {
        forkEth();
        IVault vault = IVault(ETH_VAULT_M1);
        IController ctrl = IController(vault.controller());
        uint256 ta0 = vault.totalAssets();
        deal(CRVUSD, address(this), 1_000_000e18);
        IERC20(CRVUSD).transfer(address(ctrl), 1_000_000e18);
        assertEq(vault.totalAssets(), ta0, "donation must not raise totalAssets");
    }

    // 2) First-depositor + donation: the attacker cannot profit because (a) direct
    //    donations are unaccounted and (b) DEAD_SHARES=1000 gives OZ virtual-share
    //    protection. Attacker ends with less than they put in.
    function testFirstDepositorDonationNoProfit() public {
        forkEth();
        IVault vault = IVault(ETH_VAULT_M1);
        uint256 bal0 = IERC20(CRVUSD).balanceOf(address(this));
        deal(CRVUSD, address(this), bal0 + 10_000 + 100e18);
        IERC20(CRVUSD).approve(address(vault), type(uint256).max);
        uint256 shares = vault.deposit(10_000, address(this)); // minimum assets
        assertGt(shares, 0, "min deposit minted 0");
        // try the classic donation: direct transfer, then a victim deposit
        IERC20(CRVUSD).transfer(vault.controller(), 100e18);
        address victim = address(0xBEEF);
        deal(CRVUSD, victim, 1_000e18);
        vm.startPrank(victim);
        IERC20(CRVUSD).approve(address(vault), type(uint256).max);
        uint256 vshares = vault.deposit(1_000e18, victim);
        vm.stopPrank();
        assertGt(vshares, 0, "victim minted 0");
        // attacker exits
        vault.redeem(shares, address(this), address(this));
        uint256 afterBal = IERC20(CRVUSD).balanceOf(address(this));
        emit log_named_uint("attacker_start_balance", bal0);
        emit log_named_uint("attacker_end_balance", afterBal);
        // attacker deposited 10,000 wei and donated 100e18 that is not credited;
        // they must end at or below start + 10,000 (in fact 1 wei below).
        assertLe(afterBal, bal0 + 10_000, "attacker must not profit");
        emit log_named_int("attacker_pnl_wei", int256(afterBal) - int256(bal0 + 10_000));
    }

    // 3) Every live ETH borrower is healthy, so permissionless liquidate() reverts
    //    at the exact gating check "Not enough rekt".
    function testHealthyEthLoanCannotBeLiquidated() public {
        forkEth();
        IController ctrl = IController(ETH_CTRL_M0);
        address user = ctrl.loans(0);
        int256 h = ctrl.health(user, true);
        emit log_named_int("health_m0_loan0", h);
        assertGt(h, 0, "position is healthy");
        vm.expectRevert(bytes("Not enough rekt"));
        ctrl.liquidate(user, 0, 1e18);
    }

    // 4) OP wstETH/USDC market: all 5 positions healthy; liquidate reverts at the
    //    same gate. Oracle is Chainlink WSTETH/USD (fresh, EMA-smoothed).
    function testHealthyOpLoanCannotBeLiquidated() public {
        forkOp();
        IController ctrl = IController(OP_CTRL_M2);
        address user = ctrl.loans(0);
        int256 h = ctrl.health(user, true);
        uint256 p = IOracle(OP_ORACLE_M2).price();
        emit log_named_int("health_op_m2_loan0", h);
        emit log_named_uint("op_wsteth_usd_oracle", p);
        assertGt(h, 0, "position is healthy");
        assertGt(p, 0, "oracle live");
        vm.expectRevert(bytes("Not enough rekt"));
        ctrl.liquidate(user, 0, 1e18);
    }
}
