pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * ERC721
 * Genesis MonsterGo Egg
 */
contract EggNFT is ERC721, Ownable {

    //
    mapping(address => bool) public minters;
    uint256 public NFT_MAX_SUPPLY = 12000;
    // LaunchpadNFT
    address public LAUNCHPAD;

    struct StageInfo{
       uint256 maxSupply;
       uint256 supply;
    }

    mapping(address => StageInfo) public sellerStages;

    // Stock Setting
    mapping(address => uint256[]) private mintCatIds;
    mapping(address => mapping(uint256 => uint256)) private mintCatStocks;

    constructor(string memory _baseUri,
                string memory _name,
                string memory _symbol,
                address _launchpad)
        ERC721(_name, _symbol)
    public {
        _setBaseURI(_baseUri);
        LAUNCHPAD = _launchpad;
    }

  	modifier onlyMint() {
  		require(sellerStages[msg.sender].maxSupply > 0, "must call by mint");
  		_;
  	}

    modifier notContract() {
       require(!address(tx.origin).isContract(), "contract not allowed");
      _;
    }

    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }

    function getMaxLaunchpadSupply() view public returns (uint256) {
        return sellerStages[LAUNCHPAD].maxSupply;
    }

    function getLaunchpadSupply() view public returns (uint256) {
        return sellerStages[LAUNCHPAD].supply;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
  		_setBaseURI(_baseUri);
  	}

    function getCatId(uint256 _tokenId) public pure returns (uint256) {
  			return _tokenId.mod(1000);
  	}

    function getNextTokenID() public view returns (uint256) {
  		return ERC721.totalSupply() + 1;
  	}

    function tokenURI(uint256 _tokenId) public override virtual view returns (string memory) {
        require(_exists(_tokenId), "NONEXISTENT_TOKEN");
        uint256 _catId = getCatId(_tokenId);

        return string(abi.encodePacked(baseURI(), _tokenId.toString(), "/", _catId.toString(), ".json"));
    }

    function uri(uint256 _tokenId) public view returns (string memory) {
      return tokenURI(_tokenId);
    }

    function mintTo(address _to, uint256 _size) external onlyLaunchpad {
        require(_to != address(0), "can't mint to empty address");
        require(_size > 0, "size must greater than zero");
        require(sellerStages[LAUNCHPAD].supply + _size <= sellerStages[LAUNCHPAD].maxSupply, "max supply reached");

        for (uint256 i=1; i <= _size; i++) {
            uint256 _catId = _randomNFTCatId(LAUNCHPAD, _to, i);
            if(ERC721.totalSupply() >= NFT_MAX_SUPPLY){
                revert("Reached the limit");
            }
            uint256 _tokenId = (ERC721.totalSupply() + 1) * 1000 + _catId;
            _mint(_to, _tokenId);
            sellerStages[LAUNCHPAD].supply += 1;
        }
    }

  	function createNFT(
  		address _to,
  		uint256 _catId,
  		bytes memory _data
  	) public onlyMint returns (uint256 tokenId) {
  		require(_catId > 0 && _catId < 1000, "invalid catId");
      tokenId = (ERC721.totalSupply() + 1) * 1000 + _catId;
      if(ERC721.totalSupply() >= NFT_MAX_SUPPLY){
          revert("Reached the limit");
      }
      address _seller = msg.sender;
      mintCatStocks[_seller][_catId] = mintCatStocks[_seller][_catId].sub(1);
  		_safeMint(_to, tokenId, _data);
      sellerStages[_seller].supply += 1;

  	}

  	function burn(address _from, uint256 _tokenId) external {
  		require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "illegal request");
      require(ownerOf(_tokenId) == _from, "from is not owner");
      _burn(_tokenId);
  	}

    function setLauchpad(address _launchpad) external onlyOwner {
        LAUNCHPAD = _launchpad;
    }

    function setMintCatStocks(address _seller,
                              uint256 _maxSupply,
                              uint256[] memory _catIds,
                              uint256[] memory _stocks) external onlyOwner{
          require(_catIds.length == _stocks.length, "stocks length not match");
          StageInfo storage _stageInfo = sellerStages[_seller];
          mintCatIds[_seller] = _catIds;

          for(uint256 i = 0; i < _catIds.length; i ++){
              mintCatStocks[_seller][_catIds[i]] = _stocks[i];
          }

          _stageInfo.maxSupply = _maxSupply;

    }

    function getStock(address _seller) public view returns(uint256){
        uint256 _totalCap = 0;
        uint256[] memory _catIds = mintCatIds[_seller];
        for(uint256 i = 0; i < _catIds.length; i++){
          _totalCap = _totalCap.add(mintCatStocks[_seller][_catIds[i]]);
        }

        return _totalCap;
    }

    function getMintStocks(address _seller) public view returns(uint256[] memory, uint256[] memory){
        uint256[] memory _catIds = mintCatIds[_seller];
        uint256[] memory _stocks = new uint256[](_catIds.length);
        for(uint256 i = 0; i < _catIds.length; i ++){
            _stocks[i] = mintCatStocks[_seller][_catIds[i]];
        }

        return (_catIds, _stocks);
    }

    function _randomNFTCatId(address _seller,
                             address _to,
                             uint256 _seedNum) private notContract returns(uint256 catId) {
          uint256 _remaingNum = getStock(_seller);
          require(_remaingNum > 0, "mint Stock empty");

          uint256 _random = _seed(_to, _seedNum, _remaingNum);
          uint256 _weight = 0;
          uint256[] memory _catIds = mintCatIds[_seller];
          for(uint256 i = 0; i < _catIds.length; i++){
            _weight = _weight.add(mintCatStocks[_seller][_catIds[i]]);
            if(_weight > _random){
                catId = _catIds[i];
                mintCatStocks[_seller][catId] = mintCatStocks[_seller][catId].sub(1);
                break;
            }
          }

          return catId;
    }

    function _seed(address _user, uint256 _seedNum, uint256 _supply) internal view returns (uint256)
    {
      return uint256( uint256( keccak256(
              abi.encodePacked(_user, _supply, _seedNum, block.timestamp, block.coinbase)
            ) ) % _supply );
    }
}
