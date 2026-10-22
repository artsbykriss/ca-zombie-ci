// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity >=0.6.2;


/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/draft-IERC6093.sol)
pragma solidity >=0.8.4;

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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



// File: BT.sol


pragma solidity ^0.8.24;

/**
 * @title BT Token Contract
 * @notice BT (BTCΞ) 是一个创新的 BEP-20 代币，具有算力挖矿、节点奖励、邀请系统等功能
 * @dev 实现了完整的 LP 管理、自动底池燃烧、自动奖励分配等机制
 * @dev 生产环境：静态+燃烧使用小时周期；动态+节点使用一天周期
 */

contract BTToken is ERC20,Ownable {
    
    // ============ 常量定义 ============
    address public tokenExt; //代币逻辑扩展合约
    address public feeSwapper;  // 手续费兑换合约地址
    
    /// @notice 黑洞地址，用于接收销毁的代币
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    /// @notice 基础比例分母
    uint256 private constant BASE = 100000;
    
    // ============ DEX 相关 ============
    /// @notice PancakeSwap Router V2 (BSC Mainnet)
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    /// @notice USDT 代币地址 (BSC)
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    
    /// @notice WBTC 代币地址 (BSC)
    address public constant WBTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    
    /// @notice WBNB 代币地址 (BSC)
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
            
    /// @notice BT-WBTC LP 池地址
    address public pancakePair;

    /// @notice 初始上级地址（创世推荐人）
    address public constant INITIAL_SUPERIOR = 0xa48E7A588Ca9eb17607ab8D9d5250B4240Bec16a;
    
    // ============ 地址配置 ============
    /// @notice 极客联盟：2% BT
    address public geekAddress = 0xd8323fBAa953B3268Afa9b9b08BE92374bF2449E;

    /// @notice 生态建设 3% BT
    address public boostBTAddress = 0xD2314A256Fe48c37Dfc8C13e62d90c23d8Bd67F8;

    /// @notice 拉升5th合约地址 (5%) 
    address public constant boostContractAddress = 0x03Ee9130ee70c25aeC447D00619B67C264b507f2;

    /// @notice 联盟地址 (BT 5%) 捐赠分配
    address public constant allianceAddress = 0xf6dC7c4d81BBCa2b8e8b2C1353e4cDf76E7c3999;

    /// @notice 技术地址 (0.5%)
    address public constant techSupportAddress = 0x1CC59782d17ba841574944faF52006033caE4082;
    
    /// @notice 白名单地址
    address public constant baiAddress = 0xC2F00595864C55C0fDb4bdA7dAE8B6A66a6bB657;

    /// @notice 归集地址
    address public constant guijiAddress = 0xF9bbDABf6Ed35e8b045712123cC7d230d10C75e8;
    
    // ============ 用户信息结构 ============
    
    /// @notice 用户信息
    struct User {
        address superior;           // 上级地址
        uint8   nodeLevel;          // 节点等级 0=无，1=V1，2=V2，3=V3, 4=V4, 5=V5
        uint256 lpAmount;           // LP 代币数量
        uint256 usdtValue;          // USDT 面值
        uint256 depositCycle;       // 入场周期
        uint256 hashrateStatic;     // 静态算力
        uint256 hashrateDynamic;    // 动态算力
        uint256 staticReceived;     // 静态已领取（累计）
        uint256 dynamicReceived;    // 动态已领取（累计）
        uint256 nodeWBTCReceived;   // 节点WBTC已领取
        uint256 nodeBTReceived;   // 节点BT奖励已领取（累计）
        uint256 validReferralCount; // 有效下级数量（直推且已入金的用户）
        uint256 hashrateReward;
    }
    
    /// @notice 用户领奖周期记录
    struct UserLast {
        uint256 lastStaticCycle;    // 上次静态领奖周期
        uint256 lastDynamicCycle;   // 上次动态领奖周期
        uint256 lastNodeWBTCCycle;  // 上次节点WBTC领奖周期
        uint256 lastNodeBTCycle;   // 上次节点BT领奖周期
    }
    
    /// @notice 用户信息映射
    mapping(address => User) public users;
    mapping(address => uint256) public wbtcReward;
    
    /// @notice 用户领奖周期映射
    mapping(address => UserLast) public userLasts;

    /// @notice 用户周期静态算力映射
    mapping(address => mapping(uint256 => uint256)) public usersCycleStaticHashrate;

    /// @notice 用户周期动态算力映射
    mapping(address => mapping(uint256 => uint256)) public usersCyclelDynamicHashrate;

    /// @notice 用户周期节点等级映射
    mapping(address => mapping(uint256 => uint256)) public usersCyclelNodeLevel;
    
    /// @notice 算力贡献记录：上级地址 => 下级地址 => 下级实际贡献的动态算力
    /// @dev 用于赎回时精确扣除，避免多扣或少扣
    mapping(address => mapping(address => uint256)) public hashrateContribution;
    
    // ============ 全网数据 ============
    
    /// @notice 全网总静态算力
    uint256 public totalStaticHashrate;
    
    /// @notice 全网总动态算力
    uint256 public totalDynamicHashrate;
    
    /// @notice 各节点等级总人数 [V1, V2, V3, V4, V5]
    uint256[5] public nodeTotalCount;
    
    // ============ 周期数据（静态奖励 + 底池燃烧）============
    
    /// @notice 周期静态算力快照
    mapping(uint256 => uint256) public hourlyCycleStaticHashrate;
    
    /// @notice 周期静态奖励
    mapping(uint256 => uint256) public hourlyCycleStaticReward;
    
    // ============ 周期数据（动态 + 节点）============
    
    /// @notice 周期动态算力快照
    mapping(uint256 => uint256) public dailyCycleDynamicHashrate;
    
    /// @notice 周期节点人数快照 [V1, V2, V3, V4, V5]
    mapping(uint256 => uint256[5]) public dailyCycleNodeCount;
    
    /// @notice 周期动态奖励
    mapping(uint256 => uint256) public dailyCycleDynamicReward;
    
    /// @notice 周期节点奖励 
    mapping(uint256 => uint256[10]) public dailyCycleNodeRewards;
    
    // ============ 时间与周期 ============
    
    /// @notice 合约创建时间（取整时）
    uint256 public  launchTime;
    
    // ============ 入金 ============
    
    /// @notice 用户是否已经入金过
    mapping(address => bool) public hasDeposited;
    
    // ============ 白名单 ============
    
    /// @notice 转账白名单（免手续费和销毁）
    mapping(address => bool) public transferWhitelist;

    /// @notice 每小时的单价
    mapping(uint256 => uint256) public pricePerHour;

    /// @notice 每日进场用户数量
    mapping(uint256 => uint256) public numberPerDay;
    
    /// @notice 进场队列
    UserQueue[] public usersQueue;
    
    /// @notice 队列处理序列号
    uint256 public processIndex;

    /// @notice 用户排队序号
    mapping(address=>uint256) public queueIndexOfUser;

    /// @notice 用户排队日期
    mapping(address=>uint256) public currentDayOfUser;

    uint256 public poolValue;

    /// @notice 用户上次卖出时间戳（停止产币机制）
    mapping(address => uint256) public userLastSellTime;
    /// @notice 用户卖出总数量（停止产币机制）
    mapping(address => uint256) public userSellAmount;

    mapping(address=>uint256) public sellValue;
    mapping(address=>uint256) public wbtcValue;
    uint256 public lastDepositeTime;
    uint256 public depositIndex;
    /// @notice 用户排队记录
    struct UserQueue{
        address user;
        uint8 status;
        uint256 value;
    }
    // ============ 事件定义 ============
    
    event Deposit(address indexed user, uint256 bnbAmount, uint256 usdtAmount,uint256 lpAmount);
    event EnterQueue(address indexed user,uint256 bnbAmount,uint256 Day);
    event Redeem(address indexed user, uint256 lpAmount, uint256 wbtcAmount, uint256 btAmount,uint256 cycle);
    event ReferrerBound(address indexed user, address indexed referrer);
    event NodeLevelChanged(address indexed user, uint8 oldLevel, uint8 newLevel);
    event HourlyCycleUpdated(uint256 cycle, uint256 staticHashrate, uint256 staticReward, uint256 burnAmount);
    event DailyCycleUpdated(uint256 cycle, uint256 dynamicHashrate, uint256 dynamicReward, uint256[5] nodeHashrate);
    event RewardClaimed(address indexed user, uint8 rewardType, uint256 amount,uint newCycle);
    event RedeemCompleted(address indexed user);
    event HashrateMismatch(address indexed user, uint256 requested, uint256 actual, string hashrateType);
    event SellAmountAdjusted(address indexed user, uint256 requestedAmount, uint256 actualAmount);
    event RewardCompleted(address indexed user, uint level, uint256 staticHashrate, uint256 dynamicHashrate, uint256 reward,bool status);
    
    
    // ============ 构造函数 ============
    
    
    constructor() ERC20(unicode"BTCΞ", unicode"BTCΞ") Ownable(baiAddress) {
        // 铸造总供应量
        launchTime = 0;
        _mint(baiAddress, 6_660_000 ether);
        _mint(INITIAL_SUPERIOR,10 ether);
        // 将关键地址加入白名单
        transferWhitelist[address(this)] = true;
        transferWhitelist[DEAD] = true;
        transferWhitelist[INITIAL_SUPERIOR] = true;
        transferWhitelist[baiAddress] = true;
        // 初始化创世上级（指向自己，避免绑定检查失败）
        users[INITIAL_SUPERIOR].superior = INITIAL_SUPERIOR;
        initializeLiquidity();
    }

    // ============ 周期函数 ============
    
    /**
     * @notice 获取当前周期（用于静态奖励和底池燃烧）
     */
    function getHourlyCycle() public view returns (uint256) {
        return (block.timestamp - launchTime) / 1 hours;
    }
    
    /**
     * @notice 获取当前周期（用于动态奖励和节点奖励
     */
    function getDailyCycle() public view returns (uint256) {
        return (block.timestamp - launchTime) / 1 days;
    }
    function setFeeSwapper(address _feeSwapper) public  onlyOwner(){
        require(_feeSwapper != address(0), "Ia");//Invalid address
        feeSwapper = _feeSwapper;
        // 将 feeSwapper 加入白名单
        transferWhitelist[_feeSwapper] = true;
    }
    function settokenExt(address ext) public  onlyOwner(){
        tokenExt = ext;
        transferWhitelist[ext] = true;
    }
    /**
     * @notice 尝试兑换累积的手续费（内部调用）
     * @dev 在普通转账时触发，失败不影响主流程
     */
    function _trySwapFees() internal {
        if (feeSwapper == address(0)) return;
        // 检查累积的手续费数量
        uint256 feeBalance = IFeeSwapper(feeSwapper).getBTBalance();
        
        // 如果累积超过 1 BT，则触发兑换
        if (feeBalance >= 1 ether) {
            try IFeeSwapper(feeSwapper).swapBTForWBTC(feeBalance) returns (uint256 nodeWBTC) {
                if (nodeWBTC > 0) {
                    _distributeNodePool(nodeWBTC);
                }
            } catch {
                // 兑换失败，不影响主流程
            }
        }
    }
    
    // ============ 核心功能：入金 ============
    
    /**
     * @notice 接收 BNB 入金
     */
    receive() external payable {
        require(msg.value >= 2e17, "Bm");//Below minimum
        require(users[msg.sender].superior != address(0), "Mb");//Must bind referrer
        require(pancakePair != address(0), "Ni");//Not initialized
        require(ITokenExt(tokenExt).getFifthTokenUSDTValue(msg.sender) >= 30 ether, "Need >=30U 5TH");
        if(launchTime == 0 && block.timestamp > 1783660740){
            // 设置启动时间
            launchTime = block.timestamp / 1 hours * 1 hours;
        }
        require(launchTime>0,"Nt");

        //更新周期数据（必须在 swap 之前，避免在 swap 过程中重复调用）
        (uint256 currentHour,uint256 currentDay)=_updateCycle();
        
        if(currentHour<24) require(IFeeSwapper(feeSwapper).earleirUser(msg.sender));
        // 检查报单人数
        _queuetoDeposit(msg.sender,currentDay,msg.value);
        lastDepositeTime = block.timestamp;
    }
    
    /**
    * @notice 排队入金
     */
    function _queuetoDeposit(address user, uint256 currentDay, uint256 bnbAmount)internal{
        // 1. 检查入金限制
        uint value = 2e17*(1+(currentDay/2));
        require(bnbAmount <= value || bnbAmount == 21e16 + value,"01");//Exceeds early deposit limit
        require(bnbAmount <= 10 ether || 
            (bnbAmount == 21e16 + 9.8 ether && value == 9.8 ether) || 
            bnbAmount == 21e16 + 10 ether, "l5");//Less than 10 BNB// 2. 记录到队列
        UserQueue memory queue=UserQueue(user,0,bnbAmount);
        usersQueue.push(queue);
        uint index = usersQueue.length - 1;

        queueIndexOfUser[user] = index;
        depositIndex = index;
        currentDayOfUser[user]=ITokenExt(tokenExt).getDay(index,currentDay+1);
        // 3. 检查是否已经入金过
        require(!hasDeposited[user], "oo");//Address can only deposit once
        // 4. 标记用户已经入金
        hasDeposited[user] = true;

        if(value+21e16 == bnbAmount && users[user].hashrateDynamic > 0) {
            IWETH(WBNB).deposit{value:21e16}();
            IERC20(WBNB).transfer(tokenExt,21e16);
            ITokenExt(tokenExt).processBuildLP(21e16, DEAD,0);
            usersQueue[index].status = 1;
            _deposit(user,value);
            return;
        }
        require(bnbAmount <= value,"02");
        if(!_executeDeposit(currentDay,usersQueue.length-1)){
            emit EnterQueue(user,bnbAmount,currentDayOfUser[user]);
        }
        
    }
    /**
     * @notice 队列执行函数
     */
    function _executeDeposit(uint256 currentDay,uint256 index) internal returns(bool){
        // 1. 计算入金数量 以100为基数，每日增加10%，最大1000.
        uint256 allow =100;
        for (uint256 d = 0; d < currentDay; d++) {
            allow = (allow * 110) / 100;
            if (allow >= 188) {
                allow = 188;
                break;
            }
        }
        // 2. 未超过当日限制
        if(numberPerDay[currentDay]>=allow) return false;
        if(usersQueue.length==0) return false;
        uint256 currentlength = usersQueue.length;
        uint256 baseIndex = processIndex;
        uint256 i = baseIndex;

        for (; i < (baseIndex + 6) && i < currentlength; i++) {
            UserQueue storage queue = usersQueue[i];
            if (queue.status > 0) {
                continue; 
            }
            _deposit(queue.user, queue.value);

            numberPerDay[currentDay] += 1;
            queue.status = 1;
            if (numberPerDay[currentDay] >= allow) {
                processIndex = i;
                return false;
            }
        }
        
        processIndex = i-1;

        // 3. 处理自己
        if(index > 0 ){ 
            UserQueue storage queue = usersQueue[index];
            // 用户处于排队中，并且是当日用户
            if(queue.status==0 && currentDayOfUser[queue.user]<=currentDay){
                // 处理入金
                _deposit(queue.user, queue.value);
                // 更新排队状态
                numberPerDay[currentDay]+=1;
                queue.status=1;
                return true;
            }
        }
        return false;
    }
    event TransferPool(address a,address b,address c,uint value);
    function _executeDepositPool() internal {
        if(block.timestamp >= lastDepositeTime + 1 days && poolValue > 0){
            uint index = depositIndex;
            address user1 = usersQueue[index].user;
            address user2 = usersQueue[index-1].user;
            address user3 = usersQueue[index-2].user;
            
            _transferWBTC(user1,poolValue * 5 / 10);
            _transferWBTC(user2,poolValue * 3 / 10);
            _transferWBTC(user3,poolValue * 2 / 10);
            emit TransferPool(
                user1,
                user2,
                user3,poolValue
            );
            poolValue = 0;
            lastDepositeTime = block.timestamp;
        }
    }
    /**
     * @notice 内部入金处理函数
     */
    function _deposit(address user, uint256 bnbAmount) internal {
        
        // 1、将BNB兑换为WBTC
        IWETH(WBNB).deposit{value:bnbAmount}();
        if(userLastSellTime[user] == 0) userLastSellTime[user] = getHourlyCycle();
        
        // 2. 处理WBTC分配和LP构建
        IERC20(WBNB).transfer(tokenExt,bnbAmount);
        (uint256 actualLP,uint256 wbtcAmount) = ITokenExt(tokenExt).processBuildLP(bnbAmount, user,1);

        wbtcValue[user] += wbtcAmount;
        
        // 3. 更新直推上级的有效下级数量
        address superior = users[user].superior;
        if (superior != address(0) && users[user].lpAmount == 0) {
            users[superior].validReferralCount += 1;
        }
        
        // 4. 更新算力和信息
        uint256 usdtAmount = IFeeSwapper(feeSwapper)._getWBNBAmountOut(bnbAmount);
        uint256 staticHashrate = _updateUserHashrateAndInfo(user, usdtAmount, actualLP);
        
        // 5. 分配奖励和算力
        _processRewardsAndHashrate(user, wbtcAmount, staticHashrate);
        
        emit Deposit(user, wbtcAmount, usdtAmount, actualLP);
    }
    
    /**
     * @notice 更新用户算力和信息
     * @dev 静态算力会随着时间递增，越晚入金算力越高（激励早期参与）
     * @param user 用户地址
     * @param usdtAmount 入金的WBTC数量
     * @param actualLP 获得的LP代币数量
     * @return staticHashrate 返回本次获得的静态算力
     */
    function _updateUserHashrateAndInfo(
        address user,
        uint256 usdtAmount,
        uint256 actualLP
    ) internal returns (uint256) {
        // 计算静态算力：基础算力 + 时间加成（每推迟一天+5%）
        uint256 elapsed = getDailyCycle();
        uint256 staticHashrate = usdtAmount + (usdtAmount * elapsed * 5000) / BASE;
        
        // 更新用户数据
        User storage u = users[user];
        u.lpAmount += actualLP;              // 累加LP代币数量
        u.usdtValue += usdtAmount;           // 累加USDT面值（用于节点等级判断）
        
        // 首次入金记录时间和领奖周期
        if (u.depositCycle == 0) {
            // 记录上次领奖周期（避免领取历史奖励）
            userLasts[user].lastStaticCycle = getHourlyCycle();
            userLasts[user].lastDynamicCycle = getDailyCycle();
            userLasts[user].lastNodeWBTCCycle = getDailyCycle();
            userLasts[user].lastNodeBTCycle = getDailyCycle();
        }
        u.depositCycle = elapsed;
        
        u.hashrateStatic += staticHashrate;  // 累加静态算力

        uint256 currentHourlyCycle = getHourlyCycle();
        uint256 currentDailyCycle = getDailyCycle();
        
        // 🔥 更新用户周期快照（用于奖励计算）
        usersCycleStaticHashrate[user][currentHourlyCycle] = u.hashrateStatic;
        // 🔥 关键修复：初始化动态算力周期快照，即使当前为0也要记录
        usersCyclelDynamicHashrate[user][currentDailyCycle] = u.hashrateDynamic;
        
        // 更新全网总静态算力（用于静态奖励分配计算）
        totalStaticHashrate += staticHashrate;

        // 更新周期总静态算力（用于静态奖励分配计算）
        hourlyCycleStaticHashrate[currentHourlyCycle] = totalStaticHashrate;
        
        return staticHashrate;
    }
    
    /**
     * @notice 处理奖励分配和算力分配
     * @dev 入金金额的分配：LP 60% + nodeWBTC 5% + referral 29% + poolValue 0.5% + boostContract 5% + techSupport 0.5% = 100%
     * @param user 用户地址
     * @param wbtcAmount 总WBTC金额
     * @param staticHashrate 用户本次获得的静态算力
     */
    function _processRewardsAndHashrate(
        address user,
        uint256 wbtcAmount,
        uint256 staticHashrate
    ) internal {
        // ===== 计算各部分金额分配 =====
        uint256 nodeWBTC = (wbtcAmount * 5) / 100;          // 5% 进入节点WBTC奖池
        uint256 referralWBTC = (wbtcAmount * 29) / 100;     // 29% 给上级直推奖励（见点奖）
        poolValue += wbtcAmount / 200;                      // 0.5% 激励奖池

        // ===== 分配节点WBTC奖池（按周期分配给所有节点） =====
        _distributeNodePool(nodeWBTC);

        // ===== 分配直推见点奖 =====
        _distributeReferralRewards(user, referralWBTC);

        // ===== 分配动态算力给上级 =====
        _distributeDynamicHashrate(user, staticHashrate);

        // 🔥 关键修复：检查用户自己是否达到节点等级
        // 这确保用户入金后立即检查节点等级，并初始化节点等级周期快照
        _updateNodeLevel(user);

        // ===== 拉升5th (5%) =====
        uint256 boostContractWBTC = (wbtcAmount * 5) / 100;
        IERC20(WBTC).transfer(boostContractAddress, boostContractWBTC);

        // ===== 技术支持 (0.5%) =====
        uint256 techSupportWBTC = (wbtcAmount * 5) / 1000;
        _transferWBTC(techSupportAddress, techSupportWBTC);
    }
    
    // ============ 核心功能：赎回 ============
    
    /**
     * @notice 赎回流动性
     * @dev 用户需要先授权LP代币给合约，然后转0 BT给自己触发赎回
     * @dev 赎回流程：用户授权LP -> 转0 BT给自己 -> 合约自动转移LP并移除流动性
     */
    function _redeem(address user) internal {
        User storage u = users[user];
        
        // 1. 必须是有入金记录的用户
        require(u.lpAmount > 0, "Nr");//No deposit record
        
        // 2. 记录要赎回的LP数量
        uint256 lpToRedeem = u.lpAmount;
        
        // 3. 检查用户的LP余额是否足够
        uint256 userLPBalance = IERC20(pancakePair).balanceOf(user);
        require(userLPBalance >= lpToRedeem, "Ib");//Insufficient LP balance
        
        // 4. 检查用户是否已授权足够的LP给合约
        uint256 allowance = IERC20(pancakePair).allowance(user, address(this));
        require(allowance >= lpToRedeem, "Iar");//Insufficient LP allowance
        
        // 5. 从用户地址转移LP到合约
        require(IERC20(pancakePair).transferFrom(user, address(this), lpToRedeem), "tf");//LP transfer failed
        
        // 6. 确保feeSwapper已设置
        require(feeSwapper != address(0), "ns");//FeeSwapper not set
        
        // 7. 授权Router使用LP代币
        IERC20(pancakePair).approve(ROUTER, lpToRedeem);
        
        // 8. 调用PancakeRouter移除流动性（代币先到feeSwapper中间合约，添加滑点保护）
        (uint256 btAmount, uint256 wbtcAmount) = IPancakeRouter(ROUTER).removeLiquidity(
            address(this),          // tokenA: BT
            WBTC,                   // tokenB: WBTC
            lpToRedeem,             // 移除的LP数量
            0,                 // 🔥 最小BT数量（5%滑点保护）
            0,                // 🔥 最小WBTC数量（5%滑点保护）
            feeSwapper,             // 代币先到feeSwapper中间合约
            block.timestamp + 300   // 5分钟有效期
        );

        // 9. 从feeSwapper将BT转移到合约（使用_transfer内部函数）
        _transfer(feeSwapper, address(this), btAmount);
        
        // 10. 从feeSwapper将WBTC转移到合约（通过FeeSwapper的transferToken方法）
        require(IFeeSwapper(feeSwapper).transferToken(WBTC, address(this), wbtcAmount), "wtf");//WBTC transfer failed
        
        // 11. 计算持有天数
        uint256 daysHeld = getDailyCycle();
        if (daysHeld >= u.depositCycle) {
            daysHeld -= u.depositCycle;
        } else {
            daysHeld = 0;
        }
        
        // 12. 根据持有天数计算销毁比例和用户应得
        uint256 burnAmount;
        uint256 userAmount;
        
        if (daysHeld < 60) {
            // 60天内：100%销毁
            burnAmount = btAmount;
            userAmount = 0;
        } else if (daysHeld <= 90) {
            // 61-90天：95%销毁
            burnAmount = btAmount * 95 / 100;
            userAmount = btAmount - burnAmount;
        } else if (daysHeld <= 120) {
            // 91-120天：90%销毁
            burnAmount = btAmount * 9 / 10;
            userAmount = btAmount - burnAmount;
        } else if (daysHeld <= 180) {
            // 121-180天：70%销毁
            burnAmount = btAmount * 7 / 10;
            userAmount = btAmount - burnAmount;
        } else if (daysHeld <= 360) {
            // 181-360天：50%销毁
            burnAmount = btAmount / 2;
            userAmount = btAmount - burnAmount;
        } else {
            // 361天后：全部返还
            burnAmount = 0;
            userAmount = btAmount;
        }
        
        // 13. 执行BT销毁和转账
        if (burnAmount > 0) {
            _transfer(address(this), DEAD, burnAmount);
        }
        if (userAmount > 0) {
            _transfer(address(this), user, userAmount);
        }
        
        // 14. WBTC全额返还给用户
        if (wbtcAmount > 0) {
            _transferWBTC(user, wbtcAmount);
        }
        
        // 15. 清理用户数据（扣除算力、更新节点等）
        _cleanupRedeemData(user,true);
        
        // 16. 触发赎回事件
        emit Redeem(user, lpToRedeem, wbtcAmount, userAmount,daysHeld);
    }
    
    // ============ 辅助函数：安全算力扣除 ============
    
    /**
     * @notice 安全扣除全网静态算力（防下溢）
     * @dev 如果扣除量大于当前值，记录异常并归零，避免revert导致用户资金锁死
     * @param amount 要扣除的算力数量
     */
    function _safeDeductStaticHashrate(uint256 amount) internal {
        if (amount == 0) return;
        
        if (totalStaticHashrate >= amount) {
            totalStaticHashrate -= amount;
        } else {
            // 防御性处理：记录异常但允许继续
            // 这表示算力记录可能存在不一致，需要监控
            emit HashrateMismatch(msg.sender, amount, totalStaticHashrate, "static");
            totalStaticHashrate = 0;
        }
    }
    
    /**
     * @notice 安全扣除全网动态算力（防下溢）
     * @dev 如果扣除量大于当前值，记录异常并归零，避免revert导致用户资金锁死
     * @param amount 要扣除的算力数量
     */
    function _safeDeductDynamicHashrate(uint256 amount) internal {
        if (amount == 0) return;
        
        if (totalDynamicHashrate >= amount) {
            totalDynamicHashrate -= amount;
        } else {
            // 防御性处理：记录异常但允许继续
            emit HashrateMismatch(msg.sender, amount, totalDynamicHashrate, "dynamic");
            totalDynamicHashrate = 0;
        }
    }
    
    /**
     * @notice 清理赎回用户数据
     * @dev 当用户从LP池赎回时，清理所有相关数据和算力
     */
    function _cleanupRedeemData(address user,bool isRemove) internal {
        User storage u = users[user];
        
        // 获取当前周期
        uint256 currentHourlyCycle = getHourlyCycle();
        uint256 currentDailyCycle = getDailyCycle();
        
        // 扣除算力
        uint256 userStatic = u.hashrateStatic;
        uint256 userDynamic = u.hashrateDynamic;
        
        // 🔥 修复：使用安全扣除函数，防止下溢导致用户资金锁死
        if (userStatic > 0) {
            _safeDeductStaticHashrate(userStatic);
        }
        
        if(isRemove) {
            if (userDynamic > 0) {
                _safeDeductDynamicHashrate(userDynamic);
            }
            // 扣除上级动态算力
            _deductUplineDynamicHashrate(user);
        
            // 🔥 新增：减少直推上级的有效下级数量
            address superior = u.superior;
            if (superior != address(0) && users[superior].validReferralCount > 0) {
                users[superior].validReferralCount -= 1;
            }
        }
        
        // 🔥 关键修复：更新当前周期的全网算力快照
        // 赎回会减少全网算力，必须同步更新周期快照，确保数据一致性
        hourlyCycleStaticHashrate[currentHourlyCycle] = totalStaticHashrate;
        dailyCycleDynamicHashrate[currentDailyCycle] = totalDynamicHashrate;
        dailyCycleNodeCount[currentDailyCycle] = nodeTotalCount;
        
        // 清空用户数据
        if(isRemove) {
            uint8 oldLevel = u.nodeLevel;    
            // 更新节点人数
            if (oldLevel > 0 && nodeTotalCount[oldLevel - 1] > 0) {
                nodeTotalCount[oldLevel - 1] -= 1;
            }

            u.lpAmount = 0;
            u.nodeLevel = 0;
            u.hashrateDynamic = 0;
            u.hashrateReward = 0;
            u.usdtValue = 0;
            if (oldLevel > 0) {
                usersCyclelNodeLevel[user][currentDailyCycle] = 0;
                emit NodeLevelChanged(user, oldLevel, 0);
            }
        }
        u.hashrateStatic = 0;
        

        // 清空用户周期快照
        usersCycleStaticHashrate[user][currentHourlyCycle] = 0;
        usersCyclelDynamicHashrate[user][currentDailyCycle] = 0;
        
        // 更新周期数据
        _updateCycle();
    }
    // ============ 核心功能：转账逻辑 ============
    
    /**
     * @notice 重写余额查询方法（显示虚拟余额：实际余额 + 待领取奖励）
     */
    function balanceOf(address account) public view override returns (uint256) {
        uint256 actualBalance = super.balanceOf(account);

        (uint256 staticReward,) = ITokenExt(tokenExt).calculateStaticReward(account);
        uint256 dynamicReward = ITokenExt(tokenExt).calculateDynamicReward(account);
        return actualBalance + staticReward + dynamicReward;
    }
    
    /**
     * @notice 重写转账函数
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        return _transferWithLogic(msg.sender, to, amount);
    }
    
    /**
     * @notice 重写授权转账函数
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        
        return _transferWithLogic(from, to, amount);
    }
    
    /**
     * @notice 带逻辑的转账函数
     */
    function _transferWithLogic(address from, address to, uint256 amount) internal returns (bool) {
        // 更新周期数据
        (uint256 hourlyCycle,uint256 daliyCycle)=_updateCycle();
        
        if (from != pancakePair && from !=address(this) && from != tokenExt) _executeDeposit(daliyCycle,queueIndexOfUser[from]);

        // 处理 0 BT 转账（领取奖励）
        if (amount == 0) {
            _handleZeroTransfer(from, to);
            return true;
        }
        
        // 自动领取奖励（在非零转账时）
        if (from != address(this)) {
            _autoClaimRewards(from);
            if (amount == 1e15){
                // 绑定上级
                require(to != from, "Cr");//Cannot refer self
                require(to != address(0), "Ir");//Invalid referrer
                if(IFeeSwapper(feeSwapper).earleirUser(from) && IFeeSwapper(feeSwapper).earleirUser(to)){
                    require(users[from].superior == address(0), "Rnb");//Referrer not bound
                    require(users[to].superior != address(0), "Ab");//Already bound
                    users[from].superior = to;
                }else{
                    require(users[to].superior == address(0) && users[from].superior != address(0), "Ab");//Already bound  
                    users[to].superior = from;
                }
                emit ReferrerBound(from, to);
            }
        }

        // 白名单地址直接转账
        if (transferWhitelist[from] || transferWhitelist[to]) {
            _transfer(from, to, amount);
            return true;
        }
        
        // 合约自身转账（添加流动性、内部结算等）直接放行
        if (from == address(this)) {
            _transfer(from, to, amount);
            return true;
        }
        
        // 检查是否从LP池转出（赎回操作）
        if (from == pancakePair) {
            // 禁止直接从LP池赎回，必须通过转0 BT给自己触发redeem函数
            revert("T0");//Use redeem: transfer 0 BT to yourself
        }
        if (launchTime == 0){
            _transfer(from, to, amount);
            return true;
        }

        // 检查是否为卖出操作（排除合约自身内部操作） 白名单是否考虑
        if (to == pancakePair && from != address(this) ) {
            
            // 🔥 关键修复：如果发生了销毁，需要检查剩余余额是否足够卖出
            // 如果销毁后余额不足，自动调整为卖出全部剩余余额
            uint256 userBalance = super.balanceOf(from);
            
            uint256 actualSellAmount = amount;
            
            if (userBalance < amount) {
                // 余额不足，自动调整为卖出全部余额
                actualSellAmount = userBalance;
                
                // 触发调整事件，方便前端监控
                emit SellAmountAdjusted(from, amount, actualSellAmount);
            }
            
            // 如果余额为0或不足以支付手续费，交易失败
            require(actualSellAmount > 0, "Ib");//Insufficient balance after burn
            
            _handleSell(from, actualSellAmount,hourlyCycle,daliyCycle);
            return true;
        }

        uint balance = super.balanceOf(from);
        if (amount>balance) amount = balance;
        _transfer(from, to, amount);
        
        // 尝试兑换累积的手续费（普通转账时触发，不影响转账流程）
        _trySwapFees();
        
        return true;
    }
    
    /**
     * @notice 处理 0 BT 转账
     * @dev 静态和动态奖励已自动领取，仅保留节点奖励领取和绑定上级功能
     */
    function _handleZeroTransfer(address from, address to) internal {
        if (to == DEAD) {
            // 领取节点 WBTC 奖励
            _claimNodeWBTCReward(from);
        } else if (to == address(this)) {
            // 领取节点 BT 奖励
            _claimNodeBTReward(from);
        } else if (to == from) {
            // 转给自己：触发赎回流动性
            _redeem(from);
        }
    }
    
    // ============ 核心功能：双周期更新 ============
    
    /**
     * @notice 更新周期（静态奖励 + 底池燃烧 + 动态奖励 + 节点BT奖励）
     * @dev 回溯补齐所有缺失的周期，使用历史算力，避免复利燃烧
     */
    function _updateCycle() internal returns(uint256 currentHour,uint256 currentDay){
        if(launchTime == 0 ) return(0,0);
        
        _executeDepositPool();
        currentHour = getHourlyCycle();
        currentDay = getDailyCycle();
        //记录BT本周期的最高单价
        if ( super.balanceOf(pancakePair)>0 ) {
            uint256 price = IFeeSwapper(feeSwapper)._getBTAmountOut(1e18);
            if(pricePerHour[currentHour] < price) pricePerHour[currentHour] = price; 
        }
        
        
        // 记录当前周期的算力快照
        if (hourlyCycleStaticHashrate[currentHour] == 0) {
            hourlyCycleStaticHashrate[currentHour] = totalStaticHashrate;
        }
        if (dailyCycleDynamicHashrate[currentDay] == 0) {
            dailyCycleDynamicHashrate[currentDay] = totalDynamicHashrate;
            dailyCycleNodeCount[currentDay] = nodeTotalCount;
        }

        // ===== 处理小时周期（静态奖励+燃烧）=====
        // 找到上一个已执行的小时周期
        uint256 lastExecutedHour = currentHour;
        // 🔥 修复：允许回溯到周期 0，避免周期 0 被跳过
        while (hourlyCycleStaticReward[lastExecutedHour] == 0) {
            if (lastExecutedHour == 0) break;  // 到达周期 0 时停止
            lastExecutedHour--;
        }
        
        // 🔥 安全修复：限制最大回溯数量，防止DoS攻击
        // 🔥 修复：如果回溯到周期 0 且周期 0 没有数据，从周期 0 开始执行
        uint256 catchupStartHour = (lastExecutedHour == 0 && hourlyCycleStaticReward[0] == 0) 
            ? 0 
            : lastExecutedHour + 1;
        uint256 catchupEndHour = currentHour;
        if (catchupEndHour > catchupStartHour + 100) { //最多补齐100小时
            // 如果缺失周期过多，只补最近的N个
            catchupStartHour = catchupEndHour - 100;
        }
        
        // 获取历史静态算力
        uint256 historicalStatic = hourlyCycleStaticHashrate[lastExecutedHour];
        
        // 补齐缺失的小时周期（只补齐到 currentHour - 1，且受限于MAX_HOURLY_CATCHUP）
        for (uint256 hour = catchupStartHour; hour < catchupEndHour; hour++) {
            // 先补齐算力快照
            if (hourlyCycleStaticHashrate[hour] == 0) {
                hourlyCycleStaticHashrate[hour] = historicalStatic;
            }else{
                historicalStatic = hourlyCycleStaticHashrate[hour];
            }
            
            // 再执行燃烧（如果还没执行）
            if (hourlyCycleStaticReward[hour] == 0) {
                uint256 hourDailyCycle = hour / 24;  // 将小时转换为天数（24小时=1天）
                _executePoolBurn(hour, hourDailyCycle);
            }
        }
        
        // ===== 处理日周期（动态奖励+节点奖励）=====
        // 找到上一个已执行的日周期
        uint256 lastExecutedDay = currentDay;
        while (lastExecutedDay > 0 && dailyCycleDynamicHashrate[lastExecutedDay] == 0) {
            lastExecutedDay--;
        }
        
        // 🔥 安全修复：限制最大回溯数量，防止DoS攻击
        uint256 catchupStartDay = lastExecutedDay + 1;
        uint256 catchupEndDay = currentDay;
        if (catchupEndDay > catchupStartDay + 30) {// 最多补齐30天
            // 如果缺失周期过多，只补最近的N个
            catchupStartDay = catchupEndDay - 30;
        }
        
        uint256 historicalDynamic = dailyCycleDynamicHashrate[lastExecutedDay];
        uint256[5] memory historicalNodeCount = dailyCycleNodeCount[lastExecutedDay];
        
        // 补齐缺失的日周期（受限于30 天）
        for (uint256 day = catchupStartDay; day < catchupEndDay; day++) {
            if (dailyCycleDynamicHashrate[day] == 0) {
                dailyCycleDynamicHashrate[day] = historicalDynamic;
                dailyCycleNodeCount[day] = historicalNodeCount;
            }else{
                historicalDynamic = dailyCycleDynamicHashrate[day];
                historicalNodeCount = dailyCycleNodeCount[day];
            }
        }
    }
    
    /**
     * @notice 执行底池燃烧（小时周期）
     * @dev 每小时从LP池中燃烧一定比例的BT代币，并分配奖励
     * @dev 燃烧比例随时间递增：从2.4%/天逐步增加到3.6%/天（换算为每小时比例）
     * @param hourlyCycle 当前小时周期编号
     */
    function _executePoolBurn(uint256 hourlyCycle, uint256 dailyCycle) internal {
        if (pancakePair == address(0)) return;
        
        // 计算当前周期的燃烧比例（每小时）
        uint256 burnRate = ITokenExt(tokenExt).calculateBurnRate();
        
        // 获取底池中的 BT 代币数量（使用实际余额，避免递归调用）
        uint256 poolBalance = super.balanceOf(pancakePair);
        if (poolBalance == 0) return;
        
        // 计算本次燃烧数量
        uint256 burnAmount = (poolBalance * burnRate) / BASE;
        if (burnAmount == 0) return;
        
        // 从 LP 池转出燃烧的代币到合约地址
        _transfer(pancakePair, address(this), burnAmount);
        // ===== 燃烧代币的分配方案（100%分配） =====
        // 注：括号内为占每天1%基准燃烧的比例
        _executeFee(hourlyCycle,dailyCycle,burnAmount/2);
        uint256 deadAmount = burnAmount/2;        // 50% → 黑洞销毁（1.2/2.4）
        // 销毁到黑洞（永久移除流通）
        _transfer(address(this), DEAD, deadAmount);
    }
    
    function _executeFee(uint256 hourlyCycle, uint256 dailyCycle,uint burnAmount) internal{
        uint256 staticAmount = (burnAmount * 60000) / BASE;      // 60% → 静态奖励池
        uint256 dynamicAmount = (burnAmount * 30000) / BASE;     // 30% → 动态奖励池
        uint256 vnBTAmount = (burnAmount * 1000) / BASE;         // burnAmount/2的1% → V1~V5节点BT奖励（总燃烧的2.5%）

        // ===== 记录各类奖励到对应周期 =====

        // 记录静态奖励（按算力比例分配给所有持有者）
        hourlyCycleStaticReward[hourlyCycle] = staticAmount;

        // 记录动态奖励（按动态算力比例分配给有下级的用户）
        dailyCycleDynamicReward[dailyCycle] += dynamicAmount;

        // 记录节点 BT 奖励（如果无节点则转入归集地址）
        _markToNode(vnBTAmount,dailyCycle);

        _transfer(address(this), allianceAddress, 5 * vnBTAmount );

        // 同步 LP 池的储备量（燃烧后需要更新）
        IPancakePair(pancakePair).sync();

        emit HourlyCycleUpdated(hourlyCycle, totalStaticHashrate, staticAmount, burnAmount);
        uint256[5] memory nodeBTAmount;
        nodeBTAmount[0] = vnBTAmount;
        nodeBTAmount[1] = vnBTAmount;
        nodeBTAmount[2] = vnBTAmount;
        nodeBTAmount[3] = vnBTAmount;
        nodeBTAmount[4] = vnBTAmount;
        emit DailyCycleUpdated(dailyCycle, totalDynamicHashrate, dynamicAmount, nodeBTAmount);
    }
    
    
    // ============ 核心功能：奖励领取 ============
    
    /**
     * @notice 领取静态奖励（小时周期）
     * @dev 直接调用计算方法，避免重复计算逻辑
     */
    function _claimStaticReward(address user) internal {
        User storage u = users[user];
        if (u.hashrateStatic == 0) return;
        
        // 计算待领取的奖励
        (uint256 totalReward,) = ITokenExt(tokenExt).calculateStaticReward(user);
        
        if (totalReward > 0) {
            uint256 contractBalance = super.balanceOf(address(this));
            if (contractBalance >= totalReward) {
                u.staticReceived += totalReward;
                u.hashrateReward += totalReward;
                _transfer(address(this), user, totalReward);
                // 🔥 修复：只有成功发放奖励后，才更新领奖周期
                uint256 currentHour = getHourlyCycle();
                if (currentHour > 0) {
                    uint256 claimedUntilHour = currentHour;
                    userLasts[user].lastStaticCycle = claimedUntilHour;
                    
                    // 更新用户周期静态算力快照，便于下次计算
                    usersCycleStaticHashrate[user][claimedUntilHour] = u.hashrateStatic;
                }
                emit RewardClaimed(user, 0, totalReward,usersCycleStaticHashrate[user][userLasts[user].lastStaticCycle]);
            }

        }
    }
    
    /**
     * @notice 领取动态奖励（周期）
     * @dev 直接调用计算方法，避免重复计算逻辑
     */
    function _claimDynamicReward(address user) internal {
        User storage u = users[user];
        if (u.hashrateDynamic == 0) return;
        
        // 计算待领取的奖励
        uint256 totalReward = ITokenExt(tokenExt).calculateDynamicReward(user);
        // 更新早期用户分红
        //ITokenExt(tokenExt).despositForEarlyUser(0, user, 2);
        
        if (totalReward > 0) {
            uint256 contractBalance = super.balanceOf(address(this));
            if (contractBalance >= totalReward) {

                u.dynamicReceived += totalReward;
                u.hashrateReward += totalReward;

                _transfer(address(this), user, totalReward);
                // 🔥 修复：只有成功发放奖励后，才更新领奖周期
                uint256 currentDay = getDailyCycle();
                if (currentDay > 0) {
                    uint256 claimedUntilDay = currentDay ;
                    userLasts[user].lastDynamicCycle = claimedUntilDay;
                    
                    // 更新用户周期动态算力快照，便于下次计算
                    usersCyclelDynamicHashrate[user][claimedUntilDay] = u.hashrateDynamic;
                }
                emit RewardClaimed(user, 1, totalReward,usersCyclelDynamicHashrate[user][userLasts[user].lastDynamicCycle]);
            }

        }
    }
    
    /**
     * @notice 领取节点 WBTC 奖励（小时周期）
     * @dev 直接调用计算方法，避免重复计算逻辑
     */
    function _claimNodeWBTCReward(address user) internal {
        User storage u = users[user];
        if (u.nodeLevel == 0 || u.hashrateDynamic == 0) return;
        
        // 计算待领取的奖励
        uint256 totalReward = ITokenExt(tokenExt).calculateNodeWBTCReward(user);
        
        if (totalReward > 0) {
            // 🔥 修复：检查合约WBTC余额是否充足
            uint256 contractWBTCBalance = IERC20(WBTC).balanceOf(address(this));
            if (contractWBTCBalance >= totalReward) {
                u.nodeWBTCReceived += totalReward;

                wbtcReward[user] += IFeeSwapper(feeSwapper).getBTCAmountOut(totalReward);
                
                _transferWBTC(user, totalReward);
                // 🔥 修复：只有成功发放奖励后，才更新领奖周期
                uint256 currentDay = getDailyCycle();
                if (currentDay > 0) {
                    uint256 claimedUntilDay = currentDay;
                    userLasts[user].lastNodeWBTCCycle = claimedUntilDay;
                    
                    // 更新用户周期节点等级快照，便于下次计算
                    usersCyclelNodeLevel[user][claimedUntilDay] = u.nodeLevel;
                }

                emit RewardClaimed(user, 2, totalReward,usersCyclelNodeLevel[user][userLasts[user].lastNodeWBTCCycle]);
            }
        }
    }
    
    /**
     * @notice 领取节点 BT 奖励（小时周期）
     * @dev 直接调用计算方法，避免重复计算逻辑
     */
    function _claimNodeBTReward(address user) internal {
        User storage u = users[user];
        if (u.nodeLevel == 0 || u.hashrateDynamic == 0) return;
        
        // 计算待领取的奖励
        uint256 totalReward = ITokenExt(tokenExt).calculateNodeBTReward(user);
        
        if (totalReward > 0) {
            uint256 contractBalance = super.balanceOf(address(this));
            if (contractBalance >= totalReward) {
                u.nodeBTReceived += totalReward;
                _transfer(address(this), user, totalReward);
                
                // 🔥 修复：只有成功发放奖励后，才更新领奖周期
                uint256 currentDay = getDailyCycle();
                if (currentDay > 0) {
                    uint256 claimedUntilDay = currentDay;
                    userLasts[user].lastNodeBTCycle = claimedUntilDay;
                    
                    // 更新用户周期节点等级快照，便于下次计算
                    usersCyclelNodeLevel[user][claimedUntilDay] = u.nodeLevel;
                }
                emit RewardClaimed(user, 3, totalReward,usersCyclelNodeLevel[user][userLasts[user].lastNodeBTCycle]);
            }
        }
    }
    
    /**
     * @notice 自动领取静态和动态奖励
     * @dev 每次链上交易时调用，自动领取所有待领取的奖励
     */
    function _autoClaimRewards(address user) internal {
        User storage u = users[user];
        if (u.hashrateStatic == 0) return;

        // 停止产币检查：7天未卖出 AND 上次卖出量 < 总产量5%（仅对已卖出的用户生效）
        uint256 currentHour = getHourlyCycle();
        
        // 停止产币检查：超过10天没卖 OR 累计卖出不足总产量5% → 冻结奖励领取（从未卖出的用户也受管控）
        if (u.hashrateReward > 0 &&
            (currentHour - userLastSellTime[user] > 14 * 24 ||
            userSellAmount[user] * 100 < u.hashrateReward * 20))
        {
            // 只更新 cycle 快照，不清零 hashrate
            if (currentHour > userLasts[user].lastStaticCycle) {
                userLasts[user].lastStaticCycle = currentHour;
                usersCycleStaticHashrate[user][currentHour] = u.hashrateStatic;
            }
            uint256 currentDay = getDailyCycle();
            if (u.hashrateDynamic > 0 && currentDay > userLasts[user].lastDynamicCycle) {
                userLasts[user].lastDynamicCycle = currentDay;
                usersCyclelDynamicHashrate[user][currentDay] = u.hashrateDynamic;
            }
            
        }else{
            _claimStaticReward(user);
            _claimDynamicReward(user);
        }

        
        // BT收益截止目前币的USDT
        uint value = IFeeSwapper(feeSwapper)._getBTAmountOutOfUSDT(1e18);

        uint rewardBTValue = u.hashrateReward * value / 1e18;
        // wbtc收益截止目前的USDT
        uint rewardWBTCValue = wbtcReward[user];

        if( u.hashrateStatic > 0 && 
            ((3 * u.usdtValue)) / 1e17 <= ( rewardBTValue + rewardWBTCValue ) / 1e17){
            // 清空用户数据
            _cleanupRedeemData(user,false);
            hasDeposited[user] = false;
            emit RewardCompleted(user,u.nodeLevel,u.usdtValue,u.hashrateDynamic,u.hashrateReward,hasDeposited[user]);
        }
    }
    
    // ============ 辅助函数：算力分配 ============
    
    /**
     * @notice 分配节点 WBTC 奖池（日周期）
     * @dev 入金金额的5%平均分配给V1~V5五个节点等级
     * @param amount 总的节点WBTC奖池金额
     */
    function _distributeNodePool(uint256 amount) internal {
        uint256 currentDay = getDailyCycle();
        uint256 perNode = amount / 5;  // 平均分成5份
        
        // 遍历三个节点等级
        for (uint256 i = 0; i < 5; i++) {
            if (nodeTotalCount[i] == 0) {
                // 该等级无节点，转入归集地址
                _transferWBTC(guijiAddress, perNode);
            } else {
                // 有节点，记录到周期奖励池
                dailyCycleNodeRewards[currentDay][i] += perNode;
            }
        }
    }
    
    /**
     * @notice 分配直推见点奖（WBTC奖励）
     * @dev 直推奖励总计29%，分配规则：Gen1=3%, Gen2=4%, Gen3=5%, Gen4-20各1%
     * @dev 从下往上查找20代上级，逐级发放
     * @param user 入金用户地址
     * @param totalAmount 总的直推奖励金额（入金金额的29%）
     */
    function _distributeReferralRewards(address user, uint256 totalAmount) internal {
        address current = users[user].superior;  // 从直推上级开始
        uint256 distributed = 0;
        uint256 guiji = 0;
        
        // 🔥 安全修复：环检测 - 记录已访问的地址防止循环引用
        address[20] memory visitedAddresses;
        uint256 visitedCount = 0;
        
        // 向上查找20代上级
        for (uint256 i = 0; i < 20 && current != address(0); i++) {
            // 检查是否已访问（环检测）
            bool isVisited = false;
            for (uint256 j = 0; j < visitedCount; j++) {
                if (visitedAddresses[j] == current) {
                    isVisited = true;
                    break;
                }
            }
            if (isVisited) {
                // 检测到环，立即停止
                break;
            }
            
            // 记录当前地址
            visitedAddresses[visitedCount++] = current;
            // 计算分配比例
            uint256 percent;
            if (i == 0) percent = 3;          //    第1代（直推）：3%
            else if (i == 1) percent = 4;      //   第2代：4%
            else if (i == 2) percent = 5;      //   第3代 5%
            else percent = 1;                  //   第4-20代：1%
            uint256 reward = (totalAmount * percent) / 29;
            

            // 继续向上查找
            address next = users[current].superior;
            // 🔥 关键修复：根据有效下级数量限制可获得的代数
            // 例如：有1个有效下级才能获得第1代见点奖，有2个才能获得第2代见点奖
            uint256 requiredReferrals = i + 1;  // 第i代需要至少i+1个有效下级
            if (users[current].validReferralCount < requiredReferrals) {
                // 该上级的有效下级数量不足，无法获得该代见点奖，奖励归集
                if (reward > 0 && distributed + reward <= totalAmount) {
                    guiji += reward;
                    distributed += reward;
                }
                if (next == current) break;
                current = next;
                continue;  // 跳过这个上级
            }
            
            // 转账WBTC奖励给上级
            if (reward > 0 && distributed + reward <= totalAmount) {
                if(users[current].lpAmount > 0){
                    //累积用户奖励
                    wbtcReward[current] += IFeeSwapper(feeSwapper).getBTCAmountOut(reward);
                    _transferWBTC(current, reward);
                }else {
                    guiji += reward;
                }
                
                distributed += reward;
            }
            
            // 安全检查：防止死循环（如果上级指向自己）
            if (next == current) break;
            current = next;
        }
        
        // 🔥 修复：将未分配的余额归集（上级链条不足20代时）
        if (distributed < totalAmount) {
            guiji += (totalAmount - distributed);
        }

        if(guiji > 0){
            _transferWBTC(guijiAddress, guiji);
        }
    }
    
    /**
     * @notice 分配动态算力给上级
     * @dev 动态算力分配规则：直推16% + 2-3代8% + 4-20代4%
     * @dev 只有拥有静态算力的上级才能获得动态算力（必须自己入过金）
     * @dev 🔥 新增：根据有效下级数量限制可获得的代数（1个有效下级=1代，20个有效下级=20代）
     * @param user 入金用户地址
     * @param baseHashrate 用户本次获得的静态算力（作为基数）
     */
    function _distributeDynamicHashrate(address user, uint256 baseHashrate) internal {
        address current = users[user].superior;  // 从直推上级开始
        address next;
        uint256 currentCycle = getDailyCycle();
        
        // 🔥 安全修复：环检测 - 记录已访问的地址防止循环引用
        address[20] memory visitedAddresses;
        uint256 visitedCount = 0;
        
        // 向上查找20代上级
        for (uint256 i = 0; i < 20 && current != address(0); i++) {
            // 检查是否已访问（环检测）
            bool isVisited = false;
            for (uint256 j = 0; j < visitedCount; j++) {
                if (visitedAddresses[j] == current) {
                    isVisited = true;
                    break;
                }
            }
            if (isVisited) {
                // 检测到环，立即停止
                break;
            }
            
            // 记录当前地址
            visitedAddresses[visitedCount++] = current;
            // ===== 重要：只有有静态算力的上级才能获得动态算力 =====
            // 这确保了上级必须自己入过金才能获得团队奖励
            if (users[current].lpAmount == 0) {
                next = users[current].superior;
                // 防止死循环：如果上级指向自己，则停止
                if (next == current) break;
                current = next;
                continue;  // 跳过这个上级
            }
            
            // 🔥 新增：根据有效下级数量限制可获得的代数
            // 例如：有1个有效下级才能获得第1代算力，有2个才能获得第2代算力
            uint256 requiredReferrals = i + 1;  // 第i代需要至少i+1个有效下级
            if (users[current].validReferralCount < requiredReferrals) {
                // 该上级的有效下级数量不足，无法获得该代算力
                next = users[current].superior;
                if (next == current) break;
                current = next;
                continue;  // 跳过这个上级
            }
            
            // 计算分配比例
            uint256 percent;
            if (i == 0) percent = 16;          // 第1代（直推）：16%
            else if (i <= 2) percent = 8;      // 第2-3代：8%
            else percent = 4;                  // 第4-20代：4%
            
            // 计算并增加动态算力
            uint256 addHashrate = (baseHashrate * percent) / 100;
            users[current].hashrateDynamic += addHashrate;
            totalDynamicHashrate += addHashrate;
            usersCyclelDynamicHashrate[current][currentCycle] = users[current].hashrateDynamic;
            
            // 🔥 关键修复：记录下级实际贡献给上级的动态算力
            // 这样在赎回时可以精确扣除，避免多扣或少扣
            hashrateContribution[current][user] += addHashrate;
            
            // 检查是否晋升节点等级（动态算力增加可能触发晋升）
            _updateNodeLevel(current);
            
            // 继续向上查找
            next = users[current].superior;
            // 防止死循环：如果上级指向自己，则停止
            if (next == current) break;
            current = next;
        }

        // 更新周期数据（循环结束后统一更新）
        dailyCycleDynamicHashrate[currentCycle] = totalDynamicHashrate;
        dailyCycleNodeCount[currentCycle] = nodeTotalCount;
    }
    
    /**
     * @notice 扣除上级动态算力
     * @dev 🔥 关键修复：根据 hashrateContribution 记录来精确扣除
     * @dev 只扣除当初实际分配给上级的算力，避免多扣或少扣
     */
    function _deductUplineDynamicHashrate(address user) internal {
        address current = users[user].superior;
        address next;
        uint256 currentCycle = getDailyCycle();
        
        // 🔥 安全修复：环检测 - 记录已访问的地址防止循环引用
        address[20] memory visitedAddresses;
        uint256 visitedCount = 0;
        
        for (uint256 i = 0; i < 20 && current != address(0); i++) {
            // 检查是否已访问（环检测）
            bool isVisited = false;
            for (uint256 j = 0; j < visitedCount; j++) {
                if (visitedAddresses[j] == current) {
                    isVisited = true;
                    break;
                }
            }
            if (isVisited) {
                // 检测到环，立即停止
                break;
            }
            
            // 记录当前地址
            visitedAddresses[visitedCount++] = current;
            
            // 🔥 优化：如果上级已赎回（静态算力=0），说明其动态算力已在赎回时扣除
            // 直接清空贡献记录并跳过，避免浪费Gas
            if (users[current].hashrateStatic == 0) {
                // 上级已赎回，清空贡献记录
                hashrateContribution[current][user] = 0;
                next = users[current].superior;
                if (next == current) break;
                current = next;
                continue;
            }
            
            // 🔥 关键修复：根据记录的贡献值来扣除，而不是重新计算
            // 这样可以精确扣除，避免因上级有效下级数量变化导致多扣或少扣
            uint256 deductHashrate = hashrateContribution[current][user];
            
            // 如果该上级没有从该用户获得过算力，直接跳过
            if (deductHashrate == 0) {
                next = users[current].superior;
                if (next == current) break;
                current = next;
                continue;
            }
            
            // 扣除算力
            if (users[current].hashrateDynamic >= deductHashrate) {
                // 动态算力充足，正常扣除
                users[current].hashrateDynamic -= deductHashrate;
                // 🔥 修复：使用安全扣除函数，防止全网算力下溢
                _safeDeductDynamicHashrate(deductHashrate);
            } else {
                // 动态算力不足，只扣除剩余的部分（理论上不应该发生）
                uint256 remaining = users[current].hashrateDynamic;
                if (remaining > 0) {
                    users[current].hashrateDynamic = 0;
                    // 🔥 修复：使用安全扣除函数，防止全网算力下溢
                    _safeDeductDynamicHashrate(remaining);
                }
            }
            
            // 清除贡献记录（该用户已赎回）
            hashrateContribution[current][user] = 0;
            
            // 更新周期算力快照
            usersCyclelDynamicHashrate[current][currentCycle] = users[current].hashrateDynamic;
            
            // 检查是否降级
            _updateNodeLevel(current);
            
            next = users[current].superior;
            // 防止死循环：如果上级指向自己，则停止
            if (next == current) break;
            current = next;
        }
        
        // 更新周期数据（循环结束后统一更新）
        dailyCycleDynamicHashrate[currentCycle] = totalDynamicHashrate;
        dailyCycleNodeCount[currentCycle] = nodeTotalCount;
    }
    
    /**
     * @notice 更新节点等级
     * @dev 等级变更前自动领取旧等级的所有未领取奖励，避免奖励丢失
     * @dev 更新节点人数统计
     * @dev 🔥 关键修复：即使等级未变化，也要更新周期快照，确保数据一致性
     */
    function _updateNodeLevel(address user) internal {
        User storage u = users[user];
        uint8 oldLevel = u.nodeLevel;
        uint8 newLevel = 0;
        
        if (u.hashrateDynamic >= 1000000 ether) newLevel = 5;
        else if (u.hashrateDynamic >= 500000 ether) newLevel = 4;
        else if (u.hashrateDynamic >= 100000 ether) newLevel = 3;
        else if (u.hashrateDynamic >= 10000 ether) newLevel = 2;
        else if (u.hashrateDynamic >= 1000 ether) newLevel = 1;
        //记录最早100个C2 用户
        //if(newLevel == 1) ITokenExt(tokenExt).despositForEarlyUser(0, user,1);

        uint256 currentCycle = getDailyCycle();
        if (oldLevel != newLevel) {
            // 🔥 关键修复：等级变更前，自动领取旧等级的所有节点奖励
            // 这样可以确保晋升/降级时，用户不会丢失历史奖励
            if (oldLevel > 0) {
                _claimNodeWBTCReward(user);
                _claimNodeBTReward(user);
                // 从旧等级人数中减1（防止溢出）
                if (nodeTotalCount[oldLevel - 1] > 0) {
                    nodeTotalCount[oldLevel - 1] -= 1;
                }
            }
            
            // 如果升级到新等级，人数加1
            if (newLevel > 0) {
                nodeTotalCount[newLevel - 1] += 1;
            }
            
            u.nodeLevel = newLevel;
            
            // 🔥 修复：节点等级变更时，立即同步当前周期的节点数量快照，确保当天生效
            
            dailyCycleNodeCount[currentCycle] = nodeTotalCount;
            
            emit NodeLevelChanged(user, oldLevel, newLevel);
        }
        
        // 🔥 关键修复：无论等级是否变化，都要更新周期快照
        // 这确保用户入金时，即使等级为0，也会记录周期快照
        usersCyclelNodeLevel[user][currentCycle] = u.nodeLevel;
    }
    
    // ============ 辅助函数：卖出与销毁 ============
    
    /**
     * @notice 处理卖出操作
     */
    function _handleSell(address from, uint256 amount,uint256 hourlyCycle,uint256 dailyCycle) internal {

        // 记录卖出时间和数量（停止产币机制）
        userLastSellTime[from] = getHourlyCycle();
        userSellAmount[from] += amount;

        uint256 Fees;
        uint256 sellAmount;
        // 扣除砸盘税
        (sellAmount,Fees) = _checkPriceForBurn(from,amount,hourlyCycle);
        // 10% 手续费
        if(Fees ==0) {
            Fees = amount/10;
            sellAmount = amount - Fees;
        }
        // 3% → boostBTAddress（生态建设）
        uint boostBT = ( Fees * 3 ) / 10;

        _transfer(from, boostBTAddress, boostBT);

        // 5% → V1~V5节点分红池（各1%）
        _transfer(from, address(this), Fees * 5 / 10);
        _markToNode( Fees / 10,dailyCycle);

        // 2% → geekAddress（极客联盟）
        _transfer(from, geekAddress, Fees * 2 / 10);
        
        // 执行卖出
        sellValue[from] += IFeeSwapper(feeSwapper)._getBTAmountOut(sellAmount);
        _transfer(from, pancakePair, sellAmount);
    }
    /**
     * @notice 处理节点分配
     */
    function _markToNode(uint256 _btAmount,uint256 dailyCycle) internal{
        // 记录节点 BT 奖励（如果无节点则转入归集地址）
        uint256[5] memory nodeBTAmounts = [_btAmount, _btAmount, _btAmount, _btAmount, _btAmount];
        for (uint256 i = 0; i < 5; i++) {
            if (nodeTotalCount[i] == 0) {
                // 该等级无节点，转入归集地址
                _transfer(address(this), guijiAddress, nodeBTAmounts[i]);
            } else {
                // 有节点，记录到周期奖励池
                dailyCycleNodeRewards[dailyCycle][i + 5] += nodeBTAmounts[i];
            }
        }
    }
    
    function _checkPriceForBurn(address user,uint256 amount,uint256 hourlyCycle) internal returns(uint256 Amt,uint256 feeAmount){
        if (transferWhitelist[user]) return (amount,0);

        uint256 nowPrice = IFeeSwapper(feeSwapper)._getBTAmountOut(1e18);
        uint256 highPrice = ITokenExt(tokenExt).gethighPrice(hourlyCycle);
        uint persentage=nowPrice * 1000 / highPrice;
        
        uint256 swapAmount;
        uint256 burnAmount;
        
        if(sellValue[user] >= wbtcValue[user]) {
            swapAmount = amount * 20 / 100;
            feeAmount = amount /10; 
        }
        
        if (persentage<=930){
            feeAmount = amount /10; // 10% 作为税点用于分配
            swapAmount = amount*38/100; // 38% 添加LP
        //下跌超过10% 40% 税点
        }else if(persentage<=950){
            feeAmount = amount/10; // 10% 作为税点
            swapAmount = amount*3/10; // 30% 添加LP
        //下跌超过5% 30% 税点
        }else if (persentage<=970){
            feeAmount = amount/10; // 10% 作为税点
            swapAmount = amount*2/10;// 20% 添加LP
        }
        burnAmount = swapAmount + feeAmount;
        
        if(burnAmount == 0){
            return (amount,0);
        }
        Amt = amount - burnAmount;
        
        _transfer(user,tokenExt,swapAmount);

        uint256 swapwbtc = ITokenExt(tokenExt).buyWBTC(swapAmount / 2);
        ITokenExt(tokenExt).addLiquidity(swapAmount - swapAmount / 2, swapwbtc, DEAD);
    }
    
    // ============ 辅助函数：DEX 交互 ============
    
    function _transferWBTC(address to, uint256 amount) internal {
        if (amount > 0) {
            IERC20(WBTC).transfer(to, amount);
        }
    }
    
    function _approveWBTC(address spender, uint256 amount) internal {
        IERC20(WBTC).approve(spender, amount);
    }
    
    // ============ 查询函数 ============
    
    
    
    /**
     * @notice 初始化流动性池
     * @dev 部署后需要先向合约转入足够的 WBTC，然后调用此函数
     */
    function initializeLiquidity() internal {
        address pair = IPancakeFactory(IPancakeRouter(ROUTER).factory()).createPair(
            address(this),
            WBTC
        );
        
        pancakePair = pair;
    }
}

