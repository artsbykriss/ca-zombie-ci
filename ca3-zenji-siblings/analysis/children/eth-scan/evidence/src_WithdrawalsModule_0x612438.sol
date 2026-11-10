
// ===== @openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// ===== @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// ===== @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ===== @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// ===== @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// ===== @openzeppelin/contracts/token/ERC20/IERC20.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ===== contracts/infiniteProxy/IProxy.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);
}

// ===== contracts/vault/common/interfaces.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IWeEth {
    function getEETHByWeETH(
        uint256 _weETHAmount
    ) external view returns (uint256);

    function getWeETHByeETH(
        uint256 _eETHAmount
    ) external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}
interface ILidoWithdrawalQueue {
    // code below from Lido WithdrawalQueueBase.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueueBase.sol

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    /// @notice length of the checkpoints. Last possible value for the claim hint
    function getLastCheckpointIndex() external view returns (uint256);

    // code below from Lido WithdrawalQueue.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueue.sol

    /// @notice Request the sequence of stETH withdrawals according to passed `withdrawalRequestInputs` data
    /// @param amounts an array of stETH amount values. The standalone withdrawal request will
    ///  be created for each item in the passed list.
    /// @param _owner address that will be able to transfer or claim the request.
    ///  If `owner` is set to `address(0)`, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal requests
    function requestWithdrawals(
        uint256[] calldata amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @notice Claim a batch of withdrawal requests once finalized (claimable) sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id.
    ///   Can be retrieved with `findCheckpointHints()`
    /// @dev
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /// @notice Returns all withdrawal requests that belongs to the `_owner` address
    ///
    /// WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`. NB! Array of request ids should be sorted
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range
    /// @param _lastIndex right boundary of the search range
    /// @return hintIds the hints for `claimWithdrawal` to find the checkpoint for the passed request ids
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);

    /// @notice Returns statuses for the array of request ids
    /// @param _requestIds array of withdrawal request ids
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    function balanceOf(address) external view returns (uint);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IWeth {
    function deposit() external payable;

    function transfer(address dst, uint wad) external returns (bool);
}

interface IFluidVaultT1 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );

    function operate(
        uint256 nftId_, // if 0 then new position
        int256 newCol_, // if negative then withdraw
        int256 newDebt_, // if negative then payback
        address to_ // address at which the borrow & withdraw amount should go to. If address(0) then it'll go to msg.sender
    )
        external
        payable
        returns (
            uint256, // nftId_
            int256, // final supply amount. if - then withdraw
            int256 // final borrow amount. if - then payback
        );
}

interface IFluidVaultT4 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );
}

