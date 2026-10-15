// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2, Vm} from "forge-std/Test.sol";

/// Minimal ERC20 interface (avoid depending on lib layout)
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

/// Minimal IOTA EVM Liquidity Book surface (joe-v2 v2.2.0 fork, deployed verbatim by MagicSea)
interface ILBPair {
    function getTokenX() external view returns (address);
    function getTokenY() external view returns (address);
    function getBinStep() external view returns (uint16);
    function getActiveId() external view returns (uint24);
    function getFactory() external view returns (address);
    function getBin(uint24 id) external view returns (uint128, uint128);
    function totalSupply(uint256 id) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function getReserves() external view returns (uint128, uint128);
    function getProtocolFees() external view returns (uint128, uint128);
    function getStaticFeeParameters() external view returns (uint16, uint16, uint16, uint16, uint24, uint16, uint24);
    function getLBHooksParameters() external view returns (bytes32);

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32);
    function setStaticFeeParameters(uint16, uint16, uint16, uint16, uint24, uint16, uint24) external;
    function setHooksParameters(bytes32 hooksParameters, bytes calldata onHooksSetData) external;
}

error LBPair__OnlyProtocolFeeRecipient();
error LBPair__OnlyFactory();

/**
 * @title MagicSea (IOTA EVM, chain 8822) — zombie-hunt II PoC / negative-result harness
 *
 * Target: MagicSea DEX = verbatim Trader Joe Liquidity Book v2.2.0 deployment (verified by
 * source-diff against traderjoe-xyz/joe-v2 tag v2.2.0, commit 1297c3822f, 2024-03-20) plus a
 * classic Uniswap-V2 (Joe V1 style) fork and a Merchant-Moe-derived LB hooks rewarder.
 *
 * The only known upstream semantic delta vs joe-v2 `main` (2024-07-08) is the composition-fee
 * share formula inside `LBPair._updateBin` (upstream fix commit 7e5b0b4944 "Fix the composition
 * fee calculation", 2024-07-04). The deployed pair still contains the pre-fix expression:
 *
 *     uint256 binLiquidity = binReserves.getLiquidity(price);
 *     shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
 *
 * instead of the fixed
 *
 *     uint256 binLiquidity = binReserves.add(fees.sub(protocolCFees)).getLiquidity(price);
 *
 * This harness measures, on the live USDC.e/USDT pool (the deepest pool, ~$127k TVL at the
 * pinned block), whether an unprivileged attacker can turn that composition-fee discrepancy
 * into positive PnL (E-U), and asserts the access-control gates (no unprivileged admin paths).
 *
 * Fork: IOTA EVM public RPC (no key), pinned block 13020932 (2026-10-15).
 */
