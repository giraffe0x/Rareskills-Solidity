// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test } from "forge-std/Test.sol";

import { UntrustedEscrow } from "../../contracts/Week1/UntrustedEscrow.sol";
import { MockERC20 } from "../../contracts/mocks/MockERC20.sol";

contract UntrustedEscrowTest is Test {
    address public buyer;
    address public seller;

    UntrustedEscrow public escrow;
    MockERC20 public token;

    function setUp() external {
        buyer = makeAddr("buyer");
        seller = makeAddr("seller");

        token = new MockERC20();
        escrow = new UntrustedEscrow(address(buyer), address(seller), address(token));

        deal(address(token), buyer, 1000);
    }

    function test_deposit() external {
        assertEq(token.balanceOf(address(escrow)), 0);

        vm.startPrank(buyer);
        token.approve(address(escrow), 1000);
        escrow.deposit(1000);

        assertEq(token.balanceOf(address(escrow)), 1000);
    }

    function test_withdraw() external {
        vm.startPrank(buyer);
        token.approve(address(escrow), 1000);
        escrow.deposit(1000);

        vm.expectRevert("Only seller can call this method");
        escrow.withdraw();

        vm.startPrank(seller);
        vm.expectRevert("Timelock not expired");
        escrow.withdraw();

        skip(3 days);
        escrow.withdraw();

        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(address(seller)), 1000);
    }

    function test_cancel() external {
        vm.startPrank(buyer);
        token.approve(address(escrow), 1000);
        escrow.deposit(1000);

        escrow.cancel();
        assertEq(token.balanceOf(address(escrow)), 0);
        assertEq(token.balanceOf(address(buyer)), 1000);

        vm.startPrank(seller);
        vm.expectRevert("Only buyer can call this method");
        escrow.cancel();
    }
}
