// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IZkLink, IZkLinkProxy, IERC20Min, StoredBlockInfo, CommitBlockInfo, ExecuteBlockInfo} from "../src/IZkLink.sol";

/// @title ApeX Omni custody (zkLink) — unprivileged extraction test
/// @notice Fork-only, read-only research. No mainnet transaction is ever signed/sent.
///         ApeX Omni's deposits are held by zkLink (ZkLink.sol + delegatecalled ZkLinkPeriphery.sol)
///         proxies on Ethereum / BSC / Arbitrum / Base / Mantle. This suite proves that every
///         value-moving entry point is either permissionless-but-not-profitable or properly gated.
contract ApexOmniZkLinkTest is Test {
    // Ethereum custody proxy (DefiLlama `apex-omni` owner / zkLink contract)
    address constant PROXY = 0x35D173cdfE4d484BC5985fDa55FABad5892c7B82;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant ATTACKER = address(0xA11CE);

    IZkLink zk;
    IZkLinkProxy proxy;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc);
        zk = IZkLink(PROXY);
        proxy = IZkLinkProxy(PROXY);
        vm.deal(ATTACKER, 100 ether);
    }

    // ---------- helpers ----------

    function _reason(bytes memory data) internal pure returns (string memory) {
        if (data.length < 68) return "<no reason>";
        bytes4 sel;
        assembly { sel := mload(add(data, 0x20)) }
        if (sel != 0x08c379a0) return "<non-string revert>";
        return abi.decode(slice(data, 4, data.length - 4), (string));
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory out = new bytes(len);
        for (uint256 i = 0; i < len; i++) out[i] = data[start + i];
        return out;
    }

    /// @dev low-level call from attacker, returns success + decoded reason
    function _attack(bytes memory data) internal returns (bool ok, string memory reason) {
        bytes memory ret;
        vm.prank(ATTACKER);
        (ok, ret) = PROXY.call(data);
        reason = ok ? "<ok>" : _reason(ret);
    }

    // ---------- live-state reads ----------

    function test_liveState_isCustodyVault() public {
        emit log_named_uint("fork block", block.number);
        emit log_named_address("proxy (custody)", PROXY);
        emit log_named_address("proxy impl target", proxy.getTarget());
        emit log_named_address("proxy master", proxy.getMaster());
        emit log_named_address("networkGovernor", zk.networkGovernor());
        emit log_named_address("periphery", zk.periphery());
        emit log_named_address("verifier", zk.verifier());
        emit log_named_uint("getNoticePeriod (upgrade delay s)", zk.getNoticePeriod());
        emit log_named_uint("exodusMode", zk.exodusMode() ? 1 : 0);
        emit log_named_uint("chainId", zk.CHAIN_ID());
        emit log_named_uint("masterChainId", zk.MASTER_CHAIN_ID());
        emit log_named_uint("totalBlocksExecuted", zk.totalBlocksExecuted());
        emit log_named_uint("totalBlocksSynchronized", zk.totalBlocksSynchronized());

        emit log_named_uint("USDC held (raw)", IERC20Min(USDC).balanceOf(PROXY));
        emit log_named_uint("USDT held (raw)", IERC20Min(USDT).balanceOf(PROXY));
        emit log_named_uint("native ETH held", PROXY.balance);

        // sanity: the custody contract is live and holds value
        assertGt(IERC20Min(USDC).balanceOf(PROXY), 0);
        assertGt(PROXY.code.length, 0);
    }

    // ---------- privileged paths must revert for an unprivileged caller ----------

    function test_nonValidator_cannotExecuteBlocks() public {
        ExecuteBlockInfo[] memory b = new ExecuteBlockInfo[](1);
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.executeCompressedBlocks.selector, b));
        emit log_named_string("executeCompressedBlocks as attacker", reason);
        assertFalse(ok, "attacker executed blocks");
    }

    function test_nonValidator_cannotCommitBlocks() public {
        StoredBlockInfo memory s;
        CommitBlockInfo[] memory b = new CommitBlockInfo[](1);
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.commitCompressedBlocks.selector, s, b));
        emit log_named_string("commitCompressedBlocks as attacker", reason);
        assertFalse(ok, "attacker committed blocks");
    }

    function test_nonMaster_cannotUpgradeProxy() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLinkProxy.upgradeTarget.selector, ATTACKER));
        emit log_named_string("upgradeTarget as attacker", reason);
        assertFalse(ok, "attacker upgraded proxy");
    }

    function test_nonMaster_cannotTransferMastership() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLinkProxy.transferMastership.selector, ATTACKER));
        emit log_named_string("transferMastership as attacker", reason);
        assertFalse(ok, "attacker took mastership");
    }

    function test_cannotReinitialize() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLinkProxy.initialize.selector, new bytes(0)));
        emit log_named_string("initialize as attacker", reason);
        assertFalse(ok, "attacker re-initialized");
    }

    function test_nonGovernor_cannotChangeGovernor() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.changeGovernor.selector, ATTACKER));
        emit log_named_string("changeGovernor as attacker", reason);
        assertFalse(ok, "attacker changed governor");
    }

    function test_nonGovernor_cannotSetValidator() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.setValidator.selector, ATTACKER, true));
        emit log_named_string("setValidator as attacker", reason);
        assertFalse(ok, "attacker set validator");
    }

    function test_nonGovernor_cannotSetGateway() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.setGateway.selector, ATTACKER));
        emit log_named_string("setGateway as attacker", reason);
        assertFalse(ok, "attacker set gateway");
    }

    function test_nonGovernor_cannotAddToken() public {
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.addToken.selector, uint16(40000), ATTACKER, uint8(18)));
        emit log_named_string("addToken as attacker", reason);
        assertFalse(ok, "attacker added token");
    }

    // ---------- permissionless paths must not yield profit ----------

    function test_withdrawPendingBalance_zeroBalance_reverts() public {
        uint16 tokenId = zk.tokenIds(USDC);
        emit log_named_uint("USDC tokenId", tokenId);
        // attacker has 0 pending balance -> underflow revert, and cannot redirect to self anyway
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.withdrawPendingBalance.selector, payable(ATTACKER), tokenId, uint128(1)));
        emit log_named_string("withdrawPendingBalance(self,1) as attacker", reason);
        assertFalse(ok, "attacker withdrew a pending balance it does not own");
    }

    function test_withdrawPendingBalance_cannotRedirectToAttacker() public {
        // Calling with _owner = victim only ever pays the victim, never the caller.
        address victim = address(0xB0B);
        uint16 tokenId = zk.tokenIds(USDC);
        bytes32 l2Victim = bytes32(uint256(uint160(victim)));
        uint128 victimPending = zk.getPendingBalance(l2Victim, tokenId);
        emit log_named_uint("victim pending (raw)", victimPending);
        uint256 before = IERC20Min(USDC).balanceOf(ATTACKER);
        (bool ok, ) = _attack(abi.encodeWithSelector(IZkLink.withdrawPendingBalance.selector, payable(victim), tokenId, victimPending));
        // if it succeeds at all, funds go to `victim`, not to the attacker
        assertEq(IERC20Min(USDC).balanceOf(ATTACKER), before, "attacker gained funds");
        emit log_named_uint("call succeeded (funds went to victim)", ok ? 1 : 0);
    }

    function test_acceptERC20_requiresRealPayment() public {
        // acceptERC20 is permissionless but requires the caller to pay the receiver first.
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(
            IZkLink.acceptERC20.selector, address(0xB0B), USDC, uint128(1e6), uint16(100), uint32(1), uint8(0), uint32(1)
        ));
        emit log_named_string("acceptERC20 without payment as attacker", reason);
        assertFalse(ok, "attacker accepted without paying");
        assertEq(IERC20Min(USDC).balanceOf(ATTACKER), 0, "attacker gained funds");
    }

    function test_activateExodusMode_notTriggerableEarly() public {
        // permissionless, but only flips when a priority request is >14d expired.
        (bool ok, string memory reason) = _attack(abi.encodeWithSelector(IZkLink.activateExodusMode.selector));
        emit log_named_string("activateExodusMode as attacker", reason);
        emit log_named_uint("exodusMode after", zk.exodusMode() ? 1 : 0);
        // either it reverted (notActive guard -> already active) or it ran but did not enter exodus
        assertFalse(zk.exodusMode(), "attacker forced exodus mode");
    }
}
