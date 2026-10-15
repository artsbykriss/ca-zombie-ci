// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IERC20, IBridgeToken, IUniswapV2Pair, IUniswapV2Factory, IHyperlaneMailbox, IInterchainSecurityModule, IMultisigIsm, IProtocolReserve} from "../src/Interfaces.sol";

/// @title Anubis (RocketSwap) fork verification
/// @notice Read-only fork checks: proves the live mint/bridge/release paths are gated
///         and that the AMM pools behave canonically (no free money).
contract AnubisTest is Test {
    string constant RPC = "https://rpc.anubispace.org"; // keyless public endpoint

    address constant DAI = 0x83fd06F0846d9D90B3016bF670Efe2E0B11cDe14; // HyperlaneSyntheticToken
    address constant USDT = 0xDfb6a28BC6DC51fed17c27C880F2c66cDd040A3e; // HyperlaneSyntheticToken (6 dec)
    address constant PUBLIC_BRIDGE = 0x8932fe7726C1EE743F662f485C3e5a5D1D595F71;
    address constant PRIVATE_BRIDGE = 0x250BA4E73A365CEfdd170a2b1ff9fc03097D64f3;
    address constant MAILBOX = 0x599899e6b3b1362Ba2460D125756a738eC1592D6;
    address constant ISM = 0x966b26267AADfC1be995803d09797E523352465D;
    address constant PAIR_DAI_USDT = 0xF14C0e3Da42Fc36A416E6036dC4c7cA0375B734f;
    address constant PAIR_ROME_USDT = 0x8CBaBF4E076baAad295fD32b3249E7F9D812B9c5;
    address constant PAIR_LGNS_DAI = 0x32A4586797E3f561F41C0F47CA57eD08D64f3dC0;
    address constant PROTOCOL_RESERVE = 0x27Cb55eE75E777fF972B74B6E68782D12Bd4ec46;
    address constant OWNER_EOA = 0x73d7297753F47414A436c1b4123C5113917a496d;
    address constant ATTACKER = 0x00000000000000000000000000000000BADadd57;

    // tokenId registered for USDT on the public bridge (from TokenRegistered events)
    bytes32 constant TOKENID_USDT = 0x8b1a1d9c2b109e527c9134b25b1a1833b16b6594f92daa9f6d9b7a6024bce9d0;

    uint256 forkBlock;

    function setUp() public {
        forkBlock = vm.createSelectFork(RPC);
        emit log_named_uint("fork block", forkBlock);
    }

    // ------------------------------------------------------------------
    // 1. The bridge ISM is the canonical Hyperlane 2-of-3 multisig
    // ------------------------------------------------------------------
    function test_ism_is_canonical_2of3() public {
        uint8 moduleType = IInterchainSecurityModule(ISM).moduleType();
        assertEq(moduleType, 4, "ISM must be MERKLE_ROOT_MULTISIG (4)");

        (address[] memory validators, uint8 threshold) = IMultisigIsm(ISM).validatorsAndThreshold("");
        assertEq(threshold, 2, "threshold must be 2");
        assertEq(validators.length, 3, "validator set must be 3");
        emit log_named_uint("threshold", threshold);
        for (uint256 i = 0; i < validators.length; i++) {
            emit log_named_address("validator", validators[i]);
        }

        // mailbox wiring
        assertEq(IHyperlaneMailbox(MAILBOX).localDomain(), 6714, "local domain must be Anubis (6714)");
        assertEq(IHyperlaneMailbox(MAILBOX).recipientIsm(PUBLIC_BRIDGE), ISM, "bridge ISM");
    }

    // ------------------------------------------------------------------
    // 2. Forged Hyperlane message cannot mint (the key extraction path)
    // ------------------------------------------------------------------
    function _buildMessage(bytes32 tokenId, address recipient, uint256 amount) internal view returns (bytes memory) {
        // Hyperlane v3 message: version | nonce | origin | sender | destination | recipient | body
        bytes memory body = abi.encode(uint8(1), tokenId, bytes32(uint256(uint160(recipient))), amount);
        return abi.encodePacked(
            IHyperlaneMailbox(MAILBOX).VERSION(), // version
            uint32(1), // nonce
            uint32(1), // origin = Ethereum
            bytes32(uint256(uint160(PUBLIC_BRIDGE))), // sender = the remote router on Ethereum
            uint32(6714), // destination = Anubis
            bytes32(uint256(uint160(PUBLIC_BRIDGE))), // recipient = public bridge on Anubis
            body
        );
    }

    function test_forged_message_rejected_empty_metadata() public {
        bytes memory message = _buildMessage(TOKENID_USDT, ATTACKER, 1_000_000e6);
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = MAILBOX.call(
            abi.encodeWithSelector(IHyperlaneMailbox.process.selector, bytes(""), message)
        );
        assertFalse(ok, "forged message with empty metadata must NOT be processed");
        emit log_named_bytes("revert data (empty metadata)", ret);
    }

    function test_forged_message_rejected_fake_signature() public {
        bytes memory message = _buildMessage(TOKENID_USDT, ATTACKER, 1_000_000e6);
        // 65 zero bytes pretending to be a signature + a fake merkle root
        bytes memory metadata = abi.encode(bytes32(uint256(0xdead)), new bytes(65));
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = MAILBOX.call(
            abi.encodeWithSelector(IHyperlaneMailbox.process.selector, metadata, message)
        );
        assertFalse(ok, "forged message with fake signature must NOT be processed");
        emit log_named_bytes("revert data (fake signature)", ret);
    }

    function test_ism_verify_rejects_without_validator_signatures() public {
        bytes memory message = _buildMessage(TOKENID_USDT, ATTACKER, 1_000_000e6);
        (bool ok, bytes memory ret) = ISM.staticcall(abi.encodeWithSelector(IInterchainSecurityModule.verify.selector, bytes(""), message));
        if (ok) {
            assertEq(abi.decode(ret, (bool)), false, "verify must not return true");
        } else {
            emit log_named_bytes("verify revert data", ret);
        }
        assertTrue(true);
    }

    // ------------------------------------------------------------------
    // 3. Synthetic tokens can only be minted by the bridges
    // ------------------------------------------------------------------
    function test_token_mints_are_bridge_gated() public {
        (bool ok, bytes memory ret) = DAI.call(
            abi.encodeWithSelector(IBridgeToken.mintPublic.selector, ATTACKER, 1_000_000e18)
        );
        assertFalse(ok, "mintPublic must revert for external caller");
        emit log_named_bytes("DAI.mintPublic revert", ret);

        (ok, ret) = USDT.call(abi.encodeWithSelector(IBridgeToken.mintPrivate.selector, ATTACKER, 1_000_000e6));
        assertFalse(ok, "mintPrivate must revert for external caller");
        emit log_named_bytes("USDT.mintPrivate revert", ret);

        // wiring
        assertEq(IBridgeToken(DAI).publicBridge(), PUBLIC_BRIDGE);
        assertEq(IBridgeToken(DAI).privateBridge(), PRIVATE_BRIDGE);
        assertEq(IBridgeToken(DAI).owner(), OWNER_EOA);
    }

    // ------------------------------------------------------------------
    // 4. ProtocolReserve (57.8M DAI) withdraw is admin-gated
    // ------------------------------------------------------------------
    function test_protocol_reserve_withdraw_is_admin_gated() public {
        uint256 bal = IERC20(DAI).balanceOf(PROTOCOL_RESERVE);
        assertGt(bal, 50_000_000e18, "reserve holds >50M DAI");
        emit log_named_uint("ProtocolReserve DAI", bal / 1e18);
        (bool ok, bytes memory ret) = PROTOCOL_RESERVE.call(
            abi.encodeWithSelector(IProtocolReserve.withdraw.selector, DAI, ATTACKER, bal, bytes32(uint256(1)))
        );
        assertFalse(ok, "withdraw must revert for non-admin");
        emit log_named_bytes("withdraw revert", ret);
    }

    // ------------------------------------------------------------------
    // 5. No skim-able excess in the big pools; skim() pays the caller 0
    // ------------------------------------------------------------------
    function _checkNoExcess(address pair) internal {
        (uint112 r0, uint112 r1, ) = IUniswapV2Pair(pair).getReserves();
        address t0 = IUniswapV2Pair(pair).token0();
        address t1 = IUniswapV2Pair(pair).token1();
        uint256 b0 = IERC20(t0).balanceOf(pair);
        uint256 b1 = IERC20(t1).balanceOf(pair);
        assertEq(b0, uint256(r0), "no token0 excess");
        assertEq(b1, uint256(r1), "no token1 excess");
    }

    function test_no_skimable_excess_in_top_pools() public {
        _checkNoExcess(PAIR_DAI_USDT);
        _checkNoExcess(PAIR_ROME_USDT);
        _checkNoExcess(PAIR_LGNS_DAI);

        uint256 a0 = IERC20(DAI).balanceOf(ATTACKER);
        uint256 a1 = IERC20(USDT).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        IUniswapV2Pair(PAIR_DAI_USDT).skim(ATTACKER);
        assertEq(IERC20(DAI).balanceOf(ATTACKER), a0, "skim pays nothing (DAI)");
        assertEq(IERC20(USDT).balanceOf(ATTACKER), a1, "skim pays nothing (USDT)");
    }

    // ------------------------------------------------------------------
    // 6. Canonical UniV2 swap math (no free money): exact-input swap
    // ------------------------------------------------------------------
    /// @dev OZ v5 *non-upgradeable* ERC20 keeps `_balances` in plain slot 0
    ///      (verified on-chain: keccak256(pair,0) holds the pair's DAI balance).
    function _setBalance(address token, address account, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encode(account, uint256(0)));
        vm.store(token, slot, bytes32(amount));
        require(IERC20(token).balanceOf(account) == amount, "vm.store balance failed");
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function test_v2_swap_is_canonical() public {
        address pair = PAIR_DAI_USDT;
        address t0 = IUniswapV2Pair(pair).token0(); // DAI
        address t1 = IUniswapV2Pair(pair).token1(); // USDT
        (uint112 r0, uint112 r1, ) = IUniswapV2Pair(pair).getReserves();

        uint256 amountIn = 100_000e18; // 100k DAI
        uint256 expectedOut = _getAmountOut(amountIn, uint256(r0), uint256(r1));

        _setBalance(t0, address(this), amountIn);
        _setBalance(t1, address(this), 0);

        IERC20(t0).transfer(pair, amountIn);
        IUniswapV2Pair(pair).swap(0, expectedOut, address(this), "");

        uint256 received = IERC20(t1).balanceOf(address(this));
        emit log_named_uint("DAI in (1e18)", amountIn / 1e18);
        emit log_named_uint("USDT out (1e6)", received / 1e6);
        assertEq(received, expectedOut, "output must equal canonical x*y=k output");
    }

    // ------------------------------------------------------------------
    // 7. LP round-trip cannot create value (mint then burn)
    // ------------------------------------------------------------------
    function test_v2_lp_roundtrip_no_free_money() public {
        address pair = PAIR_DAI_USDT;
        address t0 = IUniswapV2Pair(pair).token0();
        address t1 = IUniswapV2Pair(pair).token1();

        uint256 d0 = 50_000e18;
        uint256 d1 = 50_000e6;
        _setBalance(t0, address(this), d0);
        _setBalance(t1, address(this), d1);

        IERC20(t0).transfer(pair, d0);
        IERC20(t1).transfer(pair, d1);
        uint256 lp = IUniswapV2Pair(pair).mint(address(this));
        assertGt(lp, 0, "LP minted");

        // burn everything back
        IUniswapV2Pair(pair).transfer(pair, lp);
        (uint256 out0, uint256 out1) = IUniswapV2Pair(pair).burn(address(this));
        emit log_named_uint("DAI out (1e18)", out0 / 1e18);
        emit log_named_uint("USDT out (1e6)", out1 / 1e6);
        assertLe(out0, d0, "cannot withdraw more DAI than deposited");
        assertLe(out1, d1, "cannot withdraw more USDT than deposited");
    }
}
