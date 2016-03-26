
contract SyntheticTrader {

    // Work in process - EEEERRRROOORRRSSS

    // 1 Unit of Stock is 1/1e18 of a shear
    // Simple list of open orders
    // Sorted by price

    uint256 No_Sell_Orders; // Max number of sell orders
    uint256 No_Buy_Orders; // Max number of buy orders

    mapping (address => uint) public Own_Funds;       // Funds of the trader in Wei (access by Trader)
    mapping (address => uint) public Own_Security;    // Security of the trader in Wei (no access)
    mapping (address => int) public Own_Amount;      // Amount on Stock in Stock*10^18 (access by Trader if > 0)
    
    struct Sell
    {
       uint Amount;
       uint Price;
       address Address;
    }
    mapping (uint => Sell) public Sells;
    
    struct Buy
    {
       uint Amount;
       uint Price;
       address Address;
    }
    mapping (uint => Buy) public Buys;

    string FeedBack_Message; // Open ToDo

    uint Reference_Price;   // Each by / sell changes the reference price
                            // Only used to determine the collateral / security

    function SyntheticTrader() {
       // Initialization
       No_Sell_Orders = 0;                   // Start without orders
       No_Buy_Orders  = 0;
       Reference_Price_in_Wei = 25*10^18;    // Reference Price in Wein (lol - good old times)
    }

    function () { // Send Ether to the contract

      Own_Funds[msg.sender] += msg.value; // Add Funds in Wei

    }

    function Sell_Order(uint Amount_1e18, uint Price_in_Wei) { // Sell order
        
        while (Amount > 0){
            if (Own_Amount[msg.sender] > 0 || Own_Funds[msg.sender] > 0 ){ 
                
                if (Buys[No_Buy_Orders].Price >= Price_in_Wei) { // Sell if price is higher than ask
                    // Sell
                    
                    Sell_from_List(Amount_1e18, Price_in_Wei)
                    
                } else {// to low in price 
                    // Create Sell order with the rest Amount
                    
                    Create_Sell_Order(Amount_1e18, Price_in_Wei);
                    
                }
            } else {
                Amount = 0;
            }
        } 
      
    }

    function Buy_Order(uint Amount_1e18, uint Price_in_Wei) { // New Buy order
        
        while (Amount > 0){
            if (Own_Funds[msg.sender] + Own_Security[msg.sender] > 0){
                if (Sells[No_Sell_Orders].Price <= Price_in_Wei && No_Sell_Orders > 0) { // Buy if price is lower than ask
                    // Buy
                     
                    Buy_from_List(Amount_1e18, Price_in_Wei);
                     
                } else {// to high in price
                    // Create Sell order with the rest Amount
                    Create_Buy_Order(Amount_1e18, Price_in_Wei);
                }
            } else {
                Amount = 0
            }
        }
        
    }
  
    function Cancel_Order(uint Price_in_Wei) { // Cancle all orders

        if (Price_in_Wei <= Buys[msg.sender){
        
            Cancel_Order_Buy(Price_in_Wei)
        
        }
    
        if (Price_in_Wei >= Sells[msg.sender){
        
            Cancel_Order_Sell(Price_in_Wei)
            
        }
    
    }

    function Withdraw_All_Funds() { // Withdraw all the free funds of the trader 
        msg.sender.send(Own_Funds[msg.sender]);
        Own_Funds[msg.sender]=0;
    }

// ------------------------------------------------------------------------------
// internal routines
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
// Buy / Sell from List
// ------------------------------------------------------------------------------

    function Sell_from_List(uint Amount) { //  internal 
    
        uint List_Amount = Buys[No_Buy_Orders].Amount;
        uint List_Price  = Buys[No_Buy_Orders].Price;
        
        uint Transfer_Amount = min(Amount,List_Amount);
        uint Sell_Amount = min(Transfer_Amount, max(Own_Amount[msg.sender],0));

        // First sell the Amount the trader has and get the funds
        Own_Funds[msg.sender] += Sell_Amount * List_Price
        
        // Then sell the remaining amount with funds as security
        
        uint Pay_Amount = min(Transfer_Amount - Sell_Amount, Own_Funds / Ref_Price)
        
        Own_Security[msg.sender] += Pay_Amount * List_Price
        Own_Security[msg.sender] += Pay_Amount * Ref_Price
        Own_Funds[msg.sender]    -= Pay_Amount * Ref_Price
  
        Amount                   -= Pay_Amount + Sell_Amount
        Own_Amount[msg.sender]   -= Pay_Amount + Sell_Amount
  
        If (Pay_Amount + Sell_Amount) > 0 {
            Ref_Price = (Ref_Price * 99 + List_Price) / 100
        }
  
        Sell_from_List_send_Buyer(Sell_Amount + Pay_Amount)
        Sell_from_List_edit_List(Sell_Amount + Pay_Amount)
   }
   
    function Buy_from_List(uint Amount) { //  internal 
    
        uint List_Amount = Sells[No_Sell_Orders].Amount;
        uint List_Price  = Sells[No_Sell_Orders].Price;
        
        uint Transfer_Amount = min(Amount,List_Amount);
        
        if (Own_Amount[msg.sender] => 0) {
            // trader buys only with funds // Own_Security = 0
            
            Max_Amount = Own_Funds[msg.sender] / List_Price;
            
        } else { // Own_Amount < 0  Security > 0

            if (List_Price <= Own_Security / (-Own_Amount[msg.sender])){
                // trader can buy with the security
                Max_Amount = (Own_Security[msg.sender] + Own_Funds[msg.sender]) / List_Price;
            }else{
                // trader hase to add funds to relese his security
                Max_Amount = Own_Funds[msg.sender] / (List_Price - Own_Security[msg.sender] / (-Own_Amount[msg.sender])) ;
                Max_Amount = min(Max_Amount,-Own_Amount[msg.sender]);
                uint rem_Funds = Own_Funds[msg.sender] - (List_Price - Own_Security[msg.sender] / (-Own_Amount[msg.sender]))*Max_Amount;
                Max_Amount += rem_Funds / List_Price;
            }
        }
        
        if (Transfer_Amount >= Max_Amount){
            // exit because end of funds
            Transfer_Amount = Max_Amount;
            Amount = 0;
        }else{
            Amount = Amount - Transfer_Amount;
        }
        
        if (Own_Amount < 0) {
            uint Free_Security = max(Own_Security[msg.sender] * min(Transfer_Amount / (-Own_Amount), 1), 0);
            Own_Funds[msg.sender]    += Free_Security;
            Own_Security[msg.sender] -= Free_Security;
        }
        Own_Funds[msg.sender]  -=  Transfer_Amount * List_Price
        Own_Amount[msg.sender] +=  Transfer_Amount
        
        If (Pay_Amount + Sell_Amount) > 0 {
            Ref_Price = (Ref_Price * 99 + List_Price) / 100
        }
  
        Buy_from_List_send_Seller(Transfer_Amount)
        Buy_from_List_edit_List(Transfer_Amount)
    }
  
    function Sell_from_List_send_Buyer(uint Transfer_Amount) { // Internal
        
        address List_msg_sender = Buys[No_Buy_Orders].Address;
        
        If (Own_Amount[List_msg_sender] + Transfer_Amount > 0) {
            
            Own_Funds[List_msg_sender]   += Own_Security[List_msg_sender]
            Own_Security[List_msg_sender] = 0
            
        } else { // List_Own_Amount + Transfer_Amount =< 0
            
            uint Free_Security = Own_Security[List_msg_sender] * Transfer_Amount / (-Own_Amount[List_msg_sender]);
            Own_Funds[List_msg_sender]    += Free_Security;
            Own_Security[List_msg_sender] -= Free_Security;
        }
        
        Own_Amount[List_msg_sender] += Transfer_Amount
        
    }

    function Buy_from_List_send_Seller(uint Transfer_Amount) { // Internal
        
        address List_msg_sender = Sells[No_Sell_Orders].Address;
        
        If (Own_Amount[List_msg_sender] > 0) {
            
            Own_Funds[List_msg_sender]    += Sells[No_Sell_Orders].Price * Transfer_Amount;
            
        } else {
            
            Own_Security[List_msg_sender] += Sells[No_Sell_Orders].Price * Transfer_Amount;
            
        }
        
    }  
  
    function Sell_from_List_edit_List(uint Transfer_Amount) { // Internal
        
        If (Transfer_Amount < Buys[No_Buy_Orders].Amount) {
            // If some more available
            // Don't close the List entry
            Buys[No_Buy_Orders].Amount -= Transfer_Amount
        } else {
            // Close the order
            Buys[No_Buy_Orders].Amount = 0
            Buys[No_Buy_Orders].Price = 0
            Buys[No_Buy_Orders].Address = 0
            No_Buy_Orders -= 1
        }
    }

    function Buy_from_List_edit_List(uint Transfer_Amount) { // Internal
        
        If (Transfer_Amount < Sells[No_Sell_Orders].Amount) {
            // If some more available
            // Don't close the List entry
            Sells[No_Sell_Orders].Amount -= Transfer_Amount
        } else {
            // Close the order
            Sells[No_Sell_Orders].Amount = 0
            Sells[No_Sell_Orders].Price = 0
            Sells[No_Sell_Orders].Address = 0
            No_Sell_Orders -= 1
        }
    }
    
// ------------------------------------------------------------------------------
// Create Order
// ------------------------------------------------------------------------------




// ------------------------------------------------------------------------------
// Cancel Order
// ------------------------------------------------------------------------------
        
        
        
        
// ------------------------------------------------------------------------------
// universal routines
// ------------------------------------------------------------------------------
// https://github.com/ethereum/wiki/wiki/Solidity-Features

  function max(int a, int b) returns (int) {
    if (a > b) return a;
    else return b;
  }
  function min(int a, int b) returns (int) {
    if (a < b) return a;
    else return b;
  }
