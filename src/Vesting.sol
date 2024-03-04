// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

contract Vesting is Owned {
    using SafeTransferLib for ERC20;

    ERC20 immutable VESTING_TOKEN;

    uint256 constant interval = 90 days; // claim interval
    uint256 public constant lockAmount = 10000 * 10 ** 18; // total lock amount
    uint256 public constant perAmountClaim = 1000 * 10 ** 18; // per amount claim
    uint256 public constant maxClaimCount = lockAmount / perAmountClaim; // max claim count
    uint256 public startTime; // lock start time
    uint256 public count; // claim count

    bool public created; // if create lock
    bool public vestingEnded; // if vesting ended

    event Claimed(uint256 indexed count, address claimer, uint256 amount);
    event VestingStart(uint256 indexed startTime);
    event VestingEnded();

    constructor(address _token) Owned(msg.sender) {
        VESTING_TOKEN = ERC20(_token);
    }

    // owner creates a lock position only once
    function createLock() external onlyOwner {
        require(!created, "Lock has been created");
        require(!vestingEnded, "Vesting already ended");
        VESTING_TOKEN.safeTransferFrom(msg.sender, address(this), lockAmount);
        startTime = block.timestamp;
        created = true;

        emit VestingStart(startTime);
    }

    // owner claims tokens after unlocking at interval
    function claim() external onlyOwner {
        require(!vestingEnded, "Vesting already ended");
        require(block.timestamp >= startTime + (count + 1) * interval, "Claim not yet available");
        require(count < maxClaimCount, "All tokens have been claimed");

        count += 1;
        VESTING_TOKEN.safeTransfer(msg.sender, perAmountClaim);
        emit Claimed(count, msg.sender, perAmountClaim);

        if (count == maxClaimCount) {
            vestingEnded = true;
            emit VestingEnded();
        }
    }

    // This function can only be called after the end of vesting, and is mainly used for unexpected recovery
    function ownerCall(address target, bytes calldata data) external onlyOwner {
        require(vestingEnded, "Vesting has not ended yet");
        (bool success,) = target.call(data);
        require(success, "External call failed");
    }
}
