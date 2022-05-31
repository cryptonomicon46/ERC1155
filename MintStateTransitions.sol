//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; //Safemath no longer needed Sol v0.8.0 onwards
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MintStateTransitions is ERC1155{
    using Strings for string;
    using SafeMath for uint256;
    string _baseURI = "https://ipfs.io/ipfs/QmcDRWwXCE1LjvdESNZsmc75syTJP2zA8WW9SHEaCwEmkc/";
    string baseExtension = ".json";

    uint startedAt;
    uint DURATION = 7 days; //Mint only available for 7 days
    uint endAt;
    uint _royaltyFee = 5;

    //Track the NFT Info to check for reserves
    struct NFTInfo {
        uint id;
        uint price;
        uint reserves;
       }

    mapping (uint256=>  string) _tokenURI; //TokenId to tokenURI mapping


    NFTInfo[]  nftInfo;

    //Track Token Index to Id
    mapping(uint =>uint ) _idToidx;


    address  payable owner;




    enum MintStage {
        MintLive,
        MintEnded
    }

    MintStage mintStage;
        modifier mintTimedTransitions() {
        if (block.timestamp > endAt)
            nextMintStage();
            _;
    }


    modifier atMintStage(MintStage mintStage_) {
        if (mintStage != mintStage_) revert FunctionInvalidAtThisStage();
        _;

    }
   

    function nextMintStage() internal {
        mintStage = MintStage(uint(mintStage)+1);
    }
    uint maxMintAmount = 100;

 error InvalidAddress();
 error FunctionInvalidAtThisStage();
 error ErrorNFTReserves();
 event NFTReservesUpdated();

 
  //Example inputs 
 address devAddress; 
 //= 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
 address beneficiary;
 //= 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
 mapping (address => uint ) pendingWithdrawal;

    uint256[]  ids;
    //= [46,93];
    uint256[]  prices;
    //  = [1 ether, 0.5 ether];
    uint256[]  maxAmounts;
    //= [10,20];


 

//[46,93]
//["1000000000000000000","500000000000000000"]
// [10,20]
    constructor(
        uint[] memory tokenIds_,
        uint[] memory prices_,
        uint[] memory maxAmounts_,
        address beneficiary_,
        address devAddress_
        ) 
        ERC1155(_baseURI)
        payable
         {
     

            owner = payable(msg.sender);
            prices = prices_;
            tokenIds = tokenIds_;
            amounts  = amounts_;
            beneficiary = beneficary_;
            devAddress = devAddress_;
            require(ids.length == prices.length && ids.length == maxAmounts.length,"TokenIDs, TokenPrices and TokenAmounts should be of the same length");

               for(uint i =0; i< ids.length; i++) {
            _idToidx[ids[i]] = i;
            nftInfo.push(NFTInfo({
            id: ids[i],
            price: prices[i],
            reserves: maxAmounts[i]
                  }));
            _tokenURI[ids[i]] = string.concat(_baseURI,Strings.toString(ids[i]),baseExtension);
        }
                

         startedAt = block.timestamp;
        endAt = startedAt + DURATION;


    }


     function mintSingle(uint256 _id, uint256 _amount)  
         external   
         payable 
         mintTimedTransitions() 
         atMintStage(MintStage.MintLive){
       if (msg.sender == address(0)) revert InvalidAddress();
        require(_amount<= maxMintAmount && balanceOf(msg.sender,_id) <= maxMintAmount,"There's a limit to minting per address");
        // require(msg.sender != owner && msg.sender != beneficiary && msg.sender != devAddress,"Owner, beneficiary and devs cannot bid on this auction");
             
        uint256 _idx;
        _idx =  _idToidx[_id];
        uint256 price;
       uint256 royaltyFees;
       uint256 ownerPayment;
       uint256 nftReserves;

       price = nftInfo[_idx].price;
      nftReserves = nftInfo[_idx].reserves;
  
        require( nftReserves >= _amount,"ERC1155: Sorry, this NFT's sold out!");
        require(price.mul(_amount) <= msg.value,"ERC1155: You don't have enough funds.");

        //Update NFT Reserves
        _updateReserves(_idx,_amount);

       //Mint to the calling account address
        _mint(msg.sender,_id,_amount,""); //Will update the user balances and enumerations

        //Calculate and Pay Royalty Fee to owner/platform
         royaltyFees = (msg.value*_royaltyFee)/100;

        //Owner withdraws the balance funds
        ownerPayment = msg.value-royaltyFees;

        //Using the pendingWithdrawal method
        pendingWithdrawal[devAddress] = royaltyFees;
        pendingWithdrawal[beneficiary] = ownerPayment;

    } 

    function currentBlockTimeStamp ()
        public
        view 
        returns (uint) {
            return block.timestamp;
        }



    function getNFTInfo(uint tokenId_) 
        public 
        view 
        returns (NFTInfo memory) 
        {
            
            return nftInfo[_idToidx[tokenId_]];
        }



    function _updateReserves(uint256 _idx,uint256 amount) internal {
        if (nftInfo[_idx].reserves < amount) revert ErrorNFTReserves();
        nftInfo[_idx].reserves -= amount;
        emit NFTReservesUpdated();
    }

}

    
