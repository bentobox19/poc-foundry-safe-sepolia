// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Safe} from "@safe-global/safe-contracts/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import {console} from "forge-std/console.sol";

contract DeploySafe is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_0");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory owners = new address[](5);
        owners[0] = vm.envAddress("WALLET_ADDRESS_1");
        owners[1] = vm.envAddress("WALLET_ADDRESS_2");
        owners[2] = vm.envAddress("WALLET_ADDRESS_3");
        owners[3] = vm.envAddress("WALLET_ADDRESS_4");
        owners[4] = vm.envAddress("WALLET_ADDRESS_5");

        Safe singleton = Safe(payable(0x41675C099F32341bf84BFc5382aF534df5C7461a));
        SafeProxyFactory factory = SafeProxyFactory(0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67);

        bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners, 3, address(0), "", address(0), address(0), 0, address(0));

        address safeProxy = address(factory.createProxyWithNonce(address(singleton), initializer, block.timestamp));

        console.log("Safe deployed at:", safeProxy);

        vm.stopBroadcast();
    }
}
