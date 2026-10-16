// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IZapper.sol";

import "./owner/Operator.sol";

contract GfangSwapper is Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public fang;
    address public gfang;
    address public bfang;

    address public fangOracle;
    address public gfangOracle;
    address public treasury;
    address public zapper;

    

    mapping (address => bool) public useNativeRouter;

    event BfangSwapPerformed(address indexed sender, uint256 bfangAmount, uint256 gfangAmount);


    constructor(
        address _fang,
        address _bfang,
        address _gfang,
        address _fangOracle,
        address _gfangOracle,
        address _treasury,
        address _zapper
    ) {
        fang = _fang;
        bfang = _bfang;
        gfang = _gfang;
        fangOracle = _fangOracle;
        gfangOracle = _gfangOracle;
        treasury = _treasury;
        zapper = _zapper;
    }
   modifier whitelist(address route) {
        require(useNativeRouter[route], "route not allowed");
        _;
    }

     function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, type(uint256).max);
        }
    }

    function getFangPrice() public view returns (uint256 fangPrice) {
        try IOracle(fangOracle).consult(fang, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult FANG price from the oracle");
        }
    }
    function getGfangPrice() public view returns (uint256 gfangPrice) {
        try IOracle(gfangOracle).consult(gfang, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult GFANG price from the oracle");
        }
    }
    function redeemBonds(uint256 _bfangAmount, uint256 fangPrice) private returns (uint256) {

         IERC20(bfang).safeTransferFrom(msg.sender, address(this), _bfangAmount);
         _approveTokenIfNeeded(bfang, treasury);
       
        try ITreasury(treasury).redeemBonds(_bfangAmount, fangPrice) {
        } catch {
            revert("Treasury: cant redeem bonds");
        }
        return getFangBalance();
    }

    function swap(address _in, uint256 amount, address out, address recipient, address routerAddr, uint256 minAmountOfGfang) private returns (uint256) {
        
        IERC20(fang).safeTransferFrom(address(this), zapper, amount);
        _approveTokenIfNeeded(fang, routerAddr);
        
         try IZapper(zapper)._swap(_in, amount, out, recipient, routerAddr , minAmountOfGfang) returns (uint256 _gfangAmount) {
             require( _gfangAmount >= minAmountOfGfang, "amt < minAmountNeeded");
            return uint256(_gfangAmount);
        } catch {
            revert("Treasury: failed to get GFANG price");
        }
    }
   

    function estimateAmountOfGfang(uint256 _bfangAmount) external view returns (uint256) {
        uint256 gfangAmountPerFang = getGfangAmountPerFang();
        return _bfangAmount.mul(gfangAmountPerFang).div(1e18);
    }

    function swapBfangToGfang(uint256 _bfangAmount, address routerAddr, uint256 minAmountofGfang) external whitelist(routerAddr) {
        //check if we have the amount of bfangs we want to swap
        require(getBfangBalance(msg.sender) >= _bfangAmount, "Not enough Bfang in wallet");
        
       // send bfang to treasury(call redeem bonds in treasury) and receive fang back
        uint256 fangPrice = getFangPrice();
        uint256 fangToSwap = redeemBonds(_bfangAmount, fangPrice);
       // check if we received fang(should be more than bfangs because of higher rate in redeem in treasury)
       require ( fangToSwap >= _bfangAmount, "redeem bonds reverted"); 
       // swap fang to gfang
        uint256 gfangReceived = swap(fang, fangToSwap, gfang, msg.sender, routerAddr, minAmountofGfang);

        emit BfangSwapPerformed(msg.sender, _bfangAmount, gfangReceived);
    }


    function getFangBalance() public view returns (uint256) {
        return IERC20(fang).balanceOf(address(this));
    }
    function getGfangBalance() public view returns (uint256) {
        return IERC20(gfang).balanceOf(address(this));
    }

    function getBfangBalance(address _user) public view returns (uint256) {
        return IERC20(bfang).balanceOf(_user);
    }
    
    function getGfangAmountPerFang() public view returns (uint256) {
        uint256 fangPrice = getFangPrice();
        uint256 gfangPrice = getGfangPrice();
        return fangPrice.mul(1e18).div(gfangPrice);
    }
    function setUseNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = true;
    }

    function removeNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = false;
    }

}