interface IFluidDexT1 {
    function getRatio() external view returns (uint256 ratio_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    struct Implementations {
        address shift;
        address admin;
        address colOperations;
        address debtOperations;
        address perfectOperationsAndOracle;
    }

    struct ConstantViews {
        uint256 dexId;
        address liquidity;
        address factory;
        Implementations implementations;
        address deployerContract;
        address token0;
        address token1;
        bytes32 supplyToken0Slot;
        bytes32 borrowToken0Slot;
        bytes32 supplyToken1Slot;
        bytes32 borrowToken1Slot;
        bytes32 exchangePriceToken0Slot;
        bytes32 exchangePriceToken1Slot;
        uint256 oracleMapping;
    }

    function constantsView()
        external
        view
        returns (ConstantViews memory constantsView_);
}

interface ILiquidity {
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
}

// ===== contracts/vault/common/variables.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces.sol";
import "../../infiniteProxy/IProxy.sol";

/// @title      Variables
/// @notice     Contains common storage variables of all modules of Infinite proxy.
contract ConstantVariables {
    address internal constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant RAY_MINUS_ONE = RAY - 1;
    uint256 internal constant MAX_UINT256_MINUS_RAY_MINUS_ONE =
        MAX_UINT256 - RAY_MINUS_ONE;

    IInstaIndex internal constant INSTA_INDEX_CONTRACT =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDRESS);
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDRESS);
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;
    address internal constant SP_WSTETH_ADDRESS_SPARK =
        0x12B54025C112Aa61fAce2CDB7118740875A566E9;
    address internal constant A_WSTETH_ADDRESS_AAVEV3_LIDO =
        0xC035a7cf15375cE2706766804551791aD035E0C2;

    /***********************************|
    |           EETH ADDRESSES        |
    |__________________________________*/
    address internal constant EETH_ADDRESS =
        0x35fA164735182de50811E8e2E824cFb9B6118ac2;

    /***********************************|
    |           WeETH ADDRESSES        |
    |__________________________________*/
    address internal constant WEETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    IWeEth internal constant WEETH_CONTRACT = IWeEth(WEETH_ADDRESS);
    address internal constant A_WEETH_ADDRESS_AAVEV3 =
        0xBdfa7b7893081B35Fb54027489e2Bc7A38275129;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant D_WETH_ADDRESS_SPARK =
        0x2e7576042566f8D6990e07A1B61Ad1efd86Ae70d;
    address internal constant D_WETH_ADDRESS_AAVEV3_LIDO =
        0x91b7d78BF92db564221f6B5AeE744D1727d1Dd1e;

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    address internal constant KING_ADDRESS =
        0x8F08B70456eb22f6109F57b8fafE862ED28E6040;

    ILiteVaultV1 internal constant LITE_VAULT_V1 = ILiteVaultV1(IETH_TOKEN_V1);

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    ILidoWithdrawalQueue internal constant LIDO_WITHDRAWAL_QUEUE =
        ILidoWithdrawalQueue(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

    ILiquidity internal constant LIQUIDITY =
        ILiquidity(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);

    IFluidVaultT1 internal constant FLUID_VAULT =
        IFluidVaultT1(FLUID_VAULT_ADDRESS);

    IFluidVaultT1 internal constant FLUID_VAULT_NEW =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_NEW);

    IFluidVaultT1 internal constant FLUID_VAULT_WEETH_WSTETH =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_WEETH_WSTETH);

    address internal constant FLUID_VAULT_ADDRESS =
        0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91;

    address internal constant FLUID_VAULT_ADDRESS_NEW =
        0x82B27fA821419F5689381b565a8B0786aA2548De;

    address internal constant FLUID_VAULT_ADDRESS_WEETH_WSTETH =
        0xeAEf563015634a9d0EE6CF1357A3b205C35e028D;

    uint256 internal constant FLUID_NFT_ID_NEW = 1566;

    uint256 internal constant FLUID_NFT_WEETH_WSTETH = 6486;

    address internal constant FLUID_DEX_ADDRESS =
        address(0x0B1a513ee24972DAEf112bC777a5610d4325C9e7);

    IFluidDexT1 internal constant FLUID_DEX = IFluidDexT1(FLUID_DEX_ADDRESS);

    address internal constant FLUID_DEX_VAULT_ADDRESS =
        0x528CF7DBBff878e02e48E83De5097F8071af768D;

    IFluidVaultT4 internal constant FLUID_VAULT_T4 =
        IFluidVaultT4(FLUID_DEX_VAULT_ADDRESS);

    uint256 internal constant X8 = 0xff;

    uint256 internal constant X19 = 0x7ffff;

    uint256 internal constant X64 = 0xffffffffffffffff;

    uint256 internal constant X128 = 0xffffffffffffffffffffffffffffffff;
}

contract Variables is ConstantVariables {
    /****************************************************************************|
    |   @notice Ids associated with protocols at the time of deployment.         |
    |   New protocols might have been added or removed at the time of viewing.   |
    |                          AAVE_V2 => 1 // Disabled                          |
    |                          AAVE_V3 => 2                                      |
    |                          COMPOUND_V3 => 3                                  |
    |                          EULER => 4 // Disabled                            |
    |                          MORPHO_AAVE_V2 => 5 // Disabled                   |
    |                          MORPHO_AAVE_V3 => 6 // Disabled                   |
    |                          SPARK => 7                                        |
    |                          FLUID => 8 // Disabled                            |
    |                          FLUID_NEW => 9                                    |
    |                          AAVE V3 LIDO => 10                                |
    |                          FLUID_DEX => 11                                   |
    |                          FLUID_WEETH_WSTETH => 12                          |
    |___________________________________________________________________________*/

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    // 1: open; 2: closed
    uint8 internal _status;

    IDSA public vaultDSA;

    /// @notice Max limit (in wei) allowed for wsteth per eth unit amount.
    uint256 public leverageMaxUnitAmountLimit;

    /// @notice Secondary auth that only has the power to reduce max risk ratio.
    address public secondaryAuth;

    // Current exchange price.
    uint256 public exchangePrice;

    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public revenueExchangePrice;

    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;

    // Mapping of protocol id => max risk ratio, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    // 1 = Aave v2 // Disabled
    // 2 = Aave v3
    // 3 = Compound v3 (ETH market)
    // 4 = Euler // Disabled
    // 5 = Morpho Aave v2 // Disabled
    // 6 = Morpho Aave v3 // Disabled
    // 7 = Spark
    // 8 = Fluid // Disabled
    // 9 = Fluid New
    // 10 = Aave V3 Lido
    // 11 = Fluid Dex
    // 12 = Fluid WeETH WstETH
    mapping(uint8 => uint256) public maxRiskRatio;

    // Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    uint256 public aggrMaxVaultRatio;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    uint256 public withdrawalFeePercentage;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    uint256 public withdrawFeeAbsoluteMin; // in underlying base asset, i.e. stEth

    // charge from the profits, scaled to factor 4.
    // 100,000 would be 10% cut from profit
    uint256 public revenueFeePercentage;

    /// @notice Stores profit revenue and withdrawal fees collected.
    uint256 public revenue;

    /// @notice Revenue will be transffered to this address upon collection.
    address public treasury;

    /// @notice Tracker for amount of stETH queued for withdrawal.
    uint256 public queuedWithdrawStEth;

    /// @notice DSA's NFT ID for fluid vault T4.
    uint256 public fluidDexNFT;

    /// @notice allocation to team multisig - in wstETH
    uint256 public allocationToTeamMultisig;

    /// @notice max allocation to team multisig - in wstETH (for future use)
    uint256 public maxAllocationToTeamMultisig;

}

