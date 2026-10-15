// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { ICegaEntry } from "../../cega-entry/interfaces/ICegaEntry.sol";

interface IAddressManager {
    /**
     * @dev Emitted when a new CegaEntry is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationParams The params of the implementation update
     */
    event CegaEntryCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        ICegaEntry.ProxyImplementation[] indexed implementationParams
    );

    /**
     * @dev Emitted when the CegaEntry is updated.
     * @param implementationParams The old address of the CegaEntry
     * @param _init The new address to call upon upgrade
     * @param _calldata The calldata input for the call
     */
    event CegaEntryUpdated(
        ICegaEntry.ProxyImplementation[] indexed implementationParams,
        address _init,
        bytes _calldata
    );

    /**
     * @dev Emitted when a new address is set
     * @param id The identifier of the proxy
     * @param oldAddress The previous address assoicated with the id
     * @param newAddress The new address set to the id
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when asset wrapping proxy is updated
     * @param asset The address of the asset.
     * @param proxy The address of the new proxy.
     */
    event AssetProxyUpdated(address asset, address proxy);

    /**
     * @dev Returns the address of the Cega Oracle.
     * @return The address of the Cega Oracle.
     */
    function getCegaOracle() external view returns (address);

    /**
     * @dev Returns the address of the Cega Entry.
     * @return The address of the Cega Entry.
     */
    function getCegaEntry() external view returns (address);

    /**
     * @dev Returns the address of the Trade Winner NFT.
     * @return The address of the Trade Winner NFT.
     */
    function getTradeWinnerNFT() external view returns (address);

    /**
     * @dev Returns the address of the ACL Manager.
     * @return The address of the ACL Manager.
     */
    function getACLManager() external view returns (address);

    /**
     * @dev Returns the address of the Redeposit Manager.
     * @return The address of the Redeposit Manager.
     */
    function getRedepositManager() external view returns (address);

    /**
     * @dev Returns the address of the Cega Fee Receiver.
     * @return The address of the Cega Fee Receiver.
     */
    function getCegaFeeReceiver() external view returns (address);

    /**
     * @dev Retrieves the address associated with a given ID.
     * @param id The bytes32 ID.
     * @return The associated address.
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @dev Retrieves the asset wrapping proxy address for a given asset.
     * @param asset The address of the asset.
     * @return The address of the asset wrapping proxy.
     */
    function getAssetWrappingProxy(
        address asset
    ) external view returns (address);

    /**
     * @dev Sets the address of the Cega Entry contract.
     * @param newAddress The new address of the Cega Entry contract.
     */
    function setCegaEntry(address newAddress) external;

    /**
     * @dev Sets the address of the Trade Winner NFT contract.
     * @param newAddress The new address of the Trade Winner NFT contract.
     */
    function setTradeWinnerNFT(address newAddress) external;

    /**
     * @dev Sets the address of the Cega Oracle contract.
     * @param newAddress The new address of the Cega Oracle contract.
     */
    function setCegaOracle(address newAddress) external;

    /**
     * @dev Sets the address of the Redeposit Manager contract.
     * @param newAddress The new address of the Redeposit Manager contract.
     */
    function setRedepositManager(address newAddress) external;

    /**
     * @dev Sets the address of the Cega Fee Receiver address.
     * @param newAddress The new address of the Cega Fee Receiver contract.
     */
    function setCegaFeeReceiver(address newAddress) external;

    /**
     * @dev Sets the address of the ACL Manager contract.
     * @param newAddress The new address of the ACL Manager contract.
     */
    function setACLManager(address newAddress) external;

    /**
     * @dev Sets a new address for a given ID.
     * @param id The bytes32 ID.
     * @param newAddress The new address to be associated with the ID.
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @dev Sets a new asset wrapping proxy for a given asset.
     * @param asset The address of the asset.
     * @param proxy The address of the new proxy.
     */
    function setAssetWrappingProxy(address asset, address proxy) external;

    /**
     * @dev Updates the implementation of the Cega Entry.
     * @param implementationParams An array of new implementation parameters.
     * @param _init The address to call upon upgrade.
     * @param _calldata The calldata input for the call.
     */
    function updateCegaEntryImpl(
        ICegaEntry.ProxyImplementation[] calldata implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;
}
