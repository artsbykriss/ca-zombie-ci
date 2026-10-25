pragma solidity ^0.8.21;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
//=========================== StakedFrxUSD3 ===========================
// ====================================================================

import { IERC20 } from "@openzeppelin/contracts-5.3.0/token/ERC20/IERC20.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { SfrxUSD2 } from "src/contracts/ethereum/sfrxUSD/versioning/SfrxUSD2.sol";
import { EIP3009Module, SignatureModule } from "src/contracts/shared/core/modules/EIP3009Module.sol";
import { PermitModule } from "src/contracts/shared/core/modules/PermitModule.sol";

/**
 * @title StakedFrxUSD3
 * @notice This contract is an upgrade of SfrxUSD2 with EIP-3009, ERC-1271.
 */
contract SfrxUSD3 is SfrxUSD2, EIP3009Module, PermitModule {
    function version() public pure override returns (string memory) {
        return "3.0.0";
    }

    constructor(address _underlying) SfrxUSD2(IERC20(_underlying), "Staked Frax USD", "sfrxUSD", address(0)) {}

    /*//////////////////////////////////////////////////////////////
                        Module Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev PermitModule override
    /// @dev solmate ERC20 does not have _approve like OZ: so we create it here
    function __approve(address owner, address spender, uint256 amount) internal override {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function __transfer(address from, address to, uint256 amount) internal override returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function __domainSeparatorV4() internal view override(PermitModule) returns (bytes32) {
        return DOMAIN_SEPARATOR();
    }

    function __hashTypedDataV4(bytes32 structHash) internal view override(SignatureModule) returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
    }

    function __useNonce(address owner) internal override(PermitModule) returns (uint256) {
        return nonces[owner]++;
    }

    /// @dev Use PermitModule permit() with ERC-1271 support
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override(ERC20, PermitModule) {
        return
            PermitModule.permit({ owner: owner, spender: spender, value: value, deadline: deadline, v: v, r: r, s: s });
    }

    /// @dev override DOMAIN_SEPARATOR() to utilize the proxy address over the cached implementation address
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return computeDomainSeparator();
    }
}
