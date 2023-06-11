// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// test USDC ERC20 token to simulate payments
contract USDC is ERC20 {
    constructor() ERC20("Circle USD", "USDC") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}