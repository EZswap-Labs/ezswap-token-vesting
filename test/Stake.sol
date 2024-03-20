// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

import "src/Stake.sol";
import "src/Token.sol";

contract TestContract is Test {
    Stake stakeContract;
    EZTokenTest token;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user = 0xEeb6C7B10F2c0d259D21eB9cc5d37664bb123602;

    uint256 nowTimestamp = 2000000;

    function setUp() public {
        vm.startPrank(owner);
        token = new EZTokenTest();

        stakeContract = new Stake(
            address(token),
            nowTimestamp, // now timestamp
            10 minutes
        );

        token.transfer(user, 30_000 * 10 ** 18);
    }

    function test_stake() public {
        vm.startPrank(user);

        token.approve(address(stakeContract), type(uint256).max);

        stakeContract.stake(10_000 * 10 ** 18);
        stakeContract.stake(10_000 * 10 ** 18);
        stakeContract.stake(10_000 * 10 ** 18);

        assertEq(token.balanceOf(address(stakeContract)), stakeContract.stakes(user), "stake balance error");

        assertEq(0, stakeContract.getTotalUnstakedAmount(user), "UnstakedAmoun error");
        assertEq(0, stakeContract.getAvailableWithdrawAmount(user), "UnstakedAmoun error");
    }

    function test_unstake() public {
        test_stake();

        vm.startPrank(user);

        // first unstake
        vm.warp(nowTimestamp + 8 minutes);

        stakeContract.unstake(10_000 * 10 ** 18);

        assertEq(20_000 * 10 ** 18, stakeContract.stakes(user), "stakes balance error");

        (uint256 amountUnstake, uint256 timestampUnstake) = stakeContract.getUnstakeInfo(user, 0);

        uint256 ts = stakeContract.initialCheckPoint() + stakeContract.checkPointInterval();

        assertEq(10_000 * 10 ** 18, amountUnstake, "amountUnstake error");
        assertEq(ts, timestampUnstake, "timestamp error");

        // second unstake
        vm.warp(nowTimestamp + 9 minutes);
        stakeContract.unstake(5_000 * 10 ** 18);

        assertEq(15_000 * 10 ** 18, stakeContract.stakes(user), "stakes balance error");

        (uint256 amountUnstake2, uint256 timestampUnstake2) = stakeContract.getUnstakeInfo(user, 0);

        uint256 ts2 = stakeContract.initialCheckPoint() + stakeContract.checkPointInterval();

        assertEq(15_000 * 10 ** 18, amountUnstake2, "amountUnstake error");
        assertEq(ts2, timestampUnstake2, "timestamp error");

        // third unstake
        vm.warp(nowTimestamp + 12 minutes);
        stakeContract.unstake(5_000 * 10 ** 18);

        assertEq(10_000 * 10 ** 18, stakeContract.stakes(user), "stakes balance error");

        (uint256 amountUnstake3, uint256 timestampUnstake3) = stakeContract.getUnstakeInfo(user, 1);

        uint256 ts3 = stakeContract.initialCheckPoint() + stakeContract.checkPointInterval() * 2;

        assertEq(5_000 * 10 ** 18, amountUnstake3, "amountUnstake error");
        assertEq(ts3, timestampUnstake3, "timestamp error");
    }

    function test_withdraw() external {
        test_unstake();

        vm.startPrank(user);
        vm.warp(nowTimestamp + 30 minutes);

        uint256 balanceBefore = token.balanceOf(user);

        assertEq(stakeContract.getTotalUnstakedAmount(user), 20_000 * 10 ** 18, "getTotalUnstakedAmount error");
        assertEq(stakeContract.getAvailableWithdrawAmount(user), 15_000 * 10 ** 18, "getAvailableWithdrawAmount error");

        stakeContract.withdraw();

        (uint256 amountUnstake1, uint256 timestampUnstake1) = stakeContract.getUnstakeInfo(user, 0);
        assertEq(0, amountUnstake1, "amountUnstake error");
        assertEq(0, timestampUnstake1, "amountUnstake error");

        (uint256 amountUnstake2, uint256 timestampUnstake2) = stakeContract.getUnstakeInfo(user, 1);
        uint256 ts2 = stakeContract.initialCheckPoint() + stakeContract.checkPointInterval() * 2;
        assertEq(5_000 * 10 ** 18, amountUnstake2, "amountUnstake error");
        assertEq(ts2, timestampUnstake2, "amountUnstake error");

        uint256 balanceAfter = token.balanceOf(user);
        assertEq(balanceAfter - balanceBefore, 15_000 * 10 ** 18, "balance error");
    }
}
