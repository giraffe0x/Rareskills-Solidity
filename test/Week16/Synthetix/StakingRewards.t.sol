// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import {StakingRewards} from "./../../../contracts/Week16/Synthetix/StakingRewards.sol";
import { ERC20Token } from "./../../../contracts/Week2/ERC20Token.sol";


contract StakingRewardsTest is Test {
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public eve = address(0x3);
    address public rewardsDistribution = address(0x4);

    StakingRewards stakingRewards;
    ERC20Token rewardToken;
    ERC20Token stakingToken;

    function setUp() external {
        rewardToken = new ERC20Token();
        stakingToken = new ERC20Token();

        rewardToken.approveMinter(address(this));
        stakingToken.approveMinter(address(this));

        stakingRewards = new StakingRewards(
            eve,
            rewardsDistribution,
            address(rewardToken),
            address(stakingToken)
        );

        stakingToken.mint(alice, 100e18);
        stakingToken.mint(bob, 100e18);
        stakingToken.mint(eve, 100e18);
        rewardToken.mint(address(stakingRewards), 1000e18);

        vm.prank(eve);
        stakingRewards.setRewardsDuration(7 days);

        vm.prank(rewardsDistribution);
        stakingRewards.notifyRewardAmount(1000);
    }

    // gas 115_907
    function testStake() public {
        vm.startPrank(alice);
        stakingToken.approve(address(stakingRewards), 100e18);
        stakingRewards.stake(100e18);

        assertEq(stakingRewards.balanceOf(alice), 100e18);
    }

    // gas 194_383
    function testWithdraw() public {
        vm.startPrank(alice);
        stakingToken.approve(address(stakingRewards), 100e18);
        stakingRewards.stake(100e18);

        stakingRewards.withdraw(50e18);

        assertEq(stakingRewards.balanceOf(alice), 50e18);
    }

    // gas 203_828
    function testGetReward() public {
        vm.startPrank(alice);
        stakingToken.approve(address(stakingRewards), 100e18);
        stakingRewards.stake(100e18);

        skip(2 days);

        stakingRewards.getReward();
        assertTrue(rewardToken.balanceOf(alice) > 0);
    }

    // gas 212_140
    function testStakeAndExit() public {
      vm.startPrank(alice);
      stakingToken.approve(address(stakingRewards), 100e18);
      stakingRewards.stake(100e18);
      assertEq(stakingRewards.balanceOf(alice), 100e18);

      skip(2 days);

      stakingRewards.exit();
      assertEq(stakingToken.balanceOf(alice), 100e18);
      assertTrue(rewardToken.balanceOf(alice) > 0);
      assertEq(stakingRewards.balanceOf(alice), 0);
    }
}
