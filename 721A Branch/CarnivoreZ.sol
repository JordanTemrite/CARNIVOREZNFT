// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./AggregatorV3Interface.sol";

interface iMeat {
    function updateRewards(address _sender, address _reciever) external;
    function burnMeat(address _account, uint256 _number) external;
}

contract CarnivoreZ is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Address for address;

    iMeat public meat;
    AggregatorV3Interface internal ethPrice;
    AggregatorV3Interface internal apePrice;

    mapping(address => uint256) public primeMeatlist;
    mapping(address => uint256) public choiceMeatlist;
    mapping(address => uint256) public publicMintLimit;
    mapping(uint256 => Data) public carnivoreData;

    uint256 public mintPrice = .15 ether;
    uint256 public discountMintPrice = .1125 ether;
    uint256 public constant maxSupply = 10012;
    uint256 public teamMints;

    uint256 public _namePrice = 50 ether;
    uint256 public _descriptionPrice = 100 ether;
    uint256[] public _cardPrice = [50 ether, 100 ether, 150 ether, 200 ether, 250 ether];

    bool public meatlistSaleState = false;
    bool public publicSaleState = false;

    string private _baseURIextended;

    event nameChange(uint256 _cID, string _cName);
    event descriptionChange(uint256 _cID, string _cDesc);
    event cardChange(uint256 _cID, uint256 _cardID);
    event meatSet(address _meat);
    event salePriceChanged(uint256 _mintPrice, uint256 _billMintPrice);
    event cardPriceChanged(uint256[] _cardPrices);
    event primeListPopulated(uint256 _numberOfPrimes);
    event choiceListPopulated(uint256 _numberOfChoices);
    event publicSaleStateChanged(bool _saleState);
    event meatlistSaleStateChanged(bool _saleState);
    event baseURIChanged(string _baseURI);
    event namePriceChanged(uint256 _newPrice);
    event descriptionPriceChanged(uint256 _newPrice);

    struct Data {
        string name;
        string description;
        uint256 card;
    }
    
    address constant apeToken = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    
    address[] private _split = [
        0xCc43B7eE17Db1d698Dc0e5D0B7b54A18840D98aa, 
        0xF9Ba46D5D7a24Be56bA69c95c1011AE5B0d3c4a1, 
        0x6526c12DE85aeB53B23cFF4eaF55284199C3a703, 
        0x6856166A7A273b4a1C04D369c3123aE7Da7C36ed, 
        0x392e239cA5522EA5bD3d39cAC56402FCDeC51Ec7, 
        0x14672151CFE13665e855427B17A00f18Cc532769, 
        0x34f963c796E94aCeEc20326dCAd77D1573914964, 
        0x55a8556fcFBF953930218e70d9c97f9005d3eCB5 
    ];
    
    uint256[] private _percent = [
        45,
        16,
        14,
        10,
        7,
        6,
        1,
        1
    ];
    
    constructor() ERC721A("CarnivoreZ", "CZ") PaymentSplitter(_split, _percent) {
        ethPrice = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        apePrice = AggregatorV3Interface(0xD10aBbC76679a20055E167BB80A24ac851b37056);
    }
    
    fallback() external payable {

    }

    //Sets $MEAT contract address
    function setMeat(address _meat) external onlyOwner {
        meat = iMeat(_meat);

        emit meatSet(_meat);
    }

    //Sets sale price in WEI
    function setSalePrice(uint256 _mintPrice, uint256 _billMintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        discountMintPrice = _billMintPrice;

        emit salePriceChanged(_mintPrice, _billMintPrice);
    }

    //Sets card prices in WEI
    function setCardPrice(uint256[] memory _cardPrices) external onlyOwner {
        for(uint256 i = 0; i < _cardPrices.length; i++) {
            _cardPrice[i] = _cardPrices[i];
        }

        emit cardPriceChanged(_cardPrices);
    }

    //Sets name price in WEI
    function setNamePrice(uint256 _price) external onlyOwner {
        _namePrice = _price;

        emit namePriceChanged(_price);
    }

    //Sets description price in WEI
    function setDescriptionPrice(uint256 _price) external onlyOwner {
        _descriptionPrice = _price;

        emit descriptionPriceChanged(_price);
    }

    //Populates prime meatlist
    function populatePrimeList(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            primeMeatlist[_toBeWhitelisted[i]] += _numberOfMints;
        }

        emit primeListPopulated(_toBeWhitelisted.length);
    }

    //Populates choice meatlist
    function populateChoiceList(address[] memory _toBeWhitelisted, uint256 _numberOfMints) external onlyOwner {
        for(uint256 i = 0; i < _toBeWhitelisted.length; i++) {
            choiceMeatlist[_toBeWhitelisted[i]] += _numberOfMints;
        }

        emit choiceListPopulated(_toBeWhitelisted.length);
    }

    //Flips public sale state
    function setPublicSaleState() external onlyOwner {
        publicSaleState = !publicSaleState;

        emit publicSaleStateChanged(publicSaleState);
    }

    //Flips meatlist sale state
    function setMeatlistSaleState() external onlyOwner {
        meatlistSaleState = !meatlistSaleState;

        emit meatlistSaleStateChanged(meatlistSaleState);
    }

    //Mint function for primelist address's. Accepts $APE OR ETH
    function primeListMint(uint256 _mNum, bool _useApe) external payable {
        require(meatlistSaleState == true, "CZ: MEATLIST MINT IS INACTIVE");
        require(primeMeatlist[msg.sender] - _mNum >= 0,"CZ: ATTEMPTING TO MINT PAST ALLOTTED AMOUNT");
        require(totalSupply() + _mNum <= maxSupply, "CZ: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(0, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "CZ: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(payable(address(this)).send(msg.value), "CZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            primeMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            require(msg.sender == tx.origin, "CZ: MUST NOT BE CALLED BY A SMART CONTRACT");
            uint256 apeCost = getApeCost(ethAmount);

            bool success = IERC20(apeToken).transferFrom(msg.sender, address(this), apeCost);
            require(success, "CZ: TRANSFER FAILED");

            primeMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    //Mint function for choicelist address's. Accepts $APE OR ETH
    function choiceListMint(uint256 _mNum, bool _useApe) external payable {
        require(meatlistSaleState == true, "CZ: MEATLIST MINT IS INACTIVE");
        require(choiceMeatlist[msg.sender] - _mNum >= 0,"CZ: ATTEMPTING TO MINT PAST ALLOTTED AMOUNT");
        require(totalSupply() + _mNum <= maxSupply, "CZ: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(1, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "CZ: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(payable(address(this)).send(msg.value), "CZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            choiceMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            require(msg.sender == tx.origin, "CZ: MUST NOT BE CALLED BY A SMART CONTRACT");
            uint256 apeCost = getApeCost(ethAmount);

            bool success = IERC20(apeToken).transferFrom(msg.sender, address(this), apeCost);
            require(success, "CZ: TRANSFER FAILED");

            choiceMeatlist[msg.sender] -= _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    //Mint function for public mint. Accepts $APE OR ETH
    function publicMint(uint256 _mNum, bool _useApe) external payable {
        require(publicSaleState == true, "CZ: PUBLIC MINT IS INACTIVE");
        require(publicMintLimit[msg.sender] + _mNum <= 2, "CZ: ATTEMPTING TO MINT TOO MANY");
        require(totalSupply() + _mNum <= maxSupply, "CZ: ATTEMPTED TO MINT PAST MAX SUPPLY");
        uint256 ethAmount = calcEthAmount(2, _mNum);

        if(_useApe == false) {
            require(msg.value == ethAmount, "CZ: INSUFFCIENT OR TO MUCH ETHER SENT");
            require(payable(address(this)).send(msg.value), "CZ: ETHER MUST BE SENT TO THE CONTRACT VIA MINT FUNCTION");

            publicMintLimit[msg.sender] += _mNum;
            _safeMint(msg.sender, _mNum);
        }

        if(_useApe == true) {
            require(msg.sender == tx.origin, "CZ: MUST NOT BE CALLED BY A SMART CONTRACT");
            uint256 apeCost = getApeCost(ethAmount);

            bool success = IERC20(apeToken).transferFrom(msg.sender, address(this), apeCost);
            require(success, "CZ: TRANSFER FAILED");

            publicMintLimit[msg.sender] += _mNum;
            _safeMint(msg.sender, _mNum);
        }
    }

    //Mint function for the team. Limit 112 mints
    function teamMint(uint256 _mNum) external onlyOwner {
        require(totalSupply() + _mNum <= maxSupply, "CZ: ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(teamMints + _mNum <= 112, "CZ: THE TEAM MAY ONLY MINT 112");

        teamMints += _mNum;
        _safeMint(msg.sender, _mNum);
    }

    //Sets data struct name of NFT ID X
    function setName(uint256 _cID, string memory _cName) external {
        require(ownerOf(_cID) == msg.sender, "CZ: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cName);
        require(c.length > 0 && c.length < 20, "CZ: NAME MUST BE 1 TO 20 CHARACTERS");

        meat.burnMeat(msg.sender, _namePrice);
        carnivoreData[_cID].name = _cName;

        emit nameChange(_cID, _cName);
    }

    //Sets data struct description of NFT ID X
    function setDesc(uint256 _cID, string memory _cDesc) external {
        require(ownerOf(_cID) == msg.sender, "CZ: YOU DO NOT OWN THIS NFT");
        bytes memory c = bytes(_cDesc);
        require(c.length > 0 && c.length < 256, "CZ: DESCRIPTION MUST BE 1 TO 256 CHARACTERS");

        meat.burnMeat(msg.sender, _descriptionPrice);
        carnivoreData[_cID].description = _cDesc;

        emit descriptionChange(_cID, _cDesc);
    }

    //Sets data struct card for NFT ID X
    function setCard(uint256 _cID, uint256 _cardID) external {
        require(ownerOf(_cID) == msg.sender, "CZ: YOU DO NOT OWN THIS NFT");
        require(_cardPrice[_cardID] != 0, "CZ: INVALID CARD SELECTED");

        meat.burnMeat(msg.sender, _cardPrice[_cardID]);
        carnivoreData[_cID].card = _cardID;

        emit cardChange(_cID, _cardID);
    }

    //Withdraws ETH balance of the contract according to split defined above
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _split.length; i++) {
            address payable wallet = payable(_split[i]);
            release(wallet);
        }
    }

    //Sets baseURI for NFT metadata
    function setBaseURI(string memory baseURI_) external onlyOwner {
        bytes memory uri = bytes(baseURI_);
        require(uri.length > 0, "CZ: MUST NOT BE AN EMPTY STRING");
        _baseURIextended = baseURI_;

        emit baseURIChanged(baseURI_);
    }

    //Returns NFT's owned by wallet address
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
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

    //Calculates the required value to be sent on mint functions
    function calcEthAmount(uint256 _identifier, uint256 _mNum) public view returns(uint256) {
        if(_identifier == 0) {
            return(discountMintPrice * _mNum);
        }

        if(_identifier == 1) {
            if(_mNum < 3) {
                return(mintPrice * _mNum);
            }

            if(_mNum == 3) {
                return((mintPrice * 2) + discountMintPrice);
            }
        }

        if(_identifier == 2) {
            return(mintPrice * _mNum);
        }

        return 0;
    }

    //Returns the current price of ETH
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

    //Returns the current price of APE
    function getApePrice() public view returns(int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = apePrice.latestRoundData();
        return price;
    }

    //Returns the current price of $APE
    function getApeCost(uint256 ethAmount) public view returns(uint) {

        uint eP = uint(getEthPrice());

        uint tokenPrice = uint(getApePrice());

        uint aCost = (eP * ethAmount) / tokenPrice;

        return aCost;
    }

    //Override to update $MEAT rewards on NFT transfer
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A) {
        meat.updateRewards(from, to);
        ERC721A.transferFrom(from, to, tokenId);
    }
    
    //Override to update $MEAT rewards on NFT transfer
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721A) {
        meat.updateRewards(from, to);
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    //Returns the current baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
