// SPDX-License-Identifier: AGPL-3.0-or-later and MIT
//      ___                         ___           ___           ___           ___           ___                   
//     /  /\          __           /  /\         /  /\         /  /\         /  /\         /  /\          ___     
//    /  /::\        |  |\        /  /::|       /  /::\       /  /::\       /  /:/_       /  /::\        /  /\    
//   /__/:/\:\       |  |:|      /  /:|:|      /  /:/\:\     /__/:/\:\     /  /:/ /\     /  /:/\:\      /  /::\   
//  _\_ \:\ \:\      |  |:|     /  /:/|:|__   /  /:/  \:\   _\_ \:\ \:\   /  /:/ /:/_   /  /::\ \:\    /  /:/\:\  
// /__/\ \:\ \:\     |__|:|__  /__/:/ |:| /\ /__/:/ \  \:\ /__/\ \:\ \:\ /__/:/ /:/ /\ /__/:/\:\_\:\  /  /::\ \:\ 
// \  \:\ \:\_\/     /  /::::\ \__\/  |:|/:/ \  \:\  \__\/ \  \:\ \:\_\/ \  \:\/:/ /:/ \__\/  \:\/:/ /__/:/\:\_\:\
//  \  \:\_\:\      /  /:/~~~~     |  |:/:/   \  \:\        \  \:\_\:\    \  \::/ /:/       \__\::/  \__\/  \:\/:/
//   \  \:\/:/     /__/:/          |__|::/     \  \:\        \  \:\/:/     \  \:\/:/        /  /:/        \  \::/ 
//    \  \::/      \__\/           /__/:/       \  \:\        \  \::/       \  \::/        /__/:/          \__\/  
//     \__\/                       \__\/         \__\/         \__\/         \__\/         \__\/                  
//
// Welcome to the SyncSwap Router!
//

// File contracts/interfaces/token/IERC20Base.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IERC20Base {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
}


// File contracts/interfaces/token/IERC20.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IERC20 is IERC20Base {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


// File contracts/interfaces/token/IERC20Permit.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/interfaces/token/IERC20Permit2.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IERC20Permit2 is IERC20Permit {
    function permit2(address owner, address spender, uint amount, uint deadline, bytes calldata signature) external;
}


// File contracts/interfaces/token/IERC20PermitAllowed.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/abstract/SelfPermit.sol

// Original license: SPDX_License_Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;
abstract contract SelfPermit {
    function selfPermit(
        address token,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermitIfNecessary(
        address token,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < value) {
            selfPermit(token, value, deadline, v, r, s);
        }
    }

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max) {
            selfPermitAllowed(token, nonce, expiry, v, r, s);
        }
    }

    function selfPermit2(
        address token,
        uint value,
        uint deadline,
        bytes calldata signature
    ) public payable {
        IERC20Permit2(token).permit2(msg.sender, address(this), value, deadline, signature);
    }

    function selfPermit2IfNecessary(
        address token,
        uint value,
        uint deadline,
        bytes calldata signature
    ) external payable {
        if (IERC20(token).allowance(msg.sender, address(this)) < value) {
            selfPermit2(token, value, deadline, signature);
        }
    }
}


