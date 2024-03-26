// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CPAMM} from "../src/CPAMM.sol";

contract DeployCPAMM is Script {
    function run() external returns (CPAMM, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (address tokenA, address tokenB, uint256 deployerKey) = config.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        CPAMM amm = new CPAMM(tokenA, tokenB);
        vm.stopBroadcast();
        return (amm, config);
    }
}
