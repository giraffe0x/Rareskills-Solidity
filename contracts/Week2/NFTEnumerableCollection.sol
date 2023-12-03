// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTEnumerableCollection is ERC721Enumerable {
  uint256 public constant MAX_SUPPLY = 20;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _mint(address(0x1), 0);
    _mint(address(0x2), 1);
    _mint(address(0x2), 2);
    _mint(address(0x3), 3);
    _mint(address(0x3), 4);
    _mint(address(0x3), 5);
    _mint(address(0x4), 6);
    _mint(address(0x4), 7);
    _mint(address(0x4), 8);
    _mint(address(0x4), 9);
    _mint(address(0x5), 10);
    _mint(address(0x5), 11);
    _mint(address(0x5), 12);
    _mint(address(0x5), 13);
    _mint(address(0x5), 14);
    _mint(address(0x6), 15);
    _mint(address(0x6), 16);
    _mint(address(0x6), 17);
    _mint(address(0x6), 18);
    _mint(address(0x6), 19);
    _mint(address(0x6), 20);
    _mint(address(0x7), 21);
    _mint(address(0x7), 22);
    _mint(address(0x7), 23);
    _mint(address(0x7), 24);
    _mint(address(0x7), 25);
    _mint(address(0x7), 26);
    _mint(address(0x7), 27);
    _mint(address(0x8), 28);
    _mint(address(0x8), 29);
    _mint(address(0x8), 30);
    _mint(address(0x8), 31);
  }
}
