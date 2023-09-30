// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UntrustedEscrow {
  using SafeERC20 for IERC20;

  address public buyer;
  address public seller;
  address public token;

  uint256 public startTimestamp;
  uint256 public constant TIMELOCK = 3 days;

  constructor(address _buyer, address _seller, address _token) {
    buyer = _buyer;
    seller = _seller;
    token = _token;
  }

  function deposit(uint256 amount) external {
    require(msg.sender == buyer, "Only buyer can call this method");
    startTimestamp = block.timestamp;

    IERC20(token).safeTransferFrom(buyer, address(this), amount);
  }

  function withdraw() external {
    require(msg.sender == seller, "Only seller can call this method");
    require(block.timestamp >= startTimestamp + TIMELOCK, "Timelock not expired");

    IERC20(token).safeTransfer(seller, IERC20(token).balanceOf(address(this)));
  }

  function cancel() external {
    require(msg.sender == buyer, "Only buyer can call this method");

    IERC20(token).safeTransfer(buyer, IERC20(token).balanceOf(address(this)));
  }
}
