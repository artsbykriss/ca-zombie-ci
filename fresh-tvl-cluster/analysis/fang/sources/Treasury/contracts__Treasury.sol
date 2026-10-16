// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMasonry.sol";
import "./owner/Operator.sol";

/**************************************************************************************************************************************************

 /$$$$$$$$                                 /$$$$$$$$ /$$                                                  
| $$_____/                                | $$_____/|__/                                                  
| $$    /$$$$$$  /$$$$$$$   /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
| $$$$$|____  $$| $$__  $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
| $$__/ /$$$$$$$| $$  \ $$| $$  \ $$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
| $$   /$$__  $$| $$  | $$| $$  | $$      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  |  $$$$$$$| $$  | $$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/   \_______/|__/  |__/ \____  $$      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
                           /$$  \ $$                                                                      
                          |  $$$$$$/                                                                      
                           \______/                                                                       
                                                                                                                                                    
#### Website: https://fang.finance/
#### Author: kell

**************************************************************************************************************************************************/

contract Treasury is ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;
    uint256 public constant BASIS_DIVISOR = 100000; // 100%

    /* ========== STATE VARIABLES ========== */

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    // Legacy bond getters remain available, but bonds are permanently disabled.
    uint256 public constant epochSupplyContractionLeft = 0;
    uint256 public constant seigniorageSaved = 0;

    //=================================================================// exclusions from total supply
    address[] public excludedFromTotalSupply = [
        address(0) // FangGenesisRewardPool
    ];

    // core components
    address public fang;
    address public bfang; // Legacy metadata only; no BFANG contract is required.
    address public gfang;

    address public masonry;
    address public fangOracle;

    // price
    uint256 public fangPriceOne;
    uint256 public fangPriceCeiling;

    uint256 public maxSupplyExpansionPercent;

    // First designated epochs with X% expansion regardless of FANG price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochFangPrice;

    address public daoFund;
    uint256 public daoFundSharedPercent;

    //=================================================//

    address public devFund;
    uint256 public devFundSharedPercent;
    address public teamFund;
    uint256 public teamFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    // Retained for existing event filters; bond/debt events are never emitted.
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 fangAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 fangAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event MasonryFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event TeamFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier checkCondition {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator {
        require(
                IBasisAsset(fang).operator() == address(this) &&
                IBasisAsset(gfang).operator() == address(this) &&
                Operator(masonry).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getFangPrice() public view returns (uint256 fangPrice) {
        try IOracle(fangOracle).consult(fang, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult FANG price from the oracle");
        }
    }

    function getFangUpdatedPrice() public view returns (uint256 _fangPrice) {
        try IOracle(fangOracle).twap(fang, 1e18) returns (uint256 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult FANG price from the oracle");
        }
    }

    // budget
    function getReserve() public pure returns (uint256) {
        return 0;
    }

    function getBurnableFangLeft() public pure returns (uint256) {
        return 0;
    }

    function getRedeemableBonds() public pure returns (uint256) {
        return 0;
    }

    function getBondDiscountRate() public pure returns (uint256) {
        return 0;
    }

    function getBondPremiumRate() public pure returns (uint256) {
        return 0;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _fang,
        address _bfang, // Legacy argument: use address(0) for new deployments.
        address _gfang,
        address _fangOracle,
        address _masonry,
        uint256 _startTime
    ) public notInitialized onlyOperator {
        fang = _fang;
        bfang = _bfang;
        gfang = _gfang;
        fangOracle = _fangOracle;
        masonry = _masonry;
        startTime = _startTime;

        fangPriceOne = 10 ** 18;
        fangPriceCeiling = fangPriceOne.mul(101).div(100); // even if its stable we aim to get 1.01

        // Dynamic max expansion percent
        maxSupplyExpansionPercent = 1500; // 0.15%

        // First 12 epochs with 1.5% expansion
        bootstrapEpochs = 12;
        bootstrapSupplyExpansionPercent = 1500; // 0.15%

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        transferOperator(_operator);
    }

    function renounceOperator() external onlyOperator {
        _renounceOperator();
    }

    function setMasonry(address _masonry) external onlyOperator {
        masonry = _masonry;
    }

    function setFangOracle(address _fangOracle) external onlyOperator {
        fangOracle = _fangOracle;
    }

    function setFangPriceCeiling(uint256 _fangPriceCeiling) external onlyOperator {
        require(_fangPriceCeiling >= fangPriceOne && _fangPriceCeiling <= fangPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        fangPriceCeiling = _fangPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= BASIS_DIVISOR, "_maxSupplyExpansionPercent: out of range"); // [0.001%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 10 && _bootstrapSupplyExpansionPercent <= BASIS_DIVISOR, "_bootstrapSupplyExpansionPercent: out of range"); // [0.001%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }
    //======================================================================
    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent,
        address _teamFund,
        uint256 _teamFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 15000, "out of range");
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 3500, "out of range");
        require(_teamFund != address(0), "zero");
        require(_teamFundSharedPercent <= 5500, "out of range");

        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
        teamFund = _teamFund;
        teamFundSharedPercent = _teamFundSharedPercent;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateFangPrice() internal {
        try IOracle(fangOracle).update() {} catch {}
    }

    function getFangCirculatingSupply() public view returns (uint256) {
        IERC20 fangErc20 = IERC20(fang);
        uint256 totalSupply = fangErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(fangErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    // Keep the selectors so legacy callers receive a clear error. There is no enable switch.
    function buyBonds(uint256, uint256) external pure {
        revert("Treasury: bonds disabled");
    }

    function redeemBonds(uint256, uint256) external pure {
        revert("Treasury: bonds disabled");
    }

    function _sendToMasonry(uint256 _amount) internal {
        IBasisAsset(fang).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(fang).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(fang).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        uint256 _teamFundSharedAmount = 0;
        if (teamFundSharedPercent > 0) {
            _teamFundSharedAmount = _amount.mul(teamFundSharedPercent).div(BASIS_DIVISOR);
            IERC20(fang).transfer(teamFund, _teamFundSharedAmount);
            emit TeamFundFunded(block.timestamp, _teamFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount).sub(_teamFundSharedAmount);

        IERC20(fang).safeApprove(masonry, 0);
        IERC20(fang).safeApprove(masonry, _amount);
        IMasonry(masonry).allocateSeigniorage(_amount);
        emit MasonryFunded(block.timestamp, _amount);
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateFangPrice();
        previousEpochFangPrice = getFangPrice();
        uint256 fangSupply = getFangCirculatingSupply();
        if (epoch < bootstrapEpochs) {
            // First designated epochs with X% expansion of total fang supply
            _sendToMasonry(fangSupply.mul(bootstrapSupplyExpansionPercent).div(BASIS_DIVISOR));
        } else if (previousEpochFangPrice > fangPriceCeiling) {
            uint256 _percentage = previousEpochFangPrice.sub(fangPriceOne);
            uint256 _mse = maxSupplyExpansionPercent.mul(1e12);
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            // All expansion follows the Masonry/fund split; no bond debt is funded.
            uint256 _savedForMasonry = fangSupply.mul(_percentage).div(1e18);
            if (_savedForMasonry > 0) {
                _sendToMasonry(_savedForMasonry);
            }
        }
    }
    //===================================================================================================================================

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(fang), "fang");
        require(address(_token) != address(bfang), "bond");
        require(address(_token) != address(gfang), "share");
        _token.safeTransfer(_to, _amount);
    }

    function masonrySetOperator(address _operator) external onlyOperator {
        IMasonry(masonry).setOperator(_operator);
    }

    function masonrySetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IMasonry(masonry).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function masonryAllocateSeigniorage(uint256 amount) external onlyOperator {
        IMasonry(masonry).allocateSeigniorage(amount);
    }

    function masonryGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IMasonry(masonry).governanceRecoverUnsupported(_token, _amount, _to);
    }
}
