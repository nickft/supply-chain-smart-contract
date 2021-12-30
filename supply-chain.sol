// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/*

    Create a trusted third party that stores the money until 
    the delivery of the product takes place. Like Amazon

    1. Buyer deposits 1 ETH as payment
    2. Seller - that has created the SC - sees the money in the SC
    3. Basically Seller has defined two functions:
        -> depositPayment()
        -> confirmPayment()
    4. These functions must be executed only by the buyer
    5. Once Seller sees the money, he sends the product
    6. Once the Buyer receives the product - and he's happy - 
    he sends confirm delivery in order for the ETH to be transfered 
    from the SC to the Seller's account

*/

/*

    Approach:

    1. First we need to define the storage of the SC
    2. Seller will be defined once the SC is deployed
    3. Buyer will be defined once depositPayment() is called
    4. For depositPayment we need to define requires and actions
    5. requires: 
        a) Buyer should have money 
        b) There is no buyer defined so far (address(0))

        actions:
        define the buyer as the sender of the transaction
    6. For confirmPayment we need to transfer the money to the seller
        -> first we need to make the seller's address as payable
        -> and in the constructor cast the initialization as payable

        requires:
          a) The sender of the transaction is the buyer

        actions:
        transfer 1 ether to the seller's account

    ----------------------------------------------------------------
    IDEAS TO extend smart contracts (see Escrow smart contracts)

    What could go wrong? 

    1) What if seller does not send the product?
    2) What if buyer never calls confirm?

    So far, we don't give any motive/obligation for the buyer/seller 
    to proceed with the process.

    Motive for the Seller: Seller sends 1 ETH when SC is deployed
    Motive for the Buyer: Make the Buyer put 2 ETH and upon confirmation receive the 1 ETH back

    Force the Buyer to send confirmation: Give a deadline to respond



*/

contract Amazon {

    address payable seller;
    address buyer;


    constructor() {
        seller = payable(msg.sender);
    }

    function depositPayment() payable public{
        //require
        // 5a
        require(msg.value == 1 ether);

        // 5b
        require(buyer == address(0));

        // action
        buyer = msg.sender;
    }

    function confirmDelivery() public{
        // 6a
        require(msg.sender == buyer);

        // action
        seller.transfer(1 ether);
    }

}
