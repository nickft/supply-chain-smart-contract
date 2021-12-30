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

/**
    For the second part of the first ampliation what we want to do is too add information of the product so It can be checked when creating the smart contract. And modified.
    The information we want to add is:
        Name of the product
        price of the product
    Functionalities:
        Check name and price.
            Make variables public so easy to check
        Modify the price of the product if it has not been bought.
            We will need a variable to indicate if the product has been bought.
*/
contract Amazon {

    /*** Storage ***/
    address payable seller;
    address buyer;
    /** Data about the product **/
    string public productName;
    uint32 public price; //IN ETHER 
    bool productBought; //Does not need initialization to false because done by default by Solidity

    /**
        For varaibles of type array we need to specify an explicit data location.
        Data location can be storage or memory.
        storage is for persistent data and memory is for volatile data (as it is non persistent)
        In our case we will copy the value from memory to the storage we already have. 
    */
    constructor(uint32 _sellPrice, string memory _name) {
        seller = payable(msg.sender);
        productName = _name;
        price = _sellPrice;
    }

    modifier isSeller() {
        require(msg.sender == seller);
        _;
    }

    /*** Functions ***/
    function depositPayment() payable public{
        //require
        // 5a
        // We cannot use "ether" keyword with variables, only constants. but is equivalent to *10^18
        require(msg.value == price * 10**18);

        // 5b
        require(buyer == address(0));

        // action
        buyer = msg.sender;
        productBought = true;
    }

    function confirmDelivery() public{
        // 6a
        require(msg.sender == buyer);

        // action
        seller.transfer(price * 10**18);
        productBought=false;
    }

    /** Note: 
        Difference between external and public is that public methods can be called by 
        inside the contract, other contracts that inherit the contract and other contracts and accounts.
        external contracts can only be called by other contracts or accounts.
    */
    function changePrice(uint32 _newSellPrice) external isSeller {
        require(productBought==false); //A price cannot be changed if the product is bought.

        price=_newSellPrice;    
    }

}
