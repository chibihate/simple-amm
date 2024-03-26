// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address tokenA;
        address tokenB;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 97) {
            activeNetworkConfig = getBnbConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getBnbConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            tokenA: 0x4114eaEB687508d3C4f31349BB03ec85Af08ea7b,
            tokenB: 0x7799D3d9E7cfc0F1a1955B0176a0679114cE14d3,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.tokenA != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast(DEFAULT_ANVIL_KEY);
        ERC20Mock tokenA = new ERC20Mock();
        ERC20Mock tokenB = new ERC20Mock();
        tokenA.mint(msg.sender, 1000e18);
        tokenB.mint(msg.sender, 1000e18);
        vm.stopBroadcast();
        return NetworkConfig({tokenA: address(tokenA), tokenB: address(tokenB), deployerKey: DEFAULT_ANVIL_KEY});
    }
}
