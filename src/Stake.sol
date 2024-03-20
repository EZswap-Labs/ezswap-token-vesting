// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

contract Stake is Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    ERC20 public token;

    struct UnstakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => uint256) public stakes;
    mapping(address => UnstakeInfo[2]) public unstakeInfos;

    uint256 public initialCheckPoint;
    uint256 public checkPointInterval;
    uint256 public withdrawDelay;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address tokenAddress, uint256 _initialCheckPoint, uint256 _checkPointInterval) Owned(msg.sender) {
        token = ERC20(tokenAddress);
        initialCheckPoint = _initialCheckPoint;

        checkPointInterval = _checkPointInterval;
        withdrawDelay = 2 * _checkPointInterval;
    }

    function stake(uint256 amount) external nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(stakes[msg.sender] >= amount && amount != 0, "Unstake balance error.");

        uint256 nextCheckPoint = getNextCheckPoint(block.timestamp);
        uint256 index = findAvailableSlot(msg.sender, nextCheckPoint);

        UnstakeInfo storage info = unstakeInfos[msg.sender][index];
        if (info.timestamp != nextCheckPoint) {
            info.amount = 0;
            info.timestamp = nextCheckPoint;
        }
        info.amount += amount;

        stakes[msg.sender] -= amount;
        emit Unstaked(msg.sender, amount);
    }

    function withdraw() external nonReentrant {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < 2; i++) {
            UnstakeInfo storage info = unstakeInfos[msg.sender][i];
            if (block.timestamp >= info.timestamp + withdrawDelay && info.amount > 0) {
                totalAmount += info.amount;
                info.amount = 0;
                info.timestamp = 0;
            }
        }

        require(totalAmount > 0, "No available amount to withdraw.");

        token.safeTransfer(msg.sender, totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getNextCheckPoint(uint256 currentTime) public view returns (uint256) {
        if (currentTime <= initialCheckPoint) {
            return initialCheckPoint;
        }

        uint256 sinceInitialCheckPoint = (currentTime - initialCheckPoint) / checkPointInterval;
        uint256 nextCheckPoint = initialCheckPoint + (sinceInitialCheckPoint + 1) * checkPointInterval;

        return nextCheckPoint;
    }

    function findAvailableSlot(address user, uint256 nextCheckPoint) private view returns (uint256) {
        for (uint256 i = 0; i < 2; i++) {
            if (unstakeInfos[user][i].timestamp == nextCheckPoint || unstakeInfos[user][i].amount == 0) {
                return i;
            }
        }
        revert("You have an unwithdrawn amount, please withdraw and try again.");
    }

    function getTotalUnstakedAmount(address user) public view returns (uint256) {
        uint256 totalUnstaked = 0;
        for (uint256 i = 0; i < unstakeInfos[user].length; i++) {
            totalUnstaked += unstakeInfos[user][i].amount;
        }
        return totalUnstaked;
    }

    function getAvailableWithdrawAmount(address user) public view returns (uint256) {
        uint256 availableWithdraw = 0;
        for (uint256 i = 0; i < unstakeInfos[user].length; i++) {
            UnstakeInfo storage info = unstakeInfos[user][i];
            if (block.timestamp >= info.timestamp + withdrawDelay && info.amount > 0) {
                availableWithdraw += info.amount;
            }
        }
        return availableWithdraw;
    }

    function getUnstakeInfo(address user, uint256 index) external view returns (uint256 amount, uint256 timestamp) {
        require(index < 2, "Index out of bounds");
        UnstakeInfo storage info = unstakeInfos[user][index];
        return (info.amount, info.timestamp);
    }

    function saveERC20(address _erc20, uint256 _amount) external onlyOwner {
        require(_erc20 != address(token), "Can't transfer stake token.");
        ERC20(_erc20).safeTransfer(owner, _amount);
    }
}
