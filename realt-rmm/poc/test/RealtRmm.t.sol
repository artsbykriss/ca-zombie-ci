// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IWrapper {
    function liquidationCall(
        address[] calldata collateralAssets,
        uint256[] calldata collateralAmounts,
        address debtAsset,
        address user,
        uint256 debtToCover,
        uint8 receiveMethod
    ) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getAllTokenBalancesOfUser(address user)
        external view returns (address[] memory, uint256[] memory);
    function getRealTokenPrice(address token) external view returns (uint256);
    function getUserIndex(address user) external view returns (uint256);
}

interface IATokenRTW {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface IPool {
    function getUserAccountData(address user)
        external view
        returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase,
                 uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
}

/// @title RealT RMM v3 + RealTokenWrapper — ZH4-07 fork re-checks (Gnosis, chain 100)
/// @notice Read-only reproduction on a local fork. No mainnet transactions.
///         Pinned at block 48,811,720 (2026-10-18) where:
///           - 204 borrowers have HF < 1; one-shot liquidation bonus pool = $418,691 at marks
///           - every RealToken recipient is compliance-gated (Processor rule engine, revert RU03)
contract RealtRmmTest is Test {
    address constant WRAPPER = 0x10497611Ee6524D75FC45E3739F472F83e282AD5;
    address constant POOL    = 0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3;
    address constant ARTW    = 0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647;
    address constant WXDAI   = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address constant USER    = 0xcD2A0feC532FC05851FBD4fD39c1D8Eb3d9D64C3; // HF 0.9204, 580.88 WXDAI debt
    address constant TOKEN   = 0x4637aa1A13Aa4050C6E4bCd6ddE9c39E80E9dD54; // ledger 4.0627, mark $50.91
    address constant SAFE    = 0x4F7765c9feBc51cD63F68f573920c0B7bF803151; // incumbent (whitelisted)
    address constant ATTACKER  = 0x1111111111111111111111111111111111111111; // not whitelisted
    address constant ATTACKER2 = 0x000000000000000000000000000000000000bEEF; // not whitelisted
    address constant DEBT_WXDAI = 0x9908801dF7902675C3FEDD6Fea0294D18D5d5d34;

    uint256 constant FORK_BLOCK = 48_811_720;
    uint256 constant USER_TOKEN_LEDGER = 4_062_754_487_838_022_371; // full ledger at fork block
    uint256 constant REPAY = 50 ether;

    function setUp() public {
        // NB: GNOSIS_RPC_URL (not FORK_RPC_URL -- the CI helper sets that one to an Ethereum RPC).
        // A defined-but-empty env var is returned by envOr as "", so fall back explicitly.
        string memory url = vm.envOr("GNOSIS_RPC_URL", string(""));
        if (bytes(url).length == 0) url = "https://rpc.gnosischain.com";
        vm.createSelectFork(url, FORK_BLOCK);
    }

    function _fundAndApprove(address who, uint256 amount) internal {
        deal(WXDAI, who, amount);
        vm.prank(who);
        IERC20(WXDAI).approve(WRAPPER, amount);
    }

    /// Builds the call; the caller must vm.prank(who) immediately before invoking this.
    function _liq(address who, uint8 method) internal {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = TOKEN;
        amounts[0] = USER_TOKEN_LEDGER;
        IWrapper(WRAPPER).liquidationCall(assets, amounts, WXDAI, USER, REPAY, method);
        // silence unused warning
        who;
    }

    /// 1. Snapshot: the headline state is live at the fork block.
    function test_1_state_snapshot() public view {
        (uint256 coll, uint256 debt,,,, uint256 hf) = IPool(POOL).getUserAccountData(USER);
        assertApproxEqAbs(coll, 763.77753137e8, 0.01e8, "collateral base");
        assertApproxEqAbs(debt, 580.87858869e8, 0.01e8, "debt base");
        assertLt(hf, 1e18, "HF must be < 1");
        assertEq(IWrapper(WRAPPER).getRealTokenPrice(TOKEN), 5091 * 1e6, "mark $50.91");

        (address[] memory ts, uint256[] memory ams) = IWrapper(WRAPPER).getAllTokenBalancesOfUser(USER);
        bool found;
        for (uint256 i = 0; i < ts.length; i++) {
            if (ts[i] == TOKEN) {
                assertEq(ams[i], USER_TOKEN_LEDGER);
                found = true;
            }
        }
        assertTrue(found, "token in ledger");
    }

    /// 2. Anonymous caller, receiveMethod=1 (REALTOKEN): reverts RU03 at the RealToken transfer.
    ///    This is the v4b correction: the gate is on the recipient, not on the caller.
    function test_2_method1_anon_reverts_RU03() public {
        _fundAndApprove(ATTACKER, 100 ether);
        assertEq(IERC20(WXDAI).balanceOf(ATTACKER), 100 ether);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("RU03"));
        _liq(ATTACKER, 1);

        // whole tx reverted: attacker keeps the debt token and receives nothing
        assertEq(IERC20(WXDAI).balanceOf(ATTACKER), 100 ether, "capital untouched");
        assertEq(IERC20(TOKEN).balanceOf(ATTACKER), 0, "no token received");
    }

