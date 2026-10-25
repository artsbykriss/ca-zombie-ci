// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

import {FHE} from "../lib/FHE.sol";
import {FHEConfig} from "../lib/Impl.sol";

contract PrimusConfigBase {
    /// @notice Thrown when the contract is deployed on a chain that is not explicitly supported.
    error UnsupportedChain(uint256 chainId);

    /// @notice Thrown when a configured FHE address is zero or has no deployed code.
    error InvalidFHEConfigAddress(address account);

    /// @notice Sets the FHE config addresses automatically based on the chain ID.
    function _setupFHEConfig() internal {
        FHEConfig memory cfg;

        if (block.chainid == 56) {
            // The BNB Smart Chain Mainnet. ChainID: 56 (0x38).
            cfg = FHEConfig({ACLAddress: 0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE, FHEExecutorAddress: 0x12964221F412e3e52F5f0C9592781904266dd9B4});
        } else if (block.chainid == 97) {
            // The BNB Smart Chain Testnet. ChainID: 97 (0x61).
            cfg = FHEConfig({ACLAddress: 0x73d8e6Aa72DFD64ADcdF388411A6EE3F3CFa98B5, FHEExecutorAddress: 0xfA1f2CF8B46BA9D0FCa7b6AD484dc69E4A0E1ceb});
        } else if (block.chainid == 133) {
            // The Hashkey Testnet. ChainID: 133 (0x85).
            cfg = FHEConfig({ACLAddress: 0x4303B7c7567D0827e49fA3886a2c583dFfC0e638, FHEExecutorAddress: 0xA34Afb3FE2735aBcf9eA7964f22B7539f015d3fd});
        } else if (block.chainid == 177) {
            // The Hashkey Mainnet. ChainID: 177 (0xB1).
            cfg = FHEConfig({ACLAddress: 0x40CEB2Ad777F57Ca25785484AF5E86333B1BA0C3, FHEExecutorAddress: 0xc7a72196683BBEd91c118fA10540ed30EACB8F5b});
        } else if (block.chainid == 84532) {
            // The Base Sepolia Testnet. ChainID: 84532(0x14a34).
            cfg = FHEConfig({ACLAddress: 0x189FD84E376c33c6D39396C6E698263848cC6C03, FHEExecutorAddress: 0x22dcF054a14C81953f2De037C28Bcff871D095eD});
        } else if (block.chainid == 11155111) {
            // The Ethereum Sepolia. ChainID: 11155111(0xaa36a7).
            cfg = FHEConfig({ACLAddress: 0x637e5657c43CC800A969Ff9c903409ce9abDd43D, FHEExecutorAddress: 0xEbd4fc2914Ca6c4ab00ae6dD09411aE576C14355});
        } else if (block.chainid == 31337) {
            // Anvil/Hardhat local chain. ChainID: 31337 (0x7a69).
            cfg = FHEConfig({ACLAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, FHEExecutorAddress: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9});
        } else {
            revert UnsupportedChain(block.chainid);
        }

        _verifyFHEConfig(cfg);
        FHE.setFHEConfig(cfg);
    }

    /// @notice Verifies that the configured ACL and FHE executor addresses are non-zero
    ///         and contain deployed contract code.
    function _verifyFHEConfig(FHEConfig memory cfg) internal view {
        if (cfg.ACLAddress == address(0) || cfg.ACLAddress.code.length == 0) {
            revert InvalidFHEConfigAddress(cfg.ACLAddress);
        }
        if (cfg.FHEExecutorAddress == address(0) || cfg.FHEExecutorAddress.code.length == 0) {
            revert InvalidFHEConfigAddress(cfg.FHEExecutorAddress);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier chargeFee() {
        FHE.chargeFee(msg.sender, msg.value);
        _;
    }
    modifier chargeFeeWith(address user, uint256 amount) {
        FHE.chargeFee(user, amount);
        _;
    }
}
