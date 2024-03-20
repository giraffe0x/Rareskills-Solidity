// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { NFTStakingUpgradeable } from "../contracts/Week2/NFTStakingUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployUUPSProxy is Script {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privateKey);
    bytes32 public root = 0x897d6714686d83f84e94501e5d6f0f38c94b75381b88d1de3878b4f3d2d5014a;

    function run() public {

        address _implementation = 0xC360B5e70602A431eEAff66f03634Da650A5241C; // Replace with your token address
        vm.startBroadcast(deployer);

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            NFTStakingUpgradeable(_implementation).initialize.selector,
            0x895FCC302f1435A22EDA9DF76De25590674BE929,
            0x911d58A555265B2fF74392eB00ad7533334Abc86
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}
