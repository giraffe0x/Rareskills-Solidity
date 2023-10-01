// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1363 } from "../tokens/ERC1363.sol";

contract MockERC1363 is ERC1363 {
  constructor() ERC20("ERC20Mock", "E20M") {}

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }
}
