// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./BaseManager.sol";
import "./interfaces/IFermiEngine.sol";
import "./interfaces/IFermiSwapper.sol";
import "./interfaces/IFermiSwapCallback.sol";
import "./interfaces/IPropAMM.sol";
import "./interfaces/IPropAMMExactOut.sol";

using SafeERC20 for IERC20;

contract FermiSwapper is BaseManager, IFermiSwapper {
    using SafeCast for uint256;

    uint256 public constant VERSION = 20260604;

    IFermiEngine public fermi;
    address payable public traderVault;

    constructor(
        address payable vaultAddress,
        address payable managerAddress,
        address fermiAddress,
        address payable traderVaultAddress
    ) BaseManager(vaultAddress, managerAddress) {
        require(fermiAddress != address(0), "ZA");
        require(traderVaultAddress != address(0), "ZA");
        require(IFermiEngine(fermiAddress).traderVault() == traderVaultAddress, "TVM");
        fermi = IFermiEngine(fermiAddress);
        traderVault = traderVaultAddress;
    }

    function setFermi(address newFermi) external onlyManager {
        require(newFermi != address(0), "ZA");
        require(IFermiEngine(newFermi).traderVault() == traderVault, "TVM");
        fermi = IFermiEngine(newFermi);
    }

    function setTraderVault(address payable newTraderVault) external onlyManager {
        require(newTraderVault != address(0), "ZA");
        require(fermi.traderVault() == newTraderVault, "TVM");
        traderVault = newTraderVault;
    }

    // Returns whether a fresh price for the pair is usable this block, i.e. an update was included in the current block.
    function isActive(address tokenIn, address tokenOut) external view returns (bool active) {
        return fermi.unlocked(tokenIn, tokenOut);
    }

    // Returns whether the pair is enabled (allowed to be traded).
    function isEnabled(address tokenIn, address tokenOut) external view returns (bool) {
        return fermi.isActive(tokenIn, tokenOut);
    }

    function getPairs() external view returns (IPropAMM.TokenPair[] memory pairs) {
        IFermiEngine.PairInfo[] memory enginePairs = fermi.getPairs();
        pairs = new IPropAMM.TokenPair[](enginePairs.length);
        for (uint256 i = 0; i < enginePairs.length; i++) {
            pairs[i] = IPropAMM.TokenPair({token0: enginePairs[i].baseAsset, token1: enginePairs[i].quoteAsset});
        }
    }

    function getPairsWithStatus() external view returns (IFermiEngine.PairInfo[] memory pairs) {
        return fermi.getPairs();
    }

    // Exact-input quote.
    // Returns the amount of `tokenOut` delivered for `amountIn` of `tokenIn`.
    function quote(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut) {
        (, amountOut) = fermi.quote(tokenIn, tokenOut, amountIn.toInt256(), msg.sender);
    }

    // Exact-output quote.
    // Returns the amount of `tokenIn` required to receive `amountOut` of `tokenOut`.
    function quoteExactOut(address tokenIn, address tokenOut, uint256 amountOut)
        external
        view
        returns (uint256 amountIn)
    {
        (amountIn,) = fermi.quote(tokenIn, tokenOut, -amountOut.toInt256(), msg.sender);
    }

    // Unified quote (UniV3 sign convention): `amountSpecified > 0` is exact-input, `amountSpecified < 0` is exact-output.
    // Returns both legs the swap would settle.
    function quoteAmounts(address tokenIn, address tokenOut, int256 amountSpecified)
        external
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        return fermi.quote(tokenIn, tokenOut, amountSpecified, msg.sender);
    }

    // Exact-input push-payment swap: the caller must have transferred `amountIn` of
    // `tokenIn` to this contract beforehand.
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountOut) {
        require(recipient != address(0), "ZA");
        require(block.timestamp <= deadline, "DL"); // Deadline passed

        uint256 swapAmountIn;
        (swapAmountIn, amountOut) = fermi.swap(tokenIn, tokenOut, amountIn.toInt256(), msg.sender);
        require(amountOut >= minAmountOut, "ACF"); // Amount Check Failed

        IERC20(tokenOut).safeTransferFrom(traderVault, recipient, amountOut);
        IERC20(tokenIn).safeTransfer(traderVault, swapAmountIn);

        emit Swapped(msg.sender, tokenIn, tokenOut, swapAmountIn, amountOut, recipient);
    }

    // Exact-output push-payment swap: the caller must have transferred
    // `amountInMax` of `tokenIn` to this contract beforehand. Delivers exactly `amountOut` of
    // `tokenOut` to `recipient`, spends at most `amountInMax` (reverts "ACF" otherwise), and
    // refunds the unspent `amountInMax - amountIn` to `refundRecipient`.
    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address recipient,
        address refundRecipient,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountIn) {
        require(recipient != address(0), "ZA");
        require(refundRecipient != address(0), "ZA");
        require(block.timestamp <= deadline, "DL"); // Deadline passed

        uint256 deliveredOut;
        (amountIn, deliveredOut) = fermi.swap(tokenIn, tokenOut, -amountOut.toInt256(), msg.sender);
        require(deliveredOut == amountOut, "ACF"); // Amount Check Failed (cannot deliver exact output)
        require(amountIn <= amountInMax, "ACF"); // Amount Check Failed (input ceiling)

        IERC20(tokenOut).safeTransferFrom(traderVault, recipient, amountOut);
        IERC20(tokenIn).safeTransfer(traderVault, amountIn);

        uint256 refund = amountInMax - amountIn;
        if (refund != 0) {
            IERC20(tokenIn).safeTransfer(refundRecipient, refund);
        }

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut, recipient);
    }

    // Pulls `tokenIn` from the caller.
    // `amountSpecified` follows the UniV3 sign convention — > 0 is exact-input (the input amount),
    // < 0 is exact-output (`-amountSpecified` = the desired output). `amountCheck` is the slippage
    // bound: a minimum `amountOut` on exact-input, a maximum `amountIn` on exact-output (reverts "ACF").
    function fermiSwapWithAllowances(
        address tokenIn,
        address tokenOut,
        int256 amountSpecified,
        uint256 amountCheck,
        address recipient
    ) external nonReentrant returns (uint256 amountIn, uint256 amountOut) {
        require(recipient != address(0), "ZA");

        (amountIn, amountOut) = fermi.swap(tokenIn, tokenOut, amountSpecified, msg.sender);
        require(amountSpecified > 0 ? amountOut >= amountCheck : amountIn <= amountCheck, "ACF");

        IERC20(tokenOut).safeTransferFrom(traderVault, recipient, amountOut);
        IERC20(tokenIn).safeTransferFrom(msg.sender, traderVault, amountIn);

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut, recipient);
    }

    // Callback swap.
    // `amountSpecified` follows the UniV3 sign convention — > 0 is exact-input (the input amount),
    // < 0 is exact-output (`-amountSpecified` = the desired output). `amountCheck` is the slippage
    // bound: a minimum `amountOut` on exact-input, a maximum `amountIn` on exact-output (reverts "ACF").
    function fermiSwapWithCallback(
        address tokenIn,
        address tokenOut,
        int256 amountSpecified,
        uint256 amountCheck,
        address recipient,
        bytes calldata callbackData
    ) external nonReentrant returns (uint256 amountIn, uint256 amountOut) {
        require(recipient != address(0), "ZA");

        (amountIn, amountOut) = fermi.swap(tokenIn, tokenOut, amountSpecified, msg.sender);
        require(amountSpecified > 0 ? amountOut >= amountCheck : amountIn <= amountCheck, "ACF");

        uint256 balanceBefore = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenOut).safeTransferFrom(traderVault, recipient, amountOut);
        IFermiSwapCallback(msg.sender).fermiSwapCallback(int256(amountIn), -int256(amountOut), callbackData);
        require(IERC20(tokenIn).balanceOf(address(this)) >= balanceBefore + amountIn, "WTA");
        IERC20(tokenIn).safeTransfer(traderVault, amountIn);

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut, recipient);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IPropAMM).interfaceId
            || interfaceId == type(IPropAMMExactOut).interfaceId;
    }

    receive() external payable {}
    fallback() external payable {}
}
