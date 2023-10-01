//+------------------------------------------------------------------+
//|                                            breakeven_line_v3.mq4 |
//|                                        Copyright 2023, M. Geller |
//|                                           newlegs@protonmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, M.Geller"
#property strict
#property indicator_chart_window
//---
extern color font_color=White;
int font_size=14;
//---
int PipAdjust,NrOfDigits;
double point;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDelete("Average_Price_Line_"+Symbol());
   ObjectDelete("Information_"+Symbol());
   ObjectDelete("Information_2"+Symbol());
   ObjectDelete("Information_3"+Symbol());
//---
   NrOfDigits=Digits;
//---
   if(NrOfDigits==5 || NrOfDigits==3)
      PipAdjust=10;
   else
      if(NrOfDigits==4 || NrOfDigits==2)
         PipAdjust=1;
//---
   point=Point*PipAdjust;
//---
//Alert(INIT_FAILED);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete("Average_Price_Line_"+Symbol());
   ObjectDelete("Information_"+Symbol());
   ObjectDelete("Information_2"+Symbol());
   ObjectDelete("Information_3"+Symbol());
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   int total = OrdersTotal();

//Alert("total= "+total);
//Alert("in OnCalculate...Symbol="+Symbol());
//---
   if(total>0)
     {
      for(int i=0; i<total; i++)
        {
         int ord=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
           {
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
              {
               Total_Buy_Trades++;
               Total_Buy_Price+= OrderOpenPrice()*OrderLots();
               Total_Buy_Size += OrderLots();
               Buy_Profit+=OrderProfit()+OrderSwap()+OrderCommission();
              }
            if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
              {
               Total_Sell_Trades++;
               Total_Sell_Size+=OrderLots();
               Total_Sell_Price+=OrderOpenPrice()*OrderLots();
               Sell_Profit+=OrderProfit()+OrderSwap()+OrderCommission();
              }
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
//---
   //ObjectDelete("Average_Price_Line_"+Symbol());
   //ObjectDelete("Information_"+Symbol());
   //ObjectDelete("Information_2"+Symbol());
   //ObjectDelete("Information_3"+Symbol());
//---
   if(Net_Trades>0 && Net_Lots!=0)
     {
      distance=(Net_Result/(MathAbs(Net_Lots*MarketInfo(Symbol(),MODE_TICKVALUE)))*MarketInfo(Symbol(),MODE_TICKSIZE));  // in ticks (or points) or pips?
      if(Net_Lots>0)  // Long position
        {
         Average_Price=Bid-distance;
         if (Average_Price>tpPrice) { pipsOfProfit = (tpPrice-Average_Price)/point; }  // if loss @ TP, distance, in pips, from breakeven price to TP price is negative
         else { pipsOfProfit = MathAbs(tpPrice-Average_Price)/point; }
         pipsToTP = (Bid-tpPrice)/point;  // distance, in pips, from current bid price to TP price
        }
      if(Net_Lots<0)  // Short position
        {
         Average_Price=Ask+distance;
         if (Average_Price<tpPrice) { pipsOfProfit = (Average_Price-tpPrice)/point; }  // if loss @ TP, distance, in pips, from breakeven price to TP price is negative 
         else { pipsOfProfit = MathAbs(Average_Price-tpPrice)/point; }
         pipsToTP = (tpPrice-Ask)/point;  // distance, in pips, from current bid price to TP price
        }
     }
   if(Net_Trades>0 && Net_Lots==0)
     {
      distance=(Net_Result/((MarketInfo(Symbol(),MODE_TICKVALUE)))*MarketInfo(Symbol(),MODE_TICKSIZE));
      Average_Price=Bid-distance;
      pipsOfProfit = MathAbs((tpPrice-Average_Price)/point);  // distance, in pips, from breakeven price to TP price
     }
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
//---
   ObjectSet("Average_Price_Line_"+Symbol(),OBJPROP_COLOR,cl);
   ObjectCreate("Information_"+Symbol(),OBJ_LABEL,0,0,0);
   ObjectCreate("Information_2"+Symbol(),OBJ_LABEL,0,0,0);
   ObjectCreate("Information_3"+Symbol(),OBJ_LABEL,0,0,0);
//---
   int x,y;
   ChartTimePriceToXY(0,0,Time[0],Average_Price,x,y);
//---
   ObjectSet("Information_"+Symbol(),OBJPROP_XDISTANCE,300);
   ObjectSet("Information_"+Symbol(),OBJPROP_YDISTANCE,0);
   ObjectSetText("Information_"+Symbol(),"BreakEven = "+DoubleToStr(Average_Price,NrOfDigits)+", "+DoubleToStr(distance/(point),1)+" pips ("+DoubleToStr(Net_Result,2)+" "+AccountInfoString(ACCOUNT_CURRENCY)+") ",10,"Arial",White);
//---
   ObjectSet("Information_2"+Symbol(),OBJPROP_XDISTANCE,685);
   ObjectSet("Information_2"+Symbol(),OBJPROP_YDISTANCE,0);
   ObjectSetText("Information_2"+Symbol(),"TakeProfit = "+DoubleToStr(tpPrice,NrOfDigits)+", "+DoubleToStr(pipsToTP,1)+" pips",10,"Arial",White);
//---
   ObjectSet("Information_3"+Symbol(),OBJPROP_XDISTANCE,980);
   ObjectSet("Information_3"+Symbol(),OBJPROP_YDISTANCE,0);
   ObjectSetText("Information_3"+Symbol(),"OpenLots = "+DoubleToStr(Net_Lots,2)+", ExpectedProfit= "+DoubleToStr(profitAtClose,2)+" "+AccountInfoString(ACCOUNT_CURRENCY),10,"Arial",White);
//---
//Alert("in OnCalculate...Symbol="+Symbol());
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