    /// 3. Same call from the whitelisted incumbent Safe: succeeds with the 10% bonus.
    ///    Identical mechanics, only the recipient whitelist differs => the gate is the
    ///    sole reason an outsider cannot extract.
    function test_3_method1_whitelisted_safe_succeeds() public {
        _fundAndApprove(SAFE, 100 ether);
        uint256 tokBefore = IERC20(TOKEN).balanceOf(SAFE);
        uint256 debtBefore = IERC20(DEBT_WXDAI).balanceOf(USER);

        vm.prank(SAFE);
        _liq(SAFE, 1);

        uint256 seized = IERC20(TOKEN).balanceOf(SAFE) - tokBefore;
        assertGt(seized, 1.07 ether, "seized ~1.08 token");
        assertLt(seized, 1.09 ether, "seized ~1.08 token");
        uint256 seizedUsd = seized * IWrapper(WRAPPER).getRealTokenPrice(TOKEN) / 1e8;
        assertApproxEqAbs(seizedUsd, 55 ether, 0.01 ether, "1.10x at mark");

        uint256 debtAfter = IERC20(DEBT_WXDAI).balanceOf(USER);
        assertApproxEqAbs(debtAfter, debtBefore - REPAY, 0.01 ether, "debt down 50 WXDAI");
    }

    /// 4. Anonymous caller, receiveMethod=0 (ATOKEN): the liquidation executes, but the output
    ///    is a non-transferable aRTW claim. Transfer reverts (0xa3a2cfb6); the only redemption
    ///    path is RU03-gated on the recipient => -100% of deployed capital for the attacker.
    function test_4_method0_anon_claim_is_dead() public {
        _fundAndApprove(ATTACKER, 100 ether);

        vm.prank(ATTACKER);
        _liq(ATTACKER, 0);

        uint256 artwBal = IATokenRTW(ARTW).balanceOf(ATTACKER);
        assertGt(artwBal, 54 ether, "aRTW claim ~55");
        assertEq(IERC20(TOKEN).balanceOf(ATTACKER), 0, "no RealToken received");

        // aRTW is only movable by the pool/wrapper
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSignature("CallerNotPoolOrWrapper(address)", ATTACKER));
        IATokenRTW(ARTW).transfer(ATTACKER2, 1);

        // redemption to a non-whitelisted address hits RU03 at the final transfer
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("RU03"));
        IWrapper(WRAPPER).withdraw(TOKEN, 0.5 ether, ATTACKER2);

        // ... while the exact same redemption to a whitelisted address succeeds: the attacker
        // can only donate the asset to a KYC'd counterparty, never receive it.
        uint256 safeBefore = IERC20(TOKEN).balanceOf(SAFE);
        vm.prank(ATTACKER);
        IWrapper(WRAPPER).withdraw(TOKEN, 0.5 ether, SAFE);
        assertGt(IERC20(TOKEN).balanceOf(SAFE), safeBefore, "token delivered to whitelisted only");
    }
}
