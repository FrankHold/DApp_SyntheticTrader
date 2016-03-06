
contract SyntheticTrader {

    // Work in process - EEEERRRROOORRRSSS

    // 1 Unit of Stock is 1/1e18 of a shear
    // Simple list of open orders
    // Sorted by price

    uint256 No_Sell_Orders; // Max number of sell orders
    uint256 No_Buy_Orders; // Max number of buy orders

    struct Trader
    {
      uint Funds;      // Funds of the trader in Wei (access by Trader)
      uint Collateral;
      uint Amount;    // Amount on Stock in Stock*10^18 (access by Trader if > 0)
    }

    struct Sell
    {
       uint Amount;
       uint Price;
       uint Collateral;
       uint Address;
    }
    struct Buy
    {
       uint Amount;
       uint Price;
       uint Collateral;
       uint Address;
    }

    string Error_Message; // Open ToDo

    uint256 Reference_Price_in_Wei;  // Each by / sell changes the reference price
                                     // Only used to determine the collateral 

    function SyntheticTrader() {
       // Initialization
       No_Sell_Orders = 0;                   // Start without orders
       No_Buy_Orders  = 0;
       Reference_Price_in_Wei = 25*10^18;    // Reference Price in Wei
    }

    function () { // Send Ether to the contract

      Trader[msg.sender].Funds += msg.value; // Add Funds in Wei

    }

    function Sell_Order(uint256 Amount, uint256 Price_in_Wei) { // Sell order

            while (Amount > 0){
                 if (Buy[No_Buy_Orders].Price >= Price_in_Wei) { // Sell if price is higher than ask
                     // Sell
                     if (Trader[msg.sender].Amount>0) {
                        SellCash(Amount);
                        Reference_Price_in_Wei = (Reference_Price_in_Wei * 99 + Price_in_Wei)/100;
                     }
                     if (Amount>0 && Trader[msg.sender].Amount<=0) {
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

     function Buy_Order(uint256 Amount, uint256 Price_in_Wei) { // New Buy order

            while (Amount > 0){
                 if (Sell[No_Buy_Orders].Price <= Price_in_Wei) { // Buy if price is lower than ask
                     // Buy
                     BuyCash(Amount);
                     Reference_Price_in_Wei = (Reference_Price_in_Wei * 99 + Sell[No_Buy_Orders].Price)/100;
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
           if (Sell[i].Address == msg.sender) {
                         Sell[i].Funds                         = Sell[i].Collateral;
                         No_del++;        
           }
           if (No_del >0) {
                         Sell[i].Amount                       = Sell[i+No_del].Amount;
                         Sell[i].Collateral                    = Sell[i+No_del].Collateral;                                     // Collateral
                         Sell[i].Address                       = Sell[i+No_del].Address;
           }
        }
        No_Sell_Orders=No_Sell_Orders - No_del;

        // Buy Orders
        No_del = 0;
        for (i = 1; i<No_Buy_Orders+1; i++){
           if (Buy[i].Address == msg.sender) {
                         Buy[i].Funds                          = Buy[i].Collateral;
                         No_del++;        
           }
           if (No_del >0) {
                         Buy[i].Amount                        = Buy[i+No_del].Amount;
                         Buy[i].Collateral                     = Buy[i+No_del].Collateral;                                     // Collateral
                         Buy[i].Address                        = Buy[i+No_del].Address;
           }
        }
        No_Buy_Orders=No_Buy_Orders - No_del;

     }

     function Withdraw_All_Funds() { // Withdraw all the Funds
        msg.sender.send(Trader[msg.sender].Funds);
        Trader[msg.sender].Funds=0;
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

// subroutine

   function SellCash(uint Amount){
                     uint Trade_Amount = Amount;

                     if (Amount > Trader[msg.sender].Amount){ // here only if he has it
                        Trade_Amount = Trader[msg.sender].Amount;
                     }

                     // How much is there

                     if (Buy[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buy[No_Buy_Orders].Collateral                 -= Trade_Amount*Buy[No_Buy_Orders].Price;  // Collateral
                         Trader[msg.sender].Funds                      += Trade_Amount*Buy[No_Buy_Orders].Price;  // Funds

                         Trader[msg.sender].Amount                    -= Trade_Amount;
                         Trader[Buy[No_Buy_Orders].Address].Amount    += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;                         

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Buy[No_Buy_Orders].Amount;              // what is here
                         Trader[msg.sender].Funds                      += Buy[No_Buy_Orders].Collateral ;          // Funds

                         Trader[msg.sender].Amount                    -= Trade_Amount;
                         Trader[Buy[No_Buy_Orders].Address].Amount    += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Buy[No_Buy_Orders].Amount                     = 0;
                         Buy[No_Buy_Orders].Collateral                  = 0;                                       // Collateral
                         Buy[No_Buy_Orders].Address                     = 0;
                         No_Buy_Orders --;
                      }
   }

   function SellDept(uint Amount){

                      // remaining on 'dept' but he has to provide a security (Amount>0 && Trader[msg.sender].Amount<=0)

                      uint Trade_Amount = Amount;
                          
                      // Only as much he can provide a security
                      if (Trade_Amount * Reference_Price_in_Wei < Trader[msg.sender].Funds * 10^18){ 
                         Trade_Amount = Trader[msg.sender].Funds / Reference_Price_in_Wei * 10^18;
                      }
                     
                      if (Buy[No_Buy_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order 

                         Buy[No_Buy_Orders].Collateral                 -= Trade_Amount/10^18*Buy[No_Buy_Orders].Price;  // Collateral
                         Trader[msg.sender].Collateral                 += Trade_Amount/10^18*Buy[No_Buy_Orders].Price;  // 

                         Trader[msg.sender].Funds                      -= Trade_Amount/10^18*Reference_Price_in_Wei;    // Funds
                         Trader[msg.sender].Collateral                 += Trade_Amount/10^18*Reference_Price_in_Wei;    // 

                         Trader[msg.sender].Amount                    -= Trade_Amount;
                         Trader[Buy[No_Buy_Orders].Address].Amount    += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;                         

                      } else {
                         // Close the current order

                         Trade_Amount                                  = Buy[No_Buy_Orders].Amount;            // 
                         Trader[msg.sender].Collateral                 += Buy[No_Buy_Orders].Collateral ;        // 

                         Trader[msg.sender].Amount                    -= Trade_Amount;
                         Trader[Buy[No_Buy_Orders].Address].Amount    += Trade_Amount;                         // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Buy[No_Buy_Orders].Amount                     = 0;
                         Buy[No_Buy_Orders].Collateral                  = 0;                                     // Collateral
                         Buy[No_Buy_Orders].Address                     = 0;
                         No_Buy_Orders --;
                      }
   }


   function SellOrder(uint256 Amount, uint256 Price_in_Wei){
      
      //put it on the right position in the sell list
      
      for (uint i = No_Sell_Orders; i>0; i--){
         if (Sell[i].Price >= Price_in_Wei || No_Sell_Orders == 0) {
                         Sell[i+1].Amount                     = Amount;
                         Sell[i+1].Collateral                  = Price_in_Wei;                                    
                         Sell[i+1].Address                     = msg.sender; 
                         i=0; // Exit         

         }else{
                         Sell[i+1].Amount                     = Sell[i].Amount;
                         Sell[i+1].Collateral                  = Sell[i].Collateral;                                     // Collateral
                         Sell[i+1].Address                     = Sell[i].Address;
         }
      }
      No_Sell_Orders++;
   } 


// -----------------------------------------------------------------------------------------------------

   function BuyCash(uint Amount){
                     uint Trade_Amount = 0;

                     uint Funds_Available = Trader[msg.sender].Funds;

                     // Collateral will be set free
                     if (Trader[msg.sender].Amount + Amount < 0 ){ // he closes only his dept
                        Funds_Available += Trader[msg.sender].Collateral*(Trader[msg.sender].Amount+Amount)/10^18/Trader[msg.sender].Amount;
                     }else{ // close the dept and buy more
                        Funds_Available += Trader[msg.sender].Collateral;
                     }

                     if (Funds_Available / Sell[No_Sell_Orders].Price < Amount){
                        Trade_Amount = Funds_Available / Sell[No_Sell_Orders].Price * 10^18;
                     }else{
                        Trade_Amount = Amount;
                     }

                     // How much is there

                     if (Sell[No_Sell_Orders].Amount > Trade_Amount){
                         // reduce only a part the current order

                         // Reduce collateral 
                         if (Trader[msg.sender].Amount<0){
                            if (Trader[msg.sender].Amount < Trade_Amount){
                               Trader[msg.sender].Funds    +=Trader[msg.sender].Collateral* Trade_Amount / Trader[msg.sender].Amount;
                               Trader[msg.sender].Collateral=Trader[msg.sender].Collateral*(Trader[msg.sender].Amount-Trade_Amount)/10^18/Trader[msg.sender].Amount;

                            }else{
                               Trader[msg.sender].Funds     += Trader[msg.sender].Collateral;
                               Trader[msg.sender].Collateral = 0;
                            }
                         }
                        
                         Trader[msg.sender].Funds                      -= Trade_Amount/10^18*Sell[No_Sell_Orders].Price;  // Funds
                         Trader[Sell[No_Sell_Orders].Address].Funds    += Trade_Amount/10^18*Sell[No_Sell_Orders].Price;  

                         Sell[No_Sell_Orders].Amount                  -= Trade_Amount;
                         Trader[msg.sender].Amount                    += Trade_Amount;
                         Amount                                       -= Trade_Amount;

                     } else {
                         // Close the current order
                         Trade_Amount                                  = Sell[No_Sell_Orders].Amount; // nur so viel wie da ist
                         Trader[msg.sender].Funds                      += Sell[No_Sell_Orders].Collateral ;        // Funds

                         Trader[msg.sender].Amount                    -= Trade_Amount;
                         Trader[Sell[No_Sell_Orders].Address].Amount  += Trade_Amount;                           // Amount
                         Amount                                       -= Trade_Amount;

                         // close order
                         Sell[No_Sell_Orders].Amount                     = 0;
                         Sell[No_Sell_Orders].Collateral                  = 0;                                     // Collateral
                         Sell[No_Sell_Orders].Address                     = 0;
                         No_Sell_Orders --;
                      }
   }

   

   function BuyOrder(uint256 Amount, uint256 Price_in_Wei){
      
      //put it on the right position in the sell list
      
      for (uint i = No_Buy_Orders; i>0; i--){
         if (Buy[i].Price >= Price_in_Wei || No_Buy_Orders == 0) {
                         Buy[i+1].Amount                     = Amount;
                         Buy[i+1].Collateral                  = Price_in_Wei;                                    
                         Buy[i+1].Address                     = msg.sender;          
                         i=0; // Exit  
         }else{
                         Buy[i+1].Amount                     = Buy[i].Amount;
                         Buy[i+1].Collateral                  = Buy[i].Collateral;                                     // Collateral
                         Buy[i+1].Address                     = Buy[i].Address;
         }
      }
      No_Buy_Orders++;
   } 
}
