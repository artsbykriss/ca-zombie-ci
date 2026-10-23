// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

/* =====================================================================================
   saturn-susdat — fresh-attacker fork PoC (READ-ONLY research; fork-only; no mainnet txs)
   Target: Saturn Protocol sUSDat v2  (ERC1967 proxy 0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7
           -> impl 0x2b7074cf6681382b70e239063931ebe83c0f4e0a, "StakedUSDat" v2)
   Question: can an unprivileged caller (no roles/keys) mint/redeem at a mispriced rate,
             donate/inflate, or withdraw others' assets?
   ===================================================================================== */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function usdatBalance() external view returns (uint256);
    function asset() external view returns (address);
    function decimals() external view returns (uint8);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxRedeem(address) external view returns (uint256);
    function requestRedeem(uint256 shares, uint256 minSharePrice) external returns (uint256 requestId);
    function sweep() external;
    function paused() external view returns (bool);
    function marketMode() external view returns (uint8);
    function depositFeeBps() external view returns (uint256);
    function redemptionFeeBps() external view returns (uint16);
    function strcMirrorModule() external view returns (address);
    function strconModule() external view returns (address);
    function getWithdrawalQueue() external view returns (address);
    // privileged / value-moving
    function transferInSurplus(uint256 amount) external;
    function migrate(uint256 expectedStrcon, uint256 deadline) external;
    function buy(uint256 usdatPaid, uint256 assetReceived, address expectedVehicle, uint256 deadline) external;
    function sell(uint256 assetDelivered, uint256 usdatReceived, address expectedVehicle, uint256 deadline) external;
    function beginRedemptionBatch() external;
    function redeemQueuedShares(uint256 shares, uint256 minSharePrice) external returns (uint8, uint256);
    function endRedemptionBatch() external;
    function seize(address from) external;
    function rescueTokens(address token, uint256 amount) external;
    function setMarketMode(uint8 newMode) external;
    function setRedemptionFees(uint16 baseBps, uint16 elevatedBps) external;
    function setElevatedDepositFee(uint256) external;
    function setMigrationTolerance(uint16) external;
    function setSurplusSource(address) external;
    function setRecoveryAddress(address) external;
    function setSurplusVestingPeriod(uint256) external;
    function pause() external;
    function unpause() external;
}

interface IQueue {
    function nextTokenId() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function processRequests(uint256[] calldata tokenIds) external;
    function cancelRequest(uint256 tokenId) external;
    function claim(uint256 tokenId) external returns (uint256);
    function addRequest(address user, uint256 shares, uint256 minSharePrice) external returns (uint256);
    function seize(uint256 tokenId) external;
    function resetLegacyInProgressRequest(uint256 tokenId) external;
}

interface IModule {
    function recognizedValue() external view returns (uint256);
    function balance() external view returns (uint256);
    function VAULT() external view returns (address);
}

