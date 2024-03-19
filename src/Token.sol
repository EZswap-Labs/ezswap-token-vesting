// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract EZTokenTest is ERC20 {
    constructor() ERC20("EZT", "EZTEST", 18) {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
