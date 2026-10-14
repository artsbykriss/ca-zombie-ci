// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "openzeppelin/access/Ownable.sol";
import "@redstone-finance/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";

interface IDIA {
     function getValue(string memory key) external view returns (uint128, uint128);
}

/// @author OmniDex
contract SimplePriceOracle is Ownable, PriceOracle {
    using SafeMath for uint256;

    event AssetKeyUpdated(CToken indexed asset, string indexed key);
    event DIAOracleUpdated(address indexed diaOracleAddress);

    mapping(CToken => string) public assetsKeys;

    IDIA public dia;

    constructor(
        address DIAOracleAddress
    ) {
        _setDIAOracle(DIAOracleAddress);
    }

    function setAssetKey(
        CToken cToken,
        string calldata key
    ) external onlyOwner {
        require(
            (address(cToken) != address(0) && bytes(key).length != 0),
            "Invalid parameters"
        );
        assetsKeys[cToken] = key;
        emit AssetKeyUpdated(cToken, key);
    }

    /// @notice Sets the MasterOracle
    /// - Callable only by the governance
    /// @param diaOracleAddress The address of the MasterOracle
    function setDIAOracle(address diaOracleAddress) external onlyOwner {
        _setDIAOracle(diaOracleAddress);
    }

    /// @notice Internal function to set the MasterOracle
    /// @param diaOracleAddress The address of the MasterOracle
    function _setDIAOracle(address diaOracleAddress) internal {
        dia = IDIA(diaOracleAddress);
        emit DIAOracleUpdated(diaOracleAddress);
    }

    /// @notice Gets an asset price by address
    /// @param cToken The asset address
    function getUnderlyingPrice(
        CToken cToken
    ) public view override returns (uint256) {
        (uint128 price,) = dia.getValue(assetsKeys[cToken]);
        return price * (10 ** (28 - cToken.decimals()));
    }

}
