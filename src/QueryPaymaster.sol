// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interface/IQueryPaymaster.sol";
import "./interface/IBlockTrekker.sol";

/**
 * @title QueryPaymaster
 * @dev BlockTrekker query payment rails (how users pay for queries)
 * @notice uses centralized debiting mechanic, advanced state channel architecture in future
 */
contract QueryPaymaster is IQueryPaymaster {
    /// CONSTRUCTOR ///
    /**
     * Initialize the query paymaster contract and point ownership at the BlockTrekker admin contract
     *
     * @param _blocktrekker - address of the BlockTrekker admin contract
     */
    constructor(address _blocktrekker) {
        // set ownership over contract to be the BlockTrekker admin contract
        transferOwnership(_blocktrekker);
    }

    /// FUNCTIONS ///
    function deposit(uint256 _amount) public override {
        // transfer payment tokens directly to treasury address or revert if failure
        require(
            IERC20(usdc()).transferFrom(msg.sender, treasury(), _amount),
            "!AffordDeposit"
        );
        // update creator query balance with deposited value
        balances[msg.sender] = balances[msg.sender] + _amount;
        // log the deposit in an event
        emit Deposited(msg.sender, _amount);
    }

    function debit(
        address _from,
        uint256 _amount
    ) public override queryBalance(_from, _amount) onlyOwner {
        // update creator query balance with debited value
        balances[_from] = balances[_from] - _amount;
        // log the debit in an event
        emit Debited(_from, _amount);
    }

    /// VIEWS ///

    function usdc() public view override returns (address) {
        return IBlockTrekker(owner()).usdc();
    }

    function treasury() public view override returns (address) {
        return IBlockTrekker(owner()).treasury();
    }
}
