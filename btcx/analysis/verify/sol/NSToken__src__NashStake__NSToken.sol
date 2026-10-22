// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { INashV2Factory } from "./interfaces/INashV2Factory.sol";
import { INashV2Pair } from "./interfaces/INashV2Pair.sol";
import { INashV2Router } from "./interfaces/INashV2Router.sol";
import { NashStakeLibrary } from "./library/NashStakeLibrary.sol";

contract NSToken is ERC20, Ownable {
    error InvalidAddress();
    error InvalidValue();
    error InvalidPair();
    error InvalidState();
    error FeeProcessingFailed();
    error Unauthorized();
    error PairBurnCooldownActive();

    event TaxRatesUpdated(
        uint256 previousBuyTaxBps,
        uint256 newBuyTaxBps,
        uint256 previousSellTaxBps,
        uint256 newSellTaxBps
    );
    event FeeSwapThresholdUpdated(uint256 previousThreshold, uint256 newThreshold);
    event FeeToUpdated(address indexed previousFeeTo, address indexed newFeeTo);
    event TaxExemptionUpdated(address indexed account, bool exempt);
    event PairBurnOperatorUpdated(address indexed previousOperator, address indexed newOperator);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event TradeTaxCollected(
        address indexed account,
        bool indexed isBuy,
        uint256 grossAmount,
        uint256 feeAmount,
        uint256 netAmount
    );
    event TaxableUserSellObserved(
        uint256 indexed sequence, address indexed seller, uint256 grossAmount
    );
    event FeesProcessed(uint256 nsAmount, uint256 usdtAmount, address indexed feeTo);
    event AutomaticFeeProcessingFailed(uint256 nsAmount, bytes reason);
    event NsBurned(address indexed account, uint256 amount, uint256 totalSupplyAfter);
    event OfficialPairNsBurned(
        address indexed operator,
        uint256 burnBps,
        uint256 pairBalanceBefore,
        uint256 actualBurned,
        uint256 totalSupplyAfter
    );

    uint256 public constant BPS_DENOMINATOR = 10_000;
    address public constant PANCAKE_V2_ROUTER = NashStakeLibrary.PANCAKE_V2_ROUTER;
    address public constant BSC_USDT = NashStakeLibrary.BSC_USDT;
    uint256 public constant MIN_TOTAL_SUPPLY = 2_100_000 ether;
    uint256 public constant MAX_PAIR_BURN_BPS = 500;
    uint256 public constant PAIR_BURN_COOLDOWN = 1 days;

    address public immutable officialPair;
    address public immutable distributionVault;
    address public immutable nbEquilibrium;

    /// @notice Independent authority for feeTo and pairBurnOperator, including after Owner renunciation.
    address public governance;
    address public feeTo;
    address public pairBurnOperator;
    uint256 public buyTaxBps;
    uint256 public sellTaxBps;
    uint256 public feeSwapThreshold;
    uint256 public sellSequence;
    uint256 public pairBurnSequence;
    uint256 public lastPairBurnTime;
    bool private _inSwap;

    mapping(address account => bool exempt) public taxExempt;

    modifier onlyGovernance() {
        if (msg.sender != governance) revert Unauthorized();
        _;
    }

    constructor(
        address initialOwner_,
        address initialGovernance_,
        address distributionVault_,
        address nbEquilibrium_,
        address initialLiquidityReceiver_,
        address feeTo_,
        address pairBurnOperator_
    ) ERC20("NASH Token", "NS") Ownable(initialOwner_) {
        _requireNonzero(initialLiquidityReceiver_);

        governance = _requireNonzero(initialGovernance_);
        emit GovernanceTransferred(address(0), initialGovernance_);
        distributionVault = _requireNonzero(distributionVault_);
        nbEquilibrium = _requireNonzero(nbEquilibrium_);
        feeTo = _requireNonzero(feeTo_);
        pairBurnOperator = _requireNonzero(pairBurnOperator_);
        buyTaxBps = 300;
        sellTaxBps = 300;
        feeSwapThreshold = 1 ether;
        // Router fee conversion transfers NS from this contract to the Pair and must stay untaxed.
        taxExempt[address(this)] = true;

        // NASH launches only on BSC, so the official Router and USDT are fixed in bytecode.
        INashV2Factory factory = INashV2Factory(INashV2Router(PANCAKE_V2_ROUTER).factory());
        // Anyone can precreate the canonical Pair before this Token address has code.
        address pair = factory.getPair(address(this), BSC_USDT);
        officialPair = pair == address(0) ? factory.createPair(address(this), BSC_USDT) : pair;
        if (officialPair == address(0)) revert InvalidPair();

        _approve(address(this), PANCAKE_V2_ROUTER, type(uint256).max);
        _mint(distributionVault_, 20_800_000 ether);
        _mint(nbEquilibrium_, 5_000 ether);
        _mint(initialLiquidityReceiver_, 195_000 ether);
    }

    // Owner-only launch settings are permanently frozen after renounceOwnership.
    function setTaxRates(uint256 newBuyTaxBps, uint256 newSellTaxBps) external onlyOwner {
        _requireValidTaxRate(newBuyTaxBps);
        _requireValidTaxRate(newSellTaxBps);
        uint256 previousBuyTaxBps = buyTaxBps;
        uint256 previousSellTaxBps = sellTaxBps;
        buyTaxBps = newBuyTaxBps;
        sellTaxBps = newSellTaxBps;
        emit TaxRatesUpdated(previousBuyTaxBps, newBuyTaxBps, previousSellTaxBps, newSellTaxBps);
    }

    function setFeeSwapThreshold(uint256 newThreshold) external onlyOwner {
        if (newThreshold == 0) revert InvalidValue();
        uint256 previousThreshold = feeSwapThreshold;
        feeSwapThreshold = newThreshold;
        emit FeeSwapThresholdUpdated(previousThreshold, newThreshold);
    }

    function setTaxExempt(address account, bool exempt) external onlyOwner {
        _requireNonzero(account);
        if (account == officialPair || account == address(this)) revert InvalidValue();
        taxExempt[account] = exempt;
        emit TaxExemptionUpdated(account, exempt);
    }

    // Independent governance remains active before and after Owner renunciation.
    /// @notice Immediately replaces governance; the old address loses authority in this call.
    function transferGovernance(address newGovernance) external onlyGovernance {
        address previousGovernance = governance;
        governance = _requireNonzero(newGovernance);
        emit GovernanceTransferred(previousGovernance, newGovernance);
    }

    function setFeeTo(address newFeeTo) external onlyGovernance {
        address previousFeeTo = feeTo;
        feeTo = _requireNonzero(newFeeTo);
        emit FeeToUpdated(previousFeeTo, newFeeTo);
    }

    function setPairBurnOperator(address newOperator) external onlyGovernance {
        address previousOperator = pairBurnOperator;
        pairBurnOperator = _requireNonzero(newOperator);
        emit PairBurnOperatorUpdated(previousOperator, newOperator);
    }

    // Business actions keep their own caller and accounting boundaries.
    function processFees() external {
        if (_inSwap) revert InvalidState();
        uint256 feeBalance = balanceOf(address(this));
        if (feeBalance < feeSwapThreshold) revert InvalidState();
        (bool success,) = _tryProcessFees(feeBalance);
        // Explicit processing is atomic: failure keeps every accumulated NS in this contract.
        if (!success) revert FeeProcessingFailed();
    }

    /// @notice Burns the caller's NS up to the supply floor and returns the actual amount.
    function burn(uint256 amount) external returns (uint256 burnedAmount) {
        if (msg.sender == officialPair) revert Unauthorized();
        uint256 remainingAmount = totalSupply() - MIN_TOTAL_SUPPLY;
        burnedAmount = amount < remainingAmount ? amount : remainingAmount;
        if (burnedAmount == 0) return 0;

        _burn(msg.sender, burnedAmount);
        emit NsBurned(msg.sender, burnedAmount, totalSupply());
    }

    function burnNsFromPair(uint256 burnBps) external {
        if (msg.sender != pairBurnOperator) revert Unauthorized();
        if (burnBps == 0 || burnBps > MAX_PAIR_BURN_BPS) revert InvalidValue();
        if (pairBurnSequence != 0) {
            uint256 nextAvailableTime = lastPairBurnTime + PAIR_BURN_COOLDOWN;
            if (block.timestamp < nextAvailableTime) {
                revert PairBurnCooldownActive();
            }
        }

        uint256 pairBalanceBefore = balanceOf(officialPair);
        uint256 requestedAmount = pairBalanceBefore * burnBps / BPS_DENOMINATOR;
        uint256 remainingAmount = totalSupply() - MIN_TOTAL_SUPPLY;
        uint256 actualBurned = requestedAmount < remainingAmount ? requestedAmount : remainingAmount;
        if (actualBurned == 0) revert InvalidValue();

        // Burn and Pair reserve synchronization must succeed or revert together.
        pairBurnSequence += 1;
        lastPairBurnTime = block.timestamp;
        _burn(officialPair, actualBurned);
        INashV2Pair(officialPair).sync();
        emit OfficialPairNsBurned(
            msg.sender, burnBps, pairBalanceBefore, actualBurned, totalSupply()
        );
    }

    function _update(address from, address to, uint256 amount) internal override {
        // Fee conversion must transfer normally without another tax or swap, independently of the whitelist.
        if (
            _inSwap || from == address(0) || to == address(0) || amount == 0
                || (from != officialPair && to != officialPair) || taxExempt[from] || taxExempt[to]
        ) {
            super._update(from, to, amount);
            return;
        }

        bool isBuy = from == officialPair;
        uint256 rateBps = isBuy ? buyTaxBps : sellTaxBps;
        uint256 feeAmount = amount * rateBps / BPS_DENOMINATOR;
        uint256 netAmount = amount - feeAmount;
        if (!isBuy) {
            uint256 feeBalance = balanceOf(address(this));
            if (feeBalance >= feeSwapThreshold) {
                // Process only previously accumulated fees before collecting this transfer's fee.
                (bool success, bytes memory reason) = _tryProcessFees(feeBalance);
                // Automatic processing is fail-open so a Router failure cannot block the sell.
                if (!success) emit AutomaticFeeProcessingFailed(feeBalance, reason);
            }
        }
        if (feeAmount != 0) super._update(from, address(this), feeAmount);
        super._update(from, to, netAmount);

        address account = isBuy ? to : from;
        emit TradeTaxCollected(account, isBuy, amount, feeAmount, netAmount);
        if (!isBuy && from != nbEquilibrium) {
            sellSequence += 1;
            emit TaxableUserSellObserved(sellSequence, from, amount);
        }
    }

    function _tryProcessFees(uint256 nsAmount) private returns (bool success, bytes memory reason) {
        uint256 usdtBalanceBefore = IERC20(BSC_USDT).balanceOf(feeTo);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BSC_USDT;

        _inSwap = true;
        // The project explicitly accepts fee-conversion price risk, so amountOutMin is zero.
        try INashV2Router(PANCAKE_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                nsAmount, 0, path, feeTo, block.timestamp
            ) {
            _inSwap = false;
            uint256 usdtAmount = IERC20(BSC_USDT).balanceOf(feeTo) - usdtBalanceBefore;
            emit FeesProcessed(nsAmount, usdtAmount, feeTo);
            return (true, bytes(""));
        } catch (bytes memory caughtReason) {
            _inSwap = false;
            return (false, caughtReason);
        }
    }

    function _requireNonzero(address account) private pure returns (address) {
        if (account == address(0)) revert InvalidAddress();
        return account;
    }

    function _requireValidTaxRate(uint256 rateBps) private pure {
        if (rateBps > BPS_DENOMINATOR) revert InvalidValue();
    }
}
