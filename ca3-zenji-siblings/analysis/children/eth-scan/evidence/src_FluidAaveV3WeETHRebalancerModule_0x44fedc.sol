
// ===== @openzeppelin/contracts/token/ERC20/IERC20.sol =====
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ===== contracts/infiniteProxy/IProxy.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);
}

// ===== contracts/vault/common/interfaces.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IWeEth {
    function getEETHByWeETH(
        uint256 _weETHAmount
    ) external view returns (uint256);

    function getWeETHByeETH(
        uint256 _eETHAmount
    ) external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}
interface ILidoWithdrawalQueue {
    // code below from Lido WithdrawalQueueBase.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueueBase.sol

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    /// @notice length of the checkpoints. Last possible value for the claim hint
    function getLastCheckpointIndex() external view returns (uint256);

    // code below from Lido WithdrawalQueue.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueue.sol

    /// @notice Request the sequence of stETH withdrawals according to passed `withdrawalRequestInputs` data
    /// @param amounts an array of stETH amount values. The standalone withdrawal request will
    ///  be created for each item in the passed list.
    /// @param _owner address that will be able to transfer or claim the request.
    ///  If `owner` is set to `address(0)`, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal requests
    function requestWithdrawals(
        uint256[] calldata amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @notice Claim a batch of withdrawal requests once finalized (claimable) sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id.
    ///   Can be retrieved with `findCheckpointHints()`
    /// @dev
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /// @notice Returns all withdrawal requests that belongs to the `_owner` address
    ///
    /// WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`. NB! Array of request ids should be sorted
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range
    /// @param _lastIndex right boundary of the search range
    /// @return hintIds the hints for `claimWithdrawal` to find the checkpoint for the passed request ids
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);

    /// @notice Returns statuses for the array of request ids
    /// @param _requestIds array of withdrawal request ids
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    function balanceOf(address) external view returns (uint);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IWeth {
    function deposit() external payable;

    function transfer(address dst, uint wad) external returns (bool);
}

interface IFluidVaultT1 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );

    function operate(
        uint256 nftId_, // if 0 then new position
        int256 newCol_, // if negative then withdraw
        int256 newDebt_, // if negative then payback
        address to_ // address at which the borrow & withdraw amount should go to. If address(0) then it'll go to msg.sender
    )
        external
        payable
        returns (
            uint256, // nftId_
            int256, // final supply amount. if - then withdraw
            int256 // final borrow amount. if - then payback
        );
}

interface IFluidVaultT4 {
    /// @notice reads uint256 data `result_` from storage at a bytes32 storage `slot_` key.
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    /// @notice calculates the updated vault exchange prices
    function updateExchangePrices(
        uint256 vaultVariables2_
    )
        external
        view
        returns (
            uint256 liqSupplyExPrice_,
            uint256 liqBorrowExPrice_,
            uint256 vaultSupplyExPrice_,
            uint256 vaultBorrowExPrice_
        );
}

