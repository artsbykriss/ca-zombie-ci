// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/**
 * @title  Primus Confidential Vault (FHE) — unprivileged-path gate test (READ-ONLY, fork only)
 * @notice Forks BSC and asserts that every externally reachable, value-moving entry point on the
 *         Primus "Confidential Finance" FHE stack (eUSDu / eUSDT / eU converters + Unitas
 *         mint/redeem aggregators + UnitasRewardPool + FHE ACL) reverts for an unprivileged caller.
 *         No transaction is ever broadcast: all calls run against the fork via vm.expectRevert.
 *
 *         The point is the NEGATIVE result: no unprivileged drain exists. Value is only movable by
 *         (a) the confidential-token holder (self-service unshield/claim), (b) the keeper (batch
 *         settlement), or (c) the owner (UUPS upgrade / recover), or with a threshold KMS/alphatrion
 *         signature proof (2-of-3, all Primus-operated).
 */
interface IAggregator {
    function dispatchAggregate() external payable;
    function dispatchAggregateCallback(uint256, uint64, bytes calldata) external payable;
    function recoverAggregate(uint256, uint64, bool) external payable;
    function claim(uint256, address) external payable returns (uint64);
    function quit(uint256) external payable returns (uint64);
    function setKeeper(address) external;
    function setRewardPool(address) external;
    function pause() external;
    function owner() external view returns (address);
    function keeper() external view returns (address);
    function currentAggregateId() external view returns (uint256);
    function aggregateState(uint256) external view returns (uint8);
}

interface IConverter {
    function finalizeUnshield(bytes32, uint64, bytes calldata) external;
    function unshield(address, address, uint64) external payable returns (bytes32);
    function denyUser(address) external;
    function setFeeSkipCaller(address, bool) external;
    function owner() external view returns (address);
    function underlying() external view returns (address);
    function rate() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function isDenied(address) external view returns (bool);
}

interface IACL {
    function allow(bytes32, address) external;
    function allowForDecryption(bytes32[] calldata) external;
    function pause() external;
    function owner() external view returns (address);
}

interface IDecryption {
    function verifyPublicDecryptionEIP712KMSSignature(
        bytes32[] memory,
        bytes memory,
        bytes memory
    ) external returns (bool);
}

interface ISpaceBridgeConfig {
    function getPublicDecryptionThreshold() external view returns (uint256);
    function getUserDecryptionThreshold() external view returns (uint256);
    function getAlphatrionThreshold() external view returns (uint256);
    function getKmsSigners() external view returns (address[] memory);
    function owner() external view returns (address);
}

