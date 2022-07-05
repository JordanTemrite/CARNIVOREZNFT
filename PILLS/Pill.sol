// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./PaymentSplitter.sol";

contract Pill is ERC721A, Ownable, PaymentSplitter {
    using Address for address;

    IERC721 cz = IERC721(0x79182905C2F78787F2e194378979E9379e6A9EE7);

    uint256 constant max_supply = 4000;
    uint256 public min_purchase_price = .04 ether;

    bool internal burn_enabled = false;
    bool public mint_state = false;
    
    string private _baseURIextended;

    mapping(address => bool) public trusted;
    mapping(address => bool) public no_charge;

    address[] private _split = [
        0xF9Ba46D5D7a24Be56bA69c95c1011AE5B0d3c4a1,
        0x6526c12DE85aeB53B23cFF4eaF55284199C3a703,
        0x6856166A7A273b4a1C04D369c3123aE7Da7C36ed, 
        0xCc43B7eE17Db1d698Dc0e5D0B7b54A18840D98aa, 
        0x392e239cA5522EA5bD3d39cAC56402FCDeC51Ec7, 
        0x55a8556fcFBF953930218e70d9c97f9005d3eCB5 
    ];
    
    uint256[] private _percent = [
        26,
        26,
        20,
        14,
        11,
        3
    ];

    event mint_and_burn(uint256[] _ids);
    event pill_burned(uint256[] _ids);
    event burn_swap(bool _state);
    event mint_swap(bool _state);
    event add_trusted(address _trusted, bool _state);
    event add_no_charge(address _no_charge, bool _state);
    event baseURIChanged(string _baseURI);


    constructor() ERC721A("Pill-1", "P1") PaymentSplitter(_split, _percent) {

    }

    fallback() external payable {

    }

    function swap_burn_state() external onlyOwner {

        burn_enabled = !burn_enabled;

        emit burn_swap(burn_enabled);
    }

    function swap_mint_state() external onlyOwner {

        mint_state = !mint_state;

        emit mint_swap(mint_state);
    }

    function set_trusted(address _trusted, bool _state) external onlyOwner {

        trusted[_trusted] = _state;

        emit add_trusted(_trusted, _state);
    }

    function set_no_charge(address _to_add, bool _state) external onlyOwner {

        no_charge[_to_add] = _state;

        emit add_no_charge(_to_add, _state);
    }

    function burn_cz(uint256[] calldata _tokenID) payable external {

        require(mint_state, "CZ : MINTING IS NOT ENABLED");
        require(totalSupply() + 1 <= max_supply, "CZ : ATTEMPTING TO MINT PAST MAX");

        if(no_charge[msg.sender] == false) {
            require(msg.value >= (min_purchase_price * _tokenID.length), "CZ : INSUFFCIENT VALUE SENT");
            require(payable(address(this)).send(msg.value), "CZ: ETHER MUST BE SENT TO THE CONTRACT");
        }

        for(uint c = 0; c < _tokenID.length; c++) {
            cz.transferFrom(msg.sender, 0x000000000000000000000000000000000000Cdad, _tokenID[c]);
        }

        _safeMint(msg.sender, _tokenID.length);

        emit mint_and_burn(_tokenID);
    }

    function burn_pill(uint256[] calldata _tokenID) external {

        require(trusted[msg.sender] == true, "CZ : NOT APPROVED");

        require(burn_enabled, "CZ : PILL BURNING IS DISABLED");

        for(uint z = 0; z < _tokenID.length; z++) {
            _burn(_tokenID[z]);
        }

        emit pill_burned(_tokenID);
    }

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

    //Returns the current baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
