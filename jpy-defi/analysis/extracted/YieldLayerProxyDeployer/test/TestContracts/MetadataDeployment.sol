// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Script.sol";
//import "forge-std/StdAssertions.sol";
import "src/NFTMetadata/JPYdfMetadataNFT.sol";
import "src/NFTMetadata/utils/Utils.sol";
import "src/NFTMetadata/utils/FixedAssets.sol";

contract MetadataDeployment is Script /* , StdAssertions */ {
    struct File {
        bytes data;
        uint256 start;
        uint256 end;
    }

    mapping(bytes4 => File) public files;

    address public pointer;

    FixedAssetReader public initializedFixedAssetReader;

    function deployJPYdfMetadata(bytes32 _salt) public returns (JPYdfMetadataNFT) {
        _loadFiles();
        _storeFile();
        _deployFixedAssetReader(_salt);

        JPYdfMetadataNFT metadataNFT = new JPYdfMetadataNFT{salt: _salt}(initializedFixedAssetReader);

        return metadataNFT;
    }

    function _loadFiles() internal {
        string memory root = string.concat(vm.projectRoot(), "/utils/assets/");

        //emit log_string(root);

        uint256 offset = 0;

        //read JPYDF file

        bytes memory jpydfFile = bytes(vm.readFile(string.concat(root, "jpydf_logo.txt")));
        File memory jpydf = File(jpydfFile, offset, offset + jpydfFile.length);

        offset += jpydfFile.length;

        files[bytes4(keccak256("JPYDF"))] = jpydf;

        //read eth file
        bytes memory ethFile = bytes(vm.readFile(string.concat(root, "weth_logo.txt")));
        File memory eth = File(ethFile, offset, offset + ethFile.length);

        offset += ethFile.length;

        files[bytes4(keccak256("WETH"))] = eth;

        //read geist font file
        bytes memory geistFile = bytes(vm.readFile(string.concat(root, "geist.txt")));
        File memory geist = File(geistFile, offset, offset + geistFile.length);

        offset += geistFile.length;

        files[bytes4(keccak256("geist"))] = geist;
    }

    function _storeFile() internal {
        bytes memory data = bytes.concat(
            files[bytes4(keccak256("JPYDF"))].data,
            files[bytes4(keccak256("WETH"))].data,
            files[bytes4(keccak256("geist"))].data
        );

        //emit log_named_uint("data length", data.length);

        pointer = SSTORE2.write(data);
    }

    function _deployFixedAssetReader(bytes32 _salt) internal {
        bytes4[] memory sigs = new bytes4[](3);
        sigs[0] = bytes4(keccak256("JPYDF"));
        sigs[1] = bytes4(keccak256("WETH"));
        sigs[2] = bytes4(keccak256("geist"));

        FixedAssetReader.Asset[] memory FixedAssets = new FixedAssetReader.Asset[](3);
        FixedAssets[0] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("JPYDF"))].start), uint128(files[bytes4(keccak256("JPYDF"))].end)
        );
        FixedAssets[1] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("WETH"))].start), uint128(files[bytes4(keccak256("WETH"))].end)
        );
        FixedAssets[2] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("geist"))].start), uint128(files[bytes4(keccak256("geist"))].end)
        );

        initializedFixedAssetReader = new FixedAssetReader{salt: _salt}(pointer, sigs, FixedAssets);
    }
}
