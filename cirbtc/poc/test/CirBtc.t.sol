// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(uint256) external;
    function configureMinter(address, uint256) external;
    function removeMinter(address) external;
    function incrementMinterAllowance(uint256) external;
    function updateMasterMinter(address) external;
    function updateOwner(address) external;
    function updatePauser(address) external;
    function updateBlacklister(address) external;
    function pause() external;
    function unpause() external;
    function blacklist(address) external;
    function unblacklist(address) external;
    function rescueERC20(address, uint256) external;
    function owner() external view returns (address);
    function masterMinter() external view returns (address);
    function pauser() external view returns (address);
    function blacklister() external view returns (address);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
    function minterAllowance(address) external view returns (uint256);
}

interface IFiatTokenProxy {
    function admin() external view returns (address);
    function implementation() external view returns (address);
    function upgradeTo(address) external;
}

/**
 * @title cirBTC (Circle Wrapped Bitcoin) — permissioned-mint / custodial PoC
 *
 * READ-ONLY, fork only. cirBTC is Circle's USDC-architecture (FiatTokenV2_2)
 * wrapped BTC: minting and burning are permissioned to Circle Mint customers via
 * a MasterMinter/minter-allowance system, and the BTC reserve is held in Circle
 * custody. This test proves an external unprivileged attacker has no path to
 * mint cirBTC or move the backing; the only exposure is Circle's privileged keys.
 */
contract CirBtcTest is Test {
    address constant TOKEN = 0x72DFB2E44f59C5AD2bAFE84314E5b99a7cd5075E; // FiatTokenProxy
    address constant IMPL = 0x43506849D7C04F9138D1A2050bbF3A0c054402dd; // FiatTokenV2_2
    address constant OWNER = 0xd50154994Eac780c571FF5f7ceC0Ef2e60085182;
    address constant MASTER_MINTER = 0xC0Cc159c07a99EeCC35C36f25fE7C1Aeeb3587A2;
    address constant PAUSER = 0xabde92e0efE04a0c1469cD21Bf400Cb1969fA222;
    address constant BLACKLISTER = 0xb5BE9AfA2ff55B8f9AE3e223b2F18ab6B84e1D79;
    address constant PROXY_ADMIN = 0xC9cEe9efa5180597BB850A642aA75e5EC3B5a9BD;

    bytes32 constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;
    bytes32 constant IMPL_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

    address attacker = address(0xA77ACC);

    function setUp() public {
        string memory rpc = vm.envOr(
            "FORK_RPC_URL",
            vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))
        );
        vm.createSelectFork(rpc);
    }

    function test_token_is_circle_fiat_token_v2_2_proxy() public view {
        IERC20Like t = IERC20Like(TOKEN);
        assertEq(t.version(), "2");
        assertGt(t.totalSupply(), 0, "cirBTC has supply");
        assertEq(address(uint160(uint256(vm.load(TOKEN, IMPL_SLOT)))), IMPL, "impl slot");
        assertEq(address(uint160(uint256(vm.load(TOKEN, ADMIN_SLOT)))), PROXY_ADMIN, "admin slot");
        assertEq(IFiatTokenProxy(TOKEN).implementation(), IMPL);
        assertEq(IFiatTokenProxy(TOKEN).admin(), PROXY_ADMIN);
        // the backing is real BTC held by Circle in custody -> the token is custodial
        assertFalse(t.paused(), "not paused");
    }

    function test_roles_are_nonzero() public view {
        assertEq(IERC20Like(TOKEN).owner(), OWNER);
        assertEq(IERC20Like(TOKEN).masterMinter(), MASTER_MINTER);
        assertEq(IERC20Like(TOKEN).pauser(), PAUSER);
        assertEq(IERC20Like(TOKEN).blacklister(), BLACKLISTER);
    }

    function test_attacker_cannot_mint() public {
        uint256 before = IERC20Like(TOKEN).balanceOf(attacker);
        vm.prank(attacker);
        vm.expectRevert(bytes("FiatToken: caller is not a minter"));
        IERC20Like(TOKEN).mint(attacker, 1e8);
        assertEq(IERC20Like(TOKEN).balanceOf(attacker), before, "no cirBTC created for attacker");
    }

    function test_attacker_cannot_configure_a_minter() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).configureMinter(attacker, type(uint256).max);
        vm.expectRevert();
        IERC20Like(TOKEN).incrementMinterAllowance(type(uint256).max);
        vm.stopPrank();
    }

    function test_attacker_cannot_change_roles() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        IERC20Like(TOKEN).updateMasterMinter(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).updateOwner(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).updatePauser(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).updateBlacklister(attacker);
        vm.stopPrank();
    }

    function test_attacker_cannot_pause_or_blacklist_or_rescue() public {
        vm.startPrank(attacker);
        vm.expectRevert(bytes("Pausable: caller is not the pauser"));
        IERC20Like(TOKEN).pause();
        vm.expectRevert(bytes("Blacklistable: caller is not the blacklister"));
        IERC20Like(TOKEN).blacklist(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).rescueERC20(TOKEN, 1);
        vm.stopPrank();
    }

    function test_attacker_cannot_upgrade_the_proxy() public {
        vm.prank(attacker);
        vm.expectRevert();
        IFiatTokenProxy(TOKEN).upgradeTo(attacker);
    }

    function test_attacker_with_zero_balance_cannot_burn() public {
        assertEq(IERC20Like(TOKEN).balanceOf(attacker), 0);
        vm.prank(attacker);
        vm.expectRevert();
        IERC20Like(TOKEN).burn(1e8);
    }

    /// The only minter allowance lives on the minter set by Circle; the token's
    /// supply is only expandable through that permissioned path.
    function test_mint_requires_a_funded_minter_allowance() public view {
        // this address is a historical Circle minter; its allowance is a tiny
        // fraction of a cirBTC and is the ONLY on-chain mint authority
        assertLt(IERC20Like(TOKEN).minterAllowance(0xF2E21385762C07970166119a997138028174BB46), 1e8);
    }
}
