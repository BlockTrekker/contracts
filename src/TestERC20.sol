// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("TestERC20", "TEST") {
    /**
     * Mint ERC20 tokens for testing purposes
     *
     * @param _to - address to mint tokens to
     * @param _amount - amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    /**
     * Override the default 18 decimals to USDC's 6 decimals
     *
     * @return # of decimals used in fixed point erc20 math
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
