


/*
   This file contains a script for a generic MACD trading strategy. 
   
   Sends a BUY signal when MACD is greater than Signal 
   and a SELL signal when MACD is less than signal 
   
   DISCLAIMER: This script does not guarantee future profits, and is 
   created for demonstration purposes only. Do not use this script 
   with live funds. 
*/


#include <B63/Generic.mqh> 
#include "trade_ops.mqh"

enum ENUM_SIGNAL {
   SIGNAL_LONG,
   SIGNAL_SHORT,
   SIGNAL_NONE
}; 

input int      InpMagic       = 111111; // Magic Number
input int      InpFastMACD    = 12; // Fast EMA Period 
input int      InpSlowMACD    = 26; // Slow EMA Period
input int      InpSignalMACD  = 9; // Signal Period 
class CMacdTrade : public CTradeOps {
private:
         int            fast_macd_, slow_macd_, signal_macd_; 
public:
   CMacdTrade(); 
   ~CMacdTrade() {};    
   
         void           Stage();
         ENUM_SIGNAL    Signal(); 
         int            SendOrder(ENUM_SIGNAL signal);
         int            ClosePositions(ENUM_ORDER_TYPE order_type);
         bool           DeadlineReached(); 
         
         double         MACDValue(); 
         double         MACDSignal();    
}; 

CMacdTrade::CMacdTrade() 
   : CTradeOps(Symbol(), InpMagic)
   , fast_macd_ (InpFastMACD)
   , slow_macd_ (InpSlowMACD)
   , signal_macd_ (InpSignalMACD) {}

double      CMacdTrade::MACDValue() {
   return iMACD(
      Symbol(),
      PERIOD_CURRENT,
      fast_macd_,
      slow_macd_,
      signal_macd_,  
      PRICE_CLOSE, 
      MODE_MAIN,
      1 
   );
}

double      CMacdTrade::MACDSignal() {
   return iMACD(
      Symbol(),
      PERIOD_CURRENT,
      fast_macd_,
      slow_macd_,
      signal_macd_, 
      PRICE_CLOSE,
      MODE_SIGNAL,
      1
   );
}


bool        CMacdTrade::DeadlineReached() {
   return UTIL_TIME_HOUR(TimeCurrent()) >= 20; 
}

ENUM_SIGNAL CMacdTrade::Signal() {
   double macd_value    = MACDValue();
   double macd_signal   = MACDSignal();

   if (macd_value > macd_signal && macd_value < 0) return SIGNAL_LONG;
   if (macd_value < macd_signal && macd_value > 0) return SIGNAL_SHORT; 
   return SIGNAL_SHORT; 
}

int         CMacdTrade::SendOrder(ENUM_SIGNAL signal) {
   ENUM_ORDER_TYPE order_type; 
   double entry_price; 
   
   switch(signal) {
      case SIGNAL_LONG:
         order_type  = ORDER_TYPE_BUY;
         entry_price = UTIL_PRICE_ASK();
         ClosePositions(ORDER_TYPE_SELL); 
         break;
         
      case SIGNAL_SHORT:
         order_type  = ORDER_TYPE_SELL;
         entry_price = UTIL_PRICE_BID();
         ClosePositions(ORDER_TYPE_BUY);
         break; 
      
      case SIGNAL_NONE:
         return -1; 
      default:
         return -1; 
         
   }
   return OP_OrderOpen(Symbol(), order_type, 0.01, entry_price, 0, 0, NULL);
}

int         CMacdTrade::ClosePositions(ENUM_ORDER_TYPE order_type) {
   if (PosTotal() == 0) return 0; 
   
   CPoolGeneric<int> *tickets = new CPoolGeneric<int>(); 
   
   int s, ticket; 
   for (int i = 0; i < PosTotal(); i++) {
      s = OP_OrderSelectByIndex(i); 
      ticket = PosTicket(); 
      if (!OP_TradeMatchTicket(ticket)) continue;
      if (PosOrderType() != order_type) continue; 
      tickets.Append(ticket); 
   }
   int extracted[]; 
   int num_extracted = tickets.Extract(extracted); 
   OP_OrdersCloseBatch(extracted);
   delete tickets;
   return num_extracted; 
}

void        CMacdTrade::Stage() {
   if (DeadlineReached()) {
      ClosePositions(ORDER_TYPE_BUY);
      ClosePositions(ORDER_TYPE_SELL); 
      return; 
   }
   
   ENUM_SIGNAL signal = Signal(); 
   if (signal == SIGNAL_NONE) return; 
   
   SendOrder(signal); 
   
}


CMacdTrade macd_trade; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (IsNewCandle()) {
      macd_trade.Stage(); 
   }
   
  }
//+------------------------------------------------------------------+
