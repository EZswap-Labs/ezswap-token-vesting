// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "src/Vesting.sol";
import "src/EZSwapToken.sol";

contract TestContract is Test {
    Vesting vesting;
    EZSwap token;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user = 0xEeb6C7B10F2c0d259D21eB9cc5d37664bb123602;

    function setUp() public {
        vm.startPrank(owner);
        token = new EZSwap(owner);
        vesting = new Vesting(address(token));

        token.setWhitelist(owner, true);
        token.setWhitelist(address(vesting), true);
    }

    function testCreateLock() public {
        vm.startPrank(owner);

        uint256 approveAmount = vesting.lockAmount();
        token.approve(address(vesting), approveAmount);

        vesting.createLock();
        assertEq(token.balanceOf(address(vesting)), approveAmount, "lock failed");
        assertEq(vesting.startTime(), block.timestamp, "start time error");
        assertTrue(vesting.created(), "created error");
    }

    function testFailCreateLockTwice() public {
        testCreateLock();
        testCreateLock();
    }

    function testFailCreateLockNotOwner() public {
        vm.startPrank(user);
        uint256 approveAmount = vesting.lockAmount();
        token.approve(address(vesting), approveAmount);
        vesting.createLock();
    }

    function testClaim() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 interval = 90 * 24 * 60 * 60;
        for (uint256 i = 0; i < vesting.maxClaimCount(); i++) {
            uint256 ownerBalanceBefore = token.balanceOf(owner);
            vm.warp(block.timestamp + (i + 1) * interval);
            vesting.claim();
            uint256 ownerBalanceAfter = token.balanceOf(owner);
            assertEq(ownerBalanceAfter - ownerBalanceBefore, vesting.perAmountClaim(), "perAmountClaim error");
            assertEq(i+1, vesting.count(), "count error");
        }

        assertTrue(vesting.vestingEnded(), "vestingEnded error");
        assertEq(token.balanceOf(address(vesting)), 0, "vesting token balance error");
    }

    function testFailClaimErrorOwner() public {
        testCreateLock();
        vm.startPrank(user);

        uint256 interval = 90 * 24 * 60 * 60;
        vm.warp(block.timestamp + interval);
        vesting.claim();
    }

    function testFailClaimErrorTime() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 interval = 90 * 24 * 60 * 60 - 1;
        vm.warp(block.timestamp + interval);
        vesting.claim();
    }

    function testFailClaimErrorCount() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 interval = 90 * 24 * 60 * 60;

        for (uint256 i = 0; i <= vesting.maxClaimCount(); i++) {
            uint256 ownerBalanceBefore = token.balanceOf(owner);
            vm.warp(block.timestamp + (i + 1) * interval);
            vesting.claim();
            uint256 ownerBalanceAfter = token.balanceOf(owner);
            assertEq(ownerBalanceAfter - ownerBalanceBefore, vesting.perAmountClaim(), "perAmountClaim error");
        }
    }

    function testOwnerCall() public {
        testClaim();

        vm.startPrank(owner);
        uint256 lostBalance = 10000;
        token.transfer(address(vesting), lostBalance);

        uint256 ownerBalanceBeforeCall = token.balanceOf(address(owner));

        assertEq(token.balanceOf(address(vesting)), lostBalance, "wrong balance");
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(owner), lostBalance);
        vesting.ownerCall(address(token), data);

        uint256 ownerBalanceAfterCall = token.balanceOf(address(owner));

        assertEq(token.balanceOf(address(vesting)), 0, "wrong balance");
        assertEq(ownerBalanceAfterCall - ownerBalanceBeforeCall, lostBalance, "wrong balance");
    }

    function testFailOwnerCallBeforeEnded() public {
        testCreateLock();
        vm.startPrank(owner);

        uint256 interval = 90 * 24 * 60 * 60;
        vm.warp(block.timestamp + interval);
        vesting.claim();

        uint256 lostBalance = 10000;
        token.transfer(address(vesting), lostBalance);

        assertEq(token.balanceOf(address(vesting)), lostBalance, "wrong balance");
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", address(owner), lostBalance);
        vesting.ownerCall(address(token), data);
    }
}