interface IFluidDexT1 {
    function getRatio() external view returns (uint256 ratio_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    struct Implementations {
        address shift;
        address admin;
        address colOperations;
        address debtOperations;
        address perfectOperationsAndOracle;
    }

    struct ConstantViews {
        uint256 dexId;
        address liquidity;
        address factory;
        Implementations implementations;
        address deployerContract;
        address token0;
        address token1;
        bytes32 supplyToken0Slot;
        bytes32 borrowToken0Slot;
        bytes32 supplyToken1Slot;
        bytes32 borrowToken1Slot;
        bytes32 exchangePriceToken0Slot;
        bytes32 exchangePriceToken1Slot;
        uint256 oracleMapping;
    }

    function constantsView()
        external
        view
        returns (ConstantViews memory constantsView_);
}

interface ILiquidity {
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
}

// ===== contracts/vault/common/variables.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces.sol";
import "../../infiniteProxy/IProxy.sol";

/// @title      Variables
/// @notice     Contains common storage variables of all modules of Infinite proxy.
contract ConstantVariables {
    address internal constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant RAY_MINUS_ONE = RAY - 1;
    uint256 internal constant MAX_UINT256_MINUS_RAY_MINUS_ONE =
        MAX_UINT256 - RAY_MINUS_ONE;

    IInstaIndex internal constant INSTA_INDEX_CONTRACT =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDRESS);
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDRESS);
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;
    address internal constant SP_WSTETH_ADDRESS_SPARK =
        0x12B54025C112Aa61fAce2CDB7118740875A566E9;
    address internal constant A_WSTETH_ADDRESS_AAVEV3_LIDO =
        0xC035a7cf15375cE2706766804551791aD035E0C2;

    /***********************************|
    |           EETH ADDRESSES        |
    |__________________________________*/
    address internal constant EETH_ADDRESS =
        0x35fA164735182de50811E8e2E824cFb9B6118ac2;

    /***********************************|
    |           WeETH ADDRESSES        |
    |__________________________________*/
    address internal constant WEETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    IWeEth internal constant WEETH_CONTRACT = IWeEth(WEETH_ADDRESS);
    address internal constant A_WEETH_ADDRESS_AAVEV3 =
        0xBdfa7b7893081B35Fb54027489e2Bc7A38275129;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant D_WETH_ADDRESS_SPARK =
        0x2e7576042566f8D6990e07A1B61Ad1efd86Ae70d;
    address internal constant D_WETH_ADDRESS_AAVEV3_LIDO =
        0x91b7d78BF92db564221f6B5AeE744D1727d1Dd1e;

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    address internal constant KING_ADDRESS =
        0x8F08B70456eb22f6109F57b8fafE862ED28E6040;

    ILiteVaultV1 internal constant LITE_VAULT_V1 = ILiteVaultV1(IETH_TOKEN_V1);

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    ILidoWithdrawalQueue internal constant LIDO_WITHDRAWAL_QUEUE =
        ILidoWithdrawalQueue(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

    ILiquidity internal constant LIQUIDITY =
        ILiquidity(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);

    IFluidVaultT1 internal constant FLUID_VAULT =
        IFluidVaultT1(FLUID_VAULT_ADDRESS);

    IFluidVaultT1 internal constant FLUID_VAULT_NEW =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_NEW);

    IFluidVaultT1 internal constant FLUID_VAULT_WEETH_WSTETH =
        IFluidVaultT1(FLUID_VAULT_ADDRESS_WEETH_WSTETH);

    address internal constant FLUID_VAULT_ADDRESS =
        0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91;

    address internal constant FLUID_VAULT_ADDRESS_NEW =
        0x82B27fA821419F5689381b565a8B0786aA2548De;

    address internal constant FLUID_VAULT_ADDRESS_WEETH_WSTETH =
        0xeAEf563015634a9d0EE6CF1357A3b205C35e028D;

    uint256 internal constant FLUID_NFT_ID_NEW = 1566;

    uint256 internal constant FLUID_NFT_WEETH_WSTETH = 6486;

    address internal constant FLUID_DEX_ADDRESS =
        address(0x0B1a513ee24972DAEf112bC777a5610d4325C9e7);

    IFluidDexT1 internal constant FLUID_DEX = IFluidDexT1(FLUID_DEX_ADDRESS);

    address internal constant FLUID_DEX_VAULT_ADDRESS =
        0x528CF7DBBff878e02e48E83De5097F8071af768D;

    IFluidVaultT4 internal constant FLUID_VAULT_T4 =
        IFluidVaultT4(FLUID_DEX_VAULT_ADDRESS);

    uint256 internal constant X8 = 0xff;

    uint256 internal constant X19 = 0x7ffff;

    uint256 internal constant X64 = 0xffffffffffffffff;

    uint256 internal constant X128 = 0xffffffffffffffffffffffffffffffff;
}

