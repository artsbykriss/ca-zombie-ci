contract Nsure is DeligateERC20, Ownable {
    uint256 private constant preMineSupply  = 45 * 1e6 * 1e18;      // pre-mine
    uint256 private constant maxSupply      = 100 * 1e6 * 1e18;     // the total supply
    address private constant nsureAdmin     = 0x5Ba189D1A3E74cf3d1D38ad81F3d75cbFdbdb5bf;

    // for minters
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;


    constructor() public ERC20("Nsure Network Token", "Nsure") {
        _mint(nsureAdmin, preMineSupply);
    }


    // mint with max supply
    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        if(_amount.add(totalSupply()) > maxSupply) {
            return false;
        }

        _mint(_to, _amount);
        return true;
    }


    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "Nsure: _addMinter is the zero address");
        
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "Nsure: _delMinter is the zero address");
        
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "Nsure: caller is not the minter");
        _;
    }
}