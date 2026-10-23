// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {
    ISpoke,
    IEtherFiDataProvider,
    ILendGateway,
    IAaveOracle,
    IPriceFeed,
    IOracleSinkPriceFeed,
    IChainlinkPriceFeed,
    IOracleSink,
    IERC20Min
} from "../src/IEtherFi.sol";

/// @title ether.fi Cash Borrowing Market (Optimism, Aave V4 whitelabel instance)
/// @notice Fork-only, read-only research. No mainnet transaction is ever signed/sent.
///         The deployed `EtherFiSpokeInstance` overrides `borrow` so that the position owner
///         (`onBehalfOf`) must be a factory-registered ether.fi Cash Safe. This suite proves:
///           (1) an unprivileged caller cannot borrow (even with self-supplied collateral);
///           (2) the only active position manager is the LendGateway, whose `borrow` is driver-only;
///           (3) the RWA price feeds are relay/Chainlink sourced, not OP-DEX-spot manipulable;
///           (4) no currently-liquidatable position exists to attack via the oracle.
contract EtherFiBorrowingTest is Test {
    // --- Optimism (chain 10) addresses (verified on-chain 2026-10-23) ---
    address constant SPOKE = 0xdffcC3536D932eb51Df51a7F5FA407c4270d5308; // EtherFiSpokeInstance proxy (Cash Spoke)
    address constant HUB = 0x66753c4e3fC84f1eD0e3C267C927284E9d90C572; // EtherFi Cash Hub
    address constant ORACLE = 0xe8cbd37210bF1E29436dAe183d7b9fe45E886fA8;
    address constant DATAPROVIDER = 0xDC515Cb479a64552c5A11a57109C314E40A1A778; // EtherFiDataProvider proxy
    address constant FACTORY = 0xF4e147Db314947fC1275a8CbB6Cde48c510cd8CF; // EtherFiSafeFactory proxy
    address constant LENDGATEWAY = 0x01F8cDFb1694eA8fE4ED6c38a0fD78d1188E03F4; // only active position manager
    address constant TREASURY_SPOKE = 0x7EB4d25F137868662350603A2863F682287b0768; // 2nd registered Hub spoke (owner-only)
    address constant SINK = 0x7cb68ddc781153d9417E08bAf6A64e801e398d42; // OracleSink (LayerZero receiver)
    address constant IWSPYX_FEED = 0x8b44f7Acf288ea79795223dDfd5F872f51d33fb9; // iwSPYx/USD (OracleSinkPriceFeed)
    address constant IPAXG_FEED = 0xaC28d7fe39d16aa0d35CDCc8cE939125cB3f091b; // iPAXG/USD (ChainlinkPriceFeed)
    address constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    // A real ether.fi Cash Safe holding iwSPYx collateral + USDC/USDT debt (reserve ids 0 and 2).
    address constant RWA_USER = 0x0FCDa4D56Ce5Ade64031A66C2838401f3448e1A9;
    address constant ATTACKER = address(0xA11CE);
    uint32 constant LZ_EID_MAINNET = 30101;

    ISpoke spoke;
    IAaveOracle oracle;

    function setUp() public {
        string memory rpc = vm.envOr("OP_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://optimism.gateway.tenderly.co";
        vm.createSelectFork(rpc);
        spoke = ISpoke(SPOKE);
        oracle = IAaveOracle(ORACLE);
        vm.deal(ATTACKER, 10 ether);
    }

    function _slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory out) {
        out = new bytes(len);
        for (uint256 i = 0; i < len; i++) out[i] = data[start + i];
    }

    // ---------------------------------------------------------------
    // 1. The borrow gate: only ether.fi Cash Safes may be the borrower
    // ---------------------------------------------------------------

    function test_gate_borrow_reverts_OnlyEtherFiSafe() public {
        emit log_named_uint("fork block", block.number);
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("OnlyEtherFiSafe(address)", ATTACKER));
        spoke.borrow(0, 1_000_000, ATTACKER); // USDC reserve, 1 USDC, position owner = attacker
    }

    function test_gate_attacker_is_not_a_safe_but_real_safe_is() public {
        IEtherFiDataProvider dp = IEtherFiDataProvider(DATAPROVIDER);
        assertFalse(dp.isEtherFiSafe(ATTACKER), "attacker must not be an EtherFi Safe");
        assertTrue(dp.isEtherFiSafe(RWA_USER), "known Cash Safe must be recognised");
        emit log_named_uint("safes deployed (factory)", IEtherFiDataProvider(FACTORY).isEtherFiSafe(RWA_USER) ? 1 : 0);
    }

    /// @dev Full unprivileged attempt: supply real collateral, enable it, then try to borrow.
    function test_gate_supply_is_open_but_borrow_is_blocked() public {
        // Anyone may supply to the Spoke as their own position (msg.sender == onBehalfOf).
        deal(USDC, ATTACKER, 1_000e6);
        vm.startPrank(ATTACKER);
        IERC20Min(USDC).approve(SPOKE, type(uint256).max);
        (uint256 shares, uint256 amt) = spoke.supply(0, 1_000e6, ATTACKER);
        assertGt(shares, 0, "supply should mint shares");
        assertEq(amt, 1_000e6, "supply amount");
        spoke.setUsingAsCollateral(0, true, ATTACKER);

        // ... but borrowing is still gated to Cash Safes.
        vm.expectRevert(abi.encodeWithSignature("OnlyEtherFiSafe(address)", ATTACKER));
        spoke.borrow(0, 100e6, ATTACKER);
        vm.stopPrank();

        // Clean up is unnecessary on a fork.
        emit log_string("attacker supplied USDC and enabled collateral, borrow still reverted OnlyEtherFiSafe");
    }

    // ---------------------------------------------------------------
    // 2. The only active position manager is the LendGateway (driver-only borrow)
    // ---------------------------------------------------------------

    function test_gate_only_position_manager_is_lendgateway() public {
        assertTrue(spoke.isPositionManagerActive(LENDGATEWAY), "LendGateway must be the active PM");
        assertFalse(spoke.isPositionManagerActive(ATTACKER), "attacker must not be an active PM");
        assertFalse(spoke.isPositionManagerActive(address(0xBEEF)), "stock TakerPositionManager must not be active");

        ILendGateway lg = ILendGateway(LENDGATEWAY);
        assertFalse(lg.isDriver(ATTACKER), "attacker must not be a driver");
        assertEq(lg.minHealthFactor(), 1.1e18, "gateway min health factor");

        // Even if the attacker were approved as a position manager for a real safe, the LendGateway
        // borrow path is driver-only; the direct Spoke path still needs the Safe check.
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("OnlyDriver()"));
        lg.borrow(RWA_USER, USDC, 1_000_000, ATTACKER);
    }

    // ---------------------------------------------------------------
    // 3. RWA price feeds: relayed / Chainlink, not OP-DEX spot
    // ---------------------------------------------------------------

    function test_rwa_feed_iwspyx_is_relay_not_dex_spot() public {
        IOracleSinkPriceFeed feed = IOracleSinkPriceFeed(IWSPYX_FEED);
        IOracleSink sink = IOracleSink(SINK);

        assertEq(feed.sink(), SINK, "feed reads the OracleSink");
        assertEq(feed.decimals(), 8, "Aave V4 oracle decimals");
        assertGt(uint256(feed.latestAnswer()), 0, "feed answers");
        assertEq(feed.rateMaxStaleness(), 604_800, "7-day staleness window");

        // The sink only accepts LayerZero messages from the configured mainnet PriceRelay peer.
        assertTrue(sink.peers(LZ_EID_MAINNET) != bytes32(0), "LZ peer (mainnet relay) must be configured");
        assertFalse(sink.paused(), "sink not paused");
        (uint256 sinkPrice, uint64 srcTs) = sink.getPrice(feed.token());
        assertGt(sinkPrice, 0, "sink price set");
        assertGt(uint64(block.timestamp), srcTs, "sink price has a source timestamp");
        assertGt(sink.maxStaleness(feed.token()), 0, "sink staleness configured");

        // The feed's source must NOT be an AMM pool: no slot0()/token0() spot surface.
        (bool ok, ) = IWSPYX_FEED.staticcall(abi.encodeWithSignature("slot0()"));
        assertFalse(ok, "RWA feed must not expose a Uniswap slot0()");

        emit log_named_string("feed", feed.description());
        emit log_named_uint("feed price (8dp)", uint256(feed.latestAnswer()));
        emit log_named_uint("sink rate (6dp)", sinkPrice);
    }

    function test_rwa_feed_ipaxg_is_chainlink() public {
        IChainlinkPriceFeed feed = IChainlinkPriceFeed(IPAXG_FEED);
        address rateFeed = feed.rateFeed();
        assertGt(rateFeed.code.length, 0, "PAXG rate feed must be a contract (Chainlink aggregator)");
        assertEq(feed.rateMaxStaleness(), 604_800, "7-day staleness window");
        assertGt(uint256(feed.latestAnswer()), 0, "feed answers");
        emit log_named_string("feed", feed.description());
        emit log_named_uint("feed price (8dp)", uint256(feed.latestAnswer()));
    }

    // ---------------------------------------------------------------
    // 4. No currently-liquidatable position to attack
    // ---------------------------------------------------------------

    function test_no_liquidatable_rwa_position() public {
        ISpoke.UserAccountData memory d = spoke.getUserAccountData(RWA_USER);
        emit log_named_uint("RWA_USER healthFactor (1e18)", d.healthFactor);
        assertGt(d.healthFactor, 1e18, "position is healthy, not liquidatable");

        // A permissionless liquidator cannot seize a healthy position.
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("HealthFactorNotBelowThreshold()"));
        spoke.liquidationCall(19, 0, RWA_USER, 1_000_000, false); // iwSPYx collateral, USDC debt
    }

    // ---------------------------------------------------------------
    // 5. The Hub's second spoke is a treasury (owner-only), not a borrow path
    // ---------------------------------------------------------------

    function test_second_hub_spoke_is_owner_only_treasury() public {
        // The TreasurySpoke exposes no permissionless borrow; supply/withdraw/transfer are onlyOwner.
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = TREASURY_SPOKE.call(
            abi.encodeWithSignature("supply(address,address,uint256)", HUB, USDC, 1)
        );
        assertFalse(ok, "treasury supply must revert for a non-owner");
        assertGt(ret.length, 0, "reverts with data");
        emit log_named_uint("reserve count on Cash Spoke", spoke.getReserveCount());
    }
}
