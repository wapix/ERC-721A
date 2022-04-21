// SPDX-License-Identifier: MIT

// Amended by Achraf

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract MyNewContract is Ownable, ERC721A {
  using Strings for uint256;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  string private mintKey = "";
  
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public nftPerAddressLimit = 20;

  bool public paused = false;
  bool public revealed = false;

  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721A("MyNewContract", "MNC")  {
    setHiddenMetadataUri("ipfs://__CID__/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount, string memory _mintKey) {
    require(keccak256(bytes(_mintKey)) == keccak256(bytes(mintKey)), "Only whitelisted");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    _;
  }

  function setMintKey(string memory _mintKey) public onlyOwner {
    mintKey = _mintKey;
  }

  function mint(uint256 _mintAmount, string memory _mintKey) public payable mintCompliance(_mintAmount, _mintKey) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender] + _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver, string memory _mintKey) public mintCompliance(_mintAmount, _mintKey) onlyOwner {
    addressMintedBalance[_receiver] = addressMintedBalance[msg.sender] + _mintAmount;
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setNftPerAddressLimit(uint256 _nftPerAddressLimit) public onlyOwner {
    nftPerAddressLimit = _nftPerAddressLimit;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
