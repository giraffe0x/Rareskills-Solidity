Revisit the solidity events tutorial. How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable? Explain how you would accomplish this if you were creating an NFT marketplace

- Use or build an indexer that scans the blockchain for events
- Events involving transfer to/from the user's address would be relevant
- Bloom filter approach makes this approach fast
- Stores results in database
