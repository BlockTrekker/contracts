// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AppStorage.sol";
import "diamond-3/libraries/LibDiamond.sol";


interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// =============================================================
//                      PAYMASTER V1
//  Paymaster for onchain payments for BlockTrekker queries
// =============================================================
contract AdministrationFacet {
    AppStorage internal s;

    /// EVENTS ///
    event Deposited(address _from, uint256 _amount); // a query payment was made to the treasury

    /// FUNCTIONS ///

    /**
     * Deposit USDC tokens to pay for BlockTrekker queries
     * @notice funds are directly paid to BlockTrekker treasury and offchain balance is tracked
     *         trust in BlockTrekker app required though onchain receipts can resolve disputes
     *
     * @param _amount - the amount of USDC tokens to deposit
     */
    function deposit(uint256 _amount) external {
        require(IERC20(s.usdc).transferFrom(msg.sender, s.treasury, _amount), "!Deposit");
        emit Deposited(msg.sender, _amount);
    }
}
