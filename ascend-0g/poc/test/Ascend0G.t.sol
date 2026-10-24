// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/* ------------------------------------------------------------------ */
/* Ascend (a0G) on 0G — fresh-attacker verification of the OFT/queue  */
/* hypothesis (ZH4-PASS6 P6-02). Read-only fork PoC, no mainnet tx.    */
/* Chain: 0G (16661). All addresses are mainnet 0G deployments.        */
/* ------------------------------------------------------------------ */

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

struct SendParam {
    uint32 dstEid;
    bytes32 to;
    uint256 amountLD;
    uint256 minAmountLD;
    bytes extraOptions;
    bytes composeMsg;
    bytes oftCmd;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct OFTReceipt {
    uint256 amountSentLD;
    uint256 amountReceivedLD;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IW0G is IERC20 {
    function deposit() external payable;
}

interface ISourceCore {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToShares(uint256) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function previewRedeem(uint256) external view returns (uint256);
    function previewDeposit(uint256) external view returns (uint256);
    function maxRedeem(address) external view returns (uint256);
    function deposit(uint256, address) external returns (uint256);
    function requestWithdrawal(uint256) external;
    function pull(uint256, uint256) external;
    function oracle() external view returns (address);
    function withdrawalQueue() external view returns (address);
    function oftAdapter() external view returns (address);
    function targetEndpointId() external view returns (uint32);
    function targetCoreAddress() external view returns (bytes32);
    function limit() external view returns (uint256);
}

interface IOracle {
    function value() external view returns (uint256);
    function maxAge() external view returns (uint256);
    function lastUpdated() external view returns (uint256);
    function getValue() external view returns (uint256);
    function setValue(uint256) external;
}

interface IKeeper {
    function setValue(uint256) external;
    function hasRole(bytes32, address) external view returns (bool);
}

interface IWithdrawalQueue {
    function sourceCore() external view returns (address);
    function asset() external view returns (address);
    function totalShares() external view returns (uint256);
    function currentEpoch() external view returns (uint256);
    function epochIterator() external view returns (uint256);
    function withdrawalDelay() external view returns (uint256);
    function epochDuration() external view returns (uint256);
    function initTimestamp() external view returns (uint256);
    function sharesOf(uint256, address) external view returns (uint256);
    function shares(uint256) external view returns (uint256);
    function withdrawals(uint256) external view returns (uint256);
    function request(address, uint256) external;
    function claim(uint256, address) external returns (uint256);
    function handleEpoch() external;
    function setWithdrawalDelay(uint256) external;
}

interface ILZReceiver {
    function lzReceive(Origin calldata, bytes32, bytes calldata, address, bytes calldata) external payable;
}

interface IMellowOFTAdapter is ILZReceiver {
    function token() external view returns (address);
    function endpoint() external view returns (address);
    function sourceCore() external view returns (address);
    function approvalRequired() external view returns (bool);
    function owner() external view returns (address);
    function peers(uint32) external view returns (bytes32);
    function initialize(address) external;
    function send(SendParam calldata, MessagingFee calldata, address) external payable returns (MessagingReceipt memory, OFTReceipt memory);
    function removeDust(uint256) external view returns (uint256);
}

contract Ascend0GTest is Test {
    // ---- 0G mainnet (chainId 16661) addresses ----
    address constant VAULT   = 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB; // SourceCore proxy (a0G)
    address constant IMPL    = 0x5F5E90Eda845c948dF101A1263e17aF2d2bdf292; // SourceCore impl
    address constant PROXYADMIN = 0xD2cc3b349f0080235AE9eEA0d25f4c556F785c20;
    address constant QUEUE   = 0x10A98a5344742308744Bd59829786584A12C1146; // WithdrawalQueue
    address constant OFTADP  = 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF; // MellowOFTAdapter
    address constant W0G     = 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c; // Wrapped 0G
    address constant ORACLE  = 0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab; // Oracle
    address constant KEEPER  = 0xa57e348Afb83153cE2aB27210FFB35c9860B3A42; // value keeper proxy (holds ORACLE:SET_VALUE_ROLE)
    address constant LZEP    = 0xcb566e3B6934Fa77258d68ea18E931fa75e1aaAa; // LayerZero EndpointV2 (0G)
    address constant ETH_PEER = 0xE42215BD71E190b3864267569c2f66077260EaE4; // "0G Vault OFT" on Ethereum (EID 30101)

    uint32 constant EID_ETH = 30101;
    uint32 constant EID_0G  = 30388;

    address constant ATTACKER = 0x000000000000000000000000000000000000dEaD;

    ISourceCore vault;
    IWithdrawalQueue queue;
    IMellowOFTAdapter oft;
    IOracle oracle;
    IW0G w0g;

    uint256 forkBlock;

    function setUp() public {
        // OG_RPC_URL (set by ci/run.sh) > rpc_endpoint alias "og" (foundry.toml) > literal
        string memory rpc = vm.envOr("OG_RPC_URL", string("og"));
        uint256 blk = vm.envOr("OG_FORK_BLOCK", uint256(0));
        if (blk == 0) {
            forkBlock = vm.createSelectFork(rpc);
        } else {
            forkBlock = vm.createSelectFork(rpc, blk);
        }
        vault = ISourceCore(VAULT);
        queue = IWithdrawalQueue(QUEUE);
        oft = IMellowOFTAdapter(OFTADP);
        oracle = IOracle(ORACLE);
        w0g = IW0G(W0G);
        vm.label(VAULT, "SourceCore(a0G)");
        vm.label(QUEUE, "WithdrawalQueue");
        vm.label(OFTADP, "MellowOFTAdapter");
        vm.label(LZEP, "LZ EndpointV2");
    }

    /* ============================ state ============================ */

    function test_S0_liveState() public view {
        console2.log("fork block", forkBlock);
        console2.log("vault asset", vault.asset());
        console2.log("vault totalAssets", vault.totalAssets());
        console2.log("vault totalSupply", vault.totalSupply());
        console2.log("oracle value", oracle.value());
        console2.log("queue totalShares", queue.totalShares());
        console2.log("queue a0G balance", IERC20(VAULT).balanceOf(QUEUE));
        console2.log("oft W0G locked", w0g.balanceOf(OFTADP));
        console2.log("vault W0G liquid", w0g.balanceOf(VAULT));
        console2.log("oft peer(30101)", uint256(oft.peers(EID_ETH)));
        assertEq(vault.asset(), W0G, "asset is W0G");
        assertEq(vault.oftAdapter(), OFTADP, "adapter wired");
        assertEq(vault.withdrawalQueue(), QUEUE, "queue wired");
        assertEq(queue.sourceCore(), VAULT, "queue sourceCore");
        assertEq(oft.sourceCore(), VAULT, "adapter sourceCore");
        assertEq(oft.token(), W0G, "adapter token is W0G (NOT a0G)");
    }

    // totalAssets is oracle-derived: supply * oracle.value / 1e18
    function test_S1_totalAssetsIsOracleDerived() public view {
        uint256 expected = vault.totalSupply() * oracle.value() / 1e18;
        assertEq(vault.totalAssets(), expected, "totalAssets == supply*oracleValue/1e18");
    }

    /* ============ H1: forged OFT message to unlock/mint ============ */

    function _msg(address to, uint64 amountSD) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(uint256(uint160(to))), amountSD);
    }

