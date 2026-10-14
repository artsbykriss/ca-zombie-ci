// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../lib/Ledger.sol";
import "../CToken.sol";
import "../CErc20.sol";
import "../interfaces/IRouter.sol";
import "../velocore/interfaces/IVault.sol";
import "../interfaces/IWETH.sol";
import "./ES33.sol";

interface IBribe {
    function notifyRewardAmount(address token, uint256 amount) external;
}

interface IGauge {
    function emissionShare(address) external returns (uint256);
}

interface IComptroller {
    function getAllMarkets() external view returns (address[] memory);
}

interface VelocoreLens {
    function emissionRate(address gauge) external returns (uint256);
}

contract RewardDistributor is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using LedgerLib for Ledger;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    bytes32 public constant BRIBE_ACCOUNT = bytes32("BRIBE");
    ES33 public underlying;
    address cEther;
    address weth;
    IBribe bribe;
    IGauge gauge;
    IERC20 vc;
    IRouter router;
    IComptroller comptroller;
    Ledger weights;
    mapping(bytes32 => Ledger) assetLedgers;
    mapping(address => uint256) accruedInterest;
    uint256 supposedBalance; // unused. included for historical reasons

    uint256 public lastReap;
    uint256 public lastGaugeClaim;
    uint256 public duration;
    uint256 public swappedRF;

    event Harvest(address addr, uint256 amount);

    function initialize(address admin, ES33 underlying_, address cEther_, address weth_, IRouter router_)
        external
        initializer
    {
        _transferOwnership(admin);
        __ReentrancyGuard_init();
        underlying = underlying_;
        cEther = cEther_;
        weth = weth_;
        router = router_;
    }

    // todo: takeLP
    function slot(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function slot(IERC20 a) internal pure returns (bytes32) {
        return slot(address(a));
    }

    function slot(address informationSource, bytes32 kind) public pure returns (bytes32) {
        return keccak256(abi.encode(informationSource, kind));
    }

    function setExternals(IBribe bribe_, IGauge gauge_, IERC20 vc_, IComptroller comptroller_) external onlyOwner {
        bribe = bribe_;
        gauge = gauge_;
        vc = vc_;
        comptroller = comptroller_;
    }

    function onAssetIncrease(bytes32 kind, address account, uint256 delta) external nonReentrant {
        bytes32[] memory a = new bytes32[](1);
        a[0] = slot(msg.sender, kind);
        _harvest(account, a);
        Ledger storage ledger = assetLedgers[slot(msg.sender, kind)];
        ledger.deposit(slot(account), delta);
    }

    function onAssetDecrease(bytes32 kind, address account, uint256 delta) external nonReentrant {
        bytes32[] memory a = new bytes32[](1);
        a[0] = slot(msg.sender, kind);
        _harvest(account, a);
        Ledger storage ledger = assetLedgers[slot(msg.sender, kind)];
        ledger.withdraw(slot(account), delta);
    }

    function onAssetChange(bytes32 kind, address account, uint256 amount) external nonReentrant {
        bytes32[] memory a = new bytes32[](1);
        a[0] = slot(msg.sender, kind);
        _harvest(account, a);
        Ledger storage ledger = assetLedgers[slot(msg.sender, kind)];
        ledger.withdrawAll(slot(account));
        ledger.deposit(slot(account), amount);
    }

    function _harvest(address addr, bytes32[] memory ledgerIds) internal returns (uint256) {
        updateRewards(ledgerIds);
        uint256 harvested = 0;

        for (uint256 j = 0; j < ledgerIds.length; j++) {
            harvested += assetLedgers[ledgerIds[j]].harvest(slot(addr), slot(address(underlying)));
        }
        accruedInterest[addr] += harvested;
        return harvested;
    }

    function harvest(bytes32[] memory ledgerIds) external nonReentrant returns (uint256) {
        _harvest(msg.sender, ledgerIds);
        uint256 amount = accruedInterest[msg.sender];
        accruedInterest[msg.sender] = 0;
        IERC20(address(underlying)).safeTransfer(msg.sender, amount);
        emit Harvest(msg.sender, amount);
        return amount;
    }

    function updateRewards(bytes32[] memory ledgerIds) public {
        uint256 delta = underlying.mintEmission();
        if (delta != 0) {
            weights.reward(slot(address(underlying)), delta);
        }

        for (uint256 j = 0; j < ledgerIds.length; j++) {
            if (ledgerIds[j] != BRIBE_ACCOUNT) {
                uint256 amount = weights.harvest(ledgerIds[j], slot(address(underlying)));
                assetLedgers[ledgerIds[j]].reward(slot(address(underlying)), amount);
            }
        }
    }

    function setWeights(bytes32[] calldata _ids, uint256[] calldata _weights) external onlyOwner nonReentrant {
        updateRewards(_ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            weights.withdrawAll(_ids[i]);
            weights.deposit(_ids[i], _weights[i]);
        }
    }

    function borrowSlot(address cToken) external pure returns (bytes32) {
        return slot(cToken, bytes32("BORROW"));
    }

    function supplySlot(address cToken) external pure returns (bytes32) {
        return slot(cToken, bytes32("SUPPLY"));
    }

    function reset() external onlyOwner {
        lastGaugeClaim = block.timestamp - 10 minutes - 1;
        duration = 10 minutes;
    }

    function velocore__convert(address user, bytes32[] calldata t, int128[] memory r, bytes calldata) external {

        /*
        require(msg.sender == 0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6, "only vault");
        require(user == address(underlying));
        CToken ceth = CToken(0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6);
        CToken cusdc = CToken(0x04e9Db37d8EA0760072e1aCE3F2A219988Fdac29);
        IERC20 usdc = IERC20(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
        CToken cbtc = CToken(0x0a976E1E7D3052bEb46085AcBE1e0DAccF4A19CF);
        IERC20 btc = IERC20(0xBBeB516fb02a01611cBBE0453Fe3c580D7281011);
        CToken cusdt = CToken(0x894cccB9908A0319381c305f947aD0EF44838591);
        IERC20 usdt = IERC20(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
        ceth.takeReserves();
        cusdc.takeReserves();
        cbtc.takeReserves();
        cusdt.takeReserves();
        usdc.transfer(address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6), usdc.balanceOf(address(this)));
        btc.transfer(address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6), btc.balanceOf(address(this)));
        usdt.transfer(address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6), usdt.balanceOf(address(this)));
        (bool success,) = address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6).call{value: address(this).balance}("");
        require(success);
        */
    }

   function reap() external {
       require(msg.sender == address(underlying));
        CToken ceth = CToken(0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6);
        CToken cusdc = CToken(0x04e9Db37d8EA0760072e1aCE3F2A219988Fdac29);
        IERC20 usdc = IERC20(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
        CToken cbtc = CToken(0x0a976E1E7D3052bEb46085AcBE1e0DAccF4A19CF);
        IERC20 btc = IERC20(0xBBeB516fb02a01611cBBE0453Fe3c580D7281011);
        CToken cusdt = CToken(0x894cccB9908A0319381c305f947aD0EF44838591);
        IERC20 usdt = IERC20(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
        ceth.takeReserves();
        cusdc.takeReserves();
        cbtc.takeReserves();
        cusdt.takeReserves();
        IWETH(WETH_ADDRESS).deposit{value: address(this).balance}();
        usdc.transfer(address(underlying), usdc.balanceOf(address(this)));
        btc.transfer(address(underlying), btc.balanceOf(address(this)));
        usdt.transfer(address(underlying), usdt.balanceOf(address(this)));
        IWETH(WETH_ADDRESS).transfer(address(underlying), IWETH(WETH_ADDRESS).balanceOf(address(this)));
   }
    receive() external payable {}

    //--- view functions

    function currentPrice(IERC20 qtyToken, IERC20 quoteToken) internal view returns (uint256) {
        IPair pair = IPair(router.pairFor(address(qtyToken), address(quoteToken), false));
        (uint256 r0, uint256 r1,) = pair.getReserves();
        (IERC20 t0,) = pair.tokens();
        return qtyToken == t0 ? Math.mulDiv(1e18, r1, r0) : Math.mulDiv(1e18, r0, r1);
    }

    function rewardRateAll()
        external
        returns (address[] memory cts, uint256[] memory supplies, uint256[] memory borrows)
    {
        cts = comptroller.getAllMarkets();
        supplies = new uint256[](cts.length);
        borrows = new uint256[](cts.length);
        uint256 totalRate = underlying.emissionRate();
        for (uint256 i = 0; i < cts.length; i++) {
            supplies[i] = CToken(cts[i]).totalSupply() == 0
                ? 0
                : ((totalRate * weights.shareOf(slot(cts[i], bytes32("SUPPLY")))) * 1e18)
                    / (CToken(cts[i]).totalSupply() * CToken(cts[i]).exchangeRateCurrent());
            borrows[i] = (CToken(cts[i]).totalBorrowsCurrent()) == 0
                ? 0
                : ((totalRate * weights.shareOf(slot(cts[i], bytes32("BORROW"))))) / (CToken(cts[i]).totalBorrowsCurrent());
        }
        return (cts, supplies, borrows);
    }

    function emissionRates() external returns (address[] memory tokens, uint256[] memory rates) {
        address[] memory cts = comptroller.getAllMarkets();
        tokens = new address[](cts.length);
        rates = new uint256[](cts.length);
        for (uint256 i = 0; i < cts.length; i++) {
            CErc20 ct = CErc20(cts[i]);
            uint256 totalInterests = ct.totalBorrowsCurrent() * ct.borrowRatePerBlock();
            uint256 tokenInflow = Math.mulDiv(totalInterests, ct.reserveFactorMantissa(), 1e18);
            tokens[i] = address(ct) == cEther ? WETH_ADDRESS : ct.underlying();
            rates[i] = tokenInflow;
        }
    }

    function bribeTokens(address) external view returns (bytes32[] memory ret) {
        ret = new bytes32[](1);
        ret[0] = bytes32(uint256(uint160(address(underlying))));
    }

    function bribeRates(address) external view returns (uint256[] memory ret) {
        ret[0] = 0;
    }

    function totalBribes(address) external view returns (uint256) {
        return 0;
    }

    function velocore__bribe(address gauge, uint256)
        external
        returns (
            bytes32[] memory bribeTokens,
            int128[] memory deltaGauge,
            int128[] memory deltaPool,
            int128[] memory deltaExternal
        )
    {
        revert("");
    }
}
