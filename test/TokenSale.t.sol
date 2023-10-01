// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { TokenSale } from "../contracts/Week1/TokenSale.sol";
import { MockERC1363 } from "../contracts/mocks/MockERC1363.sol";

contract TokenSaleTest is Test {
  address public buyer1;
  address public buyer2;

  TokenSale public tokenSale;
  MockERC1363 public token;

  function setUp() external {
    buyer1 = makeAddr("buyer1");
    buyer2 = makeAddr("buyer2");

    token = new MockERC1363();

    uint256 reserveRatio = 0.5e6; // linear
    tokenSale = new TokenSale(reserveRatio, address(token));

    token.mint(buyer1, 100e18);
    token.mint(buyer2, 100e18);
  }

  function test_mint() external {
    assertEq(token.balanceOf(address(tokenSale)), 0);

    vm.startPrank(buyer1);
    token.approve(address(tokenSale), 1000e18);

    uint256 depositAmt = 1e18;
    uint256 n = tokenSale.calculateMintAmount(depositAmt);
    tokenSale.mint(depositAmt);

    assertEq(token.balanceOf(address(tokenSale)), depositAmt);
    assertEq(tokenSale.balanceOf(buyer1), n);
  }

  function test_linearIncrease() external {
    vm.startPrank(buyer1);
    token.approve(address(tokenSale), 1000e18);

    uint256 depositAmt = 1e18;
    uint256 t0 = tokenSale.calculateMintAmount(depositAmt);
    tokenSale.mint(depositAmt);

    uint256 t1 = tokenSale.calculateMintAmount(depositAmt);
    tokenSale.mint(depositAmt);

    uint256 t2 = tokenSale.calculateMintAmount(depositAmt);
    tokenSale.mint(depositAmt);

    assert(t0 > t1);
    assert(t1 > t2);

    assert(t0 - t1 > t1 - t2);
  }

  function test_burn() external {
    vm.startPrank(buyer1);
    token.approve(address(tokenSale), 1000e18);

    uint256 depositAmt = 5e18;
    tokenSale.mint(depositAmt);
    uint256 totalSupplyBefore = tokenSale.totalSupply();

    uint256 withdrawAmt = tokenSale.balanceOf(buyer1) / 5;
    uint256 n = tokenSale.calculateBurnAmount(withdrawAmt);
    tokenSale.burn(withdrawAmt);

    assertEq(token.balanceOf(address(tokenSale)), depositAmt - n);
    assertEq(tokenSale.totalSupply(), totalSupplyBefore - withdrawAmt);
  }

  function test_linearDecrease() external {
    vm.startPrank(buyer1);
    token.approve(address(tokenSale), 1000e18);

    uint256 buyer1InitBalance = token.balanceOf(buyer1);
    uint256 depositAmtBuyer1 = 5e18;
    tokenSale.mint(depositAmtBuyer1);

    vm.startPrank(buyer2);
    token.approve(address(tokenSale), 1000e18);

    uint256 depositAmtBuyer2 = 5e18;
    tokenSale.mint(depositAmtBuyer2);

    vm.startPrank(buyer1);
    uint256 withdrawAmtBuyer1 = tokenSale.balanceOf(buyer1);
    tokenSale.burn(withdrawAmtBuyer1);

    assertGt(token.balanceOf(buyer1), buyer1InitBalance);
  }

  function test_ERC1363Deposit() external {
    vm.startPrank(buyer1);

    uint256 depositAmt = 1e18;
    uint256 n = tokenSale.calculateMintAmount(depositAmt);
    token.transferAndCall(address(tokenSale), depositAmt, "");

    assertEq(token.balanceOf(address(tokenSale)), depositAmt);
    assertEq(tokenSale.balanceOf(buyer1), n);
  }
}