    // (a) a random caller cannot invoke lzReceive at all
    function test_H1a_lzReceive_onlyEndpoint() public {
        Origin memory o = Origin({srcEid: EID_ETH, sender: bytes32(uint256(uint160(ETH_PEER))), nonce: 1});
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(0x91ac5e4f, ATTACKER)); // OnlyEndpoint(address)
        oft.lzReceive(o, bytes32(uint256(1)), _msg(ATTACKER, 1_000_000), ATTACKER, "");
    }

    // (b) even via the endpoint, a non-peer sender is rejected
    function test_H1b_lzReceive_onlyPeer() public {
        Origin memory o = Origin({srcEid: EID_ETH, sender: bytes32(uint256(uint160(ATTACKER))), nonce: 1});
        vm.prank(LZEP);
        vm.expectRevert(abi.encodeWithSelector(0xc26bebcc, EID_ETH, bytes32(uint256(uint160(ATTACKER))))); // OnlyPeer
        oft.lzReceive(o, bytes32(uint256(1)), _msg(ATTACKER, 1_000_000), ATTACKER, "");
    }

    // (c) unset path => NoPeer
    function test_H1c_lzReceive_noPeer() public {
        Origin memory o = Origin({srcEid: 30111, sender: bytes32(uint256(uint160(ATTACKER))), nonce: 1});
        vm.prank(LZEP);
        vm.expectRevert(abi.encodeWithSelector(0xf6ff4fb7, uint32(30111))); // NoPeer(uint32)
        oft.lzReceive(o, bytes32(uint256(1)), _msg(ATTACKER, 1_000_000), ATTACKER, "");
    }

    // (d) CONTRAST: the *legit* path (endpoint + real peer) unlocks W0G to the message recipient.
    //     This proves the unlock logic exists and that the gate (a/b/c) is the only barrier.
    function test_H1d_validPeerUnlocks_provesGateIsTheBarrier() public {
        uint256 before = w0g.balanceOf(ATTACKER);
        Origin memory o = Origin({srcEid: EID_ETH, sender: bytes32(uint256(uint160(ETH_PEER))), nonce: 1});
        vm.prank(LZEP);
        oft.lzReceive(o, bytes32(uint256(1)), _msg(ATTACKER, 1_000_000), ATTACKER, "");
        assertEq(w0g.balanceOf(ATTACKER), before + 1e18, "1 W0G unlocked only via endpoint+peer");
    }

    // attacker cannot call send() directly (would let them drain adapter by fabricating a message)
    function test_H1e_send_isSourceCoreOnly() public {
        SendParam memory sp = SendParam({dstEid: EID_ETH, to: bytes32(uint256(uint160(ATTACKER))), amountLD: 1e18, minAmountLD: 0, extraOptions: "", composeMsg: "", oftCmd: ""});
        MessagingFee memory fee = MessagingFee({nativeFee: 0, lzTokenFee: 0});
        vm.deal(ATTACKER, 1 ether);
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("MellowOFTAdapter: forbidden"));
        oft.send{value: 0}(sp, fee, ATTACKER);
    }

    // attacker cannot re-init the adapter to steal the sourceCore link
    function test_H1f_initialize_alreadyDone() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("MellowOFTAdapter: already initialized"));
        oft.initialize(ATTACKER);
    }

    /* ============ H2: queue pays more than a redeemer's share ============ */

    // claim is self-scoped: account = msg.sender, so an attacker can never claim a victim's shares
    function test_H2a_claimIsSelfScoped() public {
        uint256 victimEpoch = queue.epochIterator();
        // attacker has no shares in any epoch
        vm.prank(ATTACKER);
        uint256 got = queue.claim(victimEpoch, ATTACKER); // receiver = attacker, account = attacker
        assertEq(got, 0, "attacker cannot pull another account's shares");
        assertEq(queue.sharesOf(victimEpoch, ATTACKER), 0, "no shares minted to attacker");
    }

    // pull() is queue-only (so no arbitrary burn/transfer of vault assets)
    function test_H2b_pull_isQueueOnly() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("SourceCore: only withdrawalQueue can pull"));
        vault.pull(1, 1);
    }

    // queue.request() is sourceCore-only
    function test_H2c_request_isSourceCoreOnly() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("WithdrawalQueue: forbidden"));
        queue.request(ATTACKER, 1);
    }

    // setWithdrawalDelay is role-gated (not E-U)
    function test_H2d_setDelay_roleGated() public {
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("WithdrawalQueue: forbidden"));
        queue.setWithdrawalDelay(0);
    }

    // End-to-end roundtrip through the async queue: attacker's own funds in, ~same out (dust only).
    function test_H2e_roundtripIsNotProfitable() public {
        uint256 amount = 1e18;
        vm.deal(ATTACKER, amount);
        vm.startPrank(ATTACKER);
        w0g.deposit{value: amount}();
        assertEq(w0g.balanceOf(ATTACKER), amount, "wrapped");
        w0g.approve(VAULT, amount);
        uint256 shares = vault.deposit(amount, ATTACKER);
        assertGt(shares, 0, "shares minted");
        vault.requestWithdrawal(shares);
        vm.stopPrank();

        uint256 reqEpoch = queue.currentEpoch();
        // withdrawalDelay is 22d and is applied to the epoch end; advance past it.
        vm.warp(block.timestamp + 23 days);
        // simulate the live keeper refreshing the oracle (else the vault is stale and reverts)
        uint256 v = oracle.value();
        vm.prank(0xc0412361882961570d79CE535cB26Fc71bf363A7);
        IKeeper(KEEPER).setValue(v);
        for (uint256 i = 0; i < 80; i++) {
            queue.handleEpoch();
        }

        assertGt(queue.sharesOf(reqEpoch, ATTACKER), 0, "attacker has a queued epoch");
        assertGt(queue.epochIterator(), reqEpoch, "attacker epoch processed");

        uint256 balBefore = w0g.balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        uint256 out = queue.claim(reqEpoch, ATTACKER);
        assertEq(w0g.balanceOf(ATTACKER), balBefore + out, "claim paid");
        // no profit: out <= amount (dust loss only)
        assertLe(out, amount, "cannot redeem more than deposited");
        console2.log("deposited", amount);
        console2.log("claimed", out);
        assertLe(amount - out, 1e6, "loss is dust (<1e6 wei)");
    }

    /* ============ H3: oracle / role trust boundary (P, not E-U) ============ */

    function test_H3a_oracleSetValue_isAccessControlled() public {
        vm.prank(ATTACKER);
        vm.expectRevert(); // AccessControlUnauthorizedAccount
        IOracle(KEEPER).setValue(1e30); // attacker tries to inflate NAV via the keeper
    }

    function test_H3b_oracleOnlyKeeperHoldsSetValueRole() public view {
        // ORACLE:SET_VALUE_ROLE is held by the keeper proxy + the admin Safe, not by arbitrary callers
        bytes32 svr = keccak256("ORACLE:SET_VALUE_ROLE");
        (bool ok1, bytes memory r1) = VAULT.staticcall(abi.encodeWithSignature("hasRole(bytes32,address)", svr, KEEPER));
        assertTrue(ok1 && abi.decode(r1, (bool)), "keeper holds SET_VALUE_ROLE");
        (bool ok2, bytes memory r2) = VAULT.staticcall(abi.encodeWithSignature("hasRole(bytes32,address)", svr, ATTACKER));
        assertTrue(ok2 && !abi.decode(r2, (bool)), "attacker does NOT hold SET_VALUE_ROLE");
    }

    function test_H3c_vaultBricksIfOracleStale() public {
        // maxAge is ~21 days; if the keeper stops, the whole vault (incl. queue) reverts (DoS, not drain)
        uint256 age = oracle.maxAge();
        vm.warp(block.timestamp + age + 1);
        vm.expectRevert(bytes("Oracle: stale value"));
        vault.totalAssets();
    }

    /* ============ H4: exit liquidity (H-O, not E-U) ============ */

    function test_H4_exitLiquidityIsTheVaultsLiquidOnly() public view {
        uint256 liquid = w0g.balanceOf(VAULT);
        uint256 queued = vault.previewRedeem(queue.totalShares());
        console2.log("vault liquid W0G", liquid);
        console2.log("queued claim W0G", queued);
        // queue can only be paid from the vault's *liquid* balance, not the OFT-locked W0G
        assertLe(queued, liquid, "queue claimable <= vault liquid");
    }
}
