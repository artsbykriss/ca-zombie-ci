// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {
    IPYieldToken
} from "@pendle/core-v2/contracts/interfaces/IPYieldToken.sol";
import { EntryBase } from "./EntryBase.sol";
import { AdhocStorage } from "../../storage/AdhocStorage.sol";
import { CegaAdhocStorage } from "../../Structs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { Errors } from "../../utils/Errors.sol";
import { IPendleEntry } from "./interfaces/IPendleEntry.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";

contract PendleEntry is ReentrancyGuard, AdhocStorage, IPendleEntry {
    // IMMUTABLE

    IAddressManager internal immutable addressManager;

    ITreasury internal immutable treasury;

    // MODIFIERS

    /**
     * @dev Modifier to restrict access to Cega admins.
     */
    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    // CONSTRUCTOR

    constructor(IAddressManager _addressManager, ITreasury _treasury) {
        addressManager = _addressManager;
        treasury = _treasury;
    }

    // FUNCTIONS

    /**
     * @dev See {IPendleEntry-claimPendleYield}.
     */
    function claimPendleYield(
        address user,
        address[] calldata ytAddresses,
        uint256[] calldata amounts,
        bytes[] calldata signatures
    ) external nonReentrant {
        require(
            ytAddresses.length == amounts.length &&
                ytAddresses.length == signatures.length,
            Errors.INVALID_ARRAY_LENGTH
        );

        CegaAdhocStorage storage cas = getStorage();

        address yieldClaimSigner = cas.yieldClaimSigner;

        for (uint256 i = 0; i < ytAddresses.length; i++) {
            bytes32 digest = ECDSA.toEthSignedMessageHash(
                abi.encode(ytAddresses[i], user, amounts[i], block.chainid)
            );
            address signer = ECDSA.recover(digest, signatures[i]);
            require(signer == yieldClaimSigner, Errors.INVALID_SIGNATURE);

            uint256 claimed = cas.claimedAmounts[ytAddresses[i]][user];
            require(claimed < amounts[i], Errors.VALUE_IS_ZERO);

            // Calculate new yield
            uint256 newYield = amounts[i] - claimed;
            cas.claimedAmounts[ytAddresses[i]][user] = amounts[i];

            // Claim pending yield
            IPYieldToken(ytAddresses[i]).redeemDueInterestAndRewards(
                address(treasury),
                true,
                true
            );

            // Transfer yield to the user
            address syToken = IPYieldToken(ytAddresses[i]).SY();
            treasury.withdraw(syToken, user, newYield, false);

            emit PendleRewardClaimed(user, ytAddresses[i], newYield);
        }
    }

    /**
     * @dev See {IPendleEntry-updateYieldClaimSigner}.
     */
    function updateYieldClaimSigner(address signer) external onlyCegaAdmin {
        CegaAdhocStorage storage cas = getStorage();

        cas.yieldClaimSigner = signer;

        emit YieldClaimSignerUpdated(signer);
    }

    /**
     * @dev See {IPendleEntry-getUserClaimedYieldAmount}.
     */
    function getUserClaimedYieldAmount(
        address token,
        address user
    ) external view returns (uint256) {
        CegaAdhocStorage storage cas = getStorage();

        return cas.claimedAmounts[token][user];
    }

    /**
     * @dev See {IPendleEntry-getYieldClaimSigner}.
     */
    function getYieldClaimSigner() external view returns (address) {
        CegaAdhocStorage storage cas = getStorage();

        return cas.yieldClaimSigner;
    }
}
