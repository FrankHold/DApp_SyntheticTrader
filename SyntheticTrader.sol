
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

    uint Reference_Price_in_Wei;    // Each by / sell changes the reference price
                                    // Only used to determine the collateral 

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

        // Sell Orders
        uint No_del = 0;
        for (uint i = 1; i<No_Sell_Orders+1; i++){
            if (Sells[i].Address == msg.sender) {
                        Own_Funds[msg.sender]                 += Sells[i].Security; // ??? Coll is stored in Coll[sender] -> ERROR
                        No_del++;        // Number of deleted sell orders 
            }
            if (No_del >0) {
                        Sells[i].Amount                        = Sells[i+No_del].Amount;
                        Sells[i].Security                      = Sells[i+No_del].Security;                 // Collateral
                        Sells[i].Address                       = Sells[i+No_del].Address;
            }
        }
        No_Sell_Orders=No_Sell_Orders - No_del;

        // Buy Orders
        No_del = 0;
        for (i = 1; i<No_Buy_Orders+1; i++){
            if (Buys[i].Address == msg.sender) {
                        Own_Funds[msg.sender]                  = Buys[i].Security;
                        No_del++;     // Number of deleted buy orders   
            }
            if (No_del >0) {
                         Buys[i].Amount                         = Buys[i+No_del].Amount;
                         Buys[i].Security                       = Buys[i+No_del].Security;               // Collateral
                         Buys[i].Address                        = Buys[i+No_del].Address;
            }
        }
        No_Buy_Orders=No_Buy_Orders - No_del;

     }

     function Withdraw_All_Funds() { // Withdraw all the free funds of the trader 
        msg.sender.send(Own_Funds[msg.sender]);
        Own_Funds[msg.sender]=0;
     }


// Maybe later

     function Cancel_Buy_Order(uint Amount, uint Price_in_Wei, uint Order_Number) internal { // Cancle Buy order

     }

     function Cancel_Sell_Order(uint Amount, uint Price_in_Wei, uint Order_Number) internal { // Cancle Buy order

     }

     function Send_Stock(address Account,uint Amount) internal {
 
     }

     function Show_10_transactions() internal {
        // buy/sell Price Amount address 
     }

