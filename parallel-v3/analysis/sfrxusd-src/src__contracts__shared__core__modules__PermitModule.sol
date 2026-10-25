pragma solidity ^0.8.0;

import { SignatureModule } from "./SignatureModule.sol";

/// @dev Ripped from OZ 4.9.4 ERC20Permit.sol with namespaced storage and support of ERC1271 signatures
abstract contract PermitModule is SignatureModule {
    //==============================================================================
    // Storage
    //==============================================================================

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    //==============================================================================
    // Functions
    //==============================================================================

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        permit({
            owner: owner,
            spender: spender,
            value: value,
            deadline: deadline,
            signature: abi.encodePacked(r, s, v)
        });
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) public virtual {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        _requireIsValidSignatureNow({
            signer: owner,
            structHash: keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, __useNonce(owner), deadline)),
            signature: signature
        });

        __approve(owner, spender, value);
    }

    //==============================================================================
    // Virtual methods to override in child class
    //==============================================================================

    function __approve(address owner, address spender, uint256 amount) internal virtual;

    function __domainSeparatorV4() internal view virtual returns (bytes32);

    function __useNonce(address owner) internal virtual returns (uint256);
}
