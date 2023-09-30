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
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Blue
#property strict
//--- indicator buffer
double         ExtMapBuffer1[];
extern string  Note1 = "--- Trading Direction ---";
extern color   font_color = White;
extern string  Note2 = "Net Lots per Trading Direction";
double         Lots_Buy;
double         Lots_Sell;
string         Trading_Direction;
double         Average_Price;
double         Local_Point;
double         PipAdjust;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //Indicator buffer
   SetIndexBuffer(0, ExtMapBuffer1);
   //Name
   IndicatorShortName("Trade State (C) 2021 CompanyName");
   SetIndexLabel(0,"Buffer1");
   SetIndexStyle(0,DRAW_LINE);
   // Initialize variables
   Local_Point = MarketInfo(Symbol(),MODE_POINT);
   PipAdjust = MathPow(10,MarketInfo(Symbol(),MODE_DIGITS));
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete("Lots_Sell_"+Symbol());
   ObjectDelete("Lots_Buy_"+Symbol());
   ObjectDelete("Average_Price_Line_"+Symbol());
   ObjectDelete("Trading_Direction_"+Symbol());
   ObjectDelete("Note2_"+Symbol());
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
   // Initialize variables for new calculation
   Lots_Buy=0;
   Lots_Sell=0;
   double sum_price_buy=0, sum_price_sell=0;
   // Loop through orders
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() != Symbol()) continue;
         if(OrderType() == OP_BUY)
           {
            Lots_Buy += OrderLots();
            sum_price_buy += OrderLots() * OrderOpenPrice();
           }
         else if(OrderType() == OP_SELL)
           {
            Lots_Sell += OrderLots();
            sum_price_sell += OrderLots() * OrderOpenPrice();
           }
        }
     }
   // Calculate average price
   Average_Price = (Lots_Buy != 0) ? sum_price_buy / Lots_Buy : (Lots_Sell != 0) ? sum_price_sell / Lots_Sell : 0;
   // Determine trading direction
   Trading_Direction = (Lots_Buy >= Lots_Sell) ? "Buy" : "Sell";
   // Display labels
   CreateLabel("Trading_Direction_"+Symbol(), "Trading Direction: "+Trading_Direction, 0, 300, 50, font_color);
   CreateLabel("Lots_Sell_"+Symbol(),"Sell Lots: "+DoubleToStr(Lots_Sell,2), 0, 300, 80, Red);
   CreateLabel("Lots_Buy_"+Symbol(),"Buy Lots: "+DoubleToStr(Lots_Buy,2), 0, 300, 110, Lime);
   // Display average price line
   ObjectCreate("Average_Price_Line_"+Symbol(),"Average Price",OBJ_TREND,0,Average_Price);
   ObjectSetInteger(0,"Average_Price_Line_"+Symbol(),OBJPROP_COLOR,font_color);
   //---
   return(rates_total);
  }
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int corner, int x_dist, int y_dist, color clr)
  {
   ObjectCreate(name, text, OBJ_LABEL, 0, 0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x_dist);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y_dist);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
  }
//+------------------------------------------------------------------+