/// @title      PrimaryHelpers
/// @notice     Contains common modifiers of all modules of Infinite proxy.
contract PrimaryHelpers is Variables {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();
    error Helpers__ProtocolDisabled();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyRebalancer() {
        if (
            !(isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert Helpers__NotRebalancer();
        }
        _;
    }

    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        if (_status == 2) revert Helpers__Reentrant();
        _status = 2;
        _;
        _status = 1;
    }

    /// @notice Implements a method to read uint256 data from storage at a bytes32 storage slot key.
    function readFromStorage(
        bytes32 slot_
    ) public view returns (uint256 result_) {
        assembly {
            result_ := sload(slot_) // read value from the storage slot
        }
    }
}

// ===== contracts/vault/common/variablesBuffer.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBuffer
/// @notice     Allocates space of 151 slots to maintain storage 
///             consistency with imported variables in VariablesPrimaryHelper.

contract VariablesBuffer {
    uint[151] internal __buffergap;
}
// ===== contracts/vault/common/variablesBufferHelper.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBufferHelper
/// @notice     Buffer Helper for variables that imports all the primary 
///             helpers from the storage slot 152.

import {VariablesBuffer} from "./variablesBuffer.sol";
import {PrimaryHelpers} from "./variables.sol";

// Buffer & variables
contract VariablesBufferHelper is VariablesBuffer, PrimaryHelpers {
}
// ===== contracts/vault/modules/common/interface.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsAaveV3 {
        uint256 wstETH; // supply
        uint256 weETH; // supply
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH supply converted to stETH
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsFluidWeETH {
        uint256 weETH; // supply
        uint256 wstETH; // borrow
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH borrow converted to stETH
    }

    struct ProtocolAssetsInDexWstETH {
        uint256 wstETHSupply;
        uint256 ethSupply;
        uint256 wstETHBorrow;
        uint256 stETHBorrow;
        uint256 ethBorrow;
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 eETH;
        uint256 weETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsAaveV3 aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH spark;
        ProtocolAssetsInWstETH fluidNew;
        ProtocolAssetsInWstETH aaveV3Lido;
        ProtocolAssetsInDexWstETH fluidDex;
        ProtocolAssetsFluidWeETH fluidWeETH;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    function getProtocolRatio(uint8 protocolId_) external view returns (uint256 ratio_);
    
    function getNetAssets()
        external
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        );

    function getWithdrawFee(uint256 stETHAmount_) external view returns (uint256);

    function getRatioAaveV3(
        uint256 eEthPerWeETH_,
        uint256 stEthPerWsteth_
    )
        external
        view
        returns (
            uint256 wstEthAmount_,
            uint256 weEthAmount_,
            uint256 eEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
    );

    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}
