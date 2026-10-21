// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";
interface IERC20D { function approve(address,uint256) external; function balanceOf(address) external view returns (uint256); }
interface IH { function deposit(uint256,bool) external; function borrow(uint256,bool) external; function withdraw(uint256,bool) external; function repay(uint256,bool) external; }
interface ITM { function setCircuitBreaker(bool) external; function getCircuitBreaker() external view returns (bool); }
interface IHV { function handlerViewProxy(bytes calldata) external returns (bool, bytes memory); }
interface IIM { function getInterestAmount(address,address,bool) external view returns (bool,uint256,uint256,bool,uint256,uint256); }
interface IDS { function getLastUpdatedBlock() external view returns (uint256); function getInactiveActionDelta() external view returns (uint256); function getGlobalEXR() external view returns (uint256,uint256); function getActionEXR() external view returns (uint256,uint256); function getUserEXR(address) external view returns (uint256,uint256); }
contract DiagTest is Test {
    address constant TM=0x913F2DEe2746CdA2ab34106c47aBC4a8f4e36fa5;
    address constant H=0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3;
    address constant USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DS=0xFdC7D058beDE981eA865Fb64D06382A2206A1C42;
    address constant MODEL=0x29Ecabde2C57B6D4183f915eBca1A25804A60dB1;
    function setUp() public { vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"))); }
    function v(bytes memory data) internal returns (bytes memory) { (bool ok, bytes memory r)=IHV(H).handlerViewProxy(data); require(ok); return r; }
    function u(string memory sig) internal returns (uint256) { bytes memory r=v(abi.encodeWithSignature(sig)); return abi.decode(r,(uint256)); }
    function amt(address who) internal returns (uint256 d,uint256 b){ bytes memory r=v(abi.encodeWithSignature("getUserAmountWithInterest(address)",who)); (d,b)=abi.decode(r,(uint256,uint256)); }
    function logx(string memory tag) internal {
        (uint256 d,uint256 b)=amt(address(this));
        console2.log(tag);
        console2.log("  dep",d); console2.log("  bor",b);
        console2.log("  hbal",IERC20D(USDT).balanceOf(H));
    }
    function test_diag() public {
        vm.prank(0x81C22BEC01C83E5BFf125d3a52634dBEf60d93d4);
        ITM(TM).setCircuitBreaker(false);
        console2.log("lastUpdated",IDS(DS).getLastUpdatedBlock());
        console2.log("inactiveDelta",IDS(DS).getInactiveActionDelta());
        (uint256 gd,uint256 gb)=IDS(DS).getGlobalEXR();
        console2.log("globalDepEXR",gd); console2.log("globalBorEXR",gb);
        console2.log("handlerBal",IERC20D(USDT).balanceOf(H));
        vm.deal(address(this), 1 ether);
        deal(USDT, address(this), 40_000_000e6);
        IERC20D(USDT).approve(H, type(uint256).max);
        logx("start");
        uint256[5] memory ds=[uint256(119800e18),478560e18,1773080e18,7149440e18,30479120e18];
        for (uint i=0;i<5;i++){ IH(H).deposit(ds[i],false); logx("after deposit");
            console2.log("   delta",IDS(DS).getInactiveActionDelta(),"last",IDS(DS).getLastUpdatedBlock());
            (uint256 ad,uint256 ab)=IDS(DS).getActionEXR(); (uint256 gd2,uint256 gb2)=IDS(DS).getGlobalEXR();
            (uint256 ud,uint256 ub)=IDS(DS).getUserEXR(address(this));
            console2.log("   actionEXR",ad,ab); console2.log("   globalEXR",gd2,gb2); console2.log("   userEXR",ud,ub);
            (bool dn,uint256 dd,uint256 gdx,bool bn,uint256 bd,uint256 gbx)=IIM(MODEL).getInterestAmount(DS,address(this),false);
            console2.log("   model negD",dn); console2.log("   model deltaD",dd); console2.log("   model gD",gdx);
            console2.log("   model negB",bn); console2.log("   model deltaB",bd); console2.log("   model gB",gbx);
        }
        IH(H).deposit(0,false); logx("after deposit0");
        for (uint i=0;i<20;i++){ IH(H).borrow(1480000e18,false); if(i<3||i>17) logx("after borrow"); }
        for (uint i=0;i<20;i++){ IH(H).repay(1480000e18,false); IH(H).withdraw(2000000e18,false); if(i<3||i>17) logx("after cycle"); }
        console2.log("my usdt",IERC20D(USDT).balanceOf(address(this)));
        IH(H).repay(type(uint256).max,false); logx("after repay max");
        IH(H).withdraw(type(uint256).max,false); logx("after withdraw max");
        console2.log("my usdt end",IERC20D(USDT).balanceOf(address(this)));
    }
}
