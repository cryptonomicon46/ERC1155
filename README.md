# ERC1155 using Timed Transitions, reentrancy guard and withdrawal from my previous medium article  

This is a simple implementataion of the ERC1155 NFT contract by open zeppelin. 
The goal is to be able to set a contract expiration time. 
And allow users to mint before the contract expires. 
We'll ensure that the user has enough funds to mint a certain amount of an NFT token. 
We'll also ensure they're only able to mint before the contract expires. 

The proceeds of the sale will go to a designated beneficiary, developer and any refunds will go back to the user. 

The token URIs are based on the IPFS link created by me. But this can be modified for your use cases. 
Just make sure to change the '_baseURI' input to the ERC1155 constructor. 


