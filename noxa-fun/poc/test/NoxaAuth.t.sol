// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface ILaunchLocker {
    error NotAuthorized();
    error NotDeployer();
    error NotFactory();
    function owner() external view returns (address);
    function factory() external view returns (address);
    function protocolFeeShare() external view returns (uint256);
    function protocolFeeRecipient() external view returns (address);
    function feeCollectors(address) external view returns (bool);
    function feeRedirects(address) external view returns (address);
    function collectFees(address token) external;
    function setFeeRedirect(address token, address recipient) external;
    function lockPosition(address token) external;
    function setFeeCollector(address collector, bool status) external;
}

interface IUniV3NPM {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @notice Read-only fork proof for NOXA Fun LaunchLocker on Robinhood Chain (4663).
///         Pinned to block 92,977,747 (2026-10-19). No mainnet transactions.
contract NoxaAuthTest is Test {
    address constant LOCKER = 0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85;
    address constant FACTORY = 0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB;
    address constant NPM = 0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3;
    address constant TOKEN = 0x77Bd112a399F833F76cad118a74b7Fcc8108Dcc2; // real launched token
    address constant FEE_COLLECTOR = 0x9eFdC1A8e6E94f16A228e44f3025E1f346EE0417; // only registered collector
    address constant ATTACKER = address(0x1111111111111111111111111111111111111111);

    function setUp() public {
        string memory rpc = vm.envOr("RH_RPC_URL", string("https://rpc.mainnet.chain.robinhood.com"));
        vm.createSelectFork(rpc);
        emit log_named_uint("fork block", block.number);
        emit log_named_uint("chain id", block.chainid);
        assertEq(block.chainid, 4663);
        assertEq(LOCKER.code.length, 4823);
    }

    function test_locker_state() public view {
        assertEq(ILaunchLocker(LOCKER).factory(), FACTORY);
        assertEq(ILaunchLocker(LOCKER).protocolFeeShare(), 100);
        assertEq(ILaunchLocker(LOCKER).protocolFeeRecipient(), FEE_COLLECTOR);
        assertTrue(ILaunchLocker(LOCKER).feeCollectors(FEE_COLLECTOR));
        assertFalse(ILaunchLocker(LOCKER).feeCollectors(ATTACKER));
        // 60,142 locked UniV3 position NFTs; sampled token 0x77bd is one of them.
        assertGe(IUniV3NPM(NPM).balanceOf(LOCKER), 60_000);
        assertEq(IUniV3NPM(NPM).ownerOf(212), LOCKER); // positionId of 0x77bd...
        assertEq(IUniV3NPM(NPM).getApproved(212), address(0));
    }

    function test_collectFees_random_reverts() public {
        vm.prank(ATTACKER);
        vm.expectRevert(ILaunchLocker.NotAuthorized.selector);
        ILaunchLocker(LOCKER).collectFees(TOKEN);
    }

    function test_setFeeRedirect_random_reverts() public {
        vm.prank(ATTACKER);
        vm.expectRevert(ILaunchLocker.NotDeployer.selector);
        ILaunchLocker(LOCKER).setFeeRedirect(TOKEN, ATTACKER);
    }

    function test_lockPosition_random_reverts() public {
        vm.prank(ATTACKER);
        vm.expectRevert(ILaunchLocker.NotFactory.selector);
        ILaunchLocker(LOCKER).lockPosition(TOKEN);
    }

    function test_setFeeCollector_random_reverts() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        ILaunchLocker(LOCKER).setFeeCollector(ATTACKER, true);
    }

    function test_nft_cannot_be_transferred_by_attacker() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        IUniV3NPM(NPM).transferFrom(LOCKER, ATTACKER, 212);
    }
}
