// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/**
 * @title   g8keepPenaltyReceiver
 * @notice  Receives tokens from g8keep snipe protection penalties for [redacted].
 */
contract g8keepPenaltyReceiver is Ownable {
    /// @dev Mapping of addresses that are allowed to transfer tokens from the penalty receiver.
    mapping(address => uint256) public allowedTransferers;

    /// @dev Guardrail to prevent a newly added transferer from transfering tokens immediately.
    uint256 private constant ALLOWED_TIME_DELAY = 1 days;

    /// @dev Thrown when allowing or removing a transferer and no change would be made.
    error NoUpdate();
    /// @dev Thrown when a transfer request is made by an address that is not allowed.
    error NotAllowed();
    /// @dev Thrown when withdrawing a token from the contract and the withdrawal fails.
    error WithdrawalFailed();
    /// @dev Thrown when attempting to set the zero address as an allowed transferer.
    error ZeroAddress();
    
    /// @dev Emitted when the penalty receiver owner updates an allowed transferer.
    event AllowedTransfererUpdated(address indexed transferer, bool allowed, uint256 allowedTime);

    modifier onlyAllowedTransferer() {
        uint256 allowedTime = allowedTransferers[msg.sender];
        if (allowedTime == 0 || allowedTime > block.timestamp) {
            revert NotAllowed();
        }
        _;
    }

    /**
     * @dev Constructs the g8keepPenaltyReceiver contract.
     * 
     * @param _defaultOwner  The address of the default owner of the contract.
     */
    constructor(address _defaultOwner) {
        _initializeOwner(_defaultOwner);
    }

    /////////// OWNER FUNCTIONS ///////////

    /**
     * @notice Admin function to configure a paired token.
     *
     * @param transferer  Address of the address to set allowed.
     * @param allowed     True if the address is allowed to transfer tokens, false if not.
     */
    function setAllowedTransferer(
        address transferer,
        bool allowed
    ) external onlyOwner {
        if (transferer == address(0)) {
            revert ZeroAddress();
        }
        uint256 allowedTime = allowedTransferers[transferer];
        if (allowed) {
            if (allowedTime > 0) {
                revert NoUpdate();
            }
            unchecked {
                allowedTime = block.timestamp + ALLOWED_TIME_DELAY;
            }
        } else {
            if (allowedTime == 0) {
                revert NoUpdate();
            }
            allowedTime = 0;
        }
        allowedTransferers[transferer] = allowedTime;

        emit AllowedTransfererUpdated(transferer, allowed, allowedTime);
    }

    /////////// TRANSFERER FUNCTIONS ///////////

    /**
     * @notice  Transfers an `amount` of `tokenAddress` from the contract to `to`.
     * 
     * @dev     Throws when called by an address that is not an allowed transferer.
     * 
     * @param tokenAddress  Address of the token to transfer.
     * @param to            Address to transfer the token to.
     * @param amount        Amount of the token to transfer.
     */
    function transferToken(address tokenAddress, address to, uint256 amount) external onlyAllowedTransferer {
        SafeTransferLib.safeTransfer(tokenAddress, to, amount);
    }
}
