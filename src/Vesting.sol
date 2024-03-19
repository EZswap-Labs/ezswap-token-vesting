// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

contract Vesting is Owned {
    using SafeTransferLib for ERC20;

    ERC20 immutable VESTING_TOKEN; // vesting token
    string public NAME; // vesting name

    uint256 public cliffInterval; // cliff interval
    uint256 public vestingInterval; // vesting interval

    uint256 public totalLockAmount; // total lock amount
    uint256 public cliffAmount; // cliff amount
    uint256 public vestingAmount; // vesting amount
    uint256 public vestingAmountPerClaim; // vesting amount per claim

    uint256 public startTime; // lock start time
    bool public created; // if create lock
    bool public cliffEnded; // if cliff ended
    bool public vestingEnded; // if vesting ended

    uint256 public maxClaimVestingCount; // owner max claim vesting count
    uint256 public claimVestingCount; // owner claim count

    event Claimed(address claimer, uint256 amount);
    event VestingAndCliffStart(uint256 indexed startTime);
    event CliffEnded();
    event VestingEnded();

    constructor(
        address _token,
        string memory _name,
        uint256 _cliffInterval,
        uint256 _vestingInterval,
        uint256 _cliffAmount,
        uint256 _totalLockAmount,
        uint256 _maxClaimVestingCount
    ) Owned(msg.sender) {
        VESTING_TOKEN = ERC20(_token);
        NAME = _name;
        cliffAmount = _cliffAmount;
        cliffInterval = _cliffInterval;
        vestingInterval = _vestingInterval;
        totalLockAmount = _totalLockAmount;
        maxClaimVestingCount = _maxClaimVestingCount;

        vestingAmount = totalLockAmount - cliffAmount;
        vestingAmountPerClaim = vestingAmount / maxClaimVestingCount;
    }

    // owner creates a lock position only once
    function createLock() external onlyOwner {
        require(!created, "Lock has been created");
        VESTING_TOKEN.safeTransferFrom(msg.sender, address(this), totalLockAmount);

        startTime = block.timestamp;
        created = true;

        emit VestingAndCliffStart(startTime);
    }

    // owner claims cliff tokens after unlocking at interval
    function claimCliff() external onlyOwner {
        require(created, "Lock hasn't been created");
        require(!cliffEnded, "Cliff already ended");
        require(block.timestamp >= startTime + cliffInterval, "Claim not yet available");

        if (cliffAmount != 0) {
            VESTING_TOKEN.safeTransfer(msg.sender, cliffAmount);
        }
        cliffEnded = true;

        emit Claimed(msg.sender, cliffAmount);
        emit CliffEnded();
    }

    // owner claims vesting tokens after unlocking at interval
    function claimVesting() external onlyOwner {
        require(cliffEnded, "Cliff hasn't ended");
        require(!vestingEnded, "Vesting already ended");

        require(
            block.timestamp >= startTime + cliffInterval + (claimVestingCount + 1) * vestingInterval,
            "Claim not yet available"
        );
        require(claimVestingCount < maxClaimVestingCount, "All tokens have been claimed");

        claimVestingCount += 1;
        VESTING_TOKEN.safeTransfer(msg.sender, vestingAmountPerClaim);

        emit Claimed(msg.sender, vestingAmountPerClaim);

        if (claimVestingCount == maxClaimVestingCount) {
            vestingEnded = true;
            emit VestingEnded();
        }
    }

    // This function can only be called after the end of cliff and vesting, and is mainly used for unexpected recovery
    function ownerCall(address target, bytes calldata data) external onlyOwner {
        require(vestingEnded && cliffEnded, "Cliff and vesting have not ended yet");
        (bool success,) = target.call(data);
        require(success, "External call failed");
    }
}
