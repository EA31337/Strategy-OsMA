/**
 * @file
 * Implements OsMA strategy based on the Moving Average of Oscillator indicator.
 */

// User input params.
INPUT string __OsMA_Parameters__ = "-- OsMA strategy params --";  // >>> OsMA <<<
INPUT float OsMA_LotSize = 0;                                     // Lot size
INPUT int OsMA_SignalOpenMethod = 2;                              // Signal open method (-127-127)
INPUT float OsMA_SignalOpenLevel = 0.0f;                          // Signal open level
INPUT int OsMA_SignalOpenFilterMethod = 32;                        // Signal open filter method
INPUT int OsMA_SignalOpenBoostMethod = 0;                         // Signal open boost method
INPUT int OsMA_SignalCloseMethod = 2;                             // Signal close method (-127-127)
INPUT float OsMA_SignalCloseLevel = 0.0f;                         // Signal close level
INPUT int OsMA_PriceStopMethod = 1;                               // Price stop method
INPUT float OsMA_PriceStopLevel = 0;                              // Price stop level
INPUT int OsMA_TickFilterMethod = 1;                              // Tick filter method
INPUT float OsMA_MaxSpread = 4.0;                                 // Max spread to trade (pips)
INPUT short OsMA_Shift = 0;                                       // Shift
INPUT int OsMA_OrderCloseTime = -20;                              // Order close time in mins (>0) or bars (<0)
INPUT string __OsMA_Indi_OsMA_Parameters__ =
    "-- OsMA strategy: OsMA indicator params --";                               // >>> OsMA strategy: OsMA indicator <<<
INPUT int OsMA_Indi_OsMA_Period_Fast = 8;                                       // Period fast
INPUT int OsMA_Indi_OsMA_Period_Slow = 20;                                      // Period slow
INPUT int OsMA_Indi_OsMA_Period_Signal = 14;                                    // Period signal
INPUT ENUM_APPLIED_PRICE OsMA_Indi_OsMA_Applied_Price = (ENUM_APPLIED_PRICE)4;  // Applied price
INPUT int OsMA_Indi_OsMA_Shift = 0;                                             // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_OsMA_Params_Defaults : OsMAParams {
  Indi_OsMA_Params_Defaults()
      : OsMAParams(::OsMA_Indi_OsMA_Period_Fast, ::OsMA_Indi_OsMA_Period_Slow, ::OsMA_Indi_OsMA_Period_Signal,
                   ::OsMA_Indi_OsMA_Applied_Price, ::OsMA_Indi_OsMA_Shift) {}
} indi_osma_defaults;

// Defines struct with default user strategy values.
struct Stg_OsMA_Params_Defaults : StgParams {
  Stg_OsMA_Params_Defaults()
      : StgParams(::OsMA_SignalOpenMethod, ::OsMA_SignalOpenFilterMethod, ::OsMA_SignalOpenLevel,
                  ::OsMA_SignalOpenBoostMethod, ::OsMA_SignalCloseMethod, ::OsMA_SignalCloseLevel,
                  ::OsMA_PriceStopMethod, ::OsMA_PriceStopLevel, ::OsMA_TickFilterMethod, ::OsMA_MaxSpread,
                  ::OsMA_Shift, ::OsMA_OrderCloseTime) {}
} stg_osma_defaults;

// Struct to define strategy parameters to override.
struct Stg_OsMA_Params : StgParams {
  OsMAParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_OsMA_Params(OsMAParams &_iparams, StgParams &_sparams)
      : iparams(indi_osma_defaults, _iparams.tf.GetTf()), sparams(stg_osma_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_OsMA : public Strategy {
 public:
  Stg_OsMA(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_OsMA *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    OsMAParams _indi_params(indi_osma_defaults, _tf);
    StgParams _stg_params(stg_osma_defaults);
#ifdef __config__
    SetParamsByTf<OsMAParams>(_indi_params, _tf, indi_osma_m1, indi_osma_m5, indi_osma_m15, indi_osma_m30, indi_osma_h1,
                              indi_osma_h4, indi_osma_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_osma_m1, stg_osma_m5, stg_osma_m15, stg_osma_m30, stg_osma_h1,
                             stg_osma_h4, stg_osma_h8);
#endif
    // Initialize indicator.
    OsMAParams osma_params(_indi_params);
    _stg_params.SetIndicator(new Indi_OsMA(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_OsMA(_stg_params, _tparams, _cparams, "OsMA");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_OsMA *_indi = GetIndicator();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: histogram is below zero and changes falling direction into rising (5 columns are taken).
          _result &= _indi[_shift + 2][0] < 0;
          _result &= _indi.IsIncreasing(2, 0, _shift);
          _result &= _indi.IsIncByPct(_level, 0, _shift, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 1)) _result &= _indi.IsDecreasing(2, 0, 3);
          }
          break;
        case ORDER_TYPE_SELL:
          // Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken).
          _result &= _indi[_shift + 2][0] > 0;
          _result &= _indi.IsDecreasing(2, 0, _shift);
          _result &= _indi.IsDecByPct(-_level, 0, _shift, 2);
          if (_result && _method != 0) {
            if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(2, 0, 3);
          }
          break;
      }
    }
    return _result;
  }
};
