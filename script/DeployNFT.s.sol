// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { NFTWithMerkleDiscountUpgradeable } from "../contracts/Week2/NFTWithMerkleDiscountUpgradeable.sol";
import "forge-std/Script.sol";

contract DeployTokenImplementation is Script {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privateKey);

    function run() public {
        // Use address provided in config to broadcast transactions
        vm.startBroadcast(deployer);
        // Deploy the ERC-20 token
        NFTWithMerkleDiscountUpgradeable implementation = new NFTWithMerkleDiscountUpgradeable();
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));
    }
}