// File contracts/interfaces/pool/IPool.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IPool {
    struct TokenAmount {
        address token;
        uint amount;
    }

    /// @dev Returns the address of pool master.
    function master() external view returns (address);

    /// @dev Returns the vault.
    function vault() external view returns (address);

    /// @dev Returns the pool type.
    function poolType() external view returns (uint16);

    /// @dev Returns the assets of the pool.
    function getAssets() external view returns (address[] memory assets);

    /// @dev Returns the swap fee of the pool.
    function getSwapFee(address sender, address tokenIn, address tokenOut, bytes calldata data) external view returns (uint24 swapFee);

    /// @dev Returns the protocol fee of the pool.
    function getProtocolFee() external view returns (uint24 protocolFee);

    /// @dev Mints liquidity.
    function mint(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (uint liquidity);

    /// @dev Burns liquidity.
    function burn(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (TokenAmount[] memory tokenAmounts);

    /// @dev Burns liquidity with single output token.
    function burnSingle(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (TokenAmount memory tokenAmount);

    /// @dev Swaps between tokens.
    function swap(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (TokenAmount memory tokenAmount);
}


// File contracts/interfaces/pool/IBasePool.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IBasePool is IPool, IERC20Permit2 {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function reserve0() external view returns (uint);
    function reserve1() external view returns (uint);
    function invariantLast() external view returns (uint);

    function getReserves() external view returns (uint, uint);
    function getAmountOut(address tokenIn, uint amountIn, address sender) external view returns (uint amountOut);
    function getAmountIn(address tokenOut, uint amountOut, address sender) external view returns (uint amountIn);

    event Mint(
        address indexed sender,
        uint amount0,
        uint amount1,
        uint liquidity,
        address indexed to
    );

    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        uint liquidity,
        address indexed to
    );

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event Sync(
        uint reserve0,
        uint reserve1
    );
}


// File contracts/interfaces/vault/IERC3156FlashBorrower.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}


// File contracts/interfaces/vault/IERC3156FlashLender.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}


// File contracts/interfaces/vault/IFlashLoanRecipient.sol

// Original license: SPDX_License_Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.9.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint[] memory amounts,
        uint[] memory feeAmounts,
        bytes memory userData
    ) external;
}


// File contracts/interfaces/vault/IFlashLoan.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IFlashLoan is IERC3156FlashLender {
    function flashLoanFeePercentage() external view returns (uint);

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoanMultiple(
        IFlashLoanRecipient recipient,
        address[] memory tokens,
        uint[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(address indexed recipient, address indexed token, uint amount, uint feeAmount);
}


// File contracts/interfaces/vault/IVault.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
interface IVault is IFlashLoan {
    function wETH() external view returns (address);

    function reserves(address token) external view returns (uint reserve);

    function balanceOf(address token, address owner) external view returns (uint balance);

    function deposit(address token, address to) external payable returns (uint amount);

    function depositETH(address to) external payable returns (uint amount);

    function transferAndDeposit(address token, address to, uint amount) external payable returns (uint);

    function transfer(address token, address to, uint amount) external;

    function withdraw(address token, address to, uint amount) external;

    function withdrawAlternative(address token, address to, uint amount, uint8 mode) external;

    function withdrawETH(address to, uint amount) external;
}


// File contracts/libraries/Ownable.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/libraries/TransferHelper.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/// @dev The ETH transfer has failed.
error ETHTransferFailed();

/// @dev The ERC20 `transferFrom` has failed.
error TransferFromFailed();

/// @dev The ERC20 `transfer` has failed.
error TransferFailed();

/// @dev The ERC20 `approve` has failed.
error ApproveFailed();

/// @dev Helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true / false.
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ApproveFailed();
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFromFailed();
        }
    }

    function safeTransferETH(address to, uint value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}("");

        if (!success) {
            revert ETHTransferFailed();
        }
    }
}


// File contracts/libraries/Rescuable.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
abstract contract Rescuable is Ownable {
    /// @dev Rescues ERC20 tokens.
    function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0) && to != token, "Invalid to");

        uint balance = IERC20(token).balanceOf(address(this));

        if (amount == 0) {
            TransferHelper.safeTransfer(token, to, balance);
        } else {
            require(amount <= balance, "Exceeds balance");
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    /// @dev Rescues Ether.
    function rescueETH(address payable to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        TransferHelper.safeTransferETH(to, amount);
    }
}


// File contracts/abstract/Multicall.sol

// Original license: SPDX_License_Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// License-Identifier: GPL-2.0-or-later
abstract contract Multicall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        for (uint i; i < data.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }
}


// File contracts/interfaces/factory/IPoolFactory.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IPoolFactory {
    function master() external view returns (address);

    function getDeployData() external view returns (bytes memory);

    function createPool(bytes calldata data) external returns (address pool);
}