contract Variables is ConstantVariables {
    /****************************************************************************|
    |   @notice Ids associated with protocols at the time of deployment.         |
    |   New protocols might have been added or removed at the time of viewing.   |
    |                          AAVE_V2 => 1 // Disabled                          |
    |                          AAVE_V3 => 2                                      |
    |                          COMPOUND_V3 => 3                                  |
    |                          EULER => 4 // Disabled                            |
    |                          MORPHO_AAVE_V2 => 5 // Disabled                   |
    |                          MORPHO_AAVE_V3 => 6 // Disabled                   |
    |                          SPARK => 7                                        |
    |                          FLUID => 8 // Disabled                            |
    |                          FLUID_NEW => 9                                    |
    |                          AAVE V3 LIDO => 10                                |
    |                          FLUID_DEX => 11                                   |
    |                          FLUID_WEETH_WSTETH => 12                          |
    |___________________________________________________________________________*/

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    // 1: open; 2: closed
    uint8 internal _status;

    IDSA public vaultDSA;

    /// @notice Max limit (in wei) allowed for wsteth per eth unit amount.
    uint256 public leverageMaxUnitAmountLimit;

    /// @notice Secondary auth that only has the power to reduce max risk ratio.
    address public secondaryAuth;

    // Current exchange price.
    uint256 public exchangePrice;

    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public revenueExchangePrice;

    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;

    // Mapping of protocol id => max risk ratio, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    // 1 = Aave v2 // Disabled
    // 2 = Aave v3
    // 3 = Compound v3 (ETH market)
    // 4 = Euler // Disabled
    // 5 = Morpho Aave v2 // Disabled
    // 6 = Morpho Aave v3 // Disabled
    // 7 = Spark
    // 8 = Fluid // Disabled
    // 9 = Fluid New
    // 10 = Aave V3 Lido
    // 11 = Fluid Dex
    // 12 = Fluid WeETH WstETH
    mapping(uint8 => uint256) public maxRiskRatio;

    // Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    uint256 public aggrMaxVaultRatio;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    uint256 public withdrawalFeePercentage;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    uint256 public withdrawFeeAbsoluteMin; // in underlying base asset, i.e. stEth

    // charge from the profits, scaled to factor 4.
    // 100,000 would be 10% cut from profit
    uint256 public revenueFeePercentage;

    /// @notice Stores profit revenue and withdrawal fees collected.
    uint256 public revenue;

    /// @notice Revenue will be transffered to this address upon collection.
    address public treasury;

    /// @notice Tracker for amount of stETH queued for withdrawal.
    uint256 public queuedWithdrawStEth;

    /// @notice DSA's NFT ID for fluid vault T4.
    uint256 public fluidDexNFT;

    /// @notice allocation to team multisig - in wstETH
    uint256 public allocationToTeamMultisig;

    /// @notice max allocation to team multisig - in wstETH (for future use)
    uint256 public maxAllocationToTeamMultisig;

}

/// @title      PrimaryHelpers
/// @notice     Contains common modifiers of all modules of Infinite proxy.
contract PrimaryHelpers is Variables {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();
    error Helpers__ProtocolDisabled();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    modifier onlyRebalancer() {
        if (
            !(isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert Helpers__NotRebalancer();
        }
        _;
    }

    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        if (_status == 2) revert Helpers__Reentrant();
        _status = 2;
        _;
        _status = 1;
    }

    /// @notice Implements a method to read uint256 data from storage at a bytes32 storage slot key.
    function readFromStorage(
        bytes32 slot_
    ) public view returns (uint256 result_) {
        assembly {
            result_ := sload(slot_) // read value from the storage slot
        }
    }
}

// ===== contracts/vault/common/variablesBuffer.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBuffer
/// @notice     Allocates space of 151 slots to maintain storage 
///             consistency with imported variables in VariablesPrimaryHelper.

contract VariablesBuffer {
    uint[151] internal __buffergap;
}
// ===== contracts/vault/common/variablesBufferHelper.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title      VariablesBufferHelper
/// @notice     Buffer Helper for variables that imports all the primary 
///             helpers from the storage slot 152.

import {VariablesBuffer} from "./variablesBuffer.sol";
import {PrimaryHelpers} from "./variables.sol";

// Buffer & variables
contract VariablesBufferHelper is VariablesBuffer, PrimaryHelpers {
}
// ===== contracts/vault/modules/common/interface.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsAaveV3 {
        uint256 wstETH; // supply
        uint256 weETH; // supply
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH supply converted to stETH
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsFluidWeETH {
        uint256 weETH; // supply
        uint256 wstETH; // borrow
        uint256 eETH; // weETH supply converted to eETH
        uint256 stETH; // wstETH borrow converted to stETH
    }

    struct ProtocolAssetsInDexWstETH {
        uint256 wstETHSupply;
        uint256 ethSupply;
        uint256 wstETHBorrow;
        uint256 stETHBorrow;
        uint256 ethBorrow;
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 eETH;
        uint256 weETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsAaveV3 aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH spark;
        ProtocolAssetsInWstETH fluidNew;
        ProtocolAssetsInWstETH aaveV3Lido;
        ProtocolAssetsInDexWstETH fluidDex;
        ProtocolAssetsFluidWeETH fluidWeETH;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    function getProtocolRatio(uint8 protocolId_) external view returns (uint256 ratio_);
    
    function getNetAssets()
        external
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        );

    function getWithdrawFee(uint256 stETHAmount_) external view returns (uint256);

    function getRatioAaveV3(
        uint256 eEthPerWeETH_,
        uint256 stEthPerWsteth_
    )
        external
        view
        returns (
            uint256 wstEthAmount_,
            uint256 weEthAmount_,
            uint256 eEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
    );

    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}
