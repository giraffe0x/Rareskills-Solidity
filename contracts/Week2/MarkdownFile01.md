-How does ERC721A save gas?
Ans: ERC721A makes efficiency gains by not setting explicit owners of specific tokenIDs when they are consecutive IDs minted by the same owner.


-Where does it add cost?
Ans: `transferFrom` and `safeTransferFrom` cost more gas as the contract has to loop across all tokenId until it reaches the NFT with an explicit owner address


-Why shouldn’t ERC721A enumerable’s implementation be used on-chain?
Enumeration functions are very gas intense. Unless the dapp really needs this functionality on chain, it is likely better to enumerate offchain instead.
