// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Pancake / Uniswap V2 Pair：仅使用 sync
interface IUniswapV2Pair {
    function sync() external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Pancake Router 精简接口（V2：加 DMD/USDC 池、卖 DMD 成 USDC）
interface IPancakeRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

interface IDMDLpHelper {
    function processLiquidity() external;
}

/**
 * @title DMDToken
 * @notice 单文件自包含（无外部 import），便于审计与开源。
 * @notice 总量 2100 万：100 万 LP 分配 + 2000 万共振（构造函数参数地址）
 * @dev 买卖各 3% 税；通缩：admin 可调 burnFromMainPair；卖出 1% 打到独立 lpHelper，并在当前卖单内立即补 DMD/USDC 池
 * @dev 注意：从 Pair 扣余额燃烧会稀释 LP 权益；买入默认关盘 buyEnabled，需 owner 开盘
 */
contract DMDToken {
    /* ========= 内联 ERC20（无 OpenZeppelin 依赖）========= */

    string private _name;
    string private _symbol;
    uint8 private constant _DECIMALS = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transferWithHooks(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transferWithHooks(from, to, amount);
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _spendAllowance(address owner_, address spender, uint256 amount) internal {
        uint256 cur = _allowances[owner_][spender];
        if (cur != type(uint256).max) {
            require(cur >= amount, "ALLOWANCE");
            unchecked {
                _allowances[owner_][spender] = cur - amount;
            }
        }
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "MINT_ZERO");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "BURN_ZERO");
        uint256 bal = _balances[from];
        require(bal >= amount, "BAL");
        unchecked {
            _balances[from] = bal - amount;
            _totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    /// @dev 普通余额划转（不经买卖税）
    function _transferRaw(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "ZERO");
        uint256 bal = _balances[from];
        require(bal >= amount, "BAL");
        unchecked {
            _balances[from] = bal - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /* ========= 内联 Ownable ========= */

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /* ========= 内联 ReentrancyGuard ========= */

    uint256 private _entered;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        require(_entered != _ENTERED, "REENTRANT");
        _entered = _ENTERED;
        _;
        _entered = _NOT_ENTERED;
    }

    /* ========= DMD 业务 ========= */

    uint256 public constant MAX_SUPPLY = 21_000_000 * 10 ** 18;
    uint256 public constant LP_ALLOCATION = 1_000_000 * 10 ** 18;
    uint256 public constant MIN_TOTAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant PAIR_BURN_BPS = 50;
    uint256 public constant TAX_BPS = 300;
    uint256 public constant SHARE_BPS = 100;

    address private constant BURN_ADDR = address(0x000000000000000000000000000000000000dEaD);
    address public constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public mainPair;
    address public lpHelper;

    address public marketingWallet;
    address public dividendWallet;

    uint256 public constant FOUNDATION_SLOT_CAP = 10;
    mapping(uint256 => address) public foundationBySlot;

    mapping(address => bool) public isExcludedFromFees;

    address public admin;
    bool public buyEnabled;

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event BuyEnabledUpdated(bool enabled);
    event LpHelperUpdated(address indexed oldHelper, address indexed newHelper);
    event BuyTaxProcessed(
        address indexed trader,
        address indexed receiver,
        uint256 grossAmount,
        uint256 netAmount,
        uint256 burnAmount,
        uint256 marketingAmount,
        uint256 levelDividendAmount
    );
    event SellTaxProcessed(
        address indexed trader,
        address indexed seller,
        uint256 grossAmount,
        uint256 netAmount,
        uint256 lpInjectAmount,
        uint256 daoDividendAmount,
        uint256 foundationAmount,
        uint256 foundationBurnAmount
    );
    event AutoLiquidityProcessed(
        uint256 tokenSwapped,
        uint256 usdcReceived,
        uint256 tokenAdded,
        uint256 usdcAdded,
        uint256 liquidity,
        uint256 tokenTail,
        uint256 usdcTail
    );

    error ZeroAddress();
    error PairNotSet();
    error InvalidFoundationSlot();
    error NotAdmin();
    error BuyingDisabled();
    error LpHelperNotSet();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address lpMintRecipient, address resonanceMintRecipient) {
        if (lpMintRecipient == address(0) || resonanceMintRecipient == address(0)) revert ZeroAddress();

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        _entered = _NOT_ENTERED;

        _name = "DMD";
        _symbol = "DMD";

        admin = msg.sender;

        _mint(lpMintRecipient, LP_ALLOCATION);
        _mint(resonanceMintRecipient, MAX_SUPPLY - LP_ALLOCATION);

        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[ROUTER] = true;
    }

    function setMarketingWallet(address a) external onlyOwner {
        if (a == address(0)) revert ZeroAddress();
        marketingWallet = a;
    }

    function setDividendWallet(address a) external onlyOwner {
        if (a == address(0)) revert ZeroAddress();
        dividendWallet = a;
    }

    function setFoundationSlot(uint256 slot, address a) external onlyOwner {
        if (slot >= FOUNDATION_SLOT_CAP) revert InvalidFoundationSlot();
        foundationBySlot[slot] = a;
    }

    function setMainPair(address pair) external onlyOwner {
        if (pair == address(0)) revert ZeroAddress();
        mainPair = pair;
    }

    function setLpHelper(address helper) external onlyOwner {
        emit LpHelperUpdated(lpHelper, helper);
        lpHelper = helper;
    }

    function setExcludedFromFees(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setAdmin(address newAdmin) external onlyOwner {
        if (newAdmin == address(0)) revert ZeroAddress();
        emit AdminUpdated(admin, newAdmin);
        admin = newAdmin;
    }

    function setBuyEnabled(bool enabled) external onlyOwner {
        buyEnabled = enabled;
        emit BuyEnabledUpdated(enabled);
    }

    function burnFromMainPair() external onlyAdmin nonReentrant {
        address pair = mainPair;
        if (pair == address(0)) revert PairNotSet();

        uint256 supply = totalSupply();
        if (supply <= MIN_TOTAL_SUPPLY) return;

        uint256 pairBal = balanceOf(pair);
        if (pairBal == 0) return;

        uint256 targetFromPair = (pairBal * PAIR_BURN_BPS) / 10_000;
        uint256 maxBurnByFloor = supply - MIN_TOTAL_SUPPLY;
        uint256 burnAmt = targetFromPair > maxBurnByFloor ? maxBurnByFloor : targetFromPair;
        if (burnAmt > pairBal) burnAmt = pairBal;
        if (burnAmt == 0) return;

        _burn(pair, burnAmt);
        IUniswapV2Pair(pair).sync();
    }

    function injectLiquidity() external onlyOwner nonReentrant {
        address helper = lpHelper;
        if (helper == address(0)) revert LpHelperNotSet();

        // 兼容历史尾巴：如果 token 合约里还残留旧版 LP 税 token，先转给 helper 再组池。
        uint256 tokenBal = balanceOf(address(this));
        if (tokenBal > 0) {
            _transferRaw(address(this), helper, tokenBal);
        }

        IDMDLpHelper(helper).processLiquidity();
    }

    receive() external payable {}

    function _transferWithHooks(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0)) {
            // mint/burn 仅允许内部 _mint/_burn 路径；对外 transfer 不应带 0 地址
            revert("ZERO");
        }

        address pair = mainPair;
        if (pair != address(0) && from == pair && !buyEnabled && !isExcludedFromFees[to]) {
            revert BuyingDisabled();
        }

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            _transferRaw(from, to, value);
            return;
        }

