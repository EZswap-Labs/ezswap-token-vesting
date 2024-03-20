// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Vesting.sol";
import "../src/EZSwapToken.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("MANTA_PRIVATE_KEY");
        vm.startBroadcast(deployerPK);

        address token = 0xa64A1Ce3A3692A0326d457a7EAcCCF130C2f9662;

        Vesting vestingInvestorTeamAdvisorCommunity = new Vesting(
            address(token),
            "InvestorTeamAdvisorCommunity_Lock",
            180 days,
            90 days,
            450_000_00 * 10 ** 18,
            450_000_000 * 10 ** 18,
            6
        );

        Vesting vestingTreasury =
            new Vesting(address(token), "Treasury_Lock", 365 days, 90 days, 0, 100_000_000 * 10 ** 18, 8);

        Vesting vestingCommunity =
            new Vesting(address(token), "CommunityAirdrop_Lock", 180 days, 90 days, 0, 385_000_000 * 10 ** 18, 8);

        vm.stopBroadcast();
    }
}
