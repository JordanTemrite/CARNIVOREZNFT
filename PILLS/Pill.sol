// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";

contract Pill is ERC721A, Ownable {
    using Address for address;

    IERC721 cz = IERC721(0x79182905C2F78787F2e194378979E9379e6A9EE7);

    address constant cz_deployer = payable(0xdFf3692F88123163f37c62f79eDE55Fccc58Ade5);

    uint256 constant max_supply = 5000;
    uint256 public min_purchase_price = .03 ether;
    uint256 public total_burned;

    bool internal burn_enabled = false;
    bool public mint_state = false;

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

    function burn_cz(uint256[] calldata _tokenID) payable external {

        require(mint_state, "CZ : MINTING IS NOT ENABLED");
        require(msg.value >= (min_purchase_price * _tokenID.length), "CZ : INSUFFCIENT VALUE SENT");
        require(payable(cz_deployer).send(msg.value), "CZ: ETHER MUST BE SENT TO THE DEPLOYER");
        require(totalSupply() + 1 <= max_supply, "CZ : ATTEMPTING TO MINT PAST MAX");

        for(uint k = 0; k < _tokenID.length; k++) {
            cz.transferFrom(msg.sender, 0x000000000000000000000000000000000000Cdad, _tokenID[k]);
        }

        total_burned += _tokenID.length;

        _safeMint(msg.sender, _tokenID.length);
    }

    function burn_pill(uint256[] calldata _tokenID) external {

        require(trusted[msg.sender] == true, "CZ : YOU ARE NOT TRUSTED BY CZ");

        require(burn_enabled, "CZ : PILL BURNING IS DISABLED");

        for(uint z = 0; z < _tokenID.length; z++) {
            _burn(_tokenID[z]);
        }
    }

}
