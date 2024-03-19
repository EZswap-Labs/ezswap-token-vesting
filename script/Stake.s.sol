// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Stake.sol";
import "../src/Token.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("MANTATEST_PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        // address token = 0xCa140E6aa4B598A48f877AB880A21b974CE3e056;

        EZTokenTest token = new EZTokenTest();

        uint256 nowTimestamp = 1710939000;

        Stake stakeContract = new Stake(
            address(token),
            nowTimestamp, // now timestamp
            10 minutes
        );

        vm.stopBroadcast();
    }
}
