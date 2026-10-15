// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {
    IG8keepFactory, IG8keepToken, IUniswapV2Pair, IERC20,
    IG8keepPenaltyReceiver, IG8keepVester
} from "../src/Interfaces.sol";

/**
 * g8keep (Base) — fresh-attacker extraction PoC.
 *
 * Claim under test: an external, unprivileged attacker (no owner/keys/roles) can extract
 * value from the live g8keep factory / its locked LP positions / the fee-bearing contracts.
 *
 * Result: every value-moving path is gated (owner-only, allowlist, or recipient-only) and
 * the factory-held LP tokens are permanently locked by the factory's own `lockedTokens`
 * mapping. The only permissionless entry point (`deployToken`) costs the caller liquidity
 * and permanently locks the LP it creates (net loss). E-U = $0.
 *
 * Read-only: all calls are eth_call / fork-simulated; no mainnet transactions are sent.
 */
contract G8keepTest is Test {
    address constant FACTORY  = 0x3C0B43867Cd04fEdfD6a95497e5ea7e3aFF8cCaE;
    address constant WETH     = 0x4200000000000000000000000000000000000006;
    address constant OWNER    = 0x28253c1A76256bf1D9095587826AfCC5705aF98a;
    address constant PENALTY  = 0x3Ac64A6BeBeBc576bEf52fC22eD5E3C64BEE4462;
    address constant VESTER   = 0x254b4A4222285BAa10E6eFce66a6EcfdF5d807A9;

    // Representative locked pairs (largest WETH first).
    address constant PAIR_HUH  = 0xc7d9143A9753ba6f49FBBb5E803C949c1E310CeD; // 17.27 ETH WETH reserve
    address constant PAIR_2    = 0x204691BB36E37E19094f4bE3BE8FDFfDFaB85333;
    address constant PAIR_TRI  = 0x5688535130cB09cD9dA2af937EeF55901f466d78; // from triage

    IG8keepFactory factory = IG8keepFactory(FACTORY);
    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
        vm.deal(attacker, 100 ether);
        vm.label(attacker, "attacker");
        vm.label(FACTORY, "g8keepFactory");
        emit log_named_uint("fork block", block.number);
    }

    // ------------------------------------------------------------------
    // 1. Live state: roles, locks, LP custody
    // ------------------------------------------------------------------
    function test_A_live_state() public view {
        assertEq(factory.owner(), OWNER, "factory owner");
        assertEq(factory.WETH(), WETH, "WETH");
        assertEq(factory.g8keepFeeWallet(), OWNER, "fee wallet == owner");
        assertEq(factory.penaltyReceiver(), PENALTY, "penalty receiver");
        assertEq(factory.g8keepTokenVesting(), VESTER, "vester");
        assertEq(factory.g8keepFee(), 100, "g8keep fee 1%");
        assertEq(factory.g8keepInitialLiquidityFee(), 200, "init liq fee 2%");
        assertTrue(factory.allowedPairs(WETH), "WETH allowed");
        assertEq(factory.pairedTokenMinimumLiquidity(WETH), 0.01 ether, "min liq");

        // factory holds ~100% of each pair's LP and the LP is flagged locked
        address[3] memory pairs = [PAIR_HUH, PAIR_2, PAIR_TRI];
        for (uint256 i; i < pairs.length; ++i) {
            uint256 lpBal = IUniswapV2Pair(pairs[i]).balanceOf(FACTORY);
            uint256 lpTot = IUniswapV2Pair(pairs[i]).totalSupply();
            assertGt(lpBal * 10000 / lpTot, 9990, "factory owns >99.9% LP");
            uint256 lockSlot = uint256(vm.load(FACTORY, keccak256(abi.encode(pairs[i], uint256(6)))));
            assertEq(lockSlot, 1, "lockedTokens[pair] == 1");
        }

        // factory holds no native and no WETH
        assertEq(FACTORY.balance, 0, "factory ETH = 0");
        assertEq(IERC20(WETH).balanceOf(FACTORY), 0, "factory WETH = 0");
    }

    // ------------------------------------------------------------------
    // 2. Owner-only paths must revert for a fresh attacker
    // ------------------------------------------------------------------
    function test_B_withdrawToken_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(); // Solady Ownable: Unauthorized()
        factory.withdrawToken(PAIR_HUH, attacker);
    }

    function test_C_withdrawETH_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        factory.withdrawETH(attacker);
    }

    function test_D_sellTokens_reverts() public {
        IG8keepFactory.TokenSale[] memory sales = new IG8keepFactory.TokenSale[](0);
        vm.prank(attacker);
        vm.expectRevert();
        factory.sellTokens(sales, block.timestamp);
    }

    // ------------------------------------------------------------------
    // 3. Allowlist / recipient-only paths must revert
    // ------------------------------------------------------------------
    function test_E_penaltyReceiver_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(); // NotAllowed()
        IG8keepPenaltyReceiver(PENALTY).transferToken(WETH, attacker, 1);
    }

    function test_F_vester_claim_reverts() public {
        uint256 n = IG8keepVester(VESTER).nextVestingId();
        assertGt(n, 0, "vestings exist");
        vm.prank(attacker);
        vm.expectRevert(); // InvalidCaller()
        IG8keepVester(VESTER).claim(0);
    }

    // ------------------------------------------------------------------
    // 4. The locked LP cannot be moved or burned by anyone
    // ------------------------------------------------------------------
    function test_G_pair_burn_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"));
        IUniswapV2Pair(PAIR_HUH).burn(attacker);
    }

    function test_H_lp_transferFrom_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(); // arithmetic underflow / no allowance
        IUniswapV2Pair(PAIR_HUH).transferFrom(FACTORY, attacker, 1);
    }

    // ------------------------------------------------------------------
    // 5. skim() is permissionless but yields nothing (no excess balances)
    // ------------------------------------------------------------------
    function test_I_skim_yields_nothing() public {
        uint256 before = IERC20(WETH).balanceOf(attacker);
        vm.prank(attacker);
        IUniswapV2Pair(PAIR_HUH).skim(attacker);
        assertEq(IERC20(WETH).balanceOf(attacker), before, "no WETH skimmed");
    }

    // ------------------------------------------------------------------
    // 6. The only permissionless entry point (deployToken) is a net loss:
    //    caller pays liquidity + 2% fee and the LP it creates is locked.
    // ------------------------------------------------------------------
    function test_J_deployToken_locks_own_liquidity() public {
        uint256 feeBefore = IERC20(WETH).balanceOf(factory.g8keepFeeWallet());
        uint256 liq = 0.01 ether; // == pairedTokenMinimumLiquidity[WETH]

        address token;
        for (uint256 i; i < 32 && token == address(0); ++i) {
            try factory.deployToken{value: liq}(
                liq, "T", "T", 1_000_000e18, attacker, 0, 0, WETH, 0,
                1 days, 30 minutes, 30 minutes, 20, bytes32(i)
            ) returns (address t) {
                token = t;
            } catch {}
        }
        assertTrue(token != address(0), "deploy succeeded");

        // 2% initial-liquidity fee went to the fee wallet
        uint256 feeDelta = IERC20(WETH).balanceOf(factory.g8keepFeeWallet()) - feeBefore;
        assertEq(feeDelta, liq * 200 / 10000, "2% fee taken");

        // the LP the attacker just created is held by the factory and locked
        address pair = IG8keepToken(token).UNISWAP_V2_PAIR();
        assertGt(IUniswapV2Pair(pair).balanceOf(FACTORY), 0, "factory holds LP");
        uint256 lockSlot = uint256(vm.load(FACTORY, keccak256(abi.encode(pair, uint256(6)))));
        assertEq(lockSlot, 1, "new LP locked");

        // even the deployer cannot withdraw it (owner-only + locked)
        vm.prank(attacker);
        vm.expectRevert();
        factory.withdrawToken(pair, attacker);
    }
}
