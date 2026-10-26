// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Pricer } from "./Pricer.sol";
import { Auth, Authority } from "solmate/auth/Auth.sol";

import { VaultToken } from "./VaultToken.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

contract Depositor is Auth {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

    uint256 public constant BASE = 1e4;
    address public depositReceiver;
    address public immutable vaultToken;
    Pricer public pricer;
    bool public isPaused;
    mapping(address => bool) public isDepositToken;
    uint256 public depositFee;
    address public depositFeeRecipient;
    uint256 public depositCap;

    error Depositor__Paused();
    error Depositor__NotDepositToken(address _token);
    error Depositor__DepositCapReached();
    error Depositor__InvalidDepositCap();

    event DepositTokenSet(address _token, bool _isDepositToken);
    event PauseToggled(bool _isPaused);
    event DepositReceiverSet(address _depositReceiver);
    event PricerSet(address _pricer);
    event DepositFeeSet(uint256 _depositFee);
    event DepositFeeRecipientSet(address _depositFeeRecipient);
    event Deposit(
        address _token,
        address _receiver,
        uint256 _amount,
        uint256 _vaultTokenAmount,
        uint256 _feeAmount,
        bytes32 _builderCode
    );
    event DepositCapSet(uint256 _depositCap);

    constructor(
        address _owner,
        address _depositReceiver,
        address _shareToken,
        address _pricer
    )
        Auth(_owner, Authority(address(0)))
    {
        depositReceiver = _depositReceiver;
        vaultToken = _shareToken;
        pricer = Pricer(_pricer);
    }

    /**
     * @notice Deposits tokens into the vault
     * @param _token The address of the token
     * @param _receiver The address of the receiver
     * @param _amount The amount of tokens to deposit
     * @param _builderCode The builder code
     */
    function deposit(address _token, address _receiver, uint256 _amount, bytes32 _builderCode) external {
        if (isPaused) {
            revert Depositor__Paused();
        }
        if (!isDepositToken[_token]) {
            revert Depositor__NotDepositToken(_token);
        }
        uint256 feeAmount;
        if (depositFee > 0 && depositFeeRecipient != address(0)) {
            feeAmount = _amount.mulDiv(depositFee, BASE);
            _token.safeTransferFrom(msg.sender, depositFeeRecipient, feeAmount);
            _amount -= feeAmount;
        }
        uint256 vaultTokenAmount = pricer.getVaultTokenAmount(_token, _amount);
        if (depositCap > 0) {
            if (VaultToken(vaultToken).totalSupply() + vaultTokenAmount > depositCap) {
                revert Depositor__DepositCapReached();
            }
        }
        _token.safeTransferFrom(msg.sender, depositReceiver, _amount);
        VaultToken(vaultToken).mint(_receiver, vaultTokenAmount);
        emit Deposit(_token, _receiver, _amount, vaultTokenAmount, feeAmount, _builderCode);
    }

    /**
     * @notice Toggles the deposit token
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _token The address of the token
     * @param _isDepositToken The status of the deposit token
     */
    function toggleDepositToken(address _token, bool _isDepositToken) external requiresAuth {
        isDepositToken[_token] = _isDepositToken;
        emit DepositTokenSet(_token, _isDepositToken);
    }

    /**
     * @notice Toggles the paused state
     * @dev Only callable by addresses with ADMIN_ROLE
     */
    function togglePaused() external requiresAuth {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Sets the deposit receiver
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _depositReceiver The address of the deposit receiver
     */
    function setDepositReceiver(address _depositReceiver) external requiresAuth {
        depositReceiver = _depositReceiver;
        emit DepositReceiverSet(_depositReceiver);
    }

    /**
     * @notice Sets the pricer
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _pricer The address of the pricer
     */
    function setPricer(address _pricer) external requiresAuth {
        pricer = Pricer(_pricer);
        emit PricerSet(_pricer);
    }

    /**
     * @notice Sets the deposit fee
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _depositFee The deposit fee
     */
    function setDepositFee(uint256 _depositFee) external requiresAuth {
        depositFee = _depositFee;
        emit DepositFeeSet(_depositFee);
    }

    /**
     * @notice Sets the deposit fee recipient
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _depositFeeRecipient The deposit fee recipient
     */
    function setDepositFeeRecipient(address _depositFeeRecipient) external requiresAuth {
        depositFeeRecipient = _depositFeeRecipient;
        emit DepositFeeRecipientSet(_depositFeeRecipient);
    }

    /**
     * @notice Sets the deposit cap
     * @dev Only callable by addresses with ADMIN_ROLE
     * @param _depositCap The deposit cap
     */
    function setDepositCap(uint256 _depositCap) external requiresAuth {
        if (_depositCap < VaultToken(vaultToken).totalSupply()) {
            revert Depositor__InvalidDepositCap();
        }
        depositCap = _depositCap;
        emit DepositCapSet(_depositCap);
    }
}
