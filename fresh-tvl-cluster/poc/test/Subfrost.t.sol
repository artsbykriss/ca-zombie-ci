// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
// NOTE: `import {ForkHelper} from "../src/ForkHelper.sol";` is the intended base, but the vendored
// ForkHelper.sol does NOT compile against forge-std 1.9.6 (redeclares the inherited VM_ADDRESS
// constant -> Error 9097). See analysis/narausd/FORKHELPER-BLOCKER.md. Until the parent lands the
// 1-line fix, this file carries the byte-identical keyless-fork logic inline.

abstract contract SubfrostH17ForkBase is Test {
    address internal constant H17_VM = address(uint160(uint256(keccak256("hevm cheat code"))));

    function h17Fork(string memory envKey, string[] memory fallbacks) internal returns (string memory url) {
        string memory override_ = vm.envOr(envKey, string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = H17_VM.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return override_;
        }
        for (uint256 i = 0; i < fallbacks.length; i++) {
            if (bytes(fallbacks[i]).length == 0) continue;
            (bool ok,) = H17_VM.call(abi.encodeWithSignature("createSelectFork(string)", fallbacks[i]));
            if (ok) return fallbacks[i];
        }
        revert("SubfrostH17ForkBase: no reachable RPC");
    }
}

interface IERC20b {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface IVault {
    function totalAssets(uint8) external view returns (uint256);
    function assets(uint8) external view returns (address);
    function assetCount() external view returns (uint8);
    function defaultPublicKey() external view returns (bytes32);
    function authNonce() external view returns (uint256);
    function relayerCount() external view returns (uint256);
    function relayerAdmin() external view returns (address);
    function isRelayer(address) external view returns (bool);
    function flatFee() external view returns (uint256);
    function protocolFeeBps() external view returns (uint256);
    function feeRecipient() external view returns (address);
    function strategy() external view returns (address);
    function nextBurnNonce() external view returns (uint256);
    function getPaymentsLength() external view returns (uint256);
    function depositAndBridge(uint8, uint256, bytes calldata) external returns (uint256);
    function withdrawFromBridge(uint256, uint8, uint256, address, bytes calldata) external;
    function authenticatedCall(bytes calldata, uint256, bytes calldata) external returns (bytes memory);
    function upgradeToAndCall(address, bytes calldata) external payable;
    function initialize(address[] calldata, bytes32, uint256, address) external;
}

interface IStrategy {
    function vault() external view returns (address);
    function pool() external view returns (address);
    function lpToken() external view returns (address);
    function owner() external view returns (address);
    function isActive() external view returns (bool);
    function deposit(uint8, uint256) external;
    function withdraw(uint8, uint256) external returns (uint256);
    function withdrawAll(uint8) external returns (uint256);
    function emergencyWithdraw() external;
    function lpBalance() external view returns (uint256);
    function totalAssets(uint8) external view returns (uint256);
}

/// @title Z3-H17 SUBFROST (Ethereum side) — adversarial fork suite (read-only mainnet fork)
/// @notice frUSD is a BITCOIN alkane; the Ethereum side is a custody vault. E-U verdict: every
///         fund-moving path is FROST(BIP340)-gated (`onlyAuth`) or immutable-vault-gated; the
///         permissionless entry (`depositAndBridge`) only takes the caller's own funds. The
///         T5 test simulates the P-class holder of the FROST key on the fork (test key stored
///         into slot 4) to quantify the trust model: whoever signs, drains.
contract SubfrostH17Test is SubfrostH17ForkBase {
    address constant VAULT = 0x95779E7E1C943042255B8a78273fe6DE4823CF06;
    address constant IMPL = 0x5376BeeDBa9Ba7F5b0396d28bd75473027B8Bd55;
    address constant STRAT = 0x5c5D66C82e2C634074661C3E7427668737C70100;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address constant RELAYER = 0x50746642693e05Cc8fc93678b2323B9c131e6385;
    address constant ATTACKER = 0x000000000000000000000000000000000000a77A;
    address constant STRAT_OWNER = 0x896F346bC711a8fd2cDA87eA6c84DE85BDd52e7c;
    bytes32 constant PKEY_SLOT = bytes32(uint256(4)); // pinned: defaultPublicKey (verified live)
    bytes32 constant NONCE_SLOT = bytes32(uint256(5)); // pinned: authNonce (verified live)

    // Fork-only BIP340 TEST key (pubkey x = TEST_PX; private key is printed in
    // analysis/subfrost/bip340_sign2.py output and is a throwaway). Signatures below were
    // self-verified off-chain against the exact BIP340 challenge the vault computes.
    uint256 constant TEST_PX = 0xf41008cdda40dd2586bbb206eb420407eaa18225b7a4d83753508bb310b13a38;
    uint256 constant NONCE = 777000; // vm.store()d into authNonce so sigs are deterministic
    uint256 constant W1_RX = 0x1f15ead3b25f4680c8ed1a5b3bf22f4f7a1acad04a21d886eb557f7ecc5b75af;
    uint256 constant W1_S = 0x97091b914250a68135085b8a7a3b149a6b3e8f0dfa17505e84cc1004d9f25cce;
    uint256 constant W2_RX = 0x2c7ac6fefed4060508f06846959b2a5395070dd682fdd5669030002a63dc6d4f;
    uint256 constant W2_S = 0xa37ecd5d003a1ce6a4c57c020d5c8979e8987f67e012b27b2cd66c33f4ec4d9f;
    uint256 constant RP_RX = 0x7d18285d9c5d4179ddd4f6ccf1f1a4fd1950bd377acee043e01fcba072549750;
    uint256 constant RP_S = 0x30977e9f967475bede4625cd89a60417790d61770d62d285e76023ddbd4202c0;

    IVault vault = IVault(VAULT);
    IStrategy strat = IStrategy(STRAT);

    function setUp() public {
        string[] memory fb = new string[](3);
        fb[0] = "https://ethereum-rpc.publicnode.com";
        fb[1] = "https://eth.drpc.org";
        fb[2] = "https://1rpc.io/eth";
        h17Fork("FORK_RPC", fb);
        console2.log("FORK BLOCK", block.number);
    }

    function _wd(uint256 bn, uint8 id, uint256 amt) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "withdrawFromBridge(uint256,uint8,uint256,address,bytes)", bn, id, amt, ATTACKER, bytes("")
        );
    }

    /* ---------- T1: live state + structural facts ---------- */
    function test_T1_liveState() public {
        assertEq(
            uint256(vm.load(VAULT, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)),
            uint256(uint160(IMPL)),
            "EIP-1967 impl slot == verified VaultImpl"
        );
        assertEq(uint256(vm.load(VAULT, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)), 0, "no proxy admin");
        assertEq(vault.assetCount(), 2, "two assets");
        assertEq(vault.assets(0), USDC, "asset 0 = USDC");
        assertEq(vault.assets(1), USDT, "asset 1 = USDT");
        assertEq(vault.strategy(), STRAT, "strategy wired");
        assertEq(strat.vault(), VAULT, "strategy vault immutable");
        assertEq(strat.pool(), 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, "3pool");
        assertEq(strat.lpToken(), CRV3, "3CRV");
        console2.log("USDC idle (6dp)", IERC20b(USDC).balanceOf(VAULT));
        console2.log("USDT idle (6dp)", IERC20b(USDT).balanceOf(VAULT));
        console2.log("totalAssets(0) USDC", vault.totalAssets(0));
        console2.log("totalAssets(1) USDT", vault.totalAssets(1));
        console2.log("strategy lpBalance", strat.lpBalance());
        console2.log("flatFee", vault.flatFee());
        console2.log("protocolFeeBps", vault.protocolFeeBps());
        console2.log("authNonce", vault.authNonce());
        console2.log("relayerCount", vault.relayerCount());
        console2.log("nextBurnNonce", vault.nextBurnNonce());
        console2.log("payments queued", vault.getPaymentsLength());
        console2.log("defaultPublicKey", uint256(vault.defaultPublicKey()));
        assertTrue(vault.isRelayer(RELAYER), "relayer live");
    }

    /* ---------- T2: public deposit works but is one-way on the EVM side ---------- */
    function test_T2_publicDepositIsOneWay() public {
        deal(USDC, ATTACKER, 100e6);
        uint256 before = vault.getPaymentsLength();
        uint256 flat = vault.flatFee();
        uint256 bps = vault.protocolFeeBps();
        uint256 expectedNet = 100e6 - flat - ((100e6 - flat) * bps) / 10000;

        vm.startPrank(ATTACKER);
        IERC20b(USDC).approve(VAULT, 100e6);
        uint256 net = vault.depositAndBridge(0, 100e6, "");
        vm.stopPrank();

        console2.log("deposit net credited", net);
        assertEq(net, expectedNet, "net = deposit - flat - bps");
        assertEq(vault.getPaymentsLength(), before + 1, "payment queued");
        assertEq(IERC20b(USDC).balanceOf(ATTACKER), 0, "100 USDC locked in the vault");
        // no EVM-side exit for the depositor without a FROST signature
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        vault.withdrawFromBridge(0x51000, 0, 10e6, ATTACKER, "");
        vm.stopPrank();
    }

    /* ---------- T3: authority gates (relayer, FROST, upgrade) ---------- */
    function test_T3_authorityGates() public {
        // direct withdraw: NotSelf (onlyAuth = the vault itself)
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        vault.withdrawFromBridge(0x51000, 0, 1e6, ATTACKER, "");
        // submission gate: non-relayer cannot call authenticatedCall
        vm.expectRevert();
        vault.authenticatedCall(_wd(0x51000, 0, 1e6), NONCE, new bytes(64));
        // upgrade: onlyAuth
        vm.expectRevert();
        vault.upgradeToAndCall(address(0xdead), "");
        vm.stopPrank();

        // even a live relayer cannot pass the signature gate with garbage
        uint256 n = vault.authNonce();
        vm.startPrank(RELAYER);
        vm.expectRevert(); // empty sig -> InvalidSignature
        vault.authenticatedCall(_wd(0x51000, 0, 1e6), n, "");
        vm.expectRevert(); // 64 zero bytes -> InvalidSignature
        vault.authenticatedCall(_wd(0x51000, 0, 1e6), n, new bytes(64));
        vm.expectRevert(); // flipped-bit legit-looking sig -> InvalidSignature
        vault.authenticatedCall(_wd(0x51000, 0, 1e6), n, abi.encodePacked(bytes32(W1_RX), bytes32(W1_S ^ 1)));
        vm.stopPrank();

        // initialize is spent
        address[] memory a = new address[](1);
        a[0] = USDC;
        vm.prank(ATTACKER);
        vm.expectRevert();
        vault.initialize(a, bytes32(TEST_PX), 0, ATTACKER);
    }

    /* ---------- T4: strategy gates + owner escape hatch goes to the vault only ---------- */
    function test_T4_strategyGates() public {
        vm.startPrank(ATTACKER);
        vm.expectRevert(); // NotVault
        strat.deposit(0, 1e6);
        vm.expectRevert(); // NotVault
        strat.withdraw(0, 1e6);
        vm.expectRevert(); // NotVault
        strat.withdrawAll(0);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        strat.emergencyWithdraw();
        vm.stopPrank();

        // owner CAN force the position home (to the immutable vault), nothing else
        uint256 lpBefore = strat.lpBalance();
        uint256 vaultDaiBefore = IERC20b(DAI).balanceOf(VAULT);
        vm.prank(STRAT_OWNER);
        strat.emergencyWithdraw();
        console2.log("lpBefore", lpBefore);
        console2.log("lpAfter", strat.lpBalance());
        console2.log("vault DAI received", IERC20b(DAI).balanceOf(VAULT) - vaultDaiBefore);
        assertEq(strat.lpBalance(), 0, "position exited");
        assertGt(IERC20b(DAI).balanceOf(VAULT), vaultDaiBefore, "proceeds went to the vault, not the owner");
        assertEq(IERC20b(USDC).balanceOf(STRAT_OWNER), 0, "owner received nothing");
    }

    /* ---------- T5: P-class simulation — the FROST key holder drains (fork only) ---------- */
    function test_T5_frostKeyHolderDrains() public {
        assertTrue(vault.isRelayer(RELAYER), "need a live relayer to submit");
        // install a known TEST pubkey + deterministic nonce (fork-only state edit)
        vm.store(VAULT, PKEY_SLOT, bytes32(TEST_PX));
        vm.store(VAULT, NONCE_SLOT, bytes32(NONCE));
        assertEq(uint256(vault.defaultPublicKey()), TEST_PX, "test key installed");
        assertEq(vault.authNonce(), NONCE, "nonce set");

        uint256 flat = vault.flatFee();
        uint256 bps = vault.protocolFeeBps();
        uint256 net1 = 100e6 - flat - ((100e6 - flat) * bps) / 10000;
        uint256 net2 = 900e6 - flat - ((900e6 - flat) * bps) / 10000;
        uint256 usdcBefore = IERC20b(USDC).balanceOf(ATTACKER);
        uint256 usdtBefore = IERC20b(USDT).balanceOf(ATTACKER);

        vm.startPrank(RELAYER);
        vault.authenticatedCall(_wd(0x51001, 0, 100e6), NONCE, abi.encodePacked(bytes32(W1_RX), bytes32(W1_S)));
        vm.stopPrank();
        assertEq(IERC20b(USDC).balanceOf(ATTACKER) - usdcBefore, net1, "USDC payout exact");
        assertEq(vault.authNonce(), NONCE + 1, "nonce consumed");

        // replay of the same payload (same nonce) is rejected
        vm.prank(RELAYER);
        vm.expectRevert();
        vault.authenticatedCall(_wd(0x51001, 0, 100e6), NONCE, abi.encodePacked(bytes32(W1_RX), bytes32(W1_S)));

        // second payout (USDT) under the next nonce
        vm.prank(RELAYER);
        vault.authenticatedCall(_wd(0x51002, 1, 900e6), NONCE + 1, abi.encodePacked(bytes32(W2_RX), bytes32(W2_S)));
        assertEq(IERC20b(USDT).balanceOf(ATTACKER) - usdtBefore, net2, "USDT payout exact");

        // same Bitcoin burn replayed (fresh nonce, same bridgeNonce) is rejected
        vm.prank(RELAYER);
        vm.expectRevert();
        vault.authenticatedCall(_wd(0x51001, 0, 100e6), NONCE + 2, abi.encodePacked(bytes32(RP_RX), bytes32(RP_S)));

        console2.log("P-class drain USDC (net)", net1);
        console2.log("P-class drain USDT (net)", net2);
        console2.log("remaining totalAssets(0)", vault.totalAssets(0));
        console2.log("remaining totalAssets(1)", vault.totalAssets(1));
    }
}