// subroutines

   function SellCash(uint Amount) internal {
                     uint Trade_Amount = Amount;

                     if (Amount > Own_Amount[msg.sender]){ // here only if he has it
                        Trade_Amount = Own_Amount[msg.sender];
                     }

                     // How much is there

                     if (Buys[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buys[No_Buy_Orders].Security                  -= Trade_Amount*Buys[No_Buy_Orders].Price;  // Collateral
                         Own_Funds[msg.sender]                         += Trade_Amount*Buys[No_Buy_Orders].Price;  // Funds

                         Own_Amount[msg.sender]                        -= Trade_Amount;
                         Own_Amount[Buys[No_Buy_Orders].Address]       += Trade_Amount;                            // Amount
                         Amount                                        -= Trade_Amount;                         

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Buys[No_Buy_Orders].Amount;               // what is here
                         Own_Funds[msg.sender]                        += Buys[No_Buy_Orders].Security;             // Funds

                         Own_Amount[msg.sender]                       -= Trade_Amount;
                         Own_Amount[Buys[No_Buy_Orders].Address]       += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Buys[No_Buy_Orders].Amount                    = 0;
                         Buys[No_Buy_Orders].Security                  = 0;                                       // Collateral
                         Buys[No_Buy_Orders].Address                   = 0;
                         No_Buy_Orders --;
                      }
   }

   function SellDept(uint Amount) internal {

                      // remaining on 'dept' but he has to provide a security (Amount>0 && Own_Amount[msg.sender]<=0)

                      uint Trade_Amount = Amount;
                          
                      // Only as much he can provide a security
                      if (Trade_Amount * Reference_Price_in_Wei < Own_Funds[msg.sender] * 10^18){ 
                         Trade_Amount = Own_Funds[msg.sender] / Reference_Price_in_Wei * 10^18;
                      }
                     
                      if (Buys[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buys[No_Buy_Orders].Security         -= Trade_Amount/10^18*Buys[No_Buy_Orders].Price;    // Collateral
                         Own_Security[msg.sender]               += Trade_Amount/10^18*Buys[No_Buy_Orders].Price;  // 

                         Own_Funds[msg.sender]                  -= Trade_Amount/10^18*Reference_Price_in_Wei;    // Funds
                         Own_Security[msg.sender]               += Trade_Amount/10^18*Reference_Price_in_Wei;    // 

                         Own_Amount[msg.sender]                 -= Trade_Amount;
                         Own_Amount[Buys[No_Buy_Orders].Address]+= Trade_Amount;                                 // Amount
                         Amount                                 -= Trade_Amount;                         

                      } else {
                         // Close the current order

                         Trade_Amount                            = Buys[No_Buy_Orders].Amount;             // 
                         Own_Security[msg.sender]               += Buys[No_Buy_Orders].Security;           // 

                         Own_Amount[msg.sender]                 -= Trade_Amount;
                         Own_Amount[Buys[No_Buy_Orders].Address]+= Trade_Amount;                          // Amount
                         Amount                                 -= Trade_Amount;

                         // close order
                         Buys[No_Buy_Orders].Amount              = 0;
                         Buys[No_Buy_Orders].Security            = 0;                                     // Collateral
                         Buys[No_Buy_Orders].Address             = 0;
                         No_Buy_Orders --;
                      }
   }


    function SellOrder(uint Amount, uint Price_in_Wei) internal {
      
        //put it on the right position in the sell list
        No_Sell_Orders++;
        for (uint i = No_Sell_Orders; i>0; i--){
            if (Sells[i-1].Price >= Price_in_Wei || i == 1) {
                        Sells[i].Price                       = Price_in_Wei; 
                        Sells[i].Amount                      = Amount;
                        Own_Amount[msg.sender]              -= Amount;
                        Sells[i].Address                     = msg.sender; 
                        i=0; // Exit         
            }else{
                        Sells[i].Price                       = Sells[i-1].Price;
                        Sells[i].Amount                      = Sells[i-1].Amount;
                        Sells[i].Address                     = Sells[i-1].Address;
            }
      }
      
    } 


// -----------------------------------------------------------------------------------------------------

   function BuyCash(uint Amount) internal {
                     uint Trade_Amount = 0;

                     uint Funds_Available = Own_Funds[msg.sender];

                     // Collateral will be set free
                     if (Own_Amount[msg.sender] + Amount < 0 ){ // he closes only his dept
                        Funds_Available += Own_Security[msg.sender]*(Own_Amount[msg.sender]+Amount)/10^18/Own_Amount[msg.sender];
                     }else{ // close the dept and will buy more
                        Funds_Available += Own_Security[msg.sender];
                     }

                     if (Funds_Available / Sells[No_Sell_Orders].Price * 10^18 < Amount){
                        Trade_Amount = Funds_Available / Sells[No_Sell_Orders].Price * 10^18;
                     }else{
                        Trade_Amount = Amount;
                     }

                     // How much is there

                     if (Sells[No_Sell_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order

                         // Reduce collateral 
                         if (Own_Amount[msg.sender]<0){
                            if (Own_Amount[msg.sender] < Trade_Amount){
                               Own_Funds[msg.sender]  +=Own_Security[msg.sender]* Trade_Amount / Own_Amount[msg.sender];
                               Own_Security[msg.sender]=Own_Security[msg.sender]*(Own_Amount[msg.sender]-Trade_Amount)/10^18/Own_Amount[msg.sender];

                            }else{
                               Own_Funds[msg.sender]   += Own_Security[msg.sender];
                               Own_Security[msg.sender] = 0;
                            }
                         }
                        
                         Own_Funds[msg.sender]                       -= Trade_Amount/10^18*Sells[No_Sell_Orders].Price;  // Funds
                         Own_Funds[Sells[No_Sell_Orders].Address]    += Trade_Amount/10^18*Sells[No_Sell_Orders].Price;  

                         Sells[No_Sell_Orders].Amount                 -= Trade_Amount;
                         Own_Amount[msg.sender]                       += Trade_Amount;
                         Amount                                       -= Trade_Amount;

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Sells[No_Sell_Orders].Amount; // nur so viel wie da ist
                         Own_Funds[msg.sender]                        += Sells[No_Sell_Orders].Security;         // Funds

                         Own_Amount[msg.sender]                       -= Trade_Amount;
                         Own_Amount[Sells[No_Sell_Orders].Address]    += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Sells[No_Sell_Orders].Amount                  = 0;
                         Sells[No_Sell_Orders].Security                = 0;                                     // Collateral
                         Sells[No_Sell_Orders].Address                 = 0;
                         No_Sell_Orders --;
                      }
   }

    function BuyOrder(uint Amount, uint Price_in_Wei) internal {
      
        //put it on the right position in the sell list
        // biggest buy price in the last position
        No_Buy_Orders++;
        for (uint i = No_Buy_Orders; i>0; i--){
            if (Buys[i-1].Price < Price_in_Wei) {
                        Buys[i].Price                      = Price_in_Wei;
                        Buys[i].Amount                     = Amount;
                        Buys[i].Security                   = Price_in_Wei*Amount/10^18;
                        Own_Funds[msg.sender]             -= Price_in_Wei*Amount/10^18;
                        Buys[i].Address                    = msg.sender;          
                        i=0; // Exit  
            }else{
                        Buys[i].Price                      = Buys[i-1].Price;
                        Buys[i].Amount                     = Buys[i-1].Amount;
                        Buys[i].Security                   = Buys[i-1].Security;                                     // Collateral
                        Buys[i].Address                    = Buys[i-1].Address;
            }
        }
    } 
}
