// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {SimpleCPAMM} from "../src/SimpleCPAMM.sol";

contract DeploySimpleCPAMM is Script {
    function run() external returns (SimpleCPAMM, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (address tokenA, address tokenB, uint256 deployerKey) = config.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        SimpleCPAMM amm = new SimpleCPAMM(tokenA, tokenB);
        vm.stopBroadcast();
        return (amm, config);
    }
}
