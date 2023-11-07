// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { UniswapV2Pair } from "../../contracts/Week3/UniswapV2Pair.sol";
import { UniswapV2Factory } from "../../contracts/Week3/UniswapV2Factory.sol";
import { ERC20Token } from "../../contracts/Week2/ERC20Token.sol";


contract UniswapV2PairTest is Test {
  address public owner = address(0x1);
  address public user = address(0x2);

  ERC20Token public tokenA;
  ERC20Token public tokenB;
  UniswapV2Factory public factory;
  UniswapV2Pair public pair;

  function setUp() external {
    vm.startPrank(owner);

    tokenA = new ERC20Token();
    tokenB = new ERC20Token();
    console2.log("tokenA address: %s", address(tokenA));
    console2.log("tokenB address: %s", address(tokenB));

    factory = new UniswapV2Factory(owner);
    pair = UniswapV2Pair(factory.createPair(address(tokenA), address(tokenB)));
    console2.log("factory address: %s", address(factory));
    console2.log("pair address: %s", address(pair));

    // deal
    deal(address(tokenA), owner, 100e18);
    deal(address(tokenB), owner, 100e18);
    deal(address(tokenA), user, 100e18);
    deal(address(tokenB), user, 100e18);

    // approve
    tokenA.approve(address(pair), 100e18);
    tokenB.approve(address(pair), 100e18);
    console2.log("pair bytecode:");
    console2.logBytes32(keccak256(type(UniswapV2Pair).creationCode));

    // seed lp
    pair.mint(
      address(tokenA),
      address(tokenB),
      100e18,
      50e18,
      0,
      0,
      address(owner),
      block.timestamp
    );
  }

  function testMint() external {
    vm.startPrank(user);

    tokenA.approve(address(pair), 100e18);
    tokenB.approve(address(pair), 100e18);

    // should be able to mint lp token
    pair.mint(
      address(tokenA),
      address(tokenB),
      10e18,
      5e18,
      0,
      0,
      address(user),
      block.timestamp
    );

    uint lpBalance = pair.balanceOf(user);
    assertTrue(lpBalance > 0, "lp balance should be greater than 0");
    console2.log("lp balance: %s", lpBalance);
  }

  function testBurn() external {
    vm.startPrank(user);

    tokenA.approve(address(pair), 100e18);
    tokenB.approve(address(pair), 100e18);

    // should be able to mint lp token
    pair.mint(
      address(tokenA),
      address(tokenB),
      10e18,
      5e18,
      0,
      0,
      address(user),
      block.timestamp
    );

    uint tokenAbalance = tokenA.balanceOf(user);
    uint tokenBbalance = tokenB.balanceOf(user);
    uint lpBalance = pair.balanceOf(user);
    assertTrue(lpBalance > 0, "lp balance should be greater than 0");
    console2.log("lp balance: %s", lpBalance);

    // should be able to burn lp token
    pair.burn(
      lpBalance,
      9.9e18,
      4.9e18,
      address(user),
      block.timestamp
    );

    lpBalance = pair.balanceOf(user);
    assertTrue(lpBalance == 0, "lp balance should be 0");
    console2.log("lp balance: %s", lpBalance);
    assertTrue(tokenA.balanceOf(user) > tokenAbalance, "tokenA balance should be greater than before");
    assertTrue(tokenB.balanceOf(user) > tokenBbalance, "tokenB balance should be greater than before");
  }

  function testSwapExact() external {
    vm.startPrank(user);

    tokenA.approve(address(pair), 100e18);
    tokenB.approve(address(pair), 100e18);

    // should be able to swap A for B
    address[] memory path = new address[](2);
    path[0] = address(tokenA);
    path[1] = address(tokenB);

    uint tokenAbalanceBefore = tokenA.balanceOf(user);
    uint tokenBbalanceBefore = tokenB.balanceOf(user);

    pair.swapExactTokensForTokens(
      10e18,
      0,
      path,
      address(user),
      block.timestamp
    );

    uint tokenAbalanceAfter = tokenA.balanceOf(user);
    uint tokenBbalanceAfter = tokenB.balanceOf(user);
    assertEq(tokenAbalanceAfter, (tokenAbalanceBefore - 10e18), "tokenA balance incorrect");
    assertTrue(tokenBbalanceAfter > tokenBbalanceBefore, "tokenB balance should be greater than before");
  }

  function testSwapForExact() external {
    vm.startPrank(user);

    tokenA.approve(address(pair), 100e18);
    tokenB.approve(address(pair), 100e18);

    // should be able to swap A for B
    address[] memory path = new address[](2);
    path[0] = address(tokenA);
    path[1] = address(tokenB);

    uint tokenAbalanceBefore = tokenA.balanceOf(user);
    uint tokenBbalanceBefore = tokenB.balanceOf(user);

    pair.swapTokensForExactTokens(
      10e18,
      26e18,
      path,
      address(user),
      block.timestamp
    );

    uint tokenAbalanceAfter = tokenA.balanceOf(user);
    uint tokenBbalanceAfter = tokenB.balanceOf(user);
    assertTrue(tokenAbalanceAfter < tokenAbalanceBefore, "tokenA balance should be less than before");
    assertEq(tokenBbalanceAfter, tokenBbalanceBefore + 10e18, "tokenB balance should be greater than before");
  }
}
