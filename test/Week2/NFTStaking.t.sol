// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { ERC20Token } from "../../contracts/Week2/ERC20Token.sol";
import { NFTStaking } from "../../contracts/Week2/NFTStaking.sol";
import { NFTWithMerkleDiscount } from "../../contracts/Week2/NFTWithMerkleDiscount.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSTaking is Test {
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

    erc721Token.whitelistMint{value: 1 ether}(proof, 1);
    assertEq(erc721Token.balanceOf(buyer2), 1);
    assertEq(erc721Token.ownerOf(1), buyer2);
  }

  function test_withdraw() external {
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

}
