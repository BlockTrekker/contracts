// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "../libraries/AppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDiamond.sol";

// =============================================================
//                      PAYMASTER V1
//  Paymaster for onchain payments for BlockTrekker queries
// =============================================================
contract PaymentFacet {
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
