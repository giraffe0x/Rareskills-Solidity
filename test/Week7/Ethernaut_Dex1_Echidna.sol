// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { Dex } from "../../contracts/Week7/Ethernaut_Dex1.sol";
import { SwappableToken } from "../../contracts/Week7/Ethernaut_Dex1.sol";



contract TestDex {
  Dex dex;
  SwappableToken token1;
  SwappableToken token2;


  constructor() {
    dex = new Dex();
    token1 = new SwappableToken(address(dex), "Token1", "TK1", 110);
    token2 = new SwappableToken(address(dex), "Token2", "TK2", 110);

    dex.setTokens(address(token1), address(token2));
    SwappableToken(token1).approve(address(dex), 100);
    SwappableToken(token2).approve(address(dex), 100);

    dex.addLiquidity(address(token1), 100);
    dex.addLiquidity(address(token2), 100);

    dex.transferOwnership(address(0));
  }

  function echidna_test_balance() public view returns (bool) {
    uint256 x = SwappableToken(token1).balanceOf(address(dex));
    uint256 y = SwappableToken(token2).balanceOf(address(dex));

    return (x * y >= 10_000);
  }

}
