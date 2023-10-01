//+------------------------------------------------------------------+
//|  Original Copyright:                            TradeState.mq4   |
//|                      Copyright 2020, MetaQuotes Software Corp.   |
//|                                           https://www.mql5.com   |
//|  Revision:                                   BreakEvenLine.mq4   |
//|                         Copyright 2023, Please Development LLC   |
//|                              https://www.pleasedevelopment.com   |
//+------------------------------------------------------------------+
#property copyright "2023 Please Development LLC"
#property link      "http://www.pleasedevelopment.com/"
#property version   "4.00"
#property strict
#property indicator_chart_window
// External parameter definitions: font color and font size
extern color font_color=White;
int font_size=14;
// Declare variables related to market info and symbol adjustments
int PipAdjust,NrOfDigits;
double point;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Delete potential previous objects from the chart to ensure a clean slate
   deleteObjects();
   // Initialize the number of digits for the current symbol
   NrOfDigits=Digits;
   // Adjust the pip value depending on the number of digits
   if(NrOfDigits==5 || NrOfDigits==3)
      PipAdjust=10;
   else
      if(NrOfDigits==4 || NrOfDigits==2)
         PipAdjust=1;
   // Calculate the value of one point (smallest price change)
   point=Point*PipAdjust;
//---
//Alert(INIT_FAILED);
   // Return that the initialization was successful
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|function is called when the indicator is de-initialized or removed|
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- delete any object. 
   deleteObjects();
  }
//+------------------------------------------------------------------+
//| Custom indicator calculation function that's executed on every   |
//| tick or price change                                             |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//Alert("in OnCalculate...Symbol="+Symbol());
   // Declare and initialize trade-related variables
   int Total_Buy_Trades=0;
   double Total_Buy_Size=0;
   double Total_Buy_Price=0;
   double Buy_Profit=0;
//---
   int Total_Sell_Trades=0;
   double Total_Sell_Size=0;
   double Total_Sell_Price=0;
   double Sell_Profit=0;
//---
   int Net_Trades=0;
   double Net_Lots=0;
//double prevNet_Lots;
   double Net_Result=0;
//---
   double Average_Price=0;
   double tpPrice=0;
   double distance=0;
   double ppMultiplier=0;
   double pipsToBE=0;
   double pipsToTP=0;
   double pipsOfProfit=0;
   double profitAtClose=0;
   double Pip_Value=MarketInfo(Symbol(),MODE_TICKVALUE)*PipAdjust;
   double Pip_Size=MarketInfo(Symbol(),MODE_TICKSIZE)*PipAdjust;
//---
//static int total;
//int prevTotal = total;
//total = OrdersTotal();
   // Check total number of open orders
   int total = OrdersTotal();

//Alert("total= "+total);
//Alert("in OnCalculate...Symbol="+Symbol());
   // If there are open orders
   if(total>0)
     {
      for(int i=0; i<total; i++)
        {
         int ord=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
           {
            // Check if it's a buy order for the current symbol
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
              {
               // Aggregate buy-related data
               Total_Buy_Trades++;
               Total_Buy_Price+= OrderOpenPrice()*OrderLots();
               Total_Buy_Size += OrderLots();
               Buy_Profit+=OrderProfit()+OrderSwap()+OrderCommission();
              }
            // Check if it's a sell order for the current symbol
            if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
              {
               // Aggregate sell-related data
               Total_Sell_Trades++;
               Total_Sell_Size+=OrderLots();
               Total_Sell_Price+=OrderOpenPrice()*OrderLots();
               Sell_Profit+=OrderProfit()+OrderSwap()+OrderCommission();
              }
            // Check for the take profit of the order if it's still open
            if(OrderSymbol()==Symbol())
              {
               datetime ctm=OrderCloseTime();
               if(ctm==0) // ctm == 0 implies the order is open/pending. The only pending order will be the TP order.
                 {
                  tpPrice = OrderTakeProfit();
                  //Alert(tpPrice);
                 }
              }
           }
        }
     }
   // Calculate the average price for buy and sell orders
   if(Total_Buy_Price>0)
     {
      Total_Buy_Price/=Total_Buy_Size;
     }
   if(Total_Sell_Price>0)
     {
      Total_Sell_Price/=Total_Sell_Size;
     }
   Net_Trades=Total_Buy_Trades+Total_Sell_Trades;