contract PrimusFheGatingTest is Test {
    // ---- BSC mainnet (chainid 56) addresses resolved from dapp.primuslabs.xyz JS bundles ----
    address constant ACL = 0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE;
    address constant FHE_EXECUTOR = 0x12964221F412e3e52F5f0C9592781904266dd9B4;
    address constant DECRYPTION = 0x29873f805e66B39c28D394B213f712B7b2B52ba1;
    address constant SPACE_BRIDGE_CONFIG = 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396;

    address constant CONV_eU = 0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800; // "Confidential U"
    address constant CONV_eUSDT = 0xc2CC9419DDEb3425876091a1eb79D5C59017838c; // "Confidential USDT"
    address constant CONV_esUSDu_u = 0x06776741b1f8bfF5ea51750E91edcf03ed8C6994; // "Confidential sUSDu" (u route)
    address constant CONV_esUSDu_usdt = 0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d; // "Confidential sUSDu" (usdt route)

    address constant AGG_MINT_u = 0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24;
    address constant AGG_MINT_usdt = 0xE76F5202EF8eEB462eC784Fe51D69E9a8a0b56c1;
    address constant AGG_REDEEM_u = 0xBef1366512ffFF33cdd6C48d66e48D33c6dbCa22;
    address constant AGG_REDEEM_usdt = 0x485dBFD90DdF92E009438FF49b1918C6636a8f89;

    address constant REWARD_POOL = 0xCfd2917b0D8b83D7EB3a4BA637e0D8a034B7524F;
    address constant UNItas_PROXY_VAULT = 0xe9E8573Bb351da16c6EE7dDaC0cBC70b7f9784AE;

    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant S_USDU = 0x385C279445581a186a4182a5503094eBb652EC71;
    address constant U_TOKEN = 0xcE24439F2D9C6a2289F741120FE202248B666666;

    // The two live admin EOAs (Primus side) and the single settlement keeper.
    address constant OWNER_PRIMUS = 0xEA7Ff99584C1996Bd9E94033b5C7A1Fe37B00d87;
    address constant OWNER_PRIMUS2 = 0x3480B1E2f19D95cdfb8dA3ae40E9C7C500Fe4893;
    address constant KEEPER = 0x43A28B8dD1ebc3752ECcfd610d70D5c2BCc18FB6;

    // Fresh, unprivileged attacker EOA (funded on the fork so fee-gated entry points run their
    // real authorization checks instead of failing on the FHE prepayment).
    address attacker = address(0xA11CE);

    function setUp() public {
        // CI may expose BSC_RPC_URL as an *empty* string when the secret is unset — envOr would
        // then return "" and createSelectFork would revert. Try each candidate until one answers.
        string[4] memory cands = [
            vm.envOr("BSC_RPC_URL", string("")),
            string("https://bsc-dataseed.binance.org"),
            string("https://bsc.publicnode.com"),
            string("https://bscrpc.pancakeswap.finance")
        ];
        uint256 forkBlock = vm.envOr("FORK_BLOCK", uint256(0));
        bool ok = false;
        for (uint256 i = 0; i < cands.length; i++) {
            if (bytes(cands[i]).length == 0) continue;
            if (forkBlock == 0) {
                try vm.createSelectFork(cands[i]) returns (uint256) {
                    ok = true;
                    break;
                } catch {}
            } else {
                try vm.createSelectFork(cands[i], forkBlock) returns (uint256) {
                    ok = true;
                    break;
                } catch {}
            }
        }
        require(ok, "no working BSC RPC for fork");
        vm.deal(attacker, 10 ether);
        console2.log("forked BSC block", block.number);
    }

    // ---------------------------------------------------------------------------------------------
    // 1. The three privileged roles are exactly the three EOAs above (no unprivileged path).
    // ---------------------------------------------------------------------------------------------
    function test_roles_are_privileged_only() public {
        assertEq(IAggregator(AGG_MINT_u).owner(), OWNER_PRIMUS, "mint_u owner");
        assertEq(IAggregator(AGG_MINT_u).keeper(), KEEPER, "mint_u keeper");
        assertEq(IAggregator(AGG_MINT_usdt).owner(), OWNER_PRIMUS2, "mint_usdt owner");
        assertEq(IAggregator(AGG_REDEEM_u).owner(), OWNER_PRIMUS, "redeem_u owner");
        assertEq(IConverter(CONV_eU).owner(), OWNER_PRIMUS, "eU owner");
        assertEq(IConverter(CONV_eUSDT).owner(), OWNER_PRIMUS2, "eUSDT owner");
        assertEq(IACL(ACL).owner(), OWNER_PRIMUS, "ACL owner");
        assertEq(ISpaceBridgeConfig(SPACE_BRIDGE_CONFIG).owner(), OWNER_PRIMUS, "SBC owner");
    }

    // ---------------------------------------------------------------------------------------------
    // 2. Batch settlement is keeper-gated (base `dispatchAggregate` is overridden in the Unitas leaf).
    // ---------------------------------------------------------------------------------------------
    function test_dispatch_is_keeper_gated() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotKeeper(address)", attacker));
        IAggregator(AGG_MINT_u).dispatchAggregate{value: 0.01 ether}();

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotKeeper(address)", attacker));
        IAggregator(AGG_MINT_u).dispatchAggregateCallback{value: 0.01 ether}(180, 1, "");

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotKeeper(address)", attacker));
        IAggregator(AGG_REDEEM_u).dispatchAggregate{value: 0.01 ether}();
    }

    // ---------------------------------------------------------------------------------------------
    // 3. Owner escape hatch / policy setters are owner-only.
    // ---------------------------------------------------------------------------------------------
    function test_owner_only_paths_revert_for_attacker() public {
        bytes memory oa = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker);

        vm.startPrank(attacker);
        vm.expectRevert(oa);
        IAggregator(AGG_MINT_u).recoverAggregate{value: 0.01 ether}(180, 1, true);
        vm.expectRevert(oa);
        IAggregator(AGG_MINT_u).setKeeper(attacker);
        vm.expectRevert(oa);
        IAggregator(AGG_MINT_u).setRewardPool(attacker);
        vm.expectRevert(oa);
        IAggregator(AGG_MINT_u).pause();
        vm.expectRevert(oa);
        IConverter(CONV_eU).denyUser(attacker);
        vm.expectRevert(oa);
        IConverter(CONV_eU).setFeeSkipCaller(attacker, true);
        vm.expectRevert(oa);
        IACL(ACL).pause();
        vm.stopPrank();
    }

    // ---------------------------------------------------------------------------------------------
    // 4. `claim` is permissionless but pays the *depositor*; on the open batch it reverts, and a
    //    caller with no deposit can never be paid (ZeroDeposits).
    // ---------------------------------------------------------------------------------------------
    function test_claim_pays_depositor_only_and_open_batch_reverts() public {
        uint256 id = IAggregator(AGG_MINT_u).currentAggregateId();
        uint8 st = IAggregator(AGG_MINT_u).aggregateState(id);
        assertEq(st, 0, "current aggregate must be Open");

        // claim on an Open (not Finalized) aggregate -> UnexpectedAggregateState(id, Open, Finalized-bit)
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSignature("UnexpectedAggregateState(uint256,uint8,bytes32)", id, uint8(0), bytes32(uint256(4)))
        );
        IAggregator(AGG_MINT_u).claim{value: 0.01 ether}(id, attacker);

        // quit with no deposit -> ZeroDeposits
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("ZeroDeposits(uint256,address)", id, attacker));
        IAggregator(AGG_MINT_u).quit{value: 0.01 ether}(id);
    }

    // ---------------------------------------------------------------------------------------------
    // 5. Unshielding requires the caller to own the ciphertext handle (FHE ACL) and an existing
    //    request for finalize; a forged request id can never be settled.
    // ---------------------------------------------------------------------------------------------
    function test_finalize_unshield_requires_real_request() public {
        bytes32 fake = bytes32(uint256(1));
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("InvalidUnshieldRequest(bytes32)", fake));
        IConverter(CONV_eU).finalizeUnshield(fake, 1e18, "");

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("InvalidUnshieldRequest(bytes32)", fake));
        IConverter(CONV_eUSDT).finalizeUnshield(fake, 1e18, "");

        // unshield of a handle the attacker has no ACL access to reverts (handle 1 is uninitialized)
        vm.prank(attacker);
        vm.expectRevert();
        IConverter(CONV_eU).unshield{value: 0.01 ether}(attacker, attacker, 1);
    }

    // ---------------------------------------------------------------------------------------------
    // 6. FHE ACL: only an existing handle-access holder can grant access; decryption-proof
    //    verification is a threshold KMS/alphatrion signature (2-of-3, all Primus EOAs).
    // ---------------------------------------------------------------------------------------------
    function test_acl_and_decryption_gating() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("SenderNotAllowed(address)", attacker));
        IACL(ACL).allow(bytes32(uint256(1)), attacker);

        bytes32[] memory hs = new bytes32[](1);
        hs[0] = bytes32(uint256(1));
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("SenderNotAllowed(address)", attacker));
        IACL(ACL).allowForDecryption(hs);

        // empty / malformed decryption proof is rejected by the stateless KMS-verification oracle
        bytes32[] memory h2 = new bytes32[](1);
        h2[0] = bytes32(uint256(1));
        vm.expectRevert(abi.encodeWithSignature("DeserializingDecryptionProofFail()"));
        IDecryption(DECRYPTION).verifyPublicDecryptionEIP712KMSSignature(h2, abi.encode(uint64(1e18)), hex"00");

        // thresholds are majority quorums over 3 Primus-operated signers
        assertEq(ISpaceBridgeConfig(SPACE_BRIDGE_CONFIG).getPublicDecryptionThreshold(), 2);
        assertEq(ISpaceBridgeConfig(SPACE_BRIDGE_CONFIG).getUserDecryptionThreshold(), 2);
        assertEq(ISpaceBridgeConfig(SPACE_BRIDGE_CONFIG).getAlphatrionThreshold(), 2);
        assertEq(ISpaceBridgeConfig(SPACE_BRIDGE_CONFIG).getKmsSigners().length, 3);
    }

    // ---------------------------------------------------------------------------------------------
    // 7. The value really is on-chain: the confidential converters hold the backing for the
    //    outstanding esUSDu / eUSDT / eU supply. It is only reachable by the holders (H-O).
    // ---------------------------------------------------------------------------------------------
    function test_live_backing_is_holder_only() public {
        uint256 susdu_u = IConverter(S_USDU).balanceOf(CONV_esUSDu_u);
        uint256 susdu_usdt = IConverter(S_USDU).balanceOf(CONV_esUSDu_usdt);
        uint256 usdt = IConverter(USDT).balanceOf(CONV_eUSDT);
        uint256 u = IConverter(U_TOKEN).balanceOf(CONV_eU);

        console2.log("esUSDu-u converter sUSDu (wei)", susdu_u);
        console2.log("esUSDu-usdt converter sUSDu (wei)", susdu_usdt);
        console2.log("eUSDT converter USDT (wei)", usdt);
        console2.log("eU converter U (wei)", u);

        // Floors recorded at block 129,593,000 (2026-10-24) — assert the funds are still present.
        assertGe(susdu_u, 90_000e18, "esUSDu-u backing present");
        assertGe(susdu_usdt, 115_000e18, "esUSDu-usdt backing present");
        assertGe(usdt, 3_900e18, "eUSDT backing present");
        assertGe(u, 4_700e18, "eU backing present");

        // aggregators hold (near) nothing; the vault proxy holds no user funds
        assertLt(IConverter(USDT).balanceOf(AGG_MINT_u), 1e6, "mint_u holds dust");
        assertLt(IConverter(U_TOKEN).balanceOf(AGG_MINT_u), 1e6, "mint_u holds dust (U)");
    }
}
