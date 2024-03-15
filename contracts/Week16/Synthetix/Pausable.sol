// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/pausable
abstract contract Pausable is Owned {
    uint32 public lastPauseTime;
    uint32 public paused = 1;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(uint32 _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused == 2) {
            lastPauseTime = uint32(block.timestamp);
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(_paused);
    }

    event PauseChanged(uint32 isPaused);

    modifier notPaused {
        require(paused == 1, "This action cannot be performed while the contract is paused");
        _;
    }
}
