// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
// import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Token is ERC20Upgradeable, Ownable2StepUpgradeable, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  function initialize(string memory name_, string memory symbol_) public initializer {
      __ERC20_init(name_, symbol_);
      __Ownable2Step_init();
      __UUPSUpgradeable_init(); // Is this step needed doesn't seem to do anything

      _mint(msg.sender, 1000000 * 10 ** decimals());

      approvedMinters[msg.sender] = 1;
      emit ApproveMinter(msg.sender);
  }

  mapping(address => uint256) public approvedMinters;

  event ApproveMinter(address indexed minter);

  function mint(address _to, uint256 _amount) external {
    require(approvedMinters[msg.sender] == 1, "Not approved minter");
    _mint(_to, _amount);
  }

  function approveMinter(address _minter) external onlyOwner {
    approvedMinters[_minter] = 1;

    emit ApproveMinter(_minter);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
