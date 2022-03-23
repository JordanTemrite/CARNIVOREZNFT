// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Ownable.sol";
import "./Address.sol";

contract MeatlistClaim is Ownable {
    using Address for address;

    uint256 public maxClaims = 120;
    uint256 public totalClaims;

    struct claimData {
        address claimer;
        uint256 mintsAlloted;
    }

    mapping(address => bool) public claimStatus;
    mapping(uint256 => claimData) public cData;

    event listClaimed(address _claimer, uint256 _numOfMints);

    constructor() {

    }

    function claimMeatlist() external {
        require(claimStatus[msg.sender] == false, "MEATLIST: ALREADY CLAIMED");
        require((totalClaims + 1) <= maxClaims, "MEATLIST: MAX CLAIM LIMIT REACHED");

        claimStatus[msg.sender] = true;
        cData[(totalClaims + 1)].claimer = address(msg.sender);
        cData[(totalClaims + 1)].mintsAlloted = 4;
        totalClaims += 1;

        emit listClaimed(address(msg.sender), 4);
    }
}
