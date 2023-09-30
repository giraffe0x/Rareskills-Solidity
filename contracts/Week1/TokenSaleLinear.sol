// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1363 } from "../tokens/IERC1363.sol";
import { BancorFormula } from "../utils/BancorFormula.sol";


contract TokenSaleLinear is BancorFormula, ERC20 {
  uint256 public scale = 10**18;
  uint256 public reserveBalance = 10 * scale;
  uint256 public reserveRatio;
  address public daiERC1363;

  constructor(uint256 _reserveRatio, address _dai) ERC20("TokenSaleLinear", "TSL") {
    reserveRatio = _reserveRatio;
    daiERC1363 = _dai;
  }

  function burn(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    require(balanceOf(msg.sender) >= amount, "Not enough tokens to burn");

    uint256 returnAmount = _calculateBurnAmount(amount);

    _burn(msg.sender, amount);
    reserveBalance -= returnAmount;
    bool success = IERC1363(daiERC1363).transfer(msg.sender, returnAmount);
    require(success, "Transfer failed");
  }

  function _depositAndMint(address to, uint256 amount) internal {
    uint256 mintAmount = _calculateMintAmount(amount);
    reserveBalance += amount;
    _mint(to, mintAmount);
  }

  function _calculateMintAmount(uint256 amount) internal view returns (uint256) {
    uint256 mintAmount = purchaseTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return mintAmount;
  }

  function _calculateBurnAmount(uint256 amount) internal view returns (uint256) {
    uint256 returnAmount = saleTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return returnAmount;
  }

  // ERC1363: onTransferReceived(_msgSender(), sender, amount, data)

  fallback(bytes calldata) external payable returns(bytes memory) {
    // if else for ERC1363 and ERC777, check function selector
    (, address sender, uint256 amount, ) = abi.decode(msg.data, (address, address, uint256, bytes));
    _depositAndMint(sender, amount);

    // return bytes4(keccak256("balanceOf(address)"));
  }
}
