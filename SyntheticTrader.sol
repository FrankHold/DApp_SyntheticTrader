
contract SyntheticTrader {

    // Work in process - EEEERRRROOORRRSSS

    // 1 Unit of Stock is 1/1e18 of a shear
    // Simple list of open orders
    // Sorted by price

    uint256 No_Sell_Orders; // Max number of sell orders
    uint256 No_Buy_Orders; // Max number of buy orders

    mapping (address => uint) public Funds;       // Funds of the trader in Wei (access by Trader)
    mapping (address => uint) public Collateral;
    mapping (address => uint) public Amount;      // Amount on Stock in Stock*10^18 (access by Trader if > 0)
    
    struct Sell
    {
       uint Amount;
       uint Price;
       uint Collateral;
       uint Address;
    }
    mapping (uint => Sell) public Sells;
    
    struct Buy
    {
       uint Amount;
       uint Price;
       uint Collateral;
       uint Address;
    }
    mapping (uint => Buy) public Buys;

    string Error_Message; // Open ToDo

    uint Reference_Price_in_Wei;    // Each by / sell changes the reference price
                                    // Only used to determine the collateral 

    function SyntheticTrader() {
       // Initialization
       No_Sell_Orders = 0;                   // Start without orders
       No_Buy_Orders  = 0;
       Reference_Price_in_Wei = 25*10^18;    // Reference Price in Wein (lol - good old times)
    }

    function () { // Send Ether to the contract

      Funds[msg.sender] += msg.value; // Add Funds in Wei

    }

    function Sell_Order(uint Amount, uint Price_in_Wei) { // Sell order

            while (Amount > 0){
                 if (Buys[No_Buy_Orders].Price >= Price_in_Wei) { // Sell if price is higher than ask
                     // Sell
                     if (Amount[msg.sender]>0) {
                        SellCash(Amount);
                        Reference_Price_in_Wei = (Reference_Price_in_Wei * 99 + Buys[No_Buy_Orders].Price)/100;
                     }
                     if (Amount>0 && Amount[msg.sender]<=0) {
                        SellDept(Amount);
                     }
                 } else {// to low in price 
                                          
                     // Create Sell order with the rest Amount
                     if (Amount > 0 && Price_in_Wei > 0){
                        SellOrder(Amount, Price_in_Wei);
                     }
                     Amount = 0;
                 } 
           } 
      
     }

     function Buy_Order(uint Amount, uint Price_in_Wei) { // New Buy order

            while (Amount > 0){
                if (Sells[No_Buy_Orders].Price <= Price_in_Wei) { // Buy if price is lower than ask
                     // Buy
                     BuyCash(Amount);
                     Reference_Price_in_Wei = (Reference_Price_in_Wei * 99 + Sells[No_Sell_Orders].Price)/100;
                } else {// to high in price
                                          
                     // Create Sell order with the rest Amount
                     if (Amount > 0 && Price_in_Wei > 0){
                        SellOrder(Amount, Price_in_Wei);
                     }
                     Amount = 0;
                } 
            }

     }
  
     function Cancel_All_Orders() { // Cancle all orders

        // Sell Orders
        uint No_del = 0;
        for (uint i = 1; i<No_Sell_Orders+1; i++){
            if (Sells[i].Address == msg.sender) {
                        Funds[msg.sender]                     += Sells[i].Collateral; // ??? Coll is stored in Coll[sender] -> ERROR
                        No_del++;        // Number of deleted sell orders 
            }
            if (No_del >0) {
                        Sells[i].Amount                        = Sells[i+No_del].Amount;
                        Sells[i].Collateral                    = Sells[i+No_del].Collateral;                 // Collateral
                        Sells[i].Address                       = Sells[i+No_del].Address;
            }
        }
        No_Sell_Orders=No_Sell_Orders - No_del;

        // Buy Orders
        No_del = 0;
        for (i = 1; i<No_Buy_Orders+1; i++){
            if (Buys[i].Address == msg.sender) {
                        Funds[msg.sender]                      = Buys[i].Collateral;
                        No_del++;     // Number of deleted buy orders   
            }
            if (No_del >0) {
                         Buys[i].Amount                         = Buys[i+No_del].Amount;
                         Buys[i].Collateral                     = Buys[i+No_del].Collateral;               // Collateral
                         Buys[i].Address                        = Buys[i+No_del].Address;
            }
        }
        No_Buy_Orders=No_Buy_Orders - No_del;

     }

     function Withdraw_All_Funds() { // Withdraw all the free funds of the trader 
        msg.sender.send(Funds[msg.sender]);
        Funds[msg.sender]=0;
     }


// Maybe later

     function Cancel_Buy_Order(uint256 Amount, uint256 Price_in_Wei, uint Order_Number) { // Cancle Buy order

     }

     function Cancel_Sell_Order(uint256 Amount, uint256 Price_in_Wei, uint Order_Number) { // Cancle Buy order

     }

     function Send_Stock(address Account,uint256 Amount) {
 
     }

     function Show_10_transactions(){
        // buy/sell Price Amount address 
     }

// subroutines

   function SellCash(uint Amount){
                     uint Trade_Amount = Amount;

                     if (Amount > Amount[msg.sender]){ // here only if he has it
                        Trade_Amount = Amount[msg.sender];
                     }

                     // How much is there

                     if (Buys[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buys[No_Buy_Orders].Collateral                -= Trade_Amount*Buys[No_Buy_Orders].Price;  // Collateral
                         Funds[msg.sender]                             += Trade_Amount*Buys[No_Buy_Orders].Price;  // Funds

                         Amount[msg.sender]                            -= Trade_Amount;
                         Amount[Buys[No_Buy_Orders].Address]           += Trade_Amount;                            // Amount
                         Amount                                        -= Trade_Amount;                         

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Buys[No_Buy_Orders].Amount;               // what is here
                         Funds[msg.sender]                            += Buys[No_Buy_Orders].Collateral ;          // Funds

                         Amount[msg.sender]                           -= Trade_Amount;
                         Amount[Buy[No_Buy_Orders].Address]           += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Buys[No_Buy_Orders].Amount                    = 0;
                         Buys[No_Buy_Orders].Collateral                = 0;                                       // Collateral
                         Buys[No_Buy_Orders].Address                   = 0;
                         No_Buy_Orders --;
                      }
   }

   function SellDept(uint Amount){

                      // remaining on 'dept' but he has to provide a security (Amount>0 && Amount[msg.sender]<=0)

                      uint Trade_Amount = Amount;
                          
                      // Only as much he can provide a security
                      if (Trade_Amount * Reference_Price_in_Wei < Funds[msg.sender] * 10^18){ 
                         Trade_Amount = Funds[msg.sender] / Reference_Price_in_Wei * 10^18;
                      }
                     
                      if (Buys[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buys[No_Buy_Orders].Collateral         -= Trade_Amount/10^18*Buys[No_Buy_Orders].Price;  // Collateral
                         Collateral[msg.sender]                 += Trade_Amount/10^18*Buys[No_Buy_Orders].Price;  // 

                         Funds[msg.sender]                      -= Trade_Amount/10^18*Reference_Price_in_Wei;    // Funds
                         Collateral[msg.sender]                 += Trade_Amount/10^18*Reference_Price_in_Wei;    // 

                         Amount[msg.sender]                     -= Trade_Amount;
                         Amount[Buys[No_Buy_Orders].Address]    += Trade_Amount;                                 // Amount
                         Amount                                 -= Trade_Amount;                         

                      } else {
                         // Close the current order

                         Trade_Amount                            = Buys[No_Buy_Orders].Amount;             // 
                         Collateral[msg.sender]                 += Buys[No_Buy_Orders].Collateral ;        // 

                         Amount[msg.sender]                     -= Trade_Amount;
                         Amount[Buys[No_Buy_Orders].Address]    += Trade_Amount;                          // Amount
                         Amount                                 -= Trade_Amount;

                         // close order
                         Buys[No_Buy_Orders].Amount              = 0;
                         Buys[No_Buy_Orders].Collateral          = 0;                                     // Collateral
                         Buys[No_Buy_Orders].Address             = 0;
                         No_Buy_Orders --;
                      }
   }


   function SellOrder(uint Amount, uint Price_in_Wei){
      
      //put it on the right position in the sell list
      
      for (uint i = No_Sell_Orders; i>0; i--){
         if (Sells[i].Price >= Price_in_Wei || No_Sell_Orders == 0) {
                         Sells[i+1].Amount                      = Amount;
                         Sells[i+1].Collateral                  = Price_in_Wei;                                    
                         Sells[i+1].Address                     = msg.sender; 
                         i=0; // Exit         

         }else{
                         Sells[i+1].Amount                      = Sells[i].Amount;
                         Sells[i+1].Collateral                  = Sells[i].Collateral;           // Collateral
                         Sells[i+1].Address                     = Sells[i].Address;
         }
      }
      No_Sell_Orders++;
   } 


// -----------------------------------------------------------------------------------------------------

   function BuyCash(uint Amount){
                     uint Trade_Amount = 0;

                     uint Funds_Available = Funds[msg.sender];

                     // Collateral will be set free
                     if (Amount[msg.sender] + Amount < 0 ){ // he closes only his dept
                        Funds_Available += Collateral[msg.sender]*(Amount[msg.sender]+Amount)/10^18/Amount[msg.sender];
                     }else{ // close the dept and will buy more
                        Funds_Available += Collateral[msg.sender];
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
                         if (Amount[msg.sender]<0){
                            if (Amount[msg.sender] < Trade_Amount){
                               Funds[msg.sender]    +=Collateral[msg.sender]* Trade_Amount / Amount[msg.sender];
                               Collateral[msg.sender]=Collateral[msg.sender]*(Amount[msg.sender]-Trade_Amount)/10^18/Amount[msg.sender];

                            }else{
                               Funds[msg.sender]     += Collateral[msg.sender];
                               Collateral[msg.sender] = 0;
                            }
                         }
                        
                         Funds[msg.sender]                       -= Trade_Amount/10^18*Sells[No_Sell_Orders].Price;  // Funds
                         Funds[Sells[No_Sell_Orders].Address]    += Trade_Amount/10^18*Sells[No_Sell_Orders].Price;  

                         Sells[No_Sell_Orders].Amount                 -= Trade_Amount;
                         Amount[msg.sender]                           += Trade_Amount;
                         Amount                                       -= Trade_Amount;

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Sells[No_Sell_Orders].Amount; // nur so viel wie da ist
                         Funds[msg.sender]                            += Sells[No_Sell_Orders].Collateral ;        // Funds

                         Amount[msg.sender]                           -= Trade_Amount;
                         Amount[Sell[No_Sell_Orders].Address]         += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Sells[No_Sell_Orders].Amount                  = 0;
                         Sells[No_Sell_Orders].Collateral              = 0;                                     // Collateral
                         Sells[No_Sell_Orders].Address                 = 0;
                         No_Sell_Orders --;
                      }
   }

   function BuyOrder(uint Amount, uint Price_in_Wei){
      
      //put it on the right position in the sell list
      
      for (uint i = No_Buy_Orders; i>0; i--){
         if (Buys[i].Price >= Price_in_Wei || No_Buy_Orders == 0) {
                         Buys[i+1].Amount                     = Amount;
                         Buys[i+1].Collateral                 = Price_in_Wei*Amount/10^18;
                         Funds[msg.sender]                   -= Price_in_Wei*Amount/10^18;
                         Buys[i+1].Address                    = msg.sender;          
                         i=0; // Exit  
         }else{
                         Buys[i+1].Amount                     = Buys[i].Amount;
                         Buys[i+1].Collateral                 = Buys[i].Collateral;                                     // Collateral
                         Buys[i+1].Address                    = Buys[i].Address;
         }
      }
      No_Buy_Orders++;
   } 
}