// ===== contracts/vault/modules/withdrawalsModule/events.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
    /// @notice Emitted when a Lido ETH withdrawal is queued
    event LogQueueEthWithdrawal(
        uint256 indexed stEthAmount,
        uint256 indexed requestId,
        uint256 indexed protocolId
    );

    /// @notice Emitted when debt is repaid
    event LogWethPayback(uint256 indexed amount, uint256 indexed protocolId);

    /// @notice Emitted when a Lido ETH withdrawal is claimed
    event LogClaimEthWithdrawal(
        uint256 indexed stEthAmount,
        uint256 indexed requestId,
        uint256 indexed protocolId
    );
}

// ===== contracts/vault/modules/withdrawalsModule/main.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../common/variablesBufferHelper.sol";
import "./events.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { IVault } from "../common/interface.sol";
import { ILidoWithdrawalQueue, IWeth, TokenInterface } from "../../common/interfaces.sol";

/// @title WithdrawalsModule
/// @dev Actions are executable by allowed rebalancers only
contract WithdrawalsModule is VariablesBufferHelper, Events {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /***********************************|
    |              ERRORS               |
    |__________________________________*/
  error WithdrawalsModule__VaultUnsafeAfterWithdraw();
  error WithdrawalsModule__InvalidERC721Transfer();
  error WithdrawalsModule__ERC721NotTransferred();
  error WithdrawalsModule__NoETHTransferred();

  /***********************************|
    |          WITHDRAWALS CORE         |
    |__________________________________*/

  /// @notice withdraws `stethAmount_` of stETH from protocol at `fromProtocolId_` and
  /// queues ETH withdrawal request for `stethAmount_` stETH at Lido WithdrawalQueue
  /// @dev more details in event logged by Lido contract WithdrawalQueue event "WithdrawalRequested"
  /// @param stethAmount_ amount to withdraw (Always in stETH).
  /// @param fromProtocolId_ Id of the protocol to withdraw stETH from. leverage ratio must be safe after request.
  /// Set to 0 to skip withdrawing from a protocol (recommended to do all in one tx to avoid risk of someone withdrawing)
  /// if set to 0, enough stETH to cover `stethAmount_` must already be in vault contract
  /// @return requestId_ Lido withdrawal request id
  function queueEthWithdrawal(
    uint256 stethAmount_,
    uint8 fromProtocolId_
  ) external nonReentrant onlyRebalancer returns (uint256 requestId_) {
    if (
      fromProtocolId_ == 1 || // Aave v2
      fromProtocolId_ == 4 || // Euler
      fromProtocolId_ == 5 || // Morpho Aave v2
      fromProtocolId_ == 6 || // Morpho Aave v3
      fromProtocolId_ == 8 // Fluid
    ) {
      revert Helpers__ProtocolDisabled();
    }

    uint256 nftBalanceBefore_ = LIDO_WITHDRAWAL_QUEUE.balanceOf(address(this));

    if (fromProtocolId_ > 0) {
      // Getting wstETH values for protocols supporting wstETH.
      uint256 fromWithdrawAmount_ = WSTETH_CONTRACT.getWstETHByStETH(
        stethAmount_
      );

      string[] memory targets_ = new string[](3);
      bytes[] memory calldatas_ = new bytes[](3);

      if (fromProtocolId_ == 2) {
        // wstETH based protocol
        targets_[0] = "AAVE-V3-A";
        calldatas_[0] = abi.encodeWithSignature(
          "withdraw(address,uint256,uint256,uint256)",
          WSTETH_ADDRESS,
          fromWithdrawAmount_, // stETH amount converted to wstETH.
          0,
          0
        );
      } else if (fromProtocolId_ == 3) {
        // wstETH based protocol
        targets_[0] = "COMPOUND-V3-A";
        calldatas_[0] = abi.encodeWithSignature(
          "withdraw(address,address,uint256,uint256,uint256)",
          COMP_ETH_MARKET_ADDRESS,
          WSTETH_ADDRESS,
          fromWithdrawAmount_, // stETH amount converted to wstETH.
          0,
          0
        );
      } else if (fromProtocolId_ == 7) {
        // wstETH based protocol
        targets_[0] = "SPARK-A";
        calldatas_[0] = abi.encodeWithSignature(
          "withdraw(address,uint256,uint256,uint256)",
          WSTETH_ADDRESS,
          fromWithdrawAmount_, // stETH amount converted to wstETH.
          0,
          0
        );
      } else if (fromProtocolId_ == 9) {
        // to: wstETH based protocol
        targets_[0] = "FLUID-A";
        calldatas_[0] = abi.encodeWithSignature(
          "operate(address,uint256,int256,int256,uint256)",
          FLUID_VAULT_ADDRESS_NEW,
          FLUID_NFT_ID_NEW,
          -int256(fromWithdrawAmount_),
          0,
          0
        );
      } else if (fromProtocolId_ == 10) {
        // wstETH based protocol
        targets_[0] = "AAVE-V3-LIDO-A";
        calldatas_[0] = abi.encodeWithSignature(
          "withdraw(address,uint256,uint256,uint256)",
          WSTETH_ADDRESS,
          fromWithdrawAmount_, // stETH amount converted to wstETH.
          0,
          0
        );
      } else {
        revert Helpers__UnsupportedProtocolId();
      }

      // convert wstETH to stETH if necessary
      targets_[1] = "WSTETH-A";
      calldatas_[1] = abi.encodeWithSignature(
        "withdraw(uint256,uint256,uint256)",
        type(uint256).max, // Converting all the withdrawn amount
        0,
        0
      );

      // Using max amount to withdraw stETH from DSA to vault
      targets_[2] = "BASIC-A";
      calldatas_[2] = abi.encodeWithSignature(
        "withdraw(address,uint256,address,uint256,uint256)",
        STETH_ADDRESS,
        type(uint256).max,
        address(this),
        0,
        0
      );

      vaultDSA.cast(targets_, calldatas_, address(this));

      // Make sure protocol ratio is still below max risk ratio
      if (
        IVault(address(this)).getProtocolRatio(fromProtocolId_) >
        maxRiskRatio[fromProtocolId_]
      ) {
        revert WithdrawalsModule__VaultUnsafeAfterWithdraw();
      }
    }

    // Approve stETH amount to Lido withdrawal queue
    IERC20Upgradeable(STETH_ADDRESS).safeApprove(
      address(LIDO_WITHDRAWAL_QUEUE),
      stethAmount_
    );

    // Request withdrawal at Lido withdrawal queue
    uint256[] memory amounts_ = new uint256[](1);
    amounts_[0] = stethAmount_;

    // Vault will always be the owner of request IDs
    uint256[] memory requestIds_ = LIDO_WITHDRAWAL_QUEUE.requestWithdrawals(
      amounts_,
      address(this) // Vault will receive the confirmatory NFT
    );

    requestId_ = requestIds_[0];

    uint256 nftBalanceAfter_ = LIDO_WITHDRAWAL_QUEUE.balanceOf(address(this));

    if (nftBalanceAfter_ != (nftBalanceBefore_ + 1)) {
      revert WithdrawalsModule__ERC721NotTransferred();
    }

    // Update queued stETH amount
    queuedWithdrawStEth += stethAmount_;

    // Log withdrawal queued
    emit LogQueueEthWithdrawal(stethAmount_, requestId_, fromProtocolId_);
  }

  /// @notice accept ERC721 token transfers ONLY from LIDO_WITHDRAWAL_QUEUE
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public returns (bytes4) {
    if (msg.sender == address(LIDO_WITHDRAWAL_QUEUE)) {
      return this.onERC721Received.selector;
    }

    revert WithdrawalsModule__InvalidERC721Transfer();
  }

  /// @notice claims ETH for queued Lido withdraw request and repays the debt at `toProtocolId_`
  /// @dev more details in event logged by Lido contract WithdrawalQueue event "WithdrawClaimed" (e.g. amount of ETH claimed)
  /// @param requestId_ Id of request at Lido. Can be found with `getEthWithdrawalRequests()`
  /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH). Protocol ID should be sent as '0' to skip repaying.
  function claimEthWithdrawal(
    uint256 requestId_,
    uint8 toProtocolId_
  ) external nonReentrant onlyRebalancer {
    // Get amount of original stETH locked (and spent) for request
    uint256[] memory requestIds_ = new uint256[](1);
    requestIds_[0] = requestId_;

    ILidoWithdrawalQueue.WithdrawalRequestStatus[]
      memory requestStatuses_ = LIDO_WITHDRAWAL_QUEUE.getWithdrawalStatus(
        requestIds_
      );

    // Check ETH balance before claim
    uint256 balanceBefore_ = address(this).balance;

    // No checks needed, Lido will fail if requestId is not claimable or invalid
    LIDO_WITHDRAWAL_QUEUE.claimWithdrawal(requestId_);

    // Check ETH balance after claim.
    uint256 balanceAfter_ = address(this).balance;

    // We can't check the exact ETH recieved as the amount can vary due to slashing and penalties.
    // https://github.com/lidofinance/lido-dao/blob/master/contracts/0.8.9/WithdrawalQueueBase.sol#L154
    if (balanceAfter_ <= balanceBefore_) {
      revert WithdrawalsModule__NoETHTransferred();
    }

    // Convert all ETH received to WETH
    IWeth(WETH_ADDRESS).deposit{ value: address(this).balance }();

    // Repay the debt at toProtocolId_
    if (toProtocolId_ > 0) {
      _paybackDebt(toProtocolId_);
    }

    // Update queued stETH amount
    queuedWithdrawStEth -= requestStatuses_[0].amountOfStETH;

    // Log withdrawal claimed
    emit LogClaimEthWithdrawal(
      requestStatuses_[0].amountOfStETH,
      requestId_,
      toProtocolId_
    );
  }

  /// @notice Internal function to repay claimed amounts to a protocol
  /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH)
  function _paybackDebt(uint8 toProtocolId_) internal {
    if (
      toProtocolId_ == 1 || // Aave v2
      toProtocolId_ == 4 || // Euler
      toProtocolId_ == 5 || // Morpho Aave v2
      toProtocolId_ == 6 || // Morpho Aave v3
      toProtocolId_ == 8 // Fluid
    ) {
      revert Helpers__ProtocolDisabled();
    }

    string[] memory targets_;
    bytes[] memory calldatas_;

    if (toProtocolId_ == 9) {
      targets_ = new string[](2);
      calldatas_ = new bytes[](2);
    } else {
      targets_ = new string[](1);
      calldatas_ = new bytes[](1);
    }

    uint256 wethBalanceToPayback_ = TokenInterface(WETH_ADDRESS).balanceOf(
      address(this)
    );

    // Deposit all WETH to DSA
    IWeth(WETH_ADDRESS).transfer(address(vaultDSA), wethBalanceToPayback_);

    // repay max WETH at `toProtocolId_`
    if (toProtocolId_ == 2) {
      targets_[0] = "AAVE-V3-A";
      calldatas_[0] = abi.encodeWithSignature(
        "payback(address,uint256,uint256,uint256,uint256)",
        WETH_ADDRESS,
        type(uint256).max,
        2,
        0,
        0
      );
    } else if (toProtocolId_ == 3) {
      targets_[0] = "COMPOUND-V3-A";
      calldatas_[0] = abi.encodeWithSignature(
        "payback(address,address,uint256,uint256,uint256)",
        COMP_ETH_MARKET_ADDRESS,
        WETH_ADDRESS,
        type(uint256).max,
        0,
        0
      );
    } else if (toProtocolId_ == 7) {
      targets_[0] = "SPARK-A";
      calldatas_[0] = abi.encodeWithSignature(
        "payback(address,uint256,uint256,uint256,uint256)",
        WETH_ADDRESS,
        type(uint256).max,
        2,
        0,
        0
      );
    } else if (toProtocolId_ == 9) {
      // Convert WETH to ETH
      targets_[0] = "WETH-A";
      calldatas_[0] = abi.encodeWithSignature(
        "withdraw(uint256,uint256,uint256)",
        type(uint256).max,
        0,
        0
      );

      // to: wstETH based protocol
      targets_[1] = "FLUID-A";
      calldatas_[1] = abi.encodeWithSignature(
        "operate(address,uint256,int256,int256,uint256)",
        FLUID_VAULT_ADDRESS_NEW,
        FLUID_NFT_ID_NEW,
        0,
        type(int256).min,
        wethBalanceToPayback_
      );
    } else if (toProtocolId_ == 10) {
      targets_[0] = "AAVE-V3-LIDO-A";
      calldatas_[0] = abi.encodeWithSignature(
        "payback(address,uint256,uint256,uint256,uint256)",
        WETH_ADDRESS,
        type(uint256).max,
        2,
        0,
        0
      );
    } else {
      revert Helpers__UnsupportedProtocolId();
    }

    // Protocol ratio can only be better after repay, no need to check max risk ratio
    vaultDSA.cast(targets_, calldatas_, address(this));

    // Log WETH payback
    emit LogWethPayback(wethBalanceToPayback_, toProtocolId_);
  }

  /// @notice Transfers WETH from vault to DSA and repays debt at `toProtocolId_`
  /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH)
  function paybackDebt(
    uint8 toProtocolId_
  ) external nonReentrant onlyRebalancer {
    _paybackDebt(toProtocolId_);
  }
}
