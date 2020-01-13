//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OsMA_EURUSD_M5_Params : Stg_OsMA_Params {
  Stg_OsMA_EURUSD_M5_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M5;
    OsMA_Period = 2;
    OsMA_Applied_Price = 3;
    OsMA_Shift = 0;
    OsMA_SignalOpenMethod = -61;
    OsMA_SignalOpenLevel = 36;
    OsMA_SignalCloseMethod = 1;
    OsMA_SignalCloseLevel = 36;
    OsMA_PriceLimitMethod = 0;
    OsMA_PriceLimitLevel = 0;
    OsMA_MaxSpread = 3;
  }
};
