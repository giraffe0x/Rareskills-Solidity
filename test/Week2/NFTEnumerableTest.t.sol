// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { NFTEnumerableCollection } from "../../contracts/Week2/NFTEnumerableCollection.sol";
import { NFTSearchForPrime } from "../../contracts/Week2/NFTSearchForPrime.sol";

contract NFTEnumerableTest is Test {
  address public owner = address(0x99);
  address public buyer1 = address(0x1);
  address public buyer2 = address(0x2);

  NFTEnumerableCollection public erc721Token;
  NFTSearchForPrime public nftSearcher;

  function setUp() external {
    vm.startPrank(owner);

    erc721Token = new NFTEnumerableCollection("NFTEnumerableCollection", "NFT");
    nftSearcher = new NFTSearchForPrime(address(erc721Token));
  }

  function test_searchForPrime() external {
    // address 0x1 holds id 0
    assertEq(nftSearcher.searchForPrime(address(0x1)), 0);
    // address 0x2 holds id 1,2
    assertEq(nftSearcher.searchForPrime(address(0x2)), 1);
    // address 0x3 holds id 3,4,5
    assertEq(nftSearcher.searchForPrime(address(0x3)), 2);
    // address 0x4 holds id 6,7,8,9
    assertEq(nftSearcher.searchForPrime(address(0x4)), 1);
    // address 0x5 holds id 10,11,12,13,14
    assertEq(nftSearcher.searchForPrime(address(0x5)), 2);
    // address 0x6 holds id 15,16,17,18,19,20
    assertEq(nftSearcher.searchForPrime(address(0x6)), 2);
    // address 0x7 holds id 21,22,23,24,25,26,27
    assertEq(nftSearcher.searchForPrime(address(0x7)), 1);
    // addresss 0x8 holds 27,28,29,30,31
    assertEq(nftSearcher.searchForPrime(address(0x8)), 2);
  }

  function test_searchForPrimeOptimized() external {
    // address 0x1 holds id 0
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x1)), 0);
    // address 0x2 holds id 1,2
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x2)), 1);
    // address 0x3 holds id 3,4,5
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x3)), 2);
    // address 0x4 holds id 6,7,8,9
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x4)), 1);
    // address 0x5 holds id 10,11,12,13,14
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x5)), 2);
    // address 0x6 holds id 15,16,17,18,19,20
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x6)), 2);
    // address 0x7 holds id 21,22,23,24,25,26,27
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x7)), 1);
    // addresss 0x8 holds 49
    assertEq(nftSearcher.searchForPrimeOptimized(address(0x8)), 2);
  }
}
