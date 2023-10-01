// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1363 } from "../tokens/IERC1363.sol";
import { BancorFormula } from "../utils/BancorFormula.sol";

contract TokenSale is BancorFormula, ERC20 {
  uint256 public scale = 10**18;
  uint256 public reserveBalance = 10 * scale;
  uint256 public reserveRatio;
  address public daiERC1363;

  // TODO add events
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);

  constructor(uint256 _reserveRatio, address _dai) ERC20("TokenSale", "TSL") {
    reserveRatio = _reserveRatio;
    daiERC1363 = _dai;
    _mint(msg.sender, 1 * scale);
  }

  function mint(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");

    bool success = IERC1363(daiERC1363).transferFrom(msg.sender, address(this), amount);
    require(success, "Transfer failed");

    _continuousMint(msg.sender, amount);
  }

  function burn(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    require(balanceOf(msg.sender) >= amount, "Not enough tokens to burn");

    _continuousBurn(msg.sender, amount);
  }

  function _continuousMint(address to, uint256 amount) internal {
    uint256 mintAmount = calculateMintAmount(amount);
    _mint(to, mintAmount);
    reserveBalance += amount;

    emit Mint(to, mintAmount);
  }

  function _continuousBurn(address from, uint256 amount) internal {
    uint256 returnAmount = calculateBurnAmount(amount);

    _burn(from, amount);
    reserveBalance -= returnAmount;
    bool success = IERC1363(daiERC1363).transfer(from, returnAmount);
    require(success, "Transfer failed");

    emit Burn(from, amount);
  }

  function calculateMintAmount(uint256 amount) public view returns (uint256) {
    uint256 mintAmount = purchaseTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return mintAmount;
  }

  function calculateBurnAmount(uint256 amount) public view returns (uint256) {
    uint256 returnAmount = saleTargetAmount(
      totalSupply(),
      reserveBalance,
      uint32(reserveRatio),
      amount
    );
    return returnAmount;
  }

  function getPrice() external view returns (uint256) {
    return reserveBalance * 1e18 / (totalSupply() * reserveRatio);
  }

  // ERC1363: onTransferReceived(_msgSender(), sender, amount, data)

  // fallback(bytes calldata) external payable returns(bytes memory) {
  //   // if else for ERC1363 and ERC777, check function selector
  //   (, address sender, uint256 amount, ) = abi.decode(msg.data, (address, address, uint256, bytes));
  //   _depositAndMint(sender, amount);

    // return bytes4(keccak256("balanceOf(address)"));
  // }
}