// File contracts/interfaces/IRouter.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IRouter {
    struct SwapStep {
        address pool;
        bytes data;
        address callback;
        bytes callbackData;
        bool useVault;
    }

    struct SwapPath {
        SwapStep[] steps;
        address tokenIn;
        uint amountIn;
    }

    struct SplitPermitParams {
        address token;
        uint approveAmount;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ArrayPermitParams {
        uint approveAmount;
        uint deadline;
        bytes signature;
    }
}


// File contracts/interfaces/IStaking.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IStaking {
    function stake(uint amount, address to) external;
    function stake(address token, uint amount, address to) external;
}


// File contracts/interfaces/IWETH.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/SyncSwapRouterV2.sol

// Original license: SPDX_License_Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
error NotEnoughLiquidityMinted();
error TooLittleReceived();
error Expired();

/// @notice The router is a universal interface for users to access
/// functions across different protocol parts in one place.
///
/// It handles the allowances and transfers of tokens, and
/// allows chained swaps/operations across multiple pools, with
/// additional features like slippage protection and permit support.
///
contract SyncSwapRouterV2 is IRouter, SelfPermit, Multicall, Rescuable {

    struct TokenInput {
        address token;
        uint amount;
        bool useVault;
    }

    address public immutable vault;
    address public immutable wETH;
    address private constant NATIVE_ETH = address(0);

    mapping(address => mapping(address => bool)) public isPoolEntered;
    mapping(address => address[]) public enteredPools;

    modifier ensure(uint deadline) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > deadline) {
            revert Expired();
        }
        _;
    }

    constructor(address _vault, address _wETH) {
        vault = _vault;
        wETH = _wETH;
    }

    function enteredPoolsLength(address account) external view returns (uint) {
        return enteredPools[account].length;
    }

    function _transferFromSender(address token, address to, uint amount, bool useVault) private {
        if (useVault) {
            if (token == NATIVE_ETH) {
                // Deposit ETH to the vault.
                IVault(vault).deposit{value: amount}(token, to);
            } else {
                // Transfer tokens to the vault.
                TransferHelper.safeTransferFrom(token, msg.sender, vault, amount);

                // Notify the vault to deposit.
                IVault(vault).deposit(token, to);
            }
        } else {
            if (token == NATIVE_ETH) {
                // Wrap native ETH to wETH.
                IWETH(wETH).deposit{value: amount}();

                // Send wETH to the pool.
                IWETH(wETH).transfer(to, amount);
            } else {
                // Transfer tokens to the pool.
                TransferHelper.safeTransferFrom(token, msg.sender, to, amount);
            }
        }
    }

    function _transferAndAddLiquidity(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData
    ) private returns (uint liquidity) {
        // Send all input tokens to the pool.
        uint n = inputs.length;

        TokenInput memory input;

        for (uint i; i < n; ) {
            input = inputs[i];

            _transferFromSender(input.token, pool, input.amount, input.useVault);

            unchecked {
                ++i;
            }
        }

        liquidity = IPool(pool).mint(data, msg.sender, callback, callbackData);

        if (liquidity < minLiquidity) {
            revert NotEnoughLiquidityMinted();
        }
    }

    function _markPoolEntered(address pool) private {
        if (!isPoolEntered[pool][msg.sender]) {
            isPoolEntered[pool][msg.sender] = true;
            enteredPools[msg.sender].push(pool);
        }
    }

    function addLiquidity(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData,
        address staking
    ) public payable returns (uint liquidity) {
        liquidity = _transferAndAddLiquidity(
            pool,
            inputs,
            data,
            minLiquidity,
            callback,
            callbackData
        );

        if (staking != address(0)) {
            (,address stakingTo) = abi.decode(data, (address, address));
            if (stakingTo != address(0)) {
                _stake(staking, pool, liquidity);
                IStaking(staking).stake(liquidity, stakingTo);
            }
        }
    }

    function addLiquidity2(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData,
        address staking
    ) external payable returns (uint liquidity) {
        liquidity = addLiquidity(
            pool,
            inputs,
            data,
            minLiquidity,
            callback,
            callbackData,
            staking
        );

        _markPoolEntered(pool);
    }

    function addLiquidityWithPermit(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData,
        SplitPermitParams[] memory permits,
        address staking
    ) public payable returns (uint liquidity) {
        // Approve all tokens via permit.
        uint n = permits.length;

        SplitPermitParams memory params;

        for (uint i; i < n; ) {
            params = permits[i];

            IERC20Permit(params.token).permit(
                msg.sender,
                address(this),
                params.approveAmount,
                params.deadline,
                params.v,
                params.r,
                params.s
            );

            unchecked {
                ++i;
            }
        }

        liquidity = _transferAndAddLiquidity(
            pool,
            inputs,
            data,
            minLiquidity,
            callback,
            callbackData
        );

        if (staking != address(0)) {
            address to = abi.decode(data, (address));
            IStaking(staking).stake(liquidity, to);
        }
    }

    function addLiquidityWithPermit2(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData,
        SplitPermitParams[] memory permits,
        address staking
    ) public payable returns (uint liquidity) {
        liquidity = addLiquidityWithPermit(
            pool,
            inputs,
            data,
            minLiquidity,
            callback,
            callbackData,
            permits,
            staking
        );

        _markPoolEntered(pool);
    }

    // Burn Liquidity
    function _transferAndBurnLiquidity(
        address pool,
        uint liquidity,
        bytes memory data,
        uint[] memory minAmounts,
        address callback,
        bytes calldata callbackData
    ) private returns (IPool.TokenAmount[] memory amounts) {
        IBasePool(pool).transferFrom(msg.sender, pool, liquidity);

        amounts = IPool(pool).burn(data, msg.sender, callback, callbackData);

        uint n = amounts.length;

        for (uint i; i < n; ) {
            IPool.TokenAmount memory tokenAmount = amounts[i];

            if (tokenAmount.amount < minAmounts[i]) {
                revert TooLittleReceived();
            }

            unchecked {
                ++i;
            }
        }
    }

    function burnLiquidity(
        address pool,
        uint liquidity,
        bytes calldata data,
        uint[] calldata minAmounts,
        address callback,
        bytes calldata callbackData
    ) external returns (IPool.TokenAmount[] memory amounts) {
        amounts = _transferAndBurnLiquidity(
            pool,
            liquidity,
            data,
            minAmounts,
            callback,
            callbackData
        );
    }

    function burnLiquidityWithPermit(
        address pool,
        uint liquidity,
        bytes calldata data,
        uint[] calldata minAmounts,
        address callback,
        bytes calldata callbackData,
        ArrayPermitParams memory permit
    ) external returns (IPool.TokenAmount[] memory amounts) {
        // Approve liquidity via permit.
        IBasePool(pool).permit2(
            msg.sender,
            address(this),
            permit.approveAmount,
            permit.deadline,
            permit.signature
        );

        amounts = _transferAndBurnLiquidity(
            pool,
            liquidity,
            data,
            minAmounts,
            callback,
            callbackData
        );
    }

    // Burn Liquidity Single
    function _transferAndBurnLiquiditySingle(
        address pool,
        uint liquidity,
        bytes memory data,
        uint minAmount,
        address callback,
        bytes memory callbackData
    ) private returns (IPool.TokenAmount memory amountOut) {
        IBasePool(pool).transferFrom(msg.sender, pool, liquidity);

        amountOut = IPool(pool).burnSingle(data, msg.sender, callback, callbackData);

        if (amountOut.amount < minAmount) {
            revert TooLittleReceived();
        }
    }

    function burnLiquiditySingle(
        address pool,
        uint liquidity,
        bytes memory data,
        uint minAmount,
        address callback,
        bytes memory callbackData
    ) external returns (IPool.TokenAmount memory amountOut) {
        amountOut = _transferAndBurnLiquiditySingle(
            pool,
            liquidity,
            data,
            minAmount,
            callback,
            callbackData
        );
    }

    function burnLiquiditySingleWithPermit(
        address pool,
        uint liquidity,
        bytes memory data,
        uint minAmount,
        address callback,
        bytes memory callbackData,
        ArrayPermitParams calldata permit
    ) external returns (IPool.TokenAmount memory amountOut) {
        // Approve liquidity via permit.
        IBasePool(pool).permit2(
            msg.sender,
            address(this),
            permit.approveAmount,
            permit.deadline,
            permit.signature
        );

        amountOut = _transferAndBurnLiquiditySingle(
            pool,
            liquidity,
            data,
            minAmount,
            callback,
            callbackData
        );
    }

    // Swap
    function _swap(
        SwapPath[] memory paths,
        uint amountOutMin
    ) private returns (IPool.TokenAmount memory amountOut) {
        uint pathsLength = paths.length;

        SwapPath memory path;
        SwapStep memory step;
        IPool.TokenAmount memory tokenAmount;

        for (uint i; i < pathsLength; ) {
            path = paths[i];

            // Prefund the first step.
            step = path.steps[0];
            _transferFromSender(path.tokenIn, step.pool, path.amountIn, step.useVault);

            // Cache steps length.
            uint stepsLength = path.steps.length;

            uint j;
            while (true) {
                if (j == stepsLength - 1) {
                    // Accumulate output amount at the last step.
                    tokenAmount = IBasePool(step.pool).swap(
                        step.data, msg.sender, step.callback, step.callbackData
                    );

                    amountOut.token = tokenAmount.token;
                    amountOut.amount += tokenAmount.amount;

                    break;
                } else {
                    // Swap and send tokens to the next step.
                    tokenAmount = IBasePool(step.pool).swap(
                        step.data, msg.sender, step.callback, step.callbackData
                    );

                    bool _useVault = step.useVault;

                    // Cache the next step.
                    unchecked {
                        ++j;
                    }
                    step = path.steps[j];

                    if (!_useVault && step.useVault) {
                        uint amount = IERC20(tokenAmount.token).balanceOf(address(this));

                        // Transfer tokens to the vault.
                        TransferHelper.safeTransfer(tokenAmount.token, vault, amount);

                        // Notify the vault to deposit.
                        IVault(vault).deposit(tokenAmount.token, step.pool);
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        if (amountOut.amount < amountOutMin) {
            revert TooLittleReceived();
        }
    }

    function swap(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable ensure(deadline) returns (IPool.TokenAmount memory amountOut) {
        amountOut = _swap(
            paths,
            amountOutMin
        );
    }

    function swapWithPermit(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline,
        SplitPermitParams calldata permit
    ) external payable ensure(deadline) returns (IPool.TokenAmount memory amountOut) {
        // Approve input tokens via permit.
        IERC20Permit(permit.token).permit(
            msg.sender,
            address(this),
            permit.approveAmount,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );

        amountOut = _swap(
            paths,
            amountOutMin
        );
    }

    /// @notice Wrapper function to allow pool deployment to be batched.
    function createPool(address _factory, bytes calldata data) external payable returns (address) {
        return IPoolFactory(_factory).createPool(data);
    }

    function _stake(address target, address token, uint amount) private {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);

        if (IERC20(token).allowance(address(this), target) < amount) {
            /// @dev This can approve arbitrary contract, the router is not intended to store any funds.
            TransferHelper.safeApprove(token, target, type(uint).max);
        }
    }

    /// @dev Universal function to stake tokens to a target contract.
    function stake(address target, address token, uint amount, address to) external {
        _stake(target, token, amount);
        IStaking(target).stake(amount, to);
    }

    function stakeWithToken(address target, address token, uint amount, address to) external {
        _stake(target, token, amount);
        IStaking(target).stake(token, amount, to);
    }
}
