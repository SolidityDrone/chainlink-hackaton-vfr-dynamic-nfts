//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
    
    import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
    import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';
    import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol';
    import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; // VFR2 HAS NO POLY INFORMATIONS AVAILABLE 
    import "../contracts/SVGLib.sol";
    
contract NFTGame is ERC721, VRFConsumerBase {
    using SafeMath for uint256;
    using Strings for uint256;
    event statsFilled(uint256 tokenID, uint256 seed);
    uint256 public _totalSupply;
    uint256 MAX_SUPPLY;
    uint256 mintPrice;
    uint256 seamTotalSupply = 1;
    string private _baseURIextended;
    address public withdrawAddress;
    mapping (uint256=>uint256) s_RandomSeed;
    mapping (uint256 => string) private s_TokenUri;
    mapping (uint256=>Stats) s_Stats;
   
    struct Stats{
        string Race;
        uint256 Attack;
    }
    //https://blog.chain.link/how-to-get-a-random-number-on-polygon/ 
    
    constructor()
        ERC721("ERC", "ERC")
        VRFConsumerBase(
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        ) 
    {
    keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    fee = 100000000000000; 
    _totalSupply = 0;
    MAX_SUPPLY = 555;
    s_trophies[1] = 555555;
    mintPrice = 1 wei; 
    }
    bytes32 internal keyHash;
    uint256 internal fee;

function CharacterStats(uint256 charID) public view returns (string memory Race, uint256 Attack ){
    return ( s_Stats[charID].Race,  s_Stats[charID].Attack);
}  


mapping(uint256 => uint256) s_trophies;
function getTrophies(uint256 _tokenID) external view returns (uint256 trophies) {
    return s_trophies[_tokenID];
}



mapping (bytes32 => uint8) s_RequestType;

function getRandomNumber() internal returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
}
function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint256 _randomnessType = s_RequestType[requestId];
    if (_randomnessType == 0){
        fulfillMint(randomness);

    } else if (_randomnessType == 1){
       // random for arena mechanics
    }
}
/* 
// Example function for how different random requests are handled
function arena() public {
    s_RequestType[getRandomNumber()] = 1;
}
*/

function _mint() external payable
    {
        require(msg.value == mintPrice, "Need to send 0.08 ether"); 
        require(_totalSupply < MAX_SUPPLY, "Supply cap was met, unable to procede with mint");
        _safeMint(msg.sender, _totalSupply +1);
        _totalSupply += 1;
        getRandomNumber(); 
    }

function fulfillMint(uint256 randomness) internal
    {
        s_RandomSeed[seamTotalSupply] =  (randomness % 4194303) + 1; 
        uint256[] memory expandedValues;
        expandedValues = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) 
        { 
            expandedValues[i] = uint256(keccak256(abi.encode((randomness % 4194303) +1, i)));
            expandedValues[i] %=6 ; 
            expandedValues[i] +=5 ; 
        }
        string[3] memory raceId = 
        [
        "Race1", 
        "Race2",
        "Race3"
        ];
        uint256 raceUint;
        raceUint = expandedValues[0];
        s_Stats[seamTotalSupply].Attack = expandedValues[1];
        s_Stats[seamTotalSupply].Race = raceId[raceUint.sub(1)];
        seamTotalSupply +=1;
    }
   

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "My721Token #', tokenId.toString(), ',"',
                '"image": "data:image/svg+xml;base64,', Base64.encode(SVGLib.assembleString(s_Stats[tokenId].Race)),'"',
              
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }
    
  
}

   