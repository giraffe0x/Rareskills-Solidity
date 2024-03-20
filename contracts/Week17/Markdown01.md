Question 1: The OZ upgrade tool for hardhat defends against 6 kinds of mistakes. What are they and why do they matter?

Answer:
1) /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
Immutable variable only assigned during construction. Upgradeable contracts have no constructors but initializers, so can't handle immutable variables

2) /// @custom:oz-upgrades-unsafe-allow state-variable-assignment
State variables are not allowed to be assigned in upgradeable contracts, as they are not preserved between upgrades. This is a security feature to prevent unexpected behavior when upgrading contracts.

3) /// @custom:oz-upgrades-unsafe-allow external-library-linking
Not known at compile time what implementation is going to be linked, thus making it very difficult to guarantee the safety of the upgrade operation.

4) /// @custom:oz-upgrades-unsafe-allow selfdestruct
If the direct call to the logic contract triggers a selfdestruct operation, then the logic contract will be destroyed, and all your contract instances will end up delegating all calls to an address without any code.

5) /// @custom:oz-upgrades-unsafe-allow delegatecall
Delegatecall is a low-level operation that can be used to call a function in another contract. It is a security risk because it can be used to call arbitrary code, including selfdestruct, which can be used to destroy the contract.

6) /// @custom:oz-upgrades-unsafe-allow constructor
Implementation should not have constructors because they have no effect on the proxy storage


Question 2: What is a beacon proxy used for?

Answer:
A beacon is used when you need multiple upgradable contracts, all with the same logic. Only need to update beacon contract once to update all the contracts.


Question 3: Why does the openzeppelin upgradeable tool insert something like uint256[50] private __gap; inside the contracts? To see it, create an upgradeable smart contract that has a parent contract and look in the parent.

Answer:
The __gap is used to reserve space in the storage layout of a contract. This is important when such a contract needs to be inherited. Without the gap, the contract cannot add new storage variable without affecting the inheriting contract's storage layout.


Question 4: What is the difference between initializing the proxy and initializing the implementation? Do you need to do both? When do they need to be done?

Answer:
The proxy is initialized when it is deployed. The implementation is initialized when it is linked to the proxy. You need to do both.

Question 5: What is the use for the reinitializer? Provide a minimal example of proper use in Solidity

Answer:
Usually an initializer is used first and then a reinitializer MAY be used in future upgrades if a module that requires initialization is added.

When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
cannot be nested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./NFTContract1.sol";

contract OurUpgradeableNFT2 is OurUpgradeableNFT1, ERC721URIStorageUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    function reInitialize() public reinitializer(2) {
        __ERC721_init("OurUpgradeableNFT", "OUN");
        __ERC721URIStorage_init();
    }
}
```
Points to note:
1. Inheriting from Initializable in previous contract automatically assigns it version 1.
2. The re-initializer in version 2 needs to be manually invoked. Placing reInitializer(2) modifier just restricts scope of invocation – it does not mean that the function with that modifier will automatically get invoked in version 2.


Ethernaut 16 - Preservation
1. Create attacker contract that calls `setFirstTime()` on Ethernaut instance to set slot0 to attacker contract address
2. Attacker contract's `setTime` should be configured to set slot2 to attacker address
3. Go to Ethernaut instance, call `setFirstTime` with arbitary data which will set `owner` to attacker


Ethernaut 24 - Puzzle Vault
1. Use proxy's `proposeNewAdmin()` to write attacker's address into slot0
2. Use impl's `addToWhiteList()` to impersonate owner and add attacker's address into whitelist
3. Use impl's `setMaxBalance()` to overwrite slot1 with attacker's address
4. Now proxy's slot1 for admin is the attacker

Ethernaut 25 - Motorbike
1. Get implementation address by doing `await web3.eth.getStorageAt(contract.address, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")`
2. Proxy contract makes an error by doing delegatecall initialize when it should be regular call
3. So implementation contract remains un-initialized, and we can set upgrader to attacker's address
4. Then do upgradeToAndCall with attacker's contract that has a `selfdestruct` function, and call that function
