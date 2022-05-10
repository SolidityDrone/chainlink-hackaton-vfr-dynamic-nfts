// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTGame {
       function getTrophies(uint256) external returns (uint256);
}

contract Staking is ReentrancyGuard {
    IERC20 public parentToken;
    IERC721 public parentNFT;
    INFTGame public parentNftFunctions;
    address public parentNFTAddress;
    constructor(address _nftContract, address _tokenContract){
        parentNFT = IERC721(_nftContract);
        parentNftFunctions = INFTGame(_nftContract);
        parentToken = IERC20(_tokenContract);
        parentNFTAddress = _nftContract;

    }
    modifier onlyMain{
        require(msg.sender == parentNFTAddress, "Not allowed");
        _;
    }
    mapping (uint256 => StakeReview) s_stakeReview; 
 
    struct StakeReview{
        address realOwner;
        uint256 claimedTrophies;
        uint256 lastClaimTime; 
    }
    function refreshTrophies(uint256 _tokenID) public {
       s_stakeReview[_tokenID].claimedTrophies = parentNftFunctions.getTrophies(_tokenID);
       
    }
    function claimedTrophies(uint256 _tokenID) public view returns (uint256){
        return s_stakeReview[_tokenID].claimedTrophies;
    }
    function stake(uint256 _tokenID) public nonReentrant() {
        require(parentNFT.ownerOf(_tokenID) == msg.sender, "Not owner");
        
        parentNFT.transferFrom(msg.sender, address(this), _tokenID);
        s_stakeReview[_tokenID].realOwner = msg.sender;
        s_stakeReview[_tokenID].lastClaimTime = block.timestamp;
    }
    
    function claim(uint256 _tokenID) public nonReentrant {
        require(s_stakeReview[_tokenID].lastClaimTime > 0 );
        require(s_stakeReview[_tokenID].realOwner == msg.sender);

        s_stakeReview[_tokenID].claimedTrophies = parentNftFunctions.getTrophies(_tokenID);
        uint256 currentTrophies = parentNftFunctions.getTrophies(_tokenID);
        uint256 amount = ((block.timestamp - s_stakeReview[_tokenID].lastClaimTime) + (currentTrophies - s_stakeReview[_tokenID].claimedTrophies) );
        if (parentToken.transfer(msg.sender, amount)){
            s_stakeReview[_tokenID].lastClaimTime = block.timestamp;
            s_stakeReview[_tokenID].claimedTrophies += (currentTrophies - s_stakeReview[_tokenID].claimedTrophies);
        } else revert("Transfer fail");
    }
    function unstake(uint256 _tokenID) public {
        require(parentNFT.ownerOf(_tokenID) == address(this), "Not staked");
        require(s_stakeReview[_tokenID].realOwner == msg.sender, "Not realOwner");
        uint256 amount = ((block.timestamp - s_stakeReview[_tokenID].lastClaimTime) + (parentNftFunctions.getTrophies(_tokenID) - s_stakeReview[_tokenID].claimedTrophies) );
         uint256 currentTrophies = parentNftFunctions.getTrophies(_tokenID);
        if (parentToken.transfer(msg.sender, amount)){
            s_stakeReview[_tokenID].lastClaimTime = block.timestamp;
             s_stakeReview[_tokenID].claimedTrophies += (currentTrophies - s_stakeReview[_tokenID].claimedTrophies);
        }
        parentNFT.transferFrom(address(this), msg.sender, _tokenID);
        s_stakeReview[_tokenID].realOwner = address(0);
    }
    
   
    
    
 
function onERC721Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,uint256,bytes)"));
    }

   
 

    

}