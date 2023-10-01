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

  event Deposit(address indexed from, uint256 amount);
  event Withdraw(address indexed to, uint256 amount);
  event Cancel(address indexed to, uint256 amount);

  constructor(address _buyer, address _seller, address _token) {
    buyer = _buyer;
    seller = _seller;
    token = _token;
  }

  /// Deposits `amount` of `token` into the escrow.
  /// @dev Only `buyer` can call this method.
  /// @param amount The amount of `token` to deposit.
  function deposit(uint256 amount) external {
    require(msg.sender == buyer, "Only buyer can call this method");
    startTimestamp = block.timestamp;

    IERC20(token).safeTransferFrom(buyer, address(this), amount);

    emit Deposit(buyer, amount);
  }

  /// Withdraws all `token` from the escrow.
  /// @dev Only `seller` can call this method after `TIMELOCK` has passed.
  function withdraw() external {
    require(msg.sender == seller, "Only seller can call this method");
    require(block.timestamp >= startTimestamp + TIMELOCK, "Timelock not expired");

    IERC20(token).safeTransfer(seller, IERC20(token).balanceOf(address(this)));

    emit Withdraw(seller, IERC20(token).balanceOf(address(this)));
  }

  /// Cancels the escrow and returns all `token` to `buyer`.
  /// @dev Only `buyer` can call this method.
  function cancel() external {
    require(msg.sender == buyer, "Only buyer can call this method");

    IERC20(token).safeTransfer(buyer, IERC20(token).balanceOf(address(this)));

    emit Cancel(buyer, IERC20(token).balanceOf(address(this)));
  }
}
