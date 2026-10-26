// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC-20 surface (also used for ERC-4626 share tokens / fleet shares).
interface IERC20Like {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

/// @notice Minimal Lazy-Summer FleetCommander (ERC-4626-ish) surface used by the PoC.
/// @dev `totalAssets()` is the NAV the vault quotes; `withdrawableTotalAssets()` is what it can
///      actually pay out right now. The gap between the two is the root of the donation bug.
interface IFleetCommander is IERC20Like {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function withdrawableTotalAssets() external view returns (uint256);
    function bufferArk() external view returns (address);
    function getActiveArks() external view returns (address[] memory);
    function getCooldown() external view returns (uint256);
    function paused() external view returns (bool);
}

/// @notice Minimal Ark surface. The FleetCommander sums `totalAssets()` over `getActiveArks()`.
/// @dev For the SiloManagedVaultArk the implementation is:
///        function totalAssets() public view returns (uint256 assets) {
///            uint256 shares = vault.balanceOf(address(this));
///            if (shares > 0) assets = vault.convertToAssets(shares);
///        }
///      i.e. it credits *any* share token sitting on the ark, including donated ones, at the
///      vault's NAV -- while `maxWithdraw(ark)` (the realisable amount) can be zero.
interface IArk {
    function totalAssets() external view returns (uint256);
    function asset() external view returns (address);
    function vault() external view returns (address);
    function depositCap() external view returns (uint256);
    function name() external view returns (string memory);
}

/// @notice Minimal ERC-4626 surface for the external vault an ark points at.
interface IVault4626 is IERC20Like {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
