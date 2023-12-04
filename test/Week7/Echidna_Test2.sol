// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Token } from  "../../contracts/Week7/Echidna_Exercise2.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise2/template.sol
///      ```
contract TestToken is Token {
    constructor() {
        pause(); // pause the contract
        owner = address(0); // lose ownership
    }

    function echidna_cannot_be_unpause() public view returns (bool) {
        // TODO: add the property
        return paused() == true;
    }
}
