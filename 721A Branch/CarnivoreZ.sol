// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./IUniswapV2Pair.sol";
import "./AggregatorV3Interface.sol";

interface iMeat {
    function updateRewards(address _sender, address _reciever) external;
    function burnMeat(address _account, uint256 _number) external;
}

contract TEST is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Address for address;

    iMeat public meat;
    AggregatorV3Interface internal ethPrice;
    
    mapping(uint256 => string) private _tokenURIs;

    mapping(address => uint256) public primeMeatlist;
    mapping(address => uint256) public choiceMeatlist;
    mapping(address => uint256) public pMintLimit;
    mapping(address => bool) public approvedAddress;
    mapping(uint256 => Data) public cData;

    uint256 public mintPrice = .15 ether;
    uint256 public bMintPrice = .1125 ether;
    uint256 public maxSupply = 10012;
    uint256 public tMints;

    uint256 public _namePrice = 100 ether;
    uint256 public _descPrice = 100 ether;
    uint256[] public _cardPrice;

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
    address pair = 0x4Ab6e651ECf894766E3ffBA610346F0e54543Cc5;
    address apeToken = 0x127554D4A22eb61127a859447bF7728fF72879Ae;
    
    address[] private _split = [
        0x82C3ACBb6cF6b04f52aDad9Bd4f3D26BC5Db5b36
    ];
    
    uint256[] private _percent = [
        100
    ];
    
    constructor() ERC721A("TESTNFT", "TEST") PaymentSplitter(_split, _percent) {
        ethPrice = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
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

    function populatePrimeList(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            primeMeatlist[_toBeWhitelisted[i]] += _numberOfMints;
        }
    }

    function populateChoiceList(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            choiceMeatlist[_toBeWhitelisted[i]] += _numberOfMints;
        }
    }

    function setPubSaleState() external onlyOwner {
        rSaleState = !rSaleState;
    }

    function setWlSaleState() external onlyOwner {
        wlSaleState = !wlSaleState;
    }

    function primeListMint(uint256 _mNum, bool _useApe) external payable {
        require(wlSaleState == true, "TEST: MEATLIST MINT IS INACTIVE");
        require(primeMeatlist[msg.sender] - _mNum >= 0,"TEST: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(0, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            primeMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            uint256 tAmount = viewApeCost(ethAmount);
            require(IERC20(apeToken).transferFrom(msg.sender, address(this), tAmount));

            primeMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    function choiceListMint(uint256 _mNum, bool _useApe) external payable {
        require(wlSaleState == true, "TEST: MEATLIST MINT IS INACTIVE");
        require(choiceMeatlist[msg.sender] - _mNum >= 0,"TEST: ATTEMPTING TO MINT PAST ALLOTED AMOUNT");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(1, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            choiceMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            uint256 tAmount = viewApeCost(ethAmount);
            require(IERC20(apeToken).transferFrom(msg.sender, address(this), tAmount));

            choiceMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    function publicMint(uint256 _mNum, bool _useApe) external payable {
        require(rSaleState == true, "TEST: PUBLIC MINT IS INACTIVE");
        require(pMintLimit[msg.sender] + _mNum <= 2, "TEST: ATTEMPTING TO MINT TOO MANY");
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(2, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "TEST: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(thisContract.send(msg.value), "TEST: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            pMintLimit[msg.sender] += _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            uint256 tAmount = viewApeCost(ethAmount);
            require(IERC20(apeToken).transferFrom(msg.sender, address(this), tAmount));

            pMintLimit[msg.sender] += _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    function teamMint(uint256 _mNum) external onlyOwner {
        require(totalSupply() + _mNum <= maxSupply, "TEST: ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(tMints + _mNum <= 112, "TEST: THE TEAM MAY ONLY MINT 112");

        tMints += _mNum;
        _safeMint(msg.sender, _mNum);
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

    function calcEthAmount(uint256 _identifier, uint256 _mNum) public view returns(uint256) {
        if(_identifier == 0) {
            return(bMintPrice * _mNum);
        }

        if(_identifier == 1) {
            if(_mNum < 3) {
                return(mintPrice * _mNum);
            }

            if(_mNum == 3) {
                return((mintPrice * 2) + bMintPrice);
            }
        }

        if(_identifier == 2) {
            return(mintPrice * _mNum);
        }

        return 0;
    }

    function getEthPrice() public view returns(int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethPrice.latestRoundData();
        return price;
    }

    function getApePrice() public view returns(uint) {

        IUniswapV2Pair v2Pair = IUniswapV2Pair(pair);

        (uint Res0, uint Res1,) = v2Pair.getReserves();

        uint eP = uint(getEthPrice());

        uint tokenPrice = (Res1 * eP) / Res0;

        return tokenPrice;
    }

    function viewApeCost(uint256 ethAmount) public view returns(uint256) {
        uint256 ePrice = uint(getEthPrice());
        uint256 aPrice = getApePrice();
        uint256 aCost = (ePrice * ethAmount) / aPrice;

        return aCost;
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
