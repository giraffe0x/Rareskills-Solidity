// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import { console } from "forge-std/console.sol";

contract NFTWithMerkleDiscount is ERC721Royalty, Ownable2Step {
  BitMaps.BitMap private claimedBitMap;

  uint256 public constant MAX_SUPPLY = 20;
  uint256 public constant PUBLIC_SALEPRICE = 0.1 ether;
  uint256 public constant WHITELIST_SALEPRICE = 0.05 ether;

  uint256 public tokensMinted;
  bytes32 public merkleRoot;

  // TODO add events

  constructor(address _receiver, uint96 _feeNumerator, bytes32 _merkleRoot) ERC721("SmartContractTrio", "SCT") {
    _setDefaultRoyalty(_receiver, _feeNumerator);
    merkleRoot = _merkleRoot;

    _mint(msg.sender, 0);
    tokensMinted = 1;
  }

  function publicMint() external payable {
    uint256 _tokenId = tokensMinted;
    require(_tokenId < MAX_SUPPLY, "Max supply reached");
    require(msg.value >= PUBLIC_SALEPRICE, "Insufficient ether sent");

    _mint(msg.sender, _tokenId);

    unchecked {
      tokensMinted++;
    }
  }

  function whitelistMint(bytes32[] calldata merkleProof, uint256 index) external payable {
    // check if already claimed
    require(!BitMaps.get(claimedBitMap, index), "Already claimed");

    // verify merkle proof
    require(_verify(merkleProof, index), "Invalid merkle proof");

    // update claimed bitmap
    BitMaps.setTo(claimedBitMap, index, true);

    // then do mint checks
    uint256 _tokenId = tokensMinted;
    require(_tokenId < MAX_SUPPLY, "Max supply reached");
    require(msg.value >= WHITELIST_SALEPRICE, "Insufficient ether sent");

    _mint(msg.sender, _tokenId);

    unchecked {
      tokensMinted++;
    }
  }

  function _verify(bytes32[] calldata merkleProof, uint256 index) internal view returns (bool) {
    bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, index))));
    return MerkleProof.verify(merkleProof, merkleRoot, node);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