//prevNet_Lots = Net_Lots;
   Net_Lots=Total_Buy_Size-Total_Sell_Size;
   Net_Result=Buy_Profit+Sell_Profit;       // aka current drawdown in dollars
   //--- delete any object. 
   deleteObjects();
   // If there are trades and the net lot is not zero
   if(Net_Trades>0 && Net_Lots!=0)
     {
      distance=(Net_Result/(MathAbs(Net_Lots*MarketInfo(Symbol(),MODE_TICKVALUE)))*MarketInfo(Symbol(),MODE_TICKSIZE));  // in ticks (or points) or pips?
      if(Net_Lots>0)  // Long position
        {
         Average_Price=Bid-distance;
         pipsOfProfit = MathAbs(tpPrice-Average_Price)/point;  // distance, in pips, from breakeven price to TP price
         pipsToTP = (Bid-tpPrice)/point;  // distance, in pips, from current bid price to TP price
        }
      if(Net_Lots<0)  // Short position
        {
         Average_Price=Ask+distance;
         pipsOfProfit = MathAbs(Average_Price-tpPrice)/point;  // distance, in pips, from breakeven price to TP price
         pipsToTP = (tpPrice-Ask)/point;  // distance, in pips, from current bid price to TP price
        }
     }
   if(Net_Trades>0 && Net_Lots==0)
     {
      distance=(Net_Result/((MarketInfo(Symbol(),MODE_TICKVALUE)))*MarketInfo(Symbol(),MODE_TICKSIZE));
      Average_Price=Bid-distance;
      pipsOfProfit = MathAbs(tpPrice-Average_Price)/point;  // distance, in pips, from breakeven price to TP price
     }
   // If the average price is calculated
   if(Average_Price>0)
     {
      pipsToBE = distance/point;           // distance, in pips, from current price to breakeven price
      ppMultiplier = Net_Result/pipsToBE;  // price per pip multiplier
      // only recalculate Expected Profit initially and when orders are opened/closed
      //profitAtClose = StrToDouble(profitAtClose);
     }
   profitAtClose = pipsOfProfit*ppMultiplier;

   ObjectDelete("Average_Price_Line_"+Symbol());
   ObjectCreate("Average_Price_Line_"+Symbol(),OBJ_HLINE,0,0,Average_Price);
   ObjectSet("Average_Price_Line_"+Symbol(),OBJPROP_WIDTH,1);

//---
   color cl=Blue;
//if(Net_Lots<0) cl=Red;
   if(Net_Lots==0)
      cl=White;
void createLabel(string objectName, int xDistance, int yDistance, string text) {
   ObjectCreate(objectName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(objectName, OBJPROP_XDISTANCE, xDistance);
   ObjectSet(objectName, OBJPROP_YDISTANCE, yDistance);
   ObjectSetText(objectName, text, 10, "Arial", White);
}

// Call the function for each label
ObjectSet("Average_Price_Line_"+Symbol(), OBJPROP_COLOR, cl);
createLabel("Information_"+Symbol(), 300, 0, "BreakEven = "+DoubleToStr(Average_Price,NrOfDigits)+", "+DoubleToStr(distance/(point),1)+" pips ("+DoubleToStr(Net_Result,2)+" "+AccountInfoString(ACCOUNT_CURRENCY)+") ");
createLabel("Information_2"+Symbol(), 685, 0, "TakeProfit = "+DoubleToStr(tpPrice,NrOfDigits)+", "+DoubleToStr(pipsToTP,1)+" pips");
createLabel("Information_3"+Symbol(), 980, 0, "OpenLots = "+DoubleToStr(Net_Lots,2)+", ExpectedProfit = "+DoubleToStr(profitAtClose,2)+" "+AccountInfoString(ACCOUNT_CURRENCY));//Alert("in OnCalculate...Symbol="+Symbol());
   return(0);
  }
//+------------------------------------------------------------------+
void deleteObjects(){
   ObjectDelete("Average_Price_Line_"+Symbol());
   ObjectDelete("Information_"+Symbol());
   ObjectDelete("Information_2"+Symbol());
   ObjectDelete("Information_3"+Symbol());
}
//+------------------------------------------------------------------+
