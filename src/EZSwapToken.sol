// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract EZSWAP is ERC20 {
    constructor(address _owner) ERC20("EZswap Protocol", "EZSWAP", 18) {
        _mint(_owner, 1_000_000_000 * 10 ** 18);
    }
}
