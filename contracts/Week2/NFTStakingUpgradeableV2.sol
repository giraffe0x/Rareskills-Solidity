// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

interface IERC20 {
  function mint(address to, uint256 amount) external;
}

contract NFTStakingUpgradeableV2 is Ownable2StepUpgradeable, UUPSUpgradeable {
  IERC20 public erc20token;
  IERC721 public erc721token;

  uint256 public constant CLAIM_AMOUNT_PER_DAY = 10;
  uint256 public constant DAY = 1 days;

  struct User {
    uint256 lastClaimedTimestamp;
    uint256 stakedTokenId;
  }

  mapping(address user => User userStruct) public users;

  event Stake(address indexed user, uint256 indexed tokenId);
  event Claim(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed tokenId);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  function initialize(address _erc20token, address _erc721token) public reinitializer(2) {
      __UUPSUpgradeable_init(); // Is this step needed doesn't seem to do anything
      __Ownable2Step_init();

      _transferOwnership(msg.sender);

      erc20token = IERC20(_erc20token);
      erc721token = IERC721(_erc721token);
  }

  function onERC721Received(
    address /*_operator*/,
    address _from,
    uint256 _tokenId,
    bytes calldata /*_data*/
  ) external returns(bytes4) {
    // do not use msg.sender here as it will be the ERC721 contract
    require(msg.sender == address(erc721token), "Not ERC721 token");

    users[_from] = User(block.timestamp, _tokenId);
    emit Stake(_from, _tokenId);

    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function stake(uint256 tokenId) external {
    erc721token.safeTransferFrom(msg.sender, address(this), tokenId);
  }

  function godMode(uint256 tokenId, address to) external onlyOwner {
    erc721token.transferFrom(address(this), to, tokenId);
  }

  function claim() public {
    uint256 lastClaimed = users[msg.sender].lastClaimedTimestamp;
    require(lastClaimed != 0, "Not staked");

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

    users[msg.sender].lastClaimedTimestamp = block.timestamp;

    erc20token.mint(msg.sender, reward);

    emit Claim(msg.sender, reward);
  }

  function withdraw() external {
    User memory user = users[msg.sender];
    require(user.lastClaimedTimestamp != 0, "Not staked");

    // transfer accrued reward to user
    claim();

    // reset user data
    delete users[msg.sender];

    // transfer NFT back to user
    erc721token.transferFrom(
      address(this),
      msg.sender,
      user.stakedTokenId
    );

    emit Withdraw(msg.sender, user.stakedTokenId);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
