// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";

interface iMeat {
    function updateRewards(address _sender, address _reciever) external;
    function burnMeat(address _account, uint256 _number) external;
}

contract TEST is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Address for address;

    iMeat public meat;
    
    mapping(uint256 => string) private _tokenURIs;

    mapping(address => uint256) public zbWL;
    mapping(address => uint256) public zmWL;
    mapping(address => uint256) public rWL;
    mapping(address => uint256) public pMintLimit;
    mapping(address => bool) public approvedAddress;
    mapping(uint256 => Data) public cData;

    uint256 public mintPrice = .3 ether;
    uint256 public bMintPrice = .225 ether;
    uint256 public maxSupply = 10000;
    uint256 public tMints = 0;

    uint256 public _namePrice = 100 ether;
    uint256 public _descPrice = 100 ether;
    uint256[] public _cardPrice = [100 ether, 150 ether, 200 ether];

    bool public wlSaleState = false;
    bool public rSaleState = false;

    string private _baseURIextended;

    event nChange(uint256 _cID, string _cName);
    event dChange(uint256 _cID, string _cDesc);
    event cChange(uint256 _cID, uint256 _cardID);

    struct Data {
        string name;
        string description;
        uint256 card;
    }
    
    address payable thisContract;
    
    address[] private _split = [
        0x79a3e8E917D02Ee638E9De592330F1D9058Fd794
        ];
    
    uint256[] private _percent = [
        100
        ];
    
    constructor() ERC721A("TESTNFT", "TEST") PaymentSplitter(_split, _percent) {
    }
    
    fallback() external payable {

    }

    function viewThisContract() external view returns(address) {
        return thisContract;
    }

    function setMeat(address _meat) external onlyOwner {
        meat = iMeat(_meat);
    }

    function setApprovedAddress(address _approved) external onlyOwner {
        approvedAddress[_approved] = !approvedAddress[_approved];
    }

    function setSalePrice(uint256 _mintPrice, uint256 _billMintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        bMintPrice = _billMintPrice;
    }

    function setCardPrice(uint256[] memory _cardPrices) external onlyOwner {
        for(uint256 i = 0; i < _cardPrices.length; i++) {
            _cardPrice[i] = _cardPrices[i];
        }
    }

    function populateBillionWL(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            zbWL[_toBeWhitelisted[i]] += _numberOfMints;
        }
    }

    function populateMillionWL(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            zmWL[_toBeWhitelisted[i]] += _numberOfMints;
        }
    }

    function populateRegularWL(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            rWL[_toBeWhitelisted[i]] += _numberOfMints;
        }
    }

    function setSaleState(bool _rSale, bool _wlSale) external onlyOwner {
        rSaleState = _rSale;
        wlSaleState = _wlSale;
    }

    function billionWhitelistMint(uint256 _mNum) external payable {
        require(wlSaleState == true, "TEST: MINT IS INACTIVE");
        require(zbWL[msg.sender] - _mNum >= 0,"TEST: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
        require(msg.value == bMintPrice * _mNum, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
        require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");

        zbWL[msg.sender] -= _mNum;
        _safeMint(msg.sender, _mNum);
    }

    function millionWhitelistMint(uint256 _mNum) external payable {
        require(wlSaleState == true, "TEST: MINT IS INACTIVE");
        require(zmWL[msg.sender] - _mNum >= 0,"TEST: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
        require(msg.value == mintPrice * _mNum, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
        require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        
        zmWL[msg.sender] -= _mNum;
        _safeMint(msg.sender, _mNum);     
    }

    function whitelistMint(uint256 _mNum) external payable {
        require(wlSaleState == true, "TEST: MINT IS INACTIVE");
        require(rWL[msg.sender] - _mNum >= 0,"TEST: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
        require(msg.value == mintPrice * _mNum, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
        require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");

        rWL[msg.sender] -= _mNum;
        _safeMint(msg.sender, _mNum);
    }

    function publicMint(uint256 _mNum) external payable {
        require(rSaleState == true, "TEST: MINT IS INACTIVE");
        require(pMintLimit[msg.sender] + _mNum <= 2, "TEST: ATTEMPTING TO MINT TOO MANY");
        require(msg.value == mintPrice * _mNum, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
        require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");

        pMintLimit[msg.sender] += _mNum;
        _safeMint(msg.sender, _mNum);
    }

    function teamMint(uint256 _mNum) external onlyOwner {
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(tMints + _mNum <= 20, "TEST: THE TEAM MAY ONLY MINT 20");

        tMints += _mNum;
        _safeMint(msg.sender, _mNum);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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

    function setName(uint256 _cID, string memory _cName) external {
        require(ownerOf(_cID) == msg.sender, "TEST: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cName);
        require(c.length > 0 && c.length < 20, "TEST: NAME MUST BE 1 TO 20 CHARACTERS");

        meat.burnMeat(msg.sender, _namePrice);
        cData[_cID].name = _cName;
        emit nChange(_cID, _cName);
    }

    function setDesc(uint256 _cID, string memory _cDesc) external {
        require(ownerOf(_cID) == msg.sender, "TEST: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cDesc);
        require(c.length > 0 && c.length < 256, "TEST: DESCRIPTION MUST BE 1 TO 256 CHARACTERS");

        meat.burnMeat(msg.sender, _descPrice);
        cData[_cID].description = _cDesc;
        emit dChange(_cID, _cDesc);
    }

    function setCard(uint256 _cID, uint256 _cardID) external {
        require(ownerOf(_cID) == msg.sender, "TEST: YOU DO NOT OWN THIS NFT");
        require(_cardPrice[_cardID] != 0, "TEST: INVALID CARD SELECTED");

        meat.burnMeat(msg.sender, _cardPrice[_cardID]);
        cData[_cID].card = _cardID;
        emit cChange(_cID, _cardID);
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _split.length; i++) {
            address payable wallet = payable(_split[i]);
            release(wallet);
        }
    }
    
    function setThisContract(address payable _contract) external onlyOwner {
        thisContract = _contract;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A) {
        meat.updateRewards(from, to);
        ERC721A.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721A) {
        meat.updateRewards(from, to);
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
