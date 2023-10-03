// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of a ERC20 token with a blacklist allowing the owner to sanction accounts.
 */
contract TokenWithSanction is ERC20, Ownable {
  mapping (address => bool) public blacklist;

  event Blacklisted(address indexed account);

  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

  /**
    * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    * - `to` must not be blacklisted.
  */
  function mint(address to, uint256 amount) external {
    require(!blacklist[msg.sender], "Caller is blacklisted");
    _mint(to, amount);
  }

  /**
    * @dev Destroys `amount` tokens from `account`, reducing the total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    * - `account` must not be blacklisted.
  */
  function burn(address from, uint256 amount) external {
    require(!blacklist[msg.sender], "Caller is blacklisted");
    _burn(from, amount);
  }

  /**
    * @dev Moves `amount` tokens from `sender` to `recipient`.
    *
    * Emits a {Transfer} event.
    *
    * Requirements
    *
    * - `sender` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - `caller` must not be blacklisted.
    * - `recipient` must not be blacklisted.
  */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(!blacklist[msg.sender], "Caller is blacklisted");
    require(!blacklist[recipient], "Caller is blacklisted");
    return super.transfer(recipient, amount);
  }

  /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's allowance.
    *
    * Emits a {Transfer} event.
    *
    * Requirements
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - `caller` must have allowance for ``sender``'s tokens of at least `amount`.
    * - `caller` and `recipient` must not be blacklisted.
  */
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(!blacklist[sender], "Caller is blacklisted");
    require(!blacklist[recipient], "Recipient is blacklisted");
    return super.transferFrom(sender, recipient, amount);
  }

  /**
    * @dev Sanctions `account` by adding it to the blacklist.
    *
    * Requirements
    *
    * - only the owner can call this function.
  */
  function addToBlacklist(address account) external onlyOwner {
    blacklist[account] = true;

    emit Blacklisted(account);
  }
}