contract SaturnSUSDatTest is Test {
    address constant VAULT = 0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7;
    address constant QUEUE = 0x4Bc9FEC04F0F95e9b42a3EF18F3C96fB57923D2e;
    address constant USDAT = 0x23238f20b894f29041f48D88eE91131C395Aaa71;
    address constant STRCON = 0xECABE1Ff8a9e1dC55899cf58dac8497ecE5Ae84c;
    address constant STRCMIRROR = 0xa2Cf4B9410cEbcDCeb3cFf772aC0219F6D1105C9;
    address constant STRCMODULE = 0x3C0f0b502aa7C2ed85620f7f52B8eFb8049b1ECf;
    // live role holders (read on-chain; see analysis/)
    address constant OPERATOR_EOA = 0xC35580434261f667d6abBDa9E3dC1DC31e5A1b92;
    address constant PARAM_MGR = 0x6F72de4F529a03Bfa883825152656a8c62CBB626;

    IVault vault = IVault(VAULT);
    IQueue queue = IQueue(QUEUE);
    IERC20 usdat = IERC20(USDAT);
    IERC20 strcon = IERC20(STRCON);

    address attacker = address(0xA11CE);
    address victim = address(0xB0B);

    uint256 forkBlock;

    function setUp() public {
        // pin to the block used in the report for reproducibility; fall back to latest
        try vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))), 26_253_655) {
        } catch {
            vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
        }
        forkBlock = block.number;
    }

    function _giveUsdat(address to, uint256 amt) internal {
        deal(USDAT, to, amt);
    }

    // -----------------------------------------------------------------------------------
    // T1: the entire privileged value-moving surface reverts for a fresh unprivileged EOA
    // -----------------------------------------------------------------------------------
    function test_T1_privileged_surface_reverts_for_fresh_eoa() public {
        vm.startPrank(attacker);

        // vault
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.transferInSurplus.selector, 1e6));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.migrate.selector, 1e18, block.timestamp + 1));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.buy.selector, 1e6, 1e18, address(0xdead), block.timestamp + 1));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.sell.selector, 1e18, 1e6, address(0xdead), block.timestamp + 1));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.beginRedemptionBatch.selector));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.redeemQueuedShares.selector, 1e18, 0));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.endRedemptionBatch.selector));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.seize.selector, victim));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.rescueTokens.selector, USDAT, 1e6));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setMarketMode.selector, uint8(0)));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setRedemptionFees.selector, uint16(1), uint16(2)));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setElevatedDepositFee.selector, uint256(1)));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setMigrationTolerance.selector, uint16(1)));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setSurplusSource.selector, attacker));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setRecoveryAddress.selector, attacker));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.setSurplusVestingPeriod.selector, uint256(1)));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.pause.selector));
        _expectAnyRevert(VAULT, abi.encodeWithSelector(IVault.unpause.selector));
        // queue
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        _expectAnyRevert(QUEUE, abi.encodeWithSelector(IQueue.processRequests.selector, ids));
        _expectAnyRevert(QUEUE, abi.encodeWithSelector(IQueue.addRequest.selector, attacker, 1e18, 0));
        _expectAnyRevert(QUEUE, abi.encodeWithSelector(IQueue.seize.selector, 0));
        _expectAnyRevert(QUEUE, abi.encodeWithSelector(IQueue.resetLegacyInProgressRequest.selector, 0));
        _expectAnyRevert(QUEUE, abi.encodeWithSelector(IQueue.claim.selector, 0));

        vm.stopPrank();
        console.log("T1 PASS: all privileged/value-moving selectors reverted for fresh EOA");
    }

    function _expectAnyRevert(address target, bytes memory data) internal {
        (bool ok,) = target.call(data);
        require(!ok, "T1: call unexpectedly succeeded");
    }

    // -----------------------------------------------------------------------------------
    // T2: deposit mints exactly previewDeposit shares; exchange rate is not mispriced
    // -----------------------------------------------------------------------------------
    function test_T2_deposit_rate_is_fair_and_unmanipulated() public {
        _giveUsdat(attacker, 1_000_000e6);
        uint256 rateBefore = vault.convertToAssets(1e18);
        uint256 expectedShares = vault.previewDeposit(1_000_000e6);

        vm.startPrank(attacker);
        usdat.approve(VAULT, type(uint256).max);
        uint256 shares = vault.deposit(1_000_000e6, attacker);
        vm.stopPrank();

        assertEq(shares, expectedShares, "shares != previewDeposit");
        uint256 rateAfter = vault.convertToAssets(1e18);
        // the depositor must not gain value: their shares are worth at most what they paid
        uint256 valueOut = vault.convertToAssets(shares);
        assertLe(valueOut, 1_000_000e6, "depositor gained value");
        // rate may rise only by the fee that accrues to existing holders (<= feeBps of NAV)
        assertLe(rateAfter, rateBefore * 10_001 / 10_000 + 2, "rate rose beyond the deposit fee");
        console.log("T2 rateBefore", rateBefore);
        console.log("T2 rateAfter", rateAfter);
        console.log("T2 shares", shares);
        console.log("T2 valueOut(USDat6)", valueOut);
        console.log("T2 PASS: deposit priced at live NAV; no mispricing");
    }

    // -----------------------------------------------------------------------------------
    // T3: direct USDat donation does NOT inflate totalAssets (tracked usdatBalance)
    // -----------------------------------------------------------------------------------
    function test_T3_usdat_donation_does_not_inflate_totalAssets() public {
        _giveUsdat(attacker, 5_000_000e6);
        uint256 taBefore = vault.totalAssets();
        uint256 rateBefore = vault.convertToAssets(1e18);
        uint256 vaultBalBefore = usdat.balanceOf(VAULT);

        vm.prank(attacker);
        usdat.transfer(VAULT, 5_000_000e6); // direct donation, no deposit

        uint256 taAfter = vault.totalAssets();
        uint256 rateAfter = vault.convertToAssets(1e18);
        assertEq(usdat.balanceOf(VAULT), vaultBalBefore + 5_000_000e6, "donation not received");
        assertEq(taAfter, taBefore, "totalAssets changed on donation");
        assertEq(rateAfter, rateBefore, "exchange rate changed on donation");
        console.log("T3 PASS: USDat donation is neutral (tracked usdatBalance)");
    }

    // -----------------------------------------------------------------------------------
    // T4: direct STRCon donation does NOT inflate recognizedValue / totalAssets
    // -----------------------------------------------------------------------------------
    function test_T4_strcon_donation_does_not_inflate_totalAssets() public {
        deal(STRCON, attacker, 10_000e18);
        IModule sm = IModule(STRCMODULE);
        uint256 rvBefore = sm.recognizedValue();
        uint256 taBefore = vault.totalAssets();

        vm.prank(attacker);
        strcon.transfer(VAULT, 10_000e18);

        assertEq(sm.recognizedValue(), rvBefore, "recognizedValue changed on STRCon donation");
        assertEq(vault.totalAssets(), taBefore, "totalAssets changed on STRCon donation");
        console.log("T4 PASS: STRCon donation is neutral (module tracked balance)");
    }

    // -----------------------------------------------------------------------------------
    // T5: requestRedeem -> cancel returns at most the deposited shares (no free value)
    // -----------------------------------------------------------------------------------
    function test_T5_request_and_cancel_no_profit() public {
        _giveUsdat(attacker, 1_000_000e6);
        vm.startPrank(attacker);
        usdat.approve(VAULT, type(uint256).max);
        vault.deposit(1_000_000e6, attacker);
        uint256 shares = vault.balanceOf(attacker);
        uint256 usdatBefore = usdat.balanceOf(attacker);
        uint256 id = vault.requestRedeem(shares, 0);
        assertEq(queue.ownerOf(id), attacker, "request owner mismatch");
        queue.cancelRequest(id);
        uint256 usdatAfter = usdat.balanceOf(attacker);
        assertEq(vault.balanceOf(attacker), shares, "shares not returned");
        assertLe(usdatAfter, usdatBefore, "attacker gained USDat from cancel");
        vm.stopPrank();
        console.log("T5 PASS: requestRedeem/cancel round-trips with no gain");
    }

    // -----------------------------------------------------------------------------------
    // T6: JIT deposit immediately before a settlement batch is NOT profitable
    //     (Certora L-08 "just-in-time deposits capture redemption fees" — acknowledged)
    // -----------------------------------------------------------------------------------
    function test_T6_jit_deposit_before_batch_is_unprofitable() public {
        // victim creates a queued redemption
        _giveUsdat(victim, 600_000e6);
        vm.startPrank(victim);
        usdat.approve(VAULT, type(uint256).max);
        vault.deposit(600_000e6, victim);
        uint256 vShares = vault.balanceOf(victim);
        uint256 vId = vault.requestRedeem(vShares, 0);
        vm.stopPrank();

        // attacker front-runs the operator batch with a large deposit
        uint256 attackDeposit = 48_000_000e6;
        _giveUsdat(attacker, attackDeposit);
        vm.startPrank(attacker);
        usdat.approve(VAULT, type(uint256).max);
        vault.deposit(attackDeposit, attacker);
        uint256 aShares = vault.balanceOf(attacker);
        vm.stopPrank();

        // operator settles the queued request
        uint256[] memory ids = new uint256[](1);
        ids[0] = vId;
        vm.prank(OPERATOR_EOA);
        queue.processRequests(ids);

        // attacker's resulting claimable value
        uint256 aValue = vault.convertToAssets(aShares);
        console.log("T6 attackDeposit", attackDeposit);
        console.log("T6 attackerShares", aShares);
        console.log("T6 attackerValueAfter", aValue);
        if (aValue >= attackDeposit) {
            console.log("T6 !! attacker PROFITED", aValue - attackDeposit);
        } else {
            console.log("T6 attacker LOSS", attackDeposit - aValue);
        }
        assertLt(aValue, attackDeposit, "JIT deposit was profitable");
        console.log("T6 PASS: JIT fee-capture is unprofitable at live scale");
    }

    // -----------------------------------------------------------------------------------
    // T7: totalAssets invariant = usdatBalance + mirrorValue + strconValue
    // -----------------------------------------------------------------------------------
    function test_T7_totalAssets_decomposition() public {
        uint256 expected = vault.usdatBalance() + IModule(STRCMIRROR).recognizedValue()
            + IModule(STRCMODULE).recognizedValue();
        assertEq(vault.totalAssets(), expected, "totalAssets != decomposition");
        console.log("T7 totalAssets", vault.totalAssets());
        console.log("T7 usdatBalance", vault.usdatBalance());
        console.log("T7 strconValue", IModule(STRCMODULE).recognizedValue());
        console.log("T7 PASS: totalAssets = tracked legs only (no donation leg)");
    }

    // -----------------------------------------------------------------------------------
    // T8: live state snapshot (for the report)
    // -----------------------------------------------------------------------------------
    function test_T8_snapshot() public {
        console.log("block", forkBlock);
        console.log("totalAssets", vault.totalAssets());
        console.log("totalSupply", vault.totalSupply());
        console.log("usdatBalance", vault.usdatBalance());
        console.log("marketMode", vault.marketMode());
        console.log("depositFeeBps", vault.depositFeeBps());
        console.log("redemptionFeeBps", vault.redemptionFeeBps());
        console.log("convertToAssets(1e18)", vault.convertToAssets(1e18));
        console.log("queue live request NFTs", queue.totalSupply());
        assertTrue(vault.paused() == false, "unexpected pause");
    }
}
