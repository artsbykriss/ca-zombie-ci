// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20Permit } from "../interfaces/telecoin/IERC20Permit.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
 * @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
 */
contract ERC20 is IERC20Permit, IERC20Metadata, IERC20Errors {

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the ERC20 token with metadata and EIP-2612 permit functionality
     * @dev Sets up the token name, symbol, decimals and initializes EIP-712 domain separator for permit signatures
     * @param _name The human-readable name of the token (e.g. "My Token")
     * @param _symbol The token symbol used on exchanges (e.g. "MTK")
     * @param _decimals Number of decimal places for token amounts (typically 18 for most ERC20 tokens)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Approves another account to spend tokens on behalf of the caller
     * @dev Implements the standard ERC20 approve function with unlimited allowance support
     * @param spender The address that will be allowed to spend the tokens
     * @param value The amount of tokens to approve for spending (in token's decimal units)
     * @return Always returns true to indicate successful approval
     */
    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @notice Transfers tokens from the caller to another address
     * @dev Uses internal _update function to handle balance changes and emit Transfer event
     * @param to The recipient address to transfer tokens to
     * @param value The amount of tokens to transfer (in token's decimal units)
     * @return Always returns true to indicate successful transfer
     */
    function transfer(
        address to,
        uint256 value
    ) public virtual returns (bool) {
        _update(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another using allowance mechanism
     * @dev Checks and updates allowance before transferring. Unlimited allowance (type(uint256).max) is not
     * decremented
     * @param from The address to transfer tokens from (must have sufficient balance)
     * @param to The recipient address to transfer tokens to
     * @param value The amount of tokens to transfer (in token's decimal units)
     * @return Always returns true to indicate successful transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        address spender = msg.sender;
        uint256 allowed = allowance[from][spender];

        if (allowed != type(uint256).max) {
            if (allowed < value) {
                revert ERC20InsufficientAllowance(spender, allowed, value);
            }
            allowance[from][spender] = allowed - value;
        }

        _update(from, to, value);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Permits an allowance to be set via signature, implementing EIP-2612
     * @dev Validates the signature against EIP-712 typed data and sets allowance without requiring a transaction from
     * owner
     * @param owner The address that owns the tokens and is granting the allowance
     * @param spender The address that will be allowed to spend the tokens
     * @param value The amount of tokens to approve for spending (in token's decimal units)
     * @param deadline The timestamp after which the permit signature is no longer valid
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (deadline < block.timestamp) {
            revert ERC2612ExpiredSignature(deadline);
        }

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 structHash =
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));

            bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

            address recoveredAddress = ecrecover(hash, v, r, s);

            if (recoveredAddress == address(0) || recoveredAddress != owner) {
                revert ERC2612InvalidSigner(recoveredAddress, owner);
            }

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /**
     * @notice Invalidates the current nonce for msg.sender
     * @dev Increments the nonce, making all outstanding permit signatures invalid
     * This provides users with an emergency mechanism to cancel pending permits in case of:
     * - Key compromise or suspected phishing
     * - Changed mind about a signed but not executed permit
     * - Need to invalidate multiple permits at once
     * Emits a NonceInvalidated event
     */
    function invalidateNonce() external {
        unchecked {
            emit NonceInvalidated(msg.sender, ++nonces[msg.sender]);
        }
    }

    /**
     * @notice Returns the domain separator for EIP-712 signature validation
     * @dev Returns cached separator if chain ID hasn't changed, otherwise recomputes it
     * @return The EIP-712 domain separator hash for this contract and chain
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    /**
     * @notice Computes the EIP-712 domain separator for the current chain and contract
     * @dev Used for EIP-712 signature validation in permit functions
     * @return The computed domain separator hash including contract name, version, chain ID, and address
     */
    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL UPDATE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to handle token transfers, mints, and burns
     * @dev Handles balance updates and total supply changes. Emits Transfer event for all operations
     * @param from The address to transfer from (address(0) for minting)
     * @param to The address to transfer to (address(0) for burning)
     * @param value The amount of tokens to transfer/mint/burn (in token's decimal units)
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (from == address(0)) {
            // Increase total supply
            totalSupply += value;
        } else {
            // Transfer - decrease from balance
            uint256 fromBalance = balanceOf[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                balanceOf[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            // Decrease total supply
            unchecked {
                totalSupply -= value;
            }
        } else {
            // Transfer or mint - increase to balance
            unchecked {
                balanceOf[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

}
