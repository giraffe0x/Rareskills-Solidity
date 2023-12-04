// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { Token } from  "../../contracts/Week7/Echidna_Exercise4.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise4/template.sol --contract TestToken --test-mode assertion
///      ```
contract TestToken is Token {
    function transfer(address to, uint256 value) public override {
        // TODO: include `assert(condition)` statements that
        // detect a breaking invariant on a transfer.
        // Hint: you may use the following to wrap the original function.
        uint256 originalBalanceSender = balances[msg.sender];
        uint256 originalBalanceTo = balances[to];

        super.transfer(to, value);

        assert(balances[msg.sender] <= originalBalanceSender);
        assert(balances[to] >= originalBalanceTo);

    }
}
