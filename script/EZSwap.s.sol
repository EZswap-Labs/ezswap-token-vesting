// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Stake.sol";
import "../src/EZSwapToken.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("MANTA_PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        EZSWAP token = new EZSWAP(0x94A47b89c600962EFF6F4cf53DFD05aA05B522b5);

        vm.stopBroadcast();
    }
}
