// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;
// ***************************************************************************************************
// ###################################################################################################
// ############# #####    ############################################################################
// ######  ##### #####  # ############################################################################
// ########  ### ###  ### ####    ###   ##        ##        ###  ##       ###  #####   #####   ###  ##
// ##########  # #  ##########    ##    ##  ########  ####   ##  ##  ####  ##  ####     ####    ##  ##
// ####                   ####  #  # #  ##        ##        ###  ##  ####   #  ###   ##  ###  #  #  ##
// ##########  # #  ##########  #    #  ##  ########  ###  ####  ##  ####  ##  ###        ##  ##    ##
// ########  ### ###  ########  ##  ##  ##        ##  ####   ##  ##       ###  ##  #####  ##  ###   ##
// ######  ##### #####  ##############################################################################
// ############# #####################################################################################
// ###################################################################################################
// @title Meridian Capital (MCD)
// @notice Meridian's ERC-20. Buys and sells are taxed; wallet-to-wallet transfers are not.
// @dev    Details:
// Tax: 5% buy / 5% sell; 50% to MCD/WETH liquidity, 50% to the specified teamWallet
// Launch tax: 90% at launch, declining exponentially (3 min half-life) to 5% over the first 30 minutes
// Supply: 18.6M
//     15.5M genesis supply, backing gMCD 1:1
//     1.55M team, locked 60 days, then vesting over 60 days
//     1.55M liquidity, of which 1M seeds MCD/WETH at launch
// MCD trades only on taxed pools or with approved hook on Uniswap v4
// Minting is locked for 60 days after deployment
// Built for Robinhood Chain
// ***************************************************************************************************

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {IUniswapV2Router02} from "src/interfaces/uniswap/IUniswapV2Router02.sol";
import {RobinhoodChain} from "src/libraries/RobinhoodChain.sol";
import {TransientSlot} from "src/libraries/TransientSlot.sol";

interface IWETH {
    function deposit() external payable;
}

interface IUniswapV2Factory {
    function createPair(address _tokenA, address _tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function mint(address _to) external returns (uint256 liquidity);
}

interface IGenesisFarm {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address token,
            uint256 allocPoint,
            uint256 lastRewardTime,
            uint256 accRewardPerShare,
            bool isStarted,
            uint16 depositFeeBP
        );
}

