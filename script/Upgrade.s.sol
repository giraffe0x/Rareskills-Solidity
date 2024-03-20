// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { NFTStakingUpgradeableV2 } from "../contracts/Week2/NFTStakingUpgradeableV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract Upgrade is Script {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privateKey);

    function run() public {
        address currentProxy = 0x97DFC8B13d41b665b850144a4b6c26E91F1D1c72;
        address newImplementation = 0x26Bea7F80AfB913b55EDBF008001248307547f41;
        vm.startBroadcast(deployer);

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            NFTStakingUpgradeableV2(newImplementation).initialize.selector,
            0x895FCC302f1435A22EDA9DF76De25590674BE929,
            0x911d58A555265B2fF74392eB00ad7533334Abc86
        );

        ERC1967Proxy proxy = ERC1967Proxy(payable(currentProxy));

        address(proxy).call{value: 0}(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", newImplementation, data));

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}
