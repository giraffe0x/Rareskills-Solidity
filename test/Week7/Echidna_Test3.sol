// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MintableToken } from  "../../contracts/Week7/Echidna_Exercise3.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise3/template.sol --contract TestToken
///      ```
contract TestToken is MintableToken {
    address echidna = msg.sender;
    int256 _totalMintable = 1000;

    // TODO: update the constructor
    constructor() MintableToken(_totalMintable) {
        owner = echidna;
    }

    function echidna_test_balance() public view returns (bool) {
        // TODO: add the property
        return balances[echidna] <= 1000;
    }
}
