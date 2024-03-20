// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20Token } from "../contracts/Week2/ERC20Token.sol";
import "forge-std/Script.sol";

contract DeployTokenImplementation is Script {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privateKey);

    function run() public {
        // Use address provided in config to broadcast transactions
        vm.startBroadcast(deployer);
        // Deploy the ERC-20 token
        ERC20Token implementation = new ERC20Token();
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));
    }
}