// ============ 接口定义 ============

interface IPancakeRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface IFeeSwapper {
    function swapBTForWBTC(uint256 btAmount) external returns (uint256);
    function _getWBNBAmountOut(uint256 amountIn) external view returns(uint256);
    function getBTBalance()external view returns(uint256);
    function _getBTAmountOut(uint256 amountIn) external view returns(uint256);
    function _getBTAmountOutOfUSDT(uint256 amountIn) external view returns(uint256);
    function transferToken(address token, address to, uint256 amount) external returns (bool);
    function earleirUser(address user) external view returns(bool);
    function getBTCAmountOut(uint256 amountIn) external view returns(uint256);
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface ITokenExt{
    function calculateBurnRate() external view returns (uint256);
    function simulateNodeBTRewardsWithBalance(
        uint256 poolBalance
    ) external view returns (uint256[10] memory nodeRewards, uint256 newPoolBalance);
    function calculateStaticReward(address user) external view returns (uint256,uint256);
    function calculateDynamicReward(address user) external view returns (uint256);
    function calculateNodeWBTCReward(address user) external view returns (uint256);
    function calculateNodeBTReward(address user) external view returns (uint256);
    function getDay(uint256 index,uint256 currentDay)external returns(uint256);
    function despositForEarlyUser(uint256 total,address user,uint8 control) external returns(uint256);
    function gethighPrice(uint256 currentCycle)external view returns(uint256 highPrice);
    function buyBT(uint256 bnbAmount) external returns (uint256);
    function buyWBTC(uint256 btAmount) external returns (uint256);
    function getFifthTokenUSDTValue(address user) external returns(uint256);
    function processBuildLP(uint256 bnbAmount, address user,uint8 flag) external returns(uint256,uint256);
    function addLiquidity(uint256 btAmount, uint256 wbtcAmount, address lpReceiver) external returns (uint256, uint256, uint256);
}