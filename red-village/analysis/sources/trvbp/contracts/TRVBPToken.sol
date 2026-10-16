// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract TRVBPToken is ERC721Enumerable, VRFConsumerBase, Ownable {
  using Strings for uint256;

  struct Champion {
    string name;
    uint16 background;
    uint16 bloodline;
    uint16 genotype;
    uint16 character_class;
    uint16 breed;
    uint16 armour_color;
    uint16[3] hair; // [0] = hair_color, [1] = hair_class, [2] = hair_style.
    uint16[2] warpaint; // [0] = warpaint color, [1] = warpaint style
  }

  // // traits
  string[1] private BACKGROUNDS = ['Black'];
  string[1] private BLOODLINES = ['Genesis'];
  string[3] private GENOTYPES = ['R1', 'R2', 'R3'];
  string[5] private CHARACTER_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  string[7] private BREEDS = ['Undead', 'Orc', 'Half Dwarf', 'Origin', 'High Born', 'Nordic', 'Elf'];
  string[47] private ARMOUR_COLORS = [
    'Snowfall', 'Meadowlight', 'Rune', 'Emerald', 'Stategreen', 'Forestdeep', 'Frost', 'Coldshade', 'Rainstorm', 'Thundercloud',
    'Gloombane', 'Splendid', 'Memorial', 'Winterkill', 'Winterstorm', 'Spectral', 'Thunderstorm', 'Charcoal', 'Chaos', 'Onyx',
    'Royal Black', 'Dark of Night', 'Royal White', 'Charlemagne', 'Ivory', 'White Quartz', 'Dynasty', 'Mercia', 'Benedictine', 'Bone',
    'Alpensun', 'Coronet', 'Candlelight', 'Duskglow', 'Ochrewash', 'Firefly', 'Polarwind', 'Pennyroyal', 'Mayhem', 'Greatwood',
    'Blood', 'Brimstone', 'Crime-of-Passion', 'Red-of-War', 'Ruby Red', 'Sovereign', 'Gloom'
  ];
  string[7] private HAIR_COLORS = ['None', 'Tan', 'Blonde', 'Black', 'Gray', 'Brown', 'Auburn'];
  string[5] private HAIR_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  string[8] private HAIR_STYLES = ['Braid', 'Short', 'Wartail', 'Mohawk', 'Long', 'Bald', 'Hightail', 'Sidepart'];
  string[9] private WARPAINT_COLORS = ['None', 'Black', 'White', 'Blue', 'Yellow', 'Green', 'Silver', 'Red', 'Gold'];
  string[11] private WARPAINT_STYLES = ['None', 'Scar', 'Ragnarok', 'Trident', 'Rogue', 'Vortex', 'Sceptre', 'Hex', 'Mimic', 'Sigil', 'Crest'];

  // constants
  uint16 public constant MAX_SUPPLY = 5000;
  uint16 public constant CEIL_NUMBER = 4999;
  address public constant VRF_COORDINATOR_ADDRESS = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
  address public constant LINK_ADDRESS = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
  bytes32 public constant VRF_KEY_HASH = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
  uint256 public constant VRF_FEE = 0.0001 * (10 ** 18);

  bool public nameEnable = false;
  string public baseURI;
  string private imageURI;

  mapping (uint16 => uint16) private randoms;
  uint16 public boundary = MAX_SUPPLY;
  bool public seeded = false;
  uint256 public randomSeedNumber;

  mapping (uint16 => Champion) private champions;
  mapping (uint16 => bool) public specialList;

  constructor() ERC721('TheRedVillageGenesis', 'TRVG') VRFConsumerBase(VRF_COORDINATOR_ADDRESS, LINK_ADDRESS) {}

  function toggleNameEnable() external onlyOwner {
    nameEnable = !nameEnable;
  }

  function setTokenURI(string calldata _uri, string calldata _imageUri) external onlyOwner {
    baseURI = _uri;
    imageURI = _imageUri;
  }

  function addSpecialTokens(uint16[] calldata _tokenIds, bool _status) external onlyOwner {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      if (_exists(_tokenIds[i])) {
        specialList[_tokenIds[i]] = _status;
      }
    }
  }

  function setTokenName(uint16 _tokenId, string calldata _name) external {
    require(nameEnable, "Feature is not active.");
    require(_exists(_tokenId), "URI query for non existent token");
    require(ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "Must be admin or owner of this token.");
    require(!specialList[_tokenId] || msg.sender == owner(), "Can not modify special token.");
    require(validateName(_name) || msg.sender == owner(), "Name: Minimum 3 and maximum 20 characters.");
    champions[_tokenId].name = _name;
  }

  function mintTo(address[] calldata _owners, uint16[] calldata _tokenIds) external onlyOwner {
    require(boundary >= _tokenIds.length, "Mint: Exceed max supply.");
    require(_tokenIds.length == _owners.length, "Mint: Input data mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      address to = _owners[i];

      uint256 id = _tokenIds[i] + randomSeedNumber;
      uint256 mapperIdx = id <= CEIL_NUMBER ? id : (id - CEIL_NUMBER); // assigning index with VRF seed number.

      uint16 index = uint16(uint256(keccak256(abi.encodePacked(mapperIdx, block.timestamp, to, totalSupply(), address(this)))) % boundary) + 1; // 1 -> 5000
      uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
      randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
      boundary -= 1;

      _safeMint(to, tokenId);
    }
  }

  /**
    * @dev Returns whether `data inputs` valid.
    *
    * Return -1 if mismatch length of tokenIds, names, attributes
    * Return index of attributes out of bound
    * ex: return 111 means error at attributes[10][1]
    */
  function isValidInput(
    uint16[] calldata _tokenIds,
    string[] calldata _names,
    uint16[11][] calldata _attributes
  ) public view onlyOwner returns (int) {
    if (_tokenIds.length != _names.length) return -1;

    if (_tokenIds.length != _attributes.length) return -1;

    for(uint256 i = 0; i < _attributes.length; i++) {
      if (_attributes[i][0] >= BACKGROUNDS.length) return int(i)*11 + 0;
      if (_attributes[i][1] >= BLOODLINES.length) return int(i)*11 + 1;
      if (_attributes[i][2] >= GENOTYPES.length) return int(i)*11 + 2;
      if (_attributes[i][3] >= CHARACTER_CLASSES.length) return int(i)*11 + 3;
      if (_attributes[i][4] >= BREEDS.length) return int(i)*11 + 4;
      if (_attributes[i][5] >= ARMOUR_COLORS.length) return int(i)*11 + 5;
      if (_attributes[i][6] >= HAIR_COLORS.length) return int(i)*11 + 6;
      if (_attributes[i][7] >= HAIR_CLASSES.length) return int(i)*11 + 7;
      if (_attributes[i][8] >= HAIR_STYLES.length) return int(i)*11 + 8;
      if (_attributes[i][9] >= WARPAINT_COLORS.length) return int(i)*11 + 9;
      if (_attributes[i][10] >= WARPAINT_STYLES.length) return int(i)*11 + 10;
    }
    return -2;
  }

  function setTokenInfo(
    uint16[] calldata _tokenIds,
    string[] calldata _names,
    uint16[11][] calldata _attributes
  ) external onlyOwner {
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      champions[_tokenIds[i]] = Champion(
        _names[i],
        _attributes[i][0],
        _attributes[i][1],
        _attributes[i][2],
        _attributes[i][3],
        _attributes[i][4],
        _attributes[i][5],
        [_attributes[i][6], _attributes[i][7], _attributes[i][8]],
        [_attributes[i][9], _attributes[i][10]]
      );
    }
  }

  function getAttributes(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "URI query for non existent token");

    Champion memory champion = champions[uint16(_tokenId)];
    string memory attributes_1 = string(abi.encodePacked(
      '[{"trait_type":"Background","value":"', BACKGROUNDS[champion.background], '"},',
      '{"trait_type":"Bloodline","value":"', BLOODLINES[champion.bloodline], '"},',
      '{"trait_type":"Genotype","value":"', GENOTYPES[champion.genotype], '"},',
      '{"trait_type":"Class","value":"', CHARACTER_CLASSES[champion.character_class], '"},'
    ));
    string memory warpaint = string(abi.encodePacked(WARPAINT_COLORS[champion.warpaint[0]], " ", WARPAINT_STYLES[champion.warpaint[1]]));
    if (champion.warpaint[0] == 0 || champion.warpaint[1] == 0) {
      warpaint = "None";
    }
    string memory hair = string(abi.encodePacked(HAIR_COLORS[champion.hair[0]], " ", HAIR_CLASSES[champion.hair[1]], " ", HAIR_STYLES[champion.hair[2]]));

    if (champion.hair[0] == 0) {
      hair = string(abi.encodePacked(HAIR_CLASSES[champion.hair[1]], " ", HAIR_STYLES[champion.hair[2]]));
    }

    string memory attributes_2 = string(abi.encodePacked(
      '{"trait_type":"Breed","value":"', BREEDS[champion.breed], '"},',
      '{"trait_type":"Armour Color","value":"', ARMOUR_COLORS[champion.armour_color], '"},',
      '{"trait_type":"Hair","value":"', hair, '"},',
      '{"trait_type":"Warpaint","value":"', warpaint, '"}]'
    ));

    return string(abi.encodePacked(
      '{',
        '"name":', '"', champion.name, '",',
        '"image":', '"', imageURI, Strings.toString(_tokenId), ".png", '",',
        '"traits":', string(abi.encodePacked(attributes_1, attributes_2)),
      '}'
    ));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for non existent token");
    Champion memory champion = champions[uint16(_tokenId)];

    if (!nameEnable && isBlank(champion.name)) {
      return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    return getAttributes(_tokenId);
  }

  function isBlank(string memory _string) private pure returns (bool) {
    return bytes(_string).length == 0;
  }

  function validateName(string calldata _string) private pure returns (bool) {
    return bytes(_string).length >= 3 && bytes(_string).length <= 20;
  }

  function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
    require(!seeded, "Random already seeded");
    require(LINK.balanceOf(address(this)) >= VRF_FEE, "Not enough LINK.");
    seeded = true;
    return requestRandomness(VRF_KEY_HASH, VRF_FEE);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    randomSeedNumber = (randomness % CEIL_NUMBER) + 1; // random from 1 to 4999
  }

  function withdrawLink() external onlyOwner {
    uint256 balance = LINK.balanceOf(address(this));
    LINK.transfer(msg.sender, balance);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    require(balance > 0, "Contract balance is 0");
    payable(msg.sender).transfer(balance);
  }
}
