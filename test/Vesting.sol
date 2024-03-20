// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "src/Vesting.sol";
import "src/EZSwapToken.sol";

contract TestContract is Test {
    Vesting vestingInvestorTeamAdvisorCommunity;
    Vesting vestingTreasury;
    Vesting vestingCommunity;

    EZSWAP token;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user = 0xEeb6C7B10F2c0d259D21eB9cc5d37664bb123602;

    function setUp() public {
        vm.startPrank(owner);
        token = new EZSWAP(owner);

        vestingInvestorTeamAdvisorCommunity = new Vesting(
            address(token),
            "InvestorTeamAdvisorCommunity_Lock",
            180 days,
            90 days,
            450_000_00 * 10 ** 18,
            450_000_000 * 10 ** 18,
            6
        );

        vestingTreasury = new Vesting(address(token), "Treasury_Lock", 365 days, 90 days, 0, 100_000_000 * 10 ** 18, 8);

        vestingCommunity =
            new Vesting(address(token), "CommunityAirdrop_Lock", 180 days, 90 days, 0, 385_000_000 * 10 ** 18, 8);

        token.transfer(user, 0);
        // token.setWhitelist(owner, true);
        // token.setWhitelist(address(vestingInvestorTeamAdvisorCommunity), true);
        // token.setWhitelist(address(vestingTreasury), true);
        // token.setWhitelist(address(vestingInvestorTeamAdvisorCommunity), true);
    }

    function testCreateLock() public {
        vm.startPrank(owner);

        uint256 approveAmount = vestingInvestorTeamAdvisorCommunity.totalLockAmount();
        token.approve(address(vestingInvestorTeamAdvisorCommunity), approveAmount);

        vestingInvestorTeamAdvisorCommunity.createLock();
        assertEq(token.balanceOf(address(vestingInvestorTeamAdvisorCommunity)), approveAmount, "lock failed");
        assertEq(vestingInvestorTeamAdvisorCommunity.startTime(), block.timestamp, "start time error");
        assertTrue(vestingInvestorTeamAdvisorCommunity.created(), "created error");
    }

    function testFailCreateLockTwice() public {
        testCreateLock();
        testCreateLock();
    }

    function testFailCreateLockNotOwner() public {
        vm.startPrank(user);
        uint256 approveAmount = vestingInvestorTeamAdvisorCommunity.totalLockAmount();
        token.approve(address(vestingInvestorTeamAdvisorCommunity), approveAmount);
        vestingInvestorTeamAdvisorCommunity.createLock();
    }

    function testClaimCliff() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 cliffInterval = vestingInvestorTeamAdvisorCommunity.cliffInterval();
        vm.warp(block.timestamp + cliffInterval);

        uint256 ownerBalanceBefore = token.balanceOf(owner);
        vestingInvestorTeamAdvisorCommunity.claimCliff();
        uint256 ownerBalanceAfter = token.balanceOf(owner);

        assertEq(
            ownerBalanceAfter - ownerBalanceBefore,
            vestingInvestorTeamAdvisorCommunity.cliffAmount(),
            "perAmountClaim error"
        );
        assertTrue(vestingInvestorTeamAdvisorCommunity.cliffEnded(), "cliffEnded error");
    }

    function testClaimVesting() public {
        testClaimCliff();
        vm.startPrank(owner);

        uint256 vestingInterval = vestingInvestorTeamAdvisorCommunity.vestingInterval();

        for (uint256 i = 0; i < vestingInvestorTeamAdvisorCommunity.maxClaimVestingCount(); i++) {
            uint256 ownerBalanceBefore = token.balanceOf(owner);
            vm.warp(block.timestamp + (i + 1) * vestingInterval);
            vestingInvestorTeamAdvisorCommunity.claimVesting();
            uint256 ownerBalanceAfter = token.balanceOf(owner);
            assertEq(
                ownerBalanceAfter - ownerBalanceBefore,
                vestingInvestorTeamAdvisorCommunity.vestingAmountPerClaim(),
                "perAmountClaim error"
            );
            assertEq(i + 1, vestingInvestorTeamAdvisorCommunity.claimVestingCount(), "count error");
        }

        assertTrue(vestingInvestorTeamAdvisorCommunity.vestingEnded(), "vestingEnded error");
        assertEq(token.balanceOf(address(vestingInvestorTeamAdvisorCommunity)), 0, "vesting token balance error");
    }

    function testFailClaimErrorOwner() public {
        testCreateLock();
        vm.startPrank(user);

        uint256 cliffInterval = vestingInvestorTeamAdvisorCommunity.cliffInterval();

        vm.warp(block.timestamp + cliffInterval);
        vestingInvestorTeamAdvisorCommunity.claimCliff();
    }

    function testFailClaimErrorTime() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 errorCliffInterval = vestingInvestorTeamAdvisorCommunity.cliffInterval() - 1;

        vm.warp(block.timestamp + errorCliffInterval);
        vestingInvestorTeamAdvisorCommunity.claimCliff();
    }

    function testOwnerCall() public {
        testClaimVesting();

        vm.startPrank(owner);
        uint256 lostBalance = 10000;
        token.transfer(address(vestingInvestorTeamAdvisorCommunity), lostBalance);

        uint256 ownerBalanceBeforeCall = token.balanceOf(address(owner));

        assertEq(token.balanceOf(address(vestingInvestorTeamAdvisorCommunity)), lostBalance, "wrong balance");
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(owner), lostBalance);
        vestingInvestorTeamAdvisorCommunity.ownerCall(address(token), data);

        uint256 ownerBalanceAfterCall = token.balanceOf(address(owner));

        assertEq(token.balanceOf(address(vestingInvestorTeamAdvisorCommunity)), 0, "wrong balance");
        assertEq(ownerBalanceAfterCall - ownerBalanceBeforeCall, lostBalance, "wrong balance");
    }

    function testFailOwnerCallBeforeEnded() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 lostBalance = 10000;
        token.transfer(address(vestingInvestorTeamAdvisorCommunity), lostBalance);

        assertEq(token.balanceOf(address(vestingInvestorTeamAdvisorCommunity)), lostBalance, "wrong balance");
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(owner), lostBalance);
        vestingInvestorTeamAdvisorCommunity.ownerCall(address(token), data);
    }
}
