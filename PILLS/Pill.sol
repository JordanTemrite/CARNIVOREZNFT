// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";

contract Pill is ERC721A, Ownable {
    using Address for address;

    IERC721 cz = IERC721(0x48926596Eac835dd906c1694FE620f75fB2F588b);
    address constant cz_deployer = payable(0xdFf3692F88123163f37c62f79eDE55Fccc58Ade5);

    uint256 constant max_supply = 5000;
    uint256 public min_purchase_price = .03 ether;
    uint256 public total_burned;

    bool internal burn_enabled = true;
    bool public mint_state = false;

    mapping(address => uint256) public available_mints;
    mapping(address => bool) public trusted;

    constructor() ERC721A("TEST", "TST") {
    }

    fallback() external payable {

    }

    function swap_burn_state() external onlyOwner {

        burn_enabled = !burn_enabled;
    }

    function swap_mint_state() external onlyOwner {

        mint_state = !mint_state;
    }

    function set_trusted(address _trusted, bool _state) external onlyOwner {
        trusted[_trusted] = _state;
    }

    function test_transfer(uint256 _tokenID) external {
        cz.transferFrom(msg.sender, address(this), _tokenID);
    }

    function burn_cz(uint256 _tokenID) payable external {

        require(cz.ownerOf(_tokenID) == msg.sender, "CZ : YOU DO NOT OWN THIS NFT");

        require(mint_state, "CZ : MINTING IS NOT ENABLED");
        require(msg.value >= min_purchase_price, "CZ : INSUFFCIENT VALUE SENT");
        require(payable(cz_deployer).send(msg.value), "CZ: ETHER MUST BE SENT TO THE DEPLOYER VIA MINT FUNCTION");
        require(totalSupply() + 1 <= max_supply, "CZ : ATTEMPTING TO MINT PAST MAX");

        cz.transferFrom(msg.sender, address(this), _tokenID);

        total_burned += 1;

        _safeMint(msg.sender, 1);
    }

    function burn_pill(uint256[] calldata _tokenID) external {

        for(uint i = 0; i < _tokenID.length; i ++) {
            require(ownerOf(_tokenID[i]) == msg.sender || trusted[msg.sender] == true, "CZ : YOU DO NOT OWN THIS PILL");
        }

        require(burn_enabled, "CZ : PILL BURNING IS DISABLED");

        for(uint z = 0; z < _tokenID.length; z++) {
            _burn(_tokenID[z]);
        }
    }

}
