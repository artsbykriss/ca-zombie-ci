// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

/// @title HashMix FIL (FEVM) — fresh-attacker extraction PoC (read-only fork test)
/// @notice Runs against a live fork of Filecoin FEVM. Every "attacker" call must
///         revert; positive controls prove the fork state is faithful and that the
///         only value-moving paths are holder self-service (H-O) or privileged (P).
contract HashMixFILTest is Test {
    // --- live targets (Filecoin FEVM, chain id 314) ---
    address constant POOL      = 0x587A7eaE9b461ad724391Aa7195210e0547eD11d; // V1 pool + cWFIL
    address constant CTRL      = 0xFA33F3866e7eF32F79734BCC5e011d767F8E574b; // V1 controller (proxy)
    address constant FEE       = 0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd; // pool feeCollector (EOA)
    address constant MSIG      = 0x358Cc936fc3035A49E02d670Ec9b8E0061E97979; // timelock/multisig (controller admin)
    address constant V2POOL    = 0x85e77391C3dDe4fee572A79CFef7f710c7476f82; // V2 pool + cWFIL
    address constant V2CTRL    = 0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5; // V2 controller (proxy)
    address constant WFIL      = 0x60E1773636cF5E4A227D9Ac24f20fEA0D0344a49; // canonical WFIL (not underlying)
    address constant HOLDER    = 0x256fA19F49661d166D58d9CF8D23c60711535413; // largest cWFIL holder (94.8%)
    // fresh unprivileged attacker (no positions, no roles)
    address constant ATT       = address(0xA77ACc0); // 0x0000000000000000000000000000000000A77ACc0

    uint256 forkBlock;

    function setUp() public {
        // try several keyless public Filecoin RPCs (CI has no Filecoin RPC env)
        string[4] memory urls;
        urls[0] = vm.envOr("FIL_RPC_URL", string("https://rpc.ankr.com/filecoin"));
        urls[1] = "https://api.node.glif.io/rpc/v1";
        urls[2] = "https://api.chain.love/rpc/v1";
        urls[3] = "https://filecoin.blockscout.com/api/eth-rpc";
        bool ok;
        for (uint256 i = 0; i < urls.length; i++) {
            try vm.createSelectFork(urls[i]) {
                try IERC20Like(POOL).totalSupply() returns (uint256) {
                    ok = true;
                    emit log_named_string("fork_rpc", urls[i]);
                    break;
                } catch {}
            } catch {}
        }
        require(ok, "no reachable Filecoin RPC");
        forkBlock = block.number;
        vm.deal(ATT, 100 ether);
        emit log_named_uint("fork_block", forkBlock);
    }

    // ---------------------------------------------------------------- helpers
    function _expectRevert(address who, address to, bytes memory data, uint256 value)
        internal
    {
        vm.prank(who);
        (bool ok,) = to.call{value: value}(data);
        require(!ok, "EXPECTED REVERT but call succeeded");
    }

    // ------------------------------------------------ pool: gated functions
    function test_attacker_reduceReserves_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("_reduceReserves(uint256)", uint256(1)), 0);
    }

    function test_attacker_reduceReserves_full_reverts() public {
        // try to drain the entire reserve balance (482.678 FIL)
        _expectRevert(ATT, POOL, abi.encodeWithSignature("_reduceReserves(uint256)", uint256(482678236460184996056)), 0);
    }

    function test_attacker_sweepToken_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("sweepToken(address,address)", ATT, WFIL), 0);
        _expectRevert(ATT, POOL, abi.encodeWithSignature("sweepToken(address,address)", ATT, POOL), 0);
    }

    function test_attacker_addReserves_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("_addReserves(uint256)", uint256(1)), 1);
    }

    function test_attacker_setReserveFactor_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("_setReserveFactor(uint256)", uint256(0)), 0);
    }

    function test_attacker_updateFeeCollector_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("updateFeeCollector(address)", ATT), 0);
    }

    function test_attacker_borrowBehalf_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("borrowBehalf(address,uint256)", ATT, uint256(1)), 0);
    }

    function test_attacker_repayBorrowBehalf_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", ATT, uint256(1)), 0);
    }

    function test_attacker_redeem_without_shares_reverts() public {
        _expectRevert(ATT, POOL, abi.encodeWithSignature("redeem(uint256)", uint256(1)), 0);
    }

    function test_attacker_permit_forgery_reverts() public {
        // forged EIP-2612 permit (r=s=v=0) must not grant allowance
        _expectRevert(
            ATT,
            POOL,
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                HOLDER, ATT, type(uint256).max, block.timestamp + 1 days, uint8(0), bytes32(0), bytes32(0)
            ),
            0
        );
        // and with v=27
        _expectRevert(
            ATT,
            POOL,
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                HOLDER, ATT, type(uint256).max, block.timestamp + 1 days, uint8(27), bytes32(0), bytes32(0)
            ),
            0
        );
    }

    // ------------------------------------------- controller: gated functions
    function test_attacker_controller_setAdmin_reverts() public {
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("setAdmin(address)", ATT), 0);
    }

    function test_attacker_controller_setFeeCollector_reverts() public {
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("setFeeCollector(address)", ATT), 0);
    }

    function test_attacker_controller_extract_reverts() public {
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("extract(address,address)", ATT, WFIL), 0);
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("extract(address,address)", ATT, POOL), 0);
    }

    function test_attacker_controller_borrow_reverts() public {
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("borrow(uint256,uint256)", uint256(1), uint256(0)), 0);
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("borrow(uint256,uint256)", uint256(1 ether), uint256(0)), 0);
    }

    function test_attacker_controller_initialize_reverts() public {
        _expectRevert(ATT, CTRL, abi.encodeWithSignature("initialize(address,address,address)", ATT, ATT, ATT), 0);
    }

    function test_attacker_controller_config_reverts() public {
        _expectRevert(
            ATT,
            CTRL,
            abi.encodeWithSignature("config(address,address,address,address,address)", ATT, ATT, ATT, ATT, ATT),
            0
        );
    }

    // ------------------------------------------------------ V2 pool parity
    function test_attacker_v2pool_reduceReserves_reverts() public {
        _expectRevert(ATT, V2POOL, abi.encodeWithSignature("_reduceReserves(uint256)", uint256(1)), 0);
    }

    function test_attacker_v2pool_sweepToken_reverts() public {
        _expectRevert(ATT, V2POOL, abi.encodeWithSignature("sweepToken(address,address)", ATT, WFIL), 0);
    }

    function test_attacker_v2pool_updateFeeCollector_reverts() public {
        _expectRevert(ATT, V2POOL, abi.encodeWithSignature("updateFeeCollector(address)", ATT), 0);
    }

    // ------------------------------------------------------- positive controls
    /// fork faithfulness + deposit path: attacker CAN deposit (no profit)
    function test_attacker_mint_is_deposit_only() public {
        uint256 balBefore = ATT.balance;
        uint256 supplyBefore = IERC20Like(POOL).totalSupply();
        // native-FIL convention: mint(0) with FIL in msg.value (verified against
        // historical pool txs, e.g. block 3,545,901 mintAmount=0 value=50 FIL)
        vm.prank(ATT);
        (bool ok,) = POOL.call{value: 1 ether}(abi.encodeWithSignature("mint(uint256)", uint256(0)));
        require(ok, "mint failed");
        uint256 shares = IERC20Like(POOL).balanceOf(ATT);
        require(shares > 0, "no shares minted");
        require(ATT.balance == balBefore - 1 ether, "attacker paid in");
        require(IERC20Like(POOL).totalSupply() > supplyBefore, "supply should grow");
        emit log_named_uint("attacker_shares_minted", shares);
    }

    /// permissionless state poke (harmless)
    function test_attacker_accrueInterest_works() public {
        vm.prank(ATT);
        (bool ok,) = POOL.call(abi.encodeWithSignature("accrueInterest()"));
        require(ok, "accrueInterest should be permissionless");
    }

    /// H-O: the largest holder can self-redeem their cWFIL for FIL
    function test_holder_can_redeem_self_service() public {
        uint256 shares = IERC20Like(POOL).balanceOf(HOLDER);
        require(shares > 0, "holder has shares");
        uint256 filBefore = HOLDER.balance;
        vm.prank(HOLDER);
        (bool ok,) = POOL.call(abi.encodeWithSignature("redeem(uint256)", shares / 100)); // redeem 1%
        require(ok, "holder redeem failed");
        require(HOLDER.balance > filBefore, "holder received FIL");
        emit log_named_uint("holder_fil_received", HOLDER.balance - filBefore);
    }

    // ---------------------------------------------- exhaustive selector sweep
    /// Call EVERY pool selector from the fresh attacker (zero args). Record which
    /// succeed and assert the attacker's FIL balance does not increase.
    function test_sweep_all_pool_selectors_no_gain() public {
        bytes4[46] memory sels = [
            bytes4(0x06fdde03), bytes4(0x095ea7b3), bytes4(0x173b9904), bytes4(0x17bfdfbc), bytes4(0x18160ddd), bytes4(0x182df0f5),
            bytes4(0x23b872dd), bytes4(0x258836fe), bytes4(0x2608f818), bytes4(0x313ce567), bytes4(0x3644e515), bytes4(0x39509351),
            bytes4(0x3af9e669), bytes4(0x3b1d21a2), bytes4(0x3e941010), bytes4(0x43600c54), bytes4(0x47bd3718), bytes4(0x601a0bf1),
            bytes4(0x6752e702), bytes4(0x675d972c), bytes4(0x69ab3250), bytes4(0x6c540baf), bytes4(0x6f307dc3), bytes4(0x70a08231),
            bytes4(0x7ecebe00), bytes4(0x852a12e3), bytes4(0x856e5bb3), bytes4(0x8f840ddd), bytes4(0x95d89b41), bytes4(0x95dd9193),
            bytes4(0xa0712d68), bytes4(0xa457c2d7), bytes4(0xa6afed95), bytes4(0xa9059cbb), bytes4(0xaa5af0fd), bytes4(0xbd6d894d),
            bytes4(0xc415b95c), bytes4(0xd0248fb4), bytes4(0xd2c35ce8), bytes4(0xd505accf), bytes4(0xdb006a75), bytes4(0xdd62ed3e),
            bytes4(0xf3fdb15a), bytes4(0xf77c4791), bytes4(0xfca7820b), bytes4(0xff5a20bf)
        ];
        uint256 balBefore = ATT.balance;
        for (uint256 i = 0; i < sels.length; i++) {
            bytes memory data = abi.encodePacked(sels[i], uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0));
            vm.recordLogs();
            vm.prank(ATT);
            (bool ok, bytes memory ret) = POOL.call(data);
            Vm.Log[] memory logs = vm.getRecordedLogs();
            emit log_named_string(
                ok ? "pool_ok" : "pool_revert",
                string.concat(vm.toString(sels[i]), " retlen=", vm.toString(ret.length), " logs=", vm.toString(logs.length))
            );
        }
        require(ATT.balance <= balBefore, "ATTACKER GAINED FIL");
    }

    /// Call EVERY controller selector from the fresh attacker (zero args).
    function test_sweep_all_controller_selectors_no_gain() public {
        bytes4[33] memory sels = [
            bytes4(0x09448a86), bytes4(0x0975e5c1), bytes4(0x0ec4d916), bytes4(0x0ecbcdab), bytes4(0x16f0115b), bytes4(0x1e65e713),
            bytes4(0x2002b30f), bytes4(0x313dd8bb), bytes4(0x36e26988), bytes4(0x54fd4d50), bytes4(0x5a446a28), bytes4(0x61bbf939),
            bytes4(0x6af9acb3), bytes4(0x6f5dee99), bytes4(0x704b6c02), bytes4(0x7e5bbb1e), bytes4(0x805a8c02), bytes4(0x818e2645),
            bytes4(0x8e02a8b5), bytes4(0x98471f1c), bytes4(0xa3c4bb2a), bytes4(0xa42dce80), bytes4(0xaf455978), bytes4(0xb65fb24c),
            bytes4(0xbb2940e3), bytes4(0xc0c53b8b), bytes4(0xc415b95c), bytes4(0xe5ffaab8), bytes4(0xf655b8e0), bytes4(0xf851a440),
            bytes4(0xf9291906), bytes4(0xfd40449d), bytes4(0xfd5b6141)
        ];
        uint256 balBefore = ATT.balance;
        for (uint256 i = 0; i < sels.length; i++) {
            bytes memory data = abi.encodePacked(sels[i], uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0));
            vm.recordLogs();
            vm.prank(ATT);
            (bool ok, bytes memory ret) = CTRL.call(data);
            Vm.Log[] memory logs = vm.getRecordedLogs();
            emit log_named_string(
                ok ? "ctrl_ok" : "ctrl_revert",
                string.concat(vm.toString(sels[i]), " retlen=", vm.toString(ret.length), " logs=", vm.toString(logs.length))
            );
        }
        require(ATT.balance <= balBefore, "ATTACKER GAINED FIL");
    }

    /// The two controller selectors that succeed for the attacker with no return
    /// data and no events must be no-op fallback calls — compare with a
    /// definitely-unknown selector (0xdeadbeef) and verify no state changes.
    function test_controller_silent_selectors_are_noops() public {
        uint256 balBefore = ATT.balance;
        // definitely-unknown selector — establishes the fallback behavior
        vm.prank(ATT);
        (bool okUnknown,) = CTRL.call(abi.encodePacked(bytes4(0xdeadbeef), uint256(0)));
        (bool okA, bytes memory adminA) = CTRL.staticcall(abi.encodeWithSignature("admin()"));
        (bool okB, bytes memory feeB) = CTRL.staticcall(abi.encodeWithSignature("feeCollector()"));
        (bool okC, bytes memory poolC) = CTRL.staticcall(abi.encodeWithSignature("pool()"));
        uint256 supplyBefore = IERC20Like(POOL).totalSupply();
        vm.prank(ATT);
        (bool ok1,) = CTRL.call(abi.encodePacked(bytes4(0xf9291906), uint256(0), uint256(0), uint256(0)));
        vm.prank(ATT);
        (bool ok2,) = CTRL.call(abi.encodePacked(bytes4(0xfd5b6141), uint256(0), uint256(0), uint256(0)));
        emit log_named_string("unknown_selector_succeeds", okUnknown ? "yes" : "no");
        emit log_named_string("f9291906_succeeds", ok1 ? "yes" : "no");
        emit log_named_string("fd5b6141_succeeds", ok2 ? "yes" : "no");
        require(ok1 == okUnknown && ok2 == okUnknown, "silent selectors differ from fallback");
        (, bytes memory adminA2) = CTRL.staticcall(abi.encodeWithSignature("admin()"));
        (, bytes memory feeB2) = CTRL.staticcall(abi.encodeWithSignature("feeCollector()"));
        (, bytes memory poolC2) = CTRL.staticcall(abi.encodeWithSignature("pool()"));
        require(keccak256(adminA) == keccak256(adminA2), "admin changed");
        require(keccak256(feeB) == keccak256(feeB2), "feeCollector changed");
        require(keccak256(poolC) == keccak256(poolC2), "pool changed");
        require(IERC20Like(POOL).totalSupply() == supplyBefore, "pool supply changed");
        require(ATT.balance == balBefore, "attacker balance changed");
        require(okA && okB && okC, "views broken");
    }

    /// P: the feeCollector (privileged EOA) CAN drain reserves
    function test_feeCollector_can_reduceReserves() public {
        uint256 balBefore = FEE.balance;
        vm.prank(FEE);
        (bool ok,) = POOL.call(abi.encodeWithSignature("_reduceReserves(uint256)", uint256(1)));
        require(ok, "feeCollector reduceReserves failed");
        require(FEE.balance == balBefore + 1, "feeCollector received 1 wei");
    }

    /// P: controller admin (timelock/multisig) can redirect feeCollector
    function test_msig_can_setFeeCollector() public {
        vm.prank(MSIG);
        (bool ok,) = CTRL.call(abi.encodeWithSignature("setFeeCollector(address)", FEE));
        require(ok, "msig setFeeCollector failed");
    }
}

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}