contract MCD is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using TransientSlot for bytes32;
    using TransientSlot for TransientSlot.Uint256Slot;

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(RobinhoodChain.UNISWAP_V2_ROUTER);
    uint256 private constant BPS_DENOMINATOR = 10_000;
    address public immutable uniswapV2Pair;
    address public teamWallet;
    address public liquidityWallet;

    // ======== Token allocation ========
    // Total 18.6M MCD supply minted at deployment.

    uint256 public constant GMCD_BACKING = 15_500_000e18;

    // Meridian's own deployments, not facts about the chain, so they live here rather than in
    // RobinhoodChain: that library is shared with contracts that have no business knowing them.
    // Internal, so they add no getter to the ABI; Config mirrors both and the tests hold the two
    // to each other.
    address internal constant GMCD = 0x296182D54dc5cBe6d960b9cFe3882dD5c87d51fd;
    address internal constant GENESIS_FARM = 0xE5BffCF30D18c27Dac29b2EDF8a608b2E2BB52F7;
    uint256 public constant LIQUIDITY_ALLOCATION = 1_550_000e18; // 10% of genesis
    uint256 public constant TEAM_ALLOCATION = 1_550_000e18; // 10% of genesis
    uint256 public constant INITIAL_LIQUIDITY = 1_000_000e18;

    // ======== Tax ========
    // Standard buy/sell tax capped at 5%.
    // Applies to whitelisted AMM pairs, all other transfers are untaxed (must be Uniswap V2 style, V3 unsupported).

    uint256 public constant MAX_TAX_BPS = 500;
    uint256 public buyTaxBps = 500;
    uint256 public sellTaxBps = 500;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    // ======== Launch ========
    // Exponentially decaying launch tax, starting at 90% and decaying to the normal buy/sell tax over 30 minutes.

    uint256 public constant LAUNCH_TAX_BPS = 9000;
    uint256 public constant LAUNCH_TAX_DURATION = 30 minutes;
    uint256 public constant LAUNCH_TAX_HALF_LIFE = 3 minutes;

    uint256 public launchTime;

    bool public tradingActive = false;

    // ======== Swap-back ========
    // Contract swap parameters.
    // Block.timestamp refers to L1 block, so we rate limit by timestamp.

    uint256 public constant SWAP_BACK_INTERVAL = 4 seconds; // 3 per 12s L1 block
    uint256 private constant LIQUIDITY_SHARE_BPS = 5000;

    bool private swapping;
    bool public swapEnabled = false;

    uint256 public swapTokensAtAmount;
    uint256 private constant MAX_SWAP_MULT = 20; // a round sells at most 20x swapTokensAtAmount
    uint256 private _lastSwapBackTime;

    // ======== Venues ========
    // Used for non-whitelisted V2 dex, V3 pools. Not for V4.
    // Blocked venue blocks transfers to that address, but does not prevent withdrawals.

    mapping(address => bool) public blockedVenue;

    // ======== V4 PoolManager gate ========
    // Used to whitelist approved hooks for Uniswap V4.
    // By default, all V4 is blocked, except via approved hooks, which must implement the transient storage calls

    address public constant poolManager = RobinhoodChain.UNISWAP_V4_POOL_MANAGER;
    bytes32 private constant INBOUND_BUDGET_SLOT = bytes32(uint256(keccak256("MCD.poolManager.inbound")) - 1);
    bytes32 private constant OUTBOUND_BUDGET_SLOT = bytes32(uint256(keccak256("MCD.poolManager.outbound")) - 1);
    mapping(address => bool) public isApprovedHook;
    bool public poolManagerGateEnabled = true;

    // ======== Minting ========
    // Minting is locked for 60 days after deployment, then approved minters, until minting is renounced.

    uint256 public constant MINT_LOCK_DURATION = 60 days;
    uint256 public immutable mintUnlocksAt;
    mapping(address => bool) public isMinter;
    bool public mintingRenounced;

    // ======== Team vesting ========

    /// @notice OpenZeppelin VestingWallet holding the team allocation for the team wallet.
    address public immutable teamVesting;

    // ======== Events ========

    event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event LiquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapTokensAtAmountUpdated(uint256 amount);
    event SwapEnabledUpdated(bool enabled);
    event BuyTaxUpdated(uint256 taxBps);
    event SellTaxUpdated(uint256 taxBps);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event VenueBlocked(address indexed venue, bool blocked);
    event ApprovedHookSet(address indexed hook, bool allowed);
    event PoolManagerGateSet(bool enabled);
    event PoolManagerTransferAuthorized(bool inbound, uint256 amount);
    event MinterUpdated(address indexed account, bool allowed);
    event MintingRenounced();

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MCD: caller is not a minter");
        _;
    }

    // ======== Constructor ========

    constructor(address _teamWallet, address _liquidityWallet, address _owner) ERC20("Meridian Capital", "MCD") {
        require(_teamWallet != address(0), "MCD: team wallet is zero");
        require(_liquidityWallet != address(0), "MCD: liquidity wallet is zero");
        require(_owner != address(0), "MCD: owner is zero");
        require(uniswapV2Router.WETH() == RobinhoodChain.WETH, "MCD: router weth mismatch");
        uint256 genesisSupply = IERC20(GMCD).totalSupply();
        require(genesisSupply == GMCD_BACKING, "MCD: unexpected gMCD supply");
        address pair = RobinhoodChain._uniswapV2PairFor(address(this), RobinhoodChain.WETH);
        uniswapV2Pair = pair;
        // Registers MCD's pair on Uniswap V2 with every genesis farm token, WETH included.
        uint256 length = IGenesisFarm(GENESIS_FARM).poolLength();
        for (uint256 i; i < length; ++i) {
            (address token,,,,,) = IGenesisFarm(GENESIS_FARM).poolInfo(i);
            _setAutomatedMarketMakerPair(RobinhoodChain._uniswapV2PairFor(address(this), token), true);
        }
        require(automatedMarketMakerPairs[pair], "MCD: weth is not a farm token");

        teamWallet = _teamWallet;
        liquidityWallet = _liquidityWallet;
        mintUnlocksAt = block.timestamp + MINT_LOCK_DURATION;

        excludeFromFees(_owner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(_liquidityWallet, true);
        excludeFromFees(_teamWallet, true);

        // Genesis supply: 15.5M, 1:1 against gMCD's supply.
        _mint(GMCD, genesisSupply);
        // Launch seed: 1M, paired with ETH in enableTrading.
        _mint(address(this), INITIAL_LIQUIDITY);
        // Owner: the rest of the 10% liquidity allocation (550k).
        _mint(_owner, LIQUIDITY_ALLOCATION - INITIAL_LIQUIDITY);
        // Team allocation: locked until minting unlocks, then vests linearly over the same 60 days.
        teamVesting = address(new VestingWallet(_teamWallet, uint64(mintUnlocksAt), uint64(MINT_LOCK_DURATION)));
        // Team: 10% of the genesis supply, into the vesting wallet.
        _mint(teamVesting, TEAM_ALLOCATION);

        swapTokensAtAmount = 500e18; // 0.05% of the 1M launch seed

        _transferOwnership(_owner);
    }

    /// @notice Accepts the launch ETH and the router's swap proceeds and refunds.
    receive() external payable {}

    // ======== Launch ========

    /// @notice Seeds MCD/WETH from the contract's ETH, LP to liquidityWallet, and opens trading and the launch tax.
    function enableTrading() external payable onlyOwner {
        require(!tradingActive, "MCD: trading is already active");
        tradingActive = true;
        swapEnabled = true;
        launchTime = block.timestamp;

        uint256 ethAmount = address(this).balance; // Includes msg.value + previous balance
        require(ethAmount > 0, "MCD: no launch ETH");
        require(balanceOf(address(this)) >= INITIAL_LIQUIDITY, "MCD: initial liquidity missing");
        address pair = uniswapV2Pair;
        // Seeds the pair directly rather than through the router, which reverts if someone pre-created the pair and
        // synced a donation into it; any donation is folded into the LP.
        if (pair.code.length == 0) {
            address created =
                IUniswapV2Factory(RobinhoodChain.UNISWAP_V2_FACTORY).createPair(address(this), RobinhoodChain.WETH);
            require(created == pair, "MCD: pair address mismatch");
        }
        IWETH(RobinhoodChain.WETH).deposit{value: ethAmount}();
        IERC20(RobinhoodChain.WETH).safeTransfer(pair, ethAmount);
        _transfer(address(this), pair, INITIAL_LIQUIDITY);
        IUniswapV2Pair(pair).mint(liquidityWallet);
    }

    // ======== Transfer and tax ========

    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        _checkVenue(from, to, amount);

        if (!tradingActive) {
            require(isExcludedFromFees[from] || isExcludedFromFees[to], "MCD: trading is not active");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from]
                && !isExcludedFromFees[from] && !isExcludedFromFees[to]
                && block.timestamp >= _lastSwapBackTime + SWAP_BACK_INTERVAL
        ) {
            swapping = true;
            _lastSwapBackTime = block.timestamp;

            _swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee && (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])) {
            (uint256 buyTotalFees, uint256 sellTotalFees) = _totalFees();
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / BPS_DENOMINATOR;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / BPS_DENOMINATOR;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    /// @dev The buy and sell rates in force now, in bps: the steady rates, or during the launch window one launch tax
    ///      on both sides, decaying from LAUNCH_TAX_BPS to MAX_TAX_BPS by halving every LAUNCH_TAX_HALF_LIFE, with
    ///      linear interpolation within each half-life.
    function _totalFees() internal view returns (uint256 buyTotalFees, uint256 sellTotalFees) {
        if (launchTime == 0 || block.timestamp >= launchTime + LAUNCH_TAX_DURATION) return (buyTaxBps, sellTaxBps);
        uint256 elapsed = block.timestamp - launchTime;
        uint256 n = elapsed / LAUNCH_TAX_HALF_LIFE;
        uint256 r = elapsed % LAUNCH_TAX_HALF_LIFE;
        uint256 launchTaxBps = MAX_TAX_BPS + (((LAUNCH_TAX_BPS - MAX_TAX_BPS) >> n) * (2 * LAUNCH_TAX_HALF_LIFE - r))
            / (2 * LAUNCH_TAX_HALF_LIFE);
        return (launchTaxBps, launchTaxBps);
    }

    /// @notice Fee a transfer of `_amount` from `_from` to `_to` would pay right now.
    function previewTax(address _from, address _to, uint256 _amount) external view returns (uint256) {
        if (isExcludedFromFees[_from] || isExcludedFromFees[_to]) return 0;
        (uint256 buyTotalFees, uint256 sellTotalFees) = _totalFees();
        if (automatedMarketMakerPairs[_to] && sellTotalFees > 0) return (_amount * sellTotalFees) / BPS_DENOMINATOR;
        if (automatedMarketMakerPairs[_from] && buyTotalFees > 0) return (_amount * buyTotalFees) / BPS_DENOMINATOR;
        return 0;
    }

    // ======== Swap-back ========

    function _swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance > swapTokensAtAmount * MAX_SWAP_MULT) {
            contractBalance = swapTokensAtAmount * MAX_SWAP_MULT;
        }

        if (contractBalance == 0) {
            return;
        }

        uint256 tokensForLiquidity = (contractBalance * LIQUIDITY_SHARE_BPS) / BPS_DENOMINATOR;
        uint256 tokensForTeam = contractBalance - tokensForLiquidity;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = tokensForLiquidity / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForTeam = (ethBalance * tokensForTeam) / amountToSwapForETH;

        uint256 ethForLiquidity = ethBalance - ethForTeam;

        (success,) = address(teamWallet).call{value: ethForTeam}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, liquidityTokens);
        }

        (success,) = address(teamWallet).call{value: address(this).balance}("");
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = RobinhoodChain.WETH;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this), tokenAmount, 0, 0, liquidityWallet, block.timestamp
        );
    }

    /// @notice Sets the contract balance at which a sell triggers the swap-back.
    function updateSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= (totalSupply() * 1) / 100000, "MCD: swap amount cannot be lower than 0.001% total supply");
        require(_newAmount <= (totalSupply() * 5) / 1000, "MCD: swap amount cannot be higher than 0.5% total supply");
        swapTokensAtAmount = _newAmount;
        emit SwapTokensAtAmountUpdated(_newAmount);
    }

    /// @notice Enables or disables the swap-back.
    function updateSwapEnabled(bool _enabled) external onlyOwner {
        require(tradingActive, "MCD: not launched");
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }

    // ======== Owner settings ========

    /// @notice Sets the buy tax in bps, capped at MAX_TAX_BPS; it applies once the launch window is over.
    function updateBuyFees(uint256 _buyTaxBps) external onlyOwner {
        require(_buyTaxBps <= MAX_TAX_BPS, "MCD: buy fees must be <= 500 bps");
        buyTaxBps = _buyTaxBps;
        emit BuyTaxUpdated(_buyTaxBps);
    }

    /// @notice Sets the sell tax in bps, capped at MAX_TAX_BPS; it applies once the launch window is over.
    function updateSellFees(uint256 _sellTaxBps) external onlyOwner {
        require(_sellTaxBps <= MAX_TAX_BPS, "MCD: sell fees must be <= 500 bps");
        sellTaxBps = _sellTaxBps;
        emit SellTaxUpdated(_sellTaxBps);
    }

    /// @notice Exempts `_account` from the tax on both sides, or removes the exemption.
    function excludeFromFees(address _account, bool _excluded) public onlyOwner {
        require(!(_account == address(this) && !_excluded), "MCD: cannot tax the token itself");
        require(!(_excluded && automatedMarketMakerPairs[_account]), "MCD: cannot exempt a pair");
        isExcludedFromFees[_account] = _excluded;
        emit ExcludeFromFees(_account, _excluded);
    }

    /// @notice Registers or unregisters `_pair` as an AMM pair. The main pair cannot be changed.
    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(_pair != uniswapV2Pair, "MCD: the pair cannot be removed from automatedMarketMakerPairs");
        require(_pair != poolManager, "MCD: pool manager cannot be a pair");
        require(!(_value && isExcludedFromFees[_pair]), "MCD: cannot register an exempt address as a pair");
        _setAutomatedMarketMakerPair(_pair, _value);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        automatedMarketMakerPairs[_pair] = _value;
        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    /// @notice Sets the address paid the team's half of the tax, in ETH.
    function updateTeamWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "MCD: team wallet is zero");
        address oldWallet = teamWallet;
        teamWallet = _newWallet;
        emit TeamWalletUpdated(_newWallet, oldWallet);
    }

    /// @notice Sets the address the swap-back MCD/WETH LP tokens are sent to.
    function updateLiquidityWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "MCD: liquidity wallet is zero");
        address oldWallet = liquidityWallet;
        liquidityWallet = _newWallet;
        emit LiquidityWalletUpdated(_newWallet, oldWallet);
    }

    // ======== Venue blocklist ========

    /// @notice Blocks or unblocks inbound transfers to each external venue in `_venues`.
    function setBlockedVenues(address[] calldata _venues, bool _blocked) external onlyOwner {
        for (uint256 i; i < _venues.length; ++i) {
            address venue = _venues[i];
            require(venue != address(0), "MCD: venue is zero");
            require(venue != address(this), "MCD: cannot block mcd");
            require(venue != uniswapV2Pair, "MCD: cannot block the main pair");
            require(venue != poolManager, "MCD: cannot block the pool manager");
            if (_blocked) {
                require(!automatedMarketMakerPairs[venue], "MCD: cannot block a registered pair");
                require(!isExcludedFromFees[venue], "MCD: cannot block an exempt address");
            }
            blockedVenue[venue] = _blocked;
            emit VenueBlocked(venue, _blocked);
        }
    }

    function _checkVenue(address _from, address _to, uint256 _amount) internal {
        require(!blockedVenue[_to], "MCD: blocked venue");
        if (poolManagerGateEnabled) {
            if (_to == poolManager) _consumeBudget(true, _amount);
            else if (_from == poolManager) _consumeBudget(false, _amount);
        }
    }

    // ======== V4 PoolManager gate ========

    /// @notice Allows or disallows `_hook` as an approved hook that may authorize PoolManager transfers.
    function setApprovedHook(address _hook, bool _allowed) external onlyOwner {
        require(_hook != address(0), "MCD: hook is zero");
        isApprovedHook[_hook] = _allowed;
        emit ApprovedHookSet(_hook, _allowed);
    }

    /// @notice Switches the PoolManager transfer budget check on or off.
    function setPoolManagerGate(bool _enabled) external onlyOwner {
        poolManagerGateEnabled = _enabled;
        emit PoolManagerGateSet(_enabled);
    }

    /// @notice Lets the PoolManager receive (`_inbound`) or send `_amount` more MCD this transaction; hooks only.
    function authorizePoolManagerTransfer(bool _inbound, uint256 _amount) external {
        require(isApprovedHook[msg.sender], "MCD: caller is not an approved hook");
        TransientSlot.Uint256Slot slot = _budgetSlot(_inbound);
        slot.tstore(slot.tload() + _amount);
        emit PoolManagerTransferAuthorized(_inbound, _amount);
    }

    /// @notice Transfer budget the PoolManager may still receive (`_inbound`) or send in this transaction.
    function poolManagerTransferBudget(bool _inbound) external view returns (uint256) {
        return _budgetSlot(_inbound).tload();
    }

    function _consumeBudget(bool _inbound, uint256 _amount) internal {
        TransientSlot.Uint256Slot slot = _budgetSlot(_inbound);
        uint256 budget = slot.tload();
        require(_amount <= budget, "MCD: unauthorized pool manager transfer");
        slot.tstore(budget - _amount);
    }

    function _budgetSlot(bool _inbound) internal pure returns (TransientSlot.Uint256Slot) {
        return (_inbound ? INBOUND_BUDGET_SLOT : OUTBOUND_BUDGET_SLOT).asUint256();
    }

    // ======== Minting ========

    /// @notice Grants or revokes the minter role for `_account`.
    function setMinter(address _account, bool _allowed) external onlyOwner {
        require(_account != address(0), "MCD: account is zero");
        isMinter[_account] = _allowed;
        emit MinterUpdated(_account, _allowed);
    }

    /// @notice Permanently disables `mint`.
    function renounceMinting() external onlyOwner {
        require(!mintingRenounced, "MCD: minting already renounced");
        mintingRenounced = true;
        emit MintingRenounced();
    }

    /// @notice Renounces minting and ownership, permanently, and opens V4; only after launch.
    function renounceOwnership() public override onlyOwner {
        require(tradingActive, "MCD: not launched");
        if (!mintingRenounced) {
            mintingRenounced = true;
            emit MintingRenounced();
        }
        // With no owner left to manage hooks, V4 opens rather than risk MCD staying stuck in a hook's pools.
        if (poolManagerGateEnabled) {
            poolManagerGateEnabled = false;
            emit PoolManagerGateSet(false);
        }
        super.renounceOwnership();
    }

    /// @notice Mints `_amount` MCD to `_to` once `mintUnlocksAt` has passed and until minting is renounced.
    function mint(address _to, uint256 _amount) external onlyMinter {
        require(!mintingRenounced, "MCD: minting renounced");
        require(block.timestamp >= mintUnlocksAt, "MCD: minting locked");
        require(_to != address(0), "MCD: to is zero");
        require(_amount > 0, "MCD: amount cannot be null");
        _mint(_to, _amount);
    }

    /// @notice Burns `_amount` MCD from the caller, reducing totalSupply.
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
