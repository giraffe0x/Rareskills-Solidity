// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1363 } from "../tokens/IERC1363.sol";
import { IERC1363Receiver } from "../tokens/IERC1363Receiver.sol";
import { BancorFormula } from "../utils/BancorFormula.sol";

contract TokenSale is BancorFormula, ERC20 {
  uint256 public scale = 10**18;
  uint256 public reserveBalance = 10 * scale;
  uint256 public reserveRatio;
  address public daiERC1363;

  mapping(address => uint256) public mintTimestamp;

  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);

  constructor(uint256 _reserveRatio, address _dai) ERC20("TokenSale", "TSL") {
    reserveRatio = _reserveRatio;
    daiERC1363 = _dai;
    _mint(msg.sender, 1 * scale);
  }

  /// @notice Mints tokens to the caller.
  /// @param amount The amount of DAI to deposit.
  function mint(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");

    bool success = IERC1363(daiERC1363).transferFrom(msg.sender, address(this), amount);
    require(success, "Transfer failed");

    mintTimestamp[msg.sender] = block.timestamp;

    _continuousMint(msg.sender, amount);
  }

  /// @notice Burns tokens from the caller.
  /// @param amount The amount of tokens to burn.
  function burn(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    require(balanceOf(msg.sender) >= amount, "Not enough tokens to burn");
    require(block.timestamp >= mintTimestamp[msg.sender] + 1 days, "Must wait 1 day before burning");

    _continuousBurn(msg.sender, amount);
  }

  /// @notice Internal function to calculate amount of tokens to mint and
  ///      transfer them to `to`.
  /// @param to The address to mint tokens to.
  /// @param amount The amount of DAI deposited.
  function _continuousMint(address to, uint256 amount) internal {
    uint256 mintAmount = calculateMintAmount(amount);
    _mint(to, mintAmount);
    reserveBalance += amount;

    emit Mint(to, mintAmount);
  }

  /// @notice Internal function to calculate amount of tokens to return
  ///      and burn them from `from`.
  /// @param from The address to burn tokens from.
  /// @param amount The amount of tokens to burn.
  function _continuousBurn(address from, uint256 amount) internal {
    uint256 returnAmount = calculateBurnAmount(amount);

    _burn(from, amount);
    reserveBalance -= returnAmount;
    bool success = IERC1363(daiERC1363).transfer(from, returnAmount);
    require(success, "Transfer failed");

    emit Burn(from, amount);
  }

  /// @notice Calculates the amount of tokens to mint using Bancor formula
  /// @param amount The amount of DAI deposited.
  function calculateMintAmount(uint256 amount) public view returns (uint256) {
    uint256 mintAmount = purchaseTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return mintAmount;
  }

  /// @notice Calculates the amount of tokens to return using Bancor formula
  /// @param amount The amount of tokens to burn.
  function calculateBurnAmount(uint256 amount) public view returns (uint256) {
    uint256 returnAmount = saleTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return returnAmount;
  }

  /// @notice Calculates the price of the token in DAI
  function getPrice() external view returns (uint256) {
    return reserveBalance * 1e18 / (totalSupply() * reserveRatio);
  }

  /// @notice Callback for ERC1363 transfers, mints tokens to the sender.
  /// @param from The address which are token transferred from.
  /// @param amount The amount of tokens transferred.
  function onTransferReceived(
    address /* operator */,
    address from,
    uint256 amount,
    bytes calldata /*  data */
  ) external returns (bytes4) {
    require(msg.sender == daiERC1363, "Only DAI accepted");
    _continuousMint(from, amount);
    return IERC1363Receiver.onTransferReceived.selector;
  }
}
