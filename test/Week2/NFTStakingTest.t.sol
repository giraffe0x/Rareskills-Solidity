// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { ERC20Token } from "../../contracts/Week2/ERC20Token.sol";
import { NFTStaking } from "../../contracts/Week2/NFTStaking.sol";
import { NFTWithMerkleDiscount } from "../../contracts/Week2/NFTWithMerkleDiscount.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// forge test --mc NFTSTakingTest --gas-report
contract NFTSTakingTest is Test {
  address public owner = address(0x99);
  address public buyer1 = address(0x1);
  address public buyer2 = address(0x2);

  ERC20Token public erc20Token;
  NFTWithMerkleDiscount public erc721Token;
  NFTStaking public nftStaker;

  bytes32 public root = 0x897d6714686d83f84e94501e5d6f0f38c94b75381b88d1de3878b4f3d2d5014a;

  function setUp() external {
    vm.startPrank(owner);

    erc20Token = new ERC20Token();
    erc721Token = new NFTWithMerkleDiscount(owner, 250, root);
    nftStaker = new NFTStaking(address(erc20Token), address(erc721Token));
    erc20Token.approveMinter(address(nftStaker));
  }

  function test_whitelistMint() external {
    vm.startPrank(buyer2);
    deal(buyer2, 1 ether);

    bytes32[] memory proof = new bytes32[](3);
    proof[0] = 0x5fa3dab1e0e1070445c119c6fd10edd16d6aa2f25a5899217f919c041d474318;
    proof[1] = 0x1fdf5401990e2cac67ac4a5f20ffb1f408ec0fb41734d0679ef9196ee9aaf536;
    proof[2] = 0xbf1aed239f5ffae94793f862021c8e65c82a6e0eb8e7165d559ad60e9a1ccada;

    // should revert with invalid proof
    vm.expectRevert("Invalid merkle proof");
    erc721Token.whitelistMint{value: 0.05 ether}(proof, 2);

    // should revert with insufficient ether sent
    vm.expectRevert("Insufficient ether sent");
    erc721Token.whitelistMint{value: 0.01 ether}(proof, 1);

    // success case
    erc721Token.whitelistMint{value: 0.05 ether}(proof, 1);
    // buyer balance should be 1
    assertEq(erc721Token.balanceOf(buyer2), 1);
    // owner of tokenId 1 should be buyer2
    assertEq(erc721Token.ownerOf(1), buyer2);

    // should revert if try to claim again
    vm.expectRevert("Already claimed");
    erc721Token.whitelistMint{value: 0.05 ether}(proof, 1);
  }

  function test_withdrawFunds() external {
    vm.startPrank(buyer2);
    deal(buyer2, 1 ether);

    bytes32[] memory proof = new bytes32[](3);
    proof[0] = 0x5fa3dab1e0e1070445c119c6fd10edd16d6aa2f25a5899217f919c041d474318;
    proof[1] = 0x1fdf5401990e2cac67ac4a5f20ffb1f408ec0fb41734d0679ef9196ee9aaf536;
    proof[2] = 0xbf1aed239f5ffae94793f862021c8e65c82a6e0eb8e7165d559ad60e9a1ccada;

    erc721Token.whitelistMint{value: 1 ether}(proof, 1);

    vm.startPrank(owner);
    erc721Token.withdraw();
    assertEq(owner.balance, 1 ether);
  }

  function test_stakeAndClaim() external {
    _whitelistMint();
    assertEq(erc721Token.balanceOf(buyer2), 1);
    assertEq(erc721Token.ownerOf(1), buyer2);

    // should revert if not staked
    vm.expectRevert("Not staked");
    nftStaker.claim();

    erc721Token.approve(address(nftStaker), 1);
    nftStaker.stake(1);
    // staking contract should own the token
    assertEq(erc721Token.balanceOf(address(nftStaker)), 1);
    assertEq(erc721Token.ownerOf(1), address(nftStaker));

    // buyer2 should have staked
    (uint256 lastClaimedTimestamp, uint256 stakedTokenId) = nftStaker.users(buyer2);

    assertEq(stakedTokenId, 1);
    assertEq(lastClaimedTimestamp, block.timestamp);

    // claim after 1.5 days
    skip(1.5 days);

    nftStaker.claim();
    assertEq(erc20Token.balanceOf(buyer2), 15);
  }

  function test_withdrawStake() external {
    _whitelistMint();
    erc721Token.approve(address(nftStaker), 1);
    nftStaker.stake(1);

    // claim after 1.5 days
    skip(1.5 days);

    nftStaker.claim();
    assertEq(erc20Token.balanceOf(buyer2), 15);
    assertEq(erc721Token.ownerOf(1), address(nftStaker));

    (uint256 lastTS, uint256 stakedTokenId) = nftStaker.users(buyer2);

    vm.startPrank(buyer2);
    nftStaker.withdraw();
    assertEq(erc721Token.ownerOf(1), address(buyer2));
  }

  // function test_fuzzClaim(uint256 _days) external {
  //   _whitelistMint();
  //   erc721Token.approve(address(nftStaker), 1);
  //   nftStaker.stake(1);

  //   skip(_days * 1 days);
  //   nftStaker.claim();
  //   uint256 balance = erc20Token.balanceOf(buyer2);
  //   assertEq(balance, _days * 10);

    // // claim again
    // skip(_days * 1 days);
    // nftStaker.claim();
    // assertEq(erc20Token.balanceOf(buyer2), balance + _days * 10);
  // }

  function _whitelistMint() internal {
    vm.startPrank(buyer2);
    deal(buyer2, 1 ether);

    bytes32[] memory proof = new bytes32[](3);
    proof[0] = 0x5fa3dab1e0e1070445c119c6fd10edd16d6aa2f25a5899217f919c041d474318;
    proof[1] = 0x1fdf5401990e2cac67ac4a5f20ffb1f408ec0fb41734d0679ef9196ee9aaf536;
    proof[2] = 0xbf1aed239f5ffae94793f862021c8e65c82a6e0eb8e7165d559ad60e9a1ccada;

    erc721Token.whitelistMint{value: 0.05 ether}(proof, 1);
  }

}
