// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/*

    Create a trusted third party that stores the money until 
    the delivery of the product takes place. Like Amazon

    The functionality of the Smart Contract is presented in the following brief case scenario:

    1) A Seller (S) publishes (through the Smart Contract) an item for sale 
       providing name and price namely, "Ticket to Barcelona Match" and 1 Eth.
    2) A Buyer (B) wants to purchase so she deposits product's price + security deposit as a payment.
       In our case the value = equals to 2 Eth.
    3) S sees the money in the Smart Contract and sends the item to B.
    4) Assuming that the shipment is not lost along the way, eventually B will receive her package.
    5) B needs to confirm the delivery of the product. If B confirms the delivery on time (e.g. under 30 days after the arrival) then
       S is getting paid with the price of the product while B receives hers security deposit intact. However, if B does not 
       confirm it on time, she receives a penalty which means that S will get both the product value as well as the security deposit.
    6) If B wants to return the product she has a specific period to do so (i.e. 10 days).
    7) Once S gets notified about B's decision, she sends the money (refund) to the smart contract. And waits for the item to return to S.
    8) Once S has received the product, she confirms the delivery and the refund is successfull
    9) As in step 4) we assume that the shipment is not lost and eventually S will receive the package.
    9) S is being given a specific period of time (i.e. 10 days) to confirm the return of the product. If she confirms on time the money will
    be returned to B. If not, B has also the ability to withdraw the money from the smart contract once the aforementioned period has passed.
*/

contract Amazon {

    uint public constant SECURITY_DEPOSIT_IN_ETHER = 1; //

    /* Entities */
    address payable seller;
    address payable buyer;

    /* Important Dates */
    uint256 public purchaseDate;
    uint256 public confirmationDate;
    uint256 public returnDate;
    
    /* Flags */
    bool returnRequested; // Whether a refund has been requested

    /* Data about the product */
    string public productName;
    uint32 public price; // In Ether 
    

    /* The seller deployes the smart contract by providing the price and the name of the product */
    constructor(uint32 _sellPrice, string memory _name) {
        seller = payable(msg.sender);
        productName = _name;
        price = _sellPrice;
    }

    /* Modifier to define if the one that makes the transaction is the seller of the product */
    modifier isSeller() {
        require(msg.sender == seller, "Only the seller can perform this function");
        _;
    }


    /* Modifier to define if the one that makes the transaction is the buyer of the product */
    modifier isBuyer(){
        require(msg.sender == buyer, "Only the client can perform this function");
        _;
    }

    /* 
        Method that allows only the seller to modify the price of the product provided that
        the product hasn't been purchased yet.
    */
    function changePrice(uint32 _newSellPrice) external payable isSeller {
        // A product is already purchased if there is a buyer != 0
        require(buyer == address(0), "A price cannot be changed if the product is bought.");

        price=_newSellPrice;    
    }

    /* 
        Method that allows a user to purchase the product.
    */
    function depositPayment() external payable {
        require(buyer == address(0), "The product has already been purchased.");

        // The value of the transaction shall be equal to the price of the product + the security deposit
        require(msg.value == (price + SECURITY_DEPOSIT_IN_ETHER) * 10**18, "There is not enough money in the transaction to cover the price plus the security deposit.");

        // Store the buyer's address as well as the date of the purchase
        buyer = msg.sender;
        purchaseDate = block.timestamp;
    }

    /* 
        Method that allows the buyer to confirm the delivery of the product. 

        Case a) If the delivery confirmation is on time (in 10 days) seller will get the price of the product and the security deposit
        is returned to the buyer

        Case b) If the delivery confirmation is overdue, seller will receive both the product price and the deposit. 
    */
    function confirmDelivery() external payable isBuyer {
        
        // 10 days to epochs = 864000    
        if(block.timestamp - purchaseDate < 86400){
            seller.transfer(price * 10**18);
            buyer.transfer(SECURITY_DEPOSIT_IN_ETHER * 10**18);
        } else {
            seller.transfer( (price + SECURITY_DEPOSIT_IN_ETHER) * 10**18);
        }

        // Store the date of the delivery confirmation
        confirmationDate = block.timestamp;
    }

    /*
        Method that allows the seller to withdraw the money from the smart contract provided that the buyer's deadline 
        to confirm the delivery has passed.
    */
    function receiveDeposit() external payable isSeller {
        // Check if a return order has been requested.
        require(returnRequested == false, "Cannot retreive the money if the return is issued");

        // 10 days to epochs = 864000
        if (block.timestamp - purchaseDate > 864000) {
            seller.transfer((price+SECURITY_DEPOSIT_IN_ETHER) * 10**18);
        }
    }

    /*
        This method allows the Seller to issue a "Return product" request. If this request is issued on time (10 days), 
        the Seller returns the money he received back to the smart contract.  
    */
    function returnIssued() external payable isSeller {

        // Make sure that the transaction contains the price of the product. 
        require(msg.value == price * 10**18, "The price of the item was different");

        // 7 days to epochs = 864000  
        require(block.timestamp - confirmationDate < 864000, "The Period to return the product has expired");
        
        // Set the returnRequested flag to "True" and store the date of the return request.
        returnDate=block.timestamp;
        returnRequested=true;
    }

    /*
        This method allows the Seller to confirm that the product has been delivered. This can be only executed
        if a return has been requested in the first place
    */
    function confirmReturnReceived() external payable isSeller {
        // Make sure that a return has been requested
        require(returnRequested==true, "The return request has not been issued.");

        // Refund the Buyer
        buyer.transfer(price* 10**18);
        returnRequested=false;
    }

    /*
        This method allows the Buyer to withdraw the money that the Seller has put in the smart contract provided
        that the Seller hasn't confirmed the return of the product after a period of time has passed after the return
        has been issued. This period is set to 10 days
    */
    function buyerReclaimReturnPrice() external payable isBuyer {
        // Make sure that a return has been requested
        require(returnRequested==true, "The return request has not been issued.");

        // 10 days to epochs = 864000   
        require(block.timestamp - returnDate > 864000, "Refund is under processing");

        // Refund the Buyer
        buyer.transfer(price * 10**18);
        returnRequested=false;
    }
    
}