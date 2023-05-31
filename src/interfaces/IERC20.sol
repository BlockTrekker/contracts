// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// partial ERC20
interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}