// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IDexFiVaultFactory.sol";
import "./IDexFiVaultProfitStorage.sol";
import "./IDexFiFarm.sol";

interface IDexFiVault {
    struct Farm {
        address beacon;
        uint256 percent;
        bytes data;
    }

    struct PublishData {
        bool published;
        address publisher;
    }

    function divider() external view returns (uint256);

    function lastHarvestTimestamp() external view returns (uint256);

    function factory() external view returns (IDexFiVaultFactory);

    function harvesterDebt() external view returns (uint256);

    function profit() external view returns (uint256);

    function profitStorage() external view returns (address);

    function native() external view returns (IERC20Upgradeable);

    function farmConnector(address) external view returns (IDexFiFarm);

    function publishData() external view returns (PublishData memory);

    function farms(uint256 index) external view returns (Farm memory);

    function farmsCount() external view returns (uint256);

    function convertlessDepositRatio() external view returns (uint256[] memory output);

    event Published(address publisher);
    event ProfitUpdated(uint256 profit);
    event HarvesterDebtIncreased(uint256 amount, uint256 remainingDebtAmount);
    event Deposited(
        address indexed user,
        address indexed to,
        uint256 nativeAmount,
        uint256 syntheticAmount,
        uint256 feeAmount
    );
    event ConvertlessDeposited(
        address indexed user,
        uint256 syntheticAmount,
        uint256[] stakingAmounts,
        uint256[] depositLiquidityAmounts,
        uint256[] feeLiquidityAmounts
    );
    event Harvested(
        address indexed user,
        uint256 reinvestAmount,
        uint256 feeAmount,
        uint256 profitAmount,
        uint256 paidDebtAmount,
        uint256 remainingDebtAmount
    );
    event Withdrawn(
        address indexed user,
        address indexed from,
        uint256 syntheticAmount,
        uint256 nativeAmount,
        uint256 feeAmount
    );
    event EmergencyWithdrawn(address indexed user, uint256 syntheticAmount, uint256[] outputAmounts);
    event ConvertlessWithdrawn(
        address indexed user,
        uint256 syntheticAmount,
        uint256[] outputAmounts,
        uint256[] feeAmounts,
        uint256 outputNativeAmount,
        uint256 feeNativeAmount
    );
    event FarmsUpdated(Farm[] farms);

    error ActualizeFarmStatusReinitializationFailed(address farm, bytes data);
    error IncreaseHarvesterDebtCallerNotHarvester(address caller, address harvester);
    error DepositAmountZero();
    error DepositUsersCountOverflow();
    error DepositLiquidityNotPositive();
    error DepositMintAmountUnderflow(uint256 mintAmount, uint256 minMintAmount);
    error DepositConvertlessSupplyZero();
    error DepositConvertlessAmountsLengthDiffers(uint256 amountsLength, uint256 target);
    error DepositConvertlessMintAmountUnderflow(uint256 mintAmount, uint256 minMintAmount);
    error WithdrawAmountZero();
    error WithdrawNativeAmountUnderflow(uint256 nativeAmount, uint256 minNativeAmount);
    error EmergencyWithdrawUserBalanceZero();
    error WithdrawConvertlessAmountZero();
    error UpdateProfitUnderflow(uint256 profit, uint256 min);
    error UpdateProfitOverflow(uint256 profit, uint256 max);
    error ProtocolPaused();
    error ContractNotInitialized();
    error RestakingAmountUnderflow(uint256 restakingAmount, uint256 minRestakingAmount);
    error UpdateFarmsLengthZero();
    error UpdateFarmsInvalidPercentsSum(uint256 percentSum, uint256 targetSum);

    function increaseHarvesterDebt(uint256 amount) external returns (bool);

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 profit_,
        address profitToken_,
        Farm[] memory farms_
    ) external returns (bool);

    function deposit(uint256 amount, address to, uint256 minMintAmount) external returns (uint256 mintAmount);

    function depositConvertless(
        uint256[] memory stakingAmounts,
        uint256 minMintAmount
    ) external returns (uint256 mintAmount);

    function harvest(
        uint256 minRestakingAmount_
    )
        external
        returns (
            uint256 reinvestAmount,
            uint256 harvestFeeAmount,
            uint256 profitAmount,
            uint256 paidDebtAmount,
            uint256 remainingDebtAmount,
            uint256 restakingAmount
        );

    function updateFarms(
        Farm[] memory farms_,
        uint256 minRestakingAmount_
    ) external returns (uint256 restakingAmount, uint256 liquidityInNative);

    function withdraw(uint256 amount, address from, uint256 minNativeAmount) external returns (uint256 nativeAmount);

    function emergencyWithdraw() external returns (uint256[] memory outputAmounts);

    function publish(uint256 minRestakingAmount_) external returns (uint256 restakingAmount);

    function updateProfit(uint256 profit_) external returns (bool);

    function updateProfitToken(address profitToken_) external returns (bool);
}
