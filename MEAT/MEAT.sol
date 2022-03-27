// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract MEAT is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private pMeat;
    mapping(address => uint256) private lClaim;
    mapping(address => bool) private tAddr;

    bool public rEnabled;

    uint256 public rStart;
    uint256 public rRate = 5 ether;

    address public cMint;

    event rewardClaimed(address _claimer, uint256 _dueBal);
    event rewardsUpdated(address _sender, address _receiver, uint256 _sendBal, uint256 _receieveBal);

    constructor(address _carnivorez) ERC20("TEST", "TEST") {
        cMint = _carnivorez;

    }

    ///////REMOVE BEFORE DEPLOYMENT!!!!!!!!/////
    function megaMint() external onlyOwner {
        _mint(msg.sender, 1000000000000000000000);
    }

    function initializeRewards() external onlyOwner {
        require(rStart == 0, "MEAT: REWARDS ALREADY INITIALIZED");
        rStart = block.timestamp;
    }

    function setMinter(address _carnivorez) external onlyOwner {
        cMint = _carnivorez;
    }

    function rewardState() external onlyOwner {
        rEnabled = !rEnabled;
    }

    function setTrusted(address _tTrust, bool _tState) external onlyOwner {
        tAddr[_tTrust] = _tState;
    }

    function updateRewards(address _cSend, address _cReceive) external {
        require(msg.sender == cMint, "MEAT: MAY ONLY BE CALLED BY PARENT CONTRACT");

        uint256 _tSend = pendingEligible(_cSend);
        uint256 _tReceive = pendingEligible(_cReceive);

        lClaim[_cSend] = block.timestamp;
        lClaim[_cReceive] = block.timestamp;

        pMeat[_cSend] = pMeat[_cSend] + _tSend;
        pMeat[_cReceive] =  pMeat[_cReceive] + _tReceive;

        emit rewardsUpdated(_cSend, _cReceive, _tSend, _tReceive);
    }

    function claimMeat() external {
        require(rEnabled == true, "MEAT: REWARDS ARE PAUSED");

        uint256 _dueBal = claimDue(msg.sender); 
        pMeat[msg.sender] = 0;
        lClaim[msg.sender] = block.timestamp;

        _mint(msg.sender, _dueBal);
        emit rewardClaimed(msg.sender, _dueBal);
    }

    function burnMeat(address _burner, uint256 _amount) external {
        require(msg.sender == address(cMint) || tAddr[msg.sender] == true, "MEAT: NOT AUTHORIZED TO BURN");

        _burn(_burner, _amount);
    }

    function pendingEligible(address _cOwner) public view returns(uint256) {
        uint256 rPeriod;

        if(rStart == 0) {
            return 0;
        } else
        if(lClaim[_cOwner] > rStart) {
            rPeriod = lClaim[_cOwner];
        } else
        if(lClaim[_cOwner] < rStart) {
            rPeriod = rStart;
        }

        return numberHeld(_cOwner).mul(rRate).mul((block.timestamp - rPeriod)).div(60);
    }

    function numberHeld(address _cOwner) public view returns(uint256) {
        return IERC721(cMint).balanceOf(_cOwner);
    }

    function claimDue(address _cOwner) public view returns(uint256) {
        return pMeat[_cOwner].add(pendingEligible(_cOwner));
    }

}
