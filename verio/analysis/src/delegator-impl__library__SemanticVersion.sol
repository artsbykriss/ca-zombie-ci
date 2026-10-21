// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Strings.sol";

library SemanticVersion {
    using Strings for uint256;

    /// @notice Error for invalid version strings
    error InvalidVersion();

    /// @notice V structure
    /// @param major The major version number
    /// @param minor The minor version number
    /// @param patch The patch version number
    struct V {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }
    
    /// @notice Parse a version string into its components
    /// @param _version Version string (e.g., "v1.2.3" or "1.2.3")
    /// @return V struct with major, minor, patch numbers
    function parse(string memory _version) internal pure returns (V memory) {
        // Remove 'v' prefix if present
        bytes memory versionBytes = bytes(_version);
        uint256 startIndex = 0;
        if (versionBytes[0] == "v") {
            startIndex = 1;
        }
        
        V memory result;
        uint256 component = 0;  // 0 = major, 1 = minor, 2 = patch
        uint256 value = 0;
        
        for (uint256 i = startIndex; i < versionBytes.length; i++) {
            if (versionBytes[i] == ".") {
                if (component == 0) result.major = value;
                else if (component == 1) result.minor = value;
                else revert InvalidVersion();
                
                component++;
                value = 0;
                continue;
            }
            
            uint8 digit = uint8(versionBytes[i]) - 48; // Convert ASCII to number
            if (digit > 9) revert InvalidVersion();
            
            value = value * 10 + digit;
        }
        
        // Set final component (patch)
        if (component != 2) revert InvalidVersion();
        result.patch = value;
        
        return result;
    }
    
    /// @notice Validate the next version, based on semantic versioning rules
    /// @return true if current < next, false if current >= next
    function validateNextVersion(V memory _current, V memory _next) internal pure returns (bool) {
        if (_current.major != _next.major) {
            return _current.major < _next.major;
        }
        if (_current.minor != _next.minor) {
            return _current.minor < _next.minor;
        }
        if (_current.patch != _next.patch) {
            return _current.patch < _next.patch;
        }
        return false;
    }

    function toString(V memory _version) internal pure returns (string memory) {
        return string.concat(
            "v",
            _version.major.toString(),
            ".",
            _version.minor.toString(),
            ".",
            _version.patch.toString()
        );
    }

    function bump(V memory _version, string calldata _bumpType) internal pure returns (V memory nextVersion) {
        if (keccak256(bytes(_bumpType)) == keccak256(bytes("major"))) {
            nextVersion.major = _version.major + 1;
            nextVersion.minor = 0;
            nextVersion.patch = 0;
        } else if (keccak256(bytes(_bumpType)) == keccak256(bytes("minor"))) {
            nextVersion.major = _version.major;
            nextVersion.minor = _version.minor + 1;
            nextVersion.patch = 0;
        } else if (keccak256(bytes(_bumpType)) == keccak256(bytes("patch"))) {
            nextVersion.major = _version.major;
            nextVersion.minor = _version.minor;
            nextVersion.patch = _version.patch + 1;
        }
        return nextVersion;
    }
}
