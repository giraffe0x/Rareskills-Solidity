// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract ERC20Token is ERC20, Ownable2Step {
  constructor() ERC20("ERC20Token", "ERC20") {}

  mapping(address => uint256) public approvedMinters;

  function mint(address _to, uint256 _amount) external {
    require(approvedMinters[msg.sender] == 1, "Not approved minter");
    _mint(_to, _amount);
  }

  function approveMinter(address _minter) external onlyOwner {
    approvedMinters[_minter] = 1;
  }
}
