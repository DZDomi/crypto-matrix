import 'package:crypto_matrix/models/models.dart';

class SharedPreferencesConst {
  static const String _INTRO_PREFIX = "intro_";
  static const String INTRO_FINISHED = _INTRO_PREFIX + "finished";

  static const String _BTL_COM_PREFIX = "blt_com_";
  static const String BLT_COM_DEVICE_UUID = _BTL_COM_PREFIX + "device_uuid";

  static const String _SETTINGS_PREFIX = "settings_";
  static const String SETTINGS_FIAT = _SETTINGS_PREFIX + "fiat";
  static const String SETTINGS_TIMEFRAME = _SETTINGS_PREFIX + "timeframe";
}

class RouteNames {
  static const String INTRO_WELCOME = 'intro-welcome';
  static const String INTRO_BLUETOOTH = 'intro-bluetooth';
  static const String INTRO_WIFI = 'intro-wifi';
  static const String OVERVIEW = 'overview';
  static const String SETTINGS = 'settings';
  static const String SETTINGS_TIMEFRAME = 'settings-timeframe';
}

class Fiats {
  static Map<String, Asset> FIATS = {
    "USDT": new Asset("USDT", "Tether USD", true),
    "USDC": new Asset("USDC", "USD Coin", true),
    "USD": new Asset("USD", "United States Dollar", true),
    "EUR": new Asset("EUR", "Euro", true),
    "JPY": new Asset("JPY", "Japanese Yen", true),
  };
}

class MatrixConst {
  static const int MAX_ROWS = 8;
}
