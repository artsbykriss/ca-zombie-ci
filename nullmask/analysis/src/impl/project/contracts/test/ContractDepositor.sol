// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ContractDepositor
 * @notice Test wallet contract that forwards arbitrary calls (so it can deposit into the
 *         pool on behalf of a recipient) and whose handling of incoming ETH is switchable:
 *         refuse it, accept it, burn more gas than a stipend carries, or accept it and
 *         answer with 64 KiB of returndata (affordable within a 30k stipend, expensive for
 *         a caller that copies it).
 * @dev Not for production.
 */
contract ContractDepositor {
    enum EthMode { REFUSE, ACCEPT, BURN_GAS, RETURN_BIG }

    EthMode public ethMode;
    uint256 private _sink;

    function setEthMode(EthMode mode) external {
        ethMode = mode;
    }

    /// @notice Forward a call with value, bubbling any revert.
    function exec(address target, bytes calldata data) external payable returns (bytes memory ret) {
        bool ok;
        (ok, ret) = target.call{value: msg.value}(data);
        if (!ok) {
            assembly {
                revert(add(ret, 32), mload(ret))
            }
        }
    }

    receive() external payable {
        if (ethMode == EthMode.REFUSE) revert("no ETH");
        if (ethMode == EthMode.RETURN_BIG) {
            assembly {
                return(0, 65536)
            }
        }
        if (ethMode == EthMode.BURN_GAS) {
            // Several cold SSTOREs: well past a 30k stipend
            for (uint256 i = 1; i <= 5; i++) {
                _sink = uint256(keccak256(abi.encode(_sink, i)));
                assembly {
                    sstore(add(0x1000, i), i)
                }
            }
        }
    }
}