contract MagicSeaTest is Test {
    // ---- live addresses (IOTA EVM, chain 8822) ----
    string constant RPC_MAINNET = "https://json-rpc.evm.iotaledger.net";
    uint256 constant PINNED_BLOCK = 13_020_932;

    ILBPair constant PAIR_USDCE_USDT = ILBPair(0xE919092CC7CBD2097ae3158f72Da484ac813b74b);
    address constant USDC_E = 0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6; // tokenX, 6 dec
    address constant USDT = 0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4; // tokenY, 6 dec
    address constant LB_FACTORY = 0x8Cce20D17aB9C6F60574e678ca96711D907fD08c;

    uint256 constant ACTIVE_ID = 8_388_608;
    uint256 constant PRECISION = 1e18;

    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(RPC_MAINNET, PINNED_BLOCK);
    }

    /// @dev Liquidity Book config: [0-24) id | [24-88) distributionY | [88-152) distributionX (1e18)
    function _config(uint64 distributionX, uint64 distributionY, uint24 id) internal pure returns (bytes32) {
        return bytes32((uint256(distributionX) << 88) | (uint256(distributionY) << 24) | uint256(id));
    }

    function _fund(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
        require(IERC20(token).balanceOf(to) == amount, "deal failed");
    }

    /// @dev Snapshot of the target pool at the pinned block.
    function test_livePoolState_snapshot() public view {
        (uint128 rX, uint128 rY) = PAIR_USDCE_USDT.getReserves();
        (uint128 bX, uint128 bY) = PAIR_USDCE_USDT.getBin(uint24(ACTIVE_ID));
        (uint128 pX, uint128 pY) = PAIR_USDCE_USDT.getProtocolFees();
        (uint16 baseFactor,,,, uint24 variableFeeControl, uint16 protocolShare,) =
            PAIR_USDCE_USDT.getStaticFeeParameters();

        console2.log("pair tokenX (USDC.e)", PAIR_USDCE_USDT.getTokenX());
        console2.log("pair total reserves X (USDC.e, 6dec)", rX);
        console2.log("pair total reserves Y (USDT, 6dec)  ", rY);
        console2.log("active bin X (6dec)", bX);
        console2.log("active bin Y (6dec)", bY);
        console2.log("totalSupply(activeId)", PAIR_USDCE_USDT.totalSupply(ACTIVE_ID));
        console2.log("protocol fees pending X", pX);
        console2.log("protocol fees pending Y", pY);
        console2.log("baseFactor", baseFactor);
        console2.log("variableFeeControl", variableFeeControl);
        console2.log("protocolShare (1e4)", protocolShare);
        console2.log("binStep", PAIR_USDCE_USDT.getBinStep());
        console2.log("activeId", PAIR_USDCE_USDT.getActiveId());

        assertEq(PAIR_USDCE_USDT.getTokenX(), USDC_E);
        assertEq(PAIR_USDCE_USDT.getTokenY(), USDT);
        assertEq(PAIR_USDCE_USDT.getActiveId(), ACTIVE_ID);
        assertEq(PAIR_USDCE_USDT.getFactory(), LB_FACTORY);
    }

    /// @dev CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees)
    bytes32 constant COMPOSITION_FEES_TOPIC =
        keccak256("CompositionFees(address,uint24,bytes32,bytes32)");

    /**
     * @dev MAIN NEGATIVE RESULT.
     * Attacker maxes the composition fee: deposits USDC.e (tokenX) ONLY into the active bin.
     * The imbalance is bounded by the bin's USDT side, so the composition fee is capped
     * (~k * active-bin USDT reserve). Attacker then burns everything in the same tx-like sequence.
     *
     * Expected: PnL < 0, and |PnL| ~= protocolShare * compositionFee (the attacker recovers the
     * LP fee via the pre-fix over-minted shares but can never recover the protocol's cut) —
     * i.e. no extractable value; the discrepancy only makes the attacker's *cost* smaller than
     * the honest fee (a "fee bypass", bounded by the composition fee itself).
     */
    function test_compositionFee_mintBurnRoundTrip_isNeverProfitable() public {
        uint256[3] memory sizes = [uint256(200_000e6), 2_000_000e6, 20_000_000e6];
        int256 prevLoss = -1;

        for (uint256 s; s < sizes.length; ++s) {
            uint256 depositX = sizes[s];

            _fund(USDC_E, attacker, depositX);
            uint256 x0 = IERC20(USDC_E).balanceOf(attacker);
            uint256 y0 = IERC20(USDT).balanceOf(attacker);

            bytes32[] memory configs = new bytes32[](1);
            configs[0] = _config(uint64(PRECISION), 0, uint24(ACTIVE_ID)); // 100% tokenX, 0% tokenY

            vm.recordLogs();
            vm.startPrank(attacker);
            IERC20(USDC_E).transfer(address(PAIR_USDCE_USDT), depositX);
            PAIR_USDCE_USDT.mint(attacker, configs, attacker);
            uint256 shares = PAIR_USDCE_USDT.balanceOf(attacker, ACTIVE_ID);

            uint256[] memory ids = new uint256[](1);
            ids[0] = ACTIVE_ID;
            uint256[] memory amts = new uint256[](1);
            amts[0] = shares;
            PAIR_USDCE_USDT.burn(attacker, attacker, ids, amts);
            vm.stopPrank();

            // decode the CompositionFees event emitted by the pair's mint
            (uint256 feeX, uint256 feeY) = _lastCompositionFees();

            uint256 x1 = IERC20(USDC_E).balanceOf(attacker);
            uint256 y1 = IERC20(USDT).balanceOf(attacker);

            int256 pnl = int256(x1 + y1) - int256(x0 + y0); // both legs ~= $1 (6 decimals)

            console2.log("--- composition mint+burn ---");
            console2.log("deposit X (USDC.e, 6dec)", depositX);
            console2.log("shares minted (active bin)", shares);
            console2.log("CompositionFees feeX (6dec)", feeX);
            console2.log("CompositionFees feeY (6dec)", feeY);
            console2.log("USDC.e balance end", x1);
            console2.log("USDT   balance end", y1);
            console2.log("PNL raw (6dec, ~USD cents)", pnl);

            // No extractable value: round trip must not be profitable.
            assertLe(pnl, 0, "composition mint+burn must never be profitable");

            // Loss must be bounded by the composition fee the minter paid (it can at most
            // recover fee - protocolCut via the over-minted shares).
            assertLe(uint256(-pnl), feeX + feeY + 2, "loss must be bounded by the composition fee");

            prevLoss = pnl;
        }
        assertLt(prevLoss, 0, "at least the largest size must show a strict loss");
    }

    /// @dev Decodes the last CompositionFees log recorded by vm.recordLogs().
    function _lastCompositionFees() internal returns (uint256 feeX, uint256 feeY) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = logs.length; i > 0; --i) {
            Vm.Log memory l = logs[i - 1];
            if (l.topics.length == 2 && l.topics[0] == COMPOSITION_FEES_TOPIC) {
                (, bytes32 totalFees,) = abi.decode(l.data, (uint24, bytes32, bytes32));
                feeX = uint256(totalFees) >> 128;
                feeY = uint256(uint128(uint256(totalFees)));
                return (feeX, feeY);
            }
        }
        revert("CompositionFees not emitted");
    }

    /**
     * @dev The other direction: deposit USDT (tokenY) only. Counterpart side (USDC.e) is much
     * smaller, so the cap is lower; still no profit.
     */
    function test_compositionFee_ySideDeposit_isNeverProfitable() public {
        uint256 depositY = 50_000_000e6; // $50M, far above the cap knee
        _fund(USDT, attacker, depositY);

        uint256 x0 = IERC20(USDC_E).balanceOf(attacker);
        uint256 y0 = IERC20(USDT).balanceOf(attacker);

        bytes32[] memory configs = new bytes32[](1);
        configs[0] = _config(0, uint64(PRECISION), uint24(ACTIVE_ID)); // 100% tokenY

        vm.startPrank(attacker);
        IERC20(USDT).transfer(address(PAIR_USDCE_USDT), depositY);
        PAIR_USDCE_USDT.mint(attacker, configs, attacker);
        uint256 shares = PAIR_USDCE_USDT.balanceOf(attacker, ACTIVE_ID);

        uint256[] memory ids = new uint256[](1);
        ids[0] = ACTIVE_ID;
        uint256[] memory amts = new uint256[](1);
        amts[0] = shares;
        PAIR_USDCE_USDT.burn(attacker, attacker, ids, amts);
        vm.stopPrank();

        int256 pnl = int256(IERC20(USDC_E).balanceOf(attacker) + IERC20(USDT).balanceOf(attacker))
            - int256(x0 + y0);
        console2.log("Y-side PNL raw (6dec)", pnl);
        assertLe(pnl, 0, "Y-side composition mint+burn must never be profitable");
    }

    /// @dev Unprivileged caller cannot pull accumulated protocol fees.
    function test_collectProtocolFees_isGated() public {
        vm.prank(attacker);
        vm.expectRevert(LBPair__OnlyProtocolFeeRecipient.selector);
        PAIR_USDCE_USDT.collectProtocolFees();
    }

    /// @dev Unprivileged caller cannot retune static fees or install hooks.
    function test_adminFeesAndHooks_areGated() public {
        vm.startPrank(attacker);
        vm.expectRevert(LBPair__OnlyFactory.selector);
        PAIR_USDCE_USDT.setStaticFeeParameters(1, 1, 1, 1, 1, 1, 1);

        vm.expectRevert(LBPair__OnlyFactory.selector);
        PAIR_USDCE_USDT.setHooksParameters(bytes32(0), "");
        vm.stopPrank();
    }

    /// @dev Sanity: the composition-fee path exists and is reachable by anyone (proves we tested
    /// the right code path, not a revert).
    function test_compositionFee_path_isReachable() public {
        _fund(USDC_E, attacker, 100_000e6);
        uint256 supplyBefore = PAIR_USDCE_USDT.totalSupply(ACTIVE_ID);

        bytes32[] memory configs = new bytes32[](1);
        configs[0] = _config(uint64(PRECISION), 0, uint24(ACTIVE_ID));

        vm.startPrank(attacker);
        IERC20(USDC_E).transfer(address(PAIR_USDCE_USDT), 100_000e6);
        (,, uint256[] memory minted) = PAIR_USDCE_USDT.mint(attacker, configs, attacker);
        vm.stopPrank();

        assertGt(minted[0], 0, "mint must succeed");
        assertGt(PAIR_USDCE_USDT.totalSupply(ACTIVE_ID), supplyBefore, "supply must grow");
    }
}