// ===== contracts/vault/modules/fluidAaveV3WeETHRebalancerModule/events.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Events {
    event LogRebalanceFromWeETHToWstETH(
        uint256 indexed weEthFlashloanAmount_,
        uint256 indexed wstEthBorrowAmount_,
        uint256 indexed route_
    );

    event LogRebalanceFromWstETHToWeETH(
        uint256 indexed wstEthFlashloanAmount_,
        uint256 indexed weEthWithdrawAmount_,
        uint256 indexed route_
    );
}

// ===== contracts/vault/modules/fluidAaveV3WeETHRebalancerModule/main.sol =====
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./events.sol";
import "../../common/variablesBufferHelper.sol";

import {IVault} from "../common/interface.sol";

// @title FluidAaveV3WeETHRebalancerModule
// @notice For Aave V3 only - Protocol Id = 2
// @notice This module is designed to rebalance the Aave V3 (weETH / ETH) position to Fluid Vault's (weETH / wstETH) NFT,
// and then use the borrowed wstETH to supply to Aave V3 in order to convert the position back to (wstETH / ETH).
// @notice Before using this module, please make sure the Aave V3 position is at safer ratio.

contract FluidAaveV3WeETHRebalancerModule is VariablesBufferHelper, Events {
  /***********************************|
  |              ERRORS               |
  |__________________________________*/
  error FluidAaveV3WeETHRebalancerModule__Unsafe();

  /// @notice Rebalances the Aave V3 (weETH / ETH) position to (wstETH / ETH) position by creating a Fluid Vault's (weETH / wstETH) position.
  /// @param weEthFlashloanAmount_ The amount of weETH to take flashloan.
  /// @param wstEthBorrowAmount_ The amount of wstETH to borrow from Fluid.
  /// @param route_ The flashloan route.
  function rebalanceFromWeETHToWstETH(
    uint256 weEthFlashloanAmount_,
    uint256 wstEthBorrowAmount_,
    uint256 route_
  ) external payable nonReentrant onlyRebalancer {
    string[] memory targets_ = new string[](4);
    bytes[] memory calldatas_ = new bytes[](4);

    // Supply weETH to Fluid Vault
    targets_[0] = "FLUID-A";
    calldatas_[0] = abi.encodeWithSignature(
       "operate(address,uint256,int256,int256,uint256)",
        FLUID_VAULT_ADDRESS_WEETH_WSTETH,
        FLUID_NFT_WEETH_WSTETH,
        int256(weEthFlashloanAmount_),
        int256(wstEthBorrowAmount_),
        0
    );

    // Supply borrowed wstETH to Aave V3
    targets_[1] = "AAVE-V3-A";
    calldatas_[1] = abi.encodeWithSignature(
      "deposit(address,uint256,uint256,uint256)",
      WSTETH_ADDRESS,
      wstEthBorrowAmount_,
      0,
      0
    );

    // Withdraw weETH from Aave V3
    targets_[2] = "AAVE-V3-A";
    calldatas_[2] = abi.encodeWithSignature(
      "withdraw(address,uint256,uint256,uint256)",
      WEETH_ADDRESS,
      weEthFlashloanAmount_,
      0,
      0
    );

    // Payback weETH to the flashloan provider
    targets_[3] = "INSTAPOOL-D";
    calldatas_[3] = abi.encodeWithSignature(
      "flashPayback(address,uint256,uint256,uint256)",
      WEETH_ADDRESS,
      weEthFlashloanAmount_,
      0,
      0
    );

    bytes memory encodedFlashData_ = abi.encode(targets_, calldatas_);

    // Execute the batch call to the flashloan target
    string[] memory flashTarget = new string[](1);
    bytes[] memory flashCalldata = new bytes[](1);

    flashTarget[0] = "INSTAPOOL-D";
    flashCalldata[0] = abi.encodeWithSignature(
      "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
      WEETH_ADDRESS,
      weEthFlashloanAmount_,
      route_,
      encodedFlashData_,
      "0x"
    );

    vaultDSA.cast(flashTarget, flashCalldata, address(this));

    uint256 fromRatio_ = IVault(address(this)).getProtocolRatio(2);
    uint256 toRatio_ = IVault(address(this)).getProtocolRatio(12);

    if (fromRatio_ > maxRiskRatio[2] || toRatio_ > maxRiskRatio[12]) {
      revert FluidAaveV3WeETHRebalancerModule__Unsafe();
    }

    emit LogRebalanceFromWeETHToWstETH(weEthFlashloanAmount_, wstEthBorrowAmount_, route_);
  }

  /// @notice Rebalances the Aave V3 (wstETH / ETH) position to (weETH / ETH) position by removing the Fluid Vault's (weETH / wstETH) position.
  /// @param wstEthFlashloanAmount_ The amount of wstETH to borrow from Fluid.
  /// @param weEthWithdrawAmount_ The amount of weETH to withdraw from Aave V3.
  /// @param route_ The flashloan route.
  function rebalanceFromWstETHToWeETH(
    uint256 wstEthFlashloanAmount_,
    uint256 weEthWithdrawAmount_,
    uint256 route_
  ) external payable nonReentrant onlyRebalancer {
    string[] memory targets_ = new string[](4);
    bytes[] memory calldatas_ = new bytes[](4);

    // Payback wstETH on Fluid Vault & withdraw weETH
    targets_[0] = "FLUID-A";
    calldatas_[0] = abi.encodeWithSignature(
       "operate(address,uint256,int256,int256,uint256)",
       FLUID_VAULT_ADDRESS_WEETH_WSTETH,
       FLUID_NFT_WEETH_WSTETH,
       -int256(weEthWithdrawAmount_),
       -int256(wstEthFlashloanAmount_),
       wstEthFlashloanAmount_
    );

    // Deposit weETH to Aave V3
    targets_[1] = "AAVE-V3-A";
    calldatas_[1] = abi.encodeWithSignature(
      "deposit(address,uint256,uint256,uint256)",
      WEETH_ADDRESS,
      weEthWithdrawAmount_,
      0,
      0
    );

    // Withdraw wstETH from Aave V3
    targets_[2] = "AAVE-V3-A";
    calldatas_[2] = abi.encodeWithSignature(
      "withdraw(address,uint256,uint256,uint256)",
      WSTETH_ADDRESS,
      wstEthFlashloanAmount_,
      0,
      0
    );

    // Payback wstETH to the flashloan provider
    targets_[3] = "INSTAPOOL-D";
    calldatas_[3] = abi.encodeWithSignature(
      "flashPayback(address,uint256,uint256,uint256)",
      WSTETH_ADDRESS,
      wstEthFlashloanAmount_,
      0,
      0
    );

    bytes memory encodedFlashData_ = abi.encode(targets_, calldatas_);

    // Execute the batch call to the flashloan target
    string[] memory flashTarget = new string[](1);
    bytes[] memory flashCalldata = new bytes[](1);

    flashTarget[0] = "INSTAPOOL-D";
    flashCalldata[0] = abi.encodeWithSignature(
      "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
      WSTETH_ADDRESS,
      wstEthFlashloanAmount_,
      route_,
      encodedFlashData_,
      "0x"
    );

    vaultDSA.cast(flashTarget, flashCalldata, address(this));

    uint256 fromRatio_ = IVault(address(this)).getProtocolRatio(2);
    uint256 toRatio_ = IVault(address(this)).getProtocolRatio(12);

    if (fromRatio_ > maxRiskRatio[2] || toRatio_ > maxRiskRatio[12]) {
      revert FluidAaveV3WeETHRebalancerModule__Unsafe();
    }

    emit LogRebalanceFromWstETHToWeETH(wstEthFlashloanAmount_, weEthWithdrawAmount_, route_);
  }
}
