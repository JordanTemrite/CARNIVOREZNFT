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

    mapping(address => uint256) private pendingMeat;
    mapping(address => uint256) private lastClaim;
    mapping(address => bool) private trustedAddress;

    bool public rewardsEnabled;

    uint256 public rewardStart;
    uint256 public constant rewardRate = 5 ether;

    address public carnivorezMintContract;

    event rewardClaimed(address _claimer, uint256 _dueBal);
    event rewardsUpdated(address _sender, address _receiver, uint256 _sendBal, uint256 _receieveBal);
    event rewardsInitialized(uint256 _rewardStart);
    event minterSet(address _minter);
    event rewardStateChanged(bool _rewardState);
    event trustedAddressChanged(address _trusted, bool _trustState);

    constructor(address _carnivorez) ERC20("Meat", "MEAT") {
        carnivorezMintContract = _carnivorez;

    }

    function initializeRewards() external onlyOwner {
        require(rewardStart == 0, "MEAT: REWARDS ALREADY INITIALIZED");
        rewardStart = block.timestamp;

        emit rewardsInitialized(rewardStart);
    }

    function setMinter(address _carnivorez) external onlyOwner {
        carnivorezMintContract = _carnivorez;

        emit minterSet(_carnivorez);
    }

    function setRewardState() external onlyOwner {
        rewardsEnabled = !rewardsEnabled;

        emit rewardStateChanged(rewardsEnabled);
    }

    function setTrusted(address _tTrust, bool _tState) external onlyOwner {
        trustedAddress[_tTrust] = _tState;

        emit trustedAddressChanged(_tTrust, _tState);
    }

    function updateRewards(address _cSend, address _cReceive) external {
        require(msg.sender == carnivorezMintContract, "MEAT: MAY ONLY BE CALLED BY PARENT CONTRACT");

        uint256 _tSend = pendingEligible(_cSend);
        uint256 _tReceive = pendingEligible(_cReceive);

        lastClaim[_cSend] = block.timestamp;
        lastClaim[_cReceive] = block.timestamp;

        pendingMeat[_cSend] = pendingMeat[_cSend] + _tSend;
        pendingMeat[_cReceive] =  pendingMeat[_cReceive] + _tReceive;

        emit rewardsUpdated(_cSend, _cReceive, _tSend, _tReceive);
    }

    function claimMeat() external {
        require(rewardsEnabled == true, "MEAT: REWARDS ARE PAUSED");

        uint256 _dueBal = claimDue(msg.sender); 
        pendingMeat[msg.sender] = 0;
        lastClaim[msg.sender] = block.timestamp;

        _mint(msg.sender, _dueBal);
        emit rewardClaimed(msg.sender, _dueBal);
    }

    function burnMeat(address _burner, uint256 _amount) external {
        require(msg.sender == address(carnivorezMintContract) || trustedAddress[msg.sender] == true, "MEAT: NOT AUTHORIZED TO BURN");

        _burn(_burner, _amount);
    }

    function pendingEligible(address _cOwner) public view returns(uint256) {
        uint256 rPeriod;

        if(rewardStart == 0) {
            return 0;
        } else
        if(lastClaim[_cOwner] > rewardStart) {
            rPeriod = lastClaim[_cOwner];
        } else
        if(lastClaim[_cOwner] < rewardStart) {
            rPeriod = rewardStart;
        }

        return numberHeld(_cOwner).mul(rewardRate).mul((block.timestamp - rPeriod)).div(86400);
    }

    function numberHeld(address _cOwner) public view returns(uint256) {
        return IERC721(carnivorezMintContract).balanceOf(_cOwner);
    }

    function claimDue(address _cOwner) public view returns(uint256) {
        return pendingMeat[_cOwner].add(pendingEligible(_cOwner));
    }

}
