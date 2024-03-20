// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of a ERC20 token with a blacklist allowing the owner to sanction accounts.
 */
contract TokenWithGodMode is ERC20, Ownable {
  address public immutable god;
  uint256 public constant TOTAL_SUPPLY = 1_000_000;

  constructor(
    string memory _name,
    string memory _symbol,
    address _god
  ) ERC20(_name, _symbol) Ownable(msg.sender) {
      god = _god;
      _mint(_god, TOTAL_SUPPLY);
  }

  modifier onlyGod {
    require(msg.sender == god, "Only god can call this function");
    _;
  }

  /**
    * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
  */
  function mint(address to, uint256 amount) external onlyGod {
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
  */
  function burn(address from, uint256 amount) external onlyGod {
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
  */
  function transfer(address recipient, uint256 amount) public override onlyGod returns (bool) {
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
  */
  function transferFrom(address sender, address recipient, uint256 amount) public override onlyGod returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }
}