        if (pair == address(0)) {
            _transferRaw(from, to, value);
            return;
        }

        if (from == pair) {
            _handleBuy(from, to, value);
            return;
        }

        if (to == pair) {
            _handleSell(from, to, value);
            return;
        }

        _transferRaw(from, to, value);
    }

    function _handleBuy(address from, address to, uint256 value) internal {
        if (marketingWallet == address(0) || dividendWallet == address(0)) {
            _transferRaw(from, to, value);
            return;
        }

        uint256 fee = (value * TAX_BPS) / 10_000;
        uint256 s1 = (value * SHARE_BPS) / 10_000;
        uint256 s2 = (value * SHARE_BPS) / 10_000;
        uint256 s3 = fee - s1 - s2;
        uint256 toUser = value - fee;

        _burn(from, s1);
        _transferRaw(from, marketingWallet, s2);
        _transferRaw(from, dividendWallet, s3);
        _transferRaw(from, to, toUser);
        emit BuyTaxProcessed(tx.origin, to, value, toUser, s1, s2, s3);
    }

    function _handleSell(address from, address to, uint256 value) internal {
        if (dividendWallet == address(0)) {
            _transferRaw(from, to, value);
            return;
        }

        uint256 fee = (value * TAX_BPS) / 10_000;
        uint256 lpPart = (value * SHARE_BPS) / 10_000;
        uint256 divPart = (value * SHARE_BPS) / 10_000;
        uint256 fundPart = fee - lpPart - divPart;
        uint256 toPair = value - fee;
        uint256 foundationAmount;
        uint256 foundationBurnAmount;
        address helper = lpHelper;

        if (helper == address(0)) revert LpHelperNotSet();

        // 先把本次卖出税里的 1% DMD 打到 helper，并在当前卖单里立即做一次补池。
        // 这里故意放在给 Pair 转 97% 之前，避免“用户卖单进行中再次操作同一 Pair”导致外层 swap 金额计算失真。
        _transferRaw(from, helper, lpPart);
        if (lpPart > 0) {
            IDMDLpHelper(helper).processLiquidity();
        }

        _transferRaw(from, dividendWallet, divPart);

        uint256 n;
        for (uint256 i; i < FOUNDATION_SLOT_CAP; ++i) {
            if (foundationBySlot[i] != address(0)) ++n;
        }
        if (n == 0) {
            _burn(from, fundPart);
            foundationBurnAmount = fundPart;
        } else {
            foundationAmount = fundPart;
            uint256 each = fundPart / n;
            uint256 leftover = fundPart % n;
            for (uint256 i; i < FOUNDATION_SLOT_CAP; ++i) {
                address fw = foundationBySlot[i];
                if (fw == address(0)) continue;
                uint256 amt = each;
                if (leftover > 0) {
                    amt += 1;
                    unchecked {
                        --leftover;
                    }
                }
                _transferRaw(from, fw, amt);
            }
        }

        _transferRaw(from, to, toPair);
        emit SellTaxProcessed(tx.origin, from, value, toPair, lpPart, divPart, foundationAmount, foundationBurnAmount);
    }
}
