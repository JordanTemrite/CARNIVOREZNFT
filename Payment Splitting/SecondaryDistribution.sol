// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract SecondaryDistro is PaymentSplitter, Ownable {
    address[] private _team = [
    0x7482885D3708509F65C050C906d608F31A36B9D4,
    0x82C3ACBb6cF6b04f52aDad9Bd4f3D26BC5Db5b36
    ];
    
    uint256[] private _teamShares = [
        10,
        90
    ];

    constructor() PaymentSplitter(_team, _teamShares) {

    }

    fallback() external payable {

    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
}
