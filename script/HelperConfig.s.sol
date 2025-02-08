// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();


    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ANVIL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0x3D36bEA55a2590a0ECC8c85Ff7CeF4091A9e1194;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;


    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }
    
    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
    
    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if(chainId == ANVIL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
    } 

    function getZkSyncSePoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        // deploy mock entrypoint contract
    }
}