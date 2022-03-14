// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";

interface iMeat {
    function updateRewards(address _sender, address _reciever) external;
    function burnMeat(address _account, uint256 _number) external;
}

contract CARNIVOREZ is ERC721Enumerable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
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
    uint256 public maxSupply = 24;
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
    
    Counters.Counter private _tokenCounter;
    
    address payable thisContract;
    
    address[] private _team = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        ];
    
    uint256[] private _teamShares = [
        100
        ];
    
    constructor() ERC721("CARNIVOREZ NFT", "CARNIVOREZ") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

    }

    function viewThisContract() external view returns(address) {
        return thisContract;
    }

    function setMeat(address _meat) external onlyOwner {
        meat = iMeat(_meat);
    }

    function setApprovedAddress(address _approved, bool _state) external onlyOwner {
        approvedAddress[_approved] = _state;
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
            zbWL[_toBeWhitelisted[i]] = zbWL[_toBeWhitelisted[i]].add(_numberOfMints);
        }
    }

    function populateMillionWL(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            zmWL[_toBeWhitelisted[i]] = zmWL[_toBeWhitelisted[i]].add(_numberOfMints);
        }
    }

    function populateRegularWL(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            rWL[_toBeWhitelisted[i]] = rWL[_toBeWhitelisted[i]].add(_numberOfMints);
        }
    }

    function setSaleState(bool _rSale, bool _wlSale) external onlyOwner {
        if(rSaleState != _rSale) {
            rSaleState = _rSale;
        }
        
        if(wlSaleState != _wlSale) {
            wlSaleState = _wlSale;
        }
    }

    function mintCARNIVOREZ(uint256 _mNum) external payable {
        require(wlSaleState == true || rSaleState == true, "CARNIVOREZ: MINT IS INACTIVE");

        if(wlSaleState == true) {
            if(zbWL[msg.sender] > 0) {
                require(zbWL[msg.sender].sub(_mNum) >= 0,"CARNIVOREZ: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
                require(msg.value == bMintPrice.mul(_mNum), "CARNIVOREZ: INSUFFCIENT OR TO MUCH ETHER SENT");
                require(thisContract.send(msg.value), "CARNIVOREZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
                require(_tokenCounter.current().add(_mNum) <= maxSupply, "CARNIVOREZ: ATTEMPTED TO MINT PAST MAX SUPPLY");

                for(uint256 i = 0; i < _mNum; i++) {
                    zbWL[msg.sender] = zbWL[msg.sender].sub(1);
                    _safeMint(msg.sender, _tokenCounter.current().add(1));
                    _tokenCounter.increment();
                }

            } else
            if(zmWL[msg.sender] > 0) {
                require(zmWL[msg.sender].sub(_mNum) >= 0,"CARNIVOREZ: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
                require(msg.value == mintPrice.mul(_mNum), "CARNIVOREZ: INSUFFCIENT OR TO MUCH ETHER SENT");
                require(thisContract.send(msg.value), "CARNIVOREZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
                require(_tokenCounter.current().add(_mNum) <= maxSupply, "CARNIVOREZ: ATTEMPTED TO MINT PAST MAX SUPPLY");

                for(uint256 i = 0; i < _mNum; i++) {
                    zmWL[msg.sender] = zmWL[msg.sender].sub(1);
                    _safeMint(msg.sender, _tokenCounter.current().add(1));
                    _tokenCounter.increment();
                }

            } else
            if(rWL[msg.sender] > 0) {
                require(rWL[msg.sender].sub(_mNum) >= 0,"CARNIVOREZ: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
                require(msg.value == mintPrice.mul(_mNum), "CARNIVOREZ: INSUFFCIENT OR TO MUCH ETHER SENT");
                require(thisContract.send(msg.value), "CARNIVOREZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
                require(_tokenCounter.current().add(_mNum) <= maxSupply, "CARNIVOREZ: ATTEMPTED TO MINT PAST MAX SUPPLY");

                for(uint256 i = 0; i < _mNum; i++) {
                    rWL[msg.sender] = rWL[msg.sender].sub(1);
                    _safeMint(msg.sender, _tokenCounter.current().add(1));
                    _tokenCounter.increment();
                }

            } else {
                require(1 == 2, "CARNIVOREZ: YOU ARE NOT WHITELISTED OR HAVE USED YOUR WHITELIST MINTS");
            }
        } else
        if(rSaleState == true) {
            require(pMintLimit[msg.sender].add(_mNum) <= 2, "CARNIVOREZ: ATTEMPTING TO MINT TOO MANY");
            require(msg.value == mintPrice.mul(_mNum), "CARNIVOREZ: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(thisContract.send(msg.value), "CARNIVOREZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");
            require(_tokenCounter.current().add(_mNum) <= maxSupply, "CARNIVOREZ: ATTEMPTED TO MINT PAST MAX SUPPLY");

            for(uint256 i = 0; i < _mNum; i++) {
                pMintLimit[msg.sender] = pMintLimit[msg.sender].add(1);
                _safeMint(msg.sender, _tokenCounter.current().add(1));
                _tokenCounter.increment();
            }
        }
    }

    function teamMint(uint256 _mNum) external onlyOwner {
        require(_tokenCounter.current().add(_mNum) <= maxSupply, "CARNIVOREZ: ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(tMints.add(_mNum) <= 20, "CARNIVOREZ: THE TEAM MAY ONLY MINT 20");

        for(uint256 i = 0; i < _mNum; i++) {
            tMints = tMints.add(1);
            _safeMint(msg.sender, _tokenCounter.current().add(1));
            _tokenCounter.increment();
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setName(uint256 _cID, string memory _cName) external {
        require(ownerOf(_cID) == msg.sender, "CARNIVOREZ: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cName);
        require(c.length > 0 && c.length < 20, "CARNIVOREZ: NAME MUST BE 1 TO 20 CHARACTERS");

        meat.burnMeat(msg.sender, _namePrice);
        cData[_cID].name = _cName;
        emit nChange(_cID, _cName);
    }

    function setDesc(uint256 _cID, string memory _cDesc) external {
        require(ownerOf(_cID) == msg.sender, "CARNIVOREZ: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cDesc);
        require(c.length > 0 && c.length < 256, "CARNIVOREZ: DESCRIPTION MUST BE 1 TO 256 CHARACTERS");

        meat.burnMeat(msg.sender, _descPrice);
        cData[_cID].description = _cDesc;
        emit dChange(_cID, _cDesc);
    }

    function setCard(uint256 _cID, uint256 _cardID) external {
        require(ownerOf(_cID) == msg.sender, "CARNIVOREZ: YOU DO NOT OWN THIS NFT");
        require(_cardPrice[_cardID] != 0, "CARNIVOREZ: INVALID CARD SELECTED");

        meat.burnMeat(msg.sender, _cardPrice[_cardID]);
        cData[_cID].card = _cardID;
        emit cChange(_cID, _cardID);
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
    function setThisContract(address payable _contract) external onlyOwner {
        thisContract = _contract;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        meat.updateRewards(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721, IERC721) {
        meat.updateRewards(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
