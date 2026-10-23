// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "forge-std/Test.sol";

import {MockHTS, MockExchangeRate} from "../src/mocks/MockHTS.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockNFT} from "../src/mocks/MockNFT.sol";
import {MockWHBAR} from "../src/mocks/MockWHBAR.sol";
import {Minter} from "../src/mocks/Minter.sol";

import {UniswapV3Factory} from "../src/core/UniswapV3Factory.sol";
import {IUniswapV3Pool} from "../src/core/interfaces/IUniswapV3Pool.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {INonfungiblePositionManager} from "../src/periphery/interfaces/INonfungiblePositionManager.sol";

/// @title SaucerSwap V2 (Hedera) — unprivileged-path / auth-gate PoC
/// @notice Local (non-forked) harness. Hedera HTS/HAS precompiles (0x167, 0x168) are mocked so the
/// deployed SaucerSwap V2 source can be exercised. Every candidate unprivileged value path is
/// expected to revert or return zero; the positive paths are exercised to prove the harness is real.
contract SaucerSwapAuthTest is Test {
    address constant HTS = address(0x167);
    address constant XR = address(0x168);

    UniswapV3Factory factory;
    MockNFT nft;
    MockWHBAR whbar;
    MockERC20 whbarToken;
    NonfungiblePositionManager nfpm;

    MockERC20 t0;
    MockERC20 t1;
    address pool;

    address victim = address(0x1111);
    address attacker = address(0xBADD);

    int24 constant LO = -60000;
    int24 constant HI = 60000;
    uint128 constant L = 1e15;

    function setUp() public {
        // --- Hedera system-contract mocks ---
        nft = new MockNFT();
        MockHTS hts = new MockHTS(address(nft));
        MockExchangeRate xr = new MockExchangeRate();
        vm.etch(HTS, address(hts).code);
        vm.etch(XR, address(xr).code);

        // --- real SaucerSwap V2 core + periphery ---
        whbarToken = new MockERC20("WHBAR", "WHBAR", 8);
        whbar = new MockWHBAR(address(whbarToken));
        factory = new UniswapV3Factory(); // owner == this test
        nfpm = new NonfungiblePositionManager(address(factory), address(whbar)); // deployer == this test
        nfpm.createNonFungible(address(this), 7776000);

        // --- tokens + pool ---
        t0 = new MockERC20("T0", "T0", 18);
        t1 = new MockERC20("T1", "T1", 18);
        pool = factory.createPool(address(t0), address(t1), 3000);
        IUniswapV3Pool(pool).initialize(uint160(2 ** 96));

        // --- LP NFT serials: 1 -> victim, 2 -> this ---
        nft.mintTo(victim, "");
        nft.mintTo(address(this), "");
    }

    // ------------------------------------------------------------------
    // Harness sanity: deployed source behaves as the real thing
    // ------------------------------------------------------------------
    function test_harness_nfpm_wired() public view {
        assertEq(nfpm.nft(), address(nft));
        assertEq(nfpm.deployer(), address(this));
        assertEq(factory.owner(), address(this));
        assertEq(nft.ownerOf(1), victim);
        assertTrue(pool != address(0));
    }

    function test_harness_pool_mint_burn_collect_owner() public {
        Minter minter = _fundedMinter();
        minter.doMint(LO, HI, L);
        minter.doBurn(LO, HI, L);
        (uint128 a0, uint128 a1) = minter.doCollect(address(minter), LO, HI);
        assertGt(uint256(a0) + uint256(a1), 0, "owner should collect its own owed");
    }

    // ------------------------------------------------------------------
    // NFPM: every value path is bound to the LP-NFT owner (cross-collection & tokenSN confusion)
    // ------------------------------------------------------------------
    function test_NFPM_decreaseLiquidity_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert("not authorized");
        nfpm.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenSN: 1,
                liquidity: 1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 1000
            })
        );
    }

    function test_NFPM_collect_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert("not authorized");
        nfpm.collect(
            INonfungiblePositionManager.CollectParams({
                tokenSN: 1,
                recipient: attacker,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function test_NFPM_burn_nonOwner_reverts() public {
        vm.prank(attacker);
        vm.expectRevert("not authorized");
        nfpm.burn(1);
    }

    /// @dev Even a tokenSN that has NO internal position cannot be used to reach another user's
    ///      position: the NFT owner is checked first and there is no cross-collection fallback.
    function test_NFPM_unmintedSerial_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        nfpm.collect(
            INonfungiblePositionManager.CollectParams({
                tokenSN: 424242,
                recipient: attacker,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    // ------------------------------------------------------------------
    // Pool: position value is keyed by msg.sender; collectProtocol is factory-owner only
    // ------------------------------------------------------------------
    function test_Pool_stranger_cannot_collect_others_position() public {
        Minter minter = _fundedMinter();
        minter.doMint(LO, HI, L);
        minter.doBurn(LO, HI, L / 2); // create owed for the minter's position

        // a stranger asks for the max on the same tick range
        vm.prank(attacker);
        (uint128 s0, uint128 s1) =
            IUniswapV3Pool(pool).collect(attacker, LO, HI, type(uint128).max, type(uint128).max);
        assertEq(uint256(s0) + uint256(s1), 0, "stranger must get nothing");

        // the real owner still collects its owed
        (uint128 o0, uint128 o1) = minter.doCollect(address(minter), LO, HI);
        assertGt(uint256(o0) + uint256(o1), 0, "owner must still be able to collect");
    }

    function test_Pool_collectProtocol_onlyFactoryOwner() public {
        vm.deal(pool, 1 ether); // simulate accumulated native HBAR (mint fees)
        vm.prank(attacker);
        vm.expectRevert();
        IUniswapV3Pool(pool).collectProtocol(attacker, 0, 0);
    }

    function test_Pool_collectProtocol_owner_sweeps_hbar_to_rentPayer() public {
        vm.deal(pool, 1 ether);
        address rentPayer = address(0xFEE);
        factory.setRentPayer(rentPayer); // only the factory owner (this test) can do this
        IUniswapV3Pool(pool).collectProtocol(address(this), 0, 0);
        assertEq(rentPayer.balance, 1 ether, "pool HBAR goes to rentPayer (privileged)");
    }

    // ------------------------------------------------------------------
    // Periphery sweep helpers: permissionless, but only move balances already in the contract
    // ------------------------------------------------------------------
    function test_NFPM_refundETH_permissionless_sweeps_contract_balance() public {
        vm.deal(address(nfpm), 1 ether); // HBAR accidentally left in the NFPM
        vm.prank(attacker);
        nfpm.refundETH();
        assertEq(attacker.balance, 1 ether, "leftover HBAR is sweepable by anyone");
        assertEq(address(nfpm).balance, 0);
    }

    // ------------------------------------------------------------------
    function _fundedMinter() internal returns (Minter minter) {
        minter = new Minter(pool, address(t0), address(t1));
        t0.mint(address(minter), 1e30);
        t1.mint(address(minter), 1e30);
    }
}
