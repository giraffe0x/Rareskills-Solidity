// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20Token } from "./ERC20Token.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTStaking {
  ERC20Token public immutable erc20token;
  IERC721 public immutable erc721token;

  uint256 public constant CLAIM_AMOUNT_PER_DAY = 10;
  uint256 public constant DAY = 1 days;

  struct User {
    uint256 lastClaimedTimestamp;
    uint256 stakedTokenId;
  }

  mapping(address user => User userStruct) public users;

  constructor(address _erc20token, address _erc721token) {
    erc20token = ERC20Token(_erc20token);
    erc721token = IERC721(_erc721token);
  }

  function stake(uint256 tokenId) external {
    erc721token.safeTransferFrom(msg.sender, address(this), tokenId);
    users[msg.sender] = User(block.timestamp, tokenId);
  }

  function claim() external {
    // require that user has staked
    uint256 lastClaimed = users[msg.sender].lastClaimedTimestamp;
    require(lastClaimed != 0, "Not staked");

    // calculate time since last claim and accumulate rewards daily
    uint256 reward;

    while (lastClaimed < block.timestamp) {
      // cannot realistically overflow
      unchecked {
        // e.g. if lastClaimed was 36hrs(day 1.5), then next day is (36 + 24)/24 = 48hrs(day 2)
        uint256 nextDay = (lastClaimed + DAY) / DAY * DAY;

        // e.g. if block.timestamp is 60hrs (day 2.5)
        // loop 1: accrued time = 48 - 36 = 12hrs
        // loop 2: accrued time = 60 - 48 = 12hrs
        uint256 accruedTime = nextDay < block.timestamp
          ? nextDay - lastClaimed
          : block.timestamp - lastClaimed;

        reward += accruedTime * CLAIM_AMOUNT_PER_DAY / DAY;
        lastClaimed += accruedTime;
      }
    }

    // update last claimed timestamp
    users[msg.sender].lastClaimedTimestamp = block.timestamp;

    // mint reward
    erc20token.mint(msg.sender, reward);
  }

  function withdraw() external {
    User storage user = users[msg.sender];
    // require that user has staked
    require(user.lastClaimedTimestamp != 0, "Not staked");

    // reset user data
    delete users[msg.sender];

    // transfer NFT back to user
    erc721token.safeTransferFrom(
      address(this),
      msg.sender,
      user.stakedTokenId
    );
  }

  function onERC721Received(
    address /*_operator*/,
    address /*_from*/,
    uint256 /*_tokenId*/,
    bytes calldata /*_data*/
  ) external pure returns(bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }


  // TODO accept direct transfer
}
