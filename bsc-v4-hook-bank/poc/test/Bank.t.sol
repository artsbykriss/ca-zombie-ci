// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

/// @title BSC "V4-hook bank" 0x16cEff8D5a4C8648FCc7293f8BD3aC9ADA454219 — read-only fork PoC
/// @notice No mainnet tx is signed/sent. All checks are fork-only. Keys are read from env at
///         runtime and never written to the repo.
contract BankTest is Test {
    address constant BANK        = 0x16cEff8D5a4C8648FCc7293f8BD3aC9ADA454219;
    address constant BANK_ADDR   = 0x7817DBF38E9d1c95671625F0052c147864692fe0;
    address constant PCS_VAULT   = 0x238a358808379702088667322f80aC48bAd5e6c4; // Pancake Infinity Vault
    address constant PCS_MANAGER = 0xa0FfB9c1CE1Fe56963B0321B32E7A0302114058b; // Pancake Infinity CLPoolManager
    address constant UNI_MANAGER = 0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF; // Uniswap V4 PoolManager
    address constant OWNER       = 0xf050633406eE54AbD99b9D834c1b622FB8d35D0b; // slot0 / deployer
    address constant STRANGER    = 0x000000000000000000000000000000000000dEaD;
    address constant BOT_F35     = 0x3A3BE115D066Ca15ac6F664c2D966bAdb703326B; // hardcoded allowlist
    address constant BOT_D1E     = 0x6d81877FE2D78b964572d1205FAC1CfbDA080Cc3;
    address constant BOT_9E1     = 0x94564AA89FFEFC6b4b95457db8A43a888beBcB4d;
    address constant BOT_A3F     = 0x09b05936D1FB2C0bcFd0826fCC786845d65F0d32;

    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    bytes constant F35 = hex"f35ca7280000000000000000000000004d3bf29ba30f8bfe4624e7678709afa195689c5d000000000000000000000000000000000000000000000046bb5a6e80b7527580000000000000000000000000000000000000000001d9e00e43c18be09ef918000000000000000000000000002c3a8ee94ddd97244a93bc48298f97d2c412f7db";
    bytes constant D1E = hex"d1e57635000000000000000000000000d3cffc6b02a34dfc72f1350339031043a854599f0000000000000000000000000000000000000000000000000730307b5b6f7ec4000000000000000000000000000000000000000002c700a662d708fd991dc000000000000000000000000000bb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c";
    bytes constant N9E = hex"9e1941ca00000000000000000000000055d398326f99059ff775485246999027b3197955000000000000000000000000ea37a8de1de2d9d10772eeb569e28bfa5cb177070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0ffb9c1ce1fe56963b0321b32e7a0302114058b000000000000000000000000000000000000000000000000000000000000004300000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000464c9031050e024ce0000000000000000000000000000000000000001381ed5c11628256dfe6e50000";
    bytes constant A3F = hex"a3f8ea7c000000000000000000000000086f405146ce90135750bbec9a063a8b20a8bffb0000000000000000000000008ac76a51cc950d9822d68b83fe1ad97b32cd580d00000000000000000000000072e09ebd9b24f47730b651889a4ed984cba53d90000000000000000000000000a0ffb9c1ce1fe56963b0321b32e7a0302114058b000000000000000000000000000000000000000000000000000000000000004300000000000000000000000000000000000000000000000000000000000a00550000000000000000000000000000000000000000000000041c3be9e3cb6aa7d0000000000000000000000000000000000000000047a20e4111297b60bb982000";

    bytes4 constant UNAUTH = 0x82b42900; // Unauthorized()

    string rpc;

    function _pickRpc() internal view returns (string memory) {
        string memory b = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(b).length > 0) return b;
        string memory dk = vm.envOr("DRPC_API_KEY", string(""));
        if (bytes(dk).length > 0) return string.concat("https://lb.drpc.org/ogrpc?network=bsc&dkey=", dk);
        string memory ank = vm.envOr("ANKR_API_KEY", string(""));
        if (bytes(ank).length > 0) return string.concat("https://rpc.ankr.com/bsc/", ank);
        return "https://bsc-rpc.publicnode.com";
    }

    function setUp() public {
        rpc = _pickRpc();
        emit log_string("fork rpc: set (redacted)");
    }

    function _selectors() internal pure returns (bytes4[39] memory s) {
        s[0]=hex"05e85860"; s[1]=hex"0a5f7886"; s[2]=hex"0ed2006f"; s[3]=hex"23a69e75";
        s[4]=hex"29645a14"; s[5]=hex"2ad802d2"; s[6]=hex"35230cd8"; s[7]=hex"43308267";
        s[8]=hex"444fe41b"; s[9]=hex"45353264"; s[10]=hex"47b148ef"; s[11]=hex"483bd75e";
        s[12]=hex"58dfff0f"; s[13]=hex"67f7a98a"; s[14]=hex"6cfee777"; s[15]=hex"716629d5";
        s[16]=hex"81e90bf2"; s[17]=hex"8eb1172f"; s[18]=hex"91dd7346"; s[19]=hex"95a8fcfb";
        s[20]=hex"9a462d4a"; s[21]=hex"9e1941ca"; s[22]=hex"a0965c16"; s[23]=hex"a3f8ea7c";
        s[24]=hex"ab6291fe"; s[25]=hex"b6a5d7de"; s[26]=hex"d1e57635"; s[27]=hex"d330ca5e";
        s[28]=hex"d3a57c62"; s[29]=hex"e336c026"; s[30]=hex"e7dd6c65"; s[31]=hex"ee4b1585";
        s[32]=hex"f35ca728"; s[33]=hex"f7a9bf57"; s[34]=hex"f9125e2c"; s[35]=hex"f98ef606";
        s[36]=hex"fa461e33"; s[37]=hex"fad7c5c6"; s[38]=hex"fc102e12";
    }

    function _callAs(address caller, bytes memory data) internal returns (bool ok, bytes memory ret) {
        vm.prank(caller);
        (ok, ret) = BANK.call(data);
    }

    function test_A_selectorProbe() public {
        vm.createSelectFork(rpc);
        bytes4[39] memory sels = _selectors();
        uint256 nonRevertEmptyStranger;
        uint256 guardedCount;
        for (uint256 i = 0; i < 39; i++) {
            bytes memory sel = abi.encodePacked(sels[i]);
            (bool okE, ) = _callAs(STRANGER, sel);
            if (okE) { nonRevertEmptyStranger++; emit log_named_bytes("EMPTY_NONREVERT", sel); }

            bytes memory padded = abi.encodePacked(sels[i], new bytes(512));
            (bool okS, bytes memory rS) = _callAs(STRANGER, padded);
            bool isGuard = (rS.length >= 4 && bytes4(rS) == UNAUTH);
            if (isGuard) guardedCount++;
            emit log_named_bytes("SEL", sel);
            emit log_named_uint("  stranger_padded_ok", okS ? 1 : 0);
            emit log_named_bytes("  stranger_padded_ret", rS);
        }
        emit log_named_uint("nonRevert empty stranger", nonRevertEmptyStranger);
        emit log_named_uint("selectors reverting Unauthorized for stranger", guardedCount);
    }

    function test_B_replayProbed() public {
        vm.createSelectFork(rpc);
        _replay(F35, BOT_F35);
        _replay(D1E, BOT_D1E);
        _replay(N9E, BOT_9E1);
        _replay(A3F, BOT_A3F);
    }

    function _replay(bytes memory cd, address bot) internal {
        (bool okS, bytes memory rS) = _callAs(STRANGER, cd);
        (bool okB, bytes memory rB) = _callAs(bot, cd);
        (bool okO, bytes memory rO) = _callAs(OWNER, cd);
        emit log_named_bytes("REPLAY_CD", cd);
        emit log_named_uint("  stranger_ok", okS ? 1 : 0); emit log_named_bytes("  stranger_ret", rS);
        emit log_named_uint("  bot_ok", okB ? 1 : 0);      emit log_named_bytes("  bot_ret", rB);
        emit log_named_uint("  owner_ok", okO ? 1 : 0);    emit log_named_bytes("  owner_ret", rO);
    }

    function test_C_guardHolds() public {
        vm.createSelectFork(rpc);
        (bool okS, bytes memory rS) = _callAs(STRANGER, D1E);
        assertFalse(okS, "stranger must revert on d1e57635");
        assertEq(bytes4(rS), UNAUTH, "stranger must get Unauthorized()");
        (bool okB, ) = _callAs(BOT_D1E, D1E);
        assertTrue(okB, "authorized bot must pass d1e57635");
        emit log_string("guard holds: stranger Unauthorized, bot OK");
    }

    function test_D_callbackGuards() public {
        vm.createSelectFork(rpc);
        bytes[3] memory cbs;
        cbs[0] = abi.encodeWithSelector(bytes4(0x91dd7346), hex"00");
        cbs[1] = abi.encodeWithSelector(bytes4(0x23a69e75), uint256(0), uint256(0), uint256(0));
        cbs[2] = abi.encodeWithSelector(bytes4(0xfa461e33), uint256(0), uint256(0), uint256(0));
        for (uint256 i = 0; i < 3; i++) {
            (bool ok, bytes memory r) = _callAs(STRANGER, cbs[i]);
            emit log_named_bytes("CALLBACK_SEL", abi.encodePacked(bytes4(cbs[i])));
            emit log_named_uint("  stranger_ok", ok ? 1 : 0);
            emit log_named_bytes("  stranger_ret", r);
        }
    }

    function test_E_noUnprivilegedDrain() public {
        vm.createSelectFork(rpc);
        bytes4[39] memory sels = _selectors();
        uint256 bankBefore = BANK.balance;
        uint256 bankAddrBefore = BANK_ADDR.balance;
        uint256 strangerBefore = STRANGER.balance;

        for (uint256 i = 0; i < 39; i++) {
            _callAs(STRANGER, abi.encodePacked(sels[i], new bytes(512)));
        }
        _callAs(STRANGER, F35); _callAs(STRANGER, D1E); _callAs(STRANGER, N9E); _callAs(STRANGER, A3F);
        _callAs(STRANGER, abi.encodeWithSelector(bytes4(0xb6a5d7de), STRANGER));

        assertEq(BANK.balance, bankBefore, "bank native changed");
        assertEq(BANK_ADDR.balance, bankAddrBefore, "BANK_ADDRESS native changed");
        assertEq(STRANGER.balance, strangerBefore, "stranger gained");
        emit log_named_uint("bank native after battery (wei)", BANK.balance);
    }

    function test_F_valueAtRisk() public {
        vm.createSelectFork(rpc);
        emit log_named_uint("BANK native wei", BANK.balance);
        emit log_named_uint("BANK_ADDRESS native wei", BANK_ADDR.balance);
        emit log_named_uint("OWNER native wei", OWNER.balance);
        emit log_named_uint("BANK USDT", IERC20(USDT).balanceOf(BANK));
        emit log_named_uint("BANK USDC", IERC20(USDC).balanceOf(BANK));
        emit log_named_uint("BANK WBNB", IERC20(WBNB).balanceOf(BANK));
    }

    function test_G_impersonationDiagnostics() public {
        vm.createSelectFork(rpc);
        vm.prank(UNI_MANAGER);
        (bool ok1, bytes memory r1) = BANK.call(abi.encodeWithSelector(bytes4(0x91dd7346), abi.encode(uint256(0))));
        emit log_named_uint("unlockCallback as UNI_MANAGER ok", ok1 ? 1 : 0);
        emit log_named_bytes("unlockCallback as UNI_MANAGER ret", r1);

        vm.prank(OWNER);
        (bool ok2, ) = BANK.call(abi.encodeWithSelector(bytes4(0xb6a5d7de), STRANGER));
        emit log_named_uint("authorize(STRANGER) as OWNER ok", ok2 ? 1 : 0);
        (bool ok3, bytes memory r3) = _callAs(STRANGER, D1E);
        emit log_named_uint("d1e57635 by STRANGER after authorize ok", ok3 ? 1 : 0);
        emit log_named_bytes("  ret", r3);
    }
}
