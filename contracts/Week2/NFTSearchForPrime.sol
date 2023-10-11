// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract NFTSearchForPrime {
  IERC721Enumerable public immutable nft;

  constructor(address _nft) {
    nft = IERC721Enumerable(_nft);
  }

  function searchForPrime(address user) external view returns (uint256 res) {
    // get which token ids the user owns
    uint256 balance = nft.balanceOf(user);
    uint256[] memory tokenIds = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      tokenIds[i] = nft.tokenOfOwnerByIndex(user, i);
    }

    // for each token id, check if it is prime
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (_isPrime(tokenIds[i])) res++;
    }
  }

  function searchForPrimeOptimized(address user) external view returns (uint256 res) {
    // get which token ids the user owns
    uint256 balance = nft.balanceOf(user);
    uint256[] memory tokenIds = new uint256[](balance);
    unchecked {
      for (uint256 i = 0; i < balance; i++) {
      tokenIds[i] = nft.tokenOfOwnerByIndex(user, i);
    }

    // for each token id, check if it is prime
      for (uint256 i = 0; i < tokenIds.length; i++) {
        if (_isPrime(tokenIds[i])) res++;
      }
    }
  }

  function _isPrime(uint256 n) internal pure returns (bool) {
    // 0 and 1 are not prime
    if (n < 2) return false;
    // 2 and 3 are prime
    if (n < 4) return true;

    unchecked {
      // if divisible by 2 or 3 then not prime
      if (n % 2 == 0 || n % 3 == 0) return false;

      // Check divisibility for numbers of the form 6k ± 1, where k is an integer
      for (uint256 i = 5; i * i <= n;) {
        if (n % i == 0 || n % (i + 2) == 0) return false;
        i += 6;
      }
    }

    return true;
  }

  // function _isPrimeOptimized(uint256 n) internal pure returns (uint256) {
  //   // 0 and 1 are not prime
  //   if (n < 2) return 0;
  //   // 2 and 3 are prime
  //   if (n < 4) return 1;

  //   // if divisible by 2 or 3 then not prime
  // unchecked {
  //     if (n % 2 == 0 || n % 3 == 0) return 0;
  //   }

  //   // Check divisibility for numbers of the form 6k ± 1, where k is an integer
  //   // e.g. 49 % 6+1 == 0
  //   for (uint256 i = 5; i * i <= n;) {
  //     if (n % i == 0 || n % (i + 2) == 0) return 0;
  //     unchecked {
  //       i += 6;
  //     }
  //   }

  //   return 1;
  // }
}
