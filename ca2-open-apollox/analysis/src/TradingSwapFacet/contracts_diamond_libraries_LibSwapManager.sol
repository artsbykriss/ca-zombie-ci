// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBook.sol";
import "../../utils/TransferHelper.sol";


library LibSwapManager {

    bytes32 constant SWAP_MANAGER_POSITION = keccak256("apollox.swap.manager.storage");

    bytes4 public constant SWAP_SELECTOR = bytes4(keccak256("swap(address,(address,address,address,address,uint256,uint256,uint256),bytes)"));

    using TransferHelper for address;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct SwapManagerStorage {
        address oneInchAggregationRouter;
    }

    function swapManagerStorage() internal pure returns (SwapManagerStorage storage pfs) {
        bytes32 position = SWAP_MANAGER_POSITION;
        assembly {
            pfs.slot := position
        }
    }

    event SetOneInchAggregationRouter(address indexed oldOneInchAggregationRouter, address indexed newOneInchAggregationRouter);

    function setOneInchAggregationRouter(address oneInchAggregationRouter) internal {
        SwapManagerStorage storage pfs = swapManagerStorage();
        address old = pfs.oneInchAggregationRouter;
        pfs.oneInchAggregationRouter = oneInchAggregationRouter;
        emit SetOneInchAggregationRouter(old, oneInchAggregationRouter);
    }

    function oneInchSwap(bytes calldata swapData, IBook.OpenDataInput memory data) internal returns (uint96) {
        // Get data (swapData) from https://api.1inch.dev/swap/v6.0/56/swap without making any changes and pass it to the contract method
        require(bytes4(swapData[0 : 4]) == SWAP_SELECTOR, "invalid 1Inch function selector");

        (, LibSwapManager.SwapDescription memory swapDesc,) = abi.decode(swapData[4 :], (address, LibSwapManager.SwapDescription, bytes));

        require(address(swapDesc.dstToken) == data.tokenIn, "tokenIn is not the same as dstToken");
        require(swapDesc.amount > 0, "invalid amount");
        require(swapDesc.dstReceiver == address(this), "invalid dstReceiver");

        LibSwapManager.SwapManagerStorage storage p = LibSwapManager.swapManagerStorage();
        address(swapDesc.srcToken).transferFrom(msg.sender, swapDesc.amount);
        swapDesc.srcToken.approve(p.oneInchAggregationRouter, swapDesc.amount);
        uint256 beforeBalance = swapDesc.dstToken.balanceOf(address(this));
        (bool succ, bytes memory _data) = address(p.oneInchAggregationRouter).call(swapData);

        require(succ, "1inch call failed");

        uint256 afterBalance = swapDesc.dstToken.balanceOf(address(this));
        (uint256 swapOut,) = abi.decode(_data, (uint256, uint256));
        uint256 diff = afterBalance - beforeBalance;

        uint96 amountOut = uint96(swapOut);
        require(swapOut == diff && swapOut >= swapDesc.minReturnAmount && amountOut == swapOut, "received incorrect token amount or less than minReturnAmount or exceeds maximum value");

        return amountOut;
    }
}